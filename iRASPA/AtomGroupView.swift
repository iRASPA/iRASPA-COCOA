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

class AtomGroupStackView: NSStackView
{
  @IBOutlet private weak var textField: NSTextField?
  @IBOutlet private weak var checkBox: NSButton?
  

  var isSelected: Bool = false
  {
    didSet
    {
      textField?.cell?.backgroundStyle = isSelected ? NSView.BackgroundStyle.dark : NSView.BackgroundStyle.light
    }
  }
  
  var draggingImageComponents: [NSDraggingImageComponent]
  {
    let component: NSDraggingImageComponent = NSDraggingImageComponent(key: NSDraggingItem.ImageComponentKey.label)
    if let textField = textField
    {
      component.contents = cacheImageOfView(textField)
      component.frame = self.convert(textField.bounds, to: textField)
      return [component]
    }
    else
    {
      return []
    }
  }

  
  func cacheImageOfView(_ view: NSView) -> NSImage
  {
    let bounds: NSRect = view.bounds
    let bitmapImageRep: NSBitmapImageRep = view.bitmapImageRepForCachingDisplay(in: bounds)!
 
    bzero(bitmapImageRep.bitmapData, bitmapImageRep.bytesPerRow * bitmapImageRep.pixelsHigh)
  
    view.cacheDisplay(in: bounds, to: bitmapImageRep)
 
    let imageCache: NSImage = NSImage(size: bitmapImageRep.size)

    imageCache.addRepresentation(bitmapImageRep)
  
    return imageCache
  }
}
