/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 S.Calero@tue.nl         https://www.tue.nl/en/research/researchers/sofia-calero/
 t.j.h.vlugt@tudelft.nl  http://homepage.tudelft.nl/v9k6y
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

import Cocoa
import SystemConfiguration
import RenderKit
import iRASPAKit
import CloudKit
import simd
import OperationKit
import Compression
import SymmetryKit
import SimulationKit
import LogViewKit
import BinaryCodable


/// ProjectViewController controls an outlineView with the projects
///
/// Note: representedObject is a ProjectTreeController
class ProjectViewController: NSViewController, NSMenuItemValidation, NSOutlineViewDataSource, NSOpenSavePanelDelegate, NSProjectViewDelegate, WindowControllerConsumer, Reloadable
{
  @IBOutlet weak var projectOutlineView: ProjectOutlineView?
  @IBOutlet private var projectContextMenu: NSMenu?
  @IBOutlet weak var searchField: NSSearchField?
  
  private let projectNodeSubscriptionID = "iRASPA projects"
  private var reachability: Reachability? = nil
  
  private var stateLock: NSLock = NSLock()
  
  weak var windowController: iRASPAWindowController?
  
  let folderIcon: NSImage = NSImage(named: "FolderIcon")!
  let cifFileIcon: NSImage = NSImage(named: "CrystalProject")!
  
  private var draggedNodes: [ProjectTreeNode] = []
  
  // Programmatically setting the selection induces a notification, use 'observeNotifications' to avoid this side-effect
  var observeNotifications: Bool = true
  
  var filterContent: Bool = false
  {
    didSet(oldValue)
    {
      switch(oldValue, filterContent)
      {
      case (false, false):
        break
      case (false, true):
        self.projectOutlineView?.expandItem(nil, expandChildren: true)
      case (true, true):
        self.projectOutlineView?.expandItem(nil, expandChildren: true)
      case (true, false):
        // switch from filtering to non-filtering
        if let document: iRASPADocument = windowController?.document as? iRASPADocument
        {
          let storedObservedNotifications: Bool = self.observeNotifications
          self.observeNotifications = false
          self.projectOutlineView?.collapseItem(document.documentData.projectRootNode, collapseChildren: true)
          self.projectOutlineView?.expandItem(document.documentData.projectRootNode)
          self.projectOutlineView?.collapseItem(document.documentData.cloudCoREMOFRootNode, collapseChildren: true)
          self.projectOutlineView?.collapseItem(document.documentData.cloudCoREMOFDDECRootNode, collapseChildren: true)
          self.projectOutlineView?.collapseItem(document.documentData.cloudIZARootNode, collapseChildren: true)
          
          if let proxyProject: ProjectTreeNode = selectedProject
          {
            self.projectOutlineView?.makeItemVisible(item: proxyProject)
            if let row = self.projectOutlineView?.row(forItem: proxyProject)
            {
              self.projectOutlineView?.scrollRowToVisible(row)
            }
          }
          self.observeNotifications = storedObservedNotifications
        }
      }
    }
  }
  
  lazy var projectQueue: FKOperationQueue = {
    var queue = FKOperationQueue()
    queue.name = "Project queue"
    queue.qualityOfService = .userInitiated
    queue.maxConcurrentOperationCount = 8
    return queue
  }()
  
  var projectView: NSView?
  {
    return self.view
  }
  
  override func awakeFromNib()
  {
    super.awakeFromNib()
    
    self.projectOutlineView?.doubleAction = #selector(ProjectViewController.projectOutlineViewDoubleClick)
  }
  
  // ViewDidLoad: bounds are not yet set (do not do geometry-related setup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    self.searchField?.toolTip = "Show Projects with matching names"
    
    // check that it works with strong-references off (for compatibility with 'El Capitan')
    if #available(OSX 10.12, *)
    {
      self.projectOutlineView?.stronglyReferencesItems = false
    }
    
    self.reachability = Reachability()
    do
    {
      try self.reachability?.startNotifier()
    }
    catch
    {
      
    }
    
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    self.projectOutlineView?.registerForDraggedTypes([NSPasteboardTypeProjectTreeNode,
                                                      NSPasteboardTypeMovie,
                                                      NSPasteboardTypeFrame])
    self.projectOutlineView?.registerForDraggedTypes([NSPasteboard.PasteboardType(String(kUTTypeFileURL))])
    self.projectOutlineView?.registerForDraggedTypes([NSPasteboard.PasteboardType(String(kPasteboardTypeFileURLPromise))])
    
    
    self.projectOutlineView?.setDraggingSourceOperationMask(.every, forLocal: true)
    self.projectOutlineView?.setDraggingSourceOperationMask(.every, forLocal: false)

    
    NotificationCenter.default.addObserver(self, selector: #selector(ProjectViewController.handleIdentityChanged(_:)), name: NSNotification.Name.NSUbiquityIdentityDidChange,
      object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(ProjectViewController.handleIdentityChanged(_:)), name: NSNotification.Name.CKAccountChanged, object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(ProjectViewController.InsertCloudNode(_:)), name: NSNotification.Name(rawValue: NotificationStrings.iCloudAddNodeNotification), object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(ProjectViewController.handleCloudReloadData(_:)), name: NSNotification.Name(rawValue: NotificationStrings.iCloudReloadDataNotification), object: nil)
  }
  
  func initializeData()
  {
    // load the document library-data
    if let documentData: DocumentData = (self.windowController?.document as? iRASPADocument)?.documentData
    {
      self.loadGalleryDatabase(documentData: documentData)
      self.loadCoREMOFDatabase(documentData: documentData)
      self.loadCoREMOFDDECDatabase(documentData: documentData)
      self.loadIZADatabase(documentData: documentData)
    }
  }
  
 
  
  @objc func handleNetworkChanged(_ notification: Notification)
  {
    self.reloadData()
  }
  
  @objc func handleCloudReloadData(_ notification: Notification)
  {
    self.reloadData()
  }

  
  @objc func InsertCloudNode(_ notification: Notification)
  {
    if let node: ProjectTreeNode = notification.userInfo?["node"] as? ProjectTreeNode,
      let parent: ProjectTreeNode = notification.userInfo?["parent"] as? ProjectTreeNode
    {
      
      let index: Int = parent.childNodes.binarySearch{ $0.displayName.lowercased() < node.displayName.lowercased() }
      Cloud.shared.projectData.insertNode(node, inItem: parent, atIndex: index)
      
      if (!filterContent)
      {
        self.projectOutlineView?.insertItems(at: IndexSet(integer: index), inParent: parent, withAnimation: .slideRight)
      }
      
    }
  }
  
  @objc func handleIdentityChanged(_ notification: Notification)
  {
    let fileManager = FileManager()
    
    if let _ = fileManager.ubiquityIdentityToken
    {
      LogQueue.shared.info(destination: self.windowController, message: "User had logged in into iCloud")
    }
    else
    {
      LogQueue.shared.info(destination: self.windowController, message: "User has logged out of iCloud")
    }
    
  }
  
  // called when the project-view tab is selected
  override func viewWillAppear()
  {
    super.viewWillAppear()
    
    NotificationCenter.default.addObserver(self, selector: #selector(ProjectViewController.handleNetworkChanged(_:)), name: ReachabilityChangedNotification, object: self.reachability)
        
    // reload before the view will appear for the switch between tabs to show the up-to-date data in the transition
    // load all data for the project-views
    self.reloadData()
    
    self.reloadSelection()
    
    self.setDetailViewController()
  }
  
  
  override func viewDidAppear()
  {
    super.viewDidAppear()
    
    // for a NSOutlineView in SourceList-style, a reloadData must be done when on-screen
    // resulting artificts from not doing this: lost selection when resigning first-responder (e.g. import file)
    self.reloadData()
    
  }
  
  
  override func viewWillDisappear()
  {
    super.viewWillDisappear()
    
    NotificationCenter.default.removeObserver(self, name: ReachabilityChangedNotification, object: self.reachability)
  }
  
  // MARK: Utility
  // =====================================================================
  
  func restoreExpandedState(nodes: [ProjectTreeNode])
  {
    for node in nodes
    {
      if node.isExpanded
      {
        self.projectOutlineView?.expandItem(node)
      }
      else
      {
        self.projectOutlineView?.collapseItem(node)
      }
      restoreExpandedState(nodes: node.childNodes)
    }
  }
  
  
  func connectedToNetwork() -> Bool
  {
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    zeroAddress.sin_family = sa_family_t(AF_INET)
    
    guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        SCNetworkReachabilityCreateWithAddress(nil, $0)
      }
    }) else {
      return false
    }
    
    var flags: SCNetworkReachabilityFlags = []
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
      return false
    }
    
    let isReachable = flags.contains(.reachable)
    let needsConnection = flags.contains(.connectionRequired)
    
    return (isReachable && !needsConnection)
  }
  
  
  
  
  

  func IndexSetForSelection(_ nodes: [ProjectTreeNode]) -> IndexSet
  {
    let set: NSMutableIndexSet = NSMutableIndexSet()
    for node in nodes
    {
      if let row: Int = self.projectOutlineView?.row(forItem: node)
      {
        set.add(row)
      }
    }
    return set as IndexSet
  }
  
  var indexPathForInsertion: IndexPath
  {
    if let documentData: DocumentData = (self.windowController?.document as? iRASPADocument)?.documentData,
      let indexSet: IndexSet = self.projectOutlineView?.selectedRowIndexes,
      let beginRow: Int = self.projectOutlineView?.row(forItem: documentData.projectRootNode),
      let endRow: Int = self.projectOutlineView?.row(forItem: documentData.cloudRootNode)
    {
      let defaultInsertionIndexPath: IndexPath = documentData.projectRootNode.indexPath
      let projectRange: IndexSet = indexSet.intersection(IndexSet(beginRow..<endRow))
      if let firstRow: Int = projectRange.first,
         let item: ProjectTreeNode = self.projectOutlineView?.item(atRow: firstRow) as? ProjectTreeNode
      {
        return item.indexPath
      }
      return defaultInsertionIndexPath
    }
    return IndexPath()
  }
  
  var firstRowOfProjectSelection: Int?
  {
    if let documentData: DocumentData = (self.windowController?.document as? iRASPADocument)?.documentData,
      let indexSet: IndexSet = self.projectOutlineView?.selectedRowIndexes,
      let beginRow: Int = self.projectOutlineView?.row(forItem: documentData.projectRootNode),
      let endRow: Int = self.projectOutlineView?.row(forItem: documentData.cloudRootNode)
    {
      let projectRange: IndexSet = indexSet.intersection(IndexSet(beginRow..<endRow))
      return projectRange.first
    }
    return nil
  }
  
  
  // MARK: keyboard handling
  // =====================================================================
  
  
  override func keyDown(with theEvent: NSEvent)
  {
    self.interpretKeyEvents([theEvent])
  }
  
  override func deleteBackward(_ sender: Any?)
  {
    deleteSelection()
  }
  
 
  override func deleteForward(_ sender: Any?)
  {
    deleteSelection()
  }

  
 
  // MARK: Import data
  // =====================================================================
  
  @IBAction func cancelImport(sender: NSButton)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument,
       let superview = sender.superview,
       let row: Int = self.projectOutlineView?.row(for: superview), row >= 0
    {
      if let projectTreeNode: ProjectTreeNode = self.projectOutlineView?.item(atRow: row) as? ProjectTreeNode
      {
        let treeController: ProjectTreeController = document.documentData.projectData
      
        projectTreeNode.importOperation?.cancel()
        
        
        self.projectOutlineView?.beginUpdates()
        treeController.removeNode(projectTreeNode)
          
        let fromItem: Any? = self.projectOutlineView?.parent(forItem: projectTreeNode)
        if let childIndex: Int = self.projectOutlineView?.childIndex(forItem: projectTreeNode)
        {
          self.projectOutlineView?.removeItems(at: IndexSet(integer: childIndex), inParent: fromItem, withAnimation: .slideLeft)
        }
        self.projectOutlineView?.endUpdates()
      }
    }
  }
  
  func panel(_ sender: Any, shouldEnable url: URL) -> Bool
  {
    if url.hasDirectoryPath
    {
      return true
    }
    
    if let type = try? NSDocumentController.shared.typeForContents(of: url)
    {
      switch(type)
      {
      case iRASPA_CIF_UTI,
           iRASPA_PDB_UTI,
           iRASPA_XYZ_UTI:
        return true
      default:
        break
      }
    }
    
    if url.pathExtension.isEmpty &&
      (url.lastPathComponent.uppercased() == "POSCAR" ||
       url.lastPathComponent.uppercased() == "CONTCAR" ||
       url.lastPathComponent.uppercased() == "XDATCAR")
    {
      return true
    }
    
    return false
  }
  
  
  func importFileOpenPanel()
  {
    let importAccessoryViewController: ImportAccessoryViewController = ImportAccessoryViewController(nibName: "ImportAccessoryViewController", bundle: Bundle.main)
     
     let openPanel: NSOpenPanel = NSOpenPanel()
    
     openPanel.accessoryView = importAccessoryViewController.view
     openPanel.isAccessoryViewDisclosed = true
     openPanel.allowsMultipleSelection = true
     openPanel.canChooseDirectories = false
     
     openPanel.delegate = self
     openPanel.canChooseFiles = true
     openPanel.allowedFileTypes = ["cif","pdb", "xyz", "poscar", "contcar"]
     openPanel.allowedFileTypes = nil
     
     openPanel.begin { (result) -> Void in
       if result == NSApplication.ModalResponse.OK
       {
         if let importButton: NSButton = importAccessoryViewController.importSeparateProjects,
            let onlyAsymmetricUnitButton: NSButton = importAccessoryViewController.onlyAsymmetricUnit,
            let asMoleculeButton: NSButton = importAccessoryViewController.importAsMolecule
         {
           let asSeparateProjects: Bool = importButton.state == NSControl.StateValue.on ? true : false
           let onlyAsymmetricUnit: Bool = onlyAsymmetricUnitButton.state == NSControl.StateValue.on ? true : false
           let asMolecule: Bool = asMoleculeButton.state == NSControl.StateValue.on ? true : false
         
           self.importStructureFiles(openPanel.urls as [URL], asSeparateProjects: asSeparateProjects, onlyAsymmetricUnit: onlyAsymmetricUnit, asMolecule: asMolecule)
         }
       }
     }
  }
  
  func importStructureFiles(_ URLs: [URL], asSeparateProjects: Bool, onlyAsymmetricUnit: Bool, asMolecule: Bool)
  {
    guard URLs.count > 0 else {return}
    
    if let document: iRASPADocument = windowController?.document as? iRASPADocument,
       let selectedRow: Int = self.projectOutlineView?.selectedRow
    {
      let treeController: ProjectTreeController = document.documentData.projectData
      
      var index = selectedRow
      var toItem: ProjectTreeNode? = nil
      
    
      if index < 0
      {
        toItem = document.documentData.projectLocalRootNode
        index=0
      }
      else
      {
        if let node: ProjectTreeNode = self.projectOutlineView?.item(atRow: index) as? ProjectTreeNode,
           node.isDescendantOfNode(document.documentData.projectLocalRootNode), !(node === document.documentData.projectLocalRootNode)
        {
          toItem = node.parentNode
          index = (node.indexPath.last ?? 0) + 1
          
        }
        else
        {
          toItem = document.documentData.projectLocalRootNode
          index = 0
        }
      }
      

      if (asSeparateProjects)
      {
        // import as separate projects: loop over urls
        self.projectOutlineView?.beginUpdates()
        for url: URL in URLs
        {
          // create a holder that can be already be inserted into the 'projectViewController'
          // there is no project attached yet, set it as lazy&loading
          let displayName = url.deletingPathExtension().lastPathComponent
          let iraspaproject: iRASPAProject = iRASPAProject(projectType: .structure, fileName: UUID().uuidString, nodeType: .leaf, storageType: .local, lazyStatus: .loading)
          iraspaproject.displayName = displayName
          let node: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iraspaproject)
          
          let projectData: ProjectTreeController = document.documentData.projectData
          projectData.insertNode(node, inItem: toItem, atIndex: index)
          
          if (!filterContent)
          {
            self.projectOutlineView?.insertItems(at: IndexSet(integer: index), inParent: toItem, withAnimation: .slideRight)
          }
          
          // send as a single operation to the 'window-controller-queue'
          do
          {
            let operation = try ImportProjectOperation(projectTreeNode: node, outlineView: self.projectOutlineView, treeController: projectData, colorSets: document.colorSets, forceFieldSets: document.forceFieldSets, urls: [url], onlyAsymmetricUnit: onlyAsymmetricUnit, asMolecule: asMolecule)
            node.importOperation = operation
            windowController?.projectConcurrentQueue.addOperation(operation)
          
            index = index + 1
          }
          catch let error
          {
            LogQueue.shared.warning(destination: windowController, message: "\(error.localizedDescription)")
          }
        }
        self.projectOutlineView?.endUpdates()
      }
      else
      {
        // create a holder that can be already be inserted into the 'projectViewController'
        // there is no project attached yet, set it as lazy&loading
        let displayName = URLs[0].deletingPathExtension().lastPathComponent
        let iraspaproject: iRASPAProject = iRASPAProject.init(projectType: .structure, fileName: UUID().uuidString, nodeType: .leaf, storageType: .local, lazyStatus: .loading)
        let node: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iraspaproject)
        
        let projectData: ProjectTreeController = document.documentData.projectData
        projectData.insertNode(node, inItem: toItem, atIndex: index)
        
        if (!filterContent)
        {
          self.projectOutlineView?.insertItems(at: IndexSet(integer: index), inParent: toItem, withAnimation: .slideRight)
        }

        // send as a single operation to the 'window-controller-queue'
        do
        {
          let operation = try ImportProjectOperation(projectTreeNode: node, outlineView: self.projectOutlineView, treeController: projectData, colorSets: document.colorSets, forceFieldSets: document.forceFieldSets, urls: URLs, onlyAsymmetricUnit: onlyAsymmetricUnit, asMolecule: asMolecule)
          node.importOperation = operation
          windowController?.projectConcurrentQueue.addOperation(operation)
        }
        catch let error
        {
          LogQueue.shared.warning(destination: windowController, message: "\(error.localizedDescription)")
        }
      }
    
      if (filterContent)
      {
        treeController.updateFilteredNodes()
      }
    }
  }
  
  
  // MARK: NSOutlineView required datasource methods
  // =====================================================================
  
  
  // Returns the number of child items encompassed by a given item
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let projectViewController: ProjectTreeController = document.documentData.projectData
      // return count of root-items (dictionary 'contents' with parent is one of "LIBRARY", "PROJECTS", "ICLOUD PUBLIC", "CLUSTERS")
      // when asked for root
      if(item==nil)
      {
        return projectViewController.rootNodes.count
      }
    }
    
    // check if the item is a ProjectTreeNode
    if let node: ProjectTreeNode = item as? ProjectTreeNode
    {
      return node.filteredAndSortedNodes.filter{$0.matchesFilter}.count
    }
    
    return 0
  }
  
  
  // Returns the child item at the specified index of a given item
  func outlineView(_ outlineView: NSOutlineView, child index: Int,ofItem item: Any?) -> Any
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let projectViewController: ProjectTreeController = document.documentData.projectData
      // return root-items (dictionaries with parent is one of "LIBRARY", "PROJECTS", "ICLOUD PUBLIC", "CLUSTERS") when asked for root
      if item == nil,
         index < projectViewController.rootNodes.count
      {
        return projectViewController.rootNodes[index]
      }
    
      // check if the item is an ProjectTreeNode
      if let node: ProjectTreeNode = item as? ProjectTreeNode
      {
        let nodes = node.filteredAndSortedNodes.filter{$0.matchesFilter}
        if index < nodes.count
        {
          return nodes[index]
        }
      }
    }
    return 0
  }
  
  
  func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool
  {
    // the top-level items are of type Dictionary<String, String>
    if let document: iRASPADocument = windowController?.document as? iRASPADocument,
      let projectNode: ProjectTreeNode = item as? ProjectTreeNode
    {
      let projectTreeController: ProjectTreeController = document.documentData.projectData
      if projectTreeController.rootNodes.contains(projectNode)
      {
        return true
      }
    }
    
    return false
  }

  
  
  func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool
  {
    if let _: ProjectTreeNode = item as? ProjectTreeNode
    {
      return true
    }
    
    if let _: Dictionary<NSString, NSString> = item as? Dictionary<NSString, NSString>
    {
      return false
    }
    return true
  }
 
  
  // Returns a Boolean value that indicates whether the a given item is expandable
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool
  {

    if let node: ProjectTreeNode = item as? ProjectTreeNode
    {
      return node.representedObject.isProjectGroup
    }
  
    return false
  }
  
  
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
  {
    if let node: ProjectTreeNode  = item as? ProjectTreeNode,
      let view: NSTableCellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "projectViewRoot"), owner: self) as? NSTableCellView,
      let document: iRASPADocument = self.windowController?.currentDocument,
       document.documentData.projectData.rootNodes.contains(node)
    {
      view.textField?.stringValue = node.displayName
      view.textField?.isEditable = false
      return view
    }
    
    if let node: ProjectTreeNode  = item as? ProjectTreeNode,
       let view: ProjectTableCellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "projectView"), owner: self) as? ProjectTableCellView
    {
      view.progressIndicator?.isHidden = true
      view.cancelButton?.isHidden = true
      
      view.textField?.isEditable = false
      
      /*
      let owner: String
      if #available(OSX 10.12, *) { owner = CKCurrentUserDefaultName}
      else { owner = CKOwnerDefaultName}
      if Cloud.shared.projectData.contains(node) && node.owner == owner
      {
        view.textField?.isEditable = true
        view.textField?.font = NSFont.systemFont(ofSize: view.textField!.font!.pointSize, weight: NSFont.Weight.semibold)
      }
      else
      {
        view.textField?.isEditable = false
        view.textField?.font = NSFont.systemFont(ofSize: view.textField!.font!.pointSize, weight: NSFont.Weight.regular)
      }
      */
      
      view.textField?.stringValue = node.displayName
      
      
      
      if node.representedObject.isProjectGroup
      {
        view.imageView?.image = self.folderIcon
      }
      else
      {
        view.imageView?.image = self.cifFileIcon
      }
      
      if node.representedObject.lazyStatus == .loading || node.representedObject.lazyStatus == .error
      {
        view.progressIndicator?.isHidden = false
        view.cancelButton?.isHidden = false
      }
      else
      {
        view.progressIndicator?.isHidden = true
        view.cancelButton?.isHidden = true
      }
      
      view.textField?.isEditable = node.isEditable
      view.textField?.textColor = NSColor.controlTextColor
      
      if let documentData: DocumentData = self.windowController?.currentDocument?.documentData,
        node.isDescendantOfNode(documentData.cloudRootNode)
      {
        if !self.connectedToNetwork()
        {
          view.textField?.textColor = NSColor.gray
        }
      }
      
      if node.representedObject.lazyStatus == .error
      {
        view.textField?.textColor = NSColor.red
      }
      
      return view
    }
    
    return nil
  }
  
  func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument,
      let projectNode: ProjectTreeNode = item as? ProjectTreeNode
    {
      let projectTreeController: ProjectTreeController = document.documentData.projectData
      if projectTreeController.rootNodes.contains(projectNode)
      {
        return 22.0
      }
    }
    return 18.0
  }
  
  // MARK: Row-views
  // =====================================================================
  
  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView?
  {
    if let rowView: ProjectTableRowView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "projectTableRowView"), owner: self) as? ProjectTableRowView,
      let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      
      // during undo/redo, the NSTableRowViews were deleted. They are remade when needed, and here we set the 'secondaryHighlighted' to correct value
      if let node = item as? ProjectTreeNode
      {
        let projectTreeController: ProjectTreeController = document.documentData.projectData
  
        
        if (node == projectTreeController.selectedTreeNode)
        {
          rowView.isSelected = true
          rowView.secondaryHighlighted = true
        }
        else
        {
          if projectTreeController.selectedTreeNodes.contains(node)
          {
            rowView.isSelected = true
          }
          else
          {
            rowView.isSelected = false
          }
          rowView.secondaryHighlighted = false
        }
      }
      return rowView
    }

    return nil
  }
  
  func outlineView(_ outlineView: NSOutlineView, didAdd rowView: NSTableRowView, forRow row: Int)
  {
    if let rowView = rowView as? ProjectTableRowView,
       let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let projectTreeController: ProjectTreeController = document.documentData.projectData
      let selectedProjectRow = projectTreeController.selectedTreeNode == nil ? -1 : self.projectOutlineView?.row(forItem: projectTreeController.selectedTreeNode)
      
      rowView.isSelected = false
      rowView.secondaryHighlighted = false
      
      if let node: ProjectTreeNode = self.projectOutlineView?.item(atRow: row) as? ProjectTreeNode,
          projectTreeController.selectedTreeNodes.contains(node)
      {
        rowView.isSelected = true
      }
      
      if (row == selectedProjectRow)
      {
        rowView.isSelected = true
        rowView.secondaryHighlighted = true
      }
      //rowView.needsDisplay = true
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView, didRemove rowView: NSTableRowView, forRow row: Int)
  {
    if (row<0)
    {
      (rowView as? ProjectTableRowView)?.isSelected = false
      (rowView as? ProjectTableRowView)?.secondaryHighlighted = false
    }
  }
  
 
  
  // MARK: NSOutlineView methods for adding and removing projects
  // =====================================================================
  
  func addNode(_ treeNode: ProjectTreeNode, inItem: ProjectTreeNode?, atIndex: Int, animationOptions: NSTableView.AnimationOptions = [.slideRight])
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let projectData: ProjectTreeController = document.documentData.projectData
      //let realChildIndex = projectData.filteredChildIndexOfItem(inItem, index: atIndex)
      
      if let undoManager = document.undoManager
      {
        undoManager.registerUndo(withTarget: self, handler: {$0.removeNode(treeNode, fromItem: inItem, atIndex: atIndex)})
        if(!undoManager.isUndoing)
        {
          undoManager.setActionName(NSLocalizedString("Add project(s)", comment: "Add project"))
        }
      }
      
      
      projectData.insertNode(treeNode, inItem: inItem, atIndex: atIndex)
      
      if (filterContent)
      {
        // update filteredChildren
        inItem?.updateFilteredChildrenRecursively(projectData.filterPredicate)
        if let index: Int = inItem?.filteredAndSortedNodes.firstIndex(of: treeNode)
        {
          self.projectOutlineView?.insertItems(at: IndexSet(integer: index), inParent: inItem, withAnimation: animationOptions)
        }
      }
      else
      {
         self.projectOutlineView?.insertItems(at: IndexSet(integer: atIndex), inParent: inItem, withAnimation: animationOptions)
      }
      
      self.reloadSelection()
    }
    
    
  }
  
  func addCloudNode(_ node: ProjectTreeNode, parent: ProjectTreeNode)
  {
    let index: Int = parent.childNodes.binarySearch{ $0.displayName.lowercased() < node.displayName.lowercased() }
    if #available(OSX 10.12, *) { node.owner = CKCurrentUserDefaultName}
    else { node.owner = "__defaultOwner__"}  // CKOwnerDefaultName
    node.isEditable = false
    Cloud.shared.projectData.insertNode(node, inItem: parent, atIndex: index)
    
    let operation = SaveProjectToCloudOperation(proxyProjects: [node], parentNode: parent)
    Cloud.shared.cloudQueue.addOperation(operation)
    
    if (!filterContent)
    {
      self.projectOutlineView?.insertItems(at: IndexSet(integer: index), inParent: parent, withAnimation: .slideRight)
    }
  }
  
  func addCloudNode(_ treeNode: ProjectTreeNode, inItem: ProjectTreeNode?, atIndex: Int)
  {
    Cloud.shared.projectData.insertNode(treeNode, inItem: inItem, atIndex: atIndex)
    
    let operation = SaveProjectToCloudOperation(proxyProjects: [treeNode], parentNode: inItem)
    Cloud.shared.cloudQueue.addOperation(operation)
      
    if (!filterContent)
    {
      self.projectOutlineView?.insertItems(at: IndexSet(integer: atIndex), inParent: inItem, withAnimation: .slideRight)
    }
  }

  func removeNode(_ node: ProjectTreeNode, fromItem: ProjectTreeNode?, atIndex: Int, animationOptions: NSTableView.AnimationOptions = [.slideLeft, .effectFade])
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      if let undoManager = document.undoManager
      {
        let lastIndex: Int = node.indexPath.last ?? 0
        undoManager.registerUndo(withTarget: self, handler: {$0.addNode(node, inItem: fromItem, atIndex: lastIndex)})
        if(!undoManager.isUndoing)
        {
          undoManager.setActionName(NSLocalizedString("Remove project(s)", comment: "Remove project"))
        }
      }
   
      let fromItem: ProjectTreeNode? = node.parentNode
      let projectData: ProjectTreeController = document.documentData.projectData
      
      node.unwrapLazyLocalPresentedObjectIfNeeded()
      
      let index: Int? = fromItem?.filteredAndSortedNodes.firstIndex(of: node)
      
      projectData.removeNode(node)
      
    
      if (filterContent)
      {
        if let index: Int = index
        {
          self.projectOutlineView?.removeItems(at: IndexSet(integer: index), inParent: fromItem, withAnimation: animationOptions)
          
          // update filteredChildren
          fromItem?.updateFilteredChildrenRecursively(projectData.filterPredicate)
        }
      }
      else
      {
        self.projectOutlineView?.removeItems(at: IndexSet(integer: atIndex), inParent: fromItem, withAnimation: animationOptions)
      }
      
      self.reloadSelection()
    }
  }
  
  func removeCloudNode(_ node: ProjectTreeNode, fromItem: ProjectTreeNode?, atIndex: Int)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      if let undoManager = document.undoManager
      {
        let lastIndex: Int = node.indexPath.last ?? 0
        undoManager.registerUndo(withTarget: self, handler: {$0.addCloudNode(node, inItem: fromItem, atIndex: lastIndex)})
        if(!undoManager.isUndoing)
        {
          undoManager.setActionName(NSLocalizedString("Remove project(s)", comment: "Remove project"))
        }
      }
      
      
      let fromItem: Any? = node.parentNode
      
      Cloud.shared.projectData.removeNode(node)
      
      
      if (!filterContent)
      {
        self.projectOutlineView?.removeItems(at: IndexSet(integer: atIndex), inParent: fromItem, withAnimation: .slideLeft)
      }
    }
  }
  
  @IBAction func removeProject(_ sender: NSButton)
  {
    deleteSelection()
  }
  

  
  func moveNode(_ node: ProjectTreeNode, toItem: ProjectTreeNode?, childIndex: Int)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let nodeIndexPath: IndexPath = node.indexPath
      let lastIndex: Int = nodeIndexPath.last ?? 0
      let fromItem: ProjectTreeNode? = node.parentNode
    
      if let undoManager = document.undoManager
      {
        
        undoManager.setActionName(NSLocalizedString("Reorder projects", comment: "Reorder projects"))
        undoManager.registerUndo(withTarget: self, handler: {$0.moveNode(node, toItem: fromItem, childIndex: lastIndex)})
      }
      
      let index: Int? = fromItem?.filteredAndSortedNodes.firstIndex(of: node)
    
      // remove old node
      let projectData: ProjectTreeController = document.documentData.projectData
      projectData.removeNodeAtArrangedObjectIndexPath(nodeIndexPath)
    
      if (filterContent)
      {
        if let index: Int = index
        {
          self.projectOutlineView?.removeItems(at: IndexSet(integer: index), inParent: fromItem, withAnimation: [])
          fromItem?.updateFilteredChildrenRecursively(projectData.filterPredicate)
        }
      }
      else
      {
        self.projectOutlineView?.removeItems(at: IndexSet(integer: lastIndex), inParent: fromItem, withAnimation: [])
      }
    
      // insert new node
      projectData.insertNode(node, inItem: toItem, atIndex: childIndex)
      
      
      if (filterContent)
      {
        // update filteredChildren
        toItem?.updateFilteredChildrenRecursively(projectData.filterPredicate)
        if let index: Int = toItem?.filteredAndSortedNodes.firstIndex(of: node)
        {
          self.projectOutlineView?.insertItems(at: IndexSet(integer: index), inParent: toItem, withAnimation: [.effectGap])
        }
      }
      else
      {
        self.projectOutlineView?.insertItems(at: IndexSet(integer: childIndex), inParent: toItem, withAnimation: [.effectGap])
      }
      
      self.reloadSelection()
    }
  }

  func moveCloudNode(_ node: ProjectTreeNode, toItem: ProjectTreeNode?, childIndex: Int)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let nodeIndexPath: IndexPath = node.indexPath
      let fromItem: ProjectTreeNode? = node.parentNode
      
      if let undoManager = document.undoManager
      {
        let lastIndex: Int = nodeIndexPath.last ?? 0
        undoManager.setActionName(NSLocalizedString("Reorder projects", comment: "Reorder projects"))
        undoManager.registerUndo(withTarget: self, handler: {$0.moveCloudNode(node, toItem: fromItem, childIndex: lastIndex)})
      }
      
      // remove old node
      Cloud.shared.projectData.removeNodeAtArrangedObjectIndexPath(nodeIndexPath)
      
      if (!filterContent)
      {
        self.projectOutlineView?.removeItems(at: IndexSet(integer: nodeIndexPath.last ?? 0), inParent: fromItem, withAnimation: NSTableView.AnimationOptions())
      }
      
      // insert new node
      Cloud.shared.projectData.insertNode(node, inItem: toItem, atIndex: childIndex)
      
      if (!filterContent)
      {
        self.projectOutlineView?.insertItems(at: IndexSet(integer: childIndex), inParent: toItem, withAnimation: .effectGap)
      }
    }
  }


 

  // MARK: NSOutlineView required delegate methods for drag&drop
  // =====================================================================
  
  
  
  // enable the outlineView to be an NSDraggingSource that supports dragging multiple items.
  // Returns a custom object that implements NSPasteboardWriting protocol (or simply use NSPasteboardItem).
  // so here we return ProjectTreeNode which means ProjectTreeNode is put on the pastboard
  
 
  // Called from 'canDrag', the first method in a drag. Sets the nodes that need to be dragged, i.e. the local root-nodes for the various subtrees of the selection
  func dragItems(_ outlineView: NSOutlineView, item: ProjectTreeNode?) -> [ProjectTreeNode]
  {
    if let projectTreeController: ProjectTreeController = (windowController?.document as? iRASPADocument)?.documentData.projectData
    {
      var selection: Set<ProjectTreeNode> = projectTreeController.selectedTreeNodes
      if let item = item
      {
        selection.insert(item)
      }
      return projectTreeController.findLocalRootsOfSelectedSubTrees(selection: selection)
    }
    return []
  }
  
  func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting?
  {
    if let projectTreeController: ProjectTreeController = (windowController?.document as? iRASPADocument)?.documentData.projectData,
       let localRootsOfSelectedNodes = self.projectOutlineView?.localRootsOfSelectedNodes,
       let node: ProjectTreeNode = item as? ProjectTreeNode,
       localRootsOfSelectedNodes.contains(node)
    {
      var selection: Set<ProjectTreeNode> = projectTreeController.selectedTreeNodes
      selection.insert(node)
      
      return projectTreeController.copyOfSelectionOfSubTree(of: node, selection: selection, recursive: false)
    }
    
    return EmptyPasteboardItem()
  }
  
  
  // Required: Implement this method know when the given dragging session is about to begin and potentially modify the dragging session.
  // draggedItems: A array of items to be dragged, excluding items for which outlineView:pasteboardWriterForItem: returns nil.
  func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any])
  {
    // store the dragged-node locally
    self.draggedNodes=draggedItems as? [ProjectTreeNode] ?? []
    
    let location: NSPoint = session.draggingLocation
    let numberOfDragItems: Int = self.draggedNodes.count
    session.enumerateDraggingItems(options: [], for: nil, classes: [NSPasteboardItem.self], searchOptions: [:], using: { (draggingItem, index, stop) in
      
      let frame = draggingItem.draggingFrame
      let size: NSSize = frame.size
      let height: CGFloat = outlineView.rowHeight
      draggingItem.draggingFrame = NSMakeRect(location.x - 0.5 * size.width, location.y - height * CGFloat(index) + (CGFloat(numberOfDragItems) - 1.5) * height, size.width , size.height)
    })
  }

  // Optional: You can implement this optional delegate method to know when the dragging source operation ended at a specific location,
  //           such as the trash (by checking for an operation of NSDragOperationDelete).
  func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation)
  {
    
    // check whether dragged to trashcan
    if (operation == NSDragOperation.delete)
    {
      self.projectOutlineView?.beginUpdates()
      self.draggedNodes.reversed().forEach({node in
        if let index: Int = node.indexPath.last
        {
          self.removeNode(node, fromItem: node.parentNode, atIndex: index)
        }
      })
      self.projectOutlineView?.endUpdates()
    }
    self.draggedNodes = []
  }
  
  // Optional: Based on the mouse position, the outline view will suggest a proposed drop location. The data source may “retarget” a drop if desired by calling
  // setDropItem:dropChildIndex: and returning something other than NSDragOperationNone. You may choose to retarget for various reasons (for example, for
  // better visual feedback when inserting into a sorted position).
  public func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation
  {
    // can not drag a parent into its descendent
    if let document: iRASPADocument = windowController?.document as? iRASPADocument,
       let parentProjectTreeNode = item as? ProjectTreeNode
    {
      let projectController: ProjectTreeController = document.documentData.projectData
      
     
      // A 'drop on' is not allowed on anything but a ProjectGroup
      if index == NSOutlineViewDropOnItemIndex, !(parentProjectTreeNode.representedObject.isProjectGroup)
      {
        return []
      }
      
      // disallow dragging projects to the directory-trees of 'GALLERY' and 'ICLOUD PUBLIC'
      if parentProjectTreeNode.isDescendantOfNode(document.documentData.galleryRootNode) ||
         parentProjectTreeNode.isDescendantOfNode(document.documentData.cloudRootNode)
      {
        //return .copy
        return []
      }

      // dragging within the same project-outlineView
      if let draggingSource = info.draggingSource as? NSOutlineView, outlineView === draggingSource
      {
        for node: ProjectTreeNode in self.draggedNodes
        {
          // node can not be dragged to a descendant
          if projectController.isDescendantOfNode(parentProjectTreeNode, parentNode: node)
          {
            return []
          }
        }
      
        // a valid target is anything "under" projectLocalRootNode
        if parentProjectTreeNode.isDescendantOfNode(document.documentData.projectLocalRootNode)
        {
          // animate to destination
          info.animatesToDestination = true
          return .move
        }
        return []
      }
      else
      {
        if iRASPAWindowController.dragAndDropConcurrentQueue.operationCount > 0
        {
          return []
        }
        
        // animate to destination
        info.animatesToDestination = true
        
        // a valid target is anything "under" projectLocalRootNode
        if parentProjectTreeNode.isDescendantOfNode(document.documentData.projectLocalRootNode)
        {
          return .copy
        }
        return []
      }
    }
    
    // otherwise dropping not allowed
    return []
  }

  func itemsAreSiblings(_ node: ProjectTreeNode, parentItem: Any?) -> Bool
  {
    if let parentItem: ProjectTreeNode = parentItem as? ProjectTreeNode
    {
      return node.parentNode == parentItem
    }
    
    return false
  }
  
  // The data source should incorporate the data from the dragging pasteboard in the implementation of this method. You can get the data for the drop operation
  // from info using the draggingPasteboard method.
  func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool
  {
    if let draggingSource = info.draggingSource as? NSOutlineView, outlineView === draggingSource
    {
      // drag/drop occured within the same outlineView -> reordering
      return internalDrop(info: info, item: item, index: index)
    }
    else
    {
      // drag/drop occured from another outlineView -> inserting copies
      return externalDrop(info: info, item: item, index: index)
    }
  }
  
  // drag/drop occured within the same outlineView -> reordering
  func internalDrop(info: NSDraggingInfo, item: Any?, index: Int) -> Bool
  {
    var childIndex: Int = index
    var placeholders: [ProjectTreeNode] = []
    
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let projectController: ProjectTreeController = document.documentData.projectData
      let predicate = document.documentData.projectData.filterPredicate
      
      let toItem: ProjectTreeNode? = item as? ProjectTreeNode
      
      if (childIndex == NSOutlineViewDropOnItemIndex)
      {
        self.projectOutlineView?.expandItem(toItem)
        childIndex = 0
      }
      
      // use real child-Index
      childIndex = projectController.filteredChildIndexOfItem(toItem, index: childIndex)
      
      let savedObserveNotifications: Bool = observeNotifications
      self.observeNotifications = false
      
      self.projectOutlineView?.beginUpdates()
      
      
      for node: ProjectTreeNode in self.draggedNodes
      {
        // Moving it from within the same parent -> account for the remove, if it is past the oldIndex
        if (self.itemsAreSiblings(node, parentItem: item))
        {
          // Moving it from within the same parent! Account for the remove, if it is past the oldIndex
          if let oldIndex = node.parentNode?.childNodes.firstIndex(of: node) , childIndex > oldIndex
          {
            childIndex = childIndex - 1 // account for the remove
          }
        }
        
        if node.isDescendantOfNode(document.documentData.galleryRootNode)
        {
          if let placeholder = node.deepCopy
          {
            placeholder.isEditable = true
            placeholder.lockedChildren = false
            placeholder.updateFilteredChildrenRecursively(predicate)
            
            placeholders.append(placeholder)
            
            self.addNode(placeholder, inItem: toItem, atIndex: childIndex, animationOptions:  [.effectGap])
            
            placeholder.parentNode?.updateFilteredChildrenRecursively(predicate)
            placeholder.representedObject.isEdited = true
            
          }
        }
        else if node.isDescendantOfNode(document.documentData.cloudRootNode)
        {
          if let placeholder = node.shallowCopy
          {
            placeholder.isEditable = true
            placeholder.lockedChildren = false
            placeholder.updateFilteredChildrenRecursively(predicate)
            
            placeholders.append(placeholder)
            
            self.addNode(placeholder, inItem: toItem, atIndex: childIndex, animationOptions:  [.effectGap])
            
            placeholder.parentNode?.updateFilteredChildrenRecursively(predicate)
            placeholder.representedObject.isEdited = true
          }
        }
        else
        {
          placeholders.append(node)
          
          self.moveNode(node, toItem: toItem, childIndex: childIndex)
        }
        
        childIndex = childIndex + 1
      }
      
      
      info.enumerateDraggingItems(options: [.concurrent], for: self.projectOutlineView, classes: [NSPasteboardItem.self], searchOptions: [:], using: { (draggingItem, index, stop) in
        let node = placeholders[index]
        if let row: Int = self.projectOutlineView?.row(forItem: node), row>=0,
           let frame: NSRect = self.projectOutlineView?.frameOfCell(atColumn: 0, row: row),
           let height: CGFloat = self.projectOutlineView?.rowHeight
        {
          draggingItem.draggingFrame = NSMakeRect(frame.origin.x, frame.origin.y+height*(CGFloat(index)+1.0), frame.width, frame.height)
        }
      })
      
      
      self.projectOutlineView?.endUpdates()
      self.observeNotifications = savedObserveNotifications
    }
    return true
  }
  
  // drag/drop occured from another outlineView -> inserting copies
  func externalDrop(info: NSDraggingInfo, item: Any?, index: Int) -> Bool
  {
    var childIndex: Int = index
        
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      var insertionIndex: Int = 0
      
      let projectController: ProjectTreeController = document.documentData.projectData
      
      let toItem: ProjectTreeNode? = item as? ProjectTreeNode
      
      if (childIndex == NSOutlineViewDropOnItemIndex)
      {
        self.projectOutlineView?.expandItem(toItem)
        childIndex = 0
      }
      
      // use real child-Index
      childIndex = projectController.filteredChildIndexOfItem(toItem, index: childIndex)
      
      
      self.projectOutlineView?.beginUpdates()

      info.enumerateDraggingItems(options: [], for: self.projectOutlineView, classes: [ProjectTreeNode.self], searchOptions: [:], using: { (draggingItem , idx, stop)  in
        
        if let item: ProjectTreeNode = draggingItem.item as? ProjectTreeNode
        {
          self.addNode(item, inItem: toItem, atIndex: childIndex, animationOptions:  [.effectGap])
          
          childIndex += 1
          insertionIndex += 1
        
          // set the draggingframe for all pasteboard-items
          if let height: CGFloat = self.projectOutlineView?.rowHeight,
             let row: Int = self.projectOutlineView?.row(forItem: item), row>=0,
             let frame: NSRect = self.projectOutlineView?.frameOfCell(atColumn: 0, row: row),
             frame.width > 0, height > 0
          {
            // frameOfCell(atColumn:row:) not working in NSOutlineview 'Sourcelist'-style
            draggingItem.draggingFrame = NSMakeRect(frame.origin.x, frame.origin.y + height * CGFloat(insertionIndex - 1), frame.width, height)
          }
        }
      })
      
      self.projectOutlineView?.endUpdates()
    }
    
    return true
  }

  
  
  // NOTE: only used for drag&drop (not copy&paste) and not called when the item is an NSPasteboardItemDataProvider
  func outlineView(_ outlineView: NSOutlineView, namesOfPromisedFilesDroppedAtDestination dropDestination: URL, forDraggedItems items: [Any]) -> [String]
  {
    for node in self.draggedNodes
    {
      if let data: Data = node.pasteboardPropertyList(forType: NSPasteboardTypeProjectTreeNode) as? Data,
         let compressedData: Data = data.compress(withAlgorithm: .lzma)
      {
        let pathExtension: String = URL(fileURLWithPath: NSPasteboardTypeProjectTreeNode.rawValue).pathExtension
        let url: URL = dropDestination.appendingPathComponent(node.displayName).appendingPathExtension(pathExtension)
        do
        {
          try compressedData.write(to: url, options: .atomic)
        }
        catch
        {
          
        }
      }
    }
    return self.draggedNodes.map{$0.displayName}
  }

  
  // MARK: methods for reacting to Notifications
  // =====================================================================
  
  func restoreSelectedItems(_ parent: ProjectTreeNode)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let treeController: ProjectTreeController = document.documentData.projectData
      let updatedSelectedIndex: NSMutableIndexSet = NSMutableIndexSet()
      for node in parent.childNodes
      {
        if treeController.selectedTreeNodes.contains(node)
        {
          if let row: Int = self.projectOutlineView?.row(forItem: node), row >= 0
          {
            updatedSelectedIndex.add(row)
          }
        }
      }
      self.projectOutlineView?.selectRowIndexes(updatedSelectedIndex as IndexSet, byExtendingSelection: true)
    }
  }
  
  
  func outlineViewItemWillExpand(_ notification:Notification)
  {
  }
  
  func outlineViewItemDidExpand(_ notification:Notification)
  {
    if let treeNode: ProjectTreeNode = notification.userInfo?["NSObject"] as? ProjectTreeNode
    {
      treeNode.isExpanded = true
    }
  }
  
  func outlineViewItemWillCollapse(_ notification:Notification)
  {
  }
  
  func outlineViewItemDidCollapse(_ notification:Notification)
  {
    if let treeNode: ProjectTreeNode = notification.userInfo?["NSObject"] as? ProjectTreeNode
    {
      treeNode.isExpanded = false
    }
  }
  
  
  
  
  
 
  
  // MARK: Menu validation
  // =====================================================================
  
  
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      if (menuItem.action == #selector(addProjectGroupContextMenu))
      {
        if let row: Int = self.projectOutlineView?.clickedRow, row >= 0
        {
          if let item: ProjectTreeNode = self.projectOutlineView?.item(atRow: row) as? ProjectTreeNode
          {
            return item.isDescendantOfNode(document.documentData.projectLocalRootNode)
          }
          return false
        }
      }
      
      if (menuItem.action == #selector(addStructureProjectContextMenu(_:)))
      {
        if let row: Int = self.projectOutlineView?.clickedRow, row >= 0
        {
          if let item: ProjectTreeNode = self.projectOutlineView?.item(atRow: row) as? ProjectTreeNode
          {
            return item.isDescendantOfNode(document.documentData.projectLocalRootNode)
          }
          return false
        }
      }
      
      if (menuItem.action == #selector(deleteSelectionContextMenu))
      {
        let treeController: ProjectTreeController = document.documentData.projectData
        return treeController.selectedTreeNode != nil || treeController.selectedNodes.count > 0
      }
      
      if (menuItem.action == #selector(ProjectContextMenuStoreSelectionInCloud(_:)))
      {
        let treeController: ProjectTreeController = document.documentData.projectData
        return treeController.selectedTreeNode != nil || treeController.selectedNodes.count > 0
      }
      
      if (menuItem.action == #selector(addStructureProject(_:)))
      {
        return true
      }
      
      if (menuItem.action == #selector(addVASPProject(_:)))
      {
        return true
      }
      
      if (menuItem.action == #selector(addRASPAProject(_:)))
      {
        return true
      }
      
      if (menuItem.action == #selector(copy(_:)))
      {
        return (self.projectOutlineView?.selectedRowIndexes.count ?? 0) > 0
      }
      
      if (menuItem.action == #selector(paste(_:)))
      {
        return iRASPAWindowController.copyAndPasteConcurrentQueue.operationCount == 0
         // NSPasteboard.general.canReadObject(forClasses: [ProjectTreeNode.self], options: [:])
      }
      
      if (menuItem.action == #selector(cut(_:)))
      {
        return (self.projectOutlineView?.selectedRowIndexes.count ?? 0) > 0
      }
      
    }
    return true
  }
  
  
  // MARK: Context Menu
  // =====================================================================
  
  func menuNeedsUpdate(_ menu: NSMenu)
  {
    if let clickRow: Int = self.projectOutlineView?.clickedRow,
      let contextMenu: NSMenu = self.projectContextMenu, menu == contextMenu,
      let menu: NSMenuItem = menu.item(at: 0)
    {
      if let item: ProjectTreeNode = self.projectOutlineView?.item(atRow: clickRow) as? ProjectTreeNode
      {
        menu.title = "You clicked on: \(item.displayName)"
        menu.isEnabled = true
      }
      else
      {
        menu.title = "You didn't click on any rows..."
        menu.isEnabled = false
      }
    }
  }
  
  @IBAction func deleteSelectionContextMenu(_ sender: NSMenuItem)
  {
    self.deleteSelection()
  }
  
  @IBAction func addProjectGroupContextMenu(_ sender: NSMenuItem)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      var index=self.projectOutlineView?.clickedRow ?? -1
      var toItem: ProjectTreeNode? = nil
      
      
      if index < 0
      {
        toItem = document.documentData.projectLocalRootNode
        index=0
      }
      else
      {
        if let node: ProjectTreeNode = self.projectOutlineView?.item(atRow: index) as? ProjectTreeNode,
           node.isDescendantOfNode(document.documentData.projectLocalRootNode)
        {
          if node.representedObject.isProjectGroup
          {
            toItem = node
            index = 0
          }
          else
          {
            toItem = node.parentNode
            index = (node.indexPath.last ?? 0) + 1
          }
        }
        else
        {
          toItem = document.documentData.projectLocalRootNode
          index = 0
        }
      }
      
      
      let project: ProjectGroup = ProjectGroup(name: "New Group project")
      project.isEdited = true
      let node: ProjectTreeNode = ProjectTreeNode(representedObject: iRASPAProject(group: project))
      node.isDropEnabled = true
      node.matchesFilter = true
      
      NSAnimationContext.beginGrouping()
      self.projectOutlineView?.beginUpdates()
      
      NSAnimationContext.current.completionHandler = { () -> Void in
        self.reloadData()
      }
      
      self.addNode(node, inItem: toItem, atIndex: index)
      
      self.projectOutlineView?.endUpdates()
      NSAnimationContext.endGrouping()
    }
  }

  
  @IBAction func addStructureProjectContextMenu(_ sender: NSMenuItem)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      var index=self.projectOutlineView?.clickedRow ?? -1
      var toItem: ProjectTreeNode? = nil
      
      if index < 0
      {
        index=0
        toItem = document.documentData.projectLocalRootNode
      }
      else
      {
        if let node: ProjectTreeNode = self.projectOutlineView?.item(atRow: index) as? ProjectTreeNode,
           node.isDescendantOfNode(document.documentData.projectLocalRootNode)
        {
          if node.representedObject.isProjectGroup
          {
            toItem = node
            index = 0
          }
          else
          {
            toItem = node.parentNode
            index = (node.indexPath.last ?? 0) + 1
          }
        }
        else
        {
          index = 0
          toItem = document.documentData.projectLocalRootNode
        }
      }
      
      let sceneList: SceneList = SceneList(name: "New scenelist", scenes: [])
      let project: ProjectStructureNode = ProjectStructureNode(name: "New Structure project", sceneList: sceneList)
      project.isEdited = true
      
      let node: ProjectTreeNode = ProjectTreeNode(displayName: project.displayName, representedObject: iRASPAProject(structureProject: project))
      //node.status = .ready
      node.isDropEnabled = false
      node.matchesFilter = true
      
      NSAnimationContext.beginGrouping()
      self.projectOutlineView?.beginUpdates()
      
      NSAnimationContext.current.completionHandler = { () -> Void in
        self.reloadData()
      }
      
      self.addNode(node, inItem: toItem, atIndex: index)
      
      self.projectOutlineView?.endUpdates()
      NSAnimationContext.endGrouping()
    }
  }
  
  
  @IBAction func ProjectContextMenuStoreSelectionInCloud(_ sender: NSMenuItem)
  {
      if let document: iRASPADocument = windowController?.document as? iRASPADocument
      {
        let selectedObjects = document.documentData.projectData.selectedTreeNodes
        
        for node in selectedObjects
        {
          let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
          let url = downloadsDirectory.appendingPathComponent(node.displayName + ".cif")
          debugPrint("display \(node.displayName) url \(url)")
          //importStructureFiles([url], asSeparateProjects: true, onlyAsymmetricUnit: false, asMolecule: false)
          
          let displayName: String = (url.lastPathComponent as NSString).deletingPathExtension
            
            let string: String
            do
            {
              string = try String(contentsOf: url, encoding: String.Encoding.utf8)
              debugPrint("string \(string)")
            }
            catch
            {
              do
              {
                string = try String(contentsOf: url, encoding: String.Encoding.ascii)
              }
              catch let error
              {
                LogQueue.shared.warning(destination: windowController, message: "\(error.localizedDescription)")
                return
              }
            }
            
            //let  parser = SKCIFParser(displayName: displayName, string: string, windowController: nil, onlyAsymmetricUnit: false)
            
          
            let cifParser: SKCIFParser = SKCIFParser(displayName: displayName, string: string, windowController: nil)
            do
            {
              try cifParser.startParsing()
              let scene: Scene = Scene(parser: cifParser.scene)
              let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
              
              let uuid = node.representedObject.fileNameUUID
              node.representedObject = iRASPAProject(structureProject:   ProjectStructureNode.init(name: displayName, sceneList: sceneList))
              node.representedObject.fileNameUUID = uuid
              
              node.representedObject.storageType = .local
              node.representedObject.nodeType = .leaf
              node.representedObject.lazyStatus = .loaded
              
                
              //let loadingStatus: iRASPAProject = iRASPAProject(projectType: .structure, fileName: node.representedObject.fileNameUUID, nodeType: node.representedObject.nodeType, storageType: node.representedObject.storageType, lazyStatus: iRASPAProject.LazyStatus.loaded)
              
              
              //node.representedObject = loadingStatus
          }
          catch
          {
            
          }
          
          
          
          
          
            if let projectStructureNode: ProjectStructureNode = node.representedObject.loadedProjectStructureNode
            {
            // if no camera present yet (e.g. after cif-import), create one
               
              
            
              
              node.representedObject.loadedProjectStructureNode?.allStructures.forEach{$0.reComputeBoundingBox()}
              
              projectStructureNode.renderCamera = RKCamera()
                projectStructureNode.renderCamera?.initialized = true
                projectStructureNode.allStructures.forEach{$0.reComputeBoundingBox()}
                if let renderCamera = projectStructureNode.renderCamera
                {
                  renderCamera.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
                  renderCamera.resetCameraDistance()
                }
              
              
              // adjust the camera to a possible change of the window-size
              if let renderCamera = projectStructureNode.renderCamera
              {
                if let size: CGSize = self.windowController?.detailTabViewController?.renderViewController?.renderViewController.viewBounds
                {
                  renderCamera.updateCameraForWindowResize(width: Double(size.width), height: Double(size.height))
                }
              }
              
              
              node.representedObject.loadedProjectStructureNode?.allStructures.forEach{$0.reComputeBonds()}
              
           
          }
        }
      }
    self.reloadData()
  }
  
  @IBAction func ProjectContextMenuStoreSelectionInCloudSave(_ sender: NSMenuItem)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let selectedObjects = document.documentData.projectData.selectedTreeNodes
      
      
      let saveOperation: CKModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [], recordIDsToDelete: [])
      saveOperation.recordsToSave = []
      saveOperation.recordIDsToDelete = nil
      saveOperation.isAtomic = false
      saveOperation.database = CKContainer(identifier: "iCloud.nl.darkwing.iRASPA").publicCloudDatabase
      
      
      
      
      for node in selectedObjects
      {
          if let projectStructure: ProjectStructureNode = node.representedObject.loadedProjectStructureNode,
             let structure = projectStructure.allIRASPAStructures.first
          {
            
            let VSA: NSNumber = NSNumber(value: structure.renderStructureVolumetricNitrogenSurfaceArea ?? 0.0)
            let GSA: NSNumber = NSNumber(value: structure.renderStructureGravimetricNitrogenSurfaceArea ?? 0.0)
            let helium: NSNumber = NSNumber(value: structure.renderStructureHeliumVoidFraction ?? 0.0)
            let di: NSNumber = NSNumber(value: structure.renderStructureLargestCavityDiameter ?? 0.0)
            let df: NSNumber = NSNumber(value: structure.renderStructureRestrictingPoreLimitingDiameter ?? 0.0)
            let dif: NSNumber = NSNumber(value: structure.renderStructureLargestCavityDiameterAlongAViablePath ?? 0.0)
            let density: NSNumber = NSNumber(value: structure.renderStructureDensity ?? 0.0)
            let mass: NSNumber = NSNumber(value: structure.renderStructureMass ?? 0.0)
            let specificV: NSNumber = NSNumber(value: structure.renderStructureSpecificVolume ?? 0.0)
            let AccesibleV: NSNumber = NSNumber(value: structure.renderStructureAccessiblePoreVolume ?? 0.0)
            let Nchannels: NSNumber = NSNumber(value: structure.renderStructureNumberOfChannelSystems ?? 0)
            let Npockets: NSNumber = NSNumber(value: structure.renderStructureNumberOfInaccessiblePockets ?? 0)
            let dim: NSNumber = NSNumber(value: structure.renderStructureDimensionalityOfPoreSystem ?? 0)
            let type: NSString =  NSString(string: structure.renderStructureMaterialType ?? "Unspecified")
            node.representedObjectInfo =
              [ "vsa": VSA,
                "gsa": GSA,
                "voidfraction" : helium,
                "di" : di,
                "df" : df,
                "dif" : dif,
                "density" : density,
                "mass" : mass,
                "specific_v" : specificV,
                "accesible_v" : AccesibleV,
                "n_channels" : Nchannels,
                "n_pockets" : Npockets,
                "dim" : dim,
                "type" : type
            ]
          }
          //let parentRecordID = CKRecordID(recordName: parentId)
  
        let recordID: CKRecord.ID = CKRecord.ID(recordName: node.representedObject.fileNameUUID)
        let record: CKRecord = CKRecord(recordType: "ProjectNode", recordID: recordID)
         
          //record["displayName"] = node.representedObject.displayName as CKRecordValue
          //record["parent"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: parentId), action: CKRecord.Reference.Action.none)
          //record["type"] = node.representedObject.projectType.rawValue as CKRecordValue
          
          let representedObjectInfoData: Data = NSKeyedArchiver.archivedData(withRootObject: node.representedObjectInfo)
          record["representedObjectInfo"] = representedObjectInfoData as CKRecordValue
          
          let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(node.representedObject.fileNameUUID)
          
          let binaryEncoder: BinaryEncoder = BinaryEncoder()
          binaryEncoder.encode(node.representedObject, encodeRepresentedObject: true)
          let data = Data(binaryEncoder.data).compress(withAlgorithm: .lzma)!
          
          do
          {
            try data.write(to: url, options: .atomicWrite)
            record["representedObject"] = CKAsset(fileURL: url)
          }
          catch let error
          {
            debugPrint("Error icloud save \(error.localizedDescription)")
          }
          
          saveOperation.savePolicy = CKModifyRecordsOperation.RecordSavePolicy.changedKeys
          
          saveOperation.recordsToSave?.append(record)
      }
      
      Cloud.shared.cloudQueue.addOperations([saveOperation], waitUntilFinished: true)
      debugPrint("done!")
    }
  }
  
  /*
  @IBAction func ProjectContextMenuStoreSelectionInCloud2(_ sender: NSMenuItem)
  {
    debugPrint("ProjectContextMenuStoreSelectionInCloud")
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let selectedObjects = document.documentData.projectData.selectedTreeNodes
      
      for node in selectedObjects
      {
        debugPrint("node \(node.representedObject.fileNameUUID)")
        let loadingStatus: iRASPAProject = iRASPAProject(projectType: .structure, fileName: node.representedObject.fileNameUUID, nodeType: node.representedObject.nodeType, storageType: node.representedObject.storageType, lazyStatus: iRASPAProject.LazyStatus.loaded)
          
        node.representedObject = loadingStatus
        
        let operation: ImportProjectFromCloudOperation = ImportProjectFromCloudOperation(projectTreeNode: node, outlineView:  nil, forceFieldSets: document.forceFieldSets, reloadCompletionBlock: {
          
          if let projectStructureNode: ProjectStructureNode = node.representedObject.loadedProjectStructureNode
          {
          // if no camera present yet (e.g. after cif-import), create one
             
          
            
            node.representedObject.loadedProjectStructureNode?.allStructures.forEach{$0.reComputeBoundingBox()}
            
            projectStructureNode.renderCamera = RKCamera()
              projectStructureNode.renderCamera?.initialized = true
              projectStructureNode.allStructures.forEach{$0.reComputeBoundingBox()}
              if let renderCamera = projectStructureNode.renderCamera
              {
                renderCamera.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
                renderCamera.resetCameraDistance()
              }
            
            
            // adjust the camera to a possible change of the window-size
            if let renderCamera = projectStructureNode.renderCamera
            {
              if let size: CGSize = self.windowController?.detailTabViewController?.renderViewController?.renderViewController.viewBounds
              {
                renderCamera.updateCameraForWindowResize(width: Double(size.width), height: Double(size.height))
              }
            }
            
            
            node.representedObject.loadedProjectStructureNode?.allStructures.forEach{$0.reComputeBonds()}
            
          }
          
          let saveOperation: CKModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [], recordIDsToDelete: [])
          saveOperation.recordsToSave = []
          saveOperation.recordIDsToDelete = nil
          saveOperation.isAtomic = false
          saveOperation.database = CKContainer(identifier: "iCloud.nl.darkwing.iRASPA").publicCloudDatabase
          
          let recordID: CKRecord.ID = CKRecord.ID(recordName: node.representedObject.fileNameUUID)
          let record: CKRecord = CKRecord(recordType: "ProjectNode", recordID: recordID)
           
            //record["displayName"] = node.representedObject.displayName as CKRecordValue
            //record["parent"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: parentId), action: CKRecord.Reference.Action.none)
            //record["type"] = node.representedObject.projectType.rawValue as CKRecordValue
            
            //let representedObjectInfoData: Data = NSKeyedArchiver.archivedData(withRootObject: node.representedObjectInfo)
            //record["representedObjectInfo"] = representedObjectInfoData as CKRecordValue
            
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(node.representedObject.fileNameUUID)
            
            let binaryEncoder: BinaryEncoder = BinaryEncoder()
            binaryEncoder.encode(node.representedObject, encodeRepresentedObject: true)
            let data = Data(binaryEncoder.data).compress(withAlgorithm: .lzma)!
            
            do
            {
              try data.write(to: url, options: .atomicWrite)
              record["representedObject"] = CKAsset(fileURL: url)
            }
            catch let error
            {
              debugPrint("Error icloud save \(error.localizedDescription)")
            }
            saveOperation.savePolicy = CKModifyRecordsOperation.RecordSavePolicy.changedKeys
            
            saveOperation.recordsToSave?.append(record)
          
            Cloud.shared.cloudQueue.addOperations([saveOperation], waitUntilFinished: false)
        })
        
        Cloud.shared.cloudQueue.addOperations([operation], waitUntilFinished: true)
        
        
        
        node.representedObject.loadedProjectStructureNode?.allStructures.forEach{$0.setRepresentationForceField(forceField: $0.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)}
      }
      
     
      return
      
      let saveOperation: CKModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [], recordIDsToDelete: [])
      saveOperation.recordsToSave = []
      saveOperation.recordIDsToDelete = nil
      saveOperation.isAtomic = false
      saveOperation.database = CKContainer(identifier: "iCloud.nl.darkwing.iRASPA").publicCloudDatabase
      
      
      
      
      for node in selectedObjects
      {
          debugPrint("id \(node.representedObject.fileNameUUID)")
          if let projectStructure: ProjectStructureNode = node.representedObject.loadedProjectStructureNode,
             let structure = projectStructure.allIRASPAStructures.first
          {
            
            let VSA: NSNumber = NSNumber(value: structure.renderStructureVolumetricNitrogenSurfaceArea ?? 0.0)
            let GSA: NSNumber = NSNumber(value: structure.renderStructureGravimetricNitrogenSurfaceArea ?? 0.0)
            let helium: NSNumber = NSNumber(value: structure.renderStructureHeliumVoidFraction ?? 0.0)
            let di: NSNumber = NSNumber(value: structure.renderStructureLargestCavityDiameter ?? 0.0)
            let df: NSNumber = NSNumber(value: structure.renderStructureRestrictingPoreLimitingDiameter ?? 0.0)
            let dif: NSNumber = NSNumber(value: structure.renderStructureLargestCavityDiameterAlongAViablePath ?? 0.0)
            let density: NSNumber = NSNumber(value: structure.renderStructureDensity ?? 0.0)
            let mass: NSNumber = NSNumber(value: structure.renderStructureMass ?? 0.0)
            let specificV: NSNumber = NSNumber(value: structure.renderStructureSpecificVolume ?? 0.0)
            let AccesibleV: NSNumber = NSNumber(value: structure.renderStructureAccessiblePoreVolume ?? 0.0)
            let Nchannels: NSNumber = NSNumber(value: structure.renderStructureNumberOfChannelSystems ?? 0)
            let Npockets: NSNumber = NSNumber(value: structure.renderStructureNumberOfInaccessiblePockets ?? 0)
            let dim: NSNumber = NSNumber(value: structure.renderStructureDimensionalityOfPoreSystem ?? 0)
            let type: NSString =  NSString(string: structure.renderStructureMaterialType ?? "Unspecified")
            node.representedObjectInfo =
              [ "vsa": VSA,
                "gsa": GSA,
                "voidfraction" : helium,
                "di" : di,
                "df" : df,
                "dif" : dif,
                "density" : density,
                "mass" : mass,
                "specific_v" : specificV,
                "accesible_v" : AccesibleV,
                "n_channels" : Nchannels,
                "n_pockets" : Npockets,
                "dim" : dim,
                "type" : type
            ]
          }
          //let parentRecordID = CKRecordID(recordName: parentId)
  
        let recordID: CKRecord.ID = CKRecord.ID(recordName: node.representedObject.fileNameUUID)
        let record: CKRecord = CKRecord(recordType: "ProjectNode", recordID: recordID)
         
          //record["displayName"] = node.representedObject.displayName as CKRecordValue
          //record["parent"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: parentId), action: CKRecord.Reference.Action.none)
          //record["type"] = node.representedObject.projectType.rawValue as CKRecordValue
          
          let representedObjectInfoData: Data = NSKeyedArchiver.archivedData(withRootObject: node.representedObjectInfo)
          record["representedObjectInfo"] = representedObjectInfoData as CKRecordValue
          
          let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(node.representedObject.fileNameUUID)
          
        
          let binaryEncoder: BinaryEncoder = BinaryEncoder()
          binaryEncoder.encode(node.representedObject, encodeRepresentedObject: true)
          let data = Data(binaryEncoder.data).compress(withAlgorithm: .lzma)!
          
          do
          {
            try data.write(to: url, options: .atomicWrite)
            record["representedObject"] = CKAsset(fileURL: url)
          }
          catch let error
          {
            debugPrint("Error icloud save \(error.localizedDescription)")
          }
          
          //saveOperation.savePolicy = CKModifyRecordsOperation.RecordSavePolicy.changedKeys
          
          //saveOperation.recordsToSave?.append(record)
      }
      
      //Cloud.shared.cloudQueue.addOperations([saveOperation], waitUntilFinished: true)
      debugPrint("done!")
    }
  }*/
  
  @IBAction func ProjectContextMenuMakeSelectionEditable(_ sender: NSMenuItem)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let selectedObjects = document.documentData.projectData.selectedTreeNodes
      
      for node in selectedObjects
      {
        node.isEditable = true
      }
    }
  }
  
  @IBAction func ProjectContextMenuSetCloudToLoaded(_ sender: NSMenuItem)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let selectedObjects = document.documentData.projectData.selectedTreeNodes
      
      for node in selectedObjects
      {
        debugPrint("node.displayName: \(node.displayName)  \(node.representedObject.fileNameUUID)")
        let fileName = node.representedObject.fileNameUUID
        
        let projectStructureNode = ProjectStructureNode(name: node.displayName, sceneList: SceneList(scenes: []))
        let project = iRASPAProject(structureProject: projectStructureNode)
        projectStructureNode.fileName = node.representedObject.fileNameUUID
        node.representedObject = project
        node.representedObject.fileNameUUID = fileName        
        node.representedObject.lazyStatus = .loaded
        node.representedObject.nodeType = .leaf
        
      }
    }
  }
  
  @IBAction func ProjectContextMenuSetToCoreMOF(_ sender: NSMenuItem)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let selectedObjects = document.documentData.projectData.selectedTreeNodes
      
      for node in selectedObjects
      {
        if let projectStructureNode: ProjectStructureNode = node.representedObject.loadedProjectStructureNode
        {
          if let scene: Scene = projectStructureNode.sceneList.scenes.first
          {
            projectStructureNode.allStructures.forEach{scene.setToCoreMOFStyle(structure: $0)}
          }
        }
      }
    }
  }
  
  @IBAction func ProjectContextMenuSetToCoreMOFDDEC(_ sender: NSMenuItem)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let selectedObjects = document.documentData.projectData.selectedTreeNodes
      
      for node in selectedObjects
      {
        if let projectStructureNode: ProjectStructureNode = node.representedObject.loadedProjectStructureNode
        {
          if let scene: Scene = projectStructureNode.sceneList.scenes.first
          {
            projectStructureNode.allStructures.forEach{scene.setToDDECStyle(structure: $0)}
          }
        }
      }
    }
  }
  
  @IBAction func ProjectContextMenuMakeSelectionUnEditable(_ sender: NSMenuItem)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let selectedObjects = document.documentData.projectData.selectedTreeNodes
      
      for node in selectedObjects
      {
        node.isEditable = false
      }
    }
  }
  
  @IBAction func ProjectContextMenuComputePropertiesSelection(_ sender: NSMenuItem)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let selectedObjects = document.documentData.projectData.selectedTreeNodes
      
      for node in selectedObjects
      {
        if let projectStructure: ProjectStructureNode = node.representedObject.loadedProjectStructureNode
        {
          projectStructure.allStructures.forEach({$0.recomputeDensityProperties()})
          
          let results: [(minimumEnergyValue: Double, voidFraction: Double)] = SKVoidFraction.compute(structures: projectStructure.allStructures.map{($0.cell, $0.atomUnitCellPositions, $0.potentialParameters)}, probeParameters: SIMD2<Double>(10.9, 2.64))
            
          for (i, result) in results.enumerated()
          {
            projectStructure.allStructures[i].minimumGridEnergyValue = Float(result.minimumEnergyValue)
            projectStructure.allStructures[i].structureHeliumVoidFraction = result.voidFraction
          }
          
          do
          {
            let results: [Double] = try SKNitrogenSurfaceArea.compute(structures: projectStructure.allStructures.map{($0.cell, $0.atomUnitCellPositions, $0.potentialParameters)}, probeParameters: SIMD2<Double>(10.9, 2.64))
            for (i, result) in results.enumerated()
            {
              projectStructure.allStructures[i].structureNitrogenSurfaceArea = result
            }
          }
          catch let error
          {
            LogQueue.shared.error(destination: self.view.window?.windowController, message: error.localizedDescription)
          }
          
          projectStructure.allStructures.forEach({$0.recomputeDensityProperties()})
          
          projectStructure.allStructures.forEach({$0.setRepresentationStyle(style: .fancy, colorSets: document.colorSets)})
        }
      }
    }
  
  }

  
  // MARK: Add button
  // =====================================================================
  
  @IBAction func addProjectGroup(_ sender: AnyObject)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      var index = self.projectOutlineView?.selectedRow ?? -1
      var toItem: ProjectTreeNode? = nil
      
      
      if index < 0
      {
        toItem = document.documentData.projectLocalRootNode
        index=0
      }
      else
      {
        if let node: ProjectTreeNode = self.projectOutlineView?.item(atRow: index) as? ProjectTreeNode,
          node.isDescendantOfNode(document.documentData.projectLocalRootNode)
        {
          if node.representedObject.isProjectGroup
          {
            toItem = node
            index = 0
          }
          else
          {
            toItem = node.parentNode
            index = (node.indexPath.last ?? 0) + 1
          }
        }
        else
        {
          toItem = document.documentData.projectLocalRootNode
          index = 0
        }
      }
      
      
      let project: ProjectGroup = ProjectGroup(name: "New Group project")
      project.isEdited = true
      let iraspaproject: iRASPAProject = iRASPAProject(group: project)
      let node: ProjectTreeNode = ProjectTreeNode(representedObject: iraspaproject)
      node.isDropEnabled = true
      node.matchesFilter = true
      
      NSAnimationContext.beginGrouping()
      self.projectOutlineView?.beginUpdates()
      
      NSAnimationContext.current.completionHandler = { () -> Void in
        self.reloadData()
      }
      self.addNode(node, inItem: toItem, atIndex: index)
      
      self.projectOutlineView?.endUpdates()
      NSAnimationContext.endGrouping()
    }
  }
  
  @IBAction func addStructureProject(_ sender: AnyObject)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      var index = self.projectOutlineView?.selectedRow ?? -1
      var toItem: ProjectTreeNode? = nil
      
      if index < 0
      {
        index=0
        toItem = document.documentData.projectLocalRootNode
      }
      else
      {
        if let node: ProjectTreeNode = self.projectOutlineView?.item(atRow: index) as? ProjectTreeNode,
           node.isDescendantOfNode(document.documentData.projectRootNode)
        {
          if node.representedObject.isProjectGroup
          {
            toItem = node
            index = 0
          }
          else
          {
            toItem = node.parentNode
            index = (node.indexPath.last ?? 0) + 1
          }
        }
        else
        {
          index = 0
          toItem = document.documentData.projectLocalRootNode
        }
      }
      
      let sceneList: SceneList = SceneList(name: "New scenelist", scenes: [])
      let project: ProjectStructureNode = ProjectStructureNode(name: "New structure", sceneList: sceneList)
      project.isEdited = true
      
      let node: ProjectTreeNode = ProjectTreeNode(displayName: project.displayName, representedObject: iRASPAProject(structureProject: project))
      node.isDropEnabled = false
      node.matchesFilter = true
      
      NSAnimationContext.beginGrouping()
      self.projectOutlineView?.beginUpdates()
      
      NSAnimationContext.current.completionHandler = { () -> Void in
        self.reloadData()
      }
      
      self.addNode(node, inItem: toItem, atIndex: index)
      
      self.projectOutlineView?.endUpdates()
      NSAnimationContext.endGrouping()
    }
  }
  
  
  @IBAction func addVASPProject(_ sender: AnyObject)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      var index = self.projectOutlineView?.selectedRow ?? -1
      var toItem: ProjectTreeNode? = nil
      
      if index < 0
      {
        toItem = document.documentData.projectRootNode
        index=0
      }
      else
      {
        if let node: ProjectTreeNode = self.projectOutlineView?.item(atRow: index) as? ProjectTreeNode,
           node.isDescendantOfNode(document.documentData.projectRootNode)
        {
          if node.representedObject.isProjectGroup
          {
            toItem = node
            index = 0
          }
          else
          {
            toItem = node.parentNode
            index = (node.indexPath.last ?? 0) + 1
          }
        }
        else
        {
          toItem = document.documentData.projectRootNode
          index = 0
        }
      }
      
      
      let project: ProjectVASPNode = ProjectVASPNode(name: "VASP project")
      project.isEdited = true
      
      let node: ProjectTreeNode = ProjectTreeNode(displayName: "VASP project", representedObject: iRASPAProject(VASP: project))
      node.matchesFilter = true
      
      NSAnimationContext.beginGrouping()
      self.projectOutlineView?.beginUpdates()
      
      NSAnimationContext.current.completionHandler = { () -> Void in
        self.reloadData()
      }
      
      self.addNode(node, inItem: toItem, atIndex: index)
      
      self.projectOutlineView?.endUpdates()
      NSAnimationContext.endGrouping()
    }
  }

  @IBAction func addRASPAProject(_ sender: AnyObject)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      var index = self.projectOutlineView?.selectedRow ?? -1
      var toItem: ProjectTreeNode? = nil
      
      if index < 0
      {
        toItem = document.documentData.projectRootNode
        index=0
      }
      else
      {
        if let node: ProjectTreeNode = self.projectOutlineView?.item(atRow: index) as? ProjectTreeNode,
           node.isDescendantOfNode(document.documentData.projectRootNode)
        {
          if node.representedObject.isProjectGroup
          {
            toItem = node
            index = 0
          }
          else
          {
            toItem = node.parentNode
            index = (node.indexPath.last ?? 0) + 1
          }
        }
        else
        {
          toItem = document.documentData.projectRootNode
          index = 0
        }
      }
      
      
      let project: ProjectRASPANode = ProjectRASPANode(name: "RASPA project")
      project.isEdited = true
      let node: ProjectTreeNode = ProjectTreeNode(displayName: "RASPA project", representedObject: iRASPAProject(RASPA: project))
      node.isDropEnabled = false
      node.matchesFilter = true
      
      NSAnimationContext.beginGrouping()
      self.projectOutlineView?.beginUpdates()
      
      NSAnimationContext.current.completionHandler = { () -> Void in
        self.reloadData()
      }
      
      self.addNode(node, inItem: toItem, atIndex: index)
      
      self.projectOutlineView?.endUpdates()
      NSAnimationContext.endGrouping()
    }
  }

  
 
  
  // MARK: Selection handling
  // =====================================================================
  
  func setCurrentSelection(treeController: ProjectTreeController, newValue: (selected: ProjectTreeNode?, selection: Set<ProjectTreeNode>), oldValue: (selected: ProjectTreeNode?, selection: Set<ProjectTreeNode>))
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument,
      let undoManager: UndoManager = document.undoManager
    {
      if !undoManager.isUndoing
      {
        undoManager.setActionName(NSLocalizedString("Change project selection", comment: "Change project selection"))
      }
      
      // save off the current selectedNode and current selection for undo/redo
      undoManager.registerUndo(withTarget: self, handler: {[unowned treeController]  in
        $0.setCurrentSelection(treeController: treeController, newValue: oldValue, oldValue: newValue)})
      
      let switchToNewProject = newValue.selected != treeController.selectedTreeNode
      
    
      treeController.selectedTreeNode = newValue.selected
      treeController.selectedTreeNodes = newValue.selection
    
      NSAnimationContext.beginGrouping()
      
      NSAnimationContext.current.completionHandler = { () -> Void in
        if switchToNewProject
        {
          self.switchToCurrentProject()
        }
      }
      
      self.reloadSelection()
      
      NSAnimationContext.endGrouping()
    }
  }

  
  
  
  
  func reloadSelection()
  {
   
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let savedObserveNotifications: Bool = self.observeNotifications
      
      // avoid sending notification due to selection change
      self.observeNotifications = false
    
      self.projectOutlineView?.selectRowIndexes(IndexSet(), byExtendingSelection: false)
      
      
      let projectTreeController: ProjectTreeController = document.documentData.projectData
      
      if let selectedTreeNode = projectTreeController.selectedTreeNode,
         let selectedRow: Int = self.projectOutlineView?.row(forItem: selectedTreeNode), selectedRow >= 0
      {
        self.projectOutlineView?.enumerateAvailableRowViews({ (rowView, row) in
          if let rowView = rowView as? ProjectTableRowView
          {
            rowView.secondaryHighlighted = (row == selectedRow)
            rowView.needsDisplay = true
            self.projectOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
          }
        })
      }
      
      
      let selectedProjectNodes:[ProjectTreeNode] = projectTreeController.selectedNodes
      for node in selectedProjectNodes
      {
        if let row: Int = self.projectOutlineView?.row(forItem: node), row >= 0
        {
          self.projectOutlineView?.selectRowIndexes(NSIndexSet(index: row) as IndexSet, byExtendingSelection: true)
        }
      }
      
      let cloudKitTreeController: ProjectTreeController = Cloud.shared.projectData
      let selectedCloudNodes:[ProjectTreeNode] = cloudKitTreeController.selectedNodes
      for node in selectedCloudNodes
      {
        if let row: Int = self.projectOutlineView?.row(forItem: node), row >= 0
        {
          self.projectOutlineView?.selectRowIndexes(NSIndexSet(index: row) as IndexSet, byExtendingSelection: true)
        }
      }
      
      self.observeNotifications = savedObserveNotifications
    }
  }
  

  func reloadData()
  {
    self.reloadData(filter: true)
    
    // expand the 'PROJECTS'-item (without animation)
    // (otherwise nothing is shown and the expand-icon is hidden)
    NSAnimationContext.beginGrouping()
    NSAnimationContext.current.duration=0
    
    self.projectOutlineView?.expandItem(nil)
    if let documentData: DocumentData = (self.windowController?.document as? iRASPADocument)?.documentData
    {
      self.restoreExpandedState(nodes: documentData.projectData.rootNodes)
    }
    
    NSAnimationContext.endGrouping()
    
    setDetailViewController()
  }
  
  
  func reloadData(filter updateFilter: Bool)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      let savedObserveNotifications: Bool = observeNotifications
      self.observeNotifications = false
    
      let projectTreeController: ProjectTreeController = document.documentData.projectData
      let cloudKitTreeController: ProjectTreeController = Cloud.shared.projectData
      
      if (updateFilter)
      {
        projectTreeController.updateFilteredNodes()
        cloudKitTreeController.updateFilteredNodes()
      }
    
      // // Drops all the visible row views and cell views, and re-acquires them all. The selection is lost.
      self.projectOutlineView?.reloadData()
      
      if (filterContent)
      {
        self.projectOutlineView?.expandItem(nil, expandChildren: true)
      }
      
      let updatedSelectedIndex: NSMutableIndexSet = NSMutableIndexSet()
      
      
      
      if let selectedNode = projectTreeController.selectedTreeNode
      {
        projectTreeController.selectedTreeNodes.insert(selectedNode)
      }
      for node in projectTreeController.selectedNodes
      {
        if let row: Int = self.projectOutlineView?.row(forItem: node), row >= 0
        {
          updatedSelectedIndex.add(row)
        }
      }
      
      if let selectedNode = cloudKitTreeController.selectedTreeNode
      {
        cloudKitTreeController.selectedTreeNodes.insert(selectedNode)
      }
      for node in cloudKitTreeController.selectedNodes
      {
        if let row: Int = self.projectOutlineView?.row(forItem: node), row >= 0
        {
          updatedSelectedIndex.add(row)
        }
      }
      
      self.projectOutlineView?.selectRowIndexes(updatedSelectedIndex as IndexSet, byExtendingSelection: false)
      
      self.observeNotifications = savedObserveNotifications
    }
  }
  
  
  
  var selectedProject: ProjectTreeNode?
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument
    {
      if let projectTreeNode = document.documentData.projectData.selectedTreeNode
      {
        return projectTreeNode
      }
    }
    return nil
  }
  
  // MARK: Set and update detail views
  // =====================================================================
  
  func setDetailViewController()
  {
    if let proxyProject: ProjectTreeNode = selectedProject,
       let projectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      let sceneList: [SceneList] = [projectStructureNode.sceneList]
      let selectedArrangedObjects: [Any] = projectStructureNode.sceneList.scenes.isEmpty ? [[]] : sceneList
      let arrangedObjects: [Any] = projectStructureNode.sceneList.scenes.isEmpty ? [[]] : sceneList
      
      windowController?.setPageControllerObjects(arrangedObjects: arrangedObjects,  selectedArrangedObjects: selectedArrangedObjects, selectedIndex: 0)
      
      let secondArrangedObjects: [Any] = [projectStructureNode.sceneList.selectedScene?.selectedMovie?.selectedFrame ?? [] ]
      
      windowController?.setPageControllerFrameObject(arrangedObjects: secondArrangedObjects, selectedIndex: 0)
    }
    else
    {
      windowController?.setPageControllerObjects(arrangedObjects: [[]], selectedArrangedObjects: [[]], selectedIndex: 0)
      windowController?.setPageControllerFrameObject(arrangedObjects: [[]], selectedIndex: 0)
    }
  }
  
  // MARK: Switch to selected project
  // =====================================================================
  
  
  // Switches to a new current project. Occurs in 3 cases:
  // (1) when click on by the mouse to select a project or using the up/down-arrow keys ('outlineViewSelectionDidChange')
  // (2) when deleting the selection and the current project is set to nil
  // (3) after undo/redo
  func switchToCurrentProject()
  {
    if let proxyProject: ProjectTreeNode = selectedProject,
       let projectOutlineView = self.projectOutlineView,
       let document: iRASPADocument = self.windowController?.currentDocument
    {
      self.projectOutlineView?.makeItemVisible(item: proxyProject)
      if let row = self.projectOutlineView?.row(forItem: proxyProject)
      {
        self.projectOutlineView?.scrollRowToVisible(row)
        self.projectOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
      }
    
      do
      {
        try proxyProject.unwrapProject(outlineView: projectOutlineView, queue: self.projectQueue, colorSets: document.colorSets, forceFieldSets: document.forceFieldSets, reloadCompletionBlock: {
                self.switchToCurrentProject()
          })
          
        proxyProject.representedObject.loadedProjectStructureNode?.undoManager = proxyProject.representedObject.undoManager
      }
      catch let error
      {
        LogQueue.shared.error(destination: self.windowController, message: "(\(proxyProject.displayName))" + error.localizedDescription)
      }
      
      
        
      if let _: ProjectGroup = proxyProject.representedObject.project as? ProjectGroup
      {
        self.windowController?.masterTabViewController?.selectedTabViewItemIndex = DetailTabViewController.ProjectViewType.directoryBrowser.rawValue
        self.windowController?.detailTabViewController?.selectedTabViewItemIndex = DetailTabViewController.ProjectViewType.directoryBrowser.rawValue
      }
      
      if let _: ProjectVASPNode = proxyProject.representedObject.project as? ProjectVASPNode
      {
        self.windowController?.masterTabViewController?.selectedTabViewItemIndex = DetailTabViewController.ProjectViewType.structureVisualisation.rawValue
        self.windowController?.detailTabViewController?.selectedTabViewItemIndex = DetailTabViewController.ProjectViewType.VASP.rawValue
      }
      
      if let projectStructureNode: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
      {
        // if no camera present yet (e.g. after cif-import), create one
        if projectStructureNode.renderCamera == nil
        {
          projectStructureNode.renderCamera = RKCamera()
          projectStructureNode.renderCamera?.initialized = true
          projectStructureNode.allStructures.forEach{$0.reComputeBoundingBox()}
          if let renderCamera = projectStructureNode.renderCamera
          {
            renderCamera.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
            renderCamera.resetCameraDistance()
          }
        }
        
        // adjust the camera to a possible change of the window-size
        if let renderCamera = projectStructureNode.renderCamera
        {
          if let size: CGSize = self.windowController?.detailTabViewController?.renderViewController?.renderViewController.viewBounds
          {
            renderCamera.updateCameraForWindowResize(width: Double(size.width), height: Double(size.height))
          }
        }
        
        projectStructureNode.setInitialSelectionIfNeeded()
          self.windowController?.masterTabViewController?.selectedTabViewItemIndex = DetailTabViewController.ProjectViewType.structureVisualisation.rawValue
        self.windowController?.detailTabViewController?.selectedTabViewItemIndex = DetailTabViewController.ProjectViewType.structureVisualisation.rawValue
      }
      
      // propagate proxyProject
      self.windowController?.propagate(proxyProject, toChildrenOf: self.windowController!.contentViewController!)
      
      // update the render-view
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.setDetailViewController()
    }
    else
    {
      // propagate proxyProject
      self.windowController?.propagate(nil, toChildrenOf: self.windowController!.contentViewController!)
      
      // update the render-view
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.setDetailViewController()
    }
  }
  

  // Keep the TreeController's selection in-sync with the NSOutlineView
  // This method may be called multiple times with one new index added to the existing selection to find out if a particular index
  // can be selected when the user is extending the selection with the keyboard or mouse.
  // purpose: (1) restrict the selection to certain nodes, (2) keep controller's selection up to date.
  func outlineView(_ outlineView: NSOutlineView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet
  {
    let allowedSelection: NSMutableIndexSet = NSMutableIndexSet()
    
    if let document = windowController?.document as? iRASPADocument
    {
      for index in proposedSelectionIndexes
      {
        if let node: ProjectTreeNode = self.projectOutlineView?.item(atRow: index) as? ProjectTreeNode
        {
          if document.documentData.projectData.rootNodes.contains(node)
          {
            return self.projectOutlineView?.selectedRowIndexes ?? IndexSet()
          }
          
          if node.isDescendantOfNode(document.documentData.cloudRootNode),
            !connectedToNetwork()
          {
            return self.projectOutlineView?.selectedRowIndexes ?? IndexSet()
          }
        
        // allow selection of already loaded projects or projects that can be lazily loaded on request
        
          allowedSelection.add(index)
        }
      }
    }
      
      
    // when loading a large project, clicking the project is not allowed but still changes the selection
    // check if that happens and then return the old selection
    if(proposedSelectionIndexes.count == 1)
    {
      if let selectedRow: Int = proposedSelectionIndexes.first,
         let node: ProjectTreeNode = self.projectOutlineView?.item(atRow: selectedRow) as? ProjectTreeNode,
         node.representedObject.lazyStatus == .loading
      {
        // if the project is not present then it can not be selected unless it is loaded lazily
        return self.projectOutlineView?.selectedRowIndexes ?? IndexSet()
      }
    }
    
    return allowedSelection as IndexSet
  }

  
  func outlineViewSelectionDidChange(_ aNotification: Notification)
  {
    if let projectOutlineView = self.projectOutlineView,
      let document = windowController?.document as? iRASPADocument
    {
      let projectTreeController: ProjectTreeController = document.documentData.projectData
      if self.observeNotifications
      {
        
        if let undoManager: UndoManager = document.undoManager,
          let oldSelectedRow: Int = self.projectOutlineView?.row(forItem: document.documentData.projectData.selectedTreeNode),
          let selectedRows: IndexSet = self.projectOutlineView?.selectedRowIndexes, ((selectedRows.count == 1) || (!selectedRows.contains(oldSelectedRow))),
          let selectedRow: Int = self.projectOutlineView?.selectedRow, selectedRow >= 0
        {
          let projectTreeController: ProjectTreeController = document.documentData.projectData
          if (!undoManager.isUndoing && !undoManager.isRedoing)
          {
            // get selected rows and the main selected row (the last selected one)
            // Note: using the arrow-keys continues from the main selected row
            var projectSelectedTreeNode: ProjectTreeNode? = nil
            var projectSelectedTreeNodes: Set<ProjectTreeNode> = []
            
            for row in projectOutlineView.selectedRowIndexes
            {
              if let selectedNode: ProjectTreeNode = self.projectOutlineView?.item(atRow: row) as? ProjectTreeNode
              {
                projectSelectedTreeNodes.insert(selectedNode)
              }
            }
            
            if (selectedRow >= 0)
            {
              if let projectTreeNode: ProjectTreeNode = self.projectOutlineView?.item(atRow: selectedRow) as? ProjectTreeNode
              {
                projectSelectedTreeNode = projectTreeNode
                
                // selection set in 'selectionIndexesForProposedSelection', make sure that the selected project is included in that set
                if let selectedNode = projectSelectedTreeNode
                {
                  projectSelectedTreeNodes.insert(selectedNode)
                }
              }
            }
            
            self.setCurrentSelection(treeController: projectTreeController, newValue: (projectSelectedTreeNode,projectSelectedTreeNodes), oldValue: (projectTreeController.selectedTreeNode, projectTreeController.selectedTreeNodes))
          }
        }
        else
        {
          if let projectOutlineView = self.projectOutlineView
          {
            var projectSelectedTreeNode: ProjectTreeNode? = nil
            var projectSelectedTreeNodes: Set<ProjectTreeNode> = []
            
            projectSelectedTreeNodes = []
            for row in projectOutlineView.selectedRowIndexes
            {
              if let selectedNode: ProjectTreeNode = self.projectOutlineView?.item(atRow: row) as? ProjectTreeNode
              {
                projectSelectedTreeNodes.insert(selectedNode)
              }
            }
            projectSelectedTreeNode = nil
            if let selectedRow = self.projectOutlineView?.selectedRow, selectedRow >= 0,
               let selectedItem: ProjectTreeNode = self.projectOutlineView?.item(atRow: selectedRow) as? ProjectTreeNode
            {
              projectSelectedTreeNode = selectedItem
            }
            self.setCurrentSelection(treeController: projectTreeController, newValue: (projectSelectedTreeNode,projectSelectedTreeNodes), oldValue: (projectTreeController.selectedTreeNode, projectTreeController.selectedTreeNodes))
          }
        }
      }
    }
  }
  
  func pageControllerArrangedObjectsDidChange(_ notification: Notification)
  {
    if let document: iRASPADocument = windowController?.document as? iRASPADocument,
       let selectedIndex: Int = notification.userInfo?["selectedIndex"] as? Int
    {
      let treeController: ProjectTreeController = document.documentData.projectData
      
      if let proxyProject = treeController.selectedTreeNode,
         let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
      {
        let movies: [Movie] = project.sceneList.scenes.flatMap{$0.movies}
        let movie: Movie = movies[selectedIndex]
        if let indexPath: IndexPath = project.sceneList.indexPath(movie)
        {
          // clear old selection
          project.sceneList.selectedScene?.selectedMovie = nil
        
          // set new selection
          let selectedScene: Scene = project.sceneList.scenes[indexPath[0]]
          let selectedMovie: Movie = selectedScene.movies[indexPath[1]]
        
          project.sceneList.selectedScene = selectedScene
        
          selectedScene.selectedMovies = [selectedMovie]
          selectedScene.selectedMovie = selectedMovie
        }
      }
    }
  }

  
  func convertSelectionToFilteredSelection()
  {
    // avoid sending notification due to selection change
    let savedObserveNotifications: Bool = observeNotifications
    observeNotifications = false
    
    if let treeController: ProjectTreeController = (windowController?.document as? iRASPADocument)?.documentData.projectData
    {
      let selectedNodes:[ProjectTreeNode] = treeController.selectedNodes
      
      treeController.setSelectedNodes([])
      
      self.projectOutlineView?.selectRowIndexes(IndexSet(), byExtendingSelection: false)
      
      for node in selectedNodes
      {
        if let row: Int = self.projectOutlineView?.row(forItem: node), row >= 0
        {
          treeController.addSelectionNode(node)
          self.projectOutlineView?.selectRowIndexes(NSIndexSet(index: row) as IndexSet, byExtendingSelection: true)
        }
      }
    }
    
    observeNotifications = savedObserveNotifications
  }
  
  
  func deleteSelection()
  {
    NSAnimationContext.beginGrouping()
    self.projectOutlineView?.beginUpdates()
    
    if let indexes: IndexSet = self.projectOutlineView?.selectedRowIndexes, (indexes.count > 0)
    {
      let deletableProjects: [ProjectTreeNode] = indexes.compactMap{self.projectOutlineView?.item(atRow: $0) as? ProjectTreeNode}.filter{$0.isEditable}
      if let document: iRASPADocument = windowController?.document as? iRASPADocument, deletableProjects.count > 0
      {
        document.undoManager?.beginUndoGrouping()
        let treeController: ProjectTreeController = document.documentData.projectData
        
        // save-off the current selection for undo/redo
        self.setCurrentSelection(treeController: treeController, newValue: (nil,[]), oldValue: (treeController.selectedTreeNode, treeController.selectedTreeNodes))
        
        // enumerate reverse; start with last index (because then all other indices are still valid after remove)
        (indexes as NSIndexSet).enumerate(options: .reverse, using: { (index, stop) -> Void in
          if let node: ProjectTreeNode = self.projectOutlineView?.item(atRow: index) as? ProjectTreeNode
          {
            if node.isDescendantOfNode(document.documentData.projectRootNode),node.isEditable
            {
              self.removeNode(node, fromItem: node.parentNode, atIndex: node.indexPath.last ?? 0)
            }
          }
        })
        
        document.undoManager?.endUndoGrouping()
      }
    }
    
    self.projectOutlineView?.endUpdates()
    NSAnimationContext.endGrouping()
  }

  
  // MARK: Search and filter
  // =====================================================================
  
  
  @IBAction func updateFilterAction(_ sender: NSSearchField)
  {
    let searchString: String = sender.stringValue
    
    if (searchString.isEmpty)
    {
      // restore no filtering
      if let document: iRASPADocument = windowController?.document as? iRASPADocument
      {
        document.documentData.projectData.filterPredicate = {_ in return true}
        document.documentData.projectData.updateFilteredNodes()
        
        filterContent = false
        
        let savedObserveNotifications = observeNotifications
        self.observeNotifications = false
      
        // reload all available items and reacquire all views
        self.projectOutlineView?.reloadItem(nil, reloadChildren: true)
        self.reloadSelection()
      
        self.observeNotifications = savedObserveNotifications
        
        self.windowController?.detailTabViewController?.directoryViewController?.reloadData()
      }
    }
    else
    {
      // filter
      if let document: iRASPADocument = windowController?.document as? iRASPADocument
      {
        document.documentData.projectData.filterPredicate = {[weak document]
          projectTreeNode in
          
          // always show the local project root to allow dragging matching nodes to the local projects
          if (projectTreeNode === document?.documentData.projectRootNode) ||
            (projectTreeNode === document?.documentData.projectLocalRootNode)
          {
            return true
          }
          
          let nodeString =  projectTreeNode.displayName 
          return nodeString.range(of: searchString, options: [.caseInsensitive,.regularExpression]) != nil
        }
        filterContent = true
        
        document.documentData.projectData.updateFilteredNodes()
        
        let savedObserveNotifications = observeNotifications
        self.observeNotifications = false
        // reload all available items and reacquire all views
        self.projectOutlineView?.reloadData()
        self.convertSelectionToFilteredSelection()
        self.reloadSelection()

        self.observeNotifications = savedObserveNotifications
        
        self.windowController?.detailTabViewController?.directoryViewController?.reloadData()
      }
    }
    
  }
  
  // MARK: NSOutlineView rename on double-click
  // =====================================================================
  
  
  @objc func projectOutlineViewDoubleClick(_ sender: AnyObject)
  {
    if let clickedRow: Int = self.projectOutlineView?.clickedRow, clickedRow >= 0,
       let projectTreeNode: ProjectTreeNode = self.projectOutlineView?.item(atRow: clickedRow) as? ProjectTreeNode, projectTreeNode.isEditable
    {
      self.projectOutlineView?.editColumn(0, row: clickedRow, with: nil, select: false)
    }
  }
  
  
  func setProjectDisplayName(_ projectTreeNode: ProjectTreeNode, to newValue: String)
  {
    let oldName: String = projectTreeNode.displayName
    
    if let document: iRASPADocument = windowController?.document as? iRASPADocument,
       let undoManager = document.undoManager
    {
      undoManager.registerUndo(withTarget: self, handler: {$0.setProjectDisplayName(projectTreeNode, to: oldName)})
      
      if !undoManager.isUndoing
      {
        undoManager.setActionName(NSLocalizedString("Change project name", comment: "Change project name"))
      }
      projectTreeNode.displayName = newValue
      projectTreeNode.representedObject.displayName = newValue
      
      // reload item in the outlineView
      if let row: Int = self.projectOutlineView?.row(forItem: projectTreeNode), row >= 0
      {
        // work around bug that causes 'reloadItem' to not do anything
        if let column: Int = (self.projectOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "displayNameColumn")))
        {
          self.projectOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: column))
        }
      }
    
      projectTreeNode.representedObject.isEdited = true
      document.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func changeProjectDisplayName(_ sender: NSTextField)
  {
    let newValue: String = sender.stringValue
    
    if let row: Int = self.projectOutlineView?.selectedRow, row >= 0
    {
      if let projectTreeNode: ProjectTreeNode = self.projectOutlineView?.item(atRow: row) as? ProjectTreeNode, projectTreeNode.isEditable
      {
        setProjectDisplayName(projectTreeNode, to: newValue)
      }

      self.reloadData()
    }
  }

  // MARK: Copy / Paste / Cut / Delete
  // =====================================================================
  
  // Copy is a server-side operation where the current state of the selection is stored in a snapshot stored locally in each ProjectTreeNode
  // The operation is performed in the background to not block the UI. However, 'paste' is disabled for the duration of this operation.
  // It is possible to do another 'Copy' while a copy is in progress. The previous 'copy'-operations will be cancelled.
  @objc func copy(_ sender: AnyObject)
  {
    if let document: iRASPADocument = self.windowController?.document as? iRASPADocument
    {
      let treeController: ProjectTreeController = document.documentData.projectData
      
      // Check if the option-key (i.e. alt) is pressed during cmd-c. If so, then do a 'Deep Copy' instead of a 'Shallow Copy'
      let alternate: Bool = (sender as? NSMenuItem)?.isAlternate ?? false
      
      // copy&paste in via the general pasteboard
      let pasteboard = NSPasteboard.general
      
      let rootsOfSelectedNodes: [ProjectTreeNode] = treeController.findLocalRootsOfSelectedSubTrees(selection: treeController.selectedTreeNodes)
      let treeNodesToBeCopied: [ProjectTreeNode] = rootsOfSelectedNodes.compactMap{treeController.copyOfSelectionOfSubTree(of: $0, selection: treeController.selectedTreeNodes,recursive: alternate)}
      
      // run the copy in the background so that the UI is responsive
      DispatchQueue.global(qos: .userInitiated).async {
        
        if iRASPAWindowController.copyAndPasteConcurrentQueue.operationCount > 0
        {
          // Previous copy still running, so cancel all copy-operations
          iRASPAWindowController.copyAndPasteConcurrentQueue.cancelAllOperations()
        }
        
        
        // The final operation will be to clear the pasteboard and write the objects. This operation depends on all copy-operations,
        // e.g. all copy-operations must have finished before the objects are written.
        let writeObjectsToPasteboordOperation: BlockOperation = BlockOperation()
        weak var weakWriteObjectsToPasteboordOperation: BlockOperation? = writeObjectsToPasteboordOperation
        writeObjectsToPasteboordOperation.addExecutionBlock({
          if let strongWriteObjectsToPasteboordOperation = weakWriteObjectsToPasteboordOperation, strongWriteObjectsToPasteboordOperation.isCancelled
          {
            // Return immediately if cancelled
            return
          }
          DispatchQueue.main.async(execute: {
            pasteboard.clearContents()
            pasteboard.writeObjects(treeNodesToBeCopied)
          })
        })
        
        // A copy-operation is basically just creating a snapshot of the current state of the copied ProjectTreeNode.
        treeNodesToBeCopied.flatMap{$0.flattenedNodes()}.forEach{ projectTreeNode in
          
          // First make sure all involved ProjectTreeNodes are set as "TemporarilyLocked" and update the UI
          // Execute the 'snapshot'-operations _after_ this one has finished
          let updateMainUIBlock: BlockOperation = BlockOperation(block: {
            self.selectedProject?.isTemporarilyLocked = true
            if let proxyProject: ProjectTreeNode = self.selectedProject,
                   proxyProject.representedObject.fileNameUUID == projectTreeNode.representedObject.fileNameUUID
            {
              // reload all
              self.windowController?.detailTabViewController?.reloadData()
            }
          })
          let snapshotOperation: BlockOperation = BlockOperation()
          snapshotOperation.addDependency(updateMainUIBlock)
          OperationQueue.main.addOperation(updateMainUIBlock)
          
          weak var weakSnapshotOperation: BlockOperation? = snapshotOperation
          snapshotOperation.addExecutionBlock({
            if let strongSnapshotOperation = weakSnapshotOperation, strongSnapshotOperation.isCancelled
            {
              LogQueue.shared.info(destination: self.windowController, message: "Previous copy cancelled")
              // Return immediately if cancelled
              return
            }
            
            
            let data: Data = projectTreeNode.representedObject.projectData()
            
            if let strongSnapshotOperation = weakSnapshotOperation, strongSnapshotOperation.isCancelled
            {
              LogQueue.shared.info(destination: self.windowController, message: "Previous copy cancelled")
              // Return if cancellation requested
              return
            }
            
            // On the main queue, set the snapshot Data as a property of the ProjectTreeNode, unlock the ProjectTreeNode and update the UI
            DispatchQueue.main.async(execute: {
                projectTreeNode.representedObject.data = data
                self.selectedProject?.isTemporarilyLocked = false
                if let proxyProject: ProjectTreeNode = self.selectedProject ,
                       proxyProject.representedObject.fileNameUUID == projectTreeNode.representedObject.fileNameUUID
                {
                  // Reload and update the UI
                  self.windowController?.detailTabViewController?.reloadData()
                }
              })
          })
          
          // the write of the objects depends on finishing all snapshot-operations
          writeObjectsToPasteboordOperation.addDependency(snapshotOperation)
          iRASPAWindowController.copyAndPasteConcurrentQueue.addOperation(snapshotOperation)
        }
        iRASPAWindowController.copyAndPasteConcurrentQueue.addOperation(writeObjectsToPasteboordOperation)
      }
    }
  }
  
  @objc func paste(_ sender: AnyObject)
  {
    if let document: iRASPADocument = self.windowController?.document as? iRASPADocument
    {
      let pasteboard = NSPasteboard.general
      
      if let pasteboardItems: [Any] = pasteboard.readObjects(forClasses: [ProjectTreeNode.self], options: nil),
         let selectedRow: Int = self.projectOutlineView?.selectedRow,
         let selectedProject: ProjectTreeNode = self.projectOutlineView?.item(atRow: selectedRow) as? ProjectTreeNode,
         let isExpandable: Bool = self.projectOutlineView?.isExpandable(selectedProject),
         let parentProject: ProjectTreeNode = self.projectOutlineView?.parent(forItem: selectedProject) as? ProjectTreeNode,
         let childIndex: Int = self.projectOutlineView?.childIndex(forItem: selectedProject),
         selectedProject.isDescendantOfNode(document.documentData.projectLocalRootNode)
      {
        let toItem: ProjectTreeNode = isExpandable ? selectedProject : parentProject
        var insertionIndex: Int = isExpandable ? 0 : childIndex + 1
        
        self.projectOutlineView?.beginUpdates()
        for pasteboardItem in pasteboardItems
        {
          if let placeholder =  pasteboardItem as? ProjectTreeNode
          {
            self.addNode(placeholder, inItem: toItem, atIndex: insertionIndex, animationOptions:  [.effectGap])
            insertionIndex += 1
          }
          else
          {
            LogQueue.shared.info(destination: self.windowController, message: "Pasted item of unknown type skipped")
          }
        }
        self.projectOutlineView?.endUpdates()
      }
    }
  }
  
  @objc func cut(_ sender: AnyObject)
  {

  }
}

