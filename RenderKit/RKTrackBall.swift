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
import MathKit

public class RKTrackBall
{
  let kTol: Double = 0.001
  let kRad2Deg: Double = 180.0 / 3.1415927
  let kDeg2Rad: Double = 3.1415927 / 180.0
  
  var gRadiusTrackball: Double = 0
  var gStartPtTrackball: SIMD3<Double> = SIMD3<Double>()
  var gEndPtTrackball: SIMD3<Double> = SIMD3<Double>()
  
  var gXCenterTrackball: Double = 0
  var gYCenterTrackball: Double = 0
  
  public init()
  {
    
  }
  
  public func start(x: CGFloat, y: CGFloat, originX: CGFloat, originY: CGFloat, width: CGFloat, height: CGFloat)
  {
    var xxyy: Double = 0
    var nx: Double = 0
    var ny: Double = 0
    
    /* Start up the trackball.  The trackball works by pretending that a ball
     encloses the 3D view.  You roll this pretend ball with the mouse.  For
     example, if you click on the center of the ball and move the mouse straight
     to the right, you roll the ball around its Y-axis.  This produces a Y-axis
     rotation.  You can click on the "edge" of the ball and roll it around
     in a circle to get a Z-axis rotation.
     
     The math behind the trackball is simple: start with a vector from the first
     mouse-click on the ball to the center of the 3D view.  At the same time, set the radius
     of the ball to be the smaller dimension of the 3D view.  As you drag the mouse
     around in the 3D view, a second vector is computed from the surface of the ball
     to the center.  The axis of rotation is the cross product of these two vectors,
     and the angle of rotation is the angle between the two vectors.
     */
    nx = Double(width)
    ny = Double(height)
    if (nx > ny)
    {
      gRadiusTrackball = Double(ny * 0.5)
    }
    else
    {
      gRadiusTrackball = Double(nx * 0.5)
    }
    
    // Figure the center of the view.
    gXCenterTrackball = Double(originX) + Double(width) * 0.5
    gYCenterTrackball = Double(originY) + Double(height) * 0.5
    
    // Compute the starting vector from the surface of the ball to its center.
    gStartPtTrackball.x = Double(x) - gXCenterTrackball
    gStartPtTrackball.y = Double(y) - gYCenterTrackball
    xxyy = gStartPtTrackball.x * gStartPtTrackball.x + gStartPtTrackball.y * gStartPtTrackball.y
    if (xxyy > gRadiusTrackball * gRadiusTrackball)
    {
      // Outside the sphere.
      gStartPtTrackball.z = 0.0;
    }
    else
    {
      gStartPtTrackball.z = sqrt (gRadiusTrackball * gRadiusTrackball - xxyy);
    }
  }
  
  public func rollToTrackball(x: CGFloat, y: CGFloat) -> simd_quatd
  {
    var rot: SIMD3<Double> = SIMD3<Double>()
    var xxyy: Double
    var cosAng: Double
    var sinAng: Double
    var ls, le: Double
    var rotationAngle: Double
    
    gEndPtTrackball.x = Double(x) - gXCenterTrackball;
    gEndPtTrackball.y = Double(y) - gYCenterTrackball;
    gEndPtTrackball.z = gYCenterTrackball - Double(y);
    
    if (fabs(gEndPtTrackball.x - gStartPtTrackball.x) < kTol && fabs(gEndPtTrackball.y - gStartPtTrackball.y) < kTol)
    {
      return simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
      //return Quaternion(x: 0.0, y: 0.0, z: 0.0, w: 1.0); // Not enough change in the vectors to have an action.
    }
    
    // Compute the ending vector from the surface of the ball to its center.
    xxyy = gEndPtTrackball.x * gEndPtTrackball.x + gEndPtTrackball.y * gEndPtTrackball.y
    if (xxyy > gRadiusTrackball * gRadiusTrackball)
    {
      // Outside the sphere.
      gEndPtTrackball.z = 0.0;
    }
    else
    {
      gEndPtTrackball.z = sqrt(gRadiusTrackball * gRadiusTrackball - xxyy)
    }
    
    // Take the cross product of the two vectors. r = s X e
    rot=SIMD3<Double>(x: gStartPtTrackball.y * gEndPtTrackball.z - gStartPtTrackball.z * gEndPtTrackball.y,
                y: gStartPtTrackball.z * gEndPtTrackball.x - gStartPtTrackball.x * gEndPtTrackball.z,
                z: gStartPtTrackball.x * gEndPtTrackball.y - gStartPtTrackball.y * gEndPtTrackball.x)
    
    // Use atan for a better angle.  If you use only cos or sin, you only get
    // half the possible angles, and you can end up with rotations that flip around near
    // the poles.
    
    // cos(a) = (s . e) / (||s|| ||e||)
    cosAng = gStartPtTrackball.x * gEndPtTrackball.x + gStartPtTrackball.y * gEndPtTrackball.y + gStartPtTrackball.z * gEndPtTrackball.z // (s . e)
    ls = sqrt(gStartPtTrackball.x * gStartPtTrackball.x + gStartPtTrackball.y * gStartPtTrackball.y + gStartPtTrackball.z * gStartPtTrackball.z)
    ls = 1.0 / ls; // 1 / ||s||
    le = sqrt(gEndPtTrackball.x * gEndPtTrackball.x + gEndPtTrackball.y * gEndPtTrackball.y + gEndPtTrackball.z * gEndPtTrackball.z)
    le = 1.0 / le; // 1 / ||e||
    cosAng = cosAng * ls * le;
    
    // sin(a) = ||(s X e)|| / (||s|| ||e||)
    sinAng = sqrt(rot.x * rot.x + rot.y * rot.y + rot.z * rot.z) // ||(s X e)||;
    
    // keep this length in lr for normalizing the rotation vector later.
    sinAng = sinAng * ls * le;
    rotationAngle = atan2(sinAng, cosAng);
    
    // Return normalize the rotation axis.
    return simd_quaternion(rotationAngle, normalize(rot))
    //return Quaternion(axis: normalize(rot), rotationAngle: rotationAngle)
  }
}
