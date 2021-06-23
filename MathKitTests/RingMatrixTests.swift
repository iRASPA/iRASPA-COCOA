//
//  RingMatrixTests.swift
//  MathKitTests
//
//  Created by David Dubbeldam on 22/06/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import XCTest

import Foundation
import XCTest
@testable import MathKit

class RingMatrixTests: XCTestCase
{
  func assertEqual(_ m1: RingMatrix, _ m2: RingMatrix) {
    XCTAssertEqual(m1.rows, m2.rows)
    XCTAssertEqual(m1.columns, m2.columns)
    for r in 0..<m1.rows {
      for c in 0..<m1.columns {
        XCTAssertEqual(m1[r, c], m2[r, c])
      }
    }
  }
  
  /*
    Since Matrix is a struct, if you copy the matrix to another variable,
    Swift doesn't actually copy the memory until you modify the new variable.
    Because Matrix uses Accelerate framework to modify its contents, we want
    to make sure that it doesn't modify the original array, only the copy.
    This helper function forces Swift to make a copy.
  */
  func copy(_ m: RingMatrix) -> RingMatrix
  {
    var q = m
    q[0,0] = m[0,0]  // force Swift to make a copy
    return q
  }
  
  // MARK: - Creating matrices

  
  func testCreateFromArray()
  {
    let a = [[1, 2], [3, 4], [5, 6]]
    let m = RingMatrix(a)
    XCTAssertEqual(m.rows, a.count)
    XCTAssertEqual(m.columns, a[0].count)
    for r in 0..<m.rows {
      for c in 0..<m.columns {
        XCTAssertEqual(m[r, c], a[r][c])
      }
    }
  }
  
  func testCreateFromArrayRange()
  {
    let a = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    for i in 0..<3 {
      for j in i..<3 {
        let m = RingMatrix(a, range: i...j)
        XCTAssertEqual(m.rows, a.count)
        XCTAssertEqual(m.columns, j - i + 1)
        for r in 0..<m.rows {
          for c in i...j {
            XCTAssertEqual(m[r, c - i], a[r][c])
          }
        }
      }
    }
  }
    
  func testCreateFromRowVector()
  {
    let v = [1, 2, 3, 4, 5, 6]
    let m = RingMatrix(v)
    XCTAssertEqual(m.rows, 1)
    XCTAssertEqual(m.columns, v.count)
    for c in 0..<m.columns {
      XCTAssertEqual(m[0, c], v[c])
    }
  }
  
  func testCreateFromColumnVector()
  {
    let v = [1, 2, 3, 4, 5, 6]
    let m = RingMatrix(v, isColumnVector: true)
    XCTAssertEqual(m.rows, v.count)
    XCTAssertEqual(m.columns, 1)
    for r in 0..<m.rows {
      XCTAssertEqual(m[r, 0], v[r])
    }
  }

  func testCreateRowVectorFromRange()
  {
    let m1 = RingMatrix(10..<20)
    XCTAssertEqual(m1.rows, 10)
    for r in 0..<m1.rows {
      XCTAssertEqual(m1[r, 0], Int(r + 10))
    }
    
    let m2 = RingMatrix(-10...10)
    XCTAssertEqual(m2.rows, 21)
    for r in 0..<m2.rows {
      XCTAssertEqual(m2[r, 0], Int(-10 + r))
    }
  }
  
  func testCreateColumnVectorFromRange()
  {
    let m1 = RingMatrix(10..<20, isColumnVector: true)
    XCTAssertEqual(m1.columns, 10)
    for c in 0..<m1.columns {
      XCTAssertEqual(m1[0, c], Int(c + 10))
    }
    
    let m2 = RingMatrix(-10...10, isColumnVector: true)
    XCTAssertEqual(m2.columns, 21)
    for c in 0..<m2.columns {
      XCTAssertEqual(m2[0, c], Int(-10 + c))
    }
  }

  func testZeros()
  {
    let m = RingMatrix.zeros(rows: 3, columns: 3)
    for r in 0..<3 {
      for c in 0..<3 {
        XCTAssertEqual(m[r, c], 0)
      }
    }
  }
  
  func testIdentityMatrix()
  {
    let m = RingMatrix.identity(size: 3)
    
    XCTAssertEqual(m[0, 0], 1)
    XCTAssertEqual(m[0, 1], 0)
    XCTAssertEqual(m[0, 2], 0)
    
    XCTAssertEqual(m[1, 0], 0)
    XCTAssertEqual(m[1, 1], 1)
    XCTAssertEqual(m[1, 2], 0)
    
    XCTAssertEqual(m[2, 0], 0)
    XCTAssertEqual(m[2, 1], 0)
    XCTAssertEqual(m[2, 2], 1)
  }
  
  func testTile()
  {
    let v = RingMatrix([1, 2, 3, 4, 5, 6])
    
    let m = v.tile(5)
    XCTAssertEqual(m.rows, 5)
    XCTAssertEqual(m.columns, v.columns)
    for r in 0..<m.rows {
      for c in 0..<m.columns {
        XCTAssertEqual(m[r, c], v[c])
      }
    }
    
    assertEqual(v, v.tile(1))
  }
  
  // MARK: - Subscripts

  func testChangeMatrixUsingSubscript()
  {
    var m = RingMatrix.ones(rows: 3, columns: 3)
    for r in 0..<3 {
      for c in 0..<3 {
        m[r, c] = 100*(Int(r)+1) + 10*(Int(c)+1)
      }
    }
    for r in 0..<3 {
      for c in 0..<3 {
        XCTAssertEqual(m[r, c], 100*(Int(r)+1) + 10*(Int(c)+1))
      }
    }
  }
  
  func testSubscriptRowVector()
  {
    let v = [1, 2, 3, 4, 5, 6]
    let m = RingMatrix(v)
    for c in 0..<m.columns {
      XCTAssertEqual(m[c], v[c])
      XCTAssertEqual(m[c], m[0, c])
    }
  }
  
  func testSubscriptColumnVector()
  {
    let v = [1, 2, 3, 4, 5, 6]
    let m = RingMatrix(v, isColumnVector: true)
    for r in 0..<m.rows {
      XCTAssertEqual(m[r], v[r])
      XCTAssertEqual(m[r], m[r, 0])
    }
  }
  
  func testSubscriptRowGetter()
  {
    let a = [[1, 2], [3, 4], [5, 6]]
    let m = RingMatrix(a)
    let M = copy(m)
    
    let r0 = m[row: 0]
    XCTAssertEqual(r0[0], 1)
    XCTAssertEqual(r0[1], 2)
    
    let r1 = m[row: 1]
    XCTAssertEqual(r1[0], 3)
    XCTAssertEqual(r1[1], 4)
    
    let r2 = m[row: 2]
    XCTAssertEqual(r2[0], 5)
    XCTAssertEqual(r2[1], 6)
    
    assertEqual(m, M)
  }
  
  func testSubscriptRowSetter()
  {
    let a = [[1, 2], [3, 4], [5, 6]]
    var m = RingMatrix(a)
    
    m[row: 0] = RingMatrix([-1, -2])
    XCTAssertEqual(m[0, 0], -1)
    XCTAssertEqual(m[0, 1], -2)
    
    m[row: 1] = RingMatrix([-3, -4])
    XCTAssertEqual(m[1, 0], -3)
    XCTAssertEqual(m[1, 1], -4)
    
    m[row: 2] = RingMatrix([-5, -6])
    XCTAssertEqual(m[2, 0], -5)
    XCTAssertEqual(m[2, 1], -6)
  }
  
  func testSubscriptRowsGetter()
  {
    let a = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    let m = RingMatrix(a)
    let M = copy(m)
    
    let r0 = m[rows: 0...0]
    XCTAssertEqual(r0.rows, 1)
    XCTAssertEqual(r0.columns, 3)
    XCTAssertEqual(r0[0, 0], 1)
    XCTAssertEqual(r0[0, 1], 2)
    XCTAssertEqual(r0[0, 2], 3)
    
    let r1 = m[rows: 0...1]
    XCTAssertEqual(r1.rows, 2)
    XCTAssertEqual(r1.columns, 3)
    XCTAssertEqual(r1[0, 0], 1)
    XCTAssertEqual(r1[0, 1], 2)
    XCTAssertEqual(r1[0, 2], 3)
    XCTAssertEqual(r1[1, 0], 4)
    XCTAssertEqual(r1[1, 1], 5)
    XCTAssertEqual(r1[1, 2], 6)
    
    let r2 = m[rows: 0...2]
    assertEqual(r2, m)
    
    let r3 = m[rows: 1...2]
    XCTAssertEqual(r3.rows, 2)
    XCTAssertEqual(r3.columns, 3)
    XCTAssertEqual(r3[0, 0], 4)
    XCTAssertEqual(r3[0, 1], 5)
    XCTAssertEqual(r3[0, 2], 6)
    XCTAssertEqual(r3[1, 0], 7)
    XCTAssertEqual(r3[1, 1], 8)
    XCTAssertEqual(r3[1, 2], 9)
    
    let r4 = m[rows: 2...2]
    XCTAssertEqual(r4.rows, 1)
    XCTAssertEqual(r4.columns, 3)
    XCTAssertEqual(r4[0, 0], 7)
    XCTAssertEqual(r4[0, 1], 8)
    XCTAssertEqual(r4[0, 2], 9)
    
    assertEqual(m, M)
  }
  
  func testSubscriptRowsSetter()
  {
    var m = RingMatrix([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
    
    m[rows: 0...0] = RingMatrix([-1, -2, -3])
    assertEqual(m, RingMatrix([[-1, -2, -3], [4, 5, 6], [7, 8, 9]]))
    
    m[rows: 0...1] = RingMatrix([[10, 20, 30], [-4, -5, -6]])
    assertEqual(m, RingMatrix([[10, 20, 30], [-4, -5, -6], [7, 8, 9]]))
    
    m[rows: 0...2] = RingMatrix([[-10, -20, -30], [40, 50, 60], [-7, -8, -9]])
    assertEqual(m, RingMatrix([[-10, -20, -30], [40, 50, 60], [-7, -8, -9]]))
    
    m[rows: 1...2] = RingMatrix([[-40, -50, -60], [70, 80, 90]])
    assertEqual(m, RingMatrix([[-10, -20, -30], [-40, -50, -60], [70, 80, 90]]))
    
    m[rows: 2...2] = RingMatrix([-70, -80, -90])
    assertEqual(m, RingMatrix([[-10, -20, -30], [-40, -50, -60], [-70, -80, -90]]))
  }
  
  func testSubscriptRowIndicesGetter()
  {
    let m = RingMatrix([[1, 2], [3, 4], [5, 6]])
    let M = copy(m)
    
    assertEqual(m[rows: [0]], [1, 2])
    assertEqual(m[rows: [1]], [3, 4])
    assertEqual(m[rows: [2]], [5, 6])
    
    assertEqual(m[rows: [0, 1]], RingMatrix([[1, 2], [3, 4]]))
    assertEqual(m[rows: [1, 0]], RingMatrix([[3, 4], [1, 2]]))
    assertEqual(m[rows: [0, 2]], RingMatrix([[1, 2], [5, 6]]))
    assertEqual(m[rows: [2, 0]], RingMatrix([[5, 6], [1, 2]]))
    
    assertEqual(m[rows: [2, 1, 0]], RingMatrix([[5, 6], [3, 4], [1, 2]]))
    
    assertEqual(m, M)
  }
  
  func testSubscriptColumnGetter()
  {
    let a = [[1, 2], [3, 4], [5, 6]]
    let m = RingMatrix(a)
    let M = copy(m)
    
    let c0 = m[column: 0]
    XCTAssertEqual(c0[0], 1)
    XCTAssertEqual(c0[1], 3)
    XCTAssertEqual(c0[2], 5)
    
    let c1 = m[column: 1]
    XCTAssertEqual(c1[0], 2)
    XCTAssertEqual(c1[1], 4)
    XCTAssertEqual(c1[2], 6)
    
    assertEqual(m, M)
  }
  
  func testSubscriptColumnSetter()
  {
    let a = [[1, 2], [3, 4], [5, 6]]
    var m = RingMatrix(a)
    
    m[column: 0] = RingMatrix([-1, -3, -5], isColumnVector: true)
    XCTAssertEqual(m[0, 0], -1)
    XCTAssertEqual(m[1, 0], -3)
    XCTAssertEqual(m[2, 0], -5)
    
    m[column: 1] = RingMatrix([-2, -4, -6], isColumnVector: true)
    XCTAssertEqual(m[0, 1], -2)
    XCTAssertEqual(m[1, 1], -4)
    XCTAssertEqual(m[2, 1], -6)
  }
  
  func testSubscriptColumnsGetter()
  {
    let a = [[1, 4, 7], [2, 5, 8], [3, 6, 9]]
    let m = RingMatrix(a)
    let M = copy(m)
    
    let r0 = m[columns: 0...0]
    XCTAssertEqual(r0.rows, 3)
    XCTAssertEqual(r0.columns, 1)
    XCTAssertEqual(r0[0, 0], 1)
    XCTAssertEqual(r0[1, 0], 2)
    XCTAssertEqual(r0[2, 0], 3)
    
    let r1 = m[columns: 0...1]
    XCTAssertEqual(r1.rows, 3)
    XCTAssertEqual(r1.columns, 2)
    XCTAssertEqual(r1[0, 0], 1)
    XCTAssertEqual(r1[1, 0], 2)
    XCTAssertEqual(r1[2, 0], 3)
    XCTAssertEqual(r1[0, 1], 4)
    XCTAssertEqual(r1[1, 1], 5)
    XCTAssertEqual(r1[2, 1], 6)
    
    let r2 = m[columns: 0...2]
    assertEqual(r2, m)
    
    let r3 = m[columns: 1...2]
    XCTAssertEqual(r3.rows, 3)
    XCTAssertEqual(r3.columns, 2)
    XCTAssertEqual(r3[0, 0], 4)
    XCTAssertEqual(r3[1, 0], 5)
    XCTAssertEqual(r3[2, 0], 6)
    XCTAssertEqual(r3[0, 1], 7)
    XCTAssertEqual(r3[1, 1], 8)
    XCTAssertEqual(r3[2, 1], 9)
    
    let r4 = m[columns: 2...2]
    XCTAssertEqual(r4.rows, 3)
    XCTAssertEqual(r4.columns, 1)
    XCTAssertEqual(r4[0, 0], 7)
    XCTAssertEqual(r4[1, 0], 8)
    XCTAssertEqual(r4[2, 0], 9)
    
    assertEqual(m, M)
  }
  
  func testSubscriptColumnsSetter()
  {
    var m = RingMatrix([[1, 4, 7], [2, 5, 8], [3, 6, 9]])
    
    m[columns: 0...0] = RingMatrix([[-1], [-2], [-3]])
    assertEqual(m, RingMatrix([[-1, 4, 7], [-2, 5, 8], [-3, 6, 9]]))
    
    m[columns: 0...1] = RingMatrix([[10, -4], [20, -5], [30, -6]])
    assertEqual(m, RingMatrix([[10, -4, 7], [20, -5, 8], [30, -6, 9]]))
    
    m[columns: 0...2] = RingMatrix([[-10, 40, -7], [-20, 50, -8], [-30, 60, -9]])
    assertEqual(m, RingMatrix([[-10, 40, -7], [-20, 50, -8], [-30, 60, -9]]))
    
    m[columns: 1...2] = RingMatrix([[-40, 70], [-50, 80], [-60, 90]])
    assertEqual(m, RingMatrix([[-10, -40, 70], [-20, -50, 80], [-30, -60, 90]]))
    
    m[columns: 2...2] = RingMatrix([[-70], [-80], [-90]])
    assertEqual(m, RingMatrix([[-10, -40, -70], [-20, -50, -80], [-30, -60, -90]]))
  }
  
  func testSubscriptScalar()
  {
    let a1 = [[7, 6], [5, 4], [3, 2]]
    let m1 = RingMatrix(a1)
    XCTAssertEqual(m1.scalar, a1[0][0])
    
    let a2 = [[9]]
    let m2 = RingMatrix(a2)
    XCTAssertEqual(m2.scalar, a2[0][0])
  }
  
  func testToArray()
  {
    let a:[[Int]] = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    let m = RingMatrix(a)
    XCTAssertEqual(m.array, a)
  }
  
  // MARK: - Arithmetic
  
  func testMultiplyMatrixMatrix()
  {
    let a = RingMatrix([[1, 2], [3, 4], [5, 6]])    // 3x2
    let b = RingMatrix([[10], [20]])                // 2x1
    let c = RingMatrix([[50], [110], [170]])        // 3x1
    let A = copy(a)
    let B = copy(b)
    assertEqual(a <*> b, c)
    assertEqual(a, A)
    assertEqual(b, B)

    let d = RingMatrix([[10, 20, 30], [40, 50, 60]])                        // 2x3
    let e = RingMatrix([[90, 120, 150], [190, 260, 330], [290, 400, 510]])  // 3x3
    let f = RingMatrix([[220, 280], [490, 640]])                            // 2x2
    let D = d
    assertEqual(a <*> d, e)
    assertEqual(d <*> a, f)
    assertEqual(a, A)
    assertEqual(d, D)
    
    let i = RingMatrix.identity(size: 2)    // 2x2
    let j = RingMatrix.identity(size: 3)    // 3x3
    assertEqual(a <*> i, a)
    assertEqual(j <*> a, a)
  }
  
  // MARK: - HermitianNormalForm
  
  func testHermitianNormalForm() throws
  {
    let m: RingMatrix = RingMatrix([[3, 3, 1, 4], [0, 1, 0, 0], [0, 0, 19, 16], [0, 0, 0, 3]])
    let A: RingMatrix = RingMatrix([[3, 0, 1, 1], [0, 1, 0, 0], [0, 0, 19, 1], [0, 0, 0, 3]])
    let U: RingMatrix = RingMatrix([[1, -3, 0, -1], [0, 1, 0, 0], [0, 0, 1, -5], [0, 0, 0, 1]])
    
    let hnf: (U: RingMatrix, A: RingMatrix, rp: [Int]) = try m.HermiteNormalForm()
    
    assertEqual(hnf.U <*> m, hnf.A)
    assertEqual(hnf.U, U)
    assertEqual(hnf.A, A)
  }
  
  func testHermitianNormalForm2() throws
  {
    let m: RingMatrix = RingMatrix([[2, 3, 6, 2], [5, 6, 1, 6], [8, 3, 1, 1]])
    let A: RingMatrix = RingMatrix([[1, 0, 50, -11], [0, 3, 28, -2], [0, 0, 61, -13]])
    let U: RingMatrix = RingMatrix([[9, -5, 1], [5, -2, 0], [11, -6, 1]])
    
    let hnf: (U: RingMatrix, A: RingMatrix, rp: [Int]) = try m.HermiteNormalForm()
    
    assertEqual(hnf.U <*> m, hnf.A)
    assertEqual(hnf.U, U)
    assertEqual(hnf.A, A)
  }
  
  func testHermitianNormalForm3() throws
  {
    let m: RingMatrix = RingMatrix([[3, 2, 1], [0 ,1, 0], [1, 1, 1]])
    let A: RingMatrix = RingMatrix([[1, 0, 1], [0, 1, 0], [0, 0, 2]])
    let U: RingMatrix = RingMatrix([[0, -1, 1], [0, 1, 0], [-1, -1, 3]])
    
    let hnf: (U: RingMatrix, A: RingMatrix, rp: [Int]) = try m.HermiteNormalForm()
    
    assertEqual(hnf.U <*> m, hnf.A)
    assertEqual(hnf.U, U)
    assertEqual(hnf.A, A)
  }
  
  func testHermitianNormalForm4() throws
  {
    let m: RingMatrix = RingMatrix([[0, 0, 5, 0, 1, 4], [0, 0, 0, -1, -4, 99], [0, 0, 0, 20, 19, 16], [0, 0, 0, 0, 2, 1], [0, 0, 0, 0, 0, 3], [0, 0, 0, 0, 0, 0]])
    let A: RingMatrix = RingMatrix([[0, 0, 5, 0, 0, 2], [0, 0, 0, 1, 0, 1], [0, 0, 0, 0, 1, 2], [0, 0, 0, 0, 0, 3], [0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0]])
    let U: RingMatrix = RingMatrix([[1, -20, -1, -31, 675, 0], [0, -1, 0, -2, 34, 0], [0, -20, -1, -30, 676, 0], [0, 0, 0, 0, 1, 0], [0, -40, -2, -61, 1351, 0], [0, 0, 0, 0, 0, 1]])
    
    let hnf: (U: RingMatrix, A: RingMatrix, rp: [Int]) = try m.HermiteNormalForm()
    
    assertEqual(hnf.U <*> m, hnf.A)
    assertEqual(hnf.U, U)
    assertEqual(hnf.A, A)
  }
  
  func testHermitianNormalForm5() throws
  {
    let m: RingMatrix = RingMatrix([[2, 4, 4], [-6, 6, 12], [10, 4, 16]])
    let A: RingMatrix = RingMatrix([[2, 0, 120], [0, 2, 20], [0, 0, 156]])
    let U: RingMatrix = RingMatrix([[-16, 6, 7], [-2, 1, 1], [-21, 8, 9]])
    
    let hnf: (U: RingMatrix, A: RingMatrix, rp: [Int]) = try m.HermiteNormalForm()
    
    assertEqual(hnf.U <*> m, hnf.A)
    assertEqual(hnf.U, U)
    assertEqual(hnf.A, A)
  }
  
  func testHermitianNormalForm6() throws
  {
    let m: RingMatrix = RingMatrix([[4, -52, -96, 16, -72, 314, 9, 186, -54], [3, 4, 0, 16, 24, 122, 39, 78, 24], [-5, 24, 48, -24, 24, -339, -45, -202, 1], [3, -12, -32, 16, 0, 106, 21, 70, -7], [-3, -16, -24, -16, -48, -134, -57, -86, -49], [2, -4, -8, 8, 0, 237, 42, 140, 19]])
    let A: RingMatrix = RingMatrix([[1, 0, 0, 0, 0, 0, 0, 0, 0], [0, 4, 0, 0, 0, 0, 0, 0, 0], [0, 0, 8, 0, 0, 4, 0, 0, 6], [0, 0, 0, 8, 0, 1, 0, 0, 3], [0, 0, 0, 0, 24, 0, 18, 8, 7], [0, 0, 0, 0, 0, 120, 21, 70, 11]])
    let U: RingMatrix = RingMatrix([[3, 13, 4, -6, 4, 0], [0, 5, 1, -1, 3, 1], [0, -3, -1, 0, -2, -1], [-4, -16, -6, 7, -5, -1], [0, -7, 0, 3, -4, 0], [-1, -4, -1, 2, -1, 1]])
    
    let hnf: (U: RingMatrix, A: RingMatrix, rp: [Int]) = try m.HermiteNormalForm()
    
    assertEqual(hnf.U <*> m, hnf.A)
    assertEqual(hnf.U, U)
    assertEqual(hnf.A, A)
  }
  
  func testHermitianNormalFormGeneral() throws
  {
    for _ in 1...1000
    {
      let m: RingMatrix = RingMatrix.random(rows: Int.random(in: 3...6), columns: Int.random(in: 3...6))
    
      let hnf: (U: RingMatrix, A: RingMatrix, rp: [Int]) = try m.HermiteNormalForm()
    
      assertEqual(hnf.U <*> m, hnf.A)
    }
  }
  
  // MARK: - SmithNormalForm
  
  func testSmithNormalForm() throws
  {
    let m: RingMatrix = RingMatrix([[2, 4, 4], [-6 ,6, 12], [10, 4, 16]])
    
    let hnf: (U: RingMatrix, V: RingMatrix, A: RingMatrix) = try m.SmithNormalForm()
    
    print(hnf.U)
    print(hnf.V)
    print(hnf.A)
    //assertEqual(hnf.U <*> m, hnf.A)
    //assertEqual(hnf.U, U)
    //assertEqual(hnf.A, A)
  }
  
  func testSmithNormalForm2() throws
  {
    let m: RingMatrix = RingMatrix([[4, -52, -96, 16, -72, 314, 9, 186, -54], [3, 4, 0, 16, 24, 122, 39, 78, 24], [-5, 24, 48, -24, 24, -339, -45, -202, 1], [3, -12, -32, 16, 0, 106, 21, 70, -7], [-3, -16, -24, -16, -48, -134, -57, -86, -49], [2, -4, -8, 8, 0, 237, 42, 140, 19]])
    let U: RingMatrix = RingMatrix([[3, 13, 4, -6, 4, 0], [-4, -17, -7, 6, -6, -2], [-48, -204, -83, 73, -72, -23], [-303, -1291, -523, 464, -456, -145], [152096, 647611, 262547, -232747, 228669, 72883], [-455188, -1938143, -785743, 696554, -684350, -218123]])
    let V: RingMatrix = RingMatrix([[1, 0, 0, 0, 0, 0, 0, 0, 0], [0, 28, 389, -536, -1153, -2304, 0, 0, 0], [0, -15, -202, 279, 602, -201, 28, -4200, -627573], [0, 15, 193, -266, -572, -1494, 7, -1050, -156894], [0, -5, -65, 89, 190, 12418, -240, 36013, 5381137], [0, 1, 13, -18, -36, 2736, -56, 8400, 1255140], [0, 0, 0, 1, 8, -16036, 320, -48020, -7175254], [0, 0, 0, 0, -6, -10, 0, 6, 907], [0, 0, 1, -2, -8, -16, 0, 0, 4]])
    let A: RingMatrix = RingMatrix([[1, 0, 0, 0, 0, 0, 0, 0, 0], [0, 1, 0, 0, 0, 0, 0, 0, 0], [0, 0, 1, 0, 0, 0, 0, 0, 0 ], [0, 0, 0, 1, 0, 0, 0, 0, 0], [0, 0, 0, 0, 4, 0, 0, 0, 0], [0, 0, 0, 0, 0, 24, 0, 0, 0 ]])
    
    let smith: (U: RingMatrix, V: RingMatrix, A: RingMatrix) = try m.SmithNormalForm()
    
    assertEqual(smith.U <*> m <*> smith.V, smith.A)
    assertEqual(smith.U, U)
    assertEqual(smith.V, V)
    assertEqual(smith.A, A)
  }
  
  func testSmithNormalFormGeneral() throws
  {
    for _ in 1...10000
    {
      let m: RingMatrix = RingMatrix.random(rows: Int.random(in: 2...6), columns: Int.random(in: 2...6))
    
      let smith: (U: RingMatrix, V: RingMatrix, A: RingMatrix) = try m.SmithNormalForm()
    
      assertEqual(smith.U <*> m <*> smith.V, smith.A)
    }
  }
}
