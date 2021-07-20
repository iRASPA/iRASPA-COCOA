//
//  SpaceGroupCenteringTests.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 13/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import SymmetryKit
import simd

class SpaceGroupCenteringTests: XCTestCase
{
  let precision: Double = 1e-5
  
  func testCenteringTriclinicSpaceGroup()
  {
    let testData: [String: Int] =
    [
      "SpglibTestData/triclinic/POSCAR-001" : 1,
      "SpglibTestData/triclinic/POSCAR-002" : 1
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referenceCentering) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let centering: SKSpacegroup.Centring? = SKSpacegroup.SKFindSpaceGroupCentering(unitCell: unitCell, atoms: reader.atoms, allowOverlappingAtomTypes: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(centering, "centering \(fileName) not found")
          if let centering = centering
          {
            XCTAssertEqual(centering.rawValue, referenceCentering, "Wrong centering found for \(fileName): \(centering.rawValue) should be \(referenceCentering)")
          }
        }
      }
    }
  }
  
  func testCenteringMonoclinicSpaceGroup()
  {
    let testData: [String: Int] =
    [
      "SpglibTestData/monoclinic/POSCAR-003" : 1,
      "SpglibTestData/monoclinic/POSCAR-004" : 1,
      "SpglibTestData/monoclinic/POSCAR-004-2" : 1,
      "SpglibTestData/monoclinic/POSCAR-005" : 6,
      "SpglibTestData/monoclinic/POSCAR-005-2" : 6,
      "SpglibTestData/monoclinic/POSCAR-006" : 1,
      "SpglibTestData/monoclinic/POSCAR-006-2" : 1,
      "SpglibTestData/monoclinic/POSCAR-007" : 1,
      "SpglibTestData/monoclinic/POSCAR-007-2" : 1,
      "SpglibTestData/monoclinic/POSCAR-008" : 6,
      "SpglibTestData/monoclinic/POSCAR-008-2" : 6,
      "SpglibTestData/monoclinic/POSCAR-009" : 6,
      "SpglibTestData/monoclinic/POSCAR-009-2" : 6,
      "SpglibTestData/monoclinic/POSCAR-010" : 1,
      "SpglibTestData/monoclinic/POSCAR-010-2" : 1,
      "SpglibTestData/monoclinic/POSCAR-011" : 1,
      "SpglibTestData/monoclinic/POSCAR-011-2" : 1,
      "SpglibTestData/monoclinic/POSCAR-012" : 6,
      "SpglibTestData/monoclinic/POSCAR-012-2" : 6,
      "SpglibTestData/monoclinic/POSCAR-012-3" : 6,
      "SpglibTestData/monoclinic/POSCAR-013" : 1,
      "SpglibTestData/monoclinic/POSCAR-013-2" : 1,
      "SpglibTestData/monoclinic/POSCAR-013-3" : 1,
      "SpglibTestData/monoclinic/POSCAR-014" : 1,
      "SpglibTestData/monoclinic/POSCAR-014-2" : 1,
      "SpglibTestData/monoclinic/POSCAR-015" : 6,
      "SpglibTestData/monoclinic/POSCAR-015-2" : 6,
      "SpglibTestData/monoclinic/POSCAR-015-3" : 6
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referenceCentering) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let centering: SKSpacegroup.Centring? = SKSpacegroup.SKFindSpaceGroupCentering(unitCell: unitCell, atoms: reader.atoms, allowOverlappingAtomTypes: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(centering, "centering \(fileName) not found")
          if let centering = centering
          {
            XCTAssertEqual(centering.rawValue, referenceCentering, "Wrong centering found for \(fileName): \(centering.rawValue) should be \(referenceCentering)")
          }
        }
      }
    }
  }
  
  func testCenteringOrthorhombicSpaceGroup()
  {
    let testData: [String: Int] =
    [
      "SpglibTestData/orthorhombic/POSCAR-016" : 1,
      "SpglibTestData/orthorhombic/POSCAR-016-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-017-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-018" : 1,
      "SpglibTestData/orthorhombic/POSCAR-018-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-019" : 1,
      "SpglibTestData/orthorhombic/POSCAR-019-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-020" : 6,
      "SpglibTestData/orthorhombic/POSCAR-021" : 6,
      "SpglibTestData/orthorhombic/POSCAR-021-2" : 6,
      "SpglibTestData/orthorhombic/POSCAR-022" : 3,
      "SpglibTestData/orthorhombic/POSCAR-023" : 2,
      "SpglibTestData/orthorhombic/POSCAR-023-2" : 2,
      //"SpglibTestData/orthorhombic/POSCAR-024" : 2,
      "SpglibTestData/orthorhombic/POSCAR-024-2" : 2,
      "SpglibTestData/orthorhombic/POSCAR-025" : 1,
      "SpglibTestData/orthorhombic/POSCAR-025-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-026" : 1,
      "SpglibTestData/orthorhombic/POSCAR-026-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-027" : 1,
      "SpglibTestData/orthorhombic/POSCAR-027-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-028" : 1,
      "SpglibTestData/orthorhombic/POSCAR-028-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-029" : 1,
      "SpglibTestData/orthorhombic/POSCAR-029-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-030" : 1,
      "SpglibTestData/orthorhombic/POSCAR-030-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-031" : 1,
      "SpglibTestData/orthorhombic/POSCAR-031-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-032" : 1,
      "SpglibTestData/orthorhombic/POSCAR-032-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-033" : 1,
      "SpglibTestData/orthorhombic/POSCAR-033-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-033-3" : 1,
      "SpglibTestData/orthorhombic/POSCAR-034" : 1,
      "SpglibTestData/orthorhombic/POSCAR-034-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-035" : 6,
      "SpglibTestData/orthorhombic/POSCAR-035-2" : 6,
      "SpglibTestData/orthorhombic/POSCAR-036" : 6,
      "SpglibTestData/orthorhombic/POSCAR-036-2" : 6,
      "SpglibTestData/orthorhombic/POSCAR-037" : 6,
      "SpglibTestData/orthorhombic/POSCAR-037-2" : 6,
      "SpglibTestData/orthorhombic/POSCAR-038" : 6,
      "SpglibTestData/orthorhombic/POSCAR-038-2" : 6,
      "SpglibTestData/orthorhombic/POSCAR-039" : 6,
      "SpglibTestData/orthorhombic/POSCAR-039-2" : 6,
      "SpglibTestData/orthorhombic/POSCAR-040" : 6,
      "SpglibTestData/orthorhombic/POSCAR-040-2" : 6,
      "SpglibTestData/orthorhombic/POSCAR-041" : 6,
      "SpglibTestData/orthorhombic/POSCAR-041-2" : 6,
      "SpglibTestData/orthorhombic/POSCAR-042" : 3,
      "SpglibTestData/orthorhombic/POSCAR-043" : 3,
      "SpglibTestData/orthorhombic/POSCAR-043-2" : 3,
      "SpglibTestData/orthorhombic/POSCAR-044" : 2,
      "SpglibTestData/orthorhombic/POSCAR-044-2" : 2,
      "SpglibTestData/orthorhombic/POSCAR-045" : 2,
      "SpglibTestData/orthorhombic/POSCAR-045-2" : 2,
      "SpglibTestData/orthorhombic/POSCAR-046" : 2,
      "SpglibTestData/orthorhombic/POSCAR-046-2" : 2,
      "SpglibTestData/orthorhombic/POSCAR-047" : 1,
      "SpglibTestData/orthorhombic/POSCAR-047-2" : 6,
      "SpglibTestData/orthorhombic/POSCAR-048" : 1,
      "SpglibTestData/orthorhombic/POSCAR-048-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-049" : 1,
      "SpglibTestData/orthorhombic/POSCAR-049-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-050" : 1,
      "SpglibTestData/orthorhombic/POSCAR-050-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-051" : 1,
      "SpglibTestData/orthorhombic/POSCAR-051-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-051-3" : 1,
      "SpglibTestData/orthorhombic/POSCAR-052" : 1,
      "SpglibTestData/orthorhombic/POSCAR-052-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-053" : 1,
      "SpglibTestData/orthorhombic/POSCAR-053-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-054" : 1,
      "SpglibTestData/orthorhombic/POSCAR-054-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-055" : 1,
      "SpglibTestData/orthorhombic/POSCAR-055-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-056" : 1,
      "SpglibTestData/orthorhombic/POSCAR-056-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-057" : 1,
      "SpglibTestData/orthorhombic/POSCAR-057-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-058" : 1,
      "SpglibTestData/orthorhombic/POSCAR-058-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-058-3" : 1,
      "SpglibTestData/orthorhombic/POSCAR-059" : 1,
      "SpglibTestData/orthorhombic/POSCAR-059-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-060" : 1,
      "SpglibTestData/orthorhombic/POSCAR-060-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-060-3" : 1,
      "SpglibTestData/orthorhombic/POSCAR-061" : 1,
      "SpglibTestData/orthorhombic/POSCAR-061-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-062" : 1,
      "SpglibTestData/orthorhombic/POSCAR-062-2" : 1,
      "SpglibTestData/orthorhombic/POSCAR-063" : 6,
      "SpglibTestData/orthorhombic/POSCAR-063-2" : 6,
      "SpglibTestData/orthorhombic/POSCAR-063-3" : 6,
      "SpglibTestData/orthorhombic/POSCAR-064" : 6,
      "SpglibTestData/orthorhombic/POSCAR-064-2" : 6,
      "SpglibTestData/orthorhombic/POSCAR-064-3" : 6,
      "SpglibTestData/orthorhombic/POSCAR-065" : 6,
      "SpglibTestData/orthorhombic/POSCAR-065-2" : 6,
      "SpglibTestData/orthorhombic/POSCAR-065-3" : 6,
      "SpglibTestData/orthorhombic/POSCAR-066" : 6,
      "SpglibTestData/orthorhombic/POSCAR-066-2" : 6,
      "SpglibTestData/orthorhombic/POSCAR-067" : 6,
      "SpglibTestData/orthorhombic/POSCAR-067-2" : 6,
      "SpglibTestData/orthorhombic/POSCAR-067-3" : 6,
      "SpglibTestData/orthorhombic/POSCAR-068" : 6,
      "SpglibTestData/orthorhombic/POSCAR-068-2" : 6,
      "SpglibTestData/orthorhombic/POSCAR-069" : 3,
      "SpglibTestData/orthorhombic/POSCAR-069-2" : 3,
      "SpglibTestData/orthorhombic/POSCAR-070" : 3,
      "SpglibTestData/orthorhombic/POSCAR-070-2" : 3,
      "SpglibTestData/orthorhombic/POSCAR-071" : 2,
      "SpglibTestData/orthorhombic/POSCAR-071-2" : 2,
      "SpglibTestData/orthorhombic/POSCAR-072" : 2,
      "SpglibTestData/orthorhombic/POSCAR-072-2" : 2,
      "SpglibTestData/orthorhombic/POSCAR-073" : 2,
      "SpglibTestData/orthorhombic/POSCAR-073-2" : 2,
      "SpglibTestData/orthorhombic/POSCAR-074" : 2,
      "SpglibTestData/orthorhombic/POSCAR-074-2" : 2
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referenceCentering) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let centering: SKSpacegroup.Centring? = SKSpacegroup.SKFindSpaceGroupCentering(unitCell: unitCell, atoms: reader.atoms, allowOverlappingAtomTypes: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(centering, "centering \(fileName) not found")
          if let centering = centering
          {
            XCTAssertEqual(centering.rawValue, referenceCentering, "Wrong centering found for \(fileName): \(centering.rawValue) should be \(referenceCentering)")
          }
        }
      }
    }
  }
  
  func testCenteringTetragonalSpaceGroup()
  {
    let testData: [String: Int] =
    [
      "SpglibTestData/tetragonal/POSCAR-075" : 1,
      "SpglibTestData/tetragonal/POSCAR-075-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-076" : 1,
      "SpglibTestData/tetragonal/POSCAR-076-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-077" : 1,
      "SpglibTestData/tetragonal/POSCAR-077-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-077-3" : 1,
      "SpglibTestData/tetragonal/POSCAR-078" : 1,
      "SpglibTestData/tetragonal/POSCAR-078-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-079" : 2,
      "SpglibTestData/tetragonal/POSCAR-079-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-080" : 2,
      "SpglibTestData/tetragonal/POSCAR-080-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-081" : 1,
      "SpglibTestData/tetragonal/POSCAR-081-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-082" : 2,
      "SpglibTestData/tetragonal/POSCAR-082-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-083" : 1,
      "SpglibTestData/tetragonal/POSCAR-083-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-083-3" : 1,
      "SpglibTestData/tetragonal/POSCAR-084" : 1,
      "SpglibTestData/tetragonal/POSCAR-084-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-085" : 1,
      "SpglibTestData/tetragonal/POSCAR-085-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-086" : 1,
      "SpglibTestData/tetragonal/POSCAR-086-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-087" : 2,
      "SpglibTestData/tetragonal/POSCAR-087-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-088" : 2,
      "SpglibTestData/tetragonal/POSCAR-088-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-090" : 1,
      "SpglibTestData/tetragonal/POSCAR-090-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-091" : 1,
      "SpglibTestData/tetragonal/POSCAR-091-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-092" : 1,
      "SpglibTestData/tetragonal/POSCAR-092-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-092-3" : 1,
      "SpglibTestData/tetragonal/POSCAR-094" : 1,
      "SpglibTestData/tetragonal/POSCAR-094-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-094-3" : 1,
      "SpglibTestData/tetragonal/POSCAR-095" : 1,
      "SpglibTestData/tetragonal/POSCAR-095-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-096" : 1,
      "SpglibTestData/tetragonal/POSCAR-096-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-097" : 2,
      "SpglibTestData/tetragonal/POSCAR-097-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-098" : 2,
      "SpglibTestData/tetragonal/POSCAR-098-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-099" : 1,
      "SpglibTestData/tetragonal/POSCAR-099-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-100" : 1,
      "SpglibTestData/tetragonal/POSCAR-100-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-102" : 1,
      "SpglibTestData/tetragonal/POSCAR-102-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-103" : 1,
      "SpglibTestData/tetragonal/POSCAR-103-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-104" : 1,
      "SpglibTestData/tetragonal/POSCAR-104-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-105" : 1,
      "SpglibTestData/tetragonal/POSCAR-105-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-106" : 1,
      "SpglibTestData/tetragonal/POSCAR-107" : 2,
      "SpglibTestData/tetragonal/POSCAR-107-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-107-3" : 2,
      "SpglibTestData/tetragonal/POSCAR-108" : 2,
      "SpglibTestData/tetragonal/POSCAR-108-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-109" : 2,
      "SpglibTestData/tetragonal/POSCAR-109-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-110" : 2,
      "SpglibTestData/tetragonal/POSCAR-110-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-111" : 1,
      "SpglibTestData/tetragonal/POSCAR-111-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-112" : 1,
      "SpglibTestData/tetragonal/POSCAR-112-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-113" : 1,
      "SpglibTestData/tetragonal/POSCAR-113-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-114" : 1,
      "SpglibTestData/tetragonal/POSCAR-114-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-115" : 1,
      "SpglibTestData/tetragonal/POSCAR-115-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-115-3" : 1,
      "SpglibTestData/tetragonal/POSCAR-115-4" : 1,
      "SpglibTestData/tetragonal/POSCAR-115-5" : 1,
      "SpglibTestData/tetragonal/POSCAR-116" : 1,
      "SpglibTestData/tetragonal/POSCAR-116-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-117" : 1,
      "SpglibTestData/tetragonal/POSCAR-117-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-118" : 1,
      "SpglibTestData/tetragonal/POSCAR-118-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-119" : 2,
      "SpglibTestData/tetragonal/POSCAR-119-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-120" : 2,
      "SpglibTestData/tetragonal/POSCAR-120-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-121" : 2,
      "SpglibTestData/tetragonal/POSCAR-121-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-122" : 2,
      "SpglibTestData/tetragonal/POSCAR-122-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-122-3" : 2,
      "SpglibTestData/tetragonal/POSCAR-123" : 2,
      "SpglibTestData/tetragonal/POSCAR-123-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-123-3" : 1,
      "SpglibTestData/tetragonal/POSCAR-124" : 2,
      "SpglibTestData/tetragonal/POSCAR-124-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-125" : 1,
      "SpglibTestData/tetragonal/POSCAR-125-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-126" : 1,
      "SpglibTestData/tetragonal/POSCAR-126-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-127" : 1,
      "SpglibTestData/tetragonal/POSCAR-127-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-128" : 1,
      "SpglibTestData/tetragonal/POSCAR-128-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-129" : 1,
      "SpglibTestData/tetragonal/POSCAR-129-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-129-3" : 1,
      "SpglibTestData/tetragonal/POSCAR-130" : 1,
      "SpglibTestData/tetragonal/POSCAR-130-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-131" : 1,
      "SpglibTestData/tetragonal/POSCAR-131-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-132" : 1,
      "SpglibTestData/tetragonal/POSCAR-132-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-133" : 1,
      "SpglibTestData/tetragonal/POSCAR-133-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-134" : 1,
      "SpglibTestData/tetragonal/POSCAR-134-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-135" : 1,
      "SpglibTestData/tetragonal/POSCAR-135-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-136" : 1,
      "SpglibTestData/tetragonal/POSCAR-136-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-136-3" : 1,
      "SpglibTestData/tetragonal/POSCAR-136-4" : 1,
      "SpglibTestData/tetragonal/POSCAR-136-5" : 1,
      "SpglibTestData/tetragonal/POSCAR-137" : 1,
      "SpglibTestData/tetragonal/POSCAR-137-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-137-3" : 1,
      "SpglibTestData/tetragonal/POSCAR-138" : 1,
      "SpglibTestData/tetragonal/POSCAR-138-2" : 1,
      "SpglibTestData/tetragonal/POSCAR-139" : 2,
      "SpglibTestData/tetragonal/POSCAR-139-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-140" : 2,
      "SpglibTestData/tetragonal/POSCAR-140-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-141" : 2,
      "SpglibTestData/tetragonal/POSCAR-141-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-142" : 2,
      "SpglibTestData/tetragonal/POSCAR-142-2" : 2,
      "SpglibTestData/tetragonal/POSCAR-142-3" : 2
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referenceCentering) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let centering: SKSpacegroup.Centring? = SKSpacegroup.SKFindSpaceGroupCentering(unitCell: unitCell, atoms: reader.atoms, allowOverlappingAtomTypes: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(centering, "centering \(fileName) not found")
          if let centering = centering
          {
            XCTAssertEqual(centering.rawValue, referenceCentering, "Wrong centering found for \(fileName): \(centering.rawValue) should be \(referenceCentering)")
          }
        }
      }
    }
  }
  
  func testCenteringTrigonalSpaceGroup()
  {
    let testData: [String: Int] =
    [
      "SpglibTestData/trigonal/POSCAR-143" : 1,
      "SpglibTestData/trigonal/POSCAR-143-2" : 1,
      "SpglibTestData/trigonal/POSCAR-144" : 1,
      "SpglibTestData/trigonal/POSCAR-144-2" : 1,
      "SpglibTestData/trigonal/POSCAR-145" : 1,
      "SpglibTestData/trigonal/POSCAR-145-2" : 1,
      "SpglibTestData/trigonal/POSCAR-146" : 8,
      "SpglibTestData/trigonal/POSCAR-146-2" : 8,
      "SpglibTestData/trigonal/POSCAR-147" : 1,
      "SpglibTestData/trigonal/POSCAR-147-2" : 1,
      "SpglibTestData/trigonal/POSCAR-148" : 8,
      "SpglibTestData/trigonal/POSCAR-148-2" : 8,
      "SpglibTestData/trigonal/POSCAR-149" : 1,
      "SpglibTestData/trigonal/POSCAR-149-2" : 1,
      "SpglibTestData/trigonal/POSCAR-150" : 1,
      "SpglibTestData/trigonal/POSCAR-150-2" : 1,
      "SpglibTestData/trigonal/POSCAR-151" : 1,
      "SpglibTestData/trigonal/POSCAR-151-2" : 1,
      "SpglibTestData/trigonal/POSCAR-152" : 1,
      "SpglibTestData/trigonal/POSCAR-152-2" : 1,
      "SpglibTestData/trigonal/POSCAR-153" : 1,
      "SpglibTestData/trigonal/POSCAR-154" : 1,
      "SpglibTestData/trigonal/POSCAR-154-2" : 1,
      "SpglibTestData/trigonal/POSCAR-154-3" : 1,
      "SpglibTestData/trigonal/POSCAR-155" : 8,
      "SpglibTestData/trigonal/POSCAR-155-2" : 8,
      "SpglibTestData/trigonal/POSCAR-156" : 1,
      "SpglibTestData/trigonal/POSCAR-156-2" : 1,
      "SpglibTestData/trigonal/POSCAR-157" : 1,
      "SpglibTestData/trigonal/POSCAR-157-2" : 1,
      "SpglibTestData/trigonal/POSCAR-158" : 1,
      "SpglibTestData/trigonal/POSCAR-158-2" : 1,
      "SpglibTestData/trigonal/POSCAR-159" : 1,
      "SpglibTestData/trigonal/POSCAR-159-2" : 1,
      "SpglibTestData/trigonal/POSCAR-160" : 8,
      "SpglibTestData/trigonal/POSCAR-160-2" : 8,
      "SpglibTestData/trigonal/POSCAR-161" : 8,
      "SpglibTestData/trigonal/POSCAR-161-2" : 8,
      "SpglibTestData/trigonal/POSCAR-162" : 1,
      "SpglibTestData/trigonal/POSCAR-162-2" : 1,
      "SpglibTestData/trigonal/POSCAR-163" : 1,
      "SpglibTestData/trigonal/POSCAR-163-2" : 1,
      "SpglibTestData/trigonal/POSCAR-164" : 1,
      "SpglibTestData/trigonal/POSCAR-164-2" : 1,
      "SpglibTestData/trigonal/POSCAR-165" : 1,
      "SpglibTestData/trigonal/POSCAR-165-2" : 1,
      "SpglibTestData/trigonal/POSCAR-166" : 8,
      "SpglibTestData/trigonal/POSCAR-166-2" : 8,
      "SpglibTestData/trigonal/POSCAR-167" : 8,
      "SpglibTestData/trigonal/POSCAR-167-2" : 8,
      "SpglibTestData/trigonal/POSCAR-167-3" : 8
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referenceCentering) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let centering: SKSpacegroup.Centring? = SKSpacegroup.SKFindSpaceGroupCentering(unitCell: unitCell, atoms: reader.atoms, allowOverlappingAtomTypes: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(centering, "centering \(fileName) not found")
          if let centering = centering
          {
            XCTAssertEqual(centering.rawValue, referenceCentering, "Wrong centering found for \(fileName): \(centering.rawValue) should be \(referenceCentering)")
          }
        }
      }
    }
  }
  
  func testCenteringHexagonalSpaceGroup()
  {
    let testData: [String: Int] =
    [
      "SpglibTestData/hexagonal/POSCAR-168" : 1,
      "SpglibTestData/hexagonal/POSCAR-169" : 1,
      "SpglibTestData/hexagonal/POSCAR-169-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-170" : 1,
      "SpglibTestData/hexagonal/POSCAR-170-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-171" : 1,
      "SpglibTestData/hexagonal/POSCAR-171-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-172" : 1,
      "SpglibTestData/hexagonal/POSCAR-173" : 1,
      "SpglibTestData/hexagonal/POSCAR-173-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-174" : 1,
      "SpglibTestData/hexagonal/POSCAR-174-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-175" : 1,
      "SpglibTestData/hexagonal/POSCAR-175-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-176" : 1,
      "SpglibTestData/hexagonal/POSCAR-176-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-177" : 1,
      "SpglibTestData/hexagonal/POSCAR-179" : 1,
      "SpglibTestData/hexagonal/POSCAR-179-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-180" : 1,
      "SpglibTestData/hexagonal/POSCAR-180-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-181" : 1,
      "SpglibTestData/hexagonal/POSCAR-181-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-182" : 1,
      "SpglibTestData/hexagonal/POSCAR-182-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-183" : 1,
      "SpglibTestData/hexagonal/POSCAR-183-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-184" : 1,
      "SpglibTestData/hexagonal/POSCAR-184-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-185" : 1,
      "SpglibTestData/hexagonal/POSCAR-185-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-186" : 1,
      "SpglibTestData/hexagonal/POSCAR-186-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-187" : 1,
      "SpglibTestData/hexagonal/POSCAR-187-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-188" : 1,
      "SpglibTestData/hexagonal/POSCAR-188-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-189" : 1,
      "SpglibTestData/hexagonal/POSCAR-189-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-190" : 1,
      "SpglibTestData/hexagonal/POSCAR-190-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-191" : 1,
      "SpglibTestData/hexagonal/POSCAR-191-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-192" : 1,
      "SpglibTestData/hexagonal/POSCAR-192-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-193" : 1,
      "SpglibTestData/hexagonal/POSCAR-193-2" : 1,
      "SpglibTestData/hexagonal/POSCAR-194" : 1,
      "SpglibTestData/hexagonal/POSCAR-194-2" : 1
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referenceCentering) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let centering: SKSpacegroup.Centring? = SKSpacegroup.SKFindSpaceGroupCentering(unitCell: unitCell, atoms: reader.atoms, allowOverlappingAtomTypes: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(centering, "centering \(fileName) not found")
          if let centering = centering
          {
            XCTAssertEqual(centering.rawValue, referenceCentering, "Wrong centering found for \(fileName): \(centering.rawValue) should be \(referenceCentering)")
          }
        }
      }
    }
  }
  
  
  func testCenteringCubicSpaceGroup()
  {
    let testData: [String: Int] =
    [
      "SpglibTestData/cubic/POSCAR-195" : 1,
      "SpglibTestData/cubic/POSCAR-195-2" : 1,
      "SpglibTestData/cubic/POSCAR-196" : 3,
      "SpglibTestData/cubic/POSCAR-196-2" : 3,
      "SpglibTestData/cubic/POSCAR-197" : 2,
      "SpglibTestData/cubic/POSCAR-197-2" : 2,
      "SpglibTestData/cubic/POSCAR-198" : 1,
      "SpglibTestData/cubic/POSCAR-198-2" : 1,
      "SpglibTestData/cubic/POSCAR-199" : 2,
      "SpglibTestData/cubic/POSCAR-199-2" : 2,
      "SpglibTestData/cubic/POSCAR-200" : 1,
      "SpglibTestData/cubic/POSCAR-200-2" : 1,
      "SpglibTestData/cubic/POSCAR-205" : 1,
      "SpglibTestData/cubic/POSCAR-205-3" : 1,
      "SpglibTestData/cubic/POSCAR-206" : 2,
      "SpglibTestData/cubic/POSCAR-206-2" : 2,
      "SpglibTestData/cubic/POSCAR-207" : 1,
      "SpglibTestData/cubic/POSCAR-208" : 1,
      "SpglibTestData/cubic/POSCAR-208-2" : 1,
      "SpglibTestData/cubic/POSCAR-209" : 3,
      "SpglibTestData/cubic/POSCAR-210" : 3,
      "SpglibTestData/cubic/POSCAR-210-2" : 3,
      "SpglibTestData/cubic/POSCAR-211" : 2,
      "SpglibTestData/cubic/POSCAR-212" : 1,
      "SpglibTestData/cubic/POSCAR-212-2" : 1,
      "SpglibTestData/cubic/POSCAR-213" : 1,
      "SpglibTestData/cubic/POSCAR-213-2" : 1,
      "SpglibTestData/cubic/POSCAR-214" : 2,
      "SpglibTestData/cubic/POSCAR-214-2" : 2,
      "SpglibTestData/cubic/POSCAR-215" : 1,
      "SpglibTestData/cubic/POSCAR-215-2" : 1,
      "SpglibTestData/cubic/POSCAR-216" : 3,
      "SpglibTestData/cubic/POSCAR-216-2" : 3,
      "SpglibTestData/cubic/POSCAR-217" : 2,
      "SpglibTestData/cubic/POSCAR-217-2" : 2,
      "SpglibTestData/cubic/POSCAR-218" : 1,
      "SpglibTestData/cubic/POSCAR-218-2" : 1,
      "SpglibTestData/cubic/POSCAR-219" : 3,
      "SpglibTestData/cubic/POSCAR-219-2" : 3,
      "SpglibTestData/cubic/POSCAR-220" : 2,
      "SpglibTestData/cubic/POSCAR-220-2" : 2,
      "SpglibTestData/cubic/POSCAR-221" : 1,
      "SpglibTestData/cubic/POSCAR-221-2" : 1,
      "SpglibTestData/cubic/POSCAR-222" : 1,
      "SpglibTestData/cubic/POSCAR-222-2" : 1,
      "SpglibTestData/cubic/POSCAR-223" : 1,
      "SpglibTestData/cubic/POSCAR-223-2" : 1,
      "SpglibTestData/cubic/POSCAR-224" : 1,
      "SpglibTestData/cubic/POSCAR-224-2" : 1,
      "SpglibTestData/cubic/POSCAR-225" : 3,
      "SpglibTestData/cubic/POSCAR-225-2" : 1,
      "SpglibTestData/cubic/POSCAR-226" : 3,
      "SpglibTestData/cubic/POSCAR-226-2" : 3,
      "SpglibTestData/cubic/POSCAR-227" : 3,
      "SpglibTestData/cubic/POSCAR-227-2" : 3,
      "SpglibTestData/cubic/POSCAR-228" : 3,
      "SpglibTestData/cubic/POSCAR-228-2" : 3,
      "SpglibTestData/cubic/POSCAR-229" : 2,
      "SpglibTestData/cubic/POSCAR-229-2" : 2,
      "SpglibTestData/cubic/POSCAR-230" : 2,
      "SpglibTestData/cubic/POSCAR-230-2" : 2,
      "SpglibTestData/cubic/POSCAR-230-3" : 2,
      "SpglibTestData/cubic/POSCAR-230-4" : 2
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referenceCentering) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let centering: SKSpacegroup.Centring? = SKSpacegroup.SKFindSpaceGroupCentering(unitCell: unitCell, atoms: reader.atoms, allowOverlappingAtomTypes: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(centering, "centering \(fileName) not found")
          if let centering = centering
          {
            XCTAssertEqual(centering.rawValue, referenceCentering, "Wrong centering found for \(fileName): \(centering.rawValue) should be \(referenceCentering)")
          }
        }
      }
    }
  }
  
  func testCenteringVirtualSpaceGroups()
  {
    let testData: [String: Int] =
    [
      "SpglibTestData/virtual_structure/POSCAR-1-221-33" : 1,
      "SpglibTestData/virtual_structure/POSCAR-1-222-33" : 1,
      "SpglibTestData/virtual_structure/POSCAR-1-223-33" : 1,
      "SpglibTestData/virtual_structure/POSCAR-1-224-33" : 1,
      "SpglibTestData/virtual_structure/POSCAR-1-227-73" : 3,
      "SpglibTestData/virtual_structure/POSCAR-1-227-93" : 3,
      "SpglibTestData/virtual_structure/POSCAR-1-227-99" : 3,
      "SpglibTestData/virtual_structure/POSCAR-1-230-conv-56" : 2,
      "SpglibTestData/virtual_structure/POSCAR-1-230-prim-33" : 2,
      "SpglibTestData/virtual_structure/POSCAR-1-bcc-33" : 2,
      "SpglibTestData/virtual_structure/POSCAR-10-221-18" : 1,
      "SpglibTestData/virtual_structure/POSCAR-10-223-18" : 1,
      "SpglibTestData/virtual_structure/POSCAR-10-227-50" : 3,
      "SpglibTestData/virtual_structure/POSCAR-102-224-13" : 1,
      "SpglibTestData/virtual_structure/POSCAR-104-222-13" : 1,
      "SpglibTestData/virtual_structure/POSCAR-105-223-13" : 1,
      "SpglibTestData/virtual_structure/POSCAR-109-227-13" : 3,
      "SpglibTestData/virtual_structure/POSCAR-11-227-48" : 3,
      "SpglibTestData/virtual_structure/POSCAR-110-230-conv-15" : 2,
      "SpglibTestData/virtual_structure/POSCAR-110-230-prim-13" : 2,
      "SpglibTestData/virtual_structure/POSCAR-111-221-11" : 1,
      "SpglibTestData/virtual_structure/POSCAR-111-224-11" : 1,
      "SpglibTestData/virtual_structure/POSCAR-111-227-66" : 3,
      "SpglibTestData/virtual_structure/POSCAR-112-222-11" : 1,
      "SpglibTestData/virtual_structure/POSCAR-112-223-11" : 1,
      "SpglibTestData/virtual_structure/POSCAR-113-227-68" : 3,
      "SpglibTestData/virtual_structure/POSCAR-115-221-14" : 1,
      "SpglibTestData/virtual_structure/POSCAR-115-223-14" : 1,
      "SpglibTestData/virtual_structure/POSCAR-115-227-33" : 3,
      "SpglibTestData/virtual_structure/POSCAR-116-230-conv-34" : 2,
      "SpglibTestData/virtual_structure/POSCAR-117-230-conv-33" : 2,
      "SpglibTestData/virtual_structure/POSCAR-118-222-14" : 1,
      "SpglibTestData/virtual_structure/POSCAR-118-224-14" : 1,
      "SpglibTestData/virtual_structure/POSCAR-12-221-19" : 1,
      "SpglibTestData/virtual_structure/POSCAR-12-224-19" : 1,
      "SpglibTestData/virtual_structure/POSCAR-12-227-21" : 3,
      "SpglibTestData/virtual_structure/POSCAR-12-227-83" : 3,
      "SpglibTestData/virtual_structure/POSCAR-120-230-conv-16" : 2,
      "SpglibTestData/virtual_structure/POSCAR-120-230-prim-14" : 2,
      "SpglibTestData/virtual_structure/POSCAR-122-230-conv-13" : 2,
      "SpglibTestData/virtual_structure/POSCAR-122-230-prim-11" : 2,
      "SpglibTestData/virtual_structure/POSCAR-123-221-05" : 1,
      "SpglibTestData/virtual_structure/POSCAR-126-222-05" : 1,
      "SpglibTestData/virtual_structure/POSCAR-13-222-18" : 1,
      "SpglibTestData/virtual_structure/POSCAR-13-224-18" : 1,
      "SpglibTestData/virtual_structure/POSCAR-13-227-49" : 3,
      "SpglibTestData/virtual_structure/POSCAR-13-230-conv-44" : 2,
      "SpglibTestData/virtual_structure/POSCAR-131-223-05" : 1,
      "SpglibTestData/virtual_structure/POSCAR-134-224-05" : 1,
      "SpglibTestData/virtual_structure/POSCAR-14-227-47" : 3,
      "SpglibTestData/virtual_structure/POSCAR-14-227-51" : 3,
      "SpglibTestData/virtual_structure/POSCAR-14-230-conv-45" : 2,
      "SpglibTestData/virtual_structure/POSCAR-142-230-conv-05" : 2,
      "SpglibTestData/virtual_structure/POSCAR-142-230-prim-05" : 2,
      "SpglibTestData/virtual_structure/POSCAR-146-221-27" : 1,
      "SpglibTestData/virtual_structure/POSCAR-146-222-27" : 1,
      "SpglibTestData/virtual_structure/POSCAR-146-223-27" : 1,
      "SpglibTestData/virtual_structure/POSCAR-146-224-27" : 1,
      "SpglibTestData/virtual_structure/POSCAR-146-227-92" : 3,
      "SpglibTestData/virtual_structure/POSCAR-146-230-conv-36" : 2,
      "SpglibTestData/virtual_structure/POSCAR-146-230-conv-55" : 2,
      "SpglibTestData/virtual_structure/POSCAR-146-230-prim-27" : 2,
      "SpglibTestData/virtual_structure/POSCAR-146-bcc-27" : 2,
      "SpglibTestData/virtual_structure/POSCAR-148-221-15" : 1,
      "SpglibTestData/virtual_structure/POSCAR-148-222-15" : 1,
      "SpglibTestData/virtual_structure/POSCAR-148-223-15" : 1,
      "SpglibTestData/virtual_structure/POSCAR-148-224-15" : 1,
      "SpglibTestData/virtual_structure/POSCAR-148-227-70" : 3,
      "SpglibTestData/virtual_structure/POSCAR-148-230-conv-17" : 2,
      "SpglibTestData/virtual_structure/POSCAR-148-230-conv-37" : 2,
      "SpglibTestData/virtual_structure/POSCAR-148-230-prim-15" : 2,
      "SpglibTestData/virtual_structure/POSCAR-148-bcc-15" : 2,
      "SpglibTestData/virtual_structure/POSCAR-15-222-19" : 1,
      "SpglibTestData/virtual_structure/POSCAR-15-223-19" : 1,
      "SpglibTestData/virtual_structure/POSCAR-15-230-conv-21" : 2,
      "SpglibTestData/virtual_structure/POSCAR-15-230-conv-22" : 2,
      "SpglibTestData/virtual_structure/POSCAR-15-230-prim-18" : 2,
      "SpglibTestData/virtual_structure/POSCAR-15-230-prim-19" : 2,
      "SpglibTestData/virtual_structure/POSCAR-15-bcc-18" : 2,
      "SpglibTestData/virtual_structure/POSCAR-15-bcc-19" : 2,
      "SpglibTestData/virtual_structure/POSCAR-155-221-17" : 1,
      "SpglibTestData/virtual_structure/POSCAR-155-222-17" : 1,
      "SpglibTestData/virtual_structure/POSCAR-155-223-17" : 1,
      "SpglibTestData/virtual_structure/POSCAR-155-224-17" : 1,
      "SpglibTestData/virtual_structure/POSCAR-155-227-72" : 3,
      "SpglibTestData/virtual_structure/POSCAR-155-230-conv-19" : 2,
      "SpglibTestData/virtual_structure/POSCAR-155-230-conv-38" : 2,
      "SpglibTestData/virtual_structure/POSCAR-155-230-prim-17" : 2,
      "SpglibTestData/virtual_structure/POSCAR-155-bcc-17" : 2,
      "SpglibTestData/virtual_structure/POSCAR-16-221-20" : 1,
      "SpglibTestData/virtual_structure/POSCAR-16-222-20" : 1,
      "SpglibTestData/virtual_structure/POSCAR-16-223-20" : 1,
      "SpglibTestData/virtual_structure/POSCAR-16-224-20" : 1,
      "SpglibTestData/virtual_structure/POSCAR-16-227-84" : 3,
      "SpglibTestData/virtual_structure/POSCAR-160-221-16" : 1,
      "SpglibTestData/virtual_structure/POSCAR-160-224-16" : 1,
      "SpglibTestData/virtual_structure/POSCAR-160-227-16" : 3,
      "SpglibTestData/virtual_structure/POSCAR-160-227-71" : 3,
      "SpglibTestData/virtual_structure/POSCAR-160-fcc" : 8,
      "SpglibTestData/virtual_structure/POSCAR-161-222-16" : 1,
      "SpglibTestData/virtual_structure/POSCAR-161-223-16" : 1,
      "SpglibTestData/virtual_structure/POSCAR-161-230-conv-18" : 2,
      "SpglibTestData/virtual_structure/POSCAR-161-230-prim-16" : 2,
      "SpglibTestData/virtual_structure/POSCAR-161-bcc-16" : 2,
      "SpglibTestData/virtual_structure/POSCAR-166-221-06" : 1,
      "SpglibTestData/virtual_structure/POSCAR-166-224-06" : 1,
      "SpglibTestData/virtual_structure/POSCAR-166-227-06" : 3,
      "SpglibTestData/virtual_structure/POSCAR-166-227-38" : 3,
      "SpglibTestData/virtual_structure/POSCAR-167-222-06" : 1,
      "SpglibTestData/virtual_structure/POSCAR-167-223-06" : 1,
      "SpglibTestData/virtual_structure/POSCAR-167-230-conv-06" : 2,
      "SpglibTestData/virtual_structure/POSCAR-167-230-prim-06" : 2,
      "SpglibTestData/virtual_structure/POSCAR-167-bcc-6" : 2,
      "SpglibTestData/virtual_structure/POSCAR-17-227-60" : 3,
      "SpglibTestData/virtual_structure/POSCAR-17-227-85" : 3,
      "SpglibTestData/virtual_structure/POSCAR-17-230-conv-46" : 2,
      "SpglibTestData/virtual_structure/POSCAR-18-227-86" : 3,
      "SpglibTestData/virtual_structure/POSCAR-19-227-59" : 3,
      "SpglibTestData/virtual_structure/POSCAR-19-227-89" : 3,
      "SpglibTestData/virtual_structure/POSCAR-19-230-conv-51" : 2,
      "SpglibTestData/virtual_structure/POSCAR-195-221-07" : 1,
      "SpglibTestData/virtual_structure/POSCAR-195-222-07" : 1,
      "SpglibTestData/virtual_structure/POSCAR-195-223-07" : 1,
      "SpglibTestData/virtual_structure/POSCAR-195-224-07" : 1,
      "SpglibTestData/virtual_structure/POSCAR-198-227-40" : 3,
      "SpglibTestData/virtual_structure/POSCAR-198-230-conv-20" : 2,
      "SpglibTestData/virtual_structure/POSCAR-199-230-conv-07" : 2,
      "SpglibTestData/virtual_structure/POSCAR-199-230-prim-07" : 2,
      "SpglibTestData/virtual_structure/POSCAR-2-221-28" : 1,
      "SpglibTestData/virtual_structure/POSCAR-2-222-28" : 1,
      "SpglibTestData/virtual_structure/POSCAR-2-223-28" : 1,
      "SpglibTestData/virtual_structure/POSCAR-2-224-28" : 1,
      "SpglibTestData/virtual_structure/POSCAR-2-227-41" : 3,
      "SpglibTestData/virtual_structure/POSCAR-2-227-74" : 3,
      "SpglibTestData/virtual_structure/POSCAR-2-227-94" : 3,
      "SpglibTestData/virtual_structure/POSCAR-2-230-conv-39" : 2,
      "SpglibTestData/virtual_structure/POSCAR-2-230-conv-57" : 2,
      "SpglibTestData/virtual_structure/POSCAR-2-230-prim-28" : 2,
      "SpglibTestData/virtual_structure/POSCAR-2-bcc-28" : 2,
      "SpglibTestData/virtual_structure/POSCAR-20-227-53" : 3,
      "SpglibTestData/virtual_structure/POSCAR-20-227-90" : 3,
      "SpglibTestData/virtual_structure/POSCAR-20-230-conv-53" : 2,
      "SpglibTestData/virtual_structure/POSCAR-200-221-02" : 1,
      "SpglibTestData/virtual_structure/POSCAR-200-223-02" : 1,
      "SpglibTestData/virtual_structure/POSCAR-201-222-02" : 1,
      "SpglibTestData/virtual_structure/POSCAR-201-224-02" : 1,
      "SpglibTestData/virtual_structure/POSCAR-205-230-conv-08" : 2,
      "SpglibTestData/virtual_structure/POSCAR-206-230-conv-02" : 2,
      "SpglibTestData/virtual_structure/POSCAR-206-230-prim-02" : 2,
      "SpglibTestData/virtual_structure/POSCAR-207-221-04" : 1,
      "SpglibTestData/virtual_structure/POSCAR-207-222-04" : 1,
      "SpglibTestData/virtual_structure/POSCAR-208-223-04" : 1,
      "SpglibTestData/virtual_structure/POSCAR-208-224-04" : 1,
      "SpglibTestData/virtual_structure/POSCAR-21-221-23" : 1,
      "SpglibTestData/virtual_structure/POSCAR-21-222-23" : 1,
      "SpglibTestData/virtual_structure/POSCAR-21-223-23" : 1,
      "SpglibTestData/virtual_structure/POSCAR-21-224-23" : 1,
      "SpglibTestData/virtual_structure/POSCAR-21-230-conv-49" : 2,
      "SpglibTestData/virtual_structure/POSCAR-212-227-19" : 3,
      "SpglibTestData/virtual_structure/POSCAR-213-230-conv-09" : 2,
      "SpglibTestData/virtual_structure/POSCAR-214-230-conv-04" : 2,
      "SpglibTestData/virtual_structure/POSCAR-214-230-prim-04" : 2,
      "SpglibTestData/virtual_structure/POSCAR-215-221-03" : 1,
      "SpglibTestData/virtual_structure/POSCAR-215-224-03" : 1,
      "SpglibTestData/virtual_structure/POSCAR-215-227-18" : 3,
      "SpglibTestData/virtual_structure/POSCAR-216-227-03" : 3,
      "SpglibTestData/virtual_structure/POSCAR-218-222-03" : 1,
      "SpglibTestData/virtual_structure/POSCAR-218-223-03" : 1,
      "SpglibTestData/virtual_structure/POSCAR-22-230-conv-26" : 2,
      "SpglibTestData/virtual_structure/POSCAR-22-230-prim-23" : 2,
      "SpglibTestData/virtual_structure/POSCAR-220-230-conv-03" : 2,
      "SpglibTestData/virtual_structure/POSCAR-220-230-prim-03" : 2,
      "SpglibTestData/virtual_structure/POSCAR-221-221-01" : 1,
      "SpglibTestData/virtual_structure/POSCAR-222-222-01" : 1,
      "SpglibTestData/virtual_structure/POSCAR-223-223-01" : 1,
      "SpglibTestData/virtual_structure/POSCAR-224-224-01" : 1,
      "SpglibTestData/virtual_structure/POSCAR-227-227-01" : 3,
      "SpglibTestData/virtual_structure/POSCAR-230-230-conv-01" : 2,
      "SpglibTestData/virtual_structure/POSCAR-230-230-conv-62" : 2,
      "SpglibTestData/virtual_structure/POSCAR-230-230-prim-01" : 2,
      "SpglibTestData/virtual_structure/POSCAR-24-230-conv-23" : 2,
      "SpglibTestData/virtual_structure/POSCAR-24-230-prim-20" : 2,
      "SpglibTestData/virtual_structure/POSCAR-25-221-21" : 1,
      "SpglibTestData/virtual_structure/POSCAR-25-223-21" : 1,
      "SpglibTestData/virtual_structure/POSCAR-25-227-54" : 3,
      "SpglibTestData/virtual_structure/POSCAR-26-227-64" : 3,
      "SpglibTestData/virtual_structure/POSCAR-27-230-conv-48" : 2,
      "SpglibTestData/virtual_structure/POSCAR-28-227-62" : 3,
      "SpglibTestData/virtual_structure/POSCAR-29-230-conv-52" : 2,
      "SpglibTestData/virtual_structure/POSCAR-3-221-29" : 1,
      "SpglibTestData/virtual_structure/POSCAR-3-222-29" : 1,
      "SpglibTestData/virtual_structure/POSCAR-3-223-29" : 1,
      "SpglibTestData/virtual_structure/POSCAR-3-224-29" : 1,
      "SpglibTestData/virtual_structure/POSCAR-3-227-82" : 3,
      "SpglibTestData/virtual_structure/POSCAR-3-227-95" : 3,
      "SpglibTestData/virtual_structure/POSCAR-3-230-conv-58" : 2,
      "SpglibTestData/virtual_structure/POSCAR-30-227-65" : 3,
      "SpglibTestData/virtual_structure/POSCAR-31-227-58" : 3,
      "SpglibTestData/virtual_structure/POSCAR-32-230-conv-47" : 2,
      "SpglibTestData/virtual_structure/POSCAR-33-227-63" : 3,
      "SpglibTestData/virtual_structure/POSCAR-34-222-21" : 1,
      "SpglibTestData/virtual_structure/POSCAR-34-224-21" : 1,
      "SpglibTestData/virtual_structure/POSCAR-35-221-22" : 1,
      "SpglibTestData/virtual_structure/POSCAR-35-224-22" : 1,
      "SpglibTestData/virtual_structure/POSCAR-35-227-87" : 3,
      "SpglibTestData/virtual_structure/POSCAR-37-222-22" : 1,
      "SpglibTestData/virtual_structure/POSCAR-37-223-22" : 1,
      "SpglibTestData/virtual_structure/POSCAR-38-221-26" : 1,
      "SpglibTestData/virtual_structure/POSCAR-39-224-26" : 1,
      "SpglibTestData/virtual_structure/POSCAR-4-227-77" : 3,
      "SpglibTestData/virtual_structure/POSCAR-4-227-81" : 3,
      "SpglibTestData/virtual_structure/POSCAR-4-227-96" : 3,
      "SpglibTestData/virtual_structure/POSCAR-4-230-conv-59" : 2,
      "SpglibTestData/virtual_structure/POSCAR-40-223-26" : 1,
      "SpglibTestData/virtual_structure/POSCAR-41-222-26" : 1,
      "SpglibTestData/virtual_structure/POSCAR-43-230-conv-25" : 2,
      "SpglibTestData/virtual_structure/POSCAR-43-230-conv-29" : 2,
      "SpglibTestData/virtual_structure/POSCAR-43-230-prim-22" : 2,
      "SpglibTestData/virtual_structure/POSCAR-43-230-prim-26" : 2,
      "SpglibTestData/virtual_structure/POSCAR-43-bcc-22" : 2,
      "SpglibTestData/virtual_structure/POSCAR-43-bcc-26" : 2,
      "SpglibTestData/virtual_structure/POSCAR-44-227-24" : 3,
      "SpglibTestData/virtual_structure/POSCAR-45-230-conv-24" : 2,
      "SpglibTestData/virtual_structure/POSCAR-45-230-prim-21" : 2,
      "SpglibTestData/virtual_structure/POSCAR-46-227-28" : 3,
      "SpglibTestData/virtual_structure/POSCAR-47-221-08" : 1,
      "SpglibTestData/virtual_structure/POSCAR-47-223-08" : 1,
      "SpglibTestData/virtual_structure/POSCAR-48-222-08" : 1,
      "SpglibTestData/virtual_structure/POSCAR-48-224-08" : 1,
      "SpglibTestData/virtual_structure/POSCAR-5-221-32" : 1,
      "SpglibTestData/virtual_structure/POSCAR-5-222-32" : 1,
      "SpglibTestData/virtual_structure/POSCAR-5-223-32" : 1,
      "SpglibTestData/virtual_structure/POSCAR-5-224-32" : 1,
      "SpglibTestData/virtual_structure/POSCAR-5-227-45" : 3,
      "SpglibTestData/virtual_structure/POSCAR-5-227-75" : 3,
      "SpglibTestData/virtual_structure/POSCAR-5-227-98" : 3,
      "SpglibTestData/virtual_structure/POSCAR-5-230-conv-40" : 2,
      "SpglibTestData/virtual_structure/POSCAR-5-230-conv-43" : 2,
      "SpglibTestData/virtual_structure/POSCAR-5-230-conv-61" : 2,
      "SpglibTestData/virtual_structure/POSCAR-5-230-prim-29" : 2,
      "SpglibTestData/virtual_structure/POSCAR-5-230-prim-32" : 2,
      "SpglibTestData/virtual_structure/POSCAR-5-bcc-29" : 2,
      "SpglibTestData/virtual_structure/POSCAR-5-bcc-32" : 2,
      "SpglibTestData/virtual_structure/POSCAR-51-227-29" : 3,
      "SpglibTestData/virtual_structure/POSCAR-53-227-32" : 3,
      "SpglibTestData/virtual_structure/POSCAR-54-230-conv-30" : 2,
      "SpglibTestData/virtual_structure/POSCAR-6-221-30" : 1,
      "SpglibTestData/virtual_structure/POSCAR-6-223-30" : 1,
      "SpglibTestData/virtual_structure/POSCAR-6-227-79" : 3,
      "SpglibTestData/virtual_structure/POSCAR-61-230-conv-31" : 2,
      "SpglibTestData/virtual_structure/POSCAR-62-227-31" : 3,
      "SpglibTestData/virtual_structure/POSCAR-65-221-09" : 1,
      "SpglibTestData/virtual_structure/POSCAR-66-223-09" : 1,
      "SpglibTestData/virtual_structure/POSCAR-67-224-09" : 1,
      "SpglibTestData/virtual_structure/POSCAR-68-222-09" : 1,
      "SpglibTestData/virtual_structure/POSCAR-7-222-30" : 1,
      "SpglibTestData/virtual_structure/POSCAR-7-224-30" : 1,
      "SpglibTestData/virtual_structure/POSCAR-7-227-78" : 3,
      "SpglibTestData/virtual_structure/POSCAR-7-227-80" : 3,
      "SpglibTestData/virtual_structure/POSCAR-7-230-conv-60" : 2,
      "SpglibTestData/virtual_structure/POSCAR-70-230-conv-11" : 2,
      "SpglibTestData/virtual_structure/POSCAR-70-230-prim-09" : 2,
      "SpglibTestData/virtual_structure/POSCAR-70-bcc-9" : 2,
      "SpglibTestData/virtual_structure/POSCAR-73-230-conv-10" : 2,
      "SpglibTestData/virtual_structure/POSCAR-73-230-prim-08" : 2,
      "SpglibTestData/virtual_structure/POSCAR-74-227-09" : 3,
      "SpglibTestData/virtual_structure/POSCAR-75-221-25" : 1,
      "SpglibTestData/virtual_structure/POSCAR-75-222-25" : 1,
      "SpglibTestData/virtual_structure/POSCAR-76-227-61" : 3,
      "SpglibTestData/virtual_structure/POSCAR-77-223-25" : 1,
      "SpglibTestData/virtual_structure/POSCAR-77-224-25" : 1,
      "SpglibTestData/virtual_structure/POSCAR-78-227-91" : 3,
      "SpglibTestData/virtual_structure/POSCAR-78-230-conv-54" : 2,
      "SpglibTestData/virtual_structure/POSCAR-8-221-31" : 1,
      "SpglibTestData/virtual_structure/POSCAR-8-224-31" : 1,
      "SpglibTestData/virtual_structure/POSCAR-8-227-44" : 3,
      "SpglibTestData/virtual_structure/POSCAR-8-227-97" : 3,
      "SpglibTestData/virtual_structure/POSCAR-80-230-conv-28" : 2,
      "SpglibTestData/virtual_structure/POSCAR-80-230-prim-25" : 2,
      "SpglibTestData/virtual_structure/POSCAR-81-221-24" : 1,
      "SpglibTestData/virtual_structure/POSCAR-81-222-24" : 1,
      "SpglibTestData/virtual_structure/POSCAR-81-223-24" : 1,
      "SpglibTestData/virtual_structure/POSCAR-81-224-24" : 1,
      "SpglibTestData/virtual_structure/POSCAR-81-227-88" : 3,
      "SpglibTestData/virtual_structure/POSCAR-81-230-conv-50" : 2,
      "SpglibTestData/virtual_structure/POSCAR-82-230-conv-27" : 2,
      "SpglibTestData/virtual_structure/POSCAR-82-230-prim-24" : 2,
      "SpglibTestData/virtual_structure/POSCAR-83-221-10" : 1,
      "SpglibTestData/virtual_structure/POSCAR-84-223-10" : 1,
      "SpglibTestData/virtual_structure/POSCAR-85-222-10" : 1,
      "SpglibTestData/virtual_structure/POSCAR-86-224-10" : 1,
      "SpglibTestData/virtual_structure/POSCAR-88-230-conv-12" : 2,
      "SpglibTestData/virtual_structure/POSCAR-88-230-prim-10" : 2,
      "SpglibTestData/virtual_structure/POSCAR-89-221-12" : 1,
      "SpglibTestData/virtual_structure/POSCAR-89-222-12" : 1,
      "SpglibTestData/virtual_structure/POSCAR-9-222-31" : 1,
      "SpglibTestData/virtual_structure/POSCAR-9-223-31" : 1,
      "SpglibTestData/virtual_structure/POSCAR-9-227-43" : 3,
      "SpglibTestData/virtual_structure/POSCAR-9-230-conv-41" : 2,
      "SpglibTestData/virtual_structure/POSCAR-9-230-conv-42" : 2,
      "SpglibTestData/virtual_structure/POSCAR-9-230-prim-30" : 2,
      "SpglibTestData/virtual_structure/POSCAR-9-230-prim-31" : 2,
      "SpglibTestData/virtual_structure/POSCAR-9-bcc-30" : 2,
      "SpglibTestData/virtual_structure/POSCAR-9-bcc-31" : 2,
      "SpglibTestData/virtual_structure/POSCAR-91-227-67" : 3,
      "SpglibTestData/virtual_structure/POSCAR-92-227-35" : 3,
      "SpglibTestData/virtual_structure/POSCAR-92-230-conv-35" : 2,
      "SpglibTestData/virtual_structure/POSCAR-93-223-12" : 1,
      "SpglibTestData/virtual_structure/POSCAR-93-224-12" : 1,
      "SpglibTestData/virtual_structure/POSCAR-95-227-36" : 3,
      "SpglibTestData/virtual_structure/POSCAR-95-230-conv-32" : 2,
      "SpglibTestData/virtual_structure/POSCAR-96-227-69" : 3,
      "SpglibTestData/virtual_structure/POSCAR-98-230-conv-14" : 2,
      "SpglibTestData/virtual_structure/POSCAR-98-230-prim-12" : 2,
      "SpglibTestData/virtual_structure/POSCAR-99-221-13" : 1
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referenceCentering) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          // search for a primitive cell based on the positions of the atoms
          let centering: SKSpacegroup.Centring? = SKSpacegroup.SKFindSpaceGroupCentering(unitCell: unitCell, atoms: reader.atoms, allowOverlappingAtomTypes: true, symmetryPrecision: precision)
                   
          XCTAssertNotNil(centering, "centering \(fileName) not found")
          if let centering = centering
          {
            XCTAssertEqual(centering.rawValue, referenceCentering, "Wrong primitiveCell found for \(fileName): \(centering.rawValue) should be \(referenceCentering)")
           
          }
        }
      }
    }
  }
}
