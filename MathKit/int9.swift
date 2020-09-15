/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

public struct int9
{
  var elements: [Int32]
  
  
  public init()
  {
    self.elements = [0,0,0,0,0,0,0,0,0]
  }
  
  public init(_ elements: [Int32])
  {
    self.elements = elements
  }
  
  public subscript(column: Int) -> Int32
    {
    get
    {
      return self.elements[column]
    }
    
    set(newValue)
    {
      self.elements[column] = newValue
    }
  }
}

public struct int11
{
  public var elements: UnsafeMutablePointer<Int32>
  public init()
  {
    self.elements = UnsafeMutablePointer<Int32>.allocate(capacity: 11)
    self.elements.initialize(repeating: 0, count: 11)
  }
  
  public subscript(column: Int) -> Int32
  {
    get
    {
      assert(column >= 0 && column < 11, "Index out of range")
      return (self.elements + column).pointee
    }
    
    set(newValue)
    {
      assert(column >= 0 && column < 11, "Index out of range")
      (self.elements + column).pointee = newValue
    }
  }
}
