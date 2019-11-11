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

import Cocoa
import RenderKit
import iRASPAKit
import CatchObjectiveCExceptions

// NOTE: When using the Custom mode, if pageController.view is layer backed, live layers are used during transition instead of snapshots
// NOTE: NSTableView is not thread safe! Do not tell NSTableView to reload its data while it is drawing on a second thread or it will crash.


// Custom: view is container, need to set arrangedObjects manual because you know what they are, and set appropriate selectedIndex
//
// step 1: pageController: (NSPageController*)pc identifierForObject:(id)page1
//         return same string as a identifier if you have one type of view
// step 2: not in cache? then call pageController:(NSPageController*)pc viewControllerForIndentifier:(NSString*) identifier
//         creates new viewcontroller, loads NIB and returns that
// step 3; at this point the view-controllers does need to vend a view
// step 4: pageController:(NSPageController*) pc preapreViewController:(NSViewController*) vc withObject:(id)page1
//         will be asked to draw a nil object, which is to be used as a blank to draw something 'appropriate'
// step 5: view can draw 'page1'
// step 6: 'newPage' is added as a subview to the container-view (users can not interact with it)
//
//
// now user wants to go to page2
// step 1: pageControllerWillStartLivetransition delegate-method is called
// step 2: snapshot of page1 is taken
// step 3: page2 does not exists yet, so call: pageController(NSPageController*) pc identifierForObject:(id)page2;
// step 4: call pageController: (NSPageController*)pc identifierForObject:(id)page2
// step 5: call pageController:(NSPageController*)pc viewControllerForIdentifier:(NSString*) identifier
// step 6: pageController:(NSPageController*) pc prepareViewController:(NSViewController*) vc withObject:(id)page2
// step 7: needs to draw page2 content, takes time, so it is drawn on background thread (need to prepare for that)
// step 8: in the mean-time, remember we took a nil-object? that snapshot is used or when we previously navigate to page2, then we have a snapshot
// step 9: remove current-view from the container-view, and in our pagecontroller custem transition view hierachy, we put the snapshots we do have there.
// step 10: when you complete your drawing on the background thread the view in the transition hierarchy will be updated,
// step 11: usually happens right away, but if it took time to draw it will fade in on the user
// step 12: so the user swiped to page 2 and that has been completed, so you get: pageControllerDidEndLiveTransition:
// step 13: needs to tell pagecontroller to complete the transition: completeTransition
//          often you can do this immediately and everything transitions to a live view
//          this removes the custom transition view hiearchy and replaces it with a new prepared view-controller with page2-content


class StructureAtomDetailViewPageController: NSPageController, WindowControllerConsumer, ProjectConsumer, NSPageControllerDelegate, PageStatusController, Reloadable
{
  weak var windowController: iRASPAWindowController?
  
  var selectedArrangedObjects: [Any] = []
  var swipeInProgress: Bool = false
  var animationInProgress: Bool = false
  
  deinit
  {
    //Swift.print("deinit: StructureAtomDetailViewPageController")
  }
  
  // MARK: protocol ProjectConsumer
  // ===============================================================================================================================
  
  weak var proxyProject: ProjectTreeNode?
  {
    didSet
    {
      self.representedObject = proxyProject?.representedObject.loadedProjectStructureNode
    }
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
  
  func reloadData()
  {
    if let viewController: StructureAtomDetailViewController  = self.selectedViewController as? StructureAtomDetailViewController
    {
      viewController.reloadData()
    }
  }
  
  func masterViewControllerTabChanged(tab: Int)
  {
    if let project = representedObject as? ProjectStructureNode
    {
      switch(tab)
      {
      case 0:
        self.arrangedObjects = [project.sceneList.selectedScene?.selectedMovie?.selectedFrame?.structure ?? [] ]
        self.selectedIndex = 0
      case 1:
        let movies: [Movie] = project.sceneList.scenes.flatMap{$0.movies}
        
        // atoms and bonds tab show a list of current-frames of all the movies
        let frames: [AnyObject] = movies.map{$0.selectedFrame?.structure ?? NSArray()}
        self.arrangedObjects = frames.isEmpty ? [[]] : frames
        
        if let selectedScene: Scene = project.sceneList.selectedScene,
          let sceneIndex: Int = project.sceneList.scenes.firstIndex(of: selectedScene),
          let selectedMovie: Movie = selectedScene.selectedMovie,
          let movieIndex: Int = selectedScene.movies.firstIndex(of: selectedMovie)
        {
          let selectionIndex: Int = project.sceneList.rowForSectionTuple(sceneIndex, movieIndex: movieIndex)
          self.selectedIndex = selectionIndex
        }
      case 2:
        if let selectedScene: Scene = project.sceneList.selectedScene,
          let selectionMovie: Movie = selectedScene.selectedMovie
        {
          let frames: [Structure] = selectionMovie.structureViewerStructures
          self.arrangedObjects = frames.isEmpty ? [[]] : frames
          
          if let selectedFrame: iRASPAStructure = selectionMovie.selectedFrame,
            let selectionIndex: Int = selectionMovie.frames.firstIndex(of: selectedFrame)
          {
            self.selectedIndex = selectionIndex
          }
        }
      default:
        break
      }
    }
    else
    {
      self.arrangedObjects = [[]]
      self.selectedIndex = 0
    }
  }
  
  func masterViewControllerSelectionChanged(tab: Int)
  {
    if let project = representedObject as? ProjectStructureNode
    {
      switch(tab)
      {
      case 0:
        break
      case 1:
        if let selectedScene: Scene = project.sceneList.selectedScene,
          let sceneIndex: Int = project.sceneList.scenes.firstIndex(of: selectedScene),
          let selectedMovie: Movie = selectedScene.selectedMovie,
          let movieIndex: Int = selectedScene.movies.firstIndex(of: selectedMovie)
        {
          let selectionIndex: Int = project.sceneList.rowForSectionTuple(sceneIndex, movieIndex: movieIndex)
          
          if let index: Int = (self.parent as? NSTabViewController)?.selectedTabViewItemIndex
          {
            switch(index)
            {
            case 5:
              self.transitionToNewIndex(selectionIndex)
            default:
              self.selectedIndex = selectionIndex
            }
          }
        }
      case 2:
        if let selectedScene: Scene = project.sceneList.selectedScene,
          let selectedMovie: Movie = selectedScene.selectedMovie,
          let selectedFrame: iRASPAStructure = selectedMovie.selectedFrame,
          let selectionIndex: Int = selectedMovie.frames.firstIndex(of: selectedFrame)
        {
          if let index: Int = (self.parent as? NSTabViewController)?.selectedTabViewItemIndex
          {
            switch(index)
            {
            case 5:
              self.transitionToNewIndex(selectionIndex)
            default:
              self.selectedIndex = selectionIndex
            }
          }
        }
      default:
        break
      }
    }
    else
    {
      self.selectedIndex = 0
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
        self.swipeInProgress = false
        NSAnimationContext.runAnimationGroup( { context in
          self.animator().selectedIndex = index
        }, completionHandler: {
          self.completeTransition()
          self.swipeInProgress = false
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
    return "StructureAtomDetailViewController"
  }
  
  
  // NSPageController will cache as many viewControllers and views as necessary to maintain performance. This method is called whenever
  // another instance is required. Note: The viewController may become the selectedViewController after a transition if necessary.
  func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController
  {
    let storyboard: NSStoryboard = NSStoryboard(name: "StructureAtomDetail", bundle: nil)
    return storyboard.instantiateController(withIdentifier: "StructureAtomDetailViewController") as! NSViewController
  }
  
  // Prepare the viewController and view for drawing. Setup data sources and perform layout. Note: this method is called on the main thread and should
  // return immediately. The view will be asked to draw on a background thread and must support background drawing. If this method is not implemented,
  // then viewController's representedObject is set to the representedObject.
  func pageController(_ pageController: NSPageController, prepare viewController: NSViewController, with object: Any?)
  {
    if let viewController: StructureAtomDetailViewController  = viewController as? StructureAtomDetailViewController
    {
      viewController.windowController = windowController
      viewController.representedObject = object
      viewController.proxyProject = self.proxyProject
      viewController.reloadData()
      
      
      // Updates the layout of the receiving view and its subviews based on the current views and constraints.
      // do this here on the main-thread to avoid the background-drawing taking too much time and dropping the live-snapshot
      //viewController.view.layoutSubtreeIfNeeded()
    }
  }
  
  // This message is sent when the user begins a transition wither via swipe gesture of one of the navigation IBAction methods
  func pageControllerWillStartLiveTransition(_ pageController: NSPageController)
  {
    swipeInProgress = true
  }
  
  // This message is sent when any page transition is completed.
  func pageController(_ pageController: NSPageController, didTransitionTo object: Any)
  {
    if swipeInProgress
    {
      windowController?.detailViewControllerSelectionChanged(index: selectedIndex)
    }
    swipeInProgress = false
  }
  
  // This message is sent when a transition animation completes either via swipe gesture or one of the navigation IBAction methods.
  // Your content view is still hidden and you must call -completeTransition; on pageController when your content is ready to show.
  // If completed successfully, a pageController:didTransitionToRepresentedObject: will already have been sent.
  func pageControllerDidEndLiveTransition(_ pageController: NSPageController)
  {
    pageController.completeTransition()
    swipeInProgress = false
  }
}
