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

class MetalPickingShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  var renderPassDescriptor: MTLRenderPassDescriptor! = nil
  var pipeLine: MTLRenderPipelineState! = nil
  var texture: MTLTexture! = nil
  var depthTexture: MTLTexture! = nil
  var depthState: MTLDepthStencilState! = nil
  var samplerState: MTLSamplerState! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let depthStateDesc: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStateDesc.depthCompareFunction = MTLCompareFunction.lessEqual
    depthStateDesc.isDepthWriteEnabled = true
    depthState = device.makeDepthStencilState(descriptor: depthStateDesc)
    
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
    
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba32Uint
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "AtomSpherePickingVertexShader")!
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "AtomSpherePickingFragmentShader")!
    pipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    do
    {
      self.pipeLine = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }
  }
  
  public func buildTextures(device: MTLDevice, size: CGSize, maximumNumberOfSamples: Int)
  {
    let pickingTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba32Uint, width: max(16, Int(size.width)), height: max(16,Int(size.height)), mipmapped: false)
    pickingTextureDescriptor.textureType = MTLTextureType.type2D
    pickingTextureDescriptor.storageMode = MTLStorageMode.managed
    pickingTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
    texture = device.makeTexture(descriptor: pickingTextureDescriptor)
    texture.label = "picking texture"
    
    let pickingDepthTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.depth32Float, width: max(16, Int(size.width)), height: max(16, Int(size.height)), mipmapped: false)
    pickingDepthTextureDescriptor.textureType = MTLTextureType.type2D
    pickingDepthTextureDescriptor.storageMode = MTLStorageMode.private
    pickingDepthTextureDescriptor.usage = MTLTextureUsage.renderTarget
    depthTexture = device.makeTexture(descriptor: pickingDepthTextureDescriptor)
    depthTexture.label = "picking depth texture"
    
    renderPassDescriptor = MTLRenderPassDescriptor()
    let colorAttachment: MTLRenderPassColorAttachmentDescriptor = renderPassDescriptor.colorAttachments[0]
    colorAttachment.texture = texture
    colorAttachment.loadAction = MTLLoadAction.clear
    colorAttachment.storeAction = MTLStoreAction.store
    let depthAttachment: MTLRenderPassDepthAttachmentDescriptor = renderPassDescriptor.depthAttachment
    depthAttachment.texture = depthTexture
    depthAttachment.loadAction = MTLLoadAction.clear
    depthAttachment.clearDepth = 1.0
    depthAttachment.storeAction = MTLStoreAction.store
  }
  
  public func pickTextureAtPoint(device: MTLDevice, _ commandQueue: MTLCommandQueue, point: NSPoint) -> [Int32]
  {
    var data : [Int32] = [0,0,0,0]
    if NSMakeRect(0.0, 0.0, CGFloat(texture.width), CGFloat(texture.height)).contains(point)
    {
      if let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer(),
        let textureBuffer: MTLBuffer = device.makeBuffer(bytes: data, length:MemoryLayout<Int32>.stride * 4, options: .storageModeManaged),
        let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
      {
        blitEncoder.label = "Picking texture blit command encoder"
        blitEncoder.copy(from: texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(Int(point.x),Int(point.y), 0), sourceSize: MTLSizeMake(1, 1, 1), to: textureBuffer, destinationOffset: 0, destinationBytesPerRow: MemoryLayout<Int32>.stride * 4, destinationBytesPerImage: 0)
        blitEncoder.synchronize(resource: textureBuffer)
        blitEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        memcpy(&data, textureBuffer.contents(), textureBuffer.length)
      }
    }
    return data
  }
  
  public func pickDepthTextureAtPoint(device: MTLDevice, _ commandQueue: MTLCommandQueue, point: NSPoint) -> Float?
  {
    var depth: Float = 1.0
    var pick : [Int32] = [0,0,0,0]
    if NSMakeRect(0.0, 0.0, CGFloat(depthTexture.width), CGFloat(depthTexture.height)).contains(point)
    {
      if let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer(),
        let textureBuffer: MTLBuffer = device.makeBuffer(bytes: pick, length: MemoryLayout<Int32>.stride * 4, options: .storageModeManaged),
        let textureBufferDepth: MTLBuffer = device.makeBuffer(bytes: &depth, length:MemoryLayout<Float>.stride, options: .storageModeManaged),
        let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
      {
        blitEncoder.label = "Picking texture blit command encoder"
        blitEncoder.copy(from: texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(Int(point.x),Int(point.y), 0), sourceSize: MTLSizeMake(1, 1, 1), to: textureBuffer, destinationOffset: 0, destinationBytesPerRow: MemoryLayout<Int32>.stride * 4, destinationBytesPerImage: 0)
        
        blitEncoder.label = "Picking texture blit command encoder"
        blitEncoder.copy(from: depthTexture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(Int(point.x),Int(point.y), 0), sourceSize: MTLSizeMake(1, 1, 1), to: textureBufferDepth, destinationOffset: 0, destinationBytesPerRow: MemoryLayout<Float>.stride, destinationBytesPerImage: 0)
        
        blitEncoder.synchronize(resource: textureBuffer)
        blitEncoder.synchronize(resource: textureBufferDepth)
        
        blitEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        memcpy(&pick, textureBuffer.contents(), textureBuffer.length)
        
        if (pick[0] == 1)
        {
          memcpy(&depth, textureBufferDepth.contents(), textureBufferDepth.length)
          return depth
        }
      }
    }
    return nil
  }
  
  public func renderPickingTextureWithEncoder(_ commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, atomShader: MetalAtomShader, atomOrthographicImposterShader: MetalAtomOrthographicImposterShader, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, size: CGSize)
  {
    if let _: RKRenderDataSource = renderDataSource
    {
      let commandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
      commandEncoder.label = "Picking command encoder"
      commandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
      commandEncoder.setDepthStencilState(self.depthState)
      commandEncoder.setCullMode(MTLCullMode.back)
      commandEncoder.setFrontFacing(MTLWinding.clockwise)
      
      
      commandEncoder.setVertexBuffer(atomOrthographicImposterShader.vertexBuffer, offset: 0, index: 0)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 1)
      commandEncoder.setFragmentSamplerState(samplerState, index: 0)
      
      var index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderAtomSource = structure as? RKRenderAtomSource,
             let buffer: MTLBuffer = self.metalBuffer(atomShader.instanceBuffer, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
            if (structure.drawAtoms && structure.isVisible &&  (instanceCount > 0) )
            {
              commandEncoder.setRenderPipelineState(pipeLine)
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
              commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: atomOrthographicImposterShader.indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: atomOrthographicImposterShader.indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
            }
          }
          if let structure: RKRenderBondSource = structure as? RKRenderBondSource,
             let buffer: MTLBuffer = self.metalBuffer(atomShader.instanceBuffer, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
            if let structure: RKRenderAtomSource = structure as? RKRenderAtomSource,
               (!structure.drawAtoms && structure.isVisible &&  (instanceCount > 0) )
            {
              commandEncoder.setRenderPipelineState(pipeLine)
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
              commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: atomOrthographicImposterShader.indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: atomOrthographicImposterShader.indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
            }
          }
          index = index + 1
        }
      }
      
      commandEncoder.endEncoding()
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
