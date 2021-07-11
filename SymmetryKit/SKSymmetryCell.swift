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
  
  static let epsilon: Double = 1.0e-5
  
  
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
    let column1: SIMD3<Double> = unitCell[0]
    let column2: SIMD3<Double> = unitCell[1]
    let column3: SIMD3<Double> = unitCell[2]
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
    
    let v1: SIMD3<Double> = SIMD3<Double>(x: a, y: 0.0, z: 0.0)
    let v2: SIMD3<Double> = SIMD3<Double>(x: b * cos(gamma), y: b * sin(gamma), z: 0.0)
    let v3: SIMD3<Double> = SIMD3<Double>(x: c * cos(beta), y: c * temp, z: c * sqrt(1.0 - cos(beta)*cos(beta)-temp*temp))
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
      return double3x3([SIMD3<Double>(a,0.0,0.0),SIMD3<Double>(b * cg,b * sg,0.0),SIMD3<Double>(c * cb,c * (ca - cb * cg) / sg, temp)])
    case .monoclinic:
      return double3x3([SIMD3<Double>(a,0.0,0.0),SIMD3<Double>(0.0,b,0.0),SIMD3<Double>(c * cos(beta),0.0,c * sin(beta))])
    case .orthorhombic:
      return double3x3([SIMD3<Double>(a,0.0,0.0),SIMD3<Double>(0.0,b,0.0),SIMD3<Double>(0.0,0.0,c)])
    case .tetragonal:
      return double3x3([SIMD3<Double>(0.5*(a+b),0.0,0.0),SIMD3<Double>(0.0,0.5*(a+b),0.0),SIMD3<Double>(0.0,0.0,c)])
    case .trigonal where spaceGroup.spaceGroupSetting.qualifier == "R":
      let avg: Double = (a+b+c)/3.0
      let angle: Double = acos((cos(gamma) + cos(beta) + cos(alpha)) / 3.0)
      // Reference, https://homepage.univie.ac.at/michael.leitner/lattice/struk/rgr.html
      let ahex: Double = 2.0 * avg * sin(0.5 * angle)
      let chex: Double = (a+b+c)/3.0 * sqrt(3.0 * (1.0 + 2.0 * cos(angle)))
      return  double3x3([SIMD3<Double>(ahex / 2,-ahex / (2 * sqrt(3)),chex / 3),SIMD3<Double>(0.0,ahex / sqrt(3),chex / 3),SIMD3<Double>(-ahex / 2,-ahex / (2 * sqrt(3)),chex / 3)])
    case .trigonal where spaceGroup.spaceGroupSetting.qualifier != "R", .hexagonal:
      return double3x3([SIMD3<Double>(0.5*(a+b),0.0,0.0),SIMD3<Double>(-(a+b)/4.0,(a+b)/4.0*sqrt(3.0),0.0),SIMD3<Double>(0.0,0.0,c)])
    case .cubic:
      let edge: Double = (a + b + c)/3.0
      return double3x3([SIMD3<Double>(edge,0.0,0.0),SIMD3<Double>(0.0,edge,0.0),SIMD3<Double>(0.0,0.0,edge)])
    default:
      return double3x3()
    }
  }
  
  public static func TransformToConventionalUnitCell(unitCell: double3x3, spaceGroup: SKSpacegroup) -> double3x3
  {
    let metric: double3x3 = unitCell.transpose * unitCell
    var lattice: double3x3 = double3x3(diagonal: SIMD3<Double>(0,0,0))
    
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
  
  static func isSmallerThen(x: Double, y: Double) -> Bool
  {
    return x < (y - epsilon)
  }
  
  static func isLargerThen(x: Double, y: Double) -> Bool
  {
    return isSmallerThen(x: y, y: x)
  }
  
  static func isSmallerEqualThen(x: Double, y: Double) -> Bool
  {
    return !(y < (x - epsilon))
  }
  
  static func isLargerEqualThen(x: Double, y: Double) -> Bool
  {
    return !(x < (y - epsilon))
  }
  
  static func  isEqualTo(x: Double, y: Double) -> Bool
  {
    return !((x < (y - epsilon)) || (y < (x - epsilon)))
  }
  
  static func isLargerThenZeroXiEtaZeta(x xi: Double, y eta: Double, z zeta: Double) -> Bool
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
      
      let v1: SIMD3<Double> = SIMD3<Double>(x: a, y: 0.0, z: 0.0)
      let v2: SIMD3<Double> = SIMD3<Double>(x: b * cos(gamma), y: b * sin(gamma), z: 0.0)
      let v3: SIMD3<Double> = SIMD3<Double>(x: c * cos(beta), y: c * temp, z: c * sqrt(1.0 - cos(beta)*cos(beta)-temp*temp))
      return double3x3([v1, v2, v3])
    }
  }
  
  public static func angles(cell: double3x3) -> (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)
  {
    let column1: SIMD3<Double> = cell[0]
    let column2: SIMD3<Double> = cell[1]
    let column3: SIMD3<Double> = cell[2]
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
    
    let v1: SIMD3<Double> = SIMD3<Double>(a*a, half_zeta, half_eta)
    let v2: SIMD3<Double> = SIMD3<Double>(half_zeta, b*b, half_xi)
    let v3: SIMD3<Double> = SIMD3<Double>(half_eta, half_xi, c*c)
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
  
  
  /// Ref: I. Krivy, B. Gruber,  "A Unified Algorithm for Determining the Reduced (Niggli) Cell",  Acta Cryst. (1976). A32, 297
  ///    R. W. Grosse-Kunstleve, N. K. Sauter and P. D. Adams, "Numerically stable algorithms for the computation of reduced unit cells", Acta Cryst. (2004). A60, 1-6
  public static func computeReducedNiggliCellAndChangeOfBasisMatrix(unitCell: double3x3) -> double3x3?
  {
    var counter: Int = 0
    
    var rotatedUnitCell: double3x3 = unitCell
    let metricMatrix: double3x3 = unitCell.transpose * unitCell
    
    // step 0:
    var A: Double = metricMatrix[0,0]
    var B: Double = metricMatrix[1,1]
    var C: Double = metricMatrix[2,2]
    var xi: Double = metricMatrix[1,2] + metricMatrix[2,1]
    var eta: Double = metricMatrix[0,2] + metricMatrix[2,0]
    var zeta: Double = metricMatrix[0,1] + metricMatrix[1,0]
        
    algorithmStart: do
    {
      counter = counter + 1
      if(counter>10000) {return nil}
      
      // step 1
      if(SKSymmetryCell.isLargerThen(x: A,y: B)||(SKSymmetryCell.isEqualTo(x: A, y: B)&&(SKSymmetryCell.isLargerThen(x: abs(xi), y: abs(eta)))))
      {
        let matrixC = SKRotationMatrix([SIMD3<Int32>(0,-1,0),SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,0,-1)])
        assert(matrixC.determinant == 1)
        rotatedUnitCell = rotatedUnitCell * matrixC
        
        // Swap x, y and ensures proper sign of determinant
        swap(&A,&B)
        swap(&xi,&eta)
        
      }
      
      // step 2
      if(SKSymmetryCell.isLargerThen(x: B,y: C)||(SKSymmetryCell.isEqualTo(x: B, y: C)&&(SKSymmetryCell.isLargerThen(x: abs(eta), y: abs(zeta)))))
      {
        let matrixC = SKRotationMatrix([SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,0,-1),SIMD3<Int32>(0,-1,0)])
        assert(matrixC.determinant == 1)
        rotatedUnitCell = rotatedUnitCell * matrixC
        
        // Swap y, z and ensures proper sign of determinant
        swap(&B,&C)
        swap(&eta,&zeta)
        
        continue algorithmStart
      }
      
      // step 3
      if(SKSymmetryCell.isLargerThenZeroXiEtaZeta(x: xi, y: eta, z: zeta))
      {
        var f: [Int32] = [1,1,1]
        if (SKSymmetryCell.isSmallerThen(x: xi, y: 0.0)) {f[0] = -1}
        if (SKSymmetryCell.isSmallerThen(x: eta, y: 0.0)) {f[1] = -1}
        if (SKSymmetryCell.isSmallerThen(x: zeta, y: 0.0)) {f[2] = -1}
       
        let matrixC = SKRotationMatrix([SIMD3<Int32>(f[0],0,0),SIMD3<Int32>(0,f[1],0),SIMD3<Int32>(0,0,f[2])])
        assert(matrixC.determinant == 1)
        rotatedUnitCell = rotatedUnitCell * matrixC
        
        xi = abs(xi)
        eta = abs(eta)
        zeta = abs(zeta)
      }
      else // step 4:
      {
        var p: Int = -1
        var f: [Int32] = [1,1,1]
        if (SKSymmetryCell.isLargerThen(x: xi, y: 0.0)) {f[0] = -1}
        else if (!SKSymmetryCell.isSmallerThen(x: xi, y: 0.0)) {p=0}
        if (SKSymmetryCell.isLargerThen(x: eta, y: 0.0)) {f[1] = -1}
        else if (!SKSymmetryCell.isSmallerThen(x: eta, y: 0.0)) {p=1}
        if (SKSymmetryCell.isLargerThen(x: zeta, y: 0.0)) {f[2] = -1}
        else if (!SKSymmetryCell.isSmallerThen(x: zeta, y: 0.0)) {p=2}
        if (f[0]*f[1]*f[2] < 0)
        {
          f[p] = -1
        }
        let matrixC = SKRotationMatrix([SIMD3<Int32>(f[0],0,0),SIMD3<Int32>(0,f[1],0),SIMD3<Int32>(0,0,f[2])])
        assert(matrixC.determinant == 1)
        rotatedUnitCell = rotatedUnitCell * matrixC
        
        xi = -abs(xi)
        eta = -abs(eta)
        zeta = -abs(zeta)
      }
      
      // step 5
      if((SKSymmetryCell.isLargerThen(x: abs(xi), y: B))||(SKSymmetryCell.isEqualTo(x: xi, y: B)&&isSmallerThen(x: 2.0*eta, y: zeta))||(SKSymmetryCell.isEqualTo(x: xi, y: -B)&&isSmallerThen(x: zeta, y: 0)))
      {
        let matrixC = SKRotationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,-Int32(sign(xi)),1)])
        assert(matrixC.determinant == 1)
        rotatedUnitCell = rotatedUnitCell * matrixC
        
        C = B + C - xi * sign(xi)
        eta = eta - zeta * sign(xi)
        xi = xi -  2.0 * B * sign(xi)
        
        continue algorithmStart
      }
      
      // step 6
      if((SKSymmetryCell.isLargerThen(x: abs(eta), y: A))||(SKSymmetryCell.isEqualTo(x: eta, y: A)&&isSmallerThen(x: 2.0*xi, y: zeta))||(SKSymmetryCell.isEqualTo(x: eta, y: -A)&&SKSymmetryCell.isSmallerThen(x: zeta, y: 0.0)))
      {
        let matrixC = SKRotationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(-Int32(sign(eta)),0,1)])
        assert(matrixC.determinant == 1)
        rotatedUnitCell = rotatedUnitCell * matrixC
        
        C = A + C - eta * sign(eta)
        xi = xi - zeta * sign(eta)
        eta = eta - 2.0*A * sign(eta)
        continue algorithmStart
      }
      
      // step7
      if((SKSymmetryCell.isLargerThen(x: abs(zeta), y: A))||(SKSymmetryCell.isEqualTo(x: zeta, y: A)&&SKSymmetryCell.isSmallerThen(x: 2.0*xi, y: eta))||(SKSymmetryCell.isEqualTo(x: zeta, y: -A)&&SKSymmetryCell.isSmallerThen(x: eta, y: 0.0)))
      {
        let matrixC = SKRotationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(-Int32(sign(zeta)),1,0),SIMD3<Int32>(0,0,1)])
        assert(matrixC.determinant == 1)
        rotatedUnitCell = rotatedUnitCell * matrixC
        
        B = A + B - zeta * sign(zeta)
        xi = xi - eta * sign(zeta)
        zeta = zeta - 2.0*A * sign(zeta)
        
        continue algorithmStart
      }
      
      // step 8
      if(SKSymmetryCell.isSmallerThen(x: xi+eta+zeta+A+B, y: 0.0)||(SKSymmetryCell.isEqualTo(x: xi+eta+zeta+A+B, y: 0.0)&&SKSymmetryCell.isLargerThen(x: 2.0*(A+eta)+zeta, y: 0.0)))
      {
        let matrixC = SKRotationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(1,1,1)])
        assert(matrixC.determinant == 1)
        rotatedUnitCell = rotatedUnitCell * matrixC
        
        C = A + B + C + xi + eta + zeta
        xi = 2.0*B + xi + zeta
        eta =  2.0*A + eta + zeta
        
        continue algorithmStart
      }
    }
        
    return rotatedUnitCell
  }
  
  /// Compute the Delaunay reduced cell
  ///
  /// - parameter unitCell:          the original unit cell
  /// - parameter symmetryPrecision: the precision of the cell
  ///
  /// - returns: the Delaunay cell
  ///
  ///   We start with a lattice basis (b_i) 1≤ i ≤ n (n=2,3). This basis is extended by a factor b_n+1 = -(b_1 + ... + b_n )
  ///   All scalar products  b_i . b_k (1 ≤ i < k ≤ n+1) are considered. The reduction is performed by mnimizing the sum: sum = b_1^2 + ... + b_n+1^2.
  ///   It can be shown that this sum can be reduced as long as one of the scalar products is still positive.
  ///   If e.g. the scalar product b_1 . b_2 is still positive, a transformation can be performed such that the sum sum' of the transformed b_i^2 is smaller than sum:
  ///   b_1' = -b_1
  ///   b_2' = b_2
  ///   b_3' = b_1 + b_3
  ///   b_4' = b+1 + b_4
  ///
  ///   If all the scalar products are less than or equal to zero, the three shortest vectors forming the reduced basis are contained in the set
  ///   V = {b_1, b_2, b_3, b_4, b_1 + b_2, b_2 + b_3, b_3 + b_1}
  ///   which corresponds to the maximal set of faces of the Dirichlet domain (14 faces).
  ///
  ///   Reference: International Tables for Crystallography, Vol.A: Space Group Symmetry, page 747
  public static func computeDelaunayReducedCell(unitCell: double3x3, symmetryPrecision: Double = 1e-5) -> double3x3?
  {
    let additionalBasisVector: SIMD3<Double> =  -(unitCell[0] + unitCell[1] + unitCell[2])
    var extendedBasis: double4x3 = double4x3([unitCell[0],unitCell[1],unitCell[2],additionalBasisVector])
    
    var somePositive: Bool = false
    repeat
    {
      somePositive = false
      // (i,j) in (0,1), (0,2), (0,3), (1,2), (1,3), (2,3); k,l denote the other two vectors
      for (i,j,k,l) in [(0,1,2,3), (0,2,1,3), (0,3,1,2), (1,2,0,3), (1,3,0,2), (2,3,0,1)]
      {
        if (dot(extendedBasis[i], extendedBasis[j]) > symmetryPrecision)
        {
          extendedBasis[k] += extendedBasis[i]
          extendedBasis[l] += extendedBasis[i]
       
          extendedBasis[i] = -extendedBasis[i]
          
          // start over (until all dotproducts are negative or zero)
          somePositive = true
          break
        }
      }
    }while(somePositive)
    
    // Search in the array {b1, b2, b3, b4, b1+b2, b2+b3, b3+b1}, sorted by length (using a small epsilon to amke sure they are really different)
    let b: [SIMD3<Double>] = [extendedBasis[0], extendedBasis[1], extendedBasis[2], extendedBasis[3],
                              extendedBasis[0] + extendedBasis[1], extendedBasis[1] + extendedBasis[2],
                              extendedBasis[2] + extendedBasis[0]].sorted(by: {length_squared($0) + 1e-10 < (length_squared($1) )})
    
    // take the first two vectors, combined with a vector that has a non-zero, positive volume
    for i in 2..<7
    {
      let trialUnitCell: double3x3 = double3x3([b[0], b[1], b[i]])
      let volume: Double = trialUnitCell.determinant
      
      if (abs(volume) > symmetryPrecision)
      {
        return (volume > 0) ? trialUnitCell: -trialUnitCell
      }
    }
    
    return nil
  }
  
  public static func computeDelaunayReducedCell2D(unitCell: double3x3, uniqueAxis: Int, symmetryPrecision: Double = 1e-5) -> double3x3?
  {
    var lattice2D: double3x3 = double3x3()
    
    let unique_vec: SIMD3<Double> = unitCell[uniqueAxis]
    
    var k: Int = 0
    for i in 0..<3
    {
      if (i != uniqueAxis)
      {
        lattice2D[k] = unitCell[i]
        k = k + 1
      }
    }
    
    var extendedBasis: double3x3 = double3x3([lattice2D[0], lattice2D[1], -(lattice2D[0] + lattice2D[1])])
    
    var somePositive: Bool = false
    repeat
    {
      somePositive = false
      // (i,j) in (0,1), (0,2), (1,2); k denote the other two vectors
      for (i,j,k) in [(0,1,2), (0,2,1), (1,2,0)]
      {
        if (dot(extendedBasis[i], extendedBasis[j]) > symmetryPrecision)
        {
          extendedBasis[k] += 2.0 * extendedBasis[i]
       
          extendedBasis[i] = -extendedBasis[i]
          
          // start over (until all dotproducts are negative or zero)
          somePositive = true
          break
        }
      }
    }while(somePositive)
    
    
    // Search in the set {b1, b2, b3, b1+b2}
    let b: [SIMD3<Double>] = [extendedBasis[0], extendedBasis[1], extendedBasis[2],
                              extendedBasis[0]+extendedBasis[1]].sorted(by: {length_squared($0) + 1e-10 < length_squared($1)})
    
    for i in 1..<4
    {
      let tmpmat: double3x3 = double3x3([b[0], unique_vec, b[i]])
      
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
  /// Ref: I. Krivy, B. Gruber,  "A Unified Algorithm for Determining the Reduced (Niggli) Cell",  Acta Cryst. (1976). A32, 297-298
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
      if(SKSymmetryCell.isLargerThen(x: A,y: B)||(SKSymmetryCell.isEqualTo(x: A, y: B)&&(SKSymmetryCell.isLargerThen(x: abs(xi), y: abs(eta)))))
      {
        swap(&A,&B)
        swap(&xi,&eta)
      }
      
      // step 2
      if(SKSymmetryCell.isLargerThen(x: B,y: C)||(SKSymmetryCell.isEqualTo(x: B, y: C)&&(SKSymmetryCell.isLargerThen(x: abs(eta), y: abs(zeta)))))
      {
        swap(&B,&C)
        swap(&eta,&zeta)
        continue algorithmStart
      }
      
      // step 3
      if(SKSymmetryCell.isLargerThenZeroXiEtaZeta(x: xi, y: eta, z: zeta))
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
      if((SKSymmetryCell.isLargerThen(x: abs(xi), y: B)) ||
          (SKSymmetryCell.isEqualTo(x: xi, y: B) && SKSymmetryCell.isSmallerThen(x: eta + eta, y: zeta)) ||
          (SKSymmetryCell.isEqualTo(x: xi, y: -B) && SKSymmetryCell.isSmallerThen(x: zeta, y: 0)))
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
      if((SKSymmetryCell.isLargerThen(x: abs(eta), y: A)) ||
          (SKSymmetryCell.isEqualTo(x: eta, y: A) && SKSymmetryCell.isSmallerThen(x: xi + xi, y: zeta)) ||
          (SKSymmetryCell.isEqualTo(x: eta, y: -A) && SKSymmetryCell.isSmallerThen(x: zeta, y: 0)))
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
      if((SKSymmetryCell.isLargerThen(x: abs(zeta), y: A)) ||
          (SKSymmetryCell.isEqualTo(x: zeta, y: A) && SKSymmetryCell.isSmallerThen(x: xi + xi, y: eta)) ||
          (SKSymmetryCell.isEqualTo(x: zeta, y: -A) && SKSymmetryCell.isSmallerThen(x: eta, y: 0)))
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
      if(SKSymmetryCell.isSmallerThen(x: xi+eta+zeta+A+B, y: 0) ||
          (SKSymmetryCell.isEqualTo(x: xi+eta+zeta+A+B, y: 0) && SKSymmetryCell.isLargerThen(x: A+A+eta+eta+zeta, y: 0)))
      {
        C += A + B + xi + eta + zeta
        xi += B + B + zeta
        eta +=  A + A  + zeta
        continue algorithmStart
      }
    }
    
    print(A,B,C,xi,eta,zeta)
    
    return SKSymmetryCell(a: sqrt(A), b: sqrt(B), c: sqrt(C), alpha: acos(xi/(2.0*sqrt(B)*sqrt(C))) * 180.0/Double.pi, beta: acos(eta/(2.0*sqrt(A)*sqrt(C))) * 180.0/Double.pi, gamma: acos(zeta/(2.0*sqrt(A)*sqrt(B))) * 180.0/Double.pi)
  }
  
  /// Ref: I. Krivy, B. Gruber,  "A Unified Algorithm for Determining the Reduced (Niggli) Cell",  Acta Cryst. (1976). A32, 297-298
  ///    R. W. Grosse-Kunstleve, N. K. Sauter and P. D. Adams, "Numerically stable algorithms for the computation of reduced unit cells", Acta Cryst. (2004). A60, 1-6
  public var computeReducedNiggliCellAndChangeOfBasisMatrix: (cell: SKSymmetryCell, changeOfBasis: SKTransformationMatrix)?
  {
    var counter: Int = 0
    
    // step 0:
    var A: Double = (a*a)
    var B: Double = (b*b)
    var C: Double = (c*c)
    var xi: Double = (2.0*b*c*cos(alpha))
    var eta: Double = (2.0*a*c*cos(beta))
    var zeta: Double = (2.0*a*b*cos(gamma))
        
    var changeOfBasisMatrix: SKTransformationMatrix = SKTransformationMatrix.identity
    
    algorithmStart: do
    {
      counter = counter + 1
      if(counter>10000) {return nil}
      
      // step 1
      if(SKSymmetryCell.isLargerThen(x: A,y: B)||(SKSymmetryCell.isEqualTo(x: A, y: B)&&(SKSymmetryCell.isLargerThen(x: abs(xi), y: abs(eta)))))
      {
        let matrixC = SKTransformationMatrix([SIMD3<Int32>(0,-1,0),SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,0,-1)])
        assert(matrixC.determinant == 1)
        changeOfBasisMatrix *= matrixC
        
        // Swap x, y and ensures proper sign of determinant
        swap(&A,&B)
        swap(&xi,&eta)
      }
      
      // step 2
      if(SKSymmetryCell.isLargerThen(x: B,y: C)||(SKSymmetryCell.isEqualTo(x: B, y: C)&&(SKSymmetryCell.isLargerThen(x: abs(eta), y: abs(zeta)))))
      {
        let matrixC = SKTransformationMatrix([SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,0,-1),SIMD3<Int32>(0,-1,0)])
        assert(matrixC.determinant == 1)
        changeOfBasisMatrix *= matrixC
        
        // Swap y, z and ensures proper sign of determinant
        swap(&B,&C)
        swap(&eta,&zeta)
        
        continue algorithmStart
      }
      
      // step 3
      if(SKSymmetryCell.isLargerThenZeroXiEtaZeta(x: xi, y: eta, z: zeta))
      {
        var f: [Int32] = [1,1,1]
        if (SKSymmetryCell.isSmallerThen(x: xi, y: 0.0)) {f[0] = -1}
        if (SKSymmetryCell.isSmallerThen(x: eta, y: 0.0)) {f[1] = -1}
        if (SKSymmetryCell.isSmallerThen(x: zeta, y: 0.0)) {f[2] = -1}
        let matrixC = SKTransformationMatrix([SIMD3<Int32>(f[0],0,0),SIMD3<Int32>(0,f[1],0),SIMD3<Int32>(0,0,f[2])])
        assert(matrixC.determinant == 1)
        changeOfBasisMatrix *= matrixC
        
        xi = abs(xi)
        eta = abs(eta)
        zeta = abs(zeta)
      }
      else // step 4:
      {
        var p: Int = -1
        var f: [Int32] = [1,1,1]
        if (SKSymmetryCell.isLargerThen(x: xi, y: 0.0)) {f[0] = -1}
        else if (!SKSymmetryCell.isSmallerThen(x: xi, y: 0.0)) {p=0}
        if (SKSymmetryCell.isLargerThen(x: eta, y: 0.0)) {f[1] = -1}
        else if (!SKSymmetryCell.isSmallerThen(x: eta, y: 0.0)) {p=1}
        if (SKSymmetryCell.isLargerThen(x: zeta, y: 0.0)) {f[2] = -1}
        else if (!SKSymmetryCell.isSmallerThen(x: zeta, y: 0.0)) {p=2}
        if (f[0]*f[1]*f[2] < 0)
        {
          f[p] = -1
        }
        let matrixC = SKTransformationMatrix([SIMD3<Int32>(f[0],0,0),SIMD3<Int32>(0,f[1],0),SIMD3<Int32>(0,0,f[2])])
        assert(matrixC.determinant == 1)
        changeOfBasisMatrix *= matrixC
        
        xi = -abs(xi)
        eta = -abs(eta)
        zeta = -abs(zeta)
      }
      
      // step 5
      if((SKSymmetryCell.isLargerThen(x: abs(xi), y: B))||(SKSymmetryCell.isEqualTo(x: xi, y: B)&&SKSymmetryCell.isSmallerThen(x: 2.0*eta, y: zeta))||(SKSymmetryCell.isEqualTo(x: xi, y: -B)&&SKSymmetryCell.isSmallerThen(x: zeta, y: 0)))
      {
        let matrixC = SKTransformationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,-Int32(sign(xi)),1)])
        assert(matrixC.determinant == 1)
        changeOfBasisMatrix *= matrixC
        
        C = B + C - xi * sign(xi)
        eta = eta - zeta * sign(xi)
        xi = xi -  2.0 * B * sign(xi)
        
        continue algorithmStart
      }
      
      // step 6
      if((SKSymmetryCell.isLargerThen(x: abs(eta), y: A))||(SKSymmetryCell.isEqualTo(x: eta, y: A)&&SKSymmetryCell.isSmallerThen(x: 2.0*xi, y: zeta))||(SKSymmetryCell.isEqualTo(x: eta, y: -A)&&SKSymmetryCell.isSmallerThen(x: zeta, y: 0.0)))
      {
        let matrixC = SKTransformationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(-Int32(sign(eta)),0,1)])
        assert(matrixC.determinant == 1)
        changeOfBasisMatrix *= matrixC
        
        C = A + C - eta * sign(eta)
        xi = xi - zeta * sign(eta)
        eta = eta - 2.0*A * sign(eta)
        
        continue algorithmStart
      }
      
      // step7
      if((SKSymmetryCell.isLargerThen(x: abs(zeta), y: A))||(SKSymmetryCell.isEqualTo(x: zeta, y: A)&&SKSymmetryCell.isSmallerThen(x: 2.0*xi, y: eta))||(SKSymmetryCell.isEqualTo(x: zeta, y: -A)&&SKSymmetryCell.isSmallerThen(x: eta, y: 0.0)))
      {
        let matrixC = SKTransformationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(-Int32(sign(zeta)),1,0),SIMD3<Int32>(0,0,1)])
        assert(matrixC.determinant == 1)
        changeOfBasisMatrix *= matrixC
        
        B = A + B - zeta * sign(zeta)
        xi = xi - eta * sign(zeta)
        zeta = zeta - 2.0*A * sign(zeta)
        
        continue algorithmStart
      }
      
      // step 8
      if(SKSymmetryCell.isSmallerThen(x: xi+eta+zeta+A+B, y: 0.0)||(SKSymmetryCell.isEqualTo(x: xi+eta+zeta+A+B, y: 0.0)&&SKSymmetryCell.isLargerThen(x: 2.0*(A+eta)+zeta, y: 0.0)))
      {
        let matrixC = SKTransformationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(1,1,1)])
        assert(matrixC.determinant == 1)
        changeOfBasisMatrix *= matrixC
        
        C = A + B + C + xi + eta + zeta
        xi = 2.0*B + xi + zeta
        eta =  2.0*A + eta + zeta
        
        continue algorithmStart
      }
    }
        
    let cell: SKSymmetryCell = SKSymmetryCell(a: sqrt(A), b: sqrt(B), c: sqrt(C), alpha: acos(xi/(2.0*sqrt(B)*sqrt(C))) * 180.0/Double.pi, beta: acos(eta/(2.0*sqrt(A)*sqrt(C))) * 180.0/Double.pi, gamma: acos(zeta/(2.0*sqrt(A)*sqrt(B))) * 180.0/Double.pi)
    
    
    return (cell, changeOfBasisMatrix)
  }
  
  private static func distanceSquared(a: SIMD3<Double>, b: SIMD3<Double>) -> Double
  {
    var dr: SIMD3<Double> = abs(a - b)
    dr -= floor(dr + SIMD3<Double>(0.5,0.5,0.5))
    return length_squared(dr)
  }
  
  
  
  public static func trim(atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], from: double3x3, to: double3x3, symmetryPrecision: Double = 1e-5) -> [(fractionalPosition: SIMD3<Double>, type: Int)]
  {
    // The change-of-basis matrix C_{old->new} that transforms coordinates in the first (old) setting to coordinates in the second (new) settings
    // is then obtained as the product: C_{old->new} = C_{new}^{-1} C_{old}
    let changeOfBasis: double3x3 = to.inverse * from
    
    let trimmedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = atoms.map{(fract(changeOfBasis * $0.fractionalPosition), $0.type)}
    var overlapTable: [Int] = [Int](repeating: -1, count: trimmedAtoms.count)
    
    var result: [(fractionalPosition: SIMD3<Double>, type: Int)] = []
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
    
    if(SKSymmetryCell.isSmallerThen(x: g1, y: g2) &&
        SKSymmetryCell.isSmallerThen(x: g2, y: g3) &&
        SKSymmetryCell.isSmallerThen(x: abs(g4), y: g2) &&
        SKSymmetryCell.isSmallerThen(x: abs(g5), y: g1) &&
        SKSymmetryCell.isSmallerThen(x: abs(g6), y: g1) &&
        ((SKSymmetryCell.isLargerThen(x: g4, y: 0) && SKSymmetryCell.isLargerThen(x: g5, y: 0) && SKSymmetryCell.isLargerThen(x: g6, y: 0)) ||
          (SKSymmetryCell.isSmallerEqualThen(x: g4, y: 0) && SKSymmetryCell.isSmallerEqualThen(x: g5, y: 0) && SKSymmetryCell.isSmallerEqualThen(x: g6, y: 0)))) {return true}
    
    
    if(!(SKSymmetryCell.isSmallerEqualThen(x: 0, y: g1)&&SKSymmetryCell.isSmallerEqualThen(x: g1, y: g2)&&SKSymmetryCell.isSmallerEqualThen(x: g2, y: g3))) {return false} // require 0<=g1<=g2<=g3
    if(SKSymmetryCell.isEqualTo(x:g1, y: g2)) {if(!(SKSymmetryCell.isSmallerEqualThen(x: abs(g4), y: abs(g5)))) {return false}} // if g1=g2, then require |g4|<=|g5|
    if(SKSymmetryCell.isEqualTo(x:g2, y: g3)) {if(!(SKSymmetryCell.isSmallerEqualThen(x: abs(g5), y: abs(g6)))) {return false}} // if g2=g3, then require |g5|<=|g6|
    if(!((SKSymmetryCell.isLargerThen(x: g4, y: 0)&&SKSymmetryCell.isLargerThen(x: g5, y: 0)&&SKSymmetryCell.isLargerThen(x: g6, y: 0)) ||
          (SKSymmetryCell.isSmallerEqualThen(x: g4, y: 0)&&SKSymmetryCell.isSmallerEqualThen(x: g5, y: 0)&&SKSymmetryCell.isSmallerEqualThen(x: g6, y: 0)))) {return false} // {g4,g5,g6}>0 || <g4,g5,g6}<=0)
    
    if(!(SKSymmetryCell.isSmallerEqualThen(x: abs(g4), y: g2))) {return false} // require |g4|<=g2
    if(!(SKSymmetryCell.isSmallerEqualThen(x: abs(g5), y: g1))) {return false} // require |g5|<=g1
    if(!(SKSymmetryCell.isSmallerEqualThen(x: abs(g6), y: g1))) {return false} // require |g6|<=g1
    if(!(SKSymmetryCell.isSmallerEqualThen(x: g3, y: g1+g2+g3+g4+g5+g6))) {return false} // require g3<=g1+g2+g3+g4+g5+g6
    
    if(SKSymmetryCell.isEqualTo(x:g4, y: g2)) {if(!SKSymmetryCell.isSmallerEqualThen(x: g6, y: 2.0*g5)) {return false}} // if(g4=g2) then require g6<=2*g5
    if(SKSymmetryCell.isEqualTo(x:g5, y: g1)) {if(!SKSymmetryCell.isSmallerEqualThen(x: g6, y: 2.0*g4)) {return false}} // if(g5=g1) then require g6<=2*g4
    if(SKSymmetryCell.isEqualTo(x:g6, y: g1)) {if(!SKSymmetryCell.isSmallerEqualThen(x: g5, y: 2.0*g4)) {return false}} // if(g6=g1) then require g5<=2*g4
    if(SKSymmetryCell.isEqualTo(x:g4, y: -g2)) {if(!SKSymmetryCell.isEqualTo(x:g6, y: 0)) {return false}} // if(g4=-g2) then require g6=0
    if(SKSymmetryCell.isEqualTo(x:g5, y: -g1)) {if(!SKSymmetryCell.isEqualTo(x:g6, y: 0)) {return false}} // if(g5=-g1) then require g6=0
    if(SKSymmetryCell.isEqualTo(x:g6, y: -g1)) {if(!SKSymmetryCell.isEqualTo(x:g5, y: 0)) {return false}} // if(g6=-g1) then require g6=0
    if(SKSymmetryCell.isEqualTo(x:g3, y: (g1+g2+g3+g4+g5+g6))) {if (!(SKSymmetryCell.isSmallerEqualThen(x: 2*g1+2*g5+g6, y: 0))) {return false}} // if g3=g1+g2+g3+g4+g5+g6 then require 2*g1+2*g5+g6<=0
    return true
  }
  
  /// Computes the smallest primitive cell
  ///
  /// - parameter reducedAtoms:        the atoms of the type that occurs least
  /// - parameter atoms:               the atoms
  /// - parameter unitCell:            the unit cell
  /// - parameter symmetryPrecision:   the precision of the search (default: 1e-5)
  ///
  /// - returns: the computed smallest primitive cell
  ///
  ///   Hannemann et al., 1998: Starting from each atom i of the con®guration, difference vectors dij to atoms j (j > i) of the same type are calculated (in principle, the category `type' could include the electronic and magnetic states of the atom, if known).
  ///   Only those difference vectors whose coordinates relative to the basis B do not exceed 12 need to be considered [note that this restriction is analogous to the minimum image convention]
  ///   Next, each difference vector dij is added to the position vectors al of the other atoms belonging to the configuration. If all resulting vectors ax = al +/- dij are elements of the set of vectors representing the atoms of the configuration,
  ///   a translation has been found and it is added to the set T of possible translations. Of course, the vectors representing the basis B are also included in the set T. In the next step, test cells are generated by choosing all possible triplets
  ///   of vectors from the set T. If such a triplet is linearly independent and the volume of the spanned parallelepiped does not exceed the volume of the simulation cell, the test cell is acceptable, in principle. In order to avoid degenerate
  ///   cells, one usually excludes cells with angles smaller than 5 degrees or larger than 175 degrees. Finally, one of the cells with the smallest volume is chosen as the representative primitive cell.
  ///   Note that this choice may result in unconventional cell constants and the cell needs to be reduced.
  ///   10.1107/s0021889898008735
  public static func findSmallestPrimitiveCell(reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)], atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], unitCell: double3x3, symmetryPrecision: Double = 1e-5) -> double3x3
  {
    var translationVectors: [SIMD3<Double>] = []
    
    if (atoms.count>0)
    {
      let origin: SIMD3<Double> = reducedAtoms[0].fractionalPosition
      
      for i in 1..<reducedAtoms.count
      {
        let vec: SIMD3<Double> = reducedAtoms[i].fractionalPosition - origin
        
        if SKSymmetryCell.testTranslationalSymmetry(of: vec, on: atoms, and: unitCell, with: symmetryPrecision)
        {
          var a: SIMD3<Double> = SIMD3<Double>(vec.x-rint(vec.x), vec.y-rint(vec.y), vec.z-rint(vec.z))
          if (a.x < 0.0 - 1e-10) {a.x += 1.0}
          if (a.y < 0.0 - 1e-10) {a.y += 1.0}
          if (a.z < 0.0 - 1e-10) {a.z += 1.0}
          translationVectors.append(a)
        }
      }
           
      translationVectors += [SIMD3<Double>(1,0,0),SIMD3<Double>(0,1,0),SIMD3<Double>(0,0,1)]
    }
    
    let size: Int = translationVectors.count
    
    var smallestCell: double3x3 = unitCell
    let initialVolume: Double = unitCell.determinant
    var minimumVolume: Double = initialVolume
    
    /*
    if(size == 1)
    {
      let DelaunayUnitCell: double3x3? = SKSymmetryCell.computeDelaunayReducedCell(unitCell: smallestCell, symmetryPrecision: symmetryPrecision)
      return DelaunayUnitCell!
    }*/
    
    for i in 0..<size
    {
      for j in i+1..<size
      {
        for k in j+1..<size
        {
          let tmpv1: SIMD3<Double> = unitCell * translationVectors[i]
          let tmpv2: SIMD3<Double> = unitCell * translationVectors[j]
          let tmpv3: SIMD3<Double> = unitCell * translationVectors[k]
          let cell: double3x3 = double3x3([tmpv1,tmpv2,tmpv3])
          let volume: Double = abs(cell.determinant)
                    
          if((volume>1.0) && (volume<minimumVolume))
          {
            minimumVolume=volume
            smallestCell = double3x3([tmpv1,tmpv2,tmpv3])
            
               
            // initialVolume/volume is nearly integer
            if Int(rint(initialVolume/volume)) == size - 2
            {
              let relativeLattice: double3x3 = double3x3([translationVectors[i],translationVectors[j],translationVectors[k]])
             
              // inverse is nearly integer
              return unitCell * double3x3(int3x3(relativeLattice.inverse)).inverse
            }
          }
        }
      }
    }
    return smallestCell
  }
  
  /// Computes translation vectors for symmetry operations
  ///
  /// - parameter unitCell:            the unit cell
  /// - parameter fractionalPositions: the fractional positions of the atomic configuration
  /// - parameter rotationMatrix:      the symmetry elements
  /// - parameter symmetryPrecision:   the precision of the search (default: 1e-5)
  ///
  /// - returns: the list of translation vectors, including (0,0,0)
  public static func primitiveTranslationVectors(unitCell: double3x3, reducedAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)],atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], rotationMatrix: SKRotationMatrix, symmetryPrecision: Double) -> [SIMD3<Double>]
  {
    var translationVectors: [SIMD3<Double>] = []
    if reducedAtoms.count>0
    {
      let origin: SIMD3<Double> = rotationMatrix * reducedAtoms[0].fractionalPosition
      
      for i in 0..<reducedAtoms.count
      {
        let vec: SIMD3<Double> = reducedAtoms[i].fractionalPosition - origin
        
        if SKSymmetryCell.testSymmetry(of: vec, and: rotationMatrix, on: atoms, and: unitCell, with: symmetryPrecision)
        {
          translationVectors.append(vec)
        }
      }
    }
    return translationVectors
  }
  
  /// Determines  whether a translation vector and rotation matrix is a symmetry element for the given atomic configuration.
  ///
  /// - parameter translationVector:   the translation vector
  /// - parameter rotationMatrix:      the rotation matrix
  /// - parameter fractionalPositions: the fractional positions of the atoms
  /// - parameter symmetryPrecision:   the precision of the search (default: 1e-5)
  /// - returns: whether the rotation+translation is a symmetry operation for the system or not
  ///
  /// - A symmetry operation, after applying the rotation and then translation on any atom, should lead to an overlap with another atom.
  ///   For each atom, we loop over all atoms. If no overlaps are found, the total result is false. As soon as an overlap is found, we can stop the current loop and continue with the next atom to check.
  private static func testSymmetry(of translationVector: SIMD3<Double>, and rotationMatrix: SKRotationMatrix, on atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], and unitCell: double3x3, with precision: Double) -> Bool
  {    
    for i in 0..<atoms.count
    {
      let rotatedAndTranslatedPosition: SIMD3<Double> = rotationMatrix * atoms[i].fractionalPosition + translationVector
      
      var isFound: Bool = false
      for j in 0..<atoms.count
      {
        if atoms[i].type == atoms[j].type
        {
          var dr: SIMD3<Double> = rotatedAndTranslatedPosition - atoms[j].fractionalPosition
          dr.x -= rint(dr.x)
          dr.y -= rint(dr.y)
          dr.z -= rint(dr.z)
          if (length_squared(unitCell * dr) < precision * precision)
          {
            isFound = true
            break
          }
        }
      }
      
      // if no overlap is found then we can immediately return 'false'
      if(!isFound)
      {
        return false
      }
    }
    return true
  }
  
  private static func testTranslationalSymmetry(of translationVector: SIMD3<Double>, on atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], and unitCell: double3x3, with precision: Double) -> Bool
  {
    let squared_precision: Double = precision * precision
    
    for i in 0..<atoms.count
    {
      let translatedPosition: SIMD3<Double> = atoms[i].fractionalPosition + translationVector
      
      var isFound: Bool = false
      for j in 0..<atoms.count
      {
        if atoms[i].type == atoms[j].type
        {
          var dr: SIMD3<Double> = translatedPosition - atoms[j].fractionalPosition
          dr.x -= rint(dr.x)
          dr.y -= rint(dr.y)
          dr.z -= rint(dr.z)
          if (length_squared(unitCell * dr) < squared_precision)
          {
            isFound = true
            break
          }
        }
      }
      
      // if no overlap is found then we can immediately return 'false'
      if(!isFound)
      {
        return false
      }
    }
    return true
  }
  
  
  public static func isOverlap(a: SIMD3<Double>, b: SIMD3<Double>, lattice: double3x3, symmetryPrecision: Double = 1e-5) -> Bool
  {
    var dr: SIMD3<Double> = abs(a - b)
    dr.x -= rint(dr.x)
    dr.y -= rint(dr.y)
    dr.z -= rint(dr.z)
    if length_squared(lattice * dr) < symmetryPrecision * symmetryPrecision
    {
      return true
    }
    return false
  }
  
  
  static func isIdentityMetric(transformedMetricMatrix: double3x3, metricMatrix: double3x3, symmetryPrecision: Double, angleSymmetryPrecision: Double) -> Bool
  {
    let angleTolerance: Double = -1.0
    let LengthMetricMatrix: SIMD3<Double> =  SIMD3<Double>(sqrt(metricMatrix[0,0]), sqrt(metricMatrix[1,1]), sqrt(metricMatrix[2,2]))
    let LengthTransformedMetric: SIMD3<Double> =  SIMD3<Double>(sqrt(transformedMetricMatrix[0,0]), sqrt(transformedMetricMatrix[1,1]), sqrt(transformedMetricMatrix[2,2]))
    
    for i in 0..<3
    {
      if abs(LengthMetricMatrix[i] - LengthTransformedMetric[i]) > symmetryPrecision
      {
        return false
      }
    }
    
    if (angleSymmetryPrecision > 0)
    {
      if (abs(getAngle(metric: metricMatrix, i: 0, j: 1) - getAngle(metric: transformedMetricMatrix, i: 0, j: 1)) > angleTolerance) {return false}
      if (abs(getAngle(metric: metricMatrix, i: 0, j: 2) - getAngle(metric: transformedMetricMatrix, i: 0, j: 2)) > angleTolerance) {return false}
      if (abs(getAngle(metric: metricMatrix, i: 1, j: 2) - getAngle(metric: transformedMetricMatrix, i: 1, j: 2)) > angleTolerance) {return false}
      
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
        
        let cos1: Double = metricMatrix[j][k] / LengthMetricMatrix[j] / LengthMetricMatrix[k]
        let cos2: Double = transformedMetricMatrix[j][k] / LengthTransformedMetric[j] / LengthTransformedMetric[k]
        let x: Double = cos1 * cos2 + sqrt(1.0 - cos1 * cos1) * sqrt(1.0 - cos2 * cos2)
        let sin_dtheta2: Double = 1.0 - x * x
        let length_ave2: Double = (LengthMetricMatrix[j] + LengthTransformedMetric[j]) * (LengthMetricMatrix[k] + LengthTransformedMetric[k])
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
