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
import MathKit

public struct SKIntegerSymmetryOperationSet
{
  public var operations: [SKSeitzIntegerMatrix]
  public var centring: SKSpacegroup.Centring
  
  public init(operations: [SKSeitzIntegerMatrix])
  {
    self.operations = operations
    self.centring = .primitive
    
    let latticeTranslation: [SIMD3<Int32>] = self.centering
    switch(latticeTranslation.count)
    {
    case 1:
      self.centring = .primitive
    case 2:
      if latticeTranslation[1].x == 0
      {
        self.centring = .a_face
      }
      else if latticeTranslation[1].y == 0
      {
        self.centring = .b_face
      }
      else if latticeTranslation[1].z == 0
      {
        self.centring = .c_face
      }
    case 3:
      self.centring = .r
      if (latticeTranslation[1].x == 0 || latticeTranslation[1].y == 0 || latticeTranslation[1].z == 0)
      {
        self.centring = .h
      }
    case 4:
      self.centring = .face
    default:
      self.centring = .primitive
    }
  }
  
  public init(encoding: [UInt8])
  {
    centring = .primitive
    let size: Int = encoding.count/3
    
    operations = []
    
    for i in 0..<size
    {
      let x: UInt8 = encoding[3 * i]
      let y: UInt8 = encoding[3 * i + 1]
      let z: UInt8 = encoding[3 * i + 2]
      
      operations.append( SKSeitzIntegerMatrix(encoding: (x,y,z)) )
    }
  }
  
  public init(spaceGroupSetting: SKSpaceGroupSetting, centroSymmetric: Bool)
  {
    centring = .primitive
    let size: Int = spaceGroupSetting.encodedSeitz.count/3
    
    operations = []
    
    for i in 0..<size
    {
      let x: UInt8 = spaceGroupSetting.encodedSeitz[3 * i]
      let y: UInt8 = spaceGroupSetting.encodedSeitz[3 * i + 1]
      let z: UInt8 = spaceGroupSetting.encodedSeitz[3 * i + 2]
      
      let seitz:SKSeitzIntegerMatrix = SKSeitzIntegerMatrix(encoding: (x,y,z))
      
      operations.append(seitz)
    }
    
    if centroSymmetric
    {
      for i in 0..<size
      {
        let x: UInt8 = spaceGroupSetting.encodedSeitz[3 * i]
        let y: UInt8 = spaceGroupSetting.encodedSeitz[3 * i + 1]
        let z: UInt8 = spaceGroupSetting.encodedSeitz[3 * i + 2]
        
        let seitz:SKSeitzIntegerMatrix = SKSeitzIntegerMatrix(encoding: (x,y,z))
        
        let translation: SIMD3<Int32> = seitz.translation + seitz.rotation * spaceGroupSetting.inversionCenter
        
        operations.append(SKSeitzIntegerMatrix(rotation: -seitz.rotation, translation: translation))
      }
    }
  }
  
   
  init(generators: [SKSeitzIntegerMatrix])
  {
    var expandedGroup: [SKSeitzIntegerMatrix] = []
    
    var count: Int = 0
    
    for k in generators
    {
      var i: Int = expandedGroup.count
      var j: Int = 0
      var element: SKSeitzIntegerMatrix = k
      while (true)
      {
        count = count + 1
        if !expandedGroup.contains(element)
        {
          expandedGroup.append(element)
        }
        if (j > i)
        {
          i = i + 1
          j = 0
        }
        if (i == expandedGroup.count) {break}
        element = expandedGroup[j] * expandedGroup[i]
        j = j + 1
      }
    }
 
    
    self.operations = Array(Set(expandedGroup))
    self.centring = .primitive
  }

  
  public var rotations: Set<SKRotationMatrix>
  {
    return Set(self.operations.map{$0.rotation})
  }
  
  
  // the transformationMatrix does not have a translational part
  public func changedBasis(transformationMatrix: SKTransformationMatrix) -> SKIntegerSymmetryOperationSet
  {
    var newSet: [SKSeitzIntegerMatrix] = []
    
    for seitzMatrix in self.operations
    {
      let inverseTransformation = transformationMatrix.inverseTimesDeterminant
      let rotation: SKTransformationMatrix = inverseTransformation * seitzMatrix.rotation * transformationMatrix / Int(transformationMatrix.determinant)
      let translation: SIMD3<Int32> = inverseTransformation * seitzMatrix.translation
      let transformedSeitzMatrix: SKSeitzIntegerMatrix = SKSeitzIntegerMatrix(rotation: SKRotationMatrix(rotation), translation: translation / Int32(transformationMatrix.determinant))
      newSet.append(transformedSeitzMatrix)
    }
    return SKIntegerSymmetryOperationSet(operations: newSet)
  }
  
  public func addingCenteringOperations(centering: SKSpacegroup.Centring) -> SKIntegerSymmetryOperationSet
  {
    let shifts: [SIMD3<Int32>]
    
    switch(centering)
    {
    case .none, .primitive:
      shifts = [SIMD3<Int32>(0,0,0)]
    case .face:
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,6,6),SIMD3<Int32>(6,0,6),SIMD3<Int32>(6,6,0)]
    case .r:
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(8,4,4),SIMD3<Int32>(4,8,8)]
    case .h:
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(8,4,0),SIMD3<Int32>(0,8,4)]
    case .d:
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(4,4,4),SIMD3<Int32>(8,8,8)]
    case .body:
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(6,6,6)]
    case .a_face:
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,6,6)]
    case .b_face:
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(6,0,6)]
    case .c_face:
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(6,6,0)]
    default:
      shifts = [SIMD3<Int32>(0,0,0)]
    }
    var symmetry: [SKSeitzIntegerMatrix] = []
    
    for seitzMatrix in operations
    {
      for shift in shifts
      {
        symmetry.append(SKSeitzIntegerMatrix(rotation: seitzMatrix.rotation, translation: seitzMatrix.translation + shift))
      }
    }
    
    return SKIntegerSymmetryOperationSet(operations: symmetry)
  }
  

  
  public var centering: [SIMD3<Int32>]
  {
    var centering: Set<SIMD3<Int32>> = []
    
    // get the set of unique rotations
    let rotationMatrices: Set<SKRotationMatrix> = Set(operations.map{$0.rotation})
    
    // for each unique rotation, get the translation differences
    for rotatationMatrix in rotationMatrices
    {
      let match: [SKSeitzIntegerMatrix] = operations.filter{$0.rotation == rotatationMatrix}
      for i in 0..<match.count
      {
        for j in i..<match.count
        {
          let translation: SIMD3<Int32> = match[i].translation -  match[j].translation
          centering.insert(translation.modulo(12))
        }
      }
    }
    return Array(centering).sorted(by: {length_squared($0) < length_squared($1)})
  }
  
  // Use site-symmetry to determine symmetrized location of an atom
  // R. W. Grosse-Kunstleve and P. D. Adams, Acta Cryst. (2002). A58, 60-65
  
  func symmetrizedPosition(position: SIMD3<Double>, lattice: double3x3, symmetryPrecision: Double = 1e-5) -> SIMD3<Double>
  {
    var sumRotation: double3x3 = double3x3(0)
    var sumTranslation: SIMD3<Double> = SIMD3<Double>(0,0,0)
    var count: Int = 0
    for operation in operations
    {
      let pos: SIMD3<Double> = operation.rotation * position + SIMD3<Double>(Double(operation.translation.x)/12.0, Double(operation.translation.y)/12.0, Double(operation.translation.z)/12.0)
      if SKSymmetryCell.isOverlap(a: pos, b: position, lattice: lattice, symmetryPrecision: symmetryPrecision)
      {
        sumRotation += double3x3(rotationMatrix: operation.rotation)
        sumTranslation += SIMD3<Double>(Double(operation.translation.x)/12.0, Double(operation.translation.y)/12.0, Double(operation.translation.z)/12.0) -
                          SIMD3<Double>(rint(pos.x - position.x), rint(pos.y - position.y), rint(pos.z - position.z))
        count += 1
      }
    }
    
    let averagedRotation: double3x3 = sumRotation / Double(count)
    let averagedTranslation: SIMD3<Double> = sumTranslation / Double(count)
    
    let symmetrizedPosition: SIMD3<Double> = averagedRotation * position + averagedTranslation
    
    return symmetrizedPosition
  }
  
  public func setEquivalentAtoms(positions: inout [SIMD3<Double>], atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], i: Int, numberOfIndependentAtoms: Int, independentAtomIndices: inout [Int], lattice: double3x3, symmetryPrecision: Double = 1e-5) -> Bool
  {
    for j in 0..<numberOfIndependentAtoms
    {
      for operation in operations
      {
        let index: Int = independentAtomIndices[j]
        let position: SIMD3<Double> = operation.rotation * positions[index] + SIMD3<Double>(Double(operation.translation.x)/12.0, Double(operation.translation.y)/12.0, Double(operation.translation.z)/12.0)
        if SKSymmetryCell.isOverlap(a: position, b: atoms[i].fractionalPosition, lattice: lattice, symmetryPrecision: symmetryPrecision)
        {
          positions[i] = fract(position)
          return true
        }
      }
    }
    return false
  }
  
  
  public func asymmetricAtoms(atoms: inout [(fractionalPosition: SIMD3<Double>, type: Int, asymmetricType: Int)],  lattice: double3x3, symmetryPrecision: Double = 1e-5) -> [(fractionalPosition: SIMD3<Double>, type: Int)]
  {
    var asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = [(atoms[0].fractionalPosition, atoms[0].type)]
    atoms[0].asymmetricType = 0
    
    // loop over all atoms
    loop: for i in 0..<atoms.count
    {
      // skip if already tagged
      if atoms[i].asymmetricType == -1
      {
        for j in 0..<asymmetricAtoms.count
        {
          for operation in operations
          {
            let position: SIMD3<Double> = operation.rotation * atoms[i].fractionalPosition + SIMD3<Double>(Double(operation.translation.x)/12.0, Double(operation.translation.y)/12.0, Double(operation.translation.z)/12.0)
            if SKSymmetryCell.isOverlap(a: position, b: asymmetricAtoms[j].fractionalPosition, lattice: lattice, symmetryPrecision: symmetryPrecision)
            {
              // overlap and the atom is therefore a copy of the asymmetric atom 'j'
              atoms[i].asymmetricType = j
            }
          }
        }
        
        if atoms[i].asymmetricType == -1
        {
        for j in 0..<asymmetricAtoms.count
        {
          for operation in operations
          {
            let position: SIMD3<Double> = operation.rotation * atoms[i].fractionalPosition + SIMD3<Double>(Double(operation.translation.x)/12.0, Double(operation.translation.y)/12.0, Double(operation.translation.z)/12.0)
            if !SKSymmetryCell.isOverlap(a: position, b: asymmetricAtoms[j].fractionalPosition, lattice: lattice, symmetryPrecision: symmetryPrecision)
            {
              asymmetricAtoms.append((atoms[i].fractionalPosition, atoms[i].type))
              atoms[i].asymmetricType = asymmetricAtoms.count - 1
              continue loop
            }
          }
        }
        }
      }
    }
    
    return asymmetricAtoms
  }
  
}
