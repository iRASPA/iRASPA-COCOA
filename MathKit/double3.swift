/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import simd


extension SIMD3 where Scalar==Double
{
  public var hashValue: Int
  {
    return Int(self.x * 256 * 256 * 256) + Int(self.y * 256 * 256) + Int(self.z * 256)
  }
  
  public static func ==(left: SIMD3<Double>, right: SIMD3<Double>) -> Bool
  {
    return (fabs(left.x - right.x) < 1e-8) && (fabs(left.y - right.y) < 1e-8) && (fabs(left.z - right.z) < 1e-8)
  }
}


public extension SIMD3 where Scalar==Double
{
  init(_ a:  SIMD3<Int32>)
  {
    self.init(Double(a.x), Double(a.y), Double(a.z))
  }
}

public extension SIMD3 where Scalar==Double
{
  static func flip(v: SIMD3<Double>, flip: Bool3, boundary: SIMD3<Double>) -> SIMD3<Double>
  {
    return SIMD3<Double>(flip.x ? boundary.x - v.x : v.x,
                         flip.y ? boundary.y - v.y : v.y,
                         flip.z ? boundary.z - v.z : v.z)
  }
}

public extension SIMD3 where Scalar==Double
{
  static func randomVectorOnUnitSphere() -> SIMD3<Double>
  {
    var ran1,ran2,ranh,ransq: Double
      
    repeat
    {
      ran1=2.0*drand48()-1.0
      ran2=2.0*drand48()-1.0
      ransq=ran1*ran1+ran2*ran2
    }
    while(ransq>=1.0)
      
    ranh=2.0*sqrt(1.0-ransq)
    return SIMD3<Double>(ran1*ranh,ran2*ranh,1.0-2.0*ransq)
  }
}

extension SIMD3 where Scalar==Double
{
  public func RotateAboutArbitraryLine(origin: SIMD3<Double>, dir d: SIMD3<Double>, theta: Double) -> SIMD3<Double>
  {
    var vec: SIMD3<Double> = SIMD3<Double>()
  
    // normalize the direction vector
    let dir: SIMD3<Double> = normalize(d)
    
    let p: SIMD3<Double> = self
  
    vec.x=origin.x*(pow(dir.y,2)+pow(dir.z,2)) +
    dir.x*(-origin.y*dir.y-origin.z*dir.z+dir.x*p.x+dir.y*p.y+dir.z*p.z) +
  ((p.x-origin.x)*(pow(dir.y,2)+pow(dir.z,2))+dir.x*(origin.y*dir.y+origin.z*dir.z-dir.y*p.y-dir.z*p.z))*cos(theta) +
  (origin.y*dir.z-origin.z*dir.y-dir.z*p.y+dir.y*p.z)*sin(theta);
  
  vec.y=origin.y*(pow(dir.x,2)+pow(dir.z,2)) +
  dir.y*(-origin.x*dir.x-origin.z*dir.z+dir.x*p.x+dir.y*p.y+dir.z*p.z) +
  ((p.y-origin.y)*(pow(dir.x,2)+pow(dir.z,2))+dir.y*(origin.x*dir.x+origin.z*dir.z-dir.x*p.x-dir.z*p.z))*cos(theta) +
  (-origin.x*dir.z+origin.z*dir.x+dir.z*p.x-dir.x*p.z)*sin(theta);
  
  vec.z=origin.z*(pow(dir.x,2)+pow(dir.y,2)) +
  dir.z*(-origin.x*dir.x-origin.y*dir.y+dir.x*p.x+dir.y*p.y+dir.z*p.z) +
  ((p.z-origin.z)*(pow(dir.x,2)+pow(dir.y,2))+dir.z*(origin.x*dir.x+origin.y*dir.y-dir.x*p.x-dir.y*p.y))*cos(theta) +
  (origin.x*dir.y-origin.y*dir.x-dir.y*p.x+dir.x*p.y)*sin(theta);
  
  return vec
  }

}

extension SIMD3 where Scalar==Double
{
  public static func *(left: simd_quatd, right: SIMD3<Double>) -> SIMD3<Double>
  {
    // Extract the vector part of the quaternion
    let u: SIMD3<Double> = left.imag
  
    // Extract the scalar part of the quaternion
    let s: Double = left.real
  
    // Do the math
    let vprime1 = 2.0 * dot(u, right) * u
    let vrpime2 = (s*s - dot(u, u)) * right
    let vprime3 = 2.0 * s * cross(u, right)
    return vprime1 + vrpime2 + vprime3
  }
}
