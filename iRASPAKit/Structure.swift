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

public class Structure: Object, AtomViewer, BondViewer, SKRenderAdsorptionSurfaceStructure, Cloning
{
  private static var classVersionNumber: Int = 9
  
  public var atomTreeController: SKAtomTreeController = SKAtomTreeController()
  public var bondSetController: SKBondSetController = SKBondSetController()
  
    /*
  // MARK: protocol RKRenderStructure implementation
  // =====================================================================
  public var displayName: String = "uninitialized"
  public var isVisible: Bool = true
   
     
     public var periodic: Bool = false
     
  public var origin: SIMD3<Double> = SIMD3<Double>(x: 0.0, y: 0.0, z: 0.0)
  public var orientation: simd_quatd = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
  
  public var cell: SKCell = SKCell()
  
  public func absoluteCartesianModelPosition(for position: SIMD3<Double>, replicaPosition: SIMD3<Int32>) -> SIMD3<Double>
  {
    return SIMD3<Double>()
  }
  
  public func absoluteCartesianScenePosition(for position: SIMD3<Double>, replicaPosition: SIMD3<Int32>) -> SIMD3<Double>
  {
    return SIMD3<Double>()
  }*/
  
  // MARK: protocol RKRenderAtomSource implementation
  // =====================================================================
  
  public var numberOfAtoms: Int
  {
    return self.atomTreeController.flattenedLeafNodes().count
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
  public var clipAtomsAtUnitCell: Bool {return false}
  
  public func filterCartesianAtomPositions(_ filter: (SIMD3<Double>) -> Bool) -> IndexSet
  {
    return []
  }
  
  public func filterCartesianBondPositions(_ filter: (SIMD3<Double>) -> Bool) -> IndexSet
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
      
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
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
  public var atomSelectionIntensity: Double = 0.5
  
  // MARK: protocol RKRenderBondSource implementation
  // =====================================================================
  
  public var numberOfInternalBonds: Int
  {
    return self.bondSetController.arrangedObjects.flatMap{$0.copies}.filter{$0.boundaryType == .internal}.count
  }
  
  public var numberOfExternalBonds: Int
  {
    return self.bondSetController.arrangedObjects.flatMap{$0.copies}.filter{$0.boundaryType == .external}.count
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
  
  public var clipBondsAtUnitCell: Bool {return false}
  
  public var bondHue: Double = 1.0
  public var bondSaturation: Double = 1.0
  public var bondValue: Double = 1.0
  
  public var bondSelectionStyle: RKSelectionStyle = .WorleyNoise3D
  public var bondSelectionScaling: Double = 1.2
  public var bondSelectionStripesDensity: Double = 0.25
  public var bondSelectionStripesFrequency: Double = 12.0
  public var bondSelectionWorleyNoise3DFrequency: Double = 2.0
  public var bondSelectionWorleyNoise3DJitter: Double = 1.0
  public var bondSelectionIntensity: Double = 0.5
  
  
 
   
  // MARK: protocol RKRenderAdsorptionSurfaceSource implementation
  // =====================================================================
  
  public var adsorptionSurfaceProbeMolecule: ProbeMolecule = .helium
  
  public var potentialParameters: [SIMD2<Double>] {return []}
  
  public var drawAdsorptionSurface: Bool = false
  
  public var adsorptionSurfaceRenderingMethod: RKEnergySurfaceType = RKEnergySurfaceType.isoSurface // NEW
  public var adsorptionVolumeTransferFunction: RKPredefinedVolumeRenderingTransferFunction = RKPredefinedVolumeRenderingTransferFunction.default
  public var adsorptionVolumeStepLength: Double = 0.0005
  
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
  
  public var adsorptionSurfaceHue = 1.0;
  public var adsorptionSurfaceSaturation = 1.0;
  public var adsorptionSurfaceValue = 1.0;
  
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
  
  // Can be be removed in a future version, only here for legacy file-reading purposes
  
  public var primitiveTransformationMatrix: double3x3 = double3x3(1.0)
  public var primitiveOrientation: simd_quatd = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
  public var primitiveRotationDelta: Double = 5.0
  
  public var primitiveOpacity: Double = 1.0
  public var primitiveIsCapped: Bool = false
  public var primitiveIsFractional: Bool = true
  public var primitiveNumberOfSides: Int = 6
  public var primitiveThickness: Double = 0.05
  
  public var primitiveHue: Double = 1.0
  public var primitiveSaturation: Double = 1.0
  public var primitiveValue: Double = 1.0
  
  public var primitiveSelectionStyle: RKSelectionStyle = .striped
  public var primitiveSelectionScaling: Double = 1.0
  public var primitiveSelectionStripesDensity: Double = 0.25
  public var primitiveSelectionStripesFrequency: Double = 12.0
  public var primitiveSelectionWorleyNoise3DFrequency: Double = 2.0
  public var primitiveSelectionWorleyNoise3DJitter: Double = 1.0
  public var primitiveSelectionIntensity: Double = 1.0
  
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
  
  public var isFractional: Bool
  {
    return false
  }
  
  public var legacySpaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: 1)
  
  public var materialType: SKStructure.Kind
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
  public var atomColorSchemeOrder: SKColorSets.ColorOrder = .elementOnly
  
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
  
  public override init()
  {
    super.init()
  }
  
  public init(name: String)
  {
    super.init()
    self.displayName = name
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
   //self.spaceGroup = original.spaceGroup
    
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
    
    self.primitiveHue = original.primitiveHue
    self.primitiveSaturation = original.primitiveSaturation
    self.primitiveValue = original.primitiveValue
    
    self.primitiveSelectionStyle = original.primitiveSelectionStyle
    self.primitiveSelectionScaling = original.primitiveSelectionScaling
    self.primitiveSelectionStripesDensity = original.primitiveSelectionStripesDensity
    self.primitiveSelectionStripesFrequency = original.primitiveSelectionStripesFrequency
    self.primitiveSelectionWorleyNoise3DFrequency = original.primitiveSelectionWorleyNoise3DFrequency
    self.primitiveSelectionWorleyNoise3DJitter = original.primitiveSelectionWorleyNoise3DJitter
    self.primitiveSelectionIntensity = original.primitiveSelectionIntensity
    
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
    self.atomTreeController = SKAtomTreeController()

    self.drawAtoms = original.drawAtoms
    
    self.atomRepresentationType = original.atomRepresentationType
    self.atomRepresentationStyle = original.atomRepresentationStyle
    self.atomForceFieldIdentifier = original.atomForceFieldIdentifier
    self.atomForceFieldOrder = original.atomForceFieldOrder
    self.atomColorSchemeIdentifier = original.atomColorSchemeIdentifier
    self.atomColorSchemeOrder = original.atomColorSchemeOrder
    
    self.atomSelectionStyle = original.atomSelectionStyle
    self.atomSelectionStripesDensity = original.atomSelectionStripesDensity
    self.atomSelectionStripesFrequency = original.atomSelectionStripesFrequency
    self.atomSelectionWorleyNoise3DFrequency = original.atomSelectionWorleyNoise3DFrequency
    self.atomSelectionWorleyNoise3DJitter = original.atomSelectionWorleyNoise3DJitter
    self.atomSelectionScaling = original.atomSelectionScaling
    self.atomSelectionIntensity = original.atomSelectionIntensity
    
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
    self.atomSelectionIntensity = original.atomSelectionIntensity
    
    self.atomAmbientColor = original.atomAmbientColor
    self.atomDiffuseColor = original.atomDiffuseColor
    self.atomSpecularColor = original.atomSpecularColor
    self.atomAmbientIntensity = original.atomAmbientIntensity
    self.atomDiffuseIntensity = original.atomDiffuseIntensity
    self.atomSpecularIntensity = original.atomSpecularIntensity
    self.atomShininess = original.atomShininess
    
    
    // bonds
    self.bondSetController = SKBondSetController()
    
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
    
    self.bondSelectionStyle = original.bondSelectionStyle
    self.bondSelectionStripesDensity = original.bondSelectionStripesDensity
    self.bondSelectionStripesFrequency = original.bondSelectionStripesFrequency
    self.bondSelectionWorleyNoise3DFrequency = original.bondSelectionWorleyNoise3DFrequency
    self.bondSelectionWorleyNoise3DJitter = original.bondSelectionWorleyNoise3DJitter
    self.bondSelectionScaling = original.bondSelectionScaling
    self.bondSelectionIntensity = original.bondSelectionIntensity
    
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
    //self.spaceGroup = clone.spaceGroup
    
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
    
    self.primitiveHue = clone.primitiveHue
    self.primitiveSaturation = clone.primitiveSaturation
    self.primitiveValue = clone.primitiveValue
    
    self.primitiveSelectionStyle = clone.primitiveSelectionStyle
    self.primitiveSelectionScaling = clone.primitiveSelectionScaling
    self.primitiveSelectionStripesDensity = clone.primitiveSelectionStripesDensity
    self.primitiveSelectionStripesFrequency = clone.primitiveSelectionStripesFrequency
    self.primitiveSelectionWorleyNoise3DFrequency = clone.primitiveSelectionWorleyNoise3DFrequency
    self.primitiveSelectionWorleyNoise3DJitter = clone.primitiveSelectionWorleyNoise3DJitter
    self.primitiveSelectionIntensity = clone.primitiveSelectionIntensity
    
    
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
    self.atomColorSchemeOrder = clone.atomColorSchemeOrder
    
    self.atomSelectionStyle = clone.atomSelectionStyle
    self.atomSelectionStripesDensity = clone.atomSelectionStripesDensity
    self.atomSelectionStripesFrequency = clone.atomSelectionStripesFrequency
    self.atomSelectionWorleyNoise3DFrequency = clone.atomSelectionWorleyNoise3DFrequency
    self.atomSelectionWorleyNoise3DJitter = clone.atomSelectionWorleyNoise3DJitter
    self.atomSelectionScaling = clone.atomSelectionScaling
    self.atomSelectionIntensity = clone.atomSelectionIntensity
    
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
    self.atomSelectionIntensity = clone.atomSelectionIntensity
    
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
    self.bondSelectionIntensity = clone.bondSelectionIntensity
    
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
    clone.atomTreeController.tag()
    
    let binaryAtomEncoder: BinaryEncoder = BinaryEncoder()
    binaryAtomEncoder.encode(clone.atomTreeController)
    let atomData: Data = Data(binaryAtomEncoder.data)
    
    let binaryBondEncoder: BinaryEncoder = BinaryEncoder()
    binaryBondEncoder.encode(clone.bondSetController)
    let bondData: Data = Data(binaryBondEncoder.data)
    
    do
    {
      self.atomTreeController = try BinaryDecoder(data: [UInt8](atomData)).decode(SKAtomTreeController.self)
      self.bondSetController = try BinaryDecoder(data: [UInt8](bondData)).decode(SKBondSetController.self)
      
      self.bondSetController.restoreBonds(atomTreeController: self.atomTreeController)
    }
    catch
    {
      debugPrint("Error")
    }
    
    // clone atoms and bonds
    clone.bondSetController.tag()
    
    //restore selection
    let tags: Set<Int> = Set(clone.atomTreeController.selectedTreeNodes.map{$0.representedObject.tag})
    let atomTreeNodes: [SKAtomTreeNode] = self.atomTreeController.flattenedLeafNodes()
    self.atomTreeController.selectedTreeNodes = Set(atomTreeNodes.filter{tags.contains($0.representedObject.tag)})
    self.bondSetController.selectedObjects = clone.bondSetController.selectedObjects
    
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
    let asymmetricAtoms: [SKAsymmetricAtom] = atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    setRepresentationColorScheme(colorSet: colorSet, for: asymmetricAtoms)
  }

  public func setRepresentationColorScheme(colorSet: SKColorSet, for asymmetricAtoms: [SKAsymmetricAtom])
  {
    for asymmetricAtom in asymmetricAtoms
    {
      let uniqueForceFieldName: String = asymmetricAtom.uniqueForceFieldName
      let chemicalElement: String = PredefinedElements.sharedInstance.elementSet[asymmetricAtom.elementIdentifier].chemicalSymbol
        
      switch(self.atomColorSchemeOrder)
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
      return self.atomColorSchemeOrder
  }
  
  public func setRepresentationColorOrder(order: SKColorSets.ColorOrder?, colorSets: SKColorSets)
  {
    if let order = order
    {
      self.atomColorSchemeOrder = order
      
      let asymmetricAtoms: [SKAsymmetricAtom] = atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
      for asymmetricAtom in asymmetricAtoms
      {
        if let colorSet: SKColorSet = colorSets[self.atomColorSchemeIdentifier]
        {
          let uniqueForceFieldName: String = asymmetricAtom.uniqueForceFieldName
          let chemicalElement: String = PredefinedElements.sharedInstance.elementSet[asymmetricAtom.elementIdentifier].chemicalSymbol
        
          switch(self.atomColorSchemeOrder)
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
  
  public func applyRepresentationColorOrder(colorSets: SKColorSets)
  {
    setRepresentationColorOrder(order: atomColorSchemeOrder, colorSets: colorSets)
  }
  
  
  
  public func unknownForceFieldNames(forceField: String, forceFieldSets: SKForceFieldSets) -> [String]
  {
    if let forceFieldSet: SKForceFieldSet = forceFieldSets[forceField]
    {
      let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    
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
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    
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
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
        
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
  
  
  public func applyRepresentationForceField(forceFieldSets: SKForceFieldSets)
  {
    setRepresentationForceField(forceField: atomForceFieldIdentifier, forceFieldSets: forceFieldSets)
  }
  
  public func getRepresentationStyle() -> Structure.RepresentationStyle?
  {
    return atomRepresentationStyle
  }
  
  public func setRepresentationStyle(style: Structure.RepresentationStyle?)
  {
    let asymmetricAtoms: [SKAsymmetricAtom] = atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    self.setRepresentationStyle(style: style, for: asymmetricAtoms)
  }
  
  public func applyRepresentationStyle()
  {
    let asymmetricAtoms: [SKAsymmetricAtom] = atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    self.setRepresentationStyle(style: atomRepresentationStyle, for: asymmetricAtoms)
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
        self.drawAtoms = true
        self.atomAmbientOcclusion = false
        self.atomScaleFactor = 0.7
        self.atomHue = 1.0
        self.atomSaturation = 1.0
        self.atomValue = 1.0
        self.atomAmbientColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.atomSpecularColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.atomHDR = true
        self.atomHDRExposure = 1.5
        self.atomAmbientIntensity = 0.2
        self.atomDiffuseIntensity = 1.0
        self.atomSpecularIntensity = 1.0
        self.atomShininess = 6.0
        self.atomForceFieldIdentifier = "Default"
        self.atomColorSchemeIdentifier = SKColorSets.ColorScheme.jmol.rawValue
        self.atomColorSchemeOrder = .elementOnly
        
        self.drawBonds = true
        self.bondAmbientOcclusion = false
        self.bondColorMode = .uniform
        self.bondScaleFactor = 0.15
        self.bondAmbientColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.bondDiffuseColor = NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        self.bondSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.bondAmbientIntensity = 0.35
        self.bondDiffuseIntensity = 1.0
        self.bondSpecularIntensity = 1.0
        self.bondShininess = 4.0
        self.bondHDR = true
        self.bondHDRExposure = 1.5
        self.bondHue = 1.0
        self.bondSaturation = 1.0
        self.bondValue = 1.0
        
        self.atomSelectionStyle = .striped
        self.atomSelectionScaling = 1.0
        self.atomSelectionIntensity = 0.7
        self.atomSelectionStripesDensity = 0.25
        self.atomSelectionStripesFrequency = 12.0
        
        self.bondSelectionStyle = .striped
        self.bondSelectionScaling = 1.0
        self.bondSelectionIntensity = 0.7
        self.bondSelectionStripesDensity = 0.25
        self.bondSelectionStripesFrequency = 12.0
        
        self.setRepresentationType(type: .sticks_and_balls)
      case .fancy:
        self.drawAtoms = true
        self.atomAmbientOcclusion = true
        self.atomHue = 1.0
        self.atomScaleFactor = 1.0
        self.atomSaturation = 0.5
        self.atomValue = 1.0
        self.atomAmbientColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.atomSpecularColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.atomHDR = false
        self.atomAmbientIntensity = 1.0
        self.atomDiffuseIntensity = 0.0
        self.atomSpecularIntensity = 0.2
        self.atomShininess = 4.0
        self.atomScaleFactor = 1.0
        self.atomForceFieldIdentifier = "Default"
        self.atomColorSchemeIdentifier = SKColorSets.ColorScheme.rasmol.rawValue
        self.atomColorSchemeOrder = .elementOnly
        
        self.drawBonds = false
        self.bondAmbientOcclusion = false
        
        self.atomSelectionStyle = .striped
        self.atomSelectionScaling = 1.0
        self.atomSelectionIntensity = 0.4
        self.atomSelectionStripesDensity = 0.25
        self.atomSelectionStripesFrequency = 12.0
        
        self.bondSelectionStyle = .striped
        self.bondSelectionScaling = 1.0
        self.bondSelectionIntensity = 0.4
        self.bondSelectionStripesDensity = 0.25
        self.bondSelectionStripesFrequency = 12.0
        
        self.setRepresentationType(type: .vdw)
      case .licorice:
        self.drawAtoms = true
        self.atomAmbientOcclusion = false
        self.atomHue = 1.0
        self.atomSaturation = 1.0
        self.atomValue = 1.0
        self.atomAmbientColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.atomSpecularColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.atomAmbientIntensity = 0.1
        self.atomDiffuseIntensity = 1.0
        self.atomSpecularIntensity = 1.0
        self.atomShininess = 4.0
        self.atomHDR = true
        self.atomHDRExposure = 1.5
        self.atomScaleFactor = 1.0
        self.atomForceFieldIdentifier = "Default"
        self.atomColorSchemeIdentifier = SKColorSets.ColorScheme.jmol.rawValue
        self.atomColorSchemeOrder = .elementOnly
        
        self.drawBonds = true
        self.bondAmbientOcclusion = false
        self.bondColorMode = .split
        self.bondScaleFactor = 0.25
        self.bondAmbientColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.bondDiffuseColor = NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        self.bondSpecularColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.bondAmbientIntensity = 0.1
        self.bondDiffuseIntensity = 1.0
        self.bondSpecularIntensity = 1.0
        self.bondShininess = 4.0
        self.bondHDR = true
        self.bondHDRExposure = 1.5
        self.bondSelectionIntensity = 0.5
        self.bondHue = 1.0
        self.bondSaturation = 1.0
        self.bondValue = 1.0
        
        self.atomSelectionStyle = .striped
        self.atomSelectionScaling = 1.0
        self.atomSelectionIntensity = 0.8
        self.atomSelectionStripesDensity = 0.25
        self.atomSelectionStripesFrequency = 12.0
               
        self.bondSelectionStyle = .striped
        self.bondSelectionScaling = 1.0
        self.bondSelectionIntensity = 0.8
        self.bondSelectionStripesDensity = 0.25
        self.bondSelectionStripesFrequency = 12.0
        
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
        atomColorSchemeOrder = .elementOnly
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
    if self.drawAtoms == true &&
       (self.atomHue ==~ 1.0) &&
       (self.atomSaturation ==~ 1.0) &&
       (self.atomValue ==~ 1.0) &&
       ((self.atomAmbientColor.redComponent - 1.0) < 1e-3) &&
       ((self.atomAmbientColor.greenComponent - 1.0) < 1e-3) &&
       ((self.atomAmbientColor.blueComponent - 1.0) < 1e-3) &&
       ((self.atomAmbientColor.alphaComponent - 1.0) < 1e-3) &&
       ((self.atomSpecularColor.redComponent - 1.0) < 1e-3) &&
       ((self.atomSpecularColor.greenComponent - 1.0) < 1e-3) &&
       ((self.atomSpecularColor.blueComponent - 1.0) < 1e-3) &&
       ((self.atomSpecularColor.alphaComponent - 1.0) < 1e-3) &&
       self.atomHDR == true &&
       (self.atomHDRExposure ==~ 1.5) &&
       self.atomAmbientOcclusion == false &&
       (self.atomAmbientIntensity ==~ 0.2) &&
       (self.atomDiffuseIntensity ==~ 1.0) &&
       (self.atomSpecularIntensity ==~ 1.0) &&
       (self.atomShininess ==~ 6.0) &&
       (self.atomScaleFactor ==~ 0.7) &&
       self.atomRepresentationType == .sticks_and_balls &&
       self.atomForceFieldIdentifier == "Default" &&
       self.atomColorSchemeIdentifier == SKColorSets.ColorScheme.jmol.rawValue &&
       self.atomColorSchemeOrder == .elementOnly &&
       self.drawBonds == true &&
       self.bondColorMode == .uniform &&
       (self.bondScaleFactor ==~ 0.15) &&
       self.bondAmbientOcclusion == false &&
       self.bondHDR == true &&
       (self.bondHDRExposure ==~ 1.5) &&
      ((self.bondAmbientColor.redComponent - 1.0) < 1e-3) &&
      ((self.bondAmbientColor.greenComponent - 1.0) < 1e-3) &&
      ((self.bondAmbientColor.blueComponent - 1.0) < 1e-3) &&
      ((self.bondAmbientColor.alphaComponent - 1.0) < 1e-3) &&
      ((self.bondDiffuseColor.redComponent - 0.8) < 1e-3) &&
      ((self.bondDiffuseColor.greenComponent - 0.8) < 1e-3) &&
      ((self.bondDiffuseColor.blueComponent - 0.8) < 1e-3) &&
      ((self.bondDiffuseColor.alphaComponent - 1.0) < 1e-3) &&
      ((self.bondSpecularColor.redComponent - 1.0) < 1e-3) &&
      ((self.bondSpecularColor.greenComponent - 1.0) < 1e-3) &&
      ((self.bondSpecularColor.blueComponent - 1.0) < 1e-3) &&
      ((self.bondSpecularColor.alphaComponent - 1.0) < 1e-3) &&
       (self.bondAmbientIntensity ==~  0.35) &&
       (self.bondDiffuseIntensity ==~  1.0) &&
       (self.bondSpecularIntensity ==~  1.0) &&
       (self.bondShininess ==~  4.0) &&
       (self.bondHue ==~  1.0) &&
       (self.bondSaturation ==~  1.0) &&
       (self.bondValue ==~  1.0)  &&
      self.atomSelectionStyle == .striped &&
      (self.atomSelectionScaling ==~ 1.0)  &&
      (self.atomSelectionIntensity ==~ 0.7)  &&
      (self.atomSelectionStripesDensity ==~ 0.25) &&
      (self.atomSelectionStripesFrequency ==~ 12.0) &&
      self.bondSelectionStyle == .striped &&
      (self.bondSelectionScaling ==~ 1.0) &&
      (self.bondSelectionIntensity ==~ 0.7) &&
      (self.bondSelectionStripesDensity ==~ 0.25) &&
      (self.bondSelectionStripesFrequency ==~ 12.0)
    {
      self.atomRepresentationStyle = .default
    }
    else if (self.atomHue ==~ 1.0) &&
       (self.atomSaturation ==~ 0.5) &&
       (self.atomValue ==~ 1.0) &&
       ((self.atomAmbientColor.redComponent - 1.0) < 1e-3) &&
       ((self.atomAmbientColor.greenComponent - 1.0) < 1e-3) &&
       ((self.atomAmbientColor.blueComponent - 1.0) < 1e-3) &&
       ((self.atomAmbientColor.alphaComponent - 1.0) < 1e-3) &&
       ((self.atomSpecularColor.redComponent - 1.0) < 1e-3) &&
       ((self.atomSpecularColor.greenComponent - 1.0) < 1e-3) &&
       ((self.atomSpecularColor.blueComponent - 1.0) < 1e-3) &&
       ((self.atomSpecularColor.alphaComponent - 1.0) < 1e-3) &&
       self.drawAtoms == true &&
       self.drawBonds == false &&
       self.atomHDR == false &&
       self.atomAmbientOcclusion == true &&
       self.bondAmbientOcclusion == false &&
       (self.atomAmbientIntensity ==~ 1.0) &&
       (self.atomDiffuseIntensity ==~ 0.0) &&
       (self.atomSpecularIntensity ==~ 0.2) &&
       (self.atomShininess ==~ 4.0) &&
       (self.atomScaleFactor ==~ 1.0) &&
       self.atomRepresentationType == .vdw &&
       self.atomForceFieldIdentifier == "Default" &&
       self.atomColorSchemeIdentifier == SKColorSets.ColorScheme.rasmol.rawValue &&
       self.atomColorSchemeOrder == .elementOnly &&
      self.atomSelectionStyle == .striped &&
      (self.atomSelectionScaling ==~ 1.0)  &&
      (self.atomSelectionIntensity ==~ 0.4)  &&
      (self.atomSelectionStripesDensity ==~ 0.25) &&
      (self.atomSelectionStripesFrequency ==~ 12.0) &&
      self.bondSelectionStyle == .striped &&
      (self.bondSelectionScaling ==~ 1.0) &&
      (self.bondSelectionIntensity ==~ 0.4) &&
      (self.bondSelectionStripesDensity ==~ 0.25) &&
      (self.bondSelectionStripesFrequency ==~ 12.0)
    {
      self.atomRepresentationStyle = .fancy
    }
    else if self.drawAtoms == true &&
      (self.atomHue ==~ 1.0) &&
      (self.atomSaturation ==~ 1.0) &&
      (self.atomValue ==~ 1.0) &&
      self.atomRepresentationType == .unity &&
      self.atomForceFieldIdentifier == "Default" &&
      self.atomColorSchemeIdentifier == SKColorSets.ColorScheme.jmol.rawValue &&
      self.atomColorSchemeOrder == .elementOnly &&
      (self.atomScaleFactor ==~ 1.0) &&
      self.atomHDR == true &&
      (self.atomHDRExposure ==~ 1.5) &&
      self.atomAmbientOcclusion == false &&
      (self.atomAmbientIntensity ==~ 0.1) &&
      (self.atomDiffuseIntensity ==~ 1.0) &&
      (self.atomSpecularIntensity ==~ 1.0) &&
      (self.atomShininess ==~ 4.0) &&
      self.drawBonds == true &&
      self.bondColorMode == .split &&
      (self.bondScaleFactor ==~ 0.25) &&
      self.bondAmbientOcclusion == false &&
      self.bondHDR == true &&
      (self.bondHDRExposure ==~ 1.5) &&
      ((self.bondAmbientColor.redComponent - 1.0) < 1e-3) &&
      ((self.bondAmbientColor.greenComponent - 1.0) < 1e-3) &&
      ((self.bondAmbientColor.blueComponent - 1.0) < 1e-3) &&
      ((self.bondAmbientColor.alphaComponent - 1.0) < 1e-3) &&
      ((self.bondDiffuseColor.redComponent - 0.8) < 1e-3) &&
      ((self.bondDiffuseColor.greenComponent - 0.8) < 1e-3) &&
      ((self.bondDiffuseColor.blueComponent - 0.8) < 1e-3) &&
      ((self.bondDiffuseColor.alphaComponent - 1.0) < 1e-3) &&
      ((self.bondSpecularColor.redComponent - 1.0) < 1e-3) &&
      ((self.bondSpecularColor.greenComponent - 1.0) < 1e-3) &&
      ((self.bondSpecularColor.blueComponent - 1.0) < 1e-3) &&
      ((self.bondSpecularColor.alphaComponent - 1.0) < 1e-3) &&
      (self.bondAmbientIntensity ==~  0.1) &&
      (self.bondDiffuseIntensity ==~  1.0) &&
      (self.bondSpecularIntensity ==~  1.0) &&
      (self.bondShininess ==~  4.0) &&
      (self.bondHue ==~  1.0) &&
      (self.bondSaturation ==~  1.0) &&
      (self.bondValue ==~  1.0) &&
      self.atomSelectionStyle == .striped &&
      (self.atomSelectionScaling ==~ 1.0)  &&
      (self.atomSelectionIntensity ==~ 0.8)  &&
      (self.atomSelectionStripesDensity ==~ 0.25) &&
      (self.atomSelectionStripesFrequency ==~ 12.0) &&
      self.bondSelectionStyle == .striped &&
      (self.bondSelectionScaling ==~ 1.0) &&
      (self.bondSelectionIntensity ==~ 0.8) &&
      (self.atomSelectionStripesDensity ==~ 0.25) &&
      (self.atomSelectionStripesFrequency ==~ 12.0)
    {
      self.atomRepresentationStyle = .licorice
    }
    else if self.drawAtoms == true &&
      self.atomRepresentationType == .unity &&
      self.atomForceFieldIdentifier == "Default" &&
      self.atomColorSchemeIdentifier == SKColorSets.ColorScheme.jmol.rawValue &&
      self.atomColorSchemeOrder == .elementOnly &&
      (self.atomScaleFactor ==~ 1.0) &&
      self.atomAmbientOcclusion == false &&
      (self.atomAmbientIntensity ==~ 0.1) &&
      (self.atomDiffuseIntensity ==~ 0.6) &&
      (self.atomSpecularIntensity ==~ 0.1) &&
      (self.atomShininess ==~ 4.0)
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
      
      let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    
      switch(type)
      {
      case .sticks_and_balls:
        asymmetricAtoms.forEach{$0.drawRadius = PredefinedElements.sharedInstance.elementSet[$0.elementIdentifier].covalentRadius}
        self.atomScaleFactor = 0.7
        self.bondScaleFactor = 0.15
      case .vdw:
        self.atomScaleFactor = 1.0
        self.bondScaleFactor = 0.15
        asymmetricAtoms.forEach{$0.drawRadius = PredefinedElements.sharedInstance.elementSet[$0.elementIdentifier].VDWRadius}
      case .unity:
        self.atomScaleFactor = 1.0
        self.bondScaleFactor = 0.25
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
        self.atomScaleFactor = 0.7
        self.bondScaleFactor = 0.15
      case .vdw:
        self.atomScaleFactor = 1.0
        self.bondScaleFactor = 0.15
        asymmetricAtoms.forEach{$0.drawRadius = PredefinedElements.sharedInstance.elementSet[$0.elementIdentifier].VDWRadius}
      case .unity:
        self.atomScaleFactor = 1.0
        self.bondScaleFactor = 0.25
        asymmetricAtoms.forEach{$0.drawRadius = bondScaleFactor}
      }
    }
  }
  
  public var isUnity: Bool
  {
    return self.atomRepresentationType == .unity
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
  
  // MARK: Measuring distance, angle, and dihedral-angles
  // =====================================================================
  
  public func bondVector(_ bond: SKBondNode) -> SIMD3<Double>
  {
    let atom1: SIMD3<Double> = bond.atom1.position
    let atom2: SIMD3<Double> = bond.atom2.position
    let dr: SIMD3<Double> = atom2 - atom1
    return dr
  }
  
  public func asymmetricBondVector(_ bond: SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>) -> SIMD3<Double>
  {
    let atom1: SIMD3<Double> = bond.atom1.position
    let atom2: SIMD3<Double> = bond.atom2.position
    let dr: SIMD3<Double> = atom2 - atom1
    return dr
  }
  
  public func asymmetricBondLength(_ asymmetricBond: SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>) -> Double
  {
    let atom1: SIMD3<Double> = asymmetricBond.atom1.position
    let atom2: SIMD3<Double> = asymmetricBond.atom2.position
    let dr: SIMD3<Double> = abs(atom2 - atom1)
    return length(dr)
  }
  
  public func bondLength(_ bond: SKBondNode) -> Double
  {
    let atom1: SIMD3<Double> = bond.atom1.position
    let atom2: SIMD3<Double> = bond.atom2.position
    let dr: SIMD3<Double> = abs(atom2 - atom1)
    return length(dr)
  }
  
  public func bendAngle(_ atomA: SKAtomCopy, _ atomB: SKAtomCopy, _ atomC:SKAtomCopy) -> Double
   {
     let posA: SIMD3<Double> = atomA.position
     let posB: SIMD3<Double> = atomB.position
     let posC: SIMD3<Double> = atomC.position
     
     let dr1: SIMD3<Double> = posA - posB
     let dr2: SIMD3<Double> = posC - posB
     
     let vectorAB: SIMD3<Double> = normalize(dr1)
     let vectorBC: SIMD3<Double> = normalize(dr2)
     
     return acos(dot(vectorAB, vectorBC))
   }
  
  public static func distance(_ atom1: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>), _ atom2: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>)) -> (Double, Double?)
  {
    var periodicLength: Double? = nil
    if(atom1.structure === atom2.structure && atom1.structure.periodic)
    {
      // Don't rotate, because for distances in the same structure we need to apply the periodic boundary conditions.
      // The rotation would be the same anyway, but applyFullCellBoundaryCondition can only be applied in the unrotated frame.
      let cartesianPosition1 = atom1.structure.absoluteCartesianModelPosition(for: atom1.copy.position, replicaPosition: atom1.replicaPosition)
      let cartesianPosition2 = atom2.structure.absoluteCartesianModelPosition(for: atom2.copy.position, replicaPosition: atom2.replicaPosition)
      periodicLength = length(atom1.structure.cell.applyFullCellBoundaryCondition(cartesianPosition2 - cartesianPosition1))
    }
    
    let absoluteCartesianPosition1 = atom1.structure.absoluteCartesianScenePosition(for: atom1.copy.position, replicaPosition: atom1.replicaPosition)
    let absoluteCartesianPosition2 = atom2.structure.absoluteCartesianScenePosition(for: atom2.copy.position, replicaPosition: atom2.replicaPosition)
        
    return (length(absoluteCartesianPosition2 - absoluteCartesianPosition1), periodicLength)
  }
  
  public static func bendAngle(_ atomA: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>), _ atomB: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>), _ atomC: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>)) -> (Double, Double?)
  {
    var periodicAngle: Double? = nil
    if((atomA.structure === atomB.structure) && (atomB.structure === atomC.structure) && atomA.structure.periodic)
    {
      // Don't rotate, because for distances in the same structure we need to apply the periodic boundary conditions.
      // The rotation would be the same anyway, but applyFullCellBoundaryCondition can only be applied in the unrotated frame.
      let cartesianPositionA: SIMD3<Double> = atomA.structure.absoluteCartesianModelPosition(for: atomA.copy.position, replicaPosition: atomA.replicaPosition)
      let cartesianPositionB: SIMD3<Double> = atomB.structure.absoluteCartesianModelPosition(for: atomB.copy.position, replicaPosition: atomB.replicaPosition)
      let cartesianPositionC: SIMD3<Double> = atomC.structure.absoluteCartesianModelPosition(for: atomC.copy.position, replicaPosition: atomC.replicaPosition)
      let dr1: SIMD3<Double> = atomA.structure.cell.applyFullCellBoundaryCondition(cartesianPositionA - cartesianPositionB)
      let dr2: SIMD3<Double> = atomA.structure.cell.applyFullCellBoundaryCondition(cartesianPositionC - cartesianPositionB)
      
      let vectorAB: SIMD3<Double> = normalize(dr1)
      let vectorBC: SIMD3<Double> = normalize(dr2)
      
      periodicAngle =  acos(dot(vectorAB, vectorBC))
    }

    let cartesianPositionA: SIMD3<Double> = atomA.structure.absoluteCartesianScenePosition(for: atomA.copy.position, replicaPosition: atomA.replicaPosition)
    let cartesianPositionB: SIMD3<Double> = atomB.structure.absoluteCartesianScenePosition(for: atomB.copy.position, replicaPosition: atomB.replicaPosition)
    let cartesianPositionC: SIMD3<Double> = atomC.structure.absoluteCartesianScenePosition(for: atomC.copy.position, replicaPosition: atomC.replicaPosition)
    let dr1: SIMD3<Double> = cartesianPositionA - cartesianPositionB
    let dr2: SIMD3<Double> = cartesianPositionC - cartesianPositionB
    
    let vectorAB: SIMD3<Double> = normalize(dr1)
    let vectorBC: SIMD3<Double> = normalize(dr2)
    
    return (acos(dot(vectorAB, vectorBC)), periodicAngle)
  }
  
  public static func dihedralAngle(_ atomA: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>), _ atomB: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>), _ atomC: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>), _ atomD: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: SIMD3<Int32>)) -> (Double, Double?)
  {
    var periodicAngle: Double? = nil
    if((atomA.structure === atomB.structure) && (atomB.structure === atomC.structure) && atomA.structure.periodic)
    {
      // Don't rotate, because for distances in the same structure we need to apply the periodic boundary conditions.
      // The rotation would be the same anyway, but applyFullCellBoundaryCondition can only be applied in the unrotated frame.
      let cartesianPositionA: SIMD3<Double> = atomA.structure.absoluteCartesianModelPosition(for: atomA.copy.position, replicaPosition: atomA.replicaPosition)
      let cartesianPositionB: SIMD3<Double> = atomB.structure.absoluteCartesianModelPosition(for: atomB.copy.position, replicaPosition: atomB.replicaPosition)
      let cartesianPositionC: SIMD3<Double> = atomC.structure.absoluteCartesianModelPosition(for: atomC.copy.position, replicaPosition: atomC.replicaPosition)
      let cartesianPositionD: SIMD3<Double> = atomD.structure.absoluteCartesianModelPosition(for: atomD.copy.position, replicaPosition: atomD.replicaPosition)
      let dr1: SIMD3<Double> = cartesianPositionA - cartesianPositionB
      let dr2: SIMD3<Double> = cartesianPositionC - cartesianPositionB
      let dr3: SIMD3<Double> = cartesianPositionD - cartesianPositionC
      
      let Dab: SIMD3<Double> = atomA.structure.cell.applyFullCellBoundaryCondition(dr1)
      let Dbc: SIMD3<Double> = atomA.structure.cell.applyFullCellBoundaryCondition(dr2)
      let Dcd: SIMD3<Double> = atomA.structure.cell.applyFullCellBoundaryCondition(dr3)
      
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
        periodicAngle = Phi + 2.0*Double.pi
      }
      periodicAngle = Phi
    }
    
    // Don't rotate, because for distances in the same structure we need to apply the periodic boundary conditions.
    // The rotation would be the same anyway, but applyFullCellBoundaryCondition can only be applied in the unrotated frame.
    let cartesianPositionA: SIMD3<Double> = atomA.structure.absoluteCartesianScenePosition(for: atomA.copy.position, replicaPosition: atomA.replicaPosition)
    let cartesianPositionB: SIMD3<Double> = atomB.structure.absoluteCartesianScenePosition(for: atomB.copy.position, replicaPosition: atomB.replicaPosition)
    let cartesianPositionC: SIMD3<Double> = atomC.structure.absoluteCartesianScenePosition(for: atomC.copy.position, replicaPosition: atomC.replicaPosition)
    let cartesianPositionD: SIMD3<Double> = atomD.structure.absoluteCartesianScenePosition(for: atomD.copy.position, replicaPosition: atomD.replicaPosition)
    
    let Dab: SIMD3<Double> = cartesianPositionA - cartesianPositionB
    let Dbc: SIMD3<Double> = cartesianPositionC - cartesianPositionB
    let Dcd: SIMD3<Double> = cartesianPositionD - cartesianPositionC
    
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
      return (Phi + 2.0*Double.pi, periodicAngle)
    }
    
    return (Phi, periodicAngle)
  }
  
  
  public func computeBondsOperation(structure: Structure, windowController: NSWindowController?) -> FKOperation?
  {
    return nil
  }
 /*
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
  */
  
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
    
    
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
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
    
    let atomList: [SKAtomCopy] = superCellAtoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    
    let bonds: SKBondSetController = SKBondSetController(arrangedObjects: self.computeBonds(cell: superCell, atomList: atomList))
    
    superCellAtoms.tag()
    bonds.tag()
    
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
  
  public func computeBonds(cancelHandler: (()-> Bool) = {return false}, updateHandler: (() -> ()) = {}) -> [SKBondNode]
  {
    return []
  }
  
  public func computeBonds(cell: SKCell, atomList: [SKAtomCopy], cancelHandler: (()-> Bool) = {return false}, updateHandler: (() -> ()) = {}) -> [SKBondNode]
  {
    return []
  }
  
  public func reComputeBonds()
  {
    let cutoff: Double = 3.0
    let offsets: [[Int]] = [[0,0,0],[1,0,0],[1,1,0],[0,1,0],[-1,1,0],[0,0,1],[1,0,1],[1,1,1],[0,1,1],[-1,1,1],[-1,0,1],[-1,-1,1],[0,-1,1],[1,-1,1]]
    
    let atoms: [SKAtomCopy] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    //atoms.forEach{ $0.bonds.removeAll()}
    var computedBonds: [SKBondNode] = []
    
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
                    
                    let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
                    
                    let bondLength: Double = length(separationVector)
                    if (bondLength < 0.8)
                    {
                      // discard as being a bond
                    }
                    else if (bondLength < bondCriteria)
                    {
                      computedBonds.append(SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .internal))
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
          
          let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
          
          
          let bondLength: Double = length(separationVector)
          if (bondLength < 0.8)
          {
            // discard as being a bond
          }
          else if (bondLength < bondCriteria )
          {
            computedBonds.append(SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .internal))
          }
        }
        
      }
    }
    
    self.bondSetController.bonds = computedBonds
  }
  
  
  public func reComputeBonds(_ node: ProjectTreeNode, cancelHandler: (()-> Bool), updateHandler: (() -> ()))
  {
    let cutoff: Double = 3.0
    let offsets: [[Int]] = [[0,0,0],[1,0,0],[1,1,0],[0,1,0],[-1,1,0],[0,0,1],[1,0,1],[1,1,1],[0,1,1],[-1,1,1],[-1,0,1],[-1,-1,1],[0,-1,1],[1,-1,1]]
    var totalCount: Int
    
    let atoms: [SKAtomCopy] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    //atoms.forEach{ $0.bonds.removeAll()}
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
                    
                    let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
                    
                    let bondLength: Double = length(separationVector)
                    if (bondLength < 0.8)
                    {
                      // discard as being a bond
                    }
                    else if (bondLength < bondCriteria)
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
          
          let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
          
          let bondLength: Double = length(separationVector)
          if (bondLength < 0.8)
          {
            // discard as being a bond
          }
          else if (bondLength < bondCriteria )
          {
            computedBonds.insert(SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .internal))
          }
        }
        
      }
    }
    
    
    //bonds.arrangedObjects = computedBonds
  }

  
  // MARK: -
  // MARK: RKRenderStructure protocol
  
  public var hasSelectedObjects: Bool
  {
    return self.atomTreeController.selectedTreeNodes.count > 0 || self.atomTreeController.selectedTreeNode != nil
  }

  public var renderBoundingBox: SKBoundingBox
  {
    return self.transformedBoundingBox
  }
  
  /*
  public var boundingBox: SKBoundingBox
  {
    return SKBoundingBox()
  }*/
  
  public var clipBonds: Bool
  {
    return false
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
      case .none, .glow:
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
      case .none, .glow:
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
      case .none, .glow:
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
      case .none, .glow:
        break
      case .striped:
        self.atomSelectionStripesDensity = newValue
      case .WorleyNoise3D:
        self.atomSelectionWorleyNoise3DJitter = newValue
      }
    }
  }
  
  public var renderBondSelectionFrequency: Double
  {
    get
    {
      switch(self.bondSelectionStyle)
      {
      case .none, .glow:
        return 0.0
      case .striped:
        return self.bondSelectionStripesFrequency
      case .WorleyNoise3D:
        return self.bondSelectionWorleyNoise3DFrequency
      }
    }
    set(newValue)
    {
      switch(self.bondSelectionStyle)
      {
      case .none, .glow:
        break
      case .striped:
        self.bondSelectionStripesFrequency = newValue
      case .WorleyNoise3D:
        self.bondSelectionWorleyNoise3DFrequency = newValue
      }
    }
  }
  
  public var renderBondSelectionDensity: Double
  {
    get
    {
      switch(self.bondSelectionStyle)
      {
      case .none, .glow:
          return 0.0
        case .striped:
          return self.bondSelectionStripesDensity
        case .WorleyNoise3D:
          return self.bondSelectionWorleyNoise3DJitter
      }
    }
    set(newValue)
    {
      switch(self.bondSelectionStyle)
      {
      case .none, .glow:
        break
      case .striped:
        self.bondSelectionStripesDensity = newValue
      case .WorleyNoise3D:
        self.bondSelectionWorleyNoise3DJitter = newValue
      }
    }
  }
  
  public var renderPrimitiveSelectionFrequency: Double
  {
    get
    {
      switch(self.primitiveSelectionStyle)
      {
      case .none, .glow:
        return 0.0
      case .striped:
        return self.primitiveSelectionStripesFrequency
      case .WorleyNoise3D:
        return self.primitiveSelectionWorleyNoise3DFrequency
      }
    }
    set(newValue)
    {
      switch(self.primitiveSelectionStyle)
      {
      case .none, .glow:
        break
      case .striped:
        self.primitiveSelectionStripesFrequency = newValue
      case .WorleyNoise3D:
        self.primitiveSelectionWorleyNoise3DFrequency = newValue
      }
    }
  }
  
  public var renderPrimitiveSelectionDensity: Double
  {
    get
    {
      switch(self.primitiveSelectionStyle)
      {
      case .none, .glow:
          return 0.0
        case .striped:
          return self.primitiveSelectionStripesDensity
        case .WorleyNoise3D:
          return self.primitiveSelectionWorleyNoise3DJitter
      }
    }
    set(newValue)
    {
      switch(self.primitiveSelectionStyle)
      {
      case .none, .glow:
        break
      case .striped:
        self.primitiveSelectionStripesDensity = newValue
      case .WorleyNoise3D:
        self.primitiveSelectionWorleyNoise3DJitter = newValue
      }
    }
  }
  
  
  public var renderInternalBonds: [RKInPerInstanceAttributesBonds]
  {
    let data: [RKInPerInstanceAttributesBonds] = [RKInPerInstanceAttributesBonds]()
    return data
  }
  
  public var renderSelectedInternalBonds: [RKInPerInstanceAttributesBonds]
  {
    return []
  }
  
  public var renderExternalBonds: [RKInPerInstanceAttributesBonds]
  {
    let data: [RKInPerInstanceAttributesBonds] = [RKInPerInstanceAttributesBonds]()
    return data
  }
  
  public var renderSelectedExternalBonds: [RKInPerInstanceAttributesBonds]
  {
    return []
  }
  
  public func recomputeDensityProperties()
  {
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
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
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    
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
  
  public var crystallographicPositions: [(SIMD3<Double>, Int, Double)]
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
  
  public func centerOfMassOfSelection(atoms: [SKAtomCopy]) -> SIMD3<Double>
  {
    return SIMD3<Double>(0.0,0.0,0.0)
  }
  
  public func matrixOfInertia(atoms: [SKAtomCopy]) -> double3x3
  {
    return double3x3()
  }
  
  
  public func recomputeSelectionBodyFixedBasis(atoms: [SKAtomCopy]) -> double3x3
  {
    let intertiaMatrix: double3x3 = matrixOfInertia(atoms: atoms)

    var eigenvectors: double3x3 = double3x3()
    var eigenvalues: SIMD3<Double> = SIMD3<Double>()
    intertiaMatrix.EigenSystemSymmetric3x3(Q: &eigenvectors, w: &eigenvalues)
    return eigenvectors
  }
  
  // -1: always update
  // 0: x
  // 1: y
  // 2: z
  // update when index changes, so when a new direction of rotation has been chosen
  public func recomputeSelectionBodyFixedBasis(index: Int)
  {
    let atoms: [SKAtomCopy] = self.atomTreeController.selectedTreeNodes.flatMap{$0.representedObject.copies}.filter{$0.type == .copy}
    if index < 0 || self.selectionRotationIndex != index
    {
      self.selectionRotationIndex = index
      self.selectionCOMTranslation = centerOfMassOfSelection(atoms: atoms)
      let intertiaMatrix: double3x3 = matrixOfInertia(atoms: atoms)

      var eigenvectors: double3x3 = double3x3()
      var eigenvalues: SIMD3<Double> = SIMD3<Double>()
      intertiaMatrix.EigenSystemSymmetric3x3(Q: &eigenvectors, w: &eigenvalues)
      self.selectionBodyFixedBasis = eigenvectors
    }
  }
  
  public func bonds(subset: [SKAsymmetricAtom]) -> [SKBondNode]
  {
    return []
  }
  
  public func translatedPositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by translation: SIMD3<Double>) -> [SIMD3<Double>]
  {
    return []
  }
  
  public func translatedBodyFramePositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by translation: SIMD3<Double>) -> [SIMD3<Double>]
  {
    return []
  }
  
  public func rotatedPositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by rotation: simd_quatd) -> [SIMD3<Double>]
  {
    return []
  }
  
  public func rotatedBodyFramePositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by rotation: simd_quatd) -> [SIMD3<Double>]
  {
    return []
  }
  
  public func computeChangedBondLength(asymmetricBond: SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>, to: Double) -> (SIMD3<Double>,SIMD3<Double>)
  {
    return (SIMD3<Double>(0.0,0.0,0.0),SIMD3<Double>(0.0,0.0,0.0))
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
      
      
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
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
      
    let atomList: [SKAtomCopy] = superCellAtoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
      
    let bonds: SKBondSetController = SKBondSetController(arrangedObjects: self.computeBonds(cell: superCell, atomList: atomList))
      
    superCellAtoms.tag()
    bonds.tag()
    
    return (cell: superCell, spaceGroup: spaceGroup, atoms: superCellAtoms, bonds: bonds)
  }
  
  public func removeOverConnections(_ bonds: [SKBondNode]) -> [SKBondNode]
  {
    let groupByFirstAtom = Dictionary(grouping: bonds, by: { $0.atom1 })
    let groupBySecondAtom = Dictionary(grouping: bonds, by: { $0.atom2 })
    var groupByAtom = groupByFirstAtom.merging(groupBySecondAtom, uniquingKeysWith: +)
        
    for atom in groupByAtom
    {
      let atomI: SKAtomCopy = atom.key
      
      // check for atom type C, N, P, or S
      if Set<Int>([6, 7, 15, 16]).contains(atomI.asymmetricParentAtom.elementIdentifier)
      {
        let connectivity: Int = atom.value.count
        let maximumConnectivity: Int = PredefinedElements.sharedInstance.elementSet[atom.key.asymmetricParentAtom.elementIdentifier].maximumUFFCoordination
      
        if connectivity > maximumConnectivity
        {
          let sorted: [SKBondNode] = atom.value.sorted(by: {self.bondLength($0) < self.bondLength($1)})
          for bond in sorted[maximumConnectivity..<sorted.count]
          {
            groupByAtom[bond.atom1]?.removeObject(bond)
            groupByAtom[bond.atom2]?.removeObject(bond)
          }
        }
      }
    }
        
    return Array(Set(groupByAtom.flatMap{$0.value}))
  }
  
  public func typeBonds()
  {
    let allBonds: [SKBondNode] = removeOverConnections(self.bondSetController.bonds)
    
    allBonds.forEach { $0.bondOrder = 0 }
    
    let groupByFirstAtom = Dictionary(grouping: allBonds, by: { $0.atom1 })
    let groupBySecondAtom = Dictionary(grouping: allBonds, by: { $0.atom2 })
    let groupByAtom = groupByFirstAtom.merging(groupBySecondAtom, uniquingKeysWith: +)
    groupByAtom.forEach{$0.key.valence = 0}
    
    self.typeBondsHardRules(groupByAtom)
  }

  
  public func typeBondsHardRules(_ groupByAtom: Dictionary<SKAtomCopy,[SKBondNode]>)
  {
    for atom in groupByAtom
    {
      debugPrint("atom: \(atom.key.asymmetricParentAtom.displayName)")
      for bond in atom.value
      {
        debugPrint("bond: \(bond.atom1.asymmetricParentAtom.displayName) - \(bond.atom2.asymmetricParentAtom.displayName)")
      }
    }
    
    // loop over atoms when the connectivity is 1
    for atom in groupByAtom
    {
      if atom.value.count == 1
      {
        // rule: If the atom is hydrogen or halogen (F, Cl, Br, I, At, Ts), Oij is set to 1
        if Set<Int>([1,9,17,35,53,85,117]).contains(atom.key.asymmetricParentAtom.elementIdentifier)
        {
          atom.value.first?.bondOrder = 1
        }
        
        // If the atom is sulfur and it connects to phosphorus, Oij is set to 2.
        if Set<Int>([16]).contains(atom.key.asymmetricParentAtom.elementIdentifier),
           Set<Int>([15]).contains(atom.value[0].atom2.asymmetricParentAtom.elementIdentifier)
        {
          atom.value[0].bondOrder = 2
        }
        
        // If the atom is nitrogen and it connects to sulfur, Oij is set to 2.
        if Set<Int>([7]).contains(atom.key.asymmetricParentAtom.elementIdentifier),
           Set<Int>([16]).contains(atom.value[0].atom2.asymmetricParentAtom.elementIdentifier)
        {
          atom.value.first?.bondOrder = 2
        }
      }
    }
    
    // loop over atoms when the connectivity is 2
    for atom in groupByAtom
    {
      let atomI: SKAtomCopy = atom.key
      if atom.value.count == 2
      {
        if atom.key.asymmetricParentAtom.elementIdentifier == 6
        {
          atom.key.valence = 1
        }
        
        if atom.key.asymmetricParentAtom.elementIdentifier == 16
        {
          atom.key.valence = 2
        }
        
        // loop over all bonds that start with this atom-type
        for (j, firstBond) in atom.value.enumerated()
        {
          for (k, secondBond) in atom.value.enumerated()
          {
            if (j<k)
            {
              let atomJ = firstBond.otherAtom(atomI)
              let atomK = secondBond.otherAtom(atomI)
              let Cj: Int = max(groupByAtom[atomJ]?.count ?? 0, groupByAtom[atomK]?.count ?? 0)
              
              if Cj != 1
              {
                let angle = (180.0/Double.pi) * self.bendAngle(atomJ, atomI, atomK)
                if (Cj == 2) && (angle > 175.0) && (angle < 185.0)
                {
                  firstBond.bondOrder = 3
                  secondBond.bondOrder = 1
                }
                else if Set<Int>([6,7]).contains(atomK.asymmetricParentAtom.elementIdentifier) // atom is C or N
                {
                  firstBond.bondOrder = 1
                  secondBond.bondOrder = 2
                }
                else
                {
                  firstBond.bondOrder = 2
                  secondBond.bondOrder = 2
                }
              }
            }
          }
        }
        
      }
    }
    
    // loop over atoms when the connectivity is 3
    for atom in groupByAtom
    {
      let atomI: SKAtomCopy = atom.key
      if atom.value.count == 3
      {
        if Set<Int>([7,15]).contains(atomI.asymmetricParentAtom.elementIdentifier)
        {
          if atom.value[0].otherAtom(atomI).asymmetricParentAtom.elementIdentifier == 8,
             let atomIconnectivity = groupByAtom[atom.value[0].otherAtom(atomI)]?.count , atomIconnectivity == 1
          {
            // fix to acid model
           
          }
          else if atom.value[1].otherAtom(atomI).asymmetricParentAtom.elementIdentifier == 8,
                  let atomKconnectivity = groupByAtom[atom.value[1].otherAtom(atomI)]?.count , atomKconnectivity == 1
          {
            // fix to acid model
           
          }
          else if atom.value[2].otherAtom(atomI).asymmetricParentAtom.elementIdentifier == 8,
                  let atomLconnectivity = groupByAtom[atom.value[2].otherAtom(atomI)]?.count , atomLconnectivity == 1
          {
            // fix to acid model
           
          }
          else
          {
            // Otherwise, set all bond orders to 1
            for bond in atom.value
            {
              bond.bondOrder = 1
            }
          }
          
        }
        
        // if the atom is S, Cl, Br, or I
        if Set<Int>([16,17,35,53]).contains(atomI.asymmetricParentAtom.elementIdentifier)
        {
          for bond in atom.value
          {
            if bond.otherAtom(atomI).asymmetricParentAtom.elementIdentifier == 8,
               let atomJconnectivity = groupByAtom[atom.value[0].otherAtom(atomI)]?.count , atomJconnectivity == 1
            {
              // fix to acid model
            }
          }
        }
        
        // if the atom is C
        if Set<Int>([6]).contains(atomI.asymmetricParentAtom.elementIdentifier)
        {
        }
        
      }
      
      // loop over atoms when the connectivity is 4
      for atom in groupByAtom
      {
        let atomI: SKAtomCopy = atom.key
        if atom.value.count == 4
        {
          // if the atom is C or N
          if Set<Int>([6, 7]).contains(atomI.asymmetricParentAtom.elementIdentifier)
          {
            // maximum connections is 4, and when they are connected with 4 atoms, all the bonds should be single
            for bond in atom.value
            {
              bond.bondOrder = 1
            }
          }  // if atom is P, S, Cl, Br, I
          else if Set<Int>([15,16,17,35,53]).contains(atomI.asymmetricParentAtom.elementIdentifier)
          {
            // fix to acid model
          }
        }
      }
      
      
    }
  }
    
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public override func binaryEncode(to encoder: BinaryEncoder)
  {
    let calendar = Calendar.current
    
    encoder.encode(Structure.classVersionNumber)
    
    //encoder.encode(self.displayName)
    //encoder.encode(isVisible)
    
    //encoder.encode(self.spaceGroupHallNumber ?? Int(1))
    //encoder.encode(cell)
    //encoder.encode(periodic)
    //encoder.encode(origin)
    //encoder.encode(scaling)
    //encoder.encode(orientation)
    //encoder.encode(rotationDelta)
    
    
    
    encoder.encode(frameworkProbeMolecule.rawValue)
    
    encoder.encode(Double(minimumGridEnergyValue ?? 0.0))
    
    self.atomTreeController.tag()
    encoder.encode(atomTreeController)
    
    encoder.encode((self.atomRepresentationStyle == RepresentationStyle.licorice || self.atomRepresentationType == RepresentationType.unity) ? true : drawAtoms)
    
    encoder.encode(atomRepresentationType.rawValue)
    encoder.encode(atomRepresentationStyle.rawValue)
    encoder.encode(atomForceFieldIdentifier)
    encoder.encode(atomForceFieldOrder.rawValue)
    encoder.encode(atomColorSchemeIdentifier)
    encoder.encode(atomColorSchemeOrder.rawValue)
    
    encoder.encode(atomSelectionStyle.rawValue)
    encoder.encode(atomSelectionStripesDensity)
    encoder.encode(atomSelectionStripesFrequency)
    encoder.encode(atomSelectionWorleyNoise3DFrequency)
    encoder.encode(atomSelectionWorleyNoise3DJitter)
    encoder.encode(atomSelectionScaling)
    encoder.encode(atomSelectionIntensity)
    
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
    encoder.encode(1.0)
    
    encoder.encode(atomAmbientColor)
    encoder.encode(atomDiffuseColor)
    encoder.encode(atomSpecularColor)
    encoder.encode(atomAmbientIntensity)
    encoder.encode(atomDiffuseIntensity)
    encoder.encode(atomSpecularIntensity)
    encoder.encode(atomShininess)
    
    encoder.encode(self.atomTextType.rawValue)
    encoder.encode(self.atomTextFont)
    let font: NSFont = NSFont(name: self.atomTextFont, size: 32) ?? NSFont()
    let fontFamilyName: String = font.familyName ?? "Helvetica"
    let fontMemberName: String = NSFontManager.shared.memberName(of: font) ?? "Regular"
    encoder.encode(fontFamilyName)
    encoder.encode(fontMemberName)
    encoder.encode(self.atomTextScaling)
    encoder.encode(self.atomTextColor)
    encoder.encode(self.atomTextGlowColor)
    encoder.encode(self.atomTextStyle.rawValue)
    encoder.encode(self.atomTextEffect.rawValue)
    encoder.encode(self.atomTextAlignment.rawValue)
    encoder.encode(self.atomTextOffset)
    
    // encode bonds using tags
    self.bondSetController.tag()
    encoder.encode(self.bondSetController)
    
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
  
    encoder.encode(bondSelectionStyle.rawValue)
    encoder.encode(bondSelectionStripesDensity)
    encoder.encode(bondSelectionStripesFrequency)
    encoder.encode(bondSelectionWorleyNoise3DFrequency)
    encoder.encode(bondSelectionWorleyNoise3DJitter)
    encoder.encode(bondSelectionScaling)
    encoder.encode(bondSelectionIntensity)
    
    encoder.encode(bondHue)
    encoder.encode(bondSaturation)
    encoder.encode(bondValue)
    
    encoder.encode(bondAmbientOcclusion)
    
    // unit cell
    //encoder.encode(self.drawUnitCell)
    //encoder.encode(self.unitCellScaleFactor)
    //encoder.encode(self.unitCellDiffuseColor)
    //encoder.encode(self.unitCellDiffuseIntensity)
    
    // local axes
    //encoder.encode(self.renderLocalAxis)
    
    // adsorption surface
    encoder.encode(self.drawAdsorptionSurface)
    encoder.encode(self.adsorptionSurfaceOpacity)
    encoder.encode(self.adsorptionSurfaceIsoValue)
    encoder.encode(Double(self.minimumGridEnergyValue ?? 0.0))
    
    encoder.encode(self.adsorptionSurfaceRenderingMethod.rawValue)
    encoder.encode(self.adsorptionVolumeTransferFunction.rawValue)
    encoder.encode(self.adsorptionVolumeStepLength)
    
    encoder.encode(self.adsorptionSurfaceSize)
    encoder.encode(Int(0))
    
    encoder.encode(self.adsorptionSurfaceProbeMolecule.rawValue)
    
    encoder.encode(self.adsorptionSurfaceHue)
    encoder.encode(self.adsorptionSurfaceSaturation)
    encoder.encode(self.adsorptionSurfaceValue)
    
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
    
    /*
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
    */
    
    // Creation
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
    
    encoder.encode(Int(0x6f6b6182))
    
    super.binaryEncode(to: encoder)
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
    
    var legacyDisplayName: String = ""
    var legacyIsVisible: Bool = false
        
    var legacyCell: SKCell = SKCell()
    var legacyPeriodic: Bool = false
    var legacyOrigin: SIMD3<Double> = SIMD3<Double>()
    var legacyScaling: SIMD3<Double> = SIMD3<Double>()
    var legacyOrientation: simd_quatd = simd_quatd()
    var legacyRotationDelta: Double = 0.0
    
    var legacyDrawUnitCell: Bool = false
    var legacyUnitCellScaleFactor: Double = 0.0
    var legacyUnitCellDiffuseColor: NSColor = NSColor()
    var legacyUnitCellDiffuseIntensity: Double = 0.0
  
    var legacyRenderLocalAxis: RKLocalAxes = RKLocalAxes()
    
    var legacyAuthorFirstName: String = ""
    var legacyAuthorMiddleName: String = ""
    var legacyAuthorLastName: String = ""
    var legacyAuthorOrchidID: String = ""
    var legacyAuthorResearcherID: String = ""
    var legacyAuthorAffiliationUniversityName: String = ""
    var legacyAuthorAffiliationFacultyName: String = ""
    var legacyAuthorAffiliationInstituteName: String = ""
    var legacyAuthorAffiliationCityName: String = ""
    var legacyAuthorAffiliationCountryName: String = ""
    
    // Creation
    var legacyCreationDate = Date()
    
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > Structure.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
  
    if readVersionNumber < 9
    {
      legacyDisplayName = try decoder.decode(String.self)
      legacyIsVisible = try decoder.decode(Bool.self)
  
      let number = try decoder.decode(Int.self)
      self.legacySpaceGroup = SKSpacegroup(HallNumber: number)
    
      legacyCell = try decoder.decode(SKCell.self)
      legacyPeriodic = try decoder.decode(Bool.self)
      legacyOrigin = try decoder.decode(SIMD3<Double>.self)
      legacyScaling = try decoder.decode(SIMD3<Double>.self)
      legacyOrientation = try decoder.decode(simd_quatd.self)
      legacyRotationDelta = try decoder.decode(Double.self)
    }
    
    if(readVersionNumber < 9)
    {
      if readVersionNumber >= 2 // introduced in version 2
      {
        self.primitiveTransformationMatrix = try decoder.decode(double3x3.self)
        self.primitiveOrientation = try decoder.decode(simd_quatd.self)
        self.primitiveRotationDelta = try decoder.decode(Double.self)
  
        self.primitiveOpacity = try decoder.decode(Double.self)
        self.primitiveIsCapped = try decoder.decode(Bool.self)
        self.primitiveIsFractional = try decoder.decode(Bool.self)
        self.primitiveNumberOfSides = try decoder.decode(Int.self)
        self.primitiveThickness = try decoder.decode(Double.self)
      
        if readVersionNumber >= 6 // introduced in version 6
        {
          self.primitiveHue = try decoder.decode(Double.self)
          self.primitiveSaturation = try decoder.decode(Double.self)
          self.primitiveValue = try decoder.decode(Double.self)
      
          guard let primitiveSelectionStyle = RKSelectionStyle(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
          self.primitiveSelectionStyle = primitiveSelectionStyle
          self.primitiveSelectionStripesDensity = try decoder.decode(Double.self)
          self.primitiveSelectionStripesFrequency = try decoder.decode(Double.self)
          self.primitiveSelectionWorleyNoise3DFrequency = try decoder.decode(Double.self)
          self.primitiveSelectionWorleyNoise3DJitter = try decoder.decode(Double.self)
          self.primitiveSelectionScaling = try decoder.decode(Double.self)
          self.primitiveSelectionIntensity = try decoder.decode(Double.self)
        }
      
        self.primitiveFrontSideHDR = try decoder.decode(Bool.self)
        self.primitiveFrontSideHDRExposure = try decoder.decode(Double.self)
        self.primitiveFrontSideAmbientColor = try decoder.decode(NSColor.self)
        self.primitiveFrontSideDiffuseColor = try decoder.decode(NSColor.self)
        self.primitiveFrontSideSpecularColor = try decoder.decode(NSColor.self)
        self.primitiveFrontSideDiffuseIntensity = try decoder.decode(Double.self)
        self.primitiveFrontSideAmbientIntensity = try decoder.decode(Double.self)
        self.primitiveFrontSideSpecularIntensity = try decoder.decode(Double.self)
        self.primitiveFrontSideShininess = try decoder.decode(Double.self)
  
        self.primitiveBackSideHDR = try decoder.decode(Bool.self)
        self.primitiveBackSideHDRExposure = try decoder.decode(Double.self)
        self.primitiveBackSideAmbientColor = try decoder.decode(NSColor.self)
        self.primitiveBackSideDiffuseColor = try decoder.decode(NSColor.self)
        self.primitiveBackSideSpecularColor = try decoder.decode(NSColor.self)
        self.primitiveBackSideDiffuseIntensity = try decoder.decode(Double.self)
        self.primitiveBackSideAmbientIntensity = try decoder.decode(Double.self)
        self.primitiveBackSideSpecularIntensity = try decoder.decode(Double.self)
        self.primitiveBackSideShininess = try decoder.decode(Double.self)
      }
    }
    
    if readVersionNumber >= 3 // introduced in version 3
    {
      guard let frameworkProbeMolecule = Structure.ProbeMolecule(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
      self.frameworkProbeMolecule = frameworkProbeMolecule
    }
    
    self.minimumGridEnergyValue = Float(try decoder.decode(Double.self))
    
    self.atomTreeController = try decoder.decode(SKAtomTreeController.self)
    self.atomTreeController.tag()
    
    self.drawAtoms = try decoder.decode(Bool.self)
    
    guard let atomRepresentationType = RepresentationType(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.atomRepresentationType = atomRepresentationType
    guard let atomRepresentationStyle = RepresentationStyle(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.atomRepresentationStyle = atomRepresentationStyle
    self.atomForceFieldIdentifier = try decoder.decode(String.self)
    guard let atomForceFieldOrder = SKForceFieldSets.ForceFieldOrder(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.atomForceFieldOrder = atomForceFieldOrder
    self.atomColorSchemeIdentifier = try decoder.decode(String.self)
    guard let atomColorOrder = SKColorSets.ColorOrder(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.atomColorSchemeOrder = atomColorOrder
    
    guard let atomSelectionStyle = RKSelectionStyle(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.atomSelectionStyle = atomSelectionStyle
    self.atomSelectionStripesDensity = try decoder.decode(Double.self)
    self.atomSelectionStripesFrequency = try decoder.decode(Double.self)
    self.atomSelectionWorleyNoise3DFrequency = try decoder.decode(Double.self)
    self.atomSelectionWorleyNoise3DJitter = try decoder.decode(Double.self)
    self.atomSelectionScaling = try decoder.decode(Double.self)
    self.atomSelectionIntensity = try decoder.decode(Double.self)
    
    self.atomHue = try decoder.decode(Double.self)
    self.atomSaturation = try decoder.decode(Double.self)
    self.atomValue = try decoder.decode(Double.self)
    self.atomScaleFactor = try decoder.decode(Double.self)
    
    self.atomAmbientOcclusion = try decoder.decode(Bool.self)
    self.atomAmbientOcclusionPatchNumber = try decoder.decode(Int.self)
    self.atomAmbientOcclusionTextureSize = try decoder.decode(Int.self)
    self.atomAmbientOcclusionPatchSize = try decoder.decode(Int.self)
    
    self.atomHDR = try decoder.decode(Bool.self)
    self.atomHDRExposure = try decoder.decode(Double.self)
    let _ = try decoder.decode(Double.self)
    
    self.atomAmbientColor = try decoder.decode(NSColor.self)
    self.atomDiffuseColor = try decoder.decode(NSColor.self)
    self.atomSpecularColor = try decoder.decode(NSColor.self)
    self.atomAmbientIntensity = try decoder.decode(Double.self)
    self.atomDiffuseIntensity = try decoder.decode(Double.self)
    self.atomSpecularIntensity = try decoder.decode(Double.self)
    self.atomShininess = try decoder.decode(Double.self)
    
    guard let atomTextType = RKTextType(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.atomTextType = atomTextType
    self.atomTextFont = try decoder.decode(String.self)
    if readVersionNumber >= 7 // introduced in version 7
    {
      let fontFamilyName: String = try decoder.decode(String.self)
      let fontMemberName: String = try decoder.decode(String.self)
      self.atomTextFont = NSFontManager.shared.font(familyName: fontFamilyName, memberName: fontMemberName) ?? "Helvetica"
    }
    self.atomTextScaling = try decoder.decode(Double.self)
    self.atomTextColor = try decoder.decode(NSColor.self)
    self.atomTextGlowColor = try decoder.decode(NSColor.self)
    guard let atomTextStyle = RKTextStyle(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.atomTextStyle = atomTextStyle
    guard let atomTextEffect = RKTextEffect(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.atomTextEffect = atomTextEffect
    guard let atomTextAlignment = RKTextAlignment(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.atomTextAlignment = atomTextAlignment
    self.atomTextOffset = try decoder.decode(SIMD3<Double>.self)
    
    self.bondSetController = try decoder.decode(SKBondSetController.self)
    
    self.bondSetController.restoreBonds(atomTreeController: self.atomTreeController)
    
    self.bondSetController.tag()
    
    self.drawBonds = try decoder.decode(Bool.self)
    self.bondScaleFactor = try decoder.decode(Double.self)
    guard let bondColorMode = RKBondColorMode(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.bondColorMode = bondColorMode
    
    self.bondAmbientColor = try decoder.decode(NSColor.self)
    self.bondDiffuseColor = try decoder.decode(NSColor.self)
    self.bondSpecularColor = try decoder.decode(NSColor.self)
    self.bondAmbientIntensity = try decoder.decode(Double.self)
    self.bondDiffuseIntensity = try decoder.decode(Double.self)
    self.bondSpecularIntensity = try decoder.decode(Double.self)
    self.bondShininess = try decoder.decode(Double.self)
    
    self.bondHDR = try decoder.decode(Bool.self)
    self.bondHDRExposure = try decoder.decode(Double.self)
    
    if readVersionNumber >= 5 // introduced in version 5
    {
      guard let bondSelectionStyle = RKSelectionStyle(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
      self.bondSelectionStyle = bondSelectionStyle
      self.bondSelectionStripesDensity = try decoder.decode(Double.self)
      self.bondSelectionStripesFrequency = try decoder.decode(Double.self)
      self.bondSelectionWorleyNoise3DFrequency = try decoder.decode(Double.self)
      self.bondSelectionWorleyNoise3DJitter = try decoder.decode(Double.self)
      self.bondSelectionScaling = try decoder.decode(Double.self)
    }
    self.bondSelectionIntensity = try decoder.decode(Double.self)
    
    self.bondHue = try decoder.decode(Double.self)
    self.bondSaturation = try decoder.decode(Double.self)
    self.bondValue = try decoder.decode(Double.self)
    
    self.bondAmbientOcclusion = try decoder.decode(Bool.self)
    
    // unit cell
    if readVersionNumber <= 8
    {
      legacyDrawUnitCell = try decoder.decode(Bool.self)
      legacyUnitCellScaleFactor = try decoder.decode(Double.self)
      legacyUnitCellDiffuseColor = try decoder.decode(NSColor.self)
      legacyUnitCellDiffuseIntensity = try decoder.decode(Double.self)
    }
    
    // local axes
    if readVersionNumber >= 8 // introduced in version 8
    {
      if readVersionNumber <= 8
      {
        legacyRenderLocalAxis = try decoder.decode(RKLocalAxes.self)
      }
    }
    
    // adsorption surface
    self.drawAdsorptionSurface = try decoder.decode(Bool.self)
    self.adsorptionSurfaceOpacity = try decoder.decode(Double.self)
    self.adsorptionSurfaceIsoValue = try decoder.decode(Double.self)
    self.minimumGridEnergyValue = Float(try decoder.decode(Double.self))
    
    if readVersionNumber >= 9 // introduced in version 9
    {
      guard let adsorptionSurfaceRenderingMethod = RKEnergySurfaceType(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
      self.adsorptionSurfaceRenderingMethod = adsorptionSurfaceRenderingMethod
      guard let adsorptionVolumeTransferFunction = RKPredefinedVolumeRenderingTransferFunction(rawValue: try decoder.decode(Int.self)) else {throw   BinaryCodableError.invalidArchiveData}
      self.adsorptionVolumeTransferFunction = adsorptionVolumeTransferFunction
      self.adsorptionVolumeStepLength = try decoder.decode(Double.self)
    }
    
    self.adsorptionSurfaceSize = try decoder.decode(Int.self)
    let _: Int = try decoder.decode(Int.self)  // numberOfTriangles
    
    guard let probeMolecule = Structure.ProbeMolecule(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.adsorptionSurfaceProbeMolecule = probeMolecule
    
    if readVersionNumber >= 6 // introduced in version 6
    {
      self.adsorptionSurfaceHue = try decoder.decode(Double.self)
      self.adsorptionSurfaceSaturation = try decoder.decode(Double.self)
      self.adsorptionSurfaceValue = try decoder.decode(Double.self)
    }
    
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
    
    /* Used for making the IZA Database
    self.adsorptionSurfaceProbeMolecule = ProbeMolecule.argon
    self.adsorptionSurfaceOpacity = 0.66666
    self.adsorptionSurfaceFrontSideAmbientColor = NSColor(red: 0.502, green: 0.855, blue: 0.922, alpha: 1.0)
    self.adsorptionSurfaceFrontSideDiffuseColor = NSColor(red: 0.502, green: 0.855, blue: 0.922, alpha: 1.0)
    self.adsorptionSurfaceBackSideAmbientColor = NSColor(red: 0.502, green: 0.855, blue: 0.922, alpha: 1.0)
    self.adsorptionSurfaceBackSideDiffuseColor = NSColor(red: 0.502, green: 0.855, blue: 0.922, alpha: 1.0)
    */
    
    // Structure properties
    guard let structureType = StructureType(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.structureType = structureType
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
    
    if(readVersionNumber < 9)
    {
      // Info
      legacyAuthorFirstName = try decoder.decode(String.self)
      legacyAuthorMiddleName = try decoder.decode(String.self)
      legacyAuthorLastName = try decoder.decode(String.self)
      legacyAuthorOrchidID = try decoder.decode(String.self)
      legacyAuthorResearcherID = try decoder.decode(String.self)
      legacyAuthorAffiliationUniversityName = try decoder.decode(String.self)
      legacyAuthorAffiliationFacultyName = try decoder.decode(String.self)
      legacyAuthorAffiliationInstituteName = try decoder.decode(String.self)
      legacyAuthorAffiliationCityName = try decoder.decode(String.self)
      legacyAuthorAffiliationCountryName = try decoder.decode(String.self)
      
      // Creation
      components.day = Int(try decoder.decode(UInt16.self))
      components.month = Int(try decoder.decode(UInt16.self))
      components.year = Int(try decoder.decode(UInt32.self))
      legacyCreationDate = calendar.date(from: components) ?? Date()
    }
    self.creationTemperature = try decoder.decode(String.self)
    guard let creationTemperatureScale = TemperatureScale(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.creationTemperatureScale = creationTemperatureScale
    self.creationPressure = try decoder.decode(String.self)
    guard let creationPressureScale = PressureScale(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.creationPressureScale = creationPressureScale
    guard let creationMethod = CreationMethod(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.creationMethod = creationMethod
    
    guard let creationUnitCellRelaxationMethod = UnitCellRelaxationMethod(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.creationUnitCellRelaxationMethod = creationUnitCellRelaxationMethod
    self.creationAtomicPositionsSoftwarePackage = try decoder.decode(String.self)
    guard let creationAtomicPositionsIonsRelaxationAlgorithm = IonsRelaxationAlgorithm(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.creationAtomicPositionsIonsRelaxationAlgorithm = creationAtomicPositionsIonsRelaxationAlgorithm
    guard let creationAtomicPositionsIonsRelaxationCheck = IonsRelaxationCheck(rawValue: try decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.creationAtomicPositionsIonsRelaxationCheck = creationAtomicPositionsIonsRelaxationCheck
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
    
    
    if readVersionNumber >= 9
    {
      let magicNumber = try decoder.decode(Int.self)
      if magicNumber != Int(0x6f6b6182)
      {
        throw BinaryDecodableError.invalidMagicNumber
      }
      
      try super.init(fromBinary: decoder)
    }
    else
    {
      super.init()
      
      self.displayName = legacyDisplayName
      self.isVisible = legacyIsVisible
      
      self.cell = legacyCell
      self.periodic = legacyPeriodic
      self.origin = legacyOrigin
      self.scaling = legacyScaling
      self.orientation = legacyOrientation
      self.rotationDelta = legacyRotationDelta
      
      self.drawUnitCell = legacyDrawUnitCell
      self.unitCellScaleFactor = legacyUnitCellScaleFactor
      self.unitCellDiffuseColor = legacyUnitCellDiffuseColor
      self.unitCellDiffuseIntensity = legacyUnitCellDiffuseIntensity
    
      self.renderLocalAxis = legacyRenderLocalAxis
      
      self.authorFirstName = legacyAuthorFirstName
      self.authorMiddleName = legacyAuthorMiddleName
      self.authorLastName = legacyAuthorLastName
      self.authorOrchidID = legacyAuthorOrchidID
      self.authorResearcherID = legacyAuthorResearcherID
      self.authorAffiliationUniversityName = legacyAuthorAffiliationUniversityName
      self.authorAffiliationFacultyName = legacyAuthorAffiliationFacultyName
      self.authorAffiliationInstituteName = legacyAuthorAffiliationInstituteName
      self.authorAffiliationCityName = legacyAuthorAffiliationCityName
      self.authorAffiliationCountryName = legacyAuthorAffiliationCountryName
      
      self.creationDate = legacyCreationDate
    }
    
    self.setRepresentationStyle(style: self.atomRepresentationStyle)
    
    if readVersionNumber <= 4
    {
      self.expandSymmetry()
      self.reComputeBonds()
    }
  }
  
}

