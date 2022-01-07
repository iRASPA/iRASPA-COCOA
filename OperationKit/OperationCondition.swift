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

let OperationConditionKey = "OperationCondition"

/**
 A protocol for defining conditions that must be satisfied in order for an
 operation to begin execution.
 */
protocol FKOperationCondition {
  /**
   The name of the condition. This is used in userInfo dictionaries of `.ConditionFailed`
   errors as the value of the `OperationConditionKey` key.
   */
  static var name: String { get }
  
  /**
   Specifies whether multiple instances of the conditionalized operation may
   be executing simultaneously.
   */
  static var isMutuallyExclusive: Bool { get }
  
  /**
   Some conditions may have the ability to satisfy the condition if another
   operation is executed first. Use this method to return an operation that
   (for example) asks for permission to perform the operation
   
   - parameter operation: The `Operation` to which the Condition has been added.
   - returns: An `NSOperation`, if a dependency should be automatically added. Otherwise, `nil`.
   - note: Only a single operation may be returned as a dependency. If you
   find that you need to return multiple operations, then you should be
   expressing that as multiple conditions. Alternatively, you could return
   a single `GroupOperation` that executes multiple operations internally.
   */
  func dependencyForOperation(_ operation: FKOperation) -> Operation?
  
  /// Evaluate the condition, to see if it has been satisfied or not.
  func evaluateForOperation(_ operation: FKOperation, completion: @escaping (OperationConditionResult) -> Void)
}

/**
 An enum to indicate whether an `OperationCondition` was satisfied, or if it
 failed with an error.
 */
public enum OperationConditionResult: Equatable {
  case satisfied
  case failed(NSError)
  
  var error: NSError? {
    if case .failed(let error) = self {
      return error
    }
    
    return nil
  }
}

public func ==(lhs: OperationConditionResult, rhs: OperationConditionResult) -> Bool {
  switch (lhs, rhs) {
  case (.satisfied, .satisfied):
    return true
  case (.failed(let lError), .failed(let rError)) where lError == rError:
    return true
  default:
    return false
  }
}

// MARK: Evaluate Conditions

public struct FKOperationConditionEvaluator {
  static func evaluate(_ conditions: [FKOperationCondition], operation: FKOperation, completion: @escaping ([NSError]) -> Void) {
    // Check conditions.
    let conditionGroup = DispatchGroup()
    
    var results = [OperationConditionResult?](repeating: nil, count: conditions.count)
    
    // Ask each condition to evaluate and store its result in the "results" array.
    for (index, condition) in conditions.enumerated() {
      conditionGroup.enter()
      condition.evaluateForOperation(operation) { result in
        results[index] = result
        conditionGroup.leave()
      }
    }
    
    // After all the conditions have evaluated, this block will execute.
    conditionGroup.notify(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default)) {
      // Aggregate the errors that occurred, in order.
      var failures = results.compactMap { $0?.error }
      
      /*
       If any of the conditions caused this operation to be cancelled,
       check for that.
       */
      if operation.isCancelled {
        failures.append(NSError(code: .conditionFailed))
      }
      
      completion(failures)
    }
  }
}

