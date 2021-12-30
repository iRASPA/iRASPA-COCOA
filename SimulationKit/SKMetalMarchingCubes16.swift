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

public class SKMetalMarchingCubes16
{
  public var voxels: [Float] = []
  
  public var recompute: Bool = true
  
  public var opacity: Double = 0.0
  public var isoValue: Float = 0.0
  public var dimensions: SIMD3<UInt32> = SIMD3<UInt32>(0,0,0)
  
  var device: MTLDevice
  var commandQueue: MTLCommandQueue
  var defaultLibrary: MTLLibrary
  
  var constructHPLevelKernel: MTLFunction? = nil
  var classifyCubesKernel: MTLFunction? = nil
  var traverseHPKernel: MTLFunction? = nil
  var constructHPLevelPipelineState: MTLComputePipelineState? = nil
  var classifyCubesPipelineState: MTLComputePipelineState? = nil
  var traverseHPPipelineState: MTLComputePipelineState? = nil
  
  public init(device: MTLDevice, commandQueue: MTLCommandQueue, dimensions: SIMD3<Int32>)
  {
    self.device = device
    self.commandQueue = commandQueue
    self.dimensions = SIMD3<UInt32>(UInt32(dimensions.x),UInt32(dimensions.y),UInt32(dimensions.z))
    
    let bundle: Bundle = Bundle(for: SKMetalMarchingCubes32.self)
    let file: String = bundle.path(forResource: "default", ofType: "metallib")!
    defaultLibrary = try! self.device.makeLibrary(filepath: file)
    
    constructHPLevelKernel = defaultLibrary.makeFunction(name: "constructHPLevel")
    if let constructHPLevelKernel = constructHPLevelKernel
    {
      do
      {
        constructHPLevelPipelineState = try device.makeComputePipelineState(function: constructHPLevelKernel)
      }
      catch
      {
        fatalError("Error occurred when creating compute pipeline state \(error)")
      }
    }
    
    classifyCubesKernel = defaultLibrary.makeFunction(name: "classifyCubes")
    
    if let classifyCubesKernel = classifyCubesKernel
    {
      do
      {
        classifyCubesPipelineState = try device.makeComputePipelineState(function: classifyCubesKernel)
      }
      catch
      {
        fatalError("Error occurred when creating compute pipeline state \(error)")
      }
    }
    
    
    traverseHPKernel = defaultLibrary.makeFunction(name: "traverseHP16")
    if let traverseHPKernel = traverseHPKernel
    {
      do
      {
        traverseHPPipelineState = try device.makeComputePipelineState(function: traverseHPKernel)
      }
      catch
      {
        fatalError("Error occurred when creating compute pipeline state \(error)")
      }
    }
  }
  
  public func prepareHistoPyramids(_ voxels: [Float]) throws ->  MTLBuffer?
  {
    if let classifyCubesPipelineState = classifyCubesPipelineState,
      let constructHPLevelPipelineState = constructHPLevelPipelineState,
      let traverseHPPipelineState = traverseHPPipelineState
    {
      let textureDescriptorRawData = MTLTextureDescriptor()
      textureDescriptorRawData.textureType = MTLTextureType.type3D
      textureDescriptorRawData.height = 16;
      textureDescriptorRawData.width = 16;
      textureDescriptorRawData.depth = 16;
      textureDescriptorRawData.pixelFormat = MTLPixelFormat.r32Float;
      textureDescriptorRawData.mipmapLevelCount = 1
      textureDescriptorRawData.resourceOptions = .storageModeManaged
      textureDescriptorRawData.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      
      let textureDescriptorUInt8Image0 = MTLTextureDescriptor()
      textureDescriptorUInt8Image0.textureType = MTLTextureType.type3D
      textureDescriptorUInt8Image0.height = 16;
      textureDescriptorUInt8Image0.width = 16;
      textureDescriptorUInt8Image0.depth = 16;
      textureDescriptorUInt8Image0.pixelFormat = MTLPixelFormat.rgba8Uint
      textureDescriptorUInt8Image0.mipmapLevelCount = 1
      textureDescriptorUInt8Image0.resourceOptions = .storageModePrivate
      textureDescriptorUInt8Image0.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUInt8Image1 = MTLTextureDescriptor()
      textureDescriptorUInt8Image1.textureType = MTLTextureType.type3D
      textureDescriptorUInt8Image1.height = 8;
      textureDescriptorUInt8Image1.width = 8;
      textureDescriptorUInt8Image1.depth = 8;
      textureDescriptorUInt8Image1.pixelFormat = MTLPixelFormat.r8Uint;
      textureDescriptorUInt8Image1.mipmapLevelCount = 1
      textureDescriptorUInt8Image1.resourceOptions = .storageModePrivate
      textureDescriptorUInt8Image1.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUShortImage2 = MTLTextureDescriptor()
      textureDescriptorUShortImage2.textureType = MTLTextureType.type3D
      textureDescriptorUShortImage2.height = 4;
      textureDescriptorUShortImage2.width = 4;
      textureDescriptorUShortImage2.depth = 4;
      textureDescriptorUShortImage2.pixelFormat = MTLPixelFormat.r16Uint;
      textureDescriptorUShortImage2.mipmapLevelCount = 1
      textureDescriptorUShortImage2.resourceOptions = .storageModePrivate
      textureDescriptorUShortImage2.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUIntImage3 = MTLTextureDescriptor()
      textureDescriptorUIntImage3.textureType = MTLTextureType.type3D
      textureDescriptorUIntImage3.height = 2;
      textureDescriptorUIntImage3.width = 2;
      textureDescriptorUIntImage3.depth = 2;
      textureDescriptorUIntImage3.pixelFormat = MTLPixelFormat.r32Uint;
      textureDescriptorUIntImage3.mipmapLevelCount = 1
      textureDescriptorUIntImage3.resourceOptions = .storageModeManaged
      textureDescriptorUIntImage3.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
     
      
      guard let image0: MTLTexture = device.makeTexture(descriptor: textureDescriptorUInt8Image0),
            let image1: MTLTexture = device.makeTexture(descriptor: textureDescriptorUInt8Image1),
            let image2: MTLTexture = device.makeTexture(descriptor: textureDescriptorUShortImage2),
            let image3: MTLTexture = device.makeTexture(descriptor: textureDescriptorUIntImage3),
            let rawDataTexture: MTLTexture = device.makeTexture(descriptor: textureDescriptorRawData) else {
              throw SimulationKitError.couldNotCreateTexture
      }
      
      
      let region: MTLRegion = MTLRegionMake3D(0, 0, 0, 16, 16, 16)
      rawDataTexture.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: voxels, bytesPerRow: MemoryLayout<Float>.stride * region.size.width, bytesPerImage: MemoryLayout<Float>.stride * region.size.width * region.size.height)
      
      guard let isoValueBufferData: MTLBuffer = device.makeBuffer(bytes: &isoValue, length: MemoryLayout<Float>.stride, options: .storageModeManaged) else {
        throw SimulationKitError.couldNotCreateBuffer
      }
      
      guard let dimensionsBufferData: MTLBuffer = device.makeBuffer(bytes: &dimensions, length: MemoryLayout<SIMD3<UInt32>>.stride, options: .storageModeManaged) else {
       throw SimulationKitError.couldNotCreateBuffer
      }
      
      guard let commandBuffer = commandQueue.makeCommandBuffer() else {
        throw SimulationKitError.couldNotMakeCommandBuffer
      }
      
      guard let commandEncoder1 = commandBuffer.makeComputeCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandEncoder
      }
      commandEncoder1.setComputePipelineState(classifyCubesPipelineState)
      commandEncoder1.setTexture(rawDataTexture, index: 0)
      commandEncoder1.setTexture(image0, index: 1)
      commandEncoder1.setBuffer(isoValueBufferData, offset: 0, index: 0)
      commandEncoder1.setBuffer(dimensionsBufferData, offset: 0, index: 1)
      let threadsPerGrid16 = MTLSize(width: 16, height: 16, depth: 16)
      let w16: Int = classifyCubesPipelineState.threadExecutionWidth
      let h16: Int = classifyCubesPipelineState.maxTotalThreadsPerThreadgroup / w16
      let threadsPerThreadgroup16: MTLSize = MTLSizeMake(w16, h16, 1)
      commandEncoder1.dispatchThreads(threadsPerGrid16, threadsPerThreadgroup: threadsPerThreadgroup16)
      commandEncoder1.endEncoding()
            
      guard let commandEncoder2 = commandBuffer.makeComputeCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandEncoder
      }
      commandEncoder2.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder2.setTexture(image0, index: 0)
      commandEncoder2.setTexture(image1, index: 1)
      let threadsPerGrid8 = MTLSize(width: 8, height: 8, depth: 8)
      let w8: Int = constructHPLevelPipelineState.threadExecutionWidth
      let h8: Int = constructHPLevelPipelineState.maxTotalThreadsPerThreadgroup / w8
      let threadsPerThreadgroup8: MTLSize = MTLSizeMake(w8, h8, 1)
      commandEncoder2.dispatchThreadgroups(threadsPerGrid8, threadsPerThreadgroup: threadsPerThreadgroup8)
      commandEncoder2.endEncoding()
      
      guard let commandEncoder3 = commandBuffer.makeComputeCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandEncoder
      }
      commandEncoder3.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder3.setTexture(image1, index: 0)
      commandEncoder3.setTexture(image2, index: 1)
      let threadsPerGrid4 = MTLSize(width: 4, height: 4, depth: 4)
      let w4: Int = constructHPLevelPipelineState.threadExecutionWidth
      let h4: Int = constructHPLevelPipelineState.maxTotalThreadsPerThreadgroup / w4
      let threadsPerThreadgroup4: MTLSize = MTLSizeMake(w4, h4, 1)
      commandEncoder3.dispatchThreads(threadsPerGrid4, threadsPerThreadgroup: threadsPerThreadgroup4)
      commandEncoder3.endEncoding()
      
      guard let commandEncoder4 = commandBuffer.makeComputeCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandEncoder
      }
      commandEncoder4.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder4.setTexture(image2, index: 0)
      commandEncoder4.setTexture(image3, index: 1)
      let threadsPerGrid2 = MTLSize(width: 2, height: 2, depth: 2)
      let w2: Int = constructHPLevelPipelineState.threadExecutionWidth
      let h2: Int = constructHPLevelPipelineState.maxTotalThreadsPerThreadgroup / w2
      let threadsPerThreadgroup2: MTLSize = MTLSizeMake(w2, h2, 1)
      commandEncoder4.dispatchThreads(threadsPerGrid2, threadsPerThreadgroup: threadsPerThreadgroup2)
      commandEncoder4.endEncoding()
      
      guard let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandEncoder
      }
      blitEncoder.synchronize(texture: image3, slice: 0, level: 0)
      blitEncoder.endEncoding()
      
      commandBuffer.commit()
      
      commandBuffer.waitUntilCompleted()
      
      if let error = commandBuffer.error
      {
        throw NSError(domain: SimulationKitError.domain, code: SimulationKitError.code.genericMetalError.rawValue, userInfo: [NSLocalizedDescriptionKey : error.localizedDescription])
      }
      
      var imageBytes2x2 = [UInt32](repeating: 0, count: 2*2*2)
      let region3d2x2 = MTLRegionMake3D(0, 0, 0, 2, 2, 2)
      image3.getBytes(&imageBytes2x2, bytesPerRow: 2 * MemoryLayout<UInt32>.stride, bytesPerImage: MemoryLayout<UInt32>.stride * 2 * 2, from: region3d2x2, mipmapLevel: 0, slice: 0)
      
      var numberOfTriangles: UInt32 = 0
      for i in 0..<8
      {
        numberOfTriangles += imageBytes2x2[i]
      }
            
      if Int(numberOfTriangles) > 0
      {
        // 3 points consisting of a position, a normal, and texture coordinates
        let isosurfaceVertexBuffer: MTLBuffer? = device.makeBuffer(length: Int(numberOfTriangles) * 3 * 3 * MemoryLayout<SIMD4<Float>>.stride, options: .storageModeShared)
        
        if isosurfaceVertexBuffer == nil
        {
          throw SimulationKitError.couldNotCreateBuffer
        }
        
        if numberOfTriangles>0
        {
          guard let commandBuffer2 = commandQueue.makeCommandBuffer() else {
            throw SimulationKitError.couldNotMakeCommandBuffer
          }
          
          guard let commandEncoder2 = commandBuffer2.makeComputeCommandEncoder() else {
            throw SimulationKitError.couldNotMakeCommandEncoder
          }
                    
          var dataSize: UInt32 = UInt32(numberOfTriangles)
          guard let sumBufferData: MTLBuffer = device.makeBuffer(bytes: &dataSize, length: MemoryLayout<UInt32>.stride, options: .storageModeManaged) else {
              throw SimulationKitError.couldNotCreateBuffer
          }
          
          commandEncoder2.setComputePipelineState(traverseHPPipelineState)
          commandEncoder2.setTexture(image0, index: 0)
          commandEncoder2.setTexture(image1, index: 1)
          commandEncoder2.setTexture(image2, index: 2)
          commandEncoder2.setTexture(image3, index: 3)
          commandEncoder2.setTexture(rawDataTexture, index: 4)
          commandEncoder2.setBuffer(isosurfaceVertexBuffer!, offset: 0, index: 0)
          commandEncoder2.setBuffer(isoValueBufferData, offset: 0, index: 1)
          commandEncoder2.setBuffer(sumBufferData, offset: 0, index: 2)
          commandEncoder2.setBuffer(dimensionsBufferData, offset: 0, index: 3)
          
          let threadsPerGrid = MTLSize(width: Int(numberOfTriangles), height: 1, depth: 1)
          let threadExecutionWidth: Int = traverseHPPipelineState.threadExecutionWidth
          let threadsPerThreadgroup: MTLSize = MTLSizeMake(threadExecutionWidth, 1, 1)
          commandEncoder2.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
          
          commandEncoder2.endEncoding()
          
          commandBuffer2.commit()
          
          commandBuffer2.waitUntilCompleted()
          
          if let error = commandBuffer2.error
          {
            throw NSError(domain: SimulationKitError.domain, code: SimulationKitError.code.genericMetalError.rawValue, userInfo: [NSLocalizedDescriptionKey : error.localizedDescription])
          }
          return isosurfaceVertexBuffer
        }
      }
    }
    return nil
  }
}



