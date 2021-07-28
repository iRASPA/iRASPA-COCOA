//
//  SKRotationalChangeOfBasis.swift
//  SymmetryKit
//
//  Created by David Dubbeldam on 28/06/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import Foundation
import MathKit
import simd

public struct SKRotationalChangeOfBasis
{
  public var rotationMatrix : SKRotationMatrix
  public var inverseRotationMatrix : SKRotationMatrix
  
  public static let identity: SKRotationalChangeOfBasis = SKRotationalChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 1, 0, 0), SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>( 0, 0, 1)]))
  
  // Table 2 from R. W. Grosse-Kunstleve, Acta Cryst. (1999). A55, 383-395
  public static let changeOfMonoclinicCentering: [SKRotationalChangeOfBasis] =
  [
    // Note: multiples matches are possible
    SKRotationalChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 1, 0, 0), SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>( 0, 0, 1)])), //  1 : I           a,  b,    c
    SKRotationalChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>(-1, 0,-1), SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>( 1, 0, 0)])), //  2 : R3       -a-c,  b,    a
    SKRotationalChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 0, 0, 1), SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>(-1, 0,-1)])), //  3 : R3.R3       c,  b, -a-c
    SKRotationalChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 0, 0, 1), SIMD3<Int32>( 0,-1, 0), SIMD3<Int32>( 1, 0, 0)])), //  4 : R2          c, -b,    a
    SKRotationalChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 1, 0, 0), SIMD3<Int32>( 0,-1, 0), SIMD3<Int32>(-1, 0,-1)])), //  5 : R2.R3       a, -b, -a-c
    SKRotationalChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>(-1, 0,-1), SIMD3<Int32>( 0,-1, 0), SIMD3<Int32>( 0, 0, 1)])), //  6 : R2.R3.R3 -a-c, -b,    c
  ]
  
 
  // Table 2 from R. W. Grosse-Kunstleve, Acta Cryst. (1999). A55, 383-395
  public static let changeOfOrthorhombicCentering: [SKRotationalChangeOfBasis] =
  [
    // Note: multiples matches are possible
    SKRotationalChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 1, 0, 0), SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>( 0, 0, 1)])), // 1 : I           a,  b,  c
    SKRotationalChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>( 0, 0, 1), SIMD3<Int32>( 1, 0, 0)])), // 2 : R3          b,  c,  a
    SKRotationalChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 0, 0, 1), SIMD3<Int32>( 1, 0, 0), SIMD3<Int32>( 0, 1, 0)])), // 3 : R3.R3       c,  a,  b
    SKRotationalChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>( 1, 0, 0), SIMD3<Int32>( 0, 0,-1)])), // 4 : R2          b,  a, -c
    SKRotationalChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 1, 0, 0), SIMD3<Int32>( 0, 0,-1), SIMD3<Int32>( 0, 1, 0)])), // 5 : R2.R3       a, -c,  b
    SKRotationalChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>( 0, 0,-1), SIMD3<Int32>( 0, 1, 0), SIMD3<Int32>( 1, 0, 0)]))  // 6 : R2.R3.R3   -c,  b,  a
  ]
  
  public init(rotation: SKRotationMatrix)
  {
    self.rotationMatrix = rotation
    self.inverseRotationMatrix = self.rotationMatrix.inverse
  }
  
  public init(changeOfBasis: SKRotationMatrix, inverseChangeOfBasis: SKRotationMatrix)
  {
    self.rotationMatrix = changeOfBasis
    self.inverseRotationMatrix = inverseChangeOfBasis
  }
  
  var inverse: SKRotationalChangeOfBasis
  {
    return SKRotationalChangeOfBasis(changeOfBasis: inverseRotationMatrix, inverseChangeOfBasis: rotationMatrix)
  }
  
  public static func * (left: SKRotationalChangeOfBasis, right: SKSeitzIntegerMatrix) -> SKSeitzIntegerMatrix
  {
    let rotation: SKRotationMatrix = left.inverseRotationMatrix * right.rotation * left.rotationMatrix
    let translation: SIMD3<Int32> = left.inverseRotationMatrix * right.translation
    return SKSeitzIntegerMatrix(rotation: rotation, translation: translation)
  }
  
  public static func * (left: SKRotationalChangeOfBasis, right: SIMD3<Double>) -> SIMD3<Double>
  {
    return left.inverseRotationMatrix * right
  }
  
  public static func * (left: SKRotationalChangeOfBasis, right: SIMD3<Int32>) -> SIMD3<Int32>
  {
    return left.inverseRotationMatrix * right
  }
}

