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


/// Geometry data for a capped cone
/// - note:
/// The orientation (0,1,0) is along the y-axis.
/// Draw using 'drawIndexedPrimitives' with type '.triangle' and setCullMode(MTLCullMode.back).
/// More information:
///
/// Paul Bourke: http://paulbourke.net/geometry/circlesphere/opengl.c
///
/// Song Ho Ahn: http://www.songho.ca/opengl/gl_cylinder.html
///
/// Texture coordinates untested
public class MetalCappedConeGeometry
{
  public var numberOfVertexes: Int
  public var vertices: [RKVertex]
  
  public var numberOfIndices: Int
  public var indices: [UInt16]
  
  public convenience init()
  {
    self.init(height: 1.0, topRadius: 0.1, baseRadius: 0.5, sectorCount: 41, stackCount: 3)
  }
  
  /// Geometry data for a capped cone
  ///
  /// - parameter height:        the height of the cone
  /// - parameter topRadius:     the top radius of the cone
  /// - parameter baseRadius:    the base radius of the cone
  /// - parameter sectorCount:   the number of sectors
  /// - parameter stackCount:    the number of stacks
  public init(height: Double, topRadius: Double, baseRadius: Double, sectorCount: Int, stackCount: Int)
  {
    vertices = []
    indices = []
   
    let sectorStep: Double = 2.0 * Double.pi / Double(sectorCount)

    let angleY: Double = atan2(baseRadius - topRadius, height)
    let nx: Double = cos(angleY)
    let ny: Double = sin(angleY)
    let nz: Double = 0
    
    // side vertices
    for i in 0...stackCount
    {
      let z: Double = -(height * 0.5) + Double(i) / Double(stackCount) * height
      let radius: Double = baseRadius + Double(i) / Double(stackCount) * (topRadius - baseRadius)
      let t: Double = 1.0 - Double(i) / Double(stackCount)

      for j in 0...sectorCount
      {
        let sectorAngle: Double = Double(j) * sectorStep
        
        let position: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle) * radius, y: -z, z: sin(sectorAngle) * radius, w: 0.0)
        let normal: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle)*nx - sin(sectorAngle)*nz, y: -ny, z: sin(sectorAngle)*nx + cos(sectorAngle)*nz, w: 0.0)
        let st: SIMD2<Float> = SIMD2<Float>(Float(j) / Float(sectorCount), Float(t))
        vertices.append(RKVertex(position: position, normal: normal, st: st))
      }
    }
    
    // bottom cap vertices
    let ref_cap_1: Int = vertices.count
    vertices.append(RKVertex(position: SIMD4<Float>(x: 0.0, y: -height * 0.5, z: 0.0, w: 0.0), normal: SIMD4<Float>(x: 0.0, y: -1.0, z: 0.0, w: 0.0), st: SIMD2<Float>(0.5,0.5)))
    for  i in 0..<sectorCount
    {
      let sectorAngle: Double = Double(i) * sectorStep
      let position: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle) * topRadius, y: -height * 0.5, z: sin(sectorAngle) * topRadius, w: 0.0)
      let normal: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: -1.0, z: 0.0, w: 0.0)
      let st: SIMD2<Float> = SIMD2<Float>(Float(position.x * 0.5 + 0.5), Float(position.z * 0.5 + 0.5))
      vertices.append(RKVertex(position: position, normal: normal, st: st))
    }
    
    // top cap vertices
    let ref_cap_2: Int = vertices.count
    vertices.append(RKVertex(position: SIMD4<Float>(x: 0.0, y: height * 0.5, z: 0.0, w: 0.0), normal: SIMD4<Float>(x: 0.0, y: 1.0, z: 0.0, w: 0.0), st: SIMD2<Float>(0.5,0.5)))
    for  i in 0..<sectorCount
    {
      let sectorAngle: Double = Double(i) * sectorStep
      let position: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle) * baseRadius, y: height * 0.5, z: sin(sectorAngle) * baseRadius, w: 0.0)
      let normal: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 1.0, z: 0.0, w: 0.0)
      let st: SIMD2<Float> = SIMD2<Float>(Float(-position.x * 0.5 + 0.5), Float(position.z * 0.5 + 0.5))
      vertices.append(RKVertex(position: position, normal: normal, st: st))
    }
    
    // side indices
    for  i in 0..<stackCount
    {
      let k1: Int = i * (sectorCount + 1)
      let k2: Int = k1 + sectorCount + 1

      for j in 0..<sectorCount
      {
        indices.append(UInt16(k1 + j))
        indices.append(UInt16(k2 + j))
        indices.append(UInt16(k1 + j + 1))
        
        indices.append(UInt16(k2 + j))
        indices.append(UInt16(k2 + j + 1))
        indices.append(UInt16(k1 + j + 1))
      }
    }
    
    // bottom cap indices
    for  i in 0..<sectorCount
    {
      indices.append(UInt16(ref_cap_1))
      indices.append(UInt16(ref_cap_1 + 1 + (i+1) % sectorCount))
      indices.append(UInt16(ref_cap_1 + 1 + i % sectorCount))
    }
    
    // top cap indices
    for  i in 0..<sectorCount
    {
      indices.append(UInt16(ref_cap_2))
      indices.append(UInt16(ref_cap_2 + 1 + i % sectorCount))
      indices.append(UInt16(ref_cap_2 + 1 + (i+1) % sectorCount))
    }
    
    numberOfVertexes = vertices.count
    numberOfIndices = indices.count
  }
}
