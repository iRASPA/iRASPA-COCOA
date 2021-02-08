/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2021 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 S.Calero@tue.nl         https://www.tue.nl/en/research/researchers/sofia-calero/
 t.j.h.vlugt@tudelft.nl  http://homepage.tudelft.nl/v9k6y
 
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
import simd

public struct int3x9
{
  var columns: [int9]
  
  public init()
  {
    self.columns = [int9(),int9(),int9()]
  }
  
  public init(_ columns: [int9])
  {
    self.columns = columns
  }
  
  public mutating func swapRows(i: Int, j: Int)
  {
    for k in 0..<3
    {
      let temp: Int32 = self.columns[k][i]
      self.columns[k][i] = self.columns[k][j]
      self.columns[k][j] = temp
    }
  }
  
  public mutating func divideRow(i: Int, by divisor: Int32)
  {
    for k in 0..<3
    {
      self.columns[k][i] /= divisor
    }
  }
  
  public mutating func subtract(row: Int, mutlipliedBy multiplier: Int32, fromRow: Int)
  {
    for k in 0..<3
    {
      self.columns[k][fromRow] -= multiplier * self.columns[k][row]
    }
  }
  
  /// Access to individual elements.
  public subscript(column: Int, row: Int) -> Int32
  {
    get
    {
      return self.columns[column][row]
    }
    set(newValue)
    {
      self.columns[column][row] = newValue
    }
  }
  
  public subscript(column: Int) -> int9
  {
    get
    {
      return self.columns[column]
    }
    
    set(newValue)
    {
      self.columns[column] = newValue
    }
  }
  
  public func rowEchelonForm(t: inout int9x9) -> int3x9
  {
    var m: int3x9 = self
    
    var pivot: Int = 0
    for r in 0..<9
    {
      if 3 <= pivot
      {
        break
      }
      var i: Int = r
      while m[pivot][i] == 0
      {
        i = i + 1
        if i == 9
        {
          i = r
          pivot = pivot + 1
          if pivot == 3
          {
            //pivot = pivot - 1
            fatalError()
          }
        }
      }
      
      m.swapRows(i: i, j: r)
      t.swapRows(i: i, j: r)
      
      let div: Int32 = m[pivot][r]
      if div != 0
      {
        // divide row r by M[r, lead]
        m.divideRow(i: r, by: div)
        t.divideRow(i: r, by: div)
      }
      for k in 0..<9
      {
        if k != r
        {
          // Subtract M[i][lead] multiplied by row r from row i
          let sub: Int32 = m[pivot][k]
          
          m.subtract(row: r, mutlipliedBy: sub, fromRow: k)
          t.subtract(row: r, mutlipliedBy: sub, fromRow: k)
        }
      }
      pivot = pivot + 1
    }
    
    
    return m
  }
  
  public var isDiagonal: Bool
  {
    for ic in 0..<3
    {
      for ir in 0..<9
      {
        if (ir != ic && self[ic][ir] != 0) {return false}
      }
    }
    return true
  }
  
  public var transpose: int9x3
  {
    var result = int9x3()
    
    for ic in 0..<3
    {
      for ir in 0..<9
      {
        result[ir][ic] = self[ic][ir]
      }
    }
    return result
  }

  public var SmithNormalForm: (int9x9, int3x9, int3x3)
  {
    var p: int9x9 = int9x9.identity
    var q: int3x3 = int3x3([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,1)])
    
    var m: int3x9 = self
    var mt: int9x3 = self.transpose
    while(true)
    {
      mt = m.transpose
      mt = mt.rowEchelonForm(t: &q)
      if mt.isDiagonal
      {
        break
      }
      m = mt.transpose
      
      m = m.rowEchelonForm(t: &p)
      if m.isDiagonal
      {
        break
      }
      


      
    }
    
    return (p, m, q)
  }
}
