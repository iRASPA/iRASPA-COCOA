//
//  DelaunayReductionTests.swift
//  SymmetryKitTests
//
//  Created by David Dubbeldam on 09/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import SymmetryKit
import simd

class DelaunayReductionTests: XCTestCase
{
  let precision: Double = 1e-5
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testDelaunay3DReduction()
  {
    let fileName = "SpglibTestData/Reduction/Delaunay3D.data"
    
    let bundle = Bundle(for: type(of: self))
    
    if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
    {
      do
      {
        let data: String = try String(contentsOf: url, encoding: String.Encoding.utf8)
        let lines: [String] = data.components(separatedBy: .newlines)
        
        for (linenumber, line) in lines.enumerated()
        {
          if(!line.isEmpty)
          {
            let numbers: [Double] = line.components(separatedBy: ",").compactMap{($0 as NSString).doubleValue}
            let inputCell: double3x3 = double3x3([numbers[0], numbers[1], numbers[2]], [numbers[3], numbers[4], numbers[5]], [numbers[6], numbers[7], numbers[8]])
            let reference: double3x3 = double3x3([numbers[9], numbers[10], numbers[11]], [numbers[12], numbers[13], numbers[14]], [numbers[15], numbers[16], numbers[17]])
          
            let reducedUnitCell: double3x3? = SKSymmetryCell.computeDelaunayReducedCell(unitCell: inputCell, symmetryPrecision: precision)
            XCTAssertNotNil(reducedUnitCell, "reduced cell \(linenumber) not found")
            if let reducedUnitCell = reducedUnitCell
            {
              XCTAssertEqual(reducedUnitCell[0][0], reference[0][0], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedUnitCell[0][1], reference[0][1], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedUnitCell[0][2], reference[0][2], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
            
              XCTAssertEqual(reducedUnitCell[1][0], reference[1][0], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedUnitCell[1][1], reference[1][1], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedUnitCell[1][2], reference[1][2], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
            
              XCTAssertEqual(reducedUnitCell[2][0], reference[2][0], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedUnitCell[2][1], reference[2][1], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedUnitCell[2][2], reference[2][2], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
          
            }
          }
        }
      }
      catch
      {
        
      }
    }
  }
  
 
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testDelaunay2DUniqueAxisBReduction()
  {
    let fileName = "SpglibTestData/Reduction/Delaunay2D_B.data"
    
    let bundle = Bundle(for: type(of: self))
    
    if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
    {
      do
      {
        let data: String = try String(contentsOf: url, encoding: String.Encoding.utf8)
        let lines: [String] = data.components(separatedBy: .newlines)
        
        for (linenumber, line) in lines.enumerated()
        {
          if(!line.isEmpty)
          {
            let numbers: [Double] = line.components(separatedBy: ",").compactMap{($0 as NSString).doubleValue}
            let inputCell: double3x3 = double3x3([numbers[0], numbers[1], numbers[2]], [numbers[3], numbers[4], numbers[5]], [numbers[6], numbers[7], numbers[8]])
            let reference: double3x3 = double3x3([numbers[9], numbers[10], numbers[11]], [numbers[12], numbers[13], numbers[14]], [numbers[15], numbers[16], numbers[17]])
          
            let reducedUnitCell: double3x3? = SKSymmetryCell.computeDelaunayReducedCell2D(unitCell: inputCell, symmetryPrecision: precision)
            XCTAssertNotNil(reducedUnitCell, "reduced cell \(linenumber) not found")
            if let reducedUnitCell = reducedUnitCell
            {
              XCTAssertEqual(reducedUnitCell[0][0], reference[0][0], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedUnitCell[0][1], reference[0][1], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedUnitCell[0][2], reference[0][2], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
            
              XCTAssertEqual(reducedUnitCell[1][0], reference[1][0], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedUnitCell[1][1], reference[1][1], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedUnitCell[1][2], reference[1][2], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
            
              XCTAssertEqual(reducedUnitCell[2][0], reference[2][0], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedUnitCell[2][1], reference[2][1], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedUnitCell[2][2], reference[2][2], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
          
            }
          }
        }
      }
      catch
      {
      }
    }
  }
  
  
  
  
  // Test-cases assembled in Spglib by Atsushi Togo (https://github.com/spglib/spglib)
  func testNiggliReduction()
  {
    let fileName = "SpglibTestData/Reduction/Niggli.data"
    
    let bundle = Bundle(for: type(of: self))
    
    if let url: URL = bundle.url(forResource: fileName, withExtension: nil)
    {
      do
      {
        let data: String = try String(contentsOf: url, encoding: String.Encoding.utf8)
        let lines: [String] = data.components(separatedBy: .newlines)
        
        for (linenumber, line) in lines.enumerated()
        {
          if(!line.isEmpty)
          {
            let numbers: [Double] = line.components(separatedBy: ",").compactMap{($0 as NSString).doubleValue}
            let inputCell: double3x3 = double3x3([numbers[0], numbers[1], numbers[2]], [numbers[3], numbers[4], numbers[5]], [numbers[6], numbers[7], numbers[8]])
            let reference: double3x3 = double3x3([numbers[9], numbers[10], numbers[11]], [numbers[12], numbers[13], numbers[14]], [numbers[15], numbers[16], numbers[17]])
            
            let reducedNiggliCell: double3x3? = SKSymmetryCell.computeReducedNiggliCellAndChangeOfBasisMatrix(unitCell: inputCell)
          
            XCTAssertNotNil(reducedNiggliCell, "reduced cell \(linenumber) not found")
            if let reducedNiggliCell = reducedNiggliCell
            {
              XCTAssertEqual(reducedNiggliCell[0][0], reference[0][0], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedNiggliCell[0][1], reference[0][1], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedNiggliCell[0][2], reference[0][2], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
            
              XCTAssertEqual(reducedNiggliCell[1][0], reference[1][0], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedNiggliCell[1][1], reference[1][1], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedNiggliCell[1][2], reference[1][2], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
            
              XCTAssertEqual(reducedNiggliCell[2][0], reference[2][0], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedNiggliCell[2][1], reference[2][1], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
              XCTAssertEqual(reducedNiggliCell[2][2], reference[2][2], accuracy: precision, "Wrong space group found for \(inputCell) should be \(reference)")
          
            }
          }
        }
      }
      catch
      {
      }
    }
  }
}
