//
//  MetalBoundingBoxCylinderShader.swift
//  RenderKit
//
//  Created by David Dubbeldam on 17/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation

class MetalBoundingBoxCylinderShader
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
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "BoundingBoxCylinderVertexShader")!
    pipelineDescriptor.sampleCount = maximumNumberOfSamples
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "BoundingBoxCylinderFragmentShader")!
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
    let boundingBoxCylinder: MetalCylinderGeometry = MetalCylinderGeometry()
    vertexBuffer = device.makeBuffer(bytes: boundingBoxCylinder.vertices, length:MemoryLayout<RKVertex>.stride * boundingBoxCylinder.vertices.count, options:.storageModeManaged)
    indexBuffer = device.makeBuffer(bytes: boundingBoxCylinder.indices, length:MemoryLayout<UInt16>.stride * boundingBoxCylinder.indices.count, options:.storageModeManaged)
    
    if let project: RKRenderDataSource = renderDataSource
    {
      let positions: [RKInPerInstanceAttributesBonds] = project.renderBoundingBoxCylinders
      
      instanceBuffer = positions.isEmpty ? nil : device.makeBuffer(bytes: positions, length: MemoryLayout<RKInPerInstanceAttributesBonds>.stride * positions.count, options:.storageModeManaged)
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
      
      if let boundingBoxCylinderInstanceBuffer = instanceBuffer
      {
        let instanceCount: Int = boundingBoxCylinderInstanceBuffer.length/MemoryLayout<RKInPerInstanceAttributesBonds>.stride
        if (instanceCount > 0)
        {
          commandEncoder.setVertexBuffer(boundingBoxCylinderInstanceBuffer, offset: 0, index: 1)
          commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
        }
      }
    }
  }
  
  
}
