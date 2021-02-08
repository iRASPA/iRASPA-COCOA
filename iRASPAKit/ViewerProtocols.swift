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
import RenderKit
import SymmetryKit
import SimulationKit

public protocol ForceFieldDefiner: class
{
  var forceFieldSets: SKForceFieldSets {get}
}

public protocol StructureViewer: class
{
  var allStructures: [Structure] {get}
  var allIRASPAStructures: [iRASPAStructure] {get}
  var selectedRenderFrames: [RKRenderStructure] {get}
  var allRenderFrames: [RKRenderStructure] {get}
}

public protocol CellViewer: StructureViewer
{
  var spaceGroupHallNumber: Int? {get set}

  var renderUnitCellLengthA: Double? {get set}
  var renderUnitCellLengthB: Double? {get set}
  var renderUnitCellLengthC: Double? {get set}
  var renderUnitCellAlphaAngle: Double? {get set}
  var renderUnitCellBetaAngle: Double? {get set}
  var renderUnitCellGammaAngle: Double? {get set}
  
  var renderUnitCellAX: Double? {get set}
  var renderUnitCellAY: Double? {get set}
  var renderUnitCellAZ: Double? {get set}
  var renderUnitCellBX: Double? {get set}
  var renderUnitCellBY: Double? {get set}
  var renderUnitCellBZ: Double? {get set}
  var renderUnitCellCX: Double? {get set}
  var renderUnitCellCY: Double? {get set}
  var renderUnitCellCZ: Double? {get set}
  var renderCellVolume: Double? {get}
  var renderCellPerpendicularWidthX: Double? {get}
  var renderCellPerpendicularWidthY: Double? {get}
  var renderCellPerpendicularWidthZ: Double? {get}
  
  var renderOriginX: Double? {get set}
  var renderOriginY: Double? {get set}
  var renderOriginZ: Double? {get set}
  var renderOrientation: simd_quatd? {get set}
  var renderRotationDelta: Double? {get set}
  var renderPeriodic: Bool? {get set}
  
  var renderMinimumReplicaX: Int32? {get set}
  var renderMinimumReplicaY: Int32? {get set}
  var renderMinimumReplicaZ: Int32? {get set}
  var renderMaximumReplicaX: Int32? {get set}
  var renderMaximumReplicaY: Int32? {get set}
  var renderMaximumReplicaZ: Int32? {get set}
  
  //var renderEulerAngles: double3? {get set}
  var renderEulerAngleX: Double? {get set}
  var renderEulerAngleY: Double? {get set}
  var renderEulerAngleZ: Double? {get set}
  
  var renderBoundingBox: SKBoundingBox {get}
  func reComputeBoundingBox()
  
  var frames: [iRASPAStructure] {get}
}

public protocol InfoViewer: StructureViewer
{
  var structureAuthorFirstName: String? {get set}
  var structureAuthorMiddleName: String? {get set}
  var structureAuthorLastName: String? {get set}
  var structureAuthorOrchidID: String? {get set}
  var structureAuthorResearcherID: String? {get set}
  var structureAuthorAffiliationUniversityName: String? {get set}
  var structureAuthorAffiliationFacultyName: String? {get set}
  var structureAuthorAffiliationInstituteName: String? {get set}
  var structureAuthorAffiliationCityName: String? {get set}
  var structureAuthorAffiliationCountryName: String? {get set}
  
  var structureCreationDate: Date? {get set}
  var structureCreationTemperature: String? {get set}
  var structureCreationTemperatureScale: Structure.TemperatureScale? {get set}
  var structureCreationPressure: String? {get set}
  var structureCreationPressureScale: Structure.PressureScale? {get set}
  var structureCreationMethod: Structure.CreationMethod? {get set}
  var structureCreationUnitCellRelaxationMethod: Structure.UnitCellRelaxationMethod? {get set}
  var structureCreationAtomicPositionsSoftwarePackage: String? {get set}
  var structureCreationAtomicPositionsIonsRelaxationAlgorithm: Structure.IonsRelaxationAlgorithm? {get set}
  var structureCreationAtomicPositionsIonsRelaxationCheck: Structure.IonsRelaxationCheck? {get set}
  var structureCreationAtomicPositionsForcefield: String? {get set}
  var structureCreationAtomicPositionsForcefieldDetails: String? {get set}
  var structureCreationAtomicChargesSoftwarePackage: String? {get set}
  var structureCreationAtomicChargesAlgorithms: String? {get set}
  var structureCreationAtomicChargesForcefield: String? {get set}
  var structureCreationAtomicChargesForcefieldDetails: String? {get set}
  
  var structureExperimentalMeasurementRadiation: String? {get set}
  var structureExperimentalMeasurementWaveLength: String? {get set}
  var structureExperimentalMeasurementThetaMin: String? {get set}
  var structureExperimentalMeasurementThetaMax: String? {get set}
  var structureExperimentalMeasurementIndexLimitsHmin: String? {get set}
  var structureExperimentalMeasurementIndexLimitsHmax: String? {get set}
  var structureExperimentalMeasurementIndexLimitsKmin: String? {get set}
  var structureExperimentalMeasurementIndexLimitsKmax: String? {get set}
  var structureExperimentalMeasurementIndexLimitsLmin: String? {get set}
  var structureExperimentalMeasurementIndexLimitsLmax: String? {get set}
  var structureExperimentalMeasurementNumberOfSymmetryIndependentReflections: String? {get set}
  var structureExperimentalMeasurementSoftware: String? {get set}
  var structureExperimentalMeasurementRefinementDetails: String? {get set}
  var structureExperimentalMeasurementGoodnessOfFit: String? {get set}
  var structureExperimentalMeasurementRFactorGt: String? {get set}
  var structureExperimentalMeasurementRFactorAll: String? {get set}
  
  var structureChemicalFormulaMoiety: String? {get set}
  var structureChemicalFormulaSum: String? {get set}
  var structureChemicalNameSystematic: String? {get set}
  
  var structureCitationArticleTitle: String? {get set}
  var structureCitationAuthors: String? {get set}
  var structureCitationJournalTitle: String? {get set}
  var structureCitationJournalVolume: String? {get set}
  var structureCitationJournalNumber: String? {get set}
  var structureCitationDOI: String? {get set}
  var structureCitationPublicationDate: Date? {get set}
  var structureCitationDatebaseCodes: String? {get set}
}

public protocol AtomVisualAppearanceViewer: StructureViewer
{
  func recheckRepresentationStyle()
  
  func getRepresentationType() -> Structure.RepresentationType?
  func setRepresentationType(type: Structure.RepresentationType?)
  
  func getRepresentationStyle() -> Structure.RepresentationStyle?
  func setRepresentationStyle(style: Structure.RepresentationStyle?, colorSets: SKColorSets)
  
  func getRepresentationColorScheme() -> String?
  func setRepresentationColorScheme(scheme: String?, colorSets: SKColorSets)
  
  func getRepresentationColorOrder() -> SKColorSets.ColorOrder?
  func setRepresentationColorOrder(order: SKColorSets.ColorOrder?, colorSets: SKColorSets)
  
  func getRepresentationForceField() -> String?
  func setRepresentationForceField(forceField: String?, forceFieldSets: SKForceFieldSets)
  
  func getRepresentationForceFieldOrder() -> SKForceFieldSets.ForceFieldOrder?
  func setRepresentationForceFieldOrder(order: SKForceFieldSets.ForceFieldOrder?, forceFieldSets: SKForceFieldSets)
  
  var renderAtomHue: Double? {get set}
  var renderAtomSaturation: Double? {get set}
  var renderAtomValue: Double? {get set}
  var renderAtomScaleFactor: Double? {get set}
  var renderAtomScaleFactorCompleted: Double? {get set}
  
  
  var renderDrawAtoms: Bool? {get set}
  
  var renderAtomAmbientOcclusion: Bool? {get set}
  
  var renderAtomHDR: Bool? {get set}
  var renderAtomHDRExposure: Double? {get set}
  
  var renderAtomAmbientColor: NSColor? {get set}
  var renderAtomDiffuseColor: NSColor? {get set}
  var renderAtomSpecularColor: NSColor? {get set}
  var renderAtomAmbientIntensity: Double? {get set}
  var renderAtomDiffuseIntensity: Double? {get set}
  var renderAtomSpecularIntensity: Double? {get set}
  var renderAtomShininess: Double? {get set}
  
  var renderAtomSelectionStyle: RKSelectionStyle? {get set}
  var renderAtomSelectionFrequency: Double? {get set}
  var renderAtomSelectionDensity: Double? {get set}
  var renderAtomSelectionIntensity: Double? {get set}
  var renderAtomSelectionScaling: Double? {get set}
}
  
public protocol PrimitiveVisualAppearanceViewer
{
  var allPrimitiveStructure: [Structure] {get}
  
  var renderDrawAtoms: Bool? {get set}
  
  var renderPrimitiveOrientation: simd_quatd? {get set}
  var renderPrimitiveRotationDelta: Double?  {get set}
  var renderPrimitiveEulerAngleX: Double?  {get set}
  var renderPrimitiveEulerAngleY: Double?  {get set}
  var renderPrimitiveEulerAngleZ: Double?  {get set}
  var renderPrimitiveTransformationMatrix: double3x3?  {get set}
  var renderPrimitiveTransformationMatrixAX: Double?  {get set}
  var renderPrimitiveTransformationMatrixAY: Double?  {get set}
  var renderPrimitiveTransformationMatrixAZ: Double?  {get set}
  var renderPrimitiveTransformationMatrixBX: Double?  {get set}
  var renderPrimitiveTransformationMatrixBY: Double? {get set}
  var renderPrimitiveTransformationMatrixBZ: Double? {get set}
  var renderPrimitiveTransformationMatrixCX: Double? {get set}
  var renderPrimitiveTransformationMatrixCY: Double? {get set}
  var renderPrimitiveTransformationMatrixCZ: Double? {get set}
  
  var renderPrimitiveOpacity: Double? {get set}
  var renderPrimitiveNumberOfSides: Int? {get set}
  var renderPrimitiveIsCapped: Bool? {get set}
  var renderPrimitiveIsFractional: Bool? {get set}
  var renderPrimitiveThickness: Double? {get set}
  
  var renderPrimitiveFrontSideHDR: Bool? {get set}
  var renderPrimitiveFrontSideHDRExposure: Double? {get set}
  var renderPrimitiveFrontSideAmbientIntensity: Double? {get set}
  var renderPrimitiveFrontSideDiffuseIntensity: Double? {get set}
  var renderPrimitiveFrontSideSpecularIntensity: Double? {get set}
  var renderPrimitiveFrontSideShininess: Double? {get set}
  var renderPrimitiveFrontSideAmbientColor: NSColor? {get set}
  var renderPrimitiveFrontSideDiffuseColor: NSColor? {get set}
  var renderPrimitiveFrontSideSpecularColor: NSColor? {get set}
  
  var renderPrimitiveBackSideHDR: Bool? {get set}
  var renderPrimitiveBackSideHDRExposure: Double? {get set}
  var renderPrimitiveBackSideAmbientIntensity: Double? {get set}
  var renderPrimitiveBackSideDiffuseIntensity: Double? {get set}
  var renderPrimitiveBackSideSpecularIntensity: Double? {get set}
  var renderPrimitiveBackSideShininess: Double? {get set}
  var renderPrimitiveBackSideAmbientColor: NSColor? {get set}
  var renderPrimitiveBackSideDiffuseColor: NSColor? {get set}
  var renderPrimitiveBackSideSpecularColor: NSColor? {get set}
}


public protocol BondVisualAppearanceViewer: StructureViewer
{
  func recheckRepresentationStyleBond()
  
  var renderDrawBonds: Bool? {get set}
  var renderBondScaleFactor: Double? {get set}
  var renderBondColorMode: RKBondColorMode? {get set}
  
  var renderBondAmbientOcclusion: Bool? {get set}
  
  var renderBondHDR: Bool? {get set}
  var renderBondHDRExposure: Double? {get set}
  
  var renderBondHue: Double? {get set}
  var renderBondSaturation: Double? {get set}
  var renderBondValue: Double? {get set}
  
  var renderBondAmbientColor: NSColor? {get set}
  var renderBondDiffuseColor: NSColor? {get set}
  var renderBondSpecularColor: NSColor? {get set}
  var renderBondAmbientIntensity: Double? {get set}
  var renderBondDiffuseIntensity: Double? {get set}
  var renderBondSpecularIntensity: Double? {get set}
  var renderBondShininess: Double? {get set}
  
  var renderBondSelectionStyle: RKSelectionStyle? {get set}
  var renderBondSelectionFrequency: Double? {get set}
  var renderBondSelectionDensity: Double? {get set}
  var renderBondSelectionIntensity: Double? {get set}
  var renderBondSelectionScaling: Double? {get set}
}

public protocol UnitCellVisualAppearanceViewer: StructureViewer
{
  var renderDrawUnitCell: Bool? {get set}
  var renderUnitCellScaleFactor: Double? {get set}
  var renderUnitCellDiffuseColor: NSColor? {get set}
  var renderUnitCellDiffuseIntensity: Double? {get set}
}

public protocol AdsorptionSurfaceVisualAppearanceViewer: StructureViewer
{
  var renderCanDrawAdsorptionSurface: Bool {get}
  var renderAdsorptionSurfaceOn: Bool? {get set}
  
  var renderAdsorptionSurfaceOpacity: Double? {get set}
  var renderAdsorptionSurfaceIsovalue: Double? {get set}
  var renderAdsorptionSurfaceProbeMolecule: Structure.ProbeMolecule? {get set}
  
  var renderMinimumGridEnergyValue: Float? {get set}
  
  var renderAdsorptionSurfaceFrontSideHDR: Bool? {get set}
  var renderAdsorptionSurfaceFrontSideHDRExposure: Double? {get set}
  var renderAdsorptionSurfaceFrontSideAmbientIntensity: Double? {get set}
  var renderAdsorptionSurfaceFrontSideDiffuseIntensity: Double? {get set}
  var renderAdsorptionSurfaceFrontSideSpecularIntensity: Double? {get set}
  var renderAdsorptionSurfaceFrontSideShininess: Double? {get set}
  var renderAdsorptionSurfaceFrontSideAmbientColor: NSColor? {get set}
  var renderAdsorptionSurfaceFrontSideDiffuseColor: NSColor? {get set}
  var renderAdsorptionSurfaceFrontSideSpecularColor: NSColor? {get set}
  
  var renderAdsorptionSurfaceBackSideHDR: Bool? {get set}
  var renderAdsorptionSurfaceBackSideHDRExposure: Double? {get set}
  var renderAdsorptionSurfaceBackSideAmbientIntensity: Double? {get set}
  var renderAdsorptionSurfaceBackSideDiffuseIntensity: Double? {get set}
  var renderAdsorptionSurfaceBackSideSpecularIntensity: Double? {get set}
  var renderAdsorptionSurfaceBackSideShininess: Double? {get set}
  var renderAdsorptionSurfaceBackSideAmbientColor: NSColor? {get set}
  var renderAdsorptionSurfaceBackSideDiffuseColor: NSColor? {get set}
  var renderAdsorptionSurfaceBackSideSpecularColor: NSColor? {get set}
}
