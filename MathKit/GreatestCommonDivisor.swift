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


extension Int
{
  public static func floorDivision(a: Int, b: Int) throws -> Int
  {
    guard (b != 0) else {throw NumericalError.divisionByZero}
   
    return Int(floor(Double(a) / Double(b)))
  }
  
  public static func modulo(a: Int, b: Int) throws -> Int
  {
    guard (b != 0) else {throw NumericalError.divisionByZero}
    
    return a - b * Int(floor(Double(a) / Double(b)))
  }
  
  public static func divisionModulo(a: Int, b: Int) throws -> (Int, Int)
  {
    //guard (b != 0) else {throw NumericalError.divisionByZero}
    if (b==0)
    {
      return (0,0)
    }
    let temp: Int = Int(floor(Double(a) / Double(b)))
    return (temp, a - b * temp)
  }
  
  
  
  public var sign: Int
  {
    if self < 0
    {
      return -1
    }
    else if self > 0
    {
      return 1
    }
    else
    {
      return 0
    }
  }
  
  public static func greatestCommonDivisor(a arg1: Int, b arg2: Int) throws -> Int
  {
    var a: Int = arg1
    var b: Int = arg2
    while b != 0
    {
      let tempa: Int = b
      let tempb: Int = try Int.modulo(a: a, b: b)
      a = tempa
      b = tempb
    }
    return abs(a)
  }
  
  public static func extendedGreatestCommonDivisor(a arg1: Int, b arg2: Int) throws -> (Int, Int, Int)
  {
    var ai: Int = arg2   // ai stands for: a with index i
    var aim1: Int = arg1 // aim1 stands for: a with index i-1
    var bim1: Int
    var cim1: Int
    
    // We can accelerate the first step
    if ai != 0
    {
      // compute both quotient and remainder
      let divmod: (q: Int, r: Int) = try Int.divisionModulo(a: aim1, b: ai)
      
      let tempaim1: Int = ai
      let tempaim2: Int = divmod.r
      aim1 = tempaim1
      ai = tempaim2
      bim1 = 0 // before: bi = 0, bim1 = 1
      var bi: Int = 1
      cim1 = 1 // before: ci = 1, cim1 = 0
      var ci: Int = -divmod.q
      // Now continue
      while ai != 0
      {
        // compute both quotient and remainder
        let divmod: (q: Int, r: Int) = try Int.divisionModulo(a: aim1, b: ai)
        let tempaim1: Int = ai
        let tempaim2: Int = divmod.r
        aim1 = tempaim1
        ai = tempaim2
        let tempbim1: Int = bi
        let tempbim2: Int = bim1 - divmod.q * bi
        bim1 = tempbim1
        bi = tempbim2
        
        let tempcim1: Int = ci
        let tempcim2: Int = cim1 - divmod.q * ci
        cim1 = tempcim1
        ci = tempcim2
      }
    }
    else
    {
      bim1 = 1
      cim1 = 0
    }
    if aim1 < 0
    {
      // Make sure that the GCD is non-negative
      aim1 = -aim1
      bim1 = -bim1
      cim1 = -cim1
    }
    
    return (aim1, bim1, cim1)
  }
}
