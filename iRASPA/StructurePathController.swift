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

class StructurePathController: NSViewController, WindowControllerConsumer, NSPathControlExtendedDelegate, NSPathCellDelegate
{
  weak var windowController: iRASPAWindowController?
  
  @IBOutlet private weak var pathControl: NSPathControl?
  weak var renderViewController: RenderViewController?
  
  deinit
  {
    //Swift.print("deinit: StructurePathController")
  }

  
  
  // the 'representedObject' is of type 'ProjectTreeNode'
  override var representedObject: Any?
    {
    get
    {
      return super.representedObject
    }
    set(newValue)
    {
      super.representedObject = newValue
      
      if let project: ProjectTreeNode = newValue as? ProjectTreeNode
      {
        self.pathControl?.url = URL(string: project.path)
      }
      else
      {
        self.pathControl?.url = URL(string: "Empty selection")
      }
    }
  }
  
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    self.pathControl?.url = URL(string: "Projects")
    
  }
  
  func pathControl(_ pathControl: NSPathControl, menuForCell menu: NSPathComponentCell) -> NSMenu
  {
    let menu: NSMenu = NSMenu(title: "menu")
    let item1: NSMenuItem = NSMenuItem(title: "first", action: #selector(StructurePathController.test(_:)), keyEquivalent: "")
    let item2: NSMenuItem = NSMenuItem(title: "second", action: #selector(StructurePathController.test(_:)), keyEquivalent: "")
    item1.target = self
    item2.target = self
    menu.addItem(item1)
    menu.addItem(item2)
    return menu
  }
  
  @objc func test(_ sender: AnyObject?)
  {
  }
  
  /*
   override func validate(_ menuItem: NSMenuItem) -> Bool
   {
   return menuItem.isEnabled
   }*/
  
  func menuNeedsUpdate(_ menu: NSMenu)
  {
  }
  
}
