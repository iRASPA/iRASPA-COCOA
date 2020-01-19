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
 A subclass of `Operation` that executes zero or more operations as part of its
 own execution. This class of operation is very useful for abstracting several
 smaller operations into a larger operation. As an example, the `GetEarthquakesOperation`
 is composed of both a `DownloadEarthquakesOperation` and a `ParseEarthquakesOperation`.
 
 Additionally, `GroupOperation`s are useful if you establish a chain of dependencies,
 but part of the chain may "loop". For example, if you have an operation that
 requires the user to be authenticated, you may consider putting the "login"
 operation inside a group operation. That way, the "login" operation may produce
 subsequent operations (still within the outer `GroupOperation`) that will all
 be executed before the rest of the operations in the initial chain of operations.
 */
open class FKGroupOperation: FKOperation
{
  fileprivate let internalQueue = FKOperationQueue()
  fileprivate let startingOperation = BlockOperation(block: {})
  fileprivate let finishingOperation = BlockOperation(block: {})
  
  fileprivate var aggregatedErrors = [NSError]()
  
  /// A lock to guard reads and writes to the `aggregatedErrors` property
  fileprivate let aggregatedErrorsLock = NSLock()
  
  convenience init(operations: Operation...)
  {
    self.init(operations: operations)
  }
  
  public override init()
  {
    super.init()
    
    internalQueue.isSuspended = true
    internalQueue.delegate = self
    internalQueue.addOperation(startingOperation)
  }
  
  public init(operations: [Operation])
  {
    super.init()
    
    internalQueue.isSuspended = true
    internalQueue.delegate = self
    internalQueue.addOperation(startingOperation)
    
    for operation in operations
    {
      internalQueue.addOperation(operation)
    }
  }
  
  override open func cancel()
  {
    internalQueue.cancelAllOperations()
    super.cancel()
  }
  
  override open func execute()
  {
    internalQueue.isSuspended = false
    internalQueue.addOperation(finishingOperation)
  }
  
  public func addOperation(_ operation: Operation)
  {
    internalQueue.addOperation(operation)
  }
  
  public func addOperations(_ operations: [Operation])
  {
    operations.forEach{internalQueue.addOperation($0)}
  }

  
  /**
   Note that some part of execution has produced an error.
   Errors aggregated through this method will be included in the final array
   of errors reported to observers and to the `finished(_:)` method.
   */
  final func aggregateError(_ error: NSError)
  {
    aggregatedErrors.append(error)
  }
  
  open func operationDidFinish(_ operation: Operation, withErrors errors: [NSError])
  {
    // For use by subclassers.
  }
}

extension FKGroupOperation: FKOperationQueueDelegate
{
  final func operationQueue(_ operationQueue: OperationQueue, willAddOperation operation: Operation) {
    assert(!finishingOperation.isFinished && !finishingOperation.isExecuting, "cannot add new operations to a group after the group has completed")
    
    /*
     Some operation in this group has produced a new operation to execute.
     We want to allow that operation to execute before the group completes,
     so we'll make the finishing operation dependent on this newly-produced operation.
     */
    if operation !== finishingOperation
    {
      finishingOperation.addDependency(operation)
    }
    
    /*
     All operations should be dependent on the "startingOperation".
     This way, we can guarantee that the conditions for other operations
     will not evaluate until just before the operation is about to run.
     Otherwise, the conditions could be evaluated at any time, even
     before the internal operation queue is unsuspended.
     */
    if operation !== startingOperation
    {
      operation.addDependency(startingOperation)
    }
  }
  
  
  
  final func operationQueue(_ operationQueue: OperationQueue, operationDidFinish operation: Operation, withErrors errors: [NSError])
  {
    aggregatedErrorsLock.withCriticalScope {
      aggregatedErrors.append(contentsOf: errors)
    }
    
    
    if operation === finishingOperation
    {
      internalQueue.isSuspended = true
      aggregatedErrorsLock.withCriticalScope {
        finish(aggregatedErrors)
      }
    }
    else if operation !== startingOperation
    {
      operationDidFinish(operation, withErrors: errors)
    }
  }
}

