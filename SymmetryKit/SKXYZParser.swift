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

extension String {
  func condensingWhitespace() -> String {
    return self.components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
      .joined(separator: " ")
  }
}


public final class SKXYZParser: SKParser, ProgressReporting
{
  weak var windowController: NSWindowController? = nil
  var cellFormulaUnitsZ: Int = 0
  var scanner: Scanner
  let letterSet: CharacterSet
  let nonLetterSet: CharacterSet
  let whiteSpacesAndNewlines: CharacterSet
  let keywordSet: CharacterSet
  let newLineChararterSet: CharacterSet
  
  var a: Double = 20.0
  var b: Double = 20.0
  var c: Double = 20.0
  var alpha: Double = 90.0
  var beta: Double = 90.0
  var gamma: Double = 90.0
  var cell: SKCell = SKCell(a: 20.0, b: 20.0, c: 20.0, alpha: 90.0*Double.pi/180.0, beta: 90.0*Double.pi/180.0, gamma: 90.0*Double.pi/180.0)
  
  var displayName: String = ""
  
  var currentMovie: Int = 0
  var currentFrame: Int = 0
  
  public var progress: Progress
  let totalProgressCount: Int
  var currentProgressCount: Double = 0.0
  let percentageFinishedStep: Double
  
  public init(displayName: String, data: Data, windowController: NSWindowController?) throws
  {
    //self.ProjectTreeNode = ProjectTreeNode
    self.displayName = displayName
    self.windowController = windowController
    
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
    //var modelNumber: Int = 0
    
    while(!scanner.isAtEnd)
    {
      var scannedLine: NSString?
      
      // scan line
      if (scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine))
      {
        if let line = scannedLine
        {
          // update progress
          currentProgressCount += 1.0
          if( Int(currentProgressCount * percentageFinishedStep) > Int((currentProgressCount-1.0) * percentageFinishedStep))
          {
            progress.completedUnitCount += 1
          }
          
          let words: [String] = line.components(separatedBy: CharacterSet.whitespaces)
          if let firstWord: String = words.first,
             let numberOfAtoms: Int = Int(firstWord)
          {
            var periodic = false
            let prefix: String = "Lattice=\""
            // commentline containing the box-sizes
            if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
              let commentString = scannedLine?.trimmingCharacters(in: CharacterSet.whitespaces),
              commentString.hasPrefix(prefix)
            {
              let cellString = String(commentString.dropFirst(prefix.count))
              let separationCharacters = CharacterSet.whitespaces.union(CharacterSet(charactersIn: "\""))
              let words: [String] = cellString.components(separatedBy: separationCharacters).filter({!$0.isEmpty})
              if words.count >= 9,
                let ax = Double(words[0]), let ay = Double(words[1]), let az = Double(words[2]),
                let bx = Double(words[3]), let by = Double(words[4]), let bz = Double(words[5]),
                let cx = Double(words[6]), let cy = Double(words[7]), let cz = Double(words[8])
              {
                periodic = true
                let unitCell: double3x3 = double3x3([SIMD3<Double>(ax,ay,az), SIMD3<Double>(bx,by,bz), SIMD3<Double>(cx,cy,cz)])
                cell = SKCell(unitCell: unitCell)
              
                // update progress
                currentProgressCount += 1.0
                if( Int(currentProgressCount * percentageFinishedStep) > Int((currentProgressCount-1.0) * percentageFinishedStep))
                {
                  progress.completedUnitCount += 1
                }
              }
            }
            
            var atoms: [SKAsymmetricAtom] = []

            for  _ in 0..<numberOfAtoms
            {
              if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
                let words: [String] = (scannedLine as String?)?.condensingWhitespace().components(separatedBy: CharacterSet.whitespaces),
                words.count >= 4
              {
                let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: "new", elementId: 0, uniqueForceFieldName: "C", position: SIMD3<Double>(0.0,0.0,0.0), charge: 0.0, color: NSColor.black, drawRadius: 1.0, bondDistanceCriteria: 1.0, occupancy: 1.0)
                
                
                if let atomicNumber: Int = SKElement.atomData[words[0].capitalizeFirst]?["atomicNumber"] as? Int,
                   let orthogonalXCoordinate: Double = Double(words[1]),
                   let orthogonalYCoordinate: Double = Double(words[2]),
                   let orthogonalZCoordinate: Double = Double(words[3])
                {
                  let chemicalSymbol: String = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
                  atom.elementIdentifier = atomicNumber
                  atom.displayName = chemicalSymbol
                  atom.uniqueForceFieldName = chemicalSymbol
                  atom.position = SIMD3<Double>(x: orthogonalXCoordinate, y: orthogonalYCoordinate, z: orthogonalZCoordinate)
                  atoms.append(atom)
                }
              }
              
              // update progress
              currentProgressCount += 1.0
              if( Int(currentProgressCount * percentageFinishedStep) > Int((currentProgressCount-1.0) * percentageFinishedStep))
              {
                progress.completedUnitCount += 1
              }
            }
            
            addFrameToStructure(atoms: atoms, periodic: periodic)
            currentMovie += 1
            
            
          }
          
        
          
        }
      }
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
        
        if (periodic)
        {
          scene[currentMovie][currentFrame].kind = .molecularCrystal
        }
        else
        {
          scene[currentMovie][currentFrame].kind = .molecule
        }
        
        scene[currentMovie][currentFrame].cell = cell
        scene[currentMovie][currentFrame].displayName = self.displayName
        
        scene[currentMovie][currentFrame].atoms = atoms
      }
    }
    
  }
}
