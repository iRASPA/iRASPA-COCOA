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

/// GPU instance of one geometric-surface patch. Layout matches `GeometricSurfacePatchInstance` in Common.h.
public struct RKGeometricSurfacePatchInstance
{
  public var position: SIMD4<Float> = SIMD4<Float>()
  public var scale: SIMD4<Float> = SIMD4<Float>()
  public var cellOrigin: SIMD4<Float> = SIMD4<Float>()
  public var firstClip: UInt32 = 0
  public var clipCount: UInt32 = 0
  public var clipToCell: UInt32 = 0
  public var pad1: UInt32 = 0
  
  public init(position: SIMD3<Float>, radius: Float, cellOrigin: SIMD3<Float>, firstClip: UInt32, clipCount: UInt32, clipToCell: Bool)
  {
    self.position = SIMD4<Float>(position.x, position.y, position.z, 1.0)
    self.scale = SIMD4<Float>(repeating: radius)
    self.cellOrigin = SIMD4<Float>(cellOrigin.x, cellOrigin.y, cellOrigin.z, 0.0)
    self.firstClip = firstClip
    self.clipCount = clipCount
    self.clipToCell = clipToCell ? 1 : 0
  }
}

/// GPU clip sphere. Layout matches `GeometricSurfaceClip` in Common.h.
public struct RKGeometricSurfaceClip
{
  public var sphere: SIMD4<Float> = SIMD4<Float>()
  
  public init(center: SIMD3<Float>, radius: Float)
  {
    self.sphere = SIMD4<Float>(center.x, center.y, center.z, radius)
  }
}
