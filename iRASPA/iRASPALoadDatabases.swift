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
import ZIPFoundation
import BinaryCodable
import iRASPAKit
import LogViewKit

extension ProjectViewController
{
  func loadGalleryDatabase(documentData: DocumentData)
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
              node.isDropEnabled = false
            }
            catch let error
            {
              debugPrint("Accesing main entry from ZIP archive failed with error:\(error)")
              return
            }
          }
        }
        
        DispatchQueue.main.async {
          let projectOutlineView: ProjectOutlineView? = self.projectOutlineView
          
          for (index, child) in documentDataGallery.projectLocalRootNode.childNodes.enumerated()
          {
            child.insert(inParent: documentData.galleryLocalRootNode, atIndex: index)
          }
          
          documentData.galleryLocalRootNode.flattenedNodes().forEach{$0.isEditable = false}
          
          documentData.projectData.updateFilteredNodes()
          projectOutlineView?.reloadItem(documentData.galleryLocalRootNode)
          
      self.windowController?.detailTabViewController?.directoryViewController?.reloadData()
        }
      }
      else
      {
        LogQueue.shared.error(destination: self.windowController, message: "Loading error, ")
      }
    })
  }
  
  func loadCoREMOFDatabase(documentData: DocumentData)
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
               let projectOutlineView: ProjectOutlineView? = self.projectOutlineView
              
              // update project outlineview
              
              projectOutlineView?.beginUpdates()
              
              documentData.cloudCoREMOFRootNode.representedObject.fileNameUUID = cloudProjectTreeNode.representedObject.fileNameUUID
              for (index, child) in cloudProjectTreeNode.childNodes.enumerated()
              {
                child.insert(inParent: documentData.cloudCoREMOFRootNode, atIndex: index)
              }
              
              documentData.cloudCoREMOFRootNode.flattenedNodes().forEach{$0.isEditable = false}
              documentData.projectData.updateFilteredNodes()
              projectOutlineView?.endUpdates()
              
              self.windowController?.detailTabViewController?.directoryViewController?.reloadData()
            }
            
          }
          else
          {
            LogQueue.shared.error(destination: self.windowController, message: "Loading error, ")
          }
        }
        catch
        {
          LogQueue.shared.error(destination: self.windowController, message: "Loading error, " + error.localizedDescription)
        }
      }
      else
      {
        LogQueue.shared.error(destination: self.windowController, message: "Loading error, ")
      }
    })
  }
  
  func loadCoREMOFDDECDatabase(documentData: DocumentData)
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
              let projectOutlineView: ProjectOutlineView? = self.projectOutlineView
              
              // update project outlineview
              projectOutlineView?.beginUpdates()
              
              documentData.cloudCoREMOFDDECRootNode.representedObject.fileNameUUID = cloudProjectTreeNode.representedObject.fileNameUUID
              for (index, child) in cloudProjectTreeNode.childNodes.enumerated()
              {
                child.insert(inParent: documentData.cloudCoREMOFDDECRootNode, atIndex: index)
              }
              
              documentData.cloudCoREMOFDDECRootNode.flattenedNodes().forEach{$0.isEditable = false}
              documentData.projectData.updateFilteredNodes()
              projectOutlineView?.endUpdates()
              
              self.windowController?.detailTabViewController?.directoryViewController?.reloadData()
            }
          }
          else
          {
            LogQueue.shared.error(destination: self.windowController, message: "Loading error, ")
          }
        }
        catch let error
        {
           LogQueue.shared.error(destination: self.windowController, message: "Loading error, " + error.localizedDescription)
          
        }
      }
      else
      {
        LogQueue.shared.error(destination: self.windowController, message: "Loading error, ")
      }
    })
  }
  
  func loadIZADatabase(documentData: DocumentData)
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
              let projectOutlineView: ProjectOutlineView? = self.projectOutlineView
              
              // update project outlineview
              projectOutlineView?.beginUpdates()
              
              documentData.cloudIZARootNode.representedObject.fileNameUUID = cloudProjectTreeNode.representedObject.fileNameUUID
              for (index, child) in cloudProjectTreeNode.childNodes.enumerated()
              {
                child.insert(inParent: documentData.cloudIZARootNode, atIndex: index)
              }
              
              documentData.projectData.updateFilteredNodes()
              projectOutlineView?.endUpdates()
              
          self.windowController?.detailTabViewController?.directoryViewController?.reloadData()
            }
          }
          else
          {
            LogQueue.shared.error(destination: self.windowController, message: "Loading error, ")
          }
        }
        catch let error
        {
          // Cloud-file not found (should NOT happen)
          LogQueue.shared.error(destination: self.windowController, message: "Loading error, " + error.localizedDescription)
        }
      }
      else
      {
        LogQueue.shared.error(destination: self.windowController, message: "Loading error, ")
      }
    })
  }
  
  func saveCoREMOFDatabase(documentData: DocumentData)
  {
    let projectTreeNodeNodes: [ProjectTreeNode] = documentData.cloudCoREMOFRootNode.flattenedNodes()
    
    documentData.cloudCoREMOFRootNode.isEditable = false
    for projectTreeNode in projectTreeNodeNodes
    {
      // set project to not editable
      projectTreeNode.isEditable = false
      
      if(projectTreeNode.representedObject.nodeType == .leaf)
      {
        projectTreeNode.representedObject.lazyStatus = .lazy
        projectTreeNode.representedObject.storageType = .publicCloud
        
        if let projectStructure: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
           let structure = projectStructure.allIRASPAStructures.first
        {
          // if modified, take the new data
          projectTreeNode.representedObject.volumetricSurfaceArea = structure.renderStructureVolumetricNitrogenSurfaceArea ?? 0.0
          projectTreeNode.representedObject.gravimetricSurfaceArea = structure.renderStructureGravimetricNitrogenSurfaceArea ?? 0.0
          projectTreeNode.representedObject.heliumVoidFraction = structure.renderStructureHeliumVoidFraction ?? 0.0
          projectTreeNode.representedObject.largestOverallCavityDiameter = structure.renderStructureLargestCavityDiameter ?? 0.0
          projectTreeNode.representedObject.restrictingPoreDiameter = structure.renderStructureRestrictingPoreLimitingDiameter ?? 0.0
          projectTreeNode.representedObject.largestDiameterAlongViablePath = structure.renderStructureLargestCavityDiameterAlongAViablePath ?? 0.0
          projectTreeNode.representedObject.density = structure.renderStructureDensity ?? 0.0
          projectTreeNode.representedObject.mass = structure.renderStructureMass ?? 0.0
          projectTreeNode.representedObject.specificVolume = structure.renderStructureSpecificVolume ?? 0.0
          projectTreeNode.representedObject.accessiblePoreVolume = structure.renderStructureAccessiblePoreVolume ?? 0.0
          projectTreeNode.representedObject.numberOfChannelSystems = structure.renderStructureNumberOfChannelSystems ?? 0
          projectTreeNode.representedObject.numberOfInaccesiblePockets = structure.renderStructureNumberOfInaccessiblePockets ?? 0
          projectTreeNode.representedObject.dimensionalityPoreSystem = structure.renderStructureDimensionalityOfPoreSystem ?? 0
          projectTreeNode.representedObject.materialType = structure.renderStructureMaterialType ?? "Unspecified"
        }
      }
      
    }
    
    
    let binaryEncoder: BinaryEncoder = BinaryEncoder()
    binaryEncoder.encode(documentData.cloudCoREMOFRootNode)
    let data: Data = Data(binaryEncoder.data)
    
    let paths: [URL] = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
    let url: URL = paths[0].appendingPathComponent("CloudCoREMOFDatabase_v1.0.data")

    do
    {
      try data.write(to: url, options: Data.WritingOptions.atomic)
     }
    catch
    {
      print(error.localizedDescription)
    }
  }
  
  func saveCoREMOFDDECDatabase(documentData: DocumentData)
  {
    let projectTreeNodeNodes: [ProjectTreeNode] = documentData.cloudCoREMOFDDECRootNode.flattenedNodes()
    
    documentData.cloudCoREMOFDDECRootNode.isEditable = false
    for projectTreeNode in projectTreeNodeNodes
    {
      // set project to not editable
      projectTreeNode.isEditable = false
      
      if(projectTreeNode.representedObject.nodeType == .leaf)
      {
        projectTreeNode.representedObject.lazyStatus = .lazy
        projectTreeNode.representedObject.storageType = .publicCloud
        
        if let projectStructure: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
           let structure = projectStructure.allIRASPAStructures.first
        {
          // if modified, take the new data
          projectTreeNode.representedObject.volumetricSurfaceArea = structure.renderStructureVolumetricNitrogenSurfaceArea ?? 0.0
          projectTreeNode.representedObject.gravimetricSurfaceArea = structure.renderStructureGravimetricNitrogenSurfaceArea ?? 0.0
          projectTreeNode.representedObject.heliumVoidFraction = structure.renderStructureHeliumVoidFraction ?? 0.0
          projectTreeNode.representedObject.largestOverallCavityDiameter = structure.renderStructureLargestCavityDiameter ?? 0.0
          projectTreeNode.representedObject.restrictingPoreDiameter = structure.renderStructureRestrictingPoreLimitingDiameter ?? 0.0
          projectTreeNode.representedObject.largestDiameterAlongViablePath = structure.renderStructureLargestCavityDiameterAlongAViablePath ?? 0.0
          projectTreeNode.representedObject.density = structure.renderStructureDensity ?? 0.0
          projectTreeNode.representedObject.mass = structure.renderStructureMass ?? 0.0
          projectTreeNode.representedObject.specificVolume = structure.renderStructureSpecificVolume ?? 0.0
          projectTreeNode.representedObject.accessiblePoreVolume = structure.renderStructureAccessiblePoreVolume ?? 0.0
          projectTreeNode.representedObject.numberOfChannelSystems = structure.renderStructureNumberOfChannelSystems ?? 0
          projectTreeNode.representedObject.numberOfInaccesiblePockets = structure.renderStructureNumberOfInaccessiblePockets ?? 0
          projectTreeNode.representedObject.dimensionalityPoreSystem = structure.renderStructureDimensionalityOfPoreSystem ?? 0
          projectTreeNode.representedObject.materialType = structure.renderStructureMaterialType ?? "Unspecified"
        }
      }
      
    }
    
    
    let binaryEncoder: BinaryEncoder = BinaryEncoder()
    binaryEncoder.encode(documentData.cloudCoREMOFDDECRootNode)
    let data: Data = Data(binaryEncoder.data)
    
    let paths: [URL] = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
    let url: URL = paths[0].appendingPathComponent("CloudCoREMOFDDECDatabase_v1.0.data")

    do
    {
      try data.write(to: url, options: Data.WritingOptions.atomic)
     }
    catch
    {
      print(error.localizedDescription)
    }
  }
  
  func saveIZADatabase(documentData: DocumentData)
  {
    let projectTreeNodeNodes: [ProjectTreeNode] = documentData.cloudIZARootNode.flattenedNodes()
    
    documentData.cloudIZARootNode.isEditable = false
    for projectTreeNode in projectTreeNodeNodes
    {
      // set project to not editable
      projectTreeNode.isEditable = false
      
      if(projectTreeNode.representedObject.nodeType == .leaf)
      {
        projectTreeNode.representedObject.lazyStatus = .lazy
        projectTreeNode.representedObject.storageType = .publicCloud
        
        if let projectStructure: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
           let structure = projectStructure.allIRASPAStructures.first
        {
          // if modified, take the new data
          projectTreeNode.representedObject.volumetricSurfaceArea = structure.renderStructureVolumetricNitrogenSurfaceArea ?? 0.0
          projectTreeNode.representedObject.gravimetricSurfaceArea = structure.renderStructureGravimetricNitrogenSurfaceArea ?? 0.0
          projectTreeNode.representedObject.heliumVoidFraction = structure.renderStructureHeliumVoidFraction ?? 0.0
          projectTreeNode.representedObject.largestOverallCavityDiameter = structure.renderStructureLargestCavityDiameter ?? 0.0
          projectTreeNode.representedObject.restrictingPoreDiameter = structure.renderStructureRestrictingPoreLimitingDiameter ?? 0.0
          projectTreeNode.representedObject.largestDiameterAlongViablePath = structure.renderStructureLargestCavityDiameterAlongAViablePath ?? 0.0
          projectTreeNode.representedObject.density = structure.renderStructureDensity ?? 0.0
          projectTreeNode.representedObject.mass = structure.renderStructureMass ?? 0.0
          projectTreeNode.representedObject.specificVolume = structure.renderStructureSpecificVolume ?? 0.0
          projectTreeNode.representedObject.accessiblePoreVolume = structure.renderStructureAccessiblePoreVolume ?? 0.0
          projectTreeNode.representedObject.numberOfChannelSystems = structure.renderStructureNumberOfChannelSystems ?? 0
          projectTreeNode.representedObject.numberOfInaccesiblePockets = structure.renderStructureNumberOfInaccessiblePockets ?? 0
          projectTreeNode.representedObject.dimensionalityPoreSystem = structure.renderStructureDimensionalityOfPoreSystem ?? 0
          projectTreeNode.representedObject.materialType = structure.renderStructureMaterialType ?? "Unspecified"
        }
      }
      
    }
    
    
    let binaryEncoder: BinaryEncoder = BinaryEncoder()
    binaryEncoder.encode(documentData.cloudIZARootNode)
    let data: Data = Data(binaryEncoder.data)
    
    let paths: [URL] = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
    let url: URL = paths[0].appendingPathComponent("CloudIZADatabase.data")

    do
    {
      try data.write(to: url, options: Data.WritingOptions.atomic)
     }
    catch
    {
      print(error.localizedDescription)
    }
  }
}
