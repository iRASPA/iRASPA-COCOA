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

/**
 A simple condition that negates the evaluation of another condition.
 This is useful (for example) if you want to only execute an operation if the
 network is NOT reachable.
 */
struct NegatedCondition<T: FKOperationCondition>: FKOperationCondition {
  static var name: String {
    return "Not<\(T.name)>"
  }
  
  static var negatedConditionKey: String {
    return "NegatedCondition"
  }
  
  static var isMutuallyExclusive: Bool {
    return T.isMutuallyExclusive
  }
  
  let condition: T
  
  init(condition: T) {
    self.condition = condition
  }
  
  func dependencyForOperation(_ operation: FKOperation) -> Operation? {
    return condition.dependencyForOperation(operation)
  }
  
  func evaluateForOperation(_ operation: FKOperation, completion: @escaping (OperationConditionResult) -> Void) {
    condition.evaluateForOperation(operation) { result in
      if result == .satisfied {
        // If the composed condition succeeded, then this one failed.
        let error = NSError(code: .conditionFailed, userInfo: [
          OperationConditionKey: type(of: self).name,
          type(of: self).negatedConditionKey: type(of: self.condition).name
          ])
        
        completion(.failed(error))
      }
      else {
        // If the composed condition failed, then this one succeeded.
        completion(.satisfied)
      }
    }
  }
}
