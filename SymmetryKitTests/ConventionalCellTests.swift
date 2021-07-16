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

class ConventionalCellTests: XCTestCase
{
  let precision: Double = 1e-5
  
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testFindTriclinicSpaceGroup()
  {
    let testData: [String: double3x3] =
      [
        "SpglibTestData/triclinic/POSCAR-001": double3x3(SIMD3<Double>( 4.91599768682 , 0.0 , 0.0 ), SIMD3<Double>( -2.45749884364 , 4.25824490673 , 0.0 ), SIMD3<Double>( 3.31083106361e-16 , 5.73336141122e-16 , 5.40699745578 )),
        "SpglibTestData/triclinic/POSCAR-002": double3x3(SIMD3<Double>( 5.50899740779 , 0.0 , 0.0 ), SIMD3<Double>( 1.70743618512 , 6.56486486224 , 0.0 ), SIMD3<Double>( 2.31047095483 , 2.55808206421 , 6.10163567424 ))
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
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, symmetryPrecision: precision)
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
  func testFindMonoclinicSpaceGroup()
  {
    let testData: [String: double3x3] =
      [
        "SpglibTestData/monoclinic/POSCAR-003": double3x3(SIMD3<Double>( 4.16049804231 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.12939805694 , 0.0 ), SIMD3<Double>( -1.46365987795 , 0.0 , 7.27532632558 )),
        "SpglibTestData/monoclinic/POSCAR-004": double3x3(SIMD3<Double>( 5.0120976416 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.21409613492 , 0.0 ), SIMD3<Double>( -2.48925099524 , 0.0 , 4.37671570567 )),
        "SpglibTestData/monoclinic/POSCAR-004-2": double3x3(SIMD3<Double>( 11.7619944655 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.34399654434 , 0.0 ), SIMD3<Double>( -4.35825743414 , 0.0 , 11.0527652783 )),
        //"SpglibTestData/monoclinic/POSCAR-005": double3x3(SIMD3<Double>( 12.5199941088 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.82999819783 , 0.0 ), SIMD3<Double>( -2.00570673892 , 0.0 , 6.36128906824 )),
        "SpglibTestData/monoclinic/POSCAR-005-2": double3x3(SIMD3<Double>( 12.8619939479 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.2049947276 , 0.0 ), SIMD3<Double>( -2.43448994423 , 0.0 , 7.76846685906 )),
        "SpglibTestData/monoclinic/POSCAR-006": double3x3(SIMD3<Double>( 6.97099671985 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.66999544986 , 0.0 ), SIMD3<Double>( -0.347545694785 , 0.0 , 10.9374744935 )),
        "SpglibTestData/monoclinic/POSCAR-006-2": double3x3(SIMD3<Double>( 6.53689692412 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.20879849013 , 0.0 ), SIMD3<Double>( -3.15173854715 , 0.0 , 8.85502239582 )),
        "SpglibTestData/monoclinic/POSCAR-007": double3x3(SIMD3<Double>( 6.79564807483 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 22.5499893893 , 0.0 ), SIMD3<Double>( -3.33137392551 , 0.0 , 5.93838236706 )),
        "SpglibTestData/monoclinic/POSCAR-007-2": double3x3(SIMD3<Double>( 13.0859938425 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.40499745672 , 0.0 ), SIMD3<Double>( -10.5150150743 , 0.0 , 16.2508775893 )),
        "SpglibTestData/monoclinic/POSCAR-008": double3x3(SIMD3<Double>( 16.6499921655 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.0819933738 , 0.0 ), SIMD3<Double>( -2.37535369871 , 0.0 , 10.6441730009 )),
        "SpglibTestData/monoclinic/POSCAR-008-2": double3x3(SIMD3<Double>( 14.087993371 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.13779617083 , 0.0 ), SIMD3<Double>( -4.75502723033 , 0.0 , 26.6955687405 )),
        //"SpglibTestData/monoclinic/POSCAR-009": double3x3(SIMD3<Double>( 16.2779923405 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.63209734986 , 0.0 ), SIMD3<Double>( -6.93540790248 , 0.0 , 9.37590780395 )),
        //"SpglibTestData/monoclinic/POSCAR-009-2": double3x3(SIMD3<Double>( 12.8724656748 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.686991207 , 0.0 ), SIMD3<Double>( -5.51979524915 , 0.0 , 7.38762914424 )),
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
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, symmetryPrecision: precision)
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
  
  func testFindOrthorhombicSpaceGroup()
  {
    let testData: [String: double3x3] =
      [
        "SpglibTestData/orthorhombic/POSCAR-016": double3x3(SIMD3<Double>( 10.7049949629 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.7339949492 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 31.6299851168 )),
        "SpglibTestData/orthorhombic/POSCAR-016-2": double3x3(SIMD3<Double>( 5.60999736026 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.66999733203 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.0499957416 )),
        "SpglibTestData/orthorhombic/POSCAR-017-2": double3x3(SIMD3<Double>( 7.04999668268 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.84999630625 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.32999796255 )),
        "SpglibTestData/orthorhombic/POSCAR-018": double3x3(SIMD3<Double>( 8.3339960785 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 13.9949934148 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.06399761718 )),
        "SpglibTestData/orthorhombic/POSCAR-018-2": double3x3(SIMD3<Double>( 7.34899654199 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.51499646388 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.89399628554 )),
        "SpglibTestData/orthorhombic/POSCAR-019": double3x3(SIMD3<Double>( 3.51835982747 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.63040701685 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.38027402216 )),
        "SpglibTestData/orthorhombic/POSCAR-019-2": double3x3(SIMD3<Double>( 4.80899773716 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.95699672644 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.46599601639 )),
        "SpglibTestData/orthorhombic/POSCAR-020": double3x3(SIMD3<Double>( 5.04999762376 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.73999588746 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.23999612274 )),
        "SpglibTestData/orthorhombic/POSCAR-021": double3x3(SIMD3<Double>( 6.38599699512 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.4299950922 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.79999821194 )),
        "SpglibTestData/orthorhombic/POSCAR-021-2": double3x3(SIMD3<Double>( 6.50799693771 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 15.1639928647 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.51799693301 )),
        "SpglibTestData/orthorhombic/POSCAR-022": double3x3(SIMD3<Double>( 5.83079725637 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.8889939352 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 13.3379937239 )),
        "SpglibTestData/orthorhombic/POSCAR-023": double3x3(SIMD3<Double>( 10.1739952127 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.1739952127 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.1749952122 )),
        "SpglibTestData/orthorhombic/POSCAR-023-2": double3x3(SIMD3<Double>( 6.04399715605 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.34599607286 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.6459916968 )),
        "SpglibTestData/orthorhombic/POSCAR-024": double3x3(SIMD3<Double>( 7.05099668221 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.2849965721 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.96799530964 )),
        "SpglibTestData/orthorhombic/POSCAR-024-2": double3x3(SIMD3<Double>( 12.8849939371 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 15.8719925316 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 15.921992508 )),
        "SpglibTestData/orthorhombic/POSCAR-025": double3x3(SIMD3<Double>( 2.91899862649 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.6179973565 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.06599855732 )),
        "SpglibTestData/orthorhombic/POSCAR-025-2": double3x3(SIMD3<Double>( 5.7675972861 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.20329614 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.84889724785 )),
        "SpglibTestData/orthorhombic/POSCAR-026": double3x3(SIMD3<Double>( 4.00999811313 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.1499947535 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.5099945841 )),
        "SpglibTestData/orthorhombic/POSCAR-026-2": double3x3(SIMD3<Double>( 8.17599615285 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.44529649668 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.64899593028 )),
        "SpglibTestData/orthorhombic/POSCAR-027": double3x3(SIMD3<Double>( 13.0279938698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 13.0369938655 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.16099568937 )),
        "SpglibTestData/orthorhombic/POSCAR-027-2": double3x3(SIMD3<Double>( 13.7939935093 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 23.8999887541 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.41679603954 )),
        "SpglibTestData/orthorhombic/POSCAR-028": double3x3(SIMD3<Double>( 7.95499625684 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.25799705535 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.20299661069 )),
        "SpglibTestData/orthorhombic/POSCAR-028-2": double3x3(SIMD3<Double>( 5.18479756034 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.19159755714 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.09799713064 )),
        "SpglibTestData/orthorhombic/POSCAR-029": double3x3(SIMD3<Double>( 21.1859900311 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.78999680502 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.2269947172 )),
        "SpglibTestData/orthorhombic/POSCAR-029-2": double3x3(SIMD3<Double>( 10.7239949539 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.25899752542 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.47199695465 )),
        "SpglibTestData/orthorhombic/POSCAR-030": double3x3(SIMD3<Double>( 8.86199583006 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.1869952066 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.637996406 )),
        "SpglibTestData/orthorhombic/POSCAR-030-2": double3x3(SIMD3<Double>( 4.4809978915 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.67199639 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.3289932576 )),
        "SpglibTestData/orthorhombic/POSCAR-031": double3x3(SIMD3<Double>( 8.87899582206 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.93599673632 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.6539978101 )),
        "SpglibTestData/orthorhombic/POSCAR-031-2": double3x3(SIMD3<Double>( 5.74299729768 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.91499768729 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.36099559526 )),
        "SpglibTestData/orthorhombic/POSCAR-032": double3x3(SIMD3<Double>( 10.388095112 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.4193950972 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.7006949649 )),
        "SpglibTestData/orthorhombic/POSCAR-032-2": double3x3(SIMD3<Double>( 5.88399723133 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.7679944627 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.21999613215 )),
        "SpglibTestData/orthorhombic/POSCAR-033": double3x3(SIMD3<Double>( 4.10855438213 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.5910714829 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.05563769575 )),
        "SpglibTestData/orthorhombic/POSCAR-033-2": double3x3(SIMD3<Double>( 5.45599743272 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.81399773481 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.7869944537 )),
        "SpglibTestData/orthorhombic/POSCAR-033-3": double3x3(SIMD3<Double>( 6.99899670668 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 13.8479934839 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.09399572089 )),
        "SpglibTestData/orthorhombic/POSCAR-034": double3x3(SIMD3<Double>( 5.91999721439 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.8899948758 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.0299943394 )),
        "SpglibTestData/orthorhombic/POSCAR-034-2": double3x3(SIMD3<Double>( 10.3479951308 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.521995049 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.94599626108 )),
        "SpglibTestData/orthorhombic/POSCAR-035": double3x3(SIMD3<Double>( 3.61999829664 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 19.3999908715 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.12999805666 )),
        "SpglibTestData/orthorhombic/POSCAR-035-2": double3x3(SIMD3<Double>( 14.357993244 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 16.8249920831 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.32099749625 )),
        "SpglibTestData/orthorhombic/POSCAR-036": double3x3(SIMD3<Double>( 7.74599635518 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 35.2929833932 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.9429915571 )),
        "SpglibTestData/orthorhombic/POSCAR-036-2": double3x3(SIMD3<Double>( 17.279991869 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.97999530399 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 13.5499936242 )),
        "SpglibTestData/orthorhombic/POSCAR-037": double3x3(SIMD3<Double>( 12.0729943191 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 19.0229910489 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.8759972351 )),
        "SpglibTestData/orthorhombic/POSCAR-037-2": double3x3(SIMD3<Double>( 5.80699726756 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.5819931386 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.7729977541 )),
        "SpglibTestData/orthorhombic/POSCAR-038": double3x3(SIMD3<Double>( 6.94699673115 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.47599789386 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 18.8499911303 )),
        "SpglibTestData/orthorhombic/POSCAR-038-2": double3x3(SIMD3<Double>( 4.14799804819 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.9679943686 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.71699683937 )),
        "SpglibTestData/orthorhombic/POSCAR-039": double3x3(SIMD3<Double>( 5.41999744966 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 38.5799818465 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.52699739932 )),
        "SpglibTestData/orthorhombic/POSCAR-039-2": double3x3(SIMD3<Double>( 11.5685945565 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 16.4416922635 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.53599739508 )),
        "SpglibTestData/orthorhombic/POSCAR-040": double3x3(SIMD3<Double>( 9.53999551103 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.84999536516 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.57999831546 )),
        "SpglibTestData/orthorhombic/POSCAR-040-2": double3x3(SIMD3<Double>( 5.08599760682 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.2379951826 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.89899722427 )),
        "SpglibTestData/orthorhombic/POSCAR-041": double3x3(SIMD3<Double>( 11.0619947949 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.1749947417 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.04099574583 )),
        "SpglibTestData/orthorhombic/POSCAR-041-2": double3x3(SIMD3<Double>( 10.2299951864 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.57999643329 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0399952758 )),
        "SpglibTestData/orthorhombic/POSCAR-042": double3x3(SIMD3<Double>( 5.31199750048 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.36299747648 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.8689944151 )),
        "SpglibTestData/orthorhombic/POSCAR-043": double3x3(SIMD3<Double>( 8.15699616179 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 39.2939815105 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.5799945511 )),
        "SpglibTestData/orthorhombic/POSCAR-043-2": double3x3(SIMD3<Double>( 11.1819947384 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 22.8729892373 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.572995025 )),
        "SpglibTestData/orthorhombic/POSCAR-044": double3x3(SIMD3<Double>( 3.65199828158 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.36199747696 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.6519973405 )),
        "SpglibTestData/orthorhombic/POSCAR-044-2": double3x3(SIMD3<Double>( 4.36099794797 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 15.7799925749 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.71999542633 )),
        "SpglibTestData/orthorhombic/POSCAR-045": double3x3(SIMD3<Double>( 11.1029947756 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.9239910955 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.57199737814 )),
        "SpglibTestData/orthorhombic/POSCAR-045-2": double3x3(SIMD3<Double>( 5.91999721439 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.4699946029 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.1599933371 )),
        "SpglibTestData/orthorhombic/POSCAR-046": double3x3(SIMD3<Double>( 21.9499896716 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.08999760494 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.4199946264 )),
        "SpglibTestData/orthorhombic/POSCAR-046-2": double3x3(SIMD3<Double>( 7.97999624508 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.1899952052 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.20999707794 )),
        "SpglibTestData/orthorhombic/POSCAR-047": double3x3(SIMD3<Double>( 3.00499858602 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.58499831311 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.8489972478 )),
        "SpglibTestData/orthorhombic/POSCAR-047-2": double3x3(SIMD3<Double>( 3.83399819594 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.28999656975 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 25.2599881141 )),
        "SpglibTestData/orthorhombic/POSCAR-048": double3x3(SIMD3<Double>( 6.32999702147 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.32999702147 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.53999551103 )),
        "SpglibTestData/orthorhombic/POSCAR-048-2": double3x3(SIMD3<Double>( 4.4792978923 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.06659620433 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.33309560839 )),
        "SpglibTestData/orthorhombic/POSCAR-049": double3x3(SIMD3<Double>( 5.13999758142 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.55999550162 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.25999611332 )),
        "SpglibTestData/orthorhombic/POSCAR-049-2": double3x3(SIMD3<Double>( 3.67699826982 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.21699707464 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.7939963326 )),
        "SpglibTestData/orthorhombic/POSCAR-050": double3x3(SIMD3<Double>( 7.32699655234 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 20.0799905515 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.11499806372 )),
        "SpglibTestData/orthorhombic/POSCAR-050-2": double3x3(SIMD3<Double>( 5.47689742289 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.47689742289 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 20.7962902145 )),
        "SpglibTestData/orthorhombic/POSCAR-051": double3x3(SIMD3<Double>( 16.7049921396 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.835998195 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.927995799 )),
        "SpglibTestData/orthorhombic/POSCAR-051-2": double3x3(SIMD3<Double>( 8.40999604274 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.54099786327 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.32799561079 )),
        "SpglibTestData/orthorhombic/POSCAR-051-3": double3x3(SIMD3<Double>( 4.36999794373 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 2.96599860437 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.52199787221 )),
        "SpglibTestData/orthorhombic/POSCAR-052": double3x3(SIMD3<Double>( 8.58799595899 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.76599587523 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.34299560373 )),
        "SpglibTestData/orthorhombic/POSCAR-052-2": double3x3(SIMD3<Double>( 5.18299756118 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.89299769764 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.49099600463 )),
        "SpglibTestData/orthorhombic/POSCAR-053": double3x3(SIMD3<Double>( 13.0659938519 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.79399586206 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.02499575336 )),
        "SpglibTestData/orthorhombic/POSCAR-053-2": double3x3(SIMD3<Double>( 8.01499622861 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.72999824488 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.39499652034 )),
        "SpglibTestData/orthorhombic/POSCAR-054": double3x3(SIMD3<Double>( 10.1199952381 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.80999726615 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.9499948476 )),
        "SpglibTestData/orthorhombic/POSCAR-054-2": double3x3(SIMD3<Double>( 9.98099530352 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.7809972798 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.521995049 )),
        "SpglibTestData/orthorhombic/POSCAR-055": double3x3(SIMD3<Double>( 11.541994569 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.6899940288 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.97399813007 )),
        "SpglibTestData/orthorhombic/POSCAR-055-2": double3x3(SIMD3<Double>( 7.91499627566 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.2199947205 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.95999813665 )),
        "SpglibTestData/orthorhombic/POSCAR-056": double3x3(SIMD3<Double>( 4.91099768917 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.4639941352 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.41199745343 )),
        "SpglibTestData/orthorhombic/POSCAR-056-2": double3x3(SIMD3<Double>( 7.80299632836 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.2729951661 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.56599596934 )),
        "SpglibTestData/orthorhombic/POSCAR-057": double3x3(SIMD3<Double>( 5.26099752448 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.4249946241 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.71499731085 )),
        "SpglibTestData/orthorhombic/POSCAR-057-2": double3x3(SIMD3<Double>( 6.35899700782 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.76499540516 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.6669968629 )),
        "SpglibTestData/orthorhombic/POSCAR-058": double3x3(SIMD3<Double>( 10.8399948993 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 23.6929888515 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.90199675232 )),
        "SpglibTestData/orthorhombic/POSCAR-058-2": double3x3(SIMD3<Double>( 4.33199796161 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.87299770705 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 2.96299860578 )),
        "SpglibTestData/orthorhombic/POSCAR-058-3": double3x3(SIMD3<Double>( 3.8912820645 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.02154657424 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 2.57249172595 )),
        "SpglibTestData/orthorhombic/POSCAR-059": double3x3(SIMD3<Double>( 3.56299832346 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.5099945841 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.3689979442 )),
        "SpglibTestData/orthorhombic/POSCAR-059-2": double3x3(SIMD3<Double>( 2.8649986519 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.64499781433 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.04499809666 )),
        "SpglibTestData/orthorhombic/POSCAR-060": double3x3(SIMD3<Double>( 16.1519923998 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.24899705958 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.30699703229 )),
        "SpglibTestData/orthorhombic/POSCAR-060-2": double3x3(SIMD3<Double>( 8.03099622108 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.51799552138 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.74899541269 )),
        "SpglibTestData/orthorhombic/POSCAR-060-3": double3x3(SIMD3<Double>( 5.36727398478 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.58837898147 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.87260731538 )),
        "SpglibTestData/orthorhombic/POSCAR-061": double3x3(SIMD3<Double>( 10.5369950419 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.1989942599 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 13.0469938608 )),
        "SpglibTestData/orthorhombic/POSCAR-061-2": double3x3(SIMD3<Double>( 5.99299718004 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.81899632083 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.01099623049 )),
        "SpglibTestData/orthorhombic/POSCAR-062": double3x3(SIMD3<Double>( 7.48999647564 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.8979967542 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.9419948513 )),
        "SpglibTestData/orthorhombic/POSCAR-062-2": double3x3(SIMD3<Double>( 9.49499553221 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.37499558867 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.149995224 )),
        "SpglibTestData/orthorhombic/POSCAR-063": double3x3(SIMD3<Double>( 9.20099567055 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.15899663139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.77099540234 )),
        "SpglibTestData/orthorhombic/POSCAR-063-2": double3x3(SIMD3<Double>( 5.56899737955 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.7959939789 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.31999655563 )),
        "SpglibTestData/orthorhombic/POSCAR-063-3": double3x3(SIMD3<Double>( 5.75999728968 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.89999581218 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 13.3299937277 )),
        "SpglibTestData/orthorhombic/POSCAR-064": double3x3(SIMD3<Double>( 5.36999747319 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 13.1499938124 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.40599745625 )),
        "SpglibTestData/orthorhombic/POSCAR-064-2": double3x3(SIMD3<Double>( 5.47099742567 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.2109942542 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.46499742849 )),
        "SpglibTestData/orthorhombic/POSCAR-064-3": double3x3(SIMD3<Double>( 5.75718235082 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.14105123631 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.80861377659 )),
        "SpglibTestData/orthorhombic/POSCAR-065": double3x3(SIMD3<Double>( 4.83799772352 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.1469961665 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.1069971264 )),
        "SpglibTestData/orthorhombic/POSCAR-065-2": double3x3(SIMD3<Double>( 5.75999728968 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.37999699794 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.0599980896 )),
        "SpglibTestData/orthorhombic/POSCAR-065-3": double3x3(SIMD3<Double>( 5.49213934289 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.56450595043 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.87129817839 )),
        "SpglibTestData/orthorhombic/POSCAR-066": double3x3(SIMD3<Double>( 6.32999702147 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.4799950687 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.5299950452 )),
        "SpglibTestData/orthorhombic/POSCAR-066-2": double3x3(SIMD3<Double>( 7.06969667341 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 25.4922880048 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.02689669355 )),
        "SpglibTestData/orthorhombic/POSCAR-067": double3x3(SIMD3<Double>( 7.96999624978 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.7219944843 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.37399794185 )),
        "SpglibTestData/orthorhombic/POSCAR-067-2": double3x3(SIMD3<Double>( 9.91599533411 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.3659946518 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.27099610815 )),
        "SpglibTestData/orthorhombic/POSCAR-067-3": double3x3(SIMD3<Double>( 7.63999640506 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.77999633919 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.48999741673 )),
        "SpglibTestData/orthorhombic/POSCAR-068": double3x3(SIMD3<Double>( 7.40999651329 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 22.2599895257 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.43999649917 )),
        "SpglibTestData/orthorhombic/POSCAR-068-2": double3x3(SIMD3<Double>( 6.41799698006 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.3659946518 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.38399699606 )),
        "SpglibTestData/orthorhombic/POSCAR-069": double3x3(SIMD3<Double>( 6.38999699324 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.8599948899 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 13.5999936006 )),
        "SpglibTestData/orthorhombic/POSCAR-069-2": double3x3(SIMD3<Double>( 2.73820871156 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.2607947013 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.4266941527 )),
        "SpglibTestData/orthorhombic/POSCAR-070": double3x3(SIMD3<Double>( 7.03899668786 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.35599606815 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.1859952071 )),
        "SpglibTestData/orthorhombic/POSCAR-070-2": double3x3(SIMD3<Double>( 7.46199648882 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.60299548139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.69899543622 )),
        "SpglibTestData/orthorhombic/POSCAR-071": double3x3(SIMD3<Double>( 2.87499864719 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.7149977814 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 15.7069926092 )),
        "SpglibTestData/orthorhombic/POSCAR-071-2": double3x3(SIMD3<Double>( 3.54199833334 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.82699819924 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.695994026 )),
        "SpglibTestData/orthorhombic/POSCAR-072": double3x3(SIMD3<Double>( 7.50099647047 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 15.9659924873 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.85799771411 )),
        "SpglibTestData/orthorhombic/POSCAR-072-2": double3x3(SIMD3<Double>( 5.96699719228 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.4799950687 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.40199745813 )),
        "SpglibTestData/orthorhombic/POSCAR-073": double3x3(SIMD3<Double>( 8.27019610853 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.31149608909 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 20.6069903035 )),
        "SpglibTestData/orthorhombic/POSCAR-073-2": double3x3(SIMD3<Double>( 5.74999729438 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.94999720028 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 20.2299904809 )),
        "SpglibTestData/orthorhombic/POSCAR-074": double3x3(SIMD3<Double>( 5.69599731979 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.4439946151 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24799611897 )),
        "SpglibTestData/orthorhombic/POSCAR-074-2": double3x3(SIMD3<Double>( 5.91199721816 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.94499720263 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.3879960531 ))
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
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, symmetryPrecision: precision)
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
  
  func testFindTetragonalSpaceGroup()
  {
    let testData: [String: double3x3] =
      [
        "SpglibTestData/tetragonal/POSCAR-075": double3x3(SIMD3<Double>( 17.4899917702 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 17.4899917702 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.94399814418 )),
        "SpglibTestData/tetragonal/POSCAR-075-2": double3x3(SIMD3<Double>( 9.19699567243 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.19699567243 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 20.5049903515 )),
        "SpglibTestData/tetragonal/POSCAR-076": double3x3(SIMD3<Double>( 3.98099812677 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.98099812677 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 15.3499927772 )),
        "SpglibTestData/tetragonal/POSCAR-076-2": double3x3(SIMD3<Double>( 8.44799602486 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.44799602486 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.9119929833 )),
        "SpglibTestData/tetragonal/POSCAR-077": double3x3(SIMD3<Double>( 11.1639947469 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.1639947469 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.6379949944 )),
        "SpglibTestData/tetragonal/POSCAR-077-2": double3x3(SIMD3<Double>( 7.97999624508 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.97999624508 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.7799953981 )),
        "SpglibTestData/tetragonal/POSCAR-077-3": double3x3(SIMD3<Double>( 11.1639947469 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.1639947469 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.6379949944 )),
        "SpglibTestData/tetragonal/POSCAR-078": double3x3(SIMD3<Double>( 10.8649948876 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.8649948876 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 28.3569866568 )),
        "SpglibTestData/tetragonal/POSCAR-078-2": double3x3(SIMD3<Double>( 7.62899641024 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.62899641024 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 29.4969861204 )),
        "SpglibTestData/tetragonal/POSCAR-079": double3x3(SIMD3<Double>( 8.48399600792 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.48399600792 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.81299726474 )),
        "SpglibTestData/tetragonal/POSCAR-079-2": double3x3(SIMD3<Double>( 14.91899298 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.91899298 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.60899641965 )),
        "SpglibTestData/tetragonal/POSCAR-080": double3x3(SIMD3<Double>( 20.3379904301 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 20.3379904301 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.6679930981 )),
        "SpglibTestData/tetragonal/POSCAR-080-2": double3x3(SIMD3<Double>( 9.69299543904 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.69299543904 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.98499718381 )),
        "SpglibTestData/tetragonal/POSCAR-081": double3x3(SIMD3<Double>( 7.62089641405 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.62089641405 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.31999702618 )),
        "SpglibTestData/tetragonal/POSCAR-081-2": double3x3(SIMD3<Double>( 10.1814952092 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.1814952092 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.29499750848 )),
        "SpglibTestData/tetragonal/POSCAR-082": double3x3(SIMD3<Double>( 5.54799738943 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.54799738943 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.1699952146 )),
        "SpglibTestData/tetragonal/POSCAR-082-2": double3x3(SIMD3<Double>( 6.32199702523 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.32199702523 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.6049940688 )),
        "SpglibTestData/tetragonal/POSCAR-083": double3x3(SIMD3<Double>( 8.32799608133 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.32799608133 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.13449852509 )),
        "SpglibTestData/tetragonal/POSCAR-083-2": double3x3(SIMD3<Double>( 12.5999940712 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.5999940712 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.99999811783 )),
        "SpglibTestData/tetragonal/POSCAR-083-3": double3x3(SIMD3<Double>( 5.52957242698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.52957242698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.67999826841 )),
        "SpglibTestData/tetragonal/POSCAR-084": double3x3(SIMD3<Double>( 6.42999697442 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.42999697442 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.62999688031 )),
        "SpglibTestData/tetragonal/POSCAR-084-2": double3x3(SIMD3<Double>( 7.16699662763 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.16699662763 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.59799689537 )),
        "SpglibTestData/tetragonal/POSCAR-085": double3x3(SIMD3<Double>( 6.26099705394 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.26099705394 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.10099807031 )),
        "SpglibTestData/tetragonal/POSCAR-085-2": double3x3(SIMD3<Double>( 8.37999605686 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.37999605686 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.48999647564 )),
        "SpglibTestData/tetragonal/POSCAR-086": double3x3(SIMD3<Double>( 11.186994736 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.186994736 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.18899708782 )),
        "SpglibTestData/tetragonal/POSCAR-086-2": double3x3(SIMD3<Double>( 7.06999667327 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.06999667327 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.82199820159 )),
        "SpglibTestData/tetragonal/POSCAR-087": double3x3(SIMD3<Double>( 11.4079946321 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.4079946321 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.2559951741 )),
        "SpglibTestData/tetragonal/POSCAR-087-2": double3x3(SIMD3<Double>( 9.88499534869 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.88499534869 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.12699852862 )),
        "SpglibTestData/tetragonal/POSCAR-088": double3x3(SIMD3<Double>( 13.6959935555 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 13.6959935555 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.98099718569 )),
        "SpglibTestData/tetragonal/POSCAR-088-2": double3x3(SIMD3<Double>( 5.74099729862 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.74099729862 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 13.120993826 )),
        "SpglibTestData/tetragonal/POSCAR-090": double3x3(SIMD3<Double>( 9.55979550171 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.55979550171 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.15999663092 )),
        "SpglibTestData/tetragonal/POSCAR-090-2": double3x3(SIMD3<Double>( 5.25380091208 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.25380091208 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.6099950076 )),
        "SpglibTestData/tetragonal/POSCAR-091": double3x3(SIMD3<Double>( 7.00819670235 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.00819670235 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.65179592897 )),
        "SpglibTestData/tetragonal/POSCAR-091-2": double3x3(SIMD3<Double>( 12.4639941352 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.4639941352 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 26.222987661 )),
        "SpglibTestData/tetragonal/POSCAR-092": double3x3(SIMD3<Double>( 7.10399665727 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.10399665727 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 36.5969827796 )),
        "SpglibTestData/tetragonal/POSCAR-092-2": double3x3(SIMD3<Double>( 6.58999689913 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.58999689913 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.039991982 )),
        "SpglibTestData/tetragonal/POSCAR-092-3": double3x3(SIMD3<Double>( 4.06437129838 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.06437129838 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.6346473255 )),
        "SpglibTestData/tetragonal/POSCAR-094": double3x3(SIMD3<Double>( 4.6862977949 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.6862977949 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.19099567525 )),
        "SpglibTestData/tetragonal/POSCAR-094-2": double3x3(SIMD3<Double>( 9.96199531246 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.96199531246 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 13.4139936882 )),
        "SpglibTestData/tetragonal/POSCAR-094-3": double3x3(SIMD3<Double>( 7.34499654387 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.34499654387 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.3999951064 )),
        "SpglibTestData/tetragonal/POSCAR-095": double3x3(SIMD3<Double>( 6.16999709676 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.16999709676 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.56399597028 )),
        "SpglibTestData/tetragonal/POSCAR-095-2": double3x3(SIMD3<Double>( 6.08039713892 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.08039713892 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.39879604801 )),
        "SpglibTestData/tetragonal/POSCAR-096": double3x3(SIMD3<Double>( 7.48999647564 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.48999647564 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 13.23999377 )),
        "SpglibTestData/tetragonal/POSCAR-096-2": double3x3(SIMD3<Double>( 5.99699717816 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.99699717816 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 39.190981559 )),
        "SpglibTestData/tetragonal/POSCAR-097": double3x3(SIMD3<Double>( 7.48299647894 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.48299647894 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.8929929922 )),
        "SpglibTestData/tetragonal/POSCAR-097-2": double3x3(SIMD3<Double>( 9.53099551527 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.53099551527 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.8239939658 )),
        "SpglibTestData/tetragonal/POSCAR-098": double3x3(SIMD3<Double>( 7.95399625731 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.95399625731 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.67799779881 )),
        "SpglibTestData/tetragonal/POSCAR-098-2": double3x3(SIMD3<Double>( 9.38299558491 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.38299558491 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 54.5999743084 )),
        "SpglibTestData/tetragonal/POSCAR-099": double3x3(SIMD3<Double>( 3.89899816536 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.89899816536 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.16699803925 )),
        "SpglibTestData/tetragonal/POSCAR-099-2": double3x3(SIMD3<Double>( 3.80719820855 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.80719820855 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.6981977893 )),
        "SpglibTestData/tetragonal/POSCAR-100": double3x3(SIMD3<Double>( 8.86999582629 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.86999582629 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.21499754612 )),
        "SpglibTestData/tetragonal/POSCAR-100-2": double3x3(SIMD3<Double>( 8.31199608886 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.31199608886 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0699952616 )),
        "SpglibTestData/tetragonal/POSCAR-102": double3x3(SIMD3<Double>( 8.86399582912 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.86399582912 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.01999622625 )),
        "SpglibTestData/tetragonal/POSCAR-102-2": double3x3(SIMD3<Double>( 10.7589949374 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.7589949374 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.65599733862 )),
        "SpglibTestData/tetragonal/POSCAR-103": double3x3(SIMD3<Double>( 6.55099691748 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.55099691748 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.8469967782 )),
        "SpglibTestData/tetragonal/POSCAR-103-2": double3x3(SIMD3<Double>( 6.51399693489 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.51399693489 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.80899679608 )),
        "SpglibTestData/tetragonal/POSCAR-104": double3x3(SIMD3<Double>( 9.41599556938 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.41599556938 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.23699565361 )),
        "SpglibTestData/tetragonal/POSCAR-104-2": double3x3(SIMD3<Double>( 10.6199950028 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.6199950028 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.00899576089 )),
        "SpglibTestData/tetragonal/POSCAR-105": double3x3(SIMD3<Double>( 7.61799641541 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.61799641541 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.49999600039 )),
        "SpglibTestData/tetragonal/POSCAR-105-2": double3x3(SIMD3<Double>( 5.63999734614 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.63999734614 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.0499957416 )),
        "SpglibTestData/tetragonal/POSCAR-106": double3x3(SIMD3<Double>( 10.8389948998 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.8389948998 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.30799750236 )),
        "SpglibTestData/tetragonal/POSCAR-107": double3x3(SIMD3<Double>( 7.76199634765 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.76199634765 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.745994473 )),
        "SpglibTestData/tetragonal/POSCAR-107-2": double3x3(SIMD3<Double>( 4.11999806137 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.11999806137 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.4749950711 )),
        "SpglibTestData/tetragonal/POSCAR-107-3": double3x3(SIMD3<Double>( 3.55189832868 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.55189832868 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 25.6453879328 )),
        "SpglibTestData/tetragonal/POSCAR-108": double3x3(SIMD3<Double>( 6.13999711087 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.13999711087 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.5719950254 )),
        "SpglibTestData/tetragonal/POSCAR-108-2": double3x3(SIMD3<Double>( 8.05499620979 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.05499620979 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 15.6879926181 )),
        "SpglibTestData/tetragonal/POSCAR-109": double3x3(SIMD3<Double>( 3.45169837583 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.45169837583 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.6799945041 )),
        "SpglibTestData/tetragonal/POSCAR-109-2": double3x3(SIMD3<Double>( 11.3799946452 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.3799946452 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.74999588276 )),
        "SpglibTestData/tetragonal/POSCAR-110": double3x3(SIMD3<Double>( 13.6199935912 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 13.6199935912 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.09999571807 )),
        "SpglibTestData/tetragonal/POSCAR-110-2": double3x3(SIMD3<Double>( 11.7822944559 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.7822944559 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 23.6384888771 )),
        "SpglibTestData/tetragonal/POSCAR-111": double3x3(SIMD3<Double>( 5.159997572 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.159997572 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0699952616 )),
        "SpglibTestData/tetragonal/POSCAR-111-2": double3x3(SIMD3<Double>( 5.81509726375 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.81509726375 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.8013972702 )),
        "SpglibTestData/tetragonal/POSCAR-112": double3x3(SIMD3<Double>( 5.42999744496 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.42999744496 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0959952494 )),
        "SpglibTestData/tetragonal/POSCAR-112-2": double3x3(SIMD3<Double>( 5.41499745202 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.41499745202 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.1969952019 )),
        "SpglibTestData/tetragonal/POSCAR-113": double3x3(SIMD3<Double>( 5.66199733579 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.66199733579 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.71599778093 )),
        "SpglibTestData/tetragonal/POSCAR-113-2": double3x3(SIMD3<Double>( 6.4023969874 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.4023969874 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.27859798674 )),
        "SpglibTestData/tetragonal/POSCAR-114": double3x3(SIMD3<Double>( 7.48399647847 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.48399647847 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.34899701253 )),
        "SpglibTestData/tetragonal/POSCAR-114-2": double3x3(SIMD3<Double>( 10.8099949134 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.8099949134 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.80999679561 )),
        "SpglibTestData/tetragonal/POSCAR-115": double3x3(SIMD3<Double>( 3.32699843451 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.32699843451 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.1509971057 )),
        "SpglibTestData/tetragonal/POSCAR-115-2": double3x3(SIMD3<Double>( 3.85899818418 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.85899818418 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.70999449 )),
        "SpglibTestData/tetragonal/POSCAR-115-3": double3x3(SIMD3<Double>( 2.33273548217 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 2.33273548217 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.78863344099 )),
        "SpglibTestData/tetragonal/POSCAR-115-4": double3x3(SIMD3<Double>( 5.01899763835 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.01899763835 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.42799603427 )),
        "SpglibTestData/tetragonal/POSCAR-115-5": double3x3(SIMD3<Double>( 3.73352204789 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.73352204789 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.20499755083 )),
        "SpglibTestData/tetragonal/POSCAR-116": double3x3(SIMD3<Double>( 5.52499740026 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.52499740026 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.4629917829 )),
        "SpglibTestData/tetragonal/POSCAR-116-2": double3x3(SIMD3<Double>( 10.5659950283 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.5659950283 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 25.2199881329 )),
        "SpglibTestData/tetragonal/POSCAR-117": double3x3(SIMD3<Double>( 7.7286734817 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.7286734817 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.61999735556 )),
        "SpglibTestData/tetragonal/POSCAR-117-2": double3x3(SIMD3<Double>( 5.70999731321 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.70999731321 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 16.4579922558 )),
        "SpglibTestData/tetragonal/POSCAR-118": double3x3(SIMD3<Double>( 6.59599689631 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.59599689631 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.16469756979 )),
        "SpglibTestData/tetragonal/POSCAR-118-2": double3x3(SIMD3<Double>( 7.82299631895 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.82299631895 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.05299574019 )),
        "SpglibTestData/tetragonal/POSCAR-119": double3x3(SIMD3<Double>( 6.26799705064 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.26799705064 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.7819930445 )),
        "SpglibTestData/tetragonal/POSCAR-119-2": double3x3(SIMD3<Double>( 3.91999815548 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.91999815548 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 15.2199928384 )),
        "SpglibTestData/tetragonal/POSCAR-120": double3x3(SIMD3<Double>( 8.46699601592 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.46699601592 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.7449940029 )),
        "SpglibTestData/tetragonal/POSCAR-120-2": double3x3(SIMD3<Double>( 12.4475941429 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.4475941429 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.927693917 )),
        "SpglibTestData/tetragonal/POSCAR-121": double3x3(SIMD3<Double>( 4.97599765858 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.97599765858 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.74599682573 )),
        "SpglibTestData/tetragonal/POSCAR-121-2": double3x3(SIMD3<Double>( 5.04699762518 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.04699762518 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.48599694807 )),
        "SpglibTestData/tetragonal/POSCAR-122": double3x3(SIMD3<Double>( 11.4839945963 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.4839945963 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.61999735556 )),
        "SpglibTestData/tetragonal/POSCAR-122-2": double3x3(SIMD3<Double>( 14.9329929734 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.9329929734 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 15.5469926845 )),
        "SpglibTestData/tetragonal/POSCAR-122-3": double3x3(SIMD3<Double>( 3.95768302129 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.95768302129 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.97647451992 )),
        "SpglibTestData/tetragonal/POSCAR-123": double3x3(SIMD3<Double>( 4.01899810889 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.01899810889 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.27899845709 )),
        "SpglibTestData/tetragonal/POSCAR-123-2": double3x3(SIMD3<Double>( 8.98099577406 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.98099577406 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.6379940533 )),
        "SpglibTestData/tetragonal/POSCAR-123-3": double3x3(SIMD3<Double>( 4.19999802372 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.19999802372 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.95999625449 )),
        "SpglibTestData/tetragonal/POSCAR-124": double3x3(SIMD3<Double>( 6.11799712123 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.11799712123 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.99599764917 )),
        "SpglibTestData/tetragonal/POSCAR-124-2": double3x3(SIMD3<Double>( 6.20999707794 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.20999707794 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0019948231 )),
        "SpglibTestData/tetragonal/POSCAR-125": double3x3(SIMD3<Double>( 8.51599599287 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.51599599287 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.71299684125 )),
        "SpglibTestData/tetragonal/POSCAR-125-2": double3x3(SIMD3<Double>( 6.37599699983 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.37599699983 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.32899608086 )),
        "SpglibTestData/tetragonal/POSCAR-126": double3x3(SIMD3<Double>( 11.3499946594 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.3499946594 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.18999708735 )),
        "SpglibTestData/tetragonal/POSCAR-126-2": double3x3(SIMD3<Double>( 6.31239702975 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.31239702975 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.54949550656 )),
        "SpglibTestData/tetragonal/POSCAR-127": double3x3(SIMD3<Double>( 5.89399722663 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.89399722663 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.34799607192 )),
        "SpglibTestData/tetragonal/POSCAR-127-2": double3x3(SIMD3<Double>( 7.1049966568 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.1049966568 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.14399805007 )),
        "SpglibTestData/tetragonal/POSCAR-128": double3x3(SIMD3<Double>( 7.05769667906 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.05769667906 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.97839530475 )),
        "SpglibTestData/tetragonal/POSCAR-128-2": double3x3(SIMD3<Double>( 7.74359635631 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.74359635631 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.6402945228 )),
        "SpglibTestData/tetragonal/POSCAR-129": double3x3(SIMD3<Double>( 4.28199798514 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.28199798514 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.18199709111 )),
        "SpglibTestData/tetragonal/POSCAR-129-2": double3x3(SIMD3<Double>( 5.00499764494 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.00499764494 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.80999773669 )),
        "SpglibTestData/tetragonal/POSCAR-129-3": double3x3(SIMD3<Double>( 4.28199798514 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.28199798514 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.18199709111 )),
        "SpglibTestData/tetragonal/POSCAR-130": double3x3(SIMD3<Double>( 5.92399721251 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.92399721251 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 18.1299914691 )),
        "SpglibTestData/tetragonal/POSCAR-130-2": double3x3(SIMD3<Double>( 7.37719652872 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.37719652872 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 15.1230928839 )),
        "SpglibTestData/tetragonal/POSCAR-131": double3x3(SIMD3<Double>( 3.01999857896 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.01999857896 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.30999750142 )),
        "SpglibTestData/tetragonal/POSCAR-131-2": double3x3(SIMD3<Double>( 4.92629768197 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.92629768197 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.28499610156 )),
        "SpglibTestData/tetragonal/POSCAR-132": double3x3(SIMD3<Double>( 6.16599709864 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.16599709864 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.05199715228 )),
        "SpglibTestData/tetragonal/POSCAR-132-2": double3x3(SIMD3<Double>( 5.85199724639 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.85199724639 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.2339933023 )),
        "SpglibTestData/tetragonal/POSCAR-133": double3x3(SIMD3<Double>( 9.38099558585 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.38099558585 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.66299780586 )),
        "SpglibTestData/tetragonal/POSCAR-133-2": double3x3(SIMD3<Double>( 11.7889944528 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.7889944528 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 23.6349888787 )),
        "SpglibTestData/tetragonal/POSCAR-134": double3x3(SIMD3<Double>( 8.42699603474 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.42699603474 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.4919931809 )),
        "SpglibTestData/tetragonal/POSCAR-134-2": double3x3(SIMD3<Double>( 6.16899709723 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.16899709723 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.21299707652 )),
        "SpglibTestData/tetragonal/POSCAR-135": double3x3(SIMD3<Double>( 8.58999595805 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.58999595805 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.91299721769 )),
        "SpglibTestData/tetragonal/POSCAR-135-2": double3x3(SIMD3<Double>( 8.52699598769 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.52699598769 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.94199720404 )),
        "SpglibTestData/tetragonal/POSCAR-136": double3x3(SIMD3<Double>( 4.39829793042 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.39829793042 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 2.87299864813 )),
        "SpglibTestData/tetragonal/POSCAR-136-2": double3x3(SIMD3<Double>( 4.5844978428 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.5844978428 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 2.95329861035 )),
        "SpglibTestData/tetragonal/POSCAR-136-3": double3x3(SIMD3<Double>( 4.22665401997 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.22665401997 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 2.68883592723 )),
        "SpglibTestData/tetragonal/POSCAR-136-4": double3x3(SIMD3<Double>( 4.66859780323 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.66859780323 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.21499754612 )),
        "SpglibTestData/tetragonal/POSCAR-136-5": double3x3(SIMD3<Double>( 6.75399682196 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.75399682196 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.10999806607 )),
        "SpglibTestData/tetragonal/POSCAR-137": double3x3(SIMD3<Double>( 8.08999619332 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.08999619332 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.44999743555 )),
        "SpglibTestData/tetragonal/POSCAR-137-2": double3x3(SIMD3<Double>( 3.63999828723 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 3.63999828723 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.26999752024 )),
        "SpglibTestData/tetragonal/POSCAR-137-3": double3x3(SIMD3<Double>( 2.24231466126 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 2.24231466126 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.85050892015 )),
        "SpglibTestData/tetragonal/POSCAR-138": double3x3(SIMD3<Double>( 8.43359603164 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.43359603164 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.67819638709 )),
        "SpglibTestData/tetragonal/POSCAR-138-2": double3x3(SIMD3<Double>( 4.34999795314 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.34999795314 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 13.7299935395 )),
        "SpglibTestData/tetragonal/POSCAR-139": double3x3(SIMD3<Double>( 11.9399943817 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.9399943817 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3999918126 )),
        "SpglibTestData/tetragonal/POSCAR-139-2": double3x3(SIMD3<Double>( 4.16999803784 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.16999803784 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.8799948805 )),
        "SpglibTestData/tetragonal/POSCAR-140": double3x3(SIMD3<Double>( 11.0759947883 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.0759947883 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 36.9329826215 )),
        "SpglibTestData/tetragonal/POSCAR-140-2": double3x3(SIMD3<Double>( 11.0119948184 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.0119948184 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.72699730521 )),
        "SpglibTestData/tetragonal/POSCAR-141": double3x3(SIMD3<Double>( 7.17719662283 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.17719662283 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.32889702199 )),
        "SpglibTestData/tetragonal/POSCAR-141-2": double3x3(SIMD3<Double>( 6.90129675265 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.90129675265 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 19.9753906007 )),
        "SpglibTestData/tetragonal/POSCAR-142": double3x3(SIMD3<Double>( 10.3299951393 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.3299951393 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 20.3799904104 )),
        "SpglibTestData/tetragonal/POSCAR-142-2": double3x3(SIMD3<Double>( 12.2839942199 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.2839942199 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 23.5819889037 )),
        "SpglibTestData/tetragonal/POSCAR-142-3": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 ))
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
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, symmetryPrecision: precision)
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
  
  func testFindTrigonalSpaceGroup()
  {
    let testData: [String: double3x3] =
      [
        "SpglibTestData/trigonal/POSCAR-143": double3x3(SIMD3<Double>( 7.24879658914 , 0.0 , 0.0 ), SIMD3<Double>( -3.62439829457 , 6.27764199306 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.78359680803 )),
        "SpglibTestData/trigonal/POSCAR-143-2": double3x3(SIMD3<Double>( 7.95418625722 , 0.0 , 0.0 ), SIMD3<Double>( -3.97709312861 , 6.88852736519 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.3612965362 )),
        "SpglibTestData/trigonal/POSCAR-144": double3x3(SIMD3<Double>( 6.86729676865 , 0.0 , 0.0 ), SIMD3<Double>( -3.43364838432 , 5.94725345698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.0619919716 )),
        "SpglibTestData/trigonal/POSCAR-144-2": double3x3(SIMD3<Double>( 4.33679795935 , 0.0 , 0.0 ), SIMD3<Double>( -2.16839897968 , 3.75577720388 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.33969607582 )),
        "SpglibTestData/trigonal/POSCAR-145": double3x3(SIMD3<Double>( 12.6919940279 , 0.0 , 0.0 ), SIMD3<Double>( -6.34599701394 , 10.9915892528 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 19.1859909722 )),
        "SpglibTestData/trigonal/POSCAR-145-2": double3x3(SIMD3<Double>( 10.5019950584 , 0.0 , 0.0 ), SIMD3<Double>( -5.25099752919 , 9.09499451097 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.47299648364 )),
        "SpglibTestData/trigonal/POSCAR-146": double3x3(SIMD3<Double>( 10.8369949007 , 0.0 , 0.0 ), SIMD3<Double>( -5.41849745037 , 9.38511288472 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.15699616179 )),
        "SpglibTestData/trigonal/POSCAR-146-2": double3x3(SIMD3<Double>( 5.99999717675 , 0.0 , 0.0 ), SIMD3<Double>( -2.99999858837 , 5.1961499777 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.3299932571 )),
        "SpglibTestData/trigonal/POSCAR-147": double3x3(SIMD3<Double>( 16.9905920052 , 0.0 , 0.0 ), SIMD3<Double>( -8.49529600261 , 14.7142843019 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.88879581745 )),
        "SpglibTestData/trigonal/POSCAR-147-2": double3x3(SIMD3<Double>( 9.3961955787 , 0.0 , 0.0 ), SIMD3<Double>( -4.69809778935 , 8.13734407008 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.22249660151 )),
        "SpglibTestData/trigonal/POSCAR-148": double3x3(SIMD3<Double>( 7.106696656 , 0.0 , 0.0 ), SIMD3<Double>( -3.553348328 , 6.15457984109 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.08669196 )),
        "SpglibTestData/trigonal/POSCAR-148-2": double3x3(SIMD3<Double>( 20.9739901309 , 0.0 , 0.0 ), SIMD3<Double>( -10.4869950654 , 18.164008272 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.1339942904 )),
        "SpglibTestData/trigonal/POSCAR-149": double3x3(SIMD3<Double>( 5.02199763694 , 0.0 , 0.0 ), SIMD3<Double>( -2.51099881847 , 4.34917753133 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.37599699983 )),
        "SpglibTestData/trigonal/POSCAR-149-2": double3x3(SIMD3<Double>( 7.15099663516 , 0.0 , 0.0 ), SIMD3<Double>( -3.57549831758 , 6.19294474842 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.17579615294 )),
        "SpglibTestData/trigonal/POSCAR-150": double3x3(SIMD3<Double>( 9.06999573219 , 0.0 , 0.0 ), SIMD3<Double>( -4.53499786609 , 7.85484671629 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.98399765482 )),
        "SpglibTestData/trigonal/POSCAR-150-2": double3x3(SIMD3<Double>( 8.63799593546 , 0.0 , 0.0 ), SIMD3<Double>( -4.31899796773 , 7.4807239179 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.73799777057 )),
        "SpglibTestData/trigonal/POSCAR-151": double3x3(SIMD3<Double>( 5.95999719557 , 0.0 , 0.0 ), SIMD3<Double>( -2.97999859779 , 5.16150897785 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.1999919067 )),
        "SpglibTestData/trigonal/POSCAR-151-2": double3x3(SIMD3<Double>( 5.03399763129 , 0.0 , 0.0 ), SIMD3<Double>( -2.51699881565 , 4.35956983129 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.1409933461 )),
        "SpglibTestData/trigonal/POSCAR-152": double3x3(SIMD3<Double>( 9.20399566913 , 0.0 , 0.0 ), SIMD3<Double>( -4.60199783457 , 7.97089406579 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 24.8179883221 )),
        "SpglibTestData/trigonal/POSCAR-152-2": double3x3(SIMD3<Double>( 5.03599763035 , 0.0 , 0.0 ), SIMD3<Double>( -2.51799881518 , 4.36130188128 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.2549947041 )),
        "SpglibTestData/trigonal/POSCAR-153": double3x3(SIMD3<Double>( 6.01999716734 , 0.0 , 0.0 ), SIMD3<Double>( -3.00999858367 , 5.21347047763 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.2999918596 )),
        "SpglibTestData/trigonal/POSCAR-154": double3x3(SIMD3<Double>( 4.91339768804 , 0.0 , 0.0 ), SIMD3<Double>( -2.45669884402 , 4.25512721674 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.40519745663 )),
        "SpglibTestData/trigonal/POSCAR-154-2": double3x3(SIMD3<Double>( 13.0399938641 , 0.0 , 0.0 ), SIMD3<Double>( -6.51999693207 , 11.2929659515 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.39999604745 )),
        "SpglibTestData/trigonal/POSCAR-154-3": double3x3(SIMD3<Double>( 4.06285842998 , 0.0 , 0.0 ), SIMD3<Double>( -2.03142921499 , 3.51853861234 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.6155767045 )),
        "SpglibTestData/trigonal/POSCAR-155": double3x3(SIMD3<Double>( 9.34159560439 , 0.0 , 0.0 ), SIMD3<Double>( -4.67079780219 , 8.09005910528 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.30549656246 )),
        "SpglibTestData/trigonal/POSCAR-155-2": double3x3(SIMD3<Double>( 9.12299570725 , 0.0 , 0.0 ), SIMD3<Double>( -4.56149785362 , 7.90074604109 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 16.9829920088 )),
        "SpglibTestData/trigonal/POSCAR-156": double3x3(SIMD3<Double>( 3.73329824333 , 0.0 , 0.0 ), SIMD3<Double>( -1.86664912166 , 3.23313111862 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.09799713064 )),
        "SpglibTestData/trigonal/POSCAR-156-2": double3x3(SIMD3<Double>( 3.91499815783 , 0.0 , 0.0 ), SIMD3<Double>( -1.95749907891 , 3.39048786045 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.7249940124 )),
        "SpglibTestData/trigonal/POSCAR-157": double3x3(SIMD3<Double>( 12.1969942608 , 0.0 , 0.0 ), SIMD3<Double>( -6.0984971304 , 10.5629068797 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 19.3589908908 )),
        "SpglibTestData/trigonal/POSCAR-157-2": double3x3(SIMD3<Double>( 8.75299588135 , 0.0 , 0.0 ), SIMD3<Double>( -4.37649794067 , 7.58031679247 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.96599813383 )),
        "SpglibTestData/trigonal/POSCAR-158": double3x3(SIMD3<Double>( 6.11999712028 , 0.0 , 0.0 ), SIMD3<Double>( -3.05999856014 , 5.30007297725 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.65799733767 )),
        "SpglibTestData/trigonal/POSCAR-158-2": double3x3(SIMD3<Double>( 12.8739939422 , 0.0 , 0.0 ), SIMD3<Double>( -6.43699697112 , 11.1492058022 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.23899565266 )),
        "SpglibTestData/trigonal/POSCAR-159": double3x3(SIMD3<Double>( 10.1999952005 , 0.0 , 0.0 ), SIMD3<Double>( -5.09999760024 , 8.83345496209 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 30.3509857186 )),
        "SpglibTestData/trigonal/POSCAR-159-2": double3x3(SIMD3<Double>( 10.5629950297 , 0.0 , 0.0 ), SIMD3<Double>( -5.28149751483 , 9.14782203574 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.36799747413 )),
        "SpglibTestData/trigonal/POSCAR-160": double3x3(SIMD3<Double>( 12.7256432997 , 0.0 , 0.0 ), SIMD3<Double>( -6.36282164985 , 11.020730377 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.902516431 )),
        "SpglibTestData/trigonal/POSCAR-160-2": double3x3(SIMD3<Double>( 5.48699741814 , 0.0 , 0.0 ), SIMD3<Double>( -2.74349870907 , 4.75187915461 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.15599569172 )),
        "SpglibTestData/trigonal/POSCAR-161": double3x3(SIMD3<Double>( 10.4379950885 , 0.0 , 0.0 ), SIMD3<Double>( -5.21899754424 , 9.03956891121 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 37.1499825194 )),
        "SpglibTestData/trigonal/POSCAR-161-2": double3x3(SIMD3<Double>( 5.159997572 , 0.0 , 0.0 ), SIMD3<Double>( -2.579998786 , 4.46868898082 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 16.5799921984 )),
        "SpglibTestData/trigonal/POSCAR-162": double3x3(SIMD3<Double>( 5.44999743555 , 0.0 , 0.0 ), SIMD3<Double>( -2.72499871777 , 4.71983622974 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.10099618814 )),
        "SpglibTestData/trigonal/POSCAR-162-2": double3x3(SIMD3<Double>( 4.989997652 , 0.0 , 0.0 ), SIMD3<Double>( -2.494998826 , 4.32146473145 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.62199782516 )),
        "SpglibTestData/trigonal/POSCAR-163": double3x3(SIMD3<Double>( 5.88999722851 , 0.0 , 0.0 ), SIMD3<Double>( -2.94499861425 , 5.10088722811 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.59099548703 )),
        "SpglibTestData/trigonal/POSCAR-163-2": double3x3(SIMD3<Double>( 5.30999750142 , 0.0 , 0.0 ), SIMD3<Double>( -2.65499875071 , 4.59859273026 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.2499932948 )),
        "SpglibTestData/trigonal/POSCAR-164": double3x3(SIMD3<Double>( 4.04699809572 , 0.0 , 0.0 ), SIMD3<Double>( -2.02349904786 , 3.50480315996 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.32999749201 )),
        "SpglibTestData/trigonal/POSCAR-164-2": double3x3(SIMD3<Double>( 6.24899705958 , 0.0 , 0.0 ), SIMD3<Double>( -3.12449852979 , 5.41179020177 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.08599760682 )),
        "SpglibTestData/trigonal/POSCAR-165": double3x3(SIMD3<Double>( 7.18499661916 , 0.0 , 0.0 ), SIMD3<Double>( -3.59249830958 , 6.2223895983 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.35099654105 )),
        "SpglibTestData/trigonal/POSCAR-165-2": double3x3(SIMD3<Double>( 12.1899942641 , 0.0 , 0.0 ), SIMD3<Double>( -6.09499713205 , 10.5568447047 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.1399952287 )),
        "SpglibTestData/trigonal/POSCAR-166": double3x3(SIMD3<Double>( 6.24299706241 , 0.0 , 0.0 ), SIMD3<Double>( -3.1214985312 , 5.4065940518 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 29.9999858837 )),
        "SpglibTestData/trigonal/POSCAR-166-2": double3x3(SIMD3<Double>( 5.42499744731 , 0.0 , 0.0 ), SIMD3<Double>( -2.71249872366 , 4.69818560484 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.83599537175 )),
        "SpglibTestData/trigonal/POSCAR-167": double3x3(SIMD3<Double>( 11.5099945841 , 0.0 , 0.0 ), SIMD3<Double>( -5.75499729203 , 9.96794770722 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 60.5699714993 )),
        "SpglibTestData/trigonal/POSCAR-167-2": double3x3(SIMD3<Double>( 10.0229952838 , 0.0 , 0.0 ), SIMD3<Double>( -5.01149764188 , 8.68016853775 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 25.4709880148 )),
        "SpglibTestData/trigonal/POSCAR-167-3": double3x3(SIMD3<Double>( 4.94919767119 , 0.0 , 0.0 ), SIMD3<Double>( -2.4745988356 , 4.28613091161 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 13.9979934134 ))
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
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, symmetryPrecision: precision)
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
  
  func testFindHexagonalSpaceGroup()
  {
    let testData: [String: double3x3] =
      [
        "SpglibTestData/hexagonal/POSCAR-168": double3x3(SIMD3<Double>( 15.9359925014 , 0.0 , 0.0 ), SIMD3<Double>( -7.96799625072 , 13.8009743408 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.89199816865 )),
        "SpglibTestData/hexagonal/POSCAR-169": double3x3(SIMD3<Double>( 7.10999665445 , 0.0 , 0.0 ), SIMD3<Double>( -3.55499832722 , 6.15743772357 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 19.3399908997 )),
        "SpglibTestData/hexagonal/POSCAR-169-2": double3x3(SIMD3<Double>( 9.70899543151 , 0.0 , 0.0 ), SIMD3<Double>( -4.85449771575 , 8.40823668891 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 19.3429908983 )),
        "SpglibTestData/hexagonal/POSCAR-170": double3x3(SIMD3<Double>( 7.10999665445 , 0.0 , 0.0 ), SIMD3<Double>( -3.55499832722 , 6.15743772357 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 19.2999909185 )),
        "SpglibTestData/hexagonal/POSCAR-170-2": double3x3(SIMD3<Double>( 10.5125950534 , 0.0 , 0.0 ), SIMD3<Double>( -5.25629752669 , 9.10417437593 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.9375929712 )),
        "SpglibTestData/hexagonal/POSCAR-171": double3x3(SIMD3<Double>( 17.3899918173 , 0.0 , 0.0 ), SIMD3<Double>( -8.69499590864 , 15.0601746854 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 13.035993866 )),
        "SpglibTestData/hexagonal/POSCAR-171-2": double3x3(SIMD3<Double>( 6.31999702618 , 0.0 , 0.0 ), SIMD3<Double>( -3.15999851309 , 5.47327797651 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 19.2899909232 )),
        "SpglibTestData/hexagonal/POSCAR-172": double3x3(SIMD3<Double>( 6.19799708358 , 0.0 , 0.0 ), SIMD3<Double>( -3.09899854179 , 5.36762292696 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 18.7269911882 )),
        "SpglibTestData/hexagonal/POSCAR-173": double3x3(SIMD3<Double>( 7.13299664363 , 0.0 , 0.0 ), SIMD3<Double>( -3.56649832181 , 6.17735629849 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.4139965114 )),
        "SpglibTestData/hexagonal/POSCAR-173-2": double3x3(SIMD3<Double>( 9.22499565925 , 0.0 , 0.0 ), SIMD3<Double>( -4.61249782963 , 7.98908059071 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.22399754189 )),
        "SpglibTestData/hexagonal/POSCAR-174": double3x3(SIMD3<Double>( 10.2742951655 , 0.0 , 0.0 ), SIMD3<Double>( -5.13714758276 , 8.89780061931 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.98749812371 )),
        "SpglibTestData/hexagonal/POSCAR-174-2": double3x3(SIMD3<Double>( 12.3199942029 , 0.0 , 0.0 ), SIMD3<Double>( -6.15999710146 , 10.6694279542 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.87999535105 )),
        "SpglibTestData/hexagonal/POSCAR-175": double3x3(SIMD3<Double>( 12.6520940467 , 0.0 , 0.0 ), SIMD3<Double>( -6.32604702333 , 10.9570348555 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.13809570014 )),
        "SpglibTestData/hexagonal/POSCAR-175-2": double3x3(SIMD3<Double>( 5.45899743131 , 0.0 , 0.0 ), SIMD3<Double>( -2.72949871566 , 4.72763045471 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.17899709252 )),
        "SpglibTestData/hexagonal/POSCAR-176": double3x3(SIMD3<Double>( 6.41799698006 , 0.0 , 0.0 ), SIMD3<Double>( -3.20899849003 , 5.55814842615 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.74299823876 )),
        "SpglibTestData/hexagonal/POSCAR-176-2": double3x3(SIMD3<Double>( 11.6699945088 , 0.0 , 0.0 ), SIMD3<Double>( -5.83499725439 , 10.1065117066 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.94999531811 )),
        "SpglibTestData/hexagonal/POSCAR-177": double3x3(SIMD3<Double>( 6.34129701615 , 0.0 , 0.0 ), SIMD3<Double>( -3.17064850808 , 5.49172430893 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.46219695926 )),
        "SpglibTestData/hexagonal/POSCAR-179": double3x3(SIMD3<Double>( 7.22129660208 , 0.0 , 0.0 ), SIMD3<Double>( -3.61064830104 , 6.25382630566 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.90719674987 )),
        "SpglibTestData/hexagonal/POSCAR-179-2": double3x3(SIMD3<Double>( 10.4119951007 , 0.0 , 0.0 ), SIMD3<Double>( -5.20599755036 , 9.0170522613 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 15.1839928553 )),
        "SpglibTestData/hexagonal/POSCAR-180": double3x3(SIMD3<Double>( 4.81899773246 , 0.0 , 0.0 ), SIMD3<Double>( -2.40949886623 , 4.17337445709 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.59199689819 )),
        "SpglibTestData/hexagonal/POSCAR-180-2": double3x3(SIMD3<Double>( 4.89999769435 , 0.0 , 0.0 ), SIMD3<Double>( -2.44999884717 , 4.24352248179 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.37999746849 )),
        "SpglibTestData/hexagonal/POSCAR-181": double3x3(SIMD3<Double>( 4.4282979163 , 0.0 , 0.0 ), SIMD3<Double>( -2.21414895815 , 3.83501849104 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.36799700359 )),
        "SpglibTestData/hexagonal/POSCAR-181-2": double3x3(SIMD3<Double>( 10.4817950679 , 0.0 , 0.0 ), SIMD3<Double>( -5.24089753394 , 9.07750080604 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.1749947417 )),
        "SpglibTestData/hexagonal/POSCAR-182": double3x3(SIMD3<Double>( 5.30999750142 , 0.0 , 0.0 ), SIMD3<Double>( -2.65499875071 , 4.59859273026 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.2499932948 )),
        "SpglibTestData/hexagonal/POSCAR-182-2": double3x3(SIMD3<Double>( 5.45799743178 , 0.0 , 0.0 ), SIMD3<Double>( -2.72899871589 , 4.72676442971 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.0159957576 )),
        "SpglibTestData/hexagonal/POSCAR-183": double3x3(SIMD3<Double>( 19.4999908244 , 0.0 , 0.0 ), SIMD3<Double>( -9.74999541222 , 16.8874874275 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.2999951534 )),
        "SpglibTestData/hexagonal/POSCAR-183-2": double3x3(SIMD3<Double>( 3.39599840204 , 0.0 , 0.0 ), SIMD3<Double>( -1.69799920102 , 2.94102088738 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.091997604 )),
        "SpglibTestData/hexagonal/POSCAR-184": double3x3(SIMD3<Double>( 13.7179935451 , 0.0 , 0.0 ), SIMD3<Double>( -6.85899677255 , 11.880130899 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.4525960227 )),
        "SpglibTestData/hexagonal/POSCAR-184-2": double3x3(SIMD3<Double>( 13.8019935056 , 0.0 , 0.0 ), SIMD3<Double>( -6.90099675279 , 11.9528769987 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.50299599898 )),
        "SpglibTestData/hexagonal/POSCAR-185": double3x3(SIMD3<Double>( 9.88499534869 , 0.0 , 0.0 ), SIMD3<Double>( -4.94249767435 , 8.56065708826 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.8049949158 )),
        "SpglibTestData/hexagonal/POSCAR-185-2": double3x3(SIMD3<Double>( 6.25999705441 , 0.0 , 0.0 ), SIMD3<Double>( -3.1299985272 , 5.42131647673 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.2489942363 )),
        "SpglibTestData/hexagonal/POSCAR-186": double3x3(SIMD3<Double>( 9.97999530399 , 0.0 , 0.0 ), SIMD3<Double>( -4.989997652 , 8.64292946291 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.63999640506 )),
        "SpglibTestData/hexagonal/POSCAR-186-2": double3x3(SIMD3<Double>( 8.09999618861 , 0.0 , 0.0 ), SIMD3<Double>( -4.04999809431 , 7.01480246989 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 13.339993723 )),
        "SpglibTestData/hexagonal/POSCAR-187": double3x3(SIMD3<Double>( 2.90649863237 , 0.0 , 0.0 ), SIMD3<Double>( -1.45324931619 , 2.5171016517 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 2.83659866526 )),
        "SpglibTestData/hexagonal/POSCAR-187-2": double3x3(SIMD3<Double>( 5.44799743649 , 0.0 , 0.0 ), SIMD3<Double>( -2.72399871824 , 4.71810417975 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.09099619285 )),
        "SpglibTestData/hexagonal/POSCAR-188": double3x3(SIMD3<Double>( 6.11999712028 , 0.0 , 0.0 ), SIMD3<Double>( -3.05999856014 , 5.30007297725 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.65799733767 )),
        "SpglibTestData/hexagonal/POSCAR-188-2": double3x3(SIMD3<Double>( 9.21799566255 , 0.0 , 0.0 ), SIMD3<Double>( -4.60899783127 , 7.98301841574 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 18.0419915105 )),
        "SpglibTestData/hexagonal/POSCAR-189": double3x3(SIMD3<Double>( 8.1539961632 , 0.0 , 0.0 ), SIMD3<Double>( -4.0769980816 , 7.06156781969 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.13699711229 )),
        "SpglibTestData/hexagonal/POSCAR-189-2": double3x3(SIMD3<Double>( 9.64999545927 , 0.0 , 0.0 ), SIMD3<Double>( -4.82499772964 , 8.35714121413 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.85699818512 )),
        "SpglibTestData/hexagonal/POSCAR-190": double3x3(SIMD3<Double>( 4.59609783734 , 0.0 , 0.0 ), SIMD3<Double>( -2.29804891867 , 3.98033748542 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.92999579806 )),
        "SpglibTestData/hexagonal/POSCAR-190-2": double3x3(SIMD3<Double>( 10.5609950306 , 0.0 , 0.0 ), SIMD3<Double>( -5.2804975153 , 9.14608998575 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 13.5219936373 )),
        "SpglibTestData/hexagonal/POSCAR-191": double3x3(SIMD3<Double>( 3.95999813665 , 0.0 , 0.0 ), SIMD3<Double>( -1.97999906833 , 3.42945898528 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 3.84399819124 )),
        "SpglibTestData/hexagonal/POSCAR-191-2": double3x3(SIMD3<Double>( 11.2569947031 , 0.0 , 0.0 ), SIMD3<Double>( -5.62849735156 , 9.74884338316 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.85299724592 )),
        "SpglibTestData/hexagonal/POSCAR-192": double3x3(SIMD3<Double>( 10.4569950795 , 0.0 , 0.0 ), SIMD3<Double>( -5.22849753977 , 9.05602338613 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.2379933004 )),
        "SpglibTestData/hexagonal/POSCAR-192-2": double3x3(SIMD3<Double>( 9.76829540361 , 0.0 , 0.0 ), SIMD3<Double>( -4.8841477018 , 8.45959197119 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.34079560476 )),
        "SpglibTestData/hexagonal/POSCAR-193": double3x3(SIMD3<Double>( 8.4899960051 , 0.0 , 0.0 ), SIMD3<Double>( -4.24499800255 , 7.35255221845 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.08399713722 )),
        "SpglibTestData/hexagonal/POSCAR-193-2": double3x3(SIMD3<Double>( 9.74899541269 , 0.0 , 0.0 ), SIMD3<Double>( -4.87449770634 , 8.44287768877 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 16.4699922502 )),
        "SpglibTestData/hexagonal/POSCAR-194": double3x3(SIMD3<Double>( 3.58699831217 , 0.0 , 0.0 ), SIMD3<Double>( -1.79349915608 , 3.10643166167 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 15.4919927104 )),
        "SpglibTestData/hexagonal/POSCAR-194-2": double3x3(SIMD3<Double>( 3.46999836722 , 0.0 , 0.0 ), SIMD3<Double>( -1.73499918361 , 3.0051067371 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 28.4499866131 ))
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
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, symmetryPrecision: precision)
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
  func testFindCubicSpaceGroup()
  {
    let testData: [String: double3x3] =
      [
        "SpglibTestData/cubic/POSCAR-195": double3x3(SIMD3<Double>( 10.3499951299 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.3499951299 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.3499951299 )),
        "SpglibTestData/cubic/POSCAR-195-2": double3x3(SIMD3<Double>( 7.26599658104 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.26599658104 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.26599658104 )),
        "SpglibTestData/cubic/POSCAR-196": double3x3(SIMD3<Double>( 12.153994281 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.153994281 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.153994281 )),
        "SpglibTestData/cubic/POSCAR-196-2": double3x3(SIMD3<Double>( 18.7499911773 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.7499911773 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 18.7499911773 )),
        "SpglibTestData/cubic/POSCAR-197": double3x3(SIMD3<Double>( 10.1453952262 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.1453952262 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.1453952262 )),
        "SpglibTestData/cubic/POSCAR-197-2": double3x3(SIMD3<Double>( 10.2499951769 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.2499951769 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.2499951769 )),
        "SpglibTestData/cubic/POSCAR-198": double3x3(SIMD3<Double>( 7.83999631095 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.83999631095 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.83999631095 )),
        "SpglibTestData/cubic/POSCAR-198-2": double3x3(SIMD3<Double>( 12.7529939992 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.7529939992 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.7529939992 )),
        "SpglibTestData/cubic/POSCAR-199": double3x3(SIMD3<Double>( 10.929994857 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.929994857 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.929994857 )),
        "SpglibTestData/cubic/POSCAR-199-2": double3x3(SIMD3<Double>( 8.41899603851 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.41899603851 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.41899603851 )),
        "SpglibTestData/cubic/POSCAR-200": double3x3(SIMD3<Double>( 7.48699647705 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.48699647705 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.48699647705 )),
        "SpglibTestData/cubic/POSCAR-200-2": double3x3(SIMD3<Double>( 5.44999743555 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.44999743555 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.44999743555 )),
        "SpglibTestData/cubic/POSCAR-205": double3x3(SIMD3<Double>( 5.62399735367 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.62399735367 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.62399735367 )),
        "SpglibTestData/cubic/POSCAR-205-3": double3x3(SIMD3<Double>( 5.62399735367 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.62399735367 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.62399735367 )),
        "SpglibTestData/cubic/POSCAR-206": double3x3(SIMD3<Double>( 10.9799948335 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.9799948335 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.9799948335 )),
        "SpglibTestData/cubic/POSCAR-206-2": double3x3(SIMD3<Double>( 11.0299948099 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.0299948099 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0299948099 )),
        "SpglibTestData/cubic/POSCAR-207": double3x3(SIMD3<Double>( 4.39999792962 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.39999792962 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.39999792962 )),
        "SpglibTestData/cubic/POSCAR-208": double3x3(SIMD3<Double>( 6.30999703088 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.30999703088 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.30999703088 )),
        "SpglibTestData/cubic/POSCAR-208-2": double3x3(SIMD3<Double>( 9.54299550962 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.54299550962 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.54299550962 )),
        "SpglibTestData/cubic/POSCAR-209": double3x3(SIMD3<Double>( 7.42299650717 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.42299650717 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.42299650717 )),
        "SpglibTestData/cubic/POSCAR-210": double3x3(SIMD3<Double>( 19.9099906315 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 19.9099906315 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 19.9099906315 )),
        "SpglibTestData/cubic/POSCAR-210-2": double3x3(SIMD3<Double>( 15.698992613 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 15.698992613 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 15.698992613 )),
        "SpglibTestData/cubic/POSCAR-211": double3x3(SIMD3<Double>( 9.68879544101 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.68879544101 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.68879544101 )),
        "SpglibTestData/cubic/POSCAR-212": double3x3(SIMD3<Double>( 6.71499684031 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.71499684031 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.71499684031 )),
        "SpglibTestData/cubic/POSCAR-212-2": double3x3(SIMD3<Double>( 6.71499684031 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.71499684031 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.71499684031 )),
        "SpglibTestData/cubic/POSCAR-213": double3x3(SIMD3<Double>( 10.2799951628 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.2799951628 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.2799951628 )),
        "SpglibTestData/cubic/POSCAR-213-2": double3x3(SIMD3<Double>( 7.93599626578 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.93599626578 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.93599626578 )),
        "SpglibTestData/cubic/POSCAR-214": double3x3(SIMD3<Double>( 21.759989761 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 21.759989761 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 21.759989761 )),
        "SpglibTestData/cubic/POSCAR-214-2": double3x3(SIMD3<Double>( 12.3149942053 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.3149942053 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.3149942053 )),
        "SpglibTestData/cubic/POSCAR-215": double3x3(SIMD3<Double>( 5.39299746237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.39299746237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.39299746237 )),
        "SpglibTestData/cubic/POSCAR-215-2": double3x3(SIMD3<Double>( 8.31999608509 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.31999608509 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.31999608509 )),
        "SpglibTestData/cubic/POSCAR-216": double3x3(SIMD3<Double>( 7.17599662339 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.17599662339 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.17599662339 )),
        "SpglibTestData/cubic/POSCAR-216-2": double3x3(SIMD3<Double>( 7.5769964347 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 7.5769964347 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 7.5769964347 )),
        "SpglibTestData/cubic/POSCAR-217": double3x3(SIMD3<Double>( 12.6999940241 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.6999940241 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.6999940241 )),
        "SpglibTestData/cubic/POSCAR-217-2": double3x3(SIMD3<Double>( 10.1679952155 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.1679952155 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.1679952155 )),
        "SpglibTestData/cubic/POSCAR-218": double3x3(SIMD3<Double>( 8.29399609733 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.29399609733 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.29399609733 )),
        "SpglibTestData/cubic/POSCAR-218-2": double3x3(SIMD3<Double>( 6.02599716452 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.02599716452 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.02599716452 )),
        "SpglibTestData/cubic/POSCAR-219": double3x3(SIMD3<Double>( 17.3439918389 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 17.3439918389 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3439918389 )),
        "SpglibTestData/cubic/POSCAR-219-2": double3x3(SIMD3<Double>( 12.1409942872 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.1409942872 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.1409942872 )),
        "SpglibTestData/cubic/POSCAR-220": double3x3(SIMD3<Double>( 9.81799538022 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.81799538022 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.81799538022 )),
        "SpglibTestData/cubic/POSCAR-220-2": double3x3(SIMD3<Double>( 8.5339959844 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.5339959844 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.5339959844 )),
        "SpglibTestData/cubic/POSCAR-221": double3x3(SIMD3<Double>( 9.63799546492 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.63799546492 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.63799546492 )),
        "SpglibTestData/cubic/POSCAR-221-2": double3x3(SIMD3<Double>( 5.79499727321 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.79499727321 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.79499727321 )),
        "SpglibTestData/cubic/POSCAR-222": double3x3(SIMD3<Double>( 10.9899948287 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.9899948287 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.9899948287 )),
        "SpglibTestData/cubic/POSCAR-222-2": double3x3(SIMD3<Double>( 16.2559923509 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 16.2559923509 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 16.2559923509 )),
        "SpglibTestData/cubic/POSCAR-223": double3x3(SIMD3<Double>( 6.66999686149 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.66999686149 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.66999686149 )),
        "SpglibTestData/cubic/POSCAR-223-2": double3x3(SIMD3<Double>( 10.2999951534 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.2999951534 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.2999951534 )),
        "SpglibTestData/cubic/POSCAR-224": double3x3(SIMD3<Double>( 4.90399769246 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.90399769246 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.90399769246 )),
        "SpglibTestData/cubic/POSCAR-224-2": double3x3(SIMD3<Double>( 4.90399769246 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 4.90399769246 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 4.90399769246 )),
        "SpglibTestData/cubic/POSCAR-225": double3x3(SIMD3<Double>( 9.98999529929 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 9.98999529929 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 9.98999529929 )),
        "SpglibTestData/cubic/POSCAR-225-2": double3x3(SIMD3<Double>( 8.19299614485 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.19299614485 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.19299614485 )),
        "SpglibTestData/cubic/POSCAR-226": double3x3(SIMD3<Double>( 25.0599882082 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 25.0599882082 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 25.0599882082 )),
        "SpglibTestData/cubic/POSCAR-226-2": double3x3(SIMD3<Double>( 10.0459952729 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0459952729 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0459952729 )),
        "SpglibTestData/cubic/POSCAR-227": double3x3(SIMD3<Double>( 10.1299952334 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.1299952334 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.1299952334 )),
        "SpglibTestData/cubic/POSCAR-227-2": double3x3(SIMD3<Double>( 23.2549890576 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 23.2549890576 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 23.2549890576 )),
        "SpglibTestData/cubic/POSCAR-228": double3x3(SIMD3<Double>( 15.7049926101 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 15.7049926101 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 15.7049926101 )),
        "SpglibTestData/cubic/POSCAR-228-2": double3x3(SIMD3<Double>( 21.8099897375 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 21.8099897375 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 21.8099897375 )),
        "SpglibTestData/cubic/POSCAR-229": double3x3(SIMD3<Double>( 18.2699914032 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.2699914032 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 18.2699914032 )),
        "SpglibTestData/cubic/POSCAR-229-2": double3x3(SIMD3<Double>( 6.22099707276 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 6.22099707276 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 6.22099707276 )),
        "SpglibTestData/cubic/POSCAR-230": double3x3(SIMD3<Double>( 12.6019940702 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.6019940702 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.6019940702 )),
        "SpglibTestData/cubic/POSCAR-230-2": double3x3(SIMD3<Double>( 12.3759941766 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.3759941766 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.3759941766 )),
        "SpglibTestData/cubic/POSCAR-230-3": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/cubic/POSCAR-230-4": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 ))
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
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, symmetryPrecision: precision)
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
  func testFindVirtualSpaceGroup()
  {
    let testData: [String: double3x3] =
      [
        "SpglibTestData/virtual_structure/POSCAR-1-221-33": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 6.12323399574e-16 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-1-222-33": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 6.12323399574e-16 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-1-223-33": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 6.12323399574e-16 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-1-224-33": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 6.12323399574e-16 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-1-227-73": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 2.91327993849 , 5.04594887013 , 0.0 ), SIMD3<Double>( 2.91327993849 , 1.68198295671 , 4.75736621812 )),
        "SpglibTestData/virtual_structure/POSCAR-1-227-93": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 3.56773895169e-16 , 5.82655987698 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 5.04554481249e-16 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-1-227-99": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 8.24 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 5.04554481249e-16 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-1-230-conv-56": double3x3(SIMD3<Double>( 11.0907889746 , 0.0 , 0.0 ), SIMD3<Double>( -3.69692965819 , 10.4564961235 , 0.0 ), SIMD3<Double>( -3.69692965819 , -5.22824806176 , 9.05559127754 )),
        "SpglibTestData/virtual_structure/POSCAR-1-230-prim-33": double3x3(SIMD3<Double>( 11.0907889746 , 0.0 , 0.0 ), SIMD3<Double>( -3.69692965819 , 10.4564961235 , 0.0 ), SIMD3<Double>( -3.69692965819 , -5.22824806176 , 9.05559127754 )),
        "SpglibTestData/virtual_structure/POSCAR-1-bcc-33": double3x3(SIMD3<Double>( 11.0907889746 , 0.0 , 0.0 ), SIMD3<Double>( -3.69692965819 , 10.4564961235 , 0.0 ), SIMD3<Double>( -3.69692965819 , -5.22824806176 , 9.05559127754 )),
        "SpglibTestData/virtual_structure/POSCAR-10-221-18": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-10-223-18": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-10-227-50": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-102-224-13": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-104-222-13": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-105-223-13": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-109-227-13": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-11-227-48": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-110-230-conv-15": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-110-230-prim-13": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-111-221-11": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-111-224-11": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-111-227-66": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-112-222-11": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-112-223-11": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-113-227-68": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-115-221-14": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-115-223-14": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-115-227-33": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-116-230-conv-34": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-117-230-conv-33": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-118-222-14": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-118-224-14": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-12-221-19": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-12-224-19": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        //"SpglibTestData/virtual_structure/POSCAR-12-227-21": double3x3(SIMD3<Double>( 10.0918977403 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( -3.36396591342 , 0.0 , 4.75736621812 )),
        "SpglibTestData/virtual_structure/POSCAR-12-227-83": double3x3(SIMD3<Double>( 11.653119754 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.653119754 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-120-230-conv-16": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-120-230-prim-14": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-122-230-conv-13": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-122-230-prim-11": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-123-221-05": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-126-222-05": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-13-222-18": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( -10.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-13-224-18": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( -10.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-13-227-49": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( -5.82655987698 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-13-230-conv-44": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 7.84174410958e-16 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-131-223-05": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-134-224-05": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-14-227-47": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 3.56773895169e-16 , 0.0 , 5.82655987698 )),
        "SpglibTestData/virtual_structure/POSCAR-14-227-51": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( -5.82655987698 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-14-230-conv-45": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 7.84174410958e-16 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-142-230-conv-05": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-142-230-prim-05": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-146-221-27": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-146-222-27": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-146-223-27": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-146-224-27": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-146-227-92": double3x3(SIMD3<Double>( 11.653119754 , 0.0 , 0.0 ), SIMD3<Double>( -5.82655987698 , 10.0918977403 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.2720986544 )),
        "SpglibTestData/virtual_structure/POSCAR-146-230-conv-36": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0907889746 )),
        "SpglibTestData/virtual_structure/POSCAR-146-230-conv-55": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 22.1815779492 )),
        "SpglibTestData/virtual_structure/POSCAR-146-230-prim-27": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0907889746 )),
        "SpglibTestData/virtual_structure/POSCAR-146-bcc-27": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0907889746 )),
        "SpglibTestData/virtual_structure/POSCAR-148-221-15": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-148-222-15": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-148-223-15": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-148-224-15": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-148-227-70": double3x3(SIMD3<Double>( 11.653119754 , 0.0 , 0.0 ), SIMD3<Double>( -5.82655987698 , 10.0918977403 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.2720986544 )),
        "SpglibTestData/virtual_structure/POSCAR-148-230-conv-17": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0907889746 )),
        "SpglibTestData/virtual_structure/POSCAR-148-230-conv-37": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 22.1815779492 )),
        "SpglibTestData/virtual_structure/POSCAR-148-230-prim-15": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0907889746 )),
        "SpglibTestData/virtual_structure/POSCAR-148-bcc-15": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0907889746 )),
        "SpglibTestData/virtual_structure/POSCAR-15-222-19": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-15-223-19": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        //"SpglibTestData/virtual_structure/POSCAR-15-230-conv-21": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( -9.05559127754 , 0.0 , 9.05559127754 )),
        //"SpglibTestData/virtual_structure/POSCAR-15-230-conv-22": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( -6.40327 , 0.0 , 9.05559127754 )),
        //"SpglibTestData/virtual_structure/POSCAR-15-230-prim-18": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( -9.05559127754 , 0.0 , 9.05559127754 )),
        //"SpglibTestData/virtual_structure/POSCAR-15-230-prim-19": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( -6.40327 , 0.0 , 9.05559127754 )),
        //"SpglibTestData/virtual_structure/POSCAR-15-bcc-18": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( -9.05559127754 , 0.0 , 9.05559127754 )),
        //"SpglibTestData/virtual_structure/POSCAR-15-bcc-19": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( -6.40327 , 0.0 , 9.05559127754 )),
        "SpglibTestData/virtual_structure/POSCAR-155-221-17": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-155-222-17": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-155-223-17": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-155-224-17": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-155-227-72": double3x3(SIMD3<Double>( 11.653119754 , 0.0 , 0.0 ), SIMD3<Double>( -5.82655987698 , 10.0918977403 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.2720986544 )),
        "SpglibTestData/virtual_structure/POSCAR-155-230-conv-19": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0907889746 )),
        "SpglibTestData/virtual_structure/POSCAR-155-230-conv-38": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 22.1815779492 )),
        "SpglibTestData/virtual_structure/POSCAR-155-230-prim-17": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0907889746 )),
        "SpglibTestData/virtual_structure/POSCAR-155-bcc-17": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0907889746 )),
        "SpglibTestData/virtual_structure/POSCAR-16-221-20": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-16-222-20": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-16-223-20": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-16-224-20": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-16-227-84": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-160-221-16": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-160-224-16": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-160-227-16": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( -2.91327993849 , 5.04594887013 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.2720986544 )),
        "SpglibTestData/virtual_structure/POSCAR-160-227-71": double3x3(SIMD3<Double>( 11.653119754 , 0.0 , 0.0 ), SIMD3<Double>( -5.82655987698 , 10.0918977403 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.2720986544 )),
        "SpglibTestData/virtual_structure/POSCAR-160-fcc": double3x3(SIMD3<Double>( 7.07106781187 , 0.0 , 0.0 ), SIMD3<Double>( -3.53553390593 , 6.12372435696 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-161-222-16": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-161-223-16": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-161-230-conv-18": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0907889746 )),
        "SpglibTestData/virtual_structure/POSCAR-161-230-prim-16": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0907889746 )),
        "SpglibTestData/virtual_structure/POSCAR-161-bcc-16": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0907889746 )),
        "SpglibTestData/virtual_structure/POSCAR-166-221-06": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-166-224-06": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-166-227-06": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( -2.91327993849 , 5.04594887013 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.2720986544 )),
        "SpglibTestData/virtual_structure/POSCAR-166-227-38": double3x3(SIMD3<Double>( 11.653119754 , 0.0 , 0.0 ), SIMD3<Double>( -5.82655987698 , 10.0918977403 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.2720986544 )),
        "SpglibTestData/virtual_structure/POSCAR-167-222-06": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-167-223-06": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( -7.07106781187 , 12.2474487139 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 17.3205080757 )),
        "SpglibTestData/virtual_structure/POSCAR-167-230-conv-06": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0907889746 )),
        "SpglibTestData/virtual_structure/POSCAR-167-230-prim-06": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0907889746 )),
        "SpglibTestData/virtual_structure/POSCAR-167-bcc-6": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( -9.05559127754 , 15.6847441853 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 11.0907889746 )),
        "SpglibTestData/virtual_structure/POSCAR-17-227-60": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-17-227-85": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-17-230-conv-46": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-18-227-86": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-19-227-59": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-19-227-89": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-19-230-conv-51": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-195-221-07": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-195-222-07": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-195-223-07": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-195-224-07": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-198-227-40": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-198-230-conv-20": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-199-230-conv-07": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-199-230-prim-07": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-2-221-28": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 6.12323399574e-16 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-2-222-28": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 6.12323399574e-16 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-2-223-28": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 6.12323399574e-16 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-2-224-28": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 6.12323399574e-16 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-2-227-41": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 2.91327993849 , 5.04594887013 , 0.0 ), SIMD3<Double>( 2.91327993849 , 1.68198295671 , 4.75736621812 )),
        "SpglibTestData/virtual_structure/POSCAR-2-227-74": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 3.56773895169e-16 , 5.82655987698 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 5.04554481249e-16 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-2-227-94": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 8.24 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 5.04554481249e-16 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-2-230-conv-39": double3x3(SIMD3<Double>( 11.0907889746 , 0.0 , 0.0 ), SIMD3<Double>( -3.69692965819 , 10.4564961235 , 0.0 ), SIMD3<Double>( -3.69692965819 , -5.22824806176 , 9.05559127754 )),
        "SpglibTestData/virtual_structure/POSCAR-2-230-conv-57": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 7.84174410958e-16 , 12.80654 , 0.0 ), SIMD3<Double>( 7.84174410958e-16 , 7.84174410958e-16 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-2-230-prim-28": double3x3(SIMD3<Double>( 11.0907889746 , 0.0 , 0.0 ), SIMD3<Double>( -3.69692965819 , 10.4564961235 , 0.0 ), SIMD3<Double>( -3.69692965819 , -5.22824806176 , 9.05559127754 )),
        "SpglibTestData/virtual_structure/POSCAR-2-bcc-28": double3x3(SIMD3<Double>( 11.0907889746 , 0.0 , 0.0 ), SIMD3<Double>( -3.69692965819 , 10.4564961235 , 0.0 ), SIMD3<Double>( -3.69692965819 , -5.22824806176 , 9.05559127754 )),
        "SpglibTestData/virtual_structure/POSCAR-20-227-53": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-20-227-90": double3x3(SIMD3<Double>( 11.653119754 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.653119754 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-20-230-conv-53": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-200-221-02": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-200-223-02": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-201-222-02": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-201-224-02": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-205-230-conv-08": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-206-230-conv-02": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-206-230-prim-02": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-207-221-04": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-207-222-04": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-208-223-04": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-208-224-04": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-21-221-23": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-21-222-23": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-21-223-23": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-21-224-23": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-21-230-conv-49": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-212-227-19": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-213-230-conv-09": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-214-230-conv-04": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-214-230-prim-04": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-215-221-03": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-215-224-03": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-215-227-18": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-216-227-03": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-218-222-03": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-218-223-03": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-22-230-conv-26": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 18.1111825551 )),
        "SpglibTestData/virtual_structure/POSCAR-22-230-prim-23": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 18.1111825551 )),
        "SpglibTestData/virtual_structure/POSCAR-220-230-conv-03": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-220-230-prim-03": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-221-221-01": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-222-222-01": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-223-223-01": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-224-224-01": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-227-227-01": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-230-230-conv-01": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-230-230-conv-62": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-230-230-prim-01": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-24-230-conv-23": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-24-230-prim-20": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-25-221-21": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-25-223-21": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-25-227-54": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-26-227-64": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.82655987698 )),
        "SpglibTestData/virtual_structure/POSCAR-27-230-conv-48": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-28-227-62": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.82655987698 )),
        "SpglibTestData/virtual_structure/POSCAR-29-230-conv-52": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-3-221-29": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-3-222-29": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-3-223-29": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-3-224-29": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-3-227-82": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-3-227-95": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-3-230-conv-58": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 7.84174410958e-16 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-30-227-65": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.82655987698 )),
        "SpglibTestData/virtual_structure/POSCAR-31-227-58": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-32-230-conv-47": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-33-227-63": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.82655987698 )),
        "SpglibTestData/virtual_structure/POSCAR-34-222-21": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-34-224-21": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-35-221-22": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-35-224-22": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-35-227-87": double3x3(SIMD3<Double>( 11.653119754 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.653119754 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-37-222-22": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-37-223-22": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-38-221-26": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.1421356237 )),
        "SpglibTestData/virtual_structure/POSCAR-39-224-26": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.1421356237 )),
        "SpglibTestData/virtual_structure/POSCAR-4-227-77": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 3.56773895169e-16 , 0.0 , 5.82655987698 )),
        "SpglibTestData/virtual_structure/POSCAR-4-227-81": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-4-227-96": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-4-230-conv-59": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 7.84174410958e-16 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-40-223-26": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.1421356237 )),
        "SpglibTestData/virtual_structure/POSCAR-41-222-26": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 14.1421356237 )),
        "SpglibTestData/virtual_structure/POSCAR-43-230-conv-25": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-43-230-conv-29": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 18.1111825551 )),
        "SpglibTestData/virtual_structure/POSCAR-43-230-prim-22": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-43-230-prim-26": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 18.1111825551 )),
        "SpglibTestData/virtual_structure/POSCAR-43-bcc-22": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-43-bcc-26": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 18.1111825551 )),
        "SpglibTestData/virtual_structure/POSCAR-44-227-24": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-45-230-conv-24": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-45-230-prim-21": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-46-227-28": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 5.82655987698 )),
        "SpglibTestData/virtual_structure/POSCAR-47-221-08": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-47-223-08": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-48-222-08": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-48-224-08": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-5-221-32": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-5-222-32": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-5-223-32": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-5-224-32": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        //"SpglibTestData/virtual_structure/POSCAR-5-227-45": double3x3(SIMD3<Double>( 10.0918977403 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( -3.36396591342 , 0.0 , 4.75736621812 )),
        "SpglibTestData/virtual_structure/POSCAR-5-227-75": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-5-227-98": double3x3(SIMD3<Double>( 11.653119754 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.653119754 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 0.0 , 8.24 )),
        //"SpglibTestData/virtual_structure/POSCAR-5-230-conv-40": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( -9.05559127754 , 0.0 , 9.05559127754 )),
        //"SpglibTestData/virtual_structure/POSCAR-5-230-conv-43": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( -6.40327 , 0.0 , 9.05559127754 )),
        "SpglibTestData/virtual_structure/POSCAR-5-230-conv-61": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( 7.84174410958e-16 , 0.0 , 12.80654 )),
        //"SpglibTestData/virtual_structure/POSCAR-5-230-prim-29": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( -9.05559127754 , 0.0 , 9.05559127754 )),
        //"SpglibTestData/virtual_structure/POSCAR-5-230-prim-32": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( -6.40327 , 0.0 , 9.05559127754 )),
        //"SpglibTestData/virtual_structure/POSCAR-5-bcc-29": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( -9.05559127754 , 0.0 , 9.05559127754 )),
        //"SpglibTestData/virtual_structure/POSCAR-5-bcc-32": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( -6.40327 , 0.0 , 9.05559127754 )),
        "SpglibTestData/virtual_structure/POSCAR-51-227-29": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-53-227-32": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-54-230-conv-30": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-6-221-30": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-6-223-30": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-6-227-79": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-61-230-conv-31": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-62-227-31": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-65-221-09": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-66-223-09": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-67-224-09": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-68-222-09": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-7-222-30": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( -10.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-7-224-30": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( -10.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-7-227-78": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 3.56773895169e-16 , 0.0 , 5.82655987698 )),
        "SpglibTestData/virtual_structure/POSCAR-7-227-80": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( -5.82655987698 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-7-230-conv-60": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 7.84174410958e-16 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-70-230-conv-11": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 18.1111825551 )),
        "SpglibTestData/virtual_structure/POSCAR-70-230-prim-09": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 18.1111825551 )),
        "SpglibTestData/virtual_structure/POSCAR-70-bcc-9": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 18.1111825551 )),
        "SpglibTestData/virtual_structure/POSCAR-73-230-conv-10": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-73-230-prim-08": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-74-227-09": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-75-221-25": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-75-222-25": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-76-227-61": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-77-223-25": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-77-224-25": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-78-227-91": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-78-230-conv-54": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-8-221-31": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-8-224-31": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        //"SpglibTestData/virtual_structure/POSCAR-8-227-44": double3x3(SIMD3<Double>( 10.0918977403 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( -3.36396591342 , 0.0 , 4.75736621812 )),
        "SpglibTestData/virtual_structure/POSCAR-8-227-97": double3x3(SIMD3<Double>( 11.653119754 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 11.653119754 , 0.0 ), SIMD3<Double>( 5.04554481249e-16 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-80-230-conv-28": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-80-230-prim-25": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-81-221-24": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-81-222-24": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-81-223-24": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-81-224-24": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-81-227-88": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-81-230-conv-50": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-82-230-conv-27": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-82-230-prim-24": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-83-221-10": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-84-223-10": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-85-222-10": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-86-224-10": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-88-230-conv-12": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-88-230-prim-10": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-89-221-12": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-89-222-12": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-9-222-31": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-9-223-31": double3x3(SIMD3<Double>( 14.1421356237 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 14.1421356237 , 0.0 ), SIMD3<Double>( 6.12323399574e-16 , 0.0 , 10.0 )),
        //"SpglibTestData/virtual_structure/POSCAR-9-227-43": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( -4.12 , 0.0 , 4.12 )),
        //"SpglibTestData/virtual_structure/POSCAR-9-230-conv-41": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( -9.05559127754 , 0.0 , 9.05559127754 )),
        //"SpglibTestData/virtual_structure/POSCAR-9-230-conv-42": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( -6.40327 , 0.0 , 9.05559127754 )),
        //"SpglibTestData/virtual_structure/POSCAR-9-230-prim-30": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( -9.05559127754 , 0.0 , 9.05559127754 )),
        //"SpglibTestData/virtual_structure/POSCAR-9-230-prim-31": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( -6.40327 , 0.0 , 9.05559127754 )),
        //"SpglibTestData/virtual_structure/POSCAR-9-bcc-30": double3x3(SIMD3<Double>( 18.1111825551 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( -9.05559127754 , 0.0 , 9.05559127754 )),
        //"SpglibTestData/virtual_structure/POSCAR-9-bcc-31": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.1111825551 , 0.0 ), SIMD3<Double>( -6.40327 , 0.0 , 9.05559127754 )),
        "SpglibTestData/virtual_structure/POSCAR-91-227-67": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-92-227-35": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-92-230-conv-35": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-93-223-12": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-93-224-12": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 )),
        "SpglibTestData/virtual_structure/POSCAR-95-227-36": double3x3(SIMD3<Double>( 5.82655987698 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.82655987698 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-95-230-conv-32": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-96-227-69": double3x3(SIMD3<Double>( 8.24 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 8.24 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 8.24 )),
        "SpglibTestData/virtual_structure/POSCAR-98-230-conv-14": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-98-230-prim-12": double3x3(SIMD3<Double>( 12.80654 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 12.80654 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 12.80654 )),
        "SpglibTestData/virtual_structure/POSCAR-99-221-13": double3x3(SIMD3<Double>( 10.0 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 10.0 , 0.0 ), SIMD3<Double>( 0.0 , 0.0 , 10.0 ))
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
          
          let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: double3x3, rotationMatrix: double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, symmetryPrecision: precision)
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
  
  /*
  func testFindMonoclincSpaceGroupDebug()
  {
    let testData: [String: double3x3] =
      [
        // primitive = double3x3([0.0000000000, 5.4049974567, 0.0000000000],[-2.0448445974, 0.0000000000, 12.9252406329], [16.4529922582, 0.0000000000, 0.0000000000])
        //"SpglibTestData/monoclinic/POSCAR-007-2" : double3x3(SIMD3<Double>( 13.0859938425 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.40499745672 , 0.0 ), SIMD3<Double>( -10.5150150743 , 0.0 , 16.2508775893 ))
        "SpglibTestData/monoclinic/POSCAR-009-2" : double3x3(SIMD3<Double>( 12.8724656748 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 18.686991207 , 0.0 ), SIMD3<Double>( -5.51979524915 , 0.0 , 7.38762914424 ))
      ]
    
    let bundle = Bundle(for: type(of: self))
    
    for (fileName, reference) in testData
    {
      if let url: URL = bundle.url(forResource: fileName, withExtension: nil),
         let data: Data = try? Data.init(contentsOf: url),
         let VASPString: String = String(data: data, encoding: String.Encoding.ascii)
      {
        let reader: SKPOSCARParser = SKPOSCARParser.init(displayName: "fileName", string: VASPString, windowController: nil)
        try! reader.startParsing()
        let unitCell = reader.cell.unitCell
        let atoms = reader.scene[0][0].atoms
        
        
        
        let origin: SIMD3<Double> = SIMD3<Double>(Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1), Double.random(in: -0.1..<0.1))
        let translatedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = atoms.map{($0.position, $0.elementIdentifier)}
        
        
        let spacegroup: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)])? = SKSpacegroup.SKFindSpaceGroup(unitCell: unitCell, atoms: translatedAtoms, symmetryPrecision: precision)
        XCTAssertNotNil(spacegroup, "space group \(fileName) not found")
        if let spacegroup = spacegroup
        {
          print("Found unit cell: ", spacegroup.cell.unitCell)
          print("Space group: ", SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber)
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
  }*/
  
  
  /*
  func testFindOrthorhombicSpaceGroupDebug()
  {
    let testData: [String: double3x3] =
      [
        "SpglibTestData/monoclinic/POSCAR-009": double3x3(SIMD3<Double>( 16.2779923405 , 0.0 , 0.0 ), SIMD3<Double>( 0.0 , 5.63209734986 , 0.0 ), SIMD3<Double>( -6.93540790248 , 0.0 , 9.37590780395 ))
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
            print("FOUND: ", spacegroup.cell.unitCell)
            print("FOUND: ", SKSpacegroup.spaceGroupData[spacegroup.hall].spaceGroupNumber)
            print("SHOULD BE ", SKSymmetryCell.init(unitCell: reference))
            print("WE HAVE ", spacegroup.cell)
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
  }*/
  
}
