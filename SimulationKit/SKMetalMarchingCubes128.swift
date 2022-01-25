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
import Metal
import simd
import LogViewKit

public class SKMetalMarchingCubes128
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
    
    let bundle: Bundle = Bundle(for: SKMetalMarchingCubes128.self)
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
    
    
    traverseHPKernel = defaultLibrary.makeFunction(name: "traverseHP")
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
  
  
  public func prepareHistoPyramids(_ voxels: [Float]) throws -> MTLBuffer?
  {
    if let classifyCubesPipelineState = classifyCubesPipelineState,
      let constructHPLevelPipelineState = constructHPLevelPipelineState,
      let traverseHPPipelineState = traverseHPPipelineState
    {
      let largestSize: UInt32 = max(dimensions.x,dimensions.y,dimensions.z)
      var powerOfTwo: Int32 = 1
      while(largestSize > Int(pow(2.0,Double(powerOfTwo))))
      {
        powerOfTwo += 1
      }
      
      var bufferSize: Int = Int(pow(2.0,Double(powerOfTwo)))
      let size: Int = bufferSize
      var images: [MTLTexture] = []
      
      let textureDescriptorRawData = MTLTextureDescriptor()
      textureDescriptorRawData.textureType = MTLTextureType.type3D
      textureDescriptorRawData.height = bufferSize;
      textureDescriptorRawData.width = bufferSize;
      textureDescriptorRawData.depth = bufferSize;
      textureDescriptorRawData.pixelFormat = MTLPixelFormat.r32Float;
      textureDescriptorRawData.mipmapLevelCount = 1
      textureDescriptorRawData.resourceOptions = .storageModeManaged
      textureDescriptorRawData.usage = [MTLTextureUsage.shaderRead]
      
      guard let rawDataTexture: MTLTexture = device.makeTexture(descriptor: textureDescriptorRawData) else {
        throw SimulationKitError.couldNotCreateTexture }
      
      let region: MTLRegion = MTLRegionMake3D(0, 0, 0, bufferSize, bufferSize, bufferSize)
      rawDataTexture.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: voxels, bytesPerRow: MemoryLayout<Float>.stride * region.size.width, bytesPerImage: MemoryLayout<Float>.stride * region.size.width * region.size.height)
      
      for i in 1..<powerOfTwo
      {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type3D
        textureDescriptor.height = bufferSize;
        textureDescriptor.width = bufferSize;
        textureDescriptor.depth = bufferSize;
        textureDescriptor.mipmapLevelCount = 1
        textureDescriptor.resourceOptions = .storageModePrivate
        textureDescriptor.usage = [MTLTextureUsage.shaderRead, MTLTextureUsage.shaderWrite]
        
        switch(i)
        {
        case 1:
          textureDescriptor.pixelFormat = MTLPixelFormat.rgba8Uint
          break;
        case 2:
          textureDescriptor.pixelFormat = MTLPixelFormat.r8Uint;
          break;
        case 3:
          textureDescriptor.pixelFormat = MTLPixelFormat.r16Uint;
          break;
        case 4:
          textureDescriptor.pixelFormat = MTLPixelFormat.r16Uint;
          break;
        default:
          textureDescriptor.pixelFormat = MTLPixelFormat.r32Uint;
          break;
        }
      
        guard let image: MTLTexture = device.makeTexture(descriptor: textureDescriptor) else {return nil}
        images.append(image)
                
        bufferSize /= 2
      }
      
      let textureDescriptor = MTLTextureDescriptor()
      textureDescriptor.textureType = MTLTextureType.type3D
      textureDescriptor.height = bufferSize;
      textureDescriptor.width = bufferSize;
      textureDescriptor.depth = bufferSize;
      textureDescriptor.mipmapLevelCount = 1
      textureDescriptor.resourceOptions = .storageModeManaged
      textureDescriptor.pixelFormat = MTLPixelFormat.r32Uint;
      textureDescriptor.usage = [MTLTextureUsage.shaderRead, MTLTextureUsage.shaderWrite]
      guard let image: MTLTexture = device.makeTexture(descriptor: textureDescriptor) else {return nil}
      images.append(image)
      
      
      guard let isoValueBufferData: MTLBuffer = device.makeBuffer(bytes: &isoValue, length: MemoryLayout<Float>.stride, options: .storageModeManaged) else {
        throw SimulationKitError.couldNotCreateBuffer
      }
      
      guard let dimensionsBufferData: MTLBuffer = device.makeBuffer(bytes: &dimensions, length: MemoryLayout<SIMD3<UInt32>>.stride, options: .storageModeManaged) else {
       throw SimulationKitError.couldNotCreateBuffer
      }
      
      var arraySize: Int32 = powerOfTwo - 1;
      guard let sizeBufferData: MTLBuffer = device.makeBuffer(bytes: &arraySize, length: MemoryLayout<Int32>.stride, options: .storageModeManaged) else {
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
      commandEncoder1.setTexture(images[0], index: 1)
      commandEncoder1.setBuffer(isoValueBufferData, offset: 0, index: 0)
      commandEncoder1.setBuffer(dimensionsBufferData, offset: 0, index: 1)
      let threadsPerGrid128 = MTLSize(width: size, height: size, depth: size)
      let w128: Int = classifyCubesPipelineState.threadExecutionWidth
      let h128: Int = classifyCubesPipelineState.maxTotalThreadsPerThreadgroup / w128
      let threadsPerThreadgroup128: MTLSize = MTLSizeMake(w128, h128, 1)
      commandEncoder1.dispatchThreads(threadsPerGrid128, threadsPerThreadgroup: threadsPerThreadgroup128)
      commandEncoder1.endEncoding()
            
     
      bufferSize = size / 2
      for i in 0..<Int(ceil(log2(Double(size)))-1)
      {
        guard let commandEncoder2 = commandBuffer.makeComputeCommandEncoder() else {
          throw SimulationKitError.couldNotMakeCommandEncoder
        }
        commandEncoder2.setComputePipelineState(constructHPLevelPipelineState)
        commandEncoder2.setTexture(images[i], index: 0)
        commandEncoder2.setTexture(images[i+1], index: 1)
        let threadsPerGrid64 = MTLSize(width: bufferSize, height: bufferSize, depth: bufferSize)
        let w64: Int = constructHPLevelPipelineState.threadExecutionWidth
        let h64: Int = constructHPLevelPipelineState.maxTotalThreadsPerThreadgroup / w64
        let threadsPerThreadgroup64: MTLSize = MTLSizeMake(w64, h64, 1)
        commandEncoder2.dispatchThreads(threadsPerGrid64, threadsPerThreadgroup: threadsPerThreadgroup64)
        commandEncoder2.endEncoding()
        
        bufferSize /= 2
      }
      
    
      guard let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandEncoder
      }
      blitEncoder.synchronize(texture: images.last!, slice: 0, level: 0)
      blitEncoder.endEncoding()
      
      commandBuffer.commit()
      
      commandBuffer.waitUntilCompleted()
      
      if let error = commandBuffer.error
      {
        throw NSError(domain: SimulationKitError.domain, code: SimulationKitError.code.genericMetalError.rawValue, userInfo: [NSLocalizedDescriptionKey : error.localizedDescription])
      }
      
      var imageBytes2x2 = [UInt32](repeating: 0, count: 2*2*2)
      let region3d2x2 = MTLRegionMake3D(0, 0, 0, 2, 2, 2)
      images.last!.getBytes(&imageBytes2x2, bytesPerRow: 2 * MemoryLayout<UInt32>.stride, bytesPerImage: MemoryLayout<UInt32>.stride * 2 * 2, from: region3d2x2, mipmapLevel: 0, slice: 0)
      
      var numberOfTriangles: UInt32 = 0
      for i in 0..<8
      {
        numberOfTriangles += imageBytes2x2[i]
      }
            
      if numberOfTriangles > 0
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
          commandEncoder2.setTexture(rawDataTexture, index: 0)
          for j in 0..<images.count
          {
            commandEncoder2.setTexture(images[j], index: 1+j)
          }
          commandEncoder2.setBuffer(isosurfaceVertexBuffer!, offset: 0, index: 0)
          commandEncoder2.setBuffer(isoValueBufferData, offset: 0, index: 1)
          commandEncoder2.setBuffer(sumBufferData, offset: 0, index: 2)
          commandEncoder2.setBuffer(dimensionsBufferData, offset: 0, index: 3)
          commandEncoder2.setBuffer(sizeBufferData, offset: 0, index: 4)
          
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


