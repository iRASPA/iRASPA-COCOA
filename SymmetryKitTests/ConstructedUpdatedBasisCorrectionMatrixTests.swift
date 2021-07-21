//
//  ConstructedUpdatedBasisTests.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 12/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import SymmetryKit
import simd

class ConstructedUpdatedBasisCorrectionMatrixTests: XCTestCase
{
  let precision: Double = 1e-5
  
  
  func testConstructedUpdatedBasisTriclinicSpaceGroup()
  {
    let testData: [String: SKTransformationMatrix] =
    [
      "SpglibTestData/triclinic/POSCAR-001" : SKTransformationMatrix([1, 0, 0],[0, -1, 0], [0, 0, -1]),
      "SpglibTestData/triclinic/POSCAR-002" : SKTransformationMatrix([1, 0, 0],[0, -1, 0], [0, 0, -1])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let basis: SKTransformationMatrix? = SKSpacegroup.SKTestConstructUpdatedBasis(unitCell: unitCell, atoms: reader.atoms, allowPartialOccupancies: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(basis, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = basis
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
  
  func testConstructedUpdatedBasisMonoclinicSpaceGroup()
  {
    let testData: [String: SKTransformationMatrix] =
    [
      "SpglibTestData/monoclinic/POSCAR-003" : SKTransformationMatrix([0, 1, 0],[-1, 0, 0], [0, 0, 1]),
      "SpglibTestData/monoclinic/POSCAR-004" : SKTransformationMatrix([1, 0, 0],[0, 0, -1], [0, 1, 0]),
      "SpglibTestData/monoclinic/POSCAR-004-2" : SKTransformationMatrix([0, 1, 0],[-1, 0, 0], [0, 0, 1]),
      "SpglibTestData/monoclinic/POSCAR-005" : SKTransformationMatrix([0, 0, 1],[-1, 0, 0], [-1, -2, -1]),
      "SpglibTestData/monoclinic/POSCAR-005-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 1], [0, -1, 1]),
      "SpglibTestData/monoclinic/POSCAR-006" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/monoclinic/POSCAR-006-2" : SKTransformationMatrix([0, 1, 0],[-1, 0, 0], [0, 0, 1]),
      "SpglibTestData/monoclinic/POSCAR-007" : SKTransformationMatrix([1, 0, 0],[0, 0, 1], [0, -1, 0]),
      "SpglibTestData/monoclinic/POSCAR-007-2" : SKTransformationMatrix([0, 1, 0],[-1, 0, 0], [0, 0, 1]),
      "SpglibTestData/monoclinic/POSCAR-008" : SKTransformationMatrix([0, 0, 1],[1, 1, 0], [-1, 1, 0]),
      "SpglibTestData/monoclinic/POSCAR-008-2" : SKTransformationMatrix([1, -1, 0],[1, 1, 0], [0, 1, 1]),
      "SpglibTestData/monoclinic/POSCAR-009" : SKTransformationMatrix([1, 1, 1],[1, 0, 0], [0, 1, -1]),
      "SpglibTestData/monoclinic/POSCAR-009-2" : SKTransformationMatrix([1, 0, 0],[-1, -1, -2], [0, 1, 0]),
      "SpglibTestData/monoclinic/POSCAR-010" : SKTransformationMatrix([0, 1, 0],[-1, 0, 0], [0, 0, 1]),
      "SpglibTestData/monoclinic/POSCAR-010-2" : SKTransformationMatrix([0, 1, 0],[-1, 0, 0], [0, 0, 1]),
      "SpglibTestData/monoclinic/POSCAR-011" : SKTransformationMatrix([0, 1, 0],[-1, 0, 0], [0, 0, 1]),
      "SpglibTestData/monoclinic/POSCAR-011-2" : SKTransformationMatrix([1, 0, 0],[0, 0, -1], [0, 1, 0]),
      "SpglibTestData/monoclinic/POSCAR-012" : SKTransformationMatrix([1, 1, 0],[-1, 1, 0], [0, 0, 1]),
      "SpglibTestData/monoclinic/POSCAR-012-2" : SKTransformationMatrix([1, 1, 0],[-1, 1, 0], [0, 0, 1]),
      "SpglibTestData/monoclinic/POSCAR-012-3" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/monoclinic/POSCAR-013" : SKTransformationMatrix([1, 0, 0],[0, 0, -1], [0, 1, 0]),
      "SpglibTestData/monoclinic/POSCAR-013-2" : SKTransformationMatrix([0, 1, 0],[-1, 0, 0], [0, 0, 1]),
      "SpglibTestData/monoclinic/POSCAR-013-3" : SKTransformationMatrix([0, 1, 0],[-1, 0, 0], [0, 0, 1]),
      "SpglibTestData/monoclinic/POSCAR-014" : SKTransformationMatrix([1, 0, 0],[0, 0, 1], [0, -1, 0]),
      "SpglibTestData/monoclinic/POSCAR-014-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/monoclinic/POSCAR-015" : SKTransformationMatrix([1, 0, 0],[-1, 2, 0], [0, 0, 1]),
      "SpglibTestData/monoclinic/POSCAR-015-2" : SKTransformationMatrix([1, 0, 0],[-1, 2, 0], [0, 0, 1]),
      "SpglibTestData/monoclinic/POSCAR-015-3" : SKTransformationMatrix([1, 0, 0],[0, 1, -1], [0, 1, 1])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let basis: SKTransformationMatrix? = SKSpacegroup.SKTestConstructUpdatedBasis(unitCell: unitCell, atoms: reader.atoms, allowPartialOccupancies: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(basis, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = basis
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
  
  func testConstructedUpdatedBasisOrthorhombicSpaceGroup()
  {
    let testData: [String: SKTransformationMatrix] =
    [
      "SpglibTestData/orthorhombic/POSCAR-016" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-016-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-017-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-018" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-018-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-019" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-019-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-020" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-021" : SKTransformationMatrix([1, 0, 0],[0, 1, -1], [0, 1, 1]),
      "SpglibTestData/orthorhombic/POSCAR-021-2" : SKTransformationMatrix([1, 0, 0],[1, 0, -2], [0, 1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-022" : SKTransformationMatrix([1, 0, 0],[1, 0, -2], [1, 2, 0]),
      "SpglibTestData/orthorhombic/POSCAR-023" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-023-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-024" : SKTransformationMatrix([1, 0, 0],[0, 1, 1], [1, -1, 1]),
      "SpglibTestData/orthorhombic/POSCAR-024-2" : SKTransformationMatrix([1, 0, 0],[1, 1, -1], [0, 1, 1]),
      "SpglibTestData/orthorhombic/POSCAR-025" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-025-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-026" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-026-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-027" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-027-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-028" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-028-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-029" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-029-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-030" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-030-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-031" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-031-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-032" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-032-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-033" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-033-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-033-3" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-034" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-034-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-035" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 0, 2]),
      "SpglibTestData/orthorhombic/POSCAR-035-2" : SKTransformationMatrix([1, 0, 0],[0, 1, -1], [0, 1, 1]),
      "SpglibTestData/orthorhombic/POSCAR-036" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 0, 2]),
      "SpglibTestData/orthorhombic/POSCAR-036-2" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-037" : SKTransformationMatrix([1, 0, 0],[0, 1, -1], [0, 1, 1]),
      "SpglibTestData/orthorhombic/POSCAR-037-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, -1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-038" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 0, 2]),
      "SpglibTestData/orthorhombic/POSCAR-038-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-039" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-039-2" : SKTransformationMatrix([1, 0, 0],[1, 2, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-040" : SKTransformationMatrix([1, 0, 0],[1, 2, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-040-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-041" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-041-2" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-042" : SKTransformationMatrix([1, 1, 0],[1, 1, 2], [1, -1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-043" : SKTransformationMatrix([1, 1, 0],[1, 1, 2], [1, -1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-043-2" : SKTransformationMatrix([1, 1, 0],[1, 1, 2], [1, -1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-044" : SKTransformationMatrix([1, 0, 0],[0, 1, 1], [1, -1, 1]),
      "SpglibTestData/orthorhombic/POSCAR-044-2" : SKTransformationMatrix([1, 0, 0],[0, 1, -1], [1, 1, 1]),
      "SpglibTestData/orthorhombic/POSCAR-045" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-045-2" : SKTransformationMatrix([1, 0, 0],[0, 1, -1], [1, 1, 1]),
      "SpglibTestData/orthorhombic/POSCAR-046" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-046-2" : SKTransformationMatrix([1, 0, 0],[0, 1, -1], [1, 1, 1]),
      "SpglibTestData/orthorhombic/POSCAR-047" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-047-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, -1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-048" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-048-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-049" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-049-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-050" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-050-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-051" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-051-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-051-3" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-052" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-052-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-053" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-053-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-054" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-054-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-055" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-055-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-056" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-056-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-057" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-057-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-058" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-058-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-058-3" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-059" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-059-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-060" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-060-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-060-3" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-061" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-061-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-062" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-062-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-063" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-063-2" : SKTransformationMatrix([1, 0, 0],[-1, 2, 0], [0, 0, 1]),
      "SpglibTestData/orthorhombic/POSCAR-063-3" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-064" : SKTransformationMatrix([1, 0, 0],[1, 0, -2], [0, 1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-064-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, -1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-064-3" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-065" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-065-2" : SKTransformationMatrix([1, 0, 0],[0, 1, -1], [0, 1, 1]),
      "SpglibTestData/orthorhombic/POSCAR-065-3" : SKTransformationMatrix([1, 0, 0],[0, 1, -1], [0, 1, 1]),
      "SpglibTestData/orthorhombic/POSCAR-066" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-066-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, -1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-067" : SKTransformationMatrix([1, 0, 0],[0, 1, -1], [0, 1, 1]),
      "SpglibTestData/orthorhombic/POSCAR-067-2" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-067-3" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-068" : SKTransformationMatrix([1, 0, 0],[1, 0, -2], [0, 1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-068-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, -1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-069" : SKTransformationMatrix([1, 1, 0],[1, 1, 2], [1, -1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-069-2" : SKTransformationMatrix([1, 0, 0],[1, 0, -2], [1, 2, 0]),
      "SpglibTestData/orthorhombic/POSCAR-070" : SKTransformationMatrix([1, 1, 0],[1, 1, 2], [1, -1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-070-2" : SKTransformationMatrix([1, 1, 0],[1, 1, 2], [1, -1, 0]),
      "SpglibTestData/orthorhombic/POSCAR-071" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-071-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-072" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-072-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-073" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-073-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/orthorhombic/POSCAR-074" : SKTransformationMatrix([1, 0, 0],[0, 1, -1], [1, 1, 1]),
      "SpglibTestData/orthorhombic/POSCAR-074-2" : SKTransformationMatrix([1, 0, 0],[0, 1, -1], [1, 1, 1])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let basis: SKTransformationMatrix? = SKSpacegroup.SKTestConstructUpdatedBasis(unitCell: unitCell, atoms: reader.atoms, allowPartialOccupancies: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(basis, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = basis
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
  
  func testConstructedUpdatedBasisTetragonalSpaceGroup()
  {
    let testData: [String: SKTransformationMatrix] =
    [
      "SpglibTestData/tetragonal/POSCAR-075" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-075-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-076" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-076-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-077" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-077-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-077-3" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-078" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-078-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-079" : SKTransformationMatrix([1, 1, -1],[0, 1, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-079-2" : SKTransformationMatrix([1, 1, -1],[0, 1, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-080" : SKTransformationMatrix([1, 1, -1],[0, 1, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-080-2" : SKTransformationMatrix([1, 1, -1],[0, 1, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-081" : SKTransformationMatrix([0, 0, -1],[0, 1, 0], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-081-2" : SKTransformationMatrix([0, 0, -1],[0, 1, 0], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-082" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-082-2" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-083" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-083-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-083-3" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-084" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-084-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-085" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-085-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-086" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-086-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-087" : SKTransformationMatrix([-1, -1, 0],[1, 0, 1], [0, 1, 1]),
      "SpglibTestData/tetragonal/POSCAR-087-2" : SKTransformationMatrix([1, 1, -1],[0, 1, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-088" : SKTransformationMatrix([1, 1, -1],[0, 1, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-088-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-090" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-090-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-091" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-091-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-092" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-092-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-092-3" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-094" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-094-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-094-3" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-095" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-095-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-096" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-096-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-097" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-097-2" : SKTransformationMatrix([-1, -1, 0],[1, 0, 1], [0, 1, 1]),
      "SpglibTestData/tetragonal/POSCAR-098" : SKTransformationMatrix([1, 1, -1],[0, 1, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-098-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-099" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-099-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-100" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-100-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-102" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-102-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-103" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-103-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-104" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-104-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-105" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-105-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-106" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-107" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-107-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-107-3" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-108" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-108-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-109" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-109-2" : SKTransformationMatrix([1, 1, -1],[0, 1, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-110" : SKTransformationMatrix([1, 1, -1],[0, 1, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-110-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-111" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-111-2" : SKTransformationMatrix([0, 0, -1],[0, 1, 0], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-112" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-112-2" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-113" : SKTransformationMatrix([0, 0, -1],[0, 1, 0], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-113-2" : SKTransformationMatrix([0, 0, -1],[0, 1, 0], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-114" : SKTransformationMatrix([0, 0, -1],[0, 1, 0], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-114-2" : SKTransformationMatrix([0, 0, -1],[0, 1, 0], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-115" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-115-2" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-115-3" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-115-4" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-115-5" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-116" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-116-2" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-117" : SKTransformationMatrix([0, 0, -1],[0, 1, 0], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-117-2" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-118" : SKTransformationMatrix([0, 0, -1],[0, 1, 0], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-118-2" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-119" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-119-2" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-120" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-120-2" : SKTransformationMatrix([-1, -1, 0],[1, 0, 1], [0, 1, 1]),
      "SpglibTestData/tetragonal/POSCAR-121" : SKTransformationMatrix([-1, -1, 0],[1, 0, 1], [0, 1, 1]),
      "SpglibTestData/tetragonal/POSCAR-121-2" : SKTransformationMatrix([-1, -1, 0],[1, 0, 1], [0, 1, 1]),
      "SpglibTestData/tetragonal/POSCAR-122" : SKTransformationMatrix([1, 1, -1],[0, 1, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-122-2" : SKTransformationMatrix([-1, -1, 0],[1, 0, 1], [0, 1, 1]),
      "SpglibTestData/tetragonal/POSCAR-122-3" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-123" : SKTransformationMatrix([1, 1, -1],[0, 1, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-123-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-123-3" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-124" : SKTransformationMatrix([-1, -1, 0],[1, 0, 1], [0, 1, 1]),
      "SpglibTestData/tetragonal/POSCAR-124-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-125" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-125-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-126" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-126-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-127" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-127-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-128" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-128-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-129" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-129-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-129-3" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-130" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-130-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-131" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-131-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-132" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-132-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-133" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-133-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-134" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-134-2" : SKTransformationMatrix([1, 1, 0],[0, 1, 1], [1, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-135" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-135-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-136" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-136-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-136-3" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-136-4" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-136-5" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-137" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-137-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-137-3" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-138" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-138-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/tetragonal/POSCAR-139" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-139-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-140" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-140-2" : SKTransformationMatrix([1, 1, -1],[0, 1, 1], [1, 0, 0]),
      "SpglibTestData/tetragonal/POSCAR-141" : SKTransformationMatrix([-1, -1, 0],[1, 0, 1], [0, 1, 1]),
      "SpglibTestData/tetragonal/POSCAR-141-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-142" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-142-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [1, 1, 2]),
      "SpglibTestData/tetragonal/POSCAR-142-3" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let basis: SKTransformationMatrix? = SKSpacegroup.SKTestConstructUpdatedBasis(unitCell: unitCell, atoms: reader.atoms, allowPartialOccupancies: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(basis, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = basis
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
  
  func testConstructedUpdatedBasisTrigonalSpaceGroup()
  {
    let testData: [String: SKTransformationMatrix] =
    [
      "SpglibTestData/trigonal/POSCAR-143" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-143-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-144" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-144-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-145" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-145-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-146" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/trigonal/POSCAR-146-2" : SKTransformationMatrix([1, 0, -1],[0, 1, 1], [1, -1, 1]),
      "SpglibTestData/trigonal/POSCAR-147" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-147-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-148" : SKTransformationMatrix([0, 1, 1],[-1, -1, 0], [1, -1, 1]),
      "SpglibTestData/trigonal/POSCAR-148-2" : SKTransformationMatrix([0, 1, -1],[1, 1, 2], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-149" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-149-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-150" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-150-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-151" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-151-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-152" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-152-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-153" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-154" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-154-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-154-3" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-155" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/trigonal/POSCAR-155-2" : SKTransformationMatrix([1, 0, -1],[0, 1, 1], [1, -1, 1]),
      "SpglibTestData/trigonal/POSCAR-156" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-156-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-157" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-157-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-158" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-158-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-159" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-159-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-160" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/trigonal/POSCAR-160-2" : SKTransformationMatrix([1, 0, -1],[0, 1, 1], [1, -1, 1]),
      "SpglibTestData/trigonal/POSCAR-161" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [2, 1, 3]),
      "SpglibTestData/trigonal/POSCAR-161-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [2, 1, 3]),
      "SpglibTestData/trigonal/POSCAR-162" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-162-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-163" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-163-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-164" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-164-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-165" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/trigonal/POSCAR-165-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/trigonal/POSCAR-166" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [2, 1, 3]),
      "SpglibTestData/trigonal/POSCAR-166-2" : SKTransformationMatrix([0, 1, 1],[-1, -1, 0], [1, -1, 1]),
      "SpglibTestData/trigonal/POSCAR-167" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [2, 1, 3]),
      "SpglibTestData/trigonal/POSCAR-167-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [2, 1, 3]),
      "SpglibTestData/trigonal/POSCAR-167-3" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [2, 1, 3])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let basis: SKTransformationMatrix? = SKSpacegroup.SKTestConstructUpdatedBasis(unitCell: unitCell, atoms: reader.atoms, allowPartialOccupancies: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(basis, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = basis
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
  
  func testConstructedUpdatedBasisHexagonalSpaceGroup()
  {
    let testData: [String: SKTransformationMatrix] =
    [
      "SpglibTestData/hexagonal/POSCAR-168" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-169" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-169-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-170" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-170-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-171" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-171-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-172" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-173" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-173-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-174" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-174-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-175" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-175-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-176" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-176-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-177" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-179" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-179-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-180" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-180-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-181" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-181-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-182" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-182-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-183" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-183-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-184" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-184-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-185" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-185-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-186" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-186-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-187" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-187-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-188" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-188-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-189" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-189-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-190" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-190-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-191" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-191-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-192" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-192-2" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-193" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/hexagonal/POSCAR-193-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-194" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/hexagonal/POSCAR-194-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let basis: SKTransformationMatrix? = SKSpacegroup.SKTestConstructUpdatedBasis(unitCell: unitCell, atoms: reader.atoms, allowPartialOccupancies: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(basis, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = basis
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
  
  func testConstructedUpdatedBasisCubicSpaceGroup()
  {
    let testData: [String: SKTransformationMatrix] =
    [
      "SpglibTestData/cubic/POSCAR-195" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-195-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-196" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-196-2" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-197" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-197-2" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-198" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-198-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-199" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-199-2" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-200" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-200-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-205" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-205-3" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-206" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-206-2" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-207" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-208" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-208-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-209" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-210" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-210-2" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-211" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-212" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-212-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-213" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-213-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-214" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-214-2" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-215" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-215-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-216" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-216-2" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-217" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-217-2" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-218" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-218-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-219" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-219-2" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-220" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-220-2" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-221" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-221-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-222" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-222-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-223" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-223-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-224" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-224-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-225" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-225-2" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/cubic/POSCAR-226" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-226-2" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-227" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-227-2" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-228" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-228-2" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/cubic/POSCAR-229" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-229-2" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-230" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-230-2" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-230-3" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/cubic/POSCAR-230-4" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let basis: SKTransformationMatrix? = SKSpacegroup.SKTestConstructUpdatedBasis(unitCell: unitCell, atoms: reader.atoms, allowPartialOccupancies: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(basis, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = basis
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
  
 
 
 
  
  func testUpdatedBasisVirtualSpaceGroup()
  {
    let testData: [String: SKTransformationMatrix] =
    [
      "SpglibTestData/virtual_structure/POSCAR-1-221-33" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-1-222-33" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-1-223-33" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-1-224-33" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-1-227-73" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-1-227-93" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-1-227-99" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-1-230-conv-56" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-1-230-prim-33" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-1-bcc-33" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-10-221-18" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-10-223-18" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-10-227-50" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-102-224-13" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-104-222-13" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-105-223-13" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-109-227-13" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-11-227-48" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-110-230-conv-15" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-110-230-prim-13" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-111-221-11" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-111-224-11" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-111-227-66" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-112-222-11" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-112-223-11" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-113-227-68" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-115-221-14" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-115-223-14" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-115-227-33" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-116-230-conv-34" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-117-230-conv-33" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-118-222-14" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-118-224-14" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-12-221-19" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-12-224-19" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-12-227-21" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-12-227-83" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-120-230-conv-16" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-120-230-prim-14" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-122-230-conv-13" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-122-230-prim-11" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-123-221-05" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-126-222-05" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-13-222-18" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-13-224-18" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-13-227-49" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-13-230-conv-44" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-131-223-05" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-134-224-05" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-14-227-47" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-14-227-51" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-14-230-conv-45" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-142-230-conv-05" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-142-230-prim-05" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-146-221-27" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-146-222-27" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-146-223-27" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-146-224-27" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-146-227-92" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-146-230-conv-36" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-146-230-conv-55" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-146-230-prim-27" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-146-bcc-27" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-148-221-15" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-148-222-15" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-148-223-15" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-148-224-15" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-148-227-70" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-148-230-conv-17" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-148-230-conv-37" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-148-230-prim-15" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-148-bcc-15" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-15-222-19" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-15-223-19" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-15-230-conv-21" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-15-230-conv-22" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-15-230-prim-18" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-15-230-prim-19" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-15-bcc-18" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-15-bcc-19" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-155-221-17" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-155-222-17" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-155-223-17" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-155-224-17" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-155-227-72" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-155-230-conv-19" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-155-230-conv-38" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-155-230-prim-17" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-155-bcc-17" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-16-221-20" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-16-222-20" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-16-223-20" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-16-224-20" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-16-227-84" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-160-221-16" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-160-224-16" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-160-227-16" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-160-227-71" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-160-fcc" : SKTransformationMatrix([-1, -1, -1],[0, 0, 1], [-1, 2, 1]),
      "SpglibTestData/virtual_structure/POSCAR-161-222-16" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-161-223-16" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-161-230-conv-18" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-161-230-prim-16" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-161-bcc-16" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-166-221-06" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-166-224-06" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-166-227-06" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-166-227-38" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-167-222-06" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-167-223-06" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-167-230-conv-06" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-167-230-prim-06" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-167-bcc-6" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-17-227-60" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-17-227-85" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-17-230-conv-46" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-18-227-86" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-19-227-59" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-19-227-89" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-19-230-conv-51" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-195-221-07" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-195-222-07" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-195-223-07" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-195-224-07" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-198-227-40" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-198-230-conv-20" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-199-230-conv-07" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-199-230-prim-07" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-2-221-28" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-222-28" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-223-28" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-224-28" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-227-41" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-227-74" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-227-94" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-230-conv-39" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-2-230-conv-57" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-2-230-prim-28" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-2-bcc-28" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-20-227-53" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-20-227-90" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-20-230-conv-53" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-200-221-02" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-200-223-02" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-201-222-02" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-201-224-02" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-205-230-conv-08" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-206-230-conv-02" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-206-230-prim-02" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-207-221-04" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-207-222-04" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-208-223-04" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-208-224-04" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-21-221-23" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-21-222-23" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-21-223-23" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-21-224-23" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-21-230-conv-49" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-212-227-19" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-213-230-conv-09" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-214-230-conv-04" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-214-230-prim-04" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-215-221-03" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-215-224-03" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-215-227-18" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-216-227-03" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-218-222-03" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-218-223-03" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-22-230-conv-26" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-22-230-prim-23" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-220-230-conv-03" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-220-230-prim-03" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-221-221-01" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-222-222-01" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-223-223-01" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-224-224-01" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-227-227-01" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-230-230-conv-01" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-230-230-conv-62" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-230-230-prim-01" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-24-230-conv-23" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-24-230-prim-20" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-25-221-21" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-25-223-21" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-25-227-54" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-26-227-64" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-27-230-conv-48" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-28-227-62" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-29-230-conv-52" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-3-221-29" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-3-222-29" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-3-223-29" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-3-224-29" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-3-227-82" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-3-227-95" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-3-230-conv-58" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-30-227-65" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-31-227-58" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-32-230-conv-47" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-33-227-63" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-34-222-21" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-34-224-21" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-35-221-22" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-35-224-22" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-35-227-87" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-37-222-22" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-37-223-22" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-38-221-26" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-39-224-26" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-4-227-77" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-4-227-81" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-4-227-96" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-4-230-conv-59" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-40-223-26" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-41-222-26" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-43-230-conv-25" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-43-230-conv-29" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-43-230-prim-22" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-43-230-prim-26" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-43-bcc-22" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-43-bcc-26" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-44-227-24" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-45-230-conv-24" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-45-230-prim-21" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-46-227-28" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-47-221-08" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-47-223-08" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-48-222-08" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-48-224-08" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-5-221-32" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-5-222-32" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-5-223-32" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-5-224-32" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-5-227-45" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-5-227-75" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-5-227-98" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-5-230-conv-40" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-5-230-conv-43" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-5-230-conv-61" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-5-230-prim-29" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-5-230-prim-32" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-5-bcc-29" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-5-bcc-32" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-51-227-29" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-53-227-32" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-54-230-conv-30" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-6-221-30" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-6-223-30" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-6-227-79" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-61-230-conv-31" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-62-227-31" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-65-221-09" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-66-223-09" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-67-224-09" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-68-222-09" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-7-222-30" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-7-224-30" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-7-227-78" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-7-227-80" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-7-230-conv-60" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-70-230-conv-11" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-70-230-prim-09" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-70-bcc-9" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-73-230-conv-10" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-73-230-prim-08" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-74-227-09" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-75-221-25" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-75-222-25" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-76-227-61" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-77-223-25" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-77-224-25" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-78-227-91" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-78-230-conv-54" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-8-221-31" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-8-224-31" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-8-227-44" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-8-227-97" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-80-230-conv-28" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-80-230-prim-25" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-81-221-24" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-81-222-24" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-81-223-24" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-81-224-24" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-81-227-88" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-81-230-conv-50" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-82-230-conv-27" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-82-230-prim-24" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-83-221-10" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-84-223-10" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-85-222-10" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-86-224-10" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-88-230-conv-12" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-88-230-prim-10" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-89-221-12" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-89-222-12" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-9-222-31" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-9-223-31" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-9-227-43" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-9-230-conv-41" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-9-230-conv-42" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-9-230-prim-30" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-9-230-prim-31" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-9-bcc-30" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-9-bcc-31" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-91-227-67" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-92-227-35" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-92-230-conv-35" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-93-223-12" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-93-224-12" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-95-227-36" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-95-230-conv-32" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-96-227-69" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-98-230-conv-14" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-98-230-prim-12" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-99-221-13" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let basis: SKTransformationMatrix? = SKSpacegroup.SKTestConstructUpdatedBasis(unitCell: unitCell, atoms: reader.atoms, allowPartialOccupancies: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(basis, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = basis
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
}
