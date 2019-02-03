/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2019 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

extension float4
{
  public init(color: NSColor)
  {
    if let color = color.usingColorSpace(NSColorSpace.genericRGB)
    {
      self.init(x: Float(color.redComponent), y: Float(color.greenComponent), z: Float(color.blueComponent), w: Float(color.alphaComponent))
    }
    else
    {
      self.init(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
    }
  }
  
  public init(color: NSColor, opacity: Double)
  {
    if let color = color.usingColorSpace(NSColorSpace.genericRGB)
    {
      self.init(x: Float(color.redComponent), y: Float(color.greenComponent), z: Float(color.blueComponent), w: Float(opacity))
    }
    else
    {
      self.init(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
    }
  }
  
  public init(value: Double)
  {
    self.init(x: Float(value), y: Float(value), z: Float(value), w: 1.0)
  }
  public init(x: Double, y: Double, z: Double, w: Double)
  {
    self.init(x: Float(x), y: Float(y), z: Float(z), w: Float(w))
    
  }
  public init(Double4: double4)
  {
    self.init(x: Float(Double4.x), y: Float(Double4.y), z: Float(Double4.z), w: Float(Double4.w))
    
  }
  public init(xyz: double3, w: Double)
  {
    self.init(x: Float(xyz.x), y: Float(xyz.y), z: Float(xyz.z), w: Float(w))
  }
  
}

extension float4: Decodable
{
  // MARK: -
  // MARK: Decodable support
  
  public init(from decoder: Decoder) throws
  {
    var container = try decoder.unkeyedContainer()
    
    let x = try container.decode(Float.self)
    let y = try container.decode(Float.self)
    let z = try container.decode(Float.self)
    let w = try container.decode(Float.self)
    self.init(x,y,z,w)
  }
}






