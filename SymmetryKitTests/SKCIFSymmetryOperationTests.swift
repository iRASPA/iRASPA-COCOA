//
//  SKCIFSymmetryOperationTests.swift
//  SymmetryKitTests
//

import XCTest
@testable import SymmetryKit

class SKCIFSymmetryOperationTests: XCTestCase
{
  func testParseIdentityOperation()
  {
    let operation = try! SKCIFSymmetryOperationParser.parse("x,y,z")
    XCTAssertEqual(operation.rotation, SKRotationMatrix.identity)
    XCTAssertEqual(operation.translation, SIMD3<Int32>(0, 0, 0))
  }
  
  func testParseBodyCenteredOperation()
  {
    let operation = try! SKCIFSymmetryOperationParser.parse("-x+1/2,-y+1/2,z+1/2")
    XCTAssertEqual(operation.rotation, SKRotationMatrix.inversionIdentity)
    XCTAssertEqual(operation.translation, SIMD3<Int32>(12, 12, 12))
  }
  
  func testCAU10SymCIFIdentifiesHall426()
  {
    let symPath = NSHomeDirectory() + "/CAU-10-H_DDEC6_RASPA_sym.cif"
    guard FileManager.default.fileExists(atPath: symPath) else
    {
      throw XCTSkip("CAU-10 reference CIF not found in home directory")
    }
    
    let data = try! Data(contentsOf: URL(fileURLWithPath: symPath))
    let parser = try! SKCIFParser(displayName: "CAU-10", data: data)
    try! parser.startParsing()
    
    XCTAssertEqual(parser.cifSymmetryOperations.count, 32)
    XCTAssertEqual(parser.spaceGroup.spaceGroupSetting.number, 426)
    XCTAssertNotNil(parser.spaceGroup.cifSymmetryOperations)
    XCTAssertEqual(parser.spaceGroupFound, .CIFSymmetryOperationsFound)
  }
  
  func testCAU10HMSymbolAloneWouldPickWrongHallWithoutSymops()
  {
    let candidates = SKSpacegroup.candidateHallNumbers(spaceGroupITNumber: 141, declaredHallNumber: nil, declaredHMSymbol: "I 41/a m d")
    XCTAssertEqual(candidates, [427, 426])
    
    let hallFromOps = SKSpacegroup.identifyHallNumber(
      fromCIFSymmetryOperations: SKSpacegroup(HallNumber: 426).spaceGroupSetting.fullSeitzMatrices.operations,
      candidateHallNumbers: candidates
    )
    XCTAssertEqual(hallFromOps, 426)
  }
  
  func testSeitzMatricesFromEmptyGeneratorEncoding()
  {
    let matrices = SKSeitzIntegerMatrix.SeitzMatrices(generatorEncoding: [])
    XCTAssertEqual(matrices.count, 3)
    XCTAssertEqual(matrices[0].rotation, SKRotationMatrix.identity)
    XCTAssertEqual(matrices[1].rotation, SKRotationMatrix.identity)
    XCTAssertEqual(matrices[2].rotation, SKRotationMatrix.identity)
  }
  
  func testGetOriginShiftForP1DoesNotCrash()
  {
    let identity = SKSeitzMatrix(rotation: SKRotationMatrix.identity, translation: SIMD3<Double>(0, 0, 0))
    let origin = try? SKSpacegroup.getOriginShift(
      HallNumber: 1,
      centering: .primitive,
      changeOfBasis: SKRotationalChangeOfBasis(rotation: SKRotationMatrix.identity),
      seitzMatrices: [identity]
    )
    XCTAssertEqual(origin, SIMD3<Double>(0, 0, 0))
  }
}
