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
import iRASPAKit

class StructureInfoDetailViewController: NSViewController, NSOutlineViewDelegate, NSTextViewDelegate, WindowControllerConsumer, ProjectConsumer
{
  weak var windowController: iRASPAWindowController?
  
  var iRASPAObjects: [iRASPAObject] = []
  
  @IBOutlet private weak var infoOutlineView: NSStaticViewBasedOutlineView?
  
  let creatorCell: OutlineViewItem = OutlineViewItem("CreatorCell")
  let creationCell: OutlineViewItem = OutlineViewItem("CreationCell")
  let creationMethods: OutlineViewItem = OutlineViewItem("CreationMethods")
  let chemicalCell: OutlineViewItem = OutlineViewItem("ChemicalCell")
  let publicationCell: OutlineViewItem = OutlineViewItem("PublicationCell")
  
  // MARK: protocol ProjectConsumer
  // =====================================================================
  
  weak var proxyProject: ProjectTreeNode? = nil
  
  // ViewDidLoad: bounds are not yet set (do not do geometry-related etup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    // check that it works with strong-references off (for compatibility with 'El Capitan')
    self.infoOutlineView?.stronglyReferencesItems = false
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    let creatorItem: OutlineViewItem = OutlineViewItem(title: "CreatorGroup", children: [creatorCell])
    let creationItem: OutlineViewItem = OutlineViewItem(title: "CreationGroup", children: [creationCell, creationMethods])
    let chemicalItem: OutlineViewItem = OutlineViewItem(title: "ChemicalGroup", children: [chemicalCell])
    let publicationItem: OutlineViewItem = OutlineViewItem(title: "PublicationGroup", children: [publicationCell])
    
    self.infoOutlineView?.items = [creatorItem, creationItem, chemicalItem, publicationItem]
  }
  
  override func viewWillAppear()
  {
    self.infoOutlineView?.needsLayout = true
    super.viewWillAppear()
  }
  
  var expandedItems: [Bool] = [false,false, false,false,false,false,false,false]
  
  func storeExpandedItems()
  {
    if let outlineView = self.infoOutlineView
    {
      for i in 0..<outlineView.items.count
      {
        self.expandedItems[i] = outlineView.isItemExpanded(outlineView.items[i])
      }
    }
  }

  func reloadData()
  {
    assert(Thread.isMainThread)
    
    self.infoOutlineView?.reloadData()
        
    NSAnimationContext.runAnimationGroup({context in
      context.duration = 0
      
      if let outlineView = self.infoOutlineView
      {
        for i in 0..<outlineView.items.count
        {
          if (self.expandedItems[i])
          {
            outlineView.expandItem(outlineView.items[i])
          }
          else
          {
            outlineView.collapseItem(outlineView.items[i])
          }
        }
      }
    }, completionHandler: {})
  }

  
  // MARK: NSTableView Delegate Methods
  // =====================================================================
  
  
  func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool
  {
    return true
  }
  
  func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool
  {
    return false
  }
  
  func getSubviewsOfView(_ v:NSView) -> [NSView]
  {
    var circleArray = [NSView]()
    
    for subview in v.subviews
    {
      circleArray += getSubviewsOfView(subview)
      
      circleArray.append(subview)
    }
    
    return circleArray
  }
  
  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView?
  {
    if let rowView: InfoTableRowView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "infoTableRowView"), owner: self) as? InfoTableRowView
    {
      return rowView
    }
    return nil
  }
  
  
  @objc func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
  {
    if let string: String = (item as? OutlineViewItem)?.title,
       let view: NSTableCellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: string), owner: self) as? NSTableCellView
    {
      let enabled: Bool = proxyProject?.isEnabled ?? false
      
      setPropertiesCreatorTableCells(on: view, identifier: string, enabled: enabled)
      setPropertiesCreationTableCells(on: view, identifier: string, enabled: enabled)
      setPropertiesChemicalTableCells(on: view, identifier: string, enabled: enabled)
      setPropertiesCitationsTableCells(on: view, identifier: string, enabled: enabled)
      
      return view
    }
    return nil
  }
  
 
  
  func setPropertiesCreatorTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    switch(identifier)
    {
    case "CreatorCell":
      if let textFieldAuthorFirstName: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldAuthorFirstName.isEditable = false
        textFieldAuthorFirstName.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldAuthorFirstName.isEditable = enabled
          if let authorFirstName: String = self.structureAuthorFirstName
          {
            textFieldAuthorFirstName.stringValue = authorFirstName
          }
          else
          {
            textFieldAuthorFirstName.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldAuthorMiddleName: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldAuthorMiddleName.isEditable = false
        textFieldAuthorMiddleName.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldAuthorMiddleName.isEditable = enabled
          if let authorMiddleName: String = self.structureAuthorMiddleName
          {
            textFieldAuthorMiddleName.stringValue = authorMiddleName
          }
          else
          {
            textFieldAuthorMiddleName.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldAuthorLastName: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldAuthorLastName.isEditable = false
        textFieldAuthorLastName.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldAuthorLastName.isEditable = enabled
          if let authorFirstName: String = self.structureAuthorLastName
          {
            textFieldAuthorLastName.stringValue = authorFirstName
          }
          else
          {
            textFieldAuthorLastName.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldOrchidID: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldOrchidID.isEditable = false
        textFieldOrchidID.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldOrchidID.isEditable = enabled
          if let authorOrchidID: String = self.structureAuthorOrchidID
          {
            textFieldOrchidID.stringValue = authorOrchidID
          }
          else
          {
            textFieldOrchidID.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldResearcherID: NSTextField = view.viewWithTag(5) as? NSTextField
      {
        textFieldResearcherID.isEditable = false
        textFieldResearcherID.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldResearcherID.isEditable = enabled
          if let authorResearcherID: String = self.structureAuthorResearcherID
          {
            textFieldResearcherID.stringValue = authorResearcherID
          }
          else
          {
            textFieldResearcherID.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldAffiliationUniversityName: NSTextField = view.viewWithTag(6) as? NSTextField
      {
        textFieldAffiliationUniversityName.isEditable = false
        textFieldAffiliationUniversityName.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldAffiliationUniversityName.isEditable = enabled
          if let authorAffiliationUniversityName: String = self.structureAuthorAffiliationUniversityName
          {
            textFieldAffiliationUniversityName.stringValue = authorAffiliationUniversityName
          }
          else
          {
            textFieldAffiliationUniversityName.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldAffiliationFacultyName: NSTextField = view.viewWithTag(7) as? NSTextField
      {
        textFieldAffiliationFacultyName.isEditable = false
        textFieldAffiliationFacultyName.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldAffiliationFacultyName.isEditable = enabled
          if let authorAffiliationFacultyName: String = self.structureAuthorAffiliationFacultyName
          {
            textFieldAffiliationFacultyName.stringValue = authorAffiliationFacultyName
          }
          else
          {
            textFieldAffiliationFacultyName.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldAffiliationInstituteName: NSTextField = view.viewWithTag(8) as? NSTextField
      {
        textFieldAffiliationInstituteName.isEditable = false
        textFieldAffiliationInstituteName.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldAffiliationInstituteName.isEditable = enabled
          if let authorAffiliationInstituteName: String = self.structureAuthorAffiliationInstituteName
          {
            textFieldAffiliationInstituteName.stringValue = authorAffiliationInstituteName
          }
          else
          {
            textFieldAffiliationInstituteName.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldAffiliationCityName: NSTextField = view.viewWithTag(9) as? NSTextField
      {
        textFieldAffiliationCityName.isEditable = false
        textFieldAffiliationCityName.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldAffiliationCityName.isEditable = enabled
          if let authorAffiliationCityName: String = self.structureAuthorAffiliationCityName
          {
            textFieldAffiliationCityName.stringValue = authorAffiliationCityName
          }
          else
          {
            textFieldAffiliationCityName.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let countries: iRASPAPopUpButton = view.viewWithTag(10) as? iRASPAPopUpButton
      {
        countries.removeAllItems()
        let locale: Locale = NSLocale.current
        let sortedCountries = Locale.isoRegionCodes.compactMap { locale.localizedString(forRegionCode: $0)}.sorted()
        countries.addItems(withTitles: sortedCountries)
        
        countries.isEditable = false
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          countries.isEditable = enabled
          if let country: String = self.structureAuthorAffiliationCountryName
          {
            countries.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            countries.selectItem(withTitle: country)
          }
          else
          {
            countries.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
        else
        {
          countries.selectItem(withTitle: Locale.current.localizedString(forRegionCode: Locale.current.regionCode ?? "NL") ?? "Netherlands")
        }
      }
    default:
      break
    }
  }
  
  func setPropertiesCreationTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    switch(identifier)
    {
    case "CreationCell":
      if let datePickerCreationDate: NSDatePicker = view.viewWithTag(1) as? NSDatePicker
      {
        datePickerCreationDate.isEnabled = false
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          datePickerCreationDate.isEnabled = enabled
          if let date: Date = self.structureCreationDate
          {
            datePickerCreationDate.dateValue = date
          }
          else
          {
            datePickerCreationDate.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldCreationTemperature: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldCreationTemperature.isEditable = false
        textFieldCreationTemperature.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldCreationTemperature.isEditable = enabled
          
          if let value: String = self.structureCreationTemperature
          {
            textFieldCreationTemperature.stringValue = value
          }
          else
          {
            textFieldCreationTemperature.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let popupButtonCreationTemperatureScale: iRASPAPopUpButton = view.viewWithTag(3) as? iRASPAPopUpButton
      {
        popupButtonCreationTemperatureScale.isEditable = false
        popupButtonCreationTemperatureScale.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          popupButtonCreationTemperatureScale.isEditable = enabled
          
          if let rawValue: Int = self.structureCreationTemperatureScale?.rawValue
          {
            popupButtonCreationTemperatureScale.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popupButtonCreationTemperatureScale.selectItem(at: rawValue)
          }
          else
          {
            popupButtonCreationTemperatureScale.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let TextFieldCreationPressure: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        TextFieldCreationPressure.isEditable = false
        TextFieldCreationPressure.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          TextFieldCreationPressure.isEditable = enabled
          
          if let value: String = self.structureCreationPressure
          {
            TextFieldCreationPressure.stringValue = value
          }
          else
          {
            TextFieldCreationPressure.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let popupButtonCreationPressureScale: iRASPAPopUpButton = view.viewWithTag(5) as? iRASPAPopUpButton
      {
        popupButtonCreationPressureScale.isEditable = false
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          popupButtonCreationPressureScale.isEditable = enabled
          
          if let rawValue: Int = self.structureCreationPressureScale?.rawValue
          {
            popupButtonCreationPressureScale.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popupButtonCreationPressureScale.selectItem(at: rawValue)
          }
          else
          {
            popupButtonCreationPressureScale.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let popUpbuttonCreationMethod: iRASPAPopUpButton = view.viewWithTag(6) as? iRASPAPopUpButton
      {
        popUpbuttonCreationMethod.isEditable = false
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          popUpbuttonCreationMethod.isEditable = enabled
          
          if let rawValue = self.structureCreationMethod?.rawValue
          {
            popUpbuttonCreationMethod.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpbuttonCreationMethod.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonCreationMethod.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
      }
    case "CreationMethods":
      if let tabView: NSTabView = getSubviewsOfView(view).filter({$0.identifier?.rawValue == "creationTabView"}).first as? NSTabView
      {
        if let structureCreationMethod = self.structureCreationMethod
        {
          switch(structureCreationMethod)
          {
          case Structure.CreationMethod.unknown, Structure.CreationMethod.simulation:
            tabView.selectTabViewItem(at: 0)
            if let popUpCreationUnitCellRelaxationMethod: iRASPAPopUpButton = view.viewWithTag(10) as? iRASPAPopUpButton
            {
              popUpCreationUnitCellRelaxationMethod.isEditable = false
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                popUpCreationUnitCellRelaxationMethod.isEditable = enabled
                
                if let index: Int = self.structureCreationUnitCellRelaxationMethod?.rawValue
                {
                  popUpCreationUnitCellRelaxationMethod.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
                  popUpCreationUnitCellRelaxationMethod.selectItem(at: index)
                }
                else
                {
                  popUpCreationUnitCellRelaxationMethod.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let comboBoxCreationSoftwarePackageAtomicPositions: iRASPAComboBox = view.viewWithTag(11) as? iRASPAComboBox
            {
              comboBoxCreationSoftwarePackageAtomicPositions.isEditable = false
              comboBoxCreationSoftwarePackageAtomicPositions.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                comboBoxCreationSoftwarePackageAtomicPositions.isEditable = enabled
                
                if let value: String = self.structureCreationAtomicPositionsSoftwarePackage
                {
                  if comboBoxCreationSoftwarePackageAtomicPositions.indexOfItem(withObjectValue: value) == NSNotFound
                  {
                    comboBoxCreationSoftwarePackageAtomicPositions.insertItem(withObjectValue: value, at: 0)
                  }
                  comboBoxCreationSoftwarePackageAtomicPositions.selectItem(withObjectValue: value)
                }
                else
                {
                  comboBoxCreationSoftwarePackageAtomicPositions.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let textFieldCreationIonsRelaxationAlgorithm: iRASPAPopUpButton = view.viewWithTag(12) as? iRASPAPopUpButton
            {
              textFieldCreationIonsRelaxationAlgorithm.isEditable = false
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textFieldCreationIonsRelaxationAlgorithm.isEditable = enabled
                
                if let index: Int = self.structureCreationAtomicPositionsIonsRelaxationAlgorithm?.rawValue
                {
                  textFieldCreationIonsRelaxationAlgorithm.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
                  textFieldCreationIonsRelaxationAlgorithm.selectItem(at: index)
                }
                else
                {
                  textFieldCreationIonsRelaxationAlgorithm.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let textFieldCreationIonsRelaxationCheck: iRASPAPopUpButton = view.viewWithTag(13) as? iRASPAPopUpButton
            {
              textFieldCreationIonsRelaxationCheck.isEditable = false
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textFieldCreationIonsRelaxationCheck.isEditable = enabled
                
                if let index: Int = self.structureCreationAtomicPositionsIonsRelaxationCheck?.rawValue
                {
                  textFieldCreationIonsRelaxationCheck.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
                  textFieldCreationIonsRelaxationCheck.selectItem(at: index)
                }
                else
                {
                  textFieldCreationIonsRelaxationCheck.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let textFieldCreationAtomicPositionsForceField: iRASPAComboBox = view.viewWithTag(14) as? iRASPAComboBox
            {
              textFieldCreationAtomicPositionsForceField.isEditable = false
              textFieldCreationAtomicPositionsForceField.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textFieldCreationAtomicPositionsForceField.isEditable = enabled
                
                if let value: String = self.structureCreationAtomicPositionsForcefield
                {
                  if textFieldCreationAtomicPositionsForceField.indexOfItem(withObjectValue: value) == NSNotFound
                  {
                    textFieldCreationAtomicPositionsForceField.insertItem(withObjectValue: value, at: 0)
                  }
                  textFieldCreationAtomicPositionsForceField.selectItem(withObjectValue: value)
                }
                else
                {
                  textFieldCreationAtomicPositionsForceField.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let comboBoxCreationAtomicPositionsForceFieldDetails: iRASPAComboBox = view.viewWithTag(15) as? iRASPAComboBox
            {
              comboBoxCreationAtomicPositionsForceFieldDetails.isEditable = false
              comboBoxCreationAtomicPositionsForceFieldDetails.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                comboBoxCreationAtomicPositionsForceFieldDetails.isEditable = enabled
                
                if let value: String = self.structureCreationAtomicPositionsForcefieldDetails
                {
                  if comboBoxCreationAtomicPositionsForceFieldDetails.indexOfItem(withObjectValue: value) == NSNotFound
                  {
                    comboBoxCreationAtomicPositionsForceFieldDetails.insertItem(withObjectValue: value, at: 0)
                  }
                  comboBoxCreationAtomicPositionsForceFieldDetails.selectItem(withObjectValue: value)
                }
                else
                {
                  comboBoxCreationAtomicPositionsForceFieldDetails.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let comboBoxCreationSoftwarePackageAtomicCharges: iRASPAComboBox = view.viewWithTag(16) as? iRASPAComboBox
            {
              comboBoxCreationSoftwarePackageAtomicCharges.isEditable = false
              comboBoxCreationSoftwarePackageAtomicCharges.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                comboBoxCreationSoftwarePackageAtomicCharges.isEditable = enabled
                
                if let value: String = self.structureCreationAtomicChargesSoftwarePackage
                {
                  if comboBoxCreationSoftwarePackageAtomicCharges.indexOfItem(withObjectValue: value) == NSNotFound
                  {
                    comboBoxCreationSoftwarePackageAtomicCharges.insertItem(withObjectValue: value, at: 0)
                  }
                  comboBoxCreationSoftwarePackageAtomicCharges.selectItem(withObjectValue: value)
                }
                else
                {
                  comboBoxCreationSoftwarePackageAtomicCharges.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let comboBoxCreationAtomicChargesAlgorithms: iRASPAComboBox = view.viewWithTag(17) as? iRASPAComboBox
            {
              comboBoxCreationAtomicChargesAlgorithms.isEditable = false
              comboBoxCreationAtomicChargesAlgorithms.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                comboBoxCreationAtomicChargesAlgorithms.isEditable = enabled
                
                if let value: String = self.structureCreationAtomicChargesAlgorithms
                {
                  if comboBoxCreationAtomicChargesAlgorithms.indexOfItem(withObjectValue: value) == NSNotFound
                  {
                    comboBoxCreationAtomicChargesAlgorithms.insertItem(withObjectValue: value, at: 0)
                  }
                  comboBoxCreationAtomicChargesAlgorithms.selectItem(withObjectValue: value)
                }
                else
                {
                  comboBoxCreationAtomicChargesAlgorithms.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let comboBoxCreationAtomicChargesForcefield: iRASPAComboBox = view.viewWithTag(18) as? iRASPAComboBox
            {
              comboBoxCreationAtomicChargesForcefield.isEditable = false
              comboBoxCreationAtomicChargesForcefield.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                comboBoxCreationAtomicChargesForcefield.isEditable = enabled
                
                if let value: String = self.structureCreationAtomicChargesForcefield
                {
                  if comboBoxCreationAtomicChargesForcefield.indexOfItem(withObjectValue: value) == NSNotFound
                  {
                    comboBoxCreationAtomicChargesForcefield.insertItem(withObjectValue: value, at: 0)
                  }
                  comboBoxCreationAtomicChargesForcefield.selectItem(withObjectValue: value)
                }
                else
                {
                  comboBoxCreationAtomicChargesForcefield.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let comboBoxCreationAtomicChargesForcefieldDetails: iRASPAComboBox = view.viewWithTag(19) as? iRASPAComboBox
            {
              comboBoxCreationAtomicChargesForcefieldDetails.isEditable = false
              comboBoxCreationAtomicChargesForcefieldDetails.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                comboBoxCreationAtomicChargesForcefieldDetails.isEditable = enabled
                
                if let value: String = self.structureCreationAtomicChargesForcefieldDetails
                {
                  if comboBoxCreationAtomicChargesForcefieldDetails.indexOfItem(withObjectValue: value) == NSNotFound
                  {
                    comboBoxCreationAtomicChargesForcefieldDetails.insertItem(withObjectValue: value, at: 0)
                  }
                  comboBoxCreationAtomicChargesForcefieldDetails.selectItem(withObjectValue: value)
                }
                else
                {
                  comboBoxCreationAtomicChargesForcefieldDetails.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
          case Structure.CreationMethod.experimental:
            tabView.selectTabViewItem(at: 1)
            if let textFieldMeasurementRadiation: NSTextField = view.viewWithTag(30) as? NSTextField
            {
              textFieldMeasurementRadiation.isEditable = false
              textFieldMeasurementRadiation.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textFieldMeasurementRadiation.isEditable = enabled
                
                if let value: String = self.structureExperimentalMeasurementRadiation
                {
                  textFieldMeasurementRadiation.stringValue = value
                }
                else
                {
                  textFieldMeasurementRadiation.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let textFieldMeasurementWaveLength: NSTextField = view.viewWithTag(31) as? NSTextField
            {
              textFieldMeasurementWaveLength.isEditable = false
              textFieldMeasurementWaveLength.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textFieldMeasurementWaveLength.isEditable = enabled
                
                if let value: String = self.structureExperimentalMeasurementWaveLength
                {
                  textFieldMeasurementWaveLength.stringValue = value
                }
                else
                {
                  textFieldMeasurementWaveLength.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let textFieldMeasurementThetaMin: NSTextField = view.viewWithTag(32) as? NSTextField
            {
              textFieldMeasurementThetaMin.isEditable = false
              textFieldMeasurementThetaMin.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textFieldMeasurementThetaMin.isEditable = enabled
                
                if let value: String = self.structureExperimentalMeasurementThetaMin
                {
                  textFieldMeasurementThetaMin.stringValue = value
                }
                else
                {
                  textFieldMeasurementThetaMin.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let textFieldMeasurementThetaMax: NSTextField = view.viewWithTag(33) as? NSTextField
            {
              textFieldMeasurementThetaMax.isEditable = false
              textFieldMeasurementThetaMax.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textFieldMeasurementThetaMax.isEditable = enabled
                
                if let value: String = self.structureExperimentalMeasurementThetaMax
                {
                  textFieldMeasurementThetaMax.stringValue = value
                }
                else
                {
                  textFieldMeasurementThetaMax.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let textFieldMeasurementIndexLimitsHmin: NSTextField = view.viewWithTag(34) as? NSTextField
            {
              textFieldMeasurementIndexLimitsHmin.isEditable = false
              textFieldMeasurementIndexLimitsHmin.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textFieldMeasurementIndexLimitsHmin.isEditable = enabled
                
                if let value: String = self.structureExperimentalMeasurementIndexLimitsHmin
                {
                  textFieldMeasurementIndexLimitsHmin.stringValue = value
                }
                else
                {
                  textFieldMeasurementIndexLimitsHmin.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let textFieldMeasurementIndexLimitsHmax: NSTextField = view.viewWithTag(35) as? NSTextField
            {
              textFieldMeasurementIndexLimitsHmax.isEditable = false
              textFieldMeasurementIndexLimitsHmax.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textFieldMeasurementIndexLimitsHmax.isEditable = enabled
                
                if let value: String = self.structureExperimentalMeasurementIndexLimitsHmax
                {
                  textFieldMeasurementIndexLimitsHmax.stringValue = value
                }
                else
                {
                  textFieldMeasurementIndexLimitsHmax.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let textFieldMeasurementIndexLimitsKmin: NSTextField = view.viewWithTag(36) as? NSTextField
            {
              textFieldMeasurementIndexLimitsKmin.isEditable = false
              textFieldMeasurementIndexLimitsKmin.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textFieldMeasurementIndexLimitsKmin.isEditable = enabled
                
                if let value: String = self.structureExperimentalMeasurementIndexLimitsKmin
                {
                  textFieldMeasurementIndexLimitsKmin.stringValue = value
                }
                else
                {
                  textFieldMeasurementIndexLimitsKmin.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let textFieldMeasurementIndexLimitsKmax: NSTextField = view.viewWithTag(37) as? NSTextField
            {
              textFieldMeasurementIndexLimitsKmax.isEditable = false
              textFieldMeasurementIndexLimitsKmax.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textFieldMeasurementIndexLimitsKmax.isEditable = enabled
                
                if let value: String = self.structureExperimentalMeasurementIndexLimitsKmax
                {
                  textFieldMeasurementIndexLimitsKmax.stringValue = value
                }
                else
                {
                  textFieldMeasurementIndexLimitsKmax.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let textFieldMeasurementIndexLimitsLmin: NSTextField = view.viewWithTag(38) as? NSTextField
            {
              textFieldMeasurementIndexLimitsLmin.isEditable = false
              textFieldMeasurementIndexLimitsLmin.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textFieldMeasurementIndexLimitsLmin.isEditable = enabled
                
                if let value: String = self.structureExperimentalMeasurementIndexLimitsLmin
                {
                  textFieldMeasurementIndexLimitsLmin.stringValue = value
                }
                else
                {
                  textFieldMeasurementIndexLimitsLmin.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let textFieldMeasurementIndexLimitsLmax: NSTextField = view.viewWithTag(39) as? NSTextField
            {
              textFieldMeasurementIndexLimitsLmax.isEditable = false
              textFieldMeasurementIndexLimitsLmax.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textFieldMeasurementIndexLimitsLmax.isEditable = enabled
                
                if let value: String = self.structureExperimentalMeasurementIndexLimitsLmax
                {
                  textFieldMeasurementIndexLimitsLmax.stringValue = value
                }
                else
                {
                  textFieldMeasurementIndexLimitsLmax.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let textFieldMeasurementNumberOfSymmetryIndependentReflections: NSTextField = view.viewWithTag(40) as? NSTextField
            {
              textFieldMeasurementNumberOfSymmetryIndependentReflections.isEditable = false
              textFieldMeasurementNumberOfSymmetryIndependentReflections.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textFieldMeasurementNumberOfSymmetryIndependentReflections.isEditable = enabled
                
                if let value: String = self.structureExperimentalMeasurementNumberOfSymmetryIndependentReflections
                {
                  textFieldMeasurementNumberOfSymmetryIndependentReflections.stringValue = value
                }
                else
                {
                  textFieldMeasurementNumberOfSymmetryIndependentReflections.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            if let textFieldMeasurementSoftware: NSTextField = view.viewWithTag(41) as? NSTextField
            {
              textFieldMeasurementSoftware.isEditable = false
              textFieldMeasurementSoftware.stringValue = ""
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textFieldMeasurementSoftware.isEditable = enabled
                
                if let value: String = self.structureExperimentalMeasurementSoftware
                {
                  textFieldMeasurementSoftware.stringValue = value
                }
                else
                {
                  textFieldMeasurementSoftware.stringValue = NSLocalizedString("Multiple Values", comment: "")
                }
              }
            }
            tabView.selectTabViewItem(at: 1)
            
            if let textViewRefinementDetails: NSTextView = getSubviewsOfView(view).filter({$0.identifier?.rawValue == "ExperimentalRefinementDetails"}).first as? NSTextView
            {
              textViewRefinementDetails.isEditable = false
              textViewRefinementDetails.typingAttributes = [.foregroundColor : NSColor.textColor]
              textViewRefinementDetails.textStorage?.setAttributedString(NSAttributedString(string: "",  attributes: [.foregroundColor : NSColor.textColor]))
              if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
              {
                textViewRefinementDetails.isEditable = enabled
                
                if let value: String = self.structureExperimentalMeasurementRefinementDetails
                {
                  textViewRefinementDetails.textStorage?.setAttributedString(NSAttributedString(string: value))
                }
                else
                {
                  textViewRefinementDetails.textStorage?.setAttributedString(NSAttributedString(string: NSLocalizedString("Multiple Values", comment: "")))
                }
              }

            }
          }
        }
        if let textFieldMeasurementGoodnessOfFit: NSTextField = view.viewWithTag(43) as? NSTextField
        {
          textFieldMeasurementGoodnessOfFit.isEditable = false
          textFieldMeasurementGoodnessOfFit.stringValue = ""
          if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
          {
            textFieldMeasurementGoodnessOfFit.isEditable = enabled
            
            if let value: String = self.structureExperimentalMeasurementGoodnessOfFit
            {
              textFieldMeasurementGoodnessOfFit.stringValue = value
            }
            else
            {
              textFieldMeasurementGoodnessOfFit.stringValue = NSLocalizedString("Multiple Values", comment: "")
            }
          }
        }
        if let textFieldMeasurementRFactorGt: NSTextField = view.viewWithTag(44) as? NSTextField
        {
          textFieldMeasurementRFactorGt.isEditable = false
          textFieldMeasurementRFactorGt.stringValue = ""
          if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
          {
            textFieldMeasurementRFactorGt.isEditable = enabled
            
            if let value: String = self.structureExperimentalMeasurementRFactorGt
            {
              textFieldMeasurementRFactorGt.stringValue = value
            }
            else
            {
              textFieldMeasurementRFactorGt.stringValue = NSLocalizedString("Multiple Values", comment: "")
            }
          }
        }
        if let textFieldMeasurementRFactorAll: NSTextField = view.viewWithTag(45) as? NSTextField
        {
          textFieldMeasurementRFactorAll.isEditable = false
          textFieldMeasurementRFactorAll.stringValue = ""
          if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
          {
            textFieldMeasurementRFactorAll.isEditable = enabled
            
            if let value: String = self.structureExperimentalMeasurementRFactorAll
            {
              textFieldMeasurementRFactorAll.stringValue = value
            }
            else
            {
              textFieldMeasurementRFactorAll.stringValue = NSLocalizedString("Multiple Values", comment: "")
            }
          }
        }
      }
    default:
      break
    }
  }
  
  func setPropertiesChemicalTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    switch(identifier)
    {
    case "ChemicalCell":
      if let textFieldChemicalFormulaMoiety: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldChemicalFormulaMoiety.isEditable = false
        textFieldChemicalFormulaMoiety.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldChemicalFormulaMoiety.isEditable = enabled
          
          if let value: String = self.structureChemicalFormulaMoiety
          {
            textFieldChemicalFormulaMoiety.stringValue = value
          }
          else
          {
            textFieldChemicalFormulaMoiety.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldChemicalFormulaSum: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldChemicalFormulaSum.isEditable = false
        textFieldChemicalFormulaSum.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldChemicalFormulaSum.isEditable = enabled
          
          if let value: String = self.structureChemicalFormulaSum
          {
            textFieldChemicalFormulaSum.stringValue = value
          }
          else
          {
            textFieldChemicalFormulaSum.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldChemicalNameSystematic: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldChemicalNameSystematic.isEditable = false
        textFieldChemicalNameSystematic.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldChemicalNameSystematic.isEditable = enabled
          
          if let value: String = self.structureChemicalNameSystematic
          {
            textFieldChemicalNameSystematic.stringValue = value
          }
          else
          {
            textFieldChemicalNameSystematic.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
    default:
      break
    }
  }
  
  func setPropertiesCitationsTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    switch(identifier)
    {
    case "PublicationCell":
      if let textViewCitationArticleTitle: NSTextView = getSubviewsOfView(view).filter({$0.identifier?.rawValue == "citationArticleTitle"}).first as? NSTextView
      {
        textViewCitationArticleTitle.isEditable = false
        textViewCitationArticleTitle.typingAttributes = [.foregroundColor : NSColor.textColor]
        textViewCitationArticleTitle.textStorage?.setAttributedString(NSAttributedString(string: "", attributes: [.foregroundColor : NSColor.textColor]))
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textViewCitationArticleTitle.isEditable = enabled
          
          if let value: String = self.structureCitationArticleTitle
          {
            textViewCitationArticleTitle.textStorage?.setAttributedString(NSAttributedString(string: value,  attributes: [.foregroundColor : NSColor.textColor]))
          }
          else
          {
            textViewCitationArticleTitle.textStorage?.setAttributedString(NSAttributedString(string: NSLocalizedString("Multiple Values", comment: "")))
          }
        }
        
      }
      
      if let textFieldCitationJournalTitle: iRASPAComboBox = view.viewWithTag(1) as? iRASPAComboBox
      {
        textFieldCitationJournalTitle.isEditable = false
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldCitationJournalTitle.isEditable = enabled
          
          if let value: String = self.structureCitationJournalTitle
          {
            if textFieldCitationJournalTitle.indexOfItem(withObjectValue: value) == NSNotFound
            {
              textFieldCitationJournalTitle.insertItem(withObjectValue: value, at: 0)
            }
            textFieldCitationJournalTitle.selectItem(withObjectValue: value)
          }
          else
          {
            textFieldCitationJournalTitle.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      
      if let textViewCitationArticleAuthors: NSTextView = getSubviewsOfView(view).filter({$0.identifier?.rawValue == "citationArticleAuthors"}).first as? NSTextView
      {
        textViewCitationArticleAuthors.isEditable = false
        textViewCitationArticleAuthors.typingAttributes = [.foregroundColor : NSColor.textColor]
        textViewCitationArticleAuthors.textStorage?.setAttributedString(NSAttributedString(string: "", attributes: [.foregroundColor : NSColor.textColor]))
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textViewCitationArticleAuthors.isEditable = enabled
          
          if let value: String = self.structureCitationAuthors
          {
            textViewCitationArticleAuthors.textStorage?.setAttributedString(NSAttributedString(string: value,  attributes: [.foregroundColor : NSColor.textColor]))
          }
          else
          {
            textViewCitationArticleAuthors.textStorage?.setAttributedString(NSAttributedString(string: NSLocalizedString("Multiple Values", comment: "")))
          }
        }
        
      }
      
      if let textFieldCitationJournalVolume: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldCitationJournalVolume.isEditable = false
        textFieldCitationJournalVolume.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldCitationJournalVolume.isEditable = enabled
          
          if let value: String = self.structureCitationJournalVolume
          {
            textFieldCitationJournalVolume.stringValue = value
          }
          else
          {
            textFieldCitationJournalVolume.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      
      if let textFieldCitationJournalNumber: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldCitationJournalNumber.isEditable = false
        textFieldCitationJournalNumber.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldCitationJournalNumber.isEditable = enabled
          
          if let value: String = self.structureCitationJournalNumber
          {
            textFieldCitationJournalNumber.stringValue = value
          }
          else
          {
            textFieldCitationJournalNumber.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      
      if let datePickerCitationPublicationDate: NSDatePicker = view.viewWithTag(5) as? NSDatePicker
      {
        datePickerCitationPublicationDate.isEnabled = false
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          datePickerCitationPublicationDate.isEnabled = enabled
          if let date: Date = self.structureCitationPublicationDate
          {
            datePickerCitationPublicationDate.dateValue = date
          }
          else
          {
            datePickerCitationPublicationDate.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      
      if let textFieldCitationDOI: NSTextField = view.viewWithTag(6) as? NSTextField
      {
        textFieldCitationDOI.isEditable = false
        textFieldCitationDOI.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldCitationDOI.isEditable = enabled
          
          if let value: String = self.structureCitationDOI
          {
            textFieldCitationDOI.stringValue = value
          }
          else
          {
            textFieldCitationDOI.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      
      if let textFieldCitationDatebaseCodes: NSTextField = view.viewWithTag(7) as? NSTextField
      {
        textFieldCitationDatebaseCodes.isEditable = false
        textFieldCitationDatebaseCodes.stringValue = ""
        if !iRASPAObjects.filter({$0.object is InfoEditor}).isEmpty
        {
          textFieldCitationDatebaseCodes.isEditable = enabled
          
          if let value: String = self.structureCitationDatebaseCodes
          {
            textFieldCitationDatebaseCodes.stringValue = value
          }
          else
          {
            textFieldCitationDatebaseCodes.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
    default:
      break
    }
  }

  // MARK: NSOutlineView notifications for expanding/collapsing items
  // =====================================================================
  
  func outlineViewItemDidExpand(_ notification:Notification)
  {
    let dictionary: AnyObject  = notification.userInfo?["NSObject"] as AnyObject
    if let index: Int = self.infoOutlineView?.childIndex(forItem: dictionary)
    {
      self.expandedItems[index] = true
    }
  }
  
  
  func outlineViewItemDidCollapse(_ notification:Notification)
  {
    let dictionary: AnyObject  = notification.userInfo?["NSObject"] as AnyObject
    if let index: Int = self.infoOutlineView?.childIndex(forItem: dictionary)
    {
      self.expandedItems[index] = false
    }
  }
  
  // MARK: Update outlineView
  // =====================================================================
  
  func updateOutlineView(identifiers: [OutlineViewItem])
  {
    // Update at the next iteration (reloading could be in progress)
    DispatchQueue.main.async(execute: {[weak self] in
      for identifier in identifiers
      {
        if let row: Int = self?.infoOutlineView?.row(forItem: identifier), row >= 0
        {
          self?.infoOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
        }
      }
    })
  }
  
  // MARK: Editing routines for creator
  // =====================================================================

  @IBAction func changedAuthorFirstName(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.structureAuthorFirstName = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorMiddleName(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.structureAuthorMiddleName = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorLastName(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.structureAuthorLastName = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorOrchidID(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.structureAuthorOrchidID = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorResearcherID(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.structureAuthorResearcherID = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorAffilitionUniversityName(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.structureAuthorAffiliationUniversityName = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorAffilitionFacultyName(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.structureAuthorAffiliationFacultyName = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorAffilitionInstituteName(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.structureAuthorAffiliationInstituteName = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorAffilitionCityName(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.structureAuthorAffiliationCityName = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorAffilitionCountryName(_ sender: NSPopUpButton)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      if let countryName: String = sender.titleOfSelectedItem
      {
        self.windowController?.document?.updateChangeCount(.changeDone)
        ProjectTreeNode.representedObject.isEdited = true
        self.structureAuthorAffiliationCountryName = countryName
        
        self.updateOutlineView(identifiers: [self.creatorCell])
      }
    }
  }

  @IBAction func changeCreationDate(_ sender: NSDatePicker)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationDate = sender.dateValue
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changeCreationTemperature(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationTemperature = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changeCreationTemperatureScale(_ sender: NSPopUpButton)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationTemperatureScale =  Structure.TemperatureScale(rawValue: sender.indexOfSelectedItem)
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changeCreationPressure(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationPressure = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changeCreationPressureScale(_ sender: NSPopUpButton)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationPressureScale =  Structure.PressureScale(rawValue: sender.indexOfSelectedItem)
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  
  // MARK: Editing routines for creation
  // =====================================================================

  
  @IBAction func changeCreationMethod(_ sender: NSPopUpButton)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationMethod = Structure.CreationMethod(rawValue: sender.indexOfSelectedItem)
      
      self.updateOutlineView(identifiers: [self.creationCell, self.creationMethods])
    }
  }
  
  @IBAction func changeCreationUnitCellRelaxationMethod(_ sender: NSPopUpButton)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationUnitCellRelaxationMethod = Structure.UnitCellRelaxationMethod(rawValue: sender.indexOfSelectedItem)
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationSoftwarePackageAtomicPositions(_ sender: NSComboBox)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationAtomicPositionsSoftwarePackage = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationIonsRelaxationAlgorithm(_ sender: NSPopUpButton)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationAtomicPositionsIonsRelaxationAlgorithm = Structure.IonsRelaxationAlgorithm(rawValue: sender.indexOfSelectedItem)
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationIonsRelaxationCheck(_ sender: NSPopUpButton)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationAtomicPositionsIonsRelaxationCheck = Structure.IonsRelaxationCheck(rawValue: sender.indexOfSelectedItem)
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationAtomicPositionsForcefield(_ sender: NSComboBox)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationAtomicPositionsForcefield = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationAtomicPositionsForcefieldDetails(_ sender: NSComboBox)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationAtomicPositionsForcefieldDetails = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  
  @IBAction func changeCreationAtomicChargesSoftwarePackage(_ sender: NSComboBox)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationAtomicChargesSoftwarePackage = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationAtomicChargesAlgorithms(_ sender: NSComboBox)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationAtomicChargesAlgorithms = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationAtomicChargesForcefield(_ sender: NSComboBox)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationAtomicChargesForcefield = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationAtomicChargesForcefieldDetail(_ sender: NSComboBox)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCreationAtomicChargesForcefieldDetails = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  
  @IBAction func changeMeasurementRadiation(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureExperimentalMeasurementRadiation = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementWaveLength(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureExperimentalMeasurementWaveLength = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementThetaMin(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureExperimentalMeasurementThetaMin = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementThetaMax(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureExperimentalMeasurementThetaMax = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementIndexLimitsHmin(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureExperimentalMeasurementIndexLimitsHmin = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementIndexLimitsHmax(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureExperimentalMeasurementIndexLimitsHmax = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementIndexLimitsKmin(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureExperimentalMeasurementIndexLimitsKmin = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementIndexLimitsKmax(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureExperimentalMeasurementIndexLimitsKmax = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementIndexLimitsLmin(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureExperimentalMeasurementIndexLimitsLmin = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementIndexLimitsLmax(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureExperimentalMeasurementIndexLimitsLmax = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementNumberOfSymmetryIndependentReflections(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureExperimentalMeasurementNumberOfSymmetryIndependentReflections = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementSoftware(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureExperimentalMeasurementSoftware = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }

  
  func textDidChange(_ notification: Notification)
  {
    guard let textView = notification.object as? NSTextView else { return }
    
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
       let identifier: String = textView.identifier?.rawValue
    {
      let textString: String = textView.string
      
      switch(identifier)
      {
      case "ExperimentalRefinementDetails":
        self.structureExperimentalMeasurementRefinementDetails = textString
      case "citationArticleAuthors":
        self.structureCitationAuthors = textString
      case "citationArticleTitle":
        self.structureCitationArticleTitle = textString
      default:
        break
      }
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementGoodnessOfFit(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureExperimentalMeasurementGoodnessOfFit = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementRFactorGt(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureExperimentalMeasurementRFactorGt = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementRFactorAll(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureExperimentalMeasurementRFactorAll = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  // MARK: Editing routines for ChemicalCell
  // =====================================================================
  

  @IBAction func changeChemicalFormulaMoiety(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureChemicalFormulaMoiety = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.chemicalCell])
    }
  }
  
  @IBAction func changeChemicalFormulaSum(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureChemicalFormulaSum = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.chemicalCell])
    }
  }

  @IBAction func changeChemicalNameSystematic(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureChemicalNameSystematic = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.chemicalCell])
    }
  }
  
  
  // MARK: Editing routines for PublicationCell
  // =====================================================================

  @IBAction func changeCitationJournalTitle(_ sender: NSComboBox)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
      !sender.stringValue.isEmpty
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCitationJournalTitle = sender.stringValue
     
      self.updateOutlineView(identifiers: [self.publicationCell])
    }
  }
  
  @IBAction func changeCitationJournalVolume(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCitationJournalVolume = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.publicationCell])
    }
  }
  
  @IBAction func changeCitationJournalNumber(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCitationJournalNumber = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.publicationCell])
    }
  }
  
  @IBAction func changeCitationPublicationDate(_ sender: NSDatePicker)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCitationPublicationDate = sender.dateValue
      
      self.updateOutlineView(identifiers: [self.publicationCell])
    }
  }

  
  @IBAction func changeCitationDOI(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCitationDOI = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.publicationCell])
    }
  }
  
  @IBAction func changeCitationDatebaseCodes(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.structureCitationDatebaseCodes = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.publicationCell])
    }
  }

  
  // MARK: Infor Viewer
  //===================================================================================================================================================
  
  public var structureAuthorFirstName: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.authorFirstName}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.authorFirstName = newValue ?? ""})
    }
  }
  
  public var structureAuthorMiddleName: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.authorMiddleName}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.authorMiddleName = newValue ?? ""})
    }
  }
  
  public var structureAuthorLastName: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.authorLastName}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.authorLastName = newValue ?? ""})
    }
  }
  
  public var structureAuthorOrchidID: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.authorOrchidID}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.authorOrchidID = newValue ?? ""})
    }
  }
 
  public var structureAuthorResearcherID: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.authorResearcherID}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.authorResearcherID = newValue ?? ""})
    }
  }
  
  public var structureAuthorAffiliationUniversityName: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.authorAffiliationUniversityName}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.authorAffiliationUniversityName = newValue ?? ""})
    }
  }
  
  public var structureAuthorAffiliationFacultyName: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.authorAffiliationFacultyName}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.authorAffiliationFacultyName = newValue ?? ""})
    }
  }
  
  public var structureAuthorAffiliationInstituteName: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.authorAffiliationInstituteName}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.authorAffiliationInstituteName = newValue ?? ""})
    }
  }
  
  public var structureAuthorAffiliationCityName: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.authorAffiliationCityName}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.authorAffiliationCityName = newValue ?? ""})
    }
  }
  
  public var structureAuthorAffiliationCountryName: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.authorAffiliationCountryName}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.authorAffiliationCountryName = newValue ?? ""})
    }
  }
  
  public var structureCreationDate: Date?
  {
    get
    {
      let set: Set<Date> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationDate}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationDate = newValue ?? Date()})
    }
  }
  
  public var structureCreationTemperature: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationTemperature}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationTemperature = newValue ?? ""})
    }
  }
  
  public var structureCreationTemperatureScale: Structure.TemperatureScale?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationTemperatureScale.rawValue}))
      return Set(set).count == 1 ? Structure.TemperatureScale(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationTemperatureScale = newValue ?? .Kelvin})
    }
  }
  
  public var structureCreationPressure: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationPressure}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationPressure = newValue ?? ""})
    }
  }

  public var structureCreationPressureScale: Structure.PressureScale?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationPressureScale.rawValue}))
      return Set(set).count == 1 ? Structure.PressureScale(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationPressureScale = newValue ?? .Pascal})
    }
  }
  
  public var structureCreationMethod: Structure.CreationMethod?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationMethod.rawValue}))
      return Set(set).count == 1 ? Structure.CreationMethod(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationMethod = newValue ?? .unknown})
    }
  }
  
  public var structureCreationUnitCellRelaxationMethod: Structure.UnitCellRelaxationMethod?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationUnitCellRelaxationMethod.rawValue}))
      return Set(set).count == 1 ? Structure.UnitCellRelaxationMethod(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationUnitCellRelaxationMethod = newValue ?? .unknown})
    }
  }
  
  public var structureCreationAtomicPositionsSoftwarePackage: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationAtomicPositionsSoftwarePackage}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationAtomicPositionsSoftwarePackage = newValue ?? ""})
    }
  }

  
  public var structureCreationAtomicPositionsIonsRelaxationAlgorithm: Structure.IonsRelaxationAlgorithm?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationAtomicPositionsIonsRelaxationAlgorithm.rawValue}))
      return Set(set).count == 1 ? Structure.IonsRelaxationAlgorithm(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationAtomicPositionsIonsRelaxationAlgorithm = newValue ?? .unknown})
    }
  }
  
  public var structureCreationAtomicPositionsIonsRelaxationCheck: Structure.IonsRelaxationCheck?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationAtomicPositionsIonsRelaxationCheck.rawValue}))
      return Set(set).count == 1 ? Structure.IonsRelaxationCheck(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationAtomicPositionsIonsRelaxationCheck = newValue ?? .unknown})
    }
  }
  
  public var structureCreationAtomicPositionsForcefield: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationAtomicPositionsForcefield}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationAtomicPositionsForcefield = newValue ?? ""})
    }
  }
  
  public var structureCreationAtomicPositionsForcefieldDetails: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationAtomicPositionsForcefieldDetails}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationAtomicPositionsForcefieldDetails = newValue ?? ""})
    }
  }
  
  public var structureCreationAtomicChargesSoftwarePackage: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationAtomicChargesSoftwarePackage}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationAtomicChargesSoftwarePackage = newValue ?? ""})
    }
  }
  
  public var structureCreationAtomicChargesAlgorithms: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationAtomicChargesAlgorithms}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationAtomicChargesAlgorithms = newValue ?? ""})
    }
  }
  
  public var structureCreationAtomicChargesForcefield: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationAtomicChargesForcefield}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationAtomicChargesForcefield = newValue ?? ""})
    }
  }
  
  public var structureCreationAtomicChargesForcefieldDetails: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.creationAtomicChargesForcefieldDetails}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.creationAtomicChargesForcefieldDetails = newValue ?? ""})
    }
  }
  
  // Experimental
  
  public var structureExperimentalMeasurementRadiation: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementRadiation}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementRadiation = newValue ?? ""})
    }
  }
  public var structureExperimentalMeasurementWaveLength: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementWaveLength}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementWaveLength = newValue ?? ""})
    }
  }
  public var structureExperimentalMeasurementThetaMin: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementThetaMin}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementThetaMin = newValue ?? ""})
    }
  }
  public var structureExperimentalMeasurementThetaMax: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementThetaMax}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementThetaMax = newValue ?? ""})
    }
  }
  public var structureExperimentalMeasurementIndexLimitsHmin: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementIndexLimitsHmin}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementIndexLimitsHmin = newValue ?? ""})
    }
  }
  public var structureExperimentalMeasurementIndexLimitsHmax: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementIndexLimitsHmax}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementIndexLimitsHmax = newValue ?? ""})
    }
  }
  public var structureExperimentalMeasurementIndexLimitsKmin: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementIndexLimitsKmin}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementIndexLimitsKmin = newValue ?? ""})
    }
  }
  public var structureExperimentalMeasurementIndexLimitsKmax: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementIndexLimitsKmax}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementIndexLimitsKmax = newValue ?? ""})
    }
  }
  public var structureExperimentalMeasurementIndexLimitsLmin: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementIndexLimitsLmin}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementIndexLimitsLmin = newValue ?? ""})
    }
  }
  public var structureExperimentalMeasurementIndexLimitsLmax: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementIndexLimitsLmax}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementIndexLimitsLmax = newValue ?? ""})
    }
  }
  public var structureExperimentalMeasurementNumberOfSymmetryIndependentReflections: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementNumberOfSymmetryIndependentReflections}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementNumberOfSymmetryIndependentReflections = newValue ?? ""})
    }
  }
  public var structureExperimentalMeasurementSoftware: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementSoftware}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementSoftware = newValue ?? ""})
    }
  }

  public var structureExperimentalMeasurementRefinementDetails: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementRefinementDetails}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementRefinementDetails = newValue ?? ""})
    }
  }
  public var structureExperimentalMeasurementGoodnessOfFit: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementGoodnessOfFit}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementGoodnessOfFit = newValue ?? ""})
    }
  }
  public var structureExperimentalMeasurementRFactorGt: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementRFactorGt}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementRFactorGt = newValue ?? ""})
    }
  }
  public var structureExperimentalMeasurementRFactorAll: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.experimentalMeasurementRFactorAll}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.experimentalMeasurementRFactorAll = newValue ?? ""})
    }
  }
  
  // chemical
  public var structureChemicalFormulaMoiety: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.chemicalFormulaMoiety}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.chemicalFormulaMoiety = newValue ?? ""})
    }
  }
  public var structureChemicalFormulaSum: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.chemicalFormulaSum}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.chemicalFormulaSum = newValue ?? ""})
    }
  }
  public var structureChemicalNameSystematic: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.chemicalNameSystematic}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.chemicalNameSystematic = newValue ?? ""})
    }
  }
  
  
  // citation
  public var structureCitationArticleTitle: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.citationArticleTitle}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.citationArticleTitle = newValue ?? ""})
    }
  }
  public var structureCitationAuthors: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.citationAuthors}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.citationAuthors = newValue ?? ""})
    }
  }
  public var structureCitationJournalTitle: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.citationJournalTitle}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.citationJournalTitle = newValue ?? ""})
    }
  }
  public var structureCitationJournalVolume: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.citationJournalVolume}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.citationJournalVolume = newValue ?? ""})
    }
  }
  public var structureCitationJournalNumber: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.citationJournalNumber}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.citationJournalNumber = newValue ?? ""})
    }
  }
  public var structureCitationDOI: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.citationDOI}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.citationDOI = newValue ?? ""})
    }
  }
  public var structureCitationPublicationDate: Date?
  {
    get
    {
      let set: Set<Date> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.citationPublicationDate}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.citationPublicationDate = newValue ?? Date()})
    }
  }
  public var structureCitationDatebaseCodes: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({($0.object as? InfoEditor)?.citationDatebaseCodes}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? InfoEditor)?.citationDatebaseCodes = newValue ?? ""})
    }
  }
}
