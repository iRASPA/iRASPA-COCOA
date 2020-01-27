/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl            http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 scaldia@upo.es                http://www.upo.es/raspa/sofiacalero.php
 t.j.h.vlugt@tudelft.nl        http://homepage.tudelft.nl/v9k6y
 
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

public class SKMetalMarchingCubes256
{
  // data are floats
  public var voxels: [Float] = []
  
  public var recompute: Bool = true
  
  public var opacity: Double = 0.0
  public var isoValue: Float = 0.0
  
  
  var device: MTLDevice
  var commandQueue: MTLCommandQueue
  var defaultLibrary: MTLLibrary
  
  // kernels for Image3D extension
  var constructHPLevelKernel: MTLFunction? = nil
  var classifyCubesKernel: MTLFunction? = nil
  var traverseHPKernel: MTLFunction? = nil
  var constructHPLevelPipelineState: MTLComputePipelineState? = nil
  var classifyCubesPipelineState: MTLComputePipelineState? = nil
  var traverseHPPipelineState: MTLComputePipelineState? = nil
  
  var image0: MTLTexture? = nil
  var image1: MTLTexture? = nil
  var image2: MTLTexture? = nil
  var image3: MTLTexture? = nil
  var image4: MTLTexture? = nil
  var image5: MTLTexture? = nil
  var image6: MTLTexture? = nil
  var image7: MTLTexture? = nil
  var rawDataTexture: MTLTexture? = nil
  
  public init(device: MTLDevice, commandQueue: MTLCommandQueue)
  {
    self.device = device
    self.commandQueue = commandQueue
    
    let bundle: Bundle = Bundle(for: SKMetalMarchingCubes256.self)
    let file: String = bundle.path(forResource: "default", ofType: "metallib")!
    defaultLibrary = try! self.device.makeLibrary(filepath: file)
    
    constructHPLevelKernel = defaultLibrary.makeFunction(name: "constructHPLevel256")
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
    
    classifyCubesKernel = defaultLibrary.makeFunction(name: "classifyCubes256")
    
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
    
    
    traverseHPKernel = defaultLibrary.makeFunction(name: "traverseHP256")
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
  
  private func determineThreadGroups(size: Int, threadExecutionWidth: Int) -> MTLSize
  {
    if (size < threadExecutionWidth)
    {
      let width: Int = size
      let height: Int = min(max(1,threadExecutionWidth/size),size)
      let depth: Int = min(max(1,threadExecutionWidth / (width * height)),size)
      return MTLSize(width: width, height: height, depth: depth)
    }
    else // 256x256x256  32
    {
      let width: Int = threadExecutionWidth
      let height: Int = min(max(1, size / threadExecutionWidth),threadExecutionWidth)
      let depth: Int = min(max(1, (width * height) / threadExecutionWidth),threadExecutionWidth)
      return MTLSize(width: width, height: height, depth: depth)
    }
  }
  
  public func prepareHistoPyramids(_ voxels: [Float], isosurfaceVertexBuffer: inout MTLBuffer?, numberOfTriangles: inout Int) throws
  {
    
    if let classifyCubesPipelineState = classifyCubesPipelineState,
       let constructHPLevelPipelineState = constructHPLevelPipelineState,
       let traverseHPPipelineState = traverseHPPipelineState
    {
      let textureDescriptorRawData = MTLTextureDescriptor()
      textureDescriptorRawData.textureType = MTLTextureType.type3D
      textureDescriptorRawData.height = 256;
      textureDescriptorRawData.width = 256;
      textureDescriptorRawData.depth = 256;
      textureDescriptorRawData.pixelFormat = MTLPixelFormat.r32Float;
      textureDescriptorRawData.mipmapLevelCount = 1
      textureDescriptorRawData.resourceOptions = .storageModeManaged
      textureDescriptorRawData.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUInt8Image0 = MTLTextureDescriptor()
      textureDescriptorUInt8Image0.textureType = MTLTextureType.type3D
      textureDescriptorUInt8Image0.height = 256;
      textureDescriptorUInt8Image0.width = 256;
      textureDescriptorUInt8Image0.depth = 256;
      textureDescriptorUInt8Image0.pixelFormat = MTLPixelFormat.rgba8Uint
      textureDescriptorUInt8Image0.mipmapLevelCount = 1
      textureDescriptorUInt8Image0.resourceOptions = .storageModePrivate
      textureDescriptorUInt8Image0.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUInt8Image1 = MTLTextureDescriptor()
      textureDescriptorUInt8Image1.textureType = MTLTextureType.type3D
      textureDescriptorUInt8Image1.height = 128;
      textureDescriptorUInt8Image1.width = 128;
      textureDescriptorUInt8Image1.depth = 128;
      textureDescriptorUInt8Image1.pixelFormat = MTLPixelFormat.rgba8Uint
      textureDescriptorUInt8Image1.mipmapLevelCount = 1
      textureDescriptorUInt8Image1.resourceOptions = .storageModePrivate
      textureDescriptorUInt8Image1.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUInt8Image2 = MTLTextureDescriptor()
      textureDescriptorUInt8Image2.textureType = MTLTextureType.type3D
      textureDescriptorUInt8Image2.height = 64;
      textureDescriptorUInt8Image2.width = 64;
      textureDescriptorUInt8Image2.depth = 64;
      textureDescriptorUInt8Image2.pixelFormat = MTLPixelFormat.r8Uint;
      textureDescriptorUInt8Image2.mipmapLevelCount = 1
      textureDescriptorUInt8Image2.resourceOptions = .storageModePrivate
      textureDescriptorUInt8Image2.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUShortImage3 = MTLTextureDescriptor()
      textureDescriptorUShortImage3.textureType = MTLTextureType.type3D
      textureDescriptorUShortImage3.height = 32;
      textureDescriptorUShortImage3.width = 32;
      textureDescriptorUShortImage3.depth = 32;
      textureDescriptorUShortImage3.pixelFormat = MTLPixelFormat.r16Uint;
      textureDescriptorUShortImage3.mipmapLevelCount = 1
      textureDescriptorUShortImage3.resourceOptions = .storageModePrivate
      textureDescriptorUShortImage3.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUShortImage4 = MTLTextureDescriptor()
      textureDescriptorUShortImage4.textureType = MTLTextureType.type3D
      textureDescriptorUShortImage4.height = 16;
      textureDescriptorUShortImage4.width = 16;
      textureDescriptorUShortImage4.depth = 16;
      textureDescriptorUShortImage4.pixelFormat = MTLPixelFormat.r16Uint;
      textureDescriptorUShortImage4.mipmapLevelCount = 1
      textureDescriptorUShortImage4.resourceOptions = .storageModePrivate
      textureDescriptorUShortImage4.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUShortImage5 = MTLTextureDescriptor()
      textureDescriptorUShortImage5.textureType = MTLTextureType.type3D
      textureDescriptorUShortImage5.height = 8;
      textureDescriptorUShortImage5.width = 8;
      textureDescriptorUShortImage5.depth = 8;
      textureDescriptorUShortImage5.pixelFormat = MTLPixelFormat.r16Uint;
      textureDescriptorUShortImage5.mipmapLevelCount = 1
      textureDescriptorUShortImage5.resourceOptions = .storageModePrivate
      textureDescriptorUShortImage5.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUIntImage6 = MTLTextureDescriptor()
      textureDescriptorUIntImage6.textureType = MTLTextureType.type3D
      textureDescriptorUIntImage6.height = 4;
      textureDescriptorUIntImage6.width = 4;
      textureDescriptorUIntImage6.depth = 4;
      textureDescriptorUIntImage6.pixelFormat = MTLPixelFormat.r32Uint;
      textureDescriptorUIntImage6.mipmapLevelCount = 1
      textureDescriptorUIntImage6.resourceOptions = .storageModePrivate
      textureDescriptorUIntImage6.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUIntImage7 = MTLTextureDescriptor()
      textureDescriptorUIntImage7.textureType = MTLTextureType.type3D
      textureDescriptorUIntImage7.height = 2;
      textureDescriptorUIntImage7.width = 2;
      textureDescriptorUIntImage7.depth = 2;
      textureDescriptorUIntImage7.pixelFormat = MTLPixelFormat.r32Uint;
      textureDescriptorUIntImage7.mipmapLevelCount = 1
      textureDescriptorUIntImage7.resourceOptions = .storageModeManaged
      textureDescriptorUIntImage7.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      guard let image0 = device.makeTexture(descriptor: textureDescriptorUInt8Image0),
            let image1 = device.makeTexture(descriptor: textureDescriptorUInt8Image1),
            let image2 = device.makeTexture(descriptor: textureDescriptorUInt8Image2),
            let image3 = device.makeTexture(descriptor: textureDescriptorUShortImage3),
            let image4 = device.makeTexture(descriptor: textureDescriptorUShortImage4),
            let image5 = device.makeTexture(descriptor: textureDescriptorUShortImage5),
            let image6 = device.makeTexture(descriptor: textureDescriptorUIntImage6),
            let image7 = device.makeTexture(descriptor: textureDescriptorUIntImage7),
            let rawDataTexture = device.makeTexture(descriptor: textureDescriptorRawData) else {
        throw SimulationKitError.couldNotCreateTexture
      }
      
      
      let region: MTLRegion = MTLRegionMake3D(0, 0, 0, 256, 256, 256)
      rawDataTexture.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: voxels, bytesPerRow: MemoryLayout<Float>.stride * region.size.width, bytesPerImage: MemoryLayout<Float>.stride * region.size.width * region.size.height)
      guard let isoValueBufferData: MTLBuffer = device.makeBuffer(bytes: &isoValue, length: MemoryLayout<Float>.stride, options: .storageModeManaged) else {
       throw SimulationKitError.couldNotCreateBuffer
      }
      
      guard let commandBuffer = commandQueue.makeCommandBuffer() else {
        throw SimulationKitError.couldNotMakeCommandBuffer
      }
      
      guard let commandEncoder0 = commandBuffer.makeComputeCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandBuffer
      }
      commandEncoder0.setComputePipelineState(classifyCubesPipelineState)
      commandEncoder0.setTexture(rawDataTexture, index: 0)
      commandEncoder0.setTexture(image0, index: 1)
      commandEncoder0.setBuffer(isoValueBufferData, offset: 0, index: 0)
      let threadExecutionWidthClassifyCubes: Int = classifyCubesPipelineState.threadExecutionWidth
      let threadsPerGroup256: MTLSize = determineThreadGroups(size: 256, threadExecutionWidth: threadExecutionWidthClassifyCubes)
      let threadGroups256: MTLSize = MTLSizeMake(256 / threadsPerGroup256.width, 256 / threadsPerGroup256.height, 256 / threadsPerGroup256.depth)
      commandEncoder0.dispatchThreadgroups(threadGroups256, threadsPerThreadgroup: threadsPerGroup256)
      commandEncoder0.endEncoding()
      
      let threadExecutionWidth: Int = constructHPLevelPipelineState.threadExecutionWidth
      
      guard let commandEncoder1 = commandBuffer.makeComputeCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandBuffer
      }
      commandEncoder1.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder1.setTexture(image0, index: 0)
      commandEncoder1.setTexture(image1, index: 1)
      let threadsPerGroup128: MTLSize = determineThreadGroups(size: 128, threadExecutionWidth: threadExecutionWidth)
      let threadGroups128: MTLSize = MTLSizeMake(128 / threadsPerGroup128.width, 128 / threadsPerGroup128.height, 128 / threadsPerGroup128.depth)
      commandEncoder1.dispatchThreadgroups(threadGroups128, threadsPerThreadgroup: threadsPerGroup128)
      commandEncoder1.endEncoding()
      
      guard let commandEncoder2 = commandBuffer.makeComputeCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandBuffer
      }
      commandEncoder2.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder2.setTexture(image1, index: 0)
      commandEncoder2.setTexture(image2, index: 1)
      let threadsPerGroup64: MTLSize = determineThreadGroups(size: 64, threadExecutionWidth: threadExecutionWidth)
      let threadGroups64: MTLSize = MTLSizeMake(64 / threadsPerGroup64.width, 64 / threadsPerGroup64.height, 64 / threadsPerGroup64.depth)
      commandEncoder2.dispatchThreadgroups(threadGroups64, threadsPerThreadgroup: threadsPerGroup64)
      commandEncoder2.endEncoding()
      
      guard let commandEncoder3 = commandBuffer.makeComputeCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandBuffer
      }
      commandEncoder3.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder3.setTexture(image2, index: 0)
      commandEncoder3.setTexture(image3, index: 1)
      let threadsPerGroup32: MTLSize = determineThreadGroups(size: 32, threadExecutionWidth: threadExecutionWidth)
      let threadGroups32: MTLSize = MTLSizeMake(32 / threadsPerGroup32.width, 32 / threadsPerGroup32.height, 32 / threadsPerGroup32.depth)
      commandEncoder3.dispatchThreadgroups(threadGroups32, threadsPerThreadgroup: threadsPerGroup32)
      commandEncoder3.endEncoding()
      
      guard let commandEncoder4 = commandBuffer.makeComputeCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandBuffer
      }
      commandEncoder4.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder4.setTexture(image3, index: 0)
      commandEncoder4.setTexture(image4, index: 1)
      let threadsPerGroup16: MTLSize = determineThreadGroups(size: 16, threadExecutionWidth: threadExecutionWidth)
      let threadGroups16: MTLSize = MTLSizeMake(16 / threadsPerGroup16.width, 16 / threadsPerGroup16.height, 16 / threadsPerGroup16.depth)
      commandEncoder4.dispatchThreadgroups(threadGroups16, threadsPerThreadgroup: threadsPerGroup16)
      commandEncoder4.endEncoding()
      
      guard let commandEncoder5 = commandBuffer.makeComputeCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandBuffer
      }
      commandEncoder5.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder5.setTexture(image4, index: 0)
      commandEncoder5.setTexture(image5, index: 1)
      let threadsPerGroup8: MTLSize = determineThreadGroups(size: 8, threadExecutionWidth: threadExecutionWidth)
      let threadGroups8: MTLSize = MTLSizeMake(8 / threadsPerGroup8.width, 8 / threadsPerGroup8.height, 8 / threadsPerGroup8.depth)
      commandEncoder5.dispatchThreadgroups(threadGroups8, threadsPerThreadgroup: threadsPerGroup8)
      commandEncoder5.endEncoding()
      
      guard let commandEncoder6 = commandBuffer.makeComputeCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandBuffer
      }
      commandEncoder6.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder6.setTexture(image5, index: 0)
      commandEncoder6.setTexture(image6, index: 1)
      let threadsPerGroup4: MTLSize = determineThreadGroups(size: 4, threadExecutionWidth: threadExecutionWidth)
      let threadGroups4: MTLSize = MTLSizeMake(4 / threadsPerGroup4.width, 4 / threadsPerGroup4.height, 4 / threadsPerGroup4.depth)
      commandEncoder6.dispatchThreadgroups(threadGroups4, threadsPerThreadgroup: threadsPerGroup4)
      commandEncoder6.endEncoding()
      
      guard let commandEncoder7 = commandBuffer.makeComputeCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandBuffer
      }
      commandEncoder7.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder7.setTexture(image6, index: 0)
      commandEncoder7.setTexture(image7, index: 1)
      let threadsPerGroup2: MTLSize = determineThreadGroups(size: 2, threadExecutionWidth: threadExecutionWidth)
      let threadGroups2: MTLSize = MTLSizeMake(2 / threadsPerGroup2.width, 2 / threadsPerGroup2.height, 2 / threadsPerGroup2.width)
      commandEncoder7.dispatchThreadgroups(threadGroups2, threadsPerThreadgroup: threadsPerGroup2)
      commandEncoder7.endEncoding()
      
      
      guard let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandBuffer
      }
      blitEncoder.synchronize(texture: image7, slice: 0, level: 0)
      blitEncoder.endEncoding()
      
      commandBuffer.commit()
      
      commandBuffer.waitUntilCompleted()
      
      if let error = commandBuffer.error
      {
        throw NSError(domain: SimulationKitError.domain, code: SimulationKitError.code.genericMetalError.rawValue, userInfo: [NSLocalizedDescriptionKey : error.localizedDescription])
      }
      
      var imageBytes2x2 = [UInt32](repeating: 0, count: 2*2*2)
      let region3d2x2 = MTLRegionMake3D(0, 0, 0, 2, 2, 2)
      image7.getBytes(&imageBytes2x2, bytesPerRow: 2 * MemoryLayout<UInt32>.stride, bytesPerImage: MemoryLayout<UInt32>.stride * 2 * 2, from: region3d2x2, mipmapLevel: 0, slice: 0)
      
      var sum2: UInt32 = 0
      for i in 0..<8
      {
        sum2 += imageBytes2x2[i]
      }
      
      numberOfTriangles = Int(sum2)
      
      if numberOfTriangles > 0
      {
        // 3 points consisting of a position, a normal, and texture coordinates
        isosurfaceVertexBuffer = device.makeBuffer(length: Int(sum2) * 3 * 3 * MemoryLayout<SIMD4<Float>>.stride, options: .storageModeShared)
        
        if isosurfaceVertexBuffer == nil
        {
          throw SimulationKitError.couldNotCreateBuffer
        }
        
        if sum2>0
        {
          guard let commandBuffer2 = commandQueue.makeCommandBuffer() else {
            throw SimulationKitError.couldNotMakeCommandBuffer
          }
          guard let commandEncoder2 = commandBuffer2.makeComputeCommandEncoder() else {
            throw SimulationKitError.couldNotMakeCommandEncoder
          }
          
          let threadExecutionWidth: Int = traverseHPPipelineState.threadExecutionWidth
          
          commandEncoder2.setComputePipelineState(traverseHPPipelineState)
          
          var dataSize: UInt32 = UInt32(sum2)
          let sumBufferData: MTLBuffer = device.makeBuffer(bytes: &dataSize, length: MemoryLayout<UInt32>.stride, options: .storageModeManaged)!
          
          commandEncoder2.setTexture(image0, index: 0)
          commandEncoder2.setTexture(image1, index: 1)
          commandEncoder2.setTexture(image2, index: 2)
          commandEncoder2.setTexture(image3, index: 3)
          commandEncoder2.setTexture(image4, index: 4)
          commandEncoder2.setTexture(image5, index: 5)
          commandEncoder2.setTexture(image6, index: 6)
          commandEncoder2.setTexture(image7, index: 7)
          commandEncoder2.setTexture(rawDataTexture, index: 8)
          commandEncoder2.setBuffer(isosurfaceVertexBuffer!, offset: 0, index: 0)
          commandEncoder2.setBuffer(isoValueBufferData, offset: 0, index: 1)
          commandEncoder2.setBuffer(sumBufferData, offset: 0, index: 2)
          
          let global_work_size: Int = (Int(sum2) + threadExecutionWidth - (Int(sum2) - threadExecutionWidth*(Int(sum2) / threadExecutionWidth)))
          
          let threadsPerGroupSum: MTLSize = MTLSizeMake(threadExecutionWidth, 1, 1)
          let threadGroupsSum: MTLSize = MTLSizeMake(global_work_size / threadsPerGroupSum.width, 1,1)
          
          commandEncoder2.dispatchThreadgroups(threadGroupsSum, threadsPerThreadgroup: threadsPerGroupSum)
          
          commandEncoder2.endEncoding()
          
          commandBuffer2.commit()
          
          commandBuffer2.waitUntilCompleted()
          
          if let error = commandBuffer2.error
          {
            throw NSError(domain: SimulationKitError.domain, code: SimulationKitError.code.genericMetalError.rawValue, userInfo: [NSLocalizedDescriptionKey : error.localizedDescription])
          }
        }
      }
    }
  }
}


