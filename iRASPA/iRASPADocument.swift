/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

import Cocoa
import RenderKit
import LogViewKit
import SymmetryKit
import SimulationKit
import iRASPAKit
import simd
import OperationKit
import Compression
import BinaryCodable
import ZIPFoundation
import Compression
import UniformTypeIdentifiers


class iRASPADocument: NSDocument, ForceFieldViewer, NSSharingServicePickerDelegate
{
  var documentData: DocumentData = DocumentData()
  var colorSets: SKColorSets = SKColorSets()
  var forceFieldSets: SKForceFieldSets = SKForceFieldSets()
  
  override class var autosavesInPlace: Bool
  {
    return Preferences.shared.autosaving
  }
  
  override func canAsynchronouslyWrite(to url: URL, ofType typeName: String,for saveOperation: NSDocument.SaveOperationType) -> Bool
  {
    return true
  }
  
  override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool
  {
    return true
  }
  
  override func makeWindowControllers()
  {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    if let windowController: iRASPAWindowController = storyboard.instantiateController(withIdentifier: "Document Window Controller") as? iRASPAWindowController
    {
      windowController.currentDocument = self
      self.addWindowController(windowController)
    
      windowController.masterTabViewController?.initializeData()
    }
  }
  
  
  // MARK: Saving data
  // =====================================================================
  
  
  // var cancelAutosave: Bool = false
  // avoid periodic autosaving when there is work on the 'Window-controller-queue' (e.g. importing projects)
  override func autosave(withImplicitCancellability autosavingIsImplicitlyCancellable: Bool, completionHandler: @escaping (Error?) -> Void)
  {
    // check if autosaving is in progress but nothing bad would happen if it were cancelled
    if (autosavingIsImplicitlyCancellable)
    {
      if let projectSerialQueue: FKOperationQueue = (self.windowControllers.first as? iRASPAWindowController)?.projectSerialQueue,
         let projectConcurrentQueue: FKOperationQueue = (self.windowControllers.first as? iRASPAWindowController)?.projectConcurrentQueue,
        (projectSerialQueue.operations.count > 0 || projectConcurrentQueue.operations.count > 0)
          {
            LogQueue.shared.info(destination: self.windowControllers.first, message: "Postponing autosave due to pending importing/exporting operations")
            completionHandler(NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil))
            return
        }
      
      if iRASPAWindowController.dragAndDropConcurrentQueue.operations.count > 0 ||
         iRASPAWindowController.copyAndPasteConcurrentQueue.operations.count > 0
      {
        LogQueue.shared.info(destination: self.windowControllers.first, message: "Postponing autosave due to pending copy-and-paste operations")
        completionHandler(NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil))
        return
      }
      
      if iRASPAWindowController.dragAndDropConcurrentQueue.operations.count > 0 ||
         iRASPAWindowController.copyAndPasteConcurrentQueue.operations.count > 0
      {
        LogQueue.shared.info(destination: self.windowControllers.first, message: "Postponing autosave due to pending drag-and-drop operations")
        completionHandler(NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil))
        return
      }
    }
    
    // autosaving is being done because the document is being closed (not cancelable)
    LogQueue.shared.info(destination: self.windowControllers.first, message: NSLocalizedString("Autosaving....", bundle: Bundle(for: iRASPADocument.self),  comment: ""))
    super.autosave(withImplicitCancellability: autosavingIsImplicitlyCancellable, completionHandler: completionHandler)
  }
  
  override func write(to url: URL, ofType typeName: String) throws
  {
    if let archive: Archive = Archive(url: url, accessMode: Archive.AccessMode.create)
    {
      var info: mach_timebase_info_data_t = mach_timebase_info_data_t()
      mach_timebase_info(&info)
      
      let startTime: UInt64  = mach_absolute_time()
      
      let binaryEncoder: BinaryEncoder = BinaryEncoder.init()
      binaryEncoder.encode(documentData)
      let mainData: Data = Data(binaryEncoder.data)
      
      // add the main-entry "nl.darkwing.iRASPA_projectData"
      try archive.addEntry(with: "nl.darkwing.iRASPA_projectData", type: Entry.EntryType.file, uncompressedSize: UInt32(mainData.count), compressionMethod: .none, provider: { (position, size) -> Data in
        return mainData.subdata(in: position ..< position+size)
      })
      
      let colorBinaryEncoder: BinaryEncoder = BinaryEncoder()
      colorBinaryEncoder.encode(colorSets)
      let colorData: Data = Data(colorBinaryEncoder.data)
      
      // add the colorData-entry "nl.darkwing.iRASPA_colorData"
      try archive.addEntry(with: "nl.darkwing.iRASPA_colorData", type: Entry.EntryType.file, uncompressedSize: UInt32(colorData.count), compressionMethod: .none, provider: { (position, size) -> Data in
        return colorData.subdata(in: position ..< position+size)
      })
      
      let forceFieldBinaryEncoder: BinaryEncoder = BinaryEncoder.init()
      forceFieldBinaryEncoder.encode(forceFieldSets)
      let forceFieldData: Data = Data(forceFieldBinaryEncoder.data)
      
      // add the forceField-entry "nl.darkwing.iRASPA_forceFieldData"
      try archive.addEntry(with: "nl.darkwing.iRASPA_forceFieldData", type: Entry.EntryType.file, uncompressedSize: UInt32(forceFieldData.count), compressionMethod: .none, provider: { (position, size) -> Data in
        return forceFieldData.subdata(in: position ..< position+size)
      })
      
      // archive all the individual projects in individual files
      let projectTreeNodeNodes: [ProjectTreeNode] = self.documentData.projectLocalRootNode.descendantNodes()
      
      for projectTreeNode in projectTreeNodeNodes
      {
        // only archive projects that have changes
        let project: iRASPAProject = projectTreeNode.representedObject
        
        if (project.undoManager.canUndo || project.isEdited)
        {
          let compressedData: Data = project.projectData()
          projectTreeNode.representedObject.data = compressedData
        
          try archive.addEntry(with: "nl.darkwing.iRASPA_Project_" + project.fileNameUUID, type: Entry.EntryType.file, uncompressedSize: UInt32(compressedData.count), compressionMethod: .none, provider: { (position, size) -> Data in
              return compressedData.subdata(in: position ..< position+size)
            })
            
          // project is 'clean' again
          project.data = compressedData
          project.isEdited = false
        }
        else
        {
          let compressedData: Data = project.projectData()
          
          try archive.addEntry(with: "nl.darkwing.iRASPA_Project_" + project.fileNameUUID, type: Entry.EntryType.file, uncompressedSize: UInt32(compressedData.count), compressionMethod: .none, provider: { (position, size) -> Data in
              return compressedData.subdata(in: position ..< position+size)
          })
        }
      }
      let endTime: UInt64  = mach_absolute_time()
      let time: Double = Double((endTime - startTime) * UInt64(info.numer)) / Double(info.denom) * 0.000000001
      //let formattedTime = String(format: "%.3f", time)
      
      let formatter = MeasurementFormatter()
      formatter.unitStyle = .short
      formatter.unitOptions = .providedUnit
      let string = formatter.string(from: Measurement(value: time, unit: UnitDuration.seconds))
      let message: String = String.localizedStringWithFormat(NSLocalizedString("Saving to Archive (%@)", comment: ""), string)
      
      LogQueue.shared.verbose(destination: self.windowControllers.first, message: message)
    }
    else
    {
      LogQueue.shared.error(destination: self.windowControllers.first, message: "Failed to create archive \(url.absoluteString) of type \(typeName)")
    }
    
  }
  
  
  // MARK: Reading data
  // =====================================================================
  
  func readDocumentFileFormat(url: URL) throws
  {
    var info: mach_timebase_info_data_t = mach_timebase_info_data_t()
    mach_timebase_info(&info)
    
    let startTime: UInt64  = mach_absolute_time()
    
    let data = try Data(contentsOf: url)
    guard let archive = Archive(data: data, accessMode: .read, preferredEncoding: .utf8) else {
      LogQueue.shared.error(destination: self.windowControllers.first, message: "Unable to open archive, " + url.absoluteString)
      return
    }
    
    // create dictionary to create an order of magntitude speed up in reading the entries.
    let dictionary = Dictionary(grouping: archive, by: { $0.path})
   
    if let forceFieldData = dictionary["nl.darkwing.iRASPA_forceFieldData"]
    {
      if forceFieldData.count > 1
      {
        LogQueue.shared.warning(destination: self.windowControllers.first, message: "Multiple Force field-sets found in archive, only reading the first")
      }
      if let entry = forceFieldData.first
      {
        do
        {
          var readData: Data = Data(capacity: entry.uncompressedSize)
          let _ = try archive.extract(entry, consumer: { (data: Data) in
            readData.append(data)
          })
          self.forceFieldSets = try BinaryDecoder(data: [UInt8](readData)).decode(SKForceFieldSets.self)
        }
        catch
        {
          LogQueue.shared.warning(destination: self.windowControllers.first, message: "Force field-set loading error, " + error.localizedDescription)
        }
      }
    }
    else
    {
      LogQueue.shared.warning(destination: self.windowControllers.first, message: "Force field-sets not found in archive")
    }
    
    if let colorData = dictionary["nl.darkwing.iRASPA_colorData"]
    {
      if colorData.count > 1
      {
        LogQueue.shared.warning(destination: self.windowControllers.first, message: "Multiple Color-sets found in archive, only reading the first")
      }
      if let entry = colorData.first
      {
        do
        {
          var readData: Data = Data(capacity: entry.uncompressedSize)
          let _ = try archive.extract(entry, consumer: { (data: Data) in
            readData.append(data)
          })
          self.colorSets = try BinaryDecoder(data: [UInt8](readData)).decode(SKColorSets.self)
        }
        catch
        {
          LogQueue.shared.warning(destination: self.windowControllers.first, message: "Color-set loading error, " + error.localizedDescription)
        }
      }
    }
    
    guard let projectEntry = dictionary["nl.darkwing.iRASPA_projectData"]?.first else {
      LogQueue.shared.error(destination: self.windowControllers.first, message: "Project data missing")
      return
    }
    
    do
    {
      var readData: Data = Data(capacity: projectEntry.uncompressedSize)
      let _ = try archive.extract(projectEntry, consumer: { (data: Data) in
        readData.append(data)
      })
      self.documentData = try BinaryDecoder(data: [UInt8](readData)).decode(DocumentData.self)
    }
    catch let error
    {
      LogQueue.shared.error(destination: self.windowControllers.first, message: "Accesing entry \(projectEntry.path) from ZIP archive failed with error, " + error.localizedDescription)
      return
    }
    
    let projectTreeNodes: [ProjectTreeNode] = self.documentData.projectLocalRootNode.flattenedNodes()
    for projectTreeNode: ProjectTreeNode in projectTreeNodes
    {
      if let projectData = dictionary["nl.darkwing.iRASPA_Project_" + projectTreeNode.representedObject.fileNameUUID]
      {
        if projectData.count > 1
        {
          LogQueue.shared.warning(destination: self.windowControllers.first, message: "Multiple projects with the same id-found in archive, only reading the first")
        }
        if let entry = projectData.first
        {
          do
          {
            var readData: Data = Data(capacity: entry.uncompressedSize)
            let _ = try archive.extract(entry, consumer: { (data: Data) in
              readData.append(data)
            })
            // store the untouched/unwrapped data in the project
            projectTreeNode.representedObject.data = readData
          }
          catch let error
          {
            LogQueue.shared.error(destination: self.windowControllers.first, message: "Accesing entry \(entry.path) from ZIP archive failed with error, " + error.localizedDescription)
          }
        }
      }
    }
    let endTime: UInt64  = mach_absolute_time()
    let time: Double = Double((endTime - startTime) * UInt64(info.numer)) / Double(info.denom) * 0.000000001
    
    let formatter = MeasurementFormatter()
    formatter.unitStyle = .short
    formatter.unitOptions = .providedUnit
    let string = formatter.string(from: Measurement(value: time, unit: UnitDuration.seconds))
    let message: String = String.localizedStringWithFormat(NSLocalizedString("Document Read (%@)", comment: ""), string)
    
    // make sure to run this on the main thread
    DispatchQueue.main.async(execute: {
      self.windowControllers.forEach{($0 as? iRASPAWindowController)?.masterTabViewController?.reloadData()}
      
      LogQueue.shared.verbose(destination: self.windowControllers.first, message: message)
    })
  }
  
  func readProjectFileFormat(url: URL) throws
  {
    // read single-project ".iraspa" format
    if let data: Data = try? Data(contentsOf: url),
       let compressedData: Data = data.decompress(withAlgorithm: .lzma)
    {
      let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](compressedData))
      do
      {
        let projectTreeNode: ProjectTreeNode = try binaryDecoder.decode(ProjectTreeNode.self, decodeRepresentedObject: true, decodeChildren: false)
        
        // make sure to run this on the main thread
        DispatchQueue.main.async
          {
            projectTreeNode.insert(inParent: self.documentData.projectLocalRootNode, atIndex: 0)
            
            if #available(OSX 11.0, *)
            {
              self.fileType = UTType.irspdoc.identifier
            }
            else
            {
              self.fileType = typeirspdoc as String
            }
            self.fileURL = nil    // disassociate document from file; makes document "untitled"
            self.displayName = projectTreeNode.displayName
            (self.windowControllers.first as? iRASPAWindowController)?.masterTabViewController?.reloadData()
        }
      }
      catch let error
      {
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Accesing main entry from ZIP archive failed with error, " + error.localizedDescription)
        return
      }
    }
    else
    {
      throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: [
        NSLocalizedDescriptionKey: NSLocalizedString("Could Not Read Main Database File", comment: ""),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString("Invalid File Format", comment: "")
        ])
    }
  }
  
  func readCIFFileFormat(url: URL)
  {
    if let data: Data = try? Data.init(contentsOf: url)
    {
      let displayName: String = url.deletingPathExtension().lastPathComponent
      
      do
      {
        let cifParser: SKCIFParser = try SKCIFParser(displayName: displayName, data: data)
        try cifParser.startParsing()
        let scene: Scene = Scene(parser: cifParser.scene)
        let sceneList: SceneList = SceneList(name: displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        let proxyProject: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
        
        DispatchQueue.main.async {
          proxyProject.insert(inParent: self.documentData.projectLocalRootNode, atIndex: 0)
          
          if #available(OSX 11.0, *)
          {
            self.fileType = UTType.irspdoc.identifier
          }
          else
          {
            self.fileType = typeirspdoc as String
          }
          self.fileURL = nil                   // disassociate document from file; makes document "untitled"
          self.displayName = displayName
          self.windowControllers.forEach{($0 as? iRASPAWindowController)?.masterTabViewController?.reloadData()}
        }
      }
      catch
      {
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Accesing CIF-file failed with error, " + error.localizedDescription)
        return
      }
    }
  }
  
  func readPDBFileFormat(url: URL) throws
  {
    if let data: Data = try? Data.init(contentsOf: url)
    {
      let displayName: String = url.deletingPathExtension().lastPathComponent
      
      do
      {
        let pdbParser: SKPDBParser = try SKPDBParser(displayName: displayName, data: data, onlyAsymmetricUnitMolecule: true, asMolecule: false, asProtein: true)
        try pdbParser.startParsing()
        let scene: Scene = Scene(parser: pdbParser.scene)
        let sceneList: SceneList = SceneList(name: displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        let proxyProject: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
        
        DispatchQueue.main.async {
           proxyProject.insert(inParent: self.documentData.projectLocalRootNode, atIndex: 0)
          
          if #available(OSX 11.0, *)
          {
            self.fileType = UTType.irspdoc.identifier
          }
          else
          {
            self.fileType = typeirspdoc as String
          }
          self.fileURL = nil                   // disassociate document from file; makes document "untitled"
          self.displayName = displayName
          self.windowControllers.forEach{($0 as? iRASPAWindowController)?.masterTabViewController?.reloadData()}
        }
      }
      catch
      {
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Accesing PDB-file failed with error, " + error.localizedDescription)
        return
      }
    }
  }
  
  func readXYZFileFormat(url: URL) throws
  {
    if let data: Data = try? Data.init(contentsOf: url)
    {
      let displayName: String = url.deletingPathExtension().lastPathComponent
      
      do
      {
        let xyzParser: SKXYZParser = try SKXYZParser(displayName: displayName, data: data)
        try xyzParser.startParsing()
        let scene: Scene = Scene(parser: xyzParser.scene)
        let sceneList: SceneList = SceneList(name: displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        let proxyProject: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
        
        DispatchQueue.main.async {
          proxyProject.insert(inParent: self.documentData.projectLocalRootNode, atIndex: 0)
          
          if #available(OSX 11.0, *)
          {
            self.fileType = UTType.irspdoc.identifier
          }
          else
          {
            self.fileType = typeirspdoc as String
          }
          self.fileURL = nil                   // disassociate document from file; makes document "untitled"
          self.displayName = displayName
          self.windowControllers.forEach{($0 as? iRASPAWindowController)?.masterTabViewController?.reloadData()}
        }
      }
      catch
      {
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Accesing PDB-file failed with error, " + error.localizedDescription)
        return
      }
    }
  }
  
  func readPOSCARFileFormat(url: URL) throws
  {
    if let data: Data = try? Data.init(contentsOf: url)
    {
      let displayName: String = url.deletingPathExtension().lastPathComponent
      
      do
      {
        let VASPParser: SKVASPPOSCARParser = try SKVASPPOSCARParser(displayName: displayName, data: data)
        try VASPParser.startParsing()
        let scene: Scene = Scene(parser: VASPParser.scene)
        let sceneList: SceneList = SceneList(name: displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        let proxyProject: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
        
        DispatchQueue.main.async {
          proxyProject.insert(inParent: self.documentData.projectLocalRootNode, atIndex: 0)
          
          if #available(OSX 11.0, *)
          {
            self.fileType = UTType.irspdoc.identifier
          }
          else
          {
            self.fileType = typeirspdoc as String
          }
          self.fileURL = nil                   // disassociate document from file; makes document "untitled"
          self.displayName = displayName
          self.windowControllers.forEach{($0 as? iRASPAWindowController)?.masterTabViewController?.reloadData()}
        }
      }
      catch
      {
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Accesing PDB-file failed with error, " + error.localizedDescription)
        return
      }
    }
  }
  
  func readCHGCARFileFormat(url: URL) throws
  {
    if let data: Data = try? Data.init(contentsOf: url)
    {
      let displayName: String = url.deletingPathExtension().lastPathComponent
      
      do
      {
        let VASPCHGCARParser: SKVASPCHGCARParser = try SKVASPCHGCARParser(displayName: displayName, data: data)
        try VASPCHGCARParser.startParsing()
        let scene: Scene = Scene(parser: VASPCHGCARParser.scene)
        let sceneList: SceneList = SceneList(name: displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        let proxyProject: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
        
        DispatchQueue.main.async {
          proxyProject.insert(inParent: self.documentData.projectLocalRootNode, atIndex: 0)
          
          if #available(OSX 11.0, *)
          {
            self.fileType = UTType.irspdoc.identifier
          }
          else
          {
            self.fileType = typeirspdoc as String
          }
          self.fileURL = nil                   // disassociate document from file; makes document "untitled"
          self.displayName = displayName
          self.windowControllers.forEach{($0 as? iRASPAWindowController)?.masterTabViewController?.reloadData()}
        }
      }
      catch
      {
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Accesing PDB-file failed with error, " + error.localizedDescription)
        return
      }
    }
  }
  
  func readLOCPOTFileFormat(url: URL) throws
  {
    if let data: Data = try? Data.init(contentsOf: url)
    {
      let displayName: String = url.deletingPathExtension().lastPathComponent
      
      do
      {
        let VASPLOCPOTParser: SKVASPLOCPOTParser = try SKVASPLOCPOTParser(displayName: displayName, data: data)
        try VASPLOCPOTParser.startParsing()
        let scene: Scene = Scene(parser: VASPLOCPOTParser.scene)
        let sceneList: SceneList = SceneList(name: displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        let proxyProject: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
        
        DispatchQueue.main.async {
          proxyProject.insert(inParent: self.documentData.projectLocalRootNode, atIndex: 0)
          
          if #available(OSX 11.0, *)
          {
            self.fileType = UTType.irspdoc.identifier
          }
          else
          {
            self.fileType = typeirspdoc as String
          }
          self.fileURL = nil                   // disassociate document from file; makes document "untitled"
          self.displayName = displayName
          self.windowControllers.forEach{($0 as? iRASPAWindowController)?.masterTabViewController?.reloadData()}
        }
      }
      catch
      {
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Accesing PDB-file failed with error, " + error.localizedDescription)
        return
      }
    }
  }
  
  func readELFCARFileFormat(url: URL) throws
  {
    if let data: Data = try? Data.init(contentsOf: url)
    {
      let displayName: String = url.deletingPathExtension().lastPathComponent
      
      do
      {
        let VASPELFCARParser: SKVASPELFCARParser = try SKVASPELFCARParser(displayName: displayName, data: data)
        try VASPELFCARParser.startParsing()
        let scene: Scene = Scene(parser: VASPELFCARParser.scene)
        let sceneList: SceneList = SceneList(name: displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        let proxyProject: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
        
        DispatchQueue.main.async {
          proxyProject.insert(inParent: self.documentData.projectLocalRootNode, atIndex: 0)
          
          if #available(OSX 11.0, *)
          {
            self.fileType = UTType.irspdoc.identifier
          }
          else
          {
            self.fileType = typeirspdoc as String
          }
          self.fileURL = nil                   // disassociate document from file; makes document "untitled"
          self.displayName = displayName
          self.windowControllers.forEach{($0 as? iRASPAWindowController)?.masterTabViewController?.reloadData()}
        }
      }
      catch
      {
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Accesing PDB-file failed with error, " + error.localizedDescription)
        return
      }
    }
  }
  
  func readXDATCARFileFormat(url: URL) throws
  {
    if let data: Data = try? Data.init(contentsOf: url)
    {
      let displayName: String = url.deletingPathExtension().lastPathComponent
      
      do
      {
        let VASPParser: SKVASPXDATCARParser = try SKVASPXDATCARParser(displayName: displayName, data: data)
        try VASPParser.startParsing()
        let scene: Scene = Scene(parser: VASPParser.scene)
        let sceneList: SceneList = SceneList(name: displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        let proxyProject: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
        
        DispatchQueue.main.async {
          proxyProject.insert(inParent: self.documentData.projectLocalRootNode, atIndex: 0)
          
          if #available(OSX 11.0, *)
          {
            self.fileType = UTType.irspdoc.identifier
          }
          else
          {
            self.fileType = typeirspdoc as String
          }
          self.fileURL = nil                   // disassociate document from file; makes document "untitled"
          self.displayName = displayName
          self.windowControllers.forEach{($0 as? iRASPAWindowController)?.masterTabViewController?.reloadData()}
        }
      }
      catch
      {
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Accesing PDB-file failed with error, " + error.localizedDescription)
        return
      }
    }
  }
  
  func readCubeFileFormat(url: URL) throws
  {
    if let data: Data = try? Data.init(contentsOf: url)
    {
      let displayName: String = url.deletingPathExtension().lastPathComponent
      
      do
      {
        let VASPParser: SKGaussianCubeParser = try SKGaussianCubeParser(displayName: displayName, data: data)
        try VASPParser.startParsing()
        let scene: Scene = Scene(parser: VASPParser.scene)
        let sceneList: SceneList = SceneList(name: displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        let proxyProject: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
        
        DispatchQueue.main.async {
          proxyProject.insert(inParent: self.documentData.projectLocalRootNode, atIndex: 0)
          
          if #available(OSX 11.0, *)
          {
            self.fileType = UTType.irspdoc.identifier
          }
          else
          {
            self.fileType = typeirspdoc as String
          }
          self.fileURL = nil                   // disassociate document from file; makes document "untitled"
          self.displayName = displayName
          self.windowControllers.forEach{($0 as? iRASPAWindowController)?.masterTabViewController?.reloadData()}
        }
      }
      catch
      {
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Accesing PDB-file failed with error, " + error.localizedDescription)
        return
      }
    }
  }
  
  override func read(from url: URL, ofType typeName: String) throws
  {
    if #available(OSX 11.0, *)
    {
      switch(typeName)
      {
      case UTType.irspdoc.identifier:
        try readDocumentFileFormat(url: url)
      case UTType.iraspa.identifier:
        try readProjectFileFormat(url: url)
      case UTType.cif.identifier:
        readCIFFileFormat(url: url)
      case UTType.pdb.identifier:
        try readPDBFileFormat(url: url)
      case UTType.xyz.identifier:
        try readXYZFileFormat(url: url)
      case UTType.cube.identifier:
        try readCubeFileFormat(url: url)
      default:
        if (url.pathExtension.isEmpty)
        {
          if (url.lastPathComponent.uppercased() == "POSCAR" ||
              url.lastPathComponent.uppercased() == "CONTCAR")
          {
            try readPOSCARFileFormat(url: url)
          }
          else if (url.lastPathComponent.uppercased() == "CHGCAR")
          {
            try readCHGCARFileFormat(url: url)
          }
          else if (url.lastPathComponent.uppercased() == "LOCPOT")
          {
            try readLOCPOTFileFormat(url: url)
          }
          else if (url.lastPathComponent.uppercased() == "ELFCAR")
          {
            try readELFCARFileFormat(url: url)
          }
          else if (url.lastPathComponent.uppercased() == "XDATCAR")
          {
            try readXDATCARFileFormat(url: url)
          }
        }
      }
    }
    else
    {
      switch(typeName as CFString)
      {
      case typeirspdoc:
        try readDocumentFileFormat(url: url)
      case typeProject:
        try readProjectFileFormat(url: url)
      case typeCIF:
        try readCIFFileFormat(url: url)
      case typePDB:
        try readPDBFileFormat(url: url)
      case typeXYZ:
        try readXYZFileFormat(url: url)
      case typeGAUSSIANCUBE:
        try readCubeFileFormat(url: url)
      default:
        if (url.pathExtension.isEmpty)
        {
          if (url.lastPathComponent.uppercased() == "POSCAR" ||
              url.lastPathComponent.uppercased() == "CONTCAR")
          {
            try readPOSCARFileFormat(url: url)
          }
          else if (url.lastPathComponent.uppercased() == "CHGCAR")
          {
            try readCHGCARFileFormat(url: url)
          }
          else if (url.lastPathComponent.uppercased() == "LOCPOT")
          {
            try readLOCPOTFileFormat(url: url)
          }
          else if (url.lastPathComponent.uppercased() == "ELFCAR")
          {
            try readELFCARFileFormat(url: url)
          }
          else if (url.lastPathComponent.uppercased() == "XDATCAR")
          {
            try readXDATCARFileFormat(url: url)
          }
        }
      }
    }
    
    try super.read(from: url, ofType: typeName)
  }
  
  override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws
  {
  }
  
  // MARK: Printing data
  // =====================================================================
  
  
  override func printOperation(withSettings printSettings: [NSPrintInfo.AttributeKey : Any]) throws -> NSPrintOperation
  {
    let renderViewController: RenderTabViewController? = (self.windowControllers.first as? iRASPAWindowController)?.detailTabViewController?.renderViewController
    
    let printInfo: NSPrintInfo = self.printInfo
    printInfo.horizontalPagination = .fit
    printInfo.verticalPagination = .fit
    printInfo.isHorizontallyCentered = true
    printInfo.isVerticallyCentered = true
    printInfo.topMargin = 0
    printInfo.bottomMargin = 0
    printInfo.leftMargin = 0
    printInfo.rightMargin = 0
    
    let printableView: NSView = PrintingView(renderViewController)
    
    let printerOperation: NSPrintOperation = NSPrintOperation(view: printableView, printInfo: printInfo)
    printerOperation.printPanel.options = [.showsOrientation, .showsPreview, .showsPaperSize]
    return printerOperation
  }
  
  override func prepare(_ sharingServicePicker: NSSharingServicePicker)
  {
    sharingServicePicker.delegate = self
  }
  
  func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService]
  {
    let emailService: NSSharingService? = NSSharingService(named: NSSharingService.Name.composeEmail)
    let airDropService: NSSharingService? = NSSharingService(named: NSSharingService.Name.sendViaAirDrop)
    let messageService: NSSharingService? = NSSharingService(named: NSSharingService.Name.composeMessage)
    var cloudSharingService: NSSharingService? = nil
    
    cloudSharingService = NSSharingService(named: NSSharingService.Name.cloudSharing)
    
    // only selected the ones that are available (airdrop is only available when wifi is supported,
    // email when an email-client is installed)
    return [emailService, messageService, airDropService, cloudSharingService].compactMap{$0}
  }
  
}

