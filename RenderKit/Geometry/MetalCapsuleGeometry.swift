//
//  MetalCapsuleGeometry.swift
//  RenderKit
//
//  Created by David Dubbeldam on 05/08/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import Foundation
import simd

/// Geometry data for a capsule
/// - note:
/// The orientation (0,1,0) is along the y-axis.
/// Draw using 'drawIndexedPrimitives' with type '.triangle' and setCullMode(MTLCullMode.back).
/// More information:
///
/// Paul Borke: http://paulbourke.net/geometry/spherical/capsule.c
///
/// Texture coordinates untested
public class MetalCapsuleGeometry
{
  public var numberOfVertexes: Int
  public var vertices: [RKVertex]
  
  public var numberOfIndices: Int
  public var indices: [UInt16]
  
  public convenience init()
  {
    self.init(radius: 1.0, height:  2.0, slices: 42)
  }
  
  /// Geometry data for a capsule
  ///
  /// - parameter radius:  the radius of the capsule
  /// - parameter height:  the height of the capsule
  /// - parameter slices:  the number of slices
  public init(radius: Double = 1.0, height: Double = 2.0, slices: Int = 42)
  {
    numberOfVertexes = (slices + 1) * (slices/2 + 2)
    vertices = []
    indices = []
    
    for j in 0...slices/4
    {
      // bottom side
      for i in 0...slices
      {
        let theta: Double = Double(i) * 2.0 * Double.pi / Double(slices);
        let phi: Double = -0.5*Double.pi + Double.pi * Double(j) / (Double(slices)/2)
        
        let pos: SIMD3<Double> = SIMD3<Double>(x: radius * cos(phi) * cos(theta), y: radius * sin(phi), z: radius * cos(phi) * sin(theta))
        let length: Double = length(pos)
        let position: SIMD4<Float> = SIMD4<Float>(x: pos.x, y: pos.y - 0.5 * height, z:  pos.z, w: 0.0)
        let normal: SIMD4<Float> = SIMD4<Float>(x: pos.x/length, y: pos.y/length, z: pos.z/length, w: 0.0)
        
        var st: SIMD2<Float> = SIMD2<Float>()
        st.x = atan2(position.z,position.x) / (2.0 * Float.pi);
        if (st.x < 0.0)
        {
          st.x = 1.0 + st.x;
        }
        st.y = 0.5 + atan2(position.y,sqrt(position.x*position.x+position.z*position.z)) / Float.pi
        vertices.append(RKVertex(position: position, normal: normal, st: st))
      }
    }
    
    // top side
    for j in slices/4...slices/2
    {
      for i in 0...slices
      {
        let theta: Double = Double(i) * 2.0 * Double.pi / Double(slices)
        let phi: Double = -0.5*Double.pi + Double.pi * Double(j) / (Double(slices)/2)
        
        let pos: SIMD3<Double> = SIMD3<Double>(x: radius * cos(phi) * cos(theta), y: radius * sin(phi), z: radius * cos(phi) * sin(theta))
        let length: Double = length(pos)
        let position: SIMD4<Float> = SIMD4<Float>(x: pos.x, y: pos.y + 0.5 * height, z: pos.z , w: 0.0)
        let normal: SIMD4<Float> = SIMD4<Float>(x: pos.x/length, y: pos.y/length, z: pos.z/length, w: 0.0)
        
        var st: SIMD2<Float> = SIMD2<Float>()
        st.x = atan2(position.z,position.x) / (2.0 * Float.pi);
        if (st.x < 0.0)
        {
          st.x = 1.0 + st.x;
        }
        st.y = 0.5 + atan2(position.y,sqrt(position.x*position.x+position.z*position.z)) / Float.pi;
        vertices.append(RKVertex(position: position, normal: normal, st: SIMD2<Float>()))
      }
    }
  
    for j in 0...slices/2
    {
      for i in 0...slices
      {
        let  i1 =  j    * (slices+1) + i
        let  i2 =  j    * (slices+1) + (i + 1)
        let  i3 = (j+1) * (slices+1) + (i + 1)
        let  i4 = (j+1) * (slices+1) + i     
        indices.append(UInt16(i1))
        indices.append(UInt16(i2))
        indices.append(UInt16(i3))
        
        indices.append(UInt16(i1))
        indices.append(UInt16(i3))
        indices.append(UInt16(i4))
        
      }
    }
   
    numberOfIndices = indices.count
    
    assert(vertices.count == (slices+1)*(slices/2+2))
  }
}
