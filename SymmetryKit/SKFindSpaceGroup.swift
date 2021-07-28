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

// See: R.W. Grosse-Kunstleve, Acta Cryst., A55, 383-395, 1999.
//
// Mathematica-code to obtain A=Q.(1/D)^T.P, the origin-shift is then A.t where t is the translation
// ExtendedSmithForm[M] gives, for an integral matrix M, {D, {P,Q}} where
// D is in Smith normal form and P and Q are matrices such that P M Q = D.
//

// Standard (default) Choices for the Space Group Settings
// ========================================================================================================
// The default choices for the standard (default) settings of the space groups are:
// unique axis b (cell choice 1) for space groups within the monoclinic system.
// obverse triple hexagonal unit cell for R space groups.
// the origin choice two - inversion center at (0,0,0) - for the centrosymmetric space groups for which there are two origin choices, within the orthorhombic, tetragonal and cubic systems.
// orthorhombic: |a| < |b| < |c|; this implies the use of A-, B-and C-centrings in the case of one-face centred cells.
// monoclinic: |a| <= |c| <= |a + c|; a, c, a + c being shortest in the net perpendicular to b.


extension SKSpacegroup
{
  /// Find the space group of a list of fractional atom positions/types and a given unitcell
  ///
  /// - parameter unitCell:                the unitcell
  /// - parameter fractionalPositions:     the fractional position and type of the atoms
  /// - parameter allowPartialOccupancies: whether to allow different type of atoms to occupy the same location.
  /// - parameter symmetryPrecision:       the precision of the symmetry determination
  ///
  /// - returns: a tuple of the Hall-space group number, the origin shift, the conventional lattice, the change-of-basis, the tranformation matrix, the rotation matrix, the fractional position and type of the atoms in the conventional cell and in the asymmetric cell.
  /// - note: unitCell = tuple.rotationMatrix * tuple.cell.unitCell * tuple.transformationMatrix
  ///
  /// The transformation matrix can be a non-integer matrix if the structure has a centring.
  
  public static func SKFindSpaceGroup(unitCell: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], allowPartialOccupancies: Bool, symmetryPrecision: Double = 1e-2) -> (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])?
  {
    var histogram:[Int:Int] = [:]
    
    for atom in atoms
    {
      histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
    }
    
    // Find least occurent element
    let minType: Int = histogram.min{a, b in a.value < b.value}!.key
    
    let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = allowPartialOccupancies ? atoms : atoms.filter{$0.type == minType}
    
    // search for a primitive cell based on the positions of the atoms
    let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: atoms, unitCell: unitCell, allowPartialOccupancies: allowPartialOccupancies, symmetryPrecision: symmetryPrecision)
  
    // convert the unit cell to a reduced Delaunay cell
    guard let DelaunayUnitCell: double3x3 = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: symmetryPrecision) else {return nil}
    
    // find the rotational symmetry of the reduced Delaunay cell
    let latticeSymmetries: SKPointSymmetrySet = SKRotationMatrix.findLatticeSymmetry(unitCell: DelaunayUnitCell, symmetryPrecision: symmetryPrecision)
    
    // adjust the input positions to the reduced Delaunay cell (possibly trimming it, reducing the number of atoms)
    let positionInDelaunayCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = SKSymmetryCell.trim(atoms: atoms, from: unitCell, to: DelaunayUnitCell, allowPartialOccupancies: allowPartialOccupancies, symmetryPrecision: symmetryPrecision)
    let reducedPositionsInDelaunayCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = allowPartialOccupancies ? positionInDelaunayCell : positionInDelaunayCell.filter{$0.type == minType}
    
    // find the rotational and translational symmetries for the atoms in the reduced Delaunay cell (based on the symmetries of the lattice, omtting the ones that are not compatible)
    // the point group of the lattice cannot be lower than the point group of the crystal
    let spaceGroupSymmetries: SKSymmetryOperationSet = SKSpacegroup.findSpaceGroupSymmetry(unitCell: DelaunayUnitCell, reducedAtoms: reducedPositionsInDelaunayCell, atoms: positionInDelaunayCell, latticeSymmetries: latticeSymmetries, allowPartialOccupancies: allowPartialOccupancies, symmetryPrecision: symmetryPrecision)
        
    // create the point symmetry set
    let pointSymmetry: SKPointSymmetrySet = SKPointSymmetrySet(rotations: spaceGroupSymmetries.rotations)
    
    // get the point group from the point symmetry set
    if let pointGroup: SKPointGroup = SKPointGroup(pointSymmetry: pointSymmetry)
    {
      // Use the axes directions of the Laue group-specific symmetry as a new basis
      var Mprime: SKTransformationMatrix = pointGroup.constructAxes(using: spaceGroupSymmetries.operations.map{$0.rotation.proper})
      
      // adjustment of (M',0) to (M,0) for certain combination of Laue and centring types
      switch(pointGroup.laue)
      {
      case .laue_1:
        // change the basis to Niggli cell
        let symmetryCell: (cell: SKSymmetryCell, changeOfBasis: SKTransformationMatrix)? =  SKSymmetryCell(unitCell: DelaunayUnitCell * Mprime).computeReducedNiggliCellAndChangeOfBasisMatrix
        if symmetryCell == nil
        {
          return nil
        }
        Mprime = symmetryCell!.changeOfBasis
      case .laue_2m:
        // Change the basis for this monoclinic centrosymmetric point group using Delaunay reduction in 2D (algorithm of Atsushi Togo used)
        // The unique axis is chosen as b, choose shortest a, c lattice vectors (|a| < |c|)
        let computedDelaunayReducedCell2D: double3x3? = SKSymmetryCell.computeDelaunayReducedCell2D(unitCell: DelaunayUnitCell * Mprime)
        if computedDelaunayReducedCell2D == nil
        {
          return nil
        }
        Mprime = SKTransformationMatrix(DelaunayUnitCell.inverse * computedDelaunayReducedCell2D!)
      default:
        break
      }
      
      var centering: SKSpacegroup.Centring = pointGroup.computeCentering(of: Mprime)
      let correctedBasis: SKTransformationMatrix = pointGroup.computeBasisCorrection(of: Mprime, withCentering: &centering)
            
      let primitiveLattice: double3x3 = DelaunayUnitCell * correctedBasis
      
      // transform the symmetries (rotation and translation) from the primtive cell to the conventional cell
      // the centering is used to add the additional translations
      let symmetryInConventionalCell: SKSymmetryOperationSet = spaceGroupSymmetries.changedBasis(transformationMatrix: correctedBasis).addingCenteringOperations(centering: centering)
      
      for spaceGroupNumber in 1...230
      {
        if let HallNumber: Int = spaceGroupHallData[spaceGroupNumber]?.first,
           let value: (origin: SIMD3<Double>, changeOfBasis: SKRotationalChangeOfBasis) = SKSpacegroup.matchSpaceGroup(HallNumber: HallNumber, lattice: primitiveLattice, pointGroupNumber: pointGroup.number,centering: centering, seitzMatrices: Array(symmetryInConventionalCell.operations), symmetryPrecision: symmetryPrecision)
        {
          let conventionalBravaisLattice: double3x3 = primitiveLattice * value.changeOfBasis.inverseRotationMatrix
          
          let transformationMatrix: double3x3 = conventionalBravaisLattice.inverse * unitCell
          
          let spaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: HallNumber)

          let spaceGroupSymmetries: SKIntegerSymmetryOperationSet = spaceGroup.spaceGroupSetting.fullSeitzMatrices
          
          let transform: double3x3 = (conventionalBravaisLattice.inverse * DelaunayUnitCell)
          var atoms: [(fractionalPosition: SIMD3<Double>, type: Int, asymmetricType: Int)] = positionInDelaunayCell.map{(fract(transform*($0.fractionalPosition) + value.origin),$0.type, -1)}
          let asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = spaceGroupSymmetries.asymmetricAtoms(HallNumber: HallNumber, atoms: &atoms, lattice: conventionalBravaisLattice, symmetryPrecision: symmetryPrecision)
          
          let cell: SKSymmetryCell = SKSymmetryCell(unitCell: conventionalBravaisLattice)
          
          let cell2: SKSymmetryCell = SKSymmetryCell(unitCell: cell.conventionalUnitCell(spaceGroup: spaceGroup))
          
          
          let rotationMatrix: double3x3 = conventionalBravaisLattice * cell2.unitCell.inverse
        
          // must be a rigid rotation
          assert((rotationMatrix.determinant-1.0)<1e-5)
          
          return (HallNumber, value.origin, cell2, value.changeOfBasis, transformationMatrix, rotationMatrix, atoms.map{($0.fractionalPosition,$0.type)}, asymmetricAtoms)
        }
      }
      
      // special cases
      // Gross-Kunstleve: special case Pa-3 (205) hallSymbol 501
      for spaceGroupNumber in [205]
      {
        if let HallNumber: Int = spaceGroupHallData[spaceGroupNumber]?.first,
           let origin: SIMD3<Double> = try? getOriginShift(HallNumber: HallNumber, centering: .primitive, changeOfBasis: SKRotationalChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>(0,0, 1),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(1,0,0)])), seitzMatrices: Array(symmetryInConventionalCell.operations), symmetryPrecision: symmetryPrecision)
        {
          let changeOfBasis: SKRotationalChangeOfBasis = SKRotationalChangeOfBasis(rotation: SKRotationMatrix([SIMD3<Int32>(0,0, 1),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(1,0,0)]))
          
          let conventionalBravaisLattice: double3x3 = primitiveLattice * changeOfBasis.inverseRotationMatrix
          
          let transformationMatrix: double3x3 = conventionalBravaisLattice.inverse * unitCell
          
          let spaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: HallNumber)

          let spaceGroupSymmetries: SKIntegerSymmetryOperationSet = spaceGroup.spaceGroupSetting.fullSeitzMatrices
          
          let transform: double3x3 = conventionalBravaisLattice.inverse * DelaunayUnitCell
          var atoms: [(fractionalPosition: SIMD3<Double>, type: Int, asymmetricType: Int)] = positionInDelaunayCell.map{(fract(transform*($0.fractionalPosition) + origin),$0.type, -1)}
          let asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = spaceGroupSymmetries.asymmetricAtoms(HallNumber: HallNumber, atoms: &atoms, lattice: conventionalBravaisLattice, symmetryPrecision: symmetryPrecision)
          
          let cell: SKSymmetryCell = SKSymmetryCell(unitCell: conventionalBravaisLattice)
          
          let cell2: SKSymmetryCell = SKSymmetryCell(unitCell: cell.conventionalUnitCell(spaceGroup: spaceGroup))
          
          let rotationMatrix: double3x3 = conventionalBravaisLattice * cell2.unitCell.inverse
          
          // must be a rigid rotation
          assert((rotationMatrix.determinant-1.0)<1e-5)
          
          return (HallNumber, origin, cell2, changeOfBasis, transformationMatrix, rotationMatrix, atoms.map{($0.fractionalPosition,$0.type)}, asymmetricAtoms)
        }
      }
    }
    return nil
  }
  
  
  public static func SKFindPrimitive(unitCell: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], allowPartialOccupancies: Bool, symmetryPrecision: Double = 1e-2) -> (cell: SKSymmetryCell, primitiveAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])?
  {
    if let spaceGroupData: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)]) = SKFindSpaceGroup(unitCell: unitCell, atoms: atoms, allowPartialOccupancies: allowPartialOccupancies, symmetryPrecision: symmetryPrecision)
    {
      let centring: Centring = SKSpacegroup(HallNumber: spaceGroupData.hall).spaceGroupSetting.centring

      let transformation: double3x3
      switch(centring)
      {
      case .primitive:
        transformation = double3x3(rotationMatrix: SKTransformationMatrix.identity)
      case .body:
        transformation = SKTransformationMatrix.bodyCenteredToPrimitive
      case .face:
        transformation = SKTransformationMatrix.faceCenteredToPrimitive
      case .a_face:
        transformation = SKTransformationMatrix.ACenteredToPrimitive
      case .b_face:
        transformation = SKTransformationMatrix.BCenteredToPrimitive
      case .c_face:
        transformation = SKTransformationMatrix.CCenteredToPrimitive
      case .r:
        transformation = SKTransformationMatrix.rhombohedralToPrimitive
      case .h:
        transformation = SKTransformationMatrix.hexagonalToPrimitive
      default:
        transformation = double3x3(rotationMatrix: SKTransformationMatrix.identity)
      }
      
      let primitiveUnitCell: double3x3 = spaceGroupData.cell.unitCell * transformation
      let cell: SKSymmetryCell = SKSymmetryCell(unitCell: primitiveUnitCell)
            
      let positionInPrimitiveCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = SKSymmetryCell.trim(atoms: spaceGroupData.atoms, from: spaceGroupData.cell.unitCell, to: primitiveUnitCell, allowPartialOccupancies: allowPartialOccupancies, symmetryPrecision: symmetryPrecision)
      
      return (cell: cell, primitiveAtoms: positionInPrimitiveCell)
    }
    return nil
  }
  
  // TODO
  public static func findNiggli(unitCell: double3x3, atoms unIndexedAtoms: [(fractionalPosition: SIMD3<Double>, type: String)], allowPartialOccupancies: Bool, symmetryPrecision: Double = 1e-2) -> (cell: SKSymmetryCell, primitiveAtoms: [(fractionalPosition: SIMD3<Double>, type: String)])?
  {
    var histogram:[String:Int] = [:]
    
    for atom in unIndexedAtoms
    {
      histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
    }
    
    var indexForAtom:[String:Int] = [:]
    var atomForIndex:[Int:String] = [:]
    for (index, element) in histogram.enumerated()
    {
      indexForAtom[element.key] = index
      atomForIndex[index] = element.key
    }
    
    // Find least occurent element
    let minType: String = indexForAtom.min{a, b in a.value < b.value}!.key
    let minIndex: Int = indexForAtom[minType]!
    
    // convert: [(0.1,0.2,0.3: "Si"), (0.4,0.5,0.6: "O"),...] to [(0.1,0.2,0.3: 0), (0.4,0.5,0.6: 1),...]
    let atoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = unIndexedAtoms.map{($0.fractionalPosition, indexForAtom[$0.type]!)}
    let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = atoms.filter{$0.type == minIndex}
    
    // search for a primitive cell based on the positions of the atoms
    let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: atoms, unitCell: unitCell, allowPartialOccupancies: allowPartialOccupancies, symmetryPrecision: symmetryPrecision)
    
    //let primitiveCell: SKCell = SKCell(unitCell: primitiveUnitCell)
    guard let DelaunayUnitCell: double3x3 = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell) else {return nil}
    let DelaunayCell: SKSymmetryCell = SKSymmetryCell(unitCell: DelaunayUnitCell)
    //let NiggliCell: (cell: SKCell, changeOfBasis: int3x3) = DelaunayCell.computeReducedNiggliCellAndChangeOfBasisMatrix!
    
    
    
    // adjust the input positions to the reduced Delaunay cell (possibly trimming it, reducing the number of atoms)
    let positionInPrimitiveCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = SKSymmetryCell.trim(atoms: atoms, from: unitCell, to: DelaunayUnitCell, allowPartialOccupancies: allowPartialOccupancies, symmetryPrecision: symmetryPrecision)
    
    // When a transformation matrix with det(P ) > 1 is specified, a dialog box appears to ask you whether or not you want to search for additional sites lying in the resultant unit cell
    // If det(P) < 1, the same position may result from two or more sites
    
    //let changedlattice: double3x3 = DelaunayUnitCell * NiggliCell.changeOfBasis
    //let transform: double3x3 = unitCell.inverse * NiggliCell.cell.unitCell
    
    return (cell: DelaunayCell, primitiveAtoms: positionInPrimitiveCell.map{(fract($0.fractionalPosition), atomForIndex[$0.type]!)})
  }
  
  
  /// Find the symmetry elements of the atomic configuration
  ///
  /// - parameter fractionalPositions: the fractional positions of the atoms
  /// - parameter latticeSymmetries: the symmetry elements of the lattice
  /// - parameter symmetryPrecision: the precision of the search (default: 1e-2)
  ///
  /// - returns: the symmetry operations, i.e. a list of (integer rotation matrix, translation vector)
  public static func findSpaceGroupSymmetry(unitCell: double3x3, reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)], atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], latticeSymmetries: SKPointSymmetrySet, allowPartialOccupancies: Bool, symmetryPrecision: Double = 1e-2) -> SKSymmetryOperationSet
  {
    var spaceGroupSymmetries: [SKSeitzMatrix] = []
    
    for rotationMatrix in latticeSymmetries.rotations
    {
      let translations: [SIMD3<Double>] = SKSymmetryCell.primitiveTranslationVectors(unitCell: unitCell, reducedAtoms: reducedAtoms, atoms: atoms, rotationMatrix: rotationMatrix, allowPartialOccupancies: allowPartialOccupancies, symmetryPrecision: symmetryPrecision)
       //print("translations")
      //print(translations)
      
      for translation in translations
      {
        spaceGroupSymmetries.append(SKSeitzMatrix(rotation: rotationMatrix, translation: translation))
      }
    }
    return SKSymmetryOperationSet(operations: spaceGroupSymmetries)
  }
  
  
  
  public static func getOriginShift(HallNumber: Int, centering: SKSpacegroup.Centring, changeOfBasis: SKRotationalChangeOfBasis, seitzMatrices: [SKSeitzMatrix], symmetryPrecision: Double = 1e-2) throws -> SIMD3<Double>?
  {
    var translations: int3x3 = int3x3()
    var translationsnew: double3x3 = double3x3()
    
    let dataBaseSpaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: HallNumber)
    var dataBaseSpaceGroupGenerators = SKSeitzIntegerMatrix.SeitzMatrices(generatorEncoding: dataBaseSpaceGroup.spaceGroupSetting.encodedGenerators)
    
    // apply change-of-basis to generators
    for i in 0..<dataBaseSpaceGroupGenerators.count
    {
      dataBaseSpaceGroupGenerators[i] = changeOfBasis * dataBaseSpaceGroupGenerators[i]
    }
    
    // apply change-of-basis to lattice translations
    var spaceGroupLatticeTranslations = dataBaseSpaceGroup.spaceGroupSetting.latticeTranslations
    for i in 0..<spaceGroupLatticeTranslations.count
    {
      spaceGroupLatticeTranslations[i] = changeOfBasis * spaceGroupLatticeTranslations[i]
    }
    
    // apply change-of-basis to centring
    var dataBaseSpaceGroupCentering = dataBaseSpaceGroup.spaceGroupSetting.centring
    switch(dataBaseSpaceGroupCentering)
    {
    case .a_face, .b_face, .c_face:
      if spaceGroupLatticeTranslations[1].x == 0
      {
        dataBaseSpaceGroupCentering = .a_face
      }
      if spaceGroupLatticeTranslations[1].y == 0
      {
        dataBaseSpaceGroupCentering = .b_face
      }
      if spaceGroupLatticeTranslations[1].z == 0
      {
        dataBaseSpaceGroupCentering = .c_face
      }
      break
    default:
      break
    }
    
    // return if the centring is not equal to the spacegroup one
    if centering != dataBaseSpaceGroupCentering
    {
      return nil
    }
    
    // apply change-of-basis to the Seitz-matrices
    var dataBaseSpaceGroupSeitzMatrices: [SKSeitzIntegerMatrix] =  dataBaseSpaceGroup.spaceGroupSetting.SeitzMatricesWithoutTranslation
    for i in 0..<dataBaseSpaceGroupSeitzMatrices.count
    {
      dataBaseSpaceGroupSeitzMatrices[i] = changeOfBasis * dataBaseSpaceGroupSeitzMatrices[i]
    }
    
    for i in 0..<dataBaseSpaceGroupGenerators.count
    {
      guard let index: Int = seitzMatrices.firstIndex(where: {$0.rotation == dataBaseSpaceGroupGenerators[i].rotation}) else {return nil}
      translations[i] = SKSeitzIntegerMatrix(SeitzMatrx: seitzMatrices[index]).translation
      translationsnew[i] = seitzMatrices[index].translation
    }
    
    var transformation: SKTransformationMatrix = SKTransformationMatrix.identity
    switch(dataBaseSpaceGroupCentering)
    {
    case .primitive:
      transformation = SKTransformationMatrix.identity
    case .body:
      transformation = SKTransformationMatrix.primitiveToBodyCentered
    case .face:
      transformation = SKTransformationMatrix.primitiveToFaceCentered
    case .a_face:
      transformation = SKTransformationMatrix.primitiveToACentered
    case .b_face:
      transformation = SKTransformationMatrix.primitiveToBCentered
    case .c_face:
      transformation = SKTransformationMatrix.primitiveToCCentered
    case .r:
      transformation = SKTransformationMatrix.primitiveToRhombohedral
    case .h:
      transformation = SKTransformationMatrix.primitiveToHexagonal
    default:
      break
    }
    
    let changeToPrimitive: SKIntegerChangeOfBasis = SKIntegerChangeOfBasis(inversionTransformation: transformation)
    
    let r1: SKRotationMatrix = dataBaseSpaceGroupGenerators[0].rotation
    let r2: SKRotationMatrix = dataBaseSpaceGroupGenerators.count > 1 ? dataBaseSpaceGroupGenerators[1].rotation : SKRotationMatrix.identity
    let r3: SKRotationMatrix = dataBaseSpaceGroupGenerators.count > 2 ? dataBaseSpaceGroupGenerators[2].rotation : SKRotationMatrix.identity
    
    let t1: SKTransformationMatrix = changeToPrimitive * SKTransformationMatrix(r1 - SKRotationMatrix.identity)
    let t2: SKTransformationMatrix = changeToPrimitive * SKTransformationMatrix(r2 - SKRotationMatrix.identity)
    let t3: SKTransformationMatrix = changeToPrimitive * SKTransformationMatrix(r3 - SKRotationMatrix.identity)
    
    
    // m is a 9x3 matrix
    let m: RingMatrix = RingMatrix(Int3x3: [t1.int3x3,t2.int3x3,t3.int3x3])
    
    // The system M * cp = b (mod Z) can be solved by computing the Smith normal form D = PMQ.
    // b is the translation difference, cp the origin shift
    // D is a matrix in diagonal form with diagonal entries d1, . . . , dn.
    // P is square, 9x9, invertible matrix
    // Q is square, 3x3, invertible matrix
    let sol:  (P: RingMatrix, Q: RingMatrix, D: RingMatrix) = try m.SmithNormalForm()
    
    var b: Matrix = Matrix(rows: 9, columns: 1, repeatedValue: 0.0)
    for i in 0..<dataBaseSpaceGroupGenerators.count
    {
      let seitzMatrix: SKSeitzIntegerMatrix? = dataBaseSpaceGroupSeitzMatrices.filter{$0.rotation == dataBaseSpaceGroupGenerators[i].rotation}.first
      guard seitzMatrix != nil else {return nil}
      
      let transPrimitive: SIMD3<Double> = changeToPrimitive * translationsnew[i]
      
      let dataBaseTranslation: SIMD3<Int32>  = changeToPrimitive * dataBaseSpaceGroupGenerators[i].translation
      
      let translationDifference: SIMD3<Double> = fract(transPrimitive - SIMD3<Double>(dataBaseTranslation) / 24.0)
      b[3*i,0] = translationDifference.x
      b[3*i+1,0] = translationDifference.y
      b[3*i+2,0] = translationDifference.z
    }
    
    // v (9x1) =  P (9x9) x b (9,1)
    let v: Matrix = sol.P <*> b
    
    // The system P * b = v, v = [v1,...,vn] has solutions(mod Z) if and only if vi==0 whenever di=0
    if (sol.D[0,0] == 0 && abs(v[0,0] - rint(v[0,0])) > symmetryPrecision) ||
       (sol.D[1,1] == 0 && abs(v[1,0] - rint(v[1,0])) > symmetryPrecision) ||
       (sol.D[2,2] == 0 && abs(v[2,0] - rint(v[2,0])) > symmetryPrecision)
    {
      return nil
    }
    for i in 3..<9
    {
      if abs(v[i,0] - rint(v[i,0])) > symmetryPrecision
      {
        return nil
      }
    }
    
    var Dinv: Matrix = Matrix(rows: 3, columns: 9, repeatedValue: 0.0)
    for i in 0..<3
    {
      if (sol.D[i,i] != 0)
      {
        Dinv[i,i] = 1.0 / Double(sol.D[i,i])
      }
    }

    // sol.Q (3x3), T (3x9), sol.P (9x9), bm (9x1) -> (3x1)
    let cp: Matrix = (sol.Q <*> Dinv <*> sol.P) <*> b
    
    let originShift: SIMD3<Double> = fract(SIMD3<Double>(cp[0], cp[1], cp[2]))
    let basis: SKIntegerChangeOfBasis = SKIntegerChangeOfBasis(inverse: changeToPrimitive)
    return fract(changeOfBasis.inverse * (basis * originShift))
  }
  
    
  public static func matchSpaceGroup(HallNumber: Int, lattice: double3x3, pointGroupNumber: Int, centering: SKSpacegroup.Centring, seitzMatrices: [SKSeitzMatrix], symmetryPrecision: Double = 1e-2)  -> (origin: SIMD3<Double>, changeOfBasis: SKRotationalChangeOfBasis)?
  {
    // bail out early if the checked space group is not of the right point-group
    if SKSpacegroup.spaceGroupData[HallNumber].pointGroupNumber != pointGroupNumber
    {
      return nil
    }
    
    switch(SKPointGroup.pointGroupData[pointGroupNumber].holohedry)
    {
    case .none:
      break
    case .triclinic, .tetragonal, .trigonal, .hexagonal:
      if let originShift: SIMD3<Double> = try? getOriginShift(HallNumber: HallNumber, centering: centering, changeOfBasis: SKRotationalChangeOfBasis(rotation: SKRotationMatrix.identity), seitzMatrices: seitzMatrices, symmetryPrecision: symmetryPrecision)
      {
        return (originShift, SKRotationalChangeOfBasis(rotation: SKRotationMatrix.identity))
      }
    case .monoclinic:
      var solutions: [(SIMD3<Double>, SKRotationalChangeOfBasis)] = []
      for changeOfMonoclinicCentering in SKRotationalChangeOfBasis.changeOfMonoclinicCentering
      {
        if let originShift: SIMD3<Double> = try? getOriginShift(HallNumber: HallNumber, centering: centering, changeOfBasis: changeOfMonoclinicCentering, seitzMatrices: seitzMatrices, symmetryPrecision: symmetryPrecision)
        {
          //let conventionalBravaisLatticeA: double3x3 = lattice * changeOfMonoclinicCentering.inverseRotationMatrix
          //let cellA: SKSymmetryCell = SKSymmetryCell(unitCell: conventionalBravaisLatticeA)
          //print("Solution:", cellA.unitCell, cellA)
          
          solutions.append((originShift, changeOfMonoclinicCentering))
        }
      }
      return solutions.sorted(by: { a, b in
        let conventionalBravaisLatticeA: double3x3 = lattice * a.1.inverseRotationMatrix
        let cellA: SKSymmetryCell = SKSymmetryCell(unitCell: conventionalBravaisLatticeA)
        let conventionalBravaisLatticeB: double3x3 = lattice * b.1.inverseRotationMatrix
        let cellB: SKSymmetryCell = SKSymmetryCell(unitCell: conventionalBravaisLatticeB)
        
        return (cellA.a + cellA.c) < (cellB.a + cellB.c)
        /*
        if [18,39,72,81,90].contains(HallNumber)
        {
          return (cellA.a, cellA.c, cellA.beta) < (cellB.a, cellB.c, cellB.beta)
         
        }
        else
        {
          return ((cellA.a < cellA.c) ? 1.0 : 0.0, cellA.a, cellB.c) < ((cellB.a < cellB.c) ? 1.0 : 0.0, cellB.a, cellB.c)
          
        }*/
      }).first
    case .orthorhombic:
      // try six orthorhombic orientations
      var solutions: [(SIMD3<Double>, SKRotationalChangeOfBasis)] = []
      for changeOfOrthorhombicCentering in SKRotationalChangeOfBasis.changeOfOrthorhombicCentering
      {
        if let originShift: SIMD3<Double> = try? getOriginShift(HallNumber: HallNumber, centering: centering, changeOfBasis: changeOfOrthorhombicCentering, seitzMatrices: seitzMatrices, symmetryPrecision: symmetryPrecision)
        {
          solutions.append((originShift, changeOfOrthorhombicCentering))
        }
      }
      
      // return the solution that is most like a<b<c
      return solutions.sorted(by: { a, b in
        let conventionalBravaisLatticeA: double3x3 = lattice * a.1.inverseRotationMatrix
        let cellA: SKSymmetryCell = SKSymmetryCell(unitCell: conventionalBravaisLatticeA)
        let conventionalBravaisLatticeB: double3x3 = lattice * b.1.inverseRotationMatrix
        let cellB: SKSymmetryCell = SKSymmetryCell(unitCell: conventionalBravaisLatticeB)
        return (cellA.a, cellA.b) < (cellB.a, cellB.b)
      }).first
    case .cubic:
      if let originShift: SIMD3<Double> = try? getOriginShift(HallNumber: HallNumber, centering: centering, changeOfBasis: SKRotationalChangeOfBasis(rotation: SKRotationMatrix.identity), seitzMatrices: seitzMatrices, symmetryPrecision: symmetryPrecision)
      {
        return (originShift, SKRotationalChangeOfBasis.identity)
      }
    }
    
    return nil
  }
}
