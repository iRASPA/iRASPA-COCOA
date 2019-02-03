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

extension float3x3
{
  public init(simd_quatd q: simd_quatd)
  {
    let sqw: Double = q.vector.w*q.vector.w
    let sqx: Double = q.vector.x*q.vector.x
    let sqy: Double = q.vector.y*q.vector.y
    let sqz: Double = q.vector.z*q.vector.z
    
    self.init()
    
    // invs (inverse square length) is only required if quaternion is not already normalised
    let invs: Double = 1 / (sqx + sqy + sqz + sqw)
    self[0,0] = Float(( sqx - sqy - sqz + sqw) * invs)  // since sqw + sqx + sqy + sqz =1/invs*invs
    self[1,1] = Float((-sqx + sqy - sqz + sqw) * invs)
    self[2,2] = Float((-sqx - sqy + sqz + sqw) * invs)
    
    
    var tmp1: Double = q.vector.x*q.vector.y
    var tmp2: Double = q.vector.z*q.vector.w
    self[0,1] = Float(2.0 * (tmp1 + tmp2)*invs)
    self[1,0] = Float(2.0 * (tmp1 - tmp2)*invs)
    
    tmp1 = q.vector.x*q.vector.z
    tmp2 = q.vector.y*q.vector.w
    self[0,2] = Float(2.0 * (tmp1 - tmp2) * invs)
    self[2,0] = Float(2.0 * (tmp1 + tmp2) * invs)
    
    tmp1 = q.vector.y * q.vector.z
    tmp2 = q.vector.x * q.vector.w
    self[1,2] = Float(2.0 * (tmp1 + tmp2) * invs)
    self[2,1] = Float(2.0 * (tmp1 - tmp2) * invs)
  }
}
