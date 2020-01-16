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
import iRASPAKit
import RenderKit
import SymmetryKit
import LogViewKit
import MathKit

class RenderTabViewController: NSTabViewController, NSMenuItemValidation, WindowControllerConsumer, ProjectConsumer, GlobalModifierFlagsConsumer, RKRenderViewSelectionDelegate, StructurePageController
{
  var structures: [Structure] = []
  
  weak var windowController: iRASPAWindowController?
  
  weak var renderDataSource: RKRenderDataSource?
  
  let ancherDistance: CGFloat = 8
  @IBOutlet var transformationPanel: NSTabView?
  var transformationPanelLeftLayoutConstraint : NSLayoutConstraint?
  var transformationPanelTopLayoutConstraint : NSLayoutConstraint?

  
  enum Tracking {
    case none
    case panning
    case addToSelection
    case newSelection
    case draggedAddToSelection
    case draggedNewSelection
    case backgroundClick
    case measurement
    case translateSelection
    case other
  }
  
  var tracking: Tracking = .none
  var startPoint: NSPoint? = NSPoint()
  var pickedDepth: Float? = 1.0
  
  public enum WindowAspectRatio: Int
  {
    case aspect_ratio_off = 0
    case aspect_ratio_4_to_3 = 1
    case aspect_ratio_16_to_9 = 2
    case aspect_ratio_1_to_1 = 3
    case aspect_ratio_1_85_to_1 = 4
    case aspect_ratio_2_39_to_1 = 5
    case aspect_ratio_21_to_9 = 6
    case aspect_ratio_3_to_2 = 7
    case aspect_ratio_3_to_1 = 8
  }
  
  var contextMenu: NSMenu? = nil
  var preferedRenderer: Int = 0
  var metalSupported: Bool = true
  
  var currentAspectRatio: WindowAspectRatio = WindowAspectRatio.aspect_ratio_off
  var currentAspectRatioValue: Double = 1.0
  
  

  var aspectRationConstraint_1_to_1: NSLayoutConstraint! = nil
  var aspectRationConstraint_4_to_3: NSLayoutConstraint! = nil
  var aspectRationConstraint_16_to_9: NSLayoutConstraint! = nil
  var aspectRationConstraint_1_85_to_1: NSLayoutConstraint! = nil
  var aspectRationConstraint_2_39_to_1: NSLayoutConstraint! = nil
  var aspectRationConstraint_21_9: NSLayoutConstraint! = nil
  var aspectRationConstraint_3_2: NSLayoutConstraint! = nil
  var aspectRationConstraint_3_1: NSLayoutConstraint! = nil
  
  
  
  // called when present in a NIB-file
  required init?(coder aDecoder: NSCoder)
  {
    super.init(coder: aDecoder)
    
    preferedRenderer = 0
    
    // Metal for OSX is available on 'El Capitan' 10.11 and beyond
    // Macs from 2012 onward should be compatible
    // Use the Metal-API to check whether the device is actually supported
      
    if let _: MTLDevice = MTLCreateSystemDefaultDevice()
    {
      preferedRenderer = 0
      metalSupported = true
    }
    else
    {
      fatalError("iRASPA requires METAL")
    }
    
   
  }
  

  var cameraBoundingBoxMenuItem: NSMenuItem? = nil
  
  // ViewDidLoad: bounds are not yet set (do not do geometry-related etup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
   
    self.view.menu = NSMenu(title: "test")
    self.view.menu?.insertItem(withTitle: "Reset camera distance", action: #selector(resetCamera), keyEquivalent: "", at: 0)
    let camerProjectionMenuItem = NSMenuItem(title: "Camera projection", action: nil, keyEquivalent: "")
    
    let resetMenuItem = NSMenuItem(title: "Reset camera to", action: nil, keyEquivalent: "")
    self.view.menu?.insertItem(resetMenuItem, at: 1)
    
    self.view.menu?.insertItem(camerProjectionMenuItem, at: 2)
   
    cameraBoundingBoxMenuItem = NSMenuItem(title: "Show bounding box", action: #selector(toggleBoundingBox), keyEquivalent: "")
    cameraBoundingBoxMenuItem?.state = .off
    if let cameraBoundingBoxMenuItem = cameraBoundingBoxMenuItem
    {
      self.view.menu?.insertItem(cameraBoundingBoxMenuItem, at: 3)
    }
    
    self.view.menu?.insertItem(withTitle: "Compute AO high-quality", action: #selector(computeHighQualityAmbientOcclusion), keyEquivalent: "", at: 4)
    
    let exportMenuItem = NSMenuItem(title: "Export to", action: nil, keyEquivalent: "")
    self.view.menu?.insertItem(exportMenuItem, at: 5)
    
    
    let projectionMenu: NSMenu = NSMenu(title: "Camera projection")
    projectionMenu.insertItem(withTitle: "Orthographic", action: #selector(setCameraToOrthographic), keyEquivalent: "", at: 0)
    projectionMenu.insertItem(withTitle: "Perspective", action: #selector(setCameraToPerspective), keyEquivalent: "", at: 1)
    camerProjectionMenuItem.submenu = projectionMenu
    
    let resetMenu: NSMenu = NSMenu(title: "Camera projection")
    resetMenu.insertItem(withTitle: "Z-direction", action: #selector(resetCameraToZ), keyEquivalent: "", at: 0)
    resetMenu.insertItem(withTitle: "Y-direction", action: #selector(resetCameraToY), keyEquivalent: "", at: 1)
    resetMenu.insertItem(withTitle: "X-direction", action: #selector(resetCameraToX), keyEquivalent: "", at: 2)
    resetMenuItem.submenu = resetMenu
    
    let exportMenu: NSMenu = NSMenu(title: "Export to")
    exportMenu.insertItem(withTitle: "PDB", action: #selector(exportToPDB), keyEquivalent: "", at: 0)
    exportMenu.insertItem(withTitle: "mmCIF", action: #selector(exportToMMCIF), keyEquivalent: "", at: 1)
    exportMenu.insertItem(withTitle: "CIF", action: #selector(exportToCIF), keyEquivalent: "", at: 2)
    exportMenu.insertItem(withTitle: "XYZ", action: #selector(exportToXYZ), keyEquivalent: "", at: 3)
    exportMenu.insertItem(withTitle: "VASP POSCAR", action: #selector(exportToVASP), keyEquivalent: "", at: 4)
    exportMenuItem.submenu = exportMenu
    
/*
    for tabViewItem in self.tabViewItems
    {
      (tabViewItem.viewController as? RenderViewController)?.selectionDelegate = self
    }
*/
    self.selectedTabViewItemIndex = preferedRenderer
    
    aspectRationConstraint_1_to_1 = NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1.0, constant: 1.0)
    self.view.addConstraint(aspectRationConstraint_1_to_1)
    aspectRationConstraint_1_to_1.isActive = false
    
    aspectRationConstraint_4_to_3 = NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 4.0/3.0, constant: 1.0)
    self.view.addConstraint(aspectRationConstraint_4_to_3)
    aspectRationConstraint_4_to_3.isActive = false
    
    aspectRationConstraint_16_to_9 = NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 16.0/9.0, constant: 1.0)
    self.view.addConstraint(aspectRationConstraint_16_to_9)
    aspectRationConstraint_16_to_9.isActive = false
    
    aspectRationConstraint_1_85_to_1 = NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1.85, constant: 1.0)
    self.view.addConstraint(aspectRationConstraint_1_85_to_1)
    aspectRationConstraint_1_85_to_1.isActive = false
    
    
    aspectRationConstraint_2_39_to_1 = NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 2.39, constant: 1.0)
    self.view.addConstraint(aspectRationConstraint_2_39_to_1)
    aspectRationConstraint_2_39_to_1.isActive = false
    
    aspectRationConstraint_21_9 = NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 21/9.0, constant: 1.0)
    self.view.addConstraint(aspectRationConstraint_21_9)
    aspectRationConstraint_21_9.isActive = false
    
    aspectRationConstraint_3_2 = NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1.5, constant: 1.0)
    self.view.addConstraint(aspectRationConstraint_3_2)
    aspectRationConstraint_3_2.isActive = false
    
    aspectRationConstraint_3_1 = NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 3.0, constant: 1.0)
    self.view.addConstraint(aspectRationConstraint_3_1)
    aspectRationConstraint_3_1.isActive = false
  }
  
  func globalModifierFlagsChanged(_ flags: NSEvent.ModifierFlags)
  {
    if flags.contains(.option)
    {
      transformationPanel?.selectTabViewItem(at: 1)
    }
    else
    {
      transformationPanel?.selectTabViewItem(at: 0)
    }
  }
  
  override func viewDidAppear()
  {
    super.viewDidAppear()
    
    if let view: RenderTabView = self.view as? RenderTabView
    {
      if view.trackingArea != nil
      {
        view.removeTrackingArea(view.trackingArea!)
      }
      let options : NSTrackingArea.Options = [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited, .enabledDuringMouseDrag  ]
      let trackingArea = NSTrackingArea(rect: view.bounds, options: options, owner: view, userInfo: nil)
      view.trackingArea = trackingArea
      view.addTrackingArea(trackingArea)
      
      if let transformationPanel = self.transformationPanel
      {
        transformationPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(transformationPanel)
        transformationPanelLeftLayoutConstraint = transformationPanel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: ancherDistance)
        transformationPanelLeftLayoutConstraint?.isActive = true
        transformationPanelTopLayoutConstraint = transformationPanel.topAnchor.constraint(equalTo: view.topAnchor, constant: ancherDistance)
        transformationPanelTopLayoutConstraint?.isActive = true
        transformationPanel.isHidden = true
        transformationPanel.wantsLayer = true
        transformationPanel.layer?.opacity = 0.0
      }
      
      if let project: ProjectStructureNode = proxyProject?.representedObject.loadedProjectStructureNode
      {
        let selectionEmpty: Bool = !project.allStructures.map{$0.atoms.selectedTreeNodes.isEmpty}.contains(false)
        showTransformationPanel(oldSelectionEmpty: selectionEmpty, newSelectionEmpty: selectionEmpty)
      }
    }
  }
  
  override func viewWillDisappear()
  {
    super.viewWillDisappear()
    
    if let view: RenderTabView = self.view as? RenderTabView
    {
      if view.trackingArea != nil
      {
        view.removeTrackingArea(view.trackingArea!)
      }
    }
    
    transformationPanelLeftLayoutConstraint?.isActive = false
    transformationPanelTopLayoutConstraint?.isActive = false
  }

  // MARK: protocol ProjectConsumer
  // ===============================================================================================================================
  
  weak var proxyProject: ProjectTreeNode?
  {
    didSet
    {
      self.representedObject = proxyProject?.representedObject.loadedProjectStructureNode
      
      if let project: ProjectStructureNode = proxyProject?.representedObject.loadedProjectStructureNode
      {
        self.renderDataSource = project
        
        let selectionEmpty: Bool = !project.allStructures.map{$0.atoms.selectedTreeNodes.isEmpty}.contains(false)
        showTransformationPanel(oldSelectionEmpty: selectionEmpty, newSelectionEmpty: selectionEmpty)
        
        // all renders need to have the current project: for exmaple: select metal, rch project, switch to openGL
        for tabViewItem in self.tabViewItems
        {
          if let renderViewController: RenderViewController = tabViewItem.viewController as? RenderViewController
          {
            renderViewController.renderDataSource = project
            renderViewController.renderCameraSource = project //proxyProject
          }
        }
        
        
        let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
        let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
        if let renderViewController: RenderViewController = tabViewItem.viewController as? RenderViewController
        {
          renderViewController.renderDataSource = project
          renderViewController.renderCameraSource = project //proxyProject
        }
      }
      else
      {
        renderViewController.renderDataSource = nil
        renderViewController.renderCameraSource = nil
        showTransformationPanel(oldSelectionEmpty: false, newSelectionEmpty: true)
      }
    }
  }
  
  func masterViewControllerTabChanged(tab: Int)
  {
    if let project = representedObject as? ProjectStructureNode
    {
      switch(tab)
      {
      case 0:
        self.structures = project.sceneList.scenes.flatMap{$0.allStructures}
      case 1:
        self.structures = project.sceneList.scenes.flatMap{$0.selectedMovies}.flatMap{$0.allStructures}
      case 2:
          self.structures = project.sceneList.selectedScene?.selectedMovie?.selectedFrames.compactMap{$0.structure} ?? []
      default:
        break
      }
    }
    else
    {
      self.structures = []
    }
  }
  
  func masterViewControllerSelectionChanged(tab: Int)
  {
    if let project = representedObject as? ProjectStructureNode
    {
      switch(tab)
      {
      case 0:
        break
      case 1:
        self.structures = project.sceneList.scenes.flatMap{$0.selectedMovies}.flatMap{$0.allStructures}
      case 2:
        self.structures = project.sceneList.selectedScene?.selectedMovie?.selectedFrames.compactMap{$0.structure} ?? []
        
      default:
        break
      }
    }
    else
    {
      self.structures = []
    }
  }



  // detect changes in the view-bounds, use these to update the 'Camera'-detail view (pictures and movies uses the aspect-ratio)
  override func viewDidLayout()
  {
    super.viewDidLayout()
    
    if let isKeyWindow = windowController?.window?.isKeyWindow, isKeyWindow
    {
      currentAspectRatioValue = Double(self.view.bounds.size.width/self.view.bounds.size.height)
      NotificationCenter.default.post(name: NSView.boundsDidChangeNotification, object: self)
    }
  }
  
  
  var aspectRatioValue: Double
  {
    switch(currentAspectRatio)
    {
    case .aspect_ratio_off:
      return Double(self.view.bounds.size.width/self.view.bounds.size.height)
    case .aspect_ratio_4_to_3:
      return 4.0/3.0
    case .aspect_ratio_16_to_9:
      return 16.0/9.0
    case .aspect_ratio_1_to_1:
      return 1.0
    case .aspect_ratio_1_85_to_1:
      return 1.05405405405405405405
    case .aspect_ratio_2_39_to_1:
      return 2.39
    case .aspect_ratio_21_to_9:
      return 21.0/9.0
    case .aspect_ratio_3_to_2:
      return 1.5
    case .aspect_ratio_3_to_1:
      return 3.0
    }
  }

  
  func setfixedAspectRatio(ratio: WindowAspectRatio)
  {
    currentAspectRatio = ratio
    
    aspectRationConstraint_4_to_3.isActive = false
    aspectRationConstraint_16_to_9.isActive = false
    aspectRationConstraint_1_to_1.isActive = false
    aspectRationConstraint_1_85_to_1.isActive = false
    aspectRationConstraint_2_39_to_1.isActive = false
    aspectRationConstraint_21_9.isActive = false
    aspectRationConstraint_3_2.isActive = false
    aspectRationConstraint_3_1.isActive = false
    
    switch(ratio)
    {
    case .aspect_ratio_off:
      break
    case .aspect_ratio_4_to_3:
      aspectRationConstraint_4_to_3.isActive = true
    case .aspect_ratio_16_to_9:
      aspectRationConstraint_16_to_9.isActive = true
    case .aspect_ratio_1_to_1:
      aspectRationConstraint_1_to_1.isActive = true
    case .aspect_ratio_1_85_to_1:
      aspectRationConstraint_1_85_to_1.isActive = true
    case .aspect_ratio_2_39_to_1:
      aspectRationConstraint_2_39_to_1.isActive = true
    case .aspect_ratio_21_to_9:
      aspectRationConstraint_21_9.isActive = true
    case .aspect_ratio_3_to_2:
      aspectRationConstraint_3_2.isActive = true
    case .aspect_ratio_3_to_1:
      aspectRationConstraint_3_1.isActive = true
    }
  }

  var printView: NSView?
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      return (renderController as? MetalViewController)?.view
    }
    return nil
  }
  
  
    
  func redraw()
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      renderController.redraw()
    }
  }
  
  @objc func reloadData()
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      renderController.reloadData()
    }
  }
  
  func reloadRenderData()
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      renderController.reloadRenderData()
    }
  }
  
  func reloadBoundingBoxData()
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      renderController.reloadBoundingBoxData()
    }
  }
  
  func reloadRenderDataSelectedAtoms()
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      renderController.reloadRenderDataSelectedAtoms()
    }
  }
  
  func updateLightUniforms()
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      renderController.updateLightUniforms()
    }
  }
  
  func updateStructureUniforms()
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      renderController.updateStructureUniforms()
    }
  }
  
  func updateIsosurfaceUniforms()
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      renderController.updateIsosurfaceUniforms()
    }
  }
  
  func updateIsosurface(completionHandler: @escaping () -> ())
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      renderController.updateAdsorptionSurface(completionHandler: completionHandler)
    }
  }
  
  func reloadBackgroundImage()
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      renderController.reloadBackgroundImage()
    }
  }
  
  var renderViewController: RenderViewController
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    return tabViewItem.viewController as! RenderViewController
  }
  
  
  func invalidateIsosurface(cachedIsosurfaces: [RKRenderStructure])
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderViewController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      if cachedIsosurfaces.isEmpty
      {
        renderViewController.invalidateIsosurfaces()
      }
      else
      {
        renderViewController.invalidateIsosurface(cachedIsosurfaces)
      }
    }
  }
  
  func invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [RKRenderStructure])
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderViewController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      if cachedAmbientOcclusionTextures.isEmpty
      {
        renderViewController.invalidateCachedAmbientOcclusionTextures()
      }
      else
      {
        renderViewController.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures)
      }
    }
  }
  
  
  
  func setRenderQualityToHigh()
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderViewController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      renderViewController.renderQuality = RKRenderQuality.high
    }
  }
  
  func setRenderQualityToMedium()
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderViewController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      renderViewController.renderQuality = RKRenderQuality.medium
    }
  }
  
  func updateAmbientOcclusion()
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderViewController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      renderViewController.updateAmbientOcclusion()
    }
  }
  
  var picture: Data?
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderViewController: RenderViewController = tabViewItem.viewController as? RenderViewController,
       let project: ProjectStructureNode = proxyProject?.representedObject.loadedProjectStructureNode
    {
      let size: NSSize = NSMakeSize(2048.0,CGFloat(rint(2048.0/aspectRatioValue)))
      let imageData: Data = renderViewController.makePicture(size: size, imageQuality: project.renderImageQuality)
      return imageData
    }
    return nil
  }
  
  
  func makePicture()
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderViewController: RenderViewController = tabViewItem.viewController as? RenderViewController,
       let project: ProjectStructureNode = proxyProject?.representedObject.loadedProjectStructureNode
    {
      let size: NSSize = NSMakeSize(CGFloat(project.renderImageNumberOfPixels),CGFloat(rint(Double(project.renderImageNumberOfPixels)/aspectRatioValue)))
      let imageData: Data = renderViewController.makePicture(size: size, imageQuality: project.renderImageQuality)
    
      let savePanel: NSSavePanel = NSSavePanel()
      savePanel.nameFieldStringValue = "picture.tiff"
      savePanel.canSelectHiddenExtension = true
      savePanel.allowedFileTypes = ["tiff"]
      
      let exportPictureAccessoryViewController: ExportPictureAccessoryViewController = ExportPictureAccessoryViewController(nibName: "ExportPictureAccessoryViewController", bundle: Bundle.main)
      
      savePanel.accessoryView = exportPictureAccessoryViewController.view
    
      savePanel.beginSheetModal(for: self.view.window!, completionHandler: { (result) -> Void in
        if result == NSApplication.ModalResponse.OK
        {
          let selectedFile: URL = savePanel.url!
          try? imageData.write(to: selectedFile, options: [.atomic])
        }
      })
    }
  }
  
  func makeMovie()
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderViewController: RenderViewController = tabViewItem.viewController as? RenderViewController,
       let project: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
    {
      let savePanel: NSSavePanel = NSSavePanel()
      savePanel.nameFieldStringValue = "movie.mp4"
      savePanel.canSelectHiddenExtension = true
      savePanel.allowedFileTypes = ["mp4"]
      
      /*
      let publicationString: NSMutableAttributedString = NSMutableAttributedString(string: "For use in scientific publications, please cite:\n")
      let fontMask: NSFontTraitMask = NSFontTraitMask.boldFontMask
      let stringRange: NSRange = NSMakeRange(0, publicationString.length - 1)
      publicationString.applyFontTraits(fontMask, range: stringRange)
      publicationString.append(NSAttributedString(string: "D. Dubbeldam, S. Calero, and T.J.H. Vlugt,\n \"iRASPA: GPU-Accelerated Visualization Software for Materials Scientists\",\nMol. Simulat., DOI: 10.1080/08927022.2018.1426855, 2018. "))
      
      let foundRange: NSRange = publicationString.mutableString.range(of: "10.1080/08927022.2018.1426855")
      
      if foundRange.location != NSNotFound
      {
        publicationString.addAttribute(NSAttributedStringKey.link, value: "http://dx.doi.org/10.1080/08927022.2018.1426855", range: foundRange)
      }
      
      let accessoryView: NSView = NSView(frame: NSMakeRect(0.0, 0.0, 600, 70.0))
      let textView: NSTextView = NSTextView(frame: NSMakeRect(0.0, 0.0, 600, 70.0))
      textView.drawsBackground = true
      textView.isEditable = false
      textView.textStorage?.setAttributedString(publicationString)
      accessoryView.addSubview(textView)
      savePanel.accessoryView = textView
      */
      
      let exportPictureAccessoryViewController: ExportPictureAccessoryViewController = ExportPictureAccessoryViewController(nibName: "ExportPictureAccessoryViewController", bundle: Bundle.main)
      
      savePanel.accessoryView = exportPictureAccessoryViewController.view
    
      savePanel.beginSheetModal(for: self.view.window!, completionHandler: { (result) -> Void in
        if result == NSApplication.ModalResponse.OK
        {
          if let selectedFile: URL = savePanel.url,
             let maximumNumberOfFrames = project.sceneList.maximumNumberOfFrames
          {
            let ratio: Double = self.aspectRatioValue
            let sizeX: Int = Int(project.renderImageNumberOfPixels)
            let sizeY: Int = Int(0.5 + Double(project.renderImageNumberOfPixels)/ratio)
          
            let movie: RKMovieCreator = RKMovieCreator(url: selectedFile, width: sizeX, height: sizeY, framesPerSecond: project.numberOfFramesPerSecond , provider: renderViewController)
          
            
            let savedSelection = project.sceneList.selection
            
            movie.beginEncoding()
            project.sceneList.setAllMovieFramesToBeginning()
            self.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: project.renderStructures)
            for _ in 0..<maximumNumberOfFrames
            {
              // only recompute ambient occlusion when there is more than 1 frame in the movie to avoid flickering
              // when there are two movie in a scene we need to recompute all anyway
              self.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: project.renderStructures)
              renderViewController.reloadData(ambientOcclusionQuality: .picture)
              movie.addFrameToVideo()
              project.sceneList.advanceAllMovieFrames()
            }
          
            movie.endEncoding()
            
            project.sceneList.selection = savedSelection
            
            if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure}), !renderStructures.isEmpty
            {
              self.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
            }
          
            self.reloadData()
            self.redraw()
          }
        }
      })
    }
  }
  
  // MARK: keyboard handling
  // ===============================================================================================================================
  
  
 
  
  public override func keyDown(with theEvent: NSEvent)
  {
    self.interpretKeyEvents([theEvent])
  }
  
  public override func deleteBackward(_ sender: Any?)
  {
    self.deleteSelection()
  }
  
  public override func deleteForward(_ sender: Any?)
  {
    self.deleteSelection()
  }
  
  public override func selectAll(_ sender: Any?)
  {
    if  let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      for structure in project.allStructures
      {
        self.setCurrentSelection(structure: structure, selection: Set(structure.atoms.flattenedNodes()), from: structure.atoms.selectedTreeNodes)
      }
    }
  }
   
  
  func deleteSelectedAtomsFor(structure: Structure, atoms: [SKAtomTreeNode], bonds: [SKBondNode], from indexPaths: [IndexPath])
  {
    if  let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.undoManager.registerUndo(withTarget: self, handler: {$0.insertSelectedAtomsIn(structure: structure, atoms: atoms.reversed(), bonds: bonds, at: indexPaths.reversed())})
      
      for bond in bonds
      {
        bond.atom1.bonds.remove(bond)
        bond.atom2.bonds.remove(bond)
        structure.bonds.arrangedObjects.remove(bond)
      }
      
      for atom in atoms
      {
        structure.atoms.removeNode(atom)
      }
      
      structure.tag(atoms: structure.atoms)
      structure.atoms.selectedTreeNodes = []
      
      self.proxyProject?.representedObject.isEdited = true
      
      self.invalidateIsosurface(cachedIsosurfaces: [structure])
      self.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      self.renderViewController.reloadData()
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.RendererSelectionDidChangeNotification), object: structure)
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: structure)
      
      (self.view as? RenderTabView)?.evaluateSelectionAnimation()
      
      clearMeasurement()
    }
  }
  
  
  
  func insertSelectedAtomsIn(structure: Structure, atoms: [SKAtomTreeNode], bonds: [SKBondNode], at indexPaths: [IndexPath])
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.undoManager.registerUndo(withTarget: self, handler: {$0.deleteSelectedAtomsFor(structure: structure, atoms: atoms.reversed(), bonds: bonds, from: indexPaths.reversed())})
      
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Insert atoms", comment:"Insert atoms"))
      }
      
    
      for (index, atom) in atoms.enumerated()
      {
        structure.atoms.insertNode(atom, atArrangedObjectIndexPath: indexPaths[index])
        structure.atoms.selectedTreeNodes.insert(atom)
      }
    
      structure.tag(atoms: structure.atoms)
    
      for bond in bonds
      {
        bond.atom1.bonds.insert(bond)
        bond.atom2.bonds.insert(bond)
        structure.bonds.arrangedObjects.insert(bond)
      }
    
      project.isEdited = true
    
      self.invalidateIsosurface(cachedIsosurfaces: [structure])
    self.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      self.renderViewController.reloadData()
    
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.RendererSelectionDidChangeNotification), object: structure)
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: structure)
    
      (self.view as? RenderTabView)?.evaluateSelectionAnimation()
    }
  }
  
  
  
  
  func deleteSelectedAtomsFor(deletedData: [AtomsChangeDataStructure])
  {
    if  let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.undoManager.registerUndo(withTarget: self, handler: {$0.insertSelectedAtomsIn(insertedData: deletedData.map{$0.reversed()})})
      
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Delete atoms", comment:"Delete atoms"))
      }
      
      for data in deletedData
      {
        for bond in data.selectedBonds
        {
          bond.atom1.bonds.remove(bond)
          bond.atom2.bonds.remove(bond)
          data.structure.bonds.arrangedObjects.remove(bond)
        }
        
        for atom in data.atoms
        {
          data.structure.atoms.removeNode(atom)
        }
        
        data.structure.tag(atoms: data.structure.atoms)
        data.structure.atoms.selectedTreeNodes = []
        
        project.isEdited = true
        
        showTransformationPanel(oldSelectionEmpty: false, newSelectionEmpty: true)
        
        self.invalidateIsosurface(cachedIsosurfaces: [data.structure])
        self.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [data.structure])
        
        NotificationCenter.default.post(name: Notification.Name(NotificationStrings.RendererSelectionDidChangeNotification), object: data.structure)
        NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: data.structure)
      }
      self.renderViewController.reloadData()
      
      (self.view as? RenderTabView)?.evaluateSelectionAnimation()
      
      clearMeasurement()
    }
  }
  
  
  func insertSelectedAtomsIn(insertedData: [AtomsChangeDataStructure])
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.undoManager.registerUndo(withTarget: self, handler: {$0.deleteSelectedAtomsFor(deletedData: insertedData.map{$0.reversed()})})
      
      if !project.undoManager.isUndoing
      {
        project.undoManager.setActionName(NSLocalizedString("Insert atoms", comment:"Insert atoms"))
      }
      
      for data in insertedData
      {
        for (index, atom) in data.atoms.enumerated()
        {
          data.structure.atoms.insertNode(atom, atArrangedObjectIndexPath: data.indexPaths[index])
          data.structure.atoms.selectedTreeNodes.insert(atom)
        }
      
        data.structure.tag(atoms: data.structure.atoms)
      
        for bond in data.selectedBonds
        {
          bond.atom1.bonds.insert(bond)
          bond.atom2.bonds.insert(bond)
          data.structure.bonds.arrangedObjects.insert(bond)
        }
        
        showTransformationPanel(oldSelectionEmpty: true, newSelectionEmpty: false)
      
        self.proxyProject?.representedObject.isEdited = true
      
        self.invalidateIsosurface(cachedIsosurfaces: [data.structure])
        self.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [data.structure])
        
        NotificationCenter.default.post(name: Notification.Name(NotificationStrings.RendererSelectionDidChangeNotification), object: data.structure)
        NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: data.structure)
      }
      self.renderViewController.reloadData()
      
      (self.view as? RenderTabView)?.evaluateSelectionAnimation()
    }
  }
  
  
  
  
  func deleteSelection()
  {
    if let project: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode,
       let proxyProject: ProjectTreeNode = proxyProject, proxyProject.isEnabled
    {
      
      var deleteData: [AtomsChangeDataStructure] = []
      for scene: Scene in project.sceneList.scenes
      {
        for movie in scene.movies
        {
          for structure in movie.allStructures
          {
            // sort the selected nodes accoording to the index-paths
            // the deepest nodes should be deleted first!
            let selectedAtoms: [SKAtomTreeNode] = structure.atoms.selectedTreeNodes.sorted(by: { $0.indexPath > $1.indexPath })
            let indexPaths: [IndexPath] = selectedAtoms.map{$0.indexPath}
            let selectedBonds: [SKBondNode] = structure.atoms.allSelectedNodes.compactMap{$0.representedObject}.flatMap{$0.copies}.flatMap{$0.bonds}
            
            let data: AtomsChangeDataStructure = AtomsChangeDataStructure(structure: structure, atoms: selectedAtoms, selectedBonds: selectedBonds, indexPaths: indexPaths)
            
            deleteData.append(data)
          }
        }
      }
      if !deleteData.isEmpty
      {
        project.undoManager.beginUndoGrouping()
        deleteSelectedAtomsFor(deletedData: deleteData)
        //project.undoManager.setActionName(NSLocalizedString("Delete selection", comment:"Delete selection"))
        project.undoManager.endUndoGrouping()
      
        (self.view as? RenderTabView)?.evaluateSelectionAnimation()
      }
    }
  }
  
  // MARK: selection
  // ===============================================================================================================================
  
  func showTransformationPanel(oldSelectionEmpty: Bool, newSelectionEmpty: Bool)
  {
    switch(oldSelectionEmpty,newSelectionEmpty)
    {
    case (true,false):
      // show view
      self.transformationPanel?.isHidden = false
      self.transformationPanel?.layer?.opacity = 0.0
      self.transformationPanelLeftLayoutConstraint?.constant = -20
      NSAnimationContext.runAnimationGroup ({ [weak self] (context: NSAnimationContext) in
        context.timingFunction = CAMediaTimingFunction(name: .easeIn)
        context.duration = 0.25
        context.allowsImplicitAnimation = true
        self?.transformationPanelLeftLayoutConstraint?.animator().constant = ancherDistance
        self?.transformationPanel?.animator().layer?.opacity = 1.0
      }) {}
    case (false,true):
      // hide view
      transformationPanelLeftLayoutConstraint?.constant = ancherDistance
      NSAnimationContext.runAnimationGroup ({ [weak self] (context: NSAnimationContext) in
        context.timingFunction = CAMediaTimingFunction(name: .easeIn)
        context.duration = 0.25
        context.allowsImplicitAnimation = true
        transformationPanel?.animator().layer?.opacity = 0.0
        self?.transformationPanelLeftLayoutConstraint?.animator().constant = -20
        })
      {
        self.transformationPanel?.isHidden = true
        self.transformationPanel?.layer?.opacity = 0.0
      }
    case (true,true):
      // hide view
      self.transformationPanel?.isHidden = true
      self.transformationPanel?.layer?.opacity = 0.0
      self.transformationPanelLeftLayoutConstraint?.constant = -20
    case (false,false):
      // show view
      self.transformationPanel?.layer?.opacity = 1.0
      self.transformationPanel?.isHidden = false
      self.transformationPanelLeftLayoutConstraint?.constant = ancherDistance
    }
  }
 
  func setCurrentSelection(structure: Structure, selection: Set<SKAtomTreeNode>, from: Set<SKAtomTreeNode>)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      // save off the current selectedNode and current selection for undo/redo
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setCurrentSelection(structure: structure, selection: from, from: selection)})
      project.undoManager.setActionName(NSLocalizedString("Change selection", comment: "Change selection"))
   
      showTransformationPanel(oldSelectionEmpty: structure.atoms.selectedTreeNodes.isEmpty,newSelectionEmpty: selection.isEmpty)
      
      structure.atoms.selectedTreeNodes = selection
      
      structure.recomputeSelectionBodyFixedBasis(index: -1)
    
      self.renderViewController.reloadRenderDataSelectedAtoms()
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.RendererSelectionDidChangeNotification), object: structure)
    }
  }
  
  
  public func clearSelectionFor(structure: Structure)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.undoManager.setActionName(NSLocalizedString("Clear selection", comment: "Clear selection"))
      self.setCurrentSelection(structure: structure, selection: [], from: structure.atoms.selectedTreeNodes)
  
      (self.view as? RenderTabView)?.evaluateSelectionAnimation()
    }
  }
  
  public func setAtomSelectionFor(structure: Structure, indexSet: IndexSet, byExtendingSelection extending: Bool)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      var selectedTreeNodes: Set<SKAtomTreeNode> = structure.atoms.selectedTreeNodes
      if (!extending)
      {
        selectedTreeNodes = []
      }
      let numberOfReplicas: Int = structure.numberOfReplicas()
      let nodes: [SKAtomTreeNode] = structure.atoms.flattenedLeafNodes()
    
      let atoms: [SKAtomCopy] = nodes.compactMap{$0.representedObject}.flatMap{$0.copies}.filter{$0.type == .copy}
    
      for index in indexSet
      {
        // take replicas into account
        selectedTreeNodes.insert(nodes[atoms[index / numberOfReplicas].asymmetricIndex])
      }
    
      if selectedTreeNodes != structure.atoms.selectedTreeNodes
      {
        project.undoManager.setActionName(NSLocalizedString("Change selection", comment: "Change selection"))
        self.setCurrentSelection(structure: structure, selection: selectedTreeNodes, from: structure.atoms.selectedTreeNodes)
      }
    
      (self.view as? RenderTabView)?.evaluateSelectionAnimation()
    }
  }
  
  public func addAtomToSelectionFor(structure: Structure, indexSet: IndexSet)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
    var selectedTreeNodes: Set<SKAtomTreeNode> = structure.atoms.selectedTreeNodes
    
    let numberOfReplicas: Int = structure.numberOfReplicas()
    let nodes: [SKAtomTreeNode] = structure.atoms.flattenedLeafNodes()
    
      let atoms: [SKAtomCopy] = nodes.compactMap{$0.representedObject}.flatMap{$0.copies}.filter{$0.type == .copy}
    
    for index in indexSet
    {
      // take replicas into account
      selectedTreeNodes.insert(nodes[atoms[index / numberOfReplicas].asymmetricIndex])
    }
    project.undoManager.setActionName(NSLocalizedString("Add atom(s) to selection", comment: "Add atom(s) to selection"))
    self.setCurrentSelection(structure: structure, selection: selectedTreeNodes, from: structure.atoms.selectedTreeNodes)
    
    (self.view as? RenderTabView)?.evaluateSelectionAnimation()
    }
  }
  
  
  public func toggleAtomSelectionFor(structure: Structure, indexSet: IndexSet)
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
    let numberOfReplicas: Int = structure.numberOfReplicas()
    
    var selectedTreeNodes: Set<SKAtomTreeNode> = structure.atoms.selectedTreeNodes
    
    let nodes: [SKAtomTreeNode] = structure.atoms.flattenedLeafNodes()
      let atoms: [SKAtomCopy] = nodes.compactMap{$0.representedObject}.flatMap{$0.copies}.filter{$0.type == .copy}
    
    for index in indexSet
    {
      let treeNode: SKAtomTreeNode = nodes[atoms[index / numberOfReplicas].asymmetricIndex]
      if (structure.atoms.selectedTreeNodes.contains(treeNode))
      {
        selectedTreeNodes.remove(treeNode)
      }
      else
      {
        selectedTreeNodes.insert(treeNode)
      }
    }
    
    project.undoManager.setActionName(NSLocalizedString("Toggle atom selection", comment: "Toggle atom selection"))
    self.setCurrentSelection(structure: structure, selection: selectedTreeNodes, from: structure.atoms.selectedTreeNodes)
    
    (self.view as? RenderTabView)?.evaluateSelectionAnimation()
    }
  }
  
  @IBAction func selectionInversion(_ sender: NSMenuItem)
  {
    if let project: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode,
      let proxyProject: ProjectTreeNode = proxyProject, proxyProject.isEnabled
    {
      project.undoManager.beginUndoGrouping()
      for scene: Scene in project.sceneList.scenes
      {
        for movie in scene.movies
        {
          for structure in movie.allStructures
          {
            if structure.isVisible
            {
              let selectedTreeNodes = structure.atoms.invertedSelection
              self.setCurrentSelection(structure: structure, selection: selectedTreeNodes, from: structure.atoms.selectedTreeNodes)
            }
          }
        }
      }
      project.undoManager.setActionName(NSLocalizedString("Invert selection", comment:"Invert selection"))
      project.undoManager.endUndoGrouping()
      
      (self.view as? RenderTabView)?.evaluateSelectionAnimation()
    }
  }
  
  // MARK: RKRenderViewSelectionDelegate protocol measurements
  // ===============================================================================================================================
  
  
  
  func clearMeasurement()
  {
    if let project: ProjectStructureNode = proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.measurementTreeNodes = []
      self.renderViewController.reloadRenderMeasurePointsData()
      self.renderViewController.redraw()
    }
  }

  func addAtomToMeasurement(_ pick: [Int32])
  {
    if (pick[0] == 1)
    {
      if let project: ProjectStructureNode = proxyProject?.representedObject.loadedProjectStructureNode
      {
        let structureIdentifier: Int = Int(pick[1])
        let movieIdentifier: Int = Int(pick[2])
        let pickedAtom: Int = Int(pick[3])
        
        let structures: [RKRenderStructure] = project.renderStructuresForScene(structureIdentifier)
        let structure: RKRenderStructure = structures[movieIdentifier]
        let replicaPosition: SIMD3<Int32> = structure.cell.replicaFromIndex(pickedAtom)
        
        let numberOfReplicas: Int = (structure as! Structure).numberOfReplicas()
        let nodes: [SKAtomTreeNode] = (structure as! Structure).atoms.flattenedLeafNodes()
          
        let atoms: [SKAtomCopy] = nodes.compactMap{$0.representedObject}.flatMap{$0.copies}.filter{$0.type == .copy}
        
        if project.measurementTreeNodes.count < 4
        {
          let node: SKAtomCopy = atoms[pickedAtom / numberOfReplicas]
          let atomInfo = (structure, node, replicaPosition)
          project.measurementTreeNodes.append(atomInfo)
        }
        
        
        if project.measurementTreeNodes.count == 2
        {
          let distance: Double = (structure as! Structure).distance(project.measurementTreeNodes[0], project.measurementTreeNodes[1])
          LogQueue.shared.info(destination: self.windowController, message: "Distance between atoms [\(project.measurementTreeNodes[0].copy.tag), \(project.measurementTreeNodes[1].copy.tag)] is \(distance)")
        }
        else if project.measurementTreeNodes.count == 3
        {
            let distance1: Double = (structure as! Structure).distance(project.measurementTreeNodes[0], project.measurementTreeNodes[1])
            let distance2: Double = (structure as! Structure).distance(project.measurementTreeNodes[1], project.measurementTreeNodes[2])
            let bendAngle: Double = (structure as! Structure).bendAngle(project.measurementTreeNodes[0], project.measurementTreeNodes[1], project.measurementTreeNodes[2])
          LogQueue.shared.info(destination: self.windowController, message: "Distances between atoms [\(project.measurementTreeNodes[0].copy.tag), \(project.measurementTreeNodes[1].copy.tag), \(project.measurementTreeNodes[2].copy.tag)] are \(distance1), \(distance2); Bend angle between the atoms is \(bendAngle * 180.0/Double.pi)")
        }
        else if project.measurementTreeNodes.count == 4
        {
          let distance1: Double = (structure as! Structure).distance(project.measurementTreeNodes[0], project.measurementTreeNodes[1])
          let distance2: Double = (structure as! Structure).distance(project.measurementTreeNodes[1], project.measurementTreeNodes[2])
          let distance3: Double = (structure as! Structure).distance(project.measurementTreeNodes[2], project.measurementTreeNodes[3])
          let bendAngle1: Double = (structure as! Structure).bendAngle(project.measurementTreeNodes[0], project.measurementTreeNodes[1], project.measurementTreeNodes[2])
          let bendAngle2: Double = (structure as! Structure).bendAngle(project.measurementTreeNodes[1], project.measurementTreeNodes[2], project.measurementTreeNodes[3])
          let dihedralAngle: Double = (structure as! Structure).dihedralAngle(project.measurementTreeNodes[0],project.measurementTreeNodes[1], project.measurementTreeNodes[2], project.measurementTreeNodes[3])
          LogQueue.shared.info(destination: self.windowController, message: "Distances between atoms [\(project.measurementTreeNodes[0].copy.tag), \(project.measurementTreeNodes[1].copy.tag), \(project.measurementTreeNodes[2].copy.tag), \(project.measurementTreeNodes[3].copy.tag)] are \(distance1), \(distance2) \(distance3); Bend angles between the atoms are \(bendAngle1 * 180.0/Double.pi), \(bendAngle2 * 180.0/Double.pi); Dihedral angle between the atoms is \(dihedralAngle * 180.0/Double.pi)")
        }
        
        self.renderViewController.reloadRenderMeasurePointsData()
        self.renderViewController.redraw()
      }
    }
  }
  
  // MARK: RKRenderViewSelectionDelegate protocol
  // ===============================================================================================================================
  
  // undo for large-changes: completely replace all atoms and bonds by new ones
  func setStructureState(structure: Structure, atoms: SKAtomTreeController, bonds: SKBondSetController)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
      let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let oldAtoms: SKAtomTreeController = structure.atoms
      let oldBonds: SKBondSetController = structure.bonds
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setStructureState(structure: structure, atoms: oldAtoms, bonds: oldBonds)})
      
      structure.atoms = atoms
      structure.bonds = bonds
      
      structure.reComputeBoundingBox()
      
      structure.setRepresentationColorScheme(scheme: structure.atomColorSchemeIdentifier, colorSets: document.colorSets)
      structure.setRepresentationForceField(forceField: structure.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)
      
      self.invalidateIsosurface(cachedIsosurfaces: [structure])
      self.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [])
      
      self.reloadData()
      self.redraw()
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.AtomsShouldReloadNotification), object: structure)
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: structure)
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.SpaceGroupShouldReloadNotification), object: self.windowController)
    }
  }
  
  func selectInRectangle(_ rect: NSRect, inViewPort bounds: NSRect, byExtendingSelection extending: Bool)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let camera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        let structure: RKRenderStructure = crystalProjectData.renderStructures[i]
        if let structure: RKRenderAtomSource = structure as? RKRenderAtomSource,
           structure.isVisible
        {
          let indexSet: IndexSet = camera.selectPositionsInRectangle(structure.atomPositions, inRect: rect, withOrigin: structure.origin, inViewPort: bounds)
        
          self.setAtomSelectionFor(structure: structure as! Structure, indexSet: indexSet, byExtendingSelection: extending)
        }
      }
      self.reloadRenderDataSelectedAtoms()
      
      
    }
  }
  
  func setAtomToSelection(_ pick: [Int32])
  {
    if (pick[0] == 1)
    {
      if let crystalProjectData: RKRenderDataSource = self.renderDataSource
      {
        let structureIdentifier: Int = Int(pick[1])
        let movieIdentifier: Int = Int(pick[2])
        let pickedAtom: Int = Int(pick[3])
        
        let structures: [RKRenderStructure] = crystalProjectData.renderStructuresForScene(structureIdentifier)
        let structure: RKRenderStructure = structures[movieIdentifier]
        
        if structure.isVisible
        {
          self.setAtomSelectionFor(structure: structure as! Structure, indexSet: IndexSet(integer: pickedAtom), byExtendingSelection: false)
          self.reloadRenderDataSelectedAtoms()
          NotificationCenter.default.post(name: Notification.Name(NotificationStrings.RendererSelectionDidChangeNotification), object: windowController)
        }
      }
    }
  }
  
  func addAtomToSelection(_ pick: [Int32])
  {
    if (pick[0] == 1)
    {
      if let crystalProjectData: RKRenderDataSource = self.renderDataSource
      {
        let structureIdentifier: Int = Int(pick[1])
        let movieIdentifier: Int = Int(pick[2])
        let pickedAtom: Int = Int(pick[3])
        
        let structures: [RKRenderStructure] = crystalProjectData.renderStructuresForScene(structureIdentifier)
        let structure: RKRenderStructure = structures[movieIdentifier]
        
        if structure.isVisible
        {
          self.addAtomToSelectionFor(structure: structure as! Structure, indexSet: IndexSet(integer: pickedAtom))
          self.reloadRenderDataSelectedAtoms()
          NotificationCenter.default.post(name: Notification.Name(NotificationStrings.RendererSelectionDidChangeNotification), object: windowController)
        }
      }
    }
  }
  
  func toggleAtomSelection(_ pick: [Int32])
  {
    if (pick[0] == 1)
    {
      if let crystalProjectData: RKRenderDataSource = self.renderDataSource
      {
        let structureIdentifier: Int = Int(pick[1])
        let movieIdentifier: Int = Int(pick[2])
        let pickedAtom: Int = Int(pick[3])
        
        let structures: [RKRenderStructure] = crystalProjectData.renderStructuresForScene(structureIdentifier)
        let structure: RKRenderStructure = structures[movieIdentifier]
        
        if structure.isVisible
        {
          self.toggleAtomSelectionFor(structure: structure as! Structure, indexSet: IndexSet(integer: pickedAtom))
          self.reloadRenderDataSelectedAtoms()
          NotificationCenter.default.post(name: Notification.Name(NotificationStrings.RendererSelectionDidChangeNotification), object: windowController)
        }
      }
    }

  }
  
  func clearSelection()
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        let structure: RKRenderStructure = crystalProjectData.renderStructures[i]
        self.setAtomSelectionFor(structure: structure as! Structure, indexSet: IndexSet(), byExtendingSelection: false)
      }
      self.reloadRenderDataSelectedAtoms()
      
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.RendererSelectionDidChangeNotification), object: windowController)
    }
  }
  
  func cameraDidChange()
  {
    let notification: Notification = Notification(name: Notification.Name(NotificationStrings.CameraDidChangeNotification), object: windowController)
    NotificationQueue(notificationCenter: NotificationCenter.default).enqueue(notification, postingStyle: NotificationQueue.PostingStyle.whenIdle)
  }
  
  func shiftSelection(to: SIMD3<Double>, origin: SIMD3<Double>, depth: Double)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
       let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let camera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure
        {
          let modelMatrix: double4x4 =  double4x4(transformation: double4x4(simd_quatd: structure.orientation), aroundPoint: structure.cell.boundingBox.center)

          let shift: SIMD3<Double> = camera.myGluUnProject(SIMD3<Double>(x: to.x, y: to.y, z: depth), modelMatrix: modelMatrix,  inViewPort: self.view.bounds) - camera.myGluUnProject(SIMD3<Double>(x: origin.x, y: origin.y, z: depth), modelMatrix: modelMatrix, inViewPort: self.view.bounds)
          
          structure.translateSelection(by: shift)
        }
        
      }
      self.reloadRenderDataSelectedAtoms()
    }
  }
  
  func finalizeShiftSelection(to: SIMD3<Double>, origin: SIMD3<Double>, depth: Double)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
       let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
       let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode,
       let camera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure
        {
          let modelMatrix: double4x4 =  double4x4(transformation: double4x4(simd_quatd: structure.orientation), aroundPoint: structure.cell.boundingBox.center)
          
          let shift: SIMD3<Double> = camera.myGluUnProject(SIMD3<Double>(x: to.x, y: to.y, z: depth), modelMatrix: modelMatrix, inViewPort: self.view.bounds) - camera.myGluUnProject(SIMD3<Double>(x: origin.x, y: origin.y, z: depth), modelMatrix: modelMatrix, inViewPort: self.view.bounds)
          
          
          project.undoManager.setActionName(NSLocalizedString("Displace selection", comment: "Displace selection"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.finalizeTranslateSelection(by: shift)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
        
      }
    }
  }
  
  func modifyAtomsFor(structure: Structure)
  {
    if  let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.undoManager.registerUndo(withTarget: self, handler: {$0.modifyAtomsFor(structure: structure)})
    }
  }
  
  func rotateSelection(by: SIMD3<Double>)
  {
    
  }
  
  
  
  // MARK: Context Menu
  // ===============================================================================================================================
  
  func menuNeedsUpdate(_ menu: NSMenu)
  {
    
  }
  
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
  {
    if (menuItem.action == #selector(copy(_:)))
    {
      return true
    }
    
    if (menuItem.action == #selector(paste(_:)))
    {
      return true
    }
    
    if (menuItem.action == #selector(cut(_:)))
    {
      return true
    }
    
    if (menuItem.action == #selector(setCameraToOrthographic))
    {
      if let _: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode,
         let camera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
      {
        menuItem.state = (camera.frustrumType == .perspective) ? NSControl.StateValue.off : NSControl.StateValue.on
        return true
      }
      return true
    }
    
    if (menuItem.action == #selector(setCameraToPerspective))
    {
      if let _: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode,
         let camera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
      {
        menuItem.state = (camera.frustrumType == .perspective) ? NSControl.StateValue.on : NSControl.StateValue.off
        return true
      }
      return false
    }
    
    if (menuItem.action == #selector(resetCamera))
    {
      if let _: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode,
         let _ = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
      {
        return true
      }
      return false
    }
    
    if (menuItem.action == #selector(resetCameraToX))
    {
      if let _: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode,
        let _ = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
      {
        return true
      }
      return false
    }
    
    if (menuItem.action == #selector(resetCameraToY))
    {
      if let _: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode,
        let _ = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
      {
        return true
      }
      return false
    }
    
    if (menuItem.action == #selector(resetCameraToZ))
    {
      if let _: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode,
        let _ = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
      {
        return true
      }
      return false
    }
    
    if (menuItem.action == #selector(toggleBoundingBox))
    {
      if let project: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
      {
        menuItem.state = (project.showBoundingBox == true) ? NSControl.StateValue.on : NSControl.StateValue.off
        return true
      }
      return false
    }
      
    if (menuItem.action == #selector(selectionInversion(_:)))
    {
      if let _: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
      {
        return true
      }
      return false
    }
    
    if (menuItem.action == #selector(exportToCIF(_:)))
    {
      if let _: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
      {
        return true
      }
      return false
    }
    
    if (menuItem.action == #selector(exportToPDB(_:)))
    {
      if let _: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
      {
        return true
      }
      return false
    }
    
    if (menuItem.action == #selector(exportToXYZ(_:)))
    {
      if let _: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
      {
        return true
      }
      return false
    }
    
    if (menuItem.action == #selector(exportToVASP(_:)))
    {
      if let _: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
      {
        return true
      }
      return false
    }
    
    if (menuItem.action == #selector(computeHighQualityAmbientOcclusion))
    {
      if let _: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
      {
        return true
      }
      return false
    }

    return true
  }
  
  @IBAction func resetCamera(_ sender: NSMenuItem)
  {
    if let project: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
    {
      // recompute bounding-box
      project.renderCamera?.boundingBox = project.renderBoundingBox
      project.renderCamera?.resetCameraDistance()
      self.cameraDidChange()
      
      self.renderViewController.redraw()
    }
  }
  
  @IBAction func resetCameraToX(_ sender: NSMenuItem)
  {
    if let project: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
    {
      // recompute bounding-box
      project.renderCamera?.boundingBox = project.renderBoundingBox
      project.renderCamera?.resetDirectionType = .plus_X
      project.renderCamera?.resetCameraToDirection()
      project.renderCamera?.resetCameraDistance()
      self.cameraDidChange()
      
      self.renderViewController.redraw()
    }
  }
  
  @IBAction func resetCameraToY(_ sender: NSMenuItem)
  {
    if let project: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
    {
      // recompute bounding-box
      project.renderCamera?.boundingBox = project.renderBoundingBox
      project.renderCamera?.resetDirectionType = .plus_Y
      project.renderCamera?.resetCameraToDirection()
      project.renderCamera?.resetCameraDistance()
      self.cameraDidChange()
      
      self.renderViewController.redraw()
    }
  }
  
  @IBAction func resetCameraToZ(_ sender: NSMenuItem)
  {
    if let project: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
    {
      // recompute bounding-box
      project.renderCamera?.boundingBox = project.renderBoundingBox
      project.renderCamera?.resetDirectionType = .plus_Z
      project.renderCamera?.resetCameraToDirection()
      project.renderCamera?.resetCameraDistance()
      self.cameraDidChange()
      
      self.renderViewController.redraw()
    }
  }
  
  @IBAction func toggleBoundingBox(_ sender: NSMenuItem)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
       let cameraBoundingBoxMenuItem = cameraBoundingBoxMenuItem
    {
      if cameraBoundingBoxMenuItem.state == .off
      {
        cameraBoundingBoxMenuItem.state = .on
        crystalProjectData.showBoundingBox = true
      }
      else
      {
        cameraBoundingBoxMenuItem.state = .off
        crystalProjectData.showBoundingBox = false
      }
      self.renderViewController.redraw()
    }
  }
  
 
  
  @IBAction func setCameraToOrthographic(_ sender: NSMenuItem)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      renderCamera.setCameraToOrthographic()
      self.cameraDidChange()
      self.renderViewController.redraw()
    }
  }
  
  @objc func setCameraToPerspective(_ sender: NSMenuItem)
  {
    if let renderCamera: RKCamera = (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera
    {
      renderCamera.setCameraToPerspective()
      self.cameraDidChange()
      
      self.renderViewController.redraw()
    }
  }
  
  @IBAction func computeHighQualityAmbientOcclusion(_ sender: NSMenuItem)
  {
    self.renderViewController.invalidateCachedAmbientOcclusionTextures()
    self.renderViewController.reloadData(ambientOcclusionQuality: .picture)
    self.renderViewController.redraw()
  }
  
  @IBAction func exportToPDB(_ sender: NSMenuItem)
  {
    if let project: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
    {
      let savePanel: NSSavePanel = NSSavePanel()
      savePanel.nameFieldStringValue = "\(project.displayName)-pdbs"
      savePanel.canSelectHiddenExtension = true
      
      let attributedString: NSAttributedString = NSAttributedString(string: "Note: Precision was lost when converting to PDB-format.")
      let accessoryView: NSView = NSView(frame: NSMakeRect(0.0, 0.0, 400, 20.0))
      let textView: NSTextView = NSTextView(frame: NSMakeRect(0.0, 2.0, 400, 16.0))
      textView.drawsBackground = false
      textView.isEditable = false
      textView.textStorage?.setAttributedString(attributedString)
      accessoryView.addSubview(textView)
      savePanel.accessoryView = textView
      
      
      savePanel.beginSheetModal(for: self.view.window!, completionHandler: { (result) -> Void in
        if result == NSApplication.ModalResponse.OK
        {
          if let url = savePanel.url
          {
            do
            {
              let fileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers: [:])
              var usedFileNames: [String: (sceneId: Int, fileWrapper: FileWrapper)] = [:]
              let scenes: [Scene] = project.sceneList.scenes
              for (i,scene) in scenes.enumerated()
              {
                var proposedFileName: String = scene.displayName
                if let nameCollision = usedFileNames[proposedFileName.lowercased()]
                {
                  let nameCollisionFileWrapper = nameCollision.fileWrapper
                  fileWrapper.removeFileWrapper(nameCollisionFileWrapper)
                  nameCollisionFileWrapper.preferredFilename = proposedFileName + "-\(nameCollision.sceneId)"
                  fileWrapper.addFileWrapper(nameCollisionFileWrapper)
                  proposedFileName += "-\(i)"
                }
                
                let subDirectoryFileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers: [:])
                subDirectoryFileWrapper.preferredFilename = proposedFileName
                fileWrapper.addFileWrapper(subDirectoryFileWrapper)
                usedFileNames[proposedFileName.lowercased()] = (i, subDirectoryFileWrapper)
                
                var atomData: [[(spaceGroupHallNumber: Int?, cell: SKCell?, atoms: [SKAsymmetricAtom])]] = []
                for movie in scene.movies
                {
                  var tempData: [(spaceGroupHallNumber: Int?, cell: SKCell?, atoms: [SKAsymmetricAtom])] = []
                  for structure in movie.allStructures
                  {
                    let state: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.superCell
                    
                    let exportAtoms: [SKAsymmetricAtom] = state.atoms.flattenedLeafNodes().compactMap{$0.representedObject}.compactMap({ (atomModel) -> SKAsymmetricAtom? in
                      let atom = atomModel
                      atom.position = structure.CartesianPosition(for: atomModel.position, replicaPosition: SIMD3<Int32>())
                      return atom
                    })
                    let exportCell: SKCell? = structure.periodic ? structure.cell : nil
                    
                    tempData.append((spaceGroupHallNumber: 1, cell: exportCell, atoms: exportAtoms))
                  }
                  atomData.append(tempData)
                }
                
                let string = SKPDBWriter.shared.string(displayName: scene.displayName, movies: atomData, origin: SIMD3<Double>(0,0,0))
                
                if let data = string.data(using: .ascii)
                {
                  let wrapper: FileWrapper = FileWrapper(regularFileWithContents: data)
                  wrapper.preferredFilename = scene.displayName + ".pdb"
                  subDirectoryFileWrapper.addFileWrapper(wrapper)
                }
              }
      
              try fileWrapper.write(to: url, options: FileWrapper.WritingOptions.atomic, originalContentsURL: nil)
            }
            catch
            {
              
            }
          }
        }
      })
    }
  }
  
  @IBAction func exportToMMCIF(_ sender: NSMenuItem)
  {
    if let project: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
    {
      let savePanel: NSSavePanel = NSSavePanel()
      savePanel.nameFieldStringValue = "\(project.displayName)-mmcifs"
      savePanel.canSelectHiddenExtension = true
      
      
      savePanel.beginSheetModal(for: self.view.window!, completionHandler: { (result) -> Void in
        if result == NSApplication.ModalResponse.OK
        {
          if let url = savePanel.url
          {
            do
            {
              let mainFileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers: [:])
              let scenes: [Scene] = project.sceneList.scenes
              
              var usedSceneFileNames: [String: (sceneId: Int, fileWrapper: FileWrapper)] = [:]
              for (i,scene) in scenes.enumerated()
              {
                var proposedSceneFileName: String = scene.displayName
                if let nameCollision = usedSceneFileNames[proposedSceneFileName.lowercased()]
                {
                  let nameCollisionFileWrapper = nameCollision.fileWrapper
                  mainFileWrapper.removeFileWrapper(nameCollisionFileWrapper)
                  nameCollisionFileWrapper.preferredFilename = proposedSceneFileName + "-\(nameCollision.sceneId)"
                  mainFileWrapper.addFileWrapper(nameCollisionFileWrapper)
                  proposedSceneFileName += "-\(i)"
                }
                
                let sceneFileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers: [:])
                sceneFileWrapper.preferredFilename = proposedSceneFileName
                mainFileWrapper.addFileWrapper(sceneFileWrapper)
                usedSceneFileNames[proposedSceneFileName.lowercased()] = (i, sceneFileWrapper)
                
                var usedMovieFileNames: [String: (movieId: Int, fileWrapper: FileWrapper)] = [:]
                for (j,movie) in scene.movies.enumerated()
                {
                  var proposedMovieFileName: String = movie.displayName
                  if let nameCollision = usedMovieFileNames[proposedMovieFileName.lowercased()]
                  {
                    let nameCollisionFileWrapper = nameCollision.fileWrapper
                    sceneFileWrapper.removeFileWrapper(nameCollisionFileWrapper)
                    nameCollisionFileWrapper.preferredFilename = proposedMovieFileName + "-\(nameCollision.movieId)"
                    sceneFileWrapper.addFileWrapper(nameCollisionFileWrapper)
                    proposedMovieFileName += "-\(j)"
                  }
                  
                  let movieFileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers: [:])
                  movieFileWrapper.preferredFilename = proposedMovieFileName
                  sceneFileWrapper.addFileWrapper(movieFileWrapper)
                  usedMovieFileNames[proposedMovieFileName.lowercased()] = (j, movieFileWrapper)
                  
                  for (k,iRASPAstructure) in movie.frames.enumerated()
                  {
                    let structure = iRASPAstructure.structure
                    let atoms: [SKAsymmetricAtom] = structure.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
                    
                    let stringData: String
                    switch(structure)
                    {
                    case let crystal as Crystal:
                      stringData = SKmmCIFWriter.shared.string(displayName: crystal.displayName, spaceGroupHallNumber: crystal.spaceGroupHallNumber, cell: crystal.cell, atoms: atoms, atomsAreFractional: true, exportFractional: false, withProteinInfo: false, origin: SIMD3<Double>(0,0,0))
                    case let proteinCrystal as ProteinCrystal:
                      stringData = SKmmCIFWriter.shared.string(displayName: proteinCrystal.displayName, spaceGroupHallNumber: proteinCrystal.spaceGroupHallNumber, cell: proteinCrystal.cell, atoms: atoms, atomsAreFractional: false, exportFractional: false, withProteinInfo: true, origin: SIMD3<Double>(0,0,0))
                    case let molecularCrystal as MolecularCrystal:
                      stringData = SKmmCIFWriter.shared.string(displayName: molecularCrystal.displayName, spaceGroupHallNumber: molecularCrystal.spaceGroupHallNumber, cell: molecularCrystal.cell, atoms: atoms, atomsAreFractional: false, exportFractional: false, withProteinInfo: false, origin: SIMD3<Double>(0,0,0))
                    case let protein as Protein:
                      let boundingBox = protein.cell.boundingBox
                      stringData = SKmmCIFWriter.shared.string(displayName: protein.displayName, spaceGroupHallNumber: protein.spaceGroupHallNumber, cell: SKCell(boundingBox: boundingBox), atoms: atoms, atomsAreFractional: false, exportFractional: false, withProteinInfo: true, origin: boundingBox.minimum)
                    case let molecule as Molecule:
                      let boundingBox = molecule.cell.boundingBox
                      stringData = SKmmCIFWriter.shared.string(displayName: molecule.displayName, spaceGroupHallNumber: molecule.spaceGroupHallNumber, cell: SKCell(boundingBox: boundingBox), atoms: atoms, atomsAreFractional: false, exportFractional: false, withProteinInfo: false, origin: boundingBox.minimum)
                    default:
                      stringData = ""
                      break
                    }
                      
                    if let data = stringData.data(using: .ascii)
                    {
                      let wrapper: FileWrapper = FileWrapper(regularFileWithContents: data)
                      wrapper.preferredFilename = "frame" + "-\(k)" + ".cif"
                      movieFileWrapper.addFileWrapper(wrapper)
                    }
                  }
                }
              }
              
              try mainFileWrapper.write(to: url, options: FileWrapper.WritingOptions.atomic, originalContentsURL: nil)
            }
            catch
            {
              
            }
          }
        }
      })
    }
  }
  
  @IBAction func exportToCIF(_ sender: NSMenuItem)
  {
    if let project: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
    {
      let savePanel: NSSavePanel = NSSavePanel()
      savePanel.nameFieldStringValue = "\(project.displayName)-cifs"
      savePanel.canSelectHiddenExtension = true
      
      
      savePanel.beginSheetModal(for: self.view.window!, completionHandler: { (result) -> Void in
        if result == NSApplication.ModalResponse.OK
        {
          if let url = savePanel.url
          {
            do
            {
              let mainFileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers: [:])
              let scenes: [Scene] = project.sceneList.scenes
              
              var usedSceneFileNames: [String: (sceneId: Int, fileWrapper: FileWrapper)] = [:]
              for (i,scene) in scenes.enumerated()
              {
                var proposedSceneFileName: String = scene.displayName
                if let nameCollision = usedSceneFileNames[proposedSceneFileName.lowercased()]
                {
                  let nameCollisionFileWrapper = nameCollision.fileWrapper
                  mainFileWrapper.removeFileWrapper(nameCollisionFileWrapper)
                  nameCollisionFileWrapper.preferredFilename = proposedSceneFileName + "-\(nameCollision.sceneId)"
                  mainFileWrapper.addFileWrapper(nameCollisionFileWrapper)
                  proposedSceneFileName += "-\(i)"
                }
                
                let sceneFileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers: [:])
                sceneFileWrapper.preferredFilename = proposedSceneFileName
                mainFileWrapper.addFileWrapper(sceneFileWrapper)
                usedSceneFileNames[proposedSceneFileName.lowercased()] = (i, sceneFileWrapper)
                
                var usedMovieFileNames: [String: (movieId: Int, fileWrapper: FileWrapper)] = [:]
                for (j,movie) in scene.movies.enumerated()
                {
                  var proposedMovieFileName: String = movie.displayName
                  if let nameCollision = usedMovieFileNames[proposedMovieFileName.lowercased()]
                  {
                    let nameCollisionFileWrapper = nameCollision.fileWrapper
                    sceneFileWrapper.removeFileWrapper(nameCollisionFileWrapper)
                    nameCollisionFileWrapper.preferredFilename = proposedMovieFileName + "-\(nameCollision.movieId)"
                    sceneFileWrapper.addFileWrapper(nameCollisionFileWrapper)
                    proposedMovieFileName += "-\(j)"
                  }
                  
                  let movieFileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers: [:])
                  movieFileWrapper.preferredFilename = proposedMovieFileName
                  sceneFileWrapper.addFileWrapper(movieFileWrapper)
                  usedMovieFileNames[proposedMovieFileName.lowercased()] = (j, movieFileWrapper)
                  
                  for (k,iRASPAstructure) in movie.frames.enumerated()
                  {
                    let structure = iRASPAstructure.structure
                    
                    let atoms: [SKAsymmetricAtom] = structure.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
                    
                    let stringData: String
                    switch(structure)
                    {
                    case let crystal as Crystal:
                      stringData = SKCIFWriter.shared.string(displayName: crystal.displayName, spaceGroupHallNumber: crystal.spaceGroupHallNumber, cell: crystal.cell, atoms: atoms, exportFractional: true, origin: SIMD3<Double>(0,0,0))
                    case let proteinCrystal as ProteinCrystal:
                      stringData = SKCIFWriter.shared.string(displayName: proteinCrystal.displayName, spaceGroupHallNumber: proteinCrystal.spaceGroupHallNumber, cell: proteinCrystal.cell, atoms: atoms, exportFractional: false, origin: SIMD3<Double>(0,0,0))
                    case let molecularCrystal as MolecularCrystal:
                      stringData = SKCIFWriter.shared.string(displayName: molecularCrystal.displayName, spaceGroupHallNumber: molecularCrystal.spaceGroupHallNumber, cell: molecularCrystal.cell, atoms: atoms, exportFractional: false, origin: SIMD3<Double>(0,0,0))
                    case let protein as Protein:
                      let boundingBox = protein.cell.boundingBox
                      stringData = SKCIFWriter.shared.string(displayName: protein.displayName, spaceGroupHallNumber: protein.spaceGroupHallNumber, cell: SKCell(boundingBox: boundingBox), atoms: atoms, exportFractional: false, origin: boundingBox.minimum)
                    case let molecule as Molecule:
                      let boundingBox = molecule.cell.boundingBox
                      stringData = SKCIFWriter.shared.string(displayName: molecule.displayName, spaceGroupHallNumber: molecule.spaceGroupHallNumber, cell: SKCell(boundingBox: boundingBox), atoms: atoms, exportFractional: false, origin: boundingBox.minimum)
                    default:
                      stringData = ""
                      break
                    }
                    
                    if let data = stringData.data(using: .ascii)
                    {
                      let wrapper: FileWrapper = FileWrapper(regularFileWithContents: data)
                      wrapper.preferredFilename = "frame" + "-\(k)" + ".cif"
                      movieFileWrapper.addFileWrapper(wrapper)
                    }
                  }
                }
              }
              
              try mainFileWrapper.write(to: url, options: FileWrapper.WritingOptions.atomic, originalContentsURL: nil)
            }
            catch
            {
              
            }
          }
        }
      })
    }
  }
  
  
  
  @IBAction func exportToXYZ(_ sender: NSMenuItem)
  {
    if let project: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
    {
      let savePanel: NSSavePanel = NSSavePanel()
      savePanel.nameFieldStringValue = "\(project.displayName)-xyzs"
      savePanel.canSelectHiddenExtension = true
      
      let attributedString: NSAttributedString = NSAttributedString(string: "Note: Any information on the unit-cell is lost.")
      let accessoryView: NSView = NSView(frame: NSMakeRect(0.0, 0.0, 400, 20.0))
      let textView: NSTextView = NSTextView(frame: NSMakeRect(0.0, 2.0, 400, 16.0))
      textView.drawsBackground = false
      textView.isEditable = false
      textView.textStorage?.setAttributedString(attributedString)
      accessoryView.addSubview(textView)
      savePanel.accessoryView = textView
      
      savePanel.beginSheetModal(for: self.view.window!, completionHandler: { (result) -> Void in
        if result == NSApplication.ModalResponse.OK
        {
          if let url = savePanel.url
          {
            do
            {
              let mainFileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers: [:])
              let scenes: [Scene] = project.sceneList.scenes
              
              var usedSceneFileNames: [String: (sceneId: Int, fileWrapper: FileWrapper)] = [:]
              for (i,scene) in scenes.enumerated()
              {
                var proposedSceneFileName: String = scene.displayName
                if let nameCollision = usedSceneFileNames[proposedSceneFileName.lowercased()]
                {
                  let nameCollisionFileWrapper = nameCollision.fileWrapper
                  mainFileWrapper.removeFileWrapper(nameCollisionFileWrapper)
                  nameCollisionFileWrapper.preferredFilename = proposedSceneFileName + "-\(nameCollision.sceneId)"
                  mainFileWrapper.addFileWrapper(nameCollisionFileWrapper)
                  proposedSceneFileName += "-\(i)"
                }
                
                let sceneFileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers: [:])
                sceneFileWrapper.preferredFilename = proposedSceneFileName
                mainFileWrapper.addFileWrapper(sceneFileWrapper)
                usedSceneFileNames[proposedSceneFileName.lowercased()] = (i, sceneFileWrapper)
                
                var usedMovieFileNames: [String: (movieId: Int, fileWrapper: FileWrapper)] = [:]
                for (j,movie) in scene.movies.enumerated()
                {
                  var proposedMovieFileName: String = movie.displayName
                  if let nameCollision = usedMovieFileNames[proposedMovieFileName.lowercased()]
                  {
                    let nameCollisionFileWrapper = nameCollision.fileWrapper
                    sceneFileWrapper.removeFileWrapper(nameCollisionFileWrapper)
                    nameCollisionFileWrapper.preferredFilename = proposedMovieFileName + "-\(nameCollision.movieId)"
                    sceneFileWrapper.addFileWrapper(nameCollisionFileWrapper)
                    proposedMovieFileName += "-\(j)"
                  }
                  
                  let movieFileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers: [:])
                  movieFileWrapper.preferredFilename = proposedMovieFileName
                  sceneFileWrapper.addFileWrapper(movieFileWrapper)
                  usedMovieFileNames[proposedMovieFileName.lowercased()] = (j, movieFileWrapper)
                  
                  var movieStringData: String = ""
                  for (k,iRASPAstructure) in movie.frames.enumerated()
                  {
                    let structure = iRASPAstructure.structure
                    
                    let exportAtoms: [(elementIdentifier: Int, position: SIMD3<Double>)] = structure.atoms.flattenedLeafNodes().compactMap{$0.representedObject}.compactMap({ (atomModel) -> (elementIdentifier: Int, position: SIMD3<Double>)? in
                      let position = structure.CartesianPosition(for: atomModel.position, replicaPosition: SIMD3<Int32>())
                      return (atomModel.elementIdentifier, position)
                    })
                    
                    let stringData: String
                    switch(structure)
                    {
                    case let crystal as Crystal:
                      let unitCell = crystal.cell.unitCell
                      let commentString = "Lattice=\"\(unitCell[0][0]) \(unitCell[0][1]) \(unitCell[0][2]) \(unitCell[1][0]) \(unitCell[1][1]) \(unitCell[1][2]) \(unitCell[2][0]) \(unitCell[2][1]) \(unitCell[2][2])\" "
                      stringData = SKXYZWriter.shared.string(displayName: crystal.displayName, commentString: commentString, atoms: exportAtoms, origin: SIMD3<Double>(0,0,0))
                    case let proteinCrystal as ProteinCrystal:
                      let unitCell = proteinCrystal.cell.unitCell
                      let commentString = "Lattice=\"\(unitCell[0][0]) \(unitCell[0][1]) \(unitCell[0][2]) \(unitCell[1][0]) \(unitCell[1][1]) \(unitCell[1][2]) \(unitCell[2][0]) \(unitCell[2][1]) \(unitCell[2][2])\" "
                      stringData = SKXYZWriter.shared.string(displayName: proteinCrystal.displayName, commentString: commentString, atoms: exportAtoms, origin: SIMD3<Double>(0,0,0))
                    case let molecularCrystal as MolecularCrystal:
                      let unitCell = molecularCrystal.cell.unitCell
                      let commentString = "Lattice=\"\(unitCell[0][0]) \(unitCell[0][1]) \(unitCell[0][2]) \(unitCell[1][0]) \(unitCell[1][1]) \(unitCell[1][2]) \(unitCell[2][0]) \(unitCell[2][1]) \(unitCell[2][2])\" "
                      stringData = SKXYZWriter.shared.string(displayName: molecularCrystal.displayName, commentString: commentString, atoms: exportAtoms, origin: SIMD3<Double>(0,0,0))
                    case let protein as Protein:
                      let boundingBox = protein.cell.boundingBox
                      let unitCell = SKCell(boundingBox: boundingBox).unitCell
                      let commentString = "Lattice=\"\(unitCell[0][0]) \(unitCell[0][1]) \(unitCell[0][2]) \(unitCell[1][0]) \(unitCell[1][1]) \(unitCell[1][2]) \(unitCell[2][0]) \(unitCell[2][1]) \(unitCell[2][2])\" "
                      stringData = SKXYZWriter.shared.string(displayName: protein.displayName, commentString: commentString, atoms: exportAtoms, origin: boundingBox.minimum)
                    case let molecule as Molecule:
                      let boundingBox = molecule.cell.boundingBox
                      let unitCell = SKCell(boundingBox: boundingBox).unitCell
                      let commentString = "Lattice=\"\(unitCell[0][0]) \(unitCell[0][1]) \(unitCell[0][2]) \(unitCell[1][0]) \(unitCell[1][1]) \(unitCell[1][2]) \(unitCell[2][0]) \(unitCell[2][1]) \(unitCell[2][2])\" "
                      stringData = SKXYZWriter.shared.string(displayName: molecule.displayName, commentString: commentString, atoms: exportAtoms, origin: boundingBox.minimum)
                    default:
                      stringData = ""
                      break
                    }
                    
                    
                    
                    movieStringData += stringData
                    
                    if let data = stringData.data(using: .ascii)
                    {
                      let wrapper: FileWrapper = FileWrapper(regularFileWithContents: data)
                      wrapper.preferredFilename = "frame" + "-\(k)" + ".xyz"
                      movieFileWrapper.addFileWrapper(wrapper)
                    }
                  }
                  if let data = movieStringData.data(using: .ascii)
                  {
                    let wrapper: FileWrapper = FileWrapper(regularFileWithContents: data)
                    wrapper.preferredFilename = movie.displayName + "-all" + ".xyz"
                    movieFileWrapper.addFileWrapper(wrapper)
                  }
                }
              }
              
              try mainFileWrapper.write(to: url, options: FileWrapper.WritingOptions.atomic, originalContentsURL: nil)
            }
            catch
            {
              
            }
          }
        }
      })
    }
  }
  
  @IBAction func exportToVASP(_ sender: NSMenuItem)
  {
    if let project: ProjectStructureNode = self.renderDataSource as? ProjectStructureNode
    {
      let savePanel: NSSavePanel = NSSavePanel()
      savePanel.nameFieldStringValue = "\(project.displayName)-poscars"
      savePanel.canSelectHiddenExtension = true
      
      savePanel.beginSheetModal(for: self.view.window!, completionHandler: { (result) -> Void in
        if result == NSApplication.ModalResponse.OK
        {
          if let url = savePanel.url
          {
            do
            {
              let mainFileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers: [:])
              let scenes: [Scene] = project.sceneList.scenes
              
              var usedSceneFileNames: [String: (sceneId: Int, fileWrapper: FileWrapper)] = [:]
              for (i,scene) in scenes.enumerated()
              {
                var proposedSceneFileName: String = scene.displayName
                if let nameCollision = usedSceneFileNames[proposedSceneFileName.lowercased()]
                {
                  let nameCollisionFileWrapper = nameCollision.fileWrapper
                  mainFileWrapper.removeFileWrapper(nameCollisionFileWrapper)
                  nameCollisionFileWrapper.preferredFilename = proposedSceneFileName + "-\(nameCollision.sceneId)"
                  mainFileWrapper.addFileWrapper(nameCollisionFileWrapper)
                  proposedSceneFileName += "-\(i)"
                }
                
                let sceneFileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers: [:])
                sceneFileWrapper.preferredFilename = proposedSceneFileName
                mainFileWrapper.addFileWrapper(sceneFileWrapper)
                usedSceneFileNames[proposedSceneFileName.lowercased()] = (i, sceneFileWrapper)
                
                var usedMovieFileNames: [String: (movieId: Int, fileWrapper: FileWrapper)] = [:]
                for (j,movie) in scene.movies.enumerated()
                {
                  var proposedMovieFileName: String = movie.displayName
                  if let nameCollision = usedMovieFileNames[proposedMovieFileName.lowercased()]
                  {
                    let nameCollisionFileWrapper = nameCollision.fileWrapper
                    sceneFileWrapper.removeFileWrapper(nameCollisionFileWrapper)
                    nameCollisionFileWrapper.preferredFilename = proposedMovieFileName + "-\(nameCollision.movieId)"
                    sceneFileWrapper.addFileWrapper(nameCollisionFileWrapper)
                    proposedMovieFileName += "-\(j)"
                  }
                  
                  let movieFileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers: [:])
                  movieFileWrapper.preferredFilename = proposedMovieFileName
                  sceneFileWrapper.addFileWrapper(movieFileWrapper)
                  usedMovieFileNames[proposedMovieFileName.lowercased()] = (j, movieFileWrapper)
                  
                  var movieStringData: String = ""
                  for (k,iRASPAstructure) in movie.frames.enumerated()
                  {
                    let structure = iRASPAstructure.structure
                    
                    let asymmetricAtoms: [SKAsymmetricAtom] = structure.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
                    let atomCopies: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
                    
                    let stringData: String
                    switch(structure)
                    {
                    case let crystal as Crystal:
                      let atoms: [(Int, SIMD3<Double>, Bool3)] = atomCopies.compactMap{($0.asymmetricParentAtom.elementIdentifier, fract($0.position), $0.asymmetricParentAtom.isFixed)}
                      stringData = SKVASPWriter.shared.string(displayName: crystal.displayName, cell: crystal.cell , atoms: atoms, atomsAreFractional: true, origin: SIMD3<Double>(0,0,0))
                    case let proteinCrystal as ProteinCrystal:
                      let atoms: [(Int, SIMD3<Double>, Bool3)] = atomCopies.compactMap{($0.asymmetricParentAtom.elementIdentifier, fract($0.position), $0.asymmetricParentAtom.isFixed)}
                      stringData = SKVASPWriter.shared.string(displayName: proteinCrystal.displayName, cell: proteinCrystal.cell, atoms: atoms, atomsAreFractional: false, origin: SIMD3<Double>(0,0,0))
                    case let crystal as MolecularCrystal:
                      let atoms: [(Int, SIMD3<Double>, Bool3)] = atomCopies.compactMap{($0.asymmetricParentAtom.elementIdentifier, $0.position, $0.asymmetricParentAtom.isFixed)}
                      stringData = SKVASPWriter.shared.string(displayName: crystal.displayName, cell: crystal.cell, atoms: atoms, atomsAreFractional: false, origin: SIMD3<Double>(0,0,0))
                    case let protein as Protein:
                      let boundingBox = protein.cell.boundingBox
                      let atoms: [(Int, SIMD3<Double>, Bool3)] = atomCopies.compactMap{($0.asymmetricParentAtom.elementIdentifier, $0.position, $0.asymmetricParentAtom.isFixed)}
                      stringData = SKVASPWriter.shared.string(displayName: protein.displayName, cell: SKCell(boundingBox: boundingBox), atoms: atoms, atomsAreFractional: false, origin: boundingBox.minimum)
                    case let molecule as Molecule:
                      let boundingBox = molecule.cell.boundingBox
                      let atoms: [(Int, SIMD3<Double>, Bool3)] = atomCopies.compactMap{($0.asymmetricParentAtom.elementIdentifier, $0.position, $0.asymmetricParentAtom.isFixed)}
                      stringData = SKVASPWriter.shared.string(displayName: molecule.displayName, cell: SKCell(boundingBox: boundingBox), atoms: atoms, atomsAreFractional: false, origin: boundingBox.minimum)
                    default:
                      stringData = ""
                      break
                    }
                    
                    movieStringData += stringData
                    
                    if let data = stringData.data(using: .ascii)
                    {
                      let wrapper: FileWrapper = FileWrapper(regularFileWithContents: data)
                      wrapper.preferredFilename = "frame" + "-\(k)" + ".poscar"
                      movieFileWrapper.addFileWrapper(wrapper)
                    }
                  }
                  if let data = movieStringData.data(using: .ascii)
                  {
                    let wrapper: FileWrapper = FileWrapper(regularFileWithContents: data)
                    wrapper.preferredFilename = movie.displayName + "-all" + ".poscar"
                    movieFileWrapper.addFileWrapper(wrapper)
                  }
                }
              }
              
              try mainFileWrapper.write(to: url, options: FileWrapper.WritingOptions.atomic, originalContentsURL: nil)
            }
            catch
            {
              
            }
          }
        }
      })
    }
  }
  
  public func computeHeliumVoidFraction(structures: [RKRenderStructure])
  {
    self.renderViewController.computeVoidFractions(structures: structures)
  }
  
  public func computeNitrogenSurfaceArea(structures: [RKRenderStructure])
  {
    self.renderViewController.computeNitrogenSurfaceArea(structures: structures)
  }
  
 
  @objc func view(_ view: NSView, stringForToolTip tag: NSView.ToolTipTag, point: NSPoint, userData data: UnsafeMutableRawPointer?) -> String
  {
    
    let pick: [Int32] =  self.renderViewController.pickPoint(point)
    
    if (pick[0] == 1)
    {
      if let crystalProjectData: RKRenderDataSource = self.renderDataSource
      {
        let structureIdentifier: Int = Int(pick[1])
        let movieIdentifier: Int = Int(pick[2])
        let pickedAtom: Int = Int(pick[3])
        
        let structures: [RKRenderStructure] = crystalProjectData.renderStructuresForScene(structureIdentifier)
        let structure: RKRenderStructure = structures[movieIdentifier]
        
        
        if let structure = structure as? Structure
        {
          let numberOfReplicas: Int = structure.numberOfReplicas()
          let nodes: [SKAtomTreeNode] = structure.atoms.flattenedLeafNodes()
          let atoms: [SKAtomCopy] = nodes.compactMap{$0.representedObject}.flatMap{$0.copies}.filter{$0.type == .copy}
          
          let atom: SKAtomCopy = atoms[pickedAtom / numberOfReplicas]
          
          return "structure: \(structure.displayName), atom: \(atom.asymmetricIndex) (\(atom.asymmetricParentAtom.displayName)), position: \(atom.position.x), \(atom.position.y), \(atom.position.z)"
        }
      }
    }
    return ""
  }

  func pickPoint(_ point: NSPoint) ->  [Int32]
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      return renderController.pickPoint(point)
    }
    return [0,0,0,0]
  }
  
  func pickDepth(_ point: NSPoint) ->  Float?
  {
    let selectedTabViewIndex: Int = self.selectedTabViewItemIndex
    let tabViewItem: NSTabViewItem = self.tabViewItems[selectedTabViewIndex]
    if let renderController: RenderViewController = tabViewItem.viewController as? RenderViewController
    {
      return renderController.pickDepth(point)
    }
    return nil
  }
  
  public override func mouseDown(with event: NSEvent)
  {
    startPoint = self.view.convert(event.locationInWindow, from: nil)
    if let view: RenderTabView = self.view as? RenderTabView,
       let layer: CALayer = view.layer
    {
      if (event.modifierFlags.contains(NSEvent.ModifierFlags.shift))
      {
        tracking = .newSelection
        view.shapeLayerNewSelection.path = CGMutablePath()
        layer.addSublayer(view.shapeLayerNewSelection)
      }
      //else if theEvent.modifierFlags.contains(.option)
      // {
      //tracking = .panning
      // }
      else if event.modifierFlags.contains(NSEvent.ModifierFlags.command) &&
             !event.modifierFlags.contains(NSEvent.ModifierFlags.option)
      {
        tracking = .addToSelection
      
        view.shapeLayerAddSelection.path = CGMutablePath()
        layer.addSublayer(view.shapeLayerAddSelection)
      
        // create animation for the layer
        let dashAnimation:CABasicAnimation = CABasicAnimation(keyPath: "lineDashPhase")
        dashAnimation.fromValue = 0.0
        dashAnimation.toValue = 15.0
        dashAnimation.duration = 0.75
        dashAnimation.repeatCount = Float.infinity
        view.shapeLayerAddSelection.add(dashAnimation, forKey:"linePhase")
      }
      else if event.modifierFlags.contains(NSEvent.ModifierFlags.option) &&
              event.modifierFlags.contains(NSEvent.ModifierFlags.command)
      {
        tracking = .translateSelection
        pickedDepth = pickDepth(startPoint!)
      }
      else if event.modifierFlags.contains(NSEvent.ModifierFlags.option) &&
            !event.modifierFlags.contains(NSEvent.ModifierFlags.command)
      {
        tracking = .measurement
      }
      else
      {
        tracking = .backgroundClick
      }
    }
  }
  
  public override func mouseDragged(with event: NSEvent)
  {
    let location: NSPoint  = self.view.convert(event.locationInWindow, from: nil)
    if let view: RenderTabView = self.view as? RenderTabView
    {
      switch(tracking)
      {
      case .newSelection:
        tracking = .draggedNewSelection
      case .addToSelection:
        tracking = .draggedAddToSelection
      case .draggedNewSelection:
        tracking = .draggedNewSelection
        if let startPoint = startPoint
        {
          let path: CGMutablePath  = CGMutablePath()
        
          path.move(to: CGPoint(x: startPoint.x, y: startPoint.y))
          path.addLine(to: CGPoint(x: startPoint.x, y: location.y))
          path.addLine(to: CGPoint(x: location.x, y: location.y))
          path.addLine(to: CGPoint(x: location.x, y: startPoint.y))
          path.closeSubpath()
        
          // set the shape layer's path
          view.shapeLayerNewSelection.path = path
        }
      case .draggedAddToSelection:
        tracking = .draggedAddToSelection
      
        if let startPoint = startPoint
        {
          let path: CGMutablePath  = CGMutablePath()
        
          path.move(to: CGPoint(x: startPoint.x, y: startPoint.y))
          path.addLine(to: CGPoint( x: startPoint.x, y: location.y))
          path.addLine(to: CGPoint(x: location.x, y: location.y))
          path.addLine(to: CGPoint(x: location.x, y: startPoint.y))
          path.closeSubpath()
        
          // set the shape layer's path
          view.shapeLayerAddSelection.path = path
        }
      case .translateSelection:
         if let point = startPoint,
            let pickedDepth = pickedDepth
         {
           shiftSelection(to: SIMD3<Double>(Double(location.x),Double(location.y),0.0), origin: SIMD3<Double>(Double(point.x),Double(point.y),0.0), depth: Double(pickedDepth))
         }
      case .measurement:
        if let _ = startPoint
        {
          cameraDidChange()
        }
      default:
        tracking = .other
        if let _ = startPoint
        {
          cameraDidChange()
        }
      }
    }
  }
  
  override func mouseUp(with theEvent: NSEvent)
  {
    let point: NSPoint = view.convert(theEvent.locationInWindow, from: nil)
    
    if let view: RenderTabView = self.view as? RenderTabView,
       let layer: CALayer = view.layer
    {
      switch(tracking)
      {
      case .newSelection:
        view.shapeLayerNewSelection.removeFromSuperlayer()
        clearSelection()
      
        if let _: RKRenderDataSource = renderDataSource
        {
          let pick: [Int32] = pickPoint(point)
          if (pick[0] > 0)
          {
            addAtomToSelection(pick)
          }
        }
      case .addToSelection:
        view.shapeLayerAddSelection.removeAnimation(forKey: "linePhase")
        view.shapeLayerAddSelection.removeFromSuperlayer()
      
        if let _: RKRenderDataSource = renderDataSource
        {
          let pick: [Int32] = pickPoint(point)
          if (pick[0] > 0)
          {
            toggleAtomSelection(pick)
          }
        }
      case .draggedNewSelection:
        if let startPoint = startPoint
        {
          selectInRectangle(NSMakeRect(startPoint.x,startPoint.y,point.x-startPoint.x,point.y-startPoint.y), inViewPort: layer.bounds, byExtendingSelection: false)
        }
        view.shapeLayerNewSelection.removeFromSuperlayer()
      case .draggedAddToSelection:
        if let startPoint = startPoint
        {
          selectInRectangle(NSMakeRect(startPoint.x,startPoint.y,point.x-startPoint.x,point.y-startPoint.y), inViewPort: layer.bounds, byExtendingSelection: true)
        }
      
        view.shapeLayerAddSelection.removeAnimation(forKey: "linePhase")
        view.shapeLayerAddSelection.removeFromSuperlayer()
      case .translateSelection:
        if let startPoint = startPoint,
           let pickedDepth = pickedDepth
        {
          finalizeShiftSelection(to: SIMD3<Double>(Double(point.x),Double(point.y),0.0), origin: SIMD3<Double>(Double(startPoint.x),Double(startPoint.y),0.0), depth: Double(pickedDepth))
        }
      case .measurement:
        if let _: RKRenderDataSource = renderDataSource
        {
          let pick: [Int32] = pickPoint(point)
          if (pick[0] > 0)
          {
            addAtomToMeasurement(pick)
          }
          else
          {
            clearMeasurement()
          }
        }
      default:
        if (tracking == .backgroundClick)
        {
          let pick: [Int32] = pickPoint(point)
          
          if (pick[0]==0)
          {
            clearSelection()
          }
          
          if (pick[0]>0)
          {
            setAtomToSelection(pick)
          }
        }
      }
    
      startPoint = nil
      tracking = .none
    }
  }
  
  /*
  override func flagsChanged(with event: NSEvent)
  {
    debugPrint("changed!! \(event.modifierFlags)")
    super.flagsChanged(with: event)
  }
 */
  
  // MARK: Tranformation Panel
  // ===============================================================================================================================
  @IBAction func deleteSelectedAtoms(_ sender: NSButton)
  {
    self.deleteSelection()
  }
  
  // MARK: translation Cartesian
  
  @IBAction func translateSelectedAtomsCartesianPlusX(_ sender: NSButton)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
           !structure.atoms.selectedTreeNodes.isEmpty
        {
          let shift: SIMD3<Double> = SIMD3<Double>(0.1, 0.0, 0.0)
          
          project.undoManager.setActionName(NSLocalizedString("Displace selection +x", comment: "Displace selection +x"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.translateSelectionCartesian(by: shift)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  @IBAction func translateSelectedAtomsCartesianMinusX(_ sender: NSButton)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          let shift: SIMD3<Double> = SIMD3<Double>(-0.1, 0.0, 0.0)
          
          project.undoManager.setActionName(NSLocalizedString("Displace selection -x", comment: "Displace selection -x"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.translateSelectionCartesian(by: shift)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  @IBAction func translateSelectedAtomsCartesianPlusY(_ sender: NSButton)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          let shift: SIMD3<Double> = SIMD3<Double>(0.0, 0.1, 0.0)
          
          project.undoManager.setActionName(NSLocalizedString("Displace selection +y", comment: "Displace selection +y"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.translateSelectionCartesian(by: shift)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
        
      }
    }
  }
  
  @IBAction func translateSelectedAtomsCartesianMinusY(_ sender: NSButton)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          let shift: SIMD3<Double> = SIMD3<Double>(0.0, -0.1, 0.0)
          
          project.undoManager.setActionName(NSLocalizedString("Displace selection -y", comment: "Displace selection -y"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.translateSelectionCartesian(by: shift)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  @IBAction func translateSelectedAtomsCartesianPlusZ(_ sender: NSButton)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          let shift: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.1)
          
          project.undoManager.setActionName(NSLocalizedString("Displace selection +z", comment: "Displace selection +z"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.translateSelectionCartesian(by: shift)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
        
      }
    }
  }
  
  @IBAction func translateSelectedAtomsCartesianMinusZ(_ sender: NSButton)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          let shift: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, -0.1)
          
          project.undoManager.setActionName(NSLocalizedString("Displace selection -z", comment: "Displace selection -z"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.translateSelectionCartesian(by: shift)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  // MARK: translation molecular frame
  
  @IBAction func translateSelectedAtomsBodyFramePlusX(_ sender: NSButton)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          let shift: SIMD3<Double> = SIMD3<Double>(0.1, 0.0, 0.0)
          
          project.undoManager.setActionName(NSLocalizedString("Displace selection +1", comment: "Displace selection +1"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.translateSelectionBodyFrame(by: shift)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
        
      }
    }
  }
  
  @IBAction func translateSelectedAtomsBodyFrameMinusX(_ sender: NSButton)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          let shift: SIMD3<Double> = SIMD3<Double>(-0.1, 0.0, 0.0)
          
          project.undoManager.setActionName(NSLocalizedString("Displace selection -1", comment: "Displace selection -1"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.translateSelectionBodyFrame(by: shift)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  @IBAction func translateSelectedAtomsBodyFramePlusY(_ sender: NSButton)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          let shift: SIMD3<Double> = SIMD3<Double>(0.0, 0.1, 0.0)
          
          project.undoManager.setActionName(NSLocalizedString("Displace selection +2", comment: "Displace selection +2"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.translateSelectionBodyFrame(by: shift)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
        
      }
    }
  }
  
  @IBAction func translateSelectedAtomsBodyFrameMinusY(_ sender: NSButton)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          let shift: SIMD3<Double> = SIMD3<Double>(0.0, -0.1, 0.0)
          
          project.undoManager.setActionName(NSLocalizedString("Displace selection -2", comment: "Displace selection -2"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.translateSelectionBodyFrame(by: shift)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  @IBAction func translateSelectedAtomsBodyFramePlusZ(_ sender: NSButton)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          let shift: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.1)
          
          project.undoManager.setActionName(NSLocalizedString("Displace selection +3", comment: "Displace selection +3"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.translateSelectionBodyFrame(by: shift)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
        
      }
    }
  }
  
  @IBAction func translateSelectedAtomsBodyFrameMinusZ(_ sender: NSButton)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          let shift: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, -0.1)
          
          project.undoManager.setActionName(NSLocalizedString("Displace selection -3", comment: "Displace selection -3"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.translateSelectionBodyFrame(by: shift)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  // MARK: rotation Cartesian
  
  @IBAction func rotateSelectedAtomsCartesianPlusX(_ sender: NSButton)
  {
    let theta: Double = 2.5 * Double.pi/180.0
    let quaternion: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(1.0,0.0,0.0))
    
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          project.undoManager.setActionName(NSLocalizedString("Rotate selection +x", comment: "Rotate selection +x"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.rotateSelectionCartesian(using: quaternion)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  @IBAction func rotateSelectedAtomsCartesianMinusX(_ sender: NSButton)
  {
    let theta: Double = -2.5 * Double.pi/180.0
    let quaternion: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(1.0,0.0,0.0))
   
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          project.undoManager.setActionName(NSLocalizedString("Rotate selection -x", comment: "Rotate selection -x"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.rotateSelectionCartesian(using: quaternion)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  @IBAction func rotateSelectedAtomsCartesianPlusY(_ sender: NSButton)
  {
    let theta: Double = 2.5 * Double.pi/180.0
    let quaternion: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(0.0,1.0,0.0))
    
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          project.undoManager.setActionName(NSLocalizedString("Rotate selection +y", comment: "Rotate selection +y"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.rotateSelectionCartesian(using: quaternion)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  @IBAction func rotateSelectedAtomsCartesianMinusY(_ sender: NSButton)
  {
    let theta: Double = -2.5 * Double.pi/180.0
    let quaternion: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(0.0,1.0,0.0))
    
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          project.undoManager.setActionName(NSLocalizedString("Rotate selection -y", comment: "Rotate selection -y"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.rotateSelectionCartesian(using: quaternion)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  @IBAction func rotateSelectedAtomsCartesianPlusZ(_ sender: NSButton)
  {
    let theta: Double = 2.5 * Double.pi/180.0
    let quaternion: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(0.0,0.0,1.0))
    
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          project.undoManager.setActionName(NSLocalizedString("Rotate selection +z", comment: "Rotate selection +z"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.rotateSelectionCartesian(using: quaternion)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  @IBAction func rotateSelectedAtomsCartesianMinusZ(_ sender: NSButton)
  {
    let theta: Double = -2.5 * Double.pi/180.0
    let quaternion: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(0.0,0.0,1.0))
    
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          project.undoManager.setActionName(NSLocalizedString("Rotate selection -z", comment: "Rotate selection -z"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.rotateSelectionCartesian(using: quaternion)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  // MARK: rotation molecular frame
  
  @IBAction func rotateSelectedAtomsBodyFramePlusX(_ sender: NSButton)
  {
    let theta: Double = 2.5 * Double.pi/180.0
    let quaternion: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(1.0,0.0,0.0))
    
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          project.undoManager.setActionName(NSLocalizedString("Rotate selection +1", comment: "Rotate selection +1"))
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.rotateSelectionBodyFrame(using: quaternion, index: 0)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  @IBAction func rotateSelectedAtomsBodyFrameMinusX(_ sender: NSButton)
  {
    let theta: Double = -2.5 * Double.pi/180.0
    let quaternion: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(1.0,0.0,0.0))

    
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          project.undoManager.setActionName(NSLocalizedString("Rotate selection -1", comment: "Rotate selection -1"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.rotateSelectionBodyFrame(using: quaternion, index: 0)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  @IBAction func rotateSelectedAtomsBodyFramePlusY(_ sender: NSButton)
  {
    let theta: Double = 2.5 * Double.pi/180.0
    let quaternion: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(0.0,1.0,0.0))
    
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          project.undoManager.setActionName(NSLocalizedString("Rotate selection +2", comment: "Rotate selection +2"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.rotateSelectionBodyFrame(using: quaternion, index: 1)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  @IBAction func rotateSelectedAtomsBodyFrameMinusY(_ sender: NSButton)
  {
    let theta: Double = -2.5 * Double.pi/180.0
    let quaternion: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(0.0,1.0,0.0))
    
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          project.undoManager.setActionName(NSLocalizedString("Rotate selection -2", comment: "Rotate selection -2"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.rotateSelectionBodyFrame(using: quaternion, index: 1)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  @IBAction func rotateSelectedAtomsBodyFramePlusZ(_ sender: NSButton)
  {
    let theta: Double = 2.5 * Double.pi/180.0
    let quaternion: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(0.0,0.0,1.0))
    
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          project.undoManager.setActionName(NSLocalizedString("Rotate selection +3", comment: "Rotate selection +3"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.rotateSelectionBodyFrame(using: quaternion, index: 2)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  @IBAction func rotateSelectedAtomsInertiaMinusZ(_ sender: NSButton)
  {
    let theta: Double = -2.5 * Double.pi/180.0
    let quaternion: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(0.0,0.0,1.0))
    
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
      let proxyProject: ProjectTreeNode = self.proxyProject, proxyProject.isEnabled,
      let project: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      for i in 0..<crystalProjectData.renderStructures.count
      {
        if let structure: Structure = crystalProjectData.renderStructures[i] as? Structure,
          !structure.atoms.selectedTreeNodes.isEmpty
        {
          project.undoManager.setActionName(NSLocalizedString("Rotate selection -3", comment: "Rotate selection -3"))
          
          if let state: (atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.rotateSelectionBodyFrame(using: quaternion, index: 2)
          {
            self.setStructureState(structure: structure, atoms: state.atoms, bonds: state.bonds)
          }
        }
      }
    }
  }
  
  
  // MARK: Copy / Paste / Cut / Delete
  // ===============================================================================================================================
  
  
  @objc func copy(_ sender: AnyObject)
  {
    if let project: ProjectStructureNode = proxyProject?.representedObject.loadedProjectStructureNode
    {
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.writeObjects(project.allStructures.flatMap{$0.readySelectedAtomsForCopyAndPaste()})
    }
  }
  
  @objc func paste(_ sender: AnyObject)
  {
    if let proxyProject: ProjectTreeNode = proxyProject,
       let _: ProjectStructureNode = proxyProject.representedObject.loadedProjectStructureNode
    {
      if !proxyProject.isEditable
      {
        LogQueue.shared.warning(destination: windowController, message: "Paste unsuccesful: project is not editable.")
        return
      }
      
      if !proxyProject.isEnabled
      {
        LogQueue.shared.warning(destination: windowController, message: "Paste unsuccesful: project is temporary disabled.")
        return
      }
      
      
      var insertionData: [AtomsChangeDataStructure] = []
      let pasteboard = NSPasteboard.general
      
      if let atoms: [SKAtomTreeNode] = pasteboard.readObjects(forClasses: [SKAtomTreeNode.self], options: nil) as? [SKAtomTreeNode]
      {
        for structure in structures
        {
          // create new sets of objects for each structure
          let objects: [SKAtomTreeNode] = atoms.copy()
          let asymmetricAtoms: [SKAsymmetricAtom] = objects.map{$0.representedObject}
          if let document: iRASPADocument = self.windowController?.currentDocument
          {
            structure.setRepresentationColorScheme(colorSets: document.colorSets, for: asymmetricAtoms)
            structure.setRepresentationForceField(forceField: structure.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets, for: asymmetricAtoms)
          }
          structure.setRepresentationType(type: structure.atomRepresentationType, for: asymmetricAtoms)
          
          structure.setRepresentationStyle(style: structure.atomRepresentationStyle, for: asymmetricAtoms)
        
          structure.convertToNativePositions(newAtoms: objects)
          let bonds: [SKBondNode] = structure.bonds(newAtoms: objects)
                
          let insertionIndex: Int = structure.atoms.rootNodes.count
          let data = AtomsChangeDataStructure(structure: structure, atoms: objects, selectedBonds: bonds, indexPaths: Array(0..<objects.count).map{IndexPath(index: insertionIndex + $0)})
          insertionData.append(data)
        }
        self.insertSelectedAtomsIn(insertedData:insertionData)
      }
    }
  }
  
  @objc func cut(_ sender: AnyObject)
  {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    
    if let project: ProjectStructureNode = proxyProject?.representedObject.loadedProjectStructureNode
    {
      let nodes: [SKAtomTreeNode] = project.allStructures.flatMap{$0.atoms.selectedNodes}
      pasteboard.writeObjects(nodes)
    }
    self.deleteSelection()
  }
}

