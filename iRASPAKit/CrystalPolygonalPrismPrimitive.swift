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
import SymmetryKit
import BinaryCodable
import simd

public final class CrystalPolygonalPrismPrimitive: Structure, RKRenderCrystalPolygonalPrismObjectsSource
{
  private static var classVersionNumber: Int = 1
  
  public override init(name: String)
  {
    super.init(name: name)
    let displayName: String = "center"
    let color: NSColor = NSColor.yellow
    let drawRadius: Double = 5.0
    let bondDistanceCriteria: Double = 0.0
    let asymmetricAtom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: displayName, elementId:  0, uniqueForceFieldName: displayName, position: SIMD3<Double>(0,0,0), charge: 0.0, color: color, drawRadius: drawRadius, bondDistanceCriteria: bondDistanceCriteria)
    self.expandSymmetry(asymmetricAtom: asymmetricAtom)
    let atomTreeNode: SKAtomTreeNode = SKAtomTreeNode(representedObject: asymmetricAtom)
    atomTreeController.insertNode(atomTreeNode, inItem: nil, atIndex: 0)
    reComputeBoundingBox()
    
    setRepresentationStyle(style: Structure.RepresentationStyle.objects)
  }
  
  public required init(original structure: Structure)
  {
    super.init(original: structure)
  }
  
  public required init(clone structure: Structure)
  {
    super.init(clone: structure)
    
    switch(structure)
    {
    case is Crystal, is CrystalEllipsoidPrimitive, is CrystalCylinderPrimitive, is CrystalPolygonalPrismPrimitive:
      // nothing to do
      break
    case is MolecularCrystal, is ProteinCrystal, is Molecule, is Protein,
         is EllipsoidPrimitive, is CylinderPrimitive, is PolygonalPrismPrimitive:
      self.atomTreeController.flattenedLeafNodes().forEach{
      let pos = $0.representedObject.position
          $0.representedObject.position = self.cell.convertToFractional(pos)
        }
      break
    default:
      break
    }
    self.expandSymmetry()
    reComputeBoundingBox()
    reComputeBonds()
    
    setRepresentationStyle(style: Structure.RepresentationStyle.objects)
  }
  
  public override var materialType: SKStructure.Kind
  {
    return .crystalPolygonalPrismPrimitive
  }
  
  public override var periodic: Bool
  {
    get
    {
      return primitiveIsFractional
    }
    set(newValue)
    {
      super.periodic = newValue
    }
  }
  
  // MARK: Rendering
  // =====================================================================
   
  public var renderCrystalPolygonalPrismObjects: [RKInPerInstanceAttributesAtoms]
  {
    var index: Int
    
    let numberOfReplicas: Int = self.cell.numberOfReplicas
    
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
    
    for (asymetricIndex, asymetricAtom) in asymmetricAtoms.enumerated()
    {
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      
      for copy in copies
      {
        let pos: SIMD3<Double> = copy.position
        copy.asymmetricIndex = asymetricIndex
        
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
              
              data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius), tag: UInt32(asymetricIndex))
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
    
    let numberOfReplicas: Int = self.cell.numberOfReplicas
    
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
    
    for (asymetricIndex, asymetricAtom) in asymmetricAtoms.enumerated()
    {
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      
      for copy in copies
      {
        let pos: SIMD3<Double> = copy.position
        copy.asymmetricIndex = asymetricIndex
        
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
              
              data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius), tag: UInt32(asymetricIndex))
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
  
  public override var cellLengthA: Double
  {
    return self.cell.a
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
  
  // MARK: -
  // MARK: Computing bonds
  
  public override func reComputeBonds()
  {
    self.bondController.arrangedObjects = []
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public override func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(CrystalPolygonalPrismPrimitive.classVersionNumber)
    
    super.binaryEncode(to: encoder)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > CrystalPolygonalPrismPrimitive.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    try super.init(fromBinary: decoder)
  }
}



