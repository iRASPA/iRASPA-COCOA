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

public final class SKGaussianCubeParser: SKParser, ProgressReporting
{
  var cellFormulaUnitsZ: Int = 0
  var scanner: Scanner
  let letterSet: CharacterSet
  let nonLetterSet: CharacterSet
  let whiteSpacesAndNewlines: CharacterSet
  let keywordSet: CharacterSet
  let newLineChararterSet: CharacterSet
  
  var currentMovie: Int = 0
  var currentFrame: Int = 0
  
  var numberOfAtoms: Int = 0
  var a: SIMD3<Double> = SIMD3<Double>(20.0,0.0,0.0)
  var b: SIMD3<Double> = SIMD3<Double>(0.0,20.0,0.0)
  var c: SIMD3<Double> = SIMD3<Double>(0.0,0.0,20.0)
  var cell: SKCell = SKCell(a: 20.0, b: 20.0, c: 20.0, alpha: 90.0*Double.pi/180.0, beta: 90.0*Double.pi/180.0, gamma: 90.0*Double.pi/180.0)
  
  var displayName: String = ""
  var dimensions: SIMD3<Int32> = SIMD3<Int32>(0,0,0)
  var aspectRatio: SIMD3<Double> = SIMD3<Double>(1.0,1.0,1.0)
  var origin: SIMD3<Double> = SIMD3<Double>(0.0,0.0,0.0)
  var numberOfValues: Int = 0
  var gridData: [Float] = []
  var range: (Double, Double) = (0.0,0.0)
  var average: Double = 0.0
  var variance: Double = 0.0
  
  var isBinaryData: Bool = false
  var data: Data
  
  public var progress: Progress
  let totalProgressCount: Int
  var currentProgressCount: Double = 0.0
  let percentageFinishedStep: Double
  
  public init(displayName: String, data: Data) throws
  {
    self.displayName = displayName
    
    self.data = data
    
    guard let string: String = String(data: data, encoding: .macOSRoman) else
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
    totalProgressCount = scanner.string.components(separatedBy: newLineChararterSet).count
    percentageFinishedStep = 10.0/Double(max(totalProgressCount - 1,1))
    
  }
  
  public override func startParsing() throws
  {
    var scannedLine: NSString? = ""
   
    // skip commentlines
    scanner.charactersToBeSkipped = nil

    scanner.scanUpTo("\n", into: &scannedLine)
    scanner.scanLocation += 1
    scanner.scanUpTo("\n", into: &scannedLine)
    scanner.scanLocation += 1
    
    scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines
    
    // read number of atoms and origin
    if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
       let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
       words.count >= 4, let natoms = Int(words[0]), let ox = Double(words[1]), let oy = Double(words[2]), let oz = Double(words[3])
    {
      numberOfAtoms = natoms
      self.origin = SIMD3<Double>(ox,oy,oz)
      
      if numberOfAtoms.signum() == -1
      {
        //throw SKParserError.MolecularOrbitalOutputNotSupported
      }
    }
    else
    {
      throw SKParserError.MissingCellParameters
    }
    
    var conversionFactor: SIMD3<Double> = SIMD3<Double>(1.0,1.0,1.0)
    
    // read box first vector
    if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
       let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
       words.count >= 4, let dx = Int32(words[0]), let ax = Double(words[1]), let ay = Double(words[2]), let az = Double(words[3])
    {
      dimensions.x = abs(dx)
      conversionFactor.x = dx.signum() == -1 ? 1.0 : BohrToAngstrom
      a = conversionFactor.x * Double(dx) * SIMD3<Double>(ax,ay,az)
    }
    else
    {
      throw SKParserError.MissingCellParameters
    }
    
    // read box second vector
    if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
       let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
       words.count >= 4, let dy = Int32(words[0]), let bx = Double(words[1]), let by = Double(words[2]), let bz = Double(words[3])
    {
      dimensions.y = abs(dy)
      conversionFactor.y = dy.signum() == -1 ? 1.0 : BohrToAngstrom
      b = conversionFactor.y * Double(dy) * SIMD3<Double>(bx,by,bz)
    }
    else
    {
      throw SKParserError.MissingCellParameters
    }
    
    // read box third vector
    if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
       let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
       words.count >= 4, let dz = Int32(words[0]), let cx = Double(words[1]), let cy = Double(words[2]), let cz = Double(words[3])
    {
      dimensions.z = abs(dz)
      conversionFactor.z = dz.signum() == -1 ? 1.0 : BohrToAngstrom
      c = conversionFactor.z * Double(dz) * SIMD3<Double>(cx,cy,cz)
    }
    else
    {
      throw SKParserError.MissingCellParameters
    }
    
    cell = SKCell(unitCell: double3x3(a, b, c))
    
    var atoms: [SKAsymmetricAtom] = []
    atoms.reserveCapacity(abs(numberOfAtoms))
    
    for _ in 0..<abs(numberOfAtoms)
    {
      if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
         let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
         words.count >= 5, let atomicNumber = Int(words[0]), let charge = Double(words[1]), let x = Double(words[2]), let y = Double(words[3]), let z = Double(words[4])
      {
        let pos: SIMD3<Double> = conversionFactor * (SIMD3<Double>(x,y,z) - origin)
        let chemicalElement: String = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
        let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: chemicalElement, elementId: atomicNumber, uniqueForceFieldName: chemicalElement, position: pos, charge: charge, color: NSColor.black, drawRadius: 1.0, bondDistanceCriteria: 1.0, occupancy: 1.0)
        atoms.append(atom)
      }
      else
      {
        debugPrint("wrong number of data points")
        break
      }
    }
    
    if(numberOfAtoms<0)
    {
      // read number of orbitals
      if scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine),
         let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
         words.count >= 1, let numberOfMolecularOrbitals = Int(words[0])
      {
      }
    }
    
   
    
    var max: Float = Float.leastNormalMagnitude
    var min: Float = Float.greatestFiniteMagnitude
    var sum: Float = 0.0
    var sumSquared: Float = 0.0
    let numberOfValues: Int = Int(dimensions.x * dimensions.y * dimensions.z)
    gridData = Array<Float>(repeating: 0.0, count: numberOfValues)
    for x: Int32 in 0..<dimensions.x  // X is the outer loop
    {
      for y: Int32 in 0..<dimensions.y  // Y is the middle loop
      {
        for z: Int32 in 0..<dimensions.z  // Z is the inner loop
        {
          if scanner.scanUpToCharacters(from: whiteSpacesAndNewlines, into: &scannedLine),
              let words: [String] = scannedLine?.components(separatedBy: CharacterSet.whitespaces).filter({!$0.isEmpty}),
              words.count >= 1
          {
            if let dataPoint: Float = Float(words[0])
            {
              let index: Int = Int(x+dimensions.x*y+z*dimensions.x*dimensions.y)
              gridData[index] = dataPoint
              
              sum += dataPoint
              sumSquared += dataPoint * dataPoint
              
              if(dataPoint > max)
              {
                max = dataPoint
              }
              if(dataPoint < min)
              {
                min = dataPoint
              }
            }
          }
        }
      }
    }
    self.average = Double(sum) / Double(dimensions.x * dimensions.y * dimensions.z)
    self.variance = Double(sumSquared) / Double(dimensions.x * dimensions.y * dimensions.z - 1)
    self.range = (Double(min), Double(max))
    
    addFrameToStructure(atoms: atoms, periodic: true)
    currentFrame += 1
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
  
        scene[currentMovie][currentFrame].kind = .GaussianCubeVolume
  
        scene[currentMovie][currentFrame].cell = cell
        scene[currentMovie][currentFrame].periodic = true
        scene[currentMovie][currentFrame].displayName = self.displayName
  
        scene[currentMovie][currentFrame].atoms = atoms
        scene[currentMovie][currentFrame].spaceGroupHallNumber = 1
  
        scene[currentMovie][currentFrame].dimensions = self.dimensions
        scene[currentMovie][currentFrame].range = self.range
        scene[currentMovie][currentFrame].average = self.average
        scene[currentMovie][currentFrame].variance = self.variance
        scene[currentMovie][currentFrame].gridData = self.gridData.withUnsafeBufferPointer({Data(buffer: $0)})
        scene[currentMovie][currentFrame].dataType = .Float
      }
    }
  }
}
