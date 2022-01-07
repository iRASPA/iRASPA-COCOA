/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

class DirectoryMasterViewController: NSViewController, WindowControllerConsumer, ProjectController
{
  @IBOutlet weak var segmentedControl: NSSegmentedControl?
  
  weak var windowController: iRASPAWindowController?
  {
    didSet
    {
      
    }
  }
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    // propagate windowController after loaded lazily
    self.propagateWindowController(windowController, toChildrenOf: self)
  }
  
  func initializeData()
  {
    
  }
  
  var projectViewController: ProjectViewController?
  {
    return  self.children.first as? ProjectViewController
  }
  
  func initializeDocumentData(documentData: DocumentData)
  {
  }
  
  func switchToCurrentProject()
  {
    func importFileOpenPanel()
    {
      if let projectViewController: ProjectViewController = self.children.first as? ProjectViewController
      {
        projectViewController.switchToCurrentProject()
      }
    }
  }
  
  func reloadData()
  {
  }
  
  func importFileOpenPanel()
  {
    if let projectViewController: ProjectViewController = self.children.first as? ProjectViewController
    {
      projectViewController.importFileOpenPanel()
    }
  }
  
  var projectsView: NSView?
  {
    return nil
  }
  
  
  func setSelectionIndex(index: Int)
  {
    
  }
}

