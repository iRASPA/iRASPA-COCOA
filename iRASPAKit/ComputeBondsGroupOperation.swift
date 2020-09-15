/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import OperationKit

class ComputeBondsGroupOperation: FKGroupOperation
{
  weak var windowController: NSWindowController?
  
  public init(structures: [Structure], windowController: NSWindowController?)
  {
    self.windowController = windowController
    
    super.init()
    
    // create a new Progress-object (Progress-objects can not be resused)
    //self.progress = progress
    progress = Progress.discreteProgress(totalUnitCount: Int64(structures.count))
    progress.completedUnitCount = 0
    
   
    let operations: [FKOperation] = structures.compactMap{$0.computeBondsOperation(structure: $0, windowController: windowController)}
    for operation in operations
    {
      progress.addChild(operation.progress, withPendingUnitCount: 1)
    }
    self.addOperations(operations)
    
    completionBlock = {
      self.progress.completedUnitCount = Int64(structures.count)
    }
  }
}

