//
//  SKSurfaceArea.swift
//  SimulationKit
//
//  Created by David Dubbeldam on 15/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation
import SymmetryKit
import simd

public class SKNitrogenSurfaceArea
{
  public static func compute(structures: [SKRenderAdsorptionSurfaceStructure]) -> ([Double], [Double])
  {
    if let device = MTLCreateSystemDefaultDevice(),
      let commandQueue: MTLCommandQueue = device.makeCommandQueue()
    {
      return SKMetalFramework.computeNitrogenSurfaceArea(device: device, commandQueue: commandQueue, structures: structures)
    }
    return ([],[])
  }
  
  public static func compute(structures: [(cell: SKCell, positions: [SIMD3<Double>], potentialParameters: [SIMD2<Double>])], probeParameters: SIMD2<Double>) throws -> [Double] 
  {
    var results: [Double] = []
    if let device = MTLCreateSystemDefaultDevice(),
       let commandQueue: MTLCommandQueue = device.makeCommandQueue()
    {
      for structure in structures
      {
        var data: [Float] = []
        
        let numberOfReplicas: SIMD3<Int32> = structure.cell.numberOfReplicas(forCutoff: 12.0)
        let framework: SKMetalFramework = SKMetalFramework(device: device, commandQueue: commandQueue, positions: structure.positions, potentialParameters: structure.potentialParameters, unitCell: structure.cell.unitCell, numberOfReplicas: numberOfReplicas)
        
        data = framework.ComputeEnergyGrid(128, sizeY: 128, sizeZ: 128, probeParameter: probeParameters)
        
        let marchingCubes = SKMetalMarchingCubes128(device: device, commandQueue: commandQueue)
        marchingCubes.isoValue = Float(-probeParameters.x)
        
        var surfaceVertexBuffer: MTLBuffer? = nil
        var numberOfTriangles: Int  = 0
        
      
        try marchingCubes.prepareHistoPyramids(data, isosurfaceVertexBuffer: &surfaceVertexBuffer, numberOfTriangles: &numberOfTriangles)
      
        
        if numberOfTriangles > 0,
          let ptr: UnsafeMutableRawPointer = surfaceVertexBuffer?.contents()
        {
          let float4Ptr = ptr.bindMemory(to: SIMD4<Float>.self, capacity: Int(numberOfTriangles) * 3 * 3 )
          
          var totalArea: Double = 0.0
          for i in stride(from: 0, through: (Int(numberOfTriangles) * 3 * 3 - 1), by: 9)
          {
            let unitCell: double3x3 = structure.cell.unitCell
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
          results.append(totalArea)
        }
        else
        {
          results.append(0.0)
        }
      }
    }
    return results
  }
}
