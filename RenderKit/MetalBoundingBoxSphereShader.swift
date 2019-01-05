//
//  MetalBoundingBoxShader.swift
//  RenderKit
//
//  Created by David Dubbeldam on 17/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation

class MetalBoundingBoxSphereShader
{
  var renderDataSource: RKRenderDataSource? = nil
  
  var pipeLine: MTLRenderPipelineState! = nil
  var indexBuffer: MTLBuffer! = nil
  var vertexBuffer: MTLBuffer! = nil
  var instanceBuffer: MTLBuffer! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "BoundingBoxSphereVertexShader")!
    pipelineDescriptor.sampleCount = maximumNumberOfSamples
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "BoundingBoxSphereFragmentShader")!
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
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    let boundingBoxSphere: MetalSphereGeometry = MetalSphereGeometry()
    vertexBuffer = device.makeBuffer(bytes: boundingBoxSphere.vertices, length:MemoryLayout<RKVertex>.stride * boundingBoxSphere.vertices.count, options:.storageModeManaged)
    indexBuffer = device.makeBuffer(bytes: boundingBoxSphere.indices, length:MemoryLayout<UInt16>.stride * boundingBoxSphere.indices.count, options:.storageModeManaged)
    
    if let project: RKRenderDataSource = renderDataSource
    {
      let positions: [RKInPerInstanceAttributesAtoms] = project.renderBoundingBoxSpheres
      
      instanceBuffer = positions.isEmpty ? nil : device.makeBuffer(bytes: positions, length: MemoryLayout<RKInPerInstanceAttributesAtoms>.stride * positions.count, options:.storageModeManaged)
    }
  }
  
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, lightUniformBuffers: MTLBuffer?, size: CGSize)
  {
    if let project: RKRenderDataSource = renderDataSource, project.showBoundingBox
    {
      commandEncoder.setRenderPipelineState(pipeLine)
      commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 3)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
      
      if let boundingBoxSphereInstanceBuffer = instanceBuffer
      {
        let instanceCount: Int = boundingBoxSphereInstanceBuffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
        if (instanceCount > 0)
        {
          commandEncoder.setVertexBuffer(boundingBoxSphereInstanceBuffer, offset: 0, index: 1)
          commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
        }
      }
    }
  }
}
