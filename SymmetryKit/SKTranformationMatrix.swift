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

import Cocoa
import MathKit
import simd

public struct SKTransformationMatrix
{
  var elements: [SIMD3<Int32>]
  
  // S.R. Hall, "Space-group notation with an explicit origin", Acta. Cryst. A, 37, 517-525, 981
  
  public static let zero: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0)])
  public static let identity: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,1)])
  public static let inversionIdentity: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(0,0,-1)])
  
  public static let primitiveToPrimitive: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>( 1, 0, 0), SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>( 0, 0, 1)])  // P -> P
  public static let primitiveToBodyCentered: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,1,1), SIMD3<Int32>(1,0,1), SIMD3<Int32>(1,1,0)])  // P -> I
  public static let primitiveToFaceCentered: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1,1,1), SIMD3<Int32>(1,-1,1), SIMD3<Int32>(1,1,-1)])  // P -> F
  public static let primitiveToACentered: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1,0,0), SIMD3<Int32>(0,-1,1), SIMD3<Int32>(0,1,1)])  // P -> A
  public static let primitiveToBCentered: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1,0,1), SIMD3<Int32>(0,-1,0), SIMD3<Int32>(1,0,1)])  // P -> B
  public static let primitiveToCCentered: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1, 1,0), SIMD3<Int32>(1,-1,0), SIMD3<Int32>(0,0,-1)])  // P -> C
  public static let primitiveToRhombohedral: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>( 1,-1, 0), SIMD3<Int32>( 0, 1,-1), SIMD3<Int32>( 1, 1, 1)])  // P -> R
  public static let primitiveToHexagonal: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>( 1,-1, 0), SIMD3<Int32>( 1, 2, 0), SIMD3<Int32>( 0, 0, 3)])  // P -> H
  
  public init()
  {
    self.elements = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0)]
  }
  
  init(_ m: [SIMD3<Int32>])
  {
    self.elements = m
  }
  
  init(_ m: SKRotationMatrix)
  {
    self.elements = m.elements
  }
  
  public init(_ m: double3x3)
  {
    let c1: SIMD3<Int32> = SIMD3<Int32>(Int32(rint(m[0].x)),
                        Int32(rint(m[0].y)),
                        Int32(rint(m[0].z)))
    let c2: SIMD3<Int32> = SIMD3<Int32>(Int32(rint(m[1].x)),
                        Int32(rint(m[1].y)),
                        Int32(rint(m[1].z)))
    let c3: SIMD3<Int32> = SIMD3<Int32>(Int32(rint(m[2].x)),
                        Int32(rint(m[2].y)),
                        Int32(rint(m[2].z)))
    self.init([c1,c2,c3])
  }
  
  var int3x3: int3x3
  {
    return MathKit.int3x3.init([self[0],self[1],self[2]])
  }
  
  /// Access to individual elements.
  public subscript(column: Int, row: Int) -> Int32
  {
    get
    {
      return self.elements[column][row]
    }
    set(newValue)
    {
      self.elements[column][row] = newValue
    }
  }
  
  public subscript(column: Int) -> SIMD3<Int32>
  {
    get
    {
      return self.elements[column]
    }
    
    set(newValue)
    {
      self.elements[column] = newValue
    }
  }
  
  public var determinant: Int32
  {
    let temp1: Int32 = (self[1,1] * self[2,2] - self[1,2] * self[2,1])
    let temp2: Int32 = (self[1,2] * self[2,0] - self[1,0] * self[2,2])
    let temp3: Int32 = (self[1,0] * self[2,1] - self[1,1] * self[2,0])
    return (self[0,0] * temp1) + (self[0,1] * temp2) + (self[0,2] * temp3)
  }
  
  // inverse times the determinant
  public var inverse: SKTransformationMatrix
  {
    var result: SKTransformationMatrix = SKTransformationMatrix()
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

}

public extension double3x3
{
  init(rotationMatrix a: SKTransformationMatrix)
  {
    let col1 = a[0]
    let col2 = a[1]
    let col3 = a[2]
    self.init([SIMD3<Double>(x: Double(col1.x), y: Double(col1.y),z: Double(col1.z)),
               SIMD3<Double>(x: Double(col2.x), y: Double(col2.y),z: Double(col2.z)),
               SIMD3<Double>(x: Double(col3.x), y: Double(col3.y),z: Double(col3.z))])
  }
}

extension SKTransformationMatrix: Hashable
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
}

extension SKTransformationMatrix
{
  public static func ==(left: SKTransformationMatrix, right: SKTransformationMatrix) -> Bool
  {
    return (left[0,0] == right[0,0]) && (left[0,1] == right[0,1]) && (left[0,2] == right[0,2]) &&
           (left[1,0] == right[1,0]) && (left[1,1] == right[1,1]) && (left[1,2] == right[1,2]) &&
           (left[2,0] == right[2,0]) && (left[2,1] == right[2,1]) && (left[2,2] == right[2,2])
  }
  
  public static func * (left: SKTransformationMatrix, right: SKTransformationMatrix) -> SKTransformationMatrix
  {
    return SKTransformationMatrix([ SIMD3<Int32>(left[0,0] * right[0,0] + left[1,0] * right[0,1] + left[2,0] * right[0,2],
                        left[0,1] * right[0,0] + left[1,1] * right[0,1] + left[2,1] * right[0,2],
                        left[0,2] * right[0,0] + left[1,2] * right[0,1] + left[2,2] * right[0,2]),
                    SIMD3<Int32>(left[0,0] * right[1,0] + left[1,0] * right[1,1] + left[2,0] * right[1,2],
                        left[0,1] * right[1,0] + left[1,1] * right[1,1] + left[2,1] * right[1,2],
                        left[0,2] * right[1,0] + left[1,2] * right[1,1] + left[2,2] * right[1,2]),
                    SIMD3<Int32>(left[0,0] * right[2,0] + left[1,0] * right[2,1] + left[2,0] * right[2,2],
                        left[0,1] * right[2,0] + left[1,1] * right[2,1] + left[2,1] * right[2,2],
                        left[0,2] * right[2,0] + left[1,2] * right[2,1] + left[2,2] * right[2,2])])
  }
  
  public static func * (left: SKTransformationMatrix, right: SKRotationMatrix) -> SKTransformationMatrix
  {
    return SKTransformationMatrix([ SIMD3<Int32>(left[0,0] * right[0,0] + left[1,0] * right[0,1] + left[2,0] * right[0,2],
                        left[0,1] * right[0,0] + left[1,1] * right[0,1] + left[2,1] * right[0,2],
                        left[0,2] * right[0,0] + left[1,2] * right[0,1] + left[2,2] * right[0,2]),
                    SIMD3<Int32>(left[0,0] * right[1,0] + left[1,0] * right[1,1] + left[2,0] * right[1,2],
                        left[0,1] * right[1,0] + left[1,1] * right[1,1] + left[2,1] * right[1,2],
                        left[0,2] * right[1,0] + left[1,2] * right[1,1] + left[2,2] * right[1,2]),
                    SIMD3<Int32>(left[0,0] * right[2,0] + left[1,0] * right[2,1] + left[2,0] * right[2,2],
                        left[0,1] * right[2,0] + left[1,1] * right[2,1] + left[2,1] * right[2,2],
                        left[0,2] * right[2,0] + left[1,2] * right[2,1] + left[2,2] * right[2,2])])
  }
  
  public static func * (left: SKRotationMatrix, right: SKTransformationMatrix) -> SKTransformationMatrix
  {
    return SKTransformationMatrix([ SIMD3<Int32>(left[0,0] * right[0,0] + left[1,0] * right[0,1] + left[2,0] * right[0,2],
                        left[0,1] * right[0,0] + left[1,1] * right[0,1] + left[2,1] * right[0,2],
                        left[0,2] * right[0,0] + left[1,2] * right[0,1] + left[2,2] * right[0,2]),
                    SIMD3<Int32>(left[0,0] * right[1,0] + left[1,0] * right[1,1] + left[2,0] * right[1,2],
                        left[0,1] * right[1,0] + left[1,1] * right[1,1] + left[2,1] * right[1,2],
                        left[0,2] * right[1,0] + left[1,2] * right[1,1] + left[2,2] * right[1,2]),
                    SIMD3<Int32>(left[0,0] * right[2,0] + left[1,0] * right[2,1] + left[2,0] * right[2,2],
                        left[0,1] * right[2,0] + left[1,1] * right[2,1] + left[2,1] * right[2,2],
                        left[0,2] * right[2,0] + left[1,2] * right[2,1] + left[2,2] * right[2,2])])
  }
  
  public static func *= (left: inout SKTransformationMatrix, right: SKTransformationMatrix)
  {
    left = left * right
  }
  
  public static func * (left: SKTransformationMatrix, right: double3x3) -> double3x3
  {
    let temp1: SIMD3<Double> = SIMD3<Double>(Double(left[0,0]) * right[0,0] + Double(left[1,0]) * right[0,1] + Double(left[2,0]) * right[0,2],
                                 Double(left[0,1]) * right[0,0] + Double(left[1,1]) * right[0,1] + Double(left[2,1]) * right[0,2],
                                 Double(left[0,2]) * right[0,0] + Double(left[1,2]) * right[0,1] + Double(left[2,2]) * right[0,2])
    let temp2: SIMD3<Double> = SIMD3<Double>(Double(left[0,0]) * right[1,0] + Double(left[1,0]) * right[1,1] + Double(left[2,0]) * right[1,2],
                                 Double(left[0,1]) * right[1,0] + Double(left[1,1]) * right[1,1] + Double(left[2,1]) * right[1,2],
                                 Double(left[0,2]) * right[1,0] + Double(left[1,2]) * right[1,1] + Double(left[2,2]) * right[1,2])
    let temp3: SIMD3<Double> = SIMD3<Double>(Double(left[0,0]) * right[2,0] + Double(left[1,0]) * right[2,1] + Double(left[2,0]) * right[2,2],
                                 Double(left[0,1]) * right[2,0] + Double(left[1,1]) * right[2,1] + Double(left[2,1]) * right[2,2],
                                 Double(left[0,2]) * right[2,0] + Double(left[1,2]) * right[2,1] + Double(left[2,2]) * right[2,2])
    return double3x3([temp1, temp2, temp3])
  }
  
  public static func *(left: double3x3, right: SKTransformationMatrix) -> double3x3
  {
    let term1: SIMD3<Double> = SIMD3<Double>(left[0,0] * Double(right[0,0]) + left[1,0] * Double(right[0,1]) + left[2,0] * Double(right[0,2]),
                                 left[0,1] * Double(right[0,0]) + left[1,1] * Double(right[0,1]) + left[2,1] * Double(right[0,2]),
                                 left[0,2] * Double(right[0,0]) + left[1,2] * Double(right[0,1]) + left[2,2] * Double(right[0,2]))
    let term2: SIMD3<Double> = SIMD3<Double>(left[0,0] * Double(right[1,0]) + left[1,0] * Double(right[1,1]) + left[2,0] * Double(right[1,2]),
                                 left[0,1] * Double(right[1,0]) + left[1,1] * Double(right[1,1]) + left[2,1] * Double(right[1,2]),
                                 left[0,2] * Double(right[1,0]) + left[1,2] * Double(right[1,1]) + left[2,2] * Double(right[1,2]))
    let term3: SIMD3<Double> = SIMD3<Double>(left[0,0] * Double(right[2,0]) + left[1,0] * Double(right[2,1]) + left[2,0] * Double(right[2,2]),
                                 left[0,1] * Double(right[2,0]) + left[1,1] * Double(right[2,1]) + left[2,1] * Double(right[2,2]),
                                 left[0,2] * Double(right[2,0]) + left[1,2] * Double(right[2,1]) + left[2,2] * Double(right[2,2]))
    return double3x3([term1, term2, term3])
  }
  
  public static func * (left: SKTransformationMatrix, right: SIMD3<Int32>) -> SIMD3<Int32>
  {
    return SIMD3<Int32>(x: left[0,0] * right.x + left[1,0] * right.y + left[2,0] * right.z,
                y: left[0,1] * right.x + left[1,1] * right.y + left[2,1] * right.z,
                z: left[0,2] * right.x + left[1,2] * right.y + left[2,2] * right.z)
  }
  

  public static func * (left: SKTransformationMatrix, right: SIMD3<Double>) -> SIMD3<Double>
  {
    return SIMD3<Double>(x: Double(left[0,0]) * right.x + Double(left[1,0]) * right.y + Double(left[2,0]) * right.z,
                         y: Double(left[0,1]) * right.x + Double(left[1,1]) * right.y + Double(left[2,1]) * right.z,
                         z: Double(left[0,2]) * right.x + Double(left[1,2]) * right.y + Double(left[2,2]) * right.z)
  }  
  
  static public func + (left: SKTransformationMatrix, right: SKTransformationMatrix) -> SKTransformationMatrix
  {
    return SKTransformationMatrix([SIMD3<Int32>(x: left[0,0] + right[0,0], y: left[0,1] + right[0,1], z: left[0,2] + right[0,2]),
                   SIMD3<Int32>(x: left[1,0] + right[1,0], y: left[1,1] + right[1,1], z: left[1,2] + right[1,2]),
                   SIMD3<Int32>(x: left[2,0] + right[2,0], y: left[2,1] + right[2,1], z: left[2,2] + right[2,2])])
  }
  
  static public func - (left: SKTransformationMatrix, right: SKTransformationMatrix) -> SKTransformationMatrix
  {
    return SKTransformationMatrix([SIMD3<Int32>(x: left[0,0] - right[0,0], y: left[0,1] - right[0,1], z: left[0,2] - right[0,2]),
                   SIMD3<Int32>(x: left[1,0] - right[1,0], y: left[1,1] - right[1,1], z: left[1,2] - right[1,2]),
                   SIMD3<Int32>(x: left[2,0] - right[2,0], y: left[2,1] - right[2,1], z: left[2,2] - right[2,2])])
  }
  
  public static prefix func - (left: SKTransformationMatrix) -> SKTransformationMatrix
  {
    return SKTransformationMatrix([SIMD3<Int32>(-left[0,0], -left[0,1], -left[0,2]),
                                   SIMD3<Int32>(-left[1,0], -left[1,1], -left[1,2]),
                                   SIMD3<Int32>(-left[2,0], -left[2,1], -left[2,2])])
    
  }
  
  public static func / (left: SKTransformationMatrix, right: Int) -> SKTransformationMatrix
  {
    assert(left[0,0].isMultiple(of: Int32(right)))
    assert(left[0,1].isMultiple(of: Int32(right)))
    assert(left[0,2].isMultiple(of: Int32(right)))
    assert(left[1,0].isMultiple(of: Int32(right)))
    assert(left[1,1].isMultiple(of: Int32(right)))
    assert(left[1,2].isMultiple(of: Int32(right)))
    assert(left[2,0].isMultiple(of: Int32(right)))
    assert(left[2,1].isMultiple(of: Int32(right)))
    assert(left[2,2].isMultiple(of: Int32(right)))
    return SKTransformationMatrix([SIMD3<Int32>(left[0,0] / Int32(right), left[0,1] / Int32(right), left[0,2] / Int32(right)),
                   SIMD3<Int32>(left[1,0] / Int32(right), left[1,1] / Int32(right), left[1,2] / Int32(right)),
                   SIMD3<Int32>(left[2,0] / Int32(right), left[2,1] / Int32(right), left[2,2] / Int32(right))])
    
  }
}
