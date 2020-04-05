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
import simd
import PythonKit


var pythonMethodsiRASPA: [PyMethodDef] = []
var logModule: PyModuleDef = PyModuleDef()

let libraryPyCFunction: PyCFunction = { (this, args) in
  return Py_VaBuildValue(strdup("s"), getVaList([strdup("Python: library")]))
}

let projectsPyCFunction: PyCFunction = { (this, args) in
  return Py_VaBuildValue(strdup("s"), getVaList([strdup("Python: projects")]))
}

let moduleName: UnsafeMutablePointer<Int8>! = strdup("iRASPA")
let libraryName: UnsafeMutablePointer<Int8>! = strdup("library")
let projectsName: UnsafeMutablePointer<Int8>! = strdup("projects")

var PyInit_PythonModuleiRASPA : @convention(c) () ->  UnsafeMutablePointer<PyObject>? = {
  return PyModule_Create2(&logModule, 1013)
}



func initPythonModuleiRASPA()
{
  pythonMethodsiRASPA = [PyMethodDef(ml_name: libraryName, ml_meth: libraryPyCFunction, ml_flags: Int32(METH_VARARGS), ml_doc: nil),
                PyMethodDef(ml_name: projectsName, ml_meth: projectsPyCFunction, ml_flags: Int32(METH_VARARGS), ml_doc: nil),
                PyMethodDef()]
  
  
  pythonMethodsiRASPA.withUnsafeMutableBufferPointer{ (bp) in
  let rbp = UnsafeMutableRawBufferPointer(bp)
  if let pointer: UnsafeMutablePointer<PyMethodDef> = rbp.baseAddress?.bindMemory(to: PyMethodDef.self, capacity: rbp.count)
  {
    logModule = PyModuleDef(m_base: PyModuleDef_Base(), m_name: moduleName, m_doc: nil, m_size: -1, m_methods: pointer, m_slots: nil, m_traverse: nil, m_clear: nil, m_free: nil)
    }
    PyImport_AppendInittab(moduleName, PyInit_PythonModuleiRASPA)
  }
}

