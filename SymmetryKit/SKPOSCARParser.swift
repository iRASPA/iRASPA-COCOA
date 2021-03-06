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
import simd
import MathKit
import LogViewKit

public final class SKPOSCARParser: SKParser, ProgressReporting
{
  weak var windowController: NSWindowController? = nil
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
  var cell: SKCell = SKCell(a: 20.0, b: 20.0, c: 20.0, alpha: 90.0*Double.pi/180.0, beta: 90.0*Double.pi/180.0, gamma: 90.0*Double.pi/180.0)
  
  var displayName: String = ""
  
  var currentMovie: Int = 0
  var currentFrame: Int = 0
  
  public var progress: Progress
  let totalProgressCount: Int
  var currentProgressCount: Double = 0.0
  let percentageFinishedStep: Double
  
  public init(displayName: String, string: String, windowController: NSWindowController?)
  {
    //self.ProjectTreeNode = ProjectTreeNode
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
    let periodic = true
    
    var scannedLine: NSString?
    
    // scan line
    
    // update progress
    currentProgressCount += 1.0
    if( Int(currentProgressCount * percentageFinishedStep) > Int((currentProgressCount-1.0) * percentageFinishedStep))
    {
      progress.completedUnitCount += 1
    }
    
    // skip commentline
    if !scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VASP file \"\(self.displayName)\": contains no data")
      return
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
      return
    }
    
    // read box first vector
    if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
      let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 3, let ax = Double(words[0]), let ay = Double(words[1]), let az = Double(words[2])
    {
      a = scaleFactor *  SIMD3<Double>(ax,ay,az)
    }
    else
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VASP file \"\(self.displayName)\": 3nd line should be the first vector of the box.")
      return
    }
    
    // read box second vector
    if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine)
    {
      if let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 3, let bx = Double(words[0]), let by = Double(words[1]), let bz = Double(words[2])
      {
        b = scaleFactor *  SIMD3<Double>(bx,by,bz)
      }
    }
    else
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VASP file \"\(self.displayName)\": 4nd line should be the third vector of the box.")
      return
    }
    
    // read box third vector
    if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
      let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}), words.count >= 3, let cx = Double(words[0]), let cy = Double(words[1]), let cz = Double(words[2])
    {
      c = scaleFactor *  SIMD3<Double>(cx,cy,cz)
    }
    else
    {
      LogQueue.shared.error(destination: self.windowController, message: "Error reading VASP file \"\(self.displayName)\": 5nd line should be the third vector of the box.")
      return
    }
    
    cell = SKCell(unitCell: double3x3(a, b, c))
    var atoms: [SKAsymmetricAtom] = []
        
    if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
      let elements: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
      scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
      let numberOfAtoms: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty})
    {
      let count = min(elements.count,numberOfAtoms.count)
      
      // check for "Selective dynamics"
      //var selectiveDynamics: Bool = false
      let previousScanLocation = self.scanner.scanLocation
      if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
        let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
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
          self.scanner.scanLocation = previousScanLocation
        }
      }
      
      var fractional: Bool = true
      if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
        let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
        words.count >= 1
      {
        if let firstCharacter = words[0].lowercased().first,
          firstCharacter == "c"  // "Cartesian"
        {
          fractional = false
        }
      }
      
      for element in 0..<count
      {
        if let atomicNumber: Int = SKElement.atomData[elements[element].capitalizeFirst]?["atomicNumber"] as? Int,
          let numberOfAtomsForElement: Int =  Int(numberOfAtoms[element])
        {
          for _ in 0..<numberOfAtomsForElement
          {
            if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
              let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
              words.count >= 3,
              let orthogonalXCoordinate: Double = Double(words[0]),
              let orthogonalYCoordinate: Double = Double(words[1]),
              let orthogonalZCoordinate: Double = Double(words[2])
            {
              let chemicalElement: String = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
              let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: "new", elementId: 0, uniqueForceFieldName: chemicalElement, position: SIMD3<Double>(0.0,0.0,0.0), charge: 0.0, color: NSColor.black, drawRadius: 1.0, bondDistanceCriteria: 1.0)
              
              atom.elementIdentifier = atomicNumber
              atom.displayName = chemicalElement
              atom.uniqueForceFieldName = chemicalElement
              atom.position = SIMD3<Double>(x: orthogonalXCoordinate, y: orthogonalYCoordinate, z: orthogonalZCoordinate)
              atom.fractional = fractional
              
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
      }
      
      addFrameToStructure(atoms: atoms, periodic: periodic)
      currentFrame += 1
      
    }
  }
  
  private func addFrameToStructure(atoms: [SKAsymmetricAtom], periodic: Bool)
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
}

