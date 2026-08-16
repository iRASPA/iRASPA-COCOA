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
  var countHPTrianglesPipelineState: MTLComputePipelineState? = nil
  
  public init(device: MTLDevice, commandQueue: MTLCommandQueue, dimensions: SIMD3<Int32>)
  {
    self.device = device
    self.commandQueue = commandQueue
    self.dimensions = SIMD3<UInt32>(UInt32(dimensions.x),UInt32(dimensions.y),UInt32(dimensions.z))
    
    let bundle: Bundle = Bundle(for: SKMetalMarchingCubes128.self)
    defaultLibrary = RKMetal.loadDefaultLibrary(device: device, bundle: bundle)
    
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

    if let countKernel = defaultLibrary.makeFunction(name: "countHPTriangles")
    {
      countHPTrianglesPipelineState = try? device.makeComputePipelineState(function: countKernel)
    }
  }

  private func dispatch3D(_ encoder: MTLComputeCommandEncoder, pipeline: MTLComputePipelineState, size: Int)
  {
    let w = max(pipeline.threadExecutionWidth, 1)
    let h = max(1, pipeline.maxTotalThreadsPerThreadgroup / w)
    let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
    let threadgroups = MTLSizeMake((size + w - 1) / w, (size + h - 1) / h, size)
    encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
  }
  
  
  public func prepareHistoPyramids(_ voxels: [Float]) throws -> MTLBuffer?
  {
    guard let classifyCubesPipelineState = classifyCubesPipelineState,
          let constructHPLevelPipelineState = constructHPLevelPipelineState,
          let traverseHPPipelineState = traverseHPPipelineState else {
      LogQueue.shared.error(destination: nil, message: "Marching cubes Metal kernels were not found in SimulationKit.default.metallib")
      throw SimulationKitError.couldNotCreateTexture
    }

      let largestSize: UInt32 = max(dimensions.x,dimensions.y,dimensions.z)
      var powerOfTwo: Int32 = 1
      while(largestSize > Int(pow(2.0,Double(powerOfTwo))))
      {
        powerOfTwo += 1
      }
      
      var bufferSize: Int = Int(pow(2.0,Double(powerOfTwo)))
      let size: Int = bufferSize
      var images: [MTLTexture] = []

      guard let rawDataTexture = RKMetal.makePrivate3DTexture(device: device, size: bufferSize, pixelFormat: .r32Float, usage: .shaderRead) else {
        throw SimulationKitError.couldNotCreateTexture
      }

      let voxelCount = bufferSize * bufferSize * bufferSize
      var cube = [Float](repeating: 0, count: voxelCount)
      let copyCount = min(voxels.count, voxelCount)
      if copyCount > 0
      {
        cube.replaceSubrange(0..<copyCount, with: voxels[0..<copyCount])
      }
      guard let voxelBuffer = device.makeBuffer(bytes: cube, length: voxelCount * MemoryLayout<Float>.stride, options: .storageModeShared) else {
        throw SimulationKitError.couldNotCreateBuffer
      }

      for i in 1..<powerOfTwo
      {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type3D
        textureDescriptor.height = bufferSize;
        textureDescriptor.width = bufferSize;
        textureDescriptor.depth = bufferSize;
        textureDescriptor.mipmapLevelCount = 1
        textureDescriptor.storageMode = .private
        textureDescriptor.usage = [MTLTextureUsage.shaderRead, MTLTextureUsage.shaderWrite]
        
        // iOS only allows shader writes to a small set of 32-bit integer formats.
        // The base level stores (triangleCount, cubeIndex); later levels store sums.
        textureDescriptor.pixelFormat = (i == 1) ? MTLPixelFormat.rg32Uint : MTLPixelFormat.r32Uint
      
        guard let image: MTLTexture = device.makeTexture(descriptor: textureDescriptor) else {
          throw SimulationKitError.couldNotCreateTexture
        }
        images.append(image)
                
        bufferSize /= 2
      }
      
      let textureDescriptor = MTLTextureDescriptor()
      textureDescriptor.textureType = MTLTextureType.type3D
      textureDescriptor.height = bufferSize;
      textureDescriptor.width = bufferSize;
      textureDescriptor.depth = bufferSize;
      textureDescriptor.mipmapLevelCount = 1
      textureDescriptor.storageMode = .private
      textureDescriptor.pixelFormat = MTLPixelFormat.r32Uint;
      textureDescriptor.usage = [MTLTextureUsage.shaderRead, MTLTextureUsage.shaderWrite]
      guard let image: MTLTexture = device.makeTexture(descriptor: textureDescriptor) else {
        throw SimulationKitError.couldNotCreateTexture
      }
      images.append(image)
      
      
      guard let isoValueBufferData: MTLBuffer = device.makeBuffer(bytes: &isoValue, length: MemoryLayout<Float>.stride, options: RKMetal.hostStorage) else {
        throw SimulationKitError.couldNotCreateBuffer
      }
      
      guard let dimensionsBufferData: MTLBuffer = device.makeBuffer(bytes: &dimensions, length: MemoryLayout<SIMD3<UInt32>>.stride, options: RKMetal.hostStorage) else {
       throw SimulationKitError.couldNotCreateBuffer
      }
      
      var arraySize: Int32 = powerOfTwo - 1;
      guard let sizeBufferData: MTLBuffer = device.makeBuffer(bytes: &arraySize, length: MemoryLayout<Int32>.stride, options: RKMetal.hostStorage) else {
       throw SimulationKitError.couldNotCreateBuffer
      }
      
      guard let commandBuffer = commandQueue.makeCommandBuffer() else {
        throw SimulationKitError.couldNotMakeCommandBuffer
      }

      guard let uploadEncoder = commandBuffer.makeBlitCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandEncoder
      }
      uploadEncoder.copy(from: voxelBuffer, sourceOffset: 0, sourceBytesPerRow: size * MemoryLayout<Float>.stride, sourceBytesPerImage: size * size * MemoryLayout<Float>.stride, sourceSize: MTLSizeMake(size, size, size), to: rawDataTexture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOriginMake(0, 0, 0))
      uploadEncoder.endEncoding()
      
      guard let commandEncoder1 = commandBuffer.makeComputeCommandEncoder() else {
        throw SimulationKitError.couldNotMakeCommandEncoder
      }
      commandEncoder1.setComputePipelineState(classifyCubesPipelineState)
      commandEncoder1.setTexture(rawDataTexture, index: 0)
      commandEncoder1.setTexture(images[0], index: 1)
      commandEncoder1.setBuffer(isoValueBufferData, offset: 0, index: 0)
      commandEncoder1.setBuffer(dimensionsBufferData, offset: 0, index: 1)
      dispatch3D(commandEncoder1, pipeline: classifyCubesPipelineState, size: size)
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
        dispatch3D(commandEncoder2, pipeline: constructHPLevelPipelineState, size: bufferSize)
        commandEncoder2.endEncoding()
        
        bufferSize /= 2
      }
      
    
      guard let countBuffer = device.makeBuffer(length: MemoryLayout<UInt32>.stride, options: .storageModeShared) else {
        throw SimulationKitError.couldNotCreateBuffer
      }
      countBuffer.contents().bindMemory(to: UInt32.self, capacity: 1).pointee = 0

      if let countPipeline = countHPTrianglesPipelineState,
         let countEncoder = commandBuffer.makeComputeCommandEncoder()
      {
        countEncoder.setComputePipelineState(countPipeline)
        countEncoder.setTexture(images.last, index: 0)
        countEncoder.setBuffer(countBuffer, offset: 0, index: 0)
        countEncoder.dispatchThreadgroups(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
        countEncoder.endEncoding()
      }
      else
      {
        let alignment = max(device.minimumLinearTextureAlignment(for: .r32Uint), 16)
        let bytesPerRow = max(2 * MemoryLayout<UInt32>.stride, alignment)
        let alignedBPR = ((bytesPerRow + alignment - 1) / alignment) * alignment
        let alignedBPI = alignedBPR * 2
        guard let alignedBuffer = device.makeBuffer(length: alignedBPI * 2, options: .storageModeShared),
              let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
          throw SimulationKitError.couldNotMakeCommandEncoder
        }
        blitEncoder.copy(from: images.last!, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: MTLSizeMake(2, 2, 2), to: alignedBuffer, destinationOffset: 0, destinationBytesPerRow: alignedBPR, destinationBytesPerImage: alignedBPI)
        #if os(macOS)
        blitEncoder.synchronize(resource: alignedBuffer)
        #endif
        blitEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        if let error = commandBuffer.error
        {
          throw NSError(domain: SimulationKitError.domain, code: SimulationKitError.code.genericMetalError.rawValue, userInfo: [NSLocalizedDescriptionKey : error.localizedDescription])
        }
        var numberOfTriangles: UInt32 = 0
        let raw = alignedBuffer.contents()
        for z in 0..<2
        {
          for y in 0..<2
          {
            for x in 0..<2
            {
              let offset = z * alignedBPI + y * alignedBPR + x * MemoryLayout<UInt32>.stride
              numberOfTriangles += raw.load(fromByteOffset: offset, as: UInt32.self)
            }
          }
        }
        return try extractVertices(numberOfTriangles: numberOfTriangles, rawDataTexture: rawDataTexture, images: images, isoValueBufferData: isoValueBufferData, dimensionsBufferData: dimensionsBufferData, sizeBufferData: sizeBufferData, traverseHPPipelineState: traverseHPPipelineState)
      }

      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()
      if let error = commandBuffer.error
      {
        throw NSError(domain: SimulationKitError.domain, code: SimulationKitError.code.genericMetalError.rawValue, userInfo: [NSLocalizedDescriptionKey : error.localizedDescription])
      }

      let numberOfTriangles = countBuffer.contents().bindMemory(to: UInt32.self, capacity: 1).pointee
      return try extractVertices(numberOfTriangles: numberOfTriangles, rawDataTexture: rawDataTexture, images: images, isoValueBufferData: isoValueBufferData, dimensionsBufferData: dimensionsBufferData, sizeBufferData: sizeBufferData, traverseHPPipelineState: traverseHPPipelineState)
  }

  private func extractVertices(numberOfTriangles: UInt32, rawDataTexture: MTLTexture, images: [MTLTexture], isoValueBufferData: MTLBuffer, dimensionsBufferData: MTLBuffer, sizeBufferData: MTLBuffer, traverseHPPipelineState: MTLComputePipelineState) throws -> MTLBuffer?
  {
      if numberOfTriangles > 0
      {
        let isosurfaceVertexBuffer: MTLBuffer? = device.makeBuffer(length: Int(numberOfTriangles) * 3 * 3 * MemoryLayout<SIMD4<Float>>.stride, options: .storageModeShared)
        if isosurfaceVertexBuffer == nil
        {
          throw SimulationKitError.couldNotCreateBuffer
        }
          guard let commandBuffer2 = commandQueue.makeCommandBuffer() else {
            throw SimulationKitError.couldNotMakeCommandBuffer
          }
          guard let commandEncoder2 = commandBuffer2.makeComputeCommandEncoder() else {
            throw SimulationKitError.couldNotMakeCommandEncoder
          }
          var dataSize: UInt32 = UInt32(numberOfTriangles)
          guard let sumBufferData: MTLBuffer = device.makeBuffer(bytes: &dataSize, length: MemoryLayout<UInt32>.stride, options: RKMetal.hostStorage) else {
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
          let threadExecutionWidth: Int = max(traverseHPPipelineState.threadExecutionWidth, 1)
          let threadgroups = MTLSizeMake((Int(numberOfTriangles) + threadExecutionWidth - 1) / threadExecutionWidth, 1, 1)
          commandEncoder2.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: MTLSizeMake(threadExecutionWidth, 1, 1))
          commandEncoder2.endEncoding()
          commandBuffer2.commit()
          commandBuffer2.waitUntilCompleted()
          if let error = commandBuffer2.error
          {
            throw NSError(domain: SimulationKitError.domain, code: SimulationKitError.code.genericMetalError.rawValue, userInfo: [NSLocalizedDescriptionKey : error.localizedDescription])
          }
          return isosurfaceVertexBuffer
      }
    return nil
  }
}


