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

// NOTE: winding-order of Metal is Clockwise (opposite to OpenGL)

public class MetalSphereGeometry
{
  var slices: Int
  public var numberOfIndices: Int
  public var numberOfVertexes: Int
  
  public var vertices: [RKVertex]
  public var indices: [UInt16]
  
  public convenience init()
  {
    self.init(r: 1.0, s: 41)
  }
  
  public init(r: Double, s: Int)
  {
    var index: Int
    var theta, phi, sinTheta, sinPhi, cosTheta, cosPhi: Double
    var position, normal: SIMD4<Float>
    
    slices = s
    numberOfIndices = 2 * (s + 1) * s
    numberOfVertexes = (s + 1) * s
    
    vertices = [RKVertex](repeating: RKVertex(), count: numberOfVertexes)
    indices = [UInt16](repeating: UInt16(), count: numberOfIndices)
    
    index = 0
    for stackNumber in 0...slices
    {
      for sliceNumber in 0..<slices
      {
        theta = Double(stackNumber) * Double.pi / Double(slices)
        phi = Double(sliceNumber) * 2 * Double.pi / Double(slices)
        sinTheta = sin(theta)
        sinPhi = sin(phi)
        cosTheta = cos(theta)
        cosPhi = cos(phi)
        normal = SIMD4<Float>(x: cosPhi * sinTheta, y: sinPhi * sinTheta, z: cosTheta, w: 0.0)
        position = SIMD4<Float>(x: r * cosPhi * sinTheta, y: r * sinPhi * sinTheta, z: r * cosTheta, w: 0.0)
        let st: SIMD2<Float> = SIMD2<Float>(x: 0.5 + 0.5 * atan2(position.z, position.x)/Float.pi, y: 0.5 - asin(position.y)/Float.pi)
        vertices[index] = RKVertex(position: position, normal: normal, st: st)
        index = index + 1
      }
    }
    
    
    index = 0
    for stackNumber in 0..<slices
    {
      for sliceNumber in 0...slices
      {
        indices[index] = UInt16(((stackNumber + 1) * slices) + (sliceNumber % slices))
        index = index + 1
        indices[index] = UInt16((stackNumber * slices) + (sliceNumber % slices))
        index = index + 1
      }
    }
  
  }
}

