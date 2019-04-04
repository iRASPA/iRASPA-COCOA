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
import MathKit
import LogViewKit

public final class SKXDATCARParser: SKParser, ProgressReporting
{
  weak var windowController: NSWindowController? = nil
  var cellFormulaUnitsZ: Int = 0
  var scanner: Scanner
  let letterSet: CharacterSet
  let nonLetterSet: CharacterSet
  let whiteSpacesAndNewlines: CharacterSet
  let keywordSet: CharacterSet
  let newLineChararterSet: CharacterSet
  
  var a: double3 = double3(20.0,0.0,0.0)
  var b: double3 = double3(0.0,20.0,0.0)
  var c: double3 = double3(0.0,0.0,20.0)
  
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
  
  public init(displayName: String, string: String, windowController: NSWindowController?)
  {
    self.displayName = displayName
    self.windowController = windowController
    
    
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
    var scannedLine: NSString?
        
    // update progress
    currentProgressCount += 1.0
    if( Int(currentProgressCount * percentageFinishedStep) > Int((currentProgressCount-1.0) * percentageFinishedStep))
    {
      progress.completedUnitCount += 1
    }
    
    while let cellInformation: (cell: SKCell, elements: [String], numberOfAtomsForElement: [Int]) = readHeader()
    {
      var atoms: [SKAsymmetricAtom] = []
      for (index,chemicalElement) in cellInformation.elements.enumerated()
      {
        for _ in 0..<cellInformation.numberOfAtomsForElement[index]
        {
          if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
              let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
              words.count >= 3,
            let orthogonalXCoordinate: Double = Double(words[0]),
            let orthogonalYCoordinate: Double = Double(words[1]),
            let orthogonalZCoordinate: Double = Double(words[2]),
            let atomicNumber: Int = SKElement.atomData[chemicalElement.lowercased().capitalizeFirst]?["atomicNumber"] as? Int
          {
            let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: chemicalElement, elementId: 0, uniqueForceFieldName: chemicalElement, position: double3(0.0,0.0,0.0), charge: 0.0, color: NSColor.black, drawRadius: 1.0, bondDistanceCriteria: 1.0)
              
            atom.elementIdentifier = atomicNumber
            atom.displayName = chemicalElement
            atom.uniqueForceFieldName = chemicalElement
            atom.position = double3(x: orthogonalXCoordinate, y: orthogonalYCoordinate, z: orthogonalZCoordinate)
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
  
  func readHeader() -> (cell: SKCell, elements: [String], numberOfAtomsForElement: [Int])?
  {
    var scannedLine: NSString?
    
    let previousScanLocation = self.scanner.scanLocation
    
    // check if 'cell-information' is printed
    if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
       scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
       scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
       scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
       scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
       scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
       scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
       scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
       let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
       let firstCharacter = words[0].lowercased().first,
         firstCharacter == "d"
    {
      self.scanner.scanLocation = previousScanLocation
      return readCellInformation()
    }
    
    self.scanner.scanLocation = previousScanLocation
    if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
       let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
        let firstCharacter = words[0].lowercased().first,
        firstCharacter == "d"
    {
      return (currentCell, currentElements, currentNumberOfAtomsForElement)
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
  
  func readCellInformation() -> (cell: SKCell, elements: [String], numberOfAtomsForElement: [Int])?
  {
    var scannedLine: NSString?
    
    // skip commentline
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VASP file \"\(self.displayName)\": contains no data")
      return nil
    }
    
    // scan scaleFactor
    var scaleFactor: Double = 1.0
    if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
      let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 1, let scale = Double(words[0])
    {
      scaleFactor = scale
    }
    else
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VASP file \"\(self.displayName)\": 2nd line should be the scale factor.")
      return nil
    }
    
    // read box first vector
    if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
      let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 3, let ax = Double(words[0]), let ay = Double(words[1]), let az = Double(words[2])
    {
      a = scaleFactor *  double3(ax,ay,az)
    }
    else
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VASP file \"\(self.displayName)\": 3nd line should be the first vector of the box.")
      return nil
    }
    
    // read box second vector
    if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 3, let bx = Double(words[0]), let by = Double(words[1]), let bz = Double(words[2])
      {
        b = scaleFactor *  double3(bx,by,bz)
      }
    }
    else
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VASP file \"\(self.displayName)\": 4nd line should be the third vector of the box.")
      return nil
    }
    
    // read box third vector
    if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
      let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 3, let cx = Double(words[0]), let cy = Double(words[1]), let cz = Double(words[2])
    {
      c = scaleFactor *  double3(cx,cy,cz)
    }
    else
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VASP file \"\(self.displayName)\": 5nd line should be the third vector of the box.")
      return nil
    }
    
    let cell = SKCell(unitCell: double3x3(a, b, c))
    
    if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
    let elements: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
    scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
    let numberOfAtoms: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
    scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      let numberOfAtoms = numberOfAtoms.compactMap{Int($0)}
      self.currentElements = elements
      self.currentNumberOfAtomsForElement = numberOfAtoms
      self.currentCell = cell
      return (cell, elements, numberOfAtoms)
    }
    return nil
  }
}
