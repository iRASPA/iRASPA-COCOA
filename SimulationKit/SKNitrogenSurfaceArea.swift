//
//  SKSurfaceArea.swift
//  SimulationKit
//
//  Created by David Dubbeldam on 15/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation
import SymmetryKit
import LogViewKit
import simd

public struct SKSurfaceAreaResult
{
  // Of the unit cell, in square angstrom.
  public let area: Double

  // In square metre per gram.
  public let gravimetric: Double

  // In square metre per cubic centimetre.
  public let volumetric: Double

  init(area: Double, structure: SKFrameworkSnapshot)
  {
    self.area = area
    self.gravimetric = structure.mass > 0.0 ? area * SKConstant.AvogadroConstantPerAngstromSquared / structure.mass : 0.0
    self.volumetric = structure.cell.volume > 0.0 ? area * 1e4 / structure.cell.volume : 0.0
  }
}

public class SKNitrogenSurfaceArea
{
  private static let gridSize: Int = 128

  // Wells shallower than this are not surface: the trim, in kelvin. Zero keeps everything the probe is bound to
  // at all, which is the whole sheet the framework holds it against.
  private static let isovalue: Double = 0.0

  // The area of the well surface: the sheet of positions where the probe rests at the floor of its energy well
  // against the framework. That is the surface a molecule actually sits on, and so the accessible surface area.
  // The zero-energy isosurface, further out, is where the probe would be turning back rather than resting, and
  // it measures roughly twice as much area --- for silicalite 704 against 344 square metre per gram, where BET
  // measurements land between 300 and 450. Both are reported: the energy isosurface as the volumetric and
  // gravimetric surface area, the well surface as the well-surface area.
  //
  // Applied blocking pockets close the surface off around themselves, which takes an inaccessible cage's own
  // internal sheet --- counted in full otherwise --- out of the total. A pocket sunk in the framework wall,
  // where one belongs, contributes no surface of its own, since the wall is already outside the sheet there.
  //
  // Where a channel is narrower than the probe's contact diameter there is no sheet to measure: the transverse
  // minima have merged onto the channel axis and the well is a line, not a surface (see SKMetalWellSurface).
  // A tight-fitting probe therefore reports less area than rolling it over the wall would --- in MFI a fifth of
  // the pore is like that for nitrogen --- which is the honest answer for a surface that is not there.
  public static func compute(structures: [SKFrameworkSnapshot]) throws -> [SKSurfaceAreaResult]
  {
    var results: [SKSurfaceAreaResult] = []
    guard let device = MTLCreateSystemDefaultDevice(),
          let commandQueue: MTLCommandQueue = device.makeCommandQueue() else {return structures.map{SKSurfaceAreaResult(area: 0.0, structure: $0)}}

    let dimensions: SIMD3<Int32> = SIMD3<Int32>(Int32(gridSize), Int32(gridSize), Int32(gridSize))

    for structure in structures
    {
      let numberOfReplicas: SIMD3<Int32> = structure.cell.numberOfReplicas(forCutoff: 12.0)
      let framework: SKMetalFramework = SKMetalFramework(device: device, commandQueue: commandQueue, positions: structure.positions, potentialParameters: structure.potentialParameters, unitCell: structure.cell.unitCell, numberOfReplicas: numberOfReplicas, blockingPockets: structure.blockingPockets)

      let field: [Float] = framework.ComputeWellFieldGrid(gridSize, sizeY: gridSize, sizeZ: gridSize, probeParameter: structure.probeParameters)

      guard let vertexBuffer: MTLBuffer = try SKMetalWellSurface.constructWellSurfaceVertexBuffer(device: device, commandQueue: commandQueue, field: field, isovalue: isovalue, dimensions: dimensions) else
      {
        LogQueue.shared.warning(destination: nil, message: "No well surface to measure a surface area on")
        results.append(SKSurfaceAreaResult(area: 0.0, structure: structure))
        continue
      }

      // Marching cubes puts the vertices on the probe-contact distance surface; the refinement slides each one
      // onto the true multi-atom well floor, which is the surface being measured.
      let trimIsovalue: Float = SKMetalWellSurface.effectiveTrimIsovalue(field: field, isovalue: isovalue, dimensions: dimensions)
      framework.RefineWellSurfaceVertexBuffer(vertexBuffer: vertexBuffer, probeParameter: structure.probeParameters, isovalue: trimIsovalue)

      results.append(SKSurfaceAreaResult(area: area(of: vertexBuffer, unitCell: structure.cell.unitCell), structure: structure))
    }
    return results
  }

  // The zero-energy isosurface of the probe-framework potential, the surface area iRASPA reported before the
  // well surface. Iso-value zero is where the probe is turning back, not where it rests.
  public static func computeEnergySurface(structures: [SKFrameworkSnapshot]) throws -> [SKSurfaceAreaResult]
  {
    var results: [SKSurfaceAreaResult] = []
    guard let device = MTLCreateSystemDefaultDevice(),
          let commandQueue: MTLCommandQueue = device.makeCommandQueue() else {return structures.map{SKSurfaceAreaResult(area: 0.0, structure: $0)}}

    let dimensions: SIMD3<Int32> = SIMD3<Int32>(Int32(gridSize), Int32(gridSize), Int32(gridSize))

    for structure in structures
    {
      let numberOfReplicas: SIMD3<Int32> = structure.cell.numberOfReplicas(forCutoff: 12.0)
      let framework: SKMetalFramework = SKMetalFramework(device: device, commandQueue: commandQueue, positions: structure.positions, potentialParameters: structure.potentialParameters, unitCell: structure.cell.unitCell, numberOfReplicas: numberOfReplicas, blockingPockets: structure.blockingPockets)

      let field: [Float] = framework.ComputeEnergyGrid(gridSize, sizeY: gridSize, sizeZ: gridSize, probeParameter: structure.probeParameters)

      guard let vertexBuffer: MTLBuffer = try SKMetalMarchingCubes.constructIsoSurfaceVertexBuffer(device: device, commandQueue: commandQueue, data: field, isovalue: 0.0, dimensions: dimensions) else
      {
        LogQueue.shared.warning(destination: nil, message: "No energy isosurface to measure a surface area on")
        results.append(SKSurfaceAreaResult(area: 0.0, structure: structure))
        continue
      }

      results.append(SKSurfaceAreaResult(area: area(of: vertexBuffer, unitCell: structure.cell.unitCell), structure: structure))
    }
    return results
  }

  // Three float4 per vertex --- position (unit-cell fractional), normal, pad --- and three vertices per
  // triangle. The surface is watertight and single-sheeted by construction, so every triangle counts.
  private static func area(of vertexBuffer: MTLBuffer, unitCell: double3x3) -> Double
  {
    let numberOfTriangles: Int = vertexBuffer.length / (9 * MemoryLayout<SIMD4<Float>>.stride)
    guard numberOfTriangles > 0 else {return 0.0}
    let vertices = vertexBuffer.contents().bindMemory(to: SIMD4<Float>.self, capacity: 9 * numberOfTriangles)

    var totalArea: Double = 0.0
    for triangle in 0..<numberOfTriangles
    {
      var corners: [SIMD3<Double>] = []
      for vertex in 0..<3
      {
        let position: SIMD4<Float> = vertices[9 * triangle + 3 * vertex]
        corners.append(unitCell * SIMD3<Double>(Double(position.x), Double(position.y), Double(position.z)))
      }
      let area: Double = 0.5 * simd.length(simd.cross(corners[1] - corners[0], corners[2] - corners[0]))
      if area.isFinite
      {
        totalArea += area
      }
    }
    return totalArea
  }
}
