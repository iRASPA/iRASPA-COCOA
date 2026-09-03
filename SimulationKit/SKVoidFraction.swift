//
//  SKVoidFraction.swift
//  SimulationKit
//
//  Created by David Dubbeldam on 15/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation
import SymmetryKit
import simd

public class SKVoidFraction
{
  // Helium in the UFF, as epsilon in kelvin and sigma in angstrom. The void fraction is by definition the one
  // helium measures, whatever probe the other framework properties are set to use.
  public static let heliumProbeParameters: SIMD2<Double> = SIMD2<Double>(10.9, 2.64)

  private static let gridSize: Int = 128

  // The Boltzmann-averaged fraction of the unit cell a helium atom can occupy at room temperature, and the
  // deepest energy on the grid.
  //
  // A grid point inside an applied blocking pocket is left out of the average: the pocket is pore the probe is
  // not allowed into, so it is not void, however deep the well it hides. It stays in the denominator, so what
  // comes out is the fraction of the whole cell that is accessible void. Which points those are has to be asked
  // for separately rather than read off the masked grid, because the mask the kernel writes is a depth ramp
  // meant for level sets (see SKMetalFramework.blockedGridPoints).
  public static func compute(structures: [SKFrameworkSnapshot]) -> [(minimumEnergyValue: Double, voidFraction: Double)]
  {
    var results: [(minimumEnergyValue: Double, voidFraction: Double)] = []
    guard let device = MTLCreateSystemDefaultDevice(),
          let commandQueue: MTLCommandQueue = device.makeCommandQueue() else {return structures.map{_ in (0.0, 0.0)}}

    let numberOfGridPoints: Int = gridSize * gridSize * gridSize

    for structure in structures
    {
      let numberOfReplicas: SIMD3<Int32> = structure.cell.numberOfReplicas(forCutoff: 12.0)
      let framework: SKMetalFramework = SKMetalFramework(device: device, commandQueue: commandQueue, positions: structure.positions, potentialParameters: structure.potentialParameters, unitCell: structure.cell.unitCell, numberOfReplicas: numberOfReplicas, blockingPockets: structure.blockingPockets)

      // With the pockets applied so that the deepest energy reported is one of an accessible well, like the
      // grid the inspector draws.
      let data: [Float] = framework.ComputeEnergyGrid(gridSize, sizeY: gridSize, sizeZ: gridSize, probeParameter: heliumProbeParameters)
      guard data.count >= numberOfGridPoints else
      {
        results.append((0.0, 0.0))
        continue
      }
      let blocked: [Bool] = framework.blockedGridPoints(gridSize, sizeY: gridSize, sizeZ: gridSize)

      var minimumEnergy: Float = Float.greatestFiniteMagnitude
      var numberOfLowEnergyValues: Double = 0.0
      for i in 0..<numberOfGridPoints where !blocked[i]
      {
        minimumEnergy = min(minimumEnergy, data[i])
        numberOfLowEnergyValues += exp(-(1.0/298.0) * Double(data[i]))  // K_B  chosen as 1.0 (energy units are Kelvin)
      }

      results.append((Double(minimumEnergy == Float.greatestFiniteMagnitude ? 0.0 : minimumEnergy), numberOfLowEnergyValues/Double(numberOfGridPoints)))
    }
    return results
  }
}
