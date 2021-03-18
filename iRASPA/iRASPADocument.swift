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



class iRASPADocument: NSDocument, ForceFieldDefiner, NSSharingServicePickerDelegate
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
  
  
  //var cancelAutosave: Bool = false
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
    LogQueue.shared.info(destination: self.windowControllers.first, message: "Autosaving....")
    super.autosave(withImplicitCancellability: autosavingIsImplicitlyCancellable, completionHandler: completionHandler)
  }
  
  override func write(to url: URL, ofType typeName: String) throws
  {
    if let archive: Archive = Archive(url: url, accessMode: Archive.AccessMode.create)
    {
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
    }
    LogQueue.shared.info(destination: self.windowControllers.first, message: "Saving to file.")
  }
  
  
  // MARK: Reading data
  // =====================================================================
  
  func readModernDocumentFileFormat(url: URL) throws
  {
    guard let archive = Archive(url: url, accessMode: .read) else  {
      return
    }
   
    if let entry = archive["nl.darkwing.iRASPA_forceFieldData"]
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
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Force field-set loading error, " + error.localizedDescription)
      }
    }
    
    if let entry = archive["nl.darkwing.iRASPA_colorData"]
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
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Force field-set loading error, " + error.localizedDescription)
      }
    }
    
    guard let entry = archive["nl.darkwing.iRASPA_projectData"] else {
      LogQueue.shared.error(destination: self.windowControllers.first, message: "Color data missing")
      return
    }
    
    do
    {
      var readData: Data = Data(capacity: entry.uncompressedSize)
      let _ = try archive.extract(entry, consumer: { (data: Data) in
        readData.append(data)
      })
      
      self.documentData = try BinaryDecoder(data: [UInt8](readData)).decode(DocumentData.self)
    }
    catch let error
    {
      LogQueue.shared.error(destination: self.windowControllers.first, message: "Accesing main entry from ZIP archive failed with error, " + error.localizedDescription)
      return
    }
    
    let projectTreeNodes: [ProjectTreeNode] = self.documentData.projectLocalRootNode.flattenedNodes()
    for node: ProjectTreeNode in projectTreeNodes
    {
      if let entry = archive["nl.darkwing.iRASPA_Project_" + node.representedObject.fileNameUUID]
      {
        do
        {
          var readData: Data = Data(capacity: entry.uncompressedSize)
          let _ = try archive.extract(entry, consumer: { (data: Data) in
            readData.append(data)
          })
          
          // store the untouched/unwrapped data in the project
          node.representedObject.data = readData
        }
        catch let error
        {
          LogQueue.shared.error(destination: self.windowControllers.first, message: "Accesing main entry from ZIP archive failed with error, " + error.localizedDescription)
          return
        }
      }
    }
    
    // make sure to run this on the main thread
    DispatchQueue.main.async(execute: {
      self.windowControllers.forEach{($0 as? iRASPAWindowController)?.masterTabViewController?.reloadData()}
    })
  }
  
  func readModernProjectFileFormat(url: URL) throws
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
            
            self.fileType = iRASPAUniversalDocumentUTI
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
        NSLocalizedDescriptionKey: NSLocalizedString("Could not read main database file.", comment: "Read error description"),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString("File was in an invalid format.", comment: "Read failure reason")
        ])
    }
  }
  
  func readCIFFileFormat(url: URL) throws
  {
    if let data: Data = try? Data.init(contentsOf: url),
       let cifString: String = String(data: data, encoding: String.Encoding.ascii)
    {
      let displayName: String = url.deletingPathExtension().lastPathComponent
      
      let cifParser: SKCIFParser = SKCIFParser(displayName: displayName, string: cifString, windowController: self.windowControllers.first)
      do
      {
        try cifParser.startParsing()
        let scene: Scene = Scene(parser: cifParser.scene)
        let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
        let proxyProject: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
        
        DispatchQueue.main.async {
          proxyProject.insert(inParent: self.documentData.projectLocalRootNode, atIndex: 0)
          
          self.fileType = iRASPAUniversalDocumentUTI
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
    if let data: Data = try? Data.init(contentsOf: url),
      let pdbString: String = String(data: data, encoding: String.Encoding.ascii)
    {
      let displayName: String = url.deletingPathExtension().lastPathComponent
      
      let pdbParser: SKPDBParser = SKPDBParser(displayName: displayName, string: pdbString, windowController: self.windowControllers.first, onlyAsymmetricUnit: true, asMolecule: true)
      do
      {
        try pdbParser.startParsing()
        let scene: Scene = Scene(parser: pdbParser.scene)
        let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
        let proxyProject: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
        
        DispatchQueue.main.async {
           proxyProject.insert(inParent: self.documentData.projectLocalRootNode, atIndex: 0)
          
          self.fileType = iRASPAUniversalDocumentUTI
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
    if let data: Data = try? Data.init(contentsOf: url),
       let xyzString: String = String(data: data, encoding: String.Encoding.ascii)
    {
      let displayName: String = url.deletingPathExtension().lastPathComponent
      
      let xyzParser: SKXYZParser = SKXYZParser(displayName: displayName, string: xyzString, windowController: self.windowControllers.first)
      do
      {
        try xyzParser.startParsing()
        let scene: Scene = Scene(parser: xyzParser.scene)
        let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
        let proxyProject: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
        
        DispatchQueue.main.async {
          proxyProject.insert(inParent: self.documentData.projectLocalRootNode, atIndex: 0)
          
          self.fileType = iRASPAUniversalDocumentUTI
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
    if let data: Data = try? Data.init(contentsOf: url),
      let VASPString: String = String(data: data, encoding: String.Encoding.ascii)
    {
      let displayName: String = url.deletingPathExtension().lastPathComponent
      
      let VASPParser: SKPOSCARParser = SKPOSCARParser(displayName: displayName, string: VASPString, windowController: self.windowControllers.first)
      do
      {
        try VASPParser.startParsing()
        let scene: Scene = Scene(parser: VASPParser.scene)
        let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
        let proxyProject: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
        
        DispatchQueue.main.async {
          proxyProject.insert(inParent: self.documentData.projectLocalRootNode, atIndex: 0)
          
          self.fileType = iRASPAUniversalDocumentUTI
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
    if let data: Data = try? Data.init(contentsOf: url),
      let VASPString: String = String(data: data, encoding: String.Encoding.ascii)
    {
      let displayName: String = url.deletingPathExtension().lastPathComponent
      
      let VASPParser: SKXDATCARParser = SKXDATCARParser(displayName: displayName, string: VASPString, windowController: self.windowControllers.first)
      do
      {
        try VASPParser.startParsing()
        let scene: Scene = Scene(parser: VASPParser.scene)
        let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
        let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
        let proxyProject: ProjectTreeNode = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
        
        DispatchQueue.main.async {
          proxyProject.insert(inParent: self.documentData.projectLocalRootNode, atIndex: 0)
          
          self.fileType = iRASPAUniversalDocumentUTI
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
    switch(typeName)
    {
    case iRASPAUniversalDocumentUTI:
      try readModernDocumentFileFormat(url: url)
    case iRASPAProjectUTI:
      try readModernProjectFileFormat(url: url)
    case iRASPA_CIF_UTI:
      try readCIFFileFormat(url: url)
    case iRASPA_PDB_UTI:
      try readPDBFileFormat(url: url)
    case iRASPA_XYZ_UTI:
      try readXYZFileFormat(url: url)
    default:
      if (url.pathExtension.isEmpty)
      {
        if (url.lastPathComponent.uppercased() == "POSCAR" ||
            url.lastPathComponent.uppercased() == "CONTCAR")
        {
          try readPOSCARFileFormat(url: url)
        }
        else if (url.lastPathComponent.uppercased() == "XDATCAR")
        {
          try readXDATCARFileFormat(url: url)
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
    if #available(OSX 10.12, *)
    {
      cloudSharingService = NSSharingService(named: NSSharingService.Name.cloudSharing)
    }
    
    // only selected the ones that are available (airdrop is only available when wifi is supported,
    // email when an email-client is installed)
    return [emailService, messageService, airDropService, cloudSharingService].compactMap{$0}
  }
  
}

