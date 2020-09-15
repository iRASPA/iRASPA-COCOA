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
import RenderKit
import Metal
import iRASPAKit

// The CrystalViewController also acts as the editing controller for the renderViewController because
// (1) Undo should be done via a controller and not in the model.
// (2) renderViewController does not have knowledge of higher-level iRASPA objects


// http://objectivetoast.com/2014/06/02/translating-autoresizing-masks-into-constraints/
// If this value is YES, the view’s superview looks at the view’s autoresizing mask, produces constraints that implement it,
// and adds those constraints to itself (the superview).
// the constraints are generated on demand during layout by the private method
// When it is set to YES, the layout system adds the generated constraints to the set of constraints as it solves the layout.
// When it is set to NO, these constraints are not generated. In this case, if there are other constraints that involve that
// view they must be sufficient to define its size and position, or if there are no constraints that involve that view,
// its size and position will stay the same.



class StructureViewController: NSVerticalSplitViewController, WindowControllerConsumer, Collapsable, Reloadable
{
  var rightSplitViewItem: NSSplitViewItem?
  {
    return self.splitViewItems[1]
  }
  
  var bottomSplitViewItem: NSSplitViewItem?
  {
    return (self.splitViewItems[0].viewController as? NSSplitViewController)?.splitViewItems[1]
  }
  
  weak var windowController: iRASPAWindowController?
  
  override func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool
  {
    return false
  }
  
  func reloadData()
  {
    (self.rightSplitViewItem?.viewController as? Reloadable)?.reloadData()
  }

  
  deinit
  {
    //Swift.print("deinit: StructureViewController")
  }
}
