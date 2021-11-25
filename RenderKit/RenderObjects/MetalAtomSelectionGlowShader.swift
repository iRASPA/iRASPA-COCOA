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

class MetalAtomSelectionGlowShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderObject]] = [[]]
  
  var atomSelectionGlowRenderPassDescriptor: MTLRenderPassDescriptor! = nil
  var atomSelectionGlowTexture: MTLTexture! = nil
  var atomSelectionGlowResolveTexture: MTLTexture! = nil

  
  var indexBuffer: MTLBuffer! = nil
  var vertexBuffer: MTLBuffer! = nil
  var pipeLineState: MTLRenderPipelineState! = nil
  var depthState: MTLDepthStencilState! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let depthStateDesc: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStateDesc.depthCompareFunction = MTLCompareFunction.lessEqual
    depthStateDesc.isDepthWriteEnabled = true
    depthState = device.makeDepthStencilState(descriptor: depthStateDesc)
    
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "AtomGlowSphereVertexShader")!
    pipelineDescriptor.sampleCount = maximumNumberOfSamples
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "AtomGlowSphereFragmentShader")!
    pipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    do
    {
      self.pipeLineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }
  }
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    let sphere: MetalSphereGeometry = MetalSphereGeometry()
    
    vertexBuffer = device.makeBuffer(bytes: sphere.vertices, length:MemoryLayout<RKVertex>.stride * sphere.vertices.count, options:.storageModeManaged)
    indexBuffer = device.makeBuffer(bytes: sphere.indices, length:MemoryLayout<UInt16>.stride * sphere.indices.count, options:.storageModeManaged)
  }
  
  public func buildTextures(device: MTLDevice, size: CGSize, maximumNumberOfSamples: Int, sceneDepthTexture: MTLTexture)
  {
    let atomSelectionGlowTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.bgra8Unorm, width: max(Int(size.width),1), height: max(Int(size.height),1), mipmapped: false)
    atomSelectionGlowTextureDescriptor.textureType = MTLTextureType.type2DMultisample
    atomSelectionGlowTextureDescriptor.sampleCount = maximumNumberOfSamples
    atomSelectionGlowTextureDescriptor.storageMode = MTLStorageMode.private
    atomSelectionGlowTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
    atomSelectionGlowTexture = device.makeTexture(descriptor: atomSelectionGlowTextureDescriptor)
    atomSelectionGlowTexture.label = "glow atoms texture"
    
    let atomSelectionGlowResolveTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.bgra8Unorm, width: max(Int(size.width),1), height: max(Int(size.height),1), mipmapped: false)
    atomSelectionGlowResolveTextureDescriptor.textureType = MTLTextureType.type2D
    atomSelectionGlowResolveTextureDescriptor.storageMode = MTLStorageMode.private
    atomSelectionGlowResolveTexture = device.makeTexture(descriptor: atomSelectionGlowResolveTextureDescriptor)
    atomSelectionGlowResolveTexture.label = "glow resolved texture"
    
    atomSelectionGlowRenderPassDescriptor = MTLRenderPassDescriptor()
    let glowAtomsColorAttachment: MTLRenderPassColorAttachmentDescriptor = atomSelectionGlowRenderPassDescriptor.colorAttachments[0]
    glowAtomsColorAttachment.texture = atomSelectionGlowTexture
    glowAtomsColorAttachment.loadAction = MTLLoadAction.clear
    glowAtomsColorAttachment.storeAction = MTLStoreAction.store
    glowAtomsColorAttachment.resolveTexture = atomSelectionGlowResolveTexture
    glowAtomsColorAttachment.storeAction = MTLStoreAction.multisampleResolve
    
    let glowAtomsDepthAttachment: MTLRenderPassDepthAttachmentDescriptor = atomSelectionGlowRenderPassDescriptor.depthAttachment
    glowAtomsDepthAttachment.texture = sceneDepthTexture
    glowAtomsDepthAttachment.loadAction = MTLLoadAction.load
    glowAtomsDepthAttachment.storeAction = MTLStoreAction.dontCare
    
    let glowAtomsStencilAttachment: MTLRenderPassStencilAttachmentDescriptor = atomSelectionGlowRenderPassDescriptor.stencilAttachment
    glowAtomsStencilAttachment.texture = sceneDepthTexture
    glowAtomsStencilAttachment.loadAction = MTLLoadAction.clear
    glowAtomsStencilAttachment.storeAction = MTLStoreAction.dontCare
    glowAtomsStencilAttachment.clearStencil = 0
  }
  
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, instanceBuffer: [[MTLBuffer?]], frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?,  size: CGSize)
  {
    if let _: RKRenderDataSource = renderDataSource
    {
      //let commandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: atomSelectionGlowRenderPassDescriptor)!
      commandEncoder.label = "Glow command encoder"
      commandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
      commandEncoder.setDepthStencilState(depthState)
      commandEncoder.setCullMode(MTLCullMode.back)
      commandEncoder.setFrontFacing(MTLWinding.clockwise)
      
      commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 1)
      commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 2)
        
        
      var index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
          
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderAtomSource = structure as? RKRenderAtomSource,
             let buffer: MTLBuffer = self.metalBuffer(instanceBuffer, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
            
            if (structure.atomSelectionStyle == .glow && structure.drawAtoms && structure.isVisible &&  (instanceCount > 0) )
            {
              commandEncoder.setRenderPipelineState(pipeLineState)
              commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
                
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
            }
          }
          index = index + 1
        }
      }
      //commandEncoder.endEncoding()
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
