//
//  RKPrimitiveVertex.swift
//  RenderKit
//
//  Created by David Dubbeldam on 07/08/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import Foundation

public struct RKPrimitiveVertex: CustomStringConvertible
{
  public var position:  SIMD4<Float>
  public var normal:  SIMD4<Float>
  public var color:  SIMD4<Float>
  public var st: SIMD2<Float>
  public var pad: SIMD2<Float> = SIMD2<Float>()
  
  public init()
  {
    self.position =  SIMD4<Float>(x: 0.0, y: 0.0, z: 0.0, w:1.0)
    self.normal =  SIMD4<Float>(x: 0.0, y: 0.0, z: 0.0, w:0.0)
    self.color = SIMD4<Float>(x: 1.0, y: 0.0, z: 0.0, w:1.0)
    self.st = SIMD2<Float>(x: 0.0, y: 0.0)
  }
  
  public init(position:  SIMD4<Float>, normal:  SIMD4<Float>, color: SIMD4<Float> = SIMD4<Float>(0,0,1,1), st: SIMD2<Float>)
  {
    self.position = position
    self.normal =  normal
    self.color = color
    self.st = st
  }
  
  public var description: String
  {
    return "{position: \(position), normal: \(normal)}"
  }
}
