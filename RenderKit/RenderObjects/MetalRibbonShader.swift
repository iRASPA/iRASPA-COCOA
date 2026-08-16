/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import Metal
import SymmetryKit

class MetalRibbonShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderObject]] = [[]]
  
  var pipeLine: MTLRenderPipelineState! = nil
  var vertexBuffer: [[MTLBuffer?]] = []
  var indexBuffer: [[MTLBuffer?]] = []
  var depthState: MTLDepthStencilState! = nil
  var samplerState: MTLSamplerState! = nil
  var aoDebugMode: RibbonAODebugMode = .off
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor, maximumNumberOfSamples: Int)
  {
    let depthStateDesc: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStateDesc.depthCompareFunction = MTLCompareFunction.lessEqual
    depthStateDesc.isDepthWriteEnabled = true
    depthState = device.makeDepthStencilState(descriptor: depthStateDesc)
    
    let pSamplerDescriptor: MTLSamplerDescriptor? = MTLSamplerDescriptor()
    if let sampler = pSamplerDescriptor
    {
      sampler.minFilter = MTLSamplerMinMagFilter.linear
      sampler.magFilter = MTLSamplerMinMagFilter.linear
      sampler.maxAnisotropy = 1
      sampler.sAddressMode = MTLSamplerAddressMode.clampToEdge
      sampler.tAddressMode = MTLSamplerAddressMode.clampToEdge
      sampler.normalizedCoordinates = true
      sampler.lodMinClamp = 0
      sampler.lodMaxClamp = Float.greatestFiniteMagnitude
    }
    samplerState = device.makeSamplerState(descriptor: pSamplerDescriptor!)
    
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "RibbonVertexShader")!
    pipelineDescriptor.sampleCount = maximumNumberOfSamples
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "RibbonFragmentShader")!
    pipelineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.pipeLine = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating ribbon render pipeline state \(error)")
    }
  }
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    vertexBuffer = []
    indexBuffer = []
    if let _: RKRenderDataSource = renderDataSource
    {
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = renderStructures[i]
        var sceneVertexBuffers: [MTLBuffer?] = []
        var sceneIndexBuffers: [MTLBuffer?] = []
        if structures.isEmpty
        {
          sceneVertexBuffers.append(nil)
          sceneIndexBuffers.append(nil)
        }
        else
        {
          for structure in structures
          {
            if let ribbonSource: RKRenderRibbonSource = structure as? RKRenderRibbonSource,
               ribbonSource.drawRibbon,
               !ribbonSource.renderRibbonVertices.isEmpty,
               !ribbonSource.renderRibbonIndices.isEmpty
            {
              let vertices: [RKVertex] = ribbonSource.renderRibbonVertices
              let indices: [UInt32] = ribbonSource.renderRibbonIndices
              let vBuffer: MTLBuffer? = device.makeBuffer(bytes: vertices,
                                                          length: MemoryLayout<RKVertex>.stride * vertices.count,
                                                          options: RKMetal.hostStorage)
              RKMetal.didModify(vBuffer, range: 0..<MemoryLayout<RKVertex>.stride * vertices.count)
              let iBuffer: MTLBuffer? = device.makeBuffer(bytes: indices,
                                                          length: MemoryLayout<UInt32>.stride * indices.count,
                                                          options: RKMetal.hostStorage)
              RKMetal.didModify(iBuffer, range: 0..<MemoryLayout<UInt32>.stride * indices.count)
              sceneVertexBuffers.append(vBuffer)
              sceneIndexBuffers.append(iBuffer)
            }
            else
            {
              sceneVertexBuffers.append(nil)
              sceneIndexBuffers.append(nil)
            }
          }
        }
        vertexBuffer.append(sceneVertexBuffers)
        indexBuffer.append(sceneIndexBuffers)
      }
    }
  }
  
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder,
                                frameUniformBuffer: MTLBuffer,
                                structureUniformBuffers: MTLBuffer?,
                                lightUniformBuffers: MTLBuffer?,
                                ambientOcclusionTextures: [[MTLTexture]],
                                size: CGSize)
  {
    commandEncoder.setDepthStencilState(depthState)
    commandEncoder.setRenderPipelineState(pipeLine)
    commandEncoder.setCullMode(MTLCullMode.none)
    commandEncoder.setFrontFacing(MTLWinding.clockwise)
    commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1)
    commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 2)
    commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 3)
    commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
    commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 1)
    commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 2)
    commandEncoder.setFragmentSamplerState(samplerState, index: 0)
    
    var index: Int = 0
    for i in 0..<self.renderStructures.count
    {
      let structures: [RKRenderObject] = self.renderStructures[i]
      for (j, structure) in structures.enumerated()
      {
        if let ribbonSource: RKRenderRibbonSource = structure as? RKRenderRibbonSource,
           let ribbonVertexBuffer: MTLBuffer = metalBuffer(vertexBuffer, sceneIndex: i, movieIndex: j),
           let ribbonIndexBuffer: MTLBuffer = metalBuffer(indexBuffer, sceneIndex: i, movieIndex: j),
           ribbonSource.drawRibbon,
           ribbonSource.isVisible,
           ribbonSource.ribbonNumberOfIndices > 0
        {
          commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 2)
          commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 1)
          
          if i < ambientOcclusionTextures.count,
             j < ambientOcclusionTextures[i].count
          {
            commandEncoder.setFragmentTexture(ambientOcclusionTextures[i][j], index: 0)
          }
          
          var debugUniforms: RibbonAODebugUniforms = RibbonAODebugUniforms()
          debugUniforms.mode = aoDebugMode.rawValue
          debugUniforms.textureWidth = Int32(ribbonSource.ribbonAmbientOcclusionTextureWidth)
          debugUniforms.textureHeight = Int32(ribbonSource.ribbonAmbientOcclusionTextureHeight)
          debugUniforms.inverseTextureSize = Float(1.0 / Double(max(ribbonSource.ribbonAmbientOcclusionTextureWidth, 1)))
          debugUniforms.viewportWidth = Int32(size.width)
          debugUniforms.viewportHeight = Int32(size.height)
          commandEncoder.setFragmentBytes(&debugUniforms, length: MemoryLayout<RibbonAODebugUniforms>.stride, index: 3)
          
          let drawRanges: [RKRibbonChainDrawRange] = ribbonSource.ribbonDrawRangesForEncoding()
          commandEncoder.setVertexBuffer(ribbonVertexBuffer, offset: 0, index: 0)
          for chainRange in drawRanges
          {
            guard chainRange.indexCount > 0 else {continue}
            commandEncoder.drawIndexedPrimitives(type: .triangle,
                                                 indexCount: chainRange.indexCount,
                                                 indexType: .uint32,
                                                 indexBuffer: ribbonIndexBuffer,
                                                 indexBufferOffset: chainRange.indexStart * MemoryLayout<UInt32>.stride)
          }
        }
        index = index + 1
      }
    }
  }
  
  func metalBuffer(_ buffer: [[MTLBuffer?]], sceneIndex: Int, movieIndex: Int) -> MTLBuffer?
  {
    if sceneIndex < buffer.count, movieIndex < buffer[sceneIndex].count
    {
      return buffer[sceneIndex][movieIndex]
    }
    return nil
  }
}
