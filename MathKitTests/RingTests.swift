//
//  RingTests.swift
//  MathKitTests
//
//  Created by David Dubbeldam on 22/06/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import MathKit

class RingTests: XCTestCase
{
  func testExtendedGreatestCommonDivisor() throws
  {
    for _ in 0..<100000
    {
      let a = Int.random(in: -100...100)
      let b = Int.random(in: -100...100)
      let result = Ring.extendedGreatestCommonDivisor(a: a, b: b)
      XCTAssertEqual(result.0, result.1*a + result.2*b, "Error")
    }
  }
}
