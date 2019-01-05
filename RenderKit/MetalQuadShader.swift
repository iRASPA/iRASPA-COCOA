//
//  MetalQuadShader.swift
//  RenderKit
//
//  Created by David Dubbeldam on 18/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation

class MetalQuadShader
{
  var quadPipeLine: MTLRenderPipelineState! = nil
  var vertexBuffer: MTLBuffer! = nil
  var indexBuffer: MTLBuffer! = nil
  var quadSamplerState: MTLSamplerState! = nil
  var textureQuad16bitsPipeLine: MTLRenderPipelineState! = nil
  
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
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let quadPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    quadPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
    quadPipelineDescriptor.vertexFunction = library.makeFunction(name: "texturedQuadVertex")!
    quadPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.invalid
    quadPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    quadPipelineDescriptor.fragmentFunction = library.makeFunction(name: "texturedQuadFragment")!
    quadPipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    do
    {
      self.quadPipeLine = try device.makeRenderPipelineState(descriptor: quadPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }
    
    
    let textureQuad16bitsPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    textureQuad16bitsPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Unorm
    textureQuad16bitsPipelineDescriptor.vertexFunction = library.makeFunction(name: "texturedQuadVertex")!
    textureQuad16bitsPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.invalid
    textureQuad16bitsPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    textureQuad16bitsPipelineDescriptor.fragmentFunction = library.makeFunction(name: "texturedQuadFragment")!
    textureQuad16bitsPipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    do
    {
      self.textureQuad16bitsPipeLine = try device.makeRenderPipelineState(descriptor: textureQuad16bitsPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }
    
  }
  
  public func renderWithEncoder(_ commandBuffer: MTLCommandBuffer, renderPass: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, sceneResolveTexture: MTLTexture, blurVerticalTexture: MTLTexture,  size: CGSize)
  {
    let quadCommandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)!
    quadCommandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
    quadCommandEncoder.label = "Quad pass command encoder"
    quadCommandEncoder.setRenderPipelineState(quadPipeLine)
    quadCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    quadCommandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
    quadCommandEncoder.setFragmentTexture(sceneResolveTexture, index: 0)
    quadCommandEncoder.setFragmentTexture(blurVerticalTexture, index: 1)
    //quadCommandEncoder.setFragmentTexture(renderer.ambientOcclusionTextures[0][0], index: 0)
    //quadCommandEncoder.setFragmentTexture(renderer.shadowMapDepthTexture, index: 0)
    quadCommandEncoder.setFragmentSamplerState(quadSamplerState, index: 0)
    quadCommandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: 4, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    quadCommandEncoder.endEncoding()
  }
}
