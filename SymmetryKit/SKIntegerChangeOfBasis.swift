//
//  SKIntegerChangeOfBasis.swift
//  SymmetryKit
//
//  Created by David Dubbeldam on 29/06/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import Foundation
import MathKit
import simd

// Let C_old be the change-of-basis matrix that transforms atomic coordinates in the first input setting to coordinates in the reference setting,
// and C_new the matrix that trans- forms coordinates in the second input setting to coordinates in the reference setting.
// The change-of-basis matrix C_{old->new} that trans-forms coordinates in the first setting to coordinates in the second settings is then obtained as the product:
//         C_{old->new} = C_new^{-1}.C_old
//         C_{new->old} = (C_new^{-1}.C_old)^(-1) = C_old^(-1).C_new

public struct SKIntegerChangeOfBasis
{
  private var changeOfBasis : SKTransformationMatrix
  private var inverseChangeOfBasis : SKTransformationMatrix
  private var changeOfBasisDeterminant: Int32 = 1
  private var inverseChangeOfBasisDeterminant: Int32 = 1
  
  public init(inversionTransformation: SKTransformationMatrix)
  {
    self.inverseChangeOfBasis = inversionTransformation
    self.changeOfBasis = inversionTransformation.inverse
    self.changeOfBasisDeterminant = inversionTransformation.determinant
    self.inverseChangeOfBasisDeterminant = 1
  }
  
  init(inverse: SKIntegerChangeOfBasis)
  {
    self.changeOfBasis = inverse.inverseChangeOfBasis
    self.changeOfBasisDeterminant = inverse.inverseChangeOfBasisDeterminant
    self.inverseChangeOfBasis = inverse.changeOfBasis
    self.inverseChangeOfBasisDeterminant = inverse.changeOfBasisDeterminant
  }
  
  public static func * (left: SKIntegerChangeOfBasis, right: SKTransformationMatrix) -> SKTransformationMatrix
  {
    return left.inverseChangeOfBasis * right * left.changeOfBasis / Int(left.inverseChangeOfBasisDeterminant * left.changeOfBasisDeterminant)
  }
  
  public static func * (left: SKIntegerChangeOfBasis, right: SIMD3<Int32>) -> SIMD3<Int32>
  {
    return left.inverseChangeOfBasis * right / Int32(left.inverseChangeOfBasisDeterminant)
  }
  
  public static func * (left: SKIntegerChangeOfBasis, right: SIMD3<Double>) -> SIMD3<Double>
  {
    return (left.inverseChangeOfBasis * right) / Double(left.inverseChangeOfBasisDeterminant)
  }
  
  public static func ==(left: SKIntegerChangeOfBasis, right: SKChangeOfBasis) -> Bool
  {
    return left.changeOfBasis.int3x3 == right.changeOfBasis.Int3x3b &&
      left.inverseChangeOfBasis.int3x3 == right.inverseChangeOfBasis.Int3x3b &&
      left.changeOfBasisDeterminant == right.inverseChangeOfBasis.denominator * right.changeOfBasis.denominator
  }
  
 
  
}
