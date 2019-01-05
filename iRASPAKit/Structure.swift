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

public class Structure: NSObject, Decodable, RKRenderStructure, AtomVisualAppearanceViewer, BondVisualAppearanceViewer, UnitCellVisualAppearanceViewer, AdsorptionSurfaceVisualAppearanceViewer, InfoViewer, CellViewer, SKRenderAdsorptionSurfaceStructure, BinaryDecodable, BinaryEncodable
{
  private var versionNumber: Int = 4
  private static var classVersionNumber: Int = 1
  public var displayName: String = "test123"
  
  public var origin: double3 = double3(x: 0.0, y: 0.0, z: 0.0)
  public var scaling: double3 = double3(x: 1.0, y: 1.0, z: 1.0)
  public var orientation: simd_quatd = simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
  public var rotationDelta: Double = 5.0
  
  public var periodic: Bool = false
  
  public var isVisible: Bool = true
  
  public var cell: SKCell = SKCell()
  public var atomUnitCellPositions: [double3]
  {
    return []
  }
  public var minimumGridEnergyValue: Float? = nil
  
  public var spaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: 1)
  
  public enum MaterialType: Int
  {
    case structure = 0
    case crystal = 1
    case molecularCrystal = 2
    case molecule = 3
    case protein = 4
    case proteinCrystal = 5
  }
  
  var materialType: MaterialType
  {
    return .structure
  }
  
  public enum StructureType: Int
  {
    case framework = 0
    case adsorbate = 1
    case cation = 2
    case ionicLiquid = 3
    case solvent = 4
  }
  
  public enum PositionType: Int
  {
    case fractional = 0
    case cartesian = 1
  }
  public var positionType: PositionType
  {
    get
    {
      return .fractional
    }
  }
  
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
  
  
  
  
  // atoms
  public var atoms: SKAtomTreeController = SKAtomTreeController()

  public var drawAtoms: Bool =  true
  
  public var atomRepresentationType: RepresentationType = .sticks_and_balls
  public var atomRepresentationStyle: RepresentationStyle = .default
  public var atomForceFieldIdentifier: String = "Default"
  public var atomForceFieldOrder: SKForceFieldSets.ForceFieldOrder = .elementOnly
  public var atomColorSchemeIdentifier: String = SKColorSets.ColorScheme.jmol.rawValue
  public var atomColorOrder: SKColorSets.ColorOrder = .elementOnly
  
  public var atomSelectionStyle: RKSelectionStyle = .WorleyNoise3D
  public var atomSelectionStripesDensity: Double = 0.25
  public var atomSelectionStripesFrequency: Double = 12.0
  public var atomSelectionWorleyNoise3DFrequency: Double = 2.0
  public var atomSelectionWorleyNoise3DJitter: Double = 1.0
  public var selectionScaling: Double = 1.2
  public var selectionIntensity: Double = 1.0
  
  public var atomHue: Double = 1.0
  public var atomSaturation: Double = 1.0
  public var atomValue: Double = 1.0
  public var atomScaleFactor: Double = 1.0
  
  public var atomAmbientOcclusion: Bool = true
  public var atomAmbientOcclusionPatchNumber: Int = 256
  public var atomAmbientOcclusionTextureSize: Int = 1024
  public var atomAmbientOcclusionPatchSize: Int = 16
  public var atomCacheAmbientOcclusionTexture: [CUnsignedChar] = [CUnsignedChar]()
  
  public var atomHDR: Bool = true
  public var atomHDRExposure: Double = 1.5
  public var atomHDRBloomLevel: Double = 0.5
  
  public var atomAmbientColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var atomDiffuseColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var atomSpecularColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var atomAmbientIntensity: Double = 0.2
  public var atomDiffuseIntensity: Double = 1.0
  public var atomSpecularIntensity: Double = 1.0
  public var atomShininess: Double = 4.0
  
  // bonds
  public var bonds: SKBondSetController = SKBondSetController()
  
  public var drawBonds: Bool = true
  
  public var bondScaleFactor: Double = 1.0
  public var bondColorMode: RKBondColorMode = .split
  
  public var bondAmbientColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var bondDiffuseColor: NSColor = NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
  public var bondSpecularColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var bondAmbientIntensity: Double = 0.1
  public var bondDiffuseIntensity: Double = 1.0
  public var bondSpecularIntensity: Double = 1.0
  public var bondShininess: Double = 4.0

  public var bondHDR: Bool = true
  public var bondHDRExposure: Double = 1.5
  public var bondHDRBloomLevel: Double = 1.0
  
  public var bondHue: Double = 1.0
  public var bondSaturation: Double = 1.0
  public var bondValue: Double = 1.0
  
  public var bondAmbientOcclusion: Bool = false
  
  // text properties
  var atomTextType: RKTextType = RKTextType.none
  var atomTextFont: String = "Helvetica"
  var atomTextScaling: Double = 1.0
  var atomTextColor: NSColor = NSColor.black
  var atomTextGlowColor: NSColor = NSColor.blue
  var atomTextStyle: RKTextStyle = RKTextStyle.flatBillboard
  var atomTextEffect: RKTextEffect = RKTextEffect.none
  var atomTextAlignment: RKTextAlignment = RKTextAlignment.center
  var atomTextOffset: double3 = double3()
  
  // unit cell
  public var drawUnitCell: Bool = false
  public var unitCellScaleFactor: Double = 1.0
  public var unitCellDiffuseColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var unitCellDiffuseIntensity: Double = 1.0
  
  
  public var clipAtomsAtUnitCell: Bool {return false}
  public var clipBondsAtUnitCell: Bool {return false}
  
  // adsorption surface
  
  public var adsorptionSurfaceProbeParameters: double2
  {
    switch(adsorptionSurfaceProbeMolecule)
    {
    case .helium:
      return double2(10.9, 2.64)
    case .nitrogen:
      return double2(36.0,3.31)
    case .methane:
      return double2(158.5,3.72)
    case .hydrogen:
      return double2(36.7,2.958)
    case .water:
      return double2(89.633,3.097)
    case .co2:
      // Y. Iwai, H. Higashi, H. Uchida, Y. Arai, Fluid Phase Equilibria 127 (1997) 251-261.
      return double2(236.1,3.72)
    case .xenon:
      // Gábor Rutkai, Monika Thol, Roland Span & Jadran Vrabec (2017), Molecular Physics, 115:9-12, 1104-1121
      return double2(226.14,3.949);
    case .krypton:
      // Gábor Rutkai, Monika Thol, Roland Span & Jadran Vrabec (2017), Molecular Physics, 115:9-12, 1104-1121
      return double2(162.58,3.6274);
    }
  }
  
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
  }

  public var drawAdsorptionSurface: Bool = false
  public var adsorptionSurfaceOpacity: Double = 1.0
  public var adsorptionSurfaceIsoValue: Double = 0.0
  
  public var adsorptionSurfaceSize: Int = 128
  public var adsorptionSurfaceNumberOfTriangles: Int = 0
  
  public var adsorptionSurfaceProbeMolecule: ProbeMolecule = .helium
  
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
  }
  

  
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
  
  public var numberOfAtoms: Int
  {
    return self.atoms.flattenedLeafNodes().count
  }
  
  public var numberOfInternalBonds: Int
  {
    return self.bonds.arrangedObjects.filter{$0.boundaryType == .internal}.count
  }
  
  public var numberOfExternalBonds: Int
  {
    return self.bonds.arrangedObjects.filter{$0.boundaryType == .external}.count
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
  
  // MARK: -
  // MARK: AtomVisualAppearanceViewer protocol redirected functions
  
  public func getRepresentationColorScheme() -> String?
  {
    return self.atomColorSchemeIdentifier
  }
  
  public func setRepresentationColorScheme(colorSet: SKColorSet)
  {
    let asymmetricAtoms: [SKAsymmetricAtom] = atoms.flattenedLeafNodes().compactMap{$0.representedObject}
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
    
    switch(self.atomForceFieldOrder)
    {
    case .elementOnly:
      asymmetricAtoms.forEach{atom in
        atom.potentialParameters = forceFieldSet[PredefinedElements.sharedInstance.elementSet[atom.elementIdentifier].chemicalSymbol]?.potentialParameters ?? double2(0.0,0.0)
        let atomicNumber: Int = atom.elementIdentifier
        let elementString: String = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
        atom.bondDistanceCriteria = forceFieldSet[elementString]?.userDefinedRadius ?? 0.0
      }
    case .forceFieldOnly:
      asymmetricAtoms.forEach{atom in
        atom.potentialParameters = forceFieldSet[atom.uniqueForceFieldName]?.potentialParameters ?? double2(0.0,0.0)
        atom.bondDistanceCriteria = forceFieldSet[atom.uniqueForceFieldName]?.userDefinedRadius ?? 1.0
      }
    case .forceFieldFirst:
      asymmetricAtoms.forEach{atom in
        atom.potentialParameters = forceFieldSet[atom.uniqueForceFieldName]?.potentialParameters ?? forceFieldSet[PredefinedElements.sharedInstance.elementSet[atom.elementIdentifier].chemicalSymbol]?.potentialParameters ?? double2(0.0,0.0)
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
        asymmetricAtom.drawRadius = 0.15 * bondScaleFactor
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
        asymmetricAtoms.forEach{$0.potentialParameters = forceFieldSet[PredefinedElements.sharedInstance.elementSet[$0.elementIdentifier].chemicalSymbol]?.potentialParameters ?? double2(0.0,0.0)}
      case .forceFieldOnly:
        asymmetricAtoms.forEach{$0.potentialParameters = forceFieldSet[$0.uniqueForceFieldName]?.potentialParameters ?? double2(0.0,0.0)}
      case .forceFieldFirst:
        asymmetricAtoms.forEach{$0.potentialParameters = forceFieldSet[$0.uniqueForceFieldName]?.potentialParameters ?? forceFieldSet[PredefinedElements.sharedInstance.elementSet[$0.elementIdentifier].chemicalSymbol]?.potentialParameters ?? double2(0.0,0.0)}
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
        bondScaleFactor = 1.0
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
        self.selectionScaling = 1.2
        
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
        self.selectionScaling = 1.0
        
        self.setRepresentationType(type: .vdw)
      case .licorice:
        atomAmbientColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        atomSpecularColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        atomAmbientIntensity = 0.1
        atomDiffuseIntensity = 1.0
        atomSpecularIntensity = 1.0
        atomShininess = 4.0
        drawAtoms = true
        atomScaleFactor = 1.0
        atomForceFieldIdentifier = "Default"
        atomColorSchemeIdentifier = SKColorSets.ColorScheme.jmol.rawValue
        atomColorOrder = .elementOnly
        atomAmbientOcclusion = false
        
        drawBonds = true
        bondColorMode = .split
        bondScaleFactor = 1.5
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
        self.selectionScaling = 1.5
        
        self.setRepresentationType(type: .unity)
      }
    }
    
    let asymmetricAtoms: [SKAsymmetricAtom] = atoms.flattenedLeafNodes().compactMap{$0.representedObject}
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
        asymmetricAtom.drawRadius = 0.15 * bondScaleFactor
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
       atomRepresentationType == .sticks_and_balls &&
       atomForceFieldIdentifier == "Default" &&
       atomColorSchemeIdentifier == SKColorSets.ColorScheme.jmol.rawValue &&
       atomColorOrder == .elementOnly &&
       drawBonds == true &&
       bondColorMode == .uniform &&
       (bondScaleFactor ==~ 1.0) &&
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
      (selectionScaling ==~ 1.2)
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
      (selectionScaling ==~ 1.0)
    {
      self.atomRepresentationStyle = .fancy
    }
    else if drawAtoms == true &&
      atomRepresentationType == .unity &&
      atomForceFieldIdentifier == "Default" &&
      atomColorSchemeIdentifier == SKColorSets.ColorScheme.jmol.rawValue &&
      atomColorOrder == .elementOnly &&
      (atomScaleFactor ==~ 1.0) &&
      atomAmbientOcclusion == false &&
      (atomAmbientIntensity ==~ 0.1) &&
      (atomDiffuseIntensity ==~ 1.0) &&
      (atomSpecularIntensity ==~ 1.0) &&
      (atomShininess ==~ 4.0) &&
      drawBonds == true &&
      bondColorMode == .split &&
      (bondScaleFactor ==~ 1.5) &&
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
      (selectionScaling ==~ 1.5)
    {
      self.atomRepresentationStyle = .licorice
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
        atomScaleFactor = 1.0
        asymmetricAtoms.forEach{$0.drawRadius = 0.15 * bondScaleFactor}
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
      return 0.15 * bondScaleFactor
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
    self.origin = try container.decode(double3.self)
    self.scaling = try container.decode(double3.self)
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
    
    self.atomAmbientColor = try NSColor(float4: container.decode(float4.self))
    self.atomDiffuseColor = try NSColor(float4: container.decode(float4.self))
    self.atomSpecularColor = try NSColor(float4: container.decode(float4.self))
    
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
      self.selectionScaling = try container.decode(Double.self)
    }
    
    // set value consistent with pre-defined styles
    if self.atomRepresentationStyle == .default
    {
      self.atomSelectionStyle = .WorleyNoise3D
      self.selectionScaling = 1.2
    }
    if self.atomRepresentationStyle == .fancy
    {
      self.atomSelectionStyle = .WorleyNoise3D
      self.selectionScaling = 1.0
    }
    if self.atomRepresentationStyle == .licorice
    {
      self.atomSelectionStyle = .WorleyNoise3D
      self.selectionScaling = 1.5
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
    
    self.bondAmbientColor = try NSColor(float4: container.decode(float4.self))
    self.bondDiffuseColor = try NSColor(float4: container.decode(float4.self))
    self.bondSpecularColor = try NSColor(float4: container.decode(float4.self))
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
      self.atomTextColor = try NSColor(float4: container.decode(float4.self))
      self.atomTextGlowColor = try NSColor(float4: container.decode(float4.self))
      self.atomTextStyle = try RKTextStyle(rawValue: container.decode(Int.self))!
      self.atomTextEffect = try RKTextEffect(rawValue: container.decode(Int.self))!
      self.atomTextAlignment = try RKTextAlignment(rawValue: container.decode(Int.self))!
      self.atomTextOffset = try container.decode(double3.self)
    }
    
    // unit cell
    self.drawUnitCell = try container.decode(Bool.self)
    self.unitCellScaleFactor = try container.decode(Double.self)
    self.unitCellDiffuseColor = try NSColor(float4: container.decode(float4.self))
    self.unitCellDiffuseIntensity = try container.decode(Double.self)
    
    
    // adsorption surface
    self.drawAdsorptionSurface = try container.decode(Bool.self)
    
    self.adsorptionSurfaceOpacity = try container.decode(Double.self)
    self.adsorptionSurfaceIsoValue = try container.decode(Double.self)
    self.adsorptionSurfaceSize = try container.decode(Int.self)
    self.adsorptionSurfaceProbeMolecule = try Structure.ProbeMolecule(rawValue: container.decode(Int.self))!
    
    self.adsorptionSurfaceFrontSideHDR = try container.decode(Bool.self)
    self.adsorptionSurfaceFrontSideHDRExposure = try container.decode(Double.self)
    self.adsorptionSurfaceFrontSideAmbientColor = try NSColor(float4: container.decode(float4.self))
    self.adsorptionSurfaceFrontSideDiffuseColor = try NSColor(float4: container.decode(float4.self))
    self.adsorptionSurfaceFrontSideSpecularColor = try NSColor(float4: container.decode(float4.self))
    
    self.adsorptionSurfaceFrontSideAmbientIntensity = try container.decode(Double.self)
    self.adsorptionSurfaceFrontSideDiffuseIntensity = try container.decode(Double.self)
    self.adsorptionSurfaceFrontSideSpecularIntensity = try container.decode(Double.self)
    self.adsorptionSurfaceFrontSideShininess = try container.decode(Double.self)
    
    self.adsorptionSurfaceBackSideHDR = try container.decode(Bool.self)
    self.adsorptionSurfaceBackSideHDRExposure = try container.decode(Double.self)
    self.adsorptionSurfaceBackSideAmbientColor = try NSColor(float4: container.decode(float4.self))
    self.adsorptionSurfaceBackSideDiffuseColor = try NSColor(float4: container.decode(float4.self))
    self.adsorptionSurfaceBackSideSpecularColor = try NSColor(float4: container.decode(float4.self))
    
    self.adsorptionSurfaceBackSideAmbientIntensity = try container.decode(Double.self)
    self.adsorptionSurfaceBackSideDiffuseIntensity = try container.decode(Double.self)
    self.adsorptionSurfaceBackSideSpecularIntensity = try container.decode(Double.self)
    self.adsorptionSurfaceBackSideShininess = try container.decode(Double.self)
    
    // REMOVE SOON AFTER CORRECTING THE GALLERY
    self.reComputeBoundingBox()
    
    
    self.setRepresentationStyle(style: self.atomRepresentationStyle)
    self.setRepresentationType(type: self.atomRepresentationType)
  }
  
  public var structureNitrogenSurfaceArea: Double = 0.0
  {
    didSet
    {
      self.structureGravimetricNitrogenSurfaceArea = structureNitrogenSurfaceArea * SKConstants.AvogadroConstantPerAngstromSquared / self.structureMass
      self.structureVolumetricNitrogenSurfaceArea = structureNitrogenSurfaceArea * 1e4 / self.cell.volume
    }
  }
  
  
  // MARK: Measuring distance, angle, and dihedral-angles
  // ===============================================================================================================================
  
  public func bondVector(_ bond: SKBondNode) -> double3
  {
    let atom1: double3 = bond.atom1.position
    let atom2: double3 = bond.atom2.position
    let dr: double3 = atom2 - atom1
    return dr
  }
  
  
  public func bondLength(_ bond: SKBondNode) -> Double
  {
    let atom1: double3 = bond.atom1.position
    let atom2: double3 = bond.atom2.position
    let dr: double3 = abs(atom2 - atom1)
    return length(dr)
  }
  
  public func distance(_ atomA: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3), _ atomB: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3)) -> Double
  {
    let posB: double3 = atomA.copy.position
    let posA: double3 = atomB.copy.position
    let dr: double3 = abs(posB - posA)
    return length(dr)
  }
  
  public func bendAngle(_ atomA: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3), _ atomB: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3), _ atomC: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3)) -> Double
  {
    let posA: double3 = atomA.copy.position
    let posB: double3 = atomB.copy.position
    let posC: double3 = atomC.copy.position
    
    let dr1: double3 = posA - posB
    let dr2: double3 = posC - posB
    
    let vectorAB: double3 = normalize(dr1)
    let vectorBC: double3 = normalize(dr2)
    
    return acos(dot(vectorAB, vectorBC))
  }
  
  public func dihedralAngle(_ atomA: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3), _ atomB: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3), _ atomC: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3), _ atomD: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3)) -> Double
  {
    let posA: double3 = atomA.copy.position
    let posB: double3 = atomB.copy.position
    let posC: double3 = atomC.copy.position
    let posD: double3 = atomD.copy.position
    
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
    
    let Pb: double3 = cross(Dbc, Dab)
    let Pc: double3 = cross(Dbc, Dcd)
    
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
            let CartesianPosition: double3 = atom.position + cell.unitCell * double3(Double(k1),Double(k2),Double(k3))
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
    var computedBonds: Set<SKBondNode> = []
    
    let perpendicularWidths: double3 = self.cell.boundingBox.widths + double3(x: 0.1, y: 0.1, z: 0.1)
    let numberOfCells: [Int] = [Int(perpendicularWidths.x/cutoff),Int(perpendicularWidths.y/cutoff),Int(perpendicularWidths.z/cutoff)]
    let totalNumberOfCells: Int = numberOfCells[0] * numberOfCells[1] * numberOfCells[2]
    let cutoffVector: double3 = double3(x: perpendicularWidths.x/Double(numberOfCells[0]), y: perpendicularWidths.y/Double(numberOfCells[1]), z: perpendicularWidths.z/Double(numberOfCells[2]))
    
    if ((numberOfCells[0]>=3) &&  (numberOfCells[1]>=3) && (numberOfCells[2]>=3))
    {
      
      var head: [Int] = [Int](repeating: -1, count: totalNumberOfCells)
      var list: [Int] = [Int](repeating: -1, count: atoms.count)
      
      // create cell-list based on the bond-cutoff
      for i in 0..<atoms.count
      {
        let position: double3 = atoms[i].position - self.cell.boundingBox.minimum
        
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
              let posA: double3 = atoms[i].position
              
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
                    let posB: double3 = atoms[j].position
                    let separationVector: double3 = posA - posB
                    
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
        let posA: double3 = atoms[i].position
        
        for j in i+1..<atoms.count
        {
          let posB: double3 = atoms[j].position
          
          let separationVector: double3 = posA - posB
          
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
    var computedBonds: Set<SKBondNode> = []
    
    
    
    
    //self.progress = 0.0
    
    
    let perpendicularWidths: double3 = self.cell.boundingBox.widths + double3(x: 0.1, y: 0.1, z: 0.1)
    let numberOfCells: [Int] = [Int(perpendicularWidths.x/cutoff),Int(perpendicularWidths.y/cutoff),Int(perpendicularWidths.z/cutoff)]
    let totalNumberOfCells: Int = numberOfCells[0] * numberOfCells[1] * numberOfCells[2]
    let cutoffVector: double3 = double3(x: perpendicularWidths.x/Double(numberOfCells[0]), y: perpendicularWidths.y/Double(numberOfCells[1]), z: perpendicularWidths.z/Double(numberOfCells[2]))
    
    if ((numberOfCells[0]>=3) &&  (numberOfCells[1]>=3) && (numberOfCells[2]>=3))
    {
      
      var head: [Int] = [Int](repeating: -1, count: totalNumberOfCells)
      var list: [Int] = [Int](repeating: -1, count: atoms.count)
      
      // create cell-list based on the bond-cutoff
      for i in 0..<atoms.count
      {
        let position: double3 = atoms[i].position - self.cell.boundingBox.minimum
        
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
              let posA: double3 = atoms[i].position
              
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
                    let posB: double3 = atoms[j].position
                    let separationVector: double3 = posA - posB
                    
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
        let posA: double3 = atoms[i].position
        
        for j in i+1..<atoms.count
        {
          let posB: double3 = atoms[j].position
          
          let separationVector: double3 = posA - posB
          
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
  
  public var hasExternalBonds: Bool
  {
    get
    {
      return false
    }
  }
  
  
  
  public var renderTextColor: NSColor
  {
    get
    {
      return atomTextColor
    }
    set(newValue)
    {
      atomTextColor = newValue
    }
  }
  
  
  public var renderTextType: RKTextType
  {
    get
    {
      return atomTextType
    }
    set(newValue)
    {
      self.atomTextType = newValue
    }
  }
  
  public var renderTextStyle: RKTextStyle
  {
    return RKTextStyle.flatBillboard
  }

  public var renderTextAlignment: RKTextAlignment
  {
    get
    {
      return atomTextAlignment
    }
    set(newValue)
    {
      atomTextAlignment = newValue
    }
  }
  
  public var renderTextFont: String
  {
    get
    {
      return atomTextFont
    }
    set(newValue)
    {
      self.atomTextFont = newValue
    }
  }
  
  public var renderTextScaling: Double
  {
    get
    {
      return atomTextScaling
    }
    set(newValue)
    {
      atomTextScaling = newValue
    }
  }
  
  public var renderTextOffset: double3
  {
    get
    {
      return atomTextOffset
    }
    set(newValue)
    {
      atomTextOffset = newValue
    }
  }
  
  public var renderTextData: [RKInPerInstanceAttributesText]
  {
    get
    {
      var data: [RKInPerInstanceAttributesText] = []
      
      let fontAtlas: RKFontAtlas = RKCachedFontAtlas.shared.fontAtlas(for: self.atomTextFont)
      
      let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
      let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
      
      for atom in atoms
      {
        let pos: double3 = atom.position
        
        //let w: Float = (atom.isVisible && atom.isVisibleEnabled) && !atomNode.isGroup ? 1.0 : -1.0
        let w: Float = (atom.asymmetricParentAtom.isVisible && atom.asymmetricParentAtom.isVisibleEnabled)  ? 1.0 : -1.0
        let atomPosition: float4 = float4(x: Float(pos.x), y: Float(pos.y), z: Float(pos.z), w: w)
        let radius: Float = Float(atom.asymmetricParentAtom?.drawRadius ?? 1.0)
        
        let text: String
        switch(renderTextType)
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
        
        let instances = fontAtlas.buildMeshWithString(position: atomPosition, scale: float4(radius,radius,radius,1.0), text: text, alignment: self.atomTextAlignment)
        
        data += instances
      }
      return data
    }
  }
  
  public var renderAtoms: [RKInPerInstanceAttributesAtoms]
  {
    get
    {
      var index: Int = 0
      
      let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
      let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
      
      
      var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms](repeating: RKInPerInstanceAttributesAtoms(), count: atoms.count)
    
      index = 0
      for atom in atoms
      {
        
        let pos: double3 = atom.position
        
        //let w: Float = (atom.isVisible && atom.isVisibleEnabled) && !atomNode.isGroup ? 1.0 : -1.0
        let w: Float = (atom.asymmetricParentAtom.isVisible && atom.asymmetricParentAtom.isVisibleEnabled)  ? 1.0 : -1.0
        let atomPosition: float4 = float4(x: Float(pos.x), y: Float(pos.y), z: Float(pos.z), w: w)
        
        let radius: Double = atom.asymmetricParentAtom?.drawRadius ?? 1.0
        let ambient: NSColor = atom.asymmetricParentAtom?.color ?? NSColor.white
        let diffuse: NSColor = atom.asymmetricParentAtom?.color ?? NSColor.white
        let specular: NSColor = self.atomSpecularColor
        
        data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: float4(color: ambient), diffuse: float4(color: diffuse), specular: float4(color: specular), scale: Float(radius))
        index = index + 1
      }
      return data
    }
  }
  
  public var renderSelectedAtoms: [RKInPerInstanceAttributesAtoms]
  {
    return [RKInPerInstanceAttributesAtoms()]
  }
  
  public func CartesianPosition(for position: double3, replicaPosition: int3) -> double3
  {
    return position
  }
  
  public var renderSelectionStyle: RKSelectionStyle
  {
    get
    {
      return self.atomSelectionStyle
    }
    set(newValue)
    {
      self.atomSelectionStyle = newValue
    }
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
  
  public var renderSelectionScaling: Double
  {
    get
    {
      return self.selectionScaling
    }
    set(newValue)
    {
      self.selectionScaling = newValue
    }
  }
  
  public var renderSelectionStripesDensity: Double
  {
    get
    {
      return self.atomSelectionStripesDensity
    }
    set(newValue)
    {
      self.atomSelectionStripesDensity = newValue
    }
  }
  
  public var renderSelectionStripesFrequency: Double
  {
    get
    {
      return self.atomSelectionStripesFrequency
    }
    set(newValue)
    {
      self.atomSelectionStripesFrequency = newValue
    }
  }

  public var renderSelectionWorleyNoise3DFrequency: Double
  {
    get
    {
      return self.atomSelectionWorleyNoise3DFrequency
    }
    set(newValue)
    {
      self.atomSelectionWorleyNoise3DFrequency = newValue
    }
  }
  
  public var renderSelectionWorleyNoise3DJitter: Double
  {
    get
    {
      return self.atomSelectionWorleyNoise3DJitter
    }
    set(newValue)
    {
      self.atomSelectionWorleyNoise3DJitter = newValue
    }
  }
  
  public var renderSelectedBonds: [RKInPerInstanceAttributesBonds]
  {
    return [RKInPerInstanceAttributesBonds]()
  }
  

  
  public var renderUnitCellSpheres: [RKInPerInstanceAttributesAtoms]
  {
    let data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms]()
    
    return data
  }

  
  public var renderUnitCellCylinders:[RKInPerInstanceAttributesBonds]
  {
    let data: [RKInPerInstanceAttributesBonds] = [RKInPerInstanceAttributesBonds]()
    
    return data
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
  
  
  
  public var atomPositions: [double3]
  {
    return []
  }
  
  public var crystallographicPositions: [(double3, Int)]
  {
    return []
  }
  
  public var potentialParameters: [double2]
  {
    //let size: Int = self.atomPositions.count
    return []
  }
  
  public var bondPositions: [double3]
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
  
  public func translateSelection(by: double3)
  {
  
  }
  
  public func finalizeTranslateSelection(by: double3) -> (atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    return nil
  }
  
  public func computeChangedBondLength(bond: SKBondNode, to: Double) -> (double3,double3)
  {
    return (double3(0),double3(0))
  }
  
  public var renderCanDrawAdsorptionSurface: Bool {return false}
  
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    let calendar = Calendar.current
    
    encoder.encode(Structure.classVersionNumber)
    
    encoder.encode(self.displayName)
    encoder.encode(isVisible)
    
    //let number = try decoder.decode(UInt32.self)
    //let spaceGroup = SKSpacegroup(HallNumber: Int(number))
    encoder.encode(self.spaceGroupHallNumber ?? Int(1))
    encoder.encode(cell)
    encoder.encode(periodic)
    encoder.encode(origin)
    encoder.encode(scaling)
    encoder.encode(orientation)
    encoder.encode(rotationDelta)
    
    encoder.encode(Double(minimumGridEnergyValue ?? 0.0))
    
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
    encoder.encode(selectionScaling)
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
    
    
    
    encoder.encode(Int(1))
    let length: Int = self.bonds.arrangedObjects.count
    encoder.encode(length)
    for bond in self.bonds.arrangedObjects
    {
      encoder.encode(bond.atom1.tag)
      encoder.encode(bond.atom2.tag)
      encoder.encode(bond.boundaryType.rawValue)
    }
    
    
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
    origin = try decoder.decode(double3.self)
    scaling = try decoder.decode(double3.self)
    orientation = try decoder.decode(simd_quatd.self)
    rotationDelta = try decoder.decode(Double.self)
    
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
    selectionScaling = try decoder.decode(Double.self)
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
    self.atomTextOffset = try decoder.decode(double3.self)
    
    
    
    //bonds = try decoder.decode(SKBondSetController.self)
    // FIX!! and move to controller
    // bonds
    let _: Int = try decoder.decode(Int.self)
    let length: Int = Int(try decoder.decode(Int.self))
    var atom1Tags: [Int] = []
    var atom2Tags: [Int] = []
    var bondBoundaryTypes: [Int] = []
    for _ in 0..<length
    {
      let a = try decoder.decode(Int.self)
      let b = try decoder.decode(Int.self)
      let c = try decoder.decode(Int.self)
      atom1Tags.append(a)
      atom2Tags.append(b)
      bondBoundaryTypes.append(c)
    }
    
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
    
    if(self.atomRepresentationStyle == RepresentationStyle.licorice)
    {
      self.setRepresentationStyle(style: RepresentationStyle.licorice)
    }
  }
  
}

extension Structure: StructureViewer
{
  public var structureViewerStructures: [Structure]
  {
    return [self]
  }
  
  public var selectedRenderFrames: [RKRenderStructure]
  {
    return [self]
  }
  
  public var allFrames: [RKRenderStructure]
  {
    return [self]
  }
  
}
