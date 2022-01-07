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

public class SKXYZWriter
{
  // The lazy initialization of the shared instance is thread safe by the definition of let
  public static let shared: SKXYZWriter = SKXYZWriter()
  
  private init()
  {
  }
  
 
  
  public func string(displayName: String, commentString: String, atoms: [(elementIdentifier: Int, position: SIMD3<Double>)], origin: SIMD3<Double>) -> String
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
    
    dataString += String(atoms.count) + "\n"
    dataString += commentString + "\n"
    for atom in atoms
    {
      let position: SIMD3<Double> = atom.position - origin
      let chemicalElement = PredefinedElements.sharedInstance.elementSet[atom.elementIdentifier].chemicalSymbol.padding(toLength: 3, withPad:  " ", startingAt: 0)
      
      let positionX: String = numberFormatter.string(from: NSNumber(value: position.x))!
      let positionY: String = numberFormatter.string(from: NSNumber(value: position.y))!
      let positionZ: String = numberFormatter.string(from: NSNumber(value: position.z))!
      
      dataString += String("\(chemicalElement) \(positionX) \(positionY) \(positionZ)\n")
    }
    
    return dataString
  }
}

