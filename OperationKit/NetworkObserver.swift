/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

/**
 An `OperationObserver` that will cause the network activity indicator to appear
 as long as the `Operation` to which it is attached is executing.
 */
struct NetworkObserver: FKOperationObserver {
  // MARK: Initilization
  
  init() { }
  
  func operationDidStart(_ operation: FKOperation) {
    DispatchQueue.main.async {
      // Increment the network indicator's "reference count"
      NetworkIndicatorController.sharedIndicatorController.networkActivityDidStart()
    }
  }
  
  func operation(_ operation: FKOperation, didProduceOperation newOperation: FKOperation) { }
  
  func operationDidFinish(_ operation: FKOperation, errors: [NSError]) {
    DispatchQueue.main.async {
      // Decrement the network indicator's "reference count".
      NetworkIndicatorController.sharedIndicatorController.networkActivityDidEnd()
    }
  }
  
}

/// A singleton to manage a visual "reference count" on the network activity indicator.
private class NetworkIndicatorController
{
  // MARK: Properties
  
  static let sharedIndicatorController = NetworkIndicatorController()
  
  fileprivate var activityCount = 0
  
  fileprivate var visibilityTimer: Timer?
  
  // MARK: Methods
  
  func networkActivityDidStart()
  {
    assert(Thread.isMainThread, "Altering network activity indicator state can only be done on the main thread.")
    
    activityCount += 1
    
    updateIndicatorVisibility()
  }
  
  func networkActivityDidEnd()
  {
    assert(Thread.isMainThread, "Altering network activity indicator state can only be done on the main thread.")
    
    activityCount -= 1
    
    updateIndicatorVisibility()
  }
  
  fileprivate func updateIndicatorVisibility()
  {
    if activityCount > 0
    {
      showIndicator()
    }
    else
    {
      /*
       To prevent the indicator from flickering on and off, we delay the
       hiding of the indicator by one second. This provides the chance
       to come in and invalidate the timer before it fires.
       */
      visibilityTimer = Timer(interval: 1.0) {
        self.hideIndicator()
      }
    }
  }
  
  fileprivate func showIndicator()
  {
    visibilityTimer?.cancel()
    visibilityTimer = nil
    //NSApplication.shared().isNetworkActivityIndicatorVisible = true
  }
  
  fileprivate func hideIndicator()
  {
    visibilityTimer?.cancel()
    visibilityTimer = nil
    //NSApplication.shared().isNetworkActivityIndicatorVisible = false
  }
}

/// Essentially a cancellable `dispatch_after`.
class Timer
{
  // MARK: Properties
  
  fileprivate var isCancelled = false
  
  // MARK: Initialization
  
  init(interval: TimeInterval, handler: @escaping ()->())
  {
    let when = DispatchTime.now() + Double(Int64(interval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    
    DispatchQueue.main.asyncAfter(deadline: when) { [weak self] in
      if self?.isCancelled == false
      {
        handler()
      }
    }
  }
  
  func cancel()
  {
    isCancelled = true
  }
}
