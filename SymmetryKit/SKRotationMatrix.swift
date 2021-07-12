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

import Cocoa
import MathKit
import simd

public struct SKPointSymmetrySet
{
  public var rotations: OrderedSet< SKRotationMatrix > = OrderedSet()
  
  public init(rotations: OrderedSet<SKRotationMatrix>)
  {
    self.rotations = rotations
  }
}


public extension double3x3
{
  init(rotationMatrix a: SKRotationMatrix)
  {
    let col1 = a[0]
    let col2 = a[1]
    let col3 = a[2]
    self.init([SIMD3<Double>(x: Double(col1.x), y: Double(col1.y),z: Double(col1.z)),
               SIMD3<Double>(x: Double(col2.x), y: Double(col2.y),z: Double(col2.z)),
               SIMD3<Double>(x: Double(col3.x), y: Double(col3.y),z: Double(col3.z))])
  }
}

public struct SKRotationMatrix
{
  var elements: [SIMD3<Int32>]
  
  // S.R. Hall, "Space-group notation with an explicit origin", Acta. Cryst. A, 37, 517-525, 981
  
  static let zero: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0)])
  static let identity: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,1)])
  static let inversionIdentity: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(0,0,-1)])
  
  // rotations for principle axes
  static let r_2_100: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(0,0,-1)])
  static let r_2i_100: SKRotationMatrix = r_2_100
  static let r_3_100: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,0,1),SIMD3<Int32>(0,-1,-1)])
  static let r_3i_100: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,-1,-1),SIMD3<Int32>(0,1,0)])
  static let r_4_100: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,0,1),SIMD3<Int32>(0,-1,0)])
  static let r_4i_100: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,0,-1),SIMD3<Int32>(0,1,0)])
  static let r_6_100: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,1),SIMD3<Int32>(0,-1,0)])
  static let r_6i_100: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,0,-1),SIMD3<Int32>(0,1,1)])
  
  static let r_2_010: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,-1)])
  static let r_2i_010: SKRotationMatrix = r_2_010
  static let r_3_010: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(-1,0,-1),SIMD3<Int32>(0,1,0),SIMD3<Int32>(1,0,0)])
  static let r_3i_010: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(0,0,1),SIMD3<Int32>(0,1,0),SIMD3<Int32>(-1,0,-1)])
  static let r_4_010: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(0,0,-1),SIMD3<Int32>(0,1,0),SIMD3<Int32>(1,0,0)])
  static let r_4i_010: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(0,0,1),SIMD3<Int32>(0,1,0),SIMD3<Int32>(-1,0,0)])
  static let r_6_010: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(0,0,-1),SIMD3<Int32>(0,1,0),SIMD3<Int32>(1,0,1)])
  static let r_6i_010: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(1,0,1),SIMD3<Int32>(0,1,0),SIMD3<Int32>(-1,0,0)])

  static let r_2_001: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(0,0,1)])
  static let r_2i_001: SKRotationMatrix = r_2_001
  static let r_3_001: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(0,1,0),SIMD3<Int32>(-1,-1,0),SIMD3<Int32>(0,0,1)])
  static let r_3i_001: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(-1,-1,0),SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,0,1)])
  static let r_4_001: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(0,1,0),SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,0,1)])
  static let r_4i_001: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(0,-1,0),SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,0,1)])
  static let r_6_001: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(1,1,0),SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,0,1)])
  static let r_6i_001: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(0,-1,0),SIMD3<Int32>(1,1,0),SIMD3<Int32>(0,0,1)])
  
  static let r_3_111: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,1),SIMD3<Int32>(1,0,0)])
  static let r_3i_111: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(0,0,1),SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0)])
  
  static let r_2prime_100: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,0,-1),SIMD3<Int32>(0,-1,0)])   // b-c
  static let r_2iprime_100: SKRotationMatrix = r_2prime_100
  static let r_2doubleprime_100: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,0,1),SIMD3<Int32>(0,1,0)]) // b+c
  static let r_2idoubleprime_100: SKRotationMatrix = r_2doubleprime_100
  
  static let r_2prime_010: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(0,0,-1),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(-1,0,0)]) // a-c
  static let r_2iprime_010: SKRotationMatrix = r_2prime_010
  static let r_2doubleprime_010: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(0,0,1),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(1,0,0)]) // a+c
  static let r_2idoubleprime_010: SKRotationMatrix = r_2doubleprime_010
  
  static let r_2prime_001: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(0,-1,0),SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,0,-1)]) // a-b
  static let r_2iprime_001: SKRotationMatrix = r_2prime_001
  static let r_2doubleprime_001: SKRotationMatrix = SKRotationMatrix([SIMD3<Int32>(0,1,0),SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,0,-1)]) // a+b
  static let r_2idoubleprime_001: SKRotationMatrix = r_2doubleprime_001
  
  static let generators: [SKPointGroup.Holohedry : (required: [SKRotationMatrix], optional: [SKRotationMatrix]) ]  =
  [
    .triclinic : (required: [SKRotationMatrix.identity], optional: []),
    .monoclinic : (required: [SKRotationMatrix.r_2_001,SKRotationMatrix.r_2_100,SKRotationMatrix.r_2_010], optional: []),
    .orthorhombic : (required: [SKRotationMatrix.r_2_001], optional: [SKRotationMatrix.r_2_100]),
    .tetragonal : (required: [SKRotationMatrix.r_4_001], optional: [SKRotationMatrix.r_2_100]),
    .trigonal : (required: [SKRotationMatrix.r_3_001, SKRotationMatrix.r_3_111], optional: [SKRotationMatrix.r_2prime_001,SKRotationMatrix.r_2doubleprime_001]),
    .hexagonal : (required: [SKRotationMatrix.r_6_001], optional: [SKRotationMatrix.r_2doubleprime_001]),
    .cubic : (required: [SKRotationMatrix.r_4_001,SKRotationMatrix.r_2_001], optional: [SKRotationMatrix.r_3_111])
  ]
  
  init(random: Int = 0)
  {
    var c1: SIMD3<Int32>
    var c2: SIMD3<Int32>
    var c3: SIMD3<Int32>
    var succes: Bool = false
    var rotationMatrix: SKRotationMatrix
    repeat
    {
      c1 = SIMD3<Int32>(Int32(arc4random_uniform(3))-1, Int32(arc4random_uniform(3))-1, Int32(arc4random_uniform(3))-1)
      c2 = SIMD3<Int32>(Int32(arc4random_uniform(3))-1, Int32(arc4random_uniform(3))-1, Int32(arc4random_uniform(3))-1)
      c3 = SIMD3<Int32>(Int32(arc4random_uniform(3))-1, Int32(arc4random_uniform(3))-1, Int32(arc4random_uniform(3))-1)
      rotationMatrix = SKRotationMatrix([c1,c2,c3])
      let determinant: Int = rotationMatrix.determinant
      let isProperRotation: Bool = determinant == 1
      let isImproperRotation: Bool = determinant == -1
 
      switch(random)
      {
        case 0:
          succes = isProperRotation || isImproperRotation
        case -1: succes = isImproperRotation
        case 1: succes = isProperRotation
        default:
          succes = isProperRotation || isImproperRotation
      }
    }
    while !(succes) || (rotationMatrix.type.rawValue==0)
    self.init([c1,c2,c3])
  }
  
  public init(_ m: double3x3)
  {
    let c1: SIMD3<Int32> = SIMD3<Int32>(Int32(rint(m[0].x)),
                        Int32(rint(m[0].y)),
                        Int32(rint(m[0].z)))
    let c2: SIMD3<Int32> = SIMD3<Int32>(Int32(rint(m[1].x)),
                        Int32(rint(m[1].y)),
                        Int32(rint(m[1].z)))
    let c3: SIMD3<Int32> = SIMD3<Int32>(Int32(rint(m[2].x)),
                        Int32(rint(m[2].y)),
                        Int32(rint(m[2].z)))
    self.init([c1,c2,c3])
  }
  
  public init(scalar: Int32, denominator: Int = 1)
  {
    self.elements = [SIMD3<Int32>(scalar,0,0),SIMD3<Int32>(0,scalar,0),SIMD3<Int32>(0,0,scalar)]
  }
  
  public init(_ columns: [SIMD3<Int32>], denominator: Int = 1)
  {
    self.elements = columns
  }
  
  public init(_ scalar: Int32, denominator: Int = 1)
  {
    self.init([SIMD3<Int32>(scalar,0,0),SIMD3<Int32>(0,scalar,0),SIMD3<Int32>(0,0,scalar)])
  }
  
  public init(rows: [SIMD3<Int32>], denominator: Int = 1)
  {
    self.elements = [SIMD3<Int32>(rows[0].x,rows[1].x,rows[2].x), SIMD3<Int32>(rows[0].y,rows[1].y,rows[2].y), SIMD3<Int32>(rows[0].z,rows[1].z,rows[2].z)]
  }
  
  public init(int3x3: int3x3)
  {
    self.elements = [int3x3[0], int3x3[1], int3x3[2]]
  }
  
  public init(_ m: SKTransformationMatrix)
  {
    self.elements = [m[0], m[1], m[2]]
    assert(abs(self.determinant) == 1, "determinant should be 1 or -1")
  }
  
  
  /// Access to individual elements.
  public subscript(column: Int, row: Int) -> Int32
  {
    get
    {
      return self.elements[column][row]
    }
    set(newValue)
    {
      self.elements[column][row] = newValue
    }
  }
  
  public subscript(column: Int) -> SIMD3<Int32>
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
  
  var int3x3: int3x3
  {
    return MathKit.int3x3.init([self[0],self[1],self[2]])
  }
  
  enum rotationType: Int
  {
    case axis_6m = -6
    case axis_4m = -4
    case axis_3m = -3
    case axis_2m = -2
    case axis_1m = -1
    case none = 0
    case axis_1 = 1
    case axis_2 = 2
    case axis_3 = 3
    case axis_4 = 4
    case axis_6 = 6
  }
  
  var proper: SKRotationMatrix
  {
    if self.determinant == 1
    {
      return self
    }
    else
    {
      return -self
    }
  }
  
  var type: rotationType
  {
    let determinant: Int = self.determinant
    
    if(determinant == -1)
    {
      switch(self.trace)
      {
      case -3:
        return rotationType.axis_1m
      case -2:
        return rotationType.axis_6m
      case -1:
        return rotationType.axis_4m
      case 0:
        return rotationType.axis_3m
      case 1:
        return rotationType.axis_2m
        
      default:
        return rotationType.none
      }
    }
    else
    {
      switch(self.trace)
      {
      case -1:
        return rotationType.axis_2
      case 0:
        return rotationType.axis_3
      case 1:
        return rotationType.axis_4
      case 2:
        return rotationType.axis_6
      case 3:
        return rotationType.axis_1
      default:
        return rotationType.none
      }
    }
    
  }
  
  public var transpose: SKRotationMatrix
  {
    return SKRotationMatrix([SIMD3<Int32>(self[0,0],self[1,0],self[2,0]),
                             SIMD3<Int32>(self[0,1],self[1,1],self[2,1]),
                             SIMD3<Int32>(self[0,2],self[1,2],self[2,2])])
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
  
  public var greatestCommonDivisor: Int32
  {
    return [self[0,0],self[0,1],self[0,2], self[1,0],self[1,1],self[1,2], self[2,0],self[2,1],self[2,2]].reduce(0){(Int32.greatestCommonDivisor(a: $0, b: $1))}
  }
  
  func positiveSenseOfRotation(rotationAxis: SIMD3<Int32>) -> Bool
  {
    let properRotationMatrix: SKRotationMatrix = self.proper
    if (rotationAxis.z == 0) && (rotationAxis.y == 0) && (rotationAxis.x*properRotationMatrix[1,2]>0) {return true}
    if (properRotationMatrix[0,1] * rotationAxis.z - properRotationMatrix[0,2] * rotationAxis.y) > 0 {return true}
    return false
  }

  
  /// Computes the number of times the matrix must be multiplied with itself in order to obtain the unit matrix
  ///
  /// - parameter type: the rotationType -6,..,6, if zero or omitted the current order is returned
  ///
  /// - returns: the rotational order
  func order(type: Int = 0) -> Int
  {
    var N: Int = type
    
    if (N == 0) {N = self.type.rawValue}
    
    // for N=1,2,3,4,5,6, the order is N
    if (N > 0) {return  N}
    
    // for type N=-1 and N=-3 (and N=-5, but that does not exist), the order is n=-2N
    if (N % 2 != 0) {return -2*N}
    
    // for type N=-2,-4,-6 the order is n=-N
    return -N
  }
  
  
  
  /// The repeated products of this rotation matrix with itself
  ///
  /// - parameter type: the rotationType -6,..,6
  ///
  /// - returns: self**(order() - 1)
  func power(exponent: Int) -> SKRotationMatrix
  {
    if (exponent == 1) {return self}
    var result: SKRotationMatrix = self
    for _ in 1..<exponent
    {
      result = result * self
    }
    return result
  }
 
  /// Sum of repeated products of this rotation matrix with itself
  ///
  /// - parameter type: the rotationType -6,..,6
  ///
  /// - returns: identity + self + self*self + ... + self**(order() - 1)
  func accumulate(type: Int = 0) -> SKRotationMatrix
  {
    let order: Int = self.order(type: type)
    if (order == 1) {return self}
    var a: SKRotationMatrix = self
    var result: SKRotationMatrix = SKRotationMatrix(1) + a
    for _ in 2..<order
    {
      a = a * self
      result = result + a
    }
    return result
  }
  
  
  /// Computes a list of integer-vectors that are orthogonal to the rotation axis for a given rotation matrix
  ///
  /// - parameter rotationOrder: the rotation order
  ///
  /// - returns: a list of perpendicular eigenvectors
  ///
  /// Note : Theorem TA4.1 in Boisen en Gibbs (1990) states that a vector x is in the plane perpendicular to the axis direction 'e' of a proper rotation matrix 'W_p'
  /// with rotational order 'n' if and only if S.x=0 where S = W_p + W_p^2 + ... + W_p^n
  /// Ref: R.W. Grosse-Kunstleve, "Algorithms for deriving crystallographic space-group information", Acta Cryst. A55, 383-395, 1999
  ///
  /// The algorithm of Atsushi Togo is used: a search over all possible rotation axes.
  func orthogonalToAxisDirection(rotationOrder: Int) -> [SIMD3<Int32>]
  {
    var orthoAxes: [SIMD3<Int32>] = []
   
    let properRotation: SKRotationMatrix = self.proper
    var sumRot: SKRotationMatrix = SKRotationMatrix.identity
    var rot: SKRotationMatrix = SKRotationMatrix.identity
   
    for _ in 0..<rotationOrder-1
    {
      rot = rot * properRotation
      sumRot = sumRot + rot
    }
   
    for rotationAxes in SKRotationMatrix.allPossibleRotationAxes
    {      
      if sumRot * rotationAxes == SIMD3<Int32>(0,0,0)
      {
        orthoAxes.append(rotationAxes)
      }
    }
   
    return orthoAxes
  }

  
  var adjoint: SKRotationMatrix
  {
    let c1: SIMD3<Int32> = SIMD3<Int32>(-self[1,2] * self[2,1] + self[1,1] * self[2,2],self[1,2] * self[2,0] - self[1,0] * self[2,2],-self[1,1] * self[2,0] + self[1,0] * self[2,1])
    let c2: SIMD3<Int32> = SIMD3<Int32>(self[0,2] * self[2,1] - self[0,1] * self[2,2], -self[0,2] * self[2,0] + self[0,0] * self[2,2], self[0,1] * self[2,0] - self[0,0] * self[2,1])
    let c3: SIMD3<Int32> = SIMD3<Int32>(-self[0,2] * self[1,1] + self[0,1] * self[1,2], self[0,2] * self[1,0] - self[0,0] * self[1,2], -self[0,1] * self[1,0] + self[0,0] * self[1,1])
    return SKRotationMatrix([c1,c2,c3])
  }
  
  // If orthogonal: (A|t)−1 =(A−1 |−A−1t)=(AT |−ATt)
  // Note: not all space-group rotation matrices are orthogonal
  // (for example: 143, 1: x, y, z, 2: -y, x-y, z, 3: -x+y, -x, z),
  // These rotation matrices are semi-orthogonal and do have an inverse.
  
  /// Inverse of the matrix if the determinant = 1 or -1, otherwise the contents of the resulting matrix are undefined.
  public var inverse: SKRotationMatrix
  {
    let determinant: Int = self.determinant
    
    let c1: SIMD3<Int32> = SIMD3<Int32>(-self[1][2] * self[2][1] + self[1][1] * self[2][2], self[0][2] * self[2][1] - self[0][1] * self[2][2], -self[0][2] * self[1][1] + self[0][1] * self[1][2])
    let c2: SIMD3<Int32> = SIMD3<Int32>(self[1][2] * self[2][0] - self[1][0] * self[2][2], -self[0][2] * self[2][0] + self[0][0] * self[2][2], self[0][2] * self[1][0] - self[0][0] * self[1][2])
    let c3: SIMD3<Int32> = SIMD3<Int32>(-self[1][1] * self[2][0] + self[1][0] * self[2][1], self[0][1] * self[2][0] - self[0][0] * self[2][1], -self[0][1] * self[1][0] + self[0][0] * self[1][1])
    
     switch(determinant)
    {
      case -1: return -SKRotationMatrix([c1, c2, c3])
      case 1: return SKRotationMatrix([c1,c2,c3])
      default: return SKRotationMatrix()
    }
  }
  
  static var inversion: SKRotationMatrix = SKRotationMatrix(scalar: -1)
  
  var isIdentity: Bool
  {
    return (self == SKRotationMatrix.identity)
  }
  
  var isInversion: Bool
  {
    return (self == SKRotationMatrix.inversion)
  }
  
  static func rationalize(fValue: Double, denomintor: Int) -> Int?
  {
    var iValue: Int
    if (denomintor == 0) {return nil}
    var localFValue: Double = fValue * Double(denomintor)
    if (localFValue < 0.0)
    {
      iValue = Int(localFValue - 0.5)
    }
    else
    {
      iValue = Int(localFValue + 0.5)
    }
    localFValue -= Double(iValue)
    localFValue /= Double(denomintor)
    if (localFValue < 0.0) {localFValue = -localFValue}
    if (localFValue > 0.0005) {return nil}
    return iValue
  }

  var properRotation: SKRotationMatrix
  {
    if (self.determinant == -1)
    {
      return SKRotationMatrix.inversion * self
    }
    return self
  }
  
  
  var properRotation2: SKRotationMatrix
  {
    if (self.determinant < 0)
    {
      return SKRotationMatrix.inversion * self
    }
    return self
  }
  
  var rotationAxis: SIMD3<Int32>
  {
    // rotation axis is the eigenvector with eigenvalue lambda==1
    for i in 0..<SKRotationMatrix.allPossibleRotationAxes.count
    {
      if self * SKRotationMatrix.allPossibleRotationAxes[i] == SKRotationMatrix.allPossibleRotationAxes[i]
      {
        return SKRotationMatrix.allPossibleRotationAxes[i]
      }
    }
    
    return SIMD3<Int32>(0,0,0)
  }
 
  var rotationAxes: [SIMD3<Int32>]
  {
    // No specific axis for I and -I
    //if self.isIdentity { return nil}
    
    var result: [SIMD3<Int32>] = []
    
    // rotation axis is the eigenvector with eigenvalue lambda==1
    for i in 0..<SKRotationMatrix.allPossibleRotationAxes.count
    {
      if self * SKRotationMatrix.allPossibleRotationAxes[i] == SKRotationMatrix.allPossibleRotationAxes[i]
      {
        result.append(SKRotationMatrix.allPossibleRotationAxes[i])
      }
    }
    
    return result
  }
  
  // Determining the lattice symmetry is equivalent to determining the Bravais type.
  static func findLatticeSymmetry(unitCell min_lattice: double3x3, anglePrecision: Double = 3.0) -> SKPointSymmetrySet
  {
    var pointSymmetries: OrderedSet<SKRotationMatrix> = []
    
    let min_cos_delta: Double = min(cos(anglePrecision * Double.pi/180.0), 1.0 - Double.ulpOfOne)
    
    let inverse_min_lattice: double3x3 = min_lattice.inverse
    for twoFoldSymmetryOperation in twoFoldSymmetryOperations
    {
      let t: SIMD3<Double> = min_lattice * twoFoldSymmetryOperation.axisDirect
      let tau: SIMD3<Double> =  twoFoldSymmetryOperation.axisReciprocal * inverse_min_lattice
      
      let numerator: Double = abs(dot(t,tau))
      let denominator: Double = sqrt(length_squared(t) * length_squared(tau))
      
      let cos_delta: Double = numerator / denominator
      if (cos_delta >= min_cos_delta)
      {
        pointSymmetries.append(twoFoldSymmetryOperation.rotationMatrix)
      }
    }
    
    // add inversion center
    pointSymmetries.append(SKRotationMatrix([SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(0,0,-1)]))
    
    var i = twoFoldSymmetryOperations.startIndex
    while i != twoFoldSymmetryOperations.endIndex
    {
      for (index, pointSymmetry) in pointSymmetries.enumerated() where index > i
      {
        for symmetryOperation in pointSymmetries
        {
          pointSymmetries.append(symmetryOperation * pointSymmetry)
        }
      }
      
      i = twoFoldSymmetryOperations.index(after: i)
    }
    
    return SKPointSymmetrySet(rotations: pointSymmetries)
  }
  
  
  /// Find the point-symmetry of the lattice
  ///
  /// Note: No atomic positions are taken into account, only the lattice vectors.
  ///
  /// - parameter unitCell: unit cell of the lattice
  ///
  /// - returns: the symmetry elements, i.e. a list of integer rotation matrices
  ///
  /// The metric tensor is computed as Gij = ai · aj = h^T h, where h^T is the transpose of h and h = ( a1 , a2 , a3 ) , the transformation matrix between Cartesian and lattice coordinates, i,e, the unit cell.
  /// Lebedev et al.(2006) introduced the idea of simply enumerating all 3x3 matrices with elements {-1,0,1} and determinant of 1 or -1.
  /// W is a distance-preserving transformation called (linear) isometry or orthogonal transformation describing a proper or improper rotation.
  /// Determinant det(W) = +/- 1, and thus each isometry is reversible. A reversal of W, that is rotation in the opposite direction, is equivalent to transposition, since W^-1= W^T.
  /// W transforms the lattice basis A' = A W or M' =  W^T M W
  /// 10.1107/s2053273315001096
  /// Le Page, Y. (1982). J. Appl. Cryst. 15, 255-259.
  /// Lebedev, A.A., Vagin, A.A. & Murshudov, G.N. (2006). Acta Cryst. D62, 83-95.
  static func findLatticeSymmetry(primitiveUnitCell: double3x3, unitCell cell_lattice: double3x3, symmetryPrecision: Double = 1e-4) -> SKPointSymmetrySet
  {
    let latticeAxes: [SIMD3<Int32>] = [
      /*
      SIMD3<Int32>( 1, 1, 1),
      SIMD3<Int32>( 1, 1, 0),
      SIMD3<Int32>( 1, 1,-1),
      SIMD3<Int32>( 1, 0, 1),
      SIMD3<Int32>( 1, 0, 0),
      SIMD3<Int32>( 1, 0,-1),
      SIMD3<Int32>( 1,-1, 1),
      SIMD3<Int32>( 1,-1, 0),
      SIMD3<Int32>( 1,-1,-1),
      SIMD3<Int32>( 0, 1, 1),
      SIMD3<Int32>( 0, 1, 0),
      SIMD3<Int32>( 0, 1,-1),
      SIMD3<Int32>( 0, 0, 1),
      SIMD3<Int32>( 0, 0,-1),
      SIMD3<Int32>( 0,-1, 1),
      SIMD3<Int32>( 0,-1, 0),
      SIMD3<Int32>( 0,-1,-1),
      SIMD3<Int32>(-1, 1, 1),
      SIMD3<Int32>(-1, 1, 0),
      SIMD3<Int32>(-1, 1,-1),
      SIMD3<Int32>(-1, 0, 1),
      SIMD3<Int32>(-1, 0, 0),
      SIMD3<Int32>(-1, 0,-1),
      SIMD3<Int32>(-1,-1, 1),
      SIMD3<Int32>(-1,-1, 0),
      SIMD3<Int32>(-1,-1,-1),*/
      
      SIMD3<Int32>( 1, 0, 0),
      SIMD3<Int32>( 0, 1, 0),
      SIMD3<Int32>( 0, 0, 1),
      SIMD3<Int32>(-1, 0, 0),
      SIMD3<Int32>( 0,-1, 0), /* 5 */
      SIMD3<Int32>( 0, 0,-1),
      SIMD3<Int32>( 0, 1, 1),
      SIMD3<Int32>( 1, 0, 1),
      SIMD3<Int32>( 1, 1, 0),
      SIMD3<Int32>( 0,-1,-1), /* 10 */
      SIMD3<Int32>(-1, 0,-1),
      SIMD3<Int32>(-1,-1, 0),
      SIMD3<Int32>( 0, 1,-1),
      SIMD3<Int32>(-1, 0, 1),
      SIMD3<Int32>( 1,-1, 0), /* 15 */
      SIMD3<Int32>( 0,-1, 1),
      SIMD3<Int32>( 1, 0,-1),
      SIMD3<Int32>(-1, 1, 0),
      SIMD3<Int32>( 1, 1, 1),
      SIMD3<Int32>(-1,-1,-1), /* 20 */
      SIMD3<Int32>(-1, 1, 1),
      SIMD3<Int32>( 1,-1, 1),
      SIMD3<Int32>( 1, 1,-1),
      SIMD3<Int32>( 1,-1,-1),
      SIMD3<Int32>(-1, 1,-1), /* 25 */
      SIMD3<Int32>(-1,-1, 1)
    ]
    
    var pointSymmetries: OrderedSet<SKRotationMatrix> = OrderedSet<SKRotationMatrix>()
    
    let min_lattice: double3x3 = SKSymmetryCell.computeDelaunayReducedCell(unitCell: cell_lattice)!
    
    let latticeMetricMatrix: double3x3 = min_lattice.transpose * min_lattice
    
    // uses a stored list of all possible lattice vectors and loop over all possible permutations
    for (index_i, firstAxis) in latticeAxes.enumerated()
    {
      for (index_j, secondAxis) in latticeAxes.enumerated()
      {
        for (index_k, thirdAxis) in latticeAxes.enumerated()
        {
          let axes: SKRotationMatrix = SKRotationMatrix([firstAxis, secondAxis, thirdAxis])
          let determinant: Int = axes.determinant
          
          // if the determinant is 1 or -1 we have a (proper) rotation  (6960 proper rotations)
          if (determinant == 1 || determinant == -1)
          {
            let transformationMatrix: double3x3 = double3x3(rotationMatrix: axes)
            // the inverse of a rotation matrix is its transpose, so we use the transpose here
            let newLattice: double3x3 = min_lattice * transformationMatrix
            let transformedLatticeMetricMatrix: double3x3 = newLattice.transpose * newLattice
            
            // Apply a change of basis on the latticeMetricMatrix using the rotation matrix
            //let transformedLatticeMetricMatrix: double3x3 = inverseTransformationMatrix * latticeMetricMatrix * transformationMatrix
            
            if (SKSymmetryCell.isIdentityMetric(transformedMetricMatrix: transformedLatticeMetricMatrix, metricMatrix: latticeMetricMatrix, symmetryPrecision: symmetryPrecision, angleSymmetryPrecision: -1.0))
            {
              if (!pointSymmetries.contains(axes))
              {
                pointSymmetries.append(axes)
              }
            }
          }
        }
      }
    }
    
    let newLattice = cell_lattice
    
    let original_lattice = min_lattice
    
    let trans: double3x3 = (original_lattice.inverse * newLattice)
      
    
    var newpointSymmetries: OrderedSet<SKRotationMatrix> = OrderedSet<SKRotationMatrix>()
    for pointSymmetry in pointSymmetries
    {
      let mat = SKRotationMatrix(trans.inverse * double3x3(rotationMatrix: pointSymmetry) * trans)
      if (!newpointSymmetries.contains(mat))
      {
        newpointSymmetries.append(mat)
      }
    }
    
    return SKPointSymmetrySet(rotations: newpointSymmetries)
  }

  
  
  
  // all possible rotation axes written in terms of integers
  // convention: e3 is positive, if e3=0, then e2 is positive. If e3=e2=0 then e1 is chosen as positive
  static let allPossibleRotationAxes: [SIMD3<Int32>] =
  [
    SIMD3<Int32>( 1, 0, 0),
    SIMD3<Int32>( 0, 1, 0),
    SIMD3<Int32>( 0, 0, 1),
    SIMD3<Int32>( 0, 1, 1),
    SIMD3<Int32>( 1, 0, 1),
    SIMD3<Int32>( 1, 1, 0),
    SIMD3<Int32>( 0, 1,-1),
    SIMD3<Int32>(-1, 0, 1),
    SIMD3<Int32>( 1,-1, 0),
    SIMD3<Int32>( 1, 1, 1), /* 10 */
    SIMD3<Int32>(-1, 1, 1),
    SIMD3<Int32>( 1,-1, 1),
    SIMD3<Int32>( 1, 1,-1),
    SIMD3<Int32>( 0, 1, 2),
    SIMD3<Int32>( 2, 0, 1),
    SIMD3<Int32>( 1, 2, 0),
    SIMD3<Int32>( 0, 2, 1),
    SIMD3<Int32>( 1, 0, 2),
    SIMD3<Int32>( 2, 1, 0),
    SIMD3<Int32>( 0,-1, 2), /* 20 */
    SIMD3<Int32>( 2, 0,-1),
    SIMD3<Int32>(-1, 2, 0),
    SIMD3<Int32>( 0,-2, 1),
    SIMD3<Int32>( 1, 0,-2),
    SIMD3<Int32>(-2, 1, 0),
    SIMD3<Int32>( 2, 1, 1),
    SIMD3<Int32>( 1, 2, 1),
    SIMD3<Int32>( 1, 1, 2),
    SIMD3<Int32>( 2,-1,-1),
    SIMD3<Int32>(-1, 2,-1), /* 30 */
    SIMD3<Int32>(-1,-1, 2),
    SIMD3<Int32>( 2, 1,-1),
    SIMD3<Int32>(-1, 2, 1),
    SIMD3<Int32>( 1,-1, 2),
    SIMD3<Int32>( 2,-1, 1), /* 35 */
    SIMD3<Int32>( 1, 2,-1),
    SIMD3<Int32>(-1, 1, 2),
    SIMD3<Int32>( 3, 1, 2),
    SIMD3<Int32>( 2, 3, 1),
    SIMD3<Int32>( 1, 2, 3), /* 40 */
    SIMD3<Int32>( 3, 2, 1),
    SIMD3<Int32>( 1, 3, 2),
    SIMD3<Int32>( 2, 1, 3),
    SIMD3<Int32>( 3,-1, 2),
    SIMD3<Int32>( 2, 3,-1), /* 45 */
    SIMD3<Int32>(-1, 2, 3),
    SIMD3<Int32>( 3,-2, 1),
    SIMD3<Int32>( 1, 3,-2),
    SIMD3<Int32>(-2, 1, 3),
    SIMD3<Int32>( 3,-1,-2), /* 50 */
    SIMD3<Int32>(-2, 3,-1),
    SIMD3<Int32>(-1,-2, 3),
    SIMD3<Int32>( 3,-2,-1),
    SIMD3<Int32>(-1, 3,-2),
    SIMD3<Int32>(-2,-1, 3), /* 55 */
    SIMD3<Int32>( 3, 1,-2),
    SIMD3<Int32>(-2, 3, 1),
    SIMD3<Int32>( 1,-2, 3),
    SIMD3<Int32>( 3, 2,-1),
    SIMD3<Int32>(-1, 3, 2), /* 60 */
    SIMD3<Int32>( 2,-1, 3),
    SIMD3<Int32>( 1, 1, 3),
    SIMD3<Int32>(-1, 1, 3),
    SIMD3<Int32>( 1,-1, 3),
    SIMD3<Int32>(-1,-1, 3), /* 65 */
    SIMD3<Int32>( 1, 3, 1),
    SIMD3<Int32>(-1, 3, 1),
    SIMD3<Int32>( 1, 3,-1),
    SIMD3<Int32>(-1, 3,-1),
    SIMD3<Int32>( 3, 1, 1), /* 70 */
    SIMD3<Int32>( 3, 1,-1),
    SIMD3<Int32>( 3,-1, 1),
    SIMD3<Int32>( 3,-1,-1)
    
    /*
    SIMD3<Int32>( 1, 0, 0),
    SIMD3<Int32>( 0, 1, 0),
    SIMD3<Int32>( 0, 0, 1),
    SIMD3<Int32>( 0, 1, 1),
    SIMD3<Int32>( 1, 0, 1),
    SIMD3<Int32>( 1, 1, 0),
    SIMD3<Int32>( 0, 1,-1),
    SIMD3<Int32>(-1, 0, 1),
    SIMD3<Int32>( 1,-1, 0),
    SIMD3<Int32>( 1, 1, 1), /* 10 */
    SIMD3<Int32>(-1, 1, 1),
    SIMD3<Int32>( 1,-1, 1),
    SIMD3<Int32>(-1,-1, 1),
    SIMD3<Int32>( 0, 1, 2),
    SIMD3<Int32>( 2, 0, 1),
    SIMD3<Int32>( 1, 2, 0),
    SIMD3<Int32>( 0, 2, 1),
    SIMD3<Int32>( 1, 0, 2),
    SIMD3<Int32>( 2, 1, 0),
    SIMD3<Int32>( 0,-1, 2), /* 20 */
    SIMD3<Int32>(-2, 0, 1),
    SIMD3<Int32>(-1, 2, 0),
    SIMD3<Int32>( 0,-2, 1),
    SIMD3<Int32>(-1, 0, 2),
    SIMD3<Int32>(-2, 1, 0),
    SIMD3<Int32>( 2, 1, 1),
    SIMD3<Int32>( 1, 2, 1),
    SIMD3<Int32>( 1, 1, 2),
    SIMD3<Int32>(-2, 1, 1),
    SIMD3<Int32>( 1,-2, 1), /* 30 */
    SIMD3<Int32>(-1,-1, 2),
    SIMD3<Int32>(-2,-1, 1),
    SIMD3<Int32>(-1, 2, 1),
    SIMD3<Int32>( 1,-1, 2),
    SIMD3<Int32>( 2,-1, 1), /* 35 */
    SIMD3<Int32>(-1,-2, 1),
    SIMD3<Int32>(-1, 1, 2),
    SIMD3<Int32>( 3, 1, 2),
    SIMD3<Int32>( 2, 3, 1),
    SIMD3<Int32>( 1, 2, 3), /* 40 */
    SIMD3<Int32>( 3, 2, 1),
    SIMD3<Int32>( 1, 3, 2),
    SIMD3<Int32>( 2, 1, 3),
    SIMD3<Int32>( 3,-1, 2),
    SIMD3<Int32>(-2,-3, 1), /* 45 */
    SIMD3<Int32>(-1, 2, 3),
    SIMD3<Int32>( 3,-2, 1),
    SIMD3<Int32>(-1,-3, 2),
    SIMD3<Int32>(-2, 1, 3),
    SIMD3<Int32>(-3, 1, 2), /* 50 */
    SIMD3<Int32>( 2,-3, 1),
    SIMD3<Int32>(-1,-2, 3),
    SIMD3<Int32>(-3, 2, 1),
    SIMD3<Int32>( 1,-3, 2),
    SIMD3<Int32>(-2,-1, 3), /* 55 */
    SIMD3<Int32>(-3,-1, 2),
    SIMD3<Int32>(-2, 3, 1),
    SIMD3<Int32>( 1,-2, 3),
    SIMD3<Int32>(-3,-2, 1),
    SIMD3<Int32>(-1, 3, 2), /* 60 */
    SIMD3<Int32>( 2,-1, 3),
    SIMD3<Int32>( 1, 1, 3),
    SIMD3<Int32>(-1, 1, 3),
    SIMD3<Int32>( 1,-1, 3),
    SIMD3<Int32>(-1,-1, 3), /* 65 */
    SIMD3<Int32>( 1, 3, 1),
    SIMD3<Int32>(-1, 3, 1),
    SIMD3<Int32>(-1,-3, 1),
    SIMD3<Int32>( 1,-3, 1),
    SIMD3<Int32>( 3, 1, 1), /* 70 */
    SIMD3<Int32>(-3,-1, 1),
    SIMD3<Int32>( 3,-1, 1),
    SIMD3<Int32>(-3, 1, 1)
    */
    
  ]
  
  // 81 2-fold symmetry operations possible for reduced cells:
  // 1) the matrix elements
  // 2) the axis directions in direct space 
  // 3) the axis directions in reciprocal space
  // Two folds correspond to 90 degree angles between lattice vectors.
  //
  // requirement on the matrices
  // 1) matrix with elements {-1,0,1} and determinant one
  // 2) each matrix individually has to produce matrices exclusively with elements {-1,0,1}
  // 3) each matrix has to correspond to a two-fold
  //
  // Note: any crystal lattice has a center of inversion
  // We can work with the acentric subgroup of the highest symmetry and add the center of inversion at the end of the procedure.
  
  static let twoFoldSymmetryOperations: [(rotationMatrix: SKRotationMatrix, axisDirect: SIMD3<Int32>, axisReciprocal: SIMD3<Int32>)] =
  [
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(-1, 0, 1), SIMD3<Int32>(-1, 1, 0)]) , axisDirect: SIMD3<Int32>(-1, 1, 1) , axisReciprocal: SIMD3<Int32>(0, 1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(-1, 1, -1), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(1, -2, 1) , axisReciprocal: SIMD3<Int32>(0, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(-1, 1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(-1, 2, 0) , axisReciprocal: SIMD3<Int32>(0, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(-1, 1, 1), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(-1, 2, 1) , axisReciprocal: SIMD3<Int32>(0, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(-1, 0, -1), SIMD3<Int32>(1, -1, 0)]) , axisDirect: SIMD3<Int32>(1, -1, 1) , axisReciprocal: SIMD3<Int32>(0, -1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(-1, -1, 1)]) , axisDirect: SIMD3<Int32>(-1, -1, 2) , axisReciprocal: SIMD3<Int32>(0, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(-1, 0, 1)]) , axisDirect: SIMD3<Int32>(-1, 0, 2) , axisReciprocal: SIMD3<Int32>(0, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(-1, 1, 1)]) , axisDirect: SIMD3<Int32>(-1, 1, 2) , axisReciprocal: SIMD3<Int32>(0, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, -1, 1), SIMD3<Int32>(0, 0, -1), SIMD3<Int32>(0, -1, 0)]) , axisDirect: SIMD3<Int32>(0, -1, 1) , axisReciprocal: SIMD3<Int32>(1, -1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, -1, -1), SIMD3<Int32>(0, 0, 1), SIMD3<Int32>(0, 1, 0)]) , axisDirect: SIMD3<Int32>(0, 1, 1) , axisReciprocal: SIMD3<Int32>(-1, 1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, -1, 0), SIMD3<Int32>(0, 1, 0), SIMD3<Int32>(0, -1, -1)]) , axisDirect: SIMD3<Int32>(0, 1, 0) , axisReciprocal: SIMD3<Int32>(1, -2, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, -1, 0), SIMD3<Int32>(0, 1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(0, 1, 0) , axisReciprocal: SIMD3<Int32>(-1, 2, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, -1, 0), SIMD3<Int32>(0, 1, 0), SIMD3<Int32>(0, 1, -1)]) , axisDirect: SIMD3<Int32>(0, 1, 0) , axisReciprocal: SIMD3<Int32>(-1, 2, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(0, -1, 1)]) , axisDirect: SIMD3<Int32>(0, -1, 2) , axisReciprocal: SIMD3<Int32>(0, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, -1), SIMD3<Int32>(0, -1, -1), SIMD3<Int32>(0, 0, 1)]) , axisDirect: SIMD3<Int32>(0, 0, 1) , axisReciprocal: SIMD3<Int32>(-1, -1, 2)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, -1), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(0, 0, 1)]) , axisDirect: SIMD3<Int32>(0, 0, 1) , axisReciprocal: SIMD3<Int32>(-1, 0, 2)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, -1), SIMD3<Int32>(0, -1, 1), SIMD3<Int32>(0, 0, 1)]) , axisDirect: SIMD3<Int32>(0, 0, 1) , axisReciprocal: SIMD3<Int32>(-1, 1, 2)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, -1, -1), SIMD3<Int32>(0, 0, 1)]) , axisDirect: SIMD3<Int32>(0, 0, 1) , axisReciprocal: SIMD3<Int32>(0, -1, 2)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(0, 0, 1)]) , axisDirect: SIMD3<Int32>(0, 0, 1) , axisReciprocal: SIMD3<Int32>(0, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, -1, 1), SIMD3<Int32>(0, 0, 1)]) , axisDirect: SIMD3<Int32>(0, 0, 1) , axisReciprocal: SIMD3<Int32>(0, 1, 2)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 1), SIMD3<Int32>(0, -1, -1), SIMD3<Int32>(0, 0, 1)]) , axisDirect: SIMD3<Int32>(0, 0, 1) , axisReciprocal: SIMD3<Int32>(1, -1, 2)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 1), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(0, 0, 1)]) , axisDirect: SIMD3<Int32>(0, 0, 1) , axisReciprocal: SIMD3<Int32>(1, 0, 2)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 1), SIMD3<Int32>(0, -1, 1), SIMD3<Int32>(0, 0, 1)]) , axisDirect: SIMD3<Int32>(0, 0, 1) , axisReciprocal: SIMD3<Int32>(1, 1, 2)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(0, 1, 1)]) , axisDirect: SIMD3<Int32>(0, 1, 2) , axisReciprocal: SIMD3<Int32>(0, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, 0, -1), SIMD3<Int32>(0, -1, 0)]) , axisDirect: SIMD3<Int32>(0, -1, 1) , axisReciprocal: SIMD3<Int32>(0, -1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, 0, 1), SIMD3<Int32>(0, 1, 0)]) , axisDirect: SIMD3<Int32>(0, 1, 1) , axisReciprocal: SIMD3<Int32>(0, 1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, 1, 0), SIMD3<Int32>(0, -1, -1)]) , axisDirect: SIMD3<Int32>(0, 1, 0) , axisReciprocal: SIMD3<Int32>(0, -2, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, 1, -1), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(0, -2, 1) , axisReciprocal: SIMD3<Int32>(0, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, 1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(0, 1, 0) , axisReciprocal: SIMD3<Int32>(0, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, 1, 1), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(0, 2, 1) , axisReciprocal: SIMD3<Int32>(0, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, 1, 0), SIMD3<Int32>(0, 1, -1)]) , axisDirect: SIMD3<Int32>(0, 1, 0) , axisReciprocal: SIMD3<Int32>(0, 2, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 1, -1), SIMD3<Int32>(0, 0, -1), SIMD3<Int32>(0, -1, 0)]) , axisDirect: SIMD3<Int32>(0, -1, 1) , axisReciprocal: SIMD3<Int32>(-1, -1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 1, 1), SIMD3<Int32>(0, 0, 1), SIMD3<Int32>(0, 1, 0)]) , axisDirect: SIMD3<Int32>(0, 1, 1) , axisReciprocal: SIMD3<Int32>(1, 1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 1, 0), SIMD3<Int32>(0, 1, 0), SIMD3<Int32>(0, -1, -1)]) , axisDirect: SIMD3<Int32>(0, 1, 0) , axisReciprocal: SIMD3<Int32>(-1, -2, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 1, 0), SIMD3<Int32>(0, 1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(0, 1, 0) , axisReciprocal: SIMD3<Int32>(1, 2, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 1, 0), SIMD3<Int32>(0, 1, 0), SIMD3<Int32>(0, 1, -1)]) , axisDirect: SIMD3<Int32>(0, 1, 0) , axisReciprocal: SIMD3<Int32>(1, 2, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(1, -1, 1)]) , axisDirect: SIMD3<Int32>(1, -1, 2) , axisReciprocal: SIMD3<Int32>(0, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(1, 0, 1)]) , axisDirect: SIMD3<Int32>(1, 0, 2) , axisReciprocal: SIMD3<Int32>(0, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(1, 1, 1)]) , axisDirect: SIMD3<Int32>(1, 1, 2) , axisReciprocal: SIMD3<Int32>(0, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(1, 0, -1), SIMD3<Int32>(-1, -1, 0)]) , axisDirect: SIMD3<Int32>(-1, -1, 1) , axisReciprocal: SIMD3<Int32>(0, -1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(1, 1, -1), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(-1, -2, 1) , axisReciprocal: SIMD3<Int32>(0, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(1, 1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(1, 2, 0) , axisReciprocal: SIMD3<Int32>(0, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(1, 1, 1), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(1, 2, 1) , axisReciprocal: SIMD3<Int32>(0, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(1, 0, 1), SIMD3<Int32>(1, 1, 0)]) , axisDirect: SIMD3<Int32>(1, 1, 1) , axisReciprocal: SIMD3<Int32>(0, 1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(-1, 1, -1)]) , axisDirect: SIMD3<Int32>(-1, 1, 0) , axisReciprocal: SIMD3<Int32>(-1, 1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, 0, -1), SIMD3<Int32>(-1, -1, 1), SIMD3<Int32>(-1, 0, 0)]) , axisDirect: SIMD3<Int32>(-1, 0, 1) , axisReciprocal: SIMD3<Int32>(-1, 1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, -1, -1), SIMD3<Int32>(-1, 0, 1), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(-1, 1, 1) , axisReciprocal: SIMD3<Int32>(-1, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(-1, 1, 0) , axisReciprocal: SIMD3<Int32>(-1, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, -1, 1), SIMD3<Int32>(-1, 0, -1), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(1, -1, 1) , axisReciprocal: SIMD3<Int32>(-1, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(-1, 0, 0), SIMD3<Int32>(1, -1, -1)]) , axisDirect: SIMD3<Int32>(-1, 1, 0) , axisReciprocal: SIMD3<Int32>(1, -1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, 0, 1), SIMD3<Int32>(-1, -1, -1), SIMD3<Int32>(1, 0, 0)]) , axisDirect: SIMD3<Int32>(1, 0, 1) , axisReciprocal: SIMD3<Int32>(1, -1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, -1, -1), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(-1, 1, 0)]) , axisDirect: SIMD3<Int32>(-1, 1, 1) , axisReciprocal: SIMD3<Int32>(-1, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, 0, -1), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(-1, 0, 0)]) , axisDirect: SIMD3<Int32>(-1, 0, 1) , axisReciprocal: SIMD3<Int32>(-1, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, 1, -1), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(-1, -1, 0)]) , axisDirect: SIMD3<Int32>(-1, -1, 1) , axisReciprocal: SIMD3<Int32>(-1, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, -1, 1), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(1, -1, 0)]) , axisDirect: SIMD3<Int32>(1, -1, 1) , axisReciprocal: SIMD3<Int32>(1, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, 0, 1), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(1, 0, 0)]) , axisDirect: SIMD3<Int32>(1, 0, 1) , axisReciprocal: SIMD3<Int32>(1, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, 1, 1), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(1, 1, 0)]) , axisDirect: SIMD3<Int32>(1, 1, 1) , axisReciprocal: SIMD3<Int32>(1, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, 0, -1), SIMD3<Int32>(1, -1, -1), SIMD3<Int32>(-1, 0, 0)]) , axisDirect: SIMD3<Int32>(-1, 0, 1) , axisReciprocal: SIMD3<Int32>(-1, -1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, 1, 0), SIMD3<Int32>(1, 0, 0), SIMD3<Int32>(-1, -1, -1)]) , axisDirect: SIMD3<Int32>(1, 1, 0) , axisReciprocal: SIMD3<Int32>(-1, -1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, 1, -1), SIMD3<Int32>(1, 0, -1), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(-1, -1, 1) , axisReciprocal: SIMD3<Int32>(1, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, 1, 0), SIMD3<Int32>(1, 0, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(1, 1, 0) , axisReciprocal: SIMD3<Int32>(1, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, 1, 1), SIMD3<Int32>(1, 0, 1), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(1, 1, 1) , axisReciprocal: SIMD3<Int32>(1, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, 0, 1), SIMD3<Int32>(1, -1, 1), SIMD3<Int32>(1, 0, 0)]) , axisDirect: SIMD3<Int32>(1, 0, 1) , axisReciprocal: SIMD3<Int32>(1, 1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(0, 1, 0), SIMD3<Int32>(1, 0, 0), SIMD3<Int32>(1, 1, -1)]) , axisDirect: SIMD3<Int32>(1, 1, 0) , axisReciprocal: SIMD3<Int32>(1, 1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, 0, 0), SIMD3<Int32>(-1, -1, 0), SIMD3<Int32>(-1, 0, -1)]) , axisDirect: SIMD3<Int32>(1, 0, 0) , axisReciprocal: SIMD3<Int32>(-2, 1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, 0, 0), SIMD3<Int32>(-1, -1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(1, 0, 0) , axisReciprocal: SIMD3<Int32>(-2, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, 0, 0), SIMD3<Int32>(-1, -1, 0), SIMD3<Int32>(1, 0, -1)]) , axisDirect: SIMD3<Int32>(1, 0, 0) , axisReciprocal: SIMD3<Int32>(2, -1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, 0, 0), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(-1, 0, -1)]) , axisDirect: SIMD3<Int32>(1, 0, 0) , axisReciprocal: SIMD3<Int32>(-2, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, -1, -1), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(-2, 1, 1) , axisReciprocal: SIMD3<Int32>(1, 0, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, -1, 0), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(-2, 1, 0) , axisReciprocal: SIMD3<Int32>(1, 0, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, -1, 1), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(2, -1, 1) , axisReciprocal: SIMD3<Int32>(1, 0, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, 0, -1), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(-2, 0, 1) , axisReciprocal: SIMD3<Int32>(1, 0, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, 0, 0), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(1, 0, 0) , axisReciprocal: SIMD3<Int32>(1, 0, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, 0, 1), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(2, 0, 1) , axisReciprocal: SIMD3<Int32>(1, 0, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, 1, -1), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(-2, -1, 1) , axisReciprocal: SIMD3<Int32>(1, 0, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, 1, 0), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(2, 1, 0) , axisReciprocal: SIMD3<Int32>(1, 0, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, 1, 1), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(2, 1, 1) , axisReciprocal: SIMD3<Int32>(1, 0, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, 0, 0), SIMD3<Int32>(0, -1, 0), SIMD3<Int32>(1, 0, -1)]) , axisDirect: SIMD3<Int32>(1, 0, 0) , axisReciprocal: SIMD3<Int32>(2, 0, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, 0, 0), SIMD3<Int32>(1, -1, 0), SIMD3<Int32>(-1, 0, -1)]) , axisDirect: SIMD3<Int32>(1, 0, 0) , axisReciprocal: SIMD3<Int32>(-2, -1, 1)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, 0, 0), SIMD3<Int32>(1, -1, 0), SIMD3<Int32>(0, 0, -1)]) , axisDirect: SIMD3<Int32>(1, 0, 0) , axisReciprocal: SIMD3<Int32>(2, 1, 0)),
    (rotationMatrix: SKRotationMatrix([SIMD3<Int32>(1, 0, 0), SIMD3<Int32>(1, -1, 0), SIMD3<Int32>(1, 0, -1)]) , axisDirect: SIMD3<Int32>(1, 0, 0) , axisReciprocal: SIMD3<Int32>(2, 1, 1))
  ]
}

extension SKRotationMatrix: Hashable
{
  public func hash(into hasher: inout Hasher)
  {
    hasher.combine(self[0,0])
    hasher.combine(self[0,1])
    hasher.combine(self[0,2])
    hasher.combine(self[1,0])
    hasher.combine(self[1,1])
    hasher.combine(self[1,2])
    hasher.combine(self[2,0])
    hasher.combine(self[2,1])
    hasher.combine(self[2,2])
  }
}
 
extension SKRotationMatrix
{
  public static func ==(left: SKRotationMatrix, right: SKRotationMatrix) -> Bool
  {
    return (left[0,0] == right[0,0]) && (left[0,1] == right[0,1]) && (left[0,2] == right[0,2]) &&
           (left[1,0] == right[1,0]) && (left[1,1] == right[1,1]) && (left[1,2] == right[1,2]) &&
           (left[2,0] == right[2,0]) && (left[2,1] == right[2,1]) && (left[2,2] == right[2,2])
  }
  
  public static func * (left: SKRotationMatrix, right: SKRotationMatrix) -> SKRotationMatrix
  {
    return SKRotationMatrix([ SIMD3<Int32>(left[0,0] * right[0,0] + left[1,0] * right[0,1] + left[2,0] * right[0,2],
                        left[0,1] * right[0,0] + left[1,1] * right[0,1] + left[2,1] * right[0,2],
                        left[0,2] * right[0,0] + left[1,2] * right[0,1] + left[2,2] * right[0,2]),
                    SIMD3<Int32>(left[0,0] * right[1,0] + left[1,0] * right[1,1] + left[2,0] * right[1,2],
                        left[0,1] * right[1,0] + left[1,1] * right[1,1] + left[2,1] * right[1,2],
                        left[0,2] * right[1,0] + left[1,2] * right[1,1] + left[2,2] * right[1,2]),
                    SIMD3<Int32>(left[0,0] * right[2,0] + left[1,0] * right[2,1] + left[2,0] * right[2,2],
                        left[0,1] * right[2,0] + left[1,1] * right[2,1] + left[2,1] * right[2,2],
                        left[0,2] * right[2,0] + left[1,2] * right[2,1] + left[2,2] * right[2,2])])
  }
  
  public static func *= (left: inout SKRotationMatrix, right: SKRotationMatrix)
  {
    left = left * right
  }
  
  public static func * (left: SKRotationMatrix, right: double3x3) -> double3x3
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
  
  public static func *(left: double3x3, right: SKRotationMatrix) -> double3x3
  {
    let term1: SIMD3<Double> = SIMD3<Double>(left[0,0] * Double(right[0,0]) + left[1,0] * Double(right[0,1]) + left[2,0] * Double(right[0,2]),
                                 left[0,1] * Double(right[0,0]) + left[1,1] * Double(right[0,1]) + left[2,1] * Double(right[0,2]),
                                 left[0,2] * Double(right[0,0]) + left[1,2] * Double(right[0,1]) + left[2,2] * Double(right[0,2]))
    let term2: SIMD3<Double> = SIMD3<Double>(left[0,0] * Double(right[1,0]) + left[1,0] * Double(right[1,1]) + left[2,0] * Double(right[1,2]),
                                 left[0,1] * Double(right[1,0]) + left[1,1] * Double(right[1,1]) + left[2,1] * Double(right[1,2]),
                                 left[0,2] * Double(right[1,0]) + left[1,2] * Double(right[1,1]) + left[2,2] * Double(right[1,2]))
    let term3: SIMD3<Double> = SIMD3<Double>(left[0,0] * Double(right[2,0]) + left[1,0] * Double(right[2,1]) + left[2,0] * Double(right[2,2]),
                                 left[0,1] * Double(right[2,0]) + left[1,1] * Double(right[2,1]) + left[2,1] * Double(right[2,2]),
                                 left[0,2] * Double(right[2,0]) + left[1,2] * Double(right[2,1]) + left[2,2] * Double(right[2,2]))
    return double3x3([term1, term2, term3])
  }
  
  public static func * (left: SKRotationMatrix, right: SIMD3<Int32>) -> SIMD3<Int32>
  {
    return SIMD3<Int32>(x: left[0,0] * right.x + left[1,0] * right.y + left[2,0] * right.z,
                y: left[0,1] * right.x + left[1,1] * right.y + left[2,1] * right.z,
                z: left[0,2] * right.x + left[1,2] * right.y + left[2,2] * right.z)
  }
  
  public static func * (left: SKRotationMatrix, right: SIMD3<Double>) -> SIMD3<Double>
  {
    return SIMD3<Double>(x: Double(left[0,0]) * right.x + Double(left[1,0]) * right.y + Double(left[2,0]) * right.z,
                         y: Double(left[0,1]) * right.x + Double(left[1,1]) * right.y + Double(left[2,1]) * right.z,
                         z: Double(left[0,2]) * right.x + Double(left[1,2]) * right.y + Double(left[2,2]) * right.z)
  }
  
  static public func + (left: SKRotationMatrix, right: SKRotationMatrix) -> SKRotationMatrix
  {
    return SKRotationMatrix([SIMD3<Int32>(x: left[0,0] + right[0,0], y: left[0,1] + right[0,1], z: left[0,2] + right[0,2]),
                   SIMD3<Int32>(x: left[1,0] + right[1,0], y: left[1,1] + right[1,1], z: left[1,2] + right[1,2]),
                   SIMD3<Int32>(x: left[2,0] + right[2,0], y: left[2,1] + right[2,1], z: left[2,2] + right[2,2])])
  }
  
  static public func - (left: SKRotationMatrix, right: SKRotationMatrix) -> SKRotationMatrix
  {
    return SKRotationMatrix([SIMD3<Int32>(x: left[0,0] - right[0,0], y: left[0,1] - right[0,1], z: left[0,2] - right[0,2]),
                   SIMD3<Int32>(x: left[1,0] - right[1,0], y: left[1,1] - right[1,1], z: left[1,2] - right[1,2]),
                   SIMD3<Int32>(x: left[2,0] - right[2,0], y: left[2,1] - right[2,1], z: left[2,2] - right[2,2])])
  }
  
  public static prefix func - (left: SKRotationMatrix) -> SKRotationMatrix
  {
    return SKRotationMatrix([SIMD3<Int32>(-left[0,0], -left[0,1], -left[0,2]),
                   SIMD3<Int32>(-left[1,0], -left[1,1], -left[1,2]),
                   SIMD3<Int32>(-left[2,0], -left[2,1], -left[2,2])])
  }
  
  public static func / (left: SKRotationMatrix, right: Int) -> SKRotationMatrix
  {
    return SKRotationMatrix([SIMD3<Int32>(left[0,0] / Int32(right), left[0,1] / Int32(right), left[0,2] / Int32(right)),
                   SIMD3<Int32>(left[1,0] / Int32(right), left[1,1] / Int32(right), left[1,2] / Int32(right)),
                   SIMD3<Int32>(left[2,0] / Int32(right), left[2,1] / Int32(right), left[2,2] / Int32(right))])
  }
}

