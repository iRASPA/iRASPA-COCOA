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

class MetalTextShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  var pipeLine: MTLRenderPipelineState! = nil
  var vertexBuffer: MTLBuffer! = nil
  var indexBuffer: MTLBuffer! = nil
  var sampler: MTLSamplerState! = nil
  
  var fontTextures: [String : MTLTexture] = [:]
  var textInstanceBuffer: [[MTLBuffer?]] = []
  var renderTextFontString: [[String]] = [[]]
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let samplerDescriptor: MTLSamplerDescriptor = MTLSamplerDescriptor()
    samplerDescriptor.minFilter = MTLSamplerMinMagFilter.linear
    samplerDescriptor.magFilter = MTLSamplerMinMagFilter.linear
    samplerDescriptor.sAddressMode = MTLSamplerAddressMode.clampToZero
    samplerDescriptor.tAddressMode = MTLSamplerAddressMode.clampToZero
    
    self.sampler = device.makeSamplerState(descriptor: samplerDescriptor)
    
    let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add
    
    pipelineDescriptor.sampleCount = maximumNumberOfSamples
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    pipelineDescriptor.vertexFunction = library.makeFunction(name: "textVertexShader")!
    pipelineDescriptor.fragmentFunction = library.makeFunction(name: "textFragmentShader")!
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
    let quad: MetalQuadGeometry = MetalQuadGeometry()
    vertexBuffer = device.makeBuffer(bytes: quad.vertices, length:MemoryLayout<RKVertex>.stride * quad.vertices.count, options:.storageModeManaged)
    indexBuffer = device.makeBuffer(bytes: quad.indices, length:MemoryLayout<UInt16>.stride * quad.indices.count, options:.storageModeManaged)
    
    if let _: RKRenderDataSource = renderDataSource
    {
      textInstanceBuffer = []
      fontTextures = [:]
      
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = renderStructures[i]
        
        var localTextInstanceBuffer: [MTLBuffer?] = []
        
        for (j,structure) in structures.enumerated()
        {
          if let structure: RKRenderAtomSource = structure  as? RKRenderAtomSource
          {
            let atomData: [RKInPerInstanceAttributesText] = structure.atomTextData
          
            let fontAtlasSize: Int = RKCachedFontAtlas.shared.fontAtlasSize
            let fontAtlas: RKFontAtlas = RKCachedFontAtlas.shared.fontAtlas(for: self.renderTextFontString[i][j])
          
            let textureDesc: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.r8Unorm, width: fontAtlasSize, height: fontAtlasSize, mipmapped: false)
            let region: MTLRegion = MTLRegionMake2D(0, 0, fontAtlasSize, fontAtlasSize)
          
            if let fontTexture = device.makeTexture(descriptor: textureDesc)
            {
              fontTexture.label = "Font Atlas"
              fontTexture.replace(region: region, mipmapLevel: 0, withBytes: fontAtlas.textureData!.bytes, bytesPerRow: fontAtlasSize)
              fontTextures[structure.atomTextFont] = fontTexture
            }
          
          
            let instanceBuffer: MTLBuffer?
            if (atomData.count > 0)
            {
              instanceBuffer = device.makeBuffer(bytes: atomData, length:MemoryLayout<RKInPerInstanceAttributesText>.stride * atomData.count, options:.storageModeManaged)
            }
            else
            {
              instanceBuffer = nil
            }
            localTextInstanceBuffer.append(instanceBuffer)
          }
          else
          {
            localTextInstanceBuffer.append(nil)
          }
            
        }
        
        textInstanceBuffer.append(localTextInstanceBuffer)
      }
    }
  }
  
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, size: CGSize)
  {
    if self.renderStructures.count > 0
    {
      var index = 0
      
      commandEncoder.setRenderPipelineState(pipeLine)
      commandEncoder.setCullMode(MTLCullMode.none)
      
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 4)
      commandEncoder.setFragmentSamplerState(sampler, index: 0)
      commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 2)
      
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 1)
      
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderStructure] = self.renderStructures[i]
        
        for (j,structure) in structures.enumerated()
        {
          if let textInstanceBuffer: MTLBuffer = self.metalBuffer(textInstanceBuffer, sceneIndex: i, movieIndex: j),
            let textVertexBuffer: MTLBuffer = vertexBuffer,
            let fontTexture: MTLTexture = self.fontTextures[renderTextFontString[i][j]]
          {
            commandEncoder.setFragmentTexture(fontTexture, index: 0)
            commandEncoder.setVertexBuffer(textVertexBuffer, offset: 0, index: 0)
            commandEncoder.setVertexBuffer(textInstanceBuffer, offset: 0, index: 1)
            
            let numberOfAtoms: Int = textInstanceBuffer.length/MemoryLayout<RKInPerInstanceAttributesText>.stride
            
            if (structure.isVisible &&  (numberOfAtoms > 0))
            {
              commandEncoder.setVertexBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 3)
              commandEncoder.setFragmentBufferOffset(index * MemoryLayout<RKStructureUniforms>.stride, index: 2)
              
              commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: numberOfAtoms)
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
