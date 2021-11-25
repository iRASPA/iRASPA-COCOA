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
import LogViewKit
import SymmetryKit
import SimulationKit
import simd

class MetalEnergyIsosurfaceShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderObject]] = [[]]
  
  var opaquePipeLine: MTLRenderPipelineState! = nil
  var transparentPipeLine: MTLRenderPipelineState! = nil
  var vertexBuffer: [[MTLBuffer?]] = []
  var instanceBuffer: [[MTLBuffer?]] = [[]]
  var transparentDepthState: MTLDepthStencilState! = nil
  var depthState: MTLDepthStencilState! = nil
  
  let cachedAdsorptionSurfaces: [Int: NSCache<AnyObject, AnyObject>] = [32: NSCache(), 64: NSCache(), 128: NSCache(), 256: NSCache(), 512: NSCache()]
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let depthStateDesc: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStateDesc.depthCompareFunction = MTLCompareFunction.lessEqual
    depthStateDesc.isDepthWriteEnabled = true
    depthState = device.makeDepthStencilState(descriptor: depthStateDesc)
    
    let transparentDepthStateDescriptor: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    transparentDepthStateDescriptor.depthCompareFunction = MTLCompareFunction.lessEqual
    transparentDepthStateDescriptor.isDepthWriteEnabled = false
    transparentDepthState = device.makeDepthStencilState(descriptor: transparentDepthStateDescriptor)
    
    let opaquePipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    opaquePipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    opaquePipelineDescriptor.vertexFunction = library.makeFunction(name: "IsosurfaceVertexShader")!
    opaquePipelineDescriptor.sampleCount = maximumNumberOfSamples
    opaquePipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    opaquePipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    opaquePipelineDescriptor.fragmentFunction = library.makeFunction(name: "IsosurfaceFragmentShader")!
    opaquePipelineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.opaquePipeLine = try device.makeRenderPipelineState(descriptor: opaquePipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error) \(device)")
    }
    
    let transparentPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    transparentPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    transparentPipelineDescriptor.vertexFunction = library.makeFunction(name: "IsosurfaceVertexShader")!
    transparentPipelineDescriptor.sampleCount = maximumNumberOfSamples
    transparentPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    transparentPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    transparentPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
    transparentPipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add;
    transparentPipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add;
    transparentPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one;
    transparentPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one;
    transparentPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor =  MTLBlendFactor.oneMinusSourceAlpha;
    transparentPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor =  MTLBlendFactor.oneMinusSourceAlpha;
    transparentPipelineDescriptor.fragmentFunction = library.makeFunction(name: "IsosurfaceFragmentShader")!
    transparentPipelineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.transparentPipeLine = try device.makeRenderPipelineState(descriptor: transparentPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error) \(device)")
    }

  }
  
  public func buildVertexBuffers()
  {
    self.vertexBuffer = []
    if let _: RKRenderDataSource = renderDataSource
    {
      for i in 0..<self.renderStructures.count
      {
        var buffers: [MTLBuffer?] = []
        let structures: [RKRenderObject] = self.renderStructures[i]
        for _ in structures
        {
          buffers.append(nil)
        }
        self.vertexBuffer.append(buffers)
      }
    }
  }
  
  public func buildInstanceBuffers(device: MTLDevice)
  {
    if let _: RKRenderDataSource = renderDataSource
    {
      instanceBuffer = []
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = renderStructures[i]
        var sceneInstance: [MTLBuffer?] = [MTLBuffer?]()
        
        if structures.isEmpty
        {
          sceneInstance.append(nil)
        }
        else
        {
          for structure in structures
          {
            let renderLatticeVectors: [SIMD4<Float>] = structure.cell.renderTranslationVectors
            let buffer: MTLBuffer = device.makeBuffer(bytes: renderLatticeVectors, length: MemoryLayout<SIMD4<Float>>.stride * renderLatticeVectors.count, options:.storageModeManaged)!
            sceneInstance.append(buffer)
          }
        }
        instanceBuffer.append(sceneInstance)
      }
    }
  }
  
  public func renderOpaqueIsosurfaceWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, isosurfaceUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, size: CGSize)
  {
    commandEncoder.setDepthStencilState(depthState)
    commandEncoder.setRenderPipelineState(opaquePipeLine)
    commandEncoder.setCullMode(MTLCullMode.none)
    commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
    commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
    commandEncoder.setVertexBuffer(isosurfaceUniformBuffers, offset: 0, index: 4)
    commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 5)
    commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
    commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 1)
    commandEncoder.setFragmentBuffer(isosurfaceUniformBuffers, offset: 0, index: 2)
    
    var index = 0
    for i in 0..<self.renderStructures.count
    {
      let structures: [RKRenderObject] = self.renderStructures[i]
      
      for (j,structure) in structures.enumerated()
      {
        if let structure: RKRenderAdsorptionSurfaceSource = structure as? RKRenderAdsorptionSurfaceSource,
           let isosurfaceVertexBuffer = self.metalBuffer(vertexBuffer, sceneIndex: i, movieIndex: j),
           let instanceIsosurfaceVertexBuffer = self.metalBuffer(instanceBuffer, sceneIndex: i, movieIndex: j),
           structure.drawAdsorptionSurface,
           structure.adsorptionSurfaceRenderingMethod == .isoSurface
        {
          let vertexCount: Int = 3 * structure.adsorptionSurfaceNumberOfTriangles
          if (structure.isVisible &&  structure.adsorptionSurfaceOpacity>0.99999 && vertexCount>0)
          {
            commandEncoder.setVertexBuffer(isosurfaceVertexBuffer, offset: 0, index: 0)
            commandEncoder.setVertexBuffer(instanceIsosurfaceVertexBuffer, offset: 0, index: 1)
            commandEncoder.setVertexBufferOffset(index*MemoryLayout<RKStructureUniforms>.stride, index: 3)
            commandEncoder.setVertexBufferOffset(index*MemoryLayout<RKIsosurfaceUniforms>.stride, index: 4)
            commandEncoder.setFragmentBufferOffset(index*MemoryLayout<RKStructureUniforms>.stride, index: 1)
            commandEncoder.setFragmentBufferOffset(index*MemoryLayout<RKIsosurfaceUniforms>.stride, index: 2)
            
            commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: instanceIsosurfaceVertexBuffer.length / MemoryLayout<SIMD4<Float>>.stride)
          }
        }
        index = index + 1
      }
    }
    commandEncoder.setCullMode(MTLCullMode.back)
  }
  
  
  
  public func renderTransparentIsosurfacesWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, isosurfaceUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, size: CGSize)
  {
    if let _: RKRenderDataSource = renderDataSource
    {
      commandEncoder.setRenderPipelineState(transparentPipeLine)
      
      // for transparent surface:
      // disable depth-buffer updates (depth-buffer testing is still active)
      // the depth buffer maintains the relationship between opaque and transparent objects,
      // but does not prevent the transparent objects from occluding each other.
      commandEncoder.setDepthStencilState(self.transparentDepthState)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setVertexBuffer(isosurfaceUniformBuffers, offset: 0, index: 4)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 5)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 1)
      commandEncoder.setFragmentBuffer(isosurfaceUniformBuffers, offset: 0, index: 2)
      
      var index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderAdsorptionSurfaceSource = structure as? RKRenderAdsorptionSurfaceSource,
             let isosurfaceVertexBuffer = self.metalBuffer(vertexBuffer, sceneIndex: i, movieIndex: j),
            let instanceIsosurfaceVertexBuffer = self.metalBuffer(instanceBuffer, sceneIndex: i, movieIndex: j),
            structure.drawAdsorptionSurface,
            structure.adsorptionSurfaceRenderingMethod == .isoSurface
          {
            let vertexCount: Int = 3 * structure.adsorptionSurfaceNumberOfTriangles
            if (structure.isVisible &&  structure.adsorptionSurfaceOpacity<=0.99999 && vertexCount>0)
            {
              commandEncoder.setVertexBuffer(isosurfaceVertexBuffer, offset: 0, index: 0)
              commandEncoder.setVertexBuffer(instanceIsosurfaceVertexBuffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index*MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setVertexBufferOffset(index*MemoryLayout<RKIsosurfaceUniforms>.stride, index: 4)
              commandEncoder.setFragmentBufferOffset(index*MemoryLayout<RKStructureUniforms>.stride, index: 1)
              commandEncoder.setFragmentBufferOffset(index*MemoryLayout<RKIsosurfaceUniforms>.stride, index: 2)
              
              commandEncoder.setCullMode(MTLCullMode.front)
              commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: instanceIsosurfaceVertexBuffer.length / MemoryLayout<SIMD4<Float>>.stride)
              
              commandEncoder.setCullMode(MTLCullMode.back)
              commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: instanceIsosurfaceVertexBuffer.length / MemoryLayout<SIMD4<Float>>.stride)
            }
          }
          index = index + 1
        }
      }
    }
  }
  
  func metalBuffer(_ buffer: [[MTLBuffer?]], sceneIndex: Int, movieIndex: Int) -> MTLBuffer?
  {
    if sceneIndex < buffer.count
    {
      if movieIndex < buffer[sceneIndex].count
      {
        return buffer[sceneIndex][movieIndex]
      }
    }
    return nil
  }
  
  public func updateAdsorptionSurface(device: MTLDevice, commandQueue: MTLCommandQueue, windowController: NSWindowController?, completionHandler: @escaping () -> ())
  {
    if let _: RKRenderDataSource = renderDataSource
    {
      var info: mach_timebase_info_data_t = mach_timebase_info_data_t()
      mach_timebase_info(&info)
      
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j, structure) in structures.enumerated()
        {
          if let structure = structure as? RKRenderAdsorptionSurfaceSource, structure.drawAdsorptionSurface
          {
            var data: [Float] = []
            let size: Int = structure.adsorptionSurfaceSize
            if let cachedVersion: Data = cachedAdsorptionSurfaces[size]?.object(forKey: structure) as? Data
            {
              data = [Float](repeating: Float(0.0), count: cachedVersion.count / MemoryLayout<Float>.stride)
              let _ = data.withUnsafeMutableBytes { cachedVersion.copyBytes(to: $0, from: 0..<cachedVersion.count)
              }
              
              LogQueue.shared.verbose(destination: windowController, message: "Loading the \(structure.displayName)-Metal energy grid from cache")
            }
            else
            {
              let startTime: UInt64  = mach_absolute_time()
              
              let cell: SKCell = structure.cell
              let positions: [SIMD3<Double>] = structure.atomUnitCellPositions
              let potentialParameters: [SIMD2<Double>] = structure.potentialParameters
              let probeParameters: SIMD2<Double> = structure.adsorptionSurfaceProbeParameters
              let size: Int = structure.adsorptionSurfaceSize
              
              let numberOfReplicas: SIMD3<Int32> = cell.numberOfReplicas(forCutoff: 12.0)
              let framework: SKMetalFramework = SKMetalFramework(device: device, commandQueue: commandQueue, positions: positions, potentialParameters: potentialParameters, unitCell: cell.unitCell, numberOfReplicas: numberOfReplicas)
              
              
              data = framework.ComputeEnergyGrid(size, sizeY: size, sizeZ: size, probeParameter: probeParameters)
              
              let endTime: UInt64  = mach_absolute_time()
              
              DispatchQueue.global().async {
                let minimumGridEnergyValue = data.min()
                
                DispatchQueue.main.async {
                  structure.minimumGridEnergyValue = minimumGridEnergyValue
                }
                
                completionHandler()
              }
              
              let time: Double = Double((endTime - startTime) * UInt64(info.numer)) / Double(info.denom) * 0.000001
              LogQueue.shared.verbose(destination: windowController, message: "Time elapsed for creation of \(structure.displayName)-Metal energy grid is \(time) milliseconds")
              
              if let cache: NSCache = cachedAdsorptionSurfaces[size]
              {
                let cachedData: Data = data.withUnsafeMutableBufferPointer{Data(buffer: $0)}
                cache.setObject(cachedData as AnyObject, forKey: structure)
              }
            }
            
            let startTime: UInt64  = mach_absolute_time()
            switch(size)
            {
            case 128:
              let marchingCubes = SKMetalMarchingCubes128(device: device, commandQueue: commandQueue)
              
              marchingCubes.isoValue = Float(structure.adsorptionSurfaceIsoValue)
              
              do
              {
                try marchingCubes.prepareHistoPyramids(data, isosurfaceVertexBuffer: &vertexBuffer[i][j], numberOfTriangles: &structure.adsorptionSurfaceNumberOfTriangles)
              } catch {
                  LogQueue.shared.error(destination: windowController, message: error.localizedDescription)
              }
            case 256:
              let marchingCubes = SKMetalMarchingCubes256(device: device, commandQueue: commandQueue)
              
              marchingCubes.isoValue = Float(structure.adsorptionSurfaceIsoValue)
              do
              {
                try marchingCubes.prepareHistoPyramids(data, isosurfaceVertexBuffer: &vertexBuffer[i][j], numberOfTriangles: &structure.adsorptionSurfaceNumberOfTriangles)
              } catch {
                 LogQueue.shared.error(destination: windowController, message: error.localizedDescription)
              }
            default:
              break
            }
            
            let endTime: UInt64  = mach_absolute_time()
            
            let time: Double = Double((endTime - startTime) * UInt64(info.numer)) / Double(info.denom) * 0.000001
            
            LogQueue.shared.verbose(destination: windowController, message: "Time elapsed for creation of \(structure.displayName)-Metal energy surface is \(time) milliseconds")
          }
        }
      }
    }
  }
  
}
