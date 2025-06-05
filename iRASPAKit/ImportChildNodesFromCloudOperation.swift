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
import CloudKit
import OperationKit

public class ImportChildNodesOfParentRecordIDOperation: FKGroupOperation, @unchecked Sendable
{
  public var childNodes: [ProjectTreeNode] = []
  
  public init(parentRecordID: CKRecord.ID)
  {
    super.init()
    
    let fetchRecordOperation: FetchRecordFromCloudOperation = FetchRecordFromCloudOperation(recordID: parentRecordID)
    
    // pass data from fetch to query-operation
    let adapterOperation = BlockOperation(block: {[weak self, unowned fetchRecordOperation] in
      if let record = fetchRecordOperation.record
      {
        let fetchChildNodesOperation = ChildrenOfParentQueryOperation(parentRecord: record)
        self?.addOperation(fetchChildNodesOperation)
        
        let copyOperation = BlockOperation(block: {[weak self] in
          self?.childNodes = fetchChildNodesOperation.childNodes
        })
        copyOperation.addDependency(fetchChildNodesOperation)
        self?.addOperation(copyOperation)
      }
    })
    adapterOperation.addDependency(fetchRecordOperation)
    
    self.addOperations([fetchRecordOperation, adapterOperation])
  }
}
