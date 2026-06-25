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

/// Name field for source-list rows: single click selects the row;
/// double-click calls `beginRenaming()` to enable editing.
class TableListNameTextField: NSTextField
{
  private(set) var allowsRenaming: Bool = false
  
  override var acceptsFirstResponder: Bool
  {
    return allowsRenaming && super.acceptsFirstResponder
  }
  
  override func mouseDown(with event: NSEvent)
  {
    if allowsRenaming
    {
      super.mouseDown(with: event)
      return
    }
    
    if let listView = enclosingListView()
    {
      listView.mouseDown(with: event)
    }
    else
    {
      super.mouseDown(with: event)
    }
  }
  
  func beginRenaming()
  {
    allowsRenaming = true
    isEditable = true
  }
  
  func endRenaming()
  {
    allowsRenaming = false
    isEditable = false
  }
  
  private func enclosingListView() -> NSView?
  {
    var view: NSView? = superview
    while let current = view
    {
      if current is NSOutlineView || current is NSTableView { return current }
      view = current.superview
    }
    return nil
  }
}

