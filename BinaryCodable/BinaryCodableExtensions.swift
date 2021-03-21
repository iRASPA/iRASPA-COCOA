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

import Foundation
import MathKit
import simd

public typealias BinaryCodable = BinaryEncodable & BinaryDecodable

/// Implementations of BinaryCodable for built-in types.

extension Int32: BinaryEncodable
{
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(Int32(self))
  }
}

extension Int32: BinaryDecodable
{
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let x: Int32 = try decoder.decode(Int32.self)
    self.init(x)
  }
}

extension Float: BinaryEncodable
{
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(self)
  }
}

extension Float: BinaryDecodable
{
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let x: Float = try decoder.decode(Float.self)
    self.init(x)
  }
}


extension SIMD2: BinaryEncodable where Scalar: BinaryEncodable
{
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(self.x)
    encoder.encode(self.y)
  }
}

extension SIMD2: BinaryDecodable where Scalar: BinaryDecodable
{
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let x: Scalar = try decoder.decode(Scalar.self)
    let y: Scalar = try decoder.decode(Scalar.self)
    self.init(x: x, y: y)
  }
}

extension Bool3: BinaryEncodable
{
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(self.x)
    encoder.encode(self.y)
    encoder.encode(self.z)
  }
}

extension Bool3: BinaryDecodable
{
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let x: Bool = try decoder.decode(Bool.self)
    let y: Bool = try decoder.decode(Bool.self)
    let z: Bool = try decoder.decode(Bool.self)
    self.init(x, y, z)
  }
}

extension SIMD3: BinaryEncodable where Scalar: BinaryEncodable
{
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(self.x)
    encoder.encode(self.y)
    encoder.encode(self.z)
  }
}

extension SIMD3: BinaryDecodable where Scalar: BinaryDecodable
{
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let x: Scalar = try decoder.decode(Scalar.self)
    let y: Scalar = try decoder.decode(Scalar.self)
    let z: Scalar = try decoder.decode(Scalar.self)
    self.init(x: x, y: y, z: z)
  }
}

extension SIMD4: BinaryEncodable where Scalar: BinaryEncodable
{
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(self.x)
    encoder.encode(self.y)
    encoder.encode(self.z)
    encoder.encode(self.w)
  }
}

extension SIMD4: BinaryDecodable where Scalar: BinaryDecodable
{
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let x: Scalar = try decoder.decode(Scalar.self)
    let y: Scalar = try decoder.decode(Scalar.self)
    let z: Scalar = try decoder.decode(Scalar.self)
    let w: Scalar = try decoder.decode(Scalar.self)
    self.init(x: x, y: y, z: z, w: w)
  }
}

extension Array: BinaryEncodable where Element: BinaryEncodable
{
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(UInt32(self.count))
    for element in self
    {
      element.binaryEncode(to: encoder)
      //element.encode(to: encoder)
    }
  }
}


extension Array: BinaryEncodableRecursive where Element: BinaryEncodableRecursive
{
  public func binaryEncode(to encoder: BinaryEncoder, encodeRepresentedObject: Bool, encodeChildren: Bool)
  {
    encoder.encode(UInt32(self.count))
    for element in self
    {
      element.binaryEncode(to: encoder, encodeRepresentedObject: encodeRepresentedObject, encodeChildren: encodeChildren)
      //element.encode(to: encoder)
    }
  }
}

extension Array: BinaryDecodable where Element: BinaryDecodable
{
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let count: UInt32 = try decoder.decode(UInt32.self)
    self.init()
    if(count != UInt32(0xFFFFFFFF))
    {
      self.reserveCapacity(Int(count))
      for _ in 0 ..< Int(count)
      {
        let decoded = try Element.init(fromBinary: decoder)
        self.append(decoded)
      }
    }
  }
}

extension Array: BinaryDecodableRecursive where Element: BinaryDecodableRecursive
{
  public init(fromBinary decoder: BinaryDecoder, decodeRepresentedObject: Bool, decodeChildren: Bool) throws
  {
    let count: UInt32 = try decoder.decode(UInt32.self)
    //debugPrint("array count: \(count)")
    self.init()
    if(count != UInt32(0xFFFFFFFF))
    {
      self.reserveCapacity(Int(count))
      for _ in 0 ..< Int(count)
      {
        let decoded = try Element.init(fromBinary: decoder, decodeRepresentedObject: decodeRepresentedObject, decodeChildren: decodeChildren)
        self.append(decoded)
      }
    }
  }
}



extension simd_quatd: BinaryEncodable
{
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(self.imag.x)
    encoder.encode(self.imag.y)
    encoder.encode(self.imag.z)
    encoder.encode(self.real)
  }
}

extension simd_quatd: BinaryDecodable
{
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let ix: Double = try decoder.decode(Double.self)
    let iy: Double = try decoder.decode(Double.self)
    let iz: Double = try decoder.decode(Double.self)
    let r: Double = try decoder.decode(Double.self)
    self.init(ix: ix, iy: iy, iz: iz, r: r)
  }
}


extension double3x3: BinaryEncodable
{
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(self[0][0])
    encoder.encode(self[0][1])
    encoder.encode(self[0][2])
    encoder.encode(self[1][0])
    encoder.encode(self[1][1])
    encoder.encode(self[1][2])
    encoder.encode(self[2][0])
    encoder.encode(self[2][1])
    encoder.encode(self[2][2])
  }
}

extension double3x3: BinaryDecodable
{
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let ax: Double = try decoder.decode(Double.self)
    let ay: Double = try decoder.decode(Double.self)
    let az: Double = try decoder.decode(Double.self)
    let bx: Double = try decoder.decode(Double.self)
    let by: Double = try decoder.decode(Double.self)
    let bz: Double = try decoder.decode(Double.self)
    let cx: Double = try decoder.decode(Double.self)
    let cy: Double = try decoder.decode(Double.self)
    let cz: Double = try decoder.decode(Double.self)
    self.init(SIMD3<Double>(ax,ay,az), SIMD3<Double>(bx,by,bz), SIMD3<Double>(cx,cy,cz))
  }
}

extension Set: BinaryEncodable where Element: BinaryEncodable
{
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(UInt32(self.count))
    for element in self
    {
      element.binaryEncode(to: encoder)
    }
  }
}

extension Set: BinaryDecodable where Element: BinaryDecodable
{
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let count: UInt32 = try decoder.decode(UInt32.self)
    //debugPrint("array count: \(count)")
    self.init()
    if(count != UInt32(0xFFFFFFFF))
    {
      self.reserveCapacity(Int(count))
      for _ in 0 ..< Int(count)
      {
        let decoded = try Element.init(fromBinary: decoder)
        self.insert(decoded)
      }
    }
  }
}
