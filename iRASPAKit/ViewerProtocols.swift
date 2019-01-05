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
import RenderKit
import SymmetryKit
import SimulationKit

public protocol StructureViewer: class
{
  var structureViewerStructures: [Structure] {get}
  
  var selectedRenderFrames: [RKRenderStructure] {get}
  var allFrames: [RKRenderStructure] {get}
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
  
  var renderDrawAtoms: Bool? {get set}
  
  var renderAtomAmbientOcclusion: Bool? {get set}
  
  var renderAtomHDR: Bool? {get set}
  var renderAtomHDRExposure: Double? {get set}
  var renderAtomHDRBloomLevel: Double? {get set}
  
  var renderAtomAmbientColor: NSColor? {get set}
  var renderAtomDiffuseColor: NSColor? {get set}
  var renderAtomSpecularColor: NSColor? {get set}
  var renderAtomAmbientIntensity: Double? {get set}
  var renderAtomDiffuseIntensity: Double? {get set}
  var renderAtomSpecularIntensity: Double? {get set}
  var renderAtomShininess: Double? {get set}
}



public protocol BondVisualAppearanceViewer: StructureViewer
{
  var renderDrawBonds: Bool? {get set}
  var renderBondScaleFactor: Double? {get set}
  var renderBondColorMode: RKBondColorMode? {get set}
  
  var renderBondAmbientOcclusion: Bool? {get set}
  
  var renderBondHDR: Bool? {get set}
  var renderBondHDRExposure: Double? {get set}
  var renderBondHDRBloomLevel: Double? {get set}
  
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
  
  var renderFrontAdsorptionSurfaceHDR: Bool? {get set}
  var renderFrontAdsorptionSurfaceHDRExposure: Double? {get set}
  var renderFrontAdsorptionSurfaceAmbientIntensity: Double? {get set}
  var renderFrontAdsorptionSurfaceDiffuseIntensity: Double? {get set}
  var renderFrontAdsorptionSurfaceSpecularIntensity: Double? {get set}
  var renderFrontAdsorptionSurfaceShininess: Double? {get set}
  var renderFrontAdsorptionSurfaceAmbientColor: NSColor? {get set}
  var renderFrontAdsorptionSurfaceDiffuseColor: NSColor? {get set}
  var renderFrontAdsorptionSurfaceSpecularColor: NSColor? {get set}
  
  var renderBackAdsorptionSurfaceHDR: Bool? {get set}
  var renderBackAdsorptionSurfaceHDRExposure: Double? {get set}
  var renderBackAdsorptionSurfaceAmbientIntensity: Double? {get set}
  var renderBackAdsorptionSurfaceDiffuseIntensity: Double? {get set}
  var renderBackAdsorptionSurfaceSpecularIntensity: Double? {get set}
  var renderBackAdsorptionSurfaceShininess: Double? {get set}
  var renderBackAdsorptionSurfaceAmbientColor: NSColor? {get set}
  var renderBackAdsorptionSurfaceDiffuseColor: NSColor? {get set}
  var renderBackAdsorptionSurfaceSpecularColor: NSColor? {get set}
}
