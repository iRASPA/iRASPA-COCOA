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

// Note: must be aligned at vector-length (16-bytes boundaries, 4 Floats of 4 bytes)
// current number of bytes: 1040 bytes, being 8 lights of 128 bytes followed by the scene ambient
public struct RKLightUniforms
{
  /// One slot per photographic role, matching `NUMBER_OF_LIGHTS` in Common.h and the order of
  /// `RKRenderLight.standardRig()`.
  public static let numberOfLights: Int = 8

  public var lights: [RKLight] = [RKLight](repeating: RKLight(), count: RKLightUniforms.numberOfLights)

  /// Ambient light for the scene as a whole. Deliberately not a property of any single light: see
  /// `sceneAmbient` in Common.h.
  public var sceneAmbient: SIMD4<Float> = SIMD4<Float>(1.0, 1.0, 1.0, 1.0)

  public static var bufferLength: Int
  {
    return numberOfLights * MemoryLayout<RKLight>.stride + MemoryLayout<SIMD4<Float>>.stride
  }

  /// `lights` is a Swift array and so holds its elements away from the rest of the struct, meaning the
  /// struct cannot be handed to Metal as it stands. This lays the two parts out back to back the way
  /// `LightUniforms` expects to find them.
  public func packed() -> [UInt8]
  {
    var bytes: [UInt8] = [UInt8](repeating: 0, count: RKLightUniforms.bufferLength)
    let ambientOffset: Int = RKLightUniforms.numberOfLights * MemoryLayout<RKLight>.stride

    bytes.withUnsafeMutableBytes
    { destination in
      self.lights.withUnsafeBytes
      { source in
        // guards against a rig that somehow holds more lights than the shaders declare
        destination.copyMemory(from: UnsafeRawBufferPointer(rebasing: source.prefix(ambientOffset)))
      }
      destination.storeBytes(of: self.sceneAmbient, toByteOffset: ambientOffset, as: SIMD4<Float>.self)
    }

    return bytes
  }

  public init()
  {
  }
  
  public init(project: RKRenderDataSource)
  {
    self.sceneAmbient = Float(project.renderSceneAmbientIntensity) * SIMD4<Float>(color: project.renderSceneAmbientColor)

    for i in 0..<min(self.lights.count, project.renderLights.count)
    {
      let light: RKRenderLight = project.renderLights[i]

      // the type is the source of truth for whether `position` names a direction or a location, so w is
      // derived from it rather than stored twice
      self.lights[i].position = SIMD4<Float>(x: Float(light.position.x),
                                             y: Float(light.position.y),
                                             z: Float(light.position.z),
                                             w: light.type.isPositional ? 1.0 : 0.0)
      // the light's own ambient is left at zero: ambient is carried by sceneAmbient instead
      self.lights[i].diffuse = Float(light.diffuseIntensity) * SIMD4<Float>(color: light.diffuse)
      self.lights[i].specular = Float(light.specularIntensity) * SIMD4<Float>(color: light.specular)
      self.lights[i].shininess = Float(light.shininess)

      self.lights[i].spotDirection = SIMD4<Float>(x: Float(light.spotDirection.x),
                                                  y: Float(light.spotDirection.y),
                                                  z: Float(light.spotDirection.z),
                                                  w: 0.0)
      self.lights[i].constantAttenuation = Float(light.constantAttenuation)
      self.lights[i].linearAttenuation = Float(light.linearAttenuation)
      self.lights[i].quadraticAttenuation = Float(light.quadraticAttenuation)
      self.lights[i].spotCutoff = Float(light.spotCutoff)
      self.lights[i].spotExponent = Float(light.spotExponent)

      self.lights[i].lightType = Float(light.type.rawValue)
      self.lights[i].enabled = light.isEnabled ? 1.0 : 0.0
    }
  }
}
