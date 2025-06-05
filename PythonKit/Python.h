#ifndef Py_PYTHON_H
#define Py_PYTHON_H
/* Since this is a "meta-include" file, no #ifdef __cplusplus / extern "C" { */

/* Include nearly all Python header files */

#include <PythonKit/patchlevel.h>
#include <PythonKit/pyconfig.h>
#include <PythonKit/pymacconfig.h>

#include <limits.h>

#ifndef UCHAR_MAX
#error "Something's broken.  UCHAR_MAX should be defined in limits.h."
#endif

#if UCHAR_MAX != 255
#error "Python's source code assumes C's unsigned char is an 8-bit type."
#endif

#if defined(__sgi) && !defined(_SGI_MP_SOURCE)
#define _SGI_MP_SOURCE
#endif

#include <stdio.h>
#ifndef NULL
#   error "Python.h requires that stdio.h define NULL."
#endif

#include <string.h>
#ifdef HAVE_ERRNO_H
#include <errno.h>
#endif
#include <stdlib.h>
#ifndef MS_WINDOWS
#include <unistd.h>
#endif
#ifdef HAVE_CRYPT_H
#if defined(HAVE_CRYPT_R) && !defined(_GNU_SOURCE)
/* Required for glibc to expose the crypt_r() function prototype. */
#  define _GNU_SOURCE
#  define _Py_GNU_SOURCE_FOR_CRYPT
#endif
#include <crypt.h>
#ifdef _Py_GNU_SOURCE_FOR_CRYPT
/* Don't leak the _GNU_SOURCE define to other headers. */
#  undef _GNU_SOURCE
#  undef _Py_GNU_SOURCE_FOR_CRYPT
#endif
#endif

/* For size_t? */
#ifdef HAVE_STDDEF_H
#include <stddef.h>
#endif

/* CAUTION:  Build setups should ensure that NDEBUG is defined on the
 * compiler command line when building Python in release mode; else
 * assert() calls won't be removed.
 */
#include <assert.h>

#include <PythonKit/pyport.h>
#include <PythonKit/pymacro.h>

/* A convenient way for code to know if clang's memory sanitizer is enabled. */
#if defined(__has_feature)
#  if __has_feature(memory_sanitizer)
#    if !defined(_Py_MEMORY_SANITIZER)
#      define _Py_MEMORY_SANITIZER
#    endif
#  endif
#endif

/* Debug-mode build with pymalloc implies PYMALLOC_DEBUG.
 *  PYMALLOC_DEBUG is in error if pymalloc is not in use.
 */
#if defined(Py_DEBUG) && defined(WITH_PYMALLOC) && !defined(PYMALLOC_DEBUG)
#define PYMALLOC_DEBUG
#endif
#if defined(PYMALLOC_DEBUG) && !defined(WITH_PYMALLOC)
#error "PYMALLOC_DEBUG requires WITH_PYMALLOC"
#endif
#include <PythonKit/pymath.h>
#include <PythonKit/pytime.h>
#include <PythonKit/pymem.h>

#include <PythonKit/object.h>
#include <PythonKit/objimpl.h>
#include <PythonKit/typeslots.h>
#include <PythonKit/pyhash.h>

#include <PythonKit/pydebug.h>

#include <PythonKit/bytearrayobject.h>
#include <PythonKit/bytesobject.h>
#include <PythonKit/unicodeobject.h>
#include <PythonKit/longobject.h>
#include <PythonKit/longintrepr.h>
#include <PythonKit/boolobject.h>
#include <PythonKit/floatobject.h>
#include <PythonKit/complexobject.h>
#include <PythonKit/rangeobject.h>
#include <PythonKit/memoryobject.h>
#include <PythonKit/tupleobject.h>
#include <PythonKit/listobject.h>
#include <PythonKit/dictobject.h>
#include <PythonKit/odictobject.h>
#include <PythonKit/enumobject.h>
#include <PythonKit/setobject.h>
#include <PythonKit/methodobject.h>
#include <PythonKit/moduleobject.h>
#include <PythonKit/funcobject.h>
#include <PythonKit/classobject.h>
#include <PythonKit/fileobject.h>
#include <PythonKit/pycapsule.h>
#include <PythonKit/code.h>
#include <PythonKit/pyframe.h>
#include <PythonKit/traceback.h>
#include <PythonKit/sliceobject.h>
#include <PythonKit/cellobject.h>
#include <PythonKit/iterobject.h>
#include <PythonKit/genobject.h>
#include <PythonKit/descrobject.h>
#include <PythonKit/genericaliasobject.h>
#include <PythonKit/warnings.h>
#include <PythonKit/weakrefobject.h>
#include <PythonKit/structseq.h>
#include <PythonKit/namespaceobject.h>
#include <PythonKit/picklebufobject.h>

#include <PythonKit/codecs.h>
#include <PythonKit/pyerrors.h>

#include <PythonKit/cpython_initconfig.h>
#include <PythonKit/pythread.h>
#include <PythonKit/pystate.h>
#include <PythonKit/context.h>

#include <PythonKit/pyarena.h>
#include <PythonKit/modsupport.h>
#include <PythonKit/compile.h>
#include <PythonKit/pythonrun.h>
#include <PythonKit/pylifecycle.h>
#include <PythonKit/ceval.h>
#include <PythonKit/sysmodule.h>
#include <PythonKit/osmodule.h>
#include <PythonKit/intrcheck.h>
#include <PythonKit/import.h>

#include <PythonKit/abstract.h>
#include <PythonKit/bltinmodule.h>

#include <PythonKit/eval.h>

#include <PythonKit/pyctype.h>
#include <PythonKit/pystrtod.h>
#include <PythonKit/pystrcmp.h>
#include <PythonKit/fileutils.h>
#include <PythonKit/pyfpe.h>
#include <PythonKit/tracemalloc.h>

#endif /* !Py_PYTHON_H */
