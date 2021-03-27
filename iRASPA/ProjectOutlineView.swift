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
import iRASPAKit
import OperationKit
import ObjectiveC

@objc protocol NSProjectViewDelegate : NSOutlineViewDelegate
{
  @objc optional func dragItems(_ outlineView: NSOutlineView, item: ProjectTreeNode?) -> [ProjectTreeNode]
}

class ProjectOutlineView: NSOutlineView
{
  var localRootsOfSelectedNodes: [ProjectTreeNode] = []
  
  override var isOpaque: Bool
  {
    return true
  }
  
  override var acceptsFirstResponder: Bool
  {
    return true
  }
  
  override func becomeFirstResponder() -> Bool
  {
    self.enumerateAvailableRowViews({ (rowView,row) in
      rowView.isEmphasized = true
      rowView.layer?.setNeedsDisplay()
    })
    return true
  }
  
  override func resignFirstResponder() -> Bool
  {
    self.enumerateAvailableRowViews({ (rowView,row) in
      rowView.isEmphasized = false
      rowView.layer?.setNeedsDisplay()
    })
    return true
  }
  
  public override func resize(withOldSuperviewSize oldSize: NSSize)
  {
    super.resizeSubviews(withOldSize: oldSize)
    self.enumerateAvailableRowViews { (rowView, index) in
      rowView.layer?.setNeedsDisplay()
    }
  }
  
  
  public func reloadSelection()
  {
    (self.delegate as? Reloadable)?.reloadData()
  }

  // disallow drag&drop when already a drag&drop is in progress
  override func canDragRows(with rowIndexes: IndexSet, at mouseDownPoint: NSPoint) -> Bool
  {
    let row = self.row(at: mouseDownPoint)
    let item: ProjectTreeNode? = self.item(atRow: row) as? ProjectTreeNode
    localRootsOfSelectedNodes = (self.delegate as? NSProjectViewDelegate)?.dragItems?(self, item: item) ?? []
    
    // loading projects can not be dragged
    if let item = item,
      item.representedObject.lazyStatus == .loading
    {
      return false
    }
    
    if let item = item
    {
      if item.disallowDrag
      {
        return false
      }
    }

    return iRASPAWindowController.dragAndDropConcurrentQueue.operationCount == 0
  }
  
  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation
  {
    let dragOperation: NSDragOperation = super.draggingEntered(sender)
    
    if let draggingSource = sender.draggingSource as? NSOutlineView
    {
      sender.draggingFormation = draggingSource === self ? .none : .list
    }
   
    return dragOperation
  }
}
