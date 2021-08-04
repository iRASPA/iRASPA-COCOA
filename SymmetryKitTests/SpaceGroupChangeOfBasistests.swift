//
//  SpaceGroupChangeOfBasistests.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 06/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import SymmetryKit
import simd

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
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type, 1.0)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, allowPartialOccupancies: true, symmetryPrecision: 1e-5)
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            print("changeOfBasis ", double3x3(rotationMatrix: spacegroup.changeOfBasis.inverseRotationMatrix).inverse)
            print("changeOfBais ", spacegroup.transformationMatrix)
            XCTAssertEqual(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber, referenceSpaceGroupValue, "Wrong space group found for \(fileName)")
            //print(spacegroup.changeOfBasis)
          }
        }
      }
    }
  }
  
}
