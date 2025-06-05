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

public class RequestDiscoveryPermissionCloudUserOperation: Operation, @unchecked Sendable
{
  
  public override func main()
  {
    CKContainer(identifier: "iCloud.nl.darkwing.iRASPA").requestApplicationPermission(CKContainer.ApplicationPermissions.userDiscoverability) { (status: CKContainer.ApplicationPermissionStatus, error: Error?) in
      
      if let error: CKError = error as? CKError
      {
        switch(error)
        {
        case CKError.networkUnavailable:
          LogQueue.shared.error(destination: nil, message: error.localizedDescription)
          break
        default:
          break
        }
      
      }
      else
      {
        let bundle: Bundle = Bundle(for:  RequestDiscoveryPermissionCloudUserOperation.self)
        switch(status)
        {
        case.initialState:
          break
        case .couldNotComplete:
          break
        case .granted:
          LogQueue.shared.info(destination: nil, message: NSLocalizedString("iCloud Public Discoverability Granted", bundle: bundle, comment: ""))
        case .denied:
          LogQueue.shared.warning(destination: nil, message: NSLocalizedString("iCloud Public Discoverability Denied", bundle: bundle, comment: ""))
          // NSWorkspace.shared().openFile("/System/Library/PreferencePanes/iCloudPref.prefPane")
        @unknown default:
          fatalError()
        }
      }
    }

  }
}
