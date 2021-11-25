//
//  SKSymmetryOperationSet.swift
//  SymmetryKit
//
//  Created by David Dubbeldam on 30/06/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import Foundation
import simd
import MathKit

public struct SKSymmetryOperationSet
{
  public var operations: [SKSeitzMatrix]
  
  public init(operations: [SKSeitzMatrix])
  {
    self.operations = operations
  }
  
  public var rotations: OrderedSet<SKRotationMatrix>
  {
    return OrderedSet(sequence: self.operations.map{$0.rotation})
  }
  
  // the transformationMatrix does not have a translational part
  public func changedBasis(transformationMatrix: SKTransformationMatrix) -> SKSymmetryOperationSet
  {
    var newSet: [SKSeitzMatrix] = []
    
    for seitzMatrix in self.operations
    {
      let inverseTransformation = transformationMatrix.adjugate
      let rotation: int3x3 = inverseTransformation.int3x3 * seitzMatrix.rotation.int3x3 * transformationMatrix.int3x3 / Int(transformationMatrix.determinant)
      let translation: SIMD3<Double> = inverseTransformation.int3x3 * seitzMatrix.translation
      let transformedSeitzMatrix: SKSeitzMatrix = SKSeitzMatrix(rotation: SKRotationMatrix(int3x3: rotation), translation: translation / Double(transformationMatrix.determinant))
      newSet.append(transformedSeitzMatrix)
    }
    return SKSymmetryOperationSet(operations: newSet)
  }
  
  public func addingCenteringOperations(centering: SKSpacegroup.Centring) -> SKSymmetryOperationSet
  {
    let shifts: [SIMD3<Double>]
    
    switch(centering)
    {
    case .none, .primitive:
      shifts = [SIMD3<Double>(0,0,0)]
    case .face:
      shifts = [SIMD3<Double>(0,0,0),SIMD3<Double>(0,0.5,0.5),SIMD3<Double>(0.5,0,0.5),SIMD3<Double>(0.5,0.5,0)]
    case .r:
      shifts = [SIMD3<Double>(0,0,0),SIMD3<Double>(8.0/12.0,4.0/12.0,4.0/12.0),SIMD3<Double>(4.0/12.0,8.0/12.0,8.0/12.0)]
    case .h:
      shifts = [SIMD3<Double>(0,0,0),SIMD3<Double>(8.0/12.0,4.0/12.0,0),SIMD3<Double>(0,8.0/12.0,4.0/12.0)]
    case .d:
      shifts = [SIMD3<Double>(0,0,0),SIMD3<Double>(4.0/12.0,4.0/12.0,4.0/12.0),SIMD3<Double>(8.0/12.0,8.0/12.0,8.0/12.0)]
    case .body:
      shifts = [SIMD3<Double>(0,0,0),SIMD3<Double>(0.5,0.5,0.5)]
    case .a_face:
      shifts = [SIMD3<Double>(0,0,0),SIMD3<Double>(0,0.5,0.5)]
    case .b_face:
      shifts = [SIMD3<Double>(0,0,0),SIMD3<Double>(0.5,0,0.5)]
    case .c_face:
      shifts = [SIMD3<Double>(0,0,0),SIMD3<Double>(0.5,0.5,0)]
    default:
      shifts = [SIMD3<Double>(0,0,0)]
    }
    var symmetry: [SKSeitzMatrix] = []
    
    for seitzMatrix in operations
    {
      for shift in shifts
      {
        symmetry.append(SKSeitzMatrix(rotation: seitzMatrix.rotation, translation: seitzMatrix.translation + shift))
      }
    }
    
    return SKSymmetryOperationSet(operations: symmetry)
  }
  
}


