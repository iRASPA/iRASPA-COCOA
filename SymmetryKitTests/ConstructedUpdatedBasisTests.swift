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

class ConstructedUpdatedBasisTests: XCTestCase
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
          let basis: SKTransformationMatrix? = SKSpacegroup.SKTestConstructUpdatedBasis(unitCell: unitCell, atoms: reader.atoms, symmetryPrecision: precision)
                   
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
          let basis: SKTransformationMatrix? = SKSpacegroup.SKTestConstructUpdatedBasis(unitCell: unitCell, atoms: reader.atoms, symmetryPrecision: precision)
                   
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
      "SpglibTestData/virtual_structure/POSCAR-1-227-73" : SKTransformationMatrix([0, 1, 0],[-1, 0, 0], [0, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-1-227-93" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-1-227-99" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-1-230-conv-56" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-1-230-prim-33" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-1-bcc-33" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-10-221-18" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-10-223-18" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-10-227-50" : SKTransformationMatrix([0, 1, 0],[-1, 0, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-102-224-13" : SKTransformationMatrix([0, 0, 1],[1, 0, 0], [0, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-104-222-13" : SKTransformationMatrix([0, 0, 1],[1, 0, 0], [0, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-105-223-13" : SKTransformationMatrix([0, 0, 1],[1, 0, 0], [0, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-109-227-13" : SKTransformationMatrix([0, 1, 0],[-1, -1, -1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-11-227-48" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-110-230-conv-15" : SKTransformationMatrix([1, 1, 0],[0, 1, 1], [1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-110-230-prim-13" : SKTransformationMatrix([-1, -1, 0],[1, 0, 1], [0, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-111-221-11" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-111-224-11" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-111-227-66" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-112-222-11" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-112-223-11" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-113-227-68" : SKTransformationMatrix([1, 0, 0],[0, 0, -1], [0, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-115-221-14" : SKTransformationMatrix([1, 0, 0],[0, 0, -1], [0, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-115-223-14" : SKTransformationMatrix([1, 0, 0],[0, 0, -1], [0, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-115-227-33" : SKTransformationMatrix([0, -1, 0],[1, 0, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-116-230-conv-34" : SKTransformationMatrix([1, 0, 0],[0, 0, -1], [0, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-117-230-conv-33" : SKTransformationMatrix([1, 0, 0],[0, 0, -1], [0, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-118-222-14" : SKTransformationMatrix([1, 0, 0],[0, 0, -1], [0, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-118-224-14" : SKTransformationMatrix([1, 0, 0],[0, 0, -1], [0, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-12-221-19" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-12-224-19" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-12-227-21" : SKTransformationMatrix([0, 0, 1],[-1, 0, 0], [-1, -2, -1]),
      "SpglibTestData/virtual_structure/POSCAR-12-227-83" : SKTransformationMatrix([0, 0, 1],[-1, -1, 0], [1, -1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-120-230-conv-16" : SKTransformationMatrix([1, 1, 0],[0, 1, 1], [1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-120-230-prim-14" : SKTransformationMatrix([-1, -1, 0],[1, 0, 1], [0, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-122-230-conv-13" : SKTransformationMatrix([-1, -1, 0],[1, 0, 1], [0, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-122-230-prim-11" : SKTransformationMatrix([1, 1, 0],[0, 1, 1], [1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-123-221-05" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-126-222-05" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-13-222-18" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-13-224-18" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-13-227-49" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-13-230-conv-44" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-131-223-05" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-134-224-05" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-14-227-47" : SKTransformationMatrix([0, 1, 0],[0, 0, 1], [1, 0, 0]),
      "SpglibTestData/virtual_structure/POSCAR-14-227-51" : SKTransformationMatrix([0, 1, 0],[-1, 0, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-14-230-conv-45" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-142-230-conv-05" : SKTransformationMatrix([-1, -1, 0],[1, 0, 1], [0, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-142-230-prim-05" : SKTransformationMatrix([1, 1, 0],[0, 1, 1], [1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-146-221-27" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-146-222-27" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-146-223-27" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-146-224-27" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-146-227-92" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-146-230-conv-36" : SKTransformationMatrix([0, 1, -1],[1, 1, 2], [1, 0, 0]),
      "SpglibTestData/virtual_structure/POSCAR-146-230-conv-55" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-146-230-prim-27" : SKTransformationMatrix([1, -1, 0],[1, 2, 1], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-146-bcc-27" : SKTransformationMatrix([1, -1, 0],[1, 2, 1], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-148-221-15" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-148-222-15" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-148-223-15" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-148-224-15" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-148-227-70" : SKTransformationMatrix([1, 0, -1],[0, 1, 1], [1, -1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-148-230-conv-17" : SKTransformationMatrix([0, 1, -1],[1, 1, 2], [1, 0, 0]),
      "SpglibTestData/virtual_structure/POSCAR-148-230-conv-37" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-148-230-prim-15" : SKTransformationMatrix([1, -1, 0],[1, 2, 1], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-148-bcc-15" : SKTransformationMatrix([1, -1, 0],[1, 2, 1], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-15-222-19" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-15-223-19" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-15-230-conv-21" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-15-230-conv-22" : SKTransformationMatrix([1, 0, 0],[0, -1, 1], [-1, -1, -1]),
      "SpglibTestData/virtual_structure/POSCAR-15-230-prim-18" : SKTransformationMatrix([1, 1, 0],[0, 1, 1], [1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-15-230-prim-19" : SKTransformationMatrix([1, 0, 0],[1, 2, 1], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-15-bcc-18" : SKTransformationMatrix([1, 1, 0],[0, 1, 1], [1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-15-bcc-19" : SKTransformationMatrix([1, 0, 0],[1, 2, 1], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-155-221-17" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-155-222-17" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-155-223-17" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-155-224-17" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-155-227-72" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-155-230-conv-19" : SKTransformationMatrix([0, 1, -1],[1, 1, 2], [1, 0, 0]),
      "SpglibTestData/virtual_structure/POSCAR-155-230-conv-38" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-155-230-prim-17" : SKTransformationMatrix([1, -1, 0],[1, 2, 1], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-155-bcc-17" : SKTransformationMatrix([1, -1, 0],[1, 2, 1], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-16-221-20" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-16-222-20" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-16-223-20" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-16-224-20" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-16-227-84" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-160-221-16" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-160-224-16" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-160-227-16" : SKTransformationMatrix([0, 1, 1],[1, 0, 0], [1, 2, -1]),
      "SpglibTestData/virtual_structure/POSCAR-160-227-71" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-160-fcc" : SKTransformationMatrix([-1, -1, -1],[0, 0, 1], [-1, 2, 1]),
      "SpglibTestData/virtual_structure/POSCAR-161-222-16" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-161-223-16" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-161-230-conv-18" : SKTransformationMatrix([0, 1, -1],[1, 1, 2], [1, 0, 0]),
      "SpglibTestData/virtual_structure/POSCAR-161-230-prim-16" : SKTransformationMatrix([1, -1, 0],[1, 2, 1], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-161-bcc-16" : SKTransformationMatrix([1, -1, 0],[1, 2, 1], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-166-221-06" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-166-224-06" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-166-227-06" : SKTransformationMatrix([0, 1, 1],[1, 0, 0], [1, 2, -1]),
      "SpglibTestData/virtual_structure/POSCAR-166-227-38" : SKTransformationMatrix([1, 0, -1],[0, 1, 1], [1, -1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-167-222-06" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-167-223-06" : SKTransformationMatrix([0, 1, -1],[-1, 0, 1], [1, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-167-230-conv-06" : SKTransformationMatrix([0, 1, -1],[1, 1, 2], [1, 0, 0]),
      "SpglibTestData/virtual_structure/POSCAR-167-230-prim-06" : SKTransformationMatrix([1, -1, 0],[1, 2, 1], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-167-bcc-6" : SKTransformationMatrix([1, -1, 0],[1, 2, 1], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-17-227-60" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-17-227-85" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-17-230-conv-46" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-18-227-86" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-19-227-59" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-19-227-89" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-19-230-conv-51" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-195-221-07" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-195-222-07" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-195-223-07" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-195-224-07" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-198-227-40" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-198-230-conv-20" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-199-230-conv-07" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-199-230-prim-07" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-2-221-28" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-222-28" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-223-28" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-224-28" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-227-41" : SKTransformationMatrix([0, 1, 0],[-1, 0, 0], [0, 1, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-227-74" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-227-94" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-230-conv-39" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-230-conv-57" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-230-prim-28" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-2-bcc-28" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-20-227-53" : SKTransformationMatrix([0, 0, 1],[1, -1, 0], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-20-227-90" : SKTransformationMatrix([0, 1, 0],[-1, 0, 1], [1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-20-230-conv-53" : SKTransformationMatrix([0, 1, 0],[-1, 0, 1], [1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-200-221-02" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-200-223-02" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-201-222-02" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-201-224-02" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-205-230-conv-08" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-206-230-conv-02" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-206-230-prim-02" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-207-221-04" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-207-222-04" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-208-223-04" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-208-224-04" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-21-221-23" : SKTransformationMatrix([0, 1, 0],[-1, 0, 1], [1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-21-222-23" : SKTransformationMatrix([0, 1, 0],[-1, 0, 1], [1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-21-223-23" : SKTransformationMatrix([0, 1, 0],[-1, 0, 1], [1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-21-224-23" : SKTransformationMatrix([0, 1, 0],[-1, 0, 1], [1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-21-230-conv-49" : SKTransformationMatrix([0, 1, 0],[-1, 0, 1], [1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-212-227-19" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-213-230-conv-09" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-214-230-conv-04" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-214-230-prim-04" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-215-221-03" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-215-224-03" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-215-227-18" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-216-227-03" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-218-222-03" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-218-223-03" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-22-230-conv-26" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-22-230-prim-23" : SKTransformationMatrix([0, 1, 1],[2, 1, 1], [0, 1, -1]),
      "SpglibTestData/virtual_structure/POSCAR-220-230-conv-03" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-220-230-prim-03" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0]),
      "SpglibTestData/virtual_structure/POSCAR-221-221-01" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-222-222-01" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-223-223-01" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-224-224-01" : SKTransformationMatrix([1, 0, 0],[0, 1, 0], [0, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-227-227-01" : SKTransformationMatrix([1, 0, 1],[1, 2, 1], [-1, 0, 1]),
      "SpglibTestData/virtual_structure/POSCAR-230-230-conv-01" : SKTransformationMatrix([0, 1, 1],[1, 0, 1], [1, 1, 0])
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
          let basis: SKTransformationMatrix? = SKSpacegroup.SKTestConstructUpdatedBasis(unitCell: unitCell, atoms: reader.atoms, symmetryPrecision: precision)
                   
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
