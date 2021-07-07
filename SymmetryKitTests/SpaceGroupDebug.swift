//
//  SpaceGroupDebug.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 06/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import SymmetryKit

class SpaceGroupDebug: XCTestCase
{

  func testMOF()
  {
    let testData: [String: (spaceGroup: Int, a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)] =
      [
        "SpglibTestData/mofs/MIL-100.cif" : (1, 72.9057, 72.9057, 72.9057, 90, 90, 90)
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, reference) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let contentString = try! String(contentsOf: url, encoding: String.Encoding.utf8)
        let parser: SKCIFParser = SKCIFParser(displayName: String(describing: url), string: contentString, windowController: nil)
        try! parser.startParsing()
        
        if let frame: SKStructure = parser.scene.first?.first,
           let unitCell = frame.cell?.unitCell
        {
          let atoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = frame.atoms.map{($0.position, $0.elementIdentifier)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: atoms, symmetryPrecision: 1e-5)
          
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            XCTAssertEqual(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber, reference.spaceGroup, "Wrong space group found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.a, reference.a, accuracy: 1e-4, "Wrong a found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.b, reference.b, accuracy: 1e-4, "Wrong b found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.c, reference.c, accuracy: 1e-4, "Wrong c found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.alpha * 180.0 / Double.pi, reference.alpha, accuracy: 1e-3, "Wrong alpha-angle found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.beta * 180.0 / Double.pi, reference.beta, accuracy: 1e-3, "Wrong beta-angle found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.gamma * 180.0 / Double.pi, reference.gamma, accuracy: 1e-3, "Wrong gamma-angle found for \(fileName)")
          }
        }
      }
    }
  }
  
  // reference data is from Materials Studio
  func testMOFs()
  {
    let testData: [String: (spaceGroup: Int, a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)] =
      [
        //"SpglibTestData/mofs/IRMOF-1.cif" : (225, 25.832, 25.832, 25.832, 90, 90, 90)
        //"SpglibTestData/zifs/ZIF-68.cif" : (194, 26.6407, 26.6407, 18.4882, 90, 90, 120)
        "SpglibTestData/zeolites/ERI.cif" : (194, 13.27, 13.27, 15.05, 90, 90, 120),
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, reference) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let contentString = try! String(contentsOf: url, encoding: String.Encoding.utf8)
        let parser: SKCIFParser = SKCIFParser(displayName: String(describing: url), string: contentString, windowController: nil)
        try! parser.startParsing()
        
        if let frame: SKStructure = parser.scene.first?.first,
           let unitCell = frame.cell?.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let atoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = frame.atoms.map{($0.position + origin, $0.elementIdentifier)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: atoms, symmetryPrecision: 1e-3)
          
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            XCTAssertEqual(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber, reference.spaceGroup, "Wrong space group found for \(fileName)")
          }
        }
      }
    }
  }
}
