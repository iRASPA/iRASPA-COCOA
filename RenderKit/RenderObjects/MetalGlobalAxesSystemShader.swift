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

class MetalGlobalAxesSystemShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderStructure]] = [[]]
  
  var axesPipeLine: MTLRenderPipelineState! = nil
  var vertexAxesBuffer: MTLBuffer! = nil
  var indexAxesBuffer: MTLBuffer! = nil
  
  var textPipeLine: MTLRenderPipelineState! = nil
  var vertexTextBuffer: MTLBuffer! = nil
  var indexTextBuffer: MTLBuffer! = nil
  var instanceBuffer: MTLBuffer? = nil
  var samplerState: MTLSamplerState! = nil
  
  var clearDepthState: MTLDepthStencilState! = nil
  var depthState: MTLDepthStencilState! = nil
  
  var backgroundPipeline: MTLRenderPipelineState! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let clearDepthStateDescriptor: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    clearDepthStateDescriptor.depthCompareFunction = MTLCompareFunction.always
    clearDepthStateDescriptor.isDepthWriteEnabled = true
    clearDepthState = device.makeDepthStencilState(descriptor: clearDepthStateDescriptor)
    
    let backgroundPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    backgroundPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    backgroundPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
    backgroundPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one
    backgroundPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
    backgroundPipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add
    backgroundPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one
    backgroundPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
    backgroundPipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add
    backgroundPipelineDescriptor.vertexFunction = library.makeFunction(name: "globalAxesBackgroundQuadVertex")!
    backgroundPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    backgroundPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    backgroundPipelineDescriptor.sampleCount = maximumNumberOfSamples
    backgroundPipelineDescriptor.fragmentFunction = library.makeFunction(name: "globalAxesBackgroundQuadFragment")!
    backgroundPipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    do
    {
      self.backgroundPipeline = try device.makeRenderPipelineState(descriptor: backgroundPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }
    
    let depthStateDescriptor: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStateDescriptor.depthCompareFunction = MTLCompareFunction.lessEqual
    depthStateDescriptor.isDepthWriteEnabled = true
    depthState = device.makeDepthStencilState(descriptor: depthStateDescriptor)
    
    let axesPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    axesPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    axesPipelineDescriptor.vertexFunction = library.makeFunction(name: "GlobalAxesSystemVertexShader")!
    axesPipelineDescriptor.sampleCount = maximumNumberOfSamples
    axesPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    axesPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    axesPipelineDescriptor.fragmentFunction = library.makeFunction(name: "GlobalAxesSystemFragmentShader")!
    axesPipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    do
    {
      self.axesPipeLine = try device.makeRenderPipelineState(descriptor: axesPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error) \(device)")
    }
    
    let textPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    textPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
    textPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
    textPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one
    textPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
    textPipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add
    textPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one
    textPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
    textPipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add
    
    textPipelineDescriptor.sampleCount = maximumNumberOfSamples
    textPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    textPipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
    textPipelineDescriptor.vertexFunction = library.makeFunction(name: "globalAxesTextVertexShader")!
    textPipelineDescriptor.fragmentFunction = library.makeFunction(name: "globalAxesTextFragmentShader")!
    textPipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    do
    {
      self.textPipeLine = try device.makeRenderPipelineState(descriptor: textPipelineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }
  }
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    if let renderDataSource = renderDataSource,
       renderDataSource.renderAxes.position != .none
    {
      let axes: MetalAxesSystemDefaultGeometry = MetalAxesSystemDefaultGeometry(center: renderDataSource.renderAxes.centerType,
                                                                                centerRadius: renderDataSource.renderAxes.centerScale,
                                                                                centerColor: SIMD4<Float>(color: renderDataSource.renderAxes.centerDiffuseColor),
                                                                                arrowHeight: renderDataSource.renderAxes.shaftLength,
                                                                                arrowRadius: renderDataSource.renderAxes.shaftWidth,
                                                                                arrowColorX: SIMD4<Float>(color: renderDataSource.renderAxes.axisXDiffuseColor),
                                                                                arrowColorY: SIMD4<Float>(color: renderDataSource.renderAxes.axisYDiffuseColor),
                                                                                arrowColorZ: SIMD4<Float>(color: renderDataSource.renderAxes.axisZDiffuseColor),
                                                                                tipHeight: renderDataSource.renderAxes.tipLength,
                                                                                tipRadius: renderDataSource.renderAxes.tipWidth,
                                                                                tipColorX: SIMD4<Float>(color: renderDataSource.renderAxes.axisXDiffuseColor),
                                                                                tipColorY: SIMD4<Float>(color: renderDataSource.renderAxes.axisYDiffuseColor),
                                                                                tipColorZ: SIMD4<Float>(color: renderDataSource.renderAxes.axisZDiffuseColor),
                                                                                tipVisibility: renderDataSource.renderAxes.tipVisibility,
                                                                                aspectRatio: renderDataSource.renderAxes.aspectRatio,
                                                                                sectorCount: renderDataSource.renderAxes.NumberOfSectors)
    
      vertexAxesBuffer = device.makeBuffer(bytes: axes.vertices, length:MemoryLayout<RKPrimitiveVertex>.stride * axes.vertices.count, options:.storageModeManaged)
      indexAxesBuffer = device.makeBuffer(bytes: axes.indices, length:MemoryLayout<UInt16>.stride * axes.indices.count, options:.storageModeManaged)
      
      let quad: MetalBackPlaneGeometry  = MetalBackPlaneGeometry()
      vertexTextBuffer = device.makeBuffer(bytes: quad.vertices, length:MemoryLayout<RKVertex>.stride * quad.vertices.count, options:.storageModeManaged)
      indexTextBuffer = device.makeBuffer(bytes: quad.indices, length:MemoryLayout<UInt16>.stride * quad.indices.count, options:.storageModeManaged)
      
      let fontAtlas: RKFontAtlas = RKCachedFontAtlas.shared.fontAtlas(for: "Helvetica")
      let X: [RKInPerInstanceAttributesText] = fontAtlas.buildMeshWithString(position: SIMD4<Float>(1.0,0.0,0.0,1.0), scale: SIMD4<Float>(1.0,1.0,1.0,1.0), text: "X", alignment: RKTextAlignment.center)
      let Y: [RKInPerInstanceAttributesText] = fontAtlas.buildMeshWithString(position: SIMD4<Float>(0.0,1.0,0.0,1.0), scale: SIMD4<Float>(1.0,1.0,1.0,1.0), text: "Y", alignment: RKTextAlignment.center)
      let Z: [RKInPerInstanceAttributesText] = fontAtlas.buildMeshWithString(position: SIMD4<Float>(0.0,0.0,1.0,1.0), scale: SIMD4<Float>(1.0,1.0,1.0,1.0), text: "Z", alignment: RKTextAlignment.center)
      let textData: [RKInPerInstanceAttributesText] = X+Y+Z
      instanceBuffer = device.makeBuffer(bytes: textData, length:MemoryLayout<RKInPerInstanceAttributesText>.stride * 3, options:.storageModeManaged)
      
      let samplerDescriptor: MTLSamplerDescriptor = MTLSamplerDescriptor()
      samplerDescriptor.minFilter = MTLSamplerMinMagFilter.linear
      samplerDescriptor.magFilter = MTLSamplerMinMagFilter.linear
      samplerDescriptor.sAddressMode = MTLSamplerAddressMode.clampToZero
      samplerDescriptor.tAddressMode = MTLSamplerAddressMode.clampToZero
      
      self.samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
    }
  }
  
  
  public func renderWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, lightUniformBuffers: MTLBuffer?, globalAxesUniformBuffers: MTLBuffer?, fontTexture: MTLTexture?, size: CGSize)
  {
    commandEncoder.setCullMode(MTLCullMode.back)
      
    if let renderDataSource = renderDataSource,
       renderDataSource.renderAxes.position != .none
    {
      let minSize: Double = min(Double(size.width),Double(size.height))
    
      switch(renderDataSource.renderAxes.position)
      {
      case .none:
        break
      case .bottomLeft:
        commandEncoder.setViewport(MTLViewport(originX: minSize * renderDataSource.renderAxes.borderOffsetScreenFraction,
                                               originY: Double(size.height) - (minSize * renderDataSource.renderAxes.borderOffsetScreenFraction + minSize * renderDataSource.renderAxes.sizeScreenFraction),
                                               width: minSize * renderDataSource.renderAxes.sizeScreenFraction,
                                               height: minSize * renderDataSource.renderAxes.sizeScreenFraction, znear: 0, zfar: 1))
      case .midLeft:
        commandEncoder.setViewport(MTLViewport(originX: minSize * renderDataSource.renderAxes.borderOffsetScreenFraction,
                                               originY: 0.5*minSize - 0.5*minSize * renderDataSource.renderAxes.sizeScreenFraction,
                                               width: minSize * renderDataSource.renderAxes.sizeScreenFraction,
                                               height: minSize * renderDataSource.renderAxes.sizeScreenFraction, znear: 0, zfar: 1))
      case .topLeft:
        commandEncoder.setViewport(MTLViewport(originX: minSize * renderDataSource.renderAxes.borderOffsetScreenFraction,
                                               originY: minSize * renderDataSource.renderAxes.borderOffsetScreenFraction,
                                               width: minSize * renderDataSource.renderAxes.sizeScreenFraction,
                                               height: minSize * renderDataSource.renderAxes.sizeScreenFraction, znear: 0, zfar: 1))
      case .midTop:
        commandEncoder.setViewport(MTLViewport(originX: 0.5*Double(size.width) - 0.5*minSize * renderDataSource.renderAxes.sizeScreenFraction,
                                               originY: minSize * renderDataSource.renderAxes.borderOffsetScreenFraction,
                                               width: minSize * renderDataSource.renderAxes.sizeScreenFraction,
                                               height: minSize * renderDataSource.renderAxes.sizeScreenFraction, znear: 0, zfar: 1))
      case .topRight:
        commandEncoder.setViewport(MTLViewport(originX: Double(size.width) - (minSize * renderDataSource.renderAxes.borderOffsetScreenFraction + minSize * renderDataSource.renderAxes.sizeScreenFraction),
                                               originY: minSize * renderDataSource.renderAxes.borderOffsetScreenFraction,
                                               width: minSize * renderDataSource.renderAxes.sizeScreenFraction,
                                               height: minSize * renderDataSource.renderAxes.sizeScreenFraction, znear: 0, zfar: 1))
      case .midRight:
        commandEncoder.setViewport(MTLViewport(originX: Double(size.width) - (minSize * renderDataSource.renderAxes.borderOffsetScreenFraction + minSize * renderDataSource.renderAxes.sizeScreenFraction),
                                               originY: 0.5*minSize - 0.5*minSize * renderDataSource.renderAxes.sizeScreenFraction,
                                               width: minSize * renderDataSource.renderAxes.sizeScreenFraction,
                                               height: minSize * renderDataSource.renderAxes.sizeScreenFraction, znear: 0, zfar: 1))
      case .bottomRight:
        commandEncoder.setViewport(MTLViewport(originX: Double(size.width) - (minSize * renderDataSource.renderAxes.borderOffsetScreenFraction + minSize * renderDataSource.renderAxes.sizeScreenFraction),
                                               originY: Double(size.height) - (minSize * renderDataSource.renderAxes.borderOffsetScreenFraction + minSize * renderDataSource.renderAxes.sizeScreenFraction),
                                               width: minSize * renderDataSource.renderAxes.sizeScreenFraction,
                                               height: minSize * renderDataSource.renderAxes.sizeScreenFraction, znear: 0, zfar: 1))
      case .midBottom:
        commandEncoder.setViewport(MTLViewport(originX: 0.5*Double(size.width) - 0.5*minSize * renderDataSource.renderAxes.sizeScreenFraction,
                                               originY: Double(size.height) - (minSize * renderDataSource.renderAxes.borderOffsetScreenFraction + minSize * renderDataSource.renderAxes.sizeScreenFraction),
                                               width: minSize * renderDataSource.renderAxes.sizeScreenFraction,
                                               height: minSize * renderDataSource.renderAxes.sizeScreenFraction, znear: 0, zfar: 1))
      case .center:
        commandEncoder.setViewport(MTLViewport(originX: 0.5*Double(size.width) - 0.5*minSize * renderDataSource.renderAxes.sizeScreenFraction,
                                               originY: 0.5*minSize - 0.5*minSize * renderDataSource.renderAxes.sizeScreenFraction,
                                               width: minSize * renderDataSource.renderAxes.sizeScreenFraction,
                                               height: minSize * renderDataSource.renderAxes.sizeScreenFraction, znear: 0, zfar: 1))
      }
      
      
      commandEncoder.label = "Axes background command encoder"
      commandEncoder.setCullMode(MTLCullMode.none)
      commandEncoder.setRenderPipelineState(self.backgroundPipeline)
      commandEncoder.setDepthStencilState(clearDepthState)
      commandEncoder.setVertexBuffer(vertexTextBuffer, offset: 0, index: 0)
      commandEncoder.setVertexBuffer(globalAxesUniformBuffers, offset: 0, index: 1)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(globalAxesUniformBuffers, offset: 0, index: 1)
      commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
      
      commandEncoder.setRenderPipelineState(axesPipeLine)
      commandEncoder.setDepthStencilState(depthState)
      commandEncoder.setCullMode(MTLCullMode.back)
      commandEncoder.setVertexBuffer(vertexAxesBuffer, offset: 0, index: 0)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1)
      commandEncoder.setVertexBuffer(lightUniformBuffers, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(globalAxesUniformBuffers, offset: 0, index: 3)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 1)
      commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 2)
      
      commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexAxesBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexAxesBuffer, indexBufferOffset: 0)
      
      commandEncoder.setRenderPipelineState(textPipeLine)
      commandEncoder.setCullMode(MTLCullMode.none)
      
      commandEncoder.setVertexBuffer(vertexTextBuffer, offset: 0, index: 0)
      commandEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
      commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
      commandEncoder.setVertexBuffer(globalAxesUniformBuffers, offset: 0, index: 3)
      
      commandEncoder.setFragmentSamplerState(samplerState, index: 0)
      commandEncoder.setFragmentTexture(fontTexture, index: 0)
      commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
      commandEncoder.setFragmentBuffer(globalAxesUniformBuffers, offset: 0, index: 1)
      
      commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 3)
      
      commandEncoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(size.width), height: Double(size.height), znear: 0, zfar: 1))
      
    }
  }
}

