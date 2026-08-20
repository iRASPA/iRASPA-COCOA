/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 J.Vreede@uva.nl      https://www.uva.nl/en/profile/v/r/j.vreede/j.vreede.html
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
//

import Cocoa
import simd
import LogViewKit
import RenderKit
import iRASPAKit
import MathKit
import Dispatch


class StructureCameraDetailViewController: NSViewController, NSOutlineViewDelegate, WindowControllerConsumer, ProjectConsumer
{
  weak var windowController: iRASPAWindowController?
  
  @IBOutlet private weak var cameraOutlineView: NSStaticViewBasedOutlineView?
  
  var heights: [String : CGFloat] = [:]
  
  let cameraOrientationCell: OutlineViewItem = OutlineViewItem("CameraOrientationCell")
  let cameraRotationCell: OutlineViewItem = OutlineViewItem("CameraRotationCell")
  let cameraViewMatrixCell: OutlineViewItem = OutlineViewItem("CameraViewMatrixCell")
  let cameraVirtualPositionCell: OutlineViewItem = OutlineViewItem("CameraVirtualPositionCell")
  
  let cameraSelectionCell: OutlineViewItem = OutlineViewItem("CameraSelectionCell")
  
  let cameraAxesCell: OutlineViewItem = OutlineViewItem("CameraAxesCell")
  let cameraAxesBackgroundCell: OutlineViewItem = OutlineViewItem("CameraAxesBackgroundCell")
  let cameraAxesTextCell: OutlineViewItem = OutlineViewItem("CameraAxesTextCell")
  
  let cameraLightStyleCell: OutlineViewItem = OutlineViewItem("CameraLightStyleCell")

  /// One cell per light, in the order of `RKRenderLight.Role`. The control tags within a cell are offset
  /// by a hundred times the light index, so a handler can recover which light it belongs to.
  let cameraLightCells: [OutlineViewItem] = (1...RKLightUniforms.numberOfLights).map { OutlineViewItem("CameraLight\($0)Cell") }

  /// Holds the occlusion strength, which grades the whole scene rather than belonging to one light.
  let cameraLightsCell: OutlineViewItem = OutlineViewItem("CameraLightsCell")

  /// Depth cues drawn over the finished image. Kept beside occlusion, the two being the pair of cues
  /// the Fancy styles are built on.
  
  let cameraRaytracingCell: OutlineViewItem = OutlineViewItem("CameraRaytracingCell")

  let cameraPictureRayTracingCell: OutlineViewItem = OutlineViewItem("CameraPictureRayTracingCell")
  let cameraPictureCell: OutlineViewItem = OutlineViewItem("CameraPictureCell")
  let cameraPictureDimensionsCell: OutlineViewItem = OutlineViewItem("CameraPictureDimensionsCell")
  
  let cameraMovieCell: OutlineViewItem = OutlineViewItem("CameraMovieCell")
  let cameraBackgroundCell: OutlineViewItem = OutlineViewItem("CameraBackgroundCell")

  
  var movieTimer: DispatchSourceTimer? = nil
  
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
    
    // check that it works with strong-references off (for compatibility with 'El Capitan')
    self.cameraOutlineView?.stronglyReferencesItems = false
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    let cameraItem: OutlineViewItem = OutlineViewItem(title: "CameraGroup", children: [cameraOrientationCell, cameraRotationCell, cameraViewMatrixCell, cameraVirtualPositionCell])
    let cameraSelectionItem: OutlineViewItem = OutlineViewItem(title: "CameraSelectionGroup", children: [cameraSelectionCell])
    let cameraAxesItem: OutlineViewItem = OutlineViewItem(title: "CameraAxesGroup", children: [cameraAxesCell, cameraAxesBackgroundCell, cameraAxesTextCell])
    let cameraLightsItem: OutlineViewItem = OutlineViewItem(title: "CameraLightsGroup", children: [cameraLightStyleCell, cameraLightsCell] + cameraLightCells)
    let cameraRaytracingItem: OutlineViewItem = OutlineViewItem(title: "CameraRaytracingGroup", children: [cameraRaytracingCell])
    let cameraPictureItem: OutlineViewItem = OutlineViewItem(title: "CameraPictureGroup", children: [cameraPictureRayTracingCell, cameraPictureCell, cameraPictureDimensionsCell, cameraMovieCell])
    let cameraBackgroundItem: OutlineViewItem = OutlineViewItem(title: "CameraBackgroundGroup",children: [cameraBackgroundCell])

    self.cameraOutlineView?.items = [cameraItem, cameraSelectionItem, cameraAxesItem, cameraLightsItem, cameraRaytracingItem, cameraPictureItem, cameraBackgroundItem]
  }
  
  override func viewWillAppear()
  {
    self.cameraOutlineView?.needsLayout = true
    super.viewWillAppear()
    self.cameraOutlineView?.reloadData()
  }
  
  override func viewDidAppear()
  {
    super.viewDidAppear()
    
    // update the aspect-ratio data in the Camera-views when the view of the renderViewConroller changes
    NotificationCenter.default.addObserver(self, selector: #selector(StructureCameraDetailViewController.updateAspectRatioView), name: NSView.boundsDidChangeNotification, object: self.windowController?.detailTabViewController?.renderViewController)
    
    // update the camera view-matrix data in the Camera-views when the camera direction or distance changes
    NotificationCenter.default.addObserver(self, selector: #selector(StructureCameraDetailViewController.updateCameraViews), name: NSNotification.Name(rawValue: CameraNotificationStrings.didChangeNotification), object: nil)
    
    // update the camera Projection Camera-views when the camera direction or distance changes
    NotificationCenter.default.addObserver(self, selector: #selector(StructureCameraDetailViewController.updateCameraOrientationView), name: NSNotification.Name(rawValue: CameraNotificationStrings.projectionDidChangeNotification), object: windowController)
  }
  
  // the windowController still exists when the view is there
  override func viewWillDisappear()
  {
    super.viewWillDisappear()
    
    NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: self.windowController?.detailTabViewController?.renderViewController)

    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: CameraNotificationStrings.didChangeNotification), object: windowController)
  }
  
  func reloadData()
  {
    self.cameraOutlineView?.reloadData()
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
  
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
  {
    if let string: String = (item as? OutlineViewItem)?.title,
      let view: NSTableCellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: string), owner: self) as? NSTableCellView
    {
      setPropertiesCameraTableCells(on: view, identifier: string)
      setPropertiesSelectionTableCells(on: view, identifier: string)
      setPropertiesAxesTableCells(on: view, identifier: string)
      setPropertiesLightsTableCells(on: view, identifier: string)
      setPropertiesRaytracingTableCells(on: view, identifier: string)
      setPropertiesExportMediaTableCells(on: view, identifier: string)
      setPropertiesBackgroundTableCells(on: view, identifier: string)
      
      return view
    }
    return nil
  }
  
  func setPropertiesCameraTableCells(on view: NSTableCellView, identifier: String)
  {
    switch(identifier)
    {
    case "CameraOrientationCell":
      if let textFieldResetPercentage: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldResetPercentage.isEnabled = false
        if let camera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
        {
          textFieldResetPercentage.isEnabled = true
          textFieldResetPercentage.doubleValue = camera.resetPercentage
        }
      }
      
      if let buttonMinusX: NSButton = view.viewWithTag(2) as? NSButton,
         let buttonMinusY: NSButton = view.viewWithTag(3) as? NSButton,
         let buttonMinusZ: NSButton = view.viewWithTag(4) as? NSButton,
         let buttonPlusX: NSButton = view.viewWithTag(5) as? NSButton,
         let buttonPlusY: NSButton = view.viewWithTag(6) as? NSButton,
         let buttonPlusZ: NSButton = view.viewWithTag(7) as? NSButton
      {
        buttonMinusX.isEnabled = false
        buttonMinusY.isEnabled = false
        buttonMinusZ.isEnabled = false
        buttonPlusX.isEnabled = false
        buttonPlusY.isEnabled = false
        buttonPlusZ.isEnabled = false
        if let camera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
        {
          buttonMinusX.isEnabled = true
          buttonMinusY.isEnabled = true
          buttonMinusZ.isEnabled = true
          buttonPlusX.isEnabled = true
          buttonPlusY.isEnabled = true
          buttonPlusZ.isEnabled = true
          switch(camera.resetDirectionType)
          {
          case RKCamera.ResetDirectionType.minus_X:
            buttonMinusX.state = NSControl.StateValue.on
          case RKCamera.ResetDirectionType.minus_Y:
            buttonMinusY.state = NSControl.StateValue.on
          case RKCamera.ResetDirectionType.minus_Z:
            buttonMinusZ.state = NSControl.StateValue.on
          case RKCamera.ResetDirectionType.plus_X:
            buttonPlusX.state = NSControl.StateValue.on
          case RKCamera.ResetDirectionType.plus_Y:
            buttonPlusY.state = NSControl.StateValue.on
          case RKCamera.ResetDirectionType.plus_Z:
            buttonPlusZ.state = NSControl.StateValue.on
          }
        }
      }
      
     
      
      if let buttonPerspective: NSButton = view.viewWithTag(9) as? NSButton,
         let buttonOrthogonal: NSButton = view.viewWithTag(10) as? NSButton
      {
        buttonPerspective.isEnabled = false
        buttonOrthogonal.isEnabled = false
        if let camera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
        {
          buttonPerspective.isEnabled = true
          buttonOrthogonal.isEnabled = true
          switch(camera.frustrumType)
          {
          case RKCamera.FrustrumType.perspective:
            buttonPerspective.state = NSControl.StateValue.on
          case RKCamera.FrustrumType.orthographic:
            buttonOrthogonal.state = NSControl.StateValue.on
          }
        }
      }
      
      if let textFieldFieldOfField: NSTextField = view.viewWithTag(11) as? NSTextField
      {
        textFieldFieldOfField.isEnabled = false
        if let camera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
        {
          textFieldFieldOfField.isEnabled = true
          textFieldFieldOfField.doubleValue = camera.angleOfView * 180.0 / Double.pi
        }
      }
      
      if let textFieldCenterOfSceneX: NSTextField = view.viewWithTag(13) as? NSTextField,
         let textFieldCenterOfSceneY: NSTextField = view.viewWithTag(14) as? NSTextField,
         let textFieldCenterOfSceneZ: NSTextField = view.viewWithTag(15) as? NSTextField
      {
        textFieldCenterOfSceneX.isEnabled = false
        textFieldCenterOfSceneY.isEnabled = false
        textFieldCenterOfSceneZ.isEnabled = false
        if let camera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
        {
          textFieldCenterOfSceneX.isEnabled = true
          textFieldCenterOfSceneY.isEnabled = true
          textFieldCenterOfSceneZ.isEnabled = true
          textFieldCenterOfSceneX.doubleValue = camera.centerOfScene.x
          textFieldCenterOfSceneY.doubleValue = camera.centerOfScene.y
          textFieldCenterOfSceneZ.doubleValue = camera.centerOfScene.z
        }
      }
    case "CameraRotationCell":
      if let textFieldRotationDelta: NSTextField = view.viewWithTag(1) as? NSTextField,
         let textFieldYawPlusX: NSButton = view.viewWithTag(2) as? NSButton,
         let textFieldYawPlusY: NSButton = view.viewWithTag(3) as? NSButton,
         let textFieldYawPlusZ: NSButton = view.viewWithTag(4) as? NSButton,
         let textFieldYawMinusX: NSButton = view.viewWithTag(5) as? NSButton,
         let textFieldYawMinusY: NSButton = view.viewWithTag(6) as? NSButton,
         let textFieldYawMinusZ: NSButton = view.viewWithTag(7) as? NSButton
      {
        textFieldRotationDelta.isEnabled = false
        textFieldYawPlusX.isEnabled = false
        textFieldYawPlusY.isEnabled = false
        textFieldYawPlusZ.isEnabled = false
        textFieldYawMinusX.isEnabled = false
        textFieldYawMinusY.isEnabled = false
        textFieldYawMinusZ.isEnabled = false
        if let rotationDelta: Double = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.rotationDelta
        {
          textFieldRotationDelta.isEnabled = true
          textFieldYawPlusX.isEnabled = true
          textFieldYawPlusY.isEnabled = true
          textFieldYawPlusZ.isEnabled = true
          textFieldYawMinusX.isEnabled = true
          textFieldYawMinusY.isEnabled = true
          textFieldYawMinusZ.isEnabled = true
          
          let formatter = MeasurementFormatter()
          formatter.unitStyle = .short
          formatter.unitOptions = .providedUnit
          let minusString = formatter.string(from: Measurement(value: -rotationDelta, unit: UnitAngle.degrees))
          let plusString = formatter.string(from: Measurement(value: rotationDelta, unit: UnitAngle.degrees))

          textFieldRotationDelta.doubleValue =  rotationDelta
          textFieldYawPlusX.title =  String.localizedStringWithFormat(NSLocalizedString("Rotate (%@)", comment: ""), plusString)
          textFieldYawPlusY.title =  String.localizedStringWithFormat(NSLocalizedString("Rotate (%@)", comment: ""), plusString)
          textFieldYawPlusZ.title =  String.localizedStringWithFormat(NSLocalizedString("Rotate (%@)", comment: ""), plusString)
          textFieldYawMinusX.title =  String.localizedStringWithFormat(NSLocalizedString("Rotate (%@)", comment: ""), minusString)
          textFieldYawMinusY.title =  String.localizedStringWithFormat(NSLocalizedString("Rotate (%@)", comment: ""), minusString)
          textFieldYawMinusZ.title =  String.localizedStringWithFormat(NSLocalizedString("Rotate (%@)", comment: ""), minusString)
        }
      }
      
      if let textFieldEulerAngleX: NSTextField = view.viewWithTag(8) as? NSTextField,
         let textFieldEulerAngleZ: NSTextField = view.viewWithTag(9) as? NSTextField,
         let textFieldEulerAngleY: NSTextField = view.viewWithTag(10) as? NSTextField,
         let sliderEulerAngleX: NSSlider = view.viewWithTag(11) as? NSSlider,
         let sliderEulerAngleZ: NSSlider = view.viewWithTag(12) as? NSSlider,
         let sliderEulerAngleY: NSSlider = view.viewWithTag(13) as? NSSlider
      {
        textFieldEulerAngleX.isEnabled = false
        sliderEulerAngleX.isEnabled = false
        textFieldEulerAngleZ.isEnabled = false
        sliderEulerAngleZ.isEnabled = false
        textFieldEulerAngleY.isEnabled = false
        sliderEulerAngleY.isEnabled = false
        if let EulerAngles: SIMD3<Double> = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.EulerAngles
        {
          textFieldEulerAngleX.isEnabled = true
          sliderEulerAngleX.isEnabled = true
          textFieldEulerAngleZ.isEnabled = true
          sliderEulerAngleZ.isEnabled = true
          textFieldEulerAngleY.isEnabled = true
          sliderEulerAngleY.isEnabled = true
          textFieldEulerAngleX.doubleValue =  EulerAngles.x * 180.0/Double.pi
          sliderEulerAngleX.doubleValue = (EulerAngles.x * 180.0/Double.pi)
          textFieldEulerAngleZ.doubleValue =  EulerAngles.z * 180.0/Double.pi
          sliderEulerAngleZ.doubleValue = EulerAngles.z * 180.0/Double.pi
          textFieldEulerAngleY.doubleValue =  EulerAngles.y * 180.0/Double.pi
          sliderEulerAngleY.doubleValue = EulerAngles.y * 180.0/Double.pi
        }
      }
    case "CameraViewMatrixCell":
      if let fieldM11: NSTextField = view.viewWithTag(1) as? NSTextField,
         let fieldM21: NSTextField = view.viewWithTag(2) as? NSTextField,
         let fieldM31: NSTextField = view.viewWithTag(3) as? NSTextField,
         let fieldM41: NSTextField = view.viewWithTag(4) as? NSTextField,
         let fieldM12: NSTextField = view.viewWithTag(5) as? NSTextField,
         let fieldM22: NSTextField = view.viewWithTag(6) as? NSTextField,
         let fieldM32: NSTextField = view.viewWithTag(7) as? NSTextField,
         let fieldM42: NSTextField = view.viewWithTag(8) as? NSTextField,
         let fieldM13: NSTextField = view.viewWithTag(9) as? NSTextField,
         let fieldM23: NSTextField = view.viewWithTag(10) as? NSTextField,
         let fieldM33: NSTextField = view.viewWithTag(11) as? NSTextField,
         let fieldM43: NSTextField = view.viewWithTag(12) as? NSTextField,
         let fieldM14: NSTextField = view.viewWithTag(13) as? NSTextField,
         let fieldM24: NSTextField = view.viewWithTag(14) as? NSTextField,
         let fieldM34: NSTextField = view.viewWithTag(15) as? NSTextField,
         let fieldM44: NSTextField = view.viewWithTag(16) as? NSTextField
      {
        fieldM11.isEnabled = false
        fieldM21.isEnabled = false
        fieldM31.isEnabled = false
        fieldM41.isEnabled = false
        
        fieldM12.isEnabled = false
        fieldM22.isEnabled = false
        fieldM32.isEnabled = false
        fieldM42.isEnabled = false
        
        fieldM13.isEnabled = false
        fieldM23.isEnabled = false
        fieldM33.isEnabled = false
        fieldM43.isEnabled = false
        
        fieldM14.isEnabled = false
        fieldM24.isEnabled = false
        fieldM34.isEnabled = false
        fieldM44.isEnabled = false
        if let viewMatrix: double4x4 = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.modelViewMatrix
        {
          fieldM11.isEnabled = true
          fieldM21.isEnabled = true
          fieldM31.isEnabled = true
          fieldM41.isEnabled = true
          
          fieldM12.isEnabled = true
          fieldM22.isEnabled = true
          fieldM32.isEnabled = true
          fieldM42.isEnabled = true
          
          fieldM13.isEnabled = true
          fieldM23.isEnabled = true
          fieldM33.isEnabled = true
          fieldM43.isEnabled = true
          
          fieldM14.isEnabled = true
          fieldM24.isEnabled = true
          fieldM34.isEnabled = true
          fieldM44.isEnabled = true
          
          fieldM11.doubleValue = viewMatrix[0][0]
          fieldM21.doubleValue = viewMatrix[0][1]
          fieldM31.doubleValue = viewMatrix[0][2]
          fieldM41.doubleValue = viewMatrix[0][3]
          
          fieldM12.doubleValue = viewMatrix[1][0]
          fieldM22.doubleValue = viewMatrix[1][1]
          fieldM32.doubleValue = viewMatrix[1][2]
          fieldM42.doubleValue = viewMatrix[1][3]
          
          fieldM13.doubleValue = viewMatrix[2][0]
          fieldM23.doubleValue = viewMatrix[2][1]
          fieldM33.doubleValue = viewMatrix[2][2]
          fieldM43.doubleValue = viewMatrix[2][3]
          
          fieldM14.doubleValue = viewMatrix[3][0]
          fieldM24.doubleValue = viewMatrix[3][1]
          fieldM34.doubleValue = viewMatrix[3][2]
          fieldM44.doubleValue = viewMatrix[3][3]
        }
      }
    case "CameraVirtualPositionCell":
      if let textFieldCameraPositionX: NSTextField = view.viewWithTag(1) as? NSTextField,
         let textFieldCameraPositionY: NSTextField = view.viewWithTag(2) as? NSTextField,
         let textFieldCameraPositionZ: NSTextField = view.viewWithTag(3) as? NSTextField,
         let textFieldCameraDistance: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        if let position: SIMD3<Double> = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.position
        {
          textFieldCameraPositionX.doubleValue = position.x
          textFieldCameraPositionY.doubleValue = position.y
          textFieldCameraPositionZ.doubleValue = position.z
          textFieldCameraDistance.doubleValue = length(position)
        }
      }
    default:
      break
    }
  }
  
  func setPropertiesSelectionTableCells(on view: NSTableCellView, identifier: String)
  {
    switch(identifier)
    {
    case "CameraSelectionCell":
      // Overall bloom level
      if let textFieldAtomSelectionIntensityLevel: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldAtomSelectionIntensityLevel.isEditable = false
        if let camera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
        {
          textFieldAtomSelectionIntensityLevel.isEditable = true
          textFieldAtomSelectionIntensityLevel.doubleValue = camera.bloomLevel
        }
      }
      if let sliderAtomSelectionIntensityLevel: NSSlider = view.viewWithTag(2) as? NSSlider
      {
        sliderAtomSelectionIntensityLevel.isEnabled = false
        sliderAtomSelectionIntensityLevel.minValue = 0.0
        sliderAtomSelectionIntensityLevel.maxValue = 2.0
        if let camera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
        {
          sliderAtomSelectionIntensityLevel.isEnabled = true
          sliderAtomSelectionIntensityLevel.doubleValue = camera.bloomLevel
        }
      }
    default:
      break
    }
  }
  
  func setPropertiesAxesTableCells(on view: NSTableCellView, identifier: String)
  {
    switch(identifier)
    {
      case "CameraAxesCell":
        if let popUpbuttonPositionType: NSPopUpButton = view.viewWithTag(1) as? NSPopUpButton
        {
          popUpbuttonPositionType.isEnabled = false
          if let project = representedObject as? ProjectStructureNode
          {
            popUpbuttonPositionType.isEnabled = true
            popUpbuttonPositionType.selectItem(at: project.renderAxes.position.rawValue)
          }
        }
        
        if let popUpbuttonStyleType: NSPopUpButton = view.viewWithTag(3) as? NSPopUpButton
        {
          popUpbuttonStyleType.isEnabled = false
          if let project = representedObject as? ProjectStructureNode
          {
            popUpbuttonStyleType.isEnabled = true
            popUpbuttonStyleType.selectItem(at: project.renderAxes.style.rawValue)
          }
        }
        
        if let textFieldAxesSize: NSTextField = view.viewWithTag(3) as? NSTextField
        {
          textFieldAxesSize.isEnabled = false
          if let project = representedObject as? ProjectStructureNode
          {
            textFieldAxesSize.isEnabled = true
            textFieldAxesSize.doubleValue = 100.0 * project.renderAxes.sizeScreenFraction
          }
        }
        
        if let textFieldAxesBorderOffset: NSTextField = view.viewWithTag(4) as? NSTextField
        {
          textFieldAxesBorderOffset.isEnabled = false
          if let project = representedObject as? ProjectStructureNode
          {
            textFieldAxesBorderOffset.isEnabled = true
            textFieldAxesBorderOffset.doubleValue = 100.0 * project.renderAxes.borderOffsetScreenFraction
          }
        }
    case "CameraAxesBackgroundCell":
      if let popupBackgroundType: NSPopUpButton = view.viewWithTag(1) as? NSPopUpButton,
         let colorWellBackground: NSColorWell = view.viewWithTag(2) as? NSColorWell,
         let textFieldAdditionalSize: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        popupBackgroundType.isEnabled = false
        colorWellBackground.isEnabled = false
        textFieldAdditionalSize.isEnabled = false
        if let project = representedObject as? ProjectStructureNode
        {
          popupBackgroundType.isEnabled = true
          colorWellBackground.isEnabled = true
          textFieldAdditionalSize.isEnabled = true
          popupBackgroundType.selectItem(at: project.renderAxes.axesBackgroundStyle.rawValue)
          colorWellBackground.color = project.renderAxes.axesBackgroundColor
          textFieldAdditionalSize.doubleValue = project.renderAxes.axesBackgroundAdditionalSize
        }
      }
    case "CameraAxesTextCell":
      if let textFieldScaleX: NSTextField = view.viewWithTag(1) as? NSTextField,
         let textFieldScaleY: NSTextField = view.viewWithTag(2) as? NSTextField,
         let textFieldScaleZ: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldScaleX.isEnabled = false
        textFieldScaleY.isEnabled = false
        textFieldScaleZ.isEnabled = false
        if let project = representedObject as? ProjectStructureNode
        {
          textFieldScaleX.isEnabled = true
          textFieldScaleY.isEnabled = true
          textFieldScaleZ.isEnabled = true
          textFieldScaleX.doubleValue = project.renderAxes.textScale.x
          textFieldScaleY.doubleValue = project.renderAxes.textScale.y
          textFieldScaleZ.doubleValue = project.renderAxes.textScale.z
        }
      }
      if let textFieldOffsetX: NSTextField = view.viewWithTag(4) as? NSTextField,
         let textFieldOffsetY: NSTextField = view.viewWithTag(5) as? NSTextField,
         let textFieldOffsetZ: NSTextField = view.viewWithTag(6) as? NSTextField,
         let colorWell: NSColorWell = view.viewWithTag(7) as? NSColorWell
      {
        textFieldOffsetX.isEnabled = false
        textFieldOffsetY.isEnabled = false
        textFieldOffsetZ.isEnabled = false
        colorWell.isEnabled = false
        if let project = representedObject as? ProjectStructureNode
        {
          textFieldOffsetX.isEnabled = true
          textFieldOffsetY.isEnabled = true
          textFieldOffsetZ.isEnabled = true
          colorWell.isEnabled = true
          textFieldOffsetX.doubleValue = project.renderAxes.textDisplacementX.x
          textFieldOffsetY.doubleValue = project.renderAxes.textDisplacementX.y
          textFieldOffsetZ.doubleValue = project.renderAxes.textDisplacementX.z
          colorWell.color = project.renderAxes.textColorX
        }
      }
      if let textFieldOffsetX: NSTextField = view.viewWithTag(8) as? NSTextField,
         let textFieldOffsetY: NSTextField = view.viewWithTag(9) as? NSTextField,
         let textFieldOffsetZ: NSTextField = view.viewWithTag(10) as? NSTextField,
         let colorWell: NSColorWell = view.viewWithTag(11) as? NSColorWell
      {
        textFieldOffsetX.isEnabled = false
        textFieldOffsetY.isEnabled = false
        textFieldOffsetZ.isEnabled = false
        colorWell.isEnabled = false
        if let project = representedObject as? ProjectStructureNode
        {
          textFieldOffsetX.isEnabled = true
          textFieldOffsetY.isEnabled = true
          textFieldOffsetZ.isEnabled = true
          colorWell.isEnabled = true
          textFieldOffsetX.doubleValue = project.renderAxes.textDisplacementY.x
          textFieldOffsetY.doubleValue = project.renderAxes.textDisplacementY.y
          textFieldOffsetZ.doubleValue = project.renderAxes.textDisplacementY.z
          colorWell.color = project.renderAxes.textColorY
        }
      }
      if let textFieldOffsetX: NSTextField = view.viewWithTag(12) as? NSTextField,
         let textFieldOffsetY: NSTextField = view.viewWithTag(13) as? NSTextField,
         let textFieldOffsetZ: NSTextField = view.viewWithTag(14) as? NSTextField,
         let colorWell: NSColorWell = view.viewWithTag(15) as? NSColorWell
      {
        textFieldOffsetX.isEnabled = false
        textFieldOffsetY.isEnabled = false
        textFieldOffsetZ.isEnabled = false
        colorWell.isEnabled = false
        if let project = representedObject as? ProjectStructureNode
        {
          textFieldOffsetX.isEnabled = true
          textFieldOffsetY.isEnabled = true
          textFieldOffsetZ.isEnabled = true
          colorWell.isEnabled = true
          textFieldOffsetX.doubleValue = project.renderAxes.textDisplacementZ.x
          textFieldOffsetY.doubleValue = project.renderAxes.textDisplacementZ.y
          textFieldOffsetZ.doubleValue = project.renderAxes.textDisplacementZ.z
          colorWell.color = project.renderAxes.textColorZ
        }
      }
      break
      default:
        break
    }
  }
  
  func setPropertiesLightsTableCells(on view: NSTableCellView, identifier: String)
  {
    if identifier == "CameraLightStyleCell"
    {
      if let popUpButton: NSPopUpButton = view.viewWithTag(1) as? NSPopUpButton
      {
        let project: ProjectStructureNode? = representedObject as? ProjectStructureNode

        popUpButton.isEnabled = (project != nil)
        popUpButton.selectItem(withTitle: (project?.renderLightStyle ?? RKLightStyle.default).displayName)
        popUpButton.toolTip = "A named set of lights. The emulations follow the documented defaults of those viewers and are a starting point rather than a match. Editing any light turns this to Custom"
      }
      return
    }

    if identifier == "CameraLightsCell"
    {
      if let sceneAmbientIntensity: NSTextField = view.viewWithTag(16) as? NSTextField,
         let sliderSceneAmbientIntensity: NSSlider = view.viewWithTag(17) as? NSSlider,
         let sceneAmbientColor: NSColorWell = view.viewWithTag(18) as? NSColorWell
      {
        let project: ProjectStructureNode? = representedObject as? ProjectStructureNode

        sceneAmbientIntensity.isEnabled = (project != nil)
        sliderSceneAmbientIntensity.isEnabled = (project != nil)
        sceneAmbientColor.isEnabled = (project != nil)
        sceneAmbientIntensity.toolTip = "Light reaching the structure from the environment as a whole, which is why it is not part of any one light: switching every light off leaves this. It scales each material's own ambient, which the representation style sets, so one leaves that style as intended and less than one darkens all of them"

        sliderSceneAmbientIntensity.minValue = 0.0
        sliderSceneAmbientIntensity.maxValue = 1.0
        sceneAmbientIntensity.doubleValue = project?.renderSceneAmbientIntensity ?? 1.0
        sliderSceneAmbientIntensity.doubleValue = project?.renderSceneAmbientIntensity ?? 1.0
        sceneAmbientColor.color = project?.renderSceneAmbientColor ?? NSColor.white
      }

      if let ambientOcclusionStrength: NSTextField = view.viewWithTag(12) as? NSTextField,
         let sliderAmbientOcclusionStrength: NSSlider = view.viewWithTag(13) as? NSSlider
      {
        let project: ProjectStructureNode? = representedObject as? ProjectStructureNode

        ambientOcclusionStrength.isEnabled = (project != nil)
        sliderAmbientOcclusionStrength.isEnabled = (project != nil)
        ambientOcclusionStrength.toolTip = "How strongly occlusion darkens the direct lighting as well as the ambient light. Zero is physically correct, one matches the older Fancy look. Used by both the rasterizer and the path tracer"

        sliderAmbientOcclusionStrength.minValue = 0.0
        sliderAmbientOcclusionStrength.maxValue = 1.0
        ambientOcclusionStrength.doubleValue = project?.renderAmbientOcclusionStrength ?? 0.0
        sliderAmbientOcclusionStrength.doubleValue = project?.renderAmbientOcclusionStrength ?? 0.0
      }

      if let shadows: NSButton = view.viewWithTag(19) as? NSButton
      {
        let project: ProjectStructureNode? = representedObject as? ProjectStructureNode
        let supported: Bool = MTLCreateSystemDefaultDevice().map{MetalPathTracerShader.isSupported(device: $0)} ?? false

        shadows.isEnabled = (project != nil) && supported
        shadows.state = (project?.renderShadows ?? false) ? NSControl.StateValue.on : NSControl.StateValue.off
        shadows.toolTip = supported
            ? "Darkens the surfaces a light cannot reach, by tracing the scene the way ray tracing does. A light sitting on the camera casts no shadow, so this only shows with a style whose lights are off to one side. Pictures and movies follow this; whether the render view does is set under Raytracing/Shadows"
            : "This graphics card cannot trace rays, so shadows are unavailable"
      }
      return
    }

    if let lightIndex: Int = self.cameraLightCells.firstIndex(where: { $0.title == identifier })
    {
      self.setPropertiesLightCell(on: view, lightIndex: lightIndex)
    }
  }

  private func setPropertiesLightCell(on view: NSTableCellView, lightIndex: Int)
  {
    let project: ProjectStructureNode? = representedObject as? ProjectStructureNode
    let light: RKRenderLight? = (project != nil && lightIndex < project!.renderLights.count) ? project!.renderLights[lightIndex] : nil

    // everything but the checkbox is pointless while the light is off, so it follows the checkbox
    let base: Int = lightIndex * 100
    let isOn: Bool = light?.isEnabled ?? false

    if let checkbox: NSButton = view.viewWithTag(base + 14) as? NSButton
    {
      checkbox.isEnabled = (light != nil)
      checkbox.state = isOn ? NSControl.StateValue.on : NSControl.StateValue.off
      checkbox.toolTip = lightIndex == 0
          ? "On the view axis, and the only light on by default. Switching it off leaves the scene lit by whichever other lights are on"
          : "Placed for its photographic role, relative to the camera rather than to the structure"
    }

    if let popUpButton: NSPopUpButton = view.viewWithTag(base + 15) as? NSPopUpButton
    {
      popUpButton.isEnabled = isOn
      popUpButton.selectItem(at: light?.type.rawValue ?? 0)
      popUpButton.toolTip = "Directional lights are placed by direction and do not fall off with distance. Point and spot lights are placed by position"
    }

    // diffuse and specular each pair an intensity field and slider with a colour well. Ambient is absent
    // because it belongs to the scene, and is edited once in the cell above rather than per light
    let terms: [(field: Int, slider: Int, color: Int, intensity: Double?, color2: NSColor?)] =
        [(base + 4, base + 5, base + 6, light?.diffuseIntensity, light?.diffuse),
         (base + 7, base + 8, base + 9, light?.specularIntensity, light?.specular)]

    for term in terms
    {
      if let field: NSTextField = view.viewWithTag(term.field) as? NSTextField
      {
        field.isEnabled = isOn
        field.doubleValue = term.intensity ?? 0.0
      }
      if let slider: NSSlider = view.viewWithTag(term.slider) as? NSSlider
      {
        slider.isEnabled = isOn
        slider.minValue = 0.0
        slider.maxValue = 1.0
        slider.doubleValue = term.intensity ?? 0.0
      }
      if let colorWell: NSColorWell = view.viewWithTag(term.color) as? NSColorWell
      {
        colorWell.isEnabled = isOn
        colorWell.color = term.color2 ?? NSColor.white
      }
    }

    if let shininess: NSTextField = view.viewWithTag(base + 10) as? NSTextField
    {
      shininess.isEnabled = isOn
      shininess.doubleValue = light?.shininess ?? 0.0
    }
    if let sliderShininess: NSSlider = view.viewWithTag(base + 11) as? NSSlider
    {
      sliderShininess.isEnabled = isOn
      sliderShininess.minValue = 0.1
      sliderShininess.maxValue = 128.0
      sliderShininess.doubleValue = light?.shininess ?? 0.1
    }
  }

  func setPropertiesRaytracingTableCells(on view: NSTableCellView, identifier: String)
  {
    switch(identifier)
    {
    case "CameraRaytracingCell":
      if let checkboxRayTracing: NSButton = view.viewWithTag(20) as? NSButton,
         let textFieldSampleCount: NSTextField = view.viewWithTag(21) as? NSTextField,
         let textFieldRotatingSampleCount: NSTextField = view.viewWithTag(22) as? NSTextField,
         let textFieldMaximumBounces: NSTextField = view.viewWithTag(23) as? NSTextField
      {
        // these are application-wide settings rather than project properties: how many samples a
        // frame can afford says more about the machine than about the structure. They are still
        // meaningless without a project to render.
        let isRayTracingSupported: Bool = RKRenderSettings.isRayTracingSupported
        let hasProject: Bool = (representedObject as? ProjectStructureNode) != nil
        let isRayTracing: Bool = RKRenderSettings.shared.interactiveRenderMode == .rayTracing

        checkboxRayTracing.isEnabled = hasProject && isRayTracingSupported
        checkboxRayTracing.state = isRayTracing ? NSControl.StateValue.on : NSControl.StateValue.off
        checkboxRayTracing.toolTip = isRayTracingSupported
            ? "Draw the render view with the path tracer instead of the rasterizer"
            : "This GPU does not support ray tracing"

        let enabled: Bool = checkboxRayTracing.isEnabled && isRayTracing

        textFieldSampleCount.isEnabled = enabled
        textFieldSampleCount.integerValue = RKRenderSettings.shared.interactiveSampleCount
        textFieldSampleCount.toolTip = "Paths traced per pixel while the camera is at rest"

        textFieldRotatingSampleCount.isEnabled = enabled
        textFieldRotatingSampleCount.integerValue = RKRenderSettings.shared.interactiveRotatingSampleCount
        textFieldRotatingSampleCount.toolTip = "Paths traced per pixel while the camera is being moved. Fewer samples mean a noisier but faster frame; the colours do not change"

        textFieldMaximumBounces.isEnabled = enabled
        textFieldMaximumBounces.integerValue = RKRenderSettings.shared.interactiveMaximumBounces
        textFieldMaximumBounces.toolTip = "How often light may bounce between surfaces, at most \(RKRenderSettings.maximumSupportedInteractiveBounces). Zero is direct lighting only"

        if let checkboxShadows: NSButton = view.viewWithTag(24) as? NSButton
        {
          // The path tracer casts its own shadow rays, so with ray-tracing on this is always on and
          // cannot be turned off. It only chooses whether the rasterizer spends a mask pass.
          if isRayTracing
          {
            checkboxShadows.isEnabled = false
            checkboxShadows.state = NSControl.StateValue.on
            checkboxShadows.toolTip = "Shadows are always included when the render view is path-traced"
          }
          else
          {
            checkboxShadows.isEnabled = hasProject && isRayTracingSupported
            checkboxShadows.state = RKRenderSettings.shared.interactiveShadows ? NSControl.StateValue.on : NSControl.StateValue.off
            checkboxShadows.toolTip = isRayTracingSupported
                ? (RKRenderSettings.tracesRaysInHardware
                    ? "Trace shadows for the render view. Pictures and movies follow the scene's own Shadows setting instead"
                    : "Trace shadows for the render view. This GPU traces rays in a shader rather than in hardware, so every frame pays for them; pictures and movies follow the scene's own Shadows setting and are unaffected")
                : "This GPU cannot trace rays, so shadows are unavailable"
          }
        }
      }
    default:
      break
    }
  }

  func setPropertiesExportMediaTableCells(on view: NSTableCellView, identifier: String)
  {
    switch(identifier)
    {
    case "CameraPictureRayTracingCell":
      if let checkboxRayTracing: NSButton = view.viewWithTag(7) as? NSButton,
         let textFieldSampleCount: NSTextField = view.viewWithTag(8) as? NSTextField,
         let textFieldMaximumBounces: NSTextField = view.viewWithTag(9) as? NSTextField
      {
        checkboxRayTracing.isEnabled = false
        textFieldSampleCount.isEnabled = false
        textFieldMaximumBounces.isEnabled = false

        // the checkbox reflects what the document asks for, which stays visible even on a machine
        // that cannot honour it; the tracer itself falls back to rasterizing
        let isRayTracingSupported: Bool = RKRenderSettings.isRayTracingSupported

        checkboxRayTracing.toolTip = isRayTracingSupported
            ? "Render exported pictures and movies with the path tracer"
            : "This GPU does not support ray tracing, so exports will be rasterized"
        textFieldSampleCount.toolTip = "Paths traced per pixel, at most \(RKRenderSettings.maximumSupportedPictureSamples). More samples mean less noise and a longer render"
        textFieldMaximumBounces.toolTip = "How often light may bounce between surfaces, at most \(RKRenderSettings.maximumSupportedPictureBounces). Zero is direct lighting only, and the image stops changing noticeably after a handful"

        if let project: ProjectStructureNode = representedObject as? ProjectStructureNode
        {
          let settings: RKPathTracerSettings = project.picturePathTracerSettings

          checkboxRayTracing.isEnabled = isRayTracingSupported
          checkboxRayTracing.state = project.renderPictureRayTracing ? NSControl.StateValue.on : NSControl.StateValue.off

          let enabled: Bool = isRayTracingSupported && project.renderPictureRayTracing
          textFieldSampleCount.isEnabled = enabled
          textFieldSampleCount.integerValue = settings.sampleCount
          textFieldMaximumBounces.isEnabled = enabled
          textFieldMaximumBounces.integerValue = settings.maximumBounces
        }
      }
    case "CameraPictureCell":
      if let popUpbuttonDPI: NSPopUpButton = view.viewWithTag(1) as? NSPopUpButton,
         let popUpbuttonPictureQuality: NSPopUpButton = view.viewWithTag(2) as? NSPopUpButton,
         let textFieldPhysicalDimensionsX: NSTextField = view.viewWithTag(3) as? NSTextField,
         let textFieldPhysicalDimensionsY: NSTextField = view.viewWithTag(4) as? NSTextField,
         let textFieldNumberOfPixelsX: NSTextField = view.viewWithTag(5) as? NSTextField,
         let textFieldNumberOfPixelsY: NSTextField = view.viewWithTag(6) as? NSTextField
      {
        popUpbuttonDPI.isEnabled = false
        textFieldPhysicalDimensionsX.isEnabled = false
        textFieldPhysicalDimensionsY.isEnabled = false
        popUpbuttonPictureQuality.isEnabled = false
        textFieldNumberOfPixelsX.isEnabled = false
        textFieldNumberOfPixelsY.isEnabled = false
        
        if let project = representedObject as? ProjectStructureNode
        {
          popUpbuttonDPI.isEnabled = true
          textFieldPhysicalDimensionsX.isEnabled = true
          textFieldPhysicalDimensionsY.isEnabled = true
          popUpbuttonPictureQuality.isEnabled = true
          textFieldNumberOfPixelsX.isEnabled = true
          textFieldNumberOfPixelsY.isEnabled = true
          
          popUpbuttonDPI.selectItem(at: project.imageDPI.rawValue)
          
          switch(project.imageUnits)
          {
          case .inch:
            textFieldPhysicalDimensionsX.doubleValue = Double(project.renderImagePhysicalSizeInInches)
          case .cm:
            textFieldPhysicalDimensionsX.doubleValue = Double(2.54 * project.renderImagePhysicalSizeInInches)
          }
          
          let aspectRatioValue: Double = self.windowController?.detailTabViewController?.renderViewController?.aspectRatioValue ?? 1.0
          
          switch(project.imageUnits)
          {
          case .inch:
            textFieldPhysicalDimensionsY.doubleValue = Double(project.renderImagePhysicalSizeInInches / aspectRatioValue)
          case .cm:
            textFieldPhysicalDimensionsY.doubleValue = Double(2.54 * project.renderImagePhysicalSizeInInches / aspectRatioValue)
          }
          
          popUpbuttonPictureQuality.selectItem(at: project.renderImageQuality.rawValue)
          
          textFieldNumberOfPixelsX.doubleValue = Double(project.renderImageNumberOfPixels)
          textFieldNumberOfPixelsY.doubleValue = rint(Double(project.renderImageNumberOfPixels) / aspectRatioValue)
          
          switch(project.imageDimensions)
          {
          case ProjectStructureNode.Dimensions.physical:
            textFieldPhysicalDimensionsX.isEnabled = true
            textFieldPhysicalDimensionsY.isEnabled = false
            textFieldNumberOfPixelsX.isEnabled = false
            textFieldNumberOfPixelsY.isEnabled = false
          case ProjectStructureNode.Dimensions.pixels:
            textFieldPhysicalDimensionsX.isEnabled = false
            textFieldPhysicalDimensionsY.isEnabled = false
            textFieldNumberOfPixelsX.isEnabled = true
            textFieldNumberOfPixelsY.isEnabled = false
          }
        }
      }
    case "CameraPictureDimensionsCell":
      if let buttonPhysical: NSButton = view.viewWithTag(1) as? NSButton,
         let buttonPixels: NSButton = view.viewWithTag(2) as? NSButton,
         let buttonUnitInch: NSButton = view.viewWithTag(3) as? NSButton,
         let buttonUnitCM: NSButton = view.viewWithTag(4) as? NSButton
      {
        buttonPhysical.isEnabled = false
        buttonPixels.isEnabled = false
        buttonUnitInch.isEnabled = false
        buttonUnitCM.isEnabled = false
        
        if let project = representedObject as? ProjectStructureNode
        {
          buttonPhysical.isEnabled = true
          buttonPixels.isEnabled = true
          buttonUnitInch.isEnabled = true
          buttonUnitCM.isEnabled = true
          
          
          switch(project.imageDimensions)
          {
          case ProjectStructureNode.Dimensions.physical:
            buttonPhysical.state = NSControl.StateValue.on
          case ProjectStructureNode.Dimensions.pixels:
            buttonPixels.state = NSControl.StateValue.on
          }
          
          switch(project.imageUnits)
          {
          case ProjectStructureNode.Units.inch:
            buttonUnitInch.state = NSControl.StateValue.on
          case ProjectStructureNode.Units.cm:
            buttonUnitCM.state = NSControl.StateValue.on
          }
        }
      }
    case "CameraMovieCell":
      if let framesPerSecondTextField: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        framesPerSecondTextField.isEditable = false
        if let project = representedObject as? ProjectStructureNode
        {
          framesPerSecondTextField.isEditable = true
          framesPerSecondTextField.integerValue = project.numberOfFramesPerSecond
        }
      }
      if let popUpbuttonMovieType: NSPopUpButton = view.viewWithTag(2) as? NSPopUpButton
      {
        popUpbuttonMovieType.isEnabled = false
        if let project = representedObject as? ProjectStructureNode
        {
          popUpbuttonMovieType.isEnabled = true
          popUpbuttonMovieType.selectItem(at: project.movieType.rawValue)
        }
      }
    default:
      break
    }
  }
  
  func setPropertiesBackgroundTableCells(on view: NSTableCellView, identifier: String)
  {
    switch(identifier)
    {
    case "CameraBackgroundCell":
      if let tabView: NSTabView = getSubviewsOfView(view).filter({$0.identifier?.rawValue == "BackgroundTabView"}).first as? NSTabView,
         let buttonColor: NSButton = view.viewWithTag(1) as? NSButton,
         let buttonLinearGradient: NSButton = view.viewWithTag(2) as? NSButton,
         let buttonRadialGradient: NSButton = view.viewWithTag(3) as? NSButton,
         let buttonImage: NSButton = view.viewWithTag(4) as? NSButton
      {
        if let project = representedObject as? ProjectStructureNode
        {
          switch(project.renderBackgroundType)
          {
          case RKBackgroundType.color:
            tabView.selectTabViewItem(at: 0)
            if let imageViewColor: NSColorWell = view.viewWithTag(10) as? NSColorWell
            {
              buttonColor.state = NSControl.StateValue.on
              imageViewColor.color = project.renderBackgroundColor
            }
          case RKBackgroundType.linearGradient:
            tabView.selectTabViewItem(at: 1)
            if let fromColorLinearGradient: NSColorWell = view.viewWithTag(20) as? NSColorWell,
              let toColorLinearGradient: NSColorWell = view.viewWithTag(21) as? NSColorWell,
              let sliderLinearGradient: NSSlider = view.viewWithTag(22) as? NSSlider,
              let textFieldLinearGradient: NSTextField = view.viewWithTag(23) as? NSTextField
            {
              buttonLinearGradient.state = NSControl.StateValue.on
              fromColorLinearGradient.color = project.backgroundLinearGradientFromColor
              toColorLinearGradient.color = project.backgroundLinearGradientToColor
              sliderLinearGradient.doubleValue = project.backgroundLinearGradientAngle
              textFieldLinearGradient.doubleValue = project.backgroundLinearGradientAngle
            }
          case RKBackgroundType.radialGradient:
            tabView.selectTabViewItem(at: 2)
            if let  fromColorRadialGradient: NSColorWell = view.viewWithTag(30) as? NSColorWell,
              let toColorRadialGradient: NSColorWell = view.viewWithTag(31) as? NSColorWell,
              let sliderRadialGradient: NSSlider = view.viewWithTag(32) as? NSSlider,
              let textFieldRadialGradient: NSTextField = view.viewWithTag(33) as? NSTextField
            {
              buttonRadialGradient.state = NSControl.StateValue.on
              fromColorRadialGradient.color = project.backgroundRadialGradientFromColor
              toColorRadialGradient.color = project.backgroundRadialGradientToColor
              sliderRadialGradient.doubleValue = project.backgroundRadialGradientRoundness
              textFieldRadialGradient.doubleValue = project.backgroundRadialGradientRoundness
            }
          case RKBackgroundType.image:
            tabView.selectTabViewItem(at: 3)
            if let imageView: NSButton = view.viewWithTag(40) as? NSButton
            {
              buttonImage.state = NSControl.StateValue.on
              if (project.renderBackgroundImage != nil),
                 let renderBackgroundImage = project.renderBackgroundImage
              {
                imageView.image = NSImage(cgImage: renderBackgroundImage, size: NSSize(width: 100.0, height: 100.0))
              }
              else
              {
                imageView.image = nil
              }
            }
          }
        }
      }
    default:
      break
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView?
  {
    if let rowView: CameraTableRowView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cameraTableRowView"), owner: self) as? CameraTableRowView
    {
      return rowView
    }
    return nil
  }
  
  // MARK: Update outlineView
  // =====================================================================
  
  func updateOutlineView(identifiers: [OutlineViewItem])
  {
    // Update at the next iteration (reloading could be in progress)
    DispatchQueue.main.async(execute: {[weak self] in
      for identifier in identifiers
      {
        if let row: Int = self?.cameraOutlineView?.row(forItem: identifier), row >= 0
        {
          self?.cameraOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
        }
      }
    })
  }
  
  // MARK: Camera actions
  // =====================================================================
  
  @IBAction func changedCameraDefaultViewPosition(_ sender: NSButtonCell)
  {
    let button: NSButtonCell = sender as NSButtonCell
    
    if let renderCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      switch(button.tag)
      {
      case 2:
        renderCamera.resetDirectionType = RKCamera.ResetDirectionType.minus_X
      case 3:
        renderCamera.resetDirectionType = RKCamera.ResetDirectionType.minus_Y
      case 4:
        renderCamera.resetDirectionType = RKCamera.ResetDirectionType.minus_Z
      case 5:
        renderCamera.resetDirectionType = RKCamera.ResetDirectionType.plus_X
      case 6:
        renderCamera.resetDirectionType = RKCamera.ResetDirectionType.plus_Y
      case 7:
        renderCamera.resetDirectionType = RKCamera.ResetDirectionType.plus_Z
      default:
        LogQueue.shared.error(destination: self.windowController, message: "Undefined camera-direction in 'changedCameraDefaultViewPosition'")
      }
      
      self.updateCameraViews()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  
  @IBAction func resetCamera(_ sender: NSButtonCell)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode,
      let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      // recompute bounding-box
      renderCamera.boundingBox = crystalProject.renderBoundingBox
      renderCamera.resetCameraToDirection()
      renderCamera.resetCameraDistance()
      
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      
      updateCameraViews()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
    }
  }
  
  @IBAction func switchCameraProjection(_ sender: NSButtonCell)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      switch(sender.tag)
      {
      case 9:
        renderCamera.setCameraToPerspective()
      case 10:
        renderCamera.setCameraToOrthographic()
      default:
        fatalError("Unknown camera projection")
      }
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
    }
  }
  
  @objc func updateCameraOrientationView()
  {
    self.windowController?.document?.updateChangeCount(.changeDone)
   
    if let row: Int = self.cameraOutlineView?.row(forItem: self.cameraOrientationCell), row >= 0,
       let outlineView: NSOutlineView = self.cameraOutlineView,
       let view: NSTableCellView = outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as?  NSTableCellView
    {
      setPropertiesCameraTableCells(on: view, identifier: "CameraOrientationCell")
      outlineView.setNeedsDisplay(outlineView.rect(ofRow: row))
    }
  }
 
  @objc func updateCameraViews()
  {
    self.windowController?.document?.updateChangeCount(.changeDone)
    
    if let row: Int = self.cameraOutlineView?.row(forItem: self.cameraRotationCell), row >= 0,
       let outlineView: NSOutlineView = self.cameraOutlineView,
       let view: NSTableCellView = outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as?  NSTableCellView
    {
      setPropertiesCameraTableCells(on: view, identifier: "CameraRotationCell")
      outlineView.setNeedsDisplay(outlineView.rect(ofRow: row))
    }
    
    if let row: Int = self.cameraOutlineView?.row(forItem: self.cameraViewMatrixCell), row >= 0,
       let outlineView: NSOutlineView = self.cameraOutlineView,
       let view: NSTableCellView = outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as?  NSTableCellView
    {
      setPropertiesCameraTableCells(on: view, identifier: "CameraViewMatrixCell")
      outlineView.setNeedsDisplay(outlineView.rect(ofRow: row))
    }
      
    if let row: Int = self.cameraOutlineView?.row(forItem: self.cameraVirtualPositionCell), row >= 0,
       let outlineView: NSOutlineView = self.cameraOutlineView,
       let view: NSTableCellView = outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as?  NSTableCellView
    {
      setPropertiesCameraTableCells(on: view, identifier: "CameraVirtualPositionCell")
        
      outlineView.setNeedsDisplay(outlineView.rect(ofRow: row))
    }
  }
  
  @IBAction func changedAngleOfView(_ sender: NSTextField)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      if let nf: NumberFormatter = sender.formatter as?  NumberFormatter,
        let number: NSNumber = nf.number(from: sender.stringValue)
      {
        let newValue: Double = number.doubleValue
        
        renderCamera.updateFieldOfView(newAngle: newValue * Double.pi / 180.0)
        self.windowController?.document?.updateChangeCount(.changeDone)
        
        self.windowController?.detailTabViewController?.renderViewController?.redraw()
      }
      else
      {
        let angleOfView = renderCamera.angleOfView
        sender.doubleValue = angleOfView
      }
    }
  }
  
  @IBAction func updateStepperAngleOfView(_ sender: NSStepper)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      var deltaValue: Double = Double(sender.intValue)
      if(deltaValue < 0 && Int(rint(renderCamera.angleOfView * 180.0 / Double.pi)) <= 10)
      {
        deltaValue /= 5.0
      }
      if(deltaValue > 0 && Int(rint(renderCamera.angleOfView * 180.0 / Double.pi)) < 10)
      {
        deltaValue /= 5.0
      }
    
      let newAngle: Int = Int(rint(renderCamera.angleOfView * 180.0 / Double.pi + deltaValue))
      if(newAngle >= 2)
      {
        renderCamera.updateFieldOfView(newAngle: Double(newAngle) * Double.pi / 180.0)
        
        self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.windowController?.detailTabViewController?.renderViewController?.redraw()
      }
      self.updateOutlineView(identifiers: [self.cameraOrientationCell])
    }

    sender.intValue = 0
  }

  
  
  @IBAction func changedResetPercentage(_ sender: NSTextField)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      let newValue: Double = sender.doubleValue
      
      renderCamera.resetPercentage = newValue
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  // MARK: Rotation
  // =====================================================================
  
  @IBAction func changedEulerAngleX(_ sender: NSTextField)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      if let nf: NumberFormatter = sender.formatter as?  NumberFormatter,
        let number: NSNumber = nf.number(from: sender.stringValue)
      {
        let EulerAngles: SIMD3<Double> = renderCamera.EulerAngles
        let newValue: Double = number.doubleValue
        
        renderCamera.worldRotation = simd_quatd(EulerAngles: SIMD3<Double>(x: newValue * Double.pi/180.0, y: EulerAngles.y, z: EulerAngles.z))
        
        self.windowController?.detailTabViewController?.renderViewController?.redraw()
        
        updateCameraViews()
        self.windowController?.document?.updateChangeCount(.changeDone)
      }
      else
      {
        sender.doubleValue = renderCamera.EulerAngles.x
      }
    }
  }
  
  @IBAction func changeRotationYawSlider(_ sender: NSSlider)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      let EulerAngles: SIMD3<Double> = renderCamera.EulerAngles
      let newValue: Double = sender.doubleValue
      
      renderCamera.worldRotation = simd_quatd(EulerAngles: SIMD3<Double>(x: newValue * Double.pi/180.0, y: EulerAngles.y, z: EulerAngles.z))
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      updateCameraViews()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func changedEulerAngleZ(_ sender: NSTextField)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      let EulerAngles: SIMD3<Double> = renderCamera.EulerAngles
      let newValue: Double = sender.doubleValue
      
      renderCamera.worldRotation = simd_quatd(EulerAngles: SIMD3<Double>(x: EulerAngles.x, y: EulerAngles.y, z: newValue * Double.pi/180.0))
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      updateCameraViews()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  
  @IBAction func changeRotationPitchSlider(_ sender: NSSlider)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      let EulerAngles: SIMD3<Double> = renderCamera.EulerAngles
      let newValue: Double = sender.doubleValue
      
      renderCamera.worldRotation = simd_quatd(EulerAngles: SIMD3<Double>(x: EulerAngles.x, y: EulerAngles.y, z: newValue * Double.pi/180.0))
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      updateCameraViews()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  
  @IBAction func changedEulerAngleY(_ sender: NSTextField)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      let EulerAngles: SIMD3<Double> = renderCamera.EulerAngles
      let newValue: Double = sender.doubleValue
      
      renderCamera.worldRotation = simd_quatd(EulerAngles: SIMD3<Double>(x: EulerAngles.x, y: newValue * Double.pi/180.0, z: EulerAngles.z))
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      updateCameraViews()
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func changeRotationRollSlider(_ sender: NSSlider)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      let EulerAngles: SIMD3<Double> = renderCamera.EulerAngles
      let newValue: Double = sender.doubleValue
      
      renderCamera.worldRotation = simd_quatd(EulerAngles: SIMD3<Double>(x: EulerAngles.x, y: newValue * Double.pi/180.0, z: EulerAngles.z))
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      updateCameraViews()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func rotateYawPlus(_ sender: NSButton)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      let rotation: simd_quatd = renderCamera.worldRotation
      let dq: simd_quatd = simd_quatd(yaw: renderCamera.rotationDelta)
      
      renderCamera.worldRotation = simd_mul(rotation, dq)
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      updateCameraViews()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func rotateYawMinus(_ sender: NSButton)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      let rotation: simd_quatd = renderCamera.worldRotation
      let dq: simd_quatd = simd_quatd(yaw: -renderCamera.rotationDelta)
      
      (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.worldRotation = simd_mul(rotation, dq)
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      updateCameraViews()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  
  
  @IBAction func rotatePitchPlus(_ sender: NSButton)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      let rotation: simd_quatd = renderCamera.worldRotation
      let dq: simd_quatd = simd_quatd(pitch: renderCamera.rotationDelta)
      
      (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.worldRotation = simd_mul(rotation, dq)
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      updateCameraViews()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func rotatePitchMinus(_ sender: NSButton)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      let rotation: simd_quatd = renderCamera.worldRotation
      let dq: simd_quatd = simd_quatd(pitch: -renderCamera.rotationDelta)
      
      (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.worldRotation = simd_mul(rotation, dq)
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      updateCameraViews()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  
  @IBAction func rotateRollPlus(_ sender: NSButton)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      let rotation: simd_quatd = renderCamera.worldRotation
      let dq: simd_quatd = simd_quatd(roll: renderCamera.rotationDelta)
      
      (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.worldRotation = simd_mul(rotation, dq)
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      updateCameraViews()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func rotateRollMinus(_ sender: NSButton)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      let rotation: simd_quatd = renderCamera.worldRotation
      let dq: simd_quatd = simd_quatd(roll: -renderCamera.rotationDelta)
      
      (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.worldRotation = simd_mul(rotation, dq)
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      updateCameraViews()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  @IBAction func changedRotationAngle(_ sender: NSTextField)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      let newValue: Double = sender.doubleValue
      
      renderCamera.rotationDelta = newValue
      
      self.updateOutlineView(identifiers: [self.cameraRotationCell])
      
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  // MARK: Selection
  // =====================================================================
  
  
  @IBAction func changeBloomLevelField(_ sender: NSTextField)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      renderCamera.bloomLevel = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraSelectionCell])
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
    }
  }
  
  @IBAction func changeBloomLevel(_ sender: NSSlider)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      renderCamera.bloomLevel  = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraSelectionCell])
      
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
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
    }
  }
  
  // MARK: Global axes
  // =====================================================================
  
  @IBAction func changeAxesPosition(_ sender: NSPopUpButton)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode,
       let position: RKGlobalAxes.Position = RKGlobalAxes.Position(rawValue: sender.indexOfSelectedItem)
    {
      crystalProject.renderAxes.position = position
      
      self.updateOutlineView(identifiers: [self.cameraAxesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAxesStyle(_ sender: NSPopUpButton)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode,
       let style: RKGlobalAxes.Style = RKGlobalAxes.Style(rawValue: sender.indexOfSelectedItem)
    {
      crystalProject.renderAxes.style = style
      crystalProject.renderAxes.setStyle(style: style)
      
      self.updateOutlineView(identifiers: [self.cameraAxesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAxesSize(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.sizeScreenFraction = sender.doubleValue / 100.0
      
      self.updateOutlineView(identifiers: [self.cameraAxesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAxesBorderOffset(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.borderOffsetScreenFraction = sender.doubleValue / 100.0
    
      self.updateOutlineView(identifiers: [self.cameraAxesCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAxesBackgroundStyle(_ sender: NSPopUpButton)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode,
       let axesBackgroundStyle = RKGlobalAxes.BackgroundStyle(rawValue: sender.indexOfSelectedItem)
    {
      crystals.renderAxes.axesBackgroundStyle = axesBackgroundStyle
     
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func setAxesBackgroundColor(_ sender: NSColorWell)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystals.renderAxes.axesBackgroundColor = sender.color
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeBackgroundAdditionalSize(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.axesBackgroundAdditionalSize = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraAxesBackgroundCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperBackgroundAdditionalSize(_ sender: NSStepper)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.axesBackgroundAdditionalSize += sender.doubleValue
      sender.doubleValue = 0.0
      
      self.updateOutlineView(identifiers: [self.cameraAxesBackgroundCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTextScalingAxesX(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textScale.x = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperTextScalingAxesX(_ sender: NSStepper)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textScale.x += sender.doubleValue
      sender.doubleValue = 0.0
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTextScalingAxesY(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textScale.y = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperTextScalingAxesY(_ sender: NSStepper)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textScale.y += sender.doubleValue
      sender.doubleValue = 0.0
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTextScalingAxesZ(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textScale.z = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperTextScalingAxesZ(_ sender: NSStepper)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textScale.z += sender.doubleValue
      sender.doubleValue = 0.0
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTextOffsetXAxesX(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementX.x = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperTextOffsetXAxesX(_ sender: NSStepper)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementX.x += sender.doubleValue
      sender.doubleValue = 0.0
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTextOffsetXAxesY(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementX.y = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperTextOffsetXAxesY(_ sender: NSStepper)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementX.y += sender.doubleValue
      sender.doubleValue = 0.0
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTextOffsetXAxesZ(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementX.z = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperTextOffsetXAxesZ(_ sender: NSStepper)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementX.z += sender.doubleValue
      sender.doubleValue = 0.0
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTextOffsetYAxesX(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementY.x = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperTextOffsetYAxesX(_ sender: NSStepper)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementY.x += sender.doubleValue
      sender.doubleValue = 0.0
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTextOffsetYAxesY(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementY.y = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperTextOffsetYAxesY(_ sender: NSStepper)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementY.y += sender.doubleValue
      sender.doubleValue = 0.0
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTextOffsetYAxesZ(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementY.z = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperTextOffsetYAxesZ(_ sender: NSStepper)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementY.z += sender.doubleValue
      sender.doubleValue = 0.0
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTextOffsetZAxesX(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementZ.x = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperTextOffsetZAxesX(_ sender: NSStepper)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementZ.x += sender.doubleValue
      sender.doubleValue = 0.0
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTextOffsetZAxesY(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementZ.y = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperTextOffsetZAxesY(_ sender: NSStepper)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementZ.y += sender.doubleValue
      sender.doubleValue = 0.0
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeTextOffsetZAxesZ(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementZ.z = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperTextOffsetZAxesZ(_ sender: NSStepper)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderAxes.textDisplacementZ.z += sender.doubleValue
      sender.doubleValue = 0.0
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
            
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func setAxesTextColorX(_ sender: NSColorWell)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystals.renderAxes.textColorX = sender.color
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func setAxesTextColorY(_ sender: NSColorWell)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystals.renderAxes.textColorY = sender.color
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func setAxesTextColorZ(_ sender: NSColorWell)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystals.renderAxes.textColorZ = sender.color
      
      self.updateOutlineView(identifiers: [self.cameraAxesTextCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadGlobalAxesSystem()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  // MARK: Global light
  // =====================================================================
  
  // The light controls all live in per-light cells whose tags are offset by a hundred times the light
  // index, so each handler recovers its light from the tag rather than needing its own outlet.

  @IBAction func changeDiffuseTextField(_ sender: NSTextField)
  {
    self.updateLight(forTag: sender.tag) { $0.diffuseIntensity = min(max(sender.doubleValue, 0.0), 1.0) }
  }

  @IBAction func changeDiffuseIntensitySlider(_ sender: NSSlider)
  {
    self.updateLight(forTag: sender.tag) { $0.diffuseIntensity = sender.doubleValue }
  }

  @IBAction func changeDiffuseColor(_ sender: NSColorWell)
  {
    self.updateLight(forTag: sender.tag) { $0.diffuse = sender.color }
  }

  @IBAction func changeSpecularTextField(_ sender: NSTextField)
  {
    self.updateLight(forTag: sender.tag) { $0.specularIntensity = min(max(sender.doubleValue, 0.0), 1.0) }
  }

  @IBAction func changeSpecularIntensitySlider(_ sender: NSSlider)
  {
    self.updateLight(forTag: sender.tag) { $0.specularIntensity = sender.doubleValue }
  }

  @IBAction func changeSpecularColor(_ sender: NSColorWell)
  {
    self.updateLight(forTag: sender.tag) { $0.specular = sender.color }
  }

  @IBAction func changeShininessSlider(_ sender: NSSlider)
  {
    self.updateLight(forTag: sender.tag) { $0.shininess = sender.doubleValue }
  }

  @IBAction func changeShininessTextField(_ sender: NSTextField)
  {
    self.updateLight(forTag: sender.tag) { $0.shininess = min(max(sender.doubleValue, 0.1), 128.0) }
  }
  
 
  
    
  
  // MARK: Background actions
  // =====================================================================
  
  @IBAction func setBackground(_ sender: NSButtonCell)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      switch(sender.tag)
      {
      case 1:
        crystals.renderBackgroundType = .color
      case 2:
        crystals.renderBackgroundType = .linearGradient
      case 3:
        crystals.renderBackgroundType = .radialGradient
      case 4:
        crystals.renderBackgroundType = .image
      default:
        fatalError("Unknown background option")
      }
      
      crystals.renderBackgroundCachedImage = crystals.drawGradientCGImage()
      
      self.updateOutlineView(identifiers: [self.cameraBackgroundCell])
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadBackgroundImage()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
    }
  }
  
  @IBAction func setBackgroundColor(_ sender: NSColorWell)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystals.renderBackgroundColor = sender.color
      crystals.renderBackgroundCachedImage = crystals.drawGradientCGImage()
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadBackgroundImage()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func setBackgroundLinearGradientFromColor(_ sender: NSColorWell)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystals.backgroundLinearGradientFromColor = sender.color
      crystals.renderBackgroundCachedImage = crystals.drawGradientCGImage()
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadBackgroundImage()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func setBackgroundLinearGradientToColor(_ sender: NSColorWell)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystals.backgroundLinearGradientToColor = sender.color
      crystals.renderBackgroundCachedImage = crystals.drawGradientCGImage()
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadBackgroundImage()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func setBackgroundLinearGradientAngle(_ sender: NSSlider)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystals.backgroundLinearGradientAngle = sender.doubleValue
      crystals.renderBackgroundCachedImage = crystals.drawGradientCGImage()
      
      self.updateOutlineView(identifiers: [self.cameraBackgroundCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadBackgroundImage()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func setBackgroundLinearGradientAngleText(_ sender: NSTextField)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      if (sender.doubleValue >= 0.0 && sender.doubleValue <= 360.0)
      {
        crystals.backgroundLinearGradientAngle = max(sender.doubleValue,0.0001)
        crystals.renderBackgroundCachedImage = crystals.drawGradientCGImage()
        
        self.updateOutlineView(identifiers: [self.cameraBackgroundCell])
        
        self.windowController?.detailTabViewController?.renderViewController?.reloadBackgroundImage()
        self.windowController?.detailTabViewController?.renderViewController?.redraw()
        
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
      }
      else
      {
        // restore proper textfield-value
        sender.doubleValue = crystals.backgroundLinearGradientAngle
      }
    }
  }
  
  
  
  @IBAction func setBackgroundRadialGradientFromColor(_ sender: NSColorWell)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystals.backgroundRadialGradientFromColor = sender.color
      crystals.renderBackgroundCachedImage = crystals.drawGradientCGImage()
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadBackgroundImage()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func setBackgroundRadialGradientToColor(_ sender: NSColorWell)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystals.backgroundRadialGradientToColor = sender.color
      crystals.renderBackgroundCachedImage = crystals.drawGradientCGImage()
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadBackgroundImage()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func setBackgroundRadialGradientRoundness(_ sender: NSSlider)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystals.backgroundRadialGradientRoundness = sender.doubleValue
      crystals.renderBackgroundCachedImage = crystals.drawGradientCGImage()
      
      self.updateOutlineView(identifiers: [self.cameraBackgroundCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadBackgroundImage()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func setBackgroundRadialGradientRoundnessText(_ sender: NSTextField)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      if (sender.doubleValue >= 0.0 && sender.doubleValue < 4.0)
      {
        crystals.backgroundRadialGradientRoundness = max(sender.doubleValue,0.0001)
        crystals.renderBackgroundCachedImage = crystals.drawGradientCGImage()
        
        self.updateOutlineView(identifiers: [self.cameraBackgroundCell])
        
        self.windowController?.detailTabViewController?.renderViewController?.reloadBackgroundImage()
        self.windowController?.detailTabViewController?.renderViewController?.redraw()
        
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
      }
      else
      {
        // restore proper textfield-value
        sender.doubleValue = crystals.backgroundRadialGradientRoundness
      }
    }
  }
  
  
  
  @IBAction func setBackgroundImage(_ sender: NSButton)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      
      let openPanel: NSOpenPanel = NSOpenPanel()
      openPanel.canChooseDirectories = false
      openPanel.allowsMultipleSelection = false
      openPanel.canChooseFiles = true
      openPanel.allowedFileTypes = NSImage.imageTypes
      openPanel.isReleasedWhenClosed = true
      
      openPanel.begin {(result) -> Void in
        
        if result == NSApplication.ModalResponse.OK
        {
          // make imageSource of selected picture
          if let url = openPanel.url,
             let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
             let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
          {
            // set the background of the project
            crystals.renderBackgroundImage = image
            crystals.renderBackgroundCachedImage = image
            
            // show the picture in the NSButton
            sender.image = NSImage(cgImage: image, size: NSSize(width: 128.0, height: 128.0))
            
            self.windowController?.detailTabViewController?.renderViewController?.reloadBackgroundImage()
            self.windowController?.detailTabViewController?.renderViewController?.redraw()
            
            self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
            self.windowController?.document?.updateChangeCount(.changeDone)
            self.proxyProject?.representedObject.isEdited = true
          }
          else
          {
            LogQueue.shared.error(destination: self.windowController, message: "Unable to use selected picture as background")
          }
        }
      }
    }
  }
  
  
  @IBAction func clearBackgroundImage(_ sender: NSButton)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystals.renderBackgroundImage = nil
      crystals.renderBackgroundType = .color
      crystals.renderBackgroundCachedImage = crystals.drawGradientCGImage()
        
      self.updateOutlineView(identifiers: [self.cameraBackgroundCell])
        
      self.windowController?.detailTabViewController?.renderViewController?.reloadBackgroundImage()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
        
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  // MARK: Raytracing actions
  // =====================================================================

  /// Selects how the render view draws. These are application preferences, not project properties,
  /// so they are not written to the document.
  @IBAction func setInteractiveRayTracing(_ sender: NSButton)
  {
    RKRenderSettings.shared.interactiveRenderMode = (sender.state == NSControl.StateValue.on) ? RKRenderMode.rayTracing : RKRenderMode.rasterization

    // the sample counts follow the checkbox, and the render view redraws on the notification the
    // setter posts
    self.updateOutlineView(identifiers: [self.cameraRaytracingCell])

    self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
  }

  @IBAction func setInteractiveSampleCount(_ sender: NSTextField)
  {
    RKRenderSettings.shared.interactiveSampleCount = sender.integerValue

    // reflect the clamped value back
    sender.integerValue = RKRenderSettings.shared.interactiveSampleCount

    self.windowController?.detailTabViewController?.renderViewController?.redraw()
    self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
  }

  @IBAction func setInteractiveRotatingSampleCount(_ sender: NSTextField)
  {
    RKRenderSettings.shared.interactiveRotatingSampleCount = sender.integerValue

    sender.integerValue = RKRenderSettings.shared.interactiveRotatingSampleCount

    self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
  }

  @IBAction func setInteractiveMaximumBounces(_ sender: NSTextField)
  {
    RKRenderSettings.shared.interactiveMaximumBounces = sender.integerValue

    sender.integerValue = RKRenderSettings.shared.interactiveMaximumBounces

    self.windowController?.detailTabViewController?.renderViewController?.redraw()
    self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
  }

  /// Whether the render view traces shadows. A machine setting rather than a project one, the scene's
  /// own Shadows setting being what an export obeys, so nothing here is written to the document.
  @IBAction func setInteractiveShadows(_ sender: NSButton)
  {
    RKRenderSettings.shared.interactiveShadows = (sender.state == NSControl.StateValue.on)

    self.windowController?.detailTabViewController?.renderViewController?.redraw()
    self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
  }


  // MARK: Picture actions
  // =====================================================================
  
  @objc func updateAspectRatioView()
  {
    self.updateOutlineView(identifiers: [self.cameraPictureCell])
  }
  
  /// Selects how exported pictures and movies are rendered. Unlike the interactive settings, this is
  /// a property of the project, so that a document keeps the look it was authored with.
  @IBAction func setPictureRayTracing(_ sender: NSButton)
  {
    if let project: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      project.renderPictureRayTracing = (sender.state == NSControl.StateValue.on)

      // the remaining fields follow the checkbox
      self.updateOutlineView(identifiers: [self.cameraPictureRayTracingCell])

      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }

  @IBAction func setPictureSampleCount(_ sender: NSTextField)
  {
    if let project: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      project.renderPictureSampleCount = sender.integerValue

      // reflect the clamped value back
      sender.integerValue = project.picturePathTracerSettings.sampleCount

      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }

  @IBAction func setPictureMaximumBounces(_ sender: NSTextField)
  {
    if let project: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      project.renderPictureMaximumBounces = sender.integerValue

      sender.integerValue = project.picturePathTracerSettings.maximumBounces

      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }

  // MARK: Light actions
  // =====================================================================

  @IBAction func setLightStyle(_ sender: NSPopUpButton)
  {
    guard let project: ProjectStructureNode = self.representedObject as? ProjectStructureNode,
          let style: RKLightStyle = RKLightStyle.presets.first(where: { $0.displayName == sender.titleOfSelectedItem })
    else
    {
      // the Custom entry stands for the lights that are already there, so choosing it changes nothing
      self.updateOutlineView(identifiers: [self.cameraLightStyleCell])
      return
    }

    project.setLightStyle(style)

    // a style rewrites every light and the occlusion strength, so all of the cells are stale
    self.updateOutlineView(identifiers: [self.cameraLightStyleCell] + self.cameraLightCells + [self.cameraLightsCell])

    // occlusion strength reaches the rasterizer through the structure uniforms rather than the light ones
    self.windowController?.detailTabViewController?.renderViewController?.updateLightUniforms()
    self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    self.windowController?.detailTabViewController?.renderViewController?.redraw()

    self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
    self.windowController?.document?.updateChangeCount(.changeDone)
    self.proxyProject?.representedObject.isEdited = true
  }

  @IBAction func toggleLight(_ sender: NSButton)
  {
    self.updateLight(forTag: sender.tag)
    {
      $0.isEnabled = (sender.state == NSControl.StateValue.on)
    }
  }

  @IBAction func setLightType(_ sender: NSPopUpButton)
  {
    self.updateLight(forTag: sender.tag)
    {
      if let type: RKLightType = RKLightType(rawValue: sender.indexOfSelectedItem)
      {
        $0.type = type
      }
    }
  }

  private func updateLight(forTag tag: Int, _ change: (inout RKRenderLight) -> ())
  {
    let index: Int = tag / 100

    if let project: ProjectStructureNode = self.representedObject as? ProjectStructureNode, index >= 0, index < project.renderLights.count, index < self.cameraLightCells.count
    {
      change(&project.renderLights[index])
      project.recheckLightStyle()

      // enabling a light changes which of its own controls are usable, so the whole cell is refreshed
      self.updateOutlineView(identifiers: [self.cameraLightCells[index], self.cameraLightStyleCell])

      self.windowController?.detailTabViewController?.renderViewController?.updateLightUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()

      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }

  // MARK: Scene ambient actions
  // =====================================================================

  /// Ambient describes the environment, not a lamp, so it is edited once for the scene. Keeping it out of
  /// the lights means the ambient level no longer rises and falls with how many of them happen to be on,
  /// and a material lit by ambient alone, as the Fancy representation style is, survives every light being
  /// switched off.
  @IBAction func changeSceneAmbientIntensityTextField(_ sender: NSTextField)
  {
    self.applySceneAmbient(intensity: sender.doubleValue, color: nil)
  }

  @IBAction func changeSceneAmbientIntensitySlider(_ sender: NSSlider)
  {
    self.applySceneAmbient(intensity: sender.doubleValue, color: nil)
  }

  @IBAction func changeSceneAmbientColor(_ sender: NSColorWell)
  {
    self.applySceneAmbient(intensity: nil, color: sender.color)
  }

  private func applySceneAmbient(intensity: Double?, color: NSColor?)
  {
    if let project: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      if let intensity: Double = intensity
      {
        project.renderSceneAmbientIntensity = min(max(intensity, 0.0), 1.0)
      }
      if let color: NSColor = color
      {
        project.renderSceneAmbientColor = color
      }
      project.recheckLightStyle()

      self.windowController?.detailTabViewController?.renderViewController?.updateLightUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()

      self.updateOutlineView(identifiers: [self.cameraLightsCell, self.cameraLightStyleCell])
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }

  // MARK: Ambient occlusion actions
  // =====================================================================

  /// One value, shared by the rasterizer and the path tracer and by both the view and exports, so it
  /// lives with the lights rather than under either renderer.
  @IBAction func changeAmbientOcclusionStrengthTextField(_ sender: NSTextField)
  {
    self.applyAmbientOcclusionStrength(sender.doubleValue)
  }

  @IBAction func changeAmbientOcclusionStrengthSlider(_ sender: NSSlider)
  {
    self.applyAmbientOcclusionStrength(sender.doubleValue)
  }

  /// Shadows are a property of the scene rather than of the lighting rig, so unlike the occlusion
  /// strength beside it this does not make the light style Custom.
  @IBAction func toggleShadows(_ sender: NSButton)
  {
    if let project: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      project.renderShadows = (sender.state == NSControl.StateValue.on)

      self.windowController?.detailTabViewController?.renderViewController?.redraw()

      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }

  private func applyAmbientOcclusionStrength(_ strength: Double)
  {
    if let project: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      project.renderAmbientOcclusionStrength = min(max(strength, 0.0), 1.0)
      project.recheckLightStyle()

      // the rasterizer reads this through the structure uniforms, so they have to be rebuilt rather
      // than just marking the view dirty
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()

      self.updateOutlineView(identifiers: [self.cameraLightsCell, self.cameraLightStyleCell])
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }

  @IBAction func setPictureEditDimensions(_ sender: NSButtonCell)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      switch(sender.tag)
      {
      case 1:
        crystals.imageDimensions = ProjectStructureNode.Dimensions.physical
      case 2:
        crystals.imageDimensions = ProjectStructureNode.Dimensions.pixels
      default:
        fatalError("Unknown dimension option")
      }
      
      self.updateOutlineView(identifiers: [self.cameraPictureCell])
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func setPictureUnits(_ sender: NSButtonCell)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      switch(sender.tag)
      {
      case 3:
        crystals.imageUnits = ProjectStructureNode.Units.inch
      case 4:
        crystals.imageUnits = ProjectStructureNode.Units.cm
      default:
        fatalError("Unknown unit option")
      }
      
      self.updateOutlineView(identifiers: [self.cameraPictureCell])
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func setPicturePhysicalSizeX(_ sender: NSTextField)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      if (sender.doubleValue >= 0)
      {
        switch(crystals.imageUnits)
        {
        case .inch:
          crystals.renderImagePhysicalSizeInInches = sender.doubleValue
        case .cm:
          crystals.renderImagePhysicalSizeInInches = sender.doubleValue / 2.54
        }
        crystals.renderImageNumberOfPixels =  Int(rint(crystals.ImageDotsPerInchValue * Double(crystals.renderImagePhysicalSizeInInches)))
        
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
      }
      else
      {
        // restore proper textfield-value
        sender.doubleValue = Double(crystals.renderImagePhysicalSizeInInches)
      }
      
      self.updateOutlineView(identifiers: [self.cameraPictureCell])
    }
  }
  
  
  @IBAction func setPictureNumberOfPixelsX(_ sender: NSTextField)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      if (sender.doubleValue >= 0)
      {
        crystals.renderImageNumberOfPixels = Int(sender.doubleValue)
        
        crystals.renderImagePhysicalSizeInInches =  Double(crystals.renderImageNumberOfPixels)/Double(crystals.ImageDotsPerInchValue)
        
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
      }
      else
      {
        // restore proper textfield-value
        sender.doubleValue = Double(crystals.renderImageNumberOfPixels)
      }
      
      self.updateOutlineView(identifiers: [self.cameraPictureCell])
    }
  }
  
  
  @IBAction func changeDPI(_ sender: NSPopUpButton)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode,
       let imageDPI = ProjectStructureNode.DPI(rawValue: sender.indexOfSelectedItem)
    {
      crystals.imageDPI = imageDPI
      
      switch(crystals.imageDimensions)
      {
      case ProjectStructureNode.Dimensions.physical:
        crystals.renderImageNumberOfPixels =  Int(crystals.ImageDotsPerInchValue * Double(crystals.renderImagePhysicalSizeInInches))
        
        
      case ProjectStructureNode.Dimensions.pixels:
        crystals.renderImagePhysicalSizeInInches =  Double(crystals.renderImageNumberOfPixels)/Double(crystals.ImageDotsPerInchValue)
      }
      
      self.updateOutlineView(identifiers: [self.cameraPictureCell])
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeOfflineImageQuality(_ sender: NSPopUpButton)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode,
       let renderImageQuality = RKImageQuality(rawValue: sender.indexOfSelectedItem)
    {
      crystals.renderImageQuality = renderImageQuality
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func makePicture(_ sender: NSButtonCell)
  {
    self.windowController?.detailTabViewController?.renderViewController?.makePicture()
  }
  
  // MARK: Movie actions
  // =====================================================================
  
  @IBAction func setNumberOfFramesPerSeconds(_ sender: NSTextField)
  {
    if let project: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      if (sender.integerValue > 0)
      {
        project.numberOfFramesPerSecond = Int(sender.doubleValue)
        
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
        
        if (self.movieTimer != nil)
        {
          self.movieTimer?.cancel()
          self.movieTimer = DispatchSource.makeTimerSource()
          let timeInterval: Double = 1.0 / Double(project.numberOfFramesPerSecond)
          self.movieTimer?.schedule(wallDeadline: DispatchWallTime.now(), repeating: timeInterval, leeway: .seconds(1))
            
          self.movieTimer?.setEventHandler(handler: {
            self.increaseCurrentFrame()
            self.movieTimer?.resume()
          })
        }
      }
      else
      {
        // restore proper textfield-value
        sender.integerValue = project.numberOfFramesPerSecond
      }
    }
  }
  
  @IBAction func changeMovieType(_ sender: NSPopUpButton)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode,
       let movieType: ProjectStructureNode.MovieType = ProjectStructureNode.MovieType(rawValue: sender.indexOfSelectedItem)
    {
      crystalProject.movieType = movieType
      
      self.updateOutlineView(identifiers: [self.cameraMovieCell])
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  
  @IBAction func makeMovie(_ sender: NSButtonCell)
  {
    self.windowController?.detailTabViewController?.renderViewController?.makeMovie()
  }
  
  @IBAction func changeMovieIndex(_ sender: NSSlider)
  {
    if let projectStructureNode: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      let newValue: Int = sender.integerValue
//crystalProject.sceneList.movieIndex = newValue
      
      if let movie: Movie = projectStructureNode.sceneList.selectedScene?.selectedMovie
      {
        // perhaps change to increase all frames
        //crystalProject.sceneList.setFrameIndexForAllMovies(to: newValue)
        movie.selectedFrame = movie.frames[newValue]
      }
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      //windowController?.frameListViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
    }
  }
  
  
  func increaseCurrentFrame()
  {
    DispatchQueue.main.async(execute: {
    if let project: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      project.sceneList.advanceAllMovieFrames()
      
      //self.windowController?.frameListViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
    }
    })
  }
  
  
  
  
  @objc func updateCameraMovieCell()
  {
    self.updateOutlineView(identifiers: [self.cameraMovieCell])
  }

  
  
  
  @IBAction func startMovieMove(_ sender: NSButtonCell)
  {
    if let _: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      
      if (sender.state == NSControl.StateValue.on)
      {
        movieTimer = DispatchSource.makeTimerSource()
        //let timeInterval: Double = 1.0 / Double(project.sceneList.numberOfFramesPerSecond)
        let timeInterval: Double = 1.0
        movieTimer?.schedule(wallDeadline: DispatchWallTime.now() + timeInterval, repeating: timeInterval)
        
        movieTimer?.setEventHandler(handler: {
          //DispatchQueue.main.async(execute: {
            self.increaseCurrentFrame()
            self.updateCameraMovieCell()
         // })
        })
        
        movieTimer?.resume()
      }
      else
      {
        movieTimer?.cancel()
        movieTimer?.setEventHandler(handler: nil)
        //DispatchQueue.main.async(execute: {
          self.movieTimer = nil
          self.updateCameraMovieCell()
        //})
      }
    }
  }
  
  
  
  @IBAction func setMovieToBeginning(sender: NSButtonCell)
  {
    if let project: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      project.sceneList.setAllMovieFramesToBeginning()
      
      updateCameraMovieCell()
      
      //windowController?.frameListViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.reloadRenderData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
    }
  }
  
  @IBAction func setMovieToEnd(_ sender: NSButtonCell)
  {
    if let project: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      project.sceneList.setAllMovieFramesToBeginning()
      
      //windowController?.frameListViewController?.reloadData()
      updateCameraMovieCell()
      self.windowController?.detailTabViewController?.renderViewController?.reloadRenderData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
    }
  }
}
