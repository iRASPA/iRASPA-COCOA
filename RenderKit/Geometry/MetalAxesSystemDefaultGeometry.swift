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
public class MetalAxesSystemDefaultGeometry
{
  public var numberOfVertexes: Int
  public var vertices: [RKPrimitiveVertex]
  
  public var numberOfIndices: Int
  public var indices: [UInt16]
  
  public enum CenterType: Int
  {
    case sphere = 0
    case cube = 1
  }
  

  /// Geometry data for an arrow
  ///
  /// - parameter arrowHeight:  the height of the arrow-shaft
  /// - parameter arrowRadius:  the radius of the arrow-shaft
  /// - parameter tipHeight:    the height of the tip
  /// - parameter tipRadius:    the radius of the tip
  /// - parameter sectorCount:  the number of sectors
  /// - parameter stackCount:   the number of stacks
  public init(center: RKGlobalAxes.CenterType, centerRadius: Double, centerColor: SIMD4<Float>, arrowHeight: Double, arrowRadius: Double, arrowColorX: SIMD4<Float>, arrowColorY: SIMD4<Float>, arrowColorZ: SIMD4<Float>, tipHeight: Double, tipRadius: Double, tipColorX: SIMD4<Float>, tipColorY: SIMD4<Float>, tipColorZ: SIMD4<Float>, tipVisibility: Bool, aspectRatio: Double, sectorCount: Int)
  {
    vertices = []
    indices = []
    
    switch(center)
    {
    case .sphere:
      let sphere: MetalNSphereGeometry = MetalNSphereGeometry(r: centerRadius * 1.2, color: centerColor, iterations: 4)
      vertices += sphere.vertices
      indices += sphere.indices
    case .cube:
      let cube: MetalCubeGeometry = MetalCubeGeometry(size: centerRadius, color:  centerColor)
      vertices += cube.vertices
      indices += cube.indices
    }
        
    let axisXoffset: Int = vertices.count
    let axisX: MetalArrowXGeometry = MetalArrowXGeometry(offset: centerRadius, arrowHeight: arrowHeight, arrowRadius: arrowRadius, arrowColor: arrowColorX, tipHeight: tipHeight, tipRadius: tipRadius, tipColor: tipColorX, tipVisibility: tipVisibility, aspectRatio: aspectRatio, sectorCount: sectorCount)
    vertices += axisX.vertices
    indices += axisX.indices.map{$0+UInt16(axisXoffset)}
    
    let axisYoffset: Int = vertices.count
    let axisY: MetalArrowYGeometry = MetalArrowYGeometry(offset: centerRadius, arrowHeight: arrowHeight, arrowRadius: arrowRadius, arrowColor: arrowColorY, tipHeight: tipHeight, tipRadius: tipRadius, tipColor: tipColorY, tipVisibility: tipVisibility, aspectRatio: aspectRatio, sectorCount: sectorCount)
    vertices += axisY.vertices
    indices += axisY.indices.map{$0+UInt16(axisYoffset)}
    
    let axisZoffset: Int = vertices.count
    let axisZ: MetalArrowZGeometry = MetalArrowZGeometry(offset: centerRadius, arrowHeight: arrowHeight, arrowRadius: arrowRadius, arrowColor: arrowColorZ, tipHeight: tipHeight, tipRadius: tipRadius, tipColor: tipColorZ, tipVisibility: tipVisibility, aspectRatio: aspectRatio, sectorCount: sectorCount)
    vertices += axisZ.vertices
    indices += axisZ.indices.map{$0+UInt16(axisZoffset)}
    
    numberOfVertexes = vertices.count
    numberOfIndices = indices.count
  }
}
