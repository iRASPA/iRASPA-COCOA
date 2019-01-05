//
//  MetalAtomSelectionWorleyNoise3DOrthographicImposterShader.swift
//  RenderKit
//
//  Created by David Dubbeldam on 17/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation

class MetalAtomSelectionWorleyNoise3DOrthographicImposterShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  var indexBuffer: MTLBuffer! = nil
  var vertexBuffer: MTLBuffer! = nil
  var pipeLine: MTLRenderPipelineState! = nil
  var transparentDepthState: MTLDepthStencilState! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let transparentDepthStateDescriptor: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    transparentDepthStateDescriptor.depthCompareFunction = MTLCompareFunction.lessEqual
    transparentDepthStateDescriptor.isDepthWriteEnabled = false
    transparentDepthState = device.makeDepthStencilState(descriptor: transparentDepthStateDescriptor)
    
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "AtomSelectionWorleyNoise3DOrthographicVertexShader")!
    pipelineDescriptor.sampleCount = maximumNumberOfSamples
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add;
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add;
    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one;
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one;
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor =  MTLBlendFactor.oneMinusSourceAlpha;
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor =  MTLBlendFactor.oneMinusSourceAlpha;
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "AtomSelectionWorleyNoise3DOrthographicFragmentShader")!
    pipelineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.pipeLine = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error) \(device)")
    }
  }
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    let quad: MetalQuadGeometry = MetalQuadGeometry()
    vertexBuffer = device.makeBuffer(bytes: quad.vertices, length:MemoryLayout<RKVertex>.stride * quad.vertices.count, options:.storageModeManaged)
    indexBuffer = device.makeBuffer(bytes: quad.indices, length:MemoryLayout<UInt16>.stride * quad.indices.count, options:.storageModeManaged)
  }
  
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, instanceBuffer: [[MTLBuffer?]], atomOrthographicImposterShader: MetalAtomOrthographicImposterShader, frameUniformBuffer: MTLBuffer, structureUniformBuffers:MTLBuffer?, lightUniformBuffers: MTLBuffer?, size: CGSize)
  {
    if (self.renderStructures.joined().reduce(false, {$0 || $1.drawAtoms}))
    {
      commandEncoder.setDepthStencilState(self.transparentDepthState)
        
      commandEncoder.setCullMode(MTLCullMode.back)
      commandEncoder.setVertexBuffer(atomOrthographicImposterShader.vertexBuffer, offset: 0, index: 0)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 1)
      commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 2)
          
      var index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
            
        for (j,structure) in structures.enumerated()
        {
          if(structure.renderSelectionStyle == .WorleyNoise3D)
          {
            commandEncoder.setRenderPipelineState(pipeLine)
              
            if let buffer: MTLBuffer = self.metalBuffer(instanceBuffer, sceneIndex: i, movieIndex: j)
            {
              let numberOfAtoms: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
                
              if (structure.renderSelectionStyle != .glow && structure.drawAtoms && structure.isVisible &&  (numberOfAtoms > 0) )
              {
                commandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
                commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
                commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
                  
                commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: atomOrthographicImposterShader.indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: atomOrthographicImposterShader.indexBuffer, indexBufferOffset: 0, instanceCount: numberOfAtoms)
              }
            }
            index = index + 1
          }
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
