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
import iRASPAKit
import RenderKit
import PowerSourceKit

class RenderTabView: NSView, CALayerDelegate, ProjectConsumer
{
  var proxyProject: ProjectTreeNode?
 
  var useSelectionAnimation: Bool = true
  let pulseAnimation:CABasicAnimation = CABasicAnimation(keyPath: "bloomPulse")
  
  var shapeLayerNewSelection: CAShapeLayer! = nil
  var shapeLayerAddSelection: CAShapeLayer! = nil
  
  override init(frame frameRect: NSRect)
  {
    super.init(frame: frameRect)
    self.wantsLayer = true
    self.layer = AnimatedPropertiesLayer()
    self.layer?.delegate = self
    self.layer?.isHidden = false
    
    pulseAnimation.duration = 0.5
    pulseAnimation.fromValue = NSNumber(value: 1.0)
    pulseAnimation.toValue = NSNumber(value: 0.0)
    pulseAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
    pulseAnimation.autoreverses = true
    pulseAnimation.repeatCount = Float.greatestFiniteMagnitude
    
    self.shapeLayerNewSelection = CAShapeLayer()
    self.shapeLayerNewSelection.lineWidth = 2.0
    self.shapeLayerNewSelection.strokeColor = CGColor(red: 0,green: 0,blue: 0,alpha: 1)
    self.shapeLayerNewSelection.fillColor = CGColor(red: 0.8,green: 0.8,blue: 0.8,alpha: 0.35)
    self.shapeLayerNewSelection.lineDashPattern = nil
    
    // create and configure shape layer
    self.shapeLayerAddSelection = CAShapeLayer()
    self.shapeLayerAddSelection.lineWidth = 2.0
    self.shapeLayerAddSelection.strokeColor = CGColor(red: 0,green: 0,blue: 0,alpha: 1)
    self.shapeLayerAddSelection.fillColor = CGColor(red: 0.8,green: 0.8,blue: 0.8,alpha: 0.35)
    self.shapeLayerAddSelection.lineDashPattern = [10,5]
    
    
    NotificationCenter.default.addObserver(self, selector: #selector(RenderTabView.powerSourceChange(_:)), name: NSNotification.Name(rawValue: PowerSourceDidChange), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(RenderTabView.preferencesPowerSourceChanged(_:)), name: NSNotification.Name(rawValue: Preferences.AnimationSettingsDidChange), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(RenderTabView.preferencesTooltipChanged(_:)), name: NSNotification.Name(rawValue: Preferences.TooltipSettingsDidChange), object: nil)
    
    (NSApp.delegate as? AppDelegate)?.powerSource.checkPowerConnection()
  }
  
  required init?(coder decoder: NSCoder)
  {
    super.init(coder: decoder)
    self.wantsLayer = true
    self.layer = AnimatedPropertiesLayer()
    self.layer?.delegate = self
    self.layer?.isHidden = false
    
    pulseAnimation.duration = 0.5
    pulseAnimation.fromValue = NSNumber(value: 1.0)
    pulseAnimation.toValue = NSNumber(value: 0.0)
    pulseAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
    pulseAnimation.autoreverses = true
    pulseAnimation.repeatCount = Float.greatestFiniteMagnitude
    
    self.shapeLayerNewSelection = CAShapeLayer()
    self.shapeLayerNewSelection.lineWidth = 2.0
    self.shapeLayerNewSelection.strokeColor = CGColor(red: 0,green: 0,blue: 0,alpha: 1)
    self.shapeLayerNewSelection.fillColor = CGColor(red: 0.8,green: 0.8,blue: 0.8,alpha: 0.35)
    self.shapeLayerNewSelection.lineDashPattern = nil
    
    // create and configure shape layer
    self.shapeLayerAddSelection = CAShapeLayer()
    self.shapeLayerAddSelection.lineWidth = 2.0
    self.shapeLayerAddSelection.strokeColor = CGColor(red: 0,green: 0,blue: 0,alpha: 1)
    self.shapeLayerAddSelection.fillColor = CGColor(red: 0.8,green: 0.8,blue: 0.8,alpha: 0.35)
    self.shapeLayerAddSelection.lineDashPattern = [10,5]
    
    NotificationCenter.default.addObserver(self, selector: #selector(RenderTabView.powerSourceChange(_:)), name: NSNotification.Name(rawValue: PowerSourceDidChange), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(RenderTabView.preferencesPowerSourceChanged(_:)), name: NSNotification.Name(rawValue: Preferences.AnimationSettingsDidChange), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(RenderTabView.preferencesTooltipChanged(_:)), name: NSNotification.Name(rawValue: Preferences.TooltipSettingsDidChange), object: nil)
    
    (NSApp.delegate as? AppDelegate)?.powerSource.checkPowerConnection()
  }
  
  // MARK: Animation
  // ===============================================================================================================================
  
  @objc func powerSourceChange(_ notification: Notification)
  {
    self.evaluateSelectionAnimation()
  }
  
  @objc func preferencesPowerSourceChanged(_ notification: Notification)
  {
    self.evaluateSelectionAnimation()
  }
  
  
  public func display(_ layer: CALayer)
  {
    if let animationKeys: [String] = self.layer?.animationKeys(),
       animationKeys.contains("animateBloomLevel"),
       let bloomPulse = (self.layer as? AnimatedPropertiesLayer)?.presentation()?.bloomPulse
    {
      (self.proxyProject?.representedObject.project as? ProjectStructureNode)?.renderCamera?.bloomPulse = bloomPulse
      (self.window?.windowController as? iRASPAWindowController)?.detailTabViewController?.renderViewController?.redraw()
    }
  }
  
  func evaluateSelectionAnimation()
  {
    if let project: ProjectStructureNode = proxyProject?.representedObject.loadedProjectStructureNode
    {
      if project.hasSelectedObjects
      {
        switch(Preferences.shared.selectionAnimation)
        {
        case .always:
          addSelectionAnimation()
          (self.window?.windowController as? iRASPAWindowController)?.detailTabViewController?.renderViewController?.redraw()
        case .whenConnectedToPower:
          if PowerSource.shared().powerSourceType == .limited
          {
            removeSelectionAnimation()
            project.renderCamera?.bloomPulse = 1.0
            (self.window?.windowController as? iRASPAWindowController)?.detailTabViewController?.renderViewController?.redraw()
          }
          else
          {
            addSelectionAnimation()
            (self.window?.windowController as? iRASPAWindowController)?.detailTabViewController?.renderViewController?.redraw()
          }
        case .undefined, .never:
          removeSelectionAnimation()
          project.renderCamera?.bloomPulse = 1.0
          (self.window?.windowController as? iRASPAWindowController)?.detailTabViewController?.renderViewController?.redraw()
        }
      }
      else
      {
        // of course: no animation when no selection
        self.removeSelectionAnimation()
      }
    }
  }
  
  func addSelectionAnimation()
  {
    guard useSelectionAnimation else {return}
    
    // check if the selection is already animating
    if let animationKeys: [String] = self.layer?.animationKeys()
    {
      if animationKeys.contains("animateBloomLevel")
      {
        return
      }
    }
    
    self.layer?.add(pulseAnimation, forKey: "animateBloomLevel")
  }
  
  func removeSelectionAnimation()
  {
    // check if the selection is already animating
    if let animationKeys: [String] = self.layer?.animationKeys()
    {
      if animationKeys.contains("animateBloomLevel")
      {
        self.layer?.removeAnimation(forKey: "animateBloomLevel")
      }
    }
  }
  
  
  // MARK: Tooltips
  // ===============================================================================================================================
  
  var toolTipTag: NSView.ToolTipTag?
  
  var mouseMoveTimer: DispatchSourceTimer?
  var mouseMoveTimerLastStamp: UInt64 = 0
  var mouseMoveTimerRunning: Bool = false
  
  let mouseMoveTimerQueue = DispatchQueue(label: "nl.darkwing.timer.mouse.move", attributes: .concurrent)
  
  @objc func preferencesTooltipChanged(_ notification: Notification)
  {
    if Preferences.shared.showRenderTooptip == false
    {
      stopMouseMoveTimer()
    }
  }
  
  private func startMouseMoveTimer()
  {
    mouseMoveTimer?.cancel()        // cancel previous timer if any
    
    mouseMoveTimer = DispatchSource.makeTimerSource(queue: mouseMoveTimerQueue)
    
    mouseMoveTimer?.schedule(deadline: .now(), repeating: .milliseconds(100), leeway: .milliseconds(10))
    
    mouseMoveTimer?.setEventHandler { [weak self] in
      DispatchQueue.main.async(execute: {
        if let strongSelf = self
        {
          let stamp: UInt64  = mach_absolute_time()
      
          if ((stamp - strongSelf.mouseMoveTimerLastStamp) > 1 * NSEC_PER_SEC/10)
          {
            // mouse has not moved for at least 0.1 seconds
            if (strongSelf.mouseMoveTimerRunning)
            {
              strongSelf.mouseMoveTimer?.cancel()
              strongSelf.mouseMoveTimer=nil
              if Preferences.shared.showRenderTooptip
              {
                strongSelf.toolTipTag = strongSelf.addToolTip(strongSelf.bounds, owner: strongSelf.nextResponder ?? strongSelf, userData: nil)
              }
              strongSelf.mouseMoveTimerRunning = false
            }
          }
        }
      })
    }
    
    mouseMoveTimer?.resume()
  }
  
  private func stopMouseMoveTimer()
  {
    mouseMoveTimer?.cancel()
    mouseMoveTimer = nil
  }
  
  
  
  var trackingArea : NSTrackingArea?
  
  override func updateTrackingAreas() {
    if trackingArea != nil
    {
      self.removeTrackingArea(trackingArea!)
    }
    let options : NSTrackingArea.Options = [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited, .enabledDuringMouseDrag ]
    trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
    self.addTrackingArea(trackingArea!)
  }
  
  override func mouseExited(with event: NSEvent)
  {
    super.mouseExited(with: event)
    stopMouseMoveTimer()
    self.mouseMoveTimerRunning = false
  }
  
  override func mouseEntered(with event: NSEvent)
  {
    super.mouseEntered(with: event)
  }
  

  
  var mouseMoveLastTimeStamp: UInt64 = mach_absolute_time()
  
  override func mouseMoved(with event: NSEvent)
  {
    super.mouseMoved(with: event)

    mouseMoveTimerLastStamp = mach_absolute_time()
    
    if (!mouseMoveTimerRunning)
    {
      if let toolTipTag = self.toolTipTag
      {
        self.removeToolTip(toolTipTag)
        self.toolTipTag = nil
      }
      
      self.startMouseMoveTimer()
      
      mouseMoveTimerRunning = true
    }
  }
  
  override func mouseDown(with event: NSEvent)
  {
    super.mouseDown(with: event)
    mouseMoveTimerLastStamp = mach_absolute_time()
    if let toolTipTag = self.toolTipTag
    {
      self.removeToolTip(toolTipTag)
      self.toolTipTag = nil
    }
    stopMouseMoveTimer()
    
   
  }
 
  
  
  override func mouseUp(with event: NSEvent)
  {
    super.mouseUp(with: event)
    mouseMoveTimerLastStamp = mach_absolute_time()
    
    if let toolTipTag = self.toolTipTag
    {
      self.removeToolTip(toolTipTag)
      self.toolTipTag = nil
    }
      
    self.startMouseMoveTimer()
      
    mouseMoveTimerRunning = true
  }
}
