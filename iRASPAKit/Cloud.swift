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


// The Singleton should be final to prevent this to be subclassed
public class Cloud
{
  public let projectData: ProjectTreeController = ProjectTreeController()
  public let cloudKitContainer: CKContainer = CKContainer(identifier: "iCloud.nl.darkwing.iRASPA")
  private let projectNodeSubscriptionID = "iRASPA projects"
  var userRecordID: CKRecord.ID? = nil
  var userRecord: CKRecord? = nil
  public var administratorRole: Bool = true
  private var cloudKitObserver: NSObjectProtocol? = nil
  
  // The lazy initialization of the shared instance is thread safe by the definition of let
  public static let shared: Cloud = Cloud()
  
  public let cloudQueue: FKOperationQueue = FKOperationQueue()
    
  // The private init makes sure the singleton is truly unique and prevents outside objects from 
  // creating their own instances of your class through virtue of access control.
  private init()
  {
    cloudQueue.name = "iCloud queue"
    cloudQueue.qualityOfService = .userInitiated

    let cloudAccountAvailableOperation: CloudAccountAvailableOperation = CloudAccountAvailableOperation()
    cloudQueue.addOperation(cloudAccountAvailableOperation)
    
    let requestDiscoveryPermissionCloudUserOperation = RequestDiscoveryPermissionCloudUserOperation()
    cloudQueue.addOperation(requestDiscoveryPermissionCloudUserOperation)
    
    let cloudSubscribeOperation = CloudSubscribeOperation(subscriptionID: projectNodeSubscriptionID)
    cloudQueue.addOperation(cloudSubscribeOperation)
    
    // load the cloud root-Nodes
    let userRecordIDOperation: FetchCurrentUserRecordOperation = FetchCurrentUserRecordOperation()
    cloudQueue.addOperation(userRecordIDOperation)
    
    let queryOperation = ImportNodesFromCloud(type: "RootNode")
    // get the root-nodes after the user-id is known
    queryOperation.addDependency(userRecordIDOperation)
    queryOperation.completionBlock = {
      DispatchQueue.main.async {
        for record in queryOperation.results
        {
          let proxyProject = ProjectTreeNode(record: record)
          proxyProject.owner = "root"
          let project: ProjectGroup = ProjectGroup(name: "test")
          proxyProject.representedObject = iRASPAProject(group: project)
          
          Cloud.shared.projectData.appendNode(proxyProject, atArrangedObjectIndexPath: [])
          Cloud.shared.projectData.updateFilteredNodes()
        }
        
        // reload cloud-treeController
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationStrings.iCloudReloadDataNotification), object: nil)
      }
    }
    cloudQueue.addOperation(queryOperation)
    
    cloudKitObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: NotificationStrings.iCloudRemoteNotificationReceived), object: nil, queue: OperationQueue.main, using: { notification in
      if let ckqn = notification.userInfo?["Records"] as? CKQueryNotification
      {
        self.iCloudHandleSubscriptionNotification(ckqn)
      }
    })

    //debugPrint("Deleting all cloudkit data....")
    //deleteAllProjectRecords()
  }
  
  
  private func iCloudHandleSubscriptionNotification(_ ckqn: CKQueryNotification)
  {
    if ckqn.subscriptionID == self.projectNodeSubscriptionID
    {
      if let _ = ckqn.recordID
      {
        switch ckqn.queryNotificationReason
        {
        case .recordCreated:
          if let recordID: CKRecord.ID = ckqn.recordID
          {
            let operation: FetchRecordFromCloudOperation = FetchRecordFromCloudOperation(recordID: recordID)
            operation.completionBlock = {
                            
              if let parentRecordID: CKRecord.ID = operation.parentReference?.recordID,
                let displayName: String = operation.displayName,
                let parent: ProjectTreeNode = Cloud.shared.projectData.FindParent(recordID: parentRecordID) //,parent.status == .ready
              {
                let proxyProject: ProjectTreeNode = ProjectTreeNode(displayName: displayName, recordID: recordID)
                DispatchQueue.main.async {
                  
                  //self.addNode(proxyProject, inItem: parent, atIndex: 0)
                  let notification: Notification = Notification(name: NSNotification.Name(rawValue: NotificationStrings.iCloudAddNodeNotification), object: self, userInfo: ["node": proxyProject, "parent": parent])
                  NotificationCenter.default.post(notification)
                }
              }
            }
            
            Cloud.shared.cloudQueue.addOperation(operation)
            
          }
          break
        case .recordDeleted:
          break
        case .recordUpdated:
          break
        @unknown default:
          fatalError()
        }
      }
    }
  }
  
  func deleteAllProjectRecords()
  {
    let fetchOperation: DeleteAllRecordsOperation =  DeleteAllRecordsOperation(type: "ProjectNode")
    cloudQueue.addOperation(fetchOperation)
    
  }
  
}

