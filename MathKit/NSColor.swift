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

import Foundation
import simd

extension NSColor
{
  public convenience init(colorCode: UInt32)
  {
    // colorCode=(r,g,b) -> shift and mask off high bits
    let redColor: CGFloat = CGFloat((colorCode >> 16) & 0x0000FF)/255.0
    let greenColor: CGFloat = CGFloat((colorCode >> 8)  & 0x0000FF)/255.0
    let blueColor: CGFloat = CGFloat(colorCode & 0x0000FF)/255.0
    self.init(calibratedRed: redColor, green: greenColor, blue: blueColor, alpha: 1.0)
  }
  
  public convenience init(float4: SIMD4<Float>)
  {
    self.init(calibratedRed: CGFloat(float4.x), green: CGFloat(float4.y), blue: CGFloat(float4.z), alpha: CGFloat(float4.w))
  }
}
