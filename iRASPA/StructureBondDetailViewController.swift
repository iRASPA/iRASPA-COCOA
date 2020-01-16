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
  
  deinit
  {
    //Swift.print("deinit: StructureBondDetailViewController")
  }
  
  // MARK: protocol ProjectConsumer
  // ===============================================================================================================================
  
  weak var proxyProject: ProjectTreeNode?
  
  var bonds: [SKBondNode] = []
  
  
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
    if let structure: Structure =  (self.representedObject as? iRASPAStructure)?.structure
    {
      var asymmetricBonds: Dictionary<SKAsymmetricBond<SKAsymmetricAtom,SKAsymmetricAtom>, SKBondNode> = [:]
      for bond in (structure.bonds.arrangedObjects.filter{$0.atom1.type == .copy && $0.atom2.type == .copy})
      {
        asymmetricBonds[SKAsymmetricBond(bond.atom1.asymmetricParentAtom, bond.atom2.asymmetricParentAtom)] = bond
      }
            
      bonds = Array(asymmetricBonds.values).sorted{
        if $0.atom1.asymmetricParentAtom.elementIdentifier == $1.atom1.asymmetricParentAtom.elementIdentifier
        {
          if $0.atom2.asymmetricParentAtom.elementIdentifier == $1.atom2.asymmetricParentAtom.elementIdentifier
          {
            if $0.atom1.asymmetricParentAtom.tag == $1.atom1.asymmetricParentAtom.tag
            {
              return $0.atom2.asymmetricParentAtom.tag < $1.atom2.asymmetricParentAtom.tag
            }
            else
            {
              return $0.atom1.asymmetricParentAtom.tag < $1.atom1.asymmetricParentAtom.tag
            }
          }
          else
          {
            return $0.atom2.asymmetricParentAtom.elementIdentifier > $1.atom2.asymmetricParentAtom.elementIdentifier
          }
        }
        else
        {
          return $0.atom1.asymmetricParentAtom.elementIdentifier > $1.atom1.asymmetricParentAtom.elementIdentifier
        }
      }
    }
    
    self.bondTableView?.reloadData()
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int
  {
    if let _ =  (self.representedObject as? iRASPAStructure)?.structure
    {
      return bonds.count
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
      let bond: SKBondNode = bonds[row]
      let bondLength = structure.bondLength(bond)
      switch(tableColumn.identifier)
      {
      case NSUserInterfaceItemIdentifier(rawValue: "bondIdColumn"):
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "bondIdRow"), owner: self) as? NSTableCellView
        view?.textField?.intValue = Int32(row)
        view?.textField?.isEditable = false
      case NSUserInterfaceItemIdentifier(rawValue: "bondFixedAtomColumn"):
        view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "fixedAtomsInBondRow"), owner: self) as? NSTableCellView
        let segmentedControl: NSSegmentedControl = view!.viewWithTag(11) as! NSSegmentedControl
        segmentedControl.setLabel(String(bond.atom1.asymmetricParentAtom.tag), forSegment: 0)
        //segmentedControl.setEnabled(true, forSegment: 0)
        let isAllFixed1: Bool = bond.atom1.asymmetricParentAtom.isFixed.x &&
                                bond.atom1.asymmetricParentAtom.isFixed.y &&
                                bond.atom1.asymmetricParentAtom.isFixed.z
        segmentedControl.setSelected(isAllFixed1, forSegment: 0)
        segmentedControl.setLabel(String(bond.atom2.asymmetricParentAtom.tag), forSegment: 1)
        //segmentedControl.setEnabled(true, forSegment: 1)
        let isAllFixed2: Bool = bond.atom2.asymmetricParentAtom.isFixed.x &&
                                bond.atom2.asymmetricParentAtom.isFixed.y &&
                                bond.atom2.asymmetricParentAtom.isFixed.z
        segmentedControl.setSelected(isAllFixed2, forSegment: 1)
        segmentedControl.isEnabled = proxyProject.isEnabled
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
  // ===============================================================================================================================
  
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
      self.bondTableView?.reloadData()
    }
  }
  
  @IBAction func fixAtom(_ sender: NSSegmentedControl)
  {
    if let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let row: Int = self.bondTableView?.row(for: sender.superview!), row >= 0
    {
      self.bondTableView?.window?.makeFirstResponder(bondTableView)
      
      if (sender.selectedSegment == 0)
      {
        let asymmetricAtom: SKAsymmetricAtom = bonds[row].atom1.asymmetricParentAtom
        
        let isFixed: Bool = sender.isSelected(forSegment: 0)
        self.fixAsymmetricAtom(asymmetricAtom, to: Bool3(isFixed,isFixed,isFixed))
      }
      if (sender.selectedSegment == 1)
      {
        let asymmetricAtom: SKAsymmetricAtom = bonds[row].atom2.asymmetricParentAtom
        
        let isFixed: Bool = sender.isSelected(forSegment: 1)
        self.fixAsymmetricAtom(asymmetricAtom, to: Bool3(isFixed,isFixed,isFixed))
      }
    }
  }
  
  

  func setBondAtomPositions(atom1: SKAsymmetricAtom, pos1: SIMD3<Double>, atom2: SKAsymmetricAtom, pos2: SIMD3<Double>)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
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
      
      structure.reComputeBonds()
      
      self.reloadData()
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.proxyProject?.representedObject.isEdited = true
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
      let bond: SKBondNode = bonds[row]
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
          let bond: SKBondNode = bonds[row]
          let asymmetricAtom1: SKAsymmetricAtom = bond.atom1.asymmetricParentAtom
          let asymmetricAtom2: SKAsymmetricAtom = bond.atom2.asymmetricParentAtom
          
          let bondLength: Double = sender.doubleValue
          
          let newPos: (SIMD3<Double>, SIMD3<Double>) = structure.computeChangedBondLength(bond: bond, to: bondLength)
          setBondAtomPositions(atom1: asymmetricAtom1, pos1: newPos.0, atom2: asymmetricAtom2, pos2: newPos.1)

        }
      }
    }
  }
  
  // MARK: Context Menu
  // ===============================================================================================================================
  
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
}
