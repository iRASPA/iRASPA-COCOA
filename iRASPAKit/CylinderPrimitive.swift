/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

import Cocoa
import RenderKit
import SymmetryKit
import BinaryCodable
import simd

public final class CylinderPrimitive: Structure, RKRenderCylinderObjectsSource
{
  private var versionNumber: Int = 1
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
    atoms.insertNode(atomTreeNode, inItem: nil, atIndex: 0)
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
    case is MolecularCrystal, is ProteinCrystal, is Molecule, is Protein:
      self.atoms.flattenedLeafNodes().forEach{
      let pos = $0.representedObject.position
          $0.representedObject.position = self.cell.convertToFractional(pos)
        }
      break
    case is EllipsoidPrimitive, is CylinderPrimitive, is PolygonalPrismPrimitive:
      if !structure.primitiveIsFractional
      {
        self.atoms.flattenedLeafNodes().forEach{
        let pos = $0.representedObject.position
            $0.representedObject.position = self.cell.convertToFractional(pos)
        }
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
    return .cylinderPrimitive
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
  
  public var renderCylinderObjects: [RKInPerInstanceAttributesAtoms]
  {
    if primitiveIsFractional
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
                
                data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius))
                index = index + 1
              }
            }
          }
        }
      }
      return data
    }
    else
    {
      var index: Int
      
      // only use leaf-nodes
      let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
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
          
          data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius))
          index = index + 1
        }
      }
      return data
    }
  }
  
  // MARK: -
  // MARK: cell property-wrapper
  
  public override var unitCell: double3x3
  {
    if primitiveIsFractional
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
    if primitiveIsFractional
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
    if primitiveIsFractional
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
    if primitiveIsFractional
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
    if primitiveIsFractional
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
    if primitiveIsFractional
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
    if primitiveIsFractional
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
    if primitiveIsFractional
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
    if primitiveIsFractional
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
    if primitiveIsFractional
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
    if primitiveIsFractional
    {
      return self.cell.perpendicularWidths.z
    }
    else
    {
      let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
      return boundaryBoxCell.perpendicularWidths.z
    }
  }
  
  public override var boundingBox: SKBoundingBox
  {
    if primitiveIsFractional
    {
      let currentBoundingBox: SKBoundingBox = self.cell.boundingBox
      
      let modelMatrix: double4x4 = double4x4(transformation: double4x4(simd_quatd: self.orientation), aroundPoint: currentBoundingBox.center, withTranslation: SIMD3<Double>(0.0,0.0,0.0))
      
      let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
      let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
      let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
      
      let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
      let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
      let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
      
      let cylinderVertices: [RKVertex] = MetalCylinderGeometry(r: 1.0, s: self.primitiveNumberOfSides).vertices
      
      // only use leaf-nodes
      let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
      
      var minimum: SIMD3<Double> = SIMD3<Double>(x: Double.greatestFiniteMagnitude, y: Double.greatestFiniteMagnitude, z: Double.greatestFiniteMagnitude)
      var maximum: SIMD3<Double> = SIMD3<Double>(x: -Double.greatestFiniteMagnitude, y: -Double.greatestFiniteMagnitude, z: -Double.greatestFiniteMagnitude)
      
      
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
                
                for vertex in cylinderVertices
                {
                  let vertexPosition: SIMD4<Double> = SIMD4<Double>(Double(vertex.position.x), Double(vertex.position.y), Double(vertex.position.z), Double(vertex.position.w))
                  
                  let transformationMatrix = double4x4(Double3x3: self.primitiveTransformationMatrix)
                  let primitiveModelMatrix = double4x4(simd_quatd: self.primitiveOrientation)
                  
                  let pos: SIMD4<Double> = modelMatrix * (primitiveModelMatrix * transformationMatrix * vertexPosition + SIMD4<Double>(cartesianPosition.x, cartesianPosition.y, cartesianPosition.z, 1.0))
                  
                  minimum = SIMD3<Double>(x: min(pos.x, minimum.x),
                                    y: min(pos.y, minimum.y),
                                    z: min(pos.z, minimum.z))
                  
                  maximum = SIMD3<Double>(x: max(pos.x, maximum.x),
                                    y: max(pos.y, maximum.y),
                                    z: max(pos.z, maximum.z))
                }
              }
            }
          }
        }
      }
      
      return SKBoundingBox(minimum: minimum, maximum: maximum)
    }
    else
    {
      let modelMatrix: double4x4 = double4x4(transformation: double4x4(simd_quatd: self.orientation), aroundPoint: SIMD3<Double>(0,0,0), withTranslation: SIMD3<Double>(0.0,0.0,0.0))
      
      let cylinderVertices: [RKVertex] = MetalCylinderGeometry(r: 1.0, s: self.primitiveNumberOfSides).vertices
      
      // only use leaf-nodes
      let asymmetricAtoms: [SKAsymmetricAtom] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}
      
      var minimum: SIMD3<Double> = SIMD3<Double>(x: Double.greatestFiniteMagnitude, y: Double.greatestFiniteMagnitude, z: Double.greatestFiniteMagnitude)
      var maximum: SIMD3<Double> = SIMD3<Double>(x: -Double.greatestFiniteMagnitude, y: -Double.greatestFiniteMagnitude, z: -Double.greatestFiniteMagnitude)
      
      
      for (asymetricIndex, asymetricAtom) in asymmetricAtoms.enumerated()
      {
        let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
        
        for copy in copies
        {
          let pos: SIMD3<Double> = copy.position
          copy.asymmetricIndex = asymetricIndex
          
          for vertex in cylinderVertices
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
  }
  
  public override var transformedBoundingBox: SKBoundingBox
  {
    return self.boundingBox
  }
  
  // MARK: -
  // MARK: Computing bonds
  
  public override func reComputeBonds()
  {
    let atomList: [SKAtomCopy] = self.atoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    atomList.forEach{$0.bonds.removeAll()}
    self.bonds.arrangedObjects = []
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
    
    let superDecoder = try container.superDecoder()
    try super.init(from: superDecoder)
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public override func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(CylinderPrimitive.classVersionNumber)
    
    super.binaryEncode(to: encoder)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > CylinderPrimitive.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    try super.init(fromBinary: decoder)
  }
}

