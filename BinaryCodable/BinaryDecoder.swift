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

import Foundation
import MathKit
import simd

/// A protocol for types which can be decoded from binary.
public protocol BinaryDecodable
{
  init(fromBinary decoder: BinaryDecoder) throws
}

public protocol BinaryDecodableRepresentedObject
{
  init(fromBinary decoder: BinaryDecoder, decodeRepresentedObject: Bool) throws
}

public protocol BinaryDecodableRecursive
{
  init(fromBinary decoder: BinaryDecoder, decodeRepresentedObject: Bool, decodeChildren: Bool) throws
}


public struct BinaryDecodableError
{
  public static var domain = "nl.darkwing.iRASPA"
  
  public enum code: Int
  {
    case invalidArchiveVersion
  }
  
  public static let invalidArchiveVersion: NSError = NSError.init(domain: BinaryDecodableError.domain, code: BinaryDecodableError.code.invalidArchiveVersion.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Invalid archive version (upgrade to latest iRASPA version)", comment: "Invalid archive version (upgrade to latest iRASPA version)")])
}

/// The actual binary decoder class.
public class BinaryDecoder
{
  fileprivate let data: [UInt8]
  fileprivate var cursor = 0
  
  public init(data: [UInt8])
  {
    self.data = data
  }
}



/// The error type.
public extension BinaryDecoder
{
  /// All errors which `BinaryDecoder` itself can throw.
  enum Error: Swift.Error
  {
    /// The decoder hit the end of the data while the values it was decoding expected
    /// more.
    case prematureEndOfData
    
    /// Attempted to decode a type which is `Decodable`, but not `BinaryDecodable`. (We
    /// require `BinaryDecodable` because `BinaryDecoder` doesn't support full keyed
    /// coding functionality.)
    case typeNotConformingToBinaryDecodable(BinaryDecodable.Type)
    
    /// Attempted to decode a type which is not `Decodable`.
    case typeNotConformingToDecodable(Any.Type)
    
    /// Attempted to decode an `Int` which can't be represented. This happens in 32-bit
    /// code when the stored `Int` doesn't fit into 32 bits.
    case intOutOfRange(Int64)
    
    /// Attempted to decode a `UInt` which can't be represented. This happens in 32-bit
    /// code when the stored `UInt` doesn't fit into 32 bits.
    case uintOutOfRange(UInt64)
    
    /// Attempted to decode a `Bool` where the byte representing it was not a `1` or a
    /// `0`.
    case boolOutOfRange(UInt8)
    
    /// Attempted to decode a `String` but the encoded `String` data was not valid
    /// UTF-8.
    case invalidUTF8([UInt8])
  }
}

/// Methods for decoding various types.
public extension BinaryDecoder
{
  func decode(_ type: UInt8.Type) throws -> UInt8
  {
    var swapped = UInt8()
    try read(into: &swapped)
    return UInt8(bigEndian: swapped)
  }
  
  func decode(_ type: Int8.Type) throws -> Int8
  {
    var swapped = Int8()
    try read(into: &swapped)
    return Int8(bigEndian: swapped)
  }
  
  func decode(_ type: UInt16.Type) throws -> UInt16
  {
    var swapped = UInt16()
    try read(into: &swapped)
    return UInt16(bigEndian: swapped)
  }
  
  func decode(_ type: Int16.Type) throws -> Int16
  {
    var swapped = Int16()
    try read(into: &swapped)
    return Int16(bigEndian: swapped)
  }
  
  func decode(_ type: UInt32.Type) throws -> UInt32
  {
    var swapped = UInt32()
    try read(into: &swapped)
    return UInt32(bigEndian: swapped)
  }
  
  func decode(_ type: Int32.Type) throws -> Int32
  {
    var swapped = Int32()
    try read(into: &swapped)
    return Int32(bigEndian: swapped)
  }
  
  func decode(_ type: Int64.Type) throws -> Int64
  {
    var swapped = Int64()
    try read(into: &swapped)
    return Int64(bigEndian: swapped)
  }
  
  func decode(_ type: Int.Type) throws -> Int
  {
    var swapped = Int()
    try read(into: &swapped)
    return Int(bigEndian: swapped)
  }
  
  
  func decode(_ type: Bool.Type) throws -> Bool
  {
    switch try decode(UInt8.self)
    {
    case 0: return false
    case 1: return true
    case let x: throw Error.boolOutOfRange(x)
    }
  }
  
  func decode(_ type: Float.Type) throws -> Float
  {
    var swapped = UInt32()
    try read(into: &swapped)
    return Float(bitPattern: UInt32(bigEndian: swapped))
  }
  
  func decode(_ type: Double.Type) throws -> Double
  {
    var swapped = UInt64()
    try read(into: &swapped)
    return Double(bitPattern: UInt64(bigEndian: swapped))
  }
  
  func decode(_ type: Character.Type) throws -> Character
  {
    var swapped = UInt16()
    try read(into: &swapped)
    return Character(Unicode.Scalar( UInt16(bigEndian: swapped)) ?? "X")
  }
  
  func decode(_ type: SIMD3<Int32>.Type) throws -> SIMD3<Int32>
  {
    let x: Int32 = try decode(Int32.self)
    let y: Int32 = try decode(Int32.self)
    let z: Int32 = try decode(Int32.self)
    return SIMD3<Int32>(x,y,z)
  }
  
  func decode(_ type: Bool3.Type) throws -> Bool3
  {
    let x: Bool = try decode(Bool.self)
    let y: Bool = try decode(Bool.self)
    let z: Bool = try decode(Bool.self)
    return Bool3(x,y,z)
  }
  
  func decode(_ type: SIMD2<Float>.Type) throws -> SIMD2<Float>
  {
    let x: Float = try decode(Float.self)
    let y: Float = try decode(Float.self)
    return SIMD2<Float>(x,y)
  }
  
  func decode(_ type: SIMD2<Double>.Type) throws -> SIMD2<Double>
  {
    let x: Double = try decode(Double.self)
    let y: Double = try decode(Double.self)
    return SIMD2<Double>(x,y)
  }
  
  func decode(_ type: SIMD3<Float>.Type) throws -> SIMD3<Float>
  {
    let x: Float = try decode(Float.self)
    let y: Float = try decode(Float.self)
    let z: Float = try decode(Float.self)
    return SIMD3<Float>(x,y,z)
  }
  
  func decode(_ type: SIMD3<Double>.Type) throws -> SIMD3<Double>
  {
    let x: Double = try decode(Double.self)
    let y: Double = try decode(Double.self)
    let z: Double = try decode(Double.self)
    return SIMD3<Double>(x,y,z)
  }
  
  func decode(_ type: SIMD4<Float>.Type) throws -> SIMD4<Float>
  {
    let x: Float = try decode(Float.self)
    let y: Float = try decode(Float.self)
    let z: Float = try decode(Float.self)
    let w: Float = try decode(Float.self)
    return SIMD4<Float>(x,y,z,w)
  }
  
  
  func decode(_ type: SIMD4<Double>.Type) throws -> SIMD4<Double>
  {
    let x: Double = try decode(Double.self)
    let y: Double = try decode(Double.self)
    let z: Double = try decode(Double.self)
    let w: Double = try decode(Double.self)
    return SIMD4<Double>(x,y,z,w)
  }
  
  
  func decode(_ type: String.Type) throws -> String
  {
    let count: UInt32 = try self.decode(UInt32.self)
    if(count != 0xFFFFFFFF)
    {
      var array: [UInt8] = []
      array.reserveCapacity(Int(count))
      for _ in 0..<Int(count)
      {
        let utf8 = try self.decode(UInt8.self)
        array.append(utf8)
      }
    
      if let str = String(bytes: array, encoding: .utf16BigEndian)
      {
        return str
      }
    }
     return String("")
  }
  
  func decode(_ type: Data.Type) throws -> Data
  {
    let count: UInt32 = try self.decode(UInt32.self)
    if(count != 0xFFFFFFFF)
    {
      var data: Data = Data(count: Int(count))
      
      try data.withUnsafeMutableBytes { (rawPtr) in
          try self.read(Int(count), into: rawPtr.baseAddress!)
      }
      return data
    }
    return Data()
  }
  
  func decode(_ type: Dictionary<String, NSColor>.Type) throws -> Dictionary<String, NSColor>
  {
    var dictionary: Dictionary<String, NSColor> = Dictionary<String, NSColor>()
    let count: UInt32 = try self.decode(UInt32.self)
    if(count != UInt32(0xFFFFFFFF))
    {
      dictionary.reserveCapacity(Int(count))
      for _ in 0 ..< Int(count)
      {
        let decodedString = try self.decode(String.self)
        let decodedValue = try self.decode(NSColor.self)
        dictionary[decodedString] = decodedValue
      }
    }
    return dictionary
  }
  
  func decode(_ type: NSColor.Type) throws -> NSColor
  {
    var swappedSpec = Int8()
    try read(into: &swappedSpec)
    let _ = Int8(bigEndian: swappedSpec)
    
    var swappedA = UInt16()
    try read(into: &swappedA)
    let a = UInt16(bigEndian: swappedA)
    
    var swappedR = UInt16()
    try read(into: &swappedR)
    let r = UInt16(bigEndian: swappedR)
    
    var swappedG = UInt16()
    try read(into: &swappedG)
    let g = UInt16(bigEndian: swappedG)
    
    var swappedB = UInt16()
    try read(into: &swappedB)
    let b = UInt16(bigEndian: swappedB)
    
    var swappedP = UInt16()
    try read(into: &swappedP)
    let _ = UInt16(bigEndian: swappedP)
    
    return NSColor(red: CGFloat(r)/65535.0, green: CGFloat(g)/65535.0, blue: CGFloat(b)/65535.0, alpha: CGFloat(a)/65535.0)
  }
  
  
  func decode(_ type: Dictionary<String, NSColor>) throws -> Dictionary<String, NSColor>
  {
      let count: UInt32 = try self.decode(UInt32.self)
      //debugPrint("array count: \(count)")
    var dictionary: Dictionary<String, NSColor> = [:]
      if(count != UInt32(0xFFFFFFFF))
      {
        for _ in 0 ..< Int(count)
        {
          let decodedString = try self.decode(String.self)
          let decodedValue = try self.decode(NSColor.self)
          dictionary[decodedString] = decodedValue
        }
      }
    return dictionary
  }

  func decode<T: BinaryDecodable>(_ type: T.Type) throws -> T
  {
    return try type.init(fromBinary: self)
  }
  
  func decode<T: BinaryDecodableRepresentedObject>(_ type: T.Type, decodeRepresentedObject: Bool) throws -> T
  {
    return try type.init(fromBinary: self, decodeRepresentedObject: decodeRepresentedObject)
  }
  
  func decode<T: BinaryDecodableRecursive>(_ type: T.Type, decodeRepresentedObject: Bool, decodeChildren: Bool) throws -> T
  {
    return try type.init(fromBinary: self, decodeRepresentedObject: decodeRepresentedObject, decodeChildren: decodeChildren)
  }
  
  /// Read the appropriate number of raw bytes directly into the given value. No byte
  /// swapping or other postprocessing is done.
  func read<T>(into: inout T) throws
  {
    try read(MemoryLayout<T>.size, into: &into)
  }
}

/// Internal methods for decoding raw data.
extension BinaryDecoder
{
  /// Read the given number of bytes into the given pointer, advancing the cursor
  /// appropriately.
  public func read(_ byteCount: Int, into: UnsafeMutableRawPointer) throws
  {
    if cursor + byteCount > data.count
    {
      throw Error.prematureEndOfData
    }
    
    data.withUnsafeBytes({
      let from = $0.baseAddress! + cursor
      memcpy(into, from, byteCount)
    })
    
    cursor += byteCount
  }
}

extension BinaryDecoder
{
  public func windBack(_ byteCount: Int)
  {
    cursor -= byteCount
  }
}
