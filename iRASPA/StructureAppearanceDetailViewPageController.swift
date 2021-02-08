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
import RenderKit
import iRASPAKit
import CatchObjectiveCExceptions

class StructureAppearanceDetailViewPageController: NSPageController, WindowControllerConsumer, ProjectConsumer, NSPageControllerDelegate, StructurePageController, Reloadable
{
  weak var windowController: iRASPAWindowController?
  
  var selectedArrangedObjects: [Any] = []
  var swipeStartingPhase: Bool = false
  var swipeInProgress: Bool = false
  var animationInProgress: Bool = false
  
  deinit
  {
    //Swift.print("deinit: StructureAppearanceDetailViewPageController")
  }
  
  // ViewDidLoad: bounds are not yet set (do not do geometry-related etup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    self.delegate = self
    self.transitionStyle = NSPageController.TransitionStyle.horizontalStrip
    self.arrangedObjects = [[]]
  }
  
  override func viewWillAppear()
  {
    super.viewWillAppear()
    
    self.reloadData()
  }
  
  // reloads the current atom-detailview-controller
  func reloadData()
  {
    if let viewController: StructureAppearanceDetailViewController  = self.selectedViewController as? StructureAppearanceDetailViewController
    {
      viewController.reloadData()
    }
  }
  
  
  // MARK: protocol ProjectConsumer
  // =====================================================================
  
  weak var proxyProject: ProjectTreeNode?
  {
    didSet
    {
      if let project: ProjectStructureNode = proxyProject?.representedObject.loadedProjectStructureNode
      {
        self.representedObject = project
        self.reloadData()
      }
      else
      {
        self.representedObject = nil
      }
    }
  }
  
  func setPageControllerObjects(arrangedObjects objects: [Any], selectedArrangedObjects selectedObjects: [Any], selectedIndex index: Int)
  {
    if let _ = representedObject as? ProjectStructureNode
    {
      self.selectedArrangedObjects = selectedObjects
      self.arrangedObjects = objects
      self.selectedIndex = index
    }
    else
    {
      self.selectedArrangedObjects = [[]]
      self.arrangedObjects = [[]]
      self.selectedIndex = 0
    }
  }
  
  func setPageControllerSelection(selectedArrangedObjects selectedObjects: [Any], selectedIndex index: Int, isActiveTab: Bool)
  {
    self.selectedArrangedObjects = selectedObjects
    if index != self.selectedIndex
    {
      if isActiveTab
      {
        self.transitionToNewIndex(index)
      }
      else
      {
        self.selectedIndex = index
      }
    }
    else
    {
      // update current viewController even if index remains the same
      if let selectedViewController = self.selectedViewController
      {
        self.pageController(self, prepare: selectedViewController, with: self.arrangedObjects[self.selectedIndex])
      }
    }
  }
  
  func transitionToNewIndex(_ index: Int)
  {
    if index >= 0 && index < self.arrangedObjects.count &&
      index != self.selectedIndex
    {
      // check animationInProgress to protect against CA-bug
      if !self.animationInProgress
      {
        self.animationInProgress = true
        self.swipeStartingPhase = false
        NSAnimationContext.runAnimationGroup( { context in
          self.animator().selectedIndex = index
        }, completionHandler: {
          self.completeTransition()
          self.swipeStartingPhase = false
          self.animationInProgress = false
        })
      }
      else
      {
        // if already in progress: just update the selectionIndex without animating
        self.selectedIndex = index
      }
    }
  }
  
  override func takeSelectedIndexFrom(_ sender: Any?)
  {
    super.takeSelectedIndexFrom(sender)
  }
  
  // Return the identifier of the view controller that owns a view to display the object. If NSPageController does not have an unused
  // viewController for this identifier, the you will be asked to create one via pageController:viewControllerForIdentifier.
  func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier
  {
    return "StructureAppearanceDetailViewController"
  }
  
  // NSPageController will cache as many viewControllers and views as necessary to maintain performance. This method is called whenever
  // another instance is required. Note: The viewController may become the selectedViewController after a transition if necessary.
  func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController
  {
    let storyboard: NSStoryboard = NSStoryboard(name: "StructureAppearanceDetail", bundle: nil)
    return storyboard.instantiateController(withIdentifier: "StructureAppearanceDetailViewController") as! NSViewController
  }
  
  // Prepare the viewController and view for drawing. Setup data sources and perform layout.
  func pageController(_ pageController: NSPageController, prepare viewController: NSViewController, with object: Any?)
  {
    if let viewController: StructureAppearanceDetailViewController  = viewController as? StructureAppearanceDetailViewController
    {
      viewController.windowController = windowController
      if swipeStartingPhase
      {
        viewController.representedObject = [object]
        swipeStartingPhase = false
      }
      else
      {
        viewController.representedObject = selectedArrangedObjects
      }
      
      viewController.proxyProject = self.proxyProject
      if let currentViewController = self.selectedViewController as? StructureAppearanceDetailViewController
      {
        viewController.expandedItems = currentViewController.expandedItems
      }
      viewController.reloadData()
    }
  }
  
  func pageControllerWillStartLiveTransition(_ pageController: NSPageController)
  {
    swipeStartingPhase = true
    swipeInProgress = true
  }
  
  func pageController(_ pageController: NSPageController, didTransitionTo object: Any)
  {
    swipeStartingPhase = false
    if swipeInProgress
    {
      selectedArrangedObjects = [object]
      windowController?.detailViewControllerSelectionChanged(index: selectedIndex)
    }
  }
  
  func pageControllerDidEndLiveTransition(_ pageController: NSPageController)
  {
    swipeStartingPhase = false
    swipeInProgress = false
    pageController.completeTransition()
  }
}
