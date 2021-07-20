//
//  SpaceGroupMOFsTest.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 07/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import SymmetryKit
import simd

class SpaceGroupMOFsTest: XCTestCase
{

  // reference data is from Materials Studio
  func testMOFs()
  {
    let testData: [String: (spaceGroup: Int, a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)] =
      [
        "SpglibTestData/mofs/Cu-BTC.cif" : (225, 26.343, 26.343, 26.343, 90, 90, 90),
        "SpglibTestData/mofs/Cu-BTC-primitive.cif" : (225, 26.343, 26.343, 26.343, 90, 90, 90),
        "SpglibTestData/mofs/IRMOF-1.cif" : (225, 25.832, 25.832, 25.832, 90, 90, 90),
        "SpglibTestData/mofs/IRMOF-1-primitive.cif" : (225, 25.832, 25.832, 25.832, 90, 90, 90),
        "SpglibTestData/mofs/MAF-X8.cif" : (73, 13.9249, 23.653, 23.637, 90, 90, 90),                  // MS: 13.9249, 23.653, 23.637
        "SpglibTestData/mofs/MAF-X8-primitive.cif" : (73, 13.9249, 23.637, 23.653, 90, 90, 90),        // MS: 23.637,  23.653, 13.9249
        "SpglibTestData/mofs/MgMOF-74.cif" : (148, 26.136, 26.136, 6.942, 90, 90, 120),
        "SpglibTestData/mofs/MgMOF-74-primitive.cif" : (148, 26.136, 26.136, 6.942, 90, 90, 120),
        "SpglibTestData/mofs/MIL-47.cif" : (62, 6.8179, 16.143, 13.939, 90, 90, 90),
        "SpglibTestData/mofs/MIL-53(Cr)ht.cif" : (74, 16.733, 6.812, 13.038, 90, 90, 90),
        "SpglibTestData/mofs/MIL-53(Cr)ht-primitive.cif" : (74, 6.812, 16.733, 13.038, 90, 90, 90),
        "SpglibTestData/mofs/MIL-53(Cr)lt.cif" : (15, 19.685, 7.849, 6.782, 90, 104.9, 90),              // MS: beta=75.10
        "SpglibTestData/mofs/MIL-53(Cr)lt-primitive.cif" : (15, 19.685, 7.849, 6.782, 90, 104.9, 90),    // MS: beta=75.10
        "SpglibTestData/mofs/PCN-68.cif" : (225, 59.153, 59.153, 59.153, 90, 90, 90),
        "SpglibTestData/mofs/PCN-68-primitive.cif" : (225, 59.153, 59.153, 59.153, 90, 90, 90),
        "SpglibTestData/mofs/PCN-61.cif" : (225, 42.7958, 42.7958, 42.7958, 90, 90, 90),
        "SpglibTestData/mofs/PCN-61-primitive.cif" : (225, 42.7958, 42.7958, 42.7958, 90, 90, 90),
        "SpglibTestData/mofs/PCN-60.cif" : (225, 42.8434, 42.8434, 42.8434, 90, 90, 90),
        "SpglibTestData/mofs/PCN-60-primitive.cif" : (225, 42.8434, 42.8434, 42.8434, 90, 90, 90),
        "SpglibTestData/mofs/MIL-100.cif" : (1, 51.5521, 51.5521, 51.5521, 120, 120, 90),
        "SpglibTestData/mofs/MIL-100-primitive.cif" : (1, 51.5521, 51.5521, 51.5521, 90, 120, 120),
        "SpglibTestData/mofs/MOF-70.cif" : (14, 9.9617, 17.9914, 11.5149, 90, 134.877, 90),
        "SpglibTestData/mofs/MOF-70-primitive.cif" : (14, 9.9617, 17.9914, 11.5149, 90, 134.877, 90),      // MS: beta=137.354, c=14.3453 (wrong)
        "SpglibTestData/mofs/MOF-72.cif" : (15, 13.686, 18.252, 14.906, 90, 101.07, 90),
        "SpglibTestData/mofs/MOF-72-primitive.cif" : (15, 13.686, 18.252, 14.906, 90, 101.07, 90),           // MS: beta=126.4982, c=18.1977 (wrong)
        "SpglibTestData/mofs/MOF-177.cif" : (143, 37.072, 37.072, 30.0333, 90, 90, 120),
        "SpglibTestData/mofs/MOF-200.cif" : (159, 52.022, 52.022, 42.316, 90, 90, 120),
        "SpglibTestData/mofs/MOF-205.cif" : (2, 30.353, 30.353, 30.353, 90, 90, 90),
        "SpglibTestData/mofs/MOF-210.cif" : (148, 50.745, 50.745, 194.256, 90, 90, 120),
        "SpglibTestData/mofs/MOF-210-primitive.cif" : (148, 50.745, 50.745, 194.256, 90, 90, 120),
        "SpglibTestData/mofs/CAN-12.cif" : (91, 20.3049, 20.3049, 49.641, 90, 90, 90),
        "SpglibTestData/mofs/Co(2,6-NDP).cif" : (78, 15.4754, 15.4754, 13.5298, 90, 90, 90),
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
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: atoms, allowOverlappingAtomTypes: true, symmetryPrecision: 1e-3)
          
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
