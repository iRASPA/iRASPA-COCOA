/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
    let boundingBoxCylinder: MetalBondCylinderGeometry = MetalBondCylinderGeometry()
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
