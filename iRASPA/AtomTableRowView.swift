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

class AtomTableRowView: NSTableRowView
{
  var isImplicitelySelected: Bool = false
  
  override init(frame frameRect: NSRect)
  {
    super.init(frame: frameRect)
    
    self.wantsLayer = true
    
    // Optimzing Drawing and scrolling, 2013 session 215
    self.canDrawSubviewsIntoLayer = true
  }
  
  required init?(coder: NSCoder)
  {
    super.init(coder: coder)
    
    self.wantsLayer = true
    
    // Optimzing Drawing and scrolling, 2013 session 215
    self.canDrawSubviewsIntoLayer = true
  }
  
  override var isOpaque: Bool { return false }
  
    
  override func drawBackground(in dirtyRect: NSRect)
  {
    if isImplicitelySelected
    {
      super.drawBackground(in: dirtyRect)
      if self.isEmphasized
      {
        NSColor.alternateSelectedControlColor.withAlphaComponent(0.20).set()
      }
      else
      {
        NSColor.secondarySelectedControlColor.withAlphaComponent(0.70).set()
      }
      dirtyRect.fill()
    }
    else
    {
      super.drawBackground(in: dirtyRect)
    }
  }
  
  override var isSelected: Bool
  {
    didSet
    {
      for view in subviews
      {
        if let view = view as? AtomGroupStackView
        {
          view.isSelected = isSelected
        }
      }
    }
  }
  
  
  override func drawSelection(in dirtyRect: NSRect)
  {
    let lightBlue: NSColor
    if self.isEmphasized
    {
      lightBlue = NSColor.alternateSelectedControlColor
    }
    else
    {
      lightBlue = NSColor.secondarySelectedControlColor
    }
    lightBlue.setStroke()
    lightBlue.setFill()
    let selectionPath: NSBezierPath = NSBezierPath(rect: self.bounds)
    selectionPath.fill()
    selectionPath.stroke()
  }
  
}
