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

// Note: must be aligned at vector-length (16-bytes boundaries, 4 Floats of 4 bytes)
// current number of bytes: 512 bytes
public struct RKLightUniforms
{
  public var lights: [RKLight] = [RKLight(),RKLight(),RKLight(),RKLight()]
  
  public init()
  {
  }
  
  public init(project: RKRenderDataSource)
  {
    
    self.lights[0].ambient = Float(project.renderLights[0].ambientIntensity) * SIMD4<Float>(color: project.renderLights[0].ambient)
    self.lights[0].diffuse = Float(project.renderLights[0].diffuseIntensity) * SIMD4<Float>(color: project.renderLights[0].diffuse)
    self.lights[0].specular = Float(project.renderLights[0].specularIntensity) * SIMD4<Float>(color: project.renderLights[0].specular)
    self.lights[0].shininess = Float(project.renderLights[0].shininess)
  }
}
