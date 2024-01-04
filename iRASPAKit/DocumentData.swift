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

import Foundation
import BinaryCodable
import CloudKit
import SimulationKit

public struct DocumentData: BinaryDecodable, BinaryEncodable
{
  private static var classVersionNumber: Int = 1
  public var projectData: ProjectTreeController
  
  
  // create the "GALLERY", "PROJECTS", "ICLOUD PUBLIC" root-nodes  
  public var projectRootNode: ProjectTreeNode
  {
    return projectData.rootNodes[1]
  }
  
  public var projectLocalRootNode: ProjectTreeNode
  {
    return projectData.rootNodes[1].childNodes[0]
  }
  
  public var galleryRootNode: ProjectTreeNode
  {
    return projectData.rootNodes[0]
  }
  
  public var galleryLocalRootNode: ProjectTreeNode
  {
    return projectData.rootNodes[0].childNodes[0]
  }
  
  public var cloudRootNode: ProjectTreeNode
  {
    return projectData.rootNodes[2]
  }
  
  public var cloudCoREMOFRootNode: ProjectTreeNode
  {
    return projectData.rootNodes[2].childNodes[0].childNodes[0]
  }
  
  public var cloudCoREMOFDDECRootNode: ProjectTreeNode
  {
    return projectData.rootNodes[2].childNodes[0].childNodes[1]
  }
  
  public var cloudCoREMOFASR2019RootNode: ProjectTreeNode
  {
    return projectData.rootNodes[2].childNodes[0].childNodes[2]
  }
  
  public var cloudCoREMOFFSR2019RootNode: ProjectTreeNode
  {
    return projectData.rootNodes[2].childNodes[0].childNodes[3]
  }
  
  public var cloudIZARootNode: ProjectTreeNode
  {
    return projectData.rootNodes[2].childNodes[0].childNodes[4]
  }
  
  public init()
  {
    projectData = ProjectTreeController()
    
    projectLocalRootNode.isExpanded = true
    projectLocalRootNode.isEditable = false
    /*
    let galleryRootNode = ProjectTreeNode(displayName: "GALLERY", representedObject: iRASPAProject.projectGroup(ProjectGroup(name: "GALLERY")))
    let projectRootNode = ProjectTreeNode(displayName: "LOCAL PROJECTS", representedObject: iRASPAProject.projectGroup(ProjectGroup(name: "LOCAL PROJECTS")))
    let cloudRootNode = ProjectTreeNode(displayName: "ICLOUD PUBLIC", representedObject: iRASPAProject.projectGroup(ProjectGroup(name: "ICLOUD PUBLIC")))
    
    galleryRootNode.isEditable = false
    projectRootNode.isEditable = false
    cloudRootNode.isEditable = false
    
    self.projectData.insertNode(galleryRootNode, inItem: nil, atIndex: 0)
    self.projectData.insertNode(projectRootNode, inItem: nil, atIndex: 1)
    self.projectData.insertNode(cloudRootNode, inItem: nil, atIndex: 2)
    
    
    let localGalleryNode: ProjectTreeNode = ProjectTreeNode(displayName: "Gallery", representedObject: iRASPAProject.projectGroup(ProjectGroup(name: "Gallery")))
    self.projectData.insertNode(localGalleryNode, inItem: galleryRootNode, atIndex: 0)
    
    let localMainNode: ProjectTreeNode = ProjectTreeNode(displayName: "Local projects", representedObject: iRASPAProject.projectGroup(ProjectGroup(name: "Local projects")))
    self.projectData.insertNode(localMainNode, inItem: projectRootNode, atIndex: 0)
    
    
    // updated 18-10-2017
    let cloudMainNode: ProjectTreeNode = ProjectTreeNode(displayName: "iCloud public", recordID: CKRecord.ID(recordName: "30089089-3163-633B-62B2-390C63E92789"), representedObject: iRASPAProject.projectGroup(ProjectGroup(name: "iCloud public")))
    self.projectData.insertNode(cloudMainNode, inItem: cloudRootNode, atIndex: 0)
    
    let cloudNodeCoREMOF: ProjectTreeNode = ProjectTreeNode(displayName: "CoRE MOF v1.0", recordID: CKRecord.ID(recordName: "982F3A9C-7B2D-809B-8F9D-852F2F7FB839"), representedObject: iRASPAProject.projectGroup(ProjectGroup(name: "CoRE MOF v1.0")))
    let cloudNodeCoREMOFDDEC: ProjectTreeNode = ProjectTreeNode(displayName: "CoRE MOF v1.0 DDEC", recordID: CKRecord.ID(recordName: "55DEA27F-47C8-81CA-CE43-956EAA1DCF2D"), representedObject: iRASPAProject.projectGroup(ProjectGroup(name: "CoRE MOF v1.0 DDEC")))
    let cloudNodeCoREMOFASR2019: ProjectTreeNode = ProjectTreeNode(displayName: "CoRE MOF ASR 2019", recordID: CKRecord.ID(recordName: "321A2B10-925E-4A70-8E79-80DC9F31F564"), representedObject: iRASPAProject(group: ProjectGroup(name: "CoRE MOF ASR 2019")))
    let cloudNodeCoREMOFFSR2019: ProjectTreeNode = ProjectTreeNode(displayName: "CoRE MOF FSR 2019", recordID: CKRecord.ID(recordName: "D7294935-AA69-49C2-AF63-E0CF70B3BE21"), representedObject: iRASPAProject(group: ProjectGroup(name: "CoRE MOF FSR 2019")))

    let cloudNodeIZA: ProjectTreeNode = ProjectTreeNode(displayName: "IZA Zeolite Topologies", recordID: CKRecord.ID(recordName: "6383111E-4D0E-1675-82F2-E97FEB76FDE4"), representedObject: iRASPAProject.projectGroup(ProjectGroup(name: "IZA Zeolite Topologies")))
    self.projectData.insertNode(cloudNodeCoREMOF, inItem: cloudMainNode, atIndex: 0)
    self.projectData.insertNode(cloudNodeCoREMOFDDEC, inItem: cloudMainNode, atIndex: 1)
    self.projectData.insertNode(cloudNodeCoREMOF2019ASR, inItem: cloudMainNode, atIndex: 2)
    self.projectData.insertNode(cloudNodeCoREMOF2019FSR, inItem: cloudMainNode, atIndex: 3)
    self.projectData.insertNode(cloudNodeIZA, inItem: cloudMainNode, atIndex: 4)
    
    self.galleryRootNode.isExpanded = true
    self.projectRootNode.isExpanded = true
    self.cloudRootNode.isExpanded = true
    self.projectLocalRootNode.isExpanded = true
    
    self.galleryRootNode.isEditable = false
    self.projectRootNode.isEditable = false
    self.cloudRootNode.isEditable = false
    self.projectLocalRootNode.isEditable = false
    cloudMainNode.isEditable = false
    
    self.galleryRootNode.disallowDrag = true
    self.projectRootNode.disallowDrag = true
    self.cloudRootNode.disallowDrag = true
    */
    
    //self.projectOutlineView?.disallowedDragNodes.insert(documentData.galleryRootNode)
    //self.projectOutlineView?.disallowedDragNodes.insert(documentData.projectRootNode)
    //self.projectOutlineView?.disallowedDragNodes.insert(documentData.cloudRootNode)
    
    //return
   
    /*
    // updated 21-10-2017
    // parent: "982F3A9C-7B2D-809B-8F9D-852F2F7FB839"
    let cloudNodeCoREMOFA: ProjectTreeNode = ProjectTreeNode(groupName: "A", recordID: CKRecordID(recordName: "D1E85AC1-D3A5-4299-DBD1-A1290C753CAC"))
    let cloudNodeCoREMOFB: ProjectTreeNode = ProjectTreeNode(groupName: "B", recordID: CKRecordID(recordName: "BF796337-C563-C7F6-051E-57C1C35FEDE0"))
    let cloudNodeCoREMOFC: ProjectTreeNode = ProjectTreeNode(groupName: "C", recordID: CKRecordID(recordName: "06443540-949D-FAA9-B361-9CB84D4F4B79"))
    let cloudNodeCoREMOFD: ProjectTreeNode = ProjectTreeNode(groupName: "D", recordID: CKRecordID(recordName: "59025283-641E-A79A-40BF-A2FD678E6BBC"))
    let cloudNodeCoREMOFE: ProjectTreeNode = ProjectTreeNode(groupName: "E", recordID: CKRecordID(recordName: "9BF83D46-3696-1EEC-CBF1-8B87FB00ECD6"))
    let cloudNodeCoREMOFF: ProjectTreeNode = ProjectTreeNode(groupName: "F", recordID: CKRecordID(recordName: "B3DDDF29-60EF-4227-9869-DF8C5A456C9E"))
    let cloudNodeCoREMOFG: ProjectTreeNode = ProjectTreeNode(groupName: "G", recordID: CKRecordID(recordName: "761ECEF0-B468-E87A-5103-B17C97A964A0"))
    let cloudNodeCoREMOFH: ProjectTreeNode = ProjectTreeNode(groupName: "H", recordID: CKRecordID(recordName: "FC775C78-FBB7-9109-D1B3-E4D29979459C"))
    let cloudNodeCoREMOFI: ProjectTreeNode = ProjectTreeNode(groupName: "I", recordID: CKRecordID(recordName: "EE787B7F-369F-FEA0-43E5-EA599B8077B4"))
    let cloudNodeCoREMOFJ: ProjectTreeNode = ProjectTreeNode(groupName: "J", recordID: CKRecordID(recordName: "DA8A718F-8095-9583-1569-9509BCB35F9B"))
    let cloudNodeCoREMOFK: ProjectTreeNode = ProjectTreeNode(groupName: "K", recordID: CKRecordID(recordName: "0360F0D2-DE94-0CA0-1ED2-AA5D64F84E6B"))
    let cloudNodeCoREMOFL: ProjectTreeNode = ProjectTreeNode(groupName: "L", recordID: CKRecordID(recordName: "8B8BDCC5-383A-A0E1-EDF9-B2C3DF4A6CA1"))
    let cloudNodeCoREMOFM: ProjectTreeNode = ProjectTreeNode(groupName: "M", recordID: CKRecordID(recordName: "E6C3B294-9F53-5FEC-033F-6BF34B6EEB3D"))
    let cloudNodeCoREMOFN: ProjectTreeNode = ProjectTreeNode(groupName: "N", recordID: CKRecordID(recordName: "140CDEDD-3239-62C9-CF3B-31C60D01426F"))
    let cloudNodeCoREMOFO: ProjectTreeNode = ProjectTreeNode(groupName: "O", recordID: CKRecordID(recordName: "9871EE52-FA52-6AF7-C70D-35259ECDD7A7"))
    let cloudNodeCoREMOFP: ProjectTreeNode = ProjectTreeNode(groupName: "P", recordID: CKRecordID(recordName: "36DD90AF-BEBE-4E01-FF5F-3A20C9ECF208"))
    let cloudNodeCoREMOFQ: ProjectTreeNode = ProjectTreeNode(groupName: "Q", recordID: CKRecordID(recordName: "B505FCDA-3A3C-E7FE-EB77-672E07DF45C7"))
    let cloudNodeCoREMOFR: ProjectTreeNode = ProjectTreeNode(groupName: "R", recordID: CKRecordID(recordName: "FC5B12C8-7ECC-1E85-2870-8CC4658FD188"))
    let cloudNodeCoREMOFS: ProjectTreeNode = ProjectTreeNode(groupName: "S", recordID: CKRecordID(recordName: "D0B035D0-49C0-A6C4-147A-BBA9E61B1285"))
    let cloudNodeCoREMOFT: ProjectTreeNode = ProjectTreeNode(groupName: "T", recordID: CKRecordID(recordName: "FB2AED1A-3794-2B44-2F71-07B53304760F"))
    let cloudNodeCoREMOFU: ProjectTreeNode = ProjectTreeNode(groupName: "U", recordID: CKRecordID(recordName: "C1701147-8ABF-6EA5-6939-76464E49DE23"))
    let cloudNodeCoREMOFV: ProjectTreeNode = ProjectTreeNode(groupName: "V", recordID: CKRecordID(recordName: "D64B33F8-911A-D9BC-811D-15D845803EE4"))
    let cloudNodeCoREMOFW: ProjectTreeNode = ProjectTreeNode(groupName: "W", recordID: CKRecordID(recordName: "0758700D-6E30-4D3D-DA91-148DFBCA43E6"))
    let cloudNodeCoREMOFX: ProjectTreeNode = ProjectTreeNode(groupName: "X", recordID: CKRecordID(recordName: "AB8CAB2B-CC2D-ACDF-429C-FF7F6A0F3337"))
    let cloudNodeCoREMOFY: ProjectTreeNode = ProjectTreeNode(groupName: "Y", recordID: CKRecordID(recordName: "CE10ECAC-57D2-458E-B74B-FB88983B3F2A"))
    let cloudNodeCoREMOFZ: ProjectTreeNode = ProjectTreeNode(groupName: "Z", recordID: CKRecordID(recordName: "04A6D421-5B4E-C14F-B12B-A01B65A90F61"))
    
    self.projectData.insertNode(cloudNodeCoREMOFA, inItem: cloudNodeCoREMOF, atIndex: 0)
    self.projectData.insertNode(cloudNodeCoREMOFB, inItem: cloudNodeCoREMOF, atIndex: 1)
    self.projectData.insertNode(cloudNodeCoREMOFC, inItem: cloudNodeCoREMOF, atIndex: 2)
    self.projectData.insertNode(cloudNodeCoREMOFD, inItem: cloudNodeCoREMOF, atIndex: 3)
    self.projectData.insertNode(cloudNodeCoREMOFE, inItem: cloudNodeCoREMOF, atIndex: 4)
    self.projectData.insertNode(cloudNodeCoREMOFF, inItem: cloudNodeCoREMOF, atIndex: 5)
    self.projectData.insertNode(cloudNodeCoREMOFG, inItem: cloudNodeCoREMOF, atIndex: 6)
    self.projectData.insertNode(cloudNodeCoREMOFH, inItem: cloudNodeCoREMOF, atIndex: 7)
    self.projectData.insertNode(cloudNodeCoREMOFI, inItem: cloudNodeCoREMOF, atIndex: 8)
    self.projectData.insertNode(cloudNodeCoREMOFJ, inItem: cloudNodeCoREMOF, atIndex: 9)
    self.projectData.insertNode(cloudNodeCoREMOFK, inItem: cloudNodeCoREMOF, atIndex: 10)
    self.projectData.insertNode(cloudNodeCoREMOFL, inItem: cloudNodeCoREMOF, atIndex: 11)
    self.projectData.insertNode(cloudNodeCoREMOFM, inItem: cloudNodeCoREMOF, atIndex: 12)
    self.projectData.insertNode(cloudNodeCoREMOFN, inItem: cloudNodeCoREMOF, atIndex: 13)
    self.projectData.insertNode(cloudNodeCoREMOFO, inItem: cloudNodeCoREMOF, atIndex: 14)
    self.projectData.insertNode(cloudNodeCoREMOFP, inItem: cloudNodeCoREMOF, atIndex: 15)
    self.projectData.insertNode(cloudNodeCoREMOFQ, inItem: cloudNodeCoREMOF, atIndex: 16)
    self.projectData.insertNode(cloudNodeCoREMOFR, inItem: cloudNodeCoREMOF, atIndex: 17)
    self.projectData.insertNode(cloudNodeCoREMOFS, inItem: cloudNodeCoREMOF, atIndex: 18)
    self.projectData.insertNode(cloudNodeCoREMOFT, inItem: cloudNodeCoREMOF, atIndex: 19)
    self.projectData.insertNode(cloudNodeCoREMOFU, inItem: cloudNodeCoREMOF, atIndex: 20)
    self.projectData.insertNode(cloudNodeCoREMOFV, inItem: cloudNodeCoREMOF, atIndex: 21)
    self.projectData.insertNode(cloudNodeCoREMOFW, inItem: cloudNodeCoREMOF, atIndex: 22)
    self.projectData.insertNode(cloudNodeCoREMOFX, inItem: cloudNodeCoREMOF, atIndex: 23)
    self.projectData.insertNode(cloudNodeCoREMOFY, inItem: cloudNodeCoREMOF, atIndex: 24)
    self.projectData.insertNode(cloudNodeCoREMOFZ, inItem: cloudNodeCoREMOF, atIndex: 25)
    */
    
    /*
    // updated 21-10-2017
    // parent: 55DEA27F-47C8-81CA-CE43-956EAA1DCF2D
    let cloudNodeCoREMOFDDECA: ProjectTreeNode = ProjectTreeNode(groupName: "A", recordID: CKRecordID(recordName: "49B0C70F-2D38-4341-4933-B2CD2A2E5F7D"))
    let cloudNodeCoREMOFDDECB: ProjectTreeNode = ProjectTreeNode(groupName: "B", recordID: CKRecordID(recordName: "75C5A587-1F0D-0C93-6FC5-C9ABCEBE1EC3"))
    let cloudNodeCoREMOFDDECC: ProjectTreeNode = ProjectTreeNode(groupName: "C", recordID: CKRecordID(recordName: "BFC5CBE2-0F7A-32B4-B82C-1D5AE772DF39"))
    let cloudNodeCoREMOFDDECD: ProjectTreeNode = ProjectTreeNode(groupName: "D", recordID: CKRecordID(recordName: "8152C893-3145-8650-D856-F78CC7D5E204"))
    let cloudNodeCoREMOFDDECE: ProjectTreeNode = ProjectTreeNode(groupName: "E", recordID: CKRecordID(recordName: "9A533CA2-3823-9F9B-27DF-3B8815B560DB"))
    let cloudNodeCoREMOFDDECF: ProjectTreeNode = ProjectTreeNode(groupName: "F", recordID: CKRecordID(recordName: "DFBDE839-AC3E-A113-16AA-FABA899FB453"))
    let cloudNodeCoREMOFDDECG: ProjectTreeNode = ProjectTreeNode(groupName: "G", recordID: CKRecordID(recordName: "0B5AA3A4-A64D-9875-CCF1-D64761A04845"))
    let cloudNodeCoREMOFDDECH: ProjectTreeNode = ProjectTreeNode(groupName: "H", recordID: CKRecordID(recordName: "DAFA6672-5789-AD37-8AD8-9B04B7A04A40"))
    let cloudNodeCoREMOFDDECI: ProjectTreeNode = ProjectTreeNode(groupName: "I", recordID: CKRecordID(recordName: "3330BF70-AD20-8414-5F00-44BB1CB9F2F7"))
    let cloudNodeCoREMOFDDECJ: ProjectTreeNode = ProjectTreeNode(groupName: "J", recordID: CKRecordID(recordName: "C4842C18-686A-BF3F-8737-881A7B136576"))
    let cloudNodeCoREMOFDDECK: ProjectTreeNode = ProjectTreeNode(groupName: "K", recordID: CKRecordID(recordName: "2921BAAD-046E-4C46-31FF-2C5B44FF0CA2"))
    let cloudNodeCoREMOFDDECL: ProjectTreeNode = ProjectTreeNode(groupName: "L", recordID: CKRecordID(recordName: "A0797571-C18C-BDF4-1841-989C44B3DBAD"))
    let cloudNodeCoREMOFDDECM: ProjectTreeNode = ProjectTreeNode(groupName: "M", recordID: CKRecordID(recordName: "09B78580-2C73-3975-4398-22CEF1F784FB"))
    let cloudNodeCoREMOFDDECN: ProjectTreeNode = ProjectTreeNode(groupName: "N", recordID: CKRecordID(recordName: "9CAEE5BF-5CE6-DA30-4D8E-B1CC279BACF1"))
    let cloudNodeCoREMOFDDECO: ProjectTreeNode = ProjectTreeNode(groupName: "O", recordID: CKRecordID(recordName: "D8ACB7FC-1B5E-FD3B-CD0A-6A1A19F67005"))
    let cloudNodeCoREMOFDDECP: ProjectTreeNode = ProjectTreeNode(groupName: "P", recordID: CKRecordID(recordName: "16CB8546-8317-4479-6E74-B2DB38258755"))
    let cloudNodeCoREMOFDDECQ: ProjectTreeNode = ProjectTreeNode(groupName: "Q", recordID: CKRecordID(recordName: "56550CFD-579A-CCE4-21FF-A3F4049AFC1A"))
    let cloudNodeCoREMOFDDECR: ProjectTreeNode = ProjectTreeNode(groupName: "R", recordID: CKRecordID(recordName: "3CED1C6B-9F65-3792-4415-7EE1463C2638"))
    let cloudNodeCoREMOFDDECS: ProjectTreeNode = ProjectTreeNode(groupName: "S", recordID: CKRecordID(recordName: "305C04F8-F935-F672-AC3B-EC90D8ABFF73"))
    let cloudNodeCoREMOFDDECT: ProjectTreeNode = ProjectTreeNode(groupName: "T", recordID: CKRecordID(recordName: "198B4C54-59B7-4C40-96DC-A0B540570D76"))
    let cloudNodeCoREMOFDDECU: ProjectTreeNode = ProjectTreeNode(groupName: "U", recordID: CKRecordID(recordName: "F5BBFEB3-DB81-41FD-F4C5-2D6446F57FD6"))
    let cloudNodeCoREMOFDDECV: ProjectTreeNode = ProjectTreeNode(groupName: "V", recordID: CKRecordID(recordName: "D44C69DD-9A6F-6490-190B-23810C217851"))
    let cloudNodeCoREMOFDDECW: ProjectTreeNode = ProjectTreeNode(groupName: "W", recordID: CKRecordID(recordName: "BE4024E6-AF55-FA0E-2E65-8F657F44DA9E"))
    let cloudNodeCoREMOFDDECX: ProjectTreeNode = ProjectTreeNode(groupName: "X", recordID: CKRecordID(recordName: "6D4CD211-0151-CA55-6E89-565CB46D551A"))
    let cloudNodeCoREMOFDDECY: ProjectTreeNode = ProjectTreeNode(groupName: "Y", recordID: CKRecordID(recordName: "A15EEEC3-A9C7-6CC8-41D8-C21BA9DB10DF"))
    let cloudNodeCoREMOFDDECZ: ProjectTreeNode = ProjectTreeNode(groupName: "Z", recordID: CKRecordID(recordName: "E1499235-F564-A352-57F5-59DECFCE09F5"))
    
    self.projectData.insertNode(cloudNodeCoREMOFDDECA, inItem: cloudNodeCoREMOFDDEC, atIndex: 0)
    self.projectData.insertNode(cloudNodeCoREMOFDDECB, inItem: cloudNodeCoREMOFDDEC, atIndex: 1)
    self.projectData.insertNode(cloudNodeCoREMOFDDECC, inItem: cloudNodeCoREMOFDDEC, atIndex: 2)
    self.projectData.insertNode(cloudNodeCoREMOFDDECD, inItem: cloudNodeCoREMOFDDEC, atIndex: 3)
    self.projectData.insertNode(cloudNodeCoREMOFDDECE, inItem: cloudNodeCoREMOFDDEC, atIndex: 4)
    self.projectData.insertNode(cloudNodeCoREMOFDDECF, inItem: cloudNodeCoREMOFDDEC, atIndex: 5)
    self.projectData.insertNode(cloudNodeCoREMOFDDECG, inItem: cloudNodeCoREMOFDDEC, atIndex: 6)
    self.projectData.insertNode(cloudNodeCoREMOFDDECH, inItem: cloudNodeCoREMOFDDEC, atIndex: 7)
    self.projectData.insertNode(cloudNodeCoREMOFDDECI, inItem: cloudNodeCoREMOFDDEC, atIndex: 8)
    self.projectData.insertNode(cloudNodeCoREMOFDDECJ, inItem: cloudNodeCoREMOFDDEC, atIndex: 9)
    self.projectData.insertNode(cloudNodeCoREMOFDDECK, inItem: cloudNodeCoREMOFDDEC, atIndex: 10)
    self.projectData.insertNode(cloudNodeCoREMOFDDECL, inItem: cloudNodeCoREMOFDDEC, atIndex: 11)
    self.projectData.insertNode(cloudNodeCoREMOFDDECM, inItem: cloudNodeCoREMOFDDEC, atIndex: 12)
    self.projectData.insertNode(cloudNodeCoREMOFDDECN, inItem: cloudNodeCoREMOFDDEC, atIndex: 13)
    self.projectData.insertNode(cloudNodeCoREMOFDDECO, inItem: cloudNodeCoREMOFDDEC, atIndex: 14)
    self.projectData.insertNode(cloudNodeCoREMOFDDECP, inItem: cloudNodeCoREMOFDDEC, atIndex: 15)
    self.projectData.insertNode(cloudNodeCoREMOFDDECQ, inItem: cloudNodeCoREMOFDDEC, atIndex: 16)
    self.projectData.insertNode(cloudNodeCoREMOFDDECR, inItem: cloudNodeCoREMOFDDEC, atIndex: 17)
    self.projectData.insertNode(cloudNodeCoREMOFDDECS, inItem: cloudNodeCoREMOFDDEC, atIndex: 18)
    self.projectData.insertNode(cloudNodeCoREMOFDDECT, inItem: cloudNodeCoREMOFDDEC, atIndex: 19)
    self.projectData.insertNode(cloudNodeCoREMOFDDECU, inItem: cloudNodeCoREMOFDDEC, atIndex: 20)
    self.projectData.insertNode(cloudNodeCoREMOFDDECV, inItem: cloudNodeCoREMOFDDEC, atIndex: 21)
    self.projectData.insertNode(cloudNodeCoREMOFDDECW, inItem: cloudNodeCoREMOFDDEC, atIndex: 22)
    self.projectData.insertNode(cloudNodeCoREMOFDDECX, inItem: cloudNodeCoREMOFDDEC, atIndex: 23)
    self.projectData.insertNode(cloudNodeCoREMOFDDECY, inItem: cloudNodeCoREMOFDDEC, atIndex: 24)
    self.projectData.insertNode(cloudNodeCoREMOFDDECZ, inItem: cloudNodeCoREMOFDDEC, atIndex: 25)
    */
    
    /*
    // updated 18-10-2017
    // parent = "6383111E-4D0E-1675-82F2-E97FEB76FDE4"
    let cloudNodeIZAA: ProjectTreeNode = ProjectTreeNode(groupName: "A", recordID: CKRecordID(recordName: "CC3D8689-29E8-BFED-FA9C-D433032ADBB4"))
    let cloudNodeIZAB: ProjectTreeNode = ProjectTreeNode(groupName: "B", recordID: CKRecordID(recordName: "FAD07991-6E0E-87AA-AC52-B3EBA5ECE86B"))
    let cloudNodeIZAC: ProjectTreeNode = ProjectTreeNode(groupName: "C", recordID: CKRecordID(recordName: "FB8FFB9B-3898-0710-DBC6-C5AB760A1E50"))
    let cloudNodeIZAD: ProjectTreeNode = ProjectTreeNode(groupName: "D", recordID: CKRecordID(recordName: "8E439D05-172B-EB0A-80E3-CC84E343974F"))
    let cloudNodeIZAE: ProjectTreeNode = ProjectTreeNode(groupName: "E", recordID: CKRecordID(recordName: "4AD3DB6C-69E3-11FB-778A-486A9E4B6CD1"))
    let cloudNodeIZAF: ProjectTreeNode = ProjectTreeNode(groupName: "F", recordID: CKRecordID(recordName: "6EEA3CD0-2B53-44EF-3DA5-7E07B9F4A628"))
    let cloudNodeIZAG: ProjectTreeNode = ProjectTreeNode(groupName: "G", recordID: CKRecordID(recordName: "ACA55E1D-2DE5-44CB-F6E8-DAB66660D073"))
    let cloudNodeIZAH: ProjectTreeNode = ProjectTreeNode(groupName: "H", recordID: CKRecordID(recordName: "9BBADA0C-97D0-C7F4-346D-F5DDA0C77211"))
    let cloudNodeIZAI: ProjectTreeNode = ProjectTreeNode(groupName: "I", recordID: CKRecordID(recordName: "B6759F3B-DA84-32B5-52EB-2D4B6BC7C29B"))
    let cloudNodeIZAJ: ProjectTreeNode = ProjectTreeNode(groupName: "J", recordID: CKRecordID(recordName: "C87E21E1-561F-61A8-FEE2-C01E5E4EE3F5"))
    let cloudNodeIZAK: ProjectTreeNode = ProjectTreeNode(groupName: "K", recordID: CKRecordID(recordName: "884B25AF-0B66-1019-EE59-C09745AAE7AB"))
    let cloudNodeIZAL: ProjectTreeNode = ProjectTreeNode(groupName: "L", recordID: CKRecordID(recordName: "26CBA0B7-239F-AFD5-FFFB-B4FECA88BA70"))
    let cloudNodeIZAM: ProjectTreeNode = ProjectTreeNode(groupName: "M", recordID: CKRecordID(recordName: "F3C4B89C-9CCA-16C5-3936-6584BE716210"))
    let cloudNodeIZAN: ProjectTreeNode = ProjectTreeNode(groupName: "N", recordID: CKRecordID(recordName: "F27C6240-9219-C780-D51C-D7F7BFF8C440"))
    let cloudNodeIZAO: ProjectTreeNode = ProjectTreeNode(groupName: "O", recordID: CKRecordID(recordName: "62692216-C181-5A8C-6585-00E752F774F3"))
    let cloudNodeIZAP: ProjectTreeNode = ProjectTreeNode(groupName: "P", recordID: CKRecordID(recordName: "A2C881C6-957F-9506-8357-9E499E645979"))
    let cloudNodeIZAQ: ProjectTreeNode = ProjectTreeNode(groupName: "Q", recordID: CKRecordID(recordName: "767A6F62-4106-A26A-3B92-606124388B77"))
    let cloudNodeIZAR: ProjectTreeNode = ProjectTreeNode(groupName: "R", recordID: CKRecordID(recordName: "D0A14551-D3F3-5BD0-DDDA-4522AEEAE4BF"))
    let cloudNodeIZAS: ProjectTreeNode = ProjectTreeNode(groupName: "S", recordID: CKRecordID(recordName: "195C15BE-4B35-6433-F1DA-B39C5B8F640C"))
    let cloudNodeIZAT: ProjectTreeNode = ProjectTreeNode(groupName: "T", recordID: CKRecordID(recordName: "514393DA-14C6-F614-265A-A126E5A18B16"))
    let cloudNodeIZAU: ProjectTreeNode = ProjectTreeNode(groupName: "U", recordID: CKRecordID(recordName: "977560B2-893D-C82B-DE90-DB09E423397F"))
    let cloudNodeIZAV: ProjectTreeNode = ProjectTreeNode(groupName: "V", recordID: CKRecordID(recordName: "67C86F37-7E79-D2A2-5B61-BC968F1AE718"))
    let cloudNodeIZAW: ProjectTreeNode = ProjectTreeNode(groupName: "W", recordID: CKRecordID(recordName: "BF1A3FEA-5B2D-C3DB-62AF-0682EB815317"))
    let cloudNodeIZAX: ProjectTreeNode = ProjectTreeNode(groupName: "X", recordID: CKRecordID(recordName: "5B0AECE3-5932-EFF6-5B0B-CB2F9429CDA1"))
    let cloudNodeIZAY: ProjectTreeNode = ProjectTreeNode(groupName: "Y", recordID: CKRecordID(recordName: "2EFE59C1-F85D-0ED7-3C13-5E5741312CE7"))
    let cloudNodeIZAZ: ProjectTreeNode = ProjectTreeNode(groupName: "Z", recordID: CKRecordID(recordName: "D65723E2-D9C2-FD2B-9D93-3C8B973D2ED8"))
    
    self.projectData.insertNode(cloudNodeIZAA, inItem: cloudNodeIZA, atIndex: 0)
    self.projectData.insertNode(cloudNodeIZAB, inItem: cloudNodeIZA, atIndex: 1)
    self.projectData.insertNode(cloudNodeIZAC, inItem: cloudNodeIZA, atIndex: 2)
    self.projectData.insertNode(cloudNodeIZAD, inItem: cloudNodeIZA, atIndex: 3)
    self.projectData.insertNode(cloudNodeIZAE, inItem: cloudNodeIZA, atIndex: 4)
    self.projectData.insertNode(cloudNodeIZAF, inItem: cloudNodeIZA, atIndex: 5)
    self.projectData.insertNode(cloudNodeIZAG, inItem: cloudNodeIZA, atIndex: 6)
    self.projectData.insertNode(cloudNodeIZAH, inItem: cloudNodeIZA, atIndex: 7)
    self.projectData.insertNode(cloudNodeIZAI, inItem: cloudNodeIZA, atIndex: 8)
    self.projectData.insertNode(cloudNodeIZAJ, inItem: cloudNodeIZA, atIndex: 9)
    self.projectData.insertNode(cloudNodeIZAK, inItem: cloudNodeIZA, atIndex: 10)
    self.projectData.insertNode(cloudNodeIZAL, inItem: cloudNodeIZA, atIndex: 11)
    self.projectData.insertNode(cloudNodeIZAM, inItem: cloudNodeIZA, atIndex: 12)
    self.projectData.insertNode(cloudNodeIZAN, inItem: cloudNodeIZA, atIndex: 13)
    self.projectData.insertNode(cloudNodeIZAO, inItem: cloudNodeIZA, atIndex: 14)
    self.projectData.insertNode(cloudNodeIZAP, inItem: cloudNodeIZA, atIndex: 15)
    self.projectData.insertNode(cloudNodeIZAQ, inItem: cloudNodeIZA, atIndex: 16)
    self.projectData.insertNode(cloudNodeIZAR, inItem: cloudNodeIZA, atIndex: 17)
    self.projectData.insertNode(cloudNodeIZAS, inItem: cloudNodeIZA, atIndex: 18)
    self.projectData.insertNode(cloudNodeIZAT, inItem: cloudNodeIZA, atIndex: 19)
    self.projectData.insertNode(cloudNodeIZAU, inItem: cloudNodeIZA, atIndex: 20)
    self.projectData.insertNode(cloudNodeIZAV, inItem: cloudNodeIZA, atIndex: 21)
    self.projectData.insertNode(cloudNodeIZAW, inItem: cloudNodeIZA, atIndex: 22)
    self.projectData.insertNode(cloudNodeIZAX, inItem: cloudNodeIZA, atIndex: 23)
    self.projectData.insertNode(cloudNodeIZAY, inItem: cloudNodeIZA, atIndex: 24)
    self.projectData.insertNode(cloudNodeIZAZ, inItem: cloudNodeIZA, atIndex: 25)
 */
    
    //let cloudNodeCoREMOFASR2019: ProjectTreeNode = ProjectTreeNode(displayName: "CoRE MOF ASR 2019", recordID: CKRecord.ID(recordName: "321A2B10-925E-4A70-8E79-80DC9F31F564"), representedObject: iRASPAProject(group: ProjectGroup(name: "CoRE MOF ASR 2019")))
    
    // parent = "321A2B10-925E-4A70-8E79-80DC9F31F564"
    //let cloudNodeCoREMOFASR2019A: ProjectTreeNode = ProjectTreeNode(groupName: "A", recordID: CKRecord.ID(recordName: "3FAA46DF-9DE0-443A-92CC-02536408CB53"))
    //let cloudNodeCoREMOFASR2019B: ProjectTreeNode = ProjectTreeNode(groupName: "B", recordID: CKRecord.ID(recordName: "BFC60411-9B7F-4C34-AFEC-5E631D727AFF"))
    //let cloudNodeCoREMOFASR2019C: ProjectTreeNode = ProjectTreeNode(groupName: "C", recordID: CKRecord.ID(recordName: "8A4387B9-2B57-4364-8968-B10F52056BA2"))
    //let cloudNodeCoREMOFASR2019D: ProjectTreeNode = ProjectTreeNode(groupName: "D", recordID: CKRecord.ID(recordName: "76EF4659-03D5-4935-BCB2-F8E8A330808E"))
    //let cloudNodeCoREMOFASR2019E: ProjectTreeNode = ProjectTreeNode(groupName: "E", recordID: CKRecord.ID(recordName: "59A052B0-0F7D-4841-9E26-6FD87D98E868"))
    //let cloudNodeCoREMOFASR2019F: ProjectTreeNode = ProjectTreeNode(groupName: "F", recordID: CKRecord.ID(recordName: "991DAF6A-CD12-49B6-A87F-C9A5707FEE61"))
    //let cloudNodeCoREMOFASR2019G: ProjectTreeNode = ProjectTreeNode(groupName: "G", recordID: CKRecord.ID(recordName: "2F0A44D0-0455-4A8C-8E3D-99B5F70739D1"))
    //let cloudNodeCoREMOFASR2019H: ProjectTreeNode = ProjectTreeNode(groupName: "H", recordID: CKRecord.ID(recordName: "4F7E576F-4D8C-440D-8BC9-FD4BA1C213AD"))
    //let cloudNodeCoREMOFASR2019I: ProjectTreeNode = ProjectTreeNode(groupName: "I", recordID: CKRecord.ID(recordName: "2319F5FD-30A1-474E-9074-9FA59D431E69"))
    //let cloudNodeCoREMOFASR2019J: ProjectTreeNode = ProjectTreeNode(groupName: "J", recordID: CKRecord.ID(recordName: "374BAA03-14A1-4BDF-89C4-7B9D9496364A"))
    //let cloudNodeCoREMOFASR2019K: ProjectTreeNode = ProjectTreeNode(groupName: "K", recordID: CKRecord.ID(recordName: "1C516215-9A68-42F1-A9A7-A9AC40F08546"))
    //let cloudNodeCoREMOFASR2019L: ProjectTreeNode = ProjectTreeNode(groupName: "L", recordID: CKRecord.ID(recordName: "EA3CBD0A-EC0F-475F-9BD3-137B7F7B22C5"))
    //let cloudNodeCoREMOFASR2019M: ProjectTreeNode = ProjectTreeNode(groupName: "M", recordID: CKRecord.ID(recordName: "45CF796D-9417-4073-ABC8-BF7F99FE597B"))
    //let cloudNodeCoREMOFASR2019N: ProjectTreeNode = ProjectTreeNode(groupName: "N", recordID: CKRecord.ID(recordName: "FEDE83F3-3B39-4431-85ED-373B2013E6DD"))
    //let cloudNodeCoREMOFASR2019O: ProjectTreeNode = ProjectTreeNode(groupName: "O", recordID: CKRecord.ID(recordName: "D9A7B326-9A30-41A0-9E5E-AB5200D31474"))
    //let cloudNodeCoREMOFASR2019P: ProjectTreeNode = ProjectTreeNode(groupName: "P", recordID: CKRecord.ID(recordName: "CB364FFC-FF65-4BD8-A87C-C46FF0C22E8D"))
    //let cloudNodeCoREMOFASR2019Q: ProjectTreeNode = ProjectTreeNode(groupName: "Q", recordID: CKRecord.ID(recordName: "28815ACF-B9A8-4D36-99A0-7814656174F9"))
    //let cloudNodeCoREMOFASR2019R: ProjectTreeNode = ProjectTreeNode(groupName: "R", recordID: CKRecord.ID(recordName: "A6E585F5-9FE0-421A-BB7D-F518C20C9C94"))
    //let cloudNodeCoREMOFASR2019S: ProjectTreeNode = ProjectTreeNode(groupName: "S", recordID: CKRecord.ID(recordName: "65F44D5A-450C-437C-9395-D47C1FFF9FBE"))
    //let cloudNodeCoREMOFASR2019T: ProjectTreeNode = ProjectTreeNode(groupName: "T", recordID: CKRecord.ID(recordName: "385BBD11-884B-4117-BB84-D5D13BEECBE9"))
    //let cloudNodeCoREMOFASR2019U: ProjectTreeNode = ProjectTreeNode(groupName: "U", recordID: CKRecord.ID(recordName: "7A7F6407-7CB0-4E37-8341-FFCC8CA0B749"))
    //let cloudNodeCoREMOFASR2019V: ProjectTreeNode = ProjectTreeNode(groupName: "V", recordID: CKRecord.ID(recordName: "83DE6320-4104-4D8A-93F5-732DA12B95EC"))
    //let cloudNodeCoREMOFASR2019W: ProjectTreeNode = ProjectTreeNode(groupName: "W", recordID: CKRecord.ID(recordName: "76F77079-A1E1-4152-944F-50AB57123272"))
    //let cloudNodeCoREMOFASR2019X: ProjectTreeNode = ProjectTreeNode(groupName: "X", recordID: CKRecord.ID(recordName: "319D867E-42B4-4006-B829-0E895145841E"))
    //let cloudNodeCoREMOFASR2019Y: ProjectTreeNode = ProjectTreeNode(groupName: "Y", recordID: CKRecord.ID(recordName: "C7887803-2E13-42BF-908E-B31F041A6588"))
    //let cloudNodeCoREMOFASR2019Z: ProjectTreeNode = ProjectTreeNode(groupName: "Z", recordID: CKRecord.ID(recordName: "13CFD52C-D25E-4225-AEA3-7EA0BD359A44"))
    //
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019A, inItem: cloudCoREMOFASR2019RootNode, atIndex: 0)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019B, inItem: cloudCoREMOFASR2019RootNode, atIndex: 1)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019C, inItem: cloudCoREMOFASR2019RootNode, atIndex: 2)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019D, inItem: cloudCoREMOFASR2019RootNode, atIndex: 3)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019E, inItem: cloudCoREMOFASR2019RootNode, atIndex: 4)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019F, inItem: cloudCoREMOFASR2019RootNode, atIndex: 5)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019G, inItem: cloudCoREMOFASR2019RootNode, atIndex: 6)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019H, inItem: cloudCoREMOFASR2019RootNode, atIndex: 7)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019I, inItem: cloudCoREMOFASR2019RootNode, atIndex: 8)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019J, inItem: cloudCoREMOFASR2019RootNode, atIndex: 9)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019K, inItem: cloudCoREMOFASR2019RootNode, atIndex: 10)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019L, inItem: cloudCoREMOFASR2019RootNode, atIndex: 11)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019M, inItem: cloudCoREMOFASR2019RootNode, atIndex: 12)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019N, inItem: cloudCoREMOFASR2019RootNode, atIndex: 13)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019O, inItem: cloudCoREMOFASR2019RootNode, atIndex: 14)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019P, inItem: cloudCoREMOFASR2019RootNode, atIndex: 15)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019Q, inItem: cloudCoREMOFASR2019RootNode, atIndex: 16)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019R, inItem: cloudCoREMOFASR2019RootNode, atIndex: 17)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019S, inItem: cloudCoREMOFASR2019RootNode, atIndex: 18)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019T, inItem: cloudCoREMOFASR2019RootNode, atIndex: 19)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019U, inItem: cloudCoREMOFASR2019RootNode, atIndex: 20)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019V, inItem: cloudCoREMOFASR2019RootNode, atIndex: 21)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019W, inItem: cloudCoREMOFASR2019RootNode, atIndex: 22)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019X, inItem: cloudCoREMOFASR2019RootNode, atIndex: 23)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019Y, inItem: cloudCoREMOFASR2019RootNode, atIndex: 24)
    //self.projectData.insertNode(cloudNodeCoREMOFASR2019Z, inItem: cloudCoREMOFASR2019RootNode, atIndex: 25)
    
    
    //let cloudNodeCoREMOFFSR2019: ProjectTreeNode = ProjectTreeNode(displayName: "CoRE MOF FSR 2019", recordID: CKRecord.ID(recordName: "D7294935-AA69-49C2-AF63-E0CF70B3BE21"), representedObject: iRASPAProject(group: ProjectGroup(name: "CoRE MOF FSR 2019")))
    
    // parent = "D7294935-AA69-49C2-AF63-E0CF70B3BE21"
    //let cloudNodeCoREMOFFSR2019A: ProjectTreeNode = ProjectTreeNode(groupName: "A", recordID: CKRecord.ID(recordName: "4A199FF3-5336-4A96-B763-42CCE882F1D0"))
    //let cloudNodeCoREMOFFSR2019B: ProjectTreeNode = ProjectTreeNode(groupName: "B", recordID: CKRecord.ID(recordName: "2BABFDFE-D205-4580-BED7-F229D636BDBA"))
    //let cloudNodeCoREMOFFSR2019C: ProjectTreeNode = ProjectTreeNode(groupName: "C", recordID: CKRecord.ID(recordName: "32909546-0947-4C5D-B4D2-3B36F740515F"))
    //let cloudNodeCoREMOFFSR2019D: ProjectTreeNode = ProjectTreeNode(groupName: "D", recordID: CKRecord.ID(recordName: "1E2BF363-B019-42A8-BFA5-C05BB67BDCA2"))
    //let cloudNodeCoREMOFFSR2019E: ProjectTreeNode = ProjectTreeNode(groupName: "E", recordID: CKRecord.ID(recordName: "0B187B1C-D36B-4E9E-856C-E4F8A9BC5509"))
    //let cloudNodeCoREMOFFSR2019F: ProjectTreeNode = ProjectTreeNode(groupName: "F", recordID: CKRecord.ID(recordName: "9343D394-4C6B-42E4-83C1-00D1A45898E9"))
    //let cloudNodeCoREMOFFSR2019G: ProjectTreeNode = ProjectTreeNode(groupName: "G", recordID: CKRecord.ID(recordName: "C7B061D9-67D4-4956-A4AA-42CAABA5DF40"))
    //let cloudNodeCoREMOFFSR2019H: ProjectTreeNode = ProjectTreeNode(groupName: "H", recordID: CKRecord.ID(recordName: "1D834D98-2D64-45A5-8E37-C495EF8FC87F"))
    //let cloudNodeCoREMOFFSR2019I: ProjectTreeNode = ProjectTreeNode(groupName: "I", recordID: CKRecord.ID(recordName: "256B0B8E-399F-475A-AD9D-222EB410281A"))
    //let cloudNodeCoREMOFFSR2019J: ProjectTreeNode = ProjectTreeNode(groupName: "J", recordID: CKRecord.ID(recordName: "9185E877-DE5D-4A54-8A97-41ED98CDFA5C"))
    //let cloudNodeCoREMOFFSR2019K: ProjectTreeNode = ProjectTreeNode(groupName: "K", recordID: CKRecord.ID(recordName: "3EAED72F-912A-4FE7-94B7-814891C657CD"))
    //let cloudNodeCoREMOFFSR2019L: ProjectTreeNode = ProjectTreeNode(groupName: "L", recordID: CKRecord.ID(recordName: "BCDCDBD8-B44E-4972-B9A3-BC1160AB4751"))
    //let cloudNodeCoREMOFFSR2019M: ProjectTreeNode = ProjectTreeNode(groupName: "M", recordID: CKRecord.ID(recordName: "C55F9FE4-D50A-480E-BF33-106832B09217"))
    //let cloudNodeCoREMOFFSR2019N: ProjectTreeNode = ProjectTreeNode(groupName: "N", recordID: CKRecord.ID(recordName: "1D9063B1-B373-430F-8A03-1BEDD26B72D9"))
    //let cloudNodeCoREMOFFSR2019O: ProjectTreeNode = ProjectTreeNode(groupName: "O", recordID: CKRecord.ID(recordName: "EB7D0DC2-814B-4BBF-A87A-40ECAAF33911"))
    //let cloudNodeCoREMOFFSR2019P: ProjectTreeNode = ProjectTreeNode(groupName: "P", recordID: CKRecord.ID(recordName: "FFAF097E-4A81-4B45-A678-A8593ACC31E6"))
    //let cloudNodeCoREMOFFSR2019Q: ProjectTreeNode = ProjectTreeNode(groupName: "Q", recordID: CKRecord.ID(recordName: "0D4FC748-7B67-4E69-B242-220028334C8E"))
    //let cloudNodeCoREMOFFSR2019R: ProjectTreeNode = ProjectTreeNode(groupName: "R", recordID: CKRecord.ID(recordName: "A99A8987-AD12-45A7-899D-3AD3AAEB87BC"))
    //let cloudNodeCoREMOFFSR2019S: ProjectTreeNode = ProjectTreeNode(groupName: "S", recordID: CKRecord.ID(recordName: "E5391B6E-774B-40D8-ADC8-4F040DCDDF24"))
    //let cloudNodeCoREMOFFSR2019T: ProjectTreeNode = ProjectTreeNode(groupName: "T", recordID: CKRecord.ID(recordName: "22086B7E-EF68-49B6-9B4D-4D3B62446EE1"))
    //let cloudNodeCoREMOFFSR2019U: ProjectTreeNode = ProjectTreeNode(groupName: "U", recordID: CKRecord.ID(recordName: "B8225614-967C-4632-8ACA-481657B8BCB7"))
    //let cloudNodeCoREMOFFSR2019V: ProjectTreeNode = ProjectTreeNode(groupName: "V", recordID: CKRecord.ID(recordName: "1A3D1AD5-C460-464B-9212-9E70676EC03D"))
    //let cloudNodeCoREMOFFSR2019W: ProjectTreeNode = ProjectTreeNode(groupName: "W", recordID: CKRecord.ID(recordName: "9FAF6962-A523-4E01-A999-734A834664DE"))
    //let cloudNodeCoREMOFFSR2019X: ProjectTreeNode = ProjectTreeNode(groupName: "X", recordID: CKRecord.ID(recordName: "328DF9DF-0CD9-4BB5-B316-8E384F729728"))
    //let cloudNodeCoREMOFFSR2019Y: ProjectTreeNode = ProjectTreeNode(groupName: "Y", recordID: CKRecord.ID(recordName: "0E75F972-C746-47EA-8477-CC4D1EC122DD"))
    //let cloudNodeCoREMOFFSR2019Z: ProjectTreeNode = ProjectTreeNode(groupName: "Z", recordID: CKRecord.ID(recordName: "2D1E4F51-CE18-49F7-A2D3-A88775126165"))
    //
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019A, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 0)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019B, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 1)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019C, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 2)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019D, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 3)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019E, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 4)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019F, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 5)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019G, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 6)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019H, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 7)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019I, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 8)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019J, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 9)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019K, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 10)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019L, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 11)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019M, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 12)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019N, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 13)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019O, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 14)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019P, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 15)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019Q, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 16)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019R, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 17)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019S, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 18)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019T, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 19)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019U, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 20)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019V, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 21)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019W, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 22)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019X, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 23)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019Y, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 24)
    //self.projectData.insertNode(cloudNodeCoREMOFFSR2019Z, inItem: cloudCoREMOFFSR2019RootNode, atIndex: 25)
  }

  // MARK: -
  // MARK: Binary Encodable support

  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(DocumentData.classVersionNumber)
    encoder.encode(self.projectData)
    encoder.encode(Int(0x6f6b6179))
  }

  // MARK: -
  // MARK: Binary Decodable support
  
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let versionNumber: Int = try decoder.decode(Int.self)
    if versionNumber > DocumentData.classVersionNumber
    {
      throw iRASPAError.invalidArchiveVersion
    }
    
    projectData = try decoder.decode(ProjectTreeController.self)
    let magicNumber = try decoder.decode(Int.self)
    if magicNumber != Int(0x6f6b6179)
    {
      debugPrint("Inconsistency error (bug)")
    }
  }

}
