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


// View-based table-views: row drawing customization should be done by subclassing NSTableRowView.

public class ProjectTableRowView: NSTableRowView, CALayerDelegate
{
  public var secondaryHighlighted: Bool = false
  
  var shapeLayer: CAShapeLayer? = nil
  var path: CGPath = CGMutablePath()
  
  
  override public var isOpaque: Bool { return false }
  
  override init(frame frameRect: NSRect)
  {
    super.init(frame: frameRect)
    wantsLayer = true
    
    // Optimzing Drawing and scrolling, 2013 session 215
    self.canDrawSubviewsIntoLayer = true
  }
  
  required public init?(coder: NSCoder)
  {
    super.init(coder: coder)
    wantsLayer = true
    
    // Optimzing Drawing and scrolling, 2013 session 215
    self.canDrawSubviewsIntoLayer = true
  }
  
  override public var wantsUpdateLayer: Bool
  {
    return false
  }
  
  deinit
  {
    self.shapeLayer = nil
  }
  
  
  public func draw(_ layer: CALayer, in ctx: CGContext)
  {
    if shapeLayer == nil
    {
      self.shapeLayer =  CAShapeLayer()
      shapeLayer?.lineWidth = 1.5
      shapeLayer?.strokeColor = NSColor.white.cgColor
      shapeLayer?.fillColor = nil
      self.path = CGPath(roundedRect: CGRect(x: 0.0, y: 0.0, width: self.bounds.width, height: max(12,self.bounds.height)), cornerWidth: 6.0, cornerHeight: 6.0, transform: nil)
      self.layer?.addSublayer(shapeLayer!)
    }
    
    if secondaryHighlighted
    {
      let cornerHeight: CGFloat = 6.0
      let cornerWidth: CGFloat = 6.0
      let rect: CGRect = CGRect(x: 0.0, y: 0.0, width: self.bounds.width, height: max(12,self.bounds.height))
      
      // Assertion: (corner_height >= 0 && 2 * corner_height <= CGRectGetHeight(rect))
      if ((cornerHeight >= 0) && (2.0 * cornerHeight <= rect.height ))
      {
        self.path = CGPath(roundedRect: rect, cornerWidth: cornerWidth, cornerHeight: cornerHeight, transform: nil)
      }
      
      self.shapeLayer?.path = self.path
      
      if (isEmphasized)
      {
        shapeLayer?.strokeColor = NSColor.white.cgColor
        shapeLayer?.lineWidth = 2.0
      }
      else
      {
        shapeLayer?.strokeColor = NSColor.systemGray.cgColor
        shapeLayer?.lineWidth = 2.0
      }
    }
    else
    {
      self.shapeLayer?.path = nil
    }
    
    // Needed on High Sierra
    let subLayers: [CALayer] = self.layer?.sublayers?.filter{$0.name == "NSVisualEffectView"} ?? []
    if !subLayers.isEmpty
    {
      subLayers.first?.addSublayer(shapeLayer!)
    }
  }
  
 
}

