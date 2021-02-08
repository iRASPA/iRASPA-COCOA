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

import Cocoa
import CloudKit
import iRASPAKit
import PowerSourceKit
import ExceptionHandling

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
  var aboutWindowController: LocalAboutWindowController
  var documentController: iRASPADocumentController
  var previousServerChangeToken: CKServerChangeToken?
  let powerSource: PowerSource = PowerSource()
  let preferences: Preferences = Preferences()
  
  
  
  override init()
  {
    let storyboard = NSStoryboard(name: "AboutWindow", bundle: nil)
    aboutWindowController = storyboard.instantiateController(withIdentifier: "About Window Controller") as! LocalAboutWindowController
    
    documentController = iRASPADocumentController()
    
    super.init()
  }
  
  func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
  {
  }
  
  func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error)
  {
  }
  
  
  // get push-notifications for CloudKit
  func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any])
  {
    fetchNotificationChanges()
  }
  
  @IBAction func showAboutWindow(_ sender: AnyObject)
  {
    self.aboutWindowController.showWindow(self)
  }
  
  func fetchNotificationChanges()
  {
    //let database: CKDatabase = CKContainer(identifier: "iCloud.nl.darkwing.iRASPA").publicCloudDatabase

    let operation = CKFetchNotificationChangesOperation(previousServerChangeToken: nil)
    
    var notificationIDsToMarkRead = [CKNotification.ID]()
    
    operation.notificationChangedBlock = { (notification: CKNotification) -> Void in
      // Process each notification received
      if notification.notificationType == .query
      {
        let queryNotification = notification as! CKQueryNotification
        //let reason = queryNotification.queryNotificationReason
        //let recordID = queryNotification.recordID
        
        // Do your process here depending on the reason of the change
        if (notification.subscriptionID == "iRASPA projects")
        {
          let notification: Notification = Notification(name: NSNotification.Name(rawValue: NotificationStrings.iCloudRemoteNotificationReceived), object: self, userInfo: ["Records": notification])
          DispatchQueue.main.async {
            NotificationCenter.default.post(notification)
          }
        }
        
        // Add the notification id to the array of processed notifications to mark them as read
        notificationIDsToMarkRead.append(queryNotification.notificationID!)
      }
    }
    
    operation.fetchNotificationChangesCompletionBlock = { (serverChangeToken: CKServerChangeToken?, operationError: Error?) -> Void in
      guard operationError == nil else
      {
        // Handle the error here
        return
      }
      
      // Mark the notifications as read to avoid processing them again
      let markOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: notificationIDsToMarkRead)
      markOperation.markNotificationsReadCompletionBlock = { (notificationIDsMarkedRead: [CKNotification.ID]?, operationError: Error?) -> Void in
        guard operationError == nil else
        {
          // Handle the error here
          return
        }
        
        self.previousServerChangeToken = serverChangeToken
        
        if operation.moreComing
        {
          self.fetchNotificationChanges()
        }
      }
      
      let operationQueue = OperationQueue()
      operationQueue.addOperation(markOperation)
    }
    
    let operationQueue = OperationQueue()
    operationQueue.addOperation(operation)
  }
  


  func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool
  {
    return true
  }

  func applicationDidFinishLaunching(_ aNotification: Notification)
  {
    // Insert code here to initialize your application
    
    // register for silent push notification
    NSApp.registerForRemoteNotifications(matching: [])
  }


  func applicationWillTerminate(_ aNotification: Notification)
  {
    // Insert code here to tear down your application
    
  }
}

