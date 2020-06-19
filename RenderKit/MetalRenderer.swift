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
  
  var internalBondSelectionShader: MetalInternalBondSelectionShader = MetalInternalBondSelectionShader()
  var externalBondSelectionShader: MetalExternalBondSelectionShader = MetalExternalBondSelectionShader()
  var internalBondSelectionWorleyShader: MetalInternalBondSelectionWorleyNoise3DShader = MetalInternalBondSelectionWorleyNoise3DShader()
  var internalBondSelectionGlowShader: MetalInternalBondSelectionGlowShader = MetalInternalBondSelectionGlowShader()
  var internalBondSelectionStripedShader: MetalInternalBondSelectionStripedShader = MetalInternalBondSelectionStripedShader()
  var externalBondSelectionWorleyShader: MetalExternalBondSelectionWorleyNoise3DShader = MetalExternalBondSelectionWorleyNoise3DShader()
  var externalBondSelectionGlowShader: MetalExternalBondSelectionGlowShader = MetalExternalBondSelectionGlowShader()
  var externalBondSelectionStripedShader: MetalExternalBondSelectionStripedShader = MetalExternalBondSelectionStripedShader()
  
  var ellipsoidPrimitiveSelectionStripedShader: MetalEllipsoidPrimitiveSelectionStripedShader = MetalEllipsoidPrimitiveSelectionStripedShader()
  var crystalEllipsoidPrimitiveSelectionStripedShader: MetalCrystalEllipsoidPrimitiveSelectionStripedShader = MetalCrystalEllipsoidPrimitiveSelectionStripedShader()
  var cylinderPrimitiveSelectionStripedShader: MetalCylinderPrimitiveSelectionStripedShader = MetalCylinderPrimitiveSelectionStripedShader()
  var crystalCylinderPrimitiveSelectionStripedShader: MetalCrystalCylinderPrimitiveSelectionStripedShader = MetalCrystalCylinderPrimitiveSelectionStripedShader()
  var polygonalPrismPrimitiveSelectionStripedShader: MetalPolygonalPrismPrimitiveSelectionStripedShader = MetalPolygonalPrismPrimitiveSelectionStripedShader()
  var crystalPolygonalPrismPrimitiveSelectionStripedShader: MetalCrystalPolygonalPrismPrimitiveSelectionStripedShader = MetalCrystalPolygonalPrismPrimitiveSelectionStripedShader()
  
  var ellipsoidPrimitiveSelectionWorleyNoise3DShader: MetalEllipsoidPrimitiveSelectionWorleyNoise3DShader = MetalEllipsoidPrimitiveSelectionWorleyNoise3DShader()
  var crystalEllipsoidPrimitiveSelectionWorleyNoise3DShader: MetalCrystalEllipsoidPrimitiveSelectionWorleyNoise3DShader = MetalCrystalEllipsoidPrimitiveSelectionWorleyNoise3DShader()
  var cylinderPrimitiveSelectionWorleyNoise3DShader: MetalCylinderPrimitiveSelectionWorleyNoise3DShader = MetalCylinderPrimitiveSelectionWorleyNoise3DShader()
  var crystalCylinderPrimitiveSelectionWorleyNoise3DShader: MetalCrystalCylinderPrimitiveSelectionWorleyNoise3DShader = MetalCrystalCylinderPrimitiveSelectionWorleyNoise3DShader()
  var polygonalPrismPrimitiveSelectionWorleyNoise3DShader: MetalPolygonalPrismPrimitiveSelectionWorleyNoise3DShader = MetalPolygonalPrismPrimitiveSelectionWorleyNoise3DShader()
  var crystalPolygonalPrismPrimitiveSelectionWorleyNoise3DShader: MetalCrystalPolygonalPrismPrimitiveSelectionWorleyNoise3DShader = MetalCrystalPolygonalPrismPrimitiveSelectionWorleyNoise3DShader()
  
  var ellipsoidPrimitiveSelectionGlowShader: MetalEllipsoidPrimitiveSelectionGlowShader = MetalEllipsoidPrimitiveSelectionGlowShader()
  var crystalEllipsoidPrimitiveSelectionGlowShader: MetalCrystalEllipsoidPrimitiveSelectionGlowShader = MetalCrystalEllipsoidPrimitiveSelectionGlowShader()
  var cylinderPrimitiveSelectionGlowShader: MetalCylinderPrimitiveSelectionGlowShader = MetalCylinderPrimitiveSelectionGlowShader()
  var crystalCylinderPrimitiveSelectionGlowShader: MetalCrystalCylinderPrimitiveSelectionGlowShader = MetalCrystalCylinderPrimitiveSelectionGlowShader()
  var polygonalPrismPrimitiveSelectionGlowShader: MetalPolygonalPrismPrimitiveSelectionGlowShader = MetalPolygonalPrismPrimitiveSelectionGlowShader()
  var crystalPolygonalPrismPrimitiveSelectionGlowShader: MetalCrystalPolygonalPrismPrimitiveSelectionGlowShader = MetalCrystalPolygonalPrismPrimitiveSelectionGlowShader()
  
  
  var blurHorizontalShader: MetalBlurHorizontalShader =  MetalBlurHorizontalShader()
  var blurVerticalShader: MetalBlurVerticalShader =  MetalBlurVerticalShader()
  
  var quadShader: MetalQuadShader = MetalQuadShader()
  
  var atomSelectionGlowPictureShader: MetalAtomSelectionGlowPictureShader = MetalAtomSelectionGlowPictureShader()
  var blurHorizontalPictureShader: MetalBlurHorizontalPictureShader =  MetalBlurHorizontalPictureShader()
  var blurVerticalPictureShader: MetalBlurVerticalPictureShader =  MetalBlurVerticalPictureShader()
  
  var metalCrystalEllipsoidShader: MetalCrystalEllipsoidShader =  MetalCrystalEllipsoidShader()
  var metalCrystalCylinderShader: MetalCrystalCylinderShader =  MetalCrystalCylinderShader()
  var metalCrystalPolygonalPrismShader: MetalCrystalPolygonalPrismShader = MetalCrystalPolygonalPrismShader()
  var metalEllipsoidShader: MetalEllipsoidShader =  MetalEllipsoidShader()
  var metalCylinderShader: MetalCylinderShader =  MetalCylinderShader()
  var metalPolygonalPrismShader: MetalPolygonalPrismShader = MetalPolygonalPrismShader()
  
  var frameUniformBuffer: MTLBuffer! = nil
  var structureUniformBuffers: MTLBuffer! = nil
  var isosurfaceUniformBuffers: MTLBuffer! = nil
  var lightUniformBuffers: MTLBuffer! = nil
  
  weak var renderDataSource: RKRenderDataSource?
  
  
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
    
    internalBondSelectionShader.renderDataSource = renderDataSource
    internalBondSelectionShader.renderStructures = renderStructures
    internalBondSelectionWorleyShader.renderDataSource = renderDataSource
    internalBondSelectionWorleyShader.renderStructures = renderStructures
    internalBondSelectionGlowShader.renderDataSource = renderDataSource
    internalBondSelectionGlowShader.renderStructures = renderStructures
    internalBondSelectionStripedShader.renderDataSource = renderDataSource
    internalBondSelectionStripedShader.renderStructures = renderStructures
    
    externalBondSelectionShader.renderDataSource = renderDataSource
    externalBondSelectionShader.renderStructures = renderStructures
    externalBondSelectionWorleyShader.renderDataSource = renderDataSource
    externalBondSelectionWorleyShader.renderStructures = renderStructures
    externalBondSelectionGlowShader.renderDataSource = renderDataSource
    externalBondSelectionGlowShader.renderStructures = renderStructures
    externalBondSelectionStripedShader.renderDataSource = renderDataSource
    externalBondSelectionStripedShader.renderStructures = renderStructures
    
    metalCrystalEllipsoidShader.renderDataSource  = renderDataSource
    metalCrystalEllipsoidShader.renderStructures = renderStructures
    metalCrystalCylinderShader.renderDataSource  = renderDataSource
    metalCrystalCylinderShader.renderStructures = renderStructures
    metalCrystalPolygonalPrismShader.renderDataSource  = renderDataSource
    metalCrystalPolygonalPrismShader.renderStructures = renderStructures
    
    metalEllipsoidShader.renderDataSource  = renderDataSource
    metalEllipsoidShader.renderStructures = renderStructures
    metalCylinderShader.renderDataSource  = renderDataSource
    metalCylinderShader.renderStructures = renderStructures
    metalPolygonalPrismShader.renderDataSource  = renderDataSource
    metalPolygonalPrismShader.renderStructures = renderStructures
    
    ellipsoidPrimitiveSelectionStripedShader.renderDataSource = renderDataSource
    ellipsoidPrimitiveSelectionStripedShader.renderStructures = renderStructures
    crystalEllipsoidPrimitiveSelectionStripedShader.renderDataSource = renderDataSource
    crystalEllipsoidPrimitiveSelectionStripedShader.renderStructures = renderStructures
    cylinderPrimitiveSelectionStripedShader.renderDataSource = renderDataSource
    cylinderPrimitiveSelectionStripedShader.renderStructures = renderStructures
    crystalCylinderPrimitiveSelectionStripedShader.renderDataSource = renderDataSource
    crystalCylinderPrimitiveSelectionStripedShader.renderStructures = renderStructures
    polygonalPrismPrimitiveSelectionStripedShader.renderDataSource = renderDataSource
    polygonalPrismPrimitiveSelectionStripedShader.renderStructures = renderStructures
    crystalPolygonalPrismPrimitiveSelectionStripedShader.renderDataSource = renderDataSource
    crystalPolygonalPrismPrimitiveSelectionStripedShader.renderStructures = renderStructures
    
    ellipsoidPrimitiveSelectionWorleyNoise3DShader.renderDataSource = renderDataSource
    ellipsoidPrimitiveSelectionWorleyNoise3DShader.renderStructures = renderStructures
    crystalEllipsoidPrimitiveSelectionWorleyNoise3DShader.renderDataSource = renderDataSource
    crystalEllipsoidPrimitiveSelectionWorleyNoise3DShader.renderStructures = renderStructures
    cylinderPrimitiveSelectionWorleyNoise3DShader.renderDataSource = renderDataSource
    cylinderPrimitiveSelectionWorleyNoise3DShader.renderStructures = renderStructures
    crystalCylinderPrimitiveSelectionWorleyNoise3DShader.renderDataSource = renderDataSource
    crystalCylinderPrimitiveSelectionWorleyNoise3DShader.renderStructures = renderStructures
    polygonalPrismPrimitiveSelectionWorleyNoise3DShader.renderDataSource = renderDataSource
    polygonalPrismPrimitiveSelectionWorleyNoise3DShader.renderStructures = renderStructures
    crystalPolygonalPrismPrimitiveSelectionWorleyNoise3DShader.renderDataSource = renderDataSource
    crystalPolygonalPrismPrimitiveSelectionWorleyNoise3DShader.renderStructures = renderStructures
    
    ellipsoidPrimitiveSelectionGlowShader.renderDataSource = renderDataSource
    ellipsoidPrimitiveSelectionGlowShader.renderStructures = renderStructures
    crystalEllipsoidPrimitiveSelectionGlowShader.renderDataSource = renderDataSource
    crystalEllipsoidPrimitiveSelectionGlowShader.renderStructures = renderStructures
    cylinderPrimitiveSelectionGlowShader.renderDataSource = renderDataSource
    cylinderPrimitiveSelectionGlowShader.renderStructures = renderStructures
    crystalCylinderPrimitiveSelectionGlowShader.renderDataSource = renderDataSource
    crystalCylinderPrimitiveSelectionGlowShader.renderStructures = renderStructures
    polygonalPrismPrimitiveSelectionGlowShader.renderDataSource = renderDataSource
    polygonalPrismPrimitiveSelectionGlowShader.renderStructures = renderStructures
    crystalPolygonalPrismPrimitiveSelectionGlowShader.renderDataSource = renderDataSource
    crystalPolygonalPrismPrimitiveSelectionGlowShader.renderStructures = renderStructures
  }
  
  
  // MARK: Reload
  // =====================================================================

  public func reloadData(device: MTLDevice, _ size: CGSize, maximumNumberOfSamples: Int)
  {
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
        self.textShader.renderTextFontString.append(structures.map{($0 as? RKRenderAtomSource)?.atomTextFont ?? ""})
      }
      
      setDataSources(renderDataSource: renderDataSource, renderStructures: renderStructures)
    }
    
    backgroundShader.reloadBackgroundImage(device: device)
    
    buildTextures(device: device, size: size, maximumNumberOfSamples: maximumNumberOfSamples)
    
    ambientOcclusionShader.buildAmbientOcclusionTextures(device: device)
    
    buildVertexBuffers(device: device)
    
    rebuildSelectionInstanceBuffers(device: device)
    
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
        self.textShader.renderTextFontString.append(structures.map{($0 as? RKRenderAtomSource)?.atomTextFont ?? ""})
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
    self.rebuildSelectionInstanceBuffers(device: device)
  }
  
  public func reloadRenderDataSelectedInternalBonds(device: MTLDevice)
  {
    
  }
  
  public func reloadRenderDataSelectedExternalBonds(device: MTLDevice)
  {
    
  }
  
  public func reloadRenderDataSelectedPrimitives(device: MTLDevice)
  {
    
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
    
    internalBondSelectionWorleyShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    internalBondSelectionGlowShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    internalBondSelectionStripedShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    externalBondSelectionWorleyShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    externalBondSelectionGlowShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    externalBondSelectionStripedShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    
    
    blurHorizontalShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    blurVerticalShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    quadShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    atomSelectionGlowPictureShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    blurHorizontalPictureShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    blurVerticalPictureShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    
    metalCrystalEllipsoidShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    metalCrystalCylinderShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    metalCrystalPolygonalPrismShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    metalEllipsoidShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    metalCylinderShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    metalPolygonalPrismShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    ellipsoidPrimitiveSelectionStripedShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    crystalEllipsoidPrimitiveSelectionStripedShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    cylinderPrimitiveSelectionStripedShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    crystalCylinderPrimitiveSelectionStripedShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    polygonalPrismPrimitiveSelectionStripedShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    crystalPolygonalPrismPrimitiveSelectionStripedShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    ellipsoidPrimitiveSelectionWorleyNoise3DShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    crystalEllipsoidPrimitiveSelectionWorleyNoise3DShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    cylinderPrimitiveSelectionWorleyNoise3DShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    crystalCylinderPrimitiveSelectionWorleyNoise3DShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    polygonalPrismPrimitiveSelectionWorleyNoise3DShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    crystalPolygonalPrismPrimitiveSelectionWorleyNoise3DShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    ellipsoidPrimitiveSelectionGlowShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    crystalEllipsoidPrimitiveSelectionGlowShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    cylinderPrimitiveSelectionGlowShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    crystalCylinderPrimitiveSelectionGlowShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    polygonalPrismPrimitiveSelectionGlowShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    crystalPolygonalPrismPrimitiveSelectionGlowShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
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
    
    atomSelectionShader.buildInstanceBuffers(device: device)
    
    atomSelectionWorleyShader.buildVertexBuffers(device: device)
    atomSelectionWorleyOrthographicImposterShader.buildVertexBuffers(device: device)
    atomSelectionWorleyPerspectiveImposterShader.buildVertexBuffers(device: device)
    
    atomSelectionStripedShader.buildVertexBuffers(device: device)
    atomSelectionStripedOrthographicImposterShader.buildVertexBuffers(device: device)
    atomSelectionStripedPerspectiveImposterShader.buildVertexBuffers(device: device)
    
    atomSelectionGlowShader.buildVertexBuffers(device: device)
    atomSelectionGlowOrthographicImposterShader.buildVertexBuffers(device: device)
    atomSelectionGlowPerspectiveImposterShader.buildVertexBuffers(device: device)
    
    internalBondSelectionShader.buildInstanceBuffers(device: device)
    externalBondSelectionShader.buildInstanceBuffers(device: device)
    
    internalBondSelectionWorleyShader.buildVertexBuffers(device: device)
    internalBondSelectionGlowShader.buildVertexBuffers(device: device)
    internalBondSelectionStripedShader.buildVertexBuffers(device: device)
    
    externalBondSelectionWorleyShader.buildVertexBuffers(device: device)
    externalBondSelectionGlowShader.buildVertexBuffers(device: device)
    externalBondSelectionStripedShader.buildVertexBuffers(device: device)
    
    blurHorizontalShader.buildVertexBuffers(device: device)
    blurVerticalShader.buildVertexBuffers(device: device)
  
    quadShader.buildVertexBuffers(device: device)
    
    atomSelectionGlowPictureShader.buildVertexBuffers(device: device)
    blurHorizontalPictureShader.buildVertexBuffers(device: device)
    blurVerticalPictureShader.buildVertexBuffers(device: device)
    
    metalCrystalEllipsoidShader.buildVertexBuffers(device: device)
    metalCrystalCylinderShader.buildVertexBuffers(device: device)
    metalCrystalPolygonalPrismShader.buildVertexBuffers(device: device)
    metalEllipsoidShader.buildVertexBuffers(device: device)
    metalCylinderShader.buildVertexBuffers(device: device)
    metalPolygonalPrismShader.buildVertexBuffers(device: device)
    
    // FIX
    ellipsoidPrimitiveSelectionStripedShader.buildVertexBuffers(device: device)
    crystalEllipsoidPrimitiveSelectionStripedShader.buildVertexBuffers(device: device)
    
    ellipsoidPrimitiveSelectionWorleyNoise3DShader.buildVertexBuffers(device: device)
    crystalEllipsoidPrimitiveSelectionWorleyNoise3DShader.buildVertexBuffers(device: device)
    
    ellipsoidPrimitiveSelectionGlowShader.buildVertexBuffers(device: device)
    crystalEllipsoidPrimitiveSelectionGlowShader.buildVertexBuffers(device: device)
  }
  
  public func rebuildSelectionInstanceBuffers(device: MTLDevice)
  {
    atomSelectionShader.buildInstanceBuffers(device: device)
    internalBondSelectionShader.buildInstanceBuffers(device: device)
    externalBondSelectionShader.buildInstanceBuffers(device: device)
    
    ellipsoidPrimitiveSelectionStripedShader.buildInstanceBuffers(device: device)
    crystalEllipsoidPrimitiveSelectionStripedShader.buildInstanceBuffers(device: device)
    cylinderPrimitiveSelectionStripedShader.buildInstanceBuffers(device: device)
    crystalCylinderPrimitiveSelectionStripedShader.buildInstanceBuffers(device: device)
    polygonalPrismPrimitiveSelectionStripedShader.buildInstanceBuffers(device: device)
    crystalPolygonalPrismPrimitiveSelectionStripedShader.buildInstanceBuffers(device: device)
    
    ellipsoidPrimitiveSelectionWorleyNoise3DShader.buildInstanceBuffers(device: device)
    crystalEllipsoidPrimitiveSelectionWorleyNoise3DShader.buildInstanceBuffers(device: device)
    cylinderPrimitiveSelectionWorleyNoise3DShader.buildInstanceBuffers(device: device)
    crystalCylinderPrimitiveSelectionWorleyNoise3DShader.buildInstanceBuffers(device: device)
    polygonalPrismPrimitiveSelectionWorleyNoise3DShader.buildInstanceBuffers(device: device)
    crystalPolygonalPrismPrimitiveSelectionWorleyNoise3DShader.buildInstanceBuffers(device: device)
    
    ellipsoidPrimitiveSelectionGlowShader.buildInstanceBuffers(device: device)
    crystalEllipsoidPrimitiveSelectionGlowShader.buildInstanceBuffers(device: device)
    cylinderPrimitiveSelectionGlowShader.buildInstanceBuffers(device: device)
    crystalCylinderPrimitiveSelectionGlowShader.buildInstanceBuffers(device: device)
    polygonalPrismPrimitiveSelectionGlowShader.buildInstanceBuffers(device: device)
    crystalPolygonalPrismPrimitiveSelectionGlowShader.buildInstanceBuffers(device: device)
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

  public func transformUniforms(maximumExtendedDynamicRangeColorComponentValue maximumEDRvalue: CGFloat, camera: RKCamera?) -> RKTransformationUniforms
  {
    if let camera: RKCamera = camera
    {
      let projectionMatrix = camera.projectionMatrix
      let viewMatrix = camera.modelViewMatrix
      
      return RKTransformationUniforms(projectionMatrix: projectionMatrix, viewMatrix: viewMatrix, bloomLevel: camera.bloomLevel, bloomPulse: camera.bloomPulse, maximumExtendedDynamicRangeColorComponentValue: maximumEDRvalue)
    }
    else
    {
      return RKTransformationUniforms(projectionMatrix: double4x4(), viewMatrix: double4x4(), bloomLevel: 1.0, bloomPulse: 1.0, maximumExtendedDynamicRangeColorComponentValue: maximumEDRvalue)
    }
  }
  
  
  // MARK: Rendering
  // =====================================================================

  public func renderSceneWithEncoder(_ commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, size: CGSize, renderQuality: RKRenderQuality, camera: RKCamera?)
  {
    let commandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
    commandEncoder.label = "Scene command encoder"
    commandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
    commandEncoder.setCullMode(MTLCullMode.back)
    commandEncoder.setFrontFacing(MTLWinding.clockwise)
    
    backgroundShader.renderBackgroundWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, size: size)
    
    self.isosurfaceShader.renderOpaqueIsosurfaceWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, isosurfaceUniformBuffers: isosurfaceUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    
    
    switch(renderQuality)
    {
    case .high, .picture:
      self.atomShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    case .medium, .low:
      if let camera: RKCamera = camera
      {
        switch(camera.frustrumType)
        {
        case RKCamera.FrustrumType.orthographic:
          self.atomOrthographicImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomShader.instanceBuffer, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
        case RKCamera.FrustrumType.perspective:
          self.atomPerspectiveImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomShader.instanceBuffer, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
        }
      }
    }
   
    self.metalCrystalEllipsoidShader.renderOpaqueWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    self.metalCrystalCylinderShader.renderOpaqueWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    self.metalCrystalPolygonalPrismShader.renderOpaqueWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    self.metalEllipsoidShader.renderOpaqueWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    self.metalCylinderShader.renderOpaqueWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    self.metalPolygonalPrismShader.renderOpaqueWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    
  
    
    self.internalBondShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    
    self.externalBondShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    
    self.unitCellCylinderShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    self.unitCellSphereShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    
    self.boundingBoxCylinderShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, lightUniformBuffers: lightUniformBuffers, size: size)
    self.boundingBoxSphereShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, lightUniformBuffers: lightUniformBuffers, size: size)
    
    
    if let camera: RKCamera = camera
    {
      // draw bonds before atoms
      self.internalBondSelectionWorleyShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceRenderer: internalBondSelectionShader, bondShader: internalBondShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      self.internalBondSelectionStripedShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceRenderer: internalBondSelectionShader, bondShader: internalBondShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      
      self.externalBondSelectionWorleyShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceRenderer: externalBondSelectionShader, bondShader: externalBondShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      self.externalBondSelectionStripedShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceRenderer: externalBondSelectionShader, bondShader: externalBondShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      
      
     
      
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
    
    
    if let camera: RKCamera = camera
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
    
  
    self.metalCrystalEllipsoidShader.renderTransparentWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    self.metalCrystalCylinderShader.renderTransparentWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    self.metalCrystalPolygonalPrismShader.renderTransparentWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    self.metalEllipsoidShader.renderTransparentWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    self.metalCylinderShader.renderTransparentWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    self.metalPolygonalPrismShader.renderTransparentWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
      
    
    self.isosurfaceShader.renderTransparentIsosurfacesWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, isosurfaceUniformBuffers: isosurfaceUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    
    if let _: RKCamera = camera
    {
      self.ellipsoidPrimitiveSelectionStripedShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      self.crystalEllipsoidPrimitiveSelectionStripedShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      self.cylinderPrimitiveSelectionStripedShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, metalCylinderShader: metalCylinderShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      self.crystalCylinderPrimitiveSelectionStripedShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, metalCrystalCylinderShader: metalCrystalCylinderShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      self.polygonalPrismPrimitiveSelectionStripedShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, metalPolygonalPrismShader: metalPolygonalPrismShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      self.crystalPolygonalPrismPrimitiveSelectionStripedShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, metalCrystalPolygonalPrismShader: metalCrystalPolygonalPrismShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
         
      self.ellipsoidPrimitiveSelectionWorleyNoise3DShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      self.crystalEllipsoidPrimitiveSelectionWorleyNoise3DShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      self.cylinderPrimitiveSelectionWorleyNoise3DShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, metalCylinderShader: metalCylinderShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      self.crystalCylinderPrimitiveSelectionWorleyNoise3DShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, metalCrystalCylinderShader: metalCrystalCylinderShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      self.polygonalPrismPrimitiveSelectionWorleyNoise3DShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, metalPolygonalPrismShader: metalPolygonalPrismShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      self.crystalPolygonalPrismPrimitiveSelectionWorleyNoise3DShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, metalCrystalPolygonalPrismShader: metalCrystalPolygonalPrismShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    }
    
    commandEncoder.endEncoding()
  }
  
  func pickingOffScreen(commandBuffer: MTLCommandBuffer, frameUniformBuffer: MTLBuffer, size: CGSize)
  {
    pickingShader.renderPickingTextureWithEncoder(commandBuffer,
                                                  renderPassDescriptor: pickingShader.renderPassDescriptor,
                                                  atomShader: atomShader,
                                                  atomOrthographicImposterShader: atomOrthographicImposterShader,
                                                  internalBondShader: internalBondShader,
                                                  externalBondShader: externalBondShader,
                                                  crystalEllipsoidPrimitiveShader: metalCrystalEllipsoidShader,
                                                  ellipsoidPrimitiveShader: metalEllipsoidShader,
                                                  crystalCylinderPrimitiveShader: metalCrystalCylinderShader,
                                                  cylinderPrimitiveShader: metalCylinderShader,
                                                  crystalPolygonalPrismPrimitiveShader: metalCrystalPolygonalPrismShader,
                                                  polygonalPrismPrimitiveShader: metalPolygonalPrismShader,
                                                  frameUniformBuffer: frameUniformBuffer,
                                                  structureUniformBuffers: structureUniformBuffers, size: size)
  }
  
  func drawOffScreen(commandBuffer: MTLCommandBuffer, frameUniformBuffer: MTLBuffer, size: CGSize, renderQuality: RKRenderQuality, camera: RKCamera?)
  {
    renderSceneWithEncoder(commandBuffer, renderPassDescriptor: backgroundShader.sceneRenderPassDescriptor, frameUniformBuffer: frameUniformBuffer, size: size, renderQuality: renderQuality, camera: camera)
    
    if let commandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor)
    {
      switch(renderQuality)
      {
      case .high, .picture:
        atomSelectionGlowShader.renderWithEncoder(commandEncoder, instanceBuffer: atomSelectionShader.instanceBuffer, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      case .medium, .low:
        if let camera: RKCamera = camera
        {
        switch(camera.frustrumType)
        {
        case RKCamera.FrustrumType.orthographic:
          atomSelectionGlowOrthographicImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
        case RKCamera.FrustrumType.perspective:
          atomSelectionGlowPerspectiveImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
          }
        }
      }
      
      internalBondSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, instanceRenderer: internalBondSelectionShader, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      externalBondSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, instanceRenderer: externalBondSelectionShader, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      
      
      ellipsoidPrimitiveSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      crystalEllipsoidPrimitiveSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      
      cylinderPrimitiveSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, metalCylinderShader: metalCylinderShader, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      crystalCylinderPrimitiveSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, metalCrystalCylinderShader: metalCrystalCylinderShader, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      
      polygonalPrismPrimitiveSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, metalPolygonalPrismShader: metalPolygonalPrismShader, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      crystalPolygonalPrismPrimitiveSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, metalCrystalPolygonalPrismShader: metalCrystalPolygonalPrismShader, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      
      commandEncoder.endEncoding()
    }
    
    blurHorizontalShader.renderWithEncoder(commandBuffer, renderPassDescriptor: blurHorizontalShader.blurHorizontalRenderPassDescriptor, texture: atomSelectionGlowShader.atomSelectionGlowResolveTexture, frameUniformBuffer: frameUniformBuffer, size: size)
    
    blurVerticalShader.renderWithEncoder(commandBuffer, renderPassDescriptor: blurVerticalShader.blurVerticalRenderPassDescriptor, texture: blurHorizontalShader.blurHorizontalTexture, frameUniformBuffer: frameUniformBuffer, size: size)
  }
  
  func drawOnScreen(commandBuffer: MTLCommandBuffer, renderPass: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, size: CGSize)
  {
    quadShader.renderWithEncoder(commandBuffer, renderPass: renderPass, frameUniformBuffer: frameUniformBuffer, sceneResolveTexture: backgroundShader.sceneResolveTexture, blurVerticalTexture: blurVerticalShader.blurVerticalTexture, size: size)
  }
  
  public func drawSceneToTexture(device: MTLDevice, size: NSSize, imageQuality: RKImageQuality, maximumNumberOfSamples: Int, camera: RKCamera?, renderQuality: RKRenderQuality) -> Data
  {
    if let _: RKRenderDataSource = renderDataSource
    {
      var uniforms: RKTransformationUniforms = self.transformUniforms(maximumExtendedDynamicRangeColorComponentValue: 1.0, camera: camera)
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
        renderSceneWithEncoder(commandBuffer, renderPassDescriptor: sceneRenderPassDescriptor, frameUniformBuffer: frameUniformBuffer, size: size, renderQuality: renderQuality, camera: camera)
      
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


