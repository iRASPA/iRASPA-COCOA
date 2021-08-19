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


/// Geometry data for an arrow
/// - note:
/// The orientation (0,1,0) is along the y-axis.
/// Draw using 'drawIndexedPrimitives' with type '.triangle' and setCullMode(MTLCullMode.back).
/// More information:
///
/// Texture coordinates undefined
public class MetalArrowGeometry
{
  public var numberOfVertexes: Int
  public var vertices: [RKVertex]
  
  public var numberOfIndices: Int
  public var indices: [UInt16]
  
  public convenience init()
  {
    self.init(arrowHeight: 2.0/3.0, arrowRadius: 1.0/12.0, tipHeight: 1.0/3.0, tipRadius: 1.0/6.0, sectorCount: 41, stackCount: 3)
  }
  
  /// Geometry data for an arrow
  ///
  /// - parameter arrowHeight:  the height of the arrow-shaft
  /// - parameter arrowRadius:  the radius of the arrow-shaft
  /// - parameter tipHeight:    the height of the tip
  /// - parameter tipRadius:    the radius of the tip
  /// - parameter sectorCount:  the number of sectors
  /// - parameter stackCount:   the number of stacks
  public init(arrowHeight: Double, arrowRadius: Double, tipHeight: Double, tipRadius: Double, sectorCount: Int, stackCount: Int)
  {
    vertices = []
    indices = []
    
    let sectorStep: Double = 2.0 * Double.pi / Double(sectorCount)
   
    // bottom cap arrow
    let ref_cap_1: Int = vertices.count
    vertices.append(RKVertex(position: SIMD4<Float>(x: 0.0, y: 0.0, z: 0.0, w: 0.0), normal: SIMD4<Float>(x: 0.0, y: -1.0, z: 0.0, w: 0.0), st: SIMD2<Float>(0.5,0.5)))
    for  i in 0..<sectorCount
    {
      let sectorAngle: Double = Double(i) * sectorStep
      let position: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle) * arrowRadius, y: 0.0, z: sin(sectorAngle) * arrowRadius, w: 0.0)
      let normal: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: -1.0, z: 0.0, w: 0.0)
      vertices.append(RKVertex(position: position, normal: normal, st: SIMD2<Float>()))
    }
  
    // arrow shaft
    let ref_cap_2: Int = vertices.count
    for j in 0...sectorCount
    {
      let sectorAngle: Double = Double(j) * sectorStep
      
      let position1: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle) * arrowRadius, y: 0.0, z: sin(sectorAngle) * arrowRadius, w: 0.0)
      let normal1: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle), y: 0.0, z: sin(sectorAngle), w: 0.0)
      vertices.append(RKVertex(position: position1, normal: normal1, st: SIMD2<Float>()))
      
      let position2: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle) * arrowRadius, y: arrowHeight, z: sin(sectorAngle) * arrowRadius, w: 0.0)
      let normal2: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle), y: 0.0, z: sin(sectorAngle), w: 0.0)
      vertices.append(RKVertex(position: position2, normal: normal2, st: SIMD2<Float>()))
    }
    
    // bottom cap arrow tip
    let ref_cap_3: Int = vertices.count
    vertices.append(RKVertex(position: SIMD4<Float>(x: 0.0, y: arrowHeight, z: 0.0, w: 0.0), normal: SIMD4<Float>(x: 0.0, y: -1.0, z: 0.0, w: 0.0), st: SIMD2<Float>(0.5,0.5)))
    for  i in 0..<sectorCount
    {
      let sectorAngle: Double = Double(i) * sectorStep
      let position: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle) * tipRadius, y: arrowHeight, z: sin(sectorAngle) * tipRadius, w: 0.0)
      let normal: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: -1.0, z: 0.0, w: 0.0)
      vertices.append(RKVertex(position: position, normal: normal, st: SIMD2<Float>()))
    }
    
    // arrow tip
    let ref_cap_4: Int = vertices.count
    let angleY: Double = atan2(tipRadius, tipHeight)
    let nx: Double = cos(angleY)
    let ny: Double = sin(angleY)
    let nz: Double = 0
    
    for i in 0...stackCount
    {
      let z: Double = arrowHeight + Double(i) / Double(stackCount) * tipHeight
      let radius: Double = tipRadius - Double(i) / Double(stackCount) * tipRadius

      for j in 0...sectorCount
      {
        let sectorAngle: Double = Double(j) * sectorStep
        
        let position: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle) * radius, y: z, z: sin(sectorAngle) * radius, w: 0.0)
        let normal: SIMD4<Float> = SIMD4<Float>(x: cos(sectorAngle)*nx - sin(sectorAngle)*nz, y: ny, z: sin(sectorAngle)*nx + cos(sectorAngle)*nz, w: 0.0)
        vertices.append(RKVertex(position: position, normal: normal, st: SIMD2<Float>()))
      }
    }
    
    // bottom cap arrow
    for  i in 0..<sectorCount
    {
      indices.append(UInt16(ref_cap_1))
      indices.append(UInt16(ref_cap_1 + 1 + (i+1) % sectorCount))
      indices.append(UInt16(ref_cap_1 + 1 + i % sectorCount))
    }
    
    // arrow shaft
    for i in 0..<sectorCount
    {
      indices.append(UInt16(ref_cap_2 + (2 * i) % (2 * sectorCount)))
      indices.append(UInt16(ref_cap_2 + (2 * i + 2) % (2 * sectorCount)))
      indices.append(UInt16(ref_cap_2 + (2 * i + 1) % (2 * sectorCount)))
      
      indices.append(UInt16(ref_cap_2 + (2 * i + 2) % (2 * sectorCount)))
      indices.append(UInt16(ref_cap_2 + (2 * i + 3) % (2 * sectorCount)))
      indices.append(UInt16(ref_cap_2 + (2 * i + 1) % (2 * sectorCount)))
    }
    
    // bottom cap arrow tip
    for  i in 0..<sectorCount
    {
      indices.append(UInt16(ref_cap_3))
      indices.append(UInt16(ref_cap_3 + 1 + (i+1) % sectorCount))
      indices.append(UInt16(ref_cap_3 + 1 + i % sectorCount))
    }
    
    // arrow tip
    for  i in 0..<stackCount
    {
      let k1: Int = i * (sectorCount + 1)
      let k2: Int = k1 + sectorCount + 1

      for j in 0..<sectorCount
      {
        indices.append(UInt16(ref_cap_4 + k1 + j))
        indices.append(UInt16(ref_cap_4 + k1 + j + 1))
        indices.append(UInt16(ref_cap_4 + k2 + j))
        
        indices.append(UInt16(ref_cap_4 + k2 + j))
        indices.append(UInt16(ref_cap_4 + k1 + j + 1))
        indices.append(UInt16(ref_cap_4 + k2 + j + 1))
      }
    }
    
    numberOfVertexes = vertices.count
    numberOfIndices = indices.count
  }
}
