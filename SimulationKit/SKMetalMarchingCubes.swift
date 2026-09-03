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

    LogQueue.shared.warning(destination: nil, message: "GPU marching cubes produced 0 triangles; building the isosurface on the CPU")
    return constructCPUIsoSurfaceVertexBuffer(device: device, data: data, isovalue: iso, dimensions: dimensions)
  }

  private static func constructCPUIsoSurfaceVertexBuffer(device: MTLDevice, data: [Float], isovalue: Float, dimensions: SIMD3<Int32>) -> MTLBuffer?
  {
    let nx = Int(max(dimensions.x, 1))
    let ny = Int(max(dimensions.y, 1))
    let nz = Int(max(dimensions.z, 1))
    let count = nx * ny * nz
    guard data.count >= count else { return nil }

    func sample(_ x: Int, _ y: Int, _ z: Int) -> Float
    {
      let ix = ((x % nx) + nx) % nx
      let iy = ((y % ny) + ny) % ny
      let iz = ((z % nz) + nz) % nz
      return data[ix + nx * (iy + ny * iz)]
    }

    func gradient(_ x: Int, _ y: Int, _ z: Int) -> SIMD3<Float>
    {
      return SIMD3<Float>(
        sample(x - 1, y, z) - sample(x + 1, y, z),
        sample(x, y - 1, z) - sample(x, y + 1, z),
        sample(x, y, z - 1) - sample(x, y, z + 1)
      )
    }

    let cornerOffset: [(Int, Int, Int)] = [
      (0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1),
      (0, 1, 0), (1, 1, 0), (1, 1, 1), (0, 1, 1)
    ]
    let edgeEnds: [(Int, Int)] = [
      (0, 1), (1, 2), (2, 3), (3, 0),
      (4, 5), (5, 6), (6, 7), (7, 4),
      (0, 4), (1, 5), (2, 6), (3, 7)
    ]

    var vertices: [SIMD4<Float>] = []
    vertices.reserveCapacity(65536)

    for z in 0..<nz
    {
      for y in 0..<ny
      {
        for x in 0..<nx
        {
          var cubeindex = 0
          var values = [Float](repeating: 0, count: 8)
          for c in 0..<8
          {
            let o = cornerOffset[c]
            values[c] = sample(x + o.0, y + o.1, z + o.2)
            if values[c] > isovalue { cubeindex |= (1 << c) }
          }
          let ntri = Int(SKMarchingCubesTables.triangleCount[cubeindex])
          if ntri == 0 { continue }

          for t in 0..<ntri
          {
            for v in 0..<3
            {
              let edge = Int(SKMarchingCubesTables.triTable[cubeindex * 16 + t * 3 + v])
              guard edge >= 0 else { continue }
              let e0 = edgeEnds[edge].0
              let e1 = edgeEnds[edge].1
              let p0 = cornerOffset[e0]
              let p1 = cornerOffset[e1]
              let v0 = values[e0]
              let denom = (values[e1] - v0)
              let u = denom == 0 ? 0.5 : (isovalue - v0) / denom
              let px = Float(x + p0.0) + Float(p1.0 - p0.0) * u
              let py = Float(y + p0.1) + Float(p1.1 - p0.1) * u
              let pz = Float(z + p0.2) + Float(p1.2 - p0.2) * u
              let n0 = gradient(x + p0.0, y + p0.1, z + p0.2)
              let n1 = gradient(x + p1.0, y + p1.1, z + p1.2)
              var n = n0 + (n1 - n0) * u
              let nlen = length(n)
              if nlen > 1e-8 { n = n / nlen }
              vertices.append(SIMD4<Float>(px / Float(nx), py / Float(ny), pz / Float(nz), 1))
              vertices.append(SIMD4<Float>(n.x, n.y, n.z, 0))
              vertices.append(SIMD4<Float>(0, 0, 0, 0))
            }
          }
        }
      }
    }

    guard !vertices.isEmpty else { return nil }
    return vertices.withUnsafeBytes { raw in
      device.makeBuffer(bytes: raw.baseAddress!, length: raw.count, options: .storageModeShared)
    }
  }
}
