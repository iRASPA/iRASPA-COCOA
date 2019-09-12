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
//

import Cocoa
import simd
import LogViewKit
import RenderKit
import iRASPAKit
import MathKit
import Dispatch



class StructureCameraDetailViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource, WindowControllerConsumer, ProjectConsumer
{
  weak var windowController: iRASPAWindowController?
  
  @IBOutlet private weak var cameraOutlineView: NSStaticViewBasedOutlineView?
  
  var list: [NSDictionary] = []
  var heights: [String : CGFloat] = [:]
  let cameraCell: [NSString : AnyObject] = [NSString(string: "cellType") : NSString(string: "CameraCell")]
  let cameraViewMatrixCell: [NSString : AnyObject] = [NSString(string: "cellType") : NSString(string: "CameraViewMatrixCell")]
  let cameraSelectionCell: [NSString : AnyObject] = [NSString(string: "cellType") : NSString(string: "CameraSelectionCell")]
  let cameraLightsCell: [NSString : AnyObject] = [NSString(string: "cellType") : NSString(string: "CameraLightsCell")]
  let cameraPictureCell: [NSString : AnyObject] = [NSString(string: "cellType") : NSString(string: "CameraPictureCell")]
  let cameraMovieCell: [NSString : AnyObject] = [NSString(string: "cellType") : NSString(string: "CameraMovieCell")]
  let cameraBackgroundCell: [NSString : AnyObject] = [NSString(string: "cellType") : NSString(string: "CameraBackgroundCell")]
  
  var movieTimer: DispatchSourceTimer? = nil
  
  // MARK: protocol ProjectConsumer
  // ===============================================================================================================================
  
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
    if #available(OSX 10.12, *)
    {
      self.cameraOutlineView?.stronglyReferencesItems = false
    }
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    let cameraDictionary: NSDictionary = ["cellType":"CameraGroup" as AnyObject,"children": [cameraCell, cameraViewMatrixCell] as AnyObject]
    let cameraSelectionDictionary: NSDictionary = ["cellType":"CameraSelectionGroup" as AnyObject,"children": [cameraSelectionCell] as AnyObject]
    let cameraLightsDictionary: NSDictionary = ["cellType":"CameraLightsGroup" as AnyObject,"children": [cameraLightsCell] as AnyObject]
    let cameraPictureDictionary: NSDictionary = ["cellType":"CameraPictureGroup" as AnyObject,"children": [cameraPictureCell, cameraMovieCell] as AnyObject]
    let cameraBackgroundDictionary: NSDictionary = ["cellType":"CameraBackgroundGroup" as AnyObject,"children": [cameraBackgroundCell] as AnyObject]
    
    self.list = [cameraDictionary,cameraSelectionDictionary,cameraLightsDictionary,cameraPictureDictionary,cameraBackgroundDictionary]
    
    self.heights =
    [
      "CameraGroup" : 17.0,
      "CameraCell" : 222.0,
      "CameraViewMatrixCell" : 380.0,
      "CameraSelectionGroup" : 17.0,
      "CameraSelectionCell" : 30.0,
      "CameraLightsGroup" : 17.0,
      "CameraLightsCell" : 141.0,
      "CameraBackgroundGroup": 17.0,
      "CameraBackgroundCell" : 102.0,
      "CameraPictureGroup" : 17,
      "CameraPictureCell" : 194.0,
      "CameraMovieCell" : 38.0
    ]
  }
  
  override func viewWillAppear()
  {
    super.viewWillAppear()
    self.cameraOutlineView?.reloadData()
  }
  
  override func viewDidAppear()
  {
    super.viewDidAppear()
    
    // update the aspect-ratio data in the Camera-views when the view of the renderViewConroller changes
    NotificationCenter.default.addObserver(self, selector: #selector(StructureCameraDetailViewController.updateAspectRatioView), name: NSView.boundsDidChangeNotification, object: self.windowController?.detailTabViewController?.renderViewController)
    
    // update the camera view-matrix data in the Camera-views when the camera direction or distance changes
    NotificationCenter.default.addObserver(self, selector: #selector(StructureCameraDetailViewController.updateCameraViewMatrix), name: NSNotification.Name(rawValue: NotificationStrings.CameraDidChangeNotification), object: windowController)
  }
  
  // the windowController still exists when the view is there
  override func viewWillDisappear()
  {
    super.viewWillDisappear()
    
    NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: self.windowController?.detailTabViewController?.renderViewController)

    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationStrings.CameraDidChangeNotification), object: windowController)
  }
  
  
  
  func reloadData()
  {
    self.cameraOutlineView?.reloadData()
  }
  
  
  
  // MARK: NSTableView Delegate Methods
  // ===============================================================================================================================
  
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
      
      //return [AnyObject]
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
  
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
  {
    if let string: String = (item as! NSDictionary)["cellType"] as? String,
      let view: NSTableCellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: string), owner: self) as? NSTableCellView
    {
      switch(string)
      {
      case "CameraCell":
        if let buttonMinusX: NSButton = view.viewWithTag(10) as? NSButton,
          let buttonMinusY: NSButton = view.viewWithTag(11) as? NSButton,
          let buttonMinusZ: NSButton = view.viewWithTag(12) as? NSButton,
          let buttonPlusX: NSButton = view.viewWithTag(13) as? NSButton,
          let buttonPlusY: NSButton = view.viewWithTag(14) as? NSButton,
          let buttonPlusZ: NSButton = view.viewWithTag(15) as? NSButton
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
        
        if let buttonPerspective: NSButton = view.viewWithTag(20) as? NSButton,
          let buttonOrthogonal: NSButton = view.viewWithTag(21) as? NSButton
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
        
        if let textFieldResetPercentage: NSTextField = view.viewWithTag(50) as? NSTextField,
          let textFieldFieldOfField: NSTextField = view.viewWithTag(40) as? NSTextField,
          let textFieldCenterOfSceneX: NSTextField = view.viewWithTag(41) as? NSTextField,
          let textFieldCenterOfSceneY: NSTextField = view.viewWithTag(42) as? NSTextField,
          let textFieldCenterOfSceneZ: NSTextField = view.viewWithTag(43) as? NSTextField
        {
          textFieldResetPercentage.isEnabled = false
          textFieldFieldOfField.isEnabled = false
          textFieldCenterOfSceneX.isEnabled = false
          textFieldCenterOfSceneY.isEnabled = false
          textFieldCenterOfSceneZ.isEnabled = false
          if let camera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
          {
            textFieldResetPercentage.isEnabled = true
            textFieldFieldOfField.isEnabled = true
            textFieldCenterOfSceneX.isEnabled = true
            textFieldCenterOfSceneY.isEnabled = true
            textFieldCenterOfSceneZ.isEnabled = true
            textFieldResetPercentage.doubleValue = camera.resetPercentage
            textFieldFieldOfField.doubleValue = camera.angleOfView * 180.0 / Double.pi
            textFieldCenterOfSceneX.doubleValue = camera.centerOfScene.x
            textFieldCenterOfSceneY.doubleValue = camera.centerOfScene.y
            textFieldCenterOfSceneZ.doubleValue = camera.centerOfScene.z
          }
        }
      case "CameraViewMatrixCell":
        if let textFieldRotationDelta: NSTextField = view.viewWithTag(30) as? NSTextField,
          let textFieldYawPlusX: NSButton = view.viewWithTag(31) as? NSButton,
          let textFieldYawPlusY: NSButton = view.viewWithTag(32) as? NSButton,
          let textFieldYawPlusZ: NSButton = view.viewWithTag(33) as? NSButton,
          let textFieldYawMinusX: NSButton = view.viewWithTag(34) as? NSButton,
          let textFieldYawMinusY: NSButton = view.viewWithTag(35) as? NSButton,
          let textFieldYawMinusZ: NSButton = view.viewWithTag(36) as? NSButton
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
            textFieldRotationDelta.doubleValue =  rotationDelta
            textFieldYawPlusX.title =  "Rotate +\(rotationDelta)°"
            textFieldYawPlusY.title =  "Rotate +\(rotationDelta)°"
            textFieldYawPlusZ.title =  "Rotate +\(rotationDelta)°"
            textFieldYawMinusX.title =  "Rotate -\(rotationDelta)°"
            textFieldYawMinusY.title =  "Rotate -\(rotationDelta)°"
            textFieldYawMinusZ.title =  "Rotate -\(rotationDelta)°"
          }
        }
        
        if let textFieldEulerAngleX: NSTextField = view.viewWithTag(40) as? NSTextField,
          let sliderEulerAngleX: NSSlider = view.viewWithTag(37) as? NSSlider,
          let textFieldEulerAngleZ: NSTextField = view.viewWithTag(41) as? NSTextField,
          let sliderEulerAngleZ: NSSlider = view.viewWithTag(38) as? NSSlider,
          let textFieldEulerAngleY: NSTextField = view.viewWithTag(42) as? NSTextField,
          let sliderEulerAngleY: NSSlider = view.viewWithTag(39) as? NSSlider
        {
          textFieldEulerAngleX.isEnabled = false
          sliderEulerAngleX.isEnabled = false
          textFieldEulerAngleY.isEnabled = false
          sliderEulerAngleY.isEnabled = false
          textFieldEulerAngleZ.isEnabled = false
          sliderEulerAngleZ.isEnabled = false
          if let EulerAngles: SIMD3<Double> = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.EulerAngles
          {
            textFieldEulerAngleX.isEnabled = true
            sliderEulerAngleX.isEnabled = true
            textFieldEulerAngleY.isEnabled = true
            sliderEulerAngleY.isEnabled = true
            textFieldEulerAngleZ.isEnabled = true
            sliderEulerAngleZ.isEnabled = true
            textFieldEulerAngleX.doubleValue =  EulerAngles.x * 180.0/Double.pi
            sliderEulerAngleX.doubleValue = (EulerAngles.x * 180.0/Double.pi)
            textFieldEulerAngleZ.doubleValue =  EulerAngles.z * 180.0/Double.pi
            sliderEulerAngleZ.doubleValue = EulerAngles.z * 180.0/Double.pi
            textFieldEulerAngleY.doubleValue =  EulerAngles.y * 180.0/Double.pi
            sliderEulerAngleY.doubleValue = EulerAngles.y * 180.0/Double.pi
          }
        }
        
        if let fieldM11: NSTextField = view.viewWithTag(0) as? NSTextField,
          let fieldM21: NSTextField = view.viewWithTag(1) as? NSTextField,
          let fieldM31: NSTextField = view.viewWithTag(2) as? NSTextField,
          let fieldM41: NSTextField = view.viewWithTag(3) as? NSTextField,
          let fieldM12: NSTextField = view.viewWithTag(4) as? NSTextField,
          let fieldM22: NSTextField = view.viewWithTag(5) as? NSTextField,
          let fieldM32: NSTextField = view.viewWithTag(6) as? NSTextField,
          let fieldM42: NSTextField = view.viewWithTag(7) as? NSTextField,
          let fieldM13: NSTextField = view.viewWithTag(8) as? NSTextField,
          let fieldM23: NSTextField = view.viewWithTag(9) as? NSTextField,
          let fieldM33: NSTextField = view.viewWithTag(10) as? NSTextField,
          let fieldM43: NSTextField = view.viewWithTag(11) as? NSTextField,
          let fieldM14: NSTextField = view.viewWithTag(12) as? NSTextField,
          let fieldM24: NSTextField = view.viewWithTag(13) as? NSTextField,
          let fieldM34: NSTextField = view.viewWithTag(14) as? NSTextField,
          let fieldM44: NSTextField = view.viewWithTag(15) as? NSTextField
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
        
        if let textFieldCameraPositionX: NSTextField = view.viewWithTag(20) as? NSTextField,
           let textFieldCameraPositionY: NSTextField = view.viewWithTag(21) as? NSTextField,
           let textFieldCameraPositionZ: NSTextField = view.viewWithTag(22) as? NSTextField,
           let textFieldCameraDistance: NSTextField = view.viewWithTag(23) as? NSTextField
        {
          if let position: SIMD3<Double> = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.position
          {
            textFieldCameraPositionX.doubleValue = position.x
            textFieldCameraPositionY.doubleValue = position.y
            textFieldCameraPositionZ.doubleValue = position.z
            textFieldCameraDistance.doubleValue = length(position)
          }
        }
      case "CameraSelectionCell":
        // Overall bloom level
        if let textFieldAtomBloomLevel: NSTextField = view.viewWithTag(2) as? NSTextField
        {
          textFieldAtomBloomLevel.isEditable = false
          if let camera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
          {
            textFieldAtomBloomLevel.isEditable = true
            textFieldAtomBloomLevel.doubleValue = camera.bloomLevel
          }
        }
        if let sliderAtomBloomLevel: NSSlider = view.viewWithTag(3) as? NSSlider
        {
          sliderAtomBloomLevel.isEnabled = false
          sliderAtomBloomLevel.minValue = 0.0
          sliderAtomBloomLevel.maxValue = 2.0
          if let camera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
          {
            sliderAtomBloomLevel.isEnabled = true
            sliderAtomBloomLevel.doubleValue = camera.bloomLevel
          }
        }
      case "CameraLightsCell":
        if let ambientLightIntensitity: NSTextField = view.viewWithTag(1) as? NSTextField,
          let sliderAmbientLightIntensitity: NSSlider = view.viewWithTag(5) as? NSSlider,
          let ambientColor: NSColorWell = view.viewWithTag(9) as? NSColorWell
        {
          ambientLightIntensitity.isEnabled = false
          sliderAmbientLightIntensitity.isEnabled = false
          ambientColor.isEnabled = false
          if let project = representedObject as? ProjectStructureNode
          {
            ambientLightIntensitity.isEnabled = true
            sliderAmbientLightIntensitity.isEnabled = true
            ambientColor.isEnabled = true
            ambientLightIntensitity.doubleValue = project.renderLights[0].ambientIntensity
            sliderAmbientLightIntensitity.minValue = 0.0
            sliderAmbientLightIntensitity.maxValue = 1.0
            sliderAmbientLightIntensitity.doubleValue = project.renderLights[0].ambientIntensity
            ambientColor.color = project.renderLights[0].ambient
          }
        }
        
        
        if let diffuseLightIntensitity: NSTextField = view.viewWithTag(2) as? NSTextField,
          let sliderDiffuseLightIntensitity: NSSlider = view.viewWithTag(6) as? NSSlider,
          let diffuseColor: NSColorWell = view.viewWithTag(10) as? NSColorWell
        {
          diffuseLightIntensitity.isEnabled = false
          sliderDiffuseLightIntensitity.isEnabled = false
          diffuseColor.isEnabled = false
          if let project = representedObject as? ProjectStructureNode
          {
            diffuseLightIntensitity.isEnabled = true
            sliderDiffuseLightIntensitity.isEnabled = true
            diffuseColor.isEnabled = true
            diffuseLightIntensitity.doubleValue = project.renderLights[0].diffuseIntensity
            sliderDiffuseLightIntensitity.minValue = 0.0
            sliderDiffuseLightIntensitity.maxValue = 1.0
            sliderDiffuseLightIntensitity.doubleValue = project.renderLights[0].diffuseIntensity
            diffuseColor.color = project.renderLights[0].diffuse
          }
        }
        
        if let specularLightIntensitity: NSTextField = view.viewWithTag(3) as? NSTextField,
          let sliderSpecularLightIntensitity: NSSlider = view.viewWithTag(7) as? NSSlider,
          let specularColor: NSColorWell = view.viewWithTag(11) as? NSColorWell
        {
          specularLightIntensitity.isEnabled = false
          sliderSpecularLightIntensitity.isEnabled = false
          specularColor.isEnabled = false
          if let project = representedObject as? ProjectStructureNode
          {
            specularLightIntensitity.isEnabled = true
            sliderSpecularLightIntensitity.isEnabled = true
            specularColor.isEnabled = true
            specularLightIntensitity.doubleValue = project.renderLights[0].specularIntensity
            sliderSpecularLightIntensitity.minValue = 0.0
            sliderSpecularLightIntensitity.maxValue = 5.0
            sliderSpecularLightIntensitity.doubleValue = project.renderLights[0].specularIntensity
            specularColor.color = project.renderLights[0].specular
          }
        }
        
        if let shininess: NSTextField = view.viewWithTag(4) as? NSTextField,
          let sliderShininess: NSSlider = view.viewWithTag(8) as? NSSlider
        {
          shininess.isEnabled = false
          sliderShininess.isEnabled = false
          if let project = representedObject as? ProjectStructureNode
          {
            shininess.isEnabled = true
            sliderShininess.isEnabled = true
            shininess.doubleValue = project.renderLights[0].shininess
            sliderShininess.minValue = 0.1
            sliderShininess.maxValue = 128.0
            sliderShininess.doubleValue = project.renderLights[0].shininess
          }
        }
      case "CameraPictureCell":
        if let popUpbuttonDPI: NSPopUpButton = view.viewWithTag(1) as? NSPopUpButton,
          let textFieldPhysicalDimensionsX: NSTextField = view.viewWithTag(3) as? NSTextField,
          let textFieldPhysicalDimensionsY: NSTextField = view.viewWithTag(4) as? NSTextField,
          let popUpbuttonPictureQuality: NSPopUpButton = view.viewWithTag(5) as? NSPopUpButton,
          let textFieldNumberOfPixelsX: NSTextField = view.viewWithTag(6) as? NSTextField,
          let textFieldNumberOfPixelsY: NSTextField = view.viewWithTag(7) as? NSTextField,
          let buttonPhysical: NSButton = view.viewWithTag(8) as? NSButton,
          let buttonPixels: NSButton = view.viewWithTag(9) as? NSButton,
          let buttonUnitInch: NSButton = view.viewWithTag(10) as? NSButton,
          let buttonUnitCM: NSButton = view.viewWithTag(11) as? NSButton
        {
          popUpbuttonDPI.isEnabled = false
          textFieldPhysicalDimensionsX.isEnabled = false
          textFieldPhysicalDimensionsY.isEnabled = false
          popUpbuttonPictureQuality.isEnabled = false
          textFieldNumberOfPixelsX.isEnabled = false
          textFieldNumberOfPixelsY.isEnabled = false
          buttonPhysical.isEnabled = false
          buttonPixels.isEnabled = false
          buttonUnitInch.isEnabled = false
          buttonUnitCM.isEnabled = false
          
          if let project = representedObject as? ProjectStructureNode
          {
            popUpbuttonDPI.isEnabled = true
            textFieldPhysicalDimensionsX.isEnabled = true
            textFieldPhysicalDimensionsY.isEnabled = true
            popUpbuttonPictureQuality.isEnabled = true
            textFieldNumberOfPixelsX.isEnabled = true
            textFieldNumberOfPixelsY.isEnabled = true
            buttonPhysical.isEnabled = true
            buttonPixels.isEnabled = true
            buttonUnitInch.isEnabled = true
            buttonUnitCM.isEnabled = true
            
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
              buttonPhysical.state = NSControl.StateValue.on
              textFieldPhysicalDimensionsX.isEnabled = true
              textFieldPhysicalDimensionsY.isEnabled = false
              textFieldNumberOfPixelsX.isEnabled = false
              textFieldNumberOfPixelsY.isEnabled = false
            case ProjectStructureNode.Dimensions.pixels:
              buttonPixels.state = NSControl.StateValue.on
              textFieldPhysicalDimensionsX.isEnabled = false
              textFieldPhysicalDimensionsY.isEnabled = false
              textFieldNumberOfPixelsX.isEnabled = true
              textFieldNumberOfPixelsY.isEnabled = false
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
      case "CameraBackgroundCell":
        let tabView: NSTabView = getSubviewsOfView(view).filter{$0.identifier?.rawValue == "BackgroundTabView"}.first as! NSTabView
        if let buttonColor: NSButton = view.viewWithTag(1) as? NSButton,
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
              if let imageViewColor: NSColorWell = view.viewWithTag(23) as? NSColorWell
              {
                buttonColor.state = NSControl.StateValue.on
                imageViewColor.color = project.renderBackgroundColor
              }
            case RKBackgroundType.linearGradient:
              tabView.selectTabViewItem(at: 1)
              if let fromColorLinearGradient: NSColorWell = view.viewWithTag(10) as? NSColorWell,
                let toColorLinearGradient: NSColorWell = view.viewWithTag(11) as? NSColorWell,
                let sliderLinearGradient: NSSlider = view.viewWithTag(12) as? NSSlider,
                let textFieldLinearGradient: NSTextField = view.viewWithTag(13) as? NSTextField
              {
                buttonLinearGradient.state = NSControl.StateValue.on
                fromColorLinearGradient.color = project.backgroundLinearGradientFromColor
                toColorLinearGradient.color = project.backgroundLinearGradientToColor
                sliderLinearGradient.doubleValue = project.backgroundLinearGradientAngle
                textFieldLinearGradient.doubleValue = project.backgroundLinearGradientAngle
              }
            case RKBackgroundType.radialGradient:
              tabView.selectTabViewItem(at: 2)
              if let  fromColorRadialGradient: NSColorWell = view.viewWithTag(15) as? NSColorWell,
                let toColorRadialGradient: NSColorWell = view.viewWithTag(16) as? NSColorWell,
                let sliderRadialGradient: NSSlider = view.viewWithTag(17) as? NSSlider,
                let textFieldRadialGradient: NSTextField = view.viewWithTag(18) as? NSTextField
              {
                buttonRadialGradient.state = NSControl.StateValue.on
                fromColorRadialGradient.color = project.backgroundRadialGradientFromColor
                toColorRadialGradient.color = project.backgroundRadialGradientToColor
                sliderRadialGradient.doubleValue = project.backgroundRadialGradientRoundness
                textFieldRadialGradient.doubleValue = project.backgroundRadialGradientRoundness
              }
            case RKBackgroundType.image:
              tabView.selectTabViewItem(at: 3)
              if let imageView: NSButton = view.viewWithTag(25) as? NSButton
              {
                buttonImage.state = NSControl.StateValue.on
                if (project.renderBackgroundImage != nil)
                {
                  imageView.image = NSImage(cgImage: project.renderBackgroundImage!, size: NSSize(width: 128.0, height: 128.0))
                }
                else
                {
                  imageView.image = nil
                }
              }
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
      default:
        break
      }
      
      return view
    }
    return nil
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
  // ===============================================================================================================================
  
  func updateOutlineView(identifiers: [[NSString : AnyObject]])
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
  // ===============================================================================================================================
  
  @IBAction func changedCameraDefaultViewPosition(_ sender: NSButtonCell)
  {
    let button: NSButtonCell = sender as NSButtonCell
    
    if let renderCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      switch(button.tag)
      {
      case 10:
        renderCamera.resetDirectionType = RKCamera.ResetDirectionType.minus_X
      case 11:
        renderCamera.resetDirectionType = RKCamera.ResetDirectionType.minus_Y
      case 12:
        renderCamera.resetDirectionType = RKCamera.ResetDirectionType.minus_Z
      case 13:
        renderCamera.resetDirectionType = RKCamera.ResetDirectionType.plus_X
      case 14:
        renderCamera.resetDirectionType = RKCamera.ResetDirectionType.plus_Y
      case 15:
        renderCamera.resetDirectionType = RKCamera.ResetDirectionType.plus_Z
      default:
        LogQueue.shared.error(destination: self.windowController, message: "Undefined camera-direction in 'changedCameraDefaultViewPosition'")
      }
      
      self.updateCameraViewMatrix()
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
      
      updateCameraViewMatrix()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
    }
  }
  
  @IBAction func switchCameraProjection(_ sender: NSButtonCell)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      switch(sender.tag)
      {
      case 20:
        renderCamera.setCameraToPerspective()
      case 21:
        renderCamera.setCameraToOrthographic()
      default:
        fatalError("Unknown camera projection")
      }
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
    }
  }
  
 
  
  @objc func updateCameraViewMatrix()
  {
    self.windowController?.document?.updateChangeCount(.changeDone)
    
    if let row: Int = self.cameraOutlineView?.row(forItem: self.cameraCell), row >= 0,
       let outlineView = self.cameraOutlineView,
       let view: NSTableCellView = outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as?  NSTableCellView
    {
      if let buttonMinusX: NSButton = view.viewWithTag(10) as? NSButton,
         let buttonMinusY: NSButton = view.viewWithTag(11) as? NSButton,
         let buttonMinusZ: NSButton = view.viewWithTag(12) as? NSButton,
         let buttonPlusX: NSButton = view.viewWithTag(13) as? NSButton,
         let buttonPlusY: NSButton = view.viewWithTag(14) as? NSButton,
         let buttonPlusZ: NSButton = view.viewWithTag(15) as? NSButton,
         let buttonPerspective: NSButton = view.viewWithTag(20) as? NSButton,
         let buttonOrthogonal: NSButton = view.viewWithTag(21) as? NSButton
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
        
        outlineView.setNeedsDisplay(outlineView.rect(ofRow: row))
      }
    }
    
    // only update when the row-view is visible
    // fast way of updating: get the current-view, set properties on it, and update the rect to redraw
    if let row: Int = self.cameraOutlineView?.row(forItem: self.cameraViewMatrixCell), row >= 0,
      let outlineView = self.cameraOutlineView,
      let view: NSTableCellView = outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as?  NSTableCellView,
      let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      let EulerAngles: SIMD3<Double> = renderCamera.EulerAngles
      
      if let textFieldEulerAngleX: NSTextField = view.viewWithTag(40) as? NSTextField
      {
        textFieldEulerAngleX.doubleValue =  EulerAngles.x * 180.0/Double.pi
      }
      
      if let sliderEulerAngleX: NSSlider = view.viewWithTag(37) as? NSSlider
      {
        sliderEulerAngleX.doubleValue = (EulerAngles.x * 180.0/Double.pi)
      }
      
      if let textFieldEulerAngleZ: NSTextField = view.viewWithTag(41) as? NSTextField
      {
        textFieldEulerAngleZ.doubleValue =  EulerAngles.z * 180.0/Double.pi
      }
      
      if let sliderEulerAngleZ: NSSlider = view.viewWithTag(38) as? NSSlider
      {
        sliderEulerAngleZ.doubleValue = EulerAngles.z * 180.0/Double.pi
      }
      
      if let textFieldEulerAngleY: NSTextField = view.viewWithTag(42) as? NSTextField
      {
        textFieldEulerAngleY.doubleValue =  EulerAngles.y * 180.0/Double.pi
      }
      
      if let sliderEulerAngleY: NSSlider = view.viewWithTag(39) as? NSSlider
      {
        sliderEulerAngleY.doubleValue = EulerAngles.y * 180.0/Double.pi
      }
      
      
      let position: SIMD3<Double> = renderCamera.position
      let centerOfScene: SIMD3<Double> = renderCamera.centerOfScene
      
      if let textFieldCamerPositionX: NSTextField = view.viewWithTag(20) as? NSTextField
      {
        textFieldCamerPositionX.doubleValue = position.x
      }
      
      if let textFieldCamerPositionY: NSTextField = view.viewWithTag(21) as? NSTextField
      {
        textFieldCamerPositionY.doubleValue = position.y
      }
      
      if let textFieldCamerPositionZ: NSTextField = view.viewWithTag(22) as? NSTextField
      {
        textFieldCamerPositionZ.doubleValue = position.z
      }
      
      if let textFieldCamerDistance: NSTextField = view.viewWithTag(23) as? NSTextField
      {
        textFieldCamerDistance.doubleValue = length(position - centerOfScene)
      }
      
      
      let viewMatrix: double4x4 = renderCamera.modelViewMatrix
      
      if let fieldM11: NSTextField = view.viewWithTag(0) as? NSTextField
      {
        fieldM11.doubleValue = viewMatrix[0][0]
      }
      if let fieldM21: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        fieldM21.doubleValue = viewMatrix[0][1]
      }
      if let fieldM31: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        fieldM31.doubleValue = viewMatrix[0][2]
      }
      if let fieldM41: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        fieldM41.doubleValue = viewMatrix[0][3]
      }
      
      if let fieldM12: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        fieldM12.doubleValue = viewMatrix[1][0]
      }
      if let fieldM22: NSTextField = view.viewWithTag(5) as? NSTextField
      {
        fieldM22.doubleValue = viewMatrix[1][1]
      }
      if let fieldM32: NSTextField = view.viewWithTag(6) as? NSTextField
      {
        fieldM32.doubleValue = viewMatrix[1][2]
      }
      if let fieldM42: NSTextField = view.viewWithTag(7) as? NSTextField
      {
        fieldM42.doubleValue = viewMatrix[1][3]
      }
      
      if let fieldM13: NSTextField = view.viewWithTag(8) as? NSTextField
      {
        fieldM13.doubleValue = viewMatrix[2][0]
      }
      if let fieldM23: NSTextField = view.viewWithTag(9) as? NSTextField
      {
        fieldM23.doubleValue = viewMatrix[2][1]
      }
      if let fieldM33: NSTextField = view.viewWithTag(10) as? NSTextField
      {
        fieldM33.doubleValue = viewMatrix[2][2]
      }
      if let fieldM43: NSTextField = view.viewWithTag(11) as? NSTextField
      {
        fieldM43.doubleValue = viewMatrix[2][3]
      }
      
      if let fieldM14: NSTextField = view.viewWithTag(12) as? NSTextField
      {
        fieldM14.doubleValue = viewMatrix[3][0]
      }
      if let fieldM24: NSTextField = view.viewWithTag(13) as? NSTextField
      {
        fieldM24.doubleValue = viewMatrix[3][1]
      }
      if let fieldM34: NSTextField = view.viewWithTag(14) as? NSTextField
      {
        fieldM34.doubleValue = viewMatrix[3][2]
      }
      if let fieldM44: NSTextField = view.viewWithTag(15) as? NSTextField
      {
        fieldM44.doubleValue = viewMatrix[3][3]
      }
      
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
        
        renderCamera.angleOfView = newValue * Double.pi / 180.0
        renderCamera.updateFieldOfView()
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
    let deltaValue: Double = Double(sender.intValue)
    
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      renderCamera.angleOfView += deltaValue * Double.pi / 180.0
      renderCamera.updateFieldOfView()
        
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.updateOutlineView(identifiers: [self.cameraCell])
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
  // ===============================================================================================================================
  
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
        
        updateCameraViewMatrix()
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
      
      updateCameraViewMatrix()
      
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
      
      updateCameraViewMatrix()
      
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
      
      updateCameraViewMatrix()
      
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
      
      updateCameraViewMatrix()
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
      
      updateCameraViewMatrix()
      
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
      
      updateCameraViewMatrix()
      
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
      
      updateCameraViewMatrix()
      
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
      
      updateCameraViewMatrix()
      
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
      
      updateCameraViewMatrix()
      
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
      
      updateCameraViewMatrix()
      
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
      
      updateCameraViewMatrix()
      
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
      
      self.updateOutlineView(identifiers: [self.cameraViewMatrixCell])
      
      self.windowController?.document?.updateChangeCount(.changeDone)
    }
  }
  
  // MARK: Selection
  // ===============================================================================================================================
  
  
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
  
  // MARK: Global light
  // ===============================================================================================================================
  
  @IBAction func changeAmbientTextField(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderLights[0].ambientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraLightsCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateLightUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeAmbientIntensitySlider(_ sender: NSSlider)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderLights[0].ambientIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraLightsCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateLightUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeAmbientColor(_ sender: NSColorWell)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderLights[0].ambient = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateLightUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeDiffuseTextField(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderLights[0].diffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraLightsCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateLightUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeDiffuseIntensitySlider(_ sender: NSSlider)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderLights[0].diffuseIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraLightsCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateLightUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeDiffuseColor(_ sender: NSColorWell)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderLights[0].diffuse = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateLightUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeSpecularTextField(_ sender: NSTextField)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderLights[0].specularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraLightsCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateLightUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  @IBAction func changeSpecularIntensitySlider(_ sender: NSSlider)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderLights[0].specularIntensity = sender.doubleValue
      
      self.updateOutlineView(identifiers: [self.cameraLightsCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.updateLightUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeSpecularColor(_ sender: NSColorWell)
  {
    if let crystalProject: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystalProject.renderLights[0].specular = sender.color
      
      self.windowController?.detailTabViewController?.renderViewController?.updateLightUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cameraOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
    
  
  // MARK: Background actions
  // ===============================================================================================================================
  
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
          if let imageSource = CGImageSourceCreateWithURL(openPanel.url! as CFURL, nil),
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
  
  
  // MARK: Picture actions
  // ===============================================================================================================================
  
  @objc func updateAspectRatioView()
  {
    self.updateOutlineView(identifiers: [self.cameraPictureCell])
  }
  
  @IBAction func setPictureEditDimensions(_ sender: NSButtonCell)
  {
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      switch(sender.tag)
      {
      case 8:
        crystals.imageDimensions = ProjectStructureNode.Dimensions.physical
      case 9:
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
      case 10:
        crystals.imageUnits = ProjectStructureNode.Units.inch
      case 11:
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
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystals.imageDPI = ProjectStructureNode.DPI(rawValue: sender.indexOfSelectedItem)!
      
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
    if let crystals: ProjectStructureNode = self.representedObject as? ProjectStructureNode
    {
      crystals.renderImageQuality = RKImageQuality(rawValue: sender.indexOfSelectedItem)!
      
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
  // ===============================================================================================================================
  
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
