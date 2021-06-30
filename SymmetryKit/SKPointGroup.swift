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
import simd
import MathKit


// the Laue class defines the symmetry of the diffraction pattern

public struct SKPointGroup
{
  private var table: RotationalOccuranceTable = RotationalOccuranceTable()
  
  public var number: Int = 0
  public var symbol: String = ""
  public var schoenflies: String = ""
  public var holohedry: Holohedry = .none
  public var laue: Laue = .none
  public var centrosymmetric: Bool = false
  public var enantiomorphic: Bool = false
  
  private init(table: RotationalOccuranceTable, number: Int, symbol: String, schoenflies: String, holohedry: Holohedry, laue: Laue, centrosymmetric: Bool, enantiomorphic: Bool)
  {
    self.table = table
    self.number = number
    self.symbol = symbol
    self.schoenflies = schoenflies
    self.holohedry = holohedry
    self.laue = laue
    self.centrosymmetric = centrosymmetric
    self.enantiomorphic = enantiomorphic
  }
  
  public enum Holohedry
  {
    case none
    case triclinic
    case monoclinic
    case orthorhombic
    case tetragonal
    case trigonal
    case hexagonal
    case cubic
  }
  
  public enum Laue: Int
  {
    case none = 0
    case laue_1 = 1
    case laue_2m = 2
    case laue_mmm = 3
    case laue_4m = 4
    case laue_4mmm = 5
    case laue_3 = 6
    case laue_3m = 7
    case laue_6m = 8
    case laue_6mmm = 9
    case laue_m3 = 10
    case laue_m3m = 11
  }
  
  
  
  public init(number: Int)
  {
    let pointGroup: SKPointGroup = SKPointGroup.pointGroupData[number]
    
    self.number = pointGroup.number
    self.symbol = pointGroup.symbol
    self.schoenflies = pointGroup.schoenflies
    self.holohedry = pointGroup.holohedry
    self.laue = pointGroup.laue
    self.centrosymmetric = pointGroup.centrosymmetric
    self.enantiomorphic = pointGroup.enantiomorphic
  }
  
  // initalize the point-group from a set of rotations
  public init?(pointSymmetry: SKPointSymmetrySet)
  {
    var table: RotationalOccuranceTable = RotationalOccuranceTable()
    
    let rotationMatrices: Set<SKRotationMatrix > = pointSymmetry.rotations
    
    for rotation in rotationMatrices
    {
      if let occurance: Int = table.occurance[rotation.type]
      {
        table.occurance[rotation.type] = occurance + 1
      }
    }
    
    let pointGroup: [SKPointGroup] = SKPointGroup.pointGroupData.filter{$0.table == table}
    
    if pointGroup.isEmpty {return nil}
    
    if let pointGroup = pointGroup.first
    {
      number = pointGroup.number
      symbol = pointGroup.symbol
      schoenflies = pointGroup.schoenflies
      holohedry = pointGroup.holohedry
      laue = pointGroup.laue

    }
  }
  
  // Lookup-table used for the construction of a basis (Table 5 in the article)
  // (R.W. Grosse-Kunstleve, "Algorithms for deriving crystallographic space-group information", Acta Cryst. A55, 383-395, 1999)
  private let rotationTypeForBasis: [Laue: Int] =
  [
    .laue_1: 0,
    .laue_2m: 2,
    .laue_mmm: 2,
    .laue_4m: 4,
    .laue_4mmm: 4,
    .laue_3: 3,
    .laue_3m: 3,
    .laue_6m: 3,
    .laue_6mmm: 3,
    .laue_m3: 2,
    .laue_m3m: 4
  ]

  /// construct a basis system for the particular point-group using the Laue group
  ///
  /// Note : The basic idea for the construction of a basis is to use the axes directions of the Laue group-specific symmetry as a new basis.
  ///        (R.W. Grosse-Kunstleve, "Algorithms for deriving crystallographic space-group information", Acta Cryst. A55, 383-395, 1999)
  ///
  /// - parameter SeitzMatrices: the symmetry elements
  ///
  /// - returns: an orthogonal axes system
  public func constructAxes(usingSeitzMatrices SeitzMatrices: [SKSeitzIntegerMatrix]) -> SKTransformationMatrix?
  {
    switch(self.laue)
    {
    case .laue_1:
      return SKTransformationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,1)])
    case .laue_2m:
      // look for all proper rotation matrices of the wanted rotation type
      let properRotationMatrices: [SKRotationMatrix] = SeitzMatrices.map{$0.rotation.proper}.filter{$0.type.rawValue == 2}
      
      if let properRotationmatrix: SKRotationMatrix = properRotationMatrices.first
      {
        var axes: SKTransformationMatrix = SKTransformationMatrix()
        
        // set the rotation axis as the first axis
        axes[1] = properRotationmatrix.rotationAxis
        
        // possible candidates for the second axis are vectors that are orthogonal to the axes of rotation
        var orthogonalAxes: [SIMD3<Int32>] = properRotationmatrix.orthogonalToAxisDirection(rotationOrder: 2)
        
        // the second axis is the shortest orthogonal axis
        axes[0] = orthogonalAxes.reduce(orthogonalAxes[0], { length_squared($0) <  length_squared($1) ? $0 : $1})
        
        if let index: Int = orthogonalAxes.firstIndex(of: axes[0])
        {
          orthogonalAxes.remove(at: index)
          
          axes[2] = orthogonalAxes.reduce(orthogonalAxes[0], { length_squared($0) <  length_squared($1) ? $0 : $1})
          
          if axes.determinant < 0
          {
            return SKTransformationMatrix([axes[0],axes[1],axes[2]])
          }
          return axes
        }
      }
    case .laue_mmm, .laue_m3, .laue_m3m:
      // The vectors are immediately available for these cases.
      if let rotationalTypeForBasis: Int = self.rotationTypeForBasis[self.laue]
      {
        // look for all proper rotation matrices of the wanted rotation type and take their rotation axes (use a set to avoid duplicates)
        let allAxes: Set<SIMD3<Int32>> = Set(SeitzMatrices.map{$0.rotation.proper}.filter{$0.type.rawValue == rotationalTypeForBasis}.map{$0.rotationAxis})
        
        
        // outside access to 'allPossibleRotationAxes' FIX or CHECK
        let uniqueAxis: [SIMD3<Int32>] = Array(Set(allAxes)).sorted{SKRotationMatrix.allPossibleRotationAxes.firstIndex(of: $0)! < SKRotationMatrix.allPossibleRotationAxes.firstIndex(of: $1)!}
        //let uniqueAxis: [int3] = allAxes.sorted{length_squared($0) < length_squared($1)}
        
        if uniqueAxis.count >= 3
        {
          let axes: SKTransformationMatrix = SKTransformationMatrix([uniqueAxis[0],uniqueAxis[1],uniqueAxis[2]])
          
          if axes.determinant < 0
          {
            return SKTransformationMatrix([axes[0],axes[2],axes[1]])
          }
          return axes
        }
      }
    case .laue_4m,  .laue_4mmm, .laue_3, .laue_3m, .laue_6m, .laue_6mmm:
      if let rotationalTypeForBasis: Int = self.rotationTypeForBasis[self.laue]
      {
        // look for all proper rotation matrices of the wanted rotation type
        let properRotationMatrices: [SKRotationMatrix] = SeitzMatrices.map{$0.rotation.proper}.filter{$0.type.rawValue == rotationalTypeForBasis}
        if let properRotationmatrix: SKRotationMatrix = properRotationMatrices.first
        {
          var axes: SKTransformationMatrix = SKTransformationMatrix()
          
          // set the rotation axis as the first axis
          axes[2] = properRotationmatrix.rotationAxis
          
          // possible candidates for the second axis are vectors that are orthogonal to the axes of rotation
          let orthogonalAxes: [SIMD3<Int32>] = properRotationmatrix.orthogonalToAxisDirection(rotationOrder: rotationalTypeForBasis)
          
          for orthogonalAxis in orthogonalAxes
          {
            axes[0] = orthogonalAxis

            let axisVector: SIMD3<Int32> =  properRotationmatrix * orthogonalAxis
            
            if SKRotationMatrix.allPossibleRotationAxes.contains(axisVector)
            {
              axes[1] = axisVector
              
              // to avoid F-center choice det=4
              if abs(int3x3([axes[0],axes[1],axes[2]]).determinant) < 4
              {
                if axes.determinant < 0
                {
                  return SKTransformationMatrix([axes[1],axes[0],axes[2]])
                }
                return axes
              }
            }
            
            if SKRotationMatrix.allPossibleRotationAxes.contains(0 &- axisVector)
            {
              axes[1] = axisVector

              // to avoid F-center choice det=4
              if abs(int3x3([axes[0],axes[1],axes[2]]).determinant) < 4
              {
                if axes.determinant < 0
                {
                  return SKTransformationMatrix([axes[1],axes[0],axes[2]])
                }
                return axes
              }
            }
          }
        }
      }
    default:
      return nil
    }
    return nil
  }
  
  private static func getBaseCentering(transformMatrix: int3x3) -> SKSpacegroup.Centring
  {
    // detect c-center
    for i in 0..<3
    {
      if (transformMatrix[0,i] == 0 &&
        transformMatrix[1,i] == 0 &&
        abs(transformMatrix[2,i]) == 1)
      {
        return .c_face
      }
    }
    
    // detect a-center
    for i in 0..<3
    {
      if (abs(transformMatrix[0,i]) == 1 &&
        transformMatrix[1,i] == 0 &&
        transformMatrix[2,i] == 0)
      {
        return .a_face
      }
    }
    
    // detect b-center
    for i in 0..<3
    {
      if (transformMatrix[0,i] == 0 &&
        abs(transformMatrix[1,i]) == 1 &&
        transformMatrix[2,i] == 0)
      {
        return .b_face
      }
    }
    
    // detect body-center
    let sum: Int32 = abs(transformMatrix[0,0]) + abs(transformMatrix[1,0]) + abs(transformMatrix[2,0])
    if sum == Int32(2)
    {
      return .body
    }
    
    fatalError()
  }

  public func computeCentering(of basis: SKTransformationMatrix) -> SKSpacegroup.Centring
  {
    let det: Int32 = abs(basis.determinant)
    
    // the absolute value of the determinant gives the scale factor by which volume is multiplied under the associated linear transformation,
    // while its sign indicates whether the transformation preserves orientation
    
    // Number of lattice points per cell (1.2.1 in Hahn 2005 fifth ed.)
    // 1: primitive centred
    // 2: C-face centred, B-face centred, A-face centred, body-centred
    // 3: rhombohedrally centred, hexagonally centred
    // 4: all-face centred
    
    switch (det)
    {
    case 1:
      return .primitive
    case 2:
      // detect a-center
      for i in 0..<3
      {
        if (abs(basis[0,i]) == 1 && basis[1,i] == 0 && basis[2,i] == 0)
        {
          return .a_face
        }
      }
      
      // detect b-center
      for i in 0..<3
      {
        if (basis[0,i] == 0 && abs(basis[1,i]) == 1 && basis[2,i] == 0)
        {
          return .b_face
        }
      }
      
      // detect c-center
      for i in 0..<3
      {
        if (basis[0,i] == 0 && basis[1,i] == 0 && abs(basis[2,i]) == 1)
        {
          return .c_face
        }
      }
      
      // detect body-center
      let sum: Int32 = abs(basis[0,0]) + abs(basis[1,0]) + abs(basis[2,0])
      if  sum == Int32(2)
      {
        return .body
      }
      return .none
    case 3:
      return .r
    case 4:
      return .face
    default:
      return .none
    }
  }
  
  public func computeBasisCorrection( of basis: SKTransformationMatrix, withCentering centering: inout SKSpacegroup.Centring) ->  SKTransformationMatrix
  {
    let det: Int32 = abs(basis.determinant)
    let lau: SKPointGroup.Laue = self.laue
    
    // the absolute value of the determinant gives the scale factor by which volume is multiplied under the associated linear transformation,
    // while its sign indicates whether the transformation preserves orientation
    
    // Number of lattice points per cell (1.2.1 in Hahn 2005 fifth ed.)
    // 1: primitive centred (including R-centered description with ‘rhombohedral axes’)
    // 2: C-face centred, B-face centred, A-face centred, body-centred
    // 3: Rhombohedrally centred (description with ‘hexagonal axes’), Hexagonally centred
    // 4: all-face centred

    switch (det)
    {
    case 1:
      return SKTransformationMatrix.identity
    case 2:
      // a “standard” conventional cell is always C-centred and a′ < b′ regardless of symmetry
      switch (centering)
      {
      case .a_face where lau == .laue_2m:
        // Tranformation monoclinic A-centring to C-centring (preserving b-axis)
        // Axes a and c are swapped, to keep the same handiness b (to keep Beta obtuse) is made negative
        centering = .c_face
        return SKTransformationMatrix([SIMD3<Int32>(0,0,1),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(1,0,0)]) // monoclinic a to c
      case .a_face where lau != .laue_2m:
        centering = .c_face
        return SKTransformationMatrix([SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,1),SIMD3<Int32>(1,0,0)])  // a to c
      case .b_face:
        centering = .c_face
        return SKTransformationMatrix([SIMD3<Int32>(0,0,1),SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0)])    // b to c
      case .body where lau == .laue_2m:
        centering = .c_face
        return SKTransformationMatrix([SIMD3<Int32>(1,0,1),SIMD3<Int32>(0, 1,0),SIMD3<Int32>(-1,0,0)]) // monoclinic i to c
      default:
        return SKTransformationMatrix.identity
      }
    case 3:
      let m: MKint3x3 = (MKint3x3([SIMD3<Int32>(0,-1,1),SIMD3<Int32>(1,0,-1),SIMD3<Int32>(1,1,1)]) * MKint3x3(basis.int3x3.inverse))
      if m.greatestCommonDivisor == 3
      {
        // reverse detected -> change to obverse
        return SKTransformationMatrix([SIMD3<Int32>(1, 1, 0), SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, 0, 1)])
      }
      return SKTransformationMatrix.identity
    case 4:
      return SKTransformationMatrix.identity
    default:
      return SKTransformationMatrix.identity
    }
  }


  
  public func computeCenteringAndBasisCorrection(of basis: int3x3) -> (centring: SKSpacegroup.Centring, correctionMatrix: double3x3)
  {
    let det: Int = abs(basis.determinant)
    let lau: SKPointGroup.Laue = self.laue
    
    // the absolute value of the determinant gives the scale factor by which volume is multiplied under the associated linear transformation,
    // while its sign indicates whether the transformation preserves orientation
    
    // Number of lattice points per cell (1.2.1 in Hahn 2005 fifth ed.)
    // 1: primitive centred
    // 2: C-face centred, B-face centred, A-face centred, body-centred
    // 3: rhombohedrally centred, hexagonally centred
    // 4: all-face centred
    
    switch (det)
    {
    case 1:
      return (.primitive, double3x3(1.0))
    case 2:
      let centering: SKSpacegroup.Centring = SKPointGroup.getBaseCentering(transformMatrix: basis)
     
      // a “standard” conventional cell is always C-centred and a′ < b′ regardless of symmetry
      switch (centering)
      {
      case .a_face where lau == .laue_2m:
        // Tranformation monoclinic A-centring to C-centring (preserving b-axis)
        // Axes a and c are swapped, to keep the same handiness b (to keep Beta obtuse) is made negative
        return (.c_face, double3x3([SIMD3<Double>(0,0,1),SIMD3<Double>(0,-1,0),SIMD3<Double>(1,0,0)])) // monoclinic a to c
      case .a_face where lau != .laue_2m:
        return (.c_face, double3x3([SIMD3<Double>(0,1,0),SIMD3<Double>(0,0,1),SIMD3<Double>(1,0,0)]))  // a to c
      case .b_face:
        return (.c_face, double3x3([SIMD3<Double>(0,0,1),SIMD3<Double>(1,0,0),SIMD3<Double>(0,1,0)]))    // b to c
      case .body where lau == .laue_2m:
        return (.c_face, double3x3([SIMD3<Double>(1,0,1),SIMD3<Double>(0, 1,0),SIMD3<Double>(-1,0,0)])) // monoclinic i to c
      default:
        return (centering, double3x3(1.0))
      }
    case 3:
      // hP (a=b) but not hR (a=b=c)
      // determinant = 1/3
      let trans_corr_mat: double3x3 = basis * double3x3([SIMD3<Double>(2.0/3.0,1.0/3.0,1.0/3.0),SIMD3<Double>(-1.0/3.0,1.0/3.0,1.0/3.0),SIMD3<Double>(-1.0/3.0,-2.0/3.0,1.0/3.0)])  // rhombo_obverse
      if trans_corr_mat.isInteger(precision: 0.1)
      {
        return (.r, double3x3([SIMD3<Double>(2.0/3.0,1.0/3.0,1.0/3.0),SIMD3<Double>(-1.0/3.0,1.0/3.0,1.0/3.0),SIMD3<Double>(-1.0/3.0,-2.0/3.0,1.0/3.0)]))
      }
      let trans_corr_mat2: double3x3 = basis * double3x3([SIMD3<Double>(1.0/3.0,2.0/3.0,1.0/3.0),SIMD3<Double>(-2.0/3.0,-1.0/3.0,1.0/3.0),SIMD3<Double>( 1.0/3.0,-1.0/3.0,1.0/3.0)])  // rhombo_reverse
      if trans_corr_mat2.isInteger(precision: 0.1)
      {
        return (.r, double3x3([SIMD3<Double>(1.0/3.0,2.0/3.0,1.0/3.0),SIMD3<Double>(-2.0/3.0,-1.0/3.0,1.0/3.0),SIMD3<Double>( 1.0/3.0,-1.0/3.0,1.0/3.0)]))
      }
      
      return (.r, basis * double3x3([SIMD3<Double>(2.0/3.0,1.0/3.0,1.0/3.0),SIMD3<Double>(-1.0/3.0,1.0/3.0,1.0/3.0),SIMD3<Double>(-1.0/3.0,-2.0/3.0,1.0/3.0)]))
    case 4:
      return (.face, double3x3(1.0))
    default:
      fatalError()
    }
  }
  

  public static func findPointGroup(unitCell: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], symmetryPrecision: Double = 1e-5) -> SKPointGroup?
  {
    let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: atoms, atoms: atoms, unitCell: unitCell, symmetryPrecision: symmetryPrecision)
    guard let primitiveDelaunayUnitCell: double3x3 = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: symmetryPrecision) else { return nil}
    let latticeSymmetries: SKPointSymmetrySet = SKRotationMatrix.findLatticeSymmetry(unitCell: primitiveDelaunayUnitCell, symmetryPrecision: symmetryPrecision)
                                                                                     
    let positionInPrimitiveCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = SKSymmetryCell.trim(atoms: atoms, from: unitCell, to: primitiveDelaunayUnitCell)
    // FIX!!!
    let spaceGroupSymmetries: SKIntegerSymmetryOperationSet = SKSpacegroup.findSpaceGroupSymmetry(reducedAtoms: positionInPrimitiveCell, atoms: positionInPrimitiveCell, latticeSymmetries: latticeSymmetries, symmetryPrecision: symmetryPrecision)
    
    let pointSymmetry: SKPointSymmetrySet = SKPointSymmetrySet(rotations: spaceGroupSymmetries.rotations)
    return SKPointGroup(pointSymmetry: pointSymmetry)
  }
  


  public static let pointGroupData: [SKPointGroup] =
    [
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 0, 0, 0, 0, 0, 0, 0), number: 0, symbol: "",       schoenflies: "",    holohedry: .none,         laue: .none,       centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 0, 0, 0, 0), number: 1, symbol: "1",      schoenflies: "C1",  holohedry: .triclinic,    laue: .laue_1,     centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 0, 1, 1, 0, 0, 0, 0), number: 2, symbol: "-1",     schoenflies: "Ci",  holohedry: .triclinic,    laue: .laue_1,     centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 1, 0, 0, 0), number: 3, symbol: "2",      schoenflies: "C2",  holohedry: .monoclinic,   laue: .laue_2m,    centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 1, 0, 1, 0, 0, 0, 0), number: 4, symbol: "m",      schoenflies: "Cs",  holohedry: .monoclinic,   laue: .laue_2m,    centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 1, 1, 1, 1, 0, 0, 0), number: 5, symbol: "2/m",    schoenflies: "C2h", holohedry: .monoclinic,   laue: .laue_2m,    centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 3, 0, 0, 0), number: 6, symbol: "222",    schoenflies: "D2",  holohedry: .orthorhombic, laue: .laue_mmm,   centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 2, 0, 1, 1, 0, 0, 0), number: 7, symbol: "mm2",    schoenflies: "C2v", holohedry: .orthorhombic, laue: .laue_mmm,   centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 3, 1, 1, 3, 0, 0, 0), number: 8, symbol: "mmm",    schoenflies: "D2h", holohedry: .orthorhombic, laue: .laue_mmm,   centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 1, 0, 2, 0), number: 9, symbol: "4",      schoenflies: "C4",  holohedry: .tetragonal,   laue: .laue_4m,    centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable(0, 2, 0, 0, 0, 1, 1, 0, 0, 0), number: 10, symbol: "-4",    schoenflies: "S4",  holohedry: .tetragonal,   laue: .laue_4m,    centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 2, 0, 1, 1, 1, 1, 0, 2, 0), number: 11, symbol: "4/m",   schoenflies: "C4h", holohedry: .tetragonal,   laue: .laue_4m,    centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 5, 0, 2, 0), number: 12, symbol: "422",   schoenflies: "D4",  holohedry: .tetragonal,   laue: .laue_4mmm,  centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 4, 0, 1, 1, 0, 2, 0), number: 13, symbol: "4mm",   schoenflies: "C4v", holohedry: .tetragonal,   laue: .laue_4mmm,  centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 2, 0, 2, 0, 1, 3, 0, 0, 0), number: 14, symbol: "-42m",  schoenflies: "D2d", holohedry: .tetragonal,   laue: .laue_4mmm,  centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 2, 0, 5, 1, 1, 5, 0, 2, 0), number: 15, symbol: "4/mmm", schoenflies: "D4h", holohedry: .tetragonal,   laue: .laue_4mmm,  centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 0, 2, 0, 0), number: 16, symbol: "3",     schoenflies: "C3",  holohedry: .trigonal,     laue: .laue_3,     centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 2, 0, 1, 1, 0, 2, 0, 0), number: 17, symbol: "-3",    schoenflies: "C3i", holohedry: .trigonal,     laue: .laue_3,     centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 3, 2, 0, 0), number: 18, symbol: "32",    schoenflies: "D3",  holohedry: .trigonal,     laue: .laue_3m,    centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 3, 0, 1, 0, 2, 0, 0), number: 19, symbol: "3m",    schoenflies: "C3v", holohedry: .trigonal,     laue: .laue_3m,    centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 2, 3, 1, 1, 3, 2, 0, 0), number: 20, symbol: "-3m",   schoenflies: "D3d", holohedry: .trigonal,     laue: .laue_3m,    centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 1, 2, 0, 2), number: 21, symbol: "6",     schoenflies: "C6",  holohedry: .hexagonal,    laue: .laue_6m,    centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable(2, 0, 0, 1, 0, 1, 0, 2, 0, 0), number: 22, symbol: "-6",    schoenflies: "C3h", holohedry: .hexagonal,    laue: .laue_6m,    centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(2, 0, 2, 1, 1, 1, 1, 2, 0, 2), number: 23, symbol: "6/m",   schoenflies: "C6h", holohedry: .hexagonal,    laue: .laue_6m,    centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 7, 2, 0, 2), number: 24, symbol: "622",   schoenflies: "D6",  holohedry: .hexagonal,    laue: .laue_6mmm,  centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 6, 0, 1, 1, 2, 0, 2), number: 25, symbol: "6mm",   schoenflies: "C6v", holohedry: .hexagonal,    laue: .laue_6mmm,  centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(2, 0, 0, 4, 0, 1, 3, 2, 0, 0), number: 26, symbol: "-6m",   schoenflies: "D3h", holohedry: .hexagonal,    laue: .laue_6mmm,  centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(2, 0, 2, 7, 1, 1, 7, 2, 0, 2), number: 27, symbol: "6/mmm", schoenflies: "D6h", holohedry: .hexagonal,    laue: .laue_6mmm,  centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 3, 8, 0, 0), number: 28, symbol: "23",    schoenflies: "T",   holohedry: .cubic,        laue: .laue_m3,    centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 8, 3, 1, 1, 3, 8, 0, 0), number: 29, symbol: "m-3",   schoenflies: "Th",  holohedry: .cubic,        laue: .laue_m3,    centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 9, 8, 6, 0), number: 30, symbol: "432",   schoenflies: "O",   holohedry: .cubic,        laue: .laue_m3m,   centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable(0, 6, 0, 6, 0, 1, 3, 8, 0, 0), number: 31, symbol: "-43m",  schoenflies: "Td",  holohedry: .cubic,        laue: .laue_m3m,   centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable(0, 6, 8, 9, 1, 1, 9, 8, 6, 0), number: 32, symbol: "m-3m",  schoenflies: "Oh",  holohedry: .cubic,        laue: .laue_m3m,   centrosymmetric: true,  enantiomorphic: false)
  ]
}

private struct RotationalOccuranceTable: Equatable
{
  var occurance: [SKRotationMatrix.rotationType: Int] =
    [SKRotationMatrix.rotationType.axis_6m: 0,
     SKRotationMatrix.rotationType.axis_4m: 0,
     SKRotationMatrix.rotationType.axis_3m: 0,
     SKRotationMatrix.rotationType.axis_2m: 0,
     SKRotationMatrix.rotationType.axis_1m: 0,
     SKRotationMatrix.rotationType.axis_1: 0,
     SKRotationMatrix.rotationType.axis_2: 0,
     SKRotationMatrix.rotationType.axis_3: 0,
     SKRotationMatrix.rotationType.axis_4: 0,
     SKRotationMatrix.rotationType.axis_6: 0]
  
  init()
  {
    
  }
  
  init(_ axis_6m: Int, _ axis_4m: Int, _ axis_3m: Int, _ axis_2m: Int, _ axis_1m: Int, _ axis_1: Int, _ axis_2: Int, _ axis_3: Int, _ axis_4: Int, _ axis_6: Int)
  {
    occurance[SKRotationMatrix.rotationType.axis_6m] = axis_6m
    occurance[SKRotationMatrix.rotationType.axis_4m] = axis_4m
    occurance[SKRotationMatrix.rotationType.axis_3m] = axis_3m
    occurance[SKRotationMatrix.rotationType.axis_2m] = axis_2m
    occurance[SKRotationMatrix.rotationType.axis_1m] = axis_1m
    occurance[SKRotationMatrix.rotationType.axis_1] = axis_1
    occurance[SKRotationMatrix.rotationType.axis_2] = axis_2
    occurance[SKRotationMatrix.rotationType.axis_3] = axis_3
    occurance[SKRotationMatrix.rotationType.axis_4] = axis_4
    occurance[SKRotationMatrix.rotationType.axis_6] = axis_6
  }
  
  public static func ==(left: RotationalOccuranceTable, right: RotationalOccuranceTable) -> Bool
  {
    
    if left.occurance.count != right.occurance.count { return false }
    
    for (key, lhsub) in left.occurance
    {
      if let rhsub = right.occurance[key]
      {
        if lhsub != rhsub
        {
          return false
        }
      }
      else
      {
        return false
      }
    }
    return true
    
  }
}



