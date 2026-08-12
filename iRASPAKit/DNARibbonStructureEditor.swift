/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.

 PyMOL nucleic-acid cartoon settings (cartoon_nucleic_acid_mode, cCartoon_* cross-sections).
 *************************************************************************************************************/

import Foundation
import SymmetryKit

public enum NucleicAcidBackboneStyle: Int, Sendable
{
  case oval = 0
  case tube
  case dumbbell
  case rect
}

public enum NucleicAcidTraceMode: Int, Sendable
{
  case phosphateMode4 = 4
  case c3PrimeMode1 = 1
}

public enum NucleicAcidRingMode: Int, Sendable
{
  case off = 0
  case filledPlanes = 1
}

public enum NucleicAcidLadderMode: Int, Sendable
{
  case off = 0
  case rungs = 1
}

public protocol DNARibbonStructureEditor: AnyObject
{
  var drawRibbon: Bool {get set}
  var ribbonScaleFactor: Double {get set}
  var ribbonSubdivisionsPerSegment: Int {get set}
  var ribbonCrossSectionRingResolution: Int {get set}
  
  var nucleicAcidBackboneStyle: NucleicAcidBackboneStyle {get set}
  var nucleicAcidTraceMode: NucleicAcidTraceMode {get set}
  var nucleicAcidRingMode: NucleicAcidRingMode {get set}
  var nucleicAcidLadderMode: NucleicAcidLadderMode {get set}
  var nucleicAcidOvalLength: Double {get set}
  var nucleicAcidOvalWidth: Double {get set}
  var nucleicAcidRingWidth: Double {get set}
  var nucleicAcidLadderRadius: Double {get set}
  
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
  
  func applyFancyRibbonAppearance()
}

extension DNARibbonStructureEditor
{
  public var dnaRibbonMeshParameters: ProteinRibbonMeshParameters
  {
    get
    {
      return ProteinRibbonMeshParameters(splineType: .bSpline,
                                       subdivisionsPerSegment: ribbonSubdivisionsPerSegment,
                                       crossSectionRingResolution: ribbonCrossSectionRingResolution,
                                       coilRadiusScale: 0.35,
                                       ribbonWidthClamp: 0.125,
                                       sheetArrowLengthExtent: 1.5,
                                       sheetArrowWingPosition: 1.0,
                                       sheetArrowPeakWidthFactor: 2.5,
                                       normalSmoothingRadius: 4,
                                       nucleicAcidRendering: true,
                                       nucleicAcidBackboneStyle: nucleicAcidBackboneStyle,
                                       nucleicAcidTraceMode: nucleicAcidTraceMode,
                                       nucleicAcidRingMode: nucleicAcidRingMode,
                                       nucleicAcidLadderMode: nucleicAcidLadderMode,
                                       nucleicAcidOvalLength: nucleicAcidOvalLength,
                                       nucleicAcidOvalWidth: nucleicAcidOvalWidth,
                                       nucleicAcidRingWidth: nucleicAcidRingWidth,
                                       nucleicAcidLadderRadius: nucleicAcidLadderRadius)
    }
    set
    {
      ribbonSubdivisionsPerSegment = newValue.subdivisionsPerSegment
      ribbonCrossSectionRingResolution = newValue.crossSectionRingResolution
      nucleicAcidBackboneStyle = newValue.nucleicAcidBackboneStyle
      nucleicAcidTraceMode = newValue.nucleicAcidTraceMode
      nucleicAcidRingMode = newValue.nucleicAcidRingMode
      nucleicAcidLadderMode = newValue.nucleicAcidLadderMode
      nucleicAcidOvalLength = newValue.nucleicAcidOvalLength
      nucleicAcidOvalWidth = newValue.nucleicAcidOvalWidth
      nucleicAcidRingWidth = newValue.nucleicAcidRingWidth
      nucleicAcidLadderRadius = newValue.nucleicAcidLadderRadius
    }
  }
  
  public func applyDefaultDnaRibbonAppearance()
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
  }
  
  public func applyFancyDnaRibbonAppearanceDefault()
  {
    ribbonHDR = true
    ribbonHDRExposure = 2.5
    ribbonHue = 1.0
    ribbonSaturation = 0.5
    ribbonValue = 1.0
    ribbonAmbientOcclusion = true
    ribbonAmbientColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    ribbonDiffuseColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    ribbonSpecularColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    ribbonAmbientIntensity = 0.2
    ribbonDiffuseIntensity = 1.0
    ribbonSpecularIntensity = 1.0
    ribbonShininess = 4.0
  }
  
  public func applyFancyRibbonAppearance()
  {
    applyFancyDnaRibbonAppearanceDefault()
  }
}
