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

/**
 `ExclusivityController` is a singleton to keep track of all the in-flight
 `Operation` instances that have declared themselves as requiring mutual exclusivity.
 We use a singleton because mutual exclusivity must be enforced across the entire
 app, regardless of the `OperationQueue` on which an `Operation` was executed.
 */
public class FKExclusivityController
{
  static let sharedExclusivityController = FKExclusivityController()
  
  fileprivate let serialQueue = DispatchQueue(label: "Operations.ExclusivityController", attributes: [])
  fileprivate var operations: [String: [Operation]] = [:]
  
  fileprivate init() {
    /*
     A private initializer effectively prevents any other part of the app
     from accidentally creating an instance.
     */
  }
  
  /// Registers an operation as being mutually exclusive
  func addOperation(_ operation: Operation, categories: [String]) {
    /*
     This needs to be a synchronous operation.
     If this were async, then we might not get around to adding dependencies
     until after the operation had already begun, which would be incorrect.
     */
    serialQueue.sync {
      for category in categories {
        self.noqueue_addOperation(operation, category: category)
      }
    }
  }
  
  /// Unregisters an operation from being mutually exclusive.
  func removeOperation(_ operation: Operation, categories: [String]) {
    serialQueue.async {
      for category in categories {
        self.noqueue_removeOperation(operation, category: category)
      }
    }
  }
  
  
  // MARK: Operation Management
  
  fileprivate func noqueue_addOperation(_ operation: Operation, category: String) {
    var operationsWithThisCategory = operations[category] ?? []
    
    if let last = operationsWithThisCategory.last {
      operation.addDependency(last)
    }
    
    operationsWithThisCategory.append(operation)
    
    operations[category] = operationsWithThisCategory
  }
  
  fileprivate func noqueue_removeOperation(_ operation: Operation, category: String) {
    let matchingOperations = operations[category]
    
    if var operationsWithThisCategory = matchingOperations,
      let index = operationsWithThisCategory.firstIndex(of: operation) {
      
      operationsWithThisCategory.remove(at: index)
      operations[category] = operationsWithThisCategory
    }
  }
  
}

