/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2019 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

import Cocoa
import simd
import MathKit

public struct RKRenderLight: Decodable
{
  private var versionNumber: Int = 1
  public var position: double4 = double4(x:0, y:0, z: 100.0, w: 0.0)
  public var ambient: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var diffuse: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var specular: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var ambientIntensity: Double = 1.0
  public var diffuseIntensity: Double = 1.0
  public var specularIntensity: Double = 1.0
  public var shininess: Double = 4.0
  public var constantAttenuation: Double = 1.0
  public var linearAttenuation: Double = 1.0
  public var quadraticAttenuation: Double = 1.0
  public var spotDirection: double3 = double3(x:1.0, y:1.0, z: 1.0)
  public var spotCutoff: Double = 1.0
  public var spotExponent: Double = 1.0
  
  public init()
  {
    
  }
  
  public init(light: RKRenderLight)
  {
    self.position = light.position
    self.ambient = light.ambient.copy() as! NSColor
    self.diffuse = light.diffuse.copy() as! NSColor
    self.specular = light.specular.copy() as! NSColor
    self.ambientIntensity = light.ambientIntensity
    self.diffuseIntensity = light.diffuseIntensity
    self.specularIntensity = light.specularIntensity
    self.shininess = light.shininess
    self.constantAttenuation = light.constantAttenuation
    self.linearAttenuation = light.linearAttenuation
    self.quadraticAttenuation = light.quadraticAttenuation
    self.spotDirection = light.spotDirection
    self.spotCutoff = light.spotCutoff
    self.spotExponent = light.spotExponent
  }
  
  
  // MARK: -
  // MARK: legacy decodable support
  
  public  init(from decoder: Decoder) throws
  {
    var container = try decoder.unkeyedContainer()
    
    let versionNumber: Int = try container.decode(Int.self)
    if versionNumber > self.versionNumber
    {
      
    }
    
    self.position = try container.decode(double4.self)
    self.ambient = try NSColor(float4: container.decode(float4.self))
    self.diffuse = try NSColor(float4: container.decode(float4.self))
    self.specular = try NSColor(float4: container.decode(float4.self))
    self.ambientIntensity = try container.decode(Double.self)
    self.diffuseIntensity = try container.decode(Double.self)
    self.specularIntensity = try container.decode(Double.self)
    self.shininess = try container.decode(Double.self)
    self.constantAttenuation = try container.decode(Double.self)
    self.linearAttenuation = try container.decode(Double.self)
    self.quadraticAttenuation = try container.decode(Double.self)
    self.spotDirection = try container.decode(double3.self)
    self.spotExponent = try container.decode(Double.self)
  }
  
}
