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
import BinaryCodable
import RenderKit
import SymmetryKit
import LogViewKit
import SimulationKit
import OperationKit

public final class ProteinCrystal: Structure, NSCopying, RKRenderAdsorptionSurfaceStructure, SpaceGroupProtocol
{
  private var versionNumber: Int = 2
  private static var classVersionNumber: Int = 1

  public override var renderCanDrawAdsorptionSurface: Bool {return true}
  
  public override init()
  {
    super.init()
    self.drawUnitCell = true
  }
  
  public override init(name: String)
  {
    super.init(name: name)
    drawUnitCell = true
    reComputeBoundingBox()
  }
  
  override var materialType: MaterialType
  {
    return .proteinCrystal
  }
  
  public override var periodic: Bool
  {
    get
    {
      return self.drawUnitCell
    }
    set(newValue)
    {
      super.periodic = newValue
    }
  }
  
  public override var positionType: PositionType
  {
    get
    {
      return .cartesian
    }
  }
  
  
  // MARK: -
  // MARK: Legacy Decodable support
  
  public required init(from decoder: Decoder) throws
  {
    var container = try decoder.unkeyedContainer()
    
    let readVersionNumber: Int = try container.decode(Int.self)
    if readVersionNumber > self.versionNumber
    {
      throw iRASPAError.invalidArchiveVersion
    }
    
    var number: Int = 1
    if readVersionNumber >= 2 // introduced in version 2
    {
       number = try container.decode(Int.self)
      
    }
    
    let superDecoder = try container.superDecoder()
    try super.init(from: superDecoder)
    self.spaceGroup = SKSpacegroup(HallNumber: number)
  }
  
  // MARK: -
  // MARK: NSCopying support
  
  public func copy(with zone: NSZone?) -> Any
  {
    //let propertyListEncoder: PropertyListEncoder = PropertyListEncoder()
    //et data: Data = try! propertyListEncoder.encode(self)
    //let propertyListDecoder: PropertyListDecoder = PropertyListDecoder()
    //let crystal: ProteinCrystal = try! propertyListDecoder.decode(ProteinCrystal.self, from: data)
    
    let binaryEncoder: BinaryEncoder = BinaryEncoder()
    binaryEncoder.encode(self)
    let data: Data = Data(binaryEncoder.data)
    do
    {
      let crystal: ProteinCrystal = try BinaryDecoder(data: [UInt8](data)).decode(ProteinCrystal.self)
    
      // set the 'bonds'-array of the atoms, since they are empty for a structure with symmetry
      let atomTreeNodes: [SKAtomTreeNode] = crystal.atoms.flattenedLeafNodes()
      let atomCopies: [SKAtomCopy] = atomTreeNodes.compactMap{$0.representedObject}.flatMap{$0.copies}
    
    
      //update selection
      let tags: Set<Int> = Set(self.atoms.selectedTreeNodes.map{$0.representedObject.tag})
      crystal.tag(atoms: crystal.atoms)
      crystal.atoms.selectedTreeNodes = Set(atomTreeNodes.filter{tags.contains($0.representedObject.tag)})
    
      for atomCopy in atomCopies
      {
        atomCopy.bonds = []
      }
    
      for bond in crystal.bonds.arrangedObjects
      {
        // make the list of bonds the atoms are involved in
        bond.atom1.bonds.insert(bond)
        bond.atom2.bonds.insert(bond)
      }
      return crystal
    }
    catch
    {
      
    }
    return ProteinCrystal()
  }
  
  public override func translateSelection(by shift: double3)
  {
    for node in self.atoms.selectedTreeNodes
    {
      node.representedObject.displacement = shift
    }
    
  }
  
  public override func finalizeTranslateSelection(by shift: double3) -> (atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    // copy the structure for undo (via the atoms, and bonds-properties)
    let proteinCrystal: ProteinCrystal =  self.copy() as! ProteinCrystal
    
    for node in self.atoms.selectedTreeNodes
    {
      node.representedObject.displacement = double3(0,0,0)
    }
    
    for node in proteinCrystal.atoms.selectedTreeNodes
    {
      node.representedObject.position += shift
      node.representedObject.displacement = double3(0,0,0)
    }
    proteinCrystal.expandSymmetry()
    
    proteinCrystal.reComputeBoundingBox()
    
    proteinCrystal.tag(atoms: proteinCrystal.atoms)
    
    proteinCrystal.reComputeBonds()
    
    return (atoms: proteinCrystal.atoms, bonds: proteinCrystal.bonds)
  }
  
  public override func expandSymmetry()
  {
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    
    let unitCell = self.cell.unitCell
    let inverseCell = self.cell.inverseUnitCell
    for asymmetricAtom in asymmetricAtoms
    {
      asymmetricAtom.copies = []
      
      let fractionalPosition = inverseCell * asymmetricAtom.position
      let images: [double3] = self.spaceGroup.listOfSymmetricPositions(fractionalPosition)
      
      for image in images
      {
        let CartesianPosition = unitCell * image
        let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: asymmetricAtom, position: CartesianPosition)
        newAtom.type = .copy
        asymmetricAtom.copies.append(newAtom)
      }
    }
  }
  
  public override func expandSymmetry(asymmetricAtom: SKAsymmetricAtom)
  {
    asymmetricAtom.copies = []
    
    let unitCell = self.cell.unitCell
    let inverseUnitCell = self.cell.inverseUnitCell
    
    let fractionalPosition = inverseUnitCell * asymmetricAtom.position
    let images: [double3] = self.spaceGroup.listOfSymmetricPositions(fractionalPosition)
    
    for image in images
    {
      let CartesianPosition = unitCell * image
      let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: asymmetricAtom, position: CartesianPosition)
      newAtom.type = .copy
      asymmetricAtom.copies.append(newAtom)
    }
  }
  
  public override var spaceGroupHallNumber: Int?
  {
    get
    {
      return self.spaceGroup.spaceGroupSetting.number
    }
    set(newValue)
    {
      if let newValue = newValue
      {
        self.spaceGroup = SKSpacegroup(HallNumber: newValue)
        let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
        
        asymmetricAtoms.forEach({ self.expandSymmetry(asymmetricAtom: $0)})
        
        self.tag(atoms: self.atoms)
        self.reComputeBoundingBox()
        self.reComputeBonds()
        
      }
    }
  }
  
  public override func numberOfReplicas() -> Int
  {
    return self.cell.numberOfReplicas
  }
  
  public override func computeChangedBondLength(bond: SKBondNode, to bondLength: Double) -> (double3, double3)
  {
    let pos1 = bond.atom1.position
    let asymmetricAtom1 = bond.atom1.asymmetricParentAtom
    let pos2 = bond.atom2.position
    let asymmetricAtom2 = bond.atom2.asymmetricParentAtom
    
    let oldBondLength: Double = self.bondLength(bond)
    
    let bondVector: double3 = normalize(self.bondVector(bond))
    
    let isAllFixed1: Bool = (asymmetricAtom1?.isFixed.x ?? false) && (asymmetricAtom1?.isFixed.y ?? false) &&
      (asymmetricAtom1?.isFixed.z ?? false)
    let isAllFixed2: Bool = (asymmetricAtom2?.isFixed.x ?? false) &&
      (asymmetricAtom2?.isFixed.y ?? false) &&
      (asymmetricAtom2?.isFixed.z ?? false)
    
    switch (isAllFixed1,isAllFixed2)
    {
    case (false, false):
      let newPos1: double3 = pos1 - 0.5 * (bondLength - oldBondLength) * bondVector
      let newPos2: double3 = pos2 + 0.5 * (bondLength - oldBondLength) * bondVector
      return (newPos1, newPos2)
    case (true, false):
      let newPos2: double3 = pos1 + bondLength * bondVector
      return (pos1, newPos2)
    case (false, true):
      let newPos1: double3 = pos2 - bondLength * bondVector
      return (newPos1, pos2)
    case (true, true):
      return (pos1,pos2)
    }
  }
  
  
  
  public override func generateCopiesForAsymmetricAtom(_ asymetricAtom: SKAsymmetricAtom)
  {
    let unitCell = self.cell.unitCell
    let inverseUnitCell = self.cell.inverseUnitCell
    
    let fractionalPosition = inverseUnitCell * asymetricAtom.position
    let images: [double3] = self.spaceGroup.listOfSymmetricPositions(fractionalPosition)
    for (index, image) in images.enumerated()
    {
      asymetricAtom.copies[index].asymmetricParentAtom = asymetricAtom
      asymetricAtom.copies[index].position = unitCell * image
      asymetricAtom.copies[index].type = .copy
    }
    
    
    for copy in asymetricAtom.copies
    {
      for bond in copy.bonds
      {
        let posA: double3 = bond.atom1.position
        let posB: double3 = bond.atom2.position
        let separationVector: double3 = posA - posB
        let periodicSeparationVector: double3 = cell.applyUnitCellBoundaryCondition(separationVector)
        
        let bondCriteria: Double = (bond.atom1.asymmetricParentAtom.bondDistanceCriteria + bond.atom2.asymmetricParentAtom.bondDistanceCriteria + 0.56)
        
        let bondLength: Double = length(periodicSeparationVector)
        if (bondLength < bondCriteria)
        {
          // Type atom as 'Double'
          if (bondLength < 0.1)
          {
            bond.atom1.type = .duplicate
          }
          
          if (length(separationVector) > bondCriteria)
          {
            bond.boundaryType = .external
          }
          else
          {
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
    if self.drawUnitCell
    {
      return self.cell.unitCell
    }
    else
    {
      let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
      return boundaryBoxCell.unitCell
    }
  }
  
  public override var cellLengthA: Double
  {
    if self.drawUnitCell
    {
      return self.cell.a
    }
    else
    {
      let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
      return boundaryBoxCell.a
    }
  }
  
  public override var cellLengthB: Double
  {
    if self.drawUnitCell
    {
      return self.cell.b
    }
    else
    {
      let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
      return boundaryBoxCell.b
    }
  }
  
  public override var cellLengthC: Double
  {
    if self.drawUnitCell
    {
      return self.cell.c
    }
    else
    {
      let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
      return boundaryBoxCell.c
    }
  }
  
  public override var cellAngleAlpha: Double
  {
    if self.drawUnitCell
    {
      return self.cell.alpha
    }
    else
    {
      let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
      return boundaryBoxCell.alpha
    }
  }
  
  public override var cellAngleBeta: Double
  {
    if self.drawUnitCell
    {
      return self.cell.beta
    }
    else
    {
      let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
      return boundaryBoxCell.beta
    }
  }
  
  public override var cellAngleGamma: Double
  {
    if self.drawUnitCell
    {
      return self.cell.gamma
    }
    else
    {
      let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
      return boundaryBoxCell.gamma
    }
  }
  
  public override var cellVolume: Double
  {
    if self.drawUnitCell
    {
      return self.cell.volume
    }
    else
    {
      let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
      return boundaryBoxCell.volume
    }
  }
  
  public override var cellPerpendicularWidthsX: Double
  {
    if self.drawUnitCell
    {
      return self.cell.perpendicularWidths.x
    }
    else
    {
      let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
      return boundaryBoxCell.perpendicularWidths.x
    }
  }
  
  public override var cellPerpendicularWidthsY: Double
  {
    if self.drawUnitCell
    {
      return self.cell.perpendicularWidths.y
    }
    else
    {
      let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
      return boundaryBoxCell.perpendicularWidths.y
    }
  }
  
  public override var cellPerpendicularWidthsZ: Double
  {
    if self.drawUnitCell
    {
      return self.cell.perpendicularWidths.z
    }
    else
    {
      let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
      return boundaryBoxCell.perpendicularWidths.z
    }
  }
  
  
  
  // for period: transformed, for non-periodic: untransformed
  public override var boundingBox: SKBoundingBox
  {
    
    var minimum: double3 = double3(x: Double.greatestFiniteMagnitude, y: Double.greatestFiniteMagnitude, z: Double.greatestFiniteMagnitude)
    var maximum: double3 = double3(x: -Double.greatestFiniteMagnitude, y: -Double.greatestFiniteMagnitude, z: -Double.greatestFiniteMagnitude)
    
    if self.drawUnitCell
    {
      minimum = self.cell.enclosingBoundingBox.minimum
      maximum = self.cell.enclosingBoundingBox.maximum
    }
      
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
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
            let cartesianPosition: double3 = atom.position + cell.unitCell * double3(x: Double(k1), y: Double(k2), z: Double(k3))
            minimum.x = min(minimum.x, cartesianPosition.x)
            minimum.y = min(minimum.y, cartesianPosition.y)
            minimum.z = min(minimum.z, cartesianPosition.z)
            maximum.x = max(maximum.x, cartesianPosition.x)
            maximum.y = max(maximum.y, cartesianPosition.y)
            maximum.z = max(maximum.z, cartesianPosition.z)
          }
        }
      }
    }
    
    return SKBoundingBox(minimum: minimum, maximum: maximum)
  }

  public override var transformedBoundingBox: SKBoundingBox
  {
    if self.drawUnitCell
    {
      return self.boundingBox
    }
    else
    {
      let currentBoundingBox: SKBoundingBox = self.cell.boundingBox
    
      let transformation = double4x4.init(transformation: double4x4(self.orientation), aroundPoint: currentBoundingBox.center)
      let transformedBoundingBox: SKBoundingBox = currentBoundingBox.adjustForTransformation(transformation)
    
      return transformedBoundingBox
    }
  }
  
  public override var renderAtoms: [RKInPerInstanceAttributesAtoms]
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
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms](repeating: RKInPerInstanceAttributesAtoms(), count: numberOfReplicas * atoms.count)
    
    index = 0
    
    for (asymetricIndex, asymetricAtom) in asymmetricAtoms.enumerated()
    {
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      
      for copy in copies
      {
        let pos: double3 = copy.position
        copy.asymmetricIndex = asymetricIndex
        
        for k1 in minimumReplicaX...maximumReplicaX
        {
          for k2 in minimumReplicaY...maximumReplicaY
          {
            for k3 in minimumReplicaZ...maximumReplicaZ
            {
              let cartesianPosition: double3 = pos + cell.unitCell * double3(x: Double(k1), y: Double(k2), z: Double(k3))
              
              let w: Double = (copy.asymmetricParentAtom.isVisible && copy.asymmetricParentAtom.isVisibleEnabled && copy.asymmetricParentAtom.symmetryType != .container) ? 1.0 : -1.0
              let atomPosition: float4 = float4(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: Float(w))
              
              let radius: Double = copy.asymmetricParentAtom.drawRadius
              let ambient: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
              let diffuse: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
              let specular: NSColor = self.atomSpecularColor
              
              data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: float4(color: ambient), diffuse: float4(color: diffuse), specular: float4(color: specular), scale: Float(radius))
              index = index + 1
            }
          }
        }
      }
    }
    return data
  }
  
  public override var renderSelectedAtoms: [RKInPerInstanceAttributesAtoms]
  {
    var index: Int
    
    let numberOfReplicas: Int = self.cell.numberOfReplicas
    
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.allSelectedNodes.compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    
    var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms](repeating: RKInPerInstanceAttributesAtoms(), count: numberOfReplicas * atoms.count)
    
    index = 0
    
    for asymetricAtom in asymmetricAtoms
    {
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      for copy in copies
      {
        let pos: double3 = copy.position + asymetricAtom.displacement
        
        for k1 in minimumReplicaX...maximumReplicaX
        {
          for k2 in minimumReplicaY...maximumReplicaY
          {
            for k3 in minimumReplicaZ...maximumReplicaZ
            {
              let cartesianPosition: double3 = pos + cell.unitCell * double3(x: Double(k1), y: Double(k2), z: Double(k3))
              
              let w: Double = (copy.asymmetricParentAtom.isVisible && copy.asymmetricParentAtom.isVisibleEnabled && asymetricAtom.symmetryType != .container) ? 1.0 : -1.0
              let atomPosition: float4 = float4(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: Float(w))
              
              let radius: Double = copy.asymmetricParentAtom.drawRadius
              let ambient: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
              let diffuse: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
              let specular: NSColor = self.atomSpecularColor
              
              data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: float4(color: ambient), diffuse: float4(color: diffuse), specular: float4(color: specular), scale: Float(radius))
              index = index + 1
            }
          }
        }
      }
    }
    return data
  }
  
  // used for 'selectInRectangle'
  public override var atomPositions: [double3]
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
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    var data: [double3] = [double3](repeating: double3(), count: numberOfReplicas * atoms.count)
    
    index = 0
    for atom in atoms
    {
      let pos: double3 = atom.position
      
      for k1 in minimumReplicaX...maximumReplicaX
      {
        for k2 in minimumReplicaY...maximumReplicaY
        {
          for k3 in minimumReplicaZ...maximumReplicaZ
          {
            let rotationMatrix: double4x4 =  double4x4(transformation: double4x4(simd_quatd: self.orientation), aroundPoint: self.cell.boundingBox.center)
            
            let cartesianPosition: double3 = pos + cell.unitCell * double3(x: Double(k1), y: Double(k2), z: Double(k3))
            
            let w: Double = (atom.asymmetricParentAtom.isVisible && atom.asymmetricParentAtom.isVisibleEnabled)  ? 1.0 : -1.0
            let position: double4 = rotationMatrix * double4(x: cartesianPosition.x, y: cartesianPosition.y, z: cartesianPosition.z, w: w)
            
            data[index] = double3(x: position.x, y: position.y, z: position.z)
            index = index + 1
          }
        }
      }
    }
    return data
  }
  
  public override var renderInternalBonds: [RKInPerInstanceAttributesBonds]
  {
    var data: [RKInPerInstanceAttributesBonds] = [RKInPerInstanceAttributesBonds]()
    
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    for bond in bonds.arrangedObjects
    {
      if bond.atom1.type == .copy &&  bond.atom2.type == .copy && bond.boundaryType == .internal
      {
        for k1 in minimumReplicaX...maximumReplicaX
        {
          for k2 in minimumReplicaY...maximumReplicaY
          {
            for k3 in minimumReplicaZ...maximumReplicaZ
            {
              let pos1: double3 = bond.atom1.position + cell.unitCell * double3(x: Double(k1), y: Double(k2), z: Double(k3))
              let pos2: double3 = bond.atom2.position + cell.unitCell * double3(x: Double(k1), y: Double(k2), z: Double(k3))
              let bondLength: Double = length(pos2-pos1)
              
              let drawRadius1: Double = bond.atom1.asymmetricParentAtom.drawRadius / bondLength
              let drawRadius2: Double = bond.atom2.asymmetricParentAtom.drawRadius / bondLength
              
              let color1: NSColor = bond.atom1.asymmetricParentAtom.color
              let color2: NSColor = bond.atom2.asymmetricParentAtom.color
              
              let w: Double = ((bond.atom1.asymmetricParentAtom.isVisible && bond.atom2.asymmetricParentAtom.isVisible) &&
                (bond.atom1.asymmetricParentAtom.isVisibleEnabled && bond.atom2.asymmetricParentAtom.isVisibleEnabled)) ? 1.0 : -1.0
              data.append(RKInPerInstanceAttributesBonds(position1: float4(xyz: pos1, w: w),
                                                         position2: float4(x: pos2.x, y: pos2.y, z: pos2.z, w: w),
                                                         color1: float4(color: color1),
                                                         color2: float4(color: color2),
                                                         scale: float4(x: drawRadius1, y: 1.0, z: drawRadius2, w: drawRadius1/drawRadius2)))
            }
          }
        }
      }
    }
    return data
  }
  
  
  public override var renderExternalBonds: [RKInPerInstanceAttributesBonds]
  {
    return []
  }
  
  // MARK: Measuring distance, angle, and dihedral-angles
  // ===============================================================================================================================
  
  override public func bondVector(_ bond: SKBondNode) -> double3
  {
    let atom1: double3 = bond.atom1.position
    let atom2: double3 = bond.atom2.position
    let dr: double3 = atom2 - atom1
    return self.cell.applyUnitCellBoundaryCondition(dr)
  }
  
  override public func bondLength(_ bond: SKBondNode) -> Double
  {
    let atom1: double3 = bond.atom1.position
    let atom2: double3 = bond.atom2.position
    let dr: double3 = atom2 - atom1
    return length(self.cell.applyUnitCellBoundaryCondition(dr))
  }
  
  override public func distance(_ atom1: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3), _ atom2: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3)) -> Double
  {
    let posB: double3 = atom1.copy.position
    let posA: double3 = atom2.copy.position
    let dr: double3 = abs(cell.applyFullCellBoundaryCondition(posB - posA))
    return length(dr)
  }
  
  public override func bendAngle(_ atomA: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3), _ atomB: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3), _ atomC: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3)) -> Double
  {
    let posA: double3 = atomA.copy.position
    let posB: double3 = atomB.copy.position
    let posC: double3 = atomC.copy.position
      
    let dr1: double3 = cell.applyFullCellBoundaryCondition(posA - posB)
    let dr2: double3 = cell.applyFullCellBoundaryCondition(posC - posB)
      
    let vectorAB: double3 = normalize(dr1)
    let vectorBC: double3 = normalize(dr2)
      
    return acos(dot(vectorAB, vectorBC))
  }
  
  public override func dihedralAngle(_ atomA: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3), _ atomB: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3), _ atomC: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3), _ atomD: (structure: RKRenderStructure, copy: SKAtomCopy, replicaPosition: int3)) -> Double
  {
    let posA: double3 = atomA.copy.position
    let posB: double3 = atomB.copy.position
    let posC: double3 = atomC.copy.position
    let posD: double3 = atomD.copy.position
      
    let Dab = cell.applyFullCellBoundaryCondition(posA - posB)
    let Dbc = normalize(cell.applyFullCellBoundaryCondition(posC - posB))
    let Dcd = cell.applyFullCellBoundaryCondition(posD - posC)
      
    let dotAB = dot(Dab,Dbc)
    let dotCD = dot(Dcd,Dbc)
      
    let dr = normalize(Dab - dotAB * Dbc)
    let ds = normalize(Dcd - dotCD * Dbc)
      
    // compute Cos(Phi)
    // Phi is defined in protein convention Phi(trans)=Pi
    let cosPhi: Double = dot(dr,ds)
      
    let Pb: double3 = cross(Dbc, Dab)
    let Pc: double3 = cross(Dbc, Dcd)
      
    let sign: Double = dot(Dbc, cross(Pb, Pc))
      
    let Phi: Double = sign > 0.0 ? fabs(acos(cosPhi)) : -fabs(acos(cosPhi))
      
    if(Phi<0.0)
    {
      return Phi + 2.0*Double.pi
    }
    return Phi
  }
  
  

  // MARK: -
  // MARK: unit cell
  
  public override var renderUnitCellSpheres: [RKInPerInstanceAttributesAtoms]
  {
    var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms]()
    
    let boundingBoxWidths: double3 = self.cell.boundingBox.widths
    let scale: Double = 0.0025 * max(boundingBoxWidths.x,boundingBoxWidths.y,boundingBoxWidths.z)
    
    for k1 in self.cell.minimumReplica.x...self.cell.maximumReplica.x+1
    {
      for k2 in self.cell.minimumReplica.y...self.cell.maximumReplica.y+1
      {
        for k3 in self.cell.minimumReplica.z...self.cell.maximumReplica.z+1
        {
          let cartesianPosition: double3 = cell.convertToCartesian(double3(x: Double(k1), y: Double(k2), z: Double(k3)))
          let spherePosition: float4 = float4(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: 1.0)
          
          let ambient: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
          let diffuse: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
          let specular: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
          
          data.append(RKInPerInstanceAttributesAtoms(position: spherePosition, ambient: float4(color: ambient), diffuse: float4(color: diffuse), specular: float4(color: specular), scale: Float(scale)))
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
    
    let boundingBoxWidths: double3 = self.cell.boundingBox.widths
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
            
            let pos1: double3 = cell.convertToCartesian(double3(x: Double(k1), y: Double(k2), z: Double(k3)))
            cylinder.position1=float4(x: Float(pos1.x + self.cell.origin.x), y: Float(pos1.y + self.cell.origin.y), z: Float(pos1.z + self.cell.origin.z), w: 1.0)
            let pos2: double3 = cell.convertToCartesian(double3(x: Double(k1+1), y: Double(k2), z: Double(k3)))
            cylinder.position2=float4(x: Float(pos2.x + self.cell.origin.x), y: Float(pos2.y + self.cell.origin.y), z: Float(pos2.z + self.cell.origin.z), w: 1.0)
            
            data.append(RKInPerInstanceAttributesBonds(position1: float4(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0),
                                                       position2: float4(x: pos2.x, y: pos2.y, z: pos2.z, w: 1.0),
                                                       color1: float4(color: color1),
                                                       color2: float4(color: color2),
                                                       scale: float4(x: Float(scale), y: 1.0, z: Float(scale), w: 1.0)))
          }
          
          if(k2 <= self.cell.maximumReplica[1])
          {
            var cylinder: RKBondVertex = RKBondVertex()
            
            let pos1: double3 = cell.convertToCartesian(double3(x: Double(k1), y: Double(k2), z: Double(k3)))
            cylinder.position1=float4(x: Float(pos1.x + self.cell.origin.x), y: Float(pos1.y + self.cell.origin.y), z: Float(pos1.z + self.cell.origin.z), w: 1.0)
            let pos2: double3 = cell.convertToCartesian(double3(x: Double(k1), y: Double(k2+1), z: Double(k3)))
            cylinder.position2=float4(x: Float(pos2.x + self.cell.origin.x), y: Float(pos2.y + self.cell.origin.y), z: Float(pos2.z + self.cell.origin.z), w: 1.0)
            
            data.append(RKInPerInstanceAttributesBonds(position1: float4(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0),
                                                       position2: float4(x: pos2.x, y: pos2.y, z: pos2.z, w: 1.0),
                                                       color1: float4(color: color1),
                                                       color2: float4(color: color2),
                                                       scale: float4(x: Float(scale), y: 1.0, z: Float(scale), w: 1.0)))
          }
          
          if(k3 <= self.cell.maximumReplica[2])
          {
            var cylinder: RKBondVertex = RKBondVertex()
            
            let pos1: double3 = cell.convertToCartesian(double3(x: Double(k1), y: Double(k2), z: Double(k3)))
            cylinder.position1=float4(x: Float(pos1.x + self.cell.origin.x), y: Float(pos1.y + self.cell.origin.y), z: Float(pos1.z + self.cell.origin.z), w: 1.0)
            let pos2: double3 = cell.convertToCartesian(double3(x: Double(k1), y: Double(k2), z: Double(k3+1)))
            cylinder.position2=float4(x: Float(pos2.x + self.cell.origin.x), y: Float(pos2.y + self.cell.origin.y), z: Float(pos2.z + self.cell.origin.z), w: 1.0)
            
            data.append(RKInPerInstanceAttributesBonds(position1: float4(x: Float(pos1.x), y: Float(pos1.y), z: Float(pos1.z), w: 1.0),
                                                       position2: float4(x: pos2.x, y: pos2.y, z: pos2.z, w: 1.0),
                                                       color1: float4(color: color1),
                                                       color2: float4(color: color2),
                                                       scale: float4(x: Float(scale), y: 1.0, z: Float(scale), w: 1.0)))
          }
        }
      }
    }
    
    return data
  }
  
  
  
  // MARK: -
  // MARK: Space group operations
  
  public override var canRemoveSymmetry: Bool
  {
    return spaceGroup.spaceGroupSetting.number > 1
  }
  
  public override var crystallographicPositions: [(double3, Int)]
  {
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    var data: [(double3, Int)] = [(double3,Int)](repeating: (double3(),0), count: atoms.count)
    
    for (index, atom) in atoms.enumerated()
    {
      data[index] = (fract(cell.inverseUnitCell * atom.position), atom.asymmetricParentAtom.elementIdentifier)
    }
    return data
  }
  
  public override var potentialParameters: [double2]
  {
    var index: Int
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    var data: [double2] = [double2](repeating: double2(), count: atoms.count)
    
    index = 0
    for atom in atoms
    {
      data[index] = atom.asymmetricParentAtom.potentialParameters
      
      index = index + 1
    }
    return data
  }
  
  public var flattenedHierarchy: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)
  {
    let atomNodes: [SKAtomTreeNode] = self.atoms.flattenedLeafNodes().filter{$0.representedObject.symmetryType == .asymmetric}
    for node in atomNodes
    {
      node.childNodes = []
    }
    
    return (cell: self.cell, spaceGroup: self.spaceGroup, atoms: SKAtomTreeController(nodes: atomNodes), bonds: self.bonds)
  }
  
  public func primitive(colorSets: SKColorSets, forceFieldSets: SKForceFieldSets) -> (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    if let primitive: (cell: SKSymmetryCell, primitiveAtoms: [(fractionalPosition: double3, type: Int)]) = SKSpacegroup.SKFindPrimitive(unitCell: self.cell.unitCell, atoms: self.crystallographicPositions, symmetryPrecision: 1e-3)
    {
      let primitiveCell = SKCell(a: primitive.cell.a, b: primitive.cell.b, c: primitive.cell.c, alpha: primitive.cell.alpha, beta: primitive.cell.beta, gamma: primitive.cell.gamma)
      
      let primitiveSpaceGroup = SKSpacegroup(HallNumber: 1)
      let primitiveAtoms = SKAtomTreeController()
      
      let cell: double3x3 = primitiveCell.unitCell
      for asymmetricAtom in primitive.primitiveAtoms
      {
        let displayName: String = PredefinedElements.sharedInstance.elementSet[asymmetricAtom.type].chemicalSymbol
        let color: NSColor = colorSets[self.atomColorSchemeIdentifier]?[displayName] ?? NSColor.black
        let drawRadius: Double = self.drawRadius(elementId: asymmetricAtom.type)
        let bondDistanceCriteria: Double = forceFieldSets[self.atomForceFieldIdentifier]?[displayName]?.userDefinedRadius ?? 1.0
        
        let CartesianPosition = cell * asymmetricAtom.fractionalPosition
        
        let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: displayName, elementId: asymmetricAtom.type, uniqueForceFieldName: displayName, position: CartesianPosition, charge: 0.0, color: color, drawRadius: drawRadius, bondDistanceCriteria: bondDistanceCriteria)
        atom.symmetryType = .asymmetric
        let node = SKAtomTreeNode(representedObject: atom)
        
        let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: atom, position: CartesianPosition)
        newAtom.type = .copy
        atom.copies.append(newAtom)
        
        primitiveAtoms.appendNode(node, atArrangedObjectIndexPath: [])
      }
      
      self.tag(atoms: primitiveAtoms)
      
      let atomList: [SKAtomCopy] = primitiveAtoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
      
      let primitiveBonds: SKBondSetController = SKBondSetController(arrangedObjects: self.computeBonds(cell: primitiveCell, atomList: atomList))
      
      return (cell: primitiveCell, spaceGroup: primitiveSpaceGroup, atoms: primitiveAtoms, bonds: primitiveBonds)
    }
    
    return nil
  }
  
  public func imposedSymmetry(colorSets: SKColorSets, forceFieldSets: SKForceFieldSets) -> (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    if let symmetry: (hall: Int, origin: double3, cell: SKSymmetryCell, changeOfBasis: SKChangeOfBasis, atoms: [(fractionalPosition: double3, type: Int)], asymmetricAtoms: [(fractionalPosition: double3, type: Int)]) = SKSpacegroup.SKFindSpaceGroup(unitCell: self.cell.unitCell, atoms: self.crystallographicPositions, symmetryPrecision: 1e-3)
    {
      
      let cellWithSymmetry = SKCell(a: symmetry.cell.a, b: symmetry.cell.b, c: symmetry.cell.c, alpha: symmetry.cell.alpha, beta: symmetry.cell.beta, gamma: symmetry.cell.gamma)
      let spaceGroupWithSymmetry = SKSpacegroup(HallNumber: symmetry.hall)
      let atomsWithSymmetry = SKAtomTreeController()
      
      for asymmetricAtom in symmetry.asymmetricAtoms
      {
        let displayName: String = PredefinedElements.sharedInstance.elementSet[asymmetricAtom.type].chemicalSymbol
        let color: NSColor = colorSets[self.atomColorSchemeIdentifier]?[displayName] ?? NSColor.black
        let drawRadius: Double = self.drawRadius(elementId: asymmetricAtom.type)
        let bondDistanceCriteria: Double = forceFieldSets[self.atomForceFieldIdentifier]?[displayName]?.userDefinedRadius ?? 1.0
        let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: displayName, elementId: asymmetricAtom.type, uniqueForceFieldName: displayName, position: asymmetricAtom.fractionalPosition, charge: 0.0, color: color, drawRadius: drawRadius, bondDistanceCriteria: bondDistanceCriteria)
        atom.symmetryType = .asymmetric
        let node = SKAtomTreeNode(representedObject: atom)
        
        let images: [double3] = spaceGroupWithSymmetry.listOfSymmetricPositions(atom.position)
        for image in images
        {
          let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: atom, position: cellWithSymmetry.unitCell * fract(image))
          newAtom.type = .copy
          atom.copies.append(newAtom)
        }
        
        atom.position = cellWithSymmetry.unitCell * atom.position
        
        atomsWithSymmetry.appendNode(node, atArrangedObjectIndexPath: [])
      }
      
      self.tag(atoms: atomsWithSymmetry)
      
      let atomList: [SKAtomCopy] = atomsWithSymmetry.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
      
      atomsWithSymmetry.flattenedLeafNodes().compactMap{$0.representedObject}.forEach{atom in
        let elementId: Int = atom.elementIdentifier
        atom.bondDistanceCriteria = PredefinedElements.sharedInstance.elementSet[elementId].covalentRadius
      }
      
      let bondsWithSymmetry: SKBondSetController = SKBondSetController(arrangedObjects: self.computeBonds(cell: cellWithSymmetry, atomList: atomList))
      
      return (cell: cellWithSymmetry, spaceGroup: spaceGroupWithSymmetry, atoms: atomsWithSymmetry, bonds: bondsWithSymmetry)
    }
    
    return nil
  }
  
  public var removedSymmetry: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)
  {
    // copy the structure for undo (via the atoms, and bonds-properties)
    let crystal: ProteinCrystal =  self.copy() as! ProteinCrystal
    
    // make copy of the atom-structure, leave atoms invariant
    let atomsWithRemovedSymmetry: SKAtomTreeController = crystal.atoms
    
    // remove all bonds that are between 'doubles'
    let atomBonds: SKBondSetController = SKBondSetController(arrangedObjects: Set(crystal.bonds.arrangedObjects.filter{$0.atom1.type == .copy &&  $0.atom2.type == .copy}))
    
    let atomNodes: [SKAtomTreeNode] = atomsWithRemovedSymmetry.flattenedLeafNodes()
    
    for atomNode in atomNodes
    {
      atomNode.isGroup = true
      let atom = atomNode.representedObject
      
      let copies: [SKAtomCopy] = atom.copies.filter{$0.type == .copy}
      for copy in copies
      {
        let newAtom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: atom.displayName, elementId: atom.elementIdentifier, uniqueForceFieldName: atom.uniqueForceFieldName, position: copy.position, charge: atom.charge, color: atom.color, drawRadius: atom.drawRadius, bondDistanceCriteria: atom.bondDistanceCriteria)
        newAtom.symmetryType = .asymmetric
        copy.asymmetricParentAtom = newAtom
        newAtom.copies = [copy]
        
        let child: SKAtomTreeNode = SKAtomTreeNode(representedObject: newAtom)
        child.append(inParent: atomNode)
      }
      atom.copies = []
      atom.symmetryType = .container
    }
    
    // tag atoms for selection in rendering
    self.tag(atoms: atomsWithRemovedSymmetry)
    
    
    // set the 'bonds'-array of the atoms, since they are empty for a structure with symmetry
    let atomCopies: [SKAtomCopy] = atomsWithRemovedSymmetry.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    for atomCopy in atomCopies
    {
      atomCopy.bonds = []
    }
    
    for bond in atomBonds.arrangedObjects
    {
      // make the list of bonds the atoms are involved in
      bond.atom1.bonds.insert(bond)
      bond.atom2.bonds.insert(bond)
    }
    
    // set space group to P1 after removal of symmetry
    return (cell: self.cell, spaceGroup: SKSpacegroup(HallNumber: 1), atoms: atomsWithRemovedSymmetry, bonds: atomBonds)
  }
  
  public override var superCell: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)
  {
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    let atomCopies: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    let spaceGroup = SKSpacegroup(HallNumber: 1)
    let newCell = SKCell(superCell: self.cell)
    
    let dx: Int = Int(maximumReplicaX - minimumReplicaX)
    let dy: Int = Int(maximumReplicaY - minimumReplicaY)
    let dz: Int = Int(maximumReplicaZ - minimumReplicaZ)
    
    let superCellAtoms: SKAtomTreeController = SKAtomTreeController()
    
    for k1 in 0...dx
    {
      for k2 in 0...dy
      {
        for k3 in 0...dz
        {
          for atom in atomCopies
          {
            let pos: double3 =  self.cell.inverseUnitCell * atom.position
            let fractionalPosition: double3 = double3(x: (pos.x + Double(k1)) / Double(dx + 1),
                                                      y: (pos.y + Double(k2)) / Double(dy + 1),
                                                      z: (pos.z + Double(k3)) / Double(dz + 1))
            let CartesianPosition = newCell.unitCell * fractionalPosition
            let newAtom: SKAsymmetricAtom = SKAsymmetricAtom(atom: atom.asymmetricParentAtom)
            newAtom.position = CartesianPosition
            
            let copy: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: newAtom, position: CartesianPosition)
            copy.type = .copy
            newAtom.copies.append(copy)
            
            let node = SKAtomTreeNode(representedObject: newAtom)
            superCellAtoms.appendNode(node, atArrangedObjectIndexPath: [])
          }
        }
      }
    }
    
    self.tag(atoms: superCellAtoms)
    
    let atomList: [SKAtomCopy] = superCellAtoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    
    //superCellAtoms.flattenedLeafNodes().flatMap{$0.representedObject}.forEach{atom in
    //  let elementId: Int = atom.elementIdentifier
    //  atom.bondDistanceCriteria = PredefinedElements.sharedInstance.elementSet[elementId].covalentRadius
    //}
    
    let bonds: SKBondSetController = SKBondSetController(arrangedObjects: self.computeBonds(cell: cell, atomList: atomList))
    
    return (cell: newCell, spaceGroup: spaceGroup, atoms: superCellAtoms, bonds: bonds)
  }
  
  public var wrapAtomsToCell: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)
  {
    // copy the structure for undo (via the atoms, and bonds-properties)
    let crystal: ProteinCrystal =  self.copy() as! ProteinCrystal
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = crystal.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    
    for asymetricAtom in asymmetricAtoms
    {
      asymetricAtom.position = crystal.cell.unitCell * fract(crystal.cell.inverseUnitCell * asymetricAtom.position)
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      
      for copy in copies
      {
        copy.position = crystal.cell.unitCell * fract(crystal.cell.inverseUnitCell * copy.position)
      }
    }
    
    // tag atoms for selection in rendering
    self.tag(atoms: crystal.atoms)
    
    crystal.reComputeBoundingBox()
    
    crystal.reComputeBonds()
    
    // set space group to P1 after removal of symmetry
    return (cell: crystal.cell, spaceGroup: crystal.spaceGroup, atoms: crystal.atoms, bonds: crystal.bonds)
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
    
    var computedBonds: Set<SKBondNode> = []
    var totalCount: Int
    
    let numberOfReplicas: double3 = double3(Double(structureCell.maximumReplicaX - structureCell.minimumReplicaX + 1),
                                            Double(structureCell.maximumReplicaY - structureCell.minimumReplicaY + 1),
                                            Double(structureCell.maximumReplicaZ - structureCell.minimumReplicaZ + 1))
    
    let perpendicularWidths: double3 = structureCell.boundingBox.widths/numberOfReplicas + double3(x: 0.1, y: 0.1, z: 0.1)
    guard perpendicularWidths.x > 0.0001 && perpendicularWidths.x > 0.0001 && perpendicularWidths.x > 0.0001 else {return []}
    
    let numberOfCells: [Int] = [Int(perpendicularWidths.x/cutoff),Int(perpendicularWidths.y/cutoff),Int(perpendicularWidths.z/cutoff)]
    let totalNumberOfCells: Int = numberOfCells[0] * numberOfCells[1] * numberOfCells[2]
    let cutoffVector: double3 = double3(x: perpendicularWidths.x/Double(numberOfCells[0]), y: perpendicularWidths.y/Double(numberOfCells[1]), z: perpendicularWidths.z/Double(numberOfCells[2]))
    
    if ((numberOfCells[0]>=3) &&  (numberOfCells[1]>=3) && (numberOfCells[2]>=3))
    {
      
      var head: [Int] = [Int](repeating: -1, count: totalNumberOfCells)
      var list: [Int] = [Int](repeating: -1, count: atoms.count)
      
      // create cell-list based on the bond-cutoff
      for i in 0..<atoms.count
      {
        let position: double3 = atoms[i].position - structureCell.boundingBox.minimum
        
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
              let posA: double3 = atoms[i].position
              
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
                    let posB: double3 = atoms[j].position
                    let separationVector: double3 = posA - posB
                    let periodicSeparationVector: double3 = structureCell.applyUnitCellBoundaryCondition(posA - posB)
                    
                    let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.56)
                    
                    let bondLength: Double = length(periodicSeparationVector)
                    if (bondLength < bondCriteria)
                    {
                      // Type atom as 'Double'
                      if (bondLength < 0.1)
                      {
                        atoms[i].type = .duplicate
                      }
                      if (length(separationVector) > bondCriteria)
                      {
                        let bond: SKBondNode = SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .external)
                        computedBonds.insert(bond)
                      }
                      else
                      {
                        let bond: SKBondNode = SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .internal)
                        computedBonds.insert(bond)
                      }
                    }
                  }
                  j=list[j]
                }
              }
              i=list[i]
            }
            
            bondProgress.completedUnitCount = bondProgress.completedUnitCount + 1
            
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
      let bondProgress: Progress = Progress(totalUnitCount: Int64(atoms.count * (atoms.count - 1) / 2))
      bondProgress.completedUnitCount = 0
      
      for i in 0..<atoms.count
      {
        let posA: double3 = atoms[i].position
        
        for j in i+1..<atoms.count
        {
          let posB: double3 = atoms[j].position
          
          let separationVector: double3 = posA - posB
          let periodicSeparationVector: double3 = structureCell.applyUnitCellBoundaryCondition(posA - posB)
          
          let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.56)
          
          let bondLength: Double = length(periodicSeparationVector)
          if (bondLength < bondCriteria)
          {
            // Type atom as 'Double'
            if (bondLength < 0.1)
            {
              atoms[i].type = .duplicate
            }
            if (length(separationVector) > bondCriteria)
            {
              let bond: SKBondNode = SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .external)
              computedBonds.insert(bond)
            }
            else
            {
              let bond: SKBondNode = SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .internal)
              computedBonds.insert(bond)
            }
          }
        }
        
        bondProgress.completedUnitCount = bondProgress.completedUnitCount + 1
        
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
    return ProteinCrystal.RecomputeBondsOperation(structure: structure, windowController: windowController)
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
  
  // MARK: RKRenderAdsorptionSurfaceStructure
  // ===============================================================================================================================
  
  public override var atomUnitCellPositions: [double3]
  {
    var index: Int
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    var data: [double3] = [double3](repeating: double3(), count: atoms.count)
    
    index = 0
    for atom in atoms
    {
      data[index] = fract(cell.inverseUnitCell * atom.position)
        index = index + 1
    }
    return data
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public override func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(ProteinCrystal.classVersionNumber)
    super.binaryEncode(to: encoder)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > ProteinCrystal.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    try super.init(fromBinary: decoder)
  }
}
