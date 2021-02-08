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

extension NSShadow
{
  convenience init(color: NSColor, offset: NSSize, blurRadius blur: CGFloat)
  {
    self.init()
    
    self.shadowColor = color
    self.shadowOffset = offset
    self.shadowBlurRadius = blur
  }
}

extension NSBezierPath
{
  func strokeInside()
  {
    self.strokeInsideWithinRect(NSZeroRect)
  }
  
  func strokeInsideWithinRect(_ clipRect: NSRect)
  {
    
    if let thisContext: NSGraphicsContext = NSGraphicsContext.current
    {
      let lineWidth: CGFloat  = self.lineWidth
    
      /* Save the current graphics context. */
      thisContext.saveGraphicsState()
    
      /* Double the stroke width, since -stroke centers strokes on paths. */
      self.lineWidth = lineWidth * 2.0
    
      /* Clip drawing to this path; draw nothing outwith the path. */
      self.setClip()
    
      /* Further clip drawing to clipRect, usually the view's frame. */
      if (clipRect.size.width > 0.0 && clipRect.size.height > 0.0)
      {
        NSBezierPath.clip(clipRect)
      }
    
      /* Stroke the path. */
      self.stroke()
    
      /* Restore the previous graphics context. */
      thisContext.restoreGraphicsState()
      self.lineWidth = lineWidth
    }
    
  }
  
  func fillWithInnerShadow(_ shadow: NSShadow)
  {
    NSGraphicsContext.saveGraphicsState()
    
    var offset: NSSize = shadow.shadowOffset
    let originalOffset: NSSize = offset
    let radius: CGFloat  = shadow.shadowBlurRadius
    let bounds: NSRect = NSInsetRect(self.bounds, -(abs(offset.width) + radius), -(abs(offset.height) + radius));
    offset.height += bounds.size.height
    shadow.shadowOffset = offset
    var transform: AffineTransform = AffineTransform()
    if (NSGraphicsContext.current!.isFlipped)
    {
      transform.translate(x: 0, y: bounds.size.height)
    }
    else
    {
      transform.translate(x: 0, y: -bounds.size.height)
    }
    
    let drawingPath: NSBezierPath = NSBezierPath(rect: bounds)
    drawingPath.windingRule = .evenOdd
    drawingPath.append(self)
    drawingPath.transform(using: transform)
    self.addClip()
    shadow.set()
    NSColor.black.set()
    drawingPath.fill()
    
    shadow.shadowOffset = originalOffset;
    
    NSGraphicsContext.restoreGraphicsState()
    
  }
}

class NSInformationPanelView: NSView
{
   
  override var wantsUpdateLayer: Bool
  {
    return true
  }
  

  override func updateLayer()
  {
    self.layer?.contents = NSImage(size: self.bounds.size, flipped: false, drawingHandler: {rect  in
      
      var kDropShadow: NSShadow? = nil
      var kInnerShadow: NSShadow? = nil
      var kBackgroundGradient: NSGradient? = nil
      var kBorderColor: NSColor? = nil
      
      if (kDropShadow == nil)
      {
        kDropShadow = NSShadow(color: NSColor(calibratedWhite: 0.863, alpha: 0.75), offset: NSMakeSize(0, -1.0), blurRadius: 1.0)
        kInnerShadow = NSShadow(color: NSColor(calibratedWhite: 0.0, alpha: 0.52), offset: NSMakeSize(0, -1.0), blurRadius: 4.0)
        kBorderColor = NSColor(calibratedWhite: 0.569, alpha: 1.0)
        
        // iTunes style
        //
        kBackgroundGradient = NSGradient(colorsAndLocations: (NSColor(calibratedRed: 0.929, green: 0.945, blue: 0.882, alpha: 1.0),0.0),
                                         (NSColor(calibratedRed: 0.902, green: 0.922, blue: 0.835, alpha: 1.0),0.5),
                                         (NSColor(calibratedRed: 0.871, green: 0.894, blue: 0.78, alpha: 1.0),0.5),
                                         (NSColor(calibratedRed: 0.949, green: 0.961, blue: 0.878, alpha: 1.0),1.0))
        
        
      }
      
      
      var bounds: NSRect = rect
      bounds.size.height -= 1.0
      bounds.origin.y += 1.0
      
      let path: NSBezierPath = NSBezierPath(roundedRect: bounds, xRadius: 3.5, yRadius: 3.5)
      
      NSGraphicsContext.saveGraphicsState()
      kDropShadow?.set()
      path.fill()
      NSGraphicsContext.restoreGraphicsState()
      
      kBackgroundGradient?.draw(in: path, angle: -90.0)
      
      kBorderColor?.setStroke()
      path.strokeInside()
      path.fillWithInnerShadow(kInnerShadow!)
      return true
    })
    
  }
  
  override func draw(_ dirtyRect: NSRect)
  {
    super.draw(dirtyRect)
    // Drawing code here.
    
  }
  
}
