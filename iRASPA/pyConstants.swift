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
import Python


var logMethods: [PyMethodDef] = []


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
  var m: UnsafeMutablePointer<PyObject>
  var d: UnsafeMutablePointer<PyObject>
  
  logMethods = [PyMethodDef(ml_name: myFunctionName, ml_meth: myBlock, ml_flags: Int32(METH_VARARGS), ml_doc: nil),
                PyMethodDef(ml_name: myFunctionName2, ml_meth: myBlock2, ml_flags: Int32(METH_VARARGS), ml_doc: nil),
                PyMethodDef()]
  
  m=Py_InitModule4_64(constantsName, &logMethods, nil, nil, 1013)
  d = PyModule_GetDict(m)
  
  // Avogadro constant
  let R: CDouble = 8.31446491
  let tmp: UnsafeMutablePointer<PyObject> = Py_VaBuildValue("d",getVaList([R]))
  PyDict_SetItemString(d,"R", tmp)
  Py_DecRef(tmp)

}

