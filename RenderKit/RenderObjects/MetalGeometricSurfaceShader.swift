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

import Foundation
import Metal
import simd
import LogViewKit
import MathKit
import SimulationKit
import SymmetryKit

/// Draws the geometric accessible surface as sphere-imposter patches. Each patch is the exposed
/// part of one probe-inflated atom; the fragment shader discards the spherical caps neighbouring
/// atoms cut out of it.
class MetalGeometricSurfaceShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderObject]] = [[]]
  
  var orthographicOpaquePipeLine: MTLRenderPipelineState! = nil
  var orthographicTransparentPipeLine: MTLRenderPipelineState! = nil
  var perspectiveOpaquePipeLine: MTLRenderPipelineState! = nil
  var perspectiveTransparentPipeLine: MTLRenderPipelineState! = nil
  
  var indexBuffer: MTLBuffer! = nil
  var vertexBuffer: MTLBuffer! = nil
  var instanceBuffer: [[MTLBuffer?]] = []
  var clipBuffer: [[MTLBuffer?]] = []
  
  var opaqueDepthState: MTLDepthStencilState! = nil
  var transparentDepthState: MTLDepthStencilState! = nil
  
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary, vertexDescriptor: MTLVertexDescriptor, maximumNumberOfSamples: Int)
  {
    let opaqueDepth: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    opaqueDepth.depthCompareFunction = MTLCompareFunction.lessEqual
    opaqueDepth.isDepthWriteEnabled = true
    opaqueDepthState = device.makeDepthStencilState(descriptor: opaqueDepth)
    
    let transparentDepth: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
    transparentDepth.depthCompareFunction = MTLCompareFunction.lessEqual
    transparentDepth.isDepthWriteEnabled = false
    transparentDepthState = device.makeDepthStencilState(descriptor: transparentDepth)
    
    func makePipeline(vertex: String, fragment: String, blended: Bool) -> MTLRenderPipelineState
    {
      let descriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
      descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
      descriptor.vertexFunction = library.makeFunction(name: vertex)!
      descriptor.fragmentFunction = library.makeFunction(name: fragment)!
      descriptor.sampleCount = maximumNumberOfSamples
      descriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
      descriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
      descriptor.vertexDescriptor = vertexDescriptor
      if blended
      {
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add
        descriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one
        descriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
      }
      do
      {
        return try device.makeRenderPipelineState(descriptor: descriptor)
      }
      catch
      {
        fatalError("Error occurred when creating geometric surface pipeline state \(error)")
      }
    }
    
    orthographicOpaquePipeLine = makePipeline(vertex: "GeometricSurfaceOrthographicVertexShader", fragment: "GeometricSurfaceOrthographicFragmentShader", blended: false)
    orthographicTransparentPipeLine = makePipeline(vertex: "GeometricSurfaceOrthographicVertexShader", fragment: "GeometricSurfaceOrthographicFragmentShader", blended: true)
    perspectiveOpaquePipeLine = makePipeline(vertex: "GeometricSurfacePerspectiveVertexShader", fragment: "GeometricSurfacePerspectiveFragmentShader", blended: false)
    perspectiveTransparentPipeLine = makePipeline(vertex: "GeometricSurfacePerspectiveVertexShader", fragment: "GeometricSurfacePerspectiveFragmentShader", blended: true)
  }
  
  public func buildVertexBuffers(device: MTLDevice)
  {
    let quad: MetalQuadGeometry = MetalQuadGeometry()
    vertexBuffer = device.makeBuffer(bytes: quad.vertices, length: MemoryLayout<RKVertex>.stride * quad.vertices.count, options: RKMetal.hostStorage)
    indexBuffer = device.makeBuffer(bytes: quad.indices, length: MemoryLayout<UInt16>.stride * quad.indices.count, options: RKMetal.hostStorage)
  }
  
  public func updateGeometricSurface(device: MTLDevice, windowController: NSWindowController?)
  {
    guard let _: RKRenderDataSource = renderDataSource else { return }
    
    instanceBuffer = []
    clipBuffer = []
    
    for i in 0..<self.renderStructures.count
    {
      let structures: [RKRenderObject] = self.renderStructures[i]
      var sceneInstances: [MTLBuffer?] = []
      var sceneClips: [MTLBuffer?] = []
      
      if structures.isEmpty
      {
        sceneInstances.append(nil)
        sceneClips.append(nil)
      }
      else
      {
        for structure in structures
        {
          guard let volumetric: RKRenderVolumetricDataSource = structure as? RKRenderVolumetricDataSource,
                volumetric.drawAdsorptionSurface,
                volumetric.adsorptionSurfaceRenderingMethod == .geometricSurface,
                let adsorption: SKRenderAdsorptionSurfaceStructure = structure as? SKRenderAdsorptionSurfaceStructure else
          {
            sceneInstances.append(nil)
            sceneClips.append(nil)
            continue
          }
          
          let positions: [SIMD3<Double>] = adsorption.atomUnitCellPositions
          let parameters: [SIMD2<Double>] = adsorption.potentialParameters
          if positions.isEmpty || parameters.isEmpty
          {
            LogQueue.shared.warning(destination: windowController, message: "No atoms to build a geometric surface on for \(structure.displayName)")
            volumetric.adsorptionSurfaceNumberOfTriangles = 0
            sceneInstances.append(nil)
            sceneClips.append(nil)
            continue
          }
          
          let surface: SKGeometricSurface = SKGeometricSurface.build(fractionalPositions: positions,
                                                                     potentialParameters: parameters,
                                                                     probeSigma: volumetric.adsorptionSurfaceProbeParameters.y,
                                                                     cell: adsorption.cell,
                                                                     blockingPockets: adsorption.appliedBlockingPockets)
          
          let unitCell: double3x3 = adsorption.cell.unitCell
          let wrapIntoCell: Bool = structure.periodic
          let replicas: [SIMD4<Float>] = {
            let listed: [SIMD4<Float>] = adsorption.cell.renderTranslationVectors
            return listed.isEmpty ? [SIMD4<Float>(0.0, 0.0, 0.0, 0.0)] : listed
          }()
          var instances: [RKGeometricSurfacePatchInstance] = []
          var clips: [RKGeometricSurfaceClip] = []
          instances.reserveCapacity(surface.patches.count * max(1, replicas.count) * (wrapIntoCell ? 4 : 1))
          for replica in replicas
          {
            let translation: SIMD3<Double> = unitCell * SIMD3<Double>(Double(replica.x), Double(replica.y), Double(replica.z))
            for patch in surface.patches
            {
              let copies: [SKGeometricSurfacePatchCopy]
              if wrapIntoCell
              {
                copies = patch.copiesInsideUnitCell(cell: adsorption.cell)
              }
              else
              {
                copies = [SKGeometricSurfacePatchCopy(center: patch.center, clips: patch.clips, cellOrigin: SIMD3<Double>())]
              }
              for copy in copies
              {
                let gpuClips: [SKGeometricSurfaceClip]
                if copy.clips.count > 64
                {
                  gpuClips = Array(copy.clips.sorted { simd_length($0.center - copy.center) < simd_length($1.center - copy.center) }.prefix(64))
                }
                else
                {
                  gpuClips = copy.clips
                }
                let first: UInt32 = UInt32(clips.count)
                for clip in gpuClips
                {
                  let clipCenter: SIMD3<Double> = clip.center + translation
                  clips.append(RKGeometricSurfaceClip(center: SIMD3<Float>(Float(clipCenter.x), Float(clipCenter.y), Float(clipCenter.z)),
                                                      radius: Float(clip.radius)))
                }
                let center: SIMD3<Double> = copy.center + translation
                let cellOrigin: SIMD3<Double> = copy.cellOrigin + translation
                instances.append(RKGeometricSurfacePatchInstance(position: SIMD3<Float>(Float(center.x), Float(center.y), Float(center.z)),
                                                                 radius: Float(patch.radius),
                                                                 cellOrigin: SIMD3<Float>(Float(cellOrigin.x), Float(cellOrigin.y), Float(cellOrigin.z)),
                                                                 firstClip: first,
                                                                 clipCount: UInt32(gpuClips.count),
                                                                 clipToCell: wrapIntoCell))
              }
            }
          }
          
          volumetric.adsorptionSurfaceNumberOfTriangles = instances.count
          LogQueue.shared.info(destination: windowController, message: "Geometric surface for \(structure.displayName): \(instances.count) patches, \(String(format: "%.2f", surface.area)) Å²")
          
          if instances.isEmpty
          {
            sceneInstances.append(nil)
            sceneClips.append(nil)
          }
          else
          {
            sceneInstances.append(device.makeBuffer(bytes: instances, length: MemoryLayout<RKGeometricSurfacePatchInstance>.stride * instances.count, options: RKMetal.hostStorage))
            if clips.isEmpty
            {
              var dummy = RKGeometricSurfaceClip(center: SIMD3<Float>(), radius: 0.0)
              sceneClips.append(device.makeBuffer(bytes: &dummy, length: MemoryLayout<RKGeometricSurfaceClip>.stride, options: RKMetal.hostStorage))
            }
            else
            {
              sceneClips.append(device.makeBuffer(bytes: clips, length: MemoryLayout<RKGeometricSurfaceClip>.stride * clips.count, options: RKMetal.hostStorage))
            }
          }
        }
      }
      instanceBuffer.append(sceneInstances)
      clipBuffer.append(sceneClips)
    }
  }
  
  public func renderOpaqueWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, isosurfaceUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, camera: RKCamera?)
  {
    render(commandEncoder, opaque: true, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, isosurfaceUniformBuffers: isosurfaceUniformBuffers, lightUniformBuffers: lightUniformBuffers, camera: camera, sceneIndex: nil, movieIndex: nil, structureIndex: nil)
  }
  
  public func renderTransparentWithEncoder(_ commandEncoder: MTLRenderCommandEncoder, sceneIndex: Int, movieIndex: Int, structureIndex: Int, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, isosurfaceUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, camera: RKCamera?)
  {
    render(commandEncoder, opaque: false, frameUniformBuffer: frameUniformBuffer, structureUniformBuffers: structureUniformBuffers, isosurfaceUniformBuffers: isosurfaceUniformBuffers, lightUniformBuffers: lightUniformBuffers, camera: camera, sceneIndex: sceneIndex, movieIndex: movieIndex, structureIndex: structureIndex)
  }
  
  private func render(_ commandEncoder: MTLRenderCommandEncoder, opaque: Bool, frameUniformBuffer: MTLBuffer, structureUniformBuffers: MTLBuffer?, isosurfaceUniformBuffers: MTLBuffer?, lightUniformBuffers: MTLBuffer?, camera: RKCamera?, sceneIndex: Int?, movieIndex: Int?, structureIndex: Int?)
  {
    let perspective: Bool = camera?.frustrumType == .perspective
    let pipeLine: MTLRenderPipelineState = opaque
      ? (perspective ? perspectiveOpaquePipeLine : orthographicOpaquePipeLine)
      : (perspective ? perspectiveTransparentPipeLine : orthographicTransparentPipeLine)
    
    commandEncoder.setDepthStencilState(opaque ? opaqueDepthState : transparentDepthState)
    commandEncoder.setRenderPipelineState(pipeLine)
    commandEncoder.setCullMode(MTLCullMode.none)
    commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    commandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 2)
    commandEncoder.setVertexBuffer(structureUniformBuffers, offset: 0, index: 3)
    commandEncoder.setFragmentBuffer(frameUniformBuffer, offset: 0, index: 0)
    commandEncoder.setFragmentBuffer(structureUniformBuffers, offset: 0, index: 1)
    commandEncoder.setFragmentBuffer(isosurfaceUniformBuffers, offset: 0, index: 2)
    commandEncoder.setFragmentBuffer(lightUniformBuffers, offset: 0, index: 3)
    
    var index = 0
    for i in 0..<self.renderStructures.count
    {
      let structures: [RKRenderObject] = self.renderStructures[i]
      for (j, structure) in structures.enumerated()
      {
        let drawThis: Bool
        if let sceneIndex, let movieIndex
        {
          drawThis = (i == sceneIndex && j == movieIndex)
        }
        else
        {
          drawThis = true
        }
        
        if drawThis,
           let volumetric: RKRenderVolumetricDataSource = structure as? RKRenderVolumetricDataSource,
           volumetric.drawAdsorptionSurface,
           volumetric.adsorptionSurfaceRenderingMethod == .geometricSurface,
           volumetric.isVisible,
           let patchBuffer: MTLBuffer = metalBuffer(instanceBuffer, sceneIndex: i, movieIndex: j),
           let clips: MTLBuffer = metalBuffer(clipBuffer, sceneIndex: i, movieIndex: j)
        {
          let instanceCount: Int = patchBuffer.length / MemoryLayout<RKGeometricSurfacePatchInstance>.stride
          let isOpaque: Bool = volumetric.adsorptionSurfaceOpacity > 0.99999
          if instanceCount > 0 && (opaque == isOpaque)
          {
            let structureOffset: Int = (structureIndex ?? index) * MemoryLayout<RKStructureUniforms>.stride
            let isosurfaceOffset: Int = (structureIndex ?? index) * MemoryLayout<RKIsosurfaceUniforms>.stride
            commandEncoder.setVertexBuffer(patchBuffer, offset: 0, index: 1)
            commandEncoder.setVertexBufferOffset(structureOffset, index: 3)
            commandEncoder.setFragmentBufferOffset(structureOffset, index: 1)
            commandEncoder.setFragmentBufferOffset(isosurfaceOffset, index: 2)
            commandEncoder.setFragmentBuffer(clips, offset: 0, index: 4)
            commandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
          }
        }
        index += 1
      }
    }
    commandEncoder.setCullMode(MTLCullMode.back)
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
