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

// each detail-viewer must define these
protocol Collapsable: class
{
  var rightSplitViewItem: NSSplitViewItem? {get}
  var bottomSplitViewItem: NSSplitViewItem? {get}
}


class DetailTabViewController: NSTabViewController, WindowControllerConsumer, Reloadable
{
  var rightSplitViewItem: NSSplitViewItem?
  {
    let index: Int = self.selectedTabViewItemIndex
    if let currentViewController: NSViewController = self.tabViewItems[index].viewController
    {
      return (currentViewController as? Collapsable)?.rightSplitViewItem
      
    }
    return nil
  }
  
  var bottomSplitViewItem: NSSplitViewItem?
  {
    let index: Int = self.selectedTabViewItemIndex
    if let currentViewController: NSViewController = self.tabViewItems[index].viewController
    {
      return (currentViewController as? Collapsable)?.bottomSplitViewItem
      
    }
    return nil
  }
  
  weak var windowController: iRASPAWindowController?
  {
    didSet
    {
      windowController?.detailTabViewController = self
    }
  }
  
  func reloadData()
  {
    debugPrint("DetailTabViewController reload")
    let index: Int = self.selectedTabViewItemIndex
    if let currentViewController: NSViewController = self.tabViewItems[index].viewController
    {
      if let viewController = currentViewController as? Reloadable
      {
        viewController.reloadData()
      }
    }
  }
  
  var renderViewController: RenderTabViewController?
  {
    return self.tabViewItems[0].viewController?.children[0].children[0] as? RenderTabViewController
  }
  
  var directoryViewController: DirectoryViewController?
  {
    return self.selectedTabViewItemIndex == 1 ? self.tabViewItems[1].viewController as? DirectoryViewController : nil
  }
  
  var structureDetailTabViewController: StructureDetailTabViewController?
  {
    return self.tabViewItems[0].viewController?.children[1].children[0] as? StructureDetailTabViewController
  }
  
  public enum ProjectViewType: Int
  {
    case structureVisualisation = 0
    case directoryBrowser = 1
    case VASP = 2
    case RASPA = 3
    case CP2K = 4
  }
  
  override func viewDidLoad()
  {
    super.viewDidLoad()

    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]    
  }
}
