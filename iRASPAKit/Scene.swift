/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import BinaryCodable
import LogViewKit
import SymmetryKit
import SimulationKit
import RenderKit
import MathKit
import simd

// An Movie is a list of Movie's. It is a set of actors that each contain a list of frames for that actor
public final class Scene: NSObject, AtomVisualAppearanceViewer, BondVisualAppearanceViewer, UnitCellVisualAppearanceViewer, CellViewer, InfoViewer, AdsorptionSurfaceVisualAppearanceViewer, BinaryDecodable, BinaryEncodable, NSPasteboardWriting, NSPasteboardReading
{
  // a Scene has a surface for the whole scene
  // all movies in the scene add to the scene potential energy surface
  private static var classVersionNumber: Int = 1
  public var displayName : String = ""
  public var movies: [Movie] = []
  
  public var filteredAndSortedObjects: [Movie] = [Movie]()
  
  public weak var selectedMovie: Movie? = nil
  public var selectedMovies: Set< Movie > = Set()
  
  public var filterPredicate: (Movie) -> Bool = {_ in return true}
  var sortDescriptors: [NSSortDescriptor] = []
  
  public var frames: [iRASPAStructure]
  {
    return self.movies.flatMap{$0.frames}
  }
  
  public override init()
  {
    movies = []
  }
  
  public init(scene: Scene)
  {
    self.displayName = scene.displayName
    self.movies = scene.movies
  }
  
  
  public convenience init(movies: [Movie])
  {
    self.init()
    self.movies = movies
  }
  
  public convenience init(name: String, movies: [Movie])
  {
    self.init()
    self.displayName = name
    self.movies = movies
  }
  
  public convenience init(parser: [[SKStructure]])
  {
    self.init()
    
    let defaultForceField: SKForceFieldSet = SKForceFieldSet()
    let defaultColorSet: SKColorSet = SKColorSet(colorScheme: SKColorSets.ColorScheme.jmol)
    
    for movies in parser
    {
      let movie: Movie = Movie()
      movie.displayName = movies.first?.displayName ?? "new"
      self.displayName = movie.displayName
      
      for frame in movies
      {
        let spaceGroupHallNumber: Int = frame.spaceGroupHallNumber ?? 1
        let spaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: spaceGroupHallNumber)
        
        let atoms: [SKAsymmetricAtom] = frame.atoms
        let cell: SKCell = frame.cell ?? SKCell(a: 20.0, b: 20.0, c: 20.0, alpha: 90.0*Double.pi/180.0, beta: 90.0*Double.pi/180.0, gamma: 90.0*Double.pi/180.0)
        
        // create the appropriate type of structure
        let displayName: String = frame.displayName ?? "new"
        let iRASPAstructure: iRASPAStructure
        switch(frame.kind)
        {
        case .molecule:
          let molecule = Molecule(name: displayName)
          molecule.cell = cell
          molecule.drawUnitCell = false
          iRASPAstructure = iRASPAStructure(molecule: molecule)
          for i in 0..<atoms.count
          {
            if atoms[i].fractional
            {
              atoms[i].fractional = false
              let newposition = cell.fullCell * atoms[i].position
              atoms[i].position = newposition
            }
          }
        case .protein:
          let protein = Protein(name: displayName)
          protein.cell = cell
          protein.drawUnitCell = false
          iRASPAstructure = iRASPAStructure(protein: protein)
          for i in 0..<atoms.count
          {
            if atoms[i].fractional
            {
              atoms[i].fractional = false
              let newposition = cell.fullCell * atoms[i].position
              atoms[i].position = newposition
            }
          }
        case .crystal:
          let crystal = Crystal(name: displayName)
          crystal.cell = cell
          crystal.drawUnitCell = true
          crystal.spaceGroup = spaceGroup
          iRASPAstructure = iRASPAStructure(crystal: crystal)
          for i in 0..<atoms.count
          {
            if !atoms[i].fractional
            {
              atoms[i].fractional = true
              let newposition = cell.inverseFullCell * atoms[i].position
              atoms[i].position = newposition
            }
          }
        case .molecularCrystal:
          let molecularCrystal = MolecularCrystal(name: displayName)
          molecularCrystal.cell = cell
          molecularCrystal.spaceGroup = spaceGroup
          molecularCrystal.drawUnitCell = true
          iRASPAstructure = iRASPAStructure(molecularCrystal: molecularCrystal)
          for i in 0..<atoms.count
          {
            if atoms[i].fractional
            {
              atoms[i].fractional = false
              let newposition = cell.fullCell * atoms[i].position
              atoms[i].position = newposition
            }
          }
        case .proteinCrystal:
          let proteinCrystal = ProteinCrystal(name: displayName)
          proteinCrystal.cell = cell
          proteinCrystal.spaceGroup = spaceGroup
          proteinCrystal.drawUnitCell = true
          iRASPAstructure = iRASPAStructure(proteinCrystal: proteinCrystal)
          for i in 0..<atoms.count
          {
            if atoms[i].fractional
            {
              atoms[i].fractional = false
              let newposition = cell.fullCell * atoms[i].position
              atoms[i].position = newposition
            }
          }
        case .proteinCrystalSolvent:
          let proteinCrystal = ProteinCrystal(name: "SOLVENT")
          movie.displayName = "SOLVENT"
          proteinCrystal.cell = cell
          proteinCrystal.spaceGroup = spaceGroup
          proteinCrystal.drawUnitCell = true
          iRASPAstructure = iRASPAStructure(proteinCrystal: proteinCrystal)
          for i in 0..<atoms.count
          {
            if atoms[i].fractional
            {
              atoms[i].fractional = false
              let newposition = cell.fullCell * atoms[i].position
              atoms[i].position = newposition
            }
          }
        case .crystalSolvent:
          iRASPAstructure = iRASPAStructure(structure: Structure(name: displayName))
        case .structure:
          iRASPAstructure = iRASPAStructure(structure: Structure(name: displayName))
        default:
          fatalError()
        }
        
        if let chemicalFormulaSum: String = frame.chemicalFormulaSum
        {
          iRASPAstructure.structure.chemicalFormulaSum = chemicalFormulaSum
        }
        if let chemicalFormulaStructural: String = frame.chemicalFormulaStructural
        {
          iRASPAstructure.structure.chemicalFormulaMoiety = chemicalFormulaStructural
        }
        
        for unknownAtom in frame.unknownAtoms
        {
          LogQueue.shared.warning(destination: nil, message: "\(displayName): unknown chemical element of atom-name \(unknownAtom)")
        }
        
        var atomTreeNodes: [SKAtomTreeNode] = []
        for atom in atoms
        {
          let atomicNumber: Int = atom.elementIdentifier
          let elementString: String = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
          let color: NSColor = defaultColorSet[elementString] ?? NSColor.black
          let drawRadius: Double = iRASPAstructure.structure.drawRadius(elementId: atomicNumber)
          let bondDistanceCriteria: Double = defaultForceField[displayName]?.userDefinedRadius ?? 1.0
          
          let structureAtom: SKAsymmetricAtom = SKAsymmetricAtom(modelAtom: atom, color: color, drawRadius: drawRadius, bondDistanceCriteria: bondDistanceCriteria)
          
          let node = SKAtomTreeNode(representedObject: structureAtom)
          atomTreeNodes.append(node)
        }
        
        iRASPAstructure.structure.atomTreeController.rootNodes = atomTreeNodes
        iRASPAstructure.structure.expandSymmetry()
        
        if let drawUnitCell: Bool = frame.drawUnitCell
        {
          iRASPAstructure.structure.drawUnitCell = drawUnitCell
        }
        
        if let numberOfChannels: Int = frame.numberOfChannels
        {
          iRASPAstructure.structure.structureNumberOfChannelSystems = numberOfChannels
        }
        
        if let numberOfPockets: Int = frame.numberOfPockets
        {
          iRASPAstructure.structure.structureNumberOfInaccessiblePockets = numberOfPockets
        }
        
        if let dimensionality: Int = frame.dimensionality
        {
          iRASPAstructure.structure.structureDimensionalityOfPoreSystem = dimensionality
        }
        
        if let Di: Double = frame.Di
        {
          iRASPAstructure.structure.structureLargestCavityDiameter = Di
        }
        
        if let Df: Double = frame.Df
        {
          iRASPAstructure.structure.structureRestrictingPoreLimitingDiameter = Df
        }
        
        if let Dif: Double = frame.Dif
        {
          iRASPAstructure.structure.structureLargestCavityDiameterAlongAViablePath = Dif
        }
        
        // compute the bounding-box of the atoms
        iRASPAstructure.structure.reComputeBoundingBox()
        
        // set creator etc
        //setToCoreMOFStyle(structure: iRASPAstructure.structure)
        iRASPAstructure.structure.structureMaterialType = "MOF"
        iRASPAstructure.structure.setRepresentationStyle(style: .default)
        
        iRASPAstructure.structure.setRepresentationForceField(forceField: "Default", forceFieldSet: defaultForceField)
        iRASPAstructure.structure.setRepresentationColorScheme(colorSet: defaultColorSet)
        
        iRASPAstructure.structure.reComputeBonds()
        
        iRASPAstructure.structure.atomTreeController.tag()
        iRASPAstructure.structure.bondController.tag()
        
        movie.frames.append(iRASPAstructure)
      }
      self.movies.append(movie)
    }
  }
  
  private func setToCoreMOFStyle(structure: Structure)
  {
    debugPrint("YEAAH")
    structure.atomRepresentationStyle = .fancy
    
    structure.structureMaterialType = "MOF"
    structure.setRepresentationStyle(style: .fancy)
    
    let calender = NSCalendar.current
    var dateComponents: DateComponents = DateComponents()
    dateComponents.year = 2014
    dateComponents.month = 10
    dateComponents.day = 4
    let date: Date = calender.date(from: dateComponents)!

    structure.authorFirstName = "Yongchul"
    structure.authorMiddleName = " "
    structure.authorLastName = "Chung"
    structure.authorOrchidID = ""
    structure.authorResearcherID = ""
    structure.authorAffiliationUniversityName = "Northwestern University"
    structure.authorAffiliationFacultyName = ""
    structure.authorAffiliationInstituteName = "Department of Chemical and Biological Engineering"
    structure.authorAffiliationCityName = "Evanston"
    structure.authorAffiliationCountryName = Locale.current.localizedString(forRegionCode: "US") ?? "Netherlands"
    structure.creationDate = date
    structure.creationTemperature = ""
    structure.creationTemperatureScale = .Kelvin
    structure.creationPressure = ""
    structure.creationPressureScale = .Pascal
    structure.creationMethod = .simulation
    structure.creationUnitCellRelaxationMethod = .allFixed
    structure.creationAtomicPositionsSoftwarePackage = "Materials Studio"
    structure.creationAtomicPositionsIonsRelaxationAlgorithm = .none
    structure.creationAtomicPositionsIonsRelaxationCheck = .none
    structure.creationAtomicPositionsForcefield = ""
    structure.creationAtomicPositionsForcefieldDetails = ""
    structure.creationAtomicChargesSoftwarePackage = ""
    structure.creationAtomicChargesAlgorithms = ""
    structure.creationAtomicChargesForcefield = ""
    structure.creationAtomicChargesForcefieldDetails = ""
    structure.citationArticleTitle = "Computation-Ready, Experimental Metal-Organic Frameworks: A Tool to Enable High-Throughput Computation of Nanoporous Crystals"
    structure.citationJournalTitle = "Chemistry of Materials"
    structure.citationAuthors = "Y.G. Chung, J. Camp, M. Haranczyk, B.J. Sikora, W. Bury, V. Krungleviciute, T. Yildirim, O.K. Farha, D.S.   and R.Q. Snurr"
    structure.citationJournalVolume = "26"
    structure.citationJournalNumber = "21"
    structure.citationJournalPageNumbers = "6185-6192"
    structure.citationDOI = "10.1021/cm502594j"
    structure.citationPublicationDate = date
    structure.citationDatebaseCodes = ""
  }
  
  private func setToDDECStyle(structure: Structure)
  {
    structure.atomRepresentationStyle = .fancy
    structure.structureMaterialType = "MOF"
    structure.setRepresentationStyle(style: .fancy)
    
    let calender = NSCalendar.current
    var dateComponents: DateComponents = DateComponents()
    dateComponents.year = 2016
    dateComponents.month = 1
    dateComponents.day = 7
    let date: Date = calender.date(from: dateComponents)!

    structure.authorFirstName = "Dalar"
    structure.authorMiddleName = " "
    structure.authorLastName = "Nazarian"
    structure.authorOrchidID = ""
    structure.authorResearcherID = ""
    structure.authorAffiliationUniversityName = "Georgia Institute of Technology"
    structure.authorAffiliationFacultyName = ""
    structure.authorAffiliationInstituteName = "School of Chemical & Biomolecular Engineering"
    structure.authorAffiliationCityName = "Atlanta"
    structure.authorAffiliationCountryName = Locale.current.localizedString(forRegionCode: "US") ?? "Netherlands"
    structure.creationDate = date
    structure.creationTemperature = ""
    structure.creationTemperatureScale = .Kelvin
    structure.creationPressure = ""
    structure.creationPressureScale = .Pascal
    structure.creationMethod = .simulation
    structure.creationUnitCellRelaxationMethod = .allFixed
    structure.creationAtomicPositionsSoftwarePackage = "Materials Studio"
    structure.creationAtomicPositionsIonsRelaxationAlgorithm = .none
    structure.creationAtomicPositionsIonsRelaxationCheck = .none
    structure.creationAtomicPositionsForcefield = ""
    structure.creationAtomicPositionsForcefieldDetails = ""
    structure.creationAtomicChargesSoftwarePackage = "VASP 5.3.5"
    structure.creationAtomicChargesAlgorithms = "DDEC"
    structure.creationAtomicChargesForcefield = ""
    structure.creationAtomicChargesForcefieldDetails = ""
    structure.citationArticleTitle = "A Comprehensive Set of High-Quality Point Charges for Simulations of Metal-Organic Frameworks"
    structure.citationJournalTitle = "Chemistry of Materials"
    structure.citationAuthors = "D. Nazarian, J. Camp, and D.S. Sholl"
    structure.citationJournalVolume = "28"
    structure.citationJournalNumber = "3"
    structure.citationJournalPageNumbers = "785-793"
    structure.citationDOI = "10.1021/acs.chemmater.5b03836"
    structure.citationPublicationDate = date
    structure.citationDatebaseCodes = ""
  }
  
  private func setToIZAStyle(structure: Structure)
  {
    structure.atomRepresentationStyle = .default
    structure.structureMaterialType = "Zeolite"
    structure.setRepresentationStyle(style: .default)
    
    structure.drawAdsorptionSurface = true
    structure.adsorptionSurfaceFrontSideDiffuseColor = NSColor.init(colorCode: 0xFFFF66)
    structure.adsorptionSurfaceBackSideDiffuseColor = NSColor.init(colorCode: 0x80FF00)
    
    let calender = NSCalendar.current
    var dateComponents: DateComponents = DateComponents()
    dateComponents.year = 2017
    dateComponents.month = 3
    dateComponents.day = 17
    let date: Date = calender.date(from: dateComponents)!

    var dateComponents2: DateComponents = DateComponents()
    dateComponents2.year = 2007
    dateComponents2.month = 2
    dateComponents2.day = 1
    let date2: Date = calender.date(from: dateComponents2)!

    structure.authorFirstName = "Christian"
    structure.authorMiddleName = " "
    structure.authorLastName = "Baerlocher"
    structure.authorOrchidID = ""
    structure.authorResearcherID = ""
    structure.authorAffiliationUniversityName = "ETH Zürich"
    structure.authorAffiliationFacultyName = ""
    structure.authorAffiliationInstituteName = "Laboratorium f. Kristallographie"
    structure.authorAffiliationCityName = "Zürich"
    structure.authorAffiliationCountryName = Locale.current.localizedString(forRegionCode: "CH") ?? "Netherlands"
    structure.creationDate = date
    structure.creationTemperature = ""
    structure.creationTemperatureScale = .Kelvin
    structure.creationPressure = ""
    structure.creationPressureScale = .Pascal
    structure.creationMethod = .simulation
    structure.creationUnitCellRelaxationMethod = .unknown
    structure.creationAtomicPositionsSoftwarePackage = "DLS76"
    structure.creationAtomicPositionsIonsRelaxationAlgorithm = .none
    structure.creationAtomicPositionsIonsRelaxationCheck = .none
    structure.creationAtomicPositionsForcefield = ""
    structure.creationAtomicPositionsForcefieldDetails = ""
    structure.creationAtomicChargesSoftwarePackage = ""
    structure.creationAtomicChargesAlgorithms = ""
    structure.creationAtomicChargesForcefield = ""
    structure.creationAtomicChargesForcefieldDetails = ""
    structure.citationArticleTitle = "Atlas of Zeolite Framework Types"
    structure.citationJournalTitle = "Elsevier"
    structure.citationAuthors = "Christian Baerlocher, Lynne B. McCusker and David H. Olson "
    structure.citationJournalVolume = ""
    structure.citationJournalNumber = ""
    structure.citationJournalPageNumbers = ""
    structure.citationDOI = "978-0-444-53064-6"
    structure.citationPublicationDate = date2
    structure.citationDatebaseCodes = ""
  }
  
  public var renderCanDrawAdsorptionSurface: Bool
  {
    return self.movies.reduce(into: false, {$0 = $0 || $1.renderCanDrawAdsorptionSurface})
  }
  
  public override var description: String
  {
    return "Scene (\(super.description)), arranged movie-objects: \(self.movies)"
  }
  
  // MARK: -
  // MARK: NSPasteboardWriting support
  
  // 1) an object added to the pasteboard will first be sent an 'writableTypesForPasteboard' message
  // 2) the object will then receive an 'pasteboardPropertyListForType' for each of these types
  
  
  public func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
  {
    return [NSPasteboard.PasteboardType(NSPasteboardTypeStructure)]
  }
  
  
  public func writingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.WritingOptions
  {
    return NSPasteboard.WritingOptions.promised
  }
  
  public func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any?
  {
    let binaryEncoder: BinaryEncoder = BinaryEncoder()
    binaryEncoder.encode(self)
    return Data(binaryEncoder.data)
  }
  
  
  // MARK: -
  // MARK: NSPasteboardReading support
  
  // 1) the pasteboard will try to find a class that can read pasteboard data, sending it an 'readableTypesForPasteboard' message
  // 2) once such a class had been found, it will sent the class an 'init' message
  
  public class func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions
  {
    return NSPasteboard.ReadingOptions()
  }
  
  public class func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
  {
    return [NSPasteboard.PasteboardType(NSPasteboardTypeStructure)]
  }
  
  public convenience required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType)
  {
    guard let data: Data = propertyList as? Data,
          let scene: Scene = try? BinaryDecoder(data: [UInt8](data)).decode(Scene.self) else
    {
      return nil
    }
    self.init(scene: scene)
  }
  
  public static func ==(lhs: Scene, rhs: Scene) -> Bool
  {
    return lhs === rhs
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(Scene.classVersionNumber)
    encoder.encode(self.displayName)
    encoder.encode(self.movies)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > Scene.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.displayName = try decoder.decode(String.self)
    self.movies  = try decoder.decode([Movie].self)
  }
}



// MARK: -
// MARK: StructureViewer protocol implementation

extension Scene: StructureViewer
{
  public var allStructures: [Structure]
  {
    return self.movies.flatMap{$0.allStructures}
  }
  
  public var allIRASPAStructures: [iRASPAStructure]
  {
    return self.movies.flatMap{$0.allIRASPAStructures}
  }
  
  public var selectedRenderFrames: [RKRenderStructure]
  {
    return self.movies.flatMap{$0.selectedRenderFrames}
  }
  
  public var allRenderFrames: [RKRenderStructure]
  {
    return self.movies.flatMap{$0.allRenderFrames}
  }
}

extension Scene: PrimitiveVisualAppearanceViewer
{
  public var allPrimitiveStructure: [Structure]
  {
    return self.movies.flatMap{$0.allPrimitiveStructure}
  }
}








