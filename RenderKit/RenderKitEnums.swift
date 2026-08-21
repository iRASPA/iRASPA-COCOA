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
import Metal
import simd
import MathKit
import SimulationKit
import SymmetryKit

public enum RKEnergySurfaceType: Int
{
  case isoSurface = 0
  case volumeRendering = 1
}

public enum RKPredefinedVolumeRenderingTransferFunction: Int
{
  case RASPA_PES = 0
  case CoolWarmDiverging = 1
  case Xray = 2
  case Gray = 3
  case Rainbow = 4
  case Turbo = 5
  case Gnuplot = 6
  case Spectral = 7
  case Cool = 8
  case Viridis = 9
  case Plasma = 10
  case Inferno = 11
  case Magma = 12
  case Cividis = 13
  case Spring = 14
  case Summer = 15
  case Autumn = 16
  case Winter = 17
  case Reds = 18
  case Blues = 19
  case Greens = 20
  case Purples = 21
  case Oranges = 22
}

public enum RKBackgroundType: Int
{
  case color = 0
  case linearGradient = 1
  case radialGradient = 2
  case image = 3
}

public enum RKBondColorMode: Int
{
  case uniform = 0
  case split = 1
  case smoothed_split = 2
}

public enum RKRenderQuality: Int
{
  case low = 0
  case medium = 1
  case high = 2
  case picture = 3
}

public enum RKImageQuality: Int
{
  case rgb_16_bits = 0
  case rgb_8_bits = 1
  case cmyk_16_bits = 2
  case cmyk_8_bits = 3
}

/// How a scene is turned into pixels.
///
/// `rasterization` is the imposter-based renderer. Under `rayTracing` the atoms, bonds and ribbons
/// are path traced instead, giving real shadows, ambient occlusion and colour bleeding. Interactive
/// frames and exports choose independently: the interactive mode is a property of the machine and
/// lives in the user defaults, while the export mode travels with the document.
public enum RKRenderMode: Int
{
  case rasterization = 0
  case rayTracing = 1
}

/// Which of the two edge cues of Tarini, Cignoni and Montani are drawn over the finished scene.
///
/// Both read the depth buffer alone, so neither knows or cares what geometry produced it. Contour
/// lines mark every depth discontinuity with a dark band whose width grows with the size of the
/// jump, which tells the eye where one surface ends and how far the next one lies behind it. Halos
/// darken whatever sits behind a nearer silhouette, which separates strands that cross. They exist
/// because occlusion alone leaves an open structure looking flat, the two cues carrying the depth
/// ordering that shading would otherwise have to.
public enum RKEdgeCueing: Int
{
  case off = 0
  case contours = 1
  case halos = 2
  case contoursAndHalos = 3

  public static let presets: [RKEdgeCueing] = [.off, .contours, .halos, .contoursAndHalos]

  public var displayName: String
  {
    switch self
    {
    case .off: return "None"
    case .contours: return "Contour lines"
    case .halos: return "Halos"
    case .contoursAndHalos: return "Contour lines and halos"
    }
  }

  public var description: String
  {
    switch self
    {
    case .off: return "off"
    case .contours: return "contour lines"
    case .halos: return "halos"
    case .contoursAndHalos: return "contour lines and halos"
    }
  }

  /// How the cues are drawn, as opposed to which of them are: contour strength, contour width in
  /// pixels, halo strength and halo radius in pixels.
  ///
  /// One setting for the whole image, while which cues appear is decided for each pixel from the
  /// structure that drew it. Two structures asking for contours therefore get the same contours,
  /// which is what keeps a picture looking drawn by one hand.
  public static let parameters: SIMD4<Float> = SIMD4<Float>(0.9, 3.0, 0.5, 4.0)

  public var drawsContours: Bool
  {
    return self == .contours || self == .contoursAndHalos
  }

  public var drawsHalos: Bool
  {
    return self == .halos || self == .contoursAndHalos
  }

  /// Marks a pixel as belonging to a structure at all, whatever cues it asked for.
  ///
  /// Kept apart from the choice of cues so that the compositing pass can tell an atom wanting none
  /// from the unit cell or the background, which look alike if only the choice is recorded. The
  /// difference matters for halos: an uncued atom still takes the halo of a ribbon passing in front
  /// of it, as does the background, while the unit cell is never drawn on.
  public static let stencilCueableBit: UInt8 = 0x80

  public static let stencilModeMask: UInt8 = 0x03

  /// What the molecular shaders write into the scene's stencil, read back by the compositing pass.
  public var stencilValue: UInt32
  {
    return UInt32(RKEdgeCueing.stencilCueableBit | (UInt8(self.rawValue) & RKEdgeCueing.stencilModeMask))
  }

  /// A depth-stencil state that records the cues of whatever wins the depth test.
  ///
  /// Replacing only when the fragment passes both tests means the value left behind is that of the
  /// nearest surface, whatever order the structures were drawn in.
  public static func cueingDepthStencilState(device: MTLDevice, depthCompareFunction: MTLCompareFunction = MTLCompareFunction.lessEqual, isDepthWriteEnabled: Bool = true) -> MTLDepthStencilState?
  {
    let stencilDescriptor: MTLStencilDescriptor = MTLStencilDescriptor()
    stencilDescriptor.stencilCompareFunction = MTLCompareFunction.always
    stencilDescriptor.stencilFailureOperation = MTLStencilOperation.keep
    stencilDescriptor.depthFailureOperation = MTLStencilOperation.keep
    stencilDescriptor.depthStencilPassOperation = MTLStencilOperation.replace
    stencilDescriptor.readMask = 0xFF
    stencilDescriptor.writeMask = 0xFF

    let descriptor: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = depthCompareFunction
    descriptor.isDepthWriteEnabled = isDepthWriteEnabled
    descriptor.frontFaceStencil = stencilDescriptor
    descriptor.backFaceStencil = stencilDescriptor
    return device.makeDepthStencilState(descriptor: descriptor)
  }

  /// The state everything that is not an atom, a bond or a ribbon draws with: it writes the mask too,
  /// but with a reference of zero, so that it clears rather than marks.
  ///
  /// Clearing rather than leaving the mask alone is what stops a contour running along a unit cell edge
  /// that crosses in front of an atom. The cell wins the depth test and owns the pixel, but if it left
  /// the stencil untouched the atom's mark would still be sitting there from earlier in the pass, and
  /// the compositing pass would read the pixel as an atom and outline it.
  public static func clearingDepthStencilState(device: MTLDevice) -> MTLDepthStencilState?
  {
    return cueingDepthStencilState(device: device)
  }
}

/// Rendering settings that describe the machine rather than the document, and so are stored in the
/// user defaults instead of in the project.
///
/// Only the interactive path lives here. How many samples a frame can afford before it stops
/// feeling responsive depends on the GPU in front of the user, so carrying these in a document
/// would mean a file authored on a fast machine crawls when opened on a slow one. The
/// corresponding export settings are on `RKRenderDataSource`.
public class RKRenderSettings
{
  public static let shared: RKRenderSettings = RKRenderSettings()

  public static let interactiveRenderModeKey: String = "nl.darkwing.iRASPA.interactiveRenderMode"
  public static let interactiveSampleCountKey: String = "nl.darkwing.iRASPA.interactiveSampleCount"
  public static let interactiveRotatingSampleCountKey: String = "nl.darkwing.iRASPA.interactiveRotatingSampleCount"
  public static let interactiveMaximumBouncesKey: String = "nl.darkwing.iRASPA.interactiveMaximumBounces"
  public static let interactiveShadowsKey: String = "nl.darkwing.iRASPA.interactiveShadows"

  public static let RenderModeDidChange: String = "RenderModeDidChange"

  /// Neither cap is a limit of the tracer, which takes any bounce count: they exist because both
  /// fields are freely editable and render time grows about linearly with the count, there being no
  /// Russian roulette to cut long paths short.
  ///
  /// Interactive frames are capped tightly, since a value entered by mistake there stalls the frame
  /// loop and can trip the GPU watchdog. An export only takes longer, so it is allowed much more
  /// than the image needs: energy decays by the surface albedo at every bounce, and on these open,
  /// mostly diffuse scenes the image stops changing visibly after a handful.
  public static let maximumSupportedInteractiveBounces: Int = 8
  public static let maximumSupportedPictureBounces: Int = 32

  /// Sample counts are capped for the same reason, and again far more tightly for interactive
  /// frames, which have to appear promptly, than for an export, which may simply take a while.
  public static let maximumSupportedInteractiveSamples: Int = 4096
  public static let maximumSupportedPictureSamples: Int = 65536

  /// True when the default Metal device supports the Metal 3 ray-tracing API.
  public static var isRayTracingSupported: Bool
  {
    guard let device: MTLDevice = MTLCreateSystemDefaultDevice() else {return false}
    return MetalPathTracerShader.isSupported(device: device)
  }

  /// True when that device walks the acceleration structures in dedicated hardware rather than in a
  /// shader. Asked once: it cannot change while the process runs, and the answer decides a default.
  public static let tracesRaysInHardware: Bool =
  {
    guard let device: MTLDevice = MTLCreateSystemDefaultDevice() else {return false}
    return MetalPathTracerShader.tracesRaysInHardware(device: device)
  }()

  /// Whether the render view spends a ray per light per pixel on shadows. Separate from the project's
  /// own shadow setting, which an export obeys wherever it is opened: an export may take as long as it
  /// needs, while a frame may not, so this defaults on only where the rays are traced in hardware.
  /// A machine that traces them in a shader can still be asked for them.
  public var interactiveShadows: Bool
  {
    get
    {
      guard let shadows: Bool = UserDefaults.standard.value(forKey: RKRenderSettings.interactiveShadowsKey) as? Bool else {return RKRenderSettings.tracesRaysInHardware}
      return shadows
    }
    set(newValue)
    {
      UserDefaults.standard.set(newValue, forKey: RKRenderSettings.interactiveShadowsKey)
    }
  }

  /// Ray tracing silently falls back to rasterization on unsupported hardware, so that a stale
  /// preference can never leave the user without an image.
  private func mode(forKey key: String) -> RKRenderMode
  {
    guard let rawValue: Int = UserDefaults.standard.value(forKey: key) as? Int,
          let mode: RKRenderMode = RKRenderMode(rawValue: rawValue) else {return RKRenderMode.rasterization}
    return mode
  }

  /// Drives the interactive render view, set from the Rendering menu.
  public var interactiveRenderMode: RKRenderMode
  {
    get
    {
      return mode(forKey: RKRenderSettings.interactiveRenderModeKey)
    }
    set(newValue)
    {
      UserDefaults.standard.set(newValue.rawValue, forKey: RKRenderSettings.interactiveRenderModeKey)
      NotificationCenter.default.post(name: Notification.Name(RKRenderSettings.RenderModeDidChange), object: self)
    }
  }

  /// Samples per pixel traced for an interactive frame drawn while the camera is at rest.
  /// Deliberately independent of the export sample count: an export can afford far more samples
  /// than a frame that has to appear promptly.
  public var interactiveSampleCount: Int
  {
    get
    {
      guard let count: Int = UserDefaults.standard.value(forKey: RKRenderSettings.interactiveSampleCountKey) as? Int else {return 32}
      return min(max(count, 1), RKRenderSettings.maximumSupportedInteractiveSamples)
    }
    set(newValue)
    {
      UserDefaults.standard.set(min(max(newValue, 1), RKRenderSettings.maximumSupportedInteractiveSamples), forKey: RKRenderSettings.interactiveSampleCountKey)
    }
  }

  /// Bounces traced for an interactive frame. Each bounce costs a full round of ray casts, so the
  /// count is capped: the field is editable and an unbounded value would let a typo hang the GPU
  /// long enough for the system to reset it.
  public var interactiveMaximumBounces: Int
  {
    get
    {
      guard let bounces: Int = UserDefaults.standard.value(forKey: RKRenderSettings.interactiveMaximumBouncesKey) as? Int else {return 2}
      return min(max(bounces, 0), RKRenderSettings.maximumSupportedInteractiveBounces)
    }
    set(newValue)
    {
      UserDefaults.standard.set(min(max(newValue, 0), RKRenderSettings.maximumSupportedInteractiveBounces), forKey: RKRenderSettings.interactiveMaximumBouncesKey)
    }
  }

  /// The settings the interactive view traces with, sample count aside; `samplesPerInteractiveFrame`
  /// supplies that, since it depends on whether the camera is moving. The occlusion strength is left
  /// at its default here and overwritten by the renderer from the project, which owns it.
  public var interactivePathTracerSettings: RKPathTracerSettings
  {
    var settings: RKPathTracerSettings = RKPathTracerSettings.standard
    settings.sampleCount = interactiveSampleCount
    settings.maximumBounces = interactiveMaximumBounces
    return settings
  }

  /// Samples per pixel traced for an interactive frame drawn while the camera is being moved.
  public var interactiveRotatingSampleCount: Int
  {
    get
    {
      guard let count: Int = UserDefaults.standard.value(forKey: RKRenderSettings.interactiveRotatingSampleCountKey) as? Int else {return 8}
      return min(max(count, 1), RKRenderSettings.maximumSupportedInteractiveSamples)
    }
    set(newValue)
    {
      UserDefaults.standard.set(min(max(newValue, 1), RKRenderSettings.maximumSupportedInteractiveSamples), forKey: RKRenderSettings.interactiveRotatingSampleCountKey)
    }
  }

  /// Samples traced for one interactive frame. Every frame is a complete trace rather than an
  /// instalment of a running average: both counts estimate the same image, so they agree on the
  /// shading and differ only in how much noise is left on it. That is what keeps the colours from
  /// shifting when the camera starts or stops moving.
  public static func samplesPerInteractiveFrame(renderQuality: RKRenderQuality) -> Int
  {
    switch renderQuality
    {
    case RKRenderQuality.high, RKRenderQuality.picture:
      return RKRenderSettings.shared.interactiveSampleCount
    case RKRenderQuality.medium, RKRenderQuality.low:
      return RKRenderSettings.shared.interactiveRotatingSampleCount
    }
  }
}

public enum RKSelectionStyle: Int
{
  case none = 0
  case WorleyNoise3D = 1
  case striped = 2
  case glow = 3
}

public enum RKTextStyle: Int
{
  case flatBillboard = 0
}

public enum RKTextEffect: Int
{
  case none = 0
  case glow = 1
  case pulsate = 2
  case squiggle = 3
}

public enum RKTextType: Int
{
  case none = 0
  case displayName = 1
  case identifier = 2
  case chemicalElement = 3
  case forceFieldType = 4
  case position = 5
  case charge = 6
}

public enum RKTextAlignment: Int
{
  case center = 0
  case left = 1
  case right = 2
  case top = 3
  case bottom = 4
  case topLeft = 5
  case topRight = 6
  case bottomLeft = 7
  case bottomRight = 8
}
