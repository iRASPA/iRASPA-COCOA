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
import OperationKit
import SimulationKit
import SymmetryKit

class ReadStructureGroupOperation: FKGroupOperation
{
  var scenes: [Scene] = []
  unowned var projectTreeNode : ProjectTreeNode
  unowned var colorSets: SKColorSets
  unowned var forceFieldSets: SKForceFieldSets
  
  public init(projectTreeNode : ProjectTreeNode, urls: [URL], windowController: NSWindowController?, colorSets: SKColorSets, forceFieldSets: SKForceFieldSets, onlyAsymmetricUnit: Bool, asMolecule: Bool)
  {
    self.projectTreeNode = projectTreeNode
    self.colorSets = colorSets
    self.forceFieldSets = forceFieldSets
    super.init()
    
    // create a new Progress-object (Progress-objects can not be resused)
    progress = Progress.discreteProgress(totalUnitCount: Int64(urls.count))
    progress.completedUnitCount = 0
    
    for url in urls
    {
      let operation: ReadStructureOperation = ReadStructureOperation(ProjectTreeNode: projectTreeNode, url: url, windowController: windowController, onlyAsymmetricUnit: onlyAsymmetricUnit, asMolecule: asMolecule)
      progress.addChild(operation.progress, withPendingUnitCount: 1)
      self.addOperation(operation)
    }
    
    completionBlock = {
      self.progress.completedUnitCount = Int64(urls.count)
    }
  }
  
  let lock: NSLock = NSLock()
  
  override func operationDidFinish(_ operation: Operation, withErrors: [NSError])
  {
    if let parserScene = (operation as? ReadStructureOperation)?.parser?.scene
    {
      let scene: Scene = Scene(parser: parserScene)
      lock.lock()
      scenes.append(scene)
      lock.unlock()
    }
  }
}

