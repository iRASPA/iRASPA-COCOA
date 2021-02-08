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
import MathKit
import simd

public class SKVASPWriter
{
  // The lazy initialization of the shared instance is thread safe by the definition of let
  public static let shared: SKVASPWriter = SKVASPWriter()
  
  private init()
  {
  }
  
  
  
  public func string(displayName: String, cell: SKCell, atoms: [(type: Int, position: SIMD3<Double>, isFixed: Bool3)], atomsAreFractional: Bool, origin: SIMD3<Double>) -> String
  {
    var dataString: String = ""
    
    let numberFormatter: NumberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    numberFormatter.minimumFractionDigits = 8
    numberFormatter.minimumIntegerDigits = 1
    numberFormatter.formatWidth=12
    numberFormatter.negativePrefix = "-"
    numberFormatter.positivePrefix = " "
    numberFormatter.paddingCharacter = " "
    numberFormatter.usesGroupingSeparator = false
    numberFormatter.groupingSeparator = ""
    numberFormatter.decimalSeparator = "."
    
    dataString += "# " + displayName + "\n"
    dataString += "1.00000000000000\n"
    let ax: String = numberFormatter.string(from: NSNumber(value: cell.unitCell[0][0]))!
    let ay: String = numberFormatter.string(from: NSNumber(value: cell.unitCell[0][1]))!
    let az: String = numberFormatter.string(from: NSNumber(value: cell.unitCell[0][2]))!
    dataString += String("\(ax) \(ay) \(az)\n")
    let bx: String = numberFormatter.string(from: NSNumber(value: cell.unitCell[1][0]))!
    let by: String = numberFormatter.string(from: NSNumber(value: cell.unitCell[1][1]))!
    let bz: String = numberFormatter.string(from: NSNumber(value: cell.unitCell[1][2]))!
    dataString += String("\(bx) \(by) \(bz)\n")
    let cx: String = numberFormatter.string(from: NSNumber(value: cell.unitCell[2][0]))!
    let cy: String = numberFormatter.string(from: NSNumber(value: cell.unitCell[2][1]))!
    let cz: String = numberFormatter.string(from: NSNumber(value: cell.unitCell[2][2]))!
    dataString += String("\(cx) \(cy) \(cz)\n")
    
    let groupAtomData: [Int : [(type: Int, position: SIMD3<Double>, isFixed: Bool3)]] = Dictionary(grouping: atoms, by: {$0.type})
    
    let orderedElementHistogram = atoms.reduce(into: OrderedDictionary<Int,Int>()) { (acc, x) in
      if let count: Int = acc[key: x.type]
      {
        acc.updateValue(count + 1 , forKey: x.type)
      }
      else
      {
        acc.updateValue(1, forKey: x.type)
        
      }
    }
    
    dataString += orderedElementHistogram.keys.map{self.formatString(str: PredefinedElements.sharedInstance.elementSet[$0].chemicalSymbol, length: 6)}.joined(separator: " ") + "\n"
    dataString += orderedElementHistogram.keys.map{self.formatString(str: String(orderedElementHistogram[key: $0] ?? 0), length: 6)}.joined(separator: " ") + "\n"
    dataString += atomsAreFractional ? "Direct\n" : "Cartesian\n"
    
    for element in orderedElementHistogram.keys
    {
      if let groupAtomData = groupAtomData[element]
      {
        for atom in groupAtomData
        {
          let position: SIMD3<Double> = atom.position - origin
          let positionX: String = numberFormatter.string(from: NSNumber(value: position.x))!
          let positionY: String = numberFormatter.string(from: NSNumber(value: position.y))!
          let positionZ: String = numberFormatter.string(from: NSNumber(value: position.z))!
          let isFixedX: Character = atom.isFixed.x ? "F" : "T"
          let isFixedY: Character = atom.isFixed.y ? "F" : "T"
          let isFixedZ: Character = atom.isFixed.z ? "F" : "T"
          dataString += String("\(positionX) \(positionY) \(positionZ) \(isFixedX) \(isFixedY) \(isFixedZ)\n")
        }
      }
    }
    
    return dataString
  }
  
  func formatString(str: String, length: Int, spacer: Character = Character(" "), justifyToTheRight: Bool = true) -> String
  {
    let c = str.count
    let start = str.startIndex
    let end = str.endIndex
    var str = str
    if c > length
    {
      switch justifyToTheRight
      {
      case true:
        let range = str.index(start, offsetBy: c - length)..<end
        return String(str[range])
      case false:
        let range = start..<str.index(end, offsetBy: length - c)
        return String(str[range])
      }
    }
    else
    {
      var extraSpace = String(repeating: spacer, count: length - c)
      if justifyToTheRight
      {
        extraSpace.append(str)
        return extraSpace
      }
      else
      {
        str.append(extraSpace)
        return str
      }
    }
  }
}


