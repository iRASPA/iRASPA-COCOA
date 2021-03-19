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
import MetalKit
import MathKit
import SimulationKit
import simd


class MetalView: MTKView
{
  var edrSupport: CGFloat = 1.0
  weak var renderCameraSource: RKRenderCameraSource?
  var renderQuality: RKRenderQuality = .high
  
  var trackball: RKTrackBall = RKTrackBall()
  var startPoint: NSPoint? = NSPoint()
  var panStartPoint: NSPoint? = NSPoint()
  
  enum Tracking
  {
    case none
    case panning
    case trucking
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
    
    NotificationCenter.default.addObserver(self, selector: #selector(screenParametersDidChange), name: NSApplication.didChangeScreenParametersNotification, object: NSApplication.shared)
  }
  
  deinit
  {
    NotificationCenter.default.removeObserver(self, name: NSApplication.didChangeScreenParametersNotification, object: NSApplication.shared)
  }
  
  @objc func screenParametersDidChange(notification: NSNotification)
  {
    let screen: NSScreen? = self.window?.screen
    if #available(OSX 10.15, *)
    {
      self.edrSupport = screen?.maximumPotentialExtendedDynamicRangeColorComponentValue ?? 1.0
    }
    else
    {
      // Fallback on earlier versions
      self.edrSupport = 1.0
    }
  }
  
  
  // MARK: Mouse control
  // =====================================================================
   
  
  override public func rightMouseDown(with event: NSEvent)
  {
    startPoint = nil
    panStartPoint = self.convert(event.locationInWindow, from: nil)

    if event.modifierFlags.contains(.option)
    {
      tracking = .panning
    }
    else
    if event.modifierFlags.contains(.command)
    {
      tracking = .trucking
    }
    else
    {
      // else pass on for context-menu
      super.rightMouseDown(with: event)
    }
  }
   
   
  override public func mouseDown(with theEvent: NSEvent)
  {
    super.mouseDown(with: theEvent)
     
    self.renderCameraSource?.renderCamera?.trackBallRotation = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
     
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
     
    self.renderQuality = RKRenderQuality.medium
    self.layer?.setNeedsDisplay()
  }
   
  override public func rightMouseDragged(with event: NSEvent)
  {
    switch(tracking)
    {
    case .panning:
      let location: NSPoint  = self.convert(event.locationInWindow, from: nil)
      if let panStartPoint = panStartPoint,
         let distance: SIMD3<Double> = self.renderCameraSource?.renderCamera?.distance
      {
        let panX: Double = Double(panStartPoint.x - location.x) * distance.z / 1500.0
        let panY: Double = Double(panStartPoint.y - location.y) * distance.z / 1500.0
         
        self.renderCameraSource?.renderCamera?.pan(x: panX, y: panY)
      }
      panStartPoint = location
       
      self.layer?.setNeedsDisplay()
    case .trucking:
      let location: NSPoint  = self.convert(event.locationInWindow, from: nil)
      if let panStartPoint = panStartPoint,
         let distance: SIMD3<Double> = self.renderCameraSource?.renderCamera?.distance
      {
        let panX: Double = Double(panStartPoint.x - location.x) * distance.z / 1500.0
        let panY: Double = Double(panStartPoint.y - location.y) * distance.z / 1500.0
         
        self.renderCameraSource?.renderCamera?.truck(x: panX, y: panY)
      }
      panStartPoint = location
       
      self.layer?.setNeedsDisplay()
    default:
      break
    }
    super.rightMouseDragged(with: event)
  }
   
  override public func mouseDragged(with theEvent: NSEvent)
  {
    super.mouseDragged(with: theEvent)
     
    let location: NSPoint  = self.convert(theEvent.locationInWindow, from: nil)
     
    self.renderQuality = RKRenderQuality.medium
     
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
        self.renderCameraSource?.renderCamera?.trackBallRotation = trackball.rollToTrackball(x: location.x, y: location.y)
      }
       
      self.layer?.setNeedsDisplay()
    }
  }
  
  override public func mouseUp(with theEvent: NSEvent)
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
      autoRotationTimer?.cancel()
      break
    default:
      if let _ = startPoint
      {
        self.renderCameraSource?.renderCamera?.trackBallRotation=trackball.rollToTrackball(x: location.x, y: location.y)
        
        if let trackBallRotation = self.renderCameraSource?.renderCamera?.trackBallRotation,
           let worldRotation = self.renderCameraSource?.renderCamera?.worldRotation
        {
          self.renderCameraSource?.renderCamera?.worldRotation = simd_normalize(simd_mul(trackBallRotation, worldRotation))
        }
      }
      self.renderCameraSource?.renderCamera?.trackBallRotation = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
    }
    
    startPoint = nil
    panStartPoint = nil
    tracking = .none
    self.renderQuality = RKRenderQuality.high
    
    self.layer?.setNeedsDisplay()
  }
  
  var timer: DispatchSourceTimer?
  var timerLastStamp: UInt64 = 0
  var timerRunning: Bool = false
  
  let timerQueue = DispatchQueue(label: "nl.darkwing.metalview.timer", attributes: .concurrent)
  
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
              strongSelf.renderQuality = RKRenderQuality.high
              strongSelf.timerRunning = false
            }
        
            // if not rotating already, then update display
            if strongSelf.tracking != .other
            {
              strongSelf.renderQuality = RKRenderQuality.high
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
  
  override public func scrollWheel(with theEvent: NSEvent)
  {
    let phase: NSEvent.Phase  = theEvent.phase
    
    timerLastStamp = mach_absolute_time()
    
    if (!timerRunning)
    {
      self.startTimer()
      
      timerRunning = true
      self.renderQuality = RKRenderQuality.medium
    }
    
    if (phase == NSEvent.Phase.began)
    {
      self.renderQuality = RKRenderQuality.medium
    }
    
    let wheelDelta: Double = Double(theEvent.deltaX + theEvent.deltaY + theEvent.deltaZ)
    
    self.renderCameraSource?.renderCamera?.increaseDistance(wheelDelta)
    
    // Bug: quits while the mouse events are still coming through
    //if (phase == NSEvent.Phase.ended || phase == NSEvent.Phase.cancelled)
    //{
    //  self.renderQuality = RKRenderQuality.high
    //  self.stopTimer()
    //}
    
    self.layer?.setNeedsDisplay()
    super.scrollWheel(with: theEvent)
  }
  
  public override func keyDown(with theEvent: NSEvent)
  {
    self.interpretKeyEvents([theEvent])

    super.keyDown(with: theEvent)
  }
  
  let autoRotationTimerQueue = DispatchQueue(label: "nl.darkwing.timer.autorotation", attributes: .concurrent)
  var autoRotationTimer: DispatchSourceTimer?
  
  public override func moveWordLeft(_ sender: Any?)
  {
    // cancel previous timer if any
    autoRotationTimer?.cancel()
    
    autoRotationTimer = DispatchSource.makeTimerSource(queue: autoRotationTimerQueue)
    
    autoRotationTimer?.schedule(deadline: .now(), repeating: .milliseconds(5), leeway: .milliseconds(10))
    
    autoRotationTimer?.setEventHandler { [weak self] in
      DispatchQueue.main.async(execute: {
        if let strongSelf = self
        {
          if let camera = strongSelf.renderCameraSource?.renderCamera
          {
            let theta: Double = -0.05 * Double.pi/180.0
            let trackBallRotation: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(0.0,1.0,0.0))
            camera.worldRotation = simd_normalize(simd_mul(trackBallRotation, camera.worldRotation))
            
            strongSelf.renderQuality = RKRenderQuality.low
            strongSelf.layer?.setNeedsDisplay()
          }
        }
      })
    }
    
    autoRotationTimer?.resume()
  }
  
  public override func moveWordRight(_ sender: Any?)
  {
    // cancel previous timer if any
    autoRotationTimer?.cancel()
    
    autoRotationTimer = DispatchSource.makeTimerSource(queue: autoRotationTimerQueue)
    
    autoRotationTimer?.schedule(deadline: .now(), repeating: .milliseconds(5), leeway: .milliseconds(10))
    
    autoRotationTimer?.setEventHandler { [weak self] in
      DispatchQueue.main.async(execute: {
        if let strongSelf = self
        {
          if let camera = strongSelf.renderCameraSource?.renderCamera
          {
            let theta: Double = 0.05 * Double.pi/180.0
            let trackBallRotation: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(0.0,1.0,0.0))
            camera.worldRotation = simd_normalize(simd_mul(trackBallRotation, camera.worldRotation))
            
            strongSelf.renderQuality = RKRenderQuality.low
            strongSelf.layer?.setNeedsDisplay()
          }
        }
      })
    }
    
    autoRotationTimer?.resume()
  }
  
  public override func moveBackward(_ sender: Any?)
  {
    // cancel previous timer if any
    autoRotationTimer?.cancel()
    
    autoRotationTimer = DispatchSource.makeTimerSource(queue: autoRotationTimerQueue)
    
    autoRotationTimer?.schedule(deadline: .now(), repeating: .milliseconds(5), leeway: .milliseconds(10))
    
    autoRotationTimer?.setEventHandler { [weak self] in
      DispatchQueue.main.async(execute: {
        if let strongSelf = self
        {
          if let camera = strongSelf.renderCameraSource?.renderCamera
          {
            let theta: Double = -0.05 * Double.pi/180.0
            let trackBallRotation: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(1.0,0.0,0.0))
            camera.worldRotation = simd_normalize(simd_mul(trackBallRotation, camera.worldRotation))
            
            strongSelf.renderQuality = RKRenderQuality.low
            strongSelf.layer?.setNeedsDisplay()
          }
        }
      })
    }
    
    autoRotationTimer?.resume()
  }
  
  // empty stub to avoid 'beep'
  public override func moveToBeginningOfParagraph(_ sender: Any?)
  {
    
  }
  
  public override func moveForward(_ sender: Any?)
  {
    // cancel previous timer if any
    autoRotationTimer?.cancel()
    
    autoRotationTimer = DispatchSource.makeTimerSource(queue: autoRotationTimerQueue)
    
    autoRotationTimer?.schedule(deadline: .now(), repeating: .milliseconds(5), leeway: .milliseconds(10))
    
    autoRotationTimer?.setEventHandler { [weak self] in
      DispatchQueue.main.async(execute: {
        if let strongSelf = self
        {
          if let camera = strongSelf.renderCameraSource?.renderCamera
          {
            let theta: Double = 0.05 * Double.pi/180.0
            let trackBallRotation: simd_quatd = simd_quatd(angle: theta, axis: SIMD3<Double>(1.0,0.0,0.0))
            camera.worldRotation = simd_normalize(simd_mul(trackBallRotation, camera.worldRotation))
            
            strongSelf.renderQuality = RKRenderQuality.low
            strongSelf.layer?.setNeedsDisplay()
          }
        }
      })
    }
    
    autoRotationTimer?.resume()
  }
  
  // empty stub to avoid 'beep'
  public override func moveToEndOfParagraph(_ sender: Any?)
  {
    
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
}
