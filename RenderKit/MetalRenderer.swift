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

#if os(macOS)
import AppKit
#else
import UIKit
#endif
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
  
  var globalAxesSystemShader: MetalGlobalAxesSystemShader = MetalGlobalAxesSystemShader()
  var localAxesShader: MetalLocalAxesShader = MetalLocalAxesShader()
  
  var atomShader: MetalAtomShader = MetalAtomShader()
  var atomOrthographicImposterShader: MetalAtomOrthographicImposterShader = MetalAtomOrthographicImposterShader()
  var atomPerspectiveImposterShader: MetalAtomPerspectiveImposterShader = MetalAtomPerspectiveImposterShader()
  
  var internalBondShader: MetalInternalBondShader = MetalInternalBondShader()
  var externalBondShader: MetalExternalBondShader = MetalExternalBondShader()
  
  var unitCellCylinderShader: MetalUnitCellCylinderShader = MetalUnitCellCylinderShader()
  var unitCellSphereShader: MetalUnitCellSphereShader = MetalUnitCellSphereShader()
  
  var boundingBoxCylinderShader: MetalBoundingBoxCylinderShader = MetalBoundingBoxCylinderShader()
  var boundingBoxSphereShader: MetalBoundingBoxSphereShader = MetalBoundingBoxSphereShader()
  
  var isosurfaceShader: MetalEnergyIsosurfaceShader = MetalEnergyIsosurfaceShader()
  var ribbonShader: MetalRibbonShader = MetalRibbonShader()
  var ribbonSelectionShader: MetalRibbonSelectionShader = MetalRibbonSelectionShader()
  var volumeRenderedSurfaceShader: MetalEnergyVolumeRenderedSurfaceShader = MetalEnergyVolumeRenderedSurfaceShader()
  
  public var ribbonAODebugMode: RibbonAODebugMode
  {
    get {ribbonShader.aoDebugMode}
    set {ribbonShader.aoDebugMode = newValue}
  }

    
  /// Clears the cueing mask behind the geometry that writes it. See `renderSceneWithEncoder`.
  var clearingDepthState: MTLDepthStencilState! = nil

  var textShader: MetalTextShader = MetalTextShader()
  
  var pickingShader: MetalPickingShader = MetalPickingShader()
  
  var ambientOcclusionShader: MetalAmbientOcclusionShader = MetalAmbientOcclusionShader()
  
  public var pathTracerShader: MetalPathTracerShader = MetalPathTracerShader()

  /// How the last picture was rendered. The picture and movie services run out of process,
  /// where the log window does not exist, so they hand this back to the application.
  private(set) public var lastPictureDiagnostic: String = "no picture has been rendered"
  
  var measurementShader: MetalMeasurementShader = MetalMeasurementShader()
  var measurementOrthographicImposterShader: MetalMeasurementOrthographicImposterShader = MetalMeasurementOrthographicImposterShader()
  var measurementPerspectiveImposterShader: MetalMeasurementPerspectiveImposterShader = MetalMeasurementPerspectiveImposterShader()
  
  var atomSelectionShader: MetalAtomSelectionShader = MetalAtomSelectionShader()
  
  var atomSelectionWorleyOrthographicImposterShader: MetalAtomSelectionWorleyNoise3DOrthographicImposterShader = MetalAtomSelectionWorleyNoise3DOrthographicImposterShader()
  var atomSelectionWorleyPerspectiveImposterShader: MetalAtomSelectionWorleyNoise3DPerspectiveImposterShader = MetalAtomSelectionWorleyNoise3DPerspectiveImposterShader()
  
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
  var globalAxesUniformBuffers: MTLBuffer! = nil
  
  public weak var renderDataSource: RKRenderDataSource?
  var renderStructures: [[RKRenderObject]] = [[]]
  
  
  public init()
  {
  }
  
  // initialize Renderer for creating pictures
  public init(device: MTLDevice, size: CGSize, dataSource: RKRenderDataSource, camera: RKCamera)
  {
    let bundle: Bundle = Bundle(for: MetalRenderer.self)
    
    if let file: String = bundle.path(forResource: "default", ofType: "metallib"),
       let defaultLibrary = try? device.makeLibrary(filepath: file)
    {
      var maximumNumberOfSamples: Int = 1
      // detect the maximum MSAA
      for i in [32,16,8,4,2,1]
      {
        if (device.supportsTextureSampleCount(i))
        {
          maximumNumberOfSamples = i
          break
        }
      }
      
      
      self.buildPipeLines(device: device, defaultLibrary, maximumNumberOfSamples: maximumNumberOfSamples)
      self.backgroundShader.buildPermanentTextures(device: device)
      
      self.buildTextures(device: device, size: size, maximumNumberOfSamples: maximumNumberOfSamples)
      
      self.renderDataSource = dataSource
      self.reloadData(device: device, size, maximumNumberOfSamples: maximumNumberOfSamples)
      
      self.buildLightUniforms(device: device)
      self.buildStructureUniforms(device: device)
      self.buildIsosurfaceUniforms(device: device)
      self.buildGlobalAxesUniforms(device: device)
    }
  }
  
  func setDataSources(renderDataSource: RKRenderDataSource, renderStructures: [[RKRenderObject]])
  {
    self.renderStructures = renderStructures
    
    backgroundShader.renderDataSource = renderDataSource
    
    globalAxesSystemShader.renderDataSource = renderDataSource
    globalAxesSystemShader.renderStructures = renderStructures
    
    localAxesShader.renderDataSource = renderDataSource
    localAxesShader.renderStructures = renderStructures
    
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
    
    ribbonShader.renderDataSource = renderDataSource
    ribbonShader.renderStructures = renderStructures
    
    ribbonSelectionShader.renderDataSource = renderDataSource
    ribbonSelectionShader.renderStructures = renderStructures
    
    volumeRenderedSurfaceShader.renderDataSource = renderDataSource
    volumeRenderedSurfaceShader.renderStructures = renderStructures
    
    textShader.renderDataSource = renderDataSource
    textShader.renderStructures = renderStructures
    
    pickingShader.renderDataSource = renderDataSource
    pickingShader.renderStructures = renderStructures
    
    ambientOcclusionShader.renderDataSource = renderDataSource
    ambientOcclusionShader.renderStructures = renderStructures
    
    pathTracerShader.renderDataSource = renderDataSource
    pathTracerShader.renderStructures = renderStructures
    // the acceleration structures bake the geometry of the structures they were built from
    pathTracerShader.invalidateGeometry()
    
    measurementShader.renderDataSource = renderDataSource
    measurementShader.renderStructures = renderStructures
    measurementOrthographicImposterShader.renderDataSource = renderDataSource
    measurementOrthographicImposterShader.renderStructures = renderStructures
    measurementPerspectiveImposterShader.renderDataSource = renderDataSource
    measurementPerspectiveImposterShader.renderStructures = renderStructures
    
    atomSelectionShader.renderDataSource = renderDataSource
    atomSelectionShader.renderStructures = renderStructures
    
    atomSelectionWorleyOrthographicImposterShader.renderDataSource = renderDataSource
    atomSelectionWorleyOrthographicImposterShader.renderStructures = renderStructures
    atomSelectionWorleyPerspectiveImposterShader.renderDataSource = renderDataSource
    atomSelectionWorleyPerspectiveImposterShader.renderStructures = renderStructures
    
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
    var renderStructures: [[RKRenderObject]] = [[]]
    if let renderDataSource: RKRenderDataSource = renderDataSource
    {
      renderStructures = []
      self.textShader.renderTextFontString = []
      for i in 0..<renderDataSource.numberOfScenes
      {
        let structures: [RKRenderObject] = renderDataSource.renderStructuresForScene(i)
        renderStructures.append(structures)
        self.textShader.renderTextFontString.append(structures.map{($0 as? RKRenderAtomSource)?.atomTextFont ?? ""})
      }
      
      setDataSources(renderDataSource: renderDataSource, renderStructures: renderStructures)
    }
    
    for structures in renderStructures
    {
      for structure in structures
      {
        if let ribbonSource: RKRenderRibbonSource = structure as? RKRenderRibbonSource,
           ribbonSource.drawRibbon
        {
          ribbonSource.rebuildRibbonMesh()
        }
      }
    }
    
    backgroundShader.reloadBackgroundImage(device: device)
    
    buildTextures(device: device, size: size, maximumNumberOfSamples: maximumNumberOfSamples)
    
    buildVertexBuffers(device: device)
    
    rebuildSelectionInstanceBuffers(device: device)
    
    buildStructureUniforms(device: device)
    buildGlobalAxesUniforms(device: device)
    buildIsosurfaceUniforms(device: device)
    buildLightUniforms(device: device)
  }
  
  public func reloadRenderData(device: MTLDevice, rebuildRibbonMesh: Bool = true)
  {
    reloadRenderDataFromSource(device: device, rebuildRibbonMesh: rebuildRibbonMesh)
  }
  
  /// Refreshes render structures and GPU buffers after atom-tree visibility changes only.
  public func reloadRenderDataForVisibility(device: MTLDevice)
  {
    reloadRenderDataFromSource(device: device, rebuildRibbonMesh: false)
  }
  
  private func reloadRenderDataFromSource(device: MTLDevice, rebuildRibbonMesh: Bool)
  {
    // makes sure the rendering data is consistent
    var renderStructures: [[RKRenderObject]] = []
    self.textShader.renderTextFontString = []
    
    if let renderDataSource: RKRenderDataSource = renderDataSource
    {
      renderStructures = []
      for i in 0..<renderDataSource.numberOfScenes
      {
        let structures: [RKRenderObject] = renderDataSource.renderStructuresForScene(i)
        renderStructures.append(structures)
        self.textShader.renderTextFontString.append(structures.map{($0 as? RKRenderAtomSource)?.atomTextFont ?? ""})
      }
      
      setDataSources(renderDataSource: renderDataSource, renderStructures: renderStructures)
    }
    
    if rebuildRibbonMesh
    {
      for structures in renderStructures
      {
        for structure in structures
        {
          if let ribbonSource: RKRenderRibbonSource = structure as? RKRenderRibbonSource,
             ribbonSource.drawRibbon
          {
            ribbonSource.rebuildRibbonMesh()
          }
        }
      }
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
  
  public func reloadGlobalAxesSystem(device: MTLDevice)
  {
    globalAxesSystemShader.buildVertexBuffers(device: device)
    
    buildGlobalAxesUniforms(device: device)
  }
  
  public func reloadLocalAxesSystem(device: MTLDevice)
  {
    localAxesShader.buildVertexBuffers(device: device)    
  }

  // MARK: Build pipelines
  // =====================================================================
  
  public func buildPipeLines(device: MTLDevice, _ library: MTLLibrary, maximumNumberOfSamples: Int)
  {
    clearingDepthState = RKEdgeCueing.clearingDepthStencilState(device: device)

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
    
    globalAxesSystemShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    localAxesShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    atomOrthographicImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    atomPerspectiveImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    internalBondShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    externalBondShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    unitCellCylinderShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    unitCellSphereShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    boundingBoxCylinderShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    boundingBoxSphereShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    isosurfaceShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    ribbonShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    ribbonSelectionShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    volumeRenderedSurfaceShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    pickingShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    textShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    ambientOcclusionShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    pathTracerShader.buildPipeLine(device: device, library: library)
    
    measurementShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    measurementOrthographicImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    measurementPerspectiveImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    atomSelectionGlowOrthographicImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    atomSelectionGlowPerspectiveImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
    atomSelectionWorleyOrthographicImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    atomSelectionWorleyPerspectiveImposterShader.buildPipeLine(device: device, library: library, vertexDescriptor: vertexDescriptor, maximumNumberOfSamples: maximumNumberOfSamples)
    
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
  
  // Used also on resizing the view
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
    
    globalAxesSystemShader.buildVertexBuffers(device: device)
    localAxesShader.buildVertexBuffers(device: device)
    
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
    isosurfaceShader.buildVertexBuffers()
    ribbonShader.buildVertexBuffers(device: device)
    volumeRenderedSurfaceShader.buildVertexBuffers(device: device)
    
    textShader.buildVertexBuffers(device: device)
    
    measurementShader.buildVertexBuffers(device: device)
    measurementOrthographicImposterShader.buildVertexBuffers(device: device)
    measurementPerspectiveImposterShader.buildVertexBuffers(device: device)
    
    atomSelectionShader.buildInstanceBuffers(device: device)
    
    atomSelectionWorleyOrthographicImposterShader.buildVertexBuffers(device: device)
    atomSelectionWorleyPerspectiveImposterShader.buildVertexBuffers(device: device)
    
    atomSelectionStripedOrthographicImposterShader.buildVertexBuffers(device: device)
    atomSelectionStripedPerspectiveImposterShader.buildVertexBuffers(device: device)
    
    atomSelectionGlowOrthographicImposterShader.buildVertexBuffers(device: device)
    atomSelectionGlowPerspectiveImposterShader.buildVertexBuffers(device: device)
    
    internalBondSelectionShader.buildInstanceBuffers(device: device)
    externalBondSelectionShader.buildInstanceBuffers(device: device)
    
    blurHorizontalShader.buildVertexBuffers(device: device)
    blurVerticalShader.buildVertexBuffers(device: device)
  
    quadShader.buildVertexBuffers(device: device)
    
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
      
      /*
      var index: Int  = 0
      for i in 0..<project.numberOfScenes
      {
        let structures: [RKRenderObject] = project.renderStructuresForScene(i)
        for (j,structure) in structures.enumerated()
        {
          structureUniforms[index] = RKStructureUniforms(sceneIdentifier: i, movieIdentifier: j, structure: structure)
          isosurfaceUniforms[index] = RKIsosurfaceUniforms(structure: structure)
          index += 1
        }
      }*/
      let ambientOcclusionStrength: Float = Float(min(max(project.renderAmbientOcclusionStrength, 0.0), 1.0))

      for (i,structure) in project.renderStructures.enumerated()
      {
        structureUniforms[i] = RKStructureUniforms(structureIdentifier: i, structure: structure)
        structureUniforms[i].ambientOcclusionStrength = ambientOcclusionStrength
        isosurfaceUniforms[i] = RKIsosurfaceUniforms(structure: structure)
      }
      
      structureUniformBuffers = device.makeBuffer(bytes: structureUniforms, length: MemoryLayout<RKStructureUniforms>.stride * max(structureUniforms.count,1), options:RKMetal.hostStorage)
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
        let structures: [RKRenderObject] = project.renderStructuresForScene(i)
        for structure in structures
        {
          isosurfaceUniforms[index] = RKIsosurfaceUniforms(structure: structure)
          index += 1
        }
      }
      
      if(!isosurfaceUniforms.isEmpty)
      {
        isosurfaceUniformBuffers = device.makeBuffer(bytes: isosurfaceUniforms, length: MemoryLayout<RKIsosurfaceUniforms>.stride * isosurfaceUniforms.count, options:RKMetal.hostStorage)
      }
    }
  }

  
  public func buildLightUniforms(device: MTLDevice)
  {
    if let project: RKRenderDataSource = renderDataSource
    {
      let lightUniforms: RKLightUniforms = RKLightUniforms(project: project)
      let bytes: [UInt8] = lightUniforms.packed()
      lightUniformBuffers = device.makeBuffer(bytes: bytes, length: bytes.count, options:RKMetal.hostStorage)
    }
  }
  
  public func buildGlobalAxesUniforms(device: MTLDevice)
  {
    if let project: RKRenderDataSource = renderDataSource
    {
      var globalAxesUniforms: RKGlobalAxesUniforms = RKGlobalAxesUniforms(project: project)
      globalAxesUniformBuffers = device.makeBuffer(bytes: &globalAxesUniforms, length: MemoryLayout<RKGlobalAxesUniforms>.stride, options:RKMetal.hostStorage)
    }
  }

  /// `pathTracing` says where the edge cueing is to look for the depth of the finished scene, the
  /// rasterizer's depth attachment holding no molecular geometry when the tracer draws it.
  public func transformUniforms(maximumExtendedDynamicRangeColorComponentValue maximumEDRvalue: CGFloat, camera: RKCamera?, pathTracing: Bool = false) -> RKTransformationUniforms
  {
    if let project: RKRenderDataSource = renderDataSource,
       let camera: RKCamera = camera
    {
      let projectionMatrix = camera.projectionMatrix
      let viewMatrix = camera.modelViewMatrix
      let modelMatrix = camera.modelMatrix
      let totalAxesSize: Double = project.renderAxes.totalAxesSize
      let axesProjectionMatrix = camera.axesProjectionMatrix(axesSize: totalAxesSize)
      let axesViewMatrix = camera.axesModelViewMatrix
      let isOrthographic = camera.isOrthographic
      
      var uniforms: RKTransformationUniforms = RKTransformationUniforms(camera: camera, projectionMatrix: projectionMatrix, viewMatrix: viewMatrix, modelMatrix: modelMatrix,  axesProjectionMatrix: axesProjectionMatrix, axesViewMatrix: axesViewMatrix, isOrthographic: isOrthographic, bloomLevel: camera.bloomLevel, bloomPulse: camera.bloomPulse, maximumExtendedDynamicRangeColorComponentValue: maximumEDRvalue)
      uniforms.edgeCueing = RKEdgeCueing.parameters
      uniforms.edgeCueingUsesTracedDepth = pathTracing ? 1.0 : 0.0
      return uniforms
    }
    else
    {
      return RKTransformationUniforms(camera: nil, projectionMatrix: double4x4(), viewMatrix: double4x4(), modelMatrix: double4x4(), axesProjectionMatrix: double4x4(), axesViewMatrix: double4x4(), isOrthographic: true, bloomLevel: 1.0, bloomPulse: 1.0, maximumExtendedDynamicRangeColorComponentValue: maximumEDRvalue)
    }
  }
  
  
  // MARK: Rendering
  // =====================================================================

  /// When `suppressMolecularGeometry` is set, the atom, bond and ribbon passes (and their
  /// selection overlays) are skipped because the path tracer draws that geometry instead.
  /// Everything else — background, isosurfaces, unit cell, primitives, text, axes — is
  /// still rasterized, and its depth is what the path-traced result is composited against.
  public func renderSceneWithEncoder(_ commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, size: CGSize, renderQuality: RKRenderQuality, camera: RKCamera?, suppressMolecularGeometry: Bool = false)
  {
    // Fast per-pixel imposters while interacting; still frames and pictures stay per-sample. Glow and
    // selection depth-test per sample against the scene, so the per-pixel path has to leave the same
    // kind of MSAA depth behind — that is what alpha-to-coverage on those pipelines is for.
    RKMetal.perSampleImposterShading = (renderQuality == .high || renderQuality == .picture)

    // Falls back to the all-lit texel when no mask was traced, so the molecular shaders can read it
    // unconditionally rather than branching on whether shadows are on.
    buildAllLitShadowMask(device: commandBuffer.device)
    guard let shadowMask: MTLTexture = activeShadowMask else {return}

    let commandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
    commandEncoder.label = "Scene command encoder"
    commandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
    commandEncoder.setCullMode(MTLCullMode.back)
    commandEncoder.setFrontFacing(MTLWinding.clockwise)
    
    backgroundShader.renderBackgroundWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, size: size)
    
    self.isosurfaceShader.renderOpaqueIsosurfaceWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, isosurfaceUniformBuffers: isosurfaceUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    
    if !suppressMolecularGeometry
    {
      self.ribbonShader.renderWithEncoder(commandEncoder, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.ribbonTextures, shadowMask: shadowMask, size: size)

    // Only the atoms, the bonds and the ribbons claim the cueing mask. Everything after them clears it
    // where it draws in front, so that a contour never appears along a unit cell edge, not even where
    // that edge crosses an atom. See `clearingDepthStencilState` on RKEdgeCueing.
    commandEncoder.setDepthStencilState(clearingDepthState)
    commandEncoder.setStencilReferenceValue(0)
    }
    
    self.localAxesShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    
    
    if !suppressMolecularGeometry
    {
      if let camera, camera.frustrumType == .perspective
      {
        self.atomPerspectiveImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomShader.instanceBuffer, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, shadowMask: shadowMask, size: size)
      }
      else
      {
        self.atomOrthographicImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomShader.instanceBuffer, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, shadowMask: shadowMask, size: size)
      }

    // Only the atoms, the bonds and the ribbons claim the cueing mask. Everything after them clears it
    // where it draws in front, so that a contour never appears along a unit cell edge, not even where
    // that edge crosses an atom. See `clearingDepthStencilState` on RKEdgeCueing.
    commandEncoder.setDepthStencilState(clearingDepthState)
    commandEncoder.setStencilReferenceValue(0)
    }
   
    self.metalCrystalEllipsoidShader.renderOpaqueWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    self.metalCrystalCylinderShader.renderOpaqueWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    self.metalCrystalPolygonalPrismShader.renderOpaqueWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    self.metalEllipsoidShader.renderOpaqueWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    self.metalCylinderShader.renderOpaqueWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    self.metalPolygonalPrismShader.renderOpaqueWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    
    if !suppressMolecularGeometry
    {
      self.internalBondShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.bondTextures, shadowMask: shadowMask, size: size)
      
      self.externalBondShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.bondTextures, shadowMask: shadowMask, size: size)

    // Only the atoms, the bonds and the ribbons claim the cueing mask. Everything after them clears it
    // where it draws in front, so that a contour never appears along a unit cell edge, not even where
    // that edge crosses an atom. See `clearingDepthStencilState` on RKEdgeCueing.
    commandEncoder.setDepthStencilState(clearingDepthState)
    commandEncoder.setStencilReferenceValue(0)
    }
    
    self.unitCellCylinderShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    self.unitCellSphereShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
    
    self.boundingBoxCylinderShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, lightUniformBuffers: lightUniformBuffers, size: size)
    self.boundingBoxSphereShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, lightUniformBuffers: lightUniformBuffers, size: size)
    
    
    if let camera: RKCamera = camera, !suppressMolecularGeometry
    {
      // draw bonds before atoms
      self.internalBondSelectionWorleyShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceRenderer: internalBondSelectionShader, bondShader: internalBondShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      self.internalBondSelectionStripedShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceRenderer: internalBondSelectionShader, bondShader: internalBondShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      
      self.externalBondSelectionWorleyShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceRenderer: externalBondSelectionShader, bondShader: externalBondShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      self.externalBondSelectionStripedShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceRenderer: externalBondSelectionShader, bondShader: externalBondShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      
      self.ribbonSelectionShader.renderOverlayWithEncoder(commandEncoder,
                                                          ribbonShader: ribbonShader,
                                                          frameUniformBuffer: frameUniformBuffer,
                                                          structureUniformBuffers: structureUniformBuffers,
                                                          lightUniformBuffers: lightUniformBuffers,
                                                          size: size)
      
      
     
      
      if camera.frustrumType == .orthographic
      {
        self.atomSelectionWorleyOrthographicImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, atomOrthographicImposterShader: atomOrthographicImposterShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
        self.atomSelectionStripedOrthographicImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, atomOrthographicImposterShader: atomOrthographicImposterShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      }
      else
      {
        self.atomSelectionWorleyPerspectiveImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, atomPerspectiveImposterShader: atomPerspectiveImposterShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
        self.atomSelectionStripedPerspectiveImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, atomPerspectiveImposterShader: atomPerspectiveImposterShader, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
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
    
    commandEncoder.endEncoding()
  }
  
  // Transparent objects must be composited back-to-front (farthest from the camera first),
  // otherwise the blending between overlapping transparent movies is incorrect.
  // Returns (sceneIndex, movieIndex, structureIndex) tuples where structureIndex is the flat
  // index used as offset into the structure/isosurface uniform buffers.
  func backToFrontRenderOrder(camera: RKCamera?) -> [(sceneIndex: Int, movieIndex: Int, structureIndex: Int)]
  {
    var items: [(sceneIndex: Int, movieIndex: Int, structureIndex: Int, depth: Double)] = []
    var index: Int = 0
    for i in 0..<self.renderStructures.count
    {
      let structures: [RKRenderObject] = self.renderStructures[i]
      for (j, structure) in structures.enumerated()
      {
        var depth: Double = 0.0
        if let camera = camera
        {
          let center: SIMD3<Double> = structure.cell.boundingBox.center
          let modelMatrix: double4x4 = double4x4(transformation: double4x4(simd_quatd: structure.orientation), aroundPoint: center, withTranslation: structure.origin)
          let worldCenter: SIMD4<Double> = modelMatrix * SIMD4<Double>(x: center.x, y: center.y, z: center.z, w: 1.0)
          let viewCenter: SIMD4<Double> = camera.modelViewMatrix * worldCenter
          depth = viewCenter.z
        }
        items.append((sceneIndex: i, movieIndex: j, structureIndex: index, depth: depth))
        index = index + 1
      }
    }
    // the camera looks along the negative z-axis in view space, so the most negative
    // view-space z is farthest away and must be drawn first
    return items.sorted{$0.depth < $1.depth}.map{(sceneIndex: $0.sceneIndex, movieIndex: $0.movieIndex, structureIndex: $0.structureIndex)}
  }
  
  public func renderSceneVolumeRenderedSurfacesWithEncoder(_ commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, size: CGSize, renderQuality: RKRenderQuality, camera: RKCamera?)
  {
    let commandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
    commandEncoder.label = "Scene volume surface command encoder"
    commandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
    commandEncoder.setCullMode(MTLCullMode.back)
    commandEncoder.setFrontFacing(MTLWinding.clockwise)
    
    for item in backToFrontRenderOrder(camera: camera)
    {
      self.volumeRenderedSurfaceShader.renderVolumeRenderedSurfacesWithEncoder(commandEncoder, sceneIndex: item.sceneIndex, movieIndex: item.movieIndex, structureIndex: item.structureIndex, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, isosurfaceUniformBuffers: isosurfaceUniformBuffers, lightUniformBuffers: lightUniformBuffers, depthTexture: self.backgroundShader.sceneResolvedDepthTexture, size: size)
    }
    
    commandEncoder.endEncoding()
  }
  
  public func renderSceneTransparentWithEncoder(_ commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, size: CGSize, renderQuality: RKRenderQuality, camera: RKCamera?)
  {
    let commandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
    commandEncoder.label = "Scene transparent command encoder"
    commandEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(size.width), height: Double(size.height), znear: 0.0, zfar: 1.0))
    commandEncoder.setCullMode(MTLCullMode.back)
    commandEncoder.setFrontFacing(MTLWinding.clockwise)
    
    // Draw all transparent objects back-to-front per structure (movie), interleaving the
    // shader types, so that overlapping transparent objects from different movies blend correctly.
    for item in backToFrontRenderOrder(camera: camera)
    {
      self.volumeRenderedSurfaceShader.renderVolumeRenderedVolumetricDataWithEncoder(commandEncoder, sceneIndex: item.sceneIndex, movieIndex: item.movieIndex, structureIndex: item.structureIndex, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, isosurfaceUniformBuffers: isosurfaceUniformBuffers, lightUniformBuffers: lightUniformBuffers, depthTexture: self.backgroundShader.sceneResolvedDepthTexture, size: size)
      
      self.isosurfaceShader.renderTransparentIsosurfacesWithEncoder(commandEncoder, sceneIndex: item.sceneIndex, movieIndex: item.movieIndex, structureIndex: item.structureIndex, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, isosurfaceUniformBuffers: isosurfaceUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      
      self.metalCrystalEllipsoidShader.renderTransparentWithEncoder(commandEncoder, sceneIndex: item.sceneIndex, movieIndex: item.movieIndex, structureIndex: item.structureIndex, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
      self.metalCrystalCylinderShader.renderTransparentWithEncoder(commandEncoder, sceneIndex: item.sceneIndex, movieIndex: item.movieIndex, structureIndex: item.structureIndex, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
      self.metalCrystalPolygonalPrismShader.renderTransparentWithEncoder(commandEncoder, sceneIndex: item.sceneIndex, movieIndex: item.movieIndex, structureIndex: item.structureIndex, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
      self.metalEllipsoidShader.renderTransparentWithEncoder(commandEncoder, sceneIndex: item.sceneIndex, movieIndex: item.movieIndex, structureIndex: item.structureIndex, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
      self.metalCylinderShader.renderTransparentWithEncoder(commandEncoder, sceneIndex: item.sceneIndex, movieIndex: item.movieIndex, structureIndex: item.structureIndex, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
      self.metalPolygonalPrismShader.renderTransparentWithEncoder(commandEncoder, sceneIndex: item.sceneIndex, movieIndex: item.movieIndex, structureIndex: item.structureIndex, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, ambientOcclusionTextures: ambientOcclusionShader.textures, size: size)
    }
      
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
      
   
      self.globalAxesSystemShader.renderWithEncoder(commandEncoder, renderPassDescriptor: renderPassDescriptor, frameUniformBuffer: frameUniformBuffer, lightUniformBuffers: lightUniformBuffers, globalAxesUniformBuffers: globalAxesUniformBuffers, fontTexture: textShader.fontTextures["Helvetica"], size: size)
    }
    
    commandEncoder.endEncoding()
  }
  
  func pickingOffScreen(commandBuffer: MTLCommandBuffer, frameUniformBuffer: MTLBuffer, size: CGSize, renderQuality: RKRenderQuality, camera: RKCamera?, skipRibbonPicking: Bool = false)
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
                                                  ribbonShader: ribbonShader,
                                                  frameUniformBuffer: frameUniformBuffer,
                                                  structureUniformBuffers: structureUniformBuffers,
                                                  size: size,
                                                  renderQuality: renderQuality,
                                                  camera: camera,
                                                  skipRibbonPicking: skipRibbonPicking)
  }
  
  func drawOffScreen(commandBuffer: MTLCommandBuffer, commandQueue: MTLCommandQueue? = nil, frameUniformBuffer: MTLBuffer, size: CGSize, renderQuality: RKRenderQuality, camera: RKCamera?, suppressMolecularGeometry: Bool = false)
  {
    // has to precede the scene pass in this same command buffer: the molecular shaders read the mask
    encodeShadowMask(device: commandBuffer.device,
                     commandQueue: commandQueue,
                     commandBuffer: commandBuffer,
                     frameUniformBuffer: frameUniformBuffer,
                     size: size,
                     renderQuality: renderQuality,
                     pathTracing: suppressMolecularGeometry)

    renderSceneWithEncoder(commandBuffer, renderPassDescriptor: backgroundShader.sceneRenderPassDescriptor, frameUniformBuffer: frameUniformBuffer, size: size, renderQuality: renderQuality, camera: camera, suppressMolecularGeometry: suppressMolecularGeometry)
    backgroundShader.encodeManualDepthResolveIfNeeded(commandBuffer, size: size)
    
    renderSceneVolumeRenderedSurfacesWithEncoder(commandBuffer, renderPassDescriptor: backgroundShader.sceneRenderVolumeRenderedSurfacesPassDescriptor, frameUniformBuffer: frameUniformBuffer, size: size, renderQuality: renderQuality, camera: camera)
    backgroundShader.encodeManualDepthResolveIfNeeded(commandBuffer, size: size)
   
    renderSceneTransparentWithEncoder(commandBuffer, renderPassDescriptor: backgroundShader.sceneRenderTransparentPassDescriptor, frameUniformBuffer: frameUniformBuffer, size: size, renderQuality: renderQuality, camera: camera)
    
    if let commandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor)
    {
      if let camera, camera.frustrumType == .perspective
      {
        atomSelectionGlowPerspectiveImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      }
      else
      {
        atomSelectionGlowOrthographicImposterShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, instanceBuffer: atomSelectionShader.instanceBuffer, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      }
      
      internalBondSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, instanceRenderer: internalBondSelectionShader, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      externalBondSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, instanceRenderer: externalBondSelectionShader, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      
      
      ellipsoidPrimitiveSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      crystalEllipsoidPrimitiveSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      
      cylinderPrimitiveSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, metalCylinderShader: metalCylinderShader, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      crystalCylinderPrimitiveSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, metalCrystalCylinderShader: metalCrystalCylinderShader, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      
      polygonalPrismPrimitiveSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, metalPolygonalPrismShader: metalPolygonalPrismShader, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      crystalPolygonalPrismPrimitiveSelectionGlowShader.renderWithEncoder(commandEncoder, renderPassDescriptor: atomSelectionGlowShader.atomSelectionGlowRenderPassDescriptor, metalCrystalPolygonalPrismShader: metalCrystalPolygonalPrismShader, frameUniformBuffer: frameUniformBuffer,  structureUniformBuffers: structureUniformBuffers, lightUniformBuffers: lightUniformBuffers, size: size)
      
      ribbonSelectionShader.renderGlowWithEncoder(commandEncoder,
                                                  ribbonShader: ribbonShader,
                                                  frameUniformBuffer: frameUniformBuffer,
                                                  structureUniformBuffers: structureUniformBuffers,
                                                  lightUniformBuffers: lightUniformBuffers,
                                                  size: size)
      
      commandEncoder.endEncoding()
    }
    
    blurHorizontalShader.renderWithEncoder(commandBuffer, renderPassDescriptor: blurHorizontalShader.blurHorizontalRenderPassDescriptor, texture: atomSelectionGlowShader.atomSelectionGlowResolveTexture, frameUniformBuffer: frameUniformBuffer, size: size)
    
    blurVerticalShader.renderWithEncoder(commandBuffer, renderPassDescriptor: blurVerticalShader.blurVerticalRenderPassDescriptor, texture: blurHorizontalShader.blurHorizontalTexture, frameUniformBuffer: frameUniformBuffer, size: size)
    
   
  }
  
  /// Composites the finished scene onto the drawable. `sourceTexture` overrides the rasterized
  /// scene texture, which is how the path-traced image reaches the screen; its depth arrives with it,
  /// through the tracer's composite depth buffer.
  func drawOnScreen(commandBuffer: MTLCommandBuffer, renderPass: MTLRenderPassDescriptor, frameUniformBuffer: MTLBuffer, size: CGSize, sourceTexture: MTLTexture? = nil, tracedDepthBuffer: MTLBuffer? = nil, tracedCueMaskBuffer: MTLBuffer? = nil)
  {
    quadShader.renderWithEncoder(commandBuffer, renderPass: renderPass, frameUniformBuffer: frameUniformBuffer, sceneResolveTexture: sourceTexture ?? backgroundShader.sceneResolveTexture, blurVerticalTexture: blurVerticalShader.blurVerticalTexture, sceneDepthTexture: backgroundShader.sceneResolvedDepthTexture, sceneCueMaskTexture: backgroundShader.sceneStencilTexture, tracedDepthBuffer: tracedDepthBuffer, tracedCueMaskBuffer: tracedCueMaskBuffer, size: size)
  }

  // MARK: -
  // MARK: Interactive path tracing

  /// Whether the interactive frame loop should path trace the molecular geometry instead of
  /// rasterizing it. Every frame traces, moving or not, so the appearance never switches between
  /// the two renderers mid-interaction.
  public func isInteractivePathTracing(device: MTLDevice) -> Bool
  {
    return RKRenderSettings.shared.interactiveRenderMode == RKRenderMode.rayTracing && MetalPathTracerShader.isSupported(device: device)
  }

  /// Traces `samplesThisFrame` more samples of the molecular geometry into the running average
  /// and composites them over the rasterized scene, all inside the caller's command buffer.
  /// Returns the texture to present, or nil when the path tracer could not run and the caller
  /// should fall back to the rasterized image.
  public func encodeInteractivePathTracer(device: MTLDevice,
                                          commandQueue: MTLCommandQueue,
                                          commandBuffer: MTLCommandBuffer,
                                          frameUniformBuffer: MTLBuffer,
                                          size: CGSize,
                                          samplesThisFrame: Int) -> MTLTexture?
  {
    // the sample and bounce budgets are a property of this machine, but the occlusion strength is a
    // look and belongs to the project, so that the view previews what an export would produce
    var settings: RKPathTracerSettings = RKRenderSettings.shared.interactivePathTracerSettings
    if let project: RKRenderDataSource = renderDataSource
    {
      settings.ambientOcclusionStrength = Float(min(max(project.renderAmbientOcclusionStrength, 0.0), 1.0))
    }

    return pathTracerShader.encodeInteractive(device: device,
                                              commandQueue: commandQueue,
                                              commandBuffer: commandBuffer,
                                              size: size,
                                              settings: settings,
                                              samplesThisFrame: samplesThisFrame,
                                              frameUniformBuffer: frameUniformBuffer,
                                              structureUniformBuffers: structureUniformBuffers,
                                              lightUniformBuffers: lightUniformBuffers,
                                              sceneColorTexture: backgroundShader.sceneResolveTexture,
                                              sceneDepthTexture: backgroundShader.sceneResolvedDepthTexture)
  }

  /// Drops the cached acceleration structures, so the next path-traced frame repacks the scene.
  public func invalidatePathTracerGeometry()
  {
    pathTracerShader.invalidateGeometry()
  }

  // MARK: Shadows
  // =====================================================================

  /// Stands in for the shadow mask when shadows are off or cannot be traced. A single texel with
  /// every light bit set, so the molecular shaders read "nothing is in shadow" and light the scene
  /// exactly as they did before shadows existed.
  private var allLitShadowMask: MTLTexture? = nil

  /// The mask the molecular passes of this frame should read.
  private var shadowMaskForFrame: MTLTexture? = nil

  private func buildAllLitShadowMask(device: MTLDevice)
  {
    guard allLitShadowMask == nil else {return}

    let descriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.r8Uint, width: 1, height: 1, mipmapped: false)
    descriptor.usage = MTLTextureUsage.shaderRead
    guard let texture: MTLTexture = device.makeTexture(descriptor: descriptor) else {return}
    texture.label = "all-lit shadow mask"

    var allLit: UInt8 = 0xFF
    texture.replace(region: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0, withBytes: &allLit, bytesPerRow: 1)
    allLitShadowMask = texture
  }

  /// Whether the scene wants ray-traced shadows, has a light able to cast one, and is on a device that
  /// can trace them. The light test is what keeps the default-on setting free under the camera-light
  /// rig, whose lights all shine along the line of sight.
  ///
  /// An export traces them wherever it is run, so that the picture a document describes does not depend
  /// on the machine it is opened on; a frame of the render view asks the machine-wide setting first,
  /// which is off by default where the rays would be traced in a shader.
  public func tracesShadows(device: MTLDevice, renderQuality: RKRenderQuality) -> Bool
  {
    guard let project: RKRenderDataSource = renderDataSource, project.renderShadows else {return false}
    guard renderQuality == RKRenderQuality.picture || RKRenderSettings.shared.interactiveShadows else {return false}
    guard project.renderLights.contains(where: {$0.castsShadows}) else {return false}
    return MetalPathTracerShader.isSupported(device: device) && pathTracerShader.canTraceShadows
  }

  /// Works out which lights reach each pixel and keeps the answer for the molecular passes of this
  /// frame. Must be encoded into the same command buffer as the scene, before it.
  ///
  /// Skipped when the path tracer is drawing the molecular geometry itself: it casts its own shadow
  /// rays, and a mask for shaders that are not running would be wasted work.
  public func encodeShadowMask(device: MTLDevice,
                               commandQueue: MTLCommandQueue?,
                               commandBuffer: MTLCommandBuffer,
                               frameUniformBuffer: MTLBuffer,
                               size: CGSize,
                               renderQuality: RKRenderQuality,
                               pathTracing: Bool)
  {
    buildAllLitShadowMask(device: device)
    shadowMaskForFrame = nil

    guard let commandQueue = commandQueue, !pathTracing, tracesShadows(device: device, renderQuality: renderQuality) else {return}

    shadowMaskForFrame = pathTracerShader.encodeShadowMask(device: device,
                                                           commandQueue: commandQueue,
                                                           commandBuffer: commandBuffer,
                                                           size: size,
                                                           frameUniformBuffer: frameUniformBuffer,
                                                           structureUniformBuffers: structureUniformBuffers,
                                                           lightUniformBuffers: lightUniformBuffers)
  }

  /// The mask the molecular passes read. Falls back to the all-lit texel whenever a mask was not
  /// traced, which is what keeps the shaders free of a "shadows enabled" branch.
  private var activeShadowMask: MTLTexture?
  {
    return shadowMaskForFrame ?? allLitShadowMask
  }

  public var pathTracerAccumulatedSampleCount: Int
  {
    return pathTracerShader.accumulatedSampleCount
  }
  
 
  // MARK: -
  // MARK: Make Pictures
  

  public func renderPictureData(device: MTLDevice, size: CGSize, camera: RKCamera, imageQuality: RKImageQuality, renderQuality: RKRenderQuality, renderMode: RKRenderMode = .rasterization, pathTracerSettings: RKPathTracerSettings = .standard) -> Data?
  {
    if let _: RKRenderDataSource = renderDataSource,
       let commandQueue: MTLCommandQueue = device.makeCommandQueue(),
       let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
    {
      let pathTracing: Bool = (renderMode == .rayTracing) && MetalPathTracerShader.isSupported(device: device)

      var uniforms: RKTransformationUniforms = self.transformUniforms(maximumExtendedDynamicRangeColorComponentValue: 1.0, camera: camera, pathTracing: pathTracing)
      let frameUniformBuffer: MTLBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<RKTransformationUniforms>.stride, options: RKMetal.hostStorage)!
      
      
      self.ambientOcclusionShader.updateAmbientOcclusionTextures(device: device, commandQueue, quality: .picture, atomShader: self.atomShader, atomOrthographicImposterShader: self.atomOrthographicImposterShader, ribbonShader: self.ribbonShader, internalBondShader: self.internalBondShader, externalBondShader: self.externalBondShader)
      // The bake is what decides how the occlusion atlases are laid out, and the shaders read that layout
      // from the structure's uniforms, so those have to be built after it rather than before. The
      // interactive path already orders the two this way.
      self.buildStructureUniforms(device: device)
    
      self.isosurfaceShader.updateAdsorptionSurface(device: device, commandQueue: commandQueue, windowController: nil, completionHandler: {})
      self.volumeRenderedSurfaceShader.updateAdsorptionSurface(device: device, commandQueue: commandQueue, windowController: nil, completionHandler: {})
      
      if renderMode == .rayTracing && !pathTracing
      {
        lastPictureDiagnostic = "ray tracing was requested but \(device.name) does not support it, rasterized instead"
        LogQueue.shared.warning(destination: nil, message: lastPictureDiagnostic)
      }
      else
      {
        lastPictureDiagnostic = "rasterized on \(device.name)"
      }
      LogQueue.shared.verbose(destination: nil, message: "Rendering picture with \(pathTracing ? "path tracing" : "rasterization")")
      
      // Atoms, bonds and ribbons are left out of the raster pass when path tracing, so the
      // scene depth buffer holds only the primitives the path tracer does not handle and
      // the composite becomes a plain depth comparison.
      self.drawOffScreen(commandBuffer: commandBuffer, commandQueue: commandQueue, frameUniformBuffer: frameUniformBuffer, size: size, renderQuality: renderQuality, camera: camera, suppressMolecularGeometry: pathTracing)
      commandBuffer.commit()
      
      // Everything below reads the rasterized scene, so it goes into a second command
      // buffer; ordering is guaranteed because it is submitted to the same queue.
      var sourceTexture: MTLTexture? = backgroundShader.sceneResolveTexture
      var tracedDepthBuffer: MTLBuffer? = nil
      var tracedCueMaskBuffer: MTLBuffer? = nil
      if pathTracing
      {
        let traced: MTLTexture? = self.pathTracerShader.render(device: device,
                                                              commandQueue: commandQueue,
                                                              size: size,
                                                              settings: pathTracerSettings,
                                                              frameUniformBuffer: frameUniformBuffer,
                                                              structureUniformBuffers: structureUniformBuffers,
                                                              lightUniformBuffers: lightUniformBuffers,
                                                              sceneColorTexture: backgroundShader.sceneResolveTexture,
                                                              sceneDepthTexture: backgroundShader.sceneResolvedDepthTexture)
        lastPictureDiagnostic = "path tracer on \(device.name): \(pathTracerShader.lastStatus)"

        if let traced = traced
        {
          sourceTexture = traced
          tracedDepthBuffer = pathTracerShader.compositeDepthBuffer
          tracedCueMaskBuffer = pathTracerShader.compositeCueMaskBuffer
        }
        else if let fallbackCommandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
        {
          // the path tracer could not run (no traceable geometry, or a resource failure):
          // rasterize the molecular geometry after all so the picture is not left empty
          self.drawOffScreen(commandBuffer: fallbackCommandBuffer, commandQueue: commandQueue, frameUniformBuffer: frameUniformBuffer, size: size, renderQuality: renderQuality, camera: camera)
          fallbackCommandBuffer.commit()
        }
      }
      
      guard let resolveCommandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer() else {return nil}
      
      let pictureTextureDescriptor: MTLTextureDescriptor
      switch(imageQuality)
      {
      case .rgb_16_bits, .cmyk_16_bits:
        pictureTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Unorm, width: max(Int(size.width), 1), height: max(Int(size.height), 1), mipmapped: false)
      case .rgb_8_bits, .cmyk_8_bits:
        pictureTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.bgra8Unorm, width: max(Int(size.width), 1), height: max(Int(size.height), 1), mipmapped: false)
      }
      
      pictureTextureDescriptor.textureType = MTLTextureType.type2D
      pictureTextureDescriptor.storageMode = RKMetal.hostStorageMode
      pictureTextureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
      let pictureTexture: MTLTexture = device.makeTexture(descriptor: pictureTextureDescriptor)!
      pictureTexture.label = "scene resolved texture"
      
      let picturePassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
      let pictureColorAttachment: MTLRenderPassColorAttachmentDescriptor = picturePassDescriptor.colorAttachments[0]
      pictureColorAttachment.texture = pictureTexture
      pictureColorAttachment.loadAction = MTLLoadAction.clear
      pictureColorAttachment.clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0)
      pictureColorAttachment.storeAction = MTLStoreAction.store
      
      if let quadCommandEncoder: MTLRenderCommandEncoder = resolveCommandBuffer.makeRenderCommandEncoder(descriptor: picturePassDescriptor)
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
    
        // A trace that was asked for can still fail, and the scene is then rasterized after all, so
        // where the edge cueing looks for its depth is settled here rather than up with the request.
        var compositeUniforms: RKTransformationUniforms = self.transformUniforms(maximumExtendedDynamicRangeColorComponentValue: 1.0, camera: camera, pathTracing: tracedDepthBuffer != nil)
        let compositeUniformBuffer: MTLBuffer? = device.makeBuffer(bytes: &compositeUniforms, length: MemoryLayout<RKTransformationUniforms>.stride, options: RKMetal.hostStorage)

        quadCommandEncoder.setVertexBuffer(quadShader.vertexBuffer, offset: 0, index: 0)
        quadCommandEncoder.setFragmentBuffer(compositeUniformBuffer ?? frameUniformBuffer, offset: 0, index: 0)
        quadCommandEncoder.setFragmentBuffer(tracedDepthBuffer ?? quadShader.placeholderDepthBuffer, offset: 0, index: 1)
        quadCommandEncoder.setFragmentBuffer(tracedCueMaskBuffer ?? quadShader.placeholderCueMaskBuffer, offset: 0, index: 2)
        quadCommandEncoder.setFragmentTexture(sourceTexture, index: 0)
        quadCommandEncoder.setFragmentTexture(blurVerticalShader.blurVerticalTexture, index: 1)
        quadCommandEncoder.setFragmentTexture(backgroundShader.sceneResolvedDepthTexture, index: 2)
        quadCommandEncoder.setFragmentTexture(backgroundShader.sceneStencilTexture, index: 3)
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
           let blitEncoder: MTLBlitCommandEncoder = resolveCommandBuffer.makeBlitCommandEncoder()
        {
          RKMetal.synchronize(blitEncoder, resource: pictureTexture)
    
          blitEncoder.copy(from: pictureTexture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0,0, 0), sourceSize: MTLSizeMake(Int(size.width), Int(size.height), 1), to: pictureTextureBuffer, destinationOffset: 0, destinationBytesPerRow: bytesPerRow, destinationBytesPerImage: 0)
          blitEncoder.endEncoding()
    
          resolveCommandBuffer.commit()
          resolveCommandBuffer.waitUntilCompleted()
    
          return Data(bytes: pictureTextureBuffer.contents().assumingMemoryBound(to: UInt8.self), count: pictureTextureBuffer.length)
        }
      }
    }
    return nil
  }
  
  public func renderPicture(device: MTLDevice, size: CGSize, imagePhysicalSizeInInches: Double, camera: RKCamera, imageQuality: RKImageQuality, renderQuality: RKRenderQuality, renderMode: RKRenderMode = .rasterization, pathTracerSettings: RKPathTracerSettings = .standard) -> Data?
  {
    if let data: Data = self.renderPictureData(device: device, size: size, camera: camera, imageQuality: imageQuality, renderQuality: renderQuality, renderMode: renderMode, pathTracerSettings: pathTracerSettings)
    {
      let cgImage: CGImage
      switch(imageQuality)
      {
      case .rgb_16_bits, .cmyk_16_bits:
        let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder16Little.rawValue | CGImageAlphaInfo.last.rawValue)
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let dataProvider: CGDataProvider = CGDataProvider(data: data as CFData)!
        let bitsPerComponent: Int = 8 * 2
        let bitsPerPixel: Int = 32 * 2
        let bytesPerRow: Int = 4 * Int(size.width) * 2
        cgImage = CGImage(width: Int(size.width), height: Int(size.height), bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, provider: dataProvider, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)!
      case .rgb_8_bits, .cmyk_8_bits:
        let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.first.rawValue)
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let dataProvider: CGDataProvider = CGDataProvider(data: data as CFData)!
        let bitsPerComponent: Int = 8
        let bitsPerPixel: Int = 32
        let bytesPerRow: Int = 4 * Int(size.width)
        cgImage = CGImage(width: Int(size.width), height: Int(size.height), bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, provider: dataProvider, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)!
      }
        
        
      #if os(macOS)
      let imageRep: NSBitmapImageRep = NSBitmapImageRep(cgImage: cgImage)
      imageRep.size = NSMakeSize(CGFloat(imagePhysicalSizeInInches * 72), CGFloat(imagePhysicalSizeInInches * 72.0 * Double(size.height) / Double(size.width)))
        
      switch(imageQuality)
      {
      case .rgb_8_bits, .rgb_16_bits:
        return imageRep.tiffRepresentation(using: NSBitmapImageRep.TIFFCompression.lzw, factor: 1.0)!
      case .cmyk_8_bits, .cmyk_16_bits:
        let imageRepCMYK: NSBitmapImageRep = imageRep.converting(to: NSColorSpace.genericCMYK, renderingIntent: NSColorRenderingIntent.perceptual)!
        imageRepCMYK.size = NSMakeSize(CGFloat(imagePhysicalSizeInInches * 72), CGFloat(imagePhysicalSizeInInches * 72))
        return imageRepCMYK.tiffRepresentation(using: NSBitmapImageRep.TIFFCompression.lzw, factor: 1.0)!
      }
      #else
      return UIImage(cgImage: cgImage).pngData()
      #endif
    }
    return nil
  }
}



