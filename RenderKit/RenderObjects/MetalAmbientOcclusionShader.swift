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
import SymmetryKit
import simd

class MetalAmbientOcclusionShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderObject]] = [[]]
  
  public let cachedAmbientOcclusionTextures: NSCache<AnyObject, AnyObject> = NSCache()
  
  var shadowMapFrameUniformBuffer: MTLBuffer! = nil
  var shadowMapPipeLine: MTLRenderPipelineState! = nil
  var ribbonShadowMapPipeLine: MTLRenderPipelineState! = nil
  var ambientOcclusionPipeLine: MTLRenderPipelineState! = nil
  var ribbonAmbientOcclusionPipeLine: MTLRenderPipelineState! = nil
  var ribbonAOBlurHorizontalPipeLine: MTLRenderPipelineState! = nil
  var ribbonAOBlurVerticalPipeLine: MTLRenderPipelineState! = nil
  var ribbonAOBlurVertexBuffer: MTLBuffer! = nil
  var ribbonAOBlurIndexBuffer: MTLBuffer! = nil
  public var textures: [[MTLTexture]] = []
  public var ribbonTextures: [[MTLTexture]] = []
  var depthTexture: MTLTexture! = nil
  var depthState: MTLDepthStencilState! = nil
  var quadSamplerState:  MTLSamplerState! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor,  maximumNumberOfSamples: Int)
  {
    let depthStateDesc: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStateDesc.depthCompareFunction = MTLCompareFunction.lessEqual
    depthStateDesc.isDepthWriteEnabled = true
    depthState = device.makeDepthStencilState(descriptor: depthStateDesc)
    
    let pSamplerDescriptor:MTLSamplerDescriptor? = MTLSamplerDescriptor()
    
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
    quadSamplerState = device.makeSamplerState(descriptor: pSamplerDescriptor!)
    
    let shadowMapPipeLineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    shadowMapPipeLineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float
    shadowMapPipeLineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    shadowMapPipeLineDescriptor.colorAttachments[0] = nil
    shadowMapPipeLineDescriptor.vertexFunction = library.makeFunction(name: "AtomShadowMapVertexShader")!
    shadowMapPipeLineDescriptor.fragmentFunction = library.makeFunction(name: "AtomShadowMapFragmentShader")!
    shadowMapPipeLineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.shadowMapPipeLine = try device.makeRenderPipelineState(descriptor: shadowMapPipeLineDescriptor)
      
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }
    
    let ribbonShadowMapPipeLineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    ribbonShadowMapPipeLineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float
    ribbonShadowMapPipeLineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    ribbonShadowMapPipeLineDescriptor.colorAttachments[0] = nil
    ribbonShadowMapPipeLineDescriptor.vertexFunction = library.makeFunction(name: "RibbonShadowMapVertexShader")!
    ribbonShadowMapPipeLineDescriptor.fragmentFunction = library.makeFunction(name: "RibbonShadowMapFragmentShader")!
    ribbonShadowMapPipeLineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.ribbonShadowMapPipeLine = try device.makeRenderPipelineState(descriptor: ribbonShadowMapPipeLineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating ribbon shadow map pipeline state \(error)")
    }
    
    
    
    let ambientOcclusionPipeLineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    ambientOcclusionPipeLineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.invalid
    ambientOcclusionPipeLineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    ambientOcclusionPipeLineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.r16Float
    ambientOcclusionPipeLineDescriptor.colorAttachments[0].isBlendingEnabled = true
    ambientOcclusionPipeLineDescriptor.colorAttachments[0].writeMask = MTLColorWriteMask.red
    ambientOcclusionPipeLineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add
    ambientOcclusionPipeLineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one
    ambientOcclusionPipeLineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one
    ambientOcclusionPipeLineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.one
    ambientOcclusionPipeLineDescriptor.vertexFunction = library.makeFunction(name: "AmbientOcclusionVertexShader")!
    ambientOcclusionPipeLineDescriptor.fragmentFunction = library.makeFunction(name: "AmbientOcclusionFragmentShader")!
    ambientOcclusionPipeLineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.ambientOcclusionPipeLine = try device.makeRenderPipelineState(descriptor: ambientOcclusionPipeLineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating render pipeline state \(error)")
    }
    
    let ribbonAmbientOcclusionPipeLineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    ribbonAmbientOcclusionPipeLineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.invalid
    ribbonAmbientOcclusionPipeLineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    ribbonAmbientOcclusionPipeLineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.r16Float
    ribbonAmbientOcclusionPipeLineDescriptor.colorAttachments[0].isBlendingEnabled = true
    ribbonAmbientOcclusionPipeLineDescriptor.colorAttachments[0].writeMask = MTLColorWriteMask.red
    ribbonAmbientOcclusionPipeLineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add
    ribbonAmbientOcclusionPipeLineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one
    ribbonAmbientOcclusionPipeLineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one
    ribbonAmbientOcclusionPipeLineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.one
    ribbonAmbientOcclusionPipeLineDescriptor.vertexFunction = library.makeFunction(name: "RibbonAmbientOcclusionVertexShader")!
    ribbonAmbientOcclusionPipeLineDescriptor.fragmentFunction = library.makeFunction(name: "RibbonAmbientOcclusionFragmentShader")!
    ribbonAmbientOcclusionPipeLineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.ribbonAmbientOcclusionPipeLine = try device.makeRenderPipelineState(descriptor: ribbonAmbientOcclusionPipeLineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating ribbon ambient occlusion pipeline state \(error)")
    }
    
    let ribbonAOBlurHorizontalPipeLineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    ribbonAOBlurHorizontalPipeLineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.invalid
    ribbonAOBlurHorizontalPipeLineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    ribbonAOBlurHorizontalPipeLineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.r16Float
    ribbonAOBlurHorizontalPipeLineDescriptor.vertexFunction = library.makeFunction(name: "ribbonAOBlurVertexShader")!
    ribbonAOBlurHorizontalPipeLineDescriptor.fragmentFunction = library.makeFunction(name: "ribbonAOBlurHorizontalFragmentShader")!
    ribbonAOBlurHorizontalPipeLineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.ribbonAOBlurHorizontalPipeLine = try device.makeRenderPipelineState(descriptor: ribbonAOBlurHorizontalPipeLineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating ribbon AO blur pipeline state \(error)")
    }
    
    let ribbonAOBlurVerticalPipeLineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
    ribbonAOBlurVerticalPipeLineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.invalid
    ribbonAOBlurVerticalPipeLineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.invalid
    ribbonAOBlurVerticalPipeLineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.r16Float
    ribbonAOBlurVerticalPipeLineDescriptor.vertexFunction = library.makeFunction(name: "ribbonAOBlurVertexShader")!
    ribbonAOBlurVerticalPipeLineDescriptor.fragmentFunction = library.makeFunction(name: "ribbonAOBlurVerticalFragmentShader")!
    ribbonAOBlurVerticalPipeLineDescriptor.vertexDescriptor = vertexDescriptor
    do
    {
      self.ribbonAOBlurVerticalPipeLine = try device.makeRenderPipelineState(descriptor: ribbonAOBlurVerticalPipeLineDescriptor)
    }
    catch
    {
      fatalError("Error occurred when creating ribbon AO vertical blur pipeline state \(error)")
    }
    
    let quad: MetalQuadGeometry = MetalQuadGeometry()
    ribbonAOBlurVertexBuffer = device.makeBuffer(bytes: quad.vertices, length: MemoryLayout<RKVertex>.stride * quad.vertices.count, options: RKMetal.hostStorage)
    ribbonAOBlurIndexBuffer = device.makeBuffer(bytes: quad.indices, length: MemoryLayout<UInt16>.stride * quad.indices.count, options: RKMetal.hostStorage)

  }
  
  public func adjustAmbientOcclusionTextureSize()
  {
    let maxSize: Int = 16384
    
    
    if let _: RKRenderDataSource = renderDataSource
    {
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        for structure in structures
        {
          if let structure: RKRenderAtomSource = structure as? RKRenderAtomSource
          {
            let numberOfAtoms: Int = structure.renderAtoms.count
            structure.atomAmbientOcclusionTextureSize = RKAmbientOcclusionSizing.maxTextureSize(numberOfAtoms: numberOfAtoms,
                                                                                                maxTextureDimension: maxSize)
            structure.atomAmbientOcclusionPatchNumber = Int(sqrt(Double(numberOfAtoms)))+1
            structure.atomAmbientOcclusionPatchSize = structure.atomAmbientOcclusionTextureSize/structure.atomAmbientOcclusionPatchNumber
          }
          
          if let ribbonSource: RKRenderRibbonSource = structure as? RKRenderRibbonSource,
             ribbonSource.drawRibbon,
             ribbonSource.ribbonNumberOfChains > 0
          {
            let numberOfAtoms: Int = (structure as? RKRenderAtomSource)?.renderAtoms.count ?? ribbonSource.ribbonResidueDrawRanges.count
            let atlasDimensions: (width: Int, height: Int, stripHeight: Int) = RKRibbonMesh.ambientOcclusionAtlasDimensions(
              maxSplineSampleCount: ribbonSource.ribbonMaxSplineSampleCount,
              numberOfChains: ribbonSource.ribbonNumberOfChains,
              numberOfAtoms: numberOfAtoms,
              maxTextureDimension: Int(maxSize))
            ribbonSource.ribbonAmbientOcclusionTextureWidth = atlasDimensions.width
            ribbonSource.ribbonAmbientOcclusionTextureHeight = atlasDimensions.height
            ribbonSource.ribbonAmbientOcclusionStripHeight = atlasDimensions.stripHeight
            ribbonSource.ribbonAmbientOcclusionTextureSize = max(atlasDimensions.width, atlasDimensions.height)
            ribbonSource.ribbonAmbientOcclusionPatchNumber = 1
            ribbonSource.ribbonAmbientOcclusionPatchSize = atlasDimensions.width
          }
        }
      }
    }
  }
  
  public func buildAmbientOcclusionTextures(device: MTLDevice)
  {
    adjustAmbientOcclusionTextureSize()
    
    self.textures = []
    self.ribbonTextures = []
    if let _: RKRenderDataSource = renderDataSource
    {
      for i in 0..<self.renderStructures.count
      {
        var localTextures: [MTLTexture] = []
        var localRibbonTextures: [MTLTexture] = []
        let structures: [RKRenderObject] = self.renderStructures[i]
        for structure in structures
        {
          let textureSize: Int = (structure as? RKRenderAtomSource)?.atomAmbientOcclusionTextureSize ?? 1
          let ambientOcclusionTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.r16Float, width: textureSize, height: textureSize,   mipmapped: false)
          ambientOcclusionTextureDescriptor.textureType = MTLTextureType.type2D
          ambientOcclusionTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
          ambientOcclusionTextureDescriptor.storageMode = RKMetal.hostStorageMode
          localTextures.append(device.makeTexture(descriptor: ambientOcclusionTextureDescriptor)!)
          
          let ribbonTextureWidth: Int = (structure as? RKRenderRibbonSource)?.ribbonAmbientOcclusionTextureWidth ?? 1
          let ribbonTextureHeight: Int = (structure as? RKRenderRibbonSource)?.ribbonAmbientOcclusionTextureHeight ?? ribbonTextureWidth
          let ribbonTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.r16Float, width: ribbonTextureWidth, height: ribbonTextureHeight, mipmapped: false)
          ribbonTextureDescriptor.textureType = MTLTextureType.type2D
          ribbonTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
          ribbonTextureDescriptor.storageMode = RKMetal.hostStorageMode
          localRibbonTextures.append(device.makeTexture(descriptor: ribbonTextureDescriptor)!)
        }
        self.textures.append(localTextures)
        self.ribbonTextures.append(localRibbonTextures)
      }
    }
  }
  
  public func updateAmbientOcclusionTextures(device: MTLDevice, _ commandQueue: MTLCommandQueue, quality: RKRenderQuality,
                                             atomShader: MetalAtomShader, atomOrthographicImposterShader: MetalAtomOrthographicImposterShader,
                                             ribbonShader: MetalRibbonShader)
  {
    buildAmbientOcclusionTextures(device: device)
    atomShader.buildVertexBuffers(device: device)
    ribbonShader.buildVertexBuffers(device: device)
    
    if let crystalProjectData: RKRenderDataSource = renderDataSource
    {
      var structureAmbientOcclusionUniformBuffers: MTLBuffer! = nil
      
      let shadowMapDepthTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.depth32Float, width: 2048, height: 2048, mipmapped: false)
      shadowMapDepthTextureDescriptor.textureType = MTLTextureType.type2D
      shadowMapDepthTextureDescriptor.storageMode = MTLStorageMode.private
      shadowMapDepthTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
      depthTexture = device.makeTexture(descriptor: shadowMapDepthTextureDescriptor)
      
      let shadowMapPassDescriptor = MTLRenderPassDescriptor()
      let shadowMapPassDepthAttachment: MTLRenderPassDepthAttachmentDescriptor = shadowMapPassDescriptor.depthAttachment
      shadowMapPassDepthAttachment.texture = depthTexture
      shadowMapPassDepthAttachment.loadAction = MTLLoadAction.clear
      shadowMapPassDepthAttachment.clearDepth = 1.0
      shadowMapPassDepthAttachment.storeAction = MTLStoreAction.store
      
      for i in 0..<self.renderStructures.count
      {
        let structures: [RKRenderObject] = self.renderStructures[i]
        
        for (j, structure) in structures.enumerated()
        {
          let modelMatrix: double4x4 = double4x4(transformation: double4x4(simd_quatd: structure.orientation), aroundPoint: structure.cell.boundingBox.center, withTranslation:  SIMD3<Double>(0.0, 0.0, 0.0))
          
          var structureUniforms: [RKStructureUniforms] = [RKStructureUniforms](repeating: RKStructureUniforms(), count: max(structures.count,1))
          
          for (k,structure) in structures.enumerated()
          {
            // FIX/CHECK
            structureUniforms[k] = RKStructureUniforms(structureIdentifier: i, structure: structure, inverseModelMatrix: modelMatrix.inverse)
          }
          
          structureAmbientOcclusionUniformBuffers = device.makeBuffer(bytes: structureUniforms, length: MemoryLayout<RKStructureUniforms>.stride * max(structures.count,1), options:RKMetal.hostStorage)
          RKMetal.didModify(structureAmbientOcclusionUniformBuffers, range: 0..<MemoryLayout<RKStructureUniforms>.stride * max(structures.count,1))
          
          let atomSourceForAO: RKRenderAtomSource? = structure as? RKRenderAtomSource
          let ribbonSourceForAO: RKRenderRibbonSource? = structure as? RKRenderRibbonSource
          let shouldBakeAtomAO: Bool = {
            guard let atomSource: RKRenderAtomSource = atomSourceForAO else {return false}
            return atomSource.drawAtoms &&
                   atomSource.atomAmbientOcclusion &&
                   structure.isVisible
          }()
          let shouldBakeRibbonAO: Bool = {
            guard let ribbonSource: RKRenderRibbonSource = ribbonSourceForAO else {return false}
            return ribbonSource.drawRibbon &&
                   ribbonSource.ribbonAmbientOcclusion &&
                   structure.isVisible &&
                   ribbonSource.ribbonNumberOfChains > 0
          }()
          
          if shouldBakeAtomAO || shouldBakeRibbonAO
          {
            let textureSize: Int = atomSourceForAO?.atomAmbientOcclusionTextureSize ?? 256
            
            if shouldBakeAtomAO,
               let cachedVersion: Data = cachedAmbientOcclusionTextures.object(forKey: structure) as? Data
            {
              let region: MTLRegion = MTLRegionMake2D(0, 0, textureSize, textureSize)
              let ambientOcclusiontexture: MTLTexture = self.textures[i][j]
              
              cachedVersion.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> () in
                ambientOcclusiontexture.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: ptr.baseAddress!, bytesPerRow: 2 * region.size.width, bytesPerImage: 2 * region.size.width * region.size.height)
              }
            }
            
            let needFreshAtomBake: Bool = shouldBakeAtomAO && cachedAmbientOcclusionTextures.object(forKey: structure) == nil
            let needFreshRibbonBake: Bool = shouldBakeRibbonAO && cachedAmbientOcclusionTextures.object(forKey: structure.ribbonAmbientOcclusionCacheKey) == nil
            
            if needFreshAtomBake || needFreshRibbonBake
            {
              var ribbonRenderStructureUniformBuffers: MTLBuffer? = nil
              var ribbonBakeDrewGeometry: Bool = false
              var ribbonAmbientOcclusionPassDescriptor: MTLRenderPassDescriptor? = nil
              var ribbonAmbientOcclusionBlendPassDescriptor: MTLRenderPassDescriptor? = nil
              var ribbonTextureWidth: Int = 0
              var ribbonTextureHeight: Int = 0
              var ribbonCanBake: Bool = false
              if needFreshRibbonBake, let ribbonSource: RKRenderRibbonSource = ribbonSourceForAO
              {
                ribbonTextureWidth = ribbonSource.ribbonAmbientOcclusionTextureWidth
                ribbonTextureHeight = ribbonSource.ribbonAmbientOcclusionTextureHeight
                ribbonCanBake = ribbonShader.metalBuffer(ribbonShader.vertexBuffer, sceneIndex: i, movieIndex: j) != nil &&
                                ribbonShader.metalBuffer(ribbonShader.indexBuffer, sceneIndex: i, movieIndex: j) != nil &&
                                ribbonSource.ribbonNumberOfIndices > 0
                
                if ribbonCanBake
                {
                  var ribbonRenderUniforms: [RKStructureUniforms] = [RKStructureUniforms](repeating: RKStructureUniforms(), count: max(structures.count, 1))
                  for (k, sceneStructure) in structures.enumerated()
                  {
                    ribbonRenderUniforms[k] = RKStructureUniforms(structureIdentifier: i, structure: sceneStructure)
                  }
                  ribbonRenderStructureUniformBuffers = device.makeBuffer(bytes: ribbonRenderUniforms, length: MemoryLayout<RKStructureUniforms>.stride * max(structures.count, 1), options: RKMetal.hostStorage)
                  RKMetal.didModify(ribbonRenderStructureUniformBuffers, range: 0..<MemoryLayout<RKStructureUniforms>.stride * max(structures.count, 1))
                  
                  ribbonAmbientOcclusionPassDescriptor = MTLRenderPassDescriptor()
                  ribbonAmbientOcclusionPassDescriptor!.colorAttachments[0].texture = ribbonTextures[i][j]
                  ribbonAmbientOcclusionPassDescriptor!.colorAttachments[0].loadAction = MTLLoadAction.clear
                  ribbonAmbientOcclusionPassDescriptor!.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
                  ribbonAmbientOcclusionPassDescriptor!.colorAttachments[0].storeAction = MTLStoreAction.store
                  
                  ribbonAmbientOcclusionBlendPassDescriptor = MTLRenderPassDescriptor()
                  ribbonAmbientOcclusionBlendPassDescriptor!.colorAttachments[0].texture = ribbonTextures[i][j]
                  ribbonAmbientOcclusionBlendPassDescriptor!.colorAttachments[0].loadAction = MTLLoadAction.load
                  ribbonAmbientOcclusionBlendPassDescriptor!.colorAttachments[0].storeAction = MTLStoreAction.store
                }
              }
              
              let ambientOcclusionPassDescriptor = MTLRenderPassDescriptor()
              let ambientOcclusionPassColorAttachment: MTLRenderPassColorAttachmentDescriptor = ambientOcclusionPassDescriptor.colorAttachments[0]
              ambientOcclusionPassColorAttachment.texture = textures[i][j]
              ambientOcclusionPassColorAttachment.loadAction = MTLLoadAction.clear
              ambientOcclusionPassColorAttachment.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
              ambientOcclusionPassColorAttachment.storeAction = MTLStoreAction.store
              
              let ambientOcclusionBlendPassDescriptor = MTLRenderPassDescriptor()
              let ambientOcclusionBlendPassColorAttachment: MTLRenderPassColorAttachmentDescriptor = ambientOcclusionBlendPassDescriptor.colorAttachments[0]
              ambientOcclusionBlendPassColorAttachment.texture = textures[i][j]
              ambientOcclusionBlendPassColorAttachment.loadAction = MTLLoadAction.load
              ambientOcclusionBlendPassColorAttachment.storeAction = MTLStoreAction.store
              
              var directions: [simd_quatd] = []
              var weights: [Float] = []
              
              if quality == .picture
              {
                directions = simd_quatd.Data1992
                weights = simd_quatd.Weights1992.map{Float(4.0*$0/1992.0)}
              }
              else
              {
                directions = simd_quatd.Data300 + simd_quatd.Data60
                weights = Array<Float>(repeating: 4.0*0.93426/360.0, count: 300) + Array<Float>(repeating: 4.0*1.32870/360.0, count: 60)
              }
              
              var shadowMapFrameUniformsArray: [RKShadowUniforms] = [RKShadowUniforms](repeating: RKShadowUniforms(), count: directions.count)
              
              if let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
              {
                if needFreshAtomBake
                {
                  let ambientOcclusionBlendCommandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: ambientOcclusionPassDescriptor)!
                  ambientOcclusionBlendCommandEncoder.endEncoding()
                }
                if needFreshRibbonBake, let ribbonClearPass: MTLRenderPassDescriptor = ribbonAmbientOcclusionPassDescriptor
                {
                  let ribbonClearEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: ribbonClearPass)!
                  ribbonClearEncoder.endEncoding()
                }
                commandBuffer.commit()
              }
              
              let boundingBox: SKBoundingBox = crystalProjectData.renderBoundingBox
              let largestRadius: Double = boundingBox.boundingSphereRadius
              let centerOfScene = boundingBox.minimum + (boundingBox.maximum - boundingBox.minimum) * 0.5
              let eye = SIMD3<Double>(x: centerOfScene.x, y: centerOfScene.y, z: centerOfScene.z + largestRadius)
              
              let boundingBoxAspectRatio: Double = fabs(boundingBox.maximum.x - boundingBox.minimum.x) / abs(boundingBox.maximum.y - boundingBox.minimum.y)
              
              let left,right,top,bottom: Double
              if (boundingBoxAspectRatio < 1.0)
              {
                left =  -largestRadius/boundingBoxAspectRatio;
                right = largestRadius/boundingBoxAspectRatio;
                top = largestRadius/boundingBoxAspectRatio;
                bottom = -largestRadius/boundingBoxAspectRatio;
              }
              else
              {
                left = -largestRadius;
                right = largestRadius;
                top = largestRadius;
                bottom = -largestRadius;
              }
              
              let near: Double = 1.0
              let far: Double = 1000.0
              
              srand48(0)
              
              let ribbonUsesRenderUniformsForShadow: Bool = needFreshRibbonBake && !(atomSourceForAO?.drawAtoms ?? false)
              
              for k in 0..<directions.count
              {
                let smallChangeQ: simd_quatd = simd_quatd.smallRandomQuaternion(angleRange: 0.5*10.0*Double.pi/180.0)
                let q: simd_quatd = smallChangeQ * directions[k]
                
                let modelMatrix: double4x4 = double4x4(transformation: double4x4(simd_quatd: q), aroundPoint: centerOfScene)
                let viewMatrix: double4x4 = RKCamera.GluLookAt(eye: eye, center: centerOfScene, up: SIMD3<Double>(x: 0, y: 1, z:0))
                let projectionMatrix: double4x4 = double4x4.glFrustumfOrthographic(left, right: right, bottom: bottom, top: top, near: near, far: far)
                
                let shadowMapFrameUniforms: RKShadowUniforms = RKShadowUniforms(projectionMatrix: projectionMatrix, viewMatrix:  viewMatrix, modelMatrix: modelMatrix)
                shadowMapFrameUniformsArray[k] = shadowMapFrameUniforms
              }
              shadowMapFrameUniformBuffer = device.makeBuffer(bytes: &shadowMapFrameUniformsArray, length:MemoryLayout<RKShadowUniforms>.stride * shadowMapFrameUniformsArray.count, options:RKMetal.hostStorage)
              RKMetal.didModify(shadowMapFrameUniformBuffer, range: 0..<MemoryLayout<RKShadowUniforms>.stride * shadowMapFrameUniformsArray.count)
              
              if let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
              {
                for k in 0..<directions.count
                {
                  let shadowMapCommandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: shadowMapPassDescriptor)!
                  shadowMapCommandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(2048), height: Double(2048), znear: 0.0, zfar: 1.0))
                  shadowMapCommandEncoder.setDepthStencilState(self.depthState)
                  shadowMapCommandEncoder.setCullMode(MTLCullMode.back)
                  shadowMapCommandEncoder.setFrontFacing(MTLWinding.clockwise)
                  shadowMapCommandEncoder.setRenderPipelineState(self.shadowMapPipeLine)
                  
                  for (l, structure) in structures.enumerated()
                  {
                    guard structure.isVisible else {continue}
                    drawAtomShadowMapInstances(shadowMapCommandEncoder,
                                               sceneIndex: i,
                                               structureIndex: l,
                                               structureUniformBuffers: structureAmbientOcclusionUniformBuffers,
                                               structureUniformOffset: l * MemoryLayout<RKStructureUniforms>.stride,
                                               shadowUniformOffset: k * MemoryLayout<RKShadowUniforms>.stride,
                                               includeHiddenAtomsForRibbonOcclusion: needFreshRibbonBake && (atomSourceForAO?.drawAtoms ?? false),
                                               atomShader: atomShader,
                                               atomOrthographicImposterShader: atomOrthographicImposterShader)
                    if needFreshRibbonBake
                    {
                      let ribbonShadowUniformBuffers: MTLBuffer = (ribbonUsesRenderUniformsForShadow && ribbonRenderStructureUniformBuffers != nil)
                        ? ribbonRenderStructureUniformBuffers!
                        : structureAmbientOcclusionUniformBuffers
                      drawRibbonShadowMapMeshes(shadowMapCommandEncoder,
                                                sceneIndex: i,
                                                structureIndex: l,
                                                shadowUniformOffset: k * MemoryLayout<RKShadowUniforms>.stride,
                                                structureUniformBuffers: ribbonShadowUniformBuffers,
                                                structureUniformOffset: l * MemoryLayout<RKStructureUniforms>.stride,
                                                ribbonShader: ribbonShader)
                    }
                  }
                  
                  shadowMapCommandEncoder.endEncoding()
                  
                  if needFreshAtomBake
                  {
                    let ambientOcclusionBlendCommandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: ambientOcclusionBlendPassDescriptor)!
                    
                    ambientOcclusionBlendCommandEncoder.setFragmentBytes(&weights[k], length: MemoryLayout<Float>.stride, index: 2)
                    
                    ambientOcclusionBlendCommandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(textureSize), height: Double(textureSize), znear: 0.0, zfar: 1.0))
                    ambientOcclusionBlendCommandEncoder.setRenderPipelineState(self.ambientOcclusionPipeLine)
                    ambientOcclusionBlendCommandEncoder.setVertexBuffer(shadowMapFrameUniformBuffer, offset: k*MemoryLayout<RKShadowUniforms>.stride, index: 2)
                    ambientOcclusionBlendCommandEncoder.setVertexBuffer(structureAmbientOcclusionUniformBuffers, offset: j*MemoryLayout<RKStructureUniforms>.stride, index: 3)
                    ambientOcclusionBlendCommandEncoder.setFragmentBuffer(shadowMapFrameUniformBuffer, offset: k*MemoryLayout<RKShadowUniforms>.stride, index: 0)
                    ambientOcclusionBlendCommandEncoder.setFragmentBuffer(structureAmbientOcclusionUniformBuffers, offset: j*MemoryLayout<RKStructureUniforms>.stride, index: 1)
                    ambientOcclusionBlendCommandEncoder.setFragmentTexture(depthTexture, index: 0)
                    ambientOcclusionBlendCommandEncoder.setFragmentSamplerState(quadSamplerState, index: 0)
                    
                    if let buffer: MTLBuffer = atomShader.instanceBuffer[i][j],
                       let indexBuffer: MTLBuffer = atomOrthographicImposterShader.indexBuffer,
                       let vertexBuffer: MTLBuffer = atomOrthographicImposterShader.vertexBuffer
                    {
                      let instanceCount: Int = buffer.length/MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
                      let indexCount: Int = indexBuffer.length / MemoryLayout<UInt16>.stride
                      if instanceCount > 0 && indexCount > 0
                      {
                        ambientOcclusionBlendCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                        ambientOcclusionBlendCommandEncoder.setVertexBuffer(buffer, offset: 0, index: 1)
                        ambientOcclusionBlendCommandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexCount, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
                      }
                    }
                    
                    ambientOcclusionBlendCommandEncoder.endEncoding()
                  }
                  
                  if needFreshRibbonBake && ribbonCanBake,
                     let ribbonSource: RKRenderRibbonSource = ribbonSourceForAO,
                     let ribbonBlendPass: MTLRenderPassDescriptor = ribbonAmbientOcclusionBlendPassDescriptor
                  {
                    let ribbonAccumulationUniformBuffers: MTLBuffer = (ribbonUsesRenderUniformsForShadow && ribbonRenderStructureUniformBuffers != nil)
                      ? ribbonRenderStructureUniformBuffers!
                      : structureAmbientOcclusionUniformBuffers
                    let ribbonAOEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: ribbonBlendPass)!
                    let drewThisPass: Bool = encodeRibbonAmbientOcclusionAccumulation(ribbonAOEncoder,
                                                                                        sceneIndex: i,
                                                                                        structureIndex: j,
                                                                                        ribbonSource: ribbonSource,
                                                                                        ribbonShader: ribbonShader,
                                                                                        structureUniformBuffers: ribbonAccumulationUniformBuffers,
                                                                                        structureUniformOffset: j * MemoryLayout<RKStructureUniforms>.stride,
                                                                                        shadowUniformOffset: k * MemoryLayout<RKShadowUniforms>.stride,
                                                                                        weight: weights[k],
                                                                                        textureWidth: ribbonTextureWidth,
                                                                                        textureHeight: ribbonTextureHeight)
                    ribbonBakeDrewGeometry = ribbonBakeDrewGeometry || drewThisPass
                    ribbonAOEncoder.endEncoding()
                  }
                }
                
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
              }
              
              if needFreshAtomBake
              {
              let dataLength: Int = textureSize * textureSize * 2
              let textureBuffer: MTLBuffer = device.makeBuffer(length: dataLength, options: MTLResourceOptions())!
              
              // storing in NSCache
              if let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
              {
                let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()!
                RKMetal.synchronize(blitEncoder, resource: self.textures[i][j])
                blitEncoder.copy(from: self.textures[i][j], sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0,0, 0), sourceSize: MTLSizeMake(textureSize, textureSize, 1), to: textureBuffer, destinationOffset: 0, destinationBytesPerRow: textureSize * 2, destinationBytesPerImage: 0)
                blitEncoder.endEncoding()
                
                
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
              }
              
              // store ambient-occlusion texture for reuse (i.e. it is too expensive to recompute everytime a user switches projects)
              let ambientOcclusionTextureData: Data = Data(bytes: textureBuffer.contents().assumingMemoryBound(to: UInt8.self), count: dataLength)
              self.cachedAmbientOcclusionTextures.setObject(ambientOcclusionTextureData as AnyObject, forKey: structure)
              }
              
              if needFreshRibbonBake && ribbonCanBake && ribbonBakeDrewGeometry
              {
                postprocessRibbonAmbientOcclusionTexture(device: device,
                                                         commandQueue: commandQueue,
                                                         texture: self.ribbonTextures[i][j],
                                                         textureWidth: ribbonTextureWidth,
                                                         textureHeight: ribbonTextureHeight)
                
                let ribbonDataLength: Int = ribbonTextureWidth * ribbonTextureHeight * 2
                let ribbonTextureBuffer: MTLBuffer = device.makeBuffer(length: ribbonDataLength, options: MTLResourceOptions())!
                if let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
                {
                  let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()!
                  RKMetal.synchronize(blitEncoder, resource: self.ribbonTextures[i][j])
                  blitEncoder.copy(from: self.ribbonTextures[i][j], sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: MTLSizeMake(ribbonTextureWidth, ribbonTextureHeight, 1), to: ribbonTextureBuffer, destinationOffset: 0, destinationBytesPerRow: ribbonTextureWidth * 2, destinationBytesPerImage: 0)
                  blitEncoder.endEncoding()
                  commandBuffer.commit()
                  commandBuffer.waitUntilCompleted()
                }
                let ribbonTextureData: Data = Data(bytes: ribbonTextureBuffer.contents().assumingMemoryBound(to: UInt8.self), count: ribbonDataLength)
                if ribbonAmbientOcclusionTextureHasContent(ribbonTextureData, texelCount: ribbonTextureWidth * ribbonTextureHeight)
                {
                  self.cachedAmbientOcclusionTextures.setObject(ribbonTextureData as AnyObject, forKey: structure.ribbonAmbientOcclusionCacheKey)
                }
                synchronizeManagedTextureToGPU(device: device, commandQueue: commandQueue, texture: self.ribbonTextures[i][j])
              }
            }
          }
          
          if let ribbonSource: RKRenderRibbonSource = structure as? RKRenderRibbonSource,
             ribbonSource.drawRibbon,
             ribbonSource.ribbonAmbientOcclusion,
             ribbonSource.isVisible,
             ribbonSource.ribbonNumberOfChains > 0
          {
            let textureWidth: Int = ribbonSource.ribbonAmbientOcclusionTextureWidth
            let textureHeight: Int = ribbonSource.ribbonAmbientOcclusionTextureHeight
            let cacheKey: NSString = structure.ribbonAmbientOcclusionCacheKey
            
            if let cachedVersion: Data = cachedAmbientOcclusionTextures.object(forKey: cacheKey) as? Data
            {
              let region: MTLRegion = MTLRegionMake2D(0, 0, textureWidth, textureHeight)
              let ribbonTexture: MTLTexture = self.ribbonTextures[i][j]
              cachedVersion.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> () in
                ribbonTexture.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: ptr.baseAddress!, bytesPerRow: 2 * region.size.width, bytesPerImage: 2 * region.size.width * region.size.height)
              }
              synchronizeManagedTextureToGPU(device: device, commandQueue: commandQueue, texture: ribbonTexture)
            }
          }
        }
      }
    }
  }
  
  @discardableResult
  private func encodeRibbonAmbientOcclusionAccumulation(_ aoEncoder: MTLRenderCommandEncoder,
                                                        sceneIndex: Int,
                                                        structureIndex: Int,
                                                        ribbonSource: RKRenderRibbonSource,
                                                        ribbonShader: MetalRibbonShader,
                                                        structureUniformBuffers: MTLBuffer,
                                                        structureUniformOffset: Int,
                                                        shadowUniformOffset: Int,
                                                        weight: Float,
                                                        textureWidth: Int,
                                                        textureHeight: Int) -> Bool
  {
    var mutableWeight: Float = weight
    
    aoEncoder.setFragmentBytes(&mutableWeight, length: MemoryLayout<Float>.stride, index: 1)
    aoEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(textureWidth), height: Double(textureHeight), znear: 0.0, zfar: 1.0))
    aoEncoder.setRenderPipelineState(self.ribbonAmbientOcclusionPipeLine)
    aoEncoder.setVertexBuffer(structureUniformBuffers, offset: structureUniformOffset, index: 3)
    aoEncoder.setFragmentBuffer(shadowMapFrameUniformBuffer, offset: shadowUniformOffset, index: 0)
    aoEncoder.setFragmentTexture(depthTexture, index: 0)
    aoEncoder.setFragmentSamplerState(quadSamplerState, index: 0)
    
    guard let ribbonVertexBuffer: MTLBuffer = ribbonShader.metalBuffer(ribbonShader.vertexBuffer, sceneIndex: sceneIndex, movieIndex: structureIndex),
          let ribbonIndexBuffer: MTLBuffer = ribbonShader.metalBuffer(ribbonShader.indexBuffer, sceneIndex: sceneIndex, movieIndex: structureIndex)
    else {return false}
    
    aoEncoder.setVertexBuffer(ribbonVertexBuffer, offset: 0, index: 0)
    
    var drewGeometry: Bool = false
    for chainRange in ribbonSource.ribbonChainDrawRanges
    {
      guard chainRange.indexCount > 0 else {continue}
      aoEncoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: chainRange.indexCount,
                                      indexType: .uint32,
                                      indexBuffer: ribbonIndexBuffer,
                                      indexBufferOffset: chainRange.indexStart * MemoryLayout<UInt32>.stride)
      drewGeometry = true
    }
    return drewGeometry
  }
  
  private func ribbonAmbientOcclusionTextureHasContent(_ data: Data, texelCount: Int) -> Bool
  {
    guard texelCount > 0, data.count >= texelCount * MemoryLayout<UInt16>.stride else {return false}
    
    var maxValue: Float = 0.0
    data.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) in
      guard let pointer: UnsafePointer<UInt16> = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt16.self) else {return}
      for index in 0..<texelCount
      {
        maxValue = max(maxValue, RKHalfFloat.float(fromHalfBits: pointer[index]))
      }
    }
    return maxValue > 1.0e-5
  }
  
  private func postprocessRibbonAmbientOcclusionTexture(device: MTLDevice,
                                                         commandQueue: MTLCommandQueue,
                                                         texture: MTLTexture,
                                                         textureWidth: Int,
                                                         textureHeight: Int)
  {
    let texelCount: Int = textureWidth * textureHeight
    guard texelCount > 0 else {return}
    
    let readBuffer: MTLBuffer = device.makeBuffer(length: texelCount * MemoryLayout<UInt16>.stride, options: MTLResourceOptions())!
    if let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
    {
      let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()!
      RKMetal.synchronize(blitEncoder, resource: texture)
      blitEncoder.copy(from: texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: MTLSizeMake(textureWidth, textureHeight, 1), to: readBuffer, destinationOffset: 0, destinationBytesPerRow: textureWidth * MemoryLayout<UInt16>.stride, destinationBytesPerImage: 0)
      blitEncoder.endEncoding()
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()
    }
    
    var channelData: [Float] = Array(repeating: 0.0, count: texelCount)
    let halfPointer: UnsafeMutablePointer<UInt16> = readBuffer.contents().assumingMemoryBound(to: UInt16.self)
    for index in 0..<texelCount
    {
      channelData[index] = RKHalfFloat.float(fromHalfBits: halfPointer[index])
    }
    
    RibbonAOTexturePostProcess.dilateAndSmooth(&channelData, width: textureWidth, height: textureHeight)
    
    for index in 0..<texelCount
    {
      halfPointer[index] = RKHalfFloat.halfBits(from: channelData[index])
    }
    
    let region: MTLRegion = MTLRegionMake2D(0, 0, textureWidth, textureHeight)
    texture.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: readBuffer.contents(), bytesPerRow: textureWidth * MemoryLayout<UInt16>.stride, bytesPerImage: textureWidth * textureHeight * MemoryLayout<UInt16>.stride)
    synchronizeManagedTextureToGPU(device: device, commandQueue: commandQueue, texture: texture)
    
    blurRibbonAmbientOcclusionTexture(device: device,
                                      commandQueue: commandQueue,
                                      sourceTexture: texture,
                                      textureWidth: textureWidth,
                                      textureHeight: textureHeight)
  }
  
  private func blurRibbonAmbientOcclusionTexture(device: MTLDevice,
                                                 commandQueue: MTLCommandQueue,
                                                 sourceTexture: MTLTexture,
                                                 textureWidth: Int,
                                                 textureHeight: Int)
  {
    let blurTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.r16Float,
                                                                                               width: textureWidth,
                                                                                               height: textureHeight,
                                                                                               mipmapped: false)
    blurTextureDescriptor.textureType = MTLTextureType.type2D
    blurTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
    blurTextureDescriptor.storageMode = RKMetal.hostStorageMode
    guard let blurTexture: MTLTexture = device.makeTexture(descriptor: blurTextureDescriptor)
    else {return}
    
    let blurPipelines: [MTLRenderPipelineState] = [ribbonAOBlurHorizontalPipeLine, ribbonAOBlurVerticalPipeLine]
    var blurUniforms: RibbonAOBlurUniforms = RibbonAOBlurUniforms()
    blurUniforms.inverseTextureSize = SIMD2<Float>(Float(1.0 / Double(max(textureWidth, 1))),
                                                   Float(1.0 / Double(max(textureHeight, 1))))
    
    for pipeline in blurPipelines
    {
      guard let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
      else {return}
      
      let blurPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
      blurPassDescriptor.colorAttachments[0].texture = blurTexture
      blurPassDescriptor.colorAttachments[0].loadAction = MTLLoadAction.dontCare
      blurPassDescriptor.colorAttachments[0].storeAction = MTLStoreAction.store
      
      let blurEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: blurPassDescriptor)!
      blurEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(textureWidth), height: Double(textureHeight), znear: 0.0, zfar: 1.0))
      blurEncoder.setRenderPipelineState(pipeline)
      blurEncoder.setVertexBuffer(ribbonAOBlurVertexBuffer, offset: 0, index: 0)
      blurEncoder.setFragmentBytes(&blurUniforms, length: MemoryLayout<RibbonAOBlurUniforms>.stride, index: 0)
      blurEncoder.setFragmentTexture(sourceTexture, index: 0)
      blurEncoder.setFragmentSamplerState(quadSamplerState, index: 0)
      blurEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: 4, indexType: .uint16, indexBuffer: ribbonAOBlurIndexBuffer, indexBufferOffset: 0)
      blurEncoder.endEncoding()
      
      let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()!
      blitEncoder.copy(from: blurTexture,
                       sourceSlice: 0,
                       sourceLevel: 0,
                       sourceOrigin: MTLOriginMake(0, 0, 0),
                       sourceSize: MTLSizeMake(textureWidth, textureHeight, 1),
                       to: sourceTexture,
                       destinationSlice: 0,
                       destinationLevel: 0,
                       destinationOrigin: MTLOriginMake(0, 0, 0))
      blitEncoder.endEncoding()
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()
    }
  }
  
  private func synchronizeManagedTextureToGPU(device: MTLDevice, commandQueue: MTLCommandQueue, texture: MTLTexture)
  {
    guard RKMetal.isManagedStorage,
          texture.storageMode == RKMetal.hostStorageMode,
          let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
    else {return}
    
    let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()!
    RKMetal.synchronize(blitEncoder, resource: texture)
    blitEncoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
  }
  
  private func drawRibbonShadowMapMeshes(_ encoder: MTLRenderCommandEncoder,
                                         sceneIndex: Int,
                                         structureIndex: Int,
                                         shadowUniformOffset: Int,
                                         structureUniformBuffers: MTLBuffer,
                                         structureUniformOffset: Int,
                                         ribbonShader: MetalRibbonShader)
  {
    guard sceneIndex < renderStructures.count,
          structureIndex < renderStructures[sceneIndex].count,
          let ribbonSource: RKRenderRibbonSource = renderStructures[sceneIndex][structureIndex] as? RKRenderRibbonSource,
          ribbonSource.drawRibbon,
          let ribbonVertexBuffer: MTLBuffer = ribbonShader.metalBuffer(ribbonShader.vertexBuffer, sceneIndex: sceneIndex, movieIndex: structureIndex),
          let ribbonIndexBuffer: MTLBuffer = ribbonShader.metalBuffer(ribbonShader.indexBuffer, sceneIndex: sceneIndex, movieIndex: structureIndex)
    else {return}
    
    encoder.setCullMode(MTLCullMode.none)
    encoder.setFrontFacing(MTLWinding.clockwise)
    encoder.setRenderPipelineState(ribbonShadowMapPipeLine)
    encoder.setVertexBuffer(shadowMapFrameUniformBuffer, offset: shadowUniformOffset, index: 1)
    encoder.setVertexBuffer(structureUniformBuffers, offset: structureUniformOffset, index: 2)
    encoder.setFragmentBuffer(shadowMapFrameUniformBuffer, offset: shadowUniformOffset, index: 0)
    encoder.setVertexBuffer(ribbonVertexBuffer, offset: 0, index: 0)
    
    for chainRange in ribbonSource.ribbonChainDrawRanges
    {
      guard chainRange.indexCount > 0 else {continue}
      encoder.drawIndexedPrimitives(type: .triangle,
                                    indexCount: chainRange.indexCount,
                                    indexType: .uint32,
                                    indexBuffer: ribbonIndexBuffer,
                                    indexBufferOffset: chainRange.indexStart * MemoryLayout<UInt32>.stride)
    }
  }
  
  private func drawAtomShadowMapInstances(_ encoder: MTLRenderCommandEncoder,
                                          sceneIndex: Int,
                                          structureIndex: Int,
                                          structureUniformBuffers: MTLBuffer,
                                          structureUniformOffset: Int,
                                          shadowUniformOffset: Int,
                                          includeHiddenAtomsForRibbonOcclusion: Bool,
                                          atomShader: MetalAtomShader,
                                          atomOrthographicImposterShader: MetalAtomOrthographicImposterShader)
  {
    guard sceneIndex < renderStructures.count,
          structureIndex < renderStructures[sceneIndex].count,
          let atomSource: RKRenderAtomSource = renderStructures[sceneIndex][structureIndex] as? RKRenderAtomSource,
          atomSource.atomAmbientOcclusion,
          atomSource.drawAtoms || includeHiddenAtomsForRibbonOcclusion,
          let instanceBuffer: MTLBuffer = atomShader.instanceBuffer[sceneIndex][structureIndex],
          let vertexBuffer: MTLBuffer = atomOrthographicImposterShader.vertexBuffer,
          let indexBuffer: MTLBuffer = atomOrthographicImposterShader.indexBuffer
    else {return}
    
    let instanceCount: Int = instanceBuffer.length / MemoryLayout<RKInPerInstanceAttributesAtoms>.stride
    let indexCount: Int = indexBuffer.length / MemoryLayout<UInt16>.stride
    guard instanceCount > 0, indexCount > 0 else {return}
    
    encoder.setRenderPipelineState(shadowMapPipeLine)
    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    encoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
    encoder.setVertexBuffer(shadowMapFrameUniformBuffer, offset: shadowUniformOffset, index: 2)
    encoder.setVertexBuffer(structureUniformBuffers, offset: structureUniformOffset, index: 3)
    encoder.setFragmentBuffer(shadowMapFrameUniformBuffer, offset: shadowUniformOffset, index: 0)
    encoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexCount, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
  }
}
