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
import Metal
import simd


/// Geometry data for an arrow
/// - note:
/// The orientation (0,1,0) is along the y-axis.
/// Draw using 'drawIndexedPrimitives' with type '.triangle' and setCullMode(MTLCullMode.back).
/// More information:
///
/// Texture coordinates undefined
public class MetalArrowZGeometry
{
  public var numberOfVertexes: Int
  public var vertices: [RKPrimitiveVertex]
  
  public var numberOfIndices: Int
  public var indices: [UInt16]
  
  
  /// Geometry data for an arrow
  ///
  /// - parameter arrowHeight:  the height of the arrow-shaft
  /// - parameter arrowRadius:  the radius of the arrow-shaft
  /// - parameter tipHeight:    the height of the tip
  /// - parameter tipRadius:    the radius of the tip
  /// - parameter sectorCount:  the number of sectors
  /// - parameter stackCount:   the number of stacks
  public init(offset: Double, arrowHeight: Double, arrowRadius: Double, arrowColor: SIMD4<Float>, tipHeight: Double, tipRadius: Double, tipColor: SIMD4<Float>, tipVisibility: Bool, aspectRatio: Double, sectorCount: Int)
  {
    vertices = []
    indices = []
    
    let sectorStep: Double = 2.0 * Double.pi / Double(sectorCount)
   
    // bottom cap arrow
    let ref_cap_1: Int = vertices.count
    vertices.append(RKPrimitiveVertex(position: SIMD4<Float>(x: 0.0, y: 0.0, z: offset, w: 0.0), normal: SIMD4<Float>(x: 0.0, y: 0.0, z: 1.0, w: 0.0), color: arrowColor, st: SIMD2<Float>(0.5,0.5)))
    for  i in 0..<sectorCount
    {
      let sectorAngle: Double = Double(i) * sectorStep + 0.25 * Double.pi
      let position: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle) * arrowRadius, y: sin(sectorAngle) * arrowRadius / aspectRatio, z: offset, w: 0.0)
      let normal: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 0.0, z: 1.0, w: 0.0)
      vertices.append(RKPrimitiveVertex(position: position, normal: normal, color: arrowColor, st: SIMD2<Float>()))
    }
  
    // arrow shaft
    let ref_cap_2: Int = vertices.count
    for i in 0..<sectorCount
    {
      let sectorAngle: Double = Double(i) * sectorStep + 0.25 * Double.pi
      let cosTheta: Double = cos(sectorAngle)
      let sinTheta: Double = sin(sectorAngle)
      
      let sectorAngle2: Double = Double(i+1) * sectorStep + 0.25 * Double.pi
      let cosTheta2: Double = cos(sectorAngle2)
      let sinTheta2: Double = sin(sectorAngle2)
      
      let position1: SIMD4<Float> = SIMD4<Float>(x: arrowRadius * cosTheta / aspectRatio, y: arrowRadius * sinTheta, z: offset,                 w: 0.0)
      let position2: SIMD4<Float> = SIMD4<Float>(x: arrowRadius * cosTheta / aspectRatio,  y: arrowRadius * sinTheta, z: offset + arrowHeight,  w: 0.0)
      let position3: SIMD4<Float> = SIMD4<Float>(x: arrowRadius * cosTheta2 / aspectRatio, y: arrowRadius * sinTheta2, z: offset + arrowHeight, w: 0.0)
      let v1: SIMD4<Float> = position2 - position1
      let w1: SIMD4<Float> = position2 - position3
      let normal1: SIMD3<Float> = normalize(cross(SIMD3<Float>(v1.x,v1.y,v1.z), SIMD3<Float>(w1.x,w1.y,w1.z)))
      
      if(sectorCount < 20 || aspectRatio < 1.0)
      {
        vertices.append(RKPrimitiveVertex(position: position1, normal: SIMD4<Float>(normal1.x,normal1.y,normal1.z,0.0), color: arrowColor, st: SIMD2<Float>()))
        vertices.append(RKPrimitiveVertex(position: position2, normal: SIMD4<Float>(normal1.x,normal1.y,normal1.z,0.0), color: tipColor, st: SIMD2<Float>()))
        vertices.append(RKPrimitiveVertex(position: position3, normal: SIMD4<Float>(normal1.x,normal1.y,normal1.z,0.0), color: tipColor, st: SIMD2<Float>()))
      }
      else
      {
        vertices.append(RKPrimitiveVertex(position: position1, normal: SIMD4<Float>(position1.x,position1.y,0.0,0.0), color: arrowColor, st: SIMD2<Float>()))
        vertices.append(RKPrimitiveVertex(position: position2, normal: SIMD4<Float>(position2.x,position2.y,0.0,0.0), color: tipColor, st: SIMD2<Float>()))
        vertices.append(RKPrimitiveVertex(position: position3, normal: SIMD4<Float>(position3.x,position3.y,0.0,0.0), color: tipColor, st: SIMD2<Float>()))
      }
     
      let position4: SIMD4<Float> = SIMD4<Float>(x: arrowRadius * cosTheta2 / aspectRatio,  y: arrowRadius * sinTheta2, z: offset + arrowHeight, w: 0.0)
      let position5: SIMD4<Float> = SIMD4<Float>(x: arrowRadius * cosTheta2 / aspectRatio,  y: arrowRadius * sinTheta2, z: offset,          w: 0.0)
      let position6: SIMD4<Float> = SIMD4<Float>(x: arrowRadius * cosTheta / aspectRatio,  y: arrowRadius * sinTheta, z: offset,  w: 0.0)
      
      let v2: SIMD4<Float> = position5 - position4
      let w2: SIMD4<Float> = position5 - position6
      let normal2: SIMD3<Float> = normalize(cross(SIMD3<Float>(v2.x,v2.y,v2.z), SIMD3<Float>(w2.x,w2.y,w2.z)))
      
      if(sectorCount < 20 || aspectRatio < 1.0)
      {
        vertices.append(RKPrimitiveVertex(position: position4, normal: SIMD4<Float>(normal2.x,normal2.y,normal2.z,0.0), color: tipColor, st: SIMD2<Float>()))
        vertices.append(RKPrimitiveVertex(position: position5, normal: SIMD4<Float>(normal2.x,normal2.y,normal2.z,0.0), color: arrowColor, st: SIMD2<Float>()))
        vertices.append(RKPrimitiveVertex(position: position6, normal: SIMD4<Float>(normal2.x,normal2.y,normal2.z,0.0), color: arrowColor, st: SIMD2<Float>()))
      }
      else
      {
        vertices.append(RKPrimitiveVertex(position: position4, normal: SIMD4<Float>(position4.x,position4.y,0.0,0.0), color: tipColor, st: SIMD2<Float>()))
        vertices.append(RKPrimitiveVertex(position: position5, normal: SIMD4<Float>(position5.x,position5.y,0.0,0.0), color: arrowColor, st: SIMD2<Float>()))
        vertices.append(RKPrimitiveVertex(position: position6, normal: SIMD4<Float>(position6.x,position6.y,0.0,0.0), color: arrowColor, st: SIMD2<Float>()))
      }
    }
    
    // bottom cap arrow tip
    let ref_cap_3: Int = vertices.count
    if(tipVisibility)
    {
      vertices.append(RKPrimitiveVertex(position: SIMD4<Float>(x: 0.0, y: 0.0, z: offset + arrowHeight, w: 0.0), normal: SIMD4<Float>(x: 0.0, y: 0.0, z: -1.0, w: 0.0), color:   tipColor, st: SIMD2<Float>(0.5,0.5)))
      for  i in 0..<sectorCount
      {
        let sectorAngle: Double = Double(i) * sectorStep + 0.25 * Double.pi
        let position: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle) * tipRadius / aspectRatio, y: sin(sectorAngle) * tipRadius, z: offset + arrowHeight, w: 0.0)
        let normal: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 0.0, z: -1.0, w: 0.0)
        vertices.append(RKPrimitiveVertex(position: position, normal: normal, color: tipColor, st: SIMD2<Float>()))
      }
    }
    else
    {
      vertices.append(RKPrimitiveVertex(position: SIMD4<Float>(x: 0.0, y: 0.0, z: offset + arrowHeight, w: 0.0), normal: SIMD4<Float>(x: 0.0, y: 0.0, z: 1.0, w: 0.0), color:   tipColor, st: SIMD2<Float>(0.5,0.5)))
      for  i in 0..<sectorCount
      {
        let sectorAngle: Double = Double(i) * sectorStep + 0.25 * Double.pi
        let position: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle) * arrowRadius / aspectRatio, y: sin(sectorAngle) * arrowRadius, z: offset + arrowHeight, w: 0.0)
        let normal: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 0.0, z: 1.0, w: 0.0)
        vertices.append(RKPrimitiveVertex(position: position, normal: normal, color: tipColor, st: SIMD2<Float>()))
      }
    }
    
    // arrow tip
    let ref_cap_4: Int = vertices.count
    if(tipVisibility)
    {
      let angleY: Double = atan2(tipRadius, tipHeight)
      let nx: Double = cos(angleY)
      let ny: Double = 0.0
      let nz: Double = sin(angleY)
      
      for i in 0...sectorCount
      {
        let sectorAngle: Double = Double(i) * sectorStep + 0.25 * Double.pi
        let sectorAngle2: Double = Double(i+1) * sectorStep + 0.25 * Double.pi
      
        let position1: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle) * tipRadius / aspectRatio, y: sin(sectorAngle) * tipRadius, z: offset + arrowHeight,   w: 0.0)
        let position2: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 0.0, z: offset + arrowHeight + tipHeight,   w: 0.0)
        let position3: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle2) * tipRadius / aspectRatio,y: sin(sectorAngle2) * tipRadius,z: offset + arrowHeight,   w: 0.0)
      
        let normal1: SIMD3<Float>, normal2: SIMD3<Float>, normal3: SIMD3<Float>
        if(sectorCount < 20 || aspectRatio < 1.0)
        {
          let v1: SIMD4<Float> = position2 - position1
          let w1: SIMD4<Float> = position2 - position3
          normal1 = normalize(cross(SIMD3<Float>(v1.x,v1.y,v1.z), SIMD3<Float>(w1.x,w1.y,w1.z)))
          normal2 = normal1
          normal3 = normal1
        }
        else
        {
          normal1 = normalize(SIMD3<Float>(x: (cos(sectorAngle)*nx - sin(sectorAngle)*ny) / aspectRatio, y: sin(sectorAngle)*nx + cos(sectorAngle)*ny, z: nz))
          normal2 = normalize(SIMD3<Float>(x: (cos(sectorAngle)*nx - sin(sectorAngle)*ny) / aspectRatio,  y: sin(sectorAngle)*nx + cos(sectorAngle)*ny, z: nz))
          normal3 = normalize(SIMD3<Float>(x: (cos(sectorAngle2)*nx - sin(sectorAngle2)*ny) / aspectRatio,  y: sin(sectorAngle2)*nx + cos(sectorAngle2)*ny, z: nz))
        }
      
        vertices.append(RKPrimitiveVertex(position: position1, normal: SIMD4<Float>(normal1.x,normal1.y,normal1.z,0.0), color: tipColor, st: SIMD2<Float>()))
        vertices.append(RKPrimitiveVertex(position: position2, normal: SIMD4<Float>(normal2.x,normal2.y,normal2.z,0.0), color: tipColor, st: SIMD2<Float>()))
        vertices.append(RKPrimitiveVertex(position: position3, normal: SIMD4<Float>(normal3.x,normal3.y,normal3.z,0.0), color: tipColor, st: SIMD2<Float>()))
      }
    }
    
    // bottom cap arrow
    for  i in 0..<sectorCount
    {
      indices.append(UInt16(ref_cap_1))
      indices.append(UInt16(ref_cap_1 + 1 + i % sectorCount))
      indices.append(UInt16(ref_cap_1 + 1 + (i+1) % sectorCount))
    }
    
    // arrow shaft
    for i in 0..<6*sectorCount
    {
      indices.append(UInt16(ref_cap_2 + i))
    }
    
    // bottom cap arrow tip
    if(tipVisibility)
    {
      for  i in 0..<sectorCount
      {
        indices.append(UInt16(ref_cap_3))
        indices.append(UInt16(ref_cap_3 + 1 + i % sectorCount))
        indices.append(UInt16(ref_cap_3 + 1 + (i+1) % sectorCount))
      }
    }
    else
    {
      for  i in 0..<sectorCount
      {
        indices.append(UInt16(ref_cap_3))
        indices.append(UInt16(ref_cap_3 + 1 + (i+1) % sectorCount))
        indices.append(UInt16(ref_cap_3 + 1 + i % sectorCount))
      }
    }
    
    // arrow tip
    if(tipVisibility)
    {
      for i in 0..<3*sectorCount
      {
        indices.append(UInt16(ref_cap_4 + i))
      }
    }
    
    numberOfVertexes = vertices.count
    numberOfIndices = indices.count
    
  }
}
