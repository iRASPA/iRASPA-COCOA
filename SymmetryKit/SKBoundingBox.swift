/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import simd

public struct SKBoundingBox: BinaryDecodable, BinaryEncodable
{
  public var minimum: SIMD3<Double> = SIMD3<Double>(x: 0.0, y: 0.0, z:0.0)
  public var maximum: SIMD3<Double> = SIMD3<Double>(x: 0.0, y: 0.0, z:0.0)
  
  static var classVersionNumber: Int = 1
  
  public init()
  {
    
  }
  
  public init(minimum: SIMD3<Double>, maximum: SIMD3<Double>)
  {
    self.minimum = minimum
    self.maximum = maximum
  }
  
  public init(center: SIMD3<Double>, width: SIMD3<Double>)
  {
    self.minimum = center - 0.5 * width
    self.maximum = center + 0.5 * width
  }
  
  public var corners: [SIMD3<Double>]
  {
    return [SIMD3<Double>(x: Double(minimum.x), y: Double(minimum.y), z: Double(minimum.z)),
            SIMD3<Double>(x: Double(maximum.x), y: Double(minimum.y), z: Double(minimum.z)),
            SIMD3<Double>(x: Double(maximum.x), y: Double(maximum.y), z: Double(minimum.z)),
            SIMD3<Double>(x: Double(minimum.x), y: Double(maximum.y), z: Double(minimum.z)),
            SIMD3<Double>(x: Double(minimum.x), y: Double(minimum.y), z: Double(maximum.z)),
            SIMD3<Double>(x: Double(maximum.x), y: Double(minimum.y), z: Double(maximum.z)),
            SIMD3<Double>(x: Double(maximum.x), y: Double(maximum.y), z: Double(maximum.z)),
            SIMD3<Double>(x: Double(minimum.x), y: Double(maximum.y), z: Double(maximum.z))]
  }
  
  public var sides: [(SIMD3<Double>,SIMD3<Double>)]
  {
    let cornerPoints: [SIMD3<Double>] = self.corners
    return [
      // bottom ring
      (cornerPoints[0], cornerPoints[1]),
      (cornerPoints[1], cornerPoints[2]),
      (cornerPoints[2], cornerPoints[3]),
      (cornerPoints[3], cornerPoints[0]),
      
      // top ring
      (cornerPoints[4], cornerPoints[5]),
      (cornerPoints[5], cornerPoints[6]),
      (cornerPoints[6], cornerPoints[7]),
      (cornerPoints[7], cornerPoints[4]),
      
      // sides
      (cornerPoints[0], cornerPoints[4]),
      (cornerPoints[1], cornerPoints[5]),
      (cornerPoints[2], cornerPoints[6]),
      (cornerPoints[3], cornerPoints[7])
    ]
  }
  
  public var center: SIMD3<Double>
  {
    return minimum + (maximum - minimum) * 0.5
  }
  
  public var shortestEdge: Double
  {
    let edgeLengths: SIMD3<Double> = maximum - minimum
    return min(edgeLengths.x, edgeLengths.y, edgeLengths.z)
  }
  
  public var boundingSphereRadius: Double
  {
    let coords: [SIMD3<Double>] =
      [
        SIMD3<Double>(x: minimum.x, y: minimum.z, z: minimum.z),
        SIMD3<Double>(x: maximum.x, y: minimum.z, z: minimum.z),
        SIMD3<Double>(x: minimum.x, y: maximum.z, z: minimum.z),
        SIMD3<Double>(x: maximum.x, y: maximum.z, z: minimum.z),
        SIMD3<Double>(x: minimum.x, y: minimum.z, z: maximum.z),
        SIMD3<Double>(x: maximum.x, y: minimum.z, z: maximum.z),
        SIMD3<Double>(x: minimum.x, y: maximum.z, z: maximum.z),
        SIMD3<Double>(x: maximum.x, y: maximum.z, z: maximum.z),
        ]
    
    let centerOfScene: SIMD3<Double> = minimum + (maximum - minimum) * 0.5
    
    var radius: Double = 0.0
    for coord in coords
    {
      let cornerRadius: Double = length(centerOfScene-coord)
      if (cornerRadius > radius)
      {
        radius = cornerRadius
      }
    }
    return radius
  }
  
  public func adjustForTransformation(_ transformation: double4x4) -> SKBoundingBox
  {
    let centerOfScene: SIMD3<Double> = self.minimum + (self.maximum - self.minimum) * 0.5
    var min: SIMD3<Double> = SIMD3<Double>()
    var max: SIMD3<Double> = SIMD3<Double>()
    
    if (transformation[0][0] > 0.0)
    {
      min.x += transformation[0][0] * (self.minimum.x - centerOfScene.x);
      max.x += transformation[0][0] * (self.maximum.x - centerOfScene.x);
    }
    else
    {
      min.x += transformation[0][0] * (self.maximum.x - centerOfScene.x);
      max.x += transformation[0][0] * (self.minimum.x - centerOfScene.x);
    }
    
    if (transformation[0][1] > 0.0)
    {
      min.y += transformation[0][1] * (self.minimum.x - centerOfScene.x);
      max.y += transformation[0][1] * (self.maximum.x - centerOfScene.x);
    }
    else
    {
      min.y += transformation[0][1] * (self.maximum.x - centerOfScene.x);
      max.y += transformation[0][1] * (self.minimum.x - centerOfScene.x);
    }
    
    if (transformation[0][2] > 0.0)
    {
      min.z += transformation[0][2] * (self.minimum.x - centerOfScene.x);
      max.z += transformation[0][2] * (self.maximum.x - centerOfScene.x);
    }
    else
    {
      min.z += transformation[0][2] * (self.maximum.x - centerOfScene.x);
      max.z += transformation[0][2] * (self.minimum.x - centerOfScene.x);
    }
    
    if (transformation[1][0] > 0.0)
    {
      min.x += transformation[1][0] * (self.minimum.y - centerOfScene.y);
      max.x += transformation[1][0] * (self.maximum.y - centerOfScene.y);
    }
    else {
      min.x += transformation[1][0] * (self.maximum.y - centerOfScene.y);
      max.x += transformation[1][0] * (self.minimum.y - centerOfScene.y);
    }
    
    if (transformation[1][1] > 0.0)
    {
      min.y += transformation[1][1] * (self.minimum.y - centerOfScene.y);
      max.y += transformation[1][1] * (self.maximum.y - centerOfScene.y);
    }
    else
    {
      min.y += transformation[1][1] * (self.maximum.y - centerOfScene.y);
      max.y += transformation[1][1] * (self.minimum.y - centerOfScene.y);
    }
    
    if (transformation[1][2] > 0.0)
    {
      min.z += transformation[1][2] * (self.minimum.y - centerOfScene.y);
      max.z += transformation[1][2] * (self.maximum.y - centerOfScene.y);
    }
    else
    {
      min.z += transformation[1][2] * (self.maximum.y - centerOfScene.y);
      max.z += transformation[1][2] * (self.minimum.y - centerOfScene.y);
    }
    
    if (transformation[2][0] > 0.0)
    {
      min.x += transformation[2][0] * (self.minimum.z - centerOfScene.z);
      max.x += transformation[2][0] * (self.maximum.z - centerOfScene.z);
    }
    else
    {
      min.x += transformation[2][0] * (self.maximum.z - centerOfScene.z);
      max.x += transformation[2][0] * (self.minimum.z - centerOfScene.z);
    }
    
    if (transformation[2][1] > 0.0)
    {
      min.y += transformation[2][1] * (self.minimum.z - centerOfScene.z);
      max.y += transformation[2][1] * (self.maximum.z - centerOfScene.z);
    }
    else
    {
      min.y += transformation[2][1] * (self.maximum.z - centerOfScene.z);
      max.y += transformation[2][1] * (self.minimum.z - centerOfScene.z);
    }
    
    if (transformation[2][2] > 0.0)
    {
      min.z += transformation[2][2] * (self.minimum.z - centerOfScene.z);
      max.z += transformation[2][2] * (self.maximum.z - centerOfScene.z);
    }
    else
    {
      min.z += transformation[2][2] * (self.maximum.z - centerOfScene.z);
      max.z += transformation[2][2] * (self.minimum.z - centerOfScene.z);
    }
    
    return SKBoundingBox(minimum: min + centerOfScene, maximum: max + centerOfScene)
  }
  
  
  public var widths: SIMD3<Double>
  {
    return SIMD3<Double>(x: maximum.x-minimum.x, y: maximum.y-minimum.y, z: maximum.z-minimum.z)
  }
  
  public static func +(left: SKBoundingBox, right: SIMD3<Double>) -> SKBoundingBox
  {
     return SKBoundingBox(minimum: left.minimum + right, maximum: left.maximum + right)
  }
  
  public static func -(left: SKBoundingBox, right: SIMD3<Double>) -> SKBoundingBox
  {
    return SKBoundingBox(minimum: left.minimum - right, maximum: left.maximum - right)
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(SKBoundingBox.classVersionNumber)
    encoder.encode(self.minimum)
    encoder.encode(self.maximum)
  }
  
  // MARK: -
  // MARK: Binary Decodable support
  
  public init(fromBinary decoder: BinaryDecoder) throws
  {
    let versionNumber: Int = try decoder.decode(Int.self)
    if versionNumber > SKBoundingBox.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.minimum = try decoder.decode(SIMD3<Double>.self)
    self.maximum = try decoder.decode(SIMD3<Double>.self)
  }
}

