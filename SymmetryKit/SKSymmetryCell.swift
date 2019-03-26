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
import Cocoa
import simd
import MathKit

//#define epsilon 2.44521858065e-05

// Specifically, a point X in a crystal is defined with respect to the basis vectors a, b, c and the origin O by the coordinates x, y, z, i.e. the position vector r of point X is given by
// r = x*a + y*b + z*c = (a,b,c).(x,y,z)^T
//     (a1,b1,c1) (x)
// r = (a2,b2,c2).(y)
//     (a3,b3,c3) (z)
//
// The metric matrix G of the unit cell in the direct lattice:
//      (a.a,a.b,a.c)
//  G = (b.a,b.b,b.c)
//      (c.a,c.b,c.c)
// The volume V^2=determinant(G)
//
// Bravais lattices: 7 primitive ones and 7 centered lattice divided into: 1) body-centerd 'I', 2) base-centred 'A', 'B', 'C', and 3) face-centered 'F'
//
// primitive Bravais lattices (index P)
// body-centered (index I): one additional point at the center of the unit cell
// base-centered (indices A, B, C): additional points at the centers of two parallel sides of the unit cell
// face-centered (index F): additional points at the centers of each face of the unit cell
//
// primitive lattice:                                    number of points in the unit cell
// ==================
// primitive (aP)                        P-1      2      1
//
// Monoclinic:
// ===========
// primitive (mP)                        P2/m    10      1
// base-centered (mS: mA,mB,mC,mI)       C2/m    12      2
//
// Orthorhombic:
// =============
// primitive (oP)                        Pmmm    47      1
// base-centered (oS: oA,oB,oC)          Cmmm    65      2
// body-centered (oI)                    Immm    71      2
// face-centered (oF)                    Fmmm    69      4
//
// tetragonal:
// ===========
// primitive (tP)                        P4/mmm 123      1
// body-centered (tI)                    I4/mmm 139      2
//
// Rhombohedral
// ============
// primitive (hR)                        R-3m   166      3
//
// Hexagonal
// =========
// base-centered (hP)                    P6/mmm 192      1
//
// Cubic:
// =======
// primitive (cP)                        Pm-3m  221      1
// body-centered (cI)                    Im-3m  229      2
// base-centered (cF)                    Fm-3m  225      4


// Swapping any two axis changes the handedness of the cell
// A cyclic rotation (abc  becomes bca or the reverse cab) maintains handedness
// Multiplying an axis by -1 changes the angles involving that axis to 180º-angle


// R.W. Kunstleve et al. "The Computational Crystallography Toolbox: crystallographic algorithms in a reusable software framework", J. Appl. Cryst., 35, 126-136, 2002.
// Test if given unit-cell parameters are compatible with the symmetry operations. A given unit cell is compatible with a given space-group representation if
// the following relation holds for all rotation matrices R of the space group:  R^T.G.R = G where G is the metrical matrix of the unit cell.

// Both the hexagonal (with 6-fold symmetry) and the trigonal (with 3-fold symmetry) systems
// require a hexagonal axial system (a=b!=c, alpha=beta=90, gamma=120).
// Convention: 6-fold axis of the lattice parallel to the c-axis.
// Trigonal is often considered a subset of hexagonal. The trigonal system does, however, have
// a unique feature: the smallest primitive cell may be chosen with a=b=c, alpha=beta=gamma!=90.
// The unique axis, along which the 3-fold symmetry axis lies, is now one of the body diagonals of the cell.
// It is mathematically convenient to transform this cell to one which is centered at the points 1/3, 2/3, 2/3 and 2/3, 1/3,1/3
//  and is thus three times as large, but has the shape of the conventional hexagonal cell, with the c-axis
// as the unique axis. This is called the "obverse" setting of a rhombohedral unit cell, and is the
// standard setting for the rhombohedral system. Rotating the 'a'- and 'b'-axes by 60 degrees
// about 'c' gives the alternative "reverse" setting. The lattice is now centered at the points
// 1/3, 2/3, 1/3 and 2/3, 1/3, 2/3. Lattices which have rhombohedral centering are given with the symbol 'R'.

public struct SKSymmetryCell: CustomStringConvertible
{
  public var a: Double
  public var b: Double
  public var c: Double
  public var alpha: Double
  public var beta: Double
  public var gamma: Double
  
  // Taken from: Table 2.C.1, page 141, Fundamentals of Crystallography, 2nd edition, C. Giacovazzo et al. 2002
  // Tranformation matrices M, conventionally used to generate centered from primitive lattices, and vice versa, accoording to: A' = M A
  
  public static let primitiveToPrimitive: int3x3 = int3x3([int3( 1, 0, 0), int3( 0, 1, 0), int3( 0, 0, 1)])  // P -> P
  
  public static let bodyCenteredToPrimitive: MKint3x3 = MKint3x3([int3(-1,1,1), int3(1,-1,1), int3(1,1,-1)], denominator: 2)  // I -> P
  public static let primitiveToBodyCentered: int3x3 = int3x3([int3(0,1,1), int3(1,0,1), int3(1,1,0)])  // P -> I
  
  public static let faceCenteredToPrimitive: MKint3x3 = MKint3x3([int3(0,1,1), int3(1,0,1), int3(1,1,0)], denominator: 2)   // F -> P
  public static let primitiveToFaceCentered: int3x3 = int3x3([int3(-1,1,1), int3(1,-1,1), int3(1,1,-1)])  // P -> F
  
  public static let ACenteredToPrimitive: MKint3x3 = MKint3x3([int3(-2,0,0), int3(0,-1,1), int3(0,1,1)], denominator: 2)   // A -> P
  public static let primitiveToACentered: int3x3 = int3x3([int3(-1,0,0), int3(0,-1,1), int3(0,1,1)])  // P -> A
  
  public static let BCenteredToPrimitive: MKint3x3 = MKint3x3([int3(-1,0,1), int3(0,-2,0), int3(1,0,1)], denominator: 2)   // B -> P
  public static let primitiveToBCentered: int3x3 = int3x3([int3(-1,0,1), int3(0,-1,0), int3(1,0,1)])  // P -> B
  
  public static let CCenteredToPrimitive: MKint3x3 = MKint3x3([int3(1,1,0), int3(1,-1,0), int3(0,0,-2)], denominator: 2)   // C -> P
  public static let primitiveToCCentered: int3x3 = int3x3([int3(1, 1,0), int3(1,-1,0), int3(0,0,-1)])  // P -> C
  
  public static let rhombohedralToPrimitive: MKint3x3 = MKint3x3([int3(2,1,1), int3(-1, 1, 1), int3(-1,-2, 1)], denominator: 3)  // R -> P
  public static let primitiveToRhombohedral: int3x3 = int3x3([int3( 1,-1, 0), int3( 0, 1,-1), int3( 1, 1, 1)])  // P -> R
  
  public static let hexagonalToPrimitive: MKint3x3 = MKint3x3([int3( 2,1, 0), int3(-1, 1, 0), int3( 0, 0, 1)], denominator: 3)  // H -> P
  public static let primitiveToHexagonal: int3x3 = int3x3([int3( 1,-1, 0), int3( 1, 2, 0), int3( 0, 0, 1)])  // P -> H
  
  
  public static let rhombohedralHexagonalToObverse: double3x3 = double3x3([double3(2.0/3.0,-1.0/3.0,-1.0/3.0),double3(1.0/3.0,1.0/3.0,-2.0/3.0),double3(1.0/3.0,1.0/3.0,1.0/3.0)])   // Rh -> Robv
  public static let rhombohedralObverseHexagonal: int3x3 = int3x3([int3(1,0,1), int3(-1,1,1), int3(0,-1,1)])  // Robv -> Rh
  
  public static let rhombohedralHexagonalToReverse: int3x3 = int3x3([int3(1,1,-2),int3(-1,0,1),int3(1,1,-1)])   // Rh -> Rrev
  public static let rhombohedralReverseToHexagonal: int3x3 = int3x3([int3(-1,-1,1), int3(0,1,1), int3(-1,0,1)])  // Rrev -> Rh
  
  var epsilon: Double
  {
    get
    {
      return 1.0e-5
      //return pow(volume,1.0/3.0) * 1.0e-5
    }
  }
  
  public var description: String
  {
    get
    {
      return "lengths: \(a), \(b), \(c), angles: \(alpha*180.0/Double.pi), \(beta*180.0/Double.pi), \(gamma*180.0/Double.pi)"
    }
  }
  
  public init(a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)
  {
    self.a = a
    self.b = b
    self.c = c
    self.alpha = alpha * Double.pi/180.0
    self.beta = beta * Double.pi/180.0
    self.gamma = gamma * Double.pi/180.0
  }
  
  public init(unitCell: double3x3)
  {
    let column1: double3 = unitCell[0]
    let column2: double3 = unitCell[1]
    let column3: double3 = unitCell[2]
    let length1: Double = length(column1)
    let length2: Double = length(column2)
    let length3: Double = length(column3)
    
    self.a = length1
    self.b = length2
    self.c = length3
    self.alpha = acos(dot(column2, column3) / (length2 * length3))
    self.beta = acos(dot(column1, column3) / (length1 * length3))
    self.gamma = acos(dot(column1, column2) / (length1 * length2))
  }
  
  public init(metricTensor: double3x3)
  {
    let A: Double = metricTensor[0][0]
    let B: Double = metricTensor[1][1]
    let C: Double = metricTensor[2][2]
    
    self.a = sqrt(A)
    self.b = sqrt(B)
    self.c = sqrt(C)
    self.alpha = acos(metricTensor[1][2]/(sqrt(B)*sqrt(C)))
    self.beta = acos(metricTensor[0][2]/(sqrt(A)*sqrt(C)))
    self.gamma = acos(metricTensor[0][1]/(sqrt(A)*sqrt(B)))
  }
  
  public var unitCell: double3x3
  {
    let temp: Double = (cos(alpha) - cos(gamma) * cos(beta)) / sin(gamma)
    
    let v1: double3 = double3(x: a, y: 0.0, z: 0.0)
    let v2: double3 = double3(x: b * cos(gamma), y: b * sin(gamma), z: 0.0)
    let v3: double3 = double3(x: c * cos(beta), y: c * temp, z: c * sqrt(1.0 - cos(beta)*cos(beta)-temp*temp))
    return double3x3([v1, v2, v3])
  }
  
  public func conventionalUnitCell(spaceGroup: SKSpacegroup) -> double3x3
  {
    let holohedry: SKPointGroup.Holohedry = spaceGroup.spaceGroupSetting.pointGroup.holohedry
    
    switch(holohedry)
    {
    case .none:
      return double3x3()
    case .triclinic:
      let cg: Double = cos(gamma)
      let cb: Double = cos(beta)
      let ca: Double = cos(alpha)
      let sg: Double = sin(gamma)
      let temp: Double = c * sqrt(1.0 - ca * ca - cb * cb - cg * cg + 2.0 * ca * cb * cg) / sg
      return double3x3([double3(a,0.0,0.0),double3(b * cg,b * sg,0.0),double3(c * cb,c * (ca - cb * cg) / sg, temp)])
    case .monoclinic:
      return double3x3([double3(a,0.0,0.0),double3(0.0,b,0.0),double3(c * cos(beta),0.0,c * sin(beta))])
    case .orthorhombic:
      return double3x3([double3(a,0.0,0.0),double3(0.0,b,0.0),double3(0.0,0.0,c)])
    case .tetragonal:
      return double3x3([double3(0.5*(a+b),0.0,0.0),double3(0.0,0.5*(a+b),0.0),double3(0.0,0.0,c)])
    case .trigonal where spaceGroup.spaceGroupSetting.qualifier == "R":
      let avg: Double = (a+b+c)/3.0
      let angle: Double = acos((cos(gamma) + cos(beta) + cos(alpha)) / 3.0)
      // Reference, https://homepage.univie.ac.at/michael.leitner/lattice/struk/rgr.html
      let ahex: Double = 2.0 * avg * sin(0.5 * angle)
      let chex: Double = (a+b+c)/3.0 * sqrt(3.0 * (1.0 + 2.0 * cos(angle)))
      return  double3x3([double3(ahex / 2,-ahex / (2 * sqrt(3)),chex / 3),double3(0.0,ahex / sqrt(3),chex / 3),double3(-ahex / 2,-ahex / (2 * sqrt(3)),chex / 3)])
    case .trigonal where spaceGroup.spaceGroupSetting.qualifier != "R", .hexagonal:
      return double3x3([double3(0.5*(a+b),0.0,0.0),double3(-(a+b)/4.0,(a+b)/4.0*sqrt(3.0),0.0),double3(0.0,0.0,c)])
    case .cubic:
      let edge: Double = (a + b + c)/3.0
      return double3x3([double3(edge,0.0,0.0),double3(0.0,edge,0.0),double3(0.0,0.0,edge)])
    default:
      return double3x3()
    }
  }
  
  public static func TransformToConventionalUnitCell(unitCell: double3x3, spaceGroup: SKSpacegroup) -> double3x3
  {
    let metric: double3x3 = unitCell.transpose * unitCell
    var lattice: double3x3 = double3x3(diagonal: double3(0,0,0))
    
    let holohedry: SKPointGroup.Holohedry = spaceGroup.spaceGroupSetting.pointGroup.holohedry
    //Swift.print("holohedry \(holohedry) \(centering)")
    
    switch(holohedry)
    {
    case .none:
      return double3x3()
    case .triclinic:
      let a: Double = sqrt(metric[0][0])
      let b: Double = sqrt(metric[1][1])
      let c: Double = sqrt(metric[2][2])
      let alpha = acos(metric[1][2] / b / c)
      let beta = acos(metric[0][2] / a / c)
      let gamma = acos(metric[0][1] / a / b)
      
      let cg: Double = cos(gamma)
      let cb: Double = cos(beta)
      let ca: Double = cos(alpha)
      let sg: Double = sin(gamma)
      
      lattice[0][0] = a;
      lattice[0][1] = b * cg
      lattice[0][2] = c * cb
      lattice[1][1] = b * sg
      lattice[1][2] = c * (ca - cb * cg) / sg
      lattice[2][2] = c * sqrt(1 - ca * ca - cb * cb - cg * cg + 2 * ca * cb * cg) / sg
      return lattice
    case .monoclinic:
      let a: Double = sqrt(metric[0][0])
      let b: Double = sqrt(metric[1][1])
      let c: Double = sqrt(metric[2][2])
      lattice[0][0] = a
      lattice[1][1] = b
      let beta: Double = acos(metric[0][2] / a / c)
      lattice[0][2] = c * cos(beta)
      lattice[2][2] = c * sin(beta)
      return lattice
    case .orthorhombic:
      let a: Double = sqrt(metric[0][0])
      let b: Double = sqrt(metric[1][1])
      let c: Double = sqrt(metric[2][2])
      lattice[0][0] = a
      lattice[1][1] = b
      lattice[2][2] = c
      return lattice
    case .tetragonal:
      let a: Double = sqrt(metric[0][0])
      let b: Double = sqrt(metric[1][1])
      let c: Double = sqrt(metric[2][2])
      lattice[0][0] = (a + b) / 2
      lattice[1][1] = (a + b) / 2
      lattice[2][2] = c
      return lattice
    case .trigonal where spaceGroup.spaceGroupSetting.qualifier == "R":
      let a: Double = sqrt(metric[0][0])
      let b: Double = sqrt(metric[1][1])
      let c: Double = sqrt(metric[2][2])
      let angle: Double = acos((metric[0][1] / a / b + metric[0][2] / a / c + metric[1][2] / b / c) / 3)
      let ahex: Double = 2 * (a+b+c)/3 * sin(angle / 2)
      let chex: Double = (a+b+c)/3 * sqrt(3 * (1 + 2 * cos(angle)))
      lattice[0][0] = ahex / 2
      lattice[1][0] = -ahex / (2 * sqrt(3))
      lattice[2][0] = chex / 3
      lattice[1][1] = ahex / sqrt(3)
      lattice[2][1] = chex / 3
      lattice[0][2] = -ahex / 2
      lattice[1][2] = -ahex / (2 * sqrt(3))
      lattice[2][2] = chex / 3
      return lattice
    case .trigonal where spaceGroup.spaceGroupSetting.qualifier != "R", .hexagonal:
      let a: Double = sqrt(metric[0][0])
      let b: Double = sqrt(metric[1][1])
      let c: Double = sqrt(metric[2][2])
      lattice[0][0] = (a + b) / 2
      lattice[0][1] = -(a + b) / 4
      lattice[1][1] = (a + b) / 4 * sqrt(3)
      lattice[2][2] = c
      return lattice
    case .cubic:
      let a: Double = sqrt(metric[0][0])
      let b: Double = sqrt(metric[1][1])
      let c: Double = sqrt(metric[2][2])
      lattice[0][0] = (a + b + c) / 3
      lattice[1][1] = (a + b + c) / 3
      lattice[2][2] = (a + b + c) / 3
      return lattice
    default:
      return double3x3()
    }
    
  }
  
  func isSmallerThen(x: Double, y: Double) -> Bool
  {
    return x < (y - epsilon)
  }
  
  func isLargerThen(x: Double, y: Double) -> Bool
  {
    return isSmallerThen(x: y, y: x)
  }
  
  func isSmallerEqualThen(x: Double, y: Double) -> Bool
  {
    return !(y < (x - epsilon))
  }
  
  func isLargerEqualThen(x: Double, y: Double) -> Bool
  {
    return !(x < (y - epsilon))
  }
  
  func isEqualTo(x: Double, y: Double) -> Bool
  {
    return !((x < (y - epsilon)) || (y < (x - epsilon)))
  }
  
  func isLargerThenZeroXiEtaZeta(x xi: Double, y eta: Double, z zeta: Double) -> Bool
  {
    var n_positive: Int = 0
    var n_zero: Int = 0
    
    if(isSmallerThen(x: 0, y: xi)) {n_positive += 1}
    else if(!isSmallerThen(x: xi, y: 0)) {n_zero+=1}
    
    if(isSmallerThen(x: 0, y: eta)) {n_positive += 1}
    else if(!isSmallerThen(x: eta, y: 0)) {n_zero+=1}
    
    if(isSmallerThen(x: 0, y: zeta)) {n_positive += 1}
    else if(!isSmallerThen(x: zeta, y: 0)) {n_zero+=1}
    
    return ((n_positive == 3) || (n_zero == 0 && n_positive == 1))
    
  }
  
  public var cell: double3x3
  {
    get
    {
      let temp: Double = (cos(alpha) - cos(gamma) * cos(beta)) / sin(gamma)
      
      let v1: double3 = double3(x: a, y: 0.0, z: 0.0)
      let v2: double3 = double3(x: b * cos(gamma), y: b * sin(gamma), z: 0.0)
      let v3: double3 = double3(x: c * cos(beta), y: c * temp, z: c * sqrt(1.0 - cos(beta)*cos(beta)-temp*temp))
      return double3x3([v1, v2, v3])
    }
  }
  
  public static func angles(cell: double3x3) -> (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)
  {
    let column1: double3 = cell[0]
    let column2: double3 = cell[1]
    let column3: double3 = cell[2]
    let length1: Double = length(column1)
    let length2: Double = length(column2)
    let length3: Double = length(column3)
    
    return (length1,length2,length3,
            acos(dot(column2, column3) / (length2 * length3)),
            acos(dot(column1, column3) / (length1 * length3)),
            acos(dot(column1, column2) / (length1 * length2)))
  }
  
  
  public var metricTensor: double3x3
  {
    let half_xi: Double = b*c*cos(alpha)
    let half_eta: Double = a*c*cos(beta)
    let half_zeta: Double = a*b*cos(gamma)
    
    let v1: double3 = double3(a*a, half_zeta, half_eta)
    let v2: double3 = double3(half_zeta, b*b, half_xi)
    let v3: double3 = double3(half_eta, half_xi, c*c)
    return double3x3([v1, v2, v3])
  }
  
  var volume: Double
  {
    get
    {
      let cosAlpha: Double = cos(alpha)
      let cosBeta: Double = cos(beta)
      let cosGamma: Double = cos(gamma)
      let temp: Double = 1.0 - cosAlpha*cosAlpha - cosBeta*cosBeta - cosGamma*cosGamma + 2.0 * cosAlpha * cosBeta * cosGamma
      return  a * b * c * sqrt(temp)
    }
  }
  
  
  
  private static func DelaunayReduceBasis(extendedBasis: inout double4x3, symmetryPrecision: Double = 1e-5) -> Bool
  {
    
    for i in 0..<4
    {
      for j in i+1..<4
      {
        let dotProduct: Double = dot(extendedBasis[i], extendedBasis[j])
        if (dotProduct > symmetryPrecision)
        {
          for k in 0..<4
          {
            if !(k == i || k == j)
            {
              extendedBasis[k] = extendedBasis[k] + extendedBasis[i]
            }
          }
          
          extendedBasis[i] = -extendedBasis[i]
          return false
        }
      }
    }
    
    return true
  }
  
  private static func getDelaunayShortestVectors(extendedBasis: double4x3, symmetryPrecision: Double = 1e-5) -> double3x3
  {
    var b: [double3] = [double3](repeatElement(double3(), count: 7))
    
    
    // Search in the set {b1, b2, b3, b4, b1+b2, b2+b3, b3+b1}
    for i in 0..<4
    {
      b[i] = extendedBasis[i]
    }
    
    b[4] = extendedBasis[0] + extendedBasis[1]
    b[5] = extendedBasis[1] + extendedBasis[2]
    b[6] = extendedBasis[2] + extendedBasis[0]
    
    // sort the vectors
    b.sort(by: {length_squared($0) < length_squared($1)})
    
    for i in 2..<7
    {
      
      let tmpMatrix: double3x3 = double3x3([b[0], b[1], b[i]])
      let volume: Double = tmpMatrix.determinant
      
      if (abs(volume) > symmetryPrecision)
      {
        return (volume > 0) ? tmpMatrix: -tmpMatrix
      }
    }
    
    return double3x3()
  }
  
  
  /// Compute the Delaunay reduced cell
  ///
  /// - parameter unitCell:          the original unit cell
  /// - parameter symmetryPrecision: the precision of the cell
  ///
  /// - returns: the Delaunay cell
  public static func computeDelaunayReducedCell(unitCell: double3x3, symmetryPrecision: Double = 1e-5) -> double3x3
  {
    let additionalBasisVector: double3 = double3(-unitCell[0][0] - unitCell[1][0] - unitCell[2][0],
                                                 -unitCell[0][1] - unitCell[1][1] - unitCell[2][1],
                                                 -unitCell[0][2] - unitCell[1][2] - unitCell[2][2])
    var extendedBasis: double4x3 = double4x3([unitCell[0],unitCell[1],unitCell[2],additionalBasisVector])
    
    while(true) { if DelaunayReduceBasis(extendedBasis: &extendedBasis) {break}}
    
    let basis: double3x3 = getDelaunayShortestVectors(extendedBasis: extendedBasis)
    
    return basis
  }
  
  
  private static func DelaunayReduceBasis2D(extendedBasis: inout double3x3, symmetryPrecision: Double = 1e-5) -> Bool
  {
    var dotProduct: Double
    
    for i in 0..<3
    {
      for j in (i + 1)..<3
      {
        dotProduct = dot(extendedBasis[i], extendedBasis[j])
        
        if (dotProduct > symmetryPrecision)
        {
          for k in 0..<3
          {
            if (!(k == i || k == j))
            {
              extendedBasis[k] = extendedBasis[k] + 2.0 * extendedBasis[i]
              break;
            }
          }
          
          extendedBasis[i] = -extendedBasis[i]
          return false
        }
      }
    }
    return true
  }
  
  public static func computeDelaunayReducedCell2D(unitCell: double3x3, uniqueAxis: Int, symmetryPrecision: Double = 1e-5) -> double3x3?
  {
    var lattice2D: double3x3 = double3x3()
    
    let unique_vec: double3 = unitCell[uniqueAxis]
    
    var k: Int = 0
    for i in 0..<3
    {
      if (i != uniqueAxis)
      {
        lattice2D[k] = unitCell[i]
        k = k + 1
      }
    }
    
    var extendedBasis: double3x3 = double3x3([lattice2D[0],lattice2D[1],-lattice2D[0] - lattice2D[1]])
    
    while(true) { if DelaunayReduceBasis2D(extendedBasis: &extendedBasis) {break}}
    
    
    // Search in the set {b1, b2, b3, b4, b1+b2, b2+b3, b3+b1}
    var b: [double3] = [extendedBasis[0],extendedBasis[1],extendedBasis[2],extendedBasis[0]+extendedBasis[1]]
    
    b.sort(by: {length_squared($0) < length_squared($1)})
    
    for i in 1..<4
    {
      let tmpmat: double3x3 = double3x3([b[0],unique_vec, b[i]])
      
      if (fabs(tmpmat.determinant) > symmetryPrecision)
      {
        extendedBasis[0] = b[0]
        extendedBasis[1] = b[i]
        break;
      }
    }
    
    var basis: double3x3 = double3x3()
    
    k = 0
    for i in 0..<3
    {
      if (i == uniqueAxis)
      {
        basis[i] = unitCell[i]
      }
      else
      {
        basis[i] = extendedBasis[k]
        k = k + 1
      }
    }
    
    let volume: Double = basis.determinant
    
    if (fabs(volume) < symmetryPrecision)
    {
      print("SymmetryKit: Delaunay lattice has zero volume")
      return nil
    }
    
    if (volume < 0)
    {
      basis[uniqueAxis] = -basis[uniqueAxis]
    }
    
    return basis
  }
  
  // In the Buerger cell, a, b and c are the shortest non-coplanar vectors that describe a primitive cell,
  // and either α, β and ɣ ≥ 90 or α, β and ɣ ≤ 90. However in pathelogical cases there can be up to 5 equally good Buerger cells.
  
  // Both as a first step in establishing the true metric symmetry and to be able to compare two structures, it is necessary to have an
  // algorithm that will always reduce equivalent cells to the same conventional cell. The Niggli cell is now invariably used for this.
  // The Niggli-reduced cell of a lattice is a unique choice from among the infinite
  // number of alternate cells that generate the same lattice. A Buerger-reduced
  // cell for a given lattice is any cell that generates that lattice, chosen such
  // that no other cell has shorter cell edges
  
  // The Niggli cell is the Buerger cell that obeys the following extra conditions to distinguish between equivalent Beurger cells:
  // c ≥ b ≥ a; a ≥ 2c cos(β); b ≥ 2a cos(ɣ); a ≥ 2b cos(ɣ)
  
  // Two principal uses of Niggli reduction are the determination of Bravais lattice type
  // and the construction of databases using a representation of the unit cell for the key
  
  // returns the Niggli-form
  // (A     B      C)
  // (xi/2  eta/2  zeta/2)
  // to get the cell-lengths and angles one can use:
  // a'=sqrt(A)            b'=sqrt(B)              c'=sqrt(C)
  // cos alpha'=xi/2b'c'   cos beta'=eta/2a'c'     cos gamma'=zeta/2a'c'
  // Algorithm: "A unified algorithm for determining the reduced (Niggli) cell", I. Krivy and B. Gruber, Acta Cryst., A 32, 297-298, 1976
  public var computeReducedNiggliCell: SKSymmetryCell?
  {
    var counter: Int = 0
    
    // step 0:
    var A: Double = (a*a)
    var B: Double = (b*b)
    var C: Double = (c*c)
    var xi: Double = (2.0*b*c*cos(alpha))
    var eta: Double = (2.0*a*c*cos(beta))
    var zeta: Double = (2.0*a*b*cos(gamma))
    
    algorithmStart: do
    {
      counter = counter + 1
      if(counter>10000) {return nil}
      
      // step 1
      if(isLargerThen(x: A,y: B)||(isEqualTo(x: A, y: B)&&(isLargerThen(x: abs(xi), y: abs(eta)))))
      {
        swap(&A,&B)
        swap(&xi,&eta)
      }
      
      // step 2
      if(isLargerThen(x: B,y: C)||(isEqualTo(x: B, y: C)&&(isLargerThen(x: abs(eta), y: abs(zeta)))))
      {
        swap(&B,&C)
        swap(&eta,&zeta)
        continue algorithmStart
      }
      
      // step 3
      if(isLargerThenZeroXiEtaZeta(x: xi, y: eta, z: zeta))
      {
        xi = abs(xi)
        eta = abs(eta)
        zeta = abs(zeta)
      }
      else // step 4:
      {
        xi = -abs(xi)
        eta = -abs(eta)
        zeta = -abs(zeta)
      }
      
      // step 5
      if((isLargerThen(x: abs(xi), y: B)) ||
        (isEqualTo(x: xi, y: B) && isSmallerThen(x: eta + eta, y: zeta)) ||
        (isEqualTo(x: xi, y: -B) && isSmallerThen(x: zeta, y: 0)))
      {
        if (xi > 0)
        {
          C += B - xi
          xi -= B + B
          eta -= zeta
        }
        else
        {
          C += B + xi
          xi += B + B
          eta += zeta
        }
        continue algorithmStart
      }
      
      // step 6
      if((isLargerThen(x: abs(eta), y: A)) ||
        (isEqualTo(x: eta, y: A) && isSmallerThen(x: xi + xi, y: zeta)) ||
        (isEqualTo(x: eta, y: -A) && isSmallerThen(x: zeta, y: 0)))
      {
        if (eta > 0)
        {
          C += A - eta
          xi -= zeta
          eta -=  A + A
        }
        else
        {
          C += A + eta
          xi += zeta
          eta +=  A + A
        }
        continue algorithmStart
      }
      
      // step7
      if((isLargerThen(x: abs(zeta), y: A)) ||
        (isEqualTo(x: zeta, y: A) && isSmallerThen(x: xi + xi, y: eta)) ||
        (isEqualTo(x: zeta, y: -A) && isSmallerThen(x: eta, y: 0)))
      {
        if (zeta > 0)
        {
          B += A - zeta
          xi -= eta
          zeta -= A + A
        }
        else
        {
          B += A + zeta
          xi += eta
          zeta += A + A
        }
        continue algorithmStart
      }
      
      // step 8
      if(isSmallerThen(x: xi+eta+zeta+A+B, y: 0) ||
        (isEqualTo(x: xi+eta+zeta+A+B, y: 0) && isLargerThen(x: A+A+eta+eta+zeta, y: 0)))
      {
        C += A + B + xi + eta + zeta
        xi += B + B + zeta
        eta +=  A + A  + zeta
        continue algorithmStart
      }
    }
    
    return SKSymmetryCell(a: sqrt(A), b: sqrt(B), c: sqrt(C), alpha: acos(xi/(2.0*sqrt(B)*sqrt(C))) * 180.0/Double.pi, beta: acos(eta/(2.0*sqrt(A)*sqrt(C))) * 180.0/Double.pi, gamma: acos(zeta/(2.0*sqrt(A)*sqrt(B))) * 180.0/Double.pi)
  }
  
  public var computeReducedNiggliCellAndChangeOfBasisMatrix: (cell: SKSymmetryCell, changeOfBasis: int3x3)?
  {
    var counter: Int = 0
    
    // step 0:
    var A: Double = (a*a)
    var B: Double = (b*b)
    var C: Double = (c*c)
    var xi: Double = (2.0*b*c*cos(alpha))
    var eta: Double = (2.0*a*c*cos(beta))
    var zeta: Double = (2.0*a*b*cos(gamma))
    
    var changeOfBasisMatrix: int3x3 = int3x3.identity
    
    algorithmStart: do
    {
      counter = counter + 1
      if(counter>10000) {return nil}
      
      // step 1
      if(isLargerThen(x: A,y: B)||(isEqualTo(x: A, y: B)&&(isLargerThen(x: abs(xi), y: abs(eta)))))
      {
        // Swap x, y and ensures proper sign of determinant
        swap(&A,&B)
        swap(&xi,&eta)
        changeOfBasisMatrix *= int3x3([int3(0,-1,0),int3(-1,0,0),int3(0,0,-1)])
      }
      
      // step 2
      if(isLargerThen(x: B,y: C)||(isEqualTo(x: B, y: C)&&(isLargerThen(x: abs(eta), y: abs(zeta)))))
      {
        // Swap y, z and ensures proper sign of determinant
        swap(&B,&C)
        swap(&eta,&zeta)
        changeOfBasisMatrix *= int3x3([int3(-1,0,0),int3(0,0,-1),int3(0,-1,0)])
        continue algorithmStart
      }
      
      // step 3
      if(isLargerThenZeroXiEtaZeta(x: xi, y: eta, z: zeta))
      {
        var f: [Int32] = [1,1,1]
        if (isSmallerThen(x: xi, y: 0.0)) {f[0] = -1}
        if (isSmallerThen(x: eta, y: 0.0)) {f[1] = -1}
        if (isSmallerThen(x: zeta, y: 0.0)) {f[2] = -1}
        xi = abs(xi)
        eta = abs(eta)
        zeta = abs(zeta)
        changeOfBasisMatrix *= int3x3([int3(f[0],0,0),int3(0,f[1],0),int3(0,0,f[2])])
      }
      else // step 4:
      {
        var p: Int = -1
        var f: [Int32] = [1,1,1]
        if (isLargerThen(x: xi, y: 0.0)) {f[0] = -1}
        else if (!isSmallerThen(x: xi, y: 0.0)) {p=0}
        if (isLargerThen(x: eta, y: 0.0)) {f[1] = -1}
        else if (!isSmallerThen(x: eta, y: 0.0)) {p=1}
        if (isLargerThen(x: zeta, y: 0.0)) {f[2] = -1}
        else if (!isSmallerThen(x: zeta, y: 0.0)) {p=2}
        if (f[0]*f[1]*f[2] < 0)
        {
          f[p] = -1
        }
        xi = -abs(xi)
        eta = -abs(eta)
        zeta = -abs(zeta)
        
        changeOfBasisMatrix *= int3x3([int3(f[0],0,0),int3(0,f[1],0),int3(0,0,f[2])])
      }
      
      // step 5
      if((isLargerThen(x: abs(xi), y: B))||(isEqualTo(x: xi, y: B)&&isSmallerThen(x: 2*eta, y: zeta))||(isEqualTo(x: xi, y: -B)&&isSmallerThen(x: zeta, y: 0)))
      {
        C = B + C - xi * sign(xi)
        eta = eta - zeta * sign(xi)
        xi = xi -  2 * B * sign(xi)
        changeOfBasisMatrix *= int3x3([int3(1,0,0),int3(0,1,0),int3(0,-Int32(sign(xi)),1)])
        continue algorithmStart
      }
      
      // step 6
      if((isLargerThen(x: abs(eta), y: A))||(isEqualTo(x: eta, y: A)&&isSmallerThen(x: 2*xi, y: zeta))||(isEqualTo(x: eta, y: -A)&&isSmallerThen(x: zeta, y: 0)))
      {
        C = A + C - eta * sign(eta)
        xi = xi - zeta * sign(eta)
        eta = eta - 2*A * sign(eta)
        changeOfBasisMatrix *= int3x3([int3(1,0,0),int3(0,1,0),int3(-Int32(sign(eta)),0,1)])
        continue algorithmStart
      }
      
      // step7
      if((isLargerThen(x: abs(zeta), y: A))||(isEqualTo(x: zeta, y: A)&&isSmallerThen(x: 2*xi, y: eta))||(isEqualTo(x: zeta, y: -A)&&isSmallerThen(x: eta, y: 0)))
      {
        B = A + B - zeta * sign(zeta)
        xi = xi - eta * sign(zeta)
        zeta = zeta - 2*A * sign(zeta)
        changeOfBasisMatrix *= int3x3([int3(1,0,0),int3(-Int32(sign(zeta)),1,0),int3(0,0,1)])
        continue algorithmStart
      }
      
      // step 8
      if(isSmallerThen(x: xi+eta+zeta+A+B, y: 0)||(isEqualTo(x: xi+eta+zeta+A+B, y: 0)&&isLargerThen(x: 2*(A+eta)+zeta, y: 0)))
      {
        C = A + B + C + xi + eta + zeta
        xi = 2*B + xi + zeta
        eta =  2*A + eta + zeta
        changeOfBasisMatrix *= int3x3([int3(1,0,0),int3(0,1,0),int3(1,1,1)])
        continue algorithmStart
      }
    }
    
    let cell: SKSymmetryCell = SKSymmetryCell(a: sqrt(A), b: sqrt(B), c: sqrt(C), alpha: acos(xi/(2.0*sqrt(B)*sqrt(C))) * 180.0/Double.pi, beta: acos(eta/(2.0*sqrt(A)*sqrt(C))) * 180.0/Double.pi, gamma: acos(zeta/(2.0*sqrt(A)*sqrt(B))) * 180.0/Double.pi)
    
    
    return (cell, changeOfBasisMatrix)
  }
  
  private static func distanceSquared(a: double3, b: double3) -> Double
  {
    var dr: double3 = abs(a - b)
    dr -= floor(dr + double3(0.5,0.5,0.5))
    return length_squared(dr)
  }
  
  
  
  public static func trim(atoms: [(fractionalPosition: double3, type: Int)], from: double3x3, to: double3x3, symmetryPrecision: Double = 1e-5) -> [(fractionalPosition: double3, type: Int)]
  {
    // compute the reduction in volume
    //let ratio: Int = abs(Int(rint(from.determinant / to.determinant)))
    
    // The change-of-basis matrix C_{old->new} that transforms coordinates in the first (old) setting to coordinates in the second (new) settings
    // is then obtained as the product: C_{old->new} = C_{new}^{-1} C_{old}
    let changeOfBasis: double3x3 = to.inverse * from
    
    let trimmedAtoms: [(fractionalPosition: double3, type: Int)] = atoms.map{(fract(changeOfBasis * $0.fractionalPosition), $0.type)}
    var overlapTable: [Int] = [Int](repeating: -1, count: trimmedAtoms.count)
    
    var result: [(fractionalPosition: double3, type: Int)] = []
    for i in 0..<trimmedAtoms.count
    {
      overlapTable[i] = i
      for j in 0..<trimmedAtoms.count
      {
        if SKSymmetryCell.distanceSquared(a: trimmedAtoms[i].fractionalPosition, b: trimmedAtoms[j].fractionalPosition) < symmetryPrecision
        {
          if overlapTable[j] == j
          {
            overlapTable[i] = j
            break
          }
        }
      }
    }
    
    for i in 0..<trimmedAtoms.count
    {
      if overlapTable[i] == i
      {
        result.append(trimmedAtoms[i])
      }
    }
    
    return result
  }
  
  
  // http://arxiv.org/pdf/1203.5146v4.pdf
  // The Niggli cell is always a Buerger cell, but the opposite is in general not true. We can only state that one (and only one) of the
  // Buerger cells is a Niggli cell.
  var isNiggliCell: Bool
  {
    let g1: Double = a*a
    let g2: Double = b*b
    let g3: Double = c*c
    let g4: Double = 2.0*b*c*cos(alpha)
    let g5: Double = 2.0*a*c*cos(beta)
    let g6: Double = 2.0*a*b*cos(gamma)
    
    if(isSmallerThen(x: g1, y: g2) &&
      isSmallerThen(x: g2, y: g3) &&
      isSmallerThen(x: abs(g4), y: g2) &&
      isSmallerThen(x: abs(g5), y: g1) &&
      isSmallerThen(x: abs(g6), y: g1) &&
      ((isLargerThen(x: g4, y: 0) && isLargerThen(x: g5, y: 0) && isLargerThen(x: g6, y: 0)) ||
        (isSmallerEqualThen(x: g4, y: 0) && isSmallerEqualThen(x: g5, y: 0) && isSmallerEqualThen(x: g6, y: 0)))) {return true}
    
    
    if(!(isSmallerEqualThen(x: 0, y: g1)&&isSmallerEqualThen(x: g1, y: g2)&&isSmallerEqualThen(x: g2, y: g3))) {return false} // require 0<=g1<=g2<=g3
    if(isEqualTo(x:g1, y: g2)) {if(!(isSmallerEqualThen(x: abs(g4), y: abs(g5)))) {return false}} // if g1=g2, then require |g4|<=|g5|
    if(isEqualTo(x:g2, y: g3)) {if(!(isSmallerEqualThen(x: abs(g5), y: abs(g6)))) {return false}} // if g2=g3, then require |g5|<=|g6|
    if(!((isLargerThen(x: g4, y: 0)&&isLargerThen(x: g5, y: 0)&&isLargerThen(x: g6, y: 0)) ||
      (isSmallerEqualThen(x: g4, y: 0)&&isSmallerEqualThen(x: g5, y: 0)&&isSmallerEqualThen(x: g6, y: 0)))) {return false} // {g4,g5,g6}>0 || <g4,g5,g6}<=0)
    
    if(!(isSmallerEqualThen(x: abs(g4), y: g2))) {return false} // require |g4|<=g2
    if(!(isSmallerEqualThen(x: abs(g5), y: g1))) {return false} // require |g5|<=g1
    if(!(isSmallerEqualThen(x: abs(g6), y: g1))) {return false} // require |g6|<=g1
    if(!(isSmallerEqualThen(x: g3, y: g1+g2+g3+g4+g5+g6))) {return false} // require g3<=g1+g2+g3+g4+g5+g6
    
    if(isEqualTo(x:g4, y: g2)) {if(!isSmallerEqualThen(x: g6, y: 2.0*g5)) {return false}} // if(g4=g2) then require g6<=2*g5
    if(isEqualTo(x:g5, y: g1)) {if(!isSmallerEqualThen(x: g6, y: 2.0*g4)) {return false}} // if(g5=g1) then require g6<=2*g4
    if(isEqualTo(x:g6, y: g1)) {if(!isSmallerEqualThen(x: g5, y: 2.0*g4)) {return false}} // if(g6=g1) then require g5<=2*g4
    if(isEqualTo(x:g4, y: -g2)) {if(!isEqualTo(x:g6, y: 0)) {return false}} // if(g4=-g2) then require g6=0
    if(isEqualTo(x:g5, y: -g1)) {if(!isEqualTo(x:g6, y: 0)) {return false}} // if(g5=-g1) then require g6=0
    if(isEqualTo(x:g6, y: -g1)) {if(!isEqualTo(x:g5, y: 0)) {return false}} // if(g6=-g1) then require g6=0
    if(isEqualTo(x:g3, y: (g1+g2+g3+g4+g5+g6))) {if (!(isSmallerEqualThen(x: 2*g1+2*g5+g6, y: 0))) {return false}} // if g3=g1+g2+g3+g4+g5+g6 then require 2*g1+2*g5+g6<=0
    return true
  }
  
  public static func findPrimitiveCell(reducedAtoms: [(fractionalPosition: double3, type: Int)], atoms: [(fractionalPosition: double3, type: Int)], unitCell: double3x3, symmetryPrecision: Double = 1e-5) -> double3x3
  {
    var translationVectors: [double3] = []
    
    if (atoms.count>0)
    {
      let origin: double3 = reducedAtoms[0].fractionalPosition
      
      for i in 0..<reducedAtoms.count
      {
        let vec: double3 = reducedAtoms[i].fractionalPosition - origin
        
        if SKSymmetryCell.isOverlapAllAtoms(translationVector: vec, rotationMatrix: int3x3([int3(1,0,0),int3(0,1,0),int3(0,0,1)]), atoms: atoms, symmetryPrecision: symmetryPrecision)
        {
          translationVectors.append(vec)
        }
      }
      
      translationVectors += [double3(1,0,0),double3(0,1,0),double3(0,0,1)]
    }
    
    let size: Int = translationVectors.count
    
    if (size == 3)
    {
      return unitCell
    }
    
    var smallestCell: double3x3 = unitCell
    let initialVolume: Double = unitCell.determinant
    var minimumVolume: Double = initialVolume
    
    for i in 0..<size
    {
      for j in i+1..<size
      {
        for k in j+1..<size
        {
          let tmpv1: double3 = unitCell * translationVectors[i]
          let tmpv2: double3 = unitCell * translationVectors[j]
          let tmpv3: double3 = unitCell * translationVectors[k]
          let cell: double3x3 = double3x3([tmpv1,tmpv2,tmpv3])
          let volume: Double = abs(cell.determinant)
          
          if((volume>1.0) && (volume<minimumVolume))
          {
            minimumVolume=volume
            smallestCell = double3x3([tmpv1,tmpv2,tmpv3])
            if Int(rint(initialVolume/volume)) == size - 2
            {
              let relativeLattice: double3x3 = double3x3([translationVectors[i],translationVectors[j],translationVectors[k]])
              return unitCell * double3x3(int3x3(relativeLattice.inverse)).inverse
            }
          }
        }
      }
    }
    return smallestCell
  }
  
  /*
   public static func findPrimitiveCell(atoms: [(fractionalPosition: double3, type: Int)], unitCell: double3x3, symmetryPrecision: Double = 1e-5) -> double3x3
   {
   var translationVectors: [double3] = []
   //let unitCell: double3x3 = double3x3(unitCellVectors)
   
   if (atoms.count>0)
   {
   let origin: double3 = atoms[0].fractionalPosition
   
   for i in 1..<atoms.count
   {
   let vec: double3 = atoms[i].fractionalPosition - origin
   
   if SKCell.isOverlapAllAtoms(translationVector: vec, rotationMatrix: int3x3([int3(1,0,0),int3(0,1,0),int3(0,0,1)]), atoms: atoms, symmetryPrecision: symmetryPrecision)
   {
   translationVectors.append(vec)
   }
   }
   
   translationVectors += [double3(1,0,0),double3(0,1,0),double3(0,0,1)]
   }
   
   let size: Int = translationVectors.count
   
   if (size == 3)
   {
   return unitCell
   }
   
   var smallestCell: double3x3 = unitCell
   let initialVolume: Double = unitCell.determinant
   var minimumVolume: Double = initialVolume
   
   
   for i in 0..<size
   {
   for j in i+1..<size
   {
   for k in j+1..<size
   {
   let tmpv1: double3 = unitCell * translationVectors[i]
   let tmpv2: double3 = unitCell * translationVectors[j]
   let tmpv3: double3 = unitCell * translationVectors[k]
   let cell: double3x3 = double3x3([tmpv1,tmpv2,tmpv3])
   let volume: Double = abs(cell.determinant)
   
   
   if((volume>symmetryPrecision) && (volume<minimumVolume))
   {
   minimumVolume=volume
   smallestCell = double3x3([tmpv1,tmpv2,tmpv3])
   if Int(rint(initialVolume/volume)) == size - 2
   {
   let relativeLattice: double3x3 = double3x3([translationVectors[i],translationVectors[j],translationVectors[k]])
   return unitCell * double3x3(int3x3(relativeLattice.inverse)).inverse
   }
   }
   }
   }
   }
   return smallestCell
   }
   */
  
  /// Computes translation vectors for symmetry operations
  ///
  /// - parameter fractionalPositions: the fractional positions of the atomic configuration
  /// - parameter rotationMatrix:      the symmetry elements
  /// - parameter symmetryPrecision:   the precision of the search (default: 1e-5)
  ///
  /// - returns: the list of translation vectors
  public static func primitiveTranslationVectors(reducedAtoms: [(fractionalPosition: double3, type: Int)],atoms: [(fractionalPosition: double3, type: Int)], rotationMatrix: SKRotationMatrix, symmetryPrecision: Double) -> [double3]
  {
    var translationVectors: [double3] = []
    if reducedAtoms.count>0
    {
      let origin: double3 = double3x3(int3x3: rotationMatrix) * reducedAtoms[0].fractionalPosition
      
      for i in 0..<reducedAtoms.count
      {
        let vec: double3 = reducedAtoms[i].fractionalPosition - origin
        
        if SKSymmetryCell.isOverlapAllAtoms(translationVector: vec, rotationMatrix: rotationMatrix, atoms: atoms, symmetryPrecision: symmetryPrecision)
        {
          translationVectors.append(vec)
        }
      }
    }
    return translationVectors
  }
  
  /// Determines overlap given a translation vector and rotation matrix for the atomic configuration.
  ///
  /// - parameter translationVector:   the translation vector
  /// - parameter rotationMatrix:      the rotation matrix
  /// - parameter fractionalPositions: the fractional positions of the atoms
  /// - parameter symmetryPrecision:   the precision of the search (default: 1e-5)
  ///
  /// - returns: whether the translation+rotations result symmetry element in overlap for all atoms or not
  private static func isOverlapAllAtoms(translationVector: double3, rotationMatrix: SKRotationMatrix, atoms: [(fractionalPosition: double3, type: Int)], symmetryPrecision: Double) -> Bool
  {
    let precision: Double = symmetryPrecision * symmetryPrecision
    
    for i in 0..<atoms.count
    {
      let pos_rot: double3 = double3x3(int3x3: rotationMatrix) * atoms[i].fractionalPosition + translationVector
      
      var isFound: Bool = false
      for j in 0..<atoms.count
      {
        if atoms[i].type == atoms[j].type
        {
          var dr: double3 = abs(pos_rot - atoms[j].fractionalPosition)
          dr -= floor(dr + double3(0.5,0.5,0.5))
          //var dr: double3 = pos_rot - fractionalPositions[j]
          //dr.x -= Double(dr.x<0.0 ? Int(dr.x-0.5) : Int(dr.x+0.5))
          //dr.y -= Double(dr.y<0.0 ? Int(dr.y-0.5) : Int(dr.y+0.5))
          //dr.z -= Double(dr.z<0.0 ? Int(dr.z-0.5) : Int(dr.z+0.5))
          if (length_squared(dr) < precision)
          {
            isFound = true
            break
          }
        }
      }
      
      // if no translation is found then we can immediately return 'false'
      if(!isFound)
      {
        return false
      }
    }
    return true
  }
  
  public static func isOverlap(a: double3, b: double3, lattice: double3x3, symmetryPrecision: Double = 1e-5) -> Bool
  {
    var dr: double3 = abs(a - b)
    dr -= floor(dr + double3(0.5,0.5,0.5))
    if length_squared(lattice * dr) < symmetryPrecision * symmetryPrecision
    {
      return true
    }
    return false
  }
  
  
  static func isIdentityMetric(metric_rotated: double3x3, metric_orig: double3x3, symmetryPrecision: Double, angleSymmetryPrecision: Double) -> Bool
  {
    let angleTolerance: Double = -1.0
    let length_orig: double3 =  double3(sqrt(metric_orig[0,0]), sqrt(metric_orig[1,1]), sqrt(metric_orig[2,2]))
    let length_rot: double3 =  double3(sqrt(metric_rotated[0,0]), sqrt(metric_rotated[1,1]), sqrt(metric_rotated[2,2]))
    
    for i in 0..<3
    {
      if abs(length_orig[i] - length_rot[i]) > symmetryPrecision
      {
        return false
      }
    }
    
    if (angleSymmetryPrecision > 0)
    {
      if (abs(getAngle(metric: metric_orig, i: 0, j: 1) - getAngle(metric: metric_rotated, i: 0, j: 1)) > angleTolerance) {return false}
      if (abs(getAngle(metric: metric_orig, i: 0, j: 2) - getAngle(metric: metric_rotated, i: 0, j: 2)) > angleTolerance) {return false}
      if (abs(getAngle(metric: metric_orig, i: 1, j: 2) - getAngle(metric: metric_rotated, i: 1, j: 2)) > angleTolerance) {return false}
      
    }
    else
    {
      /* dtheta = arccos(cos(theta1) - arccos(cos(theta2))) */
      /*        = arccos(c1) - arccos(c2) */
      /*        = arccos(c1c2 + sqrt((1-c1^2)(1-c2^2))) */
      /* sin(dtheta) = sin(arccos(x)) = sqrt(1 - x^2) */
      
      for (_, element) in [(0,1),(0,2),(1,2)].enumerated()
      {
        let j: Int = element.0
        let k: Int = element.1
        
        let cos1: Double = metric_orig[j][k] / length_orig[j] / length_orig[k]
        let cos2: Double = metric_rotated[j][k] / length_rot[j] / length_rot[k]
        let x: Double = cos1 * cos2 + sqrt(1.0 - cos1 * cos1) * sqrt(1.0 - cos2 * cos2)
        let sin_dtheta2: Double = 1.0 - x * x
        let length_ave2: Double = (length_orig[j] + length_rot[j]) * (length_orig[k] + length_rot[k])
        if (sin_dtheta2 > 1e-12)
        {
          if (sin_dtheta2 * length_ave2 * 0.25 > symmetryPrecision * symmetryPrecision)
          {
            return false
          }
        }
      }
    }
    
    return true
  }
  
  static func getAngle(metric: double3x3, i: Int, j: Int) -> Double
  {
    let length_i: Double = 1.0/sqrt(metric[i][i])
    let length_j: Double = 1.0/sqrt(metric[j][j])
    return (acos(metric[i][j]) * length_i * length_j) * 180.0/Double.pi
  }
  
  
}
