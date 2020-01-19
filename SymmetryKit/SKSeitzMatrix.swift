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
import simd
import MathKit

// Classification of symmetry operators
//
//         det(W)=+1          |       det(W)=-1
// tr(W)   3   2   1   0  -1  |  -3   -2   -1    0    1
// type    1   6   4   3   2  |  -1   -6   -4   -3   -2=m
// order   1   6   4   3   2  |   2    6    4    6    2
//
// case  1    ->  if w==0 then identity, otherwise translation. The coefficients of w are the coefficients of the translation vector.
//
// case -1    ->  inversion, coordinates of the inversion center F:  x_F=(1/2)w
//
// All other symmetry operations have a preferred axis (the rotation or rotoinversion axis). The direction u of this axis may be determined from the equation
// W.u == +/- u                                                               (eq 1)
// The + sign is for rotations, the - sign for rotoinversions.
// For type -2=m, reflections or glide reflections, u is the direction of the normal of the (glide) reflection plane.
//
// If W is the matrix of a rotation of order k or of a reflection (k=2), then W^k=I, and one determines the intrinsic translation part, 
// also called screw part or glide part t/k by
//           (W,w)^k=(W^k, W^(k-1).w + W^(k-2).w + ... + W.w + w = (I,t)       (eq 2)
//           to t/k = (1/k)(W^(k-1) + W^(k-2) + ... + W + I).w                 (eq 3)
// The vector with the column of coefficients  $\mbox{\textit{\textbf{t}}}/k$ is called the screw or glide vector. This vector is invariant under the 
// symmetry operation:  W. t/k == t/k. Indeed, multiplication with W permutes only the terms on the right side of equation 3. Thus, the screw vector 
// of a screw rotation is parallel to the screw axis. The glide vector of a glide reflection is left invariant for the same reason. Therefore, 
// it is parallel to the glide plane.
//
// If t == 0 holds, then (W,w) describes a rotation or reflection. For t!=0, (W,w) describes a screw rotation or glide reflection.
// For screw rotations and glide reflections there are no fixed points.


public struct SKSeitzMatrix: Equatable, Hashable
{
  var rotation: SKRotationMatrix
  var translation: SIMD3<Int32>  // denominator = 12
  
  static let rotationStringX: [Int: String] = [-1:"-x", 0:"", 1: "x"]
  static let rotationStringY: [Int: String] = [-1:"-y", 0:"", 1: "y"]
  static let rotationStringZ: [Int: String] = [-1:"-z", 0:"", 1: "z"]
  static let translationString: [Int: String] = [0:"", 1:"+1/12", 2:"+1/6", 3:"+1/4", 4:"+1/3", 5:"+5/12", 6:"+1/2",
                                          7:"+7/12", 8:"+2/3", 9:"+1/3", 10:"+5/6", 11:"+11/12", 12:""]
  
  public enum SymmetryType: Int
  {
    case unknown = 0
    case identity = 1             // identity with translation = 0
    case translation = 2          // identity with translation != 0
    case inversion = 3            // inversion, translation are the coordinates of the inversion center F
    case pure_rotation = 4        // (W,w)^k == (I,t): t=0      Y(W) = Y(-W)
    case pure_reflection = 5      // (W,w)^k == (I,t): t=0      Y(-W) = -W + I,   where Y(W) = W^(k-1).w + W^(k-2).w + ... + W.w + w
    case screw_rotation = 6       // (W,w)^k == (I,t): t!=0     t/k = 1/k W w, where W^k = I
    case glide_reflection = 7     // (W,w)^k == (I,t): t!=0     t/k = 1/2(W+I)
  }
  
  public init()
  {
    rotation = SKRotationMatrix()
    translation = SIMD3<Int32>()
  }
  
  public init(rotation: SKRotationMatrix, translation: SIMD3<Int32>)
  {
    self.rotation = rotation
    self.rotation.cleaunUp()
    self.translation = translation.modulo(12)

  }
  
  public init(rotation: SKRotationMatrix, translation: SIMD3<Double>)
  {
    self.rotation = rotation
    self.rotation.cleaunUp()
    self.translation = SIMD3<Int32>(((Int32(rint(translation.x * 12.0)) % 12 + 12) % 12),
                            ((Int32(rint(translation.y * 12.0)) % 12 + 12) % 12),
                            ((Int32(rint(translation.z * 12.0)) % 12 + 12) % 12))
  }
  
  public init(encoding: (UInt8, UInt8, UInt8))
  {
    let referenceValue: UInt8 = UTF8Char(ascii: "0")
    
    let x: UInt8 = encoding.0 - referenceValue
    let y: UInt8 = encoding.1 - referenceValue
    let z: UInt8 = encoding.2 - referenceValue
    
    assert(Int(x)>=0)
    assert(Int(y)>=0)
    assert(Int(z)>=0)
    assert(Int(x)<SKSeitzMatrix.SeitzData.count)
    assert(Int(y)<SKSeitzMatrix.SeitzData.count)
    assert(Int(z)<SKSeitzMatrix.SeitzData.count)
    
    let r1: SIMD3<Int32> = SIMD3<Int32>(x: Int32(SKSeitzMatrix.SeitzData[Int(x)].r1), y: Int32(SKSeitzMatrix.SeitzData[Int(y)].r1), z: Int32(SKSeitzMatrix.SeitzData[Int(z)].r1))
    let r2: SIMD3<Int32> = SIMD3<Int32>(x: Int32(SKSeitzMatrix.SeitzData[Int(x)].r2), y: Int32(SKSeitzMatrix.SeitzData[Int(y)].r2), z: Int32(SKSeitzMatrix.SeitzData[Int(z)].r2))
    let r3: SIMD3<Int32> = SIMD3<Int32>(x: Int32(SKSeitzMatrix.SeitzData[Int(x)].r3), y: Int32(SKSeitzMatrix.SeitzData[Int(y)].r3), z: Int32(SKSeitzMatrix.SeitzData[Int(z)].r3))
    self.rotation = SKRotationMatrix([r1,r2,r3])
    
    self.translation = SIMD3<Int32>(x: Int32(SKSeitzMatrix.SeitzData[Int(x)].t), y: Int32(SKSeitzMatrix.SeitzData[Int(y)].t), z: Int32(SKSeitzMatrix.SeitzData[Int(z)].t))
  }
  
  public init(random: Int = 0)
  {
    self.rotation = SKRotationMatrix(random: random)
    //self.translation = int3(Int32(arc4random_uniform(13)), Int32(arc4random_uniform(13)), Int32(arc4random_uniform(13)))
    self.translation = SIMD3<Int32>(0,0,0)
  }
  
  

  public var intrinsicPart: SIMD3<Int32>
  {
    let order: Int = self.rotation.order()
    return self.rotation.accumulate() * self.translation / Int32(order)
  }
  
  public var t: SIMD3<Int32>
  {
    return self.rotation.accumulate() * self.translation 
  }

  
  public var locationPart: SIMD3<Int32>
  {
    return self.intrinsicPart - self.translation
  }
  
  public var fixedPoint: SIMD3<Double>
  {
    var free: [Int] = [0,0,0]
    var t: int3x3 = int3x3([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,1)])
    let m: int3x3 = self.rotation - int3x3([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,1)])
    let rowEchelonMatrix: int3x3 = m.rowEchelonFormRosetta(t: &t, freeVars: &free)
    
    let locationPart: SIMD3<Int32> = self.locationPart
    let s: SIMD3<Double> = t * SIMD3<Double>(Double(locationPart.x)/12.0,Double(locationPart.y)/12.0, Double(locationPart.z)/12.0)
    let sol: SIMD3<Double> = rowEchelonMatrix.rowEchelonFormBackSubstitutionRosetta(t: s, freeVars: free)
    return sol
  }
  
  public var symmetryType: SymmetryType
  {
    if self.rotation.isIdentity
    {
      // identity with translation = 0
      if self.translation == SIMD3<Int32>(0,0,0)
      {
        return .identity
      }
      else
      {
        // identity with translation != 0
        return .translation
      }
    }
    
    if self.rotation.isInversion
    {
      // inversion, translation are the coordinates of the inversion center F
      return .inversion
    }
    
    let t: SIMD3<Int32> = self.t
    let order: Int = self.rotation.order()
    let YW: SKRotationMatrix = self.rotation.accumulate()
    let YWMinus: SKRotationMatrix = (-self.rotation).accumulate()
    
    if (t.isZero)
    {
      if YWMinus == SKRotationMatrix.identity - self.rotation
      {
        // (W,w)^k == (I,t): t=0      Y(-W) = -W + I,   where Y(W) = W^(k-1).w + W^(k-2).w + ... + W.w + w
        return .pure_reflection
      }
      if (YW == YWMinus)
      {
        // (W,w)^k == (I,t): t=0      Y(W) = Y(-W)
        return .pure_rotation
      }
      
    }
    else
    {
      if (2 * (t / Int32(order)) == (self.rotation + SKRotationMatrix.identity) * translation)
      {
        // (W,w)^k == (I,t): t!=0     t/k = 1/2(W+I)w
        return .glide_reflection
      }

      if t == (YW * translation)
      {
        // (W,w)^k == (I,t): t!=0     t/k = 1/k Y w, where W^k = I
        return .screw_rotation
      }
    }
    
    return .unknown
  }

  public func hash(into hasher: inout Hasher)
  {
    hasher.combine(self.rotation[0,0])
    hasher.combine(self.rotation[0,1])
    hasher.combine(self.rotation[0,2])
    hasher.combine(self.rotation[1,0])
    hasher.combine(self.rotation[1,1])
    hasher.combine(self.rotation[1,2])
    hasher.combine(self.rotation[2,0])
    hasher.combine(self.rotation[2,1])
    hasher.combine(self.rotation[2,2])
    
    let normalizedTranslation: SIMD3<Int32> = self.translation.modulo(12)
    hasher.combine(normalizedTranslation.x)
    hasher.combine(normalizedTranslation.y)
    hasher.combine(normalizedTranslation.z)
  }
  
  public static func ==(lhs: SKSeitzMatrix, rhs: SKSeitzMatrix) -> Bool
  {
    return (lhs.rotation[0][0] == rhs.rotation[0][0]) &&
           (lhs.rotation[0][1] == rhs.rotation[0][1]) &&
           (lhs.rotation[0][2] == rhs.rotation[0][2]) &&
           (lhs.rotation[1][0] == rhs.rotation[1][0]) &&
           (lhs.rotation[1][1] == rhs.rotation[1][1]) &&
           (lhs.rotation[1][2] == rhs.rotation[1][2]) &&
           (lhs.rotation[2][0] == rhs.rotation[2][0]) &&
           (lhs.rotation[2][1] == rhs.rotation[2][1]) &&
           (lhs.rotation[2][2] == rhs.rotation[2][2]) &&
           ((lhs.translation.modulo(12)) == (rhs.translation.modulo(12)))
  }
  
  
  /// Inverse of the matrix if it exists, otherwise the contents of the resulting matrix are undefined.
  public var inverse: SKSeitzMatrix
  {
    let inverseRotation: SKRotationMatrix = self.rotation.inverse
    let inverseTranslation: SIMD3<Int32> = 0 &- (inverseRotation * translation)
    return SKSeitzMatrix(rotation: inverseRotation, translation: inverseTranslation)
  }


  
  public static func SeitzMatrices(generatorEncoding encoding: [UInt8]) -> [SKSeitzMatrix]
  {
    let m: Int = encoding.count/3
    
    var matrices: [SKSeitzMatrix] = [SKSeitzMatrix](repeating: SKSeitzMatrix(rotation: SKRotationMatrix.identity, translation: SIMD3<Int32>(0,0,0)), count: 3)
    
    for i in 0..<m
    {
      let x: UInt8 = encoding[3 * i]
      let y: UInt8 = encoding[3 * i + 1]
      let z: UInt8 = encoding[3 * i + 2]
      
      matrices[i] = SKSeitzMatrix(encoding: (x,y,z))
    }
    
    return matrices
  }
  
  public static func SeitzMatrices(fullEncoding encoding: [UInt8]) -> [SKSeitzMatrix]
  {
    let m: Int = encoding.count/3
    
    var matrices: [SKSeitzMatrix] = [SKSeitzMatrix](repeating: SKSeitzMatrix(), count: m)
    
    for i in 0..<m
    {
      let x: UInt8 = encoding[3 * i]
      let y: UInt8 = encoding[3 * i + 1]
      let z: UInt8 = encoding[3 * i + 2]
      
      matrices[i] = SKSeitzMatrix(encoding: (x,y,z))
    }
    
    return matrices
  }
  
  public static func SeitzMatrices(encoding: [UInt8], centroSymmetric: Bool, inversionCenter: SIMD3<Int32>) -> [SKSeitzMatrix]
  {
    let m: Int = encoding.count/3
    let size: Int = centroSymmetric ? 2 * m : m
    
    var matrices: [SKSeitzMatrix] = [SKSeitzMatrix](repeating: SKSeitzMatrix(), count: size)
    
    for i in 0..<m
    {
      let x: UInt8 = encoding[3 * i]
      let y: UInt8 = encoding[3 * i + 1]
      let z: UInt8 = encoding[3 * i + 2]
      
      matrices[i] = SKSeitzMatrix(encoding: (x,y,z))
    }
    
    if (centroSymmetric)
    {
      for i in 0..<m
      {
        let x: UInt8 = encoding[3 * i]
        let y: UInt8 = encoding[3 * i + 1]
        let z: UInt8 = encoding[3 * i + 2]
        
        let seitz:SKSeitzMatrix = SKSeitzMatrix(encoding: (x,y,z))
        
        let translation: SIMD3<Int32> = seitz.translation + seitz.rotation * inversionCenter
        matrices[m+i] = SKSeitzMatrix(rotation: -seitz.rotation, translation: translation)
      }
    }
    
    return matrices
  }


 
  public static func * (left: SKSeitzMatrix, right: SIMD3<Double>) -> SIMD3<Double>
  {
    return SIMD3<Double>(x: Double(left.rotation[0][0]) * right.x + Double(left.rotation[1][0]) * right.y + Double(left.rotation[2][0]) * right.z + Double(left.translation.x)/12.0,
                   y: Double(left.rotation[0][1]) * right.x + Double(left.rotation[1][1]) * right.y + Double(left.rotation[2][1]) * right.z + Double(left.translation.y)/12.0,
                   z: Double(left.rotation[0][2]) * right.x + Double(left.rotation[1][2]) * right.y + Double(left.rotation[2][2]) * right.z + Double(left.translation.z)/12.0)
  }
  
  // (A1 | t1)(A2 | t2) = (A1A2 | t1 + A1t2)
  public static func * (left: SKSeitzMatrix, right: SKSeitzMatrix) -> SKSeitzMatrix
  {
    let rotationMatrix: SKRotationMatrix = left.rotation * right.rotation
    let a1: SIMD3<Int32> = left.translation
    let a2: SIMD3<Int32> = left.rotation * right.translation
    let translation: SIMD3<Int32> = a1 + a2
    return SKSeitzMatrix(rotation: rotationMatrix, translation: translation)
  }
  
  
  
  
  public var asString: (String, String, String)
  {
    get
    {
      var sum1: String = ""
      let s1: String = SKSeitzMatrix.rotationStringX[Int(self.rotation[0][0])] ?? ""
      sum1 += s1
      let s2: String = SKSeitzMatrix.rotationStringY[Int(self.rotation[1][0])] ?? ""
      if !sum1.isEmpty && !s2.hasPrefix("-") && !s2.isEmpty {sum1 += "+"}
      sum1 += s2
      let s3: String = SKSeitzMatrix.rotationStringZ[Int(self.rotation[2][0])] ?? ""
      if !sum1.isEmpty && !s3.hasPrefix("-") && !s3.isEmpty {sum1 += "+"}
      sum1 += s3
      let s4: String = SKSeitzMatrix.translationString[Int(self.translation.x)] ?? ""
      sum1 += s4
      
      var sum2: String = ""
      let s5: String = SKSeitzMatrix.rotationStringX[Int(self.rotation[0][1])] ?? ""
      sum2 += s5
      let s6: String = SKSeitzMatrix.rotationStringY[Int(self.rotation[1][1])] ?? ""
      if !sum2.isEmpty && !s6.hasPrefix("-") && !s6.isEmpty {sum2 += "+"}
      sum2 += s6
      let s7: String = SKSeitzMatrix.rotationStringZ[Int(self.rotation[2][1])] ?? ""
      if !sum2.isEmpty && !s7.hasPrefix("-") && !s7.isEmpty {sum2 += "+"}
      sum2 += s7
      let s8: String = SKSeitzMatrix.translationString[Int(self.translation.y)] ?? ""
      sum2 += s8
      
      var sum3: String = ""
      let s9: String = SKSeitzMatrix.rotationStringX[Int(self.rotation[0][2])] ?? ""
      sum3 += s9
      let s10: String = SKSeitzMatrix.rotationStringY[Int(self.rotation[1][2])] ?? ""
      if !sum3.isEmpty && !s10.hasPrefix("-") && !s10.isEmpty {sum3 += "+"}
      sum2 += s10
      let s11: String = SKSeitzMatrix.rotationStringZ[Int(self.rotation[2][2])] ?? ""
      if !sum3.isEmpty && !s11.hasPrefix("-") && !s11.isEmpty {sum3 += "+"}
      sum3 += s11
      let s12: String = SKSeitzMatrix.translationString[Int(self.translation.z)] ?? ""
      sum3 += s12

      return (sum1, sum2, sum3)
    }
  }

  
  static let SeitzData: [SKOneThirdSeitzMatrix] =
  [
    SKOneThirdSeitzMatrix(text: " x"      , encoding: "0", r1: 1, r2: 0, r3: 0,  t: 0),
    SKOneThirdSeitzMatrix(text: " y"      , encoding: "1", r1: 0, r2: 1, r3: 0,  t: 0),
    SKOneThirdSeitzMatrix(text: " z"      , encoding: "2", r1: 0, r2: 0, r3: 1,  t: 0),
    SKOneThirdSeitzMatrix(text: "-x"      , encoding: "3", r1:-1, r2: 0, r3: 0,  t: 0),
    SKOneThirdSeitzMatrix(text: "-y"      , encoding: "4", r1: 0, r2:-1, r3: 0,  t: 0),
    SKOneThirdSeitzMatrix(text: "-z"      , encoding: "5", r1: 0, r2: 0, r3:-1,  t: 0),
    SKOneThirdSeitzMatrix(text: "x-y"     , encoding: "6", r1: 1, r2:-1, r3: 0,  t: 0),
    SKOneThirdSeitzMatrix(text: "-x+y"    , encoding: "7", r1:-1, r2: 1, r3: 0,  t: 0),
    SKOneThirdSeitzMatrix(text: "x+1/2"   , encoding: "8", r1: 1, r2: 0, r3: 0,  t: 6),
    SKOneThirdSeitzMatrix(text: "x+1/3"   , encoding: "9", r1: 1, r2: 0, r3: 0,  t: 4),
    SKOneThirdSeitzMatrix(text: "x+1/4"   , encoding: ":", r1: 1, r2: 0, r3: 0,  t: 3),
    SKOneThirdSeitzMatrix(text: "x+2/3"   , encoding: ";", r1: 1, r2: 0, r3: 0,  t: 8),
    SKOneThirdSeitzMatrix(text: "x+3/4"   , encoding: "<", r1: 1, r2: 0, r3: 0,  t: 9),
    SKOneThirdSeitzMatrix(text: "y+1/2"   , encoding: "=", r1: 0, r2: 1, r3: 0,  t: 6),
    SKOneThirdSeitzMatrix(text: "y+1/3"   , encoding: ">", r1: 0, r2: 1, r3: 0,  t: 4),
    SKOneThirdSeitzMatrix(text: "y+1/4"   , encoding: "?", r1: 0, r2: 1, r3: 0,  t: 3),
    SKOneThirdSeitzMatrix(text: "y+2/3"   , encoding: "@", r1: 0, r2: 1, r3: 0,  t: 8),
    SKOneThirdSeitzMatrix(text: "y+3/4"   , encoding: "A", r1: 0, r2: 1, r3: 0,  t: 9),
    SKOneThirdSeitzMatrix(text: "z+1/2"   , encoding: "B", r1: 0, r2: 0, r3: 1,  t: 6),
    SKOneThirdSeitzMatrix(text: "z+1/3"   , encoding: "C", r1: 0, r2: 0, r3: 1,  t: 4),
    SKOneThirdSeitzMatrix(text: "z+1/4"   , encoding: "D", r1: 0, r2: 0, r3: 1,  t: 3),
    SKOneThirdSeitzMatrix(text: "z+1/6"   , encoding: "E", r1: 0, r2: 0, r3: 1,  t: 2),
    SKOneThirdSeitzMatrix(text: "z+2/3"   , encoding: "F", r1: 0, r2: 0, r3: 1,  t: 8),
    SKOneThirdSeitzMatrix(text: "z+3/4"   , encoding: "G", r1: 0, r2: 0, r3: 1,  t: 9),
    SKOneThirdSeitzMatrix(text: "z+5/6"   , encoding: "H", r1: 0, r2: 0, r3: 1,  t:10),
    SKOneThirdSeitzMatrix(text: "-x+1/2"  , encoding: "I", r1:-1, r2: 0, r3: 0,  t: 6),
    SKOneThirdSeitzMatrix(text: "-x+1/3"  , encoding: "J", r1:-1, r2: 0, r3: 0,  t: 4),
    SKOneThirdSeitzMatrix(text: "-x+1/4"  , encoding: "K", r1:-1, r2: 0, r3: 0,  t: 3),
    SKOneThirdSeitzMatrix(text: "-x+2/3"  , encoding: "L", r1:-1, r2: 0, r3: 0,  t: 8),
    SKOneThirdSeitzMatrix(text: "-x+3/4"  , encoding: "M", r1:-1, r2: 0, r3: 0,  t: 9),
    SKOneThirdSeitzMatrix(text: "-y+1/2"  , encoding: "N", r1: 0, r2:-1, r3: 0,  t: 6),
    SKOneThirdSeitzMatrix(text: "-y+1/3"  , encoding: "O", r1: 0, r2:-1, r3: 0,  t: 4),
    SKOneThirdSeitzMatrix(text: "-y+1/4"  , encoding: "P", r1: 0, r2:-1, r3: 0,  t: 3),
    SKOneThirdSeitzMatrix(text: "-y+2/3"  , encoding: "Q", r1: 0, r2:-1, r3: 0,  t: 8),
    SKOneThirdSeitzMatrix(text: "-y+3/4"  , encoding: "R", r1: 0, r2:-1, r3: 0,  t: 9),
    SKOneThirdSeitzMatrix(text: "-z+1/2"  , encoding: "S", r1: 0, r2: 0, r3:-1,  t: 6),
    SKOneThirdSeitzMatrix(text: "-z+1/3"  , encoding: "T", r1: 0, r2: 0, r3:-1,  t: 4),
    SKOneThirdSeitzMatrix(text: "-z+1/4"  , encoding: "U", r1: 0, r2: 0, r3:-1,  t: 3),
    SKOneThirdSeitzMatrix(text: "-z+1/6"  , encoding: "V", r1: 0, r2: 0, r3:-1,  t: 2),
    SKOneThirdSeitzMatrix(text: "-z+2/3"  , encoding: "W", r1: 0, r2: 0, r3:-1,  t: 8),
    SKOneThirdSeitzMatrix(text: "-z+3/4"  , encoding: "X", r1: 0, r2: 0, r3:-1,  t: 9),
    SKOneThirdSeitzMatrix(text: "-z+5/6"  , encoding: "Y", r1: 0, r2: 0, r3:-1,  t:10),
    SKOneThirdSeitzMatrix(text: "x-y+1/3" , encoding: "Z", r1: 1, r2:-1, r3: 0,  t: 4),
    SKOneThirdSeitzMatrix(text: "x-y+2/3" , encoding: "[", r1: 1, r2:-1, r3: 0,  t: 8),
    SKOneThirdSeitzMatrix(text: "-x+y+1/3", encoding: "\\", r1:-1, r2: 1, r3: 0,  t: 4),
    SKOneThirdSeitzMatrix(text: "-x+y+2/3", encoding: "]", r1:-1, r2: 1, r3: 0,  t: 8),
  ]
  
  
  public static func getConventionalSymmetry(transformationMatrix: double3x3, centering: SKSpacegroup.Centring, seitzMatrices: [SKSeitzMatrix]) -> [SKSeitzMatrix]
  {
    var shift: double3x3 = double3x3()
    let size: Int = seitzMatrices.count
    
    var multiplier: Int = 1
    switch(centering)
    {
    case .none, .primitive:
      break
    case .face:
      multiplier = 4
      shift = double3x3([SIMD3<Double>(0.0,1.0/2.0,1.0/2.0),SIMD3<Double>(1.0/2.0,0.0,1.0/2.0),SIMD3<Double>(1.0/2.0,1.0/2.0,0.0)])
      break
    case .r:
      multiplier = 3
      shift = double3x3([SIMD3<Double>(2.0/3.0,1.0/3.0,1.0/3.0),SIMD3<Double>(1.0/3.0,2.0/3.0,2.0/3.0),SIMD3<Double>(0.0,0.0,0.0)])
      break
    case .body:
      multiplier = 2
      shift = double3x3([SIMD3<Double>(1.0/2.0,1.0/2.0,1.0/2.0),SIMD3<Double>(0.0,0.0,0.0),SIMD3<Double>(0,0,0)])
    case .a_face:
      multiplier = 2
      shift = double3x3([SIMD3<Double>(0.0,1.0/2.0,1.0/2.0),SIMD3<Double>(0.0,0.0,0.0),SIMD3<Double>(0.0,0.0,0.0)])
    case .b_face:
      multiplier = 2
      shift = double3x3([SIMD3<Double>(1.0/2.0,0.0,1.0/2.0),SIMD3<Double>(0.0,0.0,0.0),SIMD3<Double>(0.0,0.0,0.0)])
    case .c_face:
      multiplier = 2
      shift = double3x3([SIMD3<Double>(1.0/2.0,1.0/2.0,0.0),SIMD3<Double>(0.0,0.0,0.0),SIMD3<Double>(0.0,0.0,0.0)])
      break
    default:
      break
   
    }
    
    
    
    var symmetry: [SKSeitzMatrix] = [SKSeitzMatrix](repeatElement(SKSeitzMatrix(), count: multiplier * size))
    
    
    for (index, seitzMatrix) in seitzMatrices.enumerated()
    {
      let primitive_sym_rot_d3: double3x3 = double3x3(seitzMatrix.rotation)
      
      // transform the symmetry operation in the primitive basis (W_O, w_o) to symmetry operations in the standard basis (W_S, w_S)
      // (W_S, w_S) = (C, c) * (W_O, w_o) * (C. c)^-1
      // The transformation from O to S:
      // M_{S,S} = C_{S,O}^{-1} M_{O,O} C{S,O},    C_{S,O}^{-1} = C_{O,S}
      
      let rotation: double3x3 = transformationMatrix.inverse * primitive_sym_rot_d3 * transformationMatrix
      
      
     
      // translation in conventional cell: S = C_{S,O}^-1 * P_O
      let translation: SIMD3<Double> = transformationMatrix.inverse * SIMD3<Double>(Double(seitzMatrix.translation.x)/12.0, Double(seitzMatrix.translation.y)/12.0, Double(seitzMatrix.translation.z)/12.0)
      
      
      symmetry[index] = SKSeitzMatrix(rotation: SKRotationMatrix(rotation), translation: translation)
      
      for i in 1..<multiplier
      {
        let translationWithShift: SIMD3<Double> = translation + shift[i-1]
        
        symmetry[index + i * size] = SKSeitzMatrix(rotation: SKRotationMatrix(rotation), translation: translationWithShift)
      }
    }
    
    return symmetry
  }
  
  
  

}

public struct SKOneThirdSeitzMatrix
{
  var text: String
  var encoding: Character
  var r1: Int8
  var r2: Int8
  var r3: Int8
  var t: Int8
  
  public init(text: String, encoding: Character, r1: Int8, r2: Int8, r3: Int8, t: Int8)
  {
    self.text = text
    self.encoding = encoding
    self.r1 = r1
    self.r2 = r2
    self.r3 = r3
    self.t = t
  }
  
  
  
  
  // encoding of Seitz-matrices generated by cctbx to (see 'fityk')
  // run as: 'cctbx_build/bin/cctbx.python script.py'
  //
  // from cctbx import sgtbx
  // smrows = {}
  // for s in sgtbx.space_group_symbol_iterator():
  //   #print s.number(), s.universal_hermann_mauguin().replace(" ","_")
  //   sg = sgtbx.space_group(s.hall())
  //   for i in sg.smx():
  //     sm = i.as_int_array()
  //     for n, s in enumerate(i.as_xyz().split(",")):
  //       if s not in smrows:
  //         smrows[s] = sm[3*n:3*n+3] + (sm[9+n],)
  //       else:
  //         assert smrows[s] == sm[3*n:3*n+3] + (sm[9+n],)
  // keys = sorted(smrows.keys(), cmp=lambda x, y: cmp(len(x), len(y)) or cmp(x,y))
  // if __name__ == '__main__':
  //   for n, k in enumerate(keys):
  //     print '/* %s */ { "%-8s, %2d,%2d,%2d,%3d },' % (
  //       (chr(n+ord('0')),k+'"') + smrows[k])

  
}
