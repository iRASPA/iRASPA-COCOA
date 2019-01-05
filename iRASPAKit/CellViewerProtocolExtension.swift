/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2019 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl            http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 scaldia@upo.es                http://www.upo.es/raspa/sofiacalero.php
 t.j.h.vlugt@tudelft.nl        http://homepage.tudelft.nl/v9k6y
 
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
import simd
import MathKit
import RenderKit
import SymmetryKit

extension CellViewer
{
  public func renderRecomputeDensityProperties()
  {
    self.structureViewerStructures.forEach{$0.recomputeDensityProperties()}
  }
  
  public var renderMaterialType: Structure.MaterialType?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.materialType.rawValue })
      return Set(set).count == 1 ? Structure.MaterialType(rawValue: set.first!) : nil
    }
  }
  
  public var renderStructureMaterialType: String?
  {
    get
    {
      let set: Set<String> = Set(self.structureViewerStructures.compactMap{ return $0.structureMaterialType })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureMaterialType = newValue ?? ""}
    }
  }
  
  public var renderStructureMass: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureMass })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureMass = newValue ?? 0.0}
    }
  }
  
  public var renderStructureDensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureDensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureDensity = newValue ?? 0.0}
    }
  }
  
  public var renderStructureHeliumVoidFraction: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureHeliumVoidFraction })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureHeliumVoidFraction = newValue ?? 0.0}
    }
  }
  
  public var renderStructureSpecificVolume: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureSpecificVolume })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureSpecificVolume = newValue ?? 0.0}
    }
  }
  
  public var renderStructureAccessiblePoreVolume: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureAccessiblePoreVolume })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureAccessiblePoreVolume = newValue ?? 0.0}
    }
  }
  
  public var renderStructureVolumetricNitrogenSurfaceArea: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureVolumetricNitrogenSurfaceArea })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureVolumetricNitrogenSurfaceArea = newValue ?? 0.0}
    }
  }
  
  public var renderStructureGravimetricNitrogenSurfaceArea: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureGravimetricNitrogenSurfaceArea })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureGravimetricNitrogenSurfaceArea = newValue ?? 0.0}
    }
  }
  
  public var renderStructureNumberOfChannelSystems: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.structureNumberOfChannelSystems })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureNumberOfChannelSystems = newValue ?? 0}
    }
  }
  
  
  public var renderStructureNumberOfInaccessiblePockets: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.structureNumberOfInaccessiblePockets })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureNumberOfInaccessiblePockets = newValue ?? 0}
    }
  }
  
  public var renderStructureDimensionalityOfPoreSystem: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.structureDimensionalityOfPoreSystem })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureDimensionalityOfPoreSystem = newValue ?? 0}
    }
  }
  
  public var renderStructureLargestCavityDiameter: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureLargestCavityDiameter })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureLargestCavityDiameter = newValue ?? 0.0}
    }
  }
  
  
  public var renderStructureRestrictingPoreLimitingDiameter: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureRestrictingPoreLimitingDiameter })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureRestrictingPoreLimitingDiameter = newValue ?? 0.0}
    }
  }
  
  public var renderStructureLargestCavityDiameterAlongAViablePath: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureLargestCavityDiameterAlongAViablePath })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureLargestCavityDiameterAlongAViablePath = newValue ?? 0.0}
    }
  }
  
  
  
  public var spaceGroupHallNumber: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.spaceGroupHallNumber })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.spaceGroupHallNumber = newValue}
    }
  }
  
  
  public var renderUnitCellLengthA: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellLengthA })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.a = newValue ?? 20.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellLengthB: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellLengthB })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.b = newValue ?? 20.0
        $0.reComputeBoundingBox()
      }
    }
  }

  public var renderUnitCellLengthC: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellLengthC })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.c = newValue ?? 20.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  
  public var renderUnitCellAlphaAngle: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellAngleAlpha })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.alpha = newValue ?? 90.0*Double.pi/180.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellBetaAngle: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellAngleBeta })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.beta = newValue ?? 90.0*Double.pi/180.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellGammaAngle: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellAngleGamma })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.gamma = newValue ?? 90.0*Double.pi/180.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellAX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[0].x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[0].x = newValue ?? 20.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellAY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[0].y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[0].y = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellAZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[0].z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[0].z = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellBX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[1].x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[1].x = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellBY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[1].y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[1].y = newValue ?? 20.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellBZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[1].z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[1].z = newValue ?? 20.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellCX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[2].x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[2].x = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellCY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[2].y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[2].y = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellCZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[2].z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[2].z = newValue ?? 20.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderCellVolume: Double?
  {
    let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellVolume })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderCellPerpendicularWidthX: Double?
  {
    let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellPerpendicularWidthsX })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderCellPerpendicularWidthY: Double?
  {
    let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellPerpendicularWidthsY })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderCellPerpendicularWidthZ: Double?
  {
    let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellPerpendicularWidthsZ })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  
  public var renderOriginX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.origin.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.origin.x = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderOriginY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.origin.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.origin.y = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderOriginZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.origin.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.origin.z = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderOrientation: simd_quatd?
  {
    get
    {
      let origin: [simd_quatd] = self.structureViewerStructures.compactMap{$0.orientation}
      let q: simd_quatd = origin.reduce(simd_quatd()){return simd_add($0, $1)}
      let averaged_vector: simd_quatd = simd_quatd(ix: q.vector.x / Double(origin.count), iy: q.vector.y / Double(origin.count), iz: q.vector.z / Double(origin.count), r: q.vector.w / Double(origin.count))
      return origin.isEmpty ? nil : averaged_vector
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.orientation = newValue ?? simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)}
    }
  }
  
  public var renderRotationDelta: Double?
  {
    get
    {
      let origin: [Double] = self.structureViewerStructures.compactMap{$0.rotationDelta}
      return origin.isEmpty ? nil : origin.reduce(0.0){return $0 + $1} / Double(origin.count)
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.rotationDelta = newValue ?? 5.0}
    }
  }
  
  public var renderPeriodic: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.periodic })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.periodic = newValue ?? false}
    }
  }
  
  public var renderMinimumReplicaX: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.structureViewerStructures.compactMap{ return $0.cell.minimumReplica.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.minimumReplica.x = newValue ?? 0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderMinimumReplicaY: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.structureViewerStructures.compactMap{ return $0.cell.minimumReplica.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.minimumReplica.y = newValue ?? 0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderMinimumReplicaZ: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.structureViewerStructures.compactMap{ return $0.cell.minimumReplica.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.minimumReplica.z = newValue ?? 0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderMaximumReplicaX: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.structureViewerStructures.compactMap{ return $0.cell.maximumReplica.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.maximumReplica.x = newValue ?? 0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderMaximumReplicaY: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.structureViewerStructures.compactMap{ return $0.cell.maximumReplica.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.maximumReplica.y = newValue ?? 0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderMaximumReplicaZ: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.structureViewerStructures.compactMap{ return $0.cell.maximumReplica.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.maximumReplica.z = newValue ?? 0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  
  public var renderEulerAngleX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return ($0.orientation.EulerAngles).x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.orientation.EulerAngles = double3(newValue ?? 0.0,$0.orientation.EulerAngles.y,$0.orientation.EulerAngles.z)}
    }
  }
  
  public var renderEulerAngleY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return ($0.orientation.EulerAngles).y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.orientation.EulerAngles = double3($0.orientation.EulerAngles.x, newValue ?? 0.0,$0.orientation.EulerAngles.z)}
    }
  }
  
  public var renderEulerAngleZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return ($0.orientation.EulerAngles).z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.orientation.EulerAngles = double3($0.orientation.EulerAngles.x, $0.orientation.EulerAngles.y, newValue ?? 0.0)}
    }
  }
  
  public var renderBoundingBox: SKBoundingBox
  {
    var minimum: double3 = double3(x: Double.greatestFiniteMagnitude, y: Double.greatestFiniteMagnitude, z: Double.greatestFiniteMagnitude)
    var maximum: double3 = double3(x: -Double.greatestFiniteMagnitude, y: -Double.greatestFiniteMagnitude, z: -Double.greatestFiniteMagnitude)
    
    for frame in self.structureViewerStructures
    {
      let transformedBoundingBox: SKBoundingBox = frame.transformedBoundingBox
      
      minimum.x = min(minimum.x, transformedBoundingBox.minimum.x + frame.origin.x)
      minimum.y = min(minimum.y, transformedBoundingBox.minimum.y + frame.origin.y)
      minimum.z = min(minimum.z, transformedBoundingBox.minimum.z + frame.origin.z)
      maximum.x = max(maximum.x, transformedBoundingBox.maximum.x + frame.origin.x)
      maximum.y = max(maximum.y, transformedBoundingBox.maximum.y + frame.origin.y)
      maximum.z = max(maximum.z, transformedBoundingBox.maximum.z + frame.origin.z)
    }
    
    return SKBoundingBox(minimum: minimum, maximum: maximum)
  }
  
  public func reComputeBoundingBox()
  {
    self.structureViewerStructures.forEach{$0.reComputeBoundingBox()}
  }
  
  public var renderCellPrecision: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cell.precision })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.cell.precision = newValue ?? 1e-5}
    }
  }
}

extension Array where Iterator.Element == CellViewer
{
  public var structureViewerStructures: [Structure]
  {
    return self.flatMap{$0.structureViewerStructures}
  }
  
  public var selectedFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.selectedRenderFrames}
  }
  
  public var allFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.allFrames}
  }
  
  public func renderRecomputeDensityProperties()
  {
    self.structureViewerStructures.forEach{$0.recomputeDensityProperties()}
  }
  
  public var renderMaterialType: Structure.MaterialType?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.materialType.rawValue })
      return Set(set).count == 1 ? Structure.MaterialType(rawValue: set.first!) : nil
    }
  }
  
  public var renderStructureMaterialType: String?
  {
    get
    {
      let set: Set<String> = Set(self.structureViewerStructures.compactMap{ return $0.structureMaterialType })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureMaterialType = newValue ?? ""}
    }
  }
  
  public var renderStructureMass: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureMass })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureMass = newValue ?? 0.0}
    }
  }
  
  public var renderStructureDensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureDensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureDensity = newValue ?? 0.0}
    }
  }
  
  public var renderStructureHeliumVoidFraction: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureHeliumVoidFraction })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureHeliumVoidFraction = newValue ?? 0.0}
    }
  }
  
  public var renderStructureSpecificVolume: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureSpecificVolume })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureSpecificVolume = newValue ?? 0.0}
    }
  }
  
  public var renderStructureAccessiblePoreVolume: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureAccessiblePoreVolume })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureAccessiblePoreVolume = newValue ?? 0.0}
    }
  }
  
  public var renderStructureVolumetricNitrogenSurfaceArea: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureVolumetricNitrogenSurfaceArea })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureVolumetricNitrogenSurfaceArea = newValue ?? 0.0}
    }
  }
  
  public var renderStructureGravimetricNitrogenSurfaceArea: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureGravimetricNitrogenSurfaceArea })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureGravimetricNitrogenSurfaceArea = newValue ?? 0.0}
    }
  }
  
  public var renderStructureNumberOfChannelSystems: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.structureNumberOfChannelSystems })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureNumberOfChannelSystems = newValue ?? 0}
    }
  }
  
  public var renderStructureNumberOfInaccessiblePockets: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.structureNumberOfInaccessiblePockets })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureNumberOfInaccessiblePockets = newValue ?? 0}
    }
  }
  
  public var renderStructureDimensionalityOfPoreSystem: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.structureDimensionalityOfPoreSystem })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureDimensionalityOfPoreSystem = newValue ?? 0}
    }
  }
  
  public var renderStructureLargestCavityDiameter: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureLargestCavityDiameter})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureLargestCavityDiameter = newValue ?? 0.0}
    }
  }
  
  public var renderStructureRestrictingPoreLimitingDiameter: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureRestrictingPoreLimitingDiameter })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureRestrictingPoreLimitingDiameter = newValue ?? 0.0}
    }
  }
  
  public var renderStructureLargestCavityDiameterAlongAViablePath: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.structureLargestCavityDiameterAlongAViablePath })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.structureLargestCavityDiameterAlongAViablePath = newValue ?? 0.0}
    }
  }

  
  public var renderBoundingBoxMinimumX: Double?
  {
    let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cell.boundingBox.minimum.x })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderBoundingBoxMinimumY: Double?
  {
    let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cell.boundingBox.minimum.y })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderBoundingBoxMinimumZ: Double?
  {
    let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cell.boundingBox.minimum.z })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderBoundingBoxMaximumX: Double?
  {
    let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cell.boundingBox.maximum.x })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderBoundingBoxMaximumY: Double?
  {
    let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cell.boundingBox.maximum.y })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderBoundingBoxMaximumZ: Double?
  {
    let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cell.boundingBox.maximum.z })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var spaceGroupHallNumber: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.spaceGroupHallNumber })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.spaceGroupHallNumber = newValue}
    }
  }
  
  
  public var renderUnitCellLengthA: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellLengthA })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.a = newValue ?? 20.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellLengthB: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellLengthB })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.b = newValue ?? 20.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellLengthC: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellLengthC })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.c = newValue ?? 20.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  
  public var renderUnitCellAlphaAngle: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellAngleAlpha })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.alpha = newValue ?? 90.0*Double.pi/180.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellBetaAngle: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellAngleBeta })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.beta = newValue ?? 90.0*Double.pi/180.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellGammaAngle: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellAngleGamma })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.gamma = newValue ?? 90.0*Double.pi/180.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellAX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[0].x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[0].x = newValue ?? 20.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellAY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[0].y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[0].y = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellAZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[0].z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[0].z = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellBX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[1].x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[1].x = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellBY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[1].y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[1].y = newValue ?? 20.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellBZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[1].z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.cell.unitCell[1].z = newValue ?? 20.0}
    }
  }
  
  public var renderUnitCellCX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[2].x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[2].x = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellCY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[2].y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[2].y = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellCZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCell[2].z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.unitCell[2].z = newValue ?? 20.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderCellVolume: Double?
  {
    let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellVolume })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderCellPerpendicularWidthX: Double?
  {
    let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellPerpendicularWidthsX })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderCellPerpendicularWidthY: Double?
  {
    let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellPerpendicularWidthsY })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderCellPerpendicularWidthZ: Double?
  {
    let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cellPerpendicularWidthsZ })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  
  public var renderOriginX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.origin.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.origin.x = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderOriginY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.origin.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.origin.y = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderOriginZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.origin.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.origin.z = newValue ?? 0.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderOrientation: simd_quatd?
  {
    get
    {
      let origin: [simd_quatd] = self.structureViewerStructures.compactMap{$0.orientation}
      let q: simd_quatd = origin.reduce(simd_quatd()){return simd_add($0, $1)}
      let averaged_vector: simd_quatd = simd_quatd(ix: q.vector.x / Double(origin.count), iy: q.vector.y / Double(origin.count), iz: q.vector.z / Double(origin.count), r: q.vector.w / Double(origin.count))
      return origin.isEmpty ? nil : averaged_vector
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.orientation = newValue ?? simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)}
    }
  }
  
  public var renderRotationDelta: Double?
  {
    get
    {
      let origin: [Double] = self.structureViewerStructures.compactMap{$0.rotationDelta}
      return origin.isEmpty ? nil : origin.reduce(0.0){return $0 + $1} / Double(origin.count)
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.rotationDelta = newValue ?? 5.0}
    }
  }
  
  public var renderPeriodic: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.periodic })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.periodic = newValue ?? false}
    }
  }
  
  public var renderMinimumReplicaX: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.structureViewerStructures.compactMap{ return $0.cell.minimumReplica.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.minimumReplica.x = newValue ?? 0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderMinimumReplicaY: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.structureViewerStructures.compactMap{ return $0.cell.minimumReplica.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.minimumReplica.y = newValue ?? 0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderMinimumReplicaZ: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.structureViewerStructures.compactMap{ return $0.cell.minimumReplica.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.minimumReplica.z = newValue ?? 0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderMaximumReplicaX: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.structureViewerStructures.compactMap{ return $0.cell.maximumReplica.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.maximumReplica.x = newValue ?? 0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderMaximumReplicaY: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.structureViewerStructures.compactMap{ return $0.cell.maximumReplica.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.maximumReplica.y = newValue ?? 0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderMaximumReplicaZ: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.structureViewerStructures.compactMap{ return $0.cell.maximumReplica.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.cell.maximumReplica.z = newValue ?? 0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  
  public var renderEulerAngleX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return ($0.orientation.EulerAngles).x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.orientation.EulerAngles = double3(newValue ?? 0.0,$0.orientation.EulerAngles.y,$0.orientation.EulerAngles.z)}
    }
  }
  
  public var renderEulerAngleY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return ($0.orientation.EulerAngles).y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.orientation.EulerAngles = double3($0.orientation.EulerAngles.x, newValue ?? 0.0,$0.orientation.EulerAngles.z)}
    }
  }
  
  public var renderEulerAngleZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return ($0.orientation.EulerAngles).z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.orientation.EulerAngles = double3($0.orientation.EulerAngles.x, $0.orientation.EulerAngles.y, newValue ?? 0.0)}
    }
  }
  
  public var renderBoundingBox: SKBoundingBox
  {
    var minimum: double3 = double3(x: Double.greatestFiniteMagnitude, y: Double.greatestFiniteMagnitude, z: Double.greatestFiniteMagnitude)
    var maximum: double3 = double3(x: -Double.greatestFiniteMagnitude, y: -Double.greatestFiniteMagnitude, z: -Double.greatestFiniteMagnitude)
    
    for frame in self.structureViewerStructures
    {
      let transformedBoundingBox: SKBoundingBox = frame.transformedBoundingBox
      
      minimum.x = Swift.min(minimum.x, transformedBoundingBox.minimum.x + frame.origin.x)
      minimum.y = Swift.min(minimum.y, transformedBoundingBox.minimum.y + frame.origin.y)
      minimum.z = Swift.min(minimum.z, transformedBoundingBox.minimum.z + frame.origin.z)
      maximum.x = Swift.max(maximum.x, transformedBoundingBox.maximum.x + frame.origin.x)
      maximum.y = Swift.max(maximum.y, transformedBoundingBox.maximum.y + frame.origin.y)
      maximum.z = Swift.max(maximum.z, transformedBoundingBox.maximum.z + frame.origin.z)
    }
    
    return SKBoundingBox(minimum: minimum, maximum: maximum)
  }
  
  public func reComputeBoundingBox()
  {
    self.structureViewerStructures.forEach{$0.reComputeBoundingBox()}
  }
  
  public var renderCellPrecision: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.cell.precision })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.cell.precision = newValue ?? 1e-5}
    }
  }
}

