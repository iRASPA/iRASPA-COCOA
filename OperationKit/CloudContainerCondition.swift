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

import Foundation
import CloudKit

/// A condition describing that the operation requires access to a specific CloudKit container.
struct CloudContainerCondition: FKOperationCondition {
  
  static let name = "CloudContainer"
  static let containerKey = "CKContainer"
  
  /*
   CloudKit has no problem handling multiple operations at the same time
   so we will allow operations that use CloudKit to be concurrent with each
   other.
   */
  static let isMutuallyExclusive = false
  
  let container: CKContainer // this is the container to which you need access.
  
  let permission: CKContainer.Application.Permissions
  
  /**
   - parameter container: the `CKContainer` to which you need access.
   - parameter permission: the `CKApplicationPermissions` you need for the
   container. This parameter has a default value of `[]`, which would get
   you anonymized read/write access.
   */
  init(container: CKContainer, permission: CKContainer.Application.Permissions = []) {
    self.container = container
    self.permission = permission
  }
  
  func dependencyForOperation(_ operation: FKOperation) -> Operation? {
    return CloudKitPermissionOperation(container: container, permission: permission)
  }
  
  func evaluateForOperation(_ operation: FKOperation, completion: @escaping (OperationConditionResult) -> Void) {
    container.verifyPermission(permission, requestingIfNecessary: false) { error in
      if let error = error {
        let conditionError = NSError(code: .conditionFailed, userInfo: [
          OperationConditionKey: type(of: self).name,
          type(of: self).containerKey: self.container,
          NSUnderlyingErrorKey: error
          ])
        
        completion(.failed(conditionError))
      }
      else {
        completion(.satisfied)
      }
    }
  }
}

/**
 This operation asks the user for permission to use CloudKit, if necessary.
 If permission has already been granted, this operation will quickly finish.
 */
private class CloudKitPermissionOperation: FKOperation {
  let container: CKContainer
  let permission: CKContainer.Application.Permissions
  
  init(container: CKContainer, permission: CKContainer.Application.Permissions) {
    self.container = container
    self.permission = permission
    super.init()
    
    if permission != [] {
      /*
       Requesting non-zero permissions means that this potentially presents
       an alert, so it should not run at the same time as anything else
       that presents an alert.
       */
      addCondition(AlertPresentation())
    }
  }
  
  override func execute() {
    container.verifyPermission(permission, requestingIfNecessary: true) { error in
      self.finishWithError(error)
    }
  }
  
}
