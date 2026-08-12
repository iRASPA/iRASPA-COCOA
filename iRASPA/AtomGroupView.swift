/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
  @IBOutlet private weak var ribbonVisibilityControl: NSSegmentedControl?
  

  var isSelected: Bool = false
  {
    didSet
    {
      textField?.cell?.backgroundStyle = isSelected ? NSView.BackgroundStyle.emphasized : NSView.BackgroundStyle.normal
    }
  }
  
  override func awakeFromNib()
  {
    super.awakeFromNib()
    configureHorizontalLayout()
  }
  
  /// Keep the name left-aligned whether the row is editable or read-only.
  /// When the text field is not editable it shrinks to its string width; with
  /// `distribution = .fill` that lets the visibility control absorb free space
  /// and pushes the label to the right (noticeable on Gallery / read-only projects).
  func configureHorizontalLayout()
  {
    distribution = .fill
    orientation = .horizontal
    alignment = .centerY
    
    checkBox?.setContentHuggingPriority(.required, for: .horizontal)
    checkBox?.setContentCompressionResistancePriority(.required, for: .horizontal)
    ribbonVisibilityControl?.setContentHuggingPriority(.required, for: .horizontal)
    ribbonVisibilityControl?.setContentCompressionResistancePriority(.required, for: .horizontal)
    
    textField?.alignment = .left
    textField?.setContentHuggingPriority(.defaultLow, for: .horizontal)
    textField?.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
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
