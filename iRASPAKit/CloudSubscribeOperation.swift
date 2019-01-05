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
import CloudKit
import OperationKit

public class CloudSubscribeOperation: FKGroupOperation
{
  let maximumRetryAttempts: Int = 5
  var retryAttempts: Int = 0
  
  public init(subscriptionID: String)
  {
    super.init()
    
    let projectSubscription : CKSubscription
    let predicate: NSPredicate = NSPredicate(format: "TRUEPREDICATE")
    
    if #available(OSX 10.12, *)
    {
      projectSubscription = CKQuerySubscription(recordType: "ProjectNode", predicate: predicate, subscriptionID: subscriptionID, options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate])
      
      // silent push notification
      let notificationInfo = CKSubscription.NotificationInfo()
      notificationInfo.shouldSendContentAvailable = true
      notificationInfo.desiredKeys = ["displayName", "parent"] // max 3 keys
      projectSubscription.notificationInfo = notificationInfo
      
      let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [projectSubscription], subscriptionIDsToDelete: [])
      operation.database = CKContainer(identifier: "iCloud.nl.darkwing.iRASPA").publicCloudDatabase
      operation.modifySubscriptionsCompletionBlock = { [weak self] (subscription: [CKSubscription]?, string: [String]?, error: Error?) in
        if let error = error as? CKError
        {
          switch(error)
          {
          case CKError.notAuthenticated:
            break
          //self.windowController?.logQueue.verbose(message: "iCloud authentication error: enable iCloud and iCloud-drive ")
          default:
            self?.handleCloudKitFetchError(error: error, retryOperation: operation)
          }
        }
      }
      
      self.addOperation(operation)
    }
    else
    {
      // FIX: NOT WORKING FOR 10.11 -> xcode bug
       //CKSubscription(recordType: "ProjectNode", predicate: predicate, subscriptionID: subscriptionID, options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate])
    }

    
    
  }
  
  func handleCloudKitFetchError(error: CKError, retryOperation : Operation)
  {
    switch (error.code)
    {
    case .zoneBusy, .requestRateLimited, .serviceUnavailable, .networkFailure, .networkUnavailable, .resultsTruncated:
      if self.retryAttempts < self.maximumRetryAttempts
      {
        var retrySecondsDouble: Double = 3
        if let retrySecondsString = error.userInfo[CKErrorRetryAfterKey] as? String
        {
          retrySecondsDouble = Double(retrySecondsString)!
          self.retryAttempts += 1
          let delayOperation = DelayOperation(interval: retrySecondsDouble)
          retryOperation.addDependency(delayOperation)
          self.addOperations([delayOperation,retryOperation])
        }
        
      }
      break
      //retryFetch(error, retryAfter: parseRetryTime(error), completionHandler: completionHandler)
      
    case .badDatabase, .internalError, .badContainer, .missingEntitlement,
         .constraintViolation, .incompatibleVersion, .assetFileNotFound,
         .assetFileModified, .invalidArguments,
         .permissionFailure, .serverRejectedRequest:
      // Developer issue
      //completionHandler(error)
      self.finishWithError(error as NSError)
      break
    case .unknownItem:
      // Developer issue
      // - Never delete CloudKit Record Types.
      // - This issue will arise if you created some records of this type
      //   and then deleted the type. Even if the records were also deleted,
      //   you must keep the type around because deleted recordIDs are stored
      //   along with type information. When fetching, this is unfortunately
      //   checked.
      // - A possible hack is to save a new record with the missing record type
      //   name. This works because field information is not saved on deleted
      //   record IDs. Unfortunately you might accidentally overwrite an existing
      //   record type which will lead to further errors.
      //completionHandler(error)
      break
    case .quotaExceeded, .operationCancelled:
      // User issue. Provide alert.
      //completionHandler(error)
      break
    case .limitExceeded, .partialFailure, .serverRecordChanged,
         .batchRequestFailed:
      // Not possible in a fetch operation (I think).
      //completionHandler(error)
      break
    case .notAuthenticated:
      // Handled as condition of sync operation.
      //completionHandler(error)
      break
    case .zoneNotFound, .userDeletedZone:
      // Handled in PrepareZoneOperation.
      //completionHandler(error)
      break
    case .changeTokenExpired:
      // TODO: Determine correct handling
      // CK Docs: The previousServerChangeToken value is too old and the client must re-sync from scratch
      //completionHandler(error)
      break
    default:
      break
    }
  }
}
