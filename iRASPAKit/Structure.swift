/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import Accelerate
import BinaryCodable
import RenderKit
import SymmetryKit
import SimulationKit
import MathKit
import OperationKit

infix operator ==~ : AssignmentPrecedence
fileprivate func ==~ (left: Double, right: Double) -> Bool
{
  return left == nextafter(right,Double.greatestFiniteMagnitude) || left == nextafter(right,-Double.greatestFiniteMagnitude) || left == right
}

public let NSPasteboardTypeStructure: String = "nl.iRASPA.Structure"

public class Structure: NSObject, Decodable, RKRenderStructure, SKRenderAdsorptionSurfaceStructure, BinaryDecodable, BinaryEncodable, Cloning
{
  private var versionNumber: Int = 4
  private static var classVersionNumber: Int = 4
  
  public var atoms: SKAtomTreeController = SKAtomTreeController()
  public var bonds: SKBondSetController = SKBondSetController()
  
    
  // MARK: protocol RKRenderStructure implementation
  // =====================================================================
  public var displayName: String = "uninitialized"
  public var isVisible: Bool = true
   
  public var origin: SIMD3<Double> = SIMD3<Double>(x: 0.0, y: 0.0, z: 0.0)
  public var orientation: simd_quatd = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
  
  public var cell: SKCell = SKCell()
  
  // MARK: protocol RKRenderAtomSource implementation
  // =====================================================================
  
  public var numberOfAtoms: Int
  {
    return self.atoms.flattenedLeafNodes().count
  }
  public var drawAtoms: Bool =  true
  
  // material properties
  public var atomAmbientColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var atomDiffuseColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var atomSpecularColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var atomAmbientIntensity: Double = 0.2
  public var atomDiffuseIntensity: Double = 1.0
  public var atomSpecularIntensity: Double = 1.0
  public var atomShininess: Double = 4.0
  
  public var atomHue: Double = 1.0
  public var atomSaturation: Double = 1.0
  public var atomValue: Double = 1.0
  
  public var colorAtomsWithBondColor: Bool {return true}
  public var atomScaleFactor: Double = 1.0
  public var atomAmbientOcclusion: Bool = true
  public var atomAmbientOcclusionPatchNumber: Int = 256
  public var atomAmbientOcclusionPatchSize: Int = 16
  public var atomAmbientOcclusionTextureSize: Int = 1024
  
  public var atomHDR: Bool = true
  public var atomHDRExposure: Double = 1.5
  public var atomHDRBloomLevel: Double = 0.5
  public var clipAtomsAtUnitCell: Bool {return false}
  public var atomPositions: [SIMD4<Double>]
  {
    return []
  }
  public var renderAtoms: [RKInPerInstanceAttributesAtoms]
  {
    return []
  }
  
  public var atomTextData: [RKInPerInstanceAttributesText]
  {
    var data: [RKInPerInstanceAttributesText] = []
      
    let fontAtlas: RKFontAtlas = RKCachedFontAtlas.shared.fontAtlas(for: self.atomTextFont)
      
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
      
    for atom in atoms
    {
      let pos: SIMD3<Double> = atom.position
        
      let w: Float = (atom.asymmetricParentAtom.isVisible && atom.asymmetricParentAtom.isVisibleEnabled)  ? 1.0 : -1.0
      let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(pos.x), y: Float(pos.y), z: Float(pos.z), w: w)
      let radius: Float = Float(atom.asymmetricParentAtom?.drawRadius ?? 1.0)
        
      let text: String
      switch(atomTextType)
      {
      case .none:
        text = ""
      case .displayName:
        text = String(atom.asymmetricParentAtom.displayName)
      case .identifier:
        text = String(atom.tag)
      case .chemicalElement:
        text = PredefinedElements.sharedInstance.elementSet[atom.asymmetricParentAtom.elementIdentifier].chemicalSymbol
      case .forceFieldType:
        text = atom.asymmetricParentAtom.uniqueForceFieldName
      case .position:
        text = String("(\(atom.position.x),\(atom.position.y),\(atom.position.z))")
      case .charge:
        text = String(atom.asymmetricParentAtom.charge)
      }
        
      let instances = fontAtlas.buildMeshWithString(position: atomPosition, scale: SIMD4<Float>(radius,radius,radius,1.0), text: text, alignment: self.atomTextAlignment)
        
      data += instances
    }
    return data
  }
  
  public var atomTextType: RKTextType = RKTextType.none
  public var atomTextFont: String = "Helvetica"
  public var atomTextAlignment: RKTextAlignment = RKTextAlignment.center
  public var atomTextStyle: RKTextStyle = RKTextStyle.flatBillboard
  public var atomTextColor: NSColor = NSColor.black
  public var atomTextScaling: Double = 1.0
  public var atomTextOffset: SIMD3<Double> = SIMD3<Double>()
  public var atomTextGlowColor: NSColor = NSColor.blue
  public var atomTextEffect: RKTextEffect = RKTextEffect.none
  
  public var renderSelectedAtoms: [RKInPerInstanceAttributesAtoms]
  {
    return []
  }
  
  public var atomSelectionStyle: RKSelectionStyle = .WorleyNoise3D
  public var atomSelectionScaling: Double = 1.2
  public var atomSelectionStripesDensity: Double = 0.25
  public var atomSelectionStripesFrequency: Double = 12.0
  public var atomSelectionWorleyNoise3DFrequency: Double = 2.0
  public var atomSelectionWorleyNoise3DJitter: Double = 1.0
  
  public func CartesianPosition(for position: SIMD3<Double>, replicaPosition: SIMD3<Int32>) -> SIMD3<Double>
  {
    return position
  }
  
  // MARK: protocol RKRenderBondSource implementation
  // =====================================================================
  
  public var numberOfInternalBonds: Int
  {
    return self.bonds.arrangedObjects.filter{$0.boundaryType == .internal}.count
  }
  
  public var numberOfExternalBonds: Int
  {
    return self.bonds.arrangedObjects.filter{$0.boundaryType == .external}.count
  }
  
  public var bondPositions: [SIMD3<Double>]
  {
      return []
  }
  
  public var internalBondPositions: [SIMD4<Double>]
  {
    return []
  }
  
  public var externalBondPositions: [SIMD4<Double>]
  {
    return []
  }
  
  public var drawBonds: Bool = true
  
  public var bondAmbientColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var bondDiffuseColor: NSColor = NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
  public var bondSpecularColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var bondAmbientIntensity: Double = 0.1
  public var bondDiffuseIntensity: Double = 1.0
  public var bondSpecularIntensity: Double = 1.0
  public var bondShininess: Double = 4.0

  public var hasExternalBonds: Bool {return false}
  
  public var bondScaleFactor: Double = 1.0
  public var bondColorMode: RKBondColorMode = .split
  
  public var bondHDR: Bool = true
  public var bondHDRExposure: Double = 1.5
  public var bondHDRBloomLevel: Double = 1.0
  public var clipBondsAtUnitCell: Bool {return false}
  
  public var bondHue: Double = 1.0
  public var bondSaturation: Double = 1.0
  public var bondValue: Double = 1.0
  
  // MARK: protocol RKRenderUnitCellSource implementation
  // =====================================================================
  
  public var drawUnitCell: Bool = false
  public var renderUnitCellSpheres: [RKInPerInstanceAttributesAtoms]
  {
    return []
  }

  public var renderUnitCellCylinders:[RKInPerInstanceAttributesBonds]
  {
    return []
  }
  
  public var unitCellScaleFactor: Double = 1.0
  public var unitCellDiffuseColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var unitCellDiffuseIntensity: Double = 1.0
   
  // MARK: protocol RKRenderAdsorptionSurfaceSource implementation
  // =====================================================================
  
  public var potentialParameters: [SIMD2<Double>] {return []}
  
  public var drawAdsorptionSurface: Bool = false
  public var adsorptionSurfaceOpacity: Double = 1.0
  public var adsorptionSurfaceIsoValue: Double = 0.0
  public var adsorptionSurfaceSize: Int = 128
  public var adsorptionSurfaceProbeParameters: SIMD2<Double>
  {
    switch(adsorptionSurfaceProbeMolecule)
    {
    case .helium:
      return SIMD2<Double>(10.9, 2.64)
    case .nitrogen:
      return SIMD2<Double>(36.0,3.31)
    case .methane:
      return SIMD2<Double>(158.5,3.72)
    case .hydrogen:
      return SIMD2<Double>(36.7,2.958)
    case .water:
      return SIMD2<Double>(89.633,3.097)
    case .co2:
      // Y. Iwai, H. Higashi, H. Uchida, Y. Arai, Fluid Phase Equilibria 127 (1997) 251-261.
      return SIMD2<Double>(236.1,3.72)
    case .xenon:
      // Gábor Rutkai, Monika Thol, Roland Span & Jadran Vrabec (2017), Molecular Physics, 115:9-12, 1104-1121
      return SIMD2<Double>(226.14,3.949)
    case .krypton:
      // Gábor Rutkai, Monika Thol, Roland Span & Jadran Vrabec (2017), Molecular Physics, 115:9-12, 1104-1121
      return SIMD2<Double>(162.58,3.6274)
    case .argon:
      return SIMD2<Double>(119.8,3.34)
    }
  }
  public var adsorptionSurfaceNumberOfTriangles: Int = 0
  
  public var adsorptionSurfaceFrontSideHDR: Bool = true
  public var adsorptionSurfaceFrontSideHDRExposure: Double = 1.5
  public var adsorptionSurfaceFrontSideAmbientColor: NSColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
  public var adsorptionSurfaceFrontSideDiffuseColor: NSColor = NSColor(red: 0.588235, green: 0.670588, blue: 0.729412, alpha: 1.0)
  public var adsorptionSurfaceFrontSideSpecularColor: NSColor = NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
  public var adsorptionSurfaceFrontSideDiffuseIntensity: Double = 1.0
  public var adsorptionSurfaceFrontSideAmbientIntensity: Double = 0.2
  public var adsorptionSurfaceFrontSideSpecularIntensity: Double = 1.0
  public var adsorptionSurfaceFrontSideShininess: Double = 4.0
  
  public var adsorptionSurfaceBackSideHDR: Bool = true
  public var adsorptionSurfaceBackSideHDRExposure: Double = 1.5
  public var adsorptionSurfaceBackSideAmbientColor: NSColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
  public var adsorptionSurfaceBackSideDiffuseColor: NSColor = NSColor(red: 0.588235, green: 0.670588, blue: 0.729412, alpha: 1.0)
  public var adsorptionSurfaceBackSideSpecularColor: NSColor = NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
  public var adsorptionSurfaceBackSideDiffuseIntensity: Double = 1.0
  public var adsorptionSurfaceBackSideAmbientIntensity: Double = 0.2
  public var adsorptionSurfaceBackSideSpecularIntensity: Double = 1.0
  public var adsorptionSurfaceBackSideShininess: Double = 4.0
  
  public var atomUnitCellPositions: [SIMD3<Double>] {return []}
  public var minimumGridEnergyValue: Float? = nil
  
  public var frameworkProbeParameters: SIMD2<Double>
  {
    switch(frameworkProbeMolecule)
    {
    case .helium:
      return SIMD2<Double>(10.9, 2.64)
    case .nitrogen:
      return SIMD2<Double>(36.0,3.31)
    case .methane:
      return SIMD2<Double>(158.5,3.72)
    case .hydrogen:
      return SIMD2<Double>(36.7,2.958)
    case .water:
      return SIMD2<Double>(89.633,3.097)
    case .co2:
      // Y. Iwai, H. Higashi, H. Uchida, Y. Arai, Fluid Phase Equilibria 127 (1997) 251-261.
      return SIMD2<Double>(236.1,3.72)
    case .xenon:
      // Gábor Rutkai, Monika Thol, Roland Span & Jadran Vrabec (2017), Molecular Physics, 115:9-12, 1104-1121
      return SIMD2<Double>(226.14,3.949)
    case .krypton:
      // Gábor Rutkai, Monika Thol, Roland Span & Jadran Vrabec (2017), Molecular Physics, 115:9-12, 1104-1121
      return SIMD2<Double>(162.58,3.6274)
    case .argon:
      return SIMD2<Double>(119.8,3.34)
    }
  }
  
  public var structureNitrogenSurfaceArea: Double = 0.0
  {
    didSet
    {
      self.structureGravimetricNitrogenSurfaceArea = structureNitrogenSurfaceArea * SKConstants.AvogadroConstantPerAngstromSquared / self.structureMass
      self.structureVolumetricNitrogenSurfaceArea = structureNitrogenSurfaceArea * 1e4 / self.cell.volume
    }
  }
  
  // MARK: protocol RKRenderObjectSource implementation
  // =====================================================================
  
  public var primitiveTransformationMatrix: double3x3 = double3x3(1.0)
  public var primitiveOrientation: simd_quatd = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
  
  public var primitiveOpacity: Double = 1.0
  public var primitiveIsCapped: Bool = false
  public var primitiveIsFractional: Bool = true
  public var primitiveNumberOfSides: Int = 6
  public var primitiveThickness: Double = 0.05
  
  public var primitiveFrontSideHDR: Bool = true
  public var primitiveFrontSideHDRExposure: Double = 2.0
  public var primitiveFrontSideAmbientColor: NSColor = NSColor.white
  public var primitiveFrontSideDiffuseColor: NSColor = NSColor.yellow
  public var primitiveFrontSideSpecularColor: NSColor = NSColor.white
  public var primitiveFrontSideAmbientIntensity: Double = 0.1
  public var primitiveFrontSideDiffuseIntensity: Double = 1.0
  public var primitiveFrontSideSpecularIntensity: Double = 0.2
  public var primitiveFrontSideShininess: Double = 4.0
  
  public var primitiveBackSideHDR: Bool = true
  public var primitiveBackSideHDRExposure: Double = 2.0
  public var primitiveBackSideAmbientColor: NSColor = NSColor.white
  public var primitiveBackSideDiffuseColor: NSColor = NSColor(red: 0.0, green: 0.5490196, blue: 1.0, alpha: 1.0) // Aqua
  public var primitiveBackSideSpecularColor: NSColor = NSColor.white
  public var primitiveBackSideAmbientIntensity: Double = 0.1
  public var primitiveBackSideDiffuseIntensity: Double = 1.0
  public var primitiveBackSideSpecularIntensity: Double = 0.2
  public var primitiveBackSideShininess: Double = 4.0
  
  // MARK: other variables
  // =====================================================================
  
  
  public var primitiveRotationDelta: Double = 5.0
  
  public var adsorptionSurfaceProbeMolecule: ProbeMolecule = .helium
  
  public var scaling: SIMD3<Double> = SIMD3<Double>(x: 1.0, y: 1.0, z: 1.0)
  
  public var rotationDelta: Double = 5.0
  
  public var periodic: Bool = false
  public var isFractional: Bool
  {
    return false
  }
  
  public var spaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: 1)
  
  var materialType: SKStructure.Kind
  {
    return .structure
  }
  
  var canImportMaterialsTypes: Set<SKStructure.Kind>
  {
    return []
  }
  
  public enum StructureType: Int
  {
    case framework = 0
    case adsorbate = 1
    case cation = 2
    case ionicLiquid = 3
    case solvent = 4
  }
  
  
  public var selectionCOMTranslation: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.0)
  public var selectionRotationIndex: Int = 0
  public var selectionBodyFixedBasis: double3x3 = double3x3(diagonal: SIMD3<Double>(1.0, 1.0, 1.0))
  
  public var structureType: StructureType = .framework
  public var structureMaterialType: String = "Unspecified"
  public var structureMass: Double = 0.0
  public var structureDensity: Double = 0.0
  public var structureHeliumVoidFraction: Double = 0.0
  public var structureSpecificVolume: Double = 0.0
  public var structureAccessiblePoreVolume: Double = 0.0
  public var structureVolumetricNitrogenSurfaceArea: Double = 0.0
  public var structureGravimetricNitrogenSurfaceArea: Double = 0.0
  public var structureNumberOfChannelSystems: Int = 0
  public var structureNumberOfInaccessiblePockets: Int = 0
  public var structureDimensionalityOfPoreSystem: Int = 0
  public var structureLargestCavityDiameter : Double = 0.0
  public var structureRestrictingPoreLimitingDiameter: Double = 0.0
  public var structureLargestCavityDiameterAlongAViablePath : Double = 0.0
  
  
  public var authorFirstName: String = ""
  public var authorMiddleName: String = ""
  public var authorLastName: String = ""
  public var authorOrchidID: String = ""
  public var authorResearcherID: String = ""
  public var authorAffiliationUniversityName: String = ""
  public var authorAffiliationFacultyName: String = ""
  public var authorAffiliationInstituteName: String = ""
  public var authorAffiliationCityName: String = ""
  public var authorAffiliationCountryName: String = Locale.current.localizedString(forRegionCode: Locale.current.regionCode ?? "NL") ?? "Netherlands"
  
  // MARK: enums
  // =====================================================================
  
  public enum TemperatureScale: Int
  {
    case Kelvin = 0
    case Celsius = 1
  }
  public enum PressureScale: Int
  {
    case Pascal = 0
    case bar = 1
  }
  
  public enum CreationMethod: Int
  {
    case unknown = 0
    case simulation = 1
    case experimental = 2
  }
  
  public enum UnitCellRelaxationMethod: Int
  {
    case unknown = 0
    case allFree = 1
    case fixedAnglesIsotropic = 2
    case fixedAnglesAnistropic = 3
    case betaAnglefixed = 4
    case fixedVolumeFreeAngles = 5
    case allFixed = 6
  }
  
  public enum IonsRelaxationAlgorithm: Int
  {
    case unknown = 0
    case none = 1
    case simplex = 2
    case simulatedAnnealing = 3
    case geneticAlgorithm = 4
    case steepestDescent = 5
    case conjugateGradient = 6
    case quasiNewton = 7
    case NewtonRaphson = 8
    case BakersMinimization = 9
  }
  
  public enum IonsRelaxationCheck: Int
  {
    case unknown = 0
    case none = 1
    case allPositiveEigenvalues = 2
    case someSmallNegativeEigenvalues = 3
    case someSignificantNegativeEigenvalues = 4
    case manyNegativeEigenvalues = 5
  }
  
  public var atomRepresentationType: RepresentationType = .sticks_and_balls
  public var atomRepresentationStyle: RepresentationStyle = .default
  public var atomForceFieldIdentifier: String = "Default"
  public var atomForceFieldOrder: SKForceFieldSets.ForceFieldOrder = .elementOnly
  public var atomColorSchemeIdentifier: String = SKColorSets.ColorScheme.jmol.rawValue
  public var atomColorOrder: SKColorSets.ColorOrder = .elementOnly
  
  
  public var selectionIntensity: Double = 1.0
  
  public var atomCacheAmbientOcclusionTexture: [CUnsignedChar] = [CUnsignedChar]()
  
  
  
  
  
  
  
  public var bondAmbientOcclusion: Bool = false
  
  
  
  
  public enum ProbeMolecule: Int
  {
    case helium = 0
    case methane = 1
    case nitrogen = 2
    case hydrogen = 3
    case water = 4
    case co2 = 5
    case xenon = 6
    case krypton = 7
    case argon = 8
  }
  
  public var frameworkProbeMolecule: ProbeMolecule = .nitrogen

  
  
  public var canRemoveSymmetry: Bool
  {
    get
    {
      return false
    }
  }
  
  // StructureViewer protocol
  
  public enum RepresentationType: Int
  {
    case sticks_and_balls = 0
    case vdw = 1
    case unity = 2
  }
  
  public enum RepresentationStyle: Int
  {
    case custom = -1
    case `default` = 0
    case fancy = 1
    case licorice = 2
    case objects = 3
  }
  
  public var creationDate: Date = Date()
  public var creationTemperature: String = ""
  public var creationTemperatureScale: TemperatureScale = .Kelvin
  public var creationPressure: String = ""
  public var creationPressureScale: PressureScale = .Pascal
  public var creationMethod: CreationMethod = .unknown
  public var creationUnitCellRelaxationMethod: UnitCellRelaxationMethod = .unknown
  public var creationAtomicPositionsSoftwarePackage: String = ""
  public var creationAtomicPositionsIonsRelaxationAlgorithm: IonsRelaxationAlgorithm = .unknown
  public var creationAtomicPositionsIonsRelaxationCheck: IonsRelaxationCheck = .unknown
  public var creationAtomicPositionsForcefield: String = ""
  public var creationAtomicPositionsForcefieldDetails: String = ""
  public var creationAtomicChargesSoftwarePackage: String = ""
  public var creationAtomicChargesAlgorithms: String = ""
  public var creationAtomicChargesForcefield: String = ""
  public var creationAtomicChargesForcefieldDetails: String = ""
  
  public var chemicalFormulaMoiety: String = ""
  public var chemicalFormulaSum: String = ""
  public var chemicalNameSystematic: String = ""
  public var cellFormulaUnitsZ: Int = 0
  
  
  public var citationArticleTitle: String = ""
  public var citationJournalTitle: String = ""
  public var citationAuthors: String = ""
  public var citationJournalVolume: String = ""
  public var citationJournalNumber: String = ""
  public var citationJournalPageNumbers: String = ""
  public var citationDOI: String = ""
  public var citationPublicationDate: Date = Date()
  public var citationDatebaseCodes: String = ""
  
  public var experimentalMeasurementRadiation: String = ""                               // _diffrn_radiation_type
  public var experimentalMeasurementWaveLength: String = ""                              // _diffrn_radiation_wavelength
  public var experimentalMeasurementThetaMin: String = ""                                // _cell_measurement_theta_min
  public var experimentalMeasurementThetaMax: String = ""                                // _cell_measurement_theta_max
  public var experimentalMeasurementIndexLimitsHmin: String = ""                         // _diffrn_reflns_limit_h_min
  public var experimentalMeasurementIndexLimitsHmax: String = ""                         // _diffrn_reflns_limit_h_max
  public var experimentalMeasurementIndexLimitsKmin: String = ""                         // _diffrn_reflns_limit_k_min
  public var experimentalMeasurementIndexLimitsKmax: String = ""                         // _diffrn_reflns_limit_k_max
  public var experimentalMeasurementIndexLimitsLmin: String = ""                         // _diffrn_reflns_limit_l_min
  public var experimentalMeasurementIndexLimitsLmax: String = ""                         // _diffrn_reflns_limit_l_max
  public var experimentalMeasurementNumberOfSymmetryIndependentReflections: String = ""  // _reflns_number_total
  public var experimentalMeasurementSoftware: String = ""
  public var experimentalMeasurementRefinementDetails: String = ""                       // _refine_special_details
  public var experimentalMeasurementGoodnessOfFit: String = ""                           // _refine_ls_goodness_of_fit_ref
  public var experimentalMeasurementRFactorGt: String = ""                               // _refine_ls_R_factor_gt
  public var experimentalMeasurementRFactorAll: String = ""                              // _refine_ls_R_factor_all
  

  
  public func tag(atoms: SKAtomTreeController)
  {
    // probably can be done a lot faster by using the tree-structure and recursion
    let asymmetricAtomNodes: [SKAtomTreeNode] = atoms.flattenedNodes()
    for asymmetricAtomNode in asymmetricAtomNodes
    {
      let isVisibleEnabled = asymmetricAtomNode.areAllAncestorsVisible
      asymmetricAtomNode.representedObject.isVisibleEnabled = isVisibleEnabled
    }
    
    let asymmetricAtoms: [SKAsymmetricAtom] = atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    
    for i in 0..<asymmetricAtoms.count
    {
      asymmetricAtoms[i].tag = i
    }
    
    let atomList: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}
    for i in 0..<atomList.count
    {
      atomList[i].tag = i
    }
  }
  
  
  
  
  
  public override init()
  {
    super.init()
  }
  
  public init(name: String)
  {
    self.displayName = name
    super.init()
  }
  
  public required init(original: Structure)
  {
    super.init()
    
    self.displayName = original.displayName
    
    self.origin = original.origin
    self.scaling = original.scaling
    self.orientation = original.orientation
    self.rotationDelta = original.rotationDelta
    self.periodic = original.periodic
    self.isVisible = original.isVisible
    self.cell = original.cell
    self.minimumGridEnergyValue = original.minimumGridEnergyValue
    self.spaceGroup = original.spaceGroup
    
    self.selectionCOMTranslation = original.selectionCOMTranslation
    self.selectionRotationIndex = original.selectionRotationIndex
    self.selectionBodyFixedBasis = original.selectionBodyFixedBasis
    
    self.structureType = original.structureType
    self.structureMaterialType = original.structureMaterialType
    self.structureMass = original.structureMass
    self.structureDensity = original.structureDensity
    self.structureHeliumVoidFraction = original.structureHeliumVoidFraction
    self.structureSpecificVolume = original.structureSpecificVolume
    self.structureAccessiblePoreVolume = original.structureAccessiblePoreVolume
    self.structureVolumetricNitrogenSurfaceArea = original.structureVolumetricNitrogenSurfaceArea
    self.structureGravimetricNitrogenSurfaceArea = original.structureGravimetricNitrogenSurfaceArea
    self.structureNumberOfChannelSystems = original.structureNumberOfChannelSystems
    self.structureNumberOfInaccessiblePockets = original.structureNumberOfInaccessiblePockets
    self.structureDimensionalityOfPoreSystem = original.structureDimensionalityOfPoreSystem
    self.structureLargestCavityDiameter = original.structureLargestCavityDiameter
    self.structureRestrictingPoreLimitingDiameter = original.structureRestrictingPoreLimitingDiameter
    self.structureLargestCavityDiameterAlongAViablePath = original.structureLargestCavityDiameterAlongAViablePath
    
    
    self.authorFirstName = original.authorFirstName
    self.authorMiddleName = original.authorMiddleName
    self.authorLastName = original.authorLastName
    self.authorOrchidID = original.authorOrchidID
    self.authorResearcherID = original.authorResearcherID
    self.authorAffiliationUniversityName = original.authorAffiliationUniversityName
    self.authorAffiliationFacultyName = original.authorAffiliationFacultyName
    self.authorAffiliationInstituteName = original.authorAffiliationInstituteName
    self.authorAffiliationCityName = original.authorAffiliationCityName
    self.authorAffiliationCountryName = original.authorAffiliationCountryName
    
    // primitive properties
    self.primitiveTransformationMatrix = original.primitiveTransformationMatrix
    self.primitiveOrientation = original.primitiveOrientation
    self.primitiveRotationDelta = original.primitiveRotationDelta
    
    self.primitiveOpacity = original.primitiveOpacity
    self.primitiveIsCapped = original.primitiveIsCapped
    self.primitiveIsFractional = original.primitiveIsFractional
    self.primitiveNumberOfSides = original.primitiveNumberOfSides
    self.primitiveThickness = original.primitiveThickness
    
    self.primitiveFrontSideHDR = original.primitiveFrontSideHDR
    self.primitiveFrontSideHDRExposure = original.primitiveFrontSideHDRExposure
    self.primitiveFrontSideAmbientColor = original.primitiveFrontSideAmbientColor
    self.primitiveFrontSideDiffuseColor = original.primitiveFrontSideDiffuseColor
    self.primitiveFrontSideSpecularColor = original.primitiveFrontSideSpecularColor
    self.primitiveFrontSideAmbientIntensity = original.primitiveFrontSideAmbientIntensity
    self.primitiveFrontSideDiffuseIntensity = original.primitiveFrontSideDiffuseIntensity
    self.primitiveFrontSideSpecularIntensity = original.primitiveFrontSideSpecularIntensity
    self.primitiveFrontSideShininess = original.primitiveFrontSideShininess
    
    self.primitiveBackSideHDR = original.primitiveBackSideHDR
    self.primitiveBackSideHDRExposure = original.primitiveBackSideHDRExposure
    self.primitiveBackSideAmbientColor = original.primitiveBackSideAmbientColor
    self.primitiveBackSideDiffuseColor = original.primitiveBackSideDiffuseColor
    self.primitiveBackSideSpecularColor = original.primitiveBackSideSpecularColor
    self.primitiveBackSideAmbientIntensity = original.primitiveBackSideAmbientIntensity
    self.primitiveBackSideDiffuseIntensity = original.primitiveBackSideDiffuseIntensity
    self.primitiveBackSideSpecularIntensity = original.primitiveBackSideSpecularIntensity
    self.primitiveBackSideShininess = original.primitiveBackSideShininess
    
    
    // atoms
    self.atoms = SKAtomTreeController()

    self.drawAtoms = original.drawAtoms
    
    self.atomRepresentationType = original.atomRepresentationType
    self.atomRepresentationStyle = original.atomRepresentationStyle
    self.atomForceFieldIdentifier = original.atomForceFieldIdentifier
    self.atomForceFieldOrder = original.atomForceFieldOrder
    self.atomColorSchemeIdentifier = original.atomColorSchemeIdentifier
    self.atomColorOrder = original.atomColorOrder
    
    self.atomSelectionStyle = original.atomSelectionStyle
    self.atomSelectionStripesDensity = original.atomSelectionStripesDensity
    self.atomSelectionStripesFrequency = original.atomSelectionStripesFrequency
    self.atomSelectionWorleyNoise3DFrequency = original.atomSelectionWorleyNoise3DFrequency
    self.atomSelectionWorleyNoise3DJitter = original.atomSelectionWorleyNoise3DJitter
    self.atomSelectionScaling = original.atomSelectionScaling
    self.selectionIntensity = original.selectionIntensity
    
    self.atomHue = original.atomHue
    self.atomSaturation = original.atomSaturation
    self.atomValue = original.atomValue
    self.atomScaleFactor = original.atomScaleFactor
    
    self.atomAmbientOcclusion = original.atomAmbientOcclusion
    self.atomAmbientOcclusionPatchNumber = original.atomAmbientOcclusionPatchNumber
    self.atomAmbientOcclusionTextureSize = original.atomAmbientOcclusionTextureSize
    self.atomAmbientOcclusionPatchSize = original.atomAmbientOcclusionPatchSize
    self.atomCacheAmbientOcclusionTexture = original.atomCacheAmbientOcclusionTexture
    
    self.atomHDR = original.atomHDR
    self.atomHDRExposure = original.atomHDRExposure
    self.atomHDRBloomLevel = original.atomHDRBloomLevel
    
    self.atomAmbientColor = original.atomAmbientColor
    self.atomDiffuseColor = original.atomDiffuseColor
    self.atomSpecularColor = original.atomSpecularColor
    self.atomAmbientIntensity = original.atomAmbientIntensity
    self.atomDiffuseIntensity = original.atomDiffuseIntensity
    self.atomSpecularIntensity = original.atomSpecularIntensity
    self.atomShininess = original.atomShininess
    
    
    // bonds
    self.bonds = SKBondSetController()
    
    self.drawBonds = original.drawBonds
    
    self.bondScaleFactor = original.bondScaleFactor
    self.bondColorMode = original.bondColorMode
    
    self.bondAmbientColor = original.bondAmbientColor
    self.bondDiffuseColor = original.bondDiffuseColor
    self.bondSpecularColor = original.bondSpecularColor
    self.bondAmbientIntensity = original.bondAmbientIntensity
    self.bondDiffuseIntensity = original.bondDiffuseIntensity
    self.bondSpecularIntensity = original.bondSpecularIntensity
    self.bondShininess = original.bondShininess

    self.bondHDR = original.bondHDR
    self.bondHDRExposure = original.bondHDRExposure
    self.bondHDRBloomLevel = original.bondHDRBloomLevel
    
    self.bondHue = original.bondHue
    self.bondSaturation = original.bondSaturation
    self.bondValue = original.bondValue
    
    self.bondAmbientOcclusion = original.bondAmbientOcclusion
    
    // text properties
    self.atomTextType = original.atomTextType
    self.atomTextFont = original.atomTextFont
    self.atomTextScaling = original.atomTextScaling
    self.atomTextColor = original.atomTextColor
    self.atomTextGlowColor = original.atomTextGlowColor
    self.atomTextStyle = original.atomTextStyle
    self.atomTextEffect = original.atomTextEffect
    self.atomTextAlignment = original.atomTextAlignment
    self.atomTextOffset = original.atomTextOffset
    
    // unit cell
    self.drawUnitCell = original.drawUnitCell
    self.unitCellScaleFactor = original.unitCellScaleFactor
    self.unitCellDiffuseColor = original.unitCellDiffuseColor
    self.unitCellDiffuseIntensity = original.unitCellDiffuseIntensity
    
    // adsorption surface
    self.frameworkProbeMolecule = original.frameworkProbeMolecule

    self.drawAdsorptionSurface = original.drawAdsorptionSurface
    self.adsorptionSurfaceOpacity = original.adsorptionSurfaceOpacity
    self.adsorptionSurfaceIsoValue = original.adsorptionSurfaceIsoValue
    
    self.adsorptionSurfaceSize = original.adsorptionSurfaceSize
    self.adsorptionSurfaceNumberOfTriangles = original.adsorptionSurfaceNumberOfTriangles
    
    self.adsorptionSurfaceProbeMolecule = original.adsorptionSurfaceProbeMolecule
    
    self.adsorptionSurfaceFrontSideHDR = original.adsorptionSurfaceFrontSideHDR
    self.adsorptionSurfaceFrontSideHDRExposure = original.adsorptionSurfaceFrontSideHDRExposure
    self.adsorptionSurfaceFrontSideAmbientColor = original.adsorptionSurfaceFrontSideAmbientColor
    self.adsorptionSurfaceFrontSideDiffuseColor = original.adsorptionSurfaceFrontSideDiffuseColor
    self.adsorptionSurfaceFrontSideSpecularColor = original.adsorptionSurfaceFrontSideSpecularColor
    self.adsorptionSurfaceFrontSideDiffuseIntensity = original.adsorptionSurfaceFrontSideDiffuseIntensity
    self.adsorptionSurfaceFrontSideAmbientIntensity = original.adsorptionSurfaceFrontSideAmbientIntensity
    self.adsorptionSurfaceFrontSideSpecularIntensity = original.adsorptionSurfaceFrontSideSpecularIntensity
    self.adsorptionSurfaceFrontSideShininess = original.adsorptionSurfaceFrontSideShininess
    
    self.adsorptionSurfaceBackSideHDR = original.adsorptionSurfaceBackSideHDR
    self.adsorptionSurfaceBackSideHDRExposure = original.adsorptionSurfaceBackSideHDRExposure
    self.adsorptionSurfaceBackSideAmbientColor = original.adsorptionSurfaceBackSideAmbientColor
    self.adsorptionSurfaceBackSideDiffuseColor = original.adsorptionSurfaceBackSideDiffuseColor
    self.adsorptionSurfaceBackSideSpecularColor = original.adsorptionSurfaceBackSideSpecularColor
    self.adsorptionSurfaceBackSideDiffuseIntensity = original.adsorptionSurfaceBackSideDiffuseIntensity
    self.adsorptionSurfaceBackSideAmbientIntensity = original.adsorptionSurfaceBackSideAmbientIntensity
    self.adsorptionSurfaceBackSideSpecularIntensity = original.adsorptionSurfaceBackSideSpecularIntensity
    self.adsorptionSurfaceBackSideShininess = original.adsorptionSurfaceBackSideShininess
    

    self.creationDate = original.creationDate
    self.creationTemperature = original.creationTemperature
    self.creationTemperatureScale = original.creationTemperatureScale
    self.creationPressure = original.creationPressure
    self.creationPressureScale = original.creationPressureScale
    self.creationMethod = original.creationMethod
    self.creationUnitCellRelaxationMethod = original.creationUnitCellRelaxationMethod
    self.creationAtomicPositionsSoftwarePackage = original.creationAtomicPositionsSoftwarePackage
    self.creationAtomicPositionsIonsRelaxationAlgorithm = original.creationAtomicPositionsIonsRelaxationAlgorithm
    self.creationAtomicPositionsIonsRelaxationCheck = original.creationAtomicPositionsIonsRelaxationCheck
    self.creationAtomicPositionsForcefield = original.creationAtomicPositionsForcefield
    self.creationAtomicPositionsForcefieldDetails = original.creationAtomicPositionsForcefieldDetails
    self.creationAtomicChargesSoftwarePackage = original.creationAtomicChargesSoftwarePackage
    self.creationAtomicChargesAlgorithms = original.creationAtomicChargesAlgorithms
    self.creationAtomicChargesForcefield = original.creationAtomicChargesForcefield
    self.creationAtomicChargesForcefieldDetails = original.creationAtomicChargesForcefieldDetails
    
    self.chemicalFormulaMoiety = original.chemicalFormulaMoiety
    self.chemicalFormulaSum = original.chemicalFormulaSum
    self.chemicalNameSystematic = original.chemicalNameSystematic
    self.cellFormulaUnitsZ = original.cellFormulaUnitsZ
    
    
    self.citationArticleTitle = original.citationArticleTitle
    self.citationJournalTitle = original.citationJournalTitle
    self.citationAuthors = original.citationAuthors
    self.citationJournalVolume = original.citationJournalVolume
    self.citationJournalNumber = original.citationJournalNumber
    self.citationJournalPageNumbers = original.citationJournalPageNumbers
    self.citationDOI = original.citationDOI
    self.citationPublicationDate = original.citationPublicationDate
    self.citationDatebaseCodes = original.citationDatebaseCodes
    
    self.experimentalMeasurementRadiation = original.experimentalMeasurementRadiation
    self.experimentalMeasurementWaveLength = original.experimentalMeasurementWaveLength
    self.experimentalMeasurementThetaMin = original.experimentalMeasurementThetaMin
    self.experimentalMeasurementThetaMax = original.experimentalMeasurementThetaMax
    self.experimentalMeasurementIndexLimitsHmin = original.experimentalMeasurementIndexLimitsHmin
    self.experimentalMeasurementIndexLimitsHmax = original.experimentalMeasurementIndexLimitsHmax
    self.experimentalMeasurementIndexLimitsKmin = original.experimentalMeasurementIndexLimitsKmin
    self.experimentalMeasurementIndexLimitsKmax = original.experimentalMeasurementIndexLimitsKmax
    self.experimentalMeasurementIndexLimitsLmin = original.experimentalMeasurementIndexLimitsLmin
    self.experimentalMeasurementIndexLimitsLmax = original.experimentalMeasurementIndexLimitsLmax
    self.experimentalMeasurementNumberOfSymmetryIndependentReflections = original.experimentalMeasurementNumberOfSymmetryIndependentReflections
    self.experimentalMeasurementSoftware = original.experimentalMeasurementSoftware
    self.experimentalMeasurementRefinementDetails = original.experimentalMeasurementRefinementDetails
    self.experimentalMeasurementGoodnessOfFit = original.experimentalMeasurementGoodnessOfFit
    self.experimentalMeasurementRFactorGt = original.experimentalMeasurementRFactorGt
    self.experimentalMeasurementRFactorAll = original.experimentalMeasurementRFactorAll
    
    self.setRepresentationStyle(style: self.atomRepresentationStyle)
  }
  
  public required init(clone: Structure)
  {
    super.init()
    
    self.displayName = clone.displayName
    
    self.origin = clone.origin
    self.scaling = clone.scaling
    self.orientation = clone.orientation
    self.rotationDelta = clone.rotationDelta
    self.periodic = clone.periodic
    self.isVisible = clone.isVisible
    self.cell = clone.cell
    self.minimumGridEnergyValue = clone.minimumGridEnergyValue
    self.spaceGroup = clone.spaceGroup
    
    self.selectionCOMTranslation = clone.selectionCOMTranslation
    self.selectionRotationIndex = clone.selectionRotationIndex
    self.selectionBodyFixedBasis = clone.selectionBodyFixedBasis
    
    self.structureType = clone.structureType
    self.structureMaterialType = clone.structureMaterialType
    self.structureMass = clone.structureMass
    self.structureDensity = clone.structureDensity
    self.structureHeliumVoidFraction = clone.structureHeliumVoidFraction
    self.structureSpecificVolume = clone.structureSpecificVolume
    self.structureAccessiblePoreVolume = clone.structureAccessiblePoreVolume
    self.structureVolumetricNitrogenSurfaceArea = clone.structureVolumetricNitrogenSurfaceArea
    self.structureGravimetricNitrogenSurfaceArea = clone.structureGravimetricNitrogenSurfaceArea
    self.structureNumberOfChannelSystems = clone.structureNumberOfChannelSystems
    self.structureNumberOfInaccessiblePockets = clone.structureNumberOfInaccessiblePockets
    self.structureDimensionalityOfPoreSystem = clone.structureDimensionalityOfPoreSystem
    self.structureLargestCavityDiameter = clone.structureLargestCavityDiameter
    self.structureRestrictingPoreLimitingDiameter = clone.structureRestrictingPoreLimitingDiameter
    self.structureLargestCavityDiameterAlongAViablePath = clone.structureLargestCavityDiameterAlongAViablePath
    
    
    self.authorFirstName = clone.authorFirstName
    self.authorMiddleName = clone.authorMiddleName
    self.authorLastName = clone.authorLastName
    self.authorOrchidID = clone.authorOrchidID
    self.authorResearcherID = clone.authorResearcherID
    self.authorAffiliationUniversityName = clone.authorAffiliationUniversityName
    self.authorAffiliationFacultyName = clone.authorAffiliationFacultyName
    self.authorAffiliationInstituteName = clone.authorAffiliationInstituteName
    self.authorAffiliationCityName = clone.authorAffiliationCityName
    self.authorAffiliationCountryName = clone.authorAffiliationCountryName
    
    // primitive properties
    self.primitiveTransformationMatrix = clone.primitiveTransformationMatrix
    self.primitiveOrientation = clone.primitiveOrientation
    self.primitiveRotationDelta = clone.primitiveRotationDelta
    
    self.primitiveOpacity = clone.primitiveOpacity
    self.primitiveIsCapped = clone.primitiveIsCapped
    self.primitiveIsFractional = clone.primitiveIsFractional
    self.primitiveNumberOfSides = clone.primitiveNumberOfSides
    self.primitiveThickness = clone.primitiveThickness
    
    self.primitiveFrontSideHDR = clone.primitiveFrontSideHDR
    self.primitiveFrontSideHDRExposure = clone.primitiveFrontSideHDRExposure
    self.primitiveFrontSideAmbientColor = clone.primitiveFrontSideAmbientColor
    self.primitiveFrontSideDiffuseColor = clone.primitiveFrontSideDiffuseColor
    self.primitiveFrontSideSpecularColor = clone.primitiveFrontSideSpecularColor
    self.primitiveFrontSideAmbientIntensity = clone.primitiveFrontSideAmbientIntensity
    self.primitiveFrontSideDiffuseIntensity = clone.primitiveFrontSideDiffuseIntensity
    self.primitiveFrontSideSpecularIntensity = clone.primitiveFrontSideSpecularIntensity
    self.primitiveFrontSideShininess = clone.primitiveFrontSideShininess
    
    self.primitiveBackSideHDR = clone.primitiveBackSideHDR
    self.primitiveBackSideHDRExposure = clone.primitiveBackSideHDRExposure
    self.primitiveBackSideAmbientColor = clone.primitiveBackSideAmbientColor
    self.primitiveBackSideDiffuseColor = clone.primitiveBackSideDiffuseColor
    self.primitiveBackSideSpecularColor = clone.primitiveBackSideSpecularColor
    self.primitiveBackSideAmbientIntensity = clone.primitiveBackSideAmbientIntensity
    self.primitiveBackSideDiffuseIntensity = clone.primitiveBackSideDiffuseIntensity
    self.primitiveBackSideSpecularIntensity = clone.primitiveBackSideSpecularIntensity
    self.primitiveBackSideShininess = clone.primitiveBackSideShininess
    
    // atoms
    self.drawAtoms = clone.drawAtoms
    
    self.atomRepresentationType = clone.atomRepresentationType
    self.atomRepresentationStyle = clone.atomRepresentationStyle
    self.atomForceFieldIdentifier = clone.atomForceFieldIdentifier
    self.atomForceFieldOrder = clone.atomForceFieldOrder
    self.atomColorSchemeIdentifier = clone.atomColorSchemeIdentifier
    self.atomColorOrder = clone.atomColorOrder
    
    self.atomSelectionStyle = clone.atomSelectionStyle
    self.atomSelectionStripesDensity = clone.atomSelectionStripesDensity
    self.atomSelectionStripesFrequency = clone.atomSelectionStripesFrequency
    self.atomSelectionWorleyNoise3DFrequency = clone.atomSelectionWorleyNoise3DFrequency
    self.atomSelectionWorleyNoise3DJitter = clone.atomSelectionWorleyNoise3DJitter
    self.atomSelectionScaling = clone.atomSelectionScaling
    self.selectionIntensity = clone.selectionIntensity
    
    self.atomHue = clone.atomHue
    self.atomSaturation = clone.atomSaturation
    self.atomValue = clone.atomValue
    self.atomScaleFactor = clone.atomScaleFactor
    
    self.atomAmbientOcclusion = clone.atomAmbientOcclusion
    self.atomAmbientOcclusionPatchNumber = clone.atomAmbientOcclusionPatchNumber
    self.atomAmbientOcclusionTextureSize = clone.atomAmbientOcclusionTextureSize
    self.atomAmbientOcclusionPatchSize = clone.atomAmbientOcclusionPatchSize
    self.atomCacheAmbientOcclusionTexture = clone.atomCacheAmbientOcclusionTexture
    
    self.atomHDR = clone.atomHDR
    self.atomHDRExposure = clone.atomHDRExposure
    self.atomHDRBloomLevel = clone.atomHDRBloomLevel
    
    self.atomAmbientColor = clone.atomAmbientColor
    self.atomDiffuseColor = clone.atomDiffuseColor
    self.atomSpecularColor = clone.atomSpecularColor
    self.atomAmbientIntensity = clone.atomAmbientIntensity
    self.atomDiffuseIntensity = clone.atomDiffuseIntensity
    self.atomSpecularIntensity = clone.atomSpecularIntensity
    self.atomShininess = clone.atomShininess
    
    // bonds
    self.drawBonds = clone.drawBonds
    
    self.bondScaleFactor = clone.bondScaleFactor
    self.bondColorMode = clone.bondColorMode
    
    self.bondAmbientColor = clone.bondAmbientColor
    self.bondDiffuseColor = clone.bondDiffuseColor
    self.bondSpecularColor = clone.bondSpecularColor
    self.bondAmbientIntensity = clone.bondAmbientIntensity
    self.bondDiffuseIntensity = clone.bondDiffuseIntensity
    self.bondSpecularIntensity = clone.bondSpecularIntensity
    self.bondShininess = clone.bondShininess

    self.bondHDR = clone.bondHDR
    self.bondHDRExposure = clone.bondHDRExposure
    self.bondHDRBloomLevel = clone.bondHDRBloomLevel
    
    self.bondHue = clone.bondHue
    self.bondSaturation = clone.bondSaturation
    self.bondValue = clone.bondValue
    
    self.bondAmbientOcclusion = clone.bondAmbientOcclusion
    
    // text properties
    self.atomTextType = clone.atomTextType
    self.atomTextFont = clone.atomTextFont
    self.atomTextScaling = clone.atomTextScaling
    self.atomTextColor = clone.atomTextColor
    self.atomTextGlowColor = clone.atomTextGlowColor
    self.atomTextStyle = clone.atomTextStyle
    self.atomTextEffect = clone.atomTextEffect
    self.atomTextAlignment = clone.atomTextAlignment
    self.atomTextOffset = clone.atomTextOffset
    
    // unit cell
    self.drawUnitCell = clone.drawUnitCell
    self.unitCellScaleFactor = clone.unitCellScaleFactor
    self.unitCellDiffuseColor = clone.unitCellDiffuseColor
    self.unitCellDiffuseIntensity = clone.unitCellDiffuseIntensity
    
    // adsorption surface
    self.frameworkProbeMolecule = clone.frameworkProbeMolecule

    self.drawAdsorptionSurface = clone.drawAdsorptionSurface
    self.adsorptionSurfaceOpacity = clone.adsorptionSurfaceOpacity
    self.adsorptionSurfaceIsoValue = clone.adsorptionSurfaceIsoValue
    
    self.adsorptionSurfaceSize = clone.adsorptionSurfaceSize
    self.adsorptionSurfaceNumberOfTriangles = clone.adsorptionSurfaceNumberOfTriangles
    
    self.adsorptionSurfaceProbeMolecule = clone.adsorptionSurfaceProbeMolecule
    
    self.adsorptionSurfaceFrontSideHDR = clone.adsorptionSurfaceFrontSideHDR
    self.adsorptionSurfaceFrontSideHDRExposure = clone.adsorptionSurfaceFrontSideHDRExposure
    self.adsorptionSurfaceFrontSideAmbientColor = clone.adsorptionSurfaceFrontSideAmbientColor
    self.adsorptionSurfaceFrontSideDiffuseColor = clone.adsorptionSurfaceFrontSideDiffuseColor
    self.adsorptionSurfaceFrontSideSpecularColor = clone.adsorptionSurfaceFrontSideSpecularColor
    self.adsorptionSurfaceFrontSideDiffuseIntensity = clone.adsorptionSurfaceFrontSideDiffuseIntensity
    self.adsorptionSurfaceFrontSideAmbientIntensity = clone.adsorptionSurfaceFrontSideAmbientIntensity
    self.adsorptionSurfaceFrontSideSpecularIntensity = clone.adsorptionSurfaceFrontSideSpecularIntensity
    self.adsorptionSurfaceFrontSideShininess = clone.adsorptionSurfaceFrontSideShininess
    
    self.adsorptionSurfaceBackSideHDR = clone.adsorptionSurfaceBackSideHDR
    self.adsorptionSurfaceBackSideHDRExposure = clone.adsorptionSurfaceBackSideHDRExposure
    self.adsorptionSurfaceBackSideAmbientColor = clone.adsorptionSurfaceBackSideAmbientColor
    self.adsorptionSurfaceBackSideDiffuseColor = clone.adsorptionSurfaceBackSideDiffuseColor
    self.adsorptionSurfaceBackSideSpecularColor = clone.adsorptionSurfaceBackSideSpecularColor
    self.adsorptionSurfaceBackSideDiffuseIntensity = clone.adsorptionSurfaceBackSideDiffuseIntensity
    self.adsorptionSurfaceBackSideAmbientIntensity = clone.adsorptionSurfaceBackSideAmbientIntensity
    self.adsorptionSurfaceBackSideSpecularIntensity = clone.adsorptionSurfaceBackSideSpecularIntensity
    self.adsorptionSurfaceBackSideShininess = clone.adsorptionSurfaceBackSideShininess
    

    self.creationDate = clone.creationDate
    self.creationTemperature = clone.creationTemperature
    self.creationTemperatureScale = clone.creationTemperatureScale
    self.creationPressure = clone.creationPressure
    self.creationPressureScale = clone.creationPressureScale
    self.creationMethod = clone.creationMethod
    self.creationUnitCellRelaxationMethod = clone.creationUnitCellRelaxationMethod
    self.creationAtomicPositionsSoftwarePackage = clone.creationAtomicPositionsSoftwarePackage
    self.creationAtomicPositionsIonsRelaxationAlgorithm = clone.creationAtomicPositionsIonsRelaxationAlgorithm
    self.creationAtomicPositionsIonsRelaxationCheck = clone.creationAtomicPositionsIonsRelaxationCheck
    self.creationAtomicPositionsForcefield = clone.creationAtomicPositionsForcefield
    self.creationAtomicPositionsForcefieldDetails = clone.creationAtomicPositionsForcefieldDetails
    self.creationAtomicChargesSoftwarePackage = clone.creationAtomicChargesSoftwarePackage
    self.creationAtomicChargesAlgorithms = clone.creationAtomicChargesAlgorithms
    self.creationAtomicChargesForcefield = clone.creationAtomicChargesForcefield
    self.creationAtomicChargesForcefieldDetails = clone.creationAtomicChargesForcefieldDetails
    
    self.chemicalFormulaMoiety = clone.chemicalFormulaMoiety
    self.chemicalFormulaSum = clone.chemicalFormulaSum
    self.chemicalNameSystematic = clone.chemicalNameSystematic
    self.cellFormulaUnitsZ = clone.cellFormulaUnitsZ
    
    
    self.citationArticleTitle = clone.citationArticleTitle
    self.citationJournalTitle = clone.citationJournalTitle
    self.citationAuthors = clone.citationAuthors
    self.citationJournalVolume = clone.citationJournalVolume
    self.citationJournalNumber = clone.citationJournalNumber
    self.citationJournalPageNumbers = clone.citationJournalPageNumbers
    self.citationDOI = clone.citationDOI
    self.citationPublicationDate = clone.citationPublicationDate
    self.citationDatebaseCodes = clone.citationDatebaseCodes
    
    self.experimentalMeasurementRadiation = clone.experimentalMeasurementRadiation
    self.experimentalMeasurementWaveLength = clone.experimentalMeasurementWaveLength
    self.experimentalMeasurementThetaMin = clone.experimentalMeasurementThetaMin
    self.experimentalMeasurementThetaMax = clone.experimentalMeasurementThetaMax
    self.experimentalMeasurementIndexLimitsHmin = clone.experimentalMeasurementIndexLimitsHmin
    self.experimentalMeasurementIndexLimitsHmax = clone.experimentalMeasurementIndexLimitsHmax
    self.experimentalMeasurementIndexLimitsKmin = clone.experimentalMeasurementIndexLimitsKmin
    self.experimentalMeasurementIndexLimitsKmax = clone.experimentalMeasurementIndexLimitsKmax
    self.experimentalMeasurementIndexLimitsLmin = clone.experimentalMeasurementIndexLimitsLmin
    self.experimentalMeasurementIndexLimitsLmax = clone.experimentalMeasurementIndexLimitsLmax
    self.experimentalMeasurementNumberOfSymmetryIndependentReflections = clone.experimentalMeasurementNumberOfSymmetryIndependentReflections
    self.experimentalMeasurementSoftware = clone.experimentalMeasurementSoftware
    self.experimentalMeasurementRefinementDetails = clone.experimentalMeasurementRefinementDetails
    self.experimentalMeasurementGoodnessOfFit = clone.experimentalMeasurementGoodnessOfFit
    self.experimentalMeasurementRFactorGt = clone.experimentalMeasurementRFactorGt
    self.experimentalMeasurementRFactorAll = clone.experimentalMeasurementRFactorAll
    
    
    // clone atoms and bonds
    clone.tag(atoms: clone.atoms)
    let binaryEncoder: BinaryEncoder = BinaryEncoder()
    binaryEncoder.encode(clone.atoms)
    let atomData: Data = Data(binaryEncoder.data)
    
    do
    {
      self.atoms = try BinaryDecoder(data: [UInt8](atomData)).decode(SKAtomTreeController.self)
      // set the 'bonds'-array of the atoms, since they are empty for a structure with symmetry
      let atomTreeNodes: [SKAtomTreeNode] = self.atoms.flattenedLeafNodes()
      let atomCopies: [SKAtomCopy] = atomTreeNodes.compactMap{$0.representedObject}.flatMap{$0.copies}
      
      //update tags
      let tags: Set<Int> = Set(clone.atoms.selectedTreeNodes.map{$0.representedObject.tag})
      
      // update selection
      self.atoms.selectedTreeNodes = Set(atomTreeNodes.filter{tags.contains($0.representedObject.tag)})
      
      for atomCopy in atomCopies
      {
        atomCopy.bonds = []
      }
      self.bonds.arrangedObjects = []
      
      // recreated the bonds from the tags
      for bond in clone.bonds.arrangedObjects
      {
        let newBond: SKBondNode = SKBondNode(atom1: atomCopies[bond.atom1.tag], atom2: atomCopies[bond.atom2.tag], boundaryType: bond.boundaryType)
        self.bonds.arrangedObjects.insert(newBond)
      }
      
      for bond in self.bonds.arrangedObjects
      {
        // make the list of bonds the atoms are involved in
        bond.atom1.bonds.insert(bond)
        bond.atom2.bonds.insert(bond)
      }
    }
    catch
    {
      debugPrint("Error")
    }
    
    self.setRepresentationStyle(style: self.atomRepresentationStyle)
 
  }
  
  // MARK: -
  // MARK: AtomVisualAppearanceViewer protocol redirected functions
  
  public func getRepresentationColorScheme() -> String?
  {
    return self.atomColorSchemeIdentifier
  }
  
  public func setRepresentationColorScheme(colorSet: SKColorSet)
  {
    let asymmetricAtoms: [SKAsymmetricAtom] = atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    setRepresentationColorScheme(colorSet: colorSet, for: asymmetricAtoms)
  }

  public func setRepresentationColorScheme(colorSet: SKColorSet, for asymmetricAtoms: [SKAsymmetricAtom])
  {
    for asymmetricAtom in asymmetricAtoms
    {
      let uniqueForceFieldName: String = asymmetricAtom.uniqueForceFieldName
      let chemicalElement: String = PredefinedElements.sharedInstance.elementSet[asymmetricAtom.elementIdentifier].chemicalSymbol
        
      switch(self.atomColorOrder)
      {
      case .elementOnly:
        asymmetricAtom.color = colorSet[chemicalElement] ?? NSColor.black
      case .forceFieldOnly:
        asymmetricAtom.color = colorSet[uniqueForceFieldName] ?? NSColor.black
      case .forceFieldFirst:
        asymmetricAtom.color = colorSet[uniqueForceFieldName] ?? colorSet[chemicalElement] ?? NSColor.black
      }
    }
  }

  
  public func setRepresentationColorScheme(scheme: String?, colorSets: SKColorSets)
  {
    if let scheme = scheme
    {
      self.atomColorSchemeIdentifier = scheme
      
      if let colorSet: SKColorSet = colorSets[scheme]
      {
        setRepresentationColorScheme(colorSet: colorSet)
      }
    }
  }
  
  public func setRepresentationColorScheme(colorSets: SKColorSets, for asymmetricAtoms: [SKAsymmetricAtom])
  {
    if let colorSet: SKColorSet = colorSets[self.atomColorSchemeIdentifier]
    {
      setRepresentationColorScheme(colorSet: colorSet, for: asymmetricAtoms)
    }
  }
  
  public func getRepresentationColorOrder() -> SKColorSets.ColorOrder?
  {
      return self.atomColorOrder
  }
  
  public func setRepresentationColorOrder(order: SKColorSets.ColorOrder?, colorSets: SKColorSets)
  {
    if let order = order
    {
      self.atomColorOrder = order
      
      let asymmetricAtoms: [SKAsymmetricAtom] = atoms.flattenedLeafNodes().compactMap{$0.representedObject}
      for asymmetricAtom in asymmetricAtoms
      {
        if let colorSet: SKColorSet = colorSets[self.atomColorSchemeIdentifier]
        {
          let uniqueForceFieldName: String = asymmetricAtom.uniqueForceFieldName
          let chemicalElement: String = PredefinedElements.sharedInstance.elementSet[asymmetricAtom.elementIdentifier].chemicalSymbol
        
          switch(self.atomColorOrder)
          {
          case .elementOnly:
            asymmetricAtom.color = colorSet[chemicalElement] ?? NSColor.black
          case .forceFieldOnly:
            asymmetricAtom.color = colorSet[uniqueForceFieldName] ?? NSColor.black
          case .forceFieldFirst:
            asymmetricAtom.color = colorSet[uniqueForceFieldName] ?? colorSet[chemicalElement] ?? NSColor.black
          }
        }
      }
    }
  }
  
  
  
  public func unknownForceFieldNames(forceField: String, forceFieldSets: SKForceFieldSets) -> [String]
  {
    if let forceFieldSet: SKForceFieldSet = forceFieldSets[forceField]
    {
      let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    
      return asymmetricAtoms.map{$0.uniqueForceFieldName}.filter{
      forceFieldSet[$0] != nil}
    }
    return []
  }
  
  public func getRepresentationForceField() -> String?
  {
    return self.atomForceFieldIdentifier
  }
  
  public func setRepresentationForceField(forceField: String?, forceFieldSet: SKForceFieldSet)
  {
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    
    self.setRepresentationForceField(forceField: forceField, forceFieldSet: forceFieldSet, for: asymmetricAtoms)
  }
  
  public func setRepresentationForceField(forceField: String?, forceFieldSet: SKForceFieldSet, for asymmetricAtoms: [SKAsymmetricAtom])
  {
    switch(self.atomForceFieldOrder)
    {
    case .elementOnly:
      asymmetricAtoms.forEach{atom in
        atom.potentialParameters = forceFieldSet[PredefinedElements.sharedInstance.elementSet[atom.elementIdentifier].chemicalSymbol]?.potentialParameters ?? SIMD2<Double>(0.0,0.0)
        let atomicNumber: Int = atom.elementIdentifier
        let elementString: String = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
        atom.bondDistanceCriteria = forceFieldSet[elementString]?.userDefinedRadius ?? 0.0
      }
    case .forceFieldOnly:
      asymmetricAtoms.forEach{atom in
        atom.potentialParameters = forceFieldSet[atom.uniqueForceFieldName]?.potentialParameters ?? SIMD2<Double>(0.0,0.0)
        atom.bondDistanceCriteria = forceFieldSet[atom.uniqueForceFieldName]?.userDefinedRadius ?? 1.0
      }
    case .forceFieldFirst:
      asymmetricAtoms.forEach{atom in
        atom.potentialParameters = forceFieldSet[atom.uniqueForceFieldName]?.potentialParameters ?? forceFieldSet[PredefinedElements.sharedInstance.elementSet[atom.elementIdentifier].chemicalSymbol]?.potentialParameters ?? SIMD2<Double>(0.0,0.0)
        let atomicNumber: Int = atom.elementIdentifier
        let elementString: String = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
        atom.bondDistanceCriteria = forceFieldSet[atom.uniqueForceFieldName]?.userDefinedRadius ?? forceFieldSet[elementString]?.userDefinedRadius ?? 0.0
      }
    }
    
    for asymmetricAtom in asymmetricAtoms
    {
      let elementId: Int = asymmetricAtom.elementIdentifier
      switch(self.atomRepresentationType)
      {
      case .vdw:
        asymmetricAtom.drawRadius = PredefinedElements.sharedInstance.elementSet[elementId].VDWRadius
      case .sticks_and_balls:
        asymmetricAtom.drawRadius = PredefinedElements.sharedInstance.elementSet[elementId].covalentRadius
      case .unity:
        asymmetricAtom.drawRadius = bondScaleFactor
      }
    }
  }
  
  
  public func setRepresentationForceField(forceField: String?, forceFieldSets: SKForceFieldSets)
  {
    if let forceField = forceField
    {
      self.atomForceFieldIdentifier = forceField
      
      if let forceFieldSet: SKForceFieldSet = forceFieldSets[self.atomForceFieldIdentifier]
      {
        setRepresentationForceField(forceField: forceField, forceFieldSet: forceFieldSet)
      }
    }
  }
  
  public func setRepresentationForceField(forceField: String?, forceFieldSets: SKForceFieldSets, for asymmetricAtoms: [SKAsymmetricAtom])
  {
    if let forceField = forceField
    {
      self.atomForceFieldIdentifier = forceField
      
      if let forceFieldSet: SKForceFieldSet = forceFieldSets[self.atomForceFieldIdentifier]
      {
        setRepresentationForceField(forceField: forceField, forceFieldSet: forceFieldSet, for: asymmetricAtoms)
      }
    }
  }
  
  public func getRepresentationForceFieldOrder() -> SKForceFieldSets.ForceFieldOrder?
  {
    return self.atomForceFieldOrder
  }
  
  public func setRepresentationForceFieldOrder(order: SKForceFieldSets.ForceFieldOrder?, forceFieldSet: SKForceFieldSet)
  {
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
        
    switch(self.atomForceFieldOrder)
    {
      case .elementOnly:
        asymmetricAtoms.forEach{$0.potentialParameters = forceFieldSet[PredefinedElements.sharedInstance.elementSet[$0.elementIdentifier].chemicalSymbol]?.potentialParameters ?? SIMD2<Double>(0.0,0.0)}
      case .forceFieldOnly:
        asymmetricAtoms.forEach{$0.potentialParameters = forceFieldSet[$0.uniqueForceFieldName]?.potentialParameters ?? SIMD2<Double>(0.0,0.0)}
      case .forceFieldFirst:
        asymmetricAtoms.forEach{$0.potentialParameters = forceFieldSet[$0.uniqueForceFieldName]?.potentialParameters ?? forceFieldSet[PredefinedElements.sharedInstance.elementSet[$0.elementIdentifier].chemicalSymbol]?.potentialParameters ?? SIMD2<Double>(0.0,0.0)}
    }
  }
  
  
  public func setRepresentationForceFieldOrder(order: SKForceFieldSets.ForceFieldOrder?, forceFieldSets: SKForceFieldSets)
  {
    if let order = order
    {
      self.atomForceFieldOrder = order
      
      if let forceFieldSet: SKForceFieldSet = forceFieldSets[self.atomForceFieldIdentifier]
      {
        setRepresentationForceFieldOrder(order: order, forceFieldSet: forceFieldSet)
      }
    }
  }
  
  public func getRepresentationStyle() -> Structure.RepresentationStyle?
  {
    return atomRepresentationStyle
  }
  
  public func setRepresentationStyle(style: Structure.RepresentationStyle?)
  {
    let asymmetricAtoms: [SKAsymmetricAtom] = atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    self.setRepresentationStyle(style: style, for: asymmetricAtoms)
  }
  
  public func setRepresentationStyle(style: Structure.RepresentationStyle?, for asymmetricAtoms: [SKAsymmetricAtom])
  {
    if let style = style
    {
      atomRepresentationStyle = style
      
      switch(atomRepresentationStyle)
      {
      case .custom:
        break
      case .default:
        drawAtoms = true
        atomScaleFactor = 0.7
        atomHue = 1.0
        atomSaturation = 1.0
        atomValue = 1.0
        atomAmbientColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        atomSpecularColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        atomHDR = true
        atomHDRExposure = 1.5
        atomAmbientOcclusion = false
        bondAmbientOcclusion = false
        atomAmbientIntensity = 0.2
        atomDiffuseIntensity = 1.0
        atomSpecularIntensity = 1.0
        atomShininess = 6.0
        
        atomForceFieldIdentifier = "Default"
        atomColorSchemeIdentifier = SKColorSets.ColorScheme.jmol.rawValue
        atomColorOrder = .elementOnly
        
        drawBonds = true
        bondColorMode = .uniform
        bondScaleFactor = 0.15
        bondAmbientColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        bondDiffuseColor = NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        bondSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        bondAmbientIntensity = 0.35
        bondDiffuseIntensity = 1.0
        bondSpecularIntensity = 1.0
        bondShininess = 4.0
        bondHDR = true
        bondHDRExposure = 1.5
        bondHDRBloomLevel = 1.0
        bondHue = 1.0
        bondSaturation = 1.0
        bondValue = 1.0
        bondAmbientOcclusion = false
        
        self.atomSelectionStyle = .WorleyNoise3D
        self.atomSelectionScaling = 1.2
        
        self.setRepresentationType(type: .sticks_and_balls)
      case .fancy:
        atomHue = 1.0
        atomScaleFactor = 1.0
        atomSaturation = 0.5
        atomValue = 1.0
        
        atomAmbientColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        atomSpecularColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        drawAtoms = true
        drawBonds = false
        atomHDR = false
        
        atomAmbientOcclusion = true
        bondAmbientOcclusion = false
        
        atomAmbientIntensity = 1.0
        atomDiffuseIntensity = 0.0
        atomSpecularIntensity = 0.2
        atomShininess = 4.0
        
        atomScaleFactor = 1.0
        
        atomForceFieldIdentifier = "Default"
        atomColorSchemeIdentifier = SKColorSets.ColorScheme.rasmol.rawValue
        atomColorOrder = .elementOnly
        
        self.atomSelectionStyle = .WorleyNoise3D
        self.atomSelectionScaling = 1.0
        
        self.setRepresentationType(type: .vdw)
      case .licorice:
        atomHue = 1.0
        atomSaturation = 1.0
        atomValue = 1.0
        atomAmbientColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        atomSpecularColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        atomAmbientIntensity = 0.1
        atomDiffuseIntensity = 1.0
        atomSpecularIntensity = 1.0
        atomShininess = 4.0
        drawAtoms = true
        atomHDR = true
        atomHDRBloomLevel = 1.0
        atomHDRExposure = 1.5
        atomScaleFactor = 1.0
        atomForceFieldIdentifier = "Default"
        atomColorSchemeIdentifier = SKColorSets.ColorScheme.jmol.rawValue
        atomColorOrder = .elementOnly
        atomAmbientOcclusion = false
        
        drawBonds = true
        bondColorMode = .split
        bondScaleFactor = 0.25
        bondAmbientColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        bondDiffuseColor = NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        bondSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        bondAmbientIntensity = 0.1
        bondDiffuseIntensity = 1.0
        bondSpecularIntensity = 1.0
        bondShininess = 4.0
        bondHDR = true
        bondHDRExposure = 1.5
        bondHDRBloomLevel = 1.0
        bondHue = 1.0
        bondSaturation = 1.0
        bondValue = 1.0
        bondAmbientOcclusion = false
        
        self.atomSelectionStyle = .WorleyNoise3D
        self.atomSelectionScaling = 1.5
        
        self.setRepresentationType(type: .unity)
      case .objects:
        atomAmbientColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        atomSpecularColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        atomAmbientIntensity = 0.1
        atomDiffuseIntensity = 0.6
        atomSpecularIntensity = 0.1
        atomShininess = 4.0
        drawAtoms = true
        atomScaleFactor = 1.0
        atomForceFieldIdentifier = "Default"
        atomColorSchemeIdentifier = SKColorSets.ColorScheme.jmol.rawValue
        atomColorOrder = .elementOnly
        atomAmbientOcclusion = false
        
        self.setRepresentationType(type: .unity)
      }
    }
    
    
    for asymmetricAtom in asymmetricAtoms
    {
      let elementId: Int = asymmetricAtom.elementIdentifier
      switch(self.atomRepresentationType)
      {
      case .vdw:
        asymmetricAtom.drawRadius = PredefinedElements.sharedInstance.elementSet[elementId].VDWRadius
      case .sticks_and_balls:
        asymmetricAtom.drawRadius = PredefinedElements.sharedInstance.elementSet[elementId].covalentRadius
      case .unity:
        asymmetricAtom.drawRadius = bondScaleFactor
      }
    }
  }
  
  public func setRepresentationStyle(style: Structure.RepresentationStyle?, colorSets: SKColorSets)
  {
    setRepresentationStyle(style: style)
    if let style = style
    {
      switch(style)
      {
      case .custom:
        break
      case .default:
        self.setRepresentationColorScheme(scheme: SKColorSets.ColorScheme.jmol.rawValue, colorSets: colorSets)
      case .fancy:
        self.setRepresentationColorScheme(scheme: SKColorSets.ColorScheme.rasmol.rawValue, colorSets: colorSets)
      case .licorice:
        self.setRepresentationColorScheme(scheme: SKColorSets.ColorScheme.jmol.rawValue, colorSets: colorSets)
      case .objects:
        self.setRepresentationColorScheme(scheme: SKColorSets.ColorScheme.jmol.rawValue, colorSets: colorSets)
      }
    }
  }
  
  public func recheckRepresentationStyle()
  {
    if drawAtoms == true &&
       (atomHue ==~ 1.0) &&
       (atomSaturation ==~ 1.0) &&
       (atomValue ==~ 1.0) &&
       ((atomAmbientColor.redComponent - 1.0) < 1e-3) &&
       ((atomAmbientColor.greenComponent - 1.0) < 1e-3) &&
       ((atomAmbientColor.blueComponent - 1.0) < 1e-3) &&
       ((atomAmbientColor.alphaComponent - 1.0) < 1e-3) &&
       ((atomSpecularColor.redComponent - 1.0) < 1e-3) &&
       ((atomSpecularColor.greenComponent - 1.0) < 1e-3) &&
       ((atomSpecularColor.blueComponent - 1.0) < 1e-3) &&
       ((atomSpecularColor.alphaComponent - 1.0) < 1e-3) &&
       atomHDR == true &&
       (atomHDRExposure ==~ 1.5) &&
       atomAmbientOcclusion == false &&
       (atomAmbientIntensity ==~ 0.2) &&
       (atomDiffuseIntensity ==~ 1.0) &&
       (atomSpecularIntensity ==~ 1.0) &&
       (atomShininess ==~ 6.0) &&
       (atomScaleFactor ==~ 0.7) &&
       atomRepresentationType == .sticks_and_balls &&
       atomForceFieldIdentifier == "Default" &&
       atomColorSchemeIdentifier == SKColorSets.ColorScheme.jmol.rawValue &&
       atomColorOrder == .elementOnly &&
       drawBonds == true &&
       bondColorMode == .uniform &&
       (bondScaleFactor ==~ 0.15) &&
       bondAmbientOcclusion == false &&
       bondHDR == true &&
       (bondHDRExposure ==~ 1.5) &&
      ((bondAmbientColor.redComponent - 1.0) < 1e-3) &&
      ((bondAmbientColor.greenComponent - 1.0) < 1e-3) &&
      ((bondAmbientColor.blueComponent - 1.0) < 1e-3) &&
      ((bondAmbientColor.alphaComponent - 1.0) < 1e-3) &&
      ((bondDiffuseColor.redComponent - 0.8) < 1e-3) &&
      ((bondDiffuseColor.greenComponent - 0.8) < 1e-3) &&
      ((bondDiffuseColor.blueComponent - 0.8) < 1e-3) &&
      ((bondDiffuseColor.alphaComponent - 1.0) < 1e-3) &&
      ((bondSpecularColor.redComponent - 1.0) < 1e-3) &&
      ((bondSpecularColor.greenComponent - 1.0) < 1e-3) &&
      ((bondSpecularColor.blueComponent - 1.0) < 1e-3) &&
      ((bondSpecularColor.alphaComponent - 1.0) < 1e-3) &&
       (bondAmbientIntensity ==~  0.35) &&
       (bondDiffuseIntensity ==~  1.0) &&
       (bondSpecularIntensity ==~  1.0) &&
       (bondShininess ==~  4.0) &&
       (bondHue ==~  1.0) &&
       (bondSaturation ==~  1.0) &&
       (bondValue ==~  1.0)  &&
      atomSelectionStyle == .WorleyNoise3D &&
      (atomSelectionScaling ==~ 1.2)
    {
      self.atomRepresentationStyle = .default
    }
    else if (atomHue ==~ 1.0) &&
       (atomSaturation ==~ 0.5) &&
       (atomValue ==~ 1.0) &&
       ((atomAmbientColor.redComponent - 1.0) < 1e-3) &&
       ((atomAmbientColor.greenComponent - 1.0) < 1e-3) &&
       ((atomAmbientColor.blueComponent - 1.0) < 1e-3) &&
       ((atomAmbientColor.alphaComponent - 1.0) < 1e-3) &&
       ((atomSpecularColor.redComponent - 1.0) < 1e-3) &&
       ((atomSpecularColor.greenComponent - 1.0) < 1e-3) &&
       ((atomSpecularColor.blueComponent - 1.0) < 1e-3) &&
       ((atomSpecularColor.alphaComponent - 1.0) < 1e-3) &&
       drawAtoms == true &&
       drawBonds == false &&
       atomHDR == false &&
       atomAmbientOcclusion == true &&
       bondAmbientOcclusion == false &&
       (atomAmbientIntensity ==~ 1.0) &&
       (atomDiffuseIntensity ==~ 0.0) &&
       (atomSpecularIntensity ==~ 0.2) &&
       (atomShininess ==~ 4.0) &&
       (atomScaleFactor ==~ 1.0) &&
       atomRepresentationType == .vdw &&
       atomForceFieldIdentifier == "Default" &&
       atomColorSchemeIdentifier == SKColorSets.ColorScheme.rasmol.rawValue &&
       atomColorOrder == .elementOnly &&
      atomSelectionStyle == .WorleyNoise3D &&
      (atomSelectionScaling ==~ 1.0)
    {
      self.atomRepresentationStyle = .fancy
    }
    else if drawAtoms == true &&
      (atomHue ==~ 1.0) &&
      (atomSaturation ==~ 1.0) &&
      (atomValue ==~ 1.0) &&
      atomRepresentationType == .unity &&
      atomForceFieldIdentifier == "Default" &&
      atomColorSchemeIdentifier == SKColorSets.ColorScheme.jmol.rawValue &&
      atomColorOrder == .elementOnly &&
      (atomScaleFactor ==~ 1.0) &&
      atomHDR == true &&
      (atomHDRExposure ==~ 1.5) &&
      atomAmbientOcclusion == false &&
      (atomAmbientIntensity ==~ 0.1) &&
      (atomDiffuseIntensity ==~ 1.0) &&
      (atomSpecularIntensity ==~ 1.0) &&
      (atomShininess ==~ 4.0) &&
      drawBonds == true &&
      bondColorMode == .split &&
      (bondScaleFactor ==~ 0.25) &&
      bondAmbientOcclusion == false &&
      bondHDR == true &&
      (bondHDRExposure ==~ 1.5) &&
      ((bondAmbientColor.redComponent - 1.0) < 1e-3) &&
      ((bondAmbientColor.greenComponent - 1.0) < 1e-3) &&
      ((bondAmbientColor.blueComponent - 1.0) < 1e-3) &&
      ((bondAmbientColor.alphaComponent - 1.0) < 1e-3) &&
      ((bondDiffuseColor.redComponent - 0.8) < 1e-3) &&
      ((bondDiffuseColor.greenComponent - 0.8) < 1e-3) &&
      ((bondDiffuseColor.blueComponent - 0.8) < 1e-3) &&
      ((bondDiffuseColor.alphaComponent - 1.0) < 1e-3) &&
      ((bondSpecularColor.redComponent - 1.0) < 1e-3) &&
      ((bondSpecularColor.greenComponent - 1.0) < 1e-3) &&
      ((bondSpecularColor.blueComponent - 1.0) < 1e-3) &&
      ((bondSpecularColor.alphaComponent - 1.0) < 1e-3) &&
      (bondAmbientIntensity ==~  0.1) &&
      (bondDiffuseIntensity ==~  1.0) &&
      (bondSpecularIntensity ==~  1.0) &&
      (bondShininess ==~  4.0) &&
      (bondHue ==~  1.0) &&
      (bondSaturation ==~  1.0) &&
      (bondValue ==~  1.0) &&
      atomSelectionStyle == .WorleyNoise3D &&
      (atomSelectionScaling ==~ 1.5)
    {
      self.atomRepresentationStyle = .licorice
    }
    else if drawAtoms == true &&
      atomRepresentationType == .unity &&
      atomForceFieldIdentifier == "Default" &&
      atomColorSchemeIdentifier == SKColorSets.ColorScheme.jmol.rawValue &&
      atomColorOrder == .elementOnly &&
      (atomScaleFactor ==~ 1.0) &&
      atomAmbientOcclusion == false &&
      (atomAmbientIntensity ==~ 0.1) &&
      (atomDiffuseIntensity ==~ 0.6) &&
      (atomSpecularIntensity ==~ 0.1) &&
      (atomShininess ==~ 4.0)
    {
      self.atomRepresentationStyle = .objects
    }
    else
    {
      self.atomRepresentationStyle = .custom
    }
  }
  
  
  public func getRepresentationType() -> Structure.RepresentationType?
  {
    return self.atomRepresentationType
  }
  
  public func setRepresentationType(type: Structure.RepresentationType?)
  {
    if let type = type
    {
      self.atomRepresentationType = type
      
      let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    
      switch(type)
      {
        case .sticks_and_balls:
          asymmetricAtoms.forEach{$0.drawRadius = PredefinedElements.sharedInstance.elementSet[$0.elementIdentifier].covalentRadius}
          atomScaleFactor = 0.7
        case .vdw:
          atomScaleFactor = 1.0
          asymmetricAtoms.forEach{$0.drawRadius = PredefinedElements.sharedInstance.elementSet[$0.elementIdentifier].VDWRadius}
      case .unity:
        asymmetricAtoms.forEach{$0.drawRadius = bondScaleFactor}
      }
    }
  }
  
  public func setRepresentationType(type: Structure.RepresentationType?, for asymmetricAtoms: [SKAsymmetricAtom])
  {
    if let type = type
    {
      self.atomRepresentationType = type
    
      switch(type)
      {
        case .sticks_and_balls:
          asymmetricAtoms.forEach{$0.drawRadius = PredefinedElements.sharedInstance.elementSet[$0.elementIdentifier].covalentRadius}
          atomScaleFactor = 0.7
        case .vdw:
          atomScaleFactor = 1.0
          asymmetricAtoms.forEach{$0.drawRadius = PredefinedElements.sharedInstance.elementSet[$0.elementIdentifier].VDWRadius}
      case .unity:
        asymmetricAtoms.forEach{$0.drawRadius = bondScaleFactor}
      }
    }
  }
  
  
  
  public func drawRadius(elementId: Int) -> Double
  {
    switch(self.atomRepresentationType)
    {
    case .vdw:
      return PredefinedElements.sharedInstance.elementSet[elementId].VDWRadius
    case .sticks_and_balls:
      return PredefinedElements.sharedInstance.elementSet[elementId].covalentRadius
    case .unity:
      return bondScaleFactor
    }
  }
  

  
  
  // MARK: -
  // MARK: Legacy Decodable support
  
  public required init(from decoder: Decoder) throws
  {
    var container = try decoder.unkeyedContainer()
    
    //Swift.print("Decoding Structure")
    super.init()
    
    let readVersionNumber: Int = try container.decode(Int.self)
    if readVersionNumber > self.versionNumber
    {
      throw iRASPAError.invalidArchiveVersion
    }
    
    self.displayName = try container.decode(String.self)
    self.isVisible = try container.decode(Bool.self)
    
    self.cell = try container.decode(SKCell.self)
    
    self.periodic = try container.decode(Bool.self)
    self.origin = try container.decode(SIMD3<Double>.self)
    self.scaling = try container.decode(SIMD3<Double>.self)
    self.orientation = try container.decode(simd_quatd.self)
    self.rotationDelta = try container.decode(Double.self)
    
    // Structure properties
    self.structureType = StructureType(rawValue: try container.decode(Int.self)) ?? StructureType.framework
    self.structureMaterialType = try container.decode(String.self)
    self.structureMass = try container.decode(Double.self)
    self.structureDensity = try container.decode(Double.self)
    self.structureHeliumVoidFraction = try container.decode(Double.self)
    self.structureSpecificVolume = try container.decode(Double.self)
    self.structureAccessiblePoreVolume = try container.decode(Double.self)
    self.structureVolumetricNitrogenSurfaceArea = try container.decode(Double.self)
    self.structureGravimetricNitrogenSurfaceArea = try container.decode(Double.self)
    self.structureNumberOfChannelSystems = try container.decode(Int.self)
    self.structureNumberOfInaccessiblePockets = try container.decode(Int.self)
    self.structureDimensionalityOfPoreSystem = try container.decode(Int.self)
    self.structureLargestCavityDiameter = try container.decode(Double.self)
    self.structureRestrictingPoreLimitingDiameter = try container.decode(Double.self)
    self.structureLargestCavityDiameterAlongAViablePath = try container.decode(Double.self)
    
    
    // Info
    self.authorFirstName = try container.decode(String.self)
    self.authorMiddleName = try container.decode(String.self)
    self.authorLastName = try container.decode(String.self)
    self.authorOrchidID = try container.decode(String.self)
    self.authorResearcherID = try container.decode(String.self)
    self.authorAffiliationUniversityName = try container.decode(String.self)
    self.authorAffiliationFacultyName = try container.decode(String.self)
    self.authorAffiliationInstituteName = try container.decode(String.self)
    self.authorAffiliationCityName = try container.decode(String.self)
    self.authorAffiliationCountryName = try container.decode(String.self)
    
    // Creation
    self.creationDate = try container.decode(Date.self)
    self.creationTemperature = try container.decode(String.self)
    self.creationTemperatureScale = try TemperatureScale(rawValue: container.decode(Int.self))!
    self.creationPressure = try container.decode(String.self)
    self.creationPressureScale = try PressureScale(rawValue: container.decode(Int.self))!
    self.creationMethod = try CreationMethod(rawValue: container.decode(Int.self))!
    
    self.creationUnitCellRelaxationMethod = try UnitCellRelaxationMethod(rawValue: container.decode(Int.self))!
    self.creationAtomicPositionsSoftwarePackage = try container.decode(String.self)
    self.creationAtomicPositionsIonsRelaxationAlgorithm = try IonsRelaxationAlgorithm(rawValue: container.decode(Int.self))!
    self.creationAtomicPositionsIonsRelaxationCheck = try IonsRelaxationCheck(rawValue: container.decode(Int.self))!
    self.creationAtomicPositionsForcefield = try container.decode(String.self)
    self.creationAtomicPositionsForcefieldDetails = try container.decode(String.self)
    
    self.creationAtomicChargesSoftwarePackage = try container.decode(String.self)
    self.creationAtomicChargesAlgorithms = try container.decode(String.self)
    self.creationAtomicChargesForcefield = try container.decode(String.self)
    self.creationAtomicChargesForcefieldDetails = try container.decode(String.self)
    
    // Experimental
    self.experimentalMeasurementRadiation = try container.decode(String.self)
    self.experimentalMeasurementWaveLength = try container.decode(String.self)
    self.experimentalMeasurementThetaMin = try container.decode(String.self)
    self.experimentalMeasurementThetaMax = try container.decode(String.self)
    self.experimentalMeasurementIndexLimitsHmin = try container.decode(String.self)
    self.experimentalMeasurementIndexLimitsHmax = try container.decode(String.self)
    self.experimentalMeasurementIndexLimitsKmin = try container.decode(String.self)
    self.experimentalMeasurementIndexLimitsKmax = try container.decode(String.self)
    self.experimentalMeasurementIndexLimitsLmin = try container.decode(String.self)
    self.experimentalMeasurementIndexLimitsLmax = try container.decode(String.self)
    self.experimentalMeasurementNumberOfSymmetryIndependentReflections = try container.decode(String.self)
    self.experimentalMeasurementSoftware = try container.decode(String.self)
    self.experimentalMeasurementRefinementDetails = try container.decode(String.self)
    self.experimentalMeasurementGoodnessOfFit = try container.decode(String.self)
    self.experimentalMeasurementRFactorGt = try container.decode(String.self)
    self.experimentalMeasurementRFactorAll = try container.decode(String.self)
    
    // Chemical
    self.chemicalFormulaMoiety = try container.decode(String.self)
    self.chemicalFormulaSum = try container.decode(String.self)
    self.chemicalNameSystematic = try container.decode(String.self)
    self.cellFormulaUnitsZ = try container.decode(Int.self)
    
    // Citation
    self.citationArticleTitle = try container.decode(String.self)
    self.citationAuthors = try container.decode(String.self)
    self.citationJournalTitle = try container.decode(String.self)
    self.citationJournalVolume = try container.decode(String.self)
    self.citationJournalNumber = try container.decode(String.self)
    self.citationJournalPageNumbers = try container.decode(String.self)
    self.citationDOI = try container.decode(String.self)
    self.citationPublicationDate = try container.decode(Date.self)
    self.citationDatebaseCodes = try container.decode(String.self)
    
    // atoms
    self.atoms = try container.decode(SKAtomTreeController.self)
    self.tag(atoms: self.atoms)
    
    self.drawAtoms = try container.decode(Bool.self)
    self.atomRepresentationType = try RepresentationType(rawValue: container.decode(Int.self)) ?? RepresentationType.sticks_and_balls
    self.atomRepresentationStyle = try RepresentationStyle(rawValue: container.decode(Int.self)) ?? RepresentationStyle.default
    self.atomForceFieldIdentifier = try container.decode(String.self)
    self.atomForceFieldOrder = try SKForceFieldSets.ForceFieldOrder(rawValue: container.decode(Int.self)) ?? SKForceFieldSets.ForceFieldOrder.forceFieldFirst
    self.atomColorSchemeIdentifier = try container.decode(String.self)
    self.atomColorOrder = try SKColorSets.ColorOrder(rawValue: container.decode(Int.self)) ?? SKColorSets.ColorOrder.forceFieldFirst
    
    self.atomHue = try container.decode(Double.self)
    self.atomSaturation = try container.decode(Double.self)
    self.atomValue = try container.decode(Double.self)
    self.atomScaleFactor = try container.decode(Double.self)
    
    self.atomAmbientOcclusion = try container.decode(Bool.self)
    self.atomHDR = try container.decode(Bool.self)
    self.atomHDRExposure = try container.decode(Double.self)
    self.atomHDRBloomLevel = try container.decode(Double.self)
    
    self.atomAmbientColor = try NSColor(float4: container.decode(SIMD4<Float>.self))
    self.atomDiffuseColor = try NSColor(float4: container.decode(SIMD4<Float>.self))
    self.atomSpecularColor = try NSColor(float4: container.decode(SIMD4<Float>.self))
    
    self.atomAmbientIntensity = try container.decode(Double.self)
    self.atomDiffuseIntensity = try container.decode(Double.self)
    self.atomSpecularIntensity = try container.decode(Double.self)
    self.atomShininess = try container.decode(Double.self)
    
    if readVersionNumber >= 2 // introduced in version 2
    {
      self.atomSelectionStyle = try RKSelectionStyle(rawValue: container.decode(Int.self)) ?? RKSelectionStyle.glow
      self.atomSelectionStripesDensity = try container.decode(Double.self)
      self.atomSelectionStripesFrequency = try container.decode(Double.self)
      self.atomSelectionWorleyNoise3DFrequency = try container.decode(Double.self)
      self.atomSelectionWorleyNoise3DJitter = try container.decode(Double.self)
    }
    if readVersionNumber >= 4 // introduced in version 4
    {
      self.atomSelectionScaling = try container.decode(Double.self)
    }
    
    // set value consistent with pre-defined styles
    if self.atomRepresentationStyle == .default
    {
      self.atomSelectionStyle = .WorleyNoise3D
      self.atomSelectionScaling = 1.2
    }
    if self.atomRepresentationStyle == .fancy
    {
      self.atomSelectionStyle = .WorleyNoise3D
      self.atomSelectionScaling = 1.0
    }
    if self.atomRepresentationStyle == .licorice
    {
      self.atomSelectionStyle = .WorleyNoise3D
      self.atomSelectionScaling = 1.5
    }
    
    // bonds
    let atom1Tags: [Int] = try container.decode([Int].self)
    let atom2Tags: [Int] = try container.decode([Int].self)
    let bondBoundaryTypes: [Int] = try container.decode([Int].self)
    
    let asymmetricAtoms: [SKAsymmetricAtom] = atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    let atomList: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}
    
    self.bonds.arrangedObjects = []
    for ((atom1Tag, atom2Tag), boundaryType) in zip(zip(atom1Tags, atom2Tags), bondBoundaryTypes)
    {
      let bond: SKBondNode = SKBondNode(atom1: atomList[atom1Tag], atom2: atomList[atom2Tag], boundaryType: SKBondNode.BoundaryType(rawValue: boundaryType)!)
      self.bonds.arrangedObjects.insert(bond)
    }
    
    for bond in bonds.arrangedObjects
    {
      bond.atom1.bonds.insert(bond)
      bond.atom2.bonds.insert(bond)
    }
    
    // coder.encode(self.bonds)
    self.drawBonds = try container.decode(Bool.self)
    self.bondScaleFactor = try container.decode(Double.self)
    self.bondColorMode = try RKBondColorMode(rawValue: container.decode(Int.self))!
    
    self.bondAmbientColor = try NSColor(float4: container.decode(SIMD4<Float>.self))
    self.bondDiffuseColor = try NSColor(float4: container.decode(SIMD4<Float>.self))
    self.bondSpecularColor = try NSColor(float4: container.decode(SIMD4<Float>.self))
    self.bondAmbientIntensity = try container.decode(Double.self)
    
    self.bondDiffuseIntensity = try container.decode(Double.self)
    self.bondSpecularIntensity = try container.decode(Double.self)
    self.bondShininess = try container.decode(Double.self)
    
    self.bondHDR = try container.decode(Bool.self)
    self.bondHDRExposure = try container.decode(Double.self)
    self.bondHDRBloomLevel = try container.decode(Double.self)
    
    self.bondHue = try container.decode(Double.self)
    self.bondSaturation = try container.decode(Double.self)
    self.bondValue = try container.decode(Double.self)
    self.bondAmbientOcclusion = try container.decode(Bool.self)
    
    if readVersionNumber >= 3 // introduced in version 3
    {
      self.atomTextType = try RKTextType(rawValue: container.decode(Int.self))!
      self.atomTextFont = try container.decode(String.self)
      self.atomTextScaling = try container.decode(Double.self)
      self.atomTextColor = try NSColor(float4: container.decode(SIMD4<Float>.self))
      self.atomTextGlowColor = try NSColor(float4: container.decode(SIMD4<Float>.self))
      self.atomTextStyle = try RKTextStyle(rawValue: container.decode(Int.self))!
      self.atomTextEffect = try RKTextEffect(rawValue: container.decode(Int.self))!
      self.atomTextAlignment = try RKTextAlignment(rawValue: container.decode(Int.self))!
      self.atomTextOffset = try container.decode(SIMD3<Double>.self)
    }
    
    // unit cell
    self.drawUnitCell = try container.decode(Bool.self)
    self.unitCellScaleFactor = try container.decode(Double.self)
    self.unitCellDiffuseColor = try NSColor(float4: container.decode(SIMD4<Float>.self))
    self.unitCellDiffuseIntensity = try container.decode(Double.self)
    
    
    // adsorption surface
    self.drawAdsorptionSurface = try container.decode(Bool.self)
    
    self.adsorptionSurfaceOpacity = try container.decode(Double.self)
    self.adsorptionSurfaceIsoValue = try container.decode(Double.self)
    self.adsorptionSurfaceSize = try container.decode(Int.self)
    self.adsorptionSurfaceProbeMolecule = try Structure.ProbeMolecule(rawValue: container.decode(Int.self))!
    
    self.adsorptionSurfaceFrontSideHDR = try container.decode(Bool.self)
    self.adsorptionSurfaceFrontSideHDRExposure = try container.decode(Double.self)
    self.adsorptionSurfaceFrontSideAmbientColor = try NSColor(float4: container.decode(SIMD4<Float>.self))
    self.adsorptionSurfaceFrontSideDiffuseColor = try NSColor(float4: container.decode(SIMD4<Float>.self))
    self.adsorptionSurfaceFrontSideSpecularColor = try NSColor(float4: container.decode(SIMD4<Float>.self))
    
    self.adsorptionSurfaceFrontSideAmbientIntensity = try container.decode(Double.self)
    self.adsorptionSurfaceFrontSideDiffuseIntensity = try container.decode(Double.self)
    self.adsorptionSurfaceFrontSideSpecularIntensity = try container.decode(Double.self)
    self.adsorptionSurfaceFrontSideShininess = try container.decode(Double.self)
    
    self.adsorptionSurfaceBackSideHDR = try container.decode(Bool.self)
    self.adsorptionSurfaceBackSideHDRExposure = try container.decode(Double.self)
    self.adsorptionSurfaceBackSideAmbientColor = try NSColor(float4: container.decode(SIMD4<Float>.self))
    self.adsorptionSurfaceBackSideDiffuseColor = try NSColor(float4: container.decode(SIMD4<Float>.self))
    self.adsorptionSurfaceBackSideSpecularColor = try NSColor(float4: container.decode(SIMD4<Float>.self))
    
    self.adsorptionSurfaceBackSideAmbientIntensity = try container.decode(Double.self)
    self.adsorptionSurfaceBackSideDiffuseIntensity = try container.decode(Double.self)
    self.adsorptionSurfaceBackSideSpecularIntensity = try container.decode(Double.self)
    self.adsorptionSurfaceBackSideShininess = try container.decode(Double.self)
    
    // REMOVE SOON AFTER CORRECTING THE GALLERY
    self.reComputeBoundingBox()
    
    
    self.setRepresentationStyle(style: self.atomRepresentationStyle)
    self.setRepresentationType(type: self.atomRepresentationType)
  }
  
  
  
  // MARK: Measuring distance, angle, and dihedral-angles
  // =====================================================================
  
  public func bondVector(_ bond: SKBondNode) -> SIMD3<Double>
  {
    let atom1: SIMD3<Double> = bond.atom1.position
    let atom2: SIMD3<Double> = bond.atom2.position
    let dr: SIMD3<Double> = atom2 - atom1
    return dr
  }
  
  
  public func bondLength(_ bond: SKBondNode) -> Double
  {
    let atom1: SIMD3<Double> = bond.atom1.position
    let atom2: SIMD3<Double> = bond.atom2.position
    let dr: SIMD3<Double> = abs(atom2 - atom1)
    return length(dr)
  }
  
  public func distance(_ atomA: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>), _ atomB: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>)) -> Double
  {
    let posB: SIMD3<Double> = atomA.copy.position
    let posA: SIMD3<Double> = atomB.copy.position
    let dr: SIMD3<Double> = abs(posB - posA)
    return length(dr)
  }
  
  public func bendAngle(_ atomA: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>), _ atomB: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>), _ atomC: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>)) -> Double
  {
    let posA: SIMD3<Double> = atomA.copy.position
    let posB: SIMD3<Double> = atomB.copy.position
    let posC: SIMD3<Double> = atomC.copy.position
    
    let dr1: SIMD3<Double> = posA - posB
    let dr2: SIMD3<Double> = posC - posB
    
    let vectorAB: SIMD3<Double> = normalize(dr1)
    let vectorBC: SIMD3<Double> = normalize(dr2)
    
    return acos(dot(vectorAB, vectorBC))
  }
  
  public func dihedralAngle(_ atomA: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>), _ atomB: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>), _ atomC: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>), _ atomD: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>)) -> Double
  {
    let posA: SIMD3<Double> = atomA.copy.position
    let posB: SIMD3<Double> = atomB.copy.position
    let posC: SIMD3<Double> = atomC.copy.position
    let posD: SIMD3<Double> = atomD.copy.position
    
    let Dab = posA - posB
    let Dbc = normalize(posC - posB)
    let Dcd = posD - posC
    
    let dotAB = dot(Dab,Dbc)
    let dotCD = dot(Dcd,Dbc)
    
    let dr = normalize(Dab - dotAB * Dbc)
    let ds = normalize(Dcd - dotCD * Dbc)
    
    // compute Cos(Phi)
    // Phi is defined in protein convention Phi(trans)=Pi
    let cosPhi: Double = dot(dr,ds)
    
    let Pb: SIMD3<Double> = cross(Dbc, Dab)
    let Pc: SIMD3<Double> = cross(Dbc, Dcd)
    
    let sign: Double = dot(Dbc, cross(Pb, Pc))
    
    let Phi: Double = sign > 0.0 ? fabs(acos(cosPhi)) : -fabs(acos(cosPhi))
    
    if(Phi<0.0)
    {
      return Phi + 2.0*Double.pi
    }
    return Phi
  }
  
  public func computeBondsOperation(structure: Structure, windowController: NSWindowController?) -> FKOperation?
  {
    return nil
  }
 
  // MARK: -
  // MARK: cell property-wrapper
  
  public var unitCell: double3x3
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.unitCell
  }
  
  public var cellLengthA: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.a
  }
  
  public var cellLengthB: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.b
  }
  
  public var cellLengthC: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.c
  }
  
  public var cellAngleAlpha: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.alpha
  }
  
  public var cellAngleBeta: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.beta
  }
  
  public var cellAngleGamma: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.gamma
  }
  
  public var cellVolume: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.volume
  }
  
  public var cellPerpendicularWidthsX: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.perpendicularWidths.x
  }
  
  public var cellPerpendicularWidthsY: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.perpendicularWidths.y
  }
  
  public var cellPerpendicularWidthsZ: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.enclosingBoundingBox)
    return boundaryBoxCell.perpendicularWidths.z
  }
  
  
  // MARK: -
  // MARK: general structure operations
  
  public var superCell: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)
  {
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    let atomCopies: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    let spaceGroup = SKSpacegroup(HallNumber: 1)
    let superCell = SKCell(superCell: self.cell)
    
    let superCellAtoms: SKAtomTreeController = SKAtomTreeController()
    
    for k1 in minimumReplicaX...maximumReplicaX
    {
      for k2 in minimumReplicaY...maximumReplicaY
      {
        for k3 in minimumReplicaZ...maximumReplicaZ
        {
          for atom in atomCopies
          {
            let CartesianPosition: SIMD3<Double> = atom.position + cell.unitCell * SIMD3<Double>(Double(k1),Double(k2),Double(k3))
            let newAtom: SKAsymmetricAtom = SKAsymmetricAtom(atom: atom.asymmetricParentAtom)
            newAtom.position = CartesianPosition
            
            let copy: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: newAtom, position: CartesianPosition)
            copy.type = .copy
            newAtom.copies.append(copy)
            
            let node = SKAtomTreeNode(representedObject: newAtom)
            superCellAtoms.appendNode(node, atArrangedObjectIndexPath: [])
          }
        }
      }
    }
    
    self.tag(atoms: superCellAtoms)
    
    let atomList: [SKAtomCopy] = superCellAtoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    
    let bonds: SKBondSetController = SKBondSetController(arrangedObjects: self.computeBonds(cell: superCell, atomList: atomList))
    
    return (cell: superCell, spaceGroup: spaceGroup, atoms: superCellAtoms, bonds: bonds)
  }
  
  public func convertToNativePositions(newAtoms: [SKAtomTreeNode])
  {
    
  }
  
  public func readySelectedAtomsForCopyAndPaste() -> [SKAtomTreeNode]
  {
    return []
  }
  
  public func bonds(newAtoms: [SKAtomTreeNode]) -> [SKBondNode]
  {
    return []
  }
  
  // MARK: -
  // MARK: Compute bonds
  
  public func computeBonds(cancelHandler: (()-> Bool) = {return false}, updateHandler: (() -> ()) = {}) -> Set<SKBondNode>
  {
    return []
  }
  
  public func computeBonds(cell: SKCell, atomList: [SKAtomCopy], cancelHandler: (()-> Bool) = {return false}, updateHandler: (() -> ()) = {}) -> Set<SKBondNode>
  {
    return []
  }
  
  public func reComputeBonds()
  {
    let cutoff: Double = 3.0
    let offsets: [[Int]] = [[0,0,0],[1,0,0],[1,1,0],[0,1,0],[-1,1,0],[0,0,1],[1,0,1],[1,1,1],[0,1,1],[-1,1,1],[-1,0,1],[-1,-1,1],[0,-1,1],[1,-1,1]]
    
    let atoms: [SKAtomCopy] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    atoms.forEach{ $0.bonds.removeAll()}
    var computedBonds: Set<SKBondNode> = []
    
    let perpendicularWidths: SIMD3<Double> = self.cell.boundingBox.widths + SIMD3<Double>(x: 0.1, y: 0.1, z: 0.1)
    let numberOfCells: [Int] = [Int(perpendicularWidths.x/cutoff),Int(perpendicularWidths.y/cutoff),Int(perpendicularWidths.z/cutoff)]
    let totalNumberOfCells: Int = numberOfCells[0] * numberOfCells[1] * numberOfCells[2]
    let cutoffVector: SIMD3<Double> = SIMD3<Double>(x: perpendicularWidths.x/Double(numberOfCells[0]), y: perpendicularWidths.y/Double(numberOfCells[1]), z: perpendicularWidths.z/Double(numberOfCells[2]))
    
    if ((numberOfCells[0]>=3) &&  (numberOfCells[1]>=3) && (numberOfCells[2]>=3))
    {
      
      var head: [Int] = [Int](repeating: -1, count: totalNumberOfCells)
      var list: [Int] = [Int](repeating: -1, count: atoms.count)
      
      // create cell-list based on the bond-cutoff
      for i in 0..<atoms.count
      {
        let position: SIMD3<Double> = atoms[i].position - self.cell.boundingBox.minimum
        
        let icell: Int = Int((position.x) / cutoffVector.x) +
          Int((position.y) / cutoffVector.y) * numberOfCells[0] +
          Int((position.z) / cutoffVector.z) * numberOfCells[1] * numberOfCells[0]
        
        
        list[i] = head[icell]
        head[icell] = i
      }
      
      for k1 in 0..<numberOfCells[0]
      {
        for k2 in 0..<numberOfCells[1]
        {
          for k3 in 0..<numberOfCells[2]
          {
            let icell_i: Int = k1 + k2 * numberOfCells[0] + k3 * numberOfCells[1] * numberOfCells[0]
            
            var i: Int = head[icell_i]
            while(i >= 0)
            {
              let posA: SIMD3<Double> = atoms[i].position
              
              // loop over neighboring cells
              for offset in offsets
              {
                let off: [Int] = [(k1 + offset[0]+numberOfCells[0]) % numberOfCells[0],
                                  (k2 + offset[1]+numberOfCells[1]) % numberOfCells[1],
                                  (k3 + offset[2]+numberOfCells[2]) % numberOfCells[2]]
                let icell_j: Int = off[0] + off[1] * numberOfCells[0] + off[2] * numberOfCells[1] * numberOfCells[0]
                
                var j: Int = head[icell_j]
                while(j >= 0)
                {
                  if((i < j) || (icell_i != icell_j))
                  {
                    let posB: SIMD3<Double> = atoms[j].position
                    let separationVector: SIMD3<Double> = posA - posB
                    
                    let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.56)
                    
                    if (length(separationVector) < bondCriteria)
                    {
                      computedBonds.insert(SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .internal))
                    }
                  }
                  j=list[j]
                }
              }
              i=list[i]
            }
          }
        }
      }
    }
    else
    {
      for i in 0..<atoms.count
      {
        let posA: SIMD3<Double> = atoms[i].position
        
        for j in i+1..<atoms.count
        {
          let posB: SIMD3<Double> = atoms[j].position
          
          let separationVector: SIMD3<Double> = posA - posB
          
          let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.56)
          
          if (length(separationVector) < bondCriteria )
          {
            computedBonds.insert(SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .internal))
          }
        }
        
      }
    }
    
    bonds.arrangedObjects = computedBonds
  }
  
  
  public func reComputeBonds(_ node: ProjectTreeNode, cancelHandler: (()-> Bool), updateHandler: (() -> ()))
  {
    let cutoff: Double = 3.0
    let offsets: [[Int]] = [[0,0,0],[1,0,0],[1,1,0],[0,1,0],[-1,1,0],[0,0,1],[1,0,1],[1,1,1],[0,1,1],[-1,1,1],[-1,0,1],[-1,-1,1],[0,-1,1],[1,-1,1]]
    var totalCount: Int
    
    let atoms: [SKAtomCopy] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    atoms.forEach{ $0.bonds.removeAll()}
    var computedBonds: Set<SKBondNode> = []
    
    let perpendicularWidths: SIMD3<Double> = self.cell.boundingBox.widths + SIMD3<Double>(x: 0.1, y: 0.1, z: 0.1)
    let numberOfCells: [Int] = [Int(perpendicularWidths.x/cutoff),Int(perpendicularWidths.y/cutoff),Int(perpendicularWidths.z/cutoff)]
    let totalNumberOfCells: Int = numberOfCells[0] * numberOfCells[1] * numberOfCells[2]
    let cutoffVector: SIMD3<Double> = SIMD3<Double>(x: perpendicularWidths.x/Double(numberOfCells[0]), y: perpendicularWidths.y/Double(numberOfCells[1]), z: perpendicularWidths.z/Double(numberOfCells[2]))
    
    if ((numberOfCells[0]>=3) &&  (numberOfCells[1]>=3) && (numberOfCells[2]>=3))
    {
      
      var head: [Int] = [Int](repeating: -1, count: totalNumberOfCells)
      var list: [Int] = [Int](repeating: -1, count: atoms.count)
      
      // create cell-list based on the bond-cutoff
      for i in 0..<atoms.count
      {
        let position: SIMD3<Double> = atoms[i].position - self.cell.boundingBox.minimum
        
        let icell: Int = Int((position.x) / cutoffVector.x) +
          Int((position.y) / cutoffVector.y) * numberOfCells[0] +
          Int((position.z) / cutoffVector.z) * numberOfCells[1] * numberOfCells[0]
        
        
        list[i] = head[icell]
        head[icell] = i
      }
      
      
      totalCount = numberOfCells[0] * numberOfCells[1] * numberOfCells[2]
      
      
      let bondProgress: Progress = Progress(totalUnitCount: Int64(totalCount))
      bondProgress.completedUnitCount = 0
      
      for k1 in 0..<numberOfCells[0]
      {
        for k2 in 0..<numberOfCells[1]
        {
          for k3 in 0..<numberOfCells[2]
          {
            let icell_i: Int = k1 + k2 * numberOfCells[0] + k3 * numberOfCells[1] * numberOfCells[0]
            
            var i: Int = head[icell_i]
            while(i >= 0)
            {
              let posA: SIMD3<Double> = atoms[i].position
              
              // loop over neighboring cells
              for offset in offsets
              {
                let off: [Int] = [(k1 + offset[0]+numberOfCells[0]) % numberOfCells[0],
                                  (k2 + offset[1]+numberOfCells[1]) % numberOfCells[1],
                                  (k3 + offset[2]+numberOfCells[2]) % numberOfCells[2]]
                let icell_j: Int = off[0] + off[1] * numberOfCells[0] + off[2] * numberOfCells[1] * numberOfCells[0]
                
                var j: Int = head[icell_j]
                while(j >= 0)
                {
                  if((i < j) || (icell_i != icell_j))
                  {
                    let posB: SIMD3<Double> = atoms[j].position
                    let separationVector: SIMD3<Double> = posA - posB
                    
                    let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.56)
                    
                    if (length(separationVector) < bondCriteria)
                    {
                      computedBonds.insert(SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .internal))
                    }
                  }
                  j=list[j]
                }
              }
              i=list[i]
            }
            
            
            bondProgress.completedUnitCount = bondProgress.completedUnitCount + 1
            
            if (bondProgress.completedUnitCount % 100 == 0)
            {
              updateHandler()
              //node.updateProgress(node)
            }
            
            if cancelHandler()
            {
              return
            }
            
            
          }
        }
      }
    }
    else
    {
      let bondProgress: Progress = Progress(totalUnitCount: Int64(atoms.count * (atoms.count - 1) / 2))
      bondProgress.completedUnitCount = 0
      
      for i in 0..<atoms.count
      {
        let posA: SIMD3<Double> = atoms[i].position
        
        for j in i+1..<atoms.count
        {
          let posB: SIMD3<Double> = atoms[j].position
          
          let separationVector: SIMD3<Double> = posA - posB
          
          let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.56)
          
          bondProgress.completedUnitCount = bondProgress.completedUnitCount + 1
          
          if (bondProgress.completedUnitCount % 100 == 0)
          {
            updateHandler()
            //node.updateProgress(node)
          }
          
          if cancelHandler()
          {
            return
          }
          
          if (length(separationVector) < bondCriteria )
          {
            computedBonds.insert(SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .internal))
          }
        }
        
      }
    }
    
    
    bonds.arrangedObjects = computedBonds
  }

  
  // MARK: -
  // MARK: RKRenderStructure protocol
  
  public var hasSelectedObjects: Bool
  {
    return self.atoms.selectedTreeNodes.count > 0 || self.atoms.selectedTreeNode != nil
  }

  public func generateCopiesForAsymmetricAtom(_ asymetricAtom: SKAsymmetricAtom)
  {
    for i in 0..<asymetricAtom.copies.count
    {
      asymetricAtom.copies[i].position = asymetricAtom.position
    }
  }
  
  
  
  public var renderBoundingBox: SKBoundingBox
  {
    return self.transformedBoundingBox
  }
  
  
  public var boundingBox: SKBoundingBox
  {
    return SKBoundingBox()
  }
  
  public var clipBonds: Bool
  {
    return false
  }
  
  public var transformedBoundingBox: SKBoundingBox
  {
    return SKBoundingBox()
  }
  
  public func reComputeBoundingBox()
  {
    let boundingBox: SKBoundingBox = self.boundingBox
    
    // store in the cell datastructure
    self.cell.boundingBox = boundingBox
  }
  
  public func numberOfReplicas() -> Int
  {
    return 1
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public var renderAtomSelectionFrequency: Double
  {
    get
    {
      switch(self.atomSelectionStyle)
      {
      case .glow:
        return 0.0
      case .striped:
        return self.atomSelectionStripesFrequency
      case .WorleyNoise3D:
        return self.atomSelectionWorleyNoise3DFrequency
      }
    }
    set(newValue)
    {
      switch(self.atomSelectionStyle)
      {
      case .glow:
        break
      case .striped:
        self.atomSelectionStripesFrequency = newValue
      case .WorleyNoise3D:
        self.atomSelectionWorleyNoise3DFrequency = newValue
      }
    }
  }
  
  public var renderAtomSelectionDensity: Double
  {
    get
    {
      switch(self.atomSelectionStyle)
      {
        case .glow:
          return 0.0
        case .striped:
          return self.atomSelectionStripesDensity
        case .WorleyNoise3D:
          return self.atomSelectionWorleyNoise3DJitter
      }
    }
    set(newValue)
    {
      switch(self.atomSelectionStyle)
      {
      case .glow:
        break
      case .striped:
        self.atomSelectionStripesDensity = newValue
      case .WorleyNoise3D:
        self.atomSelectionWorleyNoise3DJitter = newValue
      }
    }
  }
  
  
  
  
  
  

  
  
  public var renderSelectedBonds: [RKInPerInstanceAttributesBonds]
  {
    return [RKInPerInstanceAttributesBonds]()
  }
  

  
  
  
  public var renderInternalBonds: [RKInPerInstanceAttributesBonds]
  {
    get
    {
      let data: [RKInPerInstanceAttributesBonds] = [RKInPerInstanceAttributesBonds]()
      return data
    }
  }
  
  public var renderExternalBonds: [RKInPerInstanceAttributesBonds]
  {
    get
    {
      let data: [RKInPerInstanceAttributesBonds] = [RKInPerInstanceAttributesBonds]()
      return data
    }
  }
  
  public func recomputeDensityProperties()
  {
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    self.structureMass = 0.0
    for atom in atoms
    {
      let elementId: Int = atom.asymmetricParentAtom.elementIdentifier
      self.structureMass += PredefinedElements.sharedInstance.elementSet[elementId].mass
    }
    
    self.structureDensity = 1.0e-3 * self.structureMass / (SKConstants.AvogadroConstantPerAngstromCubed * self.cell.volume)
    self.structureSpecificVolume = 1.0e3 / self.structureDensity
    self.structureAccessiblePoreVolume = self.structureHeliumVoidFraction * self.structureSpecificVolume
  }
  
  public func expandSymmetry()
  {
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    
    for asymmetricAtom in asymmetricAtoms
    {
      let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: asymmetricAtom, position: asymmetricAtom.position)
      newAtom.type = .copy
      asymmetricAtom.copies = [newAtom]
    }
  }
  
  public func expandSymmetry(asymmetricAtom: SKAsymmetricAtom)
  {
    let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: asymmetricAtom, position: asymmetricAtom.position)
    newAtom.type = .copy
    asymmetricAtom.copies = [newAtom]
  }
  
  
  
  
  
  
  public var crystallographicPositions: [(SIMD3<Double>, Int)]
  {
    return []
  }
  
  
  
  
  public func removeSymmetry()
  {
    
  }
  
  
  
  public var spaceGroupHallNumber: Int?
  {
    get
    {
      return (type(of: self) == Structure.self) ? nil : 1
    }
    set
    {
    }
  }
  
  public func translateSelection(by: SIMD3<Double>)
  {
  
  }
  
  public func finalizeTranslateSelection(by: SIMD3<Double>) -> (atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    return nil
  }
  
  public func centerOfMassOfSelection() -> SIMD3<Double>
  {
    return SIMD3<Double>(0.0,0.0,0.0)
  }
  
  public func matrixOfInertia() -> double3x3
  {
    return double3x3()
  }
  
  // -1: always update
  // 0: x
  // 1: y
  // 2: z
  // update when index changes, so when a new direction of rotation has been chosen
  public func recomputeSelectionBodyFixedBasis(index: Int)
  {
    if index < 0 || self.selectionRotationIndex != index
    {
      self.selectionRotationIndex = index
      self.selectionCOMTranslation = centerOfMassOfSelection()
      let intertiaMatrix: double3x3 = matrixOfInertia()

      var eigenvectors: double3x3 = double3x3()
      var eigenvalues: SIMD3<Double> = SIMD3<Double>()
      intertiaMatrix.EigenSystemSymmetric3x3(Q: &eigenvectors, w: &eigenvalues)
      self.selectionBodyFixedBasis = eigenvectors
    }
  }
  
  public func translateSelectionCartesian(by translation: SIMD3<Double>) -> (atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    return nil
  }
  
  public func rotateSelectionCartesian(using: simd_quatd) -> (atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    return nil
  }
  
  public func translateSelectionBodyFrame(by: SIMD3<Double>) -> (atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    return nil
  }
  
  public func rotateSelectionBodyFrame(using: simd_quatd, index: Int) -> (atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    return nil
  }
  
  public func computeChangedBondLength(bond: SKBondNode, to: Double) -> (SIMD3<Double>,SIMD3<Double>)
  {
    return (SIMD3<Double>(0.0,0.0,0.0),SIMD3<Double>(0.0,0.0,0.0))
  }
  
  public var renderCanDrawAdsorptionSurface: Bool {return false}
  
  public func setSpaceGroup(number: Int) -> (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    return nil
  }
  
  public func applyCellContentShift() -> (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
      
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
      
      
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    let atomCopies: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
      
    let spaceGroup = SKSpacegroup(HallNumber: 1)
    var superCell = SKCell(superCell: self.cell)
    superCell.contentShift = SIMD3<Double>(0.0,0.0,0.0)
      
    let superCellAtoms: SKAtomTreeController = SKAtomTreeController()
      
    for k1 in minimumReplicaX...maximumReplicaX
    {
      for k2 in minimumReplicaY...maximumReplicaY
      {
        for k3 in minimumReplicaZ...maximumReplicaZ
        {
          for atom in atomCopies
          {
            let CartesianPosition: SIMD3<Double> = atom.position + cell.unitCell * SIMD3<Double>(Double(k1),Double(k2),Double(k3)) + self.cell.contentShift
            let newAtom: SKAsymmetricAtom = SKAsymmetricAtom(atom: atom.asymmetricParentAtom)
            newAtom.position = CartesianPosition
              
            let copy: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: newAtom, position: CartesianPosition)
            copy.type = .copy
            newAtom.copies.append(copy)
              
            let node = SKAtomTreeNode(representedObject: newAtom)
            superCellAtoms.appendNode(node, atArrangedObjectIndexPath: [])
          }
        }
      }
    }
      
    self.tag(atoms: superCellAtoms)
      
    let atomList: [SKAtomCopy] = superCellAtoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
      
    let bonds: SKBondSetController = SKBondSetController(arrangedObjects: self.computeBonds(cell: superCell, atomList: atomList))
      
    return (cell: superCell, spaceGroup: spaceGroup, atoms: superCellAtoms, bonds: bonds)
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    let calendar = Calendar.current
    
    encoder.encode(Structure.classVersionNumber)
    
    encoder.encode(self.displayName)
    encoder.encode(isVisible)
    
    encoder.encode(self.spaceGroupHallNumber ?? Int(1))
    encoder.encode(cell)
    encoder.encode(periodic)
    encoder.encode(origin)
    encoder.encode(scaling)
    encoder.encode(orientation)
    encoder.encode(rotationDelta)
    
    encoder.encode(primitiveTransformationMatrix)
    encoder.encode(primitiveOrientation)
    encoder.encode(primitiveRotationDelta)
    
    encoder.encode(primitiveOpacity)
    encoder.encode(primitiveIsCapped)
    encoder.encode(primitiveIsFractional)
    encoder.encode(primitiveNumberOfSides)
    encoder.encode(primitiveThickness)
    
    encoder.encode(primitiveFrontSideHDR)
    encoder.encode(primitiveFrontSideHDRExposure)
    encoder.encode(primitiveFrontSideAmbientColor)
    encoder.encode(primitiveFrontSideDiffuseColor)
    encoder.encode(primitiveFrontSideSpecularColor)
    encoder.encode(primitiveFrontSideDiffuseIntensity)
    encoder.encode(primitiveFrontSideAmbientIntensity)
    encoder.encode(primitiveFrontSideSpecularIntensity)
    encoder.encode(primitiveFrontSideShininess)
    
    encoder.encode(primitiveBackSideHDR)
    encoder.encode(primitiveBackSideHDRExposure)
    encoder.encode(primitiveBackSideAmbientColor)
    encoder.encode(primitiveBackSideDiffuseColor)
    encoder.encode(primitiveBackSideSpecularColor)
    encoder.encode(primitiveBackSideDiffuseIntensity)
    encoder.encode(primitiveBackSideAmbientIntensity)
    encoder.encode(primitiveBackSideSpecularIntensity)
    encoder.encode(primitiveBackSideShininess)
    
    encoder.encode(frameworkProbeMolecule.rawValue)
    
    encoder.encode(Double(minimumGridEnergyValue ?? 0.0))
    
    self.tag(atoms: self.atoms)
    encoder.encode(atoms)
    
    encoder.encode((self.atomRepresentationStyle == RepresentationStyle.licorice || self.atomRepresentationType == RepresentationType.unity) ? true : drawAtoms)
    
    encoder.encode(atomRepresentationType.rawValue)
    encoder.encode(atomRepresentationStyle.rawValue)
    encoder.encode(atomForceFieldIdentifier)
    encoder.encode(atomForceFieldOrder.rawValue)
    encoder.encode(atomColorSchemeIdentifier)
    encoder.encode(atomColorOrder.rawValue)
    
    encoder.encode(atomSelectionStyle.rawValue)
    encoder.encode(atomSelectionStripesDensity)
    encoder.encode(atomSelectionStripesFrequency)
    encoder.encode(atomSelectionWorleyNoise3DFrequency)
    encoder.encode(atomSelectionWorleyNoise3DJitter)
    encoder.encode(atomSelectionScaling)
    encoder.encode(selectionIntensity)
    
    encoder.encode(atomHue)
    encoder.encode(atomSaturation)
    encoder.encode(atomValue)
    encoder.encode(atomScaleFactor)
    
    encoder.encode(atomAmbientOcclusion)
    encoder.encode(atomAmbientOcclusionPatchNumber)
    encoder.encode(atomAmbientOcclusionTextureSize)
    encoder.encode(atomAmbientOcclusionPatchSize)
    encoder.encode(atomHDR)
    encoder.encode(atomHDRExposure)
    encoder.encode(atomHDRBloomLevel)
    
    encoder.encode(atomAmbientColor)
    encoder.encode(atomDiffuseColor)
    encoder.encode(atomSpecularColor)
    encoder.encode(atomAmbientIntensity)
    encoder.encode(atomDiffuseIntensity)
    encoder.encode(atomSpecularIntensity)
    encoder.encode(atomShininess)
    
    encoder.encode(self.atomTextType.rawValue)
    encoder.encode(self.atomTextFont)
    encoder.encode(self.atomTextScaling)
    encoder.encode(self.atomTextColor)
    encoder.encode(self.atomTextGlowColor)
    encoder.encode(self.atomTextStyle.rawValue)
    encoder.encode(self.atomTextEffect.rawValue)
    encoder.encode(self.atomTextAlignment.rawValue)
    encoder.encode(self.atomTextOffset)
    
    // encode bonds using tags
    encoder.encode(self.bonds)
    
    encoder.encode(drawBonds)
    encoder.encode(bondScaleFactor)
    encoder.encode(bondColorMode.rawValue)
    
    encoder.encode(bondAmbientColor)
    encoder.encode(bondDiffuseColor)
    encoder.encode(bondSpecularColor)
    encoder.encode(bondAmbientIntensity)
    encoder.encode(bondDiffuseIntensity)
    encoder.encode(bondSpecularIntensity)
    encoder.encode(bondShininess)
    
    encoder.encode(bondHDR)
    encoder.encode(bondHDRExposure)
    encoder.encode(bondHDRBloomLevel)
    
    encoder.encode(bondHue)
    encoder.encode(bondSaturation)
    encoder.encode(bondValue)
    
    encoder.encode(bondAmbientOcclusion)
    
    // unit cell
    encoder.encode(self.drawUnitCell)
    encoder.encode(self.unitCellScaleFactor)
    encoder.encode(self.unitCellDiffuseColor)
    encoder.encode(self.unitCellDiffuseIntensity)
    
    // adsorption surface
    encoder.encode(self.drawAdsorptionSurface)
    encoder.encode(self.adsorptionSurfaceOpacity)
    encoder.encode(self.adsorptionSurfaceIsoValue)
    encoder.encode(Double(self.minimumGridEnergyValue ?? 0.0))
    
    encoder.encode(self.adsorptionSurfaceSize)
    encoder.encode(Int(0))
    
    encoder.encode(self.adsorptionSurfaceProbeMolecule.rawValue)
    
    encoder.encode(self.adsorptionSurfaceFrontSideHDR)
    encoder.encode(self.adsorptionSurfaceFrontSideHDRExposure)
    encoder.encode(self.adsorptionSurfaceFrontSideAmbientColor)
    encoder.encode(self.adsorptionSurfaceFrontSideDiffuseColor)
    encoder.encode(self.adsorptionSurfaceFrontSideSpecularColor)
    encoder.encode(self.adsorptionSurfaceFrontSideAmbientIntensity)
    encoder.encode(self.adsorptionSurfaceFrontSideDiffuseIntensity)
    encoder.encode(self.adsorptionSurfaceFrontSideSpecularIntensity)
    encoder.encode(self.adsorptionSurfaceFrontSideShininess)
    
    encoder.encode(self.adsorptionSurfaceBackSideHDR)
    encoder.encode(self.adsorptionSurfaceBackSideHDRExposure)
    encoder.encode(self.adsorptionSurfaceBackSideAmbientColor)
    encoder.encode(self.adsorptionSurfaceBackSideDiffuseColor)
    encoder.encode(self.adsorptionSurfaceBackSideSpecularColor)
    encoder.encode(self.adsorptionSurfaceBackSideAmbientIntensity)
    encoder.encode(self.adsorptionSurfaceBackSideDiffuseIntensity)
    encoder.encode(self.adsorptionSurfaceBackSideSpecularIntensity)
    encoder.encode(self.adsorptionSurfaceBackSideShininess)
    
    // Structure properties
    encoder.encode(self.structureType.rawValue)
    encoder.encode(self.structureMaterialType)
    encoder.encode(self.structureMass)
    encoder.encode(self.structureDensity)
    encoder.encode(self.structureHeliumVoidFraction)
    encoder.encode(self.structureSpecificVolume)
    encoder.encode(self.structureAccessiblePoreVolume)
    encoder.encode(self.structureVolumetricNitrogenSurfaceArea)
    encoder.encode(self.structureGravimetricNitrogenSurfaceArea)
    encoder.encode(self.structureNumberOfChannelSystems)
    encoder.encode(self.structureNumberOfInaccessiblePockets)
    encoder.encode(self.structureDimensionalityOfPoreSystem)
    encoder.encode(self.structureLargestCavityDiameter)
    encoder.encode(self.structureRestrictingPoreLimitingDiameter)
    encoder.encode(self.structureLargestCavityDiameterAlongAViablePath)
    
    // Info
    encoder.encode(self.authorFirstName)
    encoder.encode(self.authorMiddleName)
    encoder.encode(self.authorLastName)
    encoder.encode(self.authorOrchidID)
    encoder.encode(self.authorResearcherID)
    encoder.encode(self.authorAffiliationUniversityName)
    encoder.encode(self.authorAffiliationFacultyName)
    encoder.encode(self.authorAffiliationInstituteName)
    encoder.encode(self.authorAffiliationCityName)
    encoder.encode(self.authorAffiliationCountryName)
    
    // Creation
    encoder.encode(UInt16(calendar.component(.day, from: self.creationDate)))
    encoder.encode(UInt16(calendar.component(.month, from: self.creationDate)))
    encoder.encode(UInt32(calendar.component(.year, from: self.creationDate)))
    encoder.encode(self.creationTemperature)
    encoder.encode(self.creationTemperatureScale.rawValue)
    encoder.encode(self.creationPressure)
    encoder.encode(self.creationPressureScale.rawValue)
    encoder.encode(self.creationMethod.rawValue)
    
    encoder.encode(self.creationUnitCellRelaxationMethod.rawValue)
    encoder.encode(self.creationAtomicPositionsSoftwarePackage)
    encoder.encode(self.creationAtomicPositionsIonsRelaxationAlgorithm.rawValue)
    encoder.encode(self.creationAtomicPositionsIonsRelaxationCheck.rawValue)
    encoder.encode(self.creationAtomicPositionsForcefield)
    encoder.encode(self.creationAtomicPositionsForcefieldDetails)
    
    encoder.encode(self.creationAtomicChargesSoftwarePackage)
    encoder.encode(self.creationAtomicChargesAlgorithms)
    encoder.encode(self.creationAtomicChargesForcefield)
    encoder.encode(self.creationAtomicChargesForcefieldDetails)
    
    // Experimental
    encoder.encode(self.experimentalMeasurementRadiation)
    encoder.encode(self.experimentalMeasurementWaveLength)
    encoder.encode(self.experimentalMeasurementThetaMin)
    encoder.encode(self.experimentalMeasurementThetaMax)
    encoder.encode(self.experimentalMeasurementIndexLimitsHmin)
    encoder.encode(self.experimentalMeasurementIndexLimitsHmax)
    encoder.encode(self.experimentalMeasurementIndexLimitsKmin)
    encoder.encode(self.experimentalMeasurementIndexLimitsKmax)
    encoder.encode(self.experimentalMeasurementIndexLimitsLmin)
    encoder.encode(self.experimentalMeasurementIndexLimitsLmax)
    encoder.encode(self.experimentalMeasurementNumberOfSymmetryIndependentReflections)
    encoder.encode(self.experimentalMeasurementSoftware)
    encoder.encode(self.experimentalMeasurementRefinementDetails)
    encoder.encode(self.experimentalMeasurementGoodnessOfFit)
    encoder.encode(self.experimentalMeasurementRFactorGt)
    encoder.encode(self.experimentalMeasurementRFactorAll)
    
    // Chemical
    encoder.encode(self.chemicalFormulaMoiety)
    encoder.encode(self.chemicalFormulaSum)
    encoder.encode(self.chemicalNameSystematic)
    encoder.encode(self.cellFormulaUnitsZ)
    
    // Citation
    encoder.encode(self.citationArticleTitle)
    encoder.encode(self.citationJournalTitle)
    encoder.encode(self.citationAuthors)
    encoder.encode(self.citationJournalVolume)
    encoder.encode(self.citationJournalNumber)
    encoder.encode(self.citationJournalPageNumbers)
    encoder.encode(self.citationDOI)
    encoder.encode(UInt16(calendar.component(.day, from: self.self.citationPublicationDate)))
    encoder.encode(UInt16(calendar.component(.month, from: self.self.citationPublicationDate)))
    encoder.encode(UInt32(calendar.component(.year, from: self.self.citationPublicationDate)))
    encoder.encode(self.citationDatebaseCodes)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let calendar = Calendar.current
    var components = DateComponents()
    components.era = 1
    components.quarter = 0
    components.hour = 0
    components.minute = 0
    components.second = 0
    
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > Structure.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    displayName = try decoder.decode(String.self)
    isVisible = try decoder.decode(Bool.self)
    
    let number = try decoder.decode(Int.self)
    spaceGroup = SKSpacegroup(HallNumber: number)
    cell = try decoder.decode(SKCell.self)
    periodic = try decoder.decode(Bool.self)
    origin = try decoder.decode(SIMD3<Double>.self)
    scaling = try decoder.decode(SIMD3<Double>.self)
    orientation = try decoder.decode(simd_quatd.self)
    rotationDelta = try decoder.decode(Double.self)
    
    if readVersionNumber >= 2 // introduced in version 2
    {
      primitiveTransformationMatrix = try decoder.decode(double3x3.self)
      primitiveOrientation = try decoder.decode(simd_quatd.self)
      primitiveRotationDelta = try decoder.decode(Double.self)
      
      primitiveOpacity = try decoder.decode(Double.self)
      primitiveIsCapped = try decoder.decode(Bool.self)
      primitiveIsFractional = try decoder.decode(Bool.self)
      primitiveNumberOfSides = try decoder.decode(Int.self)
      primitiveThickness = try decoder.decode(Double.self)
      
      primitiveFrontSideHDR = try decoder.decode(Bool.self)
      primitiveFrontSideHDRExposure = try decoder.decode(Double.self)
      primitiveFrontSideAmbientColor = try decoder.decode(NSColor.self)
      primitiveFrontSideDiffuseColor = try decoder.decode(NSColor.self)
      primitiveFrontSideSpecularColor = try decoder.decode(NSColor.self)
      primitiveFrontSideDiffuseIntensity = try decoder.decode(Double.self)
      primitiveFrontSideAmbientIntensity = try decoder.decode(Double.self)
      primitiveFrontSideSpecularIntensity = try decoder.decode(Double.self)
      primitiveFrontSideShininess = try decoder.decode(Double.self)
      
      primitiveBackSideHDR = try decoder.decode(Bool.self)
      primitiveBackSideHDRExposure = try decoder.decode(Double.self)
      primitiveBackSideAmbientColor = try decoder.decode(NSColor.self)
      primitiveBackSideDiffuseColor = try decoder.decode(NSColor.self)
      primitiveBackSideSpecularColor = try decoder.decode(NSColor.self)
      primitiveBackSideDiffuseIntensity = try decoder.decode(Double.self)
      primitiveBackSideAmbientIntensity = try decoder.decode(Double.self)
      primitiveBackSideSpecularIntensity = try decoder.decode(Double.self)
      primitiveBackSideShininess = try decoder.decode(Double.self)
    }
    
    if readVersionNumber >= 3 // introduced in version 3
    {
      frameworkProbeMolecule = try Structure.ProbeMolecule(rawValue: decoder.decode(Int.self))!
    }
    
    minimumGridEnergyValue = Float(try decoder.decode(Double.self))
    
    atoms = try decoder.decode(SKAtomTreeController.self)
    
    drawAtoms = try decoder.decode(Bool.self)
    
    atomRepresentationType = try RepresentationType(rawValue: decoder.decode(Int.self))!
    atomRepresentationStyle = try RepresentationStyle(rawValue: decoder.decode(Int.self)) ??  RepresentationStyle.custom
    atomForceFieldIdentifier = try decoder.decode(String.self)
    atomForceFieldOrder = try SKForceFieldSets.ForceFieldOrder(rawValue: decoder.decode(Int.self))!
    atomColorSchemeIdentifier = try decoder.decode(String.self)
    atomColorOrder = try SKColorSets.ColorOrder(rawValue: decoder.decode(Int.self))!
    
    atomSelectionStyle = try RKSelectionStyle(rawValue: decoder.decode(Int.self))!
    atomSelectionStripesDensity = try decoder.decode(Double.self)
    atomSelectionStripesFrequency = try decoder.decode(Double.self)
    atomSelectionWorleyNoise3DFrequency = try decoder.decode(Double.self)
    atomSelectionWorleyNoise3DJitter = try decoder.decode(Double.self)
    atomSelectionScaling = try decoder.decode(Double.self)
    selectionIntensity = try decoder.decode(Double.self)
    
    atomHue = try decoder.decode(Double.self)
    atomSaturation = try decoder.decode(Double.self)
    atomValue = try decoder.decode(Double.self)
    atomScaleFactor = try decoder.decode(Double.self)
    
    atomAmbientOcclusion = try decoder.decode(Bool.self)
    atomAmbientOcclusionPatchNumber = try decoder.decode(Int.self)
    atomAmbientOcclusionTextureSize = try decoder.decode(Int.self)
    atomAmbientOcclusionPatchSize = try decoder.decode(Int.self)
    
    atomHDR = try decoder.decode(Bool.self)
    atomHDRExposure = try decoder.decode(Double.self)
    atomHDRBloomLevel = try decoder.decode(Double.self)
    
    atomAmbientColor = try decoder.decode(NSColor.self)
    atomDiffuseColor = try decoder.decode(NSColor.self)
    atomSpecularColor = try decoder.decode(NSColor.self)
    atomAmbientIntensity = try decoder.decode(Double.self)
    atomDiffuseIntensity = try decoder.decode(Double.self)
    atomSpecularIntensity = try decoder.decode(Double.self)
    atomShininess = try decoder.decode(Double.self)
    
    self.atomTextType = try RKTextType(rawValue: decoder.decode(Int.self))!
    self.atomTextFont = try decoder.decode(String.self)
    self.atomTextScaling = try decoder.decode(Double.self)
    self.atomTextColor = try decoder.decode(NSColor.self)
    self.atomTextGlowColor = try decoder.decode(NSColor.self)
    self.atomTextStyle = try RKTextStyle(rawValue: decoder.decode(Int.self))!
    self.atomTextEffect = try RKTextEffect(rawValue: decoder.decode(Int.self))!
    self.atomTextAlignment = try RKTextAlignment(rawValue: decoder.decode(Int.self))!
    self.atomTextOffset = try decoder.decode(SIMD3<Double>.self)
    
    self.bonds = try decoder.decode(SKBondSetController.self)
    
    // fill in atoms from stored atom-tags
    let asymmetricAtoms: [SKAsymmetricAtom] = atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    let atomList: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}
    for bond in bonds.arrangedObjects
    {
      let atom1 = atomList[bond.atom1Tag]
      let atom2 = atomList[bond.atom2Tag]
      bond.atom1 = atom1
      bond.atom2 = atom2
      atom1.bonds.insert(bond)
      atom2.bonds.insert(bond)
    }
    
    drawBonds = try decoder.decode(Bool.self)
    bondScaleFactor = try decoder.decode(Double.self)
    bondColorMode = try RKBondColorMode(rawValue: decoder.decode(Int.self))!
    
    bondAmbientColor = try decoder.decode(NSColor.self)
    bondDiffuseColor = try decoder.decode(NSColor.self)
    bondSpecularColor = try decoder.decode(NSColor.self)
    bondAmbientIntensity = try decoder.decode(Double.self)
    bondDiffuseIntensity = try decoder.decode(Double.self)
    bondSpecularIntensity = try decoder.decode(Double.self)
    bondShininess = try decoder.decode(Double.self)
    
    bondHDR = try decoder.decode(Bool.self)
    bondHDRExposure = try decoder.decode(Double.self)
    bondHDRBloomLevel = try decoder.decode(Double.self)
    
    bondHue = try decoder.decode(Double.self)
    bondSaturation = try decoder.decode(Double.self)
    bondValue = try decoder.decode(Double.self)
    
    bondAmbientOcclusion = try decoder.decode(Bool.self)
    
    // unit cell
    self.drawUnitCell = try decoder.decode(Bool.self)
    self.unitCellScaleFactor = try decoder.decode(Double.self)
    self.unitCellDiffuseColor = try decoder.decode(NSColor.self)
    self.unitCellDiffuseIntensity = try decoder.decode(Double.self)
    
    // adsorption surface
    self.drawAdsorptionSurface = try decoder.decode(Bool.self)
    self.adsorptionSurfaceOpacity = try decoder.decode(Double.self)
    self.adsorptionSurfaceIsoValue = try decoder.decode(Double.self)
    self.minimumGridEnergyValue = Float(try decoder.decode(Double.self))
    
    self.adsorptionSurfaceSize = try decoder.decode(Int.self)
    let _: Int = try decoder.decode(Int.self)  // numberOfTriangles
    
    self.adsorptionSurfaceProbeMolecule = try Structure.ProbeMolecule(rawValue: decoder.decode(Int.self))!
    
    
    
    self.adsorptionSurfaceFrontSideHDR = try decoder.decode(Bool.self)
    self.adsorptionSurfaceFrontSideHDRExposure = try decoder.decode(Double.self)
    self.adsorptionSurfaceFrontSideAmbientColor = try decoder.decode(NSColor.self)
    self.adsorptionSurfaceFrontSideDiffuseColor = try decoder.decode(NSColor.self)
    self.adsorptionSurfaceFrontSideSpecularColor = try decoder.decode(NSColor.self)
    self.adsorptionSurfaceFrontSideAmbientIntensity = try decoder.decode(Double.self)
    self.adsorptionSurfaceFrontSideDiffuseIntensity = try decoder.decode(Double.self)
    self.adsorptionSurfaceFrontSideSpecularIntensity = try decoder.decode(Double.self)
    self.adsorptionSurfaceFrontSideShininess = try decoder.decode(Double.self)
    
    self.adsorptionSurfaceBackSideHDR = try decoder.decode(Bool.self)
    self.adsorptionSurfaceBackSideHDRExposure = try decoder.decode(Double.self)
    self.adsorptionSurfaceBackSideAmbientColor = try decoder.decode(NSColor.self)
    self.adsorptionSurfaceBackSideDiffuseColor = try decoder.decode(NSColor.self)
    self.adsorptionSurfaceBackSideSpecularColor = try decoder.decode(NSColor.self)
    self.adsorptionSurfaceBackSideAmbientIntensity = try decoder.decode(Double.self)
    self.adsorptionSurfaceBackSideDiffuseIntensity = try decoder.decode(Double.self)
    self.adsorptionSurfaceBackSideSpecularIntensity = try decoder.decode(Double.self)
    self.adsorptionSurfaceBackSideShininess = try decoder.decode(Double.self)
    
   
    
    // Structure properties
    self.structureType = StructureType(rawValue: try decoder.decode(Int.self))!
    self.structureMaterialType = try decoder.decode(String.self)
    self.structureMass = try decoder.decode(Double.self)
    self.structureDensity = try decoder.decode(Double.self)
    self.structureHeliumVoidFraction = try decoder.decode(Double.self)
    self.structureSpecificVolume = try decoder.decode(Double.self)
    self.structureAccessiblePoreVolume = try decoder.decode(Double.self)
    self.structureVolumetricNitrogenSurfaceArea = try decoder.decode(Double.self)
    self.structureGravimetricNitrogenSurfaceArea = try decoder.decode(Double.self)
    self.structureNumberOfChannelSystems = try decoder.decode(Int.self)
    self.structureNumberOfInaccessiblePockets = try decoder.decode(Int.self)
    self.structureDimensionalityOfPoreSystem = try decoder.decode(Int.self)
    self.structureLargestCavityDiameter = try decoder.decode(Double.self)
    self.structureRestrictingPoreLimitingDiameter = try decoder.decode(Double.self)
    self.structureLargestCavityDiameterAlongAViablePath = try decoder.decode(Double.self)
    
    // Info
    self.authorFirstName = try decoder.decode(String.self)
    self.authorMiddleName = try decoder.decode(String.self)
    self.authorLastName = try decoder.decode(String.self)
    self.authorOrchidID = try decoder.decode(String.self)
    self.authorResearcherID = try decoder.decode(String.self)
    self.authorAffiliationUniversityName = try decoder.decode(String.self)
    self.authorAffiliationFacultyName = try decoder.decode(String.self)
    self.authorAffiliationInstituteName = try decoder.decode(String.self)
    self.authorAffiliationCityName = try decoder.decode(String.self)
    self.authorAffiliationCountryName = try decoder.decode(String.self)
        
    // Creation
    components.day = Int(try decoder.decode(UInt16.self))
    components.month = Int(try decoder.decode(UInt16.self))
    components.year = Int(try decoder.decode(UInt32.self))
    self.creationDate = calendar.date(from: components) ?? Date()
    self.creationTemperature = try decoder.decode(String.self)
    self.creationTemperatureScale = try TemperatureScale(rawValue: decoder.decode(Int.self))!
    self.creationPressure = try decoder.decode(String.self)
    self.creationPressureScale = try PressureScale(rawValue: decoder.decode(Int.self))!
    self.creationMethod = try CreationMethod(rawValue: decoder.decode(Int.self))!
    
    
    self.creationUnitCellRelaxationMethod = try UnitCellRelaxationMethod(rawValue: decoder.decode(Int.self))!
    self.creationAtomicPositionsSoftwarePackage = try decoder.decode(String.self)
    self.creationAtomicPositionsIonsRelaxationAlgorithm = try IonsRelaxationAlgorithm(rawValue: decoder.decode(Int.self))!
    self.creationAtomicPositionsIonsRelaxationCheck = try IonsRelaxationCheck(rawValue: decoder.decode(Int.self))!
    self.creationAtomicPositionsForcefield = try decoder.decode(String.self)
    self.creationAtomicPositionsForcefieldDetails = try decoder.decode(String.self)
    
    self.creationAtomicChargesSoftwarePackage = try decoder.decode(String.self)
    self.creationAtomicChargesAlgorithms = try decoder.decode(String.self)
    self.creationAtomicChargesForcefield = try decoder.decode(String.self)
    self.creationAtomicChargesForcefieldDetails = try decoder.decode(String.self)
    
   
    
    // Experimental
    self.experimentalMeasurementRadiation = try decoder.decode(String.self)
    self.experimentalMeasurementWaveLength = try decoder.decode(String.self)
    self.experimentalMeasurementThetaMin = try decoder.decode(String.self)
    self.experimentalMeasurementThetaMax = try decoder.decode(String.self)
    self.experimentalMeasurementIndexLimitsHmin = try decoder.decode(String.self)
    self.experimentalMeasurementIndexLimitsHmax = try decoder.decode(String.self)
    self.experimentalMeasurementIndexLimitsKmin = try decoder.decode(String.self)
    self.experimentalMeasurementIndexLimitsKmax = try decoder.decode(String.self)
    self.experimentalMeasurementIndexLimitsLmin = try decoder.decode(String.self)
    self.experimentalMeasurementIndexLimitsLmax = try decoder.decode(String.self)
    self.experimentalMeasurementNumberOfSymmetryIndependentReflections = try decoder.decode(String.self)
    self.experimentalMeasurementSoftware = try decoder.decode(String.self)
    self.experimentalMeasurementRefinementDetails = try decoder.decode(String.self)
    self.experimentalMeasurementGoodnessOfFit = try decoder.decode(String.self)
    self.experimentalMeasurementRFactorGt = try decoder.decode(String.self)
    self.experimentalMeasurementRFactorAll = try decoder.decode(String.self)
    
    // Chemical
    self.chemicalFormulaMoiety = try decoder.decode(String.self)
    self.chemicalFormulaSum = try decoder.decode(String.self)
    self.chemicalNameSystematic = try decoder.decode(String.self)
    self.cellFormulaUnitsZ = try decoder.decode(Int.self)
    
    
    // Citation
    self.citationArticleTitle = try decoder.decode(String.self)
    self.citationJournalTitle = try decoder.decode(String.self)
    self.citationAuthors = try decoder.decode(String.self)
    self.citationJournalVolume = try decoder.decode(String.self)
    self.citationJournalNumber = try decoder.decode(String.self)
    self.citationJournalPageNumbers = try decoder.decode(String.self)
    self.citationDOI = try decoder.decode(String.self)
    components.day = Int(try decoder.decode(UInt16.self))
    components.month = Int(try decoder.decode(UInt16.self))
    components.year = Int(try decoder.decode(UInt32.self))
    self.citationPublicationDate = calendar.date(from: components) ?? Date()
    self.citationDatebaseCodes = try decoder.decode(String.self)
    
    super.init()
    
    self.setRepresentationStyle(style: self.atomRepresentationStyle)
  }
  
}

