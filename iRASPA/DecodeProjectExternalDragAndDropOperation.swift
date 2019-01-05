/*************************************************************************************************************
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

import Cocoa
import SymmetryKit
import OperationKit
import iRASPAKit
import LogViewKit
import BinaryCodable

class DecodePasteboardItem: FKOperation
{
  let placeholder : ProjectTreeNode
  let windowController: NSWindowController?
  let document: iRASPADocument
  let types: [NSPasteboard.PasteboardType]
  let pasteboardItem: Any
  let outlineView: NSOutlineView?
  
  public init(outlineView: NSOutlineView?, pasteboardItem: Any, placeholder : ProjectTreeNode, types: [NSPasteboard.PasteboardType], windowController: NSWindowController?, document: iRASPADocument)
  {
    self.placeholder = placeholder
    self.pasteboardItem = pasteboardItem
    self.windowController = windowController
    self.document = document
    self.outlineView = outlineView
    self.types = types
    super.init()
    
    // create a new Progress-object (Progress-objects can not be resused)
    progress = Progress.discreteProgress(totalUnitCount: Int64(100))
    progress.completedUnitCount = 0
  }
  
  override func execute()
  {
    if self.isCancelled
    {
      return
    }
    
    if let readObject = DecodePasteboardItem.decodePasteboardItem(pasteboardItem, types: types, windowController: self.windowController, document: document)
    {
      DispatchQueue.main.async(execute: {
        self.placeholder.displayName = readObject.displayName
        self.placeholder.representedObject = readObject.representedObject
        self.placeholder.childNodes = readObject.childNodes
        //self.placeholder.renderCamera = readObject.renderCamera
        for child in self.placeholder.childNodes
        {
          child.parentNode = self.placeholder
        }
        let predicate = self.document.documentData.projectData.filterPredicate
        self.placeholder.updateFilteredChildrenRecursively(predicate)
        self.placeholder.representedObject.isEdited = true
        if let row: Int = self.outlineView?.row(forItem: self.placeholder)
        {
          // 10.11 El Capitan: reloadItem (etc) just reloads the outline view item properties, not the table cell at that item
          self.outlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
        }
      })
    }
    else
    {
      DispatchQueue.main.async(execute: {
        //if case let iRASPAProject.projectProjectLazy(projectStatus) = self.placeholder.representedObject
        //{
        let iraspaproject: iRASPAProject = iRASPAProject.init(projectType: .structure, fileName: self.placeholder.representedObject.fileNameUUID, nodeType: self.placeholder.representedObject.nodeType, storageType: self.placeholder.representedObject.storageType, lazyStatus: .loading)
       self.placeholder.representedObject = iraspaproject
        //iRASPAProject.projectProjectLazy(iRASPAProject.ProjectStatus(fileWrapper: nil, fileName: projectStatus.fileName, nodeType: projectStatus.nodeType, storageType: projectStatus.storageType, lazyStatus: .error, projectType: projectStatus.projectType))
        //}
        if let row: Int = self.outlineView?.row(forItem: self.placeholder)
        {
          // 10.11 El Capitan: reloadItem (etc) just reloads the outline view item properties, not the table cell at that item
          self.outlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
        }
      })
      LogQueue.shared.error(destination: self.windowController, message: "Drop-data of project \(placeholder.displayName) overwritten by new drag from another application (manually delete project and retry original drag/drop)")
    }
    
    self.progress.completedUnitCount = 100
    
    finishWithError(nil)
  }
  
  
  
  static func decodePasteboardItem(_ pasteboardItem: Any, types: [NSPasteboard.PasteboardType],  windowController: NSWindowController?, document: iRASPADocument) -> ProjectTreeNode?
  {
    debugPrint("decodePasteboardItem: \(types)")
    do
    {
      switch(pasteboardItem)
      {
      case let url as URL:
        debugPrint("URL!!!!!!!")
        
        guard FileManager.default.fileExists(atPath: url.path) else {return nil}
        
        let data: Data = try Data(contentsOf: url, options: [])
        let displayName: String = url.deletingPathExtension().lastPathComponent
        
        if let type = try? NSWorkspace.shared.type(ofFile: url.path)
        {
          switch(type)
          {
          case _ where NSWorkspace.shared.type(type, conformsToType: iRASPAProjectUTI):
            debugPrint("HERE!!!")
            let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data.decompress(withAlgorithm: .lzma)!))
            let node: ProjectTreeNode = try binaryDecoder.decode(ProjectTreeNode.self, decodeRepresentedObject: true, decodeChildren: false)
            node.isEditable = true
            return node
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typeCIF)):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let cifParser: SKCIFParser = SKCIFParser(displayName: displayName, string: dataString, windowController: windowController)
            try cifParser.startParsing()
            let scene: Scene = Scene(parser: cifParser.scene, colorSets: document.colorSets, forceFieldSets: document.forceFieldSets)
            let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
            let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
            project.structures.forEach{$0.setRepresentationStyle(style: .default, colorSets: document.colorSets)}
            project.structures.forEach{$0.reComputeBonds()}
            let node = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
            node.isEditable = true
            return node
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typePDB)):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let pdbParser: SKPDBParser = SKPDBParser(displayName: displayName, string: dataString, windowController: windowController, onlyAsymmetricUnit: true)
            try pdbParser.startParsing()
            let scene: Scene = Scene(parser: pdbParser.scene, colorSets: document.colorSets, forceFieldSets: document.forceFieldSets)
            let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
            let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
            project.structures.forEach{$0.setRepresentationStyle(style: .default, colorSets: document.colorSets)}
            project.structures.forEach{$0.reComputeBonds()}
            let node = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
            node.isEditable = true
            return node
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typeXYZ)):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let xyzParser: SKXYZParser = SKXYZParser(displayName: displayName, string: dataString, windowController: windowController)
            try xyzParser.startParsing()
            let scene: Scene = Scene(parser: xyzParser.scene, colorSets: document.colorSets, forceFieldSets: document.forceFieldSets)
            let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
            let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
            project.structures.forEach{$0.setRepresentationStyle(style: .default, colorSets: document.colorSets)}
            project.structures.forEach{$0.reComputeBonds()}
            let node = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
            node.isEditable = true
            return node
          case _ where NSWorkspace.shared.type(type, conformsToType: String(typePOSCAR)) || (url.pathExtension.isEmpty && (url.lastPathComponent.uppercased() == "POSCAR" || url.lastPathComponent.uppercased() == "CONTCAR")):
            guard let dataString: String = String(data: data, encoding: String.Encoding.ascii) else {return nil}
            let poscarParser: SKVASPParser = SKVASPParser(displayName: displayName, string: dataString, windowController: windowController)
            try poscarParser.startParsing()
            let scene: Scene = Scene(parser: poscarParser.scene, colorSets: document.colorSets, forceFieldSets: document.forceFieldSets)
            let sceneList: SceneList = SceneList.init(name: displayName, scenes: [scene])
            let project: ProjectStructureNode = ProjectStructureNode(name: displayName, sceneList: sceneList)
            project.structures.forEach{$0.setRepresentationStyle(style: .default, colorSets: document.colorSets)}
            project.structures.forEach{$0.reComputeBonds()}
            let node = ProjectTreeNode(displayName: displayName, representedObject: iRASPAProject(structureProject: project))
            node.isEditable = true
            return node
          default:
            return nil
          }
        }
      case is EmptyPasteboardItem:
        return nil
      case let item as NSPasteboardItem:
        switch(item)
        {
        case _ where types.contains(where: {$0 == ProjectTreeNodePasteboardType}):
          if let data = item.data(forType: ProjectTreeNodePasteboardType), data.count > 0
          {
            let binaryDecoder: BinaryDecoder = BinaryDecoder(data: [UInt8](data))
            let node: ProjectTreeNode = try binaryDecoder.decode(ProjectTreeNode.self, decodeRepresentedObject: true, decodeChildren: false)
            node.isEditable = true
            return node
          }
        case _ where types.contains(where: {$0 == NSPasteboardTypeMovie}):
          if let readdata = item.data(forType: NSPasteboardTypeMovie), readdata.count > 0
          {
            if let movie: Movie = Movie(pasteboardPropertyList: readdata, ofType: NSPasteboardTypeMovie)
            {
              let scene: Scene = Scene(name: movie.displayName, movies: [movie])
              let sceneList: SceneList = SceneList.init(name: movie.displayName, scenes: [scene])
              let project: ProjectStructureNode = ProjectStructureNode(name: movie.displayName, sceneList: sceneList)
              let node = ProjectTreeNode(displayName: movie.displayName, representedObject: iRASPAProject(structureProject: project))
              node.isEditable = true
              return node
            }
          }
        case _ where types.contains(where: {$0 == NSPasteboard.PasteboardType(String(kUTTypeFileURL))}):
          if let data: Data = item.data(forType: NSPasteboard.PasteboardType(String(kUTTypeFileURL))),
            let str = String(data: data, encoding: .utf8),
            let url = URL(string: str)
          {
            return decodePasteboardItem(url, types: types, windowController: windowController, document: document)
          }
        default:
          return nil
        }
      default:
        return nil
      }
    }
    catch
    {
      LogQueue.shared.error(destination: windowController, message: "Drop data not decodable")
      return nil
    }
    return nil
  }
  
  
  

}

