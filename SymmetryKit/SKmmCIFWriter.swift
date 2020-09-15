/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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
    numberFormatter.formatWidth = 14
    numberFormatter.minimumFractionDigits = 8
    numberFormatter.minimumIntegerDigits = 1
    numberFormatter.negativePrefix = "-"
    numberFormatter.positivePrefix = " "
    numberFormatter.paddingCharacter = " "
    numberFormatter.usesGroupingSeparator = false
    numberFormatter.groupingSeparator = ""
    numberFormatter.decimalSeparator = "."
    
    // write local header
    dataString += String("data_\(displayName)\n") + "\n"
    
    // write spacegroup data
    dataString += String("_cell.length_a    \(numberFormatter.string(from: NSNumber(value: cell.a))!)\n")
    dataString += String("_cell.length_b    \(numberFormatter.string(from: NSNumber(value: cell.b))!)\n")
    dataString += String("_cell.length_c    \(numberFormatter.string(from: NSNumber(value: cell.c))!)\n")
    dataString += String("_cell.angle_alpha \(numberFormatter.string(from: NSNumber(value: cell.alpha * 180.0/Double.pi))!)\n")
    dataString += String("_cell.angle_beta  \(numberFormatter.string(from: NSNumber(value: cell.beta * 180.0/Double.pi))!)\n")
    dataString += String("_cell.angle_gamma \(numberFormatter.string(from: NSNumber(value: cell.gamma * 180.0/Double.pi))!)\n")
    dataString += String("_cell.Z_PDB       \(numberFormatter.string(from: NSNumber(value: cell.zValue))!)\n") + "\n\n"
    
    let spaceGroup = SKSpacegroup(HallNumber: spaceGroupHallNumber ?? 1)
    dataString += String("_symmetry.space_group_name_Hall '\(spaceGroup.spaceGroupSetting.Hall)'\n")
    dataString += String("_symmetry.pdbx_full_space_group_name_H-M '\(spaceGroup.spaceGroupSetting.HM)'\n")
    dataString += String("_symmetry.Int_Tables_number \(spaceGroup.spaceGroupSetting.number)") + "\n\n"
    
    // write structure atom data
    dataString += String("loop_\n")
    dataString += String("_atom_site.group_PDB\n")
    dataString += String("_atom_site.id\n")
    dataString += String("_atom_site.type_symbol\n")
    if withProteinInfo
    {
      dataString += String("_atom_site.label_comp_id\n")
      dataString += String("_atom_site.label_entity_id\n");
      dataString += String("_atom_site.label_seq_id\n");
      dataString += String("_atom_site.pdbx_PDB_ins_code\n");
    }
    dataString += exportFractional ? String("_atom_site.fract_x\n") : String("_atom_site.Cartn_x\n")
    dataString += exportFractional ? String("_atom_site.fract_y\n") : String("_atom_site.Cartn_y\n")
    dataString += exportFractional ? String("_atom_site.fract_z\n") : String("_atom_site.Cartn_z\n")
    dataString += String("_atom_site.charge\n")
    
    let unitCell: double3x3 = cell.unitCell
    let inverseUnitCell: double3x3 = cell.inverseUnitCell
    for atom in atoms
    {
      let position: SIMD3<Double>
      let chemicalElement = PredefinedElements.sharedInstance.elementSet[atom.elementIdentifier].chemicalSymbol
      
      if atomsAreFractional && !exportFractional
      {
        position = unitCell * atom.position - origin
      }
      else if !atomsAreFractional && exportFractional
      {
        position = inverseUnitCell * atom.position - origin
      }
      else
      {
        position = atom.position - origin
      }
      let name: String
      let residueString: String
      let entityId: String
      let sequenceId: String
      let insertionCode: String
      if withProteinInfo
      {
        name = chemicalElement + String(atom.remotenessIndicator) + String(atom.branchDesignator)
        residueString = atom.residueName.count > 0 ? atom.residueName : "UNK"
        entityId = atom.chainIdentifier == " " ? "?" : String(atom.chainIdentifier)
        sequenceId = String(atom.residueSequenceNumber)
        insertionCode = atom.codeForInsertionOfResidues == " " ? "?" : String(atom.codeForInsertionOfResidues)
      }
      else
      {
        name = atom.displayName.padding(toLength: 8, withPad:  " ", startingAt: 0)
        residueString = ""
        entityId = ""
        sequenceId = ""
        insertionCode = ""
      }
      let chemicalElementString = chemicalElement.padding(toLength: 3, withPad:  " ", startingAt: 0)
      
      if let positionX: String = numberFormatter.string(from: NSNumber(value: position.x)),
         let positionY: String = numberFormatter.string(from: NSNumber(value: position.y)),
         let positionZ: String = numberFormatter.string(from: NSNumber(value: position.z)),
         let charge: String = numberFormatter.string(from: NSNumber(value: atom.charge))
      {
        dataString += String("ATOM \(name) \(chemicalElementString) \(residueString) \(entityId) \(sequenceId) \(insertionCode) \(positionX) \(positionY) \(positionZ) \(charge)\n")
      }
    }
    
    return dataString
  }
}

