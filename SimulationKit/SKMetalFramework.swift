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
  
  // Spheres the probe is not allowed into, as a fractional position of the unit cell with a radius in
  // angstrom. They are read from a RASPA '.block' file and only reach the grid when the structure asks for
  // them to be applied; an empty list leaves the grid exactly as it was.
  var blockingPockets: [SIMD4<Double>] = []
  
  var pipelineState: MTLComputePipelineState? = nil
  var device: MTLDevice
  var commandQueue: MTLCommandQueue
  var defaultLibrary: MTLLibrary
  
  init(device: MTLDevice, commandQueue: MTLCommandQueue)
  {
    self.device = device
    self.commandQueue = commandQueue
    
    let bundle: Bundle = Bundle(for: SKMetalFramework.self)
    defaultLibrary = RKMetal.loadDefaultLibrary(device: device, bundle: bundle)
  }
  
  public convenience init(device: MTLDevice, commandQueue: MTLCommandQueue, positions: [SIMD3<Double>], potentialParameters: [SIMD2<Double>], unitCell: double3x3, numberOfReplicas: SIMD3<Int32>, blockingPockets: [SIMD4<Double>] = [])
  {
    self.init(device: device, commandQueue: commandQueue)
    self.blockingPockets = blockingPockets
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
  
  // The blocking pockets as the kernels read them. Metal has no zero-length buffer, so a structure without
  // pockets is still given one element; the count bound alongside it keeps the kernels out of the array.
  private func makeBlockingPocketBuffer() -> MTLBuffer?
  {
    var pockets: [SIMD4<Float>] = blockingPockets.map{SIMD4<Float>(Float($0.x), Float($0.y), Float($0.z), Float($0.w))}
    if pockets.isEmpty
    {
      pockets = [SIMD4<Float>(0.0, 0.0, 0.0, 0.0)]
    }
    return device.makeBuffer(bytes: pockets, length: pockets.count * MemoryLayout<SIMD4<Float>>.stride, options: RKMetal.hostStorage)
  }
  
  // Which points of a grid of this size lie inside a blocking pocket, in the order ComputeEnergyGrid returns
  // its energies.
  //
  // The kernel gives a blocked point an energy that rises with the depth it lies at rather than one flat
  // overlap value, because that is what lets a level set follow the sphere (see blockedEnergyPerAngstrom in
  // ComputeEnergyGrid.metal). An average over the grid cannot read exclusion out of such a value --- a point
  // just inside the rim is worth almost as much as open pore --- so a caller averaging over the grid asks here
  // which points to leave out instead. Mirrors blockingPocketDistance in the kernel.
  public func blockedGridPoints(_ sizeX: Int, sizeY: Int, sizeZ: Int) -> [Bool]
  {
    var blocked: [Bool] = [Bool](repeating: false, count: sizeX * sizeY * sizeZ)
    guard !blockingPockets.isEmpty else {return blocked}
    
    for k in 0..<sizeZ
    {
      for j in 0..<sizeY
      {
        for i in 0..<sizeX
        {
          // The grid spans the unit cell, whatever the replica cell the atoms are wrapped over, and a pocket
          // is a feature of the framework, so the nearest image is taken in unit-cell coordinates.
          let position: SIMD3<Double> = SIMD3<Double>(Double(i)/Double(sizeX), Double(j)/Double(sizeY), Double(k)/Double(sizeZ))
          for pocket in blockingPockets
          {
            var dr: SIMD3<Double> = position - SIMD3<Double>(pocket.x, pocket.y, pocket.z)
            dr -= dr.rounded(.toNearestOrEven)
            if simd.length(unitCell * dr) < pocket.w
            {
              blocked[i + sizeX * (j + sizeY * k)] = true
              break
            }
          }
        }
      }
    }
    return blocked
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
      
      guard (totalNumberOfAtoms > 0) else { return [] }
      
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
        
      var loopindex: Int = 0
      for k in 0..<sizeZ
      {
        for j in 0..<sizeY
        {
          // X various the fastest (contiguous in x)
          for i in 0..<sizeX
          {
            // Spacing 1/size and not 1/(size-1). The field is periodic with the cell, so sampling it at both
            // endpoints spends the last plane on a duplicate of the first and leaves the real spacing coarser
            // than the grid claims. Everything downstream reads the grid the other way --- marching cubes places
            // a node at index/dimensions and wraps index+1 past the end round to 0, and the volume renderer
            // samples the texture over the whole cell --- so with both endpoints stored the last layer of voxels
            // interpolates between two copies of the same plane and comes out flat, with no gradient across it.
            // That is a one-voxel shell of dead field wrapped round the cell boundary.
            let position: SIMD3<Double> = correction * SIMD3<Double>(Double(i)/Double(sizeX),Double(j)/Double(sizeY),Double(k)/Double(sizeZ))
            gridPos[loopindex] = SIMD4<Float>(Float(position.x), Float(position.y), Float(position.z), Float(0.0))
            loopindex += 1
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
      let bufferAtomPositions: MTLBuffer = device.makeBuffer(bytes: pos, length: pos.count * MemoryLayout<SIMD4<Float>>.stride, options: RKMetal.hostStorage)!
      let bufferGridPositions: MTLBuffer = device.makeBuffer(bytes: gridPos, length: gridPos.count * MemoryLayout<SIMD4<Float>>.stride, options: RKMetal.hostStorage)!
      let bufferParameters: MTLBuffer = device.makeBuffer(bytes: parameters, length: parameters.count * MemoryLayout<SIMD2<Float>>.stride, options: RKMetal.hostStorage)!
      let bufferCell: MTLBuffer = device.makeBuffer(bytes: &cell3x3Float, length: MemoryLayout<float3x3>.stride, options: RKMetal.hostStorage)!
      
      let bufferReplicas: MTLBuffer = device.makeBuffer(bytes: &replicasBufferValue, length: totalNumberOfReplicas * MemoryLayout<SIMD4<Float>>.stride, options: RKMetal.hostStorage)!
      let bufferNumberOfReplicas: MTLBuffer = device.makeBuffer(bytes: &NumberOfReplicasBufferValue, length: MemoryLayout<Int32>.stride, options: RKMetal.hostStorage)!
      let bufferOutput: MTLBuffer = device.makeBuffer(bytes: output, length: output.count * MemoryLayout<Float>.stride, options: .storageModeShared)!
      guard let bufferBlockingPockets: MTLBuffer = makeBlockingPocketBuffer() else
      {
        LogQueue.shared.error(destination: nil, message: "Metal error in ComputeEnergyGrid: could not create the blocking-pocket buffer.")
        return []
      }
      var numberOfBlockingPocketsValue: Int32 = Int32(blockingPockets.count)
      var replicaCorrection: SIMD3<Float> = SIMD3<Float>(Float(correction.x), Float(correction.y), Float(correction.z))
      
      
      // Split large work into smaller work-batches of size 'sizeOfWorkBatch'
      // The watchdog kills kernels that are running too long (and without error on High Sierra)
      
      var unitsOfWorkDone: Int = 0
      let sizeOfWorkBatch: Int = 8192
      while(unitsOfWorkDone < totalNumberOfAtoms)
      {
        var numberOfAtomsPerThreadgroup: Int32 = Int32(min(sizeOfWorkBatch,totalNumberOfAtoms-unitsOfWorkDone))
        
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
          commandEncoder.setBytes(&numberOfBlockingPocketsValue, length: MemoryLayout<Int32>.stride, index: 8)
          commandEncoder.setBuffer(bufferBlockingPockets, offset: 0, index: 9)
          commandEncoder.setBytes(&replicaCorrection, length: MemoryLayout<SIMD3<Float>>.stride, index: 10)
        
          // Prefer dispatchThreadgroups: dispatchThreads requires non-uniform
          // threadgroup sizes, which the iOS Simulator (and some devices) lack.
          let threadExecutionWidth: Int = pipelineState.threadExecutionWidth
          let threadsPerThreadgroup = MTLSizeMake(threadExecutionWidth, 1, 1)
          let threadgroupsPerGrid = MTLSize(width: NumberOfGridPoints / threadExecutionWidth, height: 1, depth: 1)
          commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
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
      
      let outputPointer = bufferOutput.contents().bindMemory(to: Float.self, capacity: sizeX * sizeY * sizeZ)
      return Array(UnsafeBufferPointer(start: outputPointer, count: sizeX * sizeY * sizeZ))
    }
    return []
  }
  
  // The well-surface field: three floats per grid point, the energy U, the additively weighted (Apollonius)
  // distance d = min over atoms of (|x - a| - 2^(1/6) sigma), and the medial reliability rel --- the length
  // of the softmin-weighted average of the unit vectors toward the atoms (1 against one wall, 0 on the
  // medial axis of a channel where opposing walls cancel). The zero level set of d is the probe-contact
  // offset surface the well surface is extracted from; U supplies the depth trim and the refinement target;
  // rel marks where the channel is too narrow for a sheet and the well collapses to a 1D filament
  // (see SKMetalWellSurface).
  public func ComputeWellFieldGrid(_ sizeX: Int, sizeY: Int, sizeZ: Int, probeParameter: SIMD2<Double>) -> [Float]
  {
    guard let accumulateFunction: MTLFunction = defaultLibrary.makeFunction(name: "ComputeWellFieldGrid"),
          let accumulatePipeline: MTLComputePipelineState = try? device.makeComputePipelineState(function: accumulateFunction) else {
      LogQueue.shared.error(destination: nil, message: "Well-field Metal kernels were not found in SimulationKit.default.metallib")
      return []
    }
    
    guard (totalNumberOfAtoms > 0) else { return [] }
    
    let threadGroupCount: Int = accumulatePipeline.threadExecutionWidth
    let temp: Int = sizeX*sizeY*sizeZ
    let NumberOfGridPoints: Int = temp + (threadGroupCount - (temp & (threadGroupCount-1)))
    
    var pos: [SIMD4<Float>] = [SIMD4<Float>](repeating: SIMD4<Float>(0,0,0,0), count: totalNumberOfAtoms)
    var parameters: [SIMD2<Float>] = [SIMD2<Float>](repeating: SIMD2<Float>(0,0), count: totalNumberOfAtoms)
    var gridPos: [SIMD4<Float>] = [SIMD4<Float>](repeating: SIMD4<Float>(0,0,0,0), count: NumberOfGridPoints)
    
    let correction: SIMD3<Double> = SIMD3<Double>(1.0/Double(numberOfReplicas.x), 1.0/Double(numberOfReplicas.y), 1.0/Double(numberOfReplicas.z))
    
    for i in 0..<totalNumberOfAtoms
    {
      let position: SIMD3<Double> = positions[i] * correction
      let currentPotentialParameters: SIMD2<Double> = self.potentialParameters[i]
      pos[i] = SIMD4<Float>(Float(position.x), Float(position.y), Float(position.z), 0.0)
      // 4 x epsilon, Lorentz-Berthelot mixed with the probe, exactly as ComputeEnergyGrid
      parameters[i] = SIMD2<Float>(Float(4.0*sqrt(currentPotentialParameters.x * probeParameter.x)),
                                   Float(0.5 * (currentPotentialParameters.y + probeParameter.y)))
    }
    
    var loopindex: Int = 0
    for k in 0..<sizeZ
    {
      for j in 0..<sizeY
      {
        for i in 0..<sizeX
        {
          // spacing 1/size, the same periodic convention as ComputeEnergyGrid
          let position: SIMD3<Double> = correction * SIMD3<Double>(Double(i)/Double(sizeX),Double(j)/Double(sizeY),Double(k)/Double(sizeZ))
          gridPos[loopindex] = SIMD4<Float>(Float(position.x), Float(position.y), Float(position.z), Float(0.0))
          loopindex += 1
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
    
    guard let bufferAtomPositions: MTLBuffer = device.makeBuffer(bytes: pos, length: pos.count * MemoryLayout<SIMD4<Float>>.stride, options: RKMetal.hostStorage),
          let bufferGridPositions: MTLBuffer = device.makeBuffer(bytes: gridPos, length: gridPos.count * MemoryLayout<SIMD4<Float>>.stride, options: RKMetal.hostStorage),
          let bufferParameters: MTLBuffer = device.makeBuffer(bytes: parameters, length: parameters.count * MemoryLayout<SIMD2<Float>>.stride, options: RKMetal.hostStorage),
          let bufferCell: MTLBuffer = device.makeBuffer(bytes: &cell3x3Float, length: MemoryLayout<float3x3>.stride, options: RKMetal.hostStorage),
          let bufferReplicas: MTLBuffer = device.makeBuffer(bytes: &replicasBufferValue, length: totalNumberOfReplicas * MemoryLayout<SIMD4<Float>>.stride, options: RKMetal.hostStorage),
          let bufferNumberOfReplicas: MTLBuffer = device.makeBuffer(bytes: &NumberOfReplicasBufferValue, length: MemoryLayout<Int32>.stride, options: RKMetal.hostStorage),
          let bufferAccumulated: MTLBuffer = device.makeBuffer(length: NumberOfGridPoints * MemoryLayout<SIMD2<Float>>.stride, options: .storageModeShared),
          let bufferSoftmin: MTLBuffer = device.makeBuffer(length: NumberOfGridPoints * MemoryLayout<SIMD4<Float>>.stride, options: .storageModeShared),
          let bufferBlockingPockets: MTLBuffer = makeBlockingPocketBuffer() else {
      LogQueue.shared.error(destination: nil, message: "Metal error in ComputeWellFieldGrid: could not create buffers.")
      return []
    }
    var numberOfBlockingPocketsValue: Int32 = Int32(blockingPockets.count)
    var replicaCorrection: SIMD3<Float> = SIMD3<Float>(Float(correction.x), Float(correction.y), Float(correction.z))
    // energy accumulates from zero, distance accumulates through min() from +large, softmin sums from zero
    let accumulatedPointer = bufferAccumulated.contents().bindMemory(to: SIMD2<Float>.self, capacity: NumberOfGridPoints)
    for i in 0..<NumberOfGridPoints
    {
      accumulatedPointer[i] = SIMD2<Float>(0.0, 1.0e10)
    }
    memset(bufferSoftmin.contents(), 0, NumberOfGridPoints * MemoryLayout<SIMD4<Float>>.stride)
    
    // batched over atoms so no single kernel outlives the GPU watchdog, as in ComputeEnergyGrid
    var unitsOfWorkDone: Int = 0
    let sizeOfWorkBatch: Int = 8192
    while(unitsOfWorkDone < totalNumberOfAtoms)
    {
      var numberOfAtomsPerThreadgroup: Int32 = Int32(min(sizeOfWorkBatch,totalNumberOfAtoms-unitsOfWorkDone))
      
      guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
        LogQueue.shared.error(destination: nil, message: "Metal error in ComputeWellFieldGrid: could not create command-buffers and -encoders.")
        return []
      }
      commandEncoder.setComputePipelineState(accumulatePipeline)
      commandEncoder.setBytes(&numberOfAtomsPerThreadgroup, length: MemoryLayout<Int32>.stride, index: 0)
      commandEncoder.setBuffer(bufferAtomPositions, offset: unitsOfWorkDone * MemoryLayout<SIMD4<Float>>.stride, index: 1)
      commandEncoder.setBuffer(bufferGridPositions, offset: 0, index: 2)
      commandEncoder.setBuffer(bufferParameters, offset: unitsOfWorkDone * MemoryLayout<SIMD2<Float>>.stride, index: 3)
      commandEncoder.setBuffer(bufferCell, offset: 0, index: 4)
      commandEncoder.setBuffer(bufferNumberOfReplicas, offset: 0, index: 5)
      commandEncoder.setBuffer(bufferReplicas, offset: 0, index: 6)
      commandEncoder.setBuffer(bufferAccumulated, offset: 0, index: 7)
      commandEncoder.setBuffer(bufferSoftmin, offset: 0, index: 8)
      commandEncoder.setBytes(&numberOfBlockingPocketsValue, length: MemoryLayout<Int32>.stride, index: 9)
      commandEncoder.setBuffer(bufferBlockingPockets, offset: 0, index: 10)
      commandEncoder.setBytes(&replicaCorrection, length: MemoryLayout<SIMD3<Float>>.stride, index: 11)
      
      let threadsPerThreadgroup = MTLSizeMake(threadGroupCount, 1, 1)
      let threadgroupsPerGrid = MTLSize(width: NumberOfGridPoints / threadGroupCount, height: 1, depth: 1)
      commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
      commandEncoder.endEncoding()
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()
      
      if let error = commandBuffer.error
      {
        LogQueue.shared.error(destination: nil, message: "Metal error in ComputeWellFieldGrid: " + error.localizedDescription)
        return []
      }
      unitsOfWorkDone += sizeOfWorkBatch
    }
    
    // collapse to three floats per grid point: (U, d, rel)
    let accumulated = bufferAccumulated.contents().bindMemory(to: SIMD2<Float>.self, capacity: temp)
    let softmin = bufferSoftmin.contents().bindMemory(to: SIMD4<Float>.self, capacity: temp)
    var output: [Float] = [Float](repeating: 0.0, count: 3 * temp)
    for i in 0..<temp
    {
      output[3 * i] = accumulated[i].x
      output[3 * i + 1] = accumulated[i].y
      let s = softmin[i]
      output[3 * i + 2] = s.w > 0.0 ? simd_length(SIMD3<Float>(s.x, s.y, s.z)) / s.w : 1.0
    }
    return output
  }
  
  // Refines a well-surface vertex buffer in place: every vertex is slid along the ray toward its nearest
  // atom onto the 1D minimum of the exact analytic energy --- the true multi-atom well floor (see
  // RefineWellSurfaceVertices in ComputeEnergyGrid.metal). Marching cubes supplies the topology on the
  // probe-contact distance surface; this pass supplies the energy-accurate geometry. Vertices on the trim
  // caps (energies at the iso level) belong to the isosurface and are left alone.
  public func RefineWellSurfaceVertexBuffer(vertexBuffer: MTLBuffer, probeParameter: SIMD2<Double>, isovalue: Float)
  {
    guard let refineFunction: MTLFunction = defaultLibrary.makeFunction(name: "RefineWellSurfaceVertices"),
          let refinePipeline: MTLComputePipelineState = try? device.makeComputePipelineState(function: refineFunction) else {
      LogQueue.shared.error(destination: nil, message: "RefineWellSurfaceVertices was not found in SimulationKit.default.metallib")
      return
    }

    let numberOfVertices: Int = vertexBuffer.length / (3 * MemoryLayout<SIMD4<Float>>.stride)
    guard totalNumberOfAtoms > 0, numberOfVertices > 0 else { return }

    let correction: SIMD3<Double> = SIMD3<Double>(1.0/Double(numberOfReplicas.x), 1.0/Double(numberOfReplicas.y), 1.0/Double(numberOfReplicas.z))

    var pos: [SIMD4<Float>] = [SIMD4<Float>](repeating: SIMD4<Float>(0,0,0,0), count: totalNumberOfAtoms)
    var parameters: [SIMD2<Float>] = [SIMD2<Float>](repeating: SIMD2<Float>(0,0), count: totalNumberOfAtoms)
    for i in 0..<totalNumberOfAtoms
    {
      let position: SIMD3<Double> = positions[i] * correction
      let currentPotentialParameters: SIMD2<Double> = self.potentialParameters[i]
      pos[i] = SIMD4<Float>(Float(position.x), Float(position.y), Float(position.z), 0.0)
      // 4 x epsilon, Lorentz-Berthelot mixed with the probe, exactly as the field kernels
      parameters[i] = SIMD2<Float>(Float(4.0*sqrt(currentPotentialParameters.x * probeParameter.x)),
                                   Float(0.5 * (currentPotentialParameters.y + probeParameter.y)))
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

    var numberOfAtomsValue: Int32 = Int32(totalNumberOfAtoms)
    var numberOfReplicasValue: Int32 = Int32(totalNumberOfReplicas)
    var cell3x3Float: float3x3 = float3x3(Double3x3: replicaCell)
    var inverseCell3x3Float: float3x3 = float3x3(Double3x3: replicaCell.inverse)
    var replicaCorrection: SIMD3<Float> = SIMD3<Float>(Float(correction.x), Float(correction.y), Float(correction.z))
    var isovalueValue: Float = isovalue

    guard let bufferAtomPositions: MTLBuffer = device.makeBuffer(bytes: pos, length: pos.count * MemoryLayout<SIMD4<Float>>.stride, options: RKMetal.hostStorage),
          let bufferParameters: MTLBuffer = device.makeBuffer(bytes: parameters, length: parameters.count * MemoryLayout<SIMD2<Float>>.stride, options: RKMetal.hostStorage),
          let bufferReplicas: MTLBuffer = device.makeBuffer(bytes: &replicasBufferValue, length: totalNumberOfReplicas * MemoryLayout<SIMD4<Float>>.stride, options: RKMetal.hostStorage),
          let bufferBlockingPockets: MTLBuffer = makeBlockingPocketBuffer() else {
      LogQueue.shared.error(destination: nil, message: "Metal error in RefineWellSurfaceVertexBuffer: could not create buffers.")
      return
    }
    var numberOfBlockingPocketsValue: Int32 = Int32(blockingPockets.count)

    // batched over vertices so no single kernel outlives the GPU watchdog
    let sizeOfWorkBatch: Int = 1 << 20
    var verticesDone: Int = 0
    while verticesDone < numberOfVertices
    {
      var verticesInBatch: UInt32 = UInt32(min(sizeOfWorkBatch, numberOfVertices - verticesDone))

      guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
        LogQueue.shared.error(destination: nil, message: "Metal error in RefineWellSurfaceVertexBuffer: could not create command-buffers and -encoders.")
        return
      }
      commandEncoder.setComputePipelineState(refinePipeline)
      commandEncoder.setBytes(&numberOfAtomsValue, length: MemoryLayout<Int32>.stride, index: 0)
      commandEncoder.setBuffer(bufferAtomPositions, offset: 0, index: 1)
      commandEncoder.setBuffer(bufferParameters, offset: 0, index: 2)
      commandEncoder.setBytes(&cell3x3Float, length: MemoryLayout<float3x3>.stride, index: 3)
      commandEncoder.setBytes(&inverseCell3x3Float, length: MemoryLayout<float3x3>.stride, index: 4)
      commandEncoder.setBytes(&numberOfReplicasValue, length: MemoryLayout<Int32>.stride, index: 5)
      commandEncoder.setBuffer(bufferReplicas, offset: 0, index: 6)
      commandEncoder.setBytes(&replicaCorrection, length: MemoryLayout<SIMD3<Float>>.stride, index: 7)
      commandEncoder.setBytes(&isovalueValue, length: MemoryLayout<Float>.stride, index: 8)
      commandEncoder.setBytes(&verticesInBatch, length: MemoryLayout<UInt32>.stride, index: 9)
      commandEncoder.setBuffer(vertexBuffer, offset: verticesDone * 3 * MemoryLayout<SIMD4<Float>>.stride, index: 10)
      commandEncoder.setBytes(&numberOfBlockingPocketsValue, length: MemoryLayout<Int32>.stride, index: 11)
      commandEncoder.setBuffer(bufferBlockingPockets, offset: 0, index: 12)

      let width: Int = max(refinePipeline.threadExecutionWidth, 1)
      commandEncoder.dispatchThreadgroups(MTLSize(width: (Int(verticesInBatch) + width - 1) / width, height: 1, depth: 1), threadsPerThreadgroup: MTLSizeMake(width, 1, 1))
      commandEncoder.endEncoding()
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()

      if let error = commandBuffer.error
      {
        LogQueue.shared.error(destination: nil, message: "Metal error in RefineWellSurfaceVertexBuffer: " + error.localizedDescription)
        return
      }
      verticesDone += Int(verticesInBatch)
    }
  }

}
