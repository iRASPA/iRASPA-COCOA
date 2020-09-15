/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

public extension NSImage {
  func imageRotatedByDegreess(degrees:CGFloat) -> NSImage {
    
    var imageBounds = NSZeroRect ; imageBounds.size = self.size
    let pathBounds = NSBezierPath(rect: imageBounds)
    var transform = NSAffineTransform()
    transform.rotate(byDegrees: degrees)
    pathBounds.transform(using: transform as AffineTransform)
    let rotatedBounds:NSRect = NSMakeRect(NSZeroPoint.x, NSZeroPoint.y , self.size.width, self.size.height )
    let rotatedImage = NSImage(size: rotatedBounds.size)
    
    //Center the image within the rotated bounds
    imageBounds.origin.x = NSMidX(rotatedBounds) - (NSWidth(imageBounds) / 2)
    imageBounds.origin.y  = NSMidY(rotatedBounds) - (NSHeight(imageBounds) / 2)
    
    // Start a new transform
    transform = NSAffineTransform()
    // Move coordinate system to the center (since we want to rotate around the center)
    transform.translateX(by: +(NSWidth(rotatedBounds) / 2 ), yBy: +(NSHeight(rotatedBounds) / 2))
    transform.rotate(byDegrees: degrees)
    // Move the coordinate system bak to normal
    transform.translateX(by: -(NSWidth(rotatedBounds) / 2 ), yBy: -(NSHeight(rotatedBounds) / 2))
    // Draw the original image, rotated, into the new image
    rotatedImage.lockFocus()
    transform.concat()
    self.draw(in: imageBounds, from: NSZeroRect, operation: NSCompositingOperation.copy, fraction: 1.0)
    rotatedImage.unlockFocus()
    
    return rotatedImage
  }
}

class PrintingView: NSView
{
  var renderViewController: RenderTabViewController? = nil
  var image: NSImage? = nil
  var pageRect = NSRect()
  
  convenience init(_ renderViewController: RenderTabViewController?)
  {
    let data: Data = renderViewController?.picture ?? Data()
    let picture: NSImage = NSImage(data: data) ?? NSImage()
    
    self.init(frame: NSMakeRect(0, 0, picture.size.width, picture.size.height))
    self.image = picture
    self.renderViewController = renderViewController
  }
  
  override init(frame frameRect: NSRect)
  {
    super.init(frame: frameRect)
  }
  
  required init?(coder: NSCoder)
  {
    fatalError("unimplemented: instantiate programmatically instead")
  }
  
  override func draw(_ dirtyRect: NSRect)
  {
    super.draw(dirtyRect)
 
    if let image = image
    {
      let aspectWidth: CGFloat = pageRect.width / image.size.width
      let aspectHeight: CGFloat = pageRect.height / image.size.height
      let aspectRatio: CGFloat = min ( aspectWidth, aspectHeight )
      
      var scaledImageRect: NSRect = NSMakeRect(0, 0, 100, 100)
      scaledImageRect.size.width = image.size.width * aspectRatio
      scaledImageRect.size.height = image.size.height * aspectRatio
      scaledImageRect.origin.x = pageRect.origin.x + (pageRect.width - scaledImageRect.size.width) / 2.0
      scaledImageRect.origin.y = pageRect.origin.y + (pageRect.height - scaledImageRect.size.height) / 2.0
      
      image.draw(in: scaledImageRect, from: NSMakeRect(0, 0, image.size.width, image.size.height), operation: .copy, fraction: 1.0 )
    }
 
  }
 
  override func knowsPageRange(_ range: NSRangePointer) -> Bool
  {
    if let printOperation = NSPrintOperation.current
    {
      let printInfo: NSPrintInfo = printOperation.printInfo
    
      // Where can I draw?
      pageRect = printInfo.imageablePageBounds
      let newFrame = NSRect(origin: CGPoint(), size: printInfo.paperSize)
      frame = newFrame
    }
    
    range.pointee = NSMakeRange(1, 1)
    
    return true
  }
    
  override func rectForPage(_ page: Int) -> NSRect
  {
    // Return the same page every time
    return pageRect
  }
  
}
