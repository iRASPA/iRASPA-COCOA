//
//  MetalBlurVerticalShader.swift
//  RenderKit
//
//  Created by David Dubbeldam on 18/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation

class MetalBlurVerticalPictureShader
{
  var pipeLineState: MTLRenderPipelineState! = nil
  var vertexBuffer: MTLBuffer! = nil
  var indexBuffer: MTLBuffer! = nil
  var quadSamplerState: MTLSamplerState! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
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
