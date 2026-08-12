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
import SymmetryKit

public enum ProteinRibbonSecondaryStructure: Sendable
{
  case coil
  case helix
  case sheet
  
  /// Ribbon display color: coil blue, α-helix green, β-sheet magenta.
  public var ribbonColor: SIMD3<Float>
  {
    switch self
    {
    case .coil: return SIMD3<Float>(0.0, 0.0, 1.0)
    case .helix: return SIMD3<Float>(0.0, 1.0, 0.0)
    case .sheet: return SIMD3<Float>(1.0, 0.0, 1.0)
    }
  }
  
  init(_ type: SKSecondaryStructureType)
  {
    switch type
    {
    case .coil: self = .coil
    case .helix: self = .helix
    case .sheet: self = .sheet
    }
  }
}

public struct ProteinRibbonSecondaryStructureAssigner
{
  public static func assign(for chain: ProteinBackboneChain,
                            contentShift: SIMD3<Double>,
                            method: ProteinRibbonSecondaryStructureMethod = .stride) -> [ProteinRibbonSecondaryStructure]
  {
    let backboneChain: SKStrideBackboneChain = makeBackboneChain(from: chain, contentShift: contentShift)
    return SKSecondaryStructureAssigner.assign(for: backboneChain, method: method.assignmentMethod).map{ProteinRibbonSecondaryStructure($0)}
  }
  
  public static func assign(for chain: ProteinBackboneChain,
                            contentShift: SIMD3<Double>,
                            method: SKSecondaryStructureAssignmentMethod) -> [ProteinRibbonSecondaryStructure]
  {
    let backboneChain: SKStrideBackboneChain = makeBackboneChain(from: chain, contentShift: contentShift)
    return SKSecondaryStructureAssigner.assign(for: backboneChain, method: method).map{ProteinRibbonSecondaryStructure($0)}
  }
  
  public static func assign(for centers: [SIMD3<Double>]) -> [ProteinRibbonSecondaryStructure]
  {
    return [ProteinRibbonSecondaryStructure](repeating: .coil, count: centers.count)
  }
  
  public static func interpolate(_ a: ProteinRibbonSecondaryStructure,
                                 _ b: ProteinRibbonSecondaryStructure,
                                 t: Double) -> ProteinRibbonSecondaryStructure
  {
    if t < 0.5 {return a}
    return b
  }
  
  public static func isSheetLeadingEdge(residueIndex: Int, assignment: [ProteinRibbonSecondaryStructure]) -> Bool
  {
    guard residueIndex >= 0 && residueIndex < assignment.count else {return false}
    guard assignment[residueIndex] == .sheet else {return false}
    return residueIndex == 0 || assignment[residueIndex - 1] != .sheet
  }
  
  public static func isSheetTrailingEdge(residueIndex: Int, assignment: [ProteinRibbonSecondaryStructure]) -> Bool
  {
    guard residueIndex >= 0 && residueIndex < assignment.count else {return false}
    guard assignment[residueIndex] == .sheet else {return false}
    return residueIndex == assignment.count - 1 || assignment[residueIndex + 1] != .sheet
  }
  
  private static func makeBackboneChain(from chain: ProteinBackboneChain, contentShift: SIMD3<Double>) -> SKStrideBackboneChain
  {
    let residues: [SKStrideBackboneResidue] = chain.residues.filter{$0.alphaCarbon != nil}.map
    { residue in
      SKStrideBackboneResidue(residueName: residue.residueName,
                              nitrogen: shiftedPosition(residue.nitrogen, contentShift: contentShift),
                              alphaCarbon: shiftedPosition(residue.alphaCarbon, contentShift: contentShift),
                              carbonylCarbon: shiftedPosition(residue.carbonylCarbon, contentShift: contentShift),
                              carbonylOxygen: shiftedPosition(residue.carbonylOxygen, contentShift: contentShift))
    }
    return SKStrideBackboneChain(chainIdentifier: chain.chainIdentifier, residues: residues)
  }
  
  private static func shiftedPosition(_ atom: SKAsymmetricAtom?, contentShift: SIMD3<Double>) -> SIMD3<Double>?
  {
    guard let atom: SKAsymmetricAtom = atom else {return nil}
    return atom.position + contentShift
  }
}
