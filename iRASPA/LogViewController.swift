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
import Python
import RenderKit
import iRASPAKit
import LogViewKit

class LogViewController: NSViewController, WindowControllerConsumer, NSTextViewDelegate, LogReporting
{
  @IBOutlet public weak var segmentedControl: NSSegmentedControl?
  @IBOutlet private weak var logScrollView: NSScrollView?
  
  // NSTextview must be strong in 'El Capitan'
  @IBOutlet public var logScriptView: LogScriptTextView?
  
  weak var windowController: iRASPAWindowController?

  deinit
  {
    logScriptView = nil
    //Swift.print("deinit: LogViewController")
  }
  
  // ViewDidLoad: bounds are not yet set (do not do geometry-related etup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    logScriptView?.setUpLineNumberView()
  }
  
  
  override func viewDidAppear()
  {
    super.viewDidAppear()
    
    if let windowController: iRASPAWindowController = self.view.window?.windowController as? iRASPAWindowController
    {
      LogQueue.shared.subscribe(self, windowController: windowController)
    }
  }
  
  

  func update(attributedString: NSTextStorage)
  {
    self.logScriptView?.layoutManager?.textStorage?.append(attributedString)
    
    self.logScrollView?.verticalRulerView?.needsDisplay = true
    
    if let logScriptView = self.logScriptView
    {
       let string: String = logScriptView.string
      logScriptView.scrollRangeToVisible(NSMakeRange((string as NSString).length, 0))
    }
  }
}
