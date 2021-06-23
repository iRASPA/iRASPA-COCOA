/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2021 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

extension double3x3
{
  
  public init(_ m: MKint3x3)
  {
    self.init([SIMD3<Double>(Double(m[0][0])/Double(m.denominator),Double(m[0][1])/Double(m.denominator),Double(m[0][2])/Double(m.denominator)),
               SIMD3<Double>(Double(m[1][0])/Double(m.denominator),Double(m[1][1])/Double(m.denominator),Double(m[1][2])/Double(m.denominator)),
               SIMD3<Double>(Double(m[2][0])/Double(m.denominator),Double(m[2][1])/Double(m.denominator),Double(m[2][2])/Double(m.denominator))])
  }
}

public struct MKint3x3: Equatable
{
  var numerator: [SIMD3<Int32>]
  public var denominator: Int = 1
  
  public init()
  {
    self.numerator = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0)]
    self.denominator = 1
  }
  
  
  
  public init(_ m: int3x3, denominator: Int = 1)
  {
    self.numerator = [m[0], m[1], m[2]]
    self.denominator = denominator
  }
  
  
  public static var identity: MKint3x3
  {
    return MKint3x3([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,1)])
  }
  
  /*
  /// Get the matrix as the corresponding C matrix type.
  public var cmatrix: matrix_int3x3
  {
    get
    {
      return matrix_int3x3()
    }
  }*/
  
  public var description : String
  {
    return "[\(numerator[0]), \(numerator[1]), \(numerator[2])]"
  }
  
  public init(scalar: Int32, denominator: Int = 1)
  {
    self.numerator = [SIMD3<Int32>(scalar,0,0),SIMD3<Int32>(0,scalar,0),SIMD3<Int32>(0,0,scalar)]
    self.denominator = denominator
  }
  
  public init(_ columns: [SIMD3<Int32>], denominator: Int = 1)
  {
    self.numerator = columns
    self.denominator = denominator
  }
  
  public init(_ scalar: Int32, denominator: Int = 1)
  {
    self.init([SIMD3<Int32>(scalar,0,0),SIMD3<Int32>(0,scalar,0),SIMD3<Int32>(0,0,scalar)])
    self.denominator = denominator
  }
  
  public init(rows: [SIMD3<Int32>], denominator: Int = 1)
  {
    self.numerator = [SIMD3<Int32>(rows[0].x,rows[1].x,rows[2].x), SIMD3<Int32>(rows[0].y,rows[1].y,rows[2].y), SIMD3<Int32>(rows[0].z,rows[1].z,rows[2].z)]
    self.denominator = denominator
  }
  
  public var Int3x3: int3x3
  {
    let normalize: Int = self.denominator
    return int3x3([SIMD3<Int32>(self[0][0] / Int32(normalize), self[0][1] / Int32(normalize), self[0][2] / Int32(normalize)),
                   SIMD3<Int32>(self[1][0] / Int32(normalize), self[1][1] / Int32(normalize), self[1][2] / Int32(normalize)),
                   SIMD3<Int32>(self[2][0] / Int32(normalize), self[2][1] / Int32(normalize), self[2][2] / Int32(normalize))])
  }
  
  public var elements: [Int]
  {
    return [Int(numerator[0].x), Int(numerator[0].y), Int(numerator[0].z),
            Int(numerator[1].x), Int(numerator[1].y), Int(numerator[1].z),
            Int(numerator[2].x), Int(numerator[2].y), Int(numerator[2].z)]
  }
  
  public var greatestCommonDivisor: Int
  {
    return elements.reduce(Int(self[0,0])){(try? Int.greatestCommonDivisor(a: $0, b: $1)) ?? 1}
  }
  
  public var determinant: Int
  {
    let temp1: Int32 = (self[1,1] * self[2,2] - self[1,2] * self[2,1])
    let temp2: Int32 = (self[1,2] * self[2,0] - self[1,0] * self[2,2])
    let temp3: Int32 = (self[1,0] * self[2,1] - self[1,1] * self[2,0])
    return Int((self[0,0] * temp1) + (self[0,1] * temp2) + (self[0,2] * temp3)) 
  }
  
  /// Access to individual elements.
  public subscript(column: Int, row: Int) -> Int32
    {
    get
    {
      return self.numerator[column][row]
    }
    set(newValue)
    {
      self.numerator[column][row] = newValue
    }
  }
  
  public subscript(column: Int) -> SIMD3<Int32>
    {
    get
    {
      return self.numerator[column]
    }
    
    set(newValue)
    {
      self.numerator[column] = newValue
    }
  }
  
  public mutating func cleaunUp()
  {
    let gcd: Int32 = [self[0,0],self[1,0],self[2,0],
                      self[0,1],self[1,1],self[2,1],
                      self[0,2],self[1,2],self[2,2]].reduce(self[0,0]){Int32.greatestCommonDivisor(a: $0, b: $1)}
    self.denominator = self.denominator / Int(gcd)
    self[0,0] /= gcd
    self[1,0] /= gcd
    self[2,0] /= gcd
    self[0,1] /= gcd
    self[1,1] /= gcd
    self[2,1] /= gcd
    self[0,2] /= gcd
    self[1,2] /= gcd
    self[2,2] /= gcd
  }
  
  
  public var isOrthogonal: Bool
  {
    return (dot(numerator[0],numerator[1])==0) && (dot(numerator[0],numerator[2])==0) && (dot(numerator[1],numerator[2])==0)
  }
  
  public var transpose: int3x3
    {
    get
    {
      return int3x3([SIMD3<Int32>(self[0][0],self[1][0],self[2][0]),
                     SIMD3<Int32>(self[0][1],self[1][1],self[2][1]),
                     SIMD3<Int32>(self[0][2],self[1][2],self[2][2])], denominator: self.denominator)
    }
  }
  
  public var isZero: Bool
  {
    return (self[0] == SIMD3<Int32>(0,0,0) &&  self[1] == SIMD3<Int32>(0,0,0) && self[2] == SIMD3<Int32>(0,0,0))
  }
  
  public var trace: Int
  {
    return Int(self[0][0] + self[1][1] + self[2][2])
  }
  
  
  
  public mutating func swapRows(i: Int, j: Int)
  {
    for k in 0..<3
    {
      let temp: Int32 = self.numerator[k][i]
      self.numerator[k][i] = self.numerator[k][j]
      self.numerator[k][j] = temp
    }
  }
  
  public mutating func subtract(row: Int, mutlipliedBy multiplier: Int32, fromRow: Int)
  {
    for k in 0..<3
    {
      self.numerator[k][fromRow] -= multiplier * self.numerator[k][row]
    }
  }
  
  public mutating func divideRow(i: Int, by divisor: Int32)
  {
    for k in 0..<3
    {
      self.numerator[k][i] /= divisor
    }
  }
  
  
  
  public var inverse: MKint3x3
  {
    var result: MKint3x3 = MKint3x3()
    result.denominator = self.determinant / self.denominator
    
    result[0,0] = self[1,1] * self[2,2] - self[2,1] * self[1,2]
    result[0,1] = self[0,2] * self[2,1] - self[0,1] * self[2,2]
    result[0,2] = self[0,1] * self[1,2] - self[0,2] * self[1,1]
    result[1,0] = self[1,2] * self[2,0] - self[1,0] * self[2,2]
    result[1,1] = self[0,0] * self[2,2] - self[0,2] * self[2,0]
    result[1,2] = self[1,0] * self[0,2] - self[0,0] * self[1,2]
    result[2,0] = self[1,0] * self[2,1] - self[2,0] * self[1,1]
    result[2,1] = self[2,0] * self[0,1] - self[0,0] * self[2,1]
    result[2,2] = self[0,0] * self[1,1] - self[1,0] * self[0,1]
    
    return result
  }
  
  
  
  public static func ==(left: MKint3x3, right: MKint3x3) -> Bool
  {
    for i in 0..<3
    {
      for j in 0..<3
      {
        if Fraction(numerator: Int(left[i][j]), denominator: left.denominator) != Fraction(numerator: Int(right[i][j]), denominator: right.denominator)
        {
          return false
        }
      }
    }
    return true
    
    /*
    return (left[0][0] == right[0][0]) && (left[0][1] == right[0][1]) && (left[0][2] == right[0][2]) &&
           (left[1][0] == right[1][0]) && (left[1][1] == right[1][1]) && (left[1][2] == right[1][2]) &&
           (left[2][0] == right[2][0]) && (left[2][1] == right[2][1]) && (left[2][2] == right[2][2])
 */
  }
  
  public static func * (left: MKint3x3, right: MKint3x3) -> MKint3x3
  {
    return MKint3x3([SIMD3<Int32>(left[0,0] * right[0,0] + left[1,0] * right[0,1] + left[2,0] * right[0,2],
                        left[0,1] * right[0,0] + left[1,1] * right[0,1] + left[2,1] * right[0,2],
                        left[0,2] * right[0,0] + left[1,2] * right[0,1] + left[2,2] * right[0,2]),
                   SIMD3<Int32>(left[0,0] * right[1,0] + left[1,0] * right[1,1] + left[2,0] * right[1,2],
                        left[0,1] * right[1,0] + left[1,1] * right[1,1] + left[2,1] * right[1,2],
                        left[0,2] * right[1,0] + left[1,2] * right[1,1] + left[2,2] * right[1,2]),
                   SIMD3<Int32>(left[0,0] * right[2,0] + left[1,0] * right[2,1] + left[2,0] * right[2,2],
                        left[0,1] * right[2,0] + left[1,1] * right[2,1] + left[2,1] * right[2,2],
                        left[0,2] * right[2,0] + left[1,2] * right[2,1] + left[2,2] * right[2,2])], denominator: left.denominator * right.denominator)
  }
  
  public static func *= (left: inout MKint3x3, right: MKint3x3)
  {
    left = left * right
  }
  
  public static func * (left: MKint3x3, right: double3x3) -> double3x3
  {
    let x: SIMD3<Double> = SIMD3<Double>((Double(left[0,0]) * right[0,0] + Double(left[1,0]) * right[0,1] + Double(left[2,0]) * right[0,2])/Double(left.denominator),
                             (Double(left[0,1]) * right[0,0] + Double(left[1,1]) * right[0,1] + Double(left[2,1]) * right[0,2])/Double(left.denominator),
                             (Double(left[0,2]) * right[0,0] + Double(left[1,2]) * right[0,1] + Double(left[2,2]) * right[0,2])/Double(left.denominator))
    let y: SIMD3<Double> = SIMD3<Double>((Double(left[0,0]) * right[1,0] + Double(left[1,0]) * right[1,1] + Double(left[2,0]) * right[1,2])/Double(left.denominator),
                             (Double(left[0,1]) * right[1,0] + Double(left[1,1]) * right[1,1] + Double(left[2,1]) * right[1,2])/Double(left.denominator),
                             (Double(left[0,2]) * right[1,0] + Double(left[1,2]) * right[1,1] + Double(left[2,2]) * right[1,2])/Double(left.denominator))
    let z: SIMD3<Double> = SIMD3<Double>((Double(left[0,0]) * right[2,0] + Double(left[1,0]) * right[2,1] + Double(left[2,0]) * right[2,2])/Double(left.denominator),
                             (Double(left[0,1]) * right[2,0] + Double(left[1,1]) * right[2,1] + Double(left[2,1]) * right[2,2])/Double(left.denominator),
                             (Double(left[0,2]) * right[2,0] + Double(left[1,2]) * right[2,1] + Double(left[2,2]) * right[2,2])/Double(left.denominator))
    return double3x3([x,y,z])
  }
  
  public static func * (left: double3x3, right: MKint3x3) -> double3x3
  {
    let x: SIMD3<Double> = SIMD3<Double>((left[0,0] * Double(right[0,0]) + left[1,0] * Double(right[0,1]) + left[2,0] * Double(right[0,2]))/Double(right.denominator),
                             (left[0,1] * Double(right[0,0]) + left[1,1] * Double(right[0,1]) + left[2,1] * Double(right[0,2]))/Double(right.denominator),
                             (left[0,2] * Double(right[0,0]) + left[1,2] * Double(right[0,1]) + left[2,2] * Double(right[0,2]))/Double(right.denominator))
    let y: SIMD3<Double> = SIMD3<Double>((left[0,0] * Double(right[1,0]) + left[1,0] * Double(right[1,1]) + left[2,0] * Double(right[1,2]))/Double(right.denominator),
                             (left[0,1] * Double(right[1,0]) + left[1,1] * Double(right[1,1]) + left[2,1] * Double(right[1,2]))/Double(right.denominator),
                             (left[0,2] * Double(right[1,0]) + left[1,2] * Double(right[1,1]) + left[2,2] * Double(right[1,2]))/Double(right.denominator))
    let z: SIMD3<Double> = SIMD3<Double>((left[0,0] * Double(right[2,0]) + left[1,0] * Double(right[2,1]) + left[2,0] * Double(right[2,2]))/Double(right.denominator),
                             (left[0,1] * Double(right[2,0]) + left[1,1] * Double(right[2,1]) + left[2,1] * Double(right[2,2]))/Double(right.denominator),
                             (left[0,2] * Double(right[2,0]) + left[1,2] * Double(right[2,1]) + left[2,2] * Double(right[2,2]))/Double(right.denominator))
    return double3x3([x,y,z])

  }
  
  
  public static func * (left: MKint3x3, right: SIMD3<Int32>) -> SIMD3<Int32>
  {
    return SIMD3<Int32>(x: left[0][0] * right.x + left[1][0] * right.y + left[2][0] * right.z,
                y: left[0][1] * right.x + left[1][1] * right.y + left[2][1] * right.z,
                z: left[0][2] * right.x + left[1][2] * right.y + left[2][2] * right.z)
  }
  
  
  
  public static func * (left: MKint3x3, right: SIMD3<Double>) -> SIMD3<Double>
  {
    return SIMD3<Double>(x: (Double(left[0][0]) * right.x + Double(left[1][0]) * right.y + Double(left[2][0]) * right.z)/Double(left.denominator),
                   y: (Double(left[0][1]) * right.x + Double(left[1][1]) * right.y + Double(left[2][1]) * right.z)/Double(left.denominator),
                   z: (Double(left[0][2]) * right.x + Double(left[1][2]) * right.y + Double(left[2][2]) * right.z)/Double(left.denominator))
  }
  
  
  static public func + (left: MKint3x3, right: MKint3x3) -> MKint3x3
  {
    return MKint3x3([SIMD3<Int32>(x: left[0][0] + right[0][0], y: left[0][1] + right[0][1], z: left[0][2] + right[0][2]),
                   SIMD3<Int32>(x: left[1][0] + right[1][0], y: left[1][1] + right[1][1], z: left[1][2] + right[1][2]),
                   SIMD3<Int32>(x: left[2][0] + right[2][0], y: left[2][1] + right[2][1], z: left[2][2] + right[2][2])])
  }
  
  static public func - (left: MKint3x3, right: MKint3x3) -> MKint3x3
  {
    return MKint3x3([SIMD3<Int32>(x: left[0][0] - right[0][0], y: left[0][1] - right[0][1], z: left[0][2] - right[0][2]),
                   SIMD3<Int32>(x: left[1][0] - right[1][0], y: left[1][1] - right[1][1], z: left[1][2] - right[1][2]),
                   SIMD3<Int32>(x: left[2][0] - right[2][0], y: left[2][1] - right[2][1], z: left[2][2] - right[2][2])])
  }
  
  public static prefix func - (left: MKint3x3) -> MKint3x3
  {
    return MKint3x3([SIMD3<Int32>(-left.numerator[0][0], -left.numerator[0][1], -left.numerator[0][2]),
                   SIMD3<Int32>(-left.numerator[1][0], -left.numerator[1][1], -left.numerator[1][2]),
                   SIMD3<Int32>(-left.numerator[2][0], -left.numerator[2][1], -left.numerator[2][2])])
    
  }
}

