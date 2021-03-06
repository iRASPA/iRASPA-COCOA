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
import simd

public struct RKLight
{
  public var position: SIMD4<Float> = SIMD4<Float>(x:0.0, y:0.0, z: 100.0, w: 0.0)  // w=0 directional light, w=1.0 positional light
  public var ambient: SIMD4<Float> = SIMD4<Float>(color: NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
  public var diffuse: SIMD4<Float> = SIMD4<Float>(color: NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
  public var specular: SIMD4<Float> = SIMD4<Float>(color: NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
  
  public var spotDirection: SIMD4<Float> = SIMD4<Float>(x:1.0, y:1.0, z: 1.0, w:0.0)
  public var constantAttenuation: Float = 1.0
  public var linearAttenuation: Float = 1.0
  public var quadraticAttenuation: Float = 1.0
  public var spotCutoff: Float = 1.0
  
  
  public var spotExponent: Float = 1.0
  public var shininess: Float = 4.0
  public var pad1: Float = 0.0
  public var pad2: Float = 0.0
  
  public var pad3: Float = 0.0
  public var pad4: Float = 0.0
  public var pad5: Float = 0.0
  public var pad6: Float = 0.0
  
  public init()
  {
    
  }
  
  public init(project: RKRenderDataSource, light: Int)
  {
    self.ambient = Float(project.renderLights[light].ambientIntensity) * SIMD4<Float>(color: project.renderLights[light].ambient)
    self.diffuse = Float(project.renderLights[light].diffuseIntensity) * SIMD4<Float>(color: project.renderLights[light].diffuse)
    self.specular = Float(project.renderLights[light].specularIntensity) * SIMD4<Float>(color: project.renderLights[light].specular)
    self.shininess = Float(project.renderLights[light].shininess)
  }
}

