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

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import simd
import MathKit
import BinaryCodable

public enum RKLightType: Int
{
  case directional = 0
  case point = 1
  case spot = 2

  public var displayName: String
  {
    switch self
    {
    case .directional: return "Directional"
    case .point: return "Point"
    case .spot: return "Spot"
    }
  }

  /// Directional lights carry a direction in `position`, the other two a location, which is the
  /// distinction the shaders make through `position.w`.
  public var isPositional: Bool
  {
    return self != .directional
  }
}

/// A named set of lights. The emulations translate the documented defaults of other molecular viewers
/// into this model; they do not reproduce those renderers, so treat them as a close starting point rather
/// than a pixel match. `custom` is what one ends up with after editing a light, not something one asks
/// for, so it is absent from `presets`.
public enum RKLightStyle: Int
{
  case custom = -1

  /// Raw value zero has always stood for the bare camera light, so documents written before this style
  /// was named Camera still decode to the rig they were saved with.
  case camera = 0
  case vmd = 1
  case chimeraX = 2
  case pymol = 3
  case jmol = 4
  case studio = 5
  case rembrandt = 6
  case publication = 7
  case `default` = 8

  public static let presets: [RKLightStyle] = [.default, .camera, .vmd, .chimeraX, .pymol, .jmol, .studio, .rembrandt, .publication]

  /// Part of a style, both applied when one is selected and required to match for the style to still be
  /// named. Zero keeps ambient occlusion to the ambient term, which is the physically correct treatment
  /// and what a rig with several lights wants. Camera asks for one, the legacy iRASPA behaviour of
  /// letting occlusion darken the direct light too: a lone headlight leaves almost nothing for occlusion
  /// to act on otherwise, since it lights very nearly what it sees.
  public var ambientOcclusionStrength: Double
  {
    switch self
    {
    case .camera: return 1.0
    default: return 0.0
    }
  }

  /// Part of a style in the same way the rig is. Every preset leaves ambient neutral at one: it multiplies
  /// the material's own ambient, which the representation style owns, so anything less would darken every
  /// representation style by that factor and take Fancy, which is lit by ambient alone, close to black.
  public var sceneAmbientIntensity: Double
  {
    return 1.0
  }

  public var sceneAmbientColor: NSColor
  {
    return NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  }

  public var displayName: String
  {
    switch self
    {
    case .custom: return "Custom"
    case .default: return "Default"
    case .camera: return "Camera"
    case .vmd: return "VMD"
    case .chimeraX: return "ChimeraX"
    case .pymol: return "PyMOL"
    case .jmol: return "Jmol"
    case .studio: return "Three-Point Studio"
    case .rembrandt: return "Rembrandt"
    case .publication: return "Publication"
    }
  }
}

public struct RKRenderLight
{
  private static var classVersionNumber: Int = 2

  /// The photographic roles, in the slot order of a rig and of the inspector cells.
  public enum Role: Int, CaseIterable
  {
    case camera = 0
    case key = 1
    case fill = 2
    case side = 3
    case rim = 4
    case backlight = 5
    case hair = 6
    case butterfly = 7

    public var displayName: String
    {
      switch self
      {
      case .camera: return "Camera"
      case .key: return "Key"
      case .fill: return "Fill"
      case .side: return "Side/Split"
      case .rim: return "Rim/Kicker"
      case .backlight: return "Backlight/Silhouette"
      case .hair: return "Hair/Top"
      case .butterfly: return "Butterfly/Paramount"
      }
    }
  }

  public var isEnabled: Bool = true
  public var type: RKLightType = .directional
  
  /// Defined in eye space, so the light travels with the camera. w=0 directional, w=1 positional.
  ///
  /// On the view axis, which is the camera light. `standardRig` overrides this for every other role;
  /// note that a light sitting exactly at the camera reduces the diffuse term to `N·V`, so it flattens
  /// the surfaces whose shape one is trying to read. That is what the off-axis key light is for.
  public var position: SIMD4<Double> = SIMD4<Double>(x: 0.0, y: 0.0, z: 100.0, w: 0.0)
  /// Not used for rendering, and not editable. Ambient describes the environment rather than one lamp, so
  /// it is a property of the scene: see `sceneAmbient` in Common.h. The pair is kept because documents
  /// written before ambient moved still hold it, and the move reads it to recover the ambient level such a
  /// document was saved with.
  public var ambient: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var diffuse: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var specular: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var ambientIntensity: Double = 0.0
  public var diffuseIntensity: Double = 1.0
  public var specularIntensity: Double = 1.0
  public var shininess: Double = 4.0
  /// No distance falloff by default. Structures are modelled in Angstrom, so a light placed a hundred
  /// units from the origin would be attenuated to nothing by a quadratic term, and switching a light
  /// from directional to point would simply turn it black.
  public var constantAttenuation: Double = 1.0
  public var linearAttenuation: Double = 0.0
  public var quadraticAttenuation: Double = 0.0
  /// Aimed into the scene, away from the viewer, which is the useful direction for a spot placed in
  /// front of the structure. Only consulted for the spot type.
  public var spotDirection: SIMD3<Double> = SIMD3<Double>(x: 0.0, y: 0.0, z: -1.0)
  /// The half angle of the cone in degrees. The previous default of 1 degree predates the spot type
  /// being reachable and would have given a cone too narrow to see.
  public var spotCutoff: Double = 45.0
  public var spotExponent: Double = 1.0
  
  /// Whether this light is able to put anything into shadow.
  ///
  /// A directional light shining along the view axis is not: it travels with the line of sight, so
  /// anything that would stand between it and a surface stands between the eye and that surface too,
  /// and is therefore what the eye sees instead. The legacy camera-light rig is made entirely of such
  /// lights, so asking this first lets the shadow pass be skipped for it rather than traced and found
  /// to have changed nothing.
  ///
  /// The tolerance scales with the distance because the position is a direction here, and only its
  /// bearing matters. Under perspective the off-axis pixels see a light of this kind at a slight angle,
  /// so a shadow of a pixel or two is given up in exchange for skipping the pass.
  public var castsShadows: Bool
  {
    if !isEnabled
    {
      return false
    }
    if type != .directional
    {
      return true
    }

    // eye space: z is the view axis, so a light with no lateral offset shines straight down it
    let lateral: Double = max(abs(position.x), abs(position.y))
    return !(position.z > 0.0 && lateral < 1.0e-3 * position.z)
  }

  public init()
  {
    
  }
  
  /// The four lights a project starts with: a key light, and a fill, rim and bounce that are switched
  /// off. The three extras are placed where they conventionally sit relative to the viewer, so that
  /// enabling one gives a usable result without first having to dial in a position.
  /// A light for each `Role`. Positions are in eye space, so x runs to the right, y upwards
  /// and z towards the viewer, which puts a light behind the structure at negative z. Only the camera
  /// light starts on, being the look iRASPA has always opened with. None of them carries ambient, which
  /// belongs to the scene instead.
  public static func standardRig() -> [RKRenderLight]
  {
    let rig: [(x: Double, y: Double, z: Double, diffuse: Double, specular: Double)] =
        [(   0.0,   0.0,  100.0, 1.0, 1.0),  // camera, straight down the view axis
         ( -30.0,  40.0,  100.0, 1.0, 1.0),  // key, up and to the left
         (  60.0,  10.0,   80.0, 0.4, 0.2),  // fill, opposite the key and dim
         ( 100.0,   0.0,    0.0, 0.7, 0.3),  // side, level with the structure and square on
         (  60.0,  25.0,  -70.0, 0.6, 0.8),  // rim, behind and to the side, mostly specular
         (   0.0,   0.0, -100.0, 0.8, 0.4),  // backlight, straight behind
         (   0.0, 100.0,  -25.0, 0.6, 0.6),  // hair, above and a little behind
         (   0.0,  80.0,   60.0, 0.9, 0.5)]  // butterfly, high and in front

    return rig.enumerated().map
    {
      var light: RKRenderLight = RKRenderLight()
      light.isEnabled = ($0.offset == 0)

      // w is derived from the light type when the uniforms are built, so it is left at zero here
      light.position = SIMD4<Double>(x: $0.element.x, y: $0.element.y, z: $0.element.z, w: 0.0)
      light.ambientIntensity = 0.0
      light.diffuseIntensity = $0.element.diffuse
      light.specularIntensity = $0.element.specular
      return light
    }
  }

  /// One switched-on slot of a lighting style: the role it fills, where it sits in eye space, and the two
  /// levels plus the specular exponent it contributes. Ambient is absent because it belongs to the scene,
  /// and a style names it through `RKLightStyle.sceneAmbientIntensity`.
  private struct StyleLight
  {
    let role: Role
    let x: Double
    let y: Double
    let z: Double
    let diffuse: Double
    let specular: Double
    let shininess: Double

    /// Only the Default rig tints its lights; every emulation leaves these white because the programs
    /// being emulated light with white.
    var diffuseColor: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    var specularColor: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  }

  /// The slots a style switches on; every other role stays off. Where another program's light is given as
  /// the direction it shines, the position here is that direction negated, and the sign conventions have
  /// been resolved so the highlight lands where that program puts it, upper left in every case.
  ///
  /// Note that a light's shininess adds to the material's own, so these exponents land near rather than
  /// exactly on the published figure.
  ///
  /// No light here carries ambient: ambient describes the environment, so it is a property of the scene and
  /// a style sets it through `sceneAmbientIntensity`. Note also that the ambient level each emulated
  /// program publishes is not reproducible at all, because in this renderer the amount of ambient a surface
  /// takes belongs to its material and the representation style owns that: Default asks for 0.2 while Fancy
  /// asks for 1.0 and zeroes diffuse outright, so a Fancy atom takes its whole colour from ambient. What
  /// distinguishes these styles is therefore the direction, level and specular of their key, fill and rim.
  private static func styleLights(for style: RKLightStyle) -> [StyleLight]
  {
    switch style
    {
    case .custom, .camera:
      return []

    // A four-light rig meant to look good rather than to imitate anything. The key sits high and to the
    // left for shape, a dim fill opposite it keeps the shadow side readable, and a rim from behind draws a
    // bright edge that lifts the structure off the background. The key is warmed and the fill and rim
    // cooled by a few percent, which reads as depth; the tint is kept small on purpose because atom
    // colours carry meaning and must stay recognisable. The camera light carries the ambient and only a
    // little diffuse, so a face turned straight at the viewer is never unlit while it is rotated.
    case .default:
      let warm: NSColor = NSColor(red: 1.00, green: 0.96, blue: 0.90, alpha: 1.0)
      let cool: NSColor = NSColor(red: 0.88, green: 0.93, blue: 1.00, alpha: 1.0)
      let coolNeutral: NSColor = NSColor(red: 0.94, green: 0.97, blue: 1.00, alpha: 1.0)
      let white: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

      return [StyleLight(role: .camera, x:   0.0, y:   0.0, z: 100.0, diffuse: 0.12, specular: 0.00, shininess:  4.0),
              StyleLight(role: .key,    x: -45.0, y:  55.0, z:  85.0, diffuse: 0.80, specular: 0.55, shininess: 28.0,
                         diffuseColor: warm, specularColor: white),
              StyleLight(role: .fill,   x:  70.0, y: -20.0, z:  65.0, diffuse: 0.28, specular: 0.00, shininess:  4.0,
                         diffuseColor: cool, specularColor: white),
              StyleLight(role: .rim,    x:  55.0, y:  30.0, z: -78.0, diffuse: 0.32, specular: 0.70, shininess: 44.0,
                         diffuseColor: coolNeutral, specularColor: coolNeutral)]

    // VMD's Opaque material is diffuse 0.65 and specular 0.50 at a Phong exponent of 40, and lights 0
    // and 1 are the two of its four that start on. Its material ambient of 0.00, which is what makes the
    // far side of a VMD structure go black, is not something a light can express here.
    case .vmd:
      return [StyleLight(role: .camera, x:  -10.0, y:  10.0, z: 100.0, diffuse: 0.65, specular: 0.50, shininess: 40.0),
              StyleLight(role: .key,    x: -100.0, y: 200.0, z:  50.0, diffuse: 0.65, specular: 0.50, shininess: 40.0)]

    // ChimeraX simple lighting is key 1.0 and fill 0.5. Its key shines along (1,-1,-1), that is from the
    // upper left front, and its fill along (-0.2,-0.2,-0.959). Only the key carries specular, at the
    // default material shininess of 30.
    case .chimeraX:
      return [StyleLight(role: .key,  x: -58.0, y: 58.0, z: 58.0, diffuse: 1.0, specular: 0.3, shininess: 30.0),
              StyleLight(role: .fill, x:  20.0, y: 20.0, z: 96.0, diffuse: 0.5, specular: 0.0, shininess: 30.0)]

    // PyMOL is direct 0.45 from the camera and reflect 0.45 for its one movable light, with shininess 55
    // and specular_intensity 0.5. spec_direct is 0, so the camera light carries no highlight.
    case .pymol:
      return [StyleLight(role: .camera, x:   0.0, y:  0.0, z: 100.0, diffuse: 0.45, specular: 0.0, shininess: 55.0),
              StyleLight(role: .key,    x: -40.0, y: 40.0, z: 100.0, diffuse: 0.45, specular: 0.5, shininess: 55.0)]

    // Jmol is diffusePercent 84 and specularPercent 22, lit from the upper left front. Its
    // specularExponent of 6 is a power of two, hence 64.
    case .jmol:
      return [StyleLight(role: .key, x: -60.0, y: 60.0, z: 80.0, diffuse: 0.84, specular: 0.22, shininess: 64.0)]

    // The photographic three-point setup this rig is named for, with the camera light out of the way.
    case .studio:
      return [StyleLight(role: .key,  x: -30.0, y: 40.0, z: 100.0, diffuse: 1.00, specular: 0.8, shininess: 8.0),
              StyleLight(role: .fill, x:  60.0, y: 10.0, z:  80.0, diffuse: 0.35, specular: 0.1, shininess: 8.0),
              StyleLight(role: .rim,  x:  60.0, y: 25.0, z: -70.0, diffuse: 0.60, specular: 0.9, shininess: 8.0)]

    // A single hard key well off axis, with no fill, for high contrast.
    case .rembrandt:
      return [StyleLight(role: .key, x: -70.0, y: 70.0, z: 60.0, diffuse: 1.0, specular: 0.6, shininess: 16.0)]

    // Even and matte with no highlights at all, for figures where shading and glare hide detail.
    case .publication:
      return [StyleLight(role: .camera, x: 0.0, y: 0.0, z: 100.0, diffuse: 0.6, specular: 0.0, shininess: 4.0)]
    }
  }

  /// The lights of a named style, or nil for `custom`, which stands for whatever is already there.
  public static func rig(for style: RKLightStyle) -> [RKRenderLight]?
  {
    if style == .custom
    {
      return nil
    }
    if style == .camera
    {
      return RKRenderLight.standardRig()
    }

    var lights: [RKRenderLight] = RKRenderLight.standardRig()
    for index in lights.indices
    {
      lights[index].isEnabled = false
    }

    for entry in RKRenderLight.styleLights(for: style)
    {
      let slot: Int = entry.role.rawValue
      lights[slot].isEnabled = true
      lights[slot].type = .directional

      // w is derived from the light type when the uniforms are built, so it is left at zero here
      lights[slot].position = SIMD4<Double>(x: entry.x, y: entry.y, z: entry.z, w: 0.0)
      lights[slot].diffuseIntensity = entry.diffuse
      lights[slot].specularIntensity = entry.specular
      lights[slot].shininess = entry.shininess
      lights[slot].diffuse = entry.diffuseColor
      lights[slot].specular = entry.specularColor
    }
    return lights
  }

  /// The rig a new document starts with.
  public static func defaultRig() -> [RKRenderLight]
  {
    return RKRenderLight.rig(for: .default) ?? RKRenderLight.standardRig()
  }

  /// The style that lights the scene the same way as these lights, scene ambient and occlusion strength,
  /// or `custom` when none does. This is rechecked after every edit, the way the representation style in
  /// the appearance inspector is, so putting a value back by hand brings the name back instead of leaving
  /// it stuck on custom.
  public static func style(matching lights: [RKRenderLight],
                           sceneAmbientIntensity: Double,
                           sceneAmbientColor: NSColor,
                           ambientOcclusionStrength: Double) -> RKLightStyle
  {
    for style in RKLightStyle.presets
    {
      if let rig: [RKRenderLight] = RKRenderLight.rig(for: style), rig.count == lights.count,
         abs(style.ambientOcclusionStrength - ambientOcclusionStrength) < 1.0e-3,
         abs(style.sceneAmbientIntensity - sceneAmbientIntensity) < 1.0e-3,
         RKRenderLight.colorsMatch(style.sceneAmbientColor, sceneAmbientColor),
         zip(rig, lights).allSatisfy({ $0.0.matchesInEffect($0.1) })
      {
        return style
      }
    }
    return .custom
  }

  /// Whether two lights light the scene identically. A light that is off cannot, whatever it carries, so
  /// switching one on, playing with it and switching it off again returns to the named style. The ambient
  /// pair is left out of the comparison because it no longer reaches the shaders, which also means a
  /// document written before ambient moved out of the lights still matches the style it names.
  public func matchesInEffect(_ other: RKRenderLight) -> Bool
  {
    if self.isEnabled != other.isEnabled
    {
      return false
    }
    if !self.isEnabled
    {
      return true
    }

    let tolerance: Double = 1.0e-3
    var matches: Bool = self.type == other.type &&
                        abs(self.position.x - other.position.x) < tolerance &&
                        abs(self.position.y - other.position.y) < tolerance &&
                        abs(self.position.z - other.position.z) < tolerance &&
                        abs(self.diffuseIntensity - other.diffuseIntensity) < tolerance &&
                        abs(self.specularIntensity - other.specularIntensity) < tolerance &&
                        abs(self.shininess - other.shininess) < tolerance &&
                        RKRenderLight.colorsMatch(self.diffuse, other.diffuse) &&
                        RKRenderLight.colorsMatch(self.specular, other.specular)

    if matches, self.type != .directional
    {
      // only a light placed at a location falls off with distance
      matches = abs(self.constantAttenuation - other.constantAttenuation) < tolerance &&
                abs(self.linearAttenuation - other.linearAttenuation) < tolerance &&
                abs(self.quadraticAttenuation - other.quadraticAttenuation) < tolerance
    }

    if matches, self.type == .spot
    {
      matches = abs(self.spotCutoff - other.spotCutoff) < tolerance &&
                abs(self.spotExponent - other.spotExponent) < tolerance &&
                abs(self.spotDirection.x - other.spotDirection.x) < tolerance &&
                abs(self.spotDirection.y - other.spotDirection.y) < tolerance &&
                abs(self.spotDirection.z - other.spotDirection.z) < tolerance
    }

    return matches
  }

  private static func colorsMatch(_ first: NSColor, _ second: NSColor) -> Bool
  {
    // a colour well hands back a different colour space than the literals a style is built from, so both
    // are converted before their components are compared
    guard let a: NSColor = first.usingColorSpace(NSColorSpace.deviceRGB),
          let b: NSColor = second.usingColorSpace(NSColorSpace.deviceRGB)
    else
    {
      return first == second
    }

    let tolerance: CGFloat = 1.0e-3
    return abs(a.redComponent - b.redComponent) < tolerance &&
           abs(a.greenComponent - b.greenComponent) < tolerance &&
           abs(a.blueComponent - b.blueComponent) < tolerance
  }

  public init(light: RKRenderLight)
  {
    self.isEnabled = light.isEnabled
    self.type = light.type
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
}

// MARK: -
// MARK: Binary encoding and decoding

extension RKRenderLight: BinaryEncodable, BinaryDecodable
{
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(RKRenderLight.classVersionNumber)

    encoder.encode(self.isEnabled)
    encoder.encode(self.type.rawValue)
    encoder.encode(self.position)
    encoder.encode(self.ambient as PlatformColor)
    encoder.encode(self.diffuse as PlatformColor)
    encoder.encode(self.specular as PlatformColor)
    encoder.encode(self.ambientIntensity)
    encoder.encode(self.diffuseIntensity)
    encoder.encode(self.specularIntensity)
    encoder.encode(self.shininess)
    encoder.encode(self.constantAttenuation)
    encoder.encode(self.linearAttenuation)
    encoder.encode(self.quadraticAttenuation)
    encoder.encode(self.spotDirection)
    encoder.encode(self.spotCutoff)
    encoder.encode(self.spotExponent)
  }

  public init(fromBinary decoder: BinaryDecoder) throws
  {
    self.init()

    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > RKRenderLight.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }

    if readVersionNumber >= 2 // introduced in version 2
    {
      self.isEnabled = try decoder.decode(Bool.self)
      guard let type = RKLightType(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
      self.type = type
    }

    self.position = try decoder.decode(SIMD4<Double>.self)
    self.ambient = try decoder.decode(PlatformColor.self)
    self.diffuse = try decoder.decode(PlatformColor.self)
    self.specular = try decoder.decode(PlatformColor.self)
    self.ambientIntensity = try decoder.decode(Double.self)
    self.diffuseIntensity = try decoder.decode(Double.self)
    self.specularIntensity = try decoder.decode(Double.self)
    self.shininess = try decoder.decode(Double.self)
    self.constantAttenuation = try decoder.decode(Double.self)
    self.linearAttenuation = try decoder.decode(Double.self)
    self.quadraticAttenuation = try decoder.decode(Double.self)
    self.spotDirection = try decoder.decode(SIMD3<Double>.self)
    self.spotCutoff = try decoder.decode(Double.self)
    self.spotExponent = try decoder.decode(Double.self)
  }
}
