/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 J.Vreede@uva.nl      https://www.uva.nl/en/profile/v/r/j.vreede/j.vreede.html
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
import simd

/// The material of the translucent spheres that show the blocking pockets of a structure.
///
/// One material per structure rather than per pocket: the pockets of a structure describe the same
/// inaccessible pore space and are read from a single file. The spheres are drawn two-sided, and the far
/// wall takes this material with the normal flipped, so there is no separate inside material.
public struct RKBlockingPocketUniforms
{
  /// The opacity of a single sphere face. A sphere is drawn back-face then front-face, so a pocket covers
  /// a fragment twice, and the value is deliberately low enough to keep the framework visible through it.
  public static let opacity: Double = 0.3
  
  public var ambient: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
  public var diffuse: SIMD4<Float> = SIMD4<Float>(x: 0.2, y: 0.65, z: 0.85, w: 1.0)
  public var specular: SIMD4<Float> = SIMD4<Float>(x: 0.92, y: 0.92, z: 0.92, w: 1.0)
  public var hdr: Int32 = 1
  public var hdrExposure: Float = 1.5
  public var shininess: Float = 4.0
  public var pad0: Float = 0.0
  
  // The payload is 64 bytes, padded out to a 256-byte stride because the buffer is indexed per structure
  // and Metal requires a constant buffer offset to be a multiple of 256 on iOS.
  private var pad1: float4x4 = float4x4(Double4x4: double4x4())
  private var pad2: float4x4 = float4x4(Double4x4: double4x4())
  private var pad3: float4x4 = float4x4(Double4x4: double4x4())
  //----------------------------------------  256 bytes boundary
  
  public init()
  {
    
  }
  
  public init(structure: RKRenderObject)
  {
    if let structure: RKRenderBlockingPocketsSource = structure as? RKRenderBlockingPocketsSource
    {
      let opacity: Double = RKBlockingPocketUniforms.opacity
      
      self.ambient = Float(structure.blockingPocketsFrontSideAmbientIntensity) * SIMD4<Float>(color: structure.blockingPocketsFrontSideAmbientColor, opacity: opacity)
      self.diffuse = Float(structure.blockingPocketsFrontSideDiffuseIntensity) * SIMD4<Float>(color: structure.blockingPocketsFrontSideDiffuseColor, opacity: opacity)
      self.specular = Float(structure.blockingPocketsFrontSideSpecularIntensity) * SIMD4<Float>(color: structure.blockingPocketsFrontSideSpecularColor, opacity: opacity)
      
      self.hdr = structure.blockingPocketsFrontSideHDR ? 1 : 0
      self.hdrExposure = Float(structure.blockingPocketsFrontSideHDRExposure)
      self.shininess = Float(structure.blockingPocketsFrontSideShininess)
    }
  }
}
