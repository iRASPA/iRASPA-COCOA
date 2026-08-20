/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 *************************************************************************************************************/

import Foundation
import SymmetryKit
import MathKit
import RenderKit

public protocol ProteinRibbonStructureEditor: AnyObject
{
  var drawRibbon: Bool {get set}
  var ribbonScaleFactor: Double {get set}
  var ribbonColorSet: ProteinRibbonColorSet {get set}
  var ribbonRepresentationStyle: ProteinRibbonRepresentationStyle {get set}
  var ribbonSecondaryStructureMethod: ProteinRibbonSecondaryStructureMethod {get set}
  var ribbonSplineType: ProteinRibbonSplineType {get set}
  var ribbonSubdivisionsPerSegment: Int {get set}
  var ribbonCrossSectionRingResolution: Int {get set}
  var ribbonCoilRadiusScale: Double {get set}
  var ribbonWidthClamp: Double {get set}
  var ribbonSheetArrowLengthExtent: Double {get set}
  var ribbonSheetArrowWingPosition: Double {get set}
  var ribbonSheetArrowPeakWidthFactor: Double {get set}
  var ribbonNormalSmoothingRadius: Int {get set}
  
  func rebuildRibbonMesh()
  func rebuildBackbone()
  func rebuildBackboneStructure()
  
  var ribbonHDR: Bool {get set}
  var ribbonHDRExposure: Double {get set}
  var ribbonHue: Double {get set}
  var ribbonSaturation: Double {get set}
  var ribbonValue: Double {get set}
  
  var ribbonAmbientOcclusion: Bool {get set}
  var ribbonAmbientColor: NSColor {get set}
  var ribbonDiffuseColor: NSColor {get set}
  var ribbonSpecularColor: NSColor {get set}
  var ribbonAmbientIntensity: Double {get set}
  var ribbonDiffuseIntensity: Double {get set}
  var ribbonSpecularIntensity: Double {get set}
  var ribbonShininess: Double {get set}
  var ribbonEdgeCueing: RKEdgeCueing {get set}
  
  func applyFancyRibbonAppearance()
  func applyIllustrativeRibbonAppearance()
  func recheckRibbonRepresentationStyle()
}

fileprivate func ribbonFloatEqual(_ left: Double, _ right: Double) -> Bool
{
  return (left - right).magnitude < 1e-3
}

fileprivate func ribbonColorIsWhite(_ color: NSColor) -> Bool
{
  guard let rgb: NSColor = color.usingColorSpace(.deviceRGB) else {return false}
  return ((rgb.redComponent - 1.0).magnitude < 1e-3) &&
         ((rgb.greenComponent - 1.0).magnitude < 1e-3) &&
         ((rgb.blueComponent - 1.0).magnitude < 1e-3) &&
         ((rgb.alphaComponent - 1.0).magnitude < 1e-3)
}

extension ProteinRibbonStructureEditor
{
  /// Replace early development arrow proportions with literature/PyMOL-like tip geometry.
  public func migrateLegacySheetArrowDefaultsIfNeeded()
  {
    let length: Double = ribbonSheetArrowLengthExtent
    let wing: Double = ribbonSheetArrowWingPosition
    let peak: Double = ribbonSheetArrowPeakWidthFactor
    // Prior development defaults that produced paddles, invisible tips, or diamond/kite heads.
    let legacyPaddle: Bool = abs(length - 2.5) < 1.0e-9 && abs(wing - 1.0) < 1.0e-9 && abs(peak - 4.0) < 1.0e-9
    let tooSubtle: Bool = abs(length - 1.5) < 1.0e-9 && abs(wing - 0.5) < 1.0e-9 && abs(peak - 1.5) < 1.0e-9
    let longDiamond: Bool = abs(length - 2.0) < 1.0e-9 && abs(wing - 1.0) < 1.0e-9 && abs(peak - 2.5) < 1.0e-9
    guard legacyPaddle || tooSubtle || longDiamond else {return}
    ribbonSheetArrowLengthExtent = 1.5
    ribbonSheetArrowWingPosition = 1.0
    ribbonSheetArrowPeakWidthFactor = 2.5
  }
  
  public var ribbonMeshParameters: ProteinRibbonMeshParameters
  {
    get
    {
      return ProteinRibbonMeshParameters(splineType: ribbonSplineType,
                                       subdivisionsPerSegment: ribbonSubdivisionsPerSegment,
                                       crossSectionRingResolution: ribbonCrossSectionRingResolution,
                                       coilRadiusScale: ribbonCoilRadiusScale,
                                       ribbonWidthClamp: ribbonWidthClamp,
                                       sheetArrowLengthExtent: ribbonSheetArrowLengthExtent,
                                       sheetArrowWingPosition: ribbonSheetArrowWingPosition,
                                       sheetArrowPeakWidthFactor: ribbonSheetArrowPeakWidthFactor,
                                       normalSmoothingRadius: ribbonNormalSmoothingRadius)
    }
    set
    {
      ribbonSplineType = newValue.splineType
      ribbonSubdivisionsPerSegment = newValue.subdivisionsPerSegment
      ribbonCrossSectionRingResolution = newValue.crossSectionRingResolution
      ribbonCoilRadiusScale = newValue.coilRadiusScale
      ribbonWidthClamp = newValue.ribbonWidthClamp
      ribbonSheetArrowLengthExtent = newValue.sheetArrowLengthExtent
      ribbonSheetArrowWingPosition = newValue.sheetArrowWingPosition
      ribbonSheetArrowPeakWidthFactor = newValue.sheetArrowPeakWidthFactor
      ribbonNormalSmoothingRadius = newValue.normalSmoothingRadius
    }
  }
  
  public func applyDefaultRibbonAppearance()
  {
    ribbonHDR = true
    ribbonHDRExposure = 1.5
    ribbonHue = 1.0
    ribbonSaturation = 1.0
    ribbonValue = 1.0
    ribbonAmbientOcclusion = false
    ribbonAmbientColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    ribbonDiffuseColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    ribbonSpecularColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    ribbonAmbientIntensity = 0.2
    ribbonDiffuseIntensity = 1.0
    ribbonSpecularIntensity = 1.0
    ribbonShininess = 6.0
    ribbonEdgeCueing = .off
    ribbonRepresentationStyle = .default
  }
  
  /// The occluded material that Tarini, Cignoni and Montani describe in "Ambient Occlusion and Edge
  /// Cueing to Enhance Real Time Molecular Visualization", without the edge cues the Illustrative style
  /// draws on top of it. It stops short of their ambient-only shading, which suits the space-filling
  /// spheres of the paper but not a ribbon: a sphere declares its orientation through its own
  /// silhouette, while a twisting sheet has nothing but shading to say which way it faces, and drops
  /// flat without a directional term.
  public func applyFancyRibbonAppearance()
  {
    applyOccludedRibbonMaterial(edgeCueing: .off)
    ribbonRepresentationStyle = .fancy
  }
  
  /// Fancy with both of the paper's cues, which is the pairing their viewer rests on: the diffuse term
  /// gives the shape of a ribbon and the contours give the depth ordering, where either alone gives
  /// only one of them.
  ///
  /// The cues count towards the style as much as the material does, so switching them off leaves a
  /// ribbon on Fancy rather than Illustrative, in the way that changing its shininess makes it Custom.
  public func applyIllustrativeRibbonAppearance()
  {
    applyOccludedRibbonMaterial(edgeCueing: .contoursAndHalos)
    ribbonRepresentationStyle = .illustrative
  }
  
  private func applyOccludedRibbonMaterial(edgeCueing: RKEdgeCueing)
  {
    ribbonHDR = true
    ribbonHDRExposure = 2.5
    ribbonHue = 1.0
    ribbonSaturation = 1.0
    ribbonValue = 1.0
    ribbonAmbientOcclusion = true
    ribbonAmbientColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    ribbonDiffuseColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    ribbonSpecularColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    ribbonAmbientIntensity = 0.2
    ribbonDiffuseIntensity = 1.0
    ribbonSpecularIntensity = 1.0
    ribbonShininess = 4.0
    ribbonEdgeCueing = edgeCueing
  }
  
  public func applyRibbonRepresentationStyle(_ style: ProteinRibbonRepresentationStyle)
  {
    ribbonRepresentationStyle = style
    switch style
    {
    case .default:
      applyDefaultRibbonAppearance()
    case .fancy:
      applyFancyRibbonAppearance()
    case .illustrative:
      applyIllustrativeRibbonAppearance()
    case .custom:
      break
    }
  }
  
  public func matchesDefaultRibbonAppearance() -> Bool
  {
    return ribbonHDR == true &&
           ribbonFloatEqual(ribbonHDRExposure, 1.5) &&
           ribbonFloatEqual(ribbonHue, 1.0) &&
           ribbonFloatEqual(ribbonSaturation, 1.0) &&
           ribbonFloatEqual(ribbonValue, 1.0) &&
           ribbonAmbientOcclusion == false &&
           ribbonColorIsWhite(ribbonAmbientColor) &&
           ribbonColorIsWhite(ribbonDiffuseColor) &&
           ribbonColorIsWhite(ribbonSpecularColor) &&
           ribbonFloatEqual(ribbonAmbientIntensity, 0.2) &&
           ribbonFloatEqual(ribbonDiffuseIntensity, 1.0) &&
           ribbonFloatEqual(ribbonSpecularIntensity, 1.0) &&
           ribbonFloatEqual(ribbonShininess, 6.0) &&
           ribbonEdgeCueing == .off
  }
  
  public func matchesFancyRibbonAppearance() -> Bool
  {
    return matchesOccludedRibbonMaterial() && ribbonEdgeCueing == .off
  }
  
  public func matchesIllustrativeRibbonAppearance() -> Bool
  {
    return matchesOccludedRibbonMaterial() && ribbonEdgeCueing == .contoursAndHalos
  }
  
  private func matchesOccludedRibbonMaterial() -> Bool
  {
    return ribbonHDR == true &&
           ribbonFloatEqual(ribbonHDRExposure, 2.5) &&
           ribbonFloatEqual(ribbonHue, 1.0) &&
           ribbonFloatEqual(ribbonSaturation, 1.0) &&
           ribbonFloatEqual(ribbonValue, 1.0) &&
           ribbonAmbientOcclusion == true &&
           ribbonColorIsWhite(ribbonAmbientColor) &&
           ribbonColorIsWhite(ribbonDiffuseColor) &&
           ribbonColorIsWhite(ribbonSpecularColor) &&
           ribbonFloatEqual(ribbonAmbientIntensity, 0.2) &&
           ribbonFloatEqual(ribbonDiffuseIntensity, 1.0) &&
           ribbonFloatEqual(ribbonSpecularIntensity, 1.0) &&
           ribbonFloatEqual(ribbonShininess, 4.0)
  }
  
  public func recheckRibbonRepresentationStyle()
  {
    if matchesDefaultRibbonAppearance()
    {
      ribbonRepresentationStyle = .default
    }
    else if matchesFancyRibbonAppearance()
    {
      ribbonRepresentationStyle = .fancy
    }
    else if matchesIllustrativeRibbonAppearance()
    {
      ribbonRepresentationStyle = .illustrative
    }
    else
    {
      ribbonRepresentationStyle = .custom
    }
  }
}

extension Protein: ProteinRibbonStructureEditor {}
extension ProteinCrystal: ProteinRibbonStructureEditor {}

extension ProteinRibbonStructureEditor where Self: AtomViewer
{
  public func rebuildRibbonSecondaryStructureHierarchy()
  {
    let atoms: [SKAsymmetricAtom] = atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    atomTreeController.rootNodes = ProteinAtomTreeBuilder.build(from: atoms,
                                                                  secondaryStructureMethod: ribbonSecondaryStructureMethod)
    atomTreeController.tag()
    rebuildBackbone()
  }
}
