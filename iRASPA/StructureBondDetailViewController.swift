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
  var observeNotifications: Bool = true
  
  weak var windowController: iRASPAWindowController?
  
  // MARK: protocol ProjectConsumer
  // =====================================================================
  
  weak var proxyProject: ProjectTreeNode?
    
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
    self.bondTableView?.reloadData()
    self.programmaticallySetSelection()
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int
  {
    if let structure =  (self.representedObject as? iRASPAStructure)?.structure
    {
      return structure.bondController.arrangedObjects.count
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
      let asymmetricBond: SKAsymmetricBond = structure.bondController.arrangedObjects[row]
      
      guard let bond: SKBondNode = asymmetricBond.copies.first else {return nil}
      let bondLength = structure.bondLength(bond)
      
      switch(tableColumn.identifier)
      {
      case NSUserInterfaceItemIdentifier(rawValue: "bondVisibilityColumn"):
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "bondVisibility"), owner: self) as? NSTableCellView
        if let checkBox: NSButton = view?.viewWithTag(10) as? NSButton
        {
          let isVisible: Bool = asymmetricBond.isVisible && asymmetricBond.atom1.isVisible && asymmetricBond.atom2.isVisible
          checkBox.state = isVisible ? NSControl.StateValue.on : NSControl.StateValue.off
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
          segmentedControl.label = NSString(string: String(asymmetricBond.atom1.tag))
          segmentedControl.setSelected(asymmetricBond.atom1.isFixed.x, forSegment: 0)
          segmentedControl.setSelected(asymmetricBond.atom1.isFixed.y, forSegment: 1)
          segmentedControl.setSelected(asymmetricBond.atom1.isFixed.z, forSegment: 2)
          segmentedControl.isEnabled = proxyProject.isEnabled
        }
        
        if let segmentedControl: NSLabelSegmentedControl = view!.viewWithTag(12) as? NSLabelSegmentedControl
        {
          segmentedControl.label = NSString(string: String(asymmetricBond.atom2.tag))
          segmentedControl.setSelected(asymmetricBond.atom2.isFixed.x, forSegment: 0)
          segmentedControl.setSelected(asymmetricBond.atom2.isFixed.y, forSegment: 1)
          segmentedControl.setSelected(asymmetricBond.atom2.isFixed.z, forSegment: 2)
          segmentedControl.isEnabled = proxyProject.isEnabled
        }
      case  NSUserInterfaceItemIdentifier(rawValue: "bondTypeColumn"):
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "bondTypeRow"), owner: self) as? NSTableCellView
        let popUp: NSPopUpButton = view!.viewWithTag(13) as! NSPopUpButton
        popUp.selectItem(at: asymmetricBond.bondType.rawValue)
        popUp.isEnabled = proxyProject.isEnabled
      case NSUserInterfaceItemIdentifier(rawValue: "bondFirstAtomColumn"):
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "bondFirstAtomRow"), owner: self) as? NSTableCellView
        let element: SKElement = PredefinedElements.sharedInstance.elementSet[asymmetricBond.atom1.elementIdentifier]
        view?.textField?.stringValue = element.chemicalSymbol
        view?.textField?.isEditable = false
      case NSUserInterfaceItemIdentifier(rawValue: "bondSecondAtomColumn"):
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "bondSecondAtomRow"), owner: self) as? NSTableCellView
        let element: SKElement = PredefinedElements.sharedInstance.elementSet[asymmetricBond.atom2.elementIdentifier]
        view?.textField?.stringValue = element.chemicalSymbol
        view?.textField?.isEditable = false
      case NSUserInterfaceItemIdentifier(rawValue: "bondLengthColumn"):
        let allFixed: Bool = asymmetricBond.atom1.isFixed.x && asymmetricBond.atom1.isFixed.y && asymmetricBond.atom1.isFixed.z &&                          asymmetricBond.atom2.isFixed.x && asymmetricBond.atom2.isFixed.y && asymmetricBond.atom2.isFixed.z
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "bondLengthRow"), owner: self) as? NSTableCellView
        view?.textField?.doubleValue = bondLength
        view?.textField?.isEditable = proxyProject.isEnabled && !allFixed
      case NSUserInterfaceItemIdentifier(rawValue: "bondLengthSliderColumn"):
        let allFixed: Bool = asymmetricBond.atom1.isFixed.x && asymmetricBond.atom1.isFixed.y && asymmetricBond.atom1.isFixed.z &&                          asymmetricBond.atom2.isFixed.x && asymmetricBond.atom2.isFixed.y && asymmetricBond.atom2.isFixed.z
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "bondLengthSliderRow"), owner: self) as? NSTableCellView
        let slider: NSSlider = view!.viewWithTag(11) as! NSSlider
        slider.doubleValue = bondLength
        slider.isEnabled = proxyProject.isEnabled && !allFixed
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
       let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure,
       let row: Int = self.bondTableView?.row(for: sender.superview!), row >= 0
    {
      self.bondTableView?.window?.makeFirstResponder(self.bondTableView)
      
      let asymmetricAtom: SKAsymmetricAtom = structure.bondController.arrangedObjects[row].atom1
      
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
       let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure,
       let row: Int = self.bondTableView?.row(for: sender.superview!), row >= 0
    {
      self.bondTableView?.window?.makeFirstResponder(bondTableView)
      let asymmetricAtom: SKAsymmetricAtom = structure.bondController.arrangedObjects[row].atom2
      
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
  
  
  @IBAction func changedBondType(_ sender: NSPopUpButton)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure,
       let row: Int = self.bondTableView?.row(for: sender.superview!), row >= 0
    {
      self.windowController?.window?.makeFirstResponder(self.bondTableView)
      
      structure.bondController.arrangedObjects[row].bondType = SKAsymmetricBond .SKBondType(rawValue: sender.indexOfSelectedItem)!
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
    }
  }
  
  func updatePositions(structure: Structure, atoms: [SKAsymmetricAtom], newpositions: [SIMD3<Double>], oldpositions: [SIMD3<Double>], newbonds: [SKBondNode], newBondSelection: IndexSet, oldbonds: [SKBondNode], oldBondSelection: IndexSet)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
      let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.undoManager.registerUndo(withTarget: self, handler: {
        $0.updatePositions(structure: structure, atoms: atoms, newpositions: oldpositions, oldpositions: newpositions, newbonds: oldbonds, newBondSelection: oldBondSelection, oldbonds: newbonds, oldBondSelection: newBondSelection)
      })
      project.undoManager.setActionName(NSLocalizedString("Change bondlength", comment: "Change bondlength"))
      
      for i in 0..<atoms.count
      {
        atoms[i].position = newpositions[i]
        atoms[i].displacement =  SIMD3<Double>(0.0,0.0,0.0)
        structure.expandSymmetry(asymmetricAtom: atoms[i])
      }
      structure.atomTreeController.tag()
      
      structure.bondController.replaceBonds(atoms: atoms, bonds: newbonds)
      structure.bondController.selectedObjects = newBondSelection
      
      structure.reComputeBoundingBox()
      
      self.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      project.isEdited = true
      document.updateChangeCount(.changeDone)
    }
  }

  func setBondAtomPositions(atom1: SKAsymmetricAtom, pos1: SIMD3<Double>, atom2: SKAsymmetricAtom, pos2: SIMD3<Double>)
  {
    if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let oldPos1: SIMD3<Double> = atom1.position
      let oldPos2: SIMD3<Double> = atom2.position
      
      let oldBondSelection: IndexSet = structure.bondController.selectedObjects
      let oldbonds: [SKBondNode] = structure.bonds(subset: [atom1,atom2])
      
    
      atom1.position = pos1
      atom2.position = pos2
      
      structure.expandSymmetry(asymmetricAtom: atom1)
      structure.expandSymmetry(asymmetricAtom: atom2)
            
      
      let newbonds: [SKBondNode] = structure.bonds(subset: [atom1,atom2])
      
      let newBondSelection: IndexSet = structure.bondController.selectedAsymmetricBonds(atoms: [atom1,atom2], bonds: newbonds)
      
      self.updatePositions(structure: structure, atoms: [atom1,atom2], newpositions: [pos1,pos2], oldpositions: [oldPos1, oldPos2], newbonds: newbonds, newBondSelection: newBondSelection, oldbonds: oldbonds, oldBondSelection: oldBondSelection)
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
      let asymmetricBond: SKAsymmetricBond = structure.bondController.arrangedObjects[row]
      if let bond: SKBondNode = asymmetricBond.copies.first
      {
        let asymmetricAtom1: SKAsymmetricAtom = bond.atom1.asymmetricParentAtom
        let asymmetricAtom2: SKAsymmetricAtom = bond.atom2.asymmetricParentAtom
      
        let bondLength: Double = number.doubleValue
      
        let newPos: (SIMD3<Double>, SIMD3<Double>) = structure.computeChangedBondLength(bond: bond, to: bondLength)
        setBondAtomPositions(atom1: asymmetricAtom1, pos1: newPos.0, atom2: asymmetricAtom2, pos2: newPos.1)
      
      
        if let view: NSTableCellView = self.bondTableView?.view(atColumn: 0, row: row, makeIfNecessary: false) as?  NSTableCellView,
           let sliderValue: NSSlider = view.viewWithTag(11) as? NSSlider
        {
          sliderValue.doubleValue = sender.doubleValue
        }
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
          let asymmetricBond: SKAsymmetricBond = structure.bondController.arrangedObjects[row]
          if let bond: SKBondNode = asymmetricBond.copies.first
          {
            let asymmetricAtom1: SKAsymmetricAtom = bond.atom1.asymmetricParentAtom
            let asymmetricAtom2: SKAsymmetricAtom = bond.atom2.asymmetricParentAtom
          
            let bondLength: Double = sender.doubleValue
          
            let newPos: (SIMD3<Double>, SIMD3<Double>) = structure.computeChangedBondLength(bond: bond, to: bondLength)
            setBondAtomPositions(atom1: asymmetricAtom1, pos1: newPos.0, atom2: asymmetricAtom2, pos2: newPos.1)
          }
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
    if let proxyProject: ProjectTreeNode = self.proxyProject, !proxyProject.isEnabled
    {
      return false
    }
    
    if (menuItem.action == #selector(RecomputeBonds(_:)))
    {
      return true
    }
    
    if (menuItem.action == #selector(TypeBonds(_:)))
    {
      return true
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
      
      structure.bondController = newBonds
      
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
      let oldBonds: SKBondSetController = structure.bondController
      
      let newBonds: SKBondSetController = SKBondSetController(arrangedObjects: structure.computeBonds())
      
      self.setBondState(oldBonds: oldBonds, newBonds: newBonds)
    }
  }
  
  @IBAction func TypeBonds(_ sender: NSMenuItem)
  {
  }
  
  @IBAction func toggleBondVisiblity(_ sender: NSButton)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let structure = (self.representedObject as? iRASPAStructure)?.structure,
       let row: Int = self.bondTableView?.row(for: sender)
    {
      let toggledState: Bool = sender.state == NSControl.StateValue.on
      if NSEvent.modifierFlags.contains(NSEvent.ModifierFlags.option)
      {
        for i in 0..<structure.bondController.arrangedObjects.count
        {
          structure.bondController.arrangedObjects[i].isVisible = toggledState
        }
      }
      else
      {
        if row < structure.bondController.arrangedObjects.count
        {
          structure.bondController.arrangedObjects[row].isVisible = toggledState
        }
      }
      self.bondTableView?.reloadData(forRowIndexes: IndexSet(0..<self.bondTableView!.numberOfRows), columnIndexes: IndexSet(integer: 0))
        
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
    }
  }
  
  // MARK: Delete selection
  // =====================================================================
  
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
  
  func deleteSelection()
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      let indexSet: IndexSet = structure.bondController.selectedObjects
      let selectedBonds: [SKAsymmetricBond] = structure.bondController.arrangedObjects[indexSet]
      
      deleteSelectedBondsFor(structure: structure, bonds: selectedBonds, from: indexSet)
    }
  }
  
  func deleteSelectedBondsFor(structure: Structure, bonds: [SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>], from indexSet: IndexSet)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.undoManager.registerUndo(withTarget: self, handler: {$0.insertSelectedBondsIn(structure: structure, bonds: bonds, at: indexSet)})
      
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Delete bonds", comment:"Delete bonds"))
      }
      
      let observeNotificationsStored: Bool = self.observeNotifications
      self.observeNotifications = false
      self.bondTableView?.beginUpdates()
      
      structure.bondController.arrangedObjects.remove(at: indexSet)
      structure.bondController.selectedObjects = []
      
      if let bondTableView = bondTableView, bondTableView.numberOfRows>0
      {
        bondTableView.removeRows(at: indexSet, withAnimation: .slideLeft)
      }
    
      self.bondTableView?.endUpdates()
      self.observeNotifications = observeNotificationsStored
    
      project.isEdited = true
      self.windowController?.currentDocument?.updateChangeCount(.changeDone)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
    }
  }
  
  func insertSelectedBondsIn(structure: Structure, bonds: [SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>], at indexSet: IndexSet)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.undoManager.registerUndo(withTarget: self, handler: {$0.deleteSelectedBondsFor(structure: structure, bonds: bonds, from: indexSet)})
      
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Insert bonds", comment:"Insert bonds"))
      }
      let observeNotificationsStored: Bool = self.observeNotifications
      self.observeNotifications = false
      self.bondTableView?.beginUpdates()
      
      structure.bondController.arrangedObjects.insertItems(bonds, atIndexes: indexSet)
      structure.bondController.selectedObjects.formUnion(indexSet)
      
      if let bondTableView = bondTableView, bondTableView.numberOfRows>0
      {
        bondTableView.insertRows(at: indexSet, withAnimation: .slideLeft)
        bondTableView.selectRowIndexes(indexSet, byExtendingSelection: true)
      }
      
      self.bondTableView?.endUpdates()
      self.observeNotifications = observeNotificationsStored
      
      project.isEdited = true
      self.windowController?.currentDocument?.updateChangeCount(.changeDone)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
    }
  }

  // MARK: Selection
  // =====================================================================
  
  func programmaticallySetSelection()
  {
    if let structure: Structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      // avoid sending notification due to selection change
      let observeNotificationsStored: Bool = self.observeNotifications
      self.observeNotifications = false
      
      let indexSet: IndexSet = structure.bondController.selectedObjects
      self.bondTableView?.selectRowIndexes(indexSet, byExtendingSelection: false)
      
      self.observeNotifications = observeNotificationsStored
    }
  }
  
  func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet
  {
    var selectedBonds: IndexSet = proposedSelectionIndexes
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let structure = (self.representedObject as? iRASPAStructure)?.structure
    {
      // add the bonds due the atom selection
      let asymmetricAtoms: Set<SKAsymmetricAtom> = Set(structure.atomTreeController.selectedTreeNodes.map{$0.representedObject})
    
      // add also all the bonds that are connected to a selected atom
      for (index, bond) in structure.bondController.arrangedObjects.enumerated()
      {
        if(asymmetricAtoms.contains(bond.atom1) ||
           asymmetricAtoms.contains(bond.atom2))
        {
          selectedBonds.insert(index)
        }
      }
    }
    return selectedBonds
  }
  
  func setCurrentSelection(structure: Structure, atomSelection: Set<SKAtomTreeNode>, previousAtomSelection: Set<SKAtomTreeNode>, bondSelection: IndexSet, previousBondSelection: IndexSet)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.undoManager.setActionName(NSLocalizedString("Change bond selection", comment: "Change bond selection"))
      
      // save off the current selectedNode and current selection for undo/redo
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setCurrentSelection(structure: structure, atomSelection: previousAtomSelection, previousAtomSelection: atomSelection, bondSelection: previousBondSelection, previousBondSelection: bondSelection)})
    
      structure.atomTreeController.selectedTreeNodes = atomSelection
      structure.bondController.selectedObjects = bondSelection
    
      // reload the selection in the renderer
      self.windowController?.detailTabViewController?.renderViewController?.reloadRenderDataSelectedInternalBonds()
    
      if (project.undoManager.isUndoing || project.undoManager.isRedoing)
      {
        self.reloadData()
      }
    }
  }
  
  func tableViewSelectionDidChange(_ notification: Notification)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let structure = (self.representedObject as? iRASPAStructure)?.structure,
       let selectedBonds: IndexSet = self.bondTableView?.selectedRowIndexes
    {
      if (self.observeNotifications && !(project.undoManager.isUndoing || project.undoManager.isRedoing))
      {
        setCurrentSelection(structure: structure, atomSelection: structure.atomTreeController.selectedTreeNodes, previousAtomSelection: structure.atomTreeController.selectedTreeNodes, bondSelection: selectedBonds, previousBondSelection: structure.bondController.selectedObjects)
      }
    }
  }
}
