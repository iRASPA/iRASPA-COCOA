import UIKit
import UniformTypeIdentifiers
import ZIPFoundation
import BinaryCodable
import iRASPAKit
import SimulationKit
import SymmetryKit
import LogViewKit

final class iRASPAUIDocument: UIDocument, ForceFieldViewer
{
  var documentData: DocumentData = DocumentData()
  var colorSets: SKColorSets = SKColorSets()
  var forceFieldSets: SKForceFieldSets = SKForceFieldSets()

  override func contents(forType typeName: String) throws -> Any
  {
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".irspdoc")
    try writeArchive(to: tempURL)
    let data = try Data(contentsOf: tempURL)
    try? FileManager.default.removeItem(at: tempURL)
    return data
  }

  override func load(fromContents contents: Any, ofType typeName: String?) throws
  {
    guard let data = contents as? Data else {
      throw CocoaError(.fileReadCorruptFile)
    }
    let ext = fileURL.pathExtension.lowercased()
    if ext == "irspdoc" || ext == "iraspa"
    {
      try readArchive(data: data)
    }
    else
    {
      try importStructure(data: data, url: fileURL)
    }
    DocumentContext.forceFieldViewer = self
  }

  private func writeArchive(to url: URL) throws
  {
    guard let archive = Archive(url: url, accessMode: .create) else {
      throw CocoaError(.fileWriteUnknown)
    }
    func addEntry(name: String, payload: Data) throws
    {
      try archive.addEntry(with: name, type: .file, uncompressedSize: UInt32(payload.count), compressionMethod: .none, provider: { position, size in
        return payload.subdata(in: position ..< position + size)
      })
    }
    let projectEncoder = BinaryEncoder()
    projectEncoder.encode(documentData)
    try addEntry(name: "nl.darkwing.iRASPA_projectData", payload: Data(projectEncoder.data))

    let colorEncoder = BinaryEncoder()
    colorEncoder.encode(colorSets)
    try addEntry(name: "nl.darkwing.iRASPA_colorData", payload: Data(colorEncoder.data))

    let forceFieldEncoder = BinaryEncoder()
    forceFieldEncoder.encode(forceFieldSets)
    try addEntry(name: "nl.darkwing.iRASPA_forceFieldData", payload: Data(forceFieldEncoder.data))

    for projectTreeNode in documentData.projectLocalRootNode.descendantNodes()
    {
      let compressedData: Data = projectTreeNode.representedObject.projectData()
      try addEntry(name: "nl.darkwing.iRASPA_Project_" + projectTreeNode.representedObject.fileNameUUID, payload: compressedData)
    }
  }

  private func readArchive(data: Data) throws
  {
    guard let archive = Archive(data: data, accessMode: .read, preferredEncoding: .utf8) else {
      throw CocoaError(.fileReadCorruptFile)
    }
    let dictionary = Dictionary(grouping: archive, by: { $0.path })

    if let entry = dictionary["nl.darkwing.iRASPA_forceFieldData"]?.first
    {
      var readData = Data(capacity: entry.uncompressedSize)
      _ = try archive.extract(entry, consumer: { readData.append($0) })
      forceFieldSets = try BinaryDecoder(data: [UInt8](readData)).decode(SKForceFieldSets.self)
    }
    if let entry = dictionary["nl.darkwing.iRASPA_colorData"]?.first
    {
      var readData = Data(capacity: entry.uncompressedSize)
      _ = try archive.extract(entry, consumer: { readData.append($0) })
      colorSets = try BinaryDecoder(data: [UInt8](readData)).decode(SKColorSets.self)
    }
    guard let projectEntry = dictionary["nl.darkwing.iRASPA_projectData"]?.first else {
      throw CocoaError(.fileReadCorruptFile)
    }
    var projectBytes = Data(capacity: projectEntry.uncompressedSize)
    _ = try archive.extract(projectEntry, consumer: { projectBytes.append($0) })
    documentData = try BinaryDecoder(data: [UInt8](projectBytes)).decode(DocumentData.self)

    for projectTreeNode in documentData.projectLocalRootNode.flattenedNodes()
    {
      let uuid = projectTreeNode.representedObject.fileNameUUID
      let key = "nl.darkwing.iRASPA_Project_" + uuid
      let entry = dictionary[key]?.first ?? dictionary.first(where: { $0.key.hasSuffix(uuid) })?.value.first
      if let entry
      {
        var blob = Data(capacity: entry.uncompressedSize)
        _ = try archive.extract(entry, consumer: { blob.append($0) })
        projectTreeNode.representedObject.data = blob
      }
    }
    LogQueue.shared.info(destination: nil, message: "Opened document with \(documentData.projectLocalRootNode.descendantLeafNodes().count) local projects")
  }

  private func importStructure(data: Data, url: URL) throws
  {
    documentData = DocumentData()
    guard importStructure(from: url) != nil else {
      throw CocoaError(.fileReadCorruptFile)
    }
  }

  /// Parses one structure file honoring the import options — the iPad
  /// counterpart of Cocoa's `ReadStructureOperation` parser dispatch.
  private func parseScene(url: URL, onlyAsymmetricUnit: Bool, asMolecule: Bool, separatePolymerChains: Bool) -> Scene?
  {
    guard let data = try? Data(contentsOf: url) else { return nil }
    let displayName = url.deletingPathExtension().lastPathComponent
    let fileName = url.lastPathComponent.uppercased()

    let parser: SKParser?
    switch url.pathExtension.uppercased()
    {
    case "CIF", "MMCIF":
      parser = try? SKCIFParser(displayName: displayName, data: data, onlyAsymmetricUnit: onlyAsymmetricUnit, asMolecule: asMolecule, asProtein: !asMolecule, separatePolymerChains: separatePolymerChains)
    case "PDB", "ENT":
      parser = try? SKPDBParser(displayName: displayName, data: data, onlyAsymmetricUnitMolecule: onlyAsymmetricUnit, asMolecule: asMolecule, asProtein: !asMolecule, separatePolymerChains: separatePolymerChains)
    case "XYZ":
      parser = try? SKXYZParser(displayName: displayName, data: data)
    case "POSCAR", "CONTCAR":
      parser = try? SKVASPPOSCARParser(displayName: displayName, data: data)
    case "VTK":
      parser = try? SKVTKParser(displayName: displayName, data: data)
    case "CUBE", "CUB":
      parser = try? SKGaussianCubeParser(displayName: displayName, data: data)
    case "":
      switch fileName
      {
      case "POSCAR", "CONTCAR":
        parser = try? SKVASPPOSCARParser(displayName: displayName, data: data)
      case "CHGCAR":
        parser = try? SKVASPCHGCARParser(displayName: displayName, data: data)
      case "LOCPOT":
        parser = try? SKVASPLOCPOTParser(displayName: displayName, data: data)
      case "ELFCAR":
        parser = try? SKVASPELFCARParser(displayName: displayName, data: data)
      case "XDATCAR":
        parser = try? SKVASPXDATCARParser(displayName: displayName, data: data)
      default:
        parser = nil
      }
    default:
      parser = nil
    }
    guard let parser else { return nil }
    do
    {
      try parser.startParsing()
    }
    catch
    {
      return nil
    }
    return Scene(parser: parser.scene)
  }

  /// Turns a scene list into a project node and finishes it the way Cocoa's
  /// `ImportProjectOperation` does (default style, bonds, insertion).
  private func makeProjectNode(displayName: String, sceneList: SceneList) -> ProjectTreeNode
  {
    let projectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
    let project = iRASPAProject(structureProject: projectStructureNode)
    project.isEdited = true
    let node = ProjectTreeNode(displayName: displayName, representedObject: project)

    // Proteins/DNA already received licorice + ribbon defaults during Scene
    // import; everything else gets the default ball-and-stick look.
    let structures = projectStructureNode.sceneList.allObjects.compactMap { $0 as? Structure }
    for structure in structures
    {
      if structure is Protein || structure is ProteinCrystal || structure is DNA || structure is DNACrystal { continue }
      structure.setRepresentationStyle(style: .default, colorSets: colorSets)
    }
    for structure in structures
    {
      structure.setRepresentationForceField(forceField: SKForceFieldSets.suggestedDisplayName(forMaterialTypeName: structure.structureMaterialType), forceFieldSets: forceFieldSets)
    }
    projectStructureNode.setInitialSelectionIfNeeded()
    documentData.projectData.insertNode(node, inItem: documentData.projectLocalRootNode, atIndex: documentData.projectLocalRootNode.childNodes.count)
    return node
  }

  /// Import with the options from the import sheet — the iPad counterpart of
  /// Cocoa's `importStructureFiles(_:importType:onlyAsymmetricUnit:asMolecule:separatePolymerChains:)`.
  @discardableResult
  func importStructures(urls: [URL], importType: SKParser.ImportType,
                        onlyAsymmetricUnit: Bool, asMolecule: Bool,
                        separatePolymerChains: Bool) -> [ProjectTreeNode]
  {
    guard !urls.isEmpty else { return [] }

    // Documents (.irspdoc/.iraspa) ignore the structure-import options.
    var structureURLs: [URL] = []
    var importedNodes: [ProjectTreeNode] = []
    for url in urls
    {
      let ext = url.pathExtension.lowercased()
      if ext == "irspdoc" || ext == "iraspa"
      {
        if let node = importStructure(from: url)
        {
          importedNodes.append(node)
        }
      }
      else
      {
        structureURLs.append(url)
      }
    }
    guard !structureURLs.isEmpty else { return importedNodes }

    func scene(_ url: URL) -> Scene?
    {
      let scene = parseScene(url: url, onlyAsymmetricUnit: onlyAsymmetricUnit, asMolecule: asMolecule, separatePolymerChains: separatePolymerChains)
      if scene == nil
      {
        LogQueue.shared.error(destination: nil, message: "Could not import \(url.lastPathComponent)")
      }
      return scene
    }

    switch importType
    {
    case .asSeperateProjects:
      for url in structureURLs
      {
        guard let scene = scene(url) else { continue }
        let displayName = url.deletingPathExtension().lastPathComponent
        importedNodes.append(makeProjectNode(displayName: displayName, sceneList: SceneList(scenes: [scene])))
      }
    case .asSingleProject:
      let scenes = structureURLs.compactMap(scene)
      guard !scenes.isEmpty else { break }
      let displayName = structureURLs[0].deletingPathExtension().lastPathComponent
      importedNodes.append(makeProjectNode(displayName: displayName, sceneList: SceneList(scenes: scenes)))
    case .asMovieFrames:
      let scenes = structureURLs.compactMap(scene)
      guard !scenes.isEmpty else { break }
      let displayName = structureURLs[0].deletingPathExtension().lastPathComponent
      importedNodes.append(makeProjectNode(displayName: displayName, sceneList: SceneList(frames: scenes.flatMap { $0.allIRASPObjects })))
    }

    if !importedNodes.isEmpty
    {
      updateChangeCount(.done)
      LogQueue.shared.info(destination: nil, message: "Imported \(importedNodes.map { $0.displayName }.joined(separator: ", "))")
    }
    return importedNodes
  }

  @discardableResult
  func importStructure(from url: URL) -> ProjectTreeNode?
  {
    guard let node = ProjectTreeNode(url: url, preview: false) else {
      LogQueue.shared.error(destination: nil, message: "Could not import \(url.lastPathComponent)")
      return nil
    }
    if url.pathExtension.lowercased() == "irspdoc", node.displayName == "Imported"
    {
      node.displayName = url.deletingPathExtension().lastPathComponent
    }
    node.representedObject.loadedProjectStructureNode?.allObjects.compactMap({ $0 as? Structure }).forEach {
      $0.setRepresentationForceField(forceField: $0.atomForceFieldIdentifier, forceFieldSets: forceFieldSets)
    }
    node.representedObject.loadedProjectStructureNode?.setInitialSelectionIfNeeded()
    documentData.projectData.insertNode(node, inItem: documentData.projectLocalRootNode, atIndex: documentData.projectLocalRootNode.childNodes.count)
    updateChangeCount(.done)
    LogQueue.shared.info(destination: nil, message: "Imported \(node.displayName)")
    return node
  }
}
