//
//  SKAsymmetricUnit.swift
//  SymmetryKit
//
//  Created by David Dubbeldam on 22/07/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import Foundation
import simd
import MathKit

public struct SKAsymmetricUnit: CustomStringConvertible
{
  let a: (Int, Int)
  let b: (Int, Int)
  let c: (Int, Int)
  
  public init(a: (Int, Int), b: (Int,Int), c: (Int, Int))
  {
    self.a = a
    self.b = b
    self.c = c
  }
  
  public var description: String
  {
    let rangeX: String = Fraction(a.0 / 2, 24).description + (a.0 % 2 == 0 ? "<=" : "<") + "x" + (a.1 % 2 == 0 ? "<=" : "<") + Fraction(a.1 / 2, 24).description
    let rangeY: String = Fraction(b.0 / 2, 24).description + (b.0 % 2 == 0 ? "<=" : "<") + "y" + (b.1 % 2 == 0 ? "<=" : "<") + Fraction(b.1 / 2, 24).description
    let rangeZ: String = Fraction(c.0 / 2, 24).description + (c.0 % 2 == 0 ? "<=" : "<") + "z" + (c.1 % 2 == 0 ? "<=" : "<") + Fraction(c.1 / 2, 24).description
    
    return rangeX + "; " + rangeY + "; " + rangeZ
  }
  
  public func contains(_ point: SIMD3<Double>) -> Bool
  {
    return isInsideRange(point.x, leftBoundary: Double(a.0) / 48.0, equalLeft: a.0 % 2, rightBoundary: Double(a.1) / 48.0, equalRight: a.1 % 2) &&
           isInsideRange(point.y, leftBoundary: Double(b.0) / 48.0, equalLeft: b.0 % 2, rightBoundary: Double(b.1) / 48.0, equalRight: b.1 % 2) &&
           isInsideRange(point.z, leftBoundary: Double(c.0) / 48.0, equalLeft: c.0 % 2, rightBoundary: Double(c.1) / 48.0, equalRight: c.1 % 2)
  }
  
  public func isInsideRange(_ point: Double, leftBoundary: Double, equalLeft: Int, rightBoundary: Double, equalRight: Int) -> Bool
  {
    let centeredPoint: Double = point - rint(point)
    
    if(equalLeft == 0 && equalRight == 0)
    {
      if(leftBoundary <= centeredPoint && centeredPoint <= rightBoundary)
      {
        return true
      }
      if(leftBoundary <= (centeredPoint + 1.0) && (centeredPoint + 1.0) <= rightBoundary)
      {
        return true
      }
    }
    
    if(equalLeft != 0 && equalRight == 0)
    {
      if(leftBoundary < centeredPoint && centeredPoint <= rightBoundary)
      {
        return true
      }
      if(leftBoundary < (centeredPoint + 1.0) && (centeredPoint + 1.0) <= rightBoundary)
      {
        return true
      }
    }
    
    if(equalLeft == 0 && equalRight != 0)
    {
      if(leftBoundary <= centeredPoint && centeredPoint < rightBoundary)
      {
        return true
      }
      if(leftBoundary <= (centeredPoint + 1.0) && (centeredPoint + 1.0) < rightBoundary)
      {
        return true
      }
    }
    
    if(equalLeft != 0 && equalRight != 0)
    {
      if(leftBoundary < centeredPoint && centeredPoint < rightBoundary)
      {
        return true
      }
      if(leftBoundary < (centeredPoint + 1.0) && (centeredPoint + 1.0) < rightBoundary)
      {
        return true
      }
    }
    
    return false
  }
  
  public static func isInsideIUCAsymmetricUnitCell(number: Int, point: SIMD3<Double>, precision eps: Double = 1e-2) -> Bool
  {
    let p: SIMD3<Double> = fract(point)
    
    switch(number)
    {
      // TRICLINIC GROUPS
      // ================
      
    case 1:   // [1] P 1 (P 1)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 2:   // [2] P -1 (-P 1)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
      
      // MONOCLINIC GROUPS
      // =================
      
    case 3: // [3] P 1 2 1 unique b axis (P 2y)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 4: // [4] P 1 21 1 unique b axis (P 2yb)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 5:  // [5] C 1 2 1 unique b axis: cell choice 1 (C 2y)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 6: // [6] P 1 m 1 unique b axis (P -2y)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 7: // [7] P 1 c 1 unique b axis: cell choice 1 (P -2yc)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 8: // [8] C 1 m 1 unique b axis: cell choice 1 (C -2y)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 9: // [9] C 1 c 1 unique b axis: cell choice 1 (C -2yc)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 10: // [10] P 1 2/m 1 unique b axis (-P 2y)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 11: // [11] P 1 21/m 1 unique axis b (-P 2yb)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 12: // [12] C 1 2/m 1 unique b axis: cell choice 1 (-C 2y)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 13: // [13] P 1 2/c 1 unique b axis: cell choice 1 (-P 2yc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 14: // [14] P 1 21/c 1 unique b axis: cell choice 1 (-P 2ybc)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 15: // [15] C 1 2/c 1 unique b axis: cell choice 1 (-C 2yc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
   
      
    // ORTHORHOMBIC GROUPS
    // ===================
      
    case 16: // [16] P 2 2 2 (P 2 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 17: // [17] P 2 2 21 Origin-1,abc (P 2c 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 18: // [18] P 21 21 2 Origin-1,abc (P 2 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 19: // [19] P 21 21 21 (P 2ac 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 20: // [20] C 2 2 21  Origin-1,abc (C 2c 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 21: // [21] C 2 2 2 Origin-1,abc (C 2 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 22: // [22] F 2 2 2 (F 2 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 23: // [23] I 2 2 2 (I 2 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 24: // [24] I 21 21 21 (I 2b 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 25: // [25] P m m 2 (P 2 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 26: // [26] P m c 21 (P 2c -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 27: // [27] P c c 2 (P 2 -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 28: // [28] P m a 2 (P 2 -2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 29: // [29] P c a 21 (P 2c -2ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 30: // [30] P n c 2 (P 2 -2bc)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 31: // [31] P m n 21 (P 2ac -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 32: // [32] P b a 2 (P 2 -2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 33: // [33] P n a 21 (P 2c -2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 34: // [34] P n n 2 (P 2 -2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 35: // [35] C m m 2 (C 2 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 36: // [36] C m c 21 (C 2c -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 37: // [37] C c c 2 (C 2 -2c)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 38: // [38] A m m 2 (A 2 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 39: // [39] A b m 2 (A 2 -2b)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 40: // [40] A m a 2 (A 2 -2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 41: // [41] A b a 2 (A 2 -2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 42: // [42] F m m 2 (F 2 -2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 43: // [43] F d d 2 (F 2 -2d)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 44: // [44] I m m 2 (I 2 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 45: // [45] I b a 2 (I 2 -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 46: // [46] I m a 2 (I 2 -2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 47: // [47] P m m m (-P 2 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 48: // [48] P n n n Origin choice 2 (-P 2ab 2bc)
      return (0.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 49: // [49] P c c m  (-P 2 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 50: // [50] P b a n Origin choice 2 (-P 2ab 2b)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 51: // [51] P m m a (-P 2a 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 52: // [52] P n n a (-P 2a 2bc)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 53: // [53] P m n a (-P 2ac 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 54: // [54] P c c a (-P 2a 2ac)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 55: // [55] P b a m (-P 2 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 56: // [56] P c c n (-P 2ab 2ac)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 57: // [57] P b c m (-P 2c 2b)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 58: // [58] P n n m (-P 2 2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 59: // [59] P m m n Origin choice 2 (-P 2ab 2a)
      return (0.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.x)
    case 60: // [60] P b c n (-P 2n 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 61: // [61] P b c a (-P 2ac 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 62: // [62] P n m a (-P 2ac 2n)      zeolites: MFI
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 63: // [63] C m c m (-C 2c 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 64: // [64] C m c a (-C 2ac 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 65: // [65] C m m m (-C 2 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 66: // [66] C c c m (-C 2 2c)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 67: // [67] C m m a (-C 2a 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 68: // [68] C c c a Origin choice 2 (-C 2a 2ac)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 69: // [69] F m m m (-F 2 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 70: // [70] F d d d:2 Origin choice 2 (-F 2uv 2vw)
      return (0.0...1.0/8.0+eps).contains(p.x) && (-1.0/8.0...1.0/8.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 71: // [71] I m m m (-I 2 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 72: // [72] I b a m (-I 2 2c)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 73: // [73] I b c a (-I 2b 2c)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 74: // [74] I m m a (-I 2b 2)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
   
      
      // TETRAGONAL GROUPS
      // =================
      
    case 75: // [75] P 4 (P 4)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 76: // [76] P 41 (P 4w)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 77: // [77] P 42 (P 4c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 78: // [78] P 43 (P 4cw)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 79: // [79] I 4 (I 4)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 80: // [80] I 41 (I 4bw)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 81: // [81] P -4 (P -4)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 82: // [82] I -4 (I -4)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 83: // [83] P 4/m (-P 4)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 84: // [84] P 42/m (-P 4c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 85: // [85] P 4/n Origin choice 2 (-P 4a)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 86: // [86] P 42/n Origin choice 2 (-P 4bc)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 87: // [87] I 4/m (-I 4)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 88: // [88] I 41/a Origin choice 2 (-I 4ad)
      return (0.0...1.0/4.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z)
    case 89: // [89] P 4 2 2 (P 4 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 90: // [90] P 4 21 2 (P 4ab 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 91: // [91] P 41 2 2 (P 4w 2c)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 92: // [92] P 41 21 2 (P 4abw 2nw)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 93: // [93] P 42 2 2 (P 4c 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 94: // [94] P 42 21 2 (P 4n 2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 95: // [95] P 43 2 2 (P 4cw 2c)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 96: // [96] P 43 21 2 (P 4nw 2abw)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 97: // [97] I 4 2 2 (I 4 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 98: // [98] I 41 2 2 (I 4bw 2bw)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 99: // [99] P 4 m m (P 4 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 100: // [100] P 4 b m (P 4 -2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.y<=1.0/2.0-p.x+eps)
    case 101: // [101] P 42 c m (P 4c -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 102: // [102] P 42 n m (P 4n -2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 103: // [103] P 4 c c (P 4 -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 104: // [104] P 4 n c (P 4 -2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 105: // [105] P 42 m c (P 4c -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 106: // [106] P 42 b c (P 4c -2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 107: // [107] I 4 m m (I 4 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 108: // [108] I 4 c m (I 4 -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=1.0/2.0-p.x+eps)
    case 109: // [109] I 41 m d (I 4bw -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 110: // [110] I 41 c d (I 4bw -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.z)
    case 111: // [111] P -4 2 m (P -4 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 112: // [112] P -4 2 c (P -4 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 113: // [113] P -4 21 m (P -4 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.y<=1.0/2.0-p.x+eps)
    case 114: // [114] P -4 21 c (P -4 2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 115: // [115] P -4 m 2 (P -4 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 116: // [116] P -4 c 2 (P -4 -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 117: // [117] P -4 b 2 (P -4 -2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z)
    case 118: // [118] P -4 n 2 (P -4 -2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 119: // [119] I -4 m 2 (I -4 -2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 120: // [120] I -4 c 2 (I -4 -2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 121: // [121] I -4 2 m (I -4 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x <= p.y+eps)
    case 122: // [122] I -4 2 d (I -4 2bw)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 123: // [123] P 4/m m m (-P 4 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x <= p.y+eps)
    case 124: // [124] P 4/m c c (-P 4 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 125: // [125] P 4/n b m Origin choice 2 (-P 4a 2b)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x <= -p.y+eps)
    case 126: // [126] P 4/n n c Origin choice 2 (-P 4a 2bc)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 127: // [127] P 4/m b m (-P 4 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y <= 1.0/2.0-p.x+eps)
    case 128: // [128] P 4/m n c (-P 4 2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 129: // [129] P 4/n m m Origin choice 2 (-P 4a 2a)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 130: // [130] P 4/n c c Origin choice 2 (-P 4a 2ac)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 131: // [131] P 42/m m c (-P 4c 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 132: // [132] P 42/m c m (-P 4c 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 133: // [133] P 42/n b c Origin choice 2 (-P 4ac 2b)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 134: // [134] P 42/n n m Origin choice 2 (-P 4ac 2bc)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x <= -p.y+eps)
    case 135: // [135] P 42/m b c (-P 4c 2ab)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 136: // [136] P 42/m n m (-P 4n 2n)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x <= p.y+eps)
    case 137: // [137] P 42/n m c Origin choice 2 (-P 4ac 2a)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z)
    case 138: // [138] P 42/n c m Origin choice 2 (-P 4ac 2ac)
      return (-1.0/4.0...1.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 139: // [139] I 4/m m m (-I 4 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.x<=p.y+eps)
    case 140: // [140] I 4/m c m (-I 4 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.y<=1.0/2.0-p.x+eps)
    case 141: // [141] I 41/a m d Origin choice 2 (-I 4bd 2)
      return (0.0...1.0/2.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
    case 142: // [142] I 41/a c d Origin choice 2 (-I 4bd 2c)
      return (0.0...1.0/2.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/8.0+eps).contains(p.z)
      
      
      // TRIGONAL GROUPS
      // ===============
      
    case 143: // [143] P 3 (P 3)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 144: // [144] P 31 (P 31)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/3.0+eps).contains(p.z)
    case 145: // [145] P 32 (P 32)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/3.0+eps).contains(p.z)
    case 146: // [146] R 3 hexagonal axes (R 3)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/3.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 147: // [147] P -3 (P -3)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 148: // [148] R-3 hexagonal axes (-R 3)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 149: // [149] P 3 1 2 (P 3 2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 150: // [150] P 3 2 1 (P 3 2")
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 151: // [151] P 31 1 2 (P 31 2 (0 0 4))
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z)
    case 152: // [152] P 31 2 1 (P 31 2")
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z)
    case 153: // [153] P 32 1 2 (P 32 2 (0 0 2))
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z)
    case 154: // [154] P 32 2 1 (P 32 2")
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z)
    case 155: // [155] R 3 2 Hexagonal axes (R 3 2")
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 156: // [156] P 3 m 1 (P 3 -2")
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=2.0*p.y+eps) && (p.y<=min(1.0-p.x,2.0*p.x)+eps)
    case 157: // [157] P 3 1 m (P 3 -2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=(p.y+1.0)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 158: // [158] P 3 c 1 (P 3 -2"c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 159: // [159] P 3 1 c (P 3 -2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 160: // [160] R 3 m Hexagonal axes (R 3 -2")
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/3.0+eps).contains(p.z) && (p.x<=2.0*p.y+eps) && (p.y<=min(1.0-p.x,2.0*p.x)+eps)
    case 161: // [161] R 3 c Hexagonal axes (R 3 -2"c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 162: // [162] P -3 1 m (-P 3 2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 163: // [163] P -3 1 c (-P 3 2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 164: // [164] P -3 m 1 (-P 3 2")
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/3.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) && (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=p.x/2.0+eps)
    case 165: // [165] P -3 c 1 (-P 3 2"c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 166: // [166] R -3 m Hexagonal axes (-R 3 2")  zeolites: CHA
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z) &&
        (p.x<=2.0*p.y+eps) && (p.y<=min(1.0-p.x,2.0*p.x)+eps)
    case 167: // [167] R -3 c Hexagonal axes (-R 3 2"c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/12.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)

      
      // HEXAGONAL GROUPS
      // ================
      
    case 168: // [168] P 6 (P 6)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 169: // [169] P 61 (P 61)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z)
    case 170: // [170] P 65 (P 65)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z)
    case 171: // [171] P 62 (P 62)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/3.0+eps).contains(p.z) && (p.y<=p.x+eps)
    case 172: // [172] P 64 (P 64)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/3.0+eps).contains(p.z) && (p.y<=p.x+eps)
    case 173: // [173] P 63 (P 6c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 174: // [174] P -6 (P -6)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 175: // [175] P6/m (-P 6)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 176: // [176] P 63/m (-P 6c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0))
    case 177: // [177] P 6 2 2 (P 6 2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 178: // [178] P 61 2 2 (P 61 2 (0 0 5))
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/12.0+eps).contains(p.z)
    case 179: // [179] P 65 2 2 (P 65 2 (0 0 1))
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/12.0+eps).contains(p.z)
    case 180: // [180] P 62 2 2 (P 62 2 (0 0 4))
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z) && (p.y<=p.x+eps)
    case 181: // [181] P 64 2 2 (P 64 2 (0 0 2))
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/6.0+eps).contains(p.z) && (p.y<=p.x+eps)
    case 182: // [182] P 63 2 2 (P 6c 2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 183: // [183] P 6 m m (P 6 -2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/3.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=p.x/2.0+eps)
    case 184: // [184] P 6 c c (P 6 -2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 185: // [185] P 63 c m (P 6c -2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 186: // [186] P 63 m c (P 6c -2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/3.0+eps).contains(p.y) && (0.0...1.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=p.x/2.0+eps)
    case 187: // [187] P -6 m 2 (P -6 2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=2.0*p.y+eps) && (p.y<=min(1.0-p.x,2.0*p.x)+eps)
    case 188: // [188] P -6 c 2 (P -6c 2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 189: // [189] P -6 2 m (P -6 -2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 190: // [190] P -6 2 c (P -6c -2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,(1.0+p.x)/2.0)+eps)
    case 191: // [191] P 6/m m m (-P 6 2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/3.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=p.x/2.0+eps)
    case 192: // [192] P 6/m c c (-P 6 2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 193: // [193] P 63/m c m (-P 6c 2)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=(1.0+p.y)/2.0+eps) && (p.y<=min(1.0-p.x,p.x)+eps)
    case 194: // [194] P 63/m m c (-P 6c 2c)
      return (0.0...2.0/3.0+eps).contains(p.x) && (0.0...2.0/3.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) &&
        (p.x<=2.0*p.y+eps) && (p.y<=min(1.0-p.x,2.0*p.x)+eps)
      
      // CUBIC GROUPS
      // ============
      
    case 195: // [195] P 2 3 (P 2 2 3)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=1.0-p.x+eps) && (p.z<=min(p.x,p.y)+eps)
    case 196: // [196] F 2 3 (F 2 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (-1.0/4.0...1.0/4.0+eps).contains(p.z) && (p.y<=p.x+eps) && (max(p.x-1.0/2.0,-p.y)...min(1.0/2.0-p.x,p.y)+eps).contains(p.z)
    case 197: // [197] I 2 3 (I 2 2 3)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=min(p.x,1.0-p.x)+eps) && (p.z<=p.y+eps)
    case 198: // [198] P 21 3 (P 2ac 2ab 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (-1.0/2.0...1.0/2.0+eps).contains(p.z) && (max(p.x-1.0/2.0,-p.y)...min(p.x,p.y)+eps).contains(p.z)
    case 199: // [199] I 21 3 (I 2b 2c 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.z<=min(p.x,p.y)+eps)
    case 200: // [200] P m -3 (-P 2 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.z<=min(p.x,p.y)+eps)
    case 201: // [201] P n -3 Origin choice 2 (-P 2ab 2bc 3)
      return (-1.0/4.0...3.0/4.0+eps).contains(p.x) && (-1.0/4.0...1.0/4.0+eps).contains(p.y) && (-1.0/4.0...1.0/4.0+eps).contains(p.z) && (p.y<=min(p.x,1.0-p.x)+eps) && (p.z<=p.y+eps)
    case 202: // [202] F m -3 (-F 2 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=min(1.0/2.0-p.x,p.y)+eps)
    case 203: // [203] F d -3 Origin choice 2 (-F 2uv 2vw 3)
      return (-1.0/8.0...3.0/8.0+eps).contains(p.x) && (-1.0/8.0...1.0/8.0+eps).contains(p.y) && (-3.0/8.0...1.0/8.0+eps).contains(p.z) && (p.y<=min(p.x,1.0/4.0-p.x)+eps) && (-p.y-1.0/4.0...p.y+eps).contains(p.z)
    case 204: // [204] I m -3 (-I 2 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=p.y+eps)
    case 205: // [205] P a -3 (-P 2ac 2ab 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.z<=min(p.x,p.y)+eps)
    case 206: // [206] I a -3 (-I 2b 2c 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.z<=min(p.x,1.0/2.0-p.x,1.0/2.0-p.y)+eps)
    case 207: // [207] P 4 3 2 (P 4 2 3)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=min(p.x,1.0-p.x)+eps) && (p.z<=p.y+eps)
    case 208: // [208] P 42 3 2 (P 4n 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (-1.0/4.0...1.0/4.0+eps).contains(p.z) && (max(-p.x,p.x-1.0/2.0,-p.y,p.y-1.0/2.0)...min(p.x,1.0/2.0-p.x,1.0/2.0-p.y)+eps).contains(p.z)
    case 209: // [209] F 4 3 2 (F 4 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (-1.0/4.0...1.0/4.0+eps).contains(p.z) && (p.y<=min(p.x,1.0/2.0-p.x)+eps) && (-p.y...p.y+eps).contains(p.z)
    case 210: // [210] F 41 3 2 (F 4d 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (-1.0/8.0...1.0/8.0+eps).contains(p.x) && (-1.0/8.0...1.0/8.0+eps).contains(p.x) && (p.y<=min(p.x,1.0/2.0-p.x)+eps) && (-p.y...min(p.x,1.0/2.0-p.x)+eps).contains(p.z)
    case 211: // [211] I 4 3 2 (I 4 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.z<=min(p.x,1.0/2.0-p.x,p.y,1.0/2.0-p.y)+eps)
    case 212: // [212] P 43 3 2 (P 4acd 2ab 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...3.0/4.0+eps).contains(p.y) && (-1.0/2.0...1.0/4.0+eps).contains(p.z-rint(p.z)) && (max(-p.y,p.x-1.0/2.0)...min(-p.y+1.0/2.0,2.0*p.x-p.y,2.0*p.y-p.x,p.y-2.0*p.x+1.0/2.0)+eps).contains(p.z-rint(p.z))
    case 213: // [213] P 41 3 2 (P 4bd 2ab 3)
      return (-1.0/4.0...1.0/2.0+eps).contains(p.x) && (0.0...3.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.x...p.x+1.0/2.0+eps).contains(p.y) && ((p.y-p.x)/2.0<=p.z) && (p.z<=min(p.y,(-4.0*p.x-2.0*p.y+3.0)/2.0,(3.0-2.0*p.x-2.0*p.y)/4.0)+eps)
    case 214: // [214] I 41 3 2 (I 4bd 2c 3)
      return (-3.0/8...1.0/8.0+eps).contains(p.x) && (-1.0/8.0...1.0/8.0+eps).contains(p.y) && (-1.0/8.0...3.0/8.0+eps).contains(p.z) && (max(p.x,p.y,p.y-p.x-1.0/8.0)...p.y+1.0/4.0+eps).contains(p.z)
    case 215: // [215] P -4 3 m (P -4 2 3)
      return (0.0...1.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=min(p.x,1.0-p.x)+eps) && (p.z<=p.y+eps)
    case 216: // [216] F -4 3 m (F -4 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (-1.0/4.0...1.0/4.0+eps).contains(p.z) && (p.y<=min(p.x,1.0-p.x)+eps) && (-p.y...p.y+eps).contains(p.z)
    case 217: // [217] I -4 3 m (I -4 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=p.y+eps)
    case 218: // [218] P -4 3 n (P -4n 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.z<=min(p.x,p.y)+eps)
    case 219: // [219] F -4 3 c (F -4a 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (-1.0/4.0...1.0/4.0+eps).contains(p.z) && (p.y<=min(p.x,1.0/2.0-p.x)+eps) && (-p.y...p.y+eps).contains(p.z)
    case 220: // [220] I -4 3 d (I -4bd 2c 3)
      return (1.0/4.0...1.0/2.0+eps).contains(p.x) && (1.0/4.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.z<=min(p.x,p.y)+eps)
    case 221: // [221] P m -3 m (-P 4 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=p.y+eps)
    case 222: // [222] P n -3 n Origin choice 2 (-P 4a 2bc 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=p.y+eps)
    case 223: // [223] P m -3 n (-P 4n 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.z<=min(p.x,1.0/2.0-p.x,1.0/2.0-p.y)+eps)
    case 224: // [224] P n -3 m Origin choice 2 (-P 4bc 2bc 3)
      return (1.0/4.0...3.0/4.0+eps).contains(p.x) && (1.0/4.0...3.0/4.0+eps).contains(p.y) && (0.0...1.0/2.0+eps).contains(p.z) && (p.y<=p.x+eps) && (max(p.x-1.0/2.0,1.0/2.0-p.y)...min(p.y,1.0-p.x)+eps).contains(p.z)
    case 225: // [225] F m -3 m (-F 4 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.y<=min(p.x,1.0/2.0-p.x)+eps) && (p.z<=p.y+eps)
    case 226: // [226] F m -3 c (-F 4a 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/4.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.y<=min(p.x,1.0/2.0-p.x)+eps) && (p.z<=p.y+eps)
    case 227: // [227] F d -3 m Origin choice 2 (-F 4vw 2vw 3)      e.g. FAU, MIL-100, 101
      var q = p
      if q.x>0.5 {q.x-=1.0}
      if q.y>0.5 {q.y-=1.0}
      if q.z>0.5 {q.z-=1.0}
      return (-1.0/8.0...3.0/8.0+eps).contains(q.x) && (-1.0/8.0...0.0+eps).contains(q.y)  && (-1.0/4.0...0.0+eps).contains(q.z)  && (q.y<=min(1.0/4.0-q.x,q.x)+eps) && (-q.y-1.0/4.0...q.y+eps).contains(q.z)
    case 228: // [228] F d -3 c Origin choice 1 (F 4d 2 3 -1ad)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/8.0+eps).contains(p.y) && (-1.0/8.0...1.0/8.0+eps).contains(p.z) && (p.y<=min(1.0/2.0-p.x,p.x)+eps) && (-p.y...p.y+eps).contains(p.z)
    case 229: // [229] I m -3 m (-I 4 2 3)
      return (0.0...1.0/2.0+eps).contains(p.x) && (0.0...1.0/2.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (p.y<=p.x+eps) && (p.z<=min(1.0/2.0-p.x,p.y)+eps)
    case 230: // [230] I a -3 d (-I 4bd 2c 3)
      return (-1.0/8.0...1.0/8.0+eps).contains(p.x) && (-1.0/8.0...1.0/8.0+eps).contains(p.y) && (0.0...1.0/4.0+eps).contains(p.z) && (max(p.x,-p.x,p.y,-p.y)<=p.z+eps)
    default:
      return false
    }
  }

}

