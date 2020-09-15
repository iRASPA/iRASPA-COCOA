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

/*
extension NSViewController
{
  
  @IBAction func screenShotPDF(_ sender: AnyObject)
  {
    do
    {
      let data: Data = self.view.dataWithPDF(inside: self.view.bounds)
      
      let fm = FileManager.default
      let docsurl = try fm.url(for:.downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      let myurl = docsurl.appendingPathComponent("snapshot.pdf")
      try data.write(to: myurl)
    }
    catch let error
    {
      print("\(error.localizedDescription)")
    }
  }

  
  
  @IBAction func screenShotPNG(_ sender: AnyObject)
  {
    if let layer = self.view.layer
    {
      let pixelsHigh: Int = Int(layer.bounds.size.height)
      let pixelsWide: Int = Int(layer.bounds.size.width)
      let bitmapBytesPerRow: Int   = (pixelsWide * 4)
      
      let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
      let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
      if let context = CGContext(data: nil, width: pixelsWide, height: pixelsHigh, bitsPerComponent: 8, bytesPerRow: bitmapBytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
      {
        context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        context.fill(layer.bounds)
        context.setShouldSmoothFonts(true)
        
        layer.presentation()?.render(in: context)
        
        if let img: CGImage = context.makeImage(),
          let pngData: Data = NSBitmapImageRep(cgImage: img).representation(using: NSBitmapImageRep.FileType.png, properties: [:])
        {
          do
          {
            let fm = FileManager.default
            let docsurl = try fm.url(for:.downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let myurl = docsurl.appendingPathComponent("snapshot.png")
            try pngData.write(to: myurl)
          }
          catch let error
          {
            print("\(error.localizedDescription)")
          }
        }
      }
    }
  }
}
*/
