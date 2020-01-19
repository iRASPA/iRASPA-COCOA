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
import Metal
import simd

public class MetalCylinderGeometry
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
    numberOfVertexes = 2 * slices
    numberOfIndices = 6 * slices
    
    vertices = [RKVertex](repeating: RKVertex(), count: numberOfVertexes)
    indices = [UInt16](repeating: UInt16(), count: numberOfIndices)
    
    let delta: Double = 2.0 * Double.pi / Double(slices)
    
    var index: Int = 0
    for i in 0..<slices
    {
      let cosTheta: Double = cos(delta * Double(i))
      let sinTheta: Double = sin(delta * Double(i))
      
      let normal2:  SIMD4<Float> =  SIMD4<Float>(x: Float(cosTheta), y: 0.0, z: Float(sinTheta), w: 0.0)
      let position2:  SIMD4<Float> =  SIMD4<Float>(x: Float(r * cosTheta), y: 1.0, z: Float(r * sinTheta), w: 0.0)
      vertices[index] = RKVertex(position: position2, normal: normal2, st: SIMD2<Float>())
      index = index + 1
      
      let position1:  SIMD4<Float> =  SIMD4<Float>(x: Float(r * cosTheta), y: -1.0, z: Float(r * sinTheta), w: 0.0)
      let normal1:  SIMD4<Float> =  SIMD4<Float>(x: Float(cosTheta), y: 0.0, z: Float(sinTheta), w: 0.0)
      vertices[index] = RKVertex(position: position1, normal: normal1, st: SIMD2<Float>())
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
  }
}
