//
//  FractionTests.swift
//  MathKitTests
//
//  Created by David Dubbeldam on 22/06/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest
@testable import MathKit

class FractionTests: XCTestCase
{
  func testFractions()
  {
    XCTAssertEqual(Fraction(3, 4), Fraction(1, 2) + Fraction(1, 4))
    XCTAssertEqual(Fraction(1,1), Fraction(3,4) / Fraction(3,4))
    XCTAssertEqual(Fraction(5,2), Fraction(1,4) * 10)
    XCTAssertEqual(Fraction(1,2), Fraction(1,4) / Fraction(1,2))
  }
}
