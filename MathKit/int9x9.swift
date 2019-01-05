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

public struct int9x9
{
  var columns: [int9]
  
  public init()
  {
    self.columns = [int9(),int9(),int9(),int9(),int9(),int9(),int9(),int9(),int9()]
  }
  
  public init(_ columns: [int9])
  {
    self.columns = columns
  }
  
  public static let identity: int9x9 = int9x9([int9([1,0,0,0,0,0,0,0,0]),int9([0,1,0,0,0,0,0,0,0]),int9([0,0,1,0,0,0,0,0,0]),
                                               int9([0,0,0,1,0,0,0,0,0]),int9([0,0,0,0,1,0,0,0,0]),int9([0,0,0,0,0,1,0,0,0]),
                                               int9([0,0,0,0,0,0,1,0,0]),int9([0,0,0,0,0,0,0,1,0]),int9([0,0,0,0,0,0,0,0,1])])
    
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
}
