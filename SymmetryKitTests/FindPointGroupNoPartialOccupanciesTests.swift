//
//  FindPointGroupNoPartialOccupanciesTests.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 20/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

//
//  FindPointGroupTests.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 18/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
import simd
@testable import SymmetryKit

class FindPointGroupNoPartialOccupanciesTests: XCTestCase
{
  let precision: Double = 1e-5
  
  public static func SKTestPointGroup(unitCell: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)], allowPartialOccupancies: Bool, symmetryPrecision: Double = 1e-2) -> Int?
  {
    var histogram:[Int:Int] = [:]
    
    for atom in atoms
    {
      histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
    }
    
    // Find least occurent element
    let minType: Int = histogram.min{a, b in a.value < b.value}!.key
    
    let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)] = allowPartialOccupancies ? atoms : atoms.filter{$0.type == minType}
    
    // search for a primitive cell based on the positions of the atoms
    let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: atoms, unitCell: unitCell, allowPartialOccupancies: allowPartialOccupancies, symmetryPrecision: symmetryPrecision)
  
    // convert the unit cell to a reduced Delaunay cell
    guard let DelaunayUnitCell: double3x3 = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: symmetryPrecision) else {return nil}
    
    // find the rotational symmetry of the reduced Delaunay cell
    let latticeSymmetries: SKPointSymmetrySet = SKRotationMatrix.findLatticeSymmetry(unitCell: DelaunayUnitCell, symmetryPrecision: symmetryPrecision)
    
    // adjust the input positions to the reduced Delaunay cell (possibly trimming it, reducing the number of atoms)
    let positionInDelaunayCell: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)] = SKSymmetryCell.trim(atoms: atoms, from: unitCell, to: DelaunayUnitCell, allowPartialOccupancies: allowPartialOccupancies, symmetryPrecision: symmetryPrecision)
    let reducedPositionsInDelaunayCell: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)] = allowPartialOccupancies ? positionInDelaunayCell : positionInDelaunayCell.filter{$0.type == minType}
    
    // find the rotational and translational symmetries for the atoms in the reduced Delaunay cell (based on the symmetries of the lattice, omtting the ones that are not compatible)
    // the point group of the lattice cannot be lower than the point group of the crystal
    let spaceGroupSymmetries: SKSymmetryOperationSet = SKSpacegroup.findSpaceGroupSymmetry(unitCell: DelaunayUnitCell, reducedAtoms: reducedPositionsInDelaunayCell, atoms: positionInDelaunayCell, latticeSymmetries: latticeSymmetries, allowPartialOccupancies: allowPartialOccupancies, symmetryPrecision: symmetryPrecision)
    
    // create the point symmetry set
    let pointSymmetry: SKPointSymmetrySet = SKPointSymmetrySet(rotations: spaceGroupSymmetries.rotations)
    
    // get the point group from the point symmetry set
    return SKPointGroup(pointSymmetry: pointSymmetry)?.number
  }
  
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testFindTriclinicSpaceGroup()
  {
    let testData: [String: Int] =
      [
        "SpglibTestData/triclinic/POSCAR-001" : 1,
        "SpglibTestData/triclinic/POSCAR-002" : 2
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, reference) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type, 1.0)}
          
          let pointGroupNumber: Int? = FindPointGroupNoPartialOccupanciesTests.SKTestPointGroup(unitCell: unitCell, atoms: translatedAtoms, allowPartialOccupancies: false, symmetryPrecision: precision)
          XCTAssertNotNil(pointGroupNumber, "space group \(fileName) not found")
          if let pointGroupNumber = pointGroupNumber
          {
            XCTAssertEqual(pointGroupNumber, reference, "Wrong pointGroup found for \(fileName)")
          }
        }
      }
    }
  }
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testFindMonoclinicSpaceGroup()
  {
    let testData: [String: Int] =
      [
        "SpglibTestData/monoclinic/POSCAR-003" : 3,
        "SpglibTestData/monoclinic/POSCAR-004" : 3,
        "SpglibTestData/monoclinic/POSCAR-004-2" : 3,
        "SpglibTestData/monoclinic/POSCAR-005" : 3,
        "SpglibTestData/monoclinic/POSCAR-005-2" : 3,
        "SpglibTestData/monoclinic/POSCAR-006" : 4,
        "SpglibTestData/monoclinic/POSCAR-006-2" : 4,
        "SpglibTestData/monoclinic/POSCAR-007" : 4,
        "SpglibTestData/monoclinic/POSCAR-007-2" : 4,
        "SpglibTestData/monoclinic/POSCAR-008" : 4,
        "SpglibTestData/monoclinic/POSCAR-008-2" : 4,
        "SpglibTestData/monoclinic/POSCAR-009" : 4,
        "SpglibTestData/monoclinic/POSCAR-009-2" : 4,
        "SpglibTestData/monoclinic/POSCAR-010" : 5,
        "SpglibTestData/monoclinic/POSCAR-010-2" : 5,
        "SpglibTestData/monoclinic/POSCAR-011" : 5,
        "SpglibTestData/monoclinic/POSCAR-011-2" : 5,
        "SpglibTestData/monoclinic/POSCAR-012" : 5,
        "SpglibTestData/monoclinic/POSCAR-012-2" : 5,
        "SpglibTestData/monoclinic/POSCAR-012-3" : 5,
        "SpglibTestData/monoclinic/POSCAR-013" : 5,
        "SpglibTestData/monoclinic/POSCAR-013-2" : 5,
        "SpglibTestData/monoclinic/POSCAR-013-3" : 5,
        "SpglibTestData/monoclinic/POSCAR-014" : 5,
        "SpglibTestData/monoclinic/POSCAR-014-2" : 5,
        "SpglibTestData/monoclinic/POSCAR-015" : 5,
        "SpglibTestData/monoclinic/POSCAR-015-2" : 5,
        "SpglibTestData/monoclinic/POSCAR-015-3" : 5
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, reference) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type, 1.0)}
          
          let pointGroupNumber: Int? = FindPointGroupNoPartialOccupanciesTests.SKTestPointGroup(unitCell: unitCell, atoms: translatedAtoms, allowPartialOccupancies: false, symmetryPrecision: precision)
          XCTAssertNotNil(pointGroupNumber, "space group \(fileName) not found")
          if let pointGroupNumber = pointGroupNumber
          {
            XCTAssertEqual(pointGroupNumber, reference, "Wrong pointGroup found for \(fileName)")
          }
        }
      }
    }
  }
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testFindOrthorhombicSpaceGroup()
  {
    let testData: [String: Int] =
      [
        "SpglibTestData/orthorhombic/POSCAR-016" : 6,
        "SpglibTestData/orthorhombic/POSCAR-016-2" : 6,
        "SpglibTestData/orthorhombic/POSCAR-017-2" : 6,
        "SpglibTestData/orthorhombic/POSCAR-018" : 6,
        "SpglibTestData/orthorhombic/POSCAR-018-2" : 6,
        "SpglibTestData/orthorhombic/POSCAR-019" : 6,
        "SpglibTestData/orthorhombic/POSCAR-019-2" : 6,
        "SpglibTestData/orthorhombic/POSCAR-020" : 6,
        "SpglibTestData/orthorhombic/POSCAR-021" : 6,
        "SpglibTestData/orthorhombic/POSCAR-021-2" : 6,
        "SpglibTestData/orthorhombic/POSCAR-022" : 6,
        "SpglibTestData/orthorhombic/POSCAR-023" : 6,
        "SpglibTestData/orthorhombic/POSCAR-023-2" : 6,
        "SpglibTestData/orthorhombic/POSCAR-024" : 6,
        "SpglibTestData/orthorhombic/POSCAR-024-2" : 6,
        "SpglibTestData/orthorhombic/POSCAR-025" : 7,
        "SpglibTestData/orthorhombic/POSCAR-025-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-026" : 7,
        "SpglibTestData/orthorhombic/POSCAR-026-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-027" : 7,
        "SpglibTestData/orthorhombic/POSCAR-027-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-028" : 7,
        "SpglibTestData/orthorhombic/POSCAR-028-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-029" : 7,
        "SpglibTestData/orthorhombic/POSCAR-029-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-030" : 7,
        "SpglibTestData/orthorhombic/POSCAR-030-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-031" : 7,
        "SpglibTestData/orthorhombic/POSCAR-031-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-032" : 7,
        "SpglibTestData/orthorhombic/POSCAR-032-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-033" : 7,
        "SpglibTestData/orthorhombic/POSCAR-033-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-033-3" : 7,
        "SpglibTestData/orthorhombic/POSCAR-034" : 7,
        "SpglibTestData/orthorhombic/POSCAR-034-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-035" : 7,
        "SpglibTestData/orthorhombic/POSCAR-035-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-036" : 7,
        "SpglibTestData/orthorhombic/POSCAR-036-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-037" : 7,
        "SpglibTestData/orthorhombic/POSCAR-037-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-038" : 7,
        "SpglibTestData/orthorhombic/POSCAR-038-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-039" : 7,
        "SpglibTestData/orthorhombic/POSCAR-039-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-040" : 7,
        "SpglibTestData/orthorhombic/POSCAR-040-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-041" : 7,
        "SpglibTestData/orthorhombic/POSCAR-041-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-042" : 7,
        "SpglibTestData/orthorhombic/POSCAR-043" : 7,
        "SpglibTestData/orthorhombic/POSCAR-043-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-044" : 7,
        "SpglibTestData/orthorhombic/POSCAR-044-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-045" : 7,
        "SpglibTestData/orthorhombic/POSCAR-045-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-046" : 7,
        "SpglibTestData/orthorhombic/POSCAR-046-2" : 7,
        "SpglibTestData/orthorhombic/POSCAR-047" : 8,
        "SpglibTestData/orthorhombic/POSCAR-047-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-048" : 8,
        "SpglibTestData/orthorhombic/POSCAR-048-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-049" : 8,
        "SpglibTestData/orthorhombic/POSCAR-049-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-050" : 8,
        "SpglibTestData/orthorhombic/POSCAR-050-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-051" : 8,
        "SpglibTestData/orthorhombic/POSCAR-051-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-051-3" : 8,
        "SpglibTestData/orthorhombic/POSCAR-052" : 8,
        "SpglibTestData/orthorhombic/POSCAR-052-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-053" : 8,
        "SpglibTestData/orthorhombic/POSCAR-053-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-054" : 8,
        "SpglibTestData/orthorhombic/POSCAR-054-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-055" : 8,
        "SpglibTestData/orthorhombic/POSCAR-055-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-056" : 8,
        "SpglibTestData/orthorhombic/POSCAR-056-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-057" : 8,
        "SpglibTestData/orthorhombic/POSCAR-057-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-058" : 8,
        "SpglibTestData/orthorhombic/POSCAR-058-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-058-3" : 8,
        "SpglibTestData/orthorhombic/POSCAR-059" : 8,
        "SpglibTestData/orthorhombic/POSCAR-059-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-060" : 8,
        "SpglibTestData/orthorhombic/POSCAR-060-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-060-3" : 8,
        "SpglibTestData/orthorhombic/POSCAR-061" : 8,
        "SpglibTestData/orthorhombic/POSCAR-061-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-062" : 8,
        "SpglibTestData/orthorhombic/POSCAR-062-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-063" : 8,
        "SpglibTestData/orthorhombic/POSCAR-063-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-063-3" : 8,
        "SpglibTestData/orthorhombic/POSCAR-064" : 8,
        "SpglibTestData/orthorhombic/POSCAR-064-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-064-3" : 8,
        "SpglibTestData/orthorhombic/POSCAR-065" : 8,
        "SpglibTestData/orthorhombic/POSCAR-065-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-065-3" : 8,
        "SpglibTestData/orthorhombic/POSCAR-066" : 8,
        "SpglibTestData/orthorhombic/POSCAR-066-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-067" : 8,
        "SpglibTestData/orthorhombic/POSCAR-067-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-067-3" : 8,
        "SpglibTestData/orthorhombic/POSCAR-068" : 8,
        "SpglibTestData/orthorhombic/POSCAR-068-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-069" : 8,
        "SpglibTestData/orthorhombic/POSCAR-069-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-070" : 8,
        "SpglibTestData/orthorhombic/POSCAR-070-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-071" : 8,
        "SpglibTestData/orthorhombic/POSCAR-071-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-072" : 8,
        "SpglibTestData/orthorhombic/POSCAR-072-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-073" : 8,
        "SpglibTestData/orthorhombic/POSCAR-073-2" : 8,
        "SpglibTestData/orthorhombic/POSCAR-074" : 8,
        "SpglibTestData/orthorhombic/POSCAR-074-2" : 8
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, reference) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type, 1.0)}
          
          let pointGroupNumber: Int? = FindPointGroupNoPartialOccupanciesTests.SKTestPointGroup(unitCell: unitCell, atoms: translatedAtoms, allowPartialOccupancies: false, symmetryPrecision: precision)
          XCTAssertNotNil(pointGroupNumber, "space group \(fileName) not found")
          if let pointGroupNumber = pointGroupNumber
          {
            XCTAssertEqual(pointGroupNumber, reference, "Wrong pointGroup found for \(fileName)")
          }
        }
      }
    }
  }
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testFindTetragonalSpaceGroup()
  {
    let testData: [String: Int] =
      [
        "SpglibTestData/tetragonal/POSCAR-075" : 9,
        "SpglibTestData/tetragonal/POSCAR-075-2" : 9,
        "SpglibTestData/tetragonal/POSCAR-076" : 9,
        "SpglibTestData/tetragonal/POSCAR-076-2" : 9,
        "SpglibTestData/tetragonal/POSCAR-077" : 9,
        "SpglibTestData/tetragonal/POSCAR-077-2" : 9,
        "SpglibTestData/tetragonal/POSCAR-077-3" : 9,
        "SpglibTestData/tetragonal/POSCAR-078" : 9,
        "SpglibTestData/tetragonal/POSCAR-078-2" : 9,
        "SpglibTestData/tetragonal/POSCAR-079" : 9,
        "SpglibTestData/tetragonal/POSCAR-079-2" : 9,
        "SpglibTestData/tetragonal/POSCAR-080" : 9,
        "SpglibTestData/tetragonal/POSCAR-080-2" : 9,
        "SpglibTestData/tetragonal/POSCAR-081" : 10,
        "SpglibTestData/tetragonal/POSCAR-081-2" : 10,
        "SpglibTestData/tetragonal/POSCAR-082" : 10,
        "SpglibTestData/tetragonal/POSCAR-082-2" : 10,
        "SpglibTestData/tetragonal/POSCAR-083" : 11,
        "SpglibTestData/tetragonal/POSCAR-083-2" : 11,
        "SpglibTestData/tetragonal/POSCAR-083-3" : 11,
        "SpglibTestData/tetragonal/POSCAR-084" : 11,
        "SpglibTestData/tetragonal/POSCAR-084-2" : 11,
        "SpglibTestData/tetragonal/POSCAR-085" : 11,
        "SpglibTestData/tetragonal/POSCAR-085-2" : 11,
        "SpglibTestData/tetragonal/POSCAR-086" : 11,
        "SpglibTestData/tetragonal/POSCAR-086-2" : 11,
        "SpglibTestData/tetragonal/POSCAR-087" : 11,
        "SpglibTestData/tetragonal/POSCAR-087-2" : 11,
        "SpglibTestData/tetragonal/POSCAR-088" : 11,
        "SpglibTestData/tetragonal/POSCAR-088-2" : 11,
        "SpglibTestData/tetragonal/POSCAR-090" : 12,
        "SpglibTestData/tetragonal/POSCAR-090-2" : 12,
        "SpglibTestData/tetragonal/POSCAR-091" : 12,
        "SpglibTestData/tetragonal/POSCAR-091-2" : 12,
        "SpglibTestData/tetragonal/POSCAR-092" : 12,
        "SpglibTestData/tetragonal/POSCAR-092-2" : 12,
        "SpglibTestData/tetragonal/POSCAR-092-3" : 12,
        "SpglibTestData/tetragonal/POSCAR-094" : 12,
        "SpglibTestData/tetragonal/POSCAR-094-2" : 12,
        "SpglibTestData/tetragonal/POSCAR-094-3" : 12,
        "SpglibTestData/tetragonal/POSCAR-095" : 12,
        "SpglibTestData/tetragonal/POSCAR-095-2" : 12,
        "SpglibTestData/tetragonal/POSCAR-096" : 12,
        "SpglibTestData/tetragonal/POSCAR-096-2" : 12,
        "SpglibTestData/tetragonal/POSCAR-097" : 12,
        "SpglibTestData/tetragonal/POSCAR-097-2" : 12,
        "SpglibTestData/tetragonal/POSCAR-098" : 12,
        "SpglibTestData/tetragonal/POSCAR-098-2" : 12,
        "SpglibTestData/tetragonal/POSCAR-099" : 13,
        "SpglibTestData/tetragonal/POSCAR-099-2" : 13,
        "SpglibTestData/tetragonal/POSCAR-100" : 13,
        "SpglibTestData/tetragonal/POSCAR-100-2" : 13,
        "SpglibTestData/tetragonal/POSCAR-102" : 13,
        "SpglibTestData/tetragonal/POSCAR-102-2" : 13,
        "SpglibTestData/tetragonal/POSCAR-103" : 13,
        "SpglibTestData/tetragonal/POSCAR-103-2" : 13,
        "SpglibTestData/tetragonal/POSCAR-104" : 13,
        "SpglibTestData/tetragonal/POSCAR-104-2" : 13,
        "SpglibTestData/tetragonal/POSCAR-105" : 13,
        "SpglibTestData/tetragonal/POSCAR-105-2" : 13,
        "SpglibTestData/tetragonal/POSCAR-106" : 13,
        "SpglibTestData/tetragonal/POSCAR-107" : 13,
        "SpglibTestData/tetragonal/POSCAR-107-2" : 13,
        "SpglibTestData/tetragonal/POSCAR-107-3" : 13,
        "SpglibTestData/tetragonal/POSCAR-108" : 13,
        "SpglibTestData/tetragonal/POSCAR-108-2" : 13,
        "SpglibTestData/tetragonal/POSCAR-109" : 13,
        "SpglibTestData/tetragonal/POSCAR-109-2" : 13,
        "SpglibTestData/tetragonal/POSCAR-110" : 13,
        "SpglibTestData/tetragonal/POSCAR-110-2" : 13,
        "SpglibTestData/tetragonal/POSCAR-111" : 14,
        "SpglibTestData/tetragonal/POSCAR-111-2" : 14,
        "SpglibTestData/tetragonal/POSCAR-112" : 14,
        "SpglibTestData/tetragonal/POSCAR-112-2" : 14,
        "SpglibTestData/tetragonal/POSCAR-113" : 14,
        "SpglibTestData/tetragonal/POSCAR-113-2" : 14,
        "SpglibTestData/tetragonal/POSCAR-114" : 14,
        "SpglibTestData/tetragonal/POSCAR-114-2" : 14,
        "SpglibTestData/tetragonal/POSCAR-115" : 14,
        "SpglibTestData/tetragonal/POSCAR-115-2" : 14,
        "SpglibTestData/tetragonal/POSCAR-115-3" : 14,
        "SpglibTestData/tetragonal/POSCAR-115-4" : 14,
        "SpglibTestData/tetragonal/POSCAR-115-5" : 14,
        "SpglibTestData/tetragonal/POSCAR-116" : 14,
        "SpglibTestData/tetragonal/POSCAR-116-2" : 14,
        "SpglibTestData/tetragonal/POSCAR-117" : 14,
        "SpglibTestData/tetragonal/POSCAR-117-2" : 14,
        "SpglibTestData/tetragonal/POSCAR-118" : 14,
        "SpglibTestData/tetragonal/POSCAR-118-2" : 14,
        "SpglibTestData/tetragonal/POSCAR-119" : 14,
        "SpglibTestData/tetragonal/POSCAR-119-2" : 14,
        "SpglibTestData/tetragonal/POSCAR-120" : 14,
        "SpglibTestData/tetragonal/POSCAR-120-2" : 14,
        "SpglibTestData/tetragonal/POSCAR-121" : 14,
        "SpglibTestData/tetragonal/POSCAR-121-2" : 14,
        "SpglibTestData/tetragonal/POSCAR-122" : 14,
        "SpglibTestData/tetragonal/POSCAR-122-2" : 14,
        "SpglibTestData/tetragonal/POSCAR-122-3" : 14,
        "SpglibTestData/tetragonal/POSCAR-123" : 15,
        "SpglibTestData/tetragonal/POSCAR-123-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-123-3" : 15,
        "SpglibTestData/tetragonal/POSCAR-124" : 15,
        "SpglibTestData/tetragonal/POSCAR-124-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-125" : 15,
        "SpglibTestData/tetragonal/POSCAR-125-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-126" : 15,
        "SpglibTestData/tetragonal/POSCAR-126-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-127" : 15,
        "SpglibTestData/tetragonal/POSCAR-127-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-128" : 15,
        "SpglibTestData/tetragonal/POSCAR-128-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-129" : 15,
        "SpglibTestData/tetragonal/POSCAR-129-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-129-3" : 15,
        "SpglibTestData/tetragonal/POSCAR-130" : 15,
        "SpglibTestData/tetragonal/POSCAR-130-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-131" : 15,
        "SpglibTestData/tetragonal/POSCAR-131-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-132" : 15,
        "SpglibTestData/tetragonal/POSCAR-132-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-133" : 15,
        "SpglibTestData/tetragonal/POSCAR-133-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-134" : 15,
        "SpglibTestData/tetragonal/POSCAR-134-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-135" : 15,
        "SpglibTestData/tetragonal/POSCAR-135-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-136" : 15,
        "SpglibTestData/tetragonal/POSCAR-136-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-136-3" : 15,
        "SpglibTestData/tetragonal/POSCAR-136-4" : 15,
        "SpglibTestData/tetragonal/POSCAR-136-5" : 15,
        "SpglibTestData/tetragonal/POSCAR-137" : 15,
        "SpglibTestData/tetragonal/POSCAR-137-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-137-3" : 15,
        "SpglibTestData/tetragonal/POSCAR-138" : 15,
        "SpglibTestData/tetragonal/POSCAR-138-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-139" : 15,
        "SpglibTestData/tetragonal/POSCAR-139-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-140" : 15,
        "SpglibTestData/tetragonal/POSCAR-140-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-141" : 15,
        "SpglibTestData/tetragonal/POSCAR-141-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-142" : 15,
        "SpglibTestData/tetragonal/POSCAR-142-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-142-3" : 15
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, reference) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type, 1.0)}
          
          let pointGroupNumber: Int? = FindPointGroupNoPartialOccupanciesTests.SKTestPointGroup(unitCell: unitCell, atoms: translatedAtoms, allowPartialOccupancies: false, symmetryPrecision: precision)
          XCTAssertNotNil(pointGroupNumber, "space group \(fileName) not found")
          if let pointGroupNumber = pointGroupNumber
          {
            XCTAssertEqual(pointGroupNumber, reference, "Wrong pointGroup found for \(fileName)")
          }
        }
      }
    }
  }

  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testFindTrigonalSpaceGroup()
  {
    let testData: [String: Int] =
      [
        "SpglibTestData/trigonal/POSCAR-143" : 16,
        "SpglibTestData/trigonal/POSCAR-143-2" : 16,
        "SpglibTestData/trigonal/POSCAR-144" : 16,
        "SpglibTestData/trigonal/POSCAR-144-2" : 16,
        "SpglibTestData/trigonal/POSCAR-145" : 16,
        "SpglibTestData/trigonal/POSCAR-145-2" : 16,
        "SpglibTestData/trigonal/POSCAR-146" : 16,
        "SpglibTestData/trigonal/POSCAR-146-2" : 16,
        "SpglibTestData/trigonal/POSCAR-147" : 17,
        "SpglibTestData/trigonal/POSCAR-147-2" : 17,
        "SpglibTestData/trigonal/POSCAR-148" : 17,
        "SpglibTestData/trigonal/POSCAR-148-2" : 17,
        "SpglibTestData/trigonal/POSCAR-149" : 18,
        "SpglibTestData/trigonal/POSCAR-149-2" : 18,
        "SpglibTestData/trigonal/POSCAR-150" : 18,
        "SpglibTestData/trigonal/POSCAR-150-2" : 18,
        "SpglibTestData/trigonal/POSCAR-151" : 18,
        "SpglibTestData/trigonal/POSCAR-151-2" : 18,
        "SpglibTestData/trigonal/POSCAR-152" : 18,
        "SpglibTestData/trigonal/POSCAR-152-2" : 18,
        "SpglibTestData/trigonal/POSCAR-153" : 18,
        "SpglibTestData/trigonal/POSCAR-154" : 18,
        "SpglibTestData/trigonal/POSCAR-154-2" : 18,
        "SpglibTestData/trigonal/POSCAR-154-3" : 18,
        "SpglibTestData/trigonal/POSCAR-155" : 18,
        "SpglibTestData/trigonal/POSCAR-155-2" : 18,
        "SpglibTestData/trigonal/POSCAR-156" : 19,
        "SpglibTestData/trigonal/POSCAR-156-2" : 19,
        "SpglibTestData/trigonal/POSCAR-157" : 19,
        "SpglibTestData/trigonal/POSCAR-157-2" : 19,
        "SpglibTestData/trigonal/POSCAR-158" : 19,
        "SpglibTestData/trigonal/POSCAR-158-2" : 19,
        "SpglibTestData/trigonal/POSCAR-159" : 19,
        "SpglibTestData/trigonal/POSCAR-159-2" : 19,
        "SpglibTestData/trigonal/POSCAR-160" : 19,
        "SpglibTestData/trigonal/POSCAR-160-2" : 19,
        "SpglibTestData/trigonal/POSCAR-161" : 19,
        "SpglibTestData/trigonal/POSCAR-161-2" : 19,
        "SpglibTestData/trigonal/POSCAR-162" : 20,
        "SpglibTestData/trigonal/POSCAR-162-2" : 20,
        "SpglibTestData/trigonal/POSCAR-163" : 20,
        "SpglibTestData/trigonal/POSCAR-163-2" : 20,
        "SpglibTestData/trigonal/POSCAR-164" : 20,
        "SpglibTestData/trigonal/POSCAR-164-2" : 20,
        "SpglibTestData/trigonal/POSCAR-165" : 20,
        "SpglibTestData/trigonal/POSCAR-165-2" : 20,
        "SpglibTestData/trigonal/POSCAR-166" : 20,
        "SpglibTestData/trigonal/POSCAR-166-2" : 20,
        "SpglibTestData/trigonal/POSCAR-167" : 20,
        "SpglibTestData/trigonal/POSCAR-167-2" : 20,
        "SpglibTestData/trigonal/POSCAR-167-3" : 20
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, reference) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type, 1.0)}
          
          let pointGroupNumber: Int? = FindPointGroupNoPartialOccupanciesTests.SKTestPointGroup(unitCell: unitCell, atoms: translatedAtoms, allowPartialOccupancies: false, symmetryPrecision: precision)
          XCTAssertNotNil(pointGroupNumber, "space group \(fileName) not found")
          if let pointGroupNumber = pointGroupNumber
          {
            XCTAssertEqual(pointGroupNumber, reference, "Wrong pointGroup found for \(fileName)")
          }
        }
      }
    }
  }
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testFindHexagonalSpaceGroup()
  {
    let testData: [String: Int] =
      [
        "SpglibTestData/hexagonal/POSCAR-168" : 21,
        "SpglibTestData/hexagonal/POSCAR-169" : 21,
        "SpglibTestData/hexagonal/POSCAR-169-2" : 21,
        "SpglibTestData/hexagonal/POSCAR-170" : 21,
        "SpglibTestData/hexagonal/POSCAR-170-2" : 21,
        "SpglibTestData/hexagonal/POSCAR-171" : 21,
        "SpglibTestData/hexagonal/POSCAR-171-2" : 21,
        "SpglibTestData/hexagonal/POSCAR-172" : 21,
        "SpglibTestData/hexagonal/POSCAR-173" : 21,
        "SpglibTestData/hexagonal/POSCAR-173-2" : 21,
        "SpglibTestData/hexagonal/POSCAR-174" : 22,
        "SpglibTestData/hexagonal/POSCAR-174-2" : 22,
        "SpglibTestData/hexagonal/POSCAR-175" : 23,
        "SpglibTestData/hexagonal/POSCAR-175-2" : 23,
        "SpglibTestData/hexagonal/POSCAR-176" : 23,
        "SpglibTestData/hexagonal/POSCAR-176-2" : 23,
        "SpglibTestData/hexagonal/POSCAR-177" : 24,
        "SpglibTestData/hexagonal/POSCAR-179" : 24,
        "SpglibTestData/hexagonal/POSCAR-179-2" : 24,
        "SpglibTestData/hexagonal/POSCAR-180" : 24,
        "SpglibTestData/hexagonal/POSCAR-180-2" : 24,
        "SpglibTestData/hexagonal/POSCAR-181" : 24,
        "SpglibTestData/hexagonal/POSCAR-181-2" : 24,
        "SpglibTestData/hexagonal/POSCAR-182" : 24,
        "SpglibTestData/hexagonal/POSCAR-182-2" : 24,
        "SpglibTestData/hexagonal/POSCAR-183" : 25,
        "SpglibTestData/hexagonal/POSCAR-183-2" : 25,
        "SpglibTestData/hexagonal/POSCAR-184" : 25,
        "SpglibTestData/hexagonal/POSCAR-184-2" : 25,
        "SpglibTestData/hexagonal/POSCAR-185" : 25,
        "SpglibTestData/hexagonal/POSCAR-185-2" : 25,
        "SpglibTestData/hexagonal/POSCAR-186" : 25,
        "SpglibTestData/hexagonal/POSCAR-186-2" : 25,
        "SpglibTestData/hexagonal/POSCAR-187" : 26,
        "SpglibTestData/hexagonal/POSCAR-187-2" : 26,
        "SpglibTestData/hexagonal/POSCAR-188" : 26,
        "SpglibTestData/hexagonal/POSCAR-188-2" : 26,
        "SpglibTestData/hexagonal/POSCAR-189" : 26,
        "SpglibTestData/hexagonal/POSCAR-189-2" : 26,
        "SpglibTestData/hexagonal/POSCAR-190" : 26,
        "SpglibTestData/hexagonal/POSCAR-190-2" : 26,
        "SpglibTestData/hexagonal/POSCAR-191" : 27,
        "SpglibTestData/hexagonal/POSCAR-191-2" : 27,
        "SpglibTestData/hexagonal/POSCAR-192" : 27,
        "SpglibTestData/hexagonal/POSCAR-192-2" : 27,
        "SpglibTestData/hexagonal/POSCAR-193" : 27,
        "SpglibTestData/hexagonal/POSCAR-193-2" : 27,
        "SpglibTestData/hexagonal/POSCAR-194" : 27,
        "SpglibTestData/hexagonal/POSCAR-194-2" : 27
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, reference) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type, 1.0)}
          
          let pointGroupNumber: Int? = FindPointGroupNoPartialOccupanciesTests.SKTestPointGroup(unitCell: unitCell, atoms: translatedAtoms, allowPartialOccupancies: false, symmetryPrecision: precision)
          XCTAssertNotNil(pointGroupNumber, "space group \(fileName) not found")
          if let pointGroupNumber = pointGroupNumber
          {
            XCTAssertEqual(pointGroupNumber, reference, "Wrong pointGroup found for \(fileName)")
          }
        }
      }
    }
  }
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testFindCubicSpaceGroup()
  {
    let testData: [String: Int] =
      [
        "SpglibTestData/cubic/POSCAR-195" : 28,
        "SpglibTestData/cubic/POSCAR-195-2" : 28,
        "SpglibTestData/cubic/POSCAR-196" : 28,
        "SpglibTestData/cubic/POSCAR-196-2" : 28,
        "SpglibTestData/cubic/POSCAR-197" : 28,
        "SpglibTestData/cubic/POSCAR-197-2" : 28,
        "SpglibTestData/cubic/POSCAR-198" : 28,
        "SpglibTestData/cubic/POSCAR-198-2" : 28,
        "SpglibTestData/cubic/POSCAR-199" : 28,
        "SpglibTestData/cubic/POSCAR-199-2" : 28,
        "SpglibTestData/cubic/POSCAR-200" : 29,
        "SpglibTestData/cubic/POSCAR-200-2" : 29,
        "SpglibTestData/cubic/POSCAR-205" : 29,
        "SpglibTestData/cubic/POSCAR-205-3" : 29,
        "SpglibTestData/cubic/POSCAR-206" : 29,
        "SpglibTestData/cubic/POSCAR-206-2" : 29,
        "SpglibTestData/cubic/POSCAR-207" : 30,
        "SpglibTestData/cubic/POSCAR-208" : 30,
        "SpglibTestData/cubic/POSCAR-208-2" : 30,
        "SpglibTestData/cubic/POSCAR-209" : 30,
        "SpglibTestData/cubic/POSCAR-210" : 30,
        "SpglibTestData/cubic/POSCAR-210-2" : 30,
        "SpglibTestData/cubic/POSCAR-211" : 30,
        "SpglibTestData/cubic/POSCAR-212" : 30,
        "SpglibTestData/cubic/POSCAR-212-2" : 30,
        "SpglibTestData/cubic/POSCAR-213" : 30,
        "SpglibTestData/cubic/POSCAR-213-2" : 30,
        "SpglibTestData/cubic/POSCAR-214" : 30,
        "SpglibTestData/cubic/POSCAR-214-2" : 30,
        "SpglibTestData/cubic/POSCAR-215" : 31,
        "SpglibTestData/cubic/POSCAR-215-2" : 31,
        "SpglibTestData/cubic/POSCAR-216" : 31,
        "SpglibTestData/cubic/POSCAR-216-2" : 31,
        "SpglibTestData/cubic/POSCAR-217" : 31,
        "SpglibTestData/cubic/POSCAR-217-2" : 31,
        "SpglibTestData/cubic/POSCAR-218" : 31,
        "SpglibTestData/cubic/POSCAR-218-2" : 31,
        "SpglibTestData/cubic/POSCAR-219" : 31,
        "SpglibTestData/cubic/POSCAR-219-2" : 31,
        "SpglibTestData/cubic/POSCAR-220" : 31,
        "SpglibTestData/cubic/POSCAR-220-2" : 31,
        "SpglibTestData/cubic/POSCAR-221" : 32,
        "SpglibTestData/cubic/POSCAR-221-2" : 32,
        "SpglibTestData/cubic/POSCAR-222" : 32,
        "SpglibTestData/cubic/POSCAR-222-2" : 32,
        "SpglibTestData/cubic/POSCAR-223" : 32,
        "SpglibTestData/cubic/POSCAR-223-2" : 32,
        "SpglibTestData/cubic/POSCAR-224" : 32,
        "SpglibTestData/cubic/POSCAR-224-2" : 32,
        "SpglibTestData/cubic/POSCAR-225" : 32,
        "SpglibTestData/cubic/POSCAR-225-2" : 32,
        "SpglibTestData/cubic/POSCAR-226" : 32,
        "SpglibTestData/cubic/POSCAR-226-2" : 32,
        "SpglibTestData/cubic/POSCAR-227" : 32,
        "SpglibTestData/cubic/POSCAR-227-2" : 32,
        "SpglibTestData/cubic/POSCAR-228" : 32,
        "SpglibTestData/cubic/POSCAR-228-2" : 32,
        "SpglibTestData/cubic/POSCAR-229" : 32,
        "SpglibTestData/cubic/POSCAR-229-2" : 32,
        "SpglibTestData/cubic/POSCAR-230" : 32,
        "SpglibTestData/cubic/POSCAR-230-2" : 32,
        "SpglibTestData/cubic/POSCAR-230-3" : 32,
        "SpglibTestData/cubic/POSCAR-230-4" : 32
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, reference) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type, 1.0)}
          
          let pointGroupNumber: Int? = FindPointGroupNoPartialOccupanciesTests.SKTestPointGroup(unitCell: unitCell, atoms: translatedAtoms, allowPartialOccupancies: false, symmetryPrecision: precision)
          XCTAssertNotNil(pointGroupNumber, "space group \(fileName) not found")
          if let pointGroupNumber = pointGroupNumber
          {
            XCTAssertEqual(pointGroupNumber, reference, "Wrong pointGroup found for \(fileName)")
          }
        }
      }
    }
  }
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testFindVirtualSpaceGroup()
  {
    let testData: [String: Int] =
      [
        "SpglibTestData/virtual_structure/POSCAR-1-221-33" : 1,
        "SpglibTestData/virtual_structure/POSCAR-1-222-33" : 1,
        "SpglibTestData/virtual_structure/POSCAR-1-223-33" : 1,
        "SpglibTestData/virtual_structure/POSCAR-1-224-33" : 1,
        "SpglibTestData/virtual_structure/POSCAR-1-227-73" : 1,
        "SpglibTestData/virtual_structure/POSCAR-1-227-93" : 1,
        "SpglibTestData/virtual_structure/POSCAR-1-227-99" : 1,
        "SpglibTestData/virtual_structure/POSCAR-1-230-conv-56" : 1,
        "SpglibTestData/virtual_structure/POSCAR-1-230-prim-33" : 1,
        "SpglibTestData/virtual_structure/POSCAR-1-bcc-33" : 1,
        "SpglibTestData/virtual_structure/POSCAR-10-221-18" : 5,
        "SpglibTestData/virtual_structure/POSCAR-10-223-18" : 5,
        "SpglibTestData/virtual_structure/POSCAR-10-227-50" : 5,
        "SpglibTestData/virtual_structure/POSCAR-102-224-13" : 13,
        "SpglibTestData/virtual_structure/POSCAR-104-222-13" : 13,
        "SpglibTestData/virtual_structure/POSCAR-105-223-13" : 13,
        "SpglibTestData/virtual_structure/POSCAR-109-227-13" : 13,
        "SpglibTestData/virtual_structure/POSCAR-11-227-48" : 5,
        "SpglibTestData/virtual_structure/POSCAR-110-230-conv-15" : 13,
        "SpglibTestData/virtual_structure/POSCAR-110-230-prim-13" : 13,
        "SpglibTestData/virtual_structure/POSCAR-111-221-11" : 14,
        "SpglibTestData/virtual_structure/POSCAR-111-224-11" : 14,
        "SpglibTestData/virtual_structure/POSCAR-111-227-66" : 14,
        "SpglibTestData/virtual_structure/POSCAR-112-222-11" : 14,
        "SpglibTestData/virtual_structure/POSCAR-112-223-11" : 14,
        "SpglibTestData/virtual_structure/POSCAR-113-227-68" : 14,
        "SpglibTestData/virtual_structure/POSCAR-115-221-14" : 14,
        "SpglibTestData/virtual_structure/POSCAR-115-223-14" : 14,
        "SpglibTestData/virtual_structure/POSCAR-115-227-33" : 14,
        "SpglibTestData/virtual_structure/POSCAR-116-230-conv-34" : 14,
        "SpglibTestData/virtual_structure/POSCAR-117-230-conv-33" : 14,
        "SpglibTestData/virtual_structure/POSCAR-118-222-14" : 14,
        "SpglibTestData/virtual_structure/POSCAR-118-224-14" : 14,
        "SpglibTestData/virtual_structure/POSCAR-12-221-19" : 5,
        "SpglibTestData/virtual_structure/POSCAR-12-224-19" : 5,
        "SpglibTestData/virtual_structure/POSCAR-12-227-21" : 5,
        "SpglibTestData/virtual_structure/POSCAR-12-227-83" : 5,
        "SpglibTestData/virtual_structure/POSCAR-120-230-conv-16" : 14,
        "SpglibTestData/virtual_structure/POSCAR-120-230-prim-14" : 14,
        "SpglibTestData/virtual_structure/POSCAR-122-230-conv-13" : 14,
        "SpglibTestData/virtual_structure/POSCAR-122-230-prim-11" : 14,
        "SpglibTestData/virtual_structure/POSCAR-123-221-05" : 15,
        "SpglibTestData/virtual_structure/POSCAR-126-222-05" : 15,
        "SpglibTestData/virtual_structure/POSCAR-13-222-18" : 5,
        "SpglibTestData/virtual_structure/POSCAR-13-224-18" : 5,
        "SpglibTestData/virtual_structure/POSCAR-13-227-49" : 5,
        "SpglibTestData/virtual_structure/POSCAR-13-230-conv-44" : 5,
        "SpglibTestData/virtual_structure/POSCAR-131-223-05" : 15,
        "SpglibTestData/virtual_structure/POSCAR-134-224-05" : 15,
        "SpglibTestData/virtual_structure/POSCAR-14-227-47" : 5,
        "SpglibTestData/virtual_structure/POSCAR-14-227-51" : 5,
        "SpglibTestData/virtual_structure/POSCAR-14-230-conv-45" : 5,
        "SpglibTestData/virtual_structure/POSCAR-142-230-conv-05" : 15,
        "SpglibTestData/virtual_structure/POSCAR-142-230-prim-05" : 15,
        "SpglibTestData/virtual_structure/POSCAR-146-221-27" : 16,
        "SpglibTestData/virtual_structure/POSCAR-146-222-27" : 16,
        "SpglibTestData/virtual_structure/POSCAR-146-223-27" : 16,
        "SpglibTestData/virtual_structure/POSCAR-146-224-27" : 16,
        "SpglibTestData/virtual_structure/POSCAR-146-227-92" : 16,
        "SpglibTestData/virtual_structure/POSCAR-146-230-conv-36" : 16,
        "SpglibTestData/virtual_structure/POSCAR-146-230-conv-55" : 16,
        "SpglibTestData/virtual_structure/POSCAR-146-230-prim-27" : 16,
        "SpglibTestData/virtual_structure/POSCAR-146-bcc-27" : 16,
        "SpglibTestData/virtual_structure/POSCAR-148-221-15" : 17,
        "SpglibTestData/virtual_structure/POSCAR-148-222-15" : 17,
        "SpglibTestData/virtual_structure/POSCAR-148-223-15" : 17,
        "SpglibTestData/virtual_structure/POSCAR-148-224-15" : 17,
        "SpglibTestData/virtual_structure/POSCAR-148-227-70" : 17,
        "SpglibTestData/virtual_structure/POSCAR-148-230-conv-17" : 17,
        "SpglibTestData/virtual_structure/POSCAR-148-230-conv-37" : 17,
        "SpglibTestData/virtual_structure/POSCAR-148-230-prim-15" : 17,
        "SpglibTestData/virtual_structure/POSCAR-148-bcc-15" : 17,
        "SpglibTestData/virtual_structure/POSCAR-15-222-19" : 5,
        "SpglibTestData/virtual_structure/POSCAR-15-223-19" : 5,
        "SpglibTestData/virtual_structure/POSCAR-15-230-conv-21" : 5,
        "SpglibTestData/virtual_structure/POSCAR-15-230-conv-22" : 5,
        "SpglibTestData/virtual_structure/POSCAR-15-230-prim-18" : 5,
        "SpglibTestData/virtual_structure/POSCAR-15-230-prim-19" : 5,
        "SpglibTestData/virtual_structure/POSCAR-15-bcc-18" : 5,
        "SpglibTestData/virtual_structure/POSCAR-15-bcc-19" : 5,
        "SpglibTestData/virtual_structure/POSCAR-155-221-17" : 18,
        "SpglibTestData/virtual_structure/POSCAR-155-222-17" : 18,
        "SpglibTestData/virtual_structure/POSCAR-155-223-17" : 18,
        "SpglibTestData/virtual_structure/POSCAR-155-224-17" : 18,
        "SpglibTestData/virtual_structure/POSCAR-155-227-72" : 18,
        "SpglibTestData/virtual_structure/POSCAR-155-230-conv-19" : 18,
        "SpglibTestData/virtual_structure/POSCAR-155-230-conv-38" : 18,
        "SpglibTestData/virtual_structure/POSCAR-155-230-prim-17" : 18,
        "SpglibTestData/virtual_structure/POSCAR-155-bcc-17" : 18,
        "SpglibTestData/virtual_structure/POSCAR-16-221-20" : 6,
        "SpglibTestData/virtual_structure/POSCAR-16-222-20" : 6,
        "SpglibTestData/virtual_structure/POSCAR-16-223-20" : 6,
        "SpglibTestData/virtual_structure/POSCAR-16-224-20" : 6,
        "SpglibTestData/virtual_structure/POSCAR-16-227-84" : 6,
        "SpglibTestData/virtual_structure/POSCAR-160-221-16" : 19,
        "SpglibTestData/virtual_structure/POSCAR-160-224-16" : 19,
        "SpglibTestData/virtual_structure/POSCAR-160-227-16" : 19,
        "SpglibTestData/virtual_structure/POSCAR-160-227-71" : 19,
        "SpglibTestData/virtual_structure/POSCAR-160-fcc" : 19,
        "SpglibTestData/virtual_structure/POSCAR-161-222-16" : 19,
        "SpglibTestData/virtual_structure/POSCAR-161-223-16" : 19,
        "SpglibTestData/virtual_structure/POSCAR-161-230-conv-18" : 19,
        "SpglibTestData/virtual_structure/POSCAR-161-230-prim-16" : 19,
        "SpglibTestData/virtual_structure/POSCAR-161-bcc-16" : 19,
        "SpglibTestData/virtual_structure/POSCAR-166-221-06" : 20,
        "SpglibTestData/virtual_structure/POSCAR-166-224-06" : 20,
        "SpglibTestData/virtual_structure/POSCAR-166-227-06" : 20,
        "SpglibTestData/virtual_structure/POSCAR-166-227-38" : 20,
        "SpglibTestData/virtual_structure/POSCAR-167-222-06" : 20,
        "SpglibTestData/virtual_structure/POSCAR-167-223-06" : 20,
        "SpglibTestData/virtual_structure/POSCAR-167-230-conv-06" : 20,
        "SpglibTestData/virtual_structure/POSCAR-167-230-prim-06" : 20,
        "SpglibTestData/virtual_structure/POSCAR-167-bcc-6" : 20,
        "SpglibTestData/virtual_structure/POSCAR-17-227-60" : 6,
        "SpglibTestData/virtual_structure/POSCAR-17-227-85" : 6,
        "SpglibTestData/virtual_structure/POSCAR-17-230-conv-46" : 6,
        "SpglibTestData/virtual_structure/POSCAR-18-227-86" : 6,
        "SpglibTestData/virtual_structure/POSCAR-19-227-59" : 6,
        "SpglibTestData/virtual_structure/POSCAR-19-227-89" : 6,
        "SpglibTestData/virtual_structure/POSCAR-19-230-conv-51" : 6,
        "SpglibTestData/virtual_structure/POSCAR-195-221-07" : 28,
        "SpglibTestData/virtual_structure/POSCAR-195-222-07" : 28,
        "SpglibTestData/virtual_structure/POSCAR-195-223-07" : 28,
        "SpglibTestData/virtual_structure/POSCAR-195-224-07" : 28,
        "SpglibTestData/virtual_structure/POSCAR-198-227-40" : 28,
        "SpglibTestData/virtual_structure/POSCAR-198-230-conv-20" : 28,
        "SpglibTestData/virtual_structure/POSCAR-199-230-conv-07" : 28,
        "SpglibTestData/virtual_structure/POSCAR-199-230-prim-07" : 28,
        "SpglibTestData/virtual_structure/POSCAR-2-221-28" : 2,
        "SpglibTestData/virtual_structure/POSCAR-2-222-28" : 2,
        "SpglibTestData/virtual_structure/POSCAR-2-223-28" : 2,
        "SpglibTestData/virtual_structure/POSCAR-2-224-28" : 2,
        "SpglibTestData/virtual_structure/POSCAR-2-227-41" : 2,
        "SpglibTestData/virtual_structure/POSCAR-2-227-74" : 2,
        "SpglibTestData/virtual_structure/POSCAR-2-227-94" : 2,
        "SpglibTestData/virtual_structure/POSCAR-2-230-conv-39" : 2,
        "SpglibTestData/virtual_structure/POSCAR-2-230-conv-57" : 2,
        "SpglibTestData/virtual_structure/POSCAR-2-230-prim-28" : 2,
        "SpglibTestData/virtual_structure/POSCAR-2-bcc-28" : 2,
        "SpglibTestData/virtual_structure/POSCAR-20-227-53" : 6,
        "SpglibTestData/virtual_structure/POSCAR-20-227-90" : 6,
        "SpglibTestData/virtual_structure/POSCAR-20-230-conv-53" : 6,
        "SpglibTestData/virtual_structure/POSCAR-200-221-02" : 29,
        "SpglibTestData/virtual_structure/POSCAR-200-223-02" : 29,
        "SpglibTestData/virtual_structure/POSCAR-201-222-02" : 29,
        "SpglibTestData/virtual_structure/POSCAR-201-224-02" : 29,
        "SpglibTestData/virtual_structure/POSCAR-205-230-conv-08" : 29,
        "SpglibTestData/virtual_structure/POSCAR-206-230-conv-02" : 29,
        "SpglibTestData/virtual_structure/POSCAR-206-230-prim-02" : 29,
        "SpglibTestData/virtual_structure/POSCAR-207-221-04" : 30,
        "SpglibTestData/virtual_structure/POSCAR-207-222-04" : 30,
        "SpglibTestData/virtual_structure/POSCAR-208-223-04" : 30,
        "SpglibTestData/virtual_structure/POSCAR-208-224-04" : 30,
        "SpglibTestData/virtual_structure/POSCAR-21-221-23" : 6,
        "SpglibTestData/virtual_structure/POSCAR-21-222-23" : 6,
        "SpglibTestData/virtual_structure/POSCAR-21-223-23" : 6,
        "SpglibTestData/virtual_structure/POSCAR-21-224-23" : 6,
        "SpglibTestData/virtual_structure/POSCAR-21-230-conv-49" : 6,
        "SpglibTestData/virtual_structure/POSCAR-212-227-19" : 30,
        "SpglibTestData/virtual_structure/POSCAR-213-230-conv-09" : 30,
        "SpglibTestData/virtual_structure/POSCAR-214-230-conv-04" : 30,
        "SpglibTestData/virtual_structure/POSCAR-214-230-prim-04" : 30,
        "SpglibTestData/virtual_structure/POSCAR-215-221-03" : 31,
        "SpglibTestData/virtual_structure/POSCAR-215-224-03" : 31,
        "SpglibTestData/virtual_structure/POSCAR-215-227-18" : 31,
        "SpglibTestData/virtual_structure/POSCAR-216-227-03" : 31,
        "SpglibTestData/virtual_structure/POSCAR-218-222-03" : 31,
        "SpglibTestData/virtual_structure/POSCAR-218-223-03" : 31,
        "SpglibTestData/virtual_structure/POSCAR-22-230-conv-26" : 6,
        "SpglibTestData/virtual_structure/POSCAR-22-230-prim-23" : 6,
        "SpglibTestData/virtual_structure/POSCAR-220-230-conv-03" : 31,
        "SpglibTestData/virtual_structure/POSCAR-220-230-prim-03" : 31,
        "SpglibTestData/virtual_structure/POSCAR-221-221-01" : 32,
        "SpglibTestData/virtual_structure/POSCAR-222-222-01" : 32,
        "SpglibTestData/virtual_structure/POSCAR-223-223-01" : 32,
        "SpglibTestData/virtual_structure/POSCAR-224-224-01" : 32,
        "SpglibTestData/virtual_structure/POSCAR-227-227-01" : 32,
        "SpglibTestData/virtual_structure/POSCAR-230-230-conv-01" : 32,
        "SpglibTestData/virtual_structure/POSCAR-230-230-conv-62" : 1,
        "SpglibTestData/virtual_structure/POSCAR-230-230-prim-01" : 32,
        "SpglibTestData/virtual_structure/POSCAR-24-230-conv-23" : 6,
        "SpglibTestData/virtual_structure/POSCAR-24-230-prim-20" : 6,
        "SpglibTestData/virtual_structure/POSCAR-25-221-21" : 7,
        "SpglibTestData/virtual_structure/POSCAR-25-223-21" : 7,
        "SpglibTestData/virtual_structure/POSCAR-25-227-54" : 7,
        "SpglibTestData/virtual_structure/POSCAR-26-227-64" : 7,
        "SpglibTestData/virtual_structure/POSCAR-27-230-conv-48" : 7,
        "SpglibTestData/virtual_structure/POSCAR-28-227-62" : 7,
        "SpglibTestData/virtual_structure/POSCAR-29-230-conv-52" : 7,
        "SpglibTestData/virtual_structure/POSCAR-3-221-29" : 3,
        "SpglibTestData/virtual_structure/POSCAR-3-222-29" : 3,
        "SpglibTestData/virtual_structure/POSCAR-3-223-29" : 3,
        "SpglibTestData/virtual_structure/POSCAR-3-224-29" : 3,
        "SpglibTestData/virtual_structure/POSCAR-3-227-82" : 3,
        "SpglibTestData/virtual_structure/POSCAR-3-227-95" : 3,
        "SpglibTestData/virtual_structure/POSCAR-3-230-conv-58" : 3,
        "SpglibTestData/virtual_structure/POSCAR-30-227-65" : 7,
        "SpglibTestData/virtual_structure/POSCAR-31-227-58" : 7,
        "SpglibTestData/virtual_structure/POSCAR-32-230-conv-47" : 7,
        "SpglibTestData/virtual_structure/POSCAR-33-227-63" : 7,
        "SpglibTestData/virtual_structure/POSCAR-34-222-21" : 7,
        "SpglibTestData/virtual_structure/POSCAR-34-224-21" : 7,
        "SpglibTestData/virtual_structure/POSCAR-35-221-22" : 7,
        "SpglibTestData/virtual_structure/POSCAR-35-224-22" : 7,
        "SpglibTestData/virtual_structure/POSCAR-35-227-87" : 7,
        "SpglibTestData/virtual_structure/POSCAR-37-222-22" : 7,
        "SpglibTestData/virtual_structure/POSCAR-37-223-22" : 7,
        "SpglibTestData/virtual_structure/POSCAR-38-221-26" : 7,
        "SpglibTestData/virtual_structure/POSCAR-39-224-26" : 7,
        "SpglibTestData/virtual_structure/POSCAR-4-227-77" : 3,
        "SpglibTestData/virtual_structure/POSCAR-4-227-81" : 3,
        "SpglibTestData/virtual_structure/POSCAR-4-227-96" : 3,
        "SpglibTestData/virtual_structure/POSCAR-4-230-conv-59" : 3,
        "SpglibTestData/virtual_structure/POSCAR-40-223-26" : 7,
        "SpglibTestData/virtual_structure/POSCAR-41-222-26" : 7,
        "SpglibTestData/virtual_structure/POSCAR-43-230-conv-25" : 7,
        "SpglibTestData/virtual_structure/POSCAR-43-230-conv-29" : 7,
        "SpglibTestData/virtual_structure/POSCAR-43-230-prim-22" : 7,
        "SpglibTestData/virtual_structure/POSCAR-43-230-prim-26" : 7,
        "SpglibTestData/virtual_structure/POSCAR-43-bcc-22" : 7,
        "SpglibTestData/virtual_structure/POSCAR-43-bcc-26" : 7,
        "SpglibTestData/virtual_structure/POSCAR-44-227-24" : 7,
        "SpglibTestData/virtual_structure/POSCAR-45-230-conv-24" : 7,
        "SpglibTestData/virtual_structure/POSCAR-45-230-prim-21" : 7,
        "SpglibTestData/virtual_structure/POSCAR-46-227-28" : 7,
        "SpglibTestData/virtual_structure/POSCAR-47-221-08" : 8,
        "SpglibTestData/virtual_structure/POSCAR-47-223-08" : 8,
        "SpglibTestData/virtual_structure/POSCAR-48-222-08" : 8,
        "SpglibTestData/virtual_structure/POSCAR-48-224-08" : 8,
        "SpglibTestData/virtual_structure/POSCAR-5-221-32" : 3,
        "SpglibTestData/virtual_structure/POSCAR-5-222-32" : 3,
        "SpglibTestData/virtual_structure/POSCAR-5-223-32" : 3,
        "SpglibTestData/virtual_structure/POSCAR-5-224-32" : 3,
        "SpglibTestData/virtual_structure/POSCAR-5-227-45" : 3,
        "SpglibTestData/virtual_structure/POSCAR-5-227-75" : 3,
        "SpglibTestData/virtual_structure/POSCAR-5-227-98" : 3,
        "SpglibTestData/virtual_structure/POSCAR-5-230-conv-40" : 3,
        "SpglibTestData/virtual_structure/POSCAR-5-230-conv-43" : 3,
        "SpglibTestData/virtual_structure/POSCAR-5-230-conv-61" : 3,
        "SpglibTestData/virtual_structure/POSCAR-5-230-prim-29" : 3,
        "SpglibTestData/virtual_structure/POSCAR-5-230-prim-32" : 3,
        "SpglibTestData/virtual_structure/POSCAR-5-bcc-29" : 3,
        "SpglibTestData/virtual_structure/POSCAR-5-bcc-32" : 3,
        "SpglibTestData/virtual_structure/POSCAR-51-227-29" : 8,
        "SpglibTestData/virtual_structure/POSCAR-53-227-32" : 8,
        "SpglibTestData/virtual_structure/POSCAR-54-230-conv-30" : 8,
        "SpglibTestData/virtual_structure/POSCAR-6-221-30" : 4,
        "SpglibTestData/virtual_structure/POSCAR-6-223-30" : 4,
        "SpglibTestData/virtual_structure/POSCAR-6-227-79" : 4,
        "SpglibTestData/virtual_structure/POSCAR-61-230-conv-31" : 8,
        "SpglibTestData/virtual_structure/POSCAR-62-227-31" : 8,
        "SpglibTestData/virtual_structure/POSCAR-65-221-09" : 8,
        "SpglibTestData/virtual_structure/POSCAR-66-223-09" : 8,
        "SpglibTestData/virtual_structure/POSCAR-67-224-09" : 8,
        "SpglibTestData/virtual_structure/POSCAR-68-222-09" : 8,
        "SpglibTestData/virtual_structure/POSCAR-7-222-30" : 4,
        "SpglibTestData/virtual_structure/POSCAR-7-224-30" : 4,
        "SpglibTestData/virtual_structure/POSCAR-7-227-78" : 4,
        "SpglibTestData/virtual_structure/POSCAR-7-227-80" : 4,
        "SpglibTestData/virtual_structure/POSCAR-7-230-conv-60" : 4,
        "SpglibTestData/virtual_structure/POSCAR-70-230-conv-11" : 8,
        "SpglibTestData/virtual_structure/POSCAR-70-230-prim-09" : 8,
        "SpglibTestData/virtual_structure/POSCAR-70-bcc-9" : 8,
        "SpglibTestData/virtual_structure/POSCAR-73-230-conv-10" : 8,
        "SpglibTestData/virtual_structure/POSCAR-73-230-prim-08" : 8,
        "SpglibTestData/virtual_structure/POSCAR-74-227-09" : 8,
        "SpglibTestData/virtual_structure/POSCAR-75-221-25" : 9,
        "SpglibTestData/virtual_structure/POSCAR-75-222-25" : 9,
        "SpglibTestData/virtual_structure/POSCAR-76-227-61" : 9,
        "SpglibTestData/virtual_structure/POSCAR-77-223-25" : 9,
        "SpglibTestData/virtual_structure/POSCAR-77-224-25" : 9,
        "SpglibTestData/virtual_structure/POSCAR-78-227-91" : 9,
        "SpglibTestData/virtual_structure/POSCAR-78-230-conv-54" : 9,
        "SpglibTestData/virtual_structure/POSCAR-8-221-31" : 4,
        "SpglibTestData/virtual_structure/POSCAR-8-224-31" : 4,
        "SpglibTestData/virtual_structure/POSCAR-8-227-44" : 4,
        "SpglibTestData/virtual_structure/POSCAR-8-227-97" : 4,
        "SpglibTestData/virtual_structure/POSCAR-80-230-conv-28" : 9,
        "SpglibTestData/virtual_structure/POSCAR-80-230-prim-25" : 9,
        "SpglibTestData/virtual_structure/POSCAR-81-221-24" : 10,
        "SpglibTestData/virtual_structure/POSCAR-81-222-24" : 10,
        "SpglibTestData/virtual_structure/POSCAR-81-223-24" : 10,
        "SpglibTestData/virtual_structure/POSCAR-81-224-24" : 10,
        "SpglibTestData/virtual_structure/POSCAR-81-227-88" : 10,
        "SpglibTestData/virtual_structure/POSCAR-81-230-conv-50" : 10,
        "SpglibTestData/virtual_structure/POSCAR-82-230-conv-27" : 10,
        "SpglibTestData/virtual_structure/POSCAR-82-230-prim-24" : 10,
        "SpglibTestData/virtual_structure/POSCAR-83-221-10" : 11,
        "SpglibTestData/virtual_structure/POSCAR-84-223-10" : 11,
        "SpglibTestData/virtual_structure/POSCAR-85-222-10" : 11,
        "SpglibTestData/virtual_structure/POSCAR-86-224-10" : 11,
        "SpglibTestData/virtual_structure/POSCAR-88-230-conv-12" : 11,
        "SpglibTestData/virtual_structure/POSCAR-88-230-prim-10" : 11,
        "SpglibTestData/virtual_structure/POSCAR-89-221-12" : 12,
        "SpglibTestData/virtual_structure/POSCAR-89-222-12" : 12,
        "SpglibTestData/virtual_structure/POSCAR-9-222-31" : 4,
        "SpglibTestData/virtual_structure/POSCAR-9-223-31" : 4,
        "SpglibTestData/virtual_structure/POSCAR-9-227-43" : 4,
        "SpglibTestData/virtual_structure/POSCAR-9-230-conv-41" : 4,
        "SpglibTestData/virtual_structure/POSCAR-9-230-conv-42" : 4,
        "SpglibTestData/virtual_structure/POSCAR-9-230-prim-30" : 4,
        "SpglibTestData/virtual_structure/POSCAR-9-230-prim-31" : 4,
        "SpglibTestData/virtual_structure/POSCAR-9-bcc-30" : 4,
        "SpglibTestData/virtual_structure/POSCAR-9-bcc-31" : 4,
        "SpglibTestData/virtual_structure/POSCAR-91-227-67" : 12,
        "SpglibTestData/virtual_structure/POSCAR-92-227-35" : 12,
        "SpglibTestData/virtual_structure/POSCAR-92-230-conv-35" : 12,
        "SpglibTestData/virtual_structure/POSCAR-93-223-12" : 12,
        "SpglibTestData/virtual_structure/POSCAR-93-224-12" : 12,
        "SpglibTestData/virtual_structure/POSCAR-95-227-36" : 12,
        "SpglibTestData/virtual_structure/POSCAR-95-230-conv-32" : 12,
        "SpglibTestData/virtual_structure/POSCAR-96-227-69" : 12,
        "SpglibTestData/virtual_structure/POSCAR-98-230-conv-14" : 12,
        "SpglibTestData/virtual_structure/POSCAR-98-230-prim-12" : 12,
        "SpglibTestData/virtual_structure/POSCAR-99-221-13" : 13
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, reference) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type, 1.0)}
          
          let pointGroupNumber: Int? = FindPointGroupNoPartialOccupanciesTests.SKTestPointGroup(unitCell: unitCell, atoms: translatedAtoms, allowPartialOccupancies: false, symmetryPrecision: precision)
          XCTAssertNotNil(pointGroupNumber, "space group \(fileName) not found")
          if let pointGroupNumber = pointGroupNumber
          {
            XCTAssertEqual(pointGroupNumber, reference, "Wrong pointGroup found for \(fileName)")
          }
        }
      }
    }
  }
  
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testFindSpaceGroupDebug()
  {
    let testData: [String: Int] =
      [
        "SpglibTestData/tetragonal/POSCAR-125-2" : 15,
        "SpglibTestData/tetragonal/POSCAR-100-2" : 13,
        "SpglibTestData/tetragonal/POSCAR-111": 14
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, reference) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          //let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)] = reader.atoms.map{($0.fractionalPosition , $0.type, 1.0)}
          
          let pointGroupNumber: Int? = FindPointGroupNoPartialOccupanciesTests.SKTestPointGroup(unitCell: unitCell, atoms: translatedAtoms, allowPartialOccupancies: false, symmetryPrecision: 1e-5)
          XCTAssertNotNil(pointGroupNumber, "space group \(fileName) not found")
          if let pointGroupNumber = pointGroupNumber
          {
            XCTAssertEqual(pointGroupNumber, reference, "Wrong pointGroup found for \(fileName)")
          }
        }
      }
    }
  }
}
