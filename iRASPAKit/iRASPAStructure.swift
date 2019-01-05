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
import RenderKit
import SimulationKit
import SymmetryKit
import LogViewKit

public let NSPasteboardTypeFrame: NSPasteboard.PasteboardType = NSPasteboard.PasteboardType("nl.iRASPA.Frame")

public final class iRASPAStructure: NSObject, Decodable, BinaryDecodable, BinaryEncodable, NSPasteboardReading, NSPasteboardWriting
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
  
  public init(frame: iRASPAStructure)
  {
    self.type = frame.type
    self.structure = frame.structure
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let type: SKStructure.Kind = SKStructure.Kind(rawValue: try decoder.decode(Int64.self))!
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
    default:
      fatalError()
    }
  }
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(type.rawValue)
    encoder.encode(structure)
  }
  
  // MARK: -
  // MARK: Legacy Decodable support
  
  public init(from decoder: Decoder) throws
  {
    var container = try decoder.unkeyedContainer()
    let type: SKStructure.Kind = SKStructure.Kind(rawValue: try container.decode(Int64.self))!
    
    self.type = type
    switch(type)
    {
    case .structure:
      self.structure = try container.decode(Structure.self)
    case .crystal:
      self.structure = try container.decode(Crystal.self)
    case .molecularCrystal:
      self.structure = try container.decode(MolecularCrystal.self)
    case .molecule:
      self.structure = try container.decode(Molecule.self)
    case .protein:
      self.structure = try container.decode(Protein.self)
    case .proteinCrystal:
      self.structure = try container.decode(ProteinCrystal.self)
    default:
      fatalError()
    }
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
            NSPasteboard.PasteboardType(String(kUTTypeFileURL))] // NSPasteboard.PasteboardType.fileURL
  }
  
  public convenience init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType)
  {
    guard let data: Data = propertyList as? Data else {return nil}
    
    switch(type)
    {
    case NSPasteboardTypeFrame:
      let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
      guard let frame: iRASPAStructure = try? binaryDecoder.decode(iRASPAStructure.self) else {return nil}
      self.init(frame: frame)
      return
    case NSPasteboardTypeMovie:
      let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
      guard let movie: Movie = try? binaryDecoder.decode(Movie.self) else {return nil}
      guard let firstFrame: iRASPAStructure = movie.frames.first else {return nil}
      self.init(frame: firstFrame)
      return
    case NSPasteboardTypeProjectTreeNode:
      let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
      guard let node: ProjectTreeNode = try? binaryDecoder.decode(ProjectTreeNode.self, decodeRepresentedObject: true, decodeChildren: false) else {return nil}
      guard let project: ProjectStructureNode = node.representedObject.project as? ProjectStructureNode else {return nil}
      guard let firstFrame: iRASPAStructure = project.sceneList.scenes.first?.movies.first?.frames.first else {return nil}
      self.init(frame: firstFrame)
      return
    case NSPasteboard.PasteboardType(String(kUTTypeFileURL)):
      debugPrint("READING NSPasteboard.PasteboardType(String(kUTTypeFileURL))")
      if let str = String(data: data, encoding: .utf8),
         let url = URL(string: str),
         FileManager.default.fileExists(atPath: url.path),
         let data: Data = try? Data(contentsOf: url, options: [])
      {
        let displayName: String = url.deletingPathExtension().lastPathComponent
        if let type = try? NSWorkspace.shared.type(ofFile: url.path)
        {
          switch(type)
          {
          case _ where NSWorkspace.shared.type(type, conformsToType: iRASPAProjectUTI):
            guard let data = data.decompress(withAlgorithm: .lzma) else {return nil}
            let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
            guard let node: ProjectTreeNode = try? binaryDecoder.decode(ProjectTreeNode.self, decodeRepresentedObject: true, decodeChildren: false) else {return nil}
            node.unwrapLazyLocalPresentedObjectIfNeeded()
            guard let project = node.representedObject.project as? ProjectStructureNode else {return nil}
            guard let frame = project.sceneList.scenes.first?.movies.first?.frames.first else {return nil}
            self.init(frame: frame)
            return
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typePOSCAR)) || (url.pathExtension.isEmpty && (url.lastPathComponent.uppercased() == "POSCAR" || url.lastPathComponent.uppercased() == "CONTCAR")):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let poscarParser: SKVASPParser = SKVASPParser(displayName: displayName, string: dataString, windowController: nil)
            try? poscarParser.startParsing()
            let scene: Scene = Scene(parser: poscarParser.scene)
            guard let frame = scene.movies.first?.frames.first else {return nil}
            self.init(frame: frame)
            return
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typeCIF)):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let cifParser: SKCIFParser = SKCIFParser(displayName: displayName, string: dataString, windowController: nil)
            try? cifParser.startParsing()
            let scene: Scene = Scene(parser: cifParser.scene)
            guard let frame = scene.movies.first?.frames.first else {return nil}
            self.init(frame: frame)
            return
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typePDB)):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let pdbParser: SKPDBParser = SKPDBParser(displayName: displayName, string: dataString, windowController: nil, onlyAsymmetricUnit: true)
            try? pdbParser.startParsing()
            let scene: Scene = Scene(parser: pdbParser.scene)
            guard let frame = scene.movies.first?.frames.first else {return nil}
            self.init(frame: frame)
            return
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typeXYZ)):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let xyzParser: SKXYZParser = SKXYZParser(displayName: displayName, string: dataString, windowController: nil)
            try? xyzParser.startParsing()
            let scene: Scene = Scene(parser: xyzParser.scene)
            guard let frame = scene.movies.first?.frames.first else {return nil}
            self.init(frame: frame)
            return
          default:
            return nil
          }
        }
      }
      return nil
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
    case NSPasteboard.Name.dragPboard:
      return [NSPasteboardTypeFrame,
              NSPasteboardTypeMovie,
              NSPasteboardTypeProjectTreeNode,
              NSPasteboard.PasteboardType(String(kPasteboardTypeFilePromiseContent)),
              NSPasteboard.PasteboardType(String(kPasteboardTypeFileURLPromise))]
    case NSPasteboard.Name.generalPboard:
      return [NSPasteboardTypeFrame,
              NSPasteboardTypeMovie,
              NSPasteboardTypeProjectTreeNode,
              NSPasteboard.PasteboardType(String(kUTTypeFileURL))]
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
    case NSPasteboard.PasteboardType(String(kPasteboardTypeFileURLPromise)):
      // used for dragging to the Finder if 'kPasteboardTypeFilePromiseContent' is not available
      let pasteboard: NSPasteboard = NSPasteboard(name: NSPasteboard.Name.dragPboard)
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
      
    case NSPasteboard.PasteboardType(String(kPasteboardTypeFilePromiseContent)):
      // used for dragging to the Finder
      // write the ProjectTreeNodePasteboardType UTI that will be asked next by calling
      // outlineView(_:namesOfPromisedFilesDroppedAtDestination:forDraggedItems:)
      return NSPasteboardTypeProjectTreeNode.rawValue
      
    case NSPasteboard.PasteboardType(String(kUTTypeFileURL)):
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
      
    default:
      return nil
    }
  }
}
