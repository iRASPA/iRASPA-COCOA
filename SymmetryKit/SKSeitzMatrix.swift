//
//  SKSeitzMatrix.swift
//  SymmetryKit
//
//  Created by David Dubbeldam on 25/06/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import Foundation
import MathKit

public struct SKSeitzMatrix
{
  var rotation: SKRotationMatrix
  var translation: SIMD3<Double>
  
  public init(rotation: SKRotationMatrix, translation: SIMD3<Int32>)
  {
    self.rotation = rotation
    self.translation = SIMD3<Double>(Double(translation.x % 12) / 12.0, Double(translation.y % 12) / 12.0, Double(translation.z % 12) / 12.0)
  }
  
  public init(rotation: SKRotationMatrix, translation: SIMD3<Double>)
  {
    self.rotation = rotation
    //self.rotation.cleaunUp()
    self.translation = translation
  }
  
  public static func * (left: SKSeitzMatrix, right: SIMD3<Double>) -> SIMD3<Double>
  {
    return SIMD3<Double>(x: Double(left.rotation[0][0]) * right.x + Double(left.rotation[1][0]) * right.y + Double(left.rotation[2][0]) * right.z + Double(left.translation.x)/12.0,
                         y: Double(left.rotation[0][1]) * right.x + Double(left.rotation[1][1]) * right.y + Double(left.rotation[2][1]) * right.z + Double(left.translation.y)/12.0,
                         z: Double(left.rotation[0][2]) * right.x + Double(left.rotation[1][2]) * right.y + Double(left.rotation[2][2]) * right.z + Double(left.translation.z)/12.0)
  }
  
  // (A1 | t1)(A2 | t2) = (A1A2 | t1 + A1t2)
  public static func * (left: SKSeitzMatrix, right: SKSeitzMatrix) -> SKSeitzMatrix
  {
    let rotationMatrix: SKRotationMatrix = left.rotation * right.rotation
    let translation: SIMD3<Double> = left.translation + left.rotation * right.translation
    return SKSeitzMatrix(rotation: rotationMatrix, translation: translation)
  }
}
