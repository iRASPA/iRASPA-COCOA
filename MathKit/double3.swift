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


extension double3
{
  public var hashValue: Int
  {
    return Int(self.x * 256 * 256 * 256) + Int(self.y * 256 * 256) + Int(self.z * 256)
  }
  
  public static func ==(left: double3, right: double3) -> Bool
  {
    return (fabs(left.x - right.x) < 1e-8) && (fabs(left.y - right.y) < 1e-8) && (fabs(left.z - right.z) < 1e-8)
  }
}


public extension double3
{
  init(_ a:  int3)
  {
    self.init(Double(a.x), Double(a.y), Double(a.z))
  }
}

public extension double3
{
  static func flip(v: double3, flip: Bool3, boundary: double3) -> double3
  {
    return double3(flip.x ? boundary.x - v.x : v.x,
                   flip.y ? boundary.y - v.y : v.y,
                   flip.z ? boundary.z - v.z : v.z)
  }
}

public extension double3
{
  static func randomVectorOnUnitSphere() -> double3
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
    return double3(ran1*ranh,ran2*ranh,1.0-2.0*ransq)
  }
}

extension double3
{
  public func RotateAboutArbitraryLine(origin: double3, dir d: double3, theta: Double) -> double3
  {
    var vec: double3 = double3()
  
    // normalize the direction vector
    var dir: double3 = normalize(d)
    
    var p: double3 = self
  
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

extension double3
{
  public static func *(left: simd_quatd, right: double3) -> double3
  {
    // Extract the vector part of the quaternion
    let u: double3 = left.imag
  
    // Extract the scalar part of the quaternion
    let s: Double = left.real
  
    // Do the math
    let vprime1 = 2.0 * dot(u, right) * u
    let vrpime2 = (s*s - dot(u, u)) * right
    let vprime3 = 2.0 * s * cross(u, right)
    return vprime1 + vrpime2 + vprime3
  }
}
