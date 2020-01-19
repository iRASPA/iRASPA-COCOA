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

class iRASPAPopUpButton: NSPopUpButton
{
  public var isEditable: Bool = true
  {
    didSet
    {
      if isEditable
      {
        (self.cell as? NSPopUpButtonCell)?.arrowPosition = .arrowAtCenter
      }
      else
      {
        (self.cell as? NSPopUpButtonCell)?.arrowPosition = .noArrow
      }
    }
  }
  
  public override func removeItem(withTitle title: String)
  {
    let index: Int = self.indexOfItem(withTitle: title)
    if index >= 0
    {
      self.removeItem(at: index)
    }
  }
  
  override func mouseDown(with event: NSEvent)
  {
    if isEditable
    {
      super.mouseDown(with: event)
    }
  }
  
  override func keyDown(with event: NSEvent)
  {
    if isEditable
    {
      super.keyDown(with: event)
    }
  }
  
  override func performKeyEquivalent(with key: NSEvent) -> Bool
  {
    if isEditable
    {
      return super.performKeyEquivalent(with: key)
    }
    return false
  }
  
}
