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
import LogViewKit

public class FetchRecordFromCloudOperation: FKGroupOperation, @unchecked Sendable
{
  let maximumRetryAttempts: Int = 5
  var retryAttempts: Int = 0
  
  public var parentReference: CKRecord.Reference? = nil
  public var identifier: String? = nil
  public var displayName: String? = nil
  public var record: CKRecord? = nil
  
  public init(recordID: CKRecord.ID)
  {
    super.init()
    
    let operation: CKFetchRecordsOperation = CKFetchRecordsOperation(recordIDs: [recordID])
    operation.database = CKContainer(identifier: "iCloud.nl.darkwing.iRASPA").publicCloudDatabase
    operation.recordIDs = [recordID]
    operation.desiredKeys = ["displayName", "parent"]
    
    operation.fetchRecordsCompletionBlock = {[weak self] (dict: [CKRecord.ID : CKRecord]?, error: Error?) -> Void in
      
      if let error = error as? CKError
      {
        LogQueue.shared.warning(destination: nil, message: "CloudKit fetch record \(recordID.recordName): \(error.localizedDescription) (\(error.code.rawValue))")
        self?.handleCloudKitFetchError(error: error, retryOperation: operation)
      }
      else
      {
        if let record: CKRecord = dict?[recordID]
        {
          self?.record = record
          self?.displayName = record["displayName"] as? String
          self?.parentReference = record["parent"] as? CKRecord.Reference
        }
        
      }
    }
    
    self.addOperation(operation)
  }
  
  func handleCloudKitFetchError(error: CKError, retryOperation : Operation)
  {
    switch (error.code)
    {
    case .zoneBusy, .requestRateLimited, .serviceUnavailable, .networkFailure, .networkUnavailable, .resultsTruncated:
      if self.retryAttempts < self.maximumRetryAttempts,
         let retrySecondsString = error.userInfo[CKErrorRetryAfterKey] as? String,
         let retrySecondsDouble = Double(retrySecondsString)
      {
        self.retryAttempts += 1
        let delayOperation = DelayOperation(interval: retrySecondsDouble)
        retryOperation.addDependency(delayOperation)
        self.addOperations([delayOperation, retryOperation])
      }
      else
      {
        self.finishWithError(error as NSError)
      }
      
    case .badDatabase, .internalError, .badContainer, .missingEntitlement,
         .constraintViolation, .incompatibleVersion, .assetFileNotFound,
         .assetFileModified, .invalidArguments,
         .permissionFailure, .serverRejectedRequest:
      // Developer issue
      //completionHandler(error)
      self.finishWithError(error as NSError)
      break
    case .unknownItem:
      LogQueue.shared.warning(destination: nil, message: "CloudKit unknownItem — record missing in this environment (Debug uses Development DB).")
      self.finishWithError(error as NSError)
    case .quotaExceeded, .operationCancelled:
      self.finishWithError(error as NSError)
    case .limitExceeded, .partialFailure, .serverRecordChanged,
         .batchRequestFailed:
      self.finishWithError(error as NSError)
    case .notAuthenticated:
      LogQueue.shared.warning(destination: nil, message: "CloudKit notAuthenticated — sign into iCloud on the Simulator.")
      self.finishWithError(error as NSError)
    case .zoneNotFound, .userDeletedZone:
      self.finishWithError(error as NSError)
    case .changeTokenExpired:
      self.finishWithError(error as NSError)
    default:
      self.finishWithError(error as NSError)
    }
  }
  
}
