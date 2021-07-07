//
//  SpaceGroupChangeOfBasistests.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 06/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import SymmetryKit

class SpaceGroupChangeOfBasistests: XCTestCase
{
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testFindOrthorhombicSpaceGroup2()
  {
    let testData: [String: Int] =
    [
      "SpglibTestData/orthorhombic/POSCAR-065-3" : 65
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
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, symmetryPrecision: 1e-5)
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            XCTAssertEqual(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber, referenceSpaceGroupValue, "Wrong space group found for \(fileName)")
            //print(spacegroup.changeOfBasis)
          }
        }
      }
    }
  }
  
}
