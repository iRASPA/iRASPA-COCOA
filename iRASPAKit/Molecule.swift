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
import LogViewKit
import simd
import MathKit
import RenderKit
import SymmetryKit
import SimulationKit
import OperationKit
import BinaryCodable

public final class Molecule: Structure, NSCopying, RKRenderAtomSource, RKRenderBondSource, RKRenderUnitCellSource
{
  private var versionNumber: Int = 1
  private static var classVersionNumber: Int = 1
  
  public override init(name: String)
  {
    super.init(name: name)
    reComputeBoundingBox()
  }
  
  public var colorAtomsWithBondColor: Bool
  {
    return (self.atomRepresentationType == .unity && self.bondColorMode == .uniform)
  }
  
  override var materialType: SKStructure.Kind
  {
    return .molecule
  }
  
  public override var positionType: PositionType
  {
    get
    {
      return .cartesian
    }
  }
  
  
  // MARK: -
  // MARK: Lgeacy Decodable support
  
  public required init(from decoder: Decoder) throws
  {
    var container = try decoder.unkeyedContainer()
    
    let readVersionNumber: Int = try container.decode(Int.self)
    if readVersionNumber > self.versionNumber
    {
      throw iRASPAError.invalidArchiveVersion
    }
    
    let superDecoder = try container.superDecoder()
    try super.init(from: superDecoder)
  }
  
  // MARK: -
  // MARK: NSCopying support
  
  public func copy(with zone: NSZone?) -> Any
  {
    //let propertyListEncoder: PropertyListEncoder = PropertyListEncoder()
    //let data: Data = try! propertyListEncoder.encode(self)
    //let propertyListDecoder: PropertyListDecoder = PropertyListDecoder()
    //let molecule: Molecule = try! propertyListDecoder.decode(Molecule.self, from: data)
    
    let binaryEncoder: BinaryEncoder = BinaryEncoder()
    binaryEncoder.encode(self)
    let data: Data = Data(binaryEncoder.data)
    do
    {
      let molecule: Molecule = try BinaryDecoder(data: [UInt8](data)).decode(Molecule.self)
      
      // set the 'bonds'-array of the atoms, since they are empty for a structure with symmetry
      let atomTreeNodes: [SKAtomTreeNode] = molecule.atoms.flattenedLeafNodes()
      let atomCopies: [SKAtomCopy] = atomTreeNodes.compactMap{$0.representedObject}.flatMap{$0.copies}
    
      //update selection
      let tags: Set<Int> = Set(self.atoms.selectedTreeNodes.map{$0.representedObject.tag})
      molecule.tag(atoms: molecule.atoms)
      molecule.atoms.selectedTreeNodes = Set(atomTreeNodes.filter{tags.contains($0.representedObject.tag)})
    
      for atomCopy in atomCopies
      {
        atomCopy.bonds = []
      }
    
      for bond in molecule.bonds.arrangedObjects
      {
        // make the list of bonds the atoms are involved in
        bond.atom1.bonds.insert(bond)
        bond.atom2.bonds.insert(bond)
      }
      return molecule
    }
    catch
    {
      
    }
    return Molecule.init(name: "")
  }
  
  // MARK: -
  // MARK: Molecule operations
  
  public override func expandSymmetry()
  {
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    
    for asymmetricAtom in asymmetricAtoms
    {
      let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: asymmetricAtom, position: asymmetricAtom.position)
      newAtom.type = .copy
      asymmetricAtom.copies = [newAtom]
    }
  }
  
  public override func expandSymmetry(asymmetricAtom: SKAsymmetricAtom)
  {
    let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: asymmetricAtom, position: asymmetricAtom.position)
    newAtom.type = .copy
    asymmetricAtom.copies = [newAtom]
  }
  
  public override func translateSelection(by shift: SIMD3<Double>)
  {
    for node in self.atoms.selectedTreeNodes
    {
      node.representedObject.displacement = shift
    }
    
  }
  
  public override func finalizeTranslateSelection(by shift: SIMD3<Double>) -> (atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    // copy the structure for undo (via the atoms, and bonds-properties)
    let molecule: Molecule =  self.copy() as! Molecule
    
    for node in self.atoms.selectedTreeNodes
    {
      node.representedObject.displacement = SIMD3<Double>(0,0,0)
    }
    
    for node in molecule.atoms.selectedTreeNodes
    {
      node.representedObject.position += shift
      node.representedObject.displacement = SIMD3<Double>(0,0,0)
    }
    
    molecule.expandSymmetry()
    
    molecule.reComputeBoundingBox()
    
    molecule.tag(atoms: molecule.atoms)
    
    molecule.reComputeBonds()
    
    return (atoms: molecule.atoms, bonds: molecule.bonds)
  }
  
  public override func centerOfMassOfSelection() -> SIMD3<Double>
  {
    var com: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.0)
    var M: Double = 0.0
    
    let atoms: [SKAtomCopy] = self.atoms.selectedTreeNodes.flatMap{$0.representedObject.copies}.filter{$0.type == .copy}
    guard !atoms.isEmpty else {return com}
    
    for atom in atoms
    {
      let elementIdentifier: Int = atom.asymmetricParentAtom.elementIdentifier
      let mass: Double = PredefinedElements.sharedInstance.elementSet[elementIdentifier].mass
      com += mass * atom.position
      M += mass
    }
    com /= M
    
    return com
  }
  
  public override func matrixOfInertia() -> double3x3
  {
    var inertiaMatrix: double3x3 = double3x3()
    let com: SIMD3<Double> = self.selectionCOMTranslation
    
    let atoms: [SKAtomCopy] = self.atoms.selectedTreeNodes.flatMap{$0.representedObject.copies}.filter{$0.type == .copy}
    for atom in atoms
    {
      let elementIdentifier: Int = atom.asymmetricParentAtom.elementIdentifier
      let mass: Double = PredefinedElements.sharedInstance.elementSet[elementIdentifier].mass
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
  
  public override func translateSelectionCartesian(by translation: SIMD3<Double>) -> (atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    // copy the structure for undo (via the atoms, and bonds-properties)
    let molecule: Molecule =  self.copy() as! Molecule
    
    for node in self.atoms.selectedTreeNodes
    {
      node.representedObject.displacement = SIMD3<Double>(0,0,0)
    }
    
    self.selectionCOMTranslation += translation
    
    for node in molecule.atoms.selectedTreeNodes
    {
      let pos: SIMD3<Double> = node.representedObject.position + translation
      node.representedObject.position = pos
    }
    
    molecule.expandSymmetry()
    
    molecule.reComputeBoundingBox()
    
    molecule.tag(atoms: molecule.atoms)
    
    molecule.reComputeBonds()
    
    return (atoms: molecule.atoms, bonds: molecule.bonds)
  }
  
  
  public override func rotateSelectionCartesian(using quaternion: simd_quatd) -> (atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    // copy the structure for undo (via the atoms, and bonds-properties)
    let molecule: Molecule =  self.copy() as! Molecule
    
    for node in self.atoms.selectedTreeNodes
    {
      node.representedObject.displacement = SIMD3<Double>(0,0,0)
    }
    
    let com: SIMD3<Double> = centerOfMassOfSelection()
    let rotationMatrix: double3x3 = double3x3(quaternion)
    
    for node in molecule.atoms.selectedTreeNodes
    {
      let pos = node.representedObject.position - com
      let position: SIMD3<Double> = rotationMatrix * pos + com
      node.representedObject.position = position
    }
    
    molecule.expandSymmetry()
    
    molecule.reComputeBoundingBox()
    
    molecule.tag(atoms: molecule.atoms)
    
    molecule.reComputeBonds()
    
    return (atoms: molecule.atoms, bonds: molecule.bonds)
  }
  
  public override func translateSelectionBodyFrame(by shift: SIMD3<Double>) -> (atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    // copy the structure for undo (via the atoms, and bonds-properties)
    let molecule: Molecule =  self.copy() as! Molecule
    
    for node in self.atoms.selectedTreeNodes
    {
      node.representedObject.displacement = SIMD3<Double>(0,0,0)
    }
    
    recomputeSelectionBodyFixedBasis(index: 3)
    
    let basis: double3x3 = self.selectionBodyFixedBasis
    let translation: SIMD3<Double> = basis.inverse * shift

    self.selectionCOMTranslation += translation
    
    for node in molecule.atoms.selectedTreeNodes
    {
      let pos: SIMD3<Double> = node.representedObject.position + translation
      node.representedObject.position = pos
    }
    
    molecule.expandSymmetry()
    
    molecule.reComputeBoundingBox()
    
    molecule.tag(atoms: molecule.atoms)
    
    molecule.reComputeBonds()
    
    return (atoms: molecule.atoms, bonds: molecule.bonds)
  }
  
  public override func rotateSelectionBodyFrame(using quaternion: simd_quatd, index: Int) -> (atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    // copy the structure for undo (via the atoms, and bonds-properties)
    let molecule: Molecule =  self.copy() as! Molecule
    
    for node in self.atoms.selectedTreeNodes
    {
      node.representedObject.displacement = SIMD3<Double>(0,0,0)
    }
    
    recomputeSelectionBodyFixedBasis(index: index)
    
    let com: SIMD3<Double> = self.selectionCOMTranslation
    let basis: double3x3 = self.selectionBodyFixedBasis
    let rotationMatrix = basis * double3x3(quaternion) * basis.inverse
    
    for node in molecule.atoms.selectedTreeNodes
    {
      let pos: SIMD3<Double> = node.representedObject.position - com
      let position: SIMD3<Double> = rotationMatrix * pos + com
      node.representedObject.position = position
    }
    
    molecule.expandSymmetry()
    
    molecule.reComputeBoundingBox()
    
    molecule.tag(atoms: molecule.atoms)
    
    molecule.reComputeBonds()
    
    return (atoms: molecule.atoms, bonds: molecule.bonds)
  }
  
  
  public override func computeChangedBondLength(bond: SKBondNode, to bondLength: Double) -> (SIMD3<Double>, SIMD3<Double>)
  {
    let pos1 = bond.atom1.position
    let asymmetricAtom1 = bond.atom1.asymmetricParentAtom
    let pos2 = bond.atom2.position
    let asymmetricAtom2 = bond.atom2.asymmetricParentAtom
    
    let oldBondLength: Double = self.bondLength(bond)
    
    let bondVector: SIMD3<Double> = normalize(self.bondVector(bond))
    
    let isAllFixed1: Bool = (asymmetricAtom1?.isFixed.x ?? false) && (asymmetricAtom1?.isFixed.y ?? false) &&
      (asymmetricAtom1?.isFixed.z ?? false)
    let isAllFixed2: Bool = (asymmetricAtom2?.isFixed.x ?? false) &&
      (asymmetricAtom2?.isFixed.y ?? false) &&
      (asymmetricAtom2?.isFixed.z ?? false)
    
    switch (isAllFixed1,isAllFixed2)
    {
    case (false, false):
      let newPos1: SIMD3<Double> = pos1 - 0.5 * (bondLength - oldBondLength) * bondVector
      let newPos2: SIMD3<Double> = pos2 + 0.5 * (bondLength - oldBondLength) * bondVector
      return (newPos1, newPos2)
    case (true, false):
      let newPos2: SIMD3<Double> = pos1 + bondLength * bondVector
      return (pos1, newPos2)
    case (false, true):
      let newPos1: SIMD3<Double> = pos2 - bondLength * bondVector
      return (newPos1, pos2)
    case (true, true):
      return (pos1,pos2)
    }
  }
  
  public override func generateCopiesForAsymmetricAtom(_ asymetricAtom: SKAsymmetricAtom)
  {
    for i in 0..<asymetricAtom.copies.count
    {
      asymetricAtom.copies[i].position = asymetricAtom.position
      asymetricAtom.copies[i].type = .copy
    }
    
    for copy in asymetricAtom.copies
    {
      for bond in copy.bonds
      {
        let posA: SIMD3<Double> = bond.atom1.position
        let posB: SIMD3<Double> = bond.atom2.position
        let separationVector: SIMD3<Double> = posA - posB
        
        let bondCriteria: Double = (bond.atom1.asymmetricParentAtom.bondDistanceCriteria + bond.atom2.asymmetricParentAtom.bondDistanceCriteria + 0.56)
        
        let bondLength: Double = length(separationVector)
        if (bondLength < bondCriteria)
        {
          // Type atom as 'Double'
          if (bondLength < 0.1)
          {
            bond.atom1.type = .duplicate
            bond.boundaryType = .internal
          }
        }
      }
    }
    
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
    var minimum: SIMD3<Double> = SIMD3<Double>(x: Double.greatestFiniteMagnitude, y: Double.greatestFiniteMagnitude, z: Double.greatestFiniteMagnitude)
    var maximum: SIMD3<Double> = SIMD3<Double>(x: -Double.greatestFiniteMagnitude, y: -Double.greatestFiniteMagnitude, z: -Double.greatestFiniteMagnitude)
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    if atoms.isEmpty
    {
      return SKBoundingBox(minimum: SIMD3<Double>(0.0,0.0,0.0), maximum: SIMD3<Double>(0.0,0.0,0.0))
    }
    
    for atom in atoms
    {
      let cartesianPosition: SIMD4<Double> = SIMD4<Double>(atom.position.x,atom.position.y,atom.position.z,1.0)
      
      let radius: Double = atom.asymmetricParentAtom?.drawRadius ?? 0.0
      
      minimum.x = min(minimum.x, cartesianPosition.x-radius)
      minimum.y = min(minimum.y, cartesianPosition.y-radius)
      minimum.z = min(minimum.z, cartesianPosition.z-radius)
      maximum.x = max(maximum.x, cartesianPosition.x+radius)
      maximum.y = max(maximum.y, cartesianPosition.y+radius)
      maximum.z = max(maximum.z, cartesianPosition.z+radius)
    }
    
    return SKBoundingBox(minimum: minimum, maximum: maximum)
  }
  
  public override var transformedBoundingBox: SKBoundingBox
  {
    let currentBoundingBox: SKBoundingBox = self.cell.boundingBox
    
    let transformation = double4x4.init(transformation: double4x4(self.orientation), aroundPoint: currentBoundingBox.center)
    let transformedBoundingBox: SKBoundingBox = currentBoundingBox.adjustForTransformation(transformation)
    
    return transformedBoundingBox
  }
  
  
  public override var renderAtoms: [RKInPerInstanceAttributesAtoms]
  {
    var index: Int
    
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldDefiner)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms](repeating: RKInPerInstanceAttributesAtoms(), count: atoms.count)
    
    index = 0
    
    for (asymetricIndex, asymetricAtom) in asymmetricAtoms.enumerated()
    {
      let atomType: SKForceFieldType? = forceFieldSet?[asymetricAtom.uniqueForceFieldName]
      let typeIsVisible: Bool = atomType?.isVisible ?? true
      
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      
      for copy in copies
      {
        let cartesianPosition: SIMD3<Double> = copy.position + self.cell.contentShift
        copy.asymmetricIndex = asymetricIndex
        
        //let w: Double = (atom.isVisible && atom.isVisibleEnabled) && !atomNode.isGroup ? 1.0 : -1.0
        let w: Double = (typeIsVisible && copy.asymmetricParentAtom.isVisible && copy.asymmetricParentAtom.isVisibleEnabled && asymetricAtom.symmetryType != .container) ? 1.0 : -1.0
        let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: Float(w))
        
        let radius: Double = copy.asymmetricParentAtom?.drawRadius ?? 1.0
        let ambient: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
        let diffuse: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
        let specular: NSColor = self.atomSpecularColor
        
        data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius))
        index = index + 1
       }
    }
    return data
  }
  
  public override var renderSelectedAtoms: [RKInPerInstanceAttributesAtoms]
  {
    var index: Int
    
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldDefiner)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
    
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.allSelectedNodes.compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms](repeating: RKInPerInstanceAttributesAtoms(), count: atoms.count)
    
    index = 0
    
    for asymetricAtom in asymmetricAtoms
    {
      let atomType: SKForceFieldType? = forceFieldSet?[asymetricAtom.uniqueForceFieldName]
      let typeIsVisible: Bool = atomType?.isVisible ?? true
      
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      for copy in copies
      {
        let cartesianPosition: SIMD3<Double> = copy.position + asymetricAtom.displacement + self.cell.contentShift
        
        //let w: Double = (atom.isVisible && atom.isVisibleEnabled) && !atomNode.isGroup ? 1.0 : -1.0
        let w: Double = (typeIsVisible && copy.asymmetricParentAtom.isVisible && copy.asymmetricParentAtom.isVisibleEnabled && asymetricAtom.symmetryType != .container) ? 1.0 : -1.0
        let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: Float(w))
        
        let radius: Double = copy.asymmetricParentAtom?.drawRadius ?? 1.0
        let ambient: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
        let diffuse: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
        let specular: NSColor = self.atomSpecularColor
        
        data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius))
        index = index + 1
      }
    }
    return data
  }
  
  public override var atomPositions: [SIMD4<Double>]
  {
    var index: Int
    
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldDefiner)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
    
    let atomNodes: [SKAtomTreeNode] = self.atoms.flattenedLeafNodes()
    let numberOfAtoms: Int = atomNodes.compactMap{$0.representedObject}.count
    var data: [SIMD4<Double>] = [SIMD4<Double>](repeating: SIMD4<Double>(), count: numberOfAtoms)
    
    index = 0
    for atomNode in atomNodes
    {
      let atom = atomNode.representedObject
      
      let atomType: SKForceFieldType? = forceFieldSet?[atom.uniqueForceFieldName]
      let typeIsVisible: Bool = atomType?.isVisible ?? true
      
      let pos: SIMD3<Double> = atom.position + self.cell.contentShift
        
      let rotationMatrix: double4x4 =  double4x4(transformation: double4x4(simd_quatd: self.orientation), aroundPoint: self.cell.boundingBox.center)
      let w: Double = (typeIsVisible && atom.isVisible && atom.isVisibleEnabled) && !atomNode.isGroup ? 1.0 : -1.0
      let position: SIMD4<Double> = rotationMatrix * SIMD4<Double>(x: pos.x, y: pos.y, z: pos.z, w: w)
        
      data[index] = position
      index = index + 1
    }
    return data
  }
  
  public override var crystallographicPositions: [(SIMD3<Double>, Int)]
  {
    return []
  }
  
  public override var potentialParameters: [SIMD2<Double>]
  {
    var index: Int
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    var data: [SIMD2<Double>] = [SIMD2<Double>](repeating: SIMD2<Double>(), count: atoms.count)
    
    index = 0
    for atom in atoms
    {
      data[index] = atom.asymmetricParentAtom.potentialParameters
      
      index = index + 1
    }
    return data
  }
  
  public override var renderInternalBonds: [RKInPerInstanceAttributesBonds]
  {
    var index: Int = 0
    var data: [RKInPerInstanceAttributesBonds] = [RKInPerInstanceAttributesBonds](repeating: RKInPerInstanceAttributesBonds(), count: bonds.arrangedObjects.count * numberOfReplicas())
      
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldDefiner)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
      
    index = 0
    for bond in bonds.arrangedObjects
    {
      if bond.boundaryType == .internal
      {
        let atom1: SKAtomCopy = bond.atom1
        let atom2: SKAtomCopy = bond.atom2
        let asymmetricAtom1: SKAsymmetricAtom = atom1.asymmetricParentAtom
        let asymmetricAtom2: SKAsymmetricAtom = atom2.asymmetricParentAtom
        
        let atomType1: SKForceFieldType? = forceFieldSet?[asymmetricAtom1.uniqueForceFieldName]
        let typeIsVisible1: Bool = atomType1?.isVisible ?? true
        let atomType2: SKForceFieldType? = forceFieldSet?[asymmetricAtom2.uniqueForceFieldName]
        let typeIsVisible2: Bool = atomType2?.isVisible ?? true
        
        let pos1: SIMD3<Double> = atom1.position + self.cell.contentShift
        let pos2: SIMD3<Double> = atom2.position + self.cell.contentShift
        let bondLength: Double = length(pos2-pos1)
          
        let color1: NSColor = asymmetricAtom1.color
        let color2: NSColor = asymmetricAtom2.color
          
        let drawRadius1: Double = asymmetricAtom1.drawRadius / bondLength;
        let drawRadius2: Double = asymmetricAtom2.drawRadius / bondLength;
          
        let w: Double = (typeIsVisible1 && typeIsVisible2 && (asymmetricAtom1.isVisible && asymmetricAtom2.isVisible) &&
            (asymmetricAtom1.isVisibleEnabled && asymmetricAtom2.isVisibleEnabled)) ? 1.0 : -1.0
          
        data[index] = RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(x: pos1.x, y: pos1.y, z: pos1.z, w: w),
                                                       position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: w),
                                                       color1: SIMD4<Float>(color: color1),
                                                       color2: SIMD4<Float>(color: color2),
                                                       scale: SIMD4<Float>(x: drawRadius1, y: 1.0, z: drawRadius2, w: drawRadius1/drawRadius2))
        index = index + 1
          
      }
    }
    return data
  }
  
  
  
  // MARK: -
  // MARK: Compute bonds
  
  public override func reComputeBonds()
  {
    let atomList: [SKAtomCopy] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    self.bonds.arrangedObjects = self.computeBonds(cell: self.cell, atomList: atomList, cancelHandler: {return false}, updateHandler: {})
  }
  
  public override func reComputeBonds(_ node: ProjectTreeNode, cancelHandler: (()-> Bool), updateHandler: (() -> ()))
  {
    let atomList: [SKAtomCopy] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    self.bonds.arrangedObjects = self.computeBonds(cell: self.cell, atomList: atomList, cancelHandler: cancelHandler, updateHandler: updateHandler)
  }
  
  public override func computeBonds(cancelHandler: (()-> Bool) = {return false}, updateHandler: (() -> ()) = {}) -> Set<SKBondNode>
  {
    let atomList: [SKAtomCopy] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    return self.computeBonds(cell: self.cell, atomList: atomList, cancelHandler: cancelHandler, updateHandler: updateHandler)
  }
  
  public override func computeBonds(cell structureCell: SKCell, atomList atoms: [SKAtomCopy], cancelHandler: (()-> Bool) = {return false}, updateHandler: (() -> ()) = {}) -> Set<SKBondNode>
  {
    let cutoff: Double = 3.0
    let offsets: [[Int]] = [[0,0,0],[1,0,0],[1,1,0],[0,1,0],[-1,1,0],[0,0,1],[1,0,1],[1,1,1],[0,1,1],[-1,1,1],[-1,0,1],[-1,-1,1],[0,-1,1],[1,-1,1]]
    
    var totalCount: Int
    var computedBonds: Set<SKBondNode> = []
    
    let perpendicularWidths: SIMD3<Double> = structureCell.boundingBox.widths + SIMD3<Double>(x: 0.1, y: 0.1, z: 0.1)
    let numberOfCells: [Int] = [Int(perpendicularWidths.x/cutoff),Int(perpendicularWidths.y/cutoff),Int(perpendicularWidths.z/cutoff)]
    let totalNumberOfCells: Int = numberOfCells[0] * numberOfCells[1] * numberOfCells[2]
    let cutoffVector: SIMD3<Double> = SIMD3<Double>(x: perpendicularWidths.x/Double(numberOfCells[0]), y: perpendicularWidths.y/Double(numberOfCells[1]), z: perpendicularWidths.z/Double(numberOfCells[2]))
    
    
    if ((numberOfCells[0]>=3) &&  (numberOfCells[1]>=3) && (numberOfCells[2]>=3))
    {
      var head: [Int] = [Int](repeating: -1, count: totalNumberOfCells)
      var list: [Int] = [Int](repeating: -1, count: atoms.count)
      
      // create cell-list based on the bond-cutoff
      for i in 0..<atoms.count
      {
        atoms[i].type = .copy
        let position: SIMD3<Double> = atoms[i].position - structureCell.boundingBox.minimum
        
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
              let posA: SIMD3<Double> = atoms[i].position
              
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
                    let posB: SIMD3<Double> = atoms[j].position
                    let separationVector: SIMD3<Double> = posA - posB
                    
                    let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.56)
                    
                    if (length(separationVector) < bondCriteria)
                    {
                      computedBonds.insert(SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .internal))
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
        let posA: SIMD3<Double> = atoms[i].position
        atoms[i].type = .copy
        
        for j in i+1..<atoms.count
        {
          let posB: SIMD3<Double> = atoms[j].position
          
          let separationVector: SIMD3<Double> = posA - posB
          
          let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.56)
          
          if (length(separationVector) < bondCriteria )
          {
            computedBonds.insert(SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .internal))
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
    
    return computedBonds
  }
  
  public override func computeBondsOperation(structure: Structure, windowController: NSWindowController?) -> FKOperation?
  {
    return Molecule.RecomputeBondsOperation(structure: structure, windowController: windowController)
  }
  
  
  public class RecomputeBondsOperation: FKOperation
  {
    let structure : Structure
    var windowController: NSWindowController? = nil
    
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
      LogQueue.shared.verbose(destination: windowController, message: "start computing bonds: \(structure.displayName)")
      
      let atoms: [SKAtomCopy] = structure.atoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
      let computedBonds = structure.computeBonds(cell: structure.cell, atomList: atoms)
      
      structure.bonds.arrangedObjects = computedBonds
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
    encoder.encode(Molecule.classVersionNumber)
    super.binaryEncode(to: encoder)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > Molecule.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    try super.init(fromBinary: decoder)
  }
}
