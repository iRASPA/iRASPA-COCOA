/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions
 of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

import Foundation
import simd
import SymmetryKit
import BinaryCodable
import SimulationKit
import MathKit

public enum ProteinAminoAcidResidueReplacer
{
  public static func isProteinStructure(_ structure: Structure) -> Bool
  {
    return structure is Protein || structure is ProteinCrystal
  }
  
  public static func isKnownAminoAcidResidueName(_ residueName: String) -> Bool
  {
    let trimmedName: String = residueName.uppercased().trimmingCharacters(in: .whitespaces)
    if SKAminoAcidIdealGeometry.idealCoordinates(for: trimmedName) != nil
    {
      return true
    }
    return normalizedResidueCode(trimmedName).flatMap{SKAminoAcidIdealGeometry.idealCoordinates(for: $0)} != nil
  }
  
  private static func normalizedResidueCode(_ residueName: String) -> String?
  {
    switch residueName
    {
    case "MSE", "SEC": return "MET"
    case "HSD", "HSE", "HSP": return "HIS"
    case "CYX", "CYM": return "CYS"
    case "ASH": return "ASP"
    case "GLH": return "GLU"
    default: return nil
    }
  }
  
  public static func isAminoAcidResidueGroupNode(_ node: SKAtomTreeNode) -> Bool
  {
    guard node.isGroup else {return false}
    let atomNodes: [SKAtomTreeNode] = node.descendantLeafNodes()
    guard let referenceAtom: SKAsymmetricAtom = atomNodes.first?.representedObject,
          isKnownAminoAcidResidueName(referenceAtom.residueName) else {return false}
    return atomNodes.allSatisfy
    {
      let atom: SKAsymmetricAtom = $0.representedObject
      return atom.chainIdentifier == referenceAtom.chainIdentifier
        && atom.residueSequenceNumber == referenceAtom.residueSequenceNumber
        && atom.codeForInsertionOfResidues == referenceAtom.codeForInsertionOfResidues
        && isKnownAminoAcidResidueName(atom.residueName)
    }
  }
  
  public static func residueContext(for clickedNode: SKAtomTreeNode,
                                    in controller: SKAtomTreeController) -> (residueNode: SKAtomTreeNode?, atomNodes: [SKAtomTreeNode])?
  {
    if ProteinRibbonSegmentSupport.isResidueGroupNode(clickedNode) || isAminoAcidResidueGroupNode(clickedNode)
    {
      let atomNodes: [SKAtomTreeNode] = clickedNode.descendantLeafNodes()
      guard let firstAtom: SKAsymmetricAtom = atomNodes.first?.representedObject,
            isKnownAminoAcidResidueName(firstAtom.residueName) else {return nil}
      return (clickedNode, atomNodes)
    }
    
    if let residueNode: SKAtomTreeNode = ProteinRibbonSegmentSupport.enclosingResidueGroupNode(for: clickedNode)
    {
      let atomNodes: [SKAtomTreeNode] = residueNode.descendantLeafNodes()
      guard let firstAtom: SKAsymmetricAtom = atomNodes.first?.representedObject,
            isKnownAminoAcidResidueName(firstAtom.residueName) else {return nil}
      return (residueNode, atomNodes)
    }
    
    if clickedNode.isGroup
    {
      var node: SKAtomTreeNode? = clickedNode.parentNode
      while let current: SKAtomTreeNode = node
      {
        if ProteinRibbonSegmentSupport.isResidueGroupNode(current) || isAminoAcidResidueGroupNode(current)
        {
          let atomNodes: [SKAtomTreeNode] = current.descendantLeafNodes()
          guard let firstAtom: SKAsymmetricAtom = atomNodes.first?.representedObject,
                isKnownAminoAcidResidueName(firstAtom.residueName) else {return nil}
          return (current, atomNodes)
        }
        node = current.parentNode
      }
    }
    
    guard clickedNode.isLeaf else {return nil}
    let referenceAtom: SKAsymmetricAtom = clickedNode.representedObject
    guard isKnownAminoAcidResidueName(referenceAtom.residueName) else {return nil}
    
    let atomNodes: [SKAtomTreeNode] = controller.flattenedLeafNodes().filter
    {
      let atom: SKAsymmetricAtom = $0.representedObject
      return atom.chainIdentifier == referenceAtom.chainIdentifier
        && atom.residueSequenceNumber == referenceAtom.residueSequenceNumber
        && atom.codeForInsertionOfResidues == referenceAtom.codeForInsertionOfResidues
        && isKnownAminoAcidResidueName(atom.residueName)
    }
    guard !atomNodes.isEmpty else {return nil}
    return (nil, atomNodes)
  }
  
  public static func currentResidueCode(for atomNodes: [SKAtomTreeNode]) -> String?
  {
    guard let residueName: String = atomNodes.first?.representedObject.residueName else {return nil}
    let trimmedName: String = residueName.uppercased().trimmingCharacters(in: .whitespaces)
    return trimmedName.isEmpty ? nil : trimmedName
  }
  
  public static func snapshotAtomBondState(for structure: Structure) -> (atoms: SKAtomTreeController, bonds: SKBondSetController)?
  {
    structure.atomTreeController.tag()
    structure.bondSetController.tag()
    
    let binaryAtomEncoder: BinaryEncoder = BinaryEncoder()
    binaryAtomEncoder.encode(structure.atomTreeController)
    let atomData: Data = Data(binaryAtomEncoder.data)
    
    let binaryBondEncoder: BinaryEncoder = BinaryEncoder()
    binaryBondEncoder.encode(structure.bondSetController)
    let bondData: Data = Data(binaryBondEncoder.data)
    
    do
    {
      let atoms: SKAtomTreeController = try BinaryDecoder(data: [UInt8](atomData)).decode(SKAtomTreeController.self)
      let bonds: SKBondSetController = try BinaryDecoder(data: [UInt8](bondData)).decode(SKBondSetController.self)
      bonds.restoreBonds(atomTreeController: atoms)
      return (atoms, bonds)
    }
    catch
    {
      return nil
    }
  }
  
  @discardableResult
  public static func replaceResidue(in structure: Structure,
                                    residueNode: SKAtomTreeNode?,
                                    atomNodes: [SKAtomTreeNode],
                                    with newResidueCode: String,
                                    colorSets: SKColorSets,
                                    forceFieldSets: SKForceFieldSets) -> Bool
  {
    guard isProteinStructure(structure),
          let atomEditor: AtomEditor = structure as? AtomEditor,
          let bondEditor: BondEditor = structure as? BondEditor else {return false}
    
    let trimmedNewCode: String = newResidueCode.uppercased().trimmingCharacters(in: .whitespaces)
    guard SKAminoAcidIdealGeometry.idealCoordinates(for: trimmedNewCode) != nil else {return false}
    
    guard let backbonePositions: (n: SIMD3<Double>, ca: SIMD3<Double>, c: SIMD3<Double>) = backbonePositions(in: atomNodes) else {return false}
    guard let alignedCoordinates: [String: SIMD3<Double>] = SKAminoAcidIdealGeometry.alignedCoordinates(for: trimmedNewCode,
                                                                                                          actualN: backbonePositions.n,
                                                                                                          actualCA: backbonePositions.ca,
                                                                                                          actualC: backbonePositions.c) else {return false}
    
    let templateAtom: SKAsymmetricAtom = atomNodes.first!.representedObject
    let preservedProperties: [String: SKAsymmetricAtom] = Dictionary(uniqueKeysWithValues: atomNodes.map
    {
      ($0.representedObject.displayName.uppercased().trimmingCharacters(in: .whitespaces), $0.representedObject)
    })
    
    let newAtomNodes: [SKAtomTreeNode] = alignedCoordinates.keys.sorted().compactMap
    {
      atomName -> SKAtomTreeNode? in
      guard let position: SIMD3<Double> = alignedCoordinates[atomName] else {return nil}
      return makeAtomTreeNode(atomName: atomName,
                              residueCode: trimmedNewCode,
                              position: position,
                              templateAtom: templateAtom,
                              preservedAtom: preservedProperties[atomName.uppercased().trimmingCharacters(in: .whitespaces)],
                              structure: structure,
                              atomEditor: atomEditor,
                              colorSets: colorSets,
                              forceFieldSets: forceFieldSets)
    }
    guard !newAtomNodes.isEmpty else {return false}
    
    let parentNode: SKAtomTreeNode?
    if let residueNode: SKAtomTreeNode = residueNode
    {
      parentNode = residueNode
      for child in residueNode.childNodes
      {
        structure.atomTreeController.removeNode(child)
      }
      for (index, atomNode) in newAtomNodes.enumerated()
      {
        structure.atomTreeController.insertNode(atomNode, inItem: residueNode, atIndex: index)
      }
      updateResidueGroupDisplayName(residueNode, residueCode: trimmedNewCode, templateAtom: templateAtom)
    }
    else
    {
      parentNode = atomNodes.first?.parentNode
      let insertionIndex: Int = atomNodes.first?.indexPath.last ?? 0
      for atomNode in atomNodes.sorted(by: {$0.indexPath > $1.indexPath})
      {
        structure.atomTreeController.removeNode(atomNode)
      }
      for (offset, atomNode) in newAtomNodes.enumerated()
      {
        structure.atomTreeController.insertNode(atomNode, inItem: parentNode, atIndex: insertionIndex + offset)
      }
    }
    
    let replacedAtoms: [SKAsymmetricAtom] = newAtomNodes.map{$0.representedObject}
    let newBonds: [SKBondNode] = structure.bonds(subset: replacedAtoms)
    bondEditor.bondSetController.replaceBonds(atoms: replacedAtoms, bonds: newBonds)
    
    structure.atomTreeController.tag()
    bondEditor.bondSetController.tag()
    structure.reComputeBoundingBox()
    
    if let ribbonEditor: ProteinRibbonStructureEditor = structure as? ProteinRibbonStructureEditor
    {
      ribbonEditor.rebuildBackbone()
    }
    
    structure.applyRepresentationStyle()
    structure.setRepresentationColorScheme(scheme: structure.atomColorSchemeIdentifier, colorSets: colorSets)
    structure.setRepresentationForceField(forceField: structure.atomForceFieldIdentifier, forceFieldSets: forceFieldSets)
    
    _ = parentNode
    return true
  }
  
  private static func backbonePositions(in atomNodes: [SKAtomTreeNode]) -> (n: SIMD3<Double>, ca: SIMD3<Double>, c: SIMD3<Double>)?
  {
    var nitrogenPosition: SIMD3<Double>?
    var alphaCarbonPosition: SIMD3<Double>?
    var carbonylPosition: SIMD3<Double>?
    
    for atomNode in atomNodes
    {
      let atom: SKAsymmetricAtom = atomNode.representedObject
      switch atom.backboneAtomRole
      {
      case .nitrogen:
        nitrogenPosition = atom.position
      case .alphaCarbon:
        alphaCarbonPosition = atom.position
      case .carbonylCarbon:
        carbonylPosition = atom.position
      default:
        let atomName: String = atom.displayName.uppercased().trimmingCharacters(in: .whitespaces)
        if atomName == "N" {nitrogenPosition = atom.position}
        if atomName == "CA" {alphaCarbonPosition = atom.position}
        if atomName == "C" {carbonylPosition = atom.position}
      }
    }
    
    guard let nitrogenPosition: SIMD3<Double> = nitrogenPosition,
          let alphaCarbonPosition: SIMD3<Double> = alphaCarbonPosition,
          let carbonylPosition: SIMD3<Double> = carbonylPosition else {return nil}
    return (nitrogenPosition, alphaCarbonPosition, carbonylPosition)
  }
  
  private static func makeAtomTreeNode(atomName: String,
                                       residueCode: String,
                                       position: SIMD3<Double>,
                                       templateAtom: SKAsymmetricAtom,
                                       preservedAtom: SKAsymmetricAtom?,
                                       structure: Structure,
                                       atomEditor: AtomEditor,
                                       colorSets: SKColorSets,
                                       forceFieldSets: SKForceFieldSets) -> SKAtomTreeNode
  {
    let definitionKey: String = residueCode + "+" + atomName.uppercased().trimmingCharacters(in: .whitespaces)
    let definition: SKResidueAtomDefinition? = SKElement.residueDefinitions[definitionKey]
    
    let elementSymbol: String = definition?.element ?? preservedAtom?.uniqueForceFieldName ?? "C"
    let elementIdentifier: Int = SKElement.atomicNumber(forSymbol: elementSymbol) ?? preservedAtom?.elementIdentifier ?? 6
    let uniqueForceFieldName: String = PredefinedElements.sharedInstance.elementSet[elementIdentifier].chemicalSymbol
    
    let color: NSColor = colorSets[atomEditor.atomColorSchemeIdentifier]?[uniqueForceFieldName] ?? preservedAtom?.color ?? NSColor.black
    let drawRadius: Double = structure.drawRadius(elementId: elementIdentifier)
    let bondDistanceCriteria: Double = forceFieldSets[atomEditor.atomForceFieldIdentifier]?[uniqueForceFieldName]?.userDefinedRadius ?? preservedAtom?.bondDistanceCriteria ?? 1.0
    
    let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: atomName,
                                                  elementId: elementIdentifier,
                                                  uniqueForceFieldName: uniqueForceFieldName,
                                                  position: position,
                                                  charge: preservedAtom?.charge ?? 0.0,
                                                  color: color,
                                                  drawRadius: drawRadius,
                                                  bondDistanceCriteria: bondDistanceCriteria,
                                                  occupancy: preservedAtom?.occupancy ?? templateAtom.occupancy)
    atom.symmetryType = .asymmetric
    atom.residueName = residueCode
    atom.chainIdentifier = templateAtom.chainIdentifier
    atom.residueSequenceNumber = templateAtom.residueSequenceNumber
    atom.codeForInsertionOfResidues = templateAtom.codeForInsertionOfResidues
    atom.segmentIdentifier = templateAtom.segmentIdentifier
    atom.asymetricID = templateAtom.asymetricID
    atom.alternateLocationIndicator = preservedAtom?.alternateLocationIndicator ?? templateAtom.alternateLocationIndicator
    atom.temperaturefactor = preservedAtom?.temperaturefactor ?? templateAtom.temperaturefactor
    atom.isVisible = preservedAtom?.isVisible ?? templateAtom.isVisible
    atom.isVisibleEnabled = preservedAtom?.isVisibleEnabled ?? templateAtom.isVisibleEnabled
    atom.isFixed = preservedAtom?.isFixed ?? templateAtom.isFixed
    atom.fractional = templateAtom.fractional
    atom.backBoneAtom = SKElement.isBackboneAtomType(definition?.type ?? "")
    
    atomEditor.expandSymmetry(asymmetricAtom: atom)
    return SKAtomTreeNode(representedObject: atom)
  }
  
  private static func updateResidueGroupDisplayName(_ residueNode: SKAtomTreeNode,
                                                     residueCode: String,
                                                     templateAtom: SKAsymmetricAtom)
  {
    var label: String = "\(residueCode) \(templateAtom.residueSequenceNumber)"
    if templateAtom.codeForInsertionOfResidues != Character(" ")
    {
      label += String(templateAtom.codeForInsertionOfResidues)
    }
    residueNode.displayName = label
    residueNode.representedObject.displayName = label
  }
}
