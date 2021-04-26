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
import simd
import PythonKit
import SymmetryKit

struct SKAsymmetricAtomPythonObject
{
  var ob_base: PyObject = PyObject()
  var asymmetricAtom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: "atom", elementId: 0, uniqueForceFieldName: "ff", position: SIMD3<Double>(1.0,2.0,3.0), charge: 0.0, color: NSColor.red, drawRadius: 1.0, bondDistanceCriteria: 1.5)
}

let moduleName: UnsafeMutablePointer<Int8>! = strdup("iraspa")

var initAtomPyCFunction : initproc = { (this: UnsafeMutablePointer<PyObject>?, _ args: UnsafeMutablePointer<PyObject>?, _ : UnsafeMutablePointer<PyObject>?) -> Int32 in
    
  this?.withMemoryRebound(to: SKAsymmetricAtomPythonObject.self, capacity: 1, { (p: UnsafeMutablePointer<SKAsymmetricAtomPythonObject>)  in
    p.pointee.asymmetricAtom = SKAsymmetricAtom(displayName: "atom", elementId: 0, uniqueForceFieldName: "ff", position: SIMD3<Double>(1.0,2.0,3.0), charge: 0.0, color: NSColor.red, drawRadius: 1.0, bondDistanceCriteria: 1.5)
  })
    
  return 0
}



let getXFunctionName: UnsafeMutablePointer<Int8>! = strdup("getX")
var getXPyCFunction : PyCFunction = { (this: UnsafeMutablePointer<PyObject>?, _ args: UnsafeMutablePointer<PyObject>?) in
    
  guard let y: Double = this?.withMemoryRebound(to: SKAsymmetricAtomPythonObject.self, capacity: 1, { (obj: UnsafeMutablePointer<SKAsymmetricAtomPythonObject> ) -> Double in
    return obj.pointee.asymmetricAtom.position.y
  })
  else
  {
    return nil
  }
    
  return Py_VaBuildValue("d", getVaList([y]))
}


var pythonMethodsiRASPA: [PyMethodDef] = [
  PyMethodDef(ml_name: getXFunctionName, ml_meth: getXPyCFunction, ml_flags: Int32(METH_NOARGS), ml_doc: nil),
  PyMethodDef()]


var getterX : getter = { (this: UnsafeMutablePointer<PyObject>?, _ args: UnsafeMutableRawPointer?) -> UnsafeMutablePointer<PyObject>? in
    
  this?.withMemoryRebound(to: SKAsymmetricAtomPythonObject.self, capacity: 1, { (obj: UnsafeMutablePointer<SKAsymmetricAtomPythonObject> ) in
    return Py_VaBuildValue("d", getVaList([obj.pointee.asymmetricAtom.position.x]))
  })
}

var setterX : setter = { (this: UnsafeMutablePointer<PyObject>?, _ value: UnsafeMutablePointer<PyObject>?, _ closure: UnsafeMutableRawPointer?) -> Int32 in
  if (value == nil)
  {
    PyErr_SetString(PyExc_TypeError, "Cannot modify the 'x' attribute")
    return -1
  }
  
  if (_Py_IS_TYPE(value, &PyFloat_Type) == 0)
  {
     PyErr_SetString(PyExc_TypeError, "The x attribute value must be a real number");
    return -1;
  }
  
  //var objectsRepresentation: UnsafeMutablePointer<PyObject> = PyObject_Repr(value)
  //var string: UnsafeMutablePointer<PyObject> = PyUnicode_AsEncodedString(objectsRepresentation, "utf-8", "~E~");
  //var text: UnsafeMutablePointer<Int8>? = PyBytes_AsString(string)
  //debugPrint("HERE \(String(cString: text!))")
  
  this?.withMemoryRebound(to: SKAsymmetricAtomPythonObject.self, capacity: 1, { (obj: UnsafeMutablePointer<SKAsymmetricAtomPythonObject> ) in
      obj.pointee.asymmetricAtom.position.x = PyFloat_AsDouble(value!)
  })
   
  return 0
}

var getSet: [PyGetSetDef] = [
  PyGetSetDef(name: strdup("x"), get: getterX, set: setterX, doc: nil, closure: nil),
  PyGetSetDef()
]

var defaultFlags: UInt = UInt(Py_TPFLAGS_HAVE_STACKLESS_EXTENSION) | Py_TPFLAGS_HAVE_VERSION_TAG | 0

var atomCopyPyType: PyTypeObject = PyTypeObject(ob_base: PyVarObject(), tp_name: strdup("atom"), tp_basicsize: Py_ssize_t(MemoryLayout<SKAsymmetricAtomPythonObject>.size), tp_itemsize: Py_ssize_t(0), tp_dealloc: nil, tp_vectorcall_offset: Py_ssize_t(0), tp_getattr: nil, tp_setattr: nil, tp_as_async: nil, tp_repr: nil, tp_as_number: nil, tp_as_sequence: nil, tp_as_mapping: nil, tp_hash: nil, tp_call: nil, tp_str: nil, tp_getattro: nil, tp_setattro: nil, tp_as_buffer: nil, tp_flags: defaultFlags, tp_doc: nil, tp_traverse: nil, tp_clear: nil, tp_richcompare: nil, tp_weaklistoffset: Py_ssize_t(0), tp_iter: nil, tp_iternext: nil, tp_methods: pythonMethodsiRASPA.withUnsafeMutableBufferPointer({return $0.baseAddress}), tp_members: nil, tp_getset: getSet.withUnsafeMutableBufferPointer({return $0.baseAddress}), tp_base: nil, tp_dict: nil, tp_descr_get: nil, tp_descr_set: nil, tp_dictoffset: Py_ssize_t(0), tp_init: initAtomPyCFunction, tp_alloc: nil, tp_new: PyType_GenericNew, tp_free: nil, tp_is_gc: nil, tp_bases: nil, tp_mro: nil, tp_cache: nil, tp_subclasses: nil, tp_weaklist: nil, tp_del: nil, tp_version_tag: 0, tp_finalize: nil, tp_vectorcall: nil)


var logModule: PyModuleDef = PyModuleDef(m_base: PyModuleDef_Base(), m_name: moduleName, m_doc: nil, m_size: -1, m_methods: pythonMethodsiRASPA.withUnsafeMutableBufferPointer({return $0.baseAddress}), m_slots: nil, m_traverse: nil, m_clear: nil, m_free: nil)


var PyInit_PythonModuleiRASPA : @convention(c) () ->  UnsafeMutablePointer<PyObject>? = {
  if PyType_Ready(&atomCopyPyType) < 0
  {
    return nil
  }
  var m: UnsafeMutablePointer<PyObject>? = PyModule_Create2(&logModule, 1013)
  if m == nil
  {
    return nil
  }
    
  Py_IncRef(&atomCopyPyType)
  
  var atomType: PyObjectPointer = PyObjectPointer(&atomCopyPyType)
  PyModule_AddObject(m, "atom", atomType.bindMemory(to: PyObject.self, capacity: 1))
  
  return m
}

func initPythonModuleiRASPA()
{
  // register the module with Python as additional built-in module
  PyImport_AppendInittab(moduleName, PyInit_PythonModuleiRASPA)
}
