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
import simd

public struct int9x3
{
  var columns: [SIMD3<Int32>]
  
  public init()
  {
    self.columns = [SIMD3<Int32>(),SIMD3<Int32>(),SIMD3<Int32>(),SIMD3<Int32>(),SIMD3<Int32>(),SIMD3<Int32>(),SIMD3<Int32>(),SIMD3<Int32>(),SIMD3<Int32>()]
  }
  
  public init(_ columns: [SIMD3<Int32>])
  {
    self.columns = columns
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
  
  public subscript(column: Int) -> SIMD3<Int32>
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
  
  public var isDiagonal: Bool
  {
    for ir in 0..<3
    {
      for ic in 0..<9
      {
        if (ir != ic && self[ic,ir] != 0) {return false}
      }
    }
    return true
  }
  
  public var transpose: int3x9
  {
    var result = int3x9()
    
    for ir in 0..<3
    {
      for ic in 0..<9
      {
        result[ir,ic] = self[ic,ir]
      }
    }
    return result
  }
  
  public mutating func swapRows(i: Int, j: Int)
  {
    for k in 0..<9
    {
      let temp: Int32 = self[k,i]
      self[k,i] = self[k,j]
      self[k,j] = temp
    }
  }
  
  public mutating func divideRow(i: Int, by divisor: Int32)
  {
    for k in 0..<9
    {
      self[k,i] /= divisor
    }
  }
  
  public mutating func subtract(row: Int, mutlipliedBy multiplier: Int32, fromRow: Int)
  {
    for k in 0..<9
    {
      self[k,fromRow] -= multiplier * self[k,row]
    }
  }
  
  public func rowEchelonForm(t: inout int3x3) -> int9x3
  {
    var m: int9x3 = self
    var i: Int = 0
    
    var pivot: Int = 0
    for r in 0..<3
    {
      if 9 <= pivot
      {
        break
      }
      i = r
      while m[pivot][i] == 0
      {
        i = i + 1
        if i == 3
        {
          i = r
          pivot = pivot + 1
          if pivot == 9
          {
            //piv_r = piv_r - 1
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
      for k in 0..<3
      {
        if k != r
        {
          // Subtract M[i][lead] multiplied by row r from row i
          let sub: Int32 = m[pivot,k]
          
          m.subtract(row: r, mutlipliedBy: sub, fromRow: k)
          t.subtract(row: r, mutlipliedBy: sub, fromRow: k)
        }
      }
      pivot = pivot + 1
    }
    
    
    return m
  }


}
