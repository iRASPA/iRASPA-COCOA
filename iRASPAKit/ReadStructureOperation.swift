/*************************************************************************************************************
 The MIT License
 
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

import Foundation
import SymmetryKit
import OperationKit

class ReadStructureOperation: FKOperation
{
  let url: URL
  var parser: SKParser? = nil
  unowned var projectTreeNode : ProjectTreeNode
  let windowController: NSWindowController?
  
  public init(ProjectTreeNode : ProjectTreeNode, url: URL, windowController: NSWindowController?, onlyAsymmetricUnit: Bool)
  {
    self.windowController = windowController
    self.url = url
    self.projectTreeNode = ProjectTreeNode
    super.init()
    
    // create a new Progress-object (Progress-objects can not be resused)
    progress = Progress.discreteProgress(totalUnitCount: Int64(100))
    progress.completedUnitCount = 0
    
    
    let displayName: String = (url.lastPathComponent as NSString).deletingPathExtension
    
    let string: String
    do
    {
      string = try String(contentsOf: self.url, encoding: String.Encoding.utf8)
    }
    catch
    {
      return
    }


    let fileName = url.lastPathComponent.lowercased()
    switch(url.pathExtension.lowercased())
    {
    case "cif":
      parser = SKCIFParser(displayName: displayName, string: string, windowController: nil, onlyAsymmetricUnit: onlyAsymmetricUnit)
     // parser?.scene.displayName = displayName
    case "pdb":
      parser = SKPDBParser(displayName: displayName, string: string, windowController: nil, onlyAsymmetricUnit: onlyAsymmetricUnit)
     // parser?.scene.displayName = displayName
    case "xyz":
      parser = SKXYZParser(displayName: displayName, string: string, windowController: nil)
      // parser?.scene.displayName = displayName
    case "poscar", "contcar":
      parser = SKVASPParser(displayName: displayName, string: string, windowController: nil)
    case "":
      if fileName == "poscar" || fileName == "contcar"
      {
        parser = SKVASPParser(displayName: displayName, string: string, windowController: nil)
      }
    default:
      fatalError("Unknown structure")
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
