//
//  SpaceGroupZeolitesTest.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 07/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import SymmetryKit
import simd

class SpaceGroupZeolitesTest: XCTestCase
{
  // reference data is from Materials Studio
  func testZeolites()
  {
    let testData: [String: (spaceGroup: Int, a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)] =
      [
        "SpglibTestData/zeolites/AEL.cif" : (63, 33.29, 14.7036, 8.3863, 90, 90, 90),
        "SpglibTestData/zeolites/AEL-primitive.cif" : (63, 33.29, 14.7036, 8.3863, 90, 90, 90),
        "SpglibTestData/zeolites/AFI.cif" : (184, 13.74, 13.74, 8.474, 90, 90, 120),
        "SpglibTestData/zeolites/AFX.cif" : (163, 13.7571, 13.7571, 19.9362, 90, 90, 120),
        "SpglibTestData/zeolites/AlPO-17.cif" : (176, 13.2371, 13.2371, 14.7708, 90, 90, 120),
        "SpglibTestData/zeolites/ATS.cif" : (15, 13.1483, 21.5771, 5.1639, 90, 91.84, 90),
        "SpglibTestData/zeolites/ATS-primitive.cif" : (15, 13.1483, 21.5771, 5.1639, 90, 91.84, 90),
        "SpglibTestData/zeolites/BEA.cif" : (91, 12.661, 12.661, 26.406, 90, 90, 90),
        "SpglibTestData/zeolites/BOG.cif" : (74, 23.798, 20.236, 12.798, 90, 90, 90),
        "SpglibTestData/zeolites/BOG-primitive.cif" : (74, 20.236, 23.798, 12.798, 90, 90, 90),
        "SpglibTestData/zeolites/CFI.cif" : (74, 5.021, 13.695, 25.497, 90, 90, 90),
        "SpglibTestData/zeolites/CFI-primitive.cif" : (74, 5.021, 13.695, 25.497, 90, 90, 90),
        "SpglibTestData/zeolites/CHA.cif" : (166, 13.8436, 13.8436, 15.1762, 90, 90, 120),
        "SpglibTestData/zeolites/CHA-primitive.cif" : (166, 13.8436, 13.8436, 15.1762, 90, 90, 120),
        "SpglibTestData/zeolites/CON.cif" : (12, 22.6242, 13.3503, 12.3642, 90, 111.087, 90),
        "SpglibTestData/zeolites/CON-primitive.cif" : (12, 22.6242, 13.3503, 12.3642, 90, 111.087, 90),
        "SpglibTestData/zeolites/DDR.cif" : (166, 13.86, 13.86, 40.891, 90, 90, 120),
        "SpglibTestData/zeolites/DON.cif" : (7, 14.9701, 8.4761, 30.0278, 90, 102.65, 90),
        "SpglibTestData/zeolites/EMT.cif" : (194, 17.3864, 17.3864, 28.3459, 90, 90, 120),
        "SpglibTestData/zeolites/ERI.cif" : (194, 13.27, 13.27, 15.05, 90, 90, 120),
        "SpglibTestData/zeolites/FAU.cif" : (227, 24.2576, 24.2576, 24.2576, 90, 90, 90),
        "SpglibTestData/zeolites/FAU-primitive.cif" : (227, 24.2576, 24.2576, 24.2576, 90, 90, 90),
        "SpglibTestData/zeolites/FER.cif" : (58, 7.41971, 14.0702, 18.7202, 90, 90, 90),
        "SpglibTestData/zeolites/FER-primitive.cif" : (58, 7.41971, 14.0702, 18.7202, 90, 90, 90),
        "SpglibTestData/zeolites/ISV.cif" : (131, 12.8528, 12.8528, 25.2136, 90, 90, 90),
        "SpglibTestData/zeolites/ITQ-1.cif" : (191, 14.2081, 14.2081, 24.945, 90, 90, 120),
        "SpglibTestData/zeolites/ITQ-1-primitive.cif" : (191, 14.2081, 14.2081, 24.945, 90, 90, 120),
        "SpglibTestData/zeolites/ITQ-3.cif" : (63, 20.622, 9.7242, 19.623, 90, 90, 90),
        "SpglibTestData/zeolites/ITQ-3-primitive.cif" : (63, 20.622, 9.7242, 19.623, 90, 90, 90),
        "SpglibTestData/zeolites/ITQ-7.cif" : (131, 12.8528, 12.8528, 25.2136, 90, 90, 90),
        "SpglibTestData/zeolites/ITQ-8.cif" : (8, 10.4364, 15.0183, 8.8553, 90, 105.739, 90),
        "SpglibTestData/zeolites/ITQ-8-primitive.cif" : (8, 10.4364, 15.0183, 8.8553, 90, 105.739, 90),
        "SpglibTestData/zeolites/ITQ-29.cif" : (221, 11.8671, 11.8671, 11.8671, 90, 90, 90),
        "SpglibTestData/zeolites/KFI.cif" : (229, 18.671, 18.671, 18.671, 90, 90, 90),
        "SpglibTestData/zeolites/LAU.cif" : (12, 14.8538, 13.1695, 7.5421, 90, 110.323, 90),
        "SpglibTestData/zeolites/LAU-primitive.cif" : (12, 14.8538, 13.1695, 7.5421, 90, 110.323, 90),
        "SpglibTestData/zeolites/LEV.cif" : (166, 13.338, 13.338, 23.014, 90, 90, 120),
        "SpglibTestData/zeolites/LEV-primitive.cif" : (166, 13.338, 13.338, 23.014, 90, 90, 120),
        "SpglibTestData/zeolites/LTA.cif" : (226, 24.555, 24.555, 24.555, 90, 90, 90),
        "SpglibTestData/zeolites/LTA-primitive.cif" : (226, 24.555, 24.555, 24.555, 90, 90, 90),
        "SpglibTestData/zeolites/LTL.cif" : (191, 18.466, 18.466, 7.4763, 90, 90, 120),
        "SpglibTestData/zeolites/MAZ.cif" : (194, 18.392, 18.392, 7.646, 90, 90, 120),
        "SpglibTestData/zeolites/MEI.cif" : (176, 13.175, 13.175, 15.848, 90, 90, 120),
        "SpglibTestData/zeolites/MEL.cif" : (119, 20.067, 20.067, 13.411, 90, 90, 90),
        "SpglibTestData/zeolites/MEL-primitive.cif" : (119, 20.067, 20.067, 13.411, 90, 90, 90),
        "SpglibTestData/zeolites/MFI-para.cif" : (19, 13.438, 19.82, 20.121, 90, 90, 90),
        "SpglibTestData/zeolites/MFI-para-primitive.cif" : (19, 13.438, 19.82, 20.121, 90, 90, 90),
        "SpglibTestData/zeolites/MFI-mono.cif" : (14, 19.8790, 20.1070, 23.8262, 90, 145.870, 90),
        "SpglibTestData/zeolites/MFI-mono-primitive.cif" : (14, 19.8790, 20.1070, 23.8262, 90, 145.870, 90),
        "SpglibTestData/zeolites/MFI.cif" : (62, 20.022, 19.899, 13.383, 90, 90, 90),
        "SpglibTestData/zeolites/MFS.cif" : (44, 7.451, 14.1711, 18.767, 90, 90, 90),
        "SpglibTestData/zeolites/MFS-primitive.cif" : (44, 14.1711, 7.451, 18.767, 90, 90, 90),
        "SpglibTestData/zeolites/MOR.cif" : (63, 18.11, 20.53, 7.528, 90, 90, 90),
        "SpglibTestData/zeolites/MOR-primitive.cif" : (63, 18.11, 20.53, 7.528, 90, 90, 90),
        "SpglibTestData/zeolites/MTW.cif" : (15, 24.8633, 5.01238, 24.3275, 90, 107.722, 90),
        "SpglibTestData/zeolites/MTW-primitive.cif" : (15, 24.8633, 5.01238, 24.3275, 90, 107.722, 90),
        "SpglibTestData/zeolites/PAU.cif" : (229, 35.093, 35.093, 35.093, 90, 90, 90),
        "SpglibTestData/zeolites/PAU-primitive.cif" : (229, 35.093, 35.093, 35.093, 90, 90, 90),
        "SpglibTestData/zeolites/RHO.cif" : (229, 15.031, 15.031, 15.031, 90, 90, 90),
        "SpglibTestData/zeolites/RHO-primitive.cif" : (229, 15.031, 15.031, 15.031, 90, 90, 90),
        "SpglibTestData/zeolites/SAPO-47.cif" : (148, 13.7347, 13.7347, 15.0503, 90, 90, 120),
        "SpglibTestData/zeolites/SAPO-47-primitive.cif" : (148, 13.7347, 13.7347, 15.0503, 90, 90, 120),
        "SpglibTestData/zeolites/SAPO-56.cif" : (163, 13.7571, 13.7571, 19.9362, 90, 90, 120),
        "SpglibTestData/zeolites/SFF.cif" : (11, 7.3881, 21.9458, 11.4853, 90, 94.702, 90),
        "SpglibTestData/zeolites/SFF-primitive.cif" : (11, 7.3881, 21.9458, 11.4853, 90, 94.702, 90),
        "SpglibTestData/zeolites/SOD.cif" : (218, 8.848, 8.848, 8.848, 90, 90, 90),
        "SpglibTestData/zeolites/STF.cif" : (2, 7.3770, 11.4114, 11.5268, 104.892, 94.661, 96.206),
        "SpglibTestData/zeolites/STF-primitive.cif" : (2, 7.3770, 11.4114, 11.5268, 104.892, 94.661, 96.206),
        "SpglibTestData/zeolites/TON.cif" : (36, 13.8590, 17.4200, 5.0380, 90, 90, 90),
        "SpglibTestData/zeolites/TON-primitive.cif" : (36, 13.8590, 17.4200, 5.0380, 90, 90, 90),
        "SpglibTestData/zeolites/VFI.cif" : (173, 18.9752, 18.9752, 8.1044, 90, 90, 120),
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
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: atoms, allowPartialOccupancies: true, symmetryPrecision: 1e-2)
          
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
