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
  public var int3x3: int3x3
  public var translation: SIMD3<Int32>
    
  public static let zero: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0)])
  public static let identity: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,1)])
  public static let inversionIdentity: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(0,0,-1)])
  
  // based on the centering, convert conventional cell to primitive using conventionally used transformation matrices
  // Taken from: Table 2.C.1, page 141, Fundamentals of Crystallography, 2nd edition, C. Giacovazzo et al. 2002
  // Tranformation matrices M, conventionally used to generate centered from primitive lattices, and vice versa, accoording to: A' = M A
    
  public static let primitiveToPrimitive: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>( 1, 0, 0), SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>( 0, 0, 1)])           // P -> P
  public static let primitiveToBodyCentered: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0, 1, 1), SIMD3<Int32>(1, 0, 1), SIMD3<Int32>(1, 1, 0)])           // P -> I
  public static let primitiveToFaceCentered: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1, 1, 1), SIMD3<Int32>(1, -1, 1), SIMD3<Int32>(1, 1, -1)])        // P -> F
  public static let primitiveToACentered: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, -1, 1), SIMD3<Int32>(0, 1, 1)])            // P -> A
  public static let primitiveToBCentered: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1, 0, 1), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(1, 0, 1)])            // P -> B
  public static let primitiveToCCentered: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1, 1, 0), SIMD3<Int32>(1, -1, 0), SIMD3<Int32>(0, 0, -1)])            // P -> C
  public static let primitiveToRhombohedral: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>( 1, -1, 0), SIMD3<Int32>( 0, 1,-1), SIMD3<Int32>( 1, 1, 1)])       // P -> R
  public static let primitiveToHexagonal: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>( 1, -1, 0), SIMD3<Int32>( 1, 2, 0), SIMD3<Int32>( 0, 0, 3)])          // P -> H
  public static let rhombohedralObverseHexagonal: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1, 0, 1), SIMD3<Int32>(-1, 1, 1), SIMD3<Int32>(0, -1, 1)])    // Robv -> Rh
  public static let rhombohedralHexagonalToReverse: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1, 1, -2),SIMD3<Int32>(-1, 0, 1),SIMD3<Int32>(1, 1, -1)])   // Rh -> Rrev
  public static let rhombohedralReverseToHexagonal: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1, -1, 1), SIMD3<Int32>(0, 1, 1), SIMD3<Int32>(-1, 0, 1)]) // Rrev -> Rh
  
  public static let monoclinicAtoC = SKTransformationMatrix([SIMD3<Int32>(0,0,1),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(1,0,0)])
  public static let AtoC = SKTransformationMatrix([SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,1),SIMD3<Int32>(1,0,0)])
  public static let monoclinicItoC = SKTransformationMatrix([SIMD3<Int32>(1,0,1),SIMD3<Int32>(0, 1,0),SIMD3<Int32>(-1,0,0)])
  public static let BtoC = SKTransformationMatrix([SIMD3<Int32>(0,0,1),SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0)])
  public static let primitiveRhombohedralToTripleHexagonalCell_R2 = SKTransformationMatrix([SIMD3<Int32>( 0,-1, 1), SIMD3<Int32>( 1, 0,-1), SIMD3<Int32>( 1, 1, 1)])
  public static let primitiveRhombohedralToTripleHexagonalCell_R1_Obverse = SKTransformationMatrix([SIMD3<Int32>( 1,-1, 0), SIMD3<Int32>( 0, 1,-1), SIMD3<Int32>( 1, 1, 1)])
  
  public static let bodyCenteredToPrimitive: double3x3 = double3x3([SIMD3<Double>(-0.5,0.5,0.5), SIMD3<Double>(0.5,-0.5,0.5), SIMD3<Double>(0.5,0.5,-0.5)])  // I -> P
  public static let faceCenteredToPrimitive: double3x3 = double3x3([SIMD3<Double>(0,0.5,0.5), SIMD3<Double>(0.5,0,0.5), SIMD3<Double>(0.5,0.5,0)])   // F -> P
  public static let ACenteredToPrimitive: double3x3 = double3x3([SIMD3<Double>(-1.0,0,0), SIMD3<Double>(0,-0.5,0.5), SIMD3<Double>(0,0.5,0.5)])   // A -> P
  public static let BCenteredToPrimitive: double3x3 = double3x3([SIMD3<Double>(-0.5,0,0.5), SIMD3<Double>(0,-1.0,0), SIMD3<Double>(0.5,0,0.5)])   // B -> P
  public static let CCenteredToPrimitive: double3x3 = double3x3([SIMD3<Double>(0.5,0.5,0), SIMD3<Double>(0.5,-0.5,0), SIMD3<Double>(0,0,-1.0)])   // C -> P
  public static let rhombohedralToPrimitive: double3x3 = double3x3([SIMD3<Double>(2.0/3.0,1.0/3.0,1.0/3.0), SIMD3<Double>(-1.0/3.0, 1.0/3.0, 1.0/3.0), SIMD3<Double>(-1.0/3.0,-2.0/3.0, 1.0/3.0)])  // R -> P
  
  // CHECK
  public static let rhombohedralReverseToPrimitive: double3x3 = double3x3([SIMD3<Double>(1.0/3.0,2.0/3.0,1.0/3.0), SIMD3<Double>(-2.0/3.0, -1.0/3.0, 1.0/3.0), SIMD3<Double>(1.0/3.0,-1.0/3.0, 1.0/3.0)])  // R -> P
  
  public static let hexagonalToPrimitive: double3x3 = double3x3([SIMD3<Double>(2.0/3.0,1.0/3.0, 0), SIMD3<Double>(-1.0/3.0, 1.0/3.0, 0), SIMD3<Double>( 0, 0, 1.0/3.0)])  // H -> P
  public static let rhombohedralHexagonalToObverse: double3x3 = double3x3([SIMD3<Double>(2.0/3.0,-1.0/3.0,-1.0/3.0),SIMD3<Double>(1.0/3.0,1.0/3.0,-2.0/3.0),SIMD3<Double>(1.0/3.0,1.0/3.0,1.0/3.0)])   // Rh -> Robv
    
  
  
  public init()
  {
    self.int3x3 = MathKit.int3x3([SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0)])
    self.translation = SIMD3<Int32>(0,0,0)
  }
  
  public init(_ m: [SIMD3<Int32>], _ translation: SIMD3<Int32> = SIMD3<Int32>(0,0,0))
  {
    self.int3x3 = MathKit.int3x3(m)
    self.translation = translation
  }
  
  public init(_ x: SIMD3<Int32>, _ y: SIMD3<Int32>, _ z: SIMD3<Int32>)
  {
    self.int3x3 = MathKit.int3x3([x,y,z])
    self.translation = SIMD3<Int32>(0,0,0)
  }
  
  init(_ m: SKRotationMatrix, _ translation: SIMD3<Int32> = SIMD3<Int32>(0,0,0))
  {
    self.int3x3 = m.int3x3
    self.translation = translation
  }
  
  init(_ m: int3x3, _ translation: SIMD3<Int32> = SIMD3<Int32>(0,0,0))
  {
    self.int3x3 = MathKit.int3x3([m[0], m[1], m[2]])
    self.translation = translation
  }
  
  public init(_ m: double3x3)
  {
    let c1: SIMD3<Int32> = SIMD3<Int32>(Int32(rint(m[0].x)), Int32(rint(m[0].y)), Int32(rint(m[0].z)))
    let c2: SIMD3<Int32> = SIMD3<Int32>(Int32(rint(m[1].x)), Int32(rint(m[1].y)), Int32(rint(m[1].z)))
    let c3: SIMD3<Int32> = SIMD3<Int32>(Int32(rint(m[2].x)), Int32(rint(m[2].y)), Int32(rint(m[2].z)))
    self.init([c1,c2,c3])
  }
  
  /*
  /// Access to individual elements.
  public subscript(column: Int, row: Int) -> Int32
  {
    get
    {
      return self.int3x3[column][row]
    }
    set(newValue)
    {
      self.int3x3[column][row] = newValue
    }
  }
  
  public subscript(column: Int) -> SIMD3<Int32>
  {
    get
    {
      return self.int3x3[column]
    }
    
    set(newValue)
    {
      self.int3x3[column] = newValue
    }
  }*/
  
  public var determinant: Int32
  {
    let temp1: Int32 = (self.int3x3[1,1] * self.int3x3[2,2] - self.int3x3[1,2] * self.int3x3[2,1])
    let temp2: Int32 = (self.int3x3[1,2] * self.int3x3[2,0] - self.int3x3[1,0] * self.int3x3[2,2])
    let temp3: Int32 = (self.int3x3[1,0] * self.int3x3[2,1] - self.int3x3[1,1] * self.int3x3[2,0])
    return (self.int3x3[0,0] * temp1) + (self.int3x3[0,1] * temp2) + (self.int3x3[0,2] * temp3)
  }
  
  // the adjugate or classical adjoint of a square matrix is the transpose of its cofactor matrix
  public var adjugate: SKTransformationMatrix
  {
    var result: SKTransformationMatrix = SKTransformationMatrix()
    result.int3x3[0,0] = self.int3x3[1,1] * self.int3x3[2,2] - self.int3x3[2,1] * self.int3x3[1,2]
    result.int3x3[0,1] = self.int3x3[0,2] * self.int3x3[2,1] - self.int3x3[0,1] * self.int3x3[2,2]
    result.int3x3[0,2] = self.int3x3[0,1] * self.int3x3[1,2] - self.int3x3[0,2] * self.int3x3[1,1]
    result.int3x3[1,0] = self.int3x3[1,2] * self.int3x3[2,0] - self.int3x3[1,0] * self.int3x3[2,2]
    result.int3x3[1,1] = self.int3x3[0,0] * self.int3x3[2,2] - self.int3x3[0,2] * self.int3x3[2,0]
    result.int3x3[1,2] = self.int3x3[1,0] * self.int3x3[0,2] - self.int3x3[0,0] * self.int3x3[1,2]
    result.int3x3[2,0] = self.int3x3[1,0] * self.int3x3[2,1] - self.int3x3[2,0] * self.int3x3[1,1]
    result.int3x3[2,1] = self.int3x3[2,0] * self.int3x3[0,1] - self.int3x3[0,0] * self.int3x3[2,1]
    result.int3x3[2,2] = self.int3x3[0,0] * self.int3x3[1,1] - self.int3x3[1,0] * self.int3x3[0,1]
    
    return result
  }
  
  public var greatestCommonDivisor: Int32
  {
    return [self.int3x3[0,0],self.int3x3[1,0],self.int3x3[2,0],
            self.int3x3[0,1],self.int3x3[1,1],self.int3x3[2,1],
            self.int3x3[0,2],self.int3x3[1,2],self.int3x3[2,2]].reduce(0){Int32.greatestCommonDivisor(a: $0, b: $1)}
  }

  public var transpose: SKTransformationMatrix
  {
    return SKTransformationMatrix([SIMD3<Int32>(self.int3x3[0,0],self.int3x3[1,0],self.int3x3[2,0]),
                                   SIMD3<Int32>(self.int3x3[0,1],self.int3x3[1,1],self.int3x3[2,1]),
                                   SIMD3<Int32>(self.int3x3[0,2],self.int3x3[1,2],self.int3x3[2,2])])
  }
}

extension SKTransformationMatrix: Hashable
{
  public func hash(into hasher: inout Hasher)
  {
    hasher.combine(self.int3x3[0,0])
    hasher.combine(self.int3x3[0,1])
    hasher.combine(self.int3x3[0,2])
    hasher.combine(self.int3x3[1,0])
    hasher.combine(self.int3x3[1,1])
    hasher.combine(self.int3x3[1,2])
    hasher.combine(self.int3x3[2,0])
    hasher.combine(self.int3x3[2,1])
    hasher.combine(self.int3x3[2,2])
    hasher.combine(self.translation.x % 24)
    hasher.combine(self.translation.y % 24)
    hasher.combine(self.translation.z % 24)
  }
}

extension SKTransformationMatrix
{
  public static func ==(left: SKTransformationMatrix, right: SKTransformationMatrix) -> Bool
  {
    return (left.int3x3[0,0] == right.int3x3[0,0]) && (left.int3x3[0,1] == right.int3x3[0,1]) && (left.int3x3[0,2] == right.int3x3[0,2]) &&
           (left.int3x3[1,0] == right.int3x3[1,0]) && (left.int3x3[1,1] == right.int3x3[1,1]) && (left.int3x3[1,2] == right.int3x3[1,2]) &&
           (left.int3x3[2,0] == right.int3x3[2,0]) && (left.int3x3[2,1] == right.int3x3[2,1]) && (left.int3x3[2,2] == right.int3x3[2,2]) &&
           (left.translation.x % 24 == right.translation.x % 24) &&
           (left.translation.y % 24 == right.translation.y % 24) &&
           (left.translation.z % 24 == right.translation.z % 24)
  }
  
  public static func * (left: SKTransformationMatrix, right: SKTransformationMatrix) -> SKTransformationMatrix
  {
    return SKTransformationMatrix(left.int3x3 * right.int3x3,
                                  left.int3x3 * right.translation + left.translation)
  }
  
  public static func *= (left: inout SKTransformationMatrix, right: SKTransformationMatrix)
  {
    left = left * right
  }

  public static func *(left: double3x3, right: SKTransformationMatrix) -> double3x3
  {
    return left * right.int3x3
  }
  
  public static func / (left: SKTransformationMatrix, right: Int) -> SKTransformationMatrix
  {
    assert(left.int3x3[0,0].isMultiple(of: Int32(right)))
    assert(left.int3x3[0,1].isMultiple(of: Int32(right)))
    assert(left.int3x3[0,2].isMultiple(of: Int32(right)))
    assert(left.int3x3[1,0].isMultiple(of: Int32(right)))
    assert(left.int3x3[1,1].isMultiple(of: Int32(right)))
    assert(left.int3x3[1,2].isMultiple(of: Int32(right)))
    assert(left.int3x3[2,0].isMultiple(of: Int32(right)))
    assert(left.int3x3[2,1].isMultiple(of: Int32(right)))
    assert(left.int3x3[2,2].isMultiple(of: Int32(right)))
    return SKTransformationMatrix([SIMD3<Int32>(left.int3x3[0,0] / Int32(right), left.int3x3[0,1] / Int32(right), left.int3x3[0,2] / Int32(right)),
                                   SIMD3<Int32>(left.int3x3[1,0] / Int32(right), left.int3x3[1,1] / Int32(right), left.int3x3[1,2] / Int32(right)),
                                   SIMD3<Int32>(left.int3x3[2,0] / Int32(right), left.int3x3[2,1] / Int32(right), left.int3x3[2,2] / Int32(right))])
    
  }
}
