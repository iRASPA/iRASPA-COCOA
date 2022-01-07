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

public class ChildrenOfParentQueryOperation: FKGroupOperation
{
  public var childNodes: [ProjectTreeNode] = []
  
  let maximumRetryAttempts: Int = 5
  var retryAttempts: Int = 0
  
  init(parentRecord: CKRecord)
  {
    super.init()
    
    let recordToMatch: CKRecord.Reference = CKRecord.Reference(record: parentRecord, action: CKRecord.ReferenceAction.none)
    let predicate = NSPredicate(format: "parent == %@", recordToMatch)
    let sortDescriptor = NSSortDescriptor(key: "displayName", ascending: true)
    let query: CKQuery = CKQuery(recordType: "ProjectNode", predicate: predicate)
    query.sortDescriptors = [sortDescriptor]
    
    let operation: CKQueryOperation = CKQueryOperation(query: query)
    operation.database = CKContainer(identifier: "iCloud.nl.darkwing.iRASPA").publicCloudDatabase
    operation.qualityOfService = .userInitiated
    operation.desiredKeys = ["displayName", "parent", "type", "representedObjectInfo"]
    
    operation.queryCompletionBlock = { [weak self] (cursor: CKQueryOperation.Cursor?, error: Error?) in
      if let error = error as? CKError
      {
        self?.handleCloudKitFetchError(error: error, retryOperation: operation)
      }
      else if let cursor = cursor
      {
        self?.fetchRecords(cursor: cursor)
        
      }
    }
    
    operation.recordFetchedBlock = populateArray
    
    self.addOperation(operation)
  }
  
  func fetchRecords(cursor: CKQueryOperation.Cursor?)
  {
    let queryOperation = CKQueryOperation(cursor: cursor!)
    queryOperation.database = CKContainer(identifier: "iCloud.nl.darkwing.iRASPA").publicCloudDatabase
    queryOperation.desiredKeys = ["displayName", "parent", "type", "representedObjectInfo"]
    queryOperation.qualityOfService = .userInitiated
    queryOperation.recordFetchedBlock = populateArray
    
    queryOperation.queryCompletionBlock = {[weak self] cursor, error in
      if let error = error as? CKError
      {
        self?.handleCloudKitFetchError(error: error, retryOperation: queryOperation)
      }
      else if let cursor = cursor
      {
        print("More data to fetch")
        self?.fetchRecords(cursor: cursor)
      }
      else
      {
      }
    }
    
    self.addOperation(queryOperation)
  }
  
  func populateArray(record: CKRecord)
  {
    let proxyProject = ProjectTreeNode(record: record)
    proxyProject.isEditable = false
    if let owner: String = record.creatorUserRecordID?.recordName
    {
      proxyProject.owner = owner
    }
    
    if let representedObjectInfoData: Data = record["representedObjectInfo"] as? Data
    {
      do
      {
        proxyProject.representedObjectInfo = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(representedObjectInfoData) as? [String: AnyObject] ?? [:]
      }
      catch
      {
        
      }
    }
    
    
    if let type: Int64 = record["type"] as? Int64,
      let displayName: String = record["displayName"] as? String
    {
      if type == 2
      {
        let projectGroup: ProjectGroup = ProjectGroup(name: displayName)
        //proxyProject.status = .icloudLazy
        
        proxyProject.representedObject = iRASPAProject(group: projectGroup)
      }
    }
    
    self.childNodes.append(proxyProject)
  }
  
  func handleCloudKitFetchError(error: CKError, retryOperation : Operation)
  {
    switch (error.code)
    {
    case .zoneBusy, .requestRateLimited, .serviceUnavailable, .networkFailure, .networkUnavailable, .resultsTruncated:
      if self.retryAttempts < self.maximumRetryAttempts
      {
        if let retrySecondsString = error.userInfo[CKErrorRetryAfterKey] as? String
        {
          let retrySeconds: Double = Double(retrySecondsString) ?? 3.0
          self.retryAttempts += 1
          let delayOperation = DelayOperation(interval: retrySeconds)
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
      LogQueue.shared.warning(destination: nil, message: "iCloud error \(error)")
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
      self.finishWithError(error as NSError)
    case .limitExceeded, .partialFailure, .serverRecordChanged,
         .batchRequestFailed:
      // Not possible in a fetch operation (I think).
      //completionHandler(error)
      LogQueue.shared.warning(destination: nil, message: "iCloud limit exceeded.")
      self.finishWithError(error as NSError)
    case .notAuthenticated:
      // Handled as condition of sync operation.
      //completionHandler(error)
      self.finishWithError(error as NSError)
    case .zoneNotFound, .userDeletedZone:
      // Handled in PrepareZoneOperation.
      //completionHandler(error)
      self.finishWithError(error as NSError)
    case .changeTokenExpired:
      // TODO: Determine correct handling
      // CK Docs: The previousServerChangeToken value is too old and the client must re-sync from scratch
      //completionHandler(error)
      self.finishWithError(error as NSError)
    default:
      break
    }
  }
  
  
}


