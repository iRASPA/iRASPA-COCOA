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
// orthorhombic: |b| > |a| > |c|


extension SKSpacegroup
{
  public static func findNiggli(unitCell: double3x3, atoms unIndexedAtoms: [(fractionalPosition: SIMD3<Double>, type: String)], symmetryPrecision: Double = 1e-5) -> (cell: SKSymmetryCell, primitiveAtoms: [(fractionalPosition: SIMD3<Double>, type: String)])?
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
    let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: atoms, unitCell: unitCell, symmetryPrecision: symmetryPrecision)
    
    //let primitiveCell: SKCell = SKCell(unitCell: primitiveUnitCell)
    guard let DelaunayUnitCell: double3x3 = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell) else {return nil}
    let DelaunayCell: SKSymmetryCell = SKSymmetryCell(unitCell: DelaunayUnitCell)
    //let NiggliCell: (cell: SKCell, changeOfBasis: int3x3) = DelaunayCell.computeReducedNiggliCellAndChangeOfBasisMatrix!
    
    
    
    // adjust the input positions to the reduced Delaunay cell (possibly trimming it, reducing the number of atoms)
    let positionInPrimitiveCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = SKSymmetryCell.trim(atoms: atoms, from: unitCell, to: DelaunayUnitCell)
    
    // When a transformation matrix with det(P ) > 1 is specified, a dialog box appears to ask you whether or not you want to search for additional sites lying in the resultant unit cell
    // If det(P) < 1, the same position may result from two or more sites
    
    //let changedlattice: double3x3 = DelaunayUnitCell * NiggliCell.changeOfBasis
    //let transform: double3x3 = unitCell.inverse * NiggliCell.cell.unitCell
    
    return (cell: DelaunayCell, primitiveAtoms: positionInPrimitiveCell.map{(fract($0.fractionalPosition), atomForIndex[$0.type]!)})
  }
  
  
  
  public static func SKFindPrimitive(unitCell: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], symmetryPrecision: Double = 1e-5) -> (cell: SKSymmetryCell, primitiveAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])?
  {
    if let spaceGroupData: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)]) = SKFindSpaceGroup(unitCell: unitCell, atoms: atoms, symmetryPrecision: symmetryPrecision)
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
            
      let positionInPrimitiveCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = SKSymmetryCell.trim(atoms: spaceGroupData.atoms, from: spaceGroupData.cell.unitCell, to: primitiveUnitCell)
      
      return (cell: cell, primitiveAtoms: positionInPrimitiveCell)
    }
    return nil
  }
  
  /// Find the space group of a list of fractional atom positions and a given unitcell
  ///
  /// - parameter unitCell:            the unitcell
  /// - parameter fractionalPositions: the fractional positions of the atoms
  /// - parameter symmetryPrecision:   the precision of the symmetry determination
  ///
  /// - returns: a tuple of the Hall-space group number, the origin, the lattice, and the change-of-basis.
  public static func SKFindSpaceGroup(unitCell: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], symmetryPrecision: Double = 1e-5) -> (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])?
  {
    var histogram:[Int:Int] = [:]
    
    for atom in atoms
    {
      histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
    }
    
    // Find least occurent element
    let minType: Int = histogram.min{a, b in a.value < b.value}!.key
    
    let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = atoms.filter{$0.type == minType}
    
    // search for a primitive cell based on the positions of the atoms
    let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: atoms, unitCell: unitCell, symmetryPrecision: symmetryPrecision)
  
    // convert the unit cell to a reduced Delaunay cell
    guard let DelaunayUnitCell: double3x3 = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: symmetryPrecision) else {return nil}
    
    // find the rotational symmetry of the reduced Delaunay cell
    let latticeSymmetries: SKPointSymmetrySet = SKRotationMatrix.findLatticeSymmetry(primitiveUnitCell: primitiveUnitCell, unitCell: DelaunayUnitCell, symmetryPrecision: symmetryPrecision)
    
    // adjust the input positions to the reduced Delaunay cell (possibly trimming it, reducing the number of atoms)
    let positionInDelaunayCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = SKSymmetryCell.trim(atoms: atoms, from: unitCell, to: DelaunayUnitCell)
    let reducedPositionsInDelaunayCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = positionInDelaunayCell.filter{$0.type == minType}
    
    // find the rotational and translational symmetries for the atoms in the reduced Delaunay cell (based on the symmetries of the lattice, omtting the ones that are not compatible)
    // the point group of the lattice cannot be lower than the point group of the crystal
    let spaceGroupSymmetries: SKSymmetryOperationSet = SKSpacegroup.findSpaceGroupSymmetry(unitCell: DelaunayUnitCell, reducedAtoms: reducedPositionsInDelaunayCell, atoms: positionInDelaunayCell, latticeSymmetries: latticeSymmetries, symmetryPrecision: symmetryPrecision)
        
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
        let computedDelaunayReducedCell2D: double3x3? = SKSymmetryCell.computeDelaunayReducedCell2D(unitCell: DelaunayUnitCell * Mprime, uniqueAxis: 1)
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
      
      //print("DelaunayUnitCell")
      //print(DelaunayUnitCell)
      //print("corrected")
      //print(primitiveLattice)
      
      // transform the symmetries (rotation and translation) from the primtive cell to the conventional cell
      // the centering is used to add the additional translations
      let symmetryInConventionalCell: SKSymmetryOperationSet = spaceGroupSymmetries.changedBasis(transformationMatrix: correctedBasis).addingCenteringOperations(centering: centering)
      
      for spaceGroupNumber in 1...230
      {
        if let HallNumber: Int = spaceGroupHallData[spaceGroupNumber]?.first,
           let value: (origin: SIMD3<Double>, changeOfBasis: SKRotationalChangeOfBasis) = SKSpacegroup.matchSpaceGroup(HallNumber: HallNumber, lattice: primitiveLattice, pointGroupNumber: pointGroup.number,centering: centering, seitzMatrices: Array(symmetryInConventionalCell.operations), symmetryPrecision: symmetryPrecision)
        {
          let conventionalBravaisLattice: double3x3 = primitiveLattice * value.changeOfBasis.inverseRotationMatrix
          
          let spaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: HallNumber)

          let spaceGroupSymmetries: SKIntegerSymmetryOperationSet = spaceGroup.spaceGroupSetting.fullSeitzMatrices
          
          let transform: double3x3 = (conventionalBravaisLattice.inverse * DelaunayUnitCell)
          var atoms: [(fractionalPosition: SIMD3<Double>, type: Int, asymmetricType: Int)] = positionInDelaunayCell.map{(fract(transform*($0.fractionalPosition) + value.origin),$0.type, -1)}
          let asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = spaceGroupSymmetries.asymmetricAtoms(atoms: &atoms, lattice: conventionalBravaisLattice, symmetryPrecision: symmetryPrecision)
          
          let cell: SKSymmetryCell = SKSymmetryCell(unitCell: conventionalBravaisLattice)          
          
          let cell2: SKSymmetryCell = SKSymmetryCell(unitCell: cell.conventionalUnitCell(spaceGroup: spaceGroup))
          
          return (HallNumber, value.origin, cell2, value.changeOfBasis, atoms.map{($0.fractionalPosition,$0.type)}, asymmetricAtoms)
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
          
          let spaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: HallNumber)

          let spaceGroupSymmetries: SKIntegerSymmetryOperationSet = spaceGroup.spaceGroupSetting.fullSeitzMatrices
          
          let transform: double3x3 = conventionalBravaisLattice.inverse * DelaunayUnitCell
          var atoms: [(fractionalPosition: SIMD3<Double>, type: Int, asymmetricType: Int)] = positionInDelaunayCell.map{(fract(transform*($0.fractionalPosition) + origin),$0.type, -1)}
          let asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = spaceGroupSymmetries.asymmetricAtoms(atoms: &atoms, lattice: conventionalBravaisLattice, symmetryPrecision: symmetryPrecision)
          
          let cell: SKSymmetryCell = SKSymmetryCell(unitCell: conventionalBravaisLattice)
          let cell2: SKSymmetryCell = SKSymmetryCell(unitCell: cell.conventionalUnitCell(spaceGroup: spaceGroup))
          
          return (HallNumber, origin, cell2, changeOfBasis, atoms.map{($0.fractionalPosition,$0.type)}, asymmetricAtoms)
        }
      }
    }
    return nil
  }
  
  public static func SKTestConstructBasis(unitCell: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], symmetryPrecision: Double = 1e-5) -> SKTransformationMatrix?
  {
    var histogram:[Int:Int] = [:]
    
    for atom in atoms
    {
      histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
    }
    
    // Find least occurent element
    let minType: Int = histogram.min{a, b in a.value < b.value}!.key
    
    let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = atoms.filter{$0.type == minType}
    
    // search for a primitive cell based on the positions of the atoms
    let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: atoms, unitCell: unitCell, symmetryPrecision: symmetryPrecision)
  
    // convert the unit cell to a reduced Delaunay cell
    guard let DelaunayUnitCell: double3x3 = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: symmetryPrecision) else {return nil}
    
    // find the rotational symmetry of the reduced Delaunay cell
    let latticeSymmetries: SKPointSymmetrySet = SKRotationMatrix.findLatticeSymmetry(primitiveUnitCell: primitiveUnitCell, unitCell: DelaunayUnitCell, symmetryPrecision: symmetryPrecision)
    
    // adjust the input positions to the reduced Delaunay cell (possibly trimming it, reducing the number of atoms)
    let positionInDelaunayCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = SKSymmetryCell.trim(atoms: atoms, from: unitCell, to: DelaunayUnitCell)
    let reducedPositionsInDelaunayCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = positionInDelaunayCell.filter{$0.type == minType}
    
    // find the rotational and translational symmetries for the atoms in the reduced Delaunay cell (based on the symmetries of the lattice, omtting the ones that are not compatible)
    // the point group of the lattice cannot be lower than the point group of the crystal
    let spaceGroupSymmetries: SKSymmetryOperationSet = SKSpacegroup.findSpaceGroupSymmetry(unitCell: DelaunayUnitCell, reducedAtoms: reducedPositionsInDelaunayCell, atoms: positionInDelaunayCell, latticeSymmetries: latticeSymmetries, symmetryPrecision: symmetryPrecision)
        
    // create the point symmetry set
    let pointSymmetry: SKPointSymmetrySet = SKPointSymmetrySet(rotations: spaceGroupSymmetries.rotations)
    
    // get the point group from the point symmetry set
    if let pointGroup: SKPointGroup = SKPointGroup(pointSymmetry: pointSymmetry)
    {
      // Use the axes directions of the Laue group-specific symmetry as a new basis
      let Mprime: SKTransformationMatrix = pointGroup.constructAxes(using: spaceGroupSymmetries.operations.map{$0.rotation.proper})
      
      return Mprime
    }
    return nil
  }
  
  public static func SKTestConstructUpdatedBasis(unitCell: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], symmetryPrecision: Double = 1e-5) -> SKTransformationMatrix?
  {
    var histogram:[Int:Int] = [:]
    
    for atom in atoms
    {
      histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
    }
    
    // Find least occurent element
    let minType: Int = histogram.min{a, b in a.value < b.value}!.key
    
    let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = atoms.filter{$0.type == minType}
    
    // search for a primitive cell based on the positions of the atoms
    let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: atoms, unitCell: unitCell, symmetryPrecision: symmetryPrecision)
  
    // convert the unit cell to a reduced Delaunay cell
    guard let DelaunayUnitCell: double3x3 = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: symmetryPrecision) else {return nil}
    
    // find the rotational symmetry of the reduced Delaunay cell
    let latticeSymmetries: SKPointSymmetrySet = SKRotationMatrix.findLatticeSymmetry(primitiveUnitCell: primitiveUnitCell, unitCell: DelaunayUnitCell, symmetryPrecision: symmetryPrecision)
    
    // adjust the input positions to the reduced Delaunay cell (possibly trimming it, reducing the number of atoms)
    let positionInDelaunayCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = SKSymmetryCell.trim(atoms: atoms, from: unitCell, to: DelaunayUnitCell)
    let reducedPositionsInDelaunayCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = positionInDelaunayCell.filter{$0.type == minType}
    
    // find the rotational and translational symmetries for the atoms in the reduced Delaunay cell (based on the symmetries of the lattice, omtting the ones that are not compatible)
    // the point group of the lattice cannot be lower than the point group of the crystal
    let spaceGroupSymmetries: SKSymmetryOperationSet = SKSpacegroup.findSpaceGroupSymmetry(unitCell: DelaunayUnitCell, reducedAtoms: reducedPositionsInDelaunayCell, atoms: positionInDelaunayCell, latticeSymmetries: latticeSymmetries, symmetryPrecision: symmetryPrecision)
        
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
        let computedDelaunayReducedCell2D: double3x3? = SKSymmetryCell.computeDelaunayReducedCell2D(unitCell: DelaunayUnitCell * Mprime, uniqueAxis: 1)
        if computedDelaunayReducedCell2D == nil
        {
          return nil
        }
        Mprime = SKTransformationMatrix(DelaunayUnitCell.inverse * computedDelaunayReducedCell2D!)
      default:
        break
      }
      
      return Mprime
      
    }
    return nil
  }
  
  public static func SKTestBasisCorrection(unitCell: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], symmetryPrecision: Double = 1e-5) -> SKTransformationMatrix?
  {
    var histogram:[Int:Int] = [:]
    
    for atom in atoms
    {
      histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
    }
    
    // Find least occurent element
    let minType: Int = histogram.min{a, b in a.value < b.value}!.key
    
    let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = atoms.filter{$0.type == minType}
    
    // search for a primitive cell based on the positions of the atoms
    let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: atoms, unitCell: unitCell, symmetryPrecision: symmetryPrecision)
  
    // convert the unit cell to a reduced Delaunay cell
    guard let DelaunayUnitCell: double3x3 = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: symmetryPrecision) else {return nil}
    
    // find the rotational symmetry of the reduced Delaunay cell
    let latticeSymmetries: SKPointSymmetrySet = SKRotationMatrix.findLatticeSymmetry(primitiveUnitCell: primitiveUnitCell, unitCell: DelaunayUnitCell, symmetryPrecision: symmetryPrecision)
    
    // adjust the input positions to the reduced Delaunay cell (possibly trimming it, reducing the number of atoms)
    let positionInDelaunayCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = SKSymmetryCell.trim(atoms: atoms, from: unitCell, to: DelaunayUnitCell)
    let reducedPositionsInDelaunayCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = positionInDelaunayCell.filter{$0.type == minType}
    
    // find the rotational and translational symmetries for the atoms in the reduced Delaunay cell (based on the symmetries of the lattice, omtting the ones that are not compatible)
    // the point group of the lattice cannot be lower than the point group of the crystal
    let spaceGroupSymmetries: SKSymmetryOperationSet = SKSpacegroup.findSpaceGroupSymmetry(unitCell: DelaunayUnitCell, reducedAtoms: reducedPositionsInDelaunayCell, atoms: positionInDelaunayCell, latticeSymmetries: latticeSymmetries, symmetryPrecision: symmetryPrecision)
        
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
        let computedDelaunayReducedCell2D: double3x3? = SKSymmetryCell.computeDelaunayReducedCell2D(unitCell: DelaunayUnitCell * Mprime, uniqueAxis: 1)
        if computedDelaunayReducedCell2D == nil
        {
          return nil
        }
        Mprime = SKTransformationMatrix(DelaunayUnitCell.inverse * computedDelaunayReducedCell2D!)
      default:
        break
      }
      
      var centering: SKSpacegroup.Centring = pointGroup.computeCentering(of: Mprime)
      let corrrectedMprime: SKTransformationMatrix = pointGroup.computeBasisCorrection(of: Mprime, withCentering: &centering)
      return corrrectedMprime
    }
    return nil
  }
  
  public static func SKFindSpaceGroupCentering(unitCell: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], symmetryPrecision: Double = 1e-5) -> SKSpacegroup.Centring?
  {
    var histogram:[Int:Int] = [:]
    
    for atom in atoms
    {
      histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
    }
    
    // Find least occurent element
    let minType: Int = histogram.min{a, b in a.value < b.value}!.key
    
    let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = atoms.filter{$0.type == minType}
    
    // search for a primitive cell based on the positions of the atoms
    let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: atoms, unitCell: unitCell, symmetryPrecision: symmetryPrecision)
  
    // convert the unit cell to a reduced Delaunay cell
    guard let DelaunayUnitCell: double3x3 = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: symmetryPrecision) else {return nil}
    
    // find the rotational symmetry of the reduced Delaunay cell
    let latticeSymmetries: SKPointSymmetrySet = SKRotationMatrix.findLatticeSymmetry(primitiveUnitCell: primitiveUnitCell, unitCell: DelaunayUnitCell, symmetryPrecision: symmetryPrecision)
    
    // adjust the input positions to the reduced Delaunay cell (possibly trimming it, reducing the number of atoms)
    let positionInDelaunayCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = SKSymmetryCell.trim(atoms: atoms, from: unitCell, to: DelaunayUnitCell)
    let reducedPositionsInDelaunayCell: [(fractionalPosition: SIMD3<Double>, type: Int)] = positionInDelaunayCell.filter{$0.type == minType}
    
    // find the rotational and translational symmetries for the atoms in the reduced Delaunay cell (based on the symmetries of the lattice, omtting the ones that are not compatible)
    // the point group of the lattice cannot be lower than the point group of the crystal
    let spaceGroupSymmetries: SKSymmetryOperationSet = SKSpacegroup.findSpaceGroupSymmetry(unitCell: DelaunayUnitCell, reducedAtoms: reducedPositionsInDelaunayCell, atoms: positionInDelaunayCell, latticeSymmetries: latticeSymmetries, symmetryPrecision: symmetryPrecision)
        
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
        let computedDelaunayReducedCell2D: double3x3? = SKSymmetryCell.computeDelaunayReducedCell2D(unitCell: DelaunayUnitCell * Mprime, uniqueAxis: 1)
        if computedDelaunayReducedCell2D == nil
        {
          return nil
        }
        Mprime = SKTransformationMatrix(DelaunayUnitCell.inverse * computedDelaunayReducedCell2D!)
      default:
        break
      }
      
      var centering: SKSpacegroup.Centring = pointGroup.computeCentering(of: Mprime)
      let M: SKTransformationMatrix = pointGroup.computeBasisCorrection(of: Mprime, withCentering: &centering)
      return centering
    }
    return nil
  }
  
  
  
  /// Find the symmetry elements of the atomic configuration
  ///
  /// - parameter fractionalPositions: the fractional positions of the atoms
  /// - parameter latticeSymmetries: the symmetry elements of the lattice
  /// - parameter symmetryPrecision: the precision of the search (default: 1e-5)
  ///
  /// - returns: the symmetry operations, i.e. a list of (integer rotation matrix, translation vector)
  public static func findSpaceGroupSymmetry(unitCell: double3x3, reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)], atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], latticeSymmetries: SKPointSymmetrySet, symmetryPrecision: Double = 1e-4) -> SKSymmetryOperationSet
  {
    var spaceGroupSymmetries: [SKSeitzMatrix] = []
    
    for rotationMatrix in latticeSymmetries.rotations
    {
      
      let translations: [SIMD3<Double>] = SKSymmetryCell.primitiveTranslationVectors(unitCell: unitCell, reducedAtoms: reducedAtoms, atoms: atoms, rotationMatrix: rotationMatrix, symmetryPrecision: symmetryPrecision)
     
      for translation in translations
      {
        spaceGroupSymmetries.append(SKSeitzMatrix(rotation: rotationMatrix, translation: translation))
      }
    }
    return SKSymmetryOperationSet(operations: spaceGroupSymmetries)
  }
  
  
  
  public static func getOriginShift(HallNumber: Int, centering: SKSpacegroup.Centring, changeOfBasis: SKRotationalChangeOfBasis, seitzMatrices: [SKSeitzMatrix], symmetryPrecision: Double = 1e-5) throws -> SIMD3<Double>?
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
      
      let translationDifference: SIMD3<Double> = fract(transPrimitive - SIMD3<Double>(dataBaseTranslation) / 12.0)
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
  
    
  public static func matchSpaceGroup(HallNumber: Int, lattice: double3x3, pointGroupNumber: Int,centering: SKSpacegroup.Centring, seitzMatrices: [SKSeitzMatrix], symmetryPrecision: Double = 1e-5)  -> (origin: SIMD3<Double>, changeOfBasis: SKRotationalChangeOfBasis)?
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
          solutions.append((originShift, changeOfMonoclinicCentering))
        }
      }
      return solutions.first
      
      /*
      for solution in solutions
      {
        let conventionalBravaisLattice: double3x3 = lattice * solution.1.inverseRotationMatrix
        let cell: SKSymmetryCell = SKSymmetryCell(unitCell: conventionalBravaisLattice)
        print("lattice a b c alpha beta gamma: ", conventionalBravaisLattice, cell.a, cell.b, cell.c,  cell.alpha * 180.0 / Double.pi, cell.beta  * 180.0 / Double.pi , cell.gamma * 180.0 / Double.pi)
        
        print("cell: ", cell.unitCell)
      }
      print("hall ", HallNumber, solutions.count)
      return solutions.sorted(by: { a, b in
        let conventionalBravaisLatticeA: double3x3 = lattice * a.1.inverseRotationMatrix
        let cellA: SKSymmetryCell = SKSymmetryCell(unitCell: conventionalBravaisLatticeA)
        let conventionalBravaisLatticeB: double3x3 = lattice * b.1.inverseRotationMatrix
        let cellB: SKSymmetryCell = SKSymmetryCell(unitCell: conventionalBravaisLatticeB)
        return cellA.beta < cellB.beta
      }).first
 */
    case .orthorhombic:
      for changeOfOrthorhombicCentering in SKRotationalChangeOfBasis.changeOfOrthorhombicCentering
      {
        if let originShift: SIMD3<Double> = try? getOriginShift(HallNumber: HallNumber, centering: centering, changeOfBasis: changeOfOrthorhombicCentering, seitzMatrices: seitzMatrices, symmetryPrecision: symmetryPrecision)
        {
          return (originShift, changeOfOrthorhombicCentering)
        }
      }
    case .cubic:
      if let originShift: SIMD3<Double> = try? getOriginShift(HallNumber: HallNumber, centering: centering, changeOfBasis: SKRotationalChangeOfBasis(rotation: SKRotationMatrix.identity), seitzMatrices: seitzMatrices, symmetryPrecision: symmetryPrecision)
      {
        return (originShift, SKRotationalChangeOfBasis.identity)
      }
    }
    
    return nil
  }
  


  
  public static func isInsideAsymmetricUnitCell(number: Int, point: SIMD3<Double>, precision eps: Double = 1e-8) -> Bool
  {
    let p: SIMD3<Double> = fract(point)
    
    switch(number)
    {
      // TRICLINIC GROUPS
      // ================
      
    case 1:   // [1] P 1 (P 1)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    //isInRange(p.x,0.0,1.0+eps) && isInRange(p.y,0.0,1.0+eps) && isInRange(p.z,0.0,1.0+eps)
    case 2:   // [2] P -1 (-P 1)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
      
      // MONOCLINIC GROUPS
      // =================
      
    case 3: // [3] P 1 2 1 unique b axis (P 2y)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 4: // [3] P 1 1 2 unique c axis (P 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 5: // [3] P 2 1 1 unique a axis (P 2x)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 6: // [4] P 1 21 1 unique b axis (P 2yb)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 7: // [4] P 1 1 21 unique c axis (P 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 8: // [4] P 21 1 1 unique a axis (P 2xa)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 9:  // [5] C 1 2 1 unique b axis: cell choice 1 (C 2y)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 10: // [5] A 1 2 1 unique b axis: cell choice 2 (A 2y)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 11: // [5] I 1 2 1 unique b axis: cell choice 3 (I 2y)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 12: // [5] A 1 1 2 unique c axis: cell choice 1 (A 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 13: // [5] B 1 1 2 unique c axis: cell choice 2 (B 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 14: // [5] I 1 1 2 unique c axis: cell choice 3 (I 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 15: // [5] B 2 1 1 unique a axis: cell choice 1 (B 2x)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 16: // [5] C 2 1 1 unique a axis: cell choice 2 (C 2x)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 17: // [5] I 2 1 1 unique a axis: cell choice 3 (I 2x)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 18: // [6] P 1 m 1 unique b axis (P -2y)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 19: // [6] P 1 1 m unique c axis (P -2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 20: // [6] P m 1 1 unique a axis (P -2x)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 21: // [7] P 1 c 1 unique b axis: cell choice 1 (P -2yc)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 22: // [7] P 1 n 1 unique b axis: cell choice 2 (P -2yac)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 23: // [7] P 1 a 1 unique b axis: cell choice 3 (P -2ya)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 24: // [7] P 1 1 a unique c axis: cell choice 1 (P -2a)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 25: // [7] P 1 1 n unique c axis: cell choice 2 (P -2ab)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 26: // [7] P 1 1 b unique c axis: cell choice 3 (P -2b)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 27: // [7] P b 1 1 unique a axis: cell choice 1 (P -2xb)
      return (0.0...1.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 28: // [7] P n 1 1 unique a axis: cell choice 2 (P -2xbc)
      return (0.0...1.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 29: // [7] P c 1 1 unique a axis: cell choice 3 (P -2xc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 30: // [8] C 1 m 1 unique b axis: cell choice 1 (C -2y)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 31: // [8] A 1 m 1 unique b axis: cell choice 2 (A -2y)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 32: // [8] I 1 m 1 unique b axis: cell choice 3 (I -2y)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 33: // [8] A 1 1 m unique c axis: cell choice 1 (A -2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 34: // [8] B 1 1 m  unique c axis: cell choice 2 (B -2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 35: // [8] I 1 1 m unique c axis: cell choice 3 (I -2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 36: // [8] B m 1 1 unique a axis: cell choice 1 (B -2x)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 37: // [8] C m 1 1 unique a axis: cell choice 2 (C -2x)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<(1.0/2.0+eps)).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 38: // [8] I m 1 1 unique a axis: cell choice 3 (I -2x)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<(1.0/2.0+eps)).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 39: // [9] C 1 c 1 unique b axis: cell choice 1 (C -2yc)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 40: // [9] A 1 n 1 unique b axis: cell choice 2 (A -2yab)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 41: // [9] I 1 a 1 unique b axis: cell choice 3 (I -2ya)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 42: // [9] A 1 a 1 unique -b axis: cell choice 1 (A -2ya)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 43: // [9] C 1 n 1 unique -b axis: cell choice 2 (C -2yac)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 44: // [9] I 1 c 1 unique -b axis: cell choice 3 (I -2yc)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 45: // [9] A 1 1 a unique c axis: cell choice 1 (A -2a)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 46: // [9] B 1 1 n unique c axis: cell choice 2 (B -2ab)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 47: // [9] I 1 1 b unique c axis: cell choice 3 (I -2b)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 48: // [9] B 1 1 b unique -c axis: cell choice 1 (B -2b)
      return (0.0..<(1.0/2.0+eps)).contains(p.x) && (0.0..<(1.0/2.0+eps)).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 49: // [9] A 1 1 n unique -c axis: cell choice 2 (A -2ab)
      return (0.0..<(1.0/2.0+eps)).contains(p.x) && (0.0..<(1.0/2.0+eps)).contains(p.y) && (0.0...(1.0+eps)).contains(p.z)
    case 50: // [9] I 1 1 a unique -c axis: cell choice 3 (I -2a)
      return (0.0..<(1.0/2.0+eps)).contains(p.x) && (0.0..<(1.0/2.0+eps)).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 51: // [9] B b 1 1 unique a axis: cell choice 1 (B -2xb)
      return (0.0..<(1.0/2.0+eps)).contains(p.x) && (0.0..<(1.0/2.0+eps)).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 52: // [9] C n 1 1 unique a axis: cell choice 2 (C -2xac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 53: // [9] I c 1 1 unique a axis: cell choice 3 (I -2xc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<(1.0/2.0+eps)).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 54: // [9] C c 1 1 unique -a axis: cell choice 1 (C -2xc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<(1.0/2.0+eps)).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 55: // [9] B n 1 1 unique -a axis: cell choice 2 (B -2xab)
      return (0.0..<(1.0/2.0+eps)).contains(p.x) && (0.0..<(1.0/2.0+eps)).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 56: // [9] I b 1 1 unique -a axis: cell choice 3 (I -2xb)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 57: // [10] P 1 2/m 1 unique b axis (-P 2y)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 58: // [10] P 1 1 2/m unique c axis (-P 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 59: // [10] P 2/m 1 1 unique a axis (-P 2x)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 60: // [11] P 1 21/m 1 unique axis b (-P 2yb)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 61: // [11] P 1 1 21/m unique c axis (-P 2c)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 62: // [11] P 21/m 1 1 unique a axis (-P 2xa)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 63: // [12] C 1 2/m 1 unique b axis: cell choice 1 (-C 2y)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 64: // [12] A 1 2/m 1 unique b axis: cell choice 2 (-A 2y)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 65: // [12] I 1 2/m 1 unique b axis: cell choice 3 (-I 2y)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 66: // [12] A 1 1 2/m unique c axis: cell choice 1 (-A 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 67: // [12] B 1 1 2/m unique c axis: cell choice 2 (-B 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 68: // [12] I 1 1 2/m unique c axis: cell choice 3 (-I 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 69: // [12] B 2/m 1 1 unique a axis: cell choice 1 (-B 2x)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 70: // [12] C 2/m 1 1 unique a axis: cell choice 2 (-C 2x)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 71: // [12] I 2/m 1 1 unique a axis: cell choice 3 (-I 2x)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 72: // [13] P 1 2/c 1 unique b axis: cell choice 1 (-P 2yc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 73: // [13] P 1 2/n 1 unique b axis: cell choice 2 (-P 2yac)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 74: // [13] P 1 2/a 1 unique b axis: cell choice 3 (-P 2ya)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 75: // [13] P 1 1 2/a unique c axis: cell choice 1 (-P 2a)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 76: // [13] P 1 1 2/n unique c axis: cell choice 2 (-P 2ab)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 77: // [13] P 1 1 2/b unique c axis: cell choice 3 (-P 2b)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 78: // [13] P 2/b 1 1 unique a axis: cell choice 1 (-P 2xb)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 79: // [13] P 2/n 1 1 unique a axis: cell choice 2 (-P 2xbc)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 80: // [13] P 2/c 1 1 unique a axis: cell choice 3 (-P 2xc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 81: // [14] P 1 21/c 1 unique b axis: cell choice 1 (-P 2ybc)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 82: // [14] P 1 21/n 1 unique b axis: cell choice 2 (-P 2yn)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 83: // [14] P 1 21/a 1 unique b axis: cell choice 3 (-P 2yab)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 84: // [14] P 1 1 21/a unique c axis: cell choice 1 (-P 2ac)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 85: // [14] P 1 1 21/n unique c axis: cell choice 2 (-P 2n)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 86: // [14] P 1 1 21/b unique c axis: cell choice 3 (-P 2bc)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 87: // [14] P 21/b 1 1 unique a axis: cell choice 1 (-P 2xab)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 88: // [14] P 21/n 1 1 unique a axis: cell choice 2 (-P 2xn)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 89: // [14] P 21/c 1 1 unique a axis: cell choice 3 (-P 2xac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 90: // [15] C 1 2/c 1 unique b axis: cell choice 1 (-C 2yc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 91: // [15] A 1 2/n 1 unique b axis: cell choice 2 (-A 2yab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 92: // [15] I 1 2/a 1 unique b axis: cell choice 3 (-I 2ya)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 93: // [15] A 1 2/a 1 unique -b axis: cell choice 1 (-A 2ya)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 94: // [15] C 1 2/n 1 unique -b axis: cell choice 2 (-C 2yac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (1.0/4.0...3.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 95: // [15] I 1 2/c 1 unique -b axis: cell choice 3 (-I 2yc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 96: // [15] A 1 1 2/a unique c axis: cell choice 1 (-A 2a)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 97: // [15] B 1 1 2/n unique c axis: cell choice 2 (-B 2ab)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 98: // [15] I 1 1 2/b unique c axis: cell choice 3 (-I 2b)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 99: // [15] B 1 1 2/b unique -c axis: cell choice 1 (-B 2b)
      return (0.0..<(1.0/2.0+eps)).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 100: // [15] A 1 1 2/n unique -c axis: cell choice 2 (-A 2ab)
      return (0.0..<(1.0/2.0+eps)).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 101: // [15] I 1 1 2/a unique -c axis: cell choice 3 (-I 2a)
      return (0.0..<(1.0/2.0+eps)).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 102: // [15] B 2/b 1 1 unique a axis: cell choice 1 (-B 2xb)
      return (0.0..<(1.0/2.0+eps)).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 103: // [15] C 2/n 1 1 unique a axis: cell choice 2 (-C 2xac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (1.0/4.0...3.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 104: // [15] I 2/c 1 1 unique a axis: cell choice 3 (-I 2xc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 105: // [15] C 2/c 1 1 unique -a axis: cell choice 1 (-C 2xc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 106: // [15] B 2/n 1 1 unique -a axis: cell choice 2 (-B 2xab)
      return (0.0..<(1.0/2.0+eps)).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 107: // [15] I 2/b 1 1 unique -a axis: cell choice 3 (-I 2xb)
      return (1.0/4.0...3.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
      
      
      
    // ORTHORHOMBIC GROUPS
    // ===================
      
    case 108: // [16] P 2 2 2 (P 2 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 109: // [17] P 2 2 21 Origin-1,abc (P 2c 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 110: // [17] P 21 2 2 Origin-1,cab (P 2a 2a)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 111: // [17] P 2 21 2 Origin-1,bca (P 2 2b)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 112: // [18] P 21 21 2 Origin-1,abc (P 2 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 113: // [18] P 2 21 21 Origin-1,cab (P 2bc 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 114: // [18] P 21 2 21 Origin-1,bca (P 2ac 2ac)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 115: // [19] P 21 21 21 (P 2ac 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 116: // [20] C 2 2 21  Origin-1,abc (C 2c 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 117: // [20] A 21 2 2  Origin-1,cba (A 2a 2a)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 118: // [20] B 2 21 2  Origin-1,bca (B 2 2b)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 119: // [21] C 2 2 2 Origin-1,abc (C 2 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 120: // [21] A 2 2 2 Origin-1,cab (A 2 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 121: // [21] B 2 2 2 Origin-1,bca (B 2 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 122: // [22] F 2 2 2 (F 2 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 123: // [23] I 2 2 2 (I 2 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 124: // [24] I 21 21 21 (I 2b 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 125: // [25] P m m 2 (P 2 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 126: // [25] P 2 m m (P -2 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 127: // [25] P m 2 m (P -2 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 128: // [26] P m c 21 (P 2c -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 129: // [26] P c m 21 (P 2c -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 130: // [26] P 21 m a (P -2a 2a)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 131: // [26] P 21 a m (P -2 2a)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 132: // [26] P b 21 m (P -2 -2b)
      return (0.0...1.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 133: // [26] P m 21 b (P -2b -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 134: // [27] P c c 2 (P 2 -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 135: // [27] P 2 a a (P -2a 2)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 136: // [27] P b 2 b (P -2b -2b)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 137: // [28] P m a 2 (P 2 -2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 138: // [28] P b m 2 (P 2 -2b)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 139: // [28] P 2 m b (P -2b 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 140: // [28] P 2 c m (P -2c 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 141: // [28] P c 2 m (P -2c -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 142: // [28] P m 2 a (P -2a -2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 143: // [29] P c a 21 (P 2c -2ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 144: // [29] P b c 21 (P 2c -2b)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 145: // [29] P 21 a b (P -2b 2a)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 146: // [29] P 21 c a (P -2ac 2a)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 147: // [29] P c 21 b (P -2bc -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 148: // [29] P b 21 a (P -2a -2ab)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 149: // [30] P n c 2 (P 2 -2bc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 150: // [30] P c n 2 (P 2 -2ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 151: // [30] P 2 n a (P -2ac 2)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 152: // [30] P 2 a n (P -2ab 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 153: // [30] P b 2 n (P -2ab -2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 154: // [30] P n 2 b (P -2bc -2bc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 155: // [31] P m n 21 (P 2ac -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 156: // [31] P n m 21 (P 2bc -2bc)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 157: // [31] P 21 m n (P -2ab 2ab)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 158: // [31] P 21 n m (P -2 2ac)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 159: // [31] P n 21 m (P -2 -2bc)
      return (0.0...1.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 160: // [31] P m 21 n (P -2ab -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 161: // [32] P b a 2 (P 2 -2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 162: // [32] P 2 c b (P -2bc 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 163: // [32] P c 2 a (P -2ac -2ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 164: // [33] P n a 21 (P 2c -2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 165: // [33] P b n 21 (P 2c -2ab)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 166: // [33] P 21 n b (P -2bc 2a)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 167: // [33] P 21 c n (P -2n 2a)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 168: // [33] P c 21 n (P -2n -2ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 169: // [33] P n 21 a (P -2ac -2n)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 170: // [34] P n n 2 (P 2 -2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 171: // [34] P 2 n n (P -2n 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 172: // [34] P n 2 n (P -2n -2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 173: // [35] C m m 2 (C 2 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 174: // [35] A 2 m m (A -2 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 175: // [35] B m 2 m (B -2 -2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 176: // [36] C m c 21 (C 2c -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 177: // [36] C c m 21 (C 2c -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 178: // [36] A 21 m a (A -2a 2a)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 179: // [36] A 21 a m (A -2 2a)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 180: // [36] B b 21 m (B -2 -2b)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 181: // [36] B m 21 b (B -2b -2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 182: // [37] C c c 2 (C 2 -2c)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 183: // [37] A 2 a a (A -2a 2)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 184: // [37] B b 2 b (B -2b -2b)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 185: // [38] A m m 2 (A 2 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 186: // [38] B m m 2 (B 2 -2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 187: // [38] B 2 m m (B -2 2)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 188: // [38] C 2 m m (C -2 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 189: // [38] C m 2 m (C -2 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 190: // [38] A m 2 m (A -2 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 191: // [39] A b m 2 (A 2 -2b)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 192: // [39] B m a 2 (B 2 -2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 193: // [39] B 2 c m (B -2a 2)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 194: // [39] C 2 m b (C -2a 2)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.x)
    case 195: // [39] C m 2 a (C -2a -2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 196: // [39] A c 2 m (A -2b -2b)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 197: // [40] A m a 2 (A 2 -2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 198: // [40] B b m 2 (B 2 -2b)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 199: // [40] B 2 m b (B -2b 2)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 200: // [40] C 2 c m (C -2c 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 201: // [40] C c 2 m (C -2c -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 202: // [40] A m 2 a (A -2a -2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 203: // [41] A b a 2 (A 2 -2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 204: // [41] B b a 2 (B 2 -2ab)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 205: // [41] B 2 c b (B -2ab 2)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 206: // [41] C 2 c b (C -2ac 2)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 207: // [41] C c 2 a (C -2ac -2ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 208: // [41] A c 2 a (A -2ab -2ab)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 209: // [42] F m m 2 (F 2 -2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 210: // [42] F 2 m m (F -2 2)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 211: // [42] F m 2 m (F -2 -2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 212: // [43] F d d 2 (F 2 -2d)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 213: // [43] F 2 d d (F -2d 2)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/8.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 214: // [43] F d 2 d (F -2d -2d)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 215: // [44] I m m 2 (I 2 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 216: // [44] I 2 m m (I -2 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 217: // [44] I m 2 m (I -2 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 218: // [45] I b a 2 (I 2 -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 219: // [45] I 2 c b (I -2a 2)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 220: // [45] I c 2 a (I -2b -2b)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 221: // [46] I m a 2 (I 2 -2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 222: // [46] I b m 2 (I 2 -2b)
      return (0.0...1.0/4.0+eps).contains(p.x) && (1.0/4.0...3.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 223: // [46] I 2 m b (I -2b 2)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 224: // [46] I 2 c m (I -2c 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 225: // [46] I c 2 m (I -2c -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.x) && (1.0/4.0...3.0/4.0+eps).contains(p.x)
    case 226: // [46] I m 2 a (I -2a -2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 227: // [47] P m m m (-P 2 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 228: // [48] P n n n Origin choice 1 (P 2 2 -1n)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 229: // [48] P n n n Origin choice 2 (-P 2ab 2bc)
      return (0.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 230: // [49] P c c m  (-P 2 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 231: // [49] P m a a (-P 2a 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 232: // [49] P b m b (-P 2b 2b)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 233: // [50] P b a n Origin choice 1 (P 2 2 -1ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 234: // [50] P b a n Origin choice 2 (-P 2ab 2b)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 235: // [50] P n c b Origin choice 1 (P 2 2 -1bc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 236: // [50] P n c b Origin choice 2 (-P 2b 2bc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 237: // [50] P c n a Origin choice 1 (P 2 2 -1ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 238: // [50] P c n a Origin choice 2 (-P 2a 2c)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 239: // [51] P m m a (-P 2a 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 240: // [51] P m m b (-P 2b 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 241: // [51] P b m m (-P 2 2b)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 242: // [51] P c m m (-P 2c 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 243: // [51] P m c m (-P 2c 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 244: // [51] P m a m (-P 2 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 245: // [52] P n n a (-P 2a 2bc)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 246: // [52] P n n b (-P 2b 2n)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 247: // [52] P b n n (-P 2n 2b)
      return (0.0...1.0/4.0+eps).contains(p.x) && (1.0/4.0...3.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 248: // [52] P c n n (-P 2ab 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 249: // [52] P n c n (-P 2ab 2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 250: // [52] P n a n (-P 2n 2bc)
      return (0.0...1.0/4.0+eps).contains(p.x) && (1.0/4.0...3.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 251: // [53] P m n a (-P 2ac 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 252: // [53] Pnmb (-P 2bc 2bc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 253: // [53] P b m n (-P 2ab 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 254: // [53] P c n m (-P 2 2ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 255: // [53] P n c m (-P 2 2bc)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 256: // [53] P m a n (-P 2ab 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 257: // [54] P c c a (-P 2a 2ac)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 258: // [54] P c c b (-P 2b 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 259: // [54] P b a a (-P 2a 2b)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 260: // [54] P c a a (-P 2ac 2c)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 261: // [54] P b c b (-P 2bc 2b)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 262: // [54] P b a b (-P 2b 2ab)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 263: // [55] P b a m (-P 2 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 264: // [55] P m c b (-P 2bc 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 265: // [55] P c m a (-P 2ac 2ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 266: // [56] P c c n (-P 2ab 2ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 267: // [56] P n a a (-P 2ac 2bc)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 268: // [56] P b n b (-P 2bc 2ab)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 269: // [57] P b c m (-P 2c 2b)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 270: // [57] P c a m (-P 2c 2ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 271: // [57] P m c a (-P 2ac 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 272: // [57] P m a b (-P 2b 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 273: // [57] P b m a (-P 2a 2ab)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 274: // [57] P c m b (-P 2bc 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 275: // [58] P n n m (-P 2 2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 276: // [58] P m n n (-P 2n 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 277: // [58] P n m n (-P 2n 2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 278: // [59] P m m n Origin choice 1 (P 2 2ab -1ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 279: // [59] P m m n Origin choice 2 (-P 2ab 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.x)
    case 280: // [59] P n m m Origin choice 1 (P 2bc 2 -1bc)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 281: // [59] P n m m Origin choice 2 (-P 2c 2bc)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 282: // [59] P m n m Origin choice 1 (P 2ac 2ac -1ac)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 283: // [59] P m n m Origin choice 2 (-P 2c 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 284: // [60] P b c n (-P 2n 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 285: // [60] P c a n (-P 2n 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 286: // [60] P n c a (-P 2a 2n)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 287: // [60] P n a b (-P 2bc 2n)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 288: // [60] P b n a (-P 2ac 2b)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 289: // [60] P c n b (-P 2b 2ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 290: // [61] P b c a (-P 2ac 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 291: // [61] P c a b (-P 2bc 2ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 292: // [62] P n m a (-P 2ac 2n)      zeolites: MFI
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 293: // [62] P m n b (-P 2bc 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 294: // [62] P b n m (-P 2c 2ab)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 295: // [62] P c m n (-P 2n 2ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (1.0/4.0...3.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 296: // [62] P m c n (-P 2n 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (1.0/4.0...3.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 297: // [62] P n a m (-P 2c 2n)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 298: // [63] C m c m (-C 2c 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 299: // [63] C c m m (-C 2c 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 300: // [63] A m m a (-A 2a 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 301: // [63] A m a m (-A 2 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.z)
    case 302: // [63] B b m m (-B 2 2b)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 303: // [63] B m m b (-B 2b 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 304: // [64] C m c a (-C 2ac 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 305: // [64] C c m b (-C 2ac 2ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 306: // [64] A b m a (-A 2ab 2ab)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 307: // [64] A c a m (-A 2 2ab)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0..<1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 308: // [64] B b c m (-B 2 2ab)
      return (0.0..<1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 309: // [64] B m a b (-B 2ab 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 310: // [65] C m m m (-C 2 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 311: // [65] A m m m (-A 2 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 312: // [65] B m m m (-B 2 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 313: // [66] C c c m (-C 2 2c)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 314: // [66] A m a a (-A 2a 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 315: // [66] B b m b (-B 2b 2b)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 316: // [67] C m m a (-C 2a 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 317: // [67] C m m b (-C 2a 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 318: // [67] A b m m (-A 2b 2b)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 319: // [67] A c m m (-A 2 2b)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 320: // [67] B m c m (-B 2 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 321: // [67] B m a m (-B 2a 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 322: // [68] C c c a Origin choice 1 (C 2 2 -1ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 323: // [68] C c c a Origin choice 2 (-C 2a 2ac)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 324: // [68] C c c b Origin choice 1 (C 2 2 -1bc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 325: // [68] C c c b Origin choice 2 (-C 2b 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 326: // [68] A b a a Origin choice 1 (A 2 2 -1ac)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 327: // [68] A b a a Origin choice 2 (-A 2a 2b)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 328: // [68] A c a a Origin choice 1 (A 2 2 -1ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 329: // [68] A c a a Origin choice 2 (-A 2ab 2b)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 330: // [68] B b c b Origin choice 1 (B 2 2 -1ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 331: // [68] B b c b Origin choice 2 (-B 2ab 2b)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 332: // [68] B b a b Origin choice 1 (B 2 2 -1ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 333: // [68] B b a b Origin choice 2 (-B 2b 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 334: // [69] F m m m (-F 2 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 335: // [70] F d d d:1 Origin choice 1 (F 2 2 -1d)
      return (0.0...1.0/8.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 336: // [70] F d d d:2 Origin choice 2 (-F 2uv 2vw)
      return (0.0...1.0/8.0+eps).contains(p.x) && (-1.0/8.0...1.0/8.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 337: // [71] I m m m (-I 2 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 338: // [72] I b a m (-I 2 2c)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 339: // [72] I m c b (-I 2a 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 340: // [72] I c m a (-I 2b 2b)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 341: // [73] I b c a (-I 2b 2c)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 342: // [73] I c a b (-I 2a 2b)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 343: // [74] I m m a (-I 2b 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 344: // [74] I m m b (-I 2a 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 345: // [74] I b m m (-I 2c 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
    case 346: // [74] I c m m (-I 2 2b)
      return (0.0...1.0/4.0+eps).contains(p.x) && (1.0/4.0...3.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 347: // [74] I m c m (-I 2 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (1.0/4.0...3.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 348: // [74] I m a m (-I 2c 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z)
      
      // TETRAGONAL GROUPS
      // =================
      
    case 349: // [75] P 4 (P 4)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 350: // [76] P 41 (P 4w)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 351: // [77] P 42 (P 4c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 352: // [78] P 43 (P 4cw)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 353: // [79] I 4 (I 4)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 354: // [80] I 41 (I 4bw)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 355: // [81] P -4 (P -4)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 356: // [82] I -4 (I -4)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 357: // [83] P 4/m (-P 4)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 358: // [84] P 42/m (-P 4c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 359: // [85] P 4/n Origin choice 1 (P 4ab -1ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 360: // [85] P 4/n Origin choice 2 (-P 4a)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 361: // [86] P 42/n Origin choice 1 (P 4n -1n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 362: // [86] P 42/n Origin choice 2 (-P 4bc)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 363: // [87] I 4/m (-I 4)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 364: // [88] I 41/a Origin choice 1 (I 4bw -1bw)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 365: // [88] I 41/a Origin choice 2 (-I 4ad)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 366: // [89] P 4 2 2 (P 4 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 367: // [90] P 4 21 2 (P 4ab 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 368: // [91] P 41 2 2 (P 4w 2c)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 369: // [92] P 41 21 2 (P 4abw 2nw)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 370: // [93] P 42 2 2 (P 4c 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 371: // [94] P 42 21 2 (P 4n 2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 372: // [95] P 43 2 2 (P 4cw 2c)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 373: // [96] P 43 21 2 (P 4nw 2abw)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 374: // [97] I 4 2 2 (I 4 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 375: // [98] I 41 2 2 (I 4bw 2bw)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 376: // [99] P 4 m m (P 4 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 377: // [100] P 4 b m (P 4 -2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.y<=1.0/2.0-p.x+eps)
    case 378: // [101] P 42 c m (P 4c -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 379: // [102] P 42 n m (P 4n -2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 380: // [103] P 4 c c (P 4 -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 381: // [104] P 4 n c (P 4 -2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 382: // [105] P 42 m c (P 4c -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 383: // [106] P 42 b c (P 4c -2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 384: // [107] I 4 m m (I 4 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 385: // [108] I 4 c m (I 4 -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=1.0/2.0-p.x+eps)
    case 386: // [109] I 41 m d (I 4bw -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 387: // [110] I 41 c d (I 4bw -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.z)
    case 388: // [111] P -4 2 m (P -4 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 389: // [112] P -4 2 c (P -4 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 390: // [113] P -4 21 m (P -4 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.y<=1.0/2.0-p.x+eps)
    case 391: // [114] P -4 21 c (P -4 2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 392: // [115] P -4 m 2 (P -4 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 393: // [116] P -4 c 2 (P -4 -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 394: // [117] P -4 b 2 (P -4 -2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 395: // [118] P -4 n 2 (P -4 -2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 396: // [119] I -4 m 2 (I -4 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 397: // [120] I -4 c 2 (I -4 -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 398: // [121] I -4 2 m (I -4 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x <= p.y+eps)
    case 399: // [122] I -4 2 d (I -4 2bw)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 400: // [123] P 4/m m m (-P 4 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x <= p.y+eps)
    case 401: // [124] P 4/m c c (-P 4 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 402: // [125] P 4/n b m Origin choice 1 (P 4 2 -1ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y <= 1.0/2.0-p.x+eps)
    case 403: // [125] P 4/n b m Origin choice 2 (-P 4a 2b)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x <= -p.y+eps)
    case 404: // [126] P 4/n n c Origin choice 1 (P 4 2 -1n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 405: // [126] P 4/n n c Origin choice 2 (-P 4a 2bc)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 406: // [127] P 4/m b m (-P 4 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y <= 1.0/2.0-p.x+eps)
    case 407: // [128] P 4/m n c (-P 4 2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 408: // [129] P 4/n m m Origin choice 1 (P 4ab 2ab -1ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y <= 1.0/2.0-p.x+eps)
    case 409: // [129] P 4/n m m Origin choice 2 (-P 4a 2a)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 410: // [130] P 4/n c c Origin choice 1 (P 4ab 2n -1ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 411: // [130] P 4/n c c Origin choice 2 (-P 4a 2ac)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 412: // [131] P 42/m m c (-P 4c 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 413: // [132] P 42/m c m (-P 4c 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 414: // [133] P 42/n b c Origin choice 1 (P 4n 2c -1n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 415: // [133] P 42/n b c Origin choice 2 (-P 4ac 2b)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 416: // [134] P 42/n n m Origin choice 1 (P 4n 2 -1n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.x<=p.y+eps) && (p.y <= 1.0-p.x+eps)
    case 417: // [134] P 42/n n m Origin choice 2 (-P 4ac 2bc)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x <= -p.y+eps)
    case 418: // [135] P 42/m b c (-P 4c 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 419: // [136] P 42/m n m (-P 4n 2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x <= p.y+eps)
    case 420: // [137] P 42/n m c Origin choice 1 (P 4n 2n -1n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 421: // [137] P 42/n m c Origin choice 2 (-P 4ac 2a)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 422: // [138] P 42/n c m Origin choice 1 (P 4n 2ab -1n)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=p.y+eps) && (p.y<=1.0/2.0-p.x+eps)
    case 423: // [138] P 42/n c m Origin choice 2 (-P 4ac 2ac)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 424: // [139] I 4/m m m (-I 4 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 425: // [140] I 4/m c m (-I 4 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.y<=1.0/2.0-p.x+eps)
    case 426: // [141] I 41/a m d Origin choice 1 (I 4bw 2bw -1bw)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 427: // [141] I 41/a m d Origin choice 2 (-I 4bd 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 428: // [142] I 41/a c d Origin choice 1 (I 4bw 2aw -1bw)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 429: // [142] I 41/a c d Origin choice 2 (-I 4bd 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
      
      
      // TRIGONAL GROUPS
      // ===============
      
    case 430: // [143] P 3 (P 3)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 431: // [144] P 31 (P 31)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/3.0+eps).contains(p.z)
    case 432: // [145] P 32 (P 32)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/3.0+eps).contains(p.z)
    case 433: // [146] R 3 hexagonal axes (R 3)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/3.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 434: // [146] R 3 Rhombohedral axes (P 3*)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.z<=min(p.x,p.y)+eps)
    case 435: // [147] P -3 (P -3)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 436: // [148] R-3 hexagonal axes (-R 3)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 437: // [148] R -3 Rhombohedral axes (-P 3*)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.z<=min(p.x,p.y,1.0-p.x,1.0-p.y)+eps)
    case 438: // [149] P 3 1 2 (P 3 2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 439: // [150] P 3 2 1 (P 3 2")
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 440: // [151] P 31 1 2 (P 31 2 (0 0 4))
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z)
    case 441: // [152] P 31 2 1 (P 31 2")
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z)
    case 442: // [153] P 32 1 2 (P 32 2 (0 0 2))
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z)
    case 443: // [154] P 32 2 1 (P 32 2")
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z)
    case 444: // [155] R 3 2 Hexagonal axes (R 3 2")
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 445: // [155] R 3 2 Rhombohedral axes (P 3* 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.z<=min(p.x,p.y,1.0-p.x,1.0-p.y)+eps)
    case 446: // [156] P 3 m 1 (P 3 -2")
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=2.0*p.y+eps) && (p.y<=min(1.0-p.x,2.0*p.x)+eps)
    case 447: // [157] P 3 1 m (P 3 -2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=(p.y+1.0)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 448: // [158] P 3 c 1 (P 3 -2"c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 449: // [159] P 3 1 c (P 3 -2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 450: // [160] R 3 m Hexagonal axes (R 3 -2")
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/3.0+eps).contains(p.z) && (p.x<=2.0*p.y+eps) && (p.y<=min(1.0-p.x,2.0*p.x)+eps)
    case 451: // [160] R 3 m Rhombohedral axes (P 3* -2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=p.y+eps)
    case 452: // [161] R 3 c Hexagonal axes (R 3 -2"c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 453: // [161] R 3 c Rhombohedral axes (P 3* -2n)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=p.y+eps)
    case 454: // [162] P -3 1 m (-P 3 2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 455: // [163] P -3 1 c (-P 3 2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 456: // [164] P -3 m 1 (-P 3 2")
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/3.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=p.x/2.0+eps)
    case 457: // [165] P -3 c 1 (-P 3 2"c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 458: // [166] R -3 m Hexagonal axes (-R 3 2")  zeolites: CHA
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z) &&
        (p.x<=2.0*p.y+eps) && (p.y<=min(1.0-p.x,2.0*p.x)+eps)
    case 459: // [166] R -3 m Rhombohedral axes (-P 3* 2)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=min(p.y,1.0-p.x)+eps)
    case 460: // [167] R -3 c Hexagonal axes (-R 3 2"c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/12.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 461: // [167] R -3 c Rhombohedral axes (-P 3* 2n)
      return (1.0/4.0...5.0/4.0+eps).contains(p.x) && (1.0/4.0...5.0/4.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=min(p.y,3.0/2.0-p.x)+eps)
      
      
      // HEXAGONAL GROUPS
      // ================
      
    case 462: // [168] P 6 (P 6)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 463: // [169] P 61 (P 61)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z)
    case 464: // [170] P 65 (P 65)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z)
    case 465: // [171] P 62 (P 62)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/3.0+eps).contains(p.z) && (p.y<=p.x+eps)
    case 466: // [172] P 64 (P 64)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/3.0+eps).contains(p.z) && (p.y<=p.x+eps)
    case 467: // [173] P 63 (P 6c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 468: // [174] P -6 (P -6)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 469: // [175] P6/m (-P 6)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 470: // [176] P 63/m (-P 6c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0))
    case 471: // [177] P 6 2 2 (P 6 2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 472: // [178] P 61 2 2 (P 61 2 (0 0 5))
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/12.0+eps).contains(p.z)
    case 473: // [179] P 65 2 2 (P 65 2 (0 0 1))
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/12.0+eps).contains(p.z)
    case 474: // [180] P 62 2 2 (P 62 2 (0 0 4))
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z) && (p.y<=p.x+eps)
    case 475: // [181] P 64 2 2 (P 64 2 (0 0 2))
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z) && (p.y<=p.x+eps)
    case 476: // [182] P 63 2 2 (P 6c 2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 477: // [183] P 6 m m (P 6 -2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/3.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=p.x/2.0+eps)
    case 478: // [184] P 6 c c (P 6 -2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 479: // [185] P 63 c m (P 6c -2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 480: // [186] P 63 m c (P 6c -2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/3.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=p.x/2.0+eps)
    case 481: // [187] P -6 m 2 (P -6 2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=2.0*p.y+eps) && (p.y<=min(1.0-p.x,2.0*p.x)+eps)
    case 482: // [188] P -6 c 2 (P -6c 2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 483: // [189] P -6 2 m (P -6 -2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 484: // [190] P -6 2 c (P -6c -2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 485: // [191] P 6/m m m (-P 6 2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=p.x/2.0+eps)
    case 486: // [192] P 6/m c c (-P 6 2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 487: // [193] P 63/m c m (-P 6c 2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 488: // [194] P 63/m m c (-P 6c 2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=2.0*p.y+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
      
      // CUBIC GROUPS
      // ============
      
    case 489: // [195] P 2 3 (P 2 2 3)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=1.0-p.x+eps) && (p.z<=min(p.x,p.y)+eps)
    case 490: // [196] F 2 3 (F 2 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (-1.0/4.0...1.0/4.0+eps).contains(p.z) && (p.y<=p.x+eps) && (max(p.x-1.0/2.0,-p.y)...min(1.0/2.0-p.x,p.y)+eps).contains(p.z)
    case 491: // [197] I 2 3 (I 2 2 3)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=min(p.x,1.0-p.x)+eps) && (p.z<=p.y+eps)
    case 492: // [198] P 21 3 (P 2ac 2ab 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (-1.0/2.0...1.0/2.0+eps).contains(p.z) && (max(p.x-1.0/2.0,-p.y)...min(p.x,p.y)+eps).contains(p.z)
    case 493: // [199] I 21 3 (I 2b 2c 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.z<=min(p.x,p.y)+eps)
    case 494: // [200] P m -3 (-P 2 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.z<=min(p.x,p.y)+eps)
    case 495: // [201] P n -3 Origin choice 1 (P 2 2 3 -1n)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=min(p.x,1.0-p.x)+eps) && (p.z<=p.y+eps)
    case 496: // [201] P n -3 Origin choice 2 (-P 2ab 2bc 3)
      return (-1.0/4.0...3.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (-1.0/4.0...1.0/4.0+eps).contains(p.z) && (p.y<=min(p.x,1.0-p.x)+eps) && (p.z<=p.y+eps)
    case 497: // [202] F m -3 (-F 2 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=min(1.0/2.0-p.x,p.y)+eps)
    case 498: // [203] F d -3 Origin choice 1 (F 2 2 3 -1d)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (-1.0/4.0...1.0/4.0+eps).contains(p.z) && (p.y<=min(p.x,1.0/2.0-p.x)+eps) && (-p.y...p.y+eps).contains(p.z)
    case 499: // [203] F d -3 Origin choice 2 (-F 2uv 2vw 3)
      return (-1.0/8.0...3.0/8.0+eps).contains(p.x) && (-1.0/8.0...1.0/8.0+eps).contains(p.y) && (-3.0/8.0...1.0/8.0+eps).contains(p.z) && (p.y<=min(p.x,1.0/4.0-p.x)+eps) && (-p.y-1.0/4.0...p.y+eps).contains(p.z)
    case 500: // [204] I m -3 (-I 2 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=p.y+eps)
    case 501: // [205] P a -3 (-P 2ac 2ab 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.z<=min(p.x,p.y)+eps)
    case 502: // [206] I a -3 (-I 2b 2c 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.z<=min(p.x,1.0/2.0-p.x,1.0/2.0-p.y)+eps)
    case 503: // [207] P 4 3 2 (P 4 2 3)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=min(p.x,1.0-p.x)+eps) && (p.z<=p.y+eps)
    case 504: // [208] P 42 3 2 (P 4n 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (-1.0/4.0...1.0/4.0+eps).contains(p.z) && (max(-p.x,p.x-1.0/2.0,-p.y,p.y-1.0/2.0)...min(p.x,1.0/2.0-p.x,1.0/2.0-p.y)+eps).contains(p.z)
    case 505: // [209] F 4 3 2 (F 4 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (-1.0/4.0...1.0/4.0+eps).contains(p.z) && (p.y<=min(p.x,1.0/2.0-p.x)+eps) && (-p.y...p.y+eps).contains(p.z)
    case 506: // [210] F 41 3 2 (F 4d 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (-1.0/8.0...1.0/8.0+eps).contains(p.x) && (-1.0/8.0...1.0/8.0+eps).contains(p.x) && (p.y<=min(p.x,1.0/2.0-p.x)+eps) && (-p.y...min(p.x,1.0/2.0-p.x)+eps).contains(p.z)
    case 507: // [211] I 4 3 2 (I 4 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.z<=min(p.x,1.0/2.0-p.x,p.y,1.0/2.0-p.y)+eps)
    case 508: // [212] P 43 3 2 (P 4acd 2ab 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...3.0/4.0+eps).contains(p.y) && (-1.0/2.0...1.0/4.0+eps).contains(p.z) && (max(-p.y,p.x-1.0/2.0)...min(-p.y+1.0/2.0,2.0*p.x-p.y,2.0*p.y-p.x,p.y-2.0*p.x+1.0/2.0)+eps).contains(p.z)
    case 509: // [213] P 41 3 2 (P 4bd 2ab 3)
      return (-1.0/4.0...1.0/2.0+eps).contains(p.x) && (0.0...3.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x...p.x+1.0/2.0+eps).contains(p.y) && ((p.y-p.x)/2.0...min(p.y,(-4.0*p.x-2.0*p.y+3.0)/2.0,(3.0-2.0*p.x-2.0*p.y)/4.0)+eps).contains(p.z)
    case 510: // [214] I 41 3 2 (I 4bd 2c 3)
      return (-3.0/8...1.0/8.0+eps).contains(p.x) && (-1.0/8.0...1.0/8.0+eps).contains(p.y) && (-1.0/8.0...3.0/8.0+eps).contains(p.z) && (max(p.x,p.y,p.y-p.x-1.0/8.0)...p.y+1.0/4.0+eps).contains(p.z)
    case 511: // [215] P -4 3 m (P -4 2 3)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=min(p.x,1.0-p.x)+eps) && (p.z<=p.y+eps)
    case 512: // [216] F -4 3 m (F -4 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (-1.0/4.0...1.0/4.0+eps).contains(p.z) && (p.y<=min(p.x,1.0-p.x)+eps) && (-p.y...p.y+eps).contains(p.z)
    case 513: // [217] I -4 3 m (I -4 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=p.y+eps)
    case 514: // [218] P -4 3 n (P -4n 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.z<=min(p.x,p.y)+eps)
    case 515: // [219] F -4 3 c (F -4a 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (-1.0/4.0...1.0/4.0+eps).contains(p.z) && (p.y<=min(p.x,1.0/2.0-p.x)+eps) && (-p.y...p.y+eps).contains(p.z)
    case 516: // [220] I -4 3 d (I -4bd 2c 3)
      return (1.0/4.0...1.0/2.0+eps).contains(p.x) && (1.0/4.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.z<=min(p.x,p.y)+eps)
    case 517: // [221] P m -3 m (-P 4 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=p.y+eps)
    case 518: // [222] P n -3 n Origin choice 1 (P 4 2 3 -1n)
      return (1.0/4.0...3.0/4.0+eps).contains(p.x) && (1.0/4.0...3.0/4.0+eps).contains(p.y) && (1.0/4.0...3.0/4.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=p.y+eps)
    case 519: // [222] P n -3 n Origin choice 2 (-P 4a 2bc 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=p.y+eps)
    case 520: // [223] P m -3 n (-P 4n 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.z<=min(p.x,1.0/2.0-p.x,1.0/2.0-p.y)+eps)
    case 521: // [224] P n -3 m Origin choice 1 (P 4n 2 3 -1n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (-1.0/4.0...1.0/4.0+eps).contains(p.z) && (p.y<=p.x+eps) && (max(p.x-1.0/2.0,-p.y)...min(1.0/2.0-p.x,p.y)+eps).contains(p.z)
    case 522: // [224] P n -3 m Origin choice 2 (-P 4bc 2bc 3)
      return (1.0/4.0...3.0/4.0+eps).contains(p.x) && (1.0/4.0...3.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=p.x+eps) && (max(p.x-1.0/2.0,1.0/2.0-p.y)...min(p.y,1.0-p.x)+eps).contains(p.z)
    case 523: // [225] F m -3 m (-F 4 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.y<=min(p.x,1.0/2.0-p.x)+eps) && (p.z<=p.y+eps)
    case 524: // [226] F m -3 c (-F 4a 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.y<=min(p.x,1.0/2.0-p.x)+eps) && (p.z<=p.y+eps)
    case 525: // [227] F d -3 m Origin choice 1 (F 4d 2 3 -1d)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/8.0+eps).contains(p.y) && (-1.0/8.0...1.0/8.0+eps).contains(p.z) && (p.y<=min(1.0/2.0-p.x,p.x)+eps) && (-p.y...p.y+eps).contains(p.z)
    case 526: // [227] F d -3 m Origin choice 2 (-F 4vw 2vw 3)      e.g. FAU, MIL-100, 101
      var q = p
      if q.x>0.5 {q.x-=1.0}
      if q.y>0.5 {q.y-=1.0}
      if q.z>0.5 {q.z-=1.0}
      return (-1.0/8.0...3.0/8.0+eps).contains(q.x) && (-1.0/8.0...0.0+eps).contains(q.y)  && (-1.0/4.0...0.0+eps).contains(q.z)  && (q.y<=min(1.0/4.0-q.x,q.x)+eps) && (-q.y-1.0/4.0...q.y+eps).contains(q.z)
      
    case 527: // [228] F d -3 c Origin choice 1 (F 4d 2 3 -1ad)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/8.0+eps).contains(p.y) && (-1.0/8.0...1.0/8.0+eps).contains(p.z) && (p.y<=min(1.0/2.0-p.x,p.x)+eps) && (-p.y...p.y+eps).contains(p.z)
    case 528: // [228] F d -3 c Origin choice 2 (-F 4ud 2vw 3)
      return (-1.0/8.0...3.0/8.0+eps).contains(p.x) && (-1.0/8.0...0.0+eps).contains(p.y) && (-1.0/4.0...0.0+eps).contains(p.z) && (p.y<=min(1.0/4.0-p.x,p.x)+eps) && (-p.y-1.0/4.0...p.y+eps).contains(p.z)
    case 529: // [229] I m -3 m (-I 4 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=min(1.0/2.0-p.x,p.y)+eps)
    case 530: // [230] I a -3 d (-I 4bd 2c 3)
      return (-1.0/8.0...1.0/8.0+eps).contains(p.x) && (-1.0/8.0...1.0/8.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (max(p.x,-p.x,p.y,-p.y)<=p.z+eps)
    default:
      return false
    }
  }

}
