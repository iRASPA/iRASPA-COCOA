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

// IMPORTANT: must be aligned on 256-bytes boundaries
// current number of bytes: 256 bytes
public struct RKShadowUniforms
{
  public var projectionMatrix: float4x4 = float4x4()
  public var viewMatrix: float4x4 = float4x4()
  public var shadowMatrix: float4x4 = float4x4()
  public var normalMatrix: float4x4 = float4x4()
  
  public init()
  {
    
  }
  
  public init(projectionMatrix: double4x4, viewMatrix: double4x4, modelMatrix: double4x4)
  {
    let OpenGLToMetalMatrix:double4x4 = double4x4([[1.0, 0.0, 0.0, 0.0], [0.0, 1.0, 0.0, 0.0], [0.0, 0.0, 0.5, 0.0], [0.0, 0.0, 0.5, 1.0]])
    let ViewToMetalDepthTextureMatrix:double4x4 = double4x4([[0.5, 0.0, 0.0, 0.0], [0.0, 0.5, 0.0, 0.0], [0.0, 0.0, 0.5, 0.0], [0.5, 0.5, 0.5, 1.0]])
    
    let mvpMatrix: double4x4 = projectionMatrix * viewMatrix * modelMatrix
    self.projectionMatrix = float4x4(Double4x4: OpenGLToMetalMatrix * projectionMatrix)
    self.viewMatrix = float4x4(Double4x4: viewMatrix * modelMatrix)
    self.shadowMatrix = float4x4(Double4x4: ViewToMetalDepthTextureMatrix * mvpMatrix)
    let normalMatrix: double3x3 = double3x3(Double4x4: viewMatrix * modelMatrix).inverse.transpose
    self.normalMatrix = float4x4(Double4x4: double4x4(Double3x3: normalMatrix))
  }
}


