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

/**
 `DelayOperation` is an `Operation` that will simply wait for a given time
 interval, or until a specific `NSDate`.
 
 It is important to note that this operation does **not** use the `sleep()`
 function, since that is inefficient and blocks the thread on which it is called.
 Instead, this operation uses `dispatch_after` to know when the appropriate amount
 of time has passed.
 
 If the interval is negative, or the `NSDate` is in the past, then this operation
 immediately finishes.
 */
public class DelayOperation: FKOperation, @unchecked Sendable
{
  // MARK: Types
  
  private enum Delay
  {
    case Interval(TimeInterval)
    case Date(NSDate)
  }
  
  // MARK: Properties
  
  private let delay: Delay
  
  // MARK: Initialization
  
  public init(interval: TimeInterval)
  {
    delay = .Interval(interval)
    super.init()
  }
  
  public init(until date: NSDate)
  {
    delay = .Date(date)
    super.init()
  }
  
  public override func execute()
  {
    let interval: TimeInterval
    
    // Figure out how long we should wait for.
    switch delay
    {
    case .Interval(let theInterval):
      interval = theInterval
      
    case .Date(let date):
      interval = date.timeIntervalSinceNow
    }
    
    guard interval > 0 else {
      finish()
      return
    }
    
    let when = DispatchTime.now() + Double(Int64(interval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).asyncAfter(deadline: when)
    {
      // If we were cancelled, then finish() has already been called.
      if !self.isCancelled
      {
        self.finish()
      }
    }
  }
  
  public override func cancel()
  {
    super.cancel()
    // Cancelling the operation means we don't want to wait anymore.
    self.finish()
  }
}

