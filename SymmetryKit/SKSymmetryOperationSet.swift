//
//  SKSymmetryOperationSet.swift
//  SymmetryKit
//
//  Created by David Dubbeldam on 30/06/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import Foundation
import simd

public struct SKSymmetryOperationSet
{
  public var operations: [SKSeitzMatrix]
  //public var centring: SKSpacegroup.Centring
  
  public init(operations: [SKSeitzMatrix])
  {
    self.operations = operations
  }
  
  public var rotations: Set<SKRotationMatrix>
  {
    return Set(self.operations.map{$0.rotation})
  }
  
  // the transformationMatrix does not have a translational part
  public func changedBasis(transformationMatrix: SKTransformationMatrix) -> SKSymmetryOperationSet
  {
    var newSet: [SKSeitzMatrix] = []
    
    for seitzMatrix in self.operations
    {
      let inverseTransformation = transformationMatrix.inverse
      let rotation: SKTransformationMatrix = inverseTransformation * seitzMatrix.rotation * transformationMatrix / Int(transformationMatrix.determinant)
      let translation: SIMD3<Double> = inverseTransformation * seitzMatrix.translation
      let transformedSeitzMatrix: SKSeitzMatrix = SKSeitzMatrix(rotation: SKRotationMatrix(rotation), translation: translation / Double(transformationMatrix.determinant))
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
      shifts = [SIMD3<Double>(0.0,0.0,0.0)]
    case .face:
      shifts = [SIMD3<Double>(0.0,0.0,0.0),SIMD3<Double>(0.0,0.5,0.5),SIMD3<Double>(0.5,0,0.5),SIMD3<Double>(0.5,0.5,0.0)]
    case .r:
      shifts = [SIMD3<Double>(0.0,0.0,0.0),SIMD3<Double>(2.0/3.0,1.0/3.0,1.0/3.0),SIMD3<Double>(1.0/3.0,2.0/3.0,2.0/3.0)]
    case .h:
      shifts = [SIMD3<Double>(0.0,0.0,0.0),SIMD3<Double>(2.0/3.0,1.0/3.0,0),SIMD3<Double>(0,2.0/3.0,1.0/3.0)]
    case .d:
      shifts = [SIMD3<Double>(0.0,0.0,0.0),SIMD3<Double>(1.0/3.0,1.0/3.0,1.0/3.0),SIMD3<Double>(2.0/3.0,2.0/3.0,2.0/3.0)]
    case .body:
      shifts = [SIMD3<Double>(0.0,0.0,0.0),SIMD3<Double>(0.5,0.5,0.5)]
    case .a_face:
      shifts = [SIMD3<Double>(0.0,0.0,0.0),SIMD3<Double>(0.0,0.5,0.5)]
    case .b_face:
      shifts = [SIMD3<Double>(0.0,0.0,0.0),SIMD3<Double>(0.5,0.0,0.5)]
    case .c_face:
      shifts = [SIMD3<Double>(0.0,0.0,0.0),SIMD3<Double>(0.5,0.5,0.0)]
    default:
      shifts = [SIMD3<Double>(0.0,0.0,0.0)]
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


