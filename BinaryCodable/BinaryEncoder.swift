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

import CoreFoundation
import MathKit
import simd

/// A protocol for types which can be encoded to binary.
public protocol BinaryEncodable
{
  func binaryEncode(to encoder: BinaryEncoder)
}

public protocol BinaryEncodableRepresentedObject
{
  func binaryEncode(to encoder: BinaryEncoder, encodeRepresentedObject: Bool)
}

public protocol BinaryEncodableRecursive
{
  func binaryEncode(to encoder: BinaryEncoder, encodeRepresentedObject: Bool, encodeChildren: Bool)
}


/// The actual binary encoder class.
public class BinaryEncoder
{
  public var data: [UInt8] = []
  
  public init() {}
}


/// Methods for encoding various types.
public extension BinaryEncoder
{
  func encode(_ value: UInt8)
  {
    appendBytes(of: value.bigEndian)
  }
  
  func encode(_ value: Character)
  {
    let byte: UInt16 = Array(String(value).utf16)[0]
    appendBytes(of: byte.bigEndian)
  }
  
  func encode(_ value: Int8)
  {
    appendBytes(of: value.bigEndian)
  }
  
  func encode(_ value: UInt16)
  {
    appendBytes(of: value.bigEndian)
  }
  
  func encode(_ value: UInt32)
  {
    appendBytes(of: value.bigEndian)
  }
  
  func encode(_ value: Int32)
  {
    appendBytes(of: value.bigEndian)
  }
  
  func encode(_ value: Int64)
  {
    appendBytes(of: value.bigEndian)
  }
  
  func encode(_ value: Int)
  {
    appendBytes(of: value.bigEndian)
  }
  
  func encode(_ value: Bool)
  {
    encode(value ? 1 as UInt8 : 0 as UInt8)
  }
  
  func encode(_ value: Float)
  {
    appendBytes(of: value.bitPattern.bigEndian)
  }
  
  func encode(_ value: Double)
  {
    appendBytes(of: value.bitPattern.bigEndian)
  }
  
  func encode(_ value: SIMD3<Int32>)
  {
    self.encode(value.x)
    self.encode(value.y)
    self.encode(value.z)
  }
  
  func encode(_ value: Bool3)
  {
    self.encode(value.x)
    self.encode(value.y)
    self.encode(value.z)
  }
  
  func encode(_ value: SIMD2<Float>)
  {
    self.encode(value.x)
    self.encode(value.y)
  }
  
  func encode(_ value: SIMD2<Double>)
  {
    self.encode(value.x)
    self.encode(value.y)
  }
  
  func encode(_ value: SIMD3<Float>)
  {
    self.encode(value.x)
    self.encode(value.y)
    self.encode(value.z)
  }
  
  func encode(_ value: SIMD3<Double>)
  {
    self.encode(value.x)
    self.encode(value.y)
    self.encode(value.z)
  }
  
  func encode(_ value: SIMD4<Float>)
  {
    self.encode(value.x)
    self.encode(value.y)
    self.encode(value.z)
    self.encode(value.w)
  }
  
  func encode(_ value: SIMD4<Double>)
  {
    self.encode(value.x)
    self.encode(value.y)
    self.encode(value.z)
    self.encode(value.w)
  }
  
  /*
  func encode(_ value: [IndexPath])
  {
    self.encode(value.count)
    for index in value
    {
      self.encode(index)
    }
  }
  
  func encode(_ value: IndexPath)
  {
    self.encode(value.count)
    for index in value
    {
      self.encode(index)
    }
  }*/
  
  func encode(_ value: String)
  {
    let array: [UInt16] = Array(value.utf16)
    let length: UInt32 = array.isEmpty ? UInt32(0xFFFFFFFF) : UInt32(array.count * 2)
    self.encode(length)
    for word in array
    {
      self.encode(word)
    }
  }
  
  func encode(_ value: NSColor)
  {
    let color = value.usingColorSpace(NSColorSpace.deviceRGB) ?? NSColor.white
    self.encode(Int8(1))
    self.encode(UInt16(color.alphaComponent*65535.0))
    self.encode(UInt16(color.redComponent*65535.0))
    self.encode(UInt16(color.greenComponent*65535.0))
    self.encode(UInt16(color.blueComponent*65535.0))
    self.encode(UInt16(0))
  }
  
  func encode(_ value: Data)
  {
    if value.isEmpty
    {
      self.encode(UInt32(0xFFFFFFFF))
      return
    }
    self.encode(UInt32(value.count))
    data.append(contentsOf: value)
  }
  
  func encode(_ type: Dictionary<String, NSColor>)
  {
    if(type.isEmpty)
    {
      self.encode(UInt32(0xFFFFFFFF))
      return
    }
    self.encode(UInt32(type.count))
    
    for (key, value) in type
    {
      self.encode(key)
      self.encode(value)
    }
  }
  
  func encode(_ encodable: BinaryEncodable)
  {
    encodable.binaryEncode(to: self)
  }
  
  func encode(_ encodable: BinaryEncodableRepresentedObject, encodeRepresentedObject: Bool)
  {
    encodable.binaryEncode(to: self, encodeRepresentedObject: encodeRepresentedObject)
  }
  
  func encode(_ encodable: BinaryEncodableRecursive, encodeRepresentedObject: Bool, encodeChildren: Bool)
  {
    encodable.binaryEncode(to: self, encodeRepresentedObject: encodeRepresentedObject, encodeChildren: encodeChildren)
  }
  
  
  
  /// Append the raw bytes of the parameter to the encoder's data. No byte-swapping
  /// or other encoding is done.
  func appendBytes<T>(of: T)
  {
    var target = of
    withUnsafeBytes(of: &target) {
      data.append(contentsOf: $0)
    }
  }
}

