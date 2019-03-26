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

extension float4x4
{
  public init(Double4x4: double4x4)
  {
    self.init([float4(Double4: Double4x4[0]), float4(Double4: Double4x4[1]), float4(Double4: Double4x4[2]), float4(Double4: Double4x4[3])])
  }
  
  public init(Double3x3: double3x3)
  {
    self.init([float4(x: Float(Double3x3[0,0]), y: Float(Double3x3[0,1]), z: Float(Double3x3[0,2]), w: 0.0),
               float4(x: Float(Double3x3[1,0]), y: Float(Double3x3[1,1]), z: Float(Double3x3[1,2]), w: 0.0),
               float4(x: Float(Double3x3[2,0]), y: Float(Double3x3[2,1]), z: Float(Double3x3[2,2]), w: 0.0),
               float4(x: 0.0, y: 0.0, z: 0.0, w: 1.0)])
  }
}
