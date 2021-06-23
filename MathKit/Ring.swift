//
//  Ring.swift
//  MathKit
//
//  Created by David Dubbeldam on 22/06/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import Foundation

struct Ring
{
  public static func greatestCommonDivisor(a arg1: Int, b arg2: Int) -> Int
  {
    var a: Int = arg1
    var b: Int = arg2
    while b != 0
    {
      let stored_a = a
      a = b
      b = stored_a % b
    }
    return abs(a)
  }
  
  public static func extendedGreatestCommonDivisor(a: Int, b: Int) -> (Int, Int, Int)
  {
    var ai: Int = b   // ai stands for: a with index i
    var aim1: Int = a // aim1 stands for: a with index i-1
    var bim1: Int = 0
    var cim1: Int = 0
    
    // We can accelerate the first step
    if ai != 0
    {
      // compute both quotient and remainder
      let q = aim1 / ai
      let r = aim1 % ai
      
      aim1 = ai
      ai = r
      bim1 = 0 // before: bi = 0, bim1 = 1
      var bi: Int = 1
      cim1 = 1 // before: ci = 1, cim1 = 0
      var ci: Int = -q
      // Now continue
      while ai != 0
      {
        // compute both quotient and remainder
        let q = aim1 / ai
        let r = aim1 % ai
       
        aim1 = ai
        ai = r
       
        let stored_bim1: Int = bim1
        bim1 = bi
        bi = stored_bim1 - q * bi
        
        let stored_cim1: Int = cim1
        cim1 = ci
        ci = stored_cim1 - q * ci
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
