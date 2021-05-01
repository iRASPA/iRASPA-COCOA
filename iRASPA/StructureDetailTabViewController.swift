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

import Cocoa

protocol StructurePageController: AnyObject
{
  func setPageControllerObjects(arrangedObjects objects: [Any], selectedArrangedObjects selectedObjects: [Any], selectedIndex index: Int)
  func setPageControllerSelection(selectedArrangedObjects selectedObjects: [Any], selectedIndex index: Int, isActiveTab: Bool)
}

protocol FramePageController: AnyObject
{
  func setPageControllerFrameObject(arrangedObjects objects: [Any], selectedIndex index: Int)
  func setPageControllerFrameSelection(selectedIndex index: Int, isActiveTab: Bool)
}


class StructureDetailTabViewController: NSTabViewController, WindowControllerConsumer, StructurePageController, FramePageController, Reloadable
{
  weak var windowController: iRASPAWindowController?
  

  // ViewDidLoad: bounds are not yet set (do not do geometry-related etup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    self.selectedTabViewItemIndex = 0
  }
  
  func reloadData()
  {
    let selectedTabIndex: Int = self.selectedTabViewItemIndex
    if let structurePageController: Reloadable = self.tabViewItems[selectedTabIndex].viewController as? Reloadable
    {
      structurePageController.reloadData()
    }
  }
  
  
  // MARK: StructurePageController protocol
  // ========================================================================================
  
  func setPageControllerObjects(arrangedObjects objects: [Any], selectedArrangedObjects selectedObjects: [Any], selectedIndex index: Int)
  {
    for child in self.children
    {
      if let structurePageController: StructurePageController = child as? StructurePageController
      {
        structurePageController.setPageControllerObjects(arrangedObjects: objects, selectedArrangedObjects: selectedObjects, selectedIndex: index)
      }
    }
    self.reloadData()
  }
  
  
  
  func setPageControllerSelection(selectedArrangedObjects selectedObjects: [Any], selectedIndex index: Int, isActiveTab: Bool)
  {
    for child in self.children
    {
      if let structurePageController: StructurePageController = child as? StructurePageController,
        let tabViewItem = self.tabViewItem(for: child)
      {
        structurePageController.setPageControllerSelection(selectedArrangedObjects: selectedObjects, selectedIndex: index, isActiveTab: tabViewItem.tabState == NSTabViewItem.State.selectedTab)
      }
    }
  }
  
  // MARK: FramePageController protocol
   // ========================================================================================
   
  
  func setPageControllerFrameObject(arrangedObjects objects: [Any], selectedIndex index: Int)
  {
    for child in self.children
    {
      if let structurePageController: FramePageController = child as? FramePageController
      {
        structurePageController.setPageControllerFrameObject(arrangedObjects: objects, selectedIndex: index)
      }
    }
    self.reloadData()
  }
  
  func setPageControllerFrameSelection(selectedIndex index: Int, isActiveTab: Bool)
  {
    for child in self.children
    {
      if let structurePageController: FramePageController = child as? FramePageController,
         let tabViewItem = self.tabViewItem(for: child)
      {
        structurePageController.setPageControllerFrameSelection(selectedIndex: index, isActiveTab: tabViewItem.tabState == NSTabViewItem.State.selectedTab)
      }
    }
  }
  
}
