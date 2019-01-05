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
import OperationKit
import SimulationKit
import SymmetryKit

public class ImportProjectOperation: FKGroupOperation
{
  private var lock: NSLock = NSLock()
  private var progressViewKVOContext = 0
  
  unowned var projectTreeNode : ProjectTreeNode
  weak var outlineView: NSOutlineView?
  
  unowned let treeController: ProjectTreeController
  
  public init(projectTreeNode: ProjectTreeNode, outlineView: NSOutlineView?, treeController: ProjectTreeController, colorSets: SKColorSets, forceFieldSets: SKForceFieldSets, urls: [URL], onlyAsymmetricUnit: Bool)
  {
    self.outlineView = outlineView
    self.projectTreeNode = projectTreeNode
    self.treeController = treeController
    let windowController: NSWindowController? = outlineView?.window?.windowController
    
    super.init()
    

    // create a new Progress-object (Progress-objects can not be resused)
    // Do this in init, so that our NSProgress instance is parented to the current one in the thread that created the operation
    // This progress's children are weighted, the reading takes 20% and the computation of the bonds takes the remaining portion
    progress = Progress.discreteProgress(totalUnitCount: 100)
    progress.completedUnitCount = 0
    
    
    let readStructureOperation: ReadStructureGroupOperation = ReadStructureGroupOperation(projectTreeNode: projectTreeNode, urls: urls, windowController: windowController, colorSets: colorSets, forceFieldSets: forceFieldSets, onlyAsymmetricUnit: onlyAsymmetricUnit)
    progress.addChild(readStructureOperation.progress, withPendingUnitCount: 20)
    
    self.addOperation(readStructureOperation)
    
    let adapterOperation = BlockOperation(block: {[weak self, unowned readStructureOperation] in
      let sceneList: SceneList = SceneList(scenes: readStructureOperation.scenes)
      let projectStructureNode: ProjectStructureNode = ProjectStructureNode(name: projectTreeNode.displayName, sceneList: sceneList)
      projectTreeNode.representedObject = iRASPAProject(structureProject: projectStructureNode)
      
      // set parent reference
      //projectStructureNode.sceneList.structureViewerStructures.forEach{$0.parentProject = projectStructureNode}
      
      // set default colorset etc.
      projectStructureNode.sceneList.structureViewerStructures.forEach{$0.setRepresentationStyle(style: .default, colorSets: colorSets)}
      
      let computeBondsGroupOperation: ComputeBondsGroupOperation = ComputeBondsGroupOperation(structures: projectStructureNode.sceneList.structureViewerStructures, windowController: windowController)
      self?.progress.addChild(computeBondsGroupOperation.progress, withPendingUnitCount: 80)
      
      self?.addOperation(computeBondsGroupOperation)
    })
    
    adapterOperation.addDependency(readStructureOperation)
    self.addOperation(adapterOperation)
 
    
    progress.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options: [.new], context: &progressViewKVOContext)
    
    completionBlock = {
      self.progress.completedUnitCount = 100
      self.progress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted))
      if (self.isCancelled)
      {
        DispatchQueue.main.async {
          if let row=self.outlineView?.row(forItem: self.projectTreeNode), row >= 0
          {
            self.outlineView?.beginUpdates()
            self.treeController.removeNode(self.projectTreeNode)
            
            let fromItem: Any? = self.outlineView?.parent(forItem: self.projectTreeNode)
            if let childIndex: Int = self.outlineView?.childIndex(forItem: self.projectTreeNode)
            {
              self.outlineView?.removeItems(at: IndexSet(integer: childIndex), inParent: fromItem, withAnimation: .slideLeft)
            }
            self.outlineView?.endUpdates()
            
            
          }
        }
      }
      else
      {
        DispatchQueue.main.async {
          if let row = self.outlineView?.row(forItem: self.projectTreeNode), row >= 0
          {
            self.projectTreeNode.representedObject.isEdited = true  // make sure it is saved
            //self.projectTreeNode.status = .ready
            self.outlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
            //Swift.print("type: \(type(of: self.projectTreeNode.representedObject!))")
          }
        }
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
        if let row = self.outlineView?.row(forItem: self.projectTreeNode), row >= 0
        {
          if let view: ProgressIndicator = self.outlineView?.view(atColumn: 0, row: row, makeIfNecessary: false) as?  ProgressIndicator
          {
            view.progressIndicator?.doubleValue = newProgress.fractionCompleted
          }
        }
      })
    }
    else
    {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
    
  }
  
}

