/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import LogViewKit
import simd
import Metal
import SymmetryKit

extension float4x4
{
  init(Double3x3: double3x3)
  {
    self.init([SIMD4<Float>(x: Float(Double3x3[0][0]), y: Float(Double3x3[0][1]), z: Float(Double3x3[0][2]), w: 0.0),
               SIMD4<Float>(x: Float(Double3x3[1][0]), y: Float(Double3x3[1][1]), z: Float(Double3x3[1][2]), w: 0.0),
               SIMD4<Float>(x: Float(Double3x3[2][0]), y: Float(Double3x3[2][1]), z: Float(Double3x3[2][2]), w:0.0),
               SIMD4<Float>(x: 0.0, y: 0.0, z: 0.0, w: 1.0)])
  }
}

extension float3x3
{
  init(Double3x3: double3x3)
  {
    self.init([SIMD3<Float>(x: Float(Double3x3[0][0]), y: Float(Double3x3[0][1]), z: Float(Double3x3[0][2])),
               SIMD3<Float>(x: Float(Double3x3[1][0]), y: Float(Double3x3[1][1]), z: Float(Double3x3[1][2])),
               SIMD3<Float>(x: Float(Double3x3[2][0]), y: Float(Double3x3[2][1]), z: Float(Double3x3[2][2]))])
  }
}

public class SKMetalFramework
{
  var positions: [SIMD3<Double>] = []
  var potentialParameters: [SIMD2<Double>] = []
  var unitCell: double3x3 = double3x3()
  var replicaCell: double3x3 = double3x3()
  var inverseCell: double3x3 = double3x3()
  var numberOfReplicas: SIMD3<Int32> = SIMD3<Int32>(1,1,1)
  var totalNumberOfReplicas: Int = 1
  var totalNumberOfAtoms: Int = 0
  
  var pipelineState: MTLComputePipelineState? = nil
  var device: MTLDevice
  var commandQueue: MTLCommandQueue
  var defaultLibrary: MTLLibrary
  
  init(device: MTLDevice, commandQueue: MTLCommandQueue)
  {
    self.device = device
    self.commandQueue = commandQueue
    
    let bundle: Bundle = Bundle(for: SKMetalFramework.self)
    let file: String = bundle.path(forResource: "default", ofType: "metallib")!
    defaultLibrary = try! self.device.makeLibrary(filepath: file)
  }
  
  public convenience init(device: MTLDevice, commandQueue: MTLCommandQueue, positions: [SIMD3<Double>], potentialParameters: [SIMD2<Double>], unitCell: double3x3, numberOfReplicas: SIMD3<Int32>)
  {
    self.init(device: device, commandQueue: commandQueue)
    self.numberOfReplicas = numberOfReplicas
    self.totalNumberOfReplicas = Int(numberOfReplicas.x * numberOfReplicas.y * numberOfReplicas.z)
    self.positions = positions
    self.potentialParameters = potentialParameters
    self.unitCell = unitCell
    self.replicaCell = double3x3([Double(numberOfReplicas.x) * unitCell[0], Double(numberOfReplicas.y) * unitCell[1],Double(numberOfReplicas.z) * unitCell[2]])
    self.inverseCell = replicaCell.inverse
    self.totalNumberOfAtoms = positions.count
    
    if let kernelFunction: MTLFunction = defaultLibrary.makeFunction(name: "ComputeEnergyGrid")
    {
      let computePipeLine: MTLComputePipelineDescriptor = MTLComputePipelineDescriptor()
      computePipeLine.computeFunction = kernelFunction
      computePipeLine.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
      
      do
      {
        pipelineState = try device.makeComputePipelineState(descriptor: computePipeLine, options: [], reflection: nil)
      }
      catch
      {
        fatalError("Error occurred when creating compute pipeline state \(error)")
      }
    }
    
  }
  
  public func ComputeEnergyGrid(_ sizeX: Int, sizeY: Int, sizeZ: Int, probeParameter: SIMD2<Double>) -> [Float]
  {
    if let pipelineState = self.pipelineState
    {
      let threadGroupCount: Int = pipelineState.threadExecutionWidth
      
      //let NumberOfAtoms: Int = self.positions.count
      let temp: Int = sizeX*sizeY*sizeZ
      let NumberOfGridPoints: Int = temp + (threadGroupCount - (temp & (threadGroupCount-1)))
      
      var pos: [SIMD4<Float>] = [SIMD4<Float>](repeating: SIMD4<Float>(0,0,0,0), count: totalNumberOfAtoms)
      var parameters: [SIMD2<Float>] = [SIMD2<Float>](repeating: SIMD2<Float>(0,0), count: totalNumberOfAtoms)
      
      var gridPos: [SIMD4<Float>] = [SIMD4<Float>](repeating: SIMD4<Float>(0,0,0,0), count: NumberOfGridPoints)
      let output: [Float] = [Float](repeating: 0.0, count: NumberOfGridPoints)
      
      let correction: SIMD3<Double> = SIMD3<Double>(1.0/Double(numberOfReplicas.x), 1.0/Double(numberOfReplicas.y), 1.0/Double(numberOfReplicas.z))
      if (totalNumberOfAtoms > 0)
      {
        for i in 0..<totalNumberOfAtoms
        {
          let position: SIMD3<Double> = positions[i] * correction
          let currentPotentialParameters: SIMD2<Double> = self.potentialParameters[i]
          
          // fill in the Cartesian position
          pos[i] = SIMD4<Float>(Float(position.x), Float(position.y), Float(position.z), 0.0)
          
          // use 4 x epsilon for a probe epsilon of unity
          parameters[i] = SIMD2<Float>(Float(4.0*sqrt(currentPotentialParameters.x * probeParameter.x)),
                                 Float(0.5 * (currentPotentialParameters.y + probeParameter.y)))
        }
        
        var index: Int = 0
        for k in 0..<sizeZ
        {
          for j in 0..<sizeY
          {
            // X various the fastest (contiguous in x)
            for i in 0..<sizeX
            {
              let position: SIMD3<Double> = correction * SIMD3<Double>(Double(i)/Double(sizeX-1),Double(j)/Double(sizeY-1),Double(k)/Double(sizeZ-1))
              gridPos[index] = SIMD4<Float>(Float(position.x), Float(position.y), Float(position.z), Float(0.0))
              index += 1
            }
          }
        }
        
      }
      
      var replicasBufferValue: [SIMD4<Float>] = [SIMD4<Float>](repeating: SIMD4<Float>(0,0,0,0), count: totalNumberOfReplicas)
      var index = 0
      for i in 0..<numberOfReplicas.x
      {
        for j in 0..<numberOfReplicas.y
        {
          for k in 0..<numberOfReplicas.z
          {
            replicasBufferValue[index] = SIMD4<Float>(Float(Double(i)/Double(numberOfReplicas.x)), Float(Double(j)/Double(numberOfReplicas.y)), Float(Double(k)/Double(numberOfReplicas.z)), Float(0.0))
            index += 1
          }
        }
      }
      
      var NumberOfReplicasBufferValue: Int32 = Int32(totalNumberOfReplicas)
      
      var cell3x3Float: float3x3 = float3x3(Double3x3: replicaCell)
      let bufferAtomPositions: MTLBuffer = device.makeBuffer(bytes: pos, length: pos.count * MemoryLayout<SIMD4<Float>>.stride, options: .storageModeManaged)!
      let bufferGridPositions: MTLBuffer = device.makeBuffer(bytes: gridPos, length: gridPos.count * MemoryLayout<SIMD4<Float>>.stride, options: .storageModeManaged)!
      let bufferParameters: MTLBuffer = device.makeBuffer(bytes: parameters, length: parameters.count * MemoryLayout<SIMD2<Float>>.stride, options: .storageModeManaged)!
      let bufferCell: MTLBuffer = device.makeBuffer(bytes: &cell3x3Float, length: MemoryLayout<float3x3>.stride, options: .storageModeManaged)!
      
      let bufferReplicas: MTLBuffer = device.makeBuffer(bytes: &replicasBufferValue, length: totalNumberOfReplicas * MemoryLayout<SIMD4<Float>>.stride, options: .storageModeManaged)!
      let bufferNumberOfReplicas: MTLBuffer = device.makeBuffer(bytes: &NumberOfReplicasBufferValue, length: MemoryLayout<Int32>.stride, options: .storageModeManaged)!
      let bufferOutput: MTLBuffer = device.makeBuffer(bytes: output, length: output.count * MemoryLayout<Float>.stride, options: .storageModeShared)!
      
      
      // Split large work into smaller work-batches of size 'sizeOfWorkBatch'
      // The watchdog kills kernels that are running too long (and without error on High Sierra)
      
      var unitsOfWorkDone: Int = 0
      let sizeOfWorkBatch: Int = 8192
      while(unitsOfWorkDone < totalNumberOfAtoms)
      {
        var numberOfAtomsPerThreadgroup: Int = min(sizeOfWorkBatch,totalNumberOfAtoms-unitsOfWorkDone)
        
        if let commandBuffer = commandQueue.makeCommandBuffer(),
           let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        {
          commandEncoder.setComputePipelineState(pipelineState)
        
          commandEncoder.setBytes(&numberOfAtomsPerThreadgroup, length: MemoryLayout<Int32>.stride, index: 0)
          commandEncoder.setBuffer(bufferAtomPositions, offset: unitsOfWorkDone * MemoryLayout<SIMD4<Float>>.stride, index: 1)
          commandEncoder.setBuffer(bufferGridPositions, offset: 0, index: 2)
          commandEncoder.setBuffer(bufferParameters, offset: unitsOfWorkDone * MemoryLayout<SIMD2<Float>>.stride, index: 3)
          commandEncoder.setBuffer(bufferCell, offset: 0, index: 4)
          commandEncoder.setBuffer(bufferNumberOfReplicas, offset: 0, index: 5)
          commandEncoder.setBuffer(bufferReplicas, offset: 0, index: 6)
          commandEncoder.setBuffer(bufferOutput, offset: 0, index: 7)
        
          commandEncoder.dispatchThreadgroups(MTLSize(width: NumberOfGridPoints/threadGroupCount, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: threadGroupCount, height: 1, depth: 1))
        
          commandEncoder.endEncoding()
        
          commandBuffer.commit()
        
          commandBuffer.waitUntilCompleted()
        
          unitsOfWorkDone += sizeOfWorkBatch
        
          if let error = commandBuffer.error
          {
            LogQueue.shared.error(destination: nil, message: "Metal error in ComputeEnergyGrid: " + error.localizedDescription)
            return []
          }
        }
        else
        {
          LogQueue.shared.error(destination: nil, message: "Metal error in ComputeEnergyGrid: Could not create command-buffers and -encoders.")
          return []
        }
      }
      
      var outputData: [Float] = [Float](repeating: 0.0, count: sizeX * sizeY * sizeZ)
      memcpy(&outputData, bufferOutput.contents(), outputData.count * MemoryLayout<Float>.stride)
      
      return outputData
    }
    return []
  }
  
  public static func computeVoidFractions(device: MTLDevice, commandQueue: MTLCommandQueue, structures: [SKRenderAdsorptionSurfaceStructure]) -> [Double]
  {
    var voidFractions: [Double] = []
    for structure in structures
    {
      var data: [Float] = []
      
      let cell: SKCell = structure.cell
      let positions: [SIMD3<Double>] = structure.atomUnitCellPositions
      let potentialParameters: [SIMD2<Double>] = structure.potentialParameters
      let probeParameters: SIMD2<Double> = SIMD2<Double>(10.9, 2.64)
      
      let numberOfReplicas: SIMD3<Int32> = cell.numberOfReplicas(forCutoff: 12.0)
      let framework: SKMetalFramework = SKMetalFramework(device: device, commandQueue: commandQueue, positions: positions, potentialParameters: potentialParameters, unitCell: cell.unitCell, numberOfReplicas: numberOfReplicas)
      
      data = framework.ComputeEnergyGrid(128, sizeY: 128, sizeZ: 128, probeParameter: probeParameters)
      
      var numberOfLowEnergyValues: Double = 0.0
      for value in data
      {
        numberOfLowEnergyValues += exp(-(1.0/298.0) * Double(value))  // K_B  chosen as 1.0 (energy units are Kelvin)
      }
      
      let voidFraction = Double(numberOfLowEnergyValues)/Double(128*128*128)
      voidFractions.append(voidFraction)
    }
    return voidFractions
  }
  
  public static func computeNitrogenSurfaceArea(device: MTLDevice, commandQueue: MTLCommandQueue, structures: [SKRenderAdsorptionSurfaceStructure]) -> ([Double], [Double])
  {
    var surfaceAreas: (gravimetric: [Double], volumetric: [Double]) = ([],[])
    
    for structure in structures
    {
      var data: [Float] = []
      
      let cell: SKCell = structure.cell
      let positions: [SIMD3<Double>] = structure.atomUnitCellPositions
      let potentialParameters: [SIMD2<Double>] = structure.potentialParameters
      let probeParameters: SIMD2<Double> = SIMD2<Double>(36.0,3.31)
      
      let numberOfReplicas: SIMD3<Int32> = cell.numberOfReplicas(forCutoff: 12.0)
      let framework: SKMetalFramework = SKMetalFramework(device: device, commandQueue: commandQueue, positions: positions, potentialParameters: potentialParameters, unitCell: cell.unitCell, numberOfReplicas: numberOfReplicas)
      
      data = framework.ComputeEnergyGrid(128, sizeY: 128, sizeZ: 128, probeParameter: probeParameters)
      
      let marchingCubes = SKMetalMarchingCubes128(device: device, commandQueue: commandQueue)
      marchingCubes.isoValue = Float(0.0)   // modified from: -probeParameters.x (which cause artifacts)
      
      var surfaceVertexBuffer: MTLBuffer? = nil
      var numberOfTriangles: Int  = 0
      
      do
      {
        try marchingCubes.prepareHistoPyramids(data, isosurfaceVertexBuffer: &surfaceVertexBuffer, numberOfTriangles: &numberOfTriangles)
      } catch {
         LogQueue.shared.error(destination: nil, message: error.localizedDescription)
      }
      
      if numberOfTriangles > 0,
        let ptr: UnsafeMutableRawPointer = surfaceVertexBuffer?.contents()
      {
        let float4Ptr = ptr.bindMemory(to: SIMD4<Float>.self, capacity: Int(numberOfTriangles) * 3 * 3 )
        
        var totalArea: Double = 0.0
        for i in stride(from: 0, through: (Int(numberOfTriangles) * 3 * 3 - 1), by: 9)
        {
          let unitCell: double3x3 = cell.unitCell
          let v1 = unitCell * SIMD3<Double>(Double(float4Ptr[i].x),Double(float4Ptr[i].y),Double(float4Ptr[i].z))
          let v2 = unitCell * SIMD3<Double>(Double(float4Ptr[i+3].x),Double(float4Ptr[i+3].y),Double(float4Ptr[i+3].z))
          let v3 = unitCell * SIMD3<Double>(Double(float4Ptr[i+6].x),Double(float4Ptr[i+6].y),Double(float4Ptr[i+6].z))
          
          let v4: SIMD3<Double> = cross((v2-v1), (v3-v1))
          let area: Double = 0.5 * simd.length(v4)
          if area.isFinite && fabs(area) < 1.0
          {
            totalArea += area
          }
        }
        
        surfaceAreas.gravimetric.append(totalArea * SKConstants.AvogadroConstantPerAngstromSquared / structure.structureMass)
        surfaceAreas.volumetric.append(totalArea * 1e4 / structure.cell.volume)
      }
      else
      {
        surfaceAreas.gravimetric.append(0.0)
        surfaceAreas.volumetric.append(0.0)
      }
    }
    return surfaceAreas
  }
}


// https://github.com/jtbandes/Metalbrot.playground/blob/master/Metalbrot.playground/Sources/Helpers.swift

extension MTLSize
{
  var hasZeroDimension: Bool {
    return depth == 0 || width == 0 || height == 0
  }
}

/// Encapsulates the sizes to be passed to `MTLComputeCommandEncoder.dispatchThreadgroups(_:threadsPerThreadgroup:)`.
public struct ThreadgroupSizes
{
  var threadsPerThreadgroup: MTLSize
  var threadgroupsPerGrid: MTLSize
  
  public static let zeros = ThreadgroupSizes(
    threadsPerThreadgroup: MTLSize(),
    threadgroupsPerGrid: MTLSize())
  
  var hasZeroDimension: Bool {
    return threadsPerThreadgroup.hasZeroDimension || threadgroupsPerGrid.hasZeroDimension
  }
}

public extension MTLComputePipelineState
{
  /// Selects "reasonable" values for threadsPerThreadgroup and threadgroupsPerGrid for the given `drawableSize`.
  /// - Remark: The heuristics used here are not perfect. There are many ways to underutilize the GPU,
  /// including selecting suboptimal threadgroup sizes, or branching in the shader code.
  ///
  /// If you are certain you can always use threadgroups with a multiple of `threadExecutionWidth`
  /// threads, then you may want to use MTLComputePipleineDescriptor and its property
  /// `threadGroupSizeIsMultipleOfThreadExecutionWidth` to configure your pipeline state.
  ///
  /// If your shader is doing some more interesting calculations, and your threads need to share memory in some
  /// meaningful way, then you’ll probably want to do something less generalized to choose your threadgroups.
  func threadgroupSizesForDrawableSize(_ drawableSize: CGSize) -> ThreadgroupSizes
  {
    let waveSize = self.threadExecutionWidth
    let maxThreadsPerGroup = self.maxTotalThreadsPerThreadgroup
    
    let drawableWidth = Int(drawableSize.width)
    let drawableHeight = Int(drawableSize.height)
    
    if drawableWidth == 0 || drawableHeight == 0 {
      print("drawableSize is zero")
      return .zeros
    }
    
    // Determine the set of possible sizes (not exceeding maxThreadsPerGroup).
    var candidates: [ThreadgroupSizes] = []
    for groupWidth in 1...maxThreadsPerGroup {
      for groupHeight in 1...(maxThreadsPerGroup/groupWidth) {
        // Round up the number of groups to ensure the entire drawable size is covered.
        // <http://stackoverflow.com/a/2745086/23649>
        let groupsPerGrid = MTLSize(width: (drawableWidth + groupWidth - 1) / groupWidth,
                                    height: (drawableHeight + groupHeight - 1) / groupHeight,
                                    depth: 1)
        
        candidates.append(ThreadgroupSizes(
          threadsPerThreadgroup: MTLSize(width: groupWidth, height: groupHeight, depth: 1),
          threadgroupsPerGrid: groupsPerGrid))
      }
    }
    
    /// Make a rough approximation for how much compute power will be "wasted" (e.g. when the total number
    /// of threads in a group isn’t an even multiple of `threadExecutionWidth`, or when the total number of
    /// threads being dispatched exceeds the drawable size). Smaller is better.
    func _estimatedUnderutilization(_ s: ThreadgroupSizes) -> Int {
      let excessWidth = s.threadsPerThreadgroup.width * s.threadgroupsPerGrid.width - drawableWidth
      let excessHeight = s.threadsPerThreadgroup.height * s.threadgroupsPerGrid.height - drawableHeight
      
      let totalThreadsPerGroup = s.threadsPerThreadgroup.width * s.threadsPerThreadgroup.height
      let totalGroups = s.threadgroupsPerGrid.width * s.threadgroupsPerGrid.height
      
      let excessArea = excessWidth * drawableHeight + excessHeight * drawableWidth + excessWidth * excessHeight
      let excessThreadsPerGroup = (waveSize - totalThreadsPerGroup % waveSize) % waveSize
      
      return excessArea + excessThreadsPerGroup * totalGroups
    }
    
    // Choose the threadgroup sizes which waste the least amount of execution time/power.
    let result = candidates.min { _estimatedUnderutilization($0) < _estimatedUnderutilization($1) }
    return result ?? .zeros
  }
  
  
}
