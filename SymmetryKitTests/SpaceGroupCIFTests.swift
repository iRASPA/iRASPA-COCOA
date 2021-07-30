//
//  SpaceGroupCIFTests.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 16/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import SymmetryKit
import simd

class SpaceGroupStructureTests: XCTestCase
{
  let precision: Double = 1e-3
  
  func testStructures()
  {
    let testData: [String] =
      [
        "CIF_Files/Structures/CuCL-IV-205.cif"
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName) in testData
    {
      
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let contentString = try! String(contentsOf: url, encoding: String.Encoding.utf8)
        let parser: SKCIFParser = SKCIFParser(displayName: String(describing: url), string: contentString, windowController: nil)
        try! parser.startParsing()
        
        if let frame: SKStructure = parser.scene.first?.first,
           let referenceUnitCell = frame.cell?.unitCell,
           let referenceSpaceGroupHallNumber = frame.spaceGroupHallNumber
        {
          let referenceSpaceGroupNumber = SKSpacegroup.spaceGroupData[referenceSpaceGroupHallNumber].spaceGroupNumber
          let atoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = frame.atoms.map{($0.position, $0.elementIdentifier)}
          let expandedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = SKSpacegroup(HallNumber: referenceSpaceGroupHallNumber).expand(atoms: atoms, unitCell: referenceUnitCell, symmetryPrecision: precision)
          let symmetryRemovedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = SKSpacegroup.init(HallNumber: referenceSpaceGroupHallNumber).duplicatesRemoved(unitCell: referenceUnitCell, atoms2: expandedAtoms)
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: referenceUnitCell, atoms: symmetryRemovedAtoms, allowPartialOccupancies: false, symmetryPrecision: precision)
          
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            print("spacegroup: ", SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber)
            XCTAssertEqual(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber, referenceSpaceGroupNumber, "Wrong space group found for \(fileName)")
          }
        }
      }
    }
  }
}
