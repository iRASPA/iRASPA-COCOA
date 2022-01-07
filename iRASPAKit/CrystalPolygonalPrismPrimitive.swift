/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
import SymmetryKit
import BinaryCodable
import simd

public final class CrystalPolygonalPrismPrimitive: Primitive, UnitCellEditor, RKRenderCrystalPolygonalPrismObjectsSource, RKRenderUnitCellSource, Cloning
{
  private static var classVersionNumber: Int = 2
  
  public override var materialType: Object.ObjectType
  {
    return .crystalPolygonalPrismPrimitive
  }
  
  public override init(name: String)
  {
    super.init(name: name)
    let displayName: String = "center"
    let color: NSColor = NSColor.yellow
    let drawRadius: Double = 5.0
    let bondDistanceCriteria: Double = 0.0
    let asymmetricAtom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: displayName, elementId:  0, uniqueForceFieldName: displayName, position: SIMD3<Double>(0,0,0), charge: 0.0, color: color, drawRadius: drawRadius, bondDistanceCriteria: bondDistanceCriteria, occupancy: 1.0)
    self.expandSymmetry(asymmetricAtom: asymmetricAtom)
    let atomTreeNode: SKAtomTreeNode = SKAtomTreeNode(representedObject: asymmetricAtom)
    atomTreeController.insertNode(atomTreeNode, inItem: nil, atIndex: 0)
    
    drawUnitCell = true
    reComputeBoundingBox()
  }
  
  public required init(copy crystalPolygonalPrismPrimitive: CrystalPolygonalPrismPrimitive)
  {
    super.init(copy: crystalPolygonalPrismPrimitive)
  }
  
  public required init(clone crystalPolygonalPrismPrimitive: CrystalPolygonalPrismPrimitive)
  {
    super.init(clone: crystalPolygonalPrismPrimitive)
  }
  
  public required init(from object: Object)
  {
    super.init(from: object)
  }
  
  
  // MARK: Rendering
  // =====================================================================
   
  public var renderCrystalPolygonalPrismObjects: [RKInPerInstanceAttributesAtoms]
  {
    var index: Int
    
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
              let fractionalPosition: SIMD3<Double> = SIMD3<Double>(x: pos.x + Double(k1), y: pos.y + Double(k2), z: pos.z + Double(k3))
              let cartesianPosition: SIMD3<Double> = self.cell.convertToCartesian(fractionalPosition)
              
              let w: Double = (copy.asymmetricParentAtom.isVisible && copy.asymmetricParentAtom.isVisibleEnabled && asymetricAtom.symmetryType != .container) ? 1.0 : -1.0
              let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: Float(w))
              
              let radius: Double = 1.0
              let ambient: NSColor = NSColor.white
              let diffuse: NSColor = NSColor.white
              let specular: NSColor = NSColor.white
              
              data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius), tag: UInt32(index))
              index = index + 1
            }
          }
        }
      }
    }
    return data
  }
  
  // MARK: Rendering selection
  // =====================================================================
  
  public var renderSelectedCrystalPolygonalPrismObjects: [RKInPerInstanceAttributesAtoms]
  {
    var index: Int
    
    let numberOfReplicas: Int = self.cell.totalNumberOfReplicas
    
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.allSelectedNodes.compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms](repeating: RKInPerInstanceAttributesAtoms(), count: numberOfReplicas * atoms.count)
    
    index = 0
    
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
              let fractionalPosition: SIMD3<Double> = SIMD3<Double>(x: pos.x + Double(k1), y: pos.y + Double(k2), z: pos.z + Double(k3))
              let cartesianPosition: SIMD3<Double> = self.cell.convertToCartesian(fractionalPosition)
              
              let w: Double = (copy.asymmetricParentAtom.isVisible && copy.asymmetricParentAtom.isVisibleEnabled && asymetricAtom.symmetryType != .container) ? 1.0 : -1.0
              let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: Float(w))
              
              let radius: Double = 1.0
              let ambient: NSColor = NSColor.white
              let diffuse: NSColor = NSColor.white
              let specular: NSColor = NSColor.white
              
              data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius), tag: UInt32(copy.asymmetricIndex))
              index = index + 1
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
      let typeIsVisible: Bool = asymetricAtom.isVisible
      
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
  
  // MARK: -
  // MARK: Translation and rotation operations
  
  public override func centerOfMassOfSelection(atoms: [SKAtomCopy]) -> SIMD3<Double>
  {
    var centerOfMassCosTheta: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.0)
    var centerOfMassSinTheta: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.0)
    var M: Double = 0.0
    
    for atom in atoms
    {
      let mass: Double = 1.0
      let pos: SIMD3<Double> = atom.position * 2.0 * Double.pi
      let cosTheta: SIMD3<Double> = SIMD3<Double>(cos(pos.x), cos(pos.y), cos(pos.z))
      let sinTheta: SIMD3<Double> = SIMD3<Double>(sin(pos.x), sin(pos.y), sin(pos.z))
      centerOfMassCosTheta += mass * cosTheta
      centerOfMassSinTheta += mass * sinTheta
      M += mass
    }
    centerOfMassCosTheta /= M
    centerOfMassSinTheta /= M
    
    let com = SIMD3<Double>((atan2(-centerOfMassSinTheta.x, -centerOfMassCosTheta.x) + Double.pi)/(2.0 * Double.pi),
                      (atan2(-centerOfMassSinTheta.y, -centerOfMassCosTheta.y) + Double.pi)/(2.0 * Double.pi),
                      (atan2(-centerOfMassSinTheta.z, -centerOfMassCosTheta.z) + Double.pi)/(2.0 * Double.pi))
    
    return  self.cell.convertToCartesian(com)
  }
  
  public override func matrixOfInertia(atoms: [SKAtomCopy]) -> double3x3
  {
    var inertiaMatrix: double3x3 = double3x3()
    let com: SIMD3<Double> = self.centerOfMassOfSelection(atoms: atoms)
    let fracCom: SIMD3<Double> = self.cell.convertToFractional(com)
    
    for atom in atoms
    {
      let mass: Double = 1.0
      var ds: SIMD3<Double> = atom.position - fracCom
      ds -= floor(ds + SIMD3<Double>(0.5,0.5,0.5))
      let dr: SIMD3<Double> = self.cell.convertToCartesian(ds)
      inertiaMatrix[0][0] += mass * (dr.y * dr.y + dr.z * dr.z)
      inertiaMatrix[0][1] -= mass * dr.x * dr.y
      inertiaMatrix[0][2] -= mass * dr.x * dr.z
      inertiaMatrix[1][0] -= mass * dr.y * dr.x
      inertiaMatrix[1][1] += mass * (dr.x * dr.x + dr.z * dr.z)
      inertiaMatrix[1][2] -= mass * dr.y * dr.z
      inertiaMatrix[2][0] -= mass * dr.z * dr.x
      inertiaMatrix[2][1] -= mass * dr.z * dr.y
      inertiaMatrix[2][2] += mass * (dr.x * dr.x + dr.y * dr.y)
    }
    
    return inertiaMatrix
  }
  
  
  // MARK: -
  // MARK: Translation operations
  
  public override func translatedPositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by translation: SIMD3<Double>) -> [SIMD3<Double>]
  {
    let fractionalTranslation: SIMD3<Double> = self.cell.convertToFractional(translation)
    return atoms.map{$0.position + fractionalTranslation}
  }
  
  public override func translatedBodyFramePositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by shift: SIMD3<Double>) -> [SIMD3<Double>]
  {
    let basis: double3x3 = self.selectionBodyFixedBasis
    let translation: SIMD3<Double> = basis.inverse * shift
    let fractionalTranslation: SIMD3<Double> = self.cell.convertToFractional(translation)
    
    return atoms.map{$0.position + fractionalTranslation}
  }
  
  // MARK: -
  // MARK: Rotation operations
  
  public override func rotatedPositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by quaternion: simd_quatd) -> [SIMD3<Double>]
  {
    let copies: [SKAtomCopy] = atoms.flatMap{$0.copies}.filter{$0.type == .copy}
    let com: SIMD3<Double> = self.centerOfMassOfSelection(atoms: copies)
    let comFrac: SIMD3<Double> = self.cell.convertToFractional(com)
    let rotationMatrix: double3x3 = double3x3(quaternion)
    
    return atoms.map({
      var ds: SIMD3<Double> = fract($0.position) - comFrac
      ds -= floor(ds + SIMD3<Double>(0.5,0.5,0.5))
      let translatedPositionCartesian: SIMD3<Double> = self.cell.convertToCartesian(ds)
      let position: SIMD3<Double> = rotationMatrix * translatedPositionCartesian
      return fract(self.cell.convertToFractional(position) + comFrac)})
  }
  
  public override func rotatedBodyFramePositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by quaternion: simd_quatd) -> [SIMD3<Double>]
  {
    let copies: [SKAtomCopy] = atoms.flatMap{$0.copies}.filter{$0.type == .copy}
    let com: SIMD3<Double> = self.centerOfMassOfSelection(atoms: copies)
    let comFrac: SIMD3<Double> = self.cell.convertToFractional(com)
    let basis: double3x3 = self.selectionBodyFixedBasis
    let rotationMatrix = basis * double3x3(quaternion) * basis.inverse
    
    return atoms.map({
      var ds: SIMD3<Double> = fract($0.position) - comFrac
      ds -= floor(ds + SIMD3<Double>(0.5,0.5,0.5))
      let translatedPositionCartesian: SIMD3<Double> = self.cell.convertToCartesian(ds)
      let position: SIMD3<Double> = rotationMatrix * translatedPositionCartesian
      return  fract(self.cell.convertToFractional(position) + comFrac)
    })
  }
  
  // MARK: -
  // MARK: cell property-wrapper
  
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
  
  public override var periodic: Bool
  {
    get
    {
      return true
    }
    set(newValue)
    {
      super.periodic = newValue
    }
  }
  
  // MARK: Measuring distance, angle, and dihedral-angles
  // =====================================================================
  
  // Used in the routine to measure distances and bend/dihedral angles
  override public func absoluteCartesianModelPosition(for position: SIMD3<Double>, replicaPosition: SIMD3<Int32>) -> SIMD3<Double>
  {
    let pos: SIMD3<Double> = SIMD3<Double>.flip(v: position, flip: self.cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
    let fractionalPosition: SIMD3<Double> = SIMD3<Double>(x: pos.x + Double(replicaPosition.x), y: pos.y + Double(replicaPosition.y), z: pos.z + Double(replicaPosition.z)) + self.cell.contentShift
    let cartesianPosition: SIMD3<Double> = self.cell.convertToCartesian(fractionalPosition)
    return cartesianPosition
  }
  
  // Used in the routine to measure distances and bend/dihedral angles
  override public func absoluteCartesianScenePosition(for position: SIMD3<Double>, replicaPosition: SIMD3<Int32>) -> SIMD3<Double>
  {
    let rotationMatrix: double4x4 =  double4x4(transformation: double4x4(simd_quatd: self.orientation), aroundPoint: self.cell.boundingBox.center)
    let pos: SIMD3<Double> = SIMD3<Double>.flip(v: position, flip: self.cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
    let fractionalPosition: SIMD3<Double> = SIMD3<Double>(x: pos.x + Double(replicaPosition.x), y: pos.y + Double(replicaPosition.y), z: pos.z + Double(replicaPosition.z)) + self.cell.contentShift
    let cartesianPosition: SIMD3<Double> = self.cell.convertToCartesian(fractionalPosition)
    let position: SIMD4<Double> = rotationMatrix * SIMD4<Double>(x: cartesianPosition.x, y: cartesianPosition.y, z: cartesianPosition.z, w: 1.0)
    let absoluteCartesianPosition: SIMD3<Double> = SIMD3<Double>(position.x,position.y,position.z) + self.origin
    return absoluteCartesianPosition
  }
  
  // MARK: -
  // MARK: Symmetry
  
  public override func expandSymmetry(asymmetricAtom: SKAsymmetricAtom)
  {
    if asymmetricAtom.copies.isEmpty
    {
      let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: asymmetricAtom, position: asymmetricAtom.position)
      newAtom.type = .copy
      asymmetricAtom.copies = [newAtom]
    }
    else
    {
      asymmetricAtom.copies[0].type = .copy
      asymmetricAtom.copies[0].position = asymmetricAtom.position
    }
  }
  
  // MARK: -
  // MARK: Computing bonds
  
  public override func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(CrystalPolygonalPrismPrimitive.classVersionNumber)
    encoder.encode(Int(0x6f6b6191))
    
    super.binaryEncode(to: encoder)
  }
  
  // MARK: -
  // MARK: RKRenderUnitCellSource protocol
  
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
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > CrystalPolygonalPrismPrimitive.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    if(readVersionNumber <= 1)
    {
      super.init()
            
      let structure: Structure = try Structure(fromBinary: decoder)
      
      self.displayName = structure.displayName
      self.isVisible = structure.isVisible
      
      self.cell = structure.cell
      self.periodic = structure.periodic
      self.origin = structure.origin
      self.scaling = structure.scaling
      self.orientation = structure.orientation
      self.rotationDelta = structure.rotationDelta
      
      self.drawUnitCell = structure.drawUnitCell
      self.unitCellScaleFactor = structure.unitCellScaleFactor
      self.unitCellDiffuseColor = structure.unitCellDiffuseColor
      self.unitCellDiffuseIntensity = structure.unitCellDiffuseIntensity
    
      self.renderLocalAxis = structure.renderLocalAxis
      
      self.drawAtoms = structure.drawAtoms
      self.atomTreeController = structure.atomTreeController
      
      self.primitiveTransformationMatrix = structure.primitiveTransformationMatrix
      self.primitiveOrientation = structure.primitiveOrientation
      self.rotationDelta = structure.primitiveRotationDelta

      self.primitiveOpacity = structure.primitiveOpacity
      self.primitiveIsCapped = structure.primitiveIsCapped
      self.primitiveIsFractional = structure.primitiveIsFractional
      self.primitiveNumberOfSides = structure.primitiveNumberOfSides
      self.primitiveThickness = structure.primitiveThickness
      
      self.primitiveHue = structure.primitiveHue
      self.primitiveSaturation = structure.primitiveSaturation
      self.primitiveValue = structure.primitiveValue
      
      self.primitiveSelectionStyle = structure.primitiveSelectionStyle
      self.primitiveSelectionStripesDensity = structure.primitiveSelectionStripesDensity
      self.primitiveSelectionStripesFrequency = structure.primitiveSelectionStripesFrequency
      self.primitiveSelectionWorleyNoise3DFrequency = structure.primitiveSelectionWorleyNoise3DFrequency
      self.primitiveSelectionWorleyNoise3DJitter = structure.primitiveSelectionWorleyNoise3DJitter
      self.primitiveSelectionScaling = structure.primitiveSelectionScaling
      self.primitiveSelectionIntensity = structure.primitiveSelectionIntensity
      
      self.primitiveFrontSideHDR = structure.primitiveFrontSideHDR
      self.primitiveFrontSideHDRExposure = structure.primitiveFrontSideHDRExposure
      self.primitiveFrontSideAmbientColor = structure.primitiveFrontSideAmbientColor
      self.primitiveFrontSideDiffuseColor = structure.primitiveFrontSideDiffuseColor
      self.primitiveFrontSideSpecularColor = structure.primitiveFrontSideSpecularColor
      self.primitiveFrontSideDiffuseIntensity = structure.primitiveFrontSideDiffuseIntensity
      self.primitiveFrontSideAmbientIntensity = structure.primitiveFrontSideAmbientIntensity
      self.primitiveFrontSideSpecularIntensity = structure.primitiveFrontSideSpecularIntensity
      self.primitiveFrontSideShininess = structure.primitiveFrontSideShininess

      self.primitiveBackSideHDR = structure.primitiveBackSideHDR
      self.primitiveBackSideHDRExposure = structure.primitiveBackSideHDRExposure
      self.primitiveBackSideAmbientColor = structure.primitiveBackSideAmbientColor
      self.primitiveBackSideDiffuseColor = structure.primitiveBackSideDiffuseColor
      self.primitiveBackSideSpecularColor = structure.primitiveBackSideSpecularColor
      self.primitiveBackSideDiffuseIntensity = structure.primitiveBackSideDiffuseIntensity
      self.primitiveBackSideAmbientIntensity = structure.primitiveBackSideAmbientIntensity
      self.primitiveBackSideSpecularIntensity = structure.primitiveBackSideSpecularIntensity
      self.primitiveBackSideShininess = structure.primitiveBackSideShininess
    }
    else
    {
      let magicNumber = try decoder.decode(Int.self)
      if magicNumber != Int(0x6f6b6191)
      {
        throw BinaryDecodableError.invalidMagicNumber
      }
      
      try super.init(fromBinary: decoder)
    }
  }
}
