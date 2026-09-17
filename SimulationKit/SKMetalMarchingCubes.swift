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
import Metal
import simd
import LogViewKit

public class SKMetalMarchingCubes
{
  public enum GridSizeType: Int
  {
    case custom = 0
    case size2x2x2 = 1
    case size4x4x4 = 2
    case size8x8x8 = 3
    case size16x16x16 = 4
    case size32x32x32 = 5
    case size64x64x64 = 6
    case size128x128x128 = 7
    case size256x256x256 = 8
    case size512x512x512 = 9
  }
  
  public init()
  {
  }
  
  public static func constructIsoSurfaceVertexBuffer(device: MTLDevice?, commandQueue: MTLCommandQueue?, data: [Float], isovalue: Double, dimensions: SIMD3<Int32>, substituteIsovalueIfNeeded: Bool = true) throws -> MTLBuffer?
  {
    guard let device: MTLDevice = device ?? MTLCreateSystemDefaultDevice(),
          let commandQueue: MTLCommandQueue = commandQueue ?? device.makeCommandQueue()
          else {
            return nil
          }

    guard let minV = data.min(), let maxV = data.max(), !data.isEmpty else {
      LogQueue.shared.error(destination: nil, message: "Marching cubes: energy grid is empty")
      return nil
    }

    var iso = Float(isovalue)
    if !(minV < iso && maxV > iso)
    {
      // A substitute a quarter of the way up the range is a last resort for the energy isosurface so
      // something is visible. It is the wrong thing for a well-surface field: the range runs from a
      // fraction of an angstrom to the overlap clamp (10,000 in mixed units), and the substitute lands
      // deep inside the repulsive core, closer to the atoms than the 0 K isosurface.
      if !substituteIsovalueIfNeeded
      {
        LogQueue.shared.warning(destination: nil, message: String(format: "Iso %.1f does not cross the grid (min %.4f, max %.1f).", isovalue, minV, maxV))
        return nil
      }
      iso = minV + 0.25 * (maxV - minV)
      LogQueue.shared.warning(destination: nil, message: String(format: "Iso %.1f K does not cross the energy grid (min %.1f, max %.1f K). Using %.1f K so a surface is visible.", isovalue, minV, maxV, iso))
    }
    else
    {
      LogQueue.shared.info(destination: nil, message: String(format: "Energy grid min %.1f max %.1f K, iso %.1f K", minV, maxV, iso))
    }

    let marchingCubes = SKMetalMarchingCubes128(device: device, commandQueue: commandQueue, dimensions: dimensions)
    marchingCubes.isoValue = iso
    if let gpu = try marchingCubes.prepareHistoPyramids(data), gpu.length > 0
    {
      return gpu
    }

    LogQueue.shared.warning(destination: nil, message: "GPU Lewiner marching cubes produced 0 triangles")
    return nil
  }
}
