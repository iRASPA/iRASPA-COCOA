//
//  SpaceGroupSpglibNoPartialOccupanciesTests.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 20/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import SymmetryKit
import simd

class SpaceGroupSpglibNoPartialOccupanciesTests: XCTestCase
{
  let precision: Double = 1e-5
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testFindTriclinicSpaceGroup()
  {
    let testData: [String: Int] =
    [
      "SpglibTestData/triclinic/POSCAR-001" : 1,
      "SpglibTestData/triclinic/POSCAR-002" : 2
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referenceSpaceGroupValue) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, allowOverlappingAtomTypes: false, symmetryPrecision: precision)
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            XCTAssertEqual(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber, referenceSpaceGroupValue, "Wrong space group found for \(fileName)")
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
        "SpglibTestData/monoclinic/POSCAR-004" : 4,
        "SpglibTestData/monoclinic/POSCAR-004-2" : 4,
        "SpglibTestData/monoclinic/POSCAR-005" : 5,
        "SpglibTestData/monoclinic/POSCAR-005-2" : 5,
        "SpglibTestData/monoclinic/POSCAR-006" : 6,
        "SpglibTestData/monoclinic/POSCAR-006-2" : 6,
        "SpglibTestData/monoclinic/POSCAR-007" : 7,
        "SpglibTestData/monoclinic/POSCAR-007-2" : 7,
        "SpglibTestData/monoclinic/POSCAR-008" : 8,
        "SpglibTestData/monoclinic/POSCAR-008-2" : 8,
        "SpglibTestData/monoclinic/POSCAR-009" : 9,
        "SpglibTestData/monoclinic/POSCAR-009-2" : 9,
        "SpglibTestData/monoclinic/POSCAR-010" : 10,
        "SpglibTestData/monoclinic/POSCAR-010-2" : 10,
        "SpglibTestData/monoclinic/POSCAR-011" : 11,
        "SpglibTestData/monoclinic/POSCAR-011-2" : 11,
        "SpglibTestData/monoclinic/POSCAR-012" : 12,
        "SpglibTestData/monoclinic/POSCAR-012-2" : 12,
        "SpglibTestData/monoclinic/POSCAR-012-3" : 12,
        "SpglibTestData/monoclinic/POSCAR-013" : 13,
        "SpglibTestData/monoclinic/POSCAR-013-2" : 13,
        "SpglibTestData/monoclinic/POSCAR-013-3" : 13,
        "SpglibTestData/monoclinic/POSCAR-014" : 14,
        "SpglibTestData/monoclinic/POSCAR-014-2" : 14,
        "SpglibTestData/monoclinic/POSCAR-015" : 15,
        "SpglibTestData/monoclinic/POSCAR-015-2" : 15,
        "SpglibTestData/monoclinic/POSCAR-015-3" : 15
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, referenceSpaceGroupValue) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, allowOverlappingAtomTypes: false, symmetryPrecision: precision)
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            XCTAssertEqual(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber, referenceSpaceGroupValue, "Wrong space group found for \(fileName)")
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
      "SpglibTestData/orthorhombic/POSCAR-016" : 16,
      "SpglibTestData/orthorhombic/POSCAR-016-2" : 16,
      "SpglibTestData/orthorhombic/POSCAR-017-2" : 17,
      "SpglibTestData/orthorhombic/POSCAR-018" : 18,
      "SpglibTestData/orthorhombic/POSCAR-018-2" : 18,
      "SpglibTestData/orthorhombic/POSCAR-019" : 19,
      "SpglibTestData/orthorhombic/POSCAR-019-2" : 19,
      "SpglibTestData/orthorhombic/POSCAR-020" : 20,
      "SpglibTestData/orthorhombic/POSCAR-021" : 21,
      "SpglibTestData/orthorhombic/POSCAR-021-2" : 21,
      "SpglibTestData/orthorhombic/POSCAR-022" : 22,
      "SpglibTestData/orthorhombic/POSCAR-023" : 23,
      "SpglibTestData/orthorhombic/POSCAR-023-2" : 23,
      "SpglibTestData/orthorhombic/POSCAR-024" : 24,
      "SpglibTestData/orthorhombic/POSCAR-024-2" : 24,
      "SpglibTestData/orthorhombic/POSCAR-025" : 25,
      "SpglibTestData/orthorhombic/POSCAR-025-2" : 25,
      "SpglibTestData/orthorhombic/POSCAR-026" : 26,
      "SpglibTestData/orthorhombic/POSCAR-026-2" : 26,
      "SpglibTestData/orthorhombic/POSCAR-027" : 27,
      "SpglibTestData/orthorhombic/POSCAR-027-2" : 27,
      "SpglibTestData/orthorhombic/POSCAR-028" : 28,
      "SpglibTestData/orthorhombic/POSCAR-028-2" : 28,
      "SpglibTestData/orthorhombic/POSCAR-029" : 29,
      "SpglibTestData/orthorhombic/POSCAR-029-2" : 29,
      "SpglibTestData/orthorhombic/POSCAR-030" : 30,
      "SpglibTestData/orthorhombic/POSCAR-030-2" : 30,
      "SpglibTestData/orthorhombic/POSCAR-031" : 31,
      "SpglibTestData/orthorhombic/POSCAR-031-2" : 31,
      "SpglibTestData/orthorhombic/POSCAR-032" : 32,
      "SpglibTestData/orthorhombic/POSCAR-032-2" : 32,
      "SpglibTestData/orthorhombic/POSCAR-033" : 33,
      "SpglibTestData/orthorhombic/POSCAR-033-2" : 33,
      "SpglibTestData/orthorhombic/POSCAR-033-3" : 33,
      "SpglibTestData/orthorhombic/POSCAR-034" : 34,
      "SpglibTestData/orthorhombic/POSCAR-034-2" : 34,
      "SpglibTestData/orthorhombic/POSCAR-035" : 35,
      "SpglibTestData/orthorhombic/POSCAR-035-2" : 35,
      "SpglibTestData/orthorhombic/POSCAR-036" : 36,
      "SpglibTestData/orthorhombic/POSCAR-036-2" : 36,
      "SpglibTestData/orthorhombic/POSCAR-037" : 37,
      "SpglibTestData/orthorhombic/POSCAR-037-2" : 37,
      "SpglibTestData/orthorhombic/POSCAR-038" : 38,
      "SpglibTestData/orthorhombic/POSCAR-038-2" : 38,
      "SpglibTestData/orthorhombic/POSCAR-039" : 39,
      "SpglibTestData/orthorhombic/POSCAR-039-2" : 39,
      "SpglibTestData/orthorhombic/POSCAR-040" : 40,
      "SpglibTestData/orthorhombic/POSCAR-040-2" : 40,
      "SpglibTestData/orthorhombic/POSCAR-041" : 41,
      "SpglibTestData/orthorhombic/POSCAR-041-2" : 41,
      "SpglibTestData/orthorhombic/POSCAR-042" : 42,
      "SpglibTestData/orthorhombic/POSCAR-043" : 43,
      "SpglibTestData/orthorhombic/POSCAR-043-2" : 43,
      "SpglibTestData/orthorhombic/POSCAR-044" : 44,
      "SpglibTestData/orthorhombic/POSCAR-044-2" : 44,
      "SpglibTestData/orthorhombic/POSCAR-045" : 45,
      "SpglibTestData/orthorhombic/POSCAR-045-2" : 45,
      "SpglibTestData/orthorhombic/POSCAR-046" : 46,
      "SpglibTestData/orthorhombic/POSCAR-046-2" : 46,
      "SpglibTestData/orthorhombic/POSCAR-047" : 47,
      "SpglibTestData/orthorhombic/POSCAR-047-2" : 47,
      "SpglibTestData/orthorhombic/POSCAR-048" : 48,
      "SpglibTestData/orthorhombic/POSCAR-048-2" : 48,
      "SpglibTestData/orthorhombic/POSCAR-049" : 49,
      "SpglibTestData/orthorhombic/POSCAR-049-2" : 49,
      "SpglibTestData/orthorhombic/POSCAR-050" : 50,
      "SpglibTestData/orthorhombic/POSCAR-050-2" : 50,
      "SpglibTestData/orthorhombic/POSCAR-051" : 51,
      "SpglibTestData/orthorhombic/POSCAR-051-2" : 51,
      "SpglibTestData/orthorhombic/POSCAR-051-3" : 51,
      "SpglibTestData/orthorhombic/POSCAR-052" : 52,
      "SpglibTestData/orthorhombic/POSCAR-052-2" : 52,
      "SpglibTestData/orthorhombic/POSCAR-053" : 53,
      "SpglibTestData/orthorhombic/POSCAR-053-2" : 53,
      "SpglibTestData/orthorhombic/POSCAR-054" : 54,
      "SpglibTestData/orthorhombic/POSCAR-054-2" : 54,
      "SpglibTestData/orthorhombic/POSCAR-055" : 55,
      "SpglibTestData/orthorhombic/POSCAR-055-2" : 55,
      "SpglibTestData/orthorhombic/POSCAR-056" : 56,
      "SpglibTestData/orthorhombic/POSCAR-056-2" : 56,
      "SpglibTestData/orthorhombic/POSCAR-057" : 57,
      "SpglibTestData/orthorhombic/POSCAR-057-2" : 57,
      "SpglibTestData/orthorhombic/POSCAR-058" : 58,
      "SpglibTestData/orthorhombic/POSCAR-058-2" : 58,
      "SpglibTestData/orthorhombic/POSCAR-058-3" : 58,
      "SpglibTestData/orthorhombic/POSCAR-059" : 59,
      "SpglibTestData/orthorhombic/POSCAR-059-2" : 59,
      "SpglibTestData/orthorhombic/POSCAR-060" : 60,
      "SpglibTestData/orthorhombic/POSCAR-060-2" : 60,
      "SpglibTestData/orthorhombic/POSCAR-060-3" : 60,
      "SpglibTestData/orthorhombic/POSCAR-061" : 61,
      "SpglibTestData/orthorhombic/POSCAR-061-2" : 61,
      "SpglibTestData/orthorhombic/POSCAR-062" : 62,
      "SpglibTestData/orthorhombic/POSCAR-062-2" : 62,
      "SpglibTestData/orthorhombic/POSCAR-063" : 63,
      "SpglibTestData/orthorhombic/POSCAR-063-2" : 63,
      "SpglibTestData/orthorhombic/POSCAR-063-3" : 63,
      "SpglibTestData/orthorhombic/POSCAR-064" : 64,
      "SpglibTestData/orthorhombic/POSCAR-064-2" : 64,
      "SpglibTestData/orthorhombic/POSCAR-064-3" : 64,
      "SpglibTestData/orthorhombic/POSCAR-065" : 65,
      "SpglibTestData/orthorhombic/POSCAR-065-2" : 65,
      "SpglibTestData/orthorhombic/POSCAR-065-3" : 65,
      "SpglibTestData/orthorhombic/POSCAR-066" : 66,
      "SpglibTestData/orthorhombic/POSCAR-066-2" : 66,
      "SpglibTestData/orthorhombic/POSCAR-067" : 67,
      "SpglibTestData/orthorhombic/POSCAR-067-2" : 67,
      "SpglibTestData/orthorhombic/POSCAR-067-3" : 67,
      "SpglibTestData/orthorhombic/POSCAR-068" : 68,
      "SpglibTestData/orthorhombic/POSCAR-068-2" : 68,
      "SpglibTestData/orthorhombic/POSCAR-069" : 69,
      "SpglibTestData/orthorhombic/POSCAR-069-2" : 69,
      "SpglibTestData/orthorhombic/POSCAR-070" : 70,
      "SpglibTestData/orthorhombic/POSCAR-070-2" : 70,
      "SpglibTestData/orthorhombic/POSCAR-071" : 71,
      "SpglibTestData/orthorhombic/POSCAR-071-2" : 71,
      "SpglibTestData/orthorhombic/POSCAR-072" : 72,
      "SpglibTestData/orthorhombic/POSCAR-072-2" : 72,
      "SpglibTestData/orthorhombic/POSCAR-073" : 73,
      "SpglibTestData/orthorhombic/POSCAR-073-2" : 73,
      "SpglibTestData/orthorhombic/POSCAR-074" : 74,
      "SpglibTestData/orthorhombic/POSCAR-074-2" : 74
    ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, referenceSpaceGroupValue) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, allowOverlappingAtomTypes: false, symmetryPrecision: precision)
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            XCTAssertEqual(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber, referenceSpaceGroupValue, "Wrong space group found for \(fileName)")
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
      "SpglibTestData/tetragonal/POSCAR-075" : 75,
      "SpglibTestData/tetragonal/POSCAR-075-2" : 75,
      "SpglibTestData/tetragonal/POSCAR-076" : 76,
      "SpglibTestData/tetragonal/POSCAR-076-2" : 76,
      "SpglibTestData/tetragonal/POSCAR-077" : 77,
      "SpglibTestData/tetragonal/POSCAR-077-2" : 77,
      "SpglibTestData/tetragonal/POSCAR-077-3" : 77,
      "SpglibTestData/tetragonal/POSCAR-078" : 78,
      "SpglibTestData/tetragonal/POSCAR-078-2" : 78,
      "SpglibTestData/tetragonal/POSCAR-079" : 79,
      "SpglibTestData/tetragonal/POSCAR-079-2" : 79,
      "SpglibTestData/tetragonal/POSCAR-080" : 80,
      "SpglibTestData/tetragonal/POSCAR-080-2" : 80,
      "SpglibTestData/tetragonal/POSCAR-081" : 81,
      "SpglibTestData/tetragonal/POSCAR-081-2" : 81,
      "SpglibTestData/tetragonal/POSCAR-082" : 82,
      "SpglibTestData/tetragonal/POSCAR-082-2" : 82,
      "SpglibTestData/tetragonal/POSCAR-083" : 83,
      "SpglibTestData/tetragonal/POSCAR-083-2" : 83,
      "SpglibTestData/tetragonal/POSCAR-083-3" : 83,
      "SpglibTestData/tetragonal/POSCAR-084" : 84,
      "SpglibTestData/tetragonal/POSCAR-084-2" : 84,
      "SpglibTestData/tetragonal/POSCAR-085" : 85,
      "SpglibTestData/tetragonal/POSCAR-085-2" : 85,
      "SpglibTestData/tetragonal/POSCAR-086" : 86,
      "SpglibTestData/tetragonal/POSCAR-086-2" : 86,
      "SpglibTestData/tetragonal/POSCAR-087" : 87,
      "SpglibTestData/tetragonal/POSCAR-087-2" : 87,
      "SpglibTestData/tetragonal/POSCAR-088" : 88,
      "SpglibTestData/tetragonal/POSCAR-088-2" : 88,
      "SpglibTestData/tetragonal/POSCAR-090" : 90,
      "SpglibTestData/tetragonal/POSCAR-090-2" : 90,
      "SpglibTestData/tetragonal/POSCAR-091" : 91,
      "SpglibTestData/tetragonal/POSCAR-091-2" :91 ,
      "SpglibTestData/tetragonal/POSCAR-092" : 92,
      "SpglibTestData/tetragonal/POSCAR-092-2" : 92,
      "SpglibTestData/tetragonal/POSCAR-092-3" : 92,
      "SpglibTestData/tetragonal/POSCAR-094" : 94,
      "SpglibTestData/tetragonal/POSCAR-094-2" : 94,
      "SpglibTestData/tetragonal/POSCAR-094-3" : 94,
      "SpglibTestData/tetragonal/POSCAR-095" : 95,
      "SpglibTestData/tetragonal/POSCAR-095-2" : 95,
      "SpglibTestData/tetragonal/POSCAR-096" : 96,
      "SpglibTestData/tetragonal/POSCAR-096-2" : 96,
      "SpglibTestData/tetragonal/POSCAR-097" : 97,
      "SpglibTestData/tetragonal/POSCAR-097-2" : 97,
      "SpglibTestData/tetragonal/POSCAR-098" : 98,
      "SpglibTestData/tetragonal/POSCAR-098-2" : 98,
      "SpglibTestData/tetragonal/POSCAR-099" : 99,
      "SpglibTestData/tetragonal/POSCAR-099-2" : 99,
      "SpglibTestData/tetragonal/POSCAR-100" : 100,
      "SpglibTestData/tetragonal/POSCAR-100-2" : 100,
      "SpglibTestData/tetragonal/POSCAR-102" : 102,
      "SpglibTestData/tetragonal/POSCAR-102-2" : 102,
      "SpglibTestData/tetragonal/POSCAR-103" : 103,
      "SpglibTestData/tetragonal/POSCAR-103-2" : 103,
      "SpglibTestData/tetragonal/POSCAR-104" : 104,
      "SpglibTestData/tetragonal/POSCAR-104-2" : 104,
      "SpglibTestData/tetragonal/POSCAR-105" : 105,
      "SpglibTestData/tetragonal/POSCAR-105-2" : 105,
      "SpglibTestData/tetragonal/POSCAR-106" : 106,
      "SpglibTestData/tetragonal/POSCAR-107" : 107,
      "SpglibTestData/tetragonal/POSCAR-107-2" : 107,
      "SpglibTestData/tetragonal/POSCAR-107-3" : 107,
      "SpglibTestData/tetragonal/POSCAR-108" : 108,
      "SpglibTestData/tetragonal/POSCAR-108-2" : 108,
      "SpglibTestData/tetragonal/POSCAR-109" : 109,
      "SpglibTestData/tetragonal/POSCAR-109-2" : 109,
      "SpglibTestData/tetragonal/POSCAR-110" : 110,
      "SpglibTestData/tetragonal/POSCAR-110-2" : 110,
      "SpglibTestData/tetragonal/POSCAR-111" : 111,
      "SpglibTestData/tetragonal/POSCAR-111-2" : 111,
      "SpglibTestData/tetragonal/POSCAR-112" : 112,
      "SpglibTestData/tetragonal/POSCAR-112-2" : 112,
      "SpglibTestData/tetragonal/POSCAR-113" : 113,
      "SpglibTestData/tetragonal/POSCAR-113-2" : 113,
      "SpglibTestData/tetragonal/POSCAR-114" : 114,
      "SpglibTestData/tetragonal/POSCAR-114-2" : 114,
      "SpglibTestData/tetragonal/POSCAR-115" : 115,
      "SpglibTestData/tetragonal/POSCAR-115-2" : 115,
      "SpglibTestData/tetragonal/POSCAR-115-3" : 115,
      "SpglibTestData/tetragonal/POSCAR-115-4" : 115,
      "SpglibTestData/tetragonal/POSCAR-115-5" : 115,
      "SpglibTestData/tetragonal/POSCAR-116" : 116,
      "SpglibTestData/tetragonal/POSCAR-116-2" : 116,
      "SpglibTestData/tetragonal/POSCAR-117" : 117,
      "SpglibTestData/tetragonal/POSCAR-117-2" : 117,
      "SpglibTestData/tetragonal/POSCAR-118" : 118,
      "SpglibTestData/tetragonal/POSCAR-118-2" : 118,
      "SpglibTestData/tetragonal/POSCAR-119" : 119,
      "SpglibTestData/tetragonal/POSCAR-119-2" : 119,
      "SpglibTestData/tetragonal/POSCAR-120" : 120,
      "SpglibTestData/tetragonal/POSCAR-120-2" : 120,
      "SpglibTestData/tetragonal/POSCAR-121" : 121,
      "SpglibTestData/tetragonal/POSCAR-121-2" : 121,
      "SpglibTestData/tetragonal/POSCAR-122" : 122,
      "SpglibTestData/tetragonal/POSCAR-122-2" : 122,
      "SpglibTestData/tetragonal/POSCAR-122-3" : 122,
      "SpglibTestData/tetragonal/POSCAR-123" : 123,
      "SpglibTestData/tetragonal/POSCAR-123-2" : 123,
      "SpglibTestData/tetragonal/POSCAR-123-3" : 123,
      "SpglibTestData/tetragonal/POSCAR-124" : 124,
      "SpglibTestData/tetragonal/POSCAR-124-2" : 124,
      "SpglibTestData/tetragonal/POSCAR-125" : 125,
      "SpglibTestData/tetragonal/POSCAR-125-2" : 125,
      "SpglibTestData/tetragonal/POSCAR-126" : 126,
      "SpglibTestData/tetragonal/POSCAR-126-2" : 126,
      "SpglibTestData/tetragonal/POSCAR-127" : 127,
      "SpglibTestData/tetragonal/POSCAR-127-2" : 127,
      "SpglibTestData/tetragonal/POSCAR-128" : 128,
      "SpglibTestData/tetragonal/POSCAR-128-2" : 128,
      "SpglibTestData/tetragonal/POSCAR-129" : 129,
      "SpglibTestData/tetragonal/POSCAR-129-2" : 129,
      "SpglibTestData/tetragonal/POSCAR-129-3" : 129,
      "SpglibTestData/tetragonal/POSCAR-130" : 130,
      "SpglibTestData/tetragonal/POSCAR-130-2" : 130,
      "SpglibTestData/tetragonal/POSCAR-131" : 131,
      "SpglibTestData/tetragonal/POSCAR-131-2" : 131,
      "SpglibTestData/tetragonal/POSCAR-132" : 132,
      "SpglibTestData/tetragonal/POSCAR-132-2" : 132,
      "SpglibTestData/tetragonal/POSCAR-133" : 133,
      "SpglibTestData/tetragonal/POSCAR-133-2" : 133,
      "SpglibTestData/tetragonal/POSCAR-134" : 134,
      "SpglibTestData/tetragonal/POSCAR-134-2" : 134,
      "SpglibTestData/tetragonal/POSCAR-135" : 135,
      "SpglibTestData/tetragonal/POSCAR-135-2" : 135,
      "SpglibTestData/tetragonal/POSCAR-136" : 136,
      "SpglibTestData/tetragonal/POSCAR-136-2" : 136,
      "SpglibTestData/tetragonal/POSCAR-136-3" : 136,
      "SpglibTestData/tetragonal/POSCAR-136-4" : 136,
      "SpglibTestData/tetragonal/POSCAR-136-5" : 136,
      "SpglibTestData/tetragonal/POSCAR-137" : 137,
      "SpglibTestData/tetragonal/POSCAR-137-2" : 137,
      "SpglibTestData/tetragonal/POSCAR-137-3" : 137,
      "SpglibTestData/tetragonal/POSCAR-138" : 138,
      "SpglibTestData/tetragonal/POSCAR-138-2" : 138,
      "SpglibTestData/tetragonal/POSCAR-139" : 139,
      "SpglibTestData/tetragonal/POSCAR-139-2" : 139,
      "SpglibTestData/tetragonal/POSCAR-140" : 140,
      "SpglibTestData/tetragonal/POSCAR-140-2" : 140,
      "SpglibTestData/tetragonal/POSCAR-141" : 141,
      "SpglibTestData/tetragonal/POSCAR-141-2" : 141,
      "SpglibTestData/tetragonal/POSCAR-142" : 142,
      "SpglibTestData/tetragonal/POSCAR-142-2" : 142,
      "SpglibTestData/tetragonal/POSCAR-142-3" : 142
    ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, referenceSpaceGroupValue) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, allowOverlappingAtomTypes: false, symmetryPrecision: precision)
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            XCTAssertEqual(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber, referenceSpaceGroupValue, "Wrong space group found for \(fileName)")
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
      "SpglibTestData/trigonal/POSCAR-143" : 143,
      "SpglibTestData/trigonal/POSCAR-143-2" : 143,
      "SpglibTestData/trigonal/POSCAR-144" : 144,
      "SpglibTestData/trigonal/POSCAR-144-2" : 144,
      "SpglibTestData/trigonal/POSCAR-145" : 145,
      "SpglibTestData/trigonal/POSCAR-145-2" : 145,
      "SpglibTestData/trigonal/POSCAR-146" : 146,
      "SpglibTestData/trigonal/POSCAR-146-2" : 146,
      "SpglibTestData/trigonal/POSCAR-147" : 147,
      "SpglibTestData/trigonal/POSCAR-147-2" : 147,
      "SpglibTestData/trigonal/POSCAR-148" : 148,
      "SpglibTestData/trigonal/POSCAR-148-2" : 148,
      "SpglibTestData/trigonal/POSCAR-149" : 149,
      "SpglibTestData/trigonal/POSCAR-149-2" : 149,
      "SpglibTestData/trigonal/POSCAR-150" : 150,
      "SpglibTestData/trigonal/POSCAR-150-2" : 150,
      "SpglibTestData/trigonal/POSCAR-151" : 151,
      "SpglibTestData/trigonal/POSCAR-151-2" : 151,
      "SpglibTestData/trigonal/POSCAR-152" : 152,
      "SpglibTestData/trigonal/POSCAR-152-2" : 152,
      "SpglibTestData/trigonal/POSCAR-153" : 153,
      "SpglibTestData/trigonal/POSCAR-154" : 154,
      "SpglibTestData/trigonal/POSCAR-154-2" : 154,
      "SpglibTestData/trigonal/POSCAR-154-3" : 154,
      "SpglibTestData/trigonal/POSCAR-155" : 155,
      "SpglibTestData/trigonal/POSCAR-155-2" : 155,
      "SpglibTestData/trigonal/POSCAR-156" : 156,
      "SpglibTestData/trigonal/POSCAR-156-2" : 156,
      "SpglibTestData/trigonal/POSCAR-157" : 157,
      "SpglibTestData/trigonal/POSCAR-157-2" : 157,
      "SpglibTestData/trigonal/POSCAR-158" : 158,
      "SpglibTestData/trigonal/POSCAR-158-2" : 158,
      "SpglibTestData/trigonal/POSCAR-159" : 159,
      "SpglibTestData/trigonal/POSCAR-159-2" : 159,
      "SpglibTestData/trigonal/POSCAR-160" : 160,
      "SpglibTestData/trigonal/POSCAR-160-2" : 160,
      "SpglibTestData/trigonal/POSCAR-161" : 161,
      "SpglibTestData/trigonal/POSCAR-161-2" : 161,
      "SpglibTestData/trigonal/POSCAR-162" : 162,
      "SpglibTestData/trigonal/POSCAR-162-2" : 162,
      "SpglibTestData/trigonal/POSCAR-163" : 163,
      "SpglibTestData/trigonal/POSCAR-163-2" : 163,
      "SpglibTestData/trigonal/POSCAR-164" : 164,
      "SpglibTestData/trigonal/POSCAR-164-2" : 164,
      "SpglibTestData/trigonal/POSCAR-165" : 165,
      "SpglibTestData/trigonal/POSCAR-165-2" : 165,
      "SpglibTestData/trigonal/POSCAR-166" : 166,
      "SpglibTestData/trigonal/POSCAR-166-2" : 166,
      "SpglibTestData/trigonal/POSCAR-167" : 167,
      "SpglibTestData/trigonal/POSCAR-167-2" : 167,
      "SpglibTestData/trigonal/POSCAR-167-3" : 167
    ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, referenceSpaceGroupValue) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, allowOverlappingAtomTypes: false, symmetryPrecision: precision)
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            XCTAssertEqual(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber, referenceSpaceGroupValue, "Wrong space group found for \(fileName)")
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
      "SpglibTestData/hexagonal/POSCAR-168" : 168,
      "SpglibTestData/hexagonal/POSCAR-169" : 169,
      "SpglibTestData/hexagonal/POSCAR-169-2" : 169,
      "SpglibTestData/hexagonal/POSCAR-170" : 170,
      "SpglibTestData/hexagonal/POSCAR-170-2" : 170,
      "SpglibTestData/hexagonal/POSCAR-171" : 171,
      "SpglibTestData/hexagonal/POSCAR-171-2" : 171,
      "SpglibTestData/hexagonal/POSCAR-172" : 172,
      "SpglibTestData/hexagonal/POSCAR-173" : 173,
      "SpglibTestData/hexagonal/POSCAR-173-2" : 173,
      "SpglibTestData/hexagonal/POSCAR-174" : 174,
      "SpglibTestData/hexagonal/POSCAR-174-2" : 174,
      "SpglibTestData/hexagonal/POSCAR-175" : 175,
      "SpglibTestData/hexagonal/POSCAR-175-2" : 175,
      "SpglibTestData/hexagonal/POSCAR-176" : 176,
      "SpglibTestData/hexagonal/POSCAR-176-2" : 176,
      "SpglibTestData/hexagonal/POSCAR-177" : 177,
      "SpglibTestData/hexagonal/POSCAR-179" : 179,
      "SpglibTestData/hexagonal/POSCAR-179-2" : 179,
      "SpglibTestData/hexagonal/POSCAR-180" : 180,
      "SpglibTestData/hexagonal/POSCAR-180-2" : 180,
      "SpglibTestData/hexagonal/POSCAR-181" : 181,
      "SpglibTestData/hexagonal/POSCAR-181-2" : 181,
      "SpglibTestData/hexagonal/POSCAR-182" : 182,
      "SpglibTestData/hexagonal/POSCAR-182-2" : 182,
      "SpglibTestData/hexagonal/POSCAR-183" : 183,
      "SpglibTestData/hexagonal/POSCAR-183-2" : 183,
      "SpglibTestData/hexagonal/POSCAR-184" : 184,
      "SpglibTestData/hexagonal/POSCAR-184-2" : 184,
      "SpglibTestData/hexagonal/POSCAR-185" : 185,
      "SpglibTestData/hexagonal/POSCAR-185-2" : 185,
      "SpglibTestData/hexagonal/POSCAR-186" : 186,
      "SpglibTestData/hexagonal/POSCAR-186-2" : 186,
      "SpglibTestData/hexagonal/POSCAR-187" : 187,
      "SpglibTestData/hexagonal/POSCAR-187-2" : 187,
      "SpglibTestData/hexagonal/POSCAR-188" : 188,
      "SpglibTestData/hexagonal/POSCAR-188-2" : 188,
      "SpglibTestData/hexagonal/POSCAR-189" : 189,
      "SpglibTestData/hexagonal/POSCAR-189-2" : 189,
      "SpglibTestData/hexagonal/POSCAR-190" : 190,
      "SpglibTestData/hexagonal/POSCAR-190-2" : 190,
      "SpglibTestData/hexagonal/POSCAR-191" : 191,
      "SpglibTestData/hexagonal/POSCAR-191-2" : 191,
      "SpglibTestData/hexagonal/POSCAR-192" : 192,
      "SpglibTestData/hexagonal/POSCAR-192-2" : 192,
      "SpglibTestData/hexagonal/POSCAR-193" : 193,
      "SpglibTestData/hexagonal/POSCAR-193-2" : 193,
      "SpglibTestData/hexagonal/POSCAR-194" : 194,
      "SpglibTestData/hexagonal/POSCAR-194-2" : 194
    ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, referenceSpaceGroupValue) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, allowOverlappingAtomTypes: false, symmetryPrecision: precision)
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            XCTAssertEqual(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber, referenceSpaceGroupValue, "Wrong space group found for \(fileName)")
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
      "SpglibTestData/cubic/POSCAR-195" : 195,
      "SpglibTestData/cubic/POSCAR-195-2" : 195,
      "SpglibTestData/cubic/POSCAR-196" : 196,
      "SpglibTestData/cubic/POSCAR-196-2" : 196,
      "SpglibTestData/cubic/POSCAR-197" : 197,
      "SpglibTestData/cubic/POSCAR-197-2" : 197,
      "SpglibTestData/cubic/POSCAR-198" : 198,
      "SpglibTestData/cubic/POSCAR-198-2" : 198,
      "SpglibTestData/cubic/POSCAR-199" : 199,
      "SpglibTestData/cubic/POSCAR-199-2" : 199,
      "SpglibTestData/cubic/POSCAR-200" : 200,
      "SpglibTestData/cubic/POSCAR-200-2" : 200,
      "SpglibTestData/cubic/POSCAR-205" :205,
      "SpglibTestData/cubic/POSCAR-205-3" : 205,
      "SpglibTestData/cubic/POSCAR-206" : 206,
      "SpglibTestData/cubic/POSCAR-206-2" : 206,
      "SpglibTestData/cubic/POSCAR-207" : 207,
      "SpglibTestData/cubic/POSCAR-208" : 208,
      "SpglibTestData/cubic/POSCAR-208-2" : 208,
      "SpglibTestData/cubic/POSCAR-209" : 209,
      "SpglibTestData/cubic/POSCAR-210" : 210,
      "SpglibTestData/cubic/POSCAR-210-2" : 210,
      "SpglibTestData/cubic/POSCAR-211" : 211,
      "SpglibTestData/cubic/POSCAR-212" : 212,
      "SpglibTestData/cubic/POSCAR-212-2" : 212,
      "SpglibTestData/cubic/POSCAR-213" : 213,
      "SpglibTestData/cubic/POSCAR-213-2" : 213,
      "SpglibTestData/cubic/POSCAR-214" : 214,
      "SpglibTestData/cubic/POSCAR-214-2" : 214,
      "SpglibTestData/cubic/POSCAR-215" : 215,
      "SpglibTestData/cubic/POSCAR-215-2" : 215,
      "SpglibTestData/cubic/POSCAR-216" : 216,
      "SpglibTestData/cubic/POSCAR-216-2" : 216,
      "SpglibTestData/cubic/POSCAR-217" : 217,
      "SpglibTestData/cubic/POSCAR-217-2" : 217,
      "SpglibTestData/cubic/POSCAR-218" : 218,
      "SpglibTestData/cubic/POSCAR-218-2" : 218,
      "SpglibTestData/cubic/POSCAR-219" : 219,
      "SpglibTestData/cubic/POSCAR-219-2" : 219,
      "SpglibTestData/cubic/POSCAR-220" : 220,
      "SpglibTestData/cubic/POSCAR-220-2" : 220,
      "SpglibTestData/cubic/POSCAR-221" : 221,
      "SpglibTestData/cubic/POSCAR-221-2" : 221,
      "SpglibTestData/cubic/POSCAR-222" : 222,
      "SpglibTestData/cubic/POSCAR-222-2" : 222,
      "SpglibTestData/cubic/POSCAR-223" : 223,
      "SpglibTestData/cubic/POSCAR-223-2" : 223,
      "SpglibTestData/cubic/POSCAR-224" : 224,
      "SpglibTestData/cubic/POSCAR-224-2" : 224,
      "SpglibTestData/cubic/POSCAR-225" : 225,
      "SpglibTestData/cubic/POSCAR-225-2" : 225,
      "SpglibTestData/cubic/POSCAR-226" : 226,
      "SpglibTestData/cubic/POSCAR-226-2" : 226,
      "SpglibTestData/cubic/POSCAR-227" : 227,
      "SpglibTestData/cubic/POSCAR-227-2" : 227,
      "SpglibTestData/cubic/POSCAR-228" : 228,
      "SpglibTestData/cubic/POSCAR-228-2" : 228,
      "SpglibTestData/cubic/POSCAR-229" : 229,
      "SpglibTestData/cubic/POSCAR-229-2" : 229,
      "SpglibTestData/cubic/POSCAR-230" : 230,
      "SpglibTestData/cubic/POSCAR-230-2" : 230,
      "SpglibTestData/cubic/POSCAR-230-3" : 230,
      "SpglibTestData/cubic/POSCAR-230-4" : 230
    ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, referenceSpaceGroupValue) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, allowOverlappingAtomTypes: false, symmetryPrecision: precision)
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            XCTAssertEqual(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber, referenceSpaceGroupValue, "Wrong space group found for \(fileName)")
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
      "SpglibTestData/virtual_structure/POSCAR-3-221-29" : 3,
      "SpglibTestData/virtual_structure/POSCAR-3-222-29" : 3,
      "SpglibTestData/virtual_structure/POSCAR-3-223-29" : 3,
      "SpglibTestData/virtual_structure/POSCAR-3-224-29" : 3,
      "SpglibTestData/virtual_structure/POSCAR-3-227-82" : 3,
      "SpglibTestData/virtual_structure/POSCAR-3-227-95" : 3,
      "SpglibTestData/virtual_structure/POSCAR-3-230-conv-58" : 3,
      "SpglibTestData/virtual_structure/POSCAR-4-227-77" : 4,
      "SpglibTestData/virtual_structure/POSCAR-4-227-81" : 4,
      "SpglibTestData/virtual_structure/POSCAR-4-227-96" : 4,
      "SpglibTestData/virtual_structure/POSCAR-4-230-conv-59" : 4,
      "SpglibTestData/virtual_structure/POSCAR-5-221-32" : 5,
      "SpglibTestData/virtual_structure/POSCAR-5-222-32" : 5,
      "SpglibTestData/virtual_structure/POSCAR-5-223-32" : 5,
      "SpglibTestData/virtual_structure/POSCAR-5-224-32" : 5,
      "SpglibTestData/virtual_structure/POSCAR-5-227-45" : 5,
      "SpglibTestData/virtual_structure/POSCAR-5-227-75" : 5,
      "SpglibTestData/virtual_structure/POSCAR-5-227-98" : 5,
      "SpglibTestData/virtual_structure/POSCAR-5-230-conv-40" : 5,
      "SpglibTestData/virtual_structure/POSCAR-5-230-conv-43" : 5,
      "SpglibTestData/virtual_structure/POSCAR-5-230-conv-61" : 5,
      "SpglibTestData/virtual_structure/POSCAR-5-230-prim-29" : 5,
      "SpglibTestData/virtual_structure/POSCAR-5-230-prim-32" : 5,
      "SpglibTestData/virtual_structure/POSCAR-5-bcc-29" : 5,
      "SpglibTestData/virtual_structure/POSCAR-5-bcc-32" : 5,
      "SpglibTestData/virtual_structure/POSCAR-6-221-30" : 6,
      "SpglibTestData/virtual_structure/POSCAR-6-223-30" : 6,
      "SpglibTestData/virtual_structure/POSCAR-6-227-79" : 6,
      "SpglibTestData/virtual_structure/POSCAR-7-222-30" : 7,
      "SpglibTestData/virtual_structure/POSCAR-7-224-30" : 7,
      "SpglibTestData/virtual_structure/POSCAR-7-227-78" : 7,
      "SpglibTestData/virtual_structure/POSCAR-7-227-80" : 7,
      "SpglibTestData/virtual_structure/POSCAR-7-230-conv-60" : 7,
      "SpglibTestData/virtual_structure/POSCAR-8-221-31" : 8,
      "SpglibTestData/virtual_structure/POSCAR-8-224-31" : 8,
      "SpglibTestData/virtual_structure/POSCAR-8-227-44" : 8,
      "SpglibTestData/virtual_structure/POSCAR-8-227-97" : 8,
      "SpglibTestData/virtual_structure/POSCAR-9-222-31" : 9,
      "SpglibTestData/virtual_structure/POSCAR-9-223-31" : 9,
      "SpglibTestData/virtual_structure/POSCAR-9-227-43" : 9,
      "SpglibTestData/virtual_structure/POSCAR-9-230-conv-41" : 9,
      "SpglibTestData/virtual_structure/POSCAR-9-230-conv-42" : 9,
      "SpglibTestData/virtual_structure/POSCAR-9-230-prim-30" : 9,
      "SpglibTestData/virtual_structure/POSCAR-9-230-prim-31" : 9,
      "SpglibTestData/virtual_structure/POSCAR-9-bcc-30" : 9,
      "SpglibTestData/virtual_structure/POSCAR-9-bcc-31" : 9,
      "SpglibTestData/virtual_structure/POSCAR-10-221-18" : 10,
      "SpglibTestData/virtual_structure/POSCAR-10-223-18" : 10,
      "SpglibTestData/virtual_structure/POSCAR-10-227-50" : 10,
      "SpglibTestData/virtual_structure/POSCAR-11-227-48" : 11,
      "SpglibTestData/virtual_structure/POSCAR-12-221-19" : 12,
      "SpglibTestData/virtual_structure/POSCAR-12-224-19" : 12,
      "SpglibTestData/virtual_structure/POSCAR-12-227-21" : 12,
      "SpglibTestData/virtual_structure/POSCAR-12-227-83" : 12,
      "SpglibTestData/virtual_structure/POSCAR-13-222-18" : 13,
      "SpglibTestData/virtual_structure/POSCAR-13-224-18" : 13,
      "SpglibTestData/virtual_structure/POSCAR-13-227-49" : 13,
      "SpglibTestData/virtual_structure/POSCAR-13-230-conv-44" : 13,
      "SpglibTestData/virtual_structure/POSCAR-14-227-47" : 14,
      "SpglibTestData/virtual_structure/POSCAR-14-227-51" : 14,
      "SpglibTestData/virtual_structure/POSCAR-14-230-conv-45" : 14,
      "SpglibTestData/virtual_structure/POSCAR-15-222-19" : 15,
      "SpglibTestData/virtual_structure/POSCAR-15-223-19" : 15,
      "SpglibTestData/virtual_structure/POSCAR-15-230-conv-21" : 15,
      "SpglibTestData/virtual_structure/POSCAR-15-230-conv-22" : 15,
      "SpglibTestData/virtual_structure/POSCAR-15-230-prim-18" : 15,
      "SpglibTestData/virtual_structure/POSCAR-15-230-prim-19" : 15,
      "SpglibTestData/virtual_structure/POSCAR-15-bcc-18" : 15,
      "SpglibTestData/virtual_structure/POSCAR-15-bcc-19" : 15,
      "SpglibTestData/virtual_structure/POSCAR-16-221-20" : 16,
      "SpglibTestData/virtual_structure/POSCAR-16-222-20" : 16,
      "SpglibTestData/virtual_structure/POSCAR-16-223-20" : 16,
      "SpglibTestData/virtual_structure/POSCAR-16-224-20" : 16,
      "SpglibTestData/virtual_structure/POSCAR-16-227-84" : 16,
      "SpglibTestData/virtual_structure/POSCAR-17-227-60" : 17,
      "SpglibTestData/virtual_structure/POSCAR-17-227-85" : 17,
      "SpglibTestData/virtual_structure/POSCAR-17-230-conv-46" : 17,
      "SpglibTestData/virtual_structure/POSCAR-18-227-86" : 18,
      "SpglibTestData/virtual_structure/POSCAR-19-227-59" : 19,
      "SpglibTestData/virtual_structure/POSCAR-19-227-89" : 19,
      "SpglibTestData/virtual_structure/POSCAR-19-230-conv-51" : 19,
      "SpglibTestData/virtual_structure/POSCAR-20-227-53" : 20,
      "SpglibTestData/virtual_structure/POSCAR-20-227-90" : 20,
      "SpglibTestData/virtual_structure/POSCAR-20-230-conv-53" : 20,
      "SpglibTestData/virtual_structure/POSCAR-21-221-23" : 21,
      "SpglibTestData/virtual_structure/POSCAR-21-222-23" : 21,
      "SpglibTestData/virtual_structure/POSCAR-21-223-23" : 21,
      "SpglibTestData/virtual_structure/POSCAR-21-224-23" : 21,
      "SpglibTestData/virtual_structure/POSCAR-21-230-conv-49" : 21,
      "SpglibTestData/virtual_structure/POSCAR-22-230-conv-26" : 22,
      "SpglibTestData/virtual_structure/POSCAR-22-230-prim-23" : 22,
      "SpglibTestData/virtual_structure/POSCAR-24-230-conv-23" : 24,
      "SpglibTestData/virtual_structure/POSCAR-24-230-prim-20" : 24,
      "SpglibTestData/virtual_structure/POSCAR-25-221-21" : 25,
      "SpglibTestData/virtual_structure/POSCAR-25-223-21" : 25,
      "SpglibTestData/virtual_structure/POSCAR-25-227-54" : 25,
      "SpglibTestData/virtual_structure/POSCAR-26-227-64" : 26,
      "SpglibTestData/virtual_structure/POSCAR-27-230-conv-48" : 27,
      "SpglibTestData/virtual_structure/POSCAR-28-227-62" : 28,
      "SpglibTestData/virtual_structure/POSCAR-29-230-conv-52" : 29,
      "SpglibTestData/virtual_structure/POSCAR-30-227-65" : 30,
      "SpglibTestData/virtual_structure/POSCAR-31-227-58" : 31,
      "SpglibTestData/virtual_structure/POSCAR-32-230-conv-47" : 32,
      "SpglibTestData/virtual_structure/POSCAR-33-227-63" : 33,
      "SpglibTestData/virtual_structure/POSCAR-34-222-21" : 34,
      "SpglibTestData/virtual_structure/POSCAR-34-224-21" : 34,
      "SpglibTestData/virtual_structure/POSCAR-35-221-22" : 35,
      "SpglibTestData/virtual_structure/POSCAR-35-224-22" : 35,
      "SpglibTestData/virtual_structure/POSCAR-35-227-87" : 35,
      "SpglibTestData/virtual_structure/POSCAR-37-222-22" : 37,
      "SpglibTestData/virtual_structure/POSCAR-37-223-22" : 37,
      "SpglibTestData/virtual_structure/POSCAR-38-221-26" : 38,
      "SpglibTestData/virtual_structure/POSCAR-39-224-26" : 39,
      "SpglibTestData/virtual_structure/POSCAR-40-223-26" : 40,
      "SpglibTestData/virtual_structure/POSCAR-41-222-26" : 41,
      "SpglibTestData/virtual_structure/POSCAR-43-230-conv-25" : 43,
      "SpglibTestData/virtual_structure/POSCAR-43-230-conv-29" : 43,
      "SpglibTestData/virtual_structure/POSCAR-43-230-prim-22" : 43,
      "SpglibTestData/virtual_structure/POSCAR-43-230-prim-26" : 43,
      "SpglibTestData/virtual_structure/POSCAR-43-bcc-22" : 43,
      "SpglibTestData/virtual_structure/POSCAR-43-bcc-26" : 43,
      "SpglibTestData/virtual_structure/POSCAR-44-227-24" : 44,
      "SpglibTestData/virtual_structure/POSCAR-45-230-conv-24" : 45,
      "SpglibTestData/virtual_structure/POSCAR-45-230-prim-21" : 45,
      "SpglibTestData/virtual_structure/POSCAR-46-227-28" : 46,
      "SpglibTestData/virtual_structure/POSCAR-47-221-08" : 47,
      "SpglibTestData/virtual_structure/POSCAR-47-223-08" : 47,
      "SpglibTestData/virtual_structure/POSCAR-48-222-08" : 48,
      "SpglibTestData/virtual_structure/POSCAR-48-224-08" : 48,
      "SpglibTestData/virtual_structure/POSCAR-51-227-29" : 51,
      "SpglibTestData/virtual_structure/POSCAR-53-227-32" : 53,
      "SpglibTestData/virtual_structure/POSCAR-54-230-conv-30" : 54,
      "SpglibTestData/virtual_structure/POSCAR-61-230-conv-31" : 61,
      "SpglibTestData/virtual_structure/POSCAR-62-227-31" : 62,
      "SpglibTestData/virtual_structure/POSCAR-65-221-09" : 65,
      "SpglibTestData/virtual_structure/POSCAR-66-223-09" : 66,
      "SpglibTestData/virtual_structure/POSCAR-67-224-09" : 67,
      "SpglibTestData/virtual_structure/POSCAR-68-222-09" : 68,
      "SpglibTestData/virtual_structure/POSCAR-70-230-conv-11" : 70,
      "SpglibTestData/virtual_structure/POSCAR-70-230-prim-09" : 70,
      "SpglibTestData/virtual_structure/POSCAR-70-bcc-9" : 70,
      "SpglibTestData/virtual_structure/POSCAR-73-230-conv-10" : 73,
      "SpglibTestData/virtual_structure/POSCAR-73-230-prim-08" : 73,
      "SpglibTestData/virtual_structure/POSCAR-74-227-09" : 74,
      "SpglibTestData/virtual_structure/POSCAR-75-221-25" : 75,
      "SpglibTestData/virtual_structure/POSCAR-75-222-25" : 75,
      "SpglibTestData/virtual_structure/POSCAR-76-227-61" : 76,
      "SpglibTestData/virtual_structure/POSCAR-77-223-25" : 77,
      "SpglibTestData/virtual_structure/POSCAR-77-224-25" : 77,
      "SpglibTestData/virtual_structure/POSCAR-78-227-91" : 78,
      "SpglibTestData/virtual_structure/POSCAR-78-230-conv-54" : 78,
      "SpglibTestData/virtual_structure/POSCAR-80-230-conv-28" : 80,
      "SpglibTestData/virtual_structure/POSCAR-80-230-prim-25" : 80,
      "SpglibTestData/virtual_structure/POSCAR-81-221-24" : 81,
      "SpglibTestData/virtual_structure/POSCAR-81-222-24" : 81,
      "SpglibTestData/virtual_structure/POSCAR-81-223-24" : 81,
      "SpglibTestData/virtual_structure/POSCAR-81-224-24" : 81,
      "SpglibTestData/virtual_structure/POSCAR-81-227-88" : 81,
      "SpglibTestData/virtual_structure/POSCAR-81-230-conv-50" : 81,
      "SpglibTestData/virtual_structure/POSCAR-82-230-conv-27" : 82,
      "SpglibTestData/virtual_structure/POSCAR-82-230-prim-24" : 82,
      "SpglibTestData/virtual_structure/POSCAR-83-221-10" : 83,
      "SpglibTestData/virtual_structure/POSCAR-84-223-10" : 84,
      "SpglibTestData/virtual_structure/POSCAR-85-222-10" : 85,
      "SpglibTestData/virtual_structure/POSCAR-86-224-10" : 86,
      "SpglibTestData/virtual_structure/POSCAR-88-230-conv-12" : 88,
      "SpglibTestData/virtual_structure/POSCAR-88-230-prim-10" : 88,
      "SpglibTestData/virtual_structure/POSCAR-89-221-12" : 89,
      "SpglibTestData/virtual_structure/POSCAR-89-222-12" : 89,
      "SpglibTestData/virtual_structure/POSCAR-91-227-67" : 91,
      "SpglibTestData/virtual_structure/POSCAR-92-227-35" : 92,
      "SpglibTestData/virtual_structure/POSCAR-92-230-conv-35" : 92,
      "SpglibTestData/virtual_structure/POSCAR-93-223-12" : 93,
      "SpglibTestData/virtual_structure/POSCAR-93-224-12" : 93,
      "SpglibTestData/virtual_structure/POSCAR-95-227-36" : 95,
      "SpglibTestData/virtual_structure/POSCAR-95-230-conv-32" : 95,
      "SpglibTestData/virtual_structure/POSCAR-96-227-69" : 96,
      "SpglibTestData/virtual_structure/POSCAR-98-230-conv-14" : 98,
      "SpglibTestData/virtual_structure/POSCAR-98-230-prim-12" : 98,
      "SpglibTestData/virtual_structure/POSCAR-99-221-13" : 99,
      "SpglibTestData/virtual_structure/POSCAR-102-224-13" : 102,
      "SpglibTestData/virtual_structure/POSCAR-104-222-13" : 104,
      "SpglibTestData/virtual_structure/POSCAR-105-223-13" : 105,
      "SpglibTestData/virtual_structure/POSCAR-109-227-13" : 109,
      "SpglibTestData/virtual_structure/POSCAR-110-230-conv-15" : 110,
      "SpglibTestData/virtual_structure/POSCAR-110-230-prim-13" : 110,
      "SpglibTestData/virtual_structure/POSCAR-111-221-11" : 111,
      "SpglibTestData/virtual_structure/POSCAR-111-224-11" : 111,
      "SpglibTestData/virtual_structure/POSCAR-111-227-66" : 111,
      "SpglibTestData/virtual_structure/POSCAR-112-222-11" : 112,
      "SpglibTestData/virtual_structure/POSCAR-112-223-11" : 112,
      "SpglibTestData/virtual_structure/POSCAR-113-227-68" : 113,
      "SpglibTestData/virtual_structure/POSCAR-115-221-14" : 115,
      "SpglibTestData/virtual_structure/POSCAR-115-223-14" : 115,
      "SpglibTestData/virtual_structure/POSCAR-115-227-33" : 115,
      "SpglibTestData/virtual_structure/POSCAR-116-230-conv-34" : 116,
      "SpglibTestData/virtual_structure/POSCAR-117-230-conv-33" : 117,
      "SpglibTestData/virtual_structure/POSCAR-118-222-14" : 118,
      "SpglibTestData/virtual_structure/POSCAR-118-224-14" : 118,
      "SpglibTestData/virtual_structure/POSCAR-120-230-conv-16" : 120,
      "SpglibTestData/virtual_structure/POSCAR-120-230-prim-14" : 120,
      "SpglibTestData/virtual_structure/POSCAR-122-230-conv-13" : 122,
      "SpglibTestData/virtual_structure/POSCAR-122-230-prim-11" : 122,
      "SpglibTestData/virtual_structure/POSCAR-123-221-05" : 123,
      "SpglibTestData/virtual_structure/POSCAR-126-222-05" : 126,
      "SpglibTestData/virtual_structure/POSCAR-131-223-05" : 131,
      "SpglibTestData/virtual_structure/POSCAR-134-224-05" : 134,
      "SpglibTestData/virtual_structure/POSCAR-142-230-conv-05" : 142,
      "SpglibTestData/virtual_structure/POSCAR-142-230-prim-05" : 142,
      "SpglibTestData/virtual_structure/POSCAR-146-221-27" : 146,
      "SpglibTestData/virtual_structure/POSCAR-146-222-27" : 146,
      "SpglibTestData/virtual_structure/POSCAR-146-223-27" : 146,
      "SpglibTestData/virtual_structure/POSCAR-146-224-27" : 146,
      "SpglibTestData/virtual_structure/POSCAR-146-227-92" : 146,
      "SpglibTestData/virtual_structure/POSCAR-146-230-conv-36" : 146,
      "SpglibTestData/virtual_structure/POSCAR-146-230-conv-55" : 146,
      "SpglibTestData/virtual_structure/POSCAR-146-230-prim-27" : 146,
      "SpglibTestData/virtual_structure/POSCAR-146-bcc-27" : 146,
      "SpglibTestData/virtual_structure/POSCAR-148-221-15" : 148,
      "SpglibTestData/virtual_structure/POSCAR-148-222-15" : 148,
      "SpglibTestData/virtual_structure/POSCAR-148-223-15" : 148,
      "SpglibTestData/virtual_structure/POSCAR-148-224-15" : 148,
      "SpglibTestData/virtual_structure/POSCAR-148-227-70" : 148,
      "SpglibTestData/virtual_structure/POSCAR-148-230-conv-17" : 148,
      "SpglibTestData/virtual_structure/POSCAR-148-230-conv-37" : 148,
      "SpglibTestData/virtual_structure/POSCAR-148-230-prim-15" : 148,
      "SpglibTestData/virtual_structure/POSCAR-148-bcc-15" : 148,
      "SpglibTestData/virtual_structure/POSCAR-155-221-17" : 155,
      "SpglibTestData/virtual_structure/POSCAR-155-222-17" : 155,
      "SpglibTestData/virtual_structure/POSCAR-155-223-17" : 155,
      "SpglibTestData/virtual_structure/POSCAR-155-224-17" : 155,
      "SpglibTestData/virtual_structure/POSCAR-155-227-72" : 155,
      "SpglibTestData/virtual_structure/POSCAR-155-230-conv-19" : 155,
      "SpglibTestData/virtual_structure/POSCAR-155-230-conv-38" : 155,
      "SpglibTestData/virtual_structure/POSCAR-155-230-prim-17" : 155,
      "SpglibTestData/virtual_structure/POSCAR-155-bcc-17" : 155,
      "SpglibTestData/virtual_structure/POSCAR-160-221-16" : 160,
      "SpglibTestData/virtual_structure/POSCAR-160-224-16" : 160,
      "SpglibTestData/virtual_structure/POSCAR-160-227-16" : 160,
      "SpglibTestData/virtual_structure/POSCAR-160-227-71" : 160,
      "SpglibTestData/virtual_structure/POSCAR-160-fcc" : 160,
      "SpglibTestData/virtual_structure/POSCAR-161-222-16" : 161,
      "SpglibTestData/virtual_structure/POSCAR-161-223-16" : 161,
      "SpglibTestData/virtual_structure/POSCAR-161-230-conv-18" : 161,
      "SpglibTestData/virtual_structure/POSCAR-161-230-prim-16" : 161,
      "SpglibTestData/virtual_structure/POSCAR-161-bcc-16" : 161,
      "SpglibTestData/virtual_structure/POSCAR-166-221-06" : 166,
      "SpglibTestData/virtual_structure/POSCAR-166-224-06" : 166,
      "SpglibTestData/virtual_structure/POSCAR-166-227-06" : 166,
      "SpglibTestData/virtual_structure/POSCAR-166-227-38" : 166,
      "SpglibTestData/virtual_structure/POSCAR-167-222-06" : 167,
      "SpglibTestData/virtual_structure/POSCAR-167-223-06" : 167,
      "SpglibTestData/virtual_structure/POSCAR-167-230-conv-06" : 167,
      "SpglibTestData/virtual_structure/POSCAR-167-230-prim-06" : 167,
      "SpglibTestData/virtual_structure/POSCAR-167-bcc-6" : 167,
      "SpglibTestData/virtual_structure/POSCAR-195-221-07" : 195,
      "SpglibTestData/virtual_structure/POSCAR-195-222-07" : 195,
      "SpglibTestData/virtual_structure/POSCAR-195-223-07" : 195,
      "SpglibTestData/virtual_structure/POSCAR-195-224-07" : 195,
      "SpglibTestData/virtual_structure/POSCAR-198-227-40" : 198,
      "SpglibTestData/virtual_structure/POSCAR-198-230-conv-20" : 198,
      "SpglibTestData/virtual_structure/POSCAR-199-230-conv-07" : 199,
      "SpglibTestData/virtual_structure/POSCAR-199-230-prim-07" : 199,
      "SpglibTestData/virtual_structure/POSCAR-200-221-02" : 200,
      "SpglibTestData/virtual_structure/POSCAR-200-223-02" : 200,
      "SpglibTestData/virtual_structure/POSCAR-201-222-02" : 201,
      "SpglibTestData/virtual_structure/POSCAR-201-224-02" : 201,
      "SpglibTestData/virtual_structure/POSCAR-205-230-conv-08" : 205,
      "SpglibTestData/virtual_structure/POSCAR-206-230-conv-02" : 206,
      "SpglibTestData/virtual_structure/POSCAR-206-230-prim-02" : 206,
      "SpglibTestData/virtual_structure/POSCAR-207-221-04" : 207,
      "SpglibTestData/virtual_structure/POSCAR-207-222-04" : 207,
      "SpglibTestData/virtual_structure/POSCAR-208-223-04" : 208,
      "SpglibTestData/virtual_structure/POSCAR-208-224-04" : 208,
      "SpglibTestData/virtual_structure/POSCAR-212-227-19" : 212,
      "SpglibTestData/virtual_structure/POSCAR-213-230-conv-09" : 213,
      "SpglibTestData/virtual_structure/POSCAR-214-230-conv-04" : 214,
      "SpglibTestData/virtual_structure/POSCAR-214-230-prim-04" : 214,
      "SpglibTestData/virtual_structure/POSCAR-215-221-03" : 215,
      "SpglibTestData/virtual_structure/POSCAR-215-224-03" : 215,
      "SpglibTestData/virtual_structure/POSCAR-215-227-18" : 215,
      "SpglibTestData/virtual_structure/POSCAR-216-227-03" : 216,
      "SpglibTestData/virtual_structure/POSCAR-218-222-03" : 218,
      "SpglibTestData/virtual_structure/POSCAR-218-223-03" : 218,
      "SpglibTestData/virtual_structure/POSCAR-220-230-conv-03" : 220,
      "SpglibTestData/virtual_structure/POSCAR-220-230-prim-03" : 220,
      "SpglibTestData/virtual_structure/POSCAR-221-221-01" : 221,
      "SpglibTestData/virtual_structure/POSCAR-222-222-01" : 222,
      "SpglibTestData/virtual_structure/POSCAR-223-223-01" : 223,
      "SpglibTestData/virtual_structure/POSCAR-224-224-01" : 224,
      "SpglibTestData/virtual_structure/POSCAR-227-227-01" : 227,
      "SpglibTestData/virtual_structure/POSCAR-230-230-conv-01" : 230,
      //"SpglibTestData/virtual_structure/POSCAR-230-230-conv-62" : 230,
      "SpglibTestData/virtual_structure/POSCAR-230-230-prim-01" : 230
    ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, referenceSpaceGroupValue) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, allowOverlappingAtomTypes: false, symmetryPrecision: precision)
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            XCTAssertEqual(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber, referenceSpaceGroupValue, "Wrong space group found for \(fileName)")
          }
        }
      }
    }
  }
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testFindTrigonalSpaceGroupDebug()
  {
    let testData: [String: Int] =
    [
      "SpglibTestData/trigonal/POSCAR-166-2" : 166
    ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, referenceSpaceGroupValue) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          //let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.map{($0.fractionalPosition, $0.type)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, allowOverlappingAtomTypes: false, symmetryPrecision: precision)
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            XCTAssertEqual(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber, referenceSpaceGroupValue, "Wrong space group found for \(fileName)")
          }
        }
      }
    }
  }
}
