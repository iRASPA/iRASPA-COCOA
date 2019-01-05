/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2019 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

public class SKMetalMarchingCubes
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
  var rawDataTexture: MTLTexture? = nil
  
  public init(device: MTLDevice, commandQueue: MTLCommandQueue)
  {
    self.device = device
    self.commandQueue = commandQueue
    
    let bundle: Bundle = Bundle(for: SKMetalMarchingCubes.self)
    let file: String = bundle.path(forResource: "default", ofType: "metallib")!
    defaultLibrary = try! self.device.makeLibrary(filepath: file)
    
    constructHPLevelKernel = defaultLibrary.makeFunction(name: "constructHPLevel128")
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
    
    classifyCubesKernel = defaultLibrary.makeFunction(name: "classifyCubes128")
    
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
    
    
    traverseHPKernel = defaultLibrary.makeFunction(name: "traverseHP128")
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
    else // 128x128x128  32
    {
      let width: Int = threadExecutionWidth
      let height: Int = min(max(1, size / threadExecutionWidth),threadExecutionWidth)
      let depth: Int = min(max(1, (width * height) / threadExecutionWidth),threadExecutionWidth)
      return MTLSize(width: width, height: height, depth: depth)
    }
  }
  
  public func prepareHistoPyramids(_ voxels: [Float], isosurfaceVertexBuffer: inout MTLBuffer?, numberOfTriangles: inout Int)
  {
    
    if let classifyCubesPipelineState = classifyCubesPipelineState,
      let constructHPLevelPipelineState = constructHPLevelPipelineState,
      let traverseHPPipelineState = traverseHPPipelineState
    {
      let textureDescriptorRawData = MTLTextureDescriptor()
      textureDescriptorRawData.textureType = MTLTextureType.type3D
      textureDescriptorRawData.height = 128;
      textureDescriptorRawData.width = 128;
      textureDescriptorRawData.depth = 128;
      textureDescriptorRawData.pixelFormat = MTLPixelFormat.r32Float;
      textureDescriptorRawData.mipmapLevelCount = 1
      textureDescriptorRawData.resourceOptions = .storageModeManaged
      textureDescriptorRawData.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      
      let textureDescriptorUInt8Image0 = MTLTextureDescriptor()
      textureDescriptorUInt8Image0.textureType = MTLTextureType.type3D
      textureDescriptorUInt8Image0.height = 128;
      textureDescriptorUInt8Image0.width = 128;
      textureDescriptorUInt8Image0.depth = 128;
      textureDescriptorUInt8Image0.pixelFormat = MTLPixelFormat.rgba8Uint
      textureDescriptorUInt8Image0.mipmapLevelCount = 1
      //textureDescriptorUInt8Image0.cpuCacheMode = .DefaultCache
      textureDescriptorUInt8Image0.resourceOptions = .storageModePrivate
      textureDescriptorUInt8Image0.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUInt8Image1 = MTLTextureDescriptor()
      textureDescriptorUInt8Image1.textureType = MTLTextureType.type3D
      textureDescriptorUInt8Image1.height = 64;
      textureDescriptorUInt8Image1.width = 64;
      textureDescriptorUInt8Image1.depth = 64;
      textureDescriptorUInt8Image1.pixelFormat = MTLPixelFormat.r8Uint;
      textureDescriptorUInt8Image1.mipmapLevelCount = 1
      textureDescriptorUInt8Image1.resourceOptions = .storageModePrivate
      textureDescriptorUInt8Image1.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUShortImage2 = MTLTextureDescriptor()
      textureDescriptorUShortImage2.textureType = MTLTextureType.type3D
      textureDescriptorUShortImage2.height = 32;
      textureDescriptorUShortImage2.width = 32;
      textureDescriptorUShortImage2.depth = 32;
      textureDescriptorUShortImage2.pixelFormat = MTLPixelFormat.r16Uint;
      textureDescriptorUShortImage2.mipmapLevelCount = 1
      textureDescriptorUShortImage2.resourceOptions = .storageModePrivate
      textureDescriptorUShortImage2.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUShortImage3 = MTLTextureDescriptor()
      textureDescriptorUShortImage3.textureType = MTLTextureType.type3D
      textureDescriptorUShortImage3.height = 16;
      textureDescriptorUShortImage3.width = 16;
      textureDescriptorUShortImage3.depth = 16;
      textureDescriptorUShortImage3.pixelFormat = MTLPixelFormat.r16Uint;
      textureDescriptorUShortImage3.mipmapLevelCount = 1
      textureDescriptorUShortImage3.resourceOptions = .storageModePrivate
      textureDescriptorUShortImage3.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUShortImage4 = MTLTextureDescriptor()
      textureDescriptorUShortImage4.textureType = MTLTextureType.type3D
      textureDescriptorUShortImage4.height = 8;
      textureDescriptorUShortImage4.width = 8;
      textureDescriptorUShortImage4.depth = 8;
      textureDescriptorUShortImage4.pixelFormat = MTLPixelFormat.r16Uint;
      textureDescriptorUShortImage4.mipmapLevelCount = 1
      textureDescriptorUShortImage4.resourceOptions = .storageModePrivate
      textureDescriptorUShortImage4.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUIntImage5 = MTLTextureDescriptor()
      textureDescriptorUIntImage5.textureType = MTLTextureType.type3D
      textureDescriptorUIntImage5.height = 4;
      textureDescriptorUIntImage5.width = 4;
      textureDescriptorUIntImage5.depth = 4;
      textureDescriptorUIntImage5.pixelFormat = MTLPixelFormat.r32Uint;
      textureDescriptorUIntImage5.mipmapLevelCount = 1
      textureDescriptorUIntImage5.resourceOptions = .storageModePrivate
      textureDescriptorUIntImage5.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      let textureDescriptorUIntImage6 = MTLTextureDescriptor()
      textureDescriptorUIntImage6.textureType = MTLTextureType.type3D
      textureDescriptorUIntImage6.height = 2;
      textureDescriptorUIntImage6.width = 2;
      textureDescriptorUIntImage6.depth = 2;
      textureDescriptorUIntImage6.pixelFormat = MTLPixelFormat.r32Uint;
      textureDescriptorUIntImage6.mipmapLevelCount = 1
      textureDescriptorUIntImage6.resourceOptions = .storageModeManaged
      textureDescriptorUIntImage6.usage = MTLTextureUsage(rawValue: MTLTextureUsage().rawValue)
      
      image0 = device.makeTexture(descriptor: textureDescriptorUInt8Image0)
      image1 = device.makeTexture(descriptor: textureDescriptorUInt8Image1)
      image2 = device.makeTexture(descriptor: textureDescriptorUShortImage2)
      image3 = device.makeTexture(descriptor: textureDescriptorUShortImage3)
      image4 = device.makeTexture(descriptor: textureDescriptorUShortImage4)
      image5 = device.makeTexture(descriptor: textureDescriptorUIntImage5)
      image6 = device.makeTexture(descriptor: textureDescriptorUIntImage6)
      rawDataTexture = device.makeTexture(descriptor: textureDescriptorRawData)
      
      
      let region: MTLRegion = MTLRegionMake3D(0, 0, 0, 128, 128, 128)
      rawDataTexture?.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: voxels, bytesPerRow: MemoryLayout<Float>.stride * region.size.width, bytesPerImage: MemoryLayout<Float>.stride * region.size.width * region.size.height)
      let isoValueBufferData: MTLBuffer = device.makeBuffer(bytes: &isoValue, length: MemoryLayout<Float>.stride, options: .storageModeManaged)!
      
      
      
      let commandBuffer = commandQueue.makeCommandBuffer()!
      
      // Creates the command encoder from the command buffer
      let commandEncoder1 = commandBuffer.makeComputeCommandEncoder()!
      commandEncoder1.setComputePipelineState(classifyCubesPipelineState)
      commandEncoder1.setTexture(rawDataTexture, index: 0)
      commandEncoder1.setTexture(image0, index: 1)
      commandEncoder1.setBuffer(isoValueBufferData, offset: 0, index: 0)
      let threadExecutionWidthClassifyCubes: Int = classifyCubesPipelineState.threadExecutionWidth
      let threadsPerGroup128: MTLSize = determineThreadGroups(size: 128, threadExecutionWidth: threadExecutionWidthClassifyCubes)
      let threadGroups128: MTLSize = MTLSizeMake(128 / threadsPerGroup128.width, 128 / threadsPerGroup128.height, 128 / threadsPerGroup128.depth)
      commandEncoder1.dispatchThreadgroups(threadGroups128, threadsPerThreadgroup: threadsPerGroup128)
      commandEncoder1.endEncoding()
      
      
      let threadExecutionWidth: Int = constructHPLevelPipelineState.threadExecutionWidth
      
      
      // Encodes the pipeline state command
      let commandEncoder2 = commandBuffer.makeComputeCommandEncoder()!
      commandEncoder2.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder2.setTexture(image0, index: 0)
      commandEncoder2.setTexture(image1, index: 1)
      let threadsPerGroup64: MTLSize = determineThreadGroups(size: 64, threadExecutionWidth: threadExecutionWidth)
      let threadGroups64: MTLSize = MTLSizeMake(64 / threadsPerGroup64.width, 64 / threadsPerGroup64.height, 64 / threadsPerGroup64.depth)
      commandEncoder2.dispatchThreadgroups(threadGroups64, threadsPerThreadgroup: threadsPerGroup64)
      commandEncoder2.endEncoding()
      
      let commandEncoder3 = commandBuffer.makeComputeCommandEncoder()!
      commandEncoder3.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder3.setTexture(image1, index: 0)
      commandEncoder3.setTexture(image2, index: 1)
      let threadsPerGroup32: MTLSize = determineThreadGroups(size: 32, threadExecutionWidth: threadExecutionWidth)
      let threadGroups32: MTLSize = MTLSizeMake(32 / threadsPerGroup32.width, 32 / threadsPerGroup32.height, 32 / threadsPerGroup32.depth)
      commandEncoder3.dispatchThreadgroups(threadGroups32, threadsPerThreadgroup: threadsPerGroup32)
      commandEncoder3.endEncoding()
      
      let commandEncoder4 = commandBuffer.makeComputeCommandEncoder()!
      commandEncoder4.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder4.setTexture(image2, index: 0)
      commandEncoder4.setTexture(image3, index: 1)
      let threadsPerGroup16: MTLSize = determineThreadGroups(size: 16, threadExecutionWidth: threadExecutionWidth)
      let threadGroups16: MTLSize = MTLSizeMake(16 / threadsPerGroup16.width, 16 / threadsPerGroup16.height, 16 / threadsPerGroup16.depth)
      commandEncoder4.dispatchThreadgroups(threadGroups16, threadsPerThreadgroup: threadsPerGroup16)
      commandEncoder4.endEncoding()
      
      let commandEncoder5 = commandBuffer.makeComputeCommandEncoder()!
      commandEncoder5.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder5.setTexture(image3, index: 0)
      commandEncoder5.setTexture(image4, index: 1)
      let threadsPerGroup8: MTLSize = determineThreadGroups(size: 8, threadExecutionWidth: threadExecutionWidth)
      let threadGroups8: MTLSize = MTLSizeMake(8 / threadsPerGroup8.width, 8 / threadsPerGroup8.height, 8 / threadsPerGroup8.depth)
      commandEncoder5.dispatchThreadgroups(threadGroups8, threadsPerThreadgroup: threadsPerGroup8)
      commandEncoder5.endEncoding()
      
      let commandEncoder6 = commandBuffer.makeComputeCommandEncoder()!
      commandEncoder6.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder6.setTexture(image4, index: 0)
      commandEncoder6.setTexture(image5, index: 1)
      let threadsPerGroup4: MTLSize = determineThreadGroups(size: 4, threadExecutionWidth: threadExecutionWidth)
      let threadGroups4: MTLSize = MTLSizeMake(4 / threadsPerGroup4.width, 4 / threadsPerGroup4.height, 4 / threadsPerGroup4.depth)
      commandEncoder6.dispatchThreadgroups(threadGroups4, threadsPerThreadgroup: threadsPerGroup4)
      commandEncoder6.endEncoding()
      
      let commandEncoder7 = commandBuffer.makeComputeCommandEncoder()!
      commandEncoder7.setComputePipelineState(constructHPLevelPipelineState)
      commandEncoder7.setTexture(image5, index: 0)
      commandEncoder7.setTexture(image6, index: 1)
      let threadsPerGroup2: MTLSize = determineThreadGroups(size: 2, threadExecutionWidth: threadExecutionWidth)
      let threadGroups2: MTLSize = MTLSizeMake(2 / threadsPerGroup2.width, 2 / threadsPerGroup2.height, 2 / threadsPerGroup2.width)
      commandEncoder7.dispatchThreadgroups(threadGroups2, threadsPerThreadgroup: threadsPerGroup2)
      commandEncoder7.endEncoding()
      
      
      let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()!
      blitEncoder.synchronize(texture: image6!, slice: 0, level: 0)
      blitEncoder.endEncoding()
      
      // Commits the commands to the command buffer
      commandBuffer.commit()
      
      // Waits until the commands are executed
      commandBuffer.waitUntilCompleted()
      
      if let error = commandBuffer.error
      {
        LogQueue.shared.error(destination: nil, message: "Metal error in RKMetalMarchingCubes: " + error.localizedDescription)
        return
      }
      
      var imageBytes2x2 = [UInt32](repeating: 0, count: 2*2*2)
      let region3d2x2 = MTLRegionMake3D(0, 0, 0, 2, 2, 2)
      image6?.getBytes(&imageBytes2x2, bytesPerRow: 2 * MemoryLayout<UInt32>.stride, bytesPerImage: MemoryLayout<UInt32>.stride * 2 * 2, from: region3d2x2, mipmapLevel: 0, slice: 0)
      
      var sum2: UInt32 = 0
      for i in 0..<8
      {
        sum2 += imageBytes2x2[i]
      }
      
      numberOfTriangles = Int(sum2)
      
      if numberOfTriangles > 0
      {
        
        // 3 points consisting of a position, a normal, and texture coordinates
        isosurfaceVertexBuffer = device.makeBuffer(length: Int(sum2) * 3 * 3 * MemoryLayout<float4>.stride, options: .storageModeShared)
        
        
        if sum2>0
        {
          let commandBuffer2 = commandQueue.makeCommandBuffer()!
          // Creates the command encoder from the command buffer
          let commandEncoder2 = commandBuffer2.makeComputeCommandEncoder()!
          let threadExecutionWidth: Int = traverseHPPipelineState.threadExecutionWidth
          
          
          // Encodes the pipeline state command
          commandEncoder2.setComputePipelineState(traverseHPPipelineState)
          
          var dataSize: UInt32 = UInt32(sum2)
          let sumBufferData: MTLBuffer = device.makeBuffer(bytes: &dataSize, length: MemoryLayout<UInt32>.stride, options: .storageModeManaged)!
          
          
          // Encodes the input texture command
          commandEncoder2.setTexture(image0, index: 0)
          commandEncoder2.setTexture(image1, index: 1)
          commandEncoder2.setTexture(image2, index: 2)
          commandEncoder2.setTexture(image3, index: 3)
          commandEncoder2.setTexture(image4, index: 4)
          commandEncoder2.setTexture(image5, index: 5)
          commandEncoder2.setTexture(image6, index: 6)
          commandEncoder2.setTexture(rawDataTexture, index: 7)
          commandEncoder2.setBuffer(isosurfaceVertexBuffer!, offset: 0, index: 0)
          commandEncoder2.setBuffer(isoValueBufferData, offset: 0, index: 1)
          commandEncoder2.setBuffer(sumBufferData, offset: 0, index: 2)
          
          
          let global_work_size: Int = (Int(sum2) + threadExecutionWidth - (Int(sum2) - threadExecutionWidth*(Int(sum2) / threadExecutionWidth)))
          
          
          let threadsPerGroupSum: MTLSize = MTLSizeMake(threadExecutionWidth, 1, 1)
          let threadGroupsSum: MTLSize = MTLSizeMake(global_work_size / threadsPerGroupSum.width, 1,1)
          
          commandEncoder2.dispatchThreadgroups(threadGroupsSum, threadsPerThreadgroup: threadsPerGroupSum)
          
          commandEncoder2.endEncoding()
          
          
          // Commits the commands to the command buffer
          commandBuffer2.commit()
          
          // Waits until the commands are executed
          commandBuffer2.waitUntilCompleted()
          
          if let error = commandBuffer2.error
          {
            LogQueue.shared.error(destination: nil, message: "Metal error in RKMetalMarchingCubes: " + error.localizedDescription)
            return
          }
          
          
        }
      }
      
      
    }
    
  }
  
}


