/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2019 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl            http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 scaldia@upo.es                http://www.upo.es/raspa/sofiacalero.php
 t.j.h.vlugt@tudelft.nl        http://homepage.tudelft.nl/v9k6y
 
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
import RenderKit
import iRASPAKit
import simd
import OperationKit


// protocol extension to pass the windowController recursively to all NSViewControllers
extension WindowControllerConsumer
{
  // if called in 'WindowDidLoad', using:
  // propagate(self, toChildrenOf: self.contentViewController!)
  // then all view-controllers will have 'windowController' set _before_ 'viewDidLoad'
  // except for lazily-loaded viewcontroller (e.g. contentViews)
  func propagateWindowController(_ windowController: iRASPAWindowController?, toChildrenOf parent: NSViewController)
  {
    if let consumer: WindowControllerConsumer = parent as? WindowControllerConsumer
    {
      consumer.windowController = windowController
    }
    
    for child in parent.children
    {
      propagateWindowController(windowController, toChildrenOf: child)
    }
  }
}

extension WindowControllerConsumer
{
  // if called in 'WindowDidLoad', using:
  // propagate(self, toChildrenOf: self.contentViewController!)
  // then all view-controllers will have 'windowController' set _before_ 'viewDidLoad'
  // except for lazily-loaded viewcontroller (e.g. contentViews)
  func propagateFlags(_ flags: NSEvent.ModifierFlags, toChildrenOf parent: NSViewController)
  {
    if let consumer: GlobalModifierFlagsConsumer = parent as? GlobalModifierFlagsConsumer
    {
      consumer.globalModifierFlagsChanged(flags)
    }
    
    for child in parent.children
    {
      propagateFlags(flags, toChildrenOf: child)
    }
  }
}

class iRASPAWindowController: NSWindowController, NSMenuItemValidation, WindowControllerConsumer, NSSharingServicePickerDelegate, NSSharingServiceDelegate, NSWindowDelegate, NSOpenSavePanelDelegate
{
  @IBOutlet private weak var actionButton: NSButton?
  
  // fulfill the WindowControllerConsumer protocol-requirement
  weak var windowController: iRASPAWindowController?
  weak var currentDocument: iRASPADocument?
  
  // set by the appropriate viewcontrollers during 'propagateWindowController'
  // masterTabViewController: controls the master-view (for Structure, DirectoryViewer, VASP etc)
  // detailTabViewController: controls the detail-view (for Structure, DirectoryViewer, VASP etc)
  weak var masterTabViewController: (MasterTabViewController & Reloadable)?
  weak var detailTabViewController: (DetailTabViewController & Reloadable)?
  
  lazy var projectSerialQueue: FKOperationQueue = {
    var queue = FKOperationQueue()
    queue.name = "WindowController serial queue"
    queue.qualityOfService = .userInitiated
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
  
  lazy var projectConcurrentQueue: FKOperationQueue = {
    var queue = FKOperationQueue()
    queue.name = "WindowController concurrent queue"
    queue.qualityOfService = .userInitiated
    queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
    return queue
  }()

  static public var globalConcurrentQueue: FKOperationQueue = {
    var queue = FKOperationQueue()
    queue.name = "WindowController global concurrent queue"
    queue.qualityOfService = .userInitiated
    queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
    return queue
  }()
  
  static public var copyAndPasteConcurrentQueue: FKOperationQueue = {
    var queue = FKOperationQueue()
    queue.name = "Copy/paste concurrent queue"
    queue.qualityOfService = .userInitiated
    queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
    return queue
  }()
  
  static public var dragAndDropConcurrentQueue: FKOperationQueue = {
    var queue = FKOperationQueue()
    queue.name = "Drag/drop concurrent queue"
    queue.qualityOfService = .userInitiated
    queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
    return queue
  }()
    
  override func windowDidLoad()
  {
    super.windowDidLoad()

    // Buttons triggering the Sharing Service Picker should be invoked on mouse down, not mouse up.
    self.actionButton?.sendAction(on: NSEvent.EventTypeMask.leftMouseDown)
    self.actionButton?.toolTip = "Share selected projects"
    
    propagateWindowController(self, toChildrenOf: self.contentViewController!)
  }
  
  func propagate(_ proxyProject: ProjectTreeNode?, toChildrenOf parent: NSViewController)
  {
    if let consumer: ProjectConsumer = parent as? ProjectConsumer
    {
      consumer.proxyProject = proxyProject
    }
    if let consumer: ProjectConsumer = parent.view as? ProjectConsumer
    {
      consumer.proxyProject = proxyProject
    }
    
    for child in parent.children
    {
      propagate(proxyProject, toChildrenOf: child)
    }
  }
  

  func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager?
  {
    return (self.document as? iRASPADocument)?.undoManager
  }

  
  // MARK: Import data
  // ===============================================================================================================================
  
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
  
  @IBAction func importProject(_ sender: NSButton)
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
        
          self.masterTabViewController?.projectViewController?.importStructureFiles(openPanel.urls as [URL], asSeparateProjects: asSeparateProjects, onlyAsymmetricUnit: onlyAsymmetricUnit, asMolecule: asMolecule)
        }
      }
    }
  }
  
  
  // MARK: Sharing
  // ===============================================================================================================================
  
  @IBAction func shareAction(_ sender : NSButton)
  {
    if let document: iRASPADocument = self.document as? iRASPADocument
    {
      let selectedProjectNodes: [ProjectTreeNode] = document.documentData.projectData.selectedNodes
      let cloudNodes: [ProjectTreeNode] = Cloud.shared.projectData.selectedNodes
      let projectTreeNodes: [ProjectTreeNode] =  selectedProjectNodes + cloudNodes
      
      let sharingServicePicker: NSSharingServicePicker = NSSharingServicePicker(items: ["The structures can be found as attachments. Drag these from this mail into the iRASPA project-view."] +  projectTreeNodes)
      sharingServicePicker.delegate = self
      sharingServicePicker.show(relativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.minX)
    }
   }
  
  override func flagsChanged(with event: NSEvent)
  {
    propagateFlags(event.modifierFlags, toChildrenOf: self.contentViewController!)
    super.flagsChanged(with: event)
  }
  
  func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService]
  {
    let emailService: NSSharingService? = NSSharingService(named: NSSharingService.Name.composeEmail)
    let airDropService: NSSharingService? = NSSharingService(named: NSSharingService.Name.sendViaAirDrop)
    
    emailService?.delegate = self
    airDropService?.delegate = self
    
    // only selected the ones that are available (airdrop is only available when wifi is supported,
    // email when an email-client is installed)
    return [emailService, airDropService].compactMap{$0}
  }
  
  func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?)
  {
    service?.subject = "iRASPA structure(s)"
  }

  // MARK: Collapsing panels
  // ===============================================================================================================================
  
  weak var leftSplitViewItem: NSSplitViewItem?
  {
    return (self.window?.contentViewController as? NSSplitViewController)?.splitViewItems[0]
  }
 
  @IBAction func toggleProjectView(_ sender : NSSegmentedControl)
  {
    switch(sender.selectedSegment)
    {
    case 0:
      if let leftSplitViewItem = leftSplitViewItem
      {
        leftSplitViewItem.animator().isCollapsed = !leftSplitViewItem.isCollapsed
      }
    case 1:
      if let bottomSplitViewItem = detailTabViewController?.bottomSplitViewItem
      {
        bottomSplitViewItem.animator().isCollapsed = !bottomSplitViewItem.isCollapsed
      }
    case 2:
      if let rightSplitViewItem = detailTabViewController?.rightSplitViewItem
      {
        rightSplitViewItem.animator().isCollapsed = !rightSplitViewItem.isCollapsed
      }
    default:
      break
    }
  }
  
  
  func windowWillEnterVersionBrowser(_ aNotification: Notification)
  {
    
  }
  
  
  func windowDidExitVersionBrowser(_ aNotification: Notification)
  {
  }
  
  // set the render-quality to medium at the start of a window resize
  func windowWillStartLiveResize(_ notification: Notification)
  {
    self.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
  }
  
  // set the render-quality to high _after_ a window resize
  func windowDidEndLiveResize(_ notification: Notification)
  {
    self.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
    self.detailTabViewController?.renderViewController?.redraw()
  }
  
  // MARK: Menu and validation
  // ===============================================================================================================================
  
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
  {
    if (menuItem.action == #selector(importProject(_:)))
    {
      return self.masterTabViewController?.masterViewController?.selectedTab == 0
    }
    
    //if (menuItem.action == #selector(exportProject(_:)))
    //{
    //  return self.masterTabViewController?.masterViewController?.selectedTab == 0
    //}
    
    return true
  }
  
  
  @IBAction func setPictureAspectRatioMenu(_ sender: AnyObject)
  {
    if let sender: NSMenuItem = sender as? NSMenuItem
    {
      let menuArray: [NSMenuItem] = sender.menu!.items
      for submenu in menuArray
      {
        submenu.state = NSControl.StateValue.off
      }
    
      sender.state = NSControl.StateValue.on
    
      let aspectRatio = RenderTabViewController.WindowAspectRatio(rawValue: sender.tag)!
      self.detailTabViewController?.renderViewController?.setfixedAspectRatio(ratio: aspectRatio)
    }
  }
  
  
  func masterViewControllerTabChanged(tab: Int)
  {
    if let structurePageController: StructurePageController = detailTabViewController?.structureDetailTabViewController
    {
      structurePageController.masterViewControllerTabChanged(tab: tab)
    }
  }
  
  func masterViewControllerSelectionChanged(tab: Int)
  {
    if let structurePageController: StructurePageController = detailTabViewController?.structureDetailTabViewController
    {
      structurePageController.masterViewControllerSelectionChanged(tab: tab)
    }
  }
  
  func detailViewControllerSelectionChanged(index: Int)
  {
    masterTabViewController?.masterViewController?.setSelectionIndex(index: index)
  }
}
