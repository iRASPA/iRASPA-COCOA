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

import Foundation

/**
  `TimeoutObserver` is a way to make an `Operation` automatically time out and
cancel after a specified time interval.
*/

struct TimeoutObserver: FKOperationObserver
{
  // MARK: Properties
  
  static let timeoutKey = "Timeout"
  
  fileprivate let timeout: TimeInterval
  
  // MARK: Initialization
  
  init(timeout: TimeInterval) {
    self.timeout = timeout
  }
  
  // MARK: OperationObserver
  
  func operationDidStart(_ operation: FKOperation) {
    // When the operation starts, queue up a block to cause it to time out.
    let when = DispatchTime.now() + Double(Int64(timeout * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    
    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).asyncAfter(deadline: when) {
      /*
       Cancel the operation if it hasn't finished and hasn't already
       been cancelled.
       */
      if !operation.isFinished && !operation.isCancelled {
        let error = NSError(code: .executionFailed, userInfo: [
          type(of: self).timeoutKey: self.timeout
          ])
        
        operation.cancelWithError(error)
      }
    }
  }
  
  func operation(_ operation: FKOperation, didProduceOperation newOperation: FKOperation) {
    // No op.
  }
  
  func operationDidFinish(_ operation: FKOperation, errors: [NSError]) {
    // No op.
  }
}
