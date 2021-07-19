//
//  PrimitiveUnitCellSearchTests.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 10/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import SymmetryKit
import simd

class PrimitiveUnitCellSearchTests: XCTestCase
{
  let precision: Double = 1e-5
  
  
  func testFindTriclinicPrimitive()
  {
    let testData: [String: double3x3] =
    [
      "SpglibTestData/data/triclinic/POSCAR-001" : double3x3([4.9159976868, 0.0000000000, 0.0000000000],[2.4574988436, 4.2582449067, 0.0000000000], [0.0000000000, 0.0000000000, 5.4069974558]),
      "SpglibTestData/data/triclinic/POSCAR-002" : double3x3([-5.5089974078, -0.0000000000, -0.0000000000],[1.7074361851, -2.5382443466, -6.0543179877], [2.3104709548, -6.6161727417, -0.0000000000])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          var histogram:[Int:Int] = [:]
                    
          for atom in reader.atoms
          {
            histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
          }
          
          // Find least occurent element
          let minType: Int = histogram.min{a, b in a.value < b.value}!.key
          
          //let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.filter{$0.type == minType}
          let reducedAtoms = reader.atoms
          
          //print(reader.unitCell)
          // search for a primitive cell based on the positions of the atoms
          let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: reader.atoms, unitCell: unitCell, symmetryPrecision: precision)
         
          let DelaunayUnitCell: double3x3? = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: precision)
          
          XCTAssertNotNil(DelaunayUnitCell, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = DelaunayUnitCell
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
  
  
  func testFindMonoclinicPrimitive()
  {
    let testData: [String: double3x3] =
    [
      "SpglibTestData/monoclinic/POSCAR-003" : double3x3([-0.0000000000, -4.1293980569, -0.0000000000],[-4.1604980423, -0.0000000000, -0.0000000000], [1.4636598779, -0.0000000000, -7.2753263256]),
      "SpglibTestData/monoclinic/POSCAR-004" : double3x3([0.0192362784, -5.0120607273, 0.0000000000],[4.3671298014, 2.5060303637, 0.0000000000], [0.0000000000, 0.0000000000, 8.2140961349]),
      "SpglibTestData/monoclinic/POSCAR-004-2" : double3x3([0.0000000000, 7.3439965443, 0.0000000000],[-4.3146051629, 0.0000000000, 10.9420608705], [11.8809944095, 0.0000000000, 0.0000000000]),
      "SpglibTestData/monoclinic/POSCAR-005" : double3x3([0.0000000000, -3.8299981978, 0.0000000000],[6.2599970544, 1.9149990989, 0.0000000000], [-2.0057067389, 0.0000000000, 6.3612890682]),
      "SpglibTestData/monoclinic/POSCAR-005-2" : double3x3([-2.4344899442, 0.0000000000, 7.7684668591],[-6.4309969739, -5.6024973638, -0.0000000000], [6.4309969739, -5.6024973638, 0.0000000000]),
      "SpglibTestData/monoclinic/POSCAR-006" : double3x3([-0.2213964213, 6.9674800963, 0.0000000000],[0.0000000000, 0.0000000000, 9.6699954499], [10.9429948509, 0.0000000000, 0.0000000000]),
      "SpglibTestData/monoclinic/POSCAR-006-2" : double3x3([0.0000000000, 3.2087984901, 0.0000000000],[-2.1919524756, 0.0000000000, 6.1584385798], [9.3991955773, 0.0000000000, 0.0000000000]),
      "SpglibTestData/monoclinic/POSCAR-007" : double3x3([-3.4242907681, -0.0000000000, -5.8698437366],[3.4507059969, -0.0000000000, -5.8698437366], [-0.0000000000, -22.5499893893, -0.0000000000]),
      "SpglibTestData/monoclinic/POSCAR-007-2" : double3x3([0.0000000000, 5.4049974567, 0.0000000000],[-2.0448445974, 0.0000000000, 12.9252406329], [16.4529922582, 0.0000000000, 0.0000000000]),
      "SpglibTestData/monoclinic/POSCAR-008" : double3x3([8.3249960827, 0.0000000000, 7.0409966869],[-8.3249960827, -0.0000000000, 7.0409966869], [2.3753536987, -10.6441730009, -0.0000000000]),
      "SpglibTestData/monoclinic/POSCAR-008-2" : double3x3([-7.0439966855, -4.0688980854, -0.0000000000],[7.0439966855, -4.0688980854, 0.0000000000], [-2.2889694552, 4.0688980854, 26.6955687405]),
      "SpglibTestData/monoclinic/POSCAR-009" : double3x3([0.0000000000, -5.6320973499, 0.0000000000],[8.1389961703, 2.8160486749, 0.0000000000], [-1.2035882678, 2.8160486749, 9.3759078039]),
      "SpglibTestData/monoclinic/POSCAR-009-2" : double3x3([1.3424000453, -0.0000000000, 9.1237692915],[-10.4229950955, -0.0000000000, -0.0000000000], [4.5402975251, -9.3434956035, -4.5618846457]),
      "SpglibTestData/monoclinic/POSCAR-010" : double3x3([-0.0000000000, -3.7769982228, -0.0000000000],[-12.3929941686, -0.0000000000, -0.0000000000], [5.9123807571, -0.0000000000, -14.2035825069]),
      "SpglibTestData/monoclinic/POSCAR-010-2" : double3x3([-0.0000000000, -3.7769982228, -0.0000000000],[-12.3929941686, -0.0000000000, -0.0000000000], [5.9123807571, -0.0000000000, -14.2035825069]),
      "SpglibTestData/monoclinic/POSCAR-011" : double3x3([0.0000000000, 4.1669980393, 0.0000000000],[-4.7272549382, 0.0000000000, 10.0459281057], [11.4066946327, 0.0000000000, 0.0000000000]),
      "SpglibTestData/monoclinic/POSCAR-011-2" : double3x3([-0.2256254105, 0.0000000000, 4.8747790476],[7.0129967001, 0.0000000000, 0.0000000000], [0.0000000000, 9.5389955115, 0.0000000000]),
      "SpglibTestData/monoclinic/POSCAR-012" : double3x3([2.5087734371, -4.3370210905, -0.0001864450],[2.5087734371, 4.3370210905, -0.0001864450], [-1.7018015993, 0.0000000000, 4.8033156256]),
      "SpglibTestData/monoclinic/POSCAR-012-2" : double3x3([-2.5086743348, -4.3368272641, 0.0000428228],[-2.5086743348, 4.3368272641, 0.0000428228], [1.7014607644, -0.0000000000, -4.8030263272]),
      "SpglibTestData/monoclinic/POSCAR-012-3" : double3x3([-6.6449968732, -4.2114980183, -0.0000000000],[-6.6449968732, 4.2114980183, -0.0000000000], [2.0520515829, -0.0000000000, -10.2230773735]),
      "SpglibTestData/monoclinic/POSCAR-013" : double3x3([-4.8589977136, -0.0000000000, -0.0000000000],[0.5498746160, -0.0000000000, -5.8170658220], [-0.0000000000, -6.7559968210, -0.0000000000]),
      "SpglibTestData/monoclinic/POSCAR-013-2" : double3x3([-0.0000000000, -7.6279964107, -0.0000000000],[-11.5259945765, -0.0000000000, -0.0000000000], [4.3627821524, -0.0000000000, -11.2946738742]),
      "SpglibTestData/monoclinic/POSCAR-013-3" : double3x3([0.0000000000, 6.5669969100, 0.0000000000],[-0.5056791541, 0.0000000000, 7.9930162785], [9.7019954348, 0.0000000000, 0.0000000000]),
      "SpglibTestData/monoclinic/POSCAR-014" : double3x3([-5.0699976144, -0.0000000000, -0.0000000000],[-2.2121897783, -0.0000000000, -5.7823347551], [-0.0000000000, -13.8299934924, -0.0000000000]),
      "SpglibTestData/monoclinic/POSCAR-014-2" : double3x3([0.3494222389, -0.0000000000, -7.1444569386],[-0.0000000000, -9.9939952974, -0.0000000000], [-11.1929947332, -0.0000000000, -0.0000000000]),
      "SpglibTestData/monoclinic/POSCAR-015" : double3x3([-5.1896717218, -0.0000000000, 0.0189686342],[-2.5948358609, 4.5638432340, 0.0094843171], [0.2840727811, -0.0000000000, -10.3538966582]),
      "SpglibTestData/monoclinic/POSCAR-015-2" : double3x3([5.1896717218, 0.0000000000, -0.0189686342],[2.5948358609, 4.5638432340, -0.0094843171], [-0.2840727811, 0.0000000000, 10.3538966582]),
      "SpglibTestData/monoclinic/POSCAR-015-3" : double3x3([0.0925408600, -0.0000000000, -5.0491496501],[-4.7064977854, -5.7609972892, -0.0000000000], [-4.7064977854, 5.7609972892, -0.0000000000])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          var histogram:[Int:Int] = [:]
                    
          for atom in reader.atoms
          {
            histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
          }
          
          // Find least occurent element
          let minType: Int = histogram.min{a, b in a.value < b.value}!.key
          
          //let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.filter{$0.type == minType}
          let reducedAtoms = reader.atoms
          
          // search for a primitive cell based on the positions of the atoms
          let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: reader.atoms, unitCell: unitCell, symmetryPrecision: precision)
         
          let DelaunayUnitCell: double3x3? = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: precision)
          
          XCTAssertNotNil(DelaunayUnitCell, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = DelaunayUnitCell
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
  
  func testFindOrthorhombicPrimitive()
  {
    let testData: [String: double3x3] =
    [
      "SpglibTestData/orthorhombic/POSCAR-016" : double3x3([10.7049949629, 0.0000000000, 0.0000000000],[0.0000000000, 10.7339949492, 0.0000000000], [0.0000000000, 0.0000000000, 31.6299851168]),
      "SpglibTestData/orthorhombic/POSCAR-016-2" : double3x3([5.6099973603, 0.0000000000, 0.0000000000],[0.0000000000, 5.6699973320, 0.0000000000], [0.0000000000, 0.0000000000, 9.0499957416]),
      "SpglibTestData/orthorhombic/POSCAR-017-2" : double3x3([0.0000000000, 0.0000000000, 4.3299979626],[7.0499966827, 0.0000000000, 0.0000000000], [0.0000000000, 7.8499963062, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-018" : double3x3([-0.0000000000, -0.0000000000, -5.0639976172],[-0.0000000000, -8.3339960785, -0.0000000000], [-13.9949934148, -0.0000000000, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-018-2" : double3x3([7.3489965420, 0.0000000000, 0.0000000000],[0.0000000000, 7.5149964639, 0.0000000000], [0.0000000000, 0.0000000000, 7.8939962855]),
      "SpglibTestData/orthorhombic/POSCAR-019" : double3x3([3.5183598275, 0.0000000000, 0.0000000000],[0.0000000000, 3.6304070169, 0.0000000000], [0.0000000000, 0.0000000000, 4.3802740222]),
      "SpglibTestData/orthorhombic/POSCAR-019-2" : double3x3([4.8089977372, 0.0000000000, 0.0000000000],[0.0000000000, 6.9569967264, 0.0000000000], [0.0000000000, 0.0000000000, 8.4659960164]),
      "SpglibTestData/orthorhombic/POSCAR-020" : double3x3([-4.3699979437, -2.5249988119, -0.0000000000],[-4.3699979437, 2.5249988119, -0.0000000000], [-0.0000000000, -0.0000000000, -8.2399961227]),
      "SpglibTestData/orthorhombic/POSCAR-021" : double3x3([-0.0000000000, -0.0000000000, -3.7999982119],[-3.1929984976, -5.2149975461, -0.0000000000], [-3.1929984976, 5.2149975461, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-021-2" : double3x3([-6.5079969377, -0.0000000000, -0.0000000000],[-0.0000000000, -0.0000000000, -6.5179969330], [-3.2539984689, -7.5819964324, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-022" : double3x3([-0.0000000000, -0.0000000000, 5.8307972564],[0.0000000000, -6.4444969676, -2.9153986282], [6.6689968620, -0.0000000000, 2.9153986282]),
      "SpglibTestData/orthorhombic/POSCAR-023" : double3x3([5.0869976064, 5.0874976061, 5.0869976064],[5.0869976064, -5.0874976061, -5.0869976064], [-5.0869976064, 5.0874976061, -5.0869976064]),
      "SpglibTestData/orthorhombic/POSCAR-023-2" : double3x3([-0.0000000000, -0.0000000000, -6.0439971560],[-8.3459960729, -0.0000000000, -0.0000000000], [4.1729980364, 8.8229958484, 3.0219985780]),
      "SpglibTestData/orthorhombic/POSCAR-024" : double3x3([-7.0509966822, -0.0000000000, -0.0000000000],[-3.5254983411, -4.9839976548, -3.6424982861], [3.5254983411, -4.9839976548, 3.6424982861]),
      "SpglibTestData/orthorhombic/POSCAR-024-2" : double3x3([0.0000000000, 0.0000000000, -12.8849939371],[7.9359962658, 7.9609962540, 6.4424969685], [7.9359962658, -7.9609962540, -6.4424969685]),
      "SpglibTestData/orthorhombic/POSCAR-025" : double3x3([-2.9189986265, -0.0000000000, -0.0000000000],[-0.0000000000, -0.0000000000, -3.0659985573], [-0.0000000000, -5.6179973565, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-025-2" : double3x3([0.0000000000, 5.7675972861, 0.0000000000],[0.0000000000, 0.0000000000, 5.8488972478], [8.2032961400, 0.0000000000, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-026" : double3x3([0.0000000000, 0.0000000000, 4.0099981131],[11.1499947535, 0.0000000000, 0.0000000000], [0.0000000000, 11.5099945841, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-026-2" : double3x3([-0.0000000000, -0.0000000000, -7.4452964967],[-0.0000000000, -8.1759961529, -0.0000000000], [-8.6489959303, -0.0000000000, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-027" : double3x3([0.0000000000, 0.0000000000, 9.1609956894],[13.0279938698, 0.0000000000, 0.0000000000], [0.0000000000, 13.0369938655, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-027-2" : double3x3([0.0000000000, 0.0000000000, 8.4167960395],[13.7939935093, 0.0000000000, 0.0000000000], [0.0000000000, 23.8999887541, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-028" : double3x3([0.0000000000, 6.2579970553, 0.0000000000],[0.0000000000, 0.0000000000, 7.2029966107], [7.9549962568, 0.0000000000, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-028-2" : double3x3([-5.1847975603, -0.0000000000, -0.0000000000],[-0.0000000000, -0.0000000000, -5.1915975571], [-0.0000000000, -6.0979971306, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-029" : double3x3([-0.0000000000, -6.7899968050, -0.0000000000],[-11.2269947172, -0.0000000000, -0.0000000000], [-0.0000000000, -0.0000000000, -21.1859900311]),
      "SpglibTestData/orthorhombic/POSCAR-029-2" : double3x3([0.0000000000, 0.0000000000, 5.2589975254],[6.4719969547, 0.0000000000, 0.0000000000], [0.0000000000, 10.7239949539, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-030" : double3x3([0.0000000000, 0.0000000000, 7.6379964060],[8.8619958301, 0.0000000000, 0.0000000000], [0.0000000000, 10.1869952066, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-030-2" : double3x3([4.4809978915, 0.0000000000, 0.0000000000],[0.0000000000, 7.6719963900, 0.0000000000], [0.0000000000, 0.0000000000, 14.3289932576]),
      "SpglibTestData/orthorhombic/POSCAR-031" : double3x3([4.6539978101, 0.0000000000, 0.0000000000],[0.0000000000, 6.9359967363, 0.0000000000], [0.0000000000, 0.0000000000, 8.8789958221]),
      "SpglibTestData/orthorhombic/POSCAR-031-2" : double3x3([-0.0000000000, -4.9149976873, -0.0000000000],[-5.7429972977, -0.0000000000, -0.0000000000], [-0.0000000000, -0.0000000000, -9.3609955953]),
      "SpglibTestData/orthorhombic/POSCAR-032" : double3x3([10.3880951120, 0.0000000000, 0.0000000000],[0.0000000000, 10.4193950972, 0.0000000000], [0.0000000000, 0.0000000000, 10.7006949649]),
      "SpglibTestData/orthorhombic/POSCAR-032-2" : double3x3([-5.8839972313, -0.0000000000, -0.0000000000],[-0.0000000000, -0.0000000000, -8.2199961321], [-0.0000000000, -11.7679944627, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-033" : double3x3([0.0000000000, 0.0000000000, 4.0556376958],[4.1085543821, 0.0000000000, 0.0000000000], [0.0000000000, 5.5910714829, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-033-2" : double3x3([-0.0000000000, -4.8139977348, -0.0000000000],[-5.4559974327, -0.0000000000, -0.0000000000], [-0.0000000000, -0.0000000000, -11.7869944537]),
      "SpglibTestData/orthorhombic/POSCAR-033-3" : double3x3([-6.9989967067, -0.0000000000, -0.0000000000],[-0.0000000000, -0.0000000000, -9.0939957209], [-0.0000000000, -13.8479934839, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-034" : double3x3([0.0000000000, 0.0000000000, 5.9199972144],[10.8899948758, 0.0000000000, 0.0000000000], [0.0000000000, 12.0299943394, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-034-2" : double3x3([0.0000000000, 0.0000000000, 7.9459962611],[10.3479951308, 0.0000000000, 0.0000000000], [0.0000000000, 10.5219950490, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-035" : double3x3([-0.0000000000, 3.6199982966, -0.0000000000],[-0.0000000000, -0.0000000000, -4.1299980567], [-9.6999954357, -1.8099991483, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-035-2" : double3x3([-0.0000000000, -0.0000000000, -5.3209974962],[-7.1789966220, -8.4124960416, -0.0000000000], [-7.1789966220, 8.4124960416, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-036" : double3x3([0.0000000000, 0.0000000000, -7.7459963552],[0.0000000000, 17.9429915571, 0.0000000000], [17.6464916966, 0.0000000000, 3.8729981776]),
      "SpglibTestData/orthorhombic/POSCAR-036-2" : double3x3([-8.6399959345, -4.9899976520, -0.0000000000],[-8.6399959345, 4.9899976520, -0.0000000000], [-0.0000000000, -0.0000000000, -13.5499936242]),
      "SpglibTestData/orthorhombic/POSCAR-037" : double3x3([-0.0000000000, -0.0000000000, -5.8759972351],[-6.0364971596, -9.5114955244, -0.0000000000], [-6.0364971596, 9.5114955244, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-037-2" : double3x3([0.0000000000, 0.0000000000, 4.7729977541],[5.8069972676, 0.0000000000, 0.0000000000], [2.9034986338, 7.2909965693, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-038" : double3x3([0.0000000000, 0.0000000000, -4.4759978939],[0.0000000000, 6.9469967311, 0.0000000000], [9.4249955651, 0.0000000000, 2.2379989469]),
      "SpglibTestData/orthorhombic/POSCAR-038-2" : double3x3([4.1479980482, 0.0000000000, 0.0000000000],[0.0000000000, 0.0000000000, -6.7169968394], [0.0000000000, 5.9839971843, 3.3584984197]),
      "SpglibTestData/orthorhombic/POSCAR-039" : double3x3([5.4199974497, 0.0000000000, 0.0000000000],[0.0000000000, 0.0000000000, -5.5269973993], [0.0000000000, 19.2899909232, 2.7634986997]),
      "SpglibTestData/orthorhombic/POSCAR-039-2" : double3x3([0.0000000000, 0.0000000000, -5.5359973951],[0.0000000000, 8.2208461317, 2.7679986975], [11.5685945565, 0.0000000000, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-040" : double3x3([0.0000000000, 0.0000000000, -3.5799983155],[0.0000000000, 4.9249976826, 1.7899991577], [9.5399955110, 0.0000000000, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-040-2" : double3x3([5.0859976068, 0.0000000000, 0.0000000000],[0.0000000000, 0.0000000000, -5.8989972243], [0.0000000000, 5.1189975913, 2.9494986121]),
      "SpglibTestData/orthorhombic/POSCAR-041" : double3x3([-0.0000000000, -5.5874973708, -4.5204978729],[-0.0000000000, -5.5874973708, 4.5204978729], [-11.0619947949, -0.0000000000, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-041-2" : double3x3([-0.0000000000, -3.7899982166, -5.0199976379],[-0.0000000000, -3.7899982166, 5.0199976379], [-10.2299951864, -0.0000000000, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-042" : double3x3([-2.6559987502, 2.6814987382, -0.0000000000],[-2.6559987502, -2.6814987382, -0.0000000000], [2.6559987502, 0.0000000000, 5.9344972076]),
      "SpglibTestData/orthorhombic/POSCAR-043" : double3x3([0.0000000000, -4.0784980809, -5.7899972756],[0.0000000000, -4.0784980809, 5.7899972756], [-19.6469907553, 4.0784980809, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-043-2" : double3x3([5.5909973692, 0.0000000000, 5.2864975125],[-5.5909973692, 0.0000000000, 5.2864975125], [0.0000000000, -11.4364946186, -5.2864975125]),
      "SpglibTestData/orthorhombic/POSCAR-044" : double3x3([-3.6519982816, -0.0000000000, -0.0000000000],[-1.8259991408, -2.8259986702, -2.6809987385], [1.8259991408, -2.8259986702, 2.6809987385]),
      "SpglibTestData/orthorhombic/POSCAR-044-2" : double3x3([4.3609979480, 0.0000000000, 0.0000000000],[-2.1804989740, -7.8899962874, -4.8599977132], [-2.1804989740, 7.8899962874, -4.8599977132]),
      "SpglibTestData/orthorhombic/POSCAR-045" : double3x3([0.0000000000, -0.0000000000, -5.5719973781],[-11.1029947756, -0.0000000000, -0.0000000000], [5.5514973878, 9.4619955477, 2.7859986891]),
      "SpglibTestData/orthorhombic/POSCAR-045-2" : double3x3([-5.9199972144, -0.0000000000, -0.0000000000],[2.9599986072, 5.7349973014, 7.0799966686], [2.9599986072, 5.7349973014, -7.0799966686]),
      "SpglibTestData/orthorhombic/POSCAR-046" : double3x3([0.0000000000, 5.0899976049, 0.0000000000],[11.4199946264, 0.0000000000, 0.0000000000], [-5.7099973132, -2.5449988025, -10.9749948358]),
      "SpglibTestData/orthorhombic/POSCAR-046-2" : double3x3([0.0000000000, -0.0000000000, -6.2099970779],[3.9899981225, 5.0949976026, 3.1049985390], [3.9899981225, -5.0949976026, 3.1049985390]),
      "SpglibTestData/orthorhombic/POSCAR-047" : double3x3([0.0000000000, 0.0000000000, 3.0049985860],[3.5849983131, 0.0000000000, 0.0000000000], [0.0000000000, 5.8489972478, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-047-2" : double3x3([-0.0000000000, 0.0000000000, 3.8339981959],[7.2899965698, -0.0000000000, 0.0000000000], [3.6449982849, 6.3149970285, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-048" : double3x3([6.3299970215, 0.0000000000, 0.0000000000],[0.0000000000, 6.3299970215, 0.0000000000], [0.0000000000, 0.0000000000, 9.5399955110]),
      "SpglibTestData/orthorhombic/POSCAR-048-2" : double3x3([0.0000000000, 4.4792978923, 0.0000000000],[0.0000000000, 0.0000000000, 8.0665962043], [9.3330956084, 0.0000000000, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-049" : double3x3([0.0000000000, 5.1399975814, 0.0000000000],[0.0000000000, 0.0000000000, 8.2599961133], [9.5599955016, 0.0000000000, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-049-2" : double3x3([-0.0000000000, -3.6769982698, -0.0000000000],[-6.2169970746, -0.0000000000, -0.0000000000], [-0.0000000000, -0.0000000000, -7.7939963326]),
      "SpglibTestData/orthorhombic/POSCAR-050" : double3x3([0.0000000000, 0.0000000000, 4.1149980637],[7.3269965523, 0.0000000000, 0.0000000000], [0.0000000000, 20.0799905515, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-050-2" : double3x3([5.4768974229, 0.0000000000, 0.0000000000],[0.0000000000, 5.4768974229, 0.0000000000], [0.0000000000, 0.0000000000, 20.7962902145]),
      "SpglibTestData/orthorhombic/POSCAR-051" : double3x3([0.0000000000, 3.8359981950, 0.0000000000],[0.0000000000, 0.0000000000, 8.9279957990], [16.7049921396, 0.0000000000, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-051-2" : double3x3([-0.0000000000, -0.0000000000, -4.5409978633],[-0.0000000000, -8.4099960427, -0.0000000000], [-9.3279956108, -0.0000000000, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-051-3" : double3x3([-2.9659986044, -0.0000000000, -0.0000000000],[-0.0000000000, -0.0000000000, -4.3699979437], [-0.0000000000, -4.5219978722, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-052" : double3x3([8.5879959590, 0.0000000000, 0.0000000000],[0.0000000000, 8.7659958752, 0.0000000000], [0.0000000000, 0.0000000000, 9.3429956037]),
      "SpglibTestData/orthorhombic/POSCAR-052-2" : double3x3([-0.0000000000, -4.8929976976, -0.0000000000],[-5.1829975612, -0.0000000000, -0.0000000000], [-0.0000000000, -0.0000000000, -8.4909960046]),
      "SpglibTestData/orthorhombic/POSCAR-053" : double3x3([8.7939958621, 0.0000000000, 0.0000000000],[0.0000000000, 9.0249957534, 0.0000000000], [0.0000000000, 0.0000000000, 13.0659938519]),
      "SpglibTestData/orthorhombic/POSCAR-053-2" : double3x3([0.0000000000, 0.0000000000, 3.7299982449],[7.3949965203, 0.0000000000, 0.0000000000], [0.0000000000, 8.0149962286, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-054" : double3x3([-0.0000000000, -5.8099972662, -0.0000000000],[-10.1199952381, -0.0000000000, -0.0000000000], [-0.0000000000, -0.0000000000, -10.9499948476]),
      "SpglibTestData/orthorhombic/POSCAR-054-2" : double3x3([-0.0000000000, -5.7809972798, -0.0000000000],[-9.9809953035, -0.0000000000, -0.0000000000], [-0.0000000000, -0.0000000000, -10.5219950490]),
      "SpglibTestData/orthorhombic/POSCAR-055" : double3x3([0.0000000000, 0.0000000000, 3.9739981301],[11.5419945690, 0.0000000000, 0.0000000000], [0.0000000000, 12.6899940288, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-055-2" : double3x3([-0.0000000000, -0.0000000000, -3.9599981367],[-0.0000000000, -7.9149962757, -0.0000000000], [-11.2199947205, -0.0000000000, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-056" : double3x3([-4.9109976892, -0.0000000000, -0.0000000000],[-0.0000000000, -0.0000000000, -5.4119974534], [-0.0000000000, -12.4639941352, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-056-2" : double3x3([0.0000000000, 7.8029963284, 0.0000000000],[0.0000000000, 0.0000000000, 8.5659959693], [10.2729951661, 0.0000000000, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-057" : double3x3([-5.2609975245, -0.0000000000, -0.0000000000],[-0.0000000000, -0.0000000000, -5.7149973109], [-0.0000000000, -11.4249946241, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-057-2" : double3x3([-6.3589970078, -0.0000000000, -0.0000000000],[-0.0000000000, -0.0000000000, -6.6669968629], [-0.0000000000, -9.7649954052, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-058" : double3x3([0.0000000000, 0.0000000000, 6.9019967523],[10.8399948993, 0.0000000000, 0.0000000000], [0.0000000000, 23.6929888515, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-058-2" : double3x3([-0.0000000000, -0.0000000000, -2.9629986058],[-0.0000000000, -4.3319979616, -0.0000000000], [-4.8729977070, -0.0000000000, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-058-3" : double3x3([-0.0000000000, -0.0000000000, -2.5724917260],[-0.0000000000, -3.8912820645, -0.0000000000], [-4.0215465742, -0.0000000000, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-059" : double3x3([-0.0000000000, -0.0000000000, -3.5629983235],[-0.0000000000, -4.3689979442, -0.0000000000], [-11.5099945841, -0.0000000000, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-059-2" : double3x3([0.0000000000, 2.8649986519, 0.0000000000],[0.0000000000, 0.0000000000, 4.0449980967], [4.6449978143, 0.0000000000, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-060" : double3x3([0.0000000000, 6.2489970596, 0.0000000000],[0.0000000000, 0.0000000000, 6.3069970323], [16.1519923998, 0.0000000000, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-060-2" : double3x3([0.0000000000, 0.0000000000, 8.0309962211],[9.5179955214, 0.0000000000, 0.0000000000], [0.0000000000, 9.7489954127, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-060-3" : double3x3([0.0000000000, 0.0000000000, 3.8726073154],[5.3672739848, 0.0000000000, 0.0000000000], [0.0000000000, 6.5883789815, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-061" : double3x3([0.0000000000, 0.0000000000, 10.5369950419],[12.1989942599, 0.0000000000, 0.0000000000], [0.0000000000, 13.0469938608, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-061-2" : double3x3([5.9929971800, 0.0000000000, 0.0000000000],[0.0000000000, 7.8189963208, 0.0000000000], [0.0000000000, 0.0000000000, 8.0109962305]),
      "SpglibTestData/orthorhombic/POSCAR-062" : double3x3([-0.0000000000, -6.8979967542, -0.0000000000],[-7.4899964756, -0.0000000000, -0.0000000000], [-0.0000000000, -0.0000000000, -10.9419948513]),
      "SpglibTestData/orthorhombic/POSCAR-062-2" : double3x3([0.0000000000, 0.0000000000, 9.3749955887],[9.4949955322, 0.0000000000, 0.0000000000], [0.0000000000, 10.1499952240, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-063" : double3x3([-4.6004978353, -3.5794983157, -0.0000000000],[-4.6004978353, 3.5794983157, -0.0000000000], [-0.0000000000, -0.0000000000, -9.7709954023]),
      "SpglibTestData/orthorhombic/POSCAR-063-2" : double3x3([5.5689973796, 0.0000000000, 0.0000000000],[2.7844986898, 6.3979969895, 0.0000000000], [0.0000000000, 0.0000000000, 7.3199965556]),
      "SpglibTestData/orthorhombic/POSCAR-063-3" : double3x3([-4.4499979061, -2.8799986448, -0.0000000000],[-4.4499979061, 2.8799986448, -0.0000000000], [-0.0000000000, -0.0000000000, -13.3299937277]),
      "SpglibTestData/orthorhombic/POSCAR-064" : double3x3([-0.0000000000, -5.3699974732, -0.0000000000],[-5.4059974563, -0.0000000000, -0.0000000000], [-0.0000000000, -2.6849987366, -6.5749969062]),
      "SpglibTestData/orthorhombic/POSCAR-064-2" : double3x3([5.4649974285, 0.0000000000, 0.0000000000],[0.0000000000, 5.4709974257, 0.0000000000], [0.0000000000, 2.7354987128, 6.1054971271]),
      "SpglibTestData/orthorhombic/POSCAR-064-3" : double3x3([-2.8785911754, -2.5705256182, -0.0000000000],[-2.8785911754, 2.5705256182, -0.0000000000], [-0.0000000000, -0.0000000000, -6.8086137766]),
      "SpglibTestData/orthorhombic/POSCAR-065" : double3x3([-2.4189988618, -4.0734980832, -0.0000000000],[-2.4189988618, 4.0734980832, -0.0000000000], [-0.0000000000, -0.0000000000, -6.1069971264]),
      "SpglibTestData/orthorhombic/POSCAR-065-2" : double3x3([-0.0000000000, -0.0000000000, -4.0599980896],[-2.8799986448, -3.1899984990, -0.0000000000], [-2.8799986448, 3.1899984990, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-065-3" : double3x3([-0.0000000000, -3.8712981784, -0.0000000000],[-3.9091981606, -0.0000000000, -0.0000000000], [0.0511698229, -0.0000000000, -3.9088632501]),
      "SpglibTestData/orthorhombic/POSCAR-066" : double3x3([-3.1649985107, -5.2399975344, -0.0000000000],[-3.1649985107, 5.2399975344, -0.0000000000], [-0.0000000000, -0.0000000000, -10.5299950452]),
      "SpglibTestData/orthorhombic/POSCAR-066-2" : double3x3([0.0000000000, 0.0000000000, 7.0268966936],[7.0696966734, 0.0000000000, 0.0000000000], [3.5348483367, 12.7461440024, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-067" : double3x3([-0.0000000000, -0.0000000000, -4.3739979419],[-3.9849981249, -5.8609972422, -0.0000000000], [-3.9849981249, 5.8609972422, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-067-2" : double3x3([-5.6829973259, -4.9579976671, -0.0000000000],[-5.6829973259, 4.9579976671, -0.0000000000], [-0.0000000000, -0.0000000000, -8.2709961081]),
      "SpglibTestData/orthorhombic/POSCAR-067-3" : double3x3([3.8899981696, 0.0000000000, 3.8199982025],[3.8899981696, 0.0000000000, -3.8199982025], [0.0000000000, 5.4899974167, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-068" : double3x3([-7.4099965133, -0.0000000000, -0.0000000000],[-0.0000000000, -0.0000000000, -7.4399964992], [-3.7049982566, -11.1299947629, -0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-068-2" : double3x3([0.0000000000, 0.0000000000, 6.3839969961],[6.4179969801, 0.0000000000, 0.0000000000], [3.2089984900, 5.6829973259, 0.0000000000]),
      "SpglibTestData/orthorhombic/POSCAR-069" : double3x3([5.4299974450, 0.0000000000, 3.1949984966],[-5.4299974450, 0.0000000000, 3.1949984966], [0.0000000000, -6.7999968003, -3.1949984966]),
      "SpglibTestData/orthorhombic/POSCAR-069-2" : double3x3([-0.0000000000, -0.0000000000, -2.7382087116],[0.0000000000, 5.6303973507, 1.3691043558], [6.2133470764, -0.0000000000, -1.3691043558]),
      "SpglibTestData/orthorhombic/POSCAR-070" : double3x3([4.1779980341, 0.0000000000, 3.5194983439],[-4.1779980341, 0.0000000000, 3.5194983439], [0.0000000000, -5.0929976035, -3.5194983439]),
      "SpglibTestData/orthorhombic/POSCAR-070-2" : double3x3([0.0000000000, -4.8014977407, -3.7309982444],[-0.0000000000, 4.8014977407, -3.7309982444], [4.8494977181, -0.0000000000, 3.7309982444]),
      "SpglibTestData/orthorhombic/POSCAR-071" : double3x3([-0.0000000000, 0.0000000000, -2.8749986472],[-4.7149977814, -0.0000000000, -0.0000000000], [2.3574988907, 7.8534963046, 1.4374993236]),
      "SpglibTestData/orthorhombic/POSCAR-071-2" : double3x3([3.5419983333, 0.0000000000, 0.0000000000],[0.0000000000, -0.0000000000, 3.8269981992], [-1.7709991667, -6.3479970130, -1.9134990996]),
      "SpglibTestData/orthorhombic/POSCAR-072" : double3x3([0.0000000000, 0.0000000000, 4.8579977141],[0.0000000000, 7.5009964705, 0.0000000000], [-7.9829962437, -3.7504982352, -2.4289988571]),
      "SpglibTestData/orthorhombic/POSCAR-072-2" : double3x3([-0.0000000000, 0.0000000000, -5.4019974581],[-5.9669971923, -0.0000000000, -0.0000000000], [2.9834985961, 5.2399975344, 2.7009987291]),
      "SpglibTestData/orthorhombic/POSCAR-073" : double3x3([-8.2701961085, -0.0000000000, -0.0000000000],[-0.0000000000, -8.3114960891, -0.0000000000], [4.1350980543, 4.1557480445, 10.3034951518]),
      "SpglibTestData/orthorhombic/POSCAR-073-2" : double3x3([-0.0000000000, -5.7499972944, -0.0000000000],[-0.0000000000, 0.0000000000, -5.9499972003], [10.1149952405, 2.8749986472, 2.9749986001]),
      "SpglibTestData/orthorhombic/POSCAR-074" : double3x3([-0.0000000000, -0.0000000000, -5.6959973198],[4.1239980595, 5.7219973076, 2.8479986599], [4.1239980595, -5.7219973076, 2.8479986599]),
      "SpglibTestData/orthorhombic/POSCAR-074-2" : double3x3([-5.9119972182, -0.0000000000, -0.0000000000],[2.9559986091, 2.9724986013, 4.1939980265], [2.9559986091, 2.9724986013, -4.1939980265])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          var histogram:[Int:Int] = [:]
                    
          for atom in reader.atoms
          {
            histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
          }
          
          // Find least occurent element
          let minType: Int = histogram.min{a, b in a.value < b.value}!.key
          
          //let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.filter{$0.type == minType}
          let reducedAtoms = reader.atoms
          
          // search for a primitive cell based on the positions of the atoms
          let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: reader.atoms, unitCell: unitCell, symmetryPrecision: precision)
         
          let DelaunayUnitCell: double3x3? = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: precision)
          
          XCTAssertNotNil(DelaunayUnitCell, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = DelaunayUnitCell
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
  
  func testFindTetragonalSpaceGroup()
  {
    let testData: [String: double3x3] =
    [
      "SpglibTestData/tetragonal/POSCAR-075" : double3x3([0.0000000000, 0.0000000000, 3.9439981442],[17.4899917702, 0.0000000000, 0.0000000000], [0.0000000000, 17.4899917702, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-075-2" : double3x3([9.1969956724, 0.0000000000, 0.0000000000],[0.0000000000, 9.1969956724, 0.0000000000], [0.0000000000, 0.0000000000, 20.5049903515]),
      "SpglibTestData/tetragonal/POSCAR-076" : double3x3([3.9809981268, 0.0000000000, 0.0000000000],[0.0000000000, 3.9809981268, 0.0000000000], [0.0000000000, 0.0000000000, 15.3499927772]),
      "SpglibTestData/tetragonal/POSCAR-076-2" : double3x3([8.4479960249, 0.0000000000, 0.0000000000],[0.0000000000, 8.4479960249, 0.0000000000], [0.0000000000, 0.0000000000, 14.9119929833]),
      "SpglibTestData/tetragonal/POSCAR-077" : double3x3([0.0000000000, 0.0000000000, 10.6379949944],[11.1639947469, 0.0000000000, 0.0000000000], [0.0000000000, 11.1639947469, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-077-2" : double3x3([7.9799962451, 0.0000000000, 0.0000000000],[0.0000000000, 7.9799962451, 0.0000000000], [0.0000000000, 0.0000000000, 9.7799953981]),
      "SpglibTestData/tetragonal/POSCAR-077-3" : double3x3([0.0000000000, 0.0000000000, 10.6379949944],[11.1639947469, 0.0000000000, 0.0000000000], [0.0000000000, 11.1639947469, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-078" : double3x3([10.8649948876, 0.0000000000, 0.0000000000],[0.0000000000, 10.8649948876, 0.0000000000], [0.0000000000, 0.0000000000, 28.3569866568]),
      "SpglibTestData/tetragonal/POSCAR-078-2" : double3x3([7.6289964102, 0.0000000000, 0.0000000000],[0.0000000000, 7.6289964102, 0.0000000000], [0.0000000000, 0.0000000000, 29.4969861204]),
      "SpglibTestData/tetragonal/POSCAR-079" : double3x3([0.0000000000, 0.0000000000, -5.8129972647],[4.2419980040, 4.2419980040, 2.9064986324], [4.2419980040, -4.2419980040, -2.9064986324]),
      "SpglibTestData/tetragonal/POSCAR-079-2" : double3x3([0.0000000000, -0.0000000000, -7.6089964196],[7.4594964900, 7.4594964900, 3.8044982098], [7.4594964900, -7.4594964900, -3.8044982098]),
      "SpglibTestData/tetragonal/POSCAR-080" : double3x3([0.0000000000, 0.0000000000, -14.6679930981],[10.1689952151, 10.1689952151, 7.3339965490], [10.1689952151, -10.1689952151, -7.3339965490]),
      "SpglibTestData/tetragonal/POSCAR-080-2" : double3x3([0.0000000000, 0.0000000000, -5.9849971838],[4.8464977195, 4.8464977195, 2.9924985919], [4.8464977195, -4.8464977195, -2.9924985919]),
      "SpglibTestData/tetragonal/POSCAR-081" : double3x3([0.0000000000, 0.0000000000, 6.3199970262],[7.6208964140, 0.0000000000, 0.0000000000], [0.0000000000, 7.6208964140, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-081-2" : double3x3([0.0000000000, 0.0000000000, 5.2949975085],[10.1814952092, 0.0000000000, 0.0000000000], [0.0000000000, 10.1814952092, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-082" : double3x3([-5.5479973894, -0.0000000000, -0.0000000000],[-0.0000000000, -5.5479973894, -0.0000000000], [2.7739986947, 2.7739986947, 5.0849976073]),
      "SpglibTestData/tetragonal/POSCAR-082-2" : double3x3([-6.3219970252, -0.0000000000, -0.0000000000],[-0.0000000000, -6.3219970252, -0.0000000000], [3.1609985126, 3.1609985126, 6.3024970344]),
      "SpglibTestData/tetragonal/POSCAR-083" : double3x3([0.0000000000, 0.0000000000, 3.1344985251],[8.3279960813, 0.0000000000, 0.0000000000], [0.0000000000, 8.3279960813, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-083-2" : double3x3([1.2599994071, 2.5199988142, -0.0000000000],[2.5199988142, -1.2599994071, 0.0000000000], [-1.8899991107, -0.6299997036, -1.9999990589]),
      "SpglibTestData/tetragonal/POSCAR-083-3" : double3x3([-0.0000000000, -0.0000000000, -3.6799982684],[-3.9099981602, -3.9099981602, -0.0000000000], [-3.9099981602, 3.9099981602, -0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-084" : double3x3([6.4299969744, 0.0000000000, 0.0000000000],[0.0000000000, 6.4299969744, 0.0000000000], [0.0000000000, 0.0000000000, 6.6299968803]),
      "SpglibTestData/tetragonal/POSCAR-084-2" : double3x3([0.0000000000, 0.0000000000, 6.5979968954],[7.1669966276, 0.0000000000, 0.0000000000], [0.0000000000, 7.1669966276, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-085" : double3x3([0.0000000000, 0.0000000000, 4.1009980703],[6.2609970539, 0.0000000000, 0.0000000000], [0.0000000000, 6.2609970539, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-085-2" : double3x3([0.0000000000, 0.0000000000, 7.4899964756],[8.3799960569, 0.0000000000, 0.0000000000], [0.0000000000, 8.3799960569, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-086" : double3x3([0.0000000000, 0.0000000000, 6.1889970878],[11.1869947360, 0.0000000000, 0.0000000000], [0.0000000000, 11.1869947360, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-086-2" : double3x3([0.0000000000, 0.0000000000, 3.8219982016],[7.0699966733, 0.0000000000, 0.0000000000], [0.0000000000, 7.0699966733, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-087" : double3x3([5.7039973160, 5.7039973160, 5.1279975871],[5.7039973160, -5.7039973160, -5.1279975871], [-5.7039973160, 5.7039973160, -5.1279975871]),
      "SpglibTestData/tetragonal/POSCAR-087-2" : double3x3([0.0000000000, 0.0000000000, -3.1269985286],[4.9424976743, 4.9424976743, 1.5634992643], [4.9424976743, -4.9424976743, -1.5634992643]),
      "SpglibTestData/tetragonal/POSCAR-088" : double3x3([0.0000000000, 0.0000000000, -5.9809971857],[6.8479967777, 6.8479967777, 2.9904985928], [6.8479967777, -6.8479967777, -2.9904985928]),
      "SpglibTestData/tetragonal/POSCAR-088-2" : double3x3([-5.7409972986, -0.0000000000, -0.0000000000],[-0.0000000000, -5.7409972986, -0.0000000000], [2.8704986493, 2.8704986493, 6.5604969130]),
      "SpglibTestData/tetragonal/POSCAR-090" : double3x3([0.0000000000, 0.0000000000, 7.1599966309],[9.5597955017, 0.0000000000, 0.0000000000], [0.0000000000, 9.5597955017, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-090-2" : double3x3([-3.7149982519, -3.7149982519, -0.0000000000],[-3.7149982519, 3.7149982519, -0.0000000000], [-0.0000000000, -0.0000000000, -10.6099950076]),
      "SpglibTestData/tetragonal/POSCAR-091" : double3x3([7.0081967023, 0.0000000000, 0.0000000000],[0.0000000000, 7.0081967023, 0.0000000000], [0.0000000000, 0.0000000000, 8.6517959290]),
      "SpglibTestData/tetragonal/POSCAR-091-2" : double3x3([12.4639941352, 0.0000000000, 0.0000000000],[0.0000000000, 12.4639941352, 0.0000000000], [0.0000000000, 0.0000000000, 26.2229876610]),
      "SpglibTestData/tetragonal/POSCAR-092" : double3x3([7.1039966573, 0.0000000000, 0.0000000000],[0.0000000000, 7.1039966573, 0.0000000000], [0.0000000000, 0.0000000000, 36.5969827796]),
      "SpglibTestData/tetragonal/POSCAR-092-2" : double3x3([6.5899968991, 0.0000000000, 0.0000000000],[0.0000000000, 6.5899968991, 0.0000000000], [0.0000000000, 0.0000000000, 17.0399919820]),
      "SpglibTestData/tetragonal/POSCAR-092-3" : double3x3([4.0643712984, 0.0000000000, 0.0000000000],[0.0000000000, 4.0643712984, 0.0000000000], [0.0000000000, 0.0000000000, 5.6346473255]),
      "SpglibTestData/tetragonal/POSCAR-094" : double3x3([4.6862977949, 0.0000000000, 0.0000000000],[0.0000000000, 4.6862977949, 0.0000000000], [0.0000000000, 0.0000000000, 9.1909956753]),
      "SpglibTestData/tetragonal/POSCAR-094-2" : double3x3([9.9619953125, 0.0000000000, 0.0000000000],[0.0000000000, 9.9619953125, 0.0000000000], [0.0000000000, 0.0000000000, 13.4139936882]),
      "SpglibTestData/tetragonal/POSCAR-094-3" : double3x3([7.3449965439, 0.0000000000, 0.0000000000],[0.0000000000, 7.3449965439, 0.0000000000], [0.0000000000, 0.0000000000, 10.3999951064]),
      "SpglibTestData/tetragonal/POSCAR-095" : double3x3([6.1699970968, 0.0000000000, 0.0000000000],[0.0000000000, 6.1699970968, 0.0000000000], [0.0000000000, 0.0000000000, 8.5639959703]),
      "SpglibTestData/tetragonal/POSCAR-095-2" : double3x3([6.0803971389, 0.0000000000, 0.0000000000],[0.0000000000, 6.0803971389, 0.0000000000], [0.0000000000, 0.0000000000, 8.3987960480]),
      "SpglibTestData/tetragonal/POSCAR-096" : double3x3([7.4899964756, 0.0000000000, 0.0000000000],[0.0000000000, 7.4899964756, 0.0000000000], [0.0000000000, 0.0000000000, 13.2399937700]),
      "SpglibTestData/tetragonal/POSCAR-096-2" : double3x3([5.9969971782, 0.0000000000, 0.0000000000],[0.0000000000, 5.9969971782, 0.0000000000], [0.0000000000, 0.0000000000, 39.1909815590]),
      "SpglibTestData/tetragonal/POSCAR-097" : double3x3([-7.4829964789, -0.0000000000, -0.0000000000],[-0.0000000000, -7.4829964789, -0.0000000000], [3.7414982395, 3.7414982395, 7.4464964961]),
      "SpglibTestData/tetragonal/POSCAR-097-2" : double3x3([4.7654977576, 4.7654977576, 6.4119969829],[4.7654977576, -4.7654977576, -6.4119969829], [-4.7654977576, 4.7654977576, -6.4119969829]),
      "SpglibTestData/tetragonal/POSCAR-098" : double3x3([0.0000000000, -0.0000000000, -4.6779977988],[3.9769981287, 3.9769981287, 2.3389988994], [3.9769981287, -3.9769981287, -2.3389988994]),
      "SpglibTestData/tetragonal/POSCAR-098-2" : double3x3([-9.3829955849, -0.0000000000, -0.0000000000],[-0.0000000000, -9.3829955849, -0.0000000000], [4.6914977925, 4.6914977925, 27.2999871542]),
      "SpglibTestData/tetragonal/POSCAR-099" : double3x3([3.8989981654, 0.0000000000, 0.0000000000],[0.0000000000, 3.8989981654, 0.0000000000], [0.0000000000, 0.0000000000, 4.1669980393]),
      "SpglibTestData/tetragonal/POSCAR-099-2" : double3x3([3.8071982086, 0.0000000000, 0.0000000000],[0.0000000000, 3.8071982086, 0.0000000000], [0.0000000000, 0.0000000000, 4.6981977893]),
      "SpglibTestData/tetragonal/POSCAR-100" : double3x3([0.0000000000, 0.0000000000, 5.2149975461],[8.8699958263, 0.0000000000, 0.0000000000], [0.0000000000, 8.8699958263, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-100-2" : double3x3([8.3119960889, 0.0000000000, 0.0000000000],[0.0000000000, 8.3119960889, 0.0000000000], [0.0000000000, 0.0000000000, 10.0699952616]),
      "SpglibTestData/tetragonal/POSCAR-102" : double3x3([0.0000000000, 0.0000000000, 8.0199962263],[8.8639958291, 0.0000000000, 0.0000000000], [0.0000000000, 8.8639958291, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-102-2" : double3x3([0.0000000000, 0.0000000000, 5.6559973386],[10.7589949374, 0.0000000000, 0.0000000000], [0.0000000000, 10.7589949374, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-103" : double3x3([6.5509969175, 0.0000000000, 0.0000000000],[0.0000000000, 6.5509969175, 0.0000000000], [0.0000000000, 0.0000000000, 6.8469967782]),
      "SpglibTestData/tetragonal/POSCAR-103-2" : double3x3([6.5139969349, 0.0000000000, 0.0000000000],[0.0000000000, 6.5139969349, 0.0000000000], [0.0000000000, 0.0000000000, 6.8089967961]),
      "SpglibTestData/tetragonal/POSCAR-104" : double3x3([0.0000000000, 0.0000000000, 9.2369956536],[9.4159955694, 0.0000000000, 0.0000000000], [0.0000000000, 9.4159955694, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-104-2" : double3x3([0.0000000000, 0.0000000000, 9.0089957609],[10.6199950028, 0.0000000000, 0.0000000000], [0.0000000000, 10.6199950028, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-105" : double3x3([7.6179964154, 0.0000000000, 0.0000000000],[0.0000000000, 7.6179964154, 0.0000000000], [0.0000000000, 0.0000000000, 8.4999960004]),
      "SpglibTestData/tetragonal/POSCAR-105-2" : double3x3([5.6399973461, 0.0000000000, 0.0000000000],[0.0000000000, 5.6399973461, 0.0000000000], [0.0000000000, 0.0000000000, 9.0499957416]),
      "SpglibTestData/tetragonal/POSCAR-106" : double3x3([0.0000000000, 0.0000000000, 5.3079975024],[10.8389948998, 0.0000000000, 0.0000000000], [0.0000000000, 10.8389948998, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-107" : double3x3([-7.7619963477, -0.0000000000, -0.0000000000],[-0.0000000000, -7.7619963477, -0.0000000000], [3.8809981738, 3.8809981738, 5.8729972365]),
      "SpglibTestData/tetragonal/POSCAR-107-2" : double3x3([-4.1199980614, -0.0000000000, -0.0000000000],[-0.0000000000, -4.1199980614, -0.0000000000], [2.0599990307, 2.0599990307, 5.2374975355]),
      "SpglibTestData/tetragonal/POSCAR-107-3" : double3x3([-3.5518983287, -0.0000000000, -0.0000000000],[-0.0000000000, -3.5518983287, -0.0000000000], [1.7759491643, 1.7759491643, 12.8226939664]),
      "SpglibTestData/tetragonal/POSCAR-108" : double3x3([-6.1399971109, -0.0000000000, -0.0000000000],[-0.0000000000, -6.1399971109, -0.0000000000], [3.0699985554, 3.0699985554, 5.2859975127]),
      "SpglibTestData/tetragonal/POSCAR-108-2" : double3x3([-8.0549962098, -0.0000000000, -0.0000000000],[-0.0000000000, -8.0549962098, -0.0000000000], [4.0274981049, 4.0274981049, 7.8439963091]),
      "SpglibTestData/tetragonal/POSCAR-109" : double3x3([-3.4516983758, -0.0000000000, -0.0000000000],[-0.0000000000, -3.4516983758, -0.0000000000], [1.7258491879, 1.7258491879, 5.8399972520]),
      "SpglibTestData/tetragonal/POSCAR-109-2" : double3x3([0.0000000000, 0.0000000000, -8.7499958828],[5.6899973226, 5.6899973226, 4.3749979414], [5.6899973226, -5.6899973226, -4.3749979414]),
      "SpglibTestData/tetragonal/POSCAR-110" : double3x3([0.0000000000, 0.0000000000, -9.0999957181],[6.8099967956, 6.8099967956, 4.5499978590], [6.8099967956, -6.8099967956, -4.5499978590]),
      "SpglibTestData/tetragonal/POSCAR-110-2" : double3x3([-11.7822944559, -0.0000000000, -0.0000000000],[-0.0000000000, -11.7822944559, -0.0000000000], [5.8911472280, 5.8911472280, 11.8192444385]),
      "SpglibTestData/tetragonal/POSCAR-111" : double3x3([5.1599975720, 0.0000000000, 0.0000000000],[0.0000000000, 5.1599975720, 0.0000000000], [0.0000000000, 0.0000000000, 10.0699952616]),
      "SpglibTestData/tetragonal/POSCAR-111-2" : double3x3([0.0000000000, 0.0000000000, 5.8013972702],[5.8150972638, 0.0000000000, 0.0000000000], [0.0000000000, 5.8150972638, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-112" : double3x3([5.4299974450, 0.0000000000, 0.0000000000],[0.0000000000, 5.4299974450, 0.0000000000], [0.0000000000, 0.0000000000, 10.0959952494]),
      "SpglibTestData/tetragonal/POSCAR-112-2" : double3x3([5.4149974520, 0.0000000000, 0.0000000000],[0.0000000000, 5.4149974520, 0.0000000000], [0.0000000000, 0.0000000000, 10.1969952019]),
      "SpglibTestData/tetragonal/POSCAR-113" : double3x3([0.0000000000, 0.0000000000, 4.7159977809],[5.6619973358, 0.0000000000, 0.0000000000], [0.0000000000, 5.6619973358, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-113-2" : double3x3([0.0000000000, 0.0000000000, 4.2785979867],[6.4023969874, 0.0000000000, 0.0000000000], [0.0000000000, 6.4023969874, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-114" : double3x3([0.0000000000, 0.0000000000, 6.3489970125],[7.4839964785, 0.0000000000, 0.0000000000], [0.0000000000, 7.4839964785, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-114-2" : double3x3([0.0000000000, 0.0000000000, 6.8099967956],[10.8099949134, 0.0000000000, 0.0000000000], [0.0000000000, 10.8099949134, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-115" : double3x3([3.3269984345, 0.0000000000, 0.0000000000],[0.0000000000, 3.3269984345, 0.0000000000], [0.0000000000, 0.0000000000, 6.1509971057]),
      "SpglibTestData/tetragonal/POSCAR-115-2" : double3x3([3.8589981842, 0.0000000000, 0.0000000000],[0.0000000000, 3.8589981842, 0.0000000000], [0.0000000000, 0.0000000000, 11.7099944900]),
      "SpglibTestData/tetragonal/POSCAR-115-3" : double3x3([-1.6494930782, -1.6494930782, -0.0000000000],[-1.6494930782, 1.6494930782, -0.0000000000], [-0.0000000000, -0.0000000000, -4.7886334410]),
      "SpglibTestData/tetragonal/POSCAR-115-4" : double3x3([5.0189976384, 0.0000000000, 0.0000000000],[0.0000000000, 5.0189976384, 0.0000000000], [0.0000000000, 0.0000000000, 8.4279960343]),
      "SpglibTestData/tetragonal/POSCAR-115-5" : double3x3([-2.6399987578, -2.6399987578, -0.0000000000],[-2.6399987578, 2.6399987578, -0.0000000000], [-0.0000000000, -0.0000000000, -5.2049975508]),
      "SpglibTestData/tetragonal/POSCAR-116" : double3x3([5.5249974003, 0.0000000000, 0.0000000000],[0.0000000000, 5.5249974003, 0.0000000000], [0.0000000000, 0.0000000000, 17.4629917829]),
      "SpglibTestData/tetragonal/POSCAR-116-2" : double3x3([10.5659950283, 0.0000000000, 0.0000000000],[0.0000000000, 10.5659950283, 0.0000000000], [0.0000000000, 0.0000000000, 25.2199881329]),
      "SpglibTestData/tetragonal/POSCAR-117" : double3x3([-0.0000000000, -0.0000000000, -5.6199973556],[-5.4649974285, -5.4649974285, -0.0000000000], [-5.4649974285, 5.4649974285, -0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-117-2" : double3x3([5.7099973132, 0.0000000000, 0.0000000000],[0.0000000000, 5.7099973132, 0.0000000000], [0.0000000000, 0.0000000000, 16.4579922558]),
      "SpglibTestData/tetragonal/POSCAR-118" : double3x3([0.0000000000, 0.0000000000, 5.1646975698],[6.5959968963, 0.0000000000, 0.0000000000], [0.0000000000, 6.5959968963, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-118-2" : double3x3([7.8229963190, 0.0000000000, 0.0000000000],[0.0000000000, 7.8229963190, 0.0000000000], [0.0000000000, 0.0000000000, 9.0529957402]),
      "SpglibTestData/tetragonal/POSCAR-119" : double3x3([-6.2679970506, -0.0000000000, -0.0000000000],[-0.0000000000, -6.2679970506, -0.0000000000], [3.1339985253, 3.1339985253, 7.3909965222]),
      "SpglibTestData/tetragonal/POSCAR-119-2" : double3x3([-3.9199981555, -0.0000000000, -0.0000000000],[-0.0000000000, -3.9199981555, -0.0000000000], [1.9599990777, 1.9599990777, 7.6099964192]),
      "SpglibTestData/tetragonal/POSCAR-120" : double3x3([-8.4669960159, -0.0000000000, -0.0000000000],[-0.0000000000, -8.4669960159, -0.0000000000], [4.2334980080, 4.2334980080, 6.3724970015]),
      "SpglibTestData/tetragonal/POSCAR-120-2" : double3x3([6.2237970714, 6.2237970714, 6.4638469585],[6.2237970714, -6.2237970714, -6.4638469585], [-6.2237970714, 6.2237970714, -6.4638469585]),
      "SpglibTestData/tetragonal/POSCAR-121" : double3x3([2.4879988293, 2.4879988293, 3.3729984129],[2.4879988293, -2.4879988293, -3.3729984129], [-2.4879988293, 2.4879988293, -3.3729984129]),
      "SpglibTestData/tetragonal/POSCAR-121-2" : double3x3([2.5234988126, 2.5234988126, 3.2429984740],[2.5234988126, -2.5234988126, -3.2429984740], [-2.5234988126, 2.5234988126, -3.2429984740]),
      "SpglibTestData/tetragonal/POSCAR-122" : double3x3([0.0000000000, 0.0000000000, -5.6199973556],[5.7419972981, 5.7419972981, 2.8099986778], [5.7419972981, -5.7419972981, -2.8099986778]),
      "SpglibTestData/tetragonal/POSCAR-122-2" : double3x3([7.4664964867, 7.4664964867, 7.7734963422],[7.4664964867, -7.4664964867, -7.7734963422], [-7.4664964867, 7.4664964867, -7.7734963422]),
      "SpglibTestData/tetragonal/POSCAR-122-3" : double3x3([-3.9576830213, -0.0000000000, -0.0000000000],[-0.0000000000, -3.9576830213, -0.0000000000], [1.9788415106, 1.9788415106, 2.9882372600]),
      "SpglibTestData/tetragonal/POSCAR-123" : double3x3([0.0000000000, 0.0000000000, -3.2789984571],[2.0094990544, 2.0094990544, 1.6394992285], [2.0094990544, -2.0094990544, -1.6394992285]),
      "SpglibTestData/tetragonal/POSCAR-123-2" : double3x3([8.9809957741, 0.0000000000, 0.0000000000],[0.0000000000, 8.9809957741, 0.0000000000], [0.0000000000, 0.0000000000, 12.6379940533]),
      "SpglibTestData/tetragonal/POSCAR-123-3" : double3x3([4.1999980237, 0.0000000000, 0.0000000000],[0.0000000000, 4.1999980237, 0.0000000000], [0.0000000000, 0.0000000000, 7.9599962545]),
      "SpglibTestData/tetragonal/POSCAR-124" : double3x3([3.0589985606, 3.0589985606, 2.4979988246],[3.0589985606, -3.0589985606, -2.4979988246], [-3.0589985606, 3.0589985606, -2.4979988246]),
      "SpglibTestData/tetragonal/POSCAR-124-2" : double3x3([6.2099970779, 0.0000000000, 0.0000000000],[0.0000000000, 6.2099970779, 0.0000000000], [0.0000000000, 0.0000000000, 11.0019948231]),
      "SpglibTestData/tetragonal/POSCAR-125" : double3x3([0.0000000000, 0.0000000000, 6.7129968413],[8.5159959929, 0.0000000000, 0.0000000000], [0.0000000000, 8.5159959929, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-125-2" : double3x3([6.3759969998, 0.0000000000, 0.0000000000],[0.0000000000, 6.3759969998, 0.0000000000], [0.0000000000, 0.0000000000, 8.3289960809]),
      "SpglibTestData/tetragonal/POSCAR-126" : double3x3([0.0000000000, 0.0000000000, 6.1899970873],[11.3499946594, 0.0000000000, 0.0000000000], [0.0000000000, 11.3499946594, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-126-2" : double3x3([6.3123970298, 0.0000000000, 0.0000000000],[0.0000000000, 6.3123970298, 0.0000000000], [0.0000000000, 0.0000000000, 9.5494955066]),
      "SpglibTestData/tetragonal/POSCAR-127" : double3x3([5.8939972266, 0.0000000000, 0.0000000000],[0.0000000000, 5.8939972266, 0.0000000000], [0.0000000000, 0.0000000000, 8.3479960719]),
      "SpglibTestData/tetragonal/POSCAR-127-2" : double3x3([0.0000000000, 0.0000000000, 4.1439980501],[7.1049966568, 0.0000000000, 0.0000000000], [0.0000000000, 7.1049966568, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-128" : double3x3([7.0576966791, 0.0000000000, 0.0000000000],[0.0000000000, 7.0576966791, 0.0000000000], [0.0000000000, 0.0000000000, 9.9783953047]),
      "SpglibTestData/tetragonal/POSCAR-128-2" : double3x3([7.7435963563, 0.0000000000, 0.0000000000],[0.0000000000, 7.7435963563, 0.0000000000], [0.0000000000, 0.0000000000, 11.6402945228]),
      "SpglibTestData/tetragonal/POSCAR-129" : double3x3([4.2819979851, 0.0000000000, 0.0000000000],[0.0000000000, 4.2819979851, 0.0000000000], [0.0000000000, 0.0000000000, 6.1819970911]),
      "SpglibTestData/tetragonal/POSCAR-129-2" : double3x3([0.0000000000, 0.0000000000, 4.8099977367],[5.0049976449, 0.0000000000, 0.0000000000], [0.0000000000, 5.0049976449, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-129-3" : double3x3([4.2819979851, 0.0000000000, 0.0000000000],[0.0000000000, 4.2819979851, 0.0000000000], [0.0000000000, 0.0000000000, 6.1819970911]),
      "SpglibTestData/tetragonal/POSCAR-130" : double3x3([5.9239972125, 0.0000000000, 0.0000000000],[0.0000000000, 5.9239972125, 0.0000000000], [0.0000000000, 0.0000000000, 18.1299914691]),
      "SpglibTestData/tetragonal/POSCAR-130-2" : double3x3([7.3771965287, 0.0000000000, 0.0000000000],[0.0000000000, 7.3771965287, 0.0000000000], [0.0000000000, 0.0000000000, 15.1230928839]),
      "SpglibTestData/tetragonal/POSCAR-131" : double3x3([3.0199985790, 0.0000000000, 0.0000000000],[0.0000000000, 3.0199985790, 0.0000000000], [0.0000000000, 0.0000000000, 5.3099975014]),
      "SpglibTestData/tetragonal/POSCAR-131-2" : double3x3([4.9262976820, 0.0000000000, 0.0000000000],[0.0000000000, 4.9262976820, 0.0000000000], [0.0000000000, 0.0000000000, 8.2849961016]),
      "SpglibTestData/tetragonal/POSCAR-132" : double3x3([0.0000000000, 0.0000000000, 6.0519971523],[6.1659970986, 0.0000000000, 0.0000000000], [0.0000000000, 6.1659970986, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-132-2" : double3x3([5.8519972464, 0.0000000000, 0.0000000000],[0.0000000000, 5.8519972464, 0.0000000000], [0.0000000000, 0.0000000000, 14.2339933023]),
      "SpglibTestData/tetragonal/POSCAR-133" : double3x3([0.0000000000, 0.0000000000, 4.6629978059],[9.3809955858, 0.0000000000, 0.0000000000], [0.0000000000, 9.3809955858, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-133-2" : double3x3([11.7889944528, 0.0000000000, 0.0000000000],[0.0000000000, 11.7889944528, 0.0000000000], [0.0000000000, 0.0000000000, 23.6349888787]),
      "SpglibTestData/tetragonal/POSCAR-134" : double3x3([8.4269960347, 0.0000000000, 0.0000000000],[0.0000000000, 8.4269960347, 0.0000000000], [0.0000000000, 0.0000000000, 14.4919931809]),
      "SpglibTestData/tetragonal/POSCAR-134-2" : double3x3([-1.5422492743, -1.5422492743, -1.5532492691],[-1.5422492743, 1.5422492743, 1.5532492691], [1.5422492743, 1.5422492743, -1.5532492691]),
      "SpglibTestData/tetragonal/POSCAR-135" : double3x3([0.0000000000, 0.0000000000, 5.9129972177],[8.5899959580, 0.0000000000, 0.0000000000], [0.0000000000, 8.5899959580, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-135-2" : double3x3([0.0000000000, 0.0000000000, 5.9419972040],[8.5269959877, 0.0000000000, 0.0000000000], [0.0000000000, 8.5269959877, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-136" : double3x3([0.0000000000, 0.0000000000, 2.8729986481],[4.3982979304, 0.0000000000, 0.0000000000], [0.0000000000, 4.3982979304, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-136-2" : double3x3([0.0000000000, 0.0000000000, 2.9532986103],[4.5844978428, 0.0000000000, 0.0000000000], [0.0000000000, 4.5844978428, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-136-3" : double3x3([0.0000000000, 0.0000000000, 2.6888359272],[4.2266540200, 0.0000000000, 0.0000000000], [0.0000000000, 4.2266540200, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-136-4" : double3x3([4.6685978032, 0.0000000000, 0.0000000000],[0.0000000000, 4.6685978032, 0.0000000000], [0.0000000000, 0.0000000000, 5.2149975461]),
      "SpglibTestData/tetragonal/POSCAR-136-5" : double3x3([0.0000000000, 0.0000000000, 4.1099980661],[6.7539968220, 0.0000000000, 0.0000000000], [0.0000000000, 6.7539968220, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-137" : double3x3([0.0000000000, 0.0000000000, 5.4499974355],[8.0899961933, 0.0000000000, 0.0000000000], [0.0000000000, 8.0899961933, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-137-2" : double3x3([3.6399982872, 0.0000000000, 0.0000000000],[0.0000000000, 3.6399982872, 0.0000000000], [0.0000000000, 0.0000000000, 5.2699975202]),
      "SpglibTestData/tetragonal/POSCAR-137-3" : double3x3([2.2423146613, 0.0000000000, 0.0000000000],[0.0000000000, 2.2423146613, 0.0000000000], [0.0000000000, 0.0000000000, 6.8505089202]),
      "SpglibTestData/tetragonal/POSCAR-138" : double3x3([0.0000000000, 0.0000000000, 7.6781963871],[8.4335960316, 0.0000000000, 0.0000000000], [0.0000000000, 8.4335960316, 0.0000000000]),
      "SpglibTestData/tetragonal/POSCAR-138-2" : double3x3([4.3499979531, 0.0000000000, 0.0000000000],[0.0000000000, 4.3499979531, 0.0000000000], [0.0000000000, 0.0000000000, 13.7299935395]),
      "SpglibTestData/tetragonal/POSCAR-139" : double3x3([-11.9399943817, -0.0000000000, -0.0000000000],[-0.0000000000, -11.9399943817, -0.0000000000], [5.9699971909, 5.9699971909, 8.6999959063]),
      "SpglibTestData/tetragonal/POSCAR-139-2" : double3x3([-4.1699980378, -0.0000000000, -0.0000000000],[-0.0000000000, -4.1699980378, -0.0000000000], [2.0849990189, 2.0849990189, 5.4399974403]),
      "SpglibTestData/tetragonal/POSCAR-140" : double3x3([-11.0759947883, -0.0000000000, -0.0000000000],[-0.0000000000, -11.0759947883, -0.0000000000], [5.5379973941, 5.5379973941, 18.4664913107]),
      "SpglibTestData/tetragonal/POSCAR-140-2" : double3x3([0.0000000000, -0.0000000000, -5.7269973052],[5.5059974092, 5.5059974092, 2.8634986526], [5.5059974092, -5.5059974092, -2.8634986526]),
      "SpglibTestData/tetragonal/POSCAR-141" : double3x3([3.5885983114, 3.5885983114, 3.1644485110],[3.5885983114, -3.5885983114, -3.1644485110], [-3.5885983114, 3.5885983114, -3.1644485110]),
      "SpglibTestData/tetragonal/POSCAR-141-2" : double3x3([-6.9012967527, -0.0000000000, -0.0000000000],[-0.0000000000, -6.9012967527, -0.0000000000], [3.4506483763, 3.4506483763, 9.9876953004]),
      "SpglibTestData/tetragonal/POSCAR-142" : double3x3([-10.3299951393, -0.0000000000, -0.0000000000],[-0.0000000000, -10.3299951393, -0.0000000000], [5.1649975697, 5.1649975697, 10.1899952052]),
      "SpglibTestData/tetragonal/POSCAR-142-2" : double3x3([-12.2839942199, -0.0000000000, -0.0000000000],[-0.0000000000, -12.2839942199, -0.0000000000], [6.1419971099, 6.1419971099, 11.7909944518]),
      "SpglibTestData/tetragonal/POSCAR-142-3" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          var histogram:[Int:Int] = [:]
                    
          for atom in reader.atoms
          {
            histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
          }
          
          // Find least occurent element
          let minType: Int = histogram.min{a, b in a.value < b.value}!.key
          
          //let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.filter{$0.type == minType}
          let reducedAtoms = reader.atoms
          
          // search for a primitive cell based on the positions of the atoms
          let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: reader.atoms, unitCell: unitCell, symmetryPrecision: precision)
         
          let DelaunayUnitCell: double3x3? = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: precision)
          
          XCTAssertNotNil(DelaunayUnitCell, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = DelaunayUnitCell
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
  
  func testFindTrigonalSpaceGroup()
  {
    let testData: [String: double3x3] =
    [
      "SpglibTestData/trigonal/POSCAR-143" : double3x3([0.0000000000, 0.0000000000, 6.7835968080],[7.2487965891, 0.0000000000, 0.0000000000], [-3.6243982946, 6.2776419931, 0.0000000000]),
      "SpglibTestData/trigonal/POSCAR-143-2" : double3x3([0.0000000000, 0.0000000000, 7.3612965362],[7.9541862572, 0.0000000000, 0.0000000000], [-3.9770931286, 6.8885273652, 0.0000000000]),
      "SpglibTestData/trigonal/POSCAR-144" : double3x3([6.8672967686, 0.0000000000, 0.0000000000],[-3.4336483843, 5.9472534570, 0.0000000000], [0.0000000000, 0.0000000000, 17.0619919716]),
      "SpglibTestData/trigonal/POSCAR-144-2" : double3x3([4.3367979594, 0.0000000000, 0.0000000000],[-2.1683989797, 3.7557772039, 0.0000000000], [0.0000000000, 0.0000000000, 8.3396960758]),
      "SpglibTestData/trigonal/POSCAR-145" : double3x3([12.6919940279, 0.0000000000, 0.0000000000],[-6.3459970139, 10.9915892528, 0.0000000000], [0.0000000000, 0.0000000000, 19.1859909722]),
      "SpglibTestData/trigonal/POSCAR-145-2" : double3x3([0.0000000000, 0.0000000000, 7.4729964836],[10.5019950584, 0.0000000000, 0.0000000000], [-5.2509975292, 9.0949945110, 0.0000000000]),
      "SpglibTestData/trigonal/POSCAR-146" : double3x3([5.4184974504, 3.1283709616, 2.7189987206],[-5.4184974504, 3.1283709616, 2.7189987206], [-0.0000000000, -6.2567419231, 2.7189987206]),
      "SpglibTestData/trigonal/POSCAR-146-2" : double3x3([-2.9999985884, 1.7320499926, 4.7766644190],[-2.9999985884, -1.7320499926, -4.7766644190], [0.0000000000, -3.4640999851, 4.7766644190]),
      "SpglibTestData/trigonal/POSCAR-147" : double3x3([0.0000000000, 0.0000000000, 8.8887958174],[16.9905920052, 0.0000000000, 0.0000000000], [-8.4952960026, 14.7142843019, 0.0000000000]),
      "SpglibTestData/trigonal/POSCAR-147-2" : double3x3([0.0000000000, 0.0000000000, 7.2224966015],[9.3961955787, 0.0000000000, 0.0000000000], [-4.6980977893, 8.1373440701, 0.0000000000]),
      "SpglibTestData/trigonal/POSCAR-148" : double3x3([-3.5533483280, 2.0515266137, 5.6955639867],[-3.5533483280, -2.0515266137, -5.6955639867], [-0.0000000000, -4.1030532274, 5.6955639867]),
      "SpglibTestData/trigonal/POSCAR-148-2" : double3x3([-0.0000000000, 0.0000000000, -12.1339942904],[-10.4869950654, 6.0546694240, 4.0446647635], [10.4869950654, 6.0546694240, 4.0446647635]),
      "SpglibTestData/trigonal/POSCAR-149" : double3x3([5.0219976369, 0.0000000000, 0.0000000000],[-2.5109988185, 4.3491775313, 0.0000000000], [0.0000000000, 0.0000000000, 6.3759969998]),
      "SpglibTestData/trigonal/POSCAR-149-2" : double3x3([7.1509966352, 0.0000000000, 0.0000000000],[-3.5754983176, 6.1929447484, 0.0000000000], [0.0000000000, 0.0000000000, 8.1757961529]),
      "SpglibTestData/trigonal/POSCAR-150" : double3x3([0.0000000000, 0.0000000000, 4.9839976548],[9.0699957322, 0.0000000000, 0.0000000000], [-4.5349978661, 7.8548467163, 0.0000000000]),
      "SpglibTestData/trigonal/POSCAR-150-2" : double3x3([0.0000000000, 0.0000000000, 4.7379977706],[8.6379959355, 0.0000000000, 0.0000000000], [-4.3189979677, 7.4807239179, 0.0000000000]),
      "SpglibTestData/trigonal/POSCAR-151" : double3x3([5.9599971956, 0.0000000000, 0.0000000000],[-2.9799985978, 5.1615089778, 0.0000000000], [0.0000000000, 0.0000000000, 17.1999919067]),
      "SpglibTestData/trigonal/POSCAR-151-2" : double3x3([5.0339976313, 0.0000000000, 0.0000000000],[-2.5169988156, 4.3595698313, 0.0000000000], [0.0000000000, 0.0000000000, 14.1409933461]),
      "SpglibTestData/trigonal/POSCAR-152" : double3x3([9.2039956691, 0.0000000000, 0.0000000000],[-4.6019978346, 7.9708940658, 0.0000000000], [0.0000000000, 0.0000000000, 24.8179883221]),
      "SpglibTestData/trigonal/POSCAR-152-2" : double3x3([5.0359976304, 0.0000000000, 0.0000000000],[-2.5179988152, 4.3613018813, 0.0000000000], [0.0000000000, 0.0000000000, 11.2549947041]),
      "SpglibTestData/trigonal/POSCAR-153" : double3x3([6.0199971673, 0.0000000000, 0.0000000000],[-3.0099985837, 5.2134704776, 0.0000000000], [0.0000000000, 0.0000000000, 17.2999918596]),
      "SpglibTestData/trigonal/POSCAR-154" : double3x3([4.9133976880, 0.0000000000, 0.0000000000],[-2.4566988440, 4.2551272167, 0.0000000000], [0.0000000000, 0.0000000000, 5.4051974566]),
      "SpglibTestData/trigonal/POSCAR-154-2" : double3x3([0.0000000000, 0.0000000000, 8.3999960474],[13.0399938641, 0.0000000000, 0.0000000000], [-6.5199969321, 11.2929659515, 0.0000000000]),
      "SpglibTestData/trigonal/POSCAR-154-3" : double3x3([3.5185386123, -2.0314292150, 0.0000000000],[0.0000000000, 4.0628584300, 0.0000000000], [0.0000000000, 0.0000000000, 4.6155767045]),
      "SpglibTestData/trigonal/POSCAR-155" : double3x3([4.6707978022, 2.6966863684, 2.4351655208],[-4.6707978022, 2.6966863684, 2.4351655208], [-0.0000000000, -5.3933727369, 2.4351655208]),
      "SpglibTestData/trigonal/POSCAR-155-2" : double3x3([-4.5614978536, 2.6335820137, 5.6609973363],[-4.5614978536, -2.6335820137, -5.6609973363], [-0.0000000000, -5.2671640274, 5.6609973363]),
      "SpglibTestData/trigonal/POSCAR-156" : double3x3([3.7332982433, 0.0000000000, 0.0000000000],[-1.8666491217, 3.2331311186, 0.0000000000], [0.0000000000, 0.0000000000, 6.0979971306]),
      "SpglibTestData/trigonal/POSCAR-156-2" : double3x3([3.9149981578, 0.0000000000, 0.0000000000],[-1.9574990789, 3.3904878604, 0.0000000000], [0.0000000000, 0.0000000000, 12.7249940124]),
      "SpglibTestData/trigonal/POSCAR-157" : double3x3([12.1969942608, 0.0000000000, 0.0000000000],[-6.0984971304, 10.5629068797, 0.0000000000], [0.0000000000, 0.0000000000, 19.3589908908]),
      "SpglibTestData/trigonal/POSCAR-157-2" : double3x3([0.0000000000, 0.0000000000, 3.9659981338],[8.7529958813, 0.0000000000, 0.0000000000], [-4.3764979407, 7.5803167925, 0.0000000000]),
      "SpglibTestData/trigonal/POSCAR-158" : double3x3([0.0000000000, 0.0000000000, 5.6579973377],[6.1199971203, 0.0000000000, 0.0000000000], [-3.0599985601, 5.3000729773, 0.0000000000]),
      "SpglibTestData/trigonal/POSCAR-158-2" : double3x3([0.0000000000, 0.0000000000, 9.2389956527],[12.8739939422, 0.0000000000, 0.0000000000], [-6.4369969711, 11.1492058022, 0.0000000000]),
      "SpglibTestData/trigonal/POSCAR-159" : double3x3([10.1999952005, 0.0000000000, 0.0000000000],[-5.0999976002, 8.8334549621, 0.0000000000], [0.0000000000, 0.0000000000, 30.3509857186]),
      "SpglibTestData/trigonal/POSCAR-159-2" : double3x3([0.0000000000, 0.0000000000, 5.3679974741],[10.5629950297, 0.0000000000, 0.0000000000], [-5.2814975148, 9.1478220357, 0.0000000000]),
      "SpglibTestData/trigonal/POSCAR-160" : double3x3([7.8050963274, 0.0000000000, 0.0000000000],[-2.5690227481, 7.3701866190, 0.0000000000], [-2.5690227481, -3.6161021795, 6.4221068059]),
      "SpglibTestData/trigonal/POSCAR-160-2" : double3x3([-2.7434987091, 1.5839597182, 3.0519985639],[-2.7434987091, -1.5839597182, -3.0519985639], [-0.0000000000, -3.1679194364, 3.0519985639]),
      "SpglibTestData/trigonal/POSCAR-161" : double3x3([5.2189975442, -9.0395689112, -0.0000000000],[5.2189975442, 9.0395689112, 0.0000000000], [-5.2189975442, 3.0131896371, 12.3833275065]),
      "SpglibTestData/trigonal/POSCAR-161-2" : double3x3([2.5799987860, -4.4686889808, -0.0000000000],[2.5799987860, 4.4686889808, -0.0000000000], [-2.5799987860, 1.4895629936, 5.5266640661]),
      "SpglibTestData/trigonal/POSCAR-162" : double3x3([5.4499974355, 0.0000000000, 0.0000000000],[-2.7249987178, 4.7198362297, 0.0000000000], [0.0000000000, 0.0000000000, 8.1009961881]),
      "SpglibTestData/trigonal/POSCAR-162-2" : double3x3([0.0000000000, 0.0000000000, 4.6219978252],[4.9899976520, 0.0000000000, 0.0000000000], [-2.4949988260, 4.3214647315, 0.0000000000]),
      "SpglibTestData/trigonal/POSCAR-163" : double3x3([5.8899972285, 0.0000000000, 0.0000000000],[-2.9449986143, 5.1008872281, 0.0000000000], [0.0000000000, 0.0000000000, 9.5909954870]),
      "SpglibTestData/trigonal/POSCAR-163-2" : double3x3([5.3099975014, 0.0000000000, 0.0000000000],[-2.6549987507, 4.5985927303, 0.0000000000], [0.0000000000, 0.0000000000, 14.2499932948]),
      "SpglibTestData/trigonal/POSCAR-164" : double3x3([4.0469980957, 0.0000000000, 0.0000000000],[-2.0234990479, 3.5048031600, 0.0000000000], [0.0000000000, 0.0000000000, 5.3299974920]),
      "SpglibTestData/trigonal/POSCAR-164-2" : double3x3([0.0000000000, 0.0000000000, 5.0859976068],[6.2489970596, 0.0000000000, 0.0000000000], [-3.1244985298, 5.4117902018, 0.0000000000]),
      "SpglibTestData/trigonal/POSCAR-165" : double3x3([7.1849966192, 0.0000000000, 0.0000000000],[-3.5924983096, 6.2223895983, 0.0000000000], [0.0000000000, 0.0000000000, 7.3509965410]),
      "SpglibTestData/trigonal/POSCAR-165-2" : double3x3([0.0000000000, 0.0000000000, 10.1399952287],[12.1899942641, 0.0000000000, 0.0000000000], [-6.0949971320, 10.5568447047, 0.0000000000]),
      "SpglibTestData/trigonal/POSCAR-166" : double3x3([3.1214985312, -5.4065940518, -0.0000000000],[3.1214985312, 5.4065940518, -0.0000000000], [-3.1214985312, 1.8021980173, 9.9999952946]),
      "SpglibTestData/trigonal/POSCAR-166-2" : double3x3([-2.7124987237, 1.5660618683, 3.2786651239],[-2.7124987237, -1.5660618683, -3.2786651239], [-0.0000000000, -3.1321237366, 3.2786651239]),
      "SpglibTestData/trigonal/POSCAR-167" : double3x3([5.7549972920, -9.9679477072, -0.0000000000],[5.7549972920, 9.9679477072, -0.0000000000], [-5.7549972920, 3.3226492357, 20.1899904998]),
      "SpglibTestData/trigonal/POSCAR-167-2" : double3x3([5.0114976419, -8.6801685377, -0.0000000000],[5.0114976419, 8.6801685377, -0.0000000000], [-5.0114976419, 2.8933895126, 8.4903293383]),
      "SpglibTestData/trigonal/POSCAR-167-3" : double3x3([2.4745988356, -4.2861309116, -0.0000000000],[2.4745988356, 4.2861309116, -0.0000000000], [-2.4745988356, 1.4287103039, 4.6659978045])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          var histogram:[Int:Int] = [:]
                    
          for atom in reader.atoms
          {
            histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
          }
          
          // Find least occurent element
          let minType: Int = histogram.min{a, b in a.value < b.value}!.key
          
          //let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.filter{$0.type == minType}
          let reducedAtoms = reader.atoms
          
          // search for a primitive cell based on the positions of the atoms
          let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: reader.atoms, unitCell: unitCell, symmetryPrecision: precision)
         
          let DelaunayUnitCell: double3x3? = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: precision)
          
          XCTAssertNotNil(DelaunayUnitCell, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = DelaunayUnitCell
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
  
  func testFindHexagonalSpaceGroup()
  {
    let testData: [String: double3x3] =
    [
      "SpglibTestData/hexagonal/POSCAR-168" : double3x3([0.0000000000, 0.0000000000, 3.8919981687],[15.9359925014, 0.0000000000, 0.0000000000], [-7.9679962507, 13.8009743408, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-169" : double3x3([7.1099966544, 0.0000000000, 0.0000000000],[-3.5549983272, 6.1574377236, 0.0000000000], [0.0000000000, 0.0000000000, 19.3399908997]),
      "SpglibTestData/hexagonal/POSCAR-169-2" : double3x3([9.7089954315, 0.0000000000, 0.0000000000],[-4.8544977158, 8.4082366889, 0.0000000000], [0.0000000000, 0.0000000000, 19.3429908983]),
      "SpglibTestData/hexagonal/POSCAR-170" : double3x3([7.1099966544, 0.0000000000, 0.0000000000],[-3.5549983272, 6.1574377236, 0.0000000000], [0.0000000000, 0.0000000000, 19.2999909185]),
      "SpglibTestData/hexagonal/POSCAR-170-2" : double3x3([10.5125950534, 0.0000000000, 0.0000000000],[-5.2562975267, 9.1041743759, 0.0000000000], [0.0000000000, 0.0000000000, 14.9375929712]),
      "SpglibTestData/hexagonal/POSCAR-171" : double3x3([0.0000000000, 0.0000000000, 13.0359938660],[17.3899918173, 0.0000000000, 0.0000000000], [-8.6949959086, 15.0601746854, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-171-2" : double3x3([6.3199970262, 0.0000000000, 0.0000000000],[-3.1599985131, 5.4732779765, 0.0000000000], [0.0000000000, 0.0000000000, 19.2899909232]),
      "SpglibTestData/hexagonal/POSCAR-172" : double3x3([6.1979970836, 0.0000000000, 0.0000000000],[-3.0989985418, 5.3676229270, 0.0000000000], [0.0000000000, 0.0000000000, 18.7269911882]),
      "SpglibTestData/hexagonal/POSCAR-173" : double3x3([7.1329966436, 0.0000000000, 0.0000000000],[-3.5664983218, 6.1773562985, 0.0000000000], [0.0000000000, 0.0000000000, 7.4139965114]),
      "SpglibTestData/hexagonal/POSCAR-173-2" : double3x3([0.0000000000, 0.0000000000, 5.2239975419],[9.2249956593, 0.0000000000, 0.0000000000], [-4.6124978296, 7.9890805907, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-174" : double3x3([0.0000000000, 0.0000000000, 3.9874981237],[10.2742951655, 0.0000000000, 0.0000000000], [-5.1371475828, 8.8978006193, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-174-2" : double3x3([0.0000000000, 0.0000000000, 9.8799953510],[12.3199942029, 0.0000000000, 0.0000000000], [-6.1599971015, 10.6694279542, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-175" : double3x3([0.0000000000, 0.0000000000, 9.1380957001],[12.6520940467, 0.0000000000, 0.0000000000], [-6.3260470233, 10.9570348555, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-175-2" : double3x3([0.0000000000, 0.0000000000, 3.0894985463],[5.4589974313, 0.0000000000, 0.0000000000], [-2.7294987157, 4.7276304547, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-176" : double3x3([0.0000000000, 0.0000000000, 3.7429982388],[6.4179969801, 0.0000000000, 0.0000000000], [-3.2089984900, 5.5581484261, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-176-2" : double3x3([0.0000000000, 0.0000000000, 9.9499953181],[11.6699945088, 0.0000000000, 0.0000000000], [-5.8349972544, 10.1065117066, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-177" : double3x3([6.3412970162, 0.0000000000, 0.0000000000],[-3.1706485081, 5.4917243089, 0.0000000000], [0.0000000000, 0.0000000000, 6.4621969593]),
      "SpglibTestData/hexagonal/POSCAR-179" : double3x3([0.0000000000, 0.0000000000, 6.9071967499],[7.2212966021, 0.0000000000, 0.0000000000], [-3.6106483010, 6.2538263057, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-179-2" : double3x3([10.4119951007, 0.0000000000, 0.0000000000],[-5.2059975504, 9.0170522613, 0.0000000000], [0.0000000000, 0.0000000000, 15.1839928553]),
      "SpglibTestData/hexagonal/POSCAR-180" : double3x3([4.8189977325, 0.0000000000, 0.0000000000],[-2.4094988662, 4.1733744571, 0.0000000000], [0.0000000000, 0.0000000000, 6.5919968982]),
      "SpglibTestData/hexagonal/POSCAR-180-2" : double3x3([4.8999976943, 0.0000000000, 0.0000000000],[-2.4499988472, 4.2435224818, 0.0000000000], [0.0000000000, 0.0000000000, 5.3799974685]),
      "SpglibTestData/hexagonal/POSCAR-181" : double3x3([4.4282979163, 0.0000000000, 0.0000000000],[-2.2141489581, 3.8350184910, 0.0000000000], [0.0000000000, 0.0000000000, 6.3679970036]),
      "SpglibTestData/hexagonal/POSCAR-181-2" : double3x3([10.4817950679, 0.0000000000, 0.0000000000],[-5.2408975339, 9.0775008060, 0.0000000000], [0.0000000000, 0.0000000000, 11.1749947417]),
      "SpglibTestData/hexagonal/POSCAR-182" : double3x3([5.3099975014, 0.0000000000, 0.0000000000],[-2.6549987507, 4.5985927303, 0.0000000000], [0.0000000000, 0.0000000000, 14.2499932948]),
      "SpglibTestData/hexagonal/POSCAR-182-2" : double3x3([5.4579974318, 0.0000000000, 0.0000000000],[-2.7289987159, 4.7267644297, 0.0000000000], [0.0000000000, 0.0000000000, 9.0159957576]),
      "SpglibTestData/hexagonal/POSCAR-183" : double3x3([0.0000000000, 0.0000000000, 10.2999951534],[19.4999908244, 0.0000000000, 0.0000000000], [-9.7499954122, 16.8874874275, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-183-2" : double3x3([3.3959984020, 0.0000000000, 0.0000000000],[-1.6979992010, 2.9410208874, 0.0000000000], [0.0000000000, 0.0000000000, 5.0919976040]),
      "SpglibTestData/hexagonal/POSCAR-184" : double3x3([0.0000000000, 0.0000000000, 8.4525960227],[13.7179935451, 0.0000000000, 0.0000000000], [-6.8589967726, 11.8801308990, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-184-2" : double3x3([0.0000000000, 0.0000000000, 8.5029959990],[13.8019935056, 0.0000000000, 0.0000000000], [-6.9009967528, 11.9528769987, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-185" : double3x3([9.8849953487, 0.0000000000, 0.0000000000],[-4.9424976743, 8.5606570883, 0.0000000000], [0.0000000000, 0.0000000000, 10.8049949158]),
      "SpglibTestData/hexagonal/POSCAR-185-2" : double3x3([6.2599970544, 0.0000000000, 0.0000000000],[-3.1299985272, 5.4213164767, 0.0000000000], [0.0000000000, 0.0000000000, 12.2489942363]),
      "SpglibTestData/hexagonal/POSCAR-186" : double3x3([0.0000000000, 0.0000000000, 7.6399964051],[9.9799953040, 0.0000000000, 0.0000000000], [-4.9899976520, 8.6429294629, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-186-2" : double3x3([8.0999961886, 0.0000000000, 0.0000000000],[-4.0499980943, 7.0148024699, 0.0000000000], [0.0000000000, 0.0000000000, 13.3399937230]),
      "SpglibTestData/hexagonal/POSCAR-187" : double3x3([0.0000000000, 0.0000000000, 2.8365986653],[2.9064986324, 0.0000000000, 0.0000000000], [-1.4532493162, 2.5171016517, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-187-2" : double3x3([5.4479974365, 0.0000000000, 0.0000000000],[-2.7239987182, 4.7181041798, 0.0000000000], [0.0000000000, 0.0000000000, 8.0909961928]),
      "SpglibTestData/hexagonal/POSCAR-188" : double3x3([0.0000000000, 0.0000000000, 5.6579973377],[6.1199971203, 0.0000000000, 0.0000000000], [-3.0599985601, 5.3000729773, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-188-2" : double3x3([9.2179956625, 0.0000000000, 0.0000000000],[-4.6089978313, 7.9830184157, 0.0000000000], [0.0000000000, 0.0000000000, 18.0419915105]),
      "SpglibTestData/hexagonal/POSCAR-189" : double3x3([0.0000000000, 0.0000000000, 6.1369971123],[8.1539961632, 0.0000000000, 0.0000000000], [-4.0769980816, 7.0615678197, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-189-2" : double3x3([0.0000000000, 0.0000000000, 3.8569981851],[9.6499954593, 0.0000000000, 0.0000000000], [-4.8249977296, 8.3571412141, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-190" : double3x3([4.5960978373, 0.0000000000, 0.0000000000],[-2.2980489187, 3.9803374854, 0.0000000000], [0.0000000000, 0.0000000000, 8.9299957981]),
      "SpglibTestData/hexagonal/POSCAR-190-2" : double3x3([10.5609950306, 0.0000000000, 0.0000000000],[-5.2804975153, 9.1460899857, 0.0000000000], [0.0000000000, 0.0000000000, 13.5219936373]),
      "SpglibTestData/hexagonal/POSCAR-191" : double3x3([0.0000000000, 0.0000000000, 3.8439981912],[3.9599981367, 0.0000000000, 0.0000000000], [-1.9799990683, 3.4294589853, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-191-2" : double3x3([0.0000000000, 0.0000000000, 5.8529972459],[11.2569947031, 0.0000000000, 0.0000000000], [-5.6284973516, 9.7488433832, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-192" : double3x3([10.4569950795, 0.0000000000, 0.0000000000],[-5.2284975398, 9.0560233861, 0.0000000000], [0.0000000000, 0.0000000000, 14.2379933004]),
      "SpglibTestData/hexagonal/POSCAR-192-2" : double3x3([0.0000000000, 0.0000000000, 9.3407956048],[9.7682954036, 0.0000000000, 0.0000000000], [-4.8841477018, 8.4595919712, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-193" : double3x3([0.0000000000, 0.0000000000, 6.0839971372],[8.4899960051, 0.0000000000, 0.0000000000], [-4.2449980026, 7.3525522184, 0.0000000000]),
      "SpglibTestData/hexagonal/POSCAR-193-2" : double3x3([9.7489954127, 0.0000000000, 0.0000000000],[-4.8744977063, 8.4428776888, 0.0000000000], [0.0000000000, 0.0000000000, 16.4699922502]),
      "SpglibTestData/hexagonal/POSCAR-194" : double3x3([3.5869983122, 0.0000000000, 0.0000000000],[-1.7934991561, 3.1064316617, 0.0000000000], [0.0000000000, 0.0000000000, 15.4919927104]),
      "SpglibTestData/hexagonal/POSCAR-194-2" : double3x3([3.4699983672, 0.0000000000, 0.0000000000],[-1.7349991836, 3.0051067371, 0.0000000000], [0.0000000000, 0.0000000000, 28.4499866131])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          var histogram:[Int:Int] = [:]
                    
          for atom in reader.atoms
          {
            histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
          }
          
          // Find least occurent element
          let minType: Int = histogram.min{a, b in a.value < b.value}!.key
          
          //let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.filter{$0.type == minType}
          let reducedAtoms = reader.atoms
          
          // search for a primitive cell based on the positions of the atoms
          let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: reader.atoms, unitCell: unitCell, symmetryPrecision: precision)
         
          let DelaunayUnitCell: double3x3? = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: precision)
          
          XCTAssertNotNil(DelaunayUnitCell, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = DelaunayUnitCell
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
  
  func testFindCubicSpaceGroup()
  {
    let testData: [String: double3x3] =
    [
      "SpglibTestData/cubic/poscar-195" : double3x3([10.3499951299, 0.0000000000, 0.0000000000],[0.0000000000, 10.3499951299, 0.0000000000], [0.0000000000, 0.0000000000, 10.3499951299]),
      "SpglibTestData/cubic/poscar-195-2" : double3x3([7.2659965810, 0.0000000000, 0.0000000000],[0.0000000000, 7.2659965810, 0.0000000000], [0.0000000000, 0.0000000000, 7.2659965810]),
      "SpglibTestData/cubic/poscar-196" : double3x3([6.0769971405, -6.0769971405, 0.0000000000],[-6.0769971405, -0.0000000000, -6.0769971405], [6.0769971405, 6.0769971405, 0.0000000000]),
      "SpglibTestData/cubic/poscar-196-2" : double3x3([9.3749955887, -9.3749955887, 0.0000000000],[-9.3749955887, -0.0000000000, -9.3749955887], [9.3749955887, 9.3749955887, 0.0000000000]),
      "SpglibTestData/cubic/poscar-197" : double3x3([5.0726976131, 5.0726976131, 5.0726976131],[5.0726976131, -5.0726976131, -5.0726976131], [-5.0726976131, 5.0726976131, -5.0726976131]),
      "SpglibTestData/cubic/poscar-197-2" : double3x3([5.1249975885, 5.1249975885, 5.1249975885],[5.1249975885, -5.1249975885, -5.1249975885], [-5.1249975885, 5.1249975885, -5.1249975885]),
      "SpglibTestData/cubic/poscar-198" : double3x3([7.8399963110, 0.0000000000, 0.0000000000],[0.0000000000, 7.8399963110, 0.0000000000], [0.0000000000, 0.0000000000, 7.8399963110]),
      "SpglibTestData/cubic/poscar-198-2" : double3x3([12.7529939992, 0.0000000000, 0.0000000000],[0.0000000000, 12.7529939992, 0.0000000000], [0.0000000000, 0.0000000000, 12.7529939992]),
      "SpglibTestData/cubic/poscar-199" : double3x3([5.4649974285, 5.4649974285, 5.4649974285],[5.4649974285, -5.4649974285, -5.4649974285], [-5.4649974285, 5.4649974285, -5.4649974285]),
      "SpglibTestData/cubic/poscar-199-2" : double3x3([4.2094980193, 4.2094980193, 4.2094980193],[4.2094980193, -4.2094980193, -4.2094980193], [-4.2094980193, 4.2094980193, -4.2094980193]),
      "SpglibTestData/cubic/poscar-200" : double3x3([7.4869964771, 0.0000000000, 0.0000000000],[0.0000000000, 7.4869964771, 0.0000000000], [0.0000000000, 0.0000000000, 7.4869964771]),
      "SpglibTestData/cubic/poscar-200-2" : double3x3([5.4499974355, 0.0000000000, 0.0000000000],[0.0000000000, 5.4499974355, 0.0000000000], [0.0000000000, 0.0000000000, 5.4499974355]),
      "SpglibTestData/cubic/poscar-205" : double3x3([5.6239973537, 0.0000000000, 0.0000000000],[0.0000000000, 5.6239973537, 0.0000000000], [0.0000000000, 0.0000000000, 5.6239973537]),
      "SpglibTestData/cubic/poscar-205-3" : double3x3([5.6239973537, 0.0000000000, 0.0000000000],[0.0000000000, 5.6239973537, 0.0000000000], [0.0000000000, 0.0000000000, 5.6239973537]),
      "SpglibTestData/cubic/poscar-206" : double3x3([5.4899974167, 5.4899974167, 5.4899974167],[5.4899974167, -5.4899974167, -5.4899974167], [-5.4899974167, 5.4899974167, -5.4899974167]),
      "SpglibTestData/cubic/poscar-206-2" : double3x3([5.5149974050, 5.5149974050, 5.5149974050],[5.5149974050, -5.5149974050, -5.5149974050], [-5.5149974050, 5.5149974050, -5.5149974050]),
      "SpglibTestData/cubic/poscar-207" : double3x3([4.3999979296, 0.0000000000, 0.0000000000],[0.0000000000, 4.3999979296, 0.0000000000], [0.0000000000, 0.0000000000, 4.3999979296]),
      "SpglibTestData/cubic/poscar-208" : double3x3([6.3099970309, 0.0000000000, 0.0000000000],[0.0000000000, 6.3099970309, 0.0000000000], [0.0000000000, 0.0000000000, 6.3099970309]),
      "SpglibTestData/cubic/poscar-208-2" : double3x3([0.0000000000, 0.0000000000, 2.3857488774],[-2.3857488774, 0.0000000000, -0.0000000000], [0.0000000000, -2.3857488774, 0.0000000000]),
      "SpglibTestData/cubic/poscar-209" : double3x3([3.7114982536, -3.7114982536, 0.0000000000],[-3.7114982536, -0.0000000000, -3.7114982536], [3.7114982536, 3.7114982536, 0.0000000000]),
      "SpglibTestData/cubic/poscar-210" : double3x3([9.9549953158, -9.9549953158, 0.0000000000],[-9.9549953158, -0.0000000000, -9.9549953158], [9.9549953158, 9.9549953158, 0.0000000000]),
      "SpglibTestData/cubic/poscar-210-2" : double3x3([7.8494963065, -7.8494963065, 0.0000000000],[-7.8494963065, -0.0000000000, -7.8494963065], [7.8494963065, 7.8494963065, 0.0000000000]),
      "SpglibTestData/cubic/poscar-211" : double3x3([4.8443977205, 4.8443977205, 4.8443977205],[4.8443977205, -4.8443977205, -4.8443977205], [-4.8443977205, 4.8443977205, -4.8443977205]),
      "SpglibTestData/cubic/poscar-212" : double3x3([6.7149968403, 0.0000000000, 0.0000000000],[0.0000000000, 6.7149968403, 0.0000000000], [0.0000000000, 0.0000000000, 6.7149968403]),
      "SpglibTestData/cubic/poscar-212-2" : double3x3([6.7149968403, 0.0000000000, 0.0000000000],[0.0000000000, 6.7149968403, 0.0000000000], [0.0000000000, 0.0000000000, 6.7149968403]),
      "SpglibTestData/cubic/poscar-213" : double3x3([10.2799951628, 0.0000000000, 0.0000000000],[0.0000000000, 10.2799951628, 0.0000000000], [0.0000000000, 0.0000000000, 10.2799951628]),
      "SpglibTestData/cubic/poscar-213-2" : double3x3([7.9359962658, 0.0000000000, 0.0000000000],[0.0000000000, 7.9359962658, 0.0000000000], [0.0000000000, 0.0000000000, 7.9359962658]),
      "SpglibTestData/cubic/poscar-214" : double3x3([10.8799948805, 10.8799948805, 10.8799948805],[10.8799948805, -10.8799948805, -10.8799948805], [-10.8799948805, 10.8799948805, -10.8799948805]),
      "SpglibTestData/cubic/poscar-214-2" : double3x3([6.1574971026, 6.1574971026, 6.1574971026],[6.1574971026, -6.1574971026, -6.1574971026], [-6.1574971026, 6.1574971026, -6.1574971026]),
      "SpglibTestData/cubic/poscar-215" : double3x3([5.3929974624, 0.0000000000, 0.0000000000],[0.0000000000, 5.3929974624, 0.0000000000], [0.0000000000, 0.0000000000, 5.3929974624]),
      "SpglibTestData/cubic/poscar-215-2" : double3x3([8.3199960851, 0.0000000000, 0.0000000000],[0.0000000000, 8.3199960851, 0.0000000000], [0.0000000000, 0.0000000000, 8.3199960851]),
      "SpglibTestData/cubic/poscar-216" : double3x3([0.0000000000, 3.5879983117, -3.5879983117],[-3.5879983117, -3.5879983117, -0.0000000000], [0.0000000000, 3.5879983117, 3.5879983117]),
      "SpglibTestData/cubic/poscar-216-2" : double3x3([3.7884982174, -3.7884982174, 0.0000000000],[-3.7884982174, -0.0000000000, -3.7884982174], [3.7884982174, 3.7884982174, 0.0000000000]),
      "SpglibTestData/cubic/poscar-217" : double3x3([6.3499970121, 6.3499970121, 6.3499970121],[6.3499970121, -6.3499970121, -6.3499970121], [-6.3499970121, 6.3499970121, -6.3499970121]),
      "SpglibTestData/cubic/poscar-217-2" : double3x3([5.0839976078, 5.0839976078, 5.0839976078],[5.0839976078, -5.0839976078, -5.0839976078], [-5.0839976078, 5.0839976078, -5.0839976078]),
      "SpglibTestData/cubic/poscar-218" : double3x3([8.2939960973, 0.0000000000, 0.0000000000],[0.0000000000, 8.2939960973, 0.0000000000], [0.0000000000, 0.0000000000, 8.2939960973]),
      "SpglibTestData/cubic/poscar-218-2" : double3x3([6.0259971645, 0.0000000000, 0.0000000000],[0.0000000000, 6.0259971645, 0.0000000000], [0.0000000000, 0.0000000000, 6.0259971645]),
      "SpglibTestData/cubic/poscar-219" : double3x3([8.6719959195, -8.6719959195, 0.0000000000],[-8.6719959195, -0.0000000000, -8.6719959195], [8.6719959195, 8.6719959195, 0.0000000000]),
      "SpglibTestData/cubic/poscar-219-2" : double3x3([6.0704971436, -6.0704971436, 0.0000000000],[-6.0704971436, -0.0000000000, -6.0704971436], [6.0704971436, 6.0704971436, 0.0000000000]),
      "SpglibTestData/cubic/poscar-220" : double3x3([4.9089976901, 4.9089976901, 4.9089976901],[4.9089976901, -4.9089976901, -4.9089976901], [-4.9089976901, 4.9089976901, -4.9089976901]),
      "SpglibTestData/cubic/poscar-220-2" : double3x3([4.2669979922, 4.2669979922, 4.2669979922],[4.2669979922, -4.2669979922, -4.2669979922], [-4.2669979922, 4.2669979922, -4.2669979922]),
      "SpglibTestData/cubic/poscar-221" : double3x3([9.6379954649, 0.0000000000, 0.0000000000],[0.0000000000, 9.6379954649, 0.0000000000], [0.0000000000, 0.0000000000, 9.6379954649]),
      "SpglibTestData/cubic/poscar-221-2" : double3x3([5.7949972732, 0.0000000000, 0.0000000000],[0.0000000000, 5.7949972732, 0.0000000000], [0.0000000000, 0.0000000000, 5.7949972732]),
      "SpglibTestData/cubic/poscar-222" : double3x3([10.9899948287, 0.0000000000, 0.0000000000],[0.0000000000, 10.9899948287, 0.0000000000], [0.0000000000, 0.0000000000, 10.9899948287]),
      "SpglibTestData/cubic/poscar-222-2" : double3x3([16.2559923509, 0.0000000000, 0.0000000000],[0.0000000000, 16.2559923509, 0.0000000000], [0.0000000000, 0.0000000000, 16.2559923509]),
      "SpglibTestData/cubic/poscar-223" : double3x3([6.6699968615, 0.0000000000, 0.0000000000],[0.0000000000, 6.6699968615, 0.0000000000], [0.0000000000, 0.0000000000, 6.6699968615]),
      "SpglibTestData/cubic/poscar-223-2" : double3x3([10.2999951534, 0.0000000000, 0.0000000000],[0.0000000000, 10.2999951534, 0.0000000000], [0.0000000000, 0.0000000000, 10.2999951534]),
      "SpglibTestData/cubic/poscar-224" : double3x3([4.9039976925, 0.0000000000, 0.0000000000],[0.0000000000, 4.9039976925, 0.0000000000], [0.0000000000, 0.0000000000, 4.9039976925]),
      "SpglibTestData/cubic/poscar-224-2" : double3x3([4.9039976925, 0.0000000000, 0.0000000000],[0.0000000000, 4.9039976925, 0.0000000000], [0.0000000000, 0.0000000000, 4.9039976925]),
      "SpglibTestData/cubic/poscar-225" : double3x3([4.9949976496, -4.9949976496, 0.0000000000],[-4.9949976496, -0.0000000000, -4.9949976496], [4.9949976496, 4.9949976496, 0.0000000000]),
      "SpglibTestData/cubic/poscar-225-2" : double3x3([4.0964980724, 0.0000000000, 0.0000000000],[0.0000000000, -4.0964980724, 0.0000000000], [0.0000000000, 0.0000000000, -4.0964980724]),
      "SpglibTestData/cubic/poscar-226" : double3x3([12.5299941041, -12.5299941041, 0.0000000000],[-12.5299941041, -0.0000000000, -12.5299941041], [12.5299941041, 12.5299941041, 0.0000000000]),
      "SpglibTestData/cubic/poscar-226-2" : double3x3([5.0229976365, -5.0229976365, 0.0000000000],[-5.0229976365, -0.0000000000, -5.0229976365], [5.0229976365, 5.0229976365, 0.0000000000]),
      "SpglibTestData/cubic/poscar-227" : double3x3([5.0649976167, -5.0649976167, 0.0000000000],[-5.0649976167, -0.0000000000, -5.0649976167], [5.0649976167, 5.0649976167, 0.0000000000]),
      "SpglibTestData/cubic/poscar-227-2" : double3x3([11.6274945288, -11.6274945288, 0.0000000000],[-11.6274945288, -0.0000000000, -11.6274945288], [11.6274945288, 11.6274945288, 0.0000000000]),
      "SpglibTestData/cubic/poscar-228" : double3x3([7.8524963051, -7.8524963051, 0.0000000000],[-7.8524963051, -0.0000000000, -7.8524963051], [7.8524963051, 7.8524963051, 0.0000000000]),
      "SpglibTestData/cubic/poscar-228-2" : double3x3([10.9049948687, -10.9049948687, 0.0000000000],[-10.9049948687, -0.0000000000, -10.9049948687], [10.9049948687, 10.9049948687, 0.0000000000]),
      "SpglibTestData/cubic/poscar-229" : double3x3([9.1349957016, 9.1349957016, 9.1349957016],[9.1349957016, -9.1349957016, -9.1349957016], [-9.1349957016, 9.1349957016, -9.1349957016]),
      "SpglibTestData/cubic/poscar-229-2" : double3x3([3.1104985364, 3.1104985364, 3.1104985364],[3.1104985364, -3.1104985364, -3.1104985364], [-3.1104985364, 3.1104985364, -3.1104985364]),
      "SpglibTestData/cubic/poscar-230" : double3x3([6.3009970351, 6.3009970351, 6.3009970351],[6.3009970351, -6.3009970351, -6.3009970351], [-6.3009970351, 6.3009970351, -6.3009970351]),
      "SpglibTestData/cubic/poscar-230-2" : double3x3([6.1879970883, 6.1879970883, 6.1879970883],[6.1879970883, -6.1879970883, -6.1879970883], [-6.1879970883, 6.1879970883, -6.1879970883]),
      "SpglibTestData/cubic/poscar-230-3" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/cubic/poscar-230-4" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          var histogram:[Int:Int] = [:]
                    
          for atom in reader.atoms
          {
            histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
          }
          
          // Find least occurent element
          let minType: Int = histogram.min{a, b in a.value < b.value}!.key
          
          //let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.filter{$0.type == minType}
          let reducedAtoms = reader.atoms
          
          // search for a primitive cell based on the positions of the atoms
          let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: reader.atoms, unitCell: unitCell, symmetryPrecision: precision)
         
          let DelaunayUnitCell: double3x3? = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: precision)
          
          XCTAssertNotNil(DelaunayUnitCell, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = DelaunayUnitCell
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
  
  func testFindVirtualSpaceGroup()
  {
    let testData: [String: double3x3] =
    [
      "SpglibTestData/virtual_structure/POSCAR-1-221-33" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-1-222-33" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-1-223-33" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-1-224-33" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-1-227-73" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-1-227-93" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-1-227-99" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-1-230-conv-56" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-1-230-prim-33" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-1-bcc-33" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-10-221-18" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-10-223-18" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-10-227-50" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-102-224-13" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-104-222-13" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-105-223-13" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-109-227-13" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-11-227-48" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-110-230-conv-15" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-110-230-prim-13" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-111-221-11" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-111-224-11" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-111-227-66" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-112-222-11" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-112-223-11" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-113-227-68" : double3x3([4.1200000000, -4.1200000000, -0.0000000000],[0.0000000000, 4.1200000000, 4.1200000000], [-4.1200000000, -4.1200000000, -0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-115-221-14" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-115-223-14" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-115-227-33" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-116-230-conv-34" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-117-230-conv-33" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-118-222-14" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-118-224-14" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-12-221-19" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-12-224-19" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-12-227-21" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-12-227-83" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-120-230-conv-16" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-120-230-prim-14" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-122-230-conv-13" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-122-230-prim-11" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-123-221-05" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-126-222-05" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-13-222-18" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-13-224-18" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-13-227-49" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-13-230-conv-44" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-131-223-05" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-134-224-05" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-14-227-47" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-14-227-51" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-14-230-conv-45" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-142-230-conv-05" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-142-230-prim-05" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-146-221-27" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-146-222-27" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-146-223-27" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-146-224-27" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-146-227-92" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-146-230-conv-36" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-146-230-conv-55" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-146-230-prim-27" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-146-bcc-27" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-148-221-15" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-148-222-15" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-148-223-15" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-148-224-15" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-148-227-70" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-148-230-conv-17" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-148-230-conv-37" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-148-230-prim-15" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-148-bcc-15" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-15-222-19" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-15-223-19" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-15-230-conv-21" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-15-230-conv-22" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-15-230-prim-18" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-15-230-prim-19" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-15-bcc-18" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-15-bcc-19" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-155-221-17" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-155-222-17" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-155-223-17" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-155-224-17" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-155-227-72" : double3x3([0.0000000000, 4.1200000000, -4.1200000000],[-4.1200000000, -4.1200000000, -0.0000000000], [0.0000000000, 4.1200000000, 4.1200000000]),
      "SpglibTestData/virtual_structure/POSCAR-155-230-conv-19" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-155-230-conv-38" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-155-230-prim-17" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-155-bcc-17" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-16-221-20" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-16-222-20" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-16-223-20" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-16-224-20" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-16-227-84" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-160-221-16" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-160-224-16" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-160-227-16" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-160-227-71" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-160-fcc" : double3x3([5.0000000000, -5.0000000000, 0.0000000000],[-5.0000000000, -0.0000000000, -5.0000000000], [5.0000000000, 5.0000000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-161-222-16" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-161-223-16" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-161-230-conv-18" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-161-230-prim-16" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-161-bcc-16" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-166-221-06" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-166-224-06" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-166-227-06" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-166-227-38" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-167-222-06" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-167-223-06" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-167-230-conv-06" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-167-230-prim-06" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-167-bcc-6" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-17-227-60" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-17-227-85" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-17-230-conv-46" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-18-227-86" : double3x3([4.1200000000, -4.1200000000, -0.0000000000],[0.0000000000, 4.1200000000, 4.1200000000], [-4.1200000000, -4.1200000000, -0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-19-227-59" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-19-227-89" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-19-230-conv-51" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-195-221-07" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-195-222-07" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-195-223-07" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-195-224-07" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-198-227-40" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-198-230-conv-20" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-199-230-conv-07" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-199-230-prim-07" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-2-221-28" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-2-222-28" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-2-223-28" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-2-224-28" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-2-227-41" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-2-227-74" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-2-227-94" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-2-230-conv-39" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-2-230-conv-57" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-2-230-prim-28" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-2-bcc-28" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-20-227-53" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-20-227-90" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-20-230-conv-53" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-200-221-02" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-200-223-02" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-201-222-02" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-201-224-02" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-205-230-conv-08" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-206-230-conv-02" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-206-230-prim-02" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-207-221-04" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-207-222-04" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-208-223-04" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-208-224-04" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-21-221-23" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-21-222-23" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-21-223-23" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-21-224-23" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-21-230-conv-49" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-212-227-19" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-213-230-conv-09" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-214-230-conv-04" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-214-230-prim-04" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-215-221-03" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-215-224-03" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-215-227-18" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-216-227-03" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-218-222-03" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-218-223-03" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-22-230-conv-26" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-22-230-prim-23" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-220-230-conv-03" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-220-230-prim-03" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-221-221-01" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-222-222-01" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-223-223-01" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-224-224-01" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-227-227-01" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-230-230-conv-01" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-230-230-conv-62" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-230-230-prim-01" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-24-230-conv-23" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-24-230-prim-20" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-25-221-21" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-25-223-21" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-25-227-54" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-26-227-64" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-27-230-conv-48" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-28-227-62" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-29-230-conv-52" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-3-221-29" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-3-222-29" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-3-223-29" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-3-224-29" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-3-227-82" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-3-227-95" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-3-230-conv-58" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-30-227-65" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-31-227-58" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-32-230-conv-47" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-33-227-63" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-34-222-21" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-34-224-21" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-35-221-22" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-35-224-22" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-35-227-87" : double3x3([-4.1200000000, -0.0000000000, 4.1200000000],[4.1200000000, 4.1200000000, 0.0000000000], [-4.1200000000, -0.0000000000, -4.1200000000]),
      "SpglibTestData/virtual_structure/POSCAR-37-222-22" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-37-223-22" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-38-221-26" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-39-224-26" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-4-227-77" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-4-227-81" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-4-227-96" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-4-230-conv-59" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-40-223-26" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-41-222-26" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-43-230-conv-25" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-43-230-conv-29" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-43-230-prim-22" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-43-230-prim-26" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-43-bcc-22" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-43-bcc-26" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-44-227-24" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-45-230-conv-24" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-45-230-prim-21" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-46-227-28" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-47-221-08" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-47-223-08" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-48-222-08" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-48-224-08" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-5-221-32" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-5-222-32" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-5-223-32" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-5-224-32" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-5-227-45" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-5-227-75" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-5-227-98" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-5-230-conv-40" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-5-230-conv-43" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-5-230-conv-61" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-5-230-prim-29" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-5-230-prim-32" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-5-bcc-29" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-5-bcc-32" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-51-227-29" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-53-227-32" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-54-230-conv-30" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-6-221-30" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-6-223-30" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-6-227-79" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-61-230-conv-31" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-62-227-31" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-65-221-09" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-66-223-09" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-67-224-09" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-68-222-09" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-7-222-30" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-7-224-30" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-7-227-78" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-7-227-80" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-7-230-conv-60" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-70-230-conv-11" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-70-230-prim-09" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-70-bcc-9" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-73-230-conv-10" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-73-230-prim-08" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-74-227-09" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-75-221-25" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-75-222-25" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-76-227-61" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-77-223-25" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-77-224-25" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-78-227-91" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-78-230-conv-54" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-8-221-31" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-8-224-31" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-8-227-44" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-8-227-97" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-80-230-conv-28" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-80-230-prim-25" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-81-221-24" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-81-222-24" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-81-223-24" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-81-224-24" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-81-227-88" : double3x3([-4.1200000000, -0.0000000000, 4.1200000000],[4.1200000000, 4.1200000000, 0.0000000000], [-4.1200000000, -0.0000000000, -4.1200000000]),
      "SpglibTestData/virtual_structure/POSCAR-81-230-conv-50" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-82-230-conv-27" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-82-230-prim-24" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-83-221-10" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-84-223-10" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-85-222-10" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-86-224-10" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-88-230-conv-12" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-88-230-prim-10" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-89-221-12" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-89-222-12" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-9-222-31" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-9-223-31" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-9-227-43" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-9-230-conv-41" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-9-230-conv-42" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-9-230-prim-30" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-9-230-prim-31" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-9-bcc-30" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-9-bcc-31" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-91-227-67" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-92-227-35" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-92-230-conv-35" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-93-223-12" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-93-224-12" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-95-227-36" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-95-230-conv-32" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-96-227-69" : double3x3([4.1200000000, -4.1200000000, 0.0000000000],[-4.1200000000, -0.0000000000, -4.1200000000], [4.1200000000, 4.1200000000, 0.0000000000]),
      "SpglibTestData/virtual_structure/POSCAR-98-230-conv-14" : double3x3([6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, -6.4032700000], [-6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-98-230-prim-12" : double3x3([-6.4032700000, 6.4032700000, 6.4032700000],[6.4032700000, -6.4032700000, 6.4032700000], [6.4032700000, 6.4032700000, -6.4032700000]),
      "SpglibTestData/virtual_structure/POSCAR-99-221-13" : double3x3([10.0000000000, 0.0000000000, 0.0000000000],[0.0000000000, 10.0000000000, 0.0000000000], [0.0000000000, 0.0000000000, 10.0000000000])
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          var histogram:[Int:Int] = [:]
                    
          for atom in reader.atoms
          {
            histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
          }
          
          // Find least occurent element
          let minType: Int = histogram.min{a, b in a.value < b.value}!.key
          
          //let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.filter{$0.type == minType}
          let reducedAtoms = reader.atoms
          
          // search for a primitive cell based on the positions of the atoms
          let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: reader.atoms, unitCell: unitCell, symmetryPrecision: precision)
         
          let DelaunayUnitCell: double3x3? = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: precision)
          
          XCTAssertNotNil(DelaunayUnitCell, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = DelaunayUnitCell
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }
  
  /*
  func testFindTetragonalSpaceGroupdDebug()
  {
    let testData: [String: double3x3] =
    [
      "SpglibTestData/tetragonal/POSCAR-083-3" : double3x3([-0.0000000000, -0.0000000000, -3.6799982684],[-3.9099981602, -3.9099981602, -0.0000000000], [-3.9099981602, 3.9099981602, -0.0000000000]),
    ]
      
    let bundle = Bundle(for: type(of: self))
      
    for (fileName, referencePrimitiveUnitCell) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          print("atoms: \(reader.atoms.count)")
          var histogram:[Int:Int] = [:]
                    
          for atom in reader.atoms
          {
            histogram[atom.type] = (histogram[atom.type] ?? 0) + 1
          }
          
          // Find least occurent element
          let minType: Int = histogram.min{a, b in a.value < b.value}!.key
          
          let reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.filter{$0.type == minType}
          
          // search for a primitive cell based on the positions of the atoms
          let primitiveUnitCell: double3x3 = SKSymmetryCell.findSmallestPrimitiveCell(reducedAtoms: reducedAtoms, atoms: reader.atoms, unitCell: unitCell, symmetryPrecision: precision)
          print("primitiveUnitCell")
          print(primitiveUnitCell)
          
          let DelaunayUnitCell: double3x3? = SKSymmetryCell.computeDelaunayReducedCell(unitCell: primitiveUnitCell, symmetryPrecision: 1e-3)
          print("DelaunayUnitCell")
          print(DelaunayUnitCell)
          
          
          XCTAssertNotNil(DelaunayUnitCell, "DelaunayUnitCell \(fileName) not found")
          if let primitiveUnitCell = DelaunayUnitCell
          {
            XCTAssertEqual(primitiveUnitCell[0][0], referencePrimitiveUnitCell[0][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][1], referencePrimitiveUnitCell[0][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[0][2], referencePrimitiveUnitCell[0][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[1][0], referencePrimitiveUnitCell[1][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][1], referencePrimitiveUnitCell[1][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[1][2], referencePrimitiveUnitCell[1][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
        
            XCTAssertEqual(primitiveUnitCell[2][0], referencePrimitiveUnitCell[2][0], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][1], referencePrimitiveUnitCell[2][1], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
            XCTAssertEqual(primitiveUnitCell[2][2], referencePrimitiveUnitCell[2][2], accuracy: precision, "Wrong primitiveCell found for \(fileName): \(primitiveUnitCell) should be \(referencePrimitiveUnitCell)")
          }
        }
      }
    }
  }*/
}
