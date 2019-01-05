//
//  SKVoidFraction.swift
//  SimulationKit
//
//  Created by David Dubbeldam on 15/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation

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
}
