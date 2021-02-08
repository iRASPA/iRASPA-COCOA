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

import Cocoa
import simd


// By tradition, the ATOM keyword is used to identify proteins or nucleic acid atoms, and keyword HETATM is used to identify atoms in small molecules
// Protein and nucleic acid chains are specified by the TER keyword, as well as a one-letter designation in the coordinate records. The chains are included one after another in the file, separated by a TER record to indicate that the chains are not physically connected to each other. Most molecular graphics programs look for this TER record so that they don't draw a bond to connect different chains.
// PDB format files use the MODEL keyword to indicate multiple molecules in a single file. This was initially created to archive coordinate sets that include several different models of the same structure, like the structural ensembles obtained in NMR analysis. When you view these files, you will see dozens of similar molecules all superimposed. The MODEL keyword is now also used in biological assembly files to separate the many symmetrical copies of the molecule that are generated from the asymmetric unit
// http://pdb101.rcsb.org/learn/guide-to-understanding-pdb-data/biological-assemblies

// A Movie consists of a list of frames
// MODEL    1
// ... -> frame
// ENDMDL

public final class SKPDBParser: SKParser, ProgressReporting
{
  var displayName: String
  var scanner: Scanner
  let letterSet: CharacterSet
  let nonLetterSet: CharacterSet
  let whiteSpacesAndNewlines: CharacterSet
  let keywordSet: CharacterSet
  let newLineChararterSet: CharacterSet
  
  var periodic: Bool = false
  var onlyAsymmetricUnit: Bool = false
  var asMolecule: Bool = false
  var spaceGroup: SKSpacegroup = SKSpacegroup()
  var scaleMatrixDefined: [Bool] = [false, false, false]
  var scaleMatrix: double3x3 = double3x3(1.0)
  var translation: SIMD3<Double> = SIMD3<Double>(0.0,0.0,0.0)
  var a: Double = 20.0
  var b: Double = 20.0
  var c: Double = 20.0
  var alpha: Double = 90.0
  var beta: Double = 90.0
  var gamma: Double = 90.0
  
  var cell: SKCell = SKCell(a: 20.0, b: 20.0, c: 20.0, alpha: 90.0*Double.pi/180.0, beta: 90.0*Double.pi/180.0, gamma: 90.0*Double.pi/180.0)
  
  var atoms: [SKAsymmetricAtom] = []
  
  var currentMovie: Int = 0
  var currentFrame: Int = 0
  //var currentAtom: Int = 0
  
  var numberOfAminoAcidAtoms: Int = 0
  var numberOfNucleicAcidAtoms: Int = 0
  var ligandAtoms: Int = 0
  var numberOfSolventAtoms: Int = 0
  var numberOfAtoms: Int = 0
  
  public var progress: Progress
  let totalProgressCount: Int
  var currentProgressCount: Double = 0.0
  let percentageFinishedStep: Double
  

  
  private func addFrameToStructure()
  {
    if (atoms.count >= 0)
    {
      if (currentMovie >= scene.count)
      {
        scene.append([SKStructure]())
      }
      
      if (currentFrame >= scene[currentMovie].count)
      {
        let structure: SKStructure = SKStructure()
        scene[currentMovie].append(structure)
        
        if (Double(numberOfAminoAcidAtoms)/(Double)(numberOfNucleicAcidAtoms) > 0.5)
        {
          if (periodic)
          {
            scene[currentMovie][currentFrame].kind = .proteinCrystal
            scene[currentMovie][currentFrame].drawUnitCell = !onlyAsymmetricUnit
          }
          else
          {
            scene[currentMovie][currentFrame].kind = .protein
            scene[currentMovie][currentFrame].drawUnitCell = false
          }
        }
        else
        {
          // set to Solvent if almost all atoms are "HETATM"
          if (Double(numberOfSolventAtoms)/(Double)(numberOfAtoms) > 0.9)
          {
            if (periodic)
            {
              scene[currentMovie][currentFrame].kind = .molecularCrystal
              scene[currentMovie][currentFrame].drawUnitCell = !onlyAsymmetricUnit
            }
            else
            {
              scene[currentMovie][currentFrame].kind = .molecule
              scene[currentMovie][currentFrame].drawUnitCell = false
            }
          }
          else
          {
            if (periodic)
            {
              scene[currentMovie][currentFrame].kind = .molecularCrystal
            }
            else
            {
              scene[currentMovie][currentFrame].kind = .molecule
            }
          }
        }
        
        scene[currentMovie][currentFrame].cell = cell
        scene[currentMovie][currentFrame].spaceGroupHallNumber = onlyAsymmetricUnit ? 1 : self.spaceGroup.spaceGroupSetting.number
        scene[currentMovie][currentFrame].displayName = self.displayName
        scene[currentMovie][currentFrame].atoms = atoms
        scene[currentMovie][currentFrame].unknownAtoms = unknownAtoms
        
        atoms = []
        numberOfAminoAcidAtoms = 0
        numberOfNucleicAcidAtoms = 0
        numberOfSolventAtoms = 0
        numberOfAtoms = 0
      }
    }
    
  }
  
  public init(displayName: String, string: String, windowController: NSWindowController?, onlyAsymmetricUnit: Bool, asMolecule: Bool)
  {
    self.displayName = displayName
    self.onlyAsymmetricUnit = onlyAsymmetricUnit
    self.asMolecule = asMolecule
    self.scanner = Scanner(string: string)
    self.scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines
    
    let mutableletterSet: NSMutableCharacterSet = NSMutableCharacterSet.letter()
    mutableletterSet.addCharacters(in: "\"#$\'_;[]")
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
    var lineNumber: Int = 0
    var modelNumber: Int = 0
    
    
    while(!scanner.isAtEnd)
    {
      var scannedLine: NSString?
      
      // scan line
      if (scanner.scanUpToCharacters(from: newLineChararterSet, into: &scannedLine))
      {
        if let scannedLine: NSString = scannedLine
        {
          lineNumber += 1
          
          
          let length = scannedLine.length
          guard (length >= 3) else
          {
            // only keyword present
            break
          }
          let shortKeyword: String = scannedLine.substring(with: NSRange(location: 0, length: 3))
         
          
          switch(shortKeyword)
          {
          // also captures "ENDMDL"
          case "END":
            addFrameToStructure()
            currentFrame += 1
            continue
          case "TER":
            addFrameToStructure()
            currentMovie += 1
            continue
          default:
            break
          }
           
          
          guard (length >= 6) else
          {
            // only keyword present
            break
          }
          let keyword: String = scannedLine.substring(with: NSRange(location: 0, length: 6))
          
          
          
          switch(keyword)
          {
          case "HEADER":
            break
          case "AUTHOR":
            break
          case "REVDAT":
            break
          case "JRNL  ":
            break
          case "REMARK":
            break
          case "MODEL ":
            // reset the current frame-list and current atom to zero
            currentMovie = 0
            
            guard (length > 10) else
            {
              let modelString: String = scannedLine.substring(from: 6)
              if let integerValue: Int = Int(modelString)
              {
                atoms = []
                currentFrame = max(0, integerValue-1)
                currentFrame = modelNumber
                modelNumber += 1
              }
              break
            }
            guard (length > 14) else
            {
              let modelString: String = scannedLine.substring(from: 10)
              if let integerValue: Int = Int(modelString)
              {
                currentFrame = max(0, integerValue-1)
              }
              break
            }
            let modelString: String = scannedLine.substring(with: NSRange(location: 10, length: 4))
            if let integerValue: Int = Int(modelString)
            {
              currentFrame = max(0, integerValue-1)
            }
            
          case "SCALE1":
            guard (length > 20) else
            {
              break
            }
            let scaleAXString: String = scannedLine.substring(with: NSRange(location: 10, length: 10)).trimmingCharacters(in: .whitespaces)
            if let doubleValue = Double(scaleAXString)
            {
              scaleMatrix[0][0] = doubleValue
            }
            
            guard (length > 30) else
            {
              break
            }
            let scaleAYString: String = scannedLine.substring(with: NSRange(location: 20, length: 10)).trimmingCharacters(in: .whitespaces)
            if let doubleValue = Double(scaleAYString)
            {
              scaleMatrix[1][0] = doubleValue
            }
            guard (length > 40) else
            {
              break
            }
            let scaleAZString: String = scannedLine.substring(with: NSRange(location: 30, length: 10)).trimmingCharacters(in: .whitespaces)
            if let doubleValue = Double(scaleAZString)
            {
              scaleMatrix[2][0] = doubleValue
              scaleMatrixDefined[0] = true
            }
            guard (length > 55) else
            {
              break
            }
            let scaleATString: String = scannedLine.substring(with: NSRange(location: 45, length: 10)).trimmingCharacters(in: .whitespaces)
            if let doubleValue = Double(scaleATString)
            {
              translation[0] = doubleValue
            }
            break
          case "SCALE2":
            guard (length > 20) else
            {
              break
            }
            let scaleAXString: String = scannedLine.substring(with: NSRange(location: 10, length: 10)).trimmingCharacters(in: .whitespaces)
            if let doubleValue = Double(scaleAXString)
            {
              scaleMatrix[0][1] = doubleValue
            }
            guard (length > 30) else
            {
              break
            }
            let scaleAYString: String = scannedLine.substring(with: NSRange(location: 20, length: 10)).trimmingCharacters(in: .whitespaces)
            if let doubleValue = Double(scaleAYString)
            {
              scaleMatrix[1][1] = doubleValue
            }
            guard (length > 40) else
            {
              break
            }
            let scaleAZString: String = scannedLine.substring(with: NSRange(location: 30, length: 10)).trimmingCharacters(in: .whitespaces)
            if let doubleValue = Double(scaleAZString)
            {
              scaleMatrix[2][1] = doubleValue
              scaleMatrixDefined[1] = true
            }
            guard (length > 55) else
            {
              break
            }
            let scaleATString: String = scannedLine.substring(with: NSRange(location: 45, length: 10)).trimmingCharacters(in: .whitespaces)
            if let doubleValue = Double(scaleATString)
            {
              translation[1] = doubleValue
            }
          case "SCALE3":
            guard (length > 20) else
            {
              break
            }
            let scaleAXString: String = scannedLine.substring(with: NSRange(location: 10, length: 10)).trimmingCharacters(in: .whitespaces)
            if let doubleValue = Double(scaleAXString)
            {
              scaleMatrix[0][2] = doubleValue
            }
            guard (length > 30) else
            {
              break
            }
            let scaleAYString: String = scannedLine.substring(with: NSRange(location: 20, length: 10)).trimmingCharacters(in: .whitespaces)
            if let doubleValue = Double(scaleAYString)
            {
              scaleMatrix[1][2] = doubleValue
            }
            guard (length > 40) else
            {
              break
            }
            let scaleAZString: String = scannedLine.substring(with: NSRange(location: 30, length: 10)).trimmingCharacters(in: .whitespaces)
            if let doubleValue = Double(scaleAZString)
            {
              scaleMatrix[2][2] = doubleValue
              scaleMatrixDefined[2] = true
            }
            guard (length > 55) else
            {
              break
            }
            let scaleATString: String = scannedLine.substring(with: NSRange(location: 45, length: 10)).trimmingCharacters(in: .whitespaces)
            if let doubleValue = Double(scaleATString)
            {
              translation[2] = doubleValue
            }
            
          case "CRYST1":
            let length = scannedLine.length
            
            guard (length >= 16) else
            {
              let cellAString: String = scannedLine.substring(from: 6).trimmingCharacters(in: .whitespaces)
              if let doubleValue: Double = Double(cellAString)
              {
                a = doubleValue
              }
              break
            }
            let cellAString: String = scannedLine.substring(with: NSRange(location: 6, length: 9)).trimmingCharacters(in: .whitespaces)
            if let doubleValue: Double = Double(cellAString)
            {
              a = doubleValue
            }
            guard (length >= 25) else
            {
              let cellBString: String = scannedLine.substring(from: 15).trimmingCharacters(in: .whitespaces)
              if let doubleValue: Double = Double(cellBString)
              {
                b = doubleValue
              }
              break
            }
            let cellBString: String = scannedLine.substring(with: NSRange(location: 15, length: 9)).trimmingCharacters(in: .whitespaces)
            if let doubleValue: Double = Double(cellBString)
            {
              b = doubleValue
            }
            guard (length >= 34) else
            {
              let cellCString: String = scannedLine.substring(from: 24).trimmingCharacters(in: .whitespaces)
              if let doubleValue: Double = Double(cellCString)
              {
                c = doubleValue
              }
              break
            }
            let cellCString: String = scannedLine.substring(with: NSRange(location: 24, length: 9)).trimmingCharacters(in: .whitespaces)
            if let doubleValue: Double = Double(cellCString)
            {
              c = doubleValue
            }
            // when we have read 'CRYST1 a b c' we consider this a MolecularCrystal
            if(!asMolecule)
            {
              periodic = true
            }
            
            guard (length >= 41) else
            {
              let cellAlphaString: String = scannedLine.substring(from: 33).trimmingCharacters(in: .whitespaces)
              if let doubleValue: Double = Double(cellAlphaString)
              {
                alpha = doubleValue
              }
              break
            }
            let cellAlphaString: String = scannedLine.substring(with: NSRange(location: 33, length: 7)).trimmingCharacters(in: .whitespaces)
            if let doubleValue: Double = Double(cellAlphaString)
            {
              alpha = doubleValue
            }
            guard (length >= 48) else
            {
              let cellBetaString: String = scannedLine.substring(from: 40).trimmingCharacters(in: .whitespaces)
              if let doubleValue: Double = Double(cellBetaString)
              {
                beta = doubleValue
              }
              break
            }
            let cellBetaString: String = scannedLine.substring(with: NSRange(location: 40, length: 7)).trimmingCharacters(in: .whitespaces)
            if let doubleValue: Double = Double(cellBetaString)
            {
              beta = doubleValue
            }
            guard (length >= 55) else
            {
              let cellGammaString: String = scannedLine.substring(from: 47).trimmingCharacters(in: .whitespaces)
              if let doubleValue: Double = Double(cellGammaString)
              {
                gamma = doubleValue
                self.cell = SKCell(a: a, b: b, c: c, alpha: alpha*Double.pi/180.0, beta: beta*Double.pi/180.0, gamma: gamma*Double.pi/180.0)
              }
              break
            }
            let cellGammaString: String = scannedLine.substring(with: NSRange(location: 47, length: 7)).trimmingCharacters(in: .whitespaces)
            if let doubleValue: Double = Double(cellGammaString)
            {
              gamma = doubleValue
              
              self.cell = SKCell(a: a, b: b, c: c, alpha: alpha*Double.pi/180.0, beta: beta*Double.pi/180.0, gamma: gamma*Double.pi/180.0)
            }
            
            guard (length >= 67) else
            {
              let spaceGroupString: String = scannedLine.substring(from: 55).trimmingCharacters(in: NSCharacterSet.whitespaces).lowercased().capitalizeFirst
              if (self.spaceGroup.number == 1)
              {
                if let spaceGroup = SKSpacegroup(H_M: spaceGroupString), !asMolecule
                {
                  self.spaceGroup = spaceGroup
                }
              }
              break
            }
            let spaceGroupString: String = (scannedLine.substring(with: NSRange(location: 55, length: 11)).trimmingCharacters(in: NSCharacterSet.whitespaces).lowercased().capitalizeFirst)
            
            if let spaceGroup = SKSpacegroup(H_M: spaceGroupString), !asMolecule
            {
              self.spaceGroup = spaceGroup
            }
            guard (length >= 70) else
            {
              break
            }
            let zValueString: String = scannedLine.substring(with: NSRange(location: 66, length: 4)).trimmingCharacters(in: .whitespaces)
            if let zValue: Int = Int(zValueString)
            {
              self.cell.zValue = zValue
            }
          case "ORIGX1":
            break
          case "ORIGX2":
            break
          case "ORIGX3":
            break
          case "ATOM  ", "HETATM":
            // count as nucleic acid atom
            numberOfNucleicAcidAtoms += 1
            numberOfAtoms += 1
            
            if keyword == "HETATM"
            {
              numberOfSolventAtoms += 1
            }
            
            guard (scannedLine.length >= 11) else
            {
              break
            }
            
            let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: "new", elementId: 0, uniqueForceFieldName: "C", position: SIMD3<Double>(0.0,0.0,0.0), charge: 0.0, color: NSColor.black, drawRadius: 1.0, bondDistanceCriteria: 1.0)
            
            let atomSerialNumberString: String = scannedLine.substring(with: NSRange(location: 6, length: 5))
            if let integerValue: Int = Int(atomSerialNumberString)
            {
              let atomSerialNumber: Int = integerValue
              atom.serialNumber = atomSerialNumber
            }
            guard (scannedLine.length >= 17) else
            {
              break
            }
            
            let atomName: String = scannedLine.substring(with: NSRange(location: 12, length: 4))
            let atomDisplayName: String = atomName.trimmingCharacters(in: CharacterSet.whitespaces) as String
            atom.displayName = atomDisplayName
            atom.remotenessIndicator = atomName[atomName.index(atomName.startIndex, offsetBy: 2)]
            atom.branchDesignator = atomName[atomName.index(atomName.startIndex, offsetBy: 3)]
            if atomName.count >= 2
            {
              let atomNameString = String(atomName.prefix(2)).trimmingCharacters(in: CharacterSet.whitespaces) as String
              if let atomicNumber: Int = SKElement.atomData[atomNameString.capitalizeFirst]?["atomicNumber"] as? Int
              {
                atom.uniqueForceFieldName = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
                atom.elementIdentifier = atomicNumber
              }
              else
              {
                let letters = CharacterSet.letters
                let atomNameString = String(atomName.unicodeScalars.filter { letters.contains($0)})
                if let atomicNumber: Int = SKElement.atomData[atomNameString.capitalizeFirst]?["atomicNumber"] as? Int, atomicNumber>0
                {
                  atom.uniqueForceFieldName = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
                  atom.elementIdentifier = atomicNumber
                }
              }
            }
            
            guard (scannedLine.length >= 18) else
            {
              break
            }
            let alternateLocationIndicator: String = scannedLine.substring(with: NSRange(location: 16, length: 1))
            atom.alternateLocationIndicator = Character(alternateLocationIndicator)
            
            guard (scannedLine.length >= 21) else
            {
              break
            }
            let residueName: String = scannedLine.substring(with: NSRange(location: 17, length: 3))
            atom.residueName = residueName as String
            
            
            if let residueData: Dictionary<String,Any> = SKElement.residueDefinitions[residueName.uppercased() + "+" + atomDisplayName.uppercased()]
            {
              numberOfAminoAcidAtoms += 1
              if let name: String = residueData["Element"] as? String,
                let atomicNumber: Int = SKElement.atomData[name.capitalizeFirst]?["atomicNumber"] as? Int,
                atomicNumber>0
              {
                atom.elementIdentifier = atomicNumber
                atom.uniqueForceFieldName = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
              }
            }
            
            
            guard (scannedLine.length >= 23) else
            {
              break
            }
            let chainIdentifier: String = scannedLine.substring(with: NSRange(location: 21, length: 1))
            atom.chainIdentifier = Character(chainIdentifier)
            
            guard (scannedLine.length >= 27) else
            {
              break
            }
            let residueSequenceNumberString: String = scannedLine.substring(with: NSRange(location: 22, length: 4))
            if let residueSequenceNumber = Int(residueSequenceNumberString.trimmingCharacters(in: .whitespaces))
            {
              atom.residueSequenceNumber = residueSequenceNumber
            }
            
            guard (scannedLine.length >= 28) else
            {
              break
            }
            let codeForInsertionOfResidues: String = scannedLine.substring(with: NSRange(location: 26, length: 1))
            atom.codeForInsertionOfResidues = Character(codeForInsertionOfResidues)
            
            guard (scannedLine.length >= 54) else
            {
              let _ = chainIdentifier
              break
            }
            let orthogonalXCoordinateString: String = scannedLine.substring(with: NSRange(location: 30, length: 8)).trimmingCharacters(in: .whitespaces)
            let orthogonalYCoordinateString: String = scannedLine.substring(with: NSRange(location: 38, length: 8)).trimmingCharacters(in: .whitespaces)
            let orthogonalZCoordinateString: String = scannedLine.substring(with: NSRange(location: 46, length: 8)).trimmingCharacters(in: .whitespaces)
            
            
            if let orthogonalXCoordinate: Double = Double(orthogonalXCoordinateString),
              let orthogonalYCoordinate: Double = Double(orthogonalYCoordinateString),
              let orthogonalZCoordinate: Double = Double(orthogonalZCoordinateString)
            {
              // with the position we have enough information to decide to add the atom
              atom.fractional = false
              atom.position = SIMD3<Double>(x: orthogonalXCoordinate, y: orthogonalYCoordinate, z: orthogonalZCoordinate)
            }
            guard (scannedLine.length >= 60) else
            {
              if atom.elementIdentifier == 0
              {
                unknownAtoms.insert(atom.displayName)
              }
              // add atom to the list
              atoms.append(atom)
              break
            }
            let occupancyString: String = scannedLine.substring(with: NSRange(location: 54, length: 6)).trimmingCharacters(in: .whitespaces)
            
            if let occupancy: Double = Double(occupancyString)
            {
              atom.occupancy = occupancy
            }
            guard (scannedLine.length >= 66) else
            {
              if atom.elementIdentifier == 0
              {
                unknownAtoms.insert(atom.displayName)
              }
              // add atom to the list
              atoms.append(atom)
              break
            }
            let temperatureFactorString: String = scannedLine.substring(with: NSRange(location: 60, length: 6)).trimmingCharacters(in: .whitespaces)
            if let temperatureFactor = Double(temperatureFactorString)
            {
              atom.temperaturefactor = temperatureFactor
            }
            
            guard (scannedLine.length >= 76) else
            {
              if atom.elementIdentifier == 0
              {
                unknownAtoms.insert(atom.displayName)
              }
              // add atom to the list
              atoms.append(atom)
              break
            }
            let segmentIdentifier: String = scannedLine.substring(with: NSRange(location: 72, length: 4))
            guard (scannedLine.length >= 78) else
            {
              let _ = segmentIdentifier
              if atom.elementIdentifier == 0
              {
                unknownAtoms.insert(atom.displayName)
              }
              // add atom to the list
              atoms.append(atom)
              break
            }
            
            
            let elementSymbol: String = scannedLine.substring(with: NSRange(location: 76, length: 2))
            let elementSymbolString: String = elementSymbol.trimmingCharacters(in: CharacterSet.whitespaces)
            if let atomicNumber: Int = SKElement.atomData[elementSymbolString.capitalizeFirst]?["atomicNumber"] as? Int, atomicNumber>0
            {
              atom.elementIdentifier = atomicNumber
              atom.uniqueForceFieldName = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
            }
            
            guard (scannedLine.length >= 80) else
            {
              // add atom to the list
              if atom.elementIdentifier == 0
              {
                unknownAtoms.insert(atom.displayName)
              }
              atoms.append(atom)
              break
            }
            
            let chargeString: String = scannedLine.substring(with: NSRange(location: 78, length: 2))
            if let chargeValue: Double = Double(chargeString.trimmingCharacters(in: .whitespaces))
            {
              atom.charge = chargeValue
            }
            
            if atom.elementIdentifier == 0
            {
              unknownAtoms.insert(atom.displayName)
            }
            
            // add atom to the list
            atoms.append(atom)
          default:
            //debugPrint("scannedLine \(scannedLine)")
            break
          }
        }
      }
      
      // update progress
      currentProgressCount += 1.0
      if( Int(currentProgressCount * percentageFinishedStep) > Int((currentProgressCount-1.0) * percentageFinishedStep))
      {
        progress.completedUnitCount += 1
      }
    }
    
    // add current frame in case last TER, ENDMDL, or END is missing
    addFrameToStructure()
  }
  
}



