/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl            http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 scaldia@upo.es                http://www.upo.es/raspa/sofiacalero.php
 t.j.h.vlugt@tudelft.nl        http://homepage.tudelft.nl/v9k6y
 
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

import Cocoa
import MetalKit
import Metal
import simd
import MathKit
import LogViewKit
import SimulationKit
import SymmetryKit



// Notes:
// Mac GPUs only support combined depth and stencil formats -> MTLPixelFormat.Depth32Float_Stencil8 supported on all devices

public class MetalRenderer
{
  public var backgroundShader: MetalBackgroundShader = MetalBackgroundShader()
  
  var atomShader: MetalAtomShader = MetalAtomShader()
  var atomOrthographicImposterShader: MetalAtomOrthographicImposterShader = MetalAtomOrthographicImposterShader()
  var atomPerspectiveImposterShader: MetalAtomPerspectiveImposterShader = MetalAtomPerspectiveImposterShader()
  
  var internalBondShader: MetalInternalBondShader = MetalInternalBondShader()
  var externalBondShader: MetalExternalBondShader = MetalExternalBondShader()
  
  var unitCellCylinderShader: MetalUnitCellCylinderShader = MetalUnitCellCylinderShader()
  var unitCellSphereShader: MetalUnitCellSphereShader = MetalUnitCellSphereShader()
  
  var boundingBoxCylinderShader: MetalBoundingBoxCylinderShader = MetalBoundingBoxCylinderShader()
  var boundingBoxSphereShader: MetalBoundingBoxSphereShader = MetalBoundingBoxSphereShader()
  
  var isosurfaceShader: MetalIsosurfaceShader = MetalIsosurfaceShader()
  
  var textShader: MetalTextShader = MetalTextShader()
  
  var pickingShader: MetalPickingShader = MetalPickingShader()
  
  var ambientOcclusionShader: MetalAmbientOcclusionShader = MetalAmbientOcclusionShader()
  
  var measurementShader: MetalMeasurementShader = MetalMeasurementShader()
  var measurementOrthographicImposterShader: MetalMeasurementOrthographicImposterShader = MetalMeasurementOrthographicImposterShader()
  var measurementPerspectiveImposterShader: MetalMeasurementPerspectiveImposterShader = MetalMeasurementPerspectiveImposterShader()
  
  var atomSelectionShader: MetalAtomSelectionShader = MetalAtomSelectionShader()
  
  var atomSelectionWorleyShader: MetalAtomSelectionWorleyNoise3DShader = MetalAtomSelectionWorleyNoise3DShader()
  var atomSelectionWorleyOrthographicImposterShader: MetalAtomSelectionWorleyNoise3DOrthographicImposterShader = MetalAtomSelectionWorleyNoise3DOrthographicImposterShader()
  var atomSelectionWorleyPerspectiveImposterShader: MetalAtomSelectionWorleyNoise3DPerspectiveImposterShader = MetalAtomSelectionWorleyNoise3DPerspectiveImposterShader()
  
  var atomSelectionStripedShader: MetalAtomSelectionStripesShader = MetalAtomSelectionStripesShader()
  var atomSelectionStripedOrthographicImposterShader: MetalAtomSelectionStripesOrthographicImposterShader = MetalAtomSelectionStripesOrthographicImposterShader()
  var atomSelectionStripedPerspectiveImposterShader: MetalAtomSelectionStripesPerspectiveImposterShader = MetalAtomSelectionStripesPerspectiveImposterShader()
  
  var atomSelectionGlowShader: MetalAtomSelectionGlowShader = MetalAtomSelectionGlowShader()
  var atomSelectionGlowOrthographicImposterShader: MetalAtomSelectionGlowOrthographicImposterShader = MetalAtomSelectionGlowOrthographicImposterShader()
  var atomSelectionGlowPerspectiveImposterShader: MetalAtomSelectionGlowPerspectiveImposterShader = MetalAtomSelectionGlowPerspectiveImposterShader()
  
  var blurHorizontalShader: MetalBlurHorizontalShader =  MetalBlurHorizontalShader()
  var blurVerticalShader: MetalBlurVerticalShader =  MetalBlurVerticalShader()
  
  var quadShader: MetalQuadShader = MetalQuadShader()
  
  var atomSelectionGlowPictureShader: MetalAtomSelectionGlowPictureShader = MetalAtomSelectionGlowPictureShader()
  var blurHorizontalPictureShader: MetalBlurHorizontalPictureShader =  MetalBlurHorizontalPictureShader()
  var blurVerticalPictureShader: MetalBlurVerticalPictureShader =  MetalBlurVerticalPictureShader()
  
  var metalSphereShader: MetalSphereShader =  MetalSphereShader()
  var metalCylinderShader: MetalCylinderShader =  MetalCylinderShader()
  var metalPolygonalPrismShader: MetalPolygonalPrismShader = MetalPolygonalPrismShader()
  
  var frameUniformBuffer: MTLBuffer! = nil
  var structureUniformBuffers: MTLBuffer! = nil
  var isosurfaceUniformBuffers: MTLBuffer! = nil
  var lightUniformBuffers: MTLBuffer! = nil
  
  weak var renderDataSource: RKRenderDataSource?
  weak var renderCameraSource: RKRenderCameraSource?
  
  var renderQuality: RKRenderQuality = .medium
  
  public init()
  {
  }
  
  func setDataSources(renderDataSource: RKRenderDataSource, renderStructures: [[RKRenderStructure]])
  {
    backgroundShader.renderDataSource = renderDataSource
    
    atomShader.renderDataSource = renderDataSource
    atomShader.renderStructures = renderStructures
    atomOrthographicImposterShader.renderDataSource = renderDataSource
    atomOrthographicImposterShader.renderStructures = renderStructures
    atomPerspectiveImposterShader.renderDataSource = renderDataSource
    atomPerspectiveImposterShader.renderStructures = renderStructures
    
    internalBondShader.renderDataSource = renderDataSource
    internalBondShader.renderStructures = renderStructures
    
    externalBondShader.renderDataSource = renderDataSource
    externalBondShader.renderStructures = renderStructures
    
    unitCellCylinderShader.renderDataSource = renderDataSource
    unitCellCylinderShader.renderStructures = renderStructures
    
    unitCellSphereShader.renderDataSource = renderDataSource
    unitCellSphereShader.renderStructures = renderStructures
    
    boundingBoxCylinderShader.renderDataSource = renderDataSource
    boundingBoxSphereShader.renderDataSource = renderDataSource
    
    isosurfaceShader.renderDataSource = renderDataSource
    isosurfaceShader.renderStructures = renderStructures
    
    textShader.renderDataSource = renderDataSource
    textShader.renderStructures = renderStructures
    
    pickingShader.renderDataSource = renderDataSource
    pickingShader.renderStructures = renderStructures
    
    ambientOcclusionShader.renderDataSource = renderDataSource
    ambientOcclusionShader.renderStructures = renderStructures
    
    measurementShader.renderDataSource = renderDataSource
    measurementShader.renderStructures = renderStructures
    measurementOrthographicImposterShader.renderDataSource = renderDataSource
    measurementOrthographicImposterShader.renderStructures = renderStructures
    measurementPerspectiveImposterShader.renderDataSource = renderDataSource
    measurementPerspectiveImposterShader.renderStructures = renderStructures
    
    atomSelectionShader.renderDataSource = renderDataSource
    atomSelectionShader.renderStructures = renderStructures
    
    atomSelectionWorleyShader.renderDataSource = renderDataSource
    atomSelectionWorleyShader.renderStructures = renderStructures
    atomSelectionWorleyOrthographicImposterShader.renderDataSource = renderDataSource
    atomSelectionWorleyOrthographicImposterShader.renderStructures = renderStructures
    atomSelectionWorleyPerspectiveImposterShader.renderDataSource = renderDataSource
    atomSelectionWorleyPerspectiveImposterShader.renderStructures = renderStructures
    
    atomSelectionStripedShader.renderDataSource = renderDataSource
    atomSelectionStripedShader.renderStructures = renderStructures
    atomSelectionStripedOrthographicImposterShader.renderDataSource = renderDataSource
    atomSelectionStripedOrthographicImposterShader.renderStructures = renderStructures
    atomSelectionStripedPerspectiveImposterShader.renderDataSource = renderDataSource
    atomSelectionStripedPerspectiveImposterShader.renderStructures = renderStructures
    
    atomSelectionGlowShader.renderDataSource = renderDataSource
    atomSelectionGlowShader.renderStructures = renderStructures
    atomSelectionGlowOrthographicImposterShader.renderDataSource = renderDataSource
    atomSelectionGlowOrthographicImposterShader.renderStructures = renderStructures
    atomSelectionGlowPerspectiveImposterShader.renderDataSource = renderDataSource
    atomSelectionGlowPerspectiveImposterShader.renderStructures = renderStructures
    
    atomSelectionGlowPictureShader.renderDataSource = renderDataSource
    atomSelectionGlowPictureShader.renderStructures = renderStructures
    
    
    metalSphereShader.renderDataSource  = renderDataSource
    metalSphereShader.renderStructures = renderStructures
    
    metalCylinderShader.renderDataSource  = renderDataSource
    metalCylinderShader.renderStructures = renderStructures
   
    metalPolygonalPrismShader.renderDataSource  = renderDataSource
    metalPolygonalPrismShader.renderStructures = renderStructures
  }
  
  
  // MARK: Reload
  // =====================================================================

  public func reloadData(device: MTLDevice, _ size: CGSize, maximumNumberOfSamples: Int)
  {
    if let renderCameraSource = renderCameraSource, renderCameraSource.renderCamera == nil,
       let renderDataSource = renderDataSource
    {
      // Camera does not exist yet, so create it. When importing CIFs, the camera is not created because the window size is not yet known.
      // The first time you view a crystal-project, the camera is created and calibrated to view the boundingBox full-size
      renderCameraSource.renderCamera = RKCamera()
      renderCameraSource.renderCamera?.boundingBox = renderDataSource.renderBoundingBox
      renderCameraSource.renderCamera?.resetCameraToDirection()
      renderCameraSource.renderCamera?.resetCameraDistance()
    }
    
    // makes sure the rendering data is consistent
    var renderStructures: [[RKRenderStructure]] = [[]]
    if let renderDataSource: RKRenderDataSource = renderDataSource
    {
      renderStructures = []
      self.textShader.renderTextFontString = []
      for i in 0..<renderDataSource.numberOfScenes
      {
        let structures: [RKRenderStructure] = renderDataSource.renderStructuresForScene(i)
        renderStructures.append(structures)
        self.textShader.renderTextFontString.append(structures.map{($0 as? RKRenderAtomSource)?.renderTextFont ?? ""})
      }
      
      setDataSources(renderDataSource: renderDataSource, renderStructures: renderStructures)
    }
    
    backgroundShader.reloadBackgroundImage(device: device)
    
    buildTextures(device: device, size: size, maximumNumberOfSamples: maximumNumberOfSamples)
    
    ambientOcclusionShader.buildAmbientOcclusionTextures(device: device)
    
    buildVertexBuffers(device: device)
    
    buildStructureUniforms(device: device)
  }
  
  public func reloadRenderData(device: MTLDevice)
  {
    // makes sure the rendering data is consistent
    var renderStructures: [[RKRenderStructure]] = []
    self.textShader.renderTextFontString = []
    
    if let renderDataSource: RKRenderDataSource = renderDataSource
    {
      renderStructures = []
      for i in 0..<renderDataSource.numberOfScenes
      {
        let structures: [RKRenderStructure] = renderDataSource.renderStructuresForScene(i)
        renderStructures.append(structures)
        self.textShader.renderTextFontString.append(structures.map{($0 as? RKRenderAtomSource)?.renderTextFont ?? ""})
      }
      
      setDataSources(renderDataSource: renderDataSource, renderStructures: renderStructures)
    }
    
    self.buildVertexBuffers(device: device)
  }
  
  public func reloadBoundingBoxData(device: MTLDevice)
  {
    boundingBoxCylinderShader.buildVertexBuffers(device: device)
    boundingBoxSphereShader.buildVertexBuffers(device: device)
  }

  public func reloadRenderDataSelectedAtoms(device: MTLDevice)
  {
    self.rebuildSelectionVertexBuffer(device: device)
  }
  
  public func reloadRenderMeasurePointsData(device: MTLDevice)
  {
    measurementShader.buildVertexBuffers(device: device)
    measurementOrthographicImposterShader.buildVertexBuffers(device: device)
    measurementPerspectiveImposterShader.buildVertexBuffers(device: device)
  }

  // MARK: Build pipelines
  // =====================================================================
  
  public func buildPipeLines(device: MTLDevice, _ library: MTLLibrary, maximumNumberOfSamples: Int)
  {
    let vertexDescriptor = MTLVertexDescriptor()
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].format = .float4
    vertexDescriptor.attributes[0].bufferIndex = 0
    vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD4<Float>>.stride
    vertexDescriptor.attributes[1].format = .float4
    vertexDescriptor.attributes[1].bufferIndex = 0
    vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD4<Float>>.stride * 2
    vertexDescriptor.attributes[2].format = .float2
    vertexDescriptor.attributes[2].bufferIndex = 0
    vertexDescriptor.layouts[0].stepFunction = .perVertex
    vertexDescriptor.layouts[0].stride = MemoryLayout<RKVertex>.stride
    
    
    backgroundShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    atomShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    atomOrthographicImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    atomPerspectiveImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    internalBondShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    externalBondShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    unitCellCylinderShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    unitCellSphereShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    boundingBoxCylinderShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    boundingBoxSphereShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    isosurfaceShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    pickingShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    textShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    ambientOcclusionShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    measurementShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    measurementOrthographicImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    measurementPerspectiveImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    atomSelectionGlowShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    atomSelectionGlowOrthographicImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    atomSelectionGlowPerspectiveImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    atomSelectionWorleyShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    atomSelectionWorleyOrthographicImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    atomSelectionWorleyPerspectiveImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    atomSelectionStripedShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    atomSelectionStripedOrthographicImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    atomSelectionStripedPerspectiveImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    blurHorizontalShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    blurVerticalShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    quadShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    atomSelectionGlowPictureShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    blurHorizontalPictureShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    blurVerticalPictureShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    
    metalSphereShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    metalCylinderShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
   
    metalPolygonalPrismShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
  }

  
  // MARK: Build textures
  // =====================================================================
  
  
  public func buildTextures(device: MTLDevice, size: CGSize, maximumNumberOfSamples: Int)
  {
    self.pickingShader.buildTextures(device: device, size: size, maximumNumberOfSamples: maximumNumberOfSamples)
    
    self.backgroundShader.buildTextures(device: device, size: size, maximumNumberOfSamples: maximumNumberOfSamples)
    
    self.atomSelectionGlowShader.buildTextures(device: device, size: size, maximumNumberOfSamples: maximumNumberOfSamples, sceneDepthTexture: backgroundShader.sceneDepthTexture)
    
    self.blurHorizontalShader.buildTextures(device: device, size: size, maximumNumberOfSamples: maximumNumberOfSamples)

    self.blurVerticalShader.buildTextures(device: device, size: size, maximumNumberOfSamples: maximumNumberOfSamples)
  }
  
  
  // MARK: Build vertex-buffers
  // =====================================================================
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    assert(Thread.isMainThread)
    
    backgroundShader.buildVertexBuffers(device: device)
    
    atomShader.buildVertexBuffers(device: device)
    atomOrthographicImposterShader.buildVertexBuffers(device: device)
    atomPerspectiveImposterShader.buildVertexBuffers(device: device)
    
    internalBondShader.buildVertexBuffers(device: device)
    externalBondShader.buildVertexBuffers(device: device)
    
    unitCellCylinderShader.buildVertexBuffers(device: device)
    unitCellSphereShader.buildVertexBuffers(device: device)
    
    boundingBoxCylinderShader.buildVertexBuffers(device: device)
    boundingBoxSphereShader.buildVertexBuffers(device: device)
    
    isosurfaceShader.buildInstanceBuffers(device: device)
    
    textShader.buildVertexBuffers(device: device)
    
    measurementShader.buildVertexBuffers(device: device)
    measurementOrthographicImposterShader.buildVertexBuffers(device: device)
    measurementPerspectiveImposterShader.buildVertexBuffers(device: device)
    
    atomSelectionShader.buildVertexBuffers(device: device)
    
    atomSelectionWorleyShader.buildVertexBuffers(device: device)
    atomSelectionWorleyOrthographicImposterShader.buildVertexBuffers(device: device)
    atomSelectionWorleyPerspectiveImposterShader.buildVertexBuffers(device: device)
    
    atomSelectionStripedShader.buildVertexBuffers(device: device)
    atomSelectionStripedOrthographicImposterShader.buildVertexBuffers(device: device)
    atomSelectionStripedPerspectiveImposterShader.buildVertexBuffers(device: device)
    
    atomSelectionGlowShader.buildVertexBuffers(device: device)
    atomSelectionGlowOrthographicImposterShader.buildVertexBuffers(device: device)
    atomSelectionGlowPerspectiveImposterShader.buildVertexBuffers(device: device)
    
    blurHorizontalShader.buildVertexBuffers(device: device)
    blurVerticalShader.buildVertexBuffers(device: device)
  
    quadShader.buildVertexBuffers(device: device)
    
    atomSelectionGlowPictureShader.buildVertexBuffers(device: device)
    blurHorizontalPictureShader.buildVertexBuffers(device: device)
    blurVerticalPictureShader.buildVertexBuffers(device: device)
    
    metalSphereShader.buildVertexBuffers(device: device)
    metalCylinderShader.buildVertexBuffers(device: device)
    metalPolygonalPrismShader.buildVertexBuffers(device: device)
    
    var uniforms: RKTransformationUniforms = transformUniforms()
    self.frameUniformBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<RKTransformationUniforms>.stride, options: .storageModeManaged)
  }
  
  public func rebuildSelectionVertexBuffer(device: MTLDevice)
  {
    atomSelectionShader.buildVertexBuffers(device: device)
  }
  
  // MARK: Uniforms
  // =====================================================================
  
  public func buildStructureUniforms(device: MTLDevice)
  {
    
    if let project: RKRenderDataSource = renderDataSource
    {
      var structureUniforms: [RKStructureUniforms] = [RKStructureUniforms](repeating: RKStructureUniforms(), count: max(project.renderStructures.count,1))
      
      var isosurfaceUniforms: [RKIsosurfaceUniforms] = [RKIsosurfaceUniforms](repeating: RKIsosurfaceUniforms(), count: max(project.renderStructures.count,1))
      
      var index: Int  = 0
      for i in 0..<project.numberOfScenes
      {
        let structures: [RKRenderStructure] = project.renderStructuresForScene(i)
        for (j,structure) in structures.enumerated()
        {
          structureUniforms[index] = RKStructureUniforms(sceneIdentifier: i, movieIdentifier: j, structure: structure)
          isosurfaceUniforms[index] = RKIsosurfaceUniforms(structure: structure)
          index += 1
        }
      }
      
      structureUniformBuffers = device.makeBuffer(bytes: structureUniforms, length: MemoryLayout<RKStructureUniforms>.stride * max(structureUniforms.count,1), options:.storageModeManaged)
      isosurfaceUniformBuffers = device.makeBuffer(bytes: isosurfaceUniforms, length: MemoryLayout<RKIsosurfaceUniforms>.stride * max(isosurfaceUniforms.count,1), options:.storageModeManaged)
      
      var lightUniforms: RKLightUniforms = RKLightUniforms(project: project)
      lightUniformBuffers = device.makeBuffer(bytes: &lightUniforms.lights, length: 4 * MemoryLayout<RKLight>.stride, options:.storageModeManaged)
    }
  }
  
  public func buildIsosurfaceUniforms(device: MTLDevice)
  {
    if let project: RKRenderDataSource = renderDataSource
    {
      var isosurfaceUniforms: [RKIsosurfaceUniforms] = [RKIsosurfaceUniforms](repeating: RKIsosurfaceUniforms(), count: project.renderStructures.count)
      
      var index: Int  = 0
      for i in 0..<project.numberOfScenes
      {
        let structures: [RKRenderStructure] = project.renderStructuresForScene(i)
        for structure in structures
        {
          isosurfaceUniforms[index] = RKIsosurfaceUniforms(structure: structure)
          index += 1
        }
      }
      
      isosurfaceUniformBuffers = device.makeBuffer(bytes: isosurfaceUniforms, length: MemoryLayout<RKIsosurfaceUniforms>.stride * isosurfaceUniforms.count, options:.storageModeManaged)
    }
  }

  
  public func buildLightUniforms(device: MTLDevice)
  {
    if let project: RKRenderDataSource = renderDataSource
    {
      var lightUniforms: RKLightUniforms = RKLightUniforms(project: project)
      lightUniformBuffers = device.makeBuffer(bytes: &lightUniforms.lights, length: 4 * MemoryLayout<RKLight>.stride, options:.storageModeManaged)
    }
  }

  public func transformUniforms() -> RKTransformationUniforms
  {
    if let camera: RKCamera = renderCameraSource?.renderCamera
    {
      let projectionMatrix = camera.projectionMatrix
      let viewMatrix = camera.modelViewMatrix
      
      return RKTransformationUniforms(projectionMatrix: projectionMatrix, viewMatrix: viewMatrix, bloomLevel: camera.bloomLevel, bloomPulse: camera.bloomPulse)
    }
    else
    {
      return RKTransformationUniforms(projectionMatrix: double4x4(), viewMatrix: double4x4(), bloomLevel: 1.0, bloomPulse: 1.0)
    }
  }
  
  
  // MARK: Rendering
  // =====================================================================

  public func renderSceneWithEncoder(_ commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, size: CGSize)
  {
    let commandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
    commandEncoder.label = "Scene command encoder"
    commandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
    commandEncoder.setCullMode(MTLCullMode.back)
    commandEncoder.setFrontFacing(MTLWinding.clockwise)
    
    backgroundShader.renderBackgroundWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, size: size)
    
    self.isosurfaceShader.renderOpaqueIsosurfaceWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, isosurfaceUniformBuffers: isosurfaceUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    
    if let camera: RKCamera = renderCameraSource?.renderCamera
    {
      switch(renderQuality)
      {
      case .high, .picture:
        self.atomShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
      case .medium, .low:
        switch(camera.frustrumType)
        {
        case RKCamera.FrustrumType.orthographic:
          self.atomOrthographicImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomShader.instanceBuffer, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
        case RKCamera.FrustrumType.perspective:
          self.atomPerspectiveImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomShader.instanceBuffer, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
        }
      }
    }
    
   
    self.metalSphereShader.renderOpaqueWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
   
     self.metalCylinderShader.renderOpaqueWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    
    self.metalPolygonalPrismShader.renderOpaqueWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    
  
    
    self.internalBondShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    
    self.externalBondShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    
    self.unitCellCylinderShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    self.unitCellSphereShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    
    self.boundingBoxCylinderShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, lightUniformBuffers: lightUniformBuffers, size: size)
    self.boundingBoxSphereShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, lightUniformBuffers: lightUniformBuffers, size: size)
    
    
    if let camera: RKCamera = renderCameraSource?.renderCamera
    {
      switch(renderQuality)
      {
      case .high, .picture:
        self.atomSelectionWorleyShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, atomShader: atomShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
        self.atomSelectionStripedShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, atomShader: atomShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      case .medium, .low:
        switch(camera.frustrumType)
        {
        case RKCamera.FrustrumType.orthographic:
          self.atomSelectionWorleyOrthographicImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, atomOrthographicImposterShader: atomOrthographicImposterShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
          self.atomSelectionStripedOrthographicImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, atomOrthographicImposterShader: atomOrthographicImposterShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
        case RKCamera.FrustrumType.perspective:
          self.atomSelectionWorleyPerspectiveImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, atomPerspectiveImposterShader: atomPerspectiveImposterShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
          self.atomSelectionStripedPerspectiveImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, atomPerspectiveImposterShader: atomPerspectiveImposterShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
        }
      }
    }
    
    
    if let camera: RKCamera = renderCameraSource?.renderCamera
    {
      switch(camera.frustrumType)
      {
      case RKCamera.FrustrumType.orthographic:
        self.measurementOrthographicImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      case RKCamera.FrustrumType.perspective:
        self.measurementPerspectiveImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      }
    }
    
    self.textShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    
  
    self.metalSphereShader.renderTransparentWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    
    self.metalCylinderShader.renderTransparentWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
  
    self.metalPolygonalPrismShader.renderTransparentWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    
    self.isosurfaceShader.renderTransparentIsosurfacesWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, isosurfaceUniformBuffers: isosurfaceUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    
    commandEncoder.endEncoding()
  }
  
  func pickingOffScreen(commandBuffer: MTLCommandBuffer, frameUniformBuffer: MTLBuffer, size: CGSize)
  {
    pickingShader.renderPickingTextureWithEncoder(commandBuffer, renderPassDescriptor: pickingShader.renderPassDescriptor, atomShader: atomShader, atomOrthographicImposterShader: atomOrthographicImposterShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, size: size)
  }
  
  func drawOffScreen(commandBuffer: MTLCommandBuffer, frameUniformBuffer: MTLBuffer, size: CGSize)
  {
    renderSceneWithEncoder(commandBuffer, renderPassDescriptor: backgroundShader.sceneRenderPassDescriptor, frameUniformBuffer: frameUniformBuffer, size: size)
    
    if let camera: RKCamera = renderCameraSource?.renderCamera
    {
      switch(renderQuality)
      {
      case .high, .picture:
        atomSelectionGlowShader.renderWithEncoder(commandBuffer, instanceBuffer: atomSelectionShader.instanceBuffer, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      case .medium, .low:
        switch(camera.frustrumType)
        {
        case RKCamera.FrustrumType.orthographic:
          atomSelectionGlowOrthographicImposterShader.renderWithEncoder(commandBuffer, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
        case RKCamera.FrustrumType.perspective:
          atomSelectionGlowPerspectiveImposterShader.renderWithEncoder(commandBuffer, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
        }
      }
    }
    
    blurHorizontalShader.renderWithEncoder(commandBuffer, renderPassDescriptor: blurHorizontalShader.blurHorizontalRenderPassDescriptor, texture: atomSelectionGlowShader.atomSelectionGlowResolveTexture, frameUniformBuffer: frameUniformBuffer, size: size)
    
    blurVerticalShader.renderWithEncoder(commandBuffer, renderPassDescriptor: blurVerticalShader.blurVerticalRenderPassDescriptor, texture: blurHorizontalShader.blurHorizontalTexture, frameUniformBuffer: frameUniformBuffer, size: size)
  }
  
  func drawOnScreen(commandBuffer: MTLCommandBuffer, renderPass: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, size: CGSize)
  {
    quadShader.renderWithEncoder(commandBuffer, renderPass: renderPass, frameUniformBuffer: frameUniformBuffer, sceneResolveTexture: backgroundShader.sceneResolveTexture, blurVerticalTexture: blurVerticalShader.blurVerticalTexture, size: size)
  }
  
  public func drawSceneToTexture(device: MTLDevice, size: NSSize, imageQuality: RKImageQuality, maximumNumberOfSamples: Int) -> Data
  {
    if let _: RKRenderDataSource = renderDataSource
    {
      var uniforms: RKTransformationUniforms = self.transformUniforms()
      let frameUniformBuffer: MTLBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<RKTransformationUniforms>.stride, options: .storageModeManaged)!
      
      let sceneTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Float, width: max(Int(size.width),100), height: max(Int(size.height),100), mipmapped: false)
      sceneTextureDescriptor.textureType = MTLTextureType.type2DMultisample
      sceneTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
      sceneTextureDescriptor.sampleCount = maximumNumberOfSamples
      sceneTextureDescriptor.storageMode = MTLStorageMode.private
      let sceneTexture: MTLTexture! = device.makeTexture(descriptor: sceneTextureDescriptor)
      sceneTexture.label = "scene multisampled texture"
      
      let sceneDepthTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.depth32Float_stencil8, width: max(Int(size.width),100), height: max(Int(size.height),100), mipmapped: false)
      sceneDepthTextureDescriptor.textureType = MTLTextureType.type2DMultisample
      sceneDepthTextureDescriptor.sampleCount = maximumNumberOfSamples
      sceneDepthTextureDescriptor.storageMode = MTLStorageMode.private
      sceneDepthTextureDescriptor.usage = MTLTextureUsage.renderTarget
      let sceneDepthTexture: MTLTexture = device.makeTexture(descriptor: sceneDepthTextureDescriptor)!
      sceneDepthTexture.label = "scene multisampled depth texture"
      
      let sceneResolveTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Float, width: max(Int(size.width),100), height: max(Int(size.height),100), mipmapped: false)
      sceneResolveTextureDescriptor.textureType = MTLTextureType.type2D
      sceneResolveTextureDescriptor.storageMode = MTLStorageMode.private
      let sceneResolveTexture: MTLTexture = device.makeTexture(descriptor: sceneResolveTextureDescriptor)!
      sceneResolveTexture.label = "scene resolved texture"
      
      let sceneRenderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
      let sceneColorAttachment: MTLRenderPassColorAttachmentDescriptor = sceneRenderPassDescriptor.colorAttachments[0]
      sceneColorAttachment.texture = sceneTexture
      sceneColorAttachment.loadAction = MTLLoadAction.load
      sceneColorAttachment.resolveTexture = sceneResolveTexture
      sceneColorAttachment.storeAction = MTLStoreAction.multisampleResolve
      
      let sceneDepthAttachment: MTLRenderPassDepthAttachmentDescriptor = sceneRenderPassDescriptor.depthAttachment
      sceneDepthAttachment.texture = sceneDepthTexture
      sceneDepthAttachment.loadAction = MTLLoadAction.clear
      sceneDepthAttachment.storeAction = MTLStoreAction.dontCare
      sceneDepthAttachment.clearDepth = 1.0
      
      let sceneStencilAttachment: MTLRenderPassStencilAttachmentDescriptor = sceneRenderPassDescriptor.stencilAttachment
      sceneStencilAttachment.texture = sceneDepthTexture
      sceneStencilAttachment.loadAction = MTLLoadAction.clear
      sceneStencilAttachment.storeAction = MTLStoreAction.dontCare
      sceneStencilAttachment.clearStencil = 0
      
      let atomSelectionGlowTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Float, width: max(Int(size.width),100), height: max(Int(size.height),100), mipmapped: false)
      atomSelectionGlowTextureDescriptor.textureType = MTLTextureType.type2DMultisample
      atomSelectionGlowTextureDescriptor.sampleCount = maximumNumberOfSamples
      atomSelectionGlowTextureDescriptor.storageMode = MTLStorageMode.private
      atomSelectionGlowTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
      let atomSelectionGlowTexture: MTLTexture = device.makeTexture(descriptor: atomSelectionGlowTextureDescriptor)!
      atomSelectionGlowTexture.label = "glow atoms texture"
      
      let atomSelectionGlowResolveTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Float, width: max(Int(size.width),100), height: max(Int(size.height),100), mipmapped: false)
      atomSelectionGlowResolveTextureDescriptor.textureType = MTLTextureType.type2D
      atomSelectionGlowResolveTextureDescriptor.storageMode = MTLStorageMode.private
      let atomSelectionGlowResolveTexture: MTLTexture = device.makeTexture(descriptor: atomSelectionGlowResolveTextureDescriptor)!
      atomSelectionGlowResolveTexture.label = "glow resolved texture"
      
      let atomSelectionGlowAtomsRenderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
      let atomSelectionGlowAtomsColorAttachment: MTLRenderPassColorAttachmentDescriptor = atomSelectionGlowAtomsRenderPassDescriptor.colorAttachments[0]
      atomSelectionGlowAtomsColorAttachment.texture = atomSelectionGlowTexture
      atomSelectionGlowAtomsColorAttachment.loadAction = MTLLoadAction.clear
      atomSelectionGlowAtomsColorAttachment.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
      atomSelectionGlowAtomsColorAttachment.storeAction = MTLStoreAction.store
      atomSelectionGlowAtomsColorAttachment.resolveTexture = atomSelectionGlowResolveTexture
      atomSelectionGlowAtomsColorAttachment.storeAction = MTLStoreAction.multisampleResolve
      
      let atomSelectionGlowAtomsDepthAttachment: MTLRenderPassDepthAttachmentDescriptor = atomSelectionGlowAtomsRenderPassDescriptor.depthAttachment
      atomSelectionGlowAtomsDepthAttachment.texture = sceneDepthTexture
      atomSelectionGlowAtomsDepthAttachment.loadAction = MTLLoadAction.load
      atomSelectionGlowAtomsDepthAttachment.storeAction = MTLStoreAction.dontCare
      
      let atomSelectionGlowAtomsStencilAttachment: MTLRenderPassStencilAttachmentDescriptor = atomSelectionGlowAtomsRenderPassDescriptor.stencilAttachment
      atomSelectionGlowAtomsStencilAttachment.texture = sceneDepthTexture
      atomSelectionGlowAtomsStencilAttachment.loadAction = MTLLoadAction.load
      atomSelectionGlowAtomsStencilAttachment.storeAction = MTLStoreAction.dontCare
      
      let blurHorizontalTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Float, width: max(Int(size.width),100), height: max(Int(size.height),100), mipmapped: false)
      blurHorizontalTextureDescriptor.textureType = MTLTextureType.type2D
      blurHorizontalTextureDescriptor.storageMode = MTLStorageMode.managed
      blurHorizontalTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
      let blurHorizontalTexture: MTLTexture = device.makeTexture(descriptor: blurHorizontalTextureDescriptor)!
      blurHorizontalTexture.label = "blur horizontal texture"
      
      let blurHorizontalRenderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
      let blurHorizontalColorAttachment: MTLRenderPassColorAttachmentDescriptor = blurHorizontalRenderPassDescriptor.colorAttachments[0]
      blurHorizontalColorAttachment.texture = blurHorizontalTexture
      blurHorizontalColorAttachment.loadAction = MTLLoadAction.clear
      blurHorizontalColorAttachment.storeAction = MTLStoreAction.store
      
      let blurVerticalTextureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Float, width: max(Int(size.width),100), height: max(Int(size.height),100), mipmapped: false)
      blurVerticalTextureDescriptor.textureType = MTLTextureType.type2D
      blurVerticalTextureDescriptor.storageMode = MTLStorageMode.managed // change to private soon
      blurVerticalTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
      let blurVerticalTexture: MTLTexture = device.makeTexture(descriptor: blurVerticalTextureDescriptor)!
      blurVerticalTexture.label = "blur vertical texture"
      
      let blurVerticalRenderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
      let blurVerticalColorAttachment: MTLRenderPassColorAttachmentDescriptor = blurVerticalRenderPassDescriptor.colorAttachments[0]
      blurVerticalColorAttachment.texture = blurVerticalTexture
      blurVerticalColorAttachment.loadAction = MTLLoadAction.clear
      blurVerticalColorAttachment.clearColor = MTLClearColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.0)
      blurVerticalColorAttachment.storeAction = MTLStoreAction.store
      
      let pictureTextureDescriptor: MTLTextureDescriptor
      switch(imageQuality)
      {
      case .rgb_16_bits, .cmyk_16_bits:
        pictureTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Unorm, width: max(Int(size.width),100), height: max(Int(size.height),100), mipmapped: false)
      case .rgb_8_bits, .cmyk_8_bits:
        pictureTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.bgra8Unorm, width: max(Int(size.width),100), height: max(Int(size.height),100), mipmapped: false)
      }
      
      pictureTextureDescriptor.textureType = MTLTextureType.type2D
      pictureTextureDescriptor.storageMode = MTLStorageMode.managed
      pictureTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
      let pictureTexture: MTLTexture = device.makeTexture(descriptor: pictureTextureDescriptor)!
      pictureTexture.label = "scene resolved texture"
      
      let picturePassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
      let pictureColorAttachment: MTLRenderPassColorAttachmentDescriptor = picturePassDescriptor.colorAttachments[0]
      pictureColorAttachment.texture = pictureTexture
      pictureColorAttachment.loadAction = MTLLoadAction.clear
      pictureColorAttachment.clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0)
      pictureColorAttachment.storeAction = MTLStoreAction.store
      
      if let commandQueue: MTLCommandQueue = device.makeCommandQueue(),
         let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
      {
        renderSceneWithEncoder(commandBuffer, renderPassDescriptor: sceneRenderPassDescriptor, frameUniformBuffer: frameUniformBuffer, size: size)
      
        atomSelectionGlowPictureShader.renderWithEncoder(commandBuffer, renderPassDescriptor: atomSelectionGlowAtomsRenderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      
        blurHorizontalPictureShader.renderWithEncoder(commandBuffer, renderPassDescriptor: blurHorizontalRenderPassDescriptor, texture: atomSelectionGlowResolveTexture, frameUniformBuffer: frameUniformBuffer, size: size)
      
        blurVerticalPictureShader.renderWithEncoder(commandBuffer, renderPassDescriptor: blurVerticalRenderPassDescriptor, texture: blurHorizontalTexture, frameUniformBuffer: frameUniformBuffer, size: size)
      
        if let quadCommandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: picturePassDescriptor)
        {
          quadCommandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
          quadCommandEncoder.label = "Quad Pass Encoder"
          switch(imageQuality)
          {
          case .rgb_16_bits, .cmyk_16_bits:
            quadCommandEncoder.setRenderPipelineState(quadShader.textureQuad16bitsPipeLine)
          case .rgb_8_bits, .cmyk_8_bits:
            quadCommandEncoder.setRenderPipelineState(quadShader.quadPipeLine)
          }
      
          quadCommandEncoder.setVertexBuffer(quadShader.vertexBuffer, offset: 0, index: 0)
          quadCommandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
          quadCommandEncoder.setFragmentTexture(sceneResolveTexture, index: 0)
          quadCommandEncoder.setFragmentTexture(blurVerticalTexture, index: 1)
          quadCommandEncoder.setFragmentSamplerState(quadShader.quadSamplerState, index: 0)
          quadCommandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: 4, indexType: .uint16, indexBuffer: quadShader.indexBuffer, indexBufferOffset: 0)
          quadCommandEncoder.endEncoding()
    
          let dataLength: Int
          let bytesPerRow: Int
          switch(imageQuality)
          {
          case .rgb_16_bits, .cmyk_16_bits:
            bytesPerRow = Int(size.width) * 4 * 2
            dataLength = bytesPerRow * Int(size.height)
          case .rgb_8_bits, .cmyk_8_bits:
            bytesPerRow = Int(size.width) * 4
            dataLength = bytesPerRow * Int(size.height)
          }
          if let pictureTextureBuffer: MTLBuffer = device.makeBuffer(length: dataLength, options: MTLResourceOptions()),
             let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
          {
            blitEncoder.synchronize(resource: pictureTexture)
      
            blitEncoder.copy(from: pictureTexture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0,0, 0), sourceSize: MTLSizeMake(Int(size.width), Int(size.height), 1), to: pictureTextureBuffer, destinationOffset: 0, destinationBytesPerRow: bytesPerRow, destinationBytesPerImage: 0)
            blitEncoder.endEncoding()
      
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
      
            return Data(bytes: pictureTextureBuffer.contents().assumingMemoryBound(to: UInt8.self), count: pictureTextureBuffer.length)
          }
        }
      }
    }
    return Data()
  }
}


