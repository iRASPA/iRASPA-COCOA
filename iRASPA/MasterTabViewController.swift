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

/// protocol to setting the index generically for all projects
protocol SelectionIndex: class
{
  func setSelectionIndex(index: Int)
}

/// protocol to use the projectController generically for all viewers
protocol ProjectController
{
  func initializeData()
  func importFileOpenPanel()
  func reloadData()
  func switchToCurrentProject()
  var projectView: NSView? {get}
}

/// MasterTabViewController controls the "Structure viewer" and the "Directory Viewer"
///
/// Note: VASP Viewer is to be added as future work
public class MasterTabViewController: NSTabViewController, WindowControllerConsumer, Reloadable, ProjectController
{
  weak var windowController: iRASPAWindowController?
  {
    didSet
    {
      windowController?.masterTabViewController = self
    }
  }
  
  /// Gets the current masterViewController as a ProjectController
  ///
  /// Note: tab-index 0 is the "Structure viewer", tab index 1 is the "Directory viewer"
  ///
  /// - returns: the current viewController of the selected tab as a ProjectController.
  var masterViewController: (ProjectController & SelectionIndex)?
  {
    let index: Int = self.selectedTabViewItemIndex
    if let currentViewController: NSViewController = self.tabViewItems[index].viewController
    {
      return currentViewController as? (ProjectController & SelectionIndex)
    }
    return nil
  }
  
  func initializeData()
  {
    let index: Int = self.selectedTabViewItemIndex
    if let currentViewController: NSViewController = self.tabViewItems[index].viewController
    {
      (currentViewController as? ProjectController)?.initializeData()
    }
  }
  
  func importFileOpenPanel()
  {
    let index: Int = self.selectedTabViewItemIndex
    if let currentViewController: NSViewController = self.tabViewItems[index].viewController
    {
      (currentViewController as? ProjectController)?.importFileOpenPanel()
    }
  }
  
  var projectView: NSView?
  {
    let index: Int = self.selectedTabViewItemIndex
    if let currentViewController: NSViewController = self.tabViewItems[index].viewController
    {
      return (currentViewController as? ProjectController)?.projectView
    }
    return nil
  }
  
  func switchToCurrentProject()
  {
    let index: Int = self.selectedTabViewItemIndex
    if let currentViewController: NSViewController = self.tabViewItems[index].viewController
    {
      (currentViewController as? ProjectController)?.switchToCurrentProject()
    }
  }
  
  func reloadData()
  {
    let index: Int = self.selectedTabViewItemIndex
    if let currentViewController: NSViewController = self.tabViewItems[index].viewController
    {
      if let viewController = currentViewController as? Reloadable
      {
        viewController.reloadData()
      }
    }
  }
}
