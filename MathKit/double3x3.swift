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

extension double3x3
{
  public init(Double4x4: double4x4)
  {
    self.init([double3(x: Double4x4[0][0], y: Double4x4[0][1], z: Double4x4[0][2]),
               double3(x: Double4x4[1][0], y: Double4x4[1][1], z: Double4x4[1][2]),
               double3(x: Double4x4[2][0], y: Double4x4[2][1], z: Double4x4[2][2])])
  }
}

extension double3x3: Decodable
{
  // MARK: -
  // MARK: Decodable support
  
  public init(from decoder: Decoder) throws
  {
    var container = try decoder.unkeyedContainer()
    self.init()
    self[0][0] = try container.decode(Double.self)
    self[0][1] = try container.decode(Double.self)
    self[0][2] = try container.decode(Double.self)
    self[1][0] = try container.decode(Double.self)
    self[1][1] = try container.decode(Double.self)
    self[1][2] = try container.decode(Double.self)
    self[2][0] = try container.decode(Double.self)
    self[2][1] = try container.decode(Double.self)
    self[2][2] = try container.decode(Double.self)
  }
}

public extension double3x3
{
  public init(int3x3 a:  int3x3)
  {
    let col1 = a[0]
    let col2 = a[1]
    let col3 = a[2]
    self.init([double3(x: Double(col1.x), y: Double(col1.y),z: Double(col1.z)),
               double3(x: Double(col2.x), y: Double(col2.y),z: Double(col2.z)),
               double3(x: Double(col3.x), y: Double(col3.y),z: Double(col3.z))])
  }
  /*
  public var determinant: Double
  {
    get
    {
      let temp1: Double = (self[1,1] * self[2,2]) - (self[1,2] * self[2,1])
      let temp2: Double = (self[1][2] * self[2][0]) - (self[1][0] * self[2][2])
      let temp3: Double = (self[1][0] * self[2][1]) - (self[1][1] * self[2][0])
      return (self[0][0] * temp1) + (self[0][1] * temp2) + (self[0][2] * temp3)
    }
  }*/
  
  public static func * (left: double3x3, right: int3) -> double3
  {
    return double3(x: left[0][0] * Double(right.x) + left[1][0] * Double(right.y) + left[2][0] * Double(right.z),
                   y: left[0][1] * Double(right.x) + left[1][1] * Double(right.y) + left[2][1] * Double(right.z),
                   z: left[0][2] * Double(right.x) + left[1][2] * Double(right.y) + left[2][2] * Double(right.z))
  }
  
  
  
  public static func * (left: int3, right: double3x3) -> double3
  {
    return double3(x: Double(left.x) * right[0][0] + Double(left.y) * right[0][1] + Double(left.z) * right[0][2],
                   y: Double(left.x) * right[1][0] + Double(left.y) * right[1][1] + Double(left.z) * right[1][2],
                   z: Double(left.x) * right[2][0] + Double(left.y) * right[2][1] + Double(left.z) * right[2][2])
  }
}




extension double3x3: Hashable
{
  public func hash(into hasher: inout Hasher)
  {
    hasher.combine(self[0,0])
    hasher.combine(self[0,1])
    hasher.combine(self[0,2])
    hasher.combine(self[1,0])
    hasher.combine(self[1,1])
    hasher.combine(self[1,2])
    hasher.combine(self[2,0])
    hasher.combine(self[2,1])
    hasher.combine(self[2,2])
  }
  
  public init(_ m: int3x3)
  {
    self.init([double3(Double(m[0][0])/Double(m.denominator),Double(m[0][1])/Double(m.denominator),Double(m[0][2])/Double(m.denominator)),
               double3(Double(m[1][0])/Double(m.denominator),Double(m[1][1])/Double(m.denominator),Double(m[1][2])/Double(m.denominator)),
               double3(Double(m[2][0])/Double(m.denominator),Double(m[2][1])/Double(m.denominator),Double(m[2][2])/Double(m.denominator))])
  }
  
  public func isInteger(precision: Double) -> Bool
  {
    for i in 0..<3
    {
      for j in 0..<3
      {
        if (fabs(rint(self[i][j]) - self[i][j]) > precision)
        {
          return false
        }
      }
    }
    return true
  }
  
  
  public static func *(left: double3x3, right: int3x3) -> double3x3
  {
    let term1: double3 = double3(left[0,0] * Double(right[0,0]) + left[1,0] * Double(right[0,1]) + left[2,0] * Double(right[0,2]),
                                 left[0,1] * Double(right[0,0]) + left[1,1] * Double(right[0,1]) + left[2,1] * Double(right[0,2]),
                                 left[0,2] * Double(right[0,0]) + left[1,2] * Double(right[0,1]) + left[2,2] * Double(right[0,2]))
    let term2: double3 = double3(left[0,0] * Double(right[1,0]) + left[1,0] * Double(right[1,1]) + left[2,0] * Double(right[1,2]),
                                 left[0,1] * Double(right[1,0]) + left[1,1] * Double(right[1,1]) + left[2,1] * Double(right[1,2]),
                                 left[0,2] * Double(right[1,0]) + left[1,2] * Double(right[1,1]) + left[2,2] * Double(right[1,2]))
    let term3: double3 = double3(left[0,0] * Double(right[2,0]) + left[1,0] * Double(right[2,1]) + left[2,0] * Double(right[2,2]),
                                 left[0,1] * Double(right[2,0]) + left[1,1] * Double(right[2,1]) + left[2,1] * Double(right[2,2]),
                                 left[0,2] * Double(right[2,0]) + left[1,2] * Double(right[2,1]) + left[2,2] * Double(right[2,2]))
    return double3x3([term1, term2, term3])
    
    
  }
  
  public static func / (left: double3x3, right: Double) -> double3x3
  {
    return double3x3([double3(left[0,0] / right, left[0,1] / right, left[0,2] / right),
                      double3(left[1,0] / right, left[1,1] / right, left[1,2] / right),
                      double3(left[2,0] / right, left[2,1] / right, left[2,2] / right)])
  }
  
  public static func ==(left: double3x3, right: double3x3) -> Bool
  {
    return (left[0][0] == right[0][0]) && (left[0][1] == right[0][1]) && (left[0][2] == right[0][2]) &&
      (left[1][0] == right[1][0]) && (left[1][1] == right[1][1]) && (left[1][2] == right[1][2]) &&
      (left[2][0] == right[2][0]) && (left[2][1] == right[2][1]) && (left[2][2] == right[2][2])
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
   
    
    var tmp1: Double = q.vector.x*q.vector.y
    var tmp2: Double = q.vector.z*q.vector.w
    self[0,1] = 2.0 * (tmp1 + tmp2)*invs
    self[1,0] = 2.0 * (tmp1 - tmp2)*invs
    
    tmp1 = q.vector.x*q.vector.z
    tmp2 = q.vector.y*q.vector.w
    self[0,2] = 2.0 * (tmp1 - tmp2) * invs
    self[2,0] = 2.0 * (tmp1 + tmp2) * invs
    
    tmp1 = q.vector.y * q.vector.z
    tmp2 = q.vector.x * q.vector.w
    self[1,2] = 2.0 * (tmp1 + tmp2) * invs
    self[2,1] = 2.0 * (tmp1 - tmp2) * invs
  }
}

