/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import simd
import RenderKit
import iRASPAKit
import SymmetryKit
import MathKit

class StructureBondDetailViewController: NSViewController, NSMenuItemValidation,WindowControllerConsumer, NSTableViewDataSource, NSTableViewDelegate, ProjectConsumer, Reloadable
{
  @IBOutlet private weak var bondTableView: NSTableView?
  @IBOutlet private var bondContextMenu: NSMenu?
  
  weak var windowController: iRASPAWindowController?
  
  // MARK: protocol ProjectConsumer
  // =====================================================================
  
  weak var proxyProject: ProjectTreeNode?
    
  var bondDictionary : [SKAsymmetricBond<SKAsymmetricAtom,SKAsymmetricAtom> : Set<SKBondNode>] = [:]
  var bondKeys: [SKAsymmetricBond<SKAsymmetricAtom,SKAsymmetricAtom>] = []
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    self.bondTableView?.dataSource = nil
    self.bondTableView?.delegate = nil
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    self.bondTableView?.doubleAction = #selector(bondViewDoubleClick(_:))
  }
  
  @objc func bondViewDoubleClick(_ sender: AnyObject)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let clickedColumn: Int = self.bondTableView?.clickedColumn, clickedColumn >= 0,
       let clickedRow: Int = self.bondTableView?.clickedRow, clickedRow >= 0,
       let identifier: String = (self.bondTableView?.tableColumns[clickedColumn].identifier).map({ $0.rawValue })
    {
      switch(identifier)
      {
      case "bondLengthColumn":
        self.bondTableView?.editColumn(clickedColumn, row: clickedRow, with: nil, select: false)
      default:
        break
      }
    }
  }
  
  override func viewWillAppear()
  {
    super.viewWillAppear()
    
    self.bondTableView?.dataSource = self
    self.bondTableView?.delegate = self
    
    self.reloadData()
  }
  
  override func viewDidAppear()
  {
    super.viewDidAppear()
    
    NotificationCenter.default.addObserver(self, selector: #selector(StructureBondDetailViewController.reloadData), name: NSNotification.Name(rawValue: NotificationStrings.RendererSelectionDidChangeNotification), object: windowController)
    
    if let structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      NotificationCenter.default.addObserver(self, selector: #selector(StructureBondDetailViewController.reloadData), name: NSNotification.Name(rawValue: NotificationStrings.BondsShouldReloadNotification), object: structure)
    }
  }
  
  // the windowController still exists when the view is there
  override func viewWillDisappear()
  {
    super.viewWillDisappear()
    
    self.bondTableView?.dataSource = nil
    self.bondTableView?.delegate = nil
    
    if let structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationStrings.BondsShouldReloadNotification), object: structure)
    }
  }
  
  
  @objc func reloadData()
  {
    bondDictionary = [:]
    bondKeys = []
    
    if let structure: Structure =  (self.representedObject as? iRASPAStructure)?.structure
    {
      
      for bond in (structure.bonds.arrangedObjects.filter{$0.atom1.type == .copy && $0.atom2.type == .copy})
      {
        let asymmetricBond: SKAsymmetricBond = SKAsymmetricBond(bond.atom1.asymmetricParentAtom, bond.atom2.asymmetricParentAtom)
        
        if bondDictionary[asymmetricBond] == nil
        {
          bondDictionary[asymmetricBond] = [bond]
        }
        else
        {
          bondDictionary[asymmetricBond]?.insert(bond)
        }
      }
      
      bondKeys = Array(bondDictionary.keys).sorted{
          if $0.atom1.elementIdentifier == $1.atom1.elementIdentifier
          {
            if $0.atom2.elementIdentifier == $1.atom2.elementIdentifier
            {
              if $0.atom1.tag == $1.atom1.tag
              {
                return $0.atom2.tag < $1.atom2.tag
              }
              else
              {
                return $0.atom1.tag < $1.atom1.tag
              }
            }
            else
            {
              return $0.atom2.elementIdentifier > $1.atom2.elementIdentifier
            }
          }
          else
          {
            return $0.atom1.elementIdentifier > $1.atom1.elementIdentifier
          }
      }
    }
    self.bondTableView?.reloadData()
    self.programmaticallySetSelection()
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int
  {
    if let _ =  (self.representedObject as? iRASPAStructure)?.structure
    {
      return bondKeys.count
    }
    return 0
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
  {
    var view: NSTableCellView? = nil
    
    if let proxyProject: ProjectTreeNode = self.proxyProject,
       let tableColumn = tableColumn,
       let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let asymmetricBond: SKAsymmetricBond = bondKeys[row]
      guard let bond: SKBondNode = bondDictionary[asymmetricBond]?.first else {return nil}
      let bondLength = structure.bondLength(bond)
      switch(tableColumn.identifier)
      {
      case NSUserInterfaceItemIdentifier(rawValue: "bondVisibilityColumn"):
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "bondVisibility"), owner: self) as? NSTableCellView
        if let checkBox: NSButton = view?.viewWithTag(10) as? NSButton
        {
          checkBox.state = bond.isVisible ? NSControl.StateValue.on : NSControl.StateValue.off
          checkBox.isEnabled = proxyProject.isEnabled
        }
      case NSUserInterfaceItemIdentifier(rawValue: "bondIdColumn"):
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "bondIdRow"), owner: self) as? NSTableCellView
        view?.textField?.intValue = Int32(row)
        view?.textField?.isEditable = false
      case NSUserInterfaceItemIdentifier(rawValue: "bondFixedAtomColumn"):
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "fixedAtomsInBondRow"), owner: self) as? NSTableCellView
        if let segmentedControl: NSLabelSegmentedControl = view!.viewWithTag(11) as? NSLabelSegmentedControl
        {
          segmentedControl.label = NSString(string: String(bond.atom1.asymmetricParentAtom.tag))
          segmentedControl.setSelected(bond.atom1.asymmetricParentAtom.isFixed.x, forSegment: 0)
          segmentedControl.setSelected(bond.atom1.asymmetricParentAtom.isFixed.y, forSegment: 1)
          segmentedControl.setSelected(bond.atom1.asymmetricParentAtom.isFixed.z, forSegment: 2)
          segmentedControl.isEnabled = proxyProject.isEnabled
        }
        
        if let segmentedControl: NSLabelSegmentedControl = view!.viewWithTag(12) as? NSLabelSegmentedControl
        {
          segmentedControl.label = NSString(string: String(bond.atom2.asymmetricParentAtom.tag))
          segmentedControl.setSelected(bond.atom2.asymmetricParentAtom.isFixed.x, forSegment: 0)
          segmentedControl.setSelected(bond.atom2.asymmetricParentAtom.isFixed.y, forSegment: 1)
          segmentedControl.setSelected(bond.atom2.asymmetricParentAtom.isFixed.z, forSegment: 2)
          segmentedControl.isEnabled = proxyProject.isEnabled
        }
      case NSUserInterfaceItemIdentifier(rawValue: "bondFirstAtomColumn"):
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "bondFirstAtomRow"), owner: self) as? NSTableCellView
        let element: SKElement = PredefinedElements.sharedInstance.elementSet[bond.atom1.asymmetricParentAtom.elementIdentifier]
        view?.textField?.stringValue = element.chemicalSymbol
        view?.textField?.isEditable = false
      case NSUserInterfaceItemIdentifier(rawValue: "bondSecondAtomColumn"):
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "bondSecondAtomRow"), owner: self) as? NSTableCellView
        let element: SKElement = PredefinedElements.sharedInstance.elementSet[bond.atom2.asymmetricParentAtom.elementIdentifier]
        view?.textField?.stringValue = element.chemicalSymbol
        view?.textField?.isEditable = false
      case NSUserInterfaceItemIdentifier(rawValue: "bondLengthColumn"):
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "bondLengthRow"), owner: self) as? NSTableCellView
        view?.textField?.doubleValue = bondLength
        view?.textField?.isEditable = proxyProject.isEnabled
      case NSUserInterfaceItemIdentifier(rawValue: "bondLengthSliderColumn"):
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "bondLengthSliderRow"), owner: self) as? NSTableCellView
        let slider: NSSlider = view!.viewWithTag(11) as! NSSlider
        slider.doubleValue = bondLength
        slider.isEnabled = proxyProject.isEnabled
      default:
        view = nil
      }
    }
    
    return view
  }
  
  
  func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
  {
    return 18.0
  }
  
  func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView?
  {
    let view: NSTableRowView = NSTableRowView()
    view.wantsLayer = true
    view.canDrawSubviewsIntoLayer = true
    return view
  }
  
  
  // MARK: Edit tableview
  // =====================================================================
  
  func fixAsymmetricAtom(_ asymmetricAtom: SKAsymmetricAtom, to isFixed: Bool3)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      let oldIsFixed: Bool3 = asymmetricAtom.isFixed
      
      project.undoManager.registerUndo(withTarget: self, handler: {$0.fixAsymmetricAtom(asymmetricAtom, to: oldIsFixed)})
        
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Change fix atom", comment: "Change fix atom"))
      }
      
      asymmetricAtom.isFixed = isFixed
      for copy in asymmetricAtom.copies
      {
        copy.asymmetricParentAtom.isFixed = isFixed
      }
      
      proxyProject.representedObject.isEdited = true
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.AtomsShouldReloadNotification), object: (self.representedObject as? iRASPAStructure)?.structure)
      self.reloadData()
    }
  }
  
  @IBAction func fixAtom1(_ sender: NSSegmentedControl)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let row: Int = self.bondTableView?.row(for: sender.superview!), row >= 0
    {
      self.bondTableView?.window?.makeFirstResponder(self.bondTableView)
      
      let asymmetricAtom: SKAsymmetricAtom = bondKeys[row].atom1
      
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
      self.fixAsymmetricAtom(asymmetricAtom, to: isFixed)
    }
  }
  
  @IBAction func fixAtom2(_ sender: NSSegmentedControl)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let row: Int = self.bondTableView?.row(for: sender.superview!), row >= 0
    {
      self.bondTableView?.window?.makeFirstResponder(bondTableView)
      let asymmetricAtom: SKAsymmetricAtom = bondKeys[row].atom2
      
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
      self.fixAsymmetricAtom(asymmetricAtom, to: isFixed)
    }
  }
  

  func setBondAtomPositions(atom1: SKAsymmetricAtom, pos1: SIMD3<Double>, atom2: SKAsymmetricAtom, pos2: SIMD3<Double>)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let oldPos1: SIMD3<Double> = atom1.position
      let oldPos2: SIMD3<Double> = atom2.position
      if project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Change bond-length", comment: "Change bond-length"))
      }
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setBondAtomPositions(atom1: atom1, pos1: oldPos1, atom2: atom2, pos2: oldPos2)})
      
      atom1.position = pos1
      atom2.position = pos2
      
      structure.generateCopiesForAsymmetricAtom(atom1)
      structure.generateCopiesForAsymmetricAtom(atom2)
      
      structure.reComputeBoundingBox()
      structure.reComputeBonds()
      
      self.reloadData()
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      project.isEdited = true
      document.updateChangeCount(.changeDone)
    }
  }

  
  @IBAction func changedBondLengthTextField(_ sender: NSTextField)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure,
       let row: Int = self.bondTableView?.row(for: sender.superview!), row >= 0,
       let nf: NumberFormatter = sender.formatter as?  NumberFormatter,
       let number: NSNumber = nf.number(from: sender.stringValue)
    {
      let bond: SKAsymmetricBond = bondKeys[row]
      let asymmetricAtom1: SKAsymmetricAtom = bond.atom1
      let asymmetricAtom2: SKAsymmetricAtom = bond.atom2
      
      let bondLength: Double = number.doubleValue
      
      let newPos: (SIMD3<Double>, SIMD3<Double>) = (SIMD3<Double>(), SIMD3<Double>())
      //let newPos: (SIMD3<Double>, SIMD3<Double>) = structure.computeChangedBondLength(bond: bond, to: bondLength)
      setBondAtomPositions(atom1: asymmetricAtom1, pos1: newPos.0, atom2: asymmetricAtom2, pos2: newPos.1)
      
      
      if let view: NSTableCellView = self.bondTableView?.view(atColumn: 0, row: row, makeIfNecessary: false) as?  NSTableCellView,
         let sliderValue: NSSlider = view.viewWithTag(11) as? NSSlider
      {
        sliderValue.doubleValue = sender.doubleValue
      }
    }
    else
    {
      // reset value if the input is not correct
      //.doubleValue = atom.position.x
    }
  }
  
  @IBAction func changedBondLengthSlider(_ sender: NSSlider)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure,
       let row: Int = self.bondTableView?.row(for: sender.superview!), row >= 0
    {
      self.windowController?.window?.makeFirstResponder(self.bondTableView)
      
      // fast way of updating: get the current-view, set properties on it, and update the rect to redraw
      if let column: Int = self.bondTableView?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "bondLengthColumn")),
         let view: NSTableCellView = self.bondTableView?.view(atColumn: column, row: row, makeIfNecessary: false) as?  NSTableCellView,
         let textFieldBondLength: NSTextField = view.viewWithTag(10) as? NSTextField
      {
        textFieldBondLength.doubleValue = sender.doubleValue
      }
      
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if endingDrag
        {
          let bond: SKAsymmetricBond = bondKeys[row]
          let asymmetricAtom1: SKAsymmetricAtom = bond.atom1
          let asymmetricAtom2: SKAsymmetricAtom = bond.atom2
          
          let bondLength: Double = sender.doubleValue
          
          let newPos: (SIMD3<Double>, SIMD3<Double>) = (SIMD3<Double>(), SIMD3<Double>())
          //let newPos: (SIMD3<Double>, SIMD3<Double>) = structure.computeChangedBondLength(bond: bond, to: bondLength)
          setBondAtomPositions(atom1: asymmetricAtom1, pos1: newPos.0, atom2: asymmetricAtom2, pos2: newPos.1)

        }
      }
    }
  }
  
  // MARK: Context Menu
  // =====================================================================
  
  func menuNeedsUpdate(_ menu: NSMenu)
  {
    self.bondTableView?.window?.makeFirstResponder(self.bondTableView)
  }
  
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
  {
    if (menuItem.action == #selector(RecomputeBonds))
    {
      if let projectTreeNode = proxyProject, projectTreeNode.isEditable
      {
        return true
      }
    }
    
    return true
  }
  
  // undo for large-changes: completely replace all atoms and bonds by new ones
  func setBondState(oldBonds: SKBondSetController, newBonds: SKBondSetController)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      proxyProject.representedObject.isEdited = true
      document.updateChangeCount(.changeDone)
      
      project.undoManager.setActionName(NSLocalizedString("Recompute bonds", comment: "Recompute bonds"))
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setBondState(oldBonds: newBonds, newBonds: oldBonds)})
      
      structure.bonds = newBonds
      
      self.reloadData()
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.proxyProject?.representedObject.isEdited = true
      document.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func RecomputeBonds(_ sender: NSMenuItem)
  {
    if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let oldBonds: SKBondSetController = structure.bonds
      
      let newBonds: SKBondSetController = SKBondSetController(arrangedObjects: structure.computeBonds())
      
      self.setBondState(oldBonds: oldBonds, newBonds: newBonds)
    }
  }
  
  @IBAction func toggleBondVisiiblity(_ sender: NSButton)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let structure = (self.representedObject as? iRASPAStructure)?.structure,
       let row: Int = self.bondTableView?.row(for: sender)
    {
      let toggledState: Bool = sender.state == NSControl.StateValue.on
      if NSEvent.modifierFlags.contains(NSEvent.ModifierFlags.option)
      {
        structure.bonds.arrangedObjects.forEach{$0.isVisible = toggledState}
      }
      else
      {
        if row < structure.bonds.arrangedObjects.count
        {
          let asymmetricBond: SKAsymmetricBond = bondKeys[row]
          
          for bond in structure.bonds.arrangedObjects
          {
            if SKAsymmetricBond(bond.atom1.asymmetricParentAtom, bond.atom2.asymmetricParentAtom) == asymmetricBond
            {
              bond.isVisible = toggledState
            }
          }
        }
      }
      self.bondTableView?.reloadData(forRowIndexes: IndexSet(0..<bondKeys.count), columnIndexes: IndexSet(integer: 0))
        
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
    }
  }
  
  // MARK: Selection
  // =====================================================================
  
  func programmaticallySetSelection()
  {
    if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let selectedAsymmetricBonds: Set<SKAsymmetricBond> = Set(structure.bonds.selectedObjects.compactMap{SKAsymmetricBond($0.atom1.asymmetricParentAtom, $0.atom2.asymmetricParentAtom)})
      
      self.bondTableView?.selectRowIndexes(IndexSet(), byExtendingSelection: false)
      
      var indexSet: IndexSet = IndexSet()
      for (row, asymmetricBond) in bondKeys.enumerated()
      {
        if selectedAsymmetricBonds.contains(asymmetricBond)
        {
          indexSet.insert(row)
        }
      }
      self.bondTableView?.selectRowIndexes(indexSet, byExtendingSelection: true)
    }
  }
  
  func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet
  {
    return proposedSelectionIndexes
  }
  
  func tableViewSelectionDidChange(_ notification: Notification)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let structure = (self.representedObject as? iRASPAStructure)?.structure,
       let indexes: IndexSet = self.bondTableView?.selectedRowIndexes
    {
      structure.bonds.selectedObjects = []
      
      for row in indexes
      {
        let asymmetricBond: SKAsymmetricBond = bondKeys[row]
        
        if let bonds = bondDictionary[asymmetricBond]
        {
          structure.bonds.selectedObjects.formUnion(bonds)
        }
      }
    }
  }
}
