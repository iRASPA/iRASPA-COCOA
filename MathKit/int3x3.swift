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

public struct int3x3: Equatable
{
  var numerator: [SIMD3<Int32>]
  var denominator: Int
  
  public init()
  {
    self.numerator = [SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0)]
    self.denominator = 1
  }
  
  
  
  public var description : String
  {
    return "[\(numerator[0]), \(numerator[1]), \(numerator[2])]"
  }
  
  public init(scalar: Int32, denominator: Int = 1)
  {
    self.numerator = [SIMD3<Int32>(scalar,0,0),SIMD3<Int32>(0,scalar,0),SIMD3<Int32>(0,0,scalar)]
    self.denominator = denominator
  }
  
  public init(_ columns: [SIMD3<Int32>], denominator: Int = 1)
  {
    self.numerator = columns
    self.denominator = denominator
  }
  
  public init(_ scalar: Int32, denominator: Int = 1)
  {
    self.init([SIMD3<Int32>(scalar,0,0),SIMD3<Int32>(0,scalar,0),SIMD3<Int32>(0,0,scalar)])
    self.denominator = denominator
  }
  
  public init(rows: [SIMD3<Int32>], denominator: Int = 1)
  {
    self.numerator = [SIMD3<Int32>(rows[0].x,rows[1].x,rows[2].x), SIMD3<Int32>(rows[0].y,rows[1].y,rows[2].y), SIMD3<Int32>(rows[0].z,rows[1].z,rows[2].z)]
    self.denominator = denominator
  }
  
  public static var identity: int3x3
  {
    return int3x3([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,1)])
  }
  
  public var elements: [Int]
  {
    return [Int(numerator[0].x), Int(numerator[0].y), Int(numerator[0].z),
            Int(numerator[1].x), Int(numerator[1].y), Int(numerator[1].z),
            Int(numerator[2].x), Int(numerator[2].y), Int(numerator[2].z)]
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
  
  public mutating func cleaunUp()
  {
    let gcd: Int32 = [self[0,0],self[1,0],self[2,0],
                    self[0,1],self[1,1],self[2,1],
                    self[0,2],self[1,2],self[2,2]].reduce(self[0,0]){Int32.greatestCommonDivisor(a: $0, b: $1)}
   
    self.denominator = self.denominator / Int(gcd)
    self[0,0] /= gcd
    self[1,0] /= gcd
    self[2,0] /= gcd
    self[0,1] /= gcd
    self[1,1] /= gcd
    self[2,1] /= gcd
    self[0,2] /= gcd
    self[1,2] /= gcd
    self[2,2] /= gcd
  }
  
  
  public var isOrthogonal: Bool
  {
    return (dot(numerator[0],numerator[1])==0) && (dot(numerator[0],numerator[2])==0) && (dot(numerator[1],numerator[2])==0)
  }
  
  public var transpose: int3x3
  {
    get
    {
      return int3x3([SIMD3<Int32>(self[0,0],self[1,0],self[2,0]),
                     SIMD3<Int32>(self[0,1],self[1,1],self[2,1]),
                     SIMD3<Int32>(self[0,2],self[1,2],self[2,2])], denominator: self.denominator)
    }
  }
  
  public var isZero: Bool
  {
    return (self[0] == SIMD3<Int32>(0,0,0) &&  self[1] == SIMD3<Int32>(0,0,0) && self[2] == SIMD3<Int32>(0,0,0))
  }
  
  public var trace: Int
  {
    return Int(self[0,0] + self[1,1] + self[2,2])
  }
  
  public var determinant: Int
  {
    let temp1: Int32 = (self[1,1] * self[2,2] - self[1,2] * self[2,1])
    let temp2: Int32 = (self[1,2] * self[2,0] - self[1,0] * self[2,2])
    let temp3: Int32 = (self[1,0] * self[2,1] - self[1,1] * self[2,0])
    return Int((self[0,0] * temp1) + (self[0,1] * temp2) + (self[0,2] * temp3))
  }
  
  public mutating func swapRows(i: Int, j: Int)
  {
    for k in 0..<3
    {
      let temp: Int32 = self[k,i]
      self[k,i] = self[k,j]
      self[k,j] = temp
    }
  }
  
  public mutating func subtract(row: Int, mutlipliedBy multiplier: Int32, fromRow: Int)
  {
    for k in 0..<3
    {
      self[k,fromRow] -= multiplier * self[k,row]
    }
  }
  
  public mutating func divideRow(i: Int, by divisor: Int32)
  {
    for k in 0..<3
    {
      self[k,i] /= divisor
    }
  }
  
  
  public func rowEchelonFormBackSubstitution(t: SIMD3<Double>, freeVars: [Int]) -> SIMD3<Double>
  {
    let rank: Int = 3 - freeVars.count
    var sol: SIMD3<Double> = SIMD3<Double>()
    
    
    for r in rank..<3
    {
      if (t[r] != 0)
      {
        return SIMD3<Double>(-10,-10,-10)
      }
    }
    
    var freeFlags: [Bool] = [false, false, false]
    for c in freeVars
    {
      freeFlags[c] = true
    }
    
    var piv_cols: [Int] = []
    for (c,f) in freeFlags.enumerated()
    {
      if (!f)
      {
        piv_cols.append(c)
      }
    }
    
    for r in stride(from: piv_cols.count - 1, through: 0, by: -1)
    {
      let piv_c: Int = piv_cols[r]
      var s: Double = -Double(t[r])
      //var s: Double = 0.0
      for c: Int in piv_c+1..<3
      {
        s += Double(self[r][c]) * sol[c]
      }
      sol[piv_c] = -Double(s) / Double(self[piv_c][r])
    }
    
    return sol
  }
  
  
  public func rowEchelonFormRosetta(t: inout int3x3, freeVars: inout [Int]) -> int3x3
  {
    var m: int3x3 = self
    var piv_r: Int = 0
    for piv_c in 0..<3
    {
      if piv_r >= 3
      {
        break
      }
      var i: Int = piv_c
      while m[piv_r][i] == 0
      {
        i = i + 1
        if i == 3
        {
          i = piv_c
          piv_r = piv_r + 1
          if piv_r == 3
          {
            piv_r = piv_r - 1
            break
          }
        }
      }
      
      // Swap rows i and piv_c
      for j in 0..<3
      {
        let temp: Int32 = m[j][piv_c]
        m[j][piv_c] = m[j][i]
        m[j][i] = temp

        let tempT: Int32 = t[j][piv_c]
        t[j][piv_c] = t[j][i]
        t[j][i] = tempT
      }
      
      let div: Int32 = m[piv_r][piv_c]
      if div != 0
      {
        // divide row r by M[r, lead]
        for j in 0..<3
        {
          m[j][piv_c] /= div
          t[j][piv_c] /= div
        }
      }
      for i in 0..<3
      {
        if i != piv_c
        {
          // Subtract M[i][lead] multiplied by row r from row i
          let sub: Int32 = m[piv_r][i]
          for k in 0..<3
          {
            m[k][i] -= (sub * m[k][piv_c])
            t[k][i] -= (sub * t[k][piv_c])
          }
        }
      }
      piv_r = piv_r + 1
    }
    
    // determine free variables
    freeVars = []
    for row in 0..<3
    {
      var allzero: Bool = true
      for j in 0..<3
      {
        if m[j][row] != 0
        {
          allzero = false
          break
        }
      }
      if allzero
      {
        freeVars.append(row)
      }
    }

    
    return m
  }
  
  public func rowEchelonFormBackSubstitutionRosetta(t: SIMD3<Double>, freeVars: [Int]) -> SIMD3<Double>
  {
    let rank: Int = 3 - freeVars.count
    //assert(rank == 2)
    var sol: SIMD3<Double> = SIMD3<Double>(0.0,0.0,0.0)
    
    
    for r in rank..<3
    {
      if (abs(t[r]) <  Double.ulpOfOne)
      {
        return t
      }
    }
 
    
    var freeFlags: [Bool] = [false, false, false]
    for c in freeVars
    {
      freeFlags[c] = true
    }
    
    var piv_cols: [Int] = []
    for (c,f) in freeFlags.enumerated()
    {
      if (!f)
      {
        piv_cols.append(c)
      }
    }
    
    
    for r in (0..<piv_cols.count).reversed()
    {
      let piv_c: Int = piv_cols[r]

      var s: Double = -Double(t[r])
      
      for c: Int in piv_c+1..<3
      {
        s += Double(self[c][r]) * sol[c]
      }

      sol[piv_c] = -Double(s) / Double(self[piv_c][r])
    }
    return sol
  }

  public func rowEchelonFormBackSubstitutionRosetta(freeVars: [Int]) -> SIMD3<Double>
  {
    let rank: Int = 3 - freeVars.count
    //assert(rank == 2)
    var sol: SIMD3<Double> = SIMD3<Double>(0.0,0.0,0.0)
    
    
    switch(rank)
    {
      
    case 2:
      let z: Double = 1.0
      let y: Double = z * Double(self[2][1]) / Double(self[1][1])
      let x: Double = (y + Double(self[2][0])) / Double(self[0][0])
      return SIMD3<Double>(x,y,z)
      
    default:
      break
    }
    
    if (rank == 1)
    {
      sol[2] = 0.0
      sol[1] = 1.0
    }
    
    for r in rank..<3
    {
      sol[r] = 1.0
    }
    
    
    
    var freeFlags: [Bool] = [false, false, false]
    for c in freeVars
    {
      freeFlags[c] = true
    }
    
    var piv_cols: [Int] = []
    for (c,f) in freeFlags.enumerated()
    {
      if (!f)
      {
        piv_cols.append(c)
      }
    }
    
    
    for r in (0..<piv_cols.count).reversed()
    {
      let piv_c: Int = piv_cols[r]
      var s: Double = 0.0
      
      for c: Int in piv_c+1..<3
      {
        s += Double(self[c][r]) * sol[c]
      }
      
      sol[piv_c] = -Double(s) / Double(self[piv_c][r])
    }
    return sol
  }

  
  public func rowEchelonForm(t: inout int3x3, freeVars: inout [Int]) -> int3x3
  {
    var m: int3x3 = self
    var i: Int = 0
    var j: Int = 0
    while (i < 3 && j < 3)
    {
      var k: Int  = i;
      while (k < 3 && m[j][k] == 0) {k = k + 1}
      if (k == 3)
      {
        j = j + 1
      }
      else
      {
        if (i != k)
        {
          for l in 0..<3
          {
            let swap: Int32 = m[l][i]
            m[l][i] = m[l][k]
            m[l][k] = swap
          }
          
          for l in 0..<3
          {
            let swap: Int32 = t[l][i]
            t[l][i] = t[l][k]
            t[l][k] = swap
          }
        }
        for kn in (k+1)..<3
        {
          k = kn
          let a: Int = abs(Int(m[j][k]))
          if (a != 0 && a < abs(Int(m[j][i])))
          {
            for l in 0..<3
            {
              let swap: Int32 = m[l][i]
              m[l][i] = m[l][k]
              m[l][k] = swap
            }
            
            for l in 0..<3
            {
              let swap: Int32 = t[l][i]
              t[l][i] = t[l][k]
              t[l][k] = swap
            }
          }
        }
        
        if (m[j][i] < 0)
        {
          for ic in 0..<3 {m[ic][i] *= -1}
          for ic in 0..<3 {t[ic][i] *= -1}
        }
        var cleared: Bool = true
        for k in i+1..<3
        {
          let a: Int32 = m[j][k] / m[j][i]
          if (a != 0)
          {
            for ic in 0..<3 {m[ic][k] -= a * m[ic][i]}
            for ic in 0..<3 {t[ic][k] -= a * t[ic][i]}
          }
          if (m[j][k] != 0) {cleared = false}
        }
        if (cleared)
        {
          i = i + 1
          j = j + 1
        }
      }
    }
    
    freeVars = []
    for piv_c in 0..<3
    {
      var allzero: Bool = true
      for j in 0..<3
      {
        if m[piv_c][j] != 0
        {
          allzero = false
          break
        }
      }
      if allzero
      {
        freeVars.append(piv_c)
      }
      
    }

   
    return m
  }
  
  func gcd_int(a1: Int, b1: Int) -> Int
  {
    var a: Int = a1
    var b: Int = b1
    do
    {
      if (b == 0) {return a < 0 ? -a : a}
      let next_b: Int = a % b
      a = b
      b = next_b
    }
    return 0
  }
  
  
  public var inverse: int3x3
  {
    var result: int3x3 = int3x3()
    result.denominator = self.determinant / self.denominator
  
    result[0,0] = self[1,1] * self[2,2] - self[2,1] * self[1,2]
    result[0,1] = self[0,2] * self[2,1] - self[0,1] * self[2,2]
    result[0,2] = self[0,1] * self[1,2] - self[0,2] * self[1,1]
    result[1,0] = self[1,2] * self[2,0] - self[1,0] * self[2,2]
    result[1,1] = self[0,0] * self[2,2] - self[0,2] * self[2,0]
    result[1,2] = self[1,0] * self[0,2] - self[0,0] * self[1,2]
    result[2,0] = self[1,0] * self[2,1] - self[2,0] * self[1,1]
    result[2,1] = self[2,0] * self[0,1] - self[0,0] * self[2,1]
    result[2,2] = self[0,0] * self[1,1] - self[1,0] * self[0,1]
    
    return result
  }

 
  
  public static func ==(left: int3x3, right: int3x3) -> Bool
  {
    return (left[0,0] == right[0,0]) && (left[0,1] == right[0,1]) && (left[0,2] == right[0,2]) &&
           (left[1,0] == right[1,0]) && (left[1,1] == right[1,1]) && (left[1,2] == right[1,2]) &&
           (left[2,0] == right[2,0]) && (left[2,1] == right[2,1]) && (left[2,2] == right[2,2])
  }
  
  public static func * (left: int3x3, right: int3x3) -> int3x3
  {
    return int3x3([ SIMD3<Int32>(left[0,0] * right[0,0] + left[1,0] * right[0,1] + left[2,0] * right[0,2],
                        left[0,1] * right[0,0] + left[1,1] * right[0,1] + left[2,1] * right[0,2],
                        left[0,2] * right[0,0] + left[1,2] * right[0,1] + left[2,2] * right[0,2]),
                    SIMD3<Int32>(left[0,0] * right[1,0] + left[1,0] * right[1,1] + left[2,0] * right[1,2],
                        left[0,1] * right[1,0] + left[1,1] * right[1,1] + left[2,1] * right[1,2],
                        left[0,2] * right[1,0] + left[1,2] * right[1,1] + left[2,2] * right[1,2]),
                    SIMD3<Int32>(left[0,0] * right[2,0] + left[1,0] * right[2,1] + left[2,0] * right[2,2],
                        left[0,1] * right[2,0] + left[1,1] * right[2,1] + left[2,1] * right[2,2],
                        left[0,2] * right[2,0] + left[1,2] * right[2,1] + left[2,2] * right[2,2])], denominator: left.denominator * right.denominator)
  }
  
  public static func *= (left: inout int3x3, right: int3x3)
  {
    left = left * right
  }
  
  public static func * (left: int3x3, right: double3x3) -> double3x3
  {
    let temp1: SIMD3<Double> = SIMD3<Double>(Double(left[0,0]) * right[0,0] + Double(left[1,0]) * right[0,1] + Double(left[2,0]) * right[0,2],
                                 Double(left[0,1]) * right[0,0] + Double(left[1,1]) * right[0,1] + Double(left[2,1]) * right[0,2],
                                 Double(left[0,2]) * right[0,0] + Double(left[1,2]) * right[0,1] + Double(left[2,2]) * right[0,2])
    let temp2: SIMD3<Double> = SIMD3<Double>(Double(left[0,0]) * right[1,0] + Double(left[1,0]) * right[1,1] + Double(left[2,0]) * right[1,2],
                                 Double(left[0,1]) * right[1,0] + Double(left[1,1]) * right[1,1] + Double(left[2,1]) * right[1,2],
                                 Double(left[0,2]) * right[1,0] + Double(left[1,2]) * right[1,1] + Double(left[2,2]) * right[1,2])
    let temp3: SIMD3<Double> = SIMD3<Double>(Double(left[0,0]) * right[2,0] + Double(left[1,0]) * right[2,1] + Double(left[2,0]) * right[2,2],
                                 Double(left[0,1]) * right[2,0] + Double(left[1,1]) * right[2,1] + Double(left[2,1]) * right[2,2],
                                 Double(left[0,2]) * right[2,0] + Double(left[1,2]) * right[2,1] + Double(left[2,2]) * right[2,2])
    return double3x3([temp1, temp2, temp3])
  }
  
  public static func * (left: int3x3, right: SIMD3<Int32>) -> SIMD3<Int32>
  {
    return SIMD3<Int32>(x: left[0,0] * right.x + left[1,0] * right.y + left[2,0] * right.z,
                y: left[0,1] * right.x + left[1,1] * right.y + left[2,1] * right.z,
                z: left[0,2] * right.x + left[1,2] * right.y + left[2,2] * right.z)
  }
  

  
  public static func * (left: int3x3, right: SIMD3<Double>) -> SIMD3<Double>
  {
    return SIMD3<Double>(x: Double(left[0,0]) * right.x + Double(left[1,0]) * right.y + Double(left[2,0]) * right.z,
                   y: Double(left[0,1]) * right.x + Double(left[1,1]) * right.y + Double(left[2,1]) * right.z,
                   z: Double(left[0,2]) * right.x + Double(left[1,2]) * right.y + Double(left[2,2]) * right.z)
  }
  
  
  static public func + (left: int3x3, right: int3x3) -> int3x3
  {
    return int3x3([SIMD3<Int32>(x: left[0,0] + right[0,0], y: left[0,1] + right[0,1], z: left[0,2] + right[0,2]),
                   SIMD3<Int32>(x: left[1,0] + right[1,0], y: left[1,1] + right[1,1], z: left[1,2] + right[1,2]),
                   SIMD3<Int32>(x: left[2,0] + right[2,0], y: left[2,1] + right[2,1], z: left[2,2] + right[2,2])])
  }
  
  static public func - (left: int3x3, right: int3x3) -> int3x3
  {
    return int3x3([SIMD3<Int32>(x: left[0,0] - right[0,0], y: left[0,1] - right[0,1], z: left[0,2] - right[0,2]),
                   SIMD3<Int32>(x: left[1,0] - right[1,0], y: left[1,1] - right[1,1], z: left[1,2] - right[1,2]),
                   SIMD3<Int32>(x: left[2,0] - right[2,0], y: left[2,1] - right[2,1], z: left[2,2] - right[2,2])])
  }
  
  public static prefix func - (left: int3x3) -> int3x3
  {
    return int3x3([SIMD3<Int32>(-left[0,0], -left[0,1], -left[0,2]),
                   SIMD3<Int32>(-left[1,0], -left[1,1], -left[1,2]),
                   SIMD3<Int32>(-left[2,0], -left[2,1], -left[2,2])])
    
  }
  
  public static func / (left: int3x3, right: Int) -> int3x3
  {
    return int3x3([SIMD3<Int32>(left[0,0] / Int32(right), left[0,1] / Int32(right), left[0,2] / Int32(right)),
                   SIMD3<Int32>(left[1,0] / Int32(right), left[1,1] / Int32(right), left[1,2] / Int32(right)),
                   SIMD3<Int32>(left[2,0] / Int32(right), left[2,1] / Int32(right), left[2,2] / Int32(right))])
    
  }
}



