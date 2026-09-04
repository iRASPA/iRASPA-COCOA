/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 J.Vreede@uva.nl      https://www.uva.nl/en/profile/v/r/j.vreede/j.vreede.html
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

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import simd
import MathKit


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
  let fileLines: [String]
  
  var periodic: Bool = false
  var onlyAsymmetricUnitMolecule: Bool = false
  var asMolecule: Bool = false
  var asProtein: Bool = false
  var preview: Bool = false
  /// PDB TER records end a polymer chain. When false (default), TER is ignored so
  /// every chain stays in one structure; when true, each TER starts a new movie.
  var separatePolymerChains: Bool = false
  
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
  
  var numberOfAminoAcidAtoms: Int = 0
  var numberOfNucleicAcidAtoms: Int = 0
  var ligandAtoms: Int = 0
  var numberOfSolventAtoms: Int = 0
  var numberOfAtoms: Int = 0
  
  var proteinDetected: Bool = false
  var dnaDetected: Bool = false
  /// An entry solved in solution or in the microscope carries a placeholder cell.
  var experimentIsNonPeriodic: Bool = false
  
  private struct ResidueKey: Hashable
  {
    let chain: Character
    let sequence: Int
  }
  
  private struct ResidueRecord
  {
    var name: String = ""
    var hasNitrogen: Bool = false
    var hasAlphaCarbon: Bool = false
    var hasCarbonyl: Bool = false
    var water: Bool = false
    var nucleotide: Bool = false
    var nitrogen: SIMD3<Double> = .zero
    var carbonyl: SIMD3<Double> = .zero
  }
  
  private var polymerChains: Set<Character> = []
  private var modifiedResidues: Set<String> = []
  private var residues: [ResidueKey: ResidueRecord] = [:]
  
  public var progress: Progress
  let totalProgressCount: Int
  var currentProgressCount: Double = 0.0
  let percentageFinishedStep: Double
  
  private static func isWaterResidue(_ residueName: String) -> Bool
  {
    switch residueName
    {
    case "HOH", "DOD", "WAT", "H2O": return true
    default: return false
    }
  }
  
  private static func isSolventAgentResidue(_ residueName: String) -> Bool
  {
    let agents: Set<String> = [
      "SO4", "PO4", "GOL", "EDO", "MPD", "PEG", "PG4", "ACT", "ACY", "DMS",
      "TRS", "MES", "EPE", "IMD", "FMT", "NA", "K", "MG", "CA", "ZN",
      "MN", "FE", "NI", "CU", "CD", "CL", "BR", "IOD", "F", "CO"
    ]
    return agents.contains(residueName)
  }
  
  /// A cell of 1 Å on a side with right angles is the PDB placeholder when there is no crystal.
  private static func isPlaceholderCell(a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double) -> Bool
  {
    let isOne: (Double) -> Bool = { abs($0 - 1.0) < 1.0e-3 }
    let isRight: (Double) -> Bool = { abs($0 - 90.0) < 1.0e-3 }
    return isOne(a) && isOne(b) && isOne(c) && isRight(alpha) && isRight(beta) && isRight(gamma)
  }
  
  private func noteResidueAtom(_ atom: SKAsymmetricAtom)
  {
    let residueName: String = atom.residueName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    guard !residueName.isEmpty else {return}
    
    let key = ResidueKey(chain: atom.chainIdentifier, sequence: atom.residueSequenceNumber)
    var residue: ResidueRecord = residues[key] ?? ResidueRecord()
    residue.name = residueName
    residue.water = Self.isWaterResidue(residueName)
    residue.nucleotide = SKNucleotide.isNucleotideResidueName(residueName)
    
    let atomName: String = atom.displayName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if atomName == "N"
    {
      residue.hasNitrogen = true
      residue.nitrogen = atom.position
    }
    else if atomName == "CA"
    {
      residue.hasAlphaCarbon = true
    }
    else if atomName == "C"
    {
      residue.hasCarbonyl = true
      residue.carbonyl = atom.position
    }
    residues[key] = residue
  }
  
  private func parseSeqres(_ line: String)
  {
    guard line.count >= 19 else {return}
    let chainField = pdbField(line, 11, 1)
    guard let chainIdentifier = chainField.first else {return}
    var start = 19
    while start + 3 <= line.count
    {
      let residueName = pdbField(line, start, 3).trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
      start += 4
      guard !residueName.isEmpty, !Self.isWaterResidue(residueName) else {continue}
      if SKElement.knownAminoAcidResidueCodes.contains(residueName) || SKNucleotide.isNucleotideResidueName(residueName)
      {
        polymerChains.insert(chainIdentifier)
        return
      }
    }
  }
  
  private func parseModres(_ line: String)
  {
    guard line.count >= 15 else {return}
    let residueName = pdbField(line, 12, 3).trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if !residueName.isEmpty
    {
      modifiedResidues.insert(residueName)
    }
  }
  
  private func kindOfCurrentPart() -> SKStructure.Kind
  {
    var peptideResidues = 0
    var nucleicResidues = 0
    var waterResidues = 0
    var otherResidues = 0
    
    let sortedResidues = residues.sorted
    {
      if $0.key.chain != $1.key.chain {return $0.key.chain < $1.key.chain}
      return $0.key.sequence < $1.key.sequence
    }
    
    for (key, residue) in sortedResidues
    {
      let declaredPolymer = polymerChains.contains(key.chain) &&
        (modifiedResidues.contains(residue.name) ||
         SKElement.knownAminoAcidResidueCodes.contains(residue.name) ||
         SKNucleotide.isNucleotideResidueName(residue.name))
      
      if residue.water
      {
        waterResidues += 1
      }
      else if residue.nucleotide || (declaredPolymer && SKNucleotide.isNucleotideResidueName(residue.name))
      {
        nucleicResidues += 1
      }
      else if (residue.hasNitrogen && residue.hasAlphaCarbon && residue.hasCarbonyl) ||
              (declaredPolymer && !Self.isWaterResidue(residue.name) && !SKNucleotide.isNucleotideResidueName(residue.name))
      {
        peptideResidues += 1
      }
      else
      {
        otherResidues += 1
      }
    }
    
    var peptideBonds = 0
    var previous: ResidueRecord?
    var previousChain: Character?
    for (key, residue) in sortedResidues
    {
      if let previous, let previousChain, key.chain == previousChain,
         previous.hasCarbonyl, residue.hasNitrogen
      {
        if simd_length(previous.carbonyl - residue.nitrogen) < 2.0
        {
          peptideBonds += 1
        }
      }
      previous = residue
      previousChain = key.chain
    }
    
    let isProtein = peptideResidues >= 2 && peptideBonds >= 1 && peptideResidues > otherResidues
    if isProtein
    {
      proteinDetected = true
      return (periodic && !asProtein) ? .proteinCrystal : .protein
    }
    
    let isDNA = nucleicResidues >= 2 && nucleicResidues > otherResidues && nucleicResidues >= peptideResidues
    if isDNA
    {
      dnaDetected = true
      return (periodic && !asMolecule) ? .dnaCrystal : .dna
    }
    
    // Fallback: atom-fraction heuristics for sparse residue metadata
    if numberOfAtoms > 0
    {
      if Double(numberOfAminoAcidAtoms) / Double(numberOfAtoms) > 0.5
      {
        proteinDetected = true
        return (periodic && !asProtein) ? .proteinCrystal : .protein
      }
      if Double(numberOfNucleicAcidAtoms) / Double(numberOfAtoms) > 0.5
      {
        dnaDetected = true
        return (periodic && !asMolecule) ? .dnaCrystal : .dna
      }
    }
    
    var onlySolvent = waterResidues > 0 && peptideResidues == 0 && nucleicResidues == 0
    if onlySolvent
    {
      for (_, residue) in residues
      {
        if !residue.water && !Self.isSolventAgentResidue(residue.name)
        {
          onlySolvent = false
          break
        }
      }
    }
    
    if proteinDetected && onlySolvent
    {
      return (periodic && !asProtein) ? .proteinCrystalSolvent : .molecule
    }
    if dnaDetected && onlySolvent
    {
      return (periodic && !asMolecule) ? .dnaCrystal : .dna
    }
    
    return (periodic && !asMolecule) ? .molecularCrystal : .molecule
  }
  
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
        
        let kind = kindOfCurrentPart()
        scene[currentMovie][currentFrame].kind = kind
        
        switch kind
        {
        case .proteinCrystal, .proteinCrystalSolvent, .dnaCrystal:
          scene[currentMovie][currentFrame].drawUnitCell = !onlyAsymmetricUnitMolecule
          scene[currentMovie][currentFrame].spaceGroupHallNumber = onlyAsymmetricUnitMolecule ? 1 : self.spaceGroup.spaceGroupSetting.number
        case .molecularCrystal:
          scene[currentMovie][currentFrame].drawUnitCell = true
          scene[currentMovie][currentFrame].spaceGroupHallNumber = self.spaceGroup.spaceGroupSetting.number
        default:
          scene[currentMovie][currentFrame].drawUnitCell = false
          scene[currentMovie][currentFrame].spaceGroupHallNumber = 1
        }
        
        scene[currentMovie][currentFrame].cell = cell
        scene[currentMovie][currentFrame].displayName = self.displayName
        scene[currentMovie][currentFrame].atoms = atoms
        scene[currentMovie][currentFrame].unknownAtoms = unknownAtoms
        scene[currentMovie][currentFrame].applyInferredMaterialType()
        
        atoms = []
        numberOfAminoAcidAtoms = 0
        numberOfNucleicAcidAtoms = 0
        numberOfSolventAtoms = 0
        numberOfAtoms = 0
        residues.removeAll(keepingCapacity: true)
      }
    }
    
  }
  
  public init(displayName: String, data: Data, onlyAsymmetricUnitMolecule: Bool, asMolecule: Bool, asProtein: Bool, preview: Bool = false, separatePolymerChains: Bool = false) throws
  {
    self.displayName = displayName
    self.onlyAsymmetricUnitMolecule = onlyAsymmetricUnitMolecule
    self.asMolecule = asMolecule
    self.asProtein = asProtein
    self.preview = preview
    self.separatePolymerChains = separatePolymerChains
    
    guard let string: String = String(data: data, encoding: String.Encoding.utf8) ?? String(data: data, encoding: String.Encoding.ascii) else
    {
      throw SKParserError.failedDecoding
    }
    
    self.fileLines = string.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
    
    progress = Progress()
    progress.totalUnitCount = 10
    
    totalProgressCount = fileLines.count
    percentageFinishedStep = 10.0/Double(max(totalProgressCount - 1, 1))
    
    atoms.reserveCapacity(min(max(data.count / 50, 256), 1_000_000))
    
  }
  
  private func pdbField(_ line: String, _ location: Int, _ length: Int) -> String
  {
    guard line.count >= location + length else {return ""}
    let start: String.Index = line.index(line.startIndex, offsetBy: location)
    let end: String.Index = line.index(start, offsetBy: length)
    return String(line[start..<end])
  }
  
  private func updateParseProgress(_ lineNumber: Int)
  {
    currentProgressCount = Double(lineNumber)
    if Int(currentProgressCount * percentageFinishedStep) > Int((currentProgressCount - 1.0) * percentageFinishedStep)
    {
      progress.completedUnitCount += 1
    }
  }
  
  private func parseAndAppendAtomRecord(line: String, isHetatm: Bool)
  {
    numberOfAtoms += 1
    
    if isHetatm
    {
      numberOfSolventAtoms += 1
    }
    
    guard line.count >= 11 else {return}
    
    var atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: "new", elementId: 0, uniqueForceFieldName: "C", position: SIMD3<Double>(0.0, 0.0, 0.0), charge: 0.0, color: NSColor.black, drawRadius: 1.0, bondDistanceCriteria: 1.0, occupancy: 1.0)
    atom.solvent = isHetatm
    
    if let integerValue: Int = Int(pdbField(line, 6, 5))
    {
      atom.serialNumber = integerValue
    }
    guard line.count >= 17 else {return}
    
    let atomName: String = pdbField(line, 12, 4)
    let atomDisplayName: String = atomName.trimmingCharacters(in: CharacterSet.whitespaces)
    atom.displayName = atomDisplayName
    if atomName.count >= 3
    {
      atom.remotenessIndicator = atomName[atomName.index(atomName.startIndex, offsetBy: 2)]
    }
    if atomName.count >= 4
    {
      atom.branchDesignator = atomName[atomName.index(atomName.startIndex, offsetBy: 3)]
    }
    if atomName.count >= 2
    {
      let atomNameString: String = String(atomName.prefix(2)).trimmingCharacters(in: CharacterSet.whitespaces)
      if let atomicNumber: Int = SKElement.atomicNumber(forSymbol: atomNameString)
      {
        atom.uniqueForceFieldName = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
        atom.elementIdentifier = atomicNumber
      }
      else
      {
        let letters: CharacterSet = CharacterSet.letters
        let symbolFromName: String = String(atomName.unicodeScalars.filter{letters.contains($0)})
        if let atomicNumber: Int = SKElement.atomicNumber(forSymbol: symbolFromName), atomicNumber > 0
        {
          atom.uniqueForceFieldName = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
          atom.elementIdentifier = atomicNumber
        }
      }
    }
    
    guard line.count >= 18 else {return}
    atom.alternateLocationIndicator = Character(pdbField(line, 16, 1))
    
    guard line.count >= 21 else {return}
    let residueName: String = pdbField(line, 17, 3)
    atom.residueName = residueName
    
    if let residueData: SKResidueAtomDefinition = SKElement.residueDefinitions[residueName.uppercased() + "+" + atomDisplayName.uppercased()]
    {
      numberOfAminoAcidAtoms += 1
      atom.backBoneAtom = SKElement.isBackboneAtomType(residueData.type)
      if let atomicNumber: Int = SKElement.atomicNumber(forSymbol: residueData.element),
         atomicNumber > 0
      {
        atom.elementIdentifier = atomicNumber
        atom.uniqueForceFieldName = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
      }
    }
    else if SKNucleotide.isNucleotideResidueName(residueName)
    {
      numberOfNucleicAcidAtoms += 1
    }
    
    guard line.count >= 23 else {return}
    atom.chainIdentifier = Character(pdbField(line, 21, 1))
    
    guard line.count >= 27 else {return}
    if let residueSequenceNumber: Int = Int(pdbField(line, 22, 4).trimmingCharacters(in: CharacterSet.whitespaces))
    {
      atom.residueSequenceNumber = residueSequenceNumber
    }
    
    guard line.count >= 28 else {return}
    atom.codeForInsertionOfResidues = Character(pdbField(line, 26, 1))
    
    guard line.count >= 54 else {return}
    if let orthogonalXCoordinate: Double = Double(pdbField(line, 30, 8).trimmingCharacters(in: CharacterSet.whitespaces)),
       let orthogonalYCoordinate: Double = Double(pdbField(line, 38, 8).trimmingCharacters(in: CharacterSet.whitespaces)),
       let orthogonalZCoordinate: Double = Double(pdbField(line, 46, 8).trimmingCharacters(in: CharacterSet.whitespaces))
    {
      atom.fractional = false
      atom.position = SIMD3<Double>(x: orthogonalXCoordinate, y: orthogonalYCoordinate, z: orthogonalZCoordinate)
    }
    
    if line.count >= 60,
       let occupancy: Double = Double(pdbField(line, 54, 6).trimmingCharacters(in: CharacterSet.whitespaces))
    {
      atom.occupancy = occupancy
    }
    
    if line.count >= 66,
       let temperatureFactor: Double = Double(pdbField(line, 60, 6).trimmingCharacters(in: CharacterSet.whitespaces))
    {
      atom.temperaturefactor = temperatureFactor
    }
    
    if line.count >= 78
    {
      let elementSymbolString: String = pdbField(line, 76, 2).trimmingCharacters(in: CharacterSet.whitespaces)
      if let atomicNumber: Int = SKElement.atomicNumber(forSymbol: elementSymbolString), atomicNumber > 0
      {
        atom.elementIdentifier = atomicNumber
        atom.uniqueForceFieldName = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
      }
    }
    
    if line.count >= 80,
       let chargeValue: Double = Double(pdbField(line, 78, 2).trimmingCharacters(in: CharacterSet.whitespaces))
    {
      atom.charge = chargeValue
    }
    
    if atom.elementIdentifier == 0
    {
      unknownAtoms.insert(atom.displayName)
    }
    
    noteResidueAtom(atom)
    atoms.append(atom)
  }
  
  public override func startParsing() throws
  {
    var lineNumber: Int = 0
    var modelNumber: Int = 0
    
    for line in fileLines
    {
      lineNumber += 1
      
      let length: Int = line.count
      guard length >= 3 else {continue}
      
      if line.hasPrefix("TER")
      {
        // TER marks the end of a polymer chain. Splitting on it puts each chain
        // in its own movie; with Separate polymer chains off, keep reading.
        if separatePolymerChains, atoms.count > 0
        {
          addFrameToStructure()
          currentMovie += 1
          if preview
          {
            return
          }
        }
        updateParseProgress(lineNumber)
        continue
      }
      
      if line.hasPrefix("ATOM  ")
      {
        parseAndAppendAtomRecord(line: line, isHetatm: false)
        updateParseProgress(lineNumber)
        continue
      }
      if line.hasPrefix("HETATM")
      {
        parseAndAppendAtomRecord(line: line, isHetatm: true)
        updateParseProgress(lineNumber)
        continue
      }
      
      guard length >= 6 else
      {
        updateParseProgress(lineNumber)
        continue
      }
      
      let scannedLine: NSString = line as NSString
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
      case "EXPDTA":
        let experiment = scannedLine.substring(from: 6).trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if experiment.contains("NMR") || experiment.contains("ELECTRON MICROSCOPY") ||
           experiment.contains("SOLUTION SCATTERING") || experiment.contains("THEORETICAL MODEL")
        {
          experimentIsNonPeriodic = true
          periodic = false
        }
      case "SEQRES":
        parseSeqres(line)
      case "MODRES":
        parseModres(line)
      case "MODEL ":
        currentMovie = 0
        
        if length <= 10
        {
          let modelString: String = scannedLine.substring(from: 6)
          if let integerValue: Int = Int(modelString)
          {
            atoms = []
            currentFrame = max(0, integerValue - 1)
            currentFrame = modelNumber
            modelNumber += 1
          }
          break
        }
        if length <= 14
        {
          let modelString: String = scannedLine.substring(from: 10)
          if let integerValue: Int = Int(modelString)
          {
            currentFrame = max(0, integerValue - 1)
          }
          break
        }
        let modelString: String = scannedLine.substring(with: NSRange(location: 10, length: 4))
        if let integerValue: Int = Int(modelString)
        {
          currentFrame = max(0, integerValue - 1)
        }
      case "ENDMDL":
        addFrameToStructure()
        currentFrame += 1
        updateParseProgress(lineNumber)
        continue
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
            let cellIsReal = a > 0.0 && b > 0.0 && c > 0.0 &&
              !Self.isPlaceholderCell(a: a, b: b, c: c, alpha: alpha, beta: beta, gamma: gamma)
            periodic = cellIsReal && !experimentIsNonPeriodic
            break
          }
          let cellCString: String = scannedLine.substring(with: NSRange(location: 24, length: 9)).trimmingCharacters(in: .whitespaces)
          if let doubleValue: Double = Double(cellCString)
          {
            c = doubleValue
          }
        
          guard (length >= 41) else
          {
            let cellAlphaString: String = scannedLine.substring(from: 33).trimmingCharacters(in: .whitespaces)
            if let doubleValue: Double = Double(cellAlphaString)
            {
              alpha = doubleValue
            }
            let cellIsReal = a > 0.0 && b > 0.0 && c > 0.0 &&
              !Self.isPlaceholderCell(a: a, b: b, c: c, alpha: alpha, beta: beta, gamma: gamma)
            periodic = cellIsReal && !experimentIsNonPeriodic
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
            let cellIsReal = a > 0.0 && b > 0.0 && c > 0.0 &&
              !Self.isPlaceholderCell(a: a, b: b, c: c, alpha: alpha, beta: beta, gamma: gamma)
            periodic = cellIsReal && !experimentIsNonPeriodic
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
            let cellIsReal = a > 0.0 && b > 0.0 && c > 0.0 &&
              !Self.isPlaceholderCell(a: a, b: b, c: c, alpha: alpha, beta: beta, gamma: gamma)
            periodic = cellIsReal && !experimentIsNonPeriodic
            break
          }
          let cellGammaString: String = scannedLine.substring(with: NSRange(location: 47, length: 7)).trimmingCharacters(in: .whitespaces)
          if let doubleValue: Double = Double(cellGammaString)
          {
            gamma = doubleValue
        
            self.cell = SKCell(a: a, b: b, c: c, alpha: alpha*Double.pi/180.0, beta: beta*Double.pi/180.0, gamma: gamma*Double.pi/180.0)
          }
          let cellIsReal = a > 0.0 && b > 0.0 && c > 0.0 &&
            !Self.isPlaceholderCell(a: a, b: b, c: c, alpha: alpha, beta: beta, gamma: gamma)
          periodic = cellIsReal && !experimentIsNonPeriodic
        
          guard (length >= 67) else
          {
            let spaceGroupString: String = scannedLine.substring(from: 55).trimmingCharacters(in: NSCharacterSet.whitespaces).lowercased().capitalizeFirst
            if (self.spaceGroup.number == 1)
            {
              if let spaceGroup = SKSpacegroup(H_M: spaceGroupString)
              {
                self.spaceGroup = spaceGroup
              }
            }
            break
          }
          let spaceGroupString: String = (scannedLine.substring(with: NSRange(location: 55, length: 11)).trimmingCharacters(in:   NSCharacterSet.whitespaces).lowercased().capitalizeFirst)
        
          if let spaceGroup = SKSpacegroup(H_M: spaceGroupString)
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
        default:
          break
        }
      
      updateParseProgress(lineNumber)
    }
    
    if atoms.count > 0
    {
      addFrameToStructure()
    }
  }
  
}



