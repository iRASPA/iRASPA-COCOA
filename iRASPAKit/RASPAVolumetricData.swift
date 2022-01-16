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

import Cocoa
import RenderKit
import SymmetryKit
import BinaryCodable
import simd

import Foundation

public class RASPAVolumetricData: VolumetricData, RKRenderVolumetricDataSource, UnitCellEditor, Cloning
{
  private static var classVersionNumber: Int = 1
  
  public override var materialType: Object.ObjectType
  {
    return .RASPAVolumetricData
  }
  
  public required init(copy RASPADensityVolume: RASPAVolumetricData)
  {
    super.init(copy: RASPADensityVolume)
  }
  
  public required init(clone RASPADensityVolume: RASPAVolumetricData)
  {
    super.init(clone: RASPADensityVolume)
  }
  
  public required init(from object: Object)
  {
    super.init(from: object)
  }
    
  public init(name: String, dimensions: SIMD3<Int32>, spacing: SIMD3<Double>, cell: SKCell, data: Data, dataType: SKStructure.DataType)
  {
    super.init()
    self.drawUnitCell = true
    self.displayName = name
    self.dimensions = dimensions
    self.spacing = spacing
    self.cell = cell
    
    let size: Int = Int(dimensions.x * dimensions.y * dimensions.z)
    var densityData: [Float] = Array<Float>(repeating: Float(0.0), count: Int(size))
    
    var arr2: [Float] = []
    
    switch(dataType)
    {
    case .Uint8:
      var convertedData: [UInt8] = Array<UInt8>(repeating: 0, count: data.count/MemoryLayout<UInt8>.stride)
      _ = convertedData.withUnsafeMutableBytes { data.copyBytes(to: $0) }
      arr2 = convertedData.map{Float($0)/Float(UInt8.max)}
    case .Int8:
      var convertedData: [Int8] = Array<Int8>(repeating: 0, count: data.count/MemoryLayout<Int8>.stride)
      _ = convertedData.withUnsafeMutableBytes { data.copyBytes(to: $0) }
      arr2 = convertedData.map{Float($0 + Int8.min)/Float(UInt8.max)}
    case .Uint16:
      var convertedData: [UInt16] = Array<UInt16>(repeating: 0, count: data.count/MemoryLayout<UInt16>.stride)
      _ = convertedData.withUnsafeMutableBytes { data.copyBytes(to: $0) }
      arr2 = convertedData.map{Float($0)/Float(UInt16.max)}
    case .Int16:
      var convertedData: [Int16] = Array<Int16>(repeating: 0, count: data.count/MemoryLayout<Int16>.stride)
      _ = convertedData.withUnsafeMutableBytes { data.copyBytes(to: $0) }
      arr2 = convertedData.map{Float($0 + Int16.min)/Float(UInt16.max)}
    case .Uint32:
      var convertedData: [UInt32] = Array<UInt32>(repeating: 0, count: data.count/MemoryLayout<UInt32>.stride)
      _ = convertedData.withUnsafeMutableBytes { data.copyBytes(to: $0) }
      arr2 = convertedData.map{Float($0)/Float(UInt32.max)}
    case .Int32:
      var convertedData: [Int32] = Array<Int32>(repeating: 0, count: data.count/MemoryLayout<Int32>.stride)
      _ = convertedData.withUnsafeMutableBytes { data.copyBytes(to: $0) }
      arr2 = convertedData.map{Float($0 + Int32.min)/Float(UInt32.max)}
    case .Uint64:
      var convertedData: [UInt64] = Array<UInt64>(repeating: 0, count: data.count/MemoryLayout<UInt64>.stride)
      _ = convertedData.withUnsafeMutableBytes { data.copyBytes(to: $0) }
      arr2 = convertedData.map{Float($0)/Float(UInt64.max)}
    case .Int64:
      var convertedData: [Int64] = Array<Int64>(repeating: 0, count: data.count/MemoryLayout<Int64>.stride)
      _ = convertedData.withUnsafeMutableBytes { data.copyBytes(to: $0) }
      arr2 = convertedData.map{Float($0 + Int64.min)/Float(UInt64.max)}
    case .Float:
      var convertedData: [Float] = Array<Float>(repeating: 0, count: data.count/MemoryLayout<Float>.stride)
      _ = convertedData.withUnsafeMutableBytes { data.copyBytes(to: $0) }
      arr2 = convertedData.map{Float($0)}
    case .Double:
      var convertedData: [Double] = Array<Double>(repeating: 0, count: data.count/MemoryLayout<Double>.stride)
      _ = convertedData.withUnsafeMutableBytes { data.copyBytes(to: $0) }
      arr2 = convertedData.map{Float($0)}
    }
    
    var maximum: Float = -Float.greatestFiniteMagnitude
    var minimum: Float = Float.greatestFiniteMagnitude
    var sum: Float = 0.0
    var sumSquared: Float = 0.0
    for x in 0..<Int(dimensions.z)
    {
      for y in 0..<Int(dimensions.y)
      {
        for z in 0..<Int(dimensions.x)
        {
          let value: Float = arr2[x+Int(dimensions.x)*y+z*Int(dimensions.x)*Int(dimensions.y)];
          
          sum += value
          sumSquared += value * value
          
          if(value > maximum)
          {
            maximum = value
          }
          if(value < minimum)
          {
            minimum = value
          }
          
          densityData[x+Int(dimensions.x)*y+z*Int(dimensions.x)*Int(dimensions.y)] = value
        }
      }
    }
    self.range = (Double(minimum), Double(maximum))
    self.average = Double(sum) / Double(dimensions.x * dimensions.y * dimensions.z)
    self.data = densityData.withUnsafeBufferPointer {Data(buffer: $0)}
    
    let largestSize: Int = Int(max(dimensions.x,dimensions.y,dimensions.z))
    var k: Int = 1
    while(largestSize > Int(pow(2.0,Double(k))))
    {
      k += 1
    }
    self.encompassingPowerOfTwoCubicGridSize = k
    self.adsorptionVolumeStepLength = 0.5 / pow(2.0,Double(k))
    self.adsorptionSurfaceIsoValue = average
    self.adsorptionSurfaceRenderingMethod = .volumeRendering
    self.adsorptionVolumeTransferFunction = .CoolWarmDiverging
    self.drawAdsorptionSurface = true
  }
    
  public var isImmutable: Bool
  {
    return true
  }
  
  public var gridData: [Float]
  {
    var copiedData = [Float](repeating: Float(0.0), count: data.count / MemoryLayout<Float>.stride)
    let _ = copiedData.withUnsafeMutableBytes { data.copyBytes(to: $0, from: 0..<data.count) }
    
    let encompassingCubicGridSize: Int32 = Int32(pow(2.0, Double(self.encompassingPowerOfTwoCubicGridSize)))
    let numberOfValues: Int32 = encompassingCubicGridSize * encompassingCubicGridSize * encompassingCubicGridSize
    var newdata = Array<Float>(repeating: 0.0, count: Int(numberOfValues))
    
    for x: Int32 in 0..<dimensions.x
    {
      for y: Int32 in 0..<dimensions.y
      {
        for z: Int32 in 0..<dimensions.z
        {
          let index: Int = Int(x+encompassingCubicGridSize*y+z*encompassingCubicGridSize*encompassingCubicGridSize)
          newdata[index] = copiedData[Int(x + dimensions.x*y + z*dimensions.x*dimensions.y)]
        }
      }
    }

    return newdata
  }
  
  public var gridValueAndGradientData: [SIMD4<Float>]
  {
    var copiedData = [Float](repeating: Float(0.0), count: data.count / MemoryLayout<Float>.stride)
    let _ = copiedData.withUnsafeMutableBytes { data.copyBytes(to: $0, from: 0..<data.count) }
    
    for i in 0..<data.count / MemoryLayout<Float>.stride
    {
      let value = copiedData[i]
      copiedData[i] = Float((Double(value) - range.0) / (range.1 - range.0))
    }
    
    let encompassingCubicGridSize: Int32 = Int32(pow(2.0, Double(self.encompassingPowerOfTwoCubicGridSize)))
    let numberOfValues: Int32 = encompassingCubicGridSize * encompassingCubicGridSize * encompassingCubicGridSize
    var newdata = Array<SIMD4<Float>>(repeating: SIMD4<Float>(0.0,0.0,0.0,0.0), count: Int(numberOfValues))
    
    for x: Int32 in 0..<dimensions.x
    {
      for y: Int32 in 0..<dimensions.y
      {
        for z: Int32 in 0..<dimensions.z
        {
          let index: Int = Int(x+encompassingCubicGridSize*y+z*encompassingCubicGridSize*encompassingCubicGridSize)
          let value = copiedData[Int(x + dimensions.x*y + z*dimensions.x*dimensions.y)]
          
          let xi: Int32 = Int32(Float(x) + 0.5)
          let xf: Float = Float(x) + 0.5 - Float(xi)
          let xd0: Float = copiedData[Int(((xi-1 + dimensions.x) % dimensions.x)+y*dimensions.x+z*dimensions.x*dimensions.y)]
          let xd1: Float = copiedData[Int((xi)+y*dimensions.x+z*dimensions.x*dimensions.y)]
          let xd2: Float = copiedData[Int(((xi+1 + dimensions.x) % dimensions.x)+y*dimensions.x+z*dimensions.x*dimensions.y)]
          let gx: Float = (xd1 - xd0) * (1.0 - xf) + (xd2 - xd1) * xf

          let yi: Int32 = Int32(Float(y) + 0.5)
          let yf: Float = Float(y) + 0.5 - Float(yi)
          let yd0: Float = copiedData[Int(x + ((yi-1+dimensions.y) % dimensions.y)*dimensions.x+z*dimensions.x*dimensions.y)]
          let yd1: Float = copiedData[Int(x + (yi)*dimensions.x+z*dimensions.x*dimensions.y)]
          let yd2: Float = copiedData[Int(x + ((yi+1+dimensions.y) % dimensions.y)*dimensions.x+z*dimensions.x*dimensions.y)]
          let gy: Float = (yd1 - yd0) * (1.0 - yf) + (yd2 - yd1) * yf

          let zi: Int32 = Int32(Float(z) + 0.5)
          let zf: Float = Float(z) + 0.5 - Float(zi)
          let zd0: Float =  copiedData[Int(x+y*dimensions.x+((zi-1+dimensions.z) % dimensions.z)*dimensions.x*dimensions.y)]
          let zd1: Float =  copiedData[Int(x+y*dimensions.x+(zi)*dimensions.x*dimensions.y)]
          let zd2: Float =  copiedData[Int(x+y*dimensions.x+((zi+1+dimensions.z) % dimensions.z)*dimensions.x*dimensions.y)]
          let gz: Float =  (zd1 - zd0) * (1.0 - zf) + (zd2 - zd1) * zf
          
          newdata[index] = SIMD4<Float>(value,gx,gy,gz)
        }
      }
    }
    return newdata
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public override func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(RASPAVolumetricData.classVersionNumber)
    
   
    encoder.encode(Int(0x6f6b6196))
    
    super.binaryEncode(to: encoder)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > RASPAVolumetricData.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    let magicNumber = try decoder.decode(Int.self)
    if magicNumber != Int(0x6f6b6196)
    {
      throw BinaryDecodableError.invalidMagicNumber
    }
    
    try super.init(fromBinary: decoder)
  }
}
