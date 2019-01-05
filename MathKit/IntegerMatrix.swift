/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2019 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl            http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 scaldia@upo.es                http://www.upo.es/raspa/sofiacalero.php
 t.j.h.vlugt@tudelft.nl        http://homepage.tudelft.nl/v9k6y
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

import Foundation
import Accelerate

// Row-major order for numpy/python-compatibility
// The cblas/Accelerate framework has input-options for both column and row-major order

public struct IntegerMatrix
{
  var numberOfColumns: Int
  var numberOfRows: Int
  var elements: [Int]
  public var denominator: Int = 1
  
  public static let HNF_C_Iwaniec: Int = 3
  
  public init(numberOfRows: Int = 3, numberOfColumns: Int = 3, denominator: Int = 1)
  {
    self.denominator = denominator
    self.numberOfColumns = numberOfColumns
    self.numberOfRows = numberOfRows
    elements = [Int](repeating: 0, count: numberOfColumns * numberOfRows)
  }
  
  public init(rows: [[Int]], denominator: Int = 1)
  {
    self.denominator = denominator
    self.numberOfRows = rows.count
    self.numberOfColumns = rows.indices.map{rows[$0].count}.reduce(0){return max($0,$1)}
    elements = [Int](repeating: 0, count: numberOfColumns * numberOfRows)
    for i in 0..<numberOfRows
    {
      for j in 0..<rows[i].count
      {
        self[i,j] = rows[i][j]
      }
    }
  }
  
  public init(size: Int, diagonal: Int = 1)
  {
    self.denominator = 1
    self.numberOfColumns = size
    self.numberOfRows = size
    elements = [Int](repeating: 0, count: numberOfColumns * numberOfRows)
    
    for i in 0..<size
    {
      self[i,i] = diagonal
    }
  }
  
  public init(matrix: IntegerMatrix)
  {
    self.numberOfColumns = matrix.numberOfColumns
    self.numberOfRows = matrix.numberOfRows
    self.denominator = matrix.denominator
    let size: Int = numberOfColumns * numberOfRows
    elements = [Int](repeating: 0, count: size)
    for i in 0..<size
    {
      self.elements[i] = matrix[i]
    }
    
  }
  
  public init(Int3x3: [int3x3], denominator: Int = 1)
  {
    self.denominator = denominator
    self.numberOfColumns = 3
    self.numberOfRows = Int3x3.count * 3

    let size: Int = numberOfColumns * numberOfRows
    elements = [Int](repeating: 0, count: size)
    
    var multiplier: Int = 1
    for i in 0..<Int3x3.count
    {
      multiplier *= Int3x3[i].denominator
    }
    
    for i in 0..<Int3x3.count
    {
      for row in 0..<3
      {
        for column in 0..<3
        {
          self[row + i * 3,column] = (multiplier / Int3x3[i].denominator) * Int(Int3x3[i][column,row])
        }
      }
      self.denominator = multiplier
    }
    
    self.cleanUp()
  }
  
  public func printMatrix()
  {
    //Swift.print("matrix")
    for row in 0..<numberOfRows
    {
      for column in 0..<numberOfColumns
      {
        let value: Int = self[row,column]
        let gcd: Int = Int.greatestCommonDivisor(a: value, b: self.denominator)
        //let gcd: Int = 1
        if gcd != 0 && self.denominator/gcd == 1
        {
          //let string: String = String(format: "%d",value/gcd)
          //Swift.print("\(string) ", terminator:"")
        }
        else
        {
          
          //let string: String = String(format: "%d/%d",value/gcd, self.denominator/gcd)
          //Swift.print("\(string) ", terminator:"")
        }

        
      }
      //Swift.print("", terminator:"\n")
    }
  }
  
  public func printMatrix2()
  {
    /*
    //Swift.print("matrix")
    for row in 0..<numberOfRows
    {
      for column in 0..<numberOfColumns
      {
        //let string: String = String(format: "%d/%d",self[row,column], self.denominator)
        //Swift.print("\(string) ", terminator:"")
      }
      //Swift.print("", terminator:"\n")
    }
   */
  }
  
  public static func identity(size: Int) -> IntegerMatrix
  {
    return IntegerMatrix(size: size, diagonal: 1)
  }
  
  public static func random(numberOfRows: Int, numberOfColumns: Int, upperbound: UInt32) -> IntegerMatrix
  {
    var matrix: IntegerMatrix = IntegerMatrix(numberOfRows: numberOfRows, numberOfColumns: numberOfColumns)
    
    for row in 0..<numberOfRows
    {
      for column in 0..<numberOfColumns
      {
        matrix[row,column] = Int(arc4random_uniform(2*upperbound + 1)) - Int(upperbound)
      }
    }
    
    return matrix
  }
  
  public var greatestCommonDivisor: Int
  {
    if elements.count == 0
    {
      return 0
    }
    return self.elements.reduce(elements[0]){Int.greatestCommonDivisor(a: $0, b: $1)}
  }
  
  public mutating func cleanUp()
  {
    if abs(self.denominator) > 1
    {
      let gcd: Int = self.greatestCommonDivisor
    
      self.denominator /= gcd
      for row in 0..<numberOfRows
      {
        for column in 0..<numberOfColumns
        {
          self[row,column] /= gcd
        }
      }
    }
  }
  
  public static func randomInvertible(numberOfRows: Int, numberOfColumns: Int) -> IntegerMatrix
  {
    var A: IntegerMatrix = IntegerMatrix(numberOfRows: numberOfRows, numberOfColumns: numberOfColumns)
    
    for i in 0..<min(numberOfRows,numberOfColumns)
    {
      A[i,i] = 1
    }
    
    // Apply random row operations
    for _ in 0..<100
    {
      let r1: Int = Int(arc4random_uniform(UInt32(numberOfRows)))
      let r2: Int = Int(arc4random_uniform(UInt32(numberOfRows)))
      if r1 != r2
      {
        let v: Int = Int(arc4random_uniform(5)) - 2
        for j in 0..<numberOfColumns
        {
          A[r1, j] = A[r1, j] + v * A[r2, j]
        }
      }
    }
    
    return A
  }


  
  public func row(_ row: Int) -> [Int]
  {
    var rowVector: [Int] = [Int](repeating: 0, count: self.numberOfColumns)
    
    for i in 0..<numberOfColumns
    {
      rowVector[i] = self[row,i]
    }
    return rowVector
  }
  
  public func column(_ column: Int) -> [Int]
  {
    var columnVector: [Int] = [Int](repeating: 0, count: self.numberOfRows)
    
    for i in 0..<numberOfRows
    {
      columnVector[i] = self[i, column]
    }
    return columnVector
  }
  
  public func submatrix(startRow: Int, startColumn: Int, numberOfRows: Int, numberOfColumns: Int) -> IntegerMatrix
  {
    // return Submatrix(self.__matrix, self.__row_start + row, self.__col_start + col, rows, cols)
    
    var matrix: IntegerMatrix = IntegerMatrix(numberOfRows: numberOfRows, numberOfColumns: numberOfColumns)
    for i in 0..<numberOfRows
    {
      for j in 0..<numberOfColumns
      {
        matrix[i,j] = self[i+startRow, j+startColumn]
      }
    }
    
    return matrix
  }
  
  // Organize the data into a single array
  public subscript(row: Int, column: Int) -> Int
  {
    get
    {
      return self.elements[row*numberOfColumns + column]
    }
    set(newValue)
    {
      self.elements[row*numberOfColumns + column] = newValue
    }
  }
  
  public subscript(element: Int) -> Int
  {
    get
    {
      return self.elements[element]
    }
    
    set(newValue)
    {
      self.elements[element] = newValue
    }
  }
  
  public func DiagonalInverted() -> IntegerMatrix
  {
    var result: IntegerMatrix = self
    
    result.denominator = self.denominator
    for i in 0..<min(self.numberOfRows,self.numberOfColumns)
    {
      if self[i,i] != 0
      {
        result.denominator *= self[i,i]
      }
    }
    
    
    for i in 0..<min(self.numberOfRows,self.numberOfColumns)
    {
      if ( result[i,i] != 0)
      {
        result[i,i] = result.denominator / self[i,i]
      }
      else
      {
         result[i,i] = 0
      }
    }
    
    return result
  }
  
  public static func * (left: IntegerMatrix, right: IntegerMatrix) -> IntegerMatrix
  {
    assert(left.numberOfColumns == right.numberOfRows)
    var result = IntegerMatrix(numberOfRows: left.numberOfRows, numberOfColumns: right.numberOfColumns)
    result.denominator = left.denominator * right.denominator
    
    for i in 0..<left.numberOfRows
    {
      for j in 0..<right.numberOfColumns
      {
        var v: Int = 0
        for k in 0..<left.numberOfColumns
        {
          v += left[i,k] * right[k,j]
        }
        result[i,j] = v
      }
    }
    return result
  }
  
  public static func * (left: IntegerMatrix, right: [Int]) -> [Int]
  {
    assert(left.numberOfColumns == right.count)
    var result: [Int] = [Int](repeating: 0, count: left.numberOfRows)
   // result.denominator = left.denominator
    
    for i in 0..<left.numberOfRows
    {
      var v: Int = 0
      for k in 0..<left.numberOfColumns
      {
        v += left[i,k] * right[k]
      }
      result[i] = v
    }
    return result
  }
  
  
  public static func ==(left: IntegerMatrix, right: IntegerMatrix) -> Bool
  {
    for i in 0..<left.numberOfRows
    {
      for j in 0..<right.numberOfColumns
      {
         if left[i,j] != right[i,j]
         {
          return false
        }
      }
    }
    return true
  }
  
  public mutating func swapColumns(a: Int, b: Int)
  {
    for i in 0..<self.numberOfRows
    {
      let temp: Int = self[i,a]
      self[i,a] = self[i,b]
      self[i,b] = temp
    }
  }
  
  public func transposed() -> IntegerMatrix
  {
    var result: IntegerMatrix = IntegerMatrix(numberOfRows: self.numberOfColumns, numberOfColumns: self.numberOfRows)
    result.denominator = self.denominator
    for i in 0..<self.numberOfRows
    {
      for j in 0..<self.numberOfColumns
      {
        result[j,i] = self[i,j]
      }
    }
    return result
  }
  
  public mutating func assignSubmatrix(startRow: Int, startColumn: Int, integerMatrix replacement: IntegerMatrix)
  {
    for i in 0..<replacement.numberOfRows
    {
      for j in 0..<replacement.numberOfColumns
      {
        self[startRow + i, startColumn + j] = replacement[i, j]
      }
    }
  }
}
