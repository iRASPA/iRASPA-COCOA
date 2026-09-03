/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 J.Vreede@uva.nl      https://www.uva.nl/en/profile/v/r/j.vreede/j.vreede.html
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

/// Draws the blocking pockets of a structure as translucent spheres of the radius they were read with.
///
/// The pockets enclose the atoms and the iso-surface they overlap, so they are drawn in the transparent
/// pass in back-to-front order alongside the iso-surface and the transparent primitives.
class MetalBlockingPocketsShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderObject]] = [[]]
  
  var pipeLine: MTLRenderPipelineState! = nil
  var indexBuffer: MTLBuffer! = nil
  var vertexBuffer: MTLBuffer! = nil
  var instanceBuffer: [[MTLBuffer?]] = []
  var depthState: MTLDepthStencilState! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    // A pocket must not hide the geometry behind it, so it tests against the depth of the opaque pass
    // but does not add itself to it: overlapping pockets then blend rather than occlude each other.
    let depthStateDescriptor: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStateDescriptor.depthCompareFunction = MTLCompareFunction.lessEqual
    depthStateDescriptor.isDepthWriteEnabled = false
    depthState = device.makeDepthStencilState(descriptor: depthStateDescriptor)
    
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "BlockingPocketSphereVertexShader")!
    pipelineDescriptor.sampleCount = maximumNumberOfSamples
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "BlockingPocketSphereFragmentShader")!
    pipelineDescriptor.vertexDescriptor = vertexDescriptor
    pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add
    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
    
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
    let sphere: MetalSphereGeometry = MetalSphereGeometry()
    vertexBuffer = device.makeBuffer(bytes: sphere.vertices, length:MemoryLayout<RKVertex>.stride * sphere.vertices.count, options:RKMetal.hostStorage)
    indexBuffer = device.makeBuffer(bytes: sphere.indices, length:MemoryLayout<UInt16>.stride * sphere.indices.count, options:RKMetal.hostStorage)
    
    if let _: RKRenderDataSource = renderDataSource
    {
      instanceBuffer = []
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = renderStructures[i]
        var sceneInstance: [MTLBuffer?] = [MTLBuffer?]()
        
        if structures.isEmpty
        {
          sceneInstance.append(nil)
        }
        else
        {
          for structure in structures
          {
            let blockingPockets: [RKInPerInstanceAttributesAtoms] = (structure as? RKRenderBlockingPocketsSource)?.renderBlockingPockets ?? []
            
            let buffer = blockingPockets.isEmpty ? nil : device.makeBuffer(bytes: blockingPockets, length: MemoryLayout<RKInPerInstanceAttributesAtoms>.stride * blockingPockets.count, options:RKMetal.hostStorage)
            
            sceneInstance.append(buffer)
          }
        }
        instanceBuffer.append(sceneInstance)
      }
    }
  }
  
  /// Draws the blocking pockets of a single structure. Called by MetalRenderer in back-to-front order so
  /// that pockets of different structures blend in the right order.
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, sceneIndex: Int, movieIndex: Int, structureIndex: Int, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, blockingPocketUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, size: CGSize)
  {
    guard sceneIndex < self.renderStructures.count,
          movieIndex < self.renderStructures[sceneIndex].count,
          let structure: RKRenderBlockingPocketsSource = self.renderStructures[sceneIndex][movieIndex] as? RKRenderBlockingPocketsSource,
          let blockingPocketInstanceBuffer: MTLBuffer = self.metalBuffer(instanceBuffer, sceneIndex: sceneIndex, movieIndex: movieIndex) else {return}
    
    let instanceCount: Int = blockingPocketInstanceBuffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
    guard structure.isVisible && structure.drawBlockingPockets && instanceCount > 0 else {return}
    
    commandEncoder.setDepthStencilState(depthState)
    commandEncoder.setRenderPipelineState(pipeLine)
    commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    commandEncoder.setVertexBuffer(blockingPocketInstanceBuffer, offset: 0, index: 1)
    commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
    commandEncoder.setVertexBuffer(structureUniformBuffers, offset: structureIndex * MemoryLayout<RKStructureUniforms>.stride, index: 3)
    commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
    commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: structureIndex * MemoryLayout<RKStructureUniforms>.stride, index: 0)
    commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 1)
    commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 2)
    commandEncoder.setFragmentBuffer(blockingPocketUniformBuffers, offset: structureIndex * MemoryLayout<RKBlockingPocketUniforms>.stride, index: 3)
    
    // The far wall of a pocket first, so that it blends underneath the near wall.
    commandEncoder.setCullMode(MTLCullMode.front)
    commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
    
    commandEncoder.setCullMode(MTLCullMode.back)
    commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
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
