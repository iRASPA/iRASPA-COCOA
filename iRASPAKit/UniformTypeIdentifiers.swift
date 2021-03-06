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

import UniformTypeIdentifiers

@available(OSX 11.0, *)
extension UTType
{
  public static let irspdoc : UTType = UTType(exportedAs: "nl.darkwing.iraspa.universal.irspdoc")
  
  public static let iraspa : UTType = UTType(exportedAs: "nl.darkwing.iraspa.iraspa")
 
  public static var cif : UTType
  {
    return UTType(importedAs: "net.sourceforge.openbabel.cif")
  }
  
  public static var pdb : UTType
  {
    return UTType(importedAs: "net.sourceforge.openbabel.pdb")
  }
  
  public static var xyz : UTType
  {
    return UTType(importedAs: "net.sourceforge.openbabel.xyz")
  }
  
  public static var poscar : UTType
  {
    return UTType(importedAs: "net.sourceforge.openbabel.poscar")
  }
}


let iRASPAProjectUTI: String = "nl.darkwing.iraspa.iraspa"
public let typeirspdoc: CFString = (UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "irspdoc" as CFString, kUTTypeData)?.takeRetainedValue())!
public let typeCIF: CFString = (UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "cif" as CFString, kUTTypeData)?.takeRetainedValue())!
public let typePDB: CFString = (UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "pdb" as CFString, kUTTypeData)?.takeRetainedValue())!
public let typeXYZ: CFString = (UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "xyz" as CFString, kUTTypeData)?.takeRetainedValue())!
public let typePOSCAR: CFString = (UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "poscar" as CFString, kUTTypeData)?.takeRetainedValue())!
public let typeProject: CFString = (UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, "iraspa" as CFString, kUTTypeData)?.takeRetainedValue())!
  
