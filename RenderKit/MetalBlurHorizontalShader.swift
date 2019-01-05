//
//  MetalBlurShader.swift
//  RenderKit
//
//  Created by David Dubbeldam on 17/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation

class MetalBlurHorizontalShader
{
  var pipeLineState: MTLRenderPipelineState! = nil
  var vertexBuffer: MTLBuffer! = nil
  var indexBuffer: MTLBuffer! = nil
  var quadSamplerState: MTLSamplerState! = nil
  
  var blurHorizontalRenderPassDescriptor: MTLRenderPassDescriptor! = nil
  var blurHorizontalTexture: MTLTexture! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "blurHorizontalVertexShader")!
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
    let blurHorizontalTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.bgra8Unorm, width: max(Int(size.width),100), height: max(Int(size.height),100), mipmapped: false)
    blurHorizontalTextureDescriptor.textureType = MTLTextureType.type2D
    blurHorizontalTextureDescriptor.storageMode = MTLStorageMode.private
    blurHorizontalTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
    blurHorizontalTexture = device.makeTexture(descriptor: blurHorizontalTextureDescriptor)
    blurHorizontalTexture.label = "blur horizontal texture"
    
    blurHorizontalRenderPassDescriptor = MTLRenderPassDescriptor()
    let blurHorizontalColorAttachment: MTLRenderPassColorAttachmentDescriptor = blurHorizontalRenderPassDescriptor.colorAttachments[0]
    blurHorizontalColorAttachment.texture = blurHorizontalTexture
    blurHorizontalColorAttachment.loadAction = MTLLoadAction.clear
    blurHorizontalColorAttachment.storeAction = MTLStoreAction.store
  }
  
  public func renderWithEncoder(_ commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, texture: MTLTexture,frameUniformBuffer: MTLBuffer, size: CGSize)
  {
    
    let blurHorizontalcommandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
    blurHorizontalcommandEncoder.label = "Horizontal blur command encoder"
    blurHorizontalcommandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
    //blurHorizontalcommandEncoder.setDepthStencilState(self.depthState)
    blurHorizontalcommandEncoder.setCullMode(MTLCullMode.back)
    blurHorizontalcommandEncoder.setFrontFacing(MTLWinding.clockwise)
    
    //blurHorizontalcommandEncoder.setRenderPipelineState(self.blurHorizontalPipeLine)
    blurHorizontalcommandEncoder.setRenderPipelineState(pipeLineState)
    blurHorizontalcommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    //blurHorizontalcommandEncoder.setFragmentTexture(self.atomSelectionGlowResolveTexture, atIndex: 0)
    blurHorizontalcommandEncoder.setFragmentTexture(texture, index: 0)
    blurHorizontalcommandEncoder.setFragmentSamplerState(quadSamplerState, index: 0)
    blurHorizontalcommandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: 4, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    blurHorizontalcommandEncoder.endEncoding()
  }
}
