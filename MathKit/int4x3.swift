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

public struct int4x3
{
  var numerator: [SIMD3<Int32>]
  var denominator: Int
  
  public init()
  {
    self.numerator = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0)]
    self.denominator = 1
  }
  
  
  
  public var description : String
  {
    return "[\(numerator[0]), \(numerator[1]), \(numerator[2]), \(numerator[3])]"
  }
  
  
  /// Access to individual elements.
  public subscript(column: Int, row: Int) -> Int32
  {
    get
    {
      return self.numerator[column][row]
    }
    set(newValue)
    {
      self.numerator[column][row] = newValue
    }
  }
  
  public subscript(column: Int) -> SIMD3<Int32>
  {
    get
    {
      return self.numerator[column]
    }
    
    set(newValue)
    {
      self.numerator[column] = newValue
    }
  }
  
}
  
  

