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

class MetalCrystalEllipsoidPrimitiveSelectionWorleyNoise3DShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  var instanceBuffer: [[MTLBuffer?]] = [[]]
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
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "PrimitiveEllipsoidSelectionWorleyNoise3DVertexShader")!
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
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "PrimitiveEllipsoidSelectionWorleyNoise3DFragmentShader")!
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
    let sphere: MetalSphereGeometry = MetalSphereGeometry()
    
    vertexBuffer = device.makeBuffer(bytes: sphere.vertices, length:MemoryLayout<RKVertex>.stride * sphere.vertices.count, options:.storageModeManaged)
    indexBuffer = device.makeBuffer(bytes: sphere.indices, length:MemoryLayout<UInt16>.stride * sphere.indices.count, options:.storageModeManaged)
  }
  
  public func buildInstanceBuffers(device: MTLDevice)
  {
    if let _: RKRenderDataSource = renderDataSource
    {
      instanceBuffer = []
      
      for i in 0..<self.renderStructures.count
      {
        var sceneInstance: [MTLBuffer?] = [MTLBuffer?]()
        let structures: [RKRenderStructure] = renderStructures[i]
        
        for structure in structures
        {
          let atomPositions: [RKInPerInstanceAttributesAtoms] = (structure as? RKRenderCrystalEllipsoidObjectsSource)?.renderSelectedCrystalEllipsoidObjects ?? []
          let buffer: MTLBuffer? = atomPositions.isEmpty ? nil : device.makeBuffer(bytes: atomPositions, length: MemoryLayout<RKInPerInstanceAttributesAtoms>.stride * atomPositions.count, options:.storageModeManaged)
          sceneInstance.append(buffer)
        }
        instanceBuffer.append(sceneInstance)
      }
    }
  }
  
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, size: CGSize)
  {
    
    if (self.renderStructures.joined().compactMap{$0 as? RKRenderCrystalEllipsoidObjectsSource}.reduce(false, {$0 || $1.drawAtoms}))
    {
      commandEncoder.setDepthStencilState(self.transparentDepthState)
      commandEncoder.setCullMode(MTLCullMode.back)
      commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 1)
      commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 2)
      
      var index = 0
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderCrystalEllipsoidObjectsSource = structure as? RKRenderCrystalEllipsoidObjectsSource,
             (structure.primitiveSelectionStyle == .WorleyNoise3D)
          {
            commandEncoder.setRenderPipelineState(pipeLine)
            
            if let instanceBuffer: MTLBuffer = self.metalBuffer(instanceBuffer, sceneIndex: i, movieIndex: j)
            {
              let numberOfAtoms: Int = instanceBuffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
              
              if (structure.drawAtoms && structure.isVisible &&  (numberOfAtoms > 0) )
              {
                commandEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
                commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
                commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
                         
                // draw only the front-faces for the Worley-noise-3D style (looks better)
                commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: numberOfAtoms)
              }
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
