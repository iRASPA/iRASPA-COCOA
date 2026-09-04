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
import LogViewKit
import MathKit
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
  
  let cachedAdsorptionSurfaces: [Int: NSCache<AnyObject, AnyObject>] = [16: NSCache(), 32: NSCache(), 64: NSCache(), 128: NSCache(), 256: NSCache(), 512: NSCache()]
  let cachedPermanentAdsorptionSurfaces: [Int: NSCache<AnyObject, AnyObject>] = [16: NSCache(), 32: NSCache(), 64: NSCache(), 128: NSCache(), 256: NSCache(), 512: NSCache()]
  
  // The well surface reads a three-floats-per-point (energy, Apollonius distance, medial reliability) field rather than the energy
  // grid; cached apart so that switching rendering methods cannot hand one builder the other's data. Like the
  // energy grid, the field depends on the probe and the force field, and is purged by the same
  // invalidateIsosurface calls (the key is only structure and grid size).
  let cachedWellFields: [Int: NSCache<AnyObject, AnyObject>] = [16: NSCache(), 32: NSCache(), 64: NSCache(), 128: NSCache(), 256: NSCache(), 512: NSCache()]
  let cachedPermanentWellFields: [Int: NSCache<AnyObject, AnyObject>] = [16: NSCache(), 32: NSCache(), 64: NSCache(), 128: NSCache(), 256: NSCache(), 512: NSCache()]
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    // Marching Cubes vertices are always 48 bytes (3 × float4). Do not reuse the shared
    // RKVertex descriptor (now 64 bytes with ribbon stripeST) — that skips 1/4 of the mesh.
    let _ = vertexDescriptor
    let isosurfaceVertexDescriptor = MTLVertexDescriptor()
    isosurfaceVertexDescriptor.attributes[0].offset = 0
    isosurfaceVertexDescriptor.attributes[0].format = .float4
    isosurfaceVertexDescriptor.attributes[0].bufferIndex = 0
    isosurfaceVertexDescriptor.attributes[1].offset = MemoryLayout<SIMD4<Float>>.stride
    isosurfaceVertexDescriptor.attributes[1].format = .float4
    isosurfaceVertexDescriptor.attributes[1].bufferIndex = 0
    isosurfaceVertexDescriptor.attributes[2].offset = MemoryLayout<SIMD4<Float>>.stride * 2
    isosurfaceVertexDescriptor.attributes[2].format = .float4
    isosurfaceVertexDescriptor.attributes[2].bufferIndex = 0
    isosurfaceVertexDescriptor.layouts[0].stepFunction = .perVertex
    isosurfaceVertexDescriptor.layouts[0].stride = MemoryLayout<SIMD4<Float>>.stride * 3
    
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
    opaquePipelineDescriptor.vertexDescriptor = isosurfaceVertexDescriptor
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
    transparentPipelineDescriptor.vertexDescriptor = isosurfaceVertexDescriptor
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
    // Keep already-computed marching-cubes meshes. Atom/bond visibility, ambient occlusion,
    // and other reloadRenderData paths rebuild vertex arrays without calling
    // updateAdsorptionSurface, and dropping the buffers here made the isosurface vanish.
    var newVertexBuffer: [[MTLBuffer?]] = []
    if let _: RKRenderDataSource = renderDataSource
    {
      for i in 0..<self.renderStructures.count
      {
        var buffers: [MTLBuffer?] = []
        let structures: [RKRenderObject] = self.renderStructures[i]
        for j in 0..<structures.count
        {
          let existing: MTLBuffer? = (i < self.vertexBuffer.count && j < self.vertexBuffer[i].count) ? self.vertexBuffer[i][j] : nil
          buffers.append(existing)
        }
        newVertexBuffer.append(buffers)
      }
    }
    self.vertexBuffer = newVertexBuffer
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
            let buffer: MTLBuffer = device.makeBuffer(bytes: renderLatticeVectors, length: MemoryLayout<SIMD4<Float>>.stride * renderLatticeVectors.count, options:RKMetal.hostStorage)!
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
    commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 3)
    
    var index = 0
    for i in 0..<self.renderStructures.count
    {
      let structures: [RKRenderObject] = self.renderStructures[i]
      
      for (j,structure) in structures.enumerated()
      {
        if let structure: RKRenderVolumetricDataSource = structure as? RKRenderVolumetricDataSource,
           let isosurfaceVertexBuffer = self.metalBuffer(vertexBuffer, sceneIndex: i, movieIndex: j),
           let instanceIsosurfaceVertexBuffer = self.metalBuffer(instanceBuffer, sceneIndex: i, movieIndex: j),
           structure.drawAdsorptionSurface,
           structure.adsorptionSurfaceRenderingMethod.isTriangulated
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
  
  
  
  // Draws the transparent isosurface of a single structure.
  // Called by MetalRenderer in back-to-front order so overlapping transparent surfaces blend correctly.
  public func renderTransparentIsosurfacesWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, sceneIndex: Int, movieIndex: Int, structureIndex: Int, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, isosurfaceUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, size: CGSize)
  {
    guard let _: RKRenderDataSource = renderDataSource,
          sceneIndex < self.renderStructures.count,
          movieIndex < self.renderStructures[sceneIndex].count,
          let structure: RKRenderVolumetricDataSource = self.renderStructures[sceneIndex][movieIndex] as? RKRenderVolumetricDataSource,
          let isosurfaceVertexBuffer = self.metalBuffer(vertexBuffer, sceneIndex: sceneIndex, movieIndex: movieIndex),
          let instanceIsosurfaceVertexBuffer = self.metalBuffer(instanceBuffer, sceneIndex: sceneIndex, movieIndex: movieIndex),
          structure.drawAdsorptionSurface,
          structure.adsorptionSurfaceRenderingMethod.isTriangulated else {return}
    
    let vertexCount: Int = 3 * structure.adsorptionSurfaceNumberOfTriangles
    guard structure.isVisible && structure.adsorptionSurfaceOpacity<=0.99999 && vertexCount>0 else {return}
    
    commandEncoder.setRenderPipelineState(transparentPipeLine)
    
    // for transparent surface:
    // disable depth-buffer updates (depth-buffer testing is still active)
    // the depth buffer maintains the relationship between opaque and transparent objects,
    // but does not prevent the transparent objects from occluding each other.
    // Correct mutual occlusion is achieved by drawing the structures back-to-front.
    commandEncoder.setDepthStencilState(self.transparentDepthState)
    commandEncoder.setVertexBuffer(isosurfaceVertexBuffer, offset: 0, index: 0)
    commandEncoder.setVertexBuffer(instanceIsosurfaceVertexBuffer, offset: 0, index: 1)
    commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
    commandEncoder.setVertexBuffer(structureUniformBuffers, offset: structureIndex*MemoryLayout<RKStructureUniforms>.stride, index: 3)
    commandEncoder.setVertexBuffer(isosurfaceUniformBuffers, offset: structureIndex*MemoryLayout<RKIsosurfaceUniforms>.stride, index: 4)
    commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 5)
    commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
    commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: structureIndex*MemoryLayout<RKStructureUniforms>.stride, index: 1)
    commandEncoder.setFragmentBuffer(isosurfaceUniformBuffers, offset: structureIndex*MemoryLayout<RKIsosurfaceUniforms>.stride, index: 2)
    commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 3)
    
    commandEncoder.setCullMode(MTLCullMode.front)
    commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: instanceIsosurfaceVertexBuffer.length / MemoryLayout<SIMD4<Float>>.stride)
    
    commandEncoder.setCullMode(MTLCullMode.back)
    commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: instanceIsosurfaceVertexBuffer.length / MemoryLayout<SIMD4<Float>>.stride)
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
      buildVertexBuffers()
      var info: mach_timebase_info_data_t = mach_timebase_info_data_t()
      mach_timebase_info(&info)
      
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j, structure) in structures.enumerated()
        {
          if let structure = structure as? RKRenderVolumetricDataSource, structure.drawAdsorptionSurface
          {
            let dimensions: SIMD3<Int32> = structure.dimensions
            let largestSize: Int = Int(max(dimensions.x,dimensions.y,dimensions.z))
            
            // search for the smallest power of 2 that contains the grid (with a minimum size of 32)
            var gridSizeType: Int = 1
            while(largestSize > Int(pow(2.0,Double(gridSizeType))))
            {
              gridSizeType += 1
            }
            let size = max(16, Int(pow(2.0,Double(gridSizeType))))
            
            func load(cached: [Int: NSCache<AnyObject, AnyObject>], permanent: [Int: NSCache<AnyObject, AnyObject>], compute: () -> [Float], name: String) -> [Float]
            {
              if let cachedVersion: Data = (permanent[size]?.object(forKey: structure) ?? cached[size]?.object(forKey: structure)) as? Data
              {
                var data: [Float] = [Float](repeating: Float(0.0), count: cachedVersion.count / MemoryLayout<Float>.stride)
                let _ = data.withUnsafeMutableBytes { cachedVersion.copyBytes(to: $0, from: 0..<cachedVersion.count) }
                LogQueue.shared.verbose(destination: windowController, message: "Loading the \(structure.displayName)-Metal \(name) from cache")
                return data
              }
              var data: [Float] = compute()
              if !data.isEmpty, let cache: NSCache = structure.isImmutable ? permanent[size] : cached[size]
              {
                let cachedData: Data = data.withUnsafeMutableBufferPointer{Data(buffer: $0)}
                cache.setObject(cachedData as AnyObject, forKey: structure)
              }
              return data
            }
            
            // The well surface and its filament overlay are level sets of the analytic force field; the
            // iso-surface and the volume rendering are level sets and samplings of the energy grid. When
            // the well field is unavailable (imported volumetric data has no analytic form) the iso-surface
            // stands in for it. The geometric surfaces are the union of the probe-inflated atoms, drawn as
            // imposters, and does not use a grid at all.
            let renderingMethod: RKEnergySurfaceType = structure.adsorptionSurfaceRenderingMethod
            if renderingMethod.isGeometricSurface
            {
              vertexBuffer[i][j] = nil
              continue
            }
            var isWellSurface: Bool = renderingMethod == .wellSurface || renderingMethod == .wellSurfaceOverlay
            
            var fieldData: [Float] = []
            if isWellSurface
            {
              fieldData = load(cached: cachedWellFields, permanent: cachedPermanentWellFields, compute: { structure.wellFieldData }, name: "well field")
              if fieldData.isEmpty
              {
                LogQueue.shared.warning(destination: windowController, message: "The well surface is not available for \(structure.displayName); showing the isosurface instead.")
                isWellSurface = false
              }
            }
            
            var data: [Float] = []
            if !isWellSurface
            {
              data = load(cached: cachedAdsorptionSurfaces, permanent: cachedPermanentAdsorptionSurfaces, compute: { structure.gridData }, name: "energy grid")
            }
            
            let startTime: UInt64  = mach_absolute_time()
            
            if !isWellSurface && data.isEmpty
            {
              LogQueue.shared.error(destination: windowController, message: "Energy grid for \(structure.displayName) is empty; no isosurface will be drawn.")
              structure.adsorptionSurfaceNumberOfTriangles = 0
              vertexBuffer[i][j] = nil
            }
            else
            {
              do
              {
                let isOverlay: Bool = isWellSurface && renderingMethod == .wellSurfaceOverlay
                let surfaceName: String = isOverlay ? "Well surface overlay" : (isWellSurface ? "Well surface" : "Isosurface")

                var buffer: MTLBuffer? = nil
                if isOverlay
                {
                  // The merged-well filament: the thin tube along channel axes too narrow for the
                  // probe's contact sheet, where the adsorbate is enclosed and sits on the axis.
                  if let adsorptionStructure = structure as? SKRenderAdsorptionSurfaceStructure
                  {
                    buffer = try SKMetalWellSurface.constructWellFilamentVertexBuffer(device: device, commandQueue: commandQueue, field: fieldData, isovalue: structure.adsorptionSurfaceIsoValue, dimensions: dimensions, unitCell: adsorptionStructure.cell.unitCell)
                  }
                }
                else if isWellSurface
                {
                  buffer = try SKMetalWellSurface.constructWellSurfaceVertexBuffer(device: device, commandQueue: commandQueue, field: fieldData, isovalue: structure.adsorptionSurfaceIsoValue, dimensions: dimensions)

                  if let constructed = buffer, let adsorptionStructure = structure as? SKRenderAdsorptionSurfaceStructure
                  {
                    // Marching cubes puts the vertices on the probe-contact distance surface; the refinement
                    // slides each one along the ray to its nearest atom onto the exact 1D minimum of the
                    // analytic energy --- the true multi-atom well floor.
                    let framework: SKMetalFramework = SKMetalFramework(device: device, commandQueue: commandQueue, positions: adsorptionStructure.atomUnitCellPositions, potentialParameters: adsorptionStructure.potentialParameters, unitCell: adsorptionStructure.cell.unitCell, numberOfReplicas: adsorptionStructure.cell.numberOfReplicas(forCutoff: 12.0), blockingPockets: adsorptionStructure.appliedBlockingPockets)
                    let trimIso: Float = SKMetalWellSurface.effectiveTrimIsovalue(field: fieldData, isovalue: structure.adsorptionSurfaceIsoValue, dimensions: dimensions)
                    framework.RefineWellSurfaceVertexBuffer(vertexBuffer: constructed, probeParameter: structure.adsorptionSurfaceProbeParameters, isovalue: trimIso)
                  }
                }
                else
                {
                  buffer = try SKMetalMarchingCubes.constructIsoSurfaceVertexBuffer(device: device, commandQueue: commandQueue, data: data, isovalue: structure.adsorptionSurfaceIsoValue, dimensions: dimensions)
                }

                if let buffer = buffer
                {
                  vertexBuffer[i][j] = buffer
                  structure.adsorptionSurfaceNumberOfTriangles = buffer.length / (3 * 3 * MemoryLayout<SIMD4<Float>>.stride)
                  if isOverlay
                  {
                    LogQueue.shared.info(destination: windowController, message: "\(surfaceName) for \(structure.displayName): \(structure.adsorptionSurfaceNumberOfTriangles) triangles; where a tightly enclosed adsorbate sits on the channel axis (not monolayer area)")
                  }
                  else if isWellSurface
                  {
                    LogQueue.shared.info(destination: windowController, message: "\(surfaceName) for \(structure.displayName): \(structure.adsorptionSurfaceNumberOfTriangles) triangles; the real monolayer area")
                  }
                  else
                  {
                    LogQueue.shared.info(destination: windowController, message: "\(surfaceName) for \(structure.displayName): \(structure.adsorptionSurfaceNumberOfTriangles) triangles")
                  }
                }
                else
                {
                  vertexBuffer[i][j] = nil
                  structure.adsorptionSurfaceNumberOfTriangles = 0
                  LogQueue.shared.warning(destination: windowController, message: "\(surfaceName) produced 0 triangles for \(structure.displayName) at iso \(structure.adsorptionSurfaceIsoValue) K")
                }
              }
              catch
              {
                LogQueue.shared.error(destination: windowController, message: error.localizedDescription)
              }
            }
            
            let endTime: UInt64  = mach_absolute_time()
            
            let time: Double = Double((endTime - startTime) * UInt64(info.numer)) / Double(info.denom) * 0.000001
            
            LogQueue.shared.verbose(destination: windowController, message: "Time elapsed for creation of \(structure.displayName)-Metal energy surface is \(time) milliseconds")
          }
        }
      }
    }
    completionHandler()
  }
  
}
