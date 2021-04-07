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
import SymmetryKit
import SimulationKit
import RenderKit
import iRASPAKit
import MathKit

class StructureElementDetailViewController: NSViewController, NSMenuItemValidation,WindowControllerConsumer, ProjectConsumer, NSTableViewDataSource, NSTableViewDelegate
{
  weak var windowController: iRASPAWindowController?
  
  @IBOutlet private weak var forceFieldTableView: NSTableView?
  @IBOutlet private weak var forceFieldSetComboBox: NSComboBox?
  @IBOutlet private weak var colorSetComboBox: NSComboBox?
  
  @IBOutlet private var elementContextMenu: NSMenu?
  
  var selectedColorSetIndex: Int = 0
  var selectedForceFieldSetIndex: Int = 0
  
  
  // MARK: protocol ProjectConsumer
  // =====================================================================
  
  weak var proxyProject: ProjectTreeNode?
  {
    didSet
    {
      if let project: ProjectStructureNode = proxyProject?.representedObject.loadedProjectStructureNode
      {
        self.representedObject = project
        self.reloadData()
      }
      else
      {
        self.representedObject = nil
      }
    }
  }
  
  // ViewDidLoad: bounds are not yet set (do not do geometry-related etup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
  }
  
  override func viewWillAppear()
  {
    self.forceFieldTableView?.needsLayout = true
    super.viewWillAppear()
    
    self.reloadData()
  }
  
  // the windowController still exists when the view is there
  override func viewWillDisappear()
  {
    super.viewWillDisappear()
  }
  
  
  func reloadData()
  {
    self.forceFieldTableView?.reloadData()
    
    if let forceFieldSetComboBox: NSComboBox = forceFieldSetComboBox
    {
      forceFieldSetComboBox.isEditable = true
      
      forceFieldSetComboBox.removeAllItems()
      if let document = self.windowController?.document as? iRASPADocument
      {
        let forceFieldSets: SKForceFieldSets = document.forceFieldSets
        for i in 0..<forceFieldSets.count
        {
          forceFieldSetComboBox.addItem(withObjectValue: forceFieldSets[i].displayName)
        }
        forceFieldSetComboBox.selectItem(at: selectedForceFieldSetIndex)
      }
    }
    
    if let colorSetComboBox: NSComboBox = colorSetComboBox
    {
      colorSetComboBox.isEditable = true
      
      colorSetComboBox.removeAllItems()
      if let document = self.windowController?.document as? iRASPADocument
      {
        let colorSets: SKColorSets = document.colorSets
        for i in 0..<colorSets.count
        {
          colorSetComboBox.addItem(withObjectValue: colorSets[i].displayName)
        }
        colorSetComboBox.selectItem(at: selectedColorSetIndex)
      }
    }
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int
  {
    if let document = self.windowController?.document as? iRASPADocument
    {
      let forceFieldData: SKForceFieldSet = document.forceFieldSets[selectedForceFieldSetIndex]
      return forceFieldData.atomTypeList.count
    }
    return 0
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
  {
    var view: NSTableCellView? = nil
    
    if let document = self.windowController?.document as? iRASPADocument
    {
      let forceFieldData: SKForceFieldSet = document.forceFieldSets[selectedForceFieldSetIndex]
      let uniqueForceFieldName = forceFieldData.atomTypeList[row].forceFieldStringIdentifier
      let atomicNumber: Int = forceFieldData.atomTypeList[row].atomicNumber
      let element: SKElement = PredefinedElements.sharedInstance.elementSet[atomicNumber]
      
      //let sortIndex: Int = forceFieldData.sortedAtomTypes[row].value.sortIndex
      let potentialParameters: SIMD2<Double> = forceFieldData.atomTypeList[row].potentialParameters
      
      view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "elementView"), owner: self) as? NSTableCellView
      
      let editable: Bool = forceFieldData.editable
      
      if let visibilityCheckBox: NSButton = view?.viewWithTag(50) as? NSButton
      {
        visibilityCheckBox.isEnabled = editable
        let isVisible: Bool = document.forceFieldSets[selectedForceFieldSetIndex][uniqueForceFieldName]?.isVisible ?? true
        visibilityCheckBox.state = isVisible ? NSControl.StateValue.on : NSControl.StateValue.off
      }
      
      if let sortIndexView: NSTextField = view?.viewWithTag(1) as? NSTextField
      {
        sortIndexView.integerValue = row
        sortIndexView.isEditable = false
      }
      if let uniqueForceFieldNameView: NSTextField = view?.viewWithTag(2) as? NSTextField
      {
        uniqueForceFieldNameView.stringValue = uniqueForceFieldName
        uniqueForceFieldNameView.isEditable = editable && !SKForceFieldSet.isDefaultForceFieldType(uniqueForceFieldName: uniqueForceFieldName)
      }
      if let atomElementNameView: NSTextField = view?.viewWithTag(3) as? NSTextField
      {
        if let bundle = Bundle(identifier: "nl.darkwing.SymmetryKit")
        {
          atomElementNameView.stringValue = NSLocalizedString(element.name, bundle: bundle, comment: element.name)
        }
        else
        {
          atomElementNameView.stringValue = element.name
        }
        atomElementNameView.isEditable = false
      }
      
      if let atomColorView: NSColorWell = view?.viewWithTag(4) as? NSColorWell
      {
        atomColorView.color = document.colorSets[selectedColorSetIndex][uniqueForceFieldName] ?? NSColor.black
        atomColorView.isEnabled = document.colorSets[selectedColorSetIndex].editable
      }
      
      if let atomAtomicNumberView: NSTextField = view?.viewWithTag(10) as? NSTextField
      {
        atomAtomicNumberView.intValue = Int32(element.atomicNumber)
        atomAtomicNumberView.isEditable = editable && !SKForceFieldSet.isDefaultForceFieldType(uniqueForceFieldName: uniqueForceFieldName)
      }
      if let atomElementView: NSTextField = view?.viewWithTag(11) as? NSTextField
      {
        atomElementView.stringValue = element.chemicalSymbol
        atomElementView.isEditable = editable && !SKForceFieldSet.isDefaultForceFieldType(uniqueForceFieldName: uniqueForceFieldName)
      }
      if let atomGroupView: NSTextField = view?.viewWithTag(12) as? NSTextField
      {
        atomGroupView.intValue = Int32(element.group)
        atomGroupView.isEditable = false
      }
      if let atomPeriodView: NSTextField = view?.viewWithTag(13) as? NSTextField
      {
        atomPeriodView.intValue = Int32(element.period)
        atomPeriodView.isEditable = false
      }
      
      if let possibleOxidationStatesView: NSTextField = view?.viewWithTag(15) as? NSTextField
      {
        possibleOxidationStatesView.stringValue =  element.possibleOxidationStates.map{String($0)}.joined(separator: ",")
        possibleOxidationStatesView.isEditable = false
      }
      
      if let atomMassView: NSTextField = view?.viewWithTag(20) as? NSTextField
      {
        atomMassView.doubleValue = document.forceFieldSets[selectedForceFieldSetIndex][uniqueForceFieldName]?.mass ?? 0.0
        atomMassView.isEditable = editable && !SKForceFieldSet.isDefaultForceFieldType(uniqueForceFieldName: uniqueForceFieldName)
      }
      if let atomicRadiusView: NSTextField = view?.viewWithTag(21) as? NSTextField
      {
        atomicRadiusView.doubleValue = element.atomRadius
        atomicRadiusView.isEditable = false
      }
      if let covalentRadiusView: NSTextField = view?.viewWithTag(22) as? NSTextField
      {
        covalentRadiusView.doubleValue = element.covalentRadius
        covalentRadiusView.isEditable = false
      }
      if let vDWRadiusView: NSTextField = view?.viewWithTag(23) as? NSTextField
      {
        vDWRadiusView.doubleValue = element.VDWRadius
        vDWRadiusView.isEditable = false
      }
      if let tripleBondCovalentRadiusView: NSTextField = view?.viewWithTag(24) as? NSTextField
      {
        tripleBondCovalentRadiusView.doubleValue = element.tripleBondCovalentRadius
        tripleBondCovalentRadiusView.isEditable = false
      }
      if let userDefinedRadiusView: NSTextField = view?.viewWithTag(25) as? NSTextField
      {
        userDefinedRadiusView.doubleValue = document.forceFieldSets[selectedForceFieldSetIndex][uniqueForceFieldName]?.userDefinedRadius ?? 0.0
        userDefinedRadiusView.isEditable = editable
      }
     
      if let potentialParametersEpsilonView: NSTextField = view?.viewWithTag(30) as? NSTextField
      {
        potentialParametersEpsilonView.doubleValue = potentialParameters.x
        potentialParametersEpsilonView.isEditable = editable
      }
      if let potentialParametersSigmaView: NSTextField = view?.viewWithTag(31) as? NSTextField
      {
        potentialParametersSigmaView.doubleValue = potentialParameters.y
        potentialParametersSigmaView.isEditable = editable
      }
    }
    return view
  }
  
  func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
  {
    return 230.0
  }
  
  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView?
  {
    if let rowView: ElementsTableRowView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "elementsTableRowView"), owner: self) as? ElementsTableRowView
    {
      return rowView
    }
    return nil
  }
  
  
  // MARK: Menu and validation
  // =====================================================================
  
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
  {
    if (menuItem.action == #selector(addForceFieldTypeContextMenu(_:)))
    {
      if let document: iRASPADocument = self.windowController?.currentDocument,
         document.forceFieldSets[selectedForceFieldSetIndex].editable,
         let forceFieldTableView = self.forceFieldTableView, forceFieldTableView.clickedRow >= 0
      {
        return true
      }
    }
    if (menuItem.action == #selector(removeForceFieldTypeContextMenu(_:)))
    {
      if let document: iRASPADocument = self.windowController?.currentDocument,
         document.forceFieldSets[selectedForceFieldSetIndex].editable,
         let forceFieldTableView = self.forceFieldTableView, forceFieldTableView.clickedRow >= 0
      {
        let forceFieldData: SKForceFieldSet = document.forceFieldSets[selectedForceFieldSetIndex]
        let uniqueForceFieldName = forceFieldData.atomTypeList[forceFieldTableView.clickedRow].forceFieldStringIdentifier
        
        if !SKForceFieldSet.isDefaultForceFieldType(uniqueForceFieldName: uniqueForceFieldName)
        {
          return true
        }
      }
    }
    return false
  }
  
  @IBAction func addForceFieldTypeContextMenu(_ sender: NSMenuItem)
  {
    let clickedRow: Int = self.forceFieldTableView?.clickedRow ?? -1
    
    if let document: iRASPADocument = self.windowController?.currentDocument,
       document.forceFieldSets[selectedForceFieldSetIndex].editable,
       let forceFieldTableView = self.forceFieldTableView, clickedRow >= 0
    {
      forceFieldTableView.beginUpdates()
      let forceFieldSets: SKForceFieldSets = document.forceFieldSets
      let forceFieldData: SKForceFieldSet = forceFieldSets[selectedForceFieldSetIndex]
      var forceFieldType: SKForceFieldType = forceFieldData.atomTypeList[clickedRow]
      let elementId: Int = forceFieldData.atomTypeList[clickedRow].atomicNumber
      let newUniqueForceFieldName = forceFieldData.uniqueName(for: elementId)
      forceFieldType.forceFieldStringIdentifier = newUniqueForceFieldName
      
      forceFieldData.insert(forceFieldType, at: clickedRow + 1)
      document.colorSets.insert(key: newUniqueForceFieldName, element: forceFieldType.atomicNumber)
      
      forceFieldTableView.insertRows(at: IndexSet(integer: clickedRow + 1), withAnimation: [.slideRight])
      forceFieldTableView.reloadData(forRowIndexes: IndexSet(0..<forceFieldTableView.numberOfRows), columnIndexes: IndexSet(integer: 0))
      forceFieldTableView.endUpdates()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func removeForceFieldTypeContextMenu(_ sender: NSMenuItem)
  {
    let clickedRow: Int = self.forceFieldTableView?.clickedRow ?? -1
    
    if let document: iRASPADocument = self.windowController?.currentDocument,
       document.forceFieldSets[selectedForceFieldSetIndex].editable,
       let forceFieldTableView = self.forceFieldTableView, clickedRow >= 0
    {
      let forceFieldSets: SKForceFieldSets = document.forceFieldSets
      let forceFieldSet: SKForceFieldSet = forceFieldSets[selectedForceFieldSetIndex]
      
      let keys: [String] = [forceFieldSet.atomTypeList[clickedRow].forceFieldStringIdentifier]
      
      forceFieldSet.remove(sortIndices: IndexSet(integer: clickedRow))
      
      for oldUniqueName in keys
      {
        // if none of the forcefields refer to this name, then delete it from colors
        if !document.forceFieldSets.contains(uniqueIdentifier: oldUniqueName)
        {
          document.colorSets.remove(key: oldUniqueName)
        }
      }
      
      
      forceFieldTableView.removeRows(at: IndexSet(integer: clickedRow), withAnimation: .slideLeft)
      forceFieldTableView.reloadData(forRowIndexes: IndexSet(0..<forceFieldTableView.numberOfRows), columnIndexes: IndexSet(integer: 0))
    }
  }
  
  // MARK: Selection
  // =====================================================================
  
  func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet
  {
    if let document = self.windowController?.document as? iRASPADocument
    {
      let forceFieldData: SKForceFieldSet = document.forceFieldSets[selectedForceFieldSetIndex]
      if forceFieldData.editable
      {
        return proposedSelectionIndexes
      }
    }
    
    return []
  }
  
  // MARK: Actions
  // =====================================================================
  
  @IBAction func changeUniqueForceFieldName(_ sender: NSTextField)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       document.forceFieldSets[selectedForceFieldSetIndex].editable,
       let row: Int = self.forceFieldTableView?.row(for: sender.superview!), row >= 0
    {
      let forceFieldData: SKForceFieldSet = document.forceFieldSets[selectedForceFieldSetIndex]
      let forceFieldType: SKForceFieldType = forceFieldData.atomTypeList[row]
      
      let newUniqueName: String = sender.stringValue
      let oldUniqueName: String = forceFieldData.atomTypeList[row].forceFieldStringIdentifier
      
      // make sure the new identifier is unique
      guard !(forceFieldData.atomTypeList.contains(where: {$0.forceFieldStringIdentifier == newUniqueName}) ||
             SKForceFieldSet.isDefaultForceFieldType(uniqueForceFieldName: sender.stringValue) ||
             newUniqueName.isEmpty) else
      {
        sender.stringValue = oldUniqueName
        return
      }
      
      // also add the identifier to the color-sets
      document.colorSets.insert(key: sender.stringValue, element: forceFieldType.atomicNumber)
      
      forceFieldData.atomTypeList[row].forceFieldStringIdentifier = newUniqueName
      
      // if none of the forcefields refer to this name, then delete it from colors
      if !document.forceFieldSets.contains(uniqueIdentifier: oldUniqueName)
      {
        document.colorSets.remove(key: oldUniqueName)
      }
    }
  }
  
  @IBAction func changeElementAtomicNumber(_ sender: NSTextField)
  {
    
    
    if let document: iRASPADocument = self.windowController?.currentDocument,
       document.forceFieldSets[selectedForceFieldSetIndex].editable,
       let row: Int = self.forceFieldTableView?.row(for: sender.superview!), row >= 0
    {
      let forceFieldData: SKForceFieldSet = document.forceFieldSets[selectedForceFieldSetIndex]
      let uniqueForceFieldName = forceFieldData.atomTypeList[row].forceFieldStringIdentifier
      
      let highestAtomicNumber: Int = PredefinedElements.sharedInstance.elementSet.last?.atomicNumber ?? 118
      guard sender.integerValue <= highestAtomicNumber else
      {
        sender.integerValue = forceFieldData.atomTypeList[row].atomicNumber
        return
      }
      
      if !SKForceFieldSet.isDefaultForceFieldType(uniqueForceFieldName: uniqueForceFieldName)
      {
        forceFieldData.atomTypeList[row].atomicNumber = sender.integerValue
      }
      self.reloadData()
    }
  }
  
  @IBAction func changeElement(_ sender: NSTextField)
  {
    let chemicalElement: String = sender.stringValue
    
    if let document: iRASPADocument = self.windowController?.currentDocument,
       document.forceFieldSets[selectedForceFieldSetIndex].editable,
       let project: ProjectStructureNode = representedObject as? ProjectStructureNode,
       let row: Int = self.forceFieldTableView?.row(for: sender.superview!), row >= 0
    {
      let forceFieldData: SKForceFieldSet = document.forceFieldSets[selectedForceFieldSetIndex]
      let uniqueForceFieldName = forceFieldData.atomTypeList[row].forceFieldStringIdentifier
      
      guard let atomicNumber: Int = SKElement.atomData[chemicalElement]?["atomicNumber"] as? Int else
      {
        let oldAtomicNumber: Int  = forceFieldData.atomTypeList[row].atomicNumber
        sender.stringValue = PredefinedElements.sharedInstance.elementSet[oldAtomicNumber].chemicalSymbol
        return
      }
      
      if !SKForceFieldSet.isDefaultForceFieldType(uniqueForceFieldName: uniqueForceFieldName)
      {
        forceFieldData.atomTypeList[row].atomicNumber = atomicNumber
        forceFieldData.atomTypeList[row].forceFieldStringIdentifier = uniqueForceFieldName
        
        project.allStructures.forEach{$0.setRepresentationColorScheme(scheme: $0.atomColorSchemeIdentifier, colorSets: document.colorSets)}
      }
      self.reloadData()
    }
  }
  
  @IBAction func changeElementColor(_ sender: NSColorWell)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       document.colorSets[selectedColorSetIndex].editable,
       let project: ProjectStructureNode = representedObject as? ProjectStructureNode,
       let row: Int = self.forceFieldTableView?.row(for: sender.superview!), row >= 0
    {
      let forceFieldData: SKForceFieldSet = document.forceFieldSets[selectedForceFieldSetIndex]
      let uniqueForceFieldName = forceFieldData.atomTypeList[row].forceFieldStringIdentifier
      
      document.colorSets[selectedColorSetIndex][uniqueForceFieldName] = sender.color
      
      project.allStructures.forEach{$0.setRepresentationColorScheme(scheme: $0.atomColorSchemeIdentifier, colorSets: document.colorSets)}
      self.windowController?.detailTabViewController?.renderViewController?.reloadRenderData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      project.isEdited = true
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  
  
  @IBAction func addForceFieldType(_ sender: AnyObject)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       document.forceFieldSets[selectedForceFieldSetIndex].editable,
       let forceFieldTableView = self.forceFieldTableView, forceFieldTableView.selectedRow >= 0
    {
      forceFieldTableView.beginUpdates()
      let forceFieldSets: SKForceFieldSets = document.forceFieldSets
      let selectedRow: Int = forceFieldTableView.selectedRow
      
      let forceFieldData: SKForceFieldSet = forceFieldSets[selectedForceFieldSetIndex]
      var forceFieldType: SKForceFieldType = forceFieldData.atomTypeList[selectedRow]
      let elementId: Int = forceFieldData.atomTypeList[selectedRow].atomicNumber
      let newUniqueForceFieldName = forceFieldData.uniqueName(for: elementId)
      
      forceFieldType.forceFieldStringIdentifier = newUniqueForceFieldName
      forceFieldData.insert(forceFieldType, at: selectedRow + 1)
      
      document.colorSets.insert(key: newUniqueForceFieldName, element: forceFieldType.atomicNumber)
      
      forceFieldTableView.insertRows(at: IndexSet(integer: selectedRow + 1), withAnimation: [.slideRight])
      forceFieldTableView.reloadData(forRowIndexes: IndexSet(0..<forceFieldTableView.numberOfRows), columnIndexes: IndexSet(integer: 0))
      forceFieldTableView.endUpdates()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func removeSelectedForceFieldTypes(_ sender: AnyObject)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       document.forceFieldSets[selectedForceFieldSetIndex].editable,
       let forceFieldTableView = self.forceFieldTableView, forceFieldTableView.selectedRow >= 0
    {
      let forceFieldSets: SKForceFieldSets = document.forceFieldSets
      let forceFieldSet: SKForceFieldSet = forceFieldSets[selectedForceFieldSetIndex]
      let selectedRows: IndexSet = forceFieldTableView.selectedRowIndexes
      
      // only non-default indexes should be removed
      let removedIndexes = selectedRows.filteredIndexSet { (index) -> Bool in
        let uniqueForceFieldName: String = forceFieldSet.atomTypeList[index].forceFieldStringIdentifier
        return !SKForceFieldSet.isDefaultForceFieldType(uniqueForceFieldName: uniqueForceFieldName)
      }
      
      forceFieldSet.remove(sortIndices: removedIndexes)
      
      let keys: [String] = forceFieldSet.atomTypeList[selectedRows].map{$0.forceFieldStringIdentifier}
      for oldUniqueName in keys
      {
        // if none of the forcefields refer to this name, then delete it from colors
        if !document.forceFieldSets.contains(uniqueIdentifier: oldUniqueName)
        {
          document.colorSets.remove(key: oldUniqueName)
        }
      }
      
      
      forceFieldTableView.removeRows(at: removedIndexes, withAnimation: .slideLeft)
      forceFieldTableView.reloadData(forRowIndexes: IndexSet(0..<forceFieldTableView.numberOfRows), columnIndexes: IndexSet(integer: 0))
    }
  }
  
  @IBAction func changeAtomVisibility(_ sender: NSButton)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       document.forceFieldSets[selectedForceFieldSetIndex].editable,
       let row: Int = self.forceFieldTableView?.row(for: sender.superview!), row >= 0
    {
      let forceFieldSets: SKForceFieldSets = document.forceFieldSets
      let forceFieldSet: SKForceFieldSet = forceFieldSets[selectedForceFieldSetIndex]
      
      forceFieldSet.atomTypeList[row].isVisible = (sender.state == NSControl.StateValue.on)
      self.reloadData()
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      document.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func changeAtomMass(_ sender: NSTextField)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       document.forceFieldSets[selectedForceFieldSetIndex].editable,
       let row: Int = self.forceFieldTableView?.row(for: sender.superview!), row >= 0
    {
      let forceFieldSets: SKForceFieldSets = document.forceFieldSets
      let forceFieldSet: SKForceFieldSet = forceFieldSets[selectedForceFieldSetIndex]
      let uniqueForceFieldName: String = forceFieldSet.atomTypeList[row].forceFieldStringIdentifier
      
      if !SKForceFieldSet.isDefaultForceFieldType(uniqueForceFieldName: uniqueForceFieldName)
      {
        forceFieldSet.atomTypeList[row].mass = sender.doubleValue
      }
      self.reloadData()
      
      document.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func changeUserDefinedRadius(_ sender: NSTextField)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let project: ProjectStructureNode = representedObject as? ProjectStructureNode,
       document.forceFieldSets[selectedForceFieldSetIndex].editable,
       let row: Int = self.forceFieldTableView?.row(for: sender.superview!), row >= 0
    {
      let forceFieldSets: SKForceFieldSets = document.forceFieldSets
      let forceFieldSet: SKForceFieldSet = forceFieldSets[selectedForceFieldSetIndex]
      
      forceFieldSet.atomTypeList[row].userDefinedRadius = sender.doubleValue
     
      
      project.allStructures.forEach{$0.setRepresentationForceField(forceField: $0.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)}
      
      self.reloadData()
      
      document.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func changePotentialParameterEpsilon(_ sender: NSTextField)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       document.forceFieldSets[selectedForceFieldSetIndex].editable,
       let project: ProjectStructureNode = representedObject as? ProjectStructureNode,
       let row: Int = self.forceFieldTableView?.row(for: sender.superview!), row >= 0
    {
      let forceFieldSets: SKForceFieldSets = document.forceFieldSets
      let forceFieldSet: SKForceFieldSet = forceFieldSets[selectedForceFieldSetIndex]
      let value: SKForceFieldType = forceFieldSet.atomTypeList[row]
      forceFieldSet.atomTypeList[row].potentialParameters = SIMD2<Double>(sender.doubleValue,value.potentialParameters.y)
    
      
      project.allStructures.forEach{$0.setRepresentationForceField(forceField: $0.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)}
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: project.allStructures)
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      document.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func changePotentialParameterSigma(_ sender: NSTextField)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       document.forceFieldSets[selectedForceFieldSetIndex].editable,
       let project: ProjectStructureNode = representedObject as? ProjectStructureNode,
       let row: Int = self.forceFieldTableView?.row(for: sender.superview!), row >= 0
    {
      let forceFieldSets: SKForceFieldSets = document.forceFieldSets
      let forceFieldSet: SKForceFieldSet = forceFieldSets[selectedForceFieldSetIndex]
      let value: SKForceFieldType = forceFieldSet.atomTypeList[row]
      forceFieldSet.atomTypeList[row].potentialParameters = SIMD2<Double>(value.potentialParameters.x, sender.doubleValue)
      
      project.allStructures.forEach{$0.setRepresentationForceField(forceField: $0.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)}
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: project.allStructures)
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      document.updateChangeCount(.changeDone)
    }
  }
  
 
  @IBAction func addForceFieldSet(_ sender: NSComboBox)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       !sender.stringValue.isEmpty
    {
      let index: Int = sender.indexOfItem(withObjectValue: sender.stringValue.capitalizeFirst)
      if index == NSNotFound
      {
        let forceFieldSet: SKForceFieldSet = SKForceFieldSet(name: sender.stringValue.capitalizeFirst, forceFieldSet: document.forceFieldSets[selectedForceFieldSetIndex], editable: true)
      
        document.forceFieldSets.append(forceFieldSet)
        self.selectedForceFieldSetIndex = document.forceFieldSets.count - 1
      
        document.updateChangeCount(.changeDone)
        
        sender.reloadData()
      }
      else
      {
        self.selectedForceFieldSetIndex = index
      }
    }
    self.reloadData()
    self.windowController?.window?.makeFirstResponder(self.forceFieldTableView)
  }
  
  // select color set or add new one if not found
  @IBAction func addColorSet(_ sender: NSComboBox)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       !sender.stringValue.isEmpty
    {
      let index: Int = sender.indexOfItem(withObjectValue: sender.stringValue.capitalizeFirst)
      if index == NSNotFound
      {
        let colorSets: SKColorSets = document.colorSets
        
        let colorSet: SKColorSet = SKColorSet(name: sender.stringValue.capitalizeFirst, from: colorSets[selectedColorSetIndex], editable: true)
        
        colorSets.append(colorSet)
        self.selectedColorSetIndex = colorSets.count - 1
        
        document.updateChangeCount(.changeDone)
        
        sender.reloadData()
      }
      else
      {
        self.selectedColorSetIndex = index
        
        //document.colorSets[self.selectedColorSetIndex].print()
      }
    }
    self.reloadData()
    self.windowController?.window?.makeFirstResponder(self.forceFieldTableView)
  }
}
