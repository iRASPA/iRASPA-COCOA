/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import ZIPFoundation
import BinaryCodable
import iRASPAKit
import LogViewKit

extension iRASPADocument
{
  func loadGalleryDatabase()
  {
    DispatchQueue.global(qos: .userInitiated).async(execute: {
      if let url: URL = Bundle.main.url(forResource: "Gallery", withExtension: "irspdoc")
      {
        var documentDataGallery: DocumentData
        guard let archive = Archive(url: url, accessMode: .read) else  {
          return
        }
        
        guard let entry = archive["nl.darkwing.iRASPA_projectData"] else {
          return
        }
        
        do
        {
          var readData: Data = Data(capacity: entry.uncompressedSize)
          let _ = try archive.extract(entry, consumer: { (data: Data) in
            readData.append(data)
          })
          
          documentDataGallery = try BinaryDecoder(data: [UInt8](readData)).decode(DocumentData.self)
        }
        catch let error
        {
          debugPrint("Accesing main entry from ZIP archive failed with error:\(error)")
          return
        }
        
        let projectTreeNodes: [ProjectTreeNode] = documentDataGallery.projectLocalRootNode.flattenedNodes()
        for node: ProjectTreeNode in projectTreeNodes
        {
          //debugPrint("node: \(node.displayName)  \(node.representedObject.fileNameUUID)")
          if let entry = archive["nl.darkwing.iRASPA_Project_" + node.representedObject.fileNameUUID]
          {
            do
            {
              //debugPrint("data: \(entry.uncompressedSize)")
              var readData: Data = Data(capacity: entry.uncompressedSize)
              let _ = try archive.extract(entry, consumer: { (data: Data) in
                readData.append(data)
              })
              
              // store the untouched/unwrapped data in the project
              node.representedObject.data = readData
            }
            catch let error
            {
              debugPrint("Accesing main entry from ZIP archive failed with error:\(error)")
              return
            }
          }
        }
        
        DispatchQueue.main.async {
          let windowController: iRASPAWindowController? = self.windowControllers.first as? iRASPAWindowController
          let projectOutlineView: ProjectOutlineView? = windowController?.masterTabViewController?.masterViewController?.projectViewController?.projectOutlineView
          
          for (index, child) in documentDataGallery.projectLocalRootNode.childNodes.enumerated()
          {
            child.insert(inParent: self.documentData.galleryLocalRootNode, atIndex: index)
          }
          
          self.documentData.galleryLocalRootNode.flattenedNodes().forEach{$0.isEditable = false}
          
          self.documentData.projectData.updateFilteredNodes()
          projectOutlineView?.reloadItem(self.documentData.galleryLocalRootNode)
          
          windowController?.detailTabViewController?.directoryViewController?.reloadData()
        }
      }
      else
      {
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Loading error, ")
      }
    })
  }
  
  func loadCoREMOFDatabase()
  {
    DispatchQueue.global(qos: .userInitiated).async(execute: {
      if let url: URL = Bundle.main.url(forResource: "CloudCoREMOFDatabase_v1.0", withExtension: "data")
      {
        do
        {
          let cloudFileWrapper = try FileWrapper(url: url, options: FileWrapper.ReadingOptions.immediate)
          if let data: Data = cloudFileWrapper.regularFileContents
          {
            // get the whole tree of ProxyProject but do not load the 'representedObjects' (i.e. the projects themselves)
            // The projects will be loaded 'on-demand'
            
            let cloudProjectTreeNode: ProjectTreeNode = try BinaryDecoder(data: [UInt8](data)).decode(ProjectTreeNode.self)
            
            for node in cloudProjectTreeNode.flattenedGroupNodes()
            {
              node.representedObject.project = ProjectGroup(name: node.displayName)
              node.representedObject.lazyStatus = .loaded
            }
           
            DispatchQueue.main.async {
              let windowController: iRASPAWindowController? = self.windowControllers.first as? iRASPAWindowController
               let projectOutlineView: ProjectOutlineView? = windowController?.masterTabViewController?.masterViewController?.projectViewController?.projectOutlineView
              
              // update project outlineview
              
              projectOutlineView?.beginUpdates()
              
              for (index, child) in cloudProjectTreeNode.childNodes.enumerated()
              {
                child.insert(inParent: self.documentData.cloudCoREMOFRootNode, atIndex: index)
              }
              
              self.documentData.cloudCoREMOFRootNode.flattenedNodes().forEach{$0.isEditable = false}
              self.documentData.projectData.updateFilteredNodes()
              projectOutlineView?.endUpdates()
              
              windowController?.detailTabViewController?.directoryViewController?.reloadData()
            }
            
          }
          else
          {
            LogQueue.shared.error(destination: self.windowControllers.first, message: "Loading error, ")
          }
        }
        catch
        {
          LogQueue.shared.error(destination: self.windowControllers.first, message: "Loading error, " + error.localizedDescription)
        }
      }
      else
      {
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Loading error, ")
      }
    })
  }
  
  func loadCoREMOFDDECDatabase()
  {
    DispatchQueue.global(qos: .userInitiated).async(execute: {
      if let url: URL = Bundle.main.url(forResource: "CloudCoREMOFDDECDatabase_v1.0", withExtension: "data")
      {
        do
        {
          let cloudFileWrapper = try FileWrapper(url: url, options: FileWrapper.ReadingOptions.immediate)
          if let data: Data = cloudFileWrapper.regularFileContents
          {
            // get the whole tree of ProxyProject but do not load the 'representedObjects' (i.e. the projects themselves)
            // The projects will be loaded 'on-demand'
            
            let cloudProjectTreeNode: ProjectTreeNode = try BinaryDecoder(data: [UInt8](data)).decode(ProjectTreeNode.self)
            
            for node in cloudProjectTreeNode.flattenedGroupNodes()
            {
              node.representedObject.project = ProjectGroup(name: node.displayName)
              node.representedObject.lazyStatus = .loaded
            }
            
            DispatchQueue.main.async {
              let windowController: iRASPAWindowController? = self.windowControllers.first as? iRASPAWindowController
              let projectOutlineView: ProjectOutlineView? = windowController?.masterTabViewController?.masterViewController?.projectViewController?.projectOutlineView
              
              // update project outlineview
              projectOutlineView?.beginUpdates()
              
              for (index, child) in cloudProjectTreeNode.childNodes.enumerated()
              {
                child.insert(inParent: self.documentData.cloudCoREMOFDDECRootNode, atIndex: index)
              }
              
              self.documentData.cloudCoREMOFDDECRootNode.flattenedNodes().forEach{$0.isEditable = false}
              self.documentData.projectData.updateFilteredNodes()
              projectOutlineView?.endUpdates()
              
              windowController?.detailTabViewController?.directoryViewController?.reloadData()
            }
          }
          else
          {
            LogQueue.shared.error(destination: self.windowControllers.first, message: "Loading error, ")
          }
        }
        catch let error
        {
           LogQueue.shared.error(destination: self.windowControllers.first, message: "Loading error, " + error.localizedDescription)
          
        }
      }
      else
      {
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Loading error, ")
      }
    })
  }
  
  func loadIZADatabase()
  {
    DispatchQueue.global(qos: .userInitiated).async(execute: {
      if let url: URL = Bundle.main.url(forResource: "CloudIZADatabase", withExtension: "data")
      {
        do
        {
          let cloudFileWrapper = try FileWrapper(url: url, options: FileWrapper.ReadingOptions.immediate)
          if let data: Data = cloudFileWrapper.regularFileContents
          {
            // get the whole tree of ProxyProject but do not load the 'representedObjects' (i.e. the projects themselves)
            // The projects will be loaded 'on-demand'
            
            let cloudProjectTreeNode: ProjectTreeNode = try BinaryDecoder(data: [UInt8](data)).decode(ProjectTreeNode.self)
            
            for node in cloudProjectTreeNode.flattenedGroupNodes()
            {
              node.representedObject.project = ProjectGroup(name: node.displayName)
              node.representedObject.lazyStatus = .loaded
            }
            
            DispatchQueue.main.async {
              let windowController: iRASPAWindowController? = self.windowControllers.first as? iRASPAWindowController
              let projectOutlineView: ProjectOutlineView? = windowController?.masterTabViewController?.masterViewController?.projectViewController?.projectOutlineView
              
              // update project outlineview
              projectOutlineView?.beginUpdates()
              
              
              for (index, child) in cloudProjectTreeNode.childNodes.enumerated()
              {
                child.insert(inParent: self.documentData.cloudIZARootNode, atIndex: index)
              }
              
              self.documentData.projectData.updateFilteredNodes()
              projectOutlineView?.endUpdates()
              
              windowController?.detailTabViewController?.directoryViewController?.reloadData()
            }
          }
          else
          {
            LogQueue.shared.error(destination: self.windowControllers.first, message: "Loading error, ")
          }
        }
        catch let error
        {
          // Cloud-file not found (should NOT happen)
          LogQueue.shared.error(destination: self.windowControllers.first, message: "Loading error, " + error.localizedDescription)
        }
      }
      else
      {
        LogQueue.shared.error(destination: self.windowControllers.first, message: "Loading error, ")
      }
    })
  }
}
