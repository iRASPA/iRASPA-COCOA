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

class MetalBlurVerticalShader
{
  var pipeLineState: MTLRenderPipelineState! = nil
  var vertexBuffer: MTLBuffer! = nil
  var indexBuffer: MTLBuffer! = nil
  var quadSamplerState: MTLSamplerState! = nil
  
  var blurVerticalTexture: MTLTexture! = nil
  var blurVerticalRenderPassDescriptor: MTLRenderPassDescriptor! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "blurVerticalVertexShader")!
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.invalid
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "blurFragmentShader")!
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
    quadSamplerState = device.makeSamplerState(descriptor: pSamplerDescriptor!)
    
    let quad: MetalQuadGeometry = MetalQuadGeometry()
    vertexBuffer = device.makeBuffer(bytes: quad.vertices, length:MemoryLayout<RKVertex>.stride * quad.vertices.count, options:.storageModeManaged)
    indexBuffer = device.makeBuffer(bytes: quad.indices, length:MemoryLayout<UInt16>.stride * quad.indices.count, options:.storageModeManaged)
  }
  
  public func buildTextures(device: MTLDevice, size: CGSize, maximumNumberOfSamples: Int)
  {
    let blurVerticalTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.bgra8Unorm, width: max(Int(size.width),1), height: max(Int(size.height),1), mipmapped: false)
    blurVerticalTextureDescriptor.textureType = MTLTextureType.type2D
    blurVerticalTextureDescriptor.storageMode = MTLStorageMode.private
    blurVerticalTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
    blurVerticalTexture = device.makeTexture(descriptor: blurVerticalTextureDescriptor)
    blurVerticalTexture.label = "blur vertical texture"
    
    blurVerticalRenderPassDescriptor = MTLRenderPassDescriptor()
    let blurVerticalColorAttachment: MTLRenderPassColorAttachmentDescriptor = blurVerticalRenderPassDescriptor.colorAttachments[0]
    blurVerticalColorAttachment.texture = blurVerticalTexture
    blurVerticalColorAttachment.loadAction = MTLLoadAction.clear
    blurVerticalColorAttachment.storeAction = MTLStoreAction.store
  }
  
  public func renderWithEncoder(_ commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, texture: MTLTexture,frameUniformBuffer: MTLBuffer, size: CGSize)
  {
    let blurVerticalcommandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
    blurVerticalcommandEncoder.label = "Vertical blur command encoder"
    blurVerticalcommandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
    //blurVerticalcommandEncoder.setDepthStencilState(self.depthState)
    blurVerticalcommandEncoder.setCullMode(MTLCullMode.back)
    blurVerticalcommandEncoder.setFrontFacing(MTLWinding.clockwise)
    
    //blurVerticalcommandEncoder.setRenderPipelineState(self.blurVerticalPipeLine)
    blurVerticalcommandEncoder.setRenderPipelineState(pipeLineState)
    blurVerticalcommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    //blurVerticalcommandEncoder.setFragmentTexture(blurHorizontalTexture, atIndex: 0)
    blurVerticalcommandEncoder.setFragmentTexture(texture, index: 0)
    blurVerticalcommandEncoder.setFragmentSamplerState(quadSamplerState, index: 0)
    blurVerticalcommandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: 4, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    blurVerticalcommandEncoder.endEncoding()
  }
  
}
