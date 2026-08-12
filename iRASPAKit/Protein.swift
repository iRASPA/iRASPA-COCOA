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
import simd
import MathKit
import RenderKit
import SymmetryKit
import BinaryCodable
import SimulationKit
import LogViewKit
import OperationKit

public final class Protein: Structure, AtomEditor, BondEditor, RKRenderAtomSource, RKRenderBondSource, RKRenderRibbonSource, RKRenderUnitCellSource, RKRenderLocalAxesSource, Cloning
{
  private static var classVersionNumber: Int = 7
  
  public var backbone: ProteinBackbone = ProteinBackbone()
  public var drawRibbon: Bool = true
  public var ribbonScaleFactor: Double = 1.2
  public var ribbonColorSet: ProteinRibbonColorSet = .standardAcademic
  public var ribbonRepresentationStyle: ProteinRibbonRepresentationStyle = .default
  public var ribbonSecondaryStructureMethod: ProteinRibbonSecondaryStructureMethod = .stride
  public var ribbonSplineType: ProteinRibbonSplineType = .bSpline
  public var ribbonSubdivisionsPerSegment: Int = 24
  public var ribbonCrossSectionRingResolution: Int = 32
  public var ribbonCoilRadiusScale: Double = 0.35
  public var ribbonWidthClamp: Double = 0.125
  public var ribbonSheetArrowLengthExtent: Double = 1.5
  public var ribbonSheetArrowWingPosition: Double = 1.0
  public var ribbonSheetArrowPeakWidthFactor: Double = 2.5
  public var ribbonNormalSmoothingRadius: Int = 4
  public var ribbonHDR: Bool = true
  public var ribbonHDRExposure: Double = 1.5
  public var ribbonHue: Double = 1.0
  public var ribbonSaturation: Double = 1.0
  public var ribbonValue: Double = 1.0
  public var ribbonAmbientOcclusion: Bool = false
  public var ribbonAmbientColor: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var ribbonDiffuseColor: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var ribbonSpecularColor: NSColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  public var ribbonAmbientIntensity: Double = 0.2
  public var ribbonDiffuseIntensity: Double = 1.0
  public var ribbonSpecularIntensity: Double = 1.0
  public var ribbonShininess: Double = 6.0
  public private(set) var ribbonMesh: RKRibbonMesh = RKRibbonMesh()
  public var ribbonAmbientOcclusionPatchNumber: Int = 1
  public var ribbonAmbientOcclusionPatchSize: Int = 16
  public var ribbonAmbientOcclusionTextureSize: Int = 256
  public var ribbonAmbientOcclusionTextureWidth: Int = 2048
  public var ribbonAmbientOcclusionTextureHeight: Int = 64
  public var ribbonAmbientOcclusionStripHeight: Int = 64
  
  public var ribbonMaxSplineSampleCount: Int
  {
    return ribbonMesh.maxSplineSampleCount
  }
  
  public var ribbonCoilColor: SIMD3<Float>
  {
    return ribbonColorSet.coilColor
  }
  
  public var ribbonHelixColor: SIMD3<Float>
  {
    return ribbonColorSet.helixColor
  }
  
  public var ribbonSheetColor: SIMD3<Float>
  {
    return ribbonColorSet.sheetColor
  }
  
  public var renderRibbonVertices: [RKVertex]
  {
    return ribbonMesh.vertices
  }
  
  public var renderRibbonIndices: [UInt32]
  {
    return ribbonMesh.indices
  }
  
  public var ribbonNumberOfVertices: Int
  {
    return ribbonMesh.vertices.count
  }
  
  public var ribbonNumberOfIndices: Int
  {
    return ribbonMesh.indices.count
  }
  
  public var ribbonChainDrawRanges: [RKRibbonChainDrawRange]
  {
    return ribbonMesh.chainDrawRanges
  }
  
  public var ribbonSegmentDrawRanges: [RKRibbonChainDrawRange]
  {
    return ribbonMesh.segmentDrawRanges
  }
  
  public var ribbonResidueDrawRanges: [RKRibbonChainDrawRange]
  {
    return ribbonMesh.residueDrawRanges
  }
  
  public var ribbonUsesSegmentVisibility: Bool
  {
    if !ribbonMesh.segmentAlphaCarbonTags.isEmpty
    {
      return ribbonMesh.segmentAlphaCarbonTags.count == ribbonMesh.segmentDrawRanges.count
    }
    return ProteinRibbonSegmentSupport.segmentTreeNodesAlignWithDrawRanges(atomTreeController,
                                                                           drawRangeCount: ribbonMesh.segmentDrawRanges.count)
  }
  
  public var ribbonUsesResidueVisibility: Bool
  {
    // Mesh residue ranges are 1:1 with Cα tags; tree residue groups can outnumber them
    // (HETATM, single-sample residues skipped in the sweep). Prefer tags so R/A visibility works.
    if !ribbonMesh.residueAlphaCarbonTags.isEmpty
    {
      return ribbonMesh.residueAlphaCarbonTags.count == ribbonMesh.residueDrawRanges.count
    }
    return ProteinRibbonSegmentSupport.residueTreeNodesAlignWithDrawRanges(atomTreeController,
                                                                           drawRangeCount: ribbonMesh.residueDrawRanges.count)
  }
  
  public func isRibbonSegmentDrawRangeVisible(at index: Int) -> Bool
  {
    guard ribbonUsesSegmentVisibility else {return true}
    if !ribbonMesh.segmentAlphaCarbonTags.isEmpty
    {
      guard index >= 0 && index < ribbonMesh.segmentAlphaCarbonTags.count else {return true}
      let tag: Int = ribbonMesh.segmentAlphaCarbonTags[index]
      guard let segmentNode: SKAtomTreeNode = ProteinRibbonSegmentSupport.segmentTreeNode(forAtomTag: tag,
                                                                                            in: atomTreeController) else {return true}
      return ProteinRibbonSegmentSupport.isRibbonSegmentVisible(segmentNode)
    }
    let segmentNodes: [SKAtomTreeNode] = ProteinRibbonSegmentSupport.orderedSegmentTreeNodes(in: atomTreeController)
    guard index >= 0 && index < segmentNodes.count else {return true}
    return ProteinRibbonSegmentSupport.isRibbonSegmentVisible(segmentNodes[index])
  }
  
  public func isRibbonResidueDrawRangeVisible(at index: Int) -> Bool
  {
    guard ribbonUsesResidueVisibility else {return true}
    if !ribbonMesh.residueAlphaCarbonTags.isEmpty
    {
      guard index >= 0 && index < ribbonMesh.residueAlphaCarbonTags.count else {return true}
      let tag: Int = ribbonMesh.residueAlphaCarbonTags[index]
      guard let residueNode: SKAtomTreeNode = ProteinRibbonSegmentSupport.residueTreeNode(forAtomTag: tag,
                                                                                            in: atomTreeController) else {return true}
      return ProteinRibbonSegmentSupport.isRibbonResidueVisible(residueNode)
    }
    let residueNodes: [SKAtomTreeNode] = ProteinRibbonSegmentSupport.orderedResidueTreeNodes(in: atomTreeController)
    guard index >= 0 && index < residueNodes.count else {return true}
    return ProteinRibbonSegmentSupport.isRibbonResidueVisible(residueNodes[index])
  }
  
  public func ribbonDrawRangesForEncoding() -> [RKRibbonChainDrawRange]
  {
    return drawRangesForEncoding(mesh: ribbonMesh)
  }
  
  private func drawRangesForEncoding(mesh: RKRibbonMesh) -> [RKRibbonChainDrawRange]
  {
    if ribbonUsesResidueVisibility && !mesh.residueDrawRanges.isEmpty
    {
      let visible: [Bool]
      if mesh.residueAlphaCarbonTags.count == mesh.residueDrawRanges.count
      {
        visible = ProteinRibbonSegmentSupport.residueVisibilityMask(forAtomTags: mesh.residueAlphaCarbonTags,
                                                                    in: atomTreeController)
      }
      else if ribbonMesh.residueAlphaCarbonTags.count == mesh.residueDrawRanges.count
      {
        visible = ProteinRibbonSegmentSupport.residueVisibilityMask(forAtomTags: ribbonMesh.residueAlphaCarbonTags,
                                                                    in: atomTreeController)
      }
      else
      {
        return mesh.chainDrawRanges
      }
      if visible.allSatisfy({$0})
      {
        return mesh.chainDrawRanges
      }
      return RKRibbonMesh.mergedVisibleDrawRanges(mesh.residueDrawRanges, visible: visible)
    }
    
    if ribbonUsesSegmentVisibility && !mesh.segmentDrawRanges.isEmpty
    {
      let visible: [Bool]
      if mesh.segmentAlphaCarbonTags.count == mesh.segmentDrawRanges.count
      {
        visible = ProteinRibbonSegmentSupport.segmentVisibilityMask(forAtomTags: mesh.segmentAlphaCarbonTags,
                                                                    in: atomTreeController)
      }
      else if ribbonMesh.segmentAlphaCarbonTags.count == mesh.segmentDrawRanges.count
      {
        visible = ProteinRibbonSegmentSupport.segmentVisibilityMask(forAtomTags: ribbonMesh.segmentAlphaCarbonTags,
                                                                    in: atomTreeController)
      }
      else
      {
        return mesh.chainDrawRanges
      }
      if visible.allSatisfy({$0})
      {
        return mesh.chainDrawRanges
      }
      return RKRibbonMesh.mergedVisibleDrawRanges(mesh.segmentDrawRanges, visible: visible)
    }
    
    return mesh.chainDrawRanges
  }
  
  public var renderSelectedRibbonSegmentDrawRangeIndices: Set<Int>
  {
    return ProteinRibbonSegmentSupport.selectedSegmentDrawRangeIndices(in: atomTreeController)
  }
  
  public var renderSelectedRibbonResidueDrawRangeIndices: Set<Int>
  {
    return ProteinRibbonSegmentSupport.selectedResidueDrawRangeIndices(in: atomTreeController)
  }
  
  public var ribbonNumberOfChains: Int
  {
    return ribbonMesh.numberOfChains
  }
  
  public var ribbonNumberOfRings: Int
  {
    return ribbonMesh.numberOfRings
  }
  
  public override init()
  {
    super.init()
    self.drawUnitCell = false
    self.drawAtoms = false
    self.drawBonds = false
    reComputeBoundingBox()
  }
  
  public override init(name: String)
  {
    super.init(name: name)
    self.drawAtoms = false
    self.drawBonds = false
  }
  
  public required init(copy protein: Protein)
  {
    super.init(copy: protein)
    self.drawRibbon = protein.drawRibbon
    self.ribbonScaleFactor = protein.ribbonScaleFactor
    self.ribbonColorSet = protein.ribbonColorSet
    self.ribbonRepresentationStyle = protein.ribbonRepresentationStyle
    self.ribbonSecondaryStructureMethod = protein.ribbonSecondaryStructureMethod
    self.ribbonSplineType = protein.ribbonSplineType
    self.ribbonSubdivisionsPerSegment = protein.ribbonSubdivisionsPerSegment
    self.ribbonCrossSectionRingResolution = protein.ribbonCrossSectionRingResolution
    self.ribbonCoilRadiusScale = protein.ribbonCoilRadiusScale
    self.ribbonWidthClamp = protein.ribbonWidthClamp
    self.ribbonSheetArrowLengthExtent = protein.ribbonSheetArrowLengthExtent
    self.ribbonSheetArrowWingPosition = protein.ribbonSheetArrowWingPosition
    self.ribbonSheetArrowPeakWidthFactor = protein.ribbonSheetArrowPeakWidthFactor
    self.ribbonNormalSmoothingRadius = protein.ribbonNormalSmoothingRadius
    self.ribbonHDR = protein.ribbonHDR
    self.ribbonHDRExposure = protein.ribbonHDRExposure
    self.ribbonHue = protein.ribbonHue
    self.ribbonSaturation = protein.ribbonSaturation
    self.ribbonValue = protein.ribbonValue
    self.ribbonAmbientOcclusion = protein.ribbonAmbientOcclusion
    self.ribbonAmbientColor = protein.ribbonAmbientColor
    self.ribbonDiffuseColor = protein.ribbonDiffuseColor
    self.ribbonSpecularColor = protein.ribbonSpecularColor
    self.ribbonAmbientIntensity = protein.ribbonAmbientIntensity
    self.ribbonDiffuseIntensity = protein.ribbonDiffuseIntensity
    self.ribbonSpecularIntensity = protein.ribbonSpecularIntensity
    self.ribbonShininess = protein.ribbonShininess
  }
  
  public required init(clone protein: Protein)
  {
    super.init(clone: protein)
    self.drawRibbon = protein.drawRibbon
    self.ribbonScaleFactor = protein.ribbonScaleFactor
    self.ribbonColorSet = protein.ribbonColorSet
    self.ribbonRepresentationStyle = protein.ribbonRepresentationStyle
    self.ribbonSecondaryStructureMethod = protein.ribbonSecondaryStructureMethod
    self.ribbonSplineType = protein.ribbonSplineType
    self.ribbonSubdivisionsPerSegment = protein.ribbonSubdivisionsPerSegment
    self.ribbonCrossSectionRingResolution = protein.ribbonCrossSectionRingResolution
    self.ribbonCoilRadiusScale = protein.ribbonCoilRadiusScale
    self.ribbonWidthClamp = protein.ribbonWidthClamp
    self.ribbonSheetArrowLengthExtent = protein.ribbonSheetArrowLengthExtent
    self.ribbonSheetArrowWingPosition = protein.ribbonSheetArrowWingPosition
    self.ribbonSheetArrowPeakWidthFactor = protein.ribbonSheetArrowPeakWidthFactor
    self.ribbonNormalSmoothingRadius = protein.ribbonNormalSmoothingRadius
    self.ribbonHDR = protein.ribbonHDR
    self.ribbonHDRExposure = protein.ribbonHDRExposure
    self.ribbonHue = protein.ribbonHue
    self.ribbonSaturation = protein.ribbonSaturation
    self.ribbonValue = protein.ribbonValue
    self.ribbonAmbientOcclusion = protein.ribbonAmbientOcclusion
    self.ribbonAmbientColor = protein.ribbonAmbientColor
    self.ribbonDiffuseColor = protein.ribbonDiffuseColor
    self.ribbonSpecularColor = protein.ribbonSpecularColor
    self.ribbonAmbientIntensity = protein.ribbonAmbientIntensity
    self.ribbonDiffuseIntensity = protein.ribbonDiffuseIntensity
    self.ribbonSpecularIntensity = protein.ribbonSpecularIntensity
    self.ribbonShininess = protein.ribbonShininess
    rebuildBackbone()
  }
  
  public required init(from object: Object)
  {
    super.init(from: object)
    
    if let atomViewer: AtomViewer = object as? AtomViewer
    {
      if atomViewer.isFractional
      {
        self.atomTreeController.flattenedLeafNodes().forEach{
            let pos = $0.representedObject.position
            $0.representedObject.position = self.cell.convertToCartesian(pos)
          }
      }
    }
    
    _ = ProteinAtomTreeBuilder.applyHierarchyIfNeeded(to: self.atomTreeController,
                                                      secondaryStructureMethod: self.ribbonSecondaryStructureMethod)
    
    self.expandSymmetry()
    reComputeBoundingBox()
    reComputeBonds()
    self.atomTreeController.tag()
    self.bondSetController.tag()
    rebuildBackbone()
  }
  
  public func rebuildBackboneStructure()
  {
    let atoms: [SKAsymmetricAtom] = atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    self.backbone = ProteinBackbone.build(from: atoms)
  }
  
  public func rebuildBackbone()
  {
    guard drawRibbon else {return}
    rebuildBackboneStructure()
    rebuildRibbonMesh()
  }
  
  public func rebuildRibbonMesh()
  {
    guard drawRibbon else {return}
    migrateLegacySheetArrowDefaultsIfNeeded()
    let atomCount: Int = atomTreeController.flattenedLeafNodes().count
    let residueCount: Int = backbone.alphaCarbonResidueCount
    let meshParameters: ProteinRibbonMeshParameters = ribbonMeshParameters.effectiveForStructure(atomCount: atomCount, residueCount: residueCount)
    ribbonMesh = ProteinRibbonMeshBuilder.build(from: backbone,
                                                radius: ribbonScaleFactor,
                                                contentShift: cell.contentShift,
                                                parameters: meshParameters,
                                                secondaryStructureMethod: ribbonSecondaryStructureMethod)
    ribbonAmbientOcclusionStripHeight = meshParameters.crossSectionRingResolution
  }
  
  public override var colorAtomsWithBondColor: Bool
  {
    return (self.atomRepresentationType == .unity && self.bondColorMode == .uniform)
  }
  
  public override var materialType: Object.ObjectType
  {
    return .protein
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
    
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldViewer)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
    
    // only use leaf-nodes
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
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
        let cartesianPosition: SIMD3<Double> = copy.position + self.cell.contentShift
        
        //let w: Double = (atom.isVisible && atom.isVisibleEnabled) && !atomNode.isGroup ? 1.0 : -1.0
        let w: Double = (typeIsVisible && copy.asymmetricParentAtom.isVisible && copy.asymmetricParentAtom.isVisibleEnabled && asymetricAtom.symmetryType != .container) ? 1.0 : -1.0
        let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: Float(w))
        
        let radius: Double = isUnity ? 1.0 : copy.asymmetricParentAtom?.drawRadius ?? 1.0
        let ambient: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
        let diffuse: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
        let specular: NSColor = self.atomSpecularColor
        
        data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius), tag: UInt32(index))
        index = index + 1
      }
    }
    return data
  }
  
  public override var renderInternalBonds: [RKInPerInstanceAttributesBonds]
  {
    var index: Int = 0
    var data: [RKInPerInstanceAttributesBonds] = [RKInPerInstanceAttributesBonds](repeating: RKInPerInstanceAttributesBonds(), count: bondSetController.arrangedObjects.count * numberOfReplicas())
      
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldViewer)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
      
    index = 0
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
          
          let w: Double = (asymmetricBond.isVisible && typeIsVisible1 && typeIsVisible2 && (asymmetricAtom1.isVisible && asymmetricAtom2.isVisible) &&
                            (asymmetricAtom1.isVisibleEnabled && asymmetricAtom2.isVisibleEnabled)) ? 1.0 : -1.0
          
          data[index] = RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(x: pos1.x, y: pos1.y, z: pos1.z, w: w),
                                                         position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: w),
                                                         color1: SIMD4<Float>(color: color1),
                                                         color2: SIMD4<Float>(color: color2),
                                                         scale: SIMD4<Float>(x: drawRadius1, y: 1.0, z: drawRadius2, w: drawRadius1/drawRadius2),
                                                         tag: UInt32(asymmetricBondIndex),
                                                         type: UInt32(asymmetricBond.bondType.rawValue))
          index = index + 1
        }
      }
    }
    return data
  }
  
  
  public override var renderExternalBonds: [RKInPerInstanceAttributesBonds]
  {
    return []
  }
  
  // MARK: Rendering selection
  // =====================================================================
    
  public override var renderSelectedAtoms: [RKInPerInstanceAttributesAtoms]
  {
    var index: Int
    
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldViewer)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
    
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.allSelectedNodes.compactMap{$0.representedObject}
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
        let cartesianPosition: SIMD3<Double> = copy.position + asymetricAtom.displacement + self.cell.contentShift
        
        //let w: Double = (atom.isVisible && atom.isVisibleEnabled) && !atomNode.isGroup ? 1.0 : -1.0
        let w: Double = (typeIsVisible && copy.asymmetricParentAtom.isVisible && copy.asymmetricParentAtom.isVisibleEnabled && asymetricAtom.symmetryType != .container) ? 1.0 : -1.0
        let atomPosition: SIMD4<Float> = SIMD4<Float>(x: Float(cartesianPosition.x), y: Float(cartesianPosition.y), z: Float(cartesianPosition.z), w: Float(w))
        
        let radius: Double = isUnity ? 1.0 : (copy.asymmetricParentAtom?.drawRadius ?? 1.0)
        let ambient: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
        let diffuse: NSColor = copy.asymmetricParentAtom?.color ?? NSColor.white
        let specular: NSColor = self.atomSpecularColor
        
        data[index] = RKInPerInstanceAttributesAtoms(position: atomPosition, ambient: SIMD4<Float>(color: ambient), diffuse: SIMD4<Float>(color: diffuse), specular: SIMD4<Float>(color: specular), scale: Float(radius), tag: UInt32(asymetricIndex))
        index = index + 1
      }
    }
    return data
  }
  
  public override var renderSelectedInternalBonds: [RKInPerInstanceAttributesBonds]
  {
    var data: [RKInPerInstanceAttributesBonds] = []
      
    let forceFieldSets: SKForceFieldSets? = (NSDocumentController.shared.currentDocument as? ForceFieldViewer)?.forceFieldSets
    let forceFieldSet: SKForceFieldSet? = forceFieldSets?[self.atomForceFieldIdentifier]
      
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
          
          let w: Double = (asymmetricBond.isVisible && typeIsVisible1 && typeIsVisible2 && (asymmetricAtom1.isVisible && asymmetricAtom2.isVisible) &&
                            (asymmetricAtom1.isVisibleEnabled && asymmetricAtom2.isVisibleEnabled)) ? 1.0 : -1.0
          
          data.append(RKInPerInstanceAttributesBonds(position1: SIMD4<Float>(x: pos1.x, y: pos1.y, z: pos1.z, w: w),
                                                         position2: SIMD4<Float>(x: pos2.x, y: pos2.y, z: pos2.z, w: w),
                                                         color1: SIMD4<Float>(color: color1),
                                                         color2: SIMD4<Float>(color: color2),
                                                         scale: SIMD4<Float>(x: drawRadius1, y: 1.0, z: drawRadius2, w: drawRadius1/drawRadius2),
                                                         tag: UInt32(asymmetricBondIndex),
                                                         type: UInt32(asymmetricBond.bondType.rawValue)))
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
  
  public override func filterCartesianBondPositions(_ filter: (SIMD3<Double>) -> Bool) -> IndexSet
  {
    var data: IndexSet = IndexSet()
    
    for (asymmetricBondIndex, asymmetricBond) in self.bondSetController.arrangedObjects.enumerated()
    {
      let asymmetricAtom1: SKAsymmetricAtom =  asymmetricBond.atom1
      let asymmetricAtom2: SKAsymmetricAtom =  asymmetricBond.atom2
      let isVisible: Bool =  asymmetricBond.isVisible && asymmetricAtom1.isVisible && asymmetricAtom1.isVisibleEnabled && asymmetricAtom2.isVisible && asymmetricAtom2.isVisibleEnabled
      
      for bond in asymmetricBond.copies
      {
        let pos: SIMD3<Double> = 0.5 * (bond.atom1.position + bond.atom2.position)
        
        let rotationMatrix: double4x4 =  double4x4(transformation: double4x4(simd_quatd: self.orientation), aroundPoint: self.cell.boundingBox.center)
        let position: SIMD4<Double> = rotationMatrix * SIMD4<Double>(x: pos.x, y: pos.y, z: pos.z, w: 1.0)
        let absoluteCartesianPosition: SIMD3<Double> = SIMD3<Double>(position.x,position.y,position.z) + origin
        
        if filter(absoluteCartesianPosition) && isVisible
        {
          data.insert(asymmetricBondIndex)
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
      let newAtom: SKAtomCopy = SKAtomCopy(asymmetricParentAtom: asymmetricAtom, position: asymmetricAtom.position)
      newAtom.type = .copy
      asymmetricAtom.copies = [newAtom]
    }
  }
  
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
    var com: SIMD3<Double> = SIMD3<Double>(0.0, 0.0, 0.0)
    var M: Double = 0.0
    
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
  
  public override func matrixOfInertia(atoms: [SKAtomCopy]) -> double3x3
  {
    var inertiaMatrix: double3x3 = double3x3()
    let com: SIMD3<Double> = self.selectionCOMTranslation
    
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
         
        let bondCriteria: Double = (subsetAtoms[i].asymmetricParentAtom.bondDistanceCriteria + subsetAtoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
         
        let bondLength: Double = length(separationVector)
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
         
        let bondCriteria: Double = (subsetAtoms[i].asymmetricParentAtom.bondDistanceCriteria + atomList[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
         
        let bondLength: Double = length(separationVector)
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
    let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
    return boundaryBoxCell.unitCell
  }
  
  public override var cellLengthA: Double?
  {
    get
    {
      let boundaryBoxCell = SKCell(boundingBox: self.cell.boundingBox)
      return boundaryBoxCell.a
    }
    set(newValue)
    {
      self.cell.a = newValue ?? 20.0
    }
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
    let asymmetricAtoms: [SKAsymmetricAtom] = self.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap{$0.copies}.filter{$0.type == .copy}
    
    if atoms.isEmpty
    {
      return SKBoundingBox(minimum: SIMD3<Double>(0.0,0.0,0.0), maximum: SIMD3<Double>(0.0,0.0,0.0))
    }
    
    for atom in atoms
    {
      let cartesianPosition: SIMD4<Double> = SIMD4<Double>(atom.position.x,atom.position.y,atom.position.z,1.0)
      
      let radius: Double = (atom.asymmetricParentAtom?.drawRadius ?? 0.0) * self.atomScaleFactor
      
      minimum.x = min(minimum.x, cartesianPosition.x - radius)
      minimum.y = min(minimum.y, cartesianPosition.y - radius)
      minimum.z = min(minimum.z, cartesianPosition.z - radius)
      
      maximum.x = max(maximum.x, cartesianPosition.x + radius)
      maximum.y = max(maximum.y, cartesianPosition.y + radius)
      maximum.z = max(maximum.z, cartesianPosition.z + radius)
    }
    
    return SKBoundingBox(minimum: minimum, maximum: maximum)
  }
  

  
  
  public override var crystallographicPositions: [(SIMD3<Double>, Int, Double)]
  {
    return []
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
  
  // MARK: Measuring distance, angle, and dihedral-angles
  // =====================================================================
  
  // Used in the routine to measure distances and bend/dihedral angles
  override public func absoluteCartesianModelPosition(for position: SIMD3<Double>, replicaPosition: SIMD3<Int32>) -> SIMD3<Double>
  {
    return position
  }
  
  // Used in the routine to measure distances and bend/dihedral angles
  override public func absoluteCartesianScenePosition(for position: SIMD3<Double>, replicaPosition: SIMD3<Int32>) -> SIMD3<Double>
  {
    let rotationMatrix: double4x4 =  double4x4(transformation: double4x4(simd_quatd: self.orientation), aroundPoint: self.cell.boundingBox.center)
    let position: SIMD4<Double> = rotationMatrix * SIMD4<Double>(x: position.x, y: position.y, z: position.z, w: 1.0)
    let absoluteCartesianPosition: SIMD3<Double> = SIMD3<Double>(position.x,position.y,position.z) + origin
    return absoluteCartesianPosition
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
    return computedBonds
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
    
    //atoms.forEach{ $0.bonds.removeAll()}

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
                    
                    let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
                    
                    let bondLength: Double = length(separationVector)
                    if (bondLength < 0.8)
                    {
                      // discard as being a bond
                    }
                    else if (bondLength < bondCriteria)
                    {
                      computedBonds.append(SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .internal))
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
          
          let bondCriteria: Double = (atoms[i].asymmetricParentAtom.bondDistanceCriteria + atoms[j].asymmetricParentAtom.bondDistanceCriteria + 0.4)
          
          let bondLength: Double = length(separationVector)
          if (bondLength < 0.8)
          {
            // discard as being a bond
          }
          else if (bondLength < bondCriteria )
          {
            computedBonds.append(SKBondNode(atom1: atoms[i], atom2: atoms[j], boundaryType: .internal))
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
    return Protein.RecomputeBondsOperation(structure: structure, windowController: windowController)
  }
  
  
  public class RecomputeBondsOperation: FKOperation, @unchecked Sendable
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
      
      let computedBonds = structure.computeBonds(cell: structure.cell, atomList: atoms)
      
      //structure.bonds.arrangedObjects = computedBonds
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
    encoder.encode(Protein.classVersionNumber)
    encoder.encode(Int(0x6f6b6187))
    encoder.encode(ribbonColorSet.rawValue)
    if Protein.classVersionNumber >= 4
    {
      encoder.encode(ribbonHDR)
      encoder.encode(ribbonHDRExposure)
      encoder.encode(ribbonHue)
      encoder.encode(ribbonSaturation)
      encoder.encode(ribbonValue)
      encoder.encode(ribbonAmbientOcclusion)
      encoder.encode(ribbonAmbientColor)
      encoder.encode(ribbonDiffuseColor)
      encoder.encode(ribbonSpecularColor)
      encoder.encode(ribbonAmbientIntensity)
      encoder.encode(ribbonDiffuseIntensity)
      encoder.encode(ribbonSpecularIntensity)
      encoder.encode(ribbonShininess)
    }
    if Protein.classVersionNumber >= 5
    {
      encoder.encode(ribbonSplineType.rawValue)
      encoder.encode(ribbonSubdivisionsPerSegment)
      encoder.encode(ribbonCrossSectionRingResolution)
      encoder.encode(ribbonCoilRadiusScale)
      encoder.encode(ribbonWidthClamp)
      encoder.encode(ribbonSheetArrowLengthExtent)
      encoder.encode(ribbonSheetArrowWingPosition)
      encoder.encode(ribbonSheetArrowPeakWidthFactor)
      encoder.encode(ribbonNormalSmoothingRadius)
    }
    if Protein.classVersionNumber >= 6
    {
      encoder.encode(ribbonRepresentationStyle.rawValue)
    }
    if Protein.classVersionNumber >= 7
    {
      encoder.encode(ribbonSecondaryStructureMethod.rawValue)
    }
    super.binaryEncode(to: encoder)
  }
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > Protein.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    if(readVersionNumber >= 2)
    {
      let magicNumber = try decoder.decode(Int.self)
      if magicNumber != Int(0x6f6b6187)
      {
        throw BinaryDecodableError.invalidMagicNumber
      }
    }
    
    if readVersionNumber >= 3
    {
      let colorSetIdentifier: String = try decoder.decode(String.self)
      self.ribbonColorSet = ProteinRibbonColorSet(rawValue: colorSetIdentifier) ?? .standardAcademic
    }
    
    if readVersionNumber >= 4
    {
      self.ribbonHDR = try decoder.decode(Bool.self)
      self.ribbonHDRExposure = try decoder.decode(Double.self)
      self.ribbonHue = try decoder.decode(Double.self)
      self.ribbonSaturation = try decoder.decode(Double.self)
      self.ribbonValue = try decoder.decode(Double.self)
      self.ribbonAmbientOcclusion = try decoder.decode(Bool.self)
      self.ribbonAmbientColor = try decoder.decode(NSColor.self)
      self.ribbonDiffuseColor = try decoder.decode(NSColor.self)
      self.ribbonSpecularColor = try decoder.decode(NSColor.self)
      self.ribbonAmbientIntensity = try decoder.decode(Double.self)
      self.ribbonDiffuseIntensity = try decoder.decode(Double.self)
      self.ribbonSpecularIntensity = try decoder.decode(Double.self)
      self.ribbonShininess = try decoder.decode(Double.self)
    }
    
    if readVersionNumber >= 5
    {
      let splineTypeIdentifier: String = try decoder.decode(String.self)
      self.ribbonSplineType = ProteinRibbonSplineType(rawValue: splineTypeIdentifier) ?? .bSpline
      self.ribbonSubdivisionsPerSegment = try decoder.decode(Int.self)
      self.ribbonCrossSectionRingResolution = try decoder.decode(Int.self)
      self.ribbonCoilRadiusScale = try decoder.decode(Double.self)
      self.ribbonWidthClamp = try decoder.decode(Double.self)
      self.ribbonSheetArrowLengthExtent = try decoder.decode(Double.self)
      self.ribbonSheetArrowWingPosition = try decoder.decode(Double.self)
      self.ribbonSheetArrowPeakWidthFactor = try decoder.decode(Double.self)
      self.ribbonNormalSmoothingRadius = try decoder.decode(Int.self)
    }
    
    if readVersionNumber >= 6
    {
      let representationStyleIdentifier: String = try decoder.decode(String.self)
      self.ribbonRepresentationStyle = ProteinRibbonRepresentationStyle(rawValue: representationStyleIdentifier) ?? .default
    }
    else if readVersionNumber >= 4
    {
      self.ribbonRepresentationStyle = self.ribbonAmbientOcclusion ? .fancy : .default
    }
    
    if readVersionNumber >= 7
    {
      let secondaryStructureMethodIdentifier: String = try decoder.decode(String.self)
      self.ribbonSecondaryStructureMethod = ProteinRibbonSecondaryStructureMethod(rawValue: secondaryStructureMethodIdentifier) ?? .stride
    }
    
    try super.init(fromBinary: decoder)
    self.recheckRibbonRepresentationStyle()
    _ = ProteinAtomTreeBuilder.applyHierarchyIfNeeded(to: self.atomTreeController,
                                                      secondaryStructureMethod: self.ribbonSecondaryStructureMethod)
    rebuildBackbone()
  }
}

