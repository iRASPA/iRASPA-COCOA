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

public class SKCIFWriter
{
  // The lazy initialization of the shared instance is thread safe by the definition of let
  public static let shared: SKCIFWriter = SKCIFWriter()
  
  private init()
  {
  }
  
  public func string(displayName: String, spaceGroupHallNumber: Int?, cell: SKCell, atoms: [SKAsymmetricAtom], exportFractional: Bool, origin: double3) -> String
  {
    var dataString: String = ""
    
    let numberFormatter: NumberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    numberFormatter.minimumFractionDigits = 8
    numberFormatter.minimumIntegerDigits = 1
    numberFormatter.negativePrefix = "-"
    numberFormatter.positivePrefix = " "
    numberFormatter.usesGroupingSeparator = false
    numberFormatter.groupingSeparator = ""
    numberFormatter.decimalSeparator = "."
    
    // write local header
    dataString += String("data_\(displayName)\n") + "\n"
    
    // write spacegroup data
    dataString += String("_cell_length_a \(numberFormatter.string(from: NSNumber(value: cell.a))!)\n")
    dataString += String("_cell_length_b \(numberFormatter.string(from: NSNumber(value: cell.b))!)\n")
    dataString += String("_cell_length_c \(numberFormatter.string(from: NSNumber(value: cell.c))!)\n")
    dataString += String("_cell_angle_alpha \(numberFormatter.string(from: NSNumber(value: cell.alpha * 180.0/Double.pi))!)\n")
    dataString += String("_cell_angle_beta \(numberFormatter.string(from: NSNumber(value: cell.beta * 180.0/Double.pi))!)\n")
    dataString += String("_cell_angle_gamma \(numberFormatter.string(from: NSNumber(value: cell.gamma * 180.0/Double.pi))!)\n") + "\n\n"
    
    let spaceGroup = SKSpacegroup(HallNumber: spaceGroupHallNumber ?? 1)
    dataString += String("_symmetry_space_group_name_Hall '\(spaceGroup.spaceGroupSetting.Hall)'\n")
    dataString += String("_symmetry_space_group_name_H-M  '\(spaceGroup.spaceGroupSetting.HM)'\n")
    dataString += String("_symmetry_Int_Tables_number     \(spaceGroup.spaceGroupSetting.number)") + "\n\n"
    
    // write structure atom data
    dataString += String("loop_\n")
    dataString += String("_atom_site_label\n")
    dataString += String("_atom_site_type_symbol\n")
    
    if exportFractional
    {
      dataString += String("_atom_site_fract_x\n")
      dataString += String("_atom_site_fract_y\n")
      dataString += String("_atom_site_fract_z\n")
    }
    else
    {
      dataString += String("_atom_site_Cartn_x\n")
      dataString += String("_atom_site_Cartn_y\n")
      dataString += String("_atom_site_Cartn_z\n")
    }
    dataString += String("_atom_site_charge\n")
    
    for atom in atoms
    {
      let position: double3 = atom.position - origin
      
      let name = atom.displayName.padding(toLength: 8, withPad:  " ", startingAt: 0)
      let chemicalElement = PredefinedElements.sharedInstance.elementSet[atom.elementIdentifier].chemicalSymbol.padding(toLength: 3, withPad:  " ", startingAt: 0)
      
      let positionX: String = numberFormatter.string(from: NSNumber(value: position.x))!
      let positionY: String = numberFormatter.string(from: NSNumber(value: position.y))!
      let positionZ: String = numberFormatter.string(from: NSNumber(value: position.z))!
      let charge: String = numberFormatter.string(from: NSNumber(value: atom.charge))!
      dataString += String("\(name) \(chemicalElement) \(positionX) \(positionY) \(positionZ) \(charge)\n")
    }
    
    return dataString
  }
}
