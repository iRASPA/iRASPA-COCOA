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

extension NSString {
  var condensedWhitespace: NSString {
    let components = self.components(separatedBy: CharacterSet.whitespacesAndNewlines)
    return components.filter { !$0.isEmpty }.joined(separator: " ") as NSString
  }
}


public struct SKVASPReader
{
  var scanner: Scanner
  let letterSet: CharacterSet
  let nonLetterSet: CharacterSet
  let whiteSpacesAndNewlines: CharacterSet
  let keywordSet: CharacterSet
  let newLineChararterSet: CharacterSet
  
  var firstAxis: SIMD3<Double>? = nil
  var secondAxis: SIMD3<Double>? = nil
  var thirdAxis: SIMD3<Double>? = nil
  
  public var atoms: [(fractionalPosition: SIMD3<Double>, type: Int)] = []
  public var unitCell: double3x3?
  {
    if let firstAxis = firstAxis,
       let secondAxis = secondAxis,
       let thirdAxis = thirdAxis
    {
      return double3x3([firstAxis, secondAxis, thirdAxis])
    }
    return nil
  }
  

  
  init(URL: URL)
  {
    let mutableletterSet: CharacterSet = CharacterSet(charactersIn: "\"#$\'_;[]")
    letterSet = mutableletterSet as CharacterSet
    nonLetterSet = letterSet.inverted
    
    whiteSpacesAndNewlines = CharacterSet.whitespacesAndNewlines
    keywordSet = CharacterSet.whitespacesAndNewlines.inverted
    
    newLineChararterSet = CharacterSet.newlines
    
    let stringData: String = try! String(contentsOf: URL)
    var types: [String]? = []
    
    self.scanner = Scanner(string: stringData)
    self.scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines
    
    var lineNumber: Int = 0
    while(!scanner.isAtEnd)
    {      
      // scan line
      if let scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)?.condensedWhitespace
      {
        lineNumber = lineNumber + 1
        
        switch(lineNumber)
        {
        case 1:
          continue
        case 2:
          continue
        case 3:  // first axis
          let splittedString: [String] = scannedLine.components(separatedBy: " ")
          if splittedString.count >= 3
          {
            if let firstNumber: Double = Double(splittedString[0]),
               let secondNumber: Double = Double(splittedString[1]),
               let thirdNumber: Double = Double(splittedString[2])
            {
              firstAxis = SIMD3<Double>(firstNumber,secondNumber,thirdNumber)
            }
          }
        case 4:  // second axis
          let splittedString: [String] = scannedLine.components(separatedBy: CharacterSet.whitespaces)
          if splittedString.count >= 3
          {
            if let firstNumber: Double = Double(splittedString[0]),
              let secondNumber: Double = Double(splittedString[1]),
              let thirdNumber: Double = Double(splittedString[2])
            {
              secondAxis = SIMD3<Double>(firstNumber,secondNumber,thirdNumber)
            }
          }
        case 5:  // third axis
          let splittedString: [String] = scannedLine.components(separatedBy: CharacterSet.whitespaces)
          if splittedString.count >= 3
          {
            if let firstNumber: Double = Double(splittedString[0]),
              let secondNumber: Double = Double(splittedString[1]),
              let thirdNumber: Double = Double(splittedString[2])
            {
              thirdAxis = SIMD3<Double>(firstNumber,secondNumber,thirdNumber)
            }
          }
        case 6:
          types = scannedLine.components(separatedBy: CharacterSet.whitespaces)
        case 7:
          continue
        default: // read in positions
          let splittedString: [String] = scannedLine.components(separatedBy: CharacterSet.whitespaces)
          if splittedString.count >= 3
          {
            if let firstNumber: Double = Double(splittedString[0]),
              let secondNumber: Double = Double(splittedString[1]),
              let thirdNumber: Double = Double(splittedString[2])
            {
              atoms.append((SIMD3<Double>(firstNumber,secondNumber,thirdNumber),1))
            }
          }
        }
      }
    }
    
    // set types based on VASP amount of atoms for each type
    // 8,4,24 means the first 8 atoms have type 1, the next 4 type 2, and the last 24 have type 3.
    if let types = types
    {
      var index: Int = 1
      var previousAmount: Int = 0
      for type in types
      {
        if let amount: Int = Int(type)
        {
          for i in previousAmount..<(previousAmount+amount)
          {
            atoms[i].type = index
          }
          previousAmount += amount
          index += 1
        }
      }
    }
  }
}
