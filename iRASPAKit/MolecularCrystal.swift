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

import Foundation
import simd
import BinaryCodable
import RenderKit
import SymmetryKit
import LogViewKit
import SimulationKit
import OperationKit

public final class MolecularCrystal: Structure, RKRenderAtomSource, RKRenderBondSource, RKRenderUnitCellSource, RKRenderAdsorptionSurfaceSource, SpaceGroupProtocol
{  
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
  
  public required init(original structure: Structure)
  {
    super.init(original: structure)
  }
  
  public required init(clone structure: Structure)
  {
    super.init(clone: structure)
    
    switch(structure)
    {
    case is Protein, is ProteinCrystal, is Molecule, is MolecularCrystal,
         is EllipsoidPrimitive, is CylinderPrimitive, is PolygonalPrismPrimitive:
      //nothing to do
      break
    case is Crystal, is CrystalEllipsoidPrimitive, is CrystalCylinderPrimitive, is CrystalPolygonalPrismPrimitive:
      self.atomTreeController.flattenedLeafNodes().forEach{
      let pos = $0.representedObject.position
          $0.representedObject.position = self.cell.convertToCartesian(pos)
        }
    default:
      break
    }
    self.expandSymmetry()
    self.atomTreeController.tag()
    reComputeBoundingBox()
    reComputeBonds()
  }
  
  public override var colorAtomsWithBondColor: Bool
  {
    return (self.atomRepresentationType == .unity && self.bondColorMode == .uniform)
  }
  
  public override var materialType: SKStructure.Kind
  {
    return .molecularCrystal
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
  
  public override var isFractional: Bool
  {
    return false
  }
  
  // MARK: Rendering
  // =====================================================================
  
  public override var renderAtoms: [RKInPerInstanceAttributesAtoms]
  {
    var index: Int
    
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldDefiner)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
    
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
      let atomType: SKForceFieldType? = forceFieldSet?[asymetricAtom.uniqueForceFieldName]
      let typeIsVisible: Bool = atomType?.isVisible ?? true
      
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
              let cartesianPosition: SIMD3<Double> = pos + cell.unitCell * SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) + self.cell.contentShift
              
              let w: Double = (typeIsVisible && copy.asymmetricParentAtom.isVisible && copy.asymmetricParentAtom.isVisibleEnabled && asymetricAtom.symmetryType != .container) ? 1.0 : -1.0
              let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: Float(w))
              
              let radius: Double = copy.asymmetricParentAtom.drawRadius * copy.asymmetricParentAtom.occupancy
              let ambient: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
              var diffuse: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
              if(copy.asymmetricParentAtom.occupancy<1.0)
              {
                diffuse = NSColor.white
              }
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
    
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldDefiner)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
    
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    for (asymmetricIndex, asymmetricBond) in bondController.arrangedObjects.enumerated()
    {
      for bond in asymmetricBond.copies
      {
        if bond.boundaryType == .internal
        {
          let atom1: SKAtomCopy = bond.atom1
          let atom2: SKAtomCopy = bond.atom2
          let asymmetricAtom1: SKAsymmetricAtom = atom1.asymmetricParentAtom
          let asymmetricAtom2: SKAsymmetricAtom = atom2.asymmetricParentAtom
        
          let color1: NSColor = bond.atom1.asymmetricParentAtom.color
          let color2: NSColor = bond.atom2.asymmetricParentAtom.color
        
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
                let pos1: SIMD3<Double> = atom1.position + cell.unitCell * SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) + self.cell.contentShift
                let pos2: SIMD3<Double> = atom2.position + cell.unitCell * SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) + self.cell.contentShift
                let bondLength: Double = length(pos2-pos1)
              
                let drawRadius1: Double = asymmetricAtom1.drawRadius / bondLength
                let drawRadius2: Double = asymmetricAtom2.drawRadius / bondLength
              
                let w: Double = (asymmetricBond.isVisible && typeIsVisible1 && typeIsVisible2 && (asymmetricAtom1.isVisible && asymmetricAtom2.isVisible) &&                     (asymmetricAtom1.isVisibleEnabled && asymmetricAtom2.isVisibleEnabled)) ? 1.0 : -1.0
                data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(xyz: pos1, w: w),
                                                         position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: w),
                                                         color1: SIMD4<Float>(color: color1),
                                                         color2: SIMD4<Float>(color: color2),
                                                         scale: SIMD4<Float>(x: drawRadius1, y: 1.0, z: drawRadius2, w: drawRadius1/drawRadius2),
                                                         tag: UInt32(asymmetricIndex),
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
    return []
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
  
  
  // MARK: Rendering selection
  // =====================================================================
  
  public override var renderSelectedAtoms: [RKInPerInstanceAttributesAtoms]
  {
    var index: Int
    
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldDefiner)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
    
    let numberOfReplicas: Int = self.cell.numberOfReplicas
    
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.allSelectedNodes.compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    
    var data: [RKInPerInstanceAttributesAtoms] = [RKInPerInstanceAttributesAtoms](repeating: RKInPerInstanceAttributesAtoms(), count: numberOfReplicas * atoms.count)
    
    index = 0
    
    for (asymetricIndex,asymetricAtom) in asymmetricAtoms.enumerated()
    {
      let atomType: SKForceFieldType? = forceFieldSet?[asymetricAtom.uniqueForceFieldName]
      let typeIsVisible: Bool = atomType?.isVisible ?? true
      
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      for copy in copies
      {
        let pos: SIMD3<Double> = copy.position + asymetricAtom.displacement + self.cell.contentShift
        
        for k1 in minimumReplicaX...maximumReplicaX
        {
          for k2 in minimumReplicaY...maximumReplicaY
          {
            for k3 in minimumReplicaZ...maximumReplicaZ
            {
              let cartesianPosition: SIMD3<Double> = pos + cell.unitCell * SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3))
              
              let w: Double = (typeIsVisible && copy.asymmetricParentAtom.isVisible && copy.asymmetricParentAtom.isVisibleEnabled && asymetricAtom.symmetryType != .container) ? 1.0 : -1.0
              let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: Float(w))
              
              let radius: Double = copy.asymmetricParentAtom.drawRadius * copy.asymmetricParentAtom.occupancy
              let ambient: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
              let diffuse: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
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
     
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldDefiner)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
     
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
     
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
     
    let selectedAsymmetricBonds: [SKAsymmetricBond] = self.bondController.arrangedObjects[self.bondController.selectedObjects]
    for (asymmetricIndex, asymmetricBond) in selectedAsymmetricBonds.enumerated()
    {
      for bond in asymmetricBond.copies
      {
        if bond.boundaryType == .internal
        {
          let atom1: SKAtomCopy = bond.atom1
          let atom2: SKAtomCopy = bond.atom2
          let asymmetricAtom1: SKAsymmetricAtom = atom1.asymmetricParentAtom
          let asymmetricAtom2: SKAsymmetricAtom = atom2.asymmetricParentAtom
        
          let color1: NSColor = bond.atom1.asymmetricParentAtom.color
          let color2: NSColor = bond.atom2.asymmetricParentAtom.color
         
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
                let pos1: SIMD3<Double> = atom1.position + cell.unitCell * SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) + self.cell.contentShift
                let pos2: SIMD3<Double> = atom2.position + cell.unitCell * SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) + self.cell.contentShift
                let bondLength: Double = length(pos2-pos1)
               
                let drawRadius1: Double = asymmetricAtom1.drawRadius / bondLength
                let drawRadius2: Double = asymmetricAtom2.drawRadius / bondLength
               
                let w: Double = (asymmetricBond.isVisible && typeIsVisible1 && typeIsVisible2 && (asymmetricAtom1.isVisible && asymmetricAtom2.isVisible) &&                    (asymmetricAtom1.isVisibleEnabled && asymmetricAtom2.isVisibleEnabled)) ? 1.0 : -1.0
                data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(xyz: pos1, w: w),
                                                          position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: w),
                                                          color1: SIMD4<Float>(color: color1),
                                                          color2: SIMD4<Float>(color: color2),
                                                          scale: SIMD4<Float>(x: drawRadius1, y: 1.0, z: drawRadius2, w: drawRadius1/drawRadius2),
                                                          tag: UInt32(asymmetricIndex),
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
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldDefiner)?.forceFieldSets
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
    
    for (asymetricIndex, asymetricAtom) in asymmetricAtoms.enumerated()
    {
      let atomType: SKForceFieldType? = forceFieldSet?[asymetricAtom.uniqueForceFieldName]
      let typeIsVisible: Bool = atomType?.isVisible ?? true
      
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
              let rotationMatrix: double4x4 =  double4x4(transformation: double4x4(simd_quatd: self.orientation), aroundPoint: self.cell.boundingBox.center)
            
              let cartesianPosition: SIMD3<Double> = pos + cell.unitCell * SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) + self.cell.contentShift
            
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
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    var data: IndexSet = IndexSet()
    
    for (asymmetricIndex, asymmetricBond) in self.bondController.arrangedObjects.enumerated()
    {
      let asymmetricAtom1: SKAsymmetricAtom =  asymmetricBond.atom1
      let asymmetricAtom2: SKAsymmetricAtom =  asymmetricBond.atom2
      let isVisible: Bool =  asymmetricBond.isVisible && asymmetricAtom1.isVisible && asymmetricAtom1.isVisibleEnabled && asymmetricAtom2.isVisible && asymmetricAtom2.isVisibleEnabled
      
      for bond in asymmetricBond.copies
      {
        let pos: SIMD3<Double> = 0.5 * (bond.atom1.position + bond.atom2.position)
      
        for k1 in minimumReplicaX...maximumReplicaX
        {
          for k2 in minimumReplicaY...maximumReplicaY
          {
            for k3 in minimumReplicaZ...maximumReplicaZ
            {
              let rotationMatrix: double4x4 =  double4x4(transformation: double4x4(simd_quatd: self.orientation), aroundPoint: self.cell.boundingBox.center)
            
              let cartesianPosition: SIMD3<Double> = pos + cell.unitCell * SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3)) + self.cell.contentShift
            
              let position: SIMD4<Double> = rotationMatrix * SIMD4<Double>(x: cartesianPosition.x, y: cartesianPosition.y, z: cartesianPosition.z, w: 1.0)
              let absoluteCartesianPosition: SIMD3<Double> = SIMD3<Double>(position.x,position.y,position.z) + origin
             
              if filter(absoluteCartesianPosition) && isVisible
              {
                data.insert(asymmetricIndex)
              }
            }
          }
        }
      }
    }
    return data
  }
  
  // MARK: -
  // MARK: Symmetry
  
  public override func expandSymmetry()
  {
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    
    let unitCell = self.cell.unitCell
    let inverseCell = self.cell.inverseUnitCell
    for asymmetricAtom in asymmetricAtoms
    {
      asymmetricAtom.copies = []
      
      let fractionalPosition = inverseCell * asymmetricAtom.position
      let images: [SIMD3<Double>] = self.spaceGroup.listOfSymmetricPositions(fractionalPosition)
      
      for image in images
      {
        let CartesianPosition = unitCell * fract(image)
        let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: asymmetricAtom, position: CartesianPosition)
        newAtom.type = .copy
        asymmetricAtom.copies.append(newAtom)
      }
    }
  }
  
  public override func expandSymmetry(asymmetricAtom: SKAsymmetricAtom)
  {
    let unitCell = self.cell.unitCell
    let inverseCell = self.cell.inverseUnitCell
    
    let fractionalPosition = fract(inverseCell * asymmetricAtom.position)
    let images: [SIMD3<Double>] = self.spaceGroup.listOfSymmetricPositions(fractionalPosition)
    
    if asymmetricAtom.copies.isEmpty
    {
      for image in images
      {
        let CartesianPosition = unitCell * fract(image)
        let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: asymmetricAtom, position: CartesianPosition)
        newAtom.type = .copy
        asymmetricAtom.copies.append(newAtom)
      }
    }
    else
    {
      for (i, image) in images.enumerated()
      {
        asymmetricAtom.copies[i].type = .copy
        asymmetricAtom.copies[i].position = unitCell * fract(image)
      }
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
        self.expandSymmetry()
        
        self.reComputeBoundingBox()
        
        self.reComputeBonds()
        
        self.atomTreeController.tag()
        self.bondController.tag()
      }
    }
  }

  
  public override func numberOfReplicas() -> Int
  {
    return self.cell.numberOfReplicas
  }
  
  public override var canRemoveSymmetry: Bool
  {
    return spaceGroup.spaceGroupSetting.number > 1
  }
  
  public override var crystallographicPositions: [(SIMD3<Double>, Int)]
  {
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    var data: [(SIMD3<Double>, Int)] = [(SIMD3<Double>,Int)](repeating: (SIMD3<Double>(),0), count: atoms.count)
    
    for (index, atom) in atoms.enumerated()
    {
      data[index] = (fract(cell.inverseUnitCell * atom.position), atom.asymmetricParentAtom.elementIdentifier)
    }
    return data
  }
  
  public override var potentialParameters: [SIMD2<Double>]
  {
    var index: Int
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
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
  
  public var flattenedHierarchy: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)
  {
    let atomNodes: [SKAtomTreeNode] = self.atomTreeController.flattenedLeafNodes().filter{$0.representedObject.symmetryType == .asymmetric}
    for node in atomNodes
    {
      node.childNodes = []
    }
    
    let atomTreeController: SKAtomTreeController = SKAtomTreeController(nodes: atomNodes)
    atomTreeController.selectedTreeNodes = []
    return (cell: self.cell, spaceGroup: self.spaceGroup, atoms: atomTreeController, bonds: self.bondController)
  }
  
  public func primitive(colorSets: SKColorSets, forceFieldSets: SKForceFieldSets) -> (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    if let primitive: (cell: SKSymmetryCell, primitiveAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)]) = SKSpacegroup.SKFindPrimitive(unitCell: self.cell.unitCell, atoms: self.crystallographicPositions, symmetryPrecision: 1e-3)
    {
      let primitiveCell = SKCell(a: primitive.cell.a, b: primitive.cell.b, c: primitive.cell.c, alpha: primitive.cell.alpha, beta: primitive.cell.beta, gamma: primitive.cell.gamma)
      
      let primitiveSpaceGroup = SKSpacegroup(HallNumber: 1)
      let primitiveAtoms = SKAtomTreeController()
      primitiveAtoms.selectedTreeNodes = []
      
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
      
      let atomList: [SKAtomCopy] = primitiveAtoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
      
      let primitiveBonds: SKBondSetController = SKBondSetController(arrangedObjects: self.computeBonds(cell: primitiveCell, atomList: atomList))
      
      primitiveAtoms.tag()
      primitiveBonds.tag()
      
      return (cell: primitiveCell, spaceGroup: primitiveSpaceGroup, atoms: primitiveAtoms, bonds: primitiveBonds)
    }
    
    return nil
  }
  
  public func imposedSymmetry(colorSets: SKColorSets, forceFieldSets: SKForceFieldSets) -> (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    if let symmetry: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, atoms: [(fractionalPosition: SIMD3<Double>, type: Int)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int)]) = SKSpacegroup.SKFindSpaceGroup(unitCell: self.cell.unitCell, atoms: self.crystallographicPositions, symmetryPrecision: 1e-3)
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
        
        let images: [SIMD3<Double>] = spaceGroupWithSymmetry.listOfSymmetricPositions(atom.position)
        for image in images
        {
          let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: atom, position: cellWithSymmetry.unitCell * fract(image))
          newAtom.type = .copy
          atom.copies.append(newAtom)
        }
        
        atom.position = cellWithSymmetry.unitCell * atom.position
        
        atomsWithSymmetry.appendNode(node, atArrangedObjectIndexPath: [])
      }
      
      let atomList: [SKAtomCopy] = atomsWithSymmetry.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
      
      atomsWithSymmetry.flattenedLeafNodes().compactMap{$0.representedObject}.forEach{atom in
        let elementId: Int = atom.elementIdentifier
        atom.bondDistanceCriteria = PredefinedElements.sharedInstance.elementSet[elementId].covalentRadius
      }
      
      let bondsWithSymmetry: SKBondSetController = SKBondSetController(arrangedObjects: self.computeBonds(cell: cellWithSymmetry, atomList: atomList))
      
      atomsWithSymmetry.tag()
      bondsWithSymmetry.tag()
      
      return (cell: cellWithSymmetry, spaceGroup: spaceGroupWithSymmetry, atoms: atomsWithSymmetry, bonds: bondsWithSymmetry)
    }
    
    return nil
  }
  
  public var removedSymmetry: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)
  {
    // copy the structure for undo (via the atoms, and bonds-properties)
    let crystal: MolecularCrystal =  self.clone()
    
    // make copy of the atom-structure, leave atoms invariant
    let atomsWithRemovedSymmetry: SKAtomTreeController = crystal.atomTreeController
    atomsWithRemovedSymmetry.selectedTreeNodes = []
    
    // remove all bonds that are between 'doubles'
    let bonds: [SKBondNode] = self.bondController.bonds
    let atomBonds: SKBondSetController = SKBondSetController(arrangedObjects: bonds)
    
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
    atomsWithRemovedSymmetry.tag()
    atomBonds.tag()
    
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
    
    
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    let atomCopies: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    let spaceGroup = SKSpacegroup(HallNumber: 1)
    let newCell = SKCell(superCell: self.cell)
    
    let dx: Int = Int(maximumReplicaX - minimumReplicaX)
    let dy: Int = Int(maximumReplicaY - minimumReplicaY)
    let dz: Int = Int(maximumReplicaZ - minimumReplicaZ)
    
    let superCellAtoms: SKAtomTreeController = SKAtomTreeController()
    superCellAtoms.selectedTreeNodes = []
    
    for k1 in 0...dx
    {
      for k2 in 0...dy
      {
        for k3 in 0...dz
        {
          for atom in atomCopies
          {
            let pos: SIMD3<Double> =  self.cell.inverseUnitCell * atom.position
            let fractionalPosition: SIMD3<Double> = SIMD3<Double>(x: (pos.x + Double(k1)) / Double(dx + 1),
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
    
    let atomList: [SKAtomCopy] = superCellAtoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    
    let bonds: SKBondSetController = SKBondSetController(arrangedObjects: self.computeBonds(cell: cell, atomList: atomList))
    
    superCellAtoms.tag()
    bonds.tag()
    
    return (cell: newCell, spaceGroup: spaceGroup, atoms: superCellAtoms, bonds: bonds)
  }
  
  public override func applyCellContentShift() -> (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    let minimumReplicaX: Int = Int(self.cell.minimumReplica.x)
    let minimumReplicaY: Int = Int(self.cell.minimumReplica.y)
    let minimumReplicaZ: Int = Int(self.cell.minimumReplica.z)
    
    let maximumReplicaX: Int = Int(self.cell.maximumReplica.x)
    let maximumReplicaY: Int = Int(self.cell.maximumReplica.y)
    let maximumReplicaZ: Int = Int(self.cell.maximumReplica.z)
    
    
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    let atomCopies: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    let spaceGroup = SKSpacegroup(HallNumber: 1)
    var newCell = SKCell(superCell: self.cell)
    newCell.contentShift = SIMD3<Double>(0.0,0.0,0.0)
    
    let dx: Int = Int(maximumReplicaX - minimumReplicaX)
    let dy: Int = Int(maximumReplicaY - minimumReplicaY)
    let dz: Int = Int(maximumReplicaZ - minimumReplicaZ)
    
    let superCellAtoms: SKAtomTreeController = SKAtomTreeController()
    superCellAtoms.selectedTreeNodes = []
    
    for k1 in 0...dx
    {
      for k2 in 0...dy
      {
        for k3 in 0...dz
        {
          for atom in atomCopies
          {
            let pos: SIMD3<Double> =  fract(self.cell.inverseUnitCell * atom.position + self.cell.contentShift)
            let fractionalPosition: SIMD3<Double> = SIMD3<Double>(x: (pos.x + Double(k1)) / Double(dx + 1),
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
    
    let atomList: [SKAtomCopy] = superCellAtoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    
    let bonds: SKBondSetController = SKBondSetController(arrangedObjects: self.computeBonds(cell: cell, atomList: atomList))
    
    superCellAtoms.tag()
    bonds.tag()
    
    return (cell: newCell, spaceGroup: spaceGroup, atoms: superCellAtoms, bonds: bonds)
  }
  
  public var wrapAtomsToCell: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)
  {
    // copy the structure for undo (via the atoms, and bonds-properties)
    let crystal: MolecularCrystal =  self.clone()
    crystal.atomTreeController.selectedTreeNodes = []
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = crystal.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    
    for asymetricAtom in asymmetricAtoms
    {
      asymetricAtom.position = crystal.cell.unitCell * fract(crystal.cell.inverseUnitCell * asymetricAtom.position)
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      
      for copy in copies
      {
        copy.position = crystal.cell.unitCell * fract(crystal.cell.inverseUnitCell * copy.position)
      }
    }
    
    crystal.reComputeBoundingBox()
    
    crystal.reComputeBonds()
    
    crystal.atomTreeController.tag()
    crystal.bondController.tag()
    
    // set space group to P1 after removal of symmetry
    return (cell: crystal.cell, spaceGroup: crystal.spaceGroup, atoms: crystal.atomTreeController, bonds: crystal.bondController)
  }
  
  public override func setSpaceGroup(number: Int) -> (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    // copy the structure for undo (via the atoms, and bonds-properties)
    let crystal: MolecularCrystal =  self.clone()
    crystal.atomTreeController.selectedTreeNodes = []
    crystal.spaceGroupHallNumber = number
    
    // set space group to P1 after removal of symmetry
    return (cell: crystal.cell, spaceGroup: crystal.spaceGroup, atoms: crystal.atomTreeController, bonds: crystal.bondController)
  }
  
  // MARK: -
  // MARK: Paste atoms
  
  public override func convertToNativePositions(newAtoms: [SKAtomTreeNode])
  {
    for i in 0..<newAtoms.count
    {
      expandSymmetry(asymmetricAtom: newAtoms[i].representedObject)
    }
  }
  
  // MARK: -
  // MARK: Drag selection operations
  
  public override func translateSelection(by shift: SIMD3<Double>)
  {
    for node in self.atomTreeController.selectedTreeNodes
    {
      node.representedObject.displacement = shift
    }
    
  }
  
  // MARK: -
  // MARK: Translation and rotation operations
  
  public override func centerOfMassOfSelection(atoms: [SKAtomCopy]) -> SIMD3<Double>
  {
    var centerOfMassCosTheta: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.0)
    var centerOfMassSinTheta: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.0)
    var centerOfMass: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.0)
    var M: Double = 0.0
    
    for atom in atoms
    {
      let elementIdentifier: Int = atom.asymmetricParentAtom.elementIdentifier
      let mass: Double = PredefinedElements.sharedInstance.elementSet[elementIdentifier].mass
      let fracPos: SIMD3<Double> = self.cell.convertToFractional(atom.position)
      let pos: SIMD3<Double> = fracPos * 2.0 * Double.pi
      let cosTheta: SIMD3<Double> = SIMD3<Double>(cos(pos.x), cos(pos.y), cos(pos.z))
      let sinTheta: SIMD3<Double> = SIMD3<Double>(sin(pos.x), sin(pos.y), sin(pos.z))
      centerOfMassCosTheta += mass * cosTheta
      centerOfMassSinTheta += mass * sinTheta
      centerOfMass += atom.position
      M += mass
    }
    centerOfMassCosTheta /= M
    centerOfMassSinTheta /= M
    centerOfMass /= M
    
    let com = SIMD3<Double>((atan2(-centerOfMassSinTheta.x, -centerOfMassCosTheta.x) + Double.pi)/(2.0 * Double.pi),
                      (atan2(-centerOfMassSinTheta.y, -centerOfMassCosTheta.y) + Double.pi)/(2.0 * Double.pi),
                      (atan2(-centerOfMassSinTheta.z, -centerOfMassCosTheta.z) + Double.pi)/(2.0 * Double.pi))
    let periodicCOM: SIMD3<Double> = self.cell.convertToCartesian(com)
    
    if length_squared(cell.applyFullCellBoundaryCondition(periodicCOM-com)) < 1e-6
    {
      return com
    }
    
    return periodicCOM
  }
  
  
  public override func matrixOfInertia(atoms: [SKAtomCopy]) -> double3x3
  {
    var inertiaMatrix: double3x3 = double3x3()
    let com: SIMD3<Double> = self.selectionCOMTranslation
    let fracCom: SIMD3<Double> = self.cell.convertToFractional(com)
    
    for atom in atoms
    {
      let elementIdentifier: Int = atom.asymmetricParentAtom.elementIdentifier
      let mass: Double = PredefinedElements.sharedInstance.elementSet[elementIdentifier].mass
      let fracPos: SIMD3<Double> = self.cell.convertToFractional(atom.position)
      var ds: SIMD3<Double> = fracPos - fracCom
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
  
  public override func bonds(subset: [SKAsymmetricAtom]) -> [SKBondNode]
  {
    var computedBonds: [SKBondNode] = []
     
    let subsetAtoms: [SKAtomCopy] = subset.flatMap{$0.copies}
     
    let asymmetricAtoms: Set<SKAsymmetricAtom> = Set(self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject})
       
    let subSetAsymmetricAtoms: Set<SKAsymmetricAtom> = Set(asymmetricAtoms).subtracting(subset)
    let atomList: [SKAtomCopy] = subSetAsymmetricAtoms.flatMap{$0.copies}
     
    for i in 0..<subsetAtoms.count
    {
      subsetAtoms[i].type = .copy
       
      let posA: SIMD3<Double> = subsetAtoms[i].position
       
      for j in i+1..<subsetAtoms.count
      {
        let posB: SIMD3<Double> = subsetAtoms[j].position
         
        let separationVector: SIMD3<Double> = posA - posB
        let periodicSeparationVector: SIMD3<Double> = cell.applyUnitCellBoundaryCondition(separationVector)
         
        let bondCriteria: Double = (subsetAtoms[i].asymmetricParentAtom.bondDistanceCriteria + subsetAtoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
         
        let bondLength: Double = length(periodicSeparationVector)
        if (bondLength < bondCriteria)
        {
          // Type atom as 'Double'
          if (bondLength < 0.1)
          {
            subsetAtoms[i].type = .duplicate
          }
          else if (bondLength < 0.8)
          {
            // discard as being a bond
          }
          else if (length(separationVector) > bondCriteria )
          {
            let bond: SKBondNode = SKBondNode(atom1: subsetAtoms[i], atom2: subsetAtoms[j], boundaryType: .external)
            computedBonds.append(bond)
          }
          else
          {
            let bond: SKBondNode = SKBondNode(atom1: subsetAtoms[i], atom2: subsetAtoms[j], boundaryType: .internal)
            computedBonds.append(bond)
          }
        }
      }
       
      for j in 0..<atomList.count
      {
        let posB: SIMD3<Double> = atomList[j].position
         
        let separationVector: SIMD3<Double> = posA - posB
        let periodicSeparationVector: SIMD3<Double> = cell.applyUnitCellBoundaryCondition(separationVector)
         
        let bondCriteria: Double = (subsetAtoms[i].asymmetricParentAtom.bondDistanceCriteria + atomList[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
         
        let bondLength: Double = length(periodicSeparationVector)
        if (bondLength < bondCriteria)
        {
          // Type atom as 'Double'
          if (bondLength < 0.1)
          {
            subsetAtoms[i].type = .duplicate
          }
          else if (bondLength < 0.8)
          {
            // discard as being a bond
          }
          else if (length(separationVector) > bondCriteria )
          {
            let bond: SKBondNode = SKBondNode(atom1: subsetAtoms[i], atom2: atomList[j], boundaryType: .external)
            computedBonds.append(bond)
          }
          else
          {
            let bond: SKBondNode = SKBondNode(atom1: subsetAtoms[i], atom2: atomList[j], boundaryType: .internal)
            computedBonds.append(bond)
          }
        }
      }
    }
     
    return computedBonds.filter{$0.atom1.type == .copy && $0.atom2.type == .copy}
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
    let comFrac: SIMD3<Double> = self.cell.convertToFractional(com)
    let rotationMatrix: double3x3 = double3x3(quaternion)
    
    return atoms.map({
      let fracPos: SIMD3<Double> = self.cell.convertToFractional($0.position)
      var ds: SIMD3<Double> = fracPos - comFrac
      ds -= floor(ds + SIMD3<Double>(0.5,0.5,0.5))
      let translatedPositionCartesian: SIMD3<Double> = self.cell.convertToCartesian(ds)
      let position: SIMD3<Double> = rotationMatrix * translatedPositionCartesian
      return position + com
    })
  }
  
  public override func rotatedBodyFramePositionsSelectionCartesian(atoms: [SKAsymmetricAtom], by quaternion: simd_quatd) -> [SIMD3<Double>]
  {
    let copies: [SKAtomCopy] = atoms.flatMap{$0.copies}.filter{$0.type == .copy}
    let com: SIMD3<Double> = self.centerOfMassOfSelection(atoms: copies)
    let comFrac: SIMD3<Double> = self.cell.convertToFractional(com)
    let basis: double3x3 = self.selectionBodyFixedBasis
    let rotationMatrix = basis * double3x3(quaternion) * basis.inverse
    
    return atoms.map({
      let posFrac: SIMD3<Double> = self.cell.convertToFractional($0.position)
      var ds: SIMD3<Double> = posFrac - comFrac
      ds -= floor(ds + SIMD3<Double>(0.5,0.5,0.5))
      let translatedPositionCartesian: SIMD3<Double> = self.cell.convertToCartesian(ds)
      let position: SIMD3<Double> = rotationMatrix * translatedPositionCartesian
      return position + com
    })
  }
  
  
  
  public override func computeChangedBondLength(asymmetricBond bond: SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>, to bondLength: Double) -> (SIMD3<Double>, SIMD3<Double>)
  {
    let pos1 = bond.atom1.position
    let asymmetricAtom1: SKAsymmetricAtom = bond.atom1
    let pos2 = bond.atom2.position
    let asymmetricAtom2: SKAsymmetricAtom = bond.atom2
    
    let oldBondLength: Double = self.asymmetricBondLength(bond)
    
    let bondVector: SIMD3<Double> = normalize(self.asymmetricBondVector(bond))
    
    let isAllFixed1: Bool = asymmetricAtom1.isFixed.x && asymmetricAtom1.isFixed.y && asymmetricAtom1.isFixed.z
    let isAllFixed2: Bool = asymmetricAtom2.isFixed.x && asymmetricAtom2.isFixed.y && asymmetricAtom2.isFixed.z
    
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
  
  public override func computeChangedBondLength(bond: SKBondNode, to bondLength: Double) -> (SIMD3<Double>, SIMD3<Double>)
  {
    let pos1 = bond.atom1.position
    let asymmetricAtom1: SKAsymmetricAtom = bond.atom1.asymmetricParentAtom
    let pos2 = bond.atom2.position
    let asymmetricAtom2: SKAsymmetricAtom = bond.atom2.asymmetricParentAtom
    
    let oldBondLength: Double = self.bondLength(bond)
    
    let bondVector: SIMD3<Double> = normalize(self.bondVector(bond))
    
    let isAllFixed1: Bool = asymmetricAtom1.isFixed.x && asymmetricAtom1.isFixed.y && asymmetricAtom1.isFixed.z
    let isAllFixed2: Bool = asymmetricAtom2.isFixed.x && asymmetricAtom2.isFixed.y && asymmetricAtom2.isFixed.z
    
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
  
  
  
  // for periodic: transformed, for non-periodic: untransformed
  public override var boundingBox: SKBoundingBox
  {
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
      let pos: SIMD3<Double> = atom.position
      
      for k1 in minimumReplicaX...maximumReplicaX
      {
        for k2 in minimumReplicaY...maximumReplicaY
        {
          for k3 in minimumReplicaZ...maximumReplicaZ
          {
            let radius: Double = (atom.asymmetricParentAtom?.drawRadius ?? 0.0) * self.atomScaleFactor
            
            let cartesianPosition: SIMD3<Double> = pos + cell.unitCell * SIMD3<Double>(x: Double(k1), y: Double(k2), z: Double(k3))
            
            minimum.x = min(minimum.x, cartesianPosition.x - radius)
            minimum.y = min(minimum.y, cartesianPosition.y - radius)
            minimum.z = min(minimum.z, cartesianPosition.z - radius)
            
            maximum.x = max(maximum.x, cartesianPosition.x - radius)
            maximum.y = max(maximum.y, cartesianPosition.y - radius)
            maximum.z = max(maximum.z, cartesianPosition.z - radius)
          }
        }
      }
    }
    
    if self.drawUnitCell
    {
      let cellBoundingBox: SKBoundingBox = self.cell.enclosingBoundingBox
      minimum = min(minimum, cellBoundingBox.minimum)
      maximum = max(maximum, cellBoundingBox.maximum)
    }
    
    return SKBoundingBox(minimum: minimum, maximum: maximum)
  }
  
  
  // MARK: Measuring distance, angle, and dihedral-angles
  // =====================================================================
  
  override public func bondVector(_ bond: SKBondNode) -> SIMD3<Double>
  {
    let atom1: SIMD3<Double> = bond.atom1.position
    let atom2: SIMD3<Double> = bond.atom2.position
    let dr: SIMD3<Double> = atom2 - atom1
    return self.cell.applyUnitCellBoundaryCondition(dr)
  }
  
  override public func asymmetricBondVector(_ bond: SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>) -> SIMD3<Double>
  {
    let atom1: SIMD3<Double> = bond.atom1.position
    let atom2: SIMD3<Double> = bond.atom2.position
    let dr: SIMD3<Double> = atom2 - atom1
    return self.cell.applyUnitCellBoundaryCondition(dr)
  }
  
  override public func bondLength(_ bond: SKBondNode) -> Double
  {
    let atom1: SIMD3<Double> = bond.atom1.position
    let atom2: SIMD3<Double> = bond.atom2.position
    let dr: SIMD3<Double> = atom2 - atom1
    return length(self.cell.applyUnitCellBoundaryCondition(dr))
  }
  
  override public func asymmetricBondLength(_ bond: SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>) -> Double
  {
    let atom1: SIMD3<Double> = bond.atom1.position
    let atom2: SIMD3<Double> = bond.atom2.position
    let dr: SIMD3<Double> = atom2 - atom1
    return length(self.cell.applyUnitCellBoundaryCondition(dr))
  }
  
  // Used in the routine to measure distances and bend/dihedral angles
  override public func absoluteCartesianModelPosition(for position: SIMD3<Double>, replicaPosition: SIMD3<Int32>) -> SIMD3<Double>
  {
    let cartesianPosition: SIMD3<Double> = position + self.cell.unitCell * SIMD3<Double>(x: Double(replicaPosition.x), y: Double(replicaPosition.y), z: Double(replicaPosition.z)) + self.cell.contentShift
    return cartesianPosition
  }
  
  // Used in the routine to measure distances and bend/dihedral angles
  override public func absoluteCartesianScenePosition(for position: SIMD3<Double>, replicaPosition: SIMD3<Int32>) -> SIMD3<Double>
  {
    let rotationMatrix: double4x4 =  double4x4(transformation: double4x4(simd_quatd: self.orientation), aroundPoint: self.cell.boundingBox.center)
    let cartesianPosition: SIMD3<Double> = position + self.cell.unitCell * SIMD3<Double>(x: Double(replicaPosition.x), y: Double(replicaPosition.y), z: Double(replicaPosition.z)) + self.cell.contentShift
    let position: SIMD4<Double> = rotationMatrix * SIMD4<Double>(x: cartesianPosition.x, y: cartesianPosition.y, z: cartesianPosition.z, w: 1.0)
    let absoluteCartesianPosition: SIMD3<Double> = SIMD3<Double>(position.x,position.y,position.z) + self.origin
    return absoluteCartesianPosition
  }
  
  
  // MARK: -
  // MARK: Space group operations
  
  
  
  public override func readySelectedAtomsForCopyAndPaste() -> [SKAtomTreeNode]
  {
    return  self.atomTreeController.selectedNodes
  }
  
  public override func bonds(newAtoms: [SKAtomTreeNode]) -> [SKBondNode]
  {
    var computedBonds: [SKBondNode] = []
    
    let atoms: [SKAtomCopy] = newAtoms.compactMap{$0.representedObject}.flatMap{$0.copies}
    //atoms.forEach{ $0.bonds.removeAll()}
    
    let atomList: [SKAtomCopy] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    
    for i in 0..<atoms.count
    {
      let posA: SIMD3<Double> = atoms[i].position
      
      for j in i+1..<atoms.count
      {
        let posB: SIMD3<Double> = atoms[j].position
        
        let separationVector: SIMD3<Double> = posA - posB
        let periodicSeparationVector: SIMD3<Double> = cell.applyUnitCellBoundaryCondition(posA - posB)
        
        let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
        
        let bondLength: Double = length(periodicSeparationVector)
        if (bondLength < bondCriteria)
        {
          // Type atom as 'Double'
          if (bondLength < 0.1)
          {
            atoms[i].type = .duplicate
          }
          else if (bondLength < 0.8)
          {
            // discard as being a bond
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
      
      for j in 0..<atomList.count
      {
        let posB: SIMD3<Double> = atomList[j].position
        
        let separationVector: SIMD3<Double> = posA - posB
        let periodicSeparationVector: SIMD3<Double> = cell.applyUnitCellBoundaryCondition(posA - posB)
        
        let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atomList[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
        
        let bondLength: Double = length(periodicSeparationVector)
        if (bondLength < bondCriteria)
        {
          // Type atom as 'Double'
          if (bondLength < 0.1)
          {
            atoms[i].type = .duplicate
          }
          else if (bondLength < 0.8)
          {
            // discard as being a bond
          }
          else if (length(separationVector) > bondCriteria)
          {
            let bond: SKBondNode = SKBondNode(atom1: atoms[i], atom2: atomList[j], boundaryType: .external)
            computedBonds.append(bond)
          }
          else
          {
            let bond: SKBondNode = SKBondNode(atom1: atoms[i], atom2: atomList[j], boundaryType: .internal)
            computedBonds.append(bond)
          }
        }
      }
    }
    return computedBonds.filter{$0.atom1.type == .copy && $0.atom2.type == .copy}
  }
  
  // MARK: -
  // MARK: Compute bonds
  
  public override func reComputeBonds()
  {
    let atomList: [SKAtomCopy] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    self.bondController.bonds = self.computeBonds(cell: self.cell, atomList: atomList, cancelHandler: {return false}, updateHandler: {})
  }
  
  public override func reComputeBonds(_ node: ProjectTreeNode, cancelHandler: (()-> Bool), updateHandler: (() -> ()))
  {
    let atomList: [SKAtomCopy] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    self.bondController.bonds = self.computeBonds(cell: self.cell, atomList: atomList, cancelHandler: cancelHandler, updateHandler: updateHandler)
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
    var totalCount: Int
    
    var computedBonds: [SKBondNode] = []
    
    let perpendicularWidths: SIMD3<Double> = structureCell.boundingBox.widths + SIMD3<Double>(x: 0.1, y: 0.1, z: 0.1)
    guard perpendicularWidths.x > 0.0001 && perpendicularWidths.x > 0.0001 && perpendicularWidths.x > 0.0001 else {return []}
    
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
        //get the position in the unit cell
        let position: SIMD3<Double> = structureCell.unitCell * fract(structureCell.inverseUnitCell * atoms[i].position)
        
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
                    let periodicSeparationVector: SIMD3<Double> = structureCell.applyUnitCellBoundaryCondition(posA - posB)
                    
                    let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
                    
                    let bondLength: Double = length(periodicSeparationVector)
                    if (bondLength < bondCriteria)
                    {
                      // Type atom as 'Double'
                      if (bondLength < 0.1)
                      {
                        atoms[i].type = .duplicate
                      }
                      else if (bondLength < 0.8)
                      {
                        // discard as being a bond
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
      let bondProgress: Progress = Progress(totalUnitCount: Int64(atoms.count))
      bondProgress.completedUnitCount = 0
      
      for i in 0..<atoms.count
      {
        let posA: SIMD3<Double> = atoms[i].position
        
        for j in i+1..<atoms.count
        {
          let posB: SIMD3<Double> = atoms[j].position
          
          let separationVector: SIMD3<Double> = posA - posB
          let periodicSeparationVector: SIMD3<Double> = structureCell.applyUnitCellBoundaryCondition(posA - posB)
          
          let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
          
          
          
          let bondLength: Double = length(periodicSeparationVector)
          if (bondLength < bondCriteria)
          {
            // Type atom as 'Double'
            if (bondLength < 0.1)
            {
              atoms[i].type = .duplicate
            }
            else if (bondLength < 0.8)
            {
              // discard as being a bond
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
    
    return computedBonds.filter{$0.atom1.type == .copy && $0.atom2.type == .copy}
  }
  
  
  public override func computeBondsOperation(structure: Structure, windowController: NSWindowController?) -> FKOperation?
  {
    return MolecularCrystal.RecomputeBondsOperation(structure: structure, windowController: windowController)
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
      
      let atoms: [SKAtomCopy] = structure.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
      //atoms.forEach{ $0.bonds.removeAll()}
      let computedBonds = structure.computeBonds(cell: structure.cell, atomList: atoms)
      
      //structure.bonds.arrangedObjects = computedBonds
      structure.recomputeDensityProperties()
      
      let numberOfComputedBonds: Int =  computedBonds.filter{$0.atom1.type == .copy && $0.atom2.type == .copy}.count
      LogQueue.shared.info(destination: windowController, message: "number of bonds: \(structure.displayName) = \(numberOfComputedBonds)")
      
      
      self.progress.totalUnitCount = 10
      
      finishWithError(nil)
    }
  }
  
  // MARK: RKRenderAdsorptionSurfaceStructure
  // =====================================================================
  
  public override var atomUnitCellPositions: [SIMD3<Double>]
  {
    var index: Int
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    var data: [SIMD3<Double>] = [SIMD3<Double>](repeating: SIMD3<Double>(), count: atoms.count)
    
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
    encoder.encode(MolecularCrystal.classVersionNumber)
    super.binaryEncode(to: encoder)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > MolecularCrystal.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    try super.init(fromBinary: decoder)
  }
}


