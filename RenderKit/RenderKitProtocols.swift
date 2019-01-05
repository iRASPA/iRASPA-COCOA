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

import Foundation
import simd
import MathKit
import SimulationKit
import SymmetryKit


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

public enum RKSelectionStyle: Int
{
  case WorleyNoise3D = 0
  case striped = 1
  case glow = 2
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

public protocol RKRenderViewSelectionDelegate: class
{
  func selectInRectangle(_ rect: NSRect, inViewPort bounds: NSRect, byExtendingSelection extending: Bool)
  func addAtomToSelection(_ pick: [Int32])
  func toggleAtomSelection(_ pick: [Int32])
  func clearSelection()
  func cameraDidChange()
  
  func shiftSelection(to: double3, origin: double3, depth: Double)
  func finalizeShiftSelection(to: double3, origin: double3, depth: Double)
  func rotateSelection(by: double3)
  
  func clearMeasurement()
  func addAtomToMeasurement(_ pick: [Int32])
}



/// Inserts the node into another (parent) node at a specified index
///
/// - parameter inParent: The parent where the node will be inserted into.
/// - parameter atIndex: The index of insertion
public protocol RKRenderStructure: class
{
  var displayName: String {get}
  var isVisible: Bool {get}
  
  var atomPositions: [double3] {get}
  var bondPositions: [double3] {get}
  
  var potentialParameters: [double2] {get}
  
  var renderAtoms: [RKInPerInstanceAttributesAtoms] {get}
  
  var renderTextData: [RKInPerInstanceAttributesText] {get}
  var renderTextType: RKTextType {get}
  var renderTextFont: String {get}
  var renderTextAlignment: RKTextAlignment {get}
  var renderTextStyle: RKTextStyle {get}
  var renderTextColor: NSColor {get}
  var renderTextScaling: Double {get}
  var renderTextOffset: double3 {get}

  var renderSelectedAtoms: [RKInPerInstanceAttributesAtoms] {get}
  var renderSelectionStyle: RKSelectionStyle {get}
  var renderSelectionScaling: Double {get}
  var renderSelectionStripesDensity: Double {get}
  var renderSelectionStripesFrequency: Double {get}
  var renderSelectionWorleyNoise3DFrequency: Double {get}
  var renderSelectionWorleyNoise3DJitter: Double {get}
  
  func CartesianPosition(for position: double3, replicaPosition: int3) -> double3
  
  var renderInternalBonds: [RKInPerInstanceAttributesBonds] {get}
  var renderExternalBonds: [RKInPerInstanceAttributesBonds] {get}
  var renderSelectedBonds: [RKInPerInstanceAttributesBonds] {get}
  
  var renderUnitCellSpheres: [RKInPerInstanceAttributesAtoms] {get}
  var renderUnitCellCylinders: [RKInPerInstanceAttributesBonds] {get}
  
  var numberOfAtoms: Int {get}
  var numberOfInternalBonds: Int {get}
  var numberOfExternalBonds: Int {get}
  
  var drawUnitCell: Bool {get}
  var drawAtoms: Bool {get}
  var drawBonds: Bool {get}
  
  var orientation: simd_quatd {get}
  var origin: double3 {get}
  
  // material properties
  var atomAmbientColor: NSColor {get set}
  var atomDiffuseColor: NSColor {get set}
  var atomSpecularColor: NSColor {get set}
  var atomAmbientIntensity: Double {get set}
  var atomDiffuseIntensity: Double {get set}
  var atomSpecularIntensity: Double {get set}
  var atomShininess: Double {get set}

  
  
  var cell: SKCell {get set}
    
  var atomCacheAmbientOcclusionTexture: [CUnsignedChar] {get set}
  
  var hasExternalBonds: Bool {get}
  
  var atomHue: Double {get}
  var atomSaturation: Double {get}
  var atomValue: Double {get}
  
  var atomScaleFactor: Double {get}
  var atomAmbientOcclusion: Bool {get}
  var atomAmbientOcclusionPatchNumber: Int {get set}
  var atomAmbientOcclusionPatchSize: Int {get set}
  var atomAmbientOcclusionTextureSize: Int {get set}
  
  var atomHDR: Bool {get}
  var atomHDRExposure: Double {get}
  var atomHDRBloomLevel: Double {get}
  var clipAtomsAtUnitCell: Bool {get}

  var bondAmbientColor: NSColor {get set}
  var bondDiffuseColor: NSColor {get set}
  var bondSpecularColor: NSColor {get set}
  var bondAmbientIntensity: Double {get set}
  var bondDiffuseIntensity: Double {get set}
  var bondSpecularIntensity: Double {get set}
  var bondShininess: Double {get set}
  
  var bondScaleFactor: Double {get}
  var bondColorMode: RKBondColorMode {get}
  
  var bondHDR: Bool {get}
  var bondHDRExposure: Double {get}
  var bondHDRBloomLevel: Double {get}
  var clipBondsAtUnitCell: Bool {get}
  
  var bondHue: Double {get}
  var bondSaturation: Double {get}
  var bondValue: Double {get}

  // unit cell
  var unitCellScaleFactor: Double {get}
  var unitCellDiffuseColor: NSColor {get}
  var unitCellDiffuseIntensity: Double {get}
  
  // adsorption surface
  var drawAdsorptionSurface: Bool {get set}
  var adsorptionSurfaceOpacity: Double {get set}
  var adsorptionSurfaceIsoValue: Double {get set}
  var adsorptionSurfaceSize: Int {get set}
  var adsorptionSurfaceProbeParameters: double2 { get }
  var adsorptionSurfaceNumberOfTriangles: Int {get set}
  
  var adsorptionSurfaceFrontSideHDR: Bool {get set}
  var adsorptionSurfaceFrontSideHDRExposure: Double {get set}
  var adsorptionSurfaceFrontSideAmbientColor: NSColor {get set}
  var adsorptionSurfaceFrontSideDiffuseColor: NSColor {get set}
  var adsorptionSurfaceFrontSideSpecularColor: NSColor {get set}
  var adsorptionSurfaceFrontSideDiffuseIntensity: Double {get set}
  var adsorptionSurfaceFrontSideAmbientIntensity: Double {get set}
  var adsorptionSurfaceFrontSideSpecularIntensity: Double {get set}
  var adsorptionSurfaceFrontSideShininess: Double {get set}
  
  var adsorptionSurfaceBackSideHDR: Bool {get set}
  var adsorptionSurfaceBackSideHDRExposure: Double {get set}
  var adsorptionSurfaceBackSideAmbientColor: NSColor {get set}
  var adsorptionSurfaceBackSideDiffuseColor: NSColor {get set}
  var adsorptionSurfaceBackSideSpecularColor: NSColor {get set}
  var adsorptionSurfaceBackSideDiffuseIntensity: Double {get set}
  var adsorptionSurfaceBackSideAmbientIntensity: Double {get set}
  var adsorptionSurfaceBackSideSpecularIntensity: Double {get set}
  var adsorptionSurfaceBackSideShininess: Double {get set}

}

public protocol RKRenderAdsorptionSurfaceStructure: RKRenderStructure
{
  var atomUnitCellPositions: [double3] {get}
  var minimumGridEnergyValue: Float? {get set}
  var structureHeliumVoidFraction: Double {get set}
  var structureNitrogenSurfaceArea: Double {get set}
}

public protocol RKRenderCameraSource: class
{
  var renderCamera: RKCamera? {get set}
}

public protocol RKRenderDataSource: class
{
  var numberOfScenes: Int {get}
  func numberOfMovies(sceneIndex: Int) -> Int
  func renderStructuresForScene(_ i: Int) -> [RKRenderStructure]
  var renderStructures: [RKRenderStructure] {get}
  var renderLights: [RKRenderLight] {get}
  
  var renderMeasurementPoints: [RKInPerInstanceAttributesAtoms] {get}
  var renderMeasurementStructure: [RKRenderStructure] {get}
  //var measurementTreeNodes: [double4] {get}
  
  var renderBoundingBox: SKBoundingBox {get}
  
  var hasSelectedObjects: Bool {get}
  
  var renderBackgroundType: RKBackgroundType {get}
  var renderBackgroundColor: NSColor {get}
  var renderBackgroundCachedImage: CGImage? {get}
  
  var renderImageNumberOfPixels: Int {get}
  var renderImagePhysicalSizeInInches: Double {get}
  
  var showBoundingBox: Bool {get set}
  var renderBoundingBoxSpheres: [RKInPerInstanceAttributesAtoms] {get}
  var renderBoundingBoxCylinders: [RKInPerInstanceAttributesBonds] {get}
}

public protocol RenderViewController: class
{
  var renderCameraSource: RKRenderCameraSource? {get set}
  var renderDataSource: RKRenderDataSource? {get set}
  var view: NSView {get}
  var viewBounds: CGSize {get}
  
  var renderQuality: RKRenderQuality {get set}
  
  func reloadData()
  func reloadData(ambientOcclusionQuality: RKRenderQuality)
  func reloadRenderData()
  func reloadRenderMeasurePointsData()
  func reloadBoundingBoxData()
  func reloadRenderDataSelectedAtoms()
  func reloadBackgroundImage()
  
  func updateStructureUniforms()
  func updateIsosurfaceUniforms()
  func updateLightUniforms()
  
  func updateVertexArrays()
  
  func updateAdsorptionSurface(completionHandler: @escaping () -> ())
  func invalidateCachedAmbientOcclusionTextures()
  func invalidateCachedAmbientOcclusionTexture(_ structures: [RKRenderStructure])
  
  func updateAmbientOcclusion()
  func invalidateIsosurfaces()
  func invalidateIsosurface(_ structures: [RKRenderStructure])
  
  func computeVoidFractions(structures: [RKRenderStructure])
  func computeNitrogenSurfaceArea(structures: [RKRenderStructure])
  
  func redraw()
  func makePicture(size: NSSize, imageQuality: RKImageQuality) -> Data
  func makeCVPicture(_ pixelBuffer: CVPixelBuffer)
  
  func pickPoint(_ point: NSPoint) ->  [Int32]
  func pickDepth(_ point: NSPoint) ->  Float?
}
