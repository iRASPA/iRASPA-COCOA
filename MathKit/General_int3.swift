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

struct MKint3: Equatable
{
  var numerator: SIMD3<Int32>
  var denominator: Int = 1
  
  init(numerator: SIMD3<Int32>, denominator: Int = 1)
  {
    let gcd: Int = Int.greatestCommonDivisor(a: numerator.greatestCommonDivisor, b: denominator)
    self.numerator = SIMD3<Int32>(numerator.x / Int32(gcd), numerator.y / Int32(gcd), numerator.z / Int32(gcd))
    self.denominator = denominator / gcd
  }
  
  public var x: Fraction
  {
    return Fraction(numerator: Int(numerator.x), denominator: denominator)
  }
  
  public var y: Fraction
  {
    return Fraction(numerator: Int(numerator.y), denominator: denominator)
  }
  
  public var z: Fraction
  {
    return Fraction(numerator: Int(numerator.z), denominator: denominator)
  }
  
  public var isZero: Bool
  {
    return (self.numerator == SIMD3<Int32>(0,0,0))
  }
  
  /*
  public var hashValue: Int
  {
    var hashCode: Int = self.x.hashValue
    hashCode = (hashCode * 397) ^ self.y.hashValue
    hashCode = (hashCode * 397) ^ self.z.hashValue
    
    return hashCode
  }
  
  public var squaredNorm: Int
  {
    return Int(self.x*self.x + self.y*self.y + self.z*self.z)
  }
  
  public func modulo(_ b: Int) -> MKint3
  {
    return MKint3(Int32.modulo(a: self.x, b: Int32(b)), Int32.modulo(a: self.y, b: Int32(b)), Int32.modulo(a: self.z, b: Int32(b)))
  }
  
  
  
  
  
  // modulus on int32 defined as always positive
  public static func %(left: MKint3, m: Int32) -> MKint3
  {
    return int3((((left.x % m)+m) % m),(((left.y % m)+m) % m),(((left.z % m)+m) % m))
  }
  
  public static func -(left: MKint3, right: int3) -> MKint3
  {
    return int3(left.x - right.x, left.y - right.y, left.z - right.z)
  }
  
  public static func /(left: MKint3, m: Int32) -> MKint3
  {
    assert(left.x % m == 0)
    assert(left.y % m == 0)
    assert(left.z % m == 0)
    return int3(left.x / m, left.y / m, left.z / m)
  }
  
  public static func *(m: Int32, right: MKint3) -> MKint3
  {
    return int3(m * right.x, m * right.y, m * right.z)
  }
  

  */
  
  public static func *(left: MKint3, right: MKint3) -> MKint3
  {
    let denominator: Int = left.denominator * right.denominator
    let numerator: SIMD3<Int32> = SIMD3<Int32>(left.numerator.x * Int32(right.denominator) * right.numerator.x * Int32(left.denominator),
                               left.numerator.y * Int32(right.denominator) * right.numerator.y * Int32(left.denominator),
                               left.numerator.z * Int32(right.denominator) * right.numerator.z * Int32(left.denominator))
    return MKint3(numerator: numerator, denominator: denominator)
  }
  
  public static func +(left: MKint3, right: MKint3) -> MKint3
  {
    let denominator: Int = left.denominator * right.denominator
    let numerator: SIMD3<Int32> = SIMD3<Int32>(left.numerator.x * Int32(right.denominator) + right.numerator.x * Int32(left.denominator),
                               left.numerator.y * Int32(right.denominator) + right.numerator.y * Int32(left.denominator),
                               left.numerator.z * Int32(right.denominator) + right.numerator.z * Int32(left.denominator))
    return MKint3(numerator: numerator, denominator: denominator)
  }
  
  public static func -(left: MKint3, right: MKint3) -> MKint3
  {
    let denominator: Int = left.denominator * right.denominator
    let numerator: SIMD3<Int32> = SIMD3<Int32>(left.numerator.x * Int32(right.denominator) - right.numerator.x * Int32(left.denominator),
                               left.numerator.y * Int32(right.denominator) - right.numerator.y * Int32(left.denominator),
                               left.numerator.z * Int32(right.denominator) - right.numerator.z * Int32(left.denominator))
    return MKint3(numerator: numerator, denominator: denominator)
  }
  
  public static func ==(left: MKint3, right: MKint3) -> Bool
  {
    return (left.x == right.x) && (left.y == right.y) && (left.z == right.z)
  }
  
}
