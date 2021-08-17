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


/// Geometry data for a repeatedly bi-sected sphere
/// - note:
/// Draw using 'drawIndexedPrimitives' with type '.triangle' and setCullMode(MTLCullMode.back).
/// More information:
///
/// Paul Bourke: http://paulbourke.net/geometry/circlesphere/csource3.c
public class MetalNSphereGeometry
{
  public var numberOfIndices: Int = 0
  public var numberOfVertexes: Int = 0
  
  public var vertices: [RKPrimitiveVertex]
  public var indices: [UInt16]
  
  public init(r: Double, color: SIMD4<Float>, iterations: Int)
  {
    // use an octohedron as the start object to eliminate the non-uniformity of the facets
    let octahedron: MetalOctahedronGeometry = MetalOctahedronGeometry(radius: 1.0, color: color)
    vertices = octahedron.indices.map{octahedron.vertices[Int($0)]}
    indices = []
   
    for _ in 0..<iterations
    {
      let currentNumberOfTriangles = vertices.count / 3
      for i in 0..<currentNumberOfTriangles
      {
        let pos1: SIMD3<Float> = normalize(SIMD3<Float>(x: 0.5 * (vertices[3*i].position.x + vertices[3*i+1].position.x),
                                                        y: 0.5 * (vertices[3*i].position.y + vertices[3*i+1].position.y),
                                                        z: 0.5 * (vertices[3*i].position.z + vertices[3*i+1].position.z)))
        
        let pos2: SIMD3<Float> = normalize(SIMD3<Float>(x: 0.5 * (vertices[3*i+1].position.x + vertices[3*i+2].position.x),
                                                        y: 0.5 * (vertices[3*i+1].position.y + vertices[3*i+2].position.y),
                                                        z: 0.5 * (vertices[3*i+1].position.z + vertices[3*i+2].position.z)))
        
        let pos3: SIMD3<Float> = normalize(SIMD3<Float>(x: 0.5 * (vertices[3*i+2].position.x + vertices[3*i].position.x),
                                                        y: 0.5 * (vertices[3*i+2].position.y + vertices[3*i].position.y),
                                                        z: 0.5 * (vertices[3*i+2].position.z + vertices[3*i].position.z)))
                                              
        vertices.append(vertices[3*i])
        vertices.append(RKPrimitiveVertex(position: SIMD4<Float>(x: pos1.x, y: pos1.y, z: pos1.z, w: 0.0), normal: SIMD4<Float>(x: pos1.x, y: pos1.y, z: pos1.z, w: 0.0), color: color, st: SIMD2<Float>()))
        vertices.append(RKPrimitiveVertex(position: SIMD4<Float>(x: pos3.x, y: pos3.y, z: pos3.z, w: 0.0), normal: SIMD4<Float>(x: pos3.x, y: pos3.y, z: pos3.z, w: 0.0), color: color, st: SIMD2<Float>()))
                        
        vertices.append(RKPrimitiveVertex(position: SIMD4<Float>(x: pos1.x, y: pos1.y, z: pos1.z, w: 0.0), normal: SIMD4<Float>(x: pos1.x, y: pos1.y, z: pos1.z, w: 0.0), color: color, st: SIMD2<Float>()))
        vertices.append(vertices[3*i+1])
        vertices.append(RKPrimitiveVertex(position: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: 0.0), normal: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: 0.0), color: color, st: SIMD2<Float>()))
     
        vertices.append(RKPrimitiveVertex(position: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: 0.0), normal: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: 0.0), color: color, st: SIMD2<Float>()))
        vertices.append(vertices[3*i+2])
        vertices.append(RKPrimitiveVertex(position: SIMD4<Float>(x: pos3.x, y: pos3.y, z: pos3.z, w: 0.0), normal: SIMD4<Float>(x: pos3.x, y: pos3.y, z: pos3.z, w: 0.0), color: color, st: SIMD2<Float>()))
  
        vertices[3*i] = RKPrimitiveVertex(position: SIMD4<Float>(x: pos1.x, y: pos1.y, z: pos1.z, w: 0.0), normal: SIMD4<Float>(x: pos1.x, y: pos1.y, z: pos1.z, w: 0.0), color: color, st: SIMD2<Float>())
        vertices[3*i+1] = RKPrimitiveVertex(position: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: 0.0), normal: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: 0.0), color: color, st: SIMD2<Float>())
        vertices[3*i+2] = RKPrimitiveVertex(position: SIMD4<Float>(x: pos3.x, y: pos3.y, z: pos3.z, w: 0.0), normal: SIMD4<Float>(x: pos3.x, y: pos3.y, z: pos3.z, w: 0.0), color: color, st: SIMD2<Float>())
       }
    }
    indices = Array(UInt16(0)..<UInt16(vertices.count))
    
    for i in 0..<vertices.count
    {
      vertices[i].position *= Float(r)
    }
   
    numberOfVertexes = vertices.count
    numberOfIndices = indices.count
  }
}
