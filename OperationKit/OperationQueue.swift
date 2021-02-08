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

import Foundation

/**
 The delegate of an `OperationQueue` can respond to `Operation` lifecycle
 events by implementing these methods.
 
 In general, implementing `OperationQueueDelegate` is not necessary; you would
 want to use an `OperationObserver` instead. However, there are a couple of
 situations where using `OperationQueueDelegate` can lead to simpler code.
 For example, `GroupOperation` is the delegate of its own internal
 `OperationQueue` and uses it to manage dependencies.
 */
@objc protocol FKOperationQueueDelegate: NSObjectProtocol
{
  @objc optional func operationQueue(_ operationQueue: OperationQueue, willAddOperation operation: Operation)
  @objc optional func operationQueue(_ operationQueue: OperationQueue, operationDidFinish operation: Operation, withErrors errors: [NSError])
}

/**
 `OperationQueue` is an `NSOperationQueue` subclass that implements a large
 number of "extra features" related to the `Operation` class:
 
 - Notifying a delegate of all operation completion
 - Extracting generated dependencies from operation conditions
 - Setting up dependencies to enforce mutual exclusivity
 */
public class FKOperationQueue: OperationQueue
{
  weak var delegate: FKOperationQueueDelegate?
  
  override public func addOperation(_ operation: Operation)
  {
    if let op = operation as? FKOperation
    {
      // Set up a `BlockObserver` to invoke the `OperationQueueDelegate` method.
      let delegate = FKBlockObserver(
        startHandler: nil,
        produceHandler: { [weak self] in
          self?.addOperation($1)
        },
        finishHandler: { [weak self] in
          if let q = self {
            q.delegate?.operationQueue?(q, operationDidFinish: $0, withErrors: $1)
          }
        }
      )
      op.addObserver(delegate)
      
      // Extract any dependencies needed by this operation.
      let dependencies = op.conditions.compactMap{$0.dependencyForOperation(op)}
      
      for dependency in dependencies
      {
        op.addDependency(dependency)
        self.addOperation(dependency)
      }
      
      /*
       With condition dependencies added, we can now see if this needs
       dependencies to enforce mutual exclusivity.
       */
      let concurrencyCategories: [String] = op.conditions.compactMap { condition in
        if !type(of: condition).isMutuallyExclusive { return nil }
        
        return "\(type(of: condition))"
      }
      
      if !concurrencyCategories.isEmpty
      {
        // Set up the mutual exclusivity dependencies.
        let exclusivityController = FKExclusivityController.sharedExclusivityController
        
        exclusivityController.addOperation(op, categories: concurrencyCategories)
        
        let observer = FKBlockObserver(finishHandler:  {[weak exclusivityController]  (operation: Operation, error: [NSError]) -> () in
          exclusivityController?.removeOperation(operation, categories: concurrencyCategories)
        })
        op.addObserver(observer)
      }
      
      /*
       Indicate to the operation that we've finished our extra work on it
       and it's now it a state where it can proceed with evaluating conditions,
       if appropriate.
       */
      op.willEnqueue()
    }
    else
    {
      /*
       For regular `NSOperation`s, we'll manually call out to the queue's
       delegate we don't want to just capture "operation" because that
       would lead to the operation strongly referencing itself and that's
       the pure definition of a memory leak.
       */
      operation.addCompletionBlock { [weak self, weak operation] in
        guard let queue = self, let operation = operation else { return }
        queue.delegate?.operationQueue?(queue, operationDidFinish: operation, withErrors: [])
      }
    }
 
    
    delegate?.operationQueue?(self, willAddOperation: operation)
 
    super.addOperation(operation)
  }
  
  override public func addOperations(_ operations: [Operation], waitUntilFinished wait: Bool)
  {
    /*
     The base implementation of this method does not call `addOperation()`,
     so we'll call it ourselves.
     */
    for operation in operations
    {
      addOperation(operation)
    }
    
    if wait
    {
      for operation in operations
      {
        operation.waitUntilFinished()
      }
    }
  }
}


