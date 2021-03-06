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

class NSStaticViewBasedOutlineView: NSOutlineView, NSOutlineViewDataSource
{
  var items: [OutlineViewItem] = []
  
  var isReloading = false
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    self.dataSource = self
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    self.dataSource = self
  }
  
  // Now normally when you try to directly click on one of the NSTextFields the table will first select the row.
  // Then a second click will allow you to start editing. For most tables, this is the behavior you want.
  // For something like what I have, I want to avoid this, and allow the first responder to go through.
  // This can easily be done by subclassing NSTableView and overriding
  // http://www.corbinstreehouse.com/blog/category/cocoa/
  override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool
  {
    return true
  }

  override func draw(_ dirtyRect: NSRect)
  {
    super.draw(dirtyRect)
  }
  
  override func frameOfCell(atColumn columnIndex: Int, row rowIndex: Int) -> NSRect
  {
    let superFrame: NSRect = super.frameOfCell(atColumn: columnIndex, row: rowIndex)
    
    if let item: Any = self.item(atRow: rowIndex)
    {
      if let isGroupItem: Bool = self.dataSource?.outlineView?(self, isItemExpandable: item)
      {
        return isGroupItem ? superFrame: NSMakeRect(0, superFrame.origin.y, self.bounds.size.width, superFrame.size.height)
      }
    }
    return superFrame
  }
  
  override func reloadData()
  {
    self.isReloading = true
    super.reloadData()
    self.isReloading = false
  }
  
  // MARK: NSOutlineView DataSource Methods
  // =====================================================================
  
  // Returns a Boolean value that indicates whether the a given item is expandable
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool
  {
    return (item as! OutlineViewItem).children.count > 0
  }
  
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int
  {
    if item == nil
    {
      return items.count
    }

    assert(item is OutlineViewItem)

    return (item as! OutlineViewItem).children.count
  }
  
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any
  {
    if item == nil
    {
      return items[index]
    }

    assert(item is OutlineViewItem)
    
    return (item as! OutlineViewItem).children[index]
  }
}
