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
import BinaryCodable
import RenderKit
import SimulationKit
import SymmetryKit
import LogViewKit
import MathKit

public let NSPasteboardTypeFrame: NSPasteboard.PasteboardType = NSPasteboard.PasteboardType("nl.iRASPA.Frame")

fileprivate let crystalIcon: NSImage = NSImage(named: "CrystalIcon")!
fileprivate let molecularIcon: NSImage = NSImage(named: "MolecularIcon")!
fileprivate let molecularCrystalIcon: NSImage = NSImage(named: "MolecularCrystalIcon")!
fileprivate let proteinIcon: NSImage = NSImage(named: "ProteinIcon")!
fileprivate let proteinCrystalIcon: NSImage = NSImage(named: "ProteinCrystalIcon")!
fileprivate let ellipsoidIcon: NSImage = NSImage(named: "EllipsoidIcon")!
fileprivate let ellipsoidCrystalIcon: NSImage = NSImage(named: "EllipsoidCrystalIcon")!
fileprivate let cylinderIcon: NSImage = NSImage(named: "CylinderIcon")!
fileprivate let cylinderCrystalIcon: NSImage = NSImage(named: "CylinderCrystalIcon")!
fileprivate let prismIcon: NSImage = NSImage(named: "PrismIcon")!
fileprivate let prismCrystalIcon: NSImage = NSImage(named: "PrismCrystalIcon")!
fileprivate let unknownIcon: NSImage = NSImage(named: "UnknownIcon")!

public final class iRASPAStructure: NSObject, BinaryDecodable, BinaryEncodable, NSPasteboardReading, NSPasteboardWriting, AtomVisualAppearanceViewer, BondVisualAppearanceViewer, UnitCellVisualAppearanceViewer, AdsorptionSurfaceVisualAppearanceViewer, InfoViewer, CellViewer, PrimitiveVisualAppearanceViewer, Copying
{
  
  
  public static func == (lhs: iRASPAStructure, rhs: iRASPAStructure) -> Bool
  {
    return lhs.structure === rhs.structure
  }
  
  public var type: SKStructure.Kind
  public var structure: Structure
  
  public init(structure: Structure)
  {
    self.type = .structure
    self.structure = structure
  }
  
  public init(crystal: Crystal)
  {
    self.type = .crystal
    self.structure = crystal
  }
  
  public init(molecularCrystal: MolecularCrystal)
  {
    self.type = .molecularCrystal
    self.structure = molecularCrystal
  }
  
  public init(proteinCrystal: ProteinCrystal)
  {
    self.type = .proteinCrystal
    self.structure = proteinCrystal
  }
  
  public init(molecule: Molecule)
  {
    self.type = .molecule
    self.structure = molecule
  }
  
  public init(protein: Protein)
  {
    self.type = .protein
    self.structure = protein
  }
  
  public init(crystalEllipsoidPrimitive: CrystalEllipsoidPrimitive)
  {
    self.type = .crystalEllipsoidPrimitive
    self.structure = crystalEllipsoidPrimitive
  }
   
  public init(crystalPolygonalPrismPrimitive: CrystalPolygonalPrismPrimitive)
  {
    self.type = .crystalPolygonalPrismPrimitive
    self.structure = crystalPolygonalPrismPrimitive
  }
   
  public init(crystalCylinderPrimitive: CrystalCylinderPrimitive)
  {
    self.type = .crystalCylinderPrimitive
    self.structure = crystalCylinderPrimitive
  }

  public init(ellipsoidPrimitive: EllipsoidPrimitive)
  {
    self.type = .ellipsoidPrimitive
    self.structure = ellipsoidPrimitive
  }
  
  public init(polygonalPrismPrimitive: PolygonalPrismPrimitive)
  {
    self.type = .polygonalPrismPrimitive
    self.structure = polygonalPrismPrimitive
  }
  
  public init(cylinderPrimitive: CylinderPrimitive)
  {
    self.type = .cylinderPrimitive
    self.structure = cylinderPrimitive
  }
  
  public init(frame: iRASPAStructure)
  {
    self.type = frame.type
    self.structure = frame.structure
  }
  
  
  public init(original: iRASPAStructure)
  {
    self.type = original.type
    
    switch(original.structure)
    {
    case let structure as Crystal:
      self.structure = structure.copy()
    case let structure as MolecularCrystal:
      self.structure = structure.copy()
    case let structure as Molecule:
      self.structure = structure.copy()
    case let structure as Protein:
      self.structure = structure.copy()
    case let structure as ProteinCrystal:
      self.structure = structure.copy()
    case let structure as CrystalEllipsoidPrimitive:
      self.structure = structure.copy()
    case let structure as CrystalCylinderPrimitive:
      self.structure = structure.copy()
    case let structure as CrystalPolygonalPrismPrimitive:
      self.structure = structure.copy()
    case let structure as EllipsoidPrimitive:
      self.structure = structure.copy()
    case let structure as CylinderPrimitive:
      self.structure = structure.copy()
    case let structure as PolygonalPrismPrimitive:
      self.structure = structure.copy()
    default:
      self.structure = original.structure.copy()
    }
  }
  
  private convenience init?(treeNode data: Data)
  {
    let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
    guard let node: ProjectTreeNode = try? binaryDecoder.decode(ProjectTreeNode.self, decodeRepresentedObject: true, decodeChildren: false) else {return nil}
    guard let project: ProjectStructureNode = node.representedObject.project as? ProjectStructureNode else {return nil}
    guard let firstFrame: iRASPAStructure = project.sceneList.scenes.first?.movies.first?.frames.first else {return nil}
    self.init(frame: firstFrame)
  }
  
  private convenience init?(movie data: Data)
  {
    let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
    guard let movie: Movie = try? binaryDecoder.decode(Movie.self) else {return nil}
    guard let firstFrame: iRASPAStructure = movie.frames.first else {return nil}
    self.init(frame: firstFrame)
  }
  
  private convenience init?(frame data: Data)
  {
    let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
    guard let frame: iRASPAStructure = try? binaryDecoder.decode(iRASPAStructure.self) else {return nil}
    self.init(frame: frame)
  }
  
  private convenience init?(iraspa data: Data)
  {
    guard let data = data.decompress(withAlgorithm: .lzma) else {return nil}
    let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
    guard let node: ProjectTreeNode = try? binaryDecoder.decode(ProjectTreeNode.self, decodeRepresentedObject: true, decodeChildren: false) else {return nil}
    node.unwrapLazyLocalPresentedObjectIfNeeded()
    guard let project = node.representedObject.project as? ProjectStructureNode else {return nil}
    guard let frame = project.sceneList.scenes.first?.movies.first?.frames.first else {return nil}
    self.init(frame: frame)
  }
  
  private convenience init?(displayName: String, poscar data: Data)
  {
    guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
    let poscarParser: SKPOSCARParser = SKPOSCARParser(displayName: displayName, string: dataString, windowController: nil)
    try? poscarParser.startParsing()
    let scene: Scene = Scene(parser: poscarParser.scene)
    guard let frame = scene.movies.first?.frames.first else {return nil}
    self.init(frame: frame)
  }
  
  private convenience init?(displayName: String, xdatcar data: Data)
  {
    guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
    let poscarParser: SKXDATCARParser = SKXDATCARParser(displayName: displayName, string: dataString, windowController: nil)
    try? poscarParser.startParsing()
    let scene: Scene = Scene(parser: poscarParser.scene)
    guard let frame = scene.movies.first?.frames.first else {return nil}
    self.init(frame: frame)
  }
  
  private convenience init?(displayName: String, cif data: Data)
  {
    guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
    let cifParser: SKCIFParser = SKCIFParser(displayName: displayName, string: dataString, windowController: nil)
    try? cifParser.startParsing()
    let scene: Scene = Scene(parser: cifParser.scene)
    guard let frame = scene.movies.first?.frames.first else {return nil}
    self.init(frame: frame)
  }
  
  private convenience init?(displayName: String, pdb data: Data)
  {
    guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
    let pdbParser: SKPDBParser = SKPDBParser(displayName: displayName, string: dataString, windowController: nil, onlyAsymmetricUnit: true, asMolecule: false)
    try? pdbParser.startParsing()
    let scene: Scene = Scene(parser: pdbParser.scene)
    guard let frame = scene.movies.first?.frames.first else {return nil}
    self.init(frame: frame)
  }
  
  private convenience init?(displayName: String, xyz data: Data)
  {
    guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
    let xyzParser: SKXYZParser = SKXYZParser(displayName: displayName, string: dataString, windowController: nil)
    try? xyzParser.startParsing()
    let scene: Scene = Scene(parser: xyzParser.scene)
    guard let frame = scene.movies.first?.frames.first else {return nil}
    self.init(frame: frame)
  }
  
  public var infoPanelIcon: NSImage
  {
    switch(structure.materialType)
    {
    case .crystal:
      return crystalIcon
    case .molecularCrystal:
      return molecularCrystalIcon
    case .molecule:
      return molecularIcon
    case .protein:
      return proteinIcon
    case .proteinCrystal:
      return proteinCrystalIcon
    case .crystalEllipsoidPrimitive:
      return ellipsoidCrystalIcon
    case .crystalCylinderPrimitive:
      return cylinderCrystalIcon
    case .crystalPolygonalPrismPrimitive:
      return prismCrystalIcon
    case .ellipsoidPrimitive:
      return ellipsoidIcon
    case .cylinderPrimitive:
      return cylinderIcon
    case .polygonalPrismPrimitive:
      return prismIcon
    default:
      return unknownIcon
    }
  }
  
  public var totalNumberOfAtoms: Int
  {
    return self.structure.atomTreeController.flattenedLeafNodes().reduce(0, { (Result: Int, atomTreeNode: SKAtomTreeNode) -> Int in
      return Result + atomTreeNode.representedObject.copies.filter{$0.type == .copy}.count
    })
  }
  
  public var infoPanelString: String
  {
    return structure.displayName + " (\(self.totalNumberOfAtoms) atoms)"
  }
  
  public var allPrimitiveStructure: [Structure]
  {
    switch(self.type)
    {
    case .crystalCylinderPrimitive, .crystalEllipsoidPrimitive, .crystalPolygonalPrismPrimitive,
         .cylinderPrimitive, .ellipsoidPrimitive, .polygonalPrismPrimitive:
      return [self.structure]
    default:
      return []
    }
    
  }
  
  public var allStructures: [Structure]
  {
    return [self.structure]
  }
  
  public var frames: [iRASPAStructure]
  {
    return [self]
  }
  
  public var allIRASPAStructures: [iRASPAStructure]
  {
    return [self]
  }
  
  public var selectedRenderFrames: [RKRenderStructure]
  {
    return [self.structure]
  }
  
  public var allRenderFrames: [RKRenderStructure]
  {
    return [self.structure]
  }
  
  
  public func swapRepresentedObjects(structure: iRASPAStructure)
  {
    let temptype = self.type
    self.type = structure.type
    structure.type = temptype
    
    let temp = self.structure
    self.structure = structure.structure
    structure.structure = temp
  }
  
 
  
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let type: SKStructure.Kind = SKStructure.Kind(rawValue: try decoder.decode(Int.self)) ?? .structure
    self.type = type
    
    switch(type)
    {
    case .structure:
      self.structure = try decoder.decode(Structure.self)
    case .crystal:
      self.structure = try decoder.decode(Crystal.self)
    case .molecularCrystal:
      self.structure = try decoder.decode(MolecularCrystal.self)
    case .molecule:
      self.structure = try decoder.decode(Molecule.self)
    case .protein:
      self.structure = try decoder.decode(Protein.self)
    case .proteinCrystal:
      self.structure = try decoder.decode(ProteinCrystal.self)
    case .crystalEllipsoidPrimitive:
      self.structure = try decoder.decode(CrystalEllipsoidPrimitive.self)
    case .crystalCylinderPrimitive:
      self.structure = try decoder.decode(CrystalCylinderPrimitive.self)
    case .crystalPolygonalPrismPrimitive:
      self.structure = try decoder.decode(CrystalPolygonalPrismPrimitive.self)
    case .ellipsoidPrimitive:
      self.structure = try decoder.decode(EllipsoidPrimitive.self)
    case .cylinderPrimitive:
      self.structure = try decoder.decode(CylinderPrimitive.self)
    case .polygonalPrismPrimitive:
      self.structure = try decoder.decode(PolygonalPrismPrimitive.self)
    default:
      throw BinaryDecodableError.invalidArchiveVersion
    }
  }
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(type.rawValue)
    encoder.encode(structure)
  }
  
  public var renderStructure: RKRenderStructure
  {
    return structure as RKRenderStructure
  }
  
  public var hasSelectedObjects: Bool
  {
    return structure.hasSelectedObjects
  }
  
  public var renderCanDrawAdsorptionSurface: Bool
  {
    return structure.renderCanDrawAdsorptionSurface
  }
  
  // MARK: -
  // MARK: NSPasteboardReading support
  
  public class func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions
  {
    return NSPasteboard.ReadingOptions()
  }
  
  public class func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
  {
    return [NSPasteboardTypeFrame,
            NSPasteboardTypeMovie,
            NSPasteboardTypeProjectTreeNode,
            NSPasteboard.PasteboardType.fileURL] // NSPasteboard.PasteboardType.fileURL
  }
  
  public convenience init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType)
  {
    guard let data: Data = propertyList as? Data else {return nil}
    
    switch(type)
    {
    case NSPasteboardTypeProjectTreeNode:
      self.init(treeNode: data)
    case NSPasteboardTypeMovie:
      self.init(movie: data)
    case NSPasteboardTypeFrame:
      self.init(frame: data)
    case NSPasteboard.PasteboardType.fileURL:
      guard let str = String(data: data, encoding: .utf8),
            let url = URL(string: str),
            FileManager.default.fileExists(atPath: url.path),
            let data: Data = try? Data(contentsOf: url, options: []) else {return nil}
    
      let displayName: String = url.deletingPathExtension().lastPathComponent
        
      if #available(OSX 11.0, *)
      {
        guard let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
              let type = resourceValues.contentType else {return nil}
          
        switch(type)
        {
        case _ where type.conforms(to: .iraspa):
          self.init(iraspa: data)
        case _ where type.conforms(to: .poscar) || (url.pathExtension.isEmpty && (url.lastPathComponent.uppercased() == "POSCAR" || url.lastPathComponent.uppercased() == "CONTCAR")):
          self.init(displayName: displayName, poscar: data)
        case _ where (url.pathExtension.isEmpty && (url.lastPathComponent.uppercased() == "XDATCAR")):
          self.init(displayName: displayName, xdatcar: data)
        case _ where type.conforms(to: .cif):
          self.init(displayName: displayName, cif: data)
        case _ where type.conforms(to: .pdb):
          self.init(displayName: displayName, pdb: data)
        case _ where type.conforms(to: .xyz):
          self.init(displayName: displayName, xyz: data)
        default:
          return nil
        }
      }
      else
      {
        guard let resourceValues = try? url.resourceValues(forKeys: [.typeIdentifierKey]),
              let type = resourceValues.typeIdentifier else {return nil}
          
        switch(type)
        {
        case _ where UTTypeConformsTo(type as CFString, typeProject as CFString):
          self.init(iraspa: data)
        case _ where UTTypeConformsTo(type as CFString, typePOSCAR as CFString) || (url.pathExtension.isEmpty && (url.lastPathComponent.uppercased() == "POSCAR" || url.lastPathComponent.uppercased() == "CONTCAR")):
          self.init(displayName: displayName, poscar: data)
        case _ where (url.pathExtension.isEmpty && (url.lastPathComponent.uppercased() == "XDATCAR")):
          self.init(displayName: displayName, xdatcar: data)
        case _ where UTTypeConformsTo(type as CFString, typeCIF as CFString):
          self.init(displayName: displayName, cif: data)
        case _ where UTTypeConformsTo(type as CFString, typePDB as CFString):
          self.init(displayName: displayName, pdb: data)
        case _ where UTTypeConformsTo(type as CFString, typeXYZ as CFString):
          self.init(displayName: displayName, xyz: data)
        default:
          return nil
        }
     }
    default:
      return nil
    }
  }
  
  // MARK: -
  // MARK: NSPasteboardWriting support
  
  public func writingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.WritingOptions
  {
    return NSPasteboard.WritingOptions.promised
  }
  
  public func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
  {
    switch(pasteboard.name)
    {
    case NSPasteboard.Name.drag:
      return [NSPasteboardTypeFrame,
              NSPasteboardTypeMovie,
              NSPasteboardTypeProjectTreeNode,
              NSPasteboard.PasteboardType(rawValue: kPasteboardTypeFilePromiseContent),
              NSPasteboard.PasteboardType(rawValue: kPasteboardTypeFileURLPromise)]
    case NSPasteboard.Name.general:
      return [NSPasteboardTypeFrame,
              NSPasteboardTypeMovie,
              NSPasteboardTypeProjectTreeNode,
              NSPasteboard.PasteboardType.fileURL]
    default:
      return [NSPasteboardTypeFrame]
    }
  }
  
 
  
  public func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any?
  {
    switch(type)
    {
    case NSPasteboardTypeFrame:
      let binaryEncoder: BinaryEncoder = BinaryEncoder()
      binaryEncoder.encode(self)
      return Data(binaryEncoder.data)
    case NSPasteboardTypeMovie:
      let displayName: String = structure.displayName
      let movie: Movie = Movie(name: displayName, structure: self)
      let binaryEncoder: BinaryEncoder = BinaryEncoder()
      binaryEncoder.encode(movie)
      return Data(binaryEncoder.data)
    case NSPasteboardTypeProjectTreeNode:
      let displayName: String = structure.displayName
      let movie: Movie = Movie(name: displayName, structure: self)
      let scene: Scene = Scene(name: displayName, movies: [movie])
      let sceneList: SceneList = SceneList(name: displayName, scenes: [scene])
      let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
      let projectTreeNode: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
      let binaryEncoder: BinaryEncoder = BinaryEncoder()
      binaryEncoder.encode(projectTreeNode, encodeRepresentedObject: true, encodeChildren: false)
      return Data(binaryEncoder.data)
    case NSPasteboard.PasteboardType.fileURL:
      // used for (1) writing to NSSharingService (email-attachment)
      //          (2) used to 'paste' into the Finder
      let displayName: String = structure.displayName
      let pathExtension: String = URL(fileURLWithPath: NSPasteboardTypeProjectTreeNode.rawValue).pathExtension
      let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(displayName).appendingPathExtension(pathExtension)
      let movie: Movie = Movie(name: displayName, structure: self)
      let scene: Scene = Scene(name: displayName, movies: [movie])
      let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
      let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
      let projectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
      let binaryEncoder: BinaryEncoder = BinaryEncoder()
      binaryEncoder.encode(projectTreeNode, encodeRepresentedObject: true, encodeChildren: false)
      guard let data = Data(binaryEncoder.data).compress(withAlgorithm: .lzma) else
      {
        LogQueue.shared.error(destination: nil, message: "Could not compress data during encoding of \(displayName)")
        return nil
      }
      do
      {
        try data.write(to: url, options: .atomicWrite)
      }
      catch
      {
        LogQueue.shared.error(destination: nil, message: "Could not write temporary file during encoding of \(displayName)")
        return nil
      }
      return (url as NSPasteboardWriting).pasteboardPropertyList(forType: type)
    case NSPasteboard.PasteboardType(rawValue: kPasteboardTypeFilePromiseContent):
      // used for dragging to the Finder
      // write the ProjectTreeNodePasteboardType UTI that will be asked next by calling
      // outlineView(_:namesOfPromisedFilesDroppedAtDestination:forDraggedItems:)
      return NSPasteboardTypeProjectTreeNode.rawValue
    case NSPasteboard.PasteboardType(rawValue: kPasteboardTypeFileURLPromise):
      // used for dragging to the Finder if 'kPasteboardTypeFilePromiseContent' is not available
      let pasteboard: NSPasteboard = NSPasteboard(name: NSPasteboard.Name.drag)
      if let string: String = pasteboard.string(forType: NSPasteboard.PasteboardType(rawValue: "com.apple.pastelocation")),
        let directoryURL: URL = URL(string: string)
      {
        let displayName: String = structure.displayName
        let pathExtension: String = URL(fileURLWithPath: NSPasteboardTypeProjectTreeNode.rawValue).pathExtension
        let finalURL:URL = directoryURL.appendingPathComponent(displayName).appendingPathExtension(pathExtension)
        
        let movie: Movie = Movie(name: displayName, structure: self)
        let scene: Scene = Scene(name: displayName, movies: [movie])
        let sceneList: SceneList = SceneList(name: displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
        let projectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
        let binaryEncoder: BinaryEncoder = BinaryEncoder()
        binaryEncoder.encode(projectTreeNode, encodeRepresentedObject: true, encodeChildren: false)
        guard let data = Data(binaryEncoder.data).compress(withAlgorithm: .lzma) else
        {
          LogQueue.shared.error(destination: nil, message: "Could not compress data during encoding of \(displayName)")
          return nil
        }
        do
        {
          try data.write(to: finalURL, options: .atomicWrite)
        }
        catch
        {
          LogQueue.shared.error(destination: nil, message: "Could not write temporary file during encoding of \(displayName)")
          return nil
        }
        return finalURL.absoluteString
      }
      return nil
    default:
      return nil
    }
  }
}
