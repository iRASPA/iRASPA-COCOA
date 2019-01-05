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
import SystemConfiguration

/**
 This is a condition that performs a very high-level reachability check.
 It does *not* perform a long-running reachability check, nor does it respond to changes in reachability.
 Reachability is evaluated once when the operation to which this is attached is asked about its readiness.
 */
public struct ReachabilityCondition: FKOperationCondition
{
  static let hostKey = "Host"
  static let name = "Reachability"
  static let isMutuallyExclusive = false
  
  let host: URL
  
  
  init(host: URL) {
    self.host = host
  }
  
  func dependencyForOperation(_ operation: FKOperation) -> Operation? {
    return nil
  }

  
  func evaluateForOperation(_ operation: FKOperation, completion: @escaping (OperationConditionResult) -> Void)
  {
    ReachabilityController.requestReachability(host) { reachable in
      if reachable
      {
        completion(.satisfied)
      }
      else
      {
        let error = NSError(code: .conditionFailed, userInfo: [
          OperationConditionKey: type(of: self).name,
          type(of: self).hostKey: self.host
          ])
        
        completion(.failed(error))
      }
    }
  }
  
}

/// A private singleton that maintains a basic cache of `SCNetworkReachability` objects.
private class ReachabilityController
{
  static var reachabilityRefs = [String: SCNetworkReachability]()
  
  static let reachabilityQueue = DispatchQueue(label: "Operations.Reachability", attributes: [])
  
  static func requestReachability(_ url: URL, completionHandler: @escaping (Bool) -> Void) {
    if let host = url.host {
      reachabilityQueue.async {
        var ref = self.reachabilityRefs[host]
        
        if ref == nil {
          let hostString = host as NSString
          ref = SCNetworkReachabilityCreateWithName(nil, hostString.utf8String!)
        }
        
        if let ref = ref {
          self.reachabilityRefs[host] = ref
          
          var reachable = false
          var flags: SCNetworkReachabilityFlags = []
          if SCNetworkReachabilityGetFlags(ref, &flags)
          {
            /*
             Note that this is a very basic "is reachable" check.
             Your app may choose to allow for other considerations,
             such as whether or not the connection would require
             VPN, a cellular connection, etc.
             */
            reachable = flags.contains(.reachable)
          }
          completionHandler(reachable)
        }
        else {
          completionHandler(false)
        }
      }
    }
    else {
      completionHandler(false)
    }
  }
}

