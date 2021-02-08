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
import simd
import simd.quaternion

extension simd_quatd
{
  public init(pitch: Double)
  {
    let half_theta: Double = 0.5 * pitch * Double.pi/180.0
    self.init()
    self.vector = SIMD4<Double>(sin(half_theta),0.0,0.0,cos(half_theta))
  }
  
  public init(yaw: Double)
  {
    let half_theta: Double = 0.5 * yaw * Double.pi/180.0
    self.init()
    self.vector = SIMD4<Double>(0.0,sin(half_theta),0.0,cos(half_theta))
  }
  
  public init(roll: Double)
  {
    let half_theta: Double = 0.5 * roll * Double.pi/180.0
    
    self.init()
    self.vector = SIMD4<Double>(0.0, 0.0,sin(half_theta), cos(half_theta))
  }
  
 
  
  // http://www.euclideanspace.com/maths/geometry/rotations/conversions/eulerToQuaternion/index.htm
  public init(EulerAngles angles: SIMD3<Double>)
  {
    let c1: Double = cos(angles.x/2.0)  // heading
    let s1: Double = sin(angles.x/2.0)
    let c2: Double = cos(angles.y/2.0)  // attitude
    let s2: Double = sin(angles.y/2.0)
    let c3: Double = cos(angles.z/2.0)  // bank
    let s3: Double = sin(angles.z/2.0)
    let c1c2: Double = c1 * c2
    let s1s2: Double = s1 * s2
    self.init()
    self.vector =  SIMD4<Double>(c1c2 * s3 + s1s2 * c3,
                               s1 * c2 * c3 + c1 * s2 * s3,
                               c1 * s2 * c3 - s1 * c2 * s3,
                               c1c2 * c3 - s1s2 * s3)
  }
  
  // http://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToEuler/index.htm
  // 'NASA standard airplane', but with swapped the y and z axis, to conform to x3d
  // Heading = rotation about y axis, Attitude = rotation about z axis, Bank = rotation about x axis
  // Heading applied first, Attitude applied second, Bank applied last
  public var EulerAngles: SIMD3<Double>
  {
    get
    {
      let sqw: Double = self.vector.w * self.vector.w
      let sqx: Double = self.vector.x * self.vector.x
      let sqy: Double = self.vector.y * self.vector.y
      let sqz: Double = self.vector.z * self.vector.z
      let unit: Double = sqx + sqy + sqz + sqw  // if normalised is one, otherwise is correction factor
      let test: Double = self.vector.x * self.vector.y + self.vector.z * self.vector.w
      if (test > 0.49999*unit)
      {
        // singularity at north pole
        return SIMD3<Double>(x: 2 * atan2(self.vector.x,self.vector.w), y: Double.pi/2.0, z: 0.0)
      }
      if (test < -0.49999*unit)
      {
        // singularity at south pole
        return SIMD3<Double>(x: -2 * atan2(self.vector.x,self.vector.w), y: -Double.pi/2.0, z: 0.0)
      }
      
      // return heading, attitude, bank
      return SIMD3<Double>(x: atan2(2*self.vector.y*self.vector.w-2*self.vector.x*self.vector.z, sqx - sqy - sqz + sqw),
                     y: asin(2*test/unit),
                     z: atan2(2*self.vector.x*self.vector.w-2*self.vector.y*self.vector.z , -sqx + sqy - sqz + sqw))
    }
    set(newValue)
    {
      let c1: Double = cos(newValue.x/2.0)  // heading
      let s1: Double = sin(newValue.x/2.0)
      let c2: Double = cos(newValue.y/2.0)  // attitude
      let s2: Double = sin(newValue.y/2.0)
      let c3: Double = cos(newValue.z/2.0)  // bank
      let s3: Double = sin(newValue.z/2.0)
      let c1c2: Double = c1 * c2
      let s1s2: Double = s1 * s2
      self.vector.w = c1c2 * c3 - s1s2 * s3
      self.vector.x = c1c2 * s3 + s1s2 * c3
      self.vector.y = s1 * c2 * c3 + c1 * s2 * s3
      self.vector.z = c1 * s2 * c3 - s1 * c2 * s3
    }
  }
  
  // Ref. K. Shoemake, "Uniform Random Rotations", in D. Kirk, editor, graphic Gems III, pages 124-132, Academic Press, New York, 1992
  
  public static func Random() -> simd_quatd
  {
    var s: Double = 0
    var sigma1: Double = 0
    var sigma2: Double = 0
    var theta1: Double = 0
    var theta2: Double = 0
    
    
    s=drand48()
    sigma1=sqrt(1.0-s)
    sigma2=sqrt(s)
    theta1=2.0 * Double.pi * drand48()
    theta2=2.0 * Double.pi * drand48()
    
    var q: simd_quatd = simd_quatd()
    q.vector = SIMD4<Double>(sigma2 * cos(theta2),
                                      sigma1 * sin(theta1),
                                      sigma1 * cos(theta1),
                                      sigma2 * sin(theta2))
    return q
  }
  
  public static func smallRandomQuaternion(angleRange: Double) -> simd_quatd
  {
    let randomDirection: SIMD3<Double> = SIMD3<Double>.randomVectorOnUnitSphere()
    let angle: Double = angleRange*2.0*(drand48()-0.5)
    return simd_quatd(angle: angle, axis: randomDirection).normalized
  }
  
  public static let Data120: [simd_quatd] =
  [
    simd_quatd(real: 0.0, imag: SIMD3<Double>(1.0, 0.0, 0.0)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-1.0, 0.0, 0.0)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.0, 1.0, 0.0)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.0, -1.0, 0.0)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.0, 0.0, 1.0)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.0, 0.0, -1.0)),
    simd_quatd(real: 1.0, imag: SIMD3<Double>(0.0, 0.0, 0.0)),
    simd_quatd(real: -1.0, imag: SIMD3<Double>(0.0, 0.0, 0.0)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(0.0, 0.5, 0.309017)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(0.0, -0.5, 0.309017)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(0.0, 0.5, -0.309017)),
    simd_quatd(real: -0.809017, imag: SIMD3<Double>(0.0, 0.5, 0.309017)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(0.0, -0.5, -0.309017)),
    simd_quatd(real: -0.809017, imag: SIMD3<Double>(0.0, -0.5, 0.309017)),
    simd_quatd(real: -0.809017, imag: SIMD3<Double>(0.0, 0.5, -0.309017)),
    simd_quatd(real: -0.809017, imag: SIMD3<Double>(0.0, -0.5, -0.309017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.0, 0.309017, 0.809017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.0, -0.309017, 0.809017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.0, 0.309017, -0.809017)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.0, 0.309017, 0.809017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.0, -0.309017, -0.809017)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.0, -0.309017, 0.809017)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.0, 0.309017, -0.809017)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.0, -0.309017, -0.809017)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(0.0, 0.809017, 0.5)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(0.0, -0.809017, 0.5)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(0.0, 0.809017, -0.5)),
    simd_quatd(real: -0.309017, imag: SIMD3<Double>(0.0, 0.809017, 0.5)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(0.0, -0.809017, -0.5)),
    simd_quatd(real: -0.309017, imag: SIMD3<Double>(0.0, -0.809017, 0.5)),
    simd_quatd(real: -0.309017, imag: SIMD3<Double>(0.0, 0.809017, -0.5)),
    simd_quatd(real: -0.309017, imag: SIMD3<Double>(0.0, -0.809017, -0.5)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(0.5, 0.0, 0.809017)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(-0.5, 0.0, 0.809017)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(0.5, 0.0, -0.809017)),
    simd_quatd(real: -0.309017, imag: SIMD3<Double>(0.5, 0.0, 0.809017)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(-0.5, 0.0, -0.809017)),
    simd_quatd(real: -0.309017, imag: SIMD3<Double>(-0.5, 0.0, 0.809017)),
    simd_quatd(real: -0.309017, imag: SIMD3<Double>(0.5, 0.0, -0.809017)),
    simd_quatd(real: -0.309017, imag: SIMD3<Double>(-0.5, 0.0, -0.809017)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(0.309017, 0.0, 0.5)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(-0.309017, 0.0, 0.5)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(0.309017, 0.0, -0.5)),
    simd_quatd(real: -0.809017, imag: SIMD3<Double>(0.309017, 0.0, 0.5)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(-0.309017, 0.0, -0.5)),
    simd_quatd(real: -0.809017, imag: SIMD3<Double>(-0.309017, 0.0, 0.5)),
    simd_quatd(real: -0.809017, imag: SIMD3<Double>(0.309017, 0.0, -0.5)),
    simd_quatd(real: -0.809017, imag: SIMD3<Double>(-0.309017, 0.0, -0.5)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.809017, 0.0, 0.309017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(-0.809017, 0.0, 0.309017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.809017, 0.0, -0.309017)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.809017, 0.0, 0.309017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(-0.809017, 0.0, -0.309017)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(-0.809017, 0.0, 0.309017)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.809017, 0.0, -0.309017)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(-0.809017, 0.0, -0.309017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.309017, 0.809017, 0.0)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(-0.309017, 0.809017, 0.0)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.309017, -0.809017, 0.0)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.309017, 0.809017, 0.0)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(-0.309017, -0.809017, 0.0)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(-0.309017, 0.809017, 0.0)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.309017, -0.809017, 0.0)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(-0.309017, -0.809017, 0.0)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(0.809017, 0.5, 0.0)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(-0.809017, 0.5, 0.0)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(0.809017, -0.5, 0.0)),
    simd_quatd(real: -0.309017, imag: SIMD3<Double>(0.809017, 0.5, 0.0)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(-0.809017, -0.5, 0.0)),
    simd_quatd(real: -0.309017, imag: SIMD3<Double>(-0.809017, 0.5, 0.0)),
    simd_quatd(real: -0.309017, imag: SIMD3<Double>(0.809017, -0.5, 0.0)),
    simd_quatd(real: -0.309017, imag: SIMD3<Double>(-0.809017, -0.5, 0.0)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(0.5, 0.309017, 0.0)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(-0.5, 0.309017, 0.0)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(0.5, -0.309017, 0.0)),
    simd_quatd(real: -0.809017, imag: SIMD3<Double>(0.5, 0.309017, 0.0)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(-0.5, -0.309017, 0.0)),
    simd_quatd(real: -0.809017, imag: SIMD3<Double>(-0.5, 0.309017, 0.0)),
    simd_quatd(real: -0.809017, imag: SIMD3<Double>(0.5, -0.309017, 0.0)),
    simd_quatd(real: -0.809017, imag: SIMD3<Double>(-0.5, -0.309017, 0.0)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.809017, 0.309017, 0.5)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.809017, 0.309017, 0.5)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.809017, -0.309017, 0.5)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.809017, 0.309017, -0.5)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.809017, -0.309017, 0.5)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.809017, 0.309017, -0.5)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.809017, -0.309017, -0.5)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.809017, -0.309017, -0.5)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.5, 0.809017, 0.309017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.5, 0.809017, 0.309017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.5, -0.809017, 0.309017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.5, 0.809017, -0.309017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.5, -0.809017, 0.309017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.5, 0.809017, -0.309017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.5, -0.809017, -0.309017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.5, -0.809017, -0.309017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.309017, 0.5, 0.809017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.309017, 0.5, 0.809017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.309017, -0.5, 0.809017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.309017, 0.5, -0.809017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.309017, -0.5, 0.809017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.309017, 0.5, -0.809017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.309017, -0.5, -0.809017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.309017, -0.5, -0.809017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.5, 0.5, 0.5)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(-0.5, 0.5, 0.5)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.5, -0.5, 0.5)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.5, 0.5, -0.5)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.5, 0.5, 0.5)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(-0.5, -0.5, 0.5)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(-0.5, 0.5, -0.5)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(-0.5, 0.5, 0.5)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.5, -0.5, -0.5)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.5, -0.5, 0.5)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.5, 0.5, -0.5)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(-0.5, -0.5, -0.5)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(-0.5, -0.5, 0.5)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(-0.5, 0.5, -0.5)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.5, -0.5, -0.5)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(-0.5, -0.5, -0.5))
  ]
  
  public static let Data60: [simd_quatd] =
  [
    simd_quatd(real: 0.0, imag: SIMD3<Double>(1.0, 0.0, 0.0)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.0, 1.0, 0.0)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.0, 0.0, 1.0)),
    simd_quatd(real: 1.0, imag: SIMD3<Double>(0.0, 0.0, 0.0)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(0.0, 0.5, 0.309017)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(0.0, -0.5, 0.309017)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(0.0, 0.5, -0.309017)),
    simd_quatd(real: -0.809017, imag: SIMD3<Double>(0.0, 0.5, 0.309017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.0, 0.309017, 0.809017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.0, -0.309017, 0.809017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.0, 0.309017, -0.809017)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.0, 0.309017, 0.809017)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(0.0, 0.809017, 0.5)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(0.0, -0.809017, 0.5)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(0.0, 0.809017, -0.5)),
    simd_quatd(real: -0.309017, imag: SIMD3<Double>(0.0, 0.809017, 0.5)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(0.5, 0.0, 0.809017)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(-0.5, 0.0, 0.809017)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(0.5, 0.0, -0.809017)),
    simd_quatd(real: -0.309017, imag: SIMD3<Double>(0.5, 0.0, 0.809017)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(0.309017, 0.0, 0.5)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(-0.309017, 0.0, 0.5)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(0.309017, 0.0, -0.5)),
    simd_quatd(real: -0.809017, imag: SIMD3<Double>(0.309017, 0.0, 0.5)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.809017, 0.0, 0.309017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(-0.809017, 0.0, 0.309017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.809017, 0.0, -0.309017)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.809017, 0.0, 0.309017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.309017, 0.809017, 0.0)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(-0.309017, 0.809017, 0.0)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.309017, -0.809017, 0.0)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.309017, 0.809017, 0.0)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(0.809017, 0.5, 0.0)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(-0.809017, 0.5, 0.0)),
    simd_quatd(real: 0.309017, imag: SIMD3<Double>(0.809017, -0.5, 0.0)),
    simd_quatd(real: -0.309017, imag: SIMD3<Double>(0.809017, 0.5, 0.0)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(0.5, 0.309017, 0.0)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(-0.5, 0.309017, 0.0)),
    simd_quatd(real: 0.809017, imag: SIMD3<Double>(0.5, -0.309017, 0.0)),
    simd_quatd(real: -0.809017, imag: SIMD3<Double>(0.5, 0.309017, 0.0)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.809017, 0.309017, 0.5)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.809017, 0.309017, 0.5)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.809017, -0.309017, 0.5)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.809017, 0.309017, -0.5)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.5, 0.809017, 0.309017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.5, 0.809017, 0.309017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.5, -0.809017, 0.309017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.5, 0.809017, -0.309017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.309017, 0.5, 0.809017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.309017, 0.5, 0.809017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.309017, -0.5, 0.809017)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.309017, 0.5, -0.809017)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.5, 0.5, 0.5)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(-0.5, 0.5, 0.5)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.5, -0.5, 0.5)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(0.5, 0.5, -0.5)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(0.5, 0.5, 0.5)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(-0.5, -0.5, 0.5)),
    simd_quatd(real: 0.5, imag: SIMD3<Double>(-0.5, 0.5, -0.5)),
    simd_quatd(real: -0.5, imag: SIMD3<Double>(-0.5, 0.5, 0.5))
  ]
  
  public static let Data600: [simd_quatd] =
  [
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.925615, 0.135045, 0.0)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.925615, -0.135045, 0.0)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.925615, 0.218508, 0.218508)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.925615, -0.218508, 0.218508)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.925615, 0.0, 0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.925615, 0.218508, -0.218508)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.925615, -0.218508, -0.218508)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.925615, 0.0, -0.353553)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.925615, 0.135045, 0.0)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.925615, -0.135045, 0.0)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.925615, 0.218508, 0.218508)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.925615, -0.218508, 0.218508)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.925615, 0.0, 0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.925615, 0.218508, -0.218508)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.925615, -0.218508, -0.218508)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.925615, 0.0, -0.353553)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.925615, 0.353553, 0.135045)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.925615, 0.353553, -0.135045)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.925615, -0.353553, 0.135045)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.925615, -0.353553, -0.135045)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.925615, 0.135045, 0.0)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.925615, -0.135045, 0.0)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.925615, 0.218508, 0.218508)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.925615, -0.218508, 0.218508)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(-0.925615, 0.0, 0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.925615, 0.218508, -0.218508)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.925615, -0.218508, -0.218508)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(-0.925615, 0.0, -0.353553)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.925615, 0.135045, 0.0)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.925615, -0.135045, 0.0)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.925615, 0.218508, 0.218508)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.925615, -0.218508, 0.218508)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(-0.925615, 0.0, 0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.925615, 0.218508, -0.218508)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.925615, -0.218508, -0.218508)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(-0.925615, 0.0, -0.353553)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.925615, 0.353553, 0.135045)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.925615, 0.353553, -0.135045)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.925615, -0.353553, 0.135045)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.925615, -0.353553, -0.135045)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.135045, 0.925615, 0.353553)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.135045, 0.925615, 0.353553)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.0, 0.925615, 0.135045)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.218508, 0.925615, 0.218508)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.218508, 0.925615, 0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.135045, 0.925615, -0.353553)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.135045, 0.925615, -0.353553)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.0, 0.925615, -0.135045)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.218508, 0.925615, -0.218508)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.218508, 0.925615, -0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.0, 0.925615, 0.135045)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.218508, 0.925615, 0.218508)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.218508, 0.925615, 0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.0, 0.925615, -0.135045)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.218508, 0.925615, -0.218508)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.218508, 0.925615, -0.218508)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.353553, 0.925615, 0.0)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(-0.353553, 0.925615, 0.0)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.353553, 0.925615, 0.0)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(-0.353553, 0.925615, 0.0)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.135045, -0.925615, 0.353553)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.135045, -0.925615, 0.353553)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.0, -0.925615, 0.135045)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.218508, -0.925615, 0.218508)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.218508, -0.925615, 0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.135045, -0.925615, -0.353553)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.135045, -0.925615, -0.353553)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.0, -0.925615, -0.135045)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.218508, -0.925615, -0.218508)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.218508, -0.925615, -0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.0, -0.925615, 0.135045)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.218508, -0.925615, 0.218508)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.218508, -0.925615, 0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.0, -0.925615, -0.135045)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.218508, -0.925615, -0.218508)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.218508, -0.925615, -0.218508)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.353553, -0.925615, 0.0)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(-0.353553, -0.925615, 0.0)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.353553, -0.925615, 0.0)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(-0.353553, -0.925615, 0.0)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.135045, 0.0, 0.925615)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.135045, 0.0, 0.925615)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.218508, 0.218508, 0.925615)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.218508, 0.218508, 0.925615)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.0, 0.353553, 0.925615)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.218508, -0.218508, 0.925615)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.218508, -0.218508, 0.925615)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.0, -0.353553, 0.925615)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.135045, 0.0, 0.925615)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.135045, 0.0, 0.925615)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.218508, 0.218508, 0.925615)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.218508, 0.218508, 0.925615)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.0, 0.353553, 0.925615)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.218508, -0.218508, 0.925615)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.218508, -0.218508, 0.925615)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.0, -0.353553, 0.925615)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.353553, 0.135045, 0.925615)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.353553, -0.135045, 0.925615)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.353553, 0.135045, 0.925615)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.353553, -0.135045, 0.925615)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.135045, 0.0, -0.925615)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.135045, 0.0, -0.925615)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.218508, 0.218508, -0.925615)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.218508, 0.218508, -0.925615)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.0, 0.353553, -0.925615)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.218508, -0.218508, -0.925615)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.218508, -0.218508, -0.925615)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.0, -0.353553, -0.925615)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.135045, 0.0, -0.925615)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.135045, 0.0, -0.925615)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.218508, 0.218508, -0.925615)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.218508, 0.218508, -0.925615)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.0, 0.353553, -0.925615)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.218508, -0.218508, -0.925615)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.218508, -0.218508, -0.925615)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.0, -0.353553, -0.925615)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.353553, 0.135045, -0.925615)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.353553, -0.135045, -0.925615)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.353553, 0.135045, -0.925615)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.353553, -0.135045, -0.925615)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.135045, 0.353553, 0.0)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.135045, 0.353553, 0.0)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.0, 0.135045, 0.353553)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.218508, 0.218508, 0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.218508, 0.218508, 0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.135045, -0.353553, 0.0)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.135045, -0.353553, 0.0)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.0, -0.135045, 0.353553)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.218508, -0.218508, 0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.218508, -0.218508, 0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.0, 0.135045, -0.353553)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.218508, 0.218508, -0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.218508, 0.218508, -0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.0, -0.135045, -0.353553)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.218508, -0.218508, -0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.218508, -0.218508, -0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.353553, 0.0, 0.135045)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.353553, 0.0, 0.135045)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.353553, 0.0, -0.135045)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.353553, 0.0, -0.135045)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(0.135045, 0.353553, 0.0)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(-0.135045, 0.353553, 0.0)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(0.0, 0.135045, 0.353553)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(0.218508, 0.218508, 0.218508)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(-0.218508, 0.218508, 0.218508)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(0.135045, -0.353553, 0.0)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(-0.135045, -0.353553, 0.0)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(0.0, -0.135045, 0.353553)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(0.218508, -0.218508, 0.218508)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(-0.218508, -0.218508, 0.218508)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(0.0, 0.135045, -0.353553)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(0.218508, 0.218508, -0.218508)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(-0.218508, 0.218508, -0.218508)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(0.0, -0.135045, -0.353553)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(0.218508, -0.218508, -0.218508)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(-0.218508, -0.218508, -0.218508)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(0.353553, 0.0, 0.135045)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(-0.353553, 0.0, 0.135045)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(0.353553, 0.0, -0.135045)),
    simd_quatd(real: -0.925615, imag: SIMD3<Double>(-0.353553, 0.0, -0.135045)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.0, 0.707107, 0.0)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.218508, 0.572061, 0.0)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(-0.218508, 0.572061, 0.0)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.135045, 0.572061, 0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.135045, 0.572061, 0.572061)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.0, 0.218508, 0.572061)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.218508, 0.353553, 0.572061)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.218508, 0.353553, 0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.0, 0.790569, 0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.218508, 0.707107, 0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.218508, 0.707107, 0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.353553, 0.353553, 0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(-0.353553, 0.353553, 0.353553)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.353553, 0.572061, 0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.353553, 0.572061, 0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.0, -0.707107, 0.0)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.218508, -0.572061, 0.0)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(-0.218508, -0.572061, 0.0)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.135045, -0.572061, 0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.135045, -0.572061, 0.572061)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.0, -0.218508, 0.572061)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.218508, -0.353553, 0.572061)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.218508, -0.353553, 0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.0, -0.790569, 0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.218508, -0.707107, 0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.218508, -0.707107, 0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.353553, -0.353553, 0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(-0.353553, -0.353553, 0.353553)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.353553, -0.572061, 0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.353553, -0.572061, 0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.135045, 0.572061, -0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.135045, 0.572061, -0.572061)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.0, 0.218508, -0.572061)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.218508, 0.353553, -0.572061)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.218508, 0.353553, -0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.0, 0.790569, -0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.218508, 0.707107, -0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.218508, 0.707107, -0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.353553, 0.353553, -0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(-0.353553, 0.353553, -0.353553)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.353553, 0.572061, -0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.353553, 0.572061, -0.218508)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.0, 0.707107, 0.0)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(0.218508, 0.572061, 0.0)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(-0.218508, 0.572061, 0.0)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.135045, 0.572061, 0.572061)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.135045, 0.572061, 0.572061)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(0.0, 0.218508, 0.572061)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.218508, 0.353553, 0.572061)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(-0.218508, 0.353553, 0.572061)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.0, 0.790569, 0.218508)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.218508, 0.707107, 0.353553)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.218508, 0.707107, 0.353553)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(0.353553, 0.353553, 0.353553)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(-0.353553, 0.353553, 0.353553)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.353553, 0.572061, 0.218508)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(-0.353553, 0.572061, 0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.135045, -0.572061, -0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.135045, -0.572061, -0.572061)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.0, -0.218508, -0.572061)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.218508, -0.353553, -0.572061)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.218508, -0.353553, -0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.0, -0.790569, -0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.218508, -0.707107, -0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.218508, -0.707107, -0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.353553, -0.353553, -0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(-0.353553, -0.353553, -0.353553)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.353553, -0.572061, -0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.353553, -0.572061, -0.218508)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.0, -0.707107, 0.0)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(0.218508, -0.572061, 0.0)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(-0.218508, -0.572061, 0.0)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.135045, -0.572061, 0.572061)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.135045, -0.572061, 0.572061)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(0.0, -0.218508, 0.572061)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.218508, -0.353553, 0.572061)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(-0.218508, -0.353553, 0.572061)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.0, -0.790569, 0.218508)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.218508, -0.707107, 0.353553)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.218508, -0.707107, 0.353553)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(0.353553, -0.353553, 0.353553)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(-0.353553, -0.353553, 0.353553)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.353553, -0.572061, 0.218508)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(-0.353553, -0.572061, 0.218508)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.135045, 0.572061, -0.572061)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.135045, 0.572061, -0.572061)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(0.0, 0.218508, -0.572061)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.218508, 0.353553, -0.572061)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(-0.218508, 0.353553, -0.572061)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.0, 0.790569, -0.218508)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.218508, 0.707107, -0.353553)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.218508, 0.707107, -0.353553)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(0.353553, 0.353553, -0.353553)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(-0.353553, 0.353553, -0.353553)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.353553, 0.572061, -0.218508)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(-0.353553, 0.572061, -0.218508)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.135045, -0.572061, -0.572061)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.135045, -0.572061, -0.572061)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(0.0, -0.218508, -0.572061)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.218508, -0.353553, -0.572061)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(-0.218508, -0.353553, -0.572061)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.0, -0.790569, -0.218508)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.218508, -0.707107, -0.353553)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.218508, -0.707107, -0.353553)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(0.353553, -0.353553, -0.353553)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(-0.353553, -0.353553, -0.353553)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.353553, -0.572061, -0.218508)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(-0.353553, -0.572061, -0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.218508, 0.0, 0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.218508, 0.0, 0.790569)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.0, 0.0, 0.707107)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.0, 0.572061, 0.790569)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.218508, 0.572061, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.218508, 0.572061, 0.707107)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.353553, 0.218508, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.353553, 0.353553, 0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.353553, 0.218508, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.353553, 0.353553, 0.790569)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.0, -0.572061, 0.790569)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.218508, -0.572061, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.218508, -0.572061, 0.707107)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.353553, -0.218508, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.353553, -0.353553, 0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.353553, -0.218508, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.353553, -0.353553, 0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.218508, 0.0, -0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.218508, 0.0, -0.790569)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.0, 0.0, -0.707107)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.0, 0.572061, -0.790569)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.218508, 0.572061, -0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.218508, 0.572061, -0.707107)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.353553, 0.218508, -0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.353553, 0.353553, -0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.353553, 0.218508, -0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.353553, 0.353553, -0.790569)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.218508, 0.0, 0.790569)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.218508, 0.0, 0.790569)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.0, 0.0, 0.707107)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.0, 0.572061, 0.790569)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.218508, 0.572061, 0.707107)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.218508, 0.572061, 0.707107)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.353553, 0.218508, 0.707107)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.353553, 0.353553, 0.790569)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.353553, 0.218508, 0.707107)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.353553, 0.353553, 0.790569)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.0, -0.572061, -0.790569)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.218508, -0.572061, -0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.218508, -0.572061, -0.707107)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.353553, -0.218508, -0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.353553, -0.353553, -0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.353553, -0.218508, -0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.353553, -0.353553, -0.790569)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.0, -0.572061, 0.790569)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.218508, -0.572061, 0.707107)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.218508, -0.572061, 0.707107)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.353553, -0.218508, 0.707107)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.353553, -0.353553, 0.790569)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.353553, -0.218508, 0.707107)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.353553, -0.353553, 0.790569)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.218508, 0.0, -0.790569)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.218508, 0.0, -0.790569)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.0, 0.0, -0.707107)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.0, 0.572061, -0.790569)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.218508, 0.572061, -0.707107)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.218508, 0.572061, -0.707107)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.353553, 0.218508, -0.707107)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.353553, 0.353553, -0.790569)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.353553, 0.218508, -0.707107)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.353553, 0.353553, -0.790569)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.0, -0.572061, -0.790569)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.218508, -0.572061, -0.707107)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.218508, -0.572061, -0.707107)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.353553, -0.218508, -0.707107)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.353553, -0.353553, -0.790569)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.353553, -0.218508, -0.707107)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.353553, -0.353553, -0.790569)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.218508, 0.790569, 0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.218508, 0.790569, 0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.0, 0.707107, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.353553, 0.790569, 0.353553)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.353553, 0.790569, 0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.353553, 0.707107, 0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.353553, 0.707107, 0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.218508, -0.790569, 0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.218508, -0.790569, 0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.0, -0.707107, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.353553, -0.790569, 0.353553)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.353553, -0.790569, 0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.353553, -0.707107, 0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.353553, -0.707107, 0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.218508, 0.790569, -0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.218508, 0.790569, -0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.0, 0.707107, -0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.353553, 0.790569, -0.353553)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.353553, 0.790569, -0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.353553, 0.707107, -0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.353553, 0.707107, -0.572061)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.353553, 0.790569, 0.353553)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.353553, 0.790569, 0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.353553, 0.707107, 0.572061)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.353553, 0.707107, 0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.218508, -0.790569, -0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.218508, -0.790569, -0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.0, -0.707107, -0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.353553, -0.790569, -0.353553)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.353553, -0.790569, -0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.353553, -0.707107, -0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.353553, -0.707107, -0.572061)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.353553, -0.790569, 0.353553)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.353553, -0.790569, 0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.353553, -0.707107, 0.572061)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.353553, -0.707107, 0.572061)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.353553, 0.790569, -0.353553)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.353553, 0.790569, -0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.353553, 0.707107, -0.572061)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.353553, 0.707107, -0.572061)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.353553, -0.790569, -0.353553)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.353553, -0.790569, -0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.353553, -0.707107, -0.572061)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.353553, -0.707107, -0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.707107, 0.0, 0.707107)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.572061, 0.218508, 0.790569)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.572061, -0.218508, 0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, 0.135045, 0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, -0.135045, 0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.790569, 0.0, 0.572061)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.707107, 0.218508, 0.572061)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.707107, -0.218508, 0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.572061, 0.353553, 0.707107)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.572061, -0.353553, 0.707107)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.707107, 0.0, 0.707107)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.572061, 0.218508, 0.790569)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.572061, -0.218508, 0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.572061, 0.135045, 0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.572061, -0.135045, 0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.790569, 0.0, 0.572061)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.707107, 0.218508, 0.572061)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.707107, -0.218508, 0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.572061, 0.353553, 0.707107)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.572061, -0.353553, 0.707107)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.707107, 0.0, -0.707107)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.572061, 0.218508, -0.790569)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.572061, -0.218508, -0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, 0.135045, -0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, -0.135045, -0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.790569, 0.0, -0.572061)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.707107, 0.218508, -0.572061)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.707107, -0.218508, -0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.572061, 0.353553, -0.707107)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.572061, -0.353553, -0.707107)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.572061, 0.135045, 0.572061)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.572061, -0.135045, 0.572061)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.790569, 0.0, 0.572061)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.707107, 0.218508, 0.572061)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.707107, -0.218508, 0.572061)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.572061, 0.353553, 0.707107)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.572061, -0.353553, 0.707107)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.707107, 0.0, -0.707107)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.572061, 0.218508, -0.790569)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.572061, -0.218508, -0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.572061, 0.135045, -0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.572061, -0.135045, -0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.790569, 0.0, -0.572061)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.707107, 0.218508, -0.572061)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.707107, -0.218508, -0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.572061, 0.353553, -0.707107)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.572061, -0.353553, -0.707107)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.572061, 0.135045, 0.572061)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.572061, -0.135045, 0.572061)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.790569, 0.0, 0.572061)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.707107, 0.218508, 0.572061)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.707107, -0.218508, 0.572061)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.572061, 0.353553, 0.707107)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.572061, -0.353553, 0.707107)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.572061, 0.135045, -0.572061)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.572061, -0.135045, -0.572061)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.790569, 0.0, -0.572061)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.707107, 0.218508, -0.572061)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.707107, -0.218508, -0.572061)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.572061, 0.353553, -0.707107)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.572061, -0.353553, -0.707107)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.572061, 0.135045, -0.572061)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.572061, -0.135045, -0.572061)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.790569, 0.0, -0.572061)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.707107, 0.218508, -0.572061)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.707107, -0.218508, -0.572061)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.572061, 0.353553, -0.707107)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.572061, -0.353553, -0.707107)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.572061, 0.0, 0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.572061, 0.218508, 0.353553)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.572061, -0.218508, 0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(-0.572061, 0.0, 0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.572061, 0.218508, 0.353553)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.572061, -0.218508, 0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.572061, 0.0, -0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.572061, 0.218508, -0.353553)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.572061, -0.218508, -0.353553)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(0.572061, 0.0, 0.218508)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.572061, 0.218508, 0.353553)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.572061, -0.218508, 0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(-0.572061, 0.0, -0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.572061, 0.218508, -0.353553)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.572061, -0.218508, -0.353553)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(-0.572061, 0.0, 0.218508)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(-0.572061, 0.218508, 0.353553)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(-0.572061, -0.218508, 0.353553)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(0.572061, 0.0, -0.218508)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.572061, 0.218508, -0.353553)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.572061, -0.218508, -0.353553)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(-0.572061, 0.0, -0.218508)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(-0.572061, 0.218508, -0.353553)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(-0.572061, -0.218508, -0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.790569, 0.218508, 0.0)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.790569, -0.218508, 0.0)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.707107, 0.0, 0.0)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.707107, 0.353553, 0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.790569, 0.353553, 0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.707107, -0.353553, 0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.790569, -0.353553, 0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.790569, 0.218508, 0.0)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.790569, -0.218508, 0.0)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.707107, 0.0, 0.0)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.707107, 0.353553, 0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.790569, 0.353553, 0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.707107, -0.353553, 0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.790569, -0.353553, 0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.707107, 0.353553, -0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.790569, 0.353553, -0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.707107, -0.353553, -0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.790569, -0.353553, -0.353553)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.790569, 0.218508, 0.0)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.790569, -0.218508, 0.0)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.707107, 0.0, 0.0)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.707107, 0.353553, 0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.790569, 0.353553, 0.353553)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.707107, -0.353553, 0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.790569, -0.353553, 0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.707107, 0.353553, -0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.790569, 0.353553, -0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.707107, -0.353553, -0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.790569, -0.353553, -0.353553)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.790569, 0.218508, 0.0)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.790569, -0.218508, 0.0)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(-0.707107, 0.0, 0.0)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.707107, 0.353553, 0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.790569, 0.353553, 0.353553)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.707107, -0.353553, 0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.790569, -0.353553, 0.353553)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.707107, 0.353553, -0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.790569, 0.353553, -0.353553)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.707107, -0.353553, -0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.790569, -0.353553, -0.353553)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.707107, 0.353553, -0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.790569, 0.353553, -0.353553)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.707107, -0.353553, -0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.790569, -0.353553, -0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, 0.572061, 0.135045)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, 0.572061, -0.135045)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.572061, 0.790569, 0.0)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.572061, 0.707107, 0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.572061, 0.707107, -0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.572061, 0.572061, 0.135045)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.572061, 0.572061, -0.135045)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.572061, 0.790569, 0.0)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.572061, 0.707107, 0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.572061, 0.707107, -0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, -0.572061, 0.135045)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, -0.572061, -0.135045)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.572061, -0.790569, 0.0)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.572061, -0.707107, 0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.572061, -0.707107, -0.218508)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.572061, 0.572061, 0.135045)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.572061, 0.572061, -0.135045)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.572061, 0.790569, 0.0)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.572061, 0.707107, 0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.572061, 0.707107, -0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.572061, -0.572061, 0.135045)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.572061, -0.572061, -0.135045)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.572061, -0.790569, 0.0)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.572061, -0.707107, 0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.572061, -0.707107, -0.218508)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.572061, 0.572061, 0.135045)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.572061, 0.572061, -0.135045)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.572061, 0.790569, 0.0)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.572061, 0.707107, 0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.572061, 0.707107, -0.218508)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.572061, -0.572061, 0.135045)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.572061, -0.572061, -0.135045)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.572061, -0.790569, 0.0)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.572061, -0.707107, 0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.572061, -0.707107, -0.218508)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.572061, -0.572061, 0.135045)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.572061, -0.572061, -0.135045)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.572061, -0.790569, 0.0)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.572061, -0.707107, 0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.572061, -0.707107, -0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.790569, 0.572061, 0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.790569, 0.572061, -0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.707107, 0.707107, 0.0)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.707107, 0.572061, 0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.707107, 0.572061, -0.353553)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.790569, 0.572061, 0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.790569, 0.572061, -0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.707107, 0.707107, 0.0)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.707107, 0.572061, 0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.707107, 0.572061, -0.353553)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.790569, -0.572061, 0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.790569, -0.572061, -0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.707107, -0.707107, 0.0)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.707107, -0.572061, 0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.707107, -0.572061, -0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.707107, 0.572061, 0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.707107, 0.572061, -0.353553)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.790569, -0.572061, 0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.790569, -0.572061, -0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.707107, -0.707107, 0.0)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.707107, -0.572061, 0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.707107, -0.572061, -0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.707107, 0.572061, 0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.707107, 0.572061, -0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.707107, -0.572061, 0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.707107, -0.572061, -0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.707107, -0.572061, 0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.707107, -0.572061, -0.353553)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.572061, 0.572061, 0.572061)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.572061, 0.572061, 0.572061)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(-0.572061, 0.572061, 0.572061)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(-0.572061, 0.572061, 0.572061)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.572061, -0.572061, 0.572061)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.572061, -0.572061, 0.572061)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.572061, 0.572061, -0.572061)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.572061, 0.572061, -0.572061)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(-0.572061, -0.572061, 0.572061)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(-0.572061, -0.572061, 0.572061)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(-0.572061, 0.572061, -0.572061)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(-0.572061, 0.572061, -0.572061)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.572061, -0.572061, -0.572061)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.572061, -0.572061, -0.572061)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(-0.572061, -0.572061, -0.572061)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(-0.572061, -0.572061, -0.572061))
  ]
  
  public static let Data300: [simd_quatd] =
  [
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.925615, 0.135045, 0.0)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.925615, -0.135045, 0.0)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.925615, 0.218508, 0.218508)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.925615, -0.218508, 0.218508)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.925615, 0.0, 0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.925615, 0.218508, -0.218508)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.925615, -0.218508, -0.218508)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.925615, 0.0, -0.353553)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.925615, 0.135045, 0.0)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.925615, -0.135045, 0.0)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.925615, 0.218508, 0.218508)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.925615, -0.218508, 0.218508)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.925615, 0.0, 0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.925615, 0.218508, -0.218508)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.925615, -0.218508, -0.218508)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.925615, 0.0, -0.353553)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.925615, 0.353553, 0.135045)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.925615, 0.353553, -0.135045)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.925615, -0.353553, 0.135045)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.925615, -0.353553, -0.135045)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.135045, 0.925615, 0.353553)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.135045, 0.925615, 0.353553)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.0, 0.925615, 0.135045)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.218508, 0.925615, 0.218508)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.218508, 0.925615, 0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.135045, 0.925615, -0.353553)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.135045, 0.925615, -0.353553)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.0, 0.925615, -0.135045)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.218508, 0.925615, -0.218508)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.218508, 0.925615, -0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.0, 0.925615, 0.135045)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.218508, 0.925615, 0.218508)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.218508, 0.925615, 0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.0, 0.925615, -0.135045)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.218508, 0.925615, -0.218508)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.218508, 0.925615, -0.218508)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.353553, 0.925615, 0.0)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(-0.353553, 0.925615, 0.0)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.353553, 0.925615, 0.0)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(-0.353553, 0.925615, 0.0)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.135045, 0.0, 0.925615)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.135045, 0.0, 0.925615)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.218508, 0.218508, 0.925615)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.218508, 0.218508, 0.925615)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.0, 0.353553, 0.925615)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.218508, -0.218508, 0.925615)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.218508, -0.218508, 0.925615)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.0, -0.353553, 0.925615)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.135045, 0.0, 0.925615)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.135045, 0.0, 0.925615)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.218508, 0.218508, 0.925615)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.218508, 0.218508, 0.925615)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.0, 0.353553, 0.925615)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.218508, -0.218508, 0.925615)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.218508, -0.218508, 0.925615)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.0, -0.353553, 0.925615)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.353553, 0.135045, 0.925615)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.353553, -0.135045, 0.925615)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.353553, 0.135045, 0.925615)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.353553, -0.135045, 0.925615)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.135045, 0.353553, 0.0)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.135045, 0.353553, 0.0)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.0, 0.135045, 0.353553)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.218508, 0.218508, 0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.218508, 0.218508, 0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.135045, -0.353553, 0.0)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.135045, -0.353553, 0.0)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.0, -0.135045, 0.353553)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.218508, -0.218508, 0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.218508, -0.218508, 0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.0, 0.135045, -0.353553)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.218508, 0.218508, -0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.218508, 0.218508, -0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.0, -0.135045, -0.353553)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.218508, -0.218508, -0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.218508, -0.218508, -0.218508)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.353553, 0.0, 0.135045)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.353553, 0.0, 0.135045)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(0.353553, 0.0, -0.135045)),
    simd_quatd(real: 0.925615, imag: SIMD3<Double>(-0.353553, 0.0, -0.135045)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.0, 0.707107, 0.0)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.218508, 0.572061, 0.0)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(-0.218508, 0.572061, 0.0)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.135045, 0.572061, 0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.135045, 0.572061, 0.572061)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.0, 0.218508, 0.572061)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.218508, 0.353553, 0.572061)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.218508, 0.353553, 0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.0, 0.790569, 0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.218508, 0.707107, 0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.218508, 0.707107, 0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.353553, 0.353553, 0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(-0.353553, 0.353553, 0.353553)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.353553, 0.572061, 0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.353553, 0.572061, 0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.0, -0.707107, 0.0)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.218508, -0.572061, 0.0)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(-0.218508, -0.572061, 0.0)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.135045, -0.572061, 0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.135045, -0.572061, 0.572061)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.0, -0.218508, 0.572061)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.218508, -0.353553, 0.572061)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.218508, -0.353553, 0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.0, -0.790569, 0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.218508, -0.707107, 0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.218508, -0.707107, 0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.353553, -0.353553, 0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(-0.353553, -0.353553, 0.353553)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.353553, -0.572061, 0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.353553, -0.572061, 0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.135045, 0.572061, -0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.135045, 0.572061, -0.572061)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.0, 0.218508, -0.572061)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.218508, 0.353553, -0.572061)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.218508, 0.353553, -0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.0, 0.790569, -0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.218508, 0.707107, -0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.218508, 0.707107, -0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.353553, 0.353553, -0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(-0.353553, 0.353553, -0.353553)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.353553, 0.572061, -0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.353553, 0.572061, -0.218508)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.135045, 0.572061, 0.572061)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.135045, 0.572061, 0.572061)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(0.0, 0.218508, 0.572061)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.218508, 0.353553, 0.572061)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(-0.218508, 0.353553, 0.572061)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.0, 0.790569, 0.218508)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.218508, 0.707107, 0.353553)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.218508, 0.707107, 0.353553)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(0.353553, 0.353553, 0.353553)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(-0.353553, 0.353553, 0.353553)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.353553, 0.572061, 0.218508)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(-0.353553, 0.572061, 0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.218508, 0.0, 0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.218508, 0.0, 0.790569)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.0, 0.0, 0.707107)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.0, 0.572061, 0.790569)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.218508, 0.572061, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.218508, 0.572061, 0.707107)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.353553, 0.218508, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.353553, 0.353553, 0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.353553, 0.218508, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.353553, 0.353553, 0.790569)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.0, -0.572061, 0.790569)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.218508, -0.572061, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.218508, -0.572061, 0.707107)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.353553, -0.218508, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.353553, -0.353553, 0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.353553, -0.218508, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.353553, -0.353553, 0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.218508, 0.0, -0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.218508, 0.0, -0.790569)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.0, 0.0, -0.707107)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.0, 0.572061, -0.790569)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.218508, 0.572061, -0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.218508, 0.572061, -0.707107)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.353553, 0.218508, -0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.353553, 0.353553, -0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.353553, 0.218508, -0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.353553, 0.353553, -0.790569)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.0, 0.572061, 0.790569)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.218508, 0.572061, 0.707107)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.218508, 0.572061, 0.707107)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.353553, 0.218508, 0.707107)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.353553, 0.353553, 0.790569)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(-0.353553, 0.218508, 0.707107)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.353553, 0.353553, 0.790569)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.218508, 0.790569, 0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.218508, 0.790569, 0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.0, 0.707107, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.353553, 0.790569, 0.353553)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.353553, 0.790569, 0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.353553, 0.707107, 0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.353553, 0.707107, 0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.218508, -0.790569, 0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.218508, -0.790569, 0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.0, -0.707107, 0.707107)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.353553, -0.790569, 0.353553)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.353553, -0.790569, 0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.353553, -0.707107, 0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.353553, -0.707107, 0.572061)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.353553, 0.790569, -0.353553)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.353553, 0.790569, -0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.353553, 0.707107, -0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.353553, 0.707107, -0.572061)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.353553, 0.790569, 0.353553)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(-0.353553, 0.790569, 0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.353553, 0.707107, 0.572061)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(-0.353553, 0.707107, 0.572061)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.707107, 0.0, 0.707107)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.572061, 0.218508, 0.790569)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.572061, -0.218508, 0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, 0.135045, 0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, -0.135045, 0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.790569, 0.0, 0.572061)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.707107, 0.218508, 0.572061)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.707107, -0.218508, 0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.572061, 0.353553, 0.707107)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.572061, -0.353553, 0.707107)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.707107, 0.0, 0.707107)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.572061, 0.218508, 0.790569)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.572061, -0.218508, 0.790569)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.572061, 0.135045, 0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.572061, -0.135045, 0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.790569, 0.0, 0.572061)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.707107, 0.218508, 0.572061)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.707107, -0.218508, 0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.572061, 0.353553, 0.707107)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.572061, -0.353553, 0.707107)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, 0.135045, -0.572061)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, -0.135045, -0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.790569, 0.0, -0.572061)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.707107, 0.218508, -0.572061)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.707107, -0.218508, -0.572061)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.572061, 0.353553, -0.707107)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.572061, -0.353553, -0.707107)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.572061, 0.135045, 0.572061)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.572061, -0.135045, 0.572061)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.790569, 0.0, 0.572061)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.707107, 0.218508, 0.572061)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.707107, -0.218508, 0.572061)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.572061, 0.353553, 0.707107)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.572061, -0.353553, 0.707107)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.572061, 0.0, 0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.572061, 0.218508, 0.353553)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.572061, -0.218508, 0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(-0.572061, 0.0, 0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.572061, 0.218508, 0.353553)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.572061, -0.218508, 0.353553)),
    simd_quatd(real: 0.790569, imag: SIMD3<Double>(0.572061, 0.0, -0.218508)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.572061, 0.218508, -0.353553)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.572061, -0.218508, -0.353553)),
    simd_quatd(real: -0.790569, imag: SIMD3<Double>(0.572061, 0.0, 0.218508)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.572061, 0.218508, 0.353553)),
    simd_quatd(real: -0.707107, imag: SIMD3<Double>(0.572061, -0.218508, 0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.790569, 0.218508, 0.0)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.790569, -0.218508, 0.0)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(0.707107, 0.0, 0.0)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.707107, 0.353553, 0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.790569, 0.353553, 0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.707107, -0.353553, 0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.790569, -0.353553, 0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.790569, 0.218508, 0.0)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.790569, -0.218508, 0.0)),
    simd_quatd(real: 0.707107, imag: SIMD3<Double>(-0.707107, 0.0, 0.0)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.707107, 0.353553, 0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.790569, 0.353553, 0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.707107, -0.353553, 0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.790569, -0.353553, 0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.707107, 0.353553, -0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.790569, 0.353553, -0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.707107, -0.353553, -0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.790569, -0.353553, -0.353553)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.707107, 0.353553, 0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.790569, 0.353553, 0.353553)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.707107, -0.353553, 0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.790569, -0.353553, 0.353553)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, 0.572061, 0.135045)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, 0.572061, -0.135045)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.572061, 0.790569, 0.0)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.572061, 0.707107, 0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.572061, 0.707107, -0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.572061, 0.572061, 0.135045)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(-0.572061, 0.572061, -0.135045)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.572061, 0.790569, 0.0)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.572061, 0.707107, 0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(-0.572061, 0.707107, -0.218508)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, -0.572061, 0.135045)),
    simd_quatd(real: 0.572061, imag: SIMD3<Double>(0.572061, -0.572061, -0.135045)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.572061, -0.790569, 0.0)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.572061, -0.707107, 0.218508)),
    simd_quatd(real: 0.353553, imag: SIMD3<Double>(0.572061, -0.707107, -0.218508)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.572061, 0.572061, 0.135045)),
    simd_quatd(real: -0.572061, imag: SIMD3<Double>(0.572061, 0.572061, -0.135045)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.572061, 0.790569, 0.0)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.572061, 0.707107, 0.218508)),
    simd_quatd(real: -0.353553, imag: SIMD3<Double>(0.572061, 0.707107, -0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.790569, 0.572061, 0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.790569, 0.572061, -0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(0.707107, 0.707107, 0.0)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.707107, 0.572061, 0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.707107, 0.572061, -0.353553)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.790569, 0.572061, 0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.790569, 0.572061, -0.218508)),
    simd_quatd(real: 0.0, imag: SIMD3<Double>(-0.707107, 0.707107, 0.0)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.707107, 0.572061, 0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(-0.707107, 0.572061, -0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.707107, -0.572061, 0.353553)),
    simd_quatd(real: 0.218508, imag: SIMD3<Double>(0.707107, -0.572061, -0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.707107, 0.572061, 0.353553)),
    simd_quatd(real: -0.218508, imag: SIMD3<Double>(0.707107, 0.572061, -0.353553)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.572061, 0.572061, 0.572061)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.572061, 0.572061, 0.572061)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(-0.572061, 0.572061, 0.572061)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(-0.572061, 0.572061, 0.572061)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.572061, -0.572061, 0.572061)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.572061, -0.572061, 0.572061)),
    simd_quatd(real: 0.135045, imag: SIMD3<Double>(0.572061, 0.572061, -0.572061)),
    simd_quatd(real: -0.135045, imag: SIMD3<Double>(0.572061, 0.572061, -0.572061))
  ]
  
    private static let Data1992_1 = simd_quatd(ix: 0.000000000 , iy: 0.000000000 , iz: 0.000000000 , r: 1.000000000)
  private static let Data1992_2 = simd_quatd(ix: 0.126685455 , iy: 0.126685455 , iz: 0.126685455 , r: 0.975629226)
  private static let Data1992_3 = simd_quatd(ix: -0.126685455 , iy: 0.126685455 , iz: 0.126685455 , r: 0.975629226)
  private static let Data1992_4 = simd_quatd(ix: 0.126685455 , iy: -0.126685455 , iz: 0.126685455 , r: 0.975629226)
  private static let Data1992_5 = simd_quatd(ix: -0.126685455 , iy: -0.126685455 , iz: 0.126685455 , r: 0.975629226)
  private static let Data1992_6 = simd_quatd(ix: 0.126685455 , iy: 0.126685455 , iz: -0.126685455 , r: 0.975629226)
  private static let Data1992_7 = simd_quatd(ix: -0.126685455 , iy: 0.126685455 , iz: -0.126685455 , r: 0.975629226)
  private static let Data1992_8 = simd_quatd(ix: 0.126685455 , iy: -0.126685455 , iz: -0.126685455 , r: 0.975629226)
  private static let Data1992_9 = simd_quatd(ix: -0.126685455 , iy: -0.126685455 , iz: -0.126685455 , r: 0.975629226)
  private static let Data1992_10 = simd_quatd(ix: 0.251361860 , iy: 0.000000000 , iz: 0.000000000 , r: 0.967893184)
  private static let Data1992_11 = simd_quatd(ix: -0.251361860 , iy: 0.000000000 , iz: 0.000000000 , r: 0.967893184)
  private static let Data1992_12 = simd_quatd(ix: 0.000000000 , iy: 0.000000000 , iz: 0.251361860 , r: 0.967893184)
  private static let Data1992_13 = simd_quatd(ix: 0.000000000 , iy: 0.251361860 , iz: 0.000000000 , r: 0.967893184)
  private static let Data1992_14 = simd_quatd(ix: 0.000000000 , iy: 0.000000000 , iz: -0.251361860 , r: 0.967893184)
  private static let Data1992_15 = simd_quatd(ix: 0.000000000 , iy: -0.251361860 , iz: 0.000000000 , r: 0.967893184)
  private static let Data1992_16 = simd_quatd(ix: 0.243778507 , iy: 0.243778507 , iz: 0.000000000 , r: 0.938692750)
  private static let Data1992_17 = simd_quatd(ix: -0.243778507 , iy: 0.243778507 , iz: 0.000000000 , r: 0.938692750)
  private static let Data1992_18 = simd_quatd(ix: 0.243778507 , iy: -0.243778507 , iz: 0.000000000 , r: 0.938692750)
  private static let Data1992_19 = simd_quatd(ix: -0.243778507 , iy: -0.243778507 , iz: 0.000000000 , r: 0.938692750)
  private static let Data1992_20 = simd_quatd(ix: 0.243778507 , iy: 0.000000000 , iz: 0.243778507 , r: 0.938692750)
  private static let Data1992_21 = simd_quatd(ix: 0.000000000 , iy: 0.243778507 , iz: 0.243778507 , r: 0.938692750)
  private static let Data1992_22 = simd_quatd(ix: 0.243778507 , iy: 0.000000000 , iz: -0.243778507 , r: 0.938692750)
  private static let Data1992_23 = simd_quatd(ix: 0.000000000 , iy: -0.243778507 , iz: 0.243778507 , r: 0.938692750)
  private static let Data1992_24 = simd_quatd(ix: -0.243778507 , iy: 0.000000000 , iz: 0.243778507 , r: 0.938692750)
  private static let Data1992_25 = simd_quatd(ix: 0.000000000 , iy: 0.243778507 , iz: -0.243778507 , r: 0.938692750)
  private static let Data1992_26 = simd_quatd(ix: -0.243778507 , iy: 0.000000000 , iz: -0.243778507 , r: 0.938692750)
  private static let Data1992_27 = simd_quatd(ix: 0.000000000 , iy: -0.243778507 , iz: -0.243778507 , r: 0.938692750)
  private static let Data1992_28 = simd_quatd(ix: 0.236842533 , iy: 0.236842533 , iz: 0.236842533 , r: 0.911985111)
  private static let Data1992_29 = simd_quatd(ix: -0.236842533 , iy: 0.236842533 , iz: 0.236842533 , r: 0.911985111)
  private static let Data1992_30 = simd_quatd(ix: 0.236842533 , iy: -0.236842533 , iz: 0.236842533 , r: 0.911985111)
  private static let Data1992_31 = simd_quatd(ix: -0.236842533 , iy: -0.236842533 , iz: 0.236842533 , r: 0.911985111)
  private static let Data1992_32 = simd_quatd(ix: 0.236842533 , iy: 0.236842533 , iz: -0.236842533 , r: 0.911985111)
  private static let Data1992_33 = simd_quatd(ix: -0.236842533 , iy: 0.236842533 , iz: -0.236842533 , r: 0.911985111)
  private static let Data1992_34 = simd_quatd(ix: 0.236842533 , iy: -0.236842533 , iz: -0.236842533 , r: 0.911985111)
  private static let Data1992_35 = simd_quatd(ix: -0.236842533 , iy: -0.236842533 , iz: -0.236842533 , r: 0.911985111)
  private static let Data1992_36 = simd_quatd(ix: 0.357781348 , iy: 0.119260449 , iz: 0.119260449 , r: 0.918447820)
  private static let Data1992_37 = simd_quatd(ix: -0.357781348 , iy: 0.119260449 , iz: 0.119260449 , r: 0.918447820)
  private static let Data1992_38 = simd_quatd(ix: 0.357781348 , iy: -0.119260449 , iz: 0.119260449 , r: 0.918447820)
  private static let Data1992_39 = simd_quatd(ix: -0.357781348 , iy: -0.119260449 , iz: 0.119260449 , r: 0.918447820)
  private static let Data1992_40 = simd_quatd(ix: 0.357781348 , iy: 0.119260449 , iz: -0.119260449 , r: 0.918447820)
  private static let Data1992_41 = simd_quatd(ix: -0.357781348 , iy: 0.119260449 , iz: -0.119260449 , r: 0.918447820)
  private static let Data1992_42 = simd_quatd(ix: 0.357781348 , iy: -0.119260449 , iz: -0.119260449 , r: 0.918447820)
  private static let Data1992_43 = simd_quatd(ix: -0.357781348 , iy: -0.119260449 , iz: -0.119260449 , r: 0.918447820)
  private static let Data1992_44 = simd_quatd(ix: 0.119260449 , iy: 0.119260449 , iz: 0.357781348 , r: 0.918447820)
  private static let Data1992_45 = simd_quatd(ix: 0.119260449 , iy: 0.357781348 , iz: 0.119260449 , r: 0.918447820)
  private static let Data1992_46 = simd_quatd(ix: 0.119260449 , iy: 0.119260449 , iz: -0.357781348 , r: 0.918447820)
  private static let Data1992_47 = simd_quatd(ix: 0.119260449 , iy: -0.357781348 , iz: 0.119260449 , r: 0.918447820)
  private static let Data1992_48 = simd_quatd(ix: -0.119260449 , iy: 0.119260449 , iz: 0.357781348 , r: 0.918447820)
  private static let Data1992_49 = simd_quatd(ix: 0.119260449 , iy: 0.357781348 , iz: -0.119260449 , r: 0.918447820)
  private static let Data1992_50 = simd_quatd(ix: -0.119260449 , iy: 0.119260449 , iz: -0.357781348 , r: 0.918447820)
  private static let Data1992_51 = simd_quatd(ix: 0.119260449 , iy: -0.357781348 , iz: -0.119260449 , r: 0.918447820)
  private static let Data1992_52 = simd_quatd(ix: 0.119260449 , iy: -0.119260449 , iz: 0.357781348 , r: 0.918447820)
  private static let Data1992_53 = simd_quatd(ix: -0.119260449 , iy: 0.357781348 , iz: 0.119260449 , r: 0.918447820)
  private static let Data1992_54 = simd_quatd(ix: 0.119260449 , iy: -0.119260449 , iz: -0.357781348 , r: 0.918447820)
  private static let Data1992_55 = simd_quatd(ix: -0.119260449 , iy: -0.357781348 , iz: 0.119260449 , r: 0.918447820)
  private static let Data1992_56 = simd_quatd(ix: -0.119260449 , iy: -0.119260449 , iz: 0.357781348 , r: 0.918447820)
  private static let Data1992_57 = simd_quatd(ix: -0.119260449 , iy: 0.357781348 , iz: -0.119260449 , r: 0.918447820)
  private static let Data1992_58 = simd_quatd(ix: -0.119260449 , iy: -0.119260449 , iz: -0.357781348 , r: 0.918447820)
  private static let Data1992_59 = simd_quatd(ix: -0.119260449 , iy: -0.357781348 , iz: -0.119260449 , r: 0.918447820)
  private static let Data1992_60 = simd_quatd(ix: 0.339013602 , iy: 0.339013602 , iz: 0.113004534 , r: 0.870269803)
  private static let Data1992_61 = simd_quatd(ix: -0.339013602 , iy: 0.339013602 , iz: 0.113004534 , r: 0.870269803)
  private static let Data1992_62 = simd_quatd(ix: 0.339013602 , iy: -0.339013602 , iz: 0.113004534 , r: 0.870269803)
  private static let Data1992_63 = simd_quatd(ix: -0.339013602 , iy: -0.339013602 , iz: 0.113004534 , r: 0.870269803)
  private static let Data1992_64 = simd_quatd(ix: 0.339013602 , iy: 0.339013602 , iz: -0.113004534 , r: 0.870269803)
  private static let Data1992_65 = simd_quatd(ix: -0.339013602 , iy: 0.339013602 , iz: -0.113004534 , r: 0.870269803)
  private static let Data1992_66 = simd_quatd(ix: 0.339013602 , iy: -0.339013602 , iz: -0.113004534 , r: 0.870269803)
  private static let Data1992_67 = simd_quatd(ix: -0.339013602 , iy: -0.339013602 , iz: -0.113004534 , r: 0.870269803)
  private static let Data1992_68 = simd_quatd(ix: 0.339013602 , iy: 0.113004534 , iz: 0.339013602 , r: 0.870269803)
  private static let Data1992_69 = simd_quatd(ix: 0.113004534 , iy: 0.339013602 , iz: 0.339013602 , r: 0.870269803)
  private static let Data1992_70 = simd_quatd(ix: 0.339013602 , iy: 0.113004534 , iz: -0.339013602 , r: 0.870269803)
  private static let Data1992_71 = simd_quatd(ix: 0.113004534 , iy: -0.339013602 , iz: 0.339013602 , r: 0.870269803)
  private static let Data1992_72 = simd_quatd(ix: -0.339013602 , iy: 0.113004534 , iz: 0.339013602 , r: 0.870269803)
  private static let Data1992_73 = simd_quatd(ix: 0.113004534 , iy: 0.339013602 , iz: -0.339013602 , r: 0.870269803)
  private static let Data1992_74 = simd_quatd(ix: -0.339013602 , iy: 0.113004534 , iz: -0.339013602 , r: 0.870269803)
  private static let Data1992_75 = simd_quatd(ix: 0.113004534 , iy: -0.339013602 , iz: -0.339013602 , r: 0.870269803)
  private static let Data1992_76 = simd_quatd(ix: 0.339013602 , iy: -0.113004534 , iz: 0.339013602 , r: 0.870269803)
  private static let Data1992_77 = simd_quatd(ix: -0.113004534 , iy: 0.339013602 , iz: 0.339013602 , r: 0.870269803)
  private static let Data1992_78 = simd_quatd(ix: 0.339013602 , iy: -0.113004534 , iz: -0.339013602 , r: 0.870269803)
  private static let Data1992_79 = simd_quatd(ix: -0.113004534 , iy: -0.339013602 , iz: 0.339013602 , r: 0.870269803)
  private static let Data1992_80 = simd_quatd(ix: -0.339013602 , iy: -0.113004534 , iz: 0.339013602 , r: 0.870269803)
  private static let Data1992_81 = simd_quatd(ix: -0.113004534 , iy: 0.339013602 , iz: -0.339013602 , r: 0.870269803)
  private static let Data1992_82 = simd_quatd(ix: -0.339013602 , iy: -0.113004534 , iz: -0.339013602 , r: 0.870269803)
  private static let Data1992_83 = simd_quatd(ix: -0.113004534 , iy: -0.339013602 , iz: -0.339013602 , r: 0.870269803)
  private static let Data1992_84 = simd_quatd(ix: 1.000000000 , iy: 0.000000000 , iz: 0.000000000 , r: 0.000000000)
  private static let Data1992_85 = simd_quatd(ix: 0.975629226 , iy: -0.126685455 , iz: 0.126685455 , r: -0.126685455)
  private static let Data1992_86 = simd_quatd(ix: 0.975629226 , iy: -0.126685455 , iz: 0.126685455 , r: 0.126685455)
  private static let Data1992_87 = simd_quatd(ix: 0.975629226 , iy: -0.126685455 , iz: -0.126685455 , r: -0.126685455)
  private static let Data1992_88 = simd_quatd(ix: 0.975629226 , iy: -0.126685455 , iz: -0.126685455 , r: 0.126685455)
  private static let Data1992_89 = simd_quatd(ix: 0.975629226 , iy: 0.126685455 , iz: 0.126685455 , r: -0.126685455)
  private static let Data1992_90 = simd_quatd(ix: 0.975629226 , iy: 0.126685455 , iz: 0.126685455 , r: 0.126685455)
  private static let Data1992_91 = simd_quatd(ix: 0.975629226 , iy: 0.126685455 , iz: -0.126685455 , r: -0.126685455)
  private static let Data1992_92 = simd_quatd(ix: 0.975629226 , iy: 0.126685455 , iz: -0.126685455 , r: 0.126685455)
  private static let Data1992_93 = simd_quatd(ix: 0.967893184 , iy: 0.000000000 , iz: 0.000000000 , r: -0.251361860)
  private static let Data1992_94 = simd_quatd(ix: 0.967893184 , iy: 0.000000000 , iz: 0.000000000 , r: 0.251361860)
  private static let Data1992_95 = simd_quatd(ix: 0.967893184 , iy: -0.251361860 , iz: 0.000000000 , r: 0.000000000)
  private static let Data1992_96 = simd_quatd(ix: 0.967893184 , iy: 0.000000000 , iz: 0.251361860 , r: 0.000000000)
  private static let Data1992_97 = simd_quatd(ix: 0.967893184 , iy: 0.251361860 , iz: 0.000000000 , r: 0.000000000)
  private static let Data1992_98 = simd_quatd(ix: 0.967893184 , iy: 0.000000000 , iz: -0.251361860 , r: 0.000000000)
  private static let Data1992_99 = simd_quatd(ix: 0.938692750 , iy: 0.000000000 , iz: 0.243778507 , r: -0.243778507)
  private static let Data1992_100 = simd_quatd(ix: 0.938692750 , iy: 0.000000000 , iz: 0.243778507 , r: 0.243778507)
  private static let Data1992_101 = simd_quatd(ix: 0.938692750 , iy: 0.000000000 , iz: -0.243778507 , r: -0.243778507)
  private static let Data1992_102 = simd_quatd(ix: 0.938692750 , iy: 0.000000000 , iz: -0.243778507 , r: 0.243778507)
  private static let Data1992_103 = simd_quatd(ix: 0.938692750 , iy: -0.243778507 , iz: 0.000000000 , r: -0.243778507)
  private static let Data1992_104 = simd_quatd(ix: 0.938692750 , iy: -0.243778507 , iz: 0.243778507 , r: 0.000000000)
  private static let Data1992_105 = simd_quatd(ix: 0.938692750 , iy: 0.243778507 , iz: 0.000000000 , r: -0.243778507)
  private static let Data1992_106 = simd_quatd(ix: 0.938692750 , iy: -0.243778507 , iz: -0.243778507 , r: 0.000000000)
  private static let Data1992_107 = simd_quatd(ix: 0.938692750 , iy: -0.243778507 , iz: 0.000000000 , r: 0.243778507)
  private static let Data1992_108 = simd_quatd(ix: 0.938692750 , iy: 0.243778507 , iz: 0.243778507 , r: 0.000000000)
  private static let Data1992_109 = simd_quatd(ix: 0.938692750 , iy: 0.243778507 , iz: 0.000000000 , r: 0.243778507)
  private static let Data1992_110 = simd_quatd(ix: 0.938692750 , iy: 0.243778507 , iz: -0.243778507 , r: 0.000000000)
  private static let Data1992_111 = simd_quatd(ix: 0.911985111 , iy: -0.236842533 , iz: 0.236842533 , r: -0.236842533)
  private static let Data1992_112 = simd_quatd(ix: 0.911985111 , iy: -0.236842533 , iz: 0.236842533 , r: 0.236842533)
  private static let Data1992_113 = simd_quatd(ix: 0.911985111 , iy: -0.236842533 , iz: -0.236842533 , r: -0.236842533)
  private static let Data1992_114 = simd_quatd(ix: 0.911985111 , iy: -0.236842533 , iz: -0.236842533 , r: 0.236842533)
  private static let Data1992_115 = simd_quatd(ix: 0.911985111 , iy: 0.236842533 , iz: 0.236842533 , r: -0.236842533)
  private static let Data1992_116 = simd_quatd(ix: 0.911985111 , iy: 0.236842533 , iz: 0.236842533 , r: 0.236842533)
  private static let Data1992_117 = simd_quatd(ix: 0.911985111 , iy: 0.236842533 , iz: -0.236842533 , r: -0.236842533)
  private static let Data1992_118 = simd_quatd(ix: 0.911985111 , iy: 0.236842533 , iz: -0.236842533 , r: 0.236842533)
  private static let Data1992_119 = simd_quatd(ix: 0.918447820 , iy: -0.119260449 , iz: 0.119260449 , r: -0.357781348)
  private static let Data1992_120 = simd_quatd(ix: 0.918447820 , iy: -0.119260449 , iz: 0.119260449 , r: 0.357781348)
  private static let Data1992_121 = simd_quatd(ix: 0.918447820 , iy: -0.119260449 , iz: -0.119260449 , r: -0.357781348)
  private static let Data1992_122 = simd_quatd(ix: 0.918447820 , iy: -0.119260449 , iz: -0.119260449 , r: 0.357781348)
  private static let Data1992_123 = simd_quatd(ix: 0.918447820 , iy: 0.119260449 , iz: 0.119260449 , r: -0.357781348)
  private static let Data1992_124 = simd_quatd(ix: 0.918447820 , iy: 0.119260449 , iz: 0.119260449 , r: 0.357781348)
  private static let Data1992_125 = simd_quatd(ix: 0.918447820 , iy: 0.119260449 , iz: -0.119260449 , r: -0.357781348)
  private static let Data1992_126 = simd_quatd(ix: 0.918447820 , iy: 0.119260449 , iz: -0.119260449 , r: 0.357781348)
  private static let Data1992_127 = simd_quatd(ix: 0.918447820 , iy: -0.357781348 , iz: 0.119260449 , r: -0.119260449)
  private static let Data1992_128 = simd_quatd(ix: 0.918447820 , iy: -0.119260449 , iz: 0.357781348 , r: -0.119260449)
  private static let Data1992_129 = simd_quatd(ix: 0.918447820 , iy: 0.357781348 , iz: 0.119260449 , r: -0.119260449)
  private static let Data1992_130 = simd_quatd(ix: 0.918447820 , iy: -0.119260449 , iz: -0.357781348 , r: -0.119260449)
  private static let Data1992_131 = simd_quatd(ix: 0.918447820 , iy: -0.357781348 , iz: 0.119260449 , r: 0.119260449)
  private static let Data1992_132 = simd_quatd(ix: 0.918447820 , iy: 0.119260449 , iz: 0.357781348 , r: -0.119260449)
  private static let Data1992_133 = simd_quatd(ix: 0.918447820 , iy: 0.357781348 , iz: 0.119260449 , r: 0.119260449)
  private static let Data1992_134 = simd_quatd(ix: 0.918447820 , iy: 0.119260449 , iz: -0.357781348 , r: -0.119260449)
  private static let Data1992_135 = simd_quatd(ix: 0.918447820 , iy: -0.357781348 , iz: -0.119260449 , r: -0.119260449)
  private static let Data1992_136 = simd_quatd(ix: 0.918447820 , iy: -0.119260449 , iz: 0.357781348 , r: 0.119260449)
  private static let Data1992_137 = simd_quatd(ix: 0.918447820 , iy: 0.357781348 , iz: -0.119260449 , r: -0.119260449)
  private static let Data1992_138 = simd_quatd(ix: 0.918447820 , iy: -0.119260449 , iz: -0.357781348 , r: 0.119260449)
  private static let Data1992_139 = simd_quatd(ix: 0.918447820 , iy: -0.357781348 , iz: -0.119260449 , r: 0.119260449)
  private static let Data1992_140 = simd_quatd(ix: 0.918447820 , iy: 0.119260449 , iz: 0.357781348 , r: 0.119260449)
  private static let Data1992_141 = simd_quatd(ix: 0.918447820 , iy: 0.357781348 , iz: -0.119260449 , r: 0.119260449)
  private static let Data1992_142 = simd_quatd(ix: 0.918447820 , iy: 0.119260449 , iz: -0.357781348 , r: 0.119260449)
  private static let Data1992_143 = simd_quatd(ix: 0.870269803 , iy: -0.113004534 , iz: 0.339013602 , r: -0.339013602)
  private static let Data1992_144 = simd_quatd(ix: 0.870269803 , iy: -0.113004534 , iz: 0.339013602 , r: 0.339013602)
  private static let Data1992_145 = simd_quatd(ix: 0.870269803 , iy: -0.113004534 , iz: -0.339013602 , r: -0.339013602)
  private static let Data1992_146 = simd_quatd(ix: 0.870269803 , iy: -0.113004534 , iz: -0.339013602 , r: 0.339013602)
  private static let Data1992_147 = simd_quatd(ix: 0.870269803 , iy: 0.113004534 , iz: 0.339013602 , r: -0.339013602)
  private static let Data1992_148 = simd_quatd(ix: 0.870269803 , iy: 0.113004534 , iz: 0.339013602 , r: 0.339013602)
  private static let Data1992_149 = simd_quatd(ix: 0.870269803 , iy: 0.113004534 , iz: -0.339013602 , r: -0.339013602)
  private static let Data1992_150 = simd_quatd(ix: 0.870269803 , iy: 0.113004534 , iz: -0.339013602 , r: 0.339013602)
  private static let Data1992_151 = simd_quatd(ix: 0.870269803 , iy: -0.339013602 , iz: 0.113004534 , r: -0.339013602)
  private static let Data1992_152 = simd_quatd(ix: 0.870269803 , iy: -0.339013602 , iz: 0.339013602 , r: -0.113004534)
  private static let Data1992_153 = simd_quatd(ix: 0.870269803 , iy: 0.339013602 , iz: 0.113004534 , r: -0.339013602)
  private static let Data1992_154 = simd_quatd(ix: 0.870269803 , iy: -0.339013602 , iz: -0.339013602 , r: -0.113004534)
  private static let Data1992_155 = simd_quatd(ix: 0.870269803 , iy: -0.339013602 , iz: 0.113004534 , r: 0.339013602)
  private static let Data1992_156 = simd_quatd(ix: 0.870269803 , iy: 0.339013602 , iz: 0.339013602 , r: -0.113004534)
  private static let Data1992_157 = simd_quatd(ix: 0.870269803 , iy: 0.339013602 , iz: 0.113004534 , r: 0.339013602)
  private static let Data1992_158 = simd_quatd(ix: 0.870269803 , iy: 0.339013602 , iz: -0.339013602 , r: -0.113004534)
  private static let Data1992_159 = simd_quatd(ix: 0.870269803 , iy: -0.339013602 , iz: -0.113004534 , r: -0.339013602)
  private static let Data1992_160 = simd_quatd(ix: 0.870269803 , iy: -0.339013602 , iz: 0.339013602 , r: 0.113004534)
  private static let Data1992_161 = simd_quatd(ix: 0.870269803 , iy: 0.339013602 , iz: -0.113004534 , r: -0.339013602)
  private static let Data1992_162 = simd_quatd(ix: 0.870269803 , iy: -0.339013602 , iz: -0.339013602 , r: 0.113004534)
  private static let Data1992_163 = simd_quatd(ix: 0.870269803 , iy: -0.339013602 , iz: -0.113004534 , r: 0.339013602)
  private static let Data1992_164 = simd_quatd(ix: 0.870269803 , iy: 0.339013602 , iz: 0.339013602 , r: 0.113004534)
  private static let Data1992_165 = simd_quatd(ix: 0.870269803 , iy: 0.339013602 , iz: -0.113004534 , r: 0.339013602)
  private static let Data1992_166 = simd_quatd(ix: 0.870269803 , iy: 0.339013602 , iz: -0.339013602 , r: 0.113004534)
  private static let Data1992_167 = simd_quatd(ix: 0.000000000 , iy: 1.000000000 , iz: 0.000000000 , r: 0.000000000)
  private static let Data1992_168 = simd_quatd(ix: 0.126685455 , iy: 0.975629226 , iz: -0.126685455 , r: -0.126685455)
  private static let Data1992_169 = simd_quatd(ix: 0.126685455 , iy: 0.975629226 , iz: 0.126685455 , r: -0.126685455)
  private static let Data1992_170 = simd_quatd(ix: 0.126685455 , iy: 0.975629226 , iz: -0.126685455 , r: 0.126685455)
  private static let Data1992_171 = simd_quatd(ix: 0.126685455 , iy: 0.975629226 , iz: 0.126685455 , r: 0.126685455)
  private static let Data1992_172 = simd_quatd(ix: -0.126685455 , iy: 0.975629226 , iz: -0.126685455 , r: -0.126685455)
  private static let Data1992_173 = simd_quatd(ix: -0.126685455 , iy: 0.975629226 , iz: 0.126685455 , r: -0.126685455)
  private static let Data1992_174 = simd_quatd(ix: -0.126685455 , iy: 0.975629226 , iz: -0.126685455 , r: 0.126685455)
  private static let Data1992_175 = simd_quatd(ix: -0.126685455 , iy: 0.975629226 , iz: 0.126685455 , r: 0.126685455)
  private static let Data1992_176 = simd_quatd(ix: 0.000000000 , iy: 0.967893184 , iz: -0.251361860 , r: 0.000000000)
  private static let Data1992_177 = simd_quatd(ix: 0.000000000 , iy: 0.967893184 , iz: 0.251361860 , r: 0.000000000)
  private static let Data1992_178 = simd_quatd(ix: 0.251361860 , iy: 0.967893184 , iz: 0.000000000 , r: 0.000000000)
  private static let Data1992_179 = simd_quatd(ix: 0.000000000 , iy: 0.967893184 , iz: 0.000000000 , r: -0.251361860)
  private static let Data1992_180 = simd_quatd(ix: -0.251361860 , iy: 0.967893184 , iz: 0.000000000 , r: 0.000000000)
  private static let Data1992_181 = simd_quatd(ix: 0.000000000 , iy: 0.967893184 , iz: 0.000000000 , r: 0.251361860)
  private static let Data1992_182 = simd_quatd(ix: 0.000000000 , iy: 0.938692750 , iz: -0.243778507 , r: -0.243778507)
  private static let Data1992_183 = simd_quatd(ix: 0.000000000 , iy: 0.938692750 , iz: 0.243778507 , r: -0.243778507)
  private static let Data1992_184 = simd_quatd(ix: 0.000000000 , iy: 0.938692750 , iz: -0.243778507 , r: 0.243778507)
  private static let Data1992_185 = simd_quatd(ix: 0.000000000 , iy: 0.938692750 , iz: 0.243778507 , r: 0.243778507)
  private static let Data1992_186 = simd_quatd(ix: 0.243778507 , iy: 0.938692750 , iz: -0.243778507 , r: 0.000000000)
  private static let Data1992_187 = simd_quatd(ix: 0.243778507 , iy: 0.938692750 , iz: 0.000000000 , r: -0.243778507)
  private static let Data1992_188 = simd_quatd(ix: -0.243778507 , iy: 0.938692750 , iz: -0.243778507 , r: 0.000000000)
  private static let Data1992_189 = simd_quatd(ix: 0.243778507 , iy: 0.938692750 , iz: 0.000000000 , r: 0.243778507)
  private static let Data1992_190 = simd_quatd(ix: 0.243778507 , iy: 0.938692750 , iz: 0.243778507 , r: 0.000000000)
  private static let Data1992_191 = simd_quatd(ix: -0.243778507 , iy: 0.938692750 , iz: 0.000000000 , r: -0.243778507)
  private static let Data1992_192 = simd_quatd(ix: -0.243778507 , iy: 0.938692750 , iz: 0.243778507 , r: 0.000000000)
  private static let Data1992_193 = simd_quatd(ix: -0.243778507 , iy: 0.938692750 , iz: 0.000000000 , r: 0.243778507)
  private static let Data1992_194 = simd_quatd(ix: 0.236842533 , iy: 0.911985111 , iz: -0.236842533 , r: -0.236842533)
  private static let Data1992_195 = simd_quatd(ix: 0.236842533 , iy: 0.911985111 , iz: 0.236842533 , r: -0.236842533)
  private static let Data1992_196 = simd_quatd(ix: 0.236842533 , iy: 0.911985111 , iz: -0.236842533 , r: 0.236842533)
  private static let Data1992_197 = simd_quatd(ix: 0.236842533 , iy: 0.911985111 , iz: 0.236842533 , r: 0.236842533)
  private static let Data1992_198 = simd_quatd(ix: -0.236842533 , iy: 0.911985111 , iz: -0.236842533 , r: -0.236842533)
  private static let Data1992_199 = simd_quatd(ix: -0.236842533 , iy: 0.911985111 , iz: 0.236842533 , r: -0.236842533)
  private static let Data1992_200 = simd_quatd(ix: -0.236842533 , iy: 0.911985111 , iz: -0.236842533 , r: 0.236842533)
  private static let Data1992_201 = simd_quatd(ix: -0.236842533 , iy: 0.911985111 , iz: 0.236842533 , r: 0.236842533)
  private static let Data1992_202 = simd_quatd(ix: 0.119260449 , iy: 0.918447820 , iz: -0.357781348 , r: -0.119260449)
  private static let Data1992_203 = simd_quatd(ix: 0.119260449 , iy: 0.918447820 , iz: 0.357781348 , r: -0.119260449)
  private static let Data1992_204 = simd_quatd(ix: 0.119260449 , iy: 0.918447820 , iz: -0.357781348 , r: 0.119260449)
  private static let Data1992_205 = simd_quatd(ix: 0.119260449 , iy: 0.918447820 , iz: 0.357781348 , r: 0.119260449)
  private static let Data1992_206 = simd_quatd(ix: -0.119260449 , iy: 0.918447820 , iz: -0.357781348 , r: -0.119260449)
  private static let Data1992_207 = simd_quatd(ix: -0.119260449 , iy: 0.918447820 , iz: 0.357781348 , r: -0.119260449)
  private static let Data1992_208 = simd_quatd(ix: -0.119260449 , iy: 0.918447820 , iz: -0.357781348 , r: 0.119260449)
  private static let Data1992_209 = simd_quatd(ix: -0.119260449 , iy: 0.918447820 , iz: 0.357781348 , r: 0.119260449)
  private static let Data1992_210 = simd_quatd(ix: 0.357781348 , iy: 0.918447820 , iz: -0.119260449 , r: -0.119260449)
  private static let Data1992_211 = simd_quatd(ix: 0.119260449 , iy: 0.918447820 , iz: -0.119260449 , r: -0.357781348)
  private static let Data1992_212 = simd_quatd(ix: -0.357781348 , iy: 0.918447820 , iz: -0.119260449 , r: -0.119260449)
  private static let Data1992_213 = simd_quatd(ix: 0.119260449 , iy: 0.918447820 , iz: -0.119260449 , r: 0.357781348)
  private static let Data1992_214 = simd_quatd(ix: 0.357781348 , iy: 0.918447820 , iz: 0.119260449 , r: -0.119260449)
  private static let Data1992_215 = simd_quatd(ix: -0.119260449 , iy: 0.918447820 , iz: -0.119260449 , r: -0.357781348)
  private static let Data1992_216 = simd_quatd(ix: -0.357781348 , iy: 0.918447820 , iz: 0.119260449 , r: -0.119260449)
  private static let Data1992_217 = simd_quatd(ix: -0.119260449 , iy: 0.918447820 , iz: -0.119260449 , r: 0.357781348)
  private static let Data1992_218 = simd_quatd(ix: 0.357781348 , iy: 0.918447820 , iz: -0.119260449 , r: 0.119260449)
  private static let Data1992_219 = simd_quatd(ix: 0.119260449 , iy: 0.918447820 , iz: 0.119260449 , r: -0.357781348)
  private static let Data1992_220 = simd_quatd(ix: -0.357781348 , iy: 0.918447820 , iz: -0.119260449 , r: 0.119260449)
  private static let Data1992_221 = simd_quatd(ix: 0.119260449 , iy: 0.918447820 , iz: 0.119260449 , r: 0.357781348)
  private static let Data1992_222 = simd_quatd(ix: 0.357781348 , iy: 0.918447820 , iz: 0.119260449 , r: 0.119260449)
  private static let Data1992_223 = simd_quatd(ix: -0.119260449 , iy: 0.918447820 , iz: 0.119260449 , r: -0.357781348)
  private static let Data1992_224 = simd_quatd(ix: -0.357781348 , iy: 0.918447820 , iz: 0.119260449 , r: 0.119260449)
  private static let Data1992_225 = simd_quatd(ix: -0.119260449 , iy: 0.918447820 , iz: 0.119260449 , r: 0.357781348)
  private static let Data1992_226 = simd_quatd(ix: 0.113004534 , iy: 0.870269803 , iz: -0.339013602 , r: -0.339013602)
  private static let Data1992_227 = simd_quatd(ix: 0.113004534 , iy: 0.870269803 , iz: 0.339013602 , r: -0.339013602)
  private static let Data1992_228 = simd_quatd(ix: 0.113004534 , iy: 0.870269803 , iz: -0.339013602 , r: 0.339013602)
  private static let Data1992_229 = simd_quatd(ix: 0.113004534 , iy: 0.870269803 , iz: 0.339013602 , r: 0.339013602)
  private static let Data1992_230 = simd_quatd(ix: -0.113004534 , iy: 0.870269803 , iz: -0.339013602 , r: -0.339013602)
  private static let Data1992_231 = simd_quatd(ix: -0.113004534 , iy: 0.870269803 , iz: 0.339013602 , r: -0.339013602)
  private static let Data1992_232 = simd_quatd(ix: -0.113004534 , iy: 0.870269803 , iz: -0.339013602 , r: 0.339013602)
  private static let Data1992_233 = simd_quatd(ix: -0.113004534 , iy: 0.870269803 , iz: 0.339013602 , r: 0.339013602)
  private static let Data1992_234 = simd_quatd(ix: 0.339013602 , iy: 0.870269803 , iz: -0.339013602 , r: -0.113004534)
  private static let Data1992_235 = simd_quatd(ix: 0.339013602 , iy: 0.870269803 , iz: -0.113004534 , r: -0.339013602)
  private static let Data1992_236 = simd_quatd(ix: -0.339013602 , iy: 0.870269803 , iz: -0.339013602 , r: -0.113004534)
  private static let Data1992_237 = simd_quatd(ix: 0.339013602 , iy: 0.870269803 , iz: -0.113004534 , r: 0.339013602)
  private static let Data1992_238 = simd_quatd(ix: 0.339013602 , iy: 0.870269803 , iz: 0.339013602 , r: -0.113004534)
  private static let Data1992_239 = simd_quatd(ix: -0.339013602 , iy: 0.870269803 , iz: -0.113004534 , r: -0.339013602)
  private static let Data1992_240 = simd_quatd(ix: -0.339013602 , iy: 0.870269803 , iz: 0.339013602 , r: -0.113004534)
  private static let Data1992_241 = simd_quatd(ix: -0.339013602 , iy: 0.870269803 , iz: -0.113004534 , r: 0.339013602)
  private static let Data1992_242 = simd_quatd(ix: 0.339013602 , iy: 0.870269803 , iz: -0.339013602 , r: 0.113004534)
  private static let Data1992_243 = simd_quatd(ix: 0.339013602 , iy: 0.870269803 , iz: 0.113004534 , r: -0.339013602)
  private static let Data1992_244 = simd_quatd(ix: -0.339013602 , iy: 0.870269803 , iz: -0.339013602 , r: 0.113004534)
  private static let Data1992_245 = simd_quatd(ix: 0.339013602 , iy: 0.870269803 , iz: 0.113004534 , r: 0.339013602)
  private static let Data1992_246 = simd_quatd(ix: 0.339013602 , iy: 0.870269803 , iz: 0.339013602 , r: 0.113004534)
  private static let Data1992_247 = simd_quatd(ix: -0.339013602 , iy: 0.870269803 , iz: 0.113004534 , r: -0.339013602)
  private static let Data1992_248 = simd_quatd(ix: -0.339013602 , iy: 0.870269803 , iz: 0.339013602 , r: 0.113004534)
  private static let Data1992_249 = simd_quatd(ix: -0.339013602 , iy: 0.870269803 , iz: 0.113004534 , r: 0.339013602)
  private static let Data1992_250 = simd_quatd(ix: 0.000000000 , iy: 0.000000000 , iz: 1.000000000 , r: 0.000000000)
  private static let Data1992_251 = simd_quatd(ix: -0.126685455 , iy: 0.126685455 , iz: 0.975629226 , r: -0.126685455)
  private static let Data1992_252 = simd_quatd(ix: -0.126685455 , iy: -0.126685455 , iz: 0.975629226 , r: -0.126685455)
  private static let Data1992_253 = simd_quatd(ix: 0.126685455 , iy: 0.126685455 , iz: 0.975629226 , r: -0.126685455)
  private static let Data1992_254 = simd_quatd(ix: 0.126685455 , iy: -0.126685455 , iz: 0.975629226 , r: -0.126685455)
  private static let Data1992_255 = simd_quatd(ix: -0.126685455 , iy: 0.126685455 , iz: 0.975629226 , r: 0.126685455)
  private static let Data1992_256 = simd_quatd(ix: -0.126685455 , iy: -0.126685455 , iz: 0.975629226 , r: 0.126685455)
  private static let Data1992_257 = simd_quatd(ix: 0.126685455 , iy: 0.126685455 , iz: 0.975629226 , r: 0.126685455)
  private static let Data1992_258 = simd_quatd(ix: 0.126685455 , iy: -0.126685455 , iz: 0.975629226 , r: 0.126685455)
  private static let Data1992_259 = simd_quatd(ix: 0.000000000 , iy: 0.251361860 , iz: 0.967893184 , r: 0.000000000)
  private static let Data1992_260 = simd_quatd(ix: 0.000000000 , iy: -0.251361860 , iz: 0.967893184 , r: 0.000000000)
  private static let Data1992_261 = simd_quatd(ix: 0.000000000 , iy: 0.000000000 , iz: 0.967893184 , r: -0.251361860)
  private static let Data1992_262 = simd_quatd(ix: -0.251361860 , iy: 0.000000000 , iz: 0.967893184 , r: 0.000000000)
  private static let Data1992_263 = simd_quatd(ix: 0.000000000 , iy: 0.000000000 , iz: 0.967893184 , r: 0.251361860)
  private static let Data1992_264 = simd_quatd(ix: 0.251361860 , iy: 0.000000000 , iz: 0.967893184 , r: 0.000000000)
  private static let Data1992_265 = simd_quatd(ix: -0.243778507 , iy: 0.243778507 , iz: 0.938692750 , r: 0.000000000)
  private static let Data1992_266 = simd_quatd(ix: -0.243778507 , iy: -0.243778507 , iz: 0.938692750 , r: 0.000000000)
  private static let Data1992_267 = simd_quatd(ix: 0.243778507 , iy: 0.243778507 , iz: 0.938692750 , r: 0.000000000)
  private static let Data1992_268 = simd_quatd(ix: 0.243778507 , iy: -0.243778507 , iz: 0.938692750 , r: 0.000000000)
  private static let Data1992_269 = simd_quatd(ix: 0.000000000 , iy: 0.243778507 , iz: 0.938692750 , r: -0.243778507)
  private static let Data1992_270 = simd_quatd(ix: -0.243778507 , iy: 0.000000000 , iz: 0.938692750 , r: -0.243778507)
  private static let Data1992_271 = simd_quatd(ix: 0.000000000 , iy: 0.243778507 , iz: 0.938692750 , r: 0.243778507)
  private static let Data1992_272 = simd_quatd(ix: 0.243778507 , iy: 0.000000000 , iz: 0.938692750 , r: -0.243778507)
  private static let Data1992_273 = simd_quatd(ix: 0.000000000 , iy: -0.243778507 , iz: 0.938692750 , r: -0.243778507)
  private static let Data1992_274 = simd_quatd(ix: -0.243778507 , iy: 0.000000000 , iz: 0.938692750 , r: 0.243778507)
  private static let Data1992_275 = simd_quatd(ix: 0.000000000 , iy: -0.243778507 , iz: 0.938692750 , r: 0.243778507)
  private static let Data1992_276 = simd_quatd(ix: 0.243778507 , iy: 0.000000000 , iz: 0.938692750 , r: 0.243778507)
  private static let Data1992_277 = simd_quatd(ix: -0.236842533 , iy: 0.236842533 , iz: 0.911985111 , r: -0.236842533)
  private static let Data1992_278 = simd_quatd(ix: -0.236842533 , iy: -0.236842533 , iz: 0.911985111 , r: -0.236842533)
  private static let Data1992_279 = simd_quatd(ix: 0.236842533 , iy: 0.236842533 , iz: 0.911985111 , r: -0.236842533)
  private static let Data1992_280 = simd_quatd(ix: 0.236842533 , iy: -0.236842533 , iz: 0.911985111 , r: -0.236842533)
  private static let Data1992_281 = simd_quatd(ix: -0.236842533 , iy: 0.236842533 , iz: 0.911985111 , r: 0.236842533)
  private static let Data1992_282 = simd_quatd(ix: -0.236842533 , iy: -0.236842533 , iz: 0.911985111 , r: 0.236842533)
  private static let Data1992_283 = simd_quatd(ix: 0.236842533 , iy: 0.236842533 , iz: 0.911985111 , r: 0.236842533)
  private static let Data1992_284 = simd_quatd(ix: 0.236842533 , iy: -0.236842533 , iz: 0.911985111 , r: 0.236842533)
  private static let Data1992_285 = simd_quatd(ix: -0.119260449 , iy: 0.357781348 , iz: 0.918447820 , r: -0.119260449)
  private static let Data1992_286 = simd_quatd(ix: -0.119260449 , iy: -0.357781348 , iz: 0.918447820 , r: -0.119260449)
  private static let Data1992_287 = simd_quatd(ix: 0.119260449 , iy: 0.357781348 , iz: 0.918447820 , r: -0.119260449)
  private static let Data1992_288 = simd_quatd(ix: 0.119260449 , iy: -0.357781348 , iz: 0.918447820 , r: -0.119260449)
  private static let Data1992_289 = simd_quatd(ix: -0.119260449 , iy: 0.357781348 , iz: 0.918447820 , r: 0.119260449)
  private static let Data1992_290 = simd_quatd(ix: -0.119260449 , iy: -0.357781348 , iz: 0.918447820 , r: 0.119260449)
  private static let Data1992_291 = simd_quatd(ix: 0.119260449 , iy: 0.357781348 , iz: 0.918447820 , r: 0.119260449)
  private static let Data1992_292 = simd_quatd(ix: 0.119260449 , iy: -0.357781348 , iz: 0.918447820 , r: 0.119260449)
  private static let Data1992_293 = simd_quatd(ix: -0.119260449 , iy: 0.119260449 , iz: 0.918447820 , r: -0.357781348)
  private static let Data1992_294 = simd_quatd(ix: -0.357781348 , iy: 0.119260449 , iz: 0.918447820 , r: -0.119260449)
  private static let Data1992_295 = simd_quatd(ix: -0.119260449 , iy: 0.119260449 , iz: 0.918447820 , r: 0.357781348)
  private static let Data1992_296 = simd_quatd(ix: 0.357781348 , iy: 0.119260449 , iz: 0.918447820 , r: -0.119260449)
  private static let Data1992_297 = simd_quatd(ix: -0.119260449 , iy: -0.119260449 , iz: 0.918447820 , r: -0.357781348)
  private static let Data1992_298 = simd_quatd(ix: -0.357781348 , iy: 0.119260449 , iz: 0.918447820 , r: 0.119260449)
  private static let Data1992_299 = simd_quatd(ix: -0.119260449 , iy: -0.119260449 , iz: 0.918447820 , r: 0.357781348)
  private static let Data1992_300 = simd_quatd(ix: 0.357781348 , iy: 0.119260449 , iz: 0.918447820 , r: 0.119260449)
  private static let Data1992_301 = simd_quatd(ix: 0.119260449 , iy: 0.119260449 , iz: 0.918447820 , r: -0.357781348)
  private static let Data1992_302 = simd_quatd(ix: -0.357781348 , iy: -0.119260449 , iz: 0.918447820 , r: -0.119260449)
  private static let Data1992_303 = simd_quatd(ix: 0.119260449 , iy: 0.119260449 , iz: 0.918447820 , r: 0.357781348)
  private static let Data1992_304 = simd_quatd(ix: 0.357781348 , iy: -0.119260449 , iz: 0.918447820 , r: -0.119260449)
  private static let Data1992_305 = simd_quatd(ix: 0.119260449 , iy: -0.119260449 , iz: 0.918447820 , r: -0.357781348)
  private static let Data1992_306 = simd_quatd(ix: -0.357781348 , iy: -0.119260449 , iz: 0.918447820 , r: 0.119260449)
  private static let Data1992_307 = simd_quatd(ix: 0.119260449 , iy: -0.119260449 , iz: 0.918447820 , r: 0.357781348)
  private static let Data1992_308 = simd_quatd(ix: 0.357781348 , iy: -0.119260449 , iz: 0.918447820 , r: 0.119260449)
  private static let Data1992_309 = simd_quatd(ix: -0.339013602 , iy: 0.339013602 , iz: 0.870269803 , r: -0.113004534)
  private static let Data1992_310 = simd_quatd(ix: -0.339013602 , iy: -0.339013602 , iz: 0.870269803 , r: -0.113004534)
  private static let Data1992_311 = simd_quatd(ix: 0.339013602 , iy: 0.339013602 , iz: 0.870269803 , r: -0.113004534)
  private static let Data1992_312 = simd_quatd(ix: 0.339013602 , iy: -0.339013602 , iz: 0.870269803 , r: -0.113004534)
  private static let Data1992_313 = simd_quatd(ix: -0.339013602 , iy: 0.339013602 , iz: 0.870269803 , r: 0.113004534)
  private static let Data1992_314 = simd_quatd(ix: -0.339013602 , iy: -0.339013602 , iz: 0.870269803 , r: 0.113004534)
  private static let Data1992_315 = simd_quatd(ix: 0.339013602 , iy: 0.339013602 , iz: 0.870269803 , r: 0.113004534)
  private static let Data1992_316 = simd_quatd(ix: 0.339013602 , iy: -0.339013602 , iz: 0.870269803 , r: 0.113004534)
  private static let Data1992_317 = simd_quatd(ix: -0.113004534 , iy: 0.339013602 , iz: 0.870269803 , r: -0.339013602)
  private static let Data1992_318 = simd_quatd(ix: -0.339013602 , iy: 0.113004534 , iz: 0.870269803 , r: -0.339013602)
  private static let Data1992_319 = simd_quatd(ix: -0.113004534 , iy: 0.339013602 , iz: 0.870269803 , r: 0.339013602)
  private static let Data1992_320 = simd_quatd(ix: 0.339013602 , iy: 0.113004534 , iz: 0.870269803 , r: -0.339013602)
  private static let Data1992_321 = simd_quatd(ix: -0.113004534 , iy: -0.339013602 , iz: 0.870269803 , r: -0.339013602)
  private static let Data1992_322 = simd_quatd(ix: -0.339013602 , iy: 0.113004534 , iz: 0.870269803 , r: 0.339013602)
  private static let Data1992_323 = simd_quatd(ix: -0.113004534 , iy: -0.339013602 , iz: 0.870269803 , r: 0.339013602)
  private static let Data1992_324 = simd_quatd(ix: 0.339013602 , iy: 0.113004534 , iz: 0.870269803 , r: 0.339013602)
  private static let Data1992_325 = simd_quatd(ix: 0.113004534 , iy: 0.339013602 , iz: 0.870269803 , r: -0.339013602)
  private static let Data1992_326 = simd_quatd(ix: -0.339013602 , iy: -0.113004534 , iz: 0.870269803 , r: -0.339013602)
  private static let Data1992_327 = simd_quatd(ix: 0.113004534 , iy: 0.339013602 , iz: 0.870269803 , r: 0.339013602)
  private static let Data1992_328 = simd_quatd(ix: 0.339013602 , iy: -0.113004534 , iz: 0.870269803 , r: -0.339013602)
  private static let Data1992_329 = simd_quatd(ix: 0.113004534 , iy: -0.339013602 , iz: 0.870269803 , r: -0.339013602)
  private static let Data1992_330 = simd_quatd(ix: -0.339013602 , iy: -0.113004534 , iz: 0.870269803 , r: 0.339013602)
  private static let Data1992_331 = simd_quatd(ix: 0.113004534 , iy: -0.339013602 , iz: 0.870269803 , r: 0.339013602)
  private static let Data1992_332 = simd_quatd(ix: 0.339013602 , iy: -0.113004534 , iz: 0.870269803 , r: 0.339013602)
  private static let Data1992_333 = simd_quatd(ix: 0.500000000 , iy: 0.500000000 , iz: 0.500000000 , r: 0.500000000)
  private static let Data1992_334 = simd_quatd(ix: 0.551157340 , iy: 0.551157340 , iz: 0.551157340 , r: 0.297786430)
  private static let Data1992_335 = simd_quatd(ix: 0.424471885 , iy: 0.424471885 , iz: 0.677842795 , r: 0.424471885)
  private static let Data1992_336 = simd_quatd(ix: 0.677842795 , iy: 0.424471885 , iz: 0.424471885 , r: 0.424471885)
  private static let Data1992_337 = simd_quatd(ix: 0.551157340 , iy: 0.297786430 , iz: 0.551157340 , r: 0.551157340)
  private static let Data1992_338 = simd_quatd(ix: 0.424471885 , iy: 0.677842795 , iz: 0.424471885 , r: 0.424471885)
  private static let Data1992_339 = simd_quatd(ix: 0.297786430 , iy: 0.551157340 , iz: 0.551157340 , r: 0.551157340)
  private static let Data1992_340 = simd_quatd(ix: 0.551157340 , iy: 0.551157340 , iz: 0.297786430 , r: 0.551157340)
  private static let Data1992_341 = simd_quatd(ix: 0.424471885 , iy: 0.424471885 , iz: 0.424471885 , r: 0.677842795)
  private static let Data1992_342 = simd_quatd(ix: 0.609627522 , iy: 0.609627522 , iz: 0.358265662 , r: 0.358265662)
  private static let Data1992_343 = simd_quatd(ix: 0.358265662 , iy: 0.358265662 , iz: 0.609627522 , r: 0.609627522)
  private static let Data1992_344 = simd_quatd(ix: 0.609627522 , iy: 0.358265662 , iz: 0.609627522 , r: 0.358265662)
  private static let Data1992_345 = simd_quatd(ix: 0.358265662 , iy: 0.609627522 , iz: 0.609627522 , r: 0.358265662)
  private static let Data1992_346 = simd_quatd(ix: 0.358265662 , iy: 0.609627522 , iz: 0.358265662 , r: 0.609627522)
  private static let Data1992_347 = simd_quatd(ix: 0.609627522 , iy: 0.358265662 , iz: 0.358265662 , r: 0.609627522)
  private static let Data1992_348 = simd_quatd(ix: 0.469346375 , iy: 0.713124882 , iz: 0.469346375 , r: 0.225567868)
  private static let Data1992_349 = simd_quatd(ix: 0.225567868 , iy: 0.469346375 , iz: 0.713124882 , r: 0.469346375)
  private static let Data1992_350 = simd_quatd(ix: 0.713124882 , iy: 0.469346375 , iz: 0.225567868 , r: 0.469346375)
  private static let Data1992_351 = simd_quatd(ix: 0.469346375 , iy: 0.225567868 , iz: 0.469346375 , r: 0.713124882)
  private static let Data1992_352 = simd_quatd(ix: 0.713124882 , iy: 0.469346375 , iz: 0.469346375 , r: 0.225567868)
  private static let Data1992_353 = simd_quatd(ix: 0.469346375 , iy: 0.469346375 , iz: 0.713124882 , r: 0.225567868)
  private static let Data1992_354 = simd_quatd(ix: 0.469346375 , iy: 0.713124882 , iz: 0.225567868 , r: 0.469346375)
  private static let Data1992_355 = simd_quatd(ix: 0.713124882 , iy: 0.225567868 , iz: 0.469346375 , r: 0.469346375)
  private static let Data1992_356 = simd_quatd(ix: 0.469346375 , iy: 0.225567868 , iz: 0.713124882 , r: 0.469346375)
  private static let Data1992_357 = simd_quatd(ix: 0.225567868 , iy: 0.713124882 , iz: 0.469346375 , r: 0.469346375)
  private static let Data1992_358 = simd_quatd(ix: 0.225567868 , iy: 0.469346375 , iz: 0.469346375 , r: 0.713124882)
  private static let Data1992_359 = simd_quatd(ix: 0.469346375 , iy: 0.469346375 , iz: 0.225567868 , r: 0.713124882)
  private static let Data1992_360 = simd_quatd(ix: 0.574413822 , iy: 0.574413822 , iz: 0.574413822 , r: 0.100728756)
  private static let Data1992_361 = simd_quatd(ix: 0.337571289 , iy: 0.337571289 , iz: 0.811256356 , r: 0.337571289)
  private static let Data1992_362 = simd_quatd(ix: 0.811256356 , iy: 0.337571289 , iz: 0.337571289 , r: 0.337571289)
  private static let Data1992_363 = simd_quatd(ix: 0.574413822 , iy: 0.100728756 , iz: 0.574413822 , r: 0.574413822)
  private static let Data1992_364 = simd_quatd(ix: 0.337571289 , iy: 0.811256356 , iz: 0.337571289 , r: 0.337571289)
  private static let Data1992_365 = simd_quatd(ix: 0.100728756 , iy: 0.574413822 , iz: 0.574413822 , r: 0.574413822)
  private static let Data1992_366 = simd_quatd(ix: 0.574413822 , iy: 0.574413822 , iz: 0.100728756 , r: 0.574413822)
  private static let Data1992_367 = simd_quatd(ix: 0.337571289 , iy: 0.337571289 , iz: 0.337571289 , r: 0.811256356)
  private static let Data1992_368 = simd_quatd(ix: 0.638114584 , iy: 0.638114584 , iz: 0.399593685 , r: 0.161072786)
  private static let Data1992_369 = simd_quatd(ix: 0.280333236 , iy: 0.280333236 , iz: 0.757375033 , r: 0.518854134)
  private static let Data1992_370 = simd_quatd(ix: 0.757375033 , iy: 0.518854134 , iz: 0.280333236 , r: 0.280333236)
  private static let Data1992_371 = simd_quatd(ix: 0.399593685 , iy: 0.161072786 , iz: 0.638114584 , r: 0.638114584)
  private static let Data1992_372 = simd_quatd(ix: 0.518854134 , iy: 0.757375033 , iz: 0.280333236 , r: 0.280333236)
  private static let Data1992_373 = simd_quatd(ix: 0.161072786 , iy: 0.399593685 , iz: 0.638114584 , r: 0.638114584)
  private static let Data1992_374 = simd_quatd(ix: 0.638114584 , iy: 0.638114584 , iz: 0.161072786 , r: 0.399593685)
  private static let Data1992_375 = simd_quatd(ix: 0.280333236 , iy: 0.280333236 , iz: 0.518854134 , r: 0.757375033)
  private static let Data1992_376 = simd_quatd(ix: 0.638114584 , iy: 0.399593685 , iz: 0.638114584 , r: 0.161072786)
  private static let Data1992_377 = simd_quatd(ix: 0.399593685 , iy: 0.638114584 , iz: 0.638114584 , r: 0.161072786)
  private static let Data1992_378 = simd_quatd(ix: 0.280333236 , iy: 0.757375033 , iz: 0.280333236 , r: 0.518854134)
  private static let Data1992_379 = simd_quatd(ix: 0.757375033 , iy: 0.280333236 , iz: 0.280333236 , r: 0.518854134)
  private static let Data1992_380 = simd_quatd(ix: 0.518854134 , iy: 0.280333236 , iz: 0.757375033 , r: 0.280333236)
  private static let Data1992_381 = simd_quatd(ix: 0.280333236 , iy: 0.757375033 , iz: 0.518854134 , r: 0.280333236)
  private static let Data1992_382 = simd_quatd(ix: 0.161072786 , iy: 0.638114584 , iz: 0.399593685 , r: 0.638114584)
  private static let Data1992_383 = simd_quatd(ix: 0.638114584 , iy: 0.399593685 , iz: 0.161072786 , r: 0.638114584)
  private static let Data1992_384 = simd_quatd(ix: 0.757375033 , iy: 0.280333236 , iz: 0.518854134 , r: 0.280333236)
  private static let Data1992_385 = simd_quatd(ix: 0.280333236 , iy: 0.518854134 , iz: 0.757375033 , r: 0.280333236)
  private static let Data1992_386 = simd_quatd(ix: 0.399593685 , iy: 0.638114584 , iz: 0.161072786 , r: 0.638114584)
  private static let Data1992_387 = simd_quatd(ix: 0.638114584 , iy: 0.161072786 , iz: 0.399593685 , r: 0.638114584)
  private static let Data1992_388 = simd_quatd(ix: 0.638114584 , iy: 0.161072786 , iz: 0.638114584 , r: 0.399593685)
  private static let Data1992_389 = simd_quatd(ix: 0.161072786 , iy: 0.638114584 , iz: 0.638114584 , r: 0.399593685)
  private static let Data1992_390 = simd_quatd(ix: 0.280333236 , iy: 0.518854134 , iz: 0.280333236 , r: 0.757375033)
  private static let Data1992_391 = simd_quatd(ix: 0.518854134 , iy: 0.280333236 , iz: 0.280333236 , r: 0.757375033)
  private static let Data1992_392 = simd_quatd(ix: 0.491637169 , iy: 0.717646237 , iz: 0.491637169 , r: 0.039619033)
  private static let Data1992_393 = simd_quatd(ix: 0.152623567 , iy: 0.378632635 , iz: 0.830650771 , r: 0.378632635)
  private static let Data1992_394 = simd_quatd(ix: 0.830650771 , iy: 0.378632635 , iz: 0.152623567 , r: 0.378632635)
  private static let Data1992_395 = simd_quatd(ix: 0.491637169 , iy: 0.039619033 , iz: 0.491637169 , r: 0.717646237)
  private static let Data1992_396 = simd_quatd(ix: 0.378632635 , iy: 0.830650771 , iz: 0.378632635 , r: 0.152623567)
  private static let Data1992_397 = simd_quatd(ix: 0.039619033 , iy: 0.491637169 , iz: 0.717646237 , r: 0.491637169)
  private static let Data1992_398 = simd_quatd(ix: 0.717646237 , iy: 0.491637169 , iz: 0.039619033 , r: 0.491637169)
  private static let Data1992_399 = simd_quatd(ix: 0.378632635 , iy: 0.152623567 , iz: 0.378632635 , r: 0.830650771)
  private static let Data1992_400 = simd_quatd(ix: 0.717646237 , iy: 0.491637169 , iz: 0.491637169 , r: 0.039619033)
  private static let Data1992_401 = simd_quatd(ix: 0.491637169 , iy: 0.491637169 , iz: 0.717646237 , r: 0.039619033)
  private static let Data1992_402 = simd_quatd(ix: 0.378632635 , iy: 0.830650771 , iz: 0.152623567 , r: 0.378632635)
  private static let Data1992_403 = simd_quatd(ix: 0.830650771 , iy: 0.152623567 , iz: 0.378632635 , r: 0.378632635)
  private static let Data1992_404 = simd_quatd(ix: 0.378632635 , iy: 0.152623567 , iz: 0.830650771 , r: 0.378632635)
  private static let Data1992_405 = simd_quatd(ix: 0.152623567 , iy: 0.830650771 , iz: 0.378632635 , r: 0.378632635)
  private static let Data1992_406 = simd_quatd(ix: 0.039619033 , iy: 0.491637169 , iz: 0.491637169 , r: 0.717646237)
  private static let Data1992_407 = simd_quatd(ix: 0.491637169 , iy: 0.491637169 , iz: 0.039619033 , r: 0.717646237)
  private static let Data1992_408 = simd_quatd(ix: 0.830650771 , iy: 0.378632635 , iz: 0.378632635 , r: 0.152623567)
  private static let Data1992_409 = simd_quatd(ix: 0.378632635 , iy: 0.378632635 , iz: 0.830650771 , r: 0.152623567)
  private static let Data1992_410 = simd_quatd(ix: 0.491637169 , iy: 0.717646237 , iz: 0.039619033 , r: 0.491637169)
  private static let Data1992_411 = simd_quatd(ix: 0.717646237 , iy: 0.039619033 , iz: 0.491637169 , r: 0.491637169)
  private static let Data1992_412 = simd_quatd(ix: 0.491637169 , iy: 0.039619033 , iz: 0.717646237 , r: 0.491637169)
  private static let Data1992_413 = simd_quatd(ix: 0.039619033 , iy: 0.717646237 , iz: 0.491637169 , r: 0.491637169)
  private static let Data1992_414 = simd_quatd(ix: 0.152623567 , iy: 0.378632635 , iz: 0.378632635 , r: 0.830650771)
  private static let Data1992_415 = simd_quatd(ix: 0.378632635 , iy: 0.378632635 , iz: 0.152623567 , r: 0.830650771)
  private static let Data1992_416 = simd_quatd(ix: 0.500000000 , iy: 0.500000000 , iz: -0.500000000 , r: 0.500000000)
  private static let Data1992_417 = simd_quatd(ix: 0.677842795 , iy: 0.424471885 , iz: -0.424471885 , r: 0.424471885)
  private static let Data1992_418 = simd_quatd(ix: 0.551157340 , iy: 0.551157340 , iz: -0.297786430 , r: 0.551157340)
  private static let Data1992_419 = simd_quatd(ix: 0.551157340 , iy: 0.297786430 , iz: -0.551157340 , r: 0.551157340)
  private static let Data1992_420 = simd_quatd(ix: 0.424471885 , iy: 0.424471885 , iz: -0.424471885 , r: 0.677842795)
  private static let Data1992_421 = simd_quatd(ix: 0.551157340 , iy: 0.551157340 , iz: -0.551157340 , r: 0.297786430)
  private static let Data1992_422 = simd_quatd(ix: 0.424471885 , iy: 0.677842795 , iz: -0.424471885 , r: 0.424471885)
  private static let Data1992_423 = simd_quatd(ix: -0.424471885 , iy: -0.424471885 , iz: 0.677842795 , r: -0.424471885)
  private static let Data1992_424 = simd_quatd(ix: 0.297786430 , iy: 0.551157340 , iz: -0.551157340 , r: 0.551157340)
  private static let Data1992_425 = simd_quatd(ix: 0.609627522 , iy: 0.358265662 , iz: -0.609627522 , r: 0.358265662)
  private static let Data1992_426 = simd_quatd(ix: 0.358265662 , iy: 0.609627522 , iz: -0.358265662 , r: 0.609627522)
  private static let Data1992_427 = simd_quatd(ix: 0.609627522 , iy: 0.358265662 , iz: -0.358265662 , r: 0.609627522)
  private static let Data1992_428 = simd_quatd(ix: 0.609627522 , iy: 0.609627522 , iz: -0.358265662 , r: 0.358265662)
  private static let Data1992_429 = simd_quatd(ix: 0.358265662 , iy: 0.609627522 , iz: -0.609627522 , r: 0.358265662)
  private static let Data1992_430 = simd_quatd(ix: 0.358265662 , iy: 0.358265662 , iz: -0.609627522 , r: 0.609627522)
  private static let Data1992_431 = simd_quatd(ix: 0.713124882 , iy: 0.469346375 , iz: -0.469346375 , r: 0.225567868)
  private static let Data1992_432 = simd_quatd(ix: 0.469346375 , iy: 0.713124882 , iz: -0.225567868 , r: 0.469346375)
  private static let Data1992_433 = simd_quatd(ix: -0.469346375 , iy: -0.225567868 , iz: 0.713124882 , r: -0.469346375)
  private static let Data1992_434 = simd_quatd(ix: 0.225567868 , iy: 0.469346375 , iz: -0.469346375 , r: 0.713124882)
  private static let Data1992_435 = simd_quatd(ix: 0.713124882 , iy: 0.225567868 , iz: -0.469346375 , r: 0.469346375)
  private static let Data1992_436 = simd_quatd(ix: 0.713124882 , iy: 0.469346375 , iz: -0.225567868 , r: 0.469346375)
  private static let Data1992_437 = simd_quatd(ix: -0.469346375 , iy: -0.469346375 , iz: 0.713124882 , r: -0.225567868)
  private static let Data1992_438 = simd_quatd(ix: 0.469346375 , iy: 0.225567868 , iz: -0.469346375 , r: 0.713124882)
  private static let Data1992_439 = simd_quatd(ix: 0.469346375 , iy: 0.469346375 , iz: -0.225567868 , r: 0.713124882)
  private static let Data1992_440 = simd_quatd(ix: 0.469346375 , iy: 0.713124882 , iz: -0.469346375 , r: 0.225567868)
  private static let Data1992_441 = simd_quatd(ix: 0.225567868 , iy: 0.713124882 , iz: -0.469346375 , r: 0.469346375)
  private static let Data1992_442 = simd_quatd(ix: -0.225567868 , iy: -0.469346375 , iz: 0.713124882 , r: -0.469346375)
  private static let Data1992_443 = simd_quatd(ix: 0.811256356 , iy: 0.337571289 , iz: -0.337571289 , r: 0.337571289)
  private static let Data1992_444 = simd_quatd(ix: 0.574413822 , iy: 0.574413822 , iz: -0.100728756 , r: 0.574413822)
  private static let Data1992_445 = simd_quatd(ix: 0.574413822 , iy: 0.100728756 , iz: -0.574413822 , r: 0.574413822)
  private static let Data1992_446 = simd_quatd(ix: 0.337571289 , iy: 0.337571289 , iz: -0.337571289 , r: 0.811256356)
  private static let Data1992_447 = simd_quatd(ix: 0.574413822 , iy: 0.574413822 , iz: -0.574413822 , r: 0.100728756)
  private static let Data1992_448 = simd_quatd(ix: 0.337571289 , iy: 0.811256356 , iz: -0.337571289 , r: 0.337571289)
  private static let Data1992_449 = simd_quatd(ix: -0.337571289 , iy: -0.337571289 , iz: 0.811256356 , r: -0.337571289)
  private static let Data1992_450 = simd_quatd(ix: 0.100728756 , iy: 0.574413822 , iz: -0.574413822 , r: 0.574413822)
  private static let Data1992_451 = simd_quatd(ix: 0.757375033 , iy: 0.280333236 , iz: -0.518854134 , r: 0.280333236)
  private static let Data1992_452 = simd_quatd(ix: 0.399593685 , iy: 0.638114584 , iz: -0.161072786 , r: 0.638114584)
  private static let Data1992_453 = simd_quatd(ix: 0.638114584 , iy: 0.161072786 , iz: -0.638114584 , r: 0.399593685)
  private static let Data1992_454 = simd_quatd(ix: 0.280333236 , iy: 0.518854134 , iz: -0.280333236 , r: 0.757375033)
  private static let Data1992_455 = simd_quatd(ix: 0.638114584 , iy: 0.399593685 , iz: -0.638114584 , r: 0.161072786)
  private static let Data1992_456 = simd_quatd(ix: 0.280333236 , iy: 0.757375033 , iz: -0.280333236 , r: 0.518854134)
  private static let Data1992_457 = simd_quatd(ix: -0.518854134 , iy: -0.280333236 , iz: 0.757375033 , r: -0.280333236)
  private static let Data1992_458 = simd_quatd(ix: 0.161072786 , iy: 0.638114584 , iz: -0.399593685 , r: 0.638114584)
  private static let Data1992_459 = simd_quatd(ix: 0.757375033 , iy: 0.280333236 , iz: -0.280333236 , r: 0.518854134)
  private static let Data1992_460 = simd_quatd(ix: 0.757375033 , iy: 0.518854134 , iz: -0.280333236 , r: 0.280333236)
  private static let Data1992_461 = simd_quatd(ix: 0.399593685 , iy: 0.638114584 , iz: -0.638114584 , r: 0.161072786)
  private static let Data1992_462 = simd_quatd(ix: 0.399593685 , iy: 0.161072786 , iz: -0.638114584 , r: 0.638114584)
  private static let Data1992_463 = simd_quatd(ix: 0.638114584 , iy: 0.399593685 , iz: -0.161072786 , r: 0.638114584)
  private static let Data1992_464 = simd_quatd(ix: 0.638114584 , iy: 0.638114584 , iz: -0.399593685 , r: 0.161072786)
  private static let Data1992_465 = simd_quatd(ix: 0.280333236 , iy: 0.757375033 , iz: -0.518854134 , r: 0.280333236)
  private static let Data1992_466 = simd_quatd(ix: -0.280333236 , iy: -0.280333236 , iz: 0.757375033 , r: -0.518854134)
  private static let Data1992_467 = simd_quatd(ix: 0.638114584 , iy: 0.161072786 , iz: -0.399593685 , r: 0.638114584)
  private static let Data1992_468 = simd_quatd(ix: 0.638114584 , iy: 0.638114584 , iz: -0.161072786 , r: 0.399593685)
  private static let Data1992_469 = simd_quatd(ix: -0.280333236 , iy: -0.518854134 , iz: 0.757375033 , r: -0.280333236)
  private static let Data1992_470 = simd_quatd(ix: 0.280333236 , iy: 0.280333236 , iz: -0.518854134 , r: 0.757375033)
  private static let Data1992_471 = simd_quatd(ix: 0.518854134 , iy: 0.280333236 , iz: -0.280333236 , r: 0.757375033)
  private static let Data1992_472 = simd_quatd(ix: 0.518854134 , iy: 0.757375033 , iz: -0.280333236 , r: 0.280333236)
  private static let Data1992_473 = simd_quatd(ix: 0.161072786 , iy: 0.638114584 , iz: -0.638114584 , r: 0.399593685)
  private static let Data1992_474 = simd_quatd(ix: 0.161072786 , iy: 0.399593685 , iz: -0.638114584 , r: 0.638114584)
  private static let Data1992_475 = simd_quatd(ix: 0.830650771 , iy: 0.378632635 , iz: -0.378632635 , r: 0.152623567)
  private static let Data1992_476 = simd_quatd(ix: 0.491637169 , iy: 0.717646237 , iz: -0.039619033 , r: 0.491637169)
  private static let Data1992_477 = simd_quatd(ix: -0.491637169 , iy: -0.039619033 , iz: 0.717646237 , r: -0.491637169)
  private static let Data1992_478 = simd_quatd(ix: 0.152623567 , iy: 0.378632635 , iz: -0.378632635 , r: 0.830650771)
  private static let Data1992_479 = simd_quatd(ix: 0.717646237 , iy: 0.491637169 , iz: -0.491637169 , r: 0.039619033)
  private static let Data1992_480 = simd_quatd(ix: 0.378632635 , iy: 0.830650771 , iz: -0.152623567 , r: 0.378632635)
  private static let Data1992_481 = simd_quatd(ix: -0.378632635 , iy: -0.152623567 , iz: 0.830650771 , r: -0.378632635)
  private static let Data1992_482 = simd_quatd(ix: 0.039619033 , iy: 0.491637169 , iz: -0.491637169 , r: 0.717646237)
  private static let Data1992_483 = simd_quatd(ix: 0.830650771 , iy: 0.152623567 , iz: -0.378632635 , r: 0.378632635)
  private static let Data1992_484 = simd_quatd(ix: 0.830650771 , iy: 0.378632635 , iz: -0.152623567 , r: 0.378632635)
  private static let Data1992_485 = simd_quatd(ix: -0.491637169 , iy: -0.491637169 , iz: 0.717646237 , r: -0.039619033)
  private static let Data1992_486 = simd_quatd(ix: 0.491637169 , iy: 0.039619033 , iz: -0.491637169 , r: 0.717646237)
  private static let Data1992_487 = simd_quatd(ix: 0.491637169 , iy: 0.491637169 , iz: -0.039619033 , r: 0.717646237)
  private static let Data1992_488 = simd_quatd(ix: 0.491637169 , iy: 0.717646237 , iz: -0.491637169 , r: 0.039619033)
  private static let Data1992_489 = simd_quatd(ix: 0.152623567 , iy: 0.830650771 , iz: -0.378632635 , r: 0.378632635)
  private static let Data1992_490 = simd_quatd(ix: -0.152623567 , iy: -0.378632635 , iz: 0.830650771 , r: -0.378632635)
  private static let Data1992_491 = simd_quatd(ix: 0.717646237 , iy: 0.039619033 , iz: -0.491637169 , r: 0.491637169)
  private static let Data1992_492 = simd_quatd(ix: 0.717646237 , iy: 0.491637169 , iz: -0.039619033 , r: 0.491637169)
  private static let Data1992_493 = simd_quatd(ix: -0.378632635 , iy: -0.378632635 , iz: 0.830650771 , r: -0.152623567)
  private static let Data1992_494 = simd_quatd(ix: 0.378632635 , iy: 0.152623567 , iz: -0.378632635 , r: 0.830650771)
  private static let Data1992_495 = simd_quatd(ix: 0.378632635 , iy: 0.378632635 , iz: -0.152623567 , r: 0.830650771)
  private static let Data1992_496 = simd_quatd(ix: 0.378632635 , iy: 0.830650771 , iz: -0.378632635 , r: 0.152623567)
  private static let Data1992_497 = simd_quatd(ix: 0.039619033 , iy: 0.717646237 , iz: -0.491637169 , r: 0.491637169)
  private static let Data1992_498 = simd_quatd(ix: -0.039619033 , iy: -0.491637169 , iz: 0.717646237 , r: -0.491637169)
  private static let Data1992_499 = simd_quatd(ix: 0.500000000 , iy: -0.500000000 , iz: 0.500000000 , r: 0.500000000)
  private static let Data1992_500 = simd_quatd(ix: 0.424471885 , iy: -0.424471885 , iz: 0.677842795 , r: 0.424471885)
  private static let Data1992_501 = simd_quatd(ix: 0.297786430 , iy: -0.551157340 , iz: 0.551157340 , r: 0.551157340)
  private static let Data1992_502 = simd_quatd(ix: 0.551157340 , iy: -0.551157340 , iz: 0.551157340 , r: 0.297786430)
  private static let Data1992_503 = simd_quatd(ix: -0.424471885 , iy: 0.677842795 , iz: -0.424471885 , r: -0.424471885)
  private static let Data1992_504 = simd_quatd(ix: 0.551157340 , iy: -0.297786430 , iz: 0.551157340 , r: 0.551157340)
  private static let Data1992_505 = simd_quatd(ix: 0.424471885 , iy: -0.424471885 , iz: 0.424471885 , r: 0.677842795)
  private static let Data1992_506 = simd_quatd(ix: 0.677842795 , iy: -0.424471885 , iz: 0.424471885 , r: 0.424471885)
  private static let Data1992_507 = simd_quatd(ix: 0.551157340 , iy: -0.551157340 , iz: 0.297786430 , r: 0.551157340)
  private static let Data1992_508 = simd_quatd(ix: 0.609627522 , iy: -0.358265662 , iz: 0.609627522 , r: 0.358265662)
  private static let Data1992_509 = simd_quatd(ix: 0.358265662 , iy: -0.609627522 , iz: 0.358265662 , r: 0.609627522)
  private static let Data1992_510 = simd_quatd(ix: -0.358265662 , iy: 0.609627522 , iz: -0.609627522 , r: -0.358265662)
  private static let Data1992_511 = simd_quatd(ix: 0.358265662 , iy: -0.358265662 , iz: 0.609627522 , r: 0.609627522)
  private static let Data1992_512 = simd_quatd(ix: 0.609627522 , iy: -0.358265662 , iz: 0.358265662 , r: 0.609627522)
  private static let Data1992_513 = simd_quatd(ix: 0.609627522 , iy: -0.609627522 , iz: 0.358265662 , r: 0.358265662)
  private static let Data1992_514 = simd_quatd(ix: 0.469346375 , iy: -0.225567868 , iz: 0.713124882 , r: 0.469346375)
  private static let Data1992_515 = simd_quatd(ix: 0.225567868 , iy: -0.469346375 , iz: 0.469346375 , r: 0.713124882)
  private static let Data1992_516 = simd_quatd(ix: 0.713124882 , iy: -0.469346375 , iz: 0.469346375 , r: 0.225567868)
  private static let Data1992_517 = simd_quatd(ix: -0.469346375 , iy: 0.713124882 , iz: -0.225567868 , r: -0.469346375)
  private static let Data1992_518 = simd_quatd(ix: 0.469346375 , iy: -0.469346375 , iz: 0.713124882 , r: 0.225567868)
  private static let Data1992_519 = simd_quatd(ix: 0.225567868 , iy: -0.469346375 , iz: 0.713124882 , r: 0.469346375)
  private static let Data1992_520 = simd_quatd(ix: 0.713124882 , iy: -0.225567868 , iz: 0.469346375 , r: 0.469346375)
  private static let Data1992_521 = simd_quatd(ix: -0.469346375 , iy: 0.713124882 , iz: -0.469346375 , r: -0.225567868)
  private static let Data1992_522 = simd_quatd(ix: -0.225567868 , iy: 0.713124882 , iz: -0.469346375 , r: -0.469346375)
  private static let Data1992_523 = simd_quatd(ix: 0.469346375 , iy: -0.225567868 , iz: 0.469346375 , r: 0.713124882)
  private static let Data1992_524 = simd_quatd(ix: 0.469346375 , iy: -0.469346375 , iz: 0.225567868 , r: 0.713124882)
  private static let Data1992_525 = simd_quatd(ix: 0.713124882 , iy: -0.469346375 , iz: 0.225567868 , r: 0.469346375)
  private static let Data1992_526 = simd_quatd(ix: 0.337571289 , iy: -0.337571289 , iz: 0.811256356 , r: 0.337571289)
  private static let Data1992_527 = simd_quatd(ix: 0.100728756 , iy: -0.574413822 , iz: 0.574413822 , r: 0.574413822)
  private static let Data1992_528 = simd_quatd(ix: 0.574413822 , iy: -0.574413822 , iz: 0.574413822 , r: 0.100728756)
  private static let Data1992_529 = simd_quatd(ix: -0.337571289 , iy: 0.811256356 , iz: -0.337571289 , r: -0.337571289)
  private static let Data1992_530 = simd_quatd(ix: 0.574413822 , iy: -0.100728756 , iz: 0.574413822 , r: 0.574413822)
  private static let Data1992_531 = simd_quatd(ix: 0.337571289 , iy: -0.337571289 , iz: 0.337571289 , r: 0.811256356)
  private static let Data1992_532 = simd_quatd(ix: 0.811256356 , iy: -0.337571289 , iz: 0.337571289 , r: 0.337571289)
  private static let Data1992_533 = simd_quatd(ix: 0.574413822 , iy: -0.574413822 , iz: 0.100728756 , r: 0.574413822)
  private static let Data1992_534 = simd_quatd(ix: 0.518854134 , iy: -0.280333236 , iz: 0.757375033 , r: 0.280333236)
  private static let Data1992_535 = simd_quatd(ix: 0.161072786 , iy: -0.638114584 , iz: 0.399593685 , r: 0.638114584)
  private static let Data1992_536 = simd_quatd(ix: 0.638114584 , iy: -0.399593685 , iz: 0.638114584 , r: 0.161072786)
  private static let Data1992_537 = simd_quatd(ix: -0.280333236 , iy: 0.757375033 , iz: -0.280333236 , r: -0.518854134)
  private static let Data1992_538 = simd_quatd(ix: 0.638114584 , iy: -0.161072786 , iz: 0.638114584 , r: 0.399593685)
  private static let Data1992_539 = simd_quatd(ix: 0.280333236 , iy: -0.518854134 , iz: 0.280333236 , r: 0.757375033)
  private static let Data1992_540 = simd_quatd(ix: 0.757375033 , iy: -0.280333236 , iz: 0.518854134 , r: 0.280333236)
  private static let Data1992_541 = simd_quatd(ix: 0.399593685 , iy: -0.638114584 , iz: 0.161072786 , r: 0.638114584)
  private static let Data1992_542 = simd_quatd(ix: 0.280333236 , iy: -0.518854134 , iz: 0.757375033 , r: 0.280333236)
  private static let Data1992_543 = simd_quatd(ix: 0.280333236 , iy: -0.280333236 , iz: 0.757375033 , r: 0.518854134)
  private static let Data1992_544 = simd_quatd(ix: 0.638114584 , iy: -0.161072786 , iz: 0.399593685 , r: 0.638114584)
  private static let Data1992_545 = simd_quatd(ix: 0.638114584 , iy: -0.638114584 , iz: 0.399593685 , r: 0.161072786)
  private static let Data1992_546 = simd_quatd(ix: -0.161072786 , iy: 0.638114584 , iz: -0.638114584 , r: -0.399593685)
  private static let Data1992_547 = simd_quatd(ix: 0.399593685 , iy: -0.161072786 , iz: 0.638114584 , r: 0.638114584)
  private static let Data1992_548 = simd_quatd(ix: 0.518854134 , iy: -0.280333236 , iz: 0.280333236 , r: 0.757375033)
  private static let Data1992_549 = simd_quatd(ix: 0.757375033 , iy: -0.518854134 , iz: 0.280333236 , r: 0.280333236)
  private static let Data1992_550 = simd_quatd(ix: -0.399593685 , iy: 0.638114584 , iz: -0.638114584 , r: -0.161072786)
  private static let Data1992_551 = simd_quatd(ix: 0.161072786 , iy: -0.399593685 , iz: 0.638114584 , r: 0.638114584)
  private static let Data1992_552 = simd_quatd(ix: 0.757375033 , iy: -0.280333236 , iz: 0.280333236 , r: 0.518854134)
  private static let Data1992_553 = simd_quatd(ix: -0.518854134 , iy: 0.757375033 , iz: -0.280333236 , r: -0.280333236)
  private static let Data1992_554 = simd_quatd(ix: -0.280333236 , iy: 0.757375033 , iz: -0.518854134 , r: -0.280333236)
  private static let Data1992_555 = simd_quatd(ix: 0.280333236 , iy: -0.280333236 , iz: 0.518854134 , r: 0.757375033)
  private static let Data1992_556 = simd_quatd(ix: 0.638114584 , iy: -0.399593685 , iz: 0.161072786 , r: 0.638114584)
  private static let Data1992_557 = simd_quatd(ix: 0.638114584 , iy: -0.638114584 , iz: 0.161072786 , r: 0.399593685)
  private static let Data1992_558 = simd_quatd(ix: 0.378632635 , iy: -0.152623567 , iz: 0.830650771 , r: 0.378632635)
  private static let Data1992_559 = simd_quatd(ix: 0.039619033 , iy: -0.491637169 , iz: 0.491637169 , r: 0.717646237)
  private static let Data1992_560 = simd_quatd(ix: 0.717646237 , iy: -0.491637169 , iz: 0.491637169 , r: 0.039619033)
  private static let Data1992_561 = simd_quatd(ix: -0.378632635 , iy: 0.830650771 , iz: -0.152623567 , r: -0.378632635)
  private static let Data1992_562 = simd_quatd(ix: 0.491637169 , iy: -0.039619033 , iz: 0.717646237 , r: 0.491637169)
  private static let Data1992_563 = simd_quatd(ix: 0.152623567 , iy: -0.378632635 , iz: 0.378632635 , r: 0.830650771)
  private static let Data1992_564 = simd_quatd(ix: 0.830650771 , iy: -0.378632635 , iz: 0.378632635 , r: 0.152623567)
  private static let Data1992_565 = simd_quatd(ix: -0.491637169 , iy: 0.717646237 , iz: -0.039619033 , r: -0.491637169)
  private static let Data1992_566 = simd_quatd(ix: 0.378632635 , iy: -0.378632635 , iz: 0.830650771 , r: 0.152623567)
  private static let Data1992_567 = simd_quatd(ix: 0.152623567 , iy: -0.378632635 , iz: 0.830650771 , r: 0.378632635)
  private static let Data1992_568 = simd_quatd(ix: 0.717646237 , iy: -0.039619033 , iz: 0.491637169 , r: 0.491637169)
  private static let Data1992_569 = simd_quatd(ix: -0.491637169 , iy: 0.717646237 , iz: -0.491637169 , r: -0.039619033)
  private static let Data1992_570 = simd_quatd(ix: -0.039619033 , iy: 0.717646237 , iz: -0.491637169 , r: -0.491637169)
  private static let Data1992_571 = simd_quatd(ix: 0.491637169 , iy: -0.039619033 , iz: 0.491637169 , r: 0.717646237)
  private static let Data1992_572 = simd_quatd(ix: 0.378632635 , iy: -0.378632635 , iz: 0.152623567 , r: 0.830650771)
  private static let Data1992_573 = simd_quatd(ix: 0.830650771 , iy: -0.378632635 , iz: 0.152623567 , r: 0.378632635)
  private static let Data1992_574 = simd_quatd(ix: 0.491637169 , iy: -0.491637169 , iz: 0.717646237 , r: 0.039619033)
  private static let Data1992_575 = simd_quatd(ix: 0.039619033 , iy: -0.491637169 , iz: 0.717646237 , r: 0.491637169)
  private static let Data1992_576 = simd_quatd(ix: 0.830650771 , iy: -0.152623567 , iz: 0.378632635 , r: 0.378632635)
  private static let Data1992_577 = simd_quatd(ix: -0.378632635 , iy: 0.830650771 , iz: -0.378632635 , r: -0.152623567)
  private static let Data1992_578 = simd_quatd(ix: -0.152623567 , iy: 0.830650771 , iz: -0.378632635 , r: -0.378632635)
  private static let Data1992_579 = simd_quatd(ix: 0.378632635 , iy: -0.152623567 , iz: 0.378632635 , r: 0.830650771)
  private static let Data1992_580 = simd_quatd(ix: 0.491637169 , iy: -0.491637169 , iz: 0.039619033 , r: 0.717646237)
  private static let Data1992_581 = simd_quatd(ix: 0.717646237 , iy: -0.491637169 , iz: 0.039619033 , r: 0.491637169)
  private static let Data1992_582 = simd_quatd(ix: 0.500000000 , iy: -0.500000000 , iz: -0.500000000 , r: 0.500000000)
  private static let Data1992_583 = simd_quatd(ix: 0.551157340 , iy: -0.551157340 , iz: -0.297786430 , r: 0.551157340)
  private static let Data1992_584 = simd_quatd(ix: 0.424471885 , iy: -0.424471885 , iz: -0.424471885 , r: 0.677842795)
  private static let Data1992_585 = simd_quatd(ix: -0.424471885 , iy: 0.677842795 , iz: 0.424471885 , r: -0.424471885)
  private static let Data1992_586 = simd_quatd(ix: 0.297786430 , iy: -0.551157340 , iz: -0.551157340 , r: 0.551157340)
  private static let Data1992_587 = simd_quatd(ix: 0.677842795 , iy: -0.424471885 , iz: -0.424471885 , r: 0.424471885)
  private static let Data1992_588 = simd_quatd(ix: 0.551157340 , iy: -0.297786430 , iz: -0.551157340 , r: 0.551157340)
  private static let Data1992_589 = simd_quatd(ix: 0.551157340 , iy: -0.551157340 , iz: -0.551157340 , r: 0.297786430)
  private static let Data1992_590 = simd_quatd(ix: -0.424471885 , iy: 0.424471885 , iz: 0.677842795 , r: -0.424471885)
  private static let Data1992_591 = simd_quatd(ix: 0.609627522 , iy: -0.609627522 , iz: -0.358265662 , r: 0.358265662)
  private static let Data1992_592 = simd_quatd(ix: 0.358265662 , iy: -0.358265662 , iz: -0.609627522 , r: 0.609627522)
  private static let Data1992_593 = simd_quatd(ix: 0.358265662 , iy: -0.609627522 , iz: -0.358265662 , r: 0.609627522)
  private static let Data1992_594 = simd_quatd(ix: 0.609627522 , iy: -0.358265662 , iz: -0.358265662 , r: 0.609627522)
  private static let Data1992_595 = simd_quatd(ix: 0.609627522 , iy: -0.358265662 , iz: -0.609627522 , r: 0.358265662)
  private static let Data1992_596 = simd_quatd(ix: -0.358265662 , iy: 0.609627522 , iz: 0.609627522 , r: -0.358265662)
  private static let Data1992_597 = simd_quatd(ix: 0.713124882 , iy: -0.469346375 , iz: -0.225567868 , r: 0.469346375)
  private static let Data1992_598 = simd_quatd(ix: 0.469346375 , iy: -0.225567868 , iz: -0.469346375 , r: 0.713124882)
  private static let Data1992_599 = simd_quatd(ix: -0.469346375 , iy: 0.713124882 , iz: 0.469346375 , r: -0.225567868)
  private static let Data1992_600 = simd_quatd(ix: -0.225567868 , iy: 0.469346375 , iz: 0.713124882 , r: -0.469346375)
  private static let Data1992_601 = simd_quatd(ix: -0.469346375 , iy: 0.713124882 , iz: 0.225567868 , r: -0.469346375)
  private static let Data1992_602 = simd_quatd(ix: 0.469346375 , iy: -0.469346375 , iz: -0.225567868 , r: 0.713124882)
  private static let Data1992_603 = simd_quatd(ix: 0.713124882 , iy: -0.469346375 , iz: -0.469346375 , r: 0.225567868)
  private static let Data1992_604 = simd_quatd(ix: -0.225567868 , iy: 0.713124882 , iz: 0.469346375 , r: -0.469346375)
  private static let Data1992_605 = simd_quatd(ix: 0.225567868 , iy: -0.469346375 , iz: -0.469346375 , r: 0.713124882)
  private static let Data1992_606 = simd_quatd(ix: 0.713124882 , iy: -0.225567868 , iz: -0.469346375 , r: 0.469346375)
  private static let Data1992_607 = simd_quatd(ix: -0.469346375 , iy: 0.225567868 , iz: 0.713124882 , r: -0.469346375)
  private static let Data1992_608 = simd_quatd(ix: -0.469346375 , iy: 0.469346375 , iz: 0.713124882 , r: -0.225567868)
  private static let Data1992_609 = simd_quatd(ix: 0.574413822 , iy: -0.574413822 , iz: -0.100728756 , r: 0.574413822)
  private static let Data1992_610 = simd_quatd(ix: 0.337571289 , iy: -0.337571289 , iz: -0.337571289 , r: 0.811256356)
  private static let Data1992_611 = simd_quatd(ix: -0.337571289 , iy: 0.811256356 , iz: 0.337571289 , r: -0.337571289)
  private static let Data1992_612 = simd_quatd(ix: 0.100728756 , iy: -0.574413822 , iz: -0.574413822 , r: 0.574413822)
  private static let Data1992_613 = simd_quatd(ix: 0.811256356 , iy: -0.337571289 , iz: -0.337571289 , r: 0.337571289)
  private static let Data1992_614 = simd_quatd(ix: 0.574413822 , iy: -0.100728756 , iz: -0.574413822 , r: 0.574413822)
  private static let Data1992_615 = simd_quatd(ix: 0.574413822 , iy: -0.574413822 , iz: -0.574413822 , r: 0.100728756)
  private static let Data1992_616 = simd_quatd(ix: -0.337571289 , iy: 0.337571289 , iz: 0.811256356 , r: -0.337571289)
  private static let Data1992_617 = simd_quatd(ix: 0.638114584 , iy: -0.638114584 , iz: -0.161072786 , r: 0.399593685)
  private static let Data1992_618 = simd_quatd(ix: 0.280333236 , iy: -0.280333236 , iz: -0.518854134 , r: 0.757375033)
  private static let Data1992_619 = simd_quatd(ix: -0.518854134 , iy: 0.757375033 , iz: 0.280333236 , r: -0.280333236)
  private static let Data1992_620 = simd_quatd(ix: 0.161072786 , iy: -0.399593685 , iz: -0.638114584 , r: 0.638114584)
  private static let Data1992_621 = simd_quatd(ix: 0.757375033 , iy: -0.518854134 , iz: -0.280333236 , r: 0.280333236)
  private static let Data1992_622 = simd_quatd(ix: 0.399593685 , iy: -0.161072786 , iz: -0.638114584 , r: 0.638114584)
  private static let Data1992_623 = simd_quatd(ix: 0.638114584 , iy: -0.638114584 , iz: -0.399593685 , r: 0.161072786)
  private static let Data1992_624 = simd_quatd(ix: -0.280333236 , iy: 0.280333236 , iz: 0.757375033 , r: -0.518854134)
  private static let Data1992_625 = simd_quatd(ix: 0.399593685 , iy: -0.638114584 , iz: -0.161072786 , r: 0.638114584)
  private static let Data1992_626 = simd_quatd(ix: 0.638114584 , iy: -0.399593685 , iz: -0.161072786 , r: 0.638114584)
  private static let Data1992_627 = simd_quatd(ix: 0.757375033 , iy: -0.280333236 , iz: -0.518854134 , r: 0.280333236)
  private static let Data1992_628 = simd_quatd(ix: -0.280333236 , iy: 0.757375033 , iz: 0.518854134 , r: -0.280333236)
  private static let Data1992_629 = simd_quatd(ix: 0.280333236 , iy: -0.518854134 , iz: -0.280333236 , r: 0.757375033)
  private static let Data1992_630 = simd_quatd(ix: 0.757375033 , iy: -0.280333236 , iz: -0.280333236 , r: 0.518854134)
  private static let Data1992_631 = simd_quatd(ix: 0.638114584 , iy: -0.161072786 , iz: -0.638114584 , r: 0.399593685)
  private static let Data1992_632 = simd_quatd(ix: -0.399593685 , iy: 0.638114584 , iz: 0.638114584 , r: -0.161072786)
  private static let Data1992_633 = simd_quatd(ix: -0.280333236 , iy: 0.757375033 , iz: 0.280333236 , r: -0.518854134)
  private static let Data1992_634 = simd_quatd(ix: 0.518854134 , iy: -0.280333236 , iz: -0.280333236 , r: 0.757375033)
  private static let Data1992_635 = simd_quatd(ix: 0.638114584 , iy: -0.399593685 , iz: -0.638114584 , r: 0.161072786)
  private static let Data1992_636 = simd_quatd(ix: -0.161072786 , iy: 0.638114584 , iz: 0.638114584 , r: -0.399593685)
  private static let Data1992_637 = simd_quatd(ix: 0.161072786 , iy: -0.638114584 , iz: -0.399593685 , r: 0.638114584)
  private static let Data1992_638 = simd_quatd(ix: 0.638114584 , iy: -0.161072786 , iz: -0.399593685 , r: 0.638114584)
  private static let Data1992_639 = simd_quatd(ix: -0.518854134 , iy: 0.280333236 , iz: 0.757375033 , r: -0.280333236)
  private static let Data1992_640 = simd_quatd(ix: -0.280333236 , iy: 0.518854134 , iz: 0.757375033 , r: -0.280333236)
  private static let Data1992_641 = simd_quatd(ix: 0.717646237 , iy: -0.491637169 , iz: -0.039619033 , r: 0.491637169)
  private static let Data1992_642 = simd_quatd(ix: 0.378632635 , iy: -0.152623567 , iz: -0.378632635 , r: 0.830650771)
  private static let Data1992_643 = simd_quatd(ix: -0.378632635 , iy: 0.830650771 , iz: 0.378632635 , r: -0.152623567)
  private static let Data1992_644 = simd_quatd(ix: -0.039619033 , iy: 0.491637169 , iz: 0.717646237 , r: -0.491637169)
  private static let Data1992_645 = simd_quatd(ix: 0.830650771 , iy: -0.378632635 , iz: -0.152623567 , r: 0.378632635)
  private static let Data1992_646 = simd_quatd(ix: 0.491637169 , iy: -0.039619033 , iz: -0.491637169 , r: 0.717646237)
  private static let Data1992_647 = simd_quatd(ix: -0.491637169 , iy: 0.717646237 , iz: 0.491637169 , r: -0.039619033)
  private static let Data1992_648 = simd_quatd(ix: -0.152623567 , iy: 0.378632635 , iz: 0.830650771 , r: -0.378632635)
  private static let Data1992_649 = simd_quatd(ix: -0.491637169 , iy: 0.717646237 , iz: 0.039619033 , r: -0.491637169)
  private static let Data1992_650 = simd_quatd(ix: 0.491637169 , iy: -0.491637169 , iz: -0.039619033 , r: 0.717646237)
  private static let Data1992_651 = simd_quatd(ix: 0.830650771 , iy: -0.378632635 , iz: -0.378632635 , r: 0.152623567)
  private static let Data1992_652 = simd_quatd(ix: -0.152623567 , iy: 0.830650771 , iz: 0.378632635 , r: -0.378632635)
  private static let Data1992_653 = simd_quatd(ix: 0.152623567 , iy: -0.378632635 , iz: -0.378632635 , r: 0.830650771)
  private static let Data1992_654 = simd_quatd(ix: 0.830650771 , iy: -0.152623567 , iz: -0.378632635 , r: 0.378632635)
  private static let Data1992_655 = simd_quatd(ix: -0.491637169 , iy: 0.039619033 , iz: 0.717646237 , r: -0.491637169)
  private static let Data1992_656 = simd_quatd(ix: -0.491637169 , iy: 0.491637169 , iz: 0.717646237 , r: -0.039619033)
  private static let Data1992_657 = simd_quatd(ix: -0.378632635 , iy: 0.830650771 , iz: 0.152623567 , r: -0.378632635)
  private static let Data1992_658 = simd_quatd(ix: 0.378632635 , iy: -0.378632635 , iz: -0.152623567 , r: 0.830650771)
  private static let Data1992_659 = simd_quatd(ix: 0.717646237 , iy: -0.491637169 , iz: -0.491637169 , r: 0.039619033)
  private static let Data1992_660 = simd_quatd(ix: -0.039619033 , iy: 0.717646237 , iz: 0.491637169 , r: -0.491637169)
  private static let Data1992_661 = simd_quatd(ix: 0.039619033 , iy: -0.491637169 , iz: -0.491637169 , r: 0.717646237)
  private static let Data1992_662 = simd_quatd(ix: 0.717646237 , iy: -0.039619033 , iz: -0.491637169 , r: 0.491637169)
  private static let Data1992_663 = simd_quatd(ix: -0.378632635 , iy: 0.152623567 , iz: 0.830650771 , r: -0.378632635)
  private static let Data1992_664 = simd_quatd(ix: -0.378632635 , iy: 0.378632635 , iz: 0.830650771 , r: -0.152623567)
  private static let Data1992_665 = simd_quatd(ix: -0.500000000 , iy: 0.500000000 , iz: 0.500000000 , r: 0.500000000)
  private static let Data1992_666 = simd_quatd(ix: -0.424471885 , iy: 0.677842795 , iz: 0.424471885 , r: 0.424471885)
  private static let Data1992_667 = simd_quatd(ix: 0.551157340 , iy: -0.551157340 , iz: -0.551157340 , r: -0.297786430)
  private static let Data1992_668 = simd_quatd(ix: -0.297786430 , iy: 0.551157340 , iz: 0.551157340 , r: 0.551157340)
  private static let Data1992_669 = simd_quatd(ix: -0.424471885 , iy: 0.424471885 , iz: 0.677842795 , r: 0.424471885)
  private static let Data1992_670 = simd_quatd(ix: -0.551157340 , iy: 0.551157340 , iz: 0.297786430 , r: 0.551157340)
  private static let Data1992_671 = simd_quatd(ix: 0.677842795 , iy: -0.424471885 , iz: -0.424471885 , r: -0.424471885)
  private static let Data1992_672 = simd_quatd(ix: -0.424471885 , iy: 0.424471885 , iz: 0.424471885 , r: 0.677842795)
  private static let Data1992_673 = simd_quatd(ix: -0.551157340 , iy: 0.297786430 , iz: 0.551157340 , r: 0.551157340)
  private static let Data1992_674 = simd_quatd(ix: -0.358265662 , iy: 0.609627522 , iz: 0.358265662 , r: 0.609627522)
  private static let Data1992_675 = simd_quatd(ix: 0.609627522 , iy: -0.358265662 , iz: -0.609627522 , r: -0.358265662)
  private static let Data1992_676 = simd_quatd(ix: -0.358265662 , iy: 0.609627522 , iz: 0.609627522 , r: 0.358265662)
  private static let Data1992_677 = simd_quatd(ix: 0.609627522 , iy: -0.609627522 , iz: -0.358265662 , r: -0.358265662)
  private static let Data1992_678 = simd_quatd(ix: -0.609627522 , iy: 0.358265662 , iz: 0.358265662 , r: 0.609627522)
  private static let Data1992_679 = simd_quatd(ix: -0.358265662 , iy: 0.358265662 , iz: 0.609627522 , r: 0.609627522)
  private static let Data1992_680 = simd_quatd(ix: -0.469346375 , iy: 0.713124882 , iz: 0.225567868 , r: 0.469346375)
  private static let Data1992_681 = simd_quatd(ix: 0.713124882 , iy: -0.469346375 , iz: -0.469346375 , r: -0.225567868)
  private static let Data1992_682 = simd_quatd(ix: -0.225567868 , iy: 0.469346375 , iz: 0.469346375 , r: 0.713124882)
  private static let Data1992_683 = simd_quatd(ix: -0.469346375 , iy: 0.225567868 , iz: 0.713124882 , r: 0.469346375)
  private static let Data1992_684 = simd_quatd(ix: -0.225567868 , iy: 0.713124882 , iz: 0.469346375 , r: 0.469346375)
  private static let Data1992_685 = simd_quatd(ix: -0.469346375 , iy: 0.713124882 , iz: 0.469346375 , r: 0.225567868)
  private static let Data1992_686 = simd_quatd(ix: -0.469346375 , iy: 0.469346375 , iz: 0.225567868 , r: 0.713124882)
  private static let Data1992_687 = simd_quatd(ix: -0.225567868 , iy: 0.469346375 , iz: 0.713124882 , r: 0.469346375)
  private static let Data1992_688 = simd_quatd(ix: -0.469346375 , iy: 0.469346375 , iz: 0.713124882 , r: 0.225567868)
  private static let Data1992_689 = simd_quatd(ix: 0.713124882 , iy: -0.469346375 , iz: -0.225567868 , r: -0.469346375)
  private static let Data1992_690 = simd_quatd(ix: 0.713124882 , iy: -0.225567868 , iz: -0.469346375 , r: -0.469346375)
  private static let Data1992_691 = simd_quatd(ix: -0.469346375 , iy: 0.225567868 , iz: 0.469346375 , r: 0.713124882)
  private static let Data1992_692 = simd_quatd(ix: -0.337571289 , iy: 0.811256356 , iz: 0.337571289 , r: 0.337571289)
  private static let Data1992_693 = simd_quatd(ix: 0.574413822 , iy: -0.574413822 , iz: -0.574413822 , r: -0.100728756)
  private static let Data1992_694 = simd_quatd(ix: -0.100728756 , iy: 0.574413822 , iz: 0.574413822 , r: 0.574413822)
  private static let Data1992_695 = simd_quatd(ix: -0.337571289 , iy: 0.337571289 , iz: 0.811256356 , r: 0.337571289)
  private static let Data1992_696 = simd_quatd(ix: -0.574413822 , iy: 0.574413822 , iz: 0.100728756 , r: 0.574413822)
  private static let Data1992_697 = simd_quatd(ix: 0.811256356 , iy: -0.337571289 , iz: -0.337571289 , r: -0.337571289)
  private static let Data1992_698 = simd_quatd(ix: -0.337571289 , iy: 0.337571289 , iz: 0.337571289 , r: 0.811256356)
  private static let Data1992_699 = simd_quatd(ix: -0.574413822 , iy: 0.100728756 , iz: 0.574413822 , r: 0.574413822)
  private static let Data1992_700 = simd_quatd(ix: -0.280333236 , iy: 0.757375033 , iz: 0.280333236 , r: 0.518854134)
  private static let Data1992_701 = simd_quatd(ix: 0.638114584 , iy: -0.399593685 , iz: -0.638114584 , r: -0.161072786)
  private static let Data1992_702 = simd_quatd(ix: -0.161072786 , iy: 0.638114584 , iz: 0.399593685 , r: 0.638114584)
  private static let Data1992_703 = simd_quatd(ix: -0.518854134 , iy: 0.280333236 , iz: 0.757375033 , r: 0.280333236)
  private static let Data1992_704 = simd_quatd(ix: -0.399593685 , iy: 0.638114584 , iz: 0.161072786 , r: 0.638114584)
  private static let Data1992_705 = simd_quatd(ix: 0.757375033 , iy: -0.280333236 , iz: -0.518854134 , r: -0.280333236)
  private static let Data1992_706 = simd_quatd(ix: -0.280333236 , iy: 0.518854134 , iz: 0.280333236 , r: 0.757375033)
  private static let Data1992_707 = simd_quatd(ix: 0.638114584 , iy: -0.161072786 , iz: -0.638114584 , r: -0.399593685)
  private static let Data1992_708 = simd_quatd(ix: -0.280333236 , iy: 0.757375033 , iz: 0.518854134 , r: 0.280333236)
  private static let Data1992_709 = simd_quatd(ix: -0.518854134 , iy: 0.757375033 , iz: 0.280333236 , r: 0.280333236)
  private static let Data1992_710 = simd_quatd(ix: -0.638114584 , iy: 0.399593685 , iz: 0.161072786 , r: 0.638114584)
  private static let Data1992_711 = simd_quatd(ix: -0.161072786 , iy: 0.399593685 , iz: 0.638114584 , r: 0.638114584)
  private static let Data1992_712 = simd_quatd(ix: -0.399593685 , iy: 0.638114584 , iz: 0.638114584 , r: 0.161072786)
  private static let Data1992_713 = simd_quatd(ix: 0.638114584 , iy: -0.638114584 , iz: -0.161072786 , r: -0.399593685)
  private static let Data1992_714 = simd_quatd(ix: 0.757375033 , iy: -0.280333236 , iz: -0.280333236 , r: -0.518854134)
  private static let Data1992_715 = simd_quatd(ix: -0.280333236 , iy: 0.280333236 , iz: 0.518854134 , r: 0.757375033)
  private static let Data1992_716 = simd_quatd(ix: -0.161072786 , iy: 0.638114584 , iz: 0.638114584 , r: 0.399593685)
  private static let Data1992_717 = simd_quatd(ix: 0.638114584 , iy: -0.638114584 , iz: -0.399593685 , r: -0.161072786)
  private static let Data1992_718 = simd_quatd(ix: -0.518854134 , iy: 0.280333236 , iz: 0.280333236 , r: 0.757375033)
  private static let Data1992_719 = simd_quatd(ix: -0.280333236 , iy: 0.280333236 , iz: 0.757375033 , r: 0.518854134)
  private static let Data1992_720 = simd_quatd(ix: -0.280333236 , iy: 0.518854134 , iz: 0.757375033 , r: 0.280333236)
  private static let Data1992_721 = simd_quatd(ix: 0.757375033 , iy: -0.518854134 , iz: -0.280333236 , r: -0.280333236)
  private static let Data1992_722 = simd_quatd(ix: -0.638114584 , iy: 0.161072786 , iz: 0.399593685 , r: 0.638114584)
  private static let Data1992_723 = simd_quatd(ix: -0.399593685 , iy: 0.161072786 , iz: 0.638114584 , r: 0.638114584)
  private static let Data1992_724 = simd_quatd(ix: -0.378632635 , iy: 0.830650771 , iz: 0.152623567 , r: 0.378632635)
  private static let Data1992_725 = simd_quatd(ix: 0.717646237 , iy: -0.491637169 , iz: -0.491637169 , r: -0.039619033)
  private static let Data1992_726 = simd_quatd(ix: -0.039619033 , iy: 0.491637169 , iz: 0.491637169 , r: 0.717646237)
  private static let Data1992_727 = simd_quatd(ix: -0.378632635 , iy: 0.152623567 , iz: 0.830650771 , r: 0.378632635)
  private static let Data1992_728 = simd_quatd(ix: -0.491637169 , iy: 0.717646237 , iz: 0.039619033 , r: 0.491637169)
  private static let Data1992_729 = simd_quatd(ix: 0.830650771 , iy: -0.378632635 , iz: -0.378632635 , r: -0.152623567)
  private static let Data1992_730 = simd_quatd(ix: -0.152623567 , iy: 0.378632635 , iz: 0.378632635 , r: 0.830650771)
  private static let Data1992_731 = simd_quatd(ix: -0.491637169 , iy: 0.039619033 , iz: 0.717646237 , r: 0.491637169)
  private static let Data1992_732 = simd_quatd(ix: -0.152623567 , iy: 0.830650771 , iz: 0.378632635 , r: 0.378632635)
  private static let Data1992_733 = simd_quatd(ix: -0.378632635 , iy: 0.830650771 , iz: 0.378632635 , r: 0.152623567)
  private static let Data1992_734 = simd_quatd(ix: -0.491637169 , iy: 0.491637169 , iz: 0.039619033 , r: 0.717646237)
  private static let Data1992_735 = simd_quatd(ix: -0.039619033 , iy: 0.491637169 , iz: 0.717646237 , r: 0.491637169)
  private static let Data1992_736 = simd_quatd(ix: -0.491637169 , iy: 0.491637169 , iz: 0.717646237 , r: 0.039619033)
  private static let Data1992_737 = simd_quatd(ix: 0.717646237 , iy: -0.491637169 , iz: -0.039619033 , r: -0.491637169)
  private static let Data1992_738 = simd_quatd(ix: 0.830650771 , iy: -0.152623567 , iz: -0.378632635 , r: -0.378632635)
  private static let Data1992_739 = simd_quatd(ix: -0.378632635 , iy: 0.152623567 , iz: 0.378632635 , r: 0.830650771)
  private static let Data1992_740 = simd_quatd(ix: -0.039619033 , iy: 0.717646237 , iz: 0.491637169 , r: 0.491637169)
  private static let Data1992_741 = simd_quatd(ix: -0.491637169 , iy: 0.717646237 , iz: 0.491637169 , r: 0.039619033)
  private static let Data1992_742 = simd_quatd(ix: -0.378632635 , iy: 0.378632635 , iz: 0.152623567 , r: 0.830650771)
  private static let Data1992_743 = simd_quatd(ix: -0.152623567 , iy: 0.378632635 , iz: 0.830650771 , r: 0.378632635)
  private static let Data1992_744 = simd_quatd(ix: -0.378632635 , iy: 0.378632635 , iz: 0.830650771 , r: 0.152623567)
  private static let Data1992_745 = simd_quatd(ix: 0.830650771 , iy: -0.378632635 , iz: -0.152623567 , r: -0.378632635)
  private static let Data1992_746 = simd_quatd(ix: 0.717646237 , iy: -0.039619033 , iz: -0.491637169 , r: -0.491637169)
  private static let Data1992_747 = simd_quatd(ix: -0.491637169 , iy: 0.039619033 , iz: 0.491637169 , r: 0.717646237)
  private static let Data1992_748 = simd_quatd(ix: -0.500000000 , iy: 0.500000000 , iz: -0.500000000 , r: 0.500000000)
  private static let Data1992_749 = simd_quatd(ix: -0.297786430 , iy: 0.551157340 , iz: -0.551157340 , r: 0.551157340)
  private static let Data1992_750 = simd_quatd(ix: -0.424471885 , iy: 0.677842795 , iz: -0.424471885 , r: 0.424471885)
  private static let Data1992_751 = simd_quatd(ix: -0.424471885 , iy: 0.424471885 , iz: -0.424471885 , r: 0.677842795)
  private static let Data1992_752 = simd_quatd(ix: -0.551157340 , iy: 0.551157340 , iz: -0.297786430 , r: 0.551157340)
  private static let Data1992_753 = simd_quatd(ix: 0.424471885 , iy: -0.424471885 , iz: 0.677842795 , r: -0.424471885)
  private static let Data1992_754 = simd_quatd(ix: 0.551157340 , iy: -0.551157340 , iz: 0.551157340 , r: -0.297786430)
  private static let Data1992_755 = simd_quatd(ix: -0.551157340 , iy: 0.297786430 , iz: -0.551157340 , r: 0.551157340)
  private static let Data1992_756 = simd_quatd(ix: 0.677842795 , iy: -0.424471885 , iz: 0.424471885 , r: -0.424471885)
  private static let Data1992_757 = simd_quatd(ix: -0.358265662 , iy: 0.358265662 , iz: -0.609627522 , r: 0.609627522)
  private static let Data1992_758 = simd_quatd(ix: 0.609627522 , iy: -0.609627522 , iz: 0.358265662 , r: -0.358265662)
  private static let Data1992_759 = simd_quatd(ix: -0.358265662 , iy: 0.609627522 , iz: -0.358265662 , r: 0.609627522)
  private static let Data1992_760 = simd_quatd(ix: -0.358265662 , iy: 0.609627522 , iz: -0.609627522 , r: 0.358265662)
  private static let Data1992_761 = simd_quatd(ix: 0.609627522 , iy: -0.358265662 , iz: 0.609627522 , r: -0.358265662)
  private static let Data1992_762 = simd_quatd(ix: -0.609627522 , iy: 0.358265662 , iz: -0.358265662 , r: 0.609627522)
  private static let Data1992_763 = simd_quatd(ix: 0.225567868 , iy: -0.469346375 , iz: 0.713124882 , r: -0.469346375)
  private static let Data1992_764 = simd_quatd(ix: -0.469346375 , iy: 0.713124882 , iz: -0.469346375 , r: 0.225567868)
  private static let Data1992_765 = simd_quatd(ix: -0.469346375 , iy: 0.225567868 , iz: -0.469346375 , r: 0.713124882)
  private static let Data1992_766 = simd_quatd(ix: 0.713124882 , iy: -0.469346375 , iz: 0.225567868 , r: -0.469346375)
  private static let Data1992_767 = simd_quatd(ix: -0.225567868 , iy: 0.469346375 , iz: -0.469346375 , r: 0.713124882)
  private static let Data1992_768 = simd_quatd(ix: -0.225567868 , iy: 0.713124882 , iz: -0.469346375 , r: 0.469346375)
  private static let Data1992_769 = simd_quatd(ix: 0.469346375 , iy: -0.225567868 , iz: 0.713124882 , r: -0.469346375)
  private static let Data1992_770 = simd_quatd(ix: -0.469346375 , iy: 0.469346375 , iz: -0.225567868 , r: 0.713124882)
  private static let Data1992_771 = simd_quatd(ix: -0.469346375 , iy: 0.713124882 , iz: -0.225567868 , r: 0.469346375)
  private static let Data1992_772 = simd_quatd(ix: 0.469346375 , iy: -0.469346375 , iz: 0.713124882 , r: -0.225567868)
  private static let Data1992_773 = simd_quatd(ix: 0.713124882 , iy: -0.469346375 , iz: 0.469346375 , r: -0.225567868)
  private static let Data1992_774 = simd_quatd(ix: 0.713124882 , iy: -0.225567868 , iz: 0.469346375 , r: -0.469346375)
  private static let Data1992_775 = simd_quatd(ix: -0.100728756 , iy: 0.574413822 , iz: -0.574413822 , r: 0.574413822)
  private static let Data1992_776 = simd_quatd(ix: -0.337571289 , iy: 0.811256356 , iz: -0.337571289 , r: 0.337571289)
  private static let Data1992_777 = simd_quatd(ix: -0.337571289 , iy: 0.337571289 , iz: -0.337571289 , r: 0.811256356)
  private static let Data1992_778 = simd_quatd(ix: -0.574413822 , iy: 0.574413822 , iz: -0.100728756 , r: 0.574413822)
  private static let Data1992_779 = simd_quatd(ix: 0.337571289 , iy: -0.337571289 , iz: 0.811256356 , r: -0.337571289)
  private static let Data1992_780 = simd_quatd(ix: 0.574413822 , iy: -0.574413822 , iz: 0.574413822 , r: -0.100728756)
  private static let Data1992_781 = simd_quatd(ix: -0.574413822 , iy: 0.100728756 , iz: -0.574413822 , r: 0.574413822)
  private static let Data1992_782 = simd_quatd(ix: 0.811256356 , iy: -0.337571289 , iz: 0.337571289 , r: -0.337571289)
  private static let Data1992_783 = simd_quatd(ix: -0.161072786 , iy: 0.399593685 , iz: -0.638114584 , r: 0.638114584)
  private static let Data1992_784 = simd_quatd(ix: -0.518854134 , iy: 0.757375033 , iz: -0.280333236 , r: 0.280333236)
  private static let Data1992_785 = simd_quatd(ix: -0.280333236 , iy: 0.280333236 , iz: -0.518854134 , r: 0.757375033)
  private static let Data1992_786 = simd_quatd(ix: 0.638114584 , iy: -0.638114584 , iz: 0.161072786 , r: -0.399593685)
  private static let Data1992_787 = simd_quatd(ix: 0.280333236 , iy: -0.280333236 , iz: 0.757375033 , r: -0.518854134)
  private static let Data1992_788 = simd_quatd(ix: 0.638114584 , iy: -0.638114584 , iz: 0.399593685 , r: -0.161072786)
  private static let Data1992_789 = simd_quatd(ix: -0.399593685 , iy: 0.161072786 , iz: -0.638114584 , r: 0.638114584)
  private static let Data1992_790 = simd_quatd(ix: 0.757375033 , iy: -0.518854134 , iz: 0.280333236 , r: -0.280333236)
  private static let Data1992_791 = simd_quatd(ix: -0.161072786 , iy: 0.638114584 , iz: -0.399593685 , r: 0.638114584)
  private static let Data1992_792 = simd_quatd(ix: -0.161072786 , iy: 0.638114584 , iz: -0.638114584 , r: 0.399593685)
  private static let Data1992_793 = simd_quatd(ix: 0.518854134 , iy: -0.280333236 , iz: 0.757375033 , r: -0.280333236)
  private static let Data1992_794 = simd_quatd(ix: -0.518854134 , iy: 0.280333236 , iz: -0.280333236 , r: 0.757375033)
  private static let Data1992_795 = simd_quatd(ix: -0.280333236 , iy: 0.757375033 , iz: -0.280333236 , r: 0.518854134)
  private static let Data1992_796 = simd_quatd(ix: 0.280333236 , iy: -0.518854134 , iz: 0.757375033 , r: -0.280333236)
  private static let Data1992_797 = simd_quatd(ix: 0.638114584 , iy: -0.399593685 , iz: 0.638114584 , r: -0.161072786)
  private static let Data1992_798 = simd_quatd(ix: -0.638114584 , iy: 0.161072786 , iz: -0.399593685 , r: 0.638114584)
  private static let Data1992_799 = simd_quatd(ix: -0.280333236 , iy: 0.518854134 , iz: -0.280333236 , r: 0.757375033)
  private static let Data1992_800 = simd_quatd(ix: -0.280333236 , iy: 0.757375033 , iz: -0.518854134 , r: 0.280333236)
  private static let Data1992_801 = simd_quatd(ix: 0.638114584 , iy: -0.161072786 , iz: 0.638114584 , r: -0.399593685)
  private static let Data1992_802 = simd_quatd(ix: -0.638114584 , iy: 0.399593685 , iz: -0.161072786 , r: 0.638114584)
  private static let Data1992_803 = simd_quatd(ix: -0.399593685 , iy: 0.638114584 , iz: -0.161072786 , r: 0.638114584)
  private static let Data1992_804 = simd_quatd(ix: -0.399593685 , iy: 0.638114584 , iz: -0.638114584 , r: 0.161072786)
  private static let Data1992_805 = simd_quatd(ix: 0.757375033 , iy: -0.280333236 , iz: 0.518854134 , r: -0.280333236)
  private static let Data1992_806 = simd_quatd(ix: 0.757375033 , iy: -0.280333236 , iz: 0.280333236 , r: -0.518854134)
  private static let Data1992_807 = simd_quatd(ix: 0.039619033 , iy: -0.491637169 , iz: 0.717646237 , r: -0.491637169)
  private static let Data1992_808 = simd_quatd(ix: -0.378632635 , iy: 0.830650771 , iz: -0.378632635 , r: 0.152623567)
  private static let Data1992_809 = simd_quatd(ix: -0.378632635 , iy: 0.152623567 , iz: -0.378632635 , r: 0.830650771)
  private static let Data1992_810 = simd_quatd(ix: 0.717646237 , iy: -0.491637169 , iz: 0.039619033 , r: -0.491637169)
  private static let Data1992_811 = simd_quatd(ix: 0.152623567 , iy: -0.378632635 , iz: 0.830650771 , r: -0.378632635)
  private static let Data1992_812 = simd_quatd(ix: -0.491637169 , iy: 0.717646237 , iz: -0.491637169 , r: 0.039619033)
  private static let Data1992_813 = simd_quatd(ix: -0.491637169 , iy: 0.039619033 , iz: -0.491637169 , r: 0.717646237)
  private static let Data1992_814 = simd_quatd(ix: 0.830650771 , iy: -0.378632635 , iz: 0.152623567 , r: -0.378632635)
  private static let Data1992_815 = simd_quatd(ix: -0.039619033 , iy: 0.491637169 , iz: -0.491637169 , r: 0.717646237)
  private static let Data1992_816 = simd_quatd(ix: -0.039619033 , iy: 0.717646237 , iz: -0.491637169 , r: 0.491637169)
  private static let Data1992_817 = simd_quatd(ix: 0.378632635 , iy: -0.152623567 , iz: 0.830650771 , r: -0.378632635)
  private static let Data1992_818 = simd_quatd(ix: -0.378632635 , iy: 0.378632635 , iz: -0.152623567 , r: 0.830650771)
  private static let Data1992_819 = simd_quatd(ix: -0.378632635 , iy: 0.830650771 , iz: -0.152623567 , r: 0.378632635)
  private static let Data1992_820 = simd_quatd(ix: 0.378632635 , iy: -0.378632635 , iz: 0.830650771 , r: -0.152623567)
  private static let Data1992_821 = simd_quatd(ix: 0.717646237 , iy: -0.491637169 , iz: 0.491637169 , r: -0.039619033)
  private static let Data1992_822 = simd_quatd(ix: 0.717646237 , iy: -0.039619033 , iz: 0.491637169 , r: -0.491637169)
  private static let Data1992_823 = simd_quatd(ix: -0.152623567 , iy: 0.378632635 , iz: -0.378632635 , r: 0.830650771)
  private static let Data1992_824 = simd_quatd(ix: -0.152623567 , iy: 0.830650771 , iz: -0.378632635 , r: 0.378632635)
  private static let Data1992_825 = simd_quatd(ix: 0.491637169 , iy: -0.039619033 , iz: 0.717646237 , r: -0.491637169)
  private static let Data1992_826 = simd_quatd(ix: -0.491637169 , iy: 0.491637169 , iz: -0.039619033 , r: 0.717646237)
  private static let Data1992_827 = simd_quatd(ix: -0.491637169 , iy: 0.717646237 , iz: -0.039619033 , r: 0.491637169)
  private static let Data1992_828 = simd_quatd(ix: 0.491637169 , iy: -0.491637169 , iz: 0.717646237 , r: -0.039619033)
  private static let Data1992_829 = simd_quatd(ix: 0.830650771 , iy: -0.378632635 , iz: 0.378632635 , r: -0.152623567)
  private static let Data1992_830 = simd_quatd(ix: 0.830650771 , iy: -0.152623567 , iz: 0.378632635 , r: -0.378632635)
  private static let Data1992_831 = simd_quatd(ix: -0.500000000 , iy: -0.500000000 , iz: 0.500000000 , r: 0.500000000)
  private static let Data1992_832 = simd_quatd(ix: -0.551157340 , iy: -0.297786430 , iz: 0.551157340 , r: 0.551157340)
  private static let Data1992_833 = simd_quatd(ix: 0.677842795 , iy: 0.424471885 , iz: -0.424471885 , r: -0.424471885)
  private static let Data1992_834 = simd_quatd(ix: -0.424471885 , iy: -0.424471885 , iz: 0.677842795 , r: 0.424471885)
  private static let Data1992_835 = simd_quatd(ix: 0.551157340 , iy: 0.551157340 , iz: -0.551157340 , r: -0.297786430)
  private static let Data1992_836 = simd_quatd(ix: -0.424471885 , iy: -0.424471885 , iz: 0.424471885 , r: 0.677842795)
  private static let Data1992_837 = simd_quatd(ix: -0.551157340 , iy: -0.551157340 , iz: 0.297786430 , r: 0.551157340)
  private static let Data1992_838 = simd_quatd(ix: -0.297786430 , iy: -0.551157340 , iz: 0.551157340 , r: 0.551157340)
  private static let Data1992_839 = simd_quatd(ix: 0.424471885 , iy: 0.677842795 , iz: -0.424471885 , r: -0.424471885)
  private static let Data1992_840 = simd_quatd(ix: -0.358265662 , iy: -0.358265662 , iz: 0.609627522 , r: 0.609627522)
  private static let Data1992_841 = simd_quatd(ix: 0.609627522 , iy: 0.609627522 , iz: -0.358265662 , r: -0.358265662)
  private static let Data1992_842 = simd_quatd(ix: 0.609627522 , iy: 0.358265662 , iz: -0.609627522 , r: -0.358265662)
  private static let Data1992_843 = simd_quatd(ix: -0.609627522 , iy: -0.358265662 , iz: 0.358265662 , r: 0.609627522)
  private static let Data1992_844 = simd_quatd(ix: -0.358265662 , iy: -0.609627522 , iz: 0.358265662 , r: 0.609627522)
  private static let Data1992_845 = simd_quatd(ix: 0.358265662 , iy: 0.609627522 , iz: -0.609627522 , r: -0.358265662)
  private static let Data1992_846 = simd_quatd(ix: -0.469346375 , iy: -0.225567868 , iz: 0.469346375 , r: 0.713124882)
  private static let Data1992_847 = simd_quatd(ix: 0.713124882 , iy: 0.469346375 , iz: -0.225567868 , r: -0.469346375)
  private static let Data1992_848 = simd_quatd(ix: -0.225567868 , iy: -0.469346375 , iz: 0.713124882 , r: 0.469346375)
  private static let Data1992_849 = simd_quatd(ix: 0.469346375 , iy: 0.713124882 , iz: -0.469346375 , r: -0.225567868)
  private static let Data1992_850 = simd_quatd(ix: -0.469346375 , iy: -0.225567868 , iz: 0.713124882 , r: 0.469346375)
  private static let Data1992_851 = simd_quatd(ix: 0.713124882 , iy: 0.225567868 , iz: -0.469346375 , r: -0.469346375)
  private static let Data1992_852 = simd_quatd(ix: -0.225567868 , iy: -0.469346375 , iz: 0.469346375 , r: 0.713124882)
  private static let Data1992_853 = simd_quatd(ix: -0.469346375 , iy: -0.469346375 , iz: 0.713124882 , r: 0.225567868)
  private static let Data1992_854 = simd_quatd(ix: 0.713124882 , iy: 0.469346375 , iz: -0.469346375 , r: -0.225567868)
  private static let Data1992_855 = simd_quatd(ix: -0.469346375 , iy: -0.469346375 , iz: 0.225567868 , r: 0.713124882)
  private static let Data1992_856 = simd_quatd(ix: 0.469346375 , iy: 0.713124882 , iz: -0.225567868 , r: -0.469346375)
  private static let Data1992_857 = simd_quatd(ix: 0.225567868 , iy: 0.713124882 , iz: -0.469346375 , r: -0.469346375)
  private static let Data1992_858 = simd_quatd(ix: -0.574413822 , iy: -0.100728756 , iz: 0.574413822 , r: 0.574413822)
  private static let Data1992_859 = simd_quatd(ix: 0.811256356 , iy: 0.337571289 , iz: -0.337571289 , r: -0.337571289)
  private static let Data1992_860 = simd_quatd(ix: -0.337571289 , iy: -0.337571289 , iz: 0.811256356 , r: 0.337571289)
  private static let Data1992_861 = simd_quatd(ix: 0.574413822 , iy: 0.574413822 , iz: -0.574413822 , r: -0.100728756)
  private static let Data1992_862 = simd_quatd(ix: -0.337571289 , iy: -0.337571289 , iz: 0.337571289 , r: 0.811256356)
  private static let Data1992_863 = simd_quatd(ix: -0.574413822 , iy: -0.574413822 , iz: 0.100728756 , r: 0.574413822)
  private static let Data1992_864 = simd_quatd(ix: -0.100728756 , iy: -0.574413822 , iz: 0.574413822 , r: 0.574413822)
  private static let Data1992_865 = simd_quatd(ix: 0.337571289 , iy: 0.811256356 , iz: -0.337571289 , r: -0.337571289)
  private static let Data1992_866 = simd_quatd(ix: -0.399593685 , iy: -0.161072786 , iz: 0.638114584 , r: 0.638114584)
  private static let Data1992_867 = simd_quatd(ix: 0.757375033 , iy: 0.518854134 , iz: -0.280333236 , r: -0.280333236)
  private static let Data1992_868 = simd_quatd(ix: -0.280333236 , iy: -0.280333236 , iz: 0.757375033 , r: 0.518854134)
  private static let Data1992_869 = simd_quatd(ix: 0.638114584 , iy: 0.638114584 , iz: -0.399593685 , r: -0.161072786)
  private static let Data1992_870 = simd_quatd(ix: -0.280333236 , iy: -0.280333236 , iz: 0.518854134 , r: 0.757375033)
  private static let Data1992_871 = simd_quatd(ix: 0.638114584 , iy: 0.638114584 , iz: -0.161072786 , r: -0.399593685)
  private static let Data1992_872 = simd_quatd(ix: -0.161072786 , iy: -0.399593685 , iz: 0.638114584 , r: 0.638114584)
  private static let Data1992_873 = simd_quatd(ix: 0.518854134 , iy: 0.757375033 , iz: -0.280333236 , r: -0.280333236)
  private static let Data1992_874 = simd_quatd(ix: 0.638114584 , iy: 0.161072786 , iz: -0.638114584 , r: -0.399593685)
  private static let Data1992_875 = simd_quatd(ix: -0.638114584 , iy: -0.161072786 , iz: 0.399593685 , r: 0.638114584)
  private static let Data1992_876 = simd_quatd(ix: -0.280333236 , iy: -0.518854134 , iz: 0.280333236 , r: 0.757375033)
  private static let Data1992_877 = simd_quatd(ix: -0.280333236 , iy: -0.518854134 , iz: 0.757375033 , r: 0.280333236)
  private static let Data1992_878 = simd_quatd(ix: 0.757375033 , iy: 0.280333236 , iz: -0.518854134 , r: -0.280333236)
  private static let Data1992_879 = simd_quatd(ix: -0.518854134 , iy: -0.280333236 , iz: 0.280333236 , r: 0.757375033)
  private static let Data1992_880 = simd_quatd(ix: -0.399593685 , iy: -0.638114584 , iz: 0.161072786 , r: 0.638114584)
  private static let Data1992_881 = simd_quatd(ix: 0.161072786 , iy: 0.638114584 , iz: -0.638114584 , r: -0.399593685)
  private static let Data1992_882 = simd_quatd(ix: -0.518854134 , iy: -0.280333236 , iz: 0.757375033 , r: 0.280333236)
  private static let Data1992_883 = simd_quatd(ix: 0.757375033 , iy: 0.280333236 , iz: -0.280333236 , r: -0.518854134)
  private static let Data1992_884 = simd_quatd(ix: -0.161072786 , iy: -0.638114584 , iz: 0.399593685 , r: 0.638114584)
  private static let Data1992_885 = simd_quatd(ix: 0.399593685 , iy: 0.638114584 , iz: -0.638114584 , r: -0.161072786)
  private static let Data1992_886 = simd_quatd(ix: 0.638114584 , iy: 0.399593685 , iz: -0.638114584 , r: -0.161072786)
  private static let Data1992_887 = simd_quatd(ix: -0.638114584 , iy: -0.399593685 , iz: 0.161072786 , r: 0.638114584)
  private static let Data1992_888 = simd_quatd(ix: 0.280333236 , iy: 0.757375033 , iz: -0.280333236 , r: -0.518854134)
  private static let Data1992_889 = simd_quatd(ix: 0.280333236 , iy: 0.757375033 , iz: -0.518854134 , r: -0.280333236)
  private static let Data1992_890 = simd_quatd(ix: -0.491637169 , iy: -0.039619033 , iz: 0.491637169 , r: 0.717646237)
  private static let Data1992_891 = simd_quatd(ix: 0.830650771 , iy: 0.378632635 , iz: -0.152623567 , r: -0.378632635)
  private static let Data1992_892 = simd_quatd(ix: -0.152623567 , iy: -0.378632635 , iz: 0.830650771 , r: 0.378632635)
  private static let Data1992_893 = simd_quatd(ix: 0.491637169 , iy: 0.717646237 , iz: -0.491637169 , r: -0.039619033)
  private static let Data1992_894 = simd_quatd(ix: -0.378632635 , iy: -0.152623567 , iz: 0.378632635 , r: 0.830650771)
  private static let Data1992_895 = simd_quatd(ix: 0.717646237 , iy: 0.491637169 , iz: -0.039619033 , r: -0.491637169)
  private static let Data1992_896 = simd_quatd(ix: -0.039619033 , iy: -0.491637169 , iz: 0.717646237 , r: 0.491637169)
  private static let Data1992_897 = simd_quatd(ix: 0.378632635 , iy: 0.830650771 , iz: -0.378632635 , r: -0.152623567)
  private static let Data1992_898 = simd_quatd(ix: -0.491637169 , iy: -0.039619033 , iz: 0.717646237 , r: 0.491637169)
  private static let Data1992_899 = simd_quatd(ix: 0.717646237 , iy: 0.039619033 , iz: -0.491637169 , r: -0.491637169)
  private static let Data1992_900 = simd_quatd(ix: -0.152623567 , iy: -0.378632635 , iz: 0.378632635 , r: 0.830650771)
  private static let Data1992_901 = simd_quatd(ix: -0.378632635 , iy: -0.378632635 , iz: 0.830650771 , r: 0.152623567)
  private static let Data1992_902 = simd_quatd(ix: 0.830650771 , iy: 0.378632635 , iz: -0.378632635 , r: -0.152623567)
  private static let Data1992_903 = simd_quatd(ix: -0.378632635 , iy: -0.378632635 , iz: 0.152623567 , r: 0.830650771)
  private static let Data1992_904 = simd_quatd(ix: 0.491637169 , iy: 0.717646237 , iz: -0.039619033 , r: -0.491637169)
  private static let Data1992_905 = simd_quatd(ix: 0.039619033 , iy: 0.717646237 , iz: -0.491637169 , r: -0.491637169)
  private static let Data1992_906 = simd_quatd(ix: -0.378632635 , iy: -0.152623567 , iz: 0.830650771 , r: 0.378632635)
  private static let Data1992_907 = simd_quatd(ix: 0.830650771 , iy: 0.152623567 , iz: -0.378632635 , r: -0.378632635)
  private static let Data1992_908 = simd_quatd(ix: -0.039619033 , iy: -0.491637169 , iz: 0.491637169 , r: 0.717646237)
  private static let Data1992_909 = simd_quatd(ix: -0.491637169 , iy: -0.491637169 , iz: 0.717646237 , r: 0.039619033)
  private static let Data1992_910 = simd_quatd(ix: 0.717646237 , iy: 0.491637169 , iz: -0.491637169 , r: -0.039619033)
  private static let Data1992_911 = simd_quatd(ix: -0.491637169 , iy: -0.491637169 , iz: 0.039619033 , r: 0.717646237)
  private static let Data1992_912 = simd_quatd(ix: 0.378632635 , iy: 0.830650771 , iz: -0.152623567 , r: -0.378632635)
  private static let Data1992_913 = simd_quatd(ix: 0.152623567 , iy: 0.830650771 , iz: -0.378632635 , r: -0.378632635)
  private static let Data1992_914 = simd_quatd(ix: -0.500000000 , iy: -0.500000000 , iz: -0.500000000 , r: 0.500000000)
  private static let Data1992_915 = simd_quatd(ix: -0.424471885 , iy: -0.424471885 , iz: -0.424471885 , r: 0.677842795)
  private static let Data1992_916 = simd_quatd(ix: -0.551157340 , iy: -0.297786430 , iz: -0.551157340 , r: 0.551157340)
  private static let Data1992_917 = simd_quatd(ix: -0.551157340 , iy: -0.551157340 , iz: -0.297786430 , r: 0.551157340)
  private static let Data1992_918 = simd_quatd(ix: 0.677842795 , iy: 0.424471885 , iz: 0.424471885 , r: -0.424471885)
  private static let Data1992_919 = simd_quatd(ix: -0.297786430 , iy: -0.551157340 , iz: -0.551157340 , r: 0.551157340)
  private static let Data1992_920 = simd_quatd(ix: 0.424471885 , iy: 0.424471885 , iz: 0.677842795 , r: -0.424471885)
  private static let Data1992_921 = simd_quatd(ix: 0.424471885 , iy: 0.677842795 , iz: 0.424471885 , r: -0.424471885)
  private static let Data1992_922 = simd_quatd(ix: 0.551157340 , iy: 0.551157340 , iz: 0.551157340 , r: -0.297786430)
  private static let Data1992_923 = simd_quatd(ix: -0.358265662 , iy: -0.609627522 , iz: -0.358265662 , r: 0.609627522)
  private static let Data1992_924 = simd_quatd(ix: 0.609627522 , iy: 0.358265662 , iz: 0.609627522 , r: -0.358265662)
  private static let Data1992_925 = simd_quatd(ix: -0.609627522 , iy: -0.358265662 , iz: -0.358265662 , r: 0.609627522)
  private static let Data1992_926 = simd_quatd(ix: -0.358265662 , iy: -0.358265662 , iz: -0.609627522 , r: 0.609627522)
  private static let Data1992_927 = simd_quatd(ix: 0.358265662 , iy: 0.609627522 , iz: 0.609627522 , r: -0.358265662)
  private static let Data1992_928 = simd_quatd(ix: 0.609627522 , iy: 0.609627522 , iz: 0.358265662 , r: -0.358265662)
  private static let Data1992_929 = simd_quatd(ix: -0.225567868 , iy: -0.469346375 , iz: -0.469346375 , r: 0.713124882)
  private static let Data1992_930 = simd_quatd(ix: 0.469346375 , iy: 0.225567868 , iz: 0.713124882 , r: -0.469346375)
  private static let Data1992_931 = simd_quatd(ix: 0.469346375 , iy: 0.713124882 , iz: 0.225567868 , r: -0.469346375)
  private static let Data1992_932 = simd_quatd(ix: 0.713124882 , iy: 0.469346375 , iz: 0.469346375 , r: -0.225567868)
  private static let Data1992_933 = simd_quatd(ix: -0.469346375 , iy: -0.469346375 , iz: -0.225567868 , r: 0.713124882)
  private static let Data1992_934 = simd_quatd(ix: -0.469346375 , iy: -0.225567868 , iz: -0.469346375 , r: 0.713124882)
  private static let Data1992_935 = simd_quatd(ix: 0.225567868 , iy: 0.713124882 , iz: 0.469346375 , r: -0.469346375)
  private static let Data1992_936 = simd_quatd(ix: 0.713124882 , iy: 0.469346375 , iz: 0.225567868 , r: -0.469346375)
  private static let Data1992_937 = simd_quatd(ix: 0.713124882 , iy: 0.225567868 , iz: 0.469346375 , r: -0.469346375)
  private static let Data1992_938 = simd_quatd(ix: 0.225567868 , iy: 0.469346375 , iz: 0.713124882 , r: -0.469346375)
  private static let Data1992_939 = simd_quatd(ix: 0.469346375 , iy: 0.469346375 , iz: 0.713124882 , r: -0.225567868)
  private static let Data1992_940 = simd_quatd(ix: 0.469346375 , iy: 0.713124882 , iz: 0.469346375 , r: -0.225567868)
  private static let Data1992_941 = simd_quatd(ix: -0.337571289 , iy: -0.337571289 , iz: -0.337571289 , r: 0.811256356)
  private static let Data1992_942 = simd_quatd(ix: -0.574413822 , iy: -0.100728756 , iz: -0.574413822 , r: 0.574413822)
  private static let Data1992_943 = simd_quatd(ix: -0.574413822 , iy: -0.574413822 , iz: -0.100728756 , r: 0.574413822)
  private static let Data1992_944 = simd_quatd(ix: 0.811256356 , iy: 0.337571289 , iz: 0.337571289 , r: -0.337571289)
  private static let Data1992_945 = simd_quatd(ix: -0.100728756 , iy: -0.574413822 , iz: -0.574413822 , r: 0.574413822)
  private static let Data1992_946 = simd_quatd(ix: 0.337571289 , iy: 0.337571289 , iz: 0.811256356 , r: -0.337571289)
  private static let Data1992_947 = simd_quatd(ix: 0.337571289 , iy: 0.811256356 , iz: 0.337571289 , r: -0.337571289)
  private static let Data1992_948 = simd_quatd(ix: 0.574413822 , iy: 0.574413822 , iz: 0.574413822 , r: -0.100728756)
  private static let Data1992_949 = simd_quatd(ix: -0.280333236 , iy: -0.518854134 , iz: -0.280333236 , r: 0.757375033)
  private static let Data1992_950 = simd_quatd(ix: 0.638114584 , iy: 0.161072786 , iz: 0.638114584 , r: -0.399593685)
  private static let Data1992_951 = simd_quatd(ix: -0.399593685 , iy: -0.638114584 , iz: -0.161072786 , r: 0.638114584)
  private static let Data1992_952 = simd_quatd(ix: 0.757375033 , iy: 0.280333236 , iz: 0.518854134 , r: -0.280333236)
  private static let Data1992_953 = simd_quatd(ix: -0.161072786 , iy: -0.638114584 , iz: -0.399593685 , r: 0.638114584)
  private static let Data1992_954 = simd_quatd(ix: 0.518854134 , iy: 0.280333236 , iz: 0.757375033 , r: -0.280333236)
  private static let Data1992_955 = simd_quatd(ix: 0.280333236 , iy: 0.757375033 , iz: 0.280333236 , r: -0.518854134)
  private static let Data1992_956 = simd_quatd(ix: 0.638114584 , iy: 0.399593685 , iz: 0.638114584 , r: -0.161072786)
  private static let Data1992_957 = simd_quatd(ix: -0.518854134 , iy: -0.280333236 , iz: -0.280333236 , r: 0.757375033)
  private static let Data1992_958 = simd_quatd(ix: -0.280333236 , iy: -0.280333236 , iz: -0.518854134 , r: 0.757375033)
  private static let Data1992_959 = simd_quatd(ix: 0.161072786 , iy: 0.638114584 , iz: 0.638114584 , r: -0.399593685)
  private static let Data1992_960 = simd_quatd(ix: 0.638114584 , iy: 0.638114584 , iz: 0.161072786 , r: -0.399593685)
  private static let Data1992_961 = simd_quatd(ix: -0.638114584 , iy: -0.161072786 , iz: -0.399593685 , r: 0.638114584)
  private static let Data1992_962 = simd_quatd(ix: -0.161072786 , iy: -0.399593685 , iz: -0.638114584 , r: 0.638114584)
  private static let Data1992_963 = simd_quatd(ix: 0.280333236 , iy: 0.518854134 , iz: 0.757375033 , r: -0.280333236)
  private static let Data1992_964 = simd_quatd(ix: 0.518854134 , iy: 0.757375033 , iz: 0.280333236 , r: -0.280333236)
  private static let Data1992_965 = simd_quatd(ix: -0.638114584 , iy: -0.399593685 , iz: -0.161072786 , r: 0.638114584)
  private static let Data1992_966 = simd_quatd(ix: -0.399593685 , iy: -0.161072786 , iz: -0.638114584 , r: 0.638114584)
  private static let Data1992_967 = simd_quatd(ix: 0.280333236 , iy: 0.757375033 , iz: 0.518854134 , r: -0.280333236)
  private static let Data1992_968 = simd_quatd(ix: 0.757375033 , iy: 0.518854134 , iz: 0.280333236 , r: -0.280333236)
  private static let Data1992_969 = simd_quatd(ix: 0.757375033 , iy: 0.280333236 , iz: 0.280333236 , r: -0.518854134)
  private static let Data1992_970 = simd_quatd(ix: 0.280333236 , iy: 0.280333236 , iz: 0.757375033 , r: -0.518854134)
  private static let Data1992_971 = simd_quatd(ix: 0.399593685 , iy: 0.638114584 , iz: 0.638114584 , r: -0.161072786)
  private static let Data1992_972 = simd_quatd(ix: 0.638114584 , iy: 0.638114584 , iz: 0.399593685 , r: -0.161072786)
  private static let Data1992_973 = simd_quatd(ix: -0.152623567 , iy: -0.378632635 , iz: -0.378632635 , r: 0.830650771)
  private static let Data1992_974 = simd_quatd(ix: 0.491637169 , iy: 0.039619033 , iz: 0.717646237 , r: -0.491637169)
  private static let Data1992_975 = simd_quatd(ix: 0.491637169 , iy: 0.717646237 , iz: 0.039619033 , r: -0.491637169)
  private static let Data1992_976 = simd_quatd(ix: 0.830650771 , iy: 0.378632635 , iz: 0.378632635 , r: -0.152623567)
  private static let Data1992_977 = simd_quatd(ix: -0.039619033 , iy: -0.491637169 , iz: -0.491637169 , r: 0.717646237)
  private static let Data1992_978 = simd_quatd(ix: 0.378632635 , iy: 0.152623567 , iz: 0.830650771 , r: -0.378632635)
  private static let Data1992_979 = simd_quatd(ix: 0.378632635 , iy: 0.830650771 , iz: 0.152623567 , r: -0.378632635)
  private static let Data1992_980 = simd_quatd(ix: 0.717646237 , iy: 0.491637169 , iz: 0.491637169 , r: -0.039619033)
  private static let Data1992_981 = simd_quatd(ix: -0.378632635 , iy: -0.378632635 , iz: -0.152623567 , r: 0.830650771)
  private static let Data1992_982 = simd_quatd(ix: -0.378632635 , iy: -0.152623567 , iz: -0.378632635 , r: 0.830650771)
  private static let Data1992_983 = simd_quatd(ix: 0.039619033 , iy: 0.717646237 , iz: 0.491637169 , r: -0.491637169)
  private static let Data1992_984 = simd_quatd(ix: 0.717646237 , iy: 0.491637169 , iz: 0.039619033 , r: -0.491637169)
  private static let Data1992_985 = simd_quatd(ix: 0.717646237 , iy: 0.039619033 , iz: 0.491637169 , r: -0.491637169)
  private static let Data1992_986 = simd_quatd(ix: 0.039619033 , iy: 0.491637169 , iz: 0.717646237 , r: -0.491637169)
  private static let Data1992_987 = simd_quatd(ix: 0.378632635 , iy: 0.378632635 , iz: 0.830650771 , r: -0.152623567)
  private static let Data1992_988 = simd_quatd(ix: 0.378632635 , iy: 0.830650771 , iz: 0.378632635 , r: -0.152623567)
  private static let Data1992_989 = simd_quatd(ix: -0.491637169 , iy: -0.491637169 , iz: -0.039619033 , r: 0.717646237)
  private static let Data1992_990 = simd_quatd(ix: -0.491637169 , iy: -0.039619033 , iz: -0.491637169 , r: 0.717646237)
  private static let Data1992_991 = simd_quatd(ix: 0.152623567 , iy: 0.830650771 , iz: 0.378632635 , r: -0.378632635)
  private static let Data1992_992 = simd_quatd(ix: 0.830650771 , iy: 0.378632635 , iz: 0.152623567 , r: -0.378632635)
  private static let Data1992_993 = simd_quatd(ix: 0.830650771 , iy: 0.152623567 , iz: 0.378632635 , r: -0.378632635)
  private static let Data1992_994 = simd_quatd(ix: 0.152623567 , iy: 0.378632635 , iz: 0.830650771 , r: -0.378632635)
  private static let Data1992_995 = simd_quatd(ix: 0.491637169 , iy: 0.491637169 , iz: 0.717646237 , r: -0.039619033)
  private static let Data1992_996 = simd_quatd(ix: 0.491637169 , iy: 0.717646237 , iz: 0.491637169 , r: -0.039619033)
  private static let Data1992_997 = simd_quatd(ix: 0.707106781 , iy: 0.000000000 , iz: 0.000000000 , r: 0.707106781)
  private static let Data1992_998 = simd_quatd(ix: 0.779454186 , iy: 0.000000000 , iz: 0.179160289 , r: 0.600293897)
  private static let Data1992_999 = simd_quatd(ix: 0.600293897 , iy: 0.000000000 , iz: 0.179160289 , r: 0.779454186)
  private static let Data1992_1000 = simd_quatd(ix: 0.779454186 , iy: -0.179160289 , iz: 0.000000000 , r: 0.600293897)
  private static let Data1992_1001 = simd_quatd(ix: 0.600293897 , iy: -0.179160289 , iz: 0.000000000 , r: 0.779454186)
  private static let Data1992_1002 = simd_quatd(ix: 0.779454186 , iy: 0.179160289 , iz: 0.000000000 , r: 0.600293897)
  private static let Data1992_1003 = simd_quatd(ix: 0.600293897 , iy: 0.179160289 , iz: 0.000000000 , r: 0.779454186)
  private static let Data1992_1004 = simd_quatd(ix: 0.779454186 , iy: 0.000000000 , iz: -0.179160289 , r: 0.600293897)
  private static let Data1992_1005 = simd_quatd(ix: 0.600293897 , iy: 0.000000000 , iz: -0.179160289 , r: 0.779454186)
  private static let Data1992_1006 = simd_quatd(ix: 0.862143509 , iy: 0.000000000 , iz: 0.000000000 , r: 0.506664158)
  private static let Data1992_1007 = simd_quatd(ix: 0.506664158 , iy: 0.000000000 , iz: 0.000000000 , r: 0.862143509)
  private static let Data1992_1008 = simd_quatd(ix: 0.684403834 , iy: -0.177739676 , iz: 0.177739676 , r: 0.684403834)
  private static let Data1992_1009 = simd_quatd(ix: 0.684403834 , iy: 0.177739676 , iz: 0.177739676 , r: 0.684403834)
  private static let Data1992_1010 = simd_quatd(ix: 0.684403834 , iy: 0.177739676 , iz: -0.177739676 , r: 0.684403834)
  private static let Data1992_1011 = simd_quatd(ix: 0.684403834 , iy: -0.177739676 , iz: -0.177739676 , r: 0.684403834)
  private static let Data1992_1012 = simd_quatd(ix: 0.836133444 , iy: 0.172377436 , iz: 0.172377436 , r: 0.491378573)
  private static let Data1992_1013 = simd_quatd(ix: 0.491378573 , iy: 0.172377436 , iz: 0.172377436 , r: 0.836133444)
  private static let Data1992_1014 = simd_quatd(ix: 0.836133444 , iy: -0.172377436 , iz: -0.172377436 , r: 0.491378573)
  private static let Data1992_1015 = simd_quatd(ix: 0.491378573 , iy: -0.172377436 , iz: -0.172377436 , r: 0.836133444)
  private static let Data1992_1016 = simd_quatd(ix: 0.836133444 , iy: -0.172377436 , iz: 0.172377436 , r: 0.491378573)
  private static let Data1992_1017 = simd_quatd(ix: 0.663756009 , iy: 0.000000000 , iz: 0.344754871 , r: 0.663756009)
  private static let Data1992_1018 = simd_quatd(ix: 0.836133444 , iy: 0.172377436 , iz: -0.172377436 , r: 0.491378573)
  private static let Data1992_1019 = simd_quatd(ix: 0.663756009 , iy: -0.344754871 , iz: 0.000000000 , r: 0.663756009)
  private static let Data1992_1020 = simd_quatd(ix: 0.491378573 , iy: -0.172377436 , iz: 0.172377436 , r: 0.836133444)
  private static let Data1992_1021 = simd_quatd(ix: 0.663756009 , iy: 0.344754871 , iz: 0.000000000 , r: 0.663756009)
  private static let Data1992_1022 = simd_quatd(ix: 0.491378573 , iy: 0.172377436 , iz: -0.172377436 , r: 0.836133444)
  private static let Data1992_1023 = simd_quatd(ix: 0.663756009 , iy: 0.000000000 , iz: -0.344754871 , r: 0.663756009)
  private static let Data1992_1024 = simd_quatd(ix: 0.812343818 , iy: 0.000000000 , iz: 0.334945923 , r: 0.477397895)
  private static let Data1992_1025 = simd_quatd(ix: 0.477397895 , iy: 0.000000000 , iz: 0.334945923 , r: 0.812343818)
  private static let Data1992_1026 = simd_quatd(ix: 0.812343818 , iy: -0.334945923 , iz: 0.000000000 , r: 0.477397895)
  private static let Data1992_1027 = simd_quatd(ix: 0.477397895 , iy: -0.334945923 , iz: 0.000000000 , r: 0.812343818)
  private static let Data1992_1028 = simd_quatd(ix: 0.812343818 , iy: 0.334945923 , iz: 0.000000000 , r: 0.477397895)
  private static let Data1992_1029 = simd_quatd(ix: 0.477397895 , iy: 0.334945923 , iz: 0.000000000 , r: 0.812343818)
  private static let Data1992_1030 = simd_quatd(ix: 0.812343818 , iy: 0.000000000 , iz: -0.334945923 , r: 0.477397895)
  private static let Data1992_1031 = simd_quatd(ix: 0.477397895 , iy: 0.000000000 , iz: -0.334945923 , r: 0.812343818)
  private static let Data1992_1032 = simd_quatd(ix: 0.902430299 , iy: 0.000000000 , iz: 0.168659745 , r: 0.396451064)
  private static let Data1992_1033 = simd_quatd(ix: 0.396451064 , iy: 0.000000000 , iz: 0.168659745 , r: 0.902430299)
  private static let Data1992_1034 = simd_quatd(ix: 0.902430299 , iy: -0.168659745 , iz: 0.000000000 , r: 0.396451064)
  private static let Data1992_1035 = simd_quatd(ix: 0.396451064 , iy: -0.168659745 , iz: 0.000000000 , r: 0.902430299)
  private static let Data1992_1036 = simd_quatd(ix: 0.902430299 , iy: 0.168659745 , iz: 0.000000000 , r: 0.396451064)
  private static let Data1992_1037 = simd_quatd(ix: 0.396451064 , iy: 0.168659745 , iz: 0.000000000 , r: 0.902430299)
  private static let Data1992_1038 = simd_quatd(ix: 0.902430299 , iy: 0.000000000 , iz: -0.168659745 , r: 0.396451064)
  private static let Data1992_1039 = simd_quatd(ix: 0.396451064 , iy: 0.000000000 , iz: -0.168659745 , r: 0.902430299)
  private static let Data1992_1040 = simd_quatd(ix: 0.733770554 , iy: -0.168659745 , iz: 0.337319490 , r: 0.565110809)
  private static let Data1992_1041 = simd_quatd(ix: 0.733770554 , iy: 0.168659745 , iz: 0.337319490 , r: 0.565110809)
  private static let Data1992_1042 = simd_quatd(ix: 0.733770554 , iy: 0.337319490 , iz: -0.168659745 , r: 0.565110809)
  private static let Data1992_1043 = simd_quatd(ix: 0.733770554 , iy: -0.337319490 , iz: -0.168659745 , r: 0.565110809)
  private static let Data1992_1044 = simd_quatd(ix: 0.565110809 , iy: -0.168659745 , iz: 0.337319490 , r: 0.733770554)
  private static let Data1992_1045 = simd_quatd(ix: 0.733770554 , iy: 0.337319490 , iz: 0.168659745 , r: 0.565110809)
  private static let Data1992_1046 = simd_quatd(ix: 0.565110809 , iy: 0.337319490 , iz: -0.168659745 , r: 0.733770554)
  private static let Data1992_1047 = simd_quatd(ix: 0.733770554 , iy: -0.168659745 , iz: -0.337319490 , r: 0.565110809)
  private static let Data1992_1048 = simd_quatd(ix: 0.733770554 , iy: -0.337319490 , iz: 0.168659745 , r: 0.565110809)
  private static let Data1992_1049 = simd_quatd(ix: 0.565110809 , iy: 0.168659745 , iz: 0.337319490 , r: 0.733770554)
  private static let Data1992_1050 = simd_quatd(ix: 0.733770554 , iy: 0.168659745 , iz: -0.337319490 , r: 0.565110809)
  private static let Data1992_1051 = simd_quatd(ix: 0.565110809 , iy: -0.337319490 , iz: -0.168659745 , r: 0.733770554)
  private static let Data1992_1052 = simd_quatd(ix: 0.565110809 , iy: -0.337319490 , iz: 0.168659745 , r: 0.733770554)
  private static let Data1992_1053 = simd_quatd(ix: 0.565110809 , iy: 0.337319490 , iz: 0.168659745 , r: 0.733770554)
  private static let Data1992_1054 = simd_quatd(ix: 0.565110809 , iy: 0.168659745 , iz: -0.337319490 , r: 0.733770554)
  private static let Data1992_1055 = simd_quatd(ix: 0.565110809 , iy: -0.168659745 , iz: -0.337319490 , r: 0.733770554)
  private static let Data1992_1056 = simd_quatd(ix: 0.855092496 , iy: 0.159812545 , iz: 0.319625089 , r: 0.375654863)
  private static let Data1992_1057 = simd_quatd(ix: 0.375654863 , iy: 0.159812545 , iz: 0.319625089 , r: 0.855092496)
  private static let Data1992_1058 = simd_quatd(ix: 0.855092496 , iy: -0.319625089 , iz: -0.159812545 , r: 0.375654863)
  private static let Data1992_1059 = simd_quatd(ix: 0.375654863 , iy: -0.319625089 , iz: -0.159812545 , r: 0.855092496)
  private static let Data1992_1060 = simd_quatd(ix: 0.855092496 , iy: 0.319625089 , iz: 0.159812545 , r: 0.375654863)
  private static let Data1992_1061 = simd_quatd(ix: 0.375654863 , iy: 0.319625089 , iz: 0.159812545 , r: 0.855092496)
  private static let Data1992_1062 = simd_quatd(ix: 0.855092496 , iy: -0.159812545 , iz: -0.319625089 , r: 0.375654863)
  private static let Data1992_1063 = simd_quatd(ix: 0.375654863 , iy: -0.159812545 , iz: -0.319625089 , r: 0.855092496)
  private static let Data1992_1064 = simd_quatd(ix: 0.855092496 , iy: -0.159812545 , iz: 0.319625089 , r: 0.375654863)
  private static let Data1992_1065 = simd_quatd(ix: 0.695279952 , iy: 0.000000000 , iz: 0.479437634 , r: 0.535467407)
  private static let Data1992_1066 = simd_quatd(ix: 0.855092496 , iy: 0.319625089 , iz: -0.159812545 , r: 0.375654863)
  private static let Data1992_1067 = simd_quatd(ix: 0.695279952 , iy: -0.479437634 , iz: 0.000000000 , r: 0.535467407)
  private static let Data1992_1068 = simd_quatd(ix: 0.375654863 , iy: -0.159812545 , iz: 0.319625089 , r: 0.855092496)
  private static let Data1992_1069 = simd_quatd(ix: 0.695279952 , iy: 0.479437634 , iz: 0.000000000 , r: 0.535467407)
  private static let Data1992_1070 = simd_quatd(ix: 0.375654863 , iy: 0.319625089 , iz: -0.159812545 , r: 0.855092496)
  private static let Data1992_1071 = simd_quatd(ix: 0.695279952 , iy: 0.000000000 , iz: -0.479437634 , r: 0.535467407)
  private static let Data1992_1072 = simd_quatd(ix: 0.855092496 , iy: -0.319625089 , iz: 0.159812545 , r: 0.375654863)
  private static let Data1992_1073 = simd_quatd(ix: 0.535467407 , iy: 0.000000000 , iz: 0.479437634 , r: 0.695279952)
  private static let Data1992_1074 = simd_quatd(ix: 0.855092496 , iy: 0.159812545 , iz: -0.319625089 , r: 0.375654863)
  private static let Data1992_1075 = simd_quatd(ix: 0.535467407 , iy: -0.479437634 , iz: 0.000000000 , r: 0.695279952)
  private static let Data1992_1076 = simd_quatd(ix: 0.375654863 , iy: -0.319625089 , iz: 0.159812545 , r: 0.855092496)
  private static let Data1992_1077 = simd_quatd(ix: 0.535467407 , iy: 0.479437634 , iz: 0.000000000 , r: 0.695279952)
  private static let Data1992_1078 = simd_quatd(ix: 0.375654863 , iy: 0.159812545 , iz: -0.319625089 , r: 0.855092496)
  private static let Data1992_1079 = simd_quatd(ix: 0.535467407 , iy: 0.000000000 , iz: -0.479437634 , r: 0.695279952)
  private static let Data1992_1080 = simd_quatd(ix: -0.707106781 , iy: 0.000000000 , iz: 0.000000000 , r: 0.707106781)
  private static let Data1992_1081 = simd_quatd(ix: -0.600293897 , iy: 0.179160289 , iz: 0.000000000 , r: 0.779454186)
  private static let Data1992_1082 = simd_quatd(ix: 0.779454186 , iy: -0.179160289 , iz: -0.000000000 , r: -0.600293897)
  private static let Data1992_1083 = simd_quatd(ix: -0.600293897 , iy: 0.000000000 , iz: 0.179160289 , r: 0.779454186)
  private static let Data1992_1084 = simd_quatd(ix: 0.779454186 , iy: -0.000000000 , iz: -0.179160289 , r: -0.600293897)
  private static let Data1992_1085 = simd_quatd(ix: -0.600293897 , iy: 0.000000000 , iz: -0.179160289 , r: 0.779454186)
  private static let Data1992_1086 = simd_quatd(ix: 0.779454186 , iy: -0.000000000 , iz: 0.179160289 , r: -0.600293897)
  private static let Data1992_1087 = simd_quatd(ix: -0.600293897 , iy: -0.179160289 , iz: 0.000000000 , r: 0.779454186)
  private static let Data1992_1088 = simd_quatd(ix: 0.779454186 , iy: 0.179160289 , iz: -0.000000000 , r: -0.600293897)
  private static let Data1992_1089 = simd_quatd(ix: -0.506664158 , iy: 0.000000000 , iz: 0.000000000 , r: 0.862143509)
  private static let Data1992_1090 = simd_quatd(ix: 0.862143509 , iy: -0.000000000 , iz: -0.000000000 , r: -0.506664158)
  private static let Data1992_1091 = simd_quatd(ix: -0.684403834 , iy: 0.177739676 , iz: 0.177739676 , r: 0.684403834)
  private static let Data1992_1092 = simd_quatd(ix: -0.684403834 , iy: 0.177739676 , iz: -0.177739676 , r: 0.684403834)
  private static let Data1992_1093 = simd_quatd(ix: -0.684403834 , iy: -0.177739676 , iz: -0.177739676 , r: 0.684403834)
  private static let Data1992_1094 = simd_quatd(ix: -0.684403834 , iy: -0.177739676 , iz: 0.177739676 , r: 0.684403834)
  private static let Data1992_1095 = simd_quatd(ix: -0.491378573 , iy: 0.172377436 , iz: -0.172377436 , r: 0.836133444)
  private static let Data1992_1096 = simd_quatd(ix: 0.836133444 , iy: -0.172377436 , iz: 0.172377436 , r: -0.491378573)
  private static let Data1992_1097 = simd_quatd(ix: -0.491378573 , iy: -0.172377436 , iz: 0.172377436 , r: 0.836133444)
  private static let Data1992_1098 = simd_quatd(ix: 0.836133444 , iy: 0.172377436 , iz: -0.172377436 , r: -0.491378573)
  private static let Data1992_1099 = simd_quatd(ix: -0.491378573 , iy: 0.172377436 , iz: 0.172377436 , r: 0.836133444)
  private static let Data1992_1100 = simd_quatd(ix: -0.663756009 , iy: 0.344754871 , iz: 0.000000000 , r: 0.663756009)
  private static let Data1992_1101 = simd_quatd(ix: -0.491378573 , iy: -0.172377436 , iz: -0.172377436 , r: 0.836133444)
  private static let Data1992_1102 = simd_quatd(ix: -0.663756009 , iy: 0.000000000 , iz: 0.344754871 , r: 0.663756009)
  private static let Data1992_1103 = simd_quatd(ix: 0.836133444 , iy: -0.172377436 , iz: -0.172377436 , r: -0.491378573)
  private static let Data1992_1104 = simd_quatd(ix: -0.663756009 , iy: 0.000000000 , iz: -0.344754871 , r: 0.663756009)
  private static let Data1992_1105 = simd_quatd(ix: 0.836133444 , iy: 0.172377436 , iz: 0.172377436 , r: -0.491378573)
  private static let Data1992_1106 = simd_quatd(ix: -0.663756009 , iy: -0.344754871 , iz: 0.000000000 , r: 0.663756009)
  private static let Data1992_1107 = simd_quatd(ix: -0.477397895 , iy: 0.334945923 , iz: 0.000000000 , r: 0.812343818)
  private static let Data1992_1108 = simd_quatd(ix: 0.812343818 , iy: -0.334945923 , iz: -0.000000000 , r: -0.477397895)
  private static let Data1992_1109 = simd_quatd(ix: -0.477397895 , iy: 0.000000000 , iz: 0.334945923 , r: 0.812343818)
  private static let Data1992_1110 = simd_quatd(ix: 0.812343818 , iy: -0.000000000 , iz: -0.334945923 , r: -0.477397895)
  private static let Data1992_1111 = simd_quatd(ix: -0.477397895 , iy: 0.000000000 , iz: -0.334945923 , r: 0.812343818)
  private static let Data1992_1112 = simd_quatd(ix: 0.812343818 , iy: -0.000000000 , iz: 0.334945923 , r: -0.477397895)
  private static let Data1992_1113 = simd_quatd(ix: -0.477397895 , iy: -0.334945923 , iz: 0.000000000 , r: 0.812343818)
  private static let Data1992_1114 = simd_quatd(ix: 0.812343818 , iy: 0.334945923 , iz: -0.000000000 , r: -0.477397895)
  private static let Data1992_1115 = simd_quatd(ix: -0.396451064 , iy: 0.168659745 , iz: 0.000000000 , r: 0.902430299)
  private static let Data1992_1116 = simd_quatd(ix: 0.902430299 , iy: -0.168659745 , iz: -0.000000000 , r: -0.396451064)
  private static let Data1992_1117 = simd_quatd(ix: -0.396451064 , iy: 0.000000000 , iz: 0.168659745 , r: 0.902430299)
  private static let Data1992_1118 = simd_quatd(ix: 0.902430299 , iy: -0.000000000 , iz: -0.168659745 , r: -0.396451064)
  private static let Data1992_1119 = simd_quatd(ix: -0.396451064 , iy: 0.000000000 , iz: -0.168659745 , r: 0.902430299)
  private static let Data1992_1120 = simd_quatd(ix: 0.902430299 , iy: -0.000000000 , iz: 0.168659745 , r: -0.396451064)
  private static let Data1992_1121 = simd_quatd(ix: -0.396451064 , iy: -0.168659745 , iz: 0.000000000 , r: 0.902430299)
  private static let Data1992_1122 = simd_quatd(ix: 0.902430299 , iy: 0.168659745 , iz: -0.000000000 , r: -0.396451064)
  private static let Data1992_1123 = simd_quatd(ix: -0.565110809 , iy: 0.337319490 , iz: 0.168659745 , r: 0.733770554)
  private static let Data1992_1124 = simd_quatd(ix: -0.565110809 , iy: 0.337319490 , iz: -0.168659745 , r: 0.733770554)
  private static let Data1992_1125 = simd_quatd(ix: -0.565110809 , iy: -0.168659745 , iz: -0.337319490 , r: 0.733770554)
  private static let Data1992_1126 = simd_quatd(ix: -0.565110809 , iy: -0.168659745 , iz: 0.337319490 , r: 0.733770554)
  private static let Data1992_1127 = simd_quatd(ix: 0.733770554 , iy: -0.337319490 , iz: -0.168659745 , r: -0.565110809)
  private static let Data1992_1128 = simd_quatd(ix: -0.565110809 , iy: 0.168659745 , iz: -0.337319490 , r: 0.733770554)
  private static let Data1992_1129 = simd_quatd(ix: 0.733770554 , iy: 0.168659745 , iz: 0.337319490 , r: -0.565110809)
  private static let Data1992_1130 = simd_quatd(ix: -0.565110809 , iy: -0.337319490 , iz: 0.168659745 , r: 0.733770554)
  private static let Data1992_1131 = simd_quatd(ix: -0.565110809 , iy: 0.168659745 , iz: 0.337319490 , r: 0.733770554)
  private static let Data1992_1132 = simd_quatd(ix: 0.733770554 , iy: -0.337319490 , iz: 0.168659745 , r: -0.565110809)
  private static let Data1992_1133 = simd_quatd(ix: -0.565110809 , iy: -0.337319490 , iz: -0.168659745 , r: 0.733770554)
  private static let Data1992_1134 = simd_quatd(ix: 0.733770554 , iy: 0.168659745 , iz: -0.337319490 , r: -0.565110809)
  private static let Data1992_1135 = simd_quatd(ix: 0.733770554 , iy: -0.168659745 , iz: -0.337319490 , r: -0.565110809)
  private static let Data1992_1136 = simd_quatd(ix: 0.733770554 , iy: -0.168659745 , iz: 0.337319490 , r: -0.565110809)
  private static let Data1992_1137 = simd_quatd(ix: 0.733770554 , iy: 0.337319490 , iz: 0.168659745 , r: -0.565110809)
  private static let Data1992_1138 = simd_quatd(ix: 0.733770554 , iy: 0.337319490 , iz: -0.168659745 , r: -0.565110809)
  private static let Data1992_1139 = simd_quatd(ix: -0.375654863 , iy: 0.319625089 , iz: -0.159812545 , r: 0.855092496)
  private static let Data1992_1140 = simd_quatd(ix: 0.855092496 , iy: -0.319625089 , iz: 0.159812545 , r: -0.375654863)
  private static let Data1992_1141 = simd_quatd(ix: -0.375654863 , iy: -0.159812545 , iz: 0.319625089 , r: 0.855092496)
  private static let Data1992_1142 = simd_quatd(ix: 0.855092496 , iy: 0.159812545 , iz: -0.319625089 , r: -0.375654863)
  private static let Data1992_1143 = simd_quatd(ix: -0.375654863 , iy: 0.159812545 , iz: -0.319625089 , r: 0.855092496)
  private static let Data1992_1144 = simd_quatd(ix: 0.855092496 , iy: -0.159812545 , iz: 0.319625089 , r: -0.375654863)
  private static let Data1992_1145 = simd_quatd(ix: -0.375654863 , iy: -0.319625089 , iz: 0.159812545 , r: 0.855092496)
  private static let Data1992_1146 = simd_quatd(ix: 0.855092496 , iy: 0.319625089 , iz: -0.159812545 , r: -0.375654863)
  private static let Data1992_1147 = simd_quatd(ix: -0.375654863 , iy: 0.319625089 , iz: 0.159812545 , r: 0.855092496)
  private static let Data1992_1148 = simd_quatd(ix: -0.535467407 , iy: 0.479437634 , iz: 0.000000000 , r: 0.695279952)
  private static let Data1992_1149 = simd_quatd(ix: -0.375654863 , iy: -0.159812545 , iz: -0.319625089 , r: 0.855092496)
  private static let Data1992_1150 = simd_quatd(ix: -0.535467407 , iy: 0.000000000 , iz: 0.479437634 , r: 0.695279952)
  private static let Data1992_1151 = simd_quatd(ix: 0.855092496 , iy: -0.319625089 , iz: -0.159812545 , r: -0.375654863)
  private static let Data1992_1152 = simd_quatd(ix: -0.535467407 , iy: 0.000000000 , iz: -0.479437634 , r: 0.695279952)
  private static let Data1992_1153 = simd_quatd(ix: 0.855092496 , iy: 0.159812545 , iz: 0.319625089 , r: -0.375654863)
  private static let Data1992_1154 = simd_quatd(ix: -0.535467407 , iy: -0.479437634 , iz: 0.000000000 , r: 0.695279952)
  private static let Data1992_1155 = simd_quatd(ix: -0.375654863 , iy: 0.159812545 , iz: 0.319625089 , r: 0.855092496)
  private static let Data1992_1156 = simd_quatd(ix: 0.695279952 , iy: -0.479437634 , iz: -0.000000000 , r: -0.535467407)
  private static let Data1992_1157 = simd_quatd(ix: -0.375654863 , iy: -0.319625089 , iz: -0.159812545 , r: 0.855092496)
  private static let Data1992_1158 = simd_quatd(ix: 0.695279952 , iy: -0.000000000 , iz: -0.479437634 , r: -0.535467407)
  private static let Data1992_1159 = simd_quatd(ix: 0.855092496 , iy: -0.159812545 , iz: -0.319625089 , r: -0.375654863)
  private static let Data1992_1160 = simd_quatd(ix: 0.695279952 , iy: -0.000000000 , iz: 0.479437634 , r: -0.535467407)
  private static let Data1992_1161 = simd_quatd(ix: 0.855092496 , iy: 0.319625089 , iz: 0.159812545 , r: -0.375654863)
  private static let Data1992_1162 = simd_quatd(ix: 0.695279952 , iy: 0.479437634 , iz: -0.000000000 , r: -0.535467407)
  private static let Data1992_1163 = simd_quatd(ix: 0.000000000 , iy: 0.707106781 , iz: 0.000000000 , r: 0.707106781)
  private static let Data1992_1164 = simd_quatd(ix: 0.179160289 , iy: 0.779454186 , iz: 0.000000000 , r: 0.600293897)
  private static let Data1992_1165 = simd_quatd(ix: 0.000000000 , iy: 0.779454186 , iz: 0.179160289 , r: 0.600293897)
  private static let Data1992_1166 = simd_quatd(ix: 0.179160289 , iy: 0.600293897 , iz: 0.000000000 , r: 0.779454186)
  private static let Data1992_1167 = simd_quatd(ix: 0.000000000 , iy: 0.600293897 , iz: 0.179160289 , r: 0.779454186)
  private static let Data1992_1168 = simd_quatd(ix: 0.000000000 , iy: 0.779454186 , iz: -0.179160289 , r: 0.600293897)
  private static let Data1992_1169 = simd_quatd(ix: -0.179160289 , iy: 0.779454186 , iz: 0.000000000 , r: 0.600293897)
  private static let Data1992_1170 = simd_quatd(ix: 0.000000000 , iy: 0.600293897 , iz: -0.179160289 , r: 0.779454186)
  private static let Data1992_1171 = simd_quatd(ix: -0.179160289 , iy: 0.600293897 , iz: 0.000000000 , r: 0.779454186)
  private static let Data1992_1172 = simd_quatd(ix: 0.177739676 , iy: 0.684403834 , iz: -0.177739676 , r: 0.684403834)
  private static let Data1992_1173 = simd_quatd(ix: -0.177739676 , iy: 0.684403834 , iz: 0.177739676 , r: 0.684403834)
  private static let Data1992_1174 = simd_quatd(ix: 0.177739676 , iy: 0.684403834 , iz: 0.177739676 , r: 0.684403834)
  private static let Data1992_1175 = simd_quatd(ix: 0.000000000 , iy: 0.862143509 , iz: 0.000000000 , r: 0.506664158)
  private static let Data1992_1176 = simd_quatd(ix: -0.177739676 , iy: 0.684403834 , iz: -0.177739676 , r: 0.684403834)
  private static let Data1992_1177 = simd_quatd(ix: 0.000000000 , iy: 0.506664158 , iz: 0.000000000 , r: 0.862143509)
  private static let Data1992_1178 = simd_quatd(ix: 0.172377436 , iy: 0.836133444 , iz: -0.172377436 , r: 0.491378573)
  private static let Data1992_1179 = simd_quatd(ix: -0.172377436 , iy: 0.836133444 , iz: 0.172377436 , r: 0.491378573)
  private static let Data1992_1180 = simd_quatd(ix: 0.172377436 , iy: 0.491378573 , iz: -0.172377436 , r: 0.836133444)
  private static let Data1992_1181 = simd_quatd(ix: -0.172377436 , iy: 0.491378573 , iz: 0.172377436 , r: 0.836133444)
  private static let Data1992_1182 = simd_quatd(ix: 0.344754871 , iy: 0.663756009 , iz: 0.000000000 , r: 0.663756009)
  private static let Data1992_1183 = simd_quatd(ix: 0.172377436 , iy: 0.836133444 , iz: 0.172377436 , r: 0.491378573)
  private static let Data1992_1184 = simd_quatd(ix: 0.000000000 , iy: 0.663756009 , iz: -0.344754871 , r: 0.663756009)
  private static let Data1992_1185 = simd_quatd(ix: 0.172377436 , iy: 0.491378573 , iz: 0.172377436 , r: 0.836133444)
  private static let Data1992_1186 = simd_quatd(ix: 0.000000000 , iy: 0.663756009 , iz: 0.344754871 , r: 0.663756009)
  private static let Data1992_1187 = simd_quatd(ix: -0.172377436 , iy: 0.836133444 , iz: -0.172377436 , r: 0.491378573)
  private static let Data1992_1188 = simd_quatd(ix: -0.344754871 , iy: 0.663756009 , iz: 0.000000000 , r: 0.663756009)
  private static let Data1992_1189 = simd_quatd(ix: -0.172377436 , iy: 0.491378573 , iz: -0.172377436 , r: 0.836133444)
  private static let Data1992_1190 = simd_quatd(ix: 0.334945923 , iy: 0.812343818 , iz: 0.000000000 , r: 0.477397895)
  private static let Data1992_1191 = simd_quatd(ix: 0.000000000 , iy: 0.812343818 , iz: 0.334945923 , r: 0.477397895)
  private static let Data1992_1192 = simd_quatd(ix: 0.334945923 , iy: 0.477397895 , iz: 0.000000000 , r: 0.812343818)
  private static let Data1992_1193 = simd_quatd(ix: 0.000000000 , iy: 0.477397895 , iz: 0.334945923 , r: 0.812343818)
  private static let Data1992_1194 = simd_quatd(ix: 0.000000000 , iy: 0.812343818 , iz: -0.334945923 , r: 0.477397895)
  private static let Data1992_1195 = simd_quatd(ix: -0.334945923 , iy: 0.812343818 , iz: 0.000000000 , r: 0.477397895)
  private static let Data1992_1196 = simd_quatd(ix: 0.000000000 , iy: 0.477397895 , iz: -0.334945923 , r: 0.812343818)
  private static let Data1992_1197 = simd_quatd(ix: -0.334945923 , iy: 0.477397895 , iz: 0.000000000 , r: 0.812343818)
  private static let Data1992_1198 = simd_quatd(ix: 0.337319490 , iy: 0.733770554 , iz: -0.168659745 , r: 0.565110809)
  private static let Data1992_1199 = simd_quatd(ix: -0.168659745 , iy: 0.733770554 , iz: 0.337319490 , r: 0.565110809)
  private static let Data1992_1200 = simd_quatd(ix: 0.337319490 , iy: 0.565110809 , iz: -0.168659745 , r: 0.733770554)
  private static let Data1992_1201 = simd_quatd(ix: -0.168659745 , iy: 0.565110809 , iz: 0.337319490 , r: 0.733770554)
  private static let Data1992_1202 = simd_quatd(ix: 0.168659745 , iy: 0.733770554 , iz: -0.337319490 , r: 0.565110809)
  private static let Data1992_1203 = simd_quatd(ix: -0.337319490 , iy: 0.733770554 , iz: 0.168659745 , r: 0.565110809)
  private static let Data1992_1204 = simd_quatd(ix: 0.168659745 , iy: 0.565110809 , iz: -0.337319490 , r: 0.733770554)
  private static let Data1992_1205 = simd_quatd(ix: -0.337319490 , iy: 0.565110809 , iz: 0.168659745 , r: 0.733770554)
  private static let Data1992_1206 = simd_quatd(ix: 0.337319490 , iy: 0.733770554 , iz: 0.168659745 , r: 0.565110809)
  private static let Data1992_1207 = simd_quatd(ix: 0.168659745 , iy: 0.902430299 , iz: 0.000000000 , r: 0.396451064)
  private static let Data1992_1208 = simd_quatd(ix: -0.168659745 , iy: 0.733770554 , iz: -0.337319490 , r: 0.565110809)
  private static let Data1992_1209 = simd_quatd(ix: 0.168659745 , iy: 0.396451064 , iz: 0.000000000 , r: 0.902430299)
  private static let Data1992_1210 = simd_quatd(ix: 0.168659745 , iy: 0.733770554 , iz: 0.337319490 , r: 0.565110809)
  private static let Data1992_1211 = simd_quatd(ix: 0.000000000 , iy: 0.902430299 , iz: -0.168659745 , r: 0.396451064)
  private static let Data1992_1212 = simd_quatd(ix: -0.337319490 , iy: 0.733770554 , iz: -0.168659745 , r: 0.565110809)
  private static let Data1992_1213 = simd_quatd(ix: 0.000000000 , iy: 0.396451064 , iz: -0.168659745 , r: 0.902430299)
  private static let Data1992_1214 = simd_quatd(ix: 0.337319490 , iy: 0.565110809 , iz: 0.168659745 , r: 0.733770554)
  private static let Data1992_1215 = simd_quatd(ix: 0.000000000 , iy: 0.902430299 , iz: 0.168659745 , r: 0.396451064)
  private static let Data1992_1216 = simd_quatd(ix: -0.168659745 , iy: 0.565110809 , iz: -0.337319490 , r: 0.733770554)
  private static let Data1992_1217 = simd_quatd(ix: 0.000000000 , iy: 0.396451064 , iz: 0.168659745 , r: 0.902430299)
  private static let Data1992_1218 = simd_quatd(ix: 0.168659745 , iy: 0.565110809 , iz: 0.337319490 , r: 0.733770554)
  private static let Data1992_1219 = simd_quatd(ix: -0.168659745 , iy: 0.902430299 , iz: 0.000000000 , r: 0.396451064)
  private static let Data1992_1220 = simd_quatd(ix: -0.337319490 , iy: 0.565110809 , iz: -0.168659745 , r: 0.733770554)
  private static let Data1992_1221 = simd_quatd(ix: -0.168659745 , iy: 0.396451064 , iz: 0.000000000 , r: 0.902430299)
  private static let Data1992_1222 = simd_quatd(ix: 0.319625089 , iy: 0.855092496 , iz: -0.159812545 , r: 0.375654863)
  private static let Data1992_1223 = simd_quatd(ix: -0.159812545 , iy: 0.855092496 , iz: 0.319625089 , r: 0.375654863)
  private static let Data1992_1224 = simd_quatd(ix: 0.319625089 , iy: 0.375654863 , iz: -0.159812545 , r: 0.855092496)
  private static let Data1992_1225 = simd_quatd(ix: -0.159812545 , iy: 0.375654863 , iz: 0.319625089 , r: 0.855092496)
  private static let Data1992_1226 = simd_quatd(ix: 0.159812545 , iy: 0.855092496 , iz: -0.319625089 , r: 0.375654863)
  private static let Data1992_1227 = simd_quatd(ix: -0.319625089 , iy: 0.855092496 , iz: 0.159812545 , r: 0.375654863)
  private static let Data1992_1228 = simd_quatd(ix: 0.159812545 , iy: 0.375654863 , iz: -0.319625089 , r: 0.855092496)
  private static let Data1992_1229 = simd_quatd(ix: -0.319625089 , iy: 0.375654863 , iz: 0.159812545 , r: 0.855092496)
  private static let Data1992_1230 = simd_quatd(ix: 0.479437634 , iy: 0.695279952 , iz: 0.000000000 , r: 0.535467407)
  private static let Data1992_1231 = simd_quatd(ix: 0.319625089 , iy: 0.855092496 , iz: 0.159812545 , r: 0.375654863)
  private static let Data1992_1232 = simd_quatd(ix: 0.000000000 , iy: 0.695279952 , iz: -0.479437634 , r: 0.535467407)
  private static let Data1992_1233 = simd_quatd(ix: 0.319625089 , iy: 0.375654863 , iz: 0.159812545 , r: 0.855092496)
  private static let Data1992_1234 = simd_quatd(ix: 0.000000000 , iy: 0.695279952 , iz: 0.479437634 , r: 0.535467407)
  private static let Data1992_1235 = simd_quatd(ix: -0.159812545 , iy: 0.855092496 , iz: -0.319625089 , r: 0.375654863)
  private static let Data1992_1236 = simd_quatd(ix: -0.479437634 , iy: 0.695279952 , iz: 0.000000000 , r: 0.535467407)
  private static let Data1992_1237 = simd_quatd(ix: -0.159812545 , iy: 0.375654863 , iz: -0.319625089 , r: 0.855092496)
  private static let Data1992_1238 = simd_quatd(ix: 0.479437634 , iy: 0.535467407 , iz: 0.000000000 , r: 0.695279952)
  private static let Data1992_1239 = simd_quatd(ix: 0.159812545 , iy: 0.855092496 , iz: 0.319625089 , r: 0.375654863)
  private static let Data1992_1240 = simd_quatd(ix: 0.000000000 , iy: 0.535467407 , iz: -0.479437634 , r: 0.695279952)
  private static let Data1992_1241 = simd_quatd(ix: 0.159812545 , iy: 0.375654863 , iz: 0.319625089 , r: 0.855092496)
  private static let Data1992_1242 = simd_quatd(ix: 0.000000000 , iy: 0.535467407 , iz: 0.479437634 , r: 0.695279952)
  private static let Data1992_1243 = simd_quatd(ix: -0.319625089 , iy: 0.855092496 , iz: -0.159812545 , r: 0.375654863)
  private static let Data1992_1244 = simd_quatd(ix: -0.479437634 , iy: 0.535467407 , iz: 0.000000000 , r: 0.695279952)
  private static let Data1992_1245 = simd_quatd(ix: -0.319625089 , iy: 0.375654863 , iz: -0.159812545 , r: 0.855092496)
  private static let Data1992_1246 = simd_quatd(ix: 0.000000000 , iy: -0.707106781 , iz: 0.000000000 , r: 0.707106781)
  private static let Data1992_1247 = simd_quatd(ix: 0.000000000 , iy: -0.600293897 , iz: 0.179160289 , r: 0.779454186)
  private static let Data1992_1248 = simd_quatd(ix: -0.179160289 , iy: -0.600293897 , iz: 0.000000000 , r: 0.779454186)
  private static let Data1992_1249 = simd_quatd(ix: -0.000000000 , iy: 0.779454186 , iz: -0.179160289 , r: -0.600293897)
  private static let Data1992_1250 = simd_quatd(ix: 0.179160289 , iy: 0.779454186 , iz: -0.000000000 , r: -0.600293897)
  private static let Data1992_1251 = simd_quatd(ix: 0.179160289 , iy: -0.600293897 , iz: 0.000000000 , r: 0.779454186)
  private static let Data1992_1252 = simd_quatd(ix: 0.000000000 , iy: -0.600293897 , iz: -0.179160289 , r: 0.779454186)
  private static let Data1992_1253 = simd_quatd(ix: -0.179160289 , iy: 0.779454186 , iz: -0.000000000 , r: -0.600293897)
  private static let Data1992_1254 = simd_quatd(ix: -0.000000000 , iy: 0.779454186 , iz: 0.179160289 , r: -0.600293897)
  private static let Data1992_1255 = simd_quatd(ix: 0.177739676 , iy: -0.684403834 , iz: 0.177739676 , r: 0.684403834)
  private static let Data1992_1256 = simd_quatd(ix: -0.177739676 , iy: -0.684403834 , iz: -0.177739676 , r: 0.684403834)
  private static let Data1992_1257 = simd_quatd(ix: -0.177739676 , iy: -0.684403834 , iz: 0.177739676 , r: 0.684403834)
  private static let Data1992_1258 = simd_quatd(ix: 0.000000000 , iy: -0.506664158 , iz: 0.000000000 , r: 0.862143509)
  private static let Data1992_1259 = simd_quatd(ix: 0.177739676 , iy: -0.684403834 , iz: -0.177739676 , r: 0.684403834)
  private static let Data1992_1260 = simd_quatd(ix: -0.000000000 , iy: 0.862143509 , iz: -0.000000000 , r: -0.506664158)
  private static let Data1992_1261 = simd_quatd(ix: 0.172377436 , iy: -0.491378573 , iz: 0.172377436 , r: 0.836133444)
  private static let Data1992_1262 = simd_quatd(ix: -0.172377436 , iy: -0.491378573 , iz: -0.172377436 , r: 0.836133444)
  private static let Data1992_1263 = simd_quatd(ix: -0.172377436 , iy: 0.836133444 , iz: -0.172377436 , r: -0.491378573)
  private static let Data1992_1264 = simd_quatd(ix: 0.172377436 , iy: 0.836133444 , iz: 0.172377436 , r: -0.491378573)
  private static let Data1992_1265 = simd_quatd(ix: 0.000000000 , iy: -0.663756009 , iz: 0.344754871 , r: 0.663756009)
  private static let Data1992_1266 = simd_quatd(ix: -0.172377436 , iy: -0.491378573 , iz: 0.172377436 , r: 0.836133444)
  private static let Data1992_1267 = simd_quatd(ix: 0.344754871 , iy: -0.663756009 , iz: 0.000000000 , r: 0.663756009)
  private static let Data1992_1268 = simd_quatd(ix: 0.172377436 , iy: 0.836133444 , iz: -0.172377436 , r: -0.491378573)
  private static let Data1992_1269 = simd_quatd(ix: -0.344754871 , iy: -0.663756009 , iz: 0.000000000 , r: 0.663756009)
  private static let Data1992_1270 = simd_quatd(ix: 0.172377436 , iy: -0.491378573 , iz: -0.172377436 , r: 0.836133444)
  private static let Data1992_1271 = simd_quatd(ix: 0.000000000 , iy: -0.663756009 , iz: -0.344754871 , r: 0.663756009)
  private static let Data1992_1272 = simd_quatd(ix: -0.172377436 , iy: 0.836133444 , iz: 0.172377436 , r: -0.491378573)
  private static let Data1992_1273 = simd_quatd(ix: 0.000000000 , iy: -0.477397895 , iz: 0.334945923 , r: 0.812343818)
  private static let Data1992_1274 = simd_quatd(ix: -0.334945923 , iy: -0.477397895 , iz: 0.000000000 , r: 0.812343818)
  private static let Data1992_1275 = simd_quatd(ix: -0.000000000 , iy: 0.812343818 , iz: -0.334945923 , r: -0.477397895)
  private static let Data1992_1276 = simd_quatd(ix: 0.334945923 , iy: 0.812343818 , iz: -0.000000000 , r: -0.477397895)
  private static let Data1992_1277 = simd_quatd(ix: 0.334945923 , iy: -0.477397895 , iz: 0.000000000 , r: 0.812343818)
  private static let Data1992_1278 = simd_quatd(ix: 0.000000000 , iy: -0.477397895 , iz: -0.334945923 , r: 0.812343818)
  private static let Data1992_1279 = simd_quatd(ix: -0.334945923 , iy: 0.812343818 , iz: -0.000000000 , r: -0.477397895)
  private static let Data1992_1280 = simd_quatd(ix: -0.000000000 , iy: 0.812343818 , iz: 0.334945923 , r: -0.477397895)
  private static let Data1992_1281 = simd_quatd(ix: 0.168659745 , iy: -0.565110809 , iz: 0.337319490 , r: 0.733770554)
  private static let Data1992_1282 = simd_quatd(ix: -0.337319490 , iy: -0.565110809 , iz: -0.168659745 , r: 0.733770554)
  private static let Data1992_1283 = simd_quatd(ix: -0.168659745 , iy: 0.733770554 , iz: -0.337319490 , r: -0.565110809)
  private static let Data1992_1284 = simd_quatd(ix: 0.337319490 , iy: 0.733770554 , iz: 0.168659745 , r: -0.565110809)
  private static let Data1992_1285 = simd_quatd(ix: 0.337319490 , iy: -0.565110809 , iz: 0.168659745 , r: 0.733770554)
  private static let Data1992_1286 = simd_quatd(ix: -0.168659745 , iy: -0.565110809 , iz: -0.337319490 , r: 0.733770554)
  private static let Data1992_1287 = simd_quatd(ix: -0.337319490 , iy: 0.733770554 , iz: -0.168659745 , r: -0.565110809)
  private static let Data1992_1288 = simd_quatd(ix: 0.168659745 , iy: 0.733770554 , iz: 0.337319490 , r: -0.565110809)
  private static let Data1992_1289 = simd_quatd(ix: -0.168659745 , iy: -0.565110809 , iz: 0.337319490 , r: 0.733770554)
  private static let Data1992_1290 = simd_quatd(ix: 0.000000000 , iy: -0.396451064 , iz: 0.168659745 , r: 0.902430299)
  private static let Data1992_1291 = simd_quatd(ix: 0.337319490 , iy: -0.565110809 , iz: -0.168659745 , r: 0.733770554)
  private static let Data1992_1292 = simd_quatd(ix: -0.000000000 , iy: 0.902430299 , iz: -0.168659745 , r: -0.396451064)
  private static let Data1992_1293 = simd_quatd(ix: -0.337319490 , iy: -0.565110809 , iz: 0.168659745 , r: 0.733770554)
  private static let Data1992_1294 = simd_quatd(ix: 0.168659745 , iy: -0.396451064 , iz: 0.000000000 , r: 0.902430299)
  private static let Data1992_1295 = simd_quatd(ix: 0.168659745 , iy: -0.565110809 , iz: -0.337319490 , r: 0.733770554)
  private static let Data1992_1296 = simd_quatd(ix: -0.168659745 , iy: 0.902430299 , iz: -0.000000000 , r: -0.396451064)
  private static let Data1992_1297 = simd_quatd(ix: 0.168659745 , iy: 0.733770554 , iz: -0.337319490 , r: -0.565110809)
  private static let Data1992_1298 = simd_quatd(ix: -0.168659745 , iy: -0.396451064 , iz: 0.000000000 , r: 0.902430299)
  private static let Data1992_1299 = simd_quatd(ix: -0.337319490 , iy: 0.733770554 , iz: 0.168659745 , r: -0.565110809)
  private static let Data1992_1300 = simd_quatd(ix: 0.168659745 , iy: 0.902430299 , iz: -0.000000000 , r: -0.396451064)
  private static let Data1992_1301 = simd_quatd(ix: 0.337319490 , iy: 0.733770554 , iz: -0.168659745 , r: -0.565110809)
  private static let Data1992_1302 = simd_quatd(ix: 0.000000000 , iy: -0.396451064 , iz: -0.168659745 , r: 0.902430299)
  private static let Data1992_1303 = simd_quatd(ix: -0.168659745 , iy: 0.733770554 , iz: 0.337319490 , r: -0.565110809)
  private static let Data1992_1304 = simd_quatd(ix: -0.000000000 , iy: 0.902430299 , iz: 0.168659745 , r: -0.396451064)
  private static let Data1992_1305 = simd_quatd(ix: 0.159812545 , iy: -0.375654863 , iz: 0.319625089 , r: 0.855092496)
  private static let Data1992_1306 = simd_quatd(ix: -0.319625089 , iy: -0.375654863 , iz: -0.159812545 , r: 0.855092496)
  private static let Data1992_1307 = simd_quatd(ix: -0.159812545 , iy: 0.855092496 , iz: -0.319625089 , r: -0.375654863)
  private static let Data1992_1308 = simd_quatd(ix: 0.319625089 , iy: 0.855092496 , iz: 0.159812545 , r: -0.375654863)
  private static let Data1992_1309 = simd_quatd(ix: 0.319625089 , iy: -0.375654863 , iz: 0.159812545 , r: 0.855092496)
  private static let Data1992_1310 = simd_quatd(ix: -0.159812545 , iy: -0.375654863 , iz: -0.319625089 , r: 0.855092496)
  private static let Data1992_1311 = simd_quatd(ix: -0.319625089 , iy: 0.855092496 , iz: -0.159812545 , r: -0.375654863)
  private static let Data1992_1312 = simd_quatd(ix: 0.159812545 , iy: 0.855092496 , iz: 0.319625089 , r: -0.375654863)
  private static let Data1992_1313 = simd_quatd(ix: 0.000000000 , iy: -0.535467407 , iz: 0.479437634 , r: 0.695279952)
  private static let Data1992_1314 = simd_quatd(ix: -0.159812545 , iy: -0.375654863 , iz: 0.319625089 , r: 0.855092496)
  private static let Data1992_1315 = simd_quatd(ix: 0.479437634 , iy: -0.535467407 , iz: 0.000000000 , r: 0.695279952)
  private static let Data1992_1316 = simd_quatd(ix: 0.159812545 , iy: 0.855092496 , iz: -0.319625089 , r: -0.375654863)
  private static let Data1992_1317 = simd_quatd(ix: -0.479437634 , iy: -0.535467407 , iz: 0.000000000 , r: 0.695279952)
  private static let Data1992_1318 = simd_quatd(ix: 0.319625089 , iy: -0.375654863 , iz: -0.159812545 , r: 0.855092496)
  private static let Data1992_1319 = simd_quatd(ix: 0.000000000 , iy: -0.535467407 , iz: -0.479437634 , r: 0.695279952)
  private static let Data1992_1320 = simd_quatd(ix: -0.319625089 , iy: 0.855092496 , iz: 0.159812545 , r: -0.375654863)
  private static let Data1992_1321 = simd_quatd(ix: -0.000000000 , iy: 0.695279952 , iz: -0.479437634 , r: -0.535467407)
  private static let Data1992_1322 = simd_quatd(ix: -0.319625089 , iy: -0.375654863 , iz: 0.159812545 , r: 0.855092496)
  private static let Data1992_1323 = simd_quatd(ix: -0.479437634 , iy: 0.695279952 , iz: -0.000000000 , r: -0.535467407)
  private static let Data1992_1324 = simd_quatd(ix: 0.319625089 , iy: 0.855092496 , iz: -0.159812545 , r: -0.375654863)
  private static let Data1992_1325 = simd_quatd(ix: 0.479437634 , iy: 0.695279952 , iz: -0.000000000 , r: -0.535467407)
  private static let Data1992_1326 = simd_quatd(ix: 0.159812545 , iy: -0.375654863 , iz: -0.319625089 , r: 0.855092496)
  private static let Data1992_1327 = simd_quatd(ix: -0.000000000 , iy: 0.695279952 , iz: 0.479437634 , r: -0.535467407)
  private static let Data1992_1328 = simd_quatd(ix: -0.159812545 , iy: 0.855092496 , iz: 0.319625089 , r: -0.375654863)
  private static let Data1992_1329 = simd_quatd(ix: 0.000000000 , iy: 0.000000000 , iz: 0.707106781 , r: 0.707106781)
  private static let Data1992_1330 = simd_quatd(ix: 0.000000000 , iy: 0.179160289 , iz: 0.779454186 , r: 0.600293897)
  private static let Data1992_1331 = simd_quatd(ix: -0.179160289 , iy: 0.000000000 , iz: 0.779454186 , r: 0.600293897)
  private static let Data1992_1332 = simd_quatd(ix: 0.179160289 , iy: 0.000000000 , iz: 0.779454186 , r: 0.600293897)
  private static let Data1992_1333 = simd_quatd(ix: 0.000000000 , iy: -0.179160289 , iz: 0.779454186 , r: 0.600293897)
  private static let Data1992_1334 = simd_quatd(ix: 0.000000000 , iy: 0.179160289 , iz: 0.600293897 , r: 0.779454186)
  private static let Data1992_1335 = simd_quatd(ix: -0.179160289 , iy: 0.000000000 , iz: 0.600293897 , r: 0.779454186)
  private static let Data1992_1336 = simd_quatd(ix: 0.179160289 , iy: 0.000000000 , iz: 0.600293897 , r: 0.779454186)
  private static let Data1992_1337 = simd_quatd(ix: 0.000000000 , iy: -0.179160289 , iz: 0.600293897 , r: 0.779454186)
  private static let Data1992_1338 = simd_quatd(ix: 0.177739676 , iy: 0.177739676 , iz: 0.684403834 , r: 0.684403834)
  private static let Data1992_1339 = simd_quatd(ix: -0.177739676 , iy: -0.177739676 , iz: 0.684403834 , r: 0.684403834)
  private static let Data1992_1340 = simd_quatd(ix: 0.000000000 , iy: 0.000000000 , iz: 0.862143509 , r: 0.506664158)
  private static let Data1992_1341 = simd_quatd(ix: -0.177739676 , iy: 0.177739676 , iz: 0.684403834 , r: 0.684403834)
  private static let Data1992_1342 = simd_quatd(ix: 0.000000000 , iy: 0.000000000 , iz: 0.506664158 , r: 0.862143509)
  private static let Data1992_1343 = simd_quatd(ix: 0.177739676 , iy: -0.177739676 , iz: 0.684403834 , r: 0.684403834)
  private static let Data1992_1344 = simd_quatd(ix: 0.000000000 , iy: 0.344754871 , iz: 0.663756009 , r: 0.663756009)
  private static let Data1992_1345 = simd_quatd(ix: -0.344754871 , iy: 0.000000000 , iz: 0.663756009 , r: 0.663756009)
  private static let Data1992_1346 = simd_quatd(ix: 0.344754871 , iy: 0.000000000 , iz: 0.663756009 , r: 0.663756009)
  private static let Data1992_1347 = simd_quatd(ix: 0.000000000 , iy: -0.344754871 , iz: 0.663756009 , r: 0.663756009)
  private static let Data1992_1348 = simd_quatd(ix: 0.172377436 , iy: 0.172377436 , iz: 0.836133444 , r: 0.491378573)
  private static let Data1992_1349 = simd_quatd(ix: -0.172377436 , iy: 0.172377436 , iz: 0.836133444 , r: 0.491378573)
  private static let Data1992_1350 = simd_quatd(ix: 0.172377436 , iy: 0.172377436 , iz: 0.491378573 , r: 0.836133444)
  private static let Data1992_1351 = simd_quatd(ix: 0.172377436 , iy: -0.172377436 , iz: 0.836133444 , r: 0.491378573)
  private static let Data1992_1352 = simd_quatd(ix: -0.172377436 , iy: -0.172377436 , iz: 0.836133444 , r: 0.491378573)
  private static let Data1992_1353 = simd_quatd(ix: -0.172377436 , iy: 0.172377436 , iz: 0.491378573 , r: 0.836133444)
  private static let Data1992_1354 = simd_quatd(ix: -0.172377436 , iy: -0.172377436 , iz: 0.491378573 , r: 0.836133444)
  private static let Data1992_1355 = simd_quatd(ix: 0.172377436 , iy: -0.172377436 , iz: 0.491378573 , r: 0.836133444)
  private static let Data1992_1356 = simd_quatd(ix: 0.000000000 , iy: 0.334945923 , iz: 0.812343818 , r: 0.477397895)
  private static let Data1992_1357 = simd_quatd(ix: -0.334945923 , iy: 0.000000000 , iz: 0.812343818 , r: 0.477397895)
  private static let Data1992_1358 = simd_quatd(ix: 0.334945923 , iy: 0.000000000 , iz: 0.812343818 , r: 0.477397895)
  private static let Data1992_1359 = simd_quatd(ix: 0.000000000 , iy: -0.334945923 , iz: 0.812343818 , r: 0.477397895)
  private static let Data1992_1360 = simd_quatd(ix: 0.000000000 , iy: 0.334945923 , iz: 0.477397895 , r: 0.812343818)
  private static let Data1992_1361 = simd_quatd(ix: -0.334945923 , iy: 0.000000000 , iz: 0.477397895 , r: 0.812343818)
  private static let Data1992_1362 = simd_quatd(ix: 0.334945923 , iy: 0.000000000 , iz: 0.477397895 , r: 0.812343818)
  private static let Data1992_1363 = simd_quatd(ix: 0.000000000 , iy: -0.334945923 , iz: 0.477397895 , r: 0.812343818)
  private static let Data1992_1364 = simd_quatd(ix: 0.168659745 , iy: 0.337319490 , iz: 0.733770554 , r: 0.565110809)
  private static let Data1992_1365 = simd_quatd(ix: -0.337319490 , iy: -0.168659745 , iz: 0.733770554 , r: 0.565110809)
  private static let Data1992_1366 = simd_quatd(ix: 0.337319490 , iy: 0.168659745 , iz: 0.733770554 , r: 0.565110809)
  private static let Data1992_1367 = simd_quatd(ix: -0.168659745 , iy: -0.337319490 , iz: 0.733770554 , r: 0.565110809)
  private static let Data1992_1368 = simd_quatd(ix: 0.168659745 , iy: 0.337319490 , iz: 0.565110809 , r: 0.733770554)
  private static let Data1992_1369 = simd_quatd(ix: -0.337319490 , iy: -0.168659745 , iz: 0.565110809 , r: 0.733770554)
  private static let Data1992_1370 = simd_quatd(ix: 0.337319490 , iy: 0.168659745 , iz: 0.565110809 , r: 0.733770554)
  private static let Data1992_1371 = simd_quatd(ix: -0.168659745 , iy: -0.337319490 , iz: 0.565110809 , r: 0.733770554)
  private static let Data1992_1372 = simd_quatd(ix: 0.000000000 , iy: 0.168659745 , iz: 0.902430299 , r: 0.396451064)
  private static let Data1992_1373 = simd_quatd(ix: -0.168659745 , iy: 0.337319490 , iz: 0.733770554 , r: 0.565110809)
  private static let Data1992_1374 = simd_quatd(ix: 0.000000000 , iy: 0.168659745 , iz: 0.396451064 , r: 0.902430299)
  private static let Data1992_1375 = simd_quatd(ix: 0.337319490 , iy: -0.168659745 , iz: 0.733770554 , r: 0.565110809)
  private static let Data1992_1376 = simd_quatd(ix: -0.168659745 , iy: 0.000000000 , iz: 0.902430299 , r: 0.396451064)
  private static let Data1992_1377 = simd_quatd(ix: -0.168659745 , iy: 0.337319490 , iz: 0.565110809 , r: 0.733770554)
  private static let Data1992_1378 = simd_quatd(ix: -0.168659745 , iy: 0.000000000 , iz: 0.396451064 , r: 0.902430299)
  private static let Data1992_1379 = simd_quatd(ix: 0.337319490 , iy: -0.168659745 , iz: 0.565110809 , r: 0.733770554)
  private static let Data1992_1380 = simd_quatd(ix: 0.168659745 , iy: 0.000000000 , iz: 0.902430299 , r: 0.396451064)
  private static let Data1992_1381 = simd_quatd(ix: -0.337319490 , iy: 0.168659745 , iz: 0.733770554 , r: 0.565110809)
  private static let Data1992_1382 = simd_quatd(ix: 0.168659745 , iy: 0.000000000 , iz: 0.396451064 , r: 0.902430299)
  private static let Data1992_1383 = simd_quatd(ix: 0.168659745 , iy: -0.337319490 , iz: 0.733770554 , r: 0.565110809)
  private static let Data1992_1384 = simd_quatd(ix: 0.000000000 , iy: -0.168659745 , iz: 0.902430299 , r: 0.396451064)
  private static let Data1992_1385 = simd_quatd(ix: -0.337319490 , iy: 0.168659745 , iz: 0.565110809 , r: 0.733770554)
  private static let Data1992_1386 = simd_quatd(ix: 0.000000000 , iy: -0.168659745 , iz: 0.396451064 , r: 0.902430299)
  private static let Data1992_1387 = simd_quatd(ix: 0.168659745 , iy: -0.337319490 , iz: 0.565110809 , r: 0.733770554)
  private static let Data1992_1388 = simd_quatd(ix: 0.000000000 , iy: 0.479437634 , iz: 0.695279952 , r: 0.535467407)
  private static let Data1992_1389 = simd_quatd(ix: -0.479437634 , iy: 0.000000000 , iz: 0.695279952 , r: 0.535467407)
  private static let Data1992_1390 = simd_quatd(ix: 0.479437634 , iy: 0.000000000 , iz: 0.695279952 , r: 0.535467407)
  private static let Data1992_1391 = simd_quatd(ix: 0.000000000 , iy: -0.479437634 , iz: 0.695279952 , r: 0.535467407)
  private static let Data1992_1392 = simd_quatd(ix: 0.000000000 , iy: 0.479437634 , iz: 0.535467407 , r: 0.695279952)
  private static let Data1992_1393 = simd_quatd(ix: -0.479437634 , iy: 0.000000000 , iz: 0.535467407 , r: 0.695279952)
  private static let Data1992_1394 = simd_quatd(ix: 0.479437634 , iy: 0.000000000 , iz: 0.535467407 , r: 0.695279952)
  private static let Data1992_1395 = simd_quatd(ix: 0.000000000 , iy: -0.479437634 , iz: 0.535467407 , r: 0.695279952)
  private static let Data1992_1396 = simd_quatd(ix: 0.159812545 , iy: 0.319625089 , iz: 0.855092496 , r: 0.375654863)
  private static let Data1992_1397 = simd_quatd(ix: -0.159812545 , iy: 0.319625089 , iz: 0.855092496 , r: 0.375654863)
  private static let Data1992_1398 = simd_quatd(ix: 0.159812545 , iy: 0.319625089 , iz: 0.375654863 , r: 0.855092496)
  private static let Data1992_1399 = simd_quatd(ix: 0.319625089 , iy: -0.159812545 , iz: 0.855092496 , r: 0.375654863)
  private static let Data1992_1400 = simd_quatd(ix: -0.319625089 , iy: -0.159812545 , iz: 0.855092496 , r: 0.375654863)
  private static let Data1992_1401 = simd_quatd(ix: -0.159812545 , iy: 0.319625089 , iz: 0.375654863 , r: 0.855092496)
  private static let Data1992_1402 = simd_quatd(ix: -0.319625089 , iy: -0.159812545 , iz: 0.375654863 , r: 0.855092496)
  private static let Data1992_1403 = simd_quatd(ix: 0.319625089 , iy: -0.159812545 , iz: 0.375654863 , r: 0.855092496)
  private static let Data1992_1404 = simd_quatd(ix: 0.319625089 , iy: 0.159812545 , iz: 0.855092496 , r: 0.375654863)
  private static let Data1992_1405 = simd_quatd(ix: -0.319625089 , iy: 0.159812545 , iz: 0.855092496 , r: 0.375654863)
  private static let Data1992_1406 = simd_quatd(ix: 0.319625089 , iy: 0.159812545 , iz: 0.375654863 , r: 0.855092496)
  private static let Data1992_1407 = simd_quatd(ix: 0.159812545 , iy: -0.319625089 , iz: 0.855092496 , r: 0.375654863)
  private static let Data1992_1408 = simd_quatd(ix: -0.159812545 , iy: -0.319625089 , iz: 0.855092496 , r: 0.375654863)
  private static let Data1992_1409 = simd_quatd(ix: -0.319625089 , iy: 0.159812545 , iz: 0.375654863 , r: 0.855092496)
  private static let Data1992_1410 = simd_quatd(ix: -0.159812545 , iy: -0.319625089 , iz: 0.375654863 , r: 0.855092496)
  private static let Data1992_1411 = simd_quatd(ix: 0.159812545 , iy: -0.319625089 , iz: 0.375654863 , r: 0.855092496)
  private static let Data1992_1412 = simd_quatd(ix: 0.000000000 , iy: 0.000000000 , iz: -0.707106781 , r: 0.707106781)
  private static let Data1992_1413 = simd_quatd(ix: 0.179160289 , iy: 0.000000000 , iz: -0.600293897 , r: 0.779454186)
  private static let Data1992_1414 = simd_quatd(ix: 0.000000000 , iy: 0.179160289 , iz: -0.600293897 , r: 0.779454186)
  private static let Data1992_1415 = simd_quatd(ix: 0.000000000 , iy: -0.179160289 , iz: -0.600293897 , r: 0.779454186)
  private static let Data1992_1416 = simd_quatd(ix: -0.179160289 , iy: 0.000000000 , iz: -0.600293897 , r: 0.779454186)
  private static let Data1992_1417 = simd_quatd(ix: -0.179160289 , iy: -0.000000000 , iz: 0.779454186 , r: -0.600293897)
  private static let Data1992_1418 = simd_quatd(ix: -0.000000000 , iy: -0.179160289 , iz: 0.779454186 , r: -0.600293897)
  private static let Data1992_1419 = simd_quatd(ix: -0.000000000 , iy: 0.179160289 , iz: 0.779454186 , r: -0.600293897)
  private static let Data1992_1420 = simd_quatd(ix: 0.179160289 , iy: -0.000000000 , iz: 0.779454186 , r: -0.600293897)
  private static let Data1992_1421 = simd_quatd(ix: 0.177739676 , iy: -0.177739676 , iz: -0.684403834 , r: 0.684403834)
  private static let Data1992_1422 = simd_quatd(ix: -0.177739676 , iy: 0.177739676 , iz: -0.684403834 , r: 0.684403834)
  private static let Data1992_1423 = simd_quatd(ix: 0.000000000 , iy: 0.000000000 , iz: -0.506664158 , r: 0.862143509)
  private static let Data1992_1424 = simd_quatd(ix: 0.177739676 , iy: 0.177739676 , iz: -0.684403834 , r: 0.684403834)
  private static let Data1992_1425 = simd_quatd(ix: -0.000000000 , iy: -0.000000000 , iz: 0.862143509 , r: -0.506664158)
  private static let Data1992_1426 = simd_quatd(ix: -0.177739676 , iy: -0.177739676 , iz: -0.684403834 , r: 0.684403834)
  private static let Data1992_1427 = simd_quatd(ix: 0.344754871 , iy: 0.000000000 , iz: -0.663756009 , r: 0.663756009)
  private static let Data1992_1428 = simd_quatd(ix: 0.000000000 , iy: 0.344754871 , iz: -0.663756009 , r: 0.663756009)
  private static let Data1992_1429 = simd_quatd(ix: 0.000000000 , iy: -0.344754871 , iz: -0.663756009 , r: 0.663756009)
  private static let Data1992_1430 = simd_quatd(ix: -0.344754871 , iy: 0.000000000 , iz: -0.663756009 , r: 0.663756009)
  private static let Data1992_1431 = simd_quatd(ix: 0.172377436 , iy: -0.172377436 , iz: -0.491378573 , r: 0.836133444)
  private static let Data1992_1432 = simd_quatd(ix: 0.172377436 , iy: 0.172377436 , iz: -0.491378573 , r: 0.836133444)
  private static let Data1992_1433 = simd_quatd(ix: -0.172377436 , iy: 0.172377436 , iz: 0.836133444 , r: -0.491378573)
  private static let Data1992_1434 = simd_quatd(ix: -0.172377436 , iy: -0.172377436 , iz: -0.491378573 , r: 0.836133444)
  private static let Data1992_1435 = simd_quatd(ix: -0.172377436 , iy: 0.172377436 , iz: -0.491378573 , r: 0.836133444)
  private static let Data1992_1436 = simd_quatd(ix: -0.172377436 , iy: -0.172377436 , iz: 0.836133444 , r: -0.491378573)
  private static let Data1992_1437 = simd_quatd(ix: 0.172377436 , iy: -0.172377436 , iz: 0.836133444 , r: -0.491378573)
  private static let Data1992_1438 = simd_quatd(ix: 0.172377436 , iy: 0.172377436 , iz: 0.836133444 , r: -0.491378573)
  private static let Data1992_1439 = simd_quatd(ix: 0.334945923 , iy: 0.000000000 , iz: -0.477397895 , r: 0.812343818)
  private static let Data1992_1440 = simd_quatd(ix: 0.000000000 , iy: 0.334945923 , iz: -0.477397895 , r: 0.812343818)
  private static let Data1992_1441 = simd_quatd(ix: 0.000000000 , iy: -0.334945923 , iz: -0.477397895 , r: 0.812343818)
  private static let Data1992_1442 = simd_quatd(ix: -0.334945923 , iy: 0.000000000 , iz: -0.477397895 , r: 0.812343818)
  private static let Data1992_1443 = simd_quatd(ix: -0.334945923 , iy: -0.000000000 , iz: 0.812343818 , r: -0.477397895)
  private static let Data1992_1444 = simd_quatd(ix: -0.000000000 , iy: -0.334945923 , iz: 0.812343818 , r: -0.477397895)
  private static let Data1992_1445 = simd_quatd(ix: -0.000000000 , iy: 0.334945923 , iz: 0.812343818 , r: -0.477397895)
  private static let Data1992_1446 = simd_quatd(ix: 0.334945923 , iy: -0.000000000 , iz: 0.812343818 , r: -0.477397895)
  private static let Data1992_1447 = simd_quatd(ix: 0.337319490 , iy: -0.168659745 , iz: -0.565110809 , r: 0.733770554)
  private static let Data1992_1448 = simd_quatd(ix: -0.168659745 , iy: 0.337319490 , iz: -0.565110809 , r: 0.733770554)
  private static let Data1992_1449 = simd_quatd(ix: 0.168659745 , iy: -0.337319490 , iz: -0.565110809 , r: 0.733770554)
  private static let Data1992_1450 = simd_quatd(ix: -0.337319490 , iy: 0.168659745 , iz: -0.565110809 , r: 0.733770554)
  private static let Data1992_1451 = simd_quatd(ix: -0.337319490 , iy: 0.168659745 , iz: 0.733770554 , r: -0.565110809)
  private static let Data1992_1452 = simd_quatd(ix: 0.168659745 , iy: -0.337319490 , iz: 0.733770554 , r: -0.565110809)
  private static let Data1992_1453 = simd_quatd(ix: -0.168659745 , iy: 0.337319490 , iz: 0.733770554 , r: -0.565110809)
  private static let Data1992_1454 = simd_quatd(ix: 0.337319490 , iy: -0.168659745 , iz: 0.733770554 , r: -0.565110809)
  private static let Data1992_1455 = simd_quatd(ix: 0.168659745 , iy: 0.000000000 , iz: -0.396451064 , r: 0.902430299)
  private static let Data1992_1456 = simd_quatd(ix: 0.337319490 , iy: 0.168659745 , iz: -0.565110809 , r: 0.733770554)
  private static let Data1992_1457 = simd_quatd(ix: -0.168659745 , iy: -0.000000000 , iz: 0.902430299 , r: -0.396451064)
  private static let Data1992_1458 = simd_quatd(ix: -0.168659745 , iy: -0.337319490 , iz: -0.565110809 , r: 0.733770554)
  private static let Data1992_1459 = simd_quatd(ix: 0.000000000 , iy: 0.168659745 , iz: -0.396451064 , r: 0.902430299)
  private static let Data1992_1460 = simd_quatd(ix: -0.337319490 , iy: -0.168659745 , iz: 0.733770554 , r: -0.565110809)
  private static let Data1992_1461 = simd_quatd(ix: -0.000000000 , iy: -0.168659745 , iz: 0.902430299 , r: -0.396451064)
  private static let Data1992_1462 = simd_quatd(ix: 0.168659745 , iy: 0.337319490 , iz: 0.733770554 , r: -0.565110809)
  private static let Data1992_1463 = simd_quatd(ix: 0.000000000 , iy: -0.168659745 , iz: -0.396451064 , r: 0.902430299)
  private static let Data1992_1464 = simd_quatd(ix: 0.168659745 , iy: 0.337319490 , iz: -0.565110809 , r: 0.733770554)
  private static let Data1992_1465 = simd_quatd(ix: -0.000000000 , iy: 0.168659745 , iz: 0.902430299 , r: -0.396451064)
  private static let Data1992_1466 = simd_quatd(ix: -0.337319490 , iy: -0.168659745 , iz: -0.565110809 , r: 0.733770554)
  private static let Data1992_1467 = simd_quatd(ix: -0.168659745 , iy: 0.000000000 , iz: -0.396451064 , r: 0.902430299)
  private static let Data1992_1468 = simd_quatd(ix: -0.168659745 , iy: -0.337319490 , iz: 0.733770554 , r: -0.565110809)
  private static let Data1992_1469 = simd_quatd(ix: 0.168659745 , iy: -0.000000000 , iz: 0.902430299 , r: -0.396451064)
  private static let Data1992_1470 = simd_quatd(ix: 0.337319490 , iy: 0.168659745 , iz: 0.733770554 , r: -0.565110809)
  private static let Data1992_1471 = simd_quatd(ix: 0.479437634 , iy: 0.000000000 , iz: -0.535467407 , r: 0.695279952)
  private static let Data1992_1472 = simd_quatd(ix: 0.000000000 , iy: 0.479437634 , iz: -0.535467407 , r: 0.695279952)
  private static let Data1992_1473 = simd_quatd(ix: 0.000000000 , iy: -0.479437634 , iz: -0.535467407 , r: 0.695279952)
  private static let Data1992_1474 = simd_quatd(ix: -0.479437634 , iy: 0.000000000 , iz: -0.535467407 , r: 0.695279952)
  private static let Data1992_1475 = simd_quatd(ix: -0.479437634 , iy: -0.000000000 , iz: 0.695279952 , r: -0.535467407)
  private static let Data1992_1476 = simd_quatd(ix: -0.000000000 , iy: -0.479437634 , iz: 0.695279952 , r: -0.535467407)
  private static let Data1992_1477 = simd_quatd(ix: -0.000000000 , iy: 0.479437634 , iz: 0.695279952 , r: -0.535467407)
  private static let Data1992_1478 = simd_quatd(ix: 0.479437634 , iy: -0.000000000 , iz: 0.695279952 , r: -0.535467407)
  private static let Data1992_1479 = simd_quatd(ix: 0.319625089 , iy: -0.159812545 , iz: -0.375654863 , r: 0.855092496)
  private static let Data1992_1480 = simd_quatd(ix: 0.319625089 , iy: 0.159812545 , iz: -0.375654863 , r: 0.855092496)
  private static let Data1992_1481 = simd_quatd(ix: -0.319625089 , iy: 0.159812545 , iz: 0.855092496 , r: -0.375654863)
  private static let Data1992_1482 = simd_quatd(ix: -0.159812545 , iy: -0.319625089 , iz: -0.375654863 , r: 0.855092496)
  private static let Data1992_1483 = simd_quatd(ix: -0.159812545 , iy: 0.319625089 , iz: -0.375654863 , r: 0.855092496)
  private static let Data1992_1484 = simd_quatd(ix: -0.319625089 , iy: -0.159812545 , iz: 0.855092496 , r: -0.375654863)
  private static let Data1992_1485 = simd_quatd(ix: 0.159812545 , iy: -0.319625089 , iz: 0.855092496 , r: -0.375654863)
  private static let Data1992_1486 = simd_quatd(ix: 0.159812545 , iy: 0.319625089 , iz: 0.855092496 , r: -0.375654863)
  private static let Data1992_1487 = simd_quatd(ix: 0.159812545 , iy: -0.319625089 , iz: -0.375654863 , r: 0.855092496)
  private static let Data1992_1488 = simd_quatd(ix: 0.159812545 , iy: 0.319625089 , iz: -0.375654863 , r: 0.855092496)
  private static let Data1992_1489 = simd_quatd(ix: -0.159812545 , iy: 0.319625089 , iz: 0.855092496 , r: -0.375654863)
  private static let Data1992_1490 = simd_quatd(ix: -0.319625089 , iy: -0.159812545 , iz: -0.375654863 , r: 0.855092496)
  private static let Data1992_1491 = simd_quatd(ix: -0.319625089 , iy: 0.159812545 , iz: -0.375654863 , r: 0.855092496)
  private static let Data1992_1492 = simd_quatd(ix: -0.159812545 , iy: -0.319625089 , iz: 0.855092496 , r: -0.375654863)
  private static let Data1992_1493 = simd_quatd(ix: 0.319625089 , iy: -0.159812545 , iz: 0.855092496 , r: -0.375654863)
  private static let Data1992_1494 = simd_quatd(ix: 0.319625089 , iy: 0.159812545 , iz: 0.855092496 , r: -0.375654863)
  private static let Data1992_1495 = simd_quatd(ix: 0.707106781 , iy: 0.707106781 , iz: 0.000000000 , r: 0.000000000)
  private static let Data1992_1496 = simd_quatd(ix: 0.779454186 , iy: 0.600293897 , iz: 0.000000000 , r: -0.179160289)
  private static let Data1992_1497 = simd_quatd(ix: 0.779454186 , iy: 0.600293897 , iz: 0.179160289 , r: 0.000000000)
  private static let Data1992_1498 = simd_quatd(ix: 0.779454186 , iy: 0.600293897 , iz: -0.179160289 , r: 0.000000000)
  private static let Data1992_1499 = simd_quatd(ix: 0.779454186 , iy: 0.600293897 , iz: 0.000000000 , r: 0.179160289)
  private static let Data1992_1500 = simd_quatd(ix: 0.600293897 , iy: 0.779454186 , iz: 0.000000000 , r: -0.179160289)
  private static let Data1992_1501 = simd_quatd(ix: 0.600293897 , iy: 0.779454186 , iz: 0.179160289 , r: 0.000000000)
  private static let Data1992_1502 = simd_quatd(ix: 0.600293897 , iy: 0.779454186 , iz: -0.179160289 , r: 0.000000000)
  private static let Data1992_1503 = simd_quatd(ix: 0.600293897 , iy: 0.779454186 , iz: 0.000000000 , r: 0.179160289)
  private static let Data1992_1504 = simd_quatd(ix: 0.684403834 , iy: 0.684403834 , iz: -0.177739676 , r: -0.177739676)
  private static let Data1992_1505 = simd_quatd(ix: 0.684403834 , iy: 0.684403834 , iz: 0.177739676 , r: 0.177739676)
  private static let Data1992_1506 = simd_quatd(ix: 0.862143509 , iy: 0.506664158 , iz: 0.000000000 , r: 0.000000000)
  private static let Data1992_1507 = simd_quatd(ix: 0.684403834 , iy: 0.684403834 , iz: 0.177739676 , r: -0.177739676)
  private static let Data1992_1508 = simd_quatd(ix: 0.506664158 , iy: 0.862143509 , iz: 0.000000000 , r: 0.000000000)
  private static let Data1992_1509 = simd_quatd(ix: 0.684403834 , iy: 0.684403834 , iz: -0.177739676 , r: 0.177739676)
  private static let Data1992_1510 = simd_quatd(ix: 0.663756009 , iy: 0.663756009 , iz: 0.000000000 , r: -0.344754871)
  private static let Data1992_1511 = simd_quatd(ix: 0.663756009 , iy: 0.663756009 , iz: 0.344754871 , r: 0.000000000)
  private static let Data1992_1512 = simd_quatd(ix: 0.663756009 , iy: 0.663756009 , iz: -0.344754871 , r: 0.000000000)
  private static let Data1992_1513 = simd_quatd(ix: 0.663756009 , iy: 0.663756009 , iz: 0.000000000 , r: 0.344754871)
  private static let Data1992_1514 = simd_quatd(ix: 0.836133444 , iy: 0.491378573 , iz: -0.172377436 , r: -0.172377436)
  private static let Data1992_1515 = simd_quatd(ix: 0.836133444 , iy: 0.491378573 , iz: 0.172377436 , r: -0.172377436)
  private static let Data1992_1516 = simd_quatd(ix: 0.491378573 , iy: 0.836133444 , iz: -0.172377436 , r: -0.172377436)
  private static let Data1992_1517 = simd_quatd(ix: 0.836133444 , iy: 0.491378573 , iz: -0.172377436 , r: 0.172377436)
  private static let Data1992_1518 = simd_quatd(ix: 0.836133444 , iy: 0.491378573 , iz: 0.172377436 , r: 0.172377436)
  private static let Data1992_1519 = simd_quatd(ix: 0.491378573 , iy: 0.836133444 , iz: 0.172377436 , r: -0.172377436)
  private static let Data1992_1520 = simd_quatd(ix: 0.491378573 , iy: 0.836133444 , iz: 0.172377436 , r: 0.172377436)
  private static let Data1992_1521 = simd_quatd(ix: 0.491378573 , iy: 0.836133444 , iz: -0.172377436 , r: 0.172377436)
  private static let Data1992_1522 = simd_quatd(ix: 0.812343818 , iy: 0.477397895 , iz: 0.000000000 , r: -0.334945923)
  private static let Data1992_1523 = simd_quatd(ix: 0.812343818 , iy: 0.477397895 , iz: 0.334945923 , r: 0.000000000)
  private static let Data1992_1524 = simd_quatd(ix: 0.812343818 , iy: 0.477397895 , iz: -0.334945923 , r: 0.000000000)
  private static let Data1992_1525 = simd_quatd(ix: 0.812343818 , iy: 0.477397895 , iz: 0.000000000 , r: 0.334945923)
  private static let Data1992_1526 = simd_quatd(ix: 0.477397895 , iy: 0.812343818 , iz: 0.000000000 , r: -0.334945923)
  private static let Data1992_1527 = simd_quatd(ix: 0.477397895 , iy: 0.812343818 , iz: 0.334945923 , r: 0.000000000)
  private static let Data1992_1528 = simd_quatd(ix: 0.477397895 , iy: 0.812343818 , iz: -0.334945923 , r: 0.000000000)
  private static let Data1992_1529 = simd_quatd(ix: 0.477397895 , iy: 0.812343818 , iz: 0.000000000 , r: 0.334945923)
  private static let Data1992_1530 = simd_quatd(ix: 0.733770554 , iy: 0.565110809 , iz: -0.168659745 , r: -0.337319490)
  private static let Data1992_1531 = simd_quatd(ix: 0.733770554 , iy: 0.565110809 , iz: 0.337319490 , r: 0.168659745)
  private static let Data1992_1532 = simd_quatd(ix: 0.733770554 , iy: 0.565110809 , iz: -0.337319490 , r: -0.168659745)
  private static let Data1992_1533 = simd_quatd(ix: 0.733770554 , iy: 0.565110809 , iz: 0.168659745 , r: 0.337319490)
  private static let Data1992_1534 = simd_quatd(ix: 0.565110809 , iy: 0.733770554 , iz: -0.168659745 , r: -0.337319490)
  private static let Data1992_1535 = simd_quatd(ix: 0.565110809 , iy: 0.733770554 , iz: 0.337319490 , r: 0.168659745)
  private static let Data1992_1536 = simd_quatd(ix: 0.565110809 , iy: 0.733770554 , iz: -0.337319490 , r: -0.168659745)
  private static let Data1992_1537 = simd_quatd(ix: 0.565110809 , iy: 0.733770554 , iz: 0.168659745 , r: 0.337319490)
  private static let Data1992_1538 = simd_quatd(ix: 0.902430299 , iy: 0.396451064 , iz: 0.000000000 , r: -0.168659745)
  private static let Data1992_1539 = simd_quatd(ix: 0.733770554 , iy: 0.565110809 , iz: 0.168659745 , r: -0.337319490)
  private static let Data1992_1540 = simd_quatd(ix: 0.396451064 , iy: 0.902430299 , iz: 0.000000000 , r: -0.168659745)
  private static let Data1992_1541 = simd_quatd(ix: 0.733770554 , iy: 0.565110809 , iz: -0.337319490 , r: 0.168659745)
  private static let Data1992_1542 = simd_quatd(ix: 0.902430299 , iy: 0.396451064 , iz: 0.168659745 , r: 0.000000000)
  private static let Data1992_1543 = simd_quatd(ix: 0.565110809 , iy: 0.733770554 , iz: 0.168659745 , r: -0.337319490)
  private static let Data1992_1544 = simd_quatd(ix: 0.396451064 , iy: 0.902430299 , iz: 0.168659745 , r: 0.000000000)
  private static let Data1992_1545 = simd_quatd(ix: 0.565110809 , iy: 0.733770554 , iz: -0.337319490 , r: 0.168659745)
  private static let Data1992_1546 = simd_quatd(ix: 0.902430299 , iy: 0.396451064 , iz: -0.168659745 , r: 0.000000000)
  private static let Data1992_1547 = simd_quatd(ix: 0.733770554 , iy: 0.565110809 , iz: 0.337319490 , r: -0.168659745)
  private static let Data1992_1548 = simd_quatd(ix: 0.396451064 , iy: 0.902430299 , iz: -0.168659745 , r: 0.000000000)
  private static let Data1992_1549 = simd_quatd(ix: 0.733770554 , iy: 0.565110809 , iz: -0.168659745 , r: 0.337319490)
  private static let Data1992_1550 = simd_quatd(ix: 0.902430299 , iy: 0.396451064 , iz: 0.000000000 , r: 0.168659745)
  private static let Data1992_1551 = simd_quatd(ix: 0.565110809 , iy: 0.733770554 , iz: 0.337319490 , r: -0.168659745)
  private static let Data1992_1552 = simd_quatd(ix: 0.396451064 , iy: 0.902430299 , iz: 0.000000000 , r: 0.168659745)
  private static let Data1992_1553 = simd_quatd(ix: 0.565110809 , iy: 0.733770554 , iz: -0.168659745 , r: 0.337319490)
  private static let Data1992_1554 = simd_quatd(ix: 0.695279952 , iy: 0.535467407 , iz: 0.000000000 , r: -0.479437634)
  private static let Data1992_1555 = simd_quatd(ix: 0.695279952 , iy: 0.535467407 , iz: 0.479437634 , r: 0.000000000)
  private static let Data1992_1556 = simd_quatd(ix: 0.695279952 , iy: 0.535467407 , iz: -0.479437634 , r: 0.000000000)
  private static let Data1992_1557 = simd_quatd(ix: 0.695279952 , iy: 0.535467407 , iz: 0.000000000 , r: 0.479437634)
  private static let Data1992_1558 = simd_quatd(ix: 0.535467407 , iy: 0.695279952 , iz: 0.000000000 , r: -0.479437634)
  private static let Data1992_1559 = simd_quatd(ix: 0.535467407 , iy: 0.695279952 , iz: 0.479437634 , r: 0.000000000)
  private static let Data1992_1560 = simd_quatd(ix: 0.535467407 , iy: 0.695279952 , iz: -0.479437634 , r: 0.000000000)
  private static let Data1992_1561 = simd_quatd(ix: 0.535467407 , iy: 0.695279952 , iz: 0.000000000 , r: 0.479437634)
  private static let Data1992_1562 = simd_quatd(ix: 0.855092496 , iy: 0.375654863 , iz: -0.159812545 , r: -0.319625089)
  private static let Data1992_1563 = simd_quatd(ix: 0.855092496 , iy: 0.375654863 , iz: 0.159812545 , r: -0.319625089)
  private static let Data1992_1564 = simd_quatd(ix: 0.375654863 , iy: 0.855092496 , iz: -0.159812545 , r: -0.319625089)
  private static let Data1992_1565 = simd_quatd(ix: 0.855092496 , iy: 0.375654863 , iz: -0.319625089 , r: 0.159812545)
  private static let Data1992_1566 = simd_quatd(ix: 0.855092496 , iy: 0.375654863 , iz: 0.319625089 , r: 0.159812545)
  private static let Data1992_1567 = simd_quatd(ix: 0.375654863 , iy: 0.855092496 , iz: 0.159812545 , r: -0.319625089)
  private static let Data1992_1568 = simd_quatd(ix: 0.375654863 , iy: 0.855092496 , iz: 0.319625089 , r: 0.159812545)
  private static let Data1992_1569 = simd_quatd(ix: 0.375654863 , iy: 0.855092496 , iz: -0.319625089 , r: 0.159812545)
  private static let Data1992_1570 = simd_quatd(ix: 0.855092496 , iy: 0.375654863 , iz: -0.319625089 , r: -0.159812545)
  private static let Data1992_1571 = simd_quatd(ix: 0.855092496 , iy: 0.375654863 , iz: 0.319625089 , r: -0.159812545)
  private static let Data1992_1572 = simd_quatd(ix: 0.375654863 , iy: 0.855092496 , iz: -0.319625089 , r: -0.159812545)
  private static let Data1992_1573 = simd_quatd(ix: 0.855092496 , iy: 0.375654863 , iz: -0.159812545 , r: 0.319625089)
  private static let Data1992_1574 = simd_quatd(ix: 0.855092496 , iy: 0.375654863 , iz: 0.159812545 , r: 0.319625089)
  private static let Data1992_1575 = simd_quatd(ix: 0.375654863 , iy: 0.855092496 , iz: 0.319625089 , r: -0.159812545)
  private static let Data1992_1576 = simd_quatd(ix: 0.375654863 , iy: 0.855092496 , iz: 0.159812545 , r: 0.319625089)
  private static let Data1992_1577 = simd_quatd(ix: 0.375654863 , iy: 0.855092496 , iz: -0.159812545 , r: 0.319625089)
  private static let Data1992_1578 = simd_quatd(ix: 0.707106781 , iy: -0.707106781 , iz: 0.000000000 , r: 0.000000000)
  private static let Data1992_1579 = simd_quatd(ix: -0.600293897 , iy: 0.779454186 , iz: -0.179160289 , r: -0.000000000)
  private static let Data1992_1580 = simd_quatd(ix: -0.600293897 , iy: 0.779454186 , iz: -0.000000000 , r: -0.179160289)
  private static let Data1992_1581 = simd_quatd(ix: -0.600293897 , iy: 0.779454186 , iz: -0.000000000 , r: 0.179160289)
  private static let Data1992_1582 = simd_quatd(ix: -0.600293897 , iy: 0.779454186 , iz: 0.179160289 , r: -0.000000000)
  private static let Data1992_1583 = simd_quatd(ix: 0.779454186 , iy: -0.600293897 , iz: 0.179160289 , r: 0.000000000)
  private static let Data1992_1584 = simd_quatd(ix: 0.779454186 , iy: -0.600293897 , iz: 0.000000000 , r: 0.179160289)
  private static let Data1992_1585 = simd_quatd(ix: 0.779454186 , iy: -0.600293897 , iz: 0.000000000 , r: -0.179160289)
  private static let Data1992_1586 = simd_quatd(ix: 0.779454186 , iy: -0.600293897 , iz: -0.179160289 , r: 0.000000000)
  private static let Data1992_1587 = simd_quatd(ix: 0.684403834 , iy: -0.684403834 , iz: 0.177739676 , r: -0.177739676)
  private static let Data1992_1588 = simd_quatd(ix: 0.684403834 , iy: -0.684403834 , iz: -0.177739676 , r: 0.177739676)
  private static let Data1992_1589 = simd_quatd(ix: -0.506664158 , iy: 0.862143509 , iz: -0.000000000 , r: -0.000000000)
  private static let Data1992_1590 = simd_quatd(ix: 0.684403834 , iy: -0.684403834 , iz: 0.177739676 , r: 0.177739676)
  private static let Data1992_1591 = simd_quatd(ix: 0.862143509 , iy: -0.506664158 , iz: 0.000000000 , r: 0.000000000)
  private static let Data1992_1592 = simd_quatd(ix: 0.684403834 , iy: -0.684403834 , iz: -0.177739676 , r: -0.177739676)
  private static let Data1992_1593 = simd_quatd(ix: 0.663756009 , iy: -0.663756009 , iz: 0.344754871 , r: 0.000000000)
  private static let Data1992_1594 = simd_quatd(ix: 0.663756009 , iy: -0.663756009 , iz: 0.000000000 , r: 0.344754871)
  private static let Data1992_1595 = simd_quatd(ix: 0.663756009 , iy: -0.663756009 , iz: 0.000000000 , r: -0.344754871)
  private static let Data1992_1596 = simd_quatd(ix: 0.663756009 , iy: -0.663756009 , iz: -0.344754871 , r: 0.000000000)
  private static let Data1992_1597 = simd_quatd(ix: -0.491378573 , iy: 0.836133444 , iz: -0.172377436 , r: 0.172377436)
  private static let Data1992_1598 = simd_quatd(ix: -0.491378573 , iy: 0.836133444 , iz: -0.172377436 , r: -0.172377436)
  private static let Data1992_1599 = simd_quatd(ix: 0.836133444 , iy: -0.491378573 , iz: 0.172377436 , r: -0.172377436)
  private static let Data1992_1600 = simd_quatd(ix: -0.491378573 , iy: 0.836133444 , iz: 0.172377436 , r: 0.172377436)
  private static let Data1992_1601 = simd_quatd(ix: -0.491378573 , iy: 0.836133444 , iz: 0.172377436 , r: -0.172377436)
  private static let Data1992_1602 = simd_quatd(ix: 0.836133444 , iy: -0.491378573 , iz: 0.172377436 , r: 0.172377436)
  private static let Data1992_1603 = simd_quatd(ix: 0.836133444 , iy: -0.491378573 , iz: -0.172377436 , r: 0.172377436)
  private static let Data1992_1604 = simd_quatd(ix: 0.836133444 , iy: -0.491378573 , iz: -0.172377436 , r: -0.172377436)
  private static let Data1992_1605 = simd_quatd(ix: -0.477397895 , iy: 0.812343818 , iz: -0.334945923 , r: -0.000000000)
  private static let Data1992_1606 = simd_quatd(ix: -0.477397895 , iy: 0.812343818 , iz: -0.000000000 , r: -0.334945923)
  private static let Data1992_1607 = simd_quatd(ix: -0.477397895 , iy: 0.812343818 , iz: -0.000000000 , r: 0.334945923)
  private static let Data1992_1608 = simd_quatd(ix: -0.477397895 , iy: 0.812343818 , iz: 0.334945923 , r: -0.000000000)
  private static let Data1992_1609 = simd_quatd(ix: 0.812343818 , iy: -0.477397895 , iz: 0.334945923 , r: 0.000000000)
  private static let Data1992_1610 = simd_quatd(ix: 0.812343818 , iy: -0.477397895 , iz: 0.000000000 , r: 0.334945923)
  private static let Data1992_1611 = simd_quatd(ix: 0.812343818 , iy: -0.477397895 , iz: 0.000000000 , r: -0.334945923)
  private static let Data1992_1612 = simd_quatd(ix: 0.812343818 , iy: -0.477397895 , iz: -0.334945923 , r: 0.000000000)
  private static let Data1992_1613 = simd_quatd(ix: -0.565110809 , iy: 0.733770554 , iz: -0.337319490 , r: 0.168659745)
  private static let Data1992_1614 = simd_quatd(ix: -0.565110809 , iy: 0.733770554 , iz: 0.168659745 , r: -0.337319490)
  private static let Data1992_1615 = simd_quatd(ix: -0.565110809 , iy: 0.733770554 , iz: -0.168659745 , r: 0.337319490)
  private static let Data1992_1616 = simd_quatd(ix: -0.565110809 , iy: 0.733770554 , iz: 0.337319490 , r: -0.168659745)
  private static let Data1992_1617 = simd_quatd(ix: 0.733770554 , iy: -0.565110809 , iz: 0.337319490 , r: -0.168659745)
  private static let Data1992_1618 = simd_quatd(ix: 0.733770554 , iy: -0.565110809 , iz: -0.168659745 , r: 0.337319490)
  private static let Data1992_1619 = simd_quatd(ix: 0.733770554 , iy: -0.565110809 , iz: 0.168659745 , r: -0.337319490)
  private static let Data1992_1620 = simd_quatd(ix: 0.733770554 , iy: -0.565110809 , iz: -0.337319490 , r: 0.168659745)
  private static let Data1992_1621 = simd_quatd(ix: -0.396451064 , iy: 0.902430299 , iz: -0.168659745 , r: -0.000000000)
  private static let Data1992_1622 = simd_quatd(ix: -0.565110809 , iy: 0.733770554 , iz: -0.337319490 , r: -0.168659745)
  private static let Data1992_1623 = simd_quatd(ix: 0.902430299 , iy: -0.396451064 , iz: 0.168659745 , r: 0.000000000)
  private static let Data1992_1624 = simd_quatd(ix: -0.565110809 , iy: 0.733770554 , iz: 0.168659745 , r: 0.337319490)
  private static let Data1992_1625 = simd_quatd(ix: -0.396451064 , iy: 0.902430299 , iz: -0.000000000 , r: -0.168659745)
  private static let Data1992_1626 = simd_quatd(ix: 0.733770554 , iy: -0.565110809 , iz: 0.337319490 , r: 0.168659745)
  private static let Data1992_1627 = simd_quatd(ix: 0.902430299 , iy: -0.396451064 , iz: 0.000000000 , r: 0.168659745)
  private static let Data1992_1628 = simd_quatd(ix: 0.733770554 , iy: -0.565110809 , iz: -0.168659745 , r: -0.337319490)
  private static let Data1992_1629 = simd_quatd(ix: -0.396451064 , iy: 0.902430299 , iz: -0.000000000 , r: 0.168659745)
  private static let Data1992_1630 = simd_quatd(ix: -0.565110809 , iy: 0.733770554 , iz: -0.168659745 , r: -0.337319490)
  private static let Data1992_1631 = simd_quatd(ix: 0.902430299 , iy: -0.396451064 , iz: 0.000000000 , r: -0.168659745)
  private static let Data1992_1632 = simd_quatd(ix: -0.565110809 , iy: 0.733770554 , iz: 0.337319490 , r: 0.168659745)
  private static let Data1992_1633 = simd_quatd(ix: -0.396451064 , iy: 0.902430299 , iz: 0.168659745 , r: -0.000000000)
  private static let Data1992_1634 = simd_quatd(ix: 0.733770554 , iy: -0.565110809 , iz: 0.168659745 , r: 0.337319490)
  private static let Data1992_1635 = simd_quatd(ix: 0.902430299 , iy: -0.396451064 , iz: -0.168659745 , r: 0.000000000)
  private static let Data1992_1636 = simd_quatd(ix: 0.733770554 , iy: -0.565110809 , iz: -0.337319490 , r: -0.168659745)
  private static let Data1992_1637 = simd_quatd(ix: -0.535467407 , iy: 0.695279952 , iz: -0.479437634 , r: -0.000000000)
  private static let Data1992_1638 = simd_quatd(ix: -0.535467407 , iy: 0.695279952 , iz: -0.000000000 , r: -0.479437634)
  private static let Data1992_1639 = simd_quatd(ix: -0.535467407 , iy: 0.695279952 , iz: -0.000000000 , r: 0.479437634)
  private static let Data1992_1640 = simd_quatd(ix: -0.535467407 , iy: 0.695279952 , iz: 0.479437634 , r: -0.000000000)
  private static let Data1992_1641 = simd_quatd(ix: 0.695279952 , iy: -0.535467407 , iz: 0.479437634 , r: 0.000000000)
  private static let Data1992_1642 = simd_quatd(ix: 0.695279952 , iy: -0.535467407 , iz: 0.000000000 , r: 0.479437634)
  private static let Data1992_1643 = simd_quatd(ix: 0.695279952 , iy: -0.535467407 , iz: 0.000000000 , r: -0.479437634)
  private static let Data1992_1644 = simd_quatd(ix: 0.695279952 , iy: -0.535467407 , iz: -0.479437634 , r: 0.000000000)
  private static let Data1992_1645 = simd_quatd(ix: -0.375654863 , iy: 0.855092496 , iz: -0.319625089 , r: 0.159812545)
  private static let Data1992_1646 = simd_quatd(ix: -0.375654863 , iy: 0.855092496 , iz: -0.319625089 , r: -0.159812545)
  private static let Data1992_1647 = simd_quatd(ix: 0.855092496 , iy: -0.375654863 , iz: 0.319625089 , r: -0.159812545)
  private static let Data1992_1648 = simd_quatd(ix: -0.375654863 , iy: 0.855092496 , iz: 0.159812545 , r: 0.319625089)
  private static let Data1992_1649 = simd_quatd(ix: -0.375654863 , iy: 0.855092496 , iz: 0.159812545 , r: -0.319625089)
  private static let Data1992_1650 = simd_quatd(ix: 0.855092496 , iy: -0.375654863 , iz: 0.319625089 , r: 0.159812545)
  private static let Data1992_1651 = simd_quatd(ix: 0.855092496 , iy: -0.375654863 , iz: -0.159812545 , r: 0.319625089)
  private static let Data1992_1652 = simd_quatd(ix: 0.855092496 , iy: -0.375654863 , iz: -0.159812545 , r: -0.319625089)
  private static let Data1992_1653 = simd_quatd(ix: -0.375654863 , iy: 0.855092496 , iz: -0.159812545 , r: 0.319625089)
  private static let Data1992_1654 = simd_quatd(ix: -0.375654863 , iy: 0.855092496 , iz: -0.159812545 , r: -0.319625089)
  private static let Data1992_1655 = simd_quatd(ix: 0.855092496 , iy: -0.375654863 , iz: 0.159812545 , r: -0.319625089)
  private static let Data1992_1656 = simd_quatd(ix: -0.375654863 , iy: 0.855092496 , iz: 0.319625089 , r: 0.159812545)
  private static let Data1992_1657 = simd_quatd(ix: -0.375654863 , iy: 0.855092496 , iz: 0.319625089 , r: -0.159812545)
  private static let Data1992_1658 = simd_quatd(ix: 0.855092496 , iy: -0.375654863 , iz: 0.159812545 , r: 0.319625089)
  private static let Data1992_1659 = simd_quatd(ix: 0.855092496 , iy: -0.375654863 , iz: -0.319625089 , r: 0.159812545)
  private static let Data1992_1660 = simd_quatd(ix: 0.855092496 , iy: -0.375654863 , iz: -0.319625089 , r: -0.159812545)
  private static let Data1992_1661 = simd_quatd(ix: 0.707106781 , iy: 0.000000000 , iz: 0.707106781 , r: 0.000000000)
  private static let Data1992_1662 = simd_quatd(ix: 0.600293897 , iy: 0.000000000 , iz: 0.779454186 , r: -0.179160289)
  private static let Data1992_1663 = simd_quatd(ix: 0.600293897 , iy: -0.179160289 , iz: 0.779454186 , r: 0.000000000)
  private static let Data1992_1664 = simd_quatd(ix: 0.779454186 , iy: 0.000000000 , iz: 0.600293897 , r: -0.179160289)
  private static let Data1992_1665 = simd_quatd(ix: 0.779454186 , iy: -0.179160289 , iz: 0.600293897 , r: 0.000000000)
  private static let Data1992_1666 = simd_quatd(ix: 0.600293897 , iy: 0.179160289 , iz: 0.779454186 , r: 0.000000000)
  private static let Data1992_1667 = simd_quatd(ix: 0.600293897 , iy: 0.000000000 , iz: 0.779454186 , r: 0.179160289)
  private static let Data1992_1668 = simd_quatd(ix: 0.779454186 , iy: 0.179160289 , iz: 0.600293897 , r: 0.000000000)
  private static let Data1992_1669 = simd_quatd(ix: 0.779454186 , iy: 0.000000000 , iz: 0.600293897 , r: 0.179160289)
  private static let Data1992_1670 = simd_quatd(ix: 0.684403834 , iy: 0.177739676 , iz: 0.684403834 , r: -0.177739676)
  private static let Data1992_1671 = simd_quatd(ix: 0.684403834 , iy: -0.177739676 , iz: 0.684403834 , r: 0.177739676)
  private static let Data1992_1672 = simd_quatd(ix: 0.684403834 , iy: -0.177739676 , iz: 0.684403834 , r: -0.177739676)
  private static let Data1992_1673 = simd_quatd(ix: 0.506664158 , iy: 0.000000000 , iz: 0.862143509 , r: 0.000000000)
  private static let Data1992_1674 = simd_quatd(ix: 0.684403834 , iy: 0.177739676 , iz: 0.684403834 , r: 0.177739676)
  private static let Data1992_1675 = simd_quatd(ix: 0.862143509 , iy: 0.000000000 , iz: 0.506664158 , r: 0.000000000)
  private static let Data1992_1676 = simd_quatd(ix: 0.491378573 , iy: 0.172377436 , iz: 0.836133444 , r: -0.172377436)
  private static let Data1992_1677 = simd_quatd(ix: 0.491378573 , iy: -0.172377436 , iz: 0.836133444 , r: 0.172377436)
  private static let Data1992_1678 = simd_quatd(ix: 0.836133444 , iy: 0.172377436 , iz: 0.491378573 , r: -0.172377436)
  private static let Data1992_1679 = simd_quatd(ix: 0.836133444 , iy: -0.172377436 , iz: 0.491378573 , r: 0.172377436)
  private static let Data1992_1680 = simd_quatd(ix: 0.663756009 , iy: 0.000000000 , iz: 0.663756009 , r: -0.344754871)
  private static let Data1992_1681 = simd_quatd(ix: 0.491378573 , iy: -0.172377436 , iz: 0.836133444 , r: -0.172377436)
  private static let Data1992_1682 = simd_quatd(ix: 0.663756009 , iy: 0.344754871 , iz: 0.663756009 , r: 0.000000000)
  private static let Data1992_1683 = simd_quatd(ix: 0.836133444 , iy: -0.172377436 , iz: 0.491378573 , r: -0.172377436)
  private static let Data1992_1684 = simd_quatd(ix: 0.663756009 , iy: -0.344754871 , iz: 0.663756009 , r: 0.000000000)
  private static let Data1992_1685 = simd_quatd(ix: 0.491378573 , iy: 0.172377436 , iz: 0.836133444 , r: 0.172377436)
  private static let Data1992_1686 = simd_quatd(ix: 0.663756009 , iy: 0.000000000 , iz: 0.663756009 , r: 0.344754871)
  private static let Data1992_1687 = simd_quatd(ix: 0.836133444 , iy: 0.172377436 , iz: 0.491378573 , r: 0.172377436)
  private static let Data1992_1688 = simd_quatd(ix: 0.477397895 , iy: 0.000000000 , iz: 0.812343818 , r: -0.334945923)
  private static let Data1992_1689 = simd_quatd(ix: 0.477397895 , iy: -0.334945923 , iz: 0.812343818 , r: 0.000000000)
  private static let Data1992_1690 = simd_quatd(ix: 0.812343818 , iy: 0.000000000 , iz: 0.477397895 , r: -0.334945923)
  private static let Data1992_1691 = simd_quatd(ix: 0.812343818 , iy: -0.334945923 , iz: 0.477397895 , r: 0.000000000)
  private static let Data1992_1692 = simd_quatd(ix: 0.477397895 , iy: 0.334945923 , iz: 0.812343818 , r: 0.000000000)
  private static let Data1992_1693 = simd_quatd(ix: 0.477397895 , iy: 0.000000000 , iz: 0.812343818 , r: 0.334945923)
  private static let Data1992_1694 = simd_quatd(ix: 0.812343818 , iy: 0.334945923 , iz: 0.477397895 , r: 0.000000000)
  private static let Data1992_1695 = simd_quatd(ix: 0.812343818 , iy: 0.000000000 , iz: 0.477397895 , r: 0.334945923)
  private static let Data1992_1696 = simd_quatd(ix: 0.565110809 , iy: 0.168659745 , iz: 0.733770554 , r: -0.337319490)
  private static let Data1992_1697 = simd_quatd(ix: 0.565110809 , iy: -0.337319490 , iz: 0.733770554 , r: 0.168659745)
  private static let Data1992_1698 = simd_quatd(ix: 0.733770554 , iy: 0.168659745 , iz: 0.565110809 , r: -0.337319490)
  private static let Data1992_1699 = simd_quatd(ix: 0.733770554 , iy: -0.337319490 , iz: 0.565110809 , r: 0.168659745)
  private static let Data1992_1700 = simd_quatd(ix: 0.565110809 , iy: 0.337319490 , iz: 0.733770554 , r: -0.168659745)
  private static let Data1992_1701 = simd_quatd(ix: 0.565110809 , iy: -0.168659745 , iz: 0.733770554 , r: 0.337319490)
  private static let Data1992_1702 = simd_quatd(ix: 0.733770554 , iy: 0.337319490 , iz: 0.565110809 , r: -0.168659745)
  private static let Data1992_1703 = simd_quatd(ix: 0.733770554 , iy: -0.168659745 , iz: 0.565110809 , r: 0.337319490)
  private static let Data1992_1704 = simd_quatd(ix: 0.565110809 , iy: -0.168659745 , iz: 0.733770554 , r: -0.337319490)
  private static let Data1992_1705 = simd_quatd(ix: 0.396451064 , iy: 0.000000000 , iz: 0.902430299 , r: -0.168659745)
  private static let Data1992_1706 = simd_quatd(ix: 0.565110809 , iy: 0.337319490 , iz: 0.733770554 , r: 0.168659745)
  private static let Data1992_1707 = simd_quatd(ix: 0.902430299 , iy: 0.000000000 , iz: 0.396451064 , r: -0.168659745)
  private static let Data1992_1708 = simd_quatd(ix: 0.565110809 , iy: -0.337319490 , iz: 0.733770554 , r: -0.168659745)
  private static let Data1992_1709 = simd_quatd(ix: 0.396451064 , iy: 0.168659745 , iz: 0.902430299 , r: 0.000000000)
  private static let Data1992_1710 = simd_quatd(ix: 0.565110809 , iy: 0.168659745 , iz: 0.733770554 , r: 0.337319490)
  private static let Data1992_1711 = simd_quatd(ix: 0.902430299 , iy: 0.168659745 , iz: 0.396451064 , r: 0.000000000)
  private static let Data1992_1712 = simd_quatd(ix: 0.733770554 , iy: -0.168659745 , iz: 0.565110809 , r: -0.337319490)
  private static let Data1992_1713 = simd_quatd(ix: 0.396451064 , iy: -0.168659745 , iz: 0.902430299 , r: 0.000000000)
  private static let Data1992_1714 = simd_quatd(ix: 0.733770554 , iy: 0.337319490 , iz: 0.565110809 , r: 0.168659745)
  private static let Data1992_1715 = simd_quatd(ix: 0.902430299 , iy: -0.168659745 , iz: 0.396451064 , r: 0.000000000)
  private static let Data1992_1716 = simd_quatd(ix: 0.733770554 , iy: -0.337319490 , iz: 0.565110809 , r: -0.168659745)
  private static let Data1992_1717 = simd_quatd(ix: 0.396451064 , iy: 0.000000000 , iz: 0.902430299 , r: 0.168659745)
  private static let Data1992_1718 = simd_quatd(ix: 0.733770554 , iy: 0.168659745 , iz: 0.565110809 , r: 0.337319490)
  private static let Data1992_1719 = simd_quatd(ix: 0.902430299 , iy: 0.000000000 , iz: 0.396451064 , r: 0.168659745)
  private static let Data1992_1720 = simd_quatd(ix: 0.375654863 , iy: 0.159812545 , iz: 0.855092496 , r: -0.319625089)
  private static let Data1992_1721 = simd_quatd(ix: 0.375654863 , iy: -0.319625089 , iz: 0.855092496 , r: 0.159812545)
  private static let Data1992_1722 = simd_quatd(ix: 0.855092496 , iy: 0.159812545 , iz: 0.375654863 , r: -0.319625089)
  private static let Data1992_1723 = simd_quatd(ix: 0.855092496 , iy: -0.319625089 , iz: 0.375654863 , r: 0.159812545)
  private static let Data1992_1724 = simd_quatd(ix: 0.375654863 , iy: 0.319625089 , iz: 0.855092496 , r: -0.159812545)
  private static let Data1992_1725 = simd_quatd(ix: 0.375654863 , iy: -0.159812545 , iz: 0.855092496 , r: 0.319625089)
  private static let Data1992_1726 = simd_quatd(ix: 0.855092496 , iy: 0.319625089 , iz: 0.375654863 , r: -0.159812545)
  private static let Data1992_1727 = simd_quatd(ix: 0.855092496 , iy: -0.159812545 , iz: 0.375654863 , r: 0.319625089)
  private static let Data1992_1728 = simd_quatd(ix: 0.535467407 , iy: 0.000000000 , iz: 0.695279952 , r: -0.479437634)
  private static let Data1992_1729 = simd_quatd(ix: 0.375654863 , iy: -0.159812545 , iz: 0.855092496 , r: -0.319625089)
  private static let Data1992_1730 = simd_quatd(ix: 0.535467407 , iy: 0.479437634 , iz: 0.695279952 , r: 0.000000000)
  private static let Data1992_1731 = simd_quatd(ix: 0.855092496 , iy: -0.159812545 , iz: 0.375654863 , r: -0.319625089)
  private static let Data1992_1732 = simd_quatd(ix: 0.535467407 , iy: -0.479437634 , iz: 0.695279952 , r: 0.000000000)
  private static let Data1992_1733 = simd_quatd(ix: 0.375654863 , iy: 0.319625089 , iz: 0.855092496 , r: 0.159812545)
  private static let Data1992_1734 = simd_quatd(ix: 0.535467407 , iy: 0.000000000 , iz: 0.695279952 , r: 0.479437634)
  private static let Data1992_1735 = simd_quatd(ix: 0.855092496 , iy: 0.319625089 , iz: 0.375654863 , r: 0.159812545)
  private static let Data1992_1736 = simd_quatd(ix: 0.695279952 , iy: 0.000000000 , iz: 0.535467407 , r: -0.479437634)
  private static let Data1992_1737 = simd_quatd(ix: 0.375654863 , iy: -0.319625089 , iz: 0.855092496 , r: -0.159812545)
  private static let Data1992_1738 = simd_quatd(ix: 0.695279952 , iy: 0.479437634 , iz: 0.535467407 , r: 0.000000000)
  private static let Data1992_1739 = simd_quatd(ix: 0.855092496 , iy: -0.319625089 , iz: 0.375654863 , r: -0.159812545)
  private static let Data1992_1740 = simd_quatd(ix: 0.695279952 , iy: -0.479437634 , iz: 0.535467407 , r: 0.000000000)
  private static let Data1992_1741 = simd_quatd(ix: 0.375654863 , iy: 0.159812545 , iz: 0.855092496 , r: 0.319625089)
  private static let Data1992_1742 = simd_quatd(ix: 0.695279952 , iy: 0.000000000 , iz: 0.535467407 , r: 0.479437634)
  private static let Data1992_1743 = simd_quatd(ix: 0.855092496 , iy: 0.159812545 , iz: 0.375654863 , r: 0.319625089)
  private static let Data1992_1744 = simd_quatd(ix: 0.707106781 , iy: 0.000000000 , iz: -0.707106781 , r: 0.000000000)
  private static let Data1992_1745 = simd_quatd(ix: 0.779454186 , iy: -0.179160289 , iz: -0.600293897 , r: 0.000000000)
  private static let Data1992_1746 = simd_quatd(ix: 0.779454186 , iy: 0.000000000 , iz: -0.600293897 , r: 0.179160289)
  private static let Data1992_1747 = simd_quatd(ix: -0.600293897 , iy: 0.179160289 , iz: 0.779454186 , r: -0.000000000)
  private static let Data1992_1748 = simd_quatd(ix: -0.600293897 , iy: -0.000000000 , iz: 0.779454186 , r: -0.179160289)
  private static let Data1992_1749 = simd_quatd(ix: 0.779454186 , iy: 0.000000000 , iz: -0.600293897 , r: -0.179160289)
  private static let Data1992_1750 = simd_quatd(ix: 0.779454186 , iy: 0.179160289 , iz: -0.600293897 , r: 0.000000000)
  private static let Data1992_1751 = simd_quatd(ix: -0.600293897 , iy: -0.000000000 , iz: 0.779454186 , r: 0.179160289)
  private static let Data1992_1752 = simd_quatd(ix: -0.600293897 , iy: -0.179160289 , iz: 0.779454186 , r: -0.000000000)
  private static let Data1992_1753 = simd_quatd(ix: 0.684403834 , iy: -0.177739676 , iz: -0.684403834 , r: -0.177739676)
  private static let Data1992_1754 = simd_quatd(ix: 0.684403834 , iy: 0.177739676 , iz: -0.684403834 , r: 0.177739676)
  private static let Data1992_1755 = simd_quatd(ix: 0.684403834 , iy: -0.177739676 , iz: -0.684403834 , r: 0.177739676)
  private static let Data1992_1756 = simd_quatd(ix: 0.862143509 , iy: 0.000000000 , iz: -0.506664158 , r: 0.000000000)
  private static let Data1992_1757 = simd_quatd(ix: 0.684403834 , iy: 0.177739676 , iz: -0.684403834 , r: -0.177739676)
  private static let Data1992_1758 = simd_quatd(ix: -0.506664158 , iy: -0.000000000 , iz: 0.862143509 , r: -0.000000000)
  private static let Data1992_1759 = simd_quatd(ix: 0.836133444 , iy: -0.172377436 , iz: -0.491378573 , r: -0.172377436)
  private static let Data1992_1760 = simd_quatd(ix: 0.836133444 , iy: 0.172377436 , iz: -0.491378573 , r: 0.172377436)
  private static let Data1992_1761 = simd_quatd(ix: -0.491378573 , iy: 0.172377436 , iz: 0.836133444 , r: 0.172377436)
  private static let Data1992_1762 = simd_quatd(ix: -0.491378573 , iy: -0.172377436 , iz: 0.836133444 , r: -0.172377436)
  private static let Data1992_1763 = simd_quatd(ix: 0.663756009 , iy: -0.344754871 , iz: -0.663756009 , r: 0.000000000)
  private static let Data1992_1764 = simd_quatd(ix: 0.836133444 , iy: -0.172377436 , iz: -0.491378573 , r: 0.172377436)
  private static let Data1992_1765 = simd_quatd(ix: 0.663756009 , iy: 0.000000000 , iz: -0.663756009 , r: -0.344754871)
  private static let Data1992_1766 = simd_quatd(ix: -0.491378573 , iy: 0.172377436 , iz: 0.836133444 , r: -0.172377436)
  private static let Data1992_1767 = simd_quatd(ix: 0.663756009 , iy: 0.000000000 , iz: -0.663756009 , r: 0.344754871)
  private static let Data1992_1768 = simd_quatd(ix: 0.836133444 , iy: 0.172377436 , iz: -0.491378573 , r: -0.172377436)
  private static let Data1992_1769 = simd_quatd(ix: 0.663756009 , iy: 0.344754871 , iz: -0.663756009 , r: 0.000000000)
  private static let Data1992_1770 = simd_quatd(ix: -0.491378573 , iy: -0.172377436 , iz: 0.836133444 , r: 0.172377436)
  private static let Data1992_1771 = simd_quatd(ix: 0.812343818 , iy: -0.334945923 , iz: -0.477397895 , r: 0.000000000)
  private static let Data1992_1772 = simd_quatd(ix: 0.812343818 , iy: 0.000000000 , iz: -0.477397895 , r: 0.334945923)
  private static let Data1992_1773 = simd_quatd(ix: -0.477397895 , iy: 0.334945923 , iz: 0.812343818 , r: -0.000000000)
  private static let Data1992_1774 = simd_quatd(ix: -0.477397895 , iy: -0.000000000 , iz: 0.812343818 , r: -0.334945923)
  private static let Data1992_1775 = simd_quatd(ix: 0.812343818 , iy: 0.000000000 , iz: -0.477397895 , r: -0.334945923)
  private static let Data1992_1776 = simd_quatd(ix: 0.812343818 , iy: 0.334945923 , iz: -0.477397895 , r: 0.000000000)
  private static let Data1992_1777 = simd_quatd(ix: -0.477397895 , iy: -0.000000000 , iz: 0.812343818 , r: 0.334945923)
  private static let Data1992_1778 = simd_quatd(ix: -0.477397895 , iy: -0.334945923 , iz: 0.812343818 , r: -0.000000000)
  private static let Data1992_1779 = simd_quatd(ix: 0.733770554 , iy: -0.337319490 , iz: -0.565110809 , r: -0.168659745)
  private static let Data1992_1780 = simd_quatd(ix: 0.733770554 , iy: 0.168659745 , iz: -0.565110809 , r: 0.337319490)
  private static let Data1992_1781 = simd_quatd(ix: -0.565110809 , iy: 0.337319490 , iz: 0.733770554 , r: 0.168659745)
  private static let Data1992_1782 = simd_quatd(ix: -0.565110809 , iy: -0.168659745 , iz: 0.733770554 , r: -0.337319490)
  private static let Data1992_1783 = simd_quatd(ix: 0.733770554 , iy: -0.168659745 , iz: -0.565110809 , r: -0.337319490)
  private static let Data1992_1784 = simd_quatd(ix: 0.733770554 , iy: 0.337319490 , iz: -0.565110809 , r: 0.168659745)
  private static let Data1992_1785 = simd_quatd(ix: -0.565110809 , iy: 0.168659745 , iz: 0.733770554 , r: 0.337319490)
  private static let Data1992_1786 = simd_quatd(ix: -0.565110809 , iy: -0.337319490 , iz: 0.733770554 , r: -0.168659745)
  private static let Data1992_1787 = simd_quatd(ix: 0.733770554 , iy: -0.337319490 , iz: -0.565110809 , r: 0.168659745)
  private static let Data1992_1788 = simd_quatd(ix: 0.902430299 , iy: -0.168659745 , iz: -0.396451064 , r: 0.000000000)
  private static let Data1992_1789 = simd_quatd(ix: 0.733770554 , iy: 0.168659745 , iz: -0.565110809 , r: -0.337319490)
  private static let Data1992_1790 = simd_quatd(ix: -0.396451064 , iy: 0.168659745 , iz: 0.902430299 , r: -0.000000000)
  private static let Data1992_1791 = simd_quatd(ix: 0.733770554 , iy: -0.168659745 , iz: -0.565110809 , r: 0.337319490)
  private static let Data1992_1792 = simd_quatd(ix: 0.902430299 , iy: 0.000000000 , iz: -0.396451064 , r: -0.168659745)
  private static let Data1992_1793 = simd_quatd(ix: 0.733770554 , iy: 0.337319490 , iz: -0.565110809 , r: -0.168659745)
  private static let Data1992_1794 = simd_quatd(ix: -0.396451064 , iy: -0.000000000 , iz: 0.902430299 , r: 0.168659745)
  private static let Data1992_1795 = simd_quatd(ix: -0.565110809 , iy: 0.337319490 , iz: 0.733770554 , r: -0.168659745)
  private static let Data1992_1796 = simd_quatd(ix: 0.902430299 , iy: 0.000000000 , iz: -0.396451064 , r: 0.168659745)
  private static let Data1992_1797 = simd_quatd(ix: -0.565110809 , iy: -0.168659745 , iz: 0.733770554 , r: 0.337319490)
  private static let Data1992_1798 = simd_quatd(ix: -0.396451064 , iy: -0.000000000 , iz: 0.902430299 , r: -0.168659745)
  private static let Data1992_1799 = simd_quatd(ix: -0.565110809 , iy: 0.168659745 , iz: 0.733770554 , r: -0.337319490)
  private static let Data1992_1800 = simd_quatd(ix: 0.902430299 , iy: 0.168659745 , iz: -0.396451064 , r: 0.000000000)
  private static let Data1992_1801 = simd_quatd(ix: -0.565110809 , iy: -0.337319490 , iz: 0.733770554 , r: 0.168659745)
  private static let Data1992_1802 = simd_quatd(ix: -0.396451064 , iy: -0.168659745 , iz: 0.902430299 , r: -0.000000000)
  private static let Data1992_1803 = simd_quatd(ix: 0.855092496 , iy: -0.319625089 , iz: -0.375654863 , r: -0.159812545)
  private static let Data1992_1804 = simd_quatd(ix: 0.855092496 , iy: 0.159812545 , iz: -0.375654863 , r: 0.319625089)
  private static let Data1992_1805 = simd_quatd(ix: -0.375654863 , iy: 0.319625089 , iz: 0.855092496 , r: 0.159812545)
  private static let Data1992_1806 = simd_quatd(ix: -0.375654863 , iy: -0.159812545 , iz: 0.855092496 , r: -0.319625089)
  private static let Data1992_1807 = simd_quatd(ix: 0.855092496 , iy: -0.159812545 , iz: -0.375654863 , r: -0.319625089)
  private static let Data1992_1808 = simd_quatd(ix: 0.855092496 , iy: 0.319625089 , iz: -0.375654863 , r: 0.159812545)
  private static let Data1992_1809 = simd_quatd(ix: -0.375654863 , iy: 0.159812545 , iz: 0.855092496 , r: 0.319625089)
  private static let Data1992_1810 = simd_quatd(ix: -0.375654863 , iy: -0.319625089 , iz: 0.855092496 , r: -0.159812545)
  private static let Data1992_1811 = simd_quatd(ix: 0.695279952 , iy: -0.479437634 , iz: -0.535467407 , r: 0.000000000)
  private static let Data1992_1812 = simd_quatd(ix: 0.855092496 , iy: -0.319625089 , iz: -0.375654863 , r: 0.159812545)
  private static let Data1992_1813 = simd_quatd(ix: 0.695279952 , iy: 0.000000000 , iz: -0.535467407 , r: -0.479437634)
  private static let Data1992_1814 = simd_quatd(ix: -0.375654863 , iy: 0.319625089 , iz: 0.855092496 , r: -0.159812545)
  private static let Data1992_1815 = simd_quatd(ix: 0.695279952 , iy: 0.000000000 , iz: -0.535467407 , r: 0.479437634)
  private static let Data1992_1816 = simd_quatd(ix: 0.855092496 , iy: 0.159812545 , iz: -0.375654863 , r: -0.319625089)
  private static let Data1992_1817 = simd_quatd(ix: 0.695279952 , iy: 0.479437634 , iz: -0.535467407 , r: 0.000000000)
  private static let Data1992_1818 = simd_quatd(ix: -0.375654863 , iy: -0.159812545 , iz: 0.855092496 , r: 0.319625089)
  private static let Data1992_1819 = simd_quatd(ix: -0.535467407 , iy: 0.479437634 , iz: 0.695279952 , r: -0.000000000)
  private static let Data1992_1820 = simd_quatd(ix: 0.855092496 , iy: -0.159812545 , iz: -0.375654863 , r: 0.319625089)
  private static let Data1992_1821 = simd_quatd(ix: -0.535467407 , iy: -0.000000000 , iz: 0.695279952 , r: 0.479437634)
  private static let Data1992_1822 = simd_quatd(ix: -0.375654863 , iy: 0.159812545 , iz: 0.855092496 , r: -0.319625089)
  private static let Data1992_1823 = simd_quatd(ix: -0.535467407 , iy: -0.000000000 , iz: 0.695279952 , r: -0.479437634)
  private static let Data1992_1824 = simd_quatd(ix: 0.855092496 , iy: 0.319625089 , iz: -0.375654863 , r: -0.159812545)
  private static let Data1992_1825 = simd_quatd(ix: -0.535467407 , iy: -0.479437634 , iz: 0.695279952 , r: -0.000000000)
  private static let Data1992_1826 = simd_quatd(ix: -0.375654863 , iy: -0.319625089 , iz: 0.855092496 , r: 0.159812545)
  private static let Data1992_1827 = simd_quatd(ix: 0.000000000 , iy: 0.707106781 , iz: 0.707106781 , r: 0.000000000)
  private static let Data1992_1828 = simd_quatd(ix: 0.000000000 , iy: 0.779454186 , iz: 0.600293897 , r: -0.179160289)
  private static let Data1992_1829 = simd_quatd(ix: 0.000000000 , iy: 0.600293897 , iz: 0.779454186 , r: -0.179160289)
  private static let Data1992_1830 = simd_quatd(ix: 0.179160289 , iy: 0.779454186 , iz: 0.600293897 , r: 0.000000000)
  private static let Data1992_1831 = simd_quatd(ix: 0.179160289 , iy: 0.600293897 , iz: 0.779454186 , r: 0.000000000)
  private static let Data1992_1832 = simd_quatd(ix: -0.179160289 , iy: 0.779454186 , iz: 0.600293897 , r: 0.000000000)
  private static let Data1992_1833 = simd_quatd(ix: -0.179160289 , iy: 0.600293897 , iz: 0.779454186 , r: 0.000000000)
  private static let Data1992_1834 = simd_quatd(ix: 0.000000000 , iy: 0.779454186 , iz: 0.600293897 , r: 0.179160289)
  private static let Data1992_1835 = simd_quatd(ix: 0.000000000 , iy: 0.600293897 , iz: 0.779454186 , r: 0.179160289)
  private static let Data1992_1836 = simd_quatd(ix: 0.000000000 , iy: 0.862143509 , iz: 0.506664158 , r: 0.000000000)
  private static let Data1992_1837 = simd_quatd(ix: 0.000000000 , iy: 0.506664158 , iz: 0.862143509 , r: 0.000000000)
  private static let Data1992_1838 = simd_quatd(ix: 0.177739676 , iy: 0.684403834 , iz: 0.684403834 , r: -0.177739676)
  private static let Data1992_1839 = simd_quatd(ix: -0.177739676 , iy: 0.684403834 , iz: 0.684403834 , r: -0.177739676)
  private static let Data1992_1840 = simd_quatd(ix: -0.177739676 , iy: 0.684403834 , iz: 0.684403834 , r: 0.177739676)
  private static let Data1992_1841 = simd_quatd(ix: 0.177739676 , iy: 0.684403834 , iz: 0.684403834 , r: 0.177739676)
  private static let Data1992_1842 = simd_quatd(ix: -0.172377436 , iy: 0.836133444 , iz: 0.491378573 , r: -0.172377436)
  private static let Data1992_1843 = simd_quatd(ix: -0.172377436 , iy: 0.491378573 , iz: 0.836133444 , r: -0.172377436)
  private static let Data1992_1844 = simd_quatd(ix: 0.172377436 , iy: 0.836133444 , iz: 0.491378573 , r: 0.172377436)
  private static let Data1992_1845 = simd_quatd(ix: 0.172377436 , iy: 0.491378573 , iz: 0.836133444 , r: 0.172377436)
  private static let Data1992_1846 = simd_quatd(ix: 0.172377436 , iy: 0.836133444 , iz: 0.491378573 , r: -0.172377436)
  private static let Data1992_1847 = simd_quatd(ix: 0.000000000 , iy: 0.663756009 , iz: 0.663756009 , r: -0.344754871)
  private static let Data1992_1848 = simd_quatd(ix: -0.172377436 , iy: 0.836133444 , iz: 0.491378573 , r: 0.172377436)
  private static let Data1992_1849 = simd_quatd(ix: 0.344754871 , iy: 0.663756009 , iz: 0.663756009 , r: 0.000000000)
  private static let Data1992_1850 = simd_quatd(ix: 0.172377436 , iy: 0.491378573 , iz: 0.836133444 , r: -0.172377436)
  private static let Data1992_1851 = simd_quatd(ix: -0.344754871 , iy: 0.663756009 , iz: 0.663756009 , r: 0.000000000)
  private static let Data1992_1852 = simd_quatd(ix: -0.172377436 , iy: 0.491378573 , iz: 0.836133444 , r: 0.172377436)
  private static let Data1992_1853 = simd_quatd(ix: 0.000000000 , iy: 0.663756009 , iz: 0.663756009 , r: 0.344754871)
  private static let Data1992_1854 = simd_quatd(ix: 0.000000000 , iy: 0.812343818 , iz: 0.477397895 , r: -0.334945923)
  private static let Data1992_1855 = simd_quatd(ix: 0.000000000 , iy: 0.477397895 , iz: 0.812343818 , r: -0.334945923)
  private static let Data1992_1856 = simd_quatd(ix: 0.334945923 , iy: 0.812343818 , iz: 0.477397895 , r: 0.000000000)
  private static let Data1992_1857 = simd_quatd(ix: 0.334945923 , iy: 0.477397895 , iz: 0.812343818 , r: 0.000000000)
  private static let Data1992_1858 = simd_quatd(ix: -0.334945923 , iy: 0.812343818 , iz: 0.477397895 , r: 0.000000000)
  private static let Data1992_1859 = simd_quatd(ix: -0.334945923 , iy: 0.477397895 , iz: 0.812343818 , r: 0.000000000)
  private static let Data1992_1860 = simd_quatd(ix: 0.000000000 , iy: 0.812343818 , iz: 0.477397895 , r: 0.334945923)
  private static let Data1992_1861 = simd_quatd(ix: 0.000000000 , iy: 0.477397895 , iz: 0.812343818 , r: 0.334945923)
  private static let Data1992_1862 = simd_quatd(ix: 0.000000000 , iy: 0.902430299 , iz: 0.396451064 , r: -0.168659745)
  private static let Data1992_1863 = simd_quatd(ix: 0.000000000 , iy: 0.396451064 , iz: 0.902430299 , r: -0.168659745)
  private static let Data1992_1864 = simd_quatd(ix: 0.168659745 , iy: 0.902430299 , iz: 0.396451064 , r: 0.000000000)
  private static let Data1992_1865 = simd_quatd(ix: 0.168659745 , iy: 0.396451064 , iz: 0.902430299 , r: 0.000000000)
  private static let Data1992_1866 = simd_quatd(ix: -0.168659745 , iy: 0.902430299 , iz: 0.396451064 , r: 0.000000000)
  private static let Data1992_1867 = simd_quatd(ix: -0.168659745 , iy: 0.396451064 , iz: 0.902430299 , r: 0.000000000)
  private static let Data1992_1868 = simd_quatd(ix: 0.000000000 , iy: 0.902430299 , iz: 0.396451064 , r: 0.168659745)
  private static let Data1992_1869 = simd_quatd(ix: 0.000000000 , iy: 0.396451064 , iz: 0.902430299 , r: 0.168659745)
  private static let Data1992_1870 = simd_quatd(ix: 0.168659745 , iy: 0.733770554 , iz: 0.565110809 , r: -0.337319490)
  private static let Data1992_1871 = simd_quatd(ix: -0.168659745 , iy: 0.733770554 , iz: 0.565110809 , r: -0.337319490)
  private static let Data1992_1872 = simd_quatd(ix: -0.337319490 , iy: 0.733770554 , iz: 0.565110809 , r: 0.168659745)
  private static let Data1992_1873 = simd_quatd(ix: 0.337319490 , iy: 0.733770554 , iz: 0.565110809 , r: 0.168659745)
  private static let Data1992_1874 = simd_quatd(ix: 0.168659745 , iy: 0.565110809 , iz: 0.733770554 , r: -0.337319490)
  private static let Data1992_1875 = simd_quatd(ix: -0.337319490 , iy: 0.733770554 , iz: 0.565110809 , r: -0.168659745)
  private static let Data1992_1876 = simd_quatd(ix: -0.337319490 , iy: 0.565110809 , iz: 0.733770554 , r: 0.168659745)
  private static let Data1992_1877 = simd_quatd(ix: 0.168659745 , iy: 0.733770554 , iz: 0.565110809 , r: 0.337319490)
  private static let Data1992_1878 = simd_quatd(ix: 0.337319490 , iy: 0.733770554 , iz: 0.565110809 , r: -0.168659745)
  private static let Data1992_1879 = simd_quatd(ix: -0.168659745 , iy: 0.565110809 , iz: 0.733770554 , r: -0.337319490)
  private static let Data1992_1880 = simd_quatd(ix: -0.168659745 , iy: 0.733770554 , iz: 0.565110809 , r: 0.337319490)
  private static let Data1992_1881 = simd_quatd(ix: 0.337319490 , iy: 0.565110809 , iz: 0.733770554 , r: 0.168659745)
  private static let Data1992_1882 = simd_quatd(ix: 0.337319490 , iy: 0.565110809 , iz: 0.733770554 , r: -0.168659745)
  private static let Data1992_1883 = simd_quatd(ix: -0.337319490 , iy: 0.565110809 , iz: 0.733770554 , r: -0.168659745)
  private static let Data1992_1884 = simd_quatd(ix: -0.168659745 , iy: 0.565110809 , iz: 0.733770554 , r: 0.337319490)
  private static let Data1992_1885 = simd_quatd(ix: 0.168659745 , iy: 0.565110809 , iz: 0.733770554 , r: 0.337319490)
  private static let Data1992_1886 = simd_quatd(ix: -0.159812545 , iy: 0.855092496 , iz: 0.375654863 , r: -0.319625089)
  private static let Data1992_1887 = simd_quatd(ix: -0.159812545 , iy: 0.375654863 , iz: 0.855092496 , r: -0.319625089)
  private static let Data1992_1888 = simd_quatd(ix: 0.319625089 , iy: 0.855092496 , iz: 0.375654863 , r: 0.159812545)
  private static let Data1992_1889 = simd_quatd(ix: 0.319625089 , iy: 0.375654863 , iz: 0.855092496 , r: 0.159812545)
  private static let Data1992_1890 = simd_quatd(ix: -0.319625089 , iy: 0.855092496 , iz: 0.375654863 , r: -0.159812545)
  private static let Data1992_1891 = simd_quatd(ix: -0.319625089 , iy: 0.375654863 , iz: 0.855092496 , r: -0.159812545)
  private static let Data1992_1892 = simd_quatd(ix: 0.159812545 , iy: 0.855092496 , iz: 0.375654863 , r: 0.319625089)
  private static let Data1992_1893 = simd_quatd(ix: 0.159812545 , iy: 0.375654863 , iz: 0.855092496 , r: 0.319625089)
  private static let Data1992_1894 = simd_quatd(ix: 0.159812545 , iy: 0.855092496 , iz: 0.375654863 , r: -0.319625089)
  private static let Data1992_1895 = simd_quatd(ix: 0.000000000 , iy: 0.695279952 , iz: 0.535467407 , r: -0.479437634)
  private static let Data1992_1896 = simd_quatd(ix: -0.319625089 , iy: 0.855092496 , iz: 0.375654863 , r: 0.159812545)
  private static let Data1992_1897 = simd_quatd(ix: 0.479437634 , iy: 0.695279952 , iz: 0.535467407 , r: 0.000000000)
  private static let Data1992_1898 = simd_quatd(ix: 0.159812545 , iy: 0.375654863 , iz: 0.855092496 , r: -0.319625089)
  private static let Data1992_1899 = simd_quatd(ix: -0.479437634 , iy: 0.695279952 , iz: 0.535467407 , r: 0.000000000)
  private static let Data1992_1900 = simd_quatd(ix: -0.319625089 , iy: 0.375654863 , iz: 0.855092496 , r: 0.159812545)
  private static let Data1992_1901 = simd_quatd(ix: 0.000000000 , iy: 0.695279952 , iz: 0.535467407 , r: 0.479437634)
  private static let Data1992_1902 = simd_quatd(ix: 0.319625089 , iy: 0.855092496 , iz: 0.375654863 , r: -0.159812545)
  private static let Data1992_1903 = simd_quatd(ix: 0.000000000 , iy: 0.535467407 , iz: 0.695279952 , r: -0.479437634)
  private static let Data1992_1904 = simd_quatd(ix: -0.159812545 , iy: 0.855092496 , iz: 0.375654863 , r: 0.319625089)
  private static let Data1992_1905 = simd_quatd(ix: 0.479437634 , iy: 0.535467407 , iz: 0.695279952 , r: 0.000000000)
  private static let Data1992_1906 = simd_quatd(ix: 0.319625089 , iy: 0.375654863 , iz: 0.855092496 , r: -0.159812545)
  private static let Data1992_1907 = simd_quatd(ix: -0.479437634 , iy: 0.535467407 , iz: 0.695279952 , r: 0.000000000)
  private static let Data1992_1908 = simd_quatd(ix: -0.159812545 , iy: 0.375654863 , iz: 0.855092496 , r: 0.319625089)
  private static let Data1992_1909 = simd_quatd(ix: 0.000000000 , iy: 0.535467407 , iz: 0.695279952 , r: 0.479437634)
  private static let Data1992_1910 = simd_quatd(ix: 0.000000000 , iy: 0.707106781 , iz: -0.707106781 , r: 0.000000000)
  private static let Data1992_1911 = simd_quatd(ix: -0.179160289 , iy: -0.600293897 , iz: 0.779454186 , r: -0.000000000)
  private static let Data1992_1912 = simd_quatd(ix: 0.179160289 , iy: 0.779454186 , iz: -0.600293897 , r: 0.000000000)
  private static let Data1992_1913 = simd_quatd(ix: -0.000000000 , iy: -0.600293897 , iz: 0.779454186 , r: -0.179160289)
  private static let Data1992_1914 = simd_quatd(ix: 0.000000000 , iy: 0.779454186 , iz: -0.600293897 , r: 0.179160289)
  private static let Data1992_1915 = simd_quatd(ix: -0.000000000 , iy: -0.600293897 , iz: 0.779454186 , r: 0.179160289)
  private static let Data1992_1916 = simd_quatd(ix: 0.000000000 , iy: 0.779454186 , iz: -0.600293897 , r: -0.179160289)
  private static let Data1992_1917 = simd_quatd(ix: 0.179160289 , iy: -0.600293897 , iz: 0.779454186 , r: -0.000000000)
  private static let Data1992_1918 = simd_quatd(ix: -0.179160289 , iy: 0.779454186 , iz: -0.600293897 , r: 0.000000000)
  private static let Data1992_1919 = simd_quatd(ix: -0.000000000 , iy: -0.506664158 , iz: 0.862143509 , r: -0.000000000)
  private static let Data1992_1920 = simd_quatd(ix: 0.000000000 , iy: 0.862143509 , iz: -0.506664158 , r: 0.000000000)
  private static let Data1992_1921 = simd_quatd(ix: 0.177739676 , iy: 0.684403834 , iz: -0.684403834 , r: 0.177739676)
  private static let Data1992_1922 = simd_quatd(ix: 0.177739676 , iy: 0.684403834 , iz: -0.684403834 , r: -0.177739676)
  private static let Data1992_1923 = simd_quatd(ix: -0.177739676 , iy: 0.684403834 , iz: -0.684403834 , r: -0.177739676)
  private static let Data1992_1924 = simd_quatd(ix: -0.177739676 , iy: 0.684403834 , iz: -0.684403834 , r: 0.177739676)
  private static let Data1992_1925 = simd_quatd(ix: -0.172377436 , iy: -0.491378573 , iz: 0.836133444 , r: 0.172377436)
  private static let Data1992_1926 = simd_quatd(ix: 0.172377436 , iy: 0.836133444 , iz: -0.491378573 , r: -0.172377436)
  private static let Data1992_1927 = simd_quatd(ix: 0.172377436 , iy: -0.491378573 , iz: 0.836133444 , r: -0.172377436)
  private static let Data1992_1928 = simd_quatd(ix: -0.172377436 , iy: 0.836133444 , iz: -0.491378573 , r: 0.172377436)
  private static let Data1992_1929 = simd_quatd(ix: -0.172377436 , iy: -0.491378573 , iz: 0.836133444 , r: -0.172377436)
  private static let Data1992_1930 = simd_quatd(ix: 0.344754871 , iy: 0.663756009 , iz: -0.663756009 , r: 0.000000000)
  private static let Data1992_1931 = simd_quatd(ix: 0.172377436 , iy: -0.491378573 , iz: 0.836133444 , r: 0.172377436)
  private static let Data1992_1932 = simd_quatd(ix: 0.000000000 , iy: 0.663756009 , iz: -0.663756009 , r: 0.344754871)
  private static let Data1992_1933 = simd_quatd(ix: 0.172377436 , iy: 0.836133444 , iz: -0.491378573 , r: 0.172377436)
  private static let Data1992_1934 = simd_quatd(ix: 0.000000000 , iy: 0.663756009 , iz: -0.663756009 , r: -0.344754871)
  private static let Data1992_1935 = simd_quatd(ix: -0.172377436 , iy: 0.836133444 , iz: -0.491378573 , r: -0.172377436)
  private static let Data1992_1936 = simd_quatd(ix: -0.344754871 , iy: 0.663756009 , iz: -0.663756009 , r: 0.000000000)
  private static let Data1992_1937 = simd_quatd(ix: -0.334945923 , iy: -0.477397895 , iz: 0.812343818 , r: -0.000000000)
  private static let Data1992_1938 = simd_quatd(ix: 0.334945923 , iy: 0.812343818 , iz: -0.477397895 , r: 0.000000000)
  private static let Data1992_1939 = simd_quatd(ix: -0.000000000 , iy: -0.477397895 , iz: 0.812343818 , r: -0.334945923)
  private static let Data1992_1940 = simd_quatd(ix: 0.000000000 , iy: 0.812343818 , iz: -0.477397895 , r: 0.334945923)
  private static let Data1992_1941 = simd_quatd(ix: -0.000000000 , iy: -0.477397895 , iz: 0.812343818 , r: 0.334945923)
  private static let Data1992_1942 = simd_quatd(ix: 0.000000000 , iy: 0.812343818 , iz: -0.477397895 , r: -0.334945923)
  private static let Data1992_1943 = simd_quatd(ix: 0.334945923 , iy: -0.477397895 , iz: 0.812343818 , r: -0.000000000)
  private static let Data1992_1944 = simd_quatd(ix: -0.334945923 , iy: 0.812343818 , iz: -0.477397895 , r: 0.000000000)
  private static let Data1992_1945 = simd_quatd(ix: -0.168659745 , iy: -0.396451064 , iz: 0.902430299 , r: -0.000000000)
  private static let Data1992_1946 = simd_quatd(ix: 0.168659745 , iy: 0.902430299 , iz: -0.396451064 , r: 0.000000000)
  private static let Data1992_1947 = simd_quatd(ix: -0.000000000 , iy: -0.396451064 , iz: 0.902430299 , r: -0.168659745)
  private static let Data1992_1948 = simd_quatd(ix: 0.000000000 , iy: 0.902430299 , iz: -0.396451064 , r: 0.168659745)
  private static let Data1992_1949 = simd_quatd(ix: -0.000000000 , iy: -0.396451064 , iz: 0.902430299 , r: 0.168659745)
  private static let Data1992_1950 = simd_quatd(ix: 0.000000000 , iy: 0.902430299 , iz: -0.396451064 , r: -0.168659745)
  private static let Data1992_1951 = simd_quatd(ix: 0.168659745 , iy: -0.396451064 , iz: 0.902430299 , r: -0.000000000)
  private static let Data1992_1952 = simd_quatd(ix: -0.168659745 , iy: 0.902430299 , iz: -0.396451064 , r: 0.000000000)
  private static let Data1992_1953 = simd_quatd(ix: -0.337319490 , iy: -0.565110809 , iz: 0.733770554 , r: -0.168659745)
  private static let Data1992_1954 = simd_quatd(ix: -0.337319490 , iy: -0.565110809 , iz: 0.733770554 , r: 0.168659745)
  private static let Data1992_1955 = simd_quatd(ix: 0.168659745 , iy: -0.565110809 , iz: 0.733770554 , r: 0.337319490)
  private static let Data1992_1956 = simd_quatd(ix: 0.168659745 , iy: -0.565110809 , iz: 0.733770554 , r: -0.337319490)
  private static let Data1992_1957 = simd_quatd(ix: 0.337319490 , iy: 0.733770554 , iz: -0.565110809 , r: 0.168659745)
  private static let Data1992_1958 = simd_quatd(ix: -0.168659745 , iy: -0.565110809 , iz: 0.733770554 , r: 0.337319490)
  private static let Data1992_1959 = simd_quatd(ix: -0.168659745 , iy: 0.733770554 , iz: -0.565110809 , r: -0.337319490)
  private static let Data1992_1960 = simd_quatd(ix: 0.337319490 , iy: -0.565110809 , iz: 0.733770554 , r: -0.168659745)
  private static let Data1992_1961 = simd_quatd(ix: -0.168659745 , iy: -0.565110809 , iz: 0.733770554 , r: -0.337319490)
  private static let Data1992_1962 = simd_quatd(ix: 0.337319490 , iy: 0.733770554 , iz: -0.565110809 , r: -0.168659745)
  private static let Data1992_1963 = simd_quatd(ix: 0.337319490 , iy: -0.565110809 , iz: 0.733770554 , r: 0.168659745)
  private static let Data1992_1964 = simd_quatd(ix: -0.168659745 , iy: 0.733770554 , iz: -0.565110809 , r: 0.337319490)
  private static let Data1992_1965 = simd_quatd(ix: 0.168659745 , iy: 0.733770554 , iz: -0.565110809 , r: 0.337319490)
  private static let Data1992_1966 = simd_quatd(ix: 0.168659745 , iy: 0.733770554 , iz: -0.565110809 , r: -0.337319490)
  private static let Data1992_1967 = simd_quatd(ix: -0.337319490 , iy: 0.733770554 , iz: -0.565110809 , r: -0.168659745)
  private static let Data1992_1968 = simd_quatd(ix: -0.337319490 , iy: 0.733770554 , iz: -0.565110809 , r: 0.168659745)
  private static let Data1992_1969 = simd_quatd(ix: -0.319625089 , iy: -0.375654863 , iz: 0.855092496 , r: 0.159812545)
  private static let Data1992_1970 = simd_quatd(ix: 0.319625089 , iy: 0.855092496 , iz: -0.375654863 , r: -0.159812545)
  private static let Data1992_1971 = simd_quatd(ix: 0.159812545 , iy: -0.375654863 , iz: 0.855092496 , r: -0.319625089)
  private static let Data1992_1972 = simd_quatd(ix: -0.159812545 , iy: 0.855092496 , iz: -0.375654863 , r: 0.319625089)
  private static let Data1992_1973 = simd_quatd(ix: -0.159812545 , iy: -0.375654863 , iz: 0.855092496 , r: 0.319625089)
  private static let Data1992_1974 = simd_quatd(ix: 0.159812545 , iy: 0.855092496 , iz: -0.375654863 , r: -0.319625089)
  private static let Data1992_1975 = simd_quatd(ix: 0.319625089 , iy: -0.375654863 , iz: 0.855092496 , r: -0.159812545)
  private static let Data1992_1976 = simd_quatd(ix: -0.319625089 , iy: 0.855092496 , iz: -0.375654863 , r: 0.159812545)
  private static let Data1992_1977 = simd_quatd(ix: -0.319625089 , iy: -0.375654863 , iz: 0.855092496 , r: -0.159812545)
  private static let Data1992_1978 = simd_quatd(ix: -0.479437634 , iy: -0.535467407 , iz: 0.695279952 , r: -0.000000000)
  private static let Data1992_1979 = simd_quatd(ix: 0.159812545 , iy: -0.375654863 , iz: 0.855092496 , r: 0.319625089)
  private static let Data1992_1980 = simd_quatd(ix: -0.000000000 , iy: -0.535467407 , iz: 0.695279952 , r: -0.479437634)
  private static let Data1992_1981 = simd_quatd(ix: 0.319625089 , iy: 0.855092496 , iz: -0.375654863 , r: 0.159812545)
  private static let Data1992_1982 = simd_quatd(ix: -0.000000000 , iy: -0.535467407 , iz: 0.695279952 , r: 0.479437634)
  private static let Data1992_1983 = simd_quatd(ix: -0.159812545 , iy: 0.855092496 , iz: -0.375654863 , r: -0.319625089)
  private static let Data1992_1984 = simd_quatd(ix: 0.479437634 , iy: -0.535467407 , iz: 0.695279952 , r: -0.000000000)
  private static let Data1992_1985 = simd_quatd(ix: -0.159812545 , iy: -0.375654863 , iz: 0.855092496 , r: -0.319625089)
  private static let Data1992_1986 = simd_quatd(ix: 0.479437634 , iy: 0.695279952 , iz: -0.535467407 , r: 0.000000000)
  private static let Data1992_1987 = simd_quatd(ix: 0.319625089 , iy: -0.375654863 , iz: 0.855092496 , r: 0.159812545)
  private static let Data1992_1988 = simd_quatd(ix: 0.000000000 , iy: 0.695279952 , iz: -0.535467407 , r: 0.479437634)
  private static let Data1992_1989 = simd_quatd(ix: 0.159812545 , iy: 0.855092496 , iz: -0.375654863 , r: 0.319625089)
  private static let Data1992_1990 = simd_quatd(ix: 0.000000000 , iy: 0.695279952 , iz: -0.535467407 , r: -0.479437634)
  private static let Data1992_1991 = simd_quatd(ix: -0.319625089 , iy: 0.855092496 , iz: -0.375654863 , r: -0.159812545)
  private static let Data1992_1992 = simd_quatd(ix: -0.479437634 , iy: 0.695279952 , iz: -0.535467407 , r: 0.000000000)

  
  public static let Data1992: [simd_quatd] =
  [
        Data1992_1,
    Data1992_2,
    Data1992_3,
    Data1992_4,
    Data1992_5,
    Data1992_6,
    Data1992_7,
    Data1992_8,
    Data1992_9,
    Data1992_10,
    Data1992_11,
    Data1992_12,
    Data1992_13,
    Data1992_14,
    Data1992_15,
    Data1992_16,
    Data1992_17,
    Data1992_18,
    Data1992_19,
    Data1992_20,
    Data1992_21,
    Data1992_22,
    Data1992_23,
    Data1992_24,
    Data1992_25,
    Data1992_26,
    Data1992_27,
    Data1992_28,
    Data1992_29,
    Data1992_30,
    Data1992_31,
    Data1992_32,
    Data1992_33,
    Data1992_34,
    Data1992_35,
    Data1992_36,
    Data1992_37,
    Data1992_38,
    Data1992_39,
    Data1992_40,
    Data1992_41,
    Data1992_42,
    Data1992_43,
    Data1992_44,
    Data1992_45,
    Data1992_46,
    Data1992_47,
    Data1992_48,
    Data1992_49,
    Data1992_50,
    Data1992_51,
    Data1992_52,
    Data1992_53,
    Data1992_54,
    Data1992_55,
    Data1992_56,
    Data1992_57,
    Data1992_58,
    Data1992_59,
    Data1992_60,
    Data1992_61,
    Data1992_62,
    Data1992_63,
    Data1992_64,
    Data1992_65,
    Data1992_66,
    Data1992_67,
    Data1992_68,
    Data1992_69,
    Data1992_70,
    Data1992_71,
    Data1992_72,
    Data1992_73,
    Data1992_74,
    Data1992_75,
    Data1992_76,
    Data1992_77,
    Data1992_78,
    Data1992_79,
    Data1992_80,
    Data1992_81,
    Data1992_82,
    Data1992_83,
    Data1992_84,
    Data1992_85,
    Data1992_86,
    Data1992_87,
    Data1992_88,
    Data1992_89,
    Data1992_90,
    Data1992_91,
    Data1992_92,
    Data1992_93,
    Data1992_94,
    Data1992_95,
    Data1992_96,
    Data1992_97,
    Data1992_98,
    Data1992_99,
    Data1992_100,
    Data1992_101,
    Data1992_102,
    Data1992_103,
    Data1992_104,
    Data1992_105,
    Data1992_106,
    Data1992_107,
    Data1992_108,
    Data1992_109,
    Data1992_110,
    Data1992_111,
    Data1992_112,
    Data1992_113,
    Data1992_114,
    Data1992_115,
    Data1992_116,
    Data1992_117,
    Data1992_118,
    Data1992_119,
    Data1992_120,
    Data1992_121,
    Data1992_122,
    Data1992_123,
    Data1992_124,
    Data1992_125,
    Data1992_126,
    Data1992_127,
    Data1992_128,
    Data1992_129,
    Data1992_130,
    Data1992_131,
    Data1992_132,
    Data1992_133,
    Data1992_134,
    Data1992_135,
    Data1992_136,
    Data1992_137,
    Data1992_138,
    Data1992_139,
    Data1992_140,
    Data1992_141,
    Data1992_142,
    Data1992_143,
    Data1992_144,
    Data1992_145,
    Data1992_146,
    Data1992_147,
    Data1992_148,
    Data1992_149,
    Data1992_150,
    Data1992_151,
    Data1992_152,
    Data1992_153,
    Data1992_154,
    Data1992_155,
    Data1992_156,
    Data1992_157,
    Data1992_158,
    Data1992_159,
    Data1992_160,
    Data1992_161,
    Data1992_162,
    Data1992_163,
    Data1992_164,
    Data1992_165,
    Data1992_166,
    Data1992_167,
    Data1992_168,
    Data1992_169,
    Data1992_170,
    Data1992_171,
    Data1992_172,
    Data1992_173,
    Data1992_174,
    Data1992_175,
    Data1992_176,
    Data1992_177,
    Data1992_178,
    Data1992_179,
    Data1992_180,
    Data1992_181,
    Data1992_182,
    Data1992_183,
    Data1992_184,
    Data1992_185,
    Data1992_186,
    Data1992_187,
    Data1992_188,
    Data1992_189,
    Data1992_190,
    Data1992_191,
    Data1992_192,
    Data1992_193,
    Data1992_194,
    Data1992_195,
    Data1992_196,
    Data1992_197,
    Data1992_198,
    Data1992_199,
    Data1992_200,
    Data1992_201,
    Data1992_202,
    Data1992_203,
    Data1992_204,
    Data1992_205,
    Data1992_206,
    Data1992_207,
    Data1992_208,
    Data1992_209,
    Data1992_210,
    Data1992_211,
    Data1992_212,
    Data1992_213,
    Data1992_214,
    Data1992_215,
    Data1992_216,
    Data1992_217,
    Data1992_218,
    Data1992_219,
    Data1992_220,
    Data1992_221,
    Data1992_222,
    Data1992_223,
    Data1992_224,
    Data1992_225,
    Data1992_226,
    Data1992_227,
    Data1992_228,
    Data1992_229,
    Data1992_230,
    Data1992_231,
    Data1992_232,
    Data1992_233,
    Data1992_234,
    Data1992_235,
    Data1992_236,
    Data1992_237,
    Data1992_238,
    Data1992_239,
    Data1992_240,
    Data1992_241,
    Data1992_242,
    Data1992_243,
    Data1992_244,
    Data1992_245,
    Data1992_246,
    Data1992_247,
    Data1992_248,
    Data1992_249,
    Data1992_250,
    Data1992_251,
    Data1992_252,
    Data1992_253,
    Data1992_254,
    Data1992_255,
    Data1992_256,
    Data1992_257,
    Data1992_258,
    Data1992_259,
    Data1992_260,
    Data1992_261,
    Data1992_262,
    Data1992_263,
    Data1992_264,
    Data1992_265,
    Data1992_266,
    Data1992_267,
    Data1992_268,
    Data1992_269,
    Data1992_270,
    Data1992_271,
    Data1992_272,
    Data1992_273,
    Data1992_274,
    Data1992_275,
    Data1992_276,
    Data1992_277,
    Data1992_278,
    Data1992_279,
    Data1992_280,
    Data1992_281,
    Data1992_282,
    Data1992_283,
    Data1992_284,
    Data1992_285,
    Data1992_286,
    Data1992_287,
    Data1992_288,
    Data1992_289,
    Data1992_290,
    Data1992_291,
    Data1992_292,
    Data1992_293,
    Data1992_294,
    Data1992_295,
    Data1992_296,
    Data1992_297,
    Data1992_298,
    Data1992_299,
    Data1992_300,
    Data1992_301,
    Data1992_302,
    Data1992_303,
    Data1992_304,
    Data1992_305,
    Data1992_306,
    Data1992_307,
    Data1992_308,
    Data1992_309,
    Data1992_310,
    Data1992_311,
    Data1992_312,
    Data1992_313,
    Data1992_314,
    Data1992_315,
    Data1992_316,
    Data1992_317,
    Data1992_318,
    Data1992_319,
    Data1992_320,
    Data1992_321,
    Data1992_322,
    Data1992_323,
    Data1992_324,
    Data1992_325,
    Data1992_326,
    Data1992_327,
    Data1992_328,
    Data1992_329,
    Data1992_330,
    Data1992_331,
    Data1992_332,
    Data1992_333,
    Data1992_334,
    Data1992_335,
    Data1992_336,
    Data1992_337,
    Data1992_338,
    Data1992_339,
    Data1992_340,
    Data1992_341,
    Data1992_342,
    Data1992_343,
    Data1992_344,
    Data1992_345,
    Data1992_346,
    Data1992_347,
    Data1992_348,
    Data1992_349,
    Data1992_350,
    Data1992_351,
    Data1992_352,
    Data1992_353,
    Data1992_354,
    Data1992_355,
    Data1992_356,
    Data1992_357,
    Data1992_358,
    Data1992_359,
    Data1992_360,
    Data1992_361,
    Data1992_362,
    Data1992_363,
    Data1992_364,
    Data1992_365,
    Data1992_366,
    Data1992_367,
    Data1992_368,
    Data1992_369,
    Data1992_370,
    Data1992_371,
    Data1992_372,
    Data1992_373,
    Data1992_374,
    Data1992_375,
    Data1992_376,
    Data1992_377,
    Data1992_378,
    Data1992_379,
    Data1992_380,
    Data1992_381,
    Data1992_382,
    Data1992_383,
    Data1992_384,
    Data1992_385,
    Data1992_386,
    Data1992_387,
    Data1992_388,
    Data1992_389,
    Data1992_390,
    Data1992_391,
    Data1992_392,
    Data1992_393,
    Data1992_394,
    Data1992_395,
    Data1992_396,
    Data1992_397,
    Data1992_398,
    Data1992_399,
    Data1992_400,
    Data1992_401,
    Data1992_402,
    Data1992_403,
    Data1992_404,
    Data1992_405,
    Data1992_406,
    Data1992_407,
    Data1992_408,
    Data1992_409,
    Data1992_410,
    Data1992_411,
    Data1992_412,
    Data1992_413,
    Data1992_414,
    Data1992_415,
    Data1992_416,
    Data1992_417,
    Data1992_418,
    Data1992_419,
    Data1992_420,
    Data1992_421,
    Data1992_422,
    Data1992_423,
    Data1992_424,
    Data1992_425,
    Data1992_426,
    Data1992_427,
    Data1992_428,
    Data1992_429,
    Data1992_430,
    Data1992_431,
    Data1992_432,
    Data1992_433,
    Data1992_434,
    Data1992_435,
    Data1992_436,
    Data1992_437,
    Data1992_438,
    Data1992_439,
    Data1992_440,
    Data1992_441,
    Data1992_442,
    Data1992_443,
    Data1992_444,
    Data1992_445,
    Data1992_446,
    Data1992_447,
    Data1992_448,
    Data1992_449,
    Data1992_450,
    Data1992_451,
    Data1992_452,
    Data1992_453,
    Data1992_454,
    Data1992_455,
    Data1992_456,
    Data1992_457,
    Data1992_458,
    Data1992_459,
    Data1992_460,
    Data1992_461,
    Data1992_462,
    Data1992_463,
    Data1992_464,
    Data1992_465,
    Data1992_466,
    Data1992_467,
    Data1992_468,
    Data1992_469,
    Data1992_470,
    Data1992_471,
    Data1992_472,
    Data1992_473,
    Data1992_474,
    Data1992_475,
    Data1992_476,
    Data1992_477,
    Data1992_478,
    Data1992_479,
    Data1992_480,
    Data1992_481,
    Data1992_482,
    Data1992_483,
    Data1992_484,
    Data1992_485,
    Data1992_486,
    Data1992_487,
    Data1992_488,
    Data1992_489,
    Data1992_490,
    Data1992_491,
    Data1992_492,
    Data1992_493,
    Data1992_494,
    Data1992_495,
    Data1992_496,
    Data1992_497,
    Data1992_498,
    Data1992_499,
    Data1992_500,
    Data1992_501,
    Data1992_502,
    Data1992_503,
    Data1992_504,
    Data1992_505,
    Data1992_506,
    Data1992_507,
    Data1992_508,
    Data1992_509,
    Data1992_510,
    Data1992_511,
    Data1992_512,
    Data1992_513,
    Data1992_514,
    Data1992_515,
    Data1992_516,
    Data1992_517,
    Data1992_518,
    Data1992_519,
    Data1992_520,
    Data1992_521,
    Data1992_522,
    Data1992_523,
    Data1992_524,
    Data1992_525,
    Data1992_526,
    Data1992_527,
    Data1992_528,
    Data1992_529,
    Data1992_530,
    Data1992_531,
    Data1992_532,
    Data1992_533,
    Data1992_534,
    Data1992_535,
    Data1992_536,
    Data1992_537,
    Data1992_538,
    Data1992_539,
    Data1992_540,
    Data1992_541,
    Data1992_542,
    Data1992_543,
    Data1992_544,
    Data1992_545,
    Data1992_546,
    Data1992_547,
    Data1992_548,
    Data1992_549,
    Data1992_550,
    Data1992_551,
    Data1992_552,
    Data1992_553,
    Data1992_554,
    Data1992_555,
    Data1992_556,
    Data1992_557,
    Data1992_558,
    Data1992_559,
    Data1992_560,
    Data1992_561,
    Data1992_562,
    Data1992_563,
    Data1992_564,
    Data1992_565,
    Data1992_566,
    Data1992_567,
    Data1992_568,
    Data1992_569,
    Data1992_570,
    Data1992_571,
    Data1992_572,
    Data1992_573,
    Data1992_574,
    Data1992_575,
    Data1992_576,
    Data1992_577,
    Data1992_578,
    Data1992_579,
    Data1992_580,
    Data1992_581,
    Data1992_582,
    Data1992_583,
    Data1992_584,
    Data1992_585,
    Data1992_586,
    Data1992_587,
    Data1992_588,
    Data1992_589,
    Data1992_590,
    Data1992_591,
    Data1992_592,
    Data1992_593,
    Data1992_594,
    Data1992_595,
    Data1992_596,
    Data1992_597,
    Data1992_598,
    Data1992_599,
    Data1992_600,
    Data1992_601,
    Data1992_602,
    Data1992_603,
    Data1992_604,
    Data1992_605,
    Data1992_606,
    Data1992_607,
    Data1992_608,
    Data1992_609,
    Data1992_610,
    Data1992_611,
    Data1992_612,
    Data1992_613,
    Data1992_614,
    Data1992_615,
    Data1992_616,
    Data1992_617,
    Data1992_618,
    Data1992_619,
    Data1992_620,
    Data1992_621,
    Data1992_622,
    Data1992_623,
    Data1992_624,
    Data1992_625,
    Data1992_626,
    Data1992_627,
    Data1992_628,
    Data1992_629,
    Data1992_630,
    Data1992_631,
    Data1992_632,
    Data1992_633,
    Data1992_634,
    Data1992_635,
    Data1992_636,
    Data1992_637,
    Data1992_638,
    Data1992_639,
    Data1992_640,
    Data1992_641,
    Data1992_642,
    Data1992_643,
    Data1992_644,
    Data1992_645,
    Data1992_646,
    Data1992_647,
    Data1992_648,
    Data1992_649,
    Data1992_650,
    Data1992_651,
    Data1992_652,
    Data1992_653,
    Data1992_654,
    Data1992_655,
    Data1992_656,
    Data1992_657,
    Data1992_658,
    Data1992_659,
    Data1992_660,
    Data1992_661,
    Data1992_662,
    Data1992_663,
    Data1992_664,
    Data1992_665,
    Data1992_666,
    Data1992_667,
    Data1992_668,
    Data1992_669,
    Data1992_670,
    Data1992_671,
    Data1992_672,
    Data1992_673,
    Data1992_674,
    Data1992_675,
    Data1992_676,
    Data1992_677,
    Data1992_678,
    Data1992_679,
    Data1992_680,
    Data1992_681,
    Data1992_682,
    Data1992_683,
    Data1992_684,
    Data1992_685,
    Data1992_686,
    Data1992_687,
    Data1992_688,
    Data1992_689,
    Data1992_690,
    Data1992_691,
    Data1992_692,
    Data1992_693,
    Data1992_694,
    Data1992_695,
    Data1992_696,
    Data1992_697,
    Data1992_698,
    Data1992_699,
    Data1992_700,
    Data1992_701,
    Data1992_702,
    Data1992_703,
    Data1992_704,
    Data1992_705,
    Data1992_706,
    Data1992_707,
    Data1992_708,
    Data1992_709,
    Data1992_710,
    Data1992_711,
    Data1992_712,
    Data1992_713,
    Data1992_714,
    Data1992_715,
    Data1992_716,
    Data1992_717,
    Data1992_718,
    Data1992_719,
    Data1992_720,
    Data1992_721,
    Data1992_722,
    Data1992_723,
    Data1992_724,
    Data1992_725,
    Data1992_726,
    Data1992_727,
    Data1992_728,
    Data1992_729,
    Data1992_730,
    Data1992_731,
    Data1992_732,
    Data1992_733,
    Data1992_734,
    Data1992_735,
    Data1992_736,
    Data1992_737,
    Data1992_738,
    Data1992_739,
    Data1992_740,
    Data1992_741,
    Data1992_742,
    Data1992_743,
    Data1992_744,
    Data1992_745,
    Data1992_746,
    Data1992_747,
    Data1992_748,
    Data1992_749,
    Data1992_750,
    Data1992_751,
    Data1992_752,
    Data1992_753,
    Data1992_754,
    Data1992_755,
    Data1992_756,
    Data1992_757,
    Data1992_758,
    Data1992_759,
    Data1992_760,
    Data1992_761,
    Data1992_762,
    Data1992_763,
    Data1992_764,
    Data1992_765,
    Data1992_766,
    Data1992_767,
    Data1992_768,
    Data1992_769,
    Data1992_770,
    Data1992_771,
    Data1992_772,
    Data1992_773,
    Data1992_774,
    Data1992_775,
    Data1992_776,
    Data1992_777,
    Data1992_778,
    Data1992_779,
    Data1992_780,
    Data1992_781,
    Data1992_782,
    Data1992_783,
    Data1992_784,
    Data1992_785,
    Data1992_786,
    Data1992_787,
    Data1992_788,
    Data1992_789,
    Data1992_790,
    Data1992_791,
    Data1992_792,
    Data1992_793,
    Data1992_794,
    Data1992_795,
    Data1992_796,
    Data1992_797,
    Data1992_798,
    Data1992_799,
    Data1992_800,
    Data1992_801,
    Data1992_802,
    Data1992_803,
    Data1992_804,
    Data1992_805,
    Data1992_806,
    Data1992_807,
    Data1992_808,
    Data1992_809,
    Data1992_810,
    Data1992_811,
    Data1992_812,
    Data1992_813,
    Data1992_814,
    Data1992_815,
    Data1992_816,
    Data1992_817,
    Data1992_818,
    Data1992_819,
    Data1992_820,
    Data1992_821,
    Data1992_822,
    Data1992_823,
    Data1992_824,
    Data1992_825,
    Data1992_826,
    Data1992_827,
    Data1992_828,
    Data1992_829,
    Data1992_830,
    Data1992_831,
    Data1992_832,
    Data1992_833,
    Data1992_834,
    Data1992_835,
    Data1992_836,
    Data1992_837,
    Data1992_838,
    Data1992_839,
    Data1992_840,
    Data1992_841,
    Data1992_842,
    Data1992_843,
    Data1992_844,
    Data1992_845,
    Data1992_846,
    Data1992_847,
    Data1992_848,
    Data1992_849,
    Data1992_850,
    Data1992_851,
    Data1992_852,
    Data1992_853,
    Data1992_854,
    Data1992_855,
    Data1992_856,
    Data1992_857,
    Data1992_858,
    Data1992_859,
    Data1992_860,
    Data1992_861,
    Data1992_862,
    Data1992_863,
    Data1992_864,
    Data1992_865,
    Data1992_866,
    Data1992_867,
    Data1992_868,
    Data1992_869,
    Data1992_870,
    Data1992_871,
    Data1992_872,
    Data1992_873,
    Data1992_874,
    Data1992_875,
    Data1992_876,
    Data1992_877,
    Data1992_878,
    Data1992_879,
    Data1992_880,
    Data1992_881,
    Data1992_882,
    Data1992_883,
    Data1992_884,
    Data1992_885,
    Data1992_886,
    Data1992_887,
    Data1992_888,
    Data1992_889,
    Data1992_890,
    Data1992_891,
    Data1992_892,
    Data1992_893,
    Data1992_894,
    Data1992_895,
    Data1992_896,
    Data1992_897,
    Data1992_898,
    Data1992_899,
    Data1992_900,
    Data1992_901,
    Data1992_902,
    Data1992_903,
    Data1992_904,
    Data1992_905,
    Data1992_906,
    Data1992_907,
    Data1992_908,
    Data1992_909,
    Data1992_910,
    Data1992_911,
    Data1992_912,
    Data1992_913,
    Data1992_914,
    Data1992_915,
    Data1992_916,
    Data1992_917,
    Data1992_918,
    Data1992_919,
    Data1992_920,
    Data1992_921,
    Data1992_922,
    Data1992_923,
    Data1992_924,
    Data1992_925,
    Data1992_926,
    Data1992_927,
    Data1992_928,
    Data1992_929,
    Data1992_930,
    Data1992_931,
    Data1992_932,
    Data1992_933,
    Data1992_934,
    Data1992_935,
    Data1992_936,
    Data1992_937,
    Data1992_938,
    Data1992_939,
    Data1992_940,
    Data1992_941,
    Data1992_942,
    Data1992_943,
    Data1992_944,
    Data1992_945,
    Data1992_946,
    Data1992_947,
    Data1992_948,
    Data1992_949,
    Data1992_950,
    Data1992_951,
    Data1992_952,
    Data1992_953,
    Data1992_954,
    Data1992_955,
    Data1992_956,
    Data1992_957,
    Data1992_958,
    Data1992_959,
    Data1992_960,
    Data1992_961,
    Data1992_962,
    Data1992_963,
    Data1992_964,
    Data1992_965,
    Data1992_966,
    Data1992_967,
    Data1992_968,
    Data1992_969,
    Data1992_970,
    Data1992_971,
    Data1992_972,
    Data1992_973,
    Data1992_974,
    Data1992_975,
    Data1992_976,
    Data1992_977,
    Data1992_978,
    Data1992_979,
    Data1992_980,
    Data1992_981,
    Data1992_982,
    Data1992_983,
    Data1992_984,
    Data1992_985,
    Data1992_986,
    Data1992_987,
    Data1992_988,
    Data1992_989,
    Data1992_990,
    Data1992_991,
    Data1992_992,
    Data1992_993,
    Data1992_994,
    Data1992_995,
    Data1992_996,
    Data1992_997,
    Data1992_998,
    Data1992_999,
    Data1992_1000,
    Data1992_1001,
    Data1992_1002,
    Data1992_1003,
    Data1992_1004,
    Data1992_1005,
    Data1992_1006,
    Data1992_1007,
    Data1992_1008,
    Data1992_1009,
    Data1992_1010,
    Data1992_1011,
    Data1992_1012,
    Data1992_1013,
    Data1992_1014,
    Data1992_1015,
    Data1992_1016,
    Data1992_1017,
    Data1992_1018,
    Data1992_1019,
    Data1992_1020,
    Data1992_1021,
    Data1992_1022,
    Data1992_1023,
    Data1992_1024,
    Data1992_1025,
    Data1992_1026,
    Data1992_1027,
    Data1992_1028,
    Data1992_1029,
    Data1992_1030,
    Data1992_1031,
    Data1992_1032,
    Data1992_1033,
    Data1992_1034,
    Data1992_1035,
    Data1992_1036,
    Data1992_1037,
    Data1992_1038,
    Data1992_1039,
    Data1992_1040,
    Data1992_1041,
    Data1992_1042,
    Data1992_1043,
    Data1992_1044,
    Data1992_1045,
    Data1992_1046,
    Data1992_1047,
    Data1992_1048,
    Data1992_1049,
    Data1992_1050,
    Data1992_1051,
    Data1992_1052,
    Data1992_1053,
    Data1992_1054,
    Data1992_1055,
    Data1992_1056,
    Data1992_1057,
    Data1992_1058,
    Data1992_1059,
    Data1992_1060,
    Data1992_1061,
    Data1992_1062,
    Data1992_1063,
    Data1992_1064,
    Data1992_1065,
    Data1992_1066,
    Data1992_1067,
    Data1992_1068,
    Data1992_1069,
    Data1992_1070,
    Data1992_1071,
    Data1992_1072,
    Data1992_1073,
    Data1992_1074,
    Data1992_1075,
    Data1992_1076,
    Data1992_1077,
    Data1992_1078,
    Data1992_1079,
    Data1992_1080,
    Data1992_1081,
    Data1992_1082,
    Data1992_1083,
    Data1992_1084,
    Data1992_1085,
    Data1992_1086,
    Data1992_1087,
    Data1992_1088,
    Data1992_1089,
    Data1992_1090,
    Data1992_1091,
    Data1992_1092,
    Data1992_1093,
    Data1992_1094,
    Data1992_1095,
    Data1992_1096,
    Data1992_1097,
    Data1992_1098,
    Data1992_1099,
    Data1992_1100,
    Data1992_1101,
    Data1992_1102,
    Data1992_1103,
    Data1992_1104,
    Data1992_1105,
    Data1992_1106,
    Data1992_1107,
    Data1992_1108,
    Data1992_1109,
    Data1992_1110,
    Data1992_1111,
    Data1992_1112,
    Data1992_1113,
    Data1992_1114,
    Data1992_1115,
    Data1992_1116,
    Data1992_1117,
    Data1992_1118,
    Data1992_1119,
    Data1992_1120,
    Data1992_1121,
    Data1992_1122,
    Data1992_1123,
    Data1992_1124,
    Data1992_1125,
    Data1992_1126,
    Data1992_1127,
    Data1992_1128,
    Data1992_1129,
    Data1992_1130,
    Data1992_1131,
    Data1992_1132,
    Data1992_1133,
    Data1992_1134,
    Data1992_1135,
    Data1992_1136,
    Data1992_1137,
    Data1992_1138,
    Data1992_1139,
    Data1992_1140,
    Data1992_1141,
    Data1992_1142,
    Data1992_1143,
    Data1992_1144,
    Data1992_1145,
    Data1992_1146,
    Data1992_1147,
    Data1992_1148,
    Data1992_1149,
    Data1992_1150,
    Data1992_1151,
    Data1992_1152,
    Data1992_1153,
    Data1992_1154,
    Data1992_1155,
    Data1992_1156,
    Data1992_1157,
    Data1992_1158,
    Data1992_1159,
    Data1992_1160,
    Data1992_1161,
    Data1992_1162,
    Data1992_1163,
    Data1992_1164,
    Data1992_1165,
    Data1992_1166,
    Data1992_1167,
    Data1992_1168,
    Data1992_1169,
    Data1992_1170,
    Data1992_1171,
    Data1992_1172,
    Data1992_1173,
    Data1992_1174,
    Data1992_1175,
    Data1992_1176,
    Data1992_1177,
    Data1992_1178,
    Data1992_1179,
    Data1992_1180,
    Data1992_1181,
    Data1992_1182,
    Data1992_1183,
    Data1992_1184,
    Data1992_1185,
    Data1992_1186,
    Data1992_1187,
    Data1992_1188,
    Data1992_1189,
    Data1992_1190,
    Data1992_1191,
    Data1992_1192,
    Data1992_1193,
    Data1992_1194,
    Data1992_1195,
    Data1992_1196,
    Data1992_1197,
    Data1992_1198,
    Data1992_1199,
    Data1992_1200,
    Data1992_1201,
    Data1992_1202,
    Data1992_1203,
    Data1992_1204,
    Data1992_1205,
    Data1992_1206,
    Data1992_1207,
    Data1992_1208,
    Data1992_1209,
    Data1992_1210,
    Data1992_1211,
    Data1992_1212,
    Data1992_1213,
    Data1992_1214,
    Data1992_1215,
    Data1992_1216,
    Data1992_1217,
    Data1992_1218,
    Data1992_1219,
    Data1992_1220,
    Data1992_1221,
    Data1992_1222,
    Data1992_1223,
    Data1992_1224,
    Data1992_1225,
    Data1992_1226,
    Data1992_1227,
    Data1992_1228,
    Data1992_1229,
    Data1992_1230,
    Data1992_1231,
    Data1992_1232,
    Data1992_1233,
    Data1992_1234,
    Data1992_1235,
    Data1992_1236,
    Data1992_1237,
    Data1992_1238,
    Data1992_1239,
    Data1992_1240,
    Data1992_1241,
    Data1992_1242,
    Data1992_1243,
    Data1992_1244,
    Data1992_1245,
    Data1992_1246,
    Data1992_1247,
    Data1992_1248,
    Data1992_1249,
    Data1992_1250,
    Data1992_1251,
    Data1992_1252,
    Data1992_1253,
    Data1992_1254,
    Data1992_1255,
    Data1992_1256,
    Data1992_1257,
    Data1992_1258,
    Data1992_1259,
    Data1992_1260,
    Data1992_1261,
    Data1992_1262,
    Data1992_1263,
    Data1992_1264,
    Data1992_1265,
    Data1992_1266,
    Data1992_1267,
    Data1992_1268,
    Data1992_1269,
    Data1992_1270,
    Data1992_1271,
    Data1992_1272,
    Data1992_1273,
    Data1992_1274,
    Data1992_1275,
    Data1992_1276,
    Data1992_1277,
    Data1992_1278,
    Data1992_1279,
    Data1992_1280,
    Data1992_1281,
    Data1992_1282,
    Data1992_1283,
    Data1992_1284,
    Data1992_1285,
    Data1992_1286,
    Data1992_1287,
    Data1992_1288,
    Data1992_1289,
    Data1992_1290,
    Data1992_1291,
    Data1992_1292,
    Data1992_1293,
    Data1992_1294,
    Data1992_1295,
    Data1992_1296,
    Data1992_1297,
    Data1992_1298,
    Data1992_1299,
    Data1992_1300,
    Data1992_1301,
    Data1992_1302,
    Data1992_1303,
    Data1992_1304,
    Data1992_1305,
    Data1992_1306,
    Data1992_1307,
    Data1992_1308,
    Data1992_1309,
    Data1992_1310,
    Data1992_1311,
    Data1992_1312,
    Data1992_1313,
    Data1992_1314,
    Data1992_1315,
    Data1992_1316,
    Data1992_1317,
    Data1992_1318,
    Data1992_1319,
    Data1992_1320,
    Data1992_1321,
    Data1992_1322,
    Data1992_1323,
    Data1992_1324,
    Data1992_1325,
    Data1992_1326,
    Data1992_1327,
    Data1992_1328,
    Data1992_1329,
    Data1992_1330,
    Data1992_1331,
    Data1992_1332,
    Data1992_1333,
    Data1992_1334,
    Data1992_1335,
    Data1992_1336,
    Data1992_1337,
    Data1992_1338,
    Data1992_1339,
    Data1992_1340,
    Data1992_1341,
    Data1992_1342,
    Data1992_1343,
    Data1992_1344,
    Data1992_1345,
    Data1992_1346,
    Data1992_1347,
    Data1992_1348,
    Data1992_1349,
    Data1992_1350,
    Data1992_1351,
    Data1992_1352,
    Data1992_1353,
    Data1992_1354,
    Data1992_1355,
    Data1992_1356,
    Data1992_1357,
    Data1992_1358,
    Data1992_1359,
    Data1992_1360,
    Data1992_1361,
    Data1992_1362,
    Data1992_1363,
    Data1992_1364,
    Data1992_1365,
    Data1992_1366,
    Data1992_1367,
    Data1992_1368,
    Data1992_1369,
    Data1992_1370,
    Data1992_1371,
    Data1992_1372,
    Data1992_1373,
    Data1992_1374,
    Data1992_1375,
    Data1992_1376,
    Data1992_1377,
    Data1992_1378,
    Data1992_1379,
    Data1992_1380,
    Data1992_1381,
    Data1992_1382,
    Data1992_1383,
    Data1992_1384,
    Data1992_1385,
    Data1992_1386,
    Data1992_1387,
    Data1992_1388,
    Data1992_1389,
    Data1992_1390,
    Data1992_1391,
    Data1992_1392,
    Data1992_1393,
    Data1992_1394,
    Data1992_1395,
    Data1992_1396,
    Data1992_1397,
    Data1992_1398,
    Data1992_1399,
    Data1992_1400,
    Data1992_1401,
    Data1992_1402,
    Data1992_1403,
    Data1992_1404,
    Data1992_1405,
    Data1992_1406,
    Data1992_1407,
    Data1992_1408,
    Data1992_1409,
    Data1992_1410,
    Data1992_1411,
    Data1992_1412,
    Data1992_1413,
    Data1992_1414,
    Data1992_1415,
    Data1992_1416,
    Data1992_1417,
    Data1992_1418,
    Data1992_1419,
    Data1992_1420,
    Data1992_1421,
    Data1992_1422,
    Data1992_1423,
    Data1992_1424,
    Data1992_1425,
    Data1992_1426,
    Data1992_1427,
    Data1992_1428,
    Data1992_1429,
    Data1992_1430,
    Data1992_1431,
    Data1992_1432,
    Data1992_1433,
    Data1992_1434,
    Data1992_1435,
    Data1992_1436,
    Data1992_1437,
    Data1992_1438,
    Data1992_1439,
    Data1992_1440,
    Data1992_1441,
    Data1992_1442,
    Data1992_1443,
    Data1992_1444,
    Data1992_1445,
    Data1992_1446,
    Data1992_1447,
    Data1992_1448,
    Data1992_1449,
    Data1992_1450,
    Data1992_1451,
    Data1992_1452,
    Data1992_1453,
    Data1992_1454,
    Data1992_1455,
    Data1992_1456,
    Data1992_1457,
    Data1992_1458,
    Data1992_1459,
    Data1992_1460,
    Data1992_1461,
    Data1992_1462,
    Data1992_1463,
    Data1992_1464,
    Data1992_1465,
    Data1992_1466,
    Data1992_1467,
    Data1992_1468,
    Data1992_1469,
    Data1992_1470,
    Data1992_1471,
    Data1992_1472,
    Data1992_1473,
    Data1992_1474,
    Data1992_1475,
    Data1992_1476,
    Data1992_1477,
    Data1992_1478,
    Data1992_1479,
    Data1992_1480,
    Data1992_1481,
    Data1992_1482,
    Data1992_1483,
    Data1992_1484,
    Data1992_1485,
    Data1992_1486,
    Data1992_1487,
    Data1992_1488,
    Data1992_1489,
    Data1992_1490,
    Data1992_1491,
    Data1992_1492,
    Data1992_1493,
    Data1992_1494,
    Data1992_1495,
    Data1992_1496,
    Data1992_1497,
    Data1992_1498,
    Data1992_1499,
    Data1992_1500,
    Data1992_1501,
    Data1992_1502,
    Data1992_1503,
    Data1992_1504,
    Data1992_1505,
    Data1992_1506,
    Data1992_1507,
    Data1992_1508,
    Data1992_1509,
    Data1992_1510,
    Data1992_1511,
    Data1992_1512,
    Data1992_1513,
    Data1992_1514,
    Data1992_1515,
    Data1992_1516,
    Data1992_1517,
    Data1992_1518,
    Data1992_1519,
    Data1992_1520,
    Data1992_1521,
    Data1992_1522,
    Data1992_1523,
    Data1992_1524,
    Data1992_1525,
    Data1992_1526,
    Data1992_1527,
    Data1992_1528,
    Data1992_1529,
    Data1992_1530,
    Data1992_1531,
    Data1992_1532,
    Data1992_1533,
    Data1992_1534,
    Data1992_1535,
    Data1992_1536,
    Data1992_1537,
    Data1992_1538,
    Data1992_1539,
    Data1992_1540,
    Data1992_1541,
    Data1992_1542,
    Data1992_1543,
    Data1992_1544,
    Data1992_1545,
    Data1992_1546,
    Data1992_1547,
    Data1992_1548,
    Data1992_1549,
    Data1992_1550,
    Data1992_1551,
    Data1992_1552,
    Data1992_1553,
    Data1992_1554,
    Data1992_1555,
    Data1992_1556,
    Data1992_1557,
    Data1992_1558,
    Data1992_1559,
    Data1992_1560,
    Data1992_1561,
    Data1992_1562,
    Data1992_1563,
    Data1992_1564,
    Data1992_1565,
    Data1992_1566,
    Data1992_1567,
    Data1992_1568,
    Data1992_1569,
    Data1992_1570,
    Data1992_1571,
    Data1992_1572,
    Data1992_1573,
    Data1992_1574,
    Data1992_1575,
    Data1992_1576,
    Data1992_1577,
    Data1992_1578,
    Data1992_1579,
    Data1992_1580,
    Data1992_1581,
    Data1992_1582,
    Data1992_1583,
    Data1992_1584,
    Data1992_1585,
    Data1992_1586,
    Data1992_1587,
    Data1992_1588,
    Data1992_1589,
    Data1992_1590,
    Data1992_1591,
    Data1992_1592,
    Data1992_1593,
    Data1992_1594,
    Data1992_1595,
    Data1992_1596,
    Data1992_1597,
    Data1992_1598,
    Data1992_1599,
    Data1992_1600,
    Data1992_1601,
    Data1992_1602,
    Data1992_1603,
    Data1992_1604,
    Data1992_1605,
    Data1992_1606,
    Data1992_1607,
    Data1992_1608,
    Data1992_1609,
    Data1992_1610,
    Data1992_1611,
    Data1992_1612,
    Data1992_1613,
    Data1992_1614,
    Data1992_1615,
    Data1992_1616,
    Data1992_1617,
    Data1992_1618,
    Data1992_1619,
    Data1992_1620,
    Data1992_1621,
    Data1992_1622,
    Data1992_1623,
    Data1992_1624,
    Data1992_1625,
    Data1992_1626,
    Data1992_1627,
    Data1992_1628,
    Data1992_1629,
    Data1992_1630,
    Data1992_1631,
    Data1992_1632,
    Data1992_1633,
    Data1992_1634,
    Data1992_1635,
    Data1992_1636,
    Data1992_1637,
    Data1992_1638,
    Data1992_1639,
    Data1992_1640,
    Data1992_1641,
    Data1992_1642,
    Data1992_1643,
    Data1992_1644,
    Data1992_1645,
    Data1992_1646,
    Data1992_1647,
    Data1992_1648,
    Data1992_1649,
    Data1992_1650,
    Data1992_1651,
    Data1992_1652,
    Data1992_1653,
    Data1992_1654,
    Data1992_1655,
    Data1992_1656,
    Data1992_1657,
    Data1992_1658,
    Data1992_1659,
    Data1992_1660,
    Data1992_1661,
    Data1992_1662,
    Data1992_1663,
    Data1992_1664,
    Data1992_1665,
    Data1992_1666,
    Data1992_1667,
    Data1992_1668,
    Data1992_1669,
    Data1992_1670,
    Data1992_1671,
    Data1992_1672,
    Data1992_1673,
    Data1992_1674,
    Data1992_1675,
    Data1992_1676,
    Data1992_1677,
    Data1992_1678,
    Data1992_1679,
    Data1992_1680,
    Data1992_1681,
    Data1992_1682,
    Data1992_1683,
    Data1992_1684,
    Data1992_1685,
    Data1992_1686,
    Data1992_1687,
    Data1992_1688,
    Data1992_1689,
    Data1992_1690,
    Data1992_1691,
    Data1992_1692,
    Data1992_1693,
    Data1992_1694,
    Data1992_1695,
    Data1992_1696,
    Data1992_1697,
    Data1992_1698,
    Data1992_1699,
    Data1992_1700,
    Data1992_1701,
    Data1992_1702,
    Data1992_1703,
    Data1992_1704,
    Data1992_1705,
    Data1992_1706,
    Data1992_1707,
    Data1992_1708,
    Data1992_1709,
    Data1992_1710,
    Data1992_1711,
    Data1992_1712,
    Data1992_1713,
    Data1992_1714,
    Data1992_1715,
    Data1992_1716,
    Data1992_1717,
    Data1992_1718,
    Data1992_1719,
    Data1992_1720,
    Data1992_1721,
    Data1992_1722,
    Data1992_1723,
    Data1992_1724,
    Data1992_1725,
    Data1992_1726,
    Data1992_1727,
    Data1992_1728,
    Data1992_1729,
    Data1992_1730,
    Data1992_1731,
    Data1992_1732,
    Data1992_1733,
    Data1992_1734,
    Data1992_1735,
    Data1992_1736,
    Data1992_1737,
    Data1992_1738,
    Data1992_1739,
    Data1992_1740,
    Data1992_1741,
    Data1992_1742,
    Data1992_1743,
    Data1992_1744,
    Data1992_1745,
    Data1992_1746,
    Data1992_1747,
    Data1992_1748,
    Data1992_1749,
    Data1992_1750,
    Data1992_1751,
    Data1992_1752,
    Data1992_1753,
    Data1992_1754,
    Data1992_1755,
    Data1992_1756,
    Data1992_1757,
    Data1992_1758,
    Data1992_1759,
    Data1992_1760,
    Data1992_1761,
    Data1992_1762,
    Data1992_1763,
    Data1992_1764,
    Data1992_1765,
    Data1992_1766,
    Data1992_1767,
    Data1992_1768,
    Data1992_1769,
    Data1992_1770,
    Data1992_1771,
    Data1992_1772,
    Data1992_1773,
    Data1992_1774,
    Data1992_1775,
    Data1992_1776,
    Data1992_1777,
    Data1992_1778,
    Data1992_1779,
    Data1992_1780,
    Data1992_1781,
    Data1992_1782,
    Data1992_1783,
    Data1992_1784,
    Data1992_1785,
    Data1992_1786,
    Data1992_1787,
    Data1992_1788,
    Data1992_1789,
    Data1992_1790,
    Data1992_1791,
    Data1992_1792,
    Data1992_1793,
    Data1992_1794,
    Data1992_1795,
    Data1992_1796,
    Data1992_1797,
    Data1992_1798,
    Data1992_1799,
    Data1992_1800,
    Data1992_1801,
    Data1992_1802,
    Data1992_1803,
    Data1992_1804,
    Data1992_1805,
    Data1992_1806,
    Data1992_1807,
    Data1992_1808,
    Data1992_1809,
    Data1992_1810,
    Data1992_1811,
    Data1992_1812,
    Data1992_1813,
    Data1992_1814,
    Data1992_1815,
    Data1992_1816,
    Data1992_1817,
    Data1992_1818,
    Data1992_1819,
    Data1992_1820,
    Data1992_1821,
    Data1992_1822,
    Data1992_1823,
    Data1992_1824,
    Data1992_1825,
    Data1992_1826,
    Data1992_1827,
    Data1992_1828,
    Data1992_1829,
    Data1992_1830,
    Data1992_1831,
    Data1992_1832,
    Data1992_1833,
    Data1992_1834,
    Data1992_1835,
    Data1992_1836,
    Data1992_1837,
    Data1992_1838,
    Data1992_1839,
    Data1992_1840,
    Data1992_1841,
    Data1992_1842,
    Data1992_1843,
    Data1992_1844,
    Data1992_1845,
    Data1992_1846,
    Data1992_1847,
    Data1992_1848,
    Data1992_1849,
    Data1992_1850,
    Data1992_1851,
    Data1992_1852,
    Data1992_1853,
    Data1992_1854,
    Data1992_1855,
    Data1992_1856,
    Data1992_1857,
    Data1992_1858,
    Data1992_1859,
    Data1992_1860,
    Data1992_1861,
    Data1992_1862,
    Data1992_1863,
    Data1992_1864,
    Data1992_1865,
    Data1992_1866,
    Data1992_1867,
    Data1992_1868,
    Data1992_1869,
    Data1992_1870,
    Data1992_1871,
    Data1992_1872,
    Data1992_1873,
    Data1992_1874,
    Data1992_1875,
    Data1992_1876,
    Data1992_1877,
    Data1992_1878,
    Data1992_1879,
    Data1992_1880,
    Data1992_1881,
    Data1992_1882,
    Data1992_1883,
    Data1992_1884,
    Data1992_1885,
    Data1992_1886,
    Data1992_1887,
    Data1992_1888,
    Data1992_1889,
    Data1992_1890,
    Data1992_1891,
    Data1992_1892,
    Data1992_1893,
    Data1992_1894,
    Data1992_1895,
    Data1992_1896,
    Data1992_1897,
    Data1992_1898,
    Data1992_1899,
    Data1992_1900,
    Data1992_1901,
    Data1992_1902,
    Data1992_1903,
    Data1992_1904,
    Data1992_1905,
    Data1992_1906,
    Data1992_1907,
    Data1992_1908,
    Data1992_1909,
    Data1992_1910,
    Data1992_1911,
    Data1992_1912,
    Data1992_1913,
    Data1992_1914,
    Data1992_1915,
    Data1992_1916,
    Data1992_1917,
    Data1992_1918,
    Data1992_1919,
    Data1992_1920,
    Data1992_1921,
    Data1992_1922,
    Data1992_1923,
    Data1992_1924,
    Data1992_1925,
    Data1992_1926,
    Data1992_1927,
    Data1992_1928,
    Data1992_1929,
    Data1992_1930,
    Data1992_1931,
    Data1992_1932,
    Data1992_1933,
    Data1992_1934,
    Data1992_1935,
    Data1992_1936,
    Data1992_1937,
    Data1992_1938,
    Data1992_1939,
    Data1992_1940,
    Data1992_1941,
    Data1992_1942,
    Data1992_1943,
    Data1992_1944,
    Data1992_1945,
    Data1992_1946,
    Data1992_1947,
    Data1992_1948,
    Data1992_1949,
    Data1992_1950,
    Data1992_1951,
    Data1992_1952,
    Data1992_1953,
    Data1992_1954,
    Data1992_1955,
    Data1992_1956,
    Data1992_1957,
    Data1992_1958,
    Data1992_1959,
    Data1992_1960,
    Data1992_1961,
    Data1992_1962,
    Data1992_1963,
    Data1992_1964,
    Data1992_1965,
    Data1992_1966,
    Data1992_1967,
    Data1992_1968,
    Data1992_1969,
    Data1992_1970,
    Data1992_1971,
    Data1992_1972,
    Data1992_1973,
    Data1992_1974,
    Data1992_1975,
    Data1992_1976,
    Data1992_1977,
    Data1992_1978,
    Data1992_1979,
    Data1992_1980,
    Data1992_1981,
    Data1992_1982,
    Data1992_1983,
    Data1992_1984,
    Data1992_1985,
    Data1992_1986,
    Data1992_1987,
    Data1992_1988,
    Data1992_1989,
    Data1992_1990,
    Data1992_1991,
    Data1992_1992
  ]
  
  public static let Weights1992: [Double] =
  [
    1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 1.665264, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.517726, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.489794, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.205193, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 1.146566, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.973349, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456, 0.552456
 ]
}

