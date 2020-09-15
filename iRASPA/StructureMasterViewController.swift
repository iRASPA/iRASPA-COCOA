/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import iRASPAKit

/// StructureMasterViewController controls the SegmentedControl to select
/// the "Project Viewer", "Scene Viewer", and the "Frame Viewer'
/// Note: The TabViewController is "self.children.first"
class StructureMasterViewController: NSViewController, WindowControllerConsumer, ProjectController, SelectionIndex, Reloadable
{
  @IBOutlet weak var segmentedControl: NSSegmentedControl?
  
  weak var windowController: iRASPAWindowController?
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
  }
  
  func reloadData()
  {
    if let tabViewController: NSTabViewController = self.children.first as? NSTabViewController
    {
      let index = tabViewController.selectedTabViewItemIndex
      if let viewController = tabViewController.tabViewItems[index].viewController as? Reloadable
      {
        viewController.reloadData()
      }
    }
  }
  
  func initializeData()
  {
    if let tabViewController: NSTabViewController = self.children.first as? NSTabViewController
    {
      // foward to ProjectViewController
      (tabViewController.tabViewItems[0].viewController as? ProjectViewController)?.initializeData()
    }
  }
  
  
  func importFileOpenPanel()
  {
    if let tabViewController: NSTabViewController = self.children.first as? NSTabViewController
    {
      // foward to ProjectViewController
      (tabViewController.tabViewItems[0].viewController as? ProjectViewController)?.importFileOpenPanel()
    }
  }
  
  func switchToCurrentProject()
  {
    if let tabViewController: NSTabViewController = self.children.first as? NSTabViewController
    {
      // foward to ProjectViewController
      (tabViewController.tabViewItems[0].viewController as? ProjectViewController)?.switchToCurrentProject()
    }
  }
  
  var projectsView: NSView?
  {
    if let tabViewController: NSTabViewController = self.children.first as? NSTabViewController
    {
      // foward to ProjectViewController
      return (tabViewController.tabViewItems[0].viewController as? ProjectViewController)?.projectView
    }
    return nil
  }
  
  func setSelectionIndex(index: Int)
  {
    if let tabViewController: NSTabViewController = self.children.first as? NSTabViewController
    {
      let tabIndex = tabViewController.selectedTabViewItemIndex
      if let viewController = tabViewController.tabViewItems[tabIndex].viewController as? SelectionIndex
      {
        viewController.setSelectionIndex(index: index)
      }
    }
  }
  
  /// Connects the segmentedControl to the TabViewController
  @IBAction func changeTabItem(_ sender: NSSegmentedControl)
  {
    if let tabViewController: NSTabViewController = self.children.first as? NSTabViewController
    {
      tabViewController.selectedTabViewItemIndex = sender.selectedSegment
    }
  }
}

