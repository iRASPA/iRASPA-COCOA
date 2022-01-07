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
import simd

public struct RKGlobalAxesUniforms
{
  public var axesBackgroundColor: SIMD4<Float> = SIMD4<Float>(x: 0.8, y: 0.8, z: 0.8, w: 0.25)
  public var textColor: float3x4 = float3x4(SIMD4<Float>(x: 0.0, y: 0.0, z: 0.0, w: 1.0), SIMD4<Float>(x: 0.0, y: 0.0, z: 0.0, w: 1.0), SIMD4<Float>(x: 0.0, y: 0.0, z: 0.0, w: 1.0))
  public var textDisplacement: float3x4 = float3x4(SIMD4<Float>(0.0,0.0,0.0,0.0), SIMD4<Float>(0.0,0.0,0.0,0.0), SIMD4<Float>(0.0,0.0,0.0,0.0))
  public var axesBackGroundStyle: Int32 = 1
  public var axesScale: Float = 5.0
  public var centerScale: Float = 0.0
  public var textOffset: Float = 0.0
  public var textScale: SIMD4<Float> = SIMD4<Float>(x: 2.0, y: 2.0, z: 2.0, w: 1.0)

  public init(project: RKRenderDataSource)
  {
    axesBackgroundColor = SIMD4<Float>(color: project.renderAxes.axesBackgroundColor)
    axesBackGroundStyle = Int32(project.renderAxes.axesBackgroundStyle.rawValue)
    
    axesScale = Float(project.renderAxes.axisScale)
    centerScale = Float(project.renderAxes.centerScale)
    textOffset = Float(project.renderAxes.textOffset)
    
    textColor[0] = SIMD4<Float>(color: project.renderAxes.textColorX)
    textColor[1] = SIMD4<Float>(color: project.renderAxes.textColorY)
    textColor[2] = SIMD4<Float>(color: project.renderAxes.textColorZ)
    
    textDisplacement[0] = SIMD4<Float>(SIMD3<Float>(project.renderAxes.textDisplacementX), 1.0)
    textDisplacement[1] = SIMD4<Float>(SIMD3<Float>(project.renderAxes.textDisplacementY), 1.0)
    textDisplacement[2] = SIMD4<Float>(SIMD3<Float>(project.renderAxes.textDisplacementZ), 1.0)
    
    textScale = SIMD4<Float>(SIMD3<Float>(project.renderAxes.textScale), 1.0)
  }
}
