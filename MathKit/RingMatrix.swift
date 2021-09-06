// RingMatrix.swift
//
// Copyright (c) 2016 Matthijs Hollemans
// Copyright (c) 2014-2015 Mattt Thompson (http://mattt.me)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// https://github.com/hollance/RingMatrix/blob/master/RingMatrix.swift

import Foundation
import Accelerate

public struct RingMatrix
{
  public let rows: Int
  public let columns: Int
  var grid: [Int]
}

// MARK: - Creating matrices

extension RingMatrix
{
  public init(rows: Int, columns: Int, repeatedValue: Int)
  {
    self.rows = rows
    self.columns = columns
    self.grid = .init(repeating: repeatedValue, count: rows * columns)
  }

  public init(size: (Int, Int), repeatedValue: Int)
  {
    self.init(rows: size.0, columns: size.1, repeatedValue: repeatedValue)
  }

  /* Creates a RingMatrix from an array: [[a, b], [c, d], [e, f]]. */
  public init(_ data: [[Int]])
  {
    self.init(data, range: 0..<data[0].count)
  }

  /* Extracts one or more columns into a new RingMatrix. */
  public init(_ data: [[Int]], range: CountableRange<Int>)
  {
    let m = data.count
    let n = range.upperBound - range.lowerBound
    self.init(rows: m, columns: n, repeatedValue: 0)

    for (i, row) in data.enumerated() {
      for j in range {
        self[i, j - range.startIndex] = row[j]
      }
    }
  }

  public init(_ data: [[Int]], range: CountableClosedRange<Int>)
  {
    self.init(data, range: CountableRange(range))
  }

  /* Creates a RingMatrix from a row vector or column vector. */
  public init(_ contents: [Int], isColumnVector: Bool = false)
  {
    if isColumnVector {
      self.rows = contents.count
      self.columns = 1
    } else {
      self.rows = 1
      self.columns = contents.count
    }
    self.grid = contents
  }

  /* Creates a RingMatrix containing the numbers in the specified range. */
  public init(_ range: CountableRange<Int>, isColumnVector: Bool = false)
  {
    if isColumnVector
    {
      self.init(rows: 1, columns: range.upperBound - range.lowerBound, repeatedValue: 0)
      for c in range
      {
        self[0, c - range.lowerBound] = Int(c)
      }
    }
    else
    {
      self.init(rows: range.upperBound - range.lowerBound, columns: 1, repeatedValue: 0)
      for r in range
      {
        self[r - range.lowerBound, 0] = Int(r)
      }
    }
  }

  public init(_ range: CountableClosedRange<Int>, isColumnVector: Bool = false)
  {
    self.init(CountableRange(range), isColumnVector: isColumnVector)
  }
  
  public init(matrix: RingMatrix)
  {
    self.columns = matrix.columns
    self.rows = matrix.rows
    let size: Int = columns * rows
    grid = [Int](repeating: 0, count: size)
    for i in 0..<size
    {
      self.grid[i] = matrix.grid[i]
    }
    
  }
  
  public init(Int3x3: [int3x3], denominator: Int = 1)
  {
    self.columns = 3
    self.rows = Int3x3.count * 3

    let size: Int = columns * rows
    grid = [Int](repeating: 0, count: size)
    
    for i in 0..<Int3x3.count
    {
      for row in 0..<3
      {
        for column in 0..<3
        {
          self[row + i * 3,column] = Int(Int3x3[i][column,row])
        }
      }
    }
  }
}

extension RingMatrix
{
  /* Creates a RingMatrix where each element is 0. */
  public static func zeros(rows: Int, columns: Int) -> RingMatrix
  {
    return RingMatrix(rows: rows, columns: columns, repeatedValue: 0)
  }

  public static func zeros(size: (Int, Int)) -> RingMatrix
  {
    return RingMatrix(size: size, repeatedValue: 0)
  }

  /* Creates a RingMatrix where each element is 1. */
  public static func ones(rows: Int, columns: Int) -> RingMatrix
  {
    return RingMatrix(rows: rows, columns: columns, repeatedValue: 1)
  }

  public static func ones(size: (Int, Int)) -> RingMatrix
  {
    return RingMatrix(size: size, repeatedValue: 1)
  }

  /* Creates a (square) identity RingMatrix. */
  public static func identity(size: Int) -> RingMatrix
  {
    var m = zeros(rows: size, columns: size)
    for i in 0..<size { m[i, i] = 1 }
    return m
  }

  /* Creates a RingMatrix of random values between 0.0 and 1.0 (inclusive). */
  public static func random(rows: Int, columns: Int) -> RingMatrix
  {
    var m = zeros(rows: rows, columns: columns)
    for r in 0..<rows
    {
      for c in 0..<columns
      {
        m[r, c] = Int.random(in: -10...10)
      }
    }
    return m
  }
}

extension RingMatrix: ExpressibleByArrayLiteral
{
  /* Array literals are interpreted as row vectors. */
  public init(arrayLiteral: Int...)
  {
    self.rows = 1
    self.columns = arrayLiteral.count
    self.grid = arrayLiteral
  }
}

extension RingMatrix
{
  /* Duplicates a row vector across "d" rows. */
  public func tile(_ d: Int) -> RingMatrix
  {
    precondition(rows == 1)
    var m = RingMatrix.zeros(rows: d, columns: columns)

    for r in 0..<d {
      for c in 0..<columns {
        m[r, c] = self[0, c]
      }
    }
    
    return m
  }
}

/*
extension RingMatrix {
  /* Copies the contents of an NSData object into the RingMatrix. */
  public init(rows: Int, columns: Int, data: NSData) {
    precondition(data.length >= rows * columns * MemoryLayout<Double>.stride)
    self.init(rows: rows, columns: columns, repeatedValue: 0)

    grid.withUnsafeMutableBufferPointer { dst in
      let src = UnsafePointer<Double>(OpaquePointer(data.bytes))
      cblas_dcopy(Int32(rows * columns), src, 1, dst.baseAddress, 1)
    }
  }

  /* Copies the contents of the RingMatrix into an NSData object. */
  public var data: NSData? {
    if let data = NSMutableData(length: rows * columns * MemoryLayout<Int>.stride) {
      grid.withUnsafeBufferPointer { src in
        let dst = UnsafeMutablePointer<Double>(OpaquePointer(data.bytes))
        cblas_dcopy(Int32(rows * columns), src.baseAddress, 1, dst, 1)
      }
      return data
    } else {
      return nil
    }
  }
}*/

// MARK: - Querying the RingMatrix

extension RingMatrix
{
  public var size: (Int, Int)
  {
    return (rows, columns)
  }

  /* Returns the total number of elements in the RingMatrix. */
  public var count: Int
  {
    return rows * columns
  }

  /* Returns the largest dimension. */
  public var length: Int
  {
    return Swift.max(rows, columns)
  }

  public subscript(row: Int, column: Int) -> Int
  {
    get { return grid[(row * columns) + column] }
    set { grid[(row * columns) + column] = newValue }
  }

  /* Subscript for when the RingMatrix is a row or column vector. */
  public subscript(i: Int) -> Int
  {
    get
    {
      precondition(rows == 1 || columns == 1, "Not a row or column vector")
      return grid[i]
    }
    set
    {
      precondition(rows == 1 || columns == 1, "Not a row or column vector")
      grid[i] = newValue
    }
  }

  /* Get or set an entire row. */
  public subscript(row r: Int) -> RingMatrix
  {
    get
    {
      var v = RingMatrix.zeros(rows: 1, columns: columns)

      for c in 0..<columns {
        v[c] = self[r, c]
      }
     
      return v
    }
    set(v)
    {
      precondition(v.rows == 1 && v.columns == columns, "Not a compatible row vector")

      for c in 0..<columns {
        self[r, c] = v[c]
      }
    }
  }

  /* Get or set multiple rows. */
  public subscript(rows range: CountableRange<Int>) -> RingMatrix
  {
    get
    {
      precondition(range.upperBound <= rows, "Invalid range")

      var m = RingMatrix.zeros(rows: range.upperBound - range.lowerBound, columns: columns)
      for r in range {
        for c in 0..<columns {
          m[r - range.lowerBound, c] = self[r, c]
        }
      }
      return m
    }
    set(m)
    {
      precondition(range.upperBound <= rows, "Invalid range")

      for r in range {
        for c in 0..<columns {
          self[r, c] = m[r - range.lowerBound, c]
        }
      }
    }
  }

  public subscript(rows range: CountableClosedRange<Int>) -> RingMatrix
  {
    get {
      return self[rows: CountableRange(range)]
    }
    set(m) {
      self[rows: CountableRange(range)] = m
    }
  }

  /* Gets just the rows specified, in that order. */
  public subscript(rows rowIndices: [Int]) -> RingMatrix {
    var m = RingMatrix.zeros(rows: rowIndices.count, columns: columns)

    for (i, r) in rowIndices.enumerated() {
      for c in 0..<columns {
        m[i, c] = self[r, c]
      }
    }
  
    return m
  }

  /* Get or set an entire column. */
 
  public subscript(column c: Int) -> RingMatrix
  {
    get
    {
      var v = RingMatrix.zeros(rows: rows, columns: 1)

      for r in 0..<rows
      {
        v[r] = self[r, c]
      }
      
      return v
    }
    set(v)
    {
      precondition(v.rows == rows && v.columns == 1, "Not a compatible column vector")
      
      for r in 0..<rows {
        self[r, c] = v[r]
      }
    }
  }

  /* Get or set multiple columns. */
  public subscript(columns range: CountableRange<Int>) -> RingMatrix
  {
    get
    {
      precondition(range.upperBound <= columns, "Invalid range")

      var m = RingMatrix.zeros(rows: rows, columns: range.upperBound - range.lowerBound)
      for r in 0..<rows {
        for c in range {
          m[r, c - range.lowerBound] = self[r, c]
        }
      }
      return m
    }
    set(m)
    {
      precondition(range.upperBound <= columns, "Invalid range")

      for r in 0..<rows {
        for c in range {
          self[r, c] = m[r, c - range.lowerBound]
        }
      }
    }
  }

  public subscript(columns range: CountableClosedRange<Int>) -> RingMatrix
  {
    get
    {
      return self[columns: CountableRange(range)]
    }
    set(m)
    {
      self[columns: CountableRange(range)] = m
    }
  }

  /* Useful for when the RingMatrix is 1x1 or you want to get the first element. */
  public var scalar: Int
  {
    return grid[0]
  }

  /* Converts the RingMatrix into a 2-dimensional array. */
  public var array: [[Int]]
  {
    var a = [[Int]](repeating: [Int](repeating: 0, count: columns), count: rows)
    for r in 0..<rows
    {
      for c in 0..<columns
      {
        a[r][c] = self[r, c]
      }
    }
    return a
  }
  
  public subscript(startRow: Int, startColumn: Int, rows: Int, columns: Int) -> RingMatrix
  {
    get
    {
      var matrix: RingMatrix = RingMatrix(rows: rows, columns: columns, repeatedValue: 0)
      for i in 0..<rows
      {
        for j in 0..<columns
        {
          matrix[i,j] = self[i+startRow, j+startColumn]
        }
      }
        
      return matrix
    }
    set(replacement)
    {
      precondition(startRow + replacement.rows <= self.rows, "Not a valid replacement")
      precondition(startColumn + replacement.columns <= self.columns, "Not a valid replacement")
      
      for i in 0..<replacement.rows
      {
        for j in 0..<replacement.columns
        {
          self[startRow + i, startColumn + j] = replacement[i, j]
        }
      }
    }
  }
  
  public func transposed() -> RingMatrix
  {
    var result: RingMatrix = RingMatrix(rows: self.columns, columns: self.rows, repeatedValue: 0)
    for i in 0..<self.rows
    {
      for j in 0..<self.columns
      {
        result[j,i] = self[i,j]
      }
    }
    return result
  }
  
  public mutating func swapColumns(a: Int, b: Int)
  {
    for i in 0..<self.rows
    {
      let temp: Int = self[i,a]
      self[i,a] = self[i,b]
      self[i,b] = temp
    }
  }
}

// MARK: - Printable

extension RingMatrix: CustomStringConvertible {
  public var description: String {
    var description = ""

    for i in 0..<rows {
      let contents = (0..<columns).map{ String(format: "%5d", self[i, $0]) }.joined(separator: " ")

      switch (i, rows) {
      case (0, 1):
        description += "( \(contents) )\n"
      case (0, _):
        description += "⎛ \(contents) ⎞\n"
      case (rows - 1, _):
        description += "⎝ \(contents) ⎠\n"
      default:
        description += "⎜ \(contents) ⎥\n"
      }
    }
    return description
  }
}

// MARK: - SequenceType

/* Lets you iterate through the rows of the RingMatrix. */
extension RingMatrix: Sequence {
  public func makeIterator() -> AnyIterator<ArraySlice<Int>> {
    let endIndex = rows * columns
    var nextRowStartIndex = 0
    return AnyIterator {
      if nextRowStartIndex == endIndex {
        return nil
      } else {
        let currentRowStartIndex = nextRowStartIndex
        nextRowStartIndex += self.columns
        return self.grid[currentRowStartIndex..<nextRowStartIndex]
      }
    }
  }
}

// MARK: - Arithmetic

infix operator <*> : MultiplicationPrecedence

/* Multiplies two matrices, or a matrix with a vector. */
public func <*> (lhs: RingMatrix, rhs: RingMatrix) -> RingMatrix
{
  precondition(lhs.columns == rhs.rows, "Cannot multiply \(lhs.rows)×\(lhs.columns) matrix and \(rhs.rows)×\(rhs.columns) matrix")

  var results = RingMatrix(rows: lhs.rows, columns: rhs.columns, repeatedValue: 0)
  for i in 0..<lhs.rows
  {
    for j in 0..<rhs.columns
    {
      var v: Int = 0
      for k in 0..<lhs.columns
      {
        v += lhs[i,k] * rhs[k,j]
      }
      results[i,j] = v
    }
  }
  return results
}

/*
 Multiplies each element of the lhs matrix by each element of the rhs matrix.

 Either:
 - both matrices have the same size
 - rhs is a row vector with an equal number of columns as lhs
 - rhs is a column vector with an equal number of rows as lhs
 */
public func * (lhs: RingMatrix, rhs: RingMatrix) -> RingMatrix
{
  if lhs.columns == rhs.columns {
    if rhs.rows == 1 {   // rhs is row vector
 
      var results = lhs
      for r in 0..<results.rows {
        for c in 0..<results.columns {
          results[r, c] *= rhs[0, c]
        }
      }
      return results

    } else if lhs.rows == rhs.rows {   // lhs and rhs are same size
      
      var results = lhs
      for r in 0..<results.rows {
        for c in 0..<results.columns {
          results[r, c] *= rhs[r, c]
        }
      }
      return results
    }

  } else if lhs.rows == rhs.rows && rhs.columns == 1 {  // rhs is column vector
    
    var results = lhs
    for c in 0..<results.columns {
      for r in 0..<results.rows {
        results[r, c] *= rhs[r, 0]
      }
    }
    return results
    
  }

  fatalError("Cannot element-wise multiply \(lhs.rows)×\(lhs.columns) matrix and \(rhs.rows)×\(rhs.columns) matrix")
}

// MARK: - HermiteNormalForm

extension RingMatrix
{
  public func submatrix(startRow: Int, startColumn: Int, numberOfRows: Int, numberOfColumns: Int) -> RingMatrix
  {    
    var matrix: RingMatrix = RingMatrix(rows: numberOfRows, columns: numberOfColumns, repeatedValue: 0)
    for i in 0..<numberOfRows
    {
      for j in 0..<numberOfColumns
      {
        matrix[i,j] = self[i+startRow, j+startColumn]
      }
    }
    
    return matrix
  }
  
  public mutating func assignSubmatrix(startRow: Int, startColumn: Int, integerMatrix replacement: RingMatrix)
  {
    for i in 0..<replacement.rows
    {
      for j in 0..<replacement.columns
      {
        self[startRow + i, startColumn + j] = replacement[i, j]
      }
    }
  }
  
  public func HermiteNormalForm() throws ->(RingMatrix, RingMatrix,[Int])
  {
    // Create larger matrix
    var Apad: RingMatrix = RingMatrix(rows: self.rows + 2, columns: self.columns + 2, repeatedValue: 0)
    Apad[0, 0] = 1
    Apad[self.rows + 1, self.columns + 1] = 1
    Apad.assignSubmatrix(startRow: 1, startColumn: 1, integerMatrix: self)
    
    var rp: [Int] = [0]
    var r: Int = 0
    // Create transformation matrix
    var QQ: RingMatrix = RingMatrix.identity(size: self.rows + 2)
    var CC: RingMatrix = RingMatrix.identity(size: self.rows + 2)
    
    // Begin computing the HNF
    for j in 1..<Apad.columns
    {
      // Search for next rank increase
      var found: Bool = false
      for k in (r + 1)..<Apad.rows
      {
        if Apad[r, rp[r]] * Apad[k, j] != Apad[r, j] * Apad[k, rp[r]]
        {
          found = true
        }
      }
     
      // Found something?
      if found
      {
        // Increase rank
        rp.append(j)
        r += 1
        
        // Do column reduction
        let columnReduction: (Q: RingMatrix, C: RingMatrix, Apad: RingMatrix) = try ColumnReduction(A1: Apad, col_1: rp[r - 1], col_2: rp[r], row_start: r - 1)
        Apad = columnReduction.Apad
        
        // Update CC
        for i in (r + 1)..<columnReduction.C.columns
        {
          CC[r, i] = columnReduction.C[r, i]
        }
        // Update QQ to QQ * C^{-1}
        for l in (r + 1)..<columnReduction.C.columns
        {
          if columnReduction.C[r, l] != 0
          {
            for i in 0..<QQ.rows
            {
              QQ[i, l] -= columnReduction.C[r, l] * QQ[i, r]
            }
          }
        }
        // Update QQ to C * QQ
        for i in (r + 1)..<columnReduction.C.columns
        {
          if columnReduction.C[r, i] != 0
          {
            for j in 0..<QQ.rows
            {
              QQ[r, j] += columnReduction.C[r, i] * QQ[i, j]
            }
          }
        }
        // Update QQ to Q * QQ
        for i in 0..<QQ.rows
        {
          if i != r - 1 && i != r
          {
            for l in 0..<QQ.columns
            {
              QQ[i, l] = QQ[i, l] + columnReduction.Q[i, r - 1] * QQ[r - 1, l] + columnReduction.Q[i, r] * QQ[r, l]
            }
          }
        }
        let a = columnReduction.Q[r - 1, r - 1]
        let b = columnReduction.Q[r - 1, r    ]
        let c = columnReduction.Q[r,     r - 1]
        let d = columnReduction.Q[r,     r    ]
        for l in 0..<QQ.columns
        {
          let temp1: Int = a * QQ[r - 1, l] + b * QQ[r, l]
          let temp2: Int = c * QQ[r - 1, l] + d * QQ[r, l]
          QQ[r - 1, l] = temp1
          QQ[r, l] = temp2
        }
      }
    }
    // Compute the transformation matrix
    let T: RingMatrix = QQ <*> CC
    
    
    // Extract the necessary matrices
    var TT = RingMatrix(rows: self.rows, columns: self.rows, repeatedValue: 0)
   
    if r>1
    {
      TT.assignSubmatrix(startRow: 0, startColumn: 0, integerMatrix: T.submatrix(startRow: 1, startColumn: 1, numberOfRows: r - 2, numberOfColumns: self.rows))
      TT.assignSubmatrix(startRow: r - 2, startColumn: 0, integerMatrix: T.submatrix(startRow: r - 1, startColumn: 1, numberOfRows: self.rows - r + 2, numberOfColumns: self.rows))
    }
    let AA: RingMatrix = RingMatrix(matrix: Apad.submatrix(startRow: 1, startColumn: 1, numberOfRows: self.rows, numberOfColumns: self.columns))
    // Extract rank profile
    rp = Array(rp[1..<r])
    for i in 0..<rp.count
    {
      rp[i] -= 1
    }
    return (TT, AA, rp)
  }
  
  public func Algorithm_6_14(a: Int, b: Int, N: Int, Nfact: [Int]) throws -> Any
  {
    var k: Int = 0
    var HNF_C_Iwaniec: Int = IntegerMatrix.HNF_C_Iwaniec
    
    //if N==0 {return -16000}
    guard N>1 else {throw NumericalError.logOfZero}
    
    while(true)
    {
      if N == 2
      {
        k = 1
      }
      else
      {
        let temp: Double = log(Double(N))/log(2.0)
        k = Int(Double(HNF_C_Iwaniec) * temp * (pow(log(temp),2)))
      }
      
      // Prepare B
      var B: [Bool] = [Bool](repeating: true, count: k+1)
      
      // Compute residues
      let t: Int = Nfact.count
      var ai: [Int] = [Int](repeating: 0, count: t)
      var bi: [Int] = [Int](repeating: 0, count: t)
     
      for i in 0..<t
      {
        ai[i] = try Int.modulo(a: a, b: Nfact[i])
        bi[i] = try Int.modulo(a: b, b: Nfact[i])
      }
      
      // Compute extended GCDs
      var xi: [Int] = [Int](repeating: 0, count: t)
      for i in 0..<t
      {
        let extendedGCD: (gi: Int, xi: Int, yi: Int) = Ring.extendedGreatestCommonDivisor(a: bi[i], b: Nfact[i])
        xi[i] = extendedGCD.xi
        if (1 < extendedGCD.gi) && (extendedGCD.gi < Nfact[i])
        {
          return Array(Nfact[0..<i]) + Array([extendedGCD.gi, Nfact[i] / extendedGCD.gi]) + Array(Nfact[i+1..<t])
        }
      }
      
      // Do sieving
      for i in 0..<t
      {
        if bi[i] != 0
        {
          let si: Int =  try Int.modulo(a: -ai[i] * xi[i], b: Nfact[i])
          var idx: Int = si
          while idx <= k
          {
            B[idx] = false
            idx += Nfact[i]
          }
        }
      }
      // Find result
      for c in 0..<(k+1)
      {
        if B[c] == true
        {
          for i in 0..<t
          {
            let gi: Int = Ring.greatestCommonDivisor(a: ai[i] + c * bi[i], b: Nfact[i])
            if gi > 1
            {
              return Array(Nfact[0..<i]) + Array([gi, Nfact[i] / gi]) + Array(Nfact[(i+1)..<t])
            }
          }
          return c
        }
      }
      HNF_C_Iwaniec *= 2
    }
  }
  

  
  private func RemovedDuplicates(array: [Int]) -> [Int]
  {
    var res: [Int] = []
  
    if array.count > 0
    {
      res.append(array[0])
      for i in 1..<array.count
      {
        if array[i] != res[res.count-1]
        {
          res.append(array[i])
        }
      }
    }
    return res
  }
  
  private func Conditioning(A: RingMatrix, col_1: Int, col_2: Int, row_start: Int) throws -> ([Int], [Int])
  {
   
    let k: Int = A.rows - row_start - 2
    let d11 = A[row_start, col_1]
    let d12 = A[row_start, col_2]
    var d21 = A[row_start + 1, col_1]
    var d22 = A[row_start + 1, col_2]
    var ci = [Int](repeating: 0, count : k)
    if d11 * d22 == d12 * d21
    {
      for s in (row_start + 2)..<A.rows
      {
        if d11 * A[s, col_2] != d12 * A[s, col_1]
        {
          ci[s - row_start - 2] = 1
          d21 += A[s, col_1]
          d22 += A[s, col_2]
          break
        }
      }
    }
    
    // We now have  det( d11 & d12 \\ d21 & d22 ) \neq 0.
    if d11 > 1
    {
      // Perform a modified Algorithm 6.15:
      var F: [Int] = [d11]
      var ahat: Int = d21
      var i: Int = 0
      var has_gi: Bool = false
      var neg = false
      
      var biprime: Int = 0
      var ahatprime: Int = 0
      var bi: Int = 0
      var bip: Int = 0
      while i < k
      {
        if !has_gi
        {
          bi = A[row_start + 2 + i, col_1]
          bip = A[row_start + 2 + i, col_2]
          let gi = try Int.greatestCommonDivisor(a: ahat, b: bi)
          if gi == 0
          {
            i += 1
            continue
          }
          ahatprime = try Int.modulo(a: (ahat / gi), b: d11)
          biprime = try Int.modulo(a: (bi / gi), b: d11)
          neg = false
          if (d11 * d22 - d12 * d21).sign != (d11 * bip - d12 * bi).sign
          {
            biprime = -biprime
            neg = true
          }
          has_gi = true
        }
        
        let res: Any = try Algorithm_6_14(a: ahatprime, b: biprime, N: d11, Nfact: F)
        if res is [Int]
        {
          F = res as! [Int]
          F.sort()
          F = RemovedDuplicates(array: F)
        }
        else
        {
          if neg
          {
            ci[i] -= (res as! Int)
            d21 -= (res as! Int) * bi
            d22 -= (res as! Int) * bip
            ahat = try Int.modulo(a: (ahat - (res as! Int) * bi), b: d11)
          }
          else
          {
            ci[i] += (res as! Int)
            d21 += (res as! Int) * bi
            d22 += (res as! Int) * bip
            ahat = try Int.modulo(a: (ahat + (res as! Int) * bi), b: d11)
          }
          has_gi = false
          i += 1

        }
      }
    }
  
    return ([d21,d22],ci)
  }
  
  private func ColumnReduction(A1: RingMatrix, col_1: Int, col_2: Int, row_start: Int) throws -> (RingMatrix, RingMatrix, RingMatrix)
  {
    var A: RingMatrix = A1
    let n: Int = A.rows
    let m: Int = A.columns
    
    // Apply conditioning subroutine
    let conditioning: (D: [Int], ci: [Int]) = try Conditioning(A: A, col_1: col_1, col_2: col_2, row_start: row_start)
    
    // Initialize C
    var C: RingMatrix = RingMatrix.identity(size: n)
    
    for j in 0..<conditioning.ci.count
    {
      C[row_start + 1, row_start + 2 + j] = conditioning.ci[j]
    }
    // Transform A
    for j in col_1..<m
    {
      var v: Int = A[row_start + 1, j]
      for i in 0..<conditioning.ci.count
      {
        v += conditioning.ci[i] * A[row_start + 2 + i, j]
      }
      A[row_start + 1, j] = v
    }
    
    // Compute Q transform
    let extendedGCD: (t1: Int, m1: Int, m2: Int) = Ring.extendedGreatestCommonDivisor(a: A[row_start, col_1], b: A[row_start + 1, col_1])
    
    let s: Int = (A[row_start, col_1] * A[row_start + 1, col_2] - A[row_start, col_2] * A[row_start + 1, col_1]).sign
    var Q = RingMatrix.identity(size: n)
    let q1: Int = -s * A[row_start + 1, col_1] / extendedGCD.t1
    let q2: Int = s * A[row_start, col_1] / extendedGCD.t1
    Q[row_start, row_start] = extendedGCD.m1
    Q[row_start, row_start + 1] = extendedGCD.m2
    Q[row_start + 1, row_start] = q1
    Q[row_start + 1, row_start + 1] = q2
    
    // Transform A
    let v: Int  = extendedGCD.m1 * A[row_start, col_2] + extendedGCD.m2 * A[row_start + 1, col_2]
    let t2: Int = q1 * A[row_start, col_2] + q2 * A[row_start + 1, col_2]
    A[row_start, col_1] = extendedGCD.t1
    A[row_start, col_2] = v
    A[row_start + 1, col_1] = 0
    A[row_start + 1, col_2] = t2
    for j in (col_1 + 1)..<m
    {
      if j != col_2
      {
        let v1: Int = extendedGCD.m1 * A[row_start, j] + extendedGCD.m2 * A[row_start + 1, j]
        let v2: Int = q1 * A[row_start, j] + q2 * A[row_start + 1, j]
        A[row_start, j] = v1
        A[row_start + 1, j] = v2
      }
    }
    
    
    // Clean up above
    for i in 0..<row_start
    {
      let s1: Int = try -Int.floorDivision(a: A[i, col_1], b: extendedGCD.t1)
      for j in col_1..<m
      {
        A[i, j] = A[i, j] + s1 * A[row_start, j]
      }
      let s2: Int = try -Int.floorDivision(a: A[i, col_2], b: t2)
      for j in col_1..<m
      {
         A[i, j] = A[i, j] + s2 * A[row_start + 1, j]
      }
      for j in 0..<n
      {
        let temp: Int = Q[i, j] + s1 * Q[row_start, j] + s2 * Q[row_start + 1, j]
        Q[i, j] = temp
      }
    }
    
    // Clean up below
    for i in (row_start + 2)..<n
    {
      // assert A[i, col_1] % t1 == 0
      let s1: Int = try -Int.floorDivision(a: A[i, col_1], b: extendedGCD.t1)
      for j in col_1..<m
      {
        A[i, j] += s1 * A[row_start, j]
      }
      let s2: Int = try -Int.floorDivision(a: A[i, col_2], b: t2)
      for j in col_1..<m
      {
        A[i, j] += s2 * A[row_start + 1, j]
      }
      for j in 0..<n
      {
        Q[i, j] +=  s1 * Q[row_start, j] + s2 * Q[row_start + 1, j]
      }
    }
    
    return (Q, C, A)
  }
}

// MARK: - SmithNormalForm

extension RingMatrix
{
  public func SmithNormalForm() throws -> (RingMatrix, RingMatrix, RingMatrix)
  {
    let n: Int = self.rows
    let m: Int = self.columns
    
    let hnf: (U: RingMatrix, A: RingMatrix, rp: [Int]) = try HermiteNormalForm()
    
    var U: RingMatrix = hnf.U
    var A: RingMatrix = hnf.A
    let r: Int = hnf.rp.count
            
    var V: RingMatrix = RingMatrix.identity(size: m)
    
    // Transform A via V so that the left r x r block of A is invertible
    for i in 0..<r
    {
      if hnf.rp[i] > i
      {
        A.swapColumns(a: i, b: hnf.rp[i])
        V.swapColumns(a: i, b: hnf.rp[i])
      }
    }
    
    // Phase one
    for i in 0..<r
    {
      try Smith_Theorem5(A: &A, U: &U, V: &V, col: i)
    }
    
    var beg: Int = 0
    while beg < r && A[beg, beg] == 1
    {
      beg += 1
    }
    
    // Phase two
    if beg < r && r < m
    {
      for i in beg..<r
      {
        try Smith_Theorem8(A: &A, U: &U, V: &V, row: i, r: r)
      }
      
      // Run transposed Phase One
      var AA = A.submatrix(startRow: beg, startColumn: beg, numberOfRows: r - beg, numberOfColumns: r - beg).transposed()
      var UU = RingMatrix.identity(size: r - beg)
      var VV = RingMatrix.identity(size: r - beg)
      // Check if it is actually not a diagonal matrix
      for i in 0..<(r - beg)
      {
        try Smith_Theorem5(A: &AA, U: &UU, V: &VV, col: i)
      }
      
      // Insert AA
      AA = AA.transposed()
      A.assignSubmatrix(startRow: beg, startColumn: beg, integerMatrix: AA.transposed())
      
     // Insert transformations
      let temp: RingMatrix = UU
      UU = VV.transposed()
      VV = temp.transposed()
      
      U.assignSubmatrix(startRow: beg, startColumn: 0, integerMatrix: UU <*> U.submatrix(startRow: beg, startColumn: 0, numberOfRows: r - beg, numberOfColumns: n))
      V.assignSubmatrix(startRow: 0, startColumn: beg, integerMatrix: V.submatrix(startRow: 0, startColumn: beg, numberOfRows: m, numberOfColumns: r - beg) <*> VV)

    }
    
    //V.denominator = self.denominator
    return (U, V, A)
  }
  
  private func Smith_Theorem5(A: inout RingMatrix, U: inout RingMatrix, V: inout RingMatrix, col: Int) throws
  {
    let n: Int = A.rows
    let m: Int = A.columns
    
    // Lemma 6:
    for i in (0..<col).reversed()
    {
      // Compute ci[0] such that GCD(A[i, col] + ci[0] * A[i + 1, col], A[i, i])
      // equals GCD(A[i, col], A[i + 1, col], A[i, i])
      let ci: [Int] = try Algorithm_6_15(a: A[i, col], bi: [A[i + 1, col]], N: A[i, i])
      
      // Add ci[0] times the (i+1)-th row to the i-th row
      for j in 0..<m
      {
        A[i, j] = A[i, j] + ci[0] * A[i + 1, j]
      }
      for j in 0..<n
      {
        U[i, j] = U[i, j] + ci[0] * U[i + 1, j]
      }
      
      // Reduce i-th row modulo A[i, i]
      for j in (i + 1)..<m
      {
        let divmod: (d: Int, r: Int) = try Int.divisionModulo(a: A[i, j], b: A[i, i])
        //let d: Int = Int.floorDivision(a: A[i, j], b: A[i, i])
        //let r: Int = ((A[i, j] % A[i, i]) + A[i, i]) % A[i, i]
        if divmod.d != 0
        {
          // Subtract d times the i-th column from the j-th column
          A[i, j] = divmod.r
          for k in 0..<m
          {
            V[k, j] = V[k, j] - divmod.d * V[k, i]
          }
        }
      }
    }
    
    // Lemma 7
    for j in 0..<col
    {
      // Apply lemma 7 to submatrix starting at (j, j)
      let extendedGCD: (s1: Int, s: Int, t: Int) = Ring.extendedGreatestCommonDivisor(a: A[j, j], b: A[j, col])
      let ss: Int = -A[j, col] / extendedGCD.s1
      let tt: Int = A[j, j] / extendedGCD.s1
      // Transform columns j and col by a 2x2 matrix
      A[j, j] = extendedGCD.s1
      A[j, col] = 0
      for i in (j + 1)..<n
      {
        let temp: Int = A[i, j]
        A[i, j] = extendedGCD.s * A[i, j] + extendedGCD.t * A[i, col]
        A[i, col] = ss * temp + tt * A[i, col]
      }
      for i in 0..<m
      {
        let temp: Int = V[i, j]
        V[i, j] = extendedGCD.s * V[i, j] + extendedGCD.t * V[i, col]
        V[i, col] = ss * temp + tt * V[i, col]
      }
      
      // Clear column j in rows below
      for i in (j + 1)..<n
      {
        let mul: Int = A[i, j] / A[j, j]
        if mul != 0
        {
          for jj in 0..<m
          {
            A[i, jj] = A[i, jj] - mul * A[j, jj]
          }
          for jj in 0..<n
          {
            U[i, jj] = U[i, jj] - mul * U[j, jj]
          }
        }
      }
      
      // Reduce j-th row modulo A[j, j]
      for jj in (j + 1)..<m
      {
        //d, r = divmod(A[j, jj], A[j, j])
        //let d: Int = Int.floorDivision(a: A[j, jj], b: A[j, j])
        //let r: Int = ((A[j, jj] % A[j, j]) + A[j, j]) % A[j, j]
        let divmod: (d: Int, r: Int) = try Int.divisionModulo(a: A[j, jj], b: A[j, j])
        if divmod.d != 0
        {
          // Subtract d times the i-th column from the j-th column
          A[j, jj] = divmod.r
          for k in 0..<m
          {
            V[k, jj] = V[k, jj] - divmod.d * V[k, j]
          }
        }
      }
    }
    
    // Make A[col, col] positive
    if A[col, col] < 0
    {
      for jj in col..<m
      {
        A[col, jj] = -A[col, jj]
      }
      for jj in 0..<n
      {
        U[col, jj] = -U[col, jj]
      }
    }
    
    // Reduce col-th row modulo A[col, col]
    for j in (col + 1)..<m
    {
      //d, r = divmod(A[col, j], A[col, col])
      //let d: Int = Int.floorDivision(a: A[col, j], b: A[col, col])
      //let r: Int = ((A[col, j] % A[col, col]) + A[col, col]) % A[col, col]
      let divmod: (d: Int, r: Int) = try Int.divisionModulo(a: A[col, j], b: A[col, col])
      if divmod.d != 0
      {
        // Subtract d times the col-th column from the j-th column
        A[col, j] = divmod.r
        for k in 0..<m
        {
          V[k, j] = V[k, j] - divmod.d * V[k, col]
        }
      }
    }
    
  }
  
  private func Smith_Theorem8(A: inout RingMatrix, U: inout RingMatrix, V: inout RingMatrix, row: Int, r: Int) throws
  {
    let n: Int = A.rows
    let m: Int = A.columns
    
    for j in r..<m
    {
      if A[row, j] != 0
      {
        let extendedGCD: (s1: Int, s: Int, t: Int) = Ring.extendedGreatestCommonDivisor(a: A[row, row], b: A[row, j])
        let ss: Int = -A[row, j] / extendedGCD.s1
        let tt: Int = A[row, row] / extendedGCD.s1
        // Transform columns row and j by a 2x2 matrix
        A[row, row] = extendedGCD.s1
        A[row, j] = 0
        
        for i in (row + 1)..<n
        {
          let temp: Int = A[i, row]
          A[i, row] = extendedGCD.s * A[i, row] + extendedGCD.t * A[i, j]
          A[i, j] = ss * temp + tt * A[i, j]
        }
        for i in 0..<m
        {
          let temp: Int = V[i, row]
          V[i, row] = extendedGCD.s * V[i, row] + extendedGCD.t * V[i, j]
          V[i, j] = ss * temp + tt * V[i, j]
        }
        
        // Reduce column row
        for i in (row + 1)..<n
        {
           let d: Int = try Int.floorDivision(a: A[i, row], b: A[row, row])
           if d != 0
           {
             for jj in 0..<m
             {
               A[i, jj] = A[i, jj] - d * A[row, jj]
            }
            for jj in 0..<n
            {
              U[i, jj] = U[i, jj] - d * U[row, jj]
            }
          }
        }
        // Reduce column row
        for i in (row + 1)..<n
        {
          let d: Int = try Int.floorDivision(a: A[i, row], b: A[row, row])
          if d != 0
          {
            for jj in 0..<m
            {
              A[i, jj] = A[i, jj] - d * A[row, jj]
            }
            for jj in 0..<n
            {
              U[i, jj] = U[i, jj] - d * U[row, jj]
            }
          }
        }
        
      }
    }
  }
  
  public func Algorithm_6_15(a: Int, bi: [Int], N: Int) throws -> [Int]
  {
    if N == 1
    {
      return [Int](repeating: 0, count: bi.count)
    }
    var F: [Int] = [N]
    var ahat: Int = a
    var i: Int = 0
    let n = bi.count
    var has_gi: Bool = false
    var ci: [Int] = [Int](repeating: 0, count: n)
    
    var ahatprime: Int = 0
    var biprime: Int = 0
    
    while i < n
    {
      if !has_gi
      {
        let gi: Int = Ring.greatestCommonDivisor(a: ahat, b: bi[i])
        if gi == 0
        {
          // both ahat and bi[i] are zero: take 0 as ci[i] and continue with next entry
          ci[i] = 0
          i += 1
          continue
        }
        ahatprime = (ahat / gi) % N
        biprime = (bi[i] / gi) % N
        has_gi = true
      }
      let res: Any = try Algorithm_6_14(a: ahatprime, b: biprime, N: N, Nfact: F)
      
      if res is [Int]
      {
        F = res as! [Int]
        F.sort()
        F = RemovedDuplicates(array: F)
      }
      else
      {
        ci[i] = (res as! Int)
        ahat = (ahat + (res as! Int) * bi[i]) % N
        i += 1
        has_gi = false
      }
    }
    return ci
  }
}
