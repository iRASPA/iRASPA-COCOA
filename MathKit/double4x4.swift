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

import Foundation
import simd

extension double4x4 {
  public var inverseReplacement: double4x4 {
    return self.inverse
  }
}

extension double4x4
{
  public init(Double3x3: double3x3)
  {
    self.init([SIMD4<Double>(x: Double3x3[0,0], y: Double3x3[0,1], z: Double3x3[0,2], w: 0.0),
               SIMD4<Double>(x: Double3x3[1,0], y: Double3x3[1,1], z: Double3x3[1,2], w: 0.0),
               SIMD4<Double>(x: Double3x3[2,0], y: Double3x3[2,1], z: Double3x3[2,2], w: 0.0),
               SIMD4<Double>(x: 0.0, y: 0.0, z: 0.0, w: 1.0)])
  }
  
  public init(quaternion q: simd_quatd, translation t: SIMD3<Double>)
  {
    
    self.init()
    
    let sqw: Double = q.vector.w*q.vector.w
    let sqx: Double = q.vector.x*q.vector.x
    let sqy: Double = q.vector.y*q.vector.y
    let sqz: Double = q.vector.z*q.vector.z
    
    // invs (inverse square length) is only required if quaternion is not already normalised
    let invs: Double = 1 / (sqx + sqy + sqz + sqw)
    self[0,0] = ( sqx - sqy - sqz + sqw) * invs  // since sqw + sqx + sqy + sqz =1/invs*invs
    self[1,1] = (-sqx + sqy - sqz + sqw) * invs
    self[2,2] = (-sqx - sqy + sqz + sqw) * invs
    self[3,3] = 1.0
    
    var tmp1: Double = q.vector.x*q.vector.y
    var tmp2: Double = q.vector.z*q.vector.w
    self[0,1] = 2.0 * (tmp1 + tmp2)*invs
    self[1,0] = 2.0 * (tmp1 - tmp2)*invs
    self[3,0] = t.x
    self[0,3] = 0.0
    
    tmp1 = q.vector.x*q.vector.z
    tmp2 = q.vector.y*q.vector.w
    self[0,2] = 2.0 * (tmp1 - tmp2) * invs
    self[2,0] = 2.0 * (tmp1 + tmp2) * invs
    self[3,1] = t.y
    self[1,3] = 0.0
    
    tmp1 = q.vector.y * q.vector.z
    tmp2 = q.vector.x * q.vector.w
    self[1,2] = 2.0 * (tmp1 + tmp2) * invs
    self[2,1] = 2.0 * (tmp1 - tmp2) * invs
    self[3,2] = t.z
    self[2,3] = 0.0
    
  }
  
  public init(simd_quatd q: simd_quatd)
  {
    let sqw: Double = q.vector.w*q.vector.w
    let sqx: Double = q.vector.x*q.vector.x
    let sqy: Double = q.vector.y*q.vector.y
    let sqz: Double = q.vector.z*q.vector.z
    
    self.init()
    
    // invs (inverse square length) is only required if quaternion is not already normalised
    let invs: Double = 1 / (sqx + sqy + sqz + sqw)
    self[0,0] = ( sqx - sqy - sqz + sqw) * invs  // since sqw + sqx + sqy + sqz =1/invs*invs
    self[1,1] = (-sqx + sqy - sqz + sqw) * invs
    self[2,2] = (-sqx - sqy + sqz + sqw) * invs
    self[3,3] = 1.0;
    
    var tmp1: Double = q.vector.x*q.vector.y
    var tmp2: Double = q.vector.z*q.vector.w
    self[0,1] = 2.0 * (tmp1 + tmp2)*invs
    self[1,0] = 2.0 * (tmp1 - tmp2)*invs
    self[3,0] = 0.0
    self[0,3] = 0.0
    
    tmp1 = q.vector.x*q.vector.z
    tmp2 = q.vector.y*q.vector.w
    self[0,2] = 2.0 * (tmp1 - tmp2) * invs
    self[2,0] = 2.0 * (tmp1 + tmp2) * invs
    self[3,1] = 0.0
    self[1,3] = 0.0
    
    tmp1 = q.vector.y * q.vector.z
    tmp2 = q.vector.x * q.vector.w
    self[1,2] = 2.0 * (tmp1 + tmp2) * invs
    self[2,1] = 2.0 * (tmp1 - tmp2) * invs
    self[3,2] = 0.0
    self[2,3] = 0.0
    
  }
  
  
  public init(transformation m: double4x4, aroundPoint p: SIMD3<Double>)
  {
    var R: double4x4 = double4x4()
    
    self = m
    
    R[0,0] = 1.0-self[0,0]; R[1,0] =    -self[1,0]; R[2,0] =    -self[2,0];
    R[0,1] =    -self[0,1]; R[1,1] = 1.0-self[1,1]; R[2,1] =    -self[2,1];
    R[0,2] =    -self[0,2]; R[1,2] =    -self[1,2]; R[2,2] = 1.0-self[2,2];
    
    self[3,0] += R[0,0] * p.x + R[1,0] * p.y + R[2,0] * p.z
    self[3,1] += R[0,1] * p.x + R[1,1] * p.y + R[2,1] * p.z
    self[3,2] += R[0,2] * p.x + R[1,2] * p.y + R[2,2] * p.z
  }
  
  public init(transformation m: double4x4, aroundPoint p: SIMD3<Double>, withTranslation t: SIMD3<Double>)
  {
    var R: double4x4 = double4x4()
    
    self = m
    
    R[0,0] = 1.0-self[0,0]; R[1,0] =    -self[1,0]; R[2,0] =    -self[2,0];
    R[0,1] =    -self[0,1]; R[1,1] = 1.0-self[1,1]; R[2,1] =    -self[2,1];
    R[0,2] =    -self[0,2]; R[1,2] =    -self[1,2]; R[2,2] = 1.0-self[2,2];
    
    self[3,0] += R[0,0] * p.x + R[1,0] * p.y + R[2,0] * p.z + t.x;
    self[3,1] += R[0,1] * p.x + R[1,1] * p.y + R[2,1] * p.z + t.y;
    self[3,2] += R[0,2] * p.x + R[1,2] * p.y + R[2,2] * p.z + t.z;
  }
  
  public static func glFrustumfOrthographic(_ left: Double, right: Double, bottom: Double, top: Double, near: Double, far: Double) -> double4x4
  {
    var m: double4x4
    let _1over_rml: Double  = 1.0 / (right - left)
    let _1over_fmn: Double  = 1.0 / (far - near)
    let _1over_tmb : Double = 1.0 / (top - bottom)
    
    m=double4x4([SIMD4<Double>(x:2.0 * _1over_rml, y: 0.0,z: 0.0,w: 0.0),
                 SIMD4<Double>(x:0.0, y: 2.0 * _1over_tmb, z: 0.0, w: 0.0),
                 SIMD4<Double>(x:0.0, y: 0.0, z: -2.0 * _1over_fmn, w: 0.0),
                 SIMD4<Double>(x:-(right + left) * _1over_rml, y: -(top + bottom) * _1over_tmb, z: (-(far + near)) * _1over_fmn, w: 1.0)])
    return m
  }
}


