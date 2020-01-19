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
import iRASPAKit

class StructureInfoDetailViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextViewDelegate, WindowControllerConsumer, ProjectConsumer
{
  weak var windowController: iRASPAWindowController?
  
  @IBOutlet private weak var infoOutlineView: NSStaticViewBasedOutlineView?
  
  var list: [NSDictionary] = []
  var heights: [String : CGFloat] = [:]
  let creatorCell: [NSString : AnyObject] = [NSString(string: "cellType") : NSString(string: "CreatorCell")]
  let creationCell: [NSString : AnyObject] = [NSString(string: "cellType") : NSString(string: "CreationCell")]
  let chemicalCell: [NSString : AnyObject] = [NSString(string: "cellType") : NSString(string: "ChemicalCell")]
  let publicationCell: [NSString : AnyObject] = [NSString(string: "cellType"):NSString(string: "PublicationCell")]
  
  deinit
  {
    //Swift.print("deinit: StructureInfoDetailViewController")
  }
  
  // MARK: protocol ProjectConsumer
  // =====================================================================
  
  weak var proxyProject: ProjectTreeNode? = nil
  
  // ViewDidLoad: bounds are not yet set (do not do geometry-related etup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    // check that it works with strong-references off (for compatibility with 'El Capitan')
    if #available(OSX 10.12, *)
    {
      self.infoOutlineView?.stronglyReferencesItems = false
    }
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    let creatorDictionary: NSDictionary = [NSString(string: "cellType"):NSString(string: "CreatorGroup") as AnyObject,NSString(string: "children"): [creatorCell] as AnyObject]
    let creationDictionary: NSDictionary = [NSString(string: "cellType"):NSString(string: "CreationGroup") as AnyObject,NSString(string: "children"): [creationCell] as AnyObject]
    let chemicalDictionary: NSDictionary = [NSString(string: "cellType"):NSString(string: "ChemicalGroup") as AnyObject,NSString(string: "children"): [chemicalCell] as AnyObject]
    let publicationDictionary: NSDictionary = [NSString(string: "cellType"):NSString(string: "PublicationGroup") as AnyObject,NSString(string: "children"): [publicationCell] as AnyObject]
    
    self.list = [creatorDictionary, creationDictionary, chemicalDictionary, publicationDictionary]
    
    self.heights =
    [
      "CreatorGroup" : 17.0,
      "CreatorCell" : 285.0,
      "CreationGroup" : 17.0,
      "CreationCell" : 525.0,
      "ChemicalGroup" : 17.0,
      "ChemicalCell" : 92.0,
      "PublicationGroup": 17.0,
      "PublicationCell" : 344.0
    ]
  }
  
  var expandedItems: [Bool] = [false,false, false,false,false,false,false,false]
  
  func storeExpandedItems()
  {
    if let outlineView = self.infoOutlineView
    {
      for i in 0..<list.count
      {
        self.expandedItems[i] = outlineView.isItemExpanded(list[i])
      }
    }
  }

  func reloadData()
  {
    assert(Thread.isMainThread)
    
    self.infoOutlineView?.reloadData()
    
    NSAnimationContext.runAnimationGroup({context in
      context.duration = 0
      
      for i in 0..<self.list.count
      {
        if (self.expandedItems[i])
        {
          self.infoOutlineView?.expandItem(list[i])
        }
        else
        {
          self.infoOutlineView?.collapseItem(list[i])
        }
      }
    }, completionHandler: {})
  }

  
  // MARK: NSTableView Delegate Methods
  // =====================================================================
  
  // Returns a Boolean value that indicates whether the a given item is expandable
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool
  {
    if let dictionary = item as? NSDictionary
    {
      if let _: [AnyObject] = dictionary["children"] as? [AnyObject]
      {
        return true
      }
      else
      {
        return false
      }
    }
    return false
  }
  
  func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool
  {
    return true
  }
  
  func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool
  {
    return false
  }
  
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int
  {
    if (item == nil)
    {
      return list.count
    }
    else
    {
      if let dictionary = item as? NSDictionary
      {
        let children: [AnyObject] = dictionary["children"] as! [AnyObject]
        return children.count
      }
      else // no children more than 1 deep
      {
        return 0
      }
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any
  {
    //item is nil for root level items
    if (item == nil)
    {
      // return an Dictionary<String, AnyObject>
      return self.list[index]
    }
    else
    {
      let dictionary: NSDictionary = item as! NSDictionary
      
      let children: [AnyObject] = dictionary["children"] as! [AnyObject]
      
      return children[index]
    }
  }
  
  
  func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat
  {
    if let string: String = (item as? NSDictionary)?["cellType"] as? String
    {
      return self.heights[string] ?? 200.0
    }
    return 200.0
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
  
  @objc func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
  {
    if let string: String = (item as? NSDictionary)?["cellType"] as? String,
      let view: NSTableCellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: string), owner: self) as? NSTableCellView
    {
      let enabled: Bool = proxyProject?.isEnabled ?? false
      
      switch(string)
      {
      case "CreatorGroup":
        return view
      case "CreatorCell":
        if let textFieldAuthorFirstName: NSTextField = view.viewWithTag(1) as? NSTextField
        {
          textFieldAuthorFirstName.isEditable = false
          textFieldAuthorFirstName.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldAuthorFirstName.isEditable = enabled
            if let authorFirstName: String = representedStructure.structureAuthorFirstName
            {
              textFieldAuthorFirstName.stringValue = authorFirstName
            }
            else
            {
              textFieldAuthorFirstName.stringValue = "Multiple Values"
            }
          }
        }
        if let textFieldAuthorMiddleName: NSTextField = view.viewWithTag(2) as? NSTextField
        {
          textFieldAuthorMiddleName.isEditable = false
          textFieldAuthorMiddleName.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldAuthorMiddleName.isEditable = enabled
            if let authorMiddleName: String = representedStructure.structureAuthorMiddleName
            {
              textFieldAuthorMiddleName.stringValue = authorMiddleName
            }
            else
            {
              textFieldAuthorMiddleName.stringValue = "Multiple Values"
            }
          }
        }
        if let textFieldAuthorLastName: NSTextField = view.viewWithTag(3) as? NSTextField
        {
          textFieldAuthorLastName.isEditable = false
          textFieldAuthorLastName.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldAuthorLastName.isEditable = enabled
            if let authorFirstName: String = representedStructure.structureAuthorLastName
            {
              textFieldAuthorLastName.stringValue = authorFirstName
            }
            else
            {
              textFieldAuthorLastName.stringValue = "Multiple Values"
            }
          }
        }
        if let textFieldOrchidID: NSTextField = view.viewWithTag(4) as? NSTextField
        {
          textFieldOrchidID.isEditable = false
          textFieldOrchidID.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldOrchidID.isEditable = enabled
            if let authorOrchidID: String = representedStructure.structureAuthorOrchidID
            {
              textFieldOrchidID.stringValue = authorOrchidID
            }
            else
            {
              textFieldOrchidID.stringValue = "Multiple Values"
            }
          }
        }
        if let textFieldResearcherID: NSTextField = view.viewWithTag(5) as? NSTextField
        {
          textFieldResearcherID.isEditable = false
          textFieldResearcherID.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldResearcherID.isEditable = enabled
            if let authorResearcherID: String = representedStructure.structureAuthorResearcherID
            {
              textFieldResearcherID.stringValue = authorResearcherID
            }
            else
            {
              textFieldResearcherID.stringValue = "Multiple Values"
            }
          }
        }
        if let textFieldAffiliationUniversityName: NSTextField = view.viewWithTag(6) as? NSTextField
        {
          textFieldAffiliationUniversityName.isEditable = false
          textFieldAffiliationUniversityName.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldAffiliationUniversityName.isEditable = enabled
            if let authorAffiliationUniversityName: String = representedStructure.structureAuthorAffiliationUniversityName
            {
              textFieldAffiliationUniversityName.stringValue = authorAffiliationUniversityName
            }
            else
            {
              textFieldAffiliationUniversityName.stringValue = "Multiple Values"
            }
          }
        }
        if let textFieldAffiliationFacultyName: NSTextField = view.viewWithTag(7) as? NSTextField
        {
          textFieldAffiliationFacultyName.isEditable = false
          textFieldAffiliationFacultyName.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldAffiliationFacultyName.isEditable = enabled
            if let authorAffiliationFacultyName: String = representedStructure.structureAuthorAffiliationFacultyName
            {
              textFieldAffiliationFacultyName.stringValue = authorAffiliationFacultyName
            }
            else
            {
              textFieldAffiliationFacultyName.stringValue = "Multiple Values"
            }
          }
        }
        if let textFieldAffiliationInstituteName: NSTextField = view.viewWithTag(8) as? NSTextField
        {
          textFieldAffiliationInstituteName.isEditable = false
          textFieldAffiliationInstituteName.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldAffiliationInstituteName.isEditable = enabled
            if let authorAffiliationInstituteName: String = representedStructure.structureAuthorAffiliationInstituteName
            {
              textFieldAffiliationInstituteName.stringValue = authorAffiliationInstituteName
            }
            else
            {
              textFieldAffiliationInstituteName.stringValue = "Multiple Values"
            }
          }
        }
        if let textFieldAffiliationCityName: NSTextField = view.viewWithTag(9) as? NSTextField
        {
          textFieldAffiliationCityName.isEditable = false
          textFieldAffiliationCityName.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldAffiliationCityName.isEditable = enabled
            if let authorAffiliationCityName: String = representedStructure.structureAuthorAffiliationCityName
            {
              textFieldAffiliationCityName.stringValue = authorAffiliationCityName
            }
            else
            {
              textFieldAffiliationCityName.stringValue = "Multiple Values"
            }
          }
        }
        if let countries: iRASPAPopUpButton = view.viewWithTag(10) as? iRASPAPopUpButton
        {
          countries.removeAllItems()
          let locale: Locale = NSLocale.current
          let sortedCountries = Locale.isoRegionCodes.map { locale.localizedString(forRegionCode: $0)! }.sorted()
          countries.addItems(withTitles: sortedCountries)
          
          countries.isEditable = false
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            countries.isEditable = enabled
            if let country: String = representedStructure.structureAuthorAffiliationCountryName
            {
              countries.removeItem(withTitle: "Multiple Values")
              countries.selectItem(withTitle: country)
            }
            else
            {
              countries.stringValue = "Multiple Values"
            }
          }
          else
          {
            countries.selectItem(withTitle: Locale.current.localizedString(forRegionCode: Locale.current.regionCode ?? "NL") ?? "Netherlands")
          }
        }
        return view
      case "CreationGroup":
        return view
      case "CreationCell":
        if let datePickerCreationDate: NSDatePicker = view.viewWithTag(1) as? NSDatePicker
        {
          datePickerCreationDate.isEnabled = false
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            datePickerCreationDate.isEnabled = enabled
            if let date: Date = representedStructure.structureCreationDate
            {
              datePickerCreationDate.dateValue = date
            }
            else
            {
              datePickerCreationDate.stringValue = "Multiple Values"
            }
          }
        }
        if let textFieldCreationTemperature: NSTextField = view.viewWithTag(2) as? NSTextField
        {
          textFieldCreationTemperature.isEditable = false
          textFieldCreationTemperature.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldCreationTemperature.isEditable = enabled
            
            if let value: String = representedStructure.structureCreationTemperature
            {
              textFieldCreationTemperature.stringValue = value
            }
            else
            {
              textFieldCreationTemperature.stringValue = "Multiple Values"
            }
          }
        }
        if let popupButtonCreationTemperatureScale: iRASPAPopUpButton = view.viewWithTag(3) as? iRASPAPopUpButton
        {
          popupButtonCreationTemperatureScale.isEditable = false
          popupButtonCreationTemperatureScale.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            popupButtonCreationTemperatureScale.isEditable = enabled
            
            if let rawValue: Int = representedStructure.structureCreationTemperatureScale?.rawValue
            {
              popupButtonCreationTemperatureScale.removeItem(withTitle: "Multiple Values")
              popupButtonCreationTemperatureScale.selectItem(at: rawValue)
            }
            else
            {
              popupButtonCreationTemperatureScale.stringValue = "Multiple Values"
            }
          }
        }
        if let TextFieldCreationPressure: NSTextField = view.viewWithTag(4) as? NSTextField
        {
          TextFieldCreationPressure.isEditable = false
          TextFieldCreationPressure.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            TextFieldCreationPressure.isEditable = enabled
            
            if let value: String = representedStructure.structureCreationPressure
            {
              TextFieldCreationPressure.stringValue = value
            }
            else
            {
              TextFieldCreationPressure.stringValue = "Multiple Values"
            }
          }
        }
        if let popupButtonCreationPressureScale: iRASPAPopUpButton = view.viewWithTag(5) as? iRASPAPopUpButton
        {
          popupButtonCreationPressureScale.isEditable = false
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            popupButtonCreationPressureScale.isEditable = enabled
            
            if let rawValue: Int = representedStructure.structureCreationPressureScale?.rawValue
            {
              popupButtonCreationPressureScale.removeItem(withTitle: "Multiple Values")
              popupButtonCreationPressureScale.selectItem(at: rawValue)
            }
            else
            {
              popupButtonCreationPressureScale.stringValue = "Multiple Values"
            }
          }
        }
        if let popUpbuttonCreationMethod: iRASPAPopUpButton = view.viewWithTag(6) as? iRASPAPopUpButton
        {
          popUpbuttonCreationMethod.isEditable = false
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            popUpbuttonCreationMethod.isEditable = enabled
            
            if let rawValue = representedStructure.structureCreationMethod?.rawValue
            {
              popUpbuttonCreationMethod.removeItem(withTitle: "Multiple Values")
              popUpbuttonCreationMethod.selectItem(at: rawValue)
            }
            else
            {
              popUpbuttonCreationMethod.setTitle("Multiple Values")
            }
          }
        }
        
        
        
        if let tabView: NSTabView = getSubviewsOfView(view).filter({$0.identifier?.rawValue == "creationTabView"}).first as? NSTabView
        {
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer],
             let structureCreationMethod = representedStructure.structureCreationMethod
          {
            switch(structureCreationMethod)
            {
            case Structure.CreationMethod.unknown, Structure.CreationMethod.simulation:
              tabView.selectTabViewItem(at: 0)
              if let popUpCreationUnitCellRelaxationMethod: iRASPAPopUpButton = view.viewWithTag(10) as? iRASPAPopUpButton
              {
                popUpCreationUnitCellRelaxationMethod.isEditable = false
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  popUpCreationUnitCellRelaxationMethod.isEditable = enabled
                  
                  if let index: Int = representedStructure.structureCreationUnitCellRelaxationMethod?.rawValue
                  {
                    popUpCreationUnitCellRelaxationMethod.removeItem(withTitle: "Multiple Values")
                    popUpCreationUnitCellRelaxationMethod.selectItem(at: index)
                  }
                  else
                  {
                    popUpCreationUnitCellRelaxationMethod.stringValue = "Multiple Values"
                  }
                }
              }
              if let comboBoxCreationSoftwarePackageAtomicPositions: iRASPAComboBox = view.viewWithTag(11) as? iRASPAComboBox
              {
                comboBoxCreationSoftwarePackageAtomicPositions.isEditable = false
                comboBoxCreationSoftwarePackageAtomicPositions.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  comboBoxCreationSoftwarePackageAtomicPositions.isEditable = enabled
                  
                  if let value: String = representedStructure.structureCreationAtomicPositionsSoftwarePackage
                  {
                    if comboBoxCreationSoftwarePackageAtomicPositions.indexOfItem(withObjectValue: value) == NSNotFound
                    {
                      comboBoxCreationSoftwarePackageAtomicPositions.insertItem(withObjectValue: value, at: 0)
                    }
                    comboBoxCreationSoftwarePackageAtomicPositions.selectItem(withObjectValue: value)
                  }
                  else
                  {
                    comboBoxCreationSoftwarePackageAtomicPositions.stringValue = "Multiple Values"
                  }
                }
              }
              if let textFieldCreationIonsRelaxationAlgorithm: iRASPAPopUpButton = view.viewWithTag(12) as? iRASPAPopUpButton
              {
                textFieldCreationIonsRelaxationAlgorithm.isEditable = false
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textFieldCreationIonsRelaxationAlgorithm.isEditable = enabled
                  
                  if let index: Int = representedStructure.structureCreationAtomicPositionsIonsRelaxationAlgorithm?.rawValue
                  {
                    textFieldCreationIonsRelaxationAlgorithm.removeItem(withTitle: "Multiple Values")
                    textFieldCreationIonsRelaxationAlgorithm.selectItem(at: index)
                  }
                  else
                  {
                    textFieldCreationIonsRelaxationAlgorithm.stringValue = "Multiple Values"
                  }
                }
              }
              if let textFieldCreationIonsRelaxationCheck: iRASPAPopUpButton = view.viewWithTag(13) as? iRASPAPopUpButton
              {
                textFieldCreationIonsRelaxationCheck.isEditable = false
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textFieldCreationIonsRelaxationCheck.isEditable = enabled
                  
                  if let index: Int = representedStructure.structureCreationAtomicPositionsIonsRelaxationCheck?.rawValue
                  {
                    textFieldCreationIonsRelaxationCheck.removeItem(withTitle: "Multiple Values")
                    textFieldCreationIonsRelaxationCheck.selectItem(at: index)
                  }
                  else
                  {
                    textFieldCreationIonsRelaxationCheck.stringValue = "Multiple Values"
                  }
                }
              }
              if let textFieldCreationAtomicPositionsForceField: iRASPAComboBox = view.viewWithTag(14) as? iRASPAComboBox
              {
                textFieldCreationAtomicPositionsForceField.isEditable = false
                textFieldCreationAtomicPositionsForceField.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textFieldCreationAtomicPositionsForceField.isEditable = enabled
                  
                  if let value: String = representedStructure.structureCreationAtomicPositionsForcefield
                  {
                    if textFieldCreationAtomicPositionsForceField.indexOfItem(withObjectValue: value) == NSNotFound
                    {
                      textFieldCreationAtomicPositionsForceField.insertItem(withObjectValue: value, at: 0)
                    }
                    textFieldCreationAtomicPositionsForceField.selectItem(withObjectValue: value)
                  }
                  else
                  {
                    textFieldCreationAtomicPositionsForceField.stringValue = "Multiple Values"
                  }
                }
              }
              if let comboBoxCreationAtomicPositionsForceFieldDetails: iRASPAComboBox = view.viewWithTag(15) as? iRASPAComboBox
              {
                comboBoxCreationAtomicPositionsForceFieldDetails.isEditable = false
                comboBoxCreationAtomicPositionsForceFieldDetails.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  comboBoxCreationAtomicPositionsForceFieldDetails.isEditable = enabled
                  
                  if let value: String = representedStructure.structureCreationAtomicPositionsForcefieldDetails
                  {
                    if comboBoxCreationAtomicPositionsForceFieldDetails.indexOfItem(withObjectValue: value) == NSNotFound
                    {
                      comboBoxCreationAtomicPositionsForceFieldDetails.insertItem(withObjectValue: value, at: 0)
                    }
                    comboBoxCreationAtomicPositionsForceFieldDetails.selectItem(withObjectValue: value)
                  }
                  else
                  {
                    comboBoxCreationAtomicPositionsForceFieldDetails.stringValue = "Multiple Values"
                  }
                }
              }
              if let comboBoxCreationSoftwarePackageAtomicCharges: iRASPAComboBox = view.viewWithTag(16) as? iRASPAComboBox
              {
                comboBoxCreationSoftwarePackageAtomicCharges.isEditable = false
                comboBoxCreationSoftwarePackageAtomicCharges.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  comboBoxCreationSoftwarePackageAtomicCharges.isEditable = enabled
                  
                  if let value: String = representedStructure.structureCreationAtomicChargesSoftwarePackage
                  {
                    if comboBoxCreationSoftwarePackageAtomicCharges.indexOfItem(withObjectValue: value) == NSNotFound
                    {
                      comboBoxCreationSoftwarePackageAtomicCharges.insertItem(withObjectValue: value, at: 0)
                    }
                    comboBoxCreationSoftwarePackageAtomicCharges.selectItem(withObjectValue: value)
                  }
                  else
                  {
                    comboBoxCreationSoftwarePackageAtomicCharges.stringValue = "Multiple Values"
                  }
                }
              }
              if let comboBoxCreationAtomicChargesAlgorithms: iRASPAComboBox = view.viewWithTag(17) as? iRASPAComboBox
              {
                comboBoxCreationAtomicChargesAlgorithms.isEditable = false
                comboBoxCreationAtomicChargesAlgorithms.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  comboBoxCreationAtomicChargesAlgorithms.isEditable = enabled
                  
                  if let value: String = representedStructure.structureCreationAtomicChargesAlgorithms
                  {
                    if comboBoxCreationAtomicChargesAlgorithms.indexOfItem(withObjectValue: value) == NSNotFound
                    {
                      comboBoxCreationAtomicChargesAlgorithms.insertItem(withObjectValue: value, at: 0)
                    }
                    comboBoxCreationAtomicChargesAlgorithms.selectItem(withObjectValue: value)
                  }
                  else
                  {
                    comboBoxCreationAtomicChargesAlgorithms.stringValue = "Multiple Values"
                  }
                }
              }
              if let comboBoxCreationAtomicChargesForcefield: iRASPAComboBox = view.viewWithTag(18) as? iRASPAComboBox
              {
                comboBoxCreationAtomicChargesForcefield.isEditable = false
                comboBoxCreationAtomicChargesForcefield.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  comboBoxCreationAtomicChargesForcefield.isEditable = enabled
                  
                  if let value: String = representedStructure.structureCreationAtomicChargesForcefield
                  {
                    if comboBoxCreationAtomicChargesForcefield.indexOfItem(withObjectValue: value) == NSNotFound
                    {
                      comboBoxCreationAtomicChargesForcefield.insertItem(withObjectValue: value, at: 0)
                    }
                    comboBoxCreationAtomicChargesForcefield.selectItem(withObjectValue: value)
                  }
                  else
                  {
                    comboBoxCreationAtomicChargesForcefield.stringValue = "Multiple Values"
                  }
                }
              }
              if let comboBoxCreationAtomicChargesForcefieldDetails: iRASPAComboBox = view.viewWithTag(19) as? iRASPAComboBox
              {
                comboBoxCreationAtomicChargesForcefieldDetails.isEditable = false
                comboBoxCreationAtomicChargesForcefieldDetails.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  comboBoxCreationAtomicChargesForcefieldDetails.isEditable = enabled
                  
                  if let value: String = representedStructure.structureCreationAtomicChargesForcefieldDetails
                  {
                    if comboBoxCreationAtomicChargesForcefieldDetails.indexOfItem(withObjectValue: value) == NSNotFound
                    {
                      comboBoxCreationAtomicChargesForcefieldDetails.insertItem(withObjectValue: value, at: 0)
                    }
                    comboBoxCreationAtomicChargesForcefieldDetails.selectItem(withObjectValue: value)
                  }
                  else
                  {
                    comboBoxCreationAtomicChargesForcefieldDetails.stringValue = "Multiple Values"
                  }
                }
              }
            case Structure.CreationMethod.experimental:
              tabView.selectTabViewItem(at: 1)
              if let textFieldMeasurementRadiation: NSTextField = view.viewWithTag(30) as? NSTextField
              {
                textFieldMeasurementRadiation.isEditable = false
                textFieldMeasurementRadiation.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textFieldMeasurementRadiation.isEditable = enabled
                  
                  if let value: String = representedStructure.structureExperimentalMeasurementRadiation
                  {
                    textFieldMeasurementRadiation.stringValue = value
                  }
                  else
                  {
                    textFieldMeasurementRadiation.stringValue = "Multiple Values"
                  }
                }
              }
              if let textFieldMeasurementWaveLength: NSTextField = view.viewWithTag(31) as? NSTextField
              {
                textFieldMeasurementWaveLength.isEditable = false
                textFieldMeasurementWaveLength.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textFieldMeasurementWaveLength.isEditable = enabled
                  
                  if let value: String = representedStructure.structureExperimentalMeasurementWaveLength
                  {
                    textFieldMeasurementWaveLength.stringValue = value
                  }
                  else
                  {
                    textFieldMeasurementWaveLength.stringValue = "Multiple Values"
                  }
                }
              }
              if let textFieldMeasurementThetaMin: NSTextField = view.viewWithTag(32) as? NSTextField
              {
                textFieldMeasurementThetaMin.isEditable = false
                textFieldMeasurementThetaMin.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textFieldMeasurementThetaMin.isEditable = enabled
                  
                  if let value: String = representedStructure.structureExperimentalMeasurementThetaMin
                  {
                    textFieldMeasurementThetaMin.stringValue = value
                  }
                  else
                  {
                    textFieldMeasurementThetaMin.stringValue = "Multiple Values"
                  }
                }
              }
              if let textFieldMeasurementThetaMax: NSTextField = view.viewWithTag(33) as? NSTextField
              {
                textFieldMeasurementThetaMax.isEditable = false
                textFieldMeasurementThetaMax.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textFieldMeasurementThetaMax.isEditable = enabled
                  
                  if let value: String = representedStructure.structureExperimentalMeasurementThetaMax
                  {
                    textFieldMeasurementThetaMax.stringValue = value
                  }
                  else
                  {
                    textFieldMeasurementThetaMax.stringValue = "Multiple Values"
                  }
                }
              }
              if let textFieldMeasurementIndexLimitsHmin: NSTextField = view.viewWithTag(34) as? NSTextField
              {
                textFieldMeasurementIndexLimitsHmin.isEditable = false
                textFieldMeasurementIndexLimitsHmin.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textFieldMeasurementIndexLimitsHmin.isEditable = enabled
                  
                  if let value: String = representedStructure.structureExperimentalMeasurementIndexLimitsHmin
                  {
                    textFieldMeasurementIndexLimitsHmin.stringValue = value
                  }
                  else
                  {
                    textFieldMeasurementIndexLimitsHmin.stringValue = "Multiple Values"
                  }
                }
              }
              if let textFieldMeasurementIndexLimitsHmax: NSTextField = view.viewWithTag(35) as? NSTextField
              {
                textFieldMeasurementIndexLimitsHmax.isEditable = false
                textFieldMeasurementIndexLimitsHmax.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textFieldMeasurementIndexLimitsHmax.isEditable = enabled
                  
                  if let value: String = representedStructure.structureExperimentalMeasurementIndexLimitsHmax
                  {
                    textFieldMeasurementIndexLimitsHmax.stringValue = value
                  }
                  else
                  {
                    textFieldMeasurementIndexLimitsHmax.stringValue = "Multiple Values"
                  }
                }
              }
              if let textFieldMeasurementIndexLimitsKmin: NSTextField = view.viewWithTag(36) as? NSTextField
              {
                textFieldMeasurementIndexLimitsKmin.isEditable = false
                textFieldMeasurementIndexLimitsKmin.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textFieldMeasurementIndexLimitsKmin.isEditable = enabled
                  
                  if let value: String = representedStructure.structureExperimentalMeasurementIndexLimitsKmin
                  {
                    textFieldMeasurementIndexLimitsKmin.stringValue = value
                  }
                  else
                  {
                    textFieldMeasurementIndexLimitsKmin.stringValue = "Multiple Values"
                  }
                }
              }
              if let textFieldMeasurementIndexLimitsKmax: NSTextField = view.viewWithTag(37) as? NSTextField
              {
                textFieldMeasurementIndexLimitsKmax.isEditable = false
                textFieldMeasurementIndexLimitsKmax.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textFieldMeasurementIndexLimitsKmax.isEditable = enabled
                  
                  if let value: String = representedStructure.structureExperimentalMeasurementIndexLimitsKmax
                  {
                    textFieldMeasurementIndexLimitsKmax.stringValue = value
                  }
                  else
                  {
                    textFieldMeasurementIndexLimitsKmax.stringValue = "Multiple Values"
                  }
                }
              }
              if let textFieldMeasurementIndexLimitsLmin: NSTextField = view.viewWithTag(38) as? NSTextField
              {
                textFieldMeasurementIndexLimitsLmin.isEditable = false
                textFieldMeasurementIndexLimitsLmin.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textFieldMeasurementIndexLimitsLmin.isEditable = enabled
                  
                  if let value: String = representedStructure.structureExperimentalMeasurementIndexLimitsLmin
                  {
                    textFieldMeasurementIndexLimitsLmin.stringValue = value
                  }
                  else
                  {
                    textFieldMeasurementIndexLimitsLmin.stringValue = "Multiple Values"
                  }
                }
              }
              if let textFieldMeasurementIndexLimitsLmax: NSTextField = view.viewWithTag(39) as? NSTextField
              {
                textFieldMeasurementIndexLimitsLmax.isEditable = false
                textFieldMeasurementIndexLimitsLmax.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textFieldMeasurementIndexLimitsLmax.isEditable = enabled
                  
                  if let value: String = representedStructure.structureExperimentalMeasurementIndexLimitsLmax
                  {
                    textFieldMeasurementIndexLimitsLmax.stringValue = value
                  }
                  else
                  {
                    textFieldMeasurementIndexLimitsLmax.stringValue = "Multiple Values"
                  }
                }
              }
              if let textFieldMeasurementNumberOfSymmetryIndependentReflections: NSTextField = view.viewWithTag(40) as? NSTextField
              {
                textFieldMeasurementNumberOfSymmetryIndependentReflections.isEditable = false
                textFieldMeasurementNumberOfSymmetryIndependentReflections.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textFieldMeasurementNumberOfSymmetryIndependentReflections.isEditable = enabled
                  
                  if let value: String = representedStructure.structureExperimentalMeasurementNumberOfSymmetryIndependentReflections
                  {
                    textFieldMeasurementNumberOfSymmetryIndependentReflections.stringValue = value
                  }
                  else
                  {
                    textFieldMeasurementNumberOfSymmetryIndependentReflections.stringValue = "Multiple Values"
                  }
                }
              }
              if let textFieldMeasurementSoftware: NSTextField = view.viewWithTag(41) as? NSTextField
              {
                textFieldMeasurementSoftware.isEditable = false
                textFieldMeasurementSoftware.stringValue = ""
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textFieldMeasurementSoftware.isEditable = enabled
                  
                  if let value: String = representedStructure.structureExperimentalMeasurementSoftware
                  {
                    textFieldMeasurementSoftware.stringValue = value
                  }
                  else
                  {
                    textFieldMeasurementSoftware.stringValue = "Multiple Values"
                  }
                }
              }
              tabView.selectTabViewItem(at: 1)
              
              if let textViewRefinementDetails: NSTextView = getSubviewsOfView(view).filter({$0.identifier?.rawValue == "ExperimentalRefinementDetails"}).first as? NSTextView
              {
                textViewRefinementDetails.isEditable = false
                textViewRefinementDetails.typingAttributes = [.foregroundColor : NSColor.textColor]
                textViewRefinementDetails.textStorage?.setAttributedString(NSAttributedString(string: "",  attributes: [.foregroundColor : NSColor.textColor]))
                if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
                {
                  textViewRefinementDetails.isEditable = enabled
                  
                  if let value: String = representedStructure.structureExperimentalMeasurementRefinementDetails
                  {
                    textViewRefinementDetails.textStorage?.setAttributedString(NSAttributedString(string: value))
                  }
                  else
                  {
                    textViewRefinementDetails.textStorage?.setAttributedString(NSAttributedString(string: "Multiple Values"))
                  }
                }

              }
            }
          }
          if let textFieldMeasurementGoodnessOfFit: NSTextField = view.viewWithTag(43) as? NSTextField
          {
            textFieldMeasurementGoodnessOfFit.isEditable = false
            textFieldMeasurementGoodnessOfFit.stringValue = ""
            if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
            {
              textFieldMeasurementGoodnessOfFit.isEditable = enabled
              
              if let value: String = representedStructure.structureExperimentalMeasurementGoodnessOfFit
              {
                textFieldMeasurementGoodnessOfFit.stringValue = value
              }
              else
              {
                textFieldMeasurementGoodnessOfFit.stringValue = "Multiple Values"
              }
            }
          }
          if let textFieldMeasurementRFactorGt: NSTextField = view.viewWithTag(44) as? NSTextField
          {
            textFieldMeasurementRFactorGt.isEditable = false
            textFieldMeasurementRFactorGt.stringValue = ""
            if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
            {
              textFieldMeasurementRFactorGt.isEditable = enabled
              
              if let value: String = representedStructure.structureExperimentalMeasurementRFactorGt
              {
                textFieldMeasurementRFactorGt.stringValue = value
              }
              else
              {
                textFieldMeasurementRFactorGt.stringValue = "Multiple Values"
              }
            }
          }
          if let textFieldMeasurementRFactorAll: NSTextField = view.viewWithTag(45) as? NSTextField
          {
            textFieldMeasurementRFactorAll.isEditable = false
            textFieldMeasurementRFactorAll.stringValue = ""
            if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
            {
              textFieldMeasurementRFactorAll.isEditable = enabled
              
              if let value: String = representedStructure.structureExperimentalMeasurementRFactorAll
              {
                textFieldMeasurementRFactorAll.stringValue = value
              }
              else
              {
                textFieldMeasurementRFactorAll.stringValue = "Multiple Values"
              }
            }
          }
        }
        return view
      case "ChemicalGroup":
        return view
      case "ChemicalCell":
        if let textFieldChemicalFormulaMoiety: NSTextField = view.viewWithTag(50) as? NSTextField
        {
          textFieldChemicalFormulaMoiety.isEditable = false
          textFieldChemicalFormulaMoiety.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldChemicalFormulaMoiety.isEditable = enabled
            
            if let value: String = representedStructure.structureChemicalFormulaMoiety
            {
              textFieldChemicalFormulaMoiety.stringValue = value
            }
            else
            {
              textFieldChemicalFormulaMoiety.stringValue = "Multiple Values"
            }
          }
        }
        if let textFieldChemicalFormulaSum: NSTextField = view.viewWithTag(51) as? NSTextField
        {
          textFieldChemicalFormulaSum.isEditable = false
          textFieldChemicalFormulaSum.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldChemicalFormulaSum.isEditable = enabled
            
            if let value: String = representedStructure.structureChemicalFormulaSum
            {
              textFieldChemicalFormulaSum.stringValue = value
            }
            else
            {
              textFieldChemicalFormulaSum.stringValue = "Multiple Values"
            }
          }
        }
        if let textFieldChemicalNameSystematic: NSTextField = view.viewWithTag(52) as? NSTextField
        {
          textFieldChemicalNameSystematic.isEditable = false
          textFieldChemicalNameSystematic.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldChemicalNameSystematic.isEditable = enabled
            
            if let value: String = representedStructure.structureChemicalNameSystematic
            {
              textFieldChemicalNameSystematic.stringValue = value
            }
            else
            {
              textFieldChemicalNameSystematic.stringValue = "Multiple Values"
            }
          }
        }
        return view
      case "PublicationGroup":
        return view
      case "PublicationCell":
        if let textViewCitationArticleTitle: NSTextView = getSubviewsOfView(view).filter({$0.identifier?.rawValue == "citationArticleTitle"}).first as? NSTextView
        {
          textViewCitationArticleTitle.isEditable = false
          textViewCitationArticleTitle.typingAttributes = [.foregroundColor : NSColor.textColor]
          textViewCitationArticleTitle.textStorage?.setAttributedString(NSAttributedString(string: "", attributes: [.foregroundColor : NSColor.textColor]))
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textViewCitationArticleTitle.isEditable = enabled
            
            if let value: String = representedStructure.structureCitationArticleTitle
            {
              textViewCitationArticleTitle.textStorage?.setAttributedString(NSAttributedString(string: value,  attributes: [.foregroundColor : NSColor.textColor]))
            }
            else
            {
              textViewCitationArticleTitle.textStorage?.setAttributedString(NSAttributedString(string: "Multiple Values"))
            }
          }
          
        }
        
        if let textFieldCitationJournalTitle: iRASPAComboBox = view.viewWithTag(61) as? iRASPAComboBox
        {
          textFieldCitationJournalTitle.isEditable = false
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldCitationJournalTitle.isEditable = enabled
            
            if let value: String = representedStructure.structureCitationJournalTitle
            {
              if textFieldCitationJournalTitle.indexOfItem(withObjectValue: value) == NSNotFound
              {
                textFieldCitationJournalTitle.insertItem(withObjectValue: value, at: 0)
              }
              textFieldCitationJournalTitle.selectItem(withObjectValue: value)
            }
            else
            {
              textFieldCitationJournalTitle.stringValue = "Multiple Values"
            }
          }
        }
        
        if let textViewCitationArticleAuthors: NSTextView = getSubviewsOfView(view).filter({$0.identifier?.rawValue == "citationArticleAuthors"}).first as? NSTextView
        {
          textViewCitationArticleAuthors.isEditable = false
          textViewCitationArticleAuthors.typingAttributes = [.foregroundColor : NSColor.textColor]
          textViewCitationArticleAuthors.textStorage?.setAttributedString(NSAttributedString(string: "", attributes: [.foregroundColor : NSColor.textColor]))
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textViewCitationArticleAuthors.isEditable = enabled
            
            if let value: String = representedStructure.structureCitationAuthors
            {
              textViewCitationArticleAuthors.textStorage?.setAttributedString(NSAttributedString(string: value,  attributes: [.foregroundColor : NSColor.textColor]))
            }
            else
            {
              textViewCitationArticleAuthors.textStorage?.setAttributedString(NSAttributedString(string: "Multiple Values"))
            }
          }
          
        }
        
        if let textFieldCitationJournalVolume: NSTextField = view.viewWithTag(63) as? NSTextField
        {
          textFieldCitationJournalVolume.isEditable = false
          textFieldCitationJournalVolume.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldCitationJournalVolume.isEditable = enabled
            
            if let value: String = representedStructure.structureCitationJournalVolume
            {
              textFieldCitationJournalVolume.stringValue = value
            }
            else
            {
              textFieldCitationJournalVolume.stringValue = "Multiple Values"
            }
          }
        }
        
        if let textFieldCitationJournalNumber: NSTextField = view.viewWithTag(64) as? NSTextField
        {
          textFieldCitationJournalNumber.isEditable = false
          textFieldCitationJournalNumber.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldCitationJournalNumber.isEditable = enabled
            
            if let value: String = representedStructure.structureCitationJournalNumber
            {
              textFieldCitationJournalNumber.stringValue = value
            }
            else
            {
              textFieldCitationJournalNumber.stringValue = "Multiple Values"
            }
          }
        }
        
        if let datePickerCitationPublicationDate: NSDatePicker = view.viewWithTag(65) as? NSDatePicker
        {
          datePickerCitationPublicationDate.isEnabled = false
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            datePickerCitationPublicationDate.isEnabled = enabled
            if let date: Date = representedStructure.structureCitationPublicationDate
            {
              datePickerCitationPublicationDate.dateValue = date
            }
            else
            {
              datePickerCitationPublicationDate.stringValue = "Multiple Values"
            }
          }
        }
        
        if let textFieldCitationDOI: NSTextField = view.viewWithTag(66) as? NSTextField
        {
          textFieldCitationDOI.isEditable = false
          textFieldCitationDOI.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldCitationDOI.isEditable = enabled
            
            if let value: String = representedStructure.structureCitationDOI
            {
              textFieldCitationDOI.stringValue = value
            }
            else
            {
              textFieldCitationDOI.stringValue = "Multiple Values"
            }
          }
        }
        
        if let textFieldCitationDatebaseCodes: NSTextField = view.viewWithTag(67) as? NSTextField
        {
          textFieldCitationDatebaseCodes.isEditable = false
          textFieldCitationDatebaseCodes.stringValue = ""
          if let representedStructure: [InfoViewer] = representedObject as? [InfoViewer]
          {
            textFieldCitationDatebaseCodes.isEditable = enabled
            
            if let value: String = representedStructure.structureCitationDatebaseCodes
            {
              textFieldCitationDatebaseCodes.stringValue = value
            }
            else
            {
              textFieldCitationDatebaseCodes.stringValue = "Multiple Values"
            }
          }
        }
        return view
      default:
        break
      }
    }
    return nil
  }
  
  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView?
  {
    if let rowView: InfoTableRowView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "infoTableRowView"), owner: self) as? InfoTableRowView
    {
      return rowView
    }
    return nil
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
  
  func updateOutlineView(identifiers: [[NSString : AnyObject]])
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
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
       let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.structureAuthorFirstName = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorMiddleName(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
       let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.structureAuthorMiddleName = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorLastName(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.structureAuthorLastName = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorOrchidID(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.structureAuthorOrchidID = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorResearcherID(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.structureAuthorResearcherID = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorAffilitionUniversityName(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.structureAuthorAffiliationUniversityName = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorAffilitionFacultyName(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.structureAuthorAffiliationFacultyName = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorAffilitionInstituteName(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.structureAuthorAffiliationInstituteName = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorAffilitionCityName(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.structureAuthorAffiliationCityName = sender.stringValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changedAuthorAffilitionCountryName(_ sender: NSPopUpButton)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
       let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      if let countryName: String = sender.titleOfSelectedItem
      {
        self.windowController?.document?.updateChangeCount(.changeDone)
        ProjectTreeNode.representedObject.isEdited = true
        structure.structureAuthorAffiliationCountryName = countryName
        
        self.updateOutlineView(identifiers: [self.creatorCell])
      }
    }
  }

  @IBAction func changeCreationDate(_ sender: NSDatePicker)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationDate = sender.dateValue
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changeCreationTemperature(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationTemperature = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changeCreationTemperatureScale(_ sender: NSPopUpButton)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationTemperatureScale =  Structure.TemperatureScale(rawValue: sender.indexOfSelectedItem)
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changeCreationPressure(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationPressure = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  @IBAction func changeCreationPressureScale(_ sender: NSPopUpButton)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationPressureScale =  Structure.PressureScale(rawValue: sender.indexOfSelectedItem)
      
      self.updateOutlineView(identifiers: [self.creatorCell])
    }
  }
  
  
  // MARK: Editing routines for creation
  // =====================================================================

  
  @IBAction func changeCreationMethod(_ sender: NSPopUpButton)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationMethod = Structure.CreationMethod(rawValue: sender.indexOfSelectedItem)
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationUnitCellRelaxationMethod(_ sender: NSPopUpButton)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationUnitCellRelaxationMethod = Structure.UnitCellRelaxationMethod(rawValue: sender.indexOfSelectedItem)
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationSoftwarePackageAtomicPositions(_ sender: NSComboBox)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationAtomicPositionsSoftwarePackage = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationIonsRelaxationAlgorithm(_ sender: NSPopUpButton)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationAtomicPositionsIonsRelaxationAlgorithm = Structure.IonsRelaxationAlgorithm(rawValue: sender.indexOfSelectedItem)
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationIonsRelaxationCheck(_ sender: NSPopUpButton)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationAtomicPositionsIonsRelaxationCheck = Structure.IonsRelaxationCheck(rawValue: sender.indexOfSelectedItem)
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationAtomicPositionsForcefield(_ sender: NSComboBox)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationAtomicPositionsForcefield = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationAtomicPositionsForcefieldDetails(_ sender: NSComboBox)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationAtomicPositionsForcefieldDetails = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  
  @IBAction func changeCreationAtomicChargesSoftwarePackage(_ sender: NSComboBox)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationAtomicChargesSoftwarePackage = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationAtomicChargesAlgorithms(_ sender: NSComboBox)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationAtomicChargesAlgorithms = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationAtomicChargesForcefield(_ sender: NSComboBox)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationAtomicChargesForcefield = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeCreationAtomicChargesForcefieldDetail(_ sender: NSComboBox)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCreationAtomicChargesForcefieldDetails = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  
  @IBAction func changeMeasurementRadiation(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
       let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureExperimentalMeasurementRadiation = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementWaveLength(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureExperimentalMeasurementWaveLength = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementThetaMin(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureExperimentalMeasurementThetaMin = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementThetaMax(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureExperimentalMeasurementThetaMax = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementIndexLimitsHmin(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureExperimentalMeasurementIndexLimitsHmin = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementIndexLimitsHmax(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureExperimentalMeasurementIndexLimitsHmax = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementIndexLimitsKmin(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureExperimentalMeasurementIndexLimitsKmin = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementIndexLimitsKmax(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureExperimentalMeasurementIndexLimitsKmax = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementIndexLimitsLmin(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureExperimentalMeasurementIndexLimitsLmin = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementIndexLimitsLmax(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureExperimentalMeasurementIndexLimitsLmax = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementNumberOfSymmetryIndependentReflections(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureExperimentalMeasurementNumberOfSymmetryIndependentReflections = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementSoftware(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureExperimentalMeasurementSoftware = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }

  
  func textDidChange(_ notification: Notification)
  {
    guard let textView = notification.object as? NSTextView else { return }
    
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
       let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
       let identifier: String = textView.identifier?.rawValue
    {
      let textString: String = textView.string
      
      switch(identifier)
      {
      case "ExperimentalRefinementDetails":
        structure.structureExperimentalMeasurementRefinementDetails = textString
      case "citationArticleAuthors":
        structure.structureCitationAuthors = textString
      case "citationArticleTitle":
        structure.structureCitationArticleTitle = textString
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
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureExperimentalMeasurementGoodnessOfFit = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementRFactorGt(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureExperimentalMeasurementRFactorGt = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  @IBAction func changeMeasurementRFactorAll(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureExperimentalMeasurementRFactorAll = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.creationCell])
    }
  }
  
  // MARK: Editing routines for ChemicalCell
  // =====================================================================
  

  @IBAction func changeChemicalFormulaMoiety(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureChemicalFormulaMoiety = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.chemicalCell])
    }
  }
  
  @IBAction func changeChemicalFormulaSum(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureChemicalFormulaSum = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.chemicalCell])
    }
  }

  @IBAction func changeChemicalNameSystematic(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureChemicalNameSystematic = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.chemicalCell])
    }
  }
  
  
  // MARK: Editing routines for PublicationCell
  // =====================================================================

  @IBAction func changeCitationJournalTitle(_ sender: NSComboBox)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
      !sender.stringValue.isEmpty
    {
      self.windowController?.window?.makeFirstResponder(self.infoOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCitationJournalTitle = sender.stringValue
     
      self.updateOutlineView(identifiers: [self.publicationCell])
    }
  }
  
  @IBAction func changeCitationJournalVolume(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCitationJournalVolume = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.publicationCell])
    }
  }
  
  @IBAction func changeCitationJournalNumber(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCitationJournalNumber = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.publicationCell])
    }
  }
  
  @IBAction func changeCitationPublicationDate(_ sender: NSDatePicker)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCitationPublicationDate = sender.dateValue
      
      self.updateOutlineView(identifiers: [self.publicationCell])
    }
  }

  
  @IBAction func changeCitationDOI(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCitationDOI = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.publicationCell])
    }
  }
  
  @IBAction func changeCitationDatebaseCodes(_ sender: NSTextField)
  {
    if var structure: [InfoViewer] = self.representedObject as? [InfoViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.structureCitationDatebaseCodes = sender.stringValue
      
      self.updateOutlineView(identifiers: [self.publicationCell])
    }
  }

}
