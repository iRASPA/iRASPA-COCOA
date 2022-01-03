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
import iRASPAKit
import UniformTypeIdentifiers

class iRASPADocumentController: NSDocumentController, NSOpenSavePanelDelegate
{
  func panel(_ sender: Any, shouldEnable url: URL) -> Bool
  {
    if url.hasDirectoryPath
    {
      return true
    }
    
    // Handle cases based on file extension
    if #available(OSX 11.0, *)
    {
      if let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
         let type = resourceValues.contentType
      {
        if type.conforms(to: .irspdoc)
        {
          return true
        }
        if type.conforms(to: .iraspa)
        {
          return true
        }
        if type.conforms(to: .cif)
        {
          return true
        }
        if type.conforms(to: .pdb)
        {
          return true
        }
        if type.conforms(to: .xyz)
        {
          return true
        }
        if type.conforms(to: .vtk)
        {
          return true
        }
        if type.conforms(to: .cube)
        {
          return true
        }
      }
    }
    else
    {
      if let resourceValues = try? url.resourceValues(forKeys: [.typeIdentifierKey]),
         let type = resourceValues.typeIdentifier
      {
        if UTTypeConformsTo(type as CFString, typeirspdoc)
        {
          return true
        }
        if UTTypeConformsTo(type as CFString, typeProject)
        {
          return true
        }
        if UTTypeConformsTo(type as CFString, typeCIF)
        {
          return true
        }
        if UTTypeConformsTo(type as CFString, typePDB)
        {
          return true
        }
        if UTTypeConformsTo(type as CFString, typeXYZ)
        {
          return true
        }
        if UTTypeConformsTo(type as CFString, typeVTK)
        {
          return true
        }
        
        if UTTypeConformsTo(type as CFString, typeGAUSSIANCUBE)
        {
          return true
        }
      }
    }
    
    // Handle cases based on file name
    if url.pathExtension.isEmpty && (url.lastPathComponent.uppercased() == "POSCAR" ||
                                     url.lastPathComponent.uppercased() == "CONTCAR" ||
                                     url.lastPathComponent.uppercased() == "CHGCAR" ||
                                     url.lastPathComponent.uppercased() == "LOCPOT" ||
                                     url.lastPathComponent.uppercased() == "ELFCAR" ||
                                     url.lastPathComponent.uppercased() == "XDATCAR")
    {
      return true
    }

    return false
  }
  
  override func beginOpenPanel(_ openPanel: NSOpenPanel, forTypes inTypes: [String]?, completionHandler: @escaping (Int) -> Void)
  {
    openPanel.delegate = self
    super.beginOpenPanel(openPanel, forTypes: inTypes, completionHandler: completionHandler)
  }
}
