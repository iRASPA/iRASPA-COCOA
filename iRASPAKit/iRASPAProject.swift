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
import BinaryCodable

public let iRASPAProjectPasteboardType: NSPasteboard.PasteboardType = NSPasteboard.PasteboardType(rawValue: "nl.darkwing.iraspa.iraspa")



public final class iRASPAProject: NSObject, BinaryDecodable, BinaryEncodable, BinaryEncodableRepresentedObject, BinaryDecodableRepresentedObject
{
  public enum ProjectType: Int64
  {
    case none = 0
    case generic=1
    case group=2
    case structure=3
    case VASP=4
    case RASPA=5
    case GULP=6
    case CP2K=7
  }
  
  enum iRASPAProjectError: Error
  {
    case corruptedData
  }
  
  public enum NodeType: Int64
  {
    case group=0
    case leaf=1
  }
  
  public enum  StorageType: Int64
  {
    case local = 0
    case publicCloud = 1
    case privateCloud = 2
    case sharedCloud = 3
  }
  
  public enum  LazyStatus: Int64
  {
    case lazy = 0
    case loaded = 1
    case loading = 2
    case error = 3
  }
  
  let versionNumber: Int64 = 1
  static let classVersionNumber: Int64 = 1
  public var projectType: ProjectType
  public var fileNameUUID: String
  public var nodeType: NodeType
  public var storageType: StorageType
  public var project: ProjectNode
  public var lazyStatus: LazyStatus
  public var data: Data?
  public var fileWrapper: FileWrapper?
  
  //cached properties (dynamically accesible)
  @objc dynamic public var volumetricSurfaceArea: Double = 0.0
  @objc dynamic public var gravimetricSurfaceArea: Double = 0.0
  @objc dynamic public var heliumVoidFraction: Double = 0.0
  @objc dynamic public var largestOverallCavityDiameter: Double = 0.0
  @objc dynamic public var restrictingPoreDiameter: Double = 0.0
  @objc dynamic public var largestDiameterAlongViablePath: Double = 0.0
  @objc dynamic public var density: Double = 0.0
  @objc dynamic public var mass: Double = 0.0
  @objc dynamic public var specificVolume: Double = 0.0
  @objc dynamic public var accessiblePoreVolume: Double = 0.0
  @objc dynamic public var numberOfChannelSystems: Int = 0
  @objc dynamic public var numberOfInaccesiblePockets: Int = 0
  @objc dynamic public var dimensionalityPoreSystem: Int = 0
  @objc dynamic public var materialType: String = "Unspecified"
  
  
  public init(structureProject: ProjectStructureNode)
  {
    self.project = structureProject
    self.projectType = ProjectType.structure
    self.fileNameUUID = UUID().uuidString
    self.nodeType = .leaf
    self.storageType = .local
    self.lazyStatus = .loaded
  }
  
  public init(group: ProjectGroup)
  {
    self.project = group
    self.projectType = ProjectType.group
    self.fileNameUUID = UUID().uuidString
    self.nodeType = .group
    self.storageType = .local
    self.lazyStatus = .loaded
  }
  
  public init(VASP: ProjectVASPNode)
  {
    self.project = VASP
    self.projectType = ProjectType.VASP
    self.fileNameUUID = UUID().uuidString
    self.nodeType = .leaf
    self.storageType = .local
    self.lazyStatus = .loaded
  }
  
  public init(CP2K: ProjectCP2KNode)
  {
    self.project = CP2K
    self.projectType = ProjectType.CP2K
    self.fileNameUUID = UUID().uuidString
    self.nodeType = .leaf
    self.storageType = .local
    self.lazyStatus = .loaded
  }
  
  public init(RASPA: ProjectRASPANode)
  {
    self.project = RASPA
    self.projectType = ProjectType.RASPA
    self.fileNameUUID = UUID().uuidString
    self.nodeType = .leaf
    self.storageType = .local
    self.lazyStatus = .loaded
  }
  
  public init(projectType: ProjectType, fileName: String,
              nodeType: NodeType, storageType: StorageType, lazyStatus: LazyStatus)
  {
    self.project = ProjectNode(name: "")
    self.projectType = ProjectType.structure
    self.fileNameUUID = fileName
    self.nodeType = nodeType
    self.storageType = storageType
    self.lazyStatus = lazyStatus
  }
  
  public var isEdited: Bool
  {
    get
    {
      return project.isEdited
    }
    set(newValue)
    {
      project.isEdited = newValue
    }
  }
  
  public var displayName: String
  {
    get
    {
      return project.displayName
    }
    set(newValue)
    {
      project.displayName = newValue
    }
  }
  
  public var undoManager: UndoManager
  {
    return project.undoManager
  }
  
  public var isProjectStructureNode: Bool
  {
    if projectType == .structure
    {
      return true
    }
    return false
  }
  
  public var isProjectGroup: Bool
  {
    return nodeType == .group
  }
  
  public var isLoading: Bool
  {
    return lazyStatus == .loading
  }
  
  public var loadedProjectStructureNode: ProjectStructureNode?
  {
    if projectType == .structure
    {
      return project as? ProjectStructureNode
    }
    return nil
  }
  
  public func setMainFileWrapper(to mainFileWrapper: FileWrapper)
  {
    self.fileWrapper = mainFileWrapper
  }
  
  //legacy
  public var rawValue: Int64
  {
    if lazyStatus == .lazy
    {
      return 1
    }
    
    return projectType.rawValue
  }
  
  // save the lazy-part (the project)
  // used for saving the document and all projects as separate files that can can be lazily loaded
  public func projectData() -> Data
  {
    let binaryEncoder: BinaryEncoder = BinaryEncoder()
    
    if let data = data, lazyStatus == .lazy
    {
      // project unwrapped, write out the untouched data
      return data
    }
    
    binaryEncoder.encode(project)
    
    return Data(binaryEncoder.data).compress(withAlgorithm: .lzma)!
  }
  
  
  
  // MARK: -
  // MARK: Binary Encodable support
  
  // used for saving the document, does not save the contained project (that is done seperately with 'projectData')
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(iRASPAProject.classVersionNumber)
    encoder.encode(projectType.rawValue)
    encoder.encode(fileNameUUID)
    encoder.encode(nodeType.rawValue)
    encoder.encode(storageType.rawValue)
    encoder.encode(iRASPAProject.LazyStatus.lazy.rawValue) // set the status to 'lazy'
    
    if(storageType == .publicCloud && projectType == .structure)
    {
      encoder.encode(volumetricSurfaceArea)
      encoder.encode(gravimetricSurfaceArea)
      encoder.encode(heliumVoidFraction)
      encoder.encode(largestOverallCavityDiameter)
      encoder.encode(restrictingPoreDiameter)
      encoder.encode(largestDiameterAlongViablePath)
      encoder.encode(density)
      encoder.encode(mass)
      encoder.encode(specificVolume)
      encoder.encode(accessiblePoreVolume)
      encoder.encode(numberOfChannelSystems)
      encoder.encode(numberOfInaccesiblePockets)
      encoder.encode(dimensionalityPoreSystem)
      encoder.encode(materialType)
    }
  }
  
  // used during loading the document, does not load the project
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let versionNumber: Int = try decoder.decode(Int.self)
    if versionNumber > iRASPAProject.classVersionNumber
    {
      throw iRASPAError.invalidArchiveVersion
    }
    
    guard let readProjectType: ProjectType = ProjectType(rawValue: try decoder.decode(Int64.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.projectType = readProjectType
    self.fileNameUUID = try decoder.decode(String.self)
    guard let nodeType = NodeType(rawValue: try decoder.decode(Int64.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.nodeType = nodeType
    guard let readStorageType: StorageType = StorageType(rawValue: try decoder.decode(Int64.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.storageType = readStorageType
    
    guard let lazyStatus = iRASPAProject.LazyStatus(rawValue: try decoder.decode(Int64.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.lazyStatus = lazyStatus
    
    self.project = ProjectNode(name: "")
    
    if(readStorageType == .publicCloud && readProjectType == .structure)
    {
      volumetricSurfaceArea = try decoder.decode(Double.self)
      gravimetricSurfaceArea = try decoder.decode(Double.self)
      heliumVoidFraction = try decoder.decode(Double.self)
      largestOverallCavityDiameter = try decoder.decode(Double.self)
      restrictingPoreDiameter = try decoder.decode(Double.self)
      largestDiameterAlongViablePath = try decoder.decode(Double.self)
      density = try decoder.decode(Double.self)
      mass = try decoder.decode(Double.self)
      specificVolume = try decoder.decode(Double.self)
      accessiblePoreVolume = try decoder.decode(Double.self)
      numberOfChannelSystems = try decoder.decode(Int.self)
      numberOfInaccesiblePockets = try decoder.decode(Int.self)
      dimensionalityPoreSystem = try decoder.decode(Int.self)
      materialType = try decoder.decode(String.self)
    }
  }
  
  
  public func binaryEncode(to encoder: BinaryEncoder, encodeRepresentedObject: Bool)
  {
    encoder.encode(iRASPAProject.classVersionNumber)
    encoder.encode(projectType.rawValue)
    encoder.encode(fileNameUUID)
    encoder.encode(nodeType.rawValue)
    encoder.encode(storageType.rawValue)
    encoder.encode(lazyStatus.rawValue)
    
    if encodeRepresentedObject
    {
      if lazyStatus == .lazy
      {
        encoder.encode(data ?? Data())
      }
      else
      {
        encoder.encode(project)
      }
    }
  }
  
  
  public init(fromBinary decoder: BinaryDecoder, decodeRepresentedObject: Bool) throws
  {
    let versionNumber: Int = try decoder.decode(Int.self)
    if versionNumber > iRASPAProject.classVersionNumber
    {
      throw iRASPAError.invalidArchiveVersion
    }
    
    guard let readProjectType: ProjectType = ProjectType(rawValue: try decoder.decode(Int64.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.fileNameUUID = try decoder.decode(String.self)
    guard let nodeType = NodeType(rawValue: try decoder.decode(Int64.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.nodeType = nodeType
    guard let readStorageType: StorageType = StorageType(rawValue: try decoder.decode(Int64.self)) else {throw BinaryCodableError.invalidArchiveData}
    guard let readLazyStatus = iRASPAProject.LazyStatus(rawValue: try decoder.decode(Int64.self)) else {throw BinaryCodableError.invalidArchiveData}
    
    self.storageType = readStorageType
    self.projectType = readProjectType
    self.lazyStatus = readLazyStatus
    self.project = ProjectNode(name: "")
    if decodeRepresentedObject
    {
      if readLazyStatus == .lazy
      {
        self.data = try decoder.decode(Data.self)
      }
      else
      {
        switch(readProjectType)
        {
        case .none:
          self.project = try decoder.decode(ProjectNode.self)
        case .generic:
          self.project = try decoder.decode(ProjectNode.self)
        case .group:
          self.project = try decoder.decode(ProjectGroup.self)
        case .structure:
          self.project = try decoder.decode(ProjectStructureNode.self)
        case .VASP:
          self.project = try decoder.decode(ProjectVASPNode.self)
        case .RASPA:
          self.project = try decoder.decode(ProjectRASPANode.self)
        case .GULP:
          self.project = try decoder.decode(ProjectGULPNode.self)
        case .CP2K:
          self.project = try decoder.decode(ProjectCP2KNode.self)
        }
      }
    }
  }
}
