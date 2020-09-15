/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import simd


// Note: must be aligned at vector-length (16-bytes boundaries, 4 Floats of 4 bytes)
// current number of bytes: 512 bytes
public struct RKTransformationUniforms
{
  public enum RenderType: Int
  {
    case metal = 0
  }
  
  public var projectionMatrix: float4x4 = float4x4()
  public var viewMatrix: float4x4 = float4x4()
  public var mvpMatrix: float4x4 = float4x4()
  public var shadowMatrix: float4x4 = float4x4()
  public var projectionMatrixInverse: float4x4 = float4x4()
  public var viewMatrixInverse: float4x4 = float4x4()
  public var normalMatrix: float4x4 = float4x4()
  
  // moved 'numberOfMultiSamplePoints' to here (for downsampling when no structures are present)
  public var numberOfMultiSamplePoints: Int32 = 8;
  public var bloomLevel: Float = 1.0
  public var bloomPulse: Float = 1.0
  public var maximumEDRvalue: Float = 1.0
  var padVector2: SIMD4<Float> = SIMD4<Float>()
  var padVector3: SIMD4<Float> = SIMD4<Float>()
  var padvector4: SIMD4<Float> = SIMD4<Float>()
  
  public init()
  {
    
  }
  
  public init(projectionMatrix: double4x4, viewMatrix: double4x4, bloomLevel: Double, bloomPulse: Double, maximumExtendedDynamicRangeColorComponentValue maximumEDRvalue: CGFloat)
  {
    let OpenGLToMetalMatrix:double4x4 = double4x4([[1.0, 0.0, 0.0, 0.0], [0.0, 1.0, 0.0, 0.0], [0.0, 0.0, 0.5, 0.0], [0.0, 0.0, 0.5, 1.0]])
    let mvpMatrix: double4x4 = OpenGLToMetalMatrix * projectionMatrix * viewMatrix
    self.projectionMatrix = float4x4(Double4x4: OpenGLToMetalMatrix * projectionMatrix)
    self.viewMatrix = float4x4(Double4x4: viewMatrix)
    self.mvpMatrix = float4x4(Double4x4: mvpMatrix)
    self.shadowMatrix = float4x4(Double4x4: mvpMatrix)
    
    self.projectionMatrixInverse = float4x4(Double4x4: (OpenGLToMetalMatrix * projectionMatrix).inverse)
    self.viewMatrixInverse = float4x4(Double4x4: viewMatrix.inverse)
    
    let normalMatrix: double3x3 = double3x3(Double4x4: viewMatrix).inverse.transpose
    self.normalMatrix = float4x4(Double4x4: double4x4(Double3x3: normalMatrix))
    self.bloomLevel = Float(bloomLevel)
    self.bloomPulse = Float(bloomPulse)
    self.maximumEDRvalue = Float(maximumEDRvalue)
  }
}

