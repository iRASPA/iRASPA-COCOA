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

import Cocoa
import iRASPAKit

class ProjectCollectionViewItem: NSCollectionViewItem
{
  
  override var highlightState: NSCollectionViewItem.HighlightState
  {
    didSet
    {
      super.highlightState = highlightState
      (self.view as? ProjectSlideCarrierView)?.highlightState = highlightState
    }
  }
  
  
  override var isSelected: Bool
  {
    didSet
    {
      super.isSelected = isSelected
      (self.view as? ProjectSlideCarrierView)?.isSelected = isSelected
    }
  }
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    
    let click = NSClickGestureRecognizer(target: self, action: #selector(ProjectCollectionViewItem.click(gesture:)))
    click.numberOfClicksRequired = 2
    view.addGestureRecognizer(click)
  }
  
  func updateColor()
  {
    if isSelected {
      switch highlightState
      {
      case .none, .forDeselection:
        view.layer?.backgroundColor = NSColor.red.cgColor
      case .forSelection:
        view.layer?.backgroundColor = NSColor.green.cgColor
      default: break
      }
    }
    else
    {
      view.layer?.backgroundColor = NSColor.white.cgColor
    }
  }
  
  @objc func click(gesture: NSClickGestureRecognizer)
  {
    let _ = gesture.location(in: view)
    
    if let windowController = self.view.window?.windowController as? iRASPAWindowController,
      let document: iRASPADocument = windowController.document as? iRASPADocument,
      let node: ProjectTreeNode = self.representedObject as? ProjectTreeNode
    {
      let projectController: ProjectTreeController = document.documentData.projectData
    
      // set window to 'Structure visualization'-mode
      windowController.detailTabViewController?.selectedTabViewItemIndex = DetailTabViewController.ProjectViewType.structureVisualisation.rawValue
      
      if projectController.contains(node)
      {
        projectController.selectedTreeNodes = [node]
        projectController.selectedTreeNode = node
      }
      
      windowController.masterTabViewController?.masterViewController?.projectViewController?.switchToCurrentProject()
      windowController.masterTabViewController?.masterViewController?.projectViewController?.reloadData()
      
    }
  }
}
