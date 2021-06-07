/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2021 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import simd
import LogViewKit
import RenderKit
import iRASPAKit
import SymmetryKit
import SimulationKit
import MathKit

class StructureAtomDetailViewController: NSViewController, NSMenuItemValidation, WindowControllerConsumer, NSOutlineViewDataSource, NSOutlineViewDelegate, ProjectConsumer, Reloadable
{
  @IBOutlet private weak var atomOutlineView: AtomOutlineView?
  @IBOutlet private weak var atomNetChargeTextField: AtomNetChargeTextField?
  @IBOutlet private var atomContextMenu: NSMenu?
  
  weak var windowController: iRASPAWindowController?
  
  // MARK: protocol ProjectConsumer
  // =====================================================================

  weak var proxyProject: ProjectTreeNode?
  
  var observeNotifications: Bool = true
  var filterContent: Bool = false
  
  
  private var draggedNodes: [Any] = []
 
  var fractionalFormatter: FractionalNumberFormatter = FractionalNumberFormatter()
  var cartesianFormatter: CartesianNumberFormatter = CartesianNumberFormatter()
  var chargeFormatter: ChargeNumberFormatter = ChargeNumberFormatter()
  var fullPrecisionNumberFormatter: FullPrecisionNumberFormatter = FullPrecisionNumberFormatter()
  
  // ViewDidLoad: bounds are not yet set (do not do geometry-related etup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    self.atomOutlineView?.dataSource = nil
    self.atomOutlineView?.delegate = nil
    
    // check that it works with strong-references off (for compatibility with 'El Capitan')
    self.atomOutlineView?.stronglyReferencesItems = false
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    
    self.atomOutlineView?.registerForDraggedTypes([NSPasteboardTypeAtomTreeNode])
    
    self.atomOutlineView?.setDraggingSourceOperationMask(.every, forLocal: true)
    self.atomOutlineView?.setDraggingSourceOperationMask(.every, forLocal: false)
    
    self.atomOutlineView?.doubleAction = #selector(atomOutlineViewDoubleClick(_:))
  }
  
  @objc func atomOutlineViewDoubleClick(_ sender: AnyObject)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let clickedColumn: Int = self.atomOutlineView?.clickedColumn,
       let clickedRow: Int = self.atomOutlineView?.clickedRow, clickedRow >= 0
    {
      if clickedColumn >= 0
      {
        if let identifier: String = self.atomOutlineView?.tableColumns[clickedColumn].identifier.rawValue
        {
          switch(identifier)
          {
          case "atomNameColumn", "atomElementColumn", "atomUniqueForceFieldIdentifierColumn", "atomPositionXColumn", "atomPositionYColumn", "atomPositionZColumn", "atomChargeColumn":
            self.atomOutlineView?.editColumn(clickedColumn, row: clickedRow, with: nil, select: false)
          default:
            break
          }
        }
      }
      else
      {
        if let node: SKAtomTreeNode = self.atomOutlineView?.item(atRow: clickedRow) as? SKAtomTreeNode,
           node.representedObject.symmetryType == .container
        {
          self.atomOutlineView?.editColumn(-1, row: clickedRow, with: nil, select: false)
        }
      }
    }
  }
  
  override func viewWillAppear()
  {
    self.atomOutlineView?.needsLayout = true
    super.viewWillAppear()
    
    self.atomOutlineView?.dataSource = self
    self.atomOutlineView?.delegate = self
    
    self.reloadData()
  }
  
  override func viewDidAppear()
  {
    super.viewDidAppear()
    
    NotificationCenter.default.addObserver(self, selector: #selector(StructureAtomDetailViewController.setSelectionFromExternalSource), name: NSNotification.Name(rawValue: NotificationStrings.RendererSelectionDidChangeNotification), object: (self.representedObject as? iRASPAStructure)?.structure)
    
    NotificationCenter.default.addObserver(self, selector: #selector(StructureAtomDetailViewController.reloadAllData), name: NSNotification.Name(rawValue: NotificationStrings.AtomsShouldReloadNotification), object: (self.representedObject as? iRASPAStructure)?.structure)
  }
  
  override func viewWillDisappear()
  {
    super.viewWillDisappear()
    
    self.atomOutlineView?.dataSource = nil
    self.atomOutlineView?.delegate = nil
    
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationStrings.RendererSelectionDidChangeNotification), object: (self.representedObject as? iRASPAStructure)?.structure)
    
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationStrings.AtomsShouldReloadNotification), object: (self.representedObject as? iRASPAStructure)?.structure)
  }
  
  
  
  
  func updateNetChargeTextField()
  {
    if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let asymmetricAtoms: [SKAsymmetricAtom] = structure.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
      let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
      let netCharge: Double = atoms.map{$0.asymmetricParentAtom.charge}.reduce(0.0, +)
      self.atomNetChargeTextField?.doubleValue = netCharge
    }
    else
    {
      self.atomNetChargeTextField?.stringValue = ""
    }
  }
  
  @objc func reloadAllData()
  {
    self.reloadData(filter: true)
    self.programmaticallySetSelection()
    self.updateNetChargeTextField()
  }
  
  func reloadData()
  {
    self.reloadData(filter: true)
    self.programmaticallySetSelection()
    self.updateNetChargeTextField()
  }
  
  func reloadDataFull()
  {
    self.reloadData(filter: true)
  }
  
  
  func reloadData(filter updateFilter: Bool)
  {
    if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let treeController: SKAtomTreeController = structure.atomTreeController
      self.observeNotifications = false
      
      if (updateFilter)
      {
        treeController.updateFilteredNodes()
      }
      
      // Drops all the visible row views and cell views, and re-acquires them all. The selection is lost.
      self.atomOutlineView?.reloadData()
      
      if (filterContent)
      {
        self.atomOutlineView?.expandItem(nil, expandChildren: true)
      }
      
      
      let updatedSelectedIndex: NSMutableIndexSet = NSMutableIndexSet()
      
      for node in treeController.selectedNodes
      {
        if let row: Int = self.atomOutlineView?.row(forItem: node), row >= 0
        {
          updatedSelectedIndex.add(row)
        }
      }
      
      self.atomOutlineView?.selectRowIndexes(updatedSelectedIndex as IndexSet, byExtendingSelection: false)
      
      self.observeNotifications = true
    }
    else
    {
      // Drops all the visible row views and cell views, and re-acquires them all. The selection is lost.
      self.atomOutlineView?.reloadData()
    }
    
    
    self.updateNetChargeTextField()
  }
  
  
  
  
  // MARK: NSOutlineView notifications for expanding/collapsing items
  // =====================================================================
  
  /*
  func outlineViewItemDidExpand(_ notification:Notification)
  {
    let dictionary: AnyObject  = notification.userInfo?["NSObject"] as AnyObject
    if let index: Int = self.atomOutlineView?.childIndex(forItem: dictionary)
    {
      self.expandedItems[index] = true
    }
  }
  
  
  func outlineViewItemDidCollapse(_ notification:Notification)
  {
    let dictionary: AnyObject  = notification.userInfo?["NSObject"] as AnyObject
    if let index: Int = self.atomOutlineView?.childIndex(forItem: dictionary)
    {
      self.expandedItems[index] = false
    }
  }
  
*/
  
  
  // MARK: NSOutlineView required datasource methods
  // =====================================================================
  
  
  // Returns the number of child items encompassed by a given item
  
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int
  {
    if(item==nil)
    {
      if let structure: Structure =  (self.representedObject as? iRASPAStructure)?.structure
      {
        return filterContent ? structure.atomTreeController.filteredRootNodes.count : structure.atomTreeController.rootNodes.count
      }
      return 0
    }
    else
    {
      if let node: SKAtomTreeNode = item as? SKAtomTreeNode
      {
        return filterContent ? node.filteredAndSortedNodes.count : node.childNodes.count
      }
      return 0
    }
  }
  
  
  // Returns the child item at the specified index of a given item
  func outlineView(_ outlineView: NSOutlineView, child index: Int,ofItem item: Any?) -> Any
  {
    if(item == nil)
    {
      if let structure: Structure =  (self.representedObject as? iRASPAStructure)?.structure
      {
        return filterContent ? structure.atomTreeController.filteredRootNodes[index] : structure.atomTreeController.rootNodes[index]
      }
    }
    else
    {
      if let node: SKAtomTreeNode = (item as? SKAtomTreeNode)
      {
        return filterContent ? node.filteredAndSortedNodes[index] : node.childNodes[index]
      }
    }
    
    return 0
  }
  
  // Returns a Boolean value that indicates whether the a given item is expandable
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool
  {
    if let node: SKAtomTreeNode = (item as? SKAtomTreeNode)
    {
      return !node.childNodes.isEmpty
    }
    return false
  }
  
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
  {
    var view: NSTableCellView? = nil
    
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let proxyProject: ProjectTreeNode = self.proxyProject,
      let structure: Structure = (representedObject as? iRASPAStructure)?.structure,
       let node: SKAtomTreeNode = item as? SKAtomTreeNode
    {
      let atomNode: SKAsymmetricAtom = node.representedObject
      if (node.isGroup)
      {
        let localview: NSView? = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomGroupRow"), owner: self)

        // group-row
        if tableColumn == nil
        {
          if let checkBox: NSButton = localview!.viewWithTag(10) as? NSButton
          {
            checkBox.state = atomNode.isVisible ? NSControl.StateValue.on : NSControl.StateValue.off
            checkBox.isEnabled = atomNode.isVisibleEnabled && proxyProject.isEnabled
            
          }
          if let textField: NSTextField = localview!.viewWithTag(11) as? NSTextField
          {
            textField.isBezeled = false
            textField.drawsBackground = false
            textField.stringValue = atomNode.displayName
            textField.isEditable = proxyProject.isEnabled
          }
          return localview
        }
      }
      else if let tableColumn = tableColumn
      {
        switch(tableColumn.identifier)
        {
        case NSUserInterfaceItemIdentifier(rawValue: "atomVisibilityColumn"):
          view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomVisibility"), owner: self) as? NSTableCellView
          if let checkBox: NSButton = view?.viewWithTag(10) as? NSButton
          {
            checkBox.state = atomNode.isVisible ? NSControl.StateValue.on : NSControl.StateValue.off
            checkBox.isEnabled = atomNode.isVisibleEnabled && proxyProject.isEnabled
          }
        case NSUserInterfaceItemIdentifier(rawValue: "atomFixedColumn"):
          view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomFixed"), owner: self) as? NSTableCellView
          if let segmentedControl: NSLabelSegmentedControl = view!.viewWithTag(11) as? NSLabelSegmentedControl
          {
            segmentedControl.label = NSString(string: String(atomNode.tag))
            segmentedControl.setLabel(String(atomNode.tag), forSegment: 0)
            segmentedControl.setLabel(String(atomNode.tag), forSegment: 1)
            segmentedControl.setLabel(String(atomNode.tag), forSegment: 2)
            segmentedControl.setSelected(atomNode.isFixed.x, forSegment: 0)
            segmentedControl.setSelected(atomNode.isFixed.y, forSegment: 1)
            segmentedControl.setSelected(atomNode.isFixed.z, forSegment: 2)
            segmentedControl.setEnabled(true, forSegment: 0)
            segmentedControl.setEnabled(true, forSegment: 1)
            segmentedControl.setEnabled(true, forSegment: 2)
            segmentedControl.isEnabled = proxyProject.isEnabled
          }
        case NSUserInterfaceItemIdentifier(rawValue: "atomNameColumn"):
          view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomName"), owner: self) as? NSTableCellView
          view?.textField?.stringValue = atomNode.displayName
          view?.textField?.isEditable = node.isEditable && proxyProject.isEnabled
        case NSUserInterfaceItemIdentifier(rawValue: "atomElementColumn"):
          view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomElement"), owner: self) as? NSTableCellView
         
          view?.textField?.stringValue = PredefinedElements.sharedInstance.elementSet[node.representedObject.elementIdentifier].chemicalSymbol
          view?.textField?.textColor = NSColor.controlTextColor
          view?.textField?.font = NSFont.systemFont(ofSize: view!.textField!.font!.pointSize, weight: NSFont.Weight.regular)
          
          view?.textField?.isEditable = node.isEditable && proxyProject.isEnabled
          if let _ = (self.representedObject as? iRASPAStructure)?.structure as? RKRenderObjectSource
          {
            view?.textField?.isEditable = false
          }
        case NSUserInterfaceItemIdentifier(rawValue: "atomUniqueForceFieldIdentifierColumn"):
          view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomUniqueForceFieldIdentifier"), owner: self) as? NSTableCellView
          
          view?.textField?.stringValue = node.representedObject.uniqueForceFieldName
          if let _ : SKForceFieldType = document.forceFieldSets[structure.atomForceFieldIdentifier]?[node.representedObject.uniqueForceFieldName]
          {
            view?.textField?.textColor = NSColor.controlTextColor
            view?.textField?.font = NSFont.systemFont(ofSize: view!.textField!.font!.pointSize, weight: NSFont.Weight.regular)
          }
          else
          {
            view?.textField?.textColor = NSColor.red
            view?.textField?.font = NSFont.systemFont(ofSize: view!.textField!.font!.pointSize, weight: NSFont.Weight.bold)
          }
          
          view?.textField?.isEditable = node.isEditable && proxyProject.isEnabled
          if let _ = (self.representedObject as? iRASPAStructure)?.structure as? RKRenderObjectSource
          {
            view?.textField?.isEditable = false
          }
        case NSUserInterfaceItemIdentifier(rawValue: "atomPositionXColumn"):
          view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomPositionX"), owner: self) as? NSTableCellView
          view?.textField?.doubleValue=atomNode.position.x
          view?.textField?.formatter = structure.isFractional ? fractionalFormatter : cartesianFormatter
          view?.textField?.isEditable = node.isEditable && proxyProject.isEnabled
        case NSUserInterfaceItemIdentifier(rawValue: "atomPositionYColumn"):
          view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomPositionY"), owner: self) as? NSTableCellView
          view?.textField?.doubleValue=atomNode.position.y
          view?.textField?.formatter = structure.isFractional ? fractionalFormatter : cartesianFormatter
          view?.textField?.isEditable = node.isEditable && proxyProject.isEnabled
        case NSUserInterfaceItemIdentifier(rawValue: "atomPositionZColumn"):
          view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomPositionZ"), owner: self) as? NSTableCellView
          view?.textField?.doubleValue=atomNode.position.z
          view?.textField?.formatter = structure.isFractional ? fractionalFormatter : cartesianFormatter 
          view?.textField?.isEditable = node.isEditable && proxyProject.isEnabled
        case NSUserInterfaceItemIdentifier(rawValue: "atomChargeColumn"):
          view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomCharge"), owner: self) as? NSTableCellView
          view?.textField?.doubleValue=atomNode.charge
          view?.textField?.formatter = chargeFormatter
          view?.textField?.isEditable = node.isEditable && proxyProject.isEnabled
        default:
          view = nil
        }
      }
    }
    
    return view
  }
  
  func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool
  {
    if let node = item as? SKAtomTreeNode
    {
      return node.isGroup
    }
    
    return false
  }
  
  
  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView?
  {
    if let rowView: AtomTableRowView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomTableRowView"), owner: self) as? AtomTableRowView
    {
      if let item: SKAtomTreeNode = item as? SKAtomTreeNode
      {
        rowView.isImplicitelySelected = item.isImplicitelySelected
      }
      
      return rowView
    }
    return nil
  }
  
  func outlineView(_ outlineView: NSOutlineView, didAdd rowView: NSTableRowView, forRow row: Int)
  {
    for view in rowView.subviews
    {
      if let view = view as? AtomGroupStackView
      {
        view.isSelected = rowView.isSelected
        view.needsDisplay = true
      }
    }
    if let item: SKAtomTreeNode = outlineView.item(atRow: row) as? SKAtomTreeNode
    {
      (rowView as? AtomTableRowView)?.isImplicitelySelected = item.isImplicitelySelected
    }
    rowView.needsDisplay = true
  }
  
  func outlineView(_ outlineView: NSOutlineView, didRemove rowView: NSTableRowView, forRow row: Int)
  {
    rowView.isSelected = false
    (rowView as? AtomTableRowView)?.isImplicitelySelected = false
  }
  
  
  func convertSelectionToFilteredSelection()
  {
    // avoid sending notification due to selection change
    observeNotifications = false
    
    if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let selectedNodes:[SKAtomTreeNode] = structure.atomTreeController.selectedNodes
      
      structure.atomTreeController.setSelectedNodes([])
      
      self.atomOutlineView?.selectRowIndexes(IndexSet(), byExtendingSelection: false)
      
      for node in selectedNodes
      {
        if let index: Int = self.atomOutlineView?.row(forItem: node)
        {
          if (index>=0)
          {
            structure.atomTreeController.addSelectionNode(node)
            self.atomOutlineView?.selectRowIndexes(NSIndexSet(index: index) as IndexSet, byExtendingSelection: true)
          }
        }
      }
    }
    
    observeNotifications = true
    
    //self.atomOutlineView.reloadData()
  }
  
  
  
  // MARK: Copy / Paste / Cut / Delete
  // =====================================================================
  
  @objc func copy(_ sender: AnyObject)
  {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    
    if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      pasteboard.writeObjects(structure.readySelectedAtomsForCopyAndPaste())
    }
  }
  
  @objc func paste(_ sender: AnyObject)
  {
    let selectedRow: Int = self.atomOutlineView?.selectedRow ?? 0
    let selectedAtom: SKAtomTreeNode? = self.atomOutlineView?.item(atRow: selectedRow) as? SKAtomTreeNode
    
    
    if let proxyProject: ProjectTreeNode = self.proxyProject,
       let _: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
      let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      if !proxyProject.isEditable
      {
        LogQueue.shared.warning(destination: windowController, message: "Paste unsuccesful: project is not editable.")
        return
      }
      
      if !proxyProject.isEnabled
      {
        LogQueue.shared.warning(destination: windowController, message: "Paste unsuccesful: project is temporary disabled.")
        return
      }
      
      let pasteboard = NSPasteboard.general
      if let objects: [SKAtomTreeNode] = pasteboard.readObjects(forClasses: [SKAtomTreeNode.self], options: nil) as? [SKAtomTreeNode]
      {
        let asymmetricAtoms: [SKAsymmetricAtom]
          = objects.map{$0.representedObject}
        
        let indexPath: IndexPath = selectedAtom?.indexPath ?? [-1]
        let insertionIndex = indexPath.last! + 1
        let prefixIndexPath = indexPath.dropLast()
        
        let indexPaths = Array(0..<objects.count).map{prefixIndexPath + IndexPath(index: insertionIndex + $0)}
        
        if let document: iRASPADocument = self.windowController?.currentDocument
        {
          structure.setRepresentationColorScheme(colorSets: document.colorSets, for: asymmetricAtoms)
          structure.setRepresentationForceField(forceField: structure.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets, for: asymmetricAtoms)
        }
        structure.setRepresentationType(type: structure.atomRepresentationType, for: asymmetricAtoms)
        
        structure.convertToNativePositions(newAtoms: objects)
        
        //let bonds = structure.bonds(newAtoms: objects)
        
        // FIX
        self.insertSelectedAtomsIn(structure: structure, atoms: objects, at: indexPaths, bonds: [], at: [])
      }
    }
  }
  
  @objc func cut(_ sender: AnyObject)
  {
    if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
    
    
      let nodes: [SKAtomTreeNode] = structure.readySelectedAtomsForCopyAndPaste()
      pasteboard.writeObjects(nodes)
      self.deleteSelection()
    }
  }
  
  override func keyDown(with event: NSEvent)
  {
    // interpretKeyEvents makes 'deleteBackward' and 'deleteForward' work
    self.interpretKeyEvents([event])
  }
  
  
  override func deleteBackward(_ sender: Any?)
  {
    deleteSelection()
  }
  
  override func deleteForward(_ sender: Any?)
  {
    deleteSelection()
  }
  
  
  
  // MARK: methods for adding and removing projects
  // =====================================================================
  
  @IBAction func addGroupAtom(_ sender: AnyObject)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let proxyProject = self.proxyProject, proxyProject.isEnabled,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
      let structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      var selectedNode: SKAtomTreeNode? = nil
      var atomGroupTreeNode: SKAtomTreeNode
      var atomGroupNode: SKAsymmetricAtom
      
      let displayName: String = PredefinedElements.sharedInstance.elementSet[6].chemicalSymbol
      let color: NSColor = document.colorSets[structure.atomColorSchemeIdentifier]?[displayName] ?? NSColor.black
      let drawRadius: Double = structure.drawRadius(elementId: 6)
      let bondDistanceCriteria: Double = document.forceFieldSets[structure.atomForceFieldIdentifier]?[displayName]?.userDefinedRadius ?? 1.0
      
      atomGroupNode = SKAsymmetricAtom(displayName: displayName, elementId: 6, uniqueForceFieldName: displayName, position: SIMD3<Double>(0,0,0), charge: 0.0, color: color, drawRadius: drawRadius, bondDistanceCriteria: bondDistanceCriteria)
      atomGroupNode.displayName = "New group"
      atomGroupNode.symmetryType = .container
      structure.expandSymmetry(asymmetricAtom: atomGroupNode)
      atomGroupTreeNode = SKAtomTreeNode(representedObject: atomGroupNode, isGroup: true)
      atomGroupTreeNode.matchesFilter = true
      
      if let clickedRowContextMenu = self.atomOutlineView?.clickedRow
      {
        if !project.undoManager.isUndoing
        {
          project.undoManager.setActionName(NSLocalizedString("Add Atom-Group", comment: ""))
        }
        
        if (clickedRowContextMenu != -1)
        {
          selectedNode = self.atomOutlineView?.item(atRow: clickedRowContextMenu) as? SKAtomTreeNode
          let toItem: SKAtomTreeNode? = selectedNode!.isRootNode() ? nil: selectedNode!.parentNode
          if let index: Int = selectedNode?.indexPath.last
          {
            addNode(atomGroupTreeNode, inItem: toItem, atIndex: index + 1, inStructure: structure)
          }
        }
        else
        {
          addNode(atomGroupTreeNode, inItem: nil, atIndex: 0, inStructure: structure)
        }
      }
    }
  }
  
  @IBAction func addAtom(_ sender: AnyObject)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
      let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure, proxyProject?.isEnabled == true
    {
      self.observeNotifications = false
      
      let element: Int
      let displayName: String
      if let _  = (self.representedObject as? iRASPAStructure)?.structure as? RKRenderObjectSource
      {
        element = 0
        displayName = "center"
      }
      else
      {
        element = 6
        displayName = PredefinedElements.sharedInstance.elementSet[element].chemicalSymbol
      }
      
      let color: NSColor = document.colorSets[structure.atomColorSchemeIdentifier]?[displayName] ?? NSColor.black
      let drawRadius: Double = structure.drawRadius(elementId: element)
      let bondDistanceCriteria: Double = document.forceFieldSets[structure.atomForceFieldIdentifier]?[displayName]?.userDefinedRadius ?? 1.0
      let asymmetricAtom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: displayName, elementId:  element, uniqueForceFieldName: displayName, position: SIMD3<Double>(0,0,0), charge: 0.0, color: color, drawRadius: drawRadius, bondDistanceCriteria: bondDistanceCriteria)
      structure.expandSymmetry(asymmetricAtom: asymmetricAtom)
      let atomTreeNode: SKAtomTreeNode = SKAtomTreeNode(representedObject: asymmetricAtom)
      
      atomTreeNode.matchesFilter = true
      
      if project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Adding New Atom", comment: ""))
      }
      
      self.addNode(atomTreeNode, inItem: nil, atIndex: 0, inStructure: structure)
      
      self.observeNotifications = true
    }
  }
  
  func addNode(_ node: SKAtomTreeNode, inItem: SKAtomTreeNode?, atIndex: Int, inStructure: Structure)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
      let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure , proxyProject?.isEnabled == true
    {
      project.undoManager.registerUndo(withTarget: self, handler: {$0.removeNode(node, fromItem: inItem, atIndex: atIndex, inStructure: structure)})
      
      structure.atomTreeController.insertNode(node, inItem: inItem, atIndex: atIndex)
      structure.atomTreeController.selectedTreeNodes.insert(node)
      
      if (!filterContent)
      {
        if let outlineView = self.atomOutlineView,
               outlineView.numberOfRows >= 0
        {
          outlineView.insertItems(at: IndexSet(integer: atIndex), inParent: inItem, withAnimation: .slideRight)
          outlineView.selectRowIndexes(IndexSet(integer: self.atomOutlineView!.row(forItem: node)), byExtendingSelection: true)
        }
      }
      
      structure.atomTreeController.tag()

      if let column: Int = (self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomFixedColumn"))),
        let numberOfRows: Int = self.atomOutlineView?.numberOfRows
      {
        self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integersIn: 0..<numberOfRows), columnIndexes: IndexSet(integer: column))
      }
      
      
      if (self.filterContent)
      {
        structure.atomTreeController.updateFilteredNodes()
        
        self.atomOutlineView?.reloadData()
        self.programmaticallySetSelection()
      }
      
      structure.reComputeBoundingBox()
      structure.setRepresentationForceField(forceField: structure.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)
      structure.setRepresentationStyle(style: structure.atomRepresentationStyle, colorSets: document.colorSets)
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
  self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: structure)
      
      project.isEdited = true
      self.windowController?.currentDocument?.updateChangeCount(.changeDone)
      
      self.updateNetChargeTextField()
    }
  }
  
  

  
  func removeNode(_ node: SKAtomTreeNode, fromItem: SKAtomTreeNode?, atIndex: Int, inStructure structure: Structure)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
      let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure , proxyProject?.isEnabled == true
    {
      let index: Int = node.indexPath.last ?? 0
      project.undoManager.registerUndo(withTarget: self, handler: {$0.addNode(node, inItem: fromItem, atIndex: index, inStructure: structure)})
      
      let fromItem: SKAtomTreeNode? = node.isRootNode() ? nil: node.parentNode
      structure.atomTreeController.removeNode(node)
      structure.atomTreeController.selectedTreeNodes.remove(node)
      
      if (!filterContent)
      {
        if let outlineView = self.atomOutlineView,
          outlineView.numberOfRows > 0
        {
          outlineView.removeItems(at: IndexSet(integer: atIndex), inParent: fromItem, withAnimation: .slideLeft)
        }
      }
      
      structure.atomTreeController.tag()

      if let column: Int = (self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomFixedColumn"))),
         let numberOfRows: Int = self.atomOutlineView?.numberOfRows
      {
        self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integersIn: 0..<numberOfRows), columnIndexes: IndexSet(integer: column))
      }
      
      if (self.filterContent)
      {
        structure.atomTreeController.updateFilteredNodes()
        
        self.atomOutlineView?.reloadData()
        self.programmaticallySetSelection()
      }
      
      structure.reComputeBoundingBox()
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: structure)
      
      project.isEdited = true
    }
  }
  

  
  
  func visibilityOfFirstParentGroupAtom(_ treeNode: SKAtomTreeNode) -> Bool
  {
    var atomTreeNode: SKAtomTreeNode? = treeNode
    while(atomTreeNode != nil)
    {
      if let atomNode = atomTreeNode?.representedObject , atomTreeNode!.isGroup
      {
        return atomNode.isVisible
      }
      else
      {
        atomTreeNode=atomTreeNode!.parentNode
      }
    }
    return true
  }
  
  @IBAction func removeSelection(_ sender: NSSquareButton)
  {
    self.deleteSelection()
  }
  
  
  // MARK: NSOutlineView required delegate methods for drag&drop
  // =====================================================================
  
  
  // enable the outlineView to be an NSDraggingSource that supports dragging multiple items.
  // Returns a custom object that implements NSPasteboardWriting protocol (or simply use NSPasteboardItem).
  // so here we return AtomNode which means AtomNode is put on the pastboard
  
  func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting?
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled
    {
      return item as? SKAtomTreeNode
    }
    return nil
  }
  
  
  
  
  // Required: Implement this method know when the given dragging session is about to begin and potentially modify the dragging session.
  // draggedItems: A array of items to be dragged, excluding items for which outlineView:pasteboardWriterForItem: returns nil.
  func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any])
  {
    // store the dragged-node locally
    self.draggedNodes = draggedItems
  }
  
  
  
  
  // Optional: You can implement this optional delegate method to know when the dragging source operation ended at a specific location,
  //           such as the trash (by checking for an operation of NSDragOperationDelete).
  func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation)
  {
    
  }
  
  // Optional: Based on the mouse position, the outline view will suggest a proposed drop location. The data source may “retarget” a drop if desired by calling
  // setDropItem:dropChildIndex: and returning something other than NSDragOperationNone. You may choose to retarget for various reasons (for example, for
  // better visual feedback when inserting into a sorted position).
  func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      if (outlineView === info.draggingSource! as AnyObject)
      {
        // drag&drop is reordering in the same outlineView
        for node in self.draggedNodes
        {
          if let node = node as? SKAtomTreeNode
          {
            // can not drag a parent into its descendent
            if structure.atomTreeController.isDescendantOfNode(item as? SKAtomTreeNode, parentNode: node)
            {
              return []
            }
          }
        }
        
        if let targetNode: SKAtomTreeNode = item as? SKAtomTreeNode
        {
          if targetNode.representedObject.symmetryType == .container
          {
            return .move
          }
        }
        
        // A drop on an atom is not allowed
        if index == NSOutlineViewDropOnItemIndex
        {
          return []
        }
        
        return .move
      }
      else
      {
        // dropped from another outlineView
        if let targetNode: SKAtomTreeNode = item as? SKAtomTreeNode
        {
          if targetNode.representedObject.symmetryType == .container
          {
            // drag&drop is reordering in the same outlineView
            return .copy
          }
        }
        
        // A drop on an atom is not allowed
        if index == NSOutlineViewDropOnItemIndex
        {
          return []
        }
        
        return .copy
      }
    }
    
    // otherwise dropping not allowed
    return []
  }
  
  
  
  
  func itemsAreSiblings(_ node: SKAtomTreeNode, item: SKAtomTreeNode?) -> Bool
  {
    if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      return structure.atomTreeController.nodeIsChildOfItem(node, item: item)
    }
    return false
  }
  
  
  func moveNodes(_ moves: [(node: SKAtomTreeNode, toItem: SKAtomTreeNode?, childIndex: Int)], inStructure structure: Structure)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
      let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let observeNotificationsStored: Bool = self.observeNotifications
      self.observeNotifications = false
      
      NSAnimationContext.beginGrouping()
      
      // set the completion-handler _before_ any animations have been run
      NSAnimationContext.current.completionHandler = {
        
        structure.atomTreeController.flattenedNodes().forEach({$0.isImplicitelySelected = false})
        structure.atomTreeController.allSelectedNodes.forEach({$0.isImplicitelySelected = true})
        
        self.atomOutlineView?.enumerateAvailableRowViews({ (rowView,row) in
          if let item: SKAtomTreeNode = self.atomOutlineView?.item(atRow: row) as? SKAtomTreeNode
          {
            (rowView as? AtomTableRowView)?.isImplicitelySelected = item.isImplicitelySelected
            rowView.needsDisplay = true
          }
        })
        
        self.reloadData()
      }

      // the outlineView will not call the datasource inbetween beginUpdates/endUpdates
      self.atomOutlineView?.beginUpdates()
      
      var reverseMoves: [(node: SKAtomTreeNode, toItem: SKAtomTreeNode?, childIndex: Int)] = []
      
      for move in moves
      {
        let nodeIndexPath: IndexPath = move.node.indexPath
        let fromItem: SKAtomTreeNode? = move.node.isRootNode() ? nil: move.node.parentNode
        
        // build up the reverse moves
        reverseMoves.append((node: move.node, toItem: fromItem, childIndex: nodeIndexPath.last ?? 0))
      
        // remove old node
        structure.atomTreeController.removeNodeAtArrangedObjectIndexPath(nodeIndexPath)
      
        if (!filterContent)
        {
          if let outlineView = self.atomOutlineView,
            outlineView.numberOfRows>0
          {
            outlineView.removeItems(at: IndexSet(integer: nodeIndexPath.last ?? 0), inParent: fromItem, withAnimation: [])
          }
        }
      
        // insert new node
        structure.atomTreeController.insertNode(move.node, inItem: move.toItem, atIndex: move.childIndex)
      
        if (!filterContent)
        {
          if let outlineView = self.atomOutlineView,
            outlineView.numberOfRows>0
          {
            outlineView.insertItems(at: IndexSet(integer: move.childIndex), inParent: move.toItem, withAnimation: .effectGap)
          }
          
           // keep the selection outlineView automatically in sync without having to call 'programmaticallySetSelection()'
          if structure.atomTreeController.selectedTreeNodes.contains(move.node)
          {
            self.atomOutlineView?.selectRowIndexes(IndexSet(integer: self.atomOutlineView!.row(forItem: move.node)), byExtendingSelection: true)
          }
        }
      }
      
      structure.atomTreeController.tag()
      
      if let column: Int = (self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomFixedColumn"))),
        let numberOfRows: Int = self.atomOutlineView?.numberOfRows
      {
        self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integersIn: 0..<numberOfRows), columnIndexes: IndexSet(integer: column))
      }

      self.atomOutlineView?.endUpdates()
      NSAnimationContext.endGrouping()
      
      
      
      if (self.filterContent)
      {
        structure.atomTreeController.updateFilteredNodes()
        self.reloadData()
      }
      
      
      
      self.observeNotifications = observeNotificationsStored
      
      project.undoManager.setActionName(NSLocalizedString("Reorder Atoms", comment: ""))
      project.undoManager.registerUndo(withTarget: self, handler: {$0.moveNodes(reverseMoves.reversed(), inStructure: structure)})
      
      // the order of the atoms of the structure have changed, so remake the textures and reload the render-data
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
  self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.reloadRenderData()
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: structure)
    }
  }
  
  // The data source should incorporate the data from the dragging pasteboard in the implementation of this method. You can get the data for the drop operation
  // from info using the draggingPasteboard method.
  func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool
  {
    var childIndex: Int = index
    
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let toItem: SKAtomTreeNode? = item as? SKAtomTreeNode
      
      if (childIndex == NSOutlineViewDropOnItemIndex)
      {
        childIndex = 0
      }
      else if (self.filterContent)
      {
        // filtering 'on' and we drop before a node
        // get the node, get the indexpath and set the childIndex to the last-index
        childIndex = structure.atomTreeController.filteredChildIndexOfItem(toItem, index: childIndex)
      }
      
      if (info.draggingSource as AnyObject) === self.atomOutlineView
      {
        // drag/drop occured within the same outlineView -> reordering
        var moves: [(node: SKAtomTreeNode, toItem: SKAtomTreeNode?, childIndex: Int)] = []
        for node in self.draggedNodes
        {
          if let node = node as? SKAtomTreeNode
          {
            // Moving it from within the same parent -> account for the remove, if it is past the oldIndex
            if (self.itemsAreSiblings(node, item: item as? SKAtomTreeNode))
            {
              // Moving it from within the same parent! Account for the remove, if it is past the oldIndex
              if let oldIndex = node.parentNode?.childNodes.firstIndex(of: node) , (childIndex > oldIndex)
              {
               childIndex -= 1 // account for the remove
              }
            }
          
          
            moves.append((node: node, toItem: toItem, childIndex: childIndex))
            childIndex += 1
          }
        
          // move the selected nodes to the destination
          self.moveNodes(moves, inStructure: structure)
        }
    self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      }
      else
      {
        
        // drop occured in another outlineView as the drag -> copying
        info.draggingPasteboard.readObjects(forClasses: [NSString.self], options: nil)
        
        info.enumerateDraggingItems(options: NSDraggingItemEnumerationOptions.concurrent, for: outlineView, classes: [SKAtomTreeNode.self], searchOptions: [:], using: { (draggingItem , idx, stop)  in
          
          if let node: SKAtomTreeNode = (draggingItem as NSDraggingItem).item as? SKAtomTreeNode
          {
            self.addNode(node, inItem: toItem, atIndex: childIndex, inStructure: structure)
            //treeController.updateFilteredNode(node)
            // keep the selected node selected
            self.atomOutlineView?.selectRowIndexes(NSIndexSet(index: self.atomOutlineView!.row(forItem: node)) as IndexSet, byExtendingSelection: true)
            
            childIndex = childIndex + 1
          }
        })
        
    self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
        
        self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      }
      
      return true
    }
    return false
  }
  
  
  // MARK: NSOutlineView notifications for expanding/collapsing items
  // =====================================================================
  
  
  func restoreSelectedItems(_ parent: SKAtomTreeNode)
  {
    if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let updatedSelectedIndex: NSMutableIndexSet = NSMutableIndexSet()
      for node in parent.childNodes
      {
        if structure.atomTreeController.selectedTreeNodes.contains(node)
        {
          if let index: Int = self.atomOutlineView?.row(forItem: node)
          {
            updatedSelectedIndex.add(index)
          }
        }
      }
      self.atomOutlineView?.selectRowIndexes(updatedSelectedIndex as IndexSet, byExtendingSelection: true)
    }
  }
  
  
  func outlineViewItemWillExpand(_ notification:Notification)
  {
  }
  
  func outlineViewItemDidExpand(_ notification:Notification)
  {
    
    if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure,
       let treeNode: SKAtomTreeNode = notification.userInfo?["NSObject"] as? SKAtomTreeNode
    {
      self.atomOutlineView?.reloadItem(treeNode)
      self.restoreSelectedItems(treeNode)
      
      structure.atomTreeController.flattenedNodes().forEach({$0.isImplicitelySelected = false})
      structure.atomTreeController.allSelectedNodes.forEach({$0.isImplicitelySelected = true})
      
      self.atomOutlineView?.enumerateAvailableRowViews({ (rowView,row) in
        if let item: SKAtomTreeNode = self.atomOutlineView?.item(atRow: row) as? SKAtomTreeNode
        {
          (rowView as? AtomTableRowView)?.isImplicitelySelected = item.isImplicitelySelected
          rowView.needsDisplay = true
        }
      })

    }
  }
  
  func outlineViewItemWillCollapse(_ notification:Notification)
  {
  }
  
  func outlineViewItemDidCollapse(_ notification:Notification)
  {
    
  }
  
  // MARK: NSOutlineView notifications for the selection
  // =====================================================================
  
  
  @objc func setSelectionFromExternalSource()
  {
    let observeNotificationsStored: Bool = self.observeNotifications
    self.observeNotifications = false
    
    self.reloadData()
    
    self.observeNotifications = observeNotificationsStored
  }
  
  func programmaticallySetSelection()
  {
    if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      // avoid sending notification due to selection change
      let observeNotificationsStored: Bool = self.observeNotifications
      self.observeNotifications = false
      
      let selectedNodes:[SKAtomTreeNode] = structure.atomTreeController.selectedNodes
      
      self.atomOutlineView?.selectRowIndexes(IndexSet(), byExtendingSelection: false)
      
      for node in selectedNodes
      {
        if let index: Int = self.atomOutlineView?.row(forItem: node)
        {
          if (index>=0)
          {
            self.atomOutlineView?.selectRowIndexes(NSIndexSet(index: index) as IndexSet, byExtendingSelection: true)
          }
        }
      }
      
      structure.atomTreeController.flattenedNodes().forEach({$0.isImplicitelySelected = false})
      structure.atomTreeController.allSelectedNodes.forEach({$0.isImplicitelySelected = true})
      
      // set the basis for the selected atoms once the selection is set and use that for subsequent translations and rotations
      structure.recomputeSelectionBodyFixedBasis(index: -1)
      
      self.atomOutlineView?.enumerateAvailableRowViews({ (rowView,row) in
        if let item: SKAtomTreeNode = self.atomOutlineView?.item(atRow: row) as? SKAtomTreeNode
        {
          (rowView as? AtomTableRowView)?.isImplicitelySelected = item.isImplicitelySelected
          rowView.needsDisplay = true
        }
      })

      
      self.observeNotifications = observeNotificationsStored
    }
  }
  
  func setCurrentSelection(structure: Structure, atomSelection: Set<SKAtomTreeNode>, previousAtomSelection: Set<SKAtomTreeNode>, bondSelection: IndexSet, previousBondSelection: IndexSet)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      if project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Change Atom Selection", comment: ""))
      }
      // save off the current selectedNode and current selection for undo/redo
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setCurrentSelection(structure: structure, atomSelection: previousAtomSelection, previousAtomSelection: atomSelection, bondSelection: previousBondSelection, previousBondSelection: bondSelection)})
    
      structure.atomTreeController.selectedTreeNodes = atomSelection
      structure.bondController.selectedObjects = bondSelection
    
      // reload the selection in the renderere
      self.windowController?.detailTabViewController?.renderViewController?.reloadRenderDataSelectedAtoms()
      
      self.windowController?.detailTabViewController?.renderViewController?.showTransformationPanel(oldSelectionEmpty: structure.atomTreeController.selectedTreeNodes.isEmpty,newSelectionEmpty: atomSelection.isEmpty)
      
      // set the basis for the selected atoms once the selection is set and use that for subsequent translations and rotations
      structure.recomputeSelectionBodyFixedBasis(index: -1)
    
      
      // reload the selection in the atom-outlineview
      self.programmaticallySetSelection()
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: structure)
    }
  }


  
  
  // Keep the AtomTreeController's selection in-sync with the NSOutlineView
  // This method may be called multiple times with one new index added to the existing selection to find out if a particular index
  // can be selected when the user is extending the selection with the keyboard or mouse.
  // purpose: (1) restrict the selection to certain nodes, (2) keep controller's selection up to date.
  func outlineView(_ outlineView: NSOutlineView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet
  {
    return proposedSelectionIndexes
  }
  
  
  // Invoked when the selection did change notification is posted—that is, immediately after the outline view’s selection has changed
  func outlineViewSelectionDidChange(_ aNotification: Notification)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      if (self.observeNotifications && !project.undoManager.isUndoing && !project.undoManager.isRedoing)
      {
        
        var selectedAtomTreeNodes: Set<SKAtomTreeNode> = []
        if let selectedRows: IndexSet = self.atomOutlineView?.selectedRowIndexes
        {
          for index in selectedRows
          {
            if let node: SKAtomTreeNode = self.atomOutlineView?.item(atRow: index) as? SKAtomTreeNode
            {
              selectedAtomTreeNodes.insert(node)
            }
          }
        }
        
        let asymmetricAtoms: Set<SKAsymmetricAtom> = Set(selectedAtomTreeNodes.map{$0.representedObject})
        
        // add also all the bonds that are connected to a selected atom
        var selectedBonds: IndexSet = []
        for (index, bond) in structure.bondController.arrangedObjects.enumerated()
        {
          if(asymmetricAtoms.contains(bond.atom1) ||
             asymmetricAtoms.contains(bond.atom2))
          {
            selectedBonds.insert(index)
          }
        }
        
        setCurrentSelection(structure: structure, atomSelection: selectedAtomTreeNodes, previousAtomSelection: structure.atomTreeController.selectedTreeNodes, bondSelection: selectedBonds, previousBondSelection: structure.bondController.selectedObjects)
        
        // draw implicitely seleceted nodes as 'light blue'
        structure.atomTreeController.flattenedNodes().forEach({$0.isImplicitelySelected = false})
        structure.atomTreeController.allSelectedNodes.forEach({$0.isImplicitelySelected = true})
        
        self.atomOutlineView?.enumerateAvailableRowViews({ (rowView,row) in
          if let item: SKAtomTreeNode = self.atomOutlineView?.item(atRow: row) as? SKAtomTreeNode
          {
            (rowView as? AtomTableRowView)?.isImplicitelySelected = item.isImplicitelySelected
            rowView.needsDisplay = true
          }
        })
        
        // redraw to show selected atoms
        self.windowController?.detailTabViewController?.renderViewController?.reloadRenderDataSelectedAtoms()
      }
    }
  }
  
  func deleteSelectedAtomsFor(structure: Structure, atoms: [SKAtomTreeNode], from indexPaths: [IndexPath], bonds: [SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>], from indexSet: IndexSet)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.undoManager.registerUndo(withTarget: self, handler: {$0.insertSelectedAtomsIn(structure: structure, atoms: atoms.reversed(), at: indexPaths.reversed(), bonds: bonds, at: indexSet)})
      
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Delete Atoms", comment: ""))
      }
      
      structure.bondController.arrangedObjects.remove(at: indexSet)
      structure.bondController.selectedObjects = []
      structure.bondController.tag()
      
      let observeNotificationsStored: Bool = self.observeNotifications
      self.observeNotifications = false
      
      
      NSAnimationContext.beginGrouping()
      
      // set the completion-handler _before_ any animations have been run
      NSAnimationContext.current.completionHandler = {
        
        if let atomOutlineView = self.atomOutlineView
        {
          if(atomOutlineView.numberOfRows==0)
          {
            // if deleted all, reloadData to redraw all the alternating rows
            atomOutlineView.reloadData()
          }
          else
          {
            // reload to redraw all the alternating rows
            self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integersIn: 0..<atomOutlineView.numberOfRows), columnIndexes: IndexSet(integer: 0))
          }
        }
      }
      
      self.atomOutlineView?.beginUpdates()
      for atom in atoms
      {
        let toItem: SKAtomTreeNode? = atom.isRootNode() ? nil: atom.parentNode
        let index: Int = atom.indexPath.last ?? 0
        structure.atomTreeController.removeNode(atom)
      
        if (!self.filterContent)
        {
          if let atomOutlineView = atomOutlineView,
                 atomOutlineView.numberOfRows>0
          {
            atomOutlineView.removeItems(at: IndexSet(integer: index), inParent: toItem, withAnimation: .slideLeft)
          }
        }
      }
    
      structure.atomTreeController.selectedTreeNodes = []
      structure.atomTreeController.tag()
      structure.reComputeBoundingBox()
    
      if let column: Int = (self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomFixedColumn"))),
         let numberOfRows: Int = self.atomOutlineView?.numberOfRows,
         numberOfRows>0
      {
        self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integersIn: 0..<numberOfRows), columnIndexes: IndexSet(integer: column))
      }
      self.atomOutlineView?.endUpdates()
      
      NSAnimationContext.endGrouping()
      
      self.observeNotifications = observeNotificationsStored
    
      if (self.filterContent)
      {
        structure.atomTreeController.updateFilteredNodes()
      
        self.atomOutlineView?.reloadData()
        self.programmaticallySetSelection()
      }
    
      if let column: Int = (self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomFixedColumn"))),
         let numberOfRows: Int = self.atomOutlineView?.numberOfRows,
         numberOfRows>0
      {
        self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integersIn: 0..<numberOfRows), columnIndexes: IndexSet(integer: column))
      }
      
      
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      project.isEdited = true
      self.windowController?.currentDocument?.updateChangeCount(.changeDone)
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.windowController?.detailTabViewController?.renderViewController?.clearMeasurement()
      
      self.windowController?.detailTabViewController?.renderViewController?.showTransformationPanel(oldSelectionEmpty: false, newSelectionEmpty: true)
    
      self.updateNetChargeTextField()
    
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: structure)
    }
  }
  
  func insertSelectedAtomsIn(structure: Structure, atoms: [SKAtomTreeNode], at indexPaths: [IndexPath], bonds: [SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>], at indexSet: IndexSet)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      
      project.undoManager.registerUndo(withTarget: self, handler: {$0.deleteSelectedAtomsFor(structure: structure, atoms: atoms.reversed(), from: indexPaths.reversed(), bonds: bonds, from: indexSet)})
      
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Insert Atoms", comment: ""))
      }
      let observeNotificationsStored: Bool = self.observeNotifications
      self.observeNotifications = false
      self.atomOutlineView?.beginUpdates()
      for (index, atom) in atoms.enumerated()
      {
        structure.atomTreeController.insertNode(atom, atArrangedObjectIndexPath: indexPaths[index])
        structure.atomTreeController.selectedTreeNodes.insert(atom)
        
        let toItem: SKAtomTreeNode? = atom.isRootNode() ? nil: atom.parentNode
        let index: Int = atom.indexPath.last ?? 0
        
        if (!self.filterContent)
        {
          if let atomOutlineView = atomOutlineView,
          atomOutlineView.numberOfRows>=0
          {
            atomOutlineView.insertItems(at: IndexSet(integer: index), inParent: toItem, withAnimation: .slideLeft)
            atomOutlineView.selectRowIndexes(IndexSet(integer: atomOutlineView.row(forItem: atom)), byExtendingSelection: true)
          }
        }
      }
      
      structure.atomTreeController.tag()
      
      if let column: Int = (self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomFixedColumn"))),
        let numberOfRows: Int = self.atomOutlineView?.numberOfRows,
        numberOfRows>0
      {
        self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integersIn: 0..<numberOfRows), columnIndexes: IndexSet(integer: column))
      }
      self.atomOutlineView?.endUpdates()
      self.observeNotifications = observeNotificationsStored
      
      
      structure.bondController.arrangedObjects.insertItems(bonds, atIndexes: indexSet)
      structure.bondController.selectedObjects.formUnion(indexSet)
      structure.bondController.tag()
      
      if (self.filterContent)
      {
        structure.atomTreeController.updateFilteredNodes()
        
        self.atomOutlineView?.reloadData()
        self.programmaticallySetSelection()
      }
      
      
      if let column: Int = (self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomFixedColumn"))),
        let numberOfRows: Int = self.atomOutlineView?.numberOfRows,
        numberOfRows>0
      {
        self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integersIn: 0..<numberOfRows), columnIndexes: IndexSet(integer: column))
      }
      
      // after a delete, and before an undo, the style, colors, and forcefields potentially could change and update. Therefore: re-apply these at undo.
      structure.applyRepresentationStyle()
      if let document: iRASPADocument = self.windowController?.currentDocument
      {
        structure.applyRepresentationColorOrder(colorSets: document.colorSets)
        structure.applyRepresentationForceField(forceFieldSets: document.forceFieldSets)
      }
      
      project.isEdited = true
      self.windowController?.currentDocument?.updateChangeCount(.changeDone)
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.updateNetChargeTextField()
      self.windowController?.detailTabViewController?.renderViewController?.showTransformationPanel(oldSelectionEmpty: true, newSelectionEmpty: false)
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: structure)
    }
  }

  
  func deleteSelection()
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      // get all selected atom tree nodes _and_ the children that are implicitly selected
      // sort the selected nodes accoording to the index-paths
      // the deepest nodes should be deleted first!
      let selectedAtomTreeNodes: [SKAtomTreeNode] = structure.atomTreeController.selectedTreeNodes.flatMap{$0.flattenedNodes()}.sorted(by: { $0.indexPath > $1.indexPath })
      let indexPaths: [IndexPath] = selectedAtomTreeNodes.map{$0.indexPath}
      
      var indexSet: IndexSet = structure.bondController.selectedObjects
      
      let asymmetricAtoms: Set<SKAsymmetricAtom> = Set(selectedAtomTreeNodes.map{$0.representedObject})
      
      // add also all the bonds that are connected to a selected atom
      for (index, bond) in structure.bondController.arrangedObjects.enumerated()
      {
        if(asymmetricAtoms.contains(bond.atom1) ||
           asymmetricAtoms.contains(bond.atom2))
        {
          indexSet.insert(index)
        }
      }
      let selectedBonds: [SKAsymmetricBond] = structure.bondController.arrangedObjects[indexSet]
      
      deleteSelectedAtomsFor(structure: structure, atoms: selectedAtomTreeNodes, from: indexPaths, bonds: selectedBonds, from: indexSet)
    }
  }

  
  // MARK: Context Menu
  // =====================================================================
  
  func menuNeedsUpdate(_ menu: NSMenu)
  {
    self.atomOutlineView?.window?.makeFirstResponder(self.atomOutlineView)
  }
  
  
  // undo for large-changes: completely replace all atoms and bonds by new ones
  func setStructureState(cell: SKCell, spaceGroup: SKSpacegroup, atomTreeController: SKAtomTreeController, bondController: SKBondSetController)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
      let crystal: Structure & SpaceGroupProtocol = (representedObject as? iRASPAStructure)?.structure as? Structure & SpaceGroupProtocol
    {
      let oldCell: SKCell = crystal.cell
      let oldSpaceGroup: SKSpacegroup = crystal.spaceGroup
      let oldAtoms: SKAtomTreeController = crystal.atomTreeController
      let oldBonds: SKBondSetController = crystal.bondController
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setStructureState(cell: oldCell, spaceGroup: oldSpaceGroup, atomTreeController: oldAtoms, bondController: oldBonds)})
      
      crystal.cell = cell
      crystal.spaceGroup = spaceGroup
      crystal.atomTreeController = atomTreeController
      crystal.bondController = bondController
      
      crystal.reComputeBoundingBox()
    
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      crystal.setRepresentationColorScheme(scheme: crystal.atomColorSchemeIdentifier, colorSets: document.colorSets)
      crystal.setRepresentationForceField(forceField: crystal.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [crystal])
  self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [crystal])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.reloadData()
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: crystal)
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.SpaceGroupShouldReloadNotification), object: self.windowController)
    }
  }
  
  @IBAction func FindAndImposeSymmetry(_ sender: NSMenuItem)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
       let outlineView: AtomOutlineView = self.atomOutlineView,
       let crystal: SpaceGroupProtocol = (self.representedObject as? iRASPAStructure)?.structure as? SpaceGroupProtocol
    {
      project.undoManager.setActionName(NSLocalizedString("Find and Impose Symmetry", comment: ""))
      
      // remove the measuring nodes
      project.measurementTreeNodes = []
      
      if let state: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController) = crystal.imposedSymmetry(colorSets: document.colorSets, forceFieldSets: document.forceFieldSets)
      {
        self.setStructureState(cell: state.cell, spaceGroup: state.spaceGroup, atomTreeController: state.atoms, bondController: state.bonds)
      }
      
      outlineView.window?.makeFirstResponder(atomOutlineView)
    }
  }

  
  @IBAction func FlattenHierarchy(_ sender: NSMenuItem)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
       let outlineView: AtomOutlineView = self.atomOutlineView,
       let crystal: SpaceGroupProtocol = (self.representedObject as? iRASPAStructure)?.structure as? SpaceGroupProtocol
    {
      project.undoManager.setActionName(NSLocalizedString("Flatten Hierarchy", comment: ""))
      
      // remove the measuring nodes
      project.measurementTreeNodes = []
      
      let state: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController) = crystal.flattenedHierarchy
      self.setStructureState(cell: state.cell, spaceGroup: state.spaceGroup, atomTreeController: state.atoms, bondController: state.bonds)
      
      outlineView.window?.makeFirstResponder(atomOutlineView)
    }
  }
  
  @IBAction func RemoveSymmetry(_ sender: NSMenuItem)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
       let outlineView: AtomOutlineView = self.atomOutlineView,
       let crystal: SpaceGroupProtocol = (self.representedObject as? iRASPAStructure)?.structure as? SpaceGroupProtocol
    {
      project.undoManager.setActionName(NSLocalizedString("Remove Symmetry", comment: ""))
      
      // remove the measuring nodes
      project.measurementTreeNodes = []
      
      let state: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController) = crystal.removedSymmetry
      self.setStructureState(cell: state.cell, spaceGroup: state.spaceGroup, atomTreeController: state.atoms, bondController: state.bonds)
      
      outlineView.window?.makeFirstResponder(atomOutlineView)
    }
  }
  
  @IBAction func WrapAtomsToCell(_ sender: NSMenuItem)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
      let outlineView: AtomOutlineView = self.atomOutlineView,
      let crystal: SpaceGroupProtocol = (self.representedObject as? iRASPAStructure)?.structure as? SpaceGroupProtocol
    {
      project.undoManager.setActionName(NSLocalizedString("Wrap Atoms to Cell", comment: ""))
      
      // remove the measuring nodes
      project.measurementTreeNodes = []
      
      let state: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController) = crystal.wrapAtomsToCell
      self.setStructureState(cell: state.cell, spaceGroup: state.spaceGroup, atomTreeController: state.atoms, bondController: state.bonds)
      
      outlineView.window?.makeFirstResponder(atomOutlineView)
    }
  }
  
  @IBAction func FindPrimitive(_ sender: NSMenuItem)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
       let outlineView: AtomOutlineView = self.atomOutlineView,
      let crystal: SpaceGroupProtocol = (self.representedObject as? iRASPAStructure)?.structure as? SpaceGroupProtocol
    {
      project.undoManager.setActionName(NSLocalizedString("Find Primitive", comment: ""))
      
      // remove the measuring nodes
      project.measurementTreeNodes = []
      
      if let state: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController) = crystal.primitive(colorSets: document.colorSets, forceFieldSets: document.forceFieldSets)
      {
        self.setStructureState(cell: state.cell, spaceGroup: state.spaceGroup, atomTreeController: state.atoms, bondController: state.bonds)
      }
      outlineView.window?.makeFirstResponder(atomOutlineView)
    }
  }
  
  @IBAction func makeSuperCell(_ sender: NSMenuItem)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
       let outlineView: AtomOutlineView = self.atomOutlineView,
       let crystal: SpaceGroupProtocol = (self.representedObject as? iRASPAStructure)?.structure as? SpaceGroupProtocol
    {
      project.undoManager.setActionName(NSLocalizedString("Make Super-Cell", comment: ""))
      
      // remove the measuring nodes
      project.measurementTreeNodes = []
      
      let state: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController) = crystal.superCell
      self.setStructureState(cell: state.cell, spaceGroup: state.spaceGroup, atomTreeController: state.atoms, bondController: state.bonds)
      
      outlineView.window?.makeFirstResponder(atomOutlineView)
    }
  }

  
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, !proxyProject.isEnabled
    {
      return false
    }
    
    if (menuItem.action == #selector(addAtom))
    {
      return (((self.representedObject as? iRASPAStructure)?.structure) != nil)
    }
    
    if (menuItem.action == #selector(addGroupAtom))
    {
      return (((self.representedObject as? iRASPAStructure)?.structure) != nil)
    }
    
    if (menuItem.action == #selector(visibilityInversion))
    {
      if let numberOfRows = self.atomOutlineView?.numberOfRows
      {
        return numberOfRows > 1
      }
      return false
    }
    
    if (menuItem.action == #selector(selectionInversion))
    {
      if let numberOfRows = self.atomOutlineView?.numberOfRows
      {
        return numberOfRows >= 1
      }
      return false
    }
    
    if (menuItem.action == #selector(visibilityMatchSelection))
    {
      if let numberOfSelectedRows = self.atomOutlineView?.selectedRowIndexes.count
      {
        return numberOfSelectedRows >= 1
      }
      return false
    }
    
    if (menuItem.action == #selector(FlattenHierarchy))
    {
      return (((self.representedObject as? iRASPAStructure)?.structure) != nil)
    }
    
    if (menuItem.action == #selector(WrapAtomsToCell))
    {
      return (((self.representedObject as? iRASPAStructure)?.structure as? SpaceGroupProtocol) != nil)
    }
    
    if (menuItem.action == #selector(FindAndImposeSymmetry))
    {
      return (((self.representedObject as? iRASPAStructure)?.structure as? SpaceGroupProtocol) != nil)
    }
    
    if (menuItem.action == #selector(RemoveSymmetry))
    {
      return (((self.representedObject as? iRASPAStructure)?.structure as? SpaceGroupProtocol) != nil)
    }
    
    if (menuItem.action == #selector(FindPrimitive))
    {
      return (((self.representedObject as? iRASPAStructure)?.structure as? SpaceGroupProtocol) != nil)
    }
    
    if (menuItem.action == #selector(makeSuperCell))
    {
      return (((self.representedObject as? iRASPAStructure)?.structure as? SpaceGroupProtocol) != nil)
    }
    
    if (menuItem.action == #selector(RemoveSymmetry))
    {
      return (((self.representedObject as? iRASPAStructure)?.structure as? SpaceGroupProtocol) != nil)
    }
    
    if(menuItem.action == #selector(scrollToTop))
    {
      if let numberOfRows = self.atomOutlineView?.numberOfRows
      {
        return numberOfRows > 1
      }
      return false
    }
    
    if(menuItem.action == #selector(scrollToBottom))
    {
      if let numberOfRows = self.atomOutlineView?.numberOfRows
      {
        return numberOfRows > 1
      }
      return false
    }
    
    if(menuItem.action == #selector(scrollToFirstSelected))
    {
      if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
      {
        return structure.atomTreeController.selectedTreeNodes.count > 0
      }
      return false
    }
    
    if(menuItem.action == #selector(scrollToLastSelected))
    {
      if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
      {
        return structure.atomTreeController.selectedTreeNodes.count > 0
      }
      return false
    }
    
    
    if (menuItem.action == #selector(selectionInversion))
    {
      if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
      {
        return structure.atomTreeController.selectedTreeNodes.count > 0
      }
      return false
    }
    
    return true
  }
  
  @IBAction func selectionInversion(_ sender: NSMenuItem)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
      let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      project.undoManager.setActionName(NSLocalizedString("Invert Selection", comment:""))
      
      let invertedSelectedTreeNodes: Set<SKAtomTreeNode> = structure.atomTreeController.invertedSelection
      let invertedSelectedAsymmetricAtoms: Set<SKAsymmetricAtom> = Set(invertedSelectedTreeNodes.map{$0.representedObject})
      var invertedSelectedBonds = structure.bondController.invertedSelection
  
      // add also all the bonds that are connected to a selected atom
      for (index, bond) in structure.bondController.arrangedObjects.enumerated()
      {
        if(invertedSelectedAsymmetricAtoms.contains(bond.atom1) ||
           invertedSelectedAsymmetricAtoms.contains(bond.atom2))
        {
          invertedSelectedBonds.insert(index)
        }
      }
      
      setCurrentSelection(structure: structure, atomSelection: invertedSelectedTreeNodes, previousAtomSelection: structure.atomTreeController.selectedTreeNodes, bondSelection: invertedSelectedBonds, previousBondSelection: structure.bondController.selectedObjects)
    }
  }
  
  func removeMovieNode(_ movie: Movie, fromItem: Scene, atIndex childIndex: Int, structure: Structure, atoms: [SKAtomTreeNode], from indexPaths: [IndexPath], bonds: [SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>], from indexSet: IndexSet, move: Bool)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let currentSelectedScene: Scene? = project.sceneList.selectedScene
      
      project.undoManager.registerUndo(withTarget: self, handler: {$0.addMovieNode(movie, inItem: fromItem, atIndex: childIndex, structure: structure, atoms: atoms.reversed(), from: indexPaths.reversed(), bonds: bonds, from: indexSet, move: move)})
      
      if(move)
      {
        for (index, atom) in atoms.enumerated()
        {
          structure.atomTreeController.insertNode(atom, atArrangedObjectIndexPath: indexPaths[index])
          structure.atomTreeController.selectedTreeNodes.insert(atom)
        }
      
        structure.atomTreeController.tag()
      
        structure.bondController.arrangedObjects.insertItems(bonds, atIndexes: indexSet)
        structure.bondController.selectedObjects.formUnion(indexSet)
        structure.bondController.tag()
      }
      
      fromItem.movies.remove(at: childIndex)
      
      if let currentSelectedScene = currentSelectedScene
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: currentSelectedScene.allRenderFrames)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      self.windowController?.masterTabViewController?.reloadData()
      self.windowController?.detailTabViewController?.reloadData()
      
      project.isEdited = true
      self.windowController?.currentDocument?.updateChangeCount(.changeDone)
      
      self.windowController?.detailTabViewController?.renderViewController?.clearMeasurement()
        
        self.windowController?.detailTabViewController?.renderViewController?.showTransformationPanel(oldSelectionEmpty: false, newSelectionEmpty: true)
      
      self.updateNetChargeTextField()
    }
  }
  
  func addMovieNode(_ movie: Movie, inItem: Scene, atIndex childIndex: Int, structure: Structure, atoms: [SKAtomTreeNode], from indexPaths: [IndexPath], bonds: [SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>], from indexSet: IndexSet, move: Bool)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let currentSelectedScene: Scene? = project.sceneList.selectedScene
      
      project.undoManager.registerUndo(withTarget: self, handler: {$0.removeMovieNode(movie, fromItem: inItem, atIndex: childIndex, structure: structure, atoms: atoms.reversed(), from: indexPaths.reversed(), bonds: bonds, from: indexSet, move: move)})
      if(!project.undoManager.isUndoing)
      {
        project.undoManager.setActionName(NSLocalizedString("Add Movies", comment: ""))
      }
      
      if(move)
      {
        for atom in atoms
        {
          structure.atomTreeController.removeNode(atom)
        }
      
        structure.atomTreeController.selectedTreeNodes = []

        structure.atomTreeController.tag()
        
        structure.bondController.arrangedObjects.remove(at: indexSet)
        structure.bondController.selectedObjects = []
        structure.bondController.tag()
      }
      
      if let newstructure = movie.frames.first?.frames.first?.structure
      {
        for (index, atom) in atoms.enumerated()
        {
          let assymetricAtom: SKAsymmetricAtom = SKAsymmetricAtom(original: atom.representedObject.copy())
          let treeNode: SKAtomTreeNode = SKAtomTreeNode(name: atom.displayName, representedObject: assymetricAtom)
          newstructure.atomTreeController.insertNode(treeNode, atArrangedObjectIndexPath: [index])
          newstructure.expandSymmetry(asymmetricAtom: assymetricAtom)
        }
        newstructure.atomTreeController.tag()
        
        newstructure.setRepresentationStyle(style: structure.atomRepresentationStyle)
        newstructure.setRepresentationType(type: structure.atomRepresentationType)
        
        if let document: iRASPADocument = self.windowController?.currentDocument
        {
          newstructure.setRepresentationForceField(forceField: newstructure.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)
        }
        
        newstructure.reComputeBoundingBox()
        newstructure.reComputeBonds()
        newstructure.bondController.tag()
      }
      
      
      
      project.renderCamera?.boundingBox = project.renderBoundingBox
     
      // make sure the movie has a selected-frame
      // (otherwise it does not show up in the RenderView)
      if movie.selectedFrame == nil
      {
        if let selectedFrame = movie.frames.first
        {
          movie.selectedFrame = selectedFrame
          movie.selectedFrames.insert(selectedFrame)
        }
      }
      
      
      // insert new node
      inItem.movies.insert(movie, at: childIndex)
      
      if let currentSelectedScene = currentSelectedScene
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: currentSelectedScene.allRenderFrames)
      }
      
      (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      self.windowController?.masterTabViewController?.reloadData()
      self.windowController?.detailTabViewController?.reloadData()
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      project.isEdited = true
      self.windowController?.currentDocument?.updateChangeCount(.changeDone)
      
      self.windowController?.detailTabViewController?.renderViewController?.clearMeasurement()
        
        self.windowController?.detailTabViewController?.renderViewController?.showTransformationPanel(oldSelectionEmpty: false, newSelectionEmpty: true)
      
      self.updateNetChargeTextField()
    }
  }
  
  @IBAction func selectionCopyToMovie(_ sender: NSMenuItem)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let iRASPAStructure: iRASPAStructure = self.representedObject as? iRASPAStructure,
       let currentSelectedScene: Scene = project.sceneList.selectedScene,
       let currentSelectedMovie: Movie = currentSelectedScene.selectedMovie,
       let index: Int = currentSelectedScene.movies.firstIndex(of: currentSelectedMovie)
    {
      let structure = iRASPAStructure.structure
      let frame: iRASPAStructure = iRASPAStructure.copy()
      let movie: Movie = Movie(frame: frame)
      
      movie.selectedFrame = frame
      movie.selectedFrames.insert(frame)
      
      let selectedAtoms: [SKAtomTreeNode] = structure.atomTreeController.selectedTreeNodes.sorted(by: { $0.indexPath > $1.indexPath })
      let indexPaths: [IndexPath] = selectedAtoms.map{$0.indexPath}
      
      let indexSet: IndexSet = structure.bondController.selectedObjects
      let selectedBonds: [SKAsymmetricBond] = structure.bondController.arrangedObjects[indexSet]
      
      self.addMovieNode(movie, inItem: currentSelectedScene, atIndex: index+1, structure: structure, atoms: selectedAtoms, from: indexPaths, bonds: selectedBonds,  from: indexSet, move: false)
    }
  }
  
  @IBAction func selectionMoveToMovie(_ sender: NSMenuItem)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let iRASPAStructure: iRASPAStructure = self.representedObject as? iRASPAStructure,
       let currentSelectedScene: Scene = project.sceneList.selectedScene,
       let currentSelectedMovie: Movie = currentSelectedScene.selectedMovie,
       let index: Int = currentSelectedScene.movies.firstIndex(of: currentSelectedMovie)
    {
      let structure: Structure = iRASPAStructure.structure
      let frame: iRASPAStructure = iRASPAStructure.copy()
      let movie: Movie = Movie(frame: frame)
      
      movie.selectedFrame = frame
      movie.selectedFrames.insert(frame)
      
      let selectedAtoms: [SKAtomTreeNode] = structure.atomTreeController.selectedTreeNodes.sorted(by: { $0.indexPath > $1.indexPath })
      let indexPaths: [IndexPath] = selectedAtoms.map{$0.indexPath}
      
      let indexSet: IndexSet = structure.bondController.selectedObjects
      let selectedBonds: [SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>] = structure.bondController.arrangedObjects[indexSet]
      
      self.addMovieNode(movie, inItem: currentSelectedScene, atIndex: index+1, structure: structure, atoms: selectedAtoms, from: indexPaths, bonds: selectedBonds, from: indexSet, move: true)
    }
  }
  
  @IBAction func visibilityInversion(_ sender: NSMenuItem)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let asymmetricAtoms: [SKAsymmetricAtom] = structure.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
      asymmetricAtoms.forEach{$0.isVisible = !$0.isVisible}
      
      if let structure = (self.representedObject as? iRASPAStructure)?.structure
      {
        structure.atomTreeController.tag()
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      let savedObserveNotifications = observeNotifications
      observeNotifications = false
      
      self.atomOutlineView?.reloadData()
      observeNotifications = savedObserveNotifications
    }
  }
  
  @IBAction func visibilityMatchSelection(_ sender: NSMenuItem)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let asymmetricAtoms: [SKAsymmetricAtom] = structure.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
      asymmetricAtoms.forEach{$0.isVisible = false}
      
      let selectedAsymmetricAtoms: [SKAsymmetricAtom] = structure.atomTreeController.selectedTreeNodes.compactMap{$0.representedObject}
      selectedAsymmetricAtoms.forEach{$0.isVisible = true}
      
      if let structure = (self.representedObject as? iRASPAStructure)?.structure
      {
        structure.atomTreeController.tag()
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      let savedObserveNotifications = observeNotifications
      observeNotifications = false
      
      self.atomOutlineView?.reloadData()
      observeNotifications = savedObserveNotifications
    }
  }
  
  @IBAction func checkBoxAction(_ sender: NSButton)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let row: Int = self.atomOutlineView?.row(for: sender)
    {
      let toggledState: Bool = sender.state == NSControl.StateValue.on
      if NSEvent.modifierFlags.contains(NSEvent.ModifierFlags.option)
      {
        if let structure = (self.representedObject as? iRASPAStructure)?.structure
        {
          let asymmetricAtoms: [SKAsymmetricAtom] = structure.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
          asymmetricAtoms.forEach{$0.isVisible = toggledState}
        }
      }
      else
      {
        if let treeNode: SKAtomTreeNode = self.atomOutlineView?.item(atRow: row) as? SKAtomTreeNode
        {
          let atom: SKAsymmetricAtom = treeNode.representedObject
          atom.isVisible = toggledState
          self.atomOutlineView?.reloadItem(treeNode, reloadChildren: true)
        }
      }
      
      if let structure = (self.representedObject as? iRASPAStructure)?.structure
      {
        structure.atomTreeController.tag()
      }
        
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
      let savedObserveNotifications = observeNotifications
      observeNotifications = false
      
      self.atomOutlineView?.reloadData()
      observeNotifications = savedObserveNotifications
    }
  }
  
  @IBAction func scrollToTop(_ sender: NSMenuItem)
  {
    if let numberOfRows = self.atomOutlineView?.numberOfRows, numberOfRows>0
    {
      self.atomOutlineView?.scrollRowToVisible(0)
    }
  }
  
  @IBAction func scrollToBottom(_ sender: NSMenuItem)
  {
    if let lastRow = self.atomOutlineView?.numberOfRows
    {
      self.atomOutlineView?.scrollRowToVisible(lastRow - 1)
    }
  }
  
  @IBAction func scrollToFirstSelected(_ sender: NSMenuItem)
  {
    if let selectedRowIndexSet = self.atomOutlineView?.selectedRowIndexes,
       let firstSelectedRow = selectedRowIndexSet.first
    {
      self.atomOutlineView?.scrollRowToVisible(firstSelectedRow)
    }
  }
  
  @IBAction func scrollToLastSelected(_ sender: NSMenuItem)
  {
    if let selectedRowIndexSet = self.atomOutlineView?.selectedRowIndexes,
       let lastSelectedRow = selectedRowIndexSet.last
    {
      self.atomOutlineView?.scrollRowToVisible(lastSelectedRow)
    }
  }
  
  @IBAction func exportAsPDB(_ sender: NSMenuItem)
  {
    if let structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let state: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.superCell
      
      // PDB uses Cartesian coordinates
      let exportAtoms: [SKAsymmetricAtom] = state.atoms.flattenedLeafNodes().compactMap{$0.representedObject}.compactMap({ (atomModel) -> SKAsymmetricAtom? in
        atomModel.position = structure.absoluteCartesianModelPosition(for: atomModel.position, replicaPosition: SIMD3<Int32>())
        return atomModel
      })
      
      let stringData: String
      switch(structure)
      {
      case let crystal as Crystal:
        stringData = SKPDBWriter.shared.string(displayName: crystal.displayName,spaceGroupHallNumber: 1, cell: crystal.cell, atoms: exportAtoms, origin: SIMD3<Double>(0,0,0))
      case let proteinCrystal as ProteinCrystal:
        stringData = SKPDBWriter.shared.string(displayName: proteinCrystal.displayName,spaceGroupHallNumber: 1, cell: proteinCrystal.cell, atoms: exportAtoms, origin: SIMD3<Double>(0,0,0))
      case let crystal as MolecularCrystal:
        stringData = SKPDBWriter.shared.string(displayName: crystal.displayName,spaceGroupHallNumber: 1, cell: crystal.cell, atoms: exportAtoms, origin: SIMD3<Double>(0,0,0))
      case let protein as Protein:
        let boundingBox = protein.cell.boundingBox
        stringData = SKPDBWriter.shared.string(displayName: protein.displayName,spaceGroupHallNumber: 1, cell: SKCell(boundingBox: boundingBox), atoms: exportAtoms, origin: boundingBox.minimum)
      case let molecule as Molecule:
        let boundingBox = molecule.cell.boundingBox
        stringData = SKPDBWriter.shared.string(displayName: molecule.displayName,spaceGroupHallNumber: 1, cell: SKCell(boundingBox: boundingBox), atoms: exportAtoms, origin: boundingBox.minimum)
      default:
        stringData = ""
        break
      }
        
      let savePanel: NSSavePanel = NSSavePanel()
      savePanel.allowedFileTypes = ["pdb"]
      savePanel.nameFieldStringValue = "\(structure.displayName).pdb"
      savePanel.canSelectHiddenExtension = true
      
      let attributedString: NSAttributedString = NSAttributedString(string: "Note: Precision was lost when converting to PDB-format.")
      let accessoryView: NSView = NSView(frame: NSMakeRect(0.0, 0.0, 400, 20.0))
      let textView: NSTextView = NSTextView(frame: NSMakeRect(0.0, 2.0, 400, 16.0))
      textView.drawsBackground = false
      textView.isEditable = false
      textView.textStorage?.setAttributedString(attributedString)
      accessoryView.addSubview(textView)
      savePanel.accessoryView = textView
      
      savePanel.beginSheetModal(for: self.view.window!, completionHandler: { (result) -> Void in
        if result == NSApplication.ModalResponse.OK
        {
          if let url = savePanel.url
          {
            do
            {
              try stringData.write(to: url, atomically: true, encoding: String.Encoding.utf8)
            }
            catch
            {
              
            }
          }
        }
      })
    }
  }
  
  @IBAction func exportAsMMCIF(_ sender: NSMenuItem)
  {
    if let structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let atoms: [SKAsymmetricAtom] = structure.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
      
      
      let stringData: String
      switch(structure)
      {
      case let crystal as Crystal:
        stringData = SKmmCIFWriter.shared.string(displayName: crystal.displayName, spaceGroupHallNumber: crystal.spaceGroupHallNumber, cell: crystal.cell, atoms: atoms, atomsAreFractional: true, exportFractional: false, withProteinInfo: false, origin: SIMD3<Double>(0,0,0))
      case let proteinCrystal as ProteinCrystal:
        stringData = SKmmCIFWriter.shared.string(displayName: proteinCrystal.displayName, spaceGroupHallNumber: proteinCrystal.spaceGroupHallNumber, cell: proteinCrystal.cell, atoms: atoms, atomsAreFractional: false, exportFractional: false, withProteinInfo: true, origin: SIMD3<Double>(0,0,0))
      case let molecularCrystal as MolecularCrystal:
        stringData = SKmmCIFWriter.shared.string(displayName: molecularCrystal.displayName, spaceGroupHallNumber: molecularCrystal.spaceGroupHallNumber, cell: molecularCrystal.cell, atoms: atoms, atomsAreFractional: false, exportFractional: false, withProteinInfo: false, origin: SIMD3<Double>(0,0,0))
      case let protein as Protein:
        let boundingBox = protein.cell.boundingBox
        stringData = SKmmCIFWriter.shared.string(displayName: protein.displayName, spaceGroupHallNumber: protein.spaceGroupHallNumber, cell: SKCell(boundingBox: boundingBox), atoms: atoms, atomsAreFractional: false, exportFractional: false, withProteinInfo: true, origin: boundingBox.minimum)
      case let molecule as Molecule:
        let boundingBox = molecule.cell.boundingBox
        stringData = SKmmCIFWriter.shared.string(displayName: molecule.displayName, spaceGroupHallNumber: molecule.spaceGroupHallNumber, cell: SKCell(boundingBox: boundingBox), atoms: atoms, atomsAreFractional: false, exportFractional: false, withProteinInfo: false, origin: boundingBox.minimum)
      default:
        stringData = ""
        break
      }
      
      let savePanel: NSSavePanel = NSSavePanel()
      savePanel.allowedFileTypes = ["cif"]
      savePanel.nameFieldStringValue = "\(structure.displayName).cif"
      savePanel.canSelectHiddenExtension = true
      
      savePanel.beginSheetModal(for: self.view.window!, completionHandler: { (result) -> Void in
        if result == NSApplication.ModalResponse.OK
        {
          if let url = savePanel.url
          {
            do
            {
              try stringData.write(to: url, atomically: true, encoding: String.Encoding.utf8)
            }
            catch
            {
              
            }
          }
        }
      })
    }
  }
  
  @IBAction func exportAsCIF(_ sender: NSMenuItem)
  {
    if let structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let atoms: [SKAsymmetricAtom] = structure.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
      
      
      let stringData: String
      switch(structure)
      {
      case let crystal as Crystal:
        stringData = SKCIFWriter.shared.string(displayName: crystal.displayName, spaceGroupHallNumber: crystal.spaceGroupHallNumber, cell: crystal.cell, atoms: atoms, exportFractional: true, origin: SIMD3<Double>(0,0,0))
      case let proteinCrystal as ProteinCrystal:
        stringData = SKCIFWriter.shared.string(displayName: proteinCrystal.displayName, spaceGroupHallNumber: proteinCrystal.spaceGroupHallNumber, cell: proteinCrystal.cell, atoms: atoms, exportFractional: false, origin: SIMD3<Double>(0,0,0))
      case let molecularCrystal as MolecularCrystal:
        stringData = SKCIFWriter.shared.string(displayName: molecularCrystal.displayName, spaceGroupHallNumber: molecularCrystal.spaceGroupHallNumber, cell: molecularCrystal.cell, atoms: atoms, exportFractional: false, origin: SIMD3<Double>(0,0,0))
      case let protein as Protein:
        let boundingBox = protein.cell.boundingBox
        stringData = SKCIFWriter.shared.string(displayName: protein.displayName, spaceGroupHallNumber: protein.spaceGroupHallNumber, cell: SKCell(boundingBox: boundingBox), atoms: atoms, exportFractional: false, origin: boundingBox.minimum)
      case let molecule as Molecule:
        let boundingBox = molecule.cell.boundingBox
        stringData = SKCIFWriter.shared.string(displayName: molecule.displayName, spaceGroupHallNumber: molecule.spaceGroupHallNumber, cell: SKCell(boundingBox: boundingBox), atoms: atoms, exportFractional: false, origin: boundingBox.minimum)
      default:
        stringData = ""
        break
      }
      
      let savePanel: NSSavePanel = NSSavePanel()
      savePanel.allowedFileTypes = ["cif"]
      savePanel.nameFieldStringValue = "\(structure.displayName).cif"
      savePanel.canSelectHiddenExtension = true
      
      savePanel.beginSheetModal(for: self.view.window!, completionHandler: { (result) -> Void in
        if result == NSApplication.ModalResponse.OK
        {
          if let url = savePanel.url
          {
            do
            {
              try stringData.write(to: url, atomically: true, encoding: String.Encoding.utf8)
            }
            catch
            {
              
            }
          }
        }
      })
    }
  }
  
  @IBAction func exportAsXYZ(_ sender: NSMenuItem)
  {
    if let structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let asymmetricAtoms: [SKAsymmetricAtom] = structure.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
      let atoms: [(Int, SIMD3<Double>)] = asymmetricAtoms.flatMap{$0.copies}.compactMap{($0.asymmetricParentAtom.elementIdentifier,structure.absoluteCartesianModelPosition(for: $0.position, replicaPosition: SIMD3<Int32>()) )}
      
      let stringData: String
      switch(structure)
      {
      case let crystal as Crystal:
        let unitCell = crystal.cell.unitCell
        let commentString = "Lattice=\"\(unitCell[0][0]) \(unitCell[0][1]) \(unitCell[0][2]) \(unitCell[1][0]) \(unitCell[1][1]) \(unitCell[1][2]) \(unitCell[2][0]) \(unitCell[2][1]) \(unitCell[2][2])\" "
        stringData = SKXYZWriter.shared.string(displayName: crystal.displayName,  commentString: commentString, atoms: atoms, origin: SIMD3<Double>(0,0,0))
      case let proteinCrystal as ProteinCrystal:
        let unitCell = proteinCrystal.cell.unitCell
        let commentString = "Lattice=\"\(unitCell[0][0]) \(unitCell[0][1]) \(unitCell[0][2]) \(unitCell[1][0]) \(unitCell[1][1]) \(unitCell[1][2]) \(unitCell[2][0]) \(unitCell[2][1]) \(unitCell[2][2])\" "
        stringData = SKXYZWriter.shared.string(displayName: proteinCrystal.displayName,  commentString: commentString, atoms: atoms, origin: SIMD3<Double>(0,0,0))
      case let molecularCrystal as MolecularCrystal:
        let unitCell = molecularCrystal.cell.unitCell
        let commentString = "Lattice=\"\(unitCell[0][0]) \(unitCell[0][1]) \(unitCell[0][2]) \(unitCell[1][0]) \(unitCell[1][1]) \(unitCell[1][2]) \(unitCell[2][0]) \(unitCell[2][1]) \(unitCell[2][2])\" "
        stringData = SKXYZWriter.shared.string(displayName: molecularCrystal.displayName,  commentString: commentString, atoms: atoms, origin: SIMD3<Double>(0,0,0))
      case let protein as Protein:
        let boundingBox = protein.cell.boundingBox
        let unitCell = SKCell(boundingBox: boundingBox).unitCell
        let commentString = "Lattice=\"\(unitCell[0][0]) \(unitCell[0][1]) \(unitCell[0][2]) \(unitCell[1][0]) \(unitCell[1][1]) \(unitCell[1][2]) \(unitCell[2][0]) \(unitCell[2][1]) \(unitCell[2][2])\" "
        stringData = SKXYZWriter.shared.string(displayName: protein.displayName,  commentString: commentString, atoms: atoms, origin: boundingBox.minimum)
      case let molecule as Molecule:
        let boundingBox = molecule.cell.boundingBox
        let unitCell = SKCell(boundingBox: boundingBox).unitCell
        let commentString = "Lattice=\"\(unitCell[0][0]) \(unitCell[0][1]) \(unitCell[0][2]) \(unitCell[1][0]) \(unitCell[1][1]) \(unitCell[1][2]) \(unitCell[2][0]) \(unitCell[2][1]) \(unitCell[2][2])\" "
        stringData = SKXYZWriter.shared.string(displayName: molecule.displayName,  commentString: commentString, atoms: atoms, origin: boundingBox.minimum)
      default:
        stringData = ""
        break
      }
      
      
      let savePanel: NSSavePanel = NSSavePanel()
      savePanel.allowedFileTypes = ["xyz"]
      savePanel.nameFieldStringValue = "\(structure.displayName).xyz"
      savePanel.canSelectHiddenExtension = true
      
      let attributedString: NSAttributedString = NSAttributedString(string: "Note: Any information on the unit-cell is lost.")
      let accessoryView: NSView = NSView(frame: NSMakeRect(0.0, 0.0, 400, 20.0))
      let textView: NSTextView = NSTextView(frame: NSMakeRect(0.0, 2.0, 400, 16.0))
      textView.drawsBackground = false
      textView.isEditable = false
      textView.textStorage?.setAttributedString(attributedString)
      accessoryView.addSubview(textView)
      savePanel.accessoryView = textView
      
      savePanel.beginSheetModal(for: self.view.window!, completionHandler: { (result) -> Void in
        if result == NSApplication.ModalResponse.OK
        {
          if let url = savePanel.url
          {
            do
            {
              try stringData.write(to: url, atomically: true, encoding: String.Encoding.utf8)
            }
            catch
            {
              
            }
          }
        }
      })
    }
  }
  
  // VASP: positions between 0.0 and 1.0
  // if "atomsAreFractional" is true, then fractional positions are written, otherwise Cartesian
  @IBAction func exportAsVASP(_ sender: NSMenuItem)
  {
    if let structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let asymmetricAtoms: [SKAsymmetricAtom] = structure.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
      let atomCopies: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
      
      let stringData: String
      switch(structure)
      {
      case let crystal as Crystal:
        let atoms: [(Int, SIMD3<Double>, Bool3)] = atomCopies.compactMap{($0.asymmetricParentAtom.elementIdentifier, fract($0.position), $0.asymmetricParentAtom.isFixed)}
        stringData = SKVASPWriter.shared.string(displayName: crystal.displayName, cell: crystal.cell , atoms: atoms, atomsAreFractional: true, origin: SIMD3<Double>(0,0,0))
      case let proteinCrystal as ProteinCrystal:
        let atoms: [(Int, SIMD3<Double>, Bool3)] = atomCopies.compactMap{($0.asymmetricParentAtom.elementIdentifier, fract($0.position), $0.asymmetricParentAtom.isFixed)}
        stringData = SKVASPWriter.shared.string(displayName: proteinCrystal.displayName, cell: proteinCrystal.cell, atoms: atoms, atomsAreFractional: false, origin: SIMD3<Double>(0,0,0))
      case let molecularCrystal as MolecularCrystal:
        let atoms: [(Int, SIMD3<Double>, Bool3)] = atomCopies.compactMap{($0.asymmetricParentAtom.elementIdentifier, $0.position, $0.asymmetricParentAtom.isFixed)}
        stringData = SKVASPWriter.shared.string(displayName: molecularCrystal.displayName, cell: molecularCrystal.cell, atoms: atoms, atomsAreFractional: false, origin: SIMD3<Double>(0,0,0))
      case let protein as Protein:
        let boundingBox = protein.cell.boundingBox
        let atoms: [(Int, SIMD3<Double>, Bool3)] = atomCopies.compactMap{($0.asymmetricParentAtom.elementIdentifier, $0.position, $0.asymmetricParentAtom.isFixed)}
        stringData = SKVASPWriter.shared.string(displayName: protein.displayName, cell: SKCell(boundingBox: boundingBox), atoms: atoms, atomsAreFractional: false, origin: boundingBox.minimum)
      case let molecule as Molecule:
        let boundingBox = molecule.cell.boundingBox
        let atoms: [(Int, SIMD3<Double>, Bool3)] = atomCopies.compactMap{($0.asymmetricParentAtom.elementIdentifier, $0.position, $0.asymmetricParentAtom.isFixed)}
        stringData = SKVASPWriter.shared.string(displayName: molecule.displayName, cell: SKCell(boundingBox: boundingBox), atoms: atoms, atomsAreFractional: false, origin: boundingBox.minimum)
      default:
        stringData = ""
        break
      }
      
      
      let savePanel: NSSavePanel = NSSavePanel()
      savePanel.allowedFileTypes = ["poscar"]
      savePanel.nameFieldStringValue = "\(structure.displayName).poscar"
      savePanel.canSelectHiddenExtension = true
      
      
      savePanel.beginSheetModal(for: self.view.window!, completionHandler: { (result) -> Void in
        if result == NSApplication.ModalResponse.OK
        {
          if let url = savePanel.url
          {
            do
            {
              try stringData.write(to: url, atomically: true, encoding: String.Encoding.utf8)
            }
            catch
            {
              
            }
          }
        }
      })
    }
  }
  
  
  func outlineView(_ outlineView: NSOutlineView, mouseDownInHeaderOf tableColumn: NSTableColumn)
  {
    outlineView.window?.makeFirstResponder(outlineView)
  }
  
  
  
  // MARK: Search and filter
  // =====================================================================
  
  
  @IBAction func updateFilterAction(_ sender: NSSearchField)
  {
    let searchString: String = sender.stringValue
    
    if (searchString.isEmpty)
    {
      // restore no filtering
      if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
      {
        structure.atomTreeController.filterPredicate = {_ in return true}
        structure.atomTreeController.updateFilteredNodes()
        filterContent = false
        
        self.observeNotifications = false
        
        // reload all available items and reacquire all views
        self.atomOutlineView?.reloadData()
        self.programmaticallySetSelection()
        
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
        self.observeNotifications = true
      }
    }
    else
    {
      // filter
      if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
      {
        structure.atomTreeController.filterPredicate = {
          atomTreeNode in
          let nodeString =  atomTreeNode.representedObject.displayName
          return nodeString.range(of: searchString, options: [.caseInsensitive,.regularExpression]) != nil
        }
        filterContent = true
        structure.atomTreeController.updateFilteredNodes()
        
        self.observeNotifications = false
        
        // reload all available items and reacquire all views
        self.atomOutlineView?.reloadData()
        self.convertSelectionToFilteredSelection()
        self.programmaticallySetSelection()
        
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
        self.observeNotifications = true
      }
    }
    
  }
  
  // MARK: Edit tableview
  // =====================================================================
  
  

  func fixAsymmetricAtom(_ atomNode: SKAtomTreeNode, to isFixed: Bool3)
  {
    let asymmetricAtom = atomNode.representedObject
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
       let row: Int = self.atomOutlineView?.row(forItem: atomNode), row >= 0
    {
      let oldIsFixed: Bool3 = asymmetricAtom.isFixed
      
      project.undoManager.registerUndo(withTarget: self, handler: {$0.fixAsymmetricAtom(atomNode, to: oldIsFixed)})
        
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Change Fix Atom", comment: ""))
      }
      
      asymmetricAtom.isFixed = isFixed
      
      proxyProject.representedObject.isEdited = true
      
      // Update at the next iteration (reloading could be in progress)
      DispatchQueue.main.async(execute: {
        if let column: Int = (self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomFixedColumn")))
        {
          NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: (self.representedObject as? iRASPAStructure)?.structure)
          self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: column))
        }
      })
    }
  }
  
  @IBAction func fixAtom(_ sender: NSSegmentedControl)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let row: Int = self.atomOutlineView?.row(for: sender.superview!), row >= 0
    {
      self.atomOutlineView?.window?.makeFirstResponder(self.atomOutlineView)
      if let atomNode: SKAtomTreeNode = self.atomOutlineView?.item(atRow: row) as? SKAtomTreeNode
      {
        let isFixed: Bool3
        if NSEvent.modifierFlags.contains(NSEvent.ModifierFlags.option)
        {
          isFixed = Bool3(sender.isSelected(forSegment: 0),sender.isSelected(forSegment: 1),sender.isSelected(forSegment: 2))
        }
        else
        {
          let state: Bool = sender.isSelected(forSegment: sender.selectedSegment)
          isFixed = Bool3(state, state, state)
        }
        self.fixAsymmetricAtom(atomNode, to: isFixed)
      }
    }
  }

  
  func setAtomName(_ atomTreeNode: SKAtomTreeNode, to newValue: String)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let atom = atomTreeNode.representedObject
      let oldName: String = atom.displayName
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setAtomName(atomTreeNode, to: oldName)})
      
      if project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Change Atom Name", comment: "Change atom name"))
      }
      atomTreeNode.representedObject.displayName = newValue
      
      //atomTreeNode.representedObject.uniqueForceFieldName = newValue
      
      // reload item in the outlineView
      if let row: Int = self.atomOutlineView?.row(forItem: atomTreeNode), row >= 0
      {
        // work around bug that causes 'reloadItem' to not do anything
        if let column: Int = (self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomNameColumn")))
        {
          self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: column))
        }
      }

      self.proxyProject?.representedObject.isEdited = true
      
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      /*
      if structure.atomForceFieldOrder != .elementOnly
      {
        structure.setRepresentationForceField(forceField: structure.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)
        self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        self.windowController?.detailTabViewController?.renderViewController?.redraw()
      }
 */
    }
  }
  
  
  @IBAction func changedName(_ sender: NSTextField)
  {
    let newValue: String = sender.stringValue
    
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let row: Int = self.atomOutlineView?.row(for: sender.superview!), row >= 0,
       let node: SKAtomTreeNode = self.atomOutlineView?.item(atRow: row) as? SKAtomTreeNode
    {
      setAtomName(node, to: newValue)
    }
  }
  
  // let element: Element = Elements.sharedInstance.element[atomNode.elementId]
  // view!.textField!.stringValue=element.chemicalSymbol
  
  func setAtomElement(_ atomTreeNode: SKAtomTreeNode, to newElementId: Int)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let atom = atomTreeNode.representedObject
      let oldId: Int = atom.elementIdentifier
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setAtomElement(atomTreeNode, to: oldId)})
      if project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Change Atom Element", comment: ""))
      }
      
      atom.elementIdentifier = newElementId
      
      structure.setRepresentationStyle(style: structure.atomRepresentationStyle, for: [atom])
      structure.setRepresentationType(type: structure.atomRepresentationType, for: [atom])
      structure.setRepresentationColorScheme(scheme: structure.atomColorSchemeIdentifier, colorSets: document.colorSets)
      
      // reload item in the outlineView
      if let row: Int = self.atomOutlineView?.row(forItem: atomTreeNode), row >= 0
      {
        // work around bug that causes 'reloadItem' to not do anything
        if let column: Int = self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomElementColumn"))
        {
          self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: column))
        }
      }
      
      // reload: the size and influence of the atom has changed
      
      structure.reComputeBonds()
      
      structure.reComputeBoundingBox()
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
  self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      project.isEdited = true
    }
  }
  
  func setForceFieldType(_ atomTreeNode: SKAtomTreeNode, to newUniqueForceFieldName: String)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let atom = atomTreeNode.representedObject
      let oldId: String = atom.uniqueForceFieldName
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setForceFieldType(atomTreeNode, to: oldId)})
      if project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Change Atom Force Field Type", comment: ""))
      }
      
      atom.uniqueForceFieldName  = newUniqueForceFieldName
      
      structure.setRepresentationColorScheme(scheme: structure.atomColorSchemeIdentifier, colorSets: document.colorSets)
      structure.setRepresentationForceField(forceField: structure.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)
      
      // reload item in the outlineView
      if let row: Int = self.atomOutlineView?.row(forItem: atomTreeNode), row >= 0
      {
        // work around bug that causes 'reloadItem' to not do anything
        if let column: Int = self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomUniqueForceFieldIdentifierColumn"))
        {
          self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: column))
        }
      }
      
      // reload: the size and influence of the atom has changed
     
      structure.reComputeBonds()
      
      structure.reComputeBoundingBox()
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      project.isEdited = true
    }
  }
  
  @IBAction func changedElement(_ sender: NSTextField)
  {
    let elementName: String = sender.stringValue
    
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let row: Int = self.atomOutlineView?.row(for: sender.superview!), row >= 0,
       let atomTreeNode: SKAtomTreeNode = self.atomOutlineView?.item(atRow: row) as? SKAtomTreeNode
    {
      if let atomicNumber: Int = SKElement.atomData[elementName.capitalizeFirst]?["atomicNumber"] as? Int
      {
        setAtomElement(atomTreeNode, to: atomicNumber)
      }
      else
      {
        // reload item in the outlineView
        if let row: Int = self.atomOutlineView?.row(forItem: atomTreeNode), row >= 0
        {
          // work around bug that causes 'reloadItem' to not do anything
          if let column: Int = self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomElementColumn"))
          {
            self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: column))
          }
        }
        LogQueue.shared.error(destination: self.windowController, message: "Element \(elementName) unknown. Select correct element type.")
      }
    }
  }
  
  @IBAction func changedUniqueForceFieldIdentifier(_ sender: NSTextField)
  {
    let uniqueForceFieldName: String = sender.stringValue
    
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let row: Int = self.atomOutlineView?.row(for: sender.superview!), row >= 0,
       let node: SKAtomTreeNode = self.atomOutlineView?.item(atRow: row) as? SKAtomTreeNode
    {
      setForceFieldType(node, to: uniqueForceFieldName)
    }
  }
  
  func setAtomPositionX(_ atomTreeNode: SKAtomTreeNode, to newValue: Double)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
        let atom = atomTreeNode.representedObject
      let oldPosition: Double = atom.position.x
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setAtomPositionX(atomTreeNode, to: oldPosition)})
      
      if project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Change Atom X-Position", comment: ""))
      }
      atom.position.x = newValue
      
      structure.expandSymmetry(asymmetricAtom: atom)
      
      // reload item in the outlineView
      if let row: Int = self.atomOutlineView?.row(forItem: atomTreeNode), row >= 0
      {
        // work around bug that causes 'reloadItem' to not do anything
        if let column: Int = self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomPositionXColumn"))
        {
          self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: column))
        }
      }
      
      structure.reComputeBoundingBox()
      
      structure.bondController.selectedObjects = []
      structure.reComputeBonds()
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
  self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      project.isEdited = true
    }
  }
  
  
  @IBAction func changedPositionX(_ sender: NSTextField)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let row: Int = self.atomOutlineView?.row(for: sender.superview!), row >= 0,
       let node: SKAtomTreeNode = self.atomOutlineView?.item(atRow: row) as? SKAtomTreeNode
    {
      let atom = node.representedObject
      // make sure we can convert it to a number
      if let _: NSNumber = fullPrecisionNumberFormatter.number(from: sender.stringValue)
      {
        // but use the full precision from the textField
        setAtomPositionX(node, to: sender.doubleValue)
      }
      else
      {
        // reset value if the input is not correct
        sender.doubleValue = atom.position.x
      }
    }
  }
  
  
  func setAtomPositionY(_ atomTreeNode: SKAtomTreeNode, to newValue: Double)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let atom = atomTreeNode.representedObject
      let oldPosition: Double = atom.position.y
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setAtomPositionY(atomTreeNode, to: oldPosition)})
      
      if project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Change Atom Y-Position", comment: ""))
      }
      atom.position.y = newValue
      
      structure.expandSymmetry(asymmetricAtom: atom)
      
      // reload item in the outlineView
      if let row: Int = self.atomOutlineView?.row(forItem: atomTreeNode), row >= 0
      {
        // work around bug that causes 'reloadItem' to not do anything
        if let column: Int = self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomPositionYColumn"))
        {
          self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: column))
        }
      }
      
      structure.reComputeBoundingBox()
      
      structure.bondController.selectedObjects = []
      structure.reComputeBonds()
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
  self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      project.isEdited = true
    }
  }
  
  @IBAction func changedPositionY(_ sender: NSTextField)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let row: Int = self.atomOutlineView?.row(for: sender.superview!), row >= 0,
       let node: SKAtomTreeNode = self.atomOutlineView?.item(atRow: row) as? SKAtomTreeNode
    {
      let atom = node.representedObject
      // make sure we can convert it to a number
      if let _: NSNumber = fullPrecisionNumberFormatter.number(from: sender.stringValue)
      {
        // but use the full precision from the textField
        setAtomPositionY(node, to: sender.doubleValue)
      }
      else
      {
        // reset value if the input is not correct
        sender.doubleValue = atom.position.y
      }
    }
  }
  
  
  func setAtomPositionZ(_ atomTreeNode: SKAtomTreeNode, to newValue: Double)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let atom = atomTreeNode.representedObject
      let oldPosition: Double = atom.position.z
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setAtomPositionZ(atomTreeNode, to: oldPosition)})
 
      if project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Change Atom Z-position", comment: ""))
      }
      atom.position.z = newValue
     
      structure.expandSymmetry(asymmetricAtom: atom)
      
      // reload item in the outlineView
      if let row: Int = self.atomOutlineView?.row(forItem: atomTreeNode), row >= 0
      {
        // work around bug that causes 'reloadItem' to not do anything
        if let column: Int = self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomPositionZColumn"))
        {
          self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: column))
        }
      }
      
      structure.reComputeBoundingBox()
      
      structure.bondController.selectedObjects = []
      structure.reComputeBonds()
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      project.isEdited = true
    }
  }
  
  @IBAction func changedPositionZ(_ sender: NSTextField)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let row: Int = self.atomOutlineView?.row(for: sender.superview!), row >= 0,
       let node: SKAtomTreeNode = self.atomOutlineView?.item(atRow: row) as? SKAtomTreeNode
    {
      let atom = node.representedObject
      // make sure we can convert it to a number
      if let _: NSNumber = fullPrecisionNumberFormatter.number(from: sender.stringValue)
      {
        // but use the full precision from the textField
        setAtomPositionZ(node, to: sender.doubleValue)
      }
      else
      {
        // reset value if the input is not correct
        sender.doubleValue = atom.position.z
      }
    }
  }
  
  
  
  func setAtomCharge(_ atomTreeNode: SKAtomTreeNode, to newValue: Double)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let atom = atomTreeNode.representedObject
      let oldChargeValue: Double = atom.charge
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setAtomCharge(atomTreeNode, to: oldChargeValue)})
      
      if project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Change Atom Charge", comment: ""))
      }
      atomTreeNode.representedObject.charge = newValue
      
      // reload item in the outlineView
      if let row: Int = self.atomOutlineView?.row(forItem: atomTreeNode), row >= 0
      {
        // work around bug that causes 'reloadItem' to not do anything
        if let column: Int = self.atomOutlineView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "atomChargeColumn"))
        {
          self.atomOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: column))
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateNetChargeTextField()
    }
  }
  
  @IBAction func changedCharge(_ sender: NSTextField)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let row: Int = self.atomOutlineView?.row(for: sender.superview!), row >= 0,
       let node: SKAtomTreeNode = self.atomOutlineView?.item(atRow: row) as? SKAtomTreeNode
    {
      setAtomCharge(node, to: sender.doubleValue)
    }
  }
}
