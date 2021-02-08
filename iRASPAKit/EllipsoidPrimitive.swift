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

public final class EllipsoidPrimitive: Structure, RKRenderEllipsoidObjectsSource
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
      self.atomTreeController.flattenedLeafNodes().forEach{
      let pos = $0.representedObject.position
          $0.representedObject.position = self.cell.convertToCartesian(pos)
        }
    case is MolecularCrystal, is ProteinCrystal, is Molecule, is Protein,
         is EllipsoidPrimitive, is CylinderPrimitive, is PolygonalPrismPrimitive:
      // nothing to do
      break
    default:
      break
    }
    self.expandSymmetry()
    reComputeBoundingBox()
    
    setRepresentationStyle(style: Structure.RepresentationStyle.objects)
  }
  
  public override var materialType: SKStructure.Kind
  {
    return .ellipsoidPrimitive
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
   
  public var renderEllipsoidObjects: [RKInPerInstanceAttributesAtoms]
  {
    var index: Int
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms](repeating: RKInPerInstanceAttributesAtoms(), count:  atoms.count)
    
    index = 0
    
    for (asymetricIndex, asymetricAtom) in asymmetricAtoms.enumerated()
    {
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      
      for copy in copies
      {
        let pos: SIMD3<Double> = copy.position
        copy.asymmetricIndex = asymetricIndex
        
        let w: Double = (copy.asymmetricParentAtom.isVisible && copy.asymmetricParentAtom.isVisibleEnabled && asymetricAtom.symmetryType != .container) ? 1.0 : -1.0
        let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(pos.x), y: Float(pos.y), z: Float(pos.z), w: Float(w))
        
        let radius: Double = 1.0
        let ambient: NSColor = NSColor.white
        let diffuse: NSColor = NSColor.white
        let specular: NSColor = NSColor.white
        
        data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius), tag: UInt32(asymetricIndex))
        index = index + 1
      }
    }
    return data
  }
  
  // MARK: Rendering selection
  // =====================================================================
  
  public var renderSelectedEllipsoidObjects: [RKInPerInstanceAttributesAtoms]
  {
    var index: Int
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.allSelectedNodes.compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}
    
    var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms](repeating: RKInPerInstanceAttributesAtoms(), count:  atoms.count)
    
    index = 0
    
    for (asymetricIndex, asymetricAtom) in asymmetricAtoms.enumerated()
    {
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      
      for copy in copies
      {
        let pos: SIMD3<Double> = copy.position
        copy.asymmetricIndex = asymetricIndex
        
        let w: Double = (copy.asymmetricParentAtom.isVisible && copy.asymmetricParentAtom.isVisibleEnabled && asymetricAtom.symmetryType != .container) ? 1.0 : -1.0
        let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(pos.x), y: Float(pos.y), z: Float(pos.z), w: Float(w))
        
        let radius: Double = 1.0
        let ambient: NSColor = NSColor.white
        let diffuse: NSColor = NSColor.white
        let specular: NSColor = NSColor.white
        
        data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius), tag: UInt32(asymetricIndex))
        index = index + 1
      }
    }
    return data
  }
  
  // MARK: -
  // MARK: Filtering
   
  public override func filterCartesianAtomPositions(_ filter: (SIMD3<Double>) -> Bool) -> IndexSet
  {
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    
    var data: IndexSet = IndexSet()
    
    for (asymetricIndex, asymetricAtom) in asymmetricAtoms.enumerated()
    {
      let typeIsVisible: Bool = asymetricAtom.isVisible
      
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      
      for copy in copies
      {
        let pos: SIMD3<Double> = copy.position + self.cell.contentShift
        
        let rotationMatrix: double4x4 =  double4x4(transformation: double4x4(simd_quatd: self.orientation), aroundPoint: self.cell.boundingBox.center)
        let position: SIMD4<Double> = rotationMatrix * SIMD4<Double>(x: pos.x, y: pos.y, z: pos.z, w: 1.0)
        let absoluteCartesianPosition: SIMD3<Double> = SIMD3<Double>(position.x,position.y,position.z) + origin
        
        if filter(absoluteCartesianPosition) && (typeIsVisible && asymetricAtom.isVisible && asymetricAtom.isVisibleEnabled)
        {
          data.insert(asymetricIndex)
        }
      }
    }
    return data
  }
  
  // MARK: -
  // MARK: cell property-wrapper
  
  public override var unitCell: double3x3
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
    return boundaryBoxCell.unitCell
  }
  
  public override var cellLengthA: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
    return boundaryBoxCell.a
  }
  
  public override var cellLengthB: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
    return boundaryBoxCell.b
  }
  
  public override var cellLengthC: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
    return boundaryBoxCell.c
  }
  
  public override var cellAngleAlpha: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
    return boundaryBoxCell.alpha
  }
  
  public override var cellAngleBeta: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
    return boundaryBoxCell.beta
  }
  
  public override var cellAngleGamma: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
    return boundaryBoxCell.gamma
  }
  
  public override var cellVolume: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
    return boundaryBoxCell.volume
  }
  
  public override var cellPerpendicularWidthsX: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
    return boundaryBoxCell.perpendicularWidths.x
  }
  
  public override var cellPerpendicularWidthsY: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
    return boundaryBoxCell.perpendicularWidths.y
  }
  
  public override var cellPerpendicularWidthsZ: Double
  {
    let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
    return boundaryBoxCell.perpendicularWidths.z
  }
  
  public override var boundingBox: SKBoundingBox
  {
    let modelMatrix: double4x4 = double4x4(transformation: double4x4(simd_quatd: self.orientation), aroundPoint: SIMD3<Double>(0,0,0), withTranslation: SIMD3<Double>(0,0,0))
    
    let sphereVertices: [RKVertex] = MetalSphereGeometry().vertices
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    
    var minimum: SIMD3<Double> = SIMD3<Double>(x: Double.greatestFiniteMagnitude, y: Double.greatestFiniteMagnitude, z: Double.greatestFiniteMagnitude)
    var maximum: SIMD3<Double> = SIMD3<Double>(x: -Double.greatestFiniteMagnitude, y: -Double.greatestFiniteMagnitude, z: -Double.greatestFiniteMagnitude)
    
    
    for (asymetricIndex, asymetricAtom) in asymmetricAtoms.enumerated()
    {
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      
      for copy in copies
      {
        let pos: SIMD3<Double> = copy.position
        copy.asymmetricIndex = asymetricIndex
        
        for vertex in sphereVertices
        {
          let vertexPosition: SIMD4<Double> = SIMD4<Double>(Double(vertex.position.x), Double(vertex.position.y), Double(vertex.position.z), Double(vertex.position.w))
          
          let transformationMatrix = double4x4(Double3x3: self.primitiveTransformationMatrix)
          let primitiveModelMatrix = double4x4(simd_quatd: self.primitiveOrientation)
          
          let pos: SIMD4<Double> = modelMatrix * (primitiveModelMatrix * transformationMatrix * vertexPosition + SIMD4<Double>(pos.x, pos.y, pos.z, 1.0))
          
          minimum = SIMD3<Double>(x: min(pos.x, minimum.x),
                                  y: min(pos.y, minimum.y),
                                  z: min(pos.z, minimum.z))
          
          maximum = SIMD3<Double>(x: max(pos.x, maximum.x),
                                  y: max(pos.y, maximum.y),
                                  z: max(pos.z, maximum.z))
        }
      }
    }
    
    return SKBoundingBox(minimum: minimum, maximum: maximum)
  }
  
  // MARK: -
  // MARK: Translation and rotation operations
   
  public override func centerOfMassOfSelection(atoms: [SKAtomCopy]) -> SIMD3<Double>
  {
    var com: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.0)
    var M: Double = 0.0
     
    guard !atoms.isEmpty else {return com}
     
    for atom in atoms
    {
      let mass: Double = 1.0
      com += mass * atom.position
      M += mass
    }
    com /= M
     
    return com
  }
   
  public override func matrixOfInertia(atoms: [SKAtomCopy]) -> double3x3
  {
    var inertiaMatrix: double3x3 = double3x3()
    let com: SIMD3<Double> = self.selectionCOMTranslation
     
    for atom in atoms
    {
      let mass: Double = 1.0
      let dr: SIMD3<Double> = atom.position - com
       
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
    return atoms.map{$0.position + translation}
  }
   
  public override func translatedBodyFramePositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by shift: SIMD3<Double>) -> [SIMD3<Double>]
  {
    let basis: double3x3 = self.selectionBodyFixedBasis
    let translation: SIMD3<Double> = basis.inverse * shift
     
    return atoms.map{$0.position + translation}
  }
   
  // MARK: -
  // MARK: Rotation operations
   
  public override func rotatedPositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by quaternion: simd_quatd) -> [SIMD3<Double>]
  {
    let copies: [SKAtomCopy] = atoms.flatMap{$0.copies}.filter{$0.type == .copy}
    let com: SIMD3<Double> = self.centerOfMassOfSelection(atoms: copies)
    let rotationMatrix: double3x3 = double3x3(quaternion)
     
    return atoms.map({
      let pos = $0.position - com
      return rotationMatrix * pos + com
    })
  }
   
  public override func rotatedBodyFramePositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by quaternion: simd_quatd) -> [SIMD3<Double>]
  {
    let copies: [SKAtomCopy] = atoms.flatMap{$0.copies}.filter{$0.type == .copy}
    let com: SIMD3<Double> = self.centerOfMassOfSelection(atoms: copies)
    let basis: double3x3 = self.selectionBodyFixedBasis
    let rotationMatrix = basis * double3x3(quaternion) * basis.inverse
     
    return atoms.map({
      let pos: SIMD3<Double> = $0.position - com
      return rotationMatrix * pos + com
    })
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
    encoder.encode(EllipsoidPrimitive.classVersionNumber)
    
    super.binaryEncode(to: encoder)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > EllipsoidPrimitive.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    try super.init(fromBinary: decoder)
  }
}

