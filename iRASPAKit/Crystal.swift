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

import Foundation
import BinaryCodable
import simd
import RenderKit
import SymmetryKit
import SimulationKit
import OperationKit
import MathKit
import LogViewKit

public final class Crystal: Structure, AtomEditor, BondEditor, UnitCellEditor, IsosurfaceEditor, SpaceGroupEditor, RKRenderAtomSource, RKRenderBondSource, RKRenderUnitCellSource, RKRenderLocalAxesSource, RKRenderAdsorptionSurfaceSource, Cloning
{
  private static var classVersionNumber: Int = 2
  
  public var spaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: 1)
    
  public override init()
  {
    super.init()
    drawUnitCell = true
  }

  public override init(name: String)
  {
    super.init(name: name)
    drawUnitCell = true
    reComputeBoundingBox()
  }
  
  public required init(copy crystal: Crystal)
  {
    super.init(copy: crystal)
  }
  
  public required init(clone crystal: Crystal)
  {
    super.init(clone: crystal)
    
    self.spaceGroup = crystal.spaceGroup
  }
  
  public required init(from object: Object)
  {
    super.init(from: object)
    
    if let atomViewer: AtomViewer = object as? AtomViewer
    {
      if !atomViewer.isFractional
      {
        self.atomTreeController.flattenedLeafNodes().forEach{
        let pos = $0.representedObject.position
            $0.representedObject.position = self.cell.convertToFractional(pos)
          }
      }
    }
    
    if let spaceGroupView: SpaceGroupEditor = object as? SpaceGroupEditor
    {
      self.spaceGroup = spaceGroupView.spaceGroup
    }
    
    self.drawUnitCell = true
    self.expandSymmetry()
    reComputeBoundingBox()
    reComputeBonds()
    self.atomTreeController.tag()
    self.bondSetController.tag()
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
  
  public override var materialType: Object.ObjectType
  {
    return .crystal
  }
  
  override var canImportMaterialsTypes: Set<SKStructure.Kind>
  {
    return [.crystal, .molecularCrystal, .molecularCrystal, .molecule, .protein, .proteinCrystal, .proteinCrystalSolvent, .crystalSolvent, .molecularCrystalSolvent]
  }
  
  public override var canRemoveSymmetry: Bool
  {
    get
    {
      return spaceGroup.spaceGroupSetting.number > 1
    }
  }
  
  public override var isFractional: Bool
  {
    return true
  }
  
  public override var hasExternalBonds: Bool
  {
    return true
  }

  
  public override func numberOfReplicas() -> Int
  {
    return self.cell.totalNumberOfReplicas
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
      
      let images: [SIMD3<Double>] = spaceGroup.listOfSymmetricPositions(asymetricAtom.position + displacement)
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
  // MARK: Symmetry
  
  public override func expandSymmetry()
  {
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    
    for asymmetricAtom in asymmetricAtoms
    {
      asymmetricAtom.copies = []
      
      let images: [SIMD3<Double>] = spaceGroup.listOfSymmetricPositions(asymmetricAtom.position)
    
      for image in images
      {
        let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: asymmetricAtom, position: fract(image))
        newAtom.type = .copy
        asymmetricAtom.copies.append(newAtom)
      }
    }
  }
  
  public override func expandSymmetry(asymmetricAtom: SKAsymmetricAtom)
  {
    let images: [SIMD3<Double>] = spaceGroup.listOfSymmetricPositions(asymmetricAtom.position)
      
    if asymmetricAtom.copies.isEmpty
    {
      for image in images
      {
        let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: asymmetricAtom, position: fract(image))
        newAtom.type = .copy
        asymmetricAtom.copies.append(newAtom)
      }
    }
    else
    {
      for (i, image) in images.enumerated()
      {
        asymmetricAtom.copies[i].type = .copy
        asymmetricAtom.copies[i].position = fract(image)
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
        
        self.reComputeBonds()
        
        self.atomTreeController.tag()
        self.bondSetController.tag()
      }
    }
  }
  
  public override var crystallographicPositions: [(SIMD3<Double>, Int, Double)]
  {
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy && $0.asymmetricParentAtom.symmetryType != .container}
     
    var data: [(SIMD3<Double>, Int, Double)] = [(SIMD3<Double>, Int, Double)](repeating: (SIMD3<Double>(), 0, 0), count: atoms.count)
     
    for (index, atom) in atoms.enumerated()
    {
      data[index] = (fract(atom.position), atom.asymmetricParentAtom.elementIdentifier, atom.asymmetricParentAtom.occupancy)
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
  
  public override var clipBonds: Bool
  {
    return true
  }
   
  public func transformToFractionalPosition()
  {
    let atoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    
    for i in 0..<atoms.count
    {
      let CartesianPosition: SIMD3<Double> = atoms[i].position
      let position: SIMD3<Double> = cell.convertToFractional(CartesianPosition)
      atoms[i].position = position
      
      for copy in atoms[i].copies
      {
        let CartesianPosition: SIMD3<Double> = copy.position
        let position: SIMD3<Double> = cell.convertToFractional(CartesianPosition)
        copy.position = position
      }
    }
  }
  
  // place all copies as subnodes of asymmetric node
  public var removedSymmetry: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)
  {
    // copy the structure for undo (via the atoms, and bonds-properties)
    let crystal: Crystal =  self.clone()
    
    // make copy of the atom-structure, leave atoms invariant
    let atomsWithRemovedSymmetry: SKAtomTreeController = crystal.atomTreeController
    atomsWithRemovedSymmetry.selectedTreeNodes = []
    
    let bonds: [SKBondNode] = crystal.bondSetController.bonds
    let atomBonds: SKBondSetController = SKBondSetController(arrangedObjects: bonds)
    
    let atomNodes: [SKAtomTreeNode] = atomsWithRemovedSymmetry.flattenedLeafNodes()
    
    for atomNode in atomNodes
    {
      atomNode.isGroup = true
      let atom = atomNode.representedObject
      
      let copies: [SKAtomCopy] = atom.copies.filter{$0.type == .copy}
      for copy in copies
      {
        let newAtom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: atom.displayName, elementId: atom.elementIdentifier, uniqueForceFieldName: atom.uniqueForceFieldName, position: copy.position, charge: atom.charge, color: atom.color, drawRadius: atom.drawRadius, bondDistanceCriteria: atom.bondDistanceCriteria, occupancy: atom.occupancy)
        newAtom.symmetryType = .asymmetric
        copy.asymmetricParentAtom = newAtom
        newAtom.copies = [copy]
          
        let child: SKAtomTreeNode = SKAtomTreeNode(representedObject: newAtom)
        child.append(inParent: atomNode)
      }
      atom.copies = []
      atom.symmetryType = .container
    }
    
    atomsWithRemovedSymmetry.tag()
    atomBonds.tag()
    
    // set space group to P1 after removal of symmetry
    return (cell: self.cell, spaceGroup: SKSpacegroup(HallNumber: 1), atoms: atomsWithRemovedSymmetry, bonds: atomBonds)
  }
  
  public var wrapAtomsToCell: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)
  {
    // copy the structure for undo (via the atoms, and bonds-properties)
    let crystal: Crystal =  self.clone()
    crystal.atomTreeController.selectedTreeNodes = []
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = crystal.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    
    for asymetricAtom in asymmetricAtoms
    {
      asymetricAtom.position = fract(asymetricAtom.position)
      let copies: [SKAtomCopy] = asymetricAtom.copies.filter{$0.type == .copy}
      
      for copy in copies
      {
        copy.position = fract(copy.position)
      }
    }
    
    crystal.reComputeBoundingBox()
    
    crystal.reComputeBonds()
    
    crystal.atomTreeController.tag()
    crystal.bondSetController.tag()
    
    // set space group to P1 after removal of symmetry
    return (cell: crystal.cell, spaceGroup: crystal.spaceGroup, atoms: crystal.atomTreeController, bonds: crystal.bondSetController)
  }
  
  public override func setSpaceGroup(number: Int) -> (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
     // copy the structure for undo (via the atoms, and bonds-properties)
    let crystal: Crystal =  self.clone()
    crystal.atomTreeController.selectedTreeNodes = []
    crystal.spaceGroupHallNumber = number
    
    // set space group to P1 after removal of symmetry
    return (cell: crystal.cell, spaceGroup: crystal.spaceGroup, atoms: crystal.atomTreeController, bonds: crystal.bondSetController)
  }
  
  
  
  public func primitive(colorSets: SKColorSets, forceFieldSets: SKForceFieldSets) -> (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    if let primitive: (cell: SKSymmetryCell, primitiveAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)]) = SKSpacegroup.SKFindPrimitive(unitCell: self.cell.unitCell, atoms: self.crystallographicPositions, allowPartialOccupancies: false, symmetryPrecision: cell.precision)
    {
      let primitiveCell = SKCell(a: primitive.cell.a, b: primitive.cell.b, c: primitive.cell.c, alpha: primitive.cell.alpha, beta: primitive.cell.beta, gamma: primitive.cell.gamma)
      
      let primitiveSpaceGroup = SKSpacegroup(HallNumber: 1)
      let primitiveAtoms = SKAtomTreeController()
      primitiveAtoms.selectedTreeNodes = []
      
      for asymmetricAtom in primitive.primitiveAtoms
      {
        let displayName: String = PredefinedElements.sharedInstance.elementSet[asymmetricAtom.type].chemicalSymbol
        let color: NSColor = colorSets[self.atomColorSchemeIdentifier]?[displayName] ?? NSColor.black
        let drawRadius: Double = self.drawRadius(elementId: asymmetricAtom.type)
        let bondDistanceCriteria: Double = forceFieldSets[self.atomForceFieldIdentifier]?[displayName]?.userDefinedRadius ?? 1.0
        
        let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: displayName, elementId: asymmetricAtom.type, uniqueForceFieldName: displayName, position: asymmetricAtom.fractionalPosition, charge: 0.0, color: color, drawRadius: drawRadius, bondDistanceCriteria: bondDistanceCriteria, occupancy: asymmetricAtom.occupancy)
        atom.symmetryType = .asymmetric
        let node = SKAtomTreeNode(representedObject: atom)
        
        let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: atom, position: fract(atom.position))
        newAtom.type = .copy
        atom.copies.append(newAtom)
        
        primitiveAtoms.appendNode(node, atArrangedObjectIndexPath: [])
      }

      let atomList: [SKAtomCopy] = primitiveAtoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
      
      let bonds: [SKBondNode] = self.computeBonds(cell: primitiveCell, atomList: atomList)
      let primitiveBonds: SKBondSetController = SKBondSetController(arrangedObjects: bonds)
      
      primitiveAtoms.tag()
      primitiveBonds.tag()
      
      return (cell: primitiveCell, spaceGroup: primitiveSpaceGroup, atoms: primitiveAtoms, bonds: primitiveBonds)
    }
    
    return nil
  }
  
  public func Niggli(colorSets: SKColorSets, forceFieldSets: SKForceFieldSets) -> (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    if let primitive: (HallNumber: Int, cell: SKSymmetryCell, asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)]) = SKSpacegroup.SKFindNiggli(unitCell: self.cell.unitCell, atoms: self.crystallographicPositions, allowPartialOccupancies: false, symmetryPrecision: cell.precision)
    {
      let primitiveCell = SKCell(a: primitive.cell.a, b: primitive.cell.b, c: primitive.cell.c, alpha: primitive.cell.alpha, beta: primitive.cell.beta, gamma: primitive.cell.gamma)
      
      let primitiveSpaceGroup = SKSpacegroup(HallNumber: primitive.HallNumber)
      let primitiveAtoms = SKAtomTreeController()
      primitiveAtoms.selectedTreeNodes = []
      
      for asymmetricAtom in primitive.asymmetricAtoms
      {
        let displayName: String = PredefinedElements.sharedInstance.elementSet[asymmetricAtom.type].chemicalSymbol
        let color: NSColor = colorSets[self.atomColorSchemeIdentifier]?[displayName] ?? NSColor.black
        let drawRadius: Double = self.drawRadius(elementId: asymmetricAtom.type)
        let bondDistanceCriteria: Double = forceFieldSets[self.atomForceFieldIdentifier]?[displayName]?.userDefinedRadius ?? 1.0
        let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: displayName, elementId: asymmetricAtom.type, uniqueForceFieldName: displayName, position: asymmetricAtom.fractionalPosition, charge: 0.0, color: color, drawRadius: drawRadius, bondDistanceCriteria: bondDistanceCriteria, occupancy: asymmetricAtom.occupancy)
        atom.symmetryType = .asymmetric
        let node = SKAtomTreeNode(representedObject: atom)
        
        let images: [SIMD3<Double>] = primitiveSpaceGroup.listOfSymmetricPositions(atom.position)
        for image in images
        {
          let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: atom, position: fract(image))
          newAtom.type = .copy
          atom.copies.append(newAtom)
        }
        
        primitiveAtoms.appendNode(node, atArrangedObjectIndexPath: [])
      }

      let atomList: [SKAtomCopy] = primitiveAtoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
      
      let bonds: [SKBondNode] = self.computeBonds(cell: primitiveCell, atomList: atomList)
      let primitiveBonds: SKBondSetController = SKBondSetController(arrangedObjects: bonds)
      
      primitiveAtoms.tag()
      primitiveBonds.tag()
      
      return (cell: primitiveCell, spaceGroup: primitiveSpaceGroup, atoms: primitiveAtoms, bonds: primitiveBonds)
    }
    
    return nil
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
    return (cell: self.cell, spaceGroup: self.spaceGroup, atoms: atomTreeController, bonds: self.bondSetController)
  }

  
  
  public func imposedSymmetry(colorSets: SKColorSets, forceFieldSets: SKForceFieldSets) -> (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    let atomNodes: [SKAtomTreeNode] = self.atomTreeController.flattenedLeafNodes().filter{$0.representedObject.symmetryType == .asymmetric}
    let allowPartialOccupancies: Bool = !atomNodes.filter{$0.representedObject.occupancy < 1.0}.isEmpty
    
    if let symmetry: (hall: Int, origin: SIMD3<Double>, cell: SKSymmetryCell, changeOfBasis: SKRotationalChangeOfBasis, transformationMatrix: simd_double3x3, rotationMatrix: simd_double3x3, atoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)], asymmetricAtoms: [(fractionalPosition: SIMD3<Double>, type: Int, occupancy: Double)]) = SKSpacegroup.SKFindSpaceGroup(unitCell: self.cell.unitCell, atoms: self.crystallographicPositions, allowPartialOccupancies: allowPartialOccupancies, symmetryPrecision: cell.precision)
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
        let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: displayName, elementId: asymmetricAtom.type, uniqueForceFieldName: displayName, position: asymmetricAtom.fractionalPosition, charge: 0.0, color: color, drawRadius: drawRadius, bondDistanceCriteria: bondDistanceCriteria, occupancy: asymmetricAtom.occupancy)
        atom.symmetryType = .asymmetric
        let node = SKAtomTreeNode(representedObject: atom)
        
        let images: [SIMD3<Double>] = spaceGroupWithSymmetry.listOfSymmetricPositions(atom.position)
        for image in images
        {
          let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: atom, position: fract(image))
          newAtom.type = .copy
          atom.copies.append(newAtom)
        }
        
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
    let cell = SKCell(superCell: self.cell)
    
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
            let pos: SIMD3<Double> = atom.position
            let fractionalPosition: SIMD3<Double> = SIMD3<Double>(x: (pos.x + Double(k1)) / Double(dx + 1),
                                                      y: (pos.y + Double(k2)) / Double(dy + 1),
                                                      z: (pos.z + Double(k3)) / Double(dz + 1))
            let newAtom: SKAsymmetricAtom = SKAsymmetricAtom(atom: atom.asymmetricParentAtom)
            newAtom.position = fractionalPosition
            
            let copy: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: newAtom, position: fractionalPosition)
            copy.type = .copy
            newAtom.copies.append(copy)
            
            let node = SKAtomTreeNode(representedObject: newAtom)
            superCellAtoms.appendNode(node, atArrangedObjectIndexPath: [])
          }
        }
      }
    }
    
    let atomList: [SKAtomCopy] = superCellAtoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    superCellAtoms.tag()
    
    let bonds: SKBondSetController = SKBondSetController(arrangedObjects: self.computeBonds(cell: cell, atomList: atomList))
    bonds.tag()
    
    return (cell: cell, spaceGroup: spaceGroup, atoms: superCellAtoms, bonds: bonds)
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
            let flippedPosition: SIMD3<Double> = SIMD3<Double>.flip(v: atom.position, flip: self.cell.contentFlip, boundary: SIMD3<Double>(1.0,1.0,1.0))
            let pos: SIMD3<Double> = fract(flippedPosition + self.cell.contentShift)
            let fractionalPosition: SIMD3<Double> = SIMD3<Double>(x: (pos.x + Double(k1)) / Double(dx + 1),
                                                                  y: (pos.y + Double(k2)) / Double(dy + 1),
                                                                  z: (pos.z + Double(k3)) / Double(dz + 1))
            let newAtom: SKAsymmetricAtom = SKAsymmetricAtom(atom: atom.asymmetricParentAtom)
            newAtom.position = fractionalPosition
            
            let copy: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: newAtom, position: fractionalPosition)
            copy.type = .copy
            newAtom.copies.append(copy)
            
            let node = SKAtomTreeNode(representedObject: newAtom)
            superCellAtoms.appendNode(node, atArrangedObjectIndexPath: [])
          }
        }
      }
    }
    
    let atomList: [SKAtomCopy] = superCellAtoms.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    superCellAtoms.tag()
    
    newCell.contentShift = SIMD3<Double>(0,0,0)
    newCell.contentFlip = Bool3(false,false,false)
    
    let bonds: SKBondSetController = SKBondSetController(arrangedObjects: self.computeBonds(cell: cell, atomList: atomList))
    bonds.tag()
    
    return (cell: newCell, spaceGroup: spaceGroup, atoms: superCellAtoms, bonds: bonds)
    
  }
  
  
  
  func computeVoidFraction()
  {
    
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
  
  
  // MARK: Measuring distance, angle, and dihedral-angles
  // =====================================================================

  override public func bondVector(_ bond: SKBondNode) -> SIMD3<Double>
  {
    let atom1: SIMD3<Double> = bond.atom1.position
    let atom2: SIMD3<Double> = bond.atom2.position
    var ds: SIMD3<Double> = atom2 - atom1
    ds -= floor(ds + SIMD3<Double>(0.5,0.5,0.5))
    return self.cell.unitCell * ds
  }
  
  override public func asymmetricBondVector(_ bond: SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>) -> SIMD3<Double>
  {
    let atom1: SIMD3<Double> = bond.atom1.position
    let atom2: SIMD3<Double> = bond.atom2.position
    var ds: SIMD3<Double> = atom2 - atom1
    ds -= floor(ds + SIMD3<Double>(0.5,0.5,0.5))
    return self.cell.unitCell * ds
  }
  
  override public func bondLength(_ bond: SKBondNode) -> Double
  {
    let atom1: SIMD3<Double> = bond.atom1.position
    let atom2: SIMD3<Double> = bond.atom2.position
    var ds: SIMD3<Double> = atom2 - atom1
    ds -= floor(ds + SIMD3<Double>(0.5,0.5,0.5))
    return length(self.cell.unitCell * ds)
  }
  
  override public func asymmetricBondLength(_ asymmetricBond: SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>) -> Double
  {
    let atom1: SIMD3<Double> = asymmetricBond.atom1.position
    let atom2: SIMD3<Double> = asymmetricBond.atom2.position
    var ds: SIMD3<Double> = atom2 - atom1
    ds -= floor(ds + SIMD3<Double>(0.5,0.5,0.5))
    return length(self.cell.unitCell * ds)
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
      let newPos1: SIMD3<Double> = self.cell.convertToFractional( self.cell.convertToCartesian(pos1) - 0.5 * (bondLength - oldBondLength) * bondVector)
      let newPos2: SIMD3<Double> = self.cell.convertToFractional( self.cell.convertToCartesian(pos2) + 0.5 * (bondLength - oldBondLength) * bondVector)
      return (newPos1, newPos2)
    case (true, false):
      let newPos2: SIMD3<Double> = self.cell.convertToFractional( self.cell.convertToCartesian(pos1) + bondLength * bondVector)
      return (pos1, newPos2)
    case (false, true):
      let newPos1: SIMD3<Double> = self.cell.convertToFractional( self.cell.convertToCartesian(pos2) - bondLength * bondVector)
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
      let newPos1: SIMD3<Double> = self.cell.convertToFractional( self.cell.convertToCartesian(pos1) - 0.5 * (bondLength - oldBondLength) * bondVector)
      let newPos2: SIMD3<Double> = self.cell.convertToFractional( self.cell.convertToCartesian(pos2) + 0.5 * (bondLength - oldBondLength) * bondVector)
      return (newPos1, newPos2)
    case (true, false):
      let newPos2: SIMD3<Double> = self.cell.convertToFractional( self.cell.convertToCartesian(pos1) + bondLength * bondVector)
      return (pos1, newPos2)
    case (false, true):
      let newPos1: SIMD3<Double> = self.cell.convertToFractional( self.cell.convertToCartesian(pos2) - bondLength * bondVector)
      return (newPos1, pos2)
    case (true, true):
      return (pos1,pos2)
    }
  }
  
  
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
    var M: Double = 0.0
    
    for atom in atoms
    {
      let elementIdentifier: Int = atom.asymmetricParentAtom.elementIdentifier
      let mass: Double = PredefinedElements.sharedInstance.elementSet[elementIdentifier].mass
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
      let elementIdentifier: Int = atom.asymmetricParentAtom.elementIdentifier
      let mass: Double = PredefinedElements.sharedInstance.elementSet[elementIdentifier].mass
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
       
       let posA: SIMD3<Double> = cell.convertToCartesian(subsetAtoms[i].position)
       
       for j in i+1..<subsetAtoms.count
       {
         let posB: SIMD3<Double> = cell.convertToCartesian(subsetAtoms[j].position)
         
         let separationVector: SIMD3<Double> = posA - posB
         let periodicSeparationVector: SIMD3<Double> = cell.applyUnitCellBoundaryCondition(separationVector)
         
         let bondCriteria: Double = (subsetAtoms[i].asymmetricParentAtom.bondDistanceCriteria + subsetAtoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
         
         let bondLength: Double = length(periodicSeparationVector)
         if (bondLength < bondCriteria)
         {
           // Type atom as 'Double'
           if (bondLength < 0.1)
           {
             if(subsetAtoms[i].asymmetricParentAtom.elementIdentifier != subsetAtoms[j].asymmetricParentAtom.elementIdentifier)
             {
               subsetAtoms[i].type = .duplicate
             }
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
         let posB: SIMD3<Double> = cell.convertToCartesian(atomList[j].position)
         
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
  // MARK: Paste atoms
  
  public override func convertToNativePositions(newAtoms: [SKAtomTreeNode])
  {
    for i in 0..<newAtoms.count
    {
      newAtoms[i].representedObject.position = fract(self.cell.convertToFractional(newAtoms[i].representedObject.position))
      expandSymmetry(asymmetricAtom: newAtoms[i].representedObject)
    }
  }
  
  public override func readySelectedAtomsForCopyAndPaste() -> [SKAtomTreeNode]
  {
    let selectedNodes: [SKAtomTreeNode] = self.atomTreeController.selectedNodes.copy()
    
    selectedNodes.forEach{
      let pos = $0.representedObject.position
          $0.representedObject.position = self.cell.convertToCartesian(pos)
        }
    return selectedNodes
  }
  
  public override func bonds(newAtoms: [SKAtomTreeNode]) -> [SKBondNode]
  {
    var computedBonds: [SKBondNode] = []
    
    let atoms: [SKAtomCopy] = newAtoms.compactMap{$0.representedObject}.flatMap{$0.copies}
    //atoms.forEach{ $0.bonds.removeAll()}
    
    let atomList: [SKAtomCopy] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}.flatMap{$0.copies}
    
    for i in 0..<atoms.count
    {
      atoms[i].type = .copy
      
      let posA: SIMD3<Double> = cell.convertToCartesian(atoms[i].position)
      
      for j in i+1..<atoms.count
      {
        let posB: SIMD3<Double> = cell.convertToCartesian(atoms[j].position)
        
        let separationVector: SIMD3<Double> = posA - posB
        let periodicSeparationVector: SIMD3<Double> = cell.applyUnitCellBoundaryCondition(separationVector)
        
        let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
        
        let bondLength: Double = length(periodicSeparationVector)
        if (bondLength < bondCriteria)
        {
          // Type atom as 'Double'
          if (bondLength < 0.1)
          {
            if(atoms[i].asymmetricIndex != atoms[j].asymmetricIndex)
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
      
      for j in 0..<atomList.count
      {
        let posB: SIMD3<Double> = cell.convertToCartesian(atomList[j].position)
        
        let separationVector: SIMD3<Double> = posA - posB
        let periodicSeparationVector: SIMD3<Double> = cell.applyUnitCellBoundaryCondition(separationVector)
        
        let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atomList[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
        
        let bondLength: Double = length(periodicSeparationVector)
        if (bondLength < bondCriteria)
        {
          // Type atom as 'Double'
          if (bondLength < 0.1)
          {
            // a duplicate when: (a) both occupancies are 1.0, or (b) when they are the same asymmetric type
            if(!(atoms[i].asymmetricParentAtom.occupancy < 1.0 || atomList[j].asymmetricParentAtom.occupancy < 1.0) || (atoms[i].asymmetricIndex == atomList[j].asymmetricIndex))
            {
              atoms[i].type = .duplicate
            }
          }
          else if (bondLength < 0.8)
          {
            // discard as being a bond
          }
          else if (length(separationVector) > bondCriteria )
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
    return Crystal.RecomputeBondsOperation(structure: structure, windowController: windowController)
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
      data[index] = atom.position
      index = index + 1
    }
    return data
  }
  
  public var dimensions: SIMD3<Int32> = SIMD3<Int32>(128,128,128)
  
  public var range: (Double, Double) = (0.0,0.0)
  
  public var spacing: SIMD3<Double> = SIMD3<Double>(0.1,0.1,0.1)
  
  public var data: Data = Data()
  
  public var average: Double = 0.0
  
  public var variance: Double = 0.0
  
  public override var encompassingPowerOfTwoCubicGridSize: Int
  {
    get
    {
      return super.encompassingPowerOfTwoCubicGridSize
    }
    set(newValue)
    {
      super.encompassingPowerOfTwoCubicGridSize = newValue
      let size: Int32 = Int32(pow(2.0,Double(newValue)))
      self.dimensions = SIMD3<Int32>(size,size,size)
    }
  }
  
  public var isImmutable: Bool
  {
    return false
  }
  
  public var gridData: [Float]
  {
    let cell: SKCell = self.cell
    let positions: [SIMD3<Double>] = self.atomUnitCellPositions
    let potentialParameters: [SIMD2<Double>] = self.potentialParameters
    let probeParameters: SIMD2<Double> = self.adsorptionSurfaceProbeParameters
    let size: Int32 = Int32(pow(2.0,Double(self.encompassingPowerOfTwoCubicGridSize)))
    self.dimensions = SIMD3<Int32>(size,size,size)
    
    let numberOfReplicas: SIMD3<Int32> = cell.numberOfReplicas(forCutoff: 12.0)
    
    if let device: MTLDevice = MTLCreateSystemDefaultDevice(),
       let commandQueue: MTLCommandQueue = device.makeCommandQueue()
    {
      let framework: SKMetalFramework = SKMetalFramework(device: device, commandQueue: commandQueue, positions: positions, potentialParameters: potentialParameters, unitCell:   cell.unitCell, numberOfReplicas: numberOfReplicas)
      
      let data: [Float] = framework.ComputeEnergyGrid(Int(size), sizeY: Int(size), sizeZ: Int(size), probeParameter: probeParameters)
                  
      self.minimumGridEnergyValue = data.min()
      self.range = (Double(minimumGridEnergyValue!),0.0)
      
      self.adsorptionVolumeStepLength = 0.25 / Double(size)
   
      return data
    }
    return []
  }
  
  public var gridValueAndGradientData: [SIMD4<Float>]
  {
    var copiedData: [Float] = gridData
    
    for i in 0..<copiedData.count
    {
      let temp: Float = 1000.0*(1.0/300.0)*(copiedData[i]-Float(range.0))
      var value: Float = 0.0;
      if(temp>54000)
      {
        value = 1.0;
      }
      else
      {
        value=temp/65535.0;
      }
      copiedData[i] = value
    }
    
    let encompassingCubicGridSize: Int32 = Int32(pow(2.0, Double(self.encompassingPowerOfTwoCubicGridSize)))
    let numberOfValues: Int32 = encompassingCubicGridSize * encompassingCubicGridSize * encompassingCubicGridSize
    var newdata = Array<SIMD4<Float>>(repeating: SIMD4<Float>(0.0,0.0,0.0,0.0), count: Int(numberOfValues))
        
    for z: Int32 in 0..<dimensions.z
    {
      for y: Int32 in 0..<dimensions.y
      {
        for x: Int32 in 0..<dimensions.x
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
  // MARK: Binary Encodable support
  
  public override func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(Crystal.classVersionNumber)
    
    encoder.encode(self.spaceGroupHallNumber ?? Int(1))
    encoder.encode(Int(0x6f6b6183))
    
    super.binaryEncode(to: encoder)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > Crystal.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    if(readVersionNumber >= 2)
    {
      let number = try decoder.decode(Int.self)
      self.spaceGroup = SKSpacegroup(HallNumber: number)
      
      let magicNumber = try decoder.decode(Int.self)
      if magicNumber != Int(0x6f6b6183)
      {
        throw BinaryDecodableError.invalidMagicNumber
      }
    }
    
    try super.init(fromBinary: decoder)
    
    if(readVersionNumber <= 1)
    {
      self.spaceGroup = self.legacySpaceGroup
    }
  }
}






