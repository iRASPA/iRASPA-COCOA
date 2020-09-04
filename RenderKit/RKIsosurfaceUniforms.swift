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
import simd

public struct RKIsosurfaceUniforms
{
  public var unitCellMatrix: float4x4 = float4x4(Double4x4: double4x4(1.0))
  public var unitCellNormalMatrix: float4x4 = float4x4(Double4x4: double4x4())
  
  public var ambientFrontSide: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
  public var diffuseFrontSide: SIMD4<Float> = SIMD4<Float>(x: 0.588235, y: 0.670588, z: 0.729412, w:1.0)
  public var specularFrontSide: SIMD4<Float> = SIMD4<Float>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
  public var frontHDR: Int32 = 1
  public var frontHDRExposure: Float = 1.5
  public var pad1: Float = 0.0
  public var shininessFrontSide: Float = 4.0
  
  public var ambientBackSide: SIMD4<Float> = SIMD4<Float>(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
  public var diffuseBackSide: SIMD4<Float> = SIMD4<Float>(x: 0.588235, y: 0.670588, z: 0.729412, w:1.0)
  public var specularBackSide: SIMD4<Float> = SIMD4<Float>(x: 0.9, y: 0.9, z: 0.9, w: 1.0)
  public var backHDR: Int32 = 1
  public var backHDRExposure: Float = 1.5
  public var pad2: Float = 0.0
  public var shininessBackSide: Float = 4.0
  
  public var hue: Float = 1.0
  public var saturation: Float = 1.0
  public var value: Float = 1.0
  public var pad3: Float = 0.0
  public var pad4: SIMD4<Float> = SIMD4<Float>()
  public var pad5: SIMD4<Float> = SIMD4<Float>()
  public var pad6: SIMD4<Float> = SIMD4<Float>()
  public var pad7: float4x4 = float4x4(Double4x4: double4x4())
  
  public var pad8: float4x4 = float4x4(Double4x4: double4x4())
  public var pad9: float4x4 = float4x4(Double4x4: double4x4())
  
  public init()
  {
    
  }
  
  public init(structure: RKRenderStructure)
  {
    let unitCellMatrix: double3x3 = structure.cell.unitCell
    self.unitCellMatrix = float4x4(Double3x3: unitCellMatrix)
    self.unitCellNormalMatrix = float4x4(Double3x3: unitCellMatrix.inverse.transpose)
    
    if let structure: RKRenderAdsorptionSurfaceSource = structure as? RKRenderAdsorptionSurfaceSource
    {
      self.hue = Float(structure.adsorptionSurfaceHue);
      self.saturation = Float(structure.adsorptionSurfaceSaturation);
      self.value = Float(structure.adsorptionSurfaceValue);
      
      self.frontHDR = structure.adsorptionSurfaceFrontSideHDR ? 1 : 0
      self.frontHDRExposure = Float(structure.adsorptionSurfaceFrontSideHDRExposure)
      self.ambientBackSide = Float(structure.adsorptionSurfaceBackSideAmbientIntensity) * SIMD4<Float>(color: structure.adsorptionSurfaceBackSideAmbientColor, opacity: structure.adsorptionSurfaceOpacity)
      self.diffuseBackSide = Float(structure.adsorptionSurfaceBackSideDiffuseIntensity) * SIMD4<Float>(color: structure.adsorptionSurfaceBackSideDiffuseColor, opacity: structure.adsorptionSurfaceOpacity)
      self.specularBackSide = Float(structure.adsorptionSurfaceBackSideSpecularIntensity) * SIMD4<Float>(color: structure.adsorptionSurfaceBackSideSpecularColor, opacity: structure.adsorptionSurfaceOpacity)
      self.shininessBackSide = Float(structure.adsorptionSurfaceBackSideShininess)
    
      self.backHDR = structure.adsorptionSurfaceBackSideHDR ? 1 : 0
      self.backHDRExposure = Float(structure.adsorptionSurfaceBackSideHDRExposure)
      self.ambientFrontSide = Float(structure.adsorptionSurfaceFrontSideAmbientIntensity) * SIMD4<Float>(color: structure.adsorptionSurfaceFrontSideAmbientColor, opacity: structure.adsorptionSurfaceOpacity)
      self.diffuseFrontSide = Float(structure.adsorptionSurfaceFrontSideDiffuseIntensity) * SIMD4<Float>(color: structure.adsorptionSurfaceFrontSideDiffuseColor, opacity: structure.adsorptionSurfaceOpacity)
      self.specularFrontSide = Float(structure.adsorptionSurfaceFrontSideSpecularIntensity) * SIMD4<Float>(color: structure.adsorptionSurfaceFrontSideSpecularColor, opacity: structure.adsorptionSurfaceOpacity)
      self.shininessFrontSide = Float(structure.adsorptionSurfaceFrontSideShininess)
    }
  }
  
}
