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
import RenderKit
import simd
import SymmetryKit
import SimulationKit

// MARK: -
// MARK: AtomVisualAppearanceViewer protocol implementation

extension PrimitiveVisualAppearanceViewer
{
  public var renderPrimitiveOrientation: simd_quatd?
  {
    get
    {
      let origin: [simd_quatd] = self.structureViewerStructures.compactMap{$0.primitiveOrientation}
      let q: simd_quatd = origin.reduce(simd_quatd()){return simd_add($0, $1)}
      let averaged_vector: simd_quatd = simd_quatd(ix: q.vector.x / Double(origin.count), iy: q.vector.y / Double(origin.count), iz: q.vector.z / Double(origin.count), r: q.vector.w / Double(origin.count))
      return origin.isEmpty ? nil : averaged_vector
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveOrientation = newValue ?? simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveRotationDelta: Double?
  {
    get
    {
      let origin: [Double] = self.structureViewerStructures.compactMap{$0.primitiveRotationDelta}
      return origin.isEmpty ? nil : origin.reduce(0.0){return $0 + $1} / Double(origin.count)
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveRotationDelta = newValue ?? 5.0}
    }
  }
  
  public var renderPrimitiveEulerAngleX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return ($0.primitiveOrientation.EulerAngles).x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveOrientation.EulerAngles = double3(newValue ?? 0.0,$0.primitiveOrientation.EulerAngles.y,$0.primitiveOrientation.EulerAngles.z)
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveEulerAngleY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return ($0.primitiveOrientation.EulerAngles).y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveOrientation.EulerAngles = double3($0.primitiveOrientation.EulerAngles.x, newValue ?? 0.0,$0.primitiveOrientation.EulerAngles.z)
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveEulerAngleZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return ($0.primitiveOrientation.EulerAngles).z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveOrientation.EulerAngles = double3($0.primitiveOrientation.EulerAngles.x, $0.primitiveOrientation.EulerAngles.y, newValue ?? 0.0)
        $0.reComputeBoundingBox()
      }
    }
  }
  
  
  public var renderPrimitiveTransformationMatrix: double3x3?
  {
    get
    {
      let set: Set<double3x3> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix = newValue ?? double3x3(1.0)
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixAX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[0].x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[0].x = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixAY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[0].y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[0].y = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixAZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[0].z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[0].z = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixBX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[1].x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[1].x = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixBY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[1].y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[1].y = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixBZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[1].z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[1].z = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixCX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[2].x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[2].x = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixCY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[2].y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[2].y = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixCZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[2].z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[2].z = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveOpacity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveOpacity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveOpacity = newValue ?? 1.0}
    }
  }
  
  public var renderPrimitiveNumberOfSides: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveNumberOfSides })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveNumberOfSides = newValue ?? 6}
    }
  }
  
  public var renderPrimitiveIsCapped: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveIsCapped })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveIsCapped = newValue ?? false}
    }
  }
  
  public var renderPrimitiveIsFractional: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveIsFractional })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveIsFractional = newValue ?? false}
    }
  }
  
  public var renderPrimitiveThickness: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveThickness })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveThickness = newValue ?? 0.05}
    }
  }
  
  public var renderPrimitiveFrontSideHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideHDR = newValue ?? true}
    }
  }
  
  public var renderPrimitiveFrontSideHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideHDRExposure = newValue ?? 1.5}
    }
  }
  
  public var renderPrimitiveFrontSideAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  
  public var renderPrimitiveFrontSideAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideAmbientColor = newValue ?? NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)}
    }
  }
  
  public var renderPrimitiveFrontSideDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderPrimitiveFrontSideDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideDiffuseColor = newValue ?? NSColor(red: 0.588235, green: 0.670588, blue: 0.729412, alpha: 1.0)}
    }
  }
  
  public var renderPrimitiveFrontSideSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderPrimitiveFrontSideSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideSpecularColor = newValue ?? NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)}
    }
  }
  
  public var renderPrimitiveFrontSideShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideShininess = newValue ?? 4.0}
    }
  }
  
  public var renderPrimitiveBackSideHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideHDR = newValue ?? true}
    }
  }
  
  public var renderPrimitiveBackSideHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideHDRExposure = newValue ?? 1.5}
    }
  }
  
  
  public var renderPrimitiveBackSideAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderPrimitiveBackSideAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideAmbientColor = newValue ?? NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)}
    }
  }
  
  
  public var renderPrimitiveBackSideDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderPrimitiveBackSideDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideDiffuseColor = newValue ?? NSColor(red: 0.588235, green: 0.670588, blue: 0.729412, alpha: 1.0)}
    }
  }
  
  public var renderPrimitiveBackSideSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderPrimitiveBackSideSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideSpecularColor = newValue ?? NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)}
    }
  }
  
  public var renderPrimitiveBackSideShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideShininess = newValue ?? 4.0}
    }
  }
}

extension Array where Iterator.Element == PrimitiveVisualAppearanceViewer
{
  public var selectedFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.selectedRenderFrames}
  }
  
  public var allFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.allFrames}
  }
  
  public var structureViewerStructures: [Structure]
  {
    return self.flatMap{$0.structureViewerStructures}
  }
  
  public var renderPrimitiveOrientation: simd_quatd?
  {
    get
    {
      let origin: [simd_quatd] = self.structureViewerStructures.compactMap{$0.primitiveOrientation}
      let q: simd_quatd = origin.reduce(simd_quatd()){return simd_add($0, $1)}
      let averaged_vector: simd_quatd = simd_quatd(ix: q.vector.x / Double(origin.count), iy: q.vector.y / Double(origin.count), iz: q.vector.z / Double(origin.count), r: q.vector.w / Double(origin.count))
      return origin.isEmpty ? nil : averaged_vector
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveOrientation = newValue ?? simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveRotationDelta: Double?
  {
    get
    {
      let origin: [Double] = self.structureViewerStructures.compactMap{$0.primitiveRotationDelta}
      return origin.isEmpty ? nil : origin.reduce(0.0){return $0 + $1} / Double(origin.count)
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveRotationDelta = newValue ?? 5.0}
    }
  }
  
  public var renderPrimitiveEulerAngleX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return ($0.primitiveOrientation.EulerAngles).x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveOrientation.EulerAngles = double3(newValue ?? 0.0,$0.primitiveOrientation.EulerAngles.y,$0.primitiveOrientation.EulerAngles.z)
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveEulerAngleY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return ($0.primitiveOrientation.EulerAngles).y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveOrientation.EulerAngles = double3($0.primitiveOrientation.EulerAngles.x, newValue ?? 0.0,$0.primitiveOrientation.EulerAngles.z)
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveEulerAngleZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return ($0.primitiveOrientation.EulerAngles).z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveOrientation.EulerAngles = double3($0.primitiveOrientation.EulerAngles.x, $0.primitiveOrientation.EulerAngles.y, newValue ?? 0.0)
        $0.reComputeBoundingBox()
      }
    }
  }
  
  
  public var renderPrimitiveTransformationMatrix: double3x3?
  {
    get
    {
      let set: Set<double3x3> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix = newValue ?? double3x3(1.0)
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixAX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[0].x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[0].x = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixAY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[0].y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[0].y = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixAZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[0].z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[0].z = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixBX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[1].x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[1].x = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixBY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[1].y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[1].y = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixBZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[1].z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[1].z = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixCX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[2].x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[2].x = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixCY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[2].y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[2].y = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveTransformationMatrixCZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveTransformationMatrix[2].z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{
        $0.primitiveTransformationMatrix[2].z = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  public var renderPrimitiveOpacity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveOpacity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveOpacity = newValue ?? 1.0}
    }
  }
  
  public var renderPrimitiveNumberOfSides: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveNumberOfSides })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveNumberOfSides = newValue ?? 6}
    }
  }
  
  public var renderPrimitiveIsCapped: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveIsCapped })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveIsCapped = newValue ?? false}
    }
  }
  
  public var renderPrimitiveIsFractional: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveIsFractional })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveIsFractional = newValue ?? false}
    }
  }
  
  public var renderPrimitiveThickness: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveThickness })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveThickness = newValue ?? 0.05}
    }
  }
  
  public var renderPrimitiveFrontSideHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideHDR = newValue ?? true}
    }
  }
  
  public var renderPrimitiveFrontSideHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideHDRExposure = newValue ?? 1.5}
    }
  }
  
  public var renderPrimitiveFrontSideAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  
  public var renderPrimitiveFrontSideAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideAmbientColor = newValue ?? NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)}
    }
  }
  
  public var renderPrimitiveFrontSideDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderPrimitiveFrontSideDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideDiffuseColor = newValue ?? NSColor(red: 0.588235, green: 0.670588, blue: 0.729412, alpha: 1.0)}
    }
  }
  
  public var renderPrimitiveFrontSideSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderPrimitiveFrontSideSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideSpecularColor = newValue ?? NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)}
    }
  }
  
  public var renderPrimitiveFrontSideShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveFrontSideShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveFrontSideShininess = newValue ?? 4.0}
    }
  }
  
  public var renderPrimitiveBackSideHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideHDR = newValue ?? true}
    }
  }
  
  public var renderPrimitiveBackSideHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideHDRExposure = newValue ?? 1.5}
    }
  }
  
  
  public var renderPrimitiveBackSideAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderPrimitiveBackSideAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideAmbientColor = newValue ?? NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)}
    }
  }
  
  
  public var renderPrimitiveBackSideDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderPrimitiveBackSideDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideDiffuseColor = newValue ?? NSColor(red: 0.588235, green: 0.670588, blue: 0.729412, alpha: 1.0)}
    }
  }
  
  public var renderPrimitiveBackSideSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderPrimitiveBackSideSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideSpecularColor = newValue ?? NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)}
    }
  }
  
  public var renderPrimitiveBackSideShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.primitiveBackSideShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.primitiveBackSideShininess = newValue ?? 4.0}
    }
  }
}