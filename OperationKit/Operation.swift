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

/**
 The subclass of `NSOperation` from which all other operations should be derived.
 This class adds both Conditions and Observers, which allow the operation to define
 extended readiness requirements, as well as notify many interested parties
 about interesting operation state changes
 */
open class FKOperation: Operation, ProgressReporting
{
  open var progress: Progress = Progress()
  
  // use the KVO mechanism to indicate that changes to "state" affect other properties as well
  @objc dynamic class func keyPathsForValuesAffectingIsReady() -> Set<NSObject>
  {
    return ["state" as NSObject]
  }
  
  @objc dynamic class func keyPathsForValuesAffectingIsExecuting() -> Set<NSObject>
  {
    return ["state" as NSObject]
  }
  
  @objc dynamic class func keyPathsForValuesAffectingIsFinished() -> Set<NSObject>
  {
    return ["state" as NSObject]
  }
  
  // MARK: State Management
  
  fileprivate enum State: Int, Comparable
  {
    /// The initial state of an `Operation`.
    case initialized
    
    /// The `Operation` is ready to begin evaluating conditions.
    case pending
    
    /// The `Operation` is evaluating conditions.
    case evaluatingConditions
    
    /**
     The `Operation`'s conditions have all been satisfied, and it is ready
     to execute.
     */
    case ready
    
    /// The `Operation` is executing.
    case executing
    
    /**
     Execution of the `Operation` has finished, but it has not yet notified
     the queue of this.
     */
    case finishing
    
    /// The `Operation` has finished executing.
    case finished
    
    func canTransitionToState(_ target: State) -> Bool
    {
      switch (self, target) {
      case (.initialized, .pending):
        return true
      case (.pending, .evaluatingConditions):
        return true
      case (.evaluatingConditions, .ready):
        return true
      case (.ready, .executing):
        return true
      case (.ready, .finishing):
        return true
      case (.executing, .finishing):
        return true
      case (.finishing, .finished):
        return true
      default:
        return false
      }
    }
  }
  
  /**
   Indicates that the Operation can now begin to evaluate readiness conditions,
   if appropriate.
   */
  func willEnqueue()
  {
    state = .pending
  }
  
  /// Private storage for the `state` property that will be KVO observed.
  fileprivate var _state = State.initialized
  
  /// A lock to guard reads and writes to the `_state` property
  fileprivate let stateLock = NSLock()
  
  fileprivate var state: State
  {
    get
    {
      return stateLock.withCriticalScope
      {
        _state
      }
    }
    
    set(newState)
    {
      /*
       It's important to note that the KVO notifications are NOT called from inside
       the lock. If they were, the app would deadlock, because in the middle of
       calling the `didChangeValueForKey()` method, the observers try to access
       properties like "isReady" or "isFinished". Since those methods also
       acquire the lock, then we'd be stuck waiting on our own lock. It's the
       classic definition of deadlock.
       */
      willChangeValue(forKey: "state")
      
      stateLock.withCriticalScope { 
        guard _state != .finished else {
          return
        }
        
        //assert(_state.canTransitionToState(newState), "Performing invalid state transition.")
        _state = newState
      }
      
      didChangeValue(forKey: "state")
    }
  }
  
  // Here is where we extend our definition of "readiness".
  override open var isReady: Bool
  {
    switch state
    {
      
    case .initialized:
      // If the operation has been cancelled, "isReady" should return true
      return isCancelled
      
    case .pending:
      // If the operation has been cancelled, "isReady" should return true
      guard !isCancelled else {
        return true
      }
      
      // If super isReady, conditions can be evaluated
      if super.isReady
      {
        evaluateConditions()
      }
      
      // Until conditions have been evaluated, "isReady" returns false
      return false
      
    case .ready:
      return super.isReady || isCancelled
      
    default:
      return false
    }
  }
  
  var userInitiated: Bool
  {
    get
    {
      return qualityOfService == .userInitiated
    }
    
    set
    {
      assert(state < .executing, "Cannot modify userInitiated after execution has begun.")
      
      qualityOfService = newValue ? .userInitiated : .default
    }
  }
  
  override open var isExecuting: Bool
  {
    return state == .executing
  }
  
  override open var isFinished: Bool
  {
    return state == .finished
  }
  
  fileprivate func evaluateConditions()
  {
    assert(state == .pending && !isCancelled, "evaluateConditions() was called out-of-order")
    
    state = .evaluatingConditions
    
    FKOperationConditionEvaluator.evaluate(conditions, operation: self) { failures in
      self.stateLock.lock()
      self._internalErrors.append(contentsOf: failures)
      self.stateLock.unlock()
      self.state = .ready
    }
  }
  
  // MARK: Observers and Conditions
  
  fileprivate(set) var conditions = [FKOperationCondition]()
  
  func addCondition(_ condition: FKOperationCondition)
  {
    assert(state < .evaluatingConditions, "Cannot modify conditions after execution has begun.")
    
    conditions.append(condition)
  }
  
  fileprivate(set) var observers = [FKOperationObserver]()
  
  func addObserver(_ observer: FKOperationObserver)
  {
    assert(state < .executing, "Cannot modify observers after execution has begun.")
    
    observers.append(observer)
  }
  
  open override func addDependency(_ operation: Operation)
  {
    assert(state < .executing, "Dependencies cannot be modified after execution has begun.")
    
    super.addDependency(operation)
  }
  
  

  
  // MARK: Execution and Cancellation
  
  override final public func start()
  {
    // NSOperation.start() contains important logic that shouldn't be bypassed.
    super.start()
    
    // If the operation has been cancelled, we still need to enter the "Finished" state.
    if isCancelled
    {
      finish()
    }
  }
  
  override final public func main()
  {
    assert(state == .ready, "This operation must be performed on an operation queue.")
    
    if _internalErrors.isEmpty && !isCancelled
    {
      state = .executing
      
      for observer in observers
      {
        observer.operationDidStart(self)
      }
      
      execute()
    }
    else
    {
      finish()
    }
  }
  
  /**
   `execute()` is the entry point of execution for all `Operation` subclasses.
   If you subclass `Operation` and wish to customize its execution, you would
   do so by overriding the `execute()` method.
   
   At some point, your `Operation` subclass must call one of the "finish"
   methods defined below; this is how you indicate that your operation has
   finished its execution, and that operations dependent on yours can re-evaluate
   their readiness state.
   */
  open func execute()
  {
    print("\(type(of: self)) must override `execute()`.")
    
    finish()
  }
  
  fileprivate var _internalErrors = [NSError]()
  func cancelWithError(_ error: NSError? = nil)
  {
    if let error = error
    {
      _internalErrors.append(error)
    }
    
    cancel()
  }
  
  final func produceOperation(_ operation: FKOperation)
  {
    for observer in observers
    {
      observer.operation(self, didProduceOperation: operation)
    }
  }
  
  // MARK: Finishing
  
  /**
   Most operations may finish with a single error, if they have one at all.
   This is a convenience method to simplify calling the actual `finish()`
   method. This is also useful if you wish to finish with an error provided
   by the system frameworks. As an example, see `DownloadEarthquakesOperation`
   for how an error from an `NSURLSession` is passed along via the
   `finishWithError()` method.
   */
  public final func finishWithError(_ error: NSError?)
  {
    if let error = error
    {
      finish([error])
    }
    else
    {
      finish()
    }
  }
  
  /**
   A private property to ensure we only notify the observers once that the
   operation has finished.
   */
  fileprivate var hasFinishedAlready = false
  final func finish(_ errors: [NSError] = [])
  {
    if !hasFinishedAlready
    {
      hasFinishedAlready = true
      state = .finishing
      
      let combinedErrors = _internalErrors + errors
      finished(combinedErrors)
      
      for observer in observers
      {
        observer.operationDidFinish(self, errors: combinedErrors)
      }
      
      state = .finished
    }
  }
  
  /**
   Subclasses may override `finished(_:)` if they wish to react to the operation
   finishing with errors. For example, the `LoadModelOperation` implements
   this method to potentially inform the user about an error when trying to
   bring up the Core Data stack.
   */
  open func finished(_ errors: [NSError])
  {
    // No op.
  }
  
  override final public func waitUntilFinished()
  {
    /*
     Waiting on operations is almost NEVER the right thing to do. It is
     usually superior to use proper locking constructs, such as `dispatch_semaphore_t`
     or `dispatch_group_notify`, or even `NSLocking` objects. Many developers
     use waiting when they should instead be chaining discrete operations
     together using dependencies.
     
     To reinforce this idea, invoking `waitUntilFinished()` will crash your
     app, as incentive for you to find a more appropriate way to express
     the behavior you're wishing to create.
     */
    //super.waitUntilFinished()
    
    fatalError("Waiting on operations is an anti-pattern. Remove this ONLY if you're absolutely sure there is No Other Way™.")
  }
  
}

// Simple operator functions to simplify the assertions used above.
private func <(lhs: FKOperation.State, rhs: FKOperation.State) -> Bool
{
  return lhs.rawValue < rhs.rawValue
}

private func ==(lhs: FKOperation.State, rhs: FKOperation.State) -> Bool
{
  return lhs.rawValue == rhs.rawValue
}

