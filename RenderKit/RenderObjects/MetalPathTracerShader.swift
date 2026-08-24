/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions
 of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

import Foundation
import Metal
import MetalKit
import simd
import MathKit
import LogViewKit

// MARK: Layouts shared with PathTracer.metal
// =============================================================================
// Hand-mirrored from PathTracerCommon.h, following the convention the other uniform
// types of RenderKit use. Keep both sides in step.

struct RKPathTracerSphere
{
  var center: SIMD4<Float> = SIMD4<Float>()      // xyz = center, w = radius
  var ambient: SIMD4<Float> = SIMD4<Float>()
  var diffuse: SIMD4<Float> = SIMD4<Float>()
  var specular: SIMD4<Float> = SIMD4<Float>()
}

struct RKPathTracerCylinder
{
  var pointA: SIMD4<Float> = SIMD4<Float>()      // xyz = first end cap, w = radius
  var pointB: SIMD4<Float> = SIMD4<Float>()
  var color1: SIMD4<Float> = SIMD4<Float>()
  var color2: SIMD4<Float> = SIMD4<Float>()
  // the model x- and z-axis of the bond, which the selection patterns are wound from
  var axisX: SIMD4<Float> = SIMD4<Float>()
  var axisZ: SIMD4<Float> = SIMD4<Float>()
}

struct RKPathTracerInstance
{
  var kind: UInt32 = 0
  var primitiveBase: UInt32 = 0
  var structureIndex: UInt32 = 0
  var clipAtUnitCell: UInt32 = 0

  var selectionStyle: UInt32 = 0
  var pad0: UInt32 = 0
  var pad1: UInt32 = 0
  var pad2: UInt32 = 0
}

struct RKPathTracerUniforms
{
  var width: UInt32 = 0
  var height: UInt32 = 0
  var samplesPerDispatch: UInt32 = 1
  var sampleOffset: UInt32 = 0

  var maximumBounces: UInt32 = 2
  var seed: UInt32 = 0
  var rayEpsilon: Float = 1.0e-4
  var accumulatedSamples: Float = 1.0

  var ambientOcclusionStrength: Float = 1.0
  var pad0: Float = 0.0
  var pad1: Float = 0.0
  var pad2: Float = 0.0
}

/// Quality settings of a path-traced still.
public struct RKPathTracerSettings
{
  /// Total number of paths traced per pixel. Also drives the anti-aliasing quality, since
  /// each sample jitters within the pixel.
  public var sampleCount: Int
  /// Number of indirect bounces. 0 gives direct lighting and shadows only; 1 adds ambient
  /// occlusion and one bounce of colour bleeding.
  public var maximumBounces: Int
  /// Samples traced per compute dispatch. Kept small so a single command buffer never runs
  /// long enough to trip the GPU watchdog on large images.
  public var samplesPerDispatch: Int
  /// How much of the traced occlusion is applied to the direct lighting. The raster path
  /// multiplies its baked occlusion map into the complete shaded colour, so 1 matches the
  /// contrast of the rasterized "Fancy" ribbons and 0 leaves the direct term physically
  /// unoccluded.
  public var ambientOcclusionStrength: Float

  /// Occlusion is measured from the ray that leaves the primary hit, so at least one bounce
  /// has to be traced for it to exist at all.
  public var effectiveMaximumBounces: Int
  {
    return (ambientOcclusionStrength > 0.0) ? max(1, maximumBounces) : maximumBounces
  }

  public init(sampleCount: Int = 256, maximumBounces: Int = 2, samplesPerDispatch: Int = 8, ambientOcclusionStrength: Float = 1.0)
  {
    self.sampleCount = max(1, sampleCount)
    self.maximumBounces = max(0, maximumBounces)
    self.samplesPerDispatch = max(1, samplesPerDispatch)
    self.ambientOcclusionStrength = min(max(ambientOcclusionStrength, 0.0), 1.0)
  }

  public static let draft: RKPathTracerSettings = RKPathTracerSettings(sampleCount: 32, maximumBounces: 1, samplesPerDispatch: 8)
  public static let standard: RKPathTracerSettings = RKPathTracerSettings(sampleCount: 256, maximumBounces: 2, samplesPerDispatch: 8)
  public static let high: RKPathTracerSettings = RKPathTracerSettings(sampleCount: 1024, maximumBounces: 3, samplesPerDispatch: 4)
}

// MARK: -

/// Progressive path tracer for still images. Atoms and bonds become analytic spheres and
/// capped cylinders in bounding-box acceleration structures, ribbons become the indexed
/// triangle mesh of `RKRibbonMesh`. The result is composited over the rasterized scene,
/// which by then contains everything the path tracer does not handle (background, unit
/// cell, isosurfaces, text, axes).
///
/// The acceleration structures bake the current atom and bond scale factors, so they are only
/// valid for as long as the scene is unchanged. `invalidateGeometry` drops them; the picture
/// export path never needs to call it because it creates a fresh `MetalRenderer` per image,
/// but the interactive path does whenever the structures are reloaded.
public class MetalPathTracerShader
{
  var renderDataSource: RKRenderDataSource? = nil
  var renderStructures: [[RKRenderObject]] = [[]]

  private var accumulatePipeline: MTLComputePipelineState? = nil
  private var resolvePipeline: MTLComputePipelineState? = nil
  private var intersectionFunctionTable: MTLIntersectionFunctionTable? = nil

  /// Traces the shadows the rasterizer cannot work out for itself. Kept apart from the accumulate
  /// pipeline because an intersection function table belongs to the pipeline it was made from, and
  /// because this one runs in raster mode, where the tracer proper does not.
  private var shadowMaskPipeline: MTLComputePipelineState? = nil
  private var shadowMaskFunctionTable: MTLIntersectionFunctionTable? = nil

  private var sphereBuffer: MTLBuffer? = nil
  private var cylinderBuffer: MTLBuffer? = nil
  private var instanceDataBuffer: MTLBuffer? = nil
  private var ribbonVertexBuffer: MTLBuffer? = nil
  private var ribbonIndexBuffer: MTLBuffer? = nil

  private var primitiveAccelerationStructures: [MTLAccelerationStructure] = []
  private var instanceAccelerationStructure: MTLAccelerationStructure? = nil

  private var accumulationBuffer: MTLBuffer? = nil
  private var indirectBuffer: MTLBuffer? = nil
  private var surfaceInfoBuffer: MTLBuffer? = nil

  /// The selection overlay, kept apart from the accumulation of the model so that it can be
  /// composited last and over everything, which is the order the rasterizer draws its own
  /// selection imposters in. Premultiplied: rgb is the colour times its coverage, a the coverage.
  private var selectionBuffer: MTLBuffer? = nil

  /// Device depth of whatever ends up visible in each pixel of the composite, the traced hit where the
  /// trace won and the rasterized primitive where it did not. The rasterizer's depth buffer cannot
  /// answer that on its own, the molecular geometry having been left out of it, so the compositing pass
  /// reads this instead when it looks for the edges to cue.
  public private(set) var compositeDepthBuffer: MTLBuffer? = nil

  /// Which cues the surface at each pixel asked for, in the encoding the rasterizer writes into the
  /// scene's stencil. See `stencilValue` on RKEdgeCueing.
  public private(set) var compositeCueMaskBuffer: MTLBuffer? = nil
  private(set) public var compositeTexture: MTLTexture? = nil

  /// One byte per pixel, a bit per light, saying which lights reach the molecular surface there.
  /// The molecular raster shaders read it to drop the direct terms of the lights they are hidden from.
  private(set) public var shadowMaskTexture: MTLTexture? = nil
  private var allocatedShadowMaskWidth: Int = 0
  private var allocatedShadowMaskHeight: Int = 0

  /// What the last call to `render` did. The picture export runs out of process, where the log
  /// window does not exist, so the caller can hand this back to the application.
  private(set) public var lastStatus: String = "the path tracer has not run"

  private var sceneRadius: Float = 1.0
  private var hasGeometry: Bool = false
  private var sphereCount: Int = 0
  private var cylinderCount: Int = 0
  private var triangleCount: Int = 0

  /// Set once the acceleration structures match the current scene. Building them takes long
  /// enough that the interactive path cannot afford to do it per frame.
  private var geometryIsValid: Bool = false

  /// Size the per-pixel buffers were allocated for, so a frame at an unchanged size reuses them
  /// and keeps whatever has been accumulated into them.
  private var allocatedWidth: Int = 0
  private var allocatedHeight: Int = 0

  /// How many samples per pixel the accumulation buffers currently hold. The interactive path
  /// adds a few per frame and keeps the result until something invalidates it.
  private(set) public var accumulatedSampleCount: Int = 0

  /// Decorrelates the noise of consecutive interactive frames, which would otherwise all trace
  /// the same sample pattern.
  private var frameSeedCounter: Int = 0

  /// Throttles the interactive frame timing report.
  private var lastFrameReportTime: Date = Date.distantPast

  /// True when the device can run the path tracer at all.
  public static func isSupported(device: MTLDevice) -> Bool
  {
    if #available(macOS 11.0, iOS 14.0, *)
    {
      return device.supportsRaytracing
    }
    return false
  }

  /// True when the device traverses the acceleration structures in dedicated hardware. Apple GPUs from
  /// the sixth family on do; the Intel and AMD cards of the Intel Macs walk them in a shader instead,
  /// which is why they can only intersect rays from a compute command and why they are far slower at
  /// it. Both run everything here, so this decides what a frame can be expected to afford rather than
  /// what it is allowed to do.
  public static func tracesRaysInHardware(device: MTLDevice) -> Bool
  {
    guard isSupported(device: device) else {return false}
    if #available(macOS 11.0, iOS 14.0, *)
    {
      return device.supportsFamily(MTLGPUFamily.apple6)
    }
    return false
  }

  public init()
  {
  }

  // MARK: Pipelines
  // =====================================================================

  /// Builds the two compute pipelines and the intersection function table. Safe to call on
  /// devices without ray-tracing support: it leaves the pipelines nil and `render` then
  /// reports failure, so the caller falls back to rasterization.
  public func buildPipeLine(device: MTLDevice, library: MTLLibrary)
  {
    guard MetalPathTracerShader.isSupported(device: device) else {return}

    guard #available(macOS 11.0, iOS 14.0, *) else {return}

    guard let accumulateFunction: MTLFunction = library.makeFunction(name: "pathTracerAccumulateKernel"),
          let resolveFunction: MTLFunction = library.makeFunction(name: "pathTracerResolveKernel"),
          let sphereFunction: MTLFunction = library.makeFunction(name: "pathTracerSphereIntersection"),
          let cylinderFunction: MTLFunction = library.makeFunction(name: "pathTracerCylinderIntersection"),
          let ribbonSelectionFunction: MTLFunction = library.makeFunction(name: "pathTracerRibbonSelectionIntersection") else
    {
      LogQueue.shared.error(destination: nil, message: "Path tracer: shader functions missing from the Metal library")
      return
    }

    let linkedFunctions: MTLLinkedFunctions = MTLLinkedFunctions()
    linkedFunctions.functions = [sphereFunction, cylinderFunction, ribbonSelectionFunction]

    let accumulateDescriptor: MTLComputePipelineDescriptor = MTLComputePipelineDescriptor()
    accumulateDescriptor.computeFunction = accumulateFunction
    accumulateDescriptor.linkedFunctions = linkedFunctions
    accumulateDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true

    do
    {
      let pipeline: MTLComputePipelineState = try device.makeComputePipelineState(descriptor: accumulateDescriptor, options: [], reflection: nil)
      self.accumulatePipeline = pipeline

      let tableDescriptor: MTLIntersectionFunctionTableDescriptor = MTLIntersectionFunctionTableDescriptor()
      tableDescriptor.functionCount = 3
      guard let table: MTLIntersectionFunctionTable = pipeline.makeIntersectionFunctionTable(descriptor: tableDescriptor) else
      {
        LogQueue.shared.error(destination: nil, message: "Path tracer: could not create the intersection function table")
        self.accumulatePipeline = nil
        return
      }
      table.setFunction(pipeline.functionHandle(function: sphereFunction), index: 0)
      table.setFunction(pipeline.functionHandle(function: cylinderFunction), index: 1)
      table.setFunction(pipeline.functionHandle(function: ribbonSelectionFunction), index: 2)
      self.intersectionFunctionTable = table

      self.resolvePipeline = try device.makeComputePipelineState(function: resolveFunction)
    }
    catch
    {
      LogQueue.shared.error(destination: nil, message: "Path tracer: could not create the compute pipelines (\(error))")
      self.accumulatePipeline = nil
      self.resolvePipeline = nil
      self.intersectionFunctionTable = nil
    }

    // The shadow pass is optional: if it cannot be built the rasterizer simply goes on drawing
    // without shadows, so a failure here must not take the tracer proper down with it.
    guard let shadowFunction: MTLFunction = library.makeFunction(name: "pathTracerShadowMaskKernel") else {return}

    let shadowDescriptor: MTLComputePipelineDescriptor = MTLComputePipelineDescriptor()
    shadowDescriptor.computeFunction = shadowFunction
    shadowDescriptor.linkedFunctions = linkedFunctions
    shadowDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true

    do
    {
      let pipeline: MTLComputePipelineState = try device.makeComputePipelineState(descriptor: shadowDescriptor, options: [], reflection: nil)

      let tableDescriptor: MTLIntersectionFunctionTableDescriptor = MTLIntersectionFunctionTableDescriptor()
      tableDescriptor.functionCount = 3
      guard let table: MTLIntersectionFunctionTable = pipeline.makeIntersectionFunctionTable(descriptor: tableDescriptor) else {return}
      table.setFunction(pipeline.functionHandle(function: sphereFunction), index: 0)
      table.setFunction(pipeline.functionHandle(function: cylinderFunction), index: 1)
      // never reached by a shadow ray, the selection shells being outside its mask, but the slot has
      // to exist for the offsets the geometry descriptors carry to mean the same thing in both tables
      table.setFunction(pipeline.functionHandle(function: ribbonSelectionFunction), index: 2)

      self.shadowMaskPipeline = pipeline
      self.shadowMaskFunctionTable = table
    }
    catch
    {
      LogQueue.shared.error(destination: nil, message: "Path tracer: could not create the shadow pipeline (\(error))")
      self.shadowMaskPipeline = nil
      self.shadowMaskFunctionTable = nil
    }
  }

  // MARK: Per-size resources
  // =====================================================================

  /// Drops the cached acceleration structures, so the next frame repacks the geometry. Called
  /// whenever the structures, their scale factors or their visibility change.
  public func invalidateGeometry()
  {
    geometryIsValid = false
    primitiveAccelerationStructures = []
    instanceAccelerationStructure = nil
  }

  public func buildTextures(device: MTLDevice, size: CGSize)
  {
    let width: Int = max(Int(size.width), 1)
    let height: Int = max(Int(size.height), 1)
    let pixelCount: Int = width * height

    // reallocating per frame would stall the interactive path, and the contents do not have to
    // survive a frame, so a same-size request reuses what is already there
    guard width != allocatedWidth || height != allocatedHeight || accumulationBuffer == nil else {return}

    allocatedWidth = width
    allocatedHeight = height

    accumulationBuffer = device.makeBuffer(length: pixelCount * MemoryLayout<SIMD4<Float>>.stride, options: MTLResourceOptions.storageModePrivate)
    accumulationBuffer?.label = "path tracer direct accumulation"

    indirectBuffer = device.makeBuffer(length: pixelCount * MemoryLayout<SIMD4<Float>>.stride, options: MTLResourceOptions.storageModePrivate)
    indirectBuffer?.label = "path tracer indirect accumulation and visibility"

    surfaceInfoBuffer = device.makeBuffer(length: pixelCount * MemoryLayout<SIMD4<Float>>.stride, options: MTLResourceOptions.storageModePrivate)
    surfaceInfoBuffer?.label = "path tracer primary surface info"

    selectionBuffer = device.makeBuffer(length: pixelCount * MemoryLayout<SIMD4<Float>>.stride, options: MTLResourceOptions.storageModePrivate)
    selectionBuffer?.label = "path tracer selection overlay"

    compositeDepthBuffer = device.makeBuffer(length: pixelCount * MemoryLayout<Float>.stride, options: MTLResourceOptions.storageModePrivate)
    compositeDepthBuffer?.label = "path tracer composite depth"

    compositeCueMaskBuffer = device.makeBuffer(length: pixelCount * MemoryLayout<UInt8>.stride, options: MTLResourceOptions.storageModePrivate)
    compositeCueMaskBuffer?.label = "path tracer composite cueing mask"

    let descriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba16Float, width: width, height: height, mipmapped: false)
    descriptor.textureType = MTLTextureType.type2D
    descriptor.storageMode = MTLStorageMode.private
    descriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.shaderWrite.rawValue)
    compositeTexture = device.makeTexture(descriptor: descriptor)
    compositeTexture?.label = "path tracer composite texture"
  }

  /// Allocates the shadow mask on its own, since in raster mode it is the only per-pixel resource
  /// wanted and the accumulation buffers would be several hundred megabytes of waste.
  private func buildShadowMaskTexture(device: MTLDevice, size: CGSize)
  {
    let width: Int = max(Int(size.width), 1)
    let height: Int = max(Int(size.height), 1)

    guard width != allocatedShadowMaskWidth || height != allocatedShadowMaskHeight || shadowMaskTexture == nil else {return}

    let descriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.r8Uint, width: width, height: height, mipmapped: false)
    descriptor.textureType = MTLTextureType.type2D
    descriptor.storageMode = MTLStorageMode.private
    descriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.shaderWrite.rawValue)
    shadowMaskTexture = device.makeTexture(descriptor: descriptor)
    shadowMaskTexture?.label = "path tracer shadow mask"

    allocatedShadowMaskWidth = width
    allocatedShadowMaskHeight = height
  }

  // MARK: Geometry packing
  // =====================================================================

  /// Packs every atom, bond and ribbon of the visible structures into one set of global
  /// buffers, and records one instance per (structure, geometry kind) pair. Geometry stays
  /// in structure space; the structure's model matrix becomes the instance transform.
  ///
  /// Whatever is selected is packed a second time, enlarged as its selection style asks, as instances
  /// only primary rays can see. That shell is what the striped and Worley-noise patterns are drawn on,
  /// and it stands to the model in the same relation as the enlarged imposter the rasterizer draws
  /// over a selected atom. Atoms and bonds grow by a factor about their own axis; a ribbon, being a
  /// surface with no centre to grow from, is instead pushed out along its normals.
  private func packGeometry(device: MTLDevice) -> [(descriptor: MTLPrimitiveAccelerationStructureDescriptor, transform: float4x4, mask: UInt32)]
  {
    var spheres: [RKPathTracerSphere] = []
    var cylinders: [RKPathTracerCylinder] = []
    var instances: [RKPathTracerInstance] = []
    var ribbonVertices: [RKVertex] = []
    var ribbonIndices: [UInt32] = []
    var ribbonPositions: [Float] = []

    var sphereBoxes: [MTLAxisAlignedBoundingBox] = []
    var cylinderBoxes: [MTLAxisAlignedBoundingBox] = []

    // one entry per instance: the primitive acceleration structure to build, the instance
    // transform to place it with and the rays it answers
    var pending: [(descriptor: MTLPrimitiveAccelerationStructureDescriptor, transform: float4x4, mask: UInt32)] = []

    var minimum: SIMD3<Float> = SIMD3<Float>(repeating: Float.greatestFiniteMagnitude)
    var maximum: SIMD3<Float> = SIMD3<Float>(repeating: -Float.greatestFiniteMagnitude)

    // The structure being packed. Held here rather than passed because the two helpers below are
    // otherwise identical for the model and for a selection shell.
    var modelMatrix: float4x4 = float4x4()
    var structureIndex: Int = 0

    /// Packs `atoms` as spheres of `radiusScale` times their own scale and records the instance that
    /// places them. Does nothing when they all turn out to be invisible.
    func appendSpheres(_ atoms: [RKInPerInstanceAttributesAtoms], radiusScale: Float, selection: PathTracerSelection, clipAtUnitCell: Bool)
    {
      let sphereBase: Int = spheres.count
      let boxBase: Int = sphereBoxes.count

      for atom in atoms
      {
        // invisible atoms are marked with a negative w, as in the imposter shaders
        guard atom.position.w >= 0.0 else {continue}
        let radius: Float = radiusScale * atom.scale.z
        guard radius > 0.0 else {continue}
        let center: SIMD3<Float> = SIMD3<Float>(atom.position.x, atom.position.y, atom.position.z)

        var sphere: RKPathTracerSphere = RKPathTracerSphere()
        sphere.center = SIMD4<Float>(center.x, center.y, center.z, radius)
        sphere.ambient = atom.ambient
        sphere.diffuse = atom.diffuse
        sphere.specular = atom.specular
        spheres.append(sphere)

        sphereBoxes.append(MetalPathTracerShader.boundingBox(minimum: center - SIMD3<Float>(repeating: radius),
                                                             maximum: center + SIMD3<Float>(repeating: radius)))
        MetalPathTracerShader.expand(&minimum, &maximum, modelMatrix: modelMatrix, center: center, radius: radius)
      }

      guard sphereBoxes.count > boxBase else {return}

      let descriptor: MTLPrimitiveAccelerationStructureDescriptor = MTLPrimitiveAccelerationStructureDescriptor()
      let geometry: MTLAccelerationStructureBoundingBoxGeometryDescriptor = MTLAccelerationStructureBoundingBoxGeometryDescriptor()
      // the sphere intersection function sits at index 0 of the function table
      geometry.intersectionFunctionTableOffset = 0
      geometry.boundingBoxCount = sphereBoxes.count - boxBase
      geometry.boundingBoxBufferOffset = boxBase * MemoryLayout<MTLAxisAlignedBoundingBox>.stride
      descriptor.geometryDescriptors = [geometry]
      pending.append((descriptor: descriptor, transform: modelMatrix, mask: selection.instanceMask))

      var instance: RKPathTracerInstance = RKPathTracerInstance()
      instance.kind = UInt32(PathTracerKind.sphere.rawValue)
      instance.primitiveBase = UInt32(sphereBase)
      instance.structureIndex = UInt32(structureIndex)
      instance.clipAtUnitCell = clipAtUnitCell ? 1 : 0
      instance.selectionStyle = selection.rawValue
      instances.append(instance)
    }

    /// Packs the given bond sets as capped cylinders, expanding double and triple bonds into their
    /// sub-cylinders, and records the instance that places them. `radiusScale` multiplies the radius
    /// the model itself uses, which is how a selection shell comes to enclose its bond.
    func appendCylinders(_ bondSets: [(bonds: [RKInPerInstanceAttributesBonds], external: Bool)],
                         bondScaling: Float,
                         isUnity: Bool,
                         radiusScale: Float,
                         selection: PathTracerSelection,
                         clipAtUnitCell: Bool)
    {
      let cylinderBase: Int = cylinders.count
      let boxBase: Int = cylinderBoxes.count

      for (bonds, external) in bondSets
      {
        for bond in bonds
        {
          guard bond.position1.w >= 0.0, bond.position2.w >= 0.0 else {continue}

          let type: Int = isUnity ? 0 : Int(bond.type)
          let subCylinderCount: Int = MetalPathTracerShader.subCylinderCount(type: type)
          let position1: SIMD3<Float> = SIMD3<Float>(bond.position1.x, bond.position1.y, bond.position1.z)
          let position2: SIMD3<Float> = SIMD3<Float>(bond.position2.x, bond.position2.y, bond.position2.z)
          guard simd_length(position2 - position1) > 0.0 else {continue}

          // the two basis vectors and the sign convention differ between the internal
          // and external bond vertex shaders; both are reproduced here
          let direction: SIMD3<Float> = external ? simd_normalize(position1 - position2) : simd_normalize(position2 - position1)
          let v1: SIMD3<Float> = simd_normalize(abs(direction.x) > abs(direction.z)
                                                ? SIMD3<Float>(-direction.y, direction.x, 0.0)
                                                : SIMD3<Float>(0.0, -direction.z, direction.y))
          let v2: SIMD3<Float> = simd_normalize(simd_cross(direction, v1))

          // the model axes of the bond mesh: the sub-cylinders are displaced along them and the
          // selection patterns are wound from them
          let axisX: SIMD3<Float> = external ? -v1 : v2
          let axisZ: SIMD3<Float> = external ? -v2 : v1

          for sub in 0..<subCylinderCount
          {
            var radiusFactor: Float = 1.0
            let offset: SIMD2<Float> = MetalPathTracerShader.subCylinderOffset(type: type, sub: sub, radiusFactor: &radiusFactor)
            let displacement: SIMD3<Float> = bondScaling * (offset.x * axisX + offset.y * axisZ)
            let radius: Float = radiusScale * bondScaling * radiusFactor
            guard radius > 0.0 else {continue}

            let pointA: SIMD3<Float> = position1 + displacement
            let pointB: SIMD3<Float> = position2 + displacement

            var cylinder: RKPathTracerCylinder = RKPathTracerCylinder()
            cylinder.pointA = SIMD4<Float>(pointA.x, pointA.y, pointA.z, radius)
            cylinder.pointB = SIMD4<Float>(pointB.x, pointB.y, pointB.z, 0.0)
            cylinder.color1 = bond.color1
            cylinder.color2 = bond.color2
            cylinder.axisX = SIMD4<Float>(axisX.x, axisX.y, axisX.z, 0.0)
            cylinder.axisZ = SIMD4<Float>(axisZ.x, axisZ.y, axisZ.z, 0.0)
            cylinders.append(cylinder)

            let padding: SIMD3<Float> = SIMD3<Float>(repeating: radius)
            cylinderBoxes.append(MetalPathTracerShader.boundingBox(minimum: simd_min(pointA, pointB) - padding,
                                                                   maximum: simd_max(pointA, pointB) + padding))
            MetalPathTracerShader.expand(&minimum, &maximum, modelMatrix: modelMatrix, center: pointA, radius: radius)
            MetalPathTracerShader.expand(&minimum, &maximum, modelMatrix: modelMatrix, center: pointB, radius: radius)
          }
        }
      }

      guard cylinderBoxes.count > boxBase else {return}

      let descriptor: MTLPrimitiveAccelerationStructureDescriptor = MTLPrimitiveAccelerationStructureDescriptor()
      let geometry: MTLAccelerationStructureBoundingBoxGeometryDescriptor = MTLAccelerationStructureBoundingBoxGeometryDescriptor()
      // the cylinder intersection function sits at index 1 of the function table
      geometry.intersectionFunctionTableOffset = 1
      geometry.boundingBoxCount = cylinderBoxes.count - boxBase
      geometry.boundingBoxBufferOffset = boxBase * MemoryLayout<MTLAxisAlignedBoundingBox>.stride
      descriptor.geometryDescriptors = [geometry]
      pending.append((descriptor: descriptor, transform: modelMatrix, mask: selection.instanceMask))

      var instance: RKPathTracerInstance = RKPathTracerInstance()
      instance.kind = UInt32(PathTracerKind.cylinder.rawValue)
      instance.primitiveBase = UInt32(cylinderBase)
      instance.structureIndex = UInt32(structureIndex)
      instance.clipAtUnitCell = clipAtUnitCell ? 1 : 0
      instance.selectionStyle = selection.rawValue
      instances.append(instance)
    }

    /// Packs the triangles of the given ribbon draw `ranges`, along with the mesh vertices they index
    /// pushed `expansion` along their own normals, and records the instance that places them. The
    /// displacement is nothing for a ribbon itself and is what stands a selection shell off it
    /// otherwise, which is how `ribbonSelectionExpandedPosition` builds the raster overlay: a ribbon
    /// is a surface, so a shell over it cannot be had by scaling about a centre as for an atom.
    /// Does nothing when every range turns out to be empty.
    func appendRibbon(_ ribbonSource: RKRenderRibbonSource,
                      ranges: [RKRibbonChainDrawRange],
                      expansion: Float,
                      selection: PathTracerSelection)
    {
      let sourceVertices: [RKVertex] = ribbonSource.renderRibbonVertices
      let sourceIndices: [UInt32] = ribbonSource.renderRibbonIndices
      guard !sourceVertices.isEmpty else {return}

      let vertexBase: UInt32 = UInt32(ribbonVertices.count)
      let triangleBase: Int = ribbonIndices.count / 3

      for range in ranges
      {
        guard range.indexCount > 0 else {continue}
        let start: Int = range.indexStart
        let end: Int = min(start + range.indexCount, sourceIndices.count)
        guard start < end else {continue}
        for i in start..<end
        {
          ribbonIndices.append(sourceIndices[i] + vertexBase)
        }
      }

      guard ribbonIndices.count / 3 > triangleBase else
      {
        // nothing was selected, or every range was hidden: drop the indices appended above
        ribbonIndices.removeLast(ribbonIndices.count - triangleBase * 3)
        return
      }

      for vertex in sourceVertices
      {
        var displaced: RKVertex = vertex
        let normal: SIMD3<Float> = SIMD3<Float>(vertex.normal.x, vertex.normal.y, vertex.normal.z)
        let length: Float = simd_length(normal)
        if expansion != 0.0, length > 0.0
        {
          let offset: SIMD3<Float> = (expansion / length) * normal
          displaced.position = SIMD4<Float>(vertex.position.x + offset.x,
                                            vertex.position.y + offset.y,
                                            vertex.position.z + offset.z,
                                            vertex.position.w)
        }
        ribbonVertices.append(displaced)
        ribbonPositions.append(displaced.position.x)
        ribbonPositions.append(displaced.position.y)
        ribbonPositions.append(displaced.position.z)
        let point: SIMD3<Float> = SIMD3<Float>(displaced.position.x, displaced.position.y, displaced.position.z)
        MetalPathTracerShader.expand(&minimum, &maximum, modelMatrix: modelMatrix, center: point, radius: 0.0)
      }

      let descriptor: MTLPrimitiveAccelerationStructureDescriptor = MTLPrimitiveAccelerationStructureDescriptor()
      let geometry: MTLAccelerationStructureTriangleGeometryDescriptor = MTLAccelerationStructureTriangleGeometryDescriptor()
      geometry.triangleCount = ribbonIndices.count / 3 - triangleBase
      geometry.indexType = MTLIndexType.uint32
      geometry.indexBufferOffset = triangleBase * 3 * MemoryLayout<UInt32>.stride

      if selection == PathTracerSelection.striped
      {
        // the striped pattern has gaps, so which of the built-in test's hits count is settled by the
        // ribbon selection intersection function, at index 2 of the function table
        geometry.opaque = false
        geometry.intersectionFunctionTableOffset = 2
      }
      else
      {
        // triangles use the built-in intersection test rather than a function
        geometry.opaque = true
      }

      descriptor.geometryDescriptors = [geometry]
      pending.append((descriptor: descriptor, transform: modelMatrix, mask: selection.instanceMask))

      var instance: RKPathTracerInstance = RKPathTracerInstance()
      instance.kind = UInt32(PathTracerKind.ribbon.rawValue)
      instance.primitiveBase = UInt32(triangleBase)
      instance.structureIndex = UInt32(structureIndex)
      instance.clipAtUnitCell = 0
      instance.selectionStyle = selection.rawValue
      instances.append(instance)
    }

    for sceneStructures in renderStructures
    {
      for structure in sceneStructures
      {
        let uniforms: RKStructureUniforms = RKStructureUniforms(structureIdentifier: structureIndex, structure: structure)
        modelMatrix = uniforms.modelMatrix
        let isUnity: Bool = (structure as? RKRenderBondSource)?.isUnity ?? false

        // -- atoms ------------------------------------------------------------
        if let atomSource: RKRenderAtomSource = structure as? RKRenderAtomSource,
           atomSource.drawAtoms, structure.isVisible
        {
          let bondScaling: Float = Float((structure as? RKRenderBondSource)?.bondScaleFactor ?? 1.0)
          let radiusScale: Float = (isUnity ? bondScaling : 1.0) * Float(atomSource.atomScaleFactor)

          if atomSource.numberOfAtoms > 0
          {
            appendSpheres(atomSource.renderAtoms,
                          radiusScale: radiusScale,
                          selection: PathTracerSelection.none,
                          clipAtUnitCell: atomSource.clipAtomsAtUnitCell)
          }

          if let selection: PathTracerSelection = PathTracerSelection(atomSource.atomSelectionStyle)
          {
            appendSpheres(atomSource.renderSelectedAtoms,
                          radiusScale: radiusScale * MetalPathTracerShader.selectionScaling(atomSource.atomSelectionScaling),
                          selection: selection,
                          clipAtUnitCell: atomSource.clipAtomsAtUnitCell)
          }
        }

        // -- bonds ------------------------------------------------------------
        if let bondSource: RKRenderBondSource = structure as? RKRenderBondSource,
           bondSource.drawBonds, structure.isVisible
        {
          let bondScaling: Float = Float(bondSource.bondScaleFactor)

          appendCylinders([(bonds: bondSource.renderInternalBonds, external: false),
                           (bonds: bondSource.renderExternalBonds, external: true)],
                          bondScaling: bondScaling,
                          isUnity: isUnity,
                          radiusScale: 1.0,
                          selection: PathTracerSelection.none,
                          clipAtUnitCell: bondSource.clipBondsAtUnitCell)

          if let selection: PathTracerSelection = PathTracerSelection(bondSource.bondSelectionStyle)
          {
            // the 1.01 is the selection imposter's, which lifts the shell clear of its own bond
            appendCylinders([(bonds: bondSource.renderSelectedInternalBonds, external: false),
                             (bonds: bondSource.renderSelectedExternalBonds, external: true)],
                            bondScaling: bondScaling,
                            isUnity: isUnity,
                            radiusScale: 1.01 * MetalPathTracerShader.selectionScaling(bondSource.bondSelectionScaling),
                            selection: selection,
                            clipAtUnitCell: bondSource.clipBondsAtUnitCell)
          }
        }

        // -- ribbons ----------------------------------------------------------
        if let ribbonSource: RKRenderRibbonSource = structure as? RKRenderRibbonSource,
           ribbonSource.drawRibbon, structure.isVisible,
           ribbonSource.ribbonNumberOfIndices > 0,
           !ribbonSource.renderRibbonVertices.isEmpty
        {
          // only the visible draw ranges are included, so hidden chains and residues do
          // not show up in the path-traced image either
          appendRibbon(ribbonSource,
                       ranges: ribbonSource.ribbonDrawRangesForEncoding(),
                       expansion: 0.0,
                       selection: PathTracerSelection.none)

          // The selected residues and segments, marked on a shell standing off the ribbon. Which
          // style that shell wears is decided by the atom setting, there being no ribbon-specific
          // one, exactly as `MetalRibbonSelectionShader` decides it.
          if let atomSource: RKRenderAtomSource = structure as? RKRenderAtomSource,
             let selection: PathTracerSelection = PathTracerSelection(atomSource.atomSelectionStyle)
          {
            let expansion: Float = (MetalPathTracerShader.selectionScaling(atomSource.atomSelectionScaling) - 1.0) * selection.ribbonExpansionScale
            appendRibbon(ribbonSource,
                         ranges: MetalPathTracerShader.selectedRibbonDrawRanges(ribbonSource),
                         expansion: expansion,
                         selection: selection)
          }
        }

        structureIndex += 1
      }
    }

    hasGeometry = !instances.isEmpty
    sphereCount = spheres.count
    cylinderCount = cylinders.count
    triangleCount = ribbonIndices.count / 3
    guard hasGeometry else {return []}

    let extent: SIMD3<Float> = maximum - minimum
    sceneRadius = max(simd_length(extent), 1.0)

    sphereBuffer = MetalPathTracerShader.makeBuffer(device: device, spheres, label: "path tracer spheres")
    cylinderBuffer = MetalPathTracerShader.makeBuffer(device: device, cylinders, label: "path tracer cylinders")
    instanceDataBuffer = MetalPathTracerShader.makeBuffer(device: device, instances, label: "path tracer instance data")
    ribbonVertexBuffer = MetalPathTracerShader.makeBuffer(device: device, ribbonVertices, label: "path tracer ribbon vertices")
    ribbonIndexBuffer = MetalPathTracerShader.makeBuffer(device: device, ribbonIndices, label: "path tracer ribbon indices")

    let sphereBoxBuffer: MTLBuffer? = MetalPathTracerShader.makeBuffer(device: device, sphereBoxes, label: "path tracer sphere bounds")
    let cylinderBoxBuffer: MTLBuffer? = MetalPathTracerShader.makeBuffer(device: device, cylinderBoxes, label: "path tracer cylinder bounds")
    let ribbonPositionBuffer: MTLBuffer? = MetalPathTracerShader.makeBuffer(device: device, ribbonPositions, label: "path tracer ribbon positions")

    // the geometry descriptors were created before their buffers existed; attach them now
    for entry in pending
    {
      for geometry in entry.descriptor.geometryDescriptors ?? []
      {
        if let boundingBoxGeometry = geometry as? MTLAccelerationStructureBoundingBoxGeometryDescriptor
        {
          boundingBoxGeometry.boundingBoxBuffer = (boundingBoxGeometry.intersectionFunctionTableOffset == 0) ? sphereBoxBuffer : cylinderBoxBuffer
        }
        else if let triangleGeometry = geometry as? MTLAccelerationStructureTriangleGeometryDescriptor
        {
          triangleGeometry.vertexBuffer = ribbonPositionBuffer
          triangleGeometry.indexBuffer = ribbonIndexBuffer
        }
      }
    }

    return pending
  }

  // MARK: Acceleration structures
  // =====================================================================

  /// Builds the per-structure primitive acceleration structures and the top-level instance
  /// acceleration structure. Returns false when there is nothing to trace. The result is cached
  /// until `invalidateGeometry`, since the build has to be waited on and so would otherwise
  /// stall every interactive frame.
  private func buildAccelerationStructures(device: MTLDevice, commandQueue: MTLCommandQueue) -> Bool
  {
    guard #available(macOS 11.0, iOS 14.0, *) else {return false}

    if geometryIsValid, instanceAccelerationStructure != nil {return true}

    primitiveAccelerationStructures = []
    instanceAccelerationStructure = nil

    let pending: [(descriptor: MTLPrimitiveAccelerationStructureDescriptor, transform: float4x4, mask: UInt32)] = packGeometry(device: device)
    guard !pending.isEmpty else {return false}

    guard let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer(),
          let encoder: MTLAccelerationStructureCommandEncoder = commandBuffer.makeAccelerationStructureCommandEncoder() else {return false}

    var scratchBuffers: [MTLBuffer] = []
    for entry in pending
    {
      let sizes: MTLAccelerationStructureSizes = device.accelerationStructureSizes(descriptor: entry.descriptor)
      guard let accelerationStructure: MTLAccelerationStructure = device.makeAccelerationStructure(size: sizes.accelerationStructureSize) else
      {
        encoder.endEncoding()
        return false
      }
      guard let scratch: MTLBuffer = device.makeBuffer(length: max(sizes.buildScratchBufferSize, 1), options: MTLResourceOptions.storageModePrivate) else
      {
        encoder.endEncoding()
        return false
      }
      // held until the build has completed
      scratchBuffers.append(scratch)

      encoder.build(accelerationStructure: accelerationStructure, descriptor: entry.descriptor, scratchBuffer: scratch, scratchBufferOffset: 0)
      primitiveAccelerationStructures.append(accelerationStructure)
    }

    // the instance descriptors reference the primitive structures by index
    var instanceDescriptors: [MTLAccelerationStructureInstanceDescriptor] = []
    for (index, entry) in pending.enumerated()
    {
      var descriptor: MTLAccelerationStructureInstanceDescriptor = MTLAccelerationStructureInstanceDescriptor()
      descriptor.accelerationStructureIndex = UInt32(index)
      descriptor.options = MTLAccelerationStructureInstanceOptions(rawValue: 0)
      // keeps the selection shells out of every ray but the primary one
      descriptor.mask = entry.mask
      // the table slot is chosen per geometry, so no extra per-instance offset is needed
      descriptor.intersectionFunctionTableOffset = 0
      descriptor.transformationMatrix = MetalPathTracerShader.packedTransform(entry.transform)
      instanceDescriptors.append(descriptor)
    }

    guard let instanceDescriptorBuffer: MTLBuffer = MetalPathTracerShader.makeBuffer(device: device, instanceDescriptors, label: "path tracer instance descriptors") else
    {
      encoder.endEncoding()
      return false
    }

    let instanceDescriptor: MTLInstanceAccelerationStructureDescriptor = MTLInstanceAccelerationStructureDescriptor()
    instanceDescriptor.instancedAccelerationStructures = primitiveAccelerationStructures
    instanceDescriptor.instanceCount = instanceDescriptors.count
    instanceDescriptor.instanceDescriptorBuffer = instanceDescriptorBuffer
    instanceDescriptor.instanceDescriptorStride = MemoryLayout<MTLAccelerationStructureInstanceDescriptor>.stride

    let instanceSizes: MTLAccelerationStructureSizes = device.accelerationStructureSizes(descriptor: instanceDescriptor)
    guard let topLevel: MTLAccelerationStructure = device.makeAccelerationStructure(size: instanceSizes.accelerationStructureSize) else
    {
      encoder.endEncoding()
      return false
    }
    guard let instanceScratch: MTLBuffer = device.makeBuffer(length: max(instanceSizes.buildScratchBufferSize, 1), options: MTLResourceOptions.storageModePrivate) else
    {
      encoder.endEncoding()
      return false
    }
    scratchBuffers.append(instanceScratch)

    encoder.build(accelerationStructure: topLevel, descriptor: instanceDescriptor, scratchBuffer: instanceScratch, scratchBufferOffset: 0)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    instanceAccelerationStructure = topLevel
    geometryIsValid = true
    return true
  }

  // MARK: Rendering
  // =====================================================================

  /// Traces `settings.sampleCount` paths per pixel and composites the result over
  /// `sceneColorTexture`, respecting `sceneDepthTexture` so rasterized primitives that are
  /// nearer than the traced geometry stay visible. Returns the composited texture, or nil
  /// when the path tracer is unavailable or the scene holds no traceable geometry.
  /// Records why the path tracer bailed out and logs it, for the in-process callers that can
  /// see the log window.
  private func fail(_ reason: String) -> MTLTexture?
  {
    lastStatus = reason
    LogQueue.shared.warning(destination: nil, message: "Path tracer: \(reason), rasterizing instead")
    return nil
  }

  /// Everything the two kernels need, resolved once so the encode helpers stay readable.
  private struct Resources
  {
    let accumulatePipeline: MTLComputePipelineState
    let resolvePipeline: MTLComputePipelineState
    let functionTable: MTLIntersectionFunctionTable
    let accelerationStructure: MTLAccelerationStructure
    let sphereBuffer: MTLBuffer
    let cylinderBuffer: MTLBuffer
    let instanceDataBuffer: MTLBuffer
    let ribbonVertexBuffer: MTLBuffer
    let ribbonIndexBuffer: MTLBuffer
    let accumulationBuffer: MTLBuffer
    let indirectBuffer: MTLBuffer
    let surfaceInfoBuffer: MTLBuffer
    let selectionBuffer: MTLBuffer
    let compositeDepthBuffer: MTLBuffer
    let compositeCueMaskBuffer: MTLBuffer
    let compositeTexture: MTLTexture
    let structureUniformBuffers: MTLBuffer
    let lightUniformBuffers: MTLBuffer
    let sceneColorTexture: MTLTexture
    let sceneDepthTexture: MTLTexture
  }

  /// Resolves the pipelines, per-size buffers and acceleration structures, building whatever is
  /// missing. Returns nil, after recording why, when the path tracer cannot run.
  private func prepare(device: MTLDevice,
                       commandQueue: MTLCommandQueue,
                       size: CGSize,
                       structureUniformBuffers: MTLBuffer?,
                       lightUniformBuffers: MTLBuffer?,
                       sceneColorTexture: MTLTexture?,
                       sceneDepthTexture: MTLTexture?) -> Resources?
  {
    guard #available(macOS 11.0, iOS 14.0, *) else {_ = fail("needs macOS 11 or later"); return nil}

    guard let accumulatePipeline = accumulatePipeline,
          let resolvePipeline = resolvePipeline,
          let functionTable = intersectionFunctionTable else {_ = fail("the compute pipelines were not built"); return nil}

    guard let structureUniformBuffers = structureUniformBuffers,
          let lightUniformBuffers = lightUniformBuffers,
          let sceneColorTexture = sceneColorTexture,
          let sceneDepthTexture = sceneDepthTexture else {_ = fail("the uniform buffers or the rasterized scene textures are missing"); return nil}

    buildTextures(device: device, size: size)

    guard let accumulationBuffer = accumulationBuffer,
          let indirectBuffer = indirectBuffer,
          let surfaceInfoBuffer = surfaceInfoBuffer,
          let selectionBuffer = selectionBuffer,
          let compositeDepthBuffer = compositeDepthBuffer,
          let compositeCueMaskBuffer = compositeCueMaskBuffer,
          let compositeTexture = compositeTexture else {_ = fail("could not allocate the accumulation buffers"); return nil}

    guard buildAccelerationStructures(device: device, commandQueue: commandQueue),
          let accelerationStructure = instanceAccelerationStructure,
          let sphereBuffer = sphereBuffer,
          let cylinderBuffer = cylinderBuffer,
          let instanceDataBuffer = instanceDataBuffer,
          let ribbonVertexBuffer = ribbonVertexBuffer,
          let ribbonIndexBuffer = ribbonIndexBuffer else {_ = fail("no traceable geometry, or the acceleration structures could not be built"); return nil}

    // the intersection functions reach their geometry through the function table, which
    // Metal does not track automatically
    functionTable.setBuffer(sphereBuffer, offset: 0, index: 0)
    functionTable.setBuffer(instanceDataBuffer, offset: 0, index: 1)
    functionTable.setBuffer(structureUniformBuffers, offset: 0, index: 2)
    functionTable.setBuffer(cylinderBuffer, offset: 0, index: 3)
    functionTable.setBuffer(ribbonVertexBuffer, offset: 0, index: 4)
    functionTable.setBuffer(ribbonIndexBuffer, offset: 0, index: 5)

    return Resources(accumulatePipeline: accumulatePipeline,
                     resolvePipeline: resolvePipeline,
                     functionTable: functionTable,
                     accelerationStructure: accelerationStructure,
                     sphereBuffer: sphereBuffer,
                     cylinderBuffer: cylinderBuffer,
                     instanceDataBuffer: instanceDataBuffer,
                     ribbonVertexBuffer: ribbonVertexBuffer,
                     ribbonIndexBuffer: ribbonIndexBuffer,
                     accumulationBuffer: accumulationBuffer,
                     indirectBuffer: indirectBuffer,
                     surfaceInfoBuffer: surfaceInfoBuffer,
                     selectionBuffer: selectionBuffer,
                     compositeDepthBuffer: compositeDepthBuffer,
                     compositeCueMaskBuffer: compositeCueMaskBuffer,
                     compositeTexture: compositeTexture,
                     structureUniformBuffers: structureUniformBuffers,
                     lightUniformBuffers: lightUniformBuffers,
                     sceneColorTexture: sceneColorTexture,
                     sceneDepthTexture: sceneDepthTexture)
  }

  /// Baseline uniforms for a trace at `size`, before the per-dispatch sample range is filled in.
  private func baseUniforms(size: CGSize, settings: RKPathTracerSettings) -> RKPathTracerUniforms
  {
    var uniforms: RKPathTracerUniforms = RKPathTracerUniforms()
    uniforms.width = UInt32(max(Int(size.width), 1))
    uniforms.height = UInt32(max(Int(size.height), 1))
    uniforms.maximumBounces = UInt32(settings.effectiveMaximumBounces)
    uniforms.rayEpsilon = 1.0e-4 * sceneRadius
    uniforms.ambientOcclusionStrength = settings.ambientOcclusionStrength
    return uniforms
  }

  private static let threadgroupSize: MTLSize = MTLSize(width: 8, height: 8, depth: 1)

  private func threadgroups(size: CGSize) -> MTLSize
  {
    let width: Int = max(Int(size.width), 1)
    let height: Int = max(Int(size.height), 1)
    let group: MTLSize = MetalPathTracerShader.threadgroupSize
    return MTLSize(width: (width + group.width - 1) / group.width,
                   height: (height + group.height - 1) / group.height,
                   depth: 1)
  }

  private func encodeAccumulate(commandBuffer: MTLCommandBuffer,
                                resources: Resources,
                                uniforms: inout RKPathTracerUniforms,
                                frameUniformBuffer: MTLBuffer,
                                threadgroups: MTLSize) -> Bool
  {
    guard #available(macOS 11.0, iOS 14.0, *) else {return false}
    guard let encoder: MTLComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder() else {return false}

    encoder.label = "Path tracer accumulate encoder"
    encoder.setComputePipelineState(resources.accumulatePipeline)
    encoder.setBytes(&uniforms, length: MemoryLayout<RKPathTracerUniforms>.stride, index: 0)
    encoder.setBuffer(frameUniformBuffer, offset: 0, index: 1)
    encoder.setBuffer(resources.structureUniformBuffers, offset: 0, index: 2)
    encoder.setBuffer(resources.lightUniformBuffers, offset: 0, index: 3)
    encoder.setBuffer(resources.sphereBuffer, offset: 0, index: 4)
    encoder.setBuffer(resources.cylinderBuffer, offset: 0, index: 5)
    encoder.setBuffer(resources.instanceDataBuffer, offset: 0, index: 6)
    encoder.setBuffer(resources.ribbonVertexBuffer, offset: 0, index: 7)
    encoder.setBuffer(resources.ribbonIndexBuffer, offset: 0, index: 8)
    encoder.setAccelerationStructure(resources.accelerationStructure, bufferIndex: 9)
    encoder.setIntersectionFunctionTable(resources.functionTable, bufferIndex: 10)
    encoder.setBuffer(resources.accumulationBuffer, offset: 0, index: 11)
    encoder.setBuffer(resources.surfaceInfoBuffer, offset: 0, index: 12)
    encoder.setBuffer(resources.indirectBuffer, offset: 0, index: 13)
    encoder.setBuffer(resources.selectionBuffer, offset: 0, index: 14)

    // residency of everything reached indirectly
    for structure in primitiveAccelerationStructures
    {
      encoder.useResource(structure, usage: MTLResourceUsage.read)
    }
    encoder.useResource(resources.sphereBuffer, usage: MTLResourceUsage.read)
    encoder.useResource(resources.cylinderBuffer, usage: MTLResourceUsage.read)
    encoder.useResource(resources.instanceDataBuffer, usage: MTLResourceUsage.read)
    encoder.useResource(resources.structureUniformBuffers, usage: MTLResourceUsage.read)
    encoder.useResource(resources.ribbonVertexBuffer, usage: MTLResourceUsage.read)
    encoder.useResource(resources.ribbonIndexBuffer, usage: MTLResourceUsage.read)

    encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: MetalPathTracerShader.threadgroupSize)
    encoder.endEncoding()
    return true
  }

  private func encodeResolve(commandBuffer: MTLCommandBuffer,
                             resources: Resources,
                             uniforms: inout RKPathTracerUniforms,
                             threadgroups: MTLSize) -> Bool
  {
    guard let encoder: MTLComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder() else {return false}

    encoder.label = "Path tracer resolve encoder"
    encoder.setComputePipelineState(resources.resolvePipeline)
    encoder.setBytes(&uniforms, length: MemoryLayout<RKPathTracerUniforms>.stride, index: 0)
    encoder.setBuffer(resources.structureUniformBuffers, offset: 0, index: 1)
    encoder.setBuffer(resources.accumulationBuffer, offset: 0, index: 2)
    encoder.setBuffer(resources.surfaceInfoBuffer, offset: 0, index: 3)
    encoder.setBuffer(resources.indirectBuffer, offset: 0, index: 4)
    encoder.setBuffer(resources.compositeDepthBuffer, offset: 0, index: 5)
    encoder.setBuffer(resources.compositeCueMaskBuffer, offset: 0, index: 6)
    encoder.setBuffer(resources.selectionBuffer, offset: 0, index: 7)
    encoder.setTexture(resources.sceneColorTexture, index: 0)
    encoder.setTexture(resources.sceneDepthTexture, index: 1)
    encoder.setTexture(resources.compositeTexture, index: 2)
    encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: MetalPathTracerShader.threadgroupSize)
    encoder.endEncoding()
    return true
  }

  public func render(device: MTLDevice,
                     commandQueue: MTLCommandQueue,
                     size: CGSize,
                     settings: RKPathTracerSettings,
                     frameUniformBuffer: MTLBuffer,
                     structureUniformBuffers: MTLBuffer?,
                     lightUniformBuffers: MTLBuffer?,
                     sceneColorTexture: MTLTexture?,
                     sceneDepthTexture: MTLTexture?) -> MTLTexture?
  {
    guard let resources: Resources = prepare(device: device,
                                             commandQueue: commandQueue,
                                             size: size,
                                             structureUniformBuffers: structureUniformBuffers,
                                             lightUniformBuffers: lightUniformBuffers,
                                             sceneColorTexture: sceneColorTexture,
                                             sceneDepthTexture: sceneDepthTexture) else {return nil}

    LogQueue.shared.info(destination: nil, message: "Path tracer: \(sphereCount) atoms, \(cylinderCount) bond cylinders, \(triangleCount) ribbon triangles in \(primitiveAccelerationStructures.count) acceleration structures")

    let startTime: Date = Date()
    let groups: MTLSize = threadgroups(size: size)

    var uniforms: RKPathTracerUniforms = baseUniforms(size: size, settings: settings)
    uniforms.accumulatedSamples = Float(settings.sampleCount)

    // Samples are traced in batches, one command buffer each, so no single dispatch runs
    // long enough for the GPU watchdog to reset the device on a large image.
    var sampleOffset: Int = 0
    while sampleOffset < settings.sampleCount
    {
      let batch: Int = min(settings.samplesPerDispatch, settings.sampleCount - sampleOffset)
      uniforms.sampleOffset = UInt32(sampleOffset)
      uniforms.samplesPerDispatch = UInt32(batch)
      uniforms.seed = UInt32(truncatingIfNeeded: sampleOffset &* 9781 &+ 1)

      guard let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer() else {return nil}
      guard encodeAccumulate(commandBuffer: commandBuffer, resources: resources, uniforms: &uniforms, frameUniformBuffer: frameUniformBuffer, threadgroups: groups) else {return nil}
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()

      sampleOffset += batch
    }
    accumulatedSampleCount = settings.sampleCount

    guard let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer() else {return nil}
    guard encodeResolve(commandBuffer: commandBuffer, resources: resources, uniforms: &uniforms, threadgroups: groups) else {return nil}
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    let elapsed: Double = Date().timeIntervalSince(startTime)
    lastStatus = "traced \(uniforms.width)x\(uniforms.height), \(sphereCount) atoms, \(cylinderCount) bond cylinders, \(triangleCount) ribbon triangles, \(settings.sampleCount) samples per pixel, \(uniforms.maximumBounces) bounces, ambient occlusion strength \(settings.ambientOcclusionStrength), in \(String(format: "%.2f", elapsed)) s"
    LogQueue.shared.info(destination: nil, message: "Path tracer: \(lastStatus)")

    return compositeTexture
  }

  // MARK: Interactive rendering
  // =====================================================================

  /// Traces `samplesThisFrame` samples per pixel and composites them over the rasterized scene,
  /// encoding into the caller's command buffer so nothing blocks the frame. Returns the composited
  /// texture to present, or nil to fall back to the raster image.
  ///
  /// Each frame is a complete trace: no samples carry over. Averaging across frames would be
  /// cheaper for a still camera, but the image would then depend on how many frames had gone into
  /// it, and moving the camera would visibly shift the shading. Starting fresh every frame means
  /// the only difference between a moving and a still frame is how much noise is on it.
  ///
  /// The first call after an invalidation still has to build the acceleration structures, and
  /// that build is waited on, so it shows up as a single dropped frame.
  public func encodeInteractive(device: MTLDevice,
                                commandQueue: MTLCommandQueue,
                                commandBuffer: MTLCommandBuffer,
                                size: CGSize,
                                settings: RKPathTracerSettings,
                                samplesThisFrame: Int,
                                frameUniformBuffer: MTLBuffer,
                                structureUniformBuffers: MTLBuffer?,
                                lightUniformBuffers: MTLBuffer?,
                                sceneColorTexture: MTLTexture?,
                                sceneDepthTexture: MTLTexture?) -> MTLTexture?
  {
    guard let resources: Resources = prepare(device: device,
                                             commandQueue: commandQueue,
                                             size: size,
                                             structureUniformBuffers: structureUniformBuffers,
                                             lightUniformBuffers: lightUniformBuffers,
                                             sceneColorTexture: sceneColorTexture,
                                             sceneDepthTexture: sceneDepthTexture) else {return nil}

    let groups: MTLSize = threadgroups(size: size)
    let batch: Int = max(samplesThisFrame, 1)

    var uniforms: RKPathTracerUniforms = baseUniforms(size: size, settings: settings)
    // a sample offset of zero tells the kernel to clear the buffers rather than add to them
    uniforms.sampleOffset = 0
    uniforms.samplesPerDispatch = UInt32(batch)
    uniforms.seed = UInt32(truncatingIfNeeded: frameSeedCounter &* 9781 &+ 1)
    uniforms.accumulatedSamples = Float(batch)
    frameSeedCounter += 1

    guard encodeAccumulate(commandBuffer: commandBuffer, resources: resources, uniforms: &uniforms, frameUniformBuffer: frameUniformBuffer, threadgroups: groups) else {return nil}
    guard encodeResolve(commandBuffer: commandBuffer, resources: resources, uniforms: &uniforms, threadgroups: groups) else {return nil}

    accumulatedSampleCount = batch
    lastStatus = "interactive, \(batch) samples per pixel"

    if #available(macOS 10.15, iOS 13.0, *)
    {
      let width: UInt32 = uniforms.width
      let height: UInt32 = uniforms.height
      commandBuffer.addCompletedHandler
      {buffer in
        let elapsed: Double = buffer.gpuEndTime - buffer.gpuStartTime
        guard elapsed > 0.0 else {return}
        // at most one line per second, so rotating does not flood the log
        let now: Date = Date()
        guard now.timeIntervalSince(self.lastFrameReportTime) > 1.0 else {return}
        self.lastFrameReportTime = now
        LogQueue.shared.verbose(destination: nil, message: "Path tracer: interactive frame of \(batch) samples per pixel at \(width)x\(height) took \(String(format: "%.0f", elapsed * 1000.0)) ms on the GPU (\(String(format: "%.1f", 1.0 / elapsed)) frames per second)")
      }
    }

    return resources.compositeTexture
  }

  // MARK: Shadows for the rasterizer
  // =====================================================================

  /// True when this device and library can trace the shadow mask.
  public var canTraceShadows: Bool
  {
    return shadowMaskPipeline != nil && shadowMaskFunctionTable != nil
  }

  /// Traces which lights reach the molecular surface at each pixel and returns the mask for the
  /// raster shaders to sample. Encodes into the caller's command buffer, which must be the one that
  /// goes on to draw the scene.
  ///
  /// The first call after the geometry changes builds the acceleration structures, which is waited
  /// on and so costs a frame; every call after that reuses them.
  ///
  /// Returns nil when shadows cannot be traced, and the caller then draws unshadowed as before.
  public func encodeShadowMask(device: MTLDevice,
                               commandQueue: MTLCommandQueue,
                               commandBuffer: MTLCommandBuffer,
                               size: CGSize,
                               frameUniformBuffer: MTLBuffer,
                               structureUniformBuffers: MTLBuffer?,
                               lightUniformBuffers: MTLBuffer?) -> MTLTexture?
  {
    guard #available(macOS 11.0, iOS 14.0, *) else {return nil}

    guard let pipeline = shadowMaskPipeline,
          let functionTable = shadowMaskFunctionTable,
          let structureUniformBuffers = structureUniformBuffers,
          let lightUniformBuffers = lightUniformBuffers else {return nil}

    buildShadowMaskTexture(device: device, size: size)
    guard let shadowMaskTexture = shadowMaskTexture else {return nil}

    guard buildAccelerationStructures(device: device, commandQueue: commandQueue),
          let accelerationStructure = instanceAccelerationStructure,
          let sphereBuffer = sphereBuffer,
          let cylinderBuffer = cylinderBuffer,
          let instanceDataBuffer = instanceDataBuffer,
          let ribbonVertexBuffer = ribbonVertexBuffer,
          let ribbonIndexBuffer = ribbonIndexBuffer else {return nil}

    functionTable.setBuffer(sphereBuffer, offset: 0, index: 0)
    functionTable.setBuffer(instanceDataBuffer, offset: 0, index: 1)
    functionTable.setBuffer(structureUniformBuffers, offset: 0, index: 2)
    functionTable.setBuffer(cylinderBuffer, offset: 0, index: 3)
    functionTable.setBuffer(ribbonVertexBuffer, offset: 0, index: 4)
    functionTable.setBuffer(ribbonIndexBuffer, offset: 0, index: 5)

    guard let encoder: MTLComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder() else {return nil}

    var uniforms: RKPathTracerUniforms = RKPathTracerUniforms()
    uniforms.width = UInt32(max(Int(size.width), 1))
    uniforms.height = UInt32(max(Int(size.height), 1))
    uniforms.rayEpsilon = 1.0e-4 * sceneRadius

    encoder.label = "Path tracer shadow mask encoder"
    encoder.setComputePipelineState(pipeline)
    encoder.setBytes(&uniforms, length: MemoryLayout<RKPathTracerUniforms>.stride, index: 0)
    encoder.setBuffer(frameUniformBuffer, offset: 0, index: 1)
    encoder.setBuffer(structureUniformBuffers, offset: 0, index: 2)
    encoder.setBuffer(lightUniformBuffers, offset: 0, index: 3)
    encoder.setBuffer(instanceDataBuffer, offset: 0, index: 4)
    encoder.setBuffer(ribbonVertexBuffer, offset: 0, index: 5)
    encoder.setBuffer(ribbonIndexBuffer, offset: 0, index: 6)
    encoder.setAccelerationStructure(accelerationStructure, bufferIndex: 7)
    encoder.setIntersectionFunctionTable(functionTable, bufferIndex: 8)
    encoder.setTexture(shadowMaskTexture, index: 0)

    for structure in primitiveAccelerationStructures
    {
      encoder.useResource(structure, usage: MTLResourceUsage.read)
    }
    encoder.useResource(sphereBuffer, usage: MTLResourceUsage.read)
    encoder.useResource(cylinderBuffer, usage: MTLResourceUsage.read)
    encoder.useResource(instanceDataBuffer, usage: MTLResourceUsage.read)
    encoder.useResource(structureUniformBuffers, usage: MTLResourceUsage.read)
    encoder.useResource(ribbonVertexBuffer, usage: MTLResourceUsage.read)
    encoder.useResource(ribbonIndexBuffer, usage: MTLResourceUsage.read)

    encoder.dispatchThreadgroups(threadgroups(size: size), threadsPerThreadgroup: MetalPathTracerShader.threadgroupSize)
    encoder.endEncoding()

    return shadowMaskTexture
  }

  // MARK: Helpers
  // =====================================================================

  private enum PathTracerKind: Int
  {
    case sphere = 0
    case cylinder = 1
    case ribbon = 2
  }

  /// Mirrors PATH_TRACER_SELECTION_* of PathTracerCommon.h.
  private enum PathTracerSelection: UInt32
  {
    case none = 0
    case worley = 1
    case striped = 2

    /// The style of shell to pack for a selection, or nil when the tracer draws none: `none`
    /// selects nothing, and the glow style is drawn by the rasterizer's blur pass, which composites
    /// it over the traced image afterwards.
    init?(_ style: RKSelectionStyle)
    {
      switch style
      {
      case RKSelectionStyle.WorleyNoise3D: self = PathTracerSelection.worley
      case RKSelectionStyle.striped: self = PathTracerSelection.striped
      default: return nil
      }
    }

    /// Mirrors PATH_TRACER_MASK_* of PathTracerCommon.h.
    var instanceMask: UInt32
    {
      return (self == PathTracerSelection.none) ? 0x1 : 0x2
    }

    /// How far a ribbon selection shell stands off the ribbon, as a fraction of what
    /// `atomSelectionScaling` asks for. The striped style is lifted further than the Worley-noise
    /// one, as `ribbonSelectionExpandedPosition` lifts it: its pattern has gaps, and a shell too
    /// close to its ribbon shows through them as much as beside them. Atoms and bonds have no
    /// equivalent, their shells being scaled about a centre rather than pushed along a surface.
    var ribbonExpansionScale: Float
    {
      return (self == PathTracerSelection.striped) ? 0.45 : 0.2
    }
  }

  /// A selection scaling as the shaders receive it. `RKStructureUniforms` never passes one through
  /// unenlarged, so neither does the packing here: a shell exactly on the surface it marks would be
  /// at the very limit the selection ray stops at, and would be met or missed by rounding alone.
  private static func selectionScaling(_ scaling: Double) -> Float
  {
    return Float(max(RKStructureUniforms.minimumSelectionScaling, scaling))
  }

  /// The draw ranges of the selected residues and segments of a ribbon, hidden ones left out. The
  /// same set `MetalRibbonSelectionShader` draws its overlay over.
  private static func selectedRibbonDrawRanges(_ ribbonSource: RKRenderRibbonSource) -> [RKRibbonChainDrawRange]
  {
    var ranges: [RKRibbonChainDrawRange] = []

    for index in ribbonSource.renderSelectedRibbonSegmentDrawRangeIndices.sorted()
    {
      guard index >= 0, index < ribbonSource.ribbonSegmentDrawRanges.count else {continue}
      if ribbonSource.ribbonUsesSegmentVisibility, !ribbonSource.isRibbonSegmentDrawRangeVisible(at: index) {continue}
      ranges.append(ribbonSource.ribbonSegmentDrawRanges[index])
    }

    for index in ribbonSource.renderSelectedRibbonResidueDrawRangeIndices.sorted()
    {
      guard index >= 0, index < ribbonSource.ribbonResidueDrawRanges.count else {continue}
      if ribbonSource.ribbonUsesResidueVisibility, !ribbonSource.isRibbonResidueDrawRangeVisible(at: index) {continue}
      ranges.append(ribbonSource.ribbonResidueDrawRanges[index])
    }

    return ranges
  }

  /// Number of sub-cylinders drawn for a bond type, matching `bondImposterSubCylinderOffset`.
  private static func subCylinderCount(type: Int) -> Int
  {
    switch type
    {
    case 1: return 2    // double
    case 3: return 3    // triple
    default: return 1
    }
  }

  /// In-plane displacement of a sub-cylinder, in the model x/z of the bond. Mirrors
  /// `bondImposterSubCylinderOffset` of BondCylinderShader.metal.
  private static func subCylinderOffset(type: Int, sub: Int, radiusFactor: inout Float) -> SIMD2<Float>
  {
    radiusFactor = 1.0
    if type == 1
    {
      radiusFactor = 0.8
      return SIMD2<Float>(sub == 0 ? -1.0 : 1.0, 0.0)
    }
    if type == 3
    {
      radiusFactor = 0.8
      let dz: Float = 0.5 * sqrt(3.0)
      if sub == 0 {return SIMD2<Float>(-1.0, -dz)}
      if sub == 1 {return SIMD2<Float>(1.0, -dz)}
      return SIMD2<Float>(0.0, dz)
    }
    return SIMD2<Float>(0.0, 0.0)
  }

  private static func boundingBox(minimum: SIMD3<Float>, maximum: SIMD3<Float>) -> MTLAxisAlignedBoundingBox
  {
    var box: MTLAxisAlignedBoundingBox = MTLAxisAlignedBoundingBox()
    box.min = MTLPackedFloat3Make(minimum.x, minimum.y, minimum.z)
    box.max = MTLPackedFloat3Make(maximum.x, maximum.y, maximum.z)
    return box
  }

  /// Grows the world-space bounds, used only to scale the secondary-ray offset.
  private static func expand(_ minimum: inout SIMD3<Float>, _ maximum: inout SIMD3<Float>, modelMatrix: float4x4, center: SIMD3<Float>, radius: Float)
  {
    let world: SIMD4<Float> = modelMatrix * SIMD4<Float>(center.x, center.y, center.z, 1.0)
    let point: SIMD3<Float> = SIMD3<Float>(world.x, world.y, world.z)
    minimum = simd_min(minimum, point - SIMD3<Float>(repeating: radius))
    maximum = simd_max(maximum, point + SIMD3<Float>(repeating: radius))
  }

  private static func packedTransform(_ matrix: float4x4) -> MTLPackedFloat4x3
  {
    var packed: MTLPackedFloat4x3 = MTLPackedFloat4x3()
    packed.columns.0 = MTLPackedFloat3Make(matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z)
    packed.columns.1 = MTLPackedFloat3Make(matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z)
    packed.columns.2 = MTLPackedFloat3Make(matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z)
    packed.columns.3 = MTLPackedFloat3Make(matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z)
    return packed
  }

  /// Creates a buffer from an array, substituting a one-element placeholder for an empty
  /// array so the shader bindings are always valid.
  private static func makeBuffer<T>(device: MTLDevice, _ array: [T], label: String) -> MTLBuffer?
  {
    let count: Int = max(array.count, 1)
    let length: Int = MemoryLayout<T>.stride * count
    let buffer: MTLBuffer?
    if array.isEmpty
    {
      buffer = device.makeBuffer(length: length, options: RKMetal.hostStorage)
    }
    else
    {
      buffer = array.withUnsafeBytes
      {
        device.makeBuffer(bytes: $0.baseAddress!, length: length, options: RKMetal.hostStorage)
      }
      RKMetal.didModify(buffer, range: 0..<length)
    }
    buffer?.label = label
    return buffer
  }
}
