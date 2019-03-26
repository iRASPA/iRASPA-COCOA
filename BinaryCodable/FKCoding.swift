/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2019 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import Compression



extension PropertyListDecoder
{
  public func decodeCompressed<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
  {
    let archiveSize: Int = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Int in
      ptr.load(as: Int.self)
    }
    var data = data.advanced(by: MemoryLayout<Int>.stride)
    
    let compressedSize: Int = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Int in
      return ptr.load(as: Int.self)
    }
    data = data.advanced(by: MemoryLayout<Int>.stride)
    
    let compressionType: UInt32 = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> UInt32 in
      return ptr.load(as: UInt32.self)
    }
    data = data.advanced(by: MemoryLayout<UInt32>.stride)
    
    var archiveData: [UInt8] = [UInt8](repeatElement(0, count: archiveSize))
    
    let projectData: Data
    if compressedSize == 0
    {
      projectData = data
    }
    else
    {
      let _ = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> size_t in
        return compression_decode_buffer(&archiveData, archiveSize, ptr.baseAddress!.assumingMemoryBound(to: UInt8.self), data.count, nil, compression_algorithm(rawValue: compressionType))
      }
      projectData = Data(bytes: archiveData, count: archiveSize)
    }
    
    return try decode(type, from: projectData)
  }
}
