/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 J.Vreede@uva.nl      https://www.uva.nl/en/profile/v/r/j.vreede/j.vreede.html
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

class TableImageViewIcon: NSImageView
{
  private var sourceImage: NSImage?
  
  /// Pixels darker than this luminance are drawn in the selection tint color;
  /// lighter pixels (e.g. document grey fill) become transparent.
  private let emphasisLuminanceThreshold: CGFloat = 0.58
  
  override init(frame frameRect: NSRect)
  {
    super.init(frame: frameRect)
    wantsLayer = false
  }
  
  required init?(coder: NSCoder)
  {
    super.init(coder: coder)
    wantsLayer = false
  }
  
  public override var intrinsicContentSize: NSSize
  {
    return NSSize.init(width: 16, height: super.intrinsicContentSize.height)
  }
  
  override var image: NSImage?
  {
    get { sourceImage }
    set
    {
      sourceImage = newValue
      if let cellView = enclosingTableCellView()
      {
        applyBackgroundStyle(cellView.backgroundStyle)
      }
      else
      {
        updateDisplayedImage()
      }
    }
  }
  
  func applyBackgroundStyle(_ style: NSView.BackgroundStyle)
  {
    cell?.backgroundStyle = style
    updateDisplayedImage(for: style)
  }
  
  override func viewDidMoveToWindow()
  {
    super.viewDidMoveToWindow()
    if let cellView = enclosingTableCellView()
    {
      applyBackgroundStyle(cellView.backgroundStyle)
    }
  }
  
  private func updateDisplayedImage(for style: NSView.BackgroundStyle? = nil)
  {
    let style = style ?? enclosingTableCellView()?.backgroundStyle ?? .normal
    guard let sourceImage = sourceImage else
    {
      super.image = nil
      contentTintColor = nil
      return
    }
    
    if style == .emphasized
    {
      if sourceImage.isTemplate
      {
        let displayedImage = (sourceImage.copy() as? NSImage) ?? sourceImage
        displayedImage.isTemplate = true
        super.image = displayedImage
        contentTintColor = .alternateSelectedControlTextColor
      }
      else
      {
        super.image = emphasizedIcon(from: sourceImage, color: .alternateSelectedControlTextColor) ?? sourceImage
        contentTintColor = nil
      }
    }
    else
    {
      super.image = sourceImage
      contentTintColor = nil
    }
    
    needsDisplay = true
  }
  
  private func emphasizedIcon(from image: NSImage, color: NSColor) -> NSImage?
  {
    var proposedRect = NSRect(origin: .zero, size: image.size)
    guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else
    {
      return nil
    }
    
    let width = cgImage.width
    let height = cgImage.height
    guard width > 0, height > 0,
          let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          ),
          let data = context.data
    else
    {
      return nil
    }
    
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    
    let tint = color.usingColorSpace(.deviceRGB) ?? color
    var tintRed: CGFloat = 0
    var tintGreen: CGFloat = 0
    var tintBlue: CGFloat = 0
    var tintAlpha: CGFloat = 0
    tint.getRed(&tintRed, green: &tintGreen, blue: &tintBlue, alpha: &tintAlpha)
    
    let tintR = UInt8(tintRed * 255)
    let tintG = UInt8(tintGreen * 255)
    let tintB = UInt8(tintBlue * 255)
    
    let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
    
    for y in 0..<height
    {
      for x in 0..<width
      {
        let index = (y * width + x) * 4
        let alpha = CGFloat(pixels[index + 3]) / 255.0
        if alpha < 0.05
        {
          continue
        }
        
        var red = CGFloat(pixels[index]) / 255.0
        var green = CGFloat(pixels[index + 1]) / 255.0
        var blue = CGFloat(pixels[index + 2]) / 255.0
        
        if alpha > 0
        {
          red /= alpha
          green /= alpha
          blue /= alpha
        }
        
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        
        if luminance < emphasisLuminanceThreshold
        {
          let outAlpha = UInt8(min(255, alpha * tintAlpha * 255))
          pixels[index] = tintR
          pixels[index + 1] = tintG
          pixels[index + 2] = tintB
          pixels[index + 3] = outAlpha
        }
        else
        {
          pixels[index] = 0
          pixels[index + 1] = 0
          pixels[index + 2] = 0
          pixels[index + 3] = 0
        }
      }
    }
    
    guard let outputCGImage = context.makeImage() else
    {
      return nil
    }
    
    return NSImage(cgImage: outputCGImage, size: image.size)
  }
  
  private func enclosingTableCellView() -> NSTableCellView?
  {
    var view: NSView? = superview
    while let current = view
    {
      if let cellView = current as? NSTableCellView { return cellView }
      view = current.superview
    }
    return nil
  }
}
