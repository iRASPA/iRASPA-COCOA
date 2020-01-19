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

class ProjectSlideCarrierView: NSView
{
  var imageRef: CGImage?
  
  override init(frame frameRect: NSRect)
  {
    let image = NSImage(named: "ProjectSlideCarrier")
    imageRef = nil
    if let image = image
    {
      var imageRect: CGRect = NSMakeRect(0, 0, image.size.width, image.size.height)
      imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
    }
    
    super.init(frame: frameRect)
  }
  
  required init?(coder: NSCoder)
  {
    let image = NSImage(named: "ProjectSlideCarrier")
    imageRef = nil
    if let image = image
    {
      var imageRect: CGRect = NSMakeRect(0, 0, image.size.width, image.size.height)
      imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
    }
    
    super.init(coder: coder)
    
    
  }
  
  override func updateLayer()
  {
    self.layer?.contents = imageRef
    
    self.updateBorderView()
  }
  
  var highlightState: NSCollectionViewItem.HighlightState = NSCollectionViewItem.HighlightState.none
  {
    didSet
    {
      self.needsDisplay = true
    }
  }
  
  var isSelected: Bool = false
  {
    didSet
    {
      self.needsDisplay = true
    }
  }
  
  var SLIDE_SHADOW_MARGIN: CGFloat = 10.0
  var SLIDE_BORDER_WIDTH: CGFloat = 4.0
  
  func updateBorderView()
  {
    var borderColor: NSColor? = nil
    
    if (highlightState == NSCollectionViewItem.HighlightState.forSelection)
    {
      
      // Item is a candidate to become selected: Show an orange border around it.
      borderColor = NSColor.orange
      
    }
    else if (highlightState == NSCollectionViewItem.HighlightState.asDropTarget)
    {
      // Item is a candidate to receive dropped items: Show a red border around it.
      borderColor = NSColor.red
      
    }
    else if (isSelected && highlightState != NSCollectionViewItem.HighlightState.forDeselection)
    {
      
      // Item is selected, and is not indicated for proposed deselection: Show an Aqua border around it.
      borderColor = NSColor(calibratedRed:0.0, green:0.5, blue:1.0, alpha:1.0) // Aqua
      
    }
    else
    {
      // Item is either not selected, or is selected but not highlighted for deselection: Sbhow no border around it.
      borderColor = nil
    }
    
    var borderView: ProjectSlideBorderView? = self.borderView
    
    if let borderColor = borderColor
    {
      if borderView == nil
      {
        let bounds: NSRect = self.bounds
        let shapeBox: NSRect = NSInsetRect(bounds, (SLIDE_SHADOW_MARGIN - 0.5 * SLIDE_BORDER_WIDTH), (SLIDE_SHADOW_MARGIN - 0.5 * SLIDE_BORDER_WIDTH))
        let newBorderView = ProjectSlideBorderView(frame: shapeBox)
        self.addSubview(newBorderView)
        borderView = newBorderView
      }
      borderView?.borderColor = borderColor
    }
    else
    {
      borderView?.removeFromSuperview()
    }
    
  }
  
  
  var borderView: ProjectSlideBorderView?
  {
    for subview in self.subviews
    {
      if let subview: ProjectSlideBorderView = subview as? ProjectSlideBorderView
      {
        return subview
      }
    }
    return nil
  }
}
