//
//  GreatestCommonDivisor.swift
//  MathKitTests
//
//  Created by David Dubbeldam on 25/06/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import MathKit

class GreatestCommonDivisor: XCTestCase
{

  func testGCD() throws
  {
    let a = [20,20,60,40,120,180,-60,-80].reduce(0){Int32.greatestCommonDivisor(a: $0, b: $1)}
    XCTAssertEqual(a, 20)
  }
  
  func testGCD2() throws
  {
    let a = [20,20,60,40,120,170,-60,-80].reduce(0){Int32.greatestCommonDivisor(a: $0, b: $1)}
    XCTAssertEqual(a, 10)
  }
  
  func testGCD3() throws
  {
    let a = [20,20,60,40,120,175,-60,-80].reduce(0){Int32.greatestCommonDivisor(a: $0, b: $1)}
    XCTAssertEqual(a, 5)
  }
}
