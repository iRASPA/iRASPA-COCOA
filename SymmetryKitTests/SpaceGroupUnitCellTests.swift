//
//  SpaceGroupUnitCellTests.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 03/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
import simd
@testable import SymmetryKit

class SpaceGroupUnitCellTests: XCTestCase
{
  let precision: Double = 1e-3
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testFindMonoclinicSpaceGroup()
  {
    let testData: [String: double3x3] =
      [
        "SpglibTestData/monoclinic/POSCAR-003": double3x3(SIMD3<Double>( 4.16049804231 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.12939805694 , 0.0 ), SIMD3<Double>( -1.46365987795 , 0.0 , 7.27532632558 )),
        "SpglibTestData/monoclinic/POSCAR-004": double3x3(SIMD3<Double>( 5.0120976416 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.21409613492 , 0.0 ), SIMD3<Double>( -2.48925099524 , 0.0 , 4.37671570567 )),
        "SpglibTestData/monoclinic/POSCAR-004-2": double3x3(SIMD3<Double>( 11.7619944655 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.34399654434 , 0.0 ), SIMD3<Double>( -4.35825743414 , 0.0 , 11.0527652783 )),
        "SpglibTestData/monoclinic/POSCAR-005": double3x3(SIMD3<Double>( 12.5199941088 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.82999819783 , 0.0 ), SIMD3<Double>( -2.00570673892 , 0.0 , 6.36128906824 )),
        "SpglibTestData/monoclinic/POSCAR-005-2": double3x3(SIMD3<Double>( 12.8619939479 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.2049947276 , 0.0 ), SIMD3<Double>( -2.43448994423 , 0.0 , 7.76846685906 )),
        "SpglibTestData/monoclinic/POSCAR-006": double3x3(SIMD3<Double>( 6.97099671985 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.66999544986 , 0.0 ), SIMD3<Double>( -0.347545694785 , 0.0 , 10.9374744935 )),
        "SpglibTestData/monoclinic/POSCAR-006-2": double3x3(SIMD3<Double>( 6.53689692412 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.20879849013 , 0.0 ), SIMD3<Double>( -3.15173854715 , 0.0 , 8.85502239582 )),
        "SpglibTestData/monoclinic/POSCAR-007": double3x3(SIMD3<Double>( 6.79564807483 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 22.5499893893 , 0.0 ), SIMD3<Double>( -3.33137392551 , 0.0 , 5.93838236706 )),
        "SpglibTestData/monoclinic/POSCAR-007-2": double3x3(SIMD3<Double>( 13.0859938425 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.40499745672 , 0.0 ), SIMD3<Double>( -10.5150150743 , 0.0 , 16.2508775893 )),
        "SpglibTestData/monoclinic/POSCAR-008": double3x3(SIMD3<Double>( 16.6499921655 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.0819933738 , 0.0 ), SIMD3<Double>( -2.37535369871 , 0.0 , 10.6441730009 )),
        "SpglibTestData/monoclinic/POSCAR-008-2": double3x3(SIMD3<Double>( 14.087993371 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.13779617083 , 0.0 ), SIMD3<Double>( -4.75502723033 , 0.0 , 26.6955687405 )),
        "SpglibTestData/monoclinic/POSCAR-009": double3x3(SIMD3<Double>( 16.2779923405 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.63209734986 , 0.0 ), SIMD3<Double>( -6.93540790248 , 0.0 , 9.37590780395 )),
        "SpglibTestData/monoclinic/POSCAR-009-2": double3x3(SIMD3<Double>( 12.8724656748 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.686991207 , 0.0 ), SIMD3<Double>( -5.51979524915 , 0.0 , 7.38762914424 )),
        "SpglibTestData/monoclinic/POSCAR-010": double3x3(SIMD3<Double>( 12.3929941686 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.77699822276 , 0.0 ), SIMD3<Double>( -5.9123807571 , 0.0 , 14.2035825069 )),
        "SpglibTestData/monoclinic/POSCAR-010-2": double3x3(SIMD3<Double>( 12.3929941686 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.77699822276 , 0.0 ), SIMD3<Double>( -5.9123807571 , 0.0 , 14.2035825069 )),
        "SpglibTestData/monoclinic/POSCAR-011": double3x3(SIMD3<Double>( 11.1025947758 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.16699803925 , 0.0 ), SIMD3<Double>( -4.8567343598 , 0.0 , 10.3210858829 )),
        "SpglibTestData/monoclinic/POSCAR-011-2": double3x3(SIMD3<Double>( 4.87999770376 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.5389955115 , 0.0 ), SIMD3<Double>( -0.324244058181 , 0.0 , 7.00549702064 )),
        "SpglibTestData/monoclinic/POSCAR-012": double3x3(SIMD3<Double>( 5.01754688811 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.67404218099 , 0.0 ), SIMD3<Double>( -1.7021585635 , 0.0 , 4.80318913924 )),
        "SpglibTestData/monoclinic/POSCAR-012-2": double3x3(SIMD3<Double>( 5.01734867041 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.67365452812 , 0.0 ), SIMD3<Double>( -1.70154275122 , 0.0 , 4.8029972828 )),
        "SpglibTestData/monoclinic/POSCAR-012-3": double3x3(SIMD3<Double>( 13.2899937465 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.42299603663 , 0.0 ), SIMD3<Double>( -2.05205158286 , 0.0 , 10.2230773735 )),
        "SpglibTestData/monoclinic/POSCAR-013": double3x3(SIMD3<Double>( 4.85899771364 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.75599682102 , 0.0 ), SIMD3<Double>( -0.549874615981 , 0.0 , 5.817065822 )),
        "SpglibTestData/monoclinic/POSCAR-013-2": double3x3(SIMD3<Double>( 12.1079943027 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.62799641071 , 0.0 ), SIMD3<Double>( -4.15307458606 , 0.0 , 10.7517683411 )),
        "SpglibTestData/monoclinic/POSCAR-013-3": double3x3(SIMD3<Double>( 8.00899623143 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.56699690995 , 0.0 ), SIMD3<Double>( -7.39642298226 , 0.0 , 9.68263752453 )),
        "SpglibTestData/monoclinic/POSCAR-014": double3x3(SIMD3<Double>( 5.06999761435 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 13.8299934924 , 0.0 ), SIMD3<Double>( -2.8578078361 , 0.0 , 5.78233475514 )),
        "SpglibTestData/monoclinic/POSCAR-014-2": double3x3(SIMD3<Double>( 7.15299663421 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.99399529741 , 0.0 ), SIMD3<Double>( -6.60622141817 , 0.0 , 11.1796318348 )),
        "SpglibTestData/monoclinic/POSCAR-015": double3x3(SIMD3<Double>( 5.18970638759 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.12768646799 , 0.0 ), SIMD3<Double>( -0.321914889243 , 0.0 , 10.352789197 )),
        "SpglibTestData/monoclinic/POSCAR-015-2": double3x3(SIMD3<Double>( 5.18970638759 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.12768646799 , 0.0 ), SIMD3<Double>( -0.321914889243 , 0.0 , 10.352789197 )),
        "SpglibTestData/monoclinic/POSCAR-015-3": double3x3(SIMD3<Double>( 9.41299557079 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.5219945784 , 0.0 ), SIMD3<Double>( -0.092540860006 , 0.0 , 5.04914965011 ))
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, reference) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
      {
        
        let reader: SKVASPReader = SKVASPReader(URL: url)
        if let unitCell = reader.unitCell
        {
          let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
          let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = reader.atoms.map{($0.fractionalPosition + origin, $0.type)}
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, symmetryPrecision: precision)
          XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
          if let spacegroup = spacegroup
          {
            XCTAssertEqual(spacegroup.cell.unitCell[0][0], reference[0][0], accuracy: precision, "Wrong a found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.unitCell[0][1], reference[0][1], accuracy: precision, "Wrong a found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.unitCell[0][2], reference[0][2], accuracy: precision, "Wrong a found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.unitCell[1][0], reference[1][0], accuracy: precision, "Wrong a found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.unitCell[1][1], reference[1][1], accuracy: precision, "Wrong a found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.unitCell[1][2], reference[1][2], accuracy: precision, "Wrong a found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.unitCell[2][0], reference[2][0], accuracy: precision, "Wrong a found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.unitCell[2][1], reference[2][1], accuracy: precision, "Wrong a found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.unitCell[2][2], reference[2][2], accuracy: precision, "Wrong a found for \(fileName)")
           
          }
        }
      }
    }
  }
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testFindMonoclinicSpaceGroup2()
  {
    let testData: [String: (spacegroup: Int, a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)] =
      [
        "SpglibTestData/monoclinic/POSCAR-013-3": (13, 8.0090, 6.5670, 12.1844, 90.0000, 127.3757, 90.0000) ,
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, reference) in testData
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
            XCTAssertEqual(spacegroup.cell.a, reference.a, accuracy: precision, "Wrong a found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.b, reference.b, accuracy: precision, "Wrong b found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.c, reference.c, accuracy: precision, "Wrong c found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.alpha * 180/Double.pi, reference.alpha, accuracy: precision, "Wrong alpha found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.beta * 180/Double.pi, reference.beta, accuracy: precision, "Wrong beta found for \(fileName)")
            XCTAssertEqual(spacegroup.cell.gamma * 180/Double.pi, reference.gamma, accuracy: precision, "Wrong gamma found for \(fileName)")
            print(spacegroup.cell.unitCell)
            print(reference)
            print(SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber)
          }
        }
      }
    }
  }
}
