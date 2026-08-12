/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
 to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions
 of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

import Foundation

public struct ProteinRibbonMeshParameters: Equatable, Sendable
{
  public var splineType: ProteinRibbonSplineType = .bSpline
  public var subdivisionsPerSegment: Int = 24
  public var crossSectionRingResolution: Int = 32
  public var coilRadiusScale: Double = 0.35
  public var ribbonWidthClamp: Double = 0.125
  public var nucleicAcidRendering: Bool = false
  public var nucleicAcidBackboneStyle: NucleicAcidBackboneStyle = .oval
  public var nucleicAcidTraceMode: NucleicAcidTraceMode = .phosphateMode4
  public var nucleicAcidRingMode: NucleicAcidRingMode = .off
  public var nucleicAcidLadderMode: NucleicAcidLadderMode = .off
  /// PyMOL cartoon_oval_length (long axis, widthDirection).
  public var nucleicAcidOvalLength: Double = 1.35
  /// PyMOL cartoon_oval_width (short axis, faceNormal / orientation).
  public var nucleicAcidOvalWidth: Double = 0.25
  /// PyMOL cartoon_ring_width.
  public var nucleicAcidRingWidth: Double = 0.1
  /// PyMOL cartoon_ladder_radius.
  public var nucleicAcidLadderRadius: Double = 0.15
  public var nucleicAcidLadderSegments: Int = 8
  /// PyMOL cartoon_dumbbell_length / width / radius.
  public var nucleicAcidDumbbellLength: Double = 1.0
  public var nucleicAcidDumbbellWidth: Double = 0.15
  public var nucleicAcidDumbbellRadius: Double = 0.3
  public var sheetArrowLengthExtent: Double = 1.5
  public var sheetArrowWingPosition: Double = 1.0
  public var sheetArrowPeakWidthFactor: Double = 2.5
  public var normalSmoothingRadius: Int = 4
  
  public init()
  {
  }
  
  public init(splineType: ProteinRibbonSplineType,
              subdivisionsPerSegment: Int,
              crossSectionRingResolution: Int,
              coilRadiusScale: Double,
              ribbonWidthClamp: Double,
              sheetArrowLengthExtent: Double,
              sheetArrowWingPosition: Double,
              sheetArrowPeakWidthFactor: Double,
              normalSmoothingRadius: Int,
              nucleicAcidRendering: Bool = false,
              nucleicAcidBackboneStyle: NucleicAcidBackboneStyle = .oval,
              nucleicAcidTraceMode: NucleicAcidTraceMode = .phosphateMode4,
              nucleicAcidRingMode: NucleicAcidRingMode = .off,
              nucleicAcidLadderMode: NucleicAcidLadderMode = .off,
              nucleicAcidOvalLength: Double = 1.35,
              nucleicAcidOvalWidth: Double = 0.25,
              nucleicAcidRingWidth: Double = 0.1,
              nucleicAcidLadderRadius: Double = 0.15,
              nucleicAcidLadderSegments: Int = 8,
              nucleicAcidDumbbellLength: Double = 1.0,
              nucleicAcidDumbbellWidth: Double = 0.15,
              nucleicAcidDumbbellRadius: Double = 0.3)
  {
    self.splineType = splineType
    self.subdivisionsPerSegment = subdivisionsPerSegment
    self.crossSectionRingResolution = crossSectionRingResolution
    self.coilRadiusScale = coilRadiusScale
    self.ribbonWidthClamp = ribbonWidthClamp
    self.sheetArrowLengthExtent = sheetArrowLengthExtent
    self.sheetArrowWingPosition = sheetArrowWingPosition
    self.sheetArrowPeakWidthFactor = sheetArrowPeakWidthFactor
    self.normalSmoothingRadius = normalSmoothingRadius
    self.nucleicAcidRendering = nucleicAcidRendering
    self.nucleicAcidBackboneStyle = nucleicAcidBackboneStyle
    self.nucleicAcidTraceMode = nucleicAcidTraceMode
    self.nucleicAcidRingMode = nucleicAcidRingMode
    self.nucleicAcidLadderMode = nucleicAcidLadderMode
    self.nucleicAcidOvalLength = nucleicAcidOvalLength
    self.nucleicAcidOvalWidth = nucleicAcidOvalWidth
    self.nucleicAcidRingWidth = nucleicAcidRingWidth
    self.nucleicAcidLadderRadius = nucleicAcidLadderRadius
    self.nucleicAcidLadderSegments = nucleicAcidLadderSegments
    self.nucleicAcidDumbbellLength = nucleicAcidDumbbellLength
    self.nucleicAcidDumbbellWidth = nucleicAcidDumbbellWidth
    self.nucleicAcidDumbbellRadius = nucleicAcidDumbbellRadius
  }
  
  public static let `default`: ProteinRibbonMeshParameters = ProteinRibbonMeshParameters()
  
  /// Runtime mesh settings: user/import values with hard clamps only (no structure-size caps).
  public func effectiveForStructure(atomCount: Int, residueCount: Int) -> ProteinRibbonMeshParameters
  {
    _ = atomCount
    _ = residueCount
    return clamped
  }
  
  /// Initial ribbon mesh settings for newly imported structures.
  public static func forImportedStructure(atomCount: Int, residueCount: Int) -> ProteinRibbonMeshParameters
  {
    _ = atomCount
    _ = residueCount
    return ProteinRibbonMeshParameters.default.clamped
  }
  
  @available(*, deprecated, message: "Use forImportedStructure(atomCount:residueCount:)")
  public static func subdivisionsPerSegmentForImport(residueCount: Int) -> Int
  {
    return forImportedStructure(atomCount: residueCount, residueCount: residueCount).subdivisionsPerSegment
  }
  
  public var clamped: ProteinRibbonMeshParameters
  {
    var copy: ProteinRibbonMeshParameters = self
    copy.subdivisionsPerSegment = min(max(copy.subdivisionsPerSegment, 1), 128)
    copy.crossSectionRingResolution = min(max(copy.crossSectionRingResolution, 2), 128)
    copy.coilRadiusScale = min(max(copy.coilRadiusScale, 0.05), 2.0)
    copy.ribbonWidthClamp = min(max(copy.ribbonWidthClamp, 0.01), 1.0)
    copy.sheetArrowLengthExtent = min(max(copy.sheetArrowLengthExtent, 0.5), 10.0)
    copy.sheetArrowWingPosition = min(max(copy.sheetArrowWingPosition, 0.1), 5.0)
    copy.sheetArrowPeakWidthFactor = min(max(copy.sheetArrowPeakWidthFactor, 1.0), 10.0)
    copy.normalSmoothingRadius = min(max(copy.normalSmoothingRadius, 0), 16)
    copy.nucleicAcidOvalLength = min(max(copy.nucleicAcidOvalLength, 0.2), 3.0)
    copy.nucleicAcidOvalWidth = min(max(copy.nucleicAcidOvalWidth, 0.05), 1.0)
    copy.nucleicAcidDumbbellLength = min(max(copy.nucleicAcidDumbbellLength, 0.2), 3.0)
    copy.nucleicAcidDumbbellWidth = min(max(copy.nucleicAcidDumbbellWidth, 0.02), 1.0)
    copy.nucleicAcidDumbbellRadius = min(max(copy.nucleicAcidDumbbellRadius, 0.05), 1.5)
    copy.nucleicAcidRingWidth = min(max(copy.nucleicAcidRingWidth, 0.02), 1.0)
    copy.nucleicAcidLadderRadius = min(max(copy.nucleicAcidLadderRadius, 0.02), 1.0)
    copy.nucleicAcidLadderSegments = min(max(copy.nucleicAcidLadderSegments, 4), 32)
    return copy
  }
}
