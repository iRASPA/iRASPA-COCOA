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
  private var changeOfBasis : SKRotationMatrix
  private var inverseChangeOfBasis : SKRotationMatrix
  
  public init(rotation: SKRotationMatrix)
  {
    self.changeOfBasis = rotation
    self.inverseChangeOfBasis = self.changeOfBasis.inverse
  }
  
  public init(changeOfBasis: SKRotationMatrix, inverseChangeOfBasis: SKRotationMatrix)
  {
    self.changeOfBasis = changeOfBasis
    self.inverseChangeOfBasis = inverseChangeOfBasis
  }
  
  var inverse: SKRotationalChangeOfBasis
  {
    return SKRotationalChangeOfBasis(changeOfBasis: inverseChangeOfBasis, inverseChangeOfBasis: changeOfBasis)
  }
  
  public static func * (left: SKRotationalChangeOfBasis, right: SKSeitzIntegerMatrix) -> SKSeitzIntegerMatrix
  {
    let rotation: SKRotationMatrix = left.inverseChangeOfBasis * right.rotation * left.changeOfBasis
    let translation: SIMD3<Int32> = left.inverseChangeOfBasis * right.translation
    return SKSeitzIntegerMatrix(rotation: rotation, translation: translation)
  }
  
  public static func * (left: SKRotationalChangeOfBasis, right: SIMD3<Double>) -> SIMD3<Double>
  {
    return left.inverseChangeOfBasis * right
  }
  
  public static func * (left: double3x3, right: SKRotationalChangeOfBasis) -> double3x3
  {
    return left * right.inverseChangeOfBasis
  }
  
  public static func * (left: SKRotationalChangeOfBasis, right: SIMD3<Int32>) -> SIMD3<Int32>
  {
    return left.inverseChangeOfBasis * right
  }
}

