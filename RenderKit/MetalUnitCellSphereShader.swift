//
//  MetalUnitCellSphereShader.swift
//  RenderKit
//
//  Created by David Dubbeldam on 17/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation

class MetalUnitCellSphereShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  var pipeLine: MTLRenderPipelineState! = nil
  var indexBuffer: MTLBuffer! = nil
  var vertexBuffer: MTLBuffer! = nil
  var instanceBuffer: [[MTLBuffer?]] = []
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "UnitCellSphereVertexShader")!
    pipelineDescriptor.sampleCount = maximumNumberOfSamples
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "UnitCellSphereFragmentShader")!
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
    let unitCellSphere: MetalSphereGeometry = MetalSphereGeometry()
    vertexBuffer = device.makeBuffer(bytes: unitCellSphere.vertices, length:MemoryLayout<RKVertex>.stride * unitCellSphere.vertices.count, options:.storageModeManaged)
    indexBuffer = device.makeBuffer(bytes: unitCellSphere.indices, length:MemoryLayout<UInt16>.stride * unitCellSphere.indices.count, options:.storageModeManaged)
    
    if let _: RKRenderDataSource = renderDataSource
    {
      instanceBuffer = []
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = renderStructures[i]
        var sceneInstance: [MTLBuffer?] = [MTLBuffer?]()
        
        if structures.isEmpty
        {
          sceneInstance.append(nil)
        }
        else
        {
          for structure in structures
          {
            let unitCellSpherePositions: [RKInPerInstanceAttributesAtoms] = structure.renderUnitCellSpheres
            
            let buffer = unitCellSpherePositions.isEmpty ? nil : device.makeBuffer(bytes: unitCellSpherePositions, length: MemoryLayout<RKInPerInstanceAttributesAtoms>.stride * unitCellSpherePositions.count, options:.storageModeManaged)
            
            sceneInstance.append(buffer)
          }
        }
        instanceBuffer.append(sceneInstance)
      }
    }
  }
  
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, size: CGSize)
  {
    if (self.renderStructures.joined().reduce(false, {$0 || $1.drawUnitCell}))
    {
      commandEncoder.setRenderPipelineState(pipeLine)
      commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 1)
      
      var index: Int = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let unitCellSphereInstanceBuffer = self.metalBuffer(instanceBuffer, sceneIndex: i, movieIndex: j)
          {
            let instanceCount: Int = unitCellSphereInstanceBuffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
            if (structure.isVisible && structure.drawUnitCell && instanceCount > 0)
            {
              commandEncoder.setVertexBuffer(unitCellSphereInstanceBuffer, offset: 0, index: 1)
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
              commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
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
