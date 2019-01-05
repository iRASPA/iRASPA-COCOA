//
//  SingleProjectImportOperation.swift
//  iRASPA
//
//  Created by David Dubbeldam on 29/04/2017.
//  Copyright © 2017 David Dubbeldam. All rights reserved.
//

import Foundation
import FoundationKit

public class SingleProjectImportOperation: FKGroupOperation
{
  private var progressViewKVOContext = 0
  
  var projectProxy : ProjectProxy
  var outlineView: NSOutlineView
  
  let progress: Progress
  
  public init(projectProxy: ProjectProxy, outlineView: NSOutlineView, urls: [URL])
  {
    // Do this in init, so that our NSProgress instance is parented to the current one in the thread that created the operation
    // This progress's children are weighted, the reading takes 10% and the computation of the bonds takes the remaining portion
    
    self.outlineView = outlineView
    self.projectProxy = projectProxy
    let windowController: NSWindowController? = outlineView.window?.windowController
    
    
    let cancelHandler: () -> () = {}
    
    
    
    
    // create a new Progress-object (Progress-objects can not be resused)
    progress = Progress.discreteProgress(totalUnitCount: 100)
    progress.completedUnitCount = 0
    
    let readStructureOperation: ReadStructureGroupOperation = ReadStructureGroupOperation(urls: urls, cancelHandler: cancelHandler, windowController: windowController)
    progress.addChild(readStructureOperation.progress, withPendingUnitCount: 20)
    
    super.init(operations:  [readStructureOperation])
    
    let adapterOperation = BlockOperation(block: {
      let sceneList: SceneList = SceneList(arrangedObjects: readStructureOperation.operations.flatMap{$0.parser?.scene})
      let projectStructureNode: ProjectStructureNode = ProjectStructureNode(name: projectProxy.displayName, sceneList: sceneList)
      projectProxy.representedObject = projectStructureNode
      projectStructureNode.sceneList.structures.forEach{$0.parentProject = projectStructureNode}
      
      let computeBondsGroupOperation: ComputeBondsGroupOperation = ComputeBondsGroupOperation(structures: projectStructureNode.sceneList.structures, cancelHandler: cancelHandler, windowController: windowController)
      self.progress.addChild(computeBondsGroupOperation.progress, withPendingUnitCount: 80)
      
      self.addOperation(computeBondsGroupOperation)
    })
    
    adapterOperation.addDependency(readStructureOperation)
    self.addOperation(adapterOperation)
    
    progress.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options: [.new], context: &progressViewKVOContext)
    
    completionBlock = {
      self.progress.completedUnitCount = 100
      
      DispatchQueue.main.async {
        
        let row = self.outlineView.row(forItem: self.projectProxy)
        if (row>=0)
        {
          self.projectProxy.status = .ready
          self.outlineView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
          
          
        }
        
        self.progress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
      }
    }
  }
  
  
  
  
  override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
  {
    if context == &progressViewKVOContext,
      keyPath == "fractionCompleted",
      let newProgress = object as? Progress,
      newProgress == progress
    {
      //call my delegate here that updates the UI
      DispatchQueue.main.async(execute: {
        // check that the node still exists (it does not when closing the app, but this background process is still running)
        let row = self.outlineView.row(forItem: self.projectProxy)
        if let view: ProjectTableCellView = self.outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as?  ProjectTableCellView, row >= 0
        {
          view.progressIndicator?.doubleValue = newProgress.fractionCompleted
        }
      })
    }
    else
    {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }

  }
  
  
  /*
  // after the import-operation, remove the progress-indicator
  let cancelHandler: () -> () = {[unowned self] () -> Void in
    assert(Thread.isMainThread)
    let row=self.projectOutlineView.row(forItem: node)
    if (row>=0)
    {
      let projectData: FKTreeController< ProjectProxy > = document.documentData.projectData
      projectData.removeNode(node)
      
      let fromItem: Any? = node.isRootNode() ? self.contents[1] : node.parentNode
      let childIndex: Int = self.projectOutlineView.childIndex(forItem: node)
      self.projectOutlineView.removeItems(at: IndexSet(integer: childIndex), inParent: fromItem, withAnimation: .slideLeft)
      let parentRow: Int = self.projectOutlineView.row(forItem: fromItem)
      if (parentRow > 0)
      {
        self.projectOutlineView.reloadData(forRowIndexes: IndexSet(integer: parentRow), columnIndexes: IndexSet(integer: 0))
      }
    }
  }*/
}
