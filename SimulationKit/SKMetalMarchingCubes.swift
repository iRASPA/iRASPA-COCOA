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
  
  public static func constructIsoSurfaceVertexBuffer(device: MTLDevice?, commandQueue: MTLCommandQueue?, data: [Float], isovalue: Double, dimensions: SIMD3<Int32>, gridSizeType: GridSizeType?) throws -> MTLBuffer?
  {
    guard let device: MTLDevice = device ?? MTLCreateSystemDefaultDevice(),
          let commandQueue: MTLCommandQueue = commandQueue ?? device.makeCommandQueue(),
          let gridSizeType: GridSizeType = gridSizeType
          else {
            return nil
          }
    
    switch(gridSizeType)
    {
    case .size16x16x16:
      let marchingCubes = SKMetalMarchingCubes16(device: device, commandQueue: commandQueue, dimensions: dimensions)
      
      marchingCubes.isoValue = Float(isovalue)
      
      return try marchingCubes.prepareHistoPyramids(data)
    case .size32x32x32:
      let marchingCubes = SKMetalMarchingCubes32(device: device, commandQueue: commandQueue, dimensions: dimensions)
      
      marchingCubes.isoValue = Float(isovalue)
      
      return try marchingCubes.prepareHistoPyramids(data)
    case .size64x64x64:
      let marchingCubes = SKMetalMarchingCubes64(device: device, commandQueue: commandQueue, dimensions: dimensions)
      
      marchingCubes.isoValue = Float(isovalue)
      
      return try marchingCubes.prepareHistoPyramids(data)
    case .size128x128x128:
      let marchingCubes = SKMetalMarchingCubes128(device: device, commandQueue: commandQueue, dimensions: dimensions)
      
      marchingCubes.isoValue = Float(isovalue)
      
      return try marchingCubes.prepareHistoPyramids(data)
    case .size256x256x256:
      let marchingCubes = SKMetalMarchingCubes256(device: device, commandQueue: commandQueue, dimensions: dimensions)
      
      marchingCubes.isoValue = Float(isovalue)
      
      return try marchingCubes.prepareHistoPyramids(data)
    case .size512x512x512:
      let marchingCubes = SKMetalMarchingCubes512(device: device, commandQueue: commandQueue, dimensions: dimensions)
      
      marchingCubes.isoValue = Float(isovalue)
      
      return try marchingCubes.prepareHistoPyramids(data)
    default:
      return nil
    }
  }
}
