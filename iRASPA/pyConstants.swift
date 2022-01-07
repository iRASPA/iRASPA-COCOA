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
import PythonKit


var constantMethods: [PyMethodDef] = []
var constantModule: PyModuleDef = PyModuleDef()

var PyInit_Constants : @convention(c) () ->  UnsafeMutablePointer<PyObject>? = {
  return PyModule_Create2(&constantModule, 1013)
}

let myBlock: PyCFunction = { (this, args) in
  return Py_VaBuildValue(strdup("s"), getVaList([strdup("Python: hello from real swift!")]))
}

let myBlock2: PyCFunction = { (this, args) in
  var x: [CDouble] = [0]
  var y: [CDouble] = [0]
    
  if (withVaList([x,y]) {return PyArg_VaParse(args, strdup("dd"), $0)} == 0)
  {
    return nil
  }
  
  return Py_VaBuildValue("d", getVaList([x[0]*y[0]]))
}

let constantsName = strdup("constants")
let myFunctionName = strdup("myFunction")
let myFunctionName2 = strdup("myFunction2")

func initPythonModuleConstants()
{
  constantMethods = [PyMethodDef(ml_name: myFunctionName, ml_meth: myBlock, ml_flags: Int32(METH_VARARGS), ml_doc: nil),
                PyMethodDef(ml_name: myFunctionName2, ml_meth: myBlock2, ml_flags: Int32(METH_VARARGS), ml_doc: nil),
                PyMethodDef()]
  
  constantMethods.withUnsafeMutableBufferPointer{ (bp) in
  let rbp = UnsafeMutableRawBufferPointer(bp)
  if let pointer: UnsafeMutablePointer<PyMethodDef> = rbp.baseAddress?.bindMemory(to: PyMethodDef.self, capacity: rbp.count)
  {
    constantModule = PyModuleDef(m_base: PyModuleDef_Base(), m_name: constantsName, m_doc: nil, m_size: -1, m_methods: pointer, m_slots: nil, m_traverse: nil, m_clear: nil, m_free: nil)
    }
    PyImport_AppendInittab(constantsName, PyInit_Constants)
  }
}


func setupPythonModuleConstants()
{
  var m: UnsafeMutablePointer<PyObject>?
  var d: UnsafeMutablePointer<PyObject>?
   
  let name = PyUnicode_FromString(constantsName)
  m = PyImport_GetModule(name)
  
  d = PyModule_GetDict(m)
  
  // Avogadro constant
  let R: CDouble = 8.31446491
  let tmp: UnsafeMutablePointer<PyObject> = Py_VaBuildValue("d",getVaList([R]))
  PyDict_SetItemString(d,"R", tmp)
  Py_DecRef(tmp)
}


