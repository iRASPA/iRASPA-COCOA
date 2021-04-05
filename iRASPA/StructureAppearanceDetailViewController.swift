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
import RenderKit
import iRASPAKit
import MathKit
import SymmetryKit
import SimulationKit
import LogViewKit

// representedStructure is a object that confirms to:
// (1) AtomVisualAppearanceViewer
// (2) BondVisualAppearanceViewer
// (3) UnitCellVisualAppearanceViewer
// (4) AdsorptionSurfaceVisualAppearanceViewer
//
// Objects that conform to these protocols are:
// (1) SceneList (to view/edit all containing structures)
// (2) Scene (to view/edit all movies in the scene)
// (3) Movie (to view/edit all structures in the movie)
// (4) A subclass of Structure (to view/edit the structure)

// The representedStructure can be nil, when nothing is selected.
// This is shown as an view with all controls disabled.


class StructureAppearanceDetailViewController: NSViewController, NSOutlineViewDelegate, WindowControllerConsumer, ProjectConsumer
{
  @IBOutlet private weak var appearanceOutlineView: NSStaticViewBasedOutlineView?
  
  weak var windowController: iRASPAWindowController?
  
  deinit
  {
    //Swift.print("deinit: StructureAppearanceDetailViewController")
  }
  
  // MARK: protocol ProjectConsumer
  // =====================================================================
  

  weak var proxyProject: ProjectTreeNode?
  
  var heights : [String : CGFloat] = [:]
  
  let primitiveOrientationPropertiesCell: OutlineViewItem = OutlineViewItem("PrimitiveOrientationPropertiesCell")
  let primitiveTransformationPropertiesCell: OutlineViewItem = OutlineViewItem("PrimitiveTransformationPropertiesCell")
  let primitiveOpacityPropertiesCell: OutlineViewItem = OutlineViewItem("PrimitiveOpacityPropertiesCell")
  let primitiveSelectionPropertiesCell: OutlineViewItem = OutlineViewItem("PrimitiveSelectionPropertiesCell")
  let primitiveHSVPropertiesCell: OutlineViewItem = OutlineViewItem("PrimitiveHSVPropertiesCell")
  let primitiveFrontPropertiesCell: OutlineViewItem = OutlineViewItem("PrimitiveFrontPropertiesCell")
  let primitiveBackPropertiesCell: OutlineViewItem = OutlineViewItem("PrimitiveBackPropertiesCell")
  
  let atomsRepresentationStyleCell: OutlineViewItem = OutlineViewItem("AtomsRepresentationCell")
  let atomsSelectionCell: OutlineViewItem = OutlineViewItem("AtomsSelectionCell")
  let atomsScalingCell: OutlineViewItem = OutlineViewItem("AtomsScalingCell")
  let atomsHDRCell: OutlineViewItem = OutlineViewItem("AtomsHDRCell")
  let atomsLightingCell: OutlineViewItem = OutlineViewItem("AtomsLightingCell")
  
  let bondsScalingCell: OutlineViewItem = OutlineViewItem("BondsScalingCell")
  let bondsSelectionCell: OutlineViewItem = OutlineViewItem("BondsSelectionCell")
  let bondsHDRCell: OutlineViewItem = OutlineViewItem("BondsHDRCell")
  let bondsLightingCell: OutlineViewItem = OutlineViewItem("BondsLightingCell")
  
  let unitCellScalingCell: OutlineViewItem = OutlineViewItem("UnitCellScalingCell")
  
  let adsorptionPropertiesCell: OutlineViewItem = OutlineViewItem("AdsorptionPropertiesCell")
  let adsorptionHSVCell: OutlineViewItem = OutlineViewItem("AdsorptionHSVCell")
  let adsorptionFrontSurfaceCell: OutlineViewItem = OutlineViewItem("AdsorptionFrontSurfaceCell")
  let adsorptionBackSurfaceCell: OutlineViewItem = OutlineViewItem("AdsorptionBackSurfaceCell")
  
  let annotationVisualAppearanceCell: OutlineViewItem = OutlineViewItem("AnnotationVisualAppearanceCell")
  
  
  var surfaceUpdateBlock: () -> () = {}

  // ViewDidLoad: bounds are not yet set (do not do geometry-related etup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    self.surfaceUpdateBlock = { [weak self] in
      DispatchQueue.main.async(execute: {
        if let row: Int = self?.appearanceOutlineView?.row(forItem: self?.adsorptionPropertiesCell), row >= 0
        {
          // fast way of updating: get the current-view, set properties on it, and update the rect to redraw
          if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = self?.representedObject as? [AdsorptionSurfaceVisualAppearanceViewer],
             let view: NSTableCellView = self?.appearanceOutlineView?.view(atColumn: 0, row: row, makeIfNecessary: false) as?  NSTableCellView,
             let isovalue: Double = representedStructure.renderAdsorptionSurfaceIsovalue,
             let sliderIsovalue: NSSlider = view.viewWithTag(4) as? NSSlider,
             let textFieldIsovalue: NSTextField = view.viewWithTag(3) as? NSTextField
          {
            //sliderIsovalue.isEnabled = enabled
            let minValue: Double = Double(representedStructure.renderMinimumGridEnergyValue ?? -1000.0)
            sliderIsovalue.minValue = minValue
            sliderIsovalue.maxValue = 0.0
            sliderIsovalue.doubleValue = max(isovalue, minValue)
            textFieldIsovalue.doubleValue = max(isovalue, minValue)
          }
        }
      })
    }

    
    // check that it works with strong-references off (for compatibility with 'El Capitan')
    self.appearanceOutlineView?.stronglyReferencesItems = false
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    let primitiveVisualAppearanceItem: OutlineViewItem = OutlineViewItem(title: "PrimitiveVisualAppearanceGroup", children: [primitiveOrientationPropertiesCell, primitiveTransformationPropertiesCell, primitiveOpacityPropertiesCell, primitiveSelectionPropertiesCell, primitiveHSVPropertiesCell, primitiveFrontPropertiesCell, primitiveBackPropertiesCell])
    let atomsVisualAppearanceItem: OutlineViewItem = OutlineViewItem(title: "AtomsVisualAppearanceGroup", children: [atomsRepresentationStyleCell, atomsSelectionCell, atomsScalingCell, atomsHDRCell, atomsLightingCell])
    let bondsVisualAppearanceItem: OutlineViewItem = OutlineViewItem(title: "BondsVisualAppearanceGroup", children: [bondsScalingCell, bondsSelectionCell, bondsHDRCell, bondsLightingCell])
    let unitCellVisualAppearanceItem: OutlineViewItem = OutlineViewItem(title: "UnitCellVisualAppearanceGroup", children: [unitCellScalingCell])
    let adsorptionVisualAppearanceItem: OutlineViewItem = OutlineViewItem(title: "AdsorptionVisualAppearanceGroup", children: [adsorptionPropertiesCell, adsorptionHSVCell, adsorptionFrontSurfaceCell, adsorptionBackSurfaceCell])
    let annotationVisualAppearanceItem: OutlineViewItem = OutlineViewItem(title: "AnnotationVisualAppearanceGroup", children: [annotationVisualAppearanceCell])
    
    
    self.appearanceOutlineView?.items = [primitiveVisualAppearanceItem, atomsVisualAppearanceItem, bondsVisualAppearanceItem, unitCellVisualAppearanceItem, adsorptionVisualAppearanceItem, annotationVisualAppearanceItem]
    
  }
  
  override func viewWillAppear()
  {
    self.appearanceOutlineView?.needsLayout = true
    super.viewWillAppear()
  }
  
  override func viewDidAppear()
  {
    super.viewDidAppear()
  }
  
  // the windowController still exists when the view is there
  override func viewWillDisappear()
  {
    super.viewWillDisappear()
  }
  
  var expandedItems: [Bool] = [false,false, false,false,false,false,false,false]
  
  func storeExpandedItems()
  {
    if let outlineView = self.appearanceOutlineView
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
    
    self.appearanceOutlineView?.reloadData()
    
    NSAnimationContext.runAnimationGroup({context in
      context.duration = 0
      
      if let outlineView = self.appearanceOutlineView
      {
        for i in 0..<outlineView.items.count
        {
          if (self.expandedItems[i])
          {
            self.appearanceOutlineView?.expandItem(outlineView.items[i])
          }
          else
          {
            self.appearanceOutlineView?.collapseItem(outlineView.items[i])
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
  
  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView?
  {
    if let rowView: AppearanceTableRowView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "appearanceTableRowView"), owner: self) as? AppearanceTableRowView
    {
      return rowView
    }
    return nil
  }
  
  
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
  {
    if let string: String = (item as? OutlineViewItem)?.title,
       let view: NSTableCellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: string), owner: self) as? NSTableCellView
    {
      let enabled: Bool = proxyProject?.isEnabled ?? false
      
      setPropertiesPrimitiveTableCells(on: view, identifier: string, enabled: enabled)
      setPropertiesAtomTableCells(on: view, identifier: string, enabled: enabled)
      setPropertiesBondTableCells(on: view, identifier: string, enabled: enabled)
      setPropertiesUnitCellTableCells(on: view, identifier: string, enabled: enabled)
      setPropertiesAdsorptionTableCells(on: view, identifier: string, enabled: enabled)
      setPropertiesAnnotationTableCells(on: view, identifier: string, enabled: enabled)
      
      return view
    }
    return nil
  }
  
  func setPropertiesPrimitiveTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    switch(identifier)
    {
    case "PrimitiveOrientationPropertiesCell":
      if let textFieldRotationAngle: NSTextField = view.viewWithTag(1) as? NSTextField,
         let textFieldYawPlusX: NSButton = view.viewWithTag(2) as? NSButton,
         let textFieldYawPlusY: NSButton = view.viewWithTag(3) as? NSButton,
         let textFieldYawPlusZ: NSButton = view.viewWithTag(4) as? NSButton,
         let textFieldYawMinusX: NSButton = view.viewWithTag(5) as? NSButton,
         let textFieldYawMinusY: NSButton = view.viewWithTag(6) as? NSButton,
         let textFieldYawMinusZ: NSButton = view.viewWithTag(7) as? NSButton
      {
        textFieldRotationAngle.isEditable = false
        textFieldYawPlusX.isEnabled = false
        textFieldYawPlusY.isEnabled = false
        textFieldYawPlusZ.isEnabled = false
        textFieldYawMinusX.isEnabled = false
        textFieldYawMinusY.isEnabled = false
        textFieldYawMinusZ.isEnabled = false
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty,
          let renderRotationDelta: Double = representedStructure.renderPrimitiveRotationDelta
        {
          
          textFieldRotationAngle.isEditable = enabled
          textFieldYawPlusX.isEnabled = enabled
          textFieldYawPlusY.isEnabled = enabled
          textFieldYawPlusZ.isEnabled = enabled
          textFieldYawMinusX.isEnabled = enabled
          textFieldYawMinusY.isEnabled = enabled
          textFieldYawMinusZ.isEnabled = enabled
          
          textFieldRotationAngle.doubleValue = renderRotationDelta
          textFieldYawPlusX.title =  "Rotate +\(renderRotationDelta)°"
          textFieldYawPlusY.title =  "Rotate -\(renderRotationDelta)°"
          textFieldYawPlusZ.title =  "Rotate +\(renderRotationDelta)°"
          textFieldYawMinusX.title =  "Rotate -\(renderRotationDelta)°"
          textFieldYawMinusY.title =  "Rotate +\(renderRotationDelta)°"
          textFieldYawMinusZ.title =  "Rotate -\(renderRotationDelta)°"
        }
      }
      
      if let sliderEulerAngleX: NSSlider = view.viewWithTag(10) as? NSSlider,
        let sliderEulerAngleZ: NSSlider = view.viewWithTag(11) as? NSSlider,
        let sliderEulerAngleY: NSSlider = view.viewWithTag(12) as? NSSlider,
        let textFieldEulerAngleX: NSTextField = view.viewWithTag(13) as? NSTextField,
        let textFieldEulerAngleY: NSTextField = view.viewWithTag(14) as? NSTextField,
        let textFieldEulerAngleZ: NSTextField = view.viewWithTag(15) as? NSTextField
      {
        sliderEulerAngleX.isEnabled = false
        sliderEulerAngleZ.isEnabled = false
        sliderEulerAngleY.isEnabled = false
        textFieldEulerAngleX.isEditable = false
        textFieldEulerAngleY.isEditable = false
        textFieldEulerAngleZ.isEditable = false
        sliderEulerAngleX.stringValue = "0.0"
        sliderEulerAngleZ.stringValue = "0.0"
        sliderEulerAngleY.stringValue = "0.0"
        textFieldEulerAngleX.stringValue = "0.0"
        textFieldEulerAngleY.stringValue = "0.0"
        textFieldEulerAngleZ.stringValue = "0.0"
        
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          if let renderEulerAngleX: Double = representedStructure.renderPrimitiveEulerAngleX,
            let renderEulerAngleY: Double = representedStructure.renderPrimitiveEulerAngleY,
            let renderEulerAngleZ: Double = representedStructure.renderPrimitiveEulerAngleZ
          {
            sliderEulerAngleX.isEnabled = enabled
            sliderEulerAngleZ.isEnabled = enabled
            sliderEulerAngleY.isEnabled = enabled
            textFieldEulerAngleX.isEditable = enabled
            textFieldEulerAngleY.isEditable = enabled
            textFieldEulerAngleZ.isEditable = enabled
            sliderEulerAngleX.doubleValue = renderEulerAngleX * 180.0/Double.pi
            sliderEulerAngleZ.doubleValue = renderEulerAngleZ * 180.0/Double.pi
            sliderEulerAngleY.doubleValue = renderEulerAngleY * 180.0/Double.pi
            textFieldEulerAngleX.doubleValue = renderEulerAngleX * 180.0/Double.pi
            textFieldEulerAngleY.doubleValue = renderEulerAngleZ * 180.0/Double.pi
            textFieldEulerAngleZ.doubleValue = renderEulerAngleY * 180.0/Double.pi
          }
          else
          {
            textFieldEulerAngleX.stringValue = "Multiple Values"
            textFieldEulerAngleY.stringValue = "Multiple Values"
            textFieldEulerAngleZ.stringValue = "Multiple Values"
          }
        }
      }
    case "PrimitiveTransformationPropertiesCell":
      if let textFieldAtomScalingAX: NSTextField = view.viewWithTag(20) as? NSTextField,
        let textFieldAtomScalingBX: NSTextField = view.viewWithTag(21) as? NSTextField,
        let textFieldAtomScalingCX: NSTextField = view.viewWithTag(22) as? NSTextField,
        let textFieldAtomScalingAY: NSTextField = view.viewWithTag(23) as? NSTextField,
        let textFieldAtomScalingBY: NSTextField = view.viewWithTag(24) as? NSTextField,
        let textFieldAtomScalingCY: NSTextField = view.viewWithTag(25) as? NSTextField,
        let textFieldAtomScalingAZ: NSTextField = view.viewWithTag(26) as? NSTextField,
        let textFieldAtomScalingBZ: NSTextField = view.viewWithTag(27) as? NSTextField,
        let textFieldAtomScalingCZ: NSTextField = view.viewWithTag(28) as? NSTextField
      {
        textFieldAtomScalingAX.isEditable = false
        textFieldAtomScalingAY.isEditable = false
        textFieldAtomScalingAZ.isEditable = false
        textFieldAtomScalingBX.isEditable = false
        textFieldAtomScalingBY.isEditable = false
        textFieldAtomScalingBZ.isEditable = false
        textFieldAtomScalingCX.isEditable = false
        textFieldAtomScalingCY.isEditable = false
        textFieldAtomScalingCZ.isEditable = false
        textFieldAtomScalingAX.stringValue = "1"
        textFieldAtomScalingAY.stringValue = "0"
        textFieldAtomScalingAZ.stringValue = "0"
        textFieldAtomScalingBX.stringValue = "0"
        textFieldAtomScalingBY.stringValue = "1"
        textFieldAtomScalingBZ.stringValue = "0"
        textFieldAtomScalingCX.stringValue = "0"
        textFieldAtomScalingCY.stringValue = "0"
        textFieldAtomScalingCZ.stringValue = "1"
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          textFieldAtomScalingAX.isEditable = enabled
          textFieldAtomScalingAY.isEditable = enabled
          textFieldAtomScalingAZ.isEditable = enabled
          textFieldAtomScalingBX.isEditable = enabled
          textFieldAtomScalingBY.isEditable = enabled
          textFieldAtomScalingBZ.isEditable = enabled
          textFieldAtomScalingCX.isEditable = enabled
          textFieldAtomScalingCY.isEditable = enabled
          textFieldAtomScalingCZ.isEditable = enabled
          if let renderPrimitiveTransformationMatrix: double3x3 = representedStructure.renderPrimitiveTransformationMatrix,
            !representedStructure.allPrimitiveStructure.isEmpty
          {
            textFieldAtomScalingAX.doubleValue = renderPrimitiveTransformationMatrix[0,0]
            textFieldAtomScalingAY.doubleValue = renderPrimitiveTransformationMatrix[0,1]
            textFieldAtomScalingAZ.doubleValue = renderPrimitiveTransformationMatrix[0,2]
            textFieldAtomScalingBX.doubleValue = renderPrimitiveTransformationMatrix[1,0]
            textFieldAtomScalingBY.doubleValue = renderPrimitiveTransformationMatrix[1,1]
            textFieldAtomScalingBZ.doubleValue = renderPrimitiveTransformationMatrix[1,2]
            textFieldAtomScalingCX.doubleValue = renderPrimitiveTransformationMatrix[2,0]
            textFieldAtomScalingCY.doubleValue = renderPrimitiveTransformationMatrix[2,1]
            textFieldAtomScalingCZ.doubleValue = renderPrimitiveTransformationMatrix[2,2]
          }
          else
          {
            textFieldAtomScalingAX.stringValue = "Mult. Val."
            textFieldAtomScalingAY.stringValue = "Mult. Val."
            textFieldAtomScalingAZ.stringValue = "Mult. Val."
            textFieldAtomScalingBX.stringValue = "Mult. Val."
            textFieldAtomScalingBY.stringValue = "Mult. Val."
            textFieldAtomScalingBZ.stringValue = "Mult. Val."
            textFieldAtomScalingCX.stringValue = "Mult. Val."
            textFieldAtomScalingCY.stringValue = "Mult. Val."
            textFieldAtomScalingCZ.stringValue = "Mult. Val."
          }
        }
      }
  
    case "PrimitiveOpacityPropertiesCell":
      
      if let textFieldOpacity: NSTextField = view.viewWithTag(35) as? NSTextField
      {
        textFieldOpacity.isEditable = false
        textFieldOpacity.stringValue = "1.0"
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          textFieldOpacity.isEditable = enabled
          if let opacity = representedStructure.renderPrimitiveOpacity
          {
            textFieldOpacity.doubleValue = opacity
          }
          else
          {
            textFieldOpacity.stringValue = "Mult. Val."
          }
        }
      }
      if let sliderOpacity: NSSlider = view.viewWithTag(36) as? NSSlider
      {
        sliderOpacity.isEnabled = false
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          sliderOpacity.isEnabled = enabled
          if let opacity = representedStructure.renderPrimitiveOpacity
          {
            sliderOpacity.minValue = 0.0
            sliderOpacity.maxValue = 1.0
            sliderOpacity.doubleValue = opacity
          }
          else
          {
            sliderOpacity.minValue = 0.0
            sliderOpacity.maxValue = 1.0
            sliderOpacity.doubleValue = 0.5
          }
        }
      }
      if let textFieldNumberOfSides: NSTextField = view.viewWithTag(37) as? NSTextField
      {
        textFieldNumberOfSides.isEditable = false
        textFieldNumberOfSides.stringValue = "41"
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          textFieldNumberOfSides.isEditable = enabled
          if let numberOfSides = representedStructure.renderPrimitiveNumberOfSides
          {
            textFieldNumberOfSides.integerValue = numberOfSides
          }
          else
          {
            textFieldNumberOfSides.stringValue = "Mult. Val."
          }
        }
      }
      if let sliderNumberOfSides: NSSlider = view.viewWithTag(38) as? NSSlider
      {
        sliderNumberOfSides.isEnabled = false
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          sliderNumberOfSides.isEnabled = enabled
          if let numberOfSides = representedStructure.renderPrimitiveNumberOfSides
          {
            sliderNumberOfSides.minValue = 2
            sliderNumberOfSides.maxValue = 16
            sliderNumberOfSides.integerValue = numberOfSides
          }
          else
          {
            sliderNumberOfSides.minValue = 2
            sliderNumberOfSides.maxValue = 16
            sliderNumberOfSides.doubleValue = 6
          }
        }
      }
      
      if let button: NSButton = view.viewWithTag(39) as? NSButton
      {
        button.isEnabled = false
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          button.isEnabled = enabled
          
          if let renderPrimitiveIsCapped: Bool = representedStructure.renderPrimitiveIsCapped
          {
            button.allowsMixedState = false
            button.state = renderPrimitiveIsCapped ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            button.allowsMixedState = true
            button.state = NSControl.StateValue.mixed
          }
        }
      }
      
    case "PrimitiveSelectionPropertiesCell":
      // Selection-style
      if let popUpbuttonSelectionStyle: iRASPAPopUpButton = view.viewWithTag(2208) as? iRASPAPopUpButton,
         let textFieldSelectionFrequency: NSTextField = view.viewWithTag(2209) as? NSTextField,
         let textFieldSelectionDensity: NSTextField = view.viewWithTag(2210) as? NSTextField
      {
        popUpbuttonSelectionStyle.isEditable = false
        textFieldSelectionFrequency.isEditable = false
        textFieldSelectionFrequency.stringValue = ""
        textFieldSelectionDensity.isEditable = false
        textFieldSelectionDensity.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
        {
          popUpbuttonSelectionStyle.isEditable = enabled
          textFieldSelectionFrequency.isEditable = enabled
          textFieldSelectionDensity.isEditable = enabled
          
          if let selectionStyle: RKSelectionStyle = representedStructure.renderPrimitiveSelectionStyle
          {
            popUpbuttonSelectionStyle.removeItem(withTitle: "Multiple Values")
            popUpbuttonSelectionStyle.selectItem(at: selectionStyle.rawValue)
            
            if selectionStyle == .glow
            {
              textFieldSelectionFrequency.isEditable = false
              textFieldSelectionDensity.isEditable = false
            }
          }
          else
          {
            popUpbuttonSelectionStyle.setTitle("Multiple Values")
            textFieldSelectionFrequency.stringValue = "Mult. Val."
            textFieldSelectionDensity.stringValue = "Mult. Val."
          }
          
          if let renderSelectionFrequency: Double = representedStructure.renderPrimitiveSelectionFrequency
          {
            textFieldSelectionFrequency.doubleValue = renderSelectionFrequency
          }
          else
          {
            textFieldSelectionFrequency.stringValue = "Mult. Val."
          }
          
          if let renderSelectionDensity: Double = representedStructure.renderPrimitiveSelectionDensity
          {
            textFieldSelectionDensity.doubleValue = renderSelectionDensity
          }
          else
          {
            textFieldSelectionDensity.stringValue = "Mult. Val."
          }
        }
      }
      
      if let textFieldBondSelectionIntensityLevel: NSTextField = view.viewWithTag(2234) as? NSTextField
      {
        textFieldBondSelectionIntensityLevel.isEditable = false
        textFieldBondSelectionIntensityLevel.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
        {
          textFieldBondSelectionIntensityLevel.isEditable = enabled
          if let renderSelectionIntensityLevel: Double = representedStructure.renderPrimitiveSelectionIntensity
          {
            textFieldBondSelectionIntensityLevel.doubleValue = renderSelectionIntensityLevel
          }
          else
          {
            textFieldBondSelectionIntensityLevel.stringValue = "Multiple Values"
          }
        }
      }
        
      if let sliderSelectionIntensityLevel: NSSlider = view.viewWithTag(2235) as? NSSlider
      {
        sliderSelectionIntensityLevel.isEnabled = false
        sliderSelectionIntensityLevel.minValue = 0.0
        sliderSelectionIntensityLevel.maxValue = 2.0
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
        {
          sliderSelectionIntensityLevel.isEnabled = enabled
          if let renderSelectionIntensityLevel: Double = representedStructure.renderPrimitiveSelectionIntensity
          {
            sliderSelectionIntensityLevel.doubleValue = renderSelectionIntensityLevel
          }
        }
      }
        
      
      if let textFieldSelectionScaling: NSTextField = view.viewWithTag(2281) as? NSTextField
      {
        textFieldSelectionScaling.isEditable = false
        textFieldSelectionScaling.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
        {
          textFieldSelectionScaling.isEditable = enabled
          if let renderSelectionScaling: Double = representedStructure.renderPrimitiveSelectionScaling
          {
            textFieldSelectionScaling.doubleValue = renderSelectionScaling
          }
          else
          {
            textFieldSelectionScaling.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderSelectionScaling: NSSlider = view.viewWithTag(2282) as? NSSlider
      {
        sliderSelectionScaling.isEnabled = false
        sliderSelectionScaling.minValue = 1.0
        sliderSelectionScaling.maxValue = 2.0
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
        {
          sliderSelectionScaling.isEnabled = enabled
          if let renderSelectionScaling: Double = representedStructure.renderPrimitiveSelectionScaling
          {
            sliderSelectionScaling.doubleValue = renderSelectionScaling
          }
        }
      }
      
    case "PrimitiveHSVPropertiesCell":
      // Hue
      if let textFieldHue: NSTextField = view.viewWithTag(2213) as? NSTextField
      {
        textFieldHue.isEditable = false
        textFieldHue.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
        {
          textFieldHue.isEditable = enabled
          if let renderBondHue: Double = representedStructure.renderPrimitiveHue
          {
            textFieldHue.doubleValue = renderBondHue
          }
        }
      }
      if let sliderHue: NSSlider = view.viewWithTag(2214) as? NSSlider
      {
        sliderHue.isEnabled = false
        sliderHue.minValue = 0.0
        sliderHue.maxValue = 1.5
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
        {
          sliderHue.isEnabled = enabled
          if let renderBondHue: Double = representedStructure.renderPrimitiveHue
          {
            sliderHue.doubleValue = renderBondHue
          }
        }
      }
      
      // Saturation
      if let textFieldSaturation: NSTextField = view.viewWithTag(2215) as? NSTextField
      {
        textFieldSaturation.isEditable = false
        textFieldSaturation.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
        {
          textFieldSaturation.isEditable = enabled
          if let renderBondSaturation: Double = representedStructure.renderPrimitiveSaturation
          {
            textFieldSaturation.doubleValue = renderBondSaturation
          }
        }
      }
      if let sliderSaturation: NSSlider = view.viewWithTag(2216) as? NSSlider
      {
        sliderSaturation.isEnabled = false
        sliderSaturation.minValue = 0.0
        sliderSaturation.maxValue = 1.5
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
        {
          sliderSaturation.isEnabled = enabled
          if let renderBondSaturation: Double = representedStructure.renderPrimitiveSaturation
          {
            sliderSaturation.doubleValue = renderBondSaturation
          }
        }
      }
      
      // Value
      if let textFieldValue: NSTextField = view.viewWithTag(2217) as? NSTextField
      {
        textFieldValue.isEditable = false
        textFieldValue.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
        {
          textFieldValue.isEditable = enabled
          if let renderBondValue: Double = representedStructure.renderPrimitiveValue
          {
            textFieldValue.doubleValue = renderBondValue
          }
        }
      }
      if let sliderValue: NSSlider = view.viewWithTag(2218) as? NSSlider
      {
        sliderValue.isEnabled = false
        sliderValue.minValue = 0.0
        sliderValue.maxValue = 1.5
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
        {
          sliderValue.isEnabled = enabled
          if let renderBondValue: Double = representedStructure.renderPrimitiveValue
          {
            sliderValue.doubleValue = renderBondValue
          }
        }
      }
      
    case "PrimitiveFrontPropertiesCell":
      
      // High dynamic range
      if let button: NSButton = view.viewWithTag(41) as? NSButton
      {
        button.isEnabled = false
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          button.isEnabled = enabled
          
          if let renderPrimitiveFrontSideHDR: Bool = representedStructure.renderPrimitiveFrontSideHDR
          {
            button.allowsMixedState = false
            button.state = renderPrimitiveFrontSideHDR ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            button.allowsMixedState = true
            button.state = NSControl.StateValue.mixed
          }
        }
      }
      
      // Exposure
      if let textFieldExposure: NSTextField = view.viewWithTag(42) as? NSTextField
      {
        textFieldExposure.isEditable = false
        textFieldExposure.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          textFieldExposure.isEditable = enabled
          if let renderPrimitiveFrontSideHDRExposure: Double = representedStructure.renderPrimitiveFrontSideHDRExposure
          {
            textFieldExposure.doubleValue = renderPrimitiveFrontSideHDRExposure
          }
          else
          {
            textFieldExposure.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderExposure: NSSlider = view.viewWithTag(43) as? NSSlider
      {
        sliderExposure.isEnabled = false
        sliderExposure.minValue = 0.0
        sliderExposure.maxValue = 3.0
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          sliderExposure.isEnabled = enabled
          if let renderPrimitiveFrontSideHDRExposure: Double = representedStructure.renderPrimitiveFrontSideHDRExposure
          {
            sliderExposure.doubleValue = renderPrimitiveFrontSideHDRExposure
          }
        }
      }
      
      
      // ambient intensity and color
      if let textFieldFrontAmbientIntensity: NSTextField = view.viewWithTag(44) as? NSTextField
      {
        textFieldFrontAmbientIntensity.isEditable = false
        textFieldFrontAmbientIntensity.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          textFieldFrontAmbientIntensity.isEditable = enabled
          if let ambientIntensity = representedStructure.renderPrimitiveFrontSideAmbientIntensity
          {
            textFieldFrontAmbientIntensity.doubleValue = ambientIntensity
          }
          else
          {
            textFieldFrontAmbientIntensity.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderFrontAmbientIntensity: NSSlider = view.viewWithTag(45) as? NSSlider
      {
        sliderFrontAmbientIntensity.isEnabled = false
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          sliderFrontAmbientIntensity.isEnabled = enabled
          if let ambientIntensity = representedStructure.renderPrimitiveFrontSideAmbientIntensity
          {
            sliderFrontAmbientIntensity.minValue = 0.0
            sliderFrontAmbientIntensity.maxValue = 1.0
            sliderFrontAmbientIntensity.doubleValue = ambientIntensity
          }
        }
      }
      if let ambientFrontSideColor: NSColorWell = view.viewWithTag(46) as? NSColorWell
      {
        ambientFrontSideColor.isEnabled = false
        ambientFrontSideColor.color = NSColor.lightGray
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          ambientFrontSideColor.isEnabled = enabled
          if let color = representedStructure.renderPrimitiveFrontSideAmbientColor
          {
            ambientFrontSideColor.color = color
          }
        }
      }
      
      // diffuse intensity and color
      if let textFieldFrontDiffuseIntensity: NSTextField = view.viewWithTag(47) as? NSTextField
      {
        textFieldFrontDiffuseIntensity.isEditable = false
        textFieldFrontDiffuseIntensity.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          textFieldFrontDiffuseIntensity.isEditable = enabled
          if let diffuseIntensity = representedStructure.renderPrimitiveFrontSideDiffuseIntensity
          {
            textFieldFrontDiffuseIntensity.doubleValue = diffuseIntensity
          }
          else
          {
            textFieldFrontDiffuseIntensity.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderFrontDiffuseIntensity: NSSlider = view.viewWithTag(48) as? NSSlider
      {
        sliderFrontDiffuseIntensity.isEnabled = false
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          sliderFrontDiffuseIntensity.isEnabled = enabled
          if let diffuseIntensity = representedStructure.renderPrimitiveFrontSideDiffuseIntensity
          {
            sliderFrontDiffuseIntensity.minValue = 0.0
            sliderFrontDiffuseIntensity.maxValue = 1.0
            sliderFrontDiffuseIntensity.doubleValue = diffuseIntensity
          }
        }
      }
      if let diffuseFrontSideColor: NSColorWell = view.viewWithTag(49) as? NSColorWell
      {
        diffuseFrontSideColor.isEnabled = false
        diffuseFrontSideColor.color = NSColor.lightGray
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          diffuseFrontSideColor.isEnabled = enabled
          if let color = representedStructure.renderPrimitiveFrontSideDiffuseColor
          {
            diffuseFrontSideColor.color = color
          }
        }
      }
      
      // specular intensity and color
      if let textFieldFrontSpecularIntensity: NSTextField = view.viewWithTag(50) as? NSTextField
      {
        textFieldFrontSpecularIntensity.isEditable = false
        textFieldFrontSpecularIntensity.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          textFieldFrontSpecularIntensity.isEditable = enabled
          if let specularIntensity = representedStructure.renderPrimitiveFrontSideSpecularIntensity
          {
            textFieldFrontSpecularIntensity.doubleValue = specularIntensity
          }
          else
          {
            textFieldFrontSpecularIntensity.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderFrontSpecularIntensity: NSSlider = view.viewWithTag(51) as? NSSlider
      {
        sliderFrontSpecularIntensity.isEnabled = false
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          sliderFrontSpecularIntensity.isEnabled = enabled
          if let specularIntensity = representedStructure.renderPrimitiveFrontSideSpecularIntensity
          {
            sliderFrontSpecularIntensity.minValue = 0.0
            sliderFrontSpecularIntensity.maxValue = 1.0
            sliderFrontSpecularIntensity.doubleValue = specularIntensity
          }
        }
      }
      if let specularFrontSideColor: NSColorWell = view.viewWithTag(52) as? NSColorWell
      {
        specularFrontSideColor.isEnabled = false
        specularFrontSideColor.color = NSColor.lightGray
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          specularFrontSideColor.isEnabled = enabled
          if let color = representedStructure.renderPrimitiveFrontSideSpecularColor
          {
            specularFrontSideColor.color = color
          }
        }
      }
      
      
      
      if let textFieldFrontShininess: NSTextField = view.viewWithTag(53) as? NSTextField
      {
        textFieldFrontShininess.isEditable = false
        textFieldFrontShininess.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          textFieldFrontShininess.isEditable = enabled
          if let shininess = representedStructure.renderPrimitiveFrontSideShininess
          {
            textFieldFrontShininess.doubleValue = shininess
          }
          else
          {
            textFieldFrontShininess.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderFrontShininess: NSSlider = view.viewWithTag(54) as? NSSlider
      {
        sliderFrontShininess.isEnabled = false
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          sliderFrontShininess.isEnabled = enabled
          if let shininess = representedStructure.renderPrimitiveFrontSideShininess
          {
            sliderFrontShininess.minValue = 0.0
            sliderFrontShininess.maxValue = 256.0
            sliderFrontShininess.doubleValue = shininess
          }
        }
      }
    case "PrimitiveBackPropertiesCell":
      
      // High dynamic range
      if let button: NSButton = view.viewWithTag(57) as? NSButton
      {
        button.isEnabled = false
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          button.isEnabled = enabled
          if let renderPrimitiveHDR: Bool = representedStructure.renderPrimitiveBackSideHDR
          {
            button.allowsMixedState = false
            button.state = renderPrimitiveHDR ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            button.allowsMixedState = true
            button.state = NSControl.StateValue.mixed
          }
        }
      }
      
      // Exposure
      if let textFieldExposure: NSTextField = view.viewWithTag(58) as? NSTextField
      {
        textFieldExposure.isEditable = false
        textFieldExposure.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          textFieldExposure.isEditable = enabled
          if let renderPrimitiveBackSideHDRExposure: Double = representedStructure.renderPrimitiveBackSideHDRExposure
          {
            textFieldExposure.doubleValue = renderPrimitiveBackSideHDRExposure
          }
          else
          {
            textFieldExposure.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderExposure: NSSlider = view.viewWithTag(59) as? NSSlider
      {
        sliderExposure.isEnabled = false
        sliderExposure.minValue = 0.0
        sliderExposure.maxValue = 3.0
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          sliderExposure.isEnabled = enabled
          if let renderPrimitiveBackSideHDRExposure: Double = representedStructure.renderPrimitiveBackSideHDRExposure
          {
            sliderExposure.doubleValue = renderPrimitiveBackSideHDRExposure
          }
        }
      }
      
      
      // Ambient color
      if let textFieldBackAmbientIntensity: NSTextField = view.viewWithTag(60) as? NSTextField
      {
        textFieldBackAmbientIntensity.isEditable = false
        textFieldBackAmbientIntensity.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          textFieldBackAmbientIntensity.isEditable = enabled
          if let ambientIntensity = representedStructure.renderPrimitiveBackSideAmbientIntensity
          {
            textFieldBackAmbientIntensity.doubleValue = ambientIntensity
          }
          else
          {
            textFieldBackAmbientIntensity.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderBackAmbientIntensity: NSSlider = view.viewWithTag(61) as? NSSlider
      {
        sliderBackAmbientIntensity.isEnabled = false
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          sliderBackAmbientIntensity.isEnabled = enabled
          if let ambientIntensity = representedStructure.renderPrimitiveBackSideAmbientIntensity
          {
            sliderBackAmbientIntensity.minValue = 0.0
            sliderBackAmbientIntensity.maxValue = 1.0
            sliderBackAmbientIntensity.doubleValue = ambientIntensity
          }
        }
      }
      if let ambientBackSideColor: NSColorWell = view.viewWithTag(62) as? NSColorWell
      {
        ambientBackSideColor.isEnabled = false
        ambientBackSideColor.color = NSColor.lightGray
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          ambientBackSideColor.isEnabled = enabled
          if let color = representedStructure.renderPrimitiveBackSideAmbientColor
          {
            ambientBackSideColor.color = color
          }
        }
      }
      
      // Diffuse color
      if let textFieldBackDiffuseIntensity: NSTextField = view.viewWithTag(63) as? NSTextField
      {
        textFieldBackDiffuseIntensity.isEditable = false
        textFieldBackDiffuseIntensity.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          textFieldBackDiffuseIntensity.isEditable = enabled
          if let diffuseIntensity = representedStructure.renderPrimitiveBackSideDiffuseIntensity
          {
            textFieldBackDiffuseIntensity.doubleValue = diffuseIntensity
          }
          else
          {
            textFieldBackDiffuseIntensity.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderBackDiffuseIntensity: NSSlider = view.viewWithTag(64) as? NSSlider
      {
        sliderBackDiffuseIntensity.isEnabled = false
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          sliderBackDiffuseIntensity.isEnabled = enabled
          if let diffuseIntensity = representedStructure.renderPrimitiveBackSideDiffuseIntensity
          {
            sliderBackDiffuseIntensity.minValue = 0.0
            sliderBackDiffuseIntensity.maxValue = 1.0
            sliderBackDiffuseIntensity.doubleValue = diffuseIntensity
          }
        }
      }
      if let diffuseBackSideColor: NSColorWell = view.viewWithTag(65) as? NSColorWell
      {
        diffuseBackSideColor.isEnabled = false
        diffuseBackSideColor.color = NSColor.lightGray
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          diffuseBackSideColor.isEnabled = enabled
          if let color = representedStructure.renderPrimitiveBackSideDiffuseColor
          {
            diffuseBackSideColor.color = color
          }
        }
      }
      
      // Specular color
      if let textFieldBackSpecularIntensity: NSTextField = view.viewWithTag(66) as? NSTextField
      {
        textFieldBackSpecularIntensity.isEditable = false
        textFieldBackSpecularIntensity.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          textFieldBackSpecularIntensity.isEditable = enabled
          if let specularIntensity = representedStructure.renderPrimitiveBackSideSpecularIntensity
          {
            textFieldBackSpecularIntensity.doubleValue = specularIntensity
          }
          else
          {
            textFieldBackSpecularIntensity.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderBackSpecularIntensity: NSSlider = view.viewWithTag(67) as? NSSlider
      {
        sliderBackSpecularIntensity.isEnabled = false
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          sliderBackSpecularIntensity.isEnabled = enabled
          if let specularIntensity = representedStructure.renderPrimitiveBackSideSpecularIntensity
          {
            sliderBackSpecularIntensity.minValue = 0.0
            sliderBackSpecularIntensity.maxValue = 1.0
            sliderBackSpecularIntensity.doubleValue = specularIntensity
          }
        }
      }
      if let specularBackSideColor: NSColorWell = view.viewWithTag(68) as? NSColorWell
      {
        specularBackSideColor.isEnabled = false
        specularBackSideColor.color = NSColor.lightGray
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          specularBackSideColor.isEnabled = enabled
          if let color = representedStructure.renderPrimitiveBackSideSpecularColor
          {
            specularBackSideColor.color = color
          }
        }
      }
      
      // Shininess
      if let textFieldBackShininess: NSTextField = view.viewWithTag(69) as? NSTextField
      {
        textFieldBackShininess.isEditable = false
        textFieldBackShininess.stringValue = ""
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          textFieldBackShininess.isEditable = enabled
          if let shininess = representedStructure.renderPrimitiveBackSideShininess
          {
            textFieldBackShininess.doubleValue = shininess
          }
          else
          {
            textFieldBackShininess.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderBackShininess: NSSlider = view.viewWithTag(70) as? NSSlider
      {
        sliderBackShininess.isEnabled = false
        if let representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
          !representedStructure.allPrimitiveStructure.isEmpty
        {
          sliderBackShininess.isEnabled = enabled
          if let shininess = representedStructure.renderPrimitiveBackSideShininess
          {
            sliderBackShininess.minValue = 0.0
            sliderBackShininess.maxValue = 256.0
            sliderBackShininess.doubleValue = shininess
          }
        }
      }
   
      
      
    default:
      break
    }
  }
  
  func setPropertiesAtomTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    switch(identifier)
    {
    case "AtomsRepresentationCell":
      // Representation type
      if let popUpbuttonRepresentationType: iRASPAPopUpButton = view.viewWithTag(1) as? iRASPAPopUpButton
      {
        popUpbuttonRepresentationType.isEditable = false
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          popUpbuttonRepresentationType.isEditable = enabled
          
          if let rawValue = representedStructure.getRepresentationType()?.rawValue
          {
            popUpbuttonRepresentationType.removeItem(withTitle: "Multiple Values")
            popUpbuttonRepresentationType.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonRepresentationType.setTitle("Multiple Values")
          }
        }
        
      }
      
      // Representation style
      if let popUpbuttonRepresentationStyle: iRASPAPopUpButton = view.viewWithTag(2) as? iRASPAPopUpButton
      {
        popUpbuttonRepresentationStyle.isEditable = false
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          popUpbuttonRepresentationStyle.isEditable = enabled
          
          if let representationStyle = representedStructure.getRepresentationStyle()
          {
            popUpbuttonRepresentationStyle.removeItem(withTitle: "Multiple values")
            popUpbuttonRepresentationStyle.removeItem(withTitle: "Custom")
            
            if representationStyle.rawValue >= 0
            {
              popUpbuttonRepresentationStyle.selectItem(at: representationStyle.rawValue)
            }
            else
            {
              popUpbuttonRepresentationStyle.setTitle("Custom")
            }
          }
          else
          {
            popUpbuttonRepresentationStyle.setTitle("Multiple values")
          }
        }
      }
      
      // Color scheme
      if let popUpbuttonColorScheme: iRASPAPopUpButton = view.viewWithTag(3) as? iRASPAPopUpButton
      {
        if let document: iRASPADocument = self.windowController?.currentDocument
        {
          popUpbuttonColorScheme.removeAllItems()
          for i in 0..<document.colorSets.count
          {
            popUpbuttonColorScheme.addItem(withTitle: document.colorSets[i].displayName)
          }
          
        }
        
        popUpbuttonColorScheme.isEditable = false
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          popUpbuttonColorScheme.isEditable = enabled
          
          if let rawValue: String = representedStructure.getRepresentationColorScheme()
          {
            popUpbuttonColorScheme.removeItem(withTitle: "Multiple Values")
            popUpbuttonColorScheme.selectItem(withTitle: rawValue)
          }
          else
          {
            popUpbuttonColorScheme.setTitle("Multiple Values")
          }
        }
      }
      
      // Force Field
      if let popUpbuttonForceField: iRASPAPopUpButton = view.viewWithTag(4) as? iRASPAPopUpButton
      {
        if let document: iRASPADocument = self.windowController?.currentDocument
        {
          popUpbuttonForceField.removeAllItems()
          for i in 0..<document.forceFieldSets.count
          {
            let forceFieldSet: SKForceFieldSet = document.forceFieldSets[i]
            popUpbuttonForceField.addItem(withTitle: forceFieldSet.displayName)
          }
        }
        
        popUpbuttonForceField.isEditable = false
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          popUpbuttonForceField.isEditable = enabled
          
          if let rawValue: String = representedStructure.getRepresentationForceField()
          {
            popUpbuttonForceField.removeItem(withTitle: "Multiple Values")
            popUpbuttonForceField.selectItem(withTitle: rawValue)
          }
          else
          {
            popUpbuttonForceField.setTitle("Multiple Values")
          }
        }
      }
      
      
      // Color order
      if let popUpbuttonColorOrder: iRASPAPopUpButton = view.viewWithTag(5) as? iRASPAPopUpButton
      {
        popUpbuttonColorOrder.isEditable = false
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          popUpbuttonColorOrder.isEditable = enabled
          
          if let rawValue: Int = representedStructure.getRepresentationColorOrder()?.rawValue
          {
            popUpbuttonColorOrder.removeItem(withTitle: "Multiple Values")
            popUpbuttonColorOrder.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonColorOrder.setTitle("Multiple Values")
          }
        }
      }
      
      // Force field order
      if let popUpbuttonForceFieldOrder: iRASPAPopUpButton = view.viewWithTag(6) as? iRASPAPopUpButton
      {
        popUpbuttonForceFieldOrder.isEditable = false
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          popUpbuttonForceFieldOrder.isEditable = enabled
          
          if let rawValue: Int = representedStructure.getRepresentationForceFieldOrder()?.rawValue
          {
            popUpbuttonForceFieldOrder.removeItem(withTitle: "Multiple Values")
            popUpbuttonForceFieldOrder.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonForceFieldOrder.setTitle("Multiple Values")
          }
        }
      }
    case "AtomsSelectionCell":
      // Selection-style
      if let popUpbuttonSelectionStyle: iRASPAPopUpButton = view.viewWithTag(7) as? iRASPAPopUpButton,
         let textFieldSelectionFrequency: NSTextField = view.viewWithTag(8) as? NSTextField,
         let textFieldSelectionDensity: NSTextField = view.viewWithTag(10) as? NSTextField
      {
        popUpbuttonSelectionStyle.isEditable = false
        textFieldSelectionFrequency.isEditable = false
        textFieldSelectionFrequency.stringValue = ""
        textFieldSelectionDensity.isEditable = false
        textFieldSelectionDensity.stringValue = ""
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          popUpbuttonSelectionStyle.isEditable = enabled
          textFieldSelectionFrequency.isEditable = enabled
          textFieldSelectionDensity.isEditable = enabled
          
          if let selectionStyle: RKSelectionStyle = representedStructure.renderAtomSelectionStyle
          {
            popUpbuttonSelectionStyle.removeItem(withTitle: "Multiple Values")
            popUpbuttonSelectionStyle.selectItem(at: selectionStyle.rawValue)
            
            if selectionStyle == .glow
            {
              textFieldSelectionFrequency.isEditable = false
              textFieldSelectionDensity.isEditable = false
            }
          }
          else
          {
            popUpbuttonSelectionStyle.setTitle("Multiple Values")
            textFieldSelectionFrequency.stringValue = "Mult. Val."
            textFieldSelectionDensity.stringValue = "Mult. Val."
          }
          
          if let renderSelectionFrequency: Double = representedStructure.renderAtomSelectionFrequency
          {
            textFieldSelectionFrequency.doubleValue = renderSelectionFrequency
          }
          else
          {
            textFieldSelectionFrequency.stringValue = "Mult. Val."
          }
          
          if let renderSelectionDensity: Double = representedStructure.renderAtomSelectionDensity
          {
            textFieldSelectionDensity.doubleValue = renderSelectionDensity
          }
          else
          {
            textFieldSelectionDensity.stringValue = "Mult. Val."
          }
        }
      }

      if let textFieldAtomSelectionIntensityLevel: NSTextField = view.viewWithTag(34) as? NSTextField
      {
        textFieldAtomSelectionIntensityLevel.isEditable = false
        textFieldAtomSelectionIntensityLevel.stringValue = ""
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          textFieldAtomSelectionIntensityLevel.isEditable = enabled
          if let renderAtomSelectionIntensityLevel: Double = representedStructure.renderAtomSelectionIntensity
          {
            textFieldAtomSelectionIntensityLevel.doubleValue = renderAtomSelectionIntensityLevel
          }
          else
          {
            textFieldAtomSelectionIntensityLevel.stringValue = "Multiple Values"
          }
        }
      }
      
      if let sliderAtomSelectionIntensityLevel: NSSlider = view.viewWithTag(35) as? NSSlider
      {
        sliderAtomSelectionIntensityLevel.isEnabled = false
        sliderAtomSelectionIntensityLevel.minValue = 0.0
        sliderAtomSelectionIntensityLevel.maxValue = 2.0
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          sliderAtomSelectionIntensityLevel.isEnabled = enabled
          if let renderAtomSelectionIntensityLevel: Double = representedStructure.renderAtomSelectionIntensity
          {
            sliderAtomSelectionIntensityLevel.doubleValue = renderAtomSelectionIntensityLevel
          }
        }
      }
      
    
      if let textFieldSelectionScaling: NSTextField = view.viewWithTag(81) as? NSTextField
      {
        textFieldSelectionScaling.isEditable = false
        textFieldSelectionScaling.stringValue = ""
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          textFieldSelectionScaling.isEditable = enabled
          if let renderAtomSelectionIntensityLevel: Double = representedStructure.renderAtomSelectionScaling
          {
            textFieldSelectionScaling.doubleValue = renderAtomSelectionIntensityLevel
          }
          else
          {
            textFieldSelectionScaling.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderSelectionScaling: NSSlider = view.viewWithTag(82) as? NSSlider
      {
        sliderSelectionScaling.isEnabled = false
        sliderSelectionScaling.minValue = 1.0
        sliderSelectionScaling.maxValue = 2.0
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          sliderSelectionScaling.isEnabled = enabled
          if let renderSelectionScaling: Double = representedStructure.renderAtomSelectionScaling
          {
            sliderSelectionScaling.doubleValue = renderSelectionScaling
          }
        }
      }
      
    case "AtomsHDRCell":
      // High dynamic range
      if let button: NSButton = view.viewWithTag(11) as? NSButton
      {
        button.isEnabled = false
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          button.isEnabled = enabled
          
          if let renderAtomHDR: Bool = representedStructure.renderAtomHDR
          {
            button.allowsMixedState = false
            button.state = renderAtomHDR ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            button.allowsMixedState = true
            button.state = NSControl.StateValue.mixed
          }
        }
      }
      
      // Exposure
      if let textFieldExposure: NSTextField = view.viewWithTag(12) as? NSTextField
      {
        textFieldExposure.isEditable = false
        textFieldExposure.stringValue = ""
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          textFieldExposure.isEditable = enabled
          if let renderAtomHDRExposure: Double = representedStructure.renderAtomHDRExposure
          {
            textFieldExposure.doubleValue = renderAtomHDRExposure
          }
          else
          {
            textFieldExposure.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderExposure: NSSlider = view.viewWithTag(13) as? NSSlider
      {
        sliderExposure.isEnabled = false
        sliderExposure.minValue = 0.0
        sliderExposure.maxValue = 3.0
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          sliderExposure.isEnabled = enabled
          if let renderAtomHDRExposure: Double = representedStructure.renderAtomHDRExposure
          {
            sliderExposure.doubleValue = renderAtomHDRExposure
          }
        }
      }
      
      // Hue
      if let textFieldHue: NSTextField = view.viewWithTag(16) as? NSTextField
      {
        textFieldHue.isEditable = false
        textFieldHue.stringValue = ""
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          textFieldHue.isEditable = enabled
          if let renderHue: Double = representedStructure.renderAtomHue
          {
            textFieldHue.doubleValue = renderHue
          }
          else
          {
            textFieldHue.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderHue: NSSlider = view.viewWithTag(17) as? NSSlider
      {
        sliderHue.isEnabled = false
        sliderHue.minValue = 0.0
        sliderHue.maxValue = 1.5
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          sliderHue.isEnabled = enabled
          if let renderHue: Double = representedStructure.renderAtomHue
          {
            sliderHue.doubleValue = renderHue
          }
        }
      }
      
      // Saturation
      if let textFieldSaturation: NSTextField = view.viewWithTag(18) as? NSTextField
      {
        textFieldSaturation.isEditable = false
        textFieldSaturation.stringValue = ""
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          textFieldSaturation.isEditable = enabled
          if let renderSaturation = representedStructure.renderAtomSaturation
          {
            textFieldSaturation.doubleValue = renderSaturation
          }
          else
          {
            textFieldSaturation.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderSaturation: NSSlider = view.viewWithTag(19) as? NSSlider
      {
        sliderSaturation.isEnabled = false
        sliderSaturation.minValue = 0.0
        sliderSaturation.maxValue = 1.5
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          sliderSaturation.isEnabled = enabled
          if let renderSaturation = representedStructure.renderAtomSaturation
          {
            sliderSaturation.doubleValue = renderSaturation
          }
        }
      }
      
      // Value
      if let textFieldValue: NSTextField = view.viewWithTag(20) as? NSTextField
      {
        textFieldValue.isEditable = false
        textFieldValue.stringValue = ""
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          textFieldValue.isEditable = enabled
          if let renderValue: Double = representedStructure.renderAtomValue
          {
            textFieldValue.doubleValue = renderValue
          }
          else
          {
            textFieldValue.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderValue: NSSlider = view.viewWithTag(21) as? NSSlider
      {
        sliderValue.isEnabled = false
        sliderValue.minValue = 0.0
        sliderValue.maxValue = 1.5
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          sliderValue.isEnabled = enabled
          if let renderValue: Double = representedStructure.renderAtomValue
          {
            sliderValue.doubleValue = renderValue
          }
        }
      }
    
    
    case "AtomsScalingCell":
      // Draw atoms yes/no
      if let checkDrawAtomsbutton: NSButton = view.viewWithTag(31) as? NSButton
      {
        checkDrawAtomsbutton.isEnabled = false
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          checkDrawAtomsbutton.isEnabled = enabled
          if let renderDrawAtoms: Bool = representedStructure.renderDrawAtoms
          {
            checkDrawAtomsbutton.allowsMixedState = false
            checkDrawAtomsbutton.state = renderDrawAtoms ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            checkDrawAtomsbutton.allowsMixedState = true
            checkDrawAtomsbutton.state = NSControl.StateValue.mixed
          }
        }
      }
      
      // Atom scaling
      if let textFieldAtomScaling: NSTextField = view.viewWithTag(32) as? NSTextField
      {
        textFieldAtomScaling.isEditable = false
        textFieldAtomScaling.stringValue = ""
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          textFieldAtomScaling.isEditable = enabled
          if let renderAtomScaleFactor: Double = representedStructure.renderAtomScaleFactor
          {
            textFieldAtomScaling.doubleValue = renderAtomScaleFactor
          }
          else
          {
            textFieldAtomScaling.stringValue = "Multiple Values"
          }
        }
      }
      
      if let sliderAtomScaling: NSSlider = view.viewWithTag(33) as? NSSlider
      {
        sliderAtomScaling.isEnabled = false
        sliderAtomScaling.minValue = 0.1
        sliderAtomScaling.maxValue = 2.0
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          sliderAtomScaling.isEnabled = enabled
          if let renderAtomScaleFactor: Double = representedStructure.renderAtomScaleFactor
          {
            sliderAtomScaling.doubleValue = renderAtomScaleFactor
          }
        }
      }
    case "AtomsLightingCell":
      // Ambient occlusion
      if let buttonAmbientOcclusion: NSButton = view.viewWithTag(41) as? NSButton
      {
        buttonAmbientOcclusion.isEnabled = false
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          buttonAmbientOcclusion.isEnabled = enabled
          if let renderAtomAmbientOcclusion: Bool = representedStructure.renderAtomAmbientOcclusion
          {
            buttonAmbientOcclusion.allowsMixedState = false
            buttonAmbientOcclusion.state = renderAtomAmbientOcclusion ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            buttonAmbientOcclusion.allowsMixedState = true
            buttonAmbientOcclusion.state = NSControl.StateValue.mixed
          }
        }
      }
      
      // Atom ambient light
      if let ambientLightIntensitity: NSTextField = view.viewWithTag(42) as? NSTextField
      {
        ambientLightIntensitity.isEditable = false
        ambientLightIntensitity.stringValue = ""
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          ambientLightIntensitity.isEditable = enabled
          if let renderAtomAmbientIntensity: Double = representedStructure.renderAtomAmbientIntensity
          {
            ambientLightIntensitity.doubleValue = renderAtomAmbientIntensity
          }
          else
          {
            ambientLightIntensitity.stringValue = "Multiple Values"
          }
          
        }
      }
      if let sliderAmbientLightIntensitity: NSSlider = view.viewWithTag(43) as? NSSlider
      {
        sliderAmbientLightIntensitity.isEnabled = false
        sliderAmbientLightIntensitity.minValue = 0.0
        sliderAmbientLightIntensitity.maxValue = 1.0
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          sliderAmbientLightIntensitity.isEnabled = enabled
          if let renderAtomAmbientIntensity: Double = representedStructure.renderAtomAmbientIntensity
          {
            sliderAmbientLightIntensitity.doubleValue = renderAtomAmbientIntensity
          }
        }
      }
      if let ambientColor: NSColorWell = view.viewWithTag(44) as? NSColorWell
      {
        ambientColor.isEnabled = false
        ambientColor.color = NSColor.lightGray
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          ambientColor.isEnabled = enabled
          if let renderAtomAmbientColor: NSColor = representedStructure.renderAtomAmbientColor
          {
            ambientColor.color = renderAtomAmbientColor
          }
          else
          {
            ambientColor.color = NSColor.lightGray
          }
        }
      }
      
      // Atom diffuse light
      if let diffuseLightIntensitity: NSTextField = view.viewWithTag(45) as? NSTextField
      {
        diffuseLightIntensitity.isEditable = false
        diffuseLightIntensitity.stringValue = ""
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
          
        {
          diffuseLightIntensitity.isEditable = enabled
          if let renderAtomDiffuseIntensity: Double = representedStructure.renderAtomDiffuseIntensity
          {
            diffuseLightIntensitity.doubleValue = renderAtomDiffuseIntensity
          }
          else
          {
            diffuseLightIntensitity.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderDiffuseLightIntensitity: NSSlider = view.viewWithTag(46) as? NSSlider
      {
        sliderDiffuseLightIntensitity.isEnabled = false
        sliderDiffuseLightIntensitity.minValue = 0.0
        sliderDiffuseLightIntensitity.maxValue = 1.0
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          sliderDiffuseLightIntensitity.isEnabled = enabled
          if let renderAtomDiffuseIntensity: Double = representedStructure.renderAtomDiffuseIntensity
          {
            sliderDiffuseLightIntensitity.doubleValue = renderAtomDiffuseIntensity
          }
        }
      }
      if let diffuseColor: NSColorWell = view.viewWithTag(47) as? NSColorWell
      {
        diffuseColor.isEnabled = false
        diffuseColor.color = NSColor.lightGray
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          diffuseColor.isEnabled = enabled
          if let renderAtomDiffuseColor: NSColor = representedStructure.renderAtomDiffuseColor
          {
            diffuseColor.color = renderAtomDiffuseColor
          }
          else
          {
            diffuseColor.color = NSColor.lightGray
          }
        }
      }
      
      // Atom specular light
      if let specularLightIntensitity: NSTextField = view.viewWithTag(48) as? NSTextField
      {
        specularLightIntensitity.isEditable = false
        specularLightIntensitity.stringValue = ""
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
          
        {
          specularLightIntensitity.isEditable = enabled
          if let renderAtomSpecularIntensity: Double = representedStructure.renderAtomSpecularIntensity
          {
            specularLightIntensitity.doubleValue = renderAtomSpecularIntensity
          }
          else
          {
            specularLightIntensitity.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderSpecularLightIntensitity: NSSlider = view.viewWithTag(49) as? NSSlider
      {
        sliderSpecularLightIntensitity.isEnabled = false
        sliderSpecularLightIntensitity.minValue = 0.0
        sliderSpecularLightIntensitity.maxValue = 1.0
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          sliderSpecularLightIntensitity.isEnabled = enabled
          if let renderAtomSpecularIntensity: Double = representedStructure.renderAtomSpecularIntensity
          {
            sliderSpecularLightIntensitity.doubleValue = renderAtomSpecularIntensity
          }
        }
      }
      if let specularColor: NSColorWell = view.viewWithTag(50) as? NSColorWell
      {
        specularColor.isEnabled = false
        specularColor.color = NSColor.lightGray
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          specularColor.isEnabled = enabled
          if let renderAtomSpecularColor: NSColor = representedStructure.renderAtomSpecularColor
          {
            specularColor.color = renderAtomSpecularColor
          }
        }
      }
      
      // Atom specular shininess
      if let shininess: NSTextField = view.viewWithTag(51) as? NSTextField
      {
        shininess.isEditable = false
        shininess.stringValue = ""
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          shininess.isEditable = enabled
          if let renderAtomShininess: Double = representedStructure.renderAtomShininess
          {
            shininess.doubleValue = renderAtomShininess
          }
          else
          {
            shininess.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderShininess: NSSlider = view.viewWithTag(52) as? NSSlider
      {
        sliderShininess.isEnabled = false
        sliderShininess.minValue = 0.1
        sliderShininess.maxValue = 128.0
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          sliderShininess.isEnabled = enabled
          if let renderAtomShininess: Double = representedStructure.renderAtomShininess
          {
            sliderShininess.doubleValue = renderAtomShininess
          }
        }
      }
    default:
      break
    }
  }
  
  func setPropertiesBondTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    switch(identifier)
    {
    case "BondsVisualAppearanceCell":
      // Draw bonds yes/no
      if let checkDrawBondsbutton: NSButton = view.viewWithTag(1) as? NSButton
      {
        checkDrawBondsbutton.isEnabled = false
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          checkDrawBondsbutton.isEnabled = enabled
          if let renderDrawBonds: Bool = representedStructure.renderDrawBonds
          {
            checkDrawBondsbutton.allowsMixedState = false
            checkDrawBondsbutton.state = renderDrawBonds ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            checkDrawBondsbutton.allowsMixedState = true
            checkDrawBondsbutton.state = NSControl.StateValue.mixed
          }
        }
      }
      
      // Bond scaling
      if let textFieldBondScaling: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldBondScaling.isEditable = false
        textFieldBondScaling.stringValue = ""
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          textFieldBondScaling.isEditable = enabled
          if let renderBondScaleFactor: Double = representedStructure.renderBondScaleFactor
          {
            textFieldBondScaling.doubleValue = renderBondScaleFactor
          }
        }
      }
      if let sliderBondScaling: NSSlider = view.viewWithTag(3) as? NSSlider
      {
        sliderBondScaling.isEnabled = false
        sliderBondScaling.minValue = 0.1
        sliderBondScaling.maxValue = 1.0
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          sliderBondScaling.isEnabled = enabled
          if let renderBondScaleFactor: Double = representedStructure.renderBondScaleFactor
          {
            sliderBondScaling.doubleValue = renderBondScaleFactor
          }
        }
      }
      
      // Bond color mode
      if let popUpbuttonBondColorMode: iRASPAPopUpButton = view.viewWithTag(4) as? iRASPAPopUpButton
      {
        popUpbuttonBondColorMode.isEditable = false
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          popUpbuttonBondColorMode.isEditable = enabled
          if let rawValue: Int = representedStructure.renderBondColorMode?.rawValue
          {
            popUpbuttonBondColorMode.selectItem(at: rawValue)
          }
        }
      }
    case "BondsSelectionCell":
      // Selection-style
      if let popUpbuttonSelectionStyle: iRASPAPopUpButton = view.viewWithTag(1117) as? iRASPAPopUpButton,
         let textFieldSelectionFrequency: NSTextField = view.viewWithTag(1118) as? NSTextField,
         let textFieldSelectionDensity: NSTextField = view.viewWithTag(1110) as? NSTextField
      {
        popUpbuttonSelectionStyle.isEditable = false
        textFieldSelectionFrequency.isEditable = false
        textFieldSelectionFrequency.stringValue = ""
        textFieldSelectionDensity.isEditable = false
        textFieldSelectionDensity.stringValue = ""
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          popUpbuttonSelectionStyle.isEditable = enabled
          textFieldSelectionFrequency.isEditable = enabled
          textFieldSelectionDensity.isEditable = enabled
          
          if let selectionStyle: RKSelectionStyle = representedStructure.renderBondSelectionStyle
          {
            popUpbuttonSelectionStyle.removeItem(withTitle: "Multiple Values")
            popUpbuttonSelectionStyle.selectItem(at: selectionStyle.rawValue)
            
            if selectionStyle == .glow
            {
              textFieldSelectionFrequency.isEditable = false
              textFieldSelectionDensity.isEditable = false
            }
          }
          else
          {
            popUpbuttonSelectionStyle.setTitle("Multiple Values")
            textFieldSelectionFrequency.stringValue = "Mult. Val."
            textFieldSelectionDensity.stringValue = "Mult. Val."
          }
          
          if let renderSelectionFrequency: Double = representedStructure.renderBondSelectionFrequency
          {
            textFieldSelectionFrequency.doubleValue = renderSelectionFrequency
          }
          else
          {
            textFieldSelectionFrequency.stringValue = "Mult. Val."
          }
          
          if let renderSelectionDensity: Double = representedStructure.renderBondSelectionDensity
          {
            textFieldSelectionDensity.doubleValue = renderSelectionDensity
          }
          else
          {
            textFieldSelectionDensity.stringValue = "Mult. Val."
          }
        }
      }
      
      if let textFieldBondSelectionIntensityLevel: NSTextField = view.viewWithTag(1134) as? NSTextField
        {
          textFieldBondSelectionIntensityLevel.isEditable = false
          textFieldBondSelectionIntensityLevel.stringValue = ""
          if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
          {
            textFieldBondSelectionIntensityLevel.isEditable = enabled
            if let renderBondSelectionIntensityLevel: Double = representedStructure.renderBondSelectionIntensity
            {
              textFieldBondSelectionIntensityLevel.doubleValue = renderBondSelectionIntensityLevel
            }
            else
            {
              textFieldBondSelectionIntensityLevel.stringValue = "Multiple Values"
            }
          }
        }
        
        if let sliderBondSelectionIntensityLevel: NSSlider = view.viewWithTag(1135) as? NSSlider
        {
          sliderBondSelectionIntensityLevel.isEnabled = false
          sliderBondSelectionIntensityLevel.minValue = 0.0
          sliderBondSelectionIntensityLevel.maxValue = 2.0
          if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
          {
            sliderBondSelectionIntensityLevel.isEnabled = enabled
            if let renderBondSelectionIntensityLevel: Double = representedStructure.renderBondSelectionIntensity
            {
              sliderBondSelectionIntensityLevel.doubleValue = renderBondSelectionIntensityLevel
            }
          }
        }
        
      
        if let textFieldBondSelectionScaling: NSTextField = view.viewWithTag(1181) as? NSTextField
        {
          textFieldBondSelectionScaling.isEditable = false
          textFieldBondSelectionScaling.stringValue = ""
          if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
          {
            textFieldBondSelectionScaling.isEditable = enabled
            if let renderBondSelectionScaling: Double = representedStructure.renderBondSelectionScaling
            {
              textFieldBondSelectionScaling.doubleValue = renderBondSelectionScaling
            }
            else
            {
              textFieldBondSelectionScaling.stringValue = "Multiple Values"
            }
          }
        }
        if let sliderBondSelectionScaling: NSSlider = view.viewWithTag(1182) as? NSSlider
        {
          sliderBondSelectionScaling.isEnabled = false
          sliderBondSelectionScaling.minValue = 1.0
          sliderBondSelectionScaling.maxValue = 2.0
          if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
          {
            sliderBondSelectionScaling.isEnabled = enabled
            if let renderBondSelectionScaling: Double = representedStructure.renderBondSelectionScaling
            {
              sliderBondSelectionScaling.doubleValue = renderBondSelectionScaling
            }
          }
        }
    case "BondsHDRCell":
      // Use High Dynamic Range yes/no
      if let checkDrawHDRButton: NSButton = view.viewWithTag(10) as? NSButton
      {
        checkDrawHDRButton.isEnabled = false
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          checkDrawHDRButton.isEnabled = enabled
          if let renderHighDynamicRange: Bool = representedStructure.renderBondHDR
          {
            checkDrawHDRButton.allowsMixedState = false
            checkDrawHDRButton.state = renderHighDynamicRange ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            checkDrawHDRButton.allowsMixedState = true
            checkDrawHDRButton.state = NSControl.StateValue.mixed
          }
        }
      }
      
      
      // Exposure
      if let textFieldExposure: NSTextField = view.viewWithTag(11) as? NSTextField
      {
        textFieldExposure.isEditable = false
        textFieldExposure.stringValue = ""
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          textFieldExposure.isEditable = enabled
          if let renderBondHDRExposure: Double = representedStructure.renderBondHDRExposure
          {
            textFieldExposure.doubleValue = renderBondHDRExposure
          }
        }
      }
      if let sliderExposure: NSSlider = view.viewWithTag(12) as? NSSlider
      {
        sliderExposure.isEnabled = false
        sliderExposure.minValue = 0.0
        sliderExposure.maxValue = 3.0
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          sliderExposure.isEnabled = enabled
          if let renderBondHDRExposure: Double = representedStructure.renderBondHDRExposure
          {
            sliderExposure.doubleValue = renderBondHDRExposure
          }
        }
      }
      
      // Hue
      if let textFieldHue: NSTextField = view.viewWithTag(13) as? NSTextField
      {
        textFieldHue.isEditable = false
        textFieldHue.stringValue = ""
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          textFieldHue.isEditable = enabled
          if let renderBondHue: Double = representedStructure.renderBondHue
          {
            textFieldHue.doubleValue = renderBondHue
          }
        }
      }
      if let sliderHue: NSSlider = view.viewWithTag(14) as? NSSlider
      {
        sliderHue.isEnabled = false
        sliderHue.minValue = 0.0
        sliderHue.maxValue = 1.5
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          sliderHue.isEnabled = enabled
          if let renderBondHue: Double = representedStructure.renderBondHue
          {
            sliderHue.doubleValue = renderBondHue
          }
        }
      }
      
      // Saturation
      if let textFieldSaturation: NSTextField = view.viewWithTag(15) as? NSTextField
      {
        textFieldSaturation.isEditable = false
        textFieldSaturation.stringValue = ""
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          textFieldSaturation.isEditable = enabled
          if let renderBondSaturation: Double = representedStructure.renderBondSaturation
          {
            textFieldSaturation.doubleValue = renderBondSaturation
          }
        }
      }
      if let sliderSaturation: NSSlider = view.viewWithTag(16) as? NSSlider
      {
        sliderSaturation.isEnabled = false
        sliderSaturation.minValue = 0.0
        sliderSaturation.maxValue = 1.5
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          sliderSaturation.isEnabled = enabled
          if let renderBondSaturation: Double = representedStructure.renderBondSaturation
          {
            sliderSaturation.doubleValue = renderBondSaturation
          }
        }
      }
      
      // Value
      if let textFieldValue: NSTextField = view.viewWithTag(17) as? NSTextField
      {
        textFieldValue.isEditable = false
        textFieldValue.stringValue = ""
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          textFieldValue.isEditable = enabled
          if let renderBondValue: Double = representedStructure.renderBondValue
          {
            textFieldValue.doubleValue = renderBondValue
          }
        }
      }
      if let sliderValue: NSSlider = view.viewWithTag(18) as? NSSlider
      {
        sliderValue.isEnabled = false
        sliderValue.minValue = 0.0
        sliderValue.maxValue = 1.5
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          sliderValue.isEnabled = enabled
          if let renderBondValue: Double = representedStructure.renderBondValue
          {
            sliderValue.doubleValue = renderBondValue
          }
        }
      }
      
    case "BondsLightingCell":
      // Use ambient occlusion yes/no
      if let buttonAmbientOcclusion: NSButton = view.viewWithTag(30) as? NSButton
      {
        buttonAmbientOcclusion.isEnabled = false
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          buttonAmbientOcclusion.isEnabled = enabled
          
          if let renderBondAmbientOcclusion: Bool = representedStructure.renderBondAmbientOcclusion
          {
            buttonAmbientOcclusion.allowsMixedState = false
            buttonAmbientOcclusion.state = renderBondAmbientOcclusion ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            buttonAmbientOcclusion.allowsMixedState = true
            buttonAmbientOcclusion.state = NSControl.StateValue.mixed
          }
        }
        
        buttonAmbientOcclusion.isEnabled = false
      }
      
      // Atom ambient light
      if let ambientLightIntensitity: NSTextField = view.viewWithTag(31) as? NSTextField
      {
        ambientLightIntensitity.isEditable = false
        ambientLightIntensitity.stringValue = ""
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          ambientLightIntensitity.isEditable = enabled
          if let renderBondAmbientIntensity: Double = representedStructure.renderBondAmbientIntensity
          {
            ambientLightIntensitity.doubleValue = renderBondAmbientIntensity
          }
        }
      }
      if let sliderAmbientLightIntensitity: NSSlider = view.viewWithTag(32) as? NSSlider
      {
        sliderAmbientLightIntensitity.isEnabled = false
        sliderAmbientLightIntensitity.minValue = 0.0
        sliderAmbientLightIntensitity.maxValue = 1.0
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          sliderAmbientLightIntensitity.isEnabled = enabled
          if let renderBondAmbientIntensity: Double = representedStructure.renderBondAmbientIntensity
          {
            sliderAmbientLightIntensitity.doubleValue = renderBondAmbientIntensity
          }
        }
      }
      if let ambientColor: NSColorWell = view.viewWithTag(33) as? NSColorWell
      {
        ambientColor.isEnabled = false
        ambientColor.color = NSColor.lightGray
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          ambientColor.isEnabled = enabled
          if let renderBondAmbientColor: NSColor = representedStructure.renderBondAmbientColor
          {
            ambientColor.color = renderBondAmbientColor
          }
        }
      }
      
      // Bond diffuse light
      if let diffuseLightIntensitity: NSTextField = view.viewWithTag(34) as? NSTextField
      {
        diffuseLightIntensitity.isEditable = false
        diffuseLightIntensitity.stringValue = ""
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          diffuseLightIntensitity.isEditable = enabled
          if let renderBondDiffuseIntensity: Double = representedStructure.renderBondDiffuseIntensity
          {
            diffuseLightIntensitity.doubleValue = renderBondDiffuseIntensity
          }
        }
      }
      if let sliderDiffuseLightIntensitity: NSSlider = view.viewWithTag(35) as? NSSlider
      {
        sliderDiffuseLightIntensitity.isEnabled = false
        sliderDiffuseLightIntensitity.minValue = 0.0
        sliderDiffuseLightIntensitity.maxValue = 1.0
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          sliderDiffuseLightIntensitity.isEnabled = enabled
          if let renderBondDiffuseIntensity: Double = representedStructure.renderBondDiffuseIntensity
          {
            sliderDiffuseLightIntensitity.doubleValue = renderBondDiffuseIntensity
          }
        }
      }
      if let diffuseColor: NSColorWell = view.viewWithTag(36) as? NSColorWell
      {
        diffuseColor.isEnabled = false
        diffuseColor.color = NSColor.lightGray
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          diffuseColor.isEnabled = enabled
          if let renderBondDiffuseColor: NSColor = representedStructure.renderBondDiffuseColor
          {
            diffuseColor.color = renderBondDiffuseColor
          }
        }
      }
      
      // Atom specular light
      if let specularLightIntensitity: NSTextField = view.viewWithTag(37) as? NSTextField
      {
        specularLightIntensitity.isEditable = false
        specularLightIntensitity.stringValue = ""
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          specularLightIntensitity.isEditable = enabled
          if let renderBondSpecularIntensity: Double = representedStructure.renderBondSpecularIntensity
          {
            specularLightIntensitity.doubleValue = renderBondSpecularIntensity
          }
        }
      }
      if let sliderSpecularLightIntensitity: NSSlider = view.viewWithTag(38) as? NSSlider
      {
        sliderSpecularLightIntensitity.isEnabled = false
        sliderSpecularLightIntensitity.minValue = 0.0
        sliderSpecularLightIntensitity.maxValue = 1.0
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          sliderSpecularLightIntensitity.isEnabled = enabled
          if let renderBondSpecularIntensity: Double = representedStructure.renderBondSpecularIntensity
          {
            sliderSpecularLightIntensitity.doubleValue = renderBondSpecularIntensity
          }
        }
      }
      if let specularColor: NSColorWell = view.viewWithTag(39) as? NSColorWell
      {
        specularColor.isEnabled = false
        specularColor.color = NSColor.lightGray
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          specularColor.isEnabled = enabled
          if let renderBondSpecularColor: NSColor = representedStructure.renderBondSpecularColor
          {
            specularColor.color = renderBondSpecularColor
          }
        }
      }
      
      // Bond specular shininess
      if let shininess: NSTextField = view.viewWithTag(40) as? NSTextField
      {
        shininess.isEditable = false
        shininess.stringValue = ""
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          shininess.isEditable = enabled
          if let renderBondShininess: Double = representedStructure.renderBondShininess
          {
            shininess.doubleValue = renderBondShininess
          }
        }
      }
      if let sliderShininess: NSSlider = view.viewWithTag(41) as? NSSlider
      {
        sliderShininess.isEnabled = false
        sliderShininess.minValue = 0.1
        sliderShininess.maxValue = 128.0
        if let representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
        {
          sliderShininess.isEnabled = enabled
          if let renderBondShininess: Double = representedStructure.renderBondShininess
          {
            sliderShininess.doubleValue = renderBondShininess
          }
        }
      }
    
    default:
      break
    }
  }
  
  func setPropertiesUnitCellTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    switch(identifier)
    {
    case "UnitCellScalingCell":
      // Use unit cell yes/no
      if let checkDrawUnitCellButton: NSButton = view.viewWithTag(1) as? NSButton
      {
        checkDrawUnitCellButton.isEnabled = false
        if let representedStructure: [UnitCellVisualAppearanceViewer] = representedObject as? [UnitCellVisualAppearanceViewer]
        {
          checkDrawUnitCellButton.isEnabled = enabled
          
          if let renderDrawUnitCell: Bool = representedStructure.renderDrawUnitCell
          {
            checkDrawUnitCellButton.allowsMixedState = false
            checkDrawUnitCellButton.state = renderDrawUnitCell ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            checkDrawUnitCellButton.allowsMixedState = true
            checkDrawUnitCellButton.state = NSControl.StateValue.mixed
          }
        }
      }
      
      
      // Atom specular shininess
      if let unitCellScaling: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        unitCellScaling.isEditable = false
        unitCellScaling.stringValue = ""
        if let representedStructure: [UnitCellVisualAppearanceViewer] = representedObject as? [UnitCellVisualAppearanceViewer]
        {
          unitCellScaling.isEditable = enabled
          if let renderUnitCellScaleFactor: Double = representedStructure.renderUnitCellScaleFactor
          {
            unitCellScaling.doubleValue = renderUnitCellScaleFactor
          }
        }
      }
      if let sliderUnitCellScaling: NSSlider = view.viewWithTag(3) as? NSSlider
      {
        sliderUnitCellScaling.isEnabled = false
        sliderUnitCellScaling.minValue = 0.0
        sliderUnitCellScaling.maxValue = 2.0
        if let representedStructure: [UnitCellVisualAppearanceViewer] = representedObject as? [UnitCellVisualAppearanceViewer]
        {
          sliderUnitCellScaling.isEnabled = enabled
          if let renderUnitCellScaleFactor: Double = representedStructure.renderUnitCellScaleFactor
          {
            sliderUnitCellScaling.doubleValue = renderUnitCellScaleFactor
          }
        }
      }
      
      
      // Unit cell light intensity
      if let unitCellLightIntensitity: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        unitCellLightIntensitity.isEditable = false
        unitCellLightIntensitity.stringValue = ""
        if let representedStructure: [UnitCellVisualAppearanceViewer] = representedObject as? [UnitCellVisualAppearanceViewer]
        {
          unitCellLightIntensitity.isEditable = enabled
          if let renderUnitCellDiffuseIntensity: Double = representedStructure.renderUnitCellDiffuseIntensity
          {
            unitCellLightIntensitity.doubleValue = renderUnitCellDiffuseIntensity
          }
        }
      }
      if let sliderUnitCellLightIntensitity: NSSlider = view.viewWithTag(5) as? NSSlider
      {
        sliderUnitCellLightIntensitity.isEnabled = false
        sliderUnitCellLightIntensitity.minValue = 0.0
        sliderUnitCellLightIntensitity.maxValue = 1.0
        if let representedStructure: [UnitCellVisualAppearanceViewer] = representedObject as? [UnitCellVisualAppearanceViewer]
        {
          sliderUnitCellLightIntensitity.isEnabled = enabled
          if let renderUnitCellDiffuseIntensity: Double = representedStructure.renderUnitCellDiffuseIntensity
          {
            sliderUnitCellLightIntensitity.doubleValue = renderUnitCellDiffuseIntensity
          }
        }
      }
      if let unitCellColor: NSColorWell = view.viewWithTag(6) as? NSColorWell
      {
        unitCellColor.isEnabled = false
        unitCellColor.color = NSColor.lightGray
        if let representedStructure: [UnitCellVisualAppearanceViewer] = representedObject as? [UnitCellVisualAppearanceViewer]
        {
          unitCellColor.isEnabled = enabled
          if let renderUnitCellDiffuseColor: NSColor = representedStructure.renderUnitCellDiffuseColor
          {
            unitCellColor.color = renderUnitCellDiffuseColor
          }
        }
      }
    default:
      break
    }
  }
  
  func setPropertiesAdsorptionTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    var adsorptionSurfaceOn: Bool = false
    if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      adsorptionSurfaceOn = representedStructure.renderAdsorptionSurfaceOn ?? false
    }
    
    switch(identifier)
    {
    case "AdsorptionPropertiesCell":
      // Use unit cell yes/no
      if let checkDrawAdsorptionSurfacebutton: NSButton = view.viewWithTag(1) as? NSButton
      {
        checkDrawAdsorptionSurfacebutton.isEnabled = false
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer], representedStructure.renderCanDrawAdsorptionSurface
        {
          checkDrawAdsorptionSurfacebutton.isEnabled = enabled
          
          if let renderDrawAdsorptionSurface: Bool = representedStructure.renderAdsorptionSurfaceOn
          {
            checkDrawAdsorptionSurfacebutton.allowsMixedState = false
            checkDrawAdsorptionSurfacebutton.state = renderDrawAdsorptionSurface ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            checkDrawAdsorptionSurfacebutton.allowsMixedState = true
            checkDrawAdsorptionSurfacebutton.state = NSControl.StateValue.mixed
          }
        }
      }
      
      
      
      // Probe molecule
      if let popUpbuttonProbeParticle: iRASPAPopUpButton = view.viewWithTag(2) as? iRASPAPopUpButton
      {
        popUpbuttonProbeParticle.isEditable = false
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          popUpbuttonProbeParticle.isEditable = enabled && adsorptionSurfaceOn
          if let probeMolecule: Structure.ProbeMolecule = representedStructure.renderAdsorptionSurfaceProbeMolecule
          {
            popUpbuttonProbeParticle.selectItem(at: probeMolecule.rawValue)
          }
        }
      }
      
      
      if let textFieldIsovalue: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldIsovalue.isEditable = false
        textFieldIsovalue.stringValue = ""
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          textFieldIsovalue.isEditable = enabled && adsorptionSurfaceOn
          if let isovalue = representedStructure.renderAdsorptionSurfaceIsovalue
          {
            textFieldIsovalue.doubleValue = isovalue
          }
          else
          {
            textFieldIsovalue.stringValue = "Mult. Val."
          }
        }
      }
      if let sliderIsovalue: NSSlider = view.viewWithTag(4) as? NSSlider
      {
        sliderIsovalue.isEnabled = false
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          sliderIsovalue.isEnabled = enabled && adsorptionSurfaceOn
          if let isovalue = representedStructure.renderAdsorptionSurfaceIsovalue
          {
            sliderIsovalue.minValue = Double(representedStructure.renderMinimumGridEnergyValue ?? -1000.0)
            sliderIsovalue.maxValue = 0.0
            sliderIsovalue.doubleValue = isovalue
          }
        }
      }
      
      
      if let textFieldOpacity: NSTextField = view.viewWithTag(5) as? NSTextField
      {
        textFieldOpacity.isEditable = false
        textFieldOpacity.stringValue = ""
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          textFieldOpacity.isEditable = enabled && adsorptionSurfaceOn
          if let opacity = representedStructure.renderAdsorptionSurfaceOpacity
          {
            textFieldOpacity.doubleValue = opacity
          }
          else
          {
            textFieldOpacity.stringValue = "Mult. Val."
          }
        }
      }
      if let sliderOpacity: NSSlider = view.viewWithTag(6) as? NSSlider
      {
        sliderOpacity.isEnabled = false
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          sliderOpacity.isEnabled = enabled && adsorptionSurfaceOn
          if let opacity = representedStructure.renderAdsorptionSurfaceOpacity
          {
            sliderOpacity.minValue = 0.0
            sliderOpacity.maxValue = 1.0
            sliderOpacity.doubleValue = opacity
          }
          else
          {
            sliderOpacity.minValue = 0.0
            sliderOpacity.maxValue = 1.0
            sliderOpacity.doubleValue = 0.5
          }
        }
      }
      
      if let popUpbuttonSurfaceSize: iRASPAPopUpButton = view.viewWithTag(207) as? iRASPAPopUpButton
      {
        popUpbuttonSurfaceSize.isEditable = false
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          popUpbuttonSurfaceSize.isEditable = enabled && adsorptionSurfaceOn
          if let structureSize: Int = representedStructure.renderAdsorptionSurfaceSize
          {
            popUpbuttonSurfaceSize.removeItem(withTitle: "Multiple Values")
            popUpbuttonSurfaceSize.selectItem(withTitle: "\(structureSize)x\(structureSize)x\(structureSize)")
          }
          else
          {
            popUpbuttonSurfaceSize.setTitle("Multiple Values")
          }
        }
      }
      
    case "AdsorptionHSVCell":
      // Hue
      if let textFieldHue: NSTextField = view.viewWithTag(4413) as? NSTextField
      {
        textFieldHue.isEditable = false
        textFieldHue.stringValue = ""
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          textFieldHue.isEditable = enabled
          if let renderAdsorptionSurfaceHue: Double = representedStructure.renderAdsorptionSurfaceHue
          {
            textFieldHue.doubleValue = renderAdsorptionSurfaceHue
          }
        }
      }
      if let sliderHue: NSSlider = view.viewWithTag(4414) as? NSSlider
      {
        sliderHue.isEnabled = false
        sliderHue.minValue = 0.0
        sliderHue.maxValue = 1.5
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          sliderHue.isEnabled = enabled
          if let renderAdsorptionSurfaceHue: Double = representedStructure.renderAdsorptionSurfaceHue
          {
            sliderHue.doubleValue = renderAdsorptionSurfaceHue
          }
        }
      }
      
      // Saturation
      if let textFieldSaturation: NSTextField = view.viewWithTag(4415) as? NSTextField
      {
        textFieldSaturation.isEditable = false
        textFieldSaturation.stringValue = ""
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          textFieldSaturation.isEditable = enabled
          if let renderAdsorptionSurfaceSaturation: Double = representedStructure.renderAdsorptionSurfaceSaturation
          {
            textFieldSaturation.doubleValue = renderAdsorptionSurfaceSaturation
          }
        }
      }
      if let sliderSaturation: NSSlider = view.viewWithTag(4416) as? NSSlider
      {
        sliderSaturation.isEnabled = false
        sliderSaturation.minValue = 0.0
        sliderSaturation.maxValue = 1.5
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          sliderSaturation.isEnabled = enabled
          if let renderAdsorptionSurfaceSaturation: Double = representedStructure.renderAdsorptionSurfaceSaturation
          {
            sliderSaturation.doubleValue = renderAdsorptionSurfaceSaturation
          }
        }
      }
      
      // Value
      if let textFieldValue: NSTextField = view.viewWithTag(4417) as? NSTextField
      {
        textFieldValue.isEditable = false
        textFieldValue.stringValue = ""
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          textFieldValue.isEditable = enabled
          if let renderAdsorptionSurfaceValue: Double = representedStructure.renderAdsorptionSurfaceValue
          {
            textFieldValue.doubleValue = renderAdsorptionSurfaceValue
          }
        }
      }
      if let sliderValue: NSSlider = view.viewWithTag(4418) as? NSSlider
      {
        sliderValue.isEnabled = false
        sliderValue.minValue = 0.0
        sliderValue.maxValue = 1.5
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          sliderValue.isEnabled = enabled
          if let renderAdsorptionSurfaceValue: Double = representedStructure.renderAdsorptionSurfaceValue
          {
            sliderValue.doubleValue = renderAdsorptionSurfaceValue
          }
        }
      }
      
      
    case "AdsorptionFrontSurfaceCell":
      // High dynamic range
      if let button: NSButton = view.viewWithTag(7) as? NSButton
      {
        button.isEnabled = false
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          button.isEnabled = enabled && adsorptionSurfaceOn
          
          if let renderAdsorptionSurfaceHDR: Bool = representedStructure.renderAdsorptionSurfaceFrontSideHDR
          {
            button.allowsMixedState = false
            button.state = renderAdsorptionSurfaceHDR ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            button.allowsMixedState = true
            button.state = NSControl.StateValue.mixed
          }
        }
      }
      
      // Exposure
      if let textFieldExposure: NSTextField = view.viewWithTag(8) as? NSTextField
      {
        textFieldExposure.isEditable = false
        textFieldExposure.stringValue = ""
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          textFieldExposure.isEditable = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceFrontSideHDRExposure: Double = representedStructure.renderAdsorptionSurfaceFrontSideHDRExposure
          {
            textFieldExposure.doubleValue = renderAdsorptionSurfaceFrontSideHDRExposure
          }
          else
          {
            textFieldExposure.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderExposure: NSSlider = view.viewWithTag(9) as? NSSlider
      {
        sliderExposure.isEnabled = false
        sliderExposure.minValue = 0.0
        sliderExposure.maxValue = 3.0
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          sliderExposure.isEnabled = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceFrontSideHDRExposure: Double = representedStructure.renderAdsorptionSurfaceFrontSideHDRExposure
          {
            sliderExposure.doubleValue = renderAdsorptionSurfaceFrontSideHDRExposure
          }
        }
      }
      
      
      // ambient intensity and color
      if let textFieldFrontAmbientIntensity: NSTextField = view.viewWithTag(10) as? NSTextField
      {
        textFieldFrontAmbientIntensity.isEditable = false
        textFieldFrontAmbientIntensity.stringValue = ""
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          textFieldFrontAmbientIntensity.isEditable = enabled && adsorptionSurfaceOn
          if let ambientIntensity = representedStructure.renderAdsorptionSurfaceFrontSideAmbientIntensity
          {
            textFieldFrontAmbientIntensity.doubleValue = ambientIntensity
          }
          else
          {
            textFieldFrontAmbientIntensity.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderFrontAmbientIntensity: NSSlider = view.viewWithTag(11) as? NSSlider
      {
        sliderFrontAmbientIntensity.isEnabled = false
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          sliderFrontAmbientIntensity.isEnabled = enabled && adsorptionSurfaceOn
          if let ambientIntensity = representedStructure.renderAdsorptionSurfaceFrontSideAmbientIntensity
          {
            sliderFrontAmbientIntensity.minValue = 0.0
            sliderFrontAmbientIntensity.maxValue = 1.0
            sliderFrontAmbientIntensity.doubleValue = ambientIntensity
          }
        }
      }
      if let ambientFrontSideColor: NSColorWell = view.viewWithTag(12) as? NSColorWell
      {
        ambientFrontSideColor.isEnabled = false
        ambientFrontSideColor.color = NSColor.lightGray
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          ambientFrontSideColor.isEnabled = enabled && adsorptionSurfaceOn
          if let color = representedStructure.renderAdsorptionSurfaceFrontSideAmbientColor
          {
            ambientFrontSideColor.color = color
          }
        }
      }
      
      // diffuse intensity and color
      if let textFieldFrontDiffuseIntensity: NSTextField = view.viewWithTag(13) as? NSTextField
      {
        textFieldFrontDiffuseIntensity.isEditable = false
        textFieldFrontDiffuseIntensity.stringValue = ""
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          textFieldFrontDiffuseIntensity.isEditable = enabled && adsorptionSurfaceOn
          if let diffuseIntensity = representedStructure.renderAdsorptionSurfaceFrontSideDiffuseIntensity
          {
            textFieldFrontDiffuseIntensity.doubleValue = diffuseIntensity
          }
          else
          {
            textFieldFrontDiffuseIntensity.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderFrontDiffuseIntensity: NSSlider = view.viewWithTag(14) as? NSSlider
      {
        sliderFrontDiffuseIntensity.isEnabled = false
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          sliderFrontDiffuseIntensity.isEnabled = enabled && adsorptionSurfaceOn
          if let diffuseIntensity = representedStructure.renderAdsorptionSurfaceFrontSideDiffuseIntensity
          {
            sliderFrontDiffuseIntensity.minValue = 0.0
            sliderFrontDiffuseIntensity.maxValue = 1.0
            sliderFrontDiffuseIntensity.doubleValue = diffuseIntensity
          }
        }
      }
      if let diffuseFrontSideColor: NSColorWell = view.viewWithTag(15) as? NSColorWell
      {
        diffuseFrontSideColor.isEnabled = false
        diffuseFrontSideColor.color = NSColor.lightGray
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          diffuseFrontSideColor.isEnabled = enabled && adsorptionSurfaceOn
          if let color = representedStructure.renderAdsorptionSurfaceFrontSideDiffuseColor
          {
            diffuseFrontSideColor.color = color
          }
        }
      }
      
      // specular intensity and color
      if let textFieldFrontSpecularIntensity: NSTextField = view.viewWithTag(16) as? NSTextField
      {
        textFieldFrontSpecularIntensity.isEditable = false
        textFieldFrontSpecularIntensity.stringValue = ""
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          textFieldFrontSpecularIntensity.isEditable = enabled && adsorptionSurfaceOn
          if let specularIntensity = representedStructure.renderAdsorptionSurfaceFrontSideSpecularIntensity
          {
            textFieldFrontSpecularIntensity.doubleValue = specularIntensity
          }
          else
          {
            textFieldFrontSpecularIntensity.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderFrontSpecularIntensity: NSSlider = view.viewWithTag(17) as? NSSlider
      {
        sliderFrontSpecularIntensity.isEnabled = false
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          sliderFrontSpecularIntensity.isEnabled = enabled && adsorptionSurfaceOn
          if let specularIntensity = representedStructure.renderAdsorptionSurfaceFrontSideSpecularIntensity
          {
            sliderFrontSpecularIntensity.minValue = 0.0
            sliderFrontSpecularIntensity.maxValue = 1.0
            sliderFrontSpecularIntensity.doubleValue = specularIntensity
          }
        }
      }
      if let specularFrontSideColor: NSColorWell = view.viewWithTag(18) as? NSColorWell
      {
        specularFrontSideColor.isEnabled = false
        specularFrontSideColor.color = NSColor.lightGray
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          specularFrontSideColor.isEnabled = enabled && adsorptionSurfaceOn
          if let color = representedStructure.renderAdsorptionSurfaceFrontSideSpecularColor
          {
            specularFrontSideColor.color = color
          }
        }
      }
      
      
      
      if let textFieldFrontShininess: NSTextField = view.viewWithTag(19) as? NSTextField
      {
        textFieldFrontShininess.isEditable = false
        textFieldFrontShininess.stringValue = ""
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          textFieldFrontShininess.isEditable = enabled && adsorptionSurfaceOn
          if let shininess = representedStructure.renderAdsorptionSurfaceFrontSideShininess
          {
            textFieldFrontShininess.doubleValue = shininess
          }
          else
          {
            textFieldFrontShininess.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderFrontShininess: NSSlider = view.viewWithTag(20) as? NSSlider
      {
        sliderFrontShininess.isEnabled = false
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          sliderFrontShininess.isEnabled = enabled && adsorptionSurfaceOn
          if let shininess = representedStructure.renderAdsorptionSurfaceFrontSideShininess
          {
            sliderFrontShininess.minValue = 0.0
            sliderFrontShininess.maxValue = 256.0
            sliderFrontShininess.doubleValue = shininess
          }
        }
      }
      
    case "AdsorptionBackSurfaceCell":
      
      // High dynamic range
      if let button: NSButton = view.viewWithTag(21) as? NSButton
      {
        button.isEnabled = false
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          button.isEnabled = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceHDR: Bool = representedStructure.renderAdsorptionSurfaceBackSideHDR
          {
            button.allowsMixedState = false
            button.state = renderAdsorptionSurfaceHDR ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            button.allowsMixedState = true
            button.state = NSControl.StateValue.mixed
          }
        }
      }
      
      // Exposure
      if let textFieldExposure: NSTextField = view.viewWithTag(22) as? NSTextField
      {
        textFieldExposure.isEditable = false
        textFieldExposure.stringValue = ""
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          textFieldExposure.isEditable = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceBackSideHDRExposure: Double = representedStructure.renderAdsorptionSurfaceBackSideHDRExposure
          {
            textFieldExposure.doubleValue = renderAdsorptionSurfaceBackSideHDRExposure
          }
          else
          {
            textFieldExposure.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderExposure: NSSlider = view.viewWithTag(23) as? NSSlider
      {
        sliderExposure.isEnabled = false
        sliderExposure.minValue = 0.0
        sliderExposure.maxValue = 3.0
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          sliderExposure.isEnabled = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceBackSideHDRExposure: Double = representedStructure.renderAdsorptionSurfaceBackSideHDRExposure
          {
            sliderExposure.doubleValue = renderAdsorptionSurfaceBackSideHDRExposure
          }
        }
      }
      
      
      // Ambient color
      if let textFieldBackAmbientIntensity: NSTextField = view.viewWithTag(24) as? NSTextField
      {
        textFieldBackAmbientIntensity.isEditable = false
        textFieldBackAmbientIntensity.stringValue = ""
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          textFieldBackAmbientIntensity.isEditable = enabled && adsorptionSurfaceOn
          if let ambientIntensity = representedStructure.renderAdsorptionSurfaceBackSideAmbientIntensity
          {
            textFieldBackAmbientIntensity.doubleValue = ambientIntensity
          }
          else
          {
            textFieldBackAmbientIntensity.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderBackAmbientIntensity: NSSlider = view.viewWithTag(25) as? NSSlider
      {
        sliderBackAmbientIntensity.isEnabled = false
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          sliderBackAmbientIntensity.isEnabled = enabled && adsorptionSurfaceOn
          if let ambientIntensity = representedStructure.renderAdsorptionSurfaceBackSideAmbientIntensity
          {
            sliderBackAmbientIntensity.minValue = 0.0
            sliderBackAmbientIntensity.maxValue = 1.0
            sliderBackAmbientIntensity.doubleValue = ambientIntensity
          }
        }
      }
      if let ambientBackSideColor: NSColorWell = view.viewWithTag(26) as? NSColorWell
      {
        ambientBackSideColor.isEnabled = false
        ambientBackSideColor.color = NSColor.lightGray
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          ambientBackSideColor.isEnabled = enabled && adsorptionSurfaceOn
          if let color = representedStructure.renderAdsorptionSurfaceBackSideAmbientColor
          {
            ambientBackSideColor.color = color
          }
        }
      }
      
      // Diffuse color
      if let textFieldBackDiffuseIntensity: NSTextField = view.viewWithTag(27) as? NSTextField
      {
        textFieldBackDiffuseIntensity.isEditable = false
        textFieldBackDiffuseIntensity.stringValue = ""
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          textFieldBackDiffuseIntensity.isEditable = enabled && adsorptionSurfaceOn
          if let diffuseIntensity = representedStructure.renderAdsorptionSurfaceBackSideDiffuseIntensity
          {
            textFieldBackDiffuseIntensity.doubleValue = diffuseIntensity
          }
          else
          {
            textFieldBackDiffuseIntensity.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderBackDiffuseIntensity: NSSlider = view.viewWithTag(28) as? NSSlider
      {
        sliderBackDiffuseIntensity.isEnabled = false
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          sliderBackDiffuseIntensity.isEnabled = enabled && adsorptionSurfaceOn
          if let diffuseIntensity = representedStructure.renderAdsorptionSurfaceBackSideDiffuseIntensity
          {
            sliderBackDiffuseIntensity.minValue = 0.0
            sliderBackDiffuseIntensity.maxValue = 1.0
            sliderBackDiffuseIntensity.doubleValue = diffuseIntensity
          }
        }
      }
      if let diffuseBackSideColor: NSColorWell = view.viewWithTag(29) as? NSColorWell
      {
        diffuseBackSideColor.isEnabled = false
        diffuseBackSideColor.color = NSColor.lightGray
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          diffuseBackSideColor.isEnabled = enabled && adsorptionSurfaceOn
          if let color = representedStructure.renderAdsorptionSurfaceBackSideDiffuseColor
          {
            diffuseBackSideColor.color = color
          }
        }
      }
      
      // Specular color
      if let textFieldBackSpecularIntensity: NSTextField = view.viewWithTag(30) as? NSTextField
      {
        textFieldBackSpecularIntensity.isEditable = false
        textFieldBackSpecularIntensity.stringValue = ""
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          textFieldBackSpecularIntensity.isEditable = enabled && adsorptionSurfaceOn
          if let specularIntensity = representedStructure.renderAdsorptionSurfaceBackSideSpecularIntensity
          {
            textFieldBackSpecularIntensity.doubleValue = specularIntensity
          }
          else
          {
            textFieldBackSpecularIntensity.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderBackSpecularIntensity: NSSlider = view.viewWithTag(31) as? NSSlider
      {
        sliderBackSpecularIntensity.isEnabled = false
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          sliderBackSpecularIntensity.isEnabled = enabled && adsorptionSurfaceOn
          if let specularIntensity = representedStructure.renderAdsorptionSurfaceBackSideSpecularIntensity
          {
            sliderBackSpecularIntensity.minValue = 0.0
            sliderBackSpecularIntensity.maxValue = 1.0
            sliderBackSpecularIntensity.doubleValue = specularIntensity
          }
        }
      }
      if let specularBackSideColor: NSColorWell = view.viewWithTag(32) as? NSColorWell
      {
        specularBackSideColor.isEnabled = false
        specularBackSideColor.color = NSColor.lightGray
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          specularBackSideColor.isEnabled = enabled && adsorptionSurfaceOn
          if let color = representedStructure.renderAdsorptionSurfaceBackSideSpecularColor
          {
            specularBackSideColor.color = color
          }
        }
      }
      
      // Shininess
      if let textFieldBackShininess: NSTextField = view.viewWithTag(33) as? NSTextField
      {
        textFieldBackShininess.isEditable = false
        textFieldBackShininess.stringValue = ""
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          textFieldBackShininess.isEditable = enabled && adsorptionSurfaceOn
          if let shininess = representedStructure.renderAdsorptionSurfaceBackSideShininess
          {
            textFieldBackShininess.doubleValue = shininess
          }
          else
          {
            textFieldBackShininess.stringValue = "Multiple Values"
          }
        }
      }
      if let sliderBackShininess: NSSlider = view.viewWithTag(34) as? NSSlider
      {
        sliderBackShininess.isEnabled = false
        if let representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
        {
          sliderBackShininess.isEnabled = enabled && adsorptionSurfaceOn
          if let shininess = representedStructure.renderAdsorptionSurfaceBackSideShininess
          {
            sliderBackShininess.minValue = 0.0
            sliderBackShininess.maxValue = 256.0
            sliderBackShininess.doubleValue = shininess
          }
        }
      }
    
    default:
      break
    }
  }
  
  func setPropertiesAnnotationTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    switch(identifier)
    {
    case "AnnotationVisualAppearanceCell":
      // Annotation type
      if let popUpbuttonAnnotationType: iRASPAPopUpButton = view.viewWithTag(60) as? iRASPAPopUpButton
      {
        popUpbuttonAnnotationType.isEditable = false
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          popUpbuttonAnnotationType.isEditable = enabled
          if let rawValue: Int = representedStructure.renderTextType?.rawValue
          {
            popUpbuttonAnnotationType.removeItem(withTitle: "Multiple Values")
            
            popUpbuttonAnnotationType.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonAnnotationType.setTitle("Multiple Values")
          }
        }
      }
      
      if let textColor: NSColorWell = view.viewWithTag(61) as? NSColorWell
      {
        textColor.isEnabled = false
        textColor.color = NSColor.lightGray
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          textColor.isEnabled = enabled
          if let renderAtomAmbientColor: NSColor = representedStructure.renderTextColor
          {
            textColor.color = renderAtomAmbientColor
          }
          else
          {
            textColor.color = NSColor.lightGray
          }
        }
      }
      
      if let popUpbuttonFontFamily: iRASPAPopUpButton = view.viewWithTag(62) as? iRASPAPopUpButton,
        let popUpbuttonFontFamilyMembers: iRASPAPopUpButton = view.viewWithTag(63) as? iRASPAPopUpButton
      {
        popUpbuttonFontFamily.isEditable = false
        popUpbuttonFontFamilyMembers.isEditable = false
        if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
        {
          popUpbuttonFontFamily.isEditable = enabled
          popUpbuttonFontFamilyMembers.isEditable = enabled
          
          popUpbuttonFontFamily.removeAllItems()
          let fontFamilies = NSFontManager.shared.availableFontFamilies
          popUpbuttonFontFamily.addItems(withTitles: fontFamilies)
          
          popUpbuttonFontFamilyMembers.removeAllItems()
          
          if let fontFamilyName: String = representedStructure.renderTextFontFamily
          {
            popUpbuttonFontFamily.selectItem(withTitle: fontFamilyName)
            
            if let availableMembers: [[Any]] = NSFontManager.shared.availableMembers(ofFontFamily: fontFamilyName)
            {
              let members = availableMembers.compactMap{$0[1] as? String}
              popUpbuttonFontFamilyMembers.addItems(withTitles: members)
              
              if let fontName: String = representedStructure.renderTextFont,
                 let font: NSFont = NSFont(name: fontName, size: 32),
                 let memberName: String = NSFontManager.shared.memberName(of: font)
              {
                popUpbuttonFontFamilyMembers.selectItem(withTitle: memberName)
              }
              else
              {
                popUpbuttonFontFamilyMembers.setTitle("Multiple Values")
              }
            }
          }
          else
          {
            popUpbuttonFontFamily.setTitle("Multiple Values")
            popUpbuttonFontFamilyMembers.setTitle("Multiple Values")
          }
        }
        
        if let popUpbuttonAnnotationAlignment: iRASPAPopUpButton = view.viewWithTag(64) as? iRASPAPopUpButton
        {
          popUpbuttonAnnotationAlignment.isEditable = false
          if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
          {
            popUpbuttonAnnotationAlignment.isEditable = enabled
            if let rawValue: Int = representedStructure.renderTextAlignment?.rawValue
            {
              popUpbuttonAnnotationAlignment.removeItem(withTitle: "Multiple Values")
              
              popUpbuttonAnnotationAlignment.selectItem(at: rawValue)
            }
            else
            {
              popUpbuttonAnnotationAlignment.setTitle("Multiple Values")
            }
          }
        }
        
        if let popUpbuttonAnnotationStyle: iRASPAPopUpButton = view.viewWithTag(65) as? iRASPAPopUpButton
        {
          popUpbuttonAnnotationStyle.isEditable = false
          if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
          {
            popUpbuttonAnnotationStyle.isEditable = enabled
            if let rawValue: Int = representedStructure.renderTextStyle?.rawValue
            {
              popUpbuttonAnnotationStyle.removeItem(withTitle: "Multiple Values")
              
              popUpbuttonAnnotationStyle.selectItem(at: rawValue)
            }
            else
            {
              popUpbuttonAnnotationStyle.setTitle("Multiple Values")
            }
          }
        }
        
        
        // Scaling
        if let textFieldScaling: NSTextField = view.viewWithTag(66) as? NSTextField
        {
          textFieldScaling.isEditable = false
          textFieldScaling.stringValue = ""
          if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
          {
            textFieldScaling.isEditable = enabled
            if let renderTextScaling: Double = representedStructure.renderTextScaling
            {
              textFieldScaling.doubleValue = renderTextScaling
            }
            else
            {
              textFieldScaling.stringValue = "Multiple Values"
            }
          }
        }
        if let sliderScaling: NSSlider = view.viewWithTag(67) as? NSSlider
        {
          sliderScaling.isEnabled = false
          sliderScaling.minValue = 0.0
          sliderScaling.maxValue = 3.0
          if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
          {
            sliderScaling.isEnabled = enabled
            if let renderTextScaling: Double = representedStructure.renderTextScaling
            {
              sliderScaling.doubleValue = renderTextScaling
            }
          }
        }
        
        if let textFieldAnnotionTextDisplacementX: NSTextField = view.viewWithTag(70) as? NSTextField
        {
          textFieldAnnotionTextDisplacementX.isEditable = false
          textFieldAnnotionTextDisplacementX.stringValue = ""
          if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
          {
            textFieldAnnotionTextDisplacementX.isEditable = enabled
            if let renderTextOffsetX: Double = representedStructure.renderTextOffsetX
            {
              textFieldAnnotionTextDisplacementX.doubleValue =  renderTextOffsetX
            }
            else
            {
              textFieldAnnotionTextDisplacementX.stringValue = "Mult. Val."
            }
          }
        }
        
        if let textFieldAnnotionTextDisplacementY: NSTextField = view.viewWithTag(72) as? NSTextField
        {
          textFieldAnnotionTextDisplacementY.isEditable = false
          textFieldAnnotionTextDisplacementY.stringValue = ""
          if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
          {
            textFieldAnnotionTextDisplacementY.isEditable = enabled
            if let renderTextOffsetY: Double = representedStructure.renderTextOffsetY
            {
              textFieldAnnotionTextDisplacementY.doubleValue =  renderTextOffsetY
            }
            else
            {
              textFieldAnnotionTextDisplacementY.stringValue = "Mult. Val."
            }
          }
        }
        
        if let textFieldAnnotionTextDisplacementZ: NSTextField = view.viewWithTag(74) as? NSTextField
        {
          textFieldAnnotionTextDisplacementZ.isEditable = false
          textFieldAnnotionTextDisplacementZ.stringValue = ""
          if let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
          {
            textFieldAnnotionTextDisplacementZ.isEditable = enabled
            if let renderTextOffsetZ: Double = representedStructure.renderTextOffsetZ
            {
              textFieldAnnotionTextDisplacementZ.doubleValue =  renderTextOffsetZ
            }
            else
            {
              textFieldAnnotionTextDisplacementZ.stringValue = "Mult. Val."
            }
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
    if let index: Int = self.appearanceOutlineView?.childIndex(forItem: dictionary)
    {
      self.expandedItems[index] = true
    }
  }
  
  
  func outlineViewItemDidCollapse(_ notification:Notification)
  {
    let dictionary: AnyObject  = notification.userInfo?["NSObject"] as AnyObject
    if let index: Int = self.appearanceOutlineView?.childIndex(forItem: dictionary)
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
        if let row: Int = self?.appearanceOutlineView?.row(forItem: identifier), row >= 0
        {
          self?.appearanceOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
        }
      }
    })
  }
  
  
  // MARK: primitive properties
  // =====================================================================
  
  @IBAction func changedPrimitiveEulerAngleX(_ sender: NSTextField)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var structure: [PrimitiveVisualAppearanceViewer] = self.representedObject as? [PrimitiveVisualAppearanceViewer],
      let renderOrientation: simd_quatd = structure.renderPrimitiveOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.x = sender.doubleValue * Double.pi/180.0
      structure.renderPrimitiveOrientation = simd_quatd(EulerAngles: angles)
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
    }
  }
  
  @IBAction func changedPrimitiveEulerAngleY(_ sender: NSTextField)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var structure: [PrimitiveVisualAppearanceViewer] = self.representedObject as? [PrimitiveVisualAppearanceViewer],
      let renderOrientation: simd_quatd = structure.renderPrimitiveOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.y = sender.doubleValue * Double.pi/180.0
      structure.renderPrimitiveOrientation = simd_quatd(EulerAngles: angles)
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
    }
  }
  
  @IBAction func changedPrimitiveEulerAngleZ(_ sender: NSTextField)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var structure: [PrimitiveVisualAppearanceViewer] = self.representedObject as? [PrimitiveVisualAppearanceViewer],
      let renderOrientation: simd_quatd = structure.renderPrimitiveOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.z = sender.doubleValue * Double.pi/180.0
      structure.renderPrimitiveOrientation = simd_quatd(EulerAngles: angles)
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
    }
  }
  
  @IBAction func rotatePrimitiveYawPlus(_ sender: NSButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var structure: [PrimitiveVisualAppearanceViewer] = self.representedObject as? [PrimitiveVisualAppearanceViewer],
      let renderRotationDelta = structure.renderPrimitiveRotationDelta,
      let renderOrientation: simd_quatd = structure.renderPrimitiveOrientation
    {
      let dq: simd_quatd = simd_quatd(yaw: renderRotationDelta)
      
      structure.renderPrimitiveOrientation = renderOrientation * dq
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
    }
  }
  
  
  @IBAction func rotatePrimitiveYawMinus(_ sender: NSButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var structure: [PrimitiveVisualAppearanceViewer] = self.representedObject as? [PrimitiveVisualAppearanceViewer],
      let renderRotationDelta = structure.renderPrimitiveRotationDelta,
      let renderOrientation: simd_quatd = structure.renderPrimitiveOrientation
    {
      let dq: simd_quatd = simd_quatd(yaw: -renderRotationDelta)
      
      structure.renderPrimitiveOrientation = renderOrientation * dq
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
    }
    
  }
  
  @IBAction func rotatePrimitivePitchPlus(_ sender: NSButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var structure: [PrimitiveVisualAppearanceViewer] = self.representedObject as? [PrimitiveVisualAppearanceViewer],
      let renderRotationDelta = structure.renderPrimitiveRotationDelta,
      let renderOrientation: simd_quatd = structure.renderPrimitiveOrientation
    {
      let dq: simd_quatd = simd_quatd(pitch: renderRotationDelta)
      
      structure.renderPrimitiveOrientation = renderOrientation * dq
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
    }
  }
  
  
  @IBAction func rotatePrimitivePitchMinus(_ sender: NSButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var structure: [PrimitiveVisualAppearanceViewer] = self.representedObject as? [PrimitiveVisualAppearanceViewer],
      let renderRotationDelta = structure.renderPrimitiveRotationDelta,
      let renderOrientation: simd_quatd = structure.renderPrimitiveOrientation
    {
      let dq: simd_quatd = simd_quatd(pitch: -renderRotationDelta)
      
      structure.renderPrimitiveOrientation = renderOrientation * dq
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
    }
  }
  
  @IBAction func rotatePrimitiveRollPlus(_ sender: NSButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var structure: [PrimitiveVisualAppearanceViewer] = self.representedObject as? [PrimitiveVisualAppearanceViewer],
      let renderRotationDelta = structure.renderPrimitiveRotationDelta,
      let renderOrientation: simd_quatd = structure.renderPrimitiveOrientation
    {
      let dq: simd_quatd = simd_quatd(roll: renderRotationDelta)
      
      structure.renderPrimitiveOrientation = renderOrientation * dq
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
    }
  }
  
  
  @IBAction func rotatePrimitiveRollMinus(_ sender: NSButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var structure: [PrimitiveVisualAppearanceViewer] = self.representedObject as? [PrimitiveVisualAppearanceViewer],
      let renderRotationDelta = structure.renderPrimitiveRotationDelta,
      let renderOrientation: simd_quatd = structure.renderPrimitiveOrientation
    {
      let dq: simd_quatd = simd_quatd(roll: -renderRotationDelta)
      
      structure.renderPrimitiveOrientation = renderOrientation * dq
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
    }
  }
  
  @IBAction func changePrimitiveRotationYawSlider(_ sender: NSSlider)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var structure: [PrimitiveVisualAppearanceViewer] = self.representedObject as? [PrimitiveVisualAppearanceViewer],
      let renderOrientation = structure.renderPrimitiveOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.x = sender.doubleValue * Double.pi/180.0
      structure.renderPrimitiveOrientation = simd_quatd(EulerAngles: angles)
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        else if endingDrag
        {
          if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
          {
            self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
          }
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
          
          self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        }
        else
        {
          self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveRotationPitchSlider(_ sender: NSSlider)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var structure: [PrimitiveVisualAppearanceViewer] = self.representedObject as? [PrimitiveVisualAppearanceViewer],
      let renderOrientation = structure.renderPrimitiveOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.z = sender.doubleValue * Double.pi/180.0
      structure.renderPrimitiveOrientation = simd_quatd(EulerAngles: angles)
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        else if endingDrag
        {
          if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
          {
            self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
          }
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
          self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        }
        else
        {
          self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveRotationRollSlider(_ sender: NSSlider)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var structure: [PrimitiveVisualAppearanceViewer] = self.representedObject as? [PrimitiveVisualAppearanceViewer],
      let renderOrientation = structure.renderPrimitiveOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.y = sender.doubleValue * Double.pi/180.0
      structure.renderPrimitiveOrientation = simd_quatd(EulerAngles: angles)
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        else if endingDrag
        {
          if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
          {
            self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
          }
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
          self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        }
        else
        {
          self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changedPrimitiveRotationAngle(_ sender: NSTextField)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      var structure: [PrimitiveVisualAppearanceViewer] = self.representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      structure.renderPrimitiveRotationDelta = sender.doubleValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
    }
  }
  
  
  @IBAction func changeTransformationAXTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveTransformationMatrixAX = sender.doubleValue
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTransformationAYTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveTransformationMatrixAY = sender.doubleValue
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTransformationAZTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveTransformationMatrixAZ = sender.doubleValue
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTransformationBXTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveTransformationMatrixBX = sender.doubleValue
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTransformationBYTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveTransformationMatrixBY = sender.doubleValue
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTransformationBZTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveTransformationMatrixBZ = sender.doubleValue
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTransformationCXTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveTransformationMatrixCX = sender.doubleValue
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTransformationCYTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveTransformationMatrixCY = sender.doubleValue
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTransformationCZTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveTransformationMatrixCZ = sender.doubleValue
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveOpaquenessSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveOpacity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveOpaquenessTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveOpacity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveNumberOfSidesSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveNumberOfSides = max(2,sender.integerValue)
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveNumberOfSidesTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveNumberOfSides = max(2,sender.integerValue)
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadRenderData()

      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func togglePrimitiveIsCapped(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      sender.allowsMixedState = false
      representedStructure.renderPrimitiveIsCapped = (sender.state == NSControl.StateValue.on)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func togglePrimitiveIsFractional(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      sender.allowsMixedState = false
      representedStructure.renderPrimitiveIsFractional = (sender.state == NSControl.StateValue.on)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // High dynamic range
  @IBAction func togglePrimitiveFrontSideHDR(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      sender.allowsMixedState = false
      representedStructure.renderPrimitiveFrontSideHDR = (sender.state == NSControl.StateValue.on)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Selection style
  @IBAction func changePrimitiveSelectionStyle(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer],
       let selectionStyle = RKSelectionStyle(rawValue: sender.indexOfSelectedItem)
    {
      representedStructure.renderPrimitiveSelectionStyle = selectionStyle
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveSelectionFrequencyTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveSelectionFrequency = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveSelectionDensityTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveSelectionDensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveSelectionIntensityField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveSelectionIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveSelectionIntensity(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveSelectionIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveSelectionScalingTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveSelectionScaling = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveSelectionScalingSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveSelectionScaling = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  // Hue textfield
   @IBAction func changePrimitiveHueTextField(_ sender: NSTextField)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
        var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
     {
       representedStructure.renderPrimitiveHue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Hue slider
   @IBAction func changePrimitiveHueSlider(_ sender: NSSlider)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
        var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
     {
       representedStructure.renderPrimitiveHue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
       
       if let event: NSEvent = NSApplication.shared.currentEvent
       {
         let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
         let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
         
         if startingDrag
         {
           self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
         }
         if endingDrag
         {
           self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
         }
       }
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Saturation textfield
   @IBAction func changePrimitiveSaturationTextField(_ sender: NSTextField)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
        var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
     {
       representedStructure.renderPrimitiveSaturation = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Saturation slider
   @IBAction func changePrimitiveSaturationSlider(_ sender: NSSlider)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
        var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
     {
       representedStructure.renderPrimitiveSaturation = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
       
       if let event: NSEvent = NSApplication.shared.currentEvent
       {
         let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
         let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
         
         if startingDrag
         {
           self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
         }
         if endingDrag
         {
           self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
         }
       }
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Value textfield
   @IBAction func changePrimitiveValueTextField(_ sender: NSTextField)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
        var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
     {
       representedStructure.renderPrimitiveValue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Value slider
   @IBAction func changePrimitiveValueSlider(_ sender: NSSlider)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
        var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
     {
       representedStructure.renderPrimitiveValue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
       
       if let event: NSEvent = NSApplication.shared.currentEvent
       {
         let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
         let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
         
         if startingDrag
         {
           self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
         }
         if endingDrag
         {
           self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
         }
       }
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   
   
  
  
  @IBAction func changePrimitiveFrontSideHDRExporeTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveFrontSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Exposure slider
  @IBAction func changePrimitiveFrontSideExposureSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveFrontSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveFrontSideAmbientTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveFrontSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveFrontSideAmbientIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveFrontSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveFrontSideAmbientColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveFrontSideAmbientColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveFrontSideDiffuseTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveFrontSideDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveFrontSideDiffuseIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveFrontSideDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveFrontSideDiffuseColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveFrontSideDiffuseColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveFrontSideSpecularTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveFrontSideSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveFrontSideSpecularIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveFrontSideSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  
  @IBAction func changePrimitiveFrontSideSpecularColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveFrontSideSpecularColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveFrontSideShininessTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveFrontSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveFrontSideShininessSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveFrontSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func togglePrimitiveBackSideHDR(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      sender.allowsMixedState = false
      representedStructure.renderPrimitiveBackSideHDR = (sender.state == NSControl.StateValue.on)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveBackSideHDRExporeTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveBackSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Exposure slider
  @IBAction func changePrimitiveBackSideExposureSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveBackSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideAmbientTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveBackSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideAmbientIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveBackSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideAmbientColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveBackSideAmbientColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveBackSideDiffuseTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveBackSideDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideDiffuseIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveBackSideDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideDiffuseColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveBackSideDiffuseColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveBackSideSpecularTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveBackSideSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideSpecularIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveBackSideSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideSpecularColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveBackSideSpecularColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideShininessTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveBackSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveBackSideShininessSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [PrimitiveVisualAppearanceViewer] = representedObject as? [PrimitiveVisualAppearanceViewer]
    {
      representedStructure.renderPrimitiveBackSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // MARK: Atom actions
  // =====================================================================
  
  // Representation type
  @IBAction func changeRepresentation(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer],
       let representationType = Structure.RepresentationType(rawValue: sender.indexOfSelectedItem)
    {
      representedStructure.setRepresentationType(type: representationType)
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: representedStructure.selectedFrames)
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: representedStructure.selectedFrames)
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Representation style
  @IBAction func changeRepresentationStyle(_ sender: NSPopUpButton)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer],
       let representationStyle = Crystal.RepresentationStyle(rawValue: sender.indexOfSelectedItem), representationStyle.rawValue >= 0
    {
      representedStructure.setRepresentationStyle(style: representationStyle, colorSets: document.colorSets)
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell,self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [])
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [])
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Color scheme
  @IBAction func changeColorScheme(_ sender: NSPopUpButton)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.setRepresentationColorScheme(scheme: sender.titleOfSelectedItem ?? SKColorSets.ColorScheme.jmol.rawValue, colorSets: document.colorSets)
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Force field
  @IBAction func changeForceField(_ sender: NSPopUpButton)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.setRepresentationForceField(forceField: sender.titleOfSelectedItem ?? "Default", forceFieldSets: document.forceFieldSets)
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [])
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurface(completionHandler: surfaceUpdateBlock)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadRenderData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  // Color order
  @IBAction func changeRepresentationColorOrder(_ sender: NSPopUpButton)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer],
       let representationColorOrder = SKColorSets.ColorOrder(rawValue: sender.indexOfSelectedItem)
    {
      representedStructure.setRepresentationColorOrder(order: representationColorOrder, colorSets: document.colorSets)
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [])
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [])
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Force field order
  @IBAction func changeRepresentationForceFieldOrder(_ sender: NSPopUpButton)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       let representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer],
       let representationForceFieldOrder = SKForceFieldSets.ForceFieldOrder(rawValue: sender.indexOfSelectedItem)
    {
      representedStructure.setRepresentationForceFieldOrder(order:  representationForceFieldOrder, forceFieldSets: document.forceFieldSets)
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [])
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [])
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Selection style
  @IBAction func changeAtomSelectionStyle(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer],
       let selectionStyle = RKSelectionStyle(rawValue: sender.indexOfSelectedItem)
    {
      representedStructure.renderAtomSelectionStyle = selectionStyle
      
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell, self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomSelectionFrequencyTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomSelectionFrequency = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomSelectionDensityTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomSelectionDensity = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomSelectionIntensityLevelField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomSelectionIntensity = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomSelectionIntensityLevel(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomSelectionIntensity = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAtomSelectionScalingTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomSelectionScaling = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomSelectionScalingSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomSelectionScaling = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  // High dynamic range
  @IBAction func toggleHDR(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      sender.allowsMixedState = false
      representedStructure.renderAtomHDR = (sender.state == NSControl.StateValue.on)
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomHDRExporeTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomHDRExposure = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Exposure slider
  @IBAction func changeExposureSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomHDRExposure = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Hue textfield
  @IBAction func changeHueTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomHue = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Hue slider
  @IBAction func changeHueSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomHue = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Saturation textfield
  @IBAction func changeSaturationTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomSaturation = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Saturation slider
  @IBAction func changeSaturationSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomSaturation = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Value textfield
  @IBAction func changeValueTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomValue = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Value slider
  @IBAction func changeValueSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomValue = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomScalingSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomScaleFactor = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
         
          representedStructure.renderAtomScaleFactorCompleted = sender.doubleValue
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
          
          if let renderAtomAmbientOcclusion = representedStructure.renderAtomAmbientOcclusion , renderAtomAmbientOcclusion == true
          {
            
            self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [])
            self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [])
            self.windowController?.detailTabViewController?.renderViewController?.reloadData()
          }
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomScalingTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomScaleFactorCompleted = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      if let renderAtomAmbientOcclusion: Bool = representedStructure.renderAtomAmbientOcclusion , renderAtomAmbientOcclusion == true
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [])
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [])
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
 
  @IBAction func toggleAmbientOcclusion(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      sender.allowsMixedState = false
      representedStructure.renderAtomAmbientOcclusion = (sender.state == NSControl.StateValue.on)
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [])
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [])
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.updateAmbientOcclusion()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAmbientTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomAmbientIntensity = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAmbientIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomAmbientIntensity = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomAmbientColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomAmbientColor = sender.color
      
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeDiffuseTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomDiffuseIntensity = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeDiffuseIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomDiffuseIntensity = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomDiffuseColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomDiffuseColor = sender.color
      
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeSpecularTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomSpecularIntensity = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeSpecularIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomSpecularColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomSpecularColor = sender.color
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeShininessTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomShininess = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeShininessSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderAtomShininess = sender.doubleValue
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  
  
  @IBAction func toggleAtomBonds(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      sender.allowsMixedState = false
      representedStructure.renderDrawAtoms=(sender.state == NSControl.StateValue.on)
      
      representedStructure.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  
  // MARK: bond actions
  // =====================================================================
  
  @IBAction func toggleDrawBonds(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderDrawBonds = (sender.state == NSControl.StateValue.on)
      
      representedStructure.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeBondColorMode(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondColorMode = RKBondColorMode(rawValue: sender.indexOfSelectedItem)!
      
      representedStructure.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondScalingSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondScaleFactor = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadRenderData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondScalingTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondScaleFactor = sender.doubleValue
      
      representedStructure.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadRenderData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Selection style
  @IBAction func changeBondSelectionStyle(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer],
       let selectionStyle = RKSelectionStyle(rawValue: sender.indexOfSelectedItem)
    {
      representedStructure.renderBondSelectionStyle = selectionStyle
      
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell, self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondSelectionFrequencyTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondSelectionFrequency = sender.doubleValue
      
      representedStructure.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondSelectionDensityTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondSelectionDensity = sender.doubleValue
      
      representedStructure.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondSelectionIntensityField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondSelectionIntensity = sender.doubleValue
      
      representedStructure.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell, self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondSelectionIntensity(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondSelectionIntensity = sender.doubleValue
      
      representedStructure.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell, self.bondsScalingCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeBondSelectionScalingTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondSelectionScaling = sender.doubleValue
      
      representedStructure.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell, self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondSelectionScalingSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondSelectionScaling = sender.doubleValue
      
      representedStructure.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell, self.bondsScalingCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  
  // High dynamic range
  @IBAction func toggleBondHDR(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondHDR = (sender.state == NSControl.StateValue.on)
      
      representedStructure.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Exposure slider
  @IBAction func changeBondExposureSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Hue textfield
  @IBAction func changeBondHueTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondHue = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Hue slider
  @IBAction func changeBondHueSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondHue = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Saturation textfield
  @IBAction func changeBondSaturationTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondSaturation = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Saturation slider
  @IBAction func changeBondSaturationSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondSaturation = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Value textfield
  @IBAction func changeBondValueTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondValue = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Value slider
  @IBAction func changeBondValueSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondValue = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  
  
  
  
  @IBAction func changeBondAmbientTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeBondAmbientIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondAmbientColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondAmbientColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeBondDiffuseTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondDiffuseIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondDiffuseColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondDiffuseColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondSpecularTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeBondSpecularIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondSpecularColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondSpecularColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondShininessTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondShininessSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [BondVisualAppearanceViewer] = representedObject as? [BondVisualAppearanceViewer]
    {
      representedStructure.renderBondShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  
  // MARK: unitcell actions
  // =====================================================================
  
  
  @IBAction func toggleDrawUnitCell(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [UnitCellVisualAppearanceViewer] = representedObject as? [UnitCellVisualAppearanceViewer]
    {
      representedStructure.renderDrawUnitCell = (sender.state == NSControl.StateValue.on)
      
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
      {
        project.allStructures.forEach{$0.reComputeBoundingBox()}
        (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeUnitCellScalingSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [UnitCellVisualAppearanceViewer] = representedObject as? [UnitCellVisualAppearanceViewer]
    {
      representedStructure.renderUnitCellScaleFactor = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.unitCellScalingCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeUnitCellScalingTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [UnitCellVisualAppearanceViewer] = representedObject as? [UnitCellVisualAppearanceViewer]
    {
      representedStructure.renderUnitCellScaleFactor = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.unitCellScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeUnitCellDiffuseTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [UnitCellVisualAppearanceViewer] = representedObject as? [UnitCellVisualAppearanceViewer]
    {
      representedStructure.renderUnitCellDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.unitCellScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeUnitCellDiffuseIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [UnitCellVisualAppearanceViewer] = representedObject as? [UnitCellVisualAppearanceViewer]
    {
      representedStructure.renderUnitCellDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.unitCellScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeUnitCellDiffuseColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [UnitCellVisualAppearanceViewer] = representedObject as? [UnitCellVisualAppearanceViewer]
    {
      representedStructure.renderUnitCellDiffuseColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  // MARK: adsorption surface
  // =====================================================================
  
 
  
  @IBAction func toggleAdsorptionSurface(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceOn = (sender.state == NSControl.StateValue.on)
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurface(completionHandler: surfaceUpdateBlock)
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
    }
  }
  
  @IBAction func changeAdsorptionSurfaceProbeMolecule(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceProbeMolecule = Structure.ProbeMolecule(rawValue: sender.indexOfSelectedItem)!
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: representedStructure.selectedFrames)
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurface(completionHandler: surfaceUpdateBlock)
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceIsovalueSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceIsovalue = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
        else
        {
          
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurface(completionHandler: surfaceUpdateBlock)
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceIsovalueTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceIsovalue = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurface(completionHandler: surfaceUpdateBlock)
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  
  @IBAction func changeAdsorptionSurfaceOpaquenessSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceOpacity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        if endingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceOpaquenessTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceOpacity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceSize(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      switch(sender.indexOfSelectedItem)
      {
      case 0:
        representedStructure.renderAdsorptionSurfaceSize = 128
        break
      case 1:
        representedStructure.renderAdsorptionSurfaceSize = 256
        break
      default:
        break
      }
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurface(completionHandler: surfaceUpdateBlock)
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Hue textfield
   @IBAction func changeAdsorptionSurfaceHueTextField(_ sender: NSTextField)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
        var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
     {
       representedStructure.renderAdsorptionSurfaceHue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Hue slider
   @IBAction func changeAdsorptionSurfaceHueSlider(_ sender: NSSlider)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
        var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
     {
       representedStructure.renderAdsorptionSurfaceHue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
       
       if let event: NSEvent = NSApplication.shared.currentEvent
       {
         let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
         let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
         
         if startingDrag
         {
           self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
         }
         if endingDrag
         {
           self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
         }
       }
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Saturation textfield
   @IBAction func changeAdsorptionSurfaceSaturationTextField(_ sender: NSTextField)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
        var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
     {
       representedStructure.renderAdsorptionSurfaceSaturation = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Saturation slider
   @IBAction func changeAdsorptionSurfaceSaturationSlider(_ sender: NSSlider)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
        var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
     {
       representedStructure.renderAdsorptionSurfaceSaturation = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
       
       if let event: NSEvent = NSApplication.shared.currentEvent
       {
         let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
         let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
         
         if startingDrag
         {
           self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
         }
         if endingDrag
         {
           self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
         }
       }
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Value textfield
   @IBAction func changeAdsorptionSurfaceValueTextField(_ sender: NSTextField)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
        var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
     {
       representedStructure.renderAdsorptionSurfaceValue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Value slider
   @IBAction func changeAdsorptionSurfaceValueSlider(_ sender: NSSlider)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
        var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
     {
       representedStructure.renderAdsorptionSurfaceValue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
       
       if let event: NSEvent = NSApplication.shared.currentEvent
       {
         let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
         let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
         
         if startingDrag
         {
           self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
         }
         if endingDrag
         {
           self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
         }
       }
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
  
  // High dynamic range
  @IBAction func toggleAdsorptionSurfaceFrontSideHDR(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      sender.allowsMixedState = false
      representedStructure.renderAdsorptionSurfaceFrontSideHDR = (sender.state == NSControl.StateValue.on)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceFrontSideHDRExporeTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceFrontSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Exposure slider
  @IBAction func changeAdsorptionSurfaceFrontSideExposureSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceFrontSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceFrontSideAmbientTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceFrontSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceFrontSideAmbientIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceFrontSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceFrontSideAmbientColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceFrontSideAmbientColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceFrontSideDiffuseTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceFrontSideDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceFrontSideDiffuseIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceFrontSideDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceFrontSideDiffuseColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceFrontSideDiffuseColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceFrontSideSpecularTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceFrontSideSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceFrontSideSpecularIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceFrontSideSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  
  @IBAction func changeAdsorptionSurfaceFrontSideSpecularColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceFrontSideSpecularColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceFrontSideShininessTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceFrontSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceFrontSideShininessSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceFrontSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func toggleAdsorptionSurfaceBackSideHDR(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      sender.allowsMixedState = false
      representedStructure.renderAdsorptionSurfaceBackSideHDR = (sender.state == NSControl.StateValue.on)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceBackSideHDRExporeTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceBackSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Exposure slider
  @IBAction func changeAdsorptionSurfaceBackSideExposureSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceBackSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideAmbientTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceBackSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideAmbientIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceBackSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideAmbientColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceBackSideAmbientColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceBackSideDiffuseTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceBackSideDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideDiffuseIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceBackSideDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideDiffuseColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceBackSideDiffuseColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceBackSideSpecularTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceBackSideSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideSpecularIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceBackSideSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideSpecularColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceBackSideSpecularColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideShininessTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceBackSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceBackSideShininessSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       var representedStructure: [AdsorptionSurfaceVisualAppearanceViewer] = representedObject as? [AdsorptionSurfaceVisualAppearanceViewer]
    {
      representedStructure.renderAdsorptionSurfaceBackSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // MARK: annotation
  // =====================================================================
  
  @IBAction func changeAtomTextAnnotationStyle(_ sender: iRASPAPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderTextType = RKTextType(rawValue: sender.indexOfSelectedItem)!
      
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomTextColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderTextColor = sender.color
      
      self.updateOutlineView(identifiers: [self.annotationVisualAppearanceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomTextAnnotationFontFamily(_ sender: iRASPAPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderTextFont = sender.titleOfSelectedItem
      
      self.updateOutlineView(identifiers: [self.annotationVisualAppearanceCell])
      
      LogQueue.shared.info(destination: self.windowController, message: "Creating new font-atlas for font \(sender.titleOfSelectedItem ?? "unknown font")", completionHandler: {
      
        self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        self.windowController?.detailTabViewController?.renderViewController?.redraw()
      })
      
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAtomTextAnnotationFontMember(_ sender: iRASPAPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      if let fontFamilyName = representedStructure.renderTextFontFamily,
         let availableMembers: [[Any]] = NSFontManager.shared.availableMembers(ofFontFamily: fontFamilyName)
      {
        let fontNames = availableMembers.compactMap{$0[0] as? String}
        representedStructure.renderTextFont = fontNames[sender.indexOfSelectedItem]
        
        LogQueue.shared.info(destination: self.windowController, message: "Creating new font-atlas for font \(fontNames[sender.indexOfSelectedItem])", completionHandler: {
          
          self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
          
          self.windowController?.detailTabViewController?.renderViewController?.reloadData()
          self.windowController?.detailTabViewController?.renderViewController?.redraw()
        })
        
        
        self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
      }
    }
  }
  
  @IBAction func changeAtomTextAnnotationAlignment(_ sender: iRASPAPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderTextAlignment = RKTextAlignment(rawValue: sender.indexOfSelectedItem)!
      
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeTextScalingTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderTextScaling = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.annotationVisualAppearanceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()

      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Text scaling slider
  @IBAction func changeTextScalingSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderTextScaling = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.annotationVisualAppearanceCell])
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeTextOffsetXTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderTextOffsetX = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.annotationVisualAppearanceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperOffsetX(_ sender: NSStepper)
  {
    let deltaValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      var structure: [AtomVisualAppearanceViewer] = self.representedObject as? [AtomVisualAppearanceViewer],
      let renderTextOffsetX: Double = structure.renderTextOffsetX
    {
      let newValue: Double = renderTextOffsetX + deltaValue * 0.1
      structure.renderTextOffsetX = newValue
      
      self.updateOutlineView(identifiers: [self.annotationVisualAppearanceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
    
    sender.doubleValue = 0
  }
  
  @IBAction func changeTextOffsetYTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderTextOffsetY = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.annotationVisualAppearanceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperOffsetY(_ sender: NSStepper)
  {
    let deltaValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      var structure: [AtomVisualAppearanceViewer] = self.representedObject as? [AtomVisualAppearanceViewer],
      let renderTextOffsetY: Double = structure.renderTextOffsetY
    {
      let newValue: Double = renderTextOffsetY + deltaValue * 0.1
      structure.renderTextOffsetY = newValue
      
      self.updateOutlineView(identifiers: [self.annotationVisualAppearanceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
    
    sender.doubleValue = 0
  }
  
  @IBAction func changeTextOffsetZTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var representedStructure: [AtomVisualAppearanceViewer] = representedObject as? [AtomVisualAppearanceViewer]
    {
      representedStructure.renderTextOffsetZ = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.annotationVisualAppearanceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperOffsetZ(_ sender: NSStepper)
  {
    let deltaValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      var structure: [AtomVisualAppearanceViewer] = self.representedObject as? [AtomVisualAppearanceViewer],
      let renderTextOffsetZ: Double = structure.renderTextOffsetZ
    {
      let newValue: Double = renderTextOffsetZ + deltaValue * 0.1
      structure.renderTextOffsetZ = newValue
      
      self.updateOutlineView(identifiers: [self.annotationVisualAppearanceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
    
    sender.doubleValue = 0
  }
  
  
}
