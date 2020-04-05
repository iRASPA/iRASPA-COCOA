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


import RenderKit
import iRASPAKit
import LogViewKit
import PythonKit

extension String {
    /// Calls the given closure with a pointer to the contents of the string,
    /// represented as a null-terminated wchar_t array.
    func withWideChars<Result>(_ body: (UnsafePointer<wchar_t>) -> Result) -> Result {
        let u32 = self.unicodeScalars.map { wchar_t(bitPattern: $0.value) } + [0]
        return u32.withUnsafeBufferPointer { body($0.baseAddress!) }
    }
}



class InterpreterViewController: NSViewController, WindowControllerConsumer, NSTextViewDelegate
{
  @IBOutlet public weak var segmentedControl: NSSegmentedControl?
  
  // NSTextview must be strong in 'El Capitan'
  @IBOutlet private var pythonScriptView: PythonScriptTextView?
  @IBOutlet private weak var pythonScrollView: NSScrollView?
  
  weak var windowController: iRASPAWindowController?
  
  static weak var interpreterViewController: InterpreterViewController?
  
  var tstate: UnsafeMutablePointer<PyThreadState>? = nil
  var globalDict: UnsafeMutablePointer<PyObject>? = nil
  
  var logMethods: [PyMethodDef] = []
  static var logModule: PyModuleDef = PyModuleDef()
  var logMod: UnsafeMutablePointer<PyObject>!
  
  let captureStdoutName = strdup("CaptureStdout")
  let captureStderr = strdup("CaptureStderr")
  let moduleName = strdup("log")
  
  deinit
  {
    pythonScriptView = nil
    //free(programName)
    free(captureStdoutName)
    free(captureStderr)
    free(moduleName)
    if(tstate != nil)
    {
      PyThreadState_Swap(tstate)
      Py_EndInterpreter(tstate)
      PyThreadState_Swap(nil)
    }
  }
  
  // ViewDidLoad: bounds are not yet set (do not do geometry-related etup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    InterpreterViewController.interpreterViewController=self
    
    setupPython()
    
    pythonScriptView?.setUpLineNumberView()
    
    self.pythonScriptView?.pythonOut(string: "Python console ready\n")
  }
  
  var PyInit_log : @convention(c) () ->  UnsafeMutablePointer<PyObject>? = {
    return PyModule_Create2(&InterpreterViewController.logModule, 1013)
  }
  
  
  
  func setupPython()
  {
    self.logMethods = [PyMethodDef(ml_name: captureStdoutName, ml_meth: log_CaptureStdout, ml_flags: Int32(METH_VARARGS), ml_doc: nil), PyMethodDef(ml_name: captureStderr, ml_meth: log_CaptureStderr, ml_flags: Int32(METH_VARARGS), ml_doc: nil), PyMethodDef()]
    
    if let pythonHomeString: String = Bundle.main.path(forResource: "python3.7", ofType: nil, inDirectory: "Python-3.7/lib"),
       let pythonProgramString: String = Bundle.main.path(forResource: "python3.7", ofType: nil, inDirectory: "Python-3.7/bin"),
       let installDirectory: String = Bundle.main.path(forResource: "Python-3.7", ofType: nil)
    {
      let pythonPathString: String = installDirectory + "/lib/python3.7:" + installDirectory + "/lib/python3.7/site-packages:" +
                    installDirectory + "/lib/python3.7/multiprocessing:" + installDirectory + "/lib/python3.7/encodings:" +
                    installDirectory + "/lib/python3.7/lib-dynload:" + installDirectory + "/lib/python3.7/curses"
    
      pythonPathString.withWideChars { wname in
          Py_SetPath(wname)
      }
    
      pythonHomeString.withWideChars { wname in
          Py_SetPythonHome(wname)
      }
    
      pythonProgramString.withWideChars { wname in
          Py_SetProgramName(wname)
      }
    
      self.logMethods.withUnsafeMutableBufferPointer{ (bp) in
        let rbp = UnsafeMutableRawBufferPointer(bp)
        if let pointer: UnsafeMutablePointer<PyMethodDef> = rbp.baseAddress?.bindMemory(to: PyMethodDef.self, capacity: rbp.count)
        {
          InterpreterViewController.logModule = PyModuleDef(m_base: PyModuleDef_Base(), m_name: moduleName, m_doc: nil, m_size: -1, m_methods: pointer, m_slots: nil, m_traverse: nil, m_clear: nil, m_free: nil)
     
          PyImport_AppendInittab(moduleName, PyInit_log)
     
          initPythonModuleiRASPA()
     
          initPythonModuleConstants()
     
          Py_InitializeEx(0)
     
          tstate = Py_NewInterpreter()
     
          let string: String =
            "import log\n" +
            "import sys\n" +
            "import math\n" +
            "import constants\n" +
            "# coding: utf-8\n" +
            "class StdoutCatcher:\n" +
            "\tdef write(self, str):\n" +
            "\t\tlog.CaptureStdout(str)\n" +
            "class StderrCatcher:\n" +
            "\tdef write(self, str):\n" +
            "\t\tlog.CaptureStderr(str)\n" +
            "sys.stdout = StdoutCatcher()\n" +
            "sys.stderr = StderrCatcher()\n"
     
          PyRun_SimpleStringFlags(string,nil)
     
          setupPythonModuleConstants()
        }
      }
    }
  }
  
  var log_CaptureStdout: PyCFunction =
  {
    (this: UnsafeMutablePointer<PyObject>?, args: UnsafeMutablePointer<PyObject>?) in
    
    let buffer = UnsafeMutablePointer<UnsafeMutablePointer<CChar>>.allocate(capacity: 1)
    
    if (withVaList([buffer]) {return PyArg_VaParse(args, "s", $0)} == 0)
    {
      return nil
    }
    
    let string: String = String(cString: buffer.pointee, encoding: String.Encoding.ascii)!
    buffer.deallocate()
    
    InterpreterViewController.interpreterViewController?.pythonScriptView?.pythonOut(string: string as NSString)
    
    var Py_None = _Py_NoneStruct
    Py_IncRef(&Py_None)
    return withUnsafePointer(to: &Py_None){UnsafeMutablePointer<PyObject>(mutating: $0)}
  }
  
  
  
  let log_CaptureStderr: PyCFunction =
  {
    (this: UnsafeMutablePointer<PyObject>?, args: UnsafeMutablePointer<PyObject>?) in
    
    let buffer = UnsafeMutablePointer<UnsafeMutablePointer<CChar>>.allocate(capacity: 1)
    
    if (withVaList([buffer]) {return PyArg_VaParse(args, strdup("s"), $0)} == 0)
    {
      return nil
    }
    
    let string: String = String(cString: buffer.pointee, encoding: String.Encoding.ascii)!
    buffer.deallocate()
    
    InterpreterViewController.interpreterViewController?.pythonScriptView?.pythonOut(string: string as NSString)
    
    var Py_None = _Py_NoneStruct
    Py_IncRef(&Py_None)
    return withUnsafePointer(to: &Py_None){UnsafeMutablePointer<PyObject>(mutating: $0)}
  }
  
  func runPythonCmd()
  {
    if let pythonScriptView = pythonScriptView,
       let _ = tstate
    {
      let cmd: String = pythonScriptView.lastCommandLine
      
      self.pythonScriptView?.pythonOut(string: "\n")
      
      pythonScriptView.needsDisplay = true
      
      // switch to the current embedded interpreter
      PyThreadState_Swap(tstate)
      
      InterpreterViewController.interpreterViewController=self
      
      PyRun_SimpleStringFlags(cmd,nil)
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
