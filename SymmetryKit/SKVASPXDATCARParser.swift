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
import LogViewKit

public final class SKVASPXDATCARParser: SKParser, ProgressReporting
{
  var cellFormulaUnitsZ: Int = 0
  var scanner: Scanner
  let letterSet: CharacterSet
  let nonLetterSet: CharacterSet
  let whiteSpacesAndNewlines: CharacterSet
  let keywordSet: CharacterSet
  let newLineChararterSet: CharacterSet
  
  var a: SIMD3<Double> = SIMD3<Double>(20.0,0.0,0.0)
  var b: SIMD3<Double> = SIMD3<Double>(0.0,20.0,0.0)
  var c: SIMD3<Double> = SIMD3<Double>(0.0,0.0,20.0)
  
  var fractional: Bool = true
  
  var currentCell: SKCell = SKCell(a: 20.0, b: 20.0, c: 20.0, alpha: 90.0*Double.pi/180.0, beta: 90.0*Double.pi/180.0, gamma: 90.0*Double.pi/180.0)
  var currentElements: [String] = []
  var currentNumberOfAtomsForElement: [Int] = []
  
  var displayName: String = ""
  
  var currentMovie: Int = 0
  var currentFrame: Int = 0
  
  public var progress: Progress
  let totalProgressCount: Int
  var currentProgressCount: Double = 0.0
  let percentageFinishedStep: Double
  
  public init(displayName: String, data: Data) throws
  {
    self.displayName = displayName
    
    guard let string: String = String(data: data, encoding: String.Encoding.utf8) ?? String(data: data, encoding: String.Encoding.ascii) else
    {
      throw SKParserError.failedDecoding
    }
    
    self.scanner = Scanner(string: string)
    self.scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines
    
    let mutableletterSet: CharacterSet = CharacterSet(charactersIn: "\"#$\'_;[]")
    letterSet = mutableletterSet as CharacterSet
    nonLetterSet = letterSet.inverted
    
    whiteSpacesAndNewlines = CharacterSet.whitespacesAndNewlines
    keywordSet = CharacterSet.whitespacesAndNewlines.inverted
    
    newLineChararterSet = CharacterSet.newlines
    
    // report progress in steps of 10% (updating faster makes Progress/updating slow)
    progress = Progress()
    progress.totalUnitCount = 10
    
    // work is defined in terms of the number of lines to parse
    totalProgressCount = string.components(separatedBy: newLineChararterSet).count
    percentageFinishedStep = 10.0/Double(max(totalProgressCount - 1,1))
  }
  
  public override func startParsing() throws
  {
    var scannedLine: String?
        
    // update progress
    currentProgressCount += 1.0
    if( Int(currentProgressCount * percentageFinishedStep) > Int((currentProgressCount-1.0) * percentageFinishedStep))
    {
      progress.completedUnitCount += 1
    }
    
    while let cellInformation: (cell: SKCell, elements: [String], numberOfAtomsForElement: [Int]) = try readHeader()
    {
      var atoms: [SKAsymmetricAtom] = []
      for (index,chemicalElement) in cellInformation.elements.enumerated()
      {
        for _ in 0..<cellInformation.numberOfAtomsForElement[index]
        {
          scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
          if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
              words.count >= 3,
            let orthogonalXCoordinate: Double = Double(words[0]),
            let orthogonalYCoordinate: Double = Double(words[1]),
            let orthogonalZCoordinate: Double = Double(words[2]),
            let atomicNumber: Int = SKElement.atomData[chemicalElement.lowercased().capitalizeFirst]?["atomicNumber"] as? Int
          {
            let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: chemicalElement, elementId: 0, uniqueForceFieldName: chemicalElement, position: SIMD3<Double>(0.0,0.0,0.0), charge: 0.0, color: NSColor.black, drawRadius: 1.0, bondDistanceCriteria: 1.0, occupancy: 1.0)
              
            atom.elementIdentifier = atomicNumber
            atom.displayName = chemicalElement
            atom.uniqueForceFieldName = chemicalElement
            atom.position = SIMD3<Double>(x: orthogonalXCoordinate, y: orthogonalYCoordinate, z: orthogonalZCoordinate)
            atom.fractional = true
              
            if words.count >= 6,
               let firstChacterX: Character = words[3].lowercased().first,
               let firstChacterY: Character = words[4].lowercased().first,
               let firstChacterZ: Character = words[5].lowercased().first
            {
              atom.isFixed = Bool3(firstChacterX == "f",firstChacterY == "f",firstChacterZ == "f")
            }
              
            atoms.append(atom)
          }
        }
      }
      addFrameToStructure(cell: cellInformation.cell, atoms: atoms, periodic: true)
      currentFrame += 1
    }
  }
  
  func readHeader() throws -> (cell: SKCell, elements: [String], numberOfAtomsForElement: [Int])?
  {
    var scannedLine: String?
    
    // skip commentline
    scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
    if(scannedLine == nil)
    {
      throw SKParserError.containsNoData
    }
    
    // scan scaleFactor
    var scaleFactor: Double = 1.0
    scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 1, let scale = Double(words[0])
    {
      scaleFactor = scale
    }
    else
    {
      throw SKParserError.VASPMissingScaleFactor
    }
    
    // read box first vector
    scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 3, let ax = Double(words[0]), let ay = Double(words[1]), let az = Double(words[2])
    {
      a = scaleFactor *  SIMD3<Double>(ax,ay,az)
    }
    else
    {
      throw SKParserError.MissingCellParameters
    }
    
    // read box second vector
    scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 3, let bx = Double(words[0]), let by = Double(words[1]), let bz = Double(words[2])
    {
      b = scaleFactor *  SIMD3<Double>(bx,by,bz)
    }
    else
    {
      throw SKParserError.MissingCellParameters
    }
    
    // read box third vector
    scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 3, let cx = Double(words[0]), let cy = Double(words[1]), let cz = Double(words[2])
    {
      c = scaleFactor *  SIMD3<Double>(cx,cy,cz)
    }
    else
    {
      throw SKParserError.MissingCellParameters
    }
    
    let cell = SKCell(unitCell: double3x3(a, b, c))
    
    scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
    if let elements: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty})
    {
      scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
      if let numberOfAtoms: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty})
      {        
        // check for "Selective dynamics"
        //var selectiveDynamics: Bool = false
        let previousScanLocation = self.scanner.currentIndex
        scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
        if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
           words.count >= 1
        {
          if let firstCharacter = words[0].lowercased().first,
             firstCharacter == "s"  // "Selective dynamics"
          {
            //selectiveDynamics = true
            // nothing needs to be done, line is read
          }
          else
          {
            self.scanner.currentIndex = previousScanLocation
          }
        }
        
        scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
        if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
           words.count >= 1
        {
          if let firstCharacter = words[0].lowercased().first,
             firstCharacter == "c"  // "Cartesian"
          {
            fractional = false
          }
        }
        return (cell, elements, numberOfAtoms.compactMap{Int($0)})
      }
    }
    
    return nil
  }
  
  private func addFrameToStructure(cell: SKCell, atoms: [SKAsymmetricAtom], periodic: Bool)
  {
    if (atoms.count > 0)
    {
      if (currentMovie >= scene.count)
      {
        scene.append([SKStructure]())
      }
      
      if (currentFrame >= scene[currentMovie].count)
      {
        scene[currentMovie].append(SKStructure())
        
        scene[currentMovie][currentFrame].kind = .crystal
        
        scene[currentMovie][currentFrame].cell = cell
        scene[currentMovie][currentFrame].periodic = true
        scene[currentMovie][currentFrame].displayName = self.displayName
        
        scene[currentMovie][currentFrame].atoms = atoms
        scene[currentMovie][currentFrame].spaceGroupHallNumber = 1
      }
    }
  }
  
  func readCellInformation() throws -> (cell: SKCell, elements: [String], numberOfAtomsForElement: [Int])?
  {
    var scannedLine: String?
    
    // skip commentline
    scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
    if (scannedLine == nil)
    {
      throw SKParserError.containsNoData
    }
    
    // scan scaleFactor
    var scaleFactor: Double = 1.0
    scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 1, let scale = Double(words[0])
    {
      scaleFactor = scale
    }
    else
    {
      throw SKParserError.VASPMissingScaleFactor
    }
    
    // read box first vector
    scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 3, let ax = Double(words[0]), let ay = Double(words[1]), let az = Double(words[2])
    {
      a = scaleFactor *  SIMD3<Double>(ax,ay,az)
    }
    else
    {
      throw SKParserError.MissingCellParameters
    }
    
    // read box second vector
    scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 3, let bx = Double(words[0]), let by = Double(words[1]), let bz = Double(words[2])
    {
      b = scaleFactor *  SIMD3<Double>(bx,by,bz)
    }
    else
    {
      throw SKParserError.MissingCellParameters
    }
    
    // read box third vector
    scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
    if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 3, let cx = Double(words[0]), let cy = Double(words[1]), let cz = Double(words[2])
    {
      c = scaleFactor *  SIMD3<Double>(cx,cy,cz)
    }
    else
    {
      throw SKParserError.MissingCellParameters
    }
    debugPrint("a: \(a)")
    debugPrint("b: \(b)")
    debugPrint("c: \(c)")
    let cell = SKCell(unitCell: double3x3(a, b, c))
    
    scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
    if let elements: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty})
    {
      scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
      if let numberOfAtoms: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty})
      {
        scannedLine = scanner.scanUpToCharacters(from: newLineChararterSet)
        let numberOfAtoms = numberOfAtoms.compactMap{Int($0)}
        self.currentElements = elements
        self.currentNumberOfAtomsForElement = numberOfAtoms
        self.currentCell = cell
        return (cell, elements, numberOfAtoms)
      }
    }
    return nil
  }
}
