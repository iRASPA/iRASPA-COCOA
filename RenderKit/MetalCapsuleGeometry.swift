//
//  MetalCapsuleGeometry.swift
//  RenderKit
//
//  Created by David Dubbeldam on 05/08/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import Foundation
import simd

// Paul Borke
// http://paulbourke.net/geometry/spherical/capsule.c

// works with MTLCullMode.back
// draw with indexed triangles
public class MetalCapsuleGeometry
{
  public var numberOfVertexes: Int
  public var vertices: [RKVertex]
  
  public var numberOfIndices: Int
  public var indices: [UInt16]
  
  public convenience init()
  {
    self.init(radius: 1.0, height:  2.0, slices: 32)
  }
  
  public init(radius: Double = 1.0, height: Double = 2.0, slices: Int = 32)
  {
    numberOfVertexes = (slices + 1) * (slices/2 + 2)
    vertices = []
    indices = []
    
    for j in 0...slices/4
    {
      // top cap
      for i in 0...slices
      {
        let theta: Double = Double(i) * 2.0 * Double.pi / Double(slices);
        let phi: Double = -0.5*Double.pi + Double.pi * Double(j) / (Double(slices)/2)
        
        let pos: SIMD3<Double> = SIMD3<Double>(x: radius * cos(phi) * cos(theta), y: radius * cos(phi) * sin(theta), z: radius * sin(phi))
        let length: Double = length(pos)
        let position: SIMD4<Float> = SIMD4<Float>(x: pos.x, y: pos.y, z: pos.z - height/2.0, w: 0.0)
        let normal: SIMD4<Float> = SIMD4<Float>(x: pos.x/length, y: pos.y/length, z: pos.z/length, w: 0.0)
        
        var st: SIMD2<Float> = SIMD2<Float>()
        st.x = atan2(position.y,position.x) / (2.0 * Float.pi);
        if (st.x < 0)
        {
          st.x = 1 + st.x;
        }
        st.y = 0.5 + atan2(position.z,sqrt(position.x*position.x+position.y*position.y)) / Float.pi
        vertices.append(RKVertex(position: position, normal: normal, st: st))
      }
    }
    for j in slices/4...slices/2
    {
      // bottom cap
      for i in 0...slices
      {
        let theta: Double = Double(i) * 2.0 * Double.pi / Double(slices)
        let phi: Double = -0.5*Double.pi + Double.pi * Double(j) / (Double(slices)/2)
        
        let pos: SIMD3<Double> = SIMD3<Double>(x: radius * cos(phi) * cos(theta), y: radius * cos(phi) * sin(theta), z: radius * sin(phi))
        let length: Double = length(pos)
        let position: SIMD4<Float> = SIMD4<Float>(x: pos.x, y: pos.y, z: pos.z + height/2.0, w: 0.0)
        let normal: SIMD4<Float> = SIMD4<Float>(x: pos.x/length, y: pos.y/length, z: pos.z/length, w: 0.0)
        
        var st: SIMD2<Float> = SIMD2<Float>()
        st.x = atan2(position.y,position.x) / (2.0 * Float.pi);
        if (st.x < 0)
        {
          st.x = 1 + st.x;
        }
        st.y = 0.5 + atan2(position.z,sqrt(position.x*position.x+position.y*position.y)) / Float.pi;
        vertices.append(RKVertex(position: position, normal: normal, st: SIMD2<Float>()))
      }
    }
  
    // (slices + 1) * (slices/2 + 2)
    for j in 0...slices/2
    {
      for i in 0...slices
      {
        let  i1 =  j    * (slices+1) + i
        let  i2 =  j    * (slices+1) + (i + 1)
        let  i3 = (j+1) * (slices+1) + (i + 1)
        let  i4 = (j+1) * (slices+1) + i     
        indices.append(UInt16(i1))
        indices.append(UInt16(i3))
        indices.append(UInt16(i2))
        indices.append(UInt16(i1))
        indices.append(UInt16(i4))
        indices.append(UInt16(i3))
      }
    }
   
    numberOfIndices = indices.count
    
    assert(vertices.count == (slices+1)*(slices/2+2))
  }
}
