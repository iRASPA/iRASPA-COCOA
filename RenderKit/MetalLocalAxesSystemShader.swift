/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2021 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

class MetalLocalAxesSystemShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  var pipeLine: MTLRenderPipelineState! = nil
  var indexBuffer: MTLBuffer! = nil
  var vertexBuffer: MTLBuffer! = nil
  var instanceBuffer: [[MTLBuffer?]] = [[]]
  var samplerState: MTLSamplerState! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let pSamplerDescriptor:MTLSamplerDescriptor? = MTLSamplerDescriptor();
    
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
    samplerState = device.makeSamplerState(descriptor: pSamplerDescriptor!)
    
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "LocalAxesSystemVertexShader")!
    pipelineDescriptor.sampleCount = maximumNumberOfSamples
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "LocalAxesSystemFragmentShader")!
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
    let sphere: MetalAxesSystemDefaultGeometry = MetalAxesSystemDefaultGeometry(center: .cube, centerRadius: 5.0*0.125, centerColor: SIMD4<Float>(1.0,1.0,0.0,1.0), arrowHeight: 5.0*2.0/3.0, arrowRadius: 5.0*1.0/12.0, arrowColorX: SIMD4<Float>(1.0,0.0,0.0,1.0), arrowColorY: SIMD4<Float>(0.0,1.0,0.0,1.0), arrowColorZ: SIMD4<Float>(0.0,0.0,1.0,1.0), tipHeight: 5.0*1.0/3.0, tipRadius: 5.0*1.0/6.0, tipColorX: SIMD4<Float>(1.0,0.0,0.0,1.0), tipColorY: SIMD4<Float>(0.0,1.0,0.0,1.0), tipColorZ: SIMD4<Float>(0.0,0.0,1.0,1.0), tipVisibility: true, aspectRatio: 1.0, sectorCount: 41)
    
    vertexBuffer = device.makeBuffer(bytes: sphere.vertices, length:MemoryLayout<RKPrimitiveVertex>.stride * sphere.vertices.count, options:.storageModeManaged)
    indexBuffer = device.makeBuffer(bytes: sphere.indices, length:MemoryLayout<UInt16>.stride * sphere.indices.count, options:.storageModeManaged)
  }
  
  
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, ambientOcclusionTextures: [[MTLTexture]], size: CGSize)
  {
    commandEncoder.setCullMode(MTLCullMode.back)
      
    commandEncoder.setRenderPipelineState(pipeLine)
    commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
    commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
    commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
    commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 0)
    commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 1)
    commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 2)
    commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        
    var index = 0
    for i in 0..<self.renderStructures.count
    {
      let structures: [RKRenderStructure] = self.renderStructures[i]
          
      for (j,structure) in structures.enumerated()
      {
        if let structure: RKRenderAtomSource = structure as? RKRenderAtomSource
        {
          if structure.isVisible
          {
            commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 1)
            commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
            commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 0)
            commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
          }
        }
        index = index + 1
      }
    }
  }
}

