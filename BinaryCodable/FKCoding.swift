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
    let archiveSize = data.withUnsafeBytes { (ptr: UnsafePointer<Int>) -> Int in
      return ptr.pointee
    }
    var data = data.advanced(by: MemoryLayout<Int>.stride)
    
    let compressedSize = data.withUnsafeBytes { (ptr: UnsafePointer<Int>) -> Int in
      return ptr.pointee
    }
    data = data.advanced(by: MemoryLayout<Int>.stride)
    
    let compressionType: UInt32 = data.withUnsafeBytes { (ptr: UnsafePointer<UInt32>) -> UInt32 in
      return ptr.pointee
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
      let _ = data.withUnsafeBytes {
        compression_decode_buffer(&archiveData, archiveSize, $0, data.count, nil, compression_algorithm(rawValue: compressionType))
      }
      projectData = Data(bytes: archiveData, count: archiveSize)
    }
    
    return try decode(type, from: projectData)
  }
  
}

/*
 
 public class FKArchiver: NSArchiver
 {
 public var encodeObject: Bool = true
 public var encodeChildren: Bool = true
 
 public class func archivedData(withRootObject rootObject: Any, encodeObject: Bool, encodeChildren: Bool, compressionAlgorithm: compression_algorithm = COMPRESSION_LZFSE) -> Data
 {
 let data: NSMutableData = NSMutableData()
 let archiver: FKArchiver = FKArchiver(forWritingWith: data)
 archiver.encodeChildren = encodeChildren
 archiver.encodeObject = encodeObject
 archiver.encode(NSNumber(booleanLiteral: encodeObject))
 archiver.encode(NSNumber(booleanLiteral: encodeChildren))
 archiver.encodeRootObject(rootObject)
 
 
 var archiveSize: Int = size_t(data.length)
 var destination = [UInt8](repeatElement(0, count: Int(archiveSize)))
 
 let ptr = data.bytes.bindMemory(to: UInt8.self, capacity: data.length)
 var compressedSize: Int = compression_encode_buffer(&destination, archiveSize, ptr, archiveSize, nil, compressionAlgorithm)
 
 
 // if the compressed data size was not smaller than the uncompressed size then use the uncompressed data
 let compressedData: NSMutableData = NSMutableData()
 compressedData.append(&archiveSize, length: MemoryLayout<Int>.stride)
 compressedData.append(&compressedSize, length: MemoryLayout<Int>.stride)
 var compressionRawValue: UInt32 = compressionAlgorithm.rawValue
 compressedData.append(&compressionRawValue, length: MemoryLayout<UInt32>.stride)
 compressedData.append(compressedSize == 0 ? data as Data : Data(bytes: destination, count: compressedSize))
 
 return compressedData as Data
 }
 }
 
 
 
 
 public class FKUnarchiver: NSUnarchiver
 {
 public var encodeObject: Bool = true
 public var encodeChildren: Bool = true
 
 public enum DecodeError: Error, LocalizedError
 {
 case invalidArchive
 
 public var errorDescription: String?
 {
 switch self
 {
 case .invalidArchive:
 return NSLocalizedString("The archive-file is incompatible or corrupt.", comment: "Archive is inconsistent")
 }
 }
 }
 
 
 
 
 public class func unarchiveRootObject(with data: Data) throws -> Any?
 {
 let archiveSize = data.withUnsafeBytes { (ptr: UnsafePointer<Int>) -> Int in
 return ptr.pointee
 }
 //var data = data.advanced(by: MemoryLayout<Int>.stride)
 var data = data.subdata(in: MemoryLayout<Int>.stride..<data.count)
 
 let compressedSize = data.withUnsafeBytes { (ptr: UnsafePointer<Int>) -> Int in
 return ptr.pointee
 }
 //data = data.advanced(by: MemoryLayout<Int>.stride)
 data = data.subdata(in: MemoryLayout<Int>.stride..<data.count)
 
 let compressionType: UInt32 = data.withUnsafeBytes { (ptr: UnsafePointer<UInt32>) -> UInt32 in
 return ptr.pointee
 }
 //data = data.advanced(by: MemoryLayout<UInt32>.stride)
 data = data.subdata(in: MemoryLayout<UInt32>.stride..<data.count)
 
 var archiveData: [UInt8] = [UInt8](repeatElement(0, count: archiveSize))
 
 let projectData: Data
 if compressedSize == 0
 {
 projectData = data
 }
 else
 {
 let _ = data.withUnsafeBytes {
 compression_decode_buffer(&archiveData, archiveSize, $0, data.count, nil, compression_algorithm(rawValue: compressionType))
 }
 projectData = Data(bytes: archiveData, count: archiveSize)
 }
 
 
 if let unarchiver: FKUnarchiver = FKUnarchiver(forReadingWith: projectData)
 {
 var object: Any?
 do
 {
 try ObjC.catchException({
 unarchiver.encodeObject  = (unarchiver.decodeObject() as? NSNumber)?.boolValue ?? true
 unarchiver.encodeChildren = (unarchiver.decodeObject() as? NSNumber)?.boolValue ?? true
 object = unarchiver.decodeObject()
 })
 }
 catch
 {
 throw DecodeError.invalidArchive
 }
 
 return object
 }
 return nil
 }
 
 }
 */

