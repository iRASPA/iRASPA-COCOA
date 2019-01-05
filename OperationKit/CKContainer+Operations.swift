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

import CloudKit

extension CKContainer {
  /**
   Verify that the current user has certain permissions for the `CKContainer`,
   and potentially requesting the permission if necessary.
   
   - parameter permission: The permissions to be verified on the container.
   
   - parameter shouldRequest: If this value is `true` and the user does not
   have the passed `permission`, then the user will be prompted for it.
   
   - parameter completion: A closure that will be executed after verification
   completes. The `NSError` passed in to the closure is the result of either
   retrieving the account status, or requesting permission, if either
   operation fails. If the verification was successful, this value will
   be `nil`.
   */
  func verifyPermission(_ permission: CKContainer.Application.Permissions, requestingIfNecessary shouldRequest: Bool = false, completion: @escaping (NSError?) -> Void) {
    verifyAccountStatus(self, permission: permission, shouldRequest: shouldRequest, completion: completion)
  }
}

/**
 Make these helper functions instead of helper methods, so we don't pollute
 `CKContainer`.
 */
private func verifyAccountStatus(_ container: CKContainer, permission: CKContainer.Application.Permissions, shouldRequest: Bool, completion: @escaping (NSError?) -> Void) {
  container.accountStatus { accountStatus, accountError in
    if accountStatus == .available {
      if permission != [] {
        verifyPermission(container, permission: permission, shouldRequest: shouldRequest, completion: completion)
      }
      else {
        completion(nil)
      }
    }
    else {
      let error = accountError ?? NSError(domain: CKErrorDomain, code: CKError.notAuthenticated.rawValue, userInfo: nil)
      completion(error as NSError)
    }
  }
}

private func verifyPermission(_ container: CKContainer, permission: CKContainer.Application.Permissions, shouldRequest: Bool, completion: @escaping (NSError?) -> Void) {
  container.status(forApplicationPermission: permission) { permissionStatus, permissionError in
    if permissionStatus == .granted {
      completion(nil)
    }
    else if permissionStatus == .initialState && shouldRequest {
      requestPermission(container, permission: permission, completion: completion)
    }
    else {
      let error = permissionError ?? NSError(domain: CKErrorDomain, code: CKError.permissionFailure.rawValue, userInfo: nil)
      completion(error as NSError)
    }
  }
}

private func requestPermission(_ container: CKContainer, permission: CKContainer.Application.Permissions, completion: @escaping (NSError?) -> Void) {
  DispatchQueue.main.async {
    container.requestApplicationPermission(permission) { requestStatus, requestError in
      if requestStatus == .granted {
        completion(nil)
      }
      else {
        let error = requestError ?? NSError(domain: CKErrorDomain, code: CKError.permissionFailure.rawValue, userInfo: nil)
        completion(error as NSError)
      }
    }
  }
}

