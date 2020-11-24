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

// https://academy.realm.io/posts/altconf-nikita-lutsenko-objc-swift-interoperability/
// What NS_REFINED_FOR_SWIFT will do for you is add a double underscore to the function name that is
// imported into Swift. But since double underscores are there, and usually we don’t start methods in
// Swift with that, what it’s going to do is remove that from the typehead inside Xcode, as well.

import Foundation

public typealias PyObjectPointer = UnsafeMutableRawPointer
public typealias PyCCharPointer = UnsafePointer<Int8>
public typealias PyBinaryOperation =
    @convention(c) (PyObjectPointer?, PyObjectPointer?) -> PyObjectPointer?
public typealias PyUnaryOperation =
    @convention(c) (PyObjectPointer?) -> PyObjectPointer?


public let Py_IncRef: @convention(c) (PyObjectPointer?) -> Void = { pointer in
  __Py_IncRef(unsafeBitCast(pointer, to: UnsafeMutablePointer<PyObject>.self))
}

public let Py_DecRef: @convention(c) (PyObjectPointer?) -> Void = { pointer in
  __Py_DecRef(unsafeBitCast(pointer, to: UnsafeMutablePointer<PyObject>.self))
}

public let PyDict_New: @convention(c) () -> PyObjectPointer? = {
  unsafeBitCast(__PyDict_New(), to: PyObjectPointer.self)
}

public let PyDict_SetItem: @convention(c) (
  PyObjectPointer?, PyObjectPointer, PyObjectPointer) -> Void = { (p1,p2,p3) in
    __PyDict_SetItem(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self),
                unsafeBitCast(p3, to: UnsafeMutablePointer<PyObject>?.self))
  }

public let PyErr_Fetch: @convention(c) (
    UnsafeMutablePointer<PyObjectPointer?>,
    UnsafeMutablePointer<PyObjectPointer?>,
  UnsafeMutablePointer<PyObjectPointer?>) -> Void = { (p1, p2, p3) in
    __PyErr_Fetch(unsafeBitCast(p1, to: UnsafeMutablePointer<UnsafeMutablePointer<PyObject>?>?.self),
                unsafeBitCast(p2, to: UnsafeMutablePointer<UnsafeMutablePointer<PyObject>?>?.self),
                unsafeBitCast(p3, to: UnsafeMutablePointer<UnsafeMutablePointer<PyObject>?>?.self))
  }

public let PyObject_CallObject: @convention(c) (
  PyObjectPointer, PyObjectPointer) -> PyObjectPointer? = { (p1, p2) in
    return unsafeBitCast(__PyObject_CallObject(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                             unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}

public let PyObject_Call: @convention(c) (
    PyObjectPointer, PyObjectPointer, PyObjectPointer?) -> PyObjectPointer? = { (p1, p2, p3) in
        return unsafeBitCast(__PyObject_Call(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                           unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self),
                                           unsafeBitCast(p3, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
  }

public let PyObject_GetAttrString: @convention(c) (
  PyObjectPointer, PyCCharPointer) -> PyObjectPointer? = { (p1, p2) in
      return unsafeBitCast(__PyObject_GetAttrString(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                                  unsafeBitCast(p2, to: UnsafePointer<Int8>?.self)), to: PyObjectPointer?.self)
  }

public let PyObject_GetItem: @convention(c) (
    PyObjectPointer, PyObjectPointer) -> PyObjectPointer? = { (p1, p2) in
      return unsafeBitCast(__PyObject_GetItem(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                            unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
  }

public let PyObject_SetItem: @convention(c) (
    PyObjectPointer, PyObjectPointer, PyObjectPointer) -> Void = { (p1, p2, p3) in
      __PyObject_SetItem(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                       unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self),
                       unsafeBitCast(p3, to: UnsafeMutablePointer<PyObject>?.self))
    }

public let PyObject_DelItem: @convention(c) (
    PyObjectPointer, PyObjectPointer) -> Void = { (p1, p2) in
      __PyObject_DelItem(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                       unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self))
    }

public let PyObject_SetAttrString: @convention(c) (
    PyObjectPointer, PyCCharPointer, PyObjectPointer) -> Int32 = { (p1, p2, p3) in
      return __PyObject_SetAttrString(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                    unsafeBitCast(p2, to: UnsafePointer<Int8>?.self),
                                    unsafeBitCast(p3, to: UnsafeMutablePointer<PyObject>?.self))
}

public let PyTuple_SetItem: @convention(c) (
    PyObjectPointer, Int, PyObjectPointer) -> Void = { (p1, p2, p3) in
      __PyTuple_SetItem(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                      p2,
                      unsafeBitCast(p3, to: UnsafeMutablePointer<PyObject>?.self))
    }

public let PyTuple_New: @convention(c) (Int) -> PyObjectPointer? = { p in
    return unsafeBitCast(__PyTuple_New(p), to: PyObjectPointer?.self)
}

public let _Py_TrueStruct : PyObjectPointer = {
  return unsafeBitCast(___Py_TrueStruct, to: PyObjectPointer.self)
}()

public let _Py_FalseStruct : PyObjectPointer = {
  return unsafeBitCast(___Py_FalseStruct, to: PyObjectPointer.self)
}()

public let PySlice_Type: PyObjectPointer = {
  return unsafeBitCast(__PySlice_Type, to: PyObjectPointer.self)
}()

public let PyBool_Type: PyObjectPointer = {
  return unsafeBitCast(__PyBool_Type, to: PyObjectPointer.self)
}()




public let PyUnicode_AsUTF8: @convention(c) (PyObjectPointer) -> PyCCharPointer? = { p in
   return __PyUnicode_AsUTF8(unsafeBitCast(p, to: UnsafeMutablePointer<PyObject>?.self))
}

public let PyUnicode_DecodeUTF8: @convention(c) ( PyCCharPointer?, Int) -> (PyObjectPointer?) = { (p1, p2) in
  return unsafeBitCast(__PyUnicode_DecodeUTF8(p1, p2, nil), to: PyObjectPointer?.self)
}


public let PyLong_AsLong: @convention(c) (PyObjectPointer) -> Int = { p in
  return __PyLong_AsLong(unsafeBitCast(p, to: UnsafeMutablePointer<PyObject>?.self))
}

public let PyLong_FromLong: @convention(c) (Int) -> PyObjectPointer = { p in
  return unsafeBitCast(__PyLong_FromLong(p), to: PyObjectPointer.self)
}

public let PyLong_AsUnsignedLongMask: @convention(c) (PyObjectPointer) -> UInt = { p in
  return __PyLong_AsUnsignedLongMask(unsafeBitCast(p, to: UnsafeMutablePointer<PyObject>?.self))
}

public let PyLong_FromUnsignedLong: @convention(c) (UInt) -> PyObjectPointer = { p in
  return unsafeBitCast(__PyLong_FromUnsignedLong(p), to: PyObjectPointer.self)
}

public let PyFloat_AsDouble: @convention(c) (PyObjectPointer) -> Double = { p in
  return __PyFloat_AsDouble(unsafeBitCast(p, to: UnsafeMutablePointer<PyObject>?.self))
}

public let PyList_SetItem: @convention(c) ( PyObjectPointer, Int, PyObjectPointer) -> Int32 = { (p1, p2, p3) in
   return __PyList_SetItem(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                         p2,
                         unsafeBitCast(p3, to: UnsafeMutablePointer<PyObject>?.self))
}

public let PyDict_Next: @convention(c) (
    PyObjectPointer,
    UnsafeMutablePointer<Int>,
    UnsafeMutablePointer<PyObjectPointer?>,
    UnsafeMutablePointer<PyObjectPointer?>) -> Int32 = { (p1, p2, p3, p4) in
      return __PyDict_Next(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                            p2,
                            unsafeBitCast(p3, to: UnsafeMutablePointer<UnsafeMutablePointer<PyObject>?>?.self),
                            unsafeBitCast(p4, to: UnsafeMutablePointer<UnsafeMutablePointer<PyObject>?>?.self))
   }

public let PyObject_RichCompareBool: @convention(c) (PyObjectPointer, PyObjectPointer, Int32) -> Int32 = { (p1, p2, p3) in
    return __PyObject_RichCompareBool(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                    unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self),
                                    p3)
}

public let PyObject_RichCompare: @convention(c) (PyObjectPointer, PyObjectPointer, Int32) -> PyObjectPointer? = { (p1, p2, p3) in
    return unsafeBitCast(__PyObject_RichCompareBool(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                                    unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self),
                                                     p3), to: PyObjectPointer?.self)
}

public let PyIter_Next: @convention(c) (PyObjectPointer) -> PyObjectPointer? = { p in
  return unsafeBitCast(__PyIter_Next(unsafeBitCast(p, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}

public let PyObject_GetIter: @convention(c) (PyObjectPointer) -> PyObjectPointer? = { p in
  return unsafeBitCast(__PyObject_GetIter(unsafeBitCast(p, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}

public let PyImport_AddModule: @convention(c) (PyCCharPointer) -> PyObjectPointer? = { p in
  return unsafeBitCast(__PyImport_AddModule(p), to: PyObjectPointer?.self)
}

let PyRun_SimpleString: @convention(c) (PyCCharPointer) -> Void  = { p in
   __PyRun_SimpleString(p)
}

public let Py_LT: Int32 = 0
public let Py_LE: Int32 = 1
public let Py_EQ: Int32 = 2
public let Py_NE: Int32 = 3
public let Py_GT: Int32 = 4
public let Py_GE: Int32 = 5

public let PyNumber_Add: PyBinaryOperation = { (p1, p2) in
  return unsafeBitCast(__PyNumber_Add(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                    unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}

public let PyNumber_Subtract: PyBinaryOperation = { (p1, p2) in
  return unsafeBitCast(__PyNumber_Subtract(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                    unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}


public let PyNumber_Multiply: PyBinaryOperation = { (p1, p2) in
  return unsafeBitCast(__PyNumber_Multiply(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                    unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}


public let PyNumber_TrueDivide: PyBinaryOperation = { (p1, p2) in
  return unsafeBitCast(__PyNumber_TrueDivide(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                    unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}


public let PyNumber_InPlaceAdd: PyBinaryOperation = { (p1, p2) in
  return unsafeBitCast(__PyNumber_InPlaceAdd(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                    unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}

public let PyNumber_InPlaceSubtract: PyBinaryOperation = { (p1, p2) in
  return unsafeBitCast(__PyNumber_InPlaceSubtract(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                    unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}

public let PyNumber_InPlaceMultiply: PyBinaryOperation = { (p1, p2) in
  return unsafeBitCast(__PyNumber_InPlaceMultiply(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                    unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}

public let PyNumber_InPlaceTrueDivide: PyBinaryOperation = { (p1, p2) in
  return unsafeBitCast(__PyNumber_InPlaceTrueDivide(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                    unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}

public let PyNumber_Negative: PyUnaryOperation = { p in
  return unsafeBitCast(__PyNumber_Negative(unsafeBitCast(p, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}

let PyNumber_And: PyBinaryOperation = { (p1, p2) in
  return unsafeBitCast(__PyNumber_And(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                  unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}

let PyNumber_Or: PyBinaryOperation = { (p1, p2) in
  return unsafeBitCast(__PyNumber_Or(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                  unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}

let PyNumber_Xor: PyBinaryOperation = { (p1, p2) in
  return unsafeBitCast(__PyNumber_Xor(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                  unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}

let PyNumber_InPlaceAnd: PyBinaryOperation = { (p1, p2) in
  return unsafeBitCast(__PyNumber_InPlaceAnd(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                  unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}

let PyNumber_InPlaceOr: PyBinaryOperation = { (p1, p2) in
  return unsafeBitCast(__PyNumber_InPlaceOr(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                  unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}

let PyNumber_InPlaceXor: PyBinaryOperation = { (p1, p2) in
  return unsafeBitCast(__PyNumber_InPlaceXor(unsafeBitCast(p1, to: UnsafeMutablePointer<PyObject>?.self),
                                  unsafeBitCast(p2, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}

let PyNumber_Invert: PyUnaryOperation = { p in
  return unsafeBitCast(__PyNumber_Invert(unsafeBitCast(p, to: UnsafeMutablePointer<PyObject>?.self)), to: PyObjectPointer?.self)
}
