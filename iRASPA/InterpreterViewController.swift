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

import RenderKit
import iRASPAKit
import LogViewKit
import PythonKit

extension String {
    /// Calls the given closure with a pointer to the contents of the string,
    /// represented as a null-terminated wchar_t array.
    func withWideChars<Result>(_ body: (UnsafeMutablePointer<wchar_t>) -> Result) -> Result {
        var u32 = self.unicodeScalars.map { wchar_t(bitPattern: $0.value) } + [0]
        return u32.withUnsafeMutableBufferPointer { body($0.baseAddress!) }
    }
}



class InterpreterViewController: NSViewController, WindowControllerConsumer, NSTextViewDelegate
{
  @IBOutlet public weak var segmentedControl: NSSegmentedControl?
  
  // NSTextview must be strong in 'El Capitan'
  @IBOutlet private var pythonScriptView: PythonScriptTextView?
  @IBOutlet private weak var pythonScrollView: NSScrollView?
  
  weak var windowController: iRASPAWindowController?
  
  var tstate: UnsafeMutablePointer<PyThreadState>? = nil
  var mainModule: PythonObject? = nil
  
  // ViewDidLoad: bounds are not yet set (do not do geometry-related etup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
        
    setupPython()
    
    pythonScriptView?.setUpLineNumberView()
    
    let message: NSString = NSString(string: NSLocalizedString("Python Console Ready\n", comment: ""))
    self.pythonScriptView?.pythonOut(string: message)
  }
  
  deinit
  {
    mainModule = nil
    pythonScriptView = nil
    if(tstate != nil)
    {
      PyThreadState_Swap(tstate)
      Py_EndInterpreter(tstate)
      PyThreadState_Swap(nil)
    }
  }
  
  func setupPython()
  {
    if let bundle: Bundle = Bundle.init(identifier: "nl.darkwing.iRASPA.PythonKit"),
       let pythonHomeString: String = bundle.path(forResource: "python3.9", ofType: nil)
    {
      let pythonProgramString = "iRASPA python interpreter"
      let pythonPathString: String = pythonHomeString + ":" + pythonHomeString + "/site-packages"
          
      pythonPathString.withWideChars { wname in
          Py_SetPath(wname)
      }
    
      pythonProgramString.withWideChars { wname in
          Py_SetProgramName(wname)
      }
      
      Py_InitializeEx(0)
 
      tstate = Py_NewInterpreter()
      PyThreadState_Swap(tstate)
    
      mainModule = Python.import("catch_out")
    }
    /*
    let o: PyObjectPointer! = nil
    Py_IncRef(o)
    
    let x: PythonObject = 42  // x is an integer represented as a Python value.
    print(x + 4)         // Does a Python addition, then prints 46.
 */
  }
  
  func runPythonCmd()
  {
    if let pythonScriptView = pythonScriptView
    {
      let cmd: String = pythonScriptView.lastCommandLine
      
      self.pythonScriptView?.pythonOut(string: "\n")
      
      PyThreadState_Swap(tstate)
      PyRun_SimpleString(cmd)
      
      if let pythonOutputString = mainModule?.catchOut.print(),
         let outputString: String = String(pythonOutputString)
      {
        self.pythonScriptView?.pythonOut(string: NSString(string: outputString))
      }
      
      pythonScriptView.needsDisplay = true
    }
  }
  
  func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool
  {
    if let pythonScriptView = self.pythonScriptView,
       (self.pythonScriptView === textView)
    {
      switch(commandSelector)
      {
      case #selector(insertNewline(_:)):
        self.runPythonCmd()
        pythonScriptView.setSelectedRange(NSMakeRange(pythonScriptView.string.count, 0))
        pythonScriptView.scrollRangeToVisible(NSMakeRange((pythonScriptView.string as NSString).length, 0))
        
        return true
      case #selector(insertLineBreak(_:)):
        pythonScriptView.textStorage?.mutableString.append("\n")
        
        // set cursor to next line (even when pressed enter at any position)
        pythonScriptView.lineNumberRulerView?.needsDisplay = true
        pythonScriptView.scrollRangeToVisible(NSMakeRange((pythonScriptView.string as NSString).length, 0))
        return true
      case #selector(moveLeft(_:)),
           #selector(moveBackward(_:)),
           #selector(moveWordLeft(_:)),
           #selector(moveLeftAndModifySelection(_:)),
           #selector(moveBackwardAndModifySelection(_:)),
           #selector(moveWordBackwardAndModifySelection(_:)),
           #selector(moveWordLeftAndModifySelection(_:)),
           #selector(deleteBackward(_:)),
           #selector(deleteBackwardByDecomposingPreviousCharacter(_:)),
           #selector(deleteWordBackward(_:)):
        return pythonScriptView.selectedRanges[0].rangeValue.location <= pythonScriptView.previousTextCount
      case #selector(moveToBeginningOfDocument(_:)),
           #selector(moveToBeginningOfParagraph(_:)),
           #selector(moveUpAndModifySelection(_:)),
           #selector(pageUpAndModifySelection(_:)),
           #selector(moveParagraphBackwardAndModifySelection(_:)),
           #selector(moveToBeginningOfParagraphAndModifySelection(_:)),
           #selector(moveToBeginningOfDocumentAndModifySelection(_:)),
           #selector(moveUp(_:)),
           #selector(scrollToBeginningOfDocument(_:)),
           #selector(deleteToBeginningOfParagraph(_:)),
           #selector(scrollPageUp(_:)),
           #selector(scrollLineUp(_:)),
           #selector(pageUp(_:)),
           #selector(moveDown(_:)):
        return true
      default:
        return false
      }
    }
    return false
  }
  
  
  func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool
  {
    if let pythonScriptView = self.pythonScriptView
    {
      return affectedCharRange.location >= pythonScriptView.previousTextCount
    }
    return false
  }
}
