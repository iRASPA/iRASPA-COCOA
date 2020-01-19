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


extension SIMD3 where Scalar==Int32
{
  public var squaredNorm: Int
  {
    return Int(self.x*self.x + self.y*self.y + self.z*self.z)
  }
  
  public func modulo(_ b: Int) -> SIMD3<Int32>
  {
    return SIMD3<Int32>(Int32.modulo(a: self.x, b: Int32(b)), Int32.modulo(a: self.y, b: Int32(b)), Int32.modulo(a: self.z, b: Int32(b)))
  }
  
  public var greatestCommonDivisor: Int
  {
    return [Int(self.x), Int(self.y), Int(self.z)].reduce(Int(self.x)){Int.greatestCommonDivisor(a: $0, b: $1)}
  }
  
  public var isZero: Bool
  {
    return (self == SIMD3<Int32>(0,0,0))
  }
  
  public static func +(left: SIMD3<Int32>, right: SIMD3<Int32>) -> SIMD3<Int32>
  {
    return SIMD3<Int32>(left.x + right.x, left.y + right.y, left.z + right.z)
  }
  
  // modulus on int32 defined as always positive
  public static func %(left: SIMD3<Int32>, m: Int32) -> SIMD3<Int32>
  {
    return SIMD3<Int32>((((left.x % m)+m) % m),(((left.y % m)+m) % m),(((left.z % m)+m) % m))
  }
  
  public static func -(left: SIMD3<Int32>, right: SIMD3<Int32>) -> SIMD3<Int32>
  {
    return SIMD3<Int32>(left.x - right.x, left.y - right.y, left.z - right.z)
  }
  
  /*
  public static func /(left: int3, m: Int32) -> int3
  {
    assert(m != 0)
    assert(m != 0)
    assert(m != 0)
    return int3(left.x / m, left.y / m, left.z / m)
  }*/
  
  public static func *(left: SIMD3<Int32>, m: Int32) -> SIMD3<Int32>
  {
    return SIMD3<Int32>(left.x * m, left.y * m, left.z * m)
  }
  
  public static func *(m: Int32, right: SIMD3<Int32>) -> SIMD3<Int32>
  {
    return SIMD3<Int32>(m * right.x, m * right.y, m * right.z)
  }
  
  /*
  public static func ==(left: int3, right: int3) -> Bool
  {
    return (left.x == right.x) && (left.y == right.y) && (left.z == right.z)
  }*/
  
  
}



public func length_squared(_ v: SIMD3<Int32>) -> Int
{
  return Int(v.x*v.x + v.y*v.y + v.z*v.z)
}

public func dot(_ v1: SIMD3<Int32>, _ v2: SIMD3<Int32>) -> Int
{
  return Int(v1.x*v2.x + v1.y*v2.y + v1.z*v2.z)
}



