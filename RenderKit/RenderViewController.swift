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

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import MetalKit
import MathKit
import SimulationKit
import SymmetryKit
import AVFoundation
import CoreMedia
import CoreVideo
import LogViewKit

#if os(macOS)
public typealias RenderViewControllerBase = NSViewController
#else
public typealias RenderViewControllerBase = UIViewController
#endif

public class RenderViewController: RenderViewControllerBase, MTKViewDelegate
{
  var device: MTLDevice? = nil
  var computeDevice: MTLDevice? = nil
  var renderCommandQueue: MTLCommandQueue? = nil
  var computeCommandQueue: MTLCommandQueue? = nil
  var defaultLibrary: MTLLibrary? = nil
  var maximumNumberOfSamples: Int = 4
  var renderer: MetalRenderer = MetalRenderer()
  
  let _inflightSemaphore: DispatchSemaphore = DispatchSemaphore(value: 3)
  var constantDataBufferIndex: Int = 0
  var frameUniformBuffers: [MTLBuffer]! = nil

  
  public weak var renderDataSource: RKRenderDataSource? = nil
  {
    didSet
    {
      self.renderer.renderDataSource = renderDataSource
    }
  }
  
  public weak var renderCameraSource: RKRenderCameraSource? = nil
  {
    didSet
    {
      (self.view as? MetalView)?.renderCameraSource = renderCameraSource
    }
  }
  
  // MARK: -
  // MARK: Initialization
  
  #if os(macOS)
  override public init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?)
  {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  convenience  init()
  {
    self.init(nibName: nil, bundle: Bundle(for: RenderViewController.self))
  }
  #else
  public init()
  {
    super.init(nibName: nil, bundle: nil)
  }

  public override func loadView()
  {
    let metalView = MetalView(frame: UIScreen.main.bounds, device: MTLCreateSystemDefaultDevice())
    metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view = metalView
  }
  #endif
  
  // called when present in a NIB-file
  public required init?(coder aDecoder: NSCoder)
  {
    super.init(coder: aDecoder)
  }
  
  deinit
  {
    // clean up and avoid crashing the app due to waiting semaphores
    for _ in 0...3
    {
      self._inflightSemaphore.signal()
    }
  }
  
  // MARK: -
  // MARK: View lifecyle
  
  public override func viewDidLoad()
  {
    super.viewDidLoad()
    
    (self.view as? MTKView)?.delegate = self
    
    if let view: MetalView = self.view as? MetalView
    {
      view.onCycleRibbonAODebugMode = {[weak self] in self?.cycleRibbonAODebugMode()}
    }

    // switching the Rendering menu between rasterization and ray tracing has to repaint
    NotificationCenter.default.addObserver(forName: Notification.Name(RKRenderSettings.RenderModeDidChange), object: nil, queue: OperationQueue.main)
    {[weak self] _ in
      self?.redraw()
    }
    
    // the metal default library is not in mainBundle, but in the local framework bundle
    let bundle: Bundle = Bundle(for: MetalView.self)
    
    if let newDevice = MTLCreateSystemDefaultDevice()
    {
      var library: MTLLibrary? = nil
      if let url = bundle.url(forResource: "default", withExtension: "metallib")
      {
        library = try? newDevice.makeLibrary(URL: url)
      }
      if library == nil, let file = bundle.path(forResource: "default", ofType: "metallib")
      {
        library = try? newDevice.makeLibrary(filepath: file)
      }
      if let library
      {
      self.device = newDevice
      self.renderCommandQueue = newDevice.makeCommandQueue()
      self.defaultLibrary = library
      
      (self.view as? MTKView)?.device = newDevice
    
      #if os(macOS)
      let devices: [MTLDevice] = MTLCopyAllDevices().filter{!$0.isEqual(device) && !$0.isLowPower}
      self.computeDevice = devices.first ?? device
      #else
      self.computeDevice = newDevice
      #endif
      self.computeCommandQueue = self.computeDevice?.makeCommandQueue()

      // detect the maximum MSAA
      for i in [32,16,8,4,2,1]
      {
        if (newDevice.supportsTextureSampleCount(i))
        {
          self.maximumNumberOfSamples = i
          break
        }
      }
      #if os(iOS)
      self.maximumNumberOfSamples = min(self.maximumNumberOfSamples, 4)
      #endif
      }
    }
    
    if let device = self.device,
       let buffer1: MTLBuffer = device.makeBuffer(length: MemoryLayout<RKTransformationUniforms>.stride, options: RKMetal.hostStorage),
       let buffer2: MTLBuffer = device.makeBuffer(length: MemoryLayout<RKTransformationUniforms>.stride, options: RKMetal.hostStorage),
       let buffer3: MTLBuffer = device.makeBuffer(length: MemoryLayout<RKTransformationUniforms>.stride, options: RKMetal.hostStorage)
    {
      self.frameUniformBuffers =  [buffer1,buffer2,buffer3]
    }
  
    if let device = self.device,
       let library = self.defaultLibrary
    {
      self.renderer.buildPipeLines(device: device, library, maximumNumberOfSamples: maximumNumberOfSamples)
      
      self.renderer.buildTextures(device: device, size: CGSize(width: 400, height: 400), maximumNumberOfSamples: maximumNumberOfSamples)
      
      self.renderer.buildVertexBuffers(device: device)
      
      self.renderer.backgroundShader.buildPermanentTextures(device: device)
    }
  }
  
  #if os(macOS)
  public override func viewWillAppear()
  {
    super.viewWillAppear()
    updateEDRSupport()
  }
  #else
  public override func viewWillAppear(_ animated: Bool)
  {
    super.viewWillAppear(animated)
    updateEDRSupport()
  }
  #endif

  private func updateEDRSupport()
  {
    if let view: MetalView = self.view as? MetalView
    {
      view.edrSupport = 1.0
      #if os(macOS)
      if #available(macOS 10.15, *)
      {
        view.edrSupport = view.window?.screen?.maximumPotentialExtendedDynamicRangeColorComponentValue ?? 1.0
      }
      #endif
      
      // the backing layer does not exist yet while the view is being decoded from the XIB, so the
      // opt-in is repeated here, by which point it does
      view.configureExtendedDynamicRange()
    }
  }

  private var hostWindowController: NSWindowController?
  {
    #if os(macOS)
    return self.view.window?.windowController
    #else
    return nil
    #endif
  }

  private func setViewNeedsDisplay()
  {
    #if os(macOS)
    self.view.layer?.setNeedsDisplay()
    #else
    (self.view as? MTKView)?.setNeedsDisplay()
    #endif
  }
  
  // MARK: -
  // MARK: properties

  public var viewBounds: CGSize
  {
    let size: CGSize =  (self.view as? MetalView)?.drawableSize ?? CGSize(width: 800.0, height: 600.0)
    return size
  }
  
  public var renderQuality: RKRenderQuality
  {
    get
    {
      return (self.view as? MetalView)?.renderQuality ?? RKRenderQuality.high
    }
    set(newValue)
    {
      (self.view as? MetalView)?.renderQuality = newValue
    }
  }
  
  public var ribbonAODebugMode: RibbonAODebugMode
  {
    get {renderer.ribbonAODebugMode}
    set
    {
      renderer.ribbonAODebugMode = newValue
      redraw()
    }
  }
  
  /// Cycles ribbon AO debug visualization (also bound to Option+D in the render view).
  public func cycleRibbonAODebugMode()
  {
    var mode: RibbonAODebugMode = renderer.ribbonAODebugMode
    mode.cycle()
    renderer.ribbonAODebugMode = mode
    print("Ribbon AO debug: \(mode.label)")
    if mode == .uniformColors,
       let text: String = ribbonColorUniformDebugOverlayText(renderStructures: renderer.ribbonShader.renderStructures)
    {
      print(text)
    }
    if let view: MetalView = self.view as? MetalView
    {
      #if os(macOS)
      if mode == .uniformColors,
         let text: String = ribbonColorUniformDebugOverlayText(renderStructures: renderer.ribbonShader.renderStructures)
      {
        view.updateRibbonDebugOverlay(text: text, visible: true)
      }
      else
      {
        view.updateRibbonDebugOverlay(text: nil, visible: false)
      }
      #endif
    }
    redraw()
  }

  // MARK: -
  // MARK: Reloading
  
  public func reloadData()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView,
       let commandQueue: MTLCommandQueue = self.renderCommandQueue
    {
      invalidateRibbonAmbientOcclusionCache()
      self.renderer.reloadData(device: device, view.drawableSize, maximumNumberOfSamples: maximumNumberOfSamples)
    
      self.renderer.isosurfaceShader.buildVertexBuffers()
      self.renderer.volumeRenderedSurfaceShader.buildVertexBuffers(device: device)

      self.renderer.ambientOcclusionShader.updateAmbientOcclusionTextures(device: device, commandQueue, quality: .medium, atomShader: renderer.atomShader, atomOrthographicImposterShader: renderer.atomOrthographicImposterShader, ribbonShader: renderer.ribbonShader, internalBondShader: renderer.internalBondShader, externalBondShader: renderer.externalBondShader)
      self.renderer.buildStructureUniforms(device: device)
    
      self.renderer.isosurfaceShader.updateAdsorptionSurface(device: device, commandQueue: commandQueue, windowController: hostWindowController, completionHandler: {})
      
      self.renderer.volumeRenderedSurfaceShader.updateAdsorptionSurface(device: device, commandQueue: commandQueue, windowController: hostWindowController, completionHandler: {})

      view.renderQuality = RKRenderQuality.high
      setViewNeedsDisplay()
    }
  }
  
  public func reloadData(ambientOcclusionQuality: RKRenderQuality)
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView,
       let commandQueue: MTLCommandQueue = self.renderCommandQueue
    {
      view.renderCameraSource?.renderCamera?.trackBallRotation = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
    
      invalidateRibbonAmbientOcclusionCache()
      self.renderer.reloadData(device: device, view.drawableSize, maximumNumberOfSamples: maximumNumberOfSamples)
    
      self.renderer.isosurfaceShader.buildVertexBuffers()
    
      self.renderer.ambientOcclusionShader.updateAmbientOcclusionTextures(device: device, commandQueue, quality: ambientOcclusionQuality, atomShader: renderer.atomShader, atomOrthographicImposterShader: renderer.atomOrthographicImposterShader, ribbonShader: renderer.ribbonShader, internalBondShader: renderer.internalBondShader, externalBondShader: renderer.externalBondShader)
      self.renderer.buildStructureUniforms(device: device)
    
      self.renderer.isosurfaceShader.updateAdsorptionSurface(device: device, commandQueue: commandQueue, windowController: hostWindowController, completionHandler: {})
      
      self.renderer.volumeRenderedSurfaceShader.updateAdsorptionSurface(device: device, commandQueue: commandQueue, windowController: hostWindowController, completionHandler: {})
    
      view.renderQuality = RKRenderQuality.high
      setViewNeedsDisplay()
    }
  }
  
  public func reloadRenderData()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadRenderData(device: device)
      view.renderQuality = RKRenderQuality.high
      setViewNeedsDisplay()
    }
  }
  
  /// Updates atom/ribbon visibility in the renderer without rebaking the shadow-map AO atlas.
  public func reloadVisibility()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadRenderDataForVisibility(device: device)
      renderer.buildStructureUniforms(device: device)
      view.renderQuality = RKRenderQuality.high
      setViewNeedsDisplay()
    }
  }
  
  public func invalidateRibbonAmbientOcclusionCache()
  {
    for structures in renderer.ambientOcclusionShader.renderStructures
    {
      for structure in structures
      {
        renderer.ambientOcclusionShader.cachedAmbientOcclusionTextures.removeObject(forKey: structure.ribbonAmbientOcclusionCacheKey)
      }
    }
  }
  
  public func reloadBoundingBoxData()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadBoundingBoxData(device: device)
      setViewNeedsDisplay()
    }
  }
  
  public func reloadRenderDataSelectedAtoms()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadRenderDataSelectedAtoms(device: device)
      view.renderQuality = RKRenderQuality.high
      setViewNeedsDisplay()
    }
  }
  
  public func reloadRenderDataSelectedInternalBonds()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadRenderDataSelectedInternalBonds(device: device)
      view.renderQuality = RKRenderQuality.high
      setViewNeedsDisplay()
    }
  }
  
  public func reloadRenderDataSelectedExternalBonds()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadRenderDataSelectedExternalBonds(device: device)
      view.renderQuality = RKRenderQuality.high
      setViewNeedsDisplay()
    }
  }
  
  public func reloadRenderDataSelectedPrimitives()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadRenderDataSelectedPrimitives(device: device)
      view.renderQuality = RKRenderQuality.high
      setViewNeedsDisplay()
    }
  }
  
  public func reloadRenderMeasurePointsData()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadRenderMeasurePointsData(device: device)
      setViewNeedsDisplay()
    }
  }
  
  public func reloadGlobalAxesSystem()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadGlobalAxesSystem(device: device)
      setViewNeedsDisplay()
    }
  }
  
  public func reloadLocalAxesSystem()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadLocalAxesSystem(device: device)
      setViewNeedsDisplay()
    }
  }
  
  public func reloadBackgroundImage()
  {
    if let device = self.device
    {
      self.renderer.backgroundShader.reloadBackgroundImage(device: device)
    }
  }
  
  public func redraw()
  {
    setViewNeedsDisplay()
  }
  
  // MARK: -
  // MARK: Updating
  
  public func updateStructureUniforms()
  {
    if let device = self.device
    {
      self.renderer.buildStructureUniforms(device: device)
    }
  }
  
  public func buildStructureUniforms()
  {
    if let device = self.device
    {
      self.renderer.buildStructureUniforms(device: device)
    }
  }
  
  public func updateIsosurfaceUniforms()
  {
    if let device = self.device
    {
      self.renderer.buildIsosurfaceUniforms(device: device)
    }
  }
  
  public func updateBlockingPocketUniforms()
  {
    if let device = self.device
    {
      self.renderer.buildBlockingPocketUniforms(device: device)
    }
  }
  
  public func updateLightUniforms()
  {
    if let device = self.device
    {
      self.renderer.buildLightUniforms(device: device)
    }
  }

  public func updateVertexArrays()
  {
    if let device = self.device
    {
      self.renderer.buildVertexBuffers(device: device)
    }
  }
  
  public func updateAmbientOcclusion()
  {
    if let device = self.device,
       let commandQueue: MTLCommandQueue = self.renderCommandQueue
    {
      invalidateRibbonAmbientOcclusionCache()
      // Do not rebuild vertex buffers here: that used to nil the isosurface meshes, and the
      // Draw-atoms checkbox (which only needs a fresh AO atlas) then left the surface gone.
      self.renderer.ambientOcclusionShader.updateAmbientOcclusionTextures(device: device, commandQueue, quality: .medium, atomShader: renderer.atomShader, atomOrthographicImposterShader: renderer.atomOrthographicImposterShader, ribbonShader: renderer.ribbonShader, internalBondShader: renderer.internalBondShader, externalBondShader: renderer.externalBondShader)
      self.renderer.buildStructureUniforms(device: device)
    }
  }
  
  public func updateAdsorptionSurface(completionHandler: @escaping ()->())
  {
    if let device = self.device,
       let commandQueue: MTLCommandQueue = self.renderCommandQueue
    {
      self.renderer.isosurfaceShader.updateAdsorptionSurface(device: device, commandQueue: commandQueue, windowController: hostWindowController, completionHandler: completionHandler)
      self.renderer.volumeRenderedSurfaceShader.updateAdsorptionSurface(device: device, commandQueue: commandQueue, windowController: hostWindowController, completionHandler: completionHandler)
    }
  }
  
  // MARK: -
  // MARK: Indalidating caches
  
  public func invalidateCachedAmbientOcclusionTextures()
  {
    self.renderer.ambientOcclusionShader.cachedAmbientOcclusionTextures.removeAllObjects()
  }
  
  public func invalidateCachedAmbientOcclusionTexture(_ structures: [RKRenderObject])
  {
    for structure in structures
    {
      self.renderer.ambientOcclusionShader.cachedAmbientOcclusionTextures.removeObject(forKey: structure)
      self.renderer.ambientOcclusionShader.cachedAmbientOcclusionTextures.removeObject(forKey: structure.ribbonAmbientOcclusionCacheKey)
    }
  }
  
  public func invalidateIsosurfaces()
  {
    for size in [16, 32, 64, 128, 256, 512]
    {
      self.renderer.isosurfaceShader.cachedAdsorptionSurfaces[size]?.removeAllObjects()
      // the well field depends on the same probe and force-field settings as the energy grid, so whatever
      // invalidates one must invalidate the other; a stale entry here once served one probe's surface as
      // another's after a probe change
      self.renderer.isosurfaceShader.cachedWellFields[size]?.removeAllObjects()
      self.renderer.volumeRenderedSurfaceShader.cachedEnergyGrids[size]?.removeAllObjects()
    }
  }
  
  public func invalidateIsosurface(_ structures: [RKRenderObject])
  {
    for structure in structures
    {
      for size in [16, 32, 64, 128, 256, 512]
      {
        self.renderer.isosurfaceShader.cachedAdsorptionSurfaces[size]?.removeObject(forKey: structure)
        self.renderer.isosurfaceShader.cachedWellFields[size]?.removeObject(forKey: structure)
        self.renderer.volumeRenderedSurfaceShader.cachedEnergyGrids[size]?.removeObject(forKey: structure)
      }
    }
  }
  
  
  // MARK: -
  // MARK: Make Pictures
  
  public func makeThumbnail(size: CGSize, camera: RKCamera) -> Data?
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource
    {
      // create Ambient Occlusion in higher quality
      self.invalidateCachedAmbientOcclusionTexture(crystalProjectData.renderStructures)
      
      if let device = MTLCreateSystemDefaultDevice()
      {
        let renderer: MetalRenderer = MetalRenderer(device: device, size: size, dataSource: crystalProjectData, camera: camera)
        
        // FIX to set background
        
        if let data: Data = renderer.renderPictureData(device: device, size: size, camera: camera, imageQuality: .rgb_8_bits, renderQuality: .picture)
        {
          let cgImage: CGImage
          
          let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.first.rawValue)
          let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
          let dataProvider: CGDataProvider = CGDataProvider(data: data as CFData)!
          let bitsPerComponent: Int = 8
          let bitsPerPixel: Int = 32
          let bytesPerRow: Int = 4 * Int(size.width)
          cgImage = CGImage(width: Int(size.width), height: Int(size.height), bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, provider: dataProvider, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)!
            
          #if os(macOS)
          let imageRep: NSBitmapImageRep = NSBitmapImageRep(cgImage: cgImage)
          imageRep.size = NSMakeSize(CGFloat(crystalProjectData.renderImagePhysicalSizeInInches * 72), CGFloat(crystalProjectData.renderImagePhysicalSizeInInches * 72.0 * Double(size.height) / Double(size.width)))
          return imageRep.representation(using: NSBitmapImageRep.FileType.jpeg2000, properties: [:])
          #else
          return UIImage(cgImage: cgImage).pngData()
          #endif
        }
      }
    }
    return nil
  }
  
  public func makePicture(size: CGSize, camera: RKCamera?, imageQuality: RKImageQuality) -> Data?
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
       let camera: RKCamera = camera
    {
      // create Ambient Occlusion in higher quality
      self.invalidateCachedAmbientOcclusionTexture(crystalProjectData.renderStructures)
      
      if let device = MTLCreateSystemDefaultDevice()
      {
        let renderer: MetalRenderer = MetalRenderer(device: device, size: size, dataSource: crystalProjectData, camera: camera)
        
        if let data: Data = renderer.renderPicture(device: device, size: size, imagePhysicalSizeInInches: crystalProjectData.renderImagePhysicalSizeInInches, camera: camera, imageQuality: imageQuality, renderQuality: .picture, renderMode: crystalProjectData.pictureRenderMode, pathTracerSettings: crystalProjectData.picturePathTracerSettings)
        {
          return data
        }
      }
    }
    return nil
  }

  public func makeCVPicture(_ pixelBuffer: CVPixelBuffer)
  {
    if let _: RKRenderDataSource = self.renderDataSource,
       let view: MetalView = self.view as? MetalView
    {
      let width: Int = CVPixelBufferGetWidth(pixelBuffer)
      let height: Int = CVPixelBufferGetHeight(pixelBuffer)
      
      self.makeCVPicture(pixelBuffer, camera: view.renderCameraSource?.renderCamera, width: width, height: height)
    }
  }
  
  
  public func makeCVPicture(_ pixelBuffer: CVPixelBuffer, camera: RKCamera?, width: Int, height: Int)
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource,
       let device = MTLCreateSystemDefaultDevice()
    {
      var coreVideoTextureCache: CVMetalTextureCache? = nil
      CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &coreVideoTextureCache)
    
      var renderTexture: CVMetalTexture? = nil
      CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache!, pixelBuffer, nil, MTLPixelFormat.bgra8Unorm, width, height, 0, &renderTexture)
    
      let size: CGSize = CGSize(width: CGFloat(width), height: CGFloat(height))
      
      let renderer: MetalRenderer = MetalRenderer(device: device, size: size, dataSource: crystalProjectData, camera: camera!)
      if let data: Data = renderer.renderPictureData(device: device, size: size, camera: camera!, imageQuality: .rgb_8_bits, renderQuality: .picture)
      {
        CVPixelBufferLockBaseAddress( pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)) )
        if let destPixels: UnsafeMutablePointer<UInt8> = CVPixelBufferGetBaseAddress(pixelBuffer)?.assumingMemoryBound(to: UInt8.self)
        {
          data.copyBytes(to: destPixels, count: data.count)
        }
        CVPixelBufferUnlockBaseAddress( pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)) )
      }
    }
  }
  
  // MARK: -
  // MARK: Picking
  
  /// `point` must be in MetalView coordinates (origin bottom-left).
  private func pickingTexturePoint(forMetalViewPoint point: NSPoint) -> NSPoint?
  {
    guard let metalView = self.view as? MTKView else { return nil }
    
    let bounds: NSRect = metalView.bounds
    let drawableSize: CGSize = metalView.drawableSize
    guard bounds.width > 0.0, bounds.height > 0.0,
          drawableSize.width > 0.0, drawableSize.height > 0.0,
          bounds.contains(point) else { return nil }
    
    let x: CGFloat = point.x * drawableSize.width / bounds.width
    let y: CGFloat = (bounds.height - point.y) * drawableSize.height / bounds.height
    return NSPoint(x: x, y: y)
  }
  
  public func pickPoint(_ point: NSPoint) ->  [Int32]
  {
    if let device = self.device,
       let commandQueue: MTLCommandQueue = self.renderCommandQueue,
       let texturePoint = pickingTexturePoint(forMetalViewPoint: point)
    {
      return self.renderer.pickingShader.pickTextureAtPoint(device: device, commandQueue, point: texturePoint)
    }
    return [0, 0, 0, 0]
  }
  
  public func pickDepth(_ point: NSPoint) ->  Float?
  {
    if let device = self.device,
       let commandQueue: MTLCommandQueue = self.renderCommandQueue,
       let texturePoint = pickingTexturePoint(forMetalViewPoint: point)
    {
      return self.renderer.pickingShader.pickDepthTextureAtPoint(device: device, commandQueue, point: texturePoint)
    }
    return nil
  }
  
  
  // MARK: -
  // MARK: MTKViewDelegate protocol
  
  public func draw(in: MTKView)
  {
    if let view: MetalView = self.view as? MetalView,
       let device: MTLDevice = self.device,
       let commandQueue: MTLCommandQueue = self.renderCommandQueue,
       frameUniformBuffers != nil
    {
      #if os(macOS)
      guard view.window != nil else { return }
      #endif
      let size: CGSize = view.drawableSize
      guard size.width > 1, size.height > 1 else { return }
      guard view.currentDrawable != nil, view.currentRenderPassDescriptor != nil else { return }
      
      _ = _inflightSemaphore.wait(timeout: DispatchTime.distantFuture)
         
      let maximumEDRvalue: CGFloat
      #if os(macOS)
      if #available(macOS 10.15, *)
      {
        maximumEDRvalue = self.view.window?.screen?.maximumExtendedDynamicRangeColorComponentValue ?? 1.0
      }
      else
      {
        maximumEDRvalue = 1.0
      }
      #else
      maximumEDRvalue = 1.0
      #endif
      
      let pathTracing: Bool = renderer.isInteractivePathTracing(device: device)

      var uniforms: RKTransformationUniforms = renderer.transformUniforms(maximumExtendedDynamicRangeColorComponentValue: maximumEDRvalue, camera: view.renderCameraSource?.renderCamera, pathTracing: pathTracing)
      memcpy(frameUniformBuffers[constantDataBufferIndex].contents(),&uniforms, MemoryLayout<RKTransformationUniforms>.stride)
      RKMetal.didModify(frameUniformBuffers[constantDataBufferIndex], range: 0..<MemoryLayout<RKTransformationUniforms>.stride)

      if let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
      {
        commandBuffer.addCompletedHandler{(_) in self._inflightSemaphore.signal()}
                    
        renderer.pickingOffScreen(commandBuffer: commandBuffer, frameUniformBuffer: frameUniformBuffers[constantDataBufferIndex], size: size, renderQuality: view.renderQuality, camera: view.renderCameraSource?.renderCamera, skipRibbonPicking: view.skipRibbonPicking)
       
        renderer.drawOffScreen(commandBuffer: commandBuffer, commandQueue: commandQueue, frameUniformBuffer: frameUniformBuffers[constantDataBufferIndex], size: size, renderQuality: view.renderQuality, camera: view.renderCameraSource?.renderCamera, suppressMolecularGeometry: pathTracing)

        // the traced molecular geometry is composited over the rasterized rest of the scene
        var tracedTexture: MTLTexture? = nil
        if pathTracing
        {
          tracedTexture = renderer.encodeInteractivePathTracer(device: device,
                                                               commandQueue: commandQueue,
                                                               commandBuffer: commandBuffer,
                                                               frameUniformBuffer: frameUniformBuffers[constantDataBufferIndex],
                                                               size: size,
                                                               samplesThisFrame: RKRenderSettings.samplesPerInteractiveFrame(renderQuality: view.renderQuality))
          if let tracedDepthBuffer: MTLBuffer = tracedTexture == nil ? nil : renderer.pathTracerShader.compositeDepthBuffer
          {
            // the glow was left out of the raster passes above, having had no molecular depth to test
            // against; now that the trace has produced one, the buried selections can be hidden
            renderer.encodeSelectionGlowAgainstTracedDepth(commandBuffer: commandBuffer, frameUniformBuffer: frameUniformBuffers[constantDataBufferIndex], size: size, camera: view.renderCameraSource?.renderCamera, tracedDepthBuffer: tracedDepthBuffer)
          }

          if tracedTexture == nil
          {
            // the molecular geometry was left out of the raster passes above, so without a traced
            // image to composite there would be nothing to look at
            renderer.drawOffScreen(commandBuffer: commandBuffer, commandQueue: commandQueue, frameUniformBuffer: frameUniformBuffers[constantDataBufferIndex], size: size, renderQuality: view.renderQuality, camera: view.renderCameraSource?.renderCamera)

            // the uniforms were written expecting a traced image, so the edge cueing has to be sent
            // back to the rasterizer's depth; nothing has been committed yet, so this is in time
            uniforms.edgeCueingUsesTracedDepth = 0.0
            memcpy(frameUniformBuffers[constantDataBufferIndex].contents(),&uniforms, MemoryLayout<RKTransformationUniforms>.stride)
            RKMetal.didModify(frameUniformBuffers[constantDataBufferIndex], range: 0..<MemoryLayout<RKTransformationUniforms>.stride)
          }
        }

        if let renderPass: MTLRenderPassDescriptor = (self.view as? MTKView)?.currentRenderPassDescriptor,
           let currentDrawable = (self.view as? MTKView)?.currentDrawable
        {
          renderer.drawOnScreen(commandBuffer: commandBuffer, renderPass: renderPass, frameUniformBuffer: frameUniformBuffers[constantDataBufferIndex], size: size, sourceTexture: tracedTexture, tracedDepthBuffer: tracedTexture == nil ? nil : renderer.pathTracerShader.compositeDepthBuffer, tracedCueMaskBuffer: tracedTexture == nil ? nil : renderer.pathTracerShader.compositeCueMaskBuffer)
          commandBuffer.present(currentDrawable)
        }
        commandBuffer.commit()
         
        constantDataBufferIndex = (constantDataBufferIndex + 1) % frameUniformBuffers.count
      }
    }
  }
     
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
  {
    renderCameraSource?.renderCamera?.updateCameraForWindowResize(width: Double(size.width), height: Double(size.height))
     
    if let device = device
    {
      self.renderer.buildTextures(device: device, size: size, maximumNumberOfSamples: maximumNumberOfSamples)
    }
  }
}
