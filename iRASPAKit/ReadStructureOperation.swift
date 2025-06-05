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
import SymmetryKit
import OperationKit
import LogViewKit
import BinaryCodable

class ReadStructureOperation: FKOperation, @unchecked Sendable
{
  let url: URL
  var parser: SKParser? = nil
  unowned var projectTreeNode : ProjectTreeNode
  let windowController: NSWindowController?
  
  public init(ProjectTreeNode : ProjectTreeNode, url: URL, windowController: NSWindowController?, onlyAsymmetricUnit: Bool, asMolecule: Bool) throws
  {
    self.windowController = windowController
    self.url = url
    self.projectTreeNode = ProjectTreeNode
    super.init()
    
    // create a new Progress-object (Progress-objects can not be resused)
    progress = Progress.discreteProgress(totalUnitCount: Int64(100))
    progress.completedUnitCount = 0
        
    let displayName: String = (url.lastPathComponent as NSString).deletingPathExtension
    
    let data: Data = try Data(contentsOf: self.url)
    
    let fileName = url.lastPathComponent.uppercased()
    switch(url.pathExtension.uppercased())
    {
    case "CIF":
      parser = try SKCIFParser(displayName: displayName, data: data, onlyAsymmetricUnit: onlyAsymmetricUnit)
    case "PDB":
      parser = try SKPDBParser(displayName: displayName, data: data, onlyAsymmetricUnitMolecule: onlyAsymmetricUnit, asMolecule: asMolecule, asProtein: asMolecule)
    case "XYZ":
      parser = try SKXYZParser(displayName: displayName, data: data)
    case "POSCAR", "CONTCAR":
      parser = try SKVASPPOSCARParser(displayName: displayName, data: data)
    case "VTK":
      parser = try SKVTKParser(displayName: displayName, data: data)
    case "CUBE":
      parser = try SKGaussianCubeParser(displayName: displayName, data: data)
    case "":
      if fileName == "POSCAR" || fileName == "CONTCAR"
      {
        parser = try SKVASPPOSCARParser(displayName: displayName, data: data)
      }
      else if fileName == "CHGCAR"
      {
        parser = try SKVASPCHGCARParser(displayName: displayName, data: data)
      }
      else if fileName == "LOCPOT"
      {
        parser = try SKVASPLOCPOTParser(displayName: displayName, data: data)
      }
      else if fileName == "ELFCAR"
      {
        parser = try SKVASPELFCARParser(displayName: displayName, data: data)
      }
      else if fileName == "XDATCAR"
      {
        parser = try SKVASPXDATCARParser(displayName: displayName, data: data)
      }
    default:
      throw BinaryCodableError.unsupportedFileType
    }
  }
  
  override func execute()
  {
    if self.isCancelled
    {
      return
    }
    
    do
    {
      try parser?.startParsing()
    }
    catch
    {
      parser = nil
      return
    }
    
    
    
    self.progress.completedUnitCount = 100
    
    finishWithError(nil)
  }
}
