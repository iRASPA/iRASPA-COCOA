/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import MathKit
import simd

// Let C_old be the change-of-basis matrix that transforms atomic coordinates in the first input setting to coordinates in the reference setting,
// and C_new the matrix that trans- forms coordinates in the second input setting to coordinates in the reference setting.
// The change-of-basis matrix C_{old->new} that trans-forms coordinates in the first setting to coordinates in the second settings is then obtained as the product:
//         C_{old->new} = C_new^{-1}.C_old
//         C_{new->old} = (C_new^{-1}.C_old)^(-1) = C_old^(-1).C_new

public struct SKChangeOfBasis
{
  private var changeOfBasis : MKint3x3
  private var translation: SIMD3<Int32> = SIMD3<Int32>()
  private var inverseChangeOfBasis : MKint3x3
  
  
  public init(rotation: MKint3x3)
  {
    self.changeOfBasis = rotation
    self.translation = SIMD3<Int32>(0,0,0)
    self.inverseChangeOfBasis = self.changeOfBasis.inverse
    
    //self.changeOfBasis.cleaunUp()
    //self.inverseChangeOfBasis.cleaunUp()
  }
  
  public init(rotation: SKRotationMatrix)
  {
    self.changeOfBasis = MKint3x3(rotation)
    self.translation = SIMD3<Int32>(0,0,0)
    self.inverseChangeOfBasis = self.changeOfBasis.inverse
    
    //self.changeOfBasis.cleaunUp()
    //self.inverseChangeOfBasis.cleaunUp()
  }
  
  public init(changeOfBasis: MKint3x3, inverseChangeOfBasis: MKint3x3)
  {
    self.changeOfBasis = changeOfBasis
    self.inverseChangeOfBasis = inverseChangeOfBasis
  }
  
  var inverse: SKChangeOfBasis
  {
    return SKChangeOfBasis(changeOfBasis: inverseChangeOfBasis, inverseChangeOfBasis: changeOfBasis)
  }
  
  public static func * (left: SKChangeOfBasis, right: SKSeitzMatrix) -> SKSeitzMatrix
  {
    let rotation: MKint3x3 = left.inverseChangeOfBasis * MKint3x3(right.rotation) * left.changeOfBasis
    let translation: SIMD3<Int32> = (left.inverseChangeOfBasis * right.translation - (rotation - MKint3x3.identity) * left.translation)
    return SKSeitzMatrix(rotation: rotation.Int3x3, translation: translation / Int32(left.inverseChangeOfBasis.denominator))
  }
  
  public static func * (left: double3x3, right: SKChangeOfBasis) -> double3x3
  {
    return left * right.inverseChangeOfBasis
  }
  
  public static func * (left: SKChangeOfBasis, right: SKRotationMatrix) -> SKRotationMatrix
  {
    return (left.inverseChangeOfBasis * MKint3x3(right) * left.changeOfBasis).Int3x3
  }
  
  public static func * (left: SKChangeOfBasis, right: SIMD3<Double>) -> SIMD3<Double>
  {
    return (left.inverseChangeOfBasis * right) / Double(left.inverseChangeOfBasis.denominator)
  }
  
  public static func * (left: SKChangeOfBasis, right: SIMD3<Int32>) -> SIMD3<Int32>
  {
    return left.inverseChangeOfBasis * right / Int32(left.inverseChangeOfBasis.denominator)
  }
}
