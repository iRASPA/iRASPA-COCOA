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
import LogViewKit

class LogAndInterpreterSplitViewController: NSVerticalSplitViewController, WindowControllerConsumer
{
  weak var windowController: iRASPAWindowController?
  
  // avoids: "Detected missing constraints"
  override func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool
  {
    return false
  }
  
  deinit
  {
    //Swift.print("deinit: LogAndInterpreterSplitViewController")
  }
  
  // ViewDidLoad: bounds are not yet set (do not do geometry-related etup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    self.splitView.arrangesAllSubviews = false
    
    self.splitViewItems[0].minimumThickness = 100.0
    self.splitViewItems[1].minimumThickness = 100.0
    
    (self.splitViewItems[0].viewController as? InterpreterViewController)?.segmentedControl?.isHidden = true
   // self.splitViewItems[0].isCollapsed = true
  }
  
  
  override func splitViewDidResizeSubviews(_ notification: Notification)
  {
    if let splitView: NSSplitView = notification.object as? NSSplitView
    {
      
      if let rightSegmentedControl: NSSegmentedControl = (self.splitViewItems[1].viewController as? LogViewController)?.segmentedControl
      {
        rightSegmentedControl.setImage(self.splitViewItems[0].isCollapsed ? NSImage(named: "ShowHideViewOnLeft") : NSImage(named: "ShowHideViewOnLeft-ON"), forSegment: 0)
        rightSegmentedControl.setImage(self.splitViewItems[1].isCollapsed ? NSImage(named: "ShowHideViewOnRight") : NSImage(named: "ShowHideViewOnRight-ON"), forSegment: 1)
      }
      
      let isRightCollapsed: Bool = splitView.isSubviewCollapsed(splitView.subviews[1])
      (self.splitViewItems[0].viewController as? InterpreterViewController)?.segmentedControl?.isHidden = !isRightCollapsed
      
      if let leftSegmentedControl: NSSegmentedControl = (self.splitViewItems[0].viewController as? InterpreterViewController)?.segmentedControl
      {
        leftSegmentedControl.isHidden = !self.splitViewItems[1].isCollapsed
        leftSegmentedControl.setImage(self.splitViewItems[0].isCollapsed ? NSImage(named: "ShowHideViewOnLeft") : NSImage(named: "ShowHideViewOnLeft-ON"), forSegment: 0)
        leftSegmentedControl.setImage(self.splitViewItems[1].isCollapsed ? NSImage(named: "ShowHideViewOnRight") : NSImage(named: "ShowHideViewOnRight-ON"), forSegment: 1)
      }
    }
  }
  
  @IBAction func toggleLogAndInterpreterView(_ sender : NSSegmentedControl)
  {
    if let leftSegmentedControl: NSSegmentedControl = (self.splitViewItems[0].viewController as? InterpreterViewController)?.segmentedControl,
       let rightSegmentedControl: NSSegmentedControl = (self.splitViewItems[1].viewController as? LogViewController)?.segmentedControl
    {
      switch (self.splitViewItems[0].isCollapsed,self.splitViewItems[1].isCollapsed)
      {
      case (false,false):
        if sender.selectedSegment == 0
        {
          self.splitViewItems[0].animator().isCollapsed = true
        }
        else if sender.selectedSegment == 1
        {
          self.splitViewItems[1].animator().isCollapsed = true
        }
      case (false,true):
        if sender.selectedSegment == 0
        {
          self.splitViewItems[0].isCollapsed = true
          self.splitViewItems[1].isCollapsed = false
        }
        else if sender.selectedSegment == 1
        {
          self.splitViewItems[1].animator().isCollapsed = false
        }
        
      case (true,false):
        if sender.selectedSegment == 0
        {
          self.splitViewItems[0].animator().isCollapsed = false
        }
        else if sender.selectedSegment == 1
        {
          self.splitViewItems[0].isCollapsed = false
          self.splitViewItems[1].isCollapsed = true
        }
      case (true,true):
        LogQueue.shared.error(destination: self.windowController, message: "Inconsistency in 'toggleLogAndInterpreterView'")
      }
      
      leftSegmentedControl.isHidden = !self.splitViewItems[1].isCollapsed
      
      leftSegmentedControl.setImage(self.splitViewItems[0].isCollapsed ? NSImage(named: "ShowHideViewOnLeft") : NSImage(named: "ShowHideViewOnLeft-ON"), forSegment: 0)
      leftSegmentedControl.setImage(self.splitViewItems[1].isCollapsed ? NSImage(named: "ShowHideViewOnRight") : NSImage(named: "ShowHideViewOnRight-ON"), forSegment: 1)
      
      rightSegmentedControl.setImage(self.splitViewItems[0].isCollapsed ? NSImage(named: "ShowHideViewOnLeft") : NSImage(named: "ShowHideViewOnLeft-ON"), forSegment: 0)
      rightSegmentedControl.setImage(self.splitViewItems[1].isCollapsed ? NSImage(named: "ShowHideViewOnRight") : NSImage(named: "ShowHideViewOnRight-ON"), forSegment: 1)
    }
    
  }
}
