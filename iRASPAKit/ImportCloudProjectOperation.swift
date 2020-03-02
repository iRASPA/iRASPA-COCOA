/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import LogViewKit
import OperationKit
import SimulationKit
import SymmetryKit

extension NSOutlineView
{
  public func makeItemVisible(item: ProjectTreeNode)
  {
    if let parent = item.parentNode
    {
      makeItemVisible(item: parent)
    }
    self.expandItem(item)
  }
}

// ImportProjectFromCloud
public class ImportProjectFromCloudOperation: FKGroupOperation
{
  private var progressViewKVOContext = 0
  
  weak var projectTreeNode: ProjectTreeNode?
  let maximumRetryAttempts: Int = 5
  var retryAttempts: Int = 0
  var recordIDs: [CKRecord.ID] = []
  weak var outlineView: NSOutlineView?
  var representedObject: iRASPAProject?
  
  public init(projectTreeNode: ProjectTreeNode, outlineView: NSOutlineView?, forceFieldSets: SKForceFieldSets, reloadCompletionBlock: @escaping () -> ())
  {
    //self.recordIDs = [projectTreeNode.recordID!]
    self.recordIDs = [CKRecord.ID(recordName: projectTreeNode.representedObject.fileNameUUID)]
    self.projectTreeNode = projectTreeNode
    self.outlineView = outlineView
    
    super.init(operations: [])
    
    // create a new Progress-object (Progress-objects can not be resused)
    // Do this in init, so that our NSProgress instance is parented to the current one in the thread that created the operation
    // This progress's children are weighted, the reading takes 20% and the computation of the bonds takes the remaining portion
    progress = Progress.discreteProgress(totalUnitCount: 10)
    progress.completedUnitCount = 0
    
    
    self.addOperation(fetchOperation(recordIDs: recordIDs))
    
    //self.projectTreeNode?.status = .importing
    
    assert(Thread.isMainThread)
    if let row = outlineView?.row(forItem: self.projectTreeNode), row >= 0
    {
      outlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
    }

    
    progress.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options: [.new], context: &progressViewKVOContext)
    
    
    
    self.completionBlock = {
      DispatchQueue.main.async {
        self.progress.completedUnitCount = 10
        self.progress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
        
        self.projectTreeNode?.recordID = nil
        //self.projectTreeNode?.status = .ready
        if let representedObject = self.representedObject
        {
          projectTreeNode.representedObject = representedObject
          
          representedObject.loadedProjectStructureNode?.allStructures.forEach{$0.setRepresentationForceField(forceField: $0.atomForceFieldIdentifier, forceFieldSets: forceFieldSets)}
          
          representedObject.loadedProjectStructureNode?.allStructures.forEach{$0.reComputeBoundingBox()}
          
        }
        
        self.outlineView?.makeItemVisible(item: projectTreeNode)
        self.outlineView?.reloadItem(self.projectTreeNode)
        
        reloadCompletionBlock()
      }
    }
  }
  
  
  func fetchOperation(recordIDs: [CKRecord.ID]) -> Operation
  {
    let operation = CKFetchRecordsOperation(recordIDs: recordIDs)
    operation.database = Cloud.shared.cloudKitContainer.publicCloudDatabase
    
    operation.perRecordProgressBlock = {(record: CKRecord.ID, progress: Double) -> Void in
        self.progress.completedUnitCount = Int64(10 * progress)
    }
    
    operation.fetchRecordsCompletionBlock = {(dict: [CKRecord.ID : CKRecord]?, error: Error?) -> Void in
      
      if let error = error as? CKError
      {
        self.handleCloudKitFetchError(error: error)
        
      }
      else
      {
        if let projectTreeNode = self.projectTreeNode,
           let record: CKRecord = dict?[CKRecord.ID(recordName: projectTreeNode.representedObject.fileNameUUID)]
        {
          if let asset: CKAsset = record["representedObject"] as? CKAsset
          {
            do
            {
              let data: Data = try Data.init(contentsOf: asset.fileURL!)
              
              let propertyListDecoder: PropertyListDecoder = PropertyListDecoder()
              let project: iRASPAProject = try propertyListDecoder.decodeCompressed(iRASPAProject.self, from: data)
              self.representedObject = project
              self.representedObject?.lazyStatus = .loaded
              self.representedObject?.nodeType = .leaf              
            }
            catch
            {
              LogQueue.shared.error(destination: nil, message: "(\(projectTreeNode.displayName)) " + error.localizedDescription)
            }
          }
          
        }
      }
    }
    return operation
  }
  
  func handleCloudKitFetchError(error: CKError)
  {
    //let ckErrorCode: CKError.Code = CKError.Code(rawValue: error.code)!
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
          let fetchOperation = self.fetchOperation(recordIDs: recordIDs)
          fetchOperation.addDependency(delayOperation)
          self.addOperations([delayOperation,fetchOperation])
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
  
  override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
  {
    if context == &progressViewKVOContext,
      keyPath == "fractionCompleted",
      let newProgress = object as? Progress,
      newProgress == progress
    {
      //call my delegate here that updates the UI
      DispatchQueue.main.async(execute: {
        // check that the node still exists (it does not when closing the app, but this background process is still running)
        if let row = self.outlineView?.row(forItem: self.projectTreeNode), row >= 0
        {
          if let view: ProgressIndicator = self.outlineView?.view(atColumn: 0, row: row, makeIfNecessary: false) as?  ProgressIndicator
          {
            view.progressIndicator?.doubleValue = newProgress.fractionCompleted
          }
        }
      })
    }
    else
    {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
    
  }

}

