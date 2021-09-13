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
      let inverseTransformation = transformationMatrix.adjugate
      let rotation: int3x3 = inverseTransformation.int3x3 * seitzMatrix.rotation.int3x3 * transformationMatrix.int3x3 / Int(transformationMatrix.determinant)
      let translation: SIMD3<Int32> = inverseTransformation.int3x3 * seitzMatrix.translation
      let transformedSeitzMatrix: SKSeitzIntegerMatrix = SKSeitzIntegerMatrix(rotation: SKRotationMatrix(int3x3: rotation), translation: translation / Int32(transformationMatrix.determinant))
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
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,12,12),SIMD3<Int32>(12,0,12),SIMD3<Int32>(12,12,0)]
    case .r:
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(16,8,8),SIMD3<Int32>(8,16,16)]
    case .h:
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(16,8,0),SIMD3<Int32>(0,16,8)]
    case .d:
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(8,8,8),SIMD3<Int32>(16,16,16)]
    case .body:
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(12,12,12)]
    case .a_face:
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,12,12)]
    case .b_face:
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(12,0,12)]
    case .c_face:
      shifts = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(12,12,0)]
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
          centering.insert(translation.modulo(24))
        }
      }
    }
    return Array(centering).sorted(by: {length_squared($0) < length_squared($1)})
  }
  
  // Use site-symmetry to determine symmetrized location of an atom
  // R. W. Grosse-Kunstleve and P. D. Adams, Acta Cryst. (2002). A58, 60-65
  
  func symmetrizedPosition(position: SIMD3<Double>, lattice: double3x3, symmetryPrecision: Double = 1e-2) -> SIMD3<Double>
  {
    var sumRotation: double3x3 = double3x3(0)
    var sumTranslation: SIMD3<Double> = SIMD3<Double>(0,0,0)
    var count: Int = 0
    for operation in operations
    {
      let pos: SIMD3<Double> = operation.rotation * position + SIMD3<Double>(Double(operation.translation.x)/24.0, Double(operation.translation.y)/24.0, Double(operation.translation.z)/24.0)
      if SKSymmetryCell.isOverlap(a: pos, b: position, lattice: lattice, symmetryPrecision: symmetryPrecision)
      {
        sumRotation += double3x3(rotationMatrix: operation.rotation)
        sumTranslation += SIMD3<Double>(Double(operation.translation.x)/24.0, Double(operation.translation.y)/24.0, Double(operation.translation.z)/24.0) -
                          SIMD3<Double>(rint(pos.x - position.x), rint(pos.y - position.y), rint(pos.z - position.z))
        count += 1
      }
    }
    
    let averagedRotation: double3x3 = sumRotation / Double(count)
    let averagedTranslation: SIMD3<Double> = sumTranslation / Double(count)
    
    let symmetrizedPosition: SIMD3<Double> = averagedRotation * position + averagedTranslation
    
    return symmetrizedPosition
  }
  
  public func setEquivalentAtoms(positions: inout [SIMD3<Double>], atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], i: Int, numberOfIndependentAtoms: Int, independentAtomIndices: inout [Int], lattice: double3x3, symmetryPrecision: Double = 1e-2) -> Bool
  {
    for j in 0..<numberOfIndependentAtoms
    {
      for operation in operations
      {
        let index: Int = independentAtomIndices[j]
        let position: SIMD3<Double> = operation.rotation * positions[index] + SIMD3<Double>(Double(operation.translation.x)/24.0, Double(operation.translation.y)/24.0, Double(operation.translation.z)/24.0)
        if SKSymmetryCell.isOverlap(a: position, b: atoms[i].fractionalPosition, lattice: lattice, symmetryPrecision: symmetryPrecision)
        {
          positions[i] = fract(position)
          return true
        }
      }
    }
    return false
  }
  
  public func symmetrize(lattice: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)], symmetryPrecision: Double = 1e-2) -> [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)]
  {
    var symmetrizedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)] = []
    symmetrizedAtoms.reserveCapacity(atoms.count)
    
    for i in 0..<atoms.count
    {
      var averageRotation: SKRotationMatrix = SKRotationMatrix(0)
      var averageTranslation: SIMD3<Double> = SIMD3<Double>(0,0,0)
      var count: Int = 0
      
      for operation in operations
      {
        let translation: SIMD3<Double> = SIMD3<Double>(Double(operation.translation.x)/24.0, Double(operation.translation.y)/24.0, Double(operation.translation.z)/24.0)
        let position: SIMD3<Double> = operation.rotation * atoms[i].fractionalPosition + translation
       
        if SKSymmetryCell.isOverlap(a: position, b: atoms[i].fractionalPosition, lattice: lattice, symmetryPrecision: symmetryPrecision)
        {
          averageRotation += operation.rotation
          averageTranslation += translation - rint(position - atoms[i].fractionalPosition)
          count = count + 1
        }
      }
      
      let averagedRotation: double3x3 = double3x3(rotationMatrix: averageRotation) / Double(count)
      let averagedTranslation: SIMD3<Double> = SIMD3<Double>(Double(averageTranslation.x), Double(averageTranslation.y), Double(averageTranslation.z)) / Double(count)
      
      let symmetrizedAtom: (fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double) = (averagedRotation * atoms[i].fractionalPosition + averagedTranslation, type: atoms[i].type, occupancy: atoms[i].occupancy)
      symmetrizedAtoms.append(symmetrizedAtom)
    }
    
    return symmetrizedAtoms
  }
  
  public func asymmetricAtoms(HallNumber: Int, atoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)],  lattice: double3x3, allowPartialOccupancies: Bool, symmetryPrecision: Double = 1e-2) -> [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)]
  {
    var atoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double, asymmetricType: Int)] = atoms.map{($0.fractionalPosition, $0.type, $0.occupancy, -1)}
        
    var asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)] = []
    
    // loop over all atoms
    loop: for i in 0..<atoms.count
    {
      // skip if already tagged
      if atoms[i].asymmetricType == -1
      {
        // loop over all current asymmetric atoms, and see if one of the symmetry-copies matches with an asymmetric atom
        for j in 0..<asymmetricAtoms.count
        {
          if(atoms[i].type == asymmetricAtoms[j].type)
          {
            for operation in operations
            {
              let position: SIMD3<Double> = operation.rotation * atoms[i].fractionalPosition + SIMD3<Double>(Double(operation.translation.x)/24.0, Double(operation.translation.y)/24.0, Double(operation.translation.z)/24.0)
              if SKSymmetryCell.isOverlap(a: position, b: asymmetricAtoms[j].fractionalPosition, lattice: lattice, symmetryPrecision: symmetryPrecision)
              {
                // overlap and of the same type: the atom is therefore a copy of the asymmetric atom 'j'
                atoms[i].asymmetricType = j
                break
              }
            }
          }
        }
        
        // not typed yet
        if atoms[i].asymmetricType == -1
        {
          asymmetricAtoms.append((atoms[i].fractionalPosition, atoms[i].type, atoms[i].occupancy))
          atoms[i].asymmetricType = asymmetricAtoms.count - 1
          continue loop
          /*
          for j in 0..<asymmetricAtoms.count
          {
            for operation in operations
            {
              let position: SIMD3<Double> = operation.rotation * atoms[i].fractionalPosition + SIMD3<Double>(Double(operation.translation.x)/24.0, Double(operation.translation.y)/24.0, Double(operation.translation.z)/24.0)
              
              var dr: SIMD3<Double> = abs(position - asymmetricAtoms[j].fractionalPosition)
              dr.x -= rint(dr.x)
              dr.y -= rint(dr.y)
              dr.z -= rint(dr.z)
              if length_squared(lattice * dr) > symmetryPrecision * symmetryPrecision && atoms[i].type == asymmetricAtoms[j].type
              {
                asymmetricAtoms.append((atoms[i].fractionalPosition, atoms[i].type, atoms[i].occupancy))
                atoms[i].asymmetricType = asymmetricAtoms.count - 1
                continue loop
              }
            }
          }*/
        }
      }
    }
    
    for i in 0..<asymmetricAtoms.count
    {
      var found: Bool = false
      for operation in operations
      {
        let position: SIMD3<Double> = operation.rotation * asymmetricAtoms[i].fractionalPosition + SIMD3<Double>(Double(operation.translation.x)/24.0, Double(operation.translation.y)/24.0, Double(operation.translation.z)/24.0)
        
        // if directly inside the asymmetric unit cell, overwrite the position and break
        //let spaceGroupNumber = SKSpacegroup.spaceGroupData[HallNumber].spaceGroupNumber
        //if SKAsymmetricUnit.isInsideIUCAsymmetricUnitCell(number: spaceGroupNumber, point: position, precision: 0.0)
        if SKSpacegroup.init(HallNumber: HallNumber).spaceGroupSetting.asymmetricUnit.contains(position)
        {
          asymmetricAtoms[i].fractionalPosition = fract(position)
          found = true
          break
        }
      }
      
      // if directly inside the asymmetric unit cell including a small epsilon, overwrite the position and break
      if(!found)
      {
        for operation in operations
        {
          let position: SIMD3<Double> = operation.rotation * asymmetricAtoms[i].fractionalPosition + SIMD3<Double>(Double(operation.translation.x)/24.0, Double(operation.translation.y)/24.0, Double(operation.translation.z)/24.0)
        
          //let spaceGroupNumber = SKSpacegroup.spaceGroupData[HallNumber].spaceGroupNumber
          //if SKAsymmetricUnit.isInsideIUCAsymmetricUnitCell(number: spaceGroupNumber, point: position, precision: symmetryPrecision)
          if SKSpacegroup.init(HallNumber: HallNumber).spaceGroupSetting.asymmetricUnit.contains(position)
          {
            asymmetricAtoms[i].fractionalPosition = fract(position)
            break
          }
        }
      }
    }
    
    return asymmetricAtoms
  }
  
}
