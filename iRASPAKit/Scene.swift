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
import BinaryCodable
import LogViewKit
import SymmetryKit
import SimulationKit
import RenderKit
import MathKit
import simd

// An Movie is a list of Movie's. It is a set of actors that each contain a list of frames for that actor
public final class Scene: NSObject, Decodable,  AtomVisualAppearanceViewer, BondVisualAppearanceViewer, UnitCellVisualAppearanceViewer, CellViewer, InfoViewer, AdsorptionSurfaceVisualAppearanceViewer, PrimitiveVisualAppearanceViewer, BinaryDecodable, BinaryEncodable, NSPasteboardWriting, NSPasteboardReading
{
  // a Scene has a surface for the whole scene
  // all movies in the scene add to the scene potential energy surface
  private var versionNumber: Int = 1
  private static var classVersionNumber: Int = 1
  public var displayName : String = ""
  public var movies: [Movie] = []
  
  public var filteredAndSortedObjects: [Movie] = [Movie]()
  
  public weak var selectedMovie: Movie? = nil
  public var selectedMovies: Set< Movie > = Set()
  
  public var filterPredicate: (Movie) -> Bool = {_ in return true}
  var sortDescriptors: [NSSortDescriptor] = []
  
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
        
        iRASPAstructure.structure.atoms.rootNodes = atomTreeNodes
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
        
        // tag all the atoms with identifers from 0,..,N-1
        iRASPAstructure.structure.tag(atoms: iRASPAstructure.structure.atoms)
        
        // compute the bounding-box of the atoms
        iRASPAstructure.structure.reComputeBoundingBox()
        
        iRASPAstructure.structure.setRepresentationForceField(forceField: "Default", forceFieldSet: defaultForceField)
        iRASPAstructure.structure.setRepresentationColorScheme(colorSet: defaultColorSet)
        
        // set creator etc
        iRASPAstructure.structure.structureMaterialType = "MOF"
        iRASPAstructure.structure.setRepresentationStyle(style: .default)
        
        iRASPAstructure.structure.reComputeBonds()
        
        movie.frames.append(iRASPAstructure)
      }
      self.movies.append(movie)
    }
  }
  
  public var renderCanDrawAdsorptionSurface: Bool
  {
    return self.movies.reduce(into: false, {$0 = $0 || $1.renderCanDrawAdsorptionSurface})
  }
  
  public override var description: String
  {
    return "Scene (\(super.description)), arranged movie-objects: \(self.movies)"
  }
  
  /*
  var currentFrame: Int?
  {
    get
    {
      return nil
    }
    set(newValue)
    {
      for movie: Movie in self.movies
      {
        movie.currentFrame = newValue
      }
    }
  }*/
  
  
  deinit
  {
    //Swift.print("Deallocing FKArrayController \(T.self)")
  }
  
  
  // MARK: -
  // MARK: Legacy decodable support
  
  public required init(from decoder: Decoder) throws
  {
    var container = try decoder.unkeyedContainer()
    
    let versionNumber: Int = try container.decode(Int.self)
    if versionNumber > self.versionNumber
    {
      throw iRASPAError.invalidArchiveVersion
    }
    
    self.displayName = try container.decode(String.self)
    self.movies  = try container.decode([Movie].self)
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
    //let propertyListEncoder: PropertyListEncoder = PropertyListEncoder()
    //let data: Data = try! propertyListEncoder.encode(self)
    //return data
    
    let binaryEncoder: BinaryEncoder = BinaryEncoder()
    binaryEncoder.encode(self)
    return Data(binaryEncoder.data)
    
    //return NSArchiver.archivedData(withRootObject: self.movies)
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
  public var structureViewerStructures: [Structure]
  {
    return self.movies.flatMap{$0.structureViewerStructures}
  }
  
  public var selectedRenderFrames: [RKRenderStructure]
  {
    return self.movies.flatMap{$0.selectedRenderFrames}
  }
  
  public var allFrames: [RKRenderStructure]
  {
    return self.movies.flatMap{$0.allFrames}
  }
}






