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
import BinaryCodable
import MathKit

public class RKLocalAxes: BinaryDecodable, BinaryEncodable
{
  private static var classVersionNumber: Int = 1
  
  public enum Style: Int
  {
    case `default` = 0
    case `defaultRGB` = 1
    case cylinder = 2
    case cylinderRGB = 3
  }
  
  public enum Position: Int
  {
    case none = 0
    case origin = 1
    case originBoundingBox = 2
    case center = 3
    case centerBoundingBox = 4
  }
  
  public enum ScalingType: Int
  {
    case absolute = 0
    case relative = 1
  }
  
  public var style: RKLocalAxes.Style = RKLocalAxes.Style.default
  public var position: RKLocalAxes.Position = .none
  public var scalingType: RKLocalAxes.ScalingType = .absolute
  public var offset: SIMD3<Double> = SIMD3<Double>(0,0,0)
  public var length: Double = 5.0
  public var width: Double = 0.5
  
  public init()
  {
    self.style = RKLocalAxes.Style.default
    self.position = .none
    self.scalingType = .absolute
    self.offset = SIMD3<Double>(0,0,0)
    self.length = 5.0
    self.width = 0.5
  }
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(RKLocalAxes.classVersionNumber)
    
    encoder.encode(style.rawValue)
    encoder.encode(position.rawValue)
    encoder.encode(scalingType.rawValue)
    encoder.encode(offset)
    encoder.encode(length)
    encoder.encode(width)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let versionNumber: Int = try decoder.decode(Int.self)
    if versionNumber > RKLocalAxes.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    guard let style = try RKLocalAxes.Style(rawValue: decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.style = style
    guard let position = try RKLocalAxes.Position(rawValue: decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.position = position
    guard let scalingType = try RKLocalAxes.ScalingType(rawValue: decoder.decode(Int.self)) else {throw BinaryCodableError.invalidArchiveData}
    self.scalingType = scalingType
    
    self.offset = try decoder.decode(SIMD3<Double>.self)
    self.length = try decoder.decode(Double.self)
    self.width = try decoder.decode(Double.self)
  }
}
