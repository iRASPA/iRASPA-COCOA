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
import CloudKit
import OperationKit
import SimulationKit
import Compression
import RenderKit
import SymmetryKit
import LogViewKit



let iRASPAProjectUTI: String = "nl.darkwing.iraspa.iraspa"
let typeCIF: CFString = (UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "cif" as CFString, kUTTypeData)?.takeRetainedValue())!
let typePDB: CFString = (UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "pdb" as CFString, kUTTypeData)?.takeRetainedValue())!
let typeXYZ: CFString = (UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "xyz" as CFString, kUTTypeData)?.takeRetainedValue())!
let typePOSCAR: CFString = (UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "poscar" as CFString, kUTTypeData)?.takeRetainedValue())!
let typeProject: CFString = (UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "iraspa" as CFString, kUTTypeData)?.takeRetainedValue())!

public let NSPasteboardTypeProjectTreeNode: NSPasteboard.PasteboardType = NSPasteboard.PasteboardType(rawValue: "nl.darkwing.iraspa.iraspa")
public let NSPasteboardTypeProjectTreeNodeCopy: NSPasteboard.PasteboardType = NSPasteboard.PasteboardType(rawValue: "nl.darkwing.iraspa.project.copy")

public final class ProjectTreeNode:  NSObject, NSPasteboardReading, NSPasteboardWriting, BinaryDecodable, BinaryEncodable, BinaryEncodableRecursive, BinaryDecodableRecursive
{
  private static var classVersionNumber: Int = 1
  
  @objc dynamic public var displayName: String = "Empty"
  
  public var owner: String = "" // used at runtime
  
  //public var data: Data? = nil
  
  public weak var importOperation: Foundation.Operation? = nil
  
  public weak var projectFileWrapper: FileWrapper? = nil
  
  /// The parent of a ProjectTreeNode
  ///
  /// The parent of a node should always exists except for the single root-node which should be hidden and inaccesible from a tree-controller.
  /// The (hidden) root-node and just created nodes are the only nodes with a non-existing parent
  public weak var parentNode: ProjectTreeNode? = nil
  
  /// The children of a ProjectTreeNode
  ///
  /// An array of tree-nodes. A "leaf"-node has no children (an empty childrens-array).
  public var childNodes: [ProjectTreeNode] = [ProjectTreeNode]()
  
  public var filteredAndSortedNodes: [ProjectTreeNode] = [ProjectTreeNode]()
  
  // must be true to allow insert/deletions in the table with animations
  public var matchesFilter: Bool = true
  
  public var selected: Bool = false // used at run-time for AtomTableRowView-implicit selection
  
  public var isDropEnabled: Bool = false;
  public var isEditable: Bool = true
  public var isVisuallyCustomizable: Bool = true
  public var lockedChildren: Bool = false
  
  public var isTemporarilyLocked: Bool = false
  
  public var isEnabled: Bool
  {
    return isEditable && (!isTemporarilyLocked)
  }
  
  public var isExpanded: Bool = false
  public var disallowDrag: Bool = false
  
  /// The object the tree node represents.
  ///
  public var representedObject: iRASPAProject

  
  public var recordID: CKRecord.ID? = nil
  
  public var snapshotData: Data? = nil
  
  public convenience init(representedObject modelObject: iRASPAProject)
  {
    self.init(displayName: "new project", representedObject: modelObject)
  }
  
  public init(displayName: String, representedObject: iRASPAProject)
  {
    self.displayName = displayName
    self.representedObject = representedObject
    super.init()
  }
  
  public init(record: CKRecord)
  {
    if let name = record["displayName"] as? String
    {
      self.displayName = name
    }
    if let data = record["representedObjectInfo"] as? Data
    {
      do
      {
        self.representedObjectInfo = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: AnyObject] ?? [:]
      }
      catch let error
      {
        debugPrint("error: \(error)")
      }
    }
    self.recordID = record.recordID
    
    self.representedObject = iRASPAProject.init(projectType: .structure, fileName: record.recordID.recordName, nodeType: .leaf, storageType: .publicCloud, lazyStatus: .lazy)
      
      
      //.projectProjectLazy(iRASPAProject.ProjectStatus(fileWrapper: nil, fileName: record.recordID.recordName, nodeType: .leaf, storageType: .publicCloud, lazyStatus: .lazy, projectType: 3))
    super.init()
  }
  
  public init(displayName: String, recordID: CKRecord.ID)
  {
    self.displayName = displayName
    self.recordID = recordID
    self.representedObject = iRASPAProject.init(projectType: .structure, fileName: recordID.recordName, nodeType: .leaf, storageType: .publicCloud, lazyStatus: .lazy)
      
      //.projectProjectLazy(iRASPAProject.ProjectStatus(fileWrapper: nil, fileName: recordID.recordName, nodeType: .leaf, storageType: .publicCloud, lazyStatus: .lazy, projectType: iRASPAProject.structure))
    super.init()
  }
  
  public init(groupName: String, recordID: CKRecord.ID)
  {
    self.displayName = groupName
    self.recordID = recordID
    self.representedObject = iRASPAProject(group: ProjectGroup(displayName: groupName, recordID: recordID))
    super.init()
  }
  
  public init(displayName: String, recordID: CKRecord.ID, representedObject: iRASPAProject)
  {
    self.displayName = displayName
    self.representedObject = representedObject
    self.recordID = recordID
    super.init()
  }
  
  public required convenience init(treeNode: ProjectTreeNode)
  {
    self.init(displayName: treeNode.displayName, representedObject: treeNode.representedObject)
    
    self.childNodes = treeNode.childNodes
    
    // let the children now point to 'self' as the parent
    for child in childNodes
    {
      child.parentNode = self
    }
  }
  
  // MARK: -
  // MARK: Encodable support
  
  public var representedObjectInfo: [ String : AnyObject] = [
    "vsa": NSNumber(value: 0.0),
    "gsa": NSNumber(value: 0.0),
    "voidfraction" : NSNumber(value: 0.0),
    "di" : NSNumber(value: 0.0),
    "df" : NSNumber(value: 0.0),
    "dif" : NSNumber(value: 0.0),
    "density" : NSNumber(value: 0.0),
    "mass" : NSNumber(value: 0.0),
    "specific_v" : NSNumber(value: 0.0),
    "accesible_v" : NSNumber(value: 0.0),
    "n_channels" : NSNumber(value: 0.0),
    "n_pockets" : NSNumber(value: 0.0),
    "dim" : NSNumber(value: 0.0),
    "type" : NSString(string: "Unspecified")
  ]
  
  public enum EncodingStrategy: Int
  {
    case saveRepresentedObject = 0                   // save normally (used to save individual projects to local files, leaving copied cloud-nodes as 'lazy')
    case unwrapLocalRepresentedObject = 1            // drag to finder
    case unwrapLocalRepresentedObjectAndChildren = 2 // drag to finder, all childNodes need to be unwrapped
    case saveDocument = 3                            // save the projects as 'lazy'-projects (used for saving the whole project-tree)
    case saveSnapshot = 4                            // use the snapshot (type: Data), used for copy/paste
    case saveLeafNodeToCloud = 5                     // save the project into the cloud and turn into a 'lazy'-cloud project
    case placeholder = 6
  }
  
  // MARK: -
  // MARK: NSPasteboardWriting support
  
  // 1) an object added to the pasteboard will first be sent an 'writableTypesForPasteboard' message
  // 2) the object will then receive an 'pasteboardPropertyListForType' for each of these types
  
  // kPasteboardTypeFilePromiseContent: used for dragging to the Finder
  // kUTTypeFileURL: used for paste into the Finder
  
  // NSFilesPromisePboardType expects filename extensions;
  // kPasteboardTypeFileURLPromise expects file URLs; replaces NSFilesPromisePboardType
  // kPasteboardTypeFilePromiseContent (only mentioned in Pasteboard.h, AFAIK) expects UTIs.
 
  // drag & drop: Promise the data on the pasteboard, so all types of data can be promised.
  // copy & paste: Write data immediately, so choose which data to put on the pasteboard. The Finder copy 'kUTTypeFileURL' can always be added (URLs is a small amount of data).
  public func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
  {
    switch(pasteboard.name)
    {
    case NSPasteboard.Name.dragPboard:
      return [NSPasteboardTypeProjectTreeNode,
              NSPasteboardTypeFrame,
              NSPasteboardTypeMovie,
              NSPasteboard.PasteboardType(String(kPasteboardTypeFilePromiseContent)),
              NSPasteboard.PasteboardType(String(kPasteboardTypeFileURLPromise))]
    case NSPasteboard.Name.generalPboard:
      return [NSPasteboardTypeProjectTreeNodeCopy, NSPasteboard.PasteboardType(String(kUTTypeFileURL))]
    default:
      return [NSPasteboardTypeProjectTreeNode]
    }
  }
  
  
  // copy & paste: data has been backed up at copy to 'snapshotData' and written to the pasteboard immediately.
  // drag & drop: promise the data on the pasteboard
  // Finder requires that the file actually be present on disk for the paste action to be enabled for a file URL. 
  public func writingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.WritingOptions
  {
    switch(pasteboard.name)
    {
    case NSPasteboard.Name.dragPboard:
      return NSPasteboard.WritingOptions.promised
    case NSPasteboard.Name.generalPboard:
      return NSPasteboard.WritingOptions()
    default:
      return NSPasteboard.WritingOptions.promised
    }
  }
  
  // the projectTreeNode member 'snapshotData' is used for two reasons:
  //   1) We can generate the data here for either shallow or deep-copies,
  //   2) We can handle NSPasteboardTypeProjectTreeNodeCopy and kUTTypeFileURL in one go.
  //   Both are used in 'immediate' mode of the pasteboard, since kUTTypeFileURL needs that anyway,
  //   i.e. the file needs to be saved and the url returned in 'pasteboardPropertyList' of the NSPasteboardWriting
  
  public func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any?
  {
    switch(type)
    {
    case NSPasteboardTypeProjectTreeNodeCopy:
      // Copy projects command-c
      return self.snapshotData
    case NSPasteboard.PasteboardType(String(kUTTypeFileURL)):
      // Copy projects command-c
      // Used for (1) writing to NSSharingService (email-attachment)
      //          (2) used to 'paste' into the Finder
      let pathExtension: String = URL(fileURLWithPath: NSPasteboardTypeProjectTreeNode.rawValue).pathExtension
      let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(self.displayName).appendingPathExtension(pathExtension)
      
      guard let data = self.snapshotData?.compress(withAlgorithm: .lzma) else
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
    case NSPasteboardTypeProjectTreeNode:
      // Used for drag&drop between documents
      let binaryEncoder: BinaryEncoder = BinaryEncoder()
      binaryEncoder.encode(self, encodeRepresentedObject: true, encodeChildren: true)
      return Data(binaryEncoder.data)
    case NSPasteboardTypeFrame:
      unwrapLazyLocalPresentedObjectIfNeeded()
      guard let project: ProjectStructureNode = representedObject.project as? ProjectStructureNode else {return nil}
      guard let movie: Movie = project.sceneList.scenes.first?.movies.first else {return nil}
      guard let frame: iRASPAStructure = movie.frames.first else {return nil}
      let binaryEncoder: BinaryEncoder = BinaryEncoder()
      binaryEncoder.encode(frame)
      return Data(binaryEncoder.data)
    case NSPasteboardTypeMovie:
      unwrapLazyLocalPresentedObjectIfNeeded()
      guard let project: ProjectStructureNode = representedObject.project as? ProjectStructureNode else {return nil}
      guard let movie: Movie = project.sceneList.scenes.first?.movies.first else {return nil}
      let binaryEncoder: BinaryEncoder = BinaryEncoder()
      binaryEncoder.encode(movie)
      return Data(binaryEncoder.data)
    case NSPasteboard.PasteboardType(String(kPasteboardTypeFileURLPromise)):
      // used for dragging to the Finder if 'kPasteboardTypeFilePromiseContent' is not available
      let pasteboard: NSPasteboard = NSPasteboard(name: NSPasteboard.Name.dragPboard)
      if let string: String = pasteboard.string(forType: NSPasteboard.PasteboardType(rawValue: "com.apple.pastelocation")),
        let directoryURL: URL = URL(string: string)
      {
        let pathExtension: String = URL(fileURLWithPath: NSPasteboardTypeProjectTreeNode.rawValue).pathExtension
        let finalURL:URL = directoryURL.appendingPathComponent(self.displayName).appendingPathExtension(pathExtension)
        
        let binaryEncoder: BinaryEncoder = BinaryEncoder()
        binaryEncoder.encode(self, encodeRepresentedObject: true, encodeChildren: false)
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
    default:
      return nil
    }
  }
  
  
  // MARK: -
  // MARK: NSPasteboardReading support
  
  // 1) the pasteboard will try to find a class that can read pasteboard data, sending it an 'readableTypesForPasteboard' message
  // 2) once such a class had been found, it will sent the class an 'init' message
  
  
  public class func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions
  {
    return [.asData]
  }
  
  
  public class func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType]
  {
    return [NSPasteboardTypeProjectTreeNode,
            NSPasteboardTypeProjectTreeNodeCopy,
            NSPasteboardTypeMovie,
            NSPasteboardTypeFrame,
            NSPasteboard.PasteboardType(String(kUTTypeFileURL))] // NSPasteboard.PasteboardType.fileURL
  }
  
  
  public convenience required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType)
  {
    if let data = propertyList as? Data
    {
    switch(type)
    {
    case NSPasteboardTypeProjectTreeNode:
      let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
      guard let node: ProjectTreeNode = try? binaryDecoder.decode(ProjectTreeNode.self, decodeRepresentedObject: true, decodeChildren: true) else {return nil}
      self.init(treeNode: node)
      self.isEditable = true
      return
    case NSPasteboardTypeProjectTreeNodeCopy:
      let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
      guard let node: ProjectTreeNode = try? binaryDecoder.decode(ProjectTreeNode.self, decodeRepresentedObject: true, decodeChildren: true) else {return nil}
      self.init(treeNode: node)
      self.isEditable = true
      return
    case NSPasteboardTypeMovie:
      let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
      guard let movie: Movie = try? binaryDecoder.decode(Movie.self) else {return nil}
      let scene: Scene = Scene.init(name: movie.displayName, movies: [movie])
      let sceneList: SceneList = SceneList(name: movie.displayName, scenes: [scene])
      let project: ProjectStructureNode = ProjectStructureNode(name: movie.displayName, sceneList: sceneList)
      let node: ProjectTreeNode = ProjectTreeNode(displayName: movie.displayName, representedObject: iRASPAProject(structureProject: project))
      self.init(treeNode: node)
      self.isEditable = true
      return
    case NSPasteboardTypeFrame:
      let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
      guard let iraspaStructure: iRASPAStructure = try? binaryDecoder.decode(iRASPAStructure.self) else {return nil}
      let displayName: String = iraspaStructure.structure.displayName
      let movie: Movie = Movie.init(name: displayName, structure: iraspaStructure)
      let scene: Scene = Scene.init(name: displayName, movies: [movie])
      let sceneList: SceneList = SceneList(name: displayName, scenes: [scene])
      let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
      let node: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
      self.init(treeNode: node)
      self.isEditable = true
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
            guard let node: ProjectTreeNode = try? binaryDecoder.decode(ProjectTreeNode.self, decodeRepresentedObject: true, decodeChildren: true) else {return nil}
            self.init(treeNode: node)
            self.isEditable = true
            return
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typePOSCAR)) || (url.pathExtension.isEmpty && (url.lastPathComponent.uppercased() == "POSCAR" || url.lastPathComponent.uppercased() == "CONTCAR")):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let poscarParser: SKPOSCARParser = SKPOSCARParser(displayName: displayName, string: dataString, windowController: nil)
            try? poscarParser.startParsing()
            let scene: Scene = Scene(parser: poscarParser.scene)
            let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
            let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
            self.init(treeNode: ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project)))
            self.isEditable = true
            return
          case _ where (url.pathExtension.isEmpty && (url.lastPathComponent.uppercased() == "XDATCAR")):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let poscarParser: SKXDATCARParser = SKXDATCARParser(displayName: displayName, string: dataString, windowController: nil)
            try? poscarParser.startParsing()
            let scene: Scene = Scene(parser: poscarParser.scene)
            let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
            let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
            self.init(treeNode: ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project)))
            self.isEditable = true
            return
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typeCIF)):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let cifParser: SKCIFParser = SKCIFParser(displayName: displayName, string: dataString, windowController: nil)
            try? cifParser.startParsing()
            let scene: Scene = Scene(parser: cifParser.scene)
            let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
            let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
            self.init(treeNode: ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project)))
            self.isEditable = true
            return
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typePDB)):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let pdbParser: SKPDBParser = SKPDBParser(displayName: displayName, string: dataString, windowController: nil, onlyAsymmetricUnit: true, asMolecule: false)
            try? pdbParser.startParsing()
            let scene: Scene = Scene(parser: pdbParser.scene)
            let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
            let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
            self.init(treeNode: ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project)))
            self.isEditable = true
            return
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typeXYZ)):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let xyzParser: SKXYZParser = SKXYZParser(displayName: displayName, string: dataString, windowController: nil)
            try? xyzParser.startParsing()
            let scene: Scene = Scene(parser: xyzParser.scene)
            let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
            let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
            self.init(treeNode: ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project)))
            self.isEditable = true
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
    return nil
  }
  
  // MARK: -
  // MARK: Copy support
  
  public var shallowCopy: ProjectTreeNode?
  {
    do
    {
      let binaryEncoder: BinaryEncoder = BinaryEncoder()
      binaryEncoder.encode(self, encodeRepresentedObject: true, encodeChildren: false)
      let data = Data(binaryEncoder.data)
      let copy: ProjectTreeNode = try BinaryDecoder(data: [UInt8](data)).decode(ProjectTreeNode.self, decodeRepresentedObject: true, decodeChildren: false)
      copy.isEditable = self.isEditable
      copy.lockedChildren = self.lockedChildren
      return copy
    }
    catch
    {
      return nil
    }
  }
  
  
  // Needed?
  public var deepCopy: ProjectTreeNode?
  {
    do
    {
      let binaryEncoder: BinaryEncoder = BinaryEncoder()
      binaryEncoder.encode(self, encodeRepresentedObject: true, encodeChildren: true)
      let data = Data(binaryEncoder.data)
      
      let copy: ProjectTreeNode = try BinaryDecoder(data: [UInt8](data)).decode(ProjectTreeNode.self, decodeRepresentedObject: true, decodeChildren: true)
      copy.isEditable = self.isEditable
      copy.lockedChildren = self.lockedChildren
      return copy
    }
    catch
    {
      debugPrint("Deepcopy error: \(error)")
      return nil
    }
  }
  
  public var path: String
  {
    if (parentNode == nil)
    {
      return "Projects"
    }
    else
    {
      if let parentPath = self.parentNode?.path
      {
        /* FIX 11-07-2017
        if let representedString = self.representedObject.description
        {
          return parentPath + "/" + representedString
        }
 */
        return parentPath
      }
      return ""
    }
  }
  
  
  /// Whether the node is a root-node or not
  ///
  /// - returns: true if the node is a root-node, otherwise false
  public func isRootNode() -> Bool
  {
    assert(self.parentNode != nil, "isRootNode: Should not ask information about the hidden root-node")
    
    if (self.parentNode?.parentNode == nil)
    {
      return true
    }
    else
    {
      return false
    }
  }
  
  /// Returns the position of the receiver relative to its root parent.
  ///
  /// Note: the Index path is empty for isolated tree nodes
  ///
  /// - returns: An index path that represents the receiver’s position relative to the tree’s root node.
  public var indexPath: IndexPath
  {
    get
    {
      if let parentNode = parentNode
      {
        let path: IndexPath = parentNode.indexPath
        let index: Int = parentNode.childNodes.firstIndex(of: self)!
        
        if (path.count > 0)
        {
          return path.appending(index)
        }
        else
        {
          return [index]
        }
      }
      else
      {
        return []
      }
    }
  }
  
  public var isLeaf: Bool
  {
    return !self.representedObject.isProjectGroup
  }
  
  /// Inserts the node into another (parent) node at a specified index
  ///
  /// - parameter inParent: The parent where the node will be inserted into.
  /// - parameter atIndex: The index of insertion
  public func insert(inParent parent: ProjectTreeNode, atIndex index: Int)
  {
    assert(index<=parent.childNodes.count, "ProjectTreeNode insert: \(index) not in range children \(parent.childNodes.count)")
    
    self.parentNode=parent
    parent.childNodes.insert(self, at: index)
    
  }
  
  /// Appends the node into another (parent) node
  ///
  /// - parameter inParent: The parent where the node will be inserted into.
  public func append(inParent parent: ProjectTreeNode)
  {
    self.parentNode = parent
    parent.childNodes.insert(self, at: parent.childNodes.count)
    
  }
  
  /// Removes the node from its parent
  // Note: this takes 5 seconds for MIL-101 for removing a large set
  public func removeFromParent()
  {
    if let parentNode = parentNode,
      let index: Int = parentNode.childNodes.firstIndex(of: self)
    {
      parentNode.childNodes.remove(at: index)
      self.parentNode = nil
    }
    else
    {
      fatalError("ProjectTreeNode removeFromParent: node not present in the children of the parent")
    }
  }
  
  
  
  /// Returns the receiver’s descendent at the specified index path.
  ///
  /// Note: an error occurs if the indexPath is not valid
  ///
  /// - parameter indexPath: An index path specifying a descendent of the receiver.
  /// - returns: The tree node at the specified index path.
  public func descendantNodeAtIndexPath(_ indexPath: IndexPath) -> ProjectTreeNode?
  {
    let length: Int = indexPath.count
    var node: ProjectTreeNode = self
    
    for i in 0..<length
    {
      let index: Int = indexPath[i]
      if(index>=node.childNodes.count)
      {
        return nil
      }
      
      node=node.childNodes[index]
    }
    
    return node
  }
  
  public func adjacentIndexPath() -> IndexPath
  {
    if (self.indexPath.isEmpty)
    {
      return [0]
    }
    else
    {
      return self.indexPath.dropLast() + [self.indexPath.last! + 1]
    }
  }
  
  
  public func sortWithSortDescriptors(_ sortDescriptors: [AnyObject], recursively: Bool)
  {
    
  }
  
  public func flattenedNodes() -> [ProjectTreeNode]
  {
    return [self] + self.descendantNodes()
  }
  
  public func flattenedLeafNodes() -> [ProjectTreeNode]
  {
    if self.isLeaf
    {
      return [self]
    }
    else
    {
      return self.descendantLeafNodes()
    }
  }
  
  public func flattenedGroupNodes() -> [ProjectTreeNode]
  {
    if self.isLeaf
    {
      return []
    }
    else
    {
      return [self] + self.descendantGroupNodes()
    }
  }
  
  // includes hiddenRootNode
  public func ancestors() -> [ProjectTreeNode]
  {
    var parents = [ProjectTreeNode]()
    
    if let parentNode = parentNode
    {
      parents.append(parentNode)
      parents += parentNode.ancestors()
    }
    
    return parents
  }
  
  
  /// Returns an array of AtomTreeNodes descending from self using recursion.
  public func descendants() -> [ProjectTreeNode]
  {
    var descendants=[ProjectTreeNode]()
    
    for  child in self.childNodes
    {
      if (child.isLeaf)
      {
        descendants.append(child)
      }
      else
      {
        descendants+=child.descendants()
      }
    }
    
    return descendants
  }
  
  public func descendantNodes() -> [ProjectTreeNode]
  {
    var descendants=[ProjectTreeNode]()
    
    for  child in self.childNodes
    {
      descendants.append(child)
      if (!child.isLeaf)
      {
        descendants += child.descendantNodes()
      }
    }
    
    return descendants
  }
  
  public func descendantLeafNodes() -> [ProjectTreeNode]
  {
    var descendants=[ProjectTreeNode]()
    
    for  child in self.childNodes
    {
      if child.isLeaf
      {
        descendants.append(child)
      }
      if (!child.isLeaf)
      {
        descendants += child.descendantLeafNodes()
      }
    }
    
    return descendants
  }
  
  public func descendantGroupNodes() -> [ProjectTreeNode]
  {
    var descendants: [ProjectTreeNode] = []
    
    for  child in self.childNodes
    {
      if (!child.isLeaf)
      {
        descendants.append(child)
        descendants += child.descendantGroupNodes()
      }
    }
    
    return descendants
  }
  
  public func flattenedObjects() -> [iRASPAProject]
  {
    return [representedObject] + self.descendantObjects()
  }
  
  
  public func descendantObjects() -> [iRASPAProject]
  {
    var descendants: [iRASPAProject] = []
    
    for  child in self.childNodes
    {
      descendants.append(child.representedObject)
      if (!child.isLeaf)
      {
        descendants += child.descendantObjects()
      }
    }
    
    return descendants
  }
  
  
  public func isDescendantOfNode(_ parentNode: ProjectTreeNode) -> Bool
  {
    var treeNode: ProjectTreeNode? = self
    while(treeNode != nil)
    {
      if (treeNode! == parentNode)
      {
        return true
      }
      else
      {
        treeNode=treeNode?.parentNode
      }
    }
    return false
  }
  
  public func findLocalRootsOfSelectedSubTrees(selection: Set<ProjectTreeNode>) -> [ProjectTreeNode]
  {
    var localRoots: [ProjectTreeNode] = []
    
    // if not selected, then potentially all childNodes can be roots
    for child in self.childNodes
    {
      if !selection.contains(self) && selection.contains(child)
      {
        localRoots.append(child)
      }
      else
      {
        localRoots += child.findLocalRootsOfSelectedSubTrees(selection: selection)
      }
    }
    
    return localRoots
  }
  
  public func copyOfSelectionOfSubTree(selection: Set<ProjectTreeNode>, recursive: Bool) -> ProjectTreeNode
  {
    let copy: ProjectTreeNode = ProjectTreeNode.init(displayName: self.displayName, representedObject: self.representedObject)
    
    if selection.contains(self)
    {
      for child in childNodes
      {
        if recursive && selection.contains(self)
        {
          copy.childNodes.append(child.copyOfSubTree())
        }
        else
        {
          if selection.contains(child)
          {
            copy.childNodes.append(child.copyOfSelectionOfSubTree(selection: selection, recursive: recursive))
          }
        }
      }
      
      return copy
    }
    return copy
  }
  
  public func copyOfSubTree() -> ProjectTreeNode
  {
    let copy: ProjectTreeNode = ProjectTreeNode.init(displayName: self.displayName, representedObject: self.representedObject)
    
    for child in childNodes
    {
      copy.childNodes.append(child.copyOfSubTree())
    }
    
    return copy
  }
  
  // MARK: -
  // MARK: Filtering support
  
  
  public func updateFilteredAndSortedNodes()
  {
    self.filteredAndSortedNodes = self.childNodes.filter{$0.matchesFilter}
    // if we have filtered nodes, then all parents of this node needs to be included
    if (self.filteredAndSortedNodes.count > 0)
    {
      self.matchesFilter = true
    }
  }
  
  
  public func updateFilteredChildren(_ predicate: (ProjectTreeNode) -> Bool)
  {
    for node in self.childNodes
    {
      node.matchesFilter = true
      node.matchesFilter = predicate(self)
    }
    
    self.filteredAndSortedNodes = self.childNodes.filter{$0.matchesFilter}
    
    // if we have filtered nodes, then all parents of this node needs to be included
    if (self.filteredAndSortedNodes.count > 0)
    {
      self.matchesFilter = true
    }
  }
  
  public func updateFilteredChildrenRecursively(_ predicate: (ProjectTreeNode) -> Bool)
  {
    self.matchesFilter = false
    
    self.matchesFilter = predicate(self)
    
    for node in childNodes
    {
      node.updateFilteredChildrenRecursively(predicate)
    }
    
    // if we have filtered nodes, then all parents of this node needs to be included
    if (self.matchesFilter)
    {
      if let parentNode = parentNode
      {
        parentNode.matchesFilter = true
      }
    }
    
    filteredAndSortedNodes = childNodes.filter{$0.matchesFilter}
    
  }
  
  public func setFilteredNodesAsMatching()
  {
    self.matchesFilter = true
    filteredAndSortedNodes = childNodes
    for node in childNodes
    {
      node.setFilteredNodesAsMatching()
    }
  }
  
  enum ProjectTreeError: Error
  {
    case corruptedData
  }
  
  
  public  func unwrapProject(outlineView: NSOutlineView?, queue projectQueue: OperationQueue?, colorSets: SKColorSets, forceFieldSets: SKForceFieldSets, reloadCompletionBlock: @escaping () -> ()) throws
  {
    switch(self.representedObject.lazyStatus)
    {
    case .lazy:
      if self.representedObject.storageType == iRASPAProject.StorageType.local
      {
        if let data = self.representedObject.data?.decompress(withAlgorithm: .lzma)
        {
          do
          {
            switch(self.representedObject.projectType)
            {
            case .structure:
              let projectStructureNode: ProjectStructureNode = try BinaryDecoder(data: [UInt8](data)).decode(ProjectStructureNode.self)
            
              // legacy for new file-format
              projectStructureNode.fileName = self.representedObject.fileNameUUID
              
              self.representedObject = iRASPAProject(structureProject: projectStructureNode)
              self.representedObject.nodeType = .leaf
              self.representedObject.lazyStatus = .loaded
              self.representedObject.loadedProjectStructureNode?.allStructures.forEach{$0.setRepresentationForceField(forceField: $0.atomForceFieldIdentifier, forceFieldSets: forceFieldSets)}
            case .group:
              let projectGroupNode: ProjectGroup = try BinaryDecoder(data: [UInt8](data)).decode(ProjectGroup.self)
              
              // legacy for new file-format
              projectGroupNode.fileName = self.representedObject.fileNameUUID
              
              self.representedObject = iRASPAProject(group: projectGroupNode)
              self.representedObject.nodeType = .group
              self.representedObject.lazyStatus = .loaded
            default:
              fatalError()
              break
            }
          }
          catch let error
          {
            LogQueue.shared.error(destination: nil, message: error.localizedDescription)
          }
        }
        else
        {
          throw ProjectTreeError.corruptedData
        }
      }
      else if self.representedObject.storageType == iRASPAProject.StorageType.publicCloud
      {
        let loadingStatus: iRASPAProject = iRASPAProject(projectType: .structure, fileName: self.representedObject.fileNameUUID, nodeType: self.representedObject.nodeType, storageType: self.representedObject.storageType, lazyStatus: iRASPAProject.LazyStatus.loading)
        loadingStatus.volumetricSurfaceArea = self.representedObject.volumetricSurfaceArea
        loadingStatus.gravimetricSurfaceArea = self.representedObject.gravimetricSurfaceArea
        loadingStatus.heliumVoidFraction = self.representedObject.heliumVoidFraction
        loadingStatus.largestOverallCavityDiameter = self.representedObject.largestOverallCavityDiameter
        loadingStatus.restrictingPoreDiameter = self.representedObject.restrictingPoreDiameter
        loadingStatus.largestDiameterAlongViablePath = self.representedObject.largestDiameterAlongViablePath
        loadingStatus.density = self.representedObject.density
        loadingStatus.mass = self.representedObject.mass
        loadingStatus.specificVolume = self.representedObject.specificVolume
        loadingStatus.accessiblePoreVolume = self.representedObject.accessiblePoreVolume
        loadingStatus.numberOfChannelSystems = self.representedObject.numberOfChannelSystems
        loadingStatus.numberOfInaccesiblePockets = self.representedObject.numberOfInaccesiblePockets
        loadingStatus.dimensionalityPoreSystem = self.representedObject.dimensionalityPoreSystem
        loadingStatus.materialType = self.representedObject.materialType
          
        self.representedObject = loadingStatus
        let operation: ImportProjectFromCloudOperation = ImportProjectFromCloudOperation(projectTreeNode: self, outlineView:  outlineView, forceFieldSets: forceFieldSets, reloadCompletionBlock: reloadCompletionBlock)
        projectQueue?.addOperation(operation)
      }
    default:
      break
    }
    
    self.representedObject.loadedProjectStructureNode?.allStructures.forEach{$0.setRepresentationForceField(forceField: $0.atomForceFieldIdentifier, forceFieldSets: forceFieldSets)}
  }
  
  // used to unwrap when deleting for undo
  public func unwrapLazyLocalPresentedObjectIfNeeded()
  {
    debugPrint("unwrapLazyLocalPresentedObjectIfNeeded")
    if let data = self.representedObject.data?.decompress(withAlgorithm: .lzma), self.representedObject.lazyStatus == .lazy
    {
      do
      {
        switch(self.representedObject.projectType)
        {
        case .structure:
          let projectStructureNode: ProjectStructureNode = try BinaryDecoder(data: [UInt8](data)).decode(ProjectStructureNode.self)
          
          self.representedObject = iRASPAProject(structureProject: projectStructureNode)
          self.representedObject.lazyStatus = .loaded
        case .group:
          let projectGroupNode: ProjectGroup = try BinaryDecoder(data: [UInt8](data)).decode(ProjectGroup.self)
          
          self.representedObject = iRASPAProject(group: projectGroupNode)
          self.representedObject.lazyStatus = .loaded
        default:
          break
        }
      }
      catch
      {
        LogQueue.shared.error(destination: nil, message: "Unable to unwrap \(self.representedObject.project.displayName)")
      }
    }
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(ProjectTreeNode.classVersionNumber)
    
    encoder.encode(self.displayName)
    
    encoder.encode(self.isEditable)
    encoder.encode(self.isDropEnabled)
    
    encoder.encode(self.representedObject)
    
    encoder.encode(self.childNodes)
  }
  
  public func binaryEncode(to encoder: BinaryEncoder, encodeRepresentedObject: Bool, encodeChildren: Bool)
  {
    encoder.encode(ProjectTreeNode.classVersionNumber)
    
    encoder.encode(self.displayName)
    
    encoder.encode(self.isEditable)
    encoder.encode(self.isDropEnabled)
    
    encoder.encode(self.representedObject, encodeRepresentedObject: encodeRepresentedObject)
    
    if encodeChildren
    {
      encoder.encode(self.childNodes.filter{$0.representedObject.lazyStatus != .loading}, encodeRepresentedObject: encodeRepresentedObject, encodeChildren: encodeChildren)
    }
    else
    {
      encoder.encode(Array<ProjectTreeNode>())
    }
  }
  
  
  // MARK: -
  // MARK: Binary Decodable support
  
  public  init(fromBinary decoder: BinaryDecoder) throws
  {
    let versionNumber: Int = try decoder.decode(Int.self)
    if versionNumber > ProjectTreeNode.classVersionNumber
    {
      throw iRASPAError.invalidArchiveVersion
    }
    
    displayName = try decoder.decode(String.self)
    isEditable = try decoder.decode(Bool.self)
    isDropEnabled = try decoder.decode(Bool.self)
    
    representedObject = try decoder.decode(iRASPAProject.self)
    
    
    childNodes = try decoder.decode([ProjectTreeNode].self)
    
    super.init()
    
    for child in childNodes
    {
      child.parentNode = self
    }
  }
  
  public init(fromBinary decoder: BinaryDecoder, decodeRepresentedObject: Bool, decodeChildren: Bool) throws
  {
    let versionNumber: Int = try decoder.decode(Int.self)
    if versionNumber > ProjectTreeNode.classVersionNumber
    {
      throw iRASPAError.invalidArchiveVersion
    }
  
    displayName = try decoder.decode(String.self)
    isEditable = try decoder.decode(Bool.self)
    isDropEnabled = try decoder.decode(Bool.self)
  
    representedObject = try decoder.decode(iRASPAProject.self, decodeRepresentedObject: decodeRepresentedObject)
  
    super.init()
    //if decodeChildren
    //{
      childNodes = try decoder.decode([ProjectTreeNode].self,  decodeRepresentedObject: decodeRepresentedObject, decodeChildren: decodeChildren)
  
      for child in childNodes
      {
        child.parentNode = self
      }
    //}
  }
  
}

