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
import Accelerate

extension double3x3 {
  public var inverseReplacement: double3x3 {
    return self.inverse
  }
}

extension double3x3
{
  public init(Double4x4: double4x4)
  {
    self.init([SIMD3<Double>(x: Double4x4[0][0], y: Double4x4[0][1], z: Double4x4[0][2]),
               SIMD3<Double>(x: Double4x4[1][0], y: Double4x4[1][1], z: Double4x4[1][2]),
               SIMD3<Double>(x: Double4x4[2][0], y: Double4x4[2][1], z: Double4x4[2][2])])
  }
}



public extension double3x3
{
  init(int3x3 a:  int3x3)
  {
    let col1 = a[0]
    let col2 = a[1]
    let col3 = a[2]
    self.init([SIMD3<Double>(x: Double(col1.x), y: Double(col1.y),z: Double(col1.z)),
               SIMD3<Double>(x: Double(col2.x), y: Double(col2.y),z: Double(col2.z)),
               SIMD3<Double>(x: Double(col3.x), y: Double(col3.y),z: Double(col3.z))])
  }
  
  
  static func * (left: double3x3, right: SIMD3<Int32>) -> SIMD3<Double>
  {
    return SIMD3<Double>(x: left[0][0] * Double(right.x) + left[1][0] * Double(right.y) + left[2][0] * Double(right.z),
                   y: left[0][1] * Double(right.x) + left[1][1] * Double(right.y) + left[2][1] * Double(right.z),
                   z: left[0][2] * Double(right.x) + left[1][2] * Double(right.y) + left[2][2] * Double(right.z))
  }
  
  
  
  static func * (left: SIMD3<Int32>, right: double3x3) -> SIMD3<Double>
  {
    return SIMD3<Double>(x: Double(left.x) * right[0][0] + Double(left.y) * right[0][1] + Double(left.z) * right[0][2],
                   y: Double(left.x) * right[1][0] + Double(left.y) * right[1][1] + Double(left.z) * right[1][2],
                   z: Double(left.x) * right[2][0] + Double(left.y) * right[2][1] + Double(left.z) * right[2][2])
  }
}




extension double3x3: Hashable
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
  
  public init(_ m: int3x3)
  {
    self.init([SIMD3<Double>(Double(m[0][0])/Double(m.denominator),Double(m[0][1])/Double(m.denominator),Double(m[0][2])/Double(m.denominator)),
               SIMD3<Double>(Double(m[1][0])/Double(m.denominator),Double(m[1][1])/Double(m.denominator),Double(m[1][2])/Double(m.denominator)),
               SIMD3<Double>(Double(m[2][0])/Double(m.denominator),Double(m[2][1])/Double(m.denominator),Double(m[2][2])/Double(m.denominator))])
  }
  
  public func isInteger(precision: Double) -> Bool
  {
    for i in 0..<3
    {
      for j in 0..<3
      {
        if (fabs(rint(self[i][j]) - self[i][j]) > precision)
        {
          return false
        }
      }
    }
    return true
  }
  
  
  public static func *(left: double3x3, right: int3x3) -> double3x3
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
  
  public static func / (left: double3x3, right: Double) -> double3x3
  {
    return double3x3([SIMD3<Double>(left[0,0] / right, left[0,1] / right, left[0,2] / right),
                      SIMD3<Double>(left[1,0] / right, left[1,1] / right, left[1,2] / right),
                      SIMD3<Double>(left[2,0] / right, left[2,1] / right, left[2,2] / right)])
  }
  
  public static func ==(left: double3x3, right: double3x3) -> Bool
  {
    return (left[0][0] == right[0][0]) && (left[0][1] == right[0][1]) && (left[0][2] == right[0][2]) &&
      (left[1][0] == right[1][0]) && (left[1][1] == right[1][1]) && (left[1][2] == right[1][2]) &&
      (left[2][0] == right[2][0]) && (left[2][1] == right[2][1]) && (left[2][2] == right[2][2])
  }
  
  public init(simd_quatd q: simd_quatd)
  {
    let sqw: Double = q.vector.w*q.vector.w
    let sqx: Double = q.vector.x*q.vector.x
    let sqy: Double = q.vector.y*q.vector.y
    let sqz: Double = q.vector.z*q.vector.z
    
    self.init()
    
    // invs (inverse square length) is only required if quaternion is not already normalised
    let invs: Double = 1 / (sqx + sqy + sqz + sqw)
    self[0,0] = ( sqx - sqy - sqz + sqw) * invs  // since sqw + sqx + sqy + sqz =1/invs*invs
    self[1,1] = (-sqx + sqy - sqz + sqw) * invs
    self[2,2] = (-sqx - sqy + sqz + sqw) * invs
   
    
    var tmp1: Double = q.vector.x*q.vector.y
    var tmp2: Double = q.vector.z*q.vector.w
    self[0,1] = 2.0 * (tmp1 + tmp2)*invs
    self[1,0] = 2.0 * (tmp1 - tmp2)*invs
    
    tmp1 = q.vector.x*q.vector.z
    tmp2 = q.vector.y*q.vector.w
    self[0,2] = 2.0 * (tmp1 - tmp2) * invs
    self[2,0] = 2.0 * (tmp1 + tmp2) * invs
    
    tmp1 = q.vector.y * q.vector.z
    tmp2 = q.vector.x * q.vector.w
    self[1,2] = 2.0 * (tmp1 + tmp2) * invs
    self[2,1] = 2.0 * (tmp1 - tmp2) * invs
  }
}

extension double3x3
{
  public func EigenSystemSymmetric3x3(Q: inout double3x3, w: inout SIMD3<Double>)
  {
    
    let decompositionJobV = UnsafeMutablePointer<Int8>(mutating: ("V" as NSString).utf8String)
    let upload = UnsafeMutablePointer<Int8>(mutating: ("U" as NSString).utf8String)
    var data: [Double] = [self[0][0], self[0][1], self[0][2], self[1][0], self[1][1], self[1][2], self[2][0], self[2][1], self[2][2]]
    var work: [Double] = [Double](repeating: 0, count: Int(9*3))
    var lwork: Int32 = 9 * 3
    var eigenvalues: [Double] = [Double](repeating: 0, count: 3)
    var error: Int32 = 0
    var N: Int32 = 3
    var M: Int32 = 3
    
    dsyev_(decompositionJobV, upload, &M, &data, &N, &eigenvalues, &work, &lwork, &error)
    
    w = SIMD3<Double>(eigenvalues[2],eigenvalues[1],eigenvalues[0])
    let axis1: SIMD3<Double> = normalize(SIMD3<Double>(data[0],data[1],data[2]))
    let axis2: SIMD3<Double> = normalize(SIMD3<Double>(data[3],data[4],data[5]))
    let axis3: SIMD3<Double> = normalize(SIMD3<Double>(data[6],data[7],data[8]))
    Q = double3x3([axis1,axis2,axis3])
    if Q.determinant<0
    {
      Q = double3x3([axis1,axis3,axis2])
    }
  }
  
  public func EigenSystem3x3(Q: inout double3x3, w: inout SIMD3<Double>)
  {
    let n: Int = 3;
    var sd: Double = 0.0
    var so: Double = 0.0                  // Sums of diagonal resp. off-diagonal elements
    var s, c, t: Double;                 // sin(phi), cos(phi), tan(phi) and temporary storage
    var g, h, z, theta: Double;          // More temporary storage
    var thresh: Double;
    
    var A: double3x3 = self
    
    // Initialize Q to the identitity matrix
    for i in 0..<n
    {
      Q[i][i] = 1.0;
      for j in 0..<i
      {
        Q[i][j] = 0.0
        Q[j][i] = 0.0;
      }
    }
    
    // Initialize w to diag(A)
    for i in 0..<n
    {
      w[i] = A[i][i];
    }
    
    // Calculate SQR(tr(A))
    sd = 0.0;
    for i in 0..<n
    {
      sd += fabs(w[i]);
    }
    sd = pow(sd,2);
    // Main iteration loop
    for nIter in 0..<50
    {
      // Test for convergence
      so = 0.0;
      for p in 0..<n
      {
        for q in p+1..<n
        {
          so += fabs(A[p][q]);
        }
      }
      if (so == 0.0)
      {
        let combined = zip([w[0],w[1],w[2]],[Q[0],Q[1],Q[2]]).sorted {$0.0 > $1.0}
        w = SIMD3<Double>(combined.map {$0.0})
        Q = double3x3(combined.map {$0.1})
        return
      }
      
      if (nIter < 4)
      {
        thresh = 0.2 * so / pow(Double(n),2);
      }
      else
      {
        thresh = 0.0;
      }
      
      // Do sweep
      for p in 0..<n
      {
        for q in p+1..<n
        {
          g = 100.0 * fabs(A[p][q]);
          if (nIter > 4  &&  fabs(w[p]) + g == fabs(w[p]) &&  fabs(w[q]) + g == fabs(w[q]))
          {
            A[p][q] = 0.0;
          }
          else if (fabs(A[p][q]) > thresh)
          {
            // Calculate Jacobi transformation
            h = w[q] - w[p];
            if (fabs(h) + g == fabs(h))
            {
              t = A[p][q] / h;
            }
            else
            {
              theta = 0.5 * h / A[p][q];
              if (theta < 0.0)
              {
              t = -1.0 / (sqrt(1.0 + pow(theta,2)) - theta);
              }
              else
              {
              t = 1.0 / (sqrt(1.0 + pow(theta,2)) + theta);
              }
            }
            c = 1.0/sqrt(1.0 + pow(t,2));
            s = t * c;
            z = t * A[p][q];
            
            // Apply Jacobi transformation
            A[p][q] = 0.0;
            w[p] -= z;
            w[q] += z;
            for r in 0..<p
            {
              t = A[r][p];
              A[r][p] = c*t - s*A[r][q];
              A[r][q] = s*t + c*A[r][q];
            }
            for r in p+1..<q
            {
              t = A[p][r];
              A[p][r] = c*t - s*A[r][q];
              A[r][q] = s*t + c*A[r][q];
            }
            for r in q+1..<n
            {
              t = A[p][r];
              A[p][r] = c*t - s*A[q][r];
              A[q][r] = s*t + c*A[q][r];
            }
            
            // Update eigenvectors
            for r in 0..<n
            {
              t = Q[r][p];
              Q[r][p] = c*t - s*Q[r][q];
              Q[r][q] = s*t + c*Q[r][q];
            }
          }
        }
      }
    }
    let combined = zip([w[0],w[1],w[2]],[Q[0],Q[1],Q[2]]).sorted {$0.0 > $1.0}
    w = SIMD3<Double>(combined.map {$0.0})
    Q = double3x3(combined.map {$0.1})
  }
  
  
}
