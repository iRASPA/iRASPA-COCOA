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

class MetalPolygonalPrismShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  var opaquePipeLine: MTLRenderPipelineState! = nil
  var transparentPipeLine: MTLRenderPipelineState! = nil
  
  var indexBuffers: [[MTLBuffer?]] = []
  var vertexBuffers: [[MTLBuffer?]] = []
  var instanceBuffers: [[MTLBuffer?]] = []
  var samplerState: MTLSamplerState! = nil
  var depthState: MTLDepthStencilState! = nil
  var transparentDepthState: MTLDepthStencilState! = nil
  
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
    
    let pSamplerDescriptor:MTLSamplerDescriptor? = MTLSamplerDescriptor()
    
    if let sampler = pSamplerDescriptor
    {
      sampler.minFilter             = MTLSamplerMinMagFilter.linear
      sampler.magFilter             = MTLSamplerMinMagFilter.linear
      sampler.maxAnisotropy         = 1
      sampler.sAddressMode          = MTLSamplerAddressMode.clampToEdge
      sampler.tAddressMode          = MTLSamplerAddressMode.clampToEdge
      sampler.normalizedCoordinates = true
      sampler.lodMinClamp           = 0
      sampler.lodMaxClamp           = Float.greatestFiniteMagnitude
    }
    else
    {
      print(">> ERROR: Failed creating a sampler descriptor!")
    }
    samplerState = device.makeSamplerState(descriptor: pSamplerDescriptor!)
    
    let opaquePipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    opaquePipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    opaquePipelineDescriptor.vertexFunction = library.makeFunction(name: "PolygonalPrismVertexShader")!
    opaquePipelineDescriptor.sampleCount = maximumNumberOfSamples
    opaquePipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    opaquePipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    opaquePipelineDescriptor.fragmentFunction = library.makeFunction(name: "PolygonalPrismFragmentShader")!
    opaquePipelineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.opaquePipeLine = try device.makeRenderPipelineState(descriptor: opaquePipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }
    
    let transparentPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    transparentPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    transparentPipelineDescriptor.vertexFunction = library.makeFunction(name: "PolygonalPrismVertexShader")!
    transparentPipelineDescriptor.sampleCount = maximumNumberOfSamples
    transparentPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    transparentPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    transparentPipelineDescriptor.fragmentFunction = library.makeFunction(name: "PolygonalPrismFragmentShader")!
    transparentPipelineDescriptor.vertexDescriptor = vertexDescriptor
    transparentPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
    transparentPipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add;
    transparentPipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add;
    transparentPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one;
    transparentPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one;
    transparentPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor =  MTLBlendFactor.oneMinusSourceAlpha;
    transparentPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor =  MTLBlendFactor.oneMinusSourceAlpha;
    do
    {
      self.transparentPipeLine = try device.makeRenderPipelineState(descriptor: transparentPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error) \(device)")
    }
  }
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    if let _: RKRenderDataSource = renderDataSource
    {
      instanceBuffers = []
      indexBuffers = []
      vertexBuffers = []
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = renderStructures[i]
        var sceneInstanceBuffers: [MTLBuffer?] = [MTLBuffer?]()
        var sceneIndexBuffers: [MTLBuffer?] = [MTLBuffer?]()
        var sceneVertexBuffers: [MTLBuffer?] = [MTLBuffer?]()
        
        if structures.isEmpty
        {
          sceneInstanceBuffers.append(nil)
          sceneIndexBuffers.append(nil)
          sceneVertexBuffers.append(nil)
        }
        else
        {
          for structure in structures
          {
            if let structure: RKRenderPolygonalPrimSource = structure as? RKRenderPolygonalPrimSource
            {
              let numberOfSides: Int = structure.primitiveNumberOfSides
              if(structure.primitiveIsCapped)
              {
                let cylinder: MetalCappedNSidedPrismGeometry = MetalCappedNSidedPrismGeometry(r: 1.0, s: numberOfSides)
                
                let vertexBuffer = device.makeBuffer(bytes: cylinder.vertices, length:MemoryLayout<RKVertex>.stride * cylinder.vertices.count, options:.storageModeManaged)
                
                let indexBuffer = device.makeBuffer(bytes: cylinder.indices, length:MemoryLayout<UInt16>.stride * cylinder.indices.count, options:.storageModeManaged)
                
                sceneVertexBuffers.append(vertexBuffer)
                sceneIndexBuffers.append(indexBuffer)
              }
              else
              {
                let cylinder: MetalNSidedPrismGeometry = MetalNSidedPrismGeometry(r: 1.0, s: numberOfSides)
                
                let vertexBuffer = device.makeBuffer(bytes: cylinder.vertices, length:MemoryLayout<RKVertex>.stride * cylinder.vertices.count, options:.storageModeManaged)
                
                let indexBuffer = device.makeBuffer(bytes: cylinder.indices, length:MemoryLayout<UInt16>.stride * cylinder.indices.count, options:.storageModeManaged)
                
                sceneVertexBuffers.append(vertexBuffer)
                sceneIndexBuffers.append(indexBuffer)
              }
              
              let objects: [RKInPerInstanceAttributesAtoms] = structure.renderPolygonalPrismObjects
              
              let instanceBuffer: MTLBuffer? = objects.isEmpty ? nil : device.makeBuffer(bytes: objects, length: MemoryLayout<RKInPerInstanceAttributesAtoms>.stride * objects.count, options:.storageModeManaged)
              
              
              sceneInstanceBuffers.append(instanceBuffer)
            }
            else
            {
              sceneVertexBuffers.append(nil)
              sceneIndexBuffers.append(nil)
              sceneInstanceBuffers.append(nil)
            }
          }
        }
        instanceBuffers.append(sceneInstanceBuffers)
        vertexBuffers.append(sceneVertexBuffers)
        indexBuffers.append(sceneIndexBuffers)
      }
    }
  }
  
  public func renderOpaqueWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, ambientOcclusionTextures: [[MTLTexture]], size: CGSize)
  {
    if (self.renderStructures.joined().compactMap{$0 as? RKRenderPolygonalPrimSource}.reduce(false, {$0 || $1.drawAtoms}))
    {
      commandEncoder.setCullMode(MTLCullMode.none)
      
      commandEncoder.setDepthStencilState(depthState)
      commandEncoder.setRenderPipelineState(opaquePipeLine)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 1)
      commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 2)
      commandEncoder.setFragmentSamplerState(samplerState, index: 0)
      
      var index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderPolygonalPrimSource = structure as? RKRenderPolygonalPrimSource,
            let instanceBuffer: MTLBuffer = self.metalBuffer(instanceBuffers, sceneIndex: i, movieIndex: j),
            let vertexBuffer: MTLBuffer = self.metalBuffer(vertexBuffers, sceneIndex: i, movieIndex: j),
            let indexBuffer: MTLBuffer = self.metalBuffer(indexBuffers, sceneIndex: i, movieIndex: j)
          {
            let numberOfAtoms: Int = instanceBuffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
                        
            if (structure.drawAtoms && structure.isVisible && structure.primitiveOpacity>0.99999 && (numberOfAtoms > 0) )
            {
              commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
              commandEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.setFragmentTexture(ambientOcclusionTextures[i][j], index: 0)
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: numberOfAtoms)
            }
          }
          index = index + 1
        }
      }
    }
  }
  
  public func renderTransparentWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, ambientOcclusionTextures: [[MTLTexture]], size: CGSize)
  {
    if (self.renderStructures.joined().compactMap{$0 as? RKRenderPolygonalPrimSource}.reduce(false, {$0 || $1.drawAtoms}))
    {
      commandEncoder.setDepthStencilState(transparentDepthState)
      commandEncoder.setRenderPipelineState(transparentPipeLine)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 1)
      commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 2)
      commandEncoder.setFragmentSamplerState(samplerState, index: 0)
      
      var index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderPolygonalPrimSource = structure as? RKRenderPolygonalPrimSource,
            let instanceBuffer: MTLBuffer = self.metalBuffer(instanceBuffers, sceneIndex: i, movieIndex: j),
            let vertexBuffer: MTLBuffer = self.metalBuffer(vertexBuffers, sceneIndex: i, movieIndex: j),
            let indexBuffer: MTLBuffer = self.metalBuffer(indexBuffers, sceneIndex: i, movieIndex: j)
          {
            let numberOfAtoms: Int = instanceBuffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
            
            if (structure.drawAtoms && structure.isVisible && structure.primitiveOpacity<=0.99999 && (numberOfAtoms > 0) )
            {
              commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
              commandEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.setFragmentTexture(ambientOcclusionTextures[i][j], index: 0)
              
              commandEncoder.setCullMode(MTLCullMode.front)
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: numberOfAtoms)
              
              commandEncoder.setCullMode(MTLCullMode.back)
              commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: numberOfAtoms)
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
}
