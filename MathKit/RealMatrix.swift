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

public struct RealMatrix
{
  var numberOfColumns: Int
  var numberOfRows: Int
  var elements: [Double]
  
  public init(numberOfRows: Int = 3, numberOfColumns: Int = 3)
  {
    self.numberOfColumns = numberOfColumns
    self.numberOfRows = numberOfRows
    elements = [Double](repeating: 0.0, count: numberOfColumns * numberOfRows)
  }
  
  // Organize the data into a single array
  public subscript(row: Int, column: Int) -> Double
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
  
  public subscript(element: Int) -> Double
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
  
  public static func * (left: IntegerMatrix, right: RealMatrix) -> RealMatrix
  {
    assert(left.numberOfColumns == right.numberOfRows)
    var result = RealMatrix(numberOfRows: left.numberOfRows, numberOfColumns: right.numberOfColumns)
    
    for i in 0..<left.numberOfRows
    {
      for j in 0..<right.numberOfColumns
      {
        var v: Double = 0
        for k in 0..<left.numberOfColumns
        {
          v += Double(left[i,k])/Double(left.denominator) * right[k,j]
        }
        result[i,j] = v
      }
    }
    return result
  }
}
