/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 THE above copyright notice and this permission notice shall be included in all copies or substantial portions
 of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

import Foundation
import simd

public enum RibbonAODebugMode: Int32, CaseIterable
{
  case off = 0
  case atlasUV = 1
  case sampledAO = 2
  case atlasChecker = 3
  case baseColor = 4
  case uniformColors = 5
  
  public var label: String
  {
    switch self
    {
    case .off: return "off"
    case .atlasUV: return "atlas UV (red=U, green=V)"
    case .sampledAO: return "sampled AO (grayscale)"
    case .atlasChecker: return "atlas texel checker"
    case .baseColor: return "base color (SS type, no lighting)"
    case .uniformColors: return "uniform colors (swatches + RGB text)"
    }
  }
  
  public mutating func cycle()
  {
    let allCases: [RibbonAODebugMode] = RibbonAODebugMode.allCases
    let nextIndex: Int = (allCases.firstIndex(of: self)! + 1) % allCases.count
    self = allCases[nextIndex]
  }
}

struct RibbonAODebugUniforms
{
  var mode: Int32 = RibbonAODebugMode.off.rawValue
  var textureWidth: Int32 = 0
  var textureHeight: Int32 = 0
  var patchNumber: Int32 = 1
  var patchSize: Float = 16.0
  var inverseTextureSize: Float = 1.0 / 1024.0
  var viewportWidth: Int32 = 0
  var viewportHeight: Int32 = 0
}

struct RibbonAOBlurUniforms
{
  var inverseTextureSize: SIMD2<Float> = SIMD2(0.0, 0.0)
}

struct RibbonAOPatchUniforms
{
  var patchNumber: Int32 = 1
  var patchSize: Float = 16.0
  var inverseTextureSize: Float = 1.0 / 1024.0
  var pad: Int32 = 0
}

/// Shared ambient-occlusion atlas sizing for atom impostors and ribbon lightmaps.
enum RKAmbientOcclusionSizing
{
  static func maxTextureSize(numberOfAtoms: Int, maxTextureDimension: Int = 16384) -> Int
  {
    let cappedMax: Int = min(maxTextureDimension, 16384)
    switch numberOfAtoms
    {
    case 0...64: return min(256, cappedMax)
    case 65...256: return min(512, cappedMax)
    case 257...1024: return min(1024, cappedMax)
    case 1025...65536: return min(2048, cappedMax)
    case 65537...524288: return min(4096, cappedMax)
    default: return min(8192, cappedMax)
    }
  }
}

extension RKRenderObject
{
  var ribbonAmbientOcclusionCacheKey: NSString
  {
    let atomSource: RKRenderAtomSource? = self as? RKRenderAtomSource
    let includeAtomShadows: Bool = (atomSource?.atomAmbientOcclusion ?? false) && (atomSource?.drawAtoms ?? false)
    let ribbonSource: RKRenderRibbonSource? = self as? RKRenderRibbonSource
    let ribbonAOEnabled: Bool = ribbonSource?.ribbonAmbientOcclusion ?? false
    let textureWidth: Int = ribbonSource?.ribbonAmbientOcclusionTextureWidth ?? 0
    let textureHeight: Int = ribbonSource?.ribbonAmbientOcclusionTextureHeight ?? 0
    let maxSamples: Int = ribbonSource?.ribbonMaxSplineSampleCount ?? 0
    return NSString(string: "ribbon-ao-v36-seam-edge-\(textureWidth)x\(textureHeight)-rings-\(maxSamples)-ribbonAO-\(ribbonAOEnabled)-atomShadows-\(includeAtomShadows)-\(ObjectIdentifier(self).hashValue)")
  }
}

func ribbonColorUniformDebugOverlayText(renderStructures: [[RKRenderObject]]) -> String?
{
  for scene in renderStructures
  {
    for structure in scene
    {
      guard structure.isVisible,
            let ribbonSource: RKRenderRibbonSource = structure as? RKRenderRibbonSource,
            ribbonSource.drawRibbon else {continue}
      func format(_ color: SIMD3<Float>) -> String
      {
        return String(format: "(%.2f, %.2f, %.2f)", color.x, color.y, color.z)
      }
      return "Coil \(format(ribbonSource.ribbonCoilColor))   Helix \(format(ribbonSource.ribbonHelixColor))   Sheet \(format(ribbonSource.ribbonSheetColor))"
    }
  }
  return nil
}
