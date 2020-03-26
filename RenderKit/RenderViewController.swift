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
import MetalKit
import SimulationKit
import SymmetryKit
import AVFoundation
import CoreMedia
import CoreVideo
import LogViewKit

public class RenderViewController: NSViewController, MTKViewDelegate
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
  
  override public init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?)
  {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  convenience  init()
  {
    self.init(nibName: nil, bundle: Bundle(for: RenderViewController.self))
  }
  
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
    
    // the metal default library is not in mainBundle, but in the local framework bundle
    let bundle: Bundle = Bundle(for: MetalView.self)
    
    if let newDevice = MTLCreateSystemDefaultDevice(),
       let file: String = bundle.path(forResource: "default", ofType: "metallib"),
       let library: MTLLibrary = try? newDevice.makeLibrary(filepath: file)
    {
      self.device = newDevice
      self.renderCommandQueue = newDevice.makeCommandQueue()
      self.defaultLibrary = library
      
      (self.view as? MTKView)?.device = newDevice
    
      let devices: [MTLDevice] = MTLCopyAllDevices().filter{!$0.isEqual(device) && !$0.isLowPower}
      self.computeDevice = devices.first ?? device
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
    }
    
    if let device = self.device,
       let buffer1: MTLBuffer = device.makeBuffer(length: MemoryLayout<RKTransformationUniforms>.stride, options: .storageModeManaged),
       let buffer2: MTLBuffer = device.makeBuffer(length: MemoryLayout<RKTransformationUniforms>.stride, options: .storageModeManaged),
       let buffer3: MTLBuffer = device.makeBuffer(length: MemoryLayout<RKTransformationUniforms>.stride, options: .storageModeManaged)
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
  
  public override func viewWillAppear()
  {
    super.viewWillAppear()
    
    if let view: MetalView = self.view as? MetalView
    {
      view.edrSupport = 1.0
    
      if #available(OSX 10.15, *)
      {
        view.edrSupport = view.window?.screen?.maximumPotentialExtendedDynamicRangeColorComponentValue ?? 1.0
      }
    }
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
  
  // MARK: -
  // MARK: Reloading
  
  public func reloadData()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView,
       let commandQueue: MTLCommandQueue = self.renderCommandQueue
    {
      renderer.reloadData(device: device, view.drawableSize, maximumNumberOfSamples: maximumNumberOfSamples)
    
      renderer.ambientOcclusionShader.adjustAmbientOcclusionTextureSize()
    
      renderer.buildStructureUniforms(device: device)
    
      renderer.isosurfaceShader.buildVertexBuffers()

      renderer.ambientOcclusionShader.updateAmbientOcclusionTextures(device: device, commandQueue, quality: .medium, atomShader: renderer.atomShader, atomOrthographicImposterShader: renderer.atomOrthographicImposterShader)
    
      renderer.isosurfaceShader.updateAdsorptionSurface(device: device, commandQueue: commandQueue, windowController: self.view.window?.windowController, completionHandler: {})

      view.renderQuality = RKRenderQuality.high
      self.view.layer?.setNeedsDisplay()
    }
  }
  
  public func reloadData(ambientOcclusionQuality: RKRenderQuality)
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView,
       let commandQueue: MTLCommandQueue = self.renderCommandQueue
    {
      view.renderCameraSource?.renderCamera?.trackBallRotation = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
    
      renderer.reloadData(device: device, view.drawableSize, maximumNumberOfSamples: maximumNumberOfSamples)
    
      renderer.ambientOcclusionShader.adjustAmbientOcclusionTextureSize()
    
      renderer.buildStructureUniforms(device: device)
    
      renderer.isosurfaceShader.buildVertexBuffers()
    
      renderer.ambientOcclusionShader.updateAmbientOcclusionTextures(device: device, commandQueue, quality: ambientOcclusionQuality, atomShader: renderer.atomShader, atomOrthographicImposterShader: renderer.atomOrthographicImposterShader)
    
      renderer.isosurfaceShader.updateAdsorptionSurface(device: device, commandQueue: commandQueue, windowController: self.view.window?.windowController, completionHandler: {})
    
      view.renderQuality = RKRenderQuality.high
      self.view.layer?.setNeedsDisplay()
    }
  }
  
  public func reloadRenderData()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadRenderData(device: device)
      view.renderQuality = RKRenderQuality.high
      view.layer?.setNeedsDisplay()
    }
  }
  
  public func reloadBoundingBoxData()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadBoundingBoxData(device: device)
      view.layer?.setNeedsDisplay()
    }
  }
  
  public func reloadRenderDataSelectedAtoms()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadRenderDataSelectedAtoms(device: device)
      view.renderQuality = RKRenderQuality.high
      view.layer?.setNeedsDisplay()
    }
  }
  
  public func reloadRenderDataSelectedInternalBonds()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadRenderDataSelectedInternalBonds(device: device)
      view.renderQuality = RKRenderQuality.high
      self.view.layer?.setNeedsDisplay()
    }
  }
  
  public func reloadRenderDataSelectedExternalBonds()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadRenderDataSelectedExternalBonds(device: device)
      view.renderQuality = RKRenderQuality.high
      view.layer?.setNeedsDisplay()
    }
  }
  
  public func reloadRenderMeasurePointsData()
  {
    if let device = self.device,
       let view: MetalView = self.view as? MetalView
    {
      renderer.reloadRenderMeasurePointsData(device: device)
      view.layer?.setNeedsDisplay()
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
    self.view.layer?.setNeedsDisplay()
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
      self.renderer.ambientOcclusionShader.updateAmbientOcclusionTextures(device: device, commandQueue, quality: .medium, atomShader: renderer.atomShader, atomOrthographicImposterShader: renderer.atomOrthographicImposterShader)
    }
  }
  
  public func updateAdsorptionSurface(completionHandler: @escaping ()->())
  {
    if let device = self.device,
       let commandQueue: MTLCommandQueue = self.renderCommandQueue
    {
      self.renderer.isosurfaceShader.updateAdsorptionSurface(device: device, commandQueue: commandQueue, windowController: self.view.window?.windowController, completionHandler: completionHandler)
    }
  }
  
  // MARK: -
  // MARK: Indalidating caches
  
  public func invalidateCachedAmbientOcclusionTextures()
  {
    self.renderer.ambientOcclusionShader.cachedAmbientOcclusionTextures.removeAllObjects()
  }
  
  public func invalidateCachedAmbientOcclusionTexture(_ structures: [RKRenderStructure])
  {
    for  structure in structures
    {
      self.renderer.ambientOcclusionShader.cachedAmbientOcclusionTextures.removeObject(forKey: structure)
    }
  }
  
  public func invalidateIsosurfaces()
  {
    self.renderer.isosurfaceShader.cachedAdsorptionSurfaces[128]?.removeAllObjects()
    self.renderer.isosurfaceShader.cachedAdsorptionSurfaces[256]?.removeAllObjects()
  }
  
  public func invalidateIsosurface(_ structures: [RKRenderStructure])
  {
    for  structure in structures
    {
      self.renderer.isosurfaceShader.cachedAdsorptionSurfaces[128]?.removeObject(forKey: structure)
      self.renderer.isosurfaceShader.cachedAdsorptionSurfaces[256]?.removeObject(forKey: structure)
    }
  }
  
  
  // MARK: -
  // MARK: Picture
  
  public func makePicture(size: NSSize, imageQuality: RKImageQuality) -> Data
  {
    if let crystalProjectData: RKRenderDataSource = self.renderDataSource
    {
      // create Ambient Occlusion in higher quality
      self.invalidateCachedAmbientOcclusionTexture(crystalProjectData.renderStructures)
      
      let data: Data = self.drawSceneToTexture(size: size, imageQuality: imageQuality)
     
      let cgImage: CGImage
      switch(imageQuality)
      {
      case .rgb_16_bits, .cmyk_16_bits:
        let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder16Little.rawValue | CGImageAlphaInfo.last.rawValue)
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let dataProvider: CGDataProvider = CGDataProvider(data: data as CFData)!
        let bitsPerComponent: Int = 8 * 2
        let bitsPerPixel: Int = 32 * 2
        let bytesPerRow: Int = 4 * Int(size.width) * 2
        cgImage = CGImage(width: Int(size.width), height: Int(size.height), bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, provider: dataProvider, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)!
      case .rgb_8_bits, .cmyk_8_bits:
        let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.first.rawValue)
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let dataProvider: CGDataProvider = CGDataProvider(data: data as CFData)!
        let bitsPerComponent: Int = 8
        let bitsPerPixel: Int = 32
        let bytesPerRow: Int = 4 * Int(size.width)
        cgImage = CGImage(width: Int(size.width), height: Int(size.height), bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, provider: dataProvider, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)!
      }
        
        
      let imageRep: NSBitmapImageRep = NSBitmapImageRep(cgImage: cgImage)
      imageRep.size = NSMakeSize(CGFloat(crystalProjectData.renderImagePhysicalSizeInInches * 72), CGFloat(crystalProjectData.renderImagePhysicalSizeInInches * 72.0 * Double(size.height) / Double(size.width)))
        
      switch(imageQuality)
      {
      case .rgb_8_bits, .rgb_16_bits:
        return imageRep.tiffRepresentation(using: NSBitmapImageRep.TIFFCompression.lzw, factor: 1.0)!
      case .cmyk_8_bits, .cmyk_16_bits:
        let imageRepCMYK: NSBitmapImageRep = imageRep.converting(to: NSColorSpace.genericCMYK, renderingIntent: NSColorRenderingIntent.perceptual)!
        imageRepCMYK.size = NSMakeSize(CGFloat(crystalProjectData.renderImagePhysicalSizeInInches * 72), CGFloat(crystalProjectData.renderImagePhysicalSizeInInches * 72))
        return imageRepCMYK.tiffRepresentation(using: NSBitmapImageRep.TIFFCompression.lzw, factor: 1.0)!
      }
    }
    return Data()
  }

  public func makeCVPicture(_ pixelBuffer: CVPixelBuffer)
  {
    if let _: RKRenderDataSource = self.renderDataSource
    {
      let width: Int = CVPixelBufferGetWidth(pixelBuffer)
      let height: Int = CVPixelBufferGetHeight(pixelBuffer)
      
      self.makeCVPicture(pixelBuffer, width: width, height: height)
    }
  }
  
  public func makeCVPicture(_ pixelBuffer: CVPixelBuffer, width: Int, height: Int)
  {
    if let device = self.device
    {
      var coreVideoTextureCache: CVMetalTextureCache? = nil
      CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &coreVideoTextureCache)
    
      var renderTexture: CVMetalTexture? = nil
      CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache!, pixelBuffer, nil, MTLPixelFormat.bgra8Unorm, width, height, 0, &renderTexture)
    
      let size: NSSize = NSMakeSize(CGFloat(width), CGFloat(height))
      let data: Data = self.drawSceneToTexture(size: size, imageQuality: RKImageQuality.rgb_8_bits)
    
      CVPixelBufferLockBaseAddress( pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)) )
      if let destPixels: UnsafeMutablePointer<UInt8> = CVPixelBufferGetBaseAddress(pixelBuffer)?.assumingMemoryBound(to: UInt8.self)
      {
        data.copyBytes(to: destPixels, count: data.count)
      }
      CVPixelBufferUnlockBaseAddress( pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)) )
    }
  }
  
  public func drawSceneToTexture(size: NSSize, imageQuality: RKImageQuality) -> Data
  {
    if let device = self.device,
       let commandQueue: MTLCommandQueue = self.renderCommandQueue,
       let view: MetalView = self.view as? MetalView
    {
      self.renderer.ambientOcclusionShader.updateAmbientOcclusionTextures(device: device, commandQueue, quality: .picture, atomShader: renderer.atomShader, atomOrthographicImposterShader: renderer.atomOrthographicImposterShader)
    
      return self.renderer.drawSceneToTexture(device: device, size: size, imageQuality: imageQuality, maximumNumberOfSamples: maximumNumberOfSamples, camera: view.renderCameraSource?.renderCamera, renderQuality: view.renderQuality)
    }
    return Data()
  }
  
  // MARK: -
  // MARK: Picking
  
  public func pickPoint(_ point: NSPoint) ->  [Int32]
  {
    if let device = self.device,
       let commandQueue: MTLCommandQueue = self.renderCommandQueue
    {
      let convertedPoint: NSPoint = self.view.convertToBacking(NSPoint(x: point.x, y: self.view.frame.size.height - point.y))
      return self.renderer.pickingShader.pickTextureAtPoint(device: device, commandQueue, point: convertedPoint)
    }
    return []
  }
  
  public func pickDepth(_ point: NSPoint) ->  Float?
  {
    if let device = self.device,
       let commandQueue: MTLCommandQueue = self.renderCommandQueue
    {
      let convertedPoint: NSPoint = self.view.convertToBacking(NSPoint(x: point.x, y: self.view.frame.size.height - point.y))
      return self.renderer.pickingShader.pickDepthTextureAtPoint(device: device, commandQueue, point: convertedPoint)
    }
    return nil
  }
  
  
  // MARK: -
  // MARK: MTKViewDelegate protocol
  
  public func draw(in: MTKView)
  {
    if let view: MetalView = self.view as? MetalView,
       let _ = view.window,
       let _ = self.device,
       let commandQueue: MTLCommandQueue = self.renderCommandQueue
    {
      let size: CGSize = view.drawableSize
      
      _ = _inflightSemaphore.wait(timeout: DispatchTime.distantFuture)
         
      let maximumEDRvalue: CGFloat
      if #available(OSX 10.15, *)
      {
        maximumEDRvalue = self.view.window?.screen?.maximumExtendedDynamicRangeColorComponentValue ?? 1.0
      }
      else
      {
        // Fallback on earlier versions
        maximumEDRvalue = 1.0
      }
      
      var uniforms: RKTransformationUniforms = renderer.transformUniforms(maximumExtendedDynamicRangeColorComponentValue: maximumEDRvalue, camera: view.renderCameraSource?.renderCamera)
      memcpy(frameUniformBuffers[constantDataBufferIndex].contents(),&uniforms, MemoryLayout<RKTransformationUniforms>.stride)
      frameUniformBuffers[constantDataBufferIndex].didModifyRange(0..<MemoryLayout<RKTransformationUniforms>.stride)

      if let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
      {
        commandBuffer.addCompletedHandler{(_) in self._inflightSemaphore.signal()}
                    
        renderer.pickingOffScreen(commandBuffer: commandBuffer, frameUniformBuffer: frameUniformBuffers[constantDataBufferIndex], size: size)
       
        renderer.drawOffScreen(commandBuffer: commandBuffer, frameUniformBuffer: frameUniformBuffers[constantDataBufferIndex], size: size, renderQuality: view.renderQuality, camera: view.renderCameraSource?.renderCamera)
         
        if let renderPass: MTLRenderPassDescriptor = (self.view as? MTKView)?.currentRenderPassDescriptor,
           let currentDrawable = (self.view as? MTKView)?.currentDrawable
        {
          renderer.drawOnScreen(commandBuffer: commandBuffer, renderPass: renderPass, frameUniformBuffer: frameUniformBuffers[constantDataBufferIndex], size: size)
           
          commandBuffer.present(currentDrawable)
             
          commandBuffer.commit()
        }
         
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
