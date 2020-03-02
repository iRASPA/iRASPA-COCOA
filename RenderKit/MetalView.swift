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
import MathKit
import SimulationKit
import simd


class MetalView: MTKView
{
  var trackball: RKTrackBall = RKTrackBall()
  var startPoint: NSPoint? = NSPoint()
  var panStartPoint: NSPoint? = NSPoint()
  
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
  
  var maximumNumberOfSamples: Int = 4
  
  let _inflightSemaphore: DispatchSemaphore = DispatchSemaphore(value: 3)
  var constantDataBufferIndex: Int = 0
  var frameUniformBuffers: [MTLBuffer]! = nil
  
  var tracking: Tracking = .none
  
  var commandQueue: MTLCommandQueue! = nil
  //var defaultLibrary: MTLLibrary! = nil
  var renderer: MetalRenderer = MetalRenderer()
  
  var edrSupport: CGFloat = 1.0
  
  weak var renderDataSource: RKRenderDataSource?
  {
    didSet
    {
      renderer.renderDataSource = self.renderDataSource
    }
  }
  
  weak var renderCameraSource: RKRenderCameraSource?
    {
    didSet
    {
      renderer.renderCameraSource = self.renderCameraSource
    }
  }
  
  override func resizeSubviews(withOldSize oldSize: NSSize)
  {
    super.resizeSubviews(withOldSize: oldSize)
  }
  

  func reloadData()
  {
    renderer.reloadData(device: self.device!, self.drawableSize, maximumNumberOfSamples: maximumNumberOfSamples)
    
    renderer.ambientOcclusionShader.adjustAmbientOcclusionTextureSize()
    
    renderer.buildStructureUniforms(device: self.device!)
    
    renderer.isosurfaceShader.buildVertexBuffers()

    renderer.ambientOcclusionShader.updateAmbientOcclusionTextures(device: self.device!, self.commandQueue, quality: .medium, atomShader: renderer.atomShader, atomOrthographicImposterShader: renderer.atomOrthographicImposterShader)
    
    renderer.isosurfaceShader.updateAdsorptionSurface(device: self.device!, commandQueue: self.commandQueue, windowController: self.window?.windowController, completionHandler: {})

    renderer.renderQuality = RKRenderQuality.high
    self.layer?.setNeedsDisplay()
  }
  
  func reloadData(ambientOcclusionQuality: RKRenderQuality)
  {
    renderer.renderCameraSource?.renderCamera?.trackBallRotation = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
    
    renderer.reloadData(device: self.device!, self.drawableSize, maximumNumberOfSamples: maximumNumberOfSamples)
    
    renderer.ambientOcclusionShader.adjustAmbientOcclusionTextureSize()
    
    renderer.buildStructureUniforms(device: self.device!)
    
    renderer.isosurfaceShader.buildVertexBuffers()
    
    renderer.ambientOcclusionShader.updateAmbientOcclusionTextures(device: self.device!, self.commandQueue, quality: ambientOcclusionQuality, atomShader: renderer.atomShader, atomOrthographicImposterShader: renderer.atomOrthographicImposterShader)
    
    renderer.isosurfaceShader.updateAdsorptionSurface(device: self.device!, commandQueue: self.commandQueue, windowController: self.window?.windowController, completionHandler: {})
    
    renderer.renderQuality = RKRenderQuality.high
    self.layer?.setNeedsDisplay()
  }
  
  func reloadRenderData()
  {
    renderer.reloadRenderData(device: self.device!)
    renderer.renderQuality = RKRenderQuality.high
    self.layer?.setNeedsDisplay()
  }
  
  func reloadBoundingBoxData()
  {
    renderer.reloadBoundingBoxData(device: self.device!)
    self.layer?.setNeedsDisplay()
  }

  func reloadRenderDataSelectedAtoms()
  {
    renderer.reloadRenderDataSelectedAtoms(device: self.device!)
    renderer.renderQuality = RKRenderQuality.high
    self.layer?.setNeedsDisplay()
  }
  
  func reloadRenderDataSelectedInternalBonds()
  {
    renderer.reloadRenderDataSelectedInternalBonds(device: self.device!)
    renderer.renderQuality = RKRenderQuality.high
    self.layer?.setNeedsDisplay()
  }
  
  func reloadRenderDataSelectedExternalBonds()
  {
    renderer.reloadRenderDataSelectedExternalBonds(device: self.device!)
    renderer.renderQuality = RKRenderQuality.high
    self.layer?.setNeedsDisplay()
  }
  
  public func reloadRenderMeasurePointsData()
  {
    renderer.reloadRenderMeasurePointsData(device: self.device!)
    self.layer?.setNeedsDisplay()
  }

  func updateStructureUniforms()
  {
    self.renderer.buildStructureUniforms(device: self.device!)
  }
  
  public func updateIsosurfaceUniforms()
  {
    self.renderer.buildIsosurfaceUniforms(device: self.device!)
  }
  
  public func updateLightUniforms()
  {
    self.renderer.buildLightUniforms(device: self.device!)
  }
 
  public func drawSceneToTexture(size: NSSize, imageQuality: RKImageQuality) -> Data
  {
    self.renderer.ambientOcclusionShader.updateAmbientOcclusionTextures(device: self.device!, self.commandQueue, quality: .picture, atomShader: renderer.atomShader, atomOrthographicImposterShader: renderer.atomOrthographicImposterShader)
  
    return self.renderer.drawSceneToTexture(device: self.device!, size: size, imageQuality: imageQuality, maximumNumberOfSamples: maximumNumberOfSamples)
  }
  
  public func reloadBackgroundImage()
  {
    self.renderer.backgroundShader.reloadBackgroundImage(device: self.device!)
  }
  
  public func buildVertexBuffers()
  {
    self.renderer.buildVertexBuffers(device: self.device!)
  }
  
  public func buildStructureUniforms()
  {
    self.renderer.buildStructureUniforms(device: self.device!)
  }

  // the MetalView is initialized from the XIB file
  required init(coder: NSCoder)
  {
    super.init(coder: coder)

    self.isPaused = true
    self.enableSetNeedsDisplay = true
    self.autoResizeDrawable = true
    self.autoresizesSubviews = true
    
    self.colorPixelFormat = MTLPixelFormat.bgra8Unorm
    self.depthStencilPixelFormat = MTLPixelFormat.invalid

    self.framebufferOnly = true
    self.clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1)
  }
  
  func setup(device: MTLDevice, defaultLibrary: MTLLibrary, commandQueue: MTLCommandQueue)
  {
    self.device = device
    self.commandQueue = commandQueue
    
    // detect the maximum MSAA
    for i in [32,16,8,4,2,1]
    {
      if (device.supportsTextureSampleCount(i))
      {
        maximumNumberOfSamples = i
        break
      }
    }
    
    self.renderer.buildPipeLines(device: self.device!, defaultLibrary, maximumNumberOfSamples: maximumNumberOfSamples)
    
    
    let buffer1: MTLBuffer = device.makeBuffer(length: MemoryLayout<RKTransformationUniforms>.stride, options: .storageModeManaged)!
    let buffer2: MTLBuffer = device.makeBuffer(length: MemoryLayout<RKTransformationUniforms>.stride, options: .storageModeManaged)!
    let buffer3: MTLBuffer = device.makeBuffer(length: MemoryLayout<RKTransformationUniforms>.stride, options: .storageModeManaged)!
    
    frameUniformBuffers =  [buffer1,buffer2,buffer3]
    
    
    self.renderer.buildTextures(device: device, size: CGSize(width: 400, height: 400), maximumNumberOfSamples: maximumNumberOfSamples)
    self.renderer.buildVertexBuffers(device: device)
    
    self.renderer.backgroundShader.buildPermanentTextures(device: device)
  }
  
  
  deinit
  {
    // clean up and avoid crashing the app due to waiting semaphores
    for _ in 0...3
    {
      self._inflightSemaphore.signal()
    }
    
  }
  
  
  
  override func draw(_ dirtyRect: NSRect)
  {
    if let _ = device,
       let _ = window
    {
      _ = _inflightSemaphore.wait(timeout: DispatchTime.distantFuture)
    
      var uniforms: RKTransformationUniforms = renderer.transformUniforms()
      memcpy(frameUniformBuffers[constantDataBufferIndex].contents(),&uniforms, MemoryLayout<RKTransformationUniforms>.stride)
      frameUniformBuffers[constantDataBufferIndex].didModifyRange(0..<MemoryLayout<RKTransformationUniforms>.stride)

      let commandBuffer: MTLCommandBuffer = self.commandQueue.makeCommandBuffer()!
      commandBuffer.addCompletedHandler{(_) in
        self._inflightSemaphore.signal()
      }
    
      renderer.pickingOffScreen(commandBuffer: commandBuffer, frameUniformBuffer: frameUniformBuffers[constantDataBufferIndex], size: drawableSize)
    
      renderer.drawOffScreen(commandBuffer: commandBuffer, frameUniformBuffer: frameUniformBuffers[constantDataBufferIndex], size: drawableSize)
    
      if let renderPass: MTLRenderPassDescriptor = self.currentRenderPassDescriptor
      {
        renderer.drawOnScreen(commandBuffer: commandBuffer, renderPass: renderPass, frameUniformBuffer: frameUniformBuffers[constantDataBufferIndex], size: drawableSize)
      
        if let drawable = self.currentDrawable
        {
          commandBuffer.present(drawable)
        }
        commandBuffer.commit()
      }
    
      constantDataBufferIndex = (constantDataBufferIndex + 1) % frameUniformBuffers.count
    }
  }


  
  override func setFrameSize(_ newSize: CGSize)
  {
    super.setFrameSize(newSize)
    
    // the first time setFrameSize is called the framesize is zero, we can check for this as the frame is not yet set inside a window
    if let window = self.window,
       let scale = window.screen?.backingScaleFactor,
       let layer = layer,
       let device = device
    {
      let size: CGSize = layer.bounds.size
      drawableSize.width = size.width * scale
      drawableSize.height = size.height * scale
      
      renderCameraSource?.renderCamera?.updateCameraForWindowResize(width: Double(drawableSize.width), height: Double(drawableSize.height))
      
      self.renderer.buildTextures(device: device, size: drawableSize, maximumNumberOfSamples: maximumNumberOfSamples)
      layer.setNeedsDisplay()
    }
    
  }
  
  func updateAdsorptionSurface(completionHandler: @escaping ()->())
  {
    self.renderer.isosurfaceShader.updateAdsorptionSurface(device: self.device!, commandQueue: self.commandQueue, windowController: self.window?.windowController, completionHandler: completionHandler)
  }


  
  // MARK: Mouse control
  // =====================================================================
  
 
  override func rightMouseDown(with event: NSEvent)
  {
    startPoint = nil
    panStartPoint = self.convert(event.locationInWindow, from: nil)

    if event.modifierFlags.contains(.option)
    {
      tracking = .panning
    }
    else
    {
      // else pass on for context-menu
      super.rightMouseDown(with: event)
    }
    
  
  }
  
  
  override func mouseDown(with theEvent: NSEvent)
  {
    super.mouseDown(with: theEvent)
    
    renderer.renderCameraSource?.renderCamera?.trackBallRotation = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
    
    startPoint = self.convert(theEvent.locationInWindow, from: nil)
    
    if (theEvent.modifierFlags.contains(NSEvent.ModifierFlags.shift))
    {
      tracking = .newSelection
    }
    //else if theEvent.modifierFlags.contains(.option)
   // {
      //tracking = .panning
   // }
    else if theEvent.modifierFlags.contains(NSEvent.ModifierFlags.command) &&
            !theEvent.modifierFlags.contains(NSEvent.ModifierFlags.option)
    {
      tracking = .addToSelection
    }
    else if theEvent.modifierFlags.contains(NSEvent.ModifierFlags.option) &&
            theEvent.modifierFlags.contains(NSEvent.ModifierFlags.command)
    {
      tracking = .translateSelection
    }
    else if theEvent.modifierFlags.contains(NSEvent.ModifierFlags.option) &&
            !theEvent.modifierFlags.contains(NSEvent.ModifierFlags.command)
    {
      tracking = .measurement
      trackball.start(x: startPoint!.x, y: startPoint!.y, originX: 0.0, originY: 0.0, width: self.bounds.size.width, height: self.bounds.size.height)
    }
    else
    {
      tracking = .backgroundClick
      trackball.start(x: startPoint!.x, y: startPoint!.y, originX: 0.0, originY: 0.0, width: self.bounds.size.width, height: self.bounds.size.height)
    }
    
    
    renderer.renderQuality = RKRenderQuality.medium
    self.layer?.setNeedsDisplay()
  }
  
  override func rightMouseDragged(with event: NSEvent)
  {
    switch(tracking)
    {
    case .panning:
      let location: NSPoint  = self.convert(event.locationInWindow, from: nil)
      if let panStartPoint = panStartPoint,
         let distance: SIMD3<Double> = renderer.renderCameraSource?.renderCamera?.distance
      {
        let panX: Double = Double(panStartPoint.x - location.x) * distance.z / 1500.0
        let panY: Double = Double(panStartPoint.y - location.y) * distance.z / 1500.0
        
        renderer.renderCameraSource?.renderCamera?.pan(x: panX, y: panY)
      }
      panStartPoint = location
      
      self.layer?.setNeedsDisplay()
    default:
      break
    }
    super.rightMouseDragged(with: event)
  }
  
  override func mouseDragged(with theEvent: NSEvent)
  {
    super.mouseDragged(with: theEvent)
    
    let location: NSPoint  = self.convert(theEvent.locationInWindow, from: nil)
    
    renderer.renderQuality = RKRenderQuality.medium
    
    switch(tracking)
    {
    case .newSelection:
      tracking = .draggedNewSelection
    case .addToSelection:
      tracking = .draggedAddToSelection
    case .draggedNewSelection:
      tracking = .draggedNewSelection
    case .draggedAddToSelection:
      tracking = .draggedAddToSelection
    case .translateSelection:
      break
    case .measurement:
      break
    default:
      tracking = .other
      if let _ = startPoint
      {
        renderer.renderCameraSource?.renderCamera?.trackBallRotation = trackball.rollToTrackball(x: location.x, y: location.y)
        //self.selectionDelegate?.cameraDidChange()
      }
      
      self.layer?.setNeedsDisplay()
    }
  }
  
  
  func pickPoint(_ point: NSPoint) ->  [Int32]
  {
    //let location: NSPoint  = self.convert(point, from: nil)
    let convertedPoint: NSPoint = convertToBacking(NSPoint(x: point.x, y: self.frame.size.height - point.y))
    return self.renderer.pickingShader.pickTextureAtPoint(device: self.device!, self.commandQueue, point: convertedPoint)
  }
  
  func pickDepth(_ point: NSPoint) ->  Float?
  {
    //let location: NSPoint  = self.convert(point, from: nil)
    let convertedPoint: NSPoint = convertToBacking(NSPoint(x: point.x, y: self.frame.size.height - point.y))
    return self.renderer.pickingShader.pickDepthTextureAtPoint(device: self.device!, self.commandQueue, point: convertedPoint)
  }
  
  
  override func mouseUp(with theEvent: NSEvent)
  {
    super.mouseUp(with: theEvent)
    
    let location: NSPoint  = self.convert(theEvent.locationInWindow, from: nil)
    
    switch(tracking)
    {
    case .newSelection:
      break
    case .addToSelection:
      break
    case .draggedNewSelection:
      break
    case .draggedAddToSelection:
      break
    case .translateSelection:
      break
    case .measurement:
      break
    case .backgroundClick:
      break
    default:
      if let _ = startPoint
      {
        renderer.renderCameraSource?.renderCamera?.trackBallRotation=trackball.rollToTrackball(x: location.x, y: location.y)
        
        if let trackBallRotation = renderer.renderCameraSource?.renderCamera?.trackBallRotation,
           let worldRotation = renderer.renderCameraSource?.renderCamera?.worldRotation
        {
          renderer.renderCameraSource?.renderCamera?.worldRotation = simd_normalize(simd_mul(trackBallRotation, worldRotation))
        }
      }
      renderer.renderCameraSource?.renderCamera?.trackBallRotation = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
    }
    
    startPoint = nil
    panStartPoint = nil
    tracking = .none
    renderer.renderQuality = RKRenderQuality.high
    
    self.layer?.setNeedsDisplay()
  }
  
  var timer: DispatchSourceTimer?
  var timerLastStamp: UInt64 = 0
  var timerRunning: Bool = false
  
  let timerQueue = DispatchQueue(label: "nl.darkwing.timer", attributes: .concurrent)
  
  private func startTimer()
  {
    timer?.cancel()        // cancel previous timer if any
    
    timer = DispatchSource.makeTimerSource(queue: timerQueue)
    
    timer?.schedule(deadline: .now(), repeating: .milliseconds(500), leeway: .milliseconds(10))
    
    timer?.setEventHandler { [weak self] in
      DispatchQueue.main.async(execute: {
        
        if let strongSelf = self
        {
          let stamp: UInt64  = mach_absolute_time()
        
          if ((stamp - strongSelf.timerLastStamp) > 5 * NSEC_PER_SEC/10)
          {
            // wheel did end scroll
            if (strongSelf.timerRunning)
            {
              strongSelf.timer?.cancel()
              strongSelf.timer=nil
              strongSelf.renderer.renderQuality = RKRenderQuality.high
              strongSelf.timerRunning = false
            }
        
            // if not rotating already, then update display
            if strongSelf.tracking != .other
            {
              strongSelf.renderer.renderQuality = RKRenderQuality.high
              strongSelf.layer?.setNeedsDisplay()
            }
          }
        }
      })
    }
    
    timer?.resume()
  }
  
  private func stopTimer()
  {
    timer?.cancel()
    timer = nil
  }
  
  override func scrollWheel(with theEvent: NSEvent)
  {
    let phase: NSEvent.Phase  = theEvent.phase
    
    timerLastStamp = mach_absolute_time()
    
    if (!timerRunning)
    {
      self.startTimer()
      
      timerRunning = true
      self.renderer.renderQuality = RKRenderQuality.medium
    }
    
    if (phase == NSEvent.Phase.began)
    {
      self.renderer.renderQuality = RKRenderQuality.medium
    }
    
    let wheelDelta: Double = Double(theEvent.deltaX + theEvent.deltaY + theEvent.deltaZ)
    
    renderer.renderCameraSource?.renderCamera?.increaseDistance(wheelDelta)
    
    if (phase == NSEvent.Phase.ended || phase == NSEvent.Phase.cancelled)
    {
      self.renderer.renderQuality = RKRenderQuality.high
      self.stopTimer()
    }
    
    //self.selectionDelegate?.cameraDidChange()
    
    self.layer?.setNeedsDisplay()
  }
  
  func updateAmbientOcclusionTextures()
  {
    if let device = self.device
    {
      self.renderer.ambientOcclusionShader.updateAmbientOcclusionTextures(device: device, self.commandQueue, quality: .medium, atomShader: renderer.atomShader, atomOrthographicImposterShader: renderer.atomOrthographicImposterShader)
    }
  }
  
  public func makeCVPicture(_ pixelBuffer: CVPixelBuffer, width: Int, height: Int)
  {
    var coreVideoTextureCache: CVMetalTextureCache? = nil
    CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, self.device!, nil, &coreVideoTextureCache)
    
    var renderTexture: CVMetalTexture? = nil
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache!, pixelBuffer, nil, MTLPixelFormat.bgra8Unorm, width, height, 0, &renderTexture)
    
    
    
    let size: NSSize = NSMakeSize(CGFloat(width), CGFloat(height))
    let data: Data = self.drawSceneToTexture(size: size, imageQuality: RKImageQuality.rgb_8_bits)
    
    CVPixelBufferLockBaseAddress( pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)) )
    let destPixels: UnsafeMutablePointer<UInt8> = CVPixelBufferGetBaseAddress(pixelBuffer)!.assumingMemoryBound(to: UInt8.self)
    data.copyBytes(to: destPixels, count: data.count)
    CVPixelBufferUnlockBaseAddress( pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)) )
  }
  
  
  override var isOpaque: Bool { return true }

  override var acceptsFirstResponder: Bool { return true }
  override func becomeFirstResponder() -> Bool
  {
    return true
  }
  
  override func resignFirstResponder() -> Bool
  {
    return true
  }
  
  
  // MARK: Context Menu
  // =====================================================================
  
  func menuNeedsUpdate(_ menu: NSMenu)
  {
  }


}
