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
import Metal
import simd

public class MetalNSidedPrismGeometry
{
  var slices: Int
  public var numberOfIndices: Int
  public var numberOfVertexes: Int
  
  public var vertices: [RKVertex]
  public var indices: [UInt16]
  
  public convenience init()
  {
    self.init(r: 1.0, s: 20)
  }
  
  public init(r: Double, s: Int)
  {
    slices = s
    numberOfVertexes = 6 * slices
    numberOfIndices = 6 * slices
    
    vertices = [RKVertex](repeating: RKVertex(), count: numberOfVertexes)
    indices = [UInt16](repeating: UInt16(0), count: numberOfIndices)
    
    let delta: Double = 2.0 * Double.pi / Double(slices)
    
    var index: Int = 0
    for i in 0..<slices
    {
      let cosTheta: Double = cos(delta * Double(i))
      let sinTheta: Double = sin(delta * Double(i))
      
      let cosTheta2: Double = cos(delta * Double(i+1))
      let sinTheta2: Double = sin(delta * Double(i+1))
      
      let position1: SIMD4<Float> = SIMD4<Float>(x: Float(r * cosTheta), y: 1.0, z: Float(r * sinTheta), w: 0.0)
      let position2: SIMD4<Float> = SIMD4<Float>(x: Float(r * cosTheta), y: -1.0, z: Float(r * sinTheta), w: 0.0)
      let position3: SIMD4<Float> = SIMD4<Float>(x: Float(r * cosTheta2), y: 1.0, z: Float(r * sinTheta2), w: 0.0)
      let v1: SIMD4<Float> = position2 - position1
      let w1: SIMD4<Float> = position2 - position3
      let normal1: SIMD3<Float> = normalize(cross(SIMD3<Float>(v1.x,v1.y,v1.z), SIMD3<Float>(w1.x,w1.y,w1.z)))
      
      vertices[index] = RKVertex(position: position1, normal: SIMD4<Float>(normal1.x,normal1.y,normal1.z,0.0), st: SIMD2<Float>())
      indices[index] = UInt16(index)
      index = index + 1
      
      vertices[index] = RKVertex(position: position2, normal: SIMD4<Float>(normal1.x,normal1.y,normal1.z,0.0), st: SIMD2<Float>())
      indices[index] = UInt16(index)
      index = index + 1
      
      vertices[index] = RKVertex(position: position3, normal: SIMD4<Float>(normal1.x,normal1.y,normal1.z,0.0), st: SIMD2<Float>())
      indices[index] = UInt16(index)
      index = index + 1
      
      let position4: SIMD4<Float> = SIMD4<Float>(x: Float(r * cosTheta2), y: 1.0, z: Float(r * sinTheta2), w: 0.0)
      let position5: SIMD4<Float> = SIMD4<Float>(x: Float(r * cosTheta), y: -1.0, z: Float(r * sinTheta), w: 0.0)
      let position6: SIMD4<Float> = SIMD4<Float>(x: Float(r * cosTheta2), y: -1.0, z: Float(r * sinTheta2), w: 0.0)
      let v2: SIMD4<Float> = position5 - position4
      let w2: SIMD4<Float> = position5 - position6
      let normal2: SIMD3<Float> = normalize(cross(SIMD3<Float>(v2.x,v2.y,v2.z), SIMD3<Float>(w2.x,w2.y,w2.z)))
      
      vertices[index] = RKVertex(position: position4, normal: SIMD4<Float>(normal2.x,normal2.y,normal2.z,0.0), st: SIMD2<Float>())
      indices[index] = UInt16(index)
      index = index + 1
      
      vertices[index] = RKVertex(position: position5, normal: SIMD4<Float>(normal2.x,normal2.y,normal2.z,0.0), st: SIMD2<Float>())
      indices[index] = UInt16(index)
      index = index + 1
      
      vertices[index] = RKVertex(position: position6, normal: SIMD4<Float>(normal2.x,normal2.y,normal2.z,0.0), st: SIMD2<Float>())
      indices[index] = UInt16(index)
      index = index + 1
    }
  }
}

