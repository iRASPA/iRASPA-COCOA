/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2021 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
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

public protocol RKRenderAtomSource: RKRenderObject
{
  var numberOfAtoms: Int {get}
  var drawAtoms: Bool {get}
  
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

public protocol RKRenderUnitCellSource: RKRenderObject
{
  var drawUnitCell: Bool {get}
  var unitCellScaleFactor: Double {get}
  var unitCellDiffuseColor: NSColor {get}
  var unitCellDiffuseIntensity: Double {get}
  
  var renderUnitCellSpheres: [RKInPerInstanceAttributesAtoms] {get}
  var renderUnitCellCylinders: [RKInPerInstanceAttributesBonds] {get}
}

public protocol RKRenderAdsorptionSurfaceSource: RKRenderObject
{
  var potentialParameters: [SIMD2<Double>] {get}
  
  // adsorption surface
  var drawAdsorptionSurface: Bool {get}
  
  var adsorptionSurfaceRenderingMethod: RKEnergySurfaceType {get}
  var adsorptionVolumeTransferFunction: RKPredefinedVolumeRenderingTransferFunction {get}
  var adsorptionVolumeStepLength: Double {get}
  
  var adsorptionSurfaceOpacity: Double {get}
  var adsorptionSurfaceIsoValue: Double {get}
  var adsorptionSurfaceSize: Int {get}
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
  
  var atomUnitCellPositions: [SIMD3<Double>] {get}
  var minimumGridEnergyValue: Float? {get set}
  
  var frameworkProbeParameters: SIMD2<Double> {get}
  var structureHeliumVoidFraction: Double {get set}
  var structureNitrogenSurfaceArea: Double {get set}
}

public protocol RKRenderObjectSource //: RKRenderStructure
{
  var numberOfAtoms: Int {get}
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

public protocol RKRenderCrystalEllipsoidObjectsSource: RKRenderObjectSource
{
  var renderCrystalEllipsoidObjects: [RKInPerInstanceAttributesAtoms] {get}
  var renderSelectedCrystalEllipsoidObjects: [RKInPerInstanceAttributesAtoms] {get}
}

public protocol RKRenderEllipsoidObjectsSource: RKRenderObjectSource
{
  var renderEllipsoidObjects: [RKInPerInstanceAttributesAtoms] {get}
  var renderSelectedEllipsoidObjects: [RKInPerInstanceAttributesAtoms] {get}
}



public protocol RKRenderCrystalCylinderObjectsSource: RKRenderObjectSource
{
  var renderCrystalCylinderObjects: [RKInPerInstanceAttributesAtoms] {get}
  var renderSelectedCrystalCylinderObjects: [RKInPerInstanceAttributesAtoms] {get}
}

public protocol RKRenderCylinderObjectsSource: RKRenderObjectSource
{
  var renderCylinderObjects: [RKInPerInstanceAttributesAtoms] {get}
  var renderSelectedCylinderObjects: [RKInPerInstanceAttributesAtoms] {get}
}

public protocol RKRenderCrystalPolygonalPrismObjectsSource: RKRenderObjectSource
{
  var renderCrystalPolygonalPrismObjects: [RKInPerInstanceAttributesAtoms] {get}
  var renderSelectedCrystalPolygonalPrismObjects: [RKInPerInstanceAttributesAtoms] {get}
}

public protocol RKRenderPolygonalPrismObjectsSource: RKRenderObjectSource
{
  var renderPolygonalPrismObjects: [RKInPerInstanceAttributesAtoms] {get}
  var renderSelectedPolygonalPrismObjects: [RKInPerInstanceAttributesAtoms] {get}
}

public protocol RKRenderLocalAxesSource
{
  var renderLocalAxis: RKLocalAxes {get}
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
  
  var showBoundingBox: Bool {get set}
  var renderBoundingBoxSpheres: [RKInPerInstanceAttributesAtoms] {get}
  var renderBoundingBoxCylinders: [RKInPerInstanceAttributesBonds] {get}
  
  var renderAxes: RKGlobalAxes {get}
}


public protocol RKRenderDensityVolumeSource: AnyObject
{
  var data: Data {get}
  var dimensions: SIMD3<Int32> {get}
  var spacing: SIMD3<Double> {get}
}

public protocol RKRenderRASPADensityVolumeSource: RKRenderDensityVolumeSource
{

}

public protocol RKRenderVTKDensityVolumeSource: RKRenderDensityVolumeSource
{

}
