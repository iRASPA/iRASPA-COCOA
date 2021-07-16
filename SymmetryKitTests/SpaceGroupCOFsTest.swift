//
//  SpaceGroupCOFsTest.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 07/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import SymmetryKit
import simd

class SpaceGroupCOFsTest: XCTestCase
{
  // reference data is from Materials Studio
  func testCOFs()
  {
    let testData: [String: (spaceGroup: Int, a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)] =
      [
        "SpglibTestData/mofs/COF-1.cif" : (194, 15.6529, 15.6529, 6.7005, 90, 90, 120),
        "SpglibTestData/mofs/COF-5.cif" : (191, 30.0198, 30.0198, 3.404, 90, 90, 120),
        "SpglibTestData/mofs/COF-102.cif" : (220, 27.1771, 27.1771, 27.1771, 90, 90, 90),
        "SpglibTestData/mofs/COF-102-primitive.cif" : (220, 27.1771, 27.1771, 27.1771, 90, 90, 90),
        "SpglibTestData/mofs/COF-103.cif" : (220, 28.2477, 28.2477, 28.2477, 90, 90, 90),
        "SpglibTestData/mofs/COF-103-primitive.cif" : (220, 28.2477, 28.2477, 28.2477, 90, 90, 90),
        "SpglibTestData/mofs/COF-105.cif" : (220, 44.886, 44.886, 44.886, 90, 90, 90),
        "SpglibTestData/mofs/COF-105-primitive.cif" : (220, 44.886, 44.886, 44.886, 90, 90, 90),
        "SpglibTestData/mofs/COF-108.cif" : (215, 28.401, 28.401, 28.401, 90, 90, 90),
        "SpglibTestData/mofs/COF-202.cif" : (220, 30.1051, 30.1051, 30.1051, 90, 90, 90),
        "SpglibTestData/mofs/COF-202-primitive.cif" : (220, 30.1051, 30.1051, 30.1051, 90, 90, 90),
        "SpglibTestData/mofs/COF-300.cif" : (88, 28.127, 28.127, 8.879, 90, 90, 90),
        "SpglibTestData/mofs/COF-300-primitive.cif" : (88, 28.127, 28.127, 8.879, 90, 90, 90)
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
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: atoms, symmetryPrecision: 1e-3)
          
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
