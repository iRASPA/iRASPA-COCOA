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
import Metal
import simd

// Paul Bourke
// http://paulbourke.net/geometry/circlesphere/opengl.c
/*
 void CreateCone(XYZ p1,XYZ p2,double r1,double r2,int m,
    double theta1,double theta2)
 {
    int i,j;
    double theta;
    XYZ n,p,q,perp;

    /* Normal pointing from p1 to p2 */
    n.x = p1.x - p2.x;
    n.y = p1.y - p2.y;
    n.z = p1.z - p2.z;

    /*
       Create two perpendicular vectors perp and q
       on the plane of the disk
    */
    perp = n;
    if (n.x == 0 && n.z == 0)
       perp.x += 1;
    else
       perp.y += 1;
    CROSSPROD(perp,n,q);
    CROSSPROD(n,q,perp);
    Normalise(&perp);
    Normalise(&q);

    glBegin(GL_QUAD_STRIP);
    for (i=0;i<=m;i++) {
       theta = theta1 + i * (theta2 - theta1) / m;

       n.x = cos(theta) * perp.x + sin(theta) * q.x;
       n.y = cos(theta) * perp.y + sin(theta) * q.y;
       n.z = cos(theta) * perp.z + sin(theta) * q.z;
       Normalise(&n);

       p.x = p2.x + r2 * n.x;
       p.y = p2.y + r2 * n.y;
       p.z = p2.z + r2 * n.z;
       glNormal3f(n.x,n.y,n.z);
       glTexCoord2f(i/(double)m,1.0);
       glVertex3f(p.x,p.y,p.z);

       p.x = p1.x + r1 * n.x;
       p.y = p1.y + r1 * n.y;
       p.z = p1.z + r1 * n.z;
       glNormal3f(n.x,n.y,n.z);
       glTexCoord2f(i/(double)m,0.0);
       glVertex3f(p.x,p.y,p.z);
    }
    glEnd();
 }

 */

public class MetalCappedConeGeometry
{
  var slices: Int
  public var numberOfIndices: Int
  public var numberOfVertexes: Int
  
  public var vertices: [RKVertex]
  public var indices: [UInt16]
  
  public convenience init()
  {
    self.init(r: 1.0, s: 21)
  }
  
  public init(r: Double, s: Int)
  {
    slices = s
    numberOfVertexes = 4 * slices + 2
    numberOfIndices = 12 * slices
    
    vertices = [RKVertex](repeating: RKVertex(), count: numberOfVertexes)
    indices = [UInt16](repeating: UInt16(), count: numberOfIndices)
    
    let delta: Double = 2.0 * Double.pi / Double(slices)
    
    var index: Int = 0
    for i in 0..<slices
    {
      let cosTheta: Double = cos(delta * Double(i))
      let sinTheta: Double = sin(delta * Double(i))
      
      let position2: SIMD4<Float> = SIMD4<Float>(x: Float(r * cosTheta), y: 1.0, z: Float(r * sinTheta), w: 0.0)
      let normal2: SIMD4<Float> = SIMD4<Float>(x: Float(cosTheta), y: 0.0, z: Float(sinTheta), w: 0.0)
      vertices[index] = RKVertex(position: position2, normal: normal2, st: SIMD2<Float>())
      index = index + 1
      
      let position1: SIMD4<Float> = SIMD4<Float>(x: Float(r * cosTheta), y: -1.0, z: Float(r * sinTheta), w: 0.0)
      let normal1: SIMD4<Float> = SIMD4<Float>(x: Float(cosTheta), y: 0.0, z: Float(sinTheta), w: 0.0)
      vertices[index] = RKVertex(position: position1, normal: normal1, st: SIMD2<Float>())
      index = index + 1
      
      
    }
    
    // first cap
    // ==========================================================================
    
    let position_cap1: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: -1.0, z: 0.0, w: 0.0)
    let normal_cap1: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: -1.0, z: 0.0, w: 0.0)
    vertices[index] = RKVertex(position: position_cap1, normal: normal_cap1, st: SIMD2<Float>())
    let ref_cap_1: Int = index;
    index = index + 1
    
    
    for i in 0..<slices
    {
      let cosTheta: Double = r * cos(delta * Double(i))
      let sinTheta: Double = r * sin(delta * Double(i))
      let position_cap1: SIMD4<Float> = SIMD4<Float>(x: Float(cosTheta), y: -1.0, z: Float(sinTheta), w: 0.0)
      let normal_cap1: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: -1.0, z: 0.0, w: 0.0)
      vertices[index] = RKVertex(position: position_cap1, normal: normal_cap1, st: SIMD2<Float>())
      index = index + 1
    }
    
    // second cap
    // ==========================================================================
    
    let position_cap2: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 1.0, z: 0.0, w: 0.0)
    let normal_cap2: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 1.0, z: 0.0, w: 0.0)
    vertices[index] = RKVertex(position: position_cap2, normal: normal_cap2, st: SIMD2<Float>())
    let ref_cap_2: Int = index;
    index = index + 1
    
    for i in 0..<slices
    {
      let cosTheta: Double = r * cos(delta * Double(i))
      let sinTheta: Double = r * sin(delta * Double(i))
      let position_cap2: SIMD4<Float> = SIMD4<Float>(x: Float(cosTheta), y: 1.0, z: Float(sinTheta), w: 0.0)
      let normal_cap2: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 1.0, z: 0.0, w: 0.0)
      vertices[index] = RKVertex(position: position_cap2, normal: normal_cap2, st: SIMD2<Float>())
      index = index + 1
    }
    
    index = 0
    for i in 0..<slices
    {
      indices[index]=UInt16((2 * i) % (2 * slices))
      index = index + 1
      indices[index]=UInt16((2 * i + 1) % (2 * slices))
      index = index + 1
      indices[index]=UInt16((2 * i + 2) % (2 * slices))
      index = index + 1
      indices[index]=UInt16((2 * i + 2) % (2 * slices))
      index = index + 1
      indices[index]=UInt16((2 * i + 1) % (2 * slices))
      index = index + 1
      indices[index]=UInt16((2 * i + 3) % (2 * slices))
      index = index + 1
    }
    
    // first cap
    // ==========================================================================
    
    for i in 0..<slices
    {
      indices[index]=UInt16(ref_cap_1)
      index = index + 1
      indices[index]=UInt16(ref_cap_1 + 1 + ((i + 1) % slices))
      index = index + 1
      indices[index]=UInt16(ref_cap_1 + 1 + ((i) % slices))
      index = index + 1
    }
    
    // second cap
    // ==========================================================================
    
    for i in 0..<slices
    {
      indices[index]=UInt16(ref_cap_2)
      index = index + 1
      indices[index]=UInt16(ref_cap_2 + 1 + ((i) % slices))
      index = index + 1
      indices[index]=UInt16(ref_cap_2 + 1 + ((i + 1) % slices))
      index = index + 1
    }
  }
}
