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
import LogViewKit
import CloudKit
import OperationKit

public class ImportNodesFromCloud: FKGroupOperation
{
  let maximumRetryAttempts: Int = 5
  var retryAttempts: Int = 0
  
  public var results: [CKRecord] = []
  
  public init(type:String)
  {
    super.init()
    
    let predicate = NSPredicate(format: "TRUEPREDICATE")
    let sortDescriptor = NSSortDescriptor(key: "displayName", ascending: true)
    let query: CKQuery = CKQuery(recordType: type, predicate: predicate)
    query.sortDescriptors = [sortDescriptor]
    let queryOperation: CKQueryOperation = CKQueryOperation(query: query)
    //queryOperation.resultsLimit = 1
    queryOperation.database = CKContainer(identifier: "iCloud.nl.darkwing.iRASPA").publicCloudDatabase
    queryOperation.desiredKeys = ["displayName", "type"]
    queryOperation.recordFetchedBlock = { record  in
      self.results.append(record)
    }
    
    queryOperation.queryCompletionBlock = { [weak self] (cursor: CKQueryOperation.Cursor?, error: Error?) in
      if let error = error as? CKError
      {
        //self.finishWithError(error as NSError)
        if let cursor = cursor
        {
          let retryOperation = CKQueryOperation(cursor: cursor)
          retryOperation.database = CKContainer(identifier: "iCloud.nl.darkwing.iRASPA").publicCloudDatabase
          self?.handleCloudKitFetchError(error: error, retryOperation: retryOperation)
        }
        else
        {
          self?.handleCloudKitFetchError(error: error, retryOperation: queryOperation)
        }
      }
      else if let cursor = cursor
      {
        // if there are more nodes, then download them further
        let fetchMoreRecords = CKQueryOperation(cursor: cursor)
        fetchMoreRecords.database = CKContainer(identifier: "iCloud.nl.darkwing.iRASPA").publicCloudDatabase
        self?.addOperation(fetchMoreRecords)
      }
    }
    
    self.addOperation(queryOperation)
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
      LogQueue.shared.warning(destination: nil, message: "iCloud quota exceeded.")
      break
    case .limitExceeded, .partialFailure, .serverRecordChanged,
         .batchRequestFailed:
      // Not possible in a fetch operation (I think).
      //completionHandler(error)
      LogQueue.shared.warning(destination: nil, message: "iCloud limits exceeded.")
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

