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

protocol NSPathControlExtendedDelegate : NSPathControlDelegate
{
  func pathControl(_ pathControl: NSPathControl, menuForCell menu: NSPathComponentCell) -> NSMenu
}

class CustomPathControl: NSPathControl
{

  override func draw(_ dirtyRect: NSRect)
  {
    super.draw(dirtyRect)

    // Drawing code here.
  }
  
  /*
  override func mouseDown(with theEvent: NSEvent)
  {
    let point: NSPoint = self.convert(theEvent.locationInWindow, from: nil)
    
    let cell: NSPathCell = self.cell as! NSPathCell
    let componentCell: NSPathComponentCell = cell.pathComponentCell(at: point, withFrame: self.bounds, in: self)!
    let componentRect: NSRect = cell.rect(of: componentCell, withFrame: self.bounds, in: self)
   
    
    let menu: NSMenu = (self.delegate as! NSPathControlExtendedDelegate).pathControl(self, menuForCell: componentCell)
    
    if (menu.numberOfItems > 0)
    {
      var selectedMenuItemIndex: NSInteger = 0
      
      for menuItemIndex in 0..<selectedMenuItemIndex
      {
        if (menu.item(at: menuItemIndex)!.state == NSOnState)
        {
          selectedMenuItemIndex = menuItemIndex
          break;
        }
      }
      let selectedMenuItem: NSMenuItem = menu.item(at: selectedMenuItemIndex)!
      menu.popUp(positioning: selectedMenuItem, at: NSMakePoint(NSMinX(componentRect) - 17, NSMinY(componentRect) + 2), in: self)
    }
  }

  */

  
  override func menu(for event: NSEvent) -> NSMenu?
  {
    if (event.type != NSEvent.EventType.leftMouseDown)
    {
      return nil
    }
    else
    {
      return super.menu(for: event)
    }
  }
 
  
}
