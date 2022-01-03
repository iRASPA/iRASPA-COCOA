/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2021 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

import Cocoa
import RenderKit
import SimulationKit
import SymmetryKit
import BinaryCodable
import OperationKit
import LogViewKit
import simd

public class GaussianCubeVolumetricData: Structure, UnitCellViewer, IsosurfaceViewer, RKRenderAtomSource, RKRenderBondSource, RKRenderUnitCellSource, RKRenderLocalAxesSource, RKRenderAdsorptionSurfaceSource
{  
  private static var classVersionNumber: Int = 1
  
  public var dimensions: SIMD3<Int32> = SIMD3<Int32>()
  public var spacing: SIMD3<Double> = SIMD3<Double>()
  public var range: (Double, Double) = (0.0,0.0)
  public var data: Data = Data()
  public var average: Double = 0.0
  public var variance: Double = 0.0
  
  
  public override var materialType: Object.ObjectType
  {
    return .GaussianCubeVolumetricData
  }
  
  public required init(copy GaussianCubeVolume: GaussianCubeVolumetricData)
  {
    super.init(copy: GaussianCubeVolume)
  }
  
  public required init(clone GaussianCubeVolume: GaussianCubeVolumetricData)
  {
    super.init(clone: GaussianCubeVolume)
  }
  
  public required init(from object: Object)
  {
    super.init(from: object)
    
    if let isosurfaceViewer: IsosurfaceViewer = object as? IsosurfaceViewer
    {
      self.dimensions = isosurfaceViewer.dimensions
      self.spacing = isosurfaceViewer.spacing
      self.range = isosurfaceViewer.range
      self.data = isosurfaceViewer.data
      self.average = isosurfaceViewer.average
      self.variance = isosurfaceViewer.variance
    }
  }
  
  public init(name: String, dimensions: SIMD3<Int32>, spacing: SIMD3<Double>, cell: SKCell, data: Data, range: (Double,Double), average: Double, variance: Double)
  {
    super.init()
    self.displayName = name
    self.cell = cell
    self.dimensions = dimensions
    self.spacing = spacing
    self.data = data
    self.encompassingPowerOfTwoCubicGridSize = encompassingPowerOfTwoCubicGridSize
    self.minimumGridEnergyValue = Float(range.0)
    self.maximumGridEnergyValue = Float(0.0)
    self.range = (range.0, range.1)
    self.average = average
    self.variance = variance
    self.adsorptionSurfaceIsoValue = average
    self.adsorptionSurfaceRenderingMethod = .isoSurface
    self.adsorptionVolumeTransferFunction = .CoolWarmDiverging
    self.drawAdsorptionSurface = true
    
    let largestSize: Int = Int(max(dimensions.x,dimensions.y,dimensions.z))
    var k: Int = 1
    while(largestSize > Int(pow(2.0,Double(k))))
    {
      k += 1
    }
    self.encompassingPowerOfTwoCubicGridSize = k
    self.adsorptionVolumeStepLength = 0.5 / pow(2.0,Double(k))
  }
  
  
  
  public override var colorAtomsWithBondColor: Bool
  {
    return (self.atomRepresentationType == .unity && self.bondColorMode == .uniform)
  }
  
  public override var clipAtomsAtUnitCell: Bool
  {
    return false;
    //return atomRepresentationType == .unity
  }
  
  public override var clipBondsAtUnitCell: Bool
  {
    return true
  }
  
  public var isImmutable: Bool
  {
    return true
  }
  
  public override var isFractional: Bool
  {
    return true
  }
  
  public var gridData: [Float]
  {
    var copiedData = [Float](repeating: Float(0.0), count: data.count / MemoryLayout<Float>.stride)
    let _ = copiedData.withUnsafeMutableBytes { data.copyBytes(to: $0, from: 0..<data.count) }
    
    let encompassingCubicGridSize: Int32 = Int32(pow(2.0, Double(self.encompassingPowerOfTwoCubicGridSize)))
    let numberOfValues: Int32 = encompassingCubicGridSize * encompassingCubicGridSize * encompassingCubicGridSize
    var newdata = Array<Float>(repeating: 0.0, count: Int(numberOfValues))
    
    for x: Int32 in 0..<dimensions.x
    {
      for y: Int32 in 0..<dimensions.y
      {
        for z: Int32 in 0..<dimensions.z
        {
          let index: Int = Int(x+encompassingCubicGridSize*y+z*encompassingCubicGridSize*encompassingCubicGridSize)
          newdata[index] = copiedData[Int(x + dimensions.x*y + z*dimensions.x*dimensions.y)]
        }
      }
    }

    return newdata
  }
  
  public var gridValueAndGradientData: [SIMD4<Float>]
  {
    var copiedData = [Float](repeating: Float(0.0), count: data.count / MemoryLayout<Float>.stride)
    let _ = copiedData.withUnsafeMutableBytes { data.copyBytes(to: $0, from: 0..<data.count) }
    
    for i in 0..<data.count / MemoryLayout<Float>.stride
    {
      let value = copiedData[i]
      copiedData[i] = Float((Double(value) - range.0) / (range.1 - range.0))
    }
    
    let encompassingCubicGridSize: Int32 = Int32(pow(2.0, Double(self.encompassingPowerOfTwoCubicGridSize)))
    let numberOfValues: Int32 = encompassingCubicGridSize * encompassingCubicGridSize * encompassingCubicGridSize
    var newdata = Array<SIMD4<Float>>(repeating: SIMD4<Float>(0.0,0.0,0.0,0.0), count: Int(numberOfValues))
    
    
    
    for x: Int32 in 0..<dimensions.x
    {
      for y: Int32 in 0..<dimensions.y
      {
        for z: Int32 in 0..<dimensions.z
        {
          let index: Int = Int(x+encompassingCubicGridSize*y+z*encompassingCubicGridSize*encompassingCubicGridSize)
          let value = copiedData[Int(x + dimensions.x*y + z*dimensions.x*dimensions.y)]
          
          let xi: Int32 = Int32(Float(x) + 0.5)
          let xf: Float = Float(x) + 0.5 - Float(xi)
          let xd0: Float = copiedData[Int(((xi-1 + dimensions.x) % dimensions.x)+y*dimensions.x+z*dimensions.x*dimensions.y)]
          let xd1: Float = copiedData[Int((xi)+y*dimensions.x+z*dimensions.x*dimensions.y)]
          let xd2: Float = copiedData[Int(((xi+1 + dimensions.x) % dimensions.x)+y*dimensions.x+z*dimensions.x*dimensions.y)]
          let gx: Float = (xd1 - xd0) * (1.0 - xf) + (xd2 - xd1) * xf

          let yi: Int32 = Int32(Float(y) + 0.5)
          let yf: Float = Float(y) + 0.5 - Float(yi)
          let yd0: Float = copiedData[Int(x + ((yi-1+dimensions.y) % dimensions.y)*dimensions.x+z*dimensions.x*dimensions.y)]
          let yd1: Float = copiedData[Int(x + (yi)*dimensions.x+z*dimensions.x*dimensions.y)]
          let yd2: Float = copiedData[Int(x + ((yi+1+dimensions.y) % dimensions.y)*dimensions.x+z*dimensions.x*dimensions.y)]
          let gy: Float = (yd1 - yd0) * (1.0 - yf) + (yd2 - yd1) * yf

          let zi: Int32 = Int32(Float(z) + 0.5)
          let zf: Float = Float(z) + 0.5 - Float(zi)
          let zd0: Float =  copiedData[Int(x+y*dimensions.x+((zi-1+dimensions.z) % dimensions.z)*dimensions.x*dimensions.y)]
          let zd1: Float =  copiedData[Int(x+y*dimensions.x+(zi)*dimensions.x*dimensions.y)]
          let zd2: Float =  copiedData[Int(x+y*dimensions.x+((zi+1+dimensions.z) % dimensions.z)*dimensions.x*dimensions.y)]
          let gz: Float =  (zd1 - zd0) * (1.0 - zf) + (zd2 - zd1) * zf
          
          newdata[index] = SIMD4<Float>(value,gx,gy,gz)
        }
      }
    }
    return newdata
  }
  
  // MARK: -
  // MARK: Cell property-wrapper
  
  public override var unitCell: double3x3
  {
    return self.cell.unitCell
  }
  
  public override var cellLengthB: Double
  {
    return self.cell.b
  }
  
  public override var cellLengthC: Double
  {
    return self.cell.c
  }
  
  public override var cellAngleAlpha: Double
  {
    return self.cell.alpha
  }
  
  public override var cellAngleBeta: Double
  {
    return self.cell.beta
  }
  
  public override var cellAngleGamma: Double
  {
    return self.cell.gamma
  }
  
  public override var cellVolume: Double
  {
    return self.cell.volume
  }
  
  public override var cellPerpendicularWidthsX: Double
  {
    return self.cell.perpendicularWidths.x
  }
  
  public override var cellPerpendicularWidthsY: Double
  {
    return self.cell.perpendicularWidths.y
  }
  
  public override var cellPerpendicularWidthsZ: Double
  {
    return self.cell.perpendicularWidths.z
  }
  
  public override var boundingBox: SKBoundingBox
  {
    if(self.drawUnitCell)
    {
      let minimumReplica = cell.minimumReplica
      let maximumReplica = cell.maximumReplica
      
      let c0: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(minimumReplica.x),  y: Double(minimumReplica.y),  z: Double(minimumReplica.z)))
      let c1: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(minimumReplica.y),   z: Double(minimumReplica.z)))
      let c2: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(maximumReplica.y+1), z: Double(minimumReplica.z)))
      let c3: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(minimumReplica.x),   y: Double(maximumReplica.y+1), z: Double(minimumReplica.z)))
      let c4: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(minimumReplica.x),   y: Double(minimumReplica.y),   z: Double(maximumReplica.z+1)))
      let c5: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(minimumReplica.y),   z: Double(maximumReplica.z+1)))
      let c6: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(maximumReplica.x+1), y: Double(maximumReplica.y+1), z: Double(maximumReplica.z+1)))
      let c7: SIMD3<Double> = self.cell.unitCell * (SIMD3<Double>(x: Double(minimumReplica.x),   y: Double(maximumReplica.y+1), z: Double(maximumReplica.z+1)))
      
      let minimum = SIMD3<Double>(x: min(c0.x, c1.x, c2.x, c3.x, c4.x, c5.x, c6.x, c7.x),
                                  y: min(c0.y, c1.y, c2.y, c3.y, c4.y, c5.y, c6.y, c7.y),
                                  z: min(c0.z, c1.z, c2.z, c3.z, c4.z, c5.z, c6.z, c7.z))
  
      let maximum = SIMD3<Double>(x: max(c0.x, c1.x, c2.x, c3.x, c4.x, c5.x, c6.x, c7.x),
                                  y: max(c0.y, c1.y, c2.y, c3.y, c4.y, c5.y, c6.y, c7.y),
                                  z: max(c0.z, c1.z, c2.z, c3.z, c4.z, c5.z, c6.z, c7.z))
      
      return SKBoundingBox(minimum: minimum, maximum: maximum)
    }
    
    var minimum: SIMD3<Double> = SIMD3<Double>(x: Double.greatestFiniteMagnitude, y: Double.greatestFiniteMagnitude, z: Double.greatestFiniteMagnitude)
    var maximum: SIMD3<Double> = SIMD3<Double>(x: -Double.greatestFiniteMagnitude, y: -Double.greatestFiniteMagnitude, z: -Double.greatestFiniteMagnitude)
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    for atom in atoms
    {
      for k1 in minimumReplicaX...maximumReplicaX
      {
        for k2 in minimumReplicaY...maximumReplicaY
        {
          for k3 in minimumReplicaZ...maximumReplicaZ
          {
            let radius: Double = (atom.asymmetricParentAtom?.drawRadius ?? 0.0) * self.atomScaleFactor
            
            let cartesianPosition: SIMD3<Double> = cell.unitCell * (atom.position +  SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)))
            
            minimum.x = min(minimum.x, cartesianPosition.x - radius)
            minimum.y = min(minimum.y, cartesianPosition.y - radius)
            minimum.z = min(minimum.z, cartesianPosition.z - radius)
            
            maximum.x = max(maximum.x, cartesianPosition.x + radius)
            maximum.y = max(maximum.y, cartesianPosition.y + radius)
            maximum.z = max(maximum.z, cartesianPosition.z + radius)
          }
        }
      }
    }
    
    return SKBoundingBox(minimum: minimum, maximum: maximum)
  }
  
  
  // MARK: Rendering
  // =====================================================================
  
  public override var renderAtoms: [RKInPerInstanceAttributesAtoms]
  {
    var index: Int
    
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldViewer)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
    
    let numberOfReplicas: Int = self.cell.totalNumberOfReplicas
    
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms](repeating: RKInPerInstanceAttributesAtoms(), count: numberOfReplicas * atoms.count)
    
    index = 0
    
    for asymetricAtom in asymmetricAtoms
    {
      let atomType: SKForceFieldType? = forceFieldSet?[asymetricAtom.uniqueForceFieldName]
      let typeIsVisible: Bool = atomType?.isVisible ?? true
      
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      
      for copy in copies
      {
        let pos: SIMD3<Double> = SIMD3<Double>.flip(v: copy.position, flip: cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
      
        for k1 in minimumReplicaX...maximumReplicaX
        {
          for k2 in minimumReplicaY...maximumReplicaY
          {
            for k3 in minimumReplicaZ...maximumReplicaZ
            {
              let fractionalPosition: SIMD3<Double> = SIMD3<Double>(x: pos.x + Double(k1), y: pos.y + Double(k2), z: pos.z + Double(k3)) + self.cell.contentShift
              let cartesianPosition: SIMD3<Double> = self.cell.convertToCartesian(fractionalPosition)
            
              let w: Double = (typeIsVisible && copy.asymmetricParentAtom.isVisible && copy.asymmetricParentAtom.isVisibleEnabled && asymetricAtom.symmetryType != .container) ? 1.0 : -1.0
              let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: Float(w))
            
              let radius: Double = copy.asymmetricParentAtom.drawRadius // * copy.asymmetricParentAtom.occupancy
              let ambient: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
              let diffuse: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
              let specular: NSColor = self.atomSpecularColor
              
              data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius), tag: UInt32(index))
              index = index + 1
            }
          }
        }
      }
    }
    return data
  }
  
  public override var renderInternalBonds: [RKInPerInstanceAttributesBonds]
  {
    var data: [RKInPerInstanceAttributesBonds] = [RKInPerInstanceAttributesBonds]()
     
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldViewer)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
      
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
      
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
      
    for (asymmetricBondIndex, asymmetricBond) in bondSetController.arrangedObjects.enumerated()
    {
      for bond in asymmetricBond.copies
      {
        if bond.boundaryType == .internal
        {
          let atom1: SKAtomCopy = bond.atom1
          let atom2: SKAtomCopy = bond.atom2
          let asymmetricAtom1: SKAsymmetricAtom = atom1.asymmetricParentAtom
          let asymmetricAtom2: SKAsymmetricAtom = atom2.asymmetricParentAtom
          
          let atomPos1 = SIMD3<Double>.flip(v: atom1.position, flip: cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
          let atomPos2 = SIMD3<Double>.flip(v: atom2.position, flip: cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
          
          let color1: NSColor = asymmetricAtom1.color
          let color2: NSColor = asymmetricAtom2.color
          
          let atomType1: SKForceFieldType? = forceFieldSet?[asymmetricAtom1.uniqueForceFieldName]
          let typeIsVisible1: Bool = atomType1?.isVisible ?? true
          let atomType2: SKForceFieldType? = forceFieldSet?[asymmetricAtom2.uniqueForceFieldName]
          let typeIsVisible2: Bool = atomType2?.isVisible ?? true
          
          for k1 in minimumReplicaX...maximumReplicaX
          {
            for k2 in minimumReplicaY...maximumReplicaY
            {
              for k3 in minimumReplicaZ...maximumReplicaZ
              {
                let pos1: SIMD3<Double> = cell.convertToCartesian(atomPos1 + SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) + self.cell.contentShift) + asymmetricAtom1.displacement
                let pos2: SIMD3<Double> = cell.convertToCartesian(atomPos2 + SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) + self.cell.contentShift) + asymmetricAtom2.displacement
                let bondLength: Double = length(pos2-pos1)
                
                let drawRadius1: Double = asymmetricAtom1.drawRadius / bondLength
                let drawRadius2: Double = asymmetricAtom2.drawRadius / bondLength
                
                let w: Double = (asymmetricBond.isVisible && typeIsVisible1 && typeIsVisible2 && (asymmetricAtom1.isVisible && asymmetricAtom2.isVisible) && (asymmetricAtom1.isVisibleEnabled && asymmetricAtom2.isVisibleEnabled)) ? 1.0 : -1.0
                data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(xyz: pos1, w: w),
                      position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: w),
                      color1: SIMD4<Float>(color: color1),
                      color2: SIMD4<Float>(color: color2),
                      scale: SIMD4<Float>(x: drawRadius1, y: 1.0, z: drawRadius2, w: drawRadius1/drawRadius2),
                      tag: UInt32(asymmetricBondIndex),
                      type: UInt32(asymmetricBond.bondType.rawValue)))
              }
            }
          }
        }
      }
    }
    return data
  }
  
  public override var renderExternalBonds: [RKInPerInstanceAttributesBonds]
  {
    var data: [RKInPerInstanceAttributesBonds] = [RKInPerInstanceAttributesBonds]()
    
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldViewer)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
    
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    for (asymmetricBondIndex, asymmetricBond) in bondSetController.arrangedObjects.enumerated()
    {
      for bond in asymmetricBond.copies
      {
        if bond.boundaryType == .external
        {
          let atom1: SKAtomCopy = bond.atom1
          let atom2: SKAtomCopy = bond.atom2
          let asymmetricAtom1: SKAsymmetricAtom = atom1.asymmetricParentAtom
          let asymmetricAtom2: SKAsymmetricAtom = atom2.asymmetricParentAtom
        
          let atomPos1 = SIMD3<Double>.flip(v: atom1.position, flip: cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
          let atomPos2 = SIMD3<Double>.flip(v: atom2.position, flip: cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
        
          let color1: NSColor = asymmetricAtom1.color
          let color2: NSColor = asymmetricAtom2.color
        
          let atomType1: SKForceFieldType? = forceFieldSet?[asymmetricAtom1.uniqueForceFieldName]
          let typeIsVisible1: Bool = atomType1?.isVisible ?? true
          let atomType2: SKForceFieldType? = forceFieldSet?[asymmetricAtom2.uniqueForceFieldName]
          let typeIsVisible2: Bool = atomType2?.isVisible ?? true
        
          for k1 in minimumReplicaX...maximumReplicaX
          {
            for k2 in minimumReplicaY...maximumReplicaY
            {
              for k3 in minimumReplicaZ...maximumReplicaZ
              {
                let frac_pos1: SIMD3<Double> = atomPos1 + SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) +  self.cell.contentShift
                let frac_pos2: SIMD3<Double> = atomPos2 + SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) + self.cell.contentShift
                var dr: SIMD3<Double> = frac_pos2 - frac_pos1
              
                // apply boundary condition
                dr.x -= rint(dr.x)
                dr.y -= rint(dr.y)
                dr.z -= rint(dr.z)
              
                let pos1: SIMD3<Double> = cell.convertToCartesian(frac_pos1) + asymmetricAtom1.displacement
                let pos2: SIMD3<Double> = cell.convertToCartesian(frac_pos2) + asymmetricAtom2.displacement
              
                dr = cell.convertToCartesian(dr)
                let bondLength: Double = length(dr)
              
                let drawRadius1: Double = asymmetricAtom1.drawRadius / bondLength;
                let drawRadius2: Double = asymmetricAtom2.drawRadius / bondLength;
              
                let w: Double = (asymmetricBond.isVisible && typeIsVisible1 && typeIsVisible2 && (asymmetricAtom1.isVisible && asymmetricAtom2.isVisible) && (asymmetricAtom1.isVisibleEnabled && asymmetricAtom2.isVisibleEnabled)) ? 1.0 : -1.0
              
                data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(xyz: pos1, w: w),
                      position2: SIMD4<Float>(x: pos1.x+dr.x, y: pos1.y+dr.y, z: pos1.z+dr.z, w: w),
                      color1: SIMD4<Float>(color: color1),
                      color2: SIMD4<Float>(color: color2),
                      scale: SIMD4<Float>(x: drawRadius1, y: 1.0, z: drawRadius2, w: drawRadius1/drawRadius2),
                      tag: UInt32(asymmetricBondIndex),
                      type: UInt32(asymmetricBond.bondType.rawValue)))
                data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(xyz: pos2, w: w),
                      position2: SIMD4<Float>(x: pos2.x-dr.x, y: pos2.y-dr.y, z: pos2.z-dr.z, w: w),
                      color1: SIMD4<Float>(color: color2),
                      color2: SIMD4<Float>(color: color1),
                      scale: SIMD4<Float>(x: drawRadius2, y: 1.0, z: drawRadius1, w: drawRadius2/drawRadius1),
                      tag: UInt32(asymmetricBondIndex),
                      type: UInt32(asymmetricBond.bondType.rawValue)))
              }
            }
          }
        }
      }
    }
    return data
  }
  
  public override var renderUnitCellSpheres: [RKInPerInstanceAttributesAtoms]
   {
     var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms]()
     
     let boundingBoxWidths: SIMD3<Double> = self.cell.boundingBox.widths
     
     let scale: Double = 0.0025 * max(boundingBoxWidths.x,boundingBoxWidths.y,boundingBoxWidths.z)
     
     for k1 in self.cell.minimumReplica.x...self.cell.maximumReplica.x+1
     {
       for k2 in self.cell.minimumReplica.y...self.cell.maximumReplica.y+1
       {
         for k3 in self.cell.minimumReplica.z...self.cell.maximumReplica.z+1
         {
           let cartesianPosition: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)))
           let spherePosition: SIMD4<Float> = SIMD4<Float>(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: 1.0)
           
           let ambient: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
           let diffuse: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
           let specular: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
           
           data.append(RKInPerInstanceAttributesAtoms(position: spherePosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(scale), tag: UInt32(0)))
         }
       }
     }
     
     return data
   }

   public override var renderUnitCellCylinders: [RKInPerInstanceAttributesBonds]
   {
     var data: [RKInPerInstanceAttributesBonds] = [RKInPerInstanceAttributesBonds]()
     
     let color1: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
     let color2: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
     
     let boundingBoxWidths: SIMD3<Double> = self.cell.boundingBox.widths
     let scale: Double = 0.0025 * max(boundingBoxWidths.x,boundingBoxWidths.y,boundingBoxWidths.z)
     
     for k1 in self.cell.minimumReplica.x...self.cell.maximumReplica.x+1
     {
       for k2 in self.cell.minimumReplica.y...self.cell.maximumReplica.y+1
       {
         for k3 in self.cell.minimumReplica.z...self.cell.maximumReplica.z+1
         {
           
           if(k1 <= self.cell.maximumReplica[0])
           {
             var cylinder: RKBondVertex = RKBondVertex()
             
             let pos1: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)))
             cylinder.position1=SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0)
             let pos2: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1+1), y: Double(k2), z: Double(k3)))
             cylinder.position2=SIMD4<Float>(x: Float(pos2.x), y: Float(pos2.y), z: Float(pos2.z), w: 1.0)
             
             data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0),
               position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: 1.0),
               color1: SIMD4<Float>(color: color1),
               color2: SIMD4<Float>(color: color2),
               scale: SIMD4<Float>(x: Float(scale), y: 1.0, z: Float(scale), w: 1.0), tag: 0, type: 0))
           }
           
           if(k2 <= self.cell.maximumReplica[1])
           {
             var cylinder: RKBondVertex = RKBondVertex()
             
             let pos1: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)))
             cylinder.position1=SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0)
             let pos2: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2+1), z: Double(k3)))
             cylinder.position2=SIMD4<Float>(x: Float(pos2.x), y: Float(pos2.y), z: Float(pos2.z), w: 1.0)
             
             data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0),
               position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: 1.0),
               color1: SIMD4<Float>(color: color1),
               color2: SIMD4<Float>(color: color2),
               scale: SIMD4<Float>(x: Float(scale), y: 1.0, z: Float(scale), w: 1.0), tag: 0, type: 0))
           }
           
           if(k3 <= self.cell.maximumReplica[2])
           {
             var cylinder: RKBondVertex = RKBondVertex()
             
             let pos1: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)))
             cylinder.position1=SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0)
             let pos2: SIMD3<Double> = cell.convertToCartesian(SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3+1)))
             cylinder.position2=SIMD4<Float>(x: Float(pos2.x), y: Float(pos2.y), z: Float(pos2.z), w: 1.0)
             
             data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0),
               position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: 1.0),
               color1: SIMD4<Float>(color: color1),
               color2: SIMD4<Float>(color: color2),
               scale: SIMD4<Float>(x: Float(scale), y: 1.0, z: Float(scale), w: 1.0), tag: 0, type: 0))
           }
         }
       }
     }
     
     return data
   }
   
  
  public override var atomTextData: [RKInPerInstanceAttributesText]
  {
    var data: [RKInPerInstanceAttributesText] = []
    
    let fontAtlas: RKFontAtlas = RKCachedFontAtlas.shared.fontAtlas(for: self.atomTextFont)
    
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    
    for asymetricAtom in asymmetricAtoms
    {
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      
      for copy in copies
      {
        let pos: SIMD3<Double> = copy.position
        
        for k1 in minimumReplicaX...maximumReplicaX
        {
          for k2 in minimumReplicaY...maximumReplicaY
          {
            for k3 in minimumReplicaZ...maximumReplicaZ
            {
              let fractionalPosition: SIMD3<Double> = SIMD3<Double>(x: pos.x + Double(k1), y: pos.y + Double(k2), z: pos.z + Double(k3)) + self.cell.contentShift
              let cartesianPosition: SIMD3<Double> = self.cell.convertToCartesian(fractionalPosition)
              
              
              
              let w: Double = (copy.asymmetricParentAtom.isVisible && copy.asymmetricParentAtom.isVisibleEnabled) ? 1.0 : -1.0
              let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: Float(w))
              let radius: Float = Float(copy.asymmetricParentAtom.drawRadius)
              
              let text: String
              switch(atomTextType)
              {
              case .none:
                text = ""
              case .displayName:
                text = String(copy.asymmetricParentAtom.displayName)
              case .identifier:
                text = String(copy.tag)
              case .chemicalElement:
                text = PredefinedElements.sharedInstance.elementSet[copy.asymmetricParentAtom.elementIdentifier].chemicalSymbol
              case .forceFieldType:
                text = copy.asymmetricParentAtom.uniqueForceFieldName
              case .position:
                text = String("(\(copy.position.x),\(copy.position.y),\(copy.position.z))")
              case .charge:
                text = String(copy.asymmetricParentAtom.charge)
              }
              
              let instances = fontAtlas.buildMeshWithString(position: atomPosition, scale: SIMD4<Float>(radius,radius,radius,1.0), text: text, alignment: self.atomTextAlignment)
              
              data += instances
            }
          }
        }
      }
    }
    
    return data
  }
  
  // MARK: Rendering selection
  // =====================================================================
  
  public override var renderSelectedAtoms: [RKInPerInstanceAttributesAtoms]
  {
    var index: Int
    
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldViewer)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
    
    let numberOfReplicas: Int = self.cell.totalNumberOfReplicas
    
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.allSelectedNodes.compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}
    
    
    var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms](repeating: RKInPerInstanceAttributesAtoms(), count: numberOfReplicas * atoms.count)
    
    index = 0
    
    for (asymetricIndex, asymetricAtom) in asymmetricAtoms.enumerated()
    {
      let atomType: SKForceFieldType? = forceFieldSet?[asymetricAtom.uniqueForceFieldName]
      let typeIsVisible: Bool = atomType?.isVisible ?? true
      
      let displacement = self.cell.convertToFractional(asymetricAtom.displacement)
      
      let images: [SIMD3<Double>] = [asymetricAtom.position + displacement]
      for image in images
      {
        
        let pos: SIMD3<Double> = SIMD3<Double>.flip(v: fract(image), flip: cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
        
        for k1 in minimumReplicaX...maximumReplicaX
        {
          for k2 in minimumReplicaY...maximumReplicaY
          {
            for k3 in minimumReplicaZ...maximumReplicaZ
            {
              let fractionalPosition: SIMD3<Double> = SIMD3<Double>(x: pos.x + Double(k1), y: pos.y + Double(k2), z: pos.z + Double(k3)) + self.cell.contentShift
              let cartesianPosition: SIMD3<Double> = self.cell.convertToCartesian(fractionalPosition)
              
              let w: Double = (typeIsVisible && asymetricAtom.isVisible && asymetricAtom.isVisibleEnabled && asymetricAtom.symmetryType != .container) ? 1.0 : -1.0
              let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: Float(w))
              
              let radius: Double = asymetricAtom.drawRadius //* asymetricAtom.occupancy
              let ambient: NSColor = asymetricAtom.color
              let diffuse: NSColor = asymetricAtom.color
              let specular: NSColor = self.atomSpecularColor
              
              data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius), tag: UInt32(asymetricIndex))
              index = index + 1
            }
          }
        }
      }
    }
    return data
  }
  
  
  public override var renderSelectedInternalBonds: [RKInPerInstanceAttributesBonds]
  {
    var data: [RKInPerInstanceAttributesBonds] = []
     
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldViewer)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
      
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
      
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
      
    let selectedAsymmetricBonds: [SKAsymmetricBond] = self.bondSetController.arrangedObjects[self.bondSetController.selectedObjects]
    for (asymmetricBondIndex, asymmetricBond) in selectedAsymmetricBonds.enumerated()
    {
      for bond in asymmetricBond.copies
      {
        if bond.boundaryType == .internal
        {
          let atom1: SKAtomCopy = bond.atom1
          let atom2: SKAtomCopy = bond.atom2
          let asymmetricAtom1: SKAsymmetricAtom = atom1.asymmetricParentAtom
          let asymmetricAtom2: SKAsymmetricAtom = atom2.asymmetricParentAtom
          
          let atomPos1 = SIMD3<Double>.flip(v: atom1.position, flip: cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
          let atomPos2 = SIMD3<Double>.flip(v: atom2.position, flip: cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
          
          let color1: NSColor = asymmetricAtom1.color
          let color2: NSColor = asymmetricAtom2.color
          
          let atomType1: SKForceFieldType? = forceFieldSet?[asymmetricAtom1.uniqueForceFieldName]
          let typeIsVisible1: Bool = atomType1?.isVisible ?? true
          let atomType2: SKForceFieldType? = forceFieldSet?[asymmetricAtom2.uniqueForceFieldName]
          let typeIsVisible2: Bool = atomType2?.isVisible ?? true
          
          for k1 in minimumReplicaX...maximumReplicaX
          {
            for k2 in minimumReplicaY...maximumReplicaY
            {
              for k3 in minimumReplicaZ...maximumReplicaZ
              {
                let pos1: SIMD3<Double> = cell.convertToCartesian(atomPos1 + SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) + self.cell.contentShift) + asymmetricAtom1.displacement
                let pos2: SIMD3<Double> = cell.convertToCartesian(atomPos2 + SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) + self.cell.contentShift) + asymmetricAtom2.displacement
                let bondLength: Double = length(pos2-pos1)
                
                let drawRadius1: Double = asymmetricAtom1.drawRadius / bondLength
                let drawRadius2: Double = asymmetricAtom2.drawRadius / bondLength
                
                let w: Double = (asymmetricBond.isVisible && typeIsVisible1 && typeIsVisible2 && (asymmetricAtom1.isVisible && asymmetricAtom2.isVisible) && (asymmetricAtom1.isVisibleEnabled && asymmetricAtom2.isVisibleEnabled)) ? 1.0 : -1.0
                data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(xyz: pos1, w: w),
                      position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: w),
                      color1: SIMD4<Float>(color: color1),
                      color2: SIMD4<Float>(color: color2),
                      scale: SIMD4<Float>(x: drawRadius1, y: 1.0, z: drawRadius2, w: drawRadius1/drawRadius2),
                      tag: UInt32(asymmetricBondIndex),
                      type: UInt32(asymmetricBond.bondType.rawValue)))
              }
            }
          }
        }
      }
    }
    return data
  }
  
  public override var renderSelectedExternalBonds: [RKInPerInstanceAttributesBonds]
  {
    var data: [RKInPerInstanceAttributesBonds] = []
    
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldViewer)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
    
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    for asymmetricBondIndex in self.bondSetController.selectedObjects
    {
      let asymmetricBond = self.bondSetController.arrangedObjects[asymmetricBondIndex]
      for bond in asymmetricBond.copies
      {
        if bond.boundaryType == .external
        {
          let atom1: SKAtomCopy = bond.atom1
          let atom2: SKAtomCopy = bond.atom2
          let asymmetricAtom1: SKAsymmetricAtom = atom1.asymmetricParentAtom
          let asymmetricAtom2: SKAsymmetricAtom = atom2.asymmetricParentAtom
        
          let atomPos1 = SIMD3<Double>.flip(v: atom1.position, flip: cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
          let atomPos2 = SIMD3<Double>.flip(v: atom2.position, flip: cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
        
          let color1: NSColor = asymmetricAtom1.color
          let color2: NSColor = asymmetricAtom2.color
        
          let atomType1: SKForceFieldType? = forceFieldSet?[asymmetricAtom1.uniqueForceFieldName]
          let typeIsVisible1: Bool = atomType1?.isVisible ?? true
          let atomType2: SKForceFieldType? = forceFieldSet?[asymmetricAtom2.uniqueForceFieldName]
          let typeIsVisible2: Bool = atomType2?.isVisible ?? true
        
          for k1 in minimumReplicaX...maximumReplicaX
          {
            for k2 in minimumReplicaY...maximumReplicaY
            {
              for k3 in minimumReplicaZ...maximumReplicaZ
              {
                let frac_pos1: SIMD3<Double> = atomPos1 + SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) +  self.cell.contentShift
                let frac_pos2: SIMD3<Double> = atomPos2 + SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) + self.cell.contentShift
                var dr: SIMD3<Double> = frac_pos2 - frac_pos1
              
                // apply boundary condition
                dr.x -= rint(dr.x)
                dr.y -= rint(dr.y)
                dr.z -= rint(dr.z)
              
                let pos1: SIMD3<Double> = cell.convertToCartesian(frac_pos1) + asymmetricAtom1.displacement
                let pos2: SIMD3<Double> = cell.convertToCartesian(frac_pos2) + asymmetricAtom2.displacement
              
                dr = cell.convertToCartesian(dr)
                let bondLength: Double = length(dr)
              
                let drawRadius1: Double = asymmetricAtom1.drawRadius / bondLength;
                let drawRadius2: Double = asymmetricAtom2.drawRadius / bondLength;
              
                let w: Double = (asymmetricBond.isVisible && typeIsVisible1 && typeIsVisible2 && (asymmetricAtom1.isVisible && asymmetricAtom2.isVisible) && (asymmetricAtom1.isVisibleEnabled && asymmetricAtom2.isVisibleEnabled)) ? 1.0 : -1.0
              
                data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(xyz: pos1, w: w),
                      position2: SIMD4<Float>(x: pos1.x+dr.x, y: pos1.y+dr.y, z: pos1.z+dr.z, w: w),
                      color1: SIMD4<Float>(color: color1),
                      color2: SIMD4<Float>(color: color2),
                      scale: SIMD4<Float>(x: drawRadius1, y: 1.0, z: drawRadius2, w: drawRadius1/drawRadius2),
                      tag: UInt32(asymmetricBondIndex),
                      type: UInt32(asymmetricBond.bondType.rawValue)))
                data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(xyz: pos2, w: w),
                      position2: SIMD4<Float>(x: pos2.x-dr.x, y: pos2.y-dr.y, z: pos2.z-dr.z, w: w),
                      color1: SIMD4<Float>(color: color2),
                      color2: SIMD4<Float>(color: color1),
                      scale: SIMD4<Float>(x: drawRadius2, y: 1.0, z: drawRadius1, w: drawRadius2/drawRadius1),
                      tag: UInt32(asymmetricBondIndex),
                      type: UInt32(asymmetricBond.bondType.rawValue)))
              }
            }
          }
        }
      }
    }
    return data
  }
  
  
  // MARK: -
  // MARK: Filtering

  public override func filterCartesianAtomPositions(_ filter: (SIMD3<Double>) -> Bool) -> IndexSet
  {
    
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldViewer)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
      
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    
    var data: IndexSet = IndexSet()
    
    let rotationMatrix: double4x4 =  double4x4(transformation: double4x4(simd_quatd: self.orientation), aroundPoint: self.cell.boundingBox.center)
    for (asymetricIndex, asymetricAtom) in asymmetricAtoms.enumerated()
    {
      let atomType: SKForceFieldType? = forceFieldSet?[asymetricAtom.uniqueForceFieldName]
      let typeIsVisible: Bool = atomType?.isVisible ?? true
      
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      
      for copy in copies
      {
        let pos: SIMD3<Double> = SIMD3<Double>.flip(v: copy.position, flip: cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
      
        for k1 in minimumReplicaX...maximumReplicaX
        {
          for k2 in minimumReplicaY...maximumReplicaY
          {
            for k3 in minimumReplicaZ...maximumReplicaZ
            {
              let fractionalPosition: SIMD3<Double> = SIMD3<Double>(x: pos.x + Double(k1), y: pos.y + Double(k2), z: pos.z + Double(k3)) + self.cell.contentShift
              let cartesianPosition: SIMD3<Double> = self.cell.convertToCartesian(fractionalPosition)
            
              let position: SIMD4<Double> = rotationMatrix * SIMD4<Double>(x: cartesianPosition.x, y: cartesianPosition.y, z: cartesianPosition.z, w: 1.0)
              let absoluteCartesianPosition: SIMD3<Double> = SIMD3<Double>(position.x,position.y,position.z) + origin
            
              if filter(absoluteCartesianPosition) && (typeIsVisible && asymetricAtom.isVisible && asymetricAtom.isVisibleEnabled)
              {
                data.insert(asymetricIndex)
              }
            }
          }
        }
      }
    }
    return data
  }
  
  public override func filterCartesianBondPositions(_ filter: (SIMD3<Double>) -> Bool) -> IndexSet
  {
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldViewer)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
        
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    var data: IndexSet = IndexSet()
    
    let rotationMatrix: double4x4 =  double4x4(transformation: double4x4(simd_quatd: self.orientation), aroundPoint: self.cell.boundingBox.center)
    let asymmetricBonds: [SKAsymmetricBond] = self.bondSetController.arrangedObjects
    for (asymmetricBondIndex, asymmetricBond) in asymmetricBonds.enumerated()
    {
      for bond in asymmetricBond.copies
      {
        let atom1: SKAtomCopy = bond.atom1
        let atom2: SKAtomCopy = bond.atom2
        let asymmetricAtom1: SKAsymmetricAtom = atom1.asymmetricParentAtom
        let asymmetricAtom2: SKAsymmetricAtom = atom2.asymmetricParentAtom
        
        let atomPos1 = SIMD3<Double>.flip(v: atom1.position, flip: cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
        let atomPos2 = SIMD3<Double>.flip(v: atom2.position, flip: cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
        
        let atomType1: SKForceFieldType? = forceFieldSet?[asymmetricAtom1.uniqueForceFieldName]
        let typeIsVisible1: Bool = atomType1?.isVisible ?? true
        let atomType2: SKForceFieldType? = forceFieldSet?[asymmetricAtom2.uniqueForceFieldName]
        let typeIsVisible2: Bool = atomType2?.isVisible ?? true
        
        let visible: Bool = (asymmetricBond.isVisible && typeIsVisible1 && typeIsVisible2 && (asymmetricAtom1.isVisible && asymmetricAtom2.isVisible) && (asymmetricAtom1.isVisibleEnabled && asymmetricAtom2.isVisibleEnabled))
          
        if visible
        {
          for k1 in minimumReplicaX...maximumReplicaX
          {
            for k2 in minimumReplicaY...maximumReplicaY
            {
              for k3 in minimumReplicaZ...maximumReplicaZ
              {
                let frac_pos1: SIMD3<Double> = atomPos1 + SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) + self.cell.contentShift
                let frac_pos2: SIMD3<Double> = atomPos2 + SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) + self.cell.contentShift
                var dr: SIMD3<Double> = frac_pos2 - frac_pos1
              
                // apply boundary condition
                dr.x -= rint(dr.x)
                dr.y -= rint(dr.y)
                dr.z -= rint(dr.z)
              
                let pos1: SIMD3<Double> = cell.convertToCartesian(frac_pos1) + asymmetricAtom1.displacement
                let pos2: SIMD3<Double> = cell.convertToCartesian(frac_pos2) + asymmetricAtom2.displacement
                dr = cell.convertToCartesian(dr)
                    
                let cartesianPosition1 = pos1 + 0.5 * dr
                let position1: SIMD4<Double> = rotationMatrix * SIMD4<Double>(x: cartesianPosition1.x, y: cartesianPosition1.y, z: cartesianPosition1.z, w: 1.0)
                let absoluteCartesianPosition1: SIMD3<Double> = SIMD3<Double>(position1.x,position1.y,position1.z) + origin
                if (filter(absoluteCartesianPosition1))
                {
                  data.insert(asymmetricBondIndex)
                }
                
                let cartesianPosition2 = pos2 - 0.5 * dr
                let position2: SIMD4<Double> = rotationMatrix * SIMD4<Double>(x: cartesianPosition2.x, y: cartesianPosition2.y, z: cartesianPosition2.z, w: 1.0)
                let absoluteCartesianPosition2: SIMD3<Double> = SIMD3<Double>(position2.x,position2.y,position2.z) + origin
                if (filter(absoluteCartesianPosition2))
                {
                  data.insert(asymmetricBondIndex)
                }
                
              }
            }
          }
        }
      }
    }
    return data
  }
  


  // MARK: -
  // MARK: Compute bonds
  
  public override func reComputeBonds()
  {
    let atomList: [SKAtomCopy] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    self.bondSetController.bonds = self.computeBonds(cell: self.cell, atomList: atomList, cancelHandler: {return false}, updateHandler: {})
  }
  
  public override func reComputeBonds(_ node: ProjectTreeNode, cancelHandler: (()-> Bool), updateHandler: (() -> ()))
  {
    let atomList: [SKAtomCopy] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    self.bondSetController.bonds = self.computeBonds(cell: self.cell, atomList: atomList, cancelHandler: cancelHandler, updateHandler: updateHandler)
  }
  
  public override func computeBonds(cancelHandler: (()-> Bool) = {return false}, updateHandler: (() -> ()) = {}) -> [SKBondNode]
  {
    let atomList: [SKAtomCopy] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    return self.computeBonds(cell: self.cell, atomList: atomList, cancelHandler: cancelHandler, updateHandler: updateHandler)
  }
  
  public override func computeBonds(cell structureCell: SKCell, atomList atoms: [SKAtomCopy], cancelHandler: (()-> Bool) = {return false}, updateHandler: (() -> ()) = {}) -> [SKBondNode]
  {
    let cutoff: Double = 3.0
    let offsets: [[Int]] = [[0,0,0],[1,0,0],[1,1,0],[0,1,0],[-1,1,0],[0,0,1],[1,0,1],[1,1,1],[0,1,1],[-1,1,1],[-1,0,1],[-1,-1,1],[0,-1,1],[1,-1,1]]
    
    var computedBonds: [SKBondNode] = []
    var totalCount: Int
    
    let perpendicularWidths: SIMD3<Double> = structureCell.perpendicularWidths
    guard perpendicularWidths.x > 0.0001 && perpendicularWidths.x > 0.0001 && perpendicularWidths.x > 0.0001 else {return []}
        
    let numberOfCells: [Int] = [Int(perpendicularWidths.x/cutoff),Int(perpendicularWidths.y/cutoff),Int(perpendicularWidths.z/cutoff)]
    let totalNumberOfCells: Int = numberOfCells[0] * numberOfCells[1] * numberOfCells[2]
    
    if (numberOfCells[0]>=3 && numberOfCells[1]>=3 && numberOfCells[2]>=3)
    {
      let epsilon: Double = 1e-4
      let cutoffVector: SIMD3<Double> = SIMD3<Double>(x: epsilon+perpendicularWidths.x/Double(numberOfCells[0]), y: epsilon+perpendicularWidths.y/Double(numberOfCells[1]), z: epsilon+perpendicularWidths.z/Double(numberOfCells[2]))
      
      var head: [Int] = [Int](repeating: -1, count: totalNumberOfCells)
      var list: [Int] = [Int](repeating: -1, count: atoms.count)
      
      // create cell-list based on the bond-cutoff
      for i in 0..<atoms.count
      {
        atoms[i].type = .copy
        
        let position: SIMD3<Double> = perpendicularWidths * fract(atoms[i].position)
        
        let icell: Int = Int((position.x) / cutoffVector.x) +
                   Int((position.y) / cutoffVector.y) * numberOfCells[0] +
                   Int((position.z) / cutoffVector.z) * numberOfCells[1] * numberOfCells[0]
        
        list[i] = head[icell]
        head[icell] = i
      }
      
      totalCount = numberOfCells[0] * numberOfCells[1] * numberOfCells[2]
      
      let bondProgress: Progress = Progress(totalUnitCount: Int64(totalCount))
      bondProgress.completedUnitCount = 0
      
      for k1 in 0..<numberOfCells[0]
      {
        for k2 in 0..<numberOfCells[1]
        {
          for k3 in 0..<numberOfCells[2]
          {
            let icell_i: Int = k1 + k2 * numberOfCells[0] + k3 * numberOfCells[1] * numberOfCells[0]
            
            var i: Int = head[icell_i]
            while(i >= 0)
            {
              let posA: SIMD3<Double> = structureCell.convertToCartesian(atoms[i].position)
              
              // loop over neighboring cells
              for offset in offsets
              {
                let off: [Int] = [(k1 + offset[0]+numberOfCells[0]) % numberOfCells[0],
                                  (k2 + offset[1]+numberOfCells[1]) % numberOfCells[1],
                                  (k3 + offset[2]+numberOfCells[2]) % numberOfCells[2]]
                let icell_j: Int = off[0] + off[1] * numberOfCells[0] + off[2] * numberOfCells[1] * numberOfCells[0]
                
                var j: Int = head[icell_j]
                while(j >= 0)
                {
                  if((i < j) || (icell_i != icell_j))
                  {
                    let posB: SIMD3<Double> = structureCell.convertToCartesian(atoms[j].position)
                    let separationVector: SIMD3<Double> = posA - posB
                    let periodicSeparationVector: SIMD3<Double> = structureCell.applyUnitCellBoundaryCondition(separationVector)
                    
                    let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
                    
                    let bondLength: Double = length(periodicSeparationVector)
                    if (bondLength < bondCriteria)
                    {
                      // Type atom as 'Double'
                      if (bondLength < 0.1)
                      {
                        // a duplicate when: (a) both occupancies are 1.0, or (b) when they are the same asymmetric type
                        if(!(atoms[i].asymmetricParentAtom.occupancy < 1.0 || atoms[j].asymmetricParentAtom.occupancy < 1.0) || (atoms[i].asymmetricIndex == atoms[j].asymmetricIndex))
                        {
                          atoms[i].type = .duplicate
                        }
                      }
                      else if (length(separationVector) > bondCriteria)
                      {
                        let bond: SKBondNode = SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .external)
                        computedBonds.append(bond)
                      }
                      else
                      {
                        let bond: SKBondNode = SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .internal)
                        computedBonds.append(bond)
                      }
                    }
                  }
                  j=list[j]
                }
              }
              i=list[i]
            }
            
            bondProgress.completedUnitCount += 1
            
            if (bondProgress.completedUnitCount % 100 == 0)
            {
              updateHandler()
            }
            if cancelHandler()
            {
              return []
            }
          }
        }
      }
    }
    else
    {
      let bondProgress: Progress = Progress(totalUnitCount: Int64(atoms.count))
      bondProgress.completedUnitCount = 0
      
      for i in 0..<atoms.count
      {
        atoms[i].type = .copy
        
        let posA: SIMD3<Double> = structureCell.convertToCartesian(atoms[i].position)
        
        for j in i+1..<atoms.count
        {
          let posB: SIMD3<Double> = structureCell.convertToCartesian(atoms[j].position)
          
          let separationVector: SIMD3<Double> = posA - posB
          let periodicSeparationVector: SIMD3<Double> = structureCell.applyUnitCellBoundaryCondition(separationVector)
          
          let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
          
          let bondLength: Double = length(periodicSeparationVector)
          if (bondLength < bondCriteria)
          {
            // Type atom as 'Double'
            if (bondLength < 0.1)
            {
              // a duplicate when: (a) both occupancies are 1.0, or (b) when they are the same asymmetric type
              if(!(atoms[i].asymmetricParentAtom.occupancy < 1.0 || atoms[j].asymmetricParentAtom.occupancy < 1.0) || (atoms[i].asymmetricIndex == atoms[j].asymmetricIndex))
              {
                atoms[i].type = .duplicate
              }
            }
            else if (length(separationVector) > bondCriteria )
            {
              let bond: SKBondNode = SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .external)
              computedBonds.append(bond)
            }
            else
            {
              let bond: SKBondNode = SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .internal)
              computedBonds.append(bond)
            }
          }
        }
        
        bondProgress.completedUnitCount += 1
        
        if (bondProgress.completedUnitCount % 100 == 0)
        {
          updateHandler()
        }
        if cancelHandler()
        {
          return []
        }
      }
    }
    
    return computedBonds.filter{$0.atom1.type == .copy && $0.atom2.type == .copy}
  }
  
  public override func computeBondsOperation(structure: Structure, windowController: NSWindowController?) -> FKOperation?
  {
    return GaussianCubeVolumetricData.RecomputeBondsOperation(structure: structure, windowController: windowController)
  }
  
  public class RecomputeBondsOperation: FKOperation
  {
    let structure : Structure
    weak var windowController: NSWindowController? = nil
    
    public init(structure: Structure, windowController: NSWindowController?)
    {
      self.windowController = windowController
      self.structure = structure
      super.init()
      
      // Do this in init, so that our NSProgress instance is parented to the current one in the thread that created the operation
      // This progress's children are weighted, the reading takes 10% and the computation of the bonds takes the remaining portion
      // create a new Progress-object (Progress-objects can not be resused)
      progress = Progress.discreteProgress(totalUnitCount: 10)
      progress.completedUnitCount = 0
    }
    
    
    public override func execute()
    {
      let atoms: [SKAtomCopy] = structure.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
      //atoms.forEach({$0.bonds.removeAll()})
      let computedBonds = structure.computeBonds(cell: structure.cell, atomList: atoms)
      
      LogQueue.shared.info(destination: windowController, message: "start computing bonds: \(structure.displayName)")
      
      structure.bondSetController.bonds = Array(computedBonds)
      structure.recomputeDensityProperties()
      
      let numberOfComputedBonds: Int =  computedBonds.filter{$0.atom1.type == .copy && $0.atom2.type == .copy}.count
      LogQueue.shared.info(destination: windowController, message: "number of bonds: \(structure.displayName) = \(numberOfComputedBonds)")
      
      self.progress.totalUnitCount = 10
      
      finishWithError(nil)
    }
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public override func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(GaussianCubeVolumetricData.classVersionNumber)
    
    encoder.encode(self.dimensions)
    encoder.encode(self.spacing)
    encoder.encode(self.range.0)
    encoder.encode(self.range.1)
    encoder.encode(self.data)
    encoder.encode(self.average)
    encoder.encode(self.variance)
   
    encoder.encode(Int(0x6f6b6199))
    
    super.binaryEncode(to: encoder)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > GaussianCubeVolumetricData.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    dimensions = try decoder.decode(SIMD3<Int32>.self)
    spacing = try decoder.decode(SIMD3<Double>.self)
    let range_low = try decoder.decode(Double.self)
    let range_high = try decoder.decode(Double.self)
    self.range = (range_low, range_high)
    data = try decoder.decode(Data.self)
    self.average = try decoder.decode(Double.self)
    self.variance = try decoder.decode(Double.self)
    
    let magicNumber = try decoder.decode(Int.self)
    if magicNumber != Int(0x6f6b6199)
    {
      throw BinaryDecodableError.invalidMagicNumber
    }
    
    try super.init(fromBinary: decoder)
  }
}
