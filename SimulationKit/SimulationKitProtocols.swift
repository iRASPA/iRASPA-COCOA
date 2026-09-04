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
import SymmetryKit
import simd


public protocol SKRenderAdsorptionSurfaceStructure
{
  var structureMass: Double {get}
  var cell: SKCell {get set}
  var potentialParameters: [SIMD2<Double>] {get}
  
  var atomUnitCellPositions: [SIMD3<Double>] {get}
  /// Atomic numbers of the unit-cell copies, in the same order as `atomUnitCellPositions`.
  /// The van der Waals geometric surface reads Bondi radii from these.
  var atomUnitCellElementIdentifiers: [Int] {get}
  var minimumGridEnergyValue: Float? {get set}
  var structureHeliumVoidFraction: Double {get set}
  var structureNitrogenSurfaceArea: Double {get set}
  
  // The probe the framework properties are measured with, as epsilon in kelvin and sigma in angstrom.
  var frameworkProbeParameters: SIMD2<Double> {get}
  
  // Spheres the probe may not enter, as a fractional position of the unit cell with a radius in angstrom.
  var blockingPockets: [SIMD4<Double>] {get}
  
  // Empty unless the structure asks for its blocking pockets to be applied, so a grid computation can pass
  // this on without knowing about the setting.
  var appliedBlockingPockets: [SIMD4<Double>] {get}
}


// Everything the framework property calculators read off a structure, taken in one go.
//
// They run on a background queue while the model stays editable, and reading positions off a structure walks
// its atom tree, so what they are given has to be a copy made where the model is safe to read.
public struct SKFrameworkSnapshot
{
  public let cell: SKCell
  
  // Fractional positions of the unit cell.
  public let positions: [SIMD3<Double>]
  public let potentialParameters: [SIMD2<Double>]
  
  // The probe of the framework properties measured with one; a helium void fraction uses helium regardless.
  public let probeParameters: SIMD2<Double>
  
  // Empty unless the structure asks for its blocking pockets to be applied.
  public let blockingPockets: [SIMD4<Double>]
  
  // Of the unit cell, in gram per mole.
  public let mass: Double
  
  public init(cell: SKCell, positions: [SIMD3<Double>], potentialParameters: [SIMD2<Double>], probeParameters: SIMD2<Double>, blockingPockets: [SIMD4<Double>] = [], mass: Double = 0.0)
  {
    self.cell = cell
    self.positions = positions
    self.potentialParameters = potentialParameters
    self.probeParameters = probeParameters
    self.blockingPockets = blockingPockets
    self.mass = mass
  }
  
  public init(_ structure: SKRenderAdsorptionSurfaceStructure)
  {
    self.init(cell: structure.cell, positions: structure.atomUnitCellPositions, potentialParameters: structure.potentialParameters, probeParameters: structure.frameworkProbeParameters, blockingPockets: structure.appliedBlockingPockets, mass: structure.structureMass)
  }
  
  /// Snapshot that always includes the structure's blocking pockets, whether or not they are applied
  /// to a drawn surface. Geometric surface area uses this: an inaccessible cage is cut out of the
  /// area even when "Apply blocking pockets" is off in Appearance.
  public static func applyingBlockingPockets(_ structure: SKRenderAdsorptionSurfaceStructure) -> SKFrameworkSnapshot
  {
    return SKFrameworkSnapshot(cell: structure.cell, positions: structure.atomUnitCellPositions, potentialParameters: structure.potentialParameters, probeParameters: structure.frameworkProbeParameters, blockingPockets: structure.blockingPockets, mass: structure.structureMass)
  }
}


