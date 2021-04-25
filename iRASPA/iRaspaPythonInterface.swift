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

struct asymmetricAtomStruct
{
  var ob_base: PyObject = PyObject()
  var asymmetricAtom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: "atom", elementId: 0, uniqueForceFieldName: "ff", position: SIMD3<Double>(1.0,2.0,3.0), charge: 0.0, color: NSColor.red, drawRadius: 1.0, bondDistanceCriteria: 1.5)
}

var atomCopyPyType: PyTypeObject = PyTypeObject(ob_base: PyVarObject(), tp_name: strdup("pyAsymmetricAtom"), tp_basicsize: Py_ssize_t(MemoryLayout<asymmetricAtomStruct>.size), tp_itemsize: Py_ssize_t(0), tp_dealloc: nil, tp_vectorcall_offset: Py_ssize_t(0), tp_getattr: nil, tp_setattr: nil, tp_as_async: nil, tp_repr: nil, tp_as_number: nil, tp_as_sequence: nil, tp_as_mapping: nil, tp_hash: nil, tp_call: nil, tp_str: nil, tp_getattro: nil, tp_setattro: nil, tp_as_buffer: nil, tp_flags: 0, tp_doc: nil, tp_traverse: nil, tp_clear: nil, tp_richcompare: nil, tp_weaklistoffset: Py_ssize_t(0), tp_iter: nil, tp_iternext: nil, tp_methods: nil, tp_members: nil, tp_getset: nil, tp_base: nil, tp_dict: nil, tp_descr_get: nil, tp_descr_set: nil, tp_dictoffset: Py_ssize_t(0), tp_init: nil, tp_alloc: nil, tp_new: nil, tp_free: nil, tp_is_gc: nil, tp_bases: nil, tp_mro: nil, tp_cache: nil, tp_subclasses: nil, tp_weaklist: nil, tp_del: nil, tp_version_tag: 0, tp_finalize: nil, tp_vectorcall: nil)

let moduleName: UnsafeMutablePointer<Int8>! = strdup("iraspa")
let libraryName: UnsafeMutablePointer<Int8>! = strdup("library")
let projectsName: UnsafeMutablePointer<Int8>! = strdup("projects")

//var pythonMethodsiRASPA: [PyMethodDef] = []
var logModule: PyModuleDef = PyModuleDef()

let libraryPyCFunction: PyCFunction = { (this, args) in
  return Py_VaBuildValue(strdup("s"), getVaList([strdup("Python: library")]))
}

let projectsPyCFunction: PyCFunction = { (this, args) in
  return Py_VaBuildValue(strdup("s"), getVaList([strdup("Python: projects")]))
}



var pythonMethodsiRASPA: [PyMethodDef] = [
  PyMethodDef(ml_name: libraryName, ml_meth: libraryPyCFunction, ml_flags: Int32(METH_VARARGS), ml_doc: nil),
  PyMethodDef(ml_name: projectsName, ml_meth: projectsPyCFunction, ml_flags: Int32(METH_VARARGS), ml_doc: nil),
  PyMethodDef()]


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
  pythonMethodsiRASPA = [PyMethodDef(ml_name: libraryName, ml_meth: libraryPyCFunction, ml_flags: Int32(METH_VARARGS), ml_doc: nil),
                PyMethodDef(ml_name: projectsName, ml_meth: projectsPyCFunction, ml_flags: Int32(METH_VARARGS), ml_doc: nil),
                PyMethodDef()]
  
  
  pythonMethodsiRASPA.withUnsafeMutableBufferPointer{ (bp) in
  let rbp = UnsafeMutableRawBufferPointer(bp)
  if let pointer: UnsafeMutablePointer<PyMethodDef> = rbp.baseAddress?.bindMemory(to: PyMethodDef.self, capacity: rbp.count)
  {
    logModule = PyModuleDef(m_base: PyModuleDef_Base(), m_name: moduleName, m_doc: nil, m_size: -1, m_methods: pointer, m_slots: nil, m_traverse: nil, m_clear: nil, m_free: nil)
    }
    debugPrint("adding module")
    PyImport_AppendInittab(moduleName, PyInit_PythonModuleiRASPA)
  }
}

/*
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
  
  unsafeBitCast(Py_IncRef, to: UnsafeMutableRawPointer.self)
}

*/
