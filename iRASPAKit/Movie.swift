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
import SymmetryKit
import RenderKit
import MathKit
import LogViewKit
import simd

// A Movie is a list of structure-data, each element is a snapshot/frame

public let NSPasteboardTypeMovie: NSPasteboard.PasteboardType = NSPasteboard.PasteboardType("nl.iRASPA.Movie")

public final class Movie: NSObject, NSPasteboardWriting, NSPasteboardReading, AtomVisualAppearanceViewer, BondVisualAppearanceViewer, UnitCellVisualAppearanceViewer, CellViewer, InfoViewer, AdsorptionSurfaceVisualAppearanceViewer, BinaryDecodable, BinaryEncodable
{
  private static var classVersionNumber: Int = 1
  public var displayName : String = ""
  
  public var isLoading: Bool = false
  public weak var importOperation: Foundation.Operation? = nil
  
  /// Returns all the frames in the movie
  public var frames: [iRASPAStructure]
  
  public var filteredAndSortedObjects: [iRASPAStructure] = [iRASPAStructure]()
  
  public var selectedFrame: iRASPAStructure? = nil
  public var selectedFrames: Set< iRASPAStructure > = Set()
  
  public var filterPredicate: (iRASPAStructure) -> Bool = {_ in return true}
  var sortDescriptors: [NSSortDescriptor] = []
  
  public var renderCanDrawAdsorptionSurface: Bool
  {
    return self.frames.reduce(into: false, {$0 = ($0 || $1.renderCanDrawAdsorptionSurface)})
  }
  
  public convenience init(displayName: String)
  {
    self.init()
    self.displayName = displayName
  }
  
  public convenience init(name: String, structure: iRASPAStructure)
  {
    self.init()
    self.displayName = name
    self.frames.append(structure)
    self.selectedFrame = nil
  }
  
  public convenience init(frame: iRASPAStructure)
  {
    self.init()
    self.displayName = frame.structure.displayName
    self.frames.append(frame)
    self.selectedFrame = self.frames.first
  }
  
  public convenience init(displayName: String, frames: [iRASPAStructure])
  {
    self.init()
    self.displayName = displayName
    self.selectedFrame = frames.first
    for frame in frames
    {
      self.frames.append(frame)
    }
  }
  
  public init(movie: Movie)
  {
    self.displayName = movie.displayName
    self.frames = movie.frames
  }
  
  
  public override var description: String
  {
    return "Movie (\(super.description)), arranged structure-objects: \(self.frames)"
  }
  
  public var isVisible: Bool
  {
    get
    {
      // Create a key for elements and their frequency
      var times: [Bool: Int] = [true:0, false:0]
      let boolArray: [Bool] = self.frames.map{ return $0.structure.isVisible }
      for bool in boolArray
      {
        // Every time there is a repeat value add one to that key
        times[bool] = (times[bool] ?? 0) + 1
      }
      
      // This is for sorting the values
      return times[true]! >= times[false]! ? true : false
    }
    set(newValue)
    {
      self.frames.forEach{$0.structure.isVisible = newValue}
    }
  }
  
  
  public override init()
  {
    frames = []
  }
  
  
  // MARK: -
  // MARK: NSPasteboardWriting support
  
  // 1) an object added to the pasteboard will first be sent an 'writableTypesForPasteboard' message
  // 2) the object will then receive an 'pasteboardPropertyListForType' for each of these types
  
  
  public func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
  {
    switch(pasteboard.name)
    {
    case NSPasteboard.Name.dragPboard:
      return [NSPasteboardTypeMovie,
              NSPasteboardTypeProjectTreeNode,
              NSPasteboardTypeFrame,
              NSPasteboard.PasteboardType(String(kPasteboardTypeFilePromiseContent)),
              NSPasteboard.PasteboardType(String(kPasteboardTypeFileURLPromise))]
    case NSPasteboard.Name.generalPboard:
      return [NSPasteboardTypeMovie,
              NSPasteboardTypeProjectTreeNode,
              NSPasteboardTypeFrame,
              NSPasteboard.PasteboardType(String(kUTTypeFileURL))]
    default:
      return [NSPasteboardTypeMovie]
    }
  }
  
  public func writingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.WritingOptions
  {
    return NSPasteboard.WritingOptions.promised
  }
  
  public func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any?
  {
    switch(type)
    {
    case NSPasteboardTypeFrame:
      guard let frame: iRASPAStructure = frames.first else {return nil}
      let binaryEncoder: BinaryEncoder = BinaryEncoder()
      binaryEncoder.encode(frame)
      return Data(binaryEncoder.data)
    case NSPasteboardTypeMovie:
      let binaryEncoder: BinaryEncoder = BinaryEncoder()
      binaryEncoder.encode(self)
      return Data(binaryEncoder.data)
    case NSPasteboardTypeProjectTreeNode:
      let scene: Scene = Scene(name: self.displayName, movies: [self])
      let sceneList: SceneList = SceneList.init(name: self.displayName, scenes: [scene])
      let project: ProjectStructureNode = ProjectStructureNode(name: self.displayName, sceneList: sceneList)
      let projectTreeNode = ProjectTreeNode(displayName: self.displayName, representedObject: iRASPAProject(structureProject: project))
      let binaryEncoder: BinaryEncoder = BinaryEncoder()
      binaryEncoder.encode(projectTreeNode, encodeRepresentedObject: true, encodeChildren: false)
      return Data(binaryEncoder.data)
    case NSPasteboard.PasteboardType(String(kPasteboardTypeFileURLPromise)):
      // used for dragging to the Finder if 'kPasteboardTypeFilePromiseContent' is not available
      let pasteboard: NSPasteboard = NSPasteboard(name: NSPasteboard.Name.dragPboard)
      if let string: String = pasteboard.string(forType: NSPasteboard.PasteboardType(rawValue: "com.apple.pastelocation")),
        let directoryURL: URL = URL(string: string)
      {
        let pathExtension: String = URL(fileURLWithPath: NSPasteboardTypeProjectTreeNode.rawValue).pathExtension
        let finalURL:URL = directoryURL.appendingPathComponent(self.displayName).appendingPathExtension(pathExtension)
        
        let scene: Scene = Scene(name: self.displayName, movies: [self])
        let sceneList: SceneList = SceneList.init(name: self.displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: self.displayName, sceneList: sceneList)
        let projectTreeNode = ProjectTreeNode(displayName: self.displayName, representedObject: iRASPAProject(structureProject: project))
        let binaryEncoder: BinaryEncoder = BinaryEncoder()
        binaryEncoder.encode(projectTreeNode, encodeRepresentedObject: true, encodeChildren: false)
        guard let data = Data(binaryEncoder.data).compress(withAlgorithm: .lzma) else
        {
          LogQueue.shared.error(destination: nil, message: "Could not compress data during encoding of \(self.displayName)")
          return nil
        }
        do
        {
          try data.write(to: finalURL, options: .atomicWrite)
        }
        catch
        {
          LogQueue.shared.error(destination: nil, message: "Could not write temporary file during encoding of \(self.displayName)")
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
      let pathExtension: String = URL(fileURLWithPath: NSPasteboardTypeProjectTreeNode.rawValue).pathExtension
      let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(self.displayName).appendingPathExtension(pathExtension)
      let scene: Scene = Scene(name: self.displayName, movies: [self])
      let sceneList: SceneList = SceneList.init(name: self.displayName, scenes: [scene])
      let project: ProjectStructureNode = ProjectStructureNode(name: self.displayName, sceneList: sceneList)
      let projectTreeNode = ProjectTreeNode(displayName: self.displayName, representedObject: iRASPAProject(structureProject: project))
      let binaryEncoder: BinaryEncoder = BinaryEncoder()
      binaryEncoder.encode(projectTreeNode, encodeRepresentedObject: true, encodeChildren: false)
      guard let data = Data(binaryEncoder.data).compress(withAlgorithm: .lzma) else
      {
        LogQueue.shared.error(destination: nil, message: "Could not compress data during encoding of \(self.displayName)")
        return nil
      }
      do
      {
        try data.write(to: url, options: .atomicWrite)
      }
      catch
      {
        LogQueue.shared.error(destination: nil, message: "Could not write temporary file during encoding of \(self.displayName)")
        return nil
      }
      return (url as NSPasteboardWriting).pasteboardPropertyList(forType: type)
      
    default:
      fatalError()
    }
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
    return [NSPasteboardTypeMovie,
            NSPasteboardTypeProjectTreeNode,
            NSPasteboardTypeFrame,
            NSPasteboard.PasteboardType(String(kUTTypeFileURL))] // NSPasteboard.PasteboardType.fileURL
  }
  
  public convenience required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType)
  {
    guard let data: Data = propertyList as? Data else {return nil}
    
    switch(type)
    {
    case NSPasteboardTypeFrame:
      debugPrint("NSPasteboardTypeFrame")
      
      let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
      guard let frame: iRASPAStructure = try? binaryDecoder.decode(iRASPAStructure.self) else {return nil}
      let movie: Movie = Movie.init(name: frame.structure.displayName, structure: frame)
      self.init(movie: movie)
      return
    case NSPasteboardTypeMovie:
      let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
      guard let movie: Movie = try? binaryDecoder.decode(Movie.self) else {return nil}
      self.init(movie: movie)
      return
    case NSPasteboardTypeProjectTreeNode:
      let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
      guard let projectTreeNode: ProjectTreeNode = try? binaryDecoder.decode(ProjectTreeNode.self, decodeRepresentedObject: true, decodeChildren: false) else {return nil}
      guard let project: ProjectStructureNode = projectTreeNode.representedObject.project as? ProjectStructureNode else {return nil}
      guard let movie: Movie = project.sceneList.scenes.first?.movies.first else {return nil}
      self.init(movie: movie)
      return
    case NSPasteboard.PasteboardType(String(kUTTypeFileURL)):
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
            guard let movie = project.sceneList.scenes.first?.movies.first else {return nil}
            self.init(movie: movie)
            return
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typePOSCAR)) || (url.pathExtension.isEmpty && (url.lastPathComponent.uppercased() == "POSCAR" || url.lastPathComponent.uppercased() == "CONTCAR")):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let poscarParser: SKPOSCARParser = SKPOSCARParser(displayName: displayName, string: dataString, windowController: nil)
            try? poscarParser.startParsing()
            let scene: Scene = Scene(parser: poscarParser.scene)
            guard let movie = scene.movies.first else {return nil}
            self.init(movie: movie)
            return
          case _ where (url.pathExtension.isEmpty && (url.lastPathComponent.uppercased() == "XDATCAR")):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let poscarParser: SKXDATCARParser = SKXDATCARParser(displayName: displayName, string: dataString, windowController: nil)
            try? poscarParser.startParsing()
            let scene: Scene = Scene(parser: poscarParser.scene)
            guard let movie = scene.movies.first else {return nil}
            self.init(movie: movie)
            return
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typeCIF)):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let cifParser: SKCIFParser = SKCIFParser(displayName: displayName, string: dataString, windowController: nil)
            try? cifParser.startParsing()
            let scene: Scene = Scene(parser: cifParser.scene)
            guard let movie = scene.movies.first else {return nil}
            self.init(movie: movie)
            return
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typePDB)):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let pdbParser: SKPDBParser = SKPDBParser(displayName: displayName, string: dataString, windowController: nil, onlyAsymmetricUnit: true, asMolecule: false)
            try? pdbParser.startParsing()
            let scene: Scene = Scene(parser: pdbParser.scene)
            guard let movie = scene.movies.first else {return nil}
            self.init(movie: movie)
            return
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typeXYZ)):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let xyzParser: SKXYZParser = SKXYZParser(displayName: displayName, string: dataString, windowController: nil)
            try? xyzParser.startParsing()
            let scene: Scene = Scene(parser: xyzParser.scene)
            guard let movie = scene.movies.first else {return nil}
            self.init(movie: movie)
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
  
  public static func ==(lhs: Movie, rhs: Movie) -> Bool
  {
    return lhs === rhs
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(Movie.classVersionNumber)
    encoder.encode(self.displayName)
    encoder.encode(self.frames)
  }

  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > Movie.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.displayName = try decoder.decode(String.self)
    self.frames = try decoder.decode([iRASPAStructure].self)
  }
}



extension Movie: StructureViewer
{
  public var allStructures: [Structure]
  {
    return self.frames.flatMap{$0.allStructures}
  }
  
  public var allIRASPAStructures: [iRASPAStructure]
  {
    return self.frames.compactMap{$0}
  }
  
  public var selectedRenderFrames: [RKRenderStructure]
  {
    return self.selectedFrames.map{$0.renderStructure}
  }
  
  public var allRenderFrames: [RKRenderStructure]
  {
    return self.frames.map{$0.renderStructure}
  }
  
}



extension Movie: PrimitiveVisualAppearanceViewer
{
  public var allPrimitiveStructure: [Structure]
  {
    return self.frames.flatMap{$0.allPrimitiveStructure}
  }
}


