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
import MathKit
import SimulationKit
import SymmetryKit


public protocol RKRenderObject: AnyObject
{
  var displayName: String {get}
  var isVisible: Bool {get}
  
  var orientation: simd_quatd {get}
  var origin: SIMD3<Double> {get}
 
  var cell: SKCell {get}
  
  var periodic: Bool {get}
  func absoluteCartesianModelPosition(for position: SIMD3<Double>, replicaPosition: SIMD3<Int32>) -> SIMD3<Double>
  func absoluteCartesianScenePosition(for position: SIMD3<Double>, replicaPosition: SIMD3<Int32>) -> SIMD3<Double>
}

public protocol RKRenderLocalAxesSource
{
  var renderLocalAxis: RKLocalAxes {get}
}

public protocol RKRenderUnitCellSource: RKRenderObject
{
  var drawUnitCell: Bool {get}
  
  var unitCellScaleFactor: Double {get}
  var unitCellDiffuseColor: NSColor {get}
  var unitCellDiffuseIntensity: Double {get}
  
  var renderUnitCellSpheres: [RKInPerInstanceAttributesAtoms] {get}
  var renderUnitCellCylinders: [RKInPerInstanceAttributesBonds] {get}
}

public protocol RKRenderAtomSource: RKRenderObject
{
  var numberOfAtoms: Int {get}
  var drawAtoms: Bool {get}

  /// The cues drawn where these atoms meet something else. The bonds of the same structure follow it.
  var atomEdgeCueing: RKEdgeCueing {get}
  
  var atomAmbientColor: NSColor {get}
  var atomDiffuseColor: NSColor {get}
  var atomSpecularColor: NSColor {get}
  var atomAmbientIntensity: Double {get}
  var atomDiffuseIntensity: Double {get}
  var atomSpecularIntensity: Double {get}
  var atomShininess: Double {get}
  
  var atomHue: Double {get}
  var atomSaturation: Double {get}
  var atomValue: Double {get}
  
  var colorAtomsWithBondColor: Bool {get}
  var atomScaleFactor: Double {get}
  var atomAmbientOcclusion: Bool {get}
  var atomAmbientOcclusionPatchNumber: Int {get set}
  var atomAmbientOcclusionPatchSize: Int {get set}
  var atomAmbientOcclusionTextureSize: Int {get set}
  
  var atomHDR: Bool {get}
  var atomHDRExposure: Double {get}
  var clipAtomsAtUnitCell: Bool {get}
  var renderAtoms: [RKInPerInstanceAttributesAtoms] {get}
  
  var atomTextData: [RKInPerInstanceAttributesText] {get}
  var atomTextType: RKTextType {get}
  var atomTextFont: String {get}
  var atomTextAlignment: RKTextAlignment {get}
  var atomTextStyle: RKTextStyle {get}
  var atomTextColor: NSColor {get}
  var atomTextScaling: Double {get}
  var atomTextOffset: SIMD3<Double> {get}
  var atomTextGlowColor: NSColor {get}
  var atomTextEffect: RKTextEffect {get}
  
  var renderSelectedAtoms: [RKInPerInstanceAttributesAtoms] {get}
  var atomSelectionStyle: RKSelectionStyle {get}
  var atomSelectionStripesDensity: Double {get}
  var atomSelectionStripesFrequency: Double {get}
  var atomSelectionWorleyNoise3DFrequency: Double {get}
  var atomSelectionWorleyNoise3DJitter: Double {get}
  var atomSelectionIntensity: Double {get}
  var atomSelectionScaling: Double {get}
}

public protocol RKRenderBondSource: RKRenderObject
{
  /// Taken from the atoms, a ball-and-stick model reading badly with one of the two outlined.
  var atomEdgeCueing: RKEdgeCueing {get}

  var numberOfInternalBonds: Int {get}
  var numberOfExternalBonds: Int {get}
  var renderInternalBonds: [RKInPerInstanceAttributesBonds] {get}
  var renderSelectedInternalBonds: [RKInPerInstanceAttributesBonds] {get}
  var renderExternalBonds: [RKInPerInstanceAttributesBonds] {get}
  var renderSelectedExternalBonds: [RKInPerInstanceAttributesBonds] {get}
  var drawBonds: Bool {get}
  
  var bondAmbientColor: NSColor {get}
  var bondDiffuseColor: NSColor {get}
  var bondSpecularColor: NSColor {get}
  var bondAmbientIntensity: Double {get}
  var bondDiffuseIntensity: Double {get}
  var bondSpecularIntensity: Double {get}
  var bondShininess: Double {get}
  
  var isUnity: Bool {get}
  var hasExternalBonds: Bool {get}
  
  var bondAmbientOcclusion: Bool {get}
  var bondAmbientOcclusionPatchNumber: Int {get set}
  var bondAmbientOcclusionPatchSize: Int {get set}
  var bondAmbientOcclusionTextureSize: Int {get set}
  /// Where the external bonds' patches start in the atlas, the internal ones taking the range before it.
  var externalBondAmbientOcclusionPatchBase: Int {get set}
  
  var bondScaleFactor: Double {get}
  var bondColorMode: RKBondColorMode {get}
  
  var bondHDR: Bool {get}
  var bondHDRExposure: Double {get}
  
  var clipBondsAtUnitCell: Bool {get}
  
  var bondHue: Double {get}
  var bondSaturation: Double {get}
  var bondValue: Double {get}
  
  var bondSelectionStyle: RKSelectionStyle {get}
  var bondSelectionStripesDensity: Double {get}
  var bondSelectionStripesFrequency: Double {get}
  var bondSelectionWorleyNoise3DFrequency: Double {get}
  var bondSelectionWorleyNoise3DJitter: Double {get}
  var bondSelectionIntensity: Double {get}
  var bondSelectionScaling: Double {get}
}

public protocol RKRenderRibbonSource: RKRenderObject
{
  var drawRibbon: Bool {get}

  /// The cues drawn where these ribbons meet something else, kept apart from the atoms so that a
  /// protein can be shown with cued ribbons over plain atoms or the reverse.
  var ribbonEdgeCueing: RKEdgeCueing {get}
  var ribbonScaleFactor: Double {get}
  var renderRibbonVertices: [RKVertex] {get}
  var renderRibbonIndices: [UInt32] {get}
  var ribbonNumberOfVertices: Int {get}
  var ribbonNumberOfIndices: Int {get}
  var ribbonChainDrawRanges: [RKRibbonChainDrawRange] {get}
  var ribbonSegmentDrawRanges: [RKRibbonChainDrawRange] {get}
  var ribbonResidueDrawRanges: [RKRibbonChainDrawRange] {get}
  var ribbonUsesSegmentVisibility: Bool {get}
  var ribbonUsesResidueVisibility: Bool {get}
  func isRibbonSegmentDrawRangeVisible(at index: Int) -> Bool
  func isRibbonResidueDrawRangeVisible(at index: Int) -> Bool
  /// Visible ribbon draw ranges for encoding (merged contiguous/overlapping spans). Prefer this over per-range visibility in draw loops.
  func ribbonDrawRangesForEncoding() -> [RKRibbonChainDrawRange]
  var renderSelectedRibbonSegmentDrawRangeIndices: Set<Int> {get}
  var renderSelectedRibbonResidueDrawRangeIndices: Set<Int> {get}
  var ribbonNumberOfChains: Int {get}
  var ribbonNumberOfRings: Int {get}
  var ribbonMaxSplineSampleCount: Int {get}
  var ribbonAmbientOcclusionPatchNumber: Int {get set}
  var ribbonAmbientOcclusionPatchSize: Int {get set}
  var ribbonAmbientOcclusionTextureSize: Int {get set}
  var ribbonAmbientOcclusionTextureWidth: Int {get set}
  var ribbonAmbientOcclusionTextureHeight: Int {get set}
  var ribbonAmbientOcclusionStripHeight: Int {get set}
  var ribbonCoilColor: SIMD3<Float> {get}
  var ribbonHelixColor: SIMD3<Float> {get}
  var ribbonSheetColor: SIMD3<Float> {get}
  var ribbonHDR: Bool {get}
  var ribbonHDRExposure: Double {get}
  var ribbonHue: Double {get}
  var ribbonSaturation: Double {get}
  var ribbonValue: Double {get}
  var ribbonAmbientOcclusion: Bool {get}
  var ribbonAmbientColor: NSColor {get}
  var ribbonDiffuseColor: NSColor {get}
  var ribbonSpecularColor: NSColor {get}
  var ribbonAmbientIntensity: Double {get}
  var ribbonDiffuseIntensity: Double {get}
  var ribbonSpecularIntensity: Double {get}
  var ribbonShininess: Double {get}
  func rebuildBackbone()
  func rebuildRibbonMesh()
}

public extension RKRenderRibbonSource
{
  /// Default: resolve visibility once per encode and merge contiguous/overlapping ranges.
  /// Types with expensive per-index visibility should override with a single tree walk.
  func ribbonDrawRangesForEncoding() -> [RKRibbonChainDrawRange]
  {
    let ranges: [RKRibbonChainDrawRange]
    let isVisible: (Int) -> Bool
    if ribbonUsesResidueVisibility && !ribbonResidueDrawRanges.isEmpty
    {
      ranges = ribbonResidueDrawRanges
      isVisible = { self.isRibbonResidueDrawRangeVisible(at: $0) }
    }
    else if ribbonUsesSegmentVisibility && !ribbonSegmentDrawRanges.isEmpty
    {
      ranges = ribbonSegmentDrawRanges
      isVisible = { self.isRibbonSegmentDrawRangeVisible(at: $0) }
    }
    else
    {
      return ribbonChainDrawRanges
    }
    
    var visible: [Bool] = Array(repeating: true, count: ranges.count)
    var allVisible: Bool = true
    for index in 0..<ranges.count
    {
      let rangeVisible: Bool = isVisible(index)
      visible[index] = rangeVisible
      if !rangeVisible {allVisible = false}
    }
    if allVisible
    {
      return ribbonChainDrawRanges
    }
    return RKRibbonMesh.mergedVisibleDrawRanges(ranges, visible: visible)
  }
}

public protocol RKRenderVolumetricDataSource: RKRenderObject
{
  var drawAdsorptionSurface: Bool {get}
  
  var dimensions: SIMD3<Int32> {get}
  var gridData: [Float] {get}
  var gridValueAndGradientData: [SIMD4<Float>] {get}
  var isImmutable: Bool {get}
  
  var adsorptionSurfaceRenderingMethod: RKEnergySurfaceType {get}
  var adsorptionVolumeTransferFunction: RKPredefinedVolumeRenderingTransferFunction {get}
  var adsorptionVolumeStepLength: Double {get}
  
  var adsorptionSurfaceOpacity: Double {get}
  var adsorptionTransparencyThreshold: Double {get}
  var adsorptionSurfaceIsoValue: Double {get}
  var encompassingPowerOfTwoCubicGridSize: Int {get}
  var adsorptionSurfaceProbeParameters: SIMD2<Double> { get }
  var adsorptionSurfaceNumberOfTriangles: Int {get set}
  
  var adsorptionSurfaceHue: Double {get}
  var adsorptionSurfaceSaturation: Double {get}
  var adsorptionSurfaceValue: Double {get}
  
  var adsorptionSurfaceFrontSideHDR: Bool {get}
  var adsorptionSurfaceFrontSideHDRExposure: Double {get}
  var adsorptionSurfaceFrontSideAmbientColor: NSColor {get}
  var adsorptionSurfaceFrontSideDiffuseColor: NSColor {get}
  var adsorptionSurfaceFrontSideSpecularColor: NSColor {get}
  var adsorptionSurfaceFrontSideDiffuseIntensity: Double {get}
  var adsorptionSurfaceFrontSideAmbientIntensity: Double {get}
  var adsorptionSurfaceFrontSideSpecularIntensity: Double {get}
  var adsorptionSurfaceFrontSideShininess: Double {get}
  
  var adsorptionSurfaceBackSideHDR: Bool {get}
  var adsorptionSurfaceBackSideHDRExposure: Double {get}
  var adsorptionSurfaceBackSideAmbientColor: NSColor {get}
  var adsorptionSurfaceBackSideDiffuseColor: NSColor {get}
  var adsorptionSurfaceBackSideSpecularColor: NSColor {get}
  var adsorptionSurfaceBackSideDiffuseIntensity: Double {get}
  var adsorptionSurfaceBackSideAmbientIntensity: Double {get}
  var adsorptionSurfaceBackSideSpecularIntensity: Double {get}
  var adsorptionSurfaceBackSideShininess: Double {get}
}

public protocol RKRenderPrimitiveSource
{
  //var numberOfAtoms: Int {get}
  var drawAtoms: Bool {get}
  var isVisible: Bool {get}
  
  var atomSelectionStyle: RKSelectionStyle {get}
  var atomSelectionStripesDensity: Double {get}
  var atomSelectionStripesFrequency: Double {get}
  var atomSelectionWorleyNoise3DFrequency: Double {get}
  var atomSelectionWorleyNoise3DJitter: Double {get}
  var atomSelectionIntensity: Double {get}
  var atomSelectionScaling: Double {get}
  
  var primitiveTransformationMatrix: double3x3 {get}
  var primitiveOrientation: simd_quatd {get}
  
  var primitiveOpacity: Double {get}
  var primitiveIsCapped: Bool {get}
  var primitiveIsFractional: Bool {get}
  var primitiveNumberOfSides: Int {get}
  var primitiveThickness: Double {get}
  
  var primitiveHue: Double {get}
  var primitiveSaturation: Double {get}
  var primitiveValue: Double {get}
  
  var primitiveSelectionStyle: RKSelectionStyle {get}
  var primitiveSelectionScaling: Double {get}
  var primitiveSelectionStripesDensity: Double {get}
  var primitiveSelectionStripesFrequency: Double {get}
  var primitiveSelectionWorleyNoise3DFrequency: Double {get}
  var primitiveSelectionWorleyNoise3DJitter: Double {get}
  var primitiveSelectionIntensity: Double {get}
  
  var primitiveFrontSideHDR: Bool {get}
  var primitiveFrontSideHDRExposure: Double {get}
  var primitiveFrontSideAmbientColor: NSColor {get}
  var primitiveFrontSideDiffuseColor: NSColor {get}
  var primitiveFrontSideSpecularColor: NSColor {get}
  var primitiveFrontSideDiffuseIntensity: Double {get}
  var primitiveFrontSideAmbientIntensity: Double {get}
  var primitiveFrontSideSpecularIntensity: Double {get}
  var primitiveFrontSideShininess: Double {get}
  
  var primitiveBackSideHDR: Bool {get}
  var primitiveBackSideHDRExposure: Double {get}
  var primitiveBackSideAmbientColor: NSColor {get}
  var primitiveBackSideDiffuseColor: NSColor {get}
  var primitiveBackSideSpecularColor: NSColor {get}
  var primitiveBackSideDiffuseIntensity: Double {get}
  var primitiveBackSideAmbientIntensity: Double {get}
  var primitiveBackSideSpecularIntensity: Double {get}
  var primitiveBackSideShininess: Double {get}
}

public protocol RKRenderCrystalEllipsoidObjectsSource: RKRenderPrimitiveSource
{
  var renderCrystalEllipsoidObjects: [RKInPerInstanceAttributesAtoms] {get}
  var renderSelectedCrystalEllipsoidObjects: [RKInPerInstanceAttributesAtoms] {get}
}

public protocol RKRenderEllipsoidObjectsSource: RKRenderPrimitiveSource
{
  var renderEllipsoidObjects: [RKInPerInstanceAttributesAtoms] {get}
  var renderSelectedEllipsoidObjects: [RKInPerInstanceAttributesAtoms] {get}
}



public protocol RKRenderCrystalCylinderObjectsSource: RKRenderPrimitiveSource
{
  var renderCrystalCylinderObjects: [RKInPerInstanceAttributesAtoms] {get}
  var renderSelectedCrystalCylinderObjects: [RKInPerInstanceAttributesAtoms] {get}
}

public protocol RKRenderCylinderObjectsSource: RKRenderPrimitiveSource
{
  var renderCylinderObjects: [RKInPerInstanceAttributesAtoms] {get}
  var renderSelectedCylinderObjects: [RKInPerInstanceAttributesAtoms] {get}
}

public protocol RKRenderCrystalPolygonalPrismObjectsSource: RKRenderPrimitiveSource
{
  var renderCrystalPolygonalPrismObjects: [RKInPerInstanceAttributesAtoms] {get}
  var renderSelectedCrystalPolygonalPrismObjects: [RKInPerInstanceAttributesAtoms] {get}
}

public protocol RKRenderPolygonalPrismObjectsSource: RKRenderPrimitiveSource
{
  var renderPolygonalPrismObjects: [RKInPerInstanceAttributesAtoms] {get}
  var renderSelectedPolygonalPrismObjects: [RKInPerInstanceAttributesAtoms] {get}
}

public protocol RKRenderCameraSource: AnyObject
{
  var renderCamera: RKCamera? {get}
}

public protocol RKRenderDataSource: AnyObject
{
  var numberOfScenes: Int {get}
  func numberOfMovies(sceneIndex: Int) -> Int
  func renderStructuresForScene(_ i: Int) -> [RKRenderObject]
  var renderStructures: [RKRenderObject] {get}
  var renderLights: [RKRenderLight] {get}
  
  var renderMeasurementPoints: [RKInPerInstanceAttributesAtoms] {get}
  var renderMeasurementStructure: [RKRenderObject] {get}
  
  var renderBoundingBox: SKBoundingBox {get}
  
  var hasSelectedObjects: Bool {get}
  
  var renderBackgroundType: RKBackgroundType {get}
  var renderBackgroundColor: NSColor {get}
  var renderBackgroundCachedImage: CGImage? {get}
  
  var renderImageNumberOfPixels: Int {get}
  var renderImagePhysicalSizeInInches: Double {get}

  /// How exported pictures and movies are rendered. Unlike the interactive settings, which describe
  /// what the current machine can keep up with, these are choices about the output and so travel
  /// with the document.
  var renderPictureRayTracing: Bool {get}
  var renderPictureSampleCount: Int {get}
  var renderPictureMaximumBounces: Int {get}

  /// Applies to every combination of renderer and destination, not just exports. See
  /// `ambientOcclusionStrength` in Common.h.
  var renderAmbientOcclusionStrength: Double {get}

  /// Whether the rasterizer should darken the surfaces that a light cannot reach, which it works out
  /// by tracing the scene the path tracer has already built. Only meaningful for a rig whose lights sit
  /// off the camera axis: a light at the eye can never be blocked from anything the eye can see.
  ///
  /// The path tracer casts its own shadow rays and ignores this.
  var renderShadows: Bool {get}

  /// Light reaching the scene from the environment as a whole, kept apart from the individual lights so
  /// that switching one off cannot darken the ambient floor. See `sceneAmbient` in Common.h.
  var renderSceneAmbientIntensity: Double {get}
  var renderSceneAmbientColor: NSColor {get}
  
  var showBoundingBox: Bool {get set}
  var renderBoundingBoxSpheres: [RKInPerInstanceAttributesAtoms] {get}
  var renderBoundingBoxCylinders: [RKInPerInstanceAttributesBonds] {get}
  
  var renderAxes: RKGlobalAxes {get}
}

extension RKRenderDataSource
{
  /// The mode an export renders in. Falls back to rasterization on hardware without ray tracing, so
  /// that a document authored on a capable machine still produces an image elsewhere.
  public var pictureRenderMode: RKRenderMode
  {
    guard renderPictureRayTracing, RKRenderSettings.isRayTracingSupported else {return RKRenderMode.rasterization}
    return RKRenderMode.rayTracing
  }

  /// The stored export settings, clamped to what the tracer can be asked for. The stored values come
  /// from editable fields and from documents written by other versions, so neither is trusted here.
  public var picturePathTracerSettings: RKPathTracerSettings
  {
    var settings: RKPathTracerSettings = RKPathTracerSettings.standard
    settings.sampleCount = min(max(renderPictureSampleCount, 1), RKRenderSettings.maximumSupportedPictureSamples)
    settings.maximumBounces = min(max(renderPictureMaximumBounces, 0), RKRenderSettings.maximumSupportedPictureBounces)
    settings.ambientOcclusionStrength = Float(min(max(renderAmbientOcclusionStrength, 0.0), 1.0))
    return settings
  }
}
