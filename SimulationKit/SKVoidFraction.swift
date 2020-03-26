//
//  SKVoidFraction.swift
//  SimulationKit
//
//  Created by David Dubbeldam on 15/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation
import SymmetryKit

public class SKVoidFraction
{
  public static func compute(structures: [SKRenderAdsorptionSurfaceStructure]) -> [Double]
  {
    if let device = MTLCreateSystemDefaultDevice(),
      let commandQueue: MTLCommandQueue = device.makeCommandQueue()
    {
      return SKMetalFramework.computeVoidFractions(device: device, commandQueue: commandQueue, structures: structures)
    }
    fatalError()
  }
  
  public static func compute(structures: [(cell: SKCell, positions: [SIMD3<Double>], potentialParameters: [SIMD2<Double>])], probeParameters: SIMD2<Double>) -> [(minimumEnergyValue: Double, voidFraction: Double)]
  {
    var results: [(minimumEnergyValue: Double, voidFraction: Double)] = []
    if let device = MTLCreateSystemDefaultDevice(),
       let commandQueue: MTLCommandQueue = device.makeCommandQueue()
    {
      for structure in structures
      {
        var data: [Float] = []
        
        let numberOfReplicas: SIMD3<Int32> = structure.cell.numberOfReplicas(forCutoff: 12.0)
        let framework: SKMetalFramework = SKMetalFramework(device: device, commandQueue: commandQueue, positions: structure.positions, potentialParameters: structure.potentialParameters, unitCell: structure.cell.unitCell, numberOfReplicas: numberOfReplicas)
        
        data = framework.ComputeEnergyGrid(128, sizeY: 128, sizeZ: 128, probeParameter: probeParameters)
                
        var numberOfLowEnergyValues: Double = 0.0
        for value in data
        {
          numberOfLowEnergyValues += exp(-(1.0/298.0) * Double(value))  // K_B  chosen as 1.0 (energy units are Kelvin)
        }
        let result = (Double(data.min() ?? 0.0), Double(numberOfLowEnergyValues)/Double(128*128*128))
        results.append(result)
      }
    }
    return results
  }
  
}
