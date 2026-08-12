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

public class SKmmCIFWriter
{
  // The lazy initialization of the shared instance is thread safe by the definition of let
  public static let shared: SKmmCIFWriter = SKmmCIFWriter()
  
  private init()
  {
  }
  
  public func string(displayName: String, spaceGroupHallNumber: Int?, cell: SKCell, atoms: [SKAsymmetricAtom], atomsAreFractional: Bool, exportFractional: Bool, withProteinInfo: Bool, origin: SIMD3<Double>) -> String
  {
    var dataString: String = ""
    
    let numberFormatter: NumberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    numberFormatter.formatWidth = 12
    numberFormatter.minimumFractionDigits = 6
    numberFormatter.maximumFractionDigits = 6
    numberFormatter.minimumIntegerDigits = 1
    numberFormatter.negativePrefix = "-"
    numberFormatter.positivePrefix = " "
    numberFormatter.paddingCharacter = " "
    numberFormatter.usesGroupingSeparator = false
    numberFormatter.groupingSeparator = ""
    numberFormatter.decimalSeparator = "."
    
    let occupancyFormatter: NumberFormatter = NumberFormatter()
    occupancyFormatter.numberStyle = .decimal
    occupancyFormatter.minimumFractionDigits = 2
    occupancyFormatter.maximumFractionDigits = 2
    occupancyFormatter.usesGroupingSeparator = false
    occupancyFormatter.decimalSeparator = "."
    
    let safeName: String = Self.cifDataBlockName(from: displayName)
    
    // write local header
    dataString += "data_\(safeName)\n\n"
    
    // write cell data (mmCIF dotted tags)
    dataString += "_cell.length_a     \(numberFormatter.string(from: NSNumber(value: cell.a))!)\n"
    dataString += "_cell.length_b     \(numberFormatter.string(from: NSNumber(value: cell.b))!)\n"
    dataString += "_cell.length_c     \(numberFormatter.string(from: NSNumber(value: cell.c))!)\n"
    dataString += "_cell.angle_alpha  \(numberFormatter.string(from: NSNumber(value: cell.alpha * 180.0/Double.pi))!)\n"
    dataString += "_cell.angle_beta   \(numberFormatter.string(from: NSNumber(value: cell.beta * 180.0/Double.pi))!)\n"
    dataString += "_cell.angle_gamma  \(numberFormatter.string(from: NSNumber(value: cell.gamma * 180.0/Double.pi))!)\n"
    if cell.zValue > 0
    {
      dataString += "_cell.Z_PDB        \(cell.zValue)\n"
    }
    dataString += "\n"
    
    let spaceGroup = SKSpacegroup(HallNumber: spaceGroupHallNumber ?? 1)
    dataString += "_symmetry.space_group_name_Hall '\(spaceGroup.spaceGroupSetting.Hall)'\n"
    dataString += "_symmetry.pdbx_full_space_group_name_H-M '\(spaceGroup.spaceGroupSetting.HM)'\n"
    dataString += "_symmetry.Int_Tables_number \(spaceGroup.spaceGroupSetting.number)\n\n"
    
    // write structure atom data
    dataString += "loop_\n"
    dataString += "_atom_site.group_PDB\n"
    dataString += "_atom_site.id\n"
    dataString += "_atom_site.type_symbol\n"
    if withProteinInfo
    {
      dataString += "_atom_site.label_atom_id\n"
      dataString += "_atom_site.label_alt_id\n"
      dataString += "_atom_site.label_comp_id\n"
      dataString += "_atom_site.label_asym_id\n"
      dataString += "_atom_site.label_entity_id\n"
      dataString += "_atom_site.label_seq_id\n"
      dataString += "_atom_site.pdbx_PDB_ins_code\n"
    }
    else
    {
      dataString += "_atom_site.label_atom_id\n"
    }
    dataString += exportFractional ? "_atom_site.fract_x\n" : "_atom_site.Cartn_x\n"
    dataString += exportFractional ? "_atom_site.fract_y\n" : "_atom_site.Cartn_y\n"
    dataString += exportFractional ? "_atom_site.fract_z\n" : "_atom_site.Cartn_z\n"
    dataString += "_atom_site.occupancy\n"
    if withProteinInfo
    {
      dataString += "_atom_site.auth_seq_id\n"
      dataString += "_atom_site.auth_comp_id\n"
      dataString += "_atom_site.auth_asym_id\n"
      dataString += "_atom_site.auth_atom_id\n"
    }
    dataString += "_atom_site.charge\n"
    
    let unitCell: double3x3 = cell.unitCell
    let inverseUnitCell: double3x3 = cell.inverseUnitCell
    var serial: Int = 1
    for atom in atoms
    {
      let position: SIMD3<Double>
      if atomsAreFractional && !exportFractional
      {
        position = unitCell * atom.position - origin
      }
      else if !atomsAreFractional && exportFractional
      {
        position = inverseUnitCell * (atom.position - origin)
      }
      else
      {
        position = atom.position - origin
      }
      
      let chemicalElement: String = PredefinedElements.sharedInstance.elementSet[atom.elementIdentifier].chemicalSymbol
      let groupPDB: String = (withProteinInfo && atom.solvent) ? "HETATM" : "ATOM"
      let atomId: Int = atom.serialNumber > 0 ? atom.serialNumber : serial
      let atomName: String = Self.atomName(for: atom, chemicalElement: chemicalElement)
      
      guard let positionX: String = numberFormatter.string(from: NSNumber(value: position.x)),
            let positionY: String = numberFormatter.string(from: NSNumber(value: position.y)),
            let positionZ: String = numberFormatter.string(from: NSNumber(value: position.z)),
            let occupancy: String = occupancyFormatter.string(from: NSNumber(value: atom.occupancy)),
            let charge: String = numberFormatter.string(from: NSNumber(value: atom.charge))
      else
      {
        serial += 1
        continue
      }
      
      if withProteinInfo
      {
        let residueName: String = atom.residueName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "UNK" : atom.residueName
        let chain: String = (atom.chainIdentifier == " " || atom.chainIdentifier == "\0") ? "A" : String(atom.chainIdentifier)
        let sequenceId: String = atom.residueSequenceNumber == 0 ? "?" : String(atom.residueSequenceNumber)
        let insertionCode: String = (atom.codeForInsertionOfResidues == " " || atom.codeForInsertionOfResidues == "\0") ? "?" : String(atom.codeForInsertionOfResidues)
        let altId: String = (atom.alternateLocationIndicator == " " || atom.alternateLocationIndicator == "\0") ? "." : String(atom.alternateLocationIndicator)
        
        dataString += "\(groupPDB) \(atomId) \(chemicalElement) \(atomName) \(altId) \(residueName) \(chain) ? \(sequenceId) \(insertionCode) \(positionX) \(positionY) \(positionZ) \(occupancy) \(sequenceId) \(residueName) \(chain) \(atomName) \(charge)\n"
      }
      else
      {
        dataString += "\(groupPDB) \(atomId) \(chemicalElement) \(atomName) \(positionX) \(positionY) \(positionZ) \(occupancy) \(charge)\n"
      }
      serial += 1
    }
    
    return dataString
  }
  
  private static func cifDataBlockName(from displayName: String) -> String
  {
    let trimmed: String = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
    let mapped: String = String(trimmed.map { character -> Character in
      let scalars = String(character).unicodeScalars
      return scalars.allSatisfy { allowed.contains($0) } ? character : "_"
    })
    return mapped.isEmpty ? "structure" : mapped
  }
  
  private static func atomName(for atom: SKAsymmetricAtom, chemicalElement: String) -> String
  {
    let display: String = atom.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    if !display.isEmpty
    {
      return display.contains(" ") ? "'\(display)'" : display
    }
    
    var name: String = chemicalElement
    if atom.remotenessIndicator != " " && atom.remotenessIndicator != "\0"
    {
      name.append(atom.remotenessIndicator)
    }
    if atom.branchDesignator != " " && atom.branchDesignator != "\0"
    {
      name.append(atom.branchDesignator)
    }
    return name
  }
}
