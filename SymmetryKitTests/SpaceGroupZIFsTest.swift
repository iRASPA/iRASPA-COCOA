//
//  SpaceGroupZIFsTest.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 07/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import SymmetryKit

class SpaceGroupZIFsTest: XCTestCase
{
  
  // reference data is from Materials Studio
  func testZIFs()
  {
    let testData: [String: (spaceGroup: Int, a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)] =
      [
        "SpglibTestData/zifs/ZIF-1.cif" : (14, 14.936, 15.266, 16.5635, 90, 144.449, 90),
        "SpglibTestData/zifs/ZIF-1-primitive.cif" : (14, 14.936, 15.266, 16.5635, 90, 144.449, 90),         // MS: beta=129.0487, a=9.7405, b=15.266, c=19.015
        "SpglibTestData/zifs/ZIF-2.cif" : (61, 9.6790, 24.1140, 24.4500, 90, 90, 90),
        "SpglibTestData/zifs/ZIF-3.cif" : (136, 18.9701, 18.9701, 16.74, 90, 90, 90),
        "SpglibTestData/zifs/ZIF-4.cif" : (14, 23.9548, 15.395, 15.3073, 90, 129.718, 90),                    // MS: a=18.426, b=15.395, c=15.3073, angles=90
        "SpglibTestData/zifs/ZIF-4-primitive.cif" : (14, 23.9548, 15.395, 15.3073, 90, 129.718, 90),
        "SpglibTestData/zifs/ZIF-5.cif" : (230, 21.9619, 21.9619, 21.9619, 90, 90, 90),
        "SpglibTestData/zifs/ZIF-5-primitive.cif" : (230, 21.9619, 21.9619, 21.9619, 90, 90, 90),
        "SpglibTestData/zifs/ZIF-7.cif" : (148, 22.989, 22.989, 15.763, 90, 90, 120),
        "SpglibTestData/zifs/ZIF-7-primitive.cif" : (148, 22.989, 22.989, 15.763, 90, 90, 120),
        "SpglibTestData/zifs/ZIF-9.cif" : (148, 22.9437, 22.9437, 15.747, 90, 90, 120),
        "SpglibTestData/zifs/ZIF-9-primitive.cif" : (148, 22.9437, 22.9437, 15.747, 90, 90, 120),
        "SpglibTestData/zifs/ZIF-20.cif" : (16, 45.4725, 45.4725, 45.4725, 90, 90, 90),
        "SpglibTestData/zifs/ZIF-68-primitive.cif" : (194, 26.6407, 26.6407, 18.4882, 90, 90, 120),
        "SpglibTestData/zifs/ZIF-68.cif" : (194, 26.6407, 26.6407, 18.4882, 90, 90, 120),
        "SpglibTestData/zifs/ZIF-69.cif" : (147, 26.084, 26.084, 19.4082, 90, 90, 120),
        "SpglibTestData/zifs/ZIF-71.cif" : (221, 28.5539, 28.5539, 28.5539, 90, 90, 90),
        "SpglibTestData/zifs/ZIF-77-primitive.cif" : (72, 11.1248, 22.3469, 24.9087, 90, 90, 90),
        "SpglibTestData/zifs/ZIF-77.cif" : (72, 11.1248, 22.3469, 24.9087, 90, 90, 90),
        "SpglibTestData/zifs/ZIF-80.cif" : (194, 26.307, 26.307, 19.361, 90, 90, 120),
        "SpglibTestData/zifs/ZIF-93.cif" : (211, 28.3565, 28.3565, 28.3565, 90, 90, 90),
        "SpglibTestData/zifs/ZIF-93-primitive.cif" : (211, 28.3565, 28.3565, 28.3565, 90, 90, 90),
        "SpglibTestData/zifs/ZIF-96.cif" : (211, 28.3564, 28.3564, 28.3564, 90, 90, 90),
        "SpglibTestData/zifs/ZIF-96-primitive.cif" : (211, 28.3564, 28.3564, 28.3564, 90, 90, 90),
        "SpglibTestData/zifs/ZIF-97.cif" : (211, 28.4319, 28.4319, 28.4319, 90, 90, 90),
        "SpglibTestData/zifs/ZIF-97-primitive.cif" : (211, 28.4319, 28.4319, 28.4319, 90, 90, 90),
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
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: atoms, symmetryPrecision: 1e-2)
          
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
