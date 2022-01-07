/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
  
  // MARK: protocol ProjectConsumer
  // =====================================================================
  
  weak var proxyProject: ProjectTreeNode?
  
  var iRASPAObjects: [iRASPAObject] = []
    
  var heights : [String : CGFloat] = [:]
  
  let primitiveOrientationPropertiesCell: OutlineViewItem = OutlineViewItem("PrimitiveOrientationPropertiesCell")
  let primitiveTransformationPropertiesCell: OutlineViewItem = OutlineViewItem("PrimitiveTransformationPropertiesCell")
  let primitiveOpacityPropertiesCell: OutlineViewItem = OutlineViewItem("PrimitiveOpacityPropertiesCell")
  let primitiveSelectionPropertiesCell: OutlineViewItem = OutlineViewItem("PrimitiveSelectionPropertiesCell")
  let primitiveHSVPropertiesCell: OutlineViewItem = OutlineViewItem("PrimitiveHSVPropertiesCell")
  let primitiveFrontPropertiesCell: OutlineViewItem = OutlineViewItem("PrimitiveFrontPropertiesCell")
  let primitiveBackPropertiesCell: OutlineViewItem = OutlineViewItem("PrimitiveBackPropertiesCell")
  
  let atomsScalingCell: OutlineViewItem = OutlineViewItem("AtomsScalingCell")
  let atomsRepresentationStyleCell: OutlineViewItem = OutlineViewItem("AtomsRepresentationCell")
  let atomsSelectionCell: OutlineViewItem = OutlineViewItem("AtomsSelectionCell")
  let atomsHDRCell: OutlineViewItem = OutlineViewItem("AtomsHDRCell")
  let atomsLightingCell: OutlineViewItem = OutlineViewItem("AtomsLightingCell")
  
  let bondsScalingCell: OutlineViewItem = OutlineViewItem("BondsScalingCell")
  let bondsSelectionCell: OutlineViewItem = OutlineViewItem("BondsSelectionCell")
  let bondsHDRCell: OutlineViewItem = OutlineViewItem("BondsHDRCell")
  let bondsLightingCell: OutlineViewItem = OutlineViewItem("BondsLightingCell")
  
  let unitCellScalingCell: OutlineViewItem = OutlineViewItem("UnitCellScalingCell")
  
  let localAxesCell: OutlineViewItem = OutlineViewItem("LocalAxesCell")
  
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
        if let self = self,
           let row: Int = self.appearanceOutlineView?.row(forItem: self.adsorptionPropertiesCell), row >= 0
        {
          // fast way of updating: get the current-view, set properties on it, and update the rect to redraw
          if let proxyProject = self.proxyProject, proxyProject.isEditable,
             !self.iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty,
             let view: NSTableCellView = self.appearanceOutlineView?.view(atColumn: 0, row: row, makeIfNecessary: false) as?  NSTableCellView,
             let isovalue: Double = self.renderAdsorptionSurfaceIsovalue,
             let sliderIsovalue: NSSlider = view.viewWithTag(4) as? NSSlider,
             let textFieldIsovalue: NSTextField = view.viewWithTag(3) as? NSTextField
          {
            //sliderIsovalue.isEnabled = enabled
            let minValue: Double = Double(self.renderGridRangeMinimum ?? -1000.0)
            sliderIsovalue.minValue = minValue
            let maxValue: Double = Double(self.renderGridRangeMaximum ?? 0.0)
            sliderIsovalue.maxValue = maxValue
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
    let atomsVisualAppearanceItem: OutlineViewItem = OutlineViewItem(title: "AtomsVisualAppearanceGroup", children: [atomsScalingCell, atomsRepresentationStyleCell, atomsSelectionCell, atomsHDRCell, atomsLightingCell])
    let bondsVisualAppearanceItem: OutlineViewItem = OutlineViewItem(title: "BondsVisualAppearanceGroup", children: [bondsScalingCell, bondsSelectionCell, bondsHDRCell, bondsLightingCell])
    let unitCellVisualAppearanceItem: OutlineViewItem = OutlineViewItem(title: "UnitCellVisualAppearanceGroup", children: [unitCellScalingCell])
    let localAxesAppearanceItem: OutlineViewItem = OutlineViewItem(title: "LocalAxesVisualAppearanceGroup", children: [localAxesCell])
    let adsorptionVisualAppearanceItem: OutlineViewItem = OutlineViewItem(title: "AdsorptionVisualAppearanceGroup", children: [adsorptionPropertiesCell, adsorptionHSVCell, adsorptionFrontSurfaceCell, adsorptionBackSurfaceCell])
    let annotationVisualAppearanceItem: OutlineViewItem = OutlineViewItem(title: "AnnotationVisualAppearanceGroup", children: [annotationVisualAppearanceCell])
    
    
    self.appearanceOutlineView?.items = [primitiveVisualAppearanceItem, atomsVisualAppearanceItem, bondsVisualAppearanceItem, unitCellVisualAppearanceItem, localAxesAppearanceItem, adsorptionVisualAppearanceItem, annotationVisualAppearanceItem]
    
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
      setPropertiesLocalAxesTableCells(on: view, identifier: string, enabled: enabled)
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
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldRotationAngle.isEditable = enabled
          textFieldYawPlusX.isEnabled = enabled
          textFieldYawPlusY.isEnabled = enabled
          textFieldYawPlusZ.isEnabled = enabled
          textFieldYawMinusX.isEnabled = enabled
          textFieldYawMinusY.isEnabled = enabled
          textFieldYawMinusZ.isEnabled = enabled
          
          if let renderRotationDelta: Double = self.renderPrimitiveRotationDelta
          {
            textFieldRotationAngle.doubleValue = renderRotationDelta
            textFieldYawPlusX.title =  "Rotate +\(renderRotationDelta)°"
            textFieldYawPlusY.title =  "Rotate -\(renderRotationDelta)°"
            textFieldYawPlusZ.title =  "Rotate +\(renderRotationDelta)°"
            textFieldYawMinusX.title =  "Rotate -\(renderRotationDelta)°"
            textFieldYawMinusY.title =  "Rotate +\(renderRotationDelta)°"
            textFieldYawMinusZ.title =  "Rotate -\(renderRotationDelta)°"
          }
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
        
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          if let renderEulerAngleX: Double = self.renderPrimitiveEulerAngleX,
             let renderEulerAngleY: Double = self.renderPrimitiveEulerAngleY,
             let renderEulerAngleZ: Double = self.renderPrimitiveEulerAngleZ
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
            textFieldEulerAngleX.stringValue = NSLocalizedString("Multiple Values", comment: "")
            textFieldEulerAngleY.stringValue = NSLocalizedString("Multiple Values", comment: "")
            textFieldEulerAngleZ.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
    case "PrimitiveTransformationPropertiesCell":
      if let textFieldAtomScalingAX: NSTextField = view.viewWithTag(1) as? NSTextField,
         let textFieldAtomScalingBX: NSTextField = view.viewWithTag(2) as? NSTextField,
         let textFieldAtomScalingCX: NSTextField = view.viewWithTag(3) as? NSTextField,
         let textFieldAtomScalingAY: NSTextField = view.viewWithTag(4) as? NSTextField,
         let textFieldAtomScalingBY: NSTextField = view.viewWithTag(5) as? NSTextField,
         let textFieldAtomScalingCY: NSTextField = view.viewWithTag(6) as? NSTextField,
         let textFieldAtomScalingAZ: NSTextField = view.viewWithTag(7) as? NSTextField,
         let textFieldAtomScalingBZ: NSTextField = view.viewWithTag(8) as? NSTextField,
         let textFieldAtomScalingCZ: NSTextField = view.viewWithTag(9) as? NSTextField
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
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
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
          if let renderPrimitiveTransformationMatrix: double3x3 = self.renderPrimitiveTransformationMatrix
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
            textFieldAtomScalingAX.stringValue = NSLocalizedString("Mult. Val.", comment: "")
            textFieldAtomScalingAY.stringValue = NSLocalizedString("Mult. Val.", comment: "")
            textFieldAtomScalingAZ.stringValue = NSLocalizedString("Mult. Val.", comment: "")
            textFieldAtomScalingBX.stringValue = NSLocalizedString("Mult. Val.", comment: "")
            textFieldAtomScalingBY.stringValue = NSLocalizedString("Mult. Val.", comment: "")
            textFieldAtomScalingBZ.stringValue = NSLocalizedString("Mult. Val.", comment: "")
            textFieldAtomScalingCX.stringValue = NSLocalizedString("Mult. Val.", comment: "")
            textFieldAtomScalingCY.stringValue = NSLocalizedString("Mult. Val.", comment: "")
            textFieldAtomScalingCZ.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
  
    case "PrimitiveOpacityPropertiesCell":
      if let button: NSButton = view.viewWithTag(1) as? NSButton
      {
        button.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          button.isEnabled = enabled
          
          if let renderPrimitiveIsCapped: Bool = self.renderPrimitiveIsCapped
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
      if let textFieldOpacity: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldOpacity.isEditable = false
        textFieldOpacity.stringValue = "1.0"
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldOpacity.isEditable = enabled
          if let opacity = self.renderPrimitiveOpacity
          {
            textFieldOpacity.doubleValue = opacity
          }
          else
          {
            textFieldOpacity.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldNumberOfSides: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldNumberOfSides.isEditable = false
        textFieldNumberOfSides.stringValue = "41"
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldNumberOfSides.isEditable = enabled
          if let numberOfSides = self.renderPrimitiveNumberOfSides
          {
            textFieldNumberOfSides.integerValue = numberOfSides
          }
          else
          {
            textFieldNumberOfSides.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      
      if let sliderOpacity: NSSlider = view.viewWithTag(4) as? NSSlider
      {
        sliderOpacity.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderOpacity.isEnabled = enabled
          if let opacity = self.renderPrimitiveOpacity
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
     
      if let sliderNumberOfSides: NSSlider = view.viewWithTag(5) as? NSSlider
      {
        sliderNumberOfSides.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderNumberOfSides.isEnabled = enabled
          if let numberOfSides = self.renderPrimitiveNumberOfSides
          {
            sliderNumberOfSides.minValue = 2
            sliderNumberOfSides.maxValue = 41
            sliderNumberOfSides.integerValue = numberOfSides
          }
          else
          {
            sliderNumberOfSides.minValue = 2
            sliderNumberOfSides.maxValue = 41
            sliderNumberOfSides.doubleValue = 6
          }
        }
      }
      
    case "PrimitiveSelectionPropertiesCell":
      // Selection-style
      if let popUpbuttonSelectionStyle: iRASPAPopUpButton = view.viewWithTag(1) as? iRASPAPopUpButton,
         let textFieldSelectionFrequency: NSTextField = view.viewWithTag(2) as? NSTextField,
         let textFieldSelectionDensity: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        popUpbuttonSelectionStyle.isEditable = false
        textFieldSelectionFrequency.isEditable = false
        textFieldSelectionFrequency.stringValue = ""
        textFieldSelectionDensity.isEditable = false
        textFieldSelectionDensity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          popUpbuttonSelectionStyle.isEditable = enabled
          textFieldSelectionFrequency.isEditable = enabled
          textFieldSelectionDensity.isEditable = enabled
          
          if let selectionStyle: RKSelectionStyle = self.renderPrimitiveSelectionStyle
          {
            popUpbuttonSelectionStyle.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpbuttonSelectionStyle.selectItem(at: selectionStyle.rawValue)
            
            if selectionStyle == .glow
            {
              textFieldSelectionFrequency.isEditable = false
              textFieldSelectionDensity.isEditable = false
            }
          }
          else
          {
            popUpbuttonSelectionStyle.setTitle(NSLocalizedString("Multiple Values", comment: ""))
            textFieldSelectionFrequency.stringValue = NSLocalizedString("Mult. Val.", comment: "")
            textFieldSelectionDensity.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
          
          if let renderSelectionFrequency: Double = self.renderPrimitiveSelectionFrequency
          {
            textFieldSelectionFrequency.doubleValue = renderSelectionFrequency
          }
          else
          {
            textFieldSelectionFrequency.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
          
          if let renderSelectionDensity: Double = self.renderPrimitiveSelectionDensity
          {
            textFieldSelectionDensity.doubleValue = renderSelectionDensity
          }
          else
          {
            textFieldSelectionDensity.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      
      if let textFieldBondSelectionIntensityLevel: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldBondSelectionIntensityLevel.isEditable = false
        textFieldBondSelectionIntensityLevel.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldBondSelectionIntensityLevel.isEditable = enabled
          if let renderSelectionIntensityLevel: Double = self.renderPrimitiveSelectionIntensity
          {
            textFieldBondSelectionIntensityLevel.doubleValue = renderSelectionIntensityLevel
          }
          else
          {
            textFieldBondSelectionIntensityLevel.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
        
      if let sliderSelectionIntensityLevel: NSSlider = view.viewWithTag(5) as? NSSlider
      {
        sliderSelectionIntensityLevel.isEnabled = false
        sliderSelectionIntensityLevel.minValue = 0.0
        sliderSelectionIntensityLevel.maxValue = 2.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderSelectionIntensityLevel.isEnabled = enabled
          if let renderSelectionIntensityLevel: Double = self.renderPrimitiveSelectionIntensity
          {
            sliderSelectionIntensityLevel.doubleValue = renderSelectionIntensityLevel
          }
        }
      }
        
      
      if let textFieldSelectionScaling: NSTextField = view.viewWithTag(6) as? NSTextField
      {
        textFieldSelectionScaling.isEditable = false
        textFieldSelectionScaling.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldSelectionScaling.isEditable = enabled
          if let renderSelectionScaling: Double = self.renderPrimitiveSelectionScaling
          {
            textFieldSelectionScaling.doubleValue = renderSelectionScaling
          }
          else
          {
            textFieldSelectionScaling.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderSelectionScaling: NSSlider = view.viewWithTag(7) as? NSSlider
      {
        sliderSelectionScaling.isEnabled = false
        sliderSelectionScaling.minValue = 1.0
        sliderSelectionScaling.maxValue = 2.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderSelectionScaling.isEnabled = enabled
          if let renderSelectionScaling: Double = self.renderPrimitiveSelectionScaling
          {
            sliderSelectionScaling.doubleValue = renderSelectionScaling
          }
        }
      }
      
    case "PrimitiveHSVPropertiesCell":
      // Hue
      if let textFieldHue: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldHue.isEditable = false
        textFieldHue.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldHue.isEditable = enabled
          if let renderBondHue: Double = self.renderPrimitiveHue
          {
            textFieldHue.doubleValue = renderBondHue
          }
        }
      }
      
      // Saturation
      if let textFieldSaturation: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldSaturation.isEditable = false
        textFieldSaturation.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldSaturation.isEditable = enabled
          if let renderBondSaturation: Double = self.renderPrimitiveSaturation
          {
            textFieldSaturation.doubleValue = renderBondSaturation
          }
        }
      }
      
      // Value
      if let textFieldValue: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldValue.isEditable = false
        textFieldValue.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldValue.isEditable = enabled
          if let renderBondValue: Double = self.renderPrimitiveValue
          {
            textFieldValue.doubleValue = renderBondValue
          }
        }
      }
      
      if let sliderHue: NSSlider = view.viewWithTag(4) as? NSSlider
      {
        sliderHue.isEnabled = false
        sliderHue.minValue = 0.0
        sliderHue.maxValue = 1.5
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderHue.isEnabled = enabled
          if let renderBondHue: Double = self.renderPrimitiveHue
          {
            sliderHue.doubleValue = renderBondHue
          }
        }
      }
      
      if let sliderSaturation: NSSlider = view.viewWithTag(5) as? NSSlider
      {
        sliderSaturation.isEnabled = false
        sliderSaturation.minValue = 0.0
        sliderSaturation.maxValue = 1.5
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderSaturation.isEnabled = enabled
          if let renderBondSaturation: Double = self.renderPrimitiveSaturation
          {
            sliderSaturation.doubleValue = renderBondSaturation
          }
        }
      }
      
    
      if let sliderValue: NSSlider = view.viewWithTag(6) as? NSSlider
      {
        sliderValue.isEnabled = false
        sliderValue.minValue = 0.0
        sliderValue.maxValue = 1.5
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderValue.isEnabled = enabled
          if let renderBondValue: Double = self.renderPrimitiveValue
          {
            sliderValue.doubleValue = renderBondValue
          }
        }
      }
      
    case "PrimitiveFrontPropertiesCell":
      
      // High dynamic range
      if let button: NSButton = view.viewWithTag(1) as? NSButton
      {
        button.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          button.isEnabled = enabled
          
          if let renderPrimitiveFrontSideHDR: Bool = self.renderPrimitiveFrontSideHDR
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
      if let textFieldExposure: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldExposure.isEditable = false
        textFieldExposure.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldExposure.isEditable = enabled
          if let renderPrimitiveFrontSideHDRExposure: Double = self.renderPrimitiveFrontSideHDRExposure
          {
            textFieldExposure.doubleValue = renderPrimitiveFrontSideHDRExposure
          }
          else
          {
            textFieldExposure.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderExposure: NSSlider = view.viewWithTag(3) as? NSSlider
      {
        sliderExposure.isEnabled = false
        sliderExposure.minValue = 0.0
        sliderExposure.maxValue = 3.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderExposure.isEnabled = enabled
          if let renderPrimitiveFrontSideHDRExposure: Double = self.renderPrimitiveFrontSideHDRExposure
          {
            sliderExposure.doubleValue = renderPrimitiveFrontSideHDRExposure
          }
        }
      }
      
      
      // ambient intensity and color
      if let textFieldFrontAmbientIntensity: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldFrontAmbientIntensity.isEditable = false
        textFieldFrontAmbientIntensity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldFrontAmbientIntensity.isEditable = enabled
          if let ambientIntensity = self.renderPrimitiveFrontSideAmbientIntensity
          {
            textFieldFrontAmbientIntensity.doubleValue = ambientIntensity
          }
          else
          {
            textFieldFrontAmbientIntensity.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderFrontAmbientIntensity: NSSlider = view.viewWithTag(5) as? NSSlider
      {
        sliderFrontAmbientIntensity.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderFrontAmbientIntensity.isEnabled = enabled
          if let ambientIntensity = self.renderPrimitiveFrontSideAmbientIntensity
          {
            sliderFrontAmbientIntensity.minValue = 0.0
            sliderFrontAmbientIntensity.maxValue = 1.0
            sliderFrontAmbientIntensity.doubleValue = ambientIntensity
          }
        }
      }
      if let ambientFrontSideColor: NSColorWell = view.viewWithTag(6) as? NSColorWell
      {
        ambientFrontSideColor.isEnabled = false
        ambientFrontSideColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          ambientFrontSideColor.isEnabled = enabled
          if let color = self.renderPrimitiveFrontSideAmbientColor
          {
            ambientFrontSideColor.color = color
          }
        }
      }
      
      // diffuse intensity and color
      if let textFieldFrontDiffuseIntensity: NSTextField = view.viewWithTag(7) as? NSTextField
      {
        textFieldFrontDiffuseIntensity.isEditable = false
        textFieldFrontDiffuseIntensity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldFrontDiffuseIntensity.isEditable = enabled
          if let diffuseIntensity = self.renderPrimitiveFrontSideDiffuseIntensity
          {
            textFieldFrontDiffuseIntensity.doubleValue = diffuseIntensity
          }
          else
          {
            textFieldFrontDiffuseIntensity.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderFrontDiffuseIntensity: NSSlider = view.viewWithTag(8) as? NSSlider
      {
        sliderFrontDiffuseIntensity.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderFrontDiffuseIntensity.isEnabled = enabled
          if let diffuseIntensity = self.renderPrimitiveFrontSideDiffuseIntensity
          {
            sliderFrontDiffuseIntensity.minValue = 0.0
            sliderFrontDiffuseIntensity.maxValue = 1.0
            sliderFrontDiffuseIntensity.doubleValue = diffuseIntensity
          }
        }
      }
      if let diffuseFrontSideColor: NSColorWell = view.viewWithTag(9) as? NSColorWell
      {
        diffuseFrontSideColor.isEnabled = false
        diffuseFrontSideColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          diffuseFrontSideColor.isEnabled = enabled
          if let color = self.renderPrimitiveFrontSideDiffuseColor
          {
            diffuseFrontSideColor.color = color
          }
        }
      }
      
      // specular intensity and color
      if let textFieldFrontSpecularIntensity: NSTextField = view.viewWithTag(10) as? NSTextField
      {
        textFieldFrontSpecularIntensity.isEditable = false
        textFieldFrontSpecularIntensity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldFrontSpecularIntensity.isEditable = enabled
          if let specularIntensity = self.renderPrimitiveFrontSideSpecularIntensity
          {
            textFieldFrontSpecularIntensity.doubleValue = specularIntensity
          }
          else
          {
            textFieldFrontSpecularIntensity.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderFrontSpecularIntensity: NSSlider = view.viewWithTag(11) as? NSSlider
      {
        sliderFrontSpecularIntensity.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderFrontSpecularIntensity.isEnabled = enabled
          if let specularIntensity = self.renderPrimitiveFrontSideSpecularIntensity
          {
            sliderFrontSpecularIntensity.minValue = 0.0
            sliderFrontSpecularIntensity.maxValue = 1.0
            sliderFrontSpecularIntensity.doubleValue = specularIntensity
          }
        }
      }
      if let specularFrontSideColor: NSColorWell = view.viewWithTag(12) as? NSColorWell
      {
        specularFrontSideColor.isEnabled = false
        specularFrontSideColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          specularFrontSideColor.isEnabled = enabled
          if let color = self.renderPrimitiveFrontSideSpecularColor
          {
            specularFrontSideColor.color = color
          }
        }
      }
      
      
      
      if let textFieldFrontShininess: NSTextField = view.viewWithTag(13) as? NSTextField
      {
        textFieldFrontShininess.isEditable = false
        textFieldFrontShininess.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldFrontShininess.isEditable = enabled
          if let shininess = self.renderPrimitiveFrontSideShininess
          {
            textFieldFrontShininess.doubleValue = shininess
          }
          else
          {
            textFieldFrontShininess.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderFrontShininess: NSSlider = view.viewWithTag(14) as? NSSlider
      {
        sliderFrontShininess.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderFrontShininess.isEnabled = enabled
          if let shininess = self.renderPrimitiveFrontSideShininess
          {
            sliderFrontShininess.minValue = 0.0
            sliderFrontShininess.maxValue = 256.0
            sliderFrontShininess.doubleValue = shininess
          }
        }
      }
    case "PrimitiveBackPropertiesCell":
      
      // High dynamic range
      if let button: NSButton = view.viewWithTag(1) as? NSButton
      {
        button.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          button.isEnabled = enabled
          if let renderPrimitiveHDR: Bool = self.renderPrimitiveBackSideHDR
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
      if let textFieldExposure: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldExposure.isEditable = false
        textFieldExposure.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldExposure.isEditable = enabled
          if let renderPrimitiveBackSideHDRExposure: Double = self.renderPrimitiveBackSideHDRExposure
          {
            textFieldExposure.doubleValue = renderPrimitiveBackSideHDRExposure
          }
          else
          {
            textFieldExposure.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderExposure: NSSlider = view.viewWithTag(3) as? NSSlider
      {
        sliderExposure.isEnabled = false
        sliderExposure.minValue = 0.0
        sliderExposure.maxValue = 3.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderExposure.isEnabled = enabled
          if let renderPrimitiveBackSideHDRExposure: Double = self.renderPrimitiveBackSideHDRExposure
          {
            sliderExposure.doubleValue = renderPrimitiveBackSideHDRExposure
          }
        }
      }
      
      
      // Ambient color
      if let textFieldBackAmbientIntensity: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldBackAmbientIntensity.isEditable = false
        textFieldBackAmbientIntensity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldBackAmbientIntensity.isEditable = enabled
          if let ambientIntensity = self.renderPrimitiveBackSideAmbientIntensity
          {
            textFieldBackAmbientIntensity.doubleValue = ambientIntensity
          }
          else
          {
            textFieldBackAmbientIntensity.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderBackAmbientIntensity: NSSlider = view.viewWithTag(5) as? NSSlider
      {
        sliderBackAmbientIntensity.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderBackAmbientIntensity.isEnabled = enabled
          if let ambientIntensity = self.renderPrimitiveBackSideAmbientIntensity
          {
            sliderBackAmbientIntensity.minValue = 0.0
            sliderBackAmbientIntensity.maxValue = 1.0
            sliderBackAmbientIntensity.doubleValue = ambientIntensity
          }
        }
      }
      if let ambientBackSideColor: NSColorWell = view.viewWithTag(6) as? NSColorWell
      {
        ambientBackSideColor.isEnabled = false
        ambientBackSideColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          ambientBackSideColor.isEnabled = enabled
          if let color = self.renderPrimitiveBackSideAmbientColor
          {
            ambientBackSideColor.color = color
          }
        }
      }
      
      // Diffuse color
      if let textFieldBackDiffuseIntensity: NSTextField = view.viewWithTag(7) as? NSTextField
      {
        textFieldBackDiffuseIntensity.isEditable = false
        textFieldBackDiffuseIntensity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldBackDiffuseIntensity.isEditable = enabled
          if let diffuseIntensity = self.renderPrimitiveBackSideDiffuseIntensity
          {
            textFieldBackDiffuseIntensity.doubleValue = diffuseIntensity
          }
          else
          {
            textFieldBackDiffuseIntensity.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderBackDiffuseIntensity: NSSlider = view.viewWithTag(8) as? NSSlider
      {
        sliderBackDiffuseIntensity.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderBackDiffuseIntensity.isEnabled = enabled
          if let diffuseIntensity = self.renderPrimitiveBackSideDiffuseIntensity
          {
            sliderBackDiffuseIntensity.minValue = 0.0
            sliderBackDiffuseIntensity.maxValue = 1.0
            sliderBackDiffuseIntensity.doubleValue = diffuseIntensity
          }
        }
      }
      if let diffuseBackSideColor: NSColorWell = view.viewWithTag(9) as? NSColorWell
      {
        diffuseBackSideColor.isEnabled = false
        diffuseBackSideColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          diffuseBackSideColor.isEnabled = enabled
          if let color = self.renderPrimitiveBackSideDiffuseColor
          {
            diffuseBackSideColor.color = color
          }
        }
      }
      
      // Specular color
      if let textFieldBackSpecularIntensity: NSTextField = view.viewWithTag(10) as? NSTextField
      {
        textFieldBackSpecularIntensity.isEditable = false
        textFieldBackSpecularIntensity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldBackSpecularIntensity.isEditable = enabled
          if let specularIntensity = self.renderPrimitiveBackSideSpecularIntensity
          {
            textFieldBackSpecularIntensity.doubleValue = specularIntensity
          }
          else
          {
            textFieldBackSpecularIntensity.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderBackSpecularIntensity: NSSlider = view.viewWithTag(11) as? NSSlider
      {
        sliderBackSpecularIntensity.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderBackSpecularIntensity.isEnabled = enabled
          if let specularIntensity = self.renderPrimitiveBackSideSpecularIntensity
          {
            sliderBackSpecularIntensity.minValue = 0.0
            sliderBackSpecularIntensity.maxValue = 1.0
            sliderBackSpecularIntensity.doubleValue = specularIntensity
          }
        }
      }
      if let specularBackSideColor: NSColorWell = view.viewWithTag(12) as? NSColorWell
      {
        specularBackSideColor.isEnabled = false
        specularBackSideColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          specularBackSideColor.isEnabled = enabled
          if let color = self.renderPrimitiveBackSideSpecularColor
          {
            specularBackSideColor.color = color
          }
        }
      }
      
      // Shininess
      if let textFieldBackShininess: NSTextField = view.viewWithTag(13) as? NSTextField
      {
        textFieldBackShininess.isEditable = false
        textFieldBackShininess.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          textFieldBackShininess.isEditable = enabled
          if let shininess = self.renderPrimitiveBackSideShininess
          {
            textFieldBackShininess.doubleValue = shininess
          }
          else
          {
            textFieldBackShininess.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderBackShininess: NSSlider = view.viewWithTag(14) as? NSSlider
      {
        sliderBackShininess.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is PrimitiveEditor}).isEmpty
        {
          sliderBackShininess.isEnabled = enabled
          if let shininess = self.renderPrimitiveBackSideShininess
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
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          popUpbuttonRepresentationType.isEditable = enabled
          
          if let rawValue = self.getRepresentationType()?.rawValue
          {
            popUpbuttonRepresentationType.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpbuttonRepresentationType.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonRepresentationType.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
      }
      
      // Representation style
      if let popUpbuttonRepresentationStyle: iRASPAPopUpButton = view.viewWithTag(2) as? iRASPAPopUpButton
      {
        popUpbuttonRepresentationStyle.isEditable = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          popUpbuttonRepresentationStyle.isEditable = enabled
          
          if let representationStyle = self.getRepresentationStyle()
          {
            popUpbuttonRepresentationStyle.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
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
            popUpbuttonRepresentationStyle.setTitle(NSLocalizedString("Multiple Values", comment: ""))
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
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          popUpbuttonColorScheme.isEditable = enabled
          
          if let rawValue: String = self.getRepresentationColorScheme()
          {
            popUpbuttonColorScheme.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpbuttonColorScheme.selectItem(withTitle: rawValue)
          }
          else
          {
            popUpbuttonColorScheme.setTitle(NSLocalizedString("Multiple Values", comment: ""))
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
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          popUpbuttonForceField.isEditable = enabled
          
          if let rawValue: String = self.getRepresentationForceField()
          {
            popUpbuttonForceField.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpbuttonForceField.selectItem(withTitle: rawValue)
          }
          else
          {
            popUpbuttonForceField.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
      }
      
      
      // Color order
      if let popUpbuttonColorOrder: iRASPAPopUpButton = view.viewWithTag(5) as? iRASPAPopUpButton
      {
        popUpbuttonColorOrder.isEditable = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          popUpbuttonColorOrder.isEditable = enabled
          
          if let rawValue: Int = self.getRepresentationColorOrder()?.rawValue
          {
            popUpbuttonColorOrder.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpbuttonColorOrder.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonColorOrder.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
      }
      
      // Force field order
      if let popUpbuttonForceFieldOrder: iRASPAPopUpButton = view.viewWithTag(6) as? iRASPAPopUpButton
      {
        popUpbuttonForceFieldOrder.isEditable = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          popUpbuttonForceFieldOrder.isEditable = enabled
          
          if let rawValue: Int = self.getRepresentationForceFieldOrder()?.rawValue
          {
            popUpbuttonForceFieldOrder.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpbuttonForceFieldOrder.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonForceFieldOrder.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
      }
    case "AtomsSelectionCell":
      // Selection-style
      if let popUpbuttonSelectionStyle: iRASPAPopUpButton = view.viewWithTag(1) as? iRASPAPopUpButton,
         let textFieldSelectionFrequency: NSTextField = view.viewWithTag(2) as? NSTextField,
         let textFieldSelectionDensity: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        popUpbuttonSelectionStyle.isEditable = false
        textFieldSelectionFrequency.isEditable = false
        textFieldSelectionFrequency.stringValue = ""
        textFieldSelectionDensity.isEditable = false
        textFieldSelectionDensity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          popUpbuttonSelectionStyle.isEditable = enabled
          textFieldSelectionFrequency.isEditable = enabled
          textFieldSelectionDensity.isEditable = enabled
          
          if let selectionStyle: RKSelectionStyle = self.renderAtomSelectionStyle
          {
            popUpbuttonSelectionStyle.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpbuttonSelectionStyle.selectItem(at: selectionStyle.rawValue)
            
            if selectionStyle == .glow
            {
              textFieldSelectionFrequency.isEditable = false
              textFieldSelectionDensity.isEditable = false
            }
          }
          else
          {
            popUpbuttonSelectionStyle.setTitle(NSLocalizedString("Multiple Values", comment: ""))
            textFieldSelectionFrequency.stringValue = NSLocalizedString("Mult. Val.", comment: "")
            textFieldSelectionDensity.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
          
          if let renderSelectionFrequency: Double = self.renderAtomSelectionFrequency
          {
            textFieldSelectionFrequency.doubleValue = renderSelectionFrequency
          }
          else
          {
            textFieldSelectionFrequency.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
          
          if let renderSelectionDensity: Double = self.renderAtomSelectionDensity
          {
            textFieldSelectionDensity.doubleValue = renderSelectionDensity
          }
          else
          {
            textFieldSelectionDensity.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }

      if let textFieldAtomSelectionIntensityLevel: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldAtomSelectionIntensityLevel.isEditable = false
        textFieldAtomSelectionIntensityLevel.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          textFieldAtomSelectionIntensityLevel.isEditable = enabled
          if let renderAtomSelectionIntensityLevel: Double = self.renderAtomSelectionIntensity
          {
            textFieldAtomSelectionIntensityLevel.doubleValue = renderAtomSelectionIntensityLevel
          }
          else
          {
            textFieldAtomSelectionIntensityLevel.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      
      if let sliderAtomSelectionIntensityLevel: NSSlider = view.viewWithTag(5) as? NSSlider
      {
        sliderAtomSelectionIntensityLevel.isEnabled = false
        sliderAtomSelectionIntensityLevel.minValue = 0.0
        sliderAtomSelectionIntensityLevel.maxValue = 1.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          sliderAtomSelectionIntensityLevel.isEnabled = enabled
          if let renderAtomSelectionIntensityLevel: Double = self.renderAtomSelectionIntensity
          {
            sliderAtomSelectionIntensityLevel.doubleValue = renderAtomSelectionIntensityLevel
          }
        }
      }
      
    
      if let textFieldSelectionScaling: NSTextField = view.viewWithTag(6) as? NSTextField
      {
        textFieldSelectionScaling.isEditable = false
        textFieldSelectionScaling.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          textFieldSelectionScaling.isEditable = enabled
          if let renderAtomSelectionIntensityLevel: Double = self.renderAtomSelectionScaling
          {
            textFieldSelectionScaling.doubleValue = renderAtomSelectionIntensityLevel
          }
          else
          {
            textFieldSelectionScaling.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderSelectionScaling: NSSlider = view.viewWithTag(7) as? NSSlider
      {
        sliderSelectionScaling.isEnabled = false
        sliderSelectionScaling.minValue = 1.0
        sliderSelectionScaling.maxValue = 2.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          sliderSelectionScaling.isEnabled = enabled
          if let renderSelectionScaling: Double = self.renderAtomSelectionScaling
          {
            sliderSelectionScaling.doubleValue = renderSelectionScaling
          }
        }
      }
      
    case "AtomsHDRCell":
      // High dynamic range
      if let button: NSButton = view.viewWithTag(1) as? NSButton
      {
        button.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          button.isEnabled = enabled
          
          if let renderAtomHDR: Bool = self.renderAtomHDR
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
      if let textFieldExposure: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldExposure.isEditable = false
        textFieldExposure.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          textFieldExposure.isEditable = enabled
          if let renderAtomHDRExposure: Double = self.renderAtomHDRExposure
          {
            textFieldExposure.doubleValue = renderAtomHDRExposure
          }
          else
          {
            textFieldExposure.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderExposure: NSSlider = view.viewWithTag(3) as? NSSlider
      {
        sliderExposure.isEnabled = false
        sliderExposure.minValue = 0.0
        sliderExposure.maxValue = 3.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          sliderExposure.isEnabled = enabled
          if let renderAtomHDRExposure: Double = self.renderAtomHDRExposure
          {
            sliderExposure.doubleValue = renderAtomHDRExposure
          }
        }
      }
      
      // Hue
      if let textFieldHue: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldHue.isEditable = false
        textFieldHue.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          textFieldHue.isEditable = enabled
          if let renderHue: Double = self.renderAtomHue
          {
            textFieldHue.doubleValue = renderHue
          }
          else
          {
            textFieldHue.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderHue: NSSlider = view.viewWithTag(5) as? NSSlider
      {
        sliderHue.isEnabled = false
        sliderHue.minValue = 0.0
        sliderHue.maxValue = 1.5
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          sliderHue.isEnabled = enabled
          if let renderHue: Double = self.renderAtomHue
          {
            sliderHue.doubleValue = renderHue
          }
        }
      }
      
      // Saturation
      if let textFieldSaturation: NSTextField = view.viewWithTag(6) as? NSTextField
      {
        textFieldSaturation.isEditable = false
        textFieldSaturation.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          textFieldSaturation.isEditable = enabled
          if let renderSaturation = self.renderAtomSaturation
          {
            textFieldSaturation.doubleValue = renderSaturation
          }
          else
          {
            textFieldSaturation.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderSaturation: NSSlider = view.viewWithTag(7) as? NSSlider
      {
        sliderSaturation.isEnabled = false
        sliderSaturation.minValue = 0.0
        sliderSaturation.maxValue = 1.5
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          sliderSaturation.isEnabled = enabled
          if let renderSaturation = self.renderAtomSaturation
          {
            sliderSaturation.doubleValue = renderSaturation
          }
        }
      }
      
      // Value
      if let textFieldValue: NSTextField = view.viewWithTag(8) as? NSTextField
      {
        textFieldValue.isEditable = false
        textFieldValue.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          textFieldValue.isEditable = enabled
          if let renderValue: Double = self.renderAtomValue
          {
            textFieldValue.doubleValue = renderValue
          }
          else
          {
            textFieldValue.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderValue: NSSlider = view.viewWithTag(9) as? NSSlider
      {
        sliderValue.isEnabled = false
        sliderValue.minValue = 0.0
        sliderValue.maxValue = 1.5
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          sliderValue.isEnabled = enabled
          if let renderValue: Double = self.renderAtomValue
          {
            sliderValue.doubleValue = renderValue
          }
        }
      }
    
    
    case "AtomsScalingCell":
      // Draw atoms yes/no
      if let checkDrawAtomsbutton: NSButton = view.viewWithTag(1) as? NSButton
      {
        checkDrawAtomsbutton.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          checkDrawAtomsbutton.isEnabled = enabled
          if let renderDrawAtoms: Bool = self.renderDrawAtoms
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
      if let textFieldAtomScaling: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldAtomScaling.isEditable = false
        textFieldAtomScaling.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          textFieldAtomScaling.isEditable = enabled
          if let renderAtomScaleFactor: Double = self.renderAtomScaleFactor
          {
            textFieldAtomScaling.doubleValue = renderAtomScaleFactor
          }
          else
          {
            textFieldAtomScaling.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      
      if let sliderAtomScaling: NSSlider = view.viewWithTag(3) as? NSSlider
      {
        sliderAtomScaling.isEnabled = false
        sliderAtomScaling.minValue = 0.1
        sliderAtomScaling.maxValue = 2.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          sliderAtomScaling.isEnabled = enabled
          if let renderAtomScaleFactor: Double = self.renderAtomScaleFactor
          {
            sliderAtomScaling.doubleValue = renderAtomScaleFactor
          }
        }
      }
    case "AtomsLightingCell":
      // Ambient occlusion
      if let buttonAmbientOcclusion: NSButton = view.viewWithTag(1) as? NSButton
      {
        buttonAmbientOcclusion.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          buttonAmbientOcclusion.isEnabled = enabled
          if let renderAtomAmbientOcclusion: Bool = self.renderAtomAmbientOcclusion
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
      if let ambientLightIntensitity: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        ambientLightIntensitity.isEditable = false
        ambientLightIntensitity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          ambientLightIntensitity.isEditable = enabled
          if let renderAtomAmbientIntensity: Double = self.renderAtomAmbientIntensity
          {
            ambientLightIntensitity.doubleValue = renderAtomAmbientIntensity
          }
          else
          {
            ambientLightIntensitity.stringValue = NSLocalizedString("Mult. V.", comment: "")
          }
          
        }
      }
      if let sliderAmbientLightIntensitity: NSSlider = view.viewWithTag(3) as? NSSlider
      {
        sliderAmbientLightIntensitity.isEnabled = false
        sliderAmbientLightIntensitity.minValue = 0.0
        sliderAmbientLightIntensitity.maxValue = 1.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          sliderAmbientLightIntensitity.isEnabled = enabled
          if let renderAtomAmbientIntensity: Double = self.renderAtomAmbientIntensity
          {
            sliderAmbientLightIntensitity.doubleValue = renderAtomAmbientIntensity
          }
        }
      }
      if let ambientColor: NSColorWell = view.viewWithTag(4) as? NSColorWell
      {
        ambientColor.isEnabled = false
        ambientColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          ambientColor.isEnabled = enabled
          if let renderAtomAmbientColor: NSColor = self.renderAtomAmbientColor
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
      if let diffuseLightIntensitity: NSTextField = view.viewWithTag(5) as? NSTextField
      {
        diffuseLightIntensitity.isEditable = false
        diffuseLightIntensitity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          diffuseLightIntensitity.isEditable = enabled
          if let renderAtomDiffuseIntensity: Double = self.renderAtomDiffuseIntensity
          {
            diffuseLightIntensitity.doubleValue = renderAtomDiffuseIntensity
          }
          else
          {
            diffuseLightIntensitity.stringValue = NSLocalizedString("Mult. V.", comment: "")
          }
        }
      }
      if let sliderDiffuseLightIntensitity: NSSlider = view.viewWithTag(6) as? NSSlider
      {
        sliderDiffuseLightIntensitity.isEnabled = false
        sliderDiffuseLightIntensitity.minValue = 0.0
        sliderDiffuseLightIntensitity.maxValue = 1.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          sliderDiffuseLightIntensitity.isEnabled = enabled
          if let renderAtomDiffuseIntensity: Double = self.renderAtomDiffuseIntensity
          {
            sliderDiffuseLightIntensitity.doubleValue = renderAtomDiffuseIntensity
          }
        }
      }
      if let diffuseColor: NSColorWell = view.viewWithTag(7) as? NSColorWell
      {
        diffuseColor.isEnabled = false
        diffuseColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          diffuseColor.isEnabled = enabled
          if let renderAtomDiffuseColor: NSColor = self.renderAtomDiffuseColor
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
      if let specularLightIntensitity: NSTextField = view.viewWithTag(8) as? NSTextField
      {
        specularLightIntensitity.isEditable = false
        specularLightIntensitity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          specularLightIntensitity.isEditable = enabled
          if let renderAtomSpecularIntensity: Double = self.renderAtomSpecularIntensity
          {
            specularLightIntensitity.doubleValue = renderAtomSpecularIntensity
          }
          else
          {
            specularLightIntensitity.stringValue = NSLocalizedString("Mult. V.", comment: "")
          }
        }
      }
      if let sliderSpecularLightIntensitity: NSSlider = view.viewWithTag(9) as? NSSlider
      {
        sliderSpecularLightIntensitity.isEnabled = false
        sliderSpecularLightIntensitity.minValue = 0.0
        sliderSpecularLightIntensitity.maxValue = 1.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          sliderSpecularLightIntensitity.isEnabled = enabled
          if let renderAtomSpecularIntensity: Double = self.renderAtomSpecularIntensity
          {
            sliderSpecularLightIntensitity.doubleValue = renderAtomSpecularIntensity
          }
        }
      }
      if let specularColor: NSColorWell = view.viewWithTag(10) as? NSColorWell
      {
        specularColor.isEnabled = false
        specularColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          specularColor.isEnabled = enabled
          if let renderAtomSpecularColor: NSColor = self.renderAtomSpecularColor
          {
            specularColor.color = renderAtomSpecularColor
          }
        }
      }
      
      // Atom specular shininess
      if let shininess: NSTextField = view.viewWithTag(11) as? NSTextField
      {
        shininess.isEditable = false
        shininess.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          shininess.isEditable = enabled
          if let renderAtomShininess: Double = self.renderAtomShininess
          {
            shininess.doubleValue = renderAtomShininess
          }
          else
          {
            shininess.stringValue = NSLocalizedString("Mult. V.", comment: "")
          }
        }
      }
      if let sliderShininess: NSSlider = view.viewWithTag(12) as? NSSlider
      {
        sliderShininess.isEnabled = false
        sliderShininess.minValue = 0.1
        sliderShininess.maxValue = 128.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AtomStructureEditor}).isEmpty
        {
          sliderShininess.isEnabled = enabled
          if let renderAtomShininess: Double = self.renderAtomShininess
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
    case "BondsScalingCell":
      // Draw bonds yes/no
      if let checkDrawBondsbutton: NSButton = view.viewWithTag(1) as? NSButton
      {
        checkDrawBondsbutton.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          checkDrawBondsbutton.isEnabled = enabled
          if let renderDrawBonds: Bool = self.renderDrawBonds
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
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          textFieldBondScaling.isEditable = enabled
          if let renderBondScaleFactor: Double = self.renderBondScaleFactor
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
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          sliderBondScaling.isEnabled = enabled
          if let renderBondScaleFactor: Double = self.renderBondScaleFactor
          {
            sliderBondScaling.doubleValue = renderBondScaleFactor
          }
        }
      }
      
      // Bond color mode
      if let popUpbuttonBondColorMode: iRASPAPopUpButton = view.viewWithTag(4) as? iRASPAPopUpButton
      {
        popUpbuttonBondColorMode.isEditable = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          popUpbuttonBondColorMode.isEditable = enabled
          if let rawValue: Int = self.renderBondColorMode?.rawValue
          {
            popUpbuttonBondColorMode.selectItem(at: rawValue)
          }
        }
      }
    case "BondsSelectionCell":
      // Selection-style
      if let popUpbuttonSelectionStyle: iRASPAPopUpButton = view.viewWithTag(1) as? iRASPAPopUpButton,
         let textFieldSelectionFrequency: NSTextField = view.viewWithTag(2) as? NSTextField,
         let textFieldSelectionDensity: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        popUpbuttonSelectionStyle.isEditable = false
        textFieldSelectionFrequency.isEditable = false
        textFieldSelectionFrequency.stringValue = ""
        textFieldSelectionDensity.isEditable = false
        textFieldSelectionDensity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          popUpbuttonSelectionStyle.isEditable = enabled
          textFieldSelectionFrequency.isEditable = enabled
          textFieldSelectionDensity.isEditable = enabled
          
          if let selectionStyle: RKSelectionStyle = self.renderBondSelectionStyle
          {
            popUpbuttonSelectionStyle.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpbuttonSelectionStyle.selectItem(at: selectionStyle.rawValue)
            
            if selectionStyle == .glow
            {
              textFieldSelectionFrequency.isEditable = false
              textFieldSelectionDensity.isEditable = false
            }
          }
          else
          {
            popUpbuttonSelectionStyle.setTitle(NSLocalizedString("Multiple Values", comment: ""))
            textFieldSelectionFrequency.stringValue = NSLocalizedString("Mult. Val.", comment: "")
            textFieldSelectionDensity.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
          
          if let renderSelectionFrequency: Double = self.renderBondSelectionFrequency
          {
            textFieldSelectionFrequency.doubleValue = renderSelectionFrequency
          }
          else
          {
            textFieldSelectionFrequency.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
          
          if let renderSelectionDensity: Double = self.renderBondSelectionDensity
          {
            textFieldSelectionDensity.doubleValue = renderSelectionDensity
          }
          else
          {
            textFieldSelectionDensity.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      
      if let textFieldBondSelectionIntensityLevel: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldBondSelectionIntensityLevel.isEditable = false
        textFieldBondSelectionIntensityLevel.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
          {
            textFieldBondSelectionIntensityLevel.isEditable = enabled
            if let renderBondSelectionIntensityLevel: Double = self.renderBondSelectionIntensity
            {
              textFieldBondSelectionIntensityLevel.doubleValue = renderBondSelectionIntensityLevel
            }
            else
            {
              textFieldBondSelectionIntensityLevel.stringValue = NSLocalizedString("Multiple Values", comment: "")
            }
          }
        }
        
        if let sliderBondSelectionIntensityLevel: NSSlider = view.viewWithTag(5) as? NSSlider
        {
          sliderBondSelectionIntensityLevel.isEnabled = false
          sliderBondSelectionIntensityLevel.minValue = 0.0
          sliderBondSelectionIntensityLevel.maxValue = 1.0
          if let proxyProject = proxyProject, proxyProject.isEditable,
             !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
          {
            sliderBondSelectionIntensityLevel.isEnabled = enabled
            if let renderBondSelectionIntensityLevel: Double = self.renderBondSelectionIntensity
            {
              sliderBondSelectionIntensityLevel.doubleValue = renderBondSelectionIntensityLevel
            }
          }
        }
        
      
        if let textFieldBondSelectionScaling: NSTextField = view.viewWithTag(6) as? NSTextField
        {
          textFieldBondSelectionScaling.isEditable = false
          textFieldBondSelectionScaling.stringValue = ""
          if let proxyProject = proxyProject, proxyProject.isEditable,
             !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
          {
            textFieldBondSelectionScaling.isEditable = enabled
            if let renderBondSelectionScaling: Double = self.renderBondSelectionScaling
            {
              textFieldBondSelectionScaling.doubleValue = renderBondSelectionScaling
            }
            else
            {
              textFieldBondSelectionScaling.stringValue = NSLocalizedString("Multiple Values", comment: "")
            }
          }
        }
        if let sliderBondSelectionScaling: NSSlider = view.viewWithTag(7) as? NSSlider
        {
          sliderBondSelectionScaling.isEnabled = false
          sliderBondSelectionScaling.minValue = 1.0
          sliderBondSelectionScaling.maxValue = 2.0
          if let proxyProject = proxyProject, proxyProject.isEditable,
             !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
          {
            sliderBondSelectionScaling.isEnabled = enabled
            if let renderBondSelectionScaling: Double = self.renderBondSelectionScaling
            {
              sliderBondSelectionScaling.doubleValue = renderBondSelectionScaling
            }
          }
        }
    case "BondsHDRCell":
      // Use High Dynamic Range yes/no
      if let checkDrawHDRButton: NSButton = view.viewWithTag(1) as? NSButton
      {
        checkDrawHDRButton.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          checkDrawHDRButton.isEnabled = enabled
          if let renderHighDynamicRange: Bool = self.renderBondHDR
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
      if let textFieldExposure: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldExposure.isEditable = false
        textFieldExposure.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          textFieldExposure.isEditable = enabled
          if let renderBondHDRExposure: Double = self.renderBondHDRExposure
          {
            textFieldExposure.doubleValue = renderBondHDRExposure
          }
        }
      }
      if let sliderExposure: NSSlider = view.viewWithTag(3) as? NSSlider
      {
        sliderExposure.isEnabled = false
        sliderExposure.minValue = 0.0
        sliderExposure.maxValue = 3.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          sliderExposure.isEnabled = enabled
          if let renderBondHDRExposure: Double = self.renderBondHDRExposure
          {
            sliderExposure.doubleValue = renderBondHDRExposure
          }
        }
      }
      
      // Hue
      if let textFieldHue: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldHue.isEditable = false
        textFieldHue.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          textFieldHue.isEditable = enabled
          if let renderBondHue: Double = self.renderBondHue
          {
            textFieldHue.doubleValue = renderBondHue
          }
        }
      }
      if let sliderHue: NSSlider = view.viewWithTag(5) as? NSSlider
      {
        sliderHue.isEnabled = false
        sliderHue.minValue = 0.0
        sliderHue.maxValue = 1.5
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          sliderHue.isEnabled = enabled
          if let renderBondHue: Double = self.renderBondHue
          {
            sliderHue.doubleValue = renderBondHue
          }
        }
      }
      
      // Saturation
      if let textFieldSaturation: NSTextField = view.viewWithTag(6) as? NSTextField
      {
        textFieldSaturation.isEditable = false
        textFieldSaturation.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          textFieldSaturation.isEditable = enabled
          if let renderBondSaturation: Double = self.renderBondSaturation
          {
            textFieldSaturation.doubleValue = renderBondSaturation
          }
        }
      }
      if let sliderSaturation: NSSlider = view.viewWithTag(7) as? NSSlider
      {
        sliderSaturation.isEnabled = false
        sliderSaturation.minValue = 0.0
        sliderSaturation.maxValue = 1.5
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          sliderSaturation.isEnabled = enabled
          if let renderBondSaturation: Double = self.renderBondSaturation
          {
            sliderSaturation.doubleValue = renderBondSaturation
          }
        }
      }
      
      // Value
      if let textFieldValue: NSTextField = view.viewWithTag(8) as? NSTextField
      {
        textFieldValue.isEditable = false
        textFieldValue.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          textFieldValue.isEditable = enabled
          if let renderBondValue: Double = self.renderBondValue
          {
            textFieldValue.doubleValue = renderBondValue
          }
        }
      }
      if let sliderValue: NSSlider = view.viewWithTag(9) as? NSSlider
      {
        sliderValue.isEnabled = false
        sliderValue.minValue = 0.0
        sliderValue.maxValue = 1.5
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          sliderValue.isEnabled = enabled
          if let renderBondValue: Double = self.renderBondValue
          {
            sliderValue.doubleValue = renderBondValue
          }
        }
      }
      
    case "BondsLightingCell":
      // Use ambient occlusion yes/no
      if let buttonAmbientOcclusion: NSButton = view.viewWithTag(1) as? NSButton
      {
        buttonAmbientOcclusion.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          buttonAmbientOcclusion.isEnabled = enabled
          
          if let renderBondAmbientOcclusion: Bool = self.renderBondAmbientOcclusion
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
      if let ambientLightIntensitity: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        ambientLightIntensitity.isEditable = false
        ambientLightIntensitity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          ambientLightIntensitity.isEditable = enabled
          if let renderBondAmbientIntensity: Double = self.renderBondAmbientIntensity
          {
            ambientLightIntensitity.doubleValue = renderBondAmbientIntensity
          }
        }
      }
      if let sliderAmbientLightIntensitity: NSSlider = view.viewWithTag(3) as? NSSlider
      {
        sliderAmbientLightIntensitity.isEnabled = false
        sliderAmbientLightIntensitity.minValue = 0.0
        sliderAmbientLightIntensitity.maxValue = 1.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          sliderAmbientLightIntensitity.isEnabled = enabled
          if let renderBondAmbientIntensity: Double = self.renderBondAmbientIntensity
          {
            sliderAmbientLightIntensitity.doubleValue = renderBondAmbientIntensity
          }
        }
      }
      if let ambientColor: NSColorWell = view.viewWithTag(4) as? NSColorWell
      {
        ambientColor.isEnabled = false
        ambientColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          ambientColor.isEnabled = enabled
          if let renderBondAmbientColor: NSColor = self.renderBondAmbientColor
          {
            ambientColor.color = renderBondAmbientColor
          }
        }
      }
      
      // Bond diffuse light
      if let diffuseLightIntensitity: NSTextField = view.viewWithTag(5) as? NSTextField
      {
        diffuseLightIntensitity.isEditable = false
        diffuseLightIntensitity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          diffuseLightIntensitity.isEditable = enabled
          if let renderBondDiffuseIntensity: Double = self.renderBondDiffuseIntensity
          {
            diffuseLightIntensitity.doubleValue = renderBondDiffuseIntensity
          }
        }
      }
      if let sliderDiffuseLightIntensitity: NSSlider = view.viewWithTag(6) as? NSSlider
      {
        sliderDiffuseLightIntensitity.isEnabled = false
        sliderDiffuseLightIntensitity.minValue = 0.0
        sliderDiffuseLightIntensitity.maxValue = 1.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          sliderDiffuseLightIntensitity.isEnabled = enabled
          if let renderBondDiffuseIntensity: Double = self.renderBondDiffuseIntensity
          {
            sliderDiffuseLightIntensitity.doubleValue = renderBondDiffuseIntensity
          }
        }
      }
      if let diffuseColor: NSColorWell = view.viewWithTag(7) as? NSColorWell
      {
        diffuseColor.isEnabled = false
        diffuseColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          diffuseColor.isEnabled = enabled
          if let renderBondDiffuseColor: NSColor = self.renderBondDiffuseColor
          {
            diffuseColor.color = renderBondDiffuseColor
          }
        }
      }
      
      // Atom specular light
      if let specularLightIntensitity: NSTextField = view.viewWithTag(8) as? NSTextField
      {
        specularLightIntensitity.isEditable = false
        specularLightIntensitity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          specularLightIntensitity.isEditable = enabled
          if let renderBondSpecularIntensity: Double = self.renderBondSpecularIntensity
          {
            specularLightIntensitity.doubleValue = renderBondSpecularIntensity
          }
        }
      }
      if let sliderSpecularLightIntensitity: NSSlider = view.viewWithTag(9) as? NSSlider
      {
        sliderSpecularLightIntensitity.isEnabled = false
        sliderSpecularLightIntensitity.minValue = 0.0
        sliderSpecularLightIntensitity.maxValue = 1.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          sliderSpecularLightIntensitity.isEnabled = enabled
          if let renderBondSpecularIntensity: Double = self.renderBondSpecularIntensity
          {
            sliderSpecularLightIntensitity.doubleValue = renderBondSpecularIntensity
          }
        }
      }
      if let specularColor: NSColorWell = view.viewWithTag(10) as? NSColorWell
      {
        specularColor.isEnabled = false
        specularColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          specularColor.isEnabled = enabled
          if let renderBondSpecularColor: NSColor = self.renderBondSpecularColor
          {
            specularColor.color = renderBondSpecularColor
          }
        }
      }
      
      // Bond specular shininess
      if let shininess: NSTextField = view.viewWithTag(11) as? NSTextField
      {
        shininess.isEditable = false
        shininess.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          shininess.isEditable = enabled
          if let renderBondShininess: Double = self.renderBondShininess
          {
            shininess.doubleValue = renderBondShininess
          }
        }
      }
      if let sliderShininess: NSSlider = view.viewWithTag(12) as? NSSlider
      {
        sliderShininess.isEnabled = false
        sliderShininess.minValue = 0.1
        sliderShininess.maxValue = 128.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is BondStructureEditor}).isEmpty
        {
          sliderShininess.isEnabled = enabled
          if let renderBondShininess: Double = self.renderBondShininess
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
      if let checkDrawUnitCellButton: NSButton = view.viewWithTag(1) as? NSButton
      {
        checkDrawUnitCellButton.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is UnitCellViewer}).isEmpty
        {
          checkDrawUnitCellButton.isEnabled = enabled
          
          if let renderDrawUnitCell: Bool = self.renderDrawUnitCell
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
      
      if let unitCellScaling: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        unitCellScaling.isEditable = false
        unitCellScaling.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is UnitCellEditor}).isEmpty
        {
          unitCellScaling.isEditable = enabled
          if let renderUnitCellScaleFactor: Double = self.renderUnitCellScaleFactor
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
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is UnitCellEditor}).isEmpty
        {
          sliderUnitCellScaling.isEnabled = enabled
          if let renderUnitCellScaleFactor: Double = self.renderUnitCellScaleFactor
          {
            sliderUnitCellScaling.doubleValue = renderUnitCellScaleFactor
          }
        }
      }
      
      if let unitCellLightIntensitity: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        unitCellLightIntensitity.isEditable = false
        unitCellLightIntensitity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is UnitCellEditor}).isEmpty
        {
          unitCellLightIntensitity.isEditable = enabled
          if let renderUnitCellDiffuseIntensity: Double = self.renderUnitCellDiffuseIntensity
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
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is UnitCellEditor}).isEmpty
        {
          sliderUnitCellLightIntensitity.isEnabled = enabled
          if let renderUnitCellDiffuseIntensity: Double = self.renderUnitCellDiffuseIntensity
          {
            sliderUnitCellLightIntensitity.doubleValue = renderUnitCellDiffuseIntensity
          }
        }
      }
      
      if let unitCellColor: NSColorWell = view.viewWithTag(6) as? NSColorWell
      {
        unitCellColor.isEnabled = false
        unitCellColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is UnitCellEditor}).isEmpty
        {
          unitCellColor.isEnabled = enabled
          if let renderUnitCellDiffuseColor: NSColor = self.renderUnitCellDiffuseColor
          {
            unitCellColor.color = renderUnitCellDiffuseColor
          }
        }
      }
    default:
      break
    }
  }
  
  
  func setPropertiesLocalAxesTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    switch(identifier)
    {
    case "LocalAxesCell":
      if let popUpbuttonPosition: iRASPAPopUpButton = view.viewWithTag(1) as? iRASPAPopUpButton
      {
        popUpbuttonPosition.isEditable = false
        if let proxyProject = proxyProject, proxyProject.isEditable
        {
          popUpbuttonPosition.isEditable = enabled
          
          if let rawValue = self.renderLocalAxesPosition?.rawValue
          {
            popUpbuttonPosition.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpbuttonPosition.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonPosition.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
      }
      if let popUpbuttonStyle: iRASPAPopUpButton = view.viewWithTag(2) as? iRASPAPopUpButton
      {
        popUpbuttonStyle.isEditable = false
        if let proxyProject = proxyProject, proxyProject.isEditable
        {
          popUpbuttonStyle.isEditable = enabled
          
          if let rawValue = self.renderLocalAxesStyle?.rawValue
          {
            popUpbuttonStyle.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpbuttonStyle.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonStyle.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
      }
      if let popUpbuttonScalingType: iRASPAPopUpButton = view.viewWithTag(3) as? iRASPAPopUpButton
      {
        popUpbuttonScalingType.isEditable = false
        if let proxyProject = proxyProject, proxyProject.isEditable
        {
          popUpbuttonScalingType.isEditable = enabled
          
          if let rawValue = self.renderLocalAxesScalingType?.rawValue
          {
            popUpbuttonScalingType.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpbuttonScalingType.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonScalingType.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
      }
      if let textFieldLength: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldLength.isEditable = false
        textFieldLength.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable
        {
          textFieldLength.isEditable = enabled
          if let value = self.renderLocalAxesLength
          {
            textFieldLength.doubleValue = value
          }
          else
          {
            textFieldLength.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let sliderLength: NSSlider = view.viewWithTag(5) as? NSSlider
      {
        sliderLength.isEnabled = false
        sliderLength.minValue = 0.0
        sliderLength.maxValue = 10.0
        if let proxyProject = proxyProject, proxyProject.isEditable
        {
          sliderLength.isEnabled = enabled
          if let renderLengthFactor: Double = self.renderLocalAxesLength
          {
            sliderLength.doubleValue = renderLengthFactor
          }
        }
      }
      if let textFieldWidth: NSTextField = view.viewWithTag(6) as? NSTextField
      {
        textFieldWidth.isEditable = false
        textFieldWidth.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable
        {
          textFieldWidth.isEditable = enabled
          if let value = self.renderLocalAxesWidth
          {
            textFieldWidth.doubleValue = value
          }
          else
          {
            textFieldWidth.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let sliderWidth: NSSlider = view.viewWithTag(7) as? NSSlider
      {
        sliderWidth.isEnabled = false
        sliderWidth.minValue = 0.0
        sliderWidth.maxValue = 2.0
        if let proxyProject = proxyProject, proxyProject.isEditable
        {
          sliderWidth.isEnabled = enabled
          if let renderWidthFactor: Double = self.renderLocalAxesWidth
          {
            sliderWidth.doubleValue = renderWidthFactor
          }
        }
      }
      if let textFieldOffsetX: NSTextField = view.viewWithTag(8) as? NSTextField
      {
        textFieldOffsetX.isEditable = false
        textFieldOffsetX.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable
        {
          textFieldOffsetX.isEditable = enabled
          if let value = self.renderLocalAxesOffsetX
          {
            textFieldOffsetX.doubleValue = value
          }
          else
          {
            textFieldOffsetX.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldOffsetY: NSTextField = view.viewWithTag(9) as? NSTextField
      {
        textFieldOffsetY.isEditable = false
        textFieldOffsetY.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable
        {
          textFieldOffsetY.isEditable = enabled
          if let value = self.renderLocalAxesOffsetY
          {
            textFieldOffsetY.doubleValue = value
          }
          else
          {
            textFieldOffsetY.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldOffsetZ: NSTextField = view.viewWithTag(10) as? NSTextField
      {
        textFieldOffsetZ.isEditable = false
        textFieldOffsetZ.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable
        {
          textFieldOffsetZ.isEditable = enabled
          if let value = self.renderLocalAxesOffsetZ
          {
            textFieldOffsetZ.doubleValue = value
          }
          else
          {
            textFieldOffsetZ.stringValue = NSLocalizedString("Mult. Val.", comment: "")
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
    if let proxyProject = proxyProject, proxyProject.isEditable,
       !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
    {
      adsorptionSurfaceOn = self.renderAdsorptionSurfaceOn ?? false
    }
    
    switch(identifier)
    {
    case "AdsorptionPropertiesCell":
      // Use unit cell yes/no
      if let checkDrawAdsorptionSurfacebutton: NSButton = view.viewWithTag(1) as? NSButton
      {
        checkDrawAdsorptionSurfacebutton.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          checkDrawAdsorptionSurfacebutton.isEnabled = enabled
          
          if let renderDrawAdsorptionSurface: Bool = self.renderAdsorptionSurfaceOn
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
      
      // Rendering Method
      if let popUpbuttonRenderingType: iRASPAPopUpButton = view.viewWithTag(52) as? iRASPAPopUpButton
      {
        popUpbuttonRenderingType.isEditable = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          popUpbuttonRenderingType.isEditable = enabled && adsorptionSurfaceOn
          if let rawValue: Int = self.renderAdsorptionRenderingMethod?.rawValue
          {
            popUpbuttonRenderingType.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            
            popUpbuttonRenderingType.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonRenderingType.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
      }
      
      // Steplength
      if let textFieldStepLength: NSTextField = view.viewWithTag(53) as? NSTextField
      {
        textFieldStepLength.isEditable = false
        textFieldStepLength.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldStepLength.isEditable = enabled && adsorptionSurfaceOn
          if let stepLength = self.renderAdsorptionVolumeStepLength
          {
            textFieldStepLength.doubleValue = stepLength
          }
          else
          {
            textFieldStepLength.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      
      // Transfer Function
      if let popUpbuttonTransferFunction: iRASPAPopUpButton = view.viewWithTag(54) as? iRASPAPopUpButton
      {
        popUpbuttonTransferFunction.isEditable = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          popUpbuttonTransferFunction.isEditable = enabled && adsorptionSurfaceOn
          if let rawValue: Int = self.renderAdsorptionVolumeTransferFunction?.rawValue
          {
            popUpbuttonTransferFunction.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            
            popUpbuttonTransferFunction.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonTransferFunction.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
      }
      
      // Probe molecule
      if let popUpbuttonProbeParticle: iRASPAPopUpButton = view.viewWithTag(2) as? iRASPAPopUpButton
      {
        popUpbuttonProbeParticle.isEditable = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          popUpbuttonProbeParticle.isEditable = enabled && adsorptionSurfaceOn
          if let rawValue: Int = self.renderAdsorptionSurfaceProbeMolecule?.rawValue
          {
            popUpbuttonProbeParticle.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            
            popUpbuttonProbeParticle.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonProbeParticle.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
      }
      
      if let textFieldIsovalue: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldIsovalue.isEditable = false
        textFieldIsovalue.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldIsovalue.isEditable = enabled && adsorptionSurfaceOn
          if let isovalue = self.renderAdsorptionSurfaceIsovalue
          {
            textFieldIsovalue.doubleValue = isovalue
          }
          else
          {
            textFieldIsovalue.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let sliderIsovalue: NSSlider = view.viewWithTag(4) as? NSSlider
      {
        sliderIsovalue.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderIsovalue.isEnabled = enabled && adsorptionSurfaceOn
          if let isovalue = self.renderAdsorptionSurfaceIsovalue,
             let minimumValue: Double = self.renderAdsorptionSurfaceMinimumValue,
             let maximimValue: Double = self.renderAdsorptionSurfaceMaximumValue
          {
            sliderIsovalue.minValue = minimumValue
            sliderIsovalue.maxValue = maximimValue
            sliderIsovalue.doubleValue = isovalue
          }
        }
      }
      
      
      if let textFieldOpacity: NSTextField = view.viewWithTag(5) as? NSTextField
      {
        textFieldOpacity.isEditable = false
        textFieldOpacity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldOpacity.isEditable = enabled && adsorptionSurfaceOn
          if let opacity = self.renderAdsorptionSurfaceOpacity
          {
            textFieldOpacity.doubleValue = opacity
          }
          else
          {
            textFieldOpacity.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let sliderOpacity: NSSlider = view.viewWithTag(6) as? NSSlider
      {
        sliderOpacity.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderOpacity.isEnabled = enabled && adsorptionSurfaceOn
          if let opacity = self.renderAdsorptionSurfaceOpacity
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
      
      if let textFieldTransparencyThreshold: NSTextField = view.viewWithTag(105) as? NSTextField
      {
        textFieldTransparencyThreshold.isEditable = false
        textFieldTransparencyThreshold.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldTransparencyThreshold.isEditable = enabled && adsorptionSurfaceOn
          if let opacity = self.renderAdsorptionTransparencyThreshold
          {
            textFieldTransparencyThreshold.doubleValue = opacity
          }
          else
          {
            textFieldTransparencyThreshold.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let sliderTransparencyThreshold: NSSlider = view.viewWithTag(106) as? NSSlider
      {
        sliderTransparencyThreshold.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderTransparencyThreshold.isEnabled = enabled && adsorptionSurfaceOn
          if let opacity = self.renderAdsorptionTransparencyThreshold
          {
            sliderTransparencyThreshold.minValue = 0.0
            sliderTransparencyThreshold.maxValue = 1.0
            sliderTransparencyThreshold.doubleValue = opacity
          }
          else
          {
            sliderTransparencyThreshold.minValue = 0.0
            sliderTransparencyThreshold.maxValue = 1.0
            sliderTransparencyThreshold.doubleValue = 0.5
          }
        }
      }
      
      if let popUpbuttonSurfaceSize: iRASPAPopUpButton = view.viewWithTag(7) as? iRASPAPopUpButton,
         let dimensionTextField: NSTextField = view.viewWithTag(8) as? NSTextField
      {
        popUpbuttonSurfaceSize.isEditable = false
        popUpbuttonSurfaceSize.autoenablesItems = false
        
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          popUpbuttonSurfaceSize.isEditable = enabled && adsorptionSurfaceOn
          if let powerOfTwo: Int = self.renderEncompassingPowerOfTwoCubicGridSize,
             let dimensions: SIMD3<Int32> = self.renderGridDimension
          {
            popUpbuttonSurfaceSize.isEnabled = !self.iRASPAObjects.compactMap{($0.object as? IsosurfaceEditor)}.isEmpty
            popUpbuttonSurfaceSize.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpbuttonSurfaceSize.selectItem(at: powerOfTwo)
            
            dimensionTextField.stringValue = "(\(dimensions.x)x\(dimensions.y)x\(dimensions.z))"
          }
          else
          {
            popUpbuttonSurfaceSize.setTitle(NSLocalizedString("Multiple Values", comment: ""))
            dimensionTextField.stringValue = ""
          }
        }
      }
      
      
    case "AdsorptionHSVCell":
      // Hue
      if let textFieldHue: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldHue.isEditable = false
        textFieldHue.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldHue.isEditable = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceHue: Double = self.renderAdsorptionSurfaceHue
          {
            textFieldHue.doubleValue = renderAdsorptionSurfaceHue
          }
        }
      }
      if let sliderHue: NSSlider = view.viewWithTag(2) as? NSSlider
      {
        sliderHue.isEnabled = false
        sliderHue.minValue = 0.0
        sliderHue.maxValue = 1.5
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderHue.isEnabled = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceHue: Double = self.renderAdsorptionSurfaceHue
          {
            sliderHue.doubleValue = renderAdsorptionSurfaceHue
          }
        }
      }
      
      // Saturation
      if let textFieldSaturation: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldSaturation.isEditable = false
        textFieldSaturation.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldSaturation.isEditable = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceSaturation: Double = self.renderAdsorptionSurfaceSaturation
          {
            textFieldSaturation.doubleValue = renderAdsorptionSurfaceSaturation
          }
        }
      }
      if let sliderSaturation: NSSlider = view.viewWithTag(4) as? NSSlider
      {
        sliderSaturation.isEnabled = false
        sliderSaturation.minValue = 0.0
        sliderSaturation.maxValue = 1.5
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderSaturation.isEnabled = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceSaturation: Double = self.renderAdsorptionSurfaceSaturation
          {
            sliderSaturation.doubleValue = renderAdsorptionSurfaceSaturation
          }
        }
      }
      
      // Value
      if let textFieldValue: NSTextField = view.viewWithTag(5) as? NSTextField
      {
        textFieldValue.isEditable = false
        textFieldValue.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldValue.isEditable = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceValue: Double = self.renderAdsorptionSurfaceValue
          {
            textFieldValue.doubleValue = renderAdsorptionSurfaceValue
          }
        }
      }
      if let sliderValue: NSSlider = view.viewWithTag(6) as? NSSlider
      {
        sliderValue.isEnabled = false
        sliderValue.minValue = 0.0
        sliderValue.maxValue = 1.5
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderValue.isEnabled = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceValue: Double = self.renderAdsorptionSurfaceValue
          {
            sliderValue.doubleValue = renderAdsorptionSurfaceValue
          }
        }
      }
      
    case "AdsorptionFrontSurfaceCell":
      // High dynamic range
      if let button: NSButton = view.viewWithTag(1) as? NSButton
      {
        button.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          button.isEnabled = enabled && adsorptionSurfaceOn
          
          if let renderAdsorptionSurfaceHDR: Bool = self.renderAdsorptionSurfaceFrontSideHDR
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
      if let textFieldExposure: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldExposure.isEditable = false
        textFieldExposure.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldExposure.isEditable = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceFrontSideHDRExposure: Double = self.renderAdsorptionSurfaceFrontSideHDRExposure
          {
            textFieldExposure.doubleValue = renderAdsorptionSurfaceFrontSideHDRExposure
          }
          else
          {
            textFieldExposure.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderExposure: NSSlider = view.viewWithTag(3) as? NSSlider
      {
        sliderExposure.isEnabled = false
        sliderExposure.minValue = 0.0
        sliderExposure.maxValue = 3.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderExposure.isEnabled = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceFrontSideHDRExposure: Double = self.renderAdsorptionSurfaceFrontSideHDRExposure
          {
            sliderExposure.doubleValue = renderAdsorptionSurfaceFrontSideHDRExposure
          }
        }
      }
      
      
      // ambient intensity and color
      if let textFieldFrontAmbientIntensity: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldFrontAmbientIntensity.isEditable = false
        textFieldFrontAmbientIntensity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldFrontAmbientIntensity.isEditable = enabled && adsorptionSurfaceOn
          if let ambientIntensity = self.renderAdsorptionSurfaceFrontSideAmbientIntensity
          {
            textFieldFrontAmbientIntensity.doubleValue = ambientIntensity
          }
          else
          {
            textFieldFrontAmbientIntensity.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderFrontAmbientIntensity: NSSlider = view.viewWithTag(5) as? NSSlider
      {
        sliderFrontAmbientIntensity.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderFrontAmbientIntensity.isEnabled = enabled && adsorptionSurfaceOn
          if let ambientIntensity = self.renderAdsorptionSurfaceFrontSideAmbientIntensity
          {
            sliderFrontAmbientIntensity.minValue = 0.0
            sliderFrontAmbientIntensity.maxValue = 1.0
            sliderFrontAmbientIntensity.doubleValue = ambientIntensity
          }
        }
      }
      if let ambientFrontSideColor: NSColorWell = view.viewWithTag(6) as? NSColorWell
      {
        ambientFrontSideColor.isEnabled = false
        ambientFrontSideColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          ambientFrontSideColor.isEnabled = enabled && adsorptionSurfaceOn
          if let color = self.renderAdsorptionSurfaceFrontSideAmbientColor
          {
            ambientFrontSideColor.color = color
          }
        }
      }
      
      // diffuse intensity and color
      if let textFieldFrontDiffuseIntensity: NSTextField = view.viewWithTag(7) as? NSTextField
      {
        textFieldFrontDiffuseIntensity.isEditable = false
        textFieldFrontDiffuseIntensity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldFrontDiffuseIntensity.isEditable = enabled && adsorptionSurfaceOn
          if let diffuseIntensity = self.renderAdsorptionSurfaceFrontSideDiffuseIntensity
          {
            textFieldFrontDiffuseIntensity.doubleValue = diffuseIntensity
          }
          else
          {
            textFieldFrontDiffuseIntensity.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderFrontDiffuseIntensity: NSSlider = view.viewWithTag(8) as? NSSlider
      {
        sliderFrontDiffuseIntensity.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderFrontDiffuseIntensity.isEnabled = enabled && adsorptionSurfaceOn
          if let diffuseIntensity = self.renderAdsorptionSurfaceFrontSideDiffuseIntensity
          {
            sliderFrontDiffuseIntensity.minValue = 0.0
            sliderFrontDiffuseIntensity.maxValue = 1.0
            sliderFrontDiffuseIntensity.doubleValue = diffuseIntensity
          }
        }
      }
      if let diffuseFrontSideColor: NSColorWell = view.viewWithTag(9) as? NSColorWell
      {
        diffuseFrontSideColor.isEnabled = false
        diffuseFrontSideColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          diffuseFrontSideColor.isEnabled = enabled && adsorptionSurfaceOn
          if let color = self.renderAdsorptionSurfaceFrontSideDiffuseColor
          {
            diffuseFrontSideColor.color = color
          }
        }
      }
      
      // specular intensity and color
      if let textFieldFrontSpecularIntensity: NSTextField = view.viewWithTag(10) as? NSTextField
      {
        textFieldFrontSpecularIntensity.isEditable = false
        textFieldFrontSpecularIntensity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldFrontSpecularIntensity.isEditable = enabled && adsorptionSurfaceOn
          if let specularIntensity = self.renderAdsorptionSurfaceFrontSideSpecularIntensity
          {
            textFieldFrontSpecularIntensity.doubleValue = specularIntensity
          }
          else
          {
            textFieldFrontSpecularIntensity.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderFrontSpecularIntensity: NSSlider = view.viewWithTag(11) as? NSSlider
      {
        sliderFrontSpecularIntensity.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderFrontSpecularIntensity.isEnabled = enabled && adsorptionSurfaceOn
          if let specularIntensity = self.renderAdsorptionSurfaceFrontSideSpecularIntensity
          {
            sliderFrontSpecularIntensity.minValue = 0.0
            sliderFrontSpecularIntensity.maxValue = 1.0
            sliderFrontSpecularIntensity.doubleValue = specularIntensity
          }
        }
      }
      if let specularFrontSideColor: NSColorWell = view.viewWithTag(12) as? NSColorWell
      {
        specularFrontSideColor.isEnabled = false
        specularFrontSideColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          specularFrontSideColor.isEnabled = enabled && adsorptionSurfaceOn
          if let color = self.renderAdsorptionSurfaceFrontSideSpecularColor
          {
            specularFrontSideColor.color = color
          }
        }
      }
      
      
      
      if let textFieldFrontShininess: NSTextField = view.viewWithTag(13) as? NSTextField
      {
        textFieldFrontShininess.isEditable = false
        textFieldFrontShininess.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldFrontShininess.isEditable = enabled && adsorptionSurfaceOn
          if let shininess = self.renderAdsorptionSurfaceFrontSideShininess
          {
            textFieldFrontShininess.doubleValue = shininess
          }
          else
          {
            textFieldFrontShininess.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderFrontShininess: NSSlider = view.viewWithTag(14) as? NSSlider
      {
        sliderFrontShininess.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderFrontShininess.isEnabled = enabled && adsorptionSurfaceOn
          if let shininess = self.renderAdsorptionSurfaceFrontSideShininess
          {
            sliderFrontShininess.minValue = 0.0
            sliderFrontShininess.maxValue = 256.0
            sliderFrontShininess.doubleValue = shininess
          }
        }
      }
      
    case "AdsorptionBackSurfaceCell":
      
      // High dynamic range
      if let button: NSButton = view.viewWithTag(1) as? NSButton
      {
        button.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          button.isEnabled = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceHDR: Bool = self.renderAdsorptionSurfaceBackSideHDR
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
      if let textFieldExposure: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldExposure.isEditable = false
        textFieldExposure.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldExposure.isEditable = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceBackSideHDRExposure: Double = self.renderAdsorptionSurfaceBackSideHDRExposure
          {
            textFieldExposure.doubleValue = renderAdsorptionSurfaceBackSideHDRExposure
          }
          else
          {
            textFieldExposure.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderExposure: NSSlider = view.viewWithTag(3) as? NSSlider
      {
        sliderExposure.isEnabled = false
        sliderExposure.minValue = 0.0
        sliderExposure.maxValue = 3.0
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderExposure.isEnabled = enabled && adsorptionSurfaceOn
          if let renderAdsorptionSurfaceBackSideHDRExposure: Double = self.renderAdsorptionSurfaceBackSideHDRExposure
          {
            sliderExposure.doubleValue = renderAdsorptionSurfaceBackSideHDRExposure
          }
        }
      }
      
      
      if let textFieldBackAmbientIntensity: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldBackAmbientIntensity.isEditable = false
        textFieldBackAmbientIntensity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldBackAmbientIntensity.isEditable = enabled && adsorptionSurfaceOn
          if let ambientIntensity = self.renderAdsorptionSurfaceBackSideAmbientIntensity
          {
            textFieldBackAmbientIntensity.doubleValue = ambientIntensity
          }
          else
          {
            textFieldBackAmbientIntensity.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderBackAmbientIntensity: NSSlider = view.viewWithTag(5) as? NSSlider
      {
        sliderBackAmbientIntensity.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderBackAmbientIntensity.isEnabled = enabled && adsorptionSurfaceOn
          if let ambientIntensity = self.renderAdsorptionSurfaceBackSideAmbientIntensity
          {
            sliderBackAmbientIntensity.minValue = 0.0
            sliderBackAmbientIntensity.maxValue = 1.0
            sliderBackAmbientIntensity.doubleValue = ambientIntensity
          }
        }
      }
      if let ambientBackSideColor: NSColorWell = view.viewWithTag(6) as? NSColorWell
      {
        ambientBackSideColor.isEnabled = false
        ambientBackSideColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          ambientBackSideColor.isEnabled = enabled && adsorptionSurfaceOn
          if let color = self.renderAdsorptionSurfaceBackSideAmbientColor
          {
            ambientBackSideColor.color = color
          }
        }
      }
      
      // Diffuse color
      if let textFieldBackDiffuseIntensity: NSTextField = view.viewWithTag(7) as? NSTextField
      {
        textFieldBackDiffuseIntensity.isEditable = false
        textFieldBackDiffuseIntensity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldBackDiffuseIntensity.isEditable = enabled && adsorptionSurfaceOn
          if let diffuseIntensity = self.renderAdsorptionSurfaceBackSideDiffuseIntensity
          {
            textFieldBackDiffuseIntensity.doubleValue = diffuseIntensity
          }
          else
          {
            textFieldBackDiffuseIntensity.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderBackDiffuseIntensity: NSSlider = view.viewWithTag(8) as? NSSlider
      {
        sliderBackDiffuseIntensity.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderBackDiffuseIntensity.isEnabled = enabled && adsorptionSurfaceOn
          if let diffuseIntensity = self.renderAdsorptionSurfaceBackSideDiffuseIntensity
          {
            sliderBackDiffuseIntensity.minValue = 0.0
            sliderBackDiffuseIntensity.maxValue = 1.0
            sliderBackDiffuseIntensity.doubleValue = diffuseIntensity
          }
        }
      }
      if let diffuseBackSideColor: NSColorWell = view.viewWithTag(9) as? NSColorWell
      {
        diffuseBackSideColor.isEnabled = false
        diffuseBackSideColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          diffuseBackSideColor.isEnabled = enabled && adsorptionSurfaceOn
          if let color = self.renderAdsorptionSurfaceBackSideDiffuseColor
          {
            diffuseBackSideColor.color = color
          }
        }
      }
      
      // Specular color
      if let textFieldBackSpecularIntensity: NSTextField = view.viewWithTag(10) as? NSTextField
      {
        textFieldBackSpecularIntensity.isEditable = false
        textFieldBackSpecularIntensity.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldBackSpecularIntensity.isEditable = enabled && adsorptionSurfaceOn
          if let specularIntensity = self.renderAdsorptionSurfaceBackSideSpecularIntensity
          {
            textFieldBackSpecularIntensity.doubleValue = specularIntensity
          }
          else
          {
            textFieldBackSpecularIntensity.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderBackSpecularIntensity: NSSlider = view.viewWithTag(11) as? NSSlider
      {
        sliderBackSpecularIntensity.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderBackSpecularIntensity.isEnabled = enabled && adsorptionSurfaceOn
          if let specularIntensity = self.renderAdsorptionSurfaceBackSideSpecularIntensity
          {
            sliderBackSpecularIntensity.minValue = 0.0
            sliderBackSpecularIntensity.maxValue = 1.0
            sliderBackSpecularIntensity.doubleValue = specularIntensity
          }
        }
      }
      if let specularBackSideColor: NSColorWell = view.viewWithTag(12) as? NSColorWell
      {
        specularBackSideColor.isEnabled = false
        specularBackSideColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          specularBackSideColor.isEnabled = enabled && adsorptionSurfaceOn
          if let color = self.renderAdsorptionSurfaceBackSideSpecularColor
          {
            specularBackSideColor.color = color
          }
        }
      }
      
      // Shininess
      if let textFieldBackShininess: NSTextField = view.viewWithTag(13) as? NSTextField
      {
        textFieldBackShininess.isEditable = false
        textFieldBackShininess.stringValue = ""
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          textFieldBackShininess.isEditable = enabled && adsorptionSurfaceOn
          if let shininess = self.renderAdsorptionSurfaceBackSideShininess
          {
            textFieldBackShininess.doubleValue = shininess
          }
          else
          {
            textFieldBackShininess.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let sliderBackShininess: NSSlider = view.viewWithTag(14) as? NSSlider
      {
        sliderBackShininess.isEnabled = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is IsosurfaceViewer}).isEmpty
        {
          sliderBackShininess.isEnabled = enabled && adsorptionSurfaceOn
          if let shininess = self.renderAdsorptionSurfaceBackSideShininess
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
      if let popUpbuttonAnnotationType: iRASPAPopUpButton = view.viewWithTag(1) as? iRASPAPopUpButton
      {
        popUpbuttonAnnotationType.isEditable = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AnnotationEditor}).isEmpty
        {
          popUpbuttonAnnotationType.isEditable = enabled
          if let rawValue: Int = self.renderTextType?.rawValue
          {
            popUpbuttonAnnotationType.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            
            popUpbuttonAnnotationType.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonAnnotationType.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
      }
      
      if let textColor: NSColorWell = view.viewWithTag(2) as? NSColorWell
      {
        textColor.isEnabled = false
        textColor.color = NSColor.lightGray
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AnnotationEditor}).isEmpty
        {
          textColor.isEnabled = enabled
          if let renderAtomAmbientColor: NSColor = self.renderTextColor
          {
            textColor.color = renderAtomAmbientColor
          }
          else
          {
            textColor.color = NSColor.lightGray
          }
        }
      }
      
      if let popUpbuttonFontFamily: iRASPAPopUpButton = view.viewWithTag(3) as? iRASPAPopUpButton,
        let popUpbuttonFontFamilyMembers: iRASPAPopUpButton = view.viewWithTag(4) as? iRASPAPopUpButton
      {
        popUpbuttonFontFamily.isEditable = false
        popUpbuttonFontFamilyMembers.isEditable = false
        if let proxyProject = proxyProject, proxyProject.isEditable,
           !iRASPAObjects.filter({$0.object is AnnotationEditor}).isEmpty
        {
          popUpbuttonFontFamily.isEditable = enabled
          popUpbuttonFontFamilyMembers.isEditable = enabled
          
          popUpbuttonFontFamily.removeAllItems()
          let fontFamilies = NSFontManager.shared.availableFontFamilies
          popUpbuttonFontFamily.addItems(withTitles: fontFamilies)
          
          popUpbuttonFontFamilyMembers.removeAllItems()
          
          if let fontFamilyName: String = self.renderTextFontFamily
          {
            popUpbuttonFontFamily.selectItem(withTitle: fontFamilyName)
            
            if let availableMembers: [[Any]] = NSFontManager.shared.availableMembers(ofFontFamily: fontFamilyName)
            {
              let members = availableMembers.compactMap{$0[1] as? String}
              popUpbuttonFontFamilyMembers.addItems(withTitles: members)
              
              if let fontName: String = self.renderTextFont,
                 let font: NSFont = NSFont(name: fontName, size: 32),
                 let memberName: String = NSFontManager.shared.memberName(of: font)
              {
                popUpbuttonFontFamilyMembers.selectItem(withTitle: memberName)
              }
              else
              {
                popUpbuttonFontFamilyMembers.setTitle(NSLocalizedString("Multiple Values", comment: ""))
              }
            }
          }
          else
          {
            popUpbuttonFontFamily.setTitle(NSLocalizedString("Multiple Values", comment: ""))
            popUpbuttonFontFamilyMembers.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
        
        if let popUpbuttonAnnotationAlignment: iRASPAPopUpButton = view.viewWithTag(5) as? iRASPAPopUpButton
        {
          popUpbuttonAnnotationAlignment.isEditable = false
          if let proxyProject = proxyProject, proxyProject.isEditable,
             !iRASPAObjects.filter({$0.object is AnnotationEditor}).isEmpty
          {
            popUpbuttonAnnotationAlignment.isEditable = enabled
            if let rawValue: Int = self.renderTextAlignment?.rawValue
            {
              popUpbuttonAnnotationAlignment.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
              
              popUpbuttonAnnotationAlignment.selectItem(at: rawValue)
            }
            else
            {
              popUpbuttonAnnotationAlignment.setTitle(NSLocalizedString("Multiple Values", comment: ""))
            }
          }
        }
        
        if let popUpbuttonAnnotationStyle: iRASPAPopUpButton = view.viewWithTag(6) as? iRASPAPopUpButton
        {
          popUpbuttonAnnotationStyle.isEditable = false
          if let proxyProject = proxyProject, proxyProject.isEditable,
             !iRASPAObjects.filter({$0.object is AnnotationEditor}).isEmpty
          {
            popUpbuttonAnnotationStyle.isEditable = enabled
            if let rawValue: Int = self.renderTextStyle?.rawValue
            {
              popUpbuttonAnnotationStyle.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
              
              popUpbuttonAnnotationStyle.selectItem(at: rawValue)
            }
            else
            {
              popUpbuttonAnnotationStyle.setTitle(NSLocalizedString("Multiple Values", comment: ""))
            }
          }
        }
        
        
        // Scaling
        if let textFieldScaling: NSTextField = view.viewWithTag(7) as? NSTextField
        {
          textFieldScaling.isEditable = false
          textFieldScaling.stringValue = ""
          if let proxyProject = proxyProject, proxyProject.isEditable,
             !iRASPAObjects.filter({$0.object is AnnotationEditor}).isEmpty
          {
            textFieldScaling.isEditable = enabled
            if let renderTextScaling: Double = self.renderTextScaling
            {
              textFieldScaling.doubleValue = renderTextScaling
            }
            else
            {
              textFieldScaling.stringValue = NSLocalizedString("Multiple Values", comment: "")
            }
          }
        }
        if let sliderScaling: NSSlider = view.viewWithTag(8) as? NSSlider
        {
          sliderScaling.isEnabled = false
          sliderScaling.minValue = 0.0
          sliderScaling.maxValue = 3.0
          if let proxyProject = proxyProject, proxyProject.isEditable,
             !iRASPAObjects.filter({$0.object is AnnotationEditor}).isEmpty
          {
            sliderScaling.isEnabled = enabled
            if let renderTextScaling: Double = self.renderTextScaling
            {
              sliderScaling.doubleValue = renderTextScaling
            }
          }
        }
        
        if let textFieldAnnotionTextDisplacementX: NSTextField = view.viewWithTag(10) as? NSTextField
        {
          textFieldAnnotionTextDisplacementX.isEditable = false
          textFieldAnnotionTextDisplacementX.stringValue = ""
          if let proxyProject = proxyProject, proxyProject.isEditable,
             !iRASPAObjects.filter({$0.object is AnnotationEditor}).isEmpty
          {
            textFieldAnnotionTextDisplacementX.isEditable = enabled
            if let renderTextOffsetX: Double = self.renderTextOffsetX
            {
              textFieldAnnotionTextDisplacementX.doubleValue =  renderTextOffsetX
            }
            else
            {
              textFieldAnnotionTextDisplacementX.stringValue = NSLocalizedString("Mult. Val.", comment: "")
            }
          }
        }
        
        if let textFieldAnnotionTextDisplacementY: NSTextField = view.viewWithTag(11) as? NSTextField
        {
          textFieldAnnotionTextDisplacementY.isEditable = false
          textFieldAnnotionTextDisplacementY.stringValue = ""
          if let proxyProject = proxyProject, proxyProject.isEditable,
             !iRASPAObjects.filter({$0.object is AnnotationEditor}).isEmpty
          {
            textFieldAnnotionTextDisplacementY.isEditable = enabled
            if let renderTextOffsetY: Double = self.renderTextOffsetY
            {
              textFieldAnnotionTextDisplacementY.doubleValue =  renderTextOffsetY
            }
            else
            {
              textFieldAnnotionTextDisplacementY.stringValue = NSLocalizedString("Mult. Val.", comment: "")
            }
          }
        }
        
        if let textFieldAnnotionTextDisplacementZ: NSTextField = view.viewWithTag(12) as? NSTextField
        {
          textFieldAnnotionTextDisplacementZ.isEditable = false
          textFieldAnnotionTextDisplacementZ.stringValue = ""
          if let proxyProject = proxyProject, proxyProject.isEditable,
             !iRASPAObjects.filter({$0.object is AnnotationEditor}).isEmpty
          {
            textFieldAnnotionTextDisplacementZ.isEditable = enabled
            if let renderTextOffsetZ: Double = self.renderTextOffsetZ
            {
              textFieldAnnotionTextDisplacementZ.doubleValue =  renderTextOffsetZ
            }
            else
            {
              textFieldAnnotionTextDisplacementZ.stringValue = NSLocalizedString("Mult. Val.", comment: "")
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
      let renderOrientation: simd_quatd = self.renderPrimitiveOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.x = sender.doubleValue * Double.pi/180.0
      self.renderPrimitiveOrientation = simd_quatd(EulerAngles: angles)
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
      let renderOrientation: simd_quatd = self.renderPrimitiveOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.y = sender.doubleValue * Double.pi/180.0
      self.renderPrimitiveOrientation = simd_quatd(EulerAngles: angles)
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
      let renderOrientation: simd_quatd = self.renderPrimitiveOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.z = sender.doubleValue * Double.pi/180.0
      self.renderPrimitiveOrientation = simd_quatd(EulerAngles: angles)
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
      let renderRotationDelta = self.renderPrimitiveRotationDelta,
      let renderOrientation: simd_quatd = self.renderPrimitiveOrientation
    {
      let dq: simd_quatd = simd_quatd(yaw: renderRotationDelta)
      
      self.renderPrimitiveOrientation = renderOrientation * dq
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
      let renderRotationDelta = self.renderPrimitiveRotationDelta,
      let renderOrientation: simd_quatd = self.renderPrimitiveOrientation
    {
      let dq: simd_quatd = simd_quatd(yaw: -renderRotationDelta)
      
      self.renderPrimitiveOrientation = renderOrientation * dq
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
      let renderRotationDelta = self.renderPrimitiveRotationDelta,
      let renderOrientation: simd_quatd = self.renderPrimitiveOrientation
    {
      let dq: simd_quatd = simd_quatd(pitch: renderRotationDelta)
      
      self.renderPrimitiveOrientation = renderOrientation * dq
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
      let renderRotationDelta = self.renderPrimitiveRotationDelta,
      let renderOrientation: simd_quatd = self.renderPrimitiveOrientation
    {
      let dq: simd_quatd = simd_quatd(pitch: -renderRotationDelta)
      
      self.renderPrimitiveOrientation = renderOrientation * dq
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
      let renderRotationDelta = self.renderPrimitiveRotationDelta,
      let renderOrientation: simd_quatd = self.renderPrimitiveOrientation
    {
      let dq: simd_quatd = simd_quatd(roll: renderRotationDelta)
      
      self.renderPrimitiveOrientation = renderOrientation * dq
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
      let renderRotationDelta = self.renderPrimitiveRotationDelta,
      let renderOrientation: simd_quatd = self.renderPrimitiveOrientation
    {
      let dq: simd_quatd = simd_quatd(roll: -renderRotationDelta)
      
      self.renderPrimitiveOrientation = renderOrientation * dq
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
      let renderOrientation = self.renderPrimitiveOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.x = sender.doubleValue * Double.pi/180.0
      self.renderPrimitiveOrientation = simd_quatd(EulerAngles: angles)
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
      let renderOrientation = self.renderPrimitiveOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.z = sender.doubleValue * Double.pi/180.0
      self.renderPrimitiveOrientation = simd_quatd(EulerAngles: angles)
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
      let renderOrientation = self.renderPrimitiveOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.y = sender.doubleValue * Double.pi/180.0
      self.renderPrimitiveOrientation = simd_quatd(EulerAngles: angles)
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
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      self.renderPrimitiveRotationDelta = sender.doubleValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.primitiveOrientationPropertiesCell])
    }
  }
  
  
  @IBAction func changeTransformationAXTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.renderPrimitiveTransformationMatrixAX = sender.doubleValue
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
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.renderPrimitiveTransformationMatrixAY = sender.doubleValue
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
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.renderPrimitiveTransformationMatrixAZ = sender.doubleValue
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
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.renderPrimitiveTransformationMatrixBX = sender.doubleValue
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
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.renderPrimitiveTransformationMatrixBY = sender.doubleValue
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
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.renderPrimitiveTransformationMatrixBZ = sender.doubleValue
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
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.renderPrimitiveTransformationMatrixCX = sender.doubleValue
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
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.renderPrimitiveTransformationMatrixCY = sender.doubleValue
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
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.renderPrimitiveTransformationMatrixCZ = sender.doubleValue
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveOpacity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOpacityPropertiesCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveOpacity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveOpacityPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveNumberOfSidesSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveNumberOfSides = max(2,sender.integerValue)
      
      self.updateOutlineView(identifiers: [self.primitiveOpacityPropertiesCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveNumberOfSides = max(2,sender.integerValue)
      
      self.updateOutlineView(identifiers: [self.primitiveOpacityPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadRenderData()

      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func togglePrimitiveIsCapped(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      sender.allowsMixedState = false
      self.renderPrimitiveIsCapped = (sender.state == NSControl.StateValue.on)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func togglePrimitiveIsFractional(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      sender.allowsMixedState = false
      self.renderPrimitiveIsFractional = (sender.state == NSControl.StateValue.on)
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      sender.allowsMixedState = false
      self.renderPrimitiveFrontSideHDR = (sender.state == NSControl.StateValue.on)
      
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
       let selectionStyle = RKSelectionStyle(rawValue: sender.indexOfSelectedItem)
    {
      self.renderPrimitiveSelectionStyle = selectionStyle
      
      self.updateOutlineView(identifiers: [self.primitiveSelectionPropertiesCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveSelectionFrequency = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveSelectionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveSelectionDensityTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveSelectionDensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveSelectionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveSelectionIntensityField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveSelectionIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveSelectionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveSelectionIntensity(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveSelectionIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveSelectionPropertiesCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveSelectionScaling = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveSelectionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveSelectionScalingSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveSelectionScaling = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveSelectionPropertiesCell])
      
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
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
     {
       self.renderPrimitiveHue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.primitiveHSVPropertiesCell])
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Hue slider
   @IBAction func changePrimitiveHueSlider(_ sender: NSSlider)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
     {
       self.renderPrimitiveHue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.primitiveHSVPropertiesCell])
       
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
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
     {
       self.renderPrimitiveSaturation = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.primitiveHSVPropertiesCell])
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Saturation slider
   @IBAction func changePrimitiveSaturationSlider(_ sender: NSSlider)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
     {
       self.renderPrimitiveSaturation = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.primitiveHSVPropertiesCell])
       
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
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
     {
       self.renderPrimitiveValue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.primitiveHSVPropertiesCell])
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Value slider
   @IBAction func changePrimitiveValueSlider(_ sender: NSSlider)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
     {
       self.renderPrimitiveValue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.primitiveHSVPropertiesCell])
       
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveFrontSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveFrontPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Exposure slider
  @IBAction func changePrimitiveFrontSideExposureSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveFrontSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveFrontPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveFrontSideAmbientTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveFrontSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveFrontPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveFrontSideAmbientIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveFrontSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveFrontPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveFrontSideAmbientColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveFrontSideAmbientColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveFrontSideDiffuseTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveFrontSideDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveFrontPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveFrontSideDiffuseIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveFrontSideDiffuseIntensity = sender.doubleValue
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveFrontSideDiffuseColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveFrontSideSpecularTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveFrontSideSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveFrontPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveFrontSideSpecularIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveFrontSideSpecularIntensity = sender.doubleValue
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveFrontSideSpecularColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveFrontSideShininessTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveFrontSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveFrontPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveFrontSideShininessSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveFrontSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveFrontPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func togglePrimitiveBackSideHDR(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      sender.allowsMixedState = false
      self.renderPrimitiveBackSideHDR = (sender.state == NSControl.StateValue.on)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveBackSideHDRExporeTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveBackSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveBackPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Exposure slider
  @IBAction func changePrimitiveBackSideExposureSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveBackSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveBackPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideAmbientTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveBackSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveBackPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideAmbientIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveBackSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveBackPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideAmbientColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveBackSideAmbientColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveBackSideDiffuseTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveBackSideDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveBackPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideDiffuseIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveBackSideDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveBackPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideDiffuseColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveBackSideDiffuseColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveBackSideSpecularTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveBackSideSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveBackPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideSpecularIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveBackSideSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveBackPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideSpecularColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveBackSideSpecularColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changePrimitiveBackSideShininessTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveBackSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveBackPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changePrimitiveBackSideShininessSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderPrimitiveBackSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.primitiveBackPropertiesCell])
      
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
       let representationType = Structure.RepresentationType(rawValue: sender.indexOfSelectedItem)
    {
      self.setRepresentationType(type: representationType)
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: iRASPAObjects.flatMap{$0.selectedRenderFrames})
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: iRASPAObjects.flatMap{$0.selectedRenderFrames})
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
       let representationStyle = Crystal.RepresentationStyle(rawValue: sender.indexOfSelectedItem), representationStyle.rawValue >= 0
    {
      self.setRepresentationStyle(style: representationStyle, colorSets: document.colorSets)
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell, self.atomsSelectionCell, self.atomsScalingCell, self.atomsHDRCell, self.atomsLightingCell, self.bondsScalingCell, self.bondsSelectionCell, self.bondsHDRCell, self.bondsLightingCell])
      
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
       let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.setRepresentationColorScheme(scheme: sender.titleOfSelectedItem ?? SKColorSets.ColorScheme.jmol.rawValue, colorSets: document.colorSets)
      
      self.recheckRepresentationStyle()
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
       let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.setRepresentationForceField(forceField: sender.titleOfSelectedItem ?? "Default", forceFieldSets: document.forceFieldSets)
      
      self.recheckRepresentationStyle()
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
       let representationColorOrder = SKColorSets.ColorOrder(rawValue: sender.indexOfSelectedItem)
    {
      self.setRepresentationColorOrder(order: representationColorOrder, colorSets: document.colorSets)
      
      self.recheckRepresentationStyle()
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
       let representationForceFieldOrder = SKForceFieldSets.ForceFieldOrder(rawValue: sender.indexOfSelectedItem)
    {
      self.setRepresentationForceFieldOrder(order:  representationForceFieldOrder, forceFieldSets: document.forceFieldSets)
      
      self.recheckRepresentationStyle()
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
       let selectionStyle = RKSelectionStyle(rawValue: sender.indexOfSelectedItem)
    {
      self.renderAtomSelectionStyle = selectionStyle
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsSelectionCell, self.atomsRepresentationStyleCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomSelectionFrequency = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.bondsSelectionCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomSelectionDensityTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomSelectionDensity = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsSelectionCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomSelectionIntensityLevelField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomSelectionIntensity = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsSelectionCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomSelectionIntensityLevel(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomSelectionIntensity = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsSelectionCell, self.atomsRepresentationStyleCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomSelectionScaling = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsSelectionCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomSelectionScalingSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomSelectionScaling = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsSelectionCell, self.atomsRepresentationStyleCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      sender.allowsMixedState = false
      self.renderAtomHDR = (sender.state == NSControl.StateValue.on)
      
      self.recheckRepresentationStyle()
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomHDRExposure = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsHDRCell, self.atomsRepresentationStyleCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomHDRExposure = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsHDRCell, self.atomsRepresentationStyleCell])
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomHue = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsHDRCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Hue slider
  @IBAction func changeHueSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomHue = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsHDRCell, self.atomsRepresentationStyleCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomSaturation = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsHDRCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Saturation slider
  @IBAction func changeSaturationSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomSaturation = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsHDRCell, self.atomsRepresentationStyleCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomValue = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsHDRCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Value slider
  @IBAction func changeValueSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomValue = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsHDRCell, self.atomsRepresentationStyleCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomScaleFactor = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsScalingCell, self.atomsRepresentationStyleCell])
      
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
         
          self.renderAtomScaleFactorCompleted = sender.doubleValue
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
          
          if let renderAtomAmbientOcclusion = self.renderAtomAmbientOcclusion , renderAtomAmbientOcclusion == true
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomScaleFactorCompleted = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsScalingCell, self.atomsRepresentationStyleCell])
      
      if let renderAtomAmbientOcclusion: Bool = self.renderAtomAmbientOcclusion , renderAtomAmbientOcclusion == true
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      sender.allowsMixedState = false
      self.renderAtomAmbientOcclusion = (sender.state == NSControl.StateValue.on)
      
      self.recheckRepresentationStyle()
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomAmbientIntensity = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAmbientIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomAmbientIntensity = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomAmbientColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomAmbientColor = sender.color
      
      self.updateOutlineView(identifiers: [self.atomsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeDiffuseTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomDiffuseIntensity = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeDiffuseIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomDiffuseIntensity = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomDiffuseColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomDiffuseColor = sender.color
      
      self.updateOutlineView(identifiers: [self.atomsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeSpecularTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomSpecularIntensity = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeSpecularIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.atomsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAtomSpecularColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomSpecularColor = sender.color
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeShininessTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomShininess = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeShininessSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAtomShininess = sender.doubleValue
      
      self.recheckRepresentationStyle()
      self.updateOutlineView(identifiers: [self.atomsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  
  
  @IBAction func toggleAtomBonds(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      sender.allowsMixedState = false
      self.renderDrawAtoms=(sender.state == NSControl.StateValue.on)
      
      self.recheckRepresentationStyle()
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderDrawBonds = (sender.state == NSControl.StateValue.on)
      
      self.recheckRepresentationStyleBond()
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
       let renderBondColorMode = RKBondColorMode(rawValue: sender.indexOfSelectedItem)
    {
      self.renderBondColorMode = renderBondColorMode
      
      self.recheckRepresentationStyleBond()
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondScaleFactor = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsScalingCell, self.atomsRepresentationStyleCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondScaleFactor = sender.doubleValue
      
      self.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.bondsScalingCell, self.atomsRepresentationStyleCell])
      
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
       let selectionStyle = RKSelectionStyle(rawValue: sender.indexOfSelectedItem)
    {
      self.renderBondSelectionStyle = selectionStyle
      
      self.updateOutlineView(identifiers: [self.atomsRepresentationStyleCell, self.bondsSelectionCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondSelectionFrequency = sender.doubleValue
      
      self.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.bondsSelectionCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondSelectionDensityTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondSelectionDensity = sender.doubleValue
      
      self.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.bondsSelectionCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondSelectionIntensityField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondSelectionIntensity = sender.doubleValue
      
      self.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.bondsSelectionCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondSelectionIntensity(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondSelectionIntensity = sender.doubleValue
      
      self.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.bondsSelectionCell, self.atomsRepresentationStyleCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondSelectionScaling = sender.doubleValue
      
      self.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.bondsSelectionCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondSelectionScalingSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondSelectionScaling = sender.doubleValue
      
      self.recheckRepresentationStyleBond()
      self.updateOutlineView(identifiers: [self.bondsSelectionCell, self.atomsRepresentationStyleCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondHDR = (sender.state == NSControl.StateValue.on)
      
      self.recheckRepresentationStyleBond()
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsHDRCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondHue = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsHDRCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Hue slider
  @IBAction func changeBondHueSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondHue = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsHDRCell, self.atomsRepresentationStyleCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondSaturation = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsHDRCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Saturation slider
  @IBAction func changeBondSaturationSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondSaturation = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsHDRCell, self.atomsRepresentationStyleCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondValue = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsHDRCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Value slider
  @IBAction func changeBondValueSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondValue = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsHDRCell, self.atomsRepresentationStyleCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeBondAmbientIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondAmbientColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondAmbientColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeBondDiffuseTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondDiffuseIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondDiffuseColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondDiffuseColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondSpecularTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeBondSpecularIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondSpecularColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondSpecularColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondShininessTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsLightingCell, self.atomsRepresentationStyleCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBondShininessSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderBondShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.bondsLightingCell, self.atomsRepresentationStyleCell])
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderDrawUnitCell = (sender.state == NSControl.StateValue.on)
      
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
      {
        project.allObjects.forEach{$0.reComputeBoundingBox()}
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderUnitCellScaleFactor = sender.doubleValue
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderUnitCellScaleFactor = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.unitCellScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeUnitCellDiffuseTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderUnitCellDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.unitCellScalingCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeUnitCellDiffuseIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderUnitCellDiffuseIntensity = sender.doubleValue
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderUnitCellDiffuseColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  // MARK: local axes actions
  // =====================================================================
  
  @IBAction func changeLocalAxesPosition(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       let position: RKLocalAxes.Position = RKLocalAxes.Position(rawValue: sender.indexOfSelectedItem)
    {
      self.renderLocalAxesPosition = position
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeLocalAxesStyle(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       let presentationStyle: RKLocalAxes.Style = RKLocalAxes.Style(rawValue: sender.indexOfSelectedItem)
    {
      self.renderLocalAxesStyle = presentationStyle
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadLocalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeLocalAxesScalingStyle(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       let scalingsType: RKLocalAxes.ScalingType = RKLocalAxes.ScalingType(rawValue: sender.indexOfSelectedItem)
    {
      self.renderLocalAxesScalingType = scalingsType
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadLocalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeLocalAxisLengthTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderLocalAxesLength  = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.localAxesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadLocalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeLocalAxesLengthSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderLocalAxesLength = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.localAxesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadLocalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeLocalAxisWidthTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderLocalAxesWidth  = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.localAxesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadLocalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeLocalAxesWidthSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderLocalAxesWidth = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.localAxesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadLocalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeLocalAxisOffsetXTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderLocalAxesOffsetX  = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.localAxesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeLocalAxisOffsetYTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderLocalAxesOffsetY  = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.localAxesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeLocalAxisOffsetZTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderLocalAxesOffsetZ  = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.localAxesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperLocalAxisOffsetX(_ sender: NSStepper)
  {
    let deltaValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let renderTextOffsetX: Double = self.renderLocalAxesOffsetX
    {
      let newValue: Double = renderTextOffsetX + deltaValue * 0.5
      self.renderLocalAxesOffsetX = newValue
      
      self.updateOutlineView(identifiers: [self.localAxesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
    
    sender.doubleValue = 0
  }
  
  @IBAction func updateStepperLocalAxisOffsetY(_ sender: NSStepper)
  {
    let deltaValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let renderTextOffsetY: Double = self.renderLocalAxesOffsetY
    {
      let newValue: Double = renderTextOffsetY + deltaValue * 0.5
      self.renderLocalAxesOffsetY = newValue
      
      self.updateOutlineView(identifiers: [self.localAxesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
    
    sender.doubleValue = 0
  }
  
  @IBAction func updateStepperLocalAxisOffsetZ(_ sender: NSStepper)
  {
    let deltaValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let renderTextOffsetZ: Double = self.renderLocalAxesOffsetZ
    {
      let newValue: Double = renderTextOffsetZ + deltaValue * 0.5
      self.renderLocalAxesOffsetZ = newValue
      
      self.updateOutlineView(identifiers: [self.localAxesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
    
    sender.doubleValue = 0
  }
  
  // MARK: Adsorption surface
  // =====================================================================
  
  @IBAction func toggleAdsorptionSurface(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceOn = (sender.state == NSControl.StateValue.on)
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurface(completionHandler: surfaceUpdateBlock)
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell, self.adsorptionHSVCell, self.adsorptionFrontSurfaceCell, self.adsorptionBackSurfaceCell])
    }
  }
  
  @IBAction func changeAdsorptionRenderingType(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       let adsorptionSurfaceRenderingMethod = RKEnergySurfaceType(rawValue: sender.indexOfSelectedItem)
    {
      self.renderAdsorptionRenderingMethod = adsorptionSurfaceRenderingMethod
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: iRASPAObjects.flatMap{$0.selectedRenderFrames})
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurface(completionHandler: surfaceUpdateBlock)
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceProbeMolecule(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       let adsorptionSurfaceProbeMolecule = Structure.ProbeMolecule(rawValue: sender.indexOfSelectedItem)
    {
      self.renderAdsorptionSurfaceProbeMolecule = adsorptionSurfaceProbeMolecule
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: iRASPAObjects.flatMap{$0.selectedRenderFrames})
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurface(completionHandler: surfaceUpdateBlock)
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionTransferFunction(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
       let adsorptionVolumeTransferFunction = RKPredefinedVolumeRenderingTransferFunction(rawValue: sender.indexOfSelectedItem)
    {
      self.renderAdsorptionVolumeTransferFunction = adsorptionVolumeTransferFunction
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionVolumeStepLengthTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionVolumeStepLength = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurface(completionHandler: surfaceUpdateBlock)
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceIsovalueSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceIsovalue = sender.doubleValue
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceIsovalue = sender.doubleValue
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceOpacity = sender.doubleValue
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceOpacity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionTransparencyThresholdSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionTransparencyThreshold = sender.doubleValue
      
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
  
  @IBAction func changeAdsorptionTransparencyThresholdTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionTransparencyThreshold = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceSize(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderEncompassingPowerOfTwoCubicGridSize = sender.indexOfSelectedItem
      
      self.updateOutlineView(identifiers: [self.adsorptionPropertiesCell])
      
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
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
     {
       self.renderAdsorptionSurfaceHue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.adsorptionHSVCell])
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Hue slider
   @IBAction func changeAdsorptionSurfaceHueSlider(_ sender: NSSlider)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
     {
       self.renderAdsorptionSurfaceHue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.adsorptionHSVCell])
       
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
       self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Saturation textfield
   @IBAction func changeAdsorptionSurfaceSaturationTextField(_ sender: NSTextField)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
     {
       self.renderAdsorptionSurfaceSaturation = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.adsorptionHSVCell])
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Saturation slider
   @IBAction func changeAdsorptionSurfaceSaturationSlider(_ sender: NSSlider)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
     {
       self.renderAdsorptionSurfaceSaturation = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.adsorptionHSVCell])
       
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
       self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Value textfield
   @IBAction func changeAdsorptionSurfaceValueTextField(_ sender: NSTextField)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
     {
       self.renderAdsorptionSurfaceValue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.adsorptionHSVCell])
       
       self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
   // Value slider
   @IBAction func changeAdsorptionSurfaceValueSlider(_ sender: NSSlider)
   {
     if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
     {
       self.renderAdsorptionSurfaceValue = sender.doubleValue
       
       self.updateOutlineView(identifiers: [self.adsorptionHSVCell])
       
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
       self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
       self.windowController?.detailTabViewController?.renderViewController?.redraw()
       
       self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
       self.windowController?.document?.updateChangeCount(.changeDone)
       self.proxyProject?.representedObject.isEdited = true
     }
   }
   
  
  // High dynamic range
  @IBAction func toggleAdsorptionSurfaceFrontSideHDR(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      sender.allowsMixedState = false
      self.renderAdsorptionSurfaceFrontSideHDR = (sender.state == NSControl.StateValue.on)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceFrontSideHDRExporeTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceFrontSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionHSVCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Exposure slider
  @IBAction func changeAdsorptionSurfaceFrontSideExposureSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceFrontSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionFrontSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceFrontSideAmbientTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceFrontSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionFrontSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceFrontSideAmbientIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceFrontSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionFrontSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceFrontSideAmbientColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceFrontSideAmbientColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceFrontSideDiffuseTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceFrontSideDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionFrontSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceFrontSideDiffuseIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceFrontSideDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionFrontSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceFrontSideDiffuseColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceFrontSideDiffuseColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceFrontSideSpecularTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceFrontSideSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionFrontSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceFrontSideSpecularIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceFrontSideSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionFrontSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  
  @IBAction func changeAdsorptionSurfaceFrontSideSpecularColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceFrontSideSpecularColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceFrontSideShininessTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceFrontSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionFrontSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceFrontSideShininessSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceFrontSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionFrontSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func toggleAdsorptionSurfaceBackSideHDR(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      sender.allowsMixedState = false
      self.renderAdsorptionSurfaceBackSideHDR = (sender.state == NSControl.StateValue.on)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceBackSideHDRExporeTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceBackSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionBackSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // Exposure slider
  @IBAction func changeAdsorptionSurfaceBackSideExposureSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceBackSideHDRExposure = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionBackSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideAmbientTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceBackSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionBackSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideAmbientIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceBackSideAmbientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionBackSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideAmbientColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceBackSideAmbientColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceBackSideDiffuseTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceBackSideDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionBackSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideDiffuseIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceBackSideDiffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionBackSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideDiffuseColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceBackSideDiffuseColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceBackSideSpecularTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceBackSideSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionBackSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideSpecularIntensitySlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceBackSideSpecularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionBackSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideSpecularColor(_ sender: NSColorWell)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceBackSideSpecularColor = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAdsorptionSurfaceBackSideShininessTextField(_ sender: NSTextField)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceBackSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionBackSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAdsorptionSurfaceBackSideShininessSlider(_ sender: NSSlider)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderAdsorptionSurfaceBackSideShininess = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.adsorptionBackSurfaceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.appearanceOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // MARK: Annotation
  // =====================================================================
  
  @IBAction func changeAtomTextAnnotationStyle(_ sender: iRASPAPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      let renderTextType = RKTextType(rawValue: sender.indexOfSelectedItem)
    {
      self.renderTextType = renderTextType
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderTextColor = sender.color
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderTextFont = sender.titleOfSelectedItem
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      if let fontFamilyName = self.renderTextFontFamily,
         let availableMembers: [[Any]] = NSFontManager.shared.availableMembers(ofFontFamily: fontFamilyName)
      {
        let fontNames = availableMembers.compactMap{$0[0] as? String}
        self.renderTextFont = fontNames[sender.indexOfSelectedItem]
        
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
      let renderTextAlignment = RKTextAlignment(rawValue: sender.indexOfSelectedItem)
    {
      self.renderTextAlignment = renderTextAlignment
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderTextScaling = sender.doubleValue
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderTextScaling = sender.doubleValue
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderTextOffsetX = sender.doubleValue
      
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
      let renderTextOffsetX: Double = self.renderTextOffsetX
    {
      let newValue: Double = renderTextOffsetX + deltaValue * 0.1
      self.renderTextOffsetX = newValue
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderTextOffsetY = sender.doubleValue
      
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
      let renderTextOffsetY: Double = self.renderTextOffsetY
    {
      let newValue: Double = renderTextOffsetY + deltaValue * 0.1
      self.renderTextOffsetY = newValue
      
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      self.renderTextOffsetZ = sender.doubleValue
      
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
       let renderTextOffsetZ: Double = self.renderTextOffsetZ
    {
      let newValue: Double = renderTextOffsetZ + deltaValue * 0.1
      self.renderTextOffsetZ = newValue
      
      self.updateOutlineView(identifiers: [self.annotationVisualAppearanceCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
    
    sender.doubleValue = 0
  }
  
 
  
  // MARK: Primitive Visual Appearance
  //===================================================================================================================================================
  
  public var renderPrimitiveOrientation: simd_quatd?
  {
    get
    {
      let origin: [simd_quatd] = self.iRASPAObjects.compactMap{($0.object as? PrimitiveEditor)?.primitiveOrientation}
      let q: simd_quatd = origin.reduce(simd_quatd()){return simd_add($0, $1)}
      let averaged_vector: simd_quatd = simd_quatd(ix: q.vector.x / Double(origin.count), iy: q.vector.y / Double(origin.count), iz: q.vector.z / Double(origin.count), r: q.vector.w / Double(origin.count))
      return origin.isEmpty ? nil : averaged_vector
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? PrimitiveEditor)?.primitiveOrientation = newValue ?? simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveRotationDelta: Double?
  {
    get
    {
      let origin: [Double] = self.iRASPAObjects.compactMap{($0.object as? PrimitiveEditor)?.primitiveRotationDelta}
      return origin.isEmpty ? nil : origin.reduce(0.0){return $0 + $1} / Double(origin.count)
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? PrimitiveEditor)?.primitiveRotationDelta = newValue ?? 5.0}
    }
  }
  
  public var renderPrimitiveEulerAngleX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveOrientation.EulerAngles.x}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? PrimitiveEditor)?.primitiveOrientation.EulerAngles = SIMD3<Double>(newValue ?? 0.0,($0.object as! PrimitiveEditor).primitiveOrientation.EulerAngles.y,($0.object as! PrimitiveEditor).primitiveOrientation.EulerAngles.z)
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveEulerAngleY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveOrientation.EulerAngles.y}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? PrimitiveEditor)?.primitiveOrientation.EulerAngles = SIMD3<Double>(($0.object as! PrimitiveEditor).primitiveOrientation.EulerAngles.x, newValue ?? 0.0,($0.object as! PrimitiveEditor).primitiveOrientation.EulerAngles.z)
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveEulerAngleZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveOrientation.EulerAngles.z}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? PrimitiveEditor)?.primitiveOrientation.EulerAngles = SIMD3<Double>(($0.object as! PrimitiveEditor).primitiveOrientation.EulerAngles.x, ($0.object as! PrimitiveEditor).primitiveOrientation.EulerAngles.y, newValue ?? 0.0)
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  
  public var renderPrimitiveTransformationMatrix: double3x3?
  {
    get
    {
      let set: Set<double3x3> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix = newValue ?? double3x3(1.0)
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixAX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[0].x}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[0].x = newValue ?? 1.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixAY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[0].y}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[0].y = newValue ?? 1.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixAZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[0].z}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[0].z = newValue ?? 1.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixBX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[1].x}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[1].x = newValue ?? 1.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixBY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[1].y}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[1].y = newValue ?? 1.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixBZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[1].z}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[1].z = newValue ?? 1.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixCX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[2].x}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[2].x = newValue ?? 1.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixCY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[2].y}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[2].y = newValue ?? 1.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixCZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[2].z}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? PrimitiveEditor)?.primitiveTransformationMatrix[2].z = newValue ?? 1.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveOpacity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveOpacity}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveOpacity = newValue ?? 1.0})
    }
  }
  
  public var renderPrimitiveNumberOfSides: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveNumberOfSides}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveNumberOfSides = newValue ?? 6})
    }
  }
  
  public var renderPrimitiveIsCapped: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveIsCapped}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveIsCapped = newValue ?? false})
    }
  }
  
  public var renderPrimitiveIsFractional: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveIsFractional}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveIsFractional = newValue ?? false})
    }
  }
  
  public var renderPrimitiveThickness: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveThickness}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveThickness = newValue ?? 0.05})
    }
  }
  
  public var renderPrimitiveSelectionStyle: RKSelectionStyle?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveSelectionStyle.rawValue}))
      return Set(set).count == 1 ? RKSelectionStyle(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveSelectionStyle = newValue ?? .glow})
    }
  }
  
  public var renderPrimitiveSelectionFrequency: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.renderPrimitiveSelectionFrequency}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.renderPrimitiveSelectionFrequency = newValue ?? 4.0})
    }
  }
  
  public var renderPrimitiveSelectionDensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.renderPrimitiveSelectionDensity}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.renderPrimitiveSelectionDensity = newValue ?? 4.0})
    }
  }
  
  public var renderPrimitiveSelectionIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveSelectionIntensity}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveSelectionIntensity = newValue ?? 1.0})
    }
  }
  
  public var renderPrimitiveSelectionScaling: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveSelectionScaling}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveSelectionScaling = newValue ?? 1.0})
    }
  }
  
  
  public var renderPrimitiveHue: Double?
   {
     get
     {
       let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveHue}))
       return Set(set).count == 1 ? set.first! : nil
     }
     set(newValue)
     {
       self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveHue = newValue ?? 1.0})
     }
   }
   
   public var renderPrimitiveSaturation: Double?
   {
     get
     {
       let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveSaturation}))
       return Set(set).count == 1 ? set.first! : nil
     }
     set(newValue)
     {
       self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveSaturation = newValue ?? 1.0})
     }
   }
   
   public var renderPrimitiveValue: Double?
   {
     get
     {
       let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveValue}))
       return Set(set).count == 1 ? set.first! : nil
     }
     set(newValue)
     {
       self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveValue = newValue ?? 1.0})
     }
   }
  
  public var renderPrimitiveFrontSideHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveFrontSideHDR}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveFrontSideHDR = newValue ?? true})
    }
  }
  
  public var renderPrimitiveFrontSideHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveFrontSideHDRExposure}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveFrontSideHDRExposure = newValue ?? 1.5})
    }
  }
  
  public var renderPrimitiveFrontSideAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveFrontSideAmbientIntensity}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveFrontSideAmbientIntensity = newValue ?? 0.2})
    }
  }
  
  
  public var renderPrimitiveFrontSideAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveFrontSideAmbientColor}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveFrontSideAmbientColor = newValue ?? NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)})
    }
  }
  
  public var renderPrimitiveFrontSideDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveFrontSideDiffuseIntensity}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveFrontSideDiffuseIntensity = newValue ?? 1.0})
    }
  }
  
  public var renderPrimitiveFrontSideDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveFrontSideDiffuseColor}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveFrontSideDiffuseColor = newValue ?? NSColor(red: 0.588235, green: 0.670588, blue: 0.729412, alpha: 1.0)})
    }
  }
  
  public var renderPrimitiveFrontSideSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveFrontSideSpecularIntensity}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveFrontSideSpecularIntensity = newValue ?? 1.0})
    }
  }
  
  public var renderPrimitiveFrontSideSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveFrontSideSpecularColor}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveFrontSideSpecularColor = newValue ?? NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)})
    }
  }
  
  public var renderPrimitiveFrontSideShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveFrontSideShininess}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveFrontSideShininess = newValue ?? 4.0})
    }
  }
  
  public var renderPrimitiveBackSideHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveBackSideHDR}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveBackSideHDR = newValue ?? true})
    }
  }
  
  public var renderPrimitiveBackSideHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveBackSideHDRExposure}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveBackSideHDRExposure = newValue ?? 1.5})
    }
  }
  
  
  public var renderPrimitiveBackSideAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveBackSideAmbientIntensity}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveBackSideAmbientIntensity = newValue ?? 0.2})
    }
  }
  
  public var renderPrimitiveBackSideAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveBackSideAmbientColor}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveBackSideAmbientColor = newValue ?? NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)})
    }
  }
  
  
  public var renderPrimitiveBackSideDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveBackSideDiffuseIntensity}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveBackSideDiffuseIntensity = newValue ?? 1.0})
    }
  }
  
  public var renderPrimitiveBackSideDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveBackSideDiffuseColor}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveBackSideDiffuseColor = newValue ?? NSColor(red: 0.588235, green: 0.670588, blue: 0.729412, alpha: 1.0)})
    }
  }
  
  public var renderPrimitiveBackSideSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveBackSideSpecularIntensity}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveBackSideSpecularIntensity = newValue ?? 1.0})
    }
  }
  
  public var renderPrimitiveBackSideSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveBackSideSpecularColor}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveBackSideSpecularColor = newValue ?? NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)})
    }
  }
  
  public var renderPrimitiveBackSideShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? PrimitiveEditor)?.primitiveBackSideShininess}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? PrimitiveEditor)?.primitiveBackSideShininess = newValue ?? 4.0})
    }
  }
  
  // MARK: Atom Visual Appearance
  //===================================================================================================================================================
  
  public func recheckRepresentationStyle()
  {
    self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.recheckRepresentationStyle()}
  }
  
  public func getRepresentationType() -> Structure.RepresentationType?
  {
    let set: Set<Int> = Set(self.iRASPAObjects.compactMap{ return ($0.object as? AtomStructureEditor)?.getRepresentationType()?.rawValue })
    return Set(set).count == 1 ? Structure.RepresentationType(rawValue: set.first!) : nil
  }
  
  public func setRepresentationType(type: Structure.RepresentationType?)
  {
    self.iRASPAObjects.forEach{
      ($0.object as? AtomStructureEditor)?.setRepresentationType(type: type)
      $0.object.reComputeBoundingBox()
    }
  }
  
  
  public func getRepresentationStyle() -> Structure.RepresentationStyle?
  {
    let set: Set<Int> = Set(self.iRASPAObjects.compactMap{ return ($0.object as? AtomStructureEditor)?.getRepresentationStyle()?.rawValue })
    return Set(set).count == 1 ? Structure.RepresentationStyle(rawValue: set.first!) : nil
  }
  
  public func setRepresentationStyle(style: Structure.RepresentationStyle?, colorSets: SKColorSets)
  {
    self.iRASPAObjects.forEach{
      ($0.object as? AtomStructureEditor)?.setRepresentationStyle(style: style, colorSets: colorSets)
      $0.object.reComputeBoundingBox()
    }
  }
  
  public func getRepresentationColorScheme() -> String?
  {
    let set: Set<String> = Set(self.iRASPAObjects.compactMap{ return ($0.object as? AtomStructureEditor)?.getRepresentationColorScheme() })
    return Set(set).count == 1 ?  set.first! : nil
  }
  
  public func setRepresentationColorScheme(scheme: String?, colorSets: SKColorSets)
  {
  self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.setRepresentationColorScheme(scheme: scheme ?? "Default", colorSets: colorSets)}
  }
  
  public func getRepresentationColorOrder() -> SKColorSets.ColorOrder?
  {
    let set: Set<Int> = Set(self.iRASPAObjects.compactMap{ return ($0.object as? AtomStructureEditor)?.getRepresentationColorOrder()?.rawValue })
    return Set(set).count == 1 ?  SKColorSets.ColorOrder(rawValue: set.first!) : nil
  }
  
  public func setRepresentationColorOrder(order: SKColorSets.ColorOrder?, colorSets: SKColorSets)
  {
    self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.setRepresentationColorOrder(order: order ?? SKColorSets.ColorOrder.elementOnly, colorSets: colorSets)}
  }
  
  public func getRepresentationForceField() -> String?
  {
    let set: Set<String> = Set(self.iRASPAObjects.compactMap{ return ($0.object as? AtomStructureEditor)?.getRepresentationForceField() })
      return Set(set).count == 1 ?  set.first! : nil
  }
  
  public func setRepresentationForceField(forceField: String?, forceFieldSets: SKForceFieldSets)
  {
    self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.setRepresentationForceField(forceField: forceField ?? "Default", forceFieldSets: forceFieldSets)}
  }
  
  public func getRepresentationForceFieldOrder() -> SKForceFieldSets.ForceFieldOrder?
  {
    let set: Set<Int> = Set(self.iRASPAObjects.compactMap{ return ($0.object as? AtomStructureEditor)?.getRepresentationForceFieldOrder()?.rawValue })
    return Set(set).count == 1 ?  SKForceFieldSets.ForceFieldOrder(rawValue: set.first!) : nil
  }
  
  public func setRepresentationForceFieldOrder(order: SKForceFieldSets.ForceFieldOrder?, forceFieldSets: SKForceFieldSets)
  {
    self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.setRepresentationForceFieldOrder(order: order, forceFieldSets: forceFieldSets)}
  }
  
  public var renderAtomHue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomHue})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomHue = newValue ?? 1.0}
    }
  }
  
  public var renderAtomSaturation: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomSaturation})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomSaturation = newValue ?? 1.0}
    }
  }
  
  public var renderAtomValue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomValue})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomValue = newValue ?? 1.0}
    }
  }
  
  public var renderAtomScaleFactor: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomScaleFactor})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? AtomStructureEditor)?.atomScaleFactor = newValue ?? 1.0
      }
    }
  }
  
  public var renderAtomScaleFactorCompleted: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomScaleFactor})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? AtomStructureEditor)?.atomScaleFactor = newValue ?? 1.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderDrawAtoms: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.drawAtoms})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.drawAtoms = newValue ?? true}
    }
  }
  
  public var renderAtomAmbientOcclusion: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomAmbientOcclusion})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomAmbientOcclusion = newValue ?? true}
    }
  }
  
  public var renderAtomHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomHDR})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomHDR = newValue ?? true}
    }
  }
  
  
  public var renderAtomHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomHDRExposure})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomHDRExposure = newValue ?? 1.0}
    }
  }
  
  public var renderAtomAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomAmbientColor})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomAmbientColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderAtomDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomDiffuseColor})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomDiffuseColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderAtomSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomSpecularColor})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomSpecularColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  
  public var renderAtomAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomAmbientIntensity})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderAtomDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomDiffuseIntensity})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAtomSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomSpecularIntensity})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAtomShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomShininess})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomShininess = newValue ?? 4.0}
    }
  }
  
  public var renderAtomSelectionStyle: RKSelectionStyle?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomSelectionStyle.rawValue})
      return Set(set).count == 1 ? RKSelectionStyle(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomSelectionStyle = newValue ?? .glow}
    }
  }
  
  public var renderAtomSelectionFrequency: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.renderAtomSelectionFrequency})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.renderAtomSelectionFrequency = newValue ?? 4.0}
    }
  }
  
  public var renderAtomSelectionDensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.renderAtomSelectionDensity})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.renderAtomSelectionDensity = newValue ?? 4.0}
    }
  }
  
  public var renderAtomSelectionIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomSelectionIntensity})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomSelectionIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAtomSelectionScaling: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AtomStructureEditor)?.atomSelectionScaling})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AtomStructureEditor)?.atomSelectionScaling = newValue ?? 1.0}
    }
  }
  
  // MARK: Bond Visual Appearance
  //===================================================================================================================================================
  
  public func recheckRepresentationStyleBond()
  {
    self.iRASPAObjects.forEach{($0.object as? BondStructureEditor)?.recheckRepresentationStyle()}
  }
  
  public var renderDrawBonds: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.drawBonds}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.drawBonds = newValue ?? false})
    }
  }
  
  public var renderBondScaleFactor: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondScaleFactor}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        ($0.object as? BondStructureEditor)?.bondScaleFactor = newValue ?? 1.0
        //if(($0.object as? BondVisualAppearanceViewer)?.atomRepresentationType == .unity)
        //{
        //  let asymmetricAtoms: [SKAsymmetricAtom] = ($0.object as? BondVisualAppearanceViewer)?.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
        //  asymmetricAtoms.forEach{($0.object as? BondVisualAppearanceViewer)?.drawRadius = newValue ?? 1.0}
        //}
      }
    }
  }
  
  public var renderBondColorMode: RKBondColorMode?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondColorMode.rawValue}))
      return Set(set).count == 1 ? RKBondColorMode(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondColorMode = newValue ?? .split})
    }
  }
  
  public var renderBondAmbientOcclusion: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondAmbientOcclusion}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondAmbientOcclusion = newValue ?? false})
    }
  }
  
  public var renderBondHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondHDR}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondHDR = newValue ?? false})
    }
  }
  
  public var renderBondHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondHDRExposure}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondHDRExposure = newValue ?? 1.5})
    }
  }
  
  public var renderBondHue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondHue}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondHue = newValue ?? 1.0})
    }
  }
  
  public var renderBondSaturation: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondSaturation}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondSaturation = newValue ?? 1.0})
    }
  }
  
  public var renderBondValue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondValue}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondValue = newValue ?? 1.0})
    }
  }
  
  public var renderBondAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondAmbientColor}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondAmbientColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)})
    }
  }
  
  public var renderBondDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondDiffuseColor}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondDiffuseColor = newValue ?? NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)})
    }
  }
  
  public var renderBondSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondSpecularColor}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondSpecularColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)})
    }
  }
  
  public var renderBondAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondAmbientIntensity}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondAmbientIntensity = newValue ?? 0.2})
    }
  }
  
  public var renderBondDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondDiffuseIntensity}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondDiffuseIntensity = newValue ?? 1.0})
    }
  }
  
  public var renderBondSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondSpecularIntensity}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondSpecularIntensity = newValue ?? 1.0})
    }
  }
  
  public var renderBondShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondShininess}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondShininess = newValue ?? 4.0})
    }
  }
  
  public var renderBondSelectionStyle: RKSelectionStyle?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondSelectionStyle.rawValue}))
      return Set(set).count == 1 ? RKSelectionStyle(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondSelectionStyle = newValue ?? .glow})
    }
  }
  
  public var renderBondSelectionFrequency: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.renderBondSelectionFrequency}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.renderBondSelectionFrequency = newValue ?? 4.0})
    }
  }
  
  public var renderBondSelectionDensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.renderBondSelectionDensity}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.renderBondSelectionDensity = newValue ?? 4.0})
    }
  }
  
  public var renderBondSelectionIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondSelectionIntensity}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondSelectionIntensity = newValue ?? 1.0})
    }
  }
  
  public var renderBondSelectionScaling: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? BondStructureEditor)?.bondSelectionScaling}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? BondStructureEditor)?.bondSelectionScaling = newValue ?? 1.0})
    }
  }

  
  // MARK: Unit Cell Visual Appearance
  //===================================================================================================================================================
  
  public var renderDrawUnitCell: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap({($0.object as? UnitCellViewer)?.drawUnitCell}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? UnitCellViewer)?.drawUnitCell = newValue ?? false})
    }
  }
  
  public var renderUnitCellScaleFactor: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? UnitCellEditor)?.unitCellScaleFactor}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? UnitCellEditor)?.unitCellScaleFactor = newValue ?? 1.0})
    }
  }
  
  public var renderUnitCellDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap({($0.object as? UnitCellEditor)?.unitCellDiffuseColor}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? UnitCellEditor)?.unitCellDiffuseColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)})
    }
  }
  
  public var renderUnitCellDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap({($0.object as? UnitCellEditor)?.unitCellDiffuseIntensity}))
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach({($0.object as? UnitCellEditor)?.unitCellDiffuseIntensity = newValue ?? 1.0})
    }
  }
  
  // MARK: Local Axes Visual Appearance
  //===================================================================================================================================================
  
  public var renderLocalAxesPosition: RKLocalAxes.Position?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{ return $0.object.renderLocalAxis.position.rawValue })
      return Set(set).count == 1 ? RKLocalAxes.Position(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{$0.object.renderLocalAxis.position = newValue ?? .none}
    }
  }
  
  public var renderLocalAxesStyle: RKLocalAxes.Style?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{ return $0.object.renderLocalAxis.style.rawValue })
      return Set(set).count == 1 ? RKLocalAxes.Style(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{$0.object.renderLocalAxis.style = newValue ?? .default}
    }
  }
  
  public var renderLocalAxesScalingType: RKLocalAxes.ScalingType?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{ return $0.object.renderLocalAxis.scalingType.rawValue })
      return Set(set).count == 1 ? RKLocalAxes.ScalingType(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{$0.object.renderLocalAxis.scalingType = newValue ?? .absolute}
    }
  }
  
  public var renderLocalAxesLength: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.renderLocalAxis.length })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{$0.object.renderLocalAxis.length = newValue ?? 5.0}
    }
  }
  
  public var renderLocalAxesWidth: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.renderLocalAxis.width })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{$0.object.renderLocalAxis.width = newValue ?? 5.0}
    }
  }
  
  public var renderLocalAxesOffsetX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.renderLocalAxis.offset.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{$0.object.renderLocalAxis.offset.x = newValue ?? 5.0}
    }
  }
  
  public var renderLocalAxesOffsetY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.renderLocalAxis.offset.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{$0.object.renderLocalAxis.offset.y = newValue ?? 5.0}
    }
  }
  
  public var renderLocalAxesOffsetZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.renderLocalAxis.offset.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{$0.object.renderLocalAxis.offset.z = newValue ?? 5.0}
    }
  }
  
  
  // MARK: Adsorption SurfaceVisual Appearance
  //===================================================================================================================================================
  

  public var renderGridRangeMinimum: Double?
  {
    let set: Set<(Double)> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.range.0})
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderGridRangeMaximum: Double?
  {
    let set: Set<(Double)> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.range.1})
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderAdsorptionSurfaceOn: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.drawAdsorptionSurface})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.drawAdsorptionSurface = newValue ?? false}
    }
  }
  
  public var renderAdsorptionSurfaceOpacity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceOpacity})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceOpacity = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionTransparencyThreshold: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionTransparencyThreshold})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionTransparencyThreshold = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceIsovalue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceIsoValue})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceIsoValue = newValue ?? 0.0}
    }
  }
  
  public var renderAdsorptionSurfaceMinimumValue: Double?
  {
    let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.range.0})
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderAdsorptionSurfaceMaximumValue: Double?
  {
    let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.range.1})
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderEncompassingPowerOfTwoCubicGridSize: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.encompassingPowerOfTwoCubicGridSize})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceEditor)?.encompassingPowerOfTwoCubicGridSize = newValue ?? 6}
    }
  }
  
  public var renderGridDimension: SIMD3<Int32>?
  {
    let set: Set<SIMD3<Int32>> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.dimensions})
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderAdsorptionRenderingMethod: RKEnergySurfaceType?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceRenderingMethod.rawValue})
      return Set(set).count == 1 ? RKEnergySurfaceType(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceRenderingMethod = newValue ?? RKEnergySurfaceType.isoSurface}
    }
  }
  
  public var renderAdsorptionVolumeTransferFunction: RKPredefinedVolumeRenderingTransferFunction?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionVolumeTransferFunction.rawValue})
      return Set(set).count == 1 ? RKPredefinedVolumeRenderingTransferFunction(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionVolumeTransferFunction = newValue ?? RKPredefinedVolumeRenderingTransferFunction.CoolWarmDiverging}
    }
  }
  
  public var renderAdsorptionVolumeStepLength: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionVolumeStepLength})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionVolumeStepLength = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceProbeMolecule: Structure.ProbeMolecule?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceProbeMolecule.rawValue})
      return Set(set).count == 1 ? Structure.ProbeMolecule(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceProbeMolecule = newValue ?? .helium}
    }
  }
  
  public var renderAdsorptionSurfaceHue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceHue})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceHue = newValue ?? 1.0}
    }
  }
    
  public var renderAdsorptionSurfaceSaturation: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceSaturation})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceSaturation = newValue ?? 1.0}
    }
  }
    
  public var renderAdsorptionSurfaceValue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceValue})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceValue = newValue ?? 1.0}
    }
  }
   
  
  public var renderAdsorptionSurfaceFrontSideHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideHDR})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideHDR = newValue ?? true}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideHDRExposure})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideHDRExposure = newValue ?? 1.5}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideAmbientIntensity})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideDiffuseIntensity})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideSpecularIntensity})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideShininess})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideShininess = newValue ?? 4.0}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideAmbientColor})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideAmbientColor = newValue ?? NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideDiffuseColor})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideDiffuseColor = newValue ?? NSColor(red: 0.588235, green: 0.670588, blue: 0.729412, alpha: 1.0)}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideHDR})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideHDR = newValue ?? true}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideHDRExposure})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideHDRExposure = newValue ?? 1.5}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideAmbientIntensity})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideDiffuseIntensity})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideSpecularIntensity})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideShininess})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideShininess = newValue ?? 4.0}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideSpecularColor})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceFrontSideSpecularColor = newValue ?? NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideAmbientColor})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideAmbientColor = newValue ?? NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideDiffuseColor})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideDiffuseColor = newValue ?? NSColor(red: 0.588235, green: 0.670588, blue: 0.729412, alpha: 1.0)}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideSpecularColor})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? IsosurfaceViewer)?.adsorptionSurfaceBackSideSpecularColor = newValue ?? NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)}
    }
  }

  
  // MARK: Annotation Visual Appearance
  //===================================================================================================================================================
  
  public var renderTextType: RKTextType?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{($0.object as? AnnotationEditor)?.atomTextType.rawValue})
      return Set(set).count == 1 ? RKTextType(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AnnotationEditor)?.atomTextType = newValue ?? .none}
    }
  }
  
  public var renderTextStyle: RKTextStyle?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{($0.object as? AnnotationEditor)?.atomTextStyle.rawValue})
      return Set(set).count == 1 ? RKTextStyle(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AnnotationEditor)?.atomTextStyle = newValue ?? .flatBillboard}
    }
  }
  
  public var renderTextAlignment: RKTextAlignment?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{($0.object as? AnnotationEditor)?.atomTextAlignment.rawValue})
      return Set(set).count == 1 ? RKTextAlignment(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AnnotationEditor)?.atomTextAlignment = newValue ?? .center}
    }
  }
  
  public var renderTextFont: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap{($0.object as? AnnotationEditor)?.atomTextFont})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AnnotationEditor)?.atomTextFont = newValue ?? "Helvetica"}
    }
  }
  
  public var renderTextFontFamily: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap({ (structure) -> String? in
        if let font: NSFont = NSFont(name: (structure.object as? AnnotationEditor)?.atomTextFont ?? "Helvetica", size: 32)
        {
          return font.familyName
        }
        return nil
      }))
      return Set(set).count == 1 ? set.first! : nil
    }
  }
  
  public var renderTextColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.iRASPAObjects.compactMap{($0.object as? AnnotationEditor)?.atomTextColor})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AnnotationEditor)?.atomTextColor = newValue ?? NSColor.black}
    }
  }
  
  public var renderTextScaling: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AnnotationEditor)?.atomTextScaling})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AnnotationEditor)?.atomTextScaling = newValue ?? 1.0}
    }
  }
  
  public var renderTextOffsetX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AnnotationEditor)?.atomTextOffset.x})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AnnotationEditor)?.atomTextOffset.x = newValue ?? 0.0}
    }
  }
  
  public var renderTextOffsetY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AnnotationEditor)?.atomTextOffset.y})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AnnotationEditor)?.atomTextOffset.y = newValue ?? 0.0}
    }
  }
  
  public var renderTextOffsetZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? AnnotationEditor)?.atomTextOffset.z})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? AnnotationEditor)?.atomTextOffset.z = newValue ?? 0.0}
    }
  }
}
