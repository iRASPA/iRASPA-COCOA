/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 J.Vreede@uva.nl      https://www.uva.nl/en/profile/v/r/j.vreede/j.vreede.html
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
import simd


public struct RKInPerInstanceAttributesBonds
{
  public var position1:  SIMD4<Float> =  SIMD4<Float>()
  public var position2:  SIMD4<Float> =  SIMD4<Float>()
  public var color1:  SIMD4<Float> =  SIMD4<Float>()
  public var color2:  SIMD4<Float> =  SIMD4<Float>()
  public var scale:  SIMD4<Float> =  SIMD4<Float>()
  public var tag: UInt32 = UInt32()
  public var type: UInt32 = UInt32()
  /// First of the ambient-occlusion atlas patches belonging to this bond, one per sub-cylinder. Stamped
  /// when the instance buffers are built rather than carried by the data model, because it numbers the
  /// bonds as they are drawn. It fits in the padding the four-component members already imposed, so the
  /// buffer stride is unchanged.
  public var ambientOcclusionPatch: UInt32 = UInt32()
  
  public init()
  {
    
  }
  
  /// How many atlas patches a bond of this order owns, which is how many cylinders it is drawn as. The
  /// orders are numbered as `bondImposterSubCylinderOffset` in BondCylinderShader.metal reads them, that
  /// being what decides where the sub-cylinders end up.
  public static func ambientOcclusionPatchCount(type: UInt32) -> Int
  {
    switch type
    {
    case 1: return 2   // double
    case 3: return 3   // triple
    default: return 1
    }
  }
  
  public init(position1:  SIMD4<Float>, position2:  SIMD4<Float>, color1:  SIMD4<Float>, color2:  SIMD4<Float>, scale:  SIMD4<Float>, tag: UInt32, type: UInt32)
  {
    self.position1 = position1
    self.position2 = position2
    self.color1 = color1
    self.color2 = color2
    self.scale = scale
    self.tag = tag
    self.type = type
  }
}
