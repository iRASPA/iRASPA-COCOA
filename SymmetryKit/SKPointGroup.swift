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
  private var table: RotationalOccuranceTable = RotationalOccuranceTable.pointGroup0
  
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
    var table: RotationalOccuranceTable = RotationalOccuranceTable.pointGroup0
    
    let rotationMatrices: OrderedSet<SKRotationMatrix > = pointSymmetry.rotations
        
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
  
  /// The look-up table used for the construction of M'
  ///    Laue group           n_e           |N|
  ///    -1                          1                1
  ///     2/m                     1                2
  ///     mmm                  3                2, 2, 2
  ///     4/m                     1                4
  ///     4/mmm               2                4, 2
  ///    -3                          1                3
  ///    -3m                       2                3, 2
  ///     6/m                     1                3
  ///     6/mmm               2                3, 2
  ///     m-3                     2                3, 2
  ///     m-3m                  2                3, 4
  /// Ref: R.W. Grosse-Kunstleve, "Algorithms for deriving crystallographic space-group information", Acta Cryst. A55, 383-395, 1999
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

  /// Constructs a basis system for the particular point-group using the Laue group
  ///
  /// - parameter properRotations: the proper rotation matrices of the symmetry elements
  ///
  /// - returns: an orthogonal axes system
  ///
  /// M is constructed from the three axis directions (ex,ey,ez):
  ///     | e_x,1 e_y,1 e_z,1 |
  /// M' =  | e_x,2 e_y,2 e_z,2 |
  ///     | e_x,3 e_y,3 e_z,3 |
  /// with det(M') > 0.
  /// The basic idea for the construction of (M', 0) is to use the axes' directions of Laue-group-specific symmetry operations as a new basis.
  ///
  ///
  /// The look-up table used for the construction of M'
  ///    Laue group           n_e           |N|
  ///    -1                          1                1
  ///     2/m                     1                2
  ///     mmm                  3                2, 2, 2
  ///     4/m                     1                4
  ///     4/mmm               2                4, 2
  ///    -3                          1                3
  ///    -3m                       2                3, 2
  ///     6/m                     1                3
  ///     6/mmm               2                3, 2
  ///     m-3                     2                3, 2
  ///     m-3m                  2                3, 4
  /// Ref: R.W. Grosse-Kunstleve, "Algorithms for deriving crystallographic space-group information", Acta Cryst. A55, 383-395, 1999
  public func constructAxes(using properRotations: [SKRotationMatrix]) -> SKTransformationMatrix
  {
    switch(self.laue)
    {
    case .laue_1:
      return SKTransformationMatrix.identity
    case .laue_2m:
      // Look for all proper rotation matrices of rotation type 2
      let properRotationMatrices: [SKRotationMatrix] = properRotations.filter{$0.type.rawValue == 2}
      
      if let properRotationmatrix: SKRotationMatrix = properRotationMatrices.first
      {
        var axes: SKTransformationMatrix = SKTransformationMatrix()
        
        // set the rotation axis as the first axis
        axes[1] = properRotationmatrix.rotationAxis
       
        
        // possible candidates for the second axis are vectors that are orthogonal to the axes of rotation
        var orthogonalAxes: [SIMD3<Int32>] = properRotationmatrix.orthogonalToAxisDirection(rotationOrder: 2)
        
        // the second axis is the shortest orthogonal axis
        axes[0] = orthogonalAxes.reduce(orthogonalAxes[0], { length_squared($0) <=  length_squared($1) ? $0 : $1})
        
        if let index: Int = orthogonalAxes.firstIndex(of: axes[0])
        {
          orthogonalAxes.remove(at: index)
          
          axes[2] = orthogonalAxes.reduce(orthogonalAxes[0], { length_squared($0) <=  length_squared($1) ? $0 : $1})
          
          if axes.determinant < 0
          {
            return SKTransformationMatrix([axes[2],axes[1],axes[0]])
          }
          return axes
        }
      }
    case .laue_mmm, .laue_m3, .laue_m3m:
      // The vectors are immediately available for these cases.
      if let rotationalTypeForBasis: Int = self.rotationTypeForBasis[self.laue]
      {
        // look for all proper rotation matrices of the wanted rotation type and take their rotation axes (use a set to avoid duplicates)
        let allAxes: Set<SIMD3<Int32>> = Set(properRotations.filter{$0.type.rawValue == rotationalTypeForBasis}.map{$0.rotationAxis})
                
        let uniqueAxis: [SIMD3<Int32>] = Array(Set(allAxes)).sorted{SKRotationMatrix.allPossibleRotationAxes.firstIndex(of: $0)! < SKRotationMatrix.allPossibleRotationAxes.firstIndex(of: $1)!}
        //let uniqueAxis: [int3] = allAxes.sorted{length_squared($0) < length_squared($1)}
        
        if uniqueAxis.count >= 3
        {
          let axes: SKTransformationMatrix = SKTransformationMatrix([uniqueAxis[0], uniqueAxis[1], uniqueAxis[2]])
          
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
        let properRotationMatrices: [SKRotationMatrix] = properRotations.filter{$0.type.rawValue == rotationalTypeForBasis}
        
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
            
            if SKRotationMatrix.allPossibleRotationAxes.contains(axisVector) || SKRotationMatrix.allPossibleRotationAxes.contains(0 &- axisVector)
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
    case .none:
      break
    }
    return SKTransformationMatrix.identity
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

  /// Table 3 of spglib lists the conditions to determine the centring types
  /// "spacegroup.c" line 2075 of 2312
  public func computeCentering(of basis: SKTransformationMatrix) -> SKSpacegroup.Centring
  {
    // the absolute value of the determinant gives the scale factor by which volume is multiplied under the associated linear transformation,
    // while its sign indicates whether the transformation preserves orientation
    
    // Number of lattice points per cell (1.2.1 in Hahn 2005 fifth ed.)
    // 1: primitive centred
    // 2: C-face centred, B-face centred, A-face centred, body-centred
    // 3: rhombohedrally centred, hexagonally centred
    // 4: all-face centred
    
    switch (abs(basis.determinant))
    {
    case 1:
      return .primitive
    case 2:
      // detect a-center
      for i in 0..<3
      {
        // if (1,0,0) is found, then 'a' is detected
        if (abs(basis[0,i]) == 1 && basis[1,i] == 0 && basis[2,i] == 0)
        {
          return .a_face
        }
      }
      
      // detect b-center
      for i in 0..<3
      {
        // if (0,1,0) is found, then 'b' is detected
        if (basis[0,i] == 0 && abs(basis[1,i]) == 1 && basis[2,i] == 0)
        {
          return .b_face
        }
      }
      
      // detect c-center
      for i in 0..<3
      {
        // if (0,0,1) is found, then 'b' is detected
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
  
  /// For the convenience in the following steps, the basis vectors are further transformed to have a specific cen- tring type by multiplying a correction matrix M with M′ for the Laue classes of 2/m and mmm and and the rhombohedral system.
  /// For the Laue class 2/m, the basis vectors with the I, A, and B centring types are transformed to those with the C centring type.
  /// For the Laue class mmm, those with the A, and B centring types are transformed to those with the C centring type.
  /// For the rhombohedral system, a rhombohedrally-centred hexagonal cell is obtained by M' in either the obverse or reverse setting.
  ///     This is transformed to the primitive rhombohedral cell by Mobv if it is the obverse setting or by Mrev if it is the reverse setting.
  ///     Only one of M′Mobv or M′Mrev has to be an integer matrix, which is chosen as the transformation matrix.
  ///     By this, it is known whether the rhombohedrally-centred hexagonal cell obtained by M′ is in the obverse or reverse setting.
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
      return basis * SKTransformationMatrix.identity
    case 2:
      // a “standard” conventional cell is always C-centred and a′ < b′ regardless of symmetry
      switch (centering)
      {
      case .a_face where lau == .laue_2m:
        // Tranformation monoclinic A-centring to C-centring (preserving b-axis)
        // Axes a and c are swapped, to keep the same handiness b (to keep Beta obtuse) is made negative
        centering = .c_face
        return basis * SKTransformationMatrix([SIMD3<Int32>(0,0,1),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(1,0,0)]) // monoclinic a to c
      case .a_face where lau != .laue_2m:
        centering = .c_face
        return basis * SKTransformationMatrix([SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,1),SIMD3<Int32>(1,0,0)])  // a to c
      case .b_face:
        centering = .c_face
        return basis * SKTransformationMatrix([SIMD3<Int32>(0,0,1),SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0)])    // b to c
      case .body where lau == .laue_2m:
        centering = .c_face
        return basis * SKTransformationMatrix([SIMD3<Int32>(1,0,1),SIMD3<Int32>(0, 1,0),SIMD3<Int32>(-1,0,0)]) // monoclinic i to c
      default:
        return basis * SKTransformationMatrix.identity
      }
    case 3:
      let m: MKint3x3 = (MKint3x3([SIMD3<Int32>(0,-1,1),SIMD3<Int32>(1,0,-1),SIMD3<Int32>(1,1,1)]) * MKint3x3(basis.int3x3.inverse))
      if m.greatestCommonDivisor == 3
      {
        // reverse detected -> change to obverse
        return basis * SKTransformationMatrix([SIMD3<Int32>(1, 1, 0), SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, 0, 1)])
      }
      return basis * SKTransformationMatrix.identity
    case 4:
      return basis * SKTransformationMatrix.identity
    default:
      return basis * SKTransformationMatrix.identity
    }
  }


  public static func findPointGroup(unitCell: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], allowPartialOccupancies: Bool, symmetryPrecision: Double = 1e-2) -> SKPointGroup?
  {
    let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: atoms, atoms: atoms, unitCell: unitCell, allowPartialOccupancies: allowPartialOccupancies, symmetryPrecision: symmetryPrecision)
    guard let primitiveDelaunayUnitCell: double3x3 = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: symmetryPrecision) else { return nil}
    let latticeSymmetries: SKPointSymmetrySet = SKRotationMatrix.findLatticeSymmetry(unitCell: primitiveDelaunayUnitCell, symmetryPrecision: symmetryPrecision)
                                                                                     
    let positionInPrimitiveCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = SKSymmetryCell.trim(atoms: atoms, from: unitCell, to: primitiveDelaunayUnitCell, allowPartialOccupancies: allowPartialOccupancies, symmetryPrecision: symmetryPrecision)
    
    let spaceGroupSymmetries: SKSymmetryOperationSet = SKSpacegroup.findSpaceGroupSymmetry(unitCell: unitCell, reducedAtoms: positionInPrimitiveCell, atoms: positionInPrimitiveCell, latticeSymmetries: latticeSymmetries, allowPartialOccupancies: allowPartialOccupancies, symmetryPrecision: symmetryPrecision)
    
    let pointSymmetry: SKPointSymmetrySet = SKPointSymmetrySet(rotations: spaceGroupSymmetries.rotations)
    return SKPointGroup(pointSymmetry: pointSymmetry)
  }
  

  /// • Triclinic: 1, 1
  /// • Monoclinic: 2, 2=m, 2/m
  /// • Orthorhombic: 222, 2mm, 2/m2/m2/m (=mmm)
  /// • Tetragonal: 4, 4, 4/m, 42m, 422 4mm 4/m2/m2/m • Trigonal: 3, 3m, 32, 3, 32/m
  /// • Hexagonal: 6, 6, 6/m, 6m2, 622, 6mm, 6/m2/m2/m
  /// • Cubic: 23, 2/m3, 432, 43m, 4/m32/m
  public static let pointGroupData: [SKPointGroup] =
    [
      SKPointGroup(table: RotationalOccuranceTable.pointGroup0, number: 0, symbol: "",       schoenflies: "",    holohedry: .none,         laue: .none,       centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup1, number: 1, symbol: "1",      schoenflies: "C1",  holohedry: .triclinic,    laue: .laue_1,     centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup2, number: 2, symbol: "-1",     schoenflies: "Ci",  holohedry: .triclinic,    laue: .laue_1,     centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup3, number: 3, symbol: "2",      schoenflies: "C2",  holohedry: .monoclinic,   laue: .laue_2m,    centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup4, number: 4, symbol: "m",      schoenflies: "Cs",  holohedry: .monoclinic,   laue: .laue_2m,    centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup5, number: 5, symbol: "2/m",    schoenflies: "C2h", holohedry: .monoclinic,   laue: .laue_2m,    centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup6, number: 6, symbol: "222",    schoenflies: "D2",  holohedry: .orthorhombic, laue: .laue_mmm,   centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup7, number: 7, symbol: "mm2",    schoenflies: "C2v", holohedry: .orthorhombic, laue: .laue_mmm,   centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup8, number: 8, symbol: "mmm",    schoenflies: "D2h", holohedry: .orthorhombic, laue: .laue_mmm,   centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup9, number: 9, symbol: "4",      schoenflies: "C4",  holohedry: .tetragonal,   laue: .laue_4m,    centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup10, number: 10, symbol: "-4",    schoenflies: "S4",  holohedry: .tetragonal,   laue: .laue_4m,    centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup11, number: 11, symbol: "4/m",   schoenflies: "C4h", holohedry: .tetragonal,   laue: .laue_4m,    centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup12, number: 12, symbol: "422",   schoenflies: "D4",  holohedry: .tetragonal,   laue: .laue_4mmm,  centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup13, number: 13, symbol: "4mm",   schoenflies: "C4v", holohedry: .tetragonal,   laue: .laue_4mmm,  centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup14, number: 14, symbol: "-42m",  schoenflies: "D2d", holohedry: .tetragonal,   laue: .laue_4mmm,  centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup15, number: 15, symbol: "4/mmm", schoenflies: "D4h", holohedry: .tetragonal,   laue: .laue_4mmm,  centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup16, number: 16, symbol: "3",     schoenflies: "C3",  holohedry: .trigonal,     laue: .laue_3,     centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup17, number: 17, symbol: "-3",    schoenflies: "C3i", holohedry: .trigonal,     laue: .laue_3,     centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup18, number: 18, symbol: "32",    schoenflies: "D3",  holohedry: .trigonal,     laue: .laue_3m,    centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup19, number: 19, symbol: "3m",    schoenflies: "C3v", holohedry: .trigonal,     laue: .laue_3m,    centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup20, number: 20, symbol: "-3m",   schoenflies: "D3d", holohedry: .trigonal,     laue: .laue_3m,    centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup21, number: 21, symbol: "6",     schoenflies: "C6",  holohedry: .hexagonal,    laue: .laue_6m,    centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup22, number: 22, symbol: "-6",    schoenflies: "C3h", holohedry: .hexagonal,    laue: .laue_6m,    centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup23, number: 23, symbol: "6/m",   schoenflies: "C6h", holohedry: .hexagonal,    laue: .laue_6m,    centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup24, number: 24, symbol: "622",   schoenflies: "D6",  holohedry: .hexagonal,    laue: .laue_6mmm,  centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup25, number: 25, symbol: "6mm",   schoenflies: "C6v", holohedry: .hexagonal,    laue: .laue_6mmm,  centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup26, number: 26, symbol: "-6m",   schoenflies: "D3h", holohedry: .hexagonal,    laue: .laue_6mmm,  centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup27, number: 27, symbol: "6/mmm", schoenflies: "D6h", holohedry: .hexagonal,    laue: .laue_6mmm,  centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup28, number: 28, symbol: "23",    schoenflies: "T",   holohedry: .cubic,        laue: .laue_m3,    centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup29, number: 29, symbol: "m-3",   schoenflies: "Th",  holohedry: .cubic,        laue: .laue_m3,    centrosymmetric: true,  enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup30, number: 30, symbol: "432",   schoenflies: "O",   holohedry: .cubic,        laue: .laue_m3m,   centrosymmetric: false, enantiomorphic: true),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup31, number: 31, symbol: "-43m",  schoenflies: "Td",  holohedry: .cubic,        laue: .laue_m3m,   centrosymmetric: false, enantiomorphic: false),
      SKPointGroup(table: RotationalOccuranceTable.pointGroup32, number: 32, symbol: "m-3m",  schoenflies: "Oh",  holohedry: .cubic,        laue: .laue_m3m,   centrosymmetric: true,  enantiomorphic: false)
  ]
}

/// Table 4 from Grosse-Kunstleve, "Algorithms for deriving crystallographic space-group information", Acta Cryst. (1999). A55, 383--395
/// Table 6 from Atsushi Togo and Isao Tanaka, "Spglib: a software library for crystal symmetry search", https://arxiv.org/pdf/1808.01590.pdf
///
///                                           Numbers of W per rotation type
///                  Pointgroup  Laue class   -6  -4  -3  -2  -1  1  2  3  4  6
///  --------------------------------------------------------------------------
///  triclinic        1           -1           0   0   0   0   0  1  0  0  0  0
///                  -1           -1           0   0   0   0   1  1  0  0  0  0
///  --------------------------------------------------------------------------
///  monoclinic      2            2/m          0   0   0   0   0  1  1  0  0  0
///                  m            2/m          0   0   0   1   0  1  0  0  0  0
///                  2/m          2/m          0   0   0   1   1  1  1  0  0  0
///  --------------------------------------------------------------------------
///  orthorhombic    222          mmm          0   0   0   0   0  1  3  0  0  0
///                  mm2          mmm          0   0   0   2   0  1  1  0  0  0
///                  mmm          mmm          0   0   0   3   1  1  3  0  0  0
///  --------------------------------------------------------------------------
///  tetragonal       4           4/m          0   0   0   0   0  1  1  0  2  0
///                  -4           4/m          0   2   0   0   0  1  1  0  0  0
///                   4/m         4/m          0   2   0   1   1  1  1  0  2  0
///                   422         4/mmm        0   0   0   0   0  1  5  0  2  0
///                   4mm         4/mmm        0   0   0   4   0  1  1  0  2  0
///                  -42m         4/mmm        0   2   0   2   0  1  3  0  0  0
///                   4/mmmm      4/mmm        0   2   0   5   1  1  5  0  2  0
///  --------------------------------------------------------------------------
///  trigonal         3           -3m          0   0   0   0   0  1  0  2  0  2
///                  -3           -3m          0   0   2   0   1  1  0  2  0  0
///                   32          -3m          0   0   0   0   0  1  3  2  0  0
///                   3m          -3m          0   0   0   3   0  1  0  2  0  0
///                  -3m          -3m          0   0   2   3   1  1  3  2  0  0
///  --------------------------------------------------------------------------
///  hexagonal        6            6/m         0   0   0   0   0  1  1  2  0  2
///                  -6            6/m         2   0   0   1   0  1  0  2  0  0
///                   6/m          6/m         2   0   2   1   1  1  1  2  0  2
///                   622          6/mmm       0   0   0   0   0  1  7  2  0  2
///                   6mm          6/mmm       0   0   0   6   0  1  1  2  0  2
///                  -62m          6/mmm       2   0   0   4   0  1  3  2  0  0
///                   6/mmmm       6/mmm       2   0   2   7   1  1  7  2  0  2
///  --------------------------------------------------------------------------
///  cubic            23           m-3         0   0   0   0   0  1  3  8  0  0
///                   m-3          m-3         0   0   8   3   1  1  3  8  0  0
///                   432          m-3m        0   0   0   0   0  1  9  8  6  0
///                  -43m          m-3m        0   6   0   6   0  1  3  8  0  0
///                   m-3m         m-3m        0   6   8   9   1  1  9  8  6  0
///
public struct RotationalOccuranceTable: Equatable
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
  
  static let pointGroup0: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
  static let pointGroup1: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 0, 0, 0, 0)
  static let pointGroup2: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 0, 1, 1, 0, 0, 0, 0)
  static let pointGroup3: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 1, 0, 0, 0)
  static let pointGroup4: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 1, 0, 1, 0, 0, 0, 0)
  static let pointGroup5: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 1, 1, 1, 1, 0, 0, 0)
  static let pointGroup6: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 3, 0, 0, 0)
  static let pointGroup7: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 2, 0, 1, 1, 0, 0, 0)
  static let pointGroup8: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 3, 1, 1, 3, 0, 0, 0)
  static let pointGroup9: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 1, 0, 2, 0)
  static let pointGroup10: RotationalOccuranceTable = RotationalOccuranceTable(0, 2, 0, 0, 0, 1, 1, 0, 0, 0)
  static let pointGroup11: RotationalOccuranceTable = RotationalOccuranceTable(0, 2, 0, 1, 1, 1, 1, 0, 2, 0)
  static let pointGroup12: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 5, 0, 2, 0)
  static let pointGroup13: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 4, 0, 1, 1, 0, 2, 0)
  static let pointGroup14: RotationalOccuranceTable = RotationalOccuranceTable(0, 2, 0, 2, 0, 1, 3, 0, 0, 0)
  static let pointGroup15: RotationalOccuranceTable = RotationalOccuranceTable(0, 2, 0, 5, 1, 1, 5, 0, 2, 0)
  static let pointGroup16: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 0, 2, 0, 0)
  static let pointGroup17: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 2, 0, 1, 1, 0, 2, 0, 0)
  static let pointGroup18: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 3, 2, 0, 0)
  static let pointGroup19: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 3, 0, 1, 0, 2, 0, 0)
  static let pointGroup20: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 2, 3, 1, 1, 3, 2, 0, 0)
  static let pointGroup21: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 1, 2, 0, 2)
  static let pointGroup22: RotationalOccuranceTable = RotationalOccuranceTable(2, 0, 0, 1, 0, 1, 0, 2, 0, 0)
  static let pointGroup23: RotationalOccuranceTable = RotationalOccuranceTable(2, 0, 2, 1, 1, 1, 1, 2, 0, 2)
  static let pointGroup24: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 7, 2, 0, 2)
  static let pointGroup25: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 6, 0, 1, 1, 2, 0, 2)
  static let pointGroup26: RotationalOccuranceTable = RotationalOccuranceTable(2, 0, 0, 4, 0, 1, 3, 2, 0, 0)
  static let pointGroup27: RotationalOccuranceTable = RotationalOccuranceTable(2, 0, 2, 7, 1, 1, 7, 2, 0, 2)
  static let pointGroup28: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 3, 8, 0, 0)
  static let pointGroup29: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 8, 3, 1, 1, 3, 8, 0, 0)
  static let pointGroup30: RotationalOccuranceTable = RotationalOccuranceTable(0, 0, 0, 0, 0, 1, 9, 8, 6, 0)
  static let pointGroup31: RotationalOccuranceTable = RotationalOccuranceTable(0, 6, 0, 6, 0, 1, 3, 8, 0, 0)
  static let pointGroup32: RotationalOccuranceTable = RotationalOccuranceTable(0, 6, 8, 9, 1, 1, 9, 8, 6, 0)
  
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
}



