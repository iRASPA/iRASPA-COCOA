/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

/// Geometry data for an octahedron
/// - note:
/// The orientation (0,1,0) is along the y-axis.
/// Draw using 'drawIndexedPrimitives' with type '.triangle' and setCullMode(MTLCullMode.back).
/// More information:
///
/// http://paulbourke.net/geometry/circlesphere/csource3.c
public class MetalOctahedronGeometry
{
  public let numberOfIndices: Int = 24
  public let numberOfVertexes: Int = 6
  
  public var indices: [UInt16] =
    [
      0, 3, 4,      // Face 0 - triangle ( v0,  v3,  v3)
      0, 4, 5,      // Face 1 - triangle ( v0,  v4,  v5)
      0, 5, 2,      // Face 2 - triangle ( v0,  v5,  v2)
      0, 2, 3,      // Face 3 - triangle ( v0,  v2,  v3)
      1, 4, 3,      // Face 4 - triangle ( v1,  v4,  v3)
      1, 5, 4,      // Face 5 - triangle ( v1,  v5,  v4)
      1, 2, 5,      // Face 6 - triangle ( v1,  v2,  v5)
      1, 3, 2       // Face 7 - triangle ( v1,  v3,  v2)
  ]
  
  public var vertices: [RKPrimitiveVertex]
    
  init(radius r: Double, color: SIMD4<Float>)
  {
  vertices = [
    RKPrimitiveVertex(position: SIMD4<Float>(x: 0.0, y: 0.0, z: r, w: 0.0), normal: SIMD4<Float>(x: 0.0, y: 0.0, z: 1.0, w: 0.0), color: color, st: SIMD2<Float>()),
    RKPrimitiveVertex(position: SIMD4<Float>(x: 0.0, y: 0.0, z: -r, w: 0.0), normal: SIMD4<Float>(x: 0.0, y: 0.0, z: -1.0, w: 0.0), color: color, st: SIMD2<Float>()),
    RKPrimitiveVertex(position: SIMD4<Float>(x: r / sqrt(2.0), y: -r / sqrt(2.0), z: 0.0, w: 0.0), normal: SIMD4<Float>(x: 1.0 / sqrt(2.0), y: -1.0 / sqrt(2.0), z: 0.0, w: 0.0),  color: color, st: SIMD2<Float>()),
    RKPrimitiveVertex(position: SIMD4<Float>(x: -r / sqrt(2.0), y: -r / sqrt(2.0), z: 0.0, w: 0.0), normal: SIMD4<Float>(x: -1.0 / sqrt(2.0), y: -1.0 / sqrt(2.0), z: 0.0, w: 0.0),  color: color, st: SIMD2<Float>()),
    RKPrimitiveVertex(position: SIMD4<Float>(x: -r / sqrt(2.0), y: r / sqrt(2.0), z: 0.0, w: 0.0), normal: SIMD4<Float>(x: -1.0 / sqrt(2.0), y: 1.0 / sqrt(2.0), z: 0.0, w: 0.0),  color: color,st: SIMD2<Float>()),
    RKPrimitiveVertex(position: SIMD4<Float>(x: r / sqrt(2.0), y: r / sqrt(2.0), z: 0.0, w: 0.0), normal: SIMD4<Float>(x: 1.0 / sqrt(2.0), y: 1.0 / sqrt(2.0), z: 0.0, w: 0.0),  color: color, st: SIMD2<Float>())
    ]
  }
}
