//
//  SpaceGroupUnitCellTests.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 03/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import SymmetryKit

class SpaceGroupUnitCellTests: XCTestCase
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
        "SpglibTestData/zeolites/BOG.cif" : (74, 20.236, 23.798, 12.798, 90, 90, 90),
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
          let atoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = frame.atoms.map{($0.position, $0.elementIdentifier)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: atoms, symmetryPrecision: 1e-3)
          
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
          let atoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = frame.atoms.map{($0.position, $0.elementIdentifier)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: atoms, symmetryPrecision: 1e-4)
          
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            XCTAssertEqual(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber, reference.spaceGroup, "Wrong space group found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.a, reference.a, accuracy: 1e-5, "Wrong a found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.b, reference.b, accuracy: 1e-5, "Wrong b found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.c, reference.c, accuracy: 1e-5, "Wrong c found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.alpha * 180.0 / Double.pi, reference.alpha, accuracy: 1e-5, "Wrong alpha-angle found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.beta * 180.0 / Double.pi, reference.beta, accuracy: 1e-5, "Wrong beta-angle found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.gamma * 180.0 / Double.pi, reference.gamma, accuracy: 1e-5, "Wrong gamma-angle found for \(fileName)")
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
        "SpglibTestData/mofs/MIL-100.cif" : (1, 72.9057, 72.9057, 72.9057, 90, 90, 90),
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
          let atoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = frame.atoms.map{($0.position, $0.elementIdentifier)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: atoms, symmetryPrecision: 1e-4)
          
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
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: 0.0..<1.0), Double.random(in: 0.0..<1.0), Double.random(in: 0.0..<1.0))
          let atoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = frame.atoms.map{($0.position + origin, $0.elementIdentifier)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: atoms, symmetryPrecision: 1e-3)
          
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
}
