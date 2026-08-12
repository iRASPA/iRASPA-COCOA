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

import Cocoa
import simd
import LogViewKit


public final class SKCIFParser: SKParser, ProgressReporting
{
  var onlyAsymmetricUnit: Bool
  /// When true, treat biomolecular models as non-periodic molecules/proteins.
  var asMolecule: Bool
  /// When true (default for protein import), prefer `.protein` over `.proteinCrystal`.
  var asProtein: Bool
  /// Kept for API parity with the PDB reader; CIF/mmCIF has no TER records.
  var separatePolymerChains: Bool
  var a: Double = 0.0
  var b: Double = 0.0
  var c: Double = 0.0
  var alpha: Double = 90.0
  var beta: Double = 90.0
  var gamma: Double = 90.0
  var cellFormulaUnitsZ: Int = 0
  var cellLengthsDefined: Bool = false
  var scanner: Scanner
  let letterSet: CharacterSet
  let nonLetterSet: CharacterSet
  let whiteSpacesAndNewlines: CharacterSet
  let keywordSet: CharacterSet
  let newLineChararterSet: CharacterSet
  let letters = CharacterSet.letters
  let digits = CharacterSet.decimalDigits
  
  var atoms: [SKAsymmetricAtom] = []
  var numberOfAminoAcidAtoms: Int = 0
  var numberOfNucleicAcidAtoms: Int = 0
  var numberOfAtoms: Int = 0
  var proteinDetected: Bool = false
  var dnaDetected: Bool = false
  
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
  /// Maps `_struct_asym.id` → `_struct_asym.entity_id` for polymer-chain discovery.
  private var asymToEntity: [String: String] = [:]
  /// Entity ids whose `_entity_poly.type` is a polypeptide or nucleic acid.
  private var polymerEntityIds: Set<String> = []
  
  enum SpaceGroupStatus: Int
  {
    case notFound = 0
    case HallSymbolFound = 1
    case HMSymbolFound = 2
    case NumberFound = 3
    case CIFSymmetryOperationsFound = 4
  }
  
  var spaceGroupFound: SpaceGroupStatus = .notFound
  var spaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: 1)
  var spaceGroupITNumber: Int = 0
  var cifSymmetryOperationStrings: [String] = []
  var cifSymmetryOperations: [SKSeitzIntegerMatrix] = []
  
  var name: String = ""
  
  var creationDate: String?
  var creationMethod: String?
  
  var chemicalFormulaStructural: String?
  var chemicalFormulaSum: String?
  
  var numberOfChannels: Int?
  var numberOfPockets: Int?
  var dimensionality: Int?
  var Di: Double?
  var Df: Double?
  var Dif: Double?
 
  var currentMovie: Int = 0
  var currentFrame: Int = 0
  
  public var progress: Progress
  
  func checkForComment() -> Bool
  {
    let _: String.Index = self.scanner.currentIndex
    return true
  }
  
  public init(displayName: String,
              data: Data,
              onlyAsymmetricUnit: Bool = false,
              asMolecule: Bool = false,
              asProtein: Bool = true,
              separatePolymerChains: Bool = false) throws
  {
    self.name = displayName
    self.onlyAsymmetricUnit = onlyAsymmetricUnit
    self.asMolecule = asMolecule
    self.asProtein = asProtein
    self.separatePolymerChains = separatePolymerChains
    
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
  }
  
  public override func startParsing() throws
  {
    // define 1 steps
    progress.totalUnitCount = 1
    
    while(!scanner.isAtEnd)
    {
      // scan to first keyword
      let previousScanLocation: String.Index = self.scanner.currentIndex
      
      if let tempstring: String = scanner.scanCharacters(from: keywordSet),
         let keyword: CaseInsensitiveString = CaseInsensitiveString(tempstring)
      {
        if (keyword.hasPrefix("_audit"))
        {
          parseAudit(keyword)
        }
        else if (keyword.hasPrefix("_iraspa"))
        {
          parseiRASPA(keyword)
        }
        else if (keyword.hasPrefix("_chemical"))
        {
          parseChemical(keyword)
        }
        else if (keyword.hasPrefix("_cell"))
        {
          parseCell(keyword)
        }
        else if (keyword.hasPrefix("_symmetry"))
        {
          parseSymmetry(keyword)
        }
        else if (keyword.hasPrefix("_space_group"))
        {
          parseSymmetry(keyword)
        }
        else if (keyword.hasPrefix("_pdbx_struct_mod_residue"))
        {
          parseModResidue(keyword)
        }
        else if (keyword.hasPrefix("data_"))
        {
          parseName(keyword)
        }
        else if (keyword.hasPrefix("loop_"))
        {
          parseLoop()
        }
        else if (keyword.hasPrefix("#"))
        {
          // set back for the case that there is only a string of "#####"
          self.scanner.currentIndex = previousScanLocation
          skipComment()
        }
        else if tempstring.hasPrefix("_")
        {
          // Unknown CIF/mmCIF data item: consume the value so the scanner stays aligned.
          _ = parseValue()
        }
      }
    }
    
    // post-reading
    //=============
    
    resolveSpaceGroupFromCIFSymmetryOperations()
    resolvePolymerChainsFromEntityTables()
    
    scene.append([SKStructure()])
    
    let cellA: Double = (a > 1e-6) ? a : 20.0
    let cellB: Double = (b > 1e-6) ? b : 20.0
    let cellC: Double = (c > 1e-6) ? c : 20.0
    let cell: SKCell = SKCell(a: cellA, b: cellB, c: cellC, alpha: alpha*Double.pi/180.0, beta: beta*Double.pi/180.0, gamma: gamma*Double.pi/180.0)
    
    let kind: SKStructure.Kind = kindOfCurrentPart()
    scene[currentMovie][currentFrame].kind = kind
    
    switch kind
    {
    case .protein, .dna:
      scene[currentMovie][currentFrame].drawUnitCell = false
      scene[currentMovie][currentFrame].spaceGroupHallNumber = 1
      scene[currentMovie][currentFrame].periodic = false
    case .proteinCrystal, .dnaCrystal, .proteinCrystalSolvent:
      scene[currentMovie][currentFrame].drawUnitCell = !onlyAsymmetricUnit
      scene[currentMovie][currentFrame].spaceGroupHallNumber = onlyAsymmetricUnit ? 1 : self.spaceGroup.spaceGroupSetting.number
      scene[currentMovie][currentFrame].periodic = true
    default:
      scene[currentMovie][currentFrame].drawUnitCell = true
      scene[currentMovie][currentFrame].spaceGroupHallNumber = self.spaceGroup.spaceGroupSetting.number
      scene[currentMovie][currentFrame].periodic = true
    }
    
    scene[currentMovie][currentFrame].cifSymmetryOperations = self.cifSymmetryOperations.isEmpty ? nil : self.cifSymmetryOperations
    
    scene[currentMovie][currentFrame].displayName = self.name
    
    scene[currentMovie][currentFrame].cell = cell
    scene[currentMovie][currentFrame].atoms = self.atoms
    scene[currentMovie][currentFrame].creationDate = self.creationDate
    scene[currentMovie][currentFrame].creationMethod = self.creationMethod
    scene[currentMovie][currentFrame].chemicalFormulaSum = self.chemicalFormulaSum
    scene[currentMovie][currentFrame].chemicalFormulaStructural = self.chemicalFormulaStructural
    scene[currentMovie][currentFrame].cellFormulaUnitsZ = self.cellFormulaUnitsZ
    
    scene[currentMovie][currentFrame].numberOfChannels = self.numberOfChannels
    scene[currentMovie][currentFrame].numberOfPockets = self.numberOfPockets
    scene[currentMovie][currentFrame].dimensionality = self.dimensionality
    scene[currentMovie][currentFrame].Di = self.Di
    scene[currentMovie][currentFrame].Df = self.Df
    scene[currentMovie][currentFrame].Dif = self.Dif
    
    progress.completedUnitCount = 1
  }
  
  func skipComment()
  {
    let _ = self.scanner.scanUpToCharacters(from: CharacterSet.newlines)
  }
  
  func scanInteger() -> Int
  {
    guard let string: String = parseValue() else {return 0}
    let cleaned: String = string.split(separator: "(").first.map(String.init) ?? string
    return (cleaned as NSString).integerValue
  }
  
  func scanDouble() -> Double
  {
    guard let string: String = parseValue() else {return 0.0}
    return parseCIFDouble(string) ?? 0.0
  }
  
  func scanString() -> String?
  {
    return parseValue()
  }
  
  func parseName(_ keyword: CaseInsensitiveString)
  {
    self.name = keyword.description
    let range = name.startIndex..<name.index(name.startIndex, offsetBy: 5)
    self.name.removeSubrange(range)
  }
  
  func parseiRASPA(_ keyword: CaseInsensitiveString)
  {
    switch(keyword)
    {
    case "_iraspa_number_of_channels":
      let value: Int = scanInteger()
      self.numberOfChannels = value
    case "_iraspa_number_of_pockets":
      let value: Int = scanInteger()
      self.numberOfPockets = value
    case "_iraspa_dimensionality":
      let value: Int = scanInteger()
      self.dimensionality = value
    case "_iraspa_Di":
      let value: Double = scanDouble()
      self.Di = value
    case "_iraspa_Df":
      let value: Double = scanDouble()
      self.Df = value
    case "_iraspa_Dif":
      let value: Double = scanDouble()
      self.Dif = value
    default:
      _ = parseValue()
    }
  }
  
  
  func parseSymmetry(_ keyword: CaseInsensitiveString)
  {
    switch(keyword)
    {
    case "_symmetry_cell_setting":
      _ = parseValue()
    case "_space_group_name_Hall",
         "_symmetry_space_group_name_Hall",
         "_symmetry.space_group_name_Hall":
      if let string: String = parseValue(),
         let spaceGroup = SKSpacegroup(Hall: string)
      {
        self.spaceGroup = spaceGroup
        spaceGroupFound = .HallSymbolFound
        self.spaceGroupITNumber = spaceGroup.spaceGroupSetting.spaceGroupNumber
      }
    case "_space_group_name_H-M_alt",
         "_symmetry_space_group_name_H-M",
         "_symmetry.pdbx_full_space_group_name_H-M":
      if (spaceGroupFound != .HallSymbolFound)
      {
        if let string: String = parseValue(),
           let spaceGroup = SKSpacegroup(H_M: string)
        {
          self.spaceGroup = spaceGroup
          spaceGroupFound = .HMSymbolFound
          self.spaceGroupITNumber = spaceGroup.spaceGroupSetting.spaceGroupNumber
        }
      }
      else
      {
        _ = parseValue()
      }
    case "_space_group_IT_number",
         "_symmetry_Int_Tables_number",
         "_symmetry.Int_Tables_number":
      if (spaceGroupFound == .notFound)
      {
        let number: Int = scanInteger()
        self.spaceGroupITNumber = number
        if let spaceGroup = SKSpacegroup(number: number)
        {
          self.spaceGroup = spaceGroup
          spaceGroupFound = .NumberFound
        }
      }
      else
      {
        self.spaceGroupITNumber = scanInteger()
      }
    case "_symmetry_equiv_pos_as_xyz",
         "_space_group_symop_operation_xyz":
      if let string: String = parseValue()
      {
        parseSymmetryEquivPos(string)
      }
    default:
      _ = parseValue()
    }
  }
  
  
  func parseChemical(_ keyword: CaseInsensitiveString)
  {
    if let keyword: ChemicalFormula = ChemicalFormula(rawValue: keyword)
    {
      switch(keyword)
      {
      case .chemical_formula_analytical:
        _ = parseValue()
      case .chemical_formula_iupac:
        _ = parseValue()
      case .chemical_formula_moiety:
        _ = parseValue()
      case .chemical_formula_structural:
        if let string: String = parseValue()
        {
          self.chemicalFormulaStructural = string
        }
      case .chemical_formula_sum:
        if let string: String = parseValue()
        {
          self.chemicalFormulaSum = string
        }
      case .chemical_formula_weight:
        _ = parseValue()
      case .chemical_formula_weight_meas:
        _ = parseValue()
      }
    }
    else
    {
      _ = parseValue()
    }
  }
  
  func parseAudit(_ keyword: CaseInsensitiveString)
  {
    switch(keyword)
    {
    case "_audit_creation_date":
      if let string: String = parseValue()
      {
        self.creationDate = string
      }
    case "_audit_creation_method":
      if let string: String = parseValue()
      {
        self.creationMethod = string
      }
    default:
      _ = parseValue()
    }
  }
  
  func parseCell(_ keyword: CaseInsensitiveString)
  {
    switch(keyword)
    {
    case "_cell_length_a","_cell.length_a":
      a = scanDouble()
      cellLengthsDefined = true
    // assign a to cell-data
    case "_cell_length_b","_cell.length_b":
      b = scanDouble()
      cellLengthsDefined = true
    // assign b to cell-data
    case "_cell_length_c","_cell.length_c":
      c = scanDouble()
      cellLengthsDefined = true
    // assign c to cell-data
    case "_cell_angle_alpha","_cell.angle_alpha":
      alpha = scanDouble()
    // assign alpha to cell-data
    case "_cell_angle_beta","_cell.angle_beta":
      beta = scanDouble()
    // assign beta to cell-data
    case "_cell_angle_gamma","_cell.angle_gamma":
      gamma = scanDouble()
    // assign gamma to cell-data
    case "_cell_volume":
      _ = parseValue()
    case "_cell_formula_units_Z","_cell.Z_PDB":
      cellFormulaUnitsZ = scanInteger()
      break
    default:
      // Ignore unrecognized mmCIF/coreCIF cell tags (e.g. _cell.entry_id, *_esd).
      _ = parseValue()
    }
  }
  
  func parseModResidue(_ keyword: CaseInsensitiveString)
  {
    guard let value: String = parseValue() else {return}
    switch keyword
    {
    case "_pdbx_struct_mod_residue.label_comp_id",
         "_pdbx_struct_mod_residue.auth_comp_id":
      let trimmed: String = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
      if !trimmed.isEmpty && trimmed != "?" && trimmed != "."
      {
        modifiedResidues.insert(trimmed)
      }
    default:
      break
    }
  }
  
  func parseValue() -> String?
  {
    if self.scanner.isAtEnd
    {
      return nil
    }
    
    skipWhitespaceAndComments()
    guard !self.scanner.isAtEnd else {return nil}
    
    let previousScanLocation: String.Index = self.scanner.currentIndex
    let source: String = self.scanner.string
    let first: Character = source[self.scanner.currentIndex]
    
    // CIF text field: semicolon at start of a line
    if first == ";"
    {
      var index: String.Index = source.index(after: self.scanner.currentIndex)
      var content: String = ""
      while index < source.endIndex && source[index] != "\n" && source[index] != "\r"
      {
        content.append(source[index])
        index = source.index(after: index)
      }
      while index < source.endIndex && (source[index] == "\n" || source[index] == "\r")
      {
        index = source.index(after: index)
      }
      
      while index < source.endIndex
      {
        if source[index] == ";"
        {
          index = source.index(after: index)
          self.scanner.currentIndex = index
          return content
        }
        if !content.isEmpty {content += "\n"}
        while index < source.endIndex && source[index] != "\n" && source[index] != "\r"
        {
          content.append(source[index])
          index = source.index(after: index)
        }
        while index < source.endIndex && (source[index] == "\n" || source[index] == "\r")
        {
          index = source.index(after: index)
        }
      }
      self.scanner.currentIndex = index
      return content
    }
    
    // Single- or double-quoted char strings (CIF allows '' / "" escapes)
    if first == "'" || first == "\""
    {
      let quote: Character = first
      var index: String.Index = source.index(after: self.scanner.currentIndex)
      var content: String = ""
      while index < source.endIndex
      {
        let character: Character = source[index]
        index = source.index(after: index)
        if character == quote
        {
          if index < source.endIndex && source[index] == quote
          {
            content.append(quote)
            index = source.index(after: index)
            continue
          }
          self.scanner.currentIndex = index
          return content
        }
        content.append(character)
      }
      self.scanner.currentIndex = index
      return content
    }
    
    // Temporarily disable whitespace skipping so we can restore precisely on loop terminators.
    let previousSkipped: CharacterSet? = self.scanner.charactersToBeSkipped
    self.scanner.charactersToBeSkipped = nil
    defer { self.scanner.charactersToBeSkipped = previousSkipped }
    
    if let string: String = self.scanner.scanCharacters(from: keywordSet)
    {
      let lower: String = string.lowercased()
      if string.hasPrefix("_") || lower.hasPrefix("loop_") || lower.hasPrefix("data_") || lower.hasPrefix("save_")
      {
        self.scanner.currentIndex = previousScanLocation
        return nil
      }
      return string
    }
    
    return nil
  }
  
  private func skipWhitespaceAndComments()
  {
    let source: String = self.scanner.string
    let whitespace: CharacterSet = CharacterSet.whitespacesAndNewlines
    while !self.scanner.isAtEnd
    {
      while !self.scanner.isAtEnd,
            let scalar = source[self.scanner.currentIndex].unicodeScalars.first,
            whitespace.contains(scalar)
      {
        self.scanner.currentIndex = source.index(after: self.scanner.currentIndex)
      }
      if !self.scanner.isAtEnd && source[self.scanner.currentIndex] == "#"
      {
        skipComment()
        // skipComment uses scanUpTo which may leave us on newline; continue loop
        continue
      }
      break
    }
  }
  
  
  
  // a loop can contain comments
  // <DataItems> = <Tag> <WhiteSpace> <Value> | <LoopHeader> <LoopBody>    [case sensitive]
  // <LoopHeader> = <LOOP_> {<WhiteSpace> <Tag>}+                          [case insensitive]
  // <LoopBody> = <Value> { <WhiteSpace> <Value> }*                        [case sensitive]
  //
  // <Tag> = '_'{ <NonBlankChar>}+                                         [case insensitive]
  // <Value> = { '.' | '?' | <Numeric> | <CharString> | <TextField> }      [case sensitive]
  
  func parseSymmetryEquivPos(_ xyz: String)
  {
    let trimmed: String = xyz.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    guard !trimmed.isEmpty, trimmed != "?", trimmed != "." else { return }
    cifSymmetryOperationStrings.append(trimmed)
  }
  
  func resolveSpaceGroupFromCIFSymmetryOperations()
  {
    guard !cifSymmetryOperationStrings.isEmpty else { return }
    
    do
    {
      cifSymmetryOperations = try SKCIFSymmetryOperationParser.parseOperations(cifSymmetryOperationStrings)
    }
    catch
    {
      LogQueue.shared.warning(destination: nil, message: "\(name): failed to parse CIF symmetry operations (\(error))")
      cifSymmetryOperations = []
      return
    }
    
    let declaredHallNumber: Int? = spaceGroupFound == .HallSymbolFound ? spaceGroup.spaceGroupSetting.number : nil
    let declaredHMSymbol: String? = (spaceGroupFound == .HMSymbolFound || spaceGroupFound == .HallSymbolFound) ? spaceGroup.spaceGroupSetting.HM : nil
    let candidates: [Int] = SKSpacegroup.candidateHallNumbers(spaceGroupITNumber: spaceGroupITNumber, declaredHallNumber: declaredHallNumber, declaredHMSymbol: declaredHMSymbol)
    
    guard let identifiedHallNumber: Int = SKSpacegroup.identifyHallNumber(fromCIFSymmetryOperations: cifSymmetryOperations, candidateHallNumbers: candidates) else
    {
      LogQueue.shared.warning(destination: nil, message: "\(name): CIF symmetry operations did not match any Hall setting; using operations from CIF for expansion")
      spaceGroup = SKSpacegroup(HallNumber: spaceGroup.spaceGroupSetting.number, cifSymmetryOperations: cifSymmetryOperations)
      spaceGroupFound = .CIFSymmetryOperationsFound
      return
    }
    
    if spaceGroupFound == .HallSymbolFound && identifiedHallNumber != spaceGroup.spaceGroupSetting.number
    {
      LogQueue.shared.warning(destination: nil, message: "\(name): CIF symmetry operations identify Hall \(identifiedHallNumber) instead of declared Hall \(spaceGroup.spaceGroupSetting.number)")
    }
    
    spaceGroup = SKSpacegroup(HallNumber: identifiedHallNumber, cifSymmetryOperations: cifSymmetryOperations)
    spaceGroupFound = .CIFSymmetryOperationsFound
  }
  
  
  func parseLoop()
  {
    var previousScanLocation: String.Index
    var tags: [CaseInsensitiveString] = [CaseInsensitiveString]()
    
    // part 1: read the 'tags'
    previousScanLocation = self.scanner.currentIndex
    while let keyword = self.scanner.scanCharacters(from: keywordSet), (keyword.hasPrefix("_") || (keyword.hasPrefix("#")))
    {
      if (keyword.hasPrefix("#"))
      {
        skipComment()
      }
      else if (keyword.hasPrefix("_"))
      {
        // found a tag -> add it to the tags-array
        tags.append(CaseInsensitiveString(stringLiteral: keyword))
      }
      
      previousScanLocation = self.scanner.currentIndex
    }
    
    
    // set scanner back to the first <value>
    self.scanner.currentIndex = previousScanLocation
    
    // part 2: read the values
    var value: String?
    
    repeat
    {
      var dictionary: Dictionary<CaseInsensitiveString,String> = Dictionary<CaseInsensitiveString,String>()
      for tag in tags
      {
        value =  parseValue()
        
        if (value != nil)
        {
          dictionary[tag] = value
        }
      }
      
      if (value != nil)
      {
        if let symmetryXYZ: String = dictionary["_symmetry_equiv_pos_as_xyz"] ?? dictionary["_space_group_symop_operation_xyz"]
        {
          parseSymmetryEquivPos(symmetryXYZ)
        }
        else if let chemicalSymbol: String = normalizedChemicalElement(dictionaryValue(dictionary, "_atom_site_type_symbol", "_atom_site.type_symbol"))
        {
          appendAtomSite(from: dictionary, chemicalSymbol: chemicalSymbol)
        }
        else if let monId: String = dictionaryValue(dictionary, "_entity_poly_seq.mon_id")
        {
          recordEntityPolySeq(dictionary: dictionary, monId: monId)
        }
        else if let modRes: String = dictionaryValue(dictionary, "_pdbx_struct_mod_residue.label_comp_id", "_pdbx_struct_mod_residue.auth_comp_id")
        {
          let trimmed: String = modRes.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
          if !trimmed.isEmpty
          {
            modifiedResidues.insert(trimmed)
          }
        }
        else if let asymId: String = dictionaryValue(dictionary, "_struct_asym.id"),
                let entityId: String = dictionaryValue(dictionary, "_struct_asym.entity_id")
        {
          asymToEntity[asymId] = entityId
        }
        else if let entityId: String = dictionaryValue(dictionary, "_entity_poly.entity_id"),
                let polyType: String = dictionaryValue(dictionary, "_entity_poly.type")
        {
          recordEntityPolyType(entityId: entityId, polyType: polyType)
        }
        else
        {
          
        }
      }
    } while (value != nil)
    // Note: scanner-location is restored to first word after the 'loop'
  }
  
  private func dictionaryValue(_ dictionary: Dictionary<CaseInsensitiveString, String>, _ keys: String...) -> String?
  {
    for key in keys
    {
      if let value: String = dictionary[CaseInsensitiveString(stringLiteral: key)]
      {
        let trimmed: String = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed != "?" && trimmed != "."
        {
          return trimmed
        }
      }
    }
    return nil
  }
  
  private func normalizedChemicalElement(_ symbol: String?) -> String?
  {
    guard var chemicalElement: String = symbol?.trimmingCharacters(in: .whitespacesAndNewlines), !chemicalElement.isEmpty else {return nil}
    chemicalElement = chemicalElement.trimmingCharacters(in: CharacterSet(charactersIn: "01234567890.+-"))
    guard !chemicalElement.isEmpty else {return nil}
    return chemicalElement.lowercased().capitalizeFirst
  }
  
  private func parseCIFDouble(_ string: String?) -> Double?
  {
    guard let string, !string.isEmpty else {return nil}
    let cleaned: String = string.split(separator: "(").first.map(String.init) ?? string
    let value: Double = (cleaned as NSString).doubleValue
    return value
  }
  
  private func appendAtomSite(from dictionary: Dictionary<CaseInsensitiveString, String>, chemicalSymbol: String)
  {
    numberOfAtoms += 1
    let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: "new", elementId: 0, uniqueForceFieldName: "C", position: SIMD3<Double>(0.0,0.0,0.0), charge: 0.0, color: NSColor.black, drawRadius: 1.0, bondDistanceCriteria: 1.0, occupancy: 1.0)
    
    if let groupPDB: String = dictionaryValue(dictionary, "_atom_site.group_PDB", "_atom_site.group_pdb")
    {
      atom.solvent = groupPDB.uppercased() == "HETATM"
    }
    
    if let serial: String = dictionaryValue(dictionary, "_atom_site.id")
    {
      atom.serialNumber = Int(serial) ?? 0
    }
    
    let atomName: String = dictionaryValue(dictionary, "_atom_site.label_atom_id", "_atom_site.auth_atom_id", "_atom_site_label", "_atom_site.id")
      ?? chemicalSymbol
    atom.displayName = atomName
    if atomName.count >= 3
    {
      let third: String.Index = atomName.index(atomName.startIndex, offsetBy: 2)
      atom.remotenessIndicator = atomName[third]
    }
    if atomName.count >= 4
    {
      let fourth: String.Index = atomName.index(atomName.startIndex, offsetBy: 3)
      atom.branchDesignator = atomName[fourth]
    }
    
    let residueName: String = (dictionaryValue(dictionary, "_atom_site.label_comp_id", "_atom_site.auth_comp_id") ?? "").uppercased()
    atom.residueName = residueName
    
    if let residueData: SKResidueAtomDefinition = SKElement.residueDefinitions[residueName + "+" + atomName.uppercased()]
    {
      numberOfAminoAcidAtoms += 1
      atom.backBoneAtom = SKElement.isBackboneAtomType(residueData.type)
      if let atomicNumber: Int = SKElement.atomicNumber(forSymbol: residueData.element), atomicNumber > 0
      {
        atom.elementIdentifier = atomicNumber
        atom.uniqueForceFieldName = PredefinedElements.sharedInstance.elementSet[atomicNumber].chemicalSymbol
      }
    }
    else if SKNucleotide.isNucleotideResidueName(residueName)
    {
      numberOfNucleicAcidAtoms += 1
    }
    else if SKElement.knownAminoAcidResidueCodes.contains(residueName)
    {
      numberOfAminoAcidAtoms += 1
    }
    
    if let chainString: String = dictionaryValue(dictionary, "_atom_site.label_asym_id", "_atom_site.auth_asym_id", "_atom_site.label_entity_id"),
       let chainChar: Character = chainString.first
    {
      atom.chainIdentifier = chainChar
    }
    
    if let sequenceID: String = dictionaryValue(dictionary, "_atom_site.label_seq_id", "_atom_site.auth_seq_id")
    {
      atom.residueSequenceNumber = Int(sequenceID) ?? 0
    }
    
    if let insertionCode: String = dictionaryValue(dictionary, "_atom_site.pdbx_PDB_ins_code", "_atom_site.pdbx_pdb_ins_code"),
       let first: Character = insertionCode.first
    {
      atom.codeForInsertionOfResidues = first
    }
    
    // Prefer fractional for materials/crystals; Cartesian for biomolecular mmCIF sites.
    let looksLikeProteinSite: Bool = dictionaryValue(dictionary,
                                                     "_atom_site.group_PDB",
                                                     "_atom_site.group_pdb",
                                                     "_atom_site.label_comp_id",
                                                     "_atom_site.auth_comp_id") != nil
    
    let cartnX = parseCIFDouble(dictionaryValue(dictionary, "_atom_site.Cartn_x", "_atom_site.cartn_x", "_atom_site_Cartn_x"))
    let cartnY = parseCIFDouble(dictionaryValue(dictionary, "_atom_site.Cartn_y", "_atom_site.cartn_y", "_atom_site_Cartn_y"))
    let cartnZ = parseCIFDouble(dictionaryValue(dictionary, "_atom_site.Cartn_z", "_atom_site.cartn_z", "_atom_site_Cartn_z"))
    let fractX = parseCIFDouble(dictionaryValue(dictionary, "_atom_site.fract_x", "_atom_site_fract_x"))
    let fractY = parseCIFDouble(dictionaryValue(dictionary, "_atom_site.fract_y", "_atom_site_fract_y"))
    let fractZ = parseCIFDouble(dictionaryValue(dictionary, "_atom_site.fract_z", "_atom_site_fract_z"))
    
    if looksLikeProteinSite
    {
      if let x = cartnX, let y = cartnY, let z = cartnZ
      {
        atom.position = SIMD3<Double>(x: x, y: y, z: z)
        atom.fractional = false
      }
      else if let x = fractX, let y = fractY, let z = fractZ
      {
        atom.position = SIMD3<Double>(x: x, y: y, z: z)
        atom.fractional = true
      }
    }
    else
    {
      if let x = fractX, let y = fractY, let z = fractZ
      {
        atom.position = SIMD3<Double>(x: x, y: y, z: z)
        atom.fractional = true
      }
      else if let x = cartnX, let y = cartnY, let z = cartnZ
      {
        atom.position = SIMD3<Double>(x: x, y: y, z: z)
        atom.fractional = false
      }
    }
    
    if let charge = parseCIFDouble(dictionaryValue(dictionary, "_atom_site.charge", "_atom_site_charge", "_atom_site.pdbx_formal_charge"))
    {
      atom.charge = charge
    }
    
    if let occupancy = parseCIFDouble(dictionaryValue(dictionary, "_atom_site.occupancy", "_atom_site_occupancy"))
    {
      atom.occupancy = occupancy
    }
    
    if let temperature = parseCIFDouble(dictionaryValue(dictionary,
                                                        "_atom_site.B_iso_or_equiv",
                                                        "_atom_site_B_iso_or_equiv",
                                                        "_atom_site.U_iso_or_equiv",
                                                        "_atom_site_U_iso_or_equiv"))
    {
      atom.temperaturefactor = temperature
    }
    
    if atom.elementIdentifier == 0
    {
      if let atomicNumber: Int = SKElement.atomicNumber(forSymbol: chemicalSymbol)
      {
        atom.elementIdentifier = atomicNumber
      }
      else
      {
        let stripped: String = chemicalSymbol.trimmingCharacters(in: CharacterSet(charactersIn: "01234567890.+-"))
        if let atomicNumber: Int = SKElement.atomicNumber(forSymbol: stripped)
        {
          atom.elementIdentifier = atomicNumber
        }
      }
    }
    
    // Materials CIF often stores the site label as both name and force-field type.
    if !looksLikeProteinSite
    {
      if let label: String = dictionaryValue(dictionary, "_atom_site_label", "_atom_site.label")
      {
        atom.displayName = label
      }
      atom.uniqueForceFieldName = dictionaryValue(dictionary, "_atom_site_forcefield_label", "_atom_site.forcefield_label")
        ?? atom.displayName
    }
    else
    {
      atom.uniqueForceFieldName = dictionaryValue(dictionary, "_atom_site.forcefield_label", "_atom_site_forcefield_label")
        ?? ((atom.elementIdentifier > 0) ? PredefinedElements.sharedInstance.elementSet[atom.elementIdentifier].chemicalSymbol : chemicalSymbol)
    }
    
    guard atom.elementIdentifier > 0 else {return}
    
    if SKElement.knownAminoAcidResidueCodes.contains(residueName) ||
       SKNucleotide.isNucleotideResidueName(residueName) ||
       modifiedResidues.contains(residueName)
    {
      polymerChains.insert(atom.chainIdentifier)
    }
    
    noteResidueAtom(atom)
    atoms.append(atom)
  }
  
  private func recordEntityPolySeq(dictionary: Dictionary<CaseInsensitiveString, String>, monId: String)
  {
    let residueName: String = monId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    guard !residueName.isEmpty, residueName != "?", residueName != "." else {return}
    guard SKElement.knownAminoAcidResidueCodes.contains(residueName) ||
          SKNucleotide.isNucleotideResidueName(residueName) ||
          modifiedResidues.contains(residueName) else {return}
    
    if let entityId: String = dictionaryValue(dictionary, "_entity_poly_seq.entity_id")
    {
      polymerEntityIds.insert(entityId)
      for (asym, entity) in asymToEntity where entity == entityId
      {
        if let chain: Character = asym.first
        {
          polymerChains.insert(chain)
        }
      }
    }
  }
  
  private func recordEntityPolyType(entityId: String, polyType: String)
  {
    let entity: String = entityId.trimmingCharacters(in: .whitespacesAndNewlines)
    let type: String = polyType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !entity.isEmpty else {return}
    if type.contains("polypeptide") || type.contains("polydeoxyribonucleotide") || type.contains("polyribonucleotide") || type.contains("nucleotide")
    {
      polymerEntityIds.insert(entity)
      for (asym, mappedEntity) in asymToEntity where mappedEntity == entity
      {
        if let chain: Character = asym.first
        {
          polymerChains.insert(chain)
        }
      }
    }
  }
  
  private func resolvePolymerChainsFromEntityTables()
  {
    for (asym, entity) in asymToEntity where polymerEntityIds.contains(entity)
    {
      if let chain: Character = asym.first
      {
        polymerChains.insert(chain)
      }
    }
  }
  
  private func noteResidueAtom(_ atom: SKAsymmetricAtom)
  {
    let residueName: String = atom.residueName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    guard !residueName.isEmpty else {return}
    
    let key: ResidueKey = ResidueKey(chain: atom.chainIdentifier, sequence: atom.residueSequenceNumber)
    var record: ResidueRecord = residues[key] ?? ResidueRecord()
    record.name = residueName
    if Self.isWaterResidue(residueName) {record.water = true}
    if SKNucleotide.isNucleotideResidueName(residueName) {record.nucleotide = true}
    
    let atomName: String = atom.displayName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if atomName == "N"
    {
      record.hasNitrogen = true
      record.nitrogen = atom.position
    }
    else if atomName == "CA"
    {
      record.hasAlphaCarbon = true
    }
    else if atomName == "C"
    {
      record.hasCarbonyl = true
      record.carbonyl = atom.position
    }
    residues[key] = record
  }
  
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
    
    let periodic: Bool = cellLengthsDefined && a > 1e-6 && b > 1e-6 && c > 1e-6 && !asMolecule
    
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
    if onlySolvent
    {
      return .proteinCrystalSolvent
    }
    
    if asMolecule
    {
      return .molecule
    }
    return .crystal
  }
  
}


// Core dictionary (coreCIF) version 2.4.5 definitions
extension SKCIFParser
{
  enum AtomSite: CaseInsensitiveString
  {
    case atom_site_adp_type = "_atom_site_adp_type"
    case atom_site_aniso_B_11 = "_atom_site_aniso_B_11"
    case atom_site_aniso_B_12 = "_atom_site_aniso_B_12"
    case atom_site_aniso_B_13 = "_atom_site_aniso_B_13"
    case atom_site_aniso_B_22 = "_atom_site_aniso_B_22"
    case atom_site_aniso_B_23 = "_atom_site_aniso_B_23"
    case atom_site_aniso_B_33 = "_atom_site_aniso_B_33"
    case atom_site_aniso_label = "_atom_site_aniso_label"
    case atom_site_aniso_ratio = "_atom_site_aniso_ratio"
    case atom_site_aniso_type_symbol = "_atom_site_aniso_type_symbol"
    case atom_site_aniso_U_11 = "_atom_site_aniso_U_11"
    case atom_site_aniso_U_12 = "_atom_site_aniso_U_12"
    case atom_site_aniso_U_13 = "_atom_site_aniso_U_13"
    case atom_site_aniso_U_22 = "_atom_site_aniso_U_22"
    case atom_site_aniso_U_23 = "_atom_site_aniso_U_23"
    case atom_site_aniso_U_33 = "_atom_site_aniso_U_33"
    case atom_site_attached_hydrogens = "_atom_site_attached_hydrogens"
    case atom_site_B_equiv_geom_mean = "_atom_site_B_equiv_geom_mean"
    case atom_site_B_iso_or_equiv = "_atom_site_B_iso_or_equiv"
    case atom_site_calc_attached_atom = "_atom_site_calc_attached_atom"
    case atom_site_calc_flag = "_atom_site_calc_flag"
    case atom_site_Cartn_x = "_atom_site_Cartn_x"
    case atom_site_Cartn_y = "_atom_site_Cartn_y"
    case atom_site_Cartn_z = "_atom_site_Cartn_z"
    case atom_site_chemical_conn_number = "_atom_site_chemical_conn_number"
    case atom_site_constraints = "_atom_site_constraints"
    case atom_site_description = "_atom_site_description"
    case atom_site_disorder_assembly = "_atom_site_disorder_assembly"
    case atom_site_disorder_group = "_atom_site_disorder_group"
    case atom_site_fract_x = "_atom_site_fract_x"
    case atom_site_fract_y = "_atom_site_fract_y"
    case atom_site_fract_z = "_atom_site_fract_z"
    case atom_site_label = "_atom_site_label"
    case atom_site_label_component_0 = "_atom_site_label_component_0"
    case atom_site_label_component_1 = "_atom_site_label_component_1"
    case atom_site_label_component_2 = "_atom_site_label_component_2"
    case atom_site_label_component_3 = "_atom_site_label_component_3"
    case atom_site_label_component_4 = "_atom_site_label_component_4"
    case atom_site_label_component_5 = "_atom_site_label_component_5"
    case atom_site_label_component_6 = "_atom_site_label_component_6"
    case atom_site_occupancy = "_atom_site_occupancy"
    case atom_site_refinement_flags = "_atom_site_refinement_flags"
    case atom_site_refinement_flags_adp = "_atom_site_refinement_flags_adp"
    case atom_site_refinement_flags_occupancy = "_atom_site_refinement_flags_occupancy"
    case atom_site_refinement_flags_posn = "_atom_site_refinement_flags_posn"
    case atom_site_restraints = "_atom_site_restraints"
    case atom_site_site_symmetry_multiplicity = "_atom_site_site_symmetry_multiplicity"
    case atom_site_site_symmetry_order = "_atom_site_site_symmetry_order"
    case atom_site_symmetry_multiplicity = "_atom_site_symmetry_multiplicity"
    case atom_site_thermal_displace_type = "_atom_site_thermal_displace_type"
    case atom_site_type_symbol = "_atom_site_type_symbol"
    case atom_site_U_equiv_geom_mean = "_atom_site_U_equiv_geom_mean"
    case atom_site_U_iso_or_equiv = "_atom_site_U_iso_or_equiv"
    case atom_site_Wyckoff_symbol = "_atom_site_Wyckoff_symbol"
  }
  
  enum AtomSites: CaseInsensitiveString
  {
    case atom_sites_Cartn_tran_matrix_11 = "_atom_sites_Cartn_tran_matrix_11"
    case atom_sites_Cartn_tran_matrix_12 = "_atom_sites_Cartn_tran_matrix_12"
    case atom_sites_Cartn_tran_matrix_13 = "_atom_sites_Cartn_tran_matrix_13"
    case atom_sites_Cartn_tran_matrix_21 = "_atom_sites_Cartn_tran_matrix_21"
    case atom_sites_Cartn_tran_matrix_22 = "_atom_sites_Cartn_tran_matrix_22"
    case atom_sites_Cartn_tran_matrix_23 = "_atom_sites_Cartn_tran_matrix_23"
    case atom_sites_Cartn_tran_matrix_31 = "_atom_sites_Cartn_tran_matrix_31"
    case atom_sites_Cartn_tran_matrix_32 = "_atom_sites_Cartn_tran_matrix_32"
    case atom_sites_Cartn_tran_matrix_33 = "_atom_sites_Cartn_tran_matrix_33"
    case atom_sites_Cartn_tran_vector_1 = "_atom_sites_Cartn_tran_vector_1"
    case atom_sites_Cartn_tran_vector_2 = "_atom_sites_Cartn_tran_vector_2"
    case atom_sites_Cartn_tran_vector_3 = "_atom_sites_Cartn_tran_vector_3"
    case atom_sites_Cartn_transform_axes = "_atom_sites_Cartn_transform_axes"
    case atom_sites_fract_tran_matrix_11 = "_atom_sites_fract_tran_matrix_11"
    case atom_sites_fract_tran_matrix_12 = "_atom_sites_fract_tran_matrix_12"
    case atom_sites_fract_tran_matrix_13 = "_atom_sites_fract_tran_matrix_13"
    case atom_sites_fract_tran_matrix_21 = "_atom_sites_fract_tran_matrix_21"
    case atom_sites_fract_tran_matrix_22 = "_atom_sites_fract_tran_matrix_22"
    case atom_sites_fract_tran_matrix_23 = "_atom_sites_fract_tran_matrix_23"
    case atom_sites_fract_tran_matrix_31 = "_atom_sites_fract_tran_matrix_31"
    case atom_sites_fract_tran_matrix_32 = "_atom_sites_fract_tran_matrix_32"
    case atom_sites_fract_tran_matrix_33 = "_atom_sites_fract_tran_matrix_33"
    case atom_sites_fract_tran_vector_1 = "_atom_sites_fract_tran_vector_1"
    case atom_sites_fract_tran_vector_2 = "_atom_sites_fract_tran_vector_2"
    case atom_sites_fract_tran_vector_3 = "_atom_sites_fract_tran_vector_3"
    case atom_sites_solution_primary = "_atom_sites_solution_primary"
    case atom_sites_solution_secondary = "_atom_sites_solution_secondary"
    case atom_sites_solution_hydrogens = "_atom_sites_solution_hydrogens"
    case atom_sites_special_details = "_atom_sites_special_details"
  }
  
  enum AtomType: CaseInsensitiveString
  {
    case atom_type_analytical_mass_percent = "_atom_type_analytical_mass_%"
    case atom_type_description = "_atom_type_description"
    case atom_type_number_in_cell = "_atom_type_number_in_cell"
    case atom_type_oxidation_number = "_atom_type_oxidation_number"
    case atom_type_radius_bond = "_atom_type_radius_bond"
    case atom_type_radius_contact = "_atom_type_radius_contact"
    case atom_type_scat_Cromer_Mann_a1 = "_atom_type_scat_Cromer_Mann_a1"
    case atom_type_scat_Cromer_Mann_a2 = "_atom_type_scat_Cromer_Mann_a2"
    case atom_type_scat_Cromer_Mann_a3 = "_atom_type_scat_Cromer_Mann_a3"
    case atom_type_scat_Cromer_Mann_a4 = "_atom_type_scat_Cromer_Mann_a4"
    case atom_type_scat_Cromer_Mann_b1 = "_atom_type_scat_Cromer_Mann_b1"
    case atom_type_scat_Cromer_Mann_b2 = "_atom_type_scat_Cromer_Mann_b2"
    case atom_type_scat_Cromer_Mann_b3 = "_atom_type_scat_Cromer_Mann_b3"
    case atom_type_scat_Cromer_Mann_b4 = "_atom_type_scat_Cromer_Mann_b4"
    case atom_type_scat_Cromer_Mann_c = "_atom_type_scat_Cromer_Mann_c"
    case atom_type_scat_dispersion_imag = "_atom_type_scat_dispersion_imag"
    case atom_type_scat_dispersion_real = "_atom_type_scat_dispersion_real"
    case atom_type_scat_dispersion_source = "_atom_type_scat_dispersion_source"
    case atom_type_scat_length_neutron = "_atom_type_scat_length_neutron"
    case atom_type_scat_source = "_atom_type_scat_source"
    case atom_type_scat_versus_stol_list = "_atom_type_scat_versus_stol_list"
    case atom_type_symbol = "_atom_type_symbol"
  }
  
  enum Audit: CaseInsensitiveString
  {
    case audit_block_code = "_audit_block_code"
    case audit_block_doi = "_audit_block_doi"
    case audit_creation_date = "_audit_creation_date"
    case audit_creation_method = "_audit_creation_method"
    case audit_update_record = "_audit_update_record"
  }
  
  enum AuditAuthor: CaseInsensitiveString
  {
    case audit_author_address = "_audit_author_address"
    case audit_author_name = "_audit_author_name"
  }
  
  enum  AuditConform: CaseInsensitiveString
  {
    case audit_conform_dict_location = "_audit_conform_dict_location"
    case audit_conform_dict_name = "_audit_conform_dict_name"
    case audit_conform_dict_version = "_audit_conform_dict_version"
  }
  enum AuditContactAuthor: CaseInsensitiveString
  {
    case audit_contact_author_address = "_audit_contact_author_address"
    case audit_contact_author_email = "_audit_contact_author_email"
    case audit_contact_author_fax = "_audit_contact_author_fax"
    case audit_contact_author_name = "_audit_contact_author_name"
    case audit_contact_author_phone = "_audit_contact_author_phone"
  }
  enum AuditLink: CaseInsensitiveString
  {
    case audit_link_block_code = "_audit_link_block_code"
    case audit_link_block_description = "_audit_link_block_description"
  }
  
  enum Cell: CaseInsensitiveString
  {
    case cell_angle_alpha = "_cell_angle_alpha"
    case cell_angle_beta = "_cell_angle_beta"
    case cell_angle_gamma = "_cell_angle_gamma"
    case cell_formula_units_Z = "_cell_formula_units_Z"
    case cell_length_a = "_cell_length_a"
    case cell_length_b = "_cell_length_b"
    case cell_length_c = "_cell_length_c"
    case cell_measurement_pressure = "_cell_measurement_pressure"
    case cell_measurement_radiation = "_cell_measurement_radiation"
    case cell_measurement_reflns_used = "_cell_measurement_reflns_used"
    case cell_measurement_temperature = "_cell_measurement_temperature"
    case cell_measurement_theta_max = "_cell_measurement_theta_max"
    case cell_measurement_theta_min = "_cell_measurement_theta_min"
    case cell_measurement_wavelength = "_cell_measurement_wavelength"
    case cell_reciprocal_angle_alpha = "_cell_reciprocal_angle_alpha"
    case cell_reciprocal_angle_beta = "_cell_reciprocal_angle_beta"
    case cell_reciprocal_angle_gamma = "_cell_reciprocal_angle_gamma"
    case cell_reciprocal_length_a = "_cell_reciprocal_length_a"
    case cell_reciprocal_length_b = "_cell_reciprocal_length_b"
    case cell_reciprocal_length_c = "_cell_reciprocal_length_c"
    case cell_special_details = "_cell_special_details"
    case cell_volume = "_cell_volume"
  }
  
  enum CellMeasurementRefln: CaseInsensitiveString
  {
    case cell_measurement_refln_index_h = "_cell_measurement_refln_index_h"
    case cell_measurement_refln_index_k = "_cell_measurement_refln_index_k"
    case cell_measurement_refln_index_l = "_cell_measurement_refln_index_l"
    case cell_measurement_refln_theta = "_cell_measurement_refln_theta"
  }
  
  enum Chemical: CaseInsensitiveString
  {
    case chemical_absolute_configuration = "_chemical_absolute_configuration"
    case chemical_compound_source = "_chemical_compound_source"
    case chemical_enantioexcess_bulk = "_chemical_enantioexcess_bulk"
    case chemical_enantioexcess_bulk_technique = "_chemical_enantioexcess_bulk_technique"
    case chemical_enantioexcess_crystal = "_chemical_enantioexcess_crystal"
    case chemical_enantioexcess_crystal_technique = "_chemical_enantioexcess_crystal_technique"
    case chemical_identifier_inchi = "_chemical_identifier_inchi"
    case chemical_identifier_inchi_key = "_chemical_identifier_inchi_key"
    case chemical_identifier_inchi_version = "_chemical_identifier_inchi_version"
    case chemical_melting_point = "_chemical_melting_point"
    case chemical_melting_point_gt = "_chemical_melting_point_gt"
    case chemical_melting_point_lt = "_chemical_melting_point_lt"
    case chemical_name_common = "_chemical_name_common"
    case chemical_name_mineral = "_chemical_name_mineral"
    case chemical_name_structure_type = "_chemical_name_structure_type"
    case chemical_name_systematic = "_chemical_name_systematic"
    case chemical_optical_rotation = "_chemical_optical_rotation"
    case chemical_properties_biological = "_chemical_properties_biological"
    case chemical_properties_physical = "_chemical_properties_physical"
    case chemical_temperature_decomposition = "_chemical_temperature_decomposition"
    case chemical_temperature_decomposition_gt = "_chemical_temperature_decomposition_gt"
    case chemical_temperature_decomposition_lt = "_chemical_temperature_decomposition_lt"
    case chemical_temperature_sublimation = "_chemical_temperature_sublimation"
    case chemical_temperature_sublimation_gt = "_chemical_temperature_sublimation_gt"
    case chemical_temperature_sublimation_lt = "_chemical_temperature_sublimation_lt"
  }
  
  enum ChemicalConnAtom: CaseInsensitiveString
  {
    case chemical_conn_atom_charge = "_chemical_conn_atom_charge"
    case chemical_conn_atom_display_x = "_chemical_conn_atom_display_x"
    case chemical_conn_atom_display_y = "_chemical_conn_atom_display_y"
    case chemical_conn_atom_NCA = "_chemical_conn_atom_NCA"
    case chemical_conn_atom_NH = "_chemical_conn_atom_NH"
    case chemical_conn_atom_number = "_chemical_conn_atom_number"
    case chemical_conn_atom_type_symbol = "_chemical_conn_atom_type_symbol"
  }
  
  enum ChemicalConnBond: CaseInsensitiveString
  {
    case chemical_conn_bond_atom_1 = "_chemical_conn_bond_atom_1"
    case chemical_conn_bond_atom_2 = "_chemical_conn_bond_atom_2"
    case chemical_conn_bond_type = "_chemical_conn_bond_type"
  }
  
  enum ChemicalFormula: CaseInsensitiveString
  {
    case chemical_formula_analytical = "_chemical_formula_analytical"
    case chemical_formula_iupac = "_chemical_formula_iupac"
    case chemical_formula_moiety = "_chemical_formula_moiety"
    case chemical_formula_structural = "_chemical_formula_structural"
    case chemical_formula_sum = "_chemical_formula_sum"
    case chemical_formula_weight = "_chemical_formula_weight"
    case chemical_formula_weight_meas = "_chemical_formula_weight_meas"
  }
  
  enum Citation: CaseInsensitiveString
  {
    case citation_abstract = "_citation_abstract"
    case citation_abstract_id_CAS = "_citation_abstract_id_CAS"
    case citation_book_id_ISBN = "_citation_book_id_ISBN"
    case citation_book_publisher = "_citation_book_publisher"
    case citation_book_publisher_city = "_citation_book_publisher_city"
    case citation_book_title = "_citation_book_title"
    case citation_coordinate_linkage = "_citation_coordinate_linkage"
    case citation_country = "_citation_country"
    case citation_database_id_CSD = "_citation_database_id_CSD"
    case citation_database_id_Medline = "_citation_database_id_Medline"
    case citation_doi = "_citation_doi"
    case citation_id = "_citation_id"
    case citation_journal_abbrev = "_citation_journal_abbrev"
    case citation_journal_full = "_citation_journal_full"
    case citation_journal_id_ASTM = "_citation_journal_id_ASTM"
    case citation_journal_id_CSD = "_citation_journal_id_CSD"
    case citation_journal_id_ISSN = "_citation_journal_id_ISSN"
    case citation_journal_issue = "_citation_journal_issue"
    case citation_journal_volume = "_citation_journal_volume"
    case citation_language = "_citation_language"
    case citation_page_first = "_citation_page_first"
    case citation_page_last = "_citation_page_last"
    case citation_publisher = "_citation_publisher"
    case citation_special_details = "_citation_special_details"
    case citation_title = "_citation_title"
    case citation_year = "_citation_year"
  }
  
  enum CitationAuthor: CaseInsensitiveString
  {
    case citation_author_citation_id = "_citation_author_citation_id"
    case citation_author_name = "_citation_author_name"
    case citation_author_ordinal = "_citation_author_ordinal"
  }
  
  enum CitationEditor: CaseInsensitiveString
  {
    case citation_editor_citation_id = "_citation_editor_citation_id"
    case citation_editor_name = "_citation_editor_name"
    case citation_editor_ordinal = "_citation_editor_ordinal"
  }
  
  enum Computing: CaseInsensitiveString
  {
    case computing_cell_refinement = "_computing_cell_refinement"
    case computing_data_collection = "_computing_data_collection"
    case computing_data_reduction = "_computing_data_reduction"
    case computing_molecular_graphics = "_computing_molecular_graphics"
    case computing_publication_material = "_computing_publication_material"
    case computing_structure_refinement = "_computing_structure_refinement"
    case computing_structure_solution = "_computing_structure_solution"
  }
  
  enum Database: CaseInsensitiveString
  {
    case database_code_CAS = "_database_code_CAS"
    case database_code_COD = "_database_code_COD"
    case database_code_CSD = "_database_code_CSD"
    case database_code_ICSD = "_database_code_ICSD"
    case database_code_MDF = "_database_code_MDF"
    case database_code_NBS = "_database_code_NBS"
    case database_code_PDB = "_database_code_PDB"
    case database_code_PDF = "_database_code_PDF"
    case database_code_depnum_ccdc_archive = "_database_code_depnum_ccdc_archive"
    case database_code_depnum_ccdc_fiz = "_database_code_depnum_ccdc_fiz"
    case database_code_depnum_ccdc_journal = "_database_code_depnum_ccdc_journal"
    case database_CSD_history = "_database_CSD_history"
    case database_dataset_doi = "_database_dataset_doi"
    case database_journal_ASTM = "_database_journal_ASTM"
    case database_journal_CSD = "_database_journal_CSD"
  }
  
  enum Diffrn: CaseInsensitiveString
  {
    case diffrn_ambient_environment = "_diffrn_ambient_environment"
    case diffrn_ambient_pressure = "_diffrn_ambient_pressure"
    case diffrn_ambient_pressure_gt = "_diffrn_ambient_pressure_gt"
    case diffrn_ambient_pressure_lt = "_diffrn_ambient_pressure_lt"
    case diffrn_ambient_temperature = "_diffrn_ambient_temperature"
    case diffrn_ambient_temperature_gt = "_diffrn_ambient_temperature_gt"
    case diffrn_ambient_temperature_lt = "_diffrn_ambient_temperature_lt"
    case diffrn_crystal_treatment = "_diffrn_crystal_treatment"
    case diffrn_measured_fraction_theta_full = "_diffrn_measured_fraction_theta_full"
    case diffrn_measured_fraction_theta_max = "_diffrn_measured_fraction_theta_max"
    case diffrn_special_details = "_diffrn_special_details"
    case diffrn_symmetry_description = "_diffrn_symmetry_description"
  }
  
  enum DiffrnAttenuator: CaseInsensitiveString
  {
    case diffrn_attenuator_code = "_diffrn_attenuator_code"
    case diffrn_attenuator_material = "_diffrn_attenuator_material"
    case diffrn_attenuator_scale = "_diffrn_attenuator_scale"
  }
  
  enum DiffrnDetector: CaseInsensitiveString
  {
    case diffrn_detector = "_diffrn_detector"
    case diffrn_detector_area_resol_mean = "_diffrn_detector_area_resol_mean"
    case diffrn_detector_details = "_diffrn_detector_details"
    case diffrn_detector_dtime = "_diffrn_detector_dtime"
    case diffrn_detector_type = "_diffrn_detector_type"
    case diffrn_radiation_detector = "_diffrn_radiation_detector"
    case diffrn_radiation_detector_dtime = "_diffrn_radiation_detector_dtime"
  }
  
  enum DiffrnMeasurement: CaseInsensitiveString
  {
    case diffrn_measurement_details = "_diffrn_measurement_details"
    case diffrn_measurement_device = "_diffrn_measurement_device"
    case diffrn_measurement_device_details = "_diffrn_measurement_device_details"
    case diffrn_measurement_device_type = "_diffrn_measurement_device_type"
    case diffrn_measurement_method = "_diffrn_measurement_method"
    case diffrn_measurement_specimen_support = "_diffrn_measurement_specimen_support"
  }
  
  enum DiffrnOrientMatrix: CaseInsensitiveString
  {
    case diffrn_orient_matrix_type = "_diffrn_orient_matrix_type"
    case diffrn_orient_matrix_UB_11 = "_diffrn_orient_matrix_UB_11"
    case diffrn_orient_matrix_UB_12 = "_diffrn_orient_matrix_UB_12"
    case diffrn_orient_matrix_UB_13 = "_diffrn_orient_matrix_UB_13"
    case diffrn_orient_matrix_UB_21 = "_diffrn_orient_matrix_UB_21"
    case diffrn_orient_matrix_UB_22 = "_diffrn_orient_matrix_UB_22"
    case diffrn_orient_matrix_UB_23 = "_diffrn_orient_matrix_UB_23"
    case diffrn_orient_matrix_UB_31 = "_diffrn_orient_matrix_UB_31"
    case diffrn_orient_matrix_UB_32 = "_diffrn_orient_matrix_UB_32"
    case diffrn_orient_matrix_UB_33 = "_diffrn_orient_matrix_UB_33"
  }
  
  enum DiffrnOrientRefln: CaseInsensitiveString
  {
    case diffrn_orient_refln_angle_chi = "_diffrn_orient_refln_angle_chi"
    case diffrn_orient_refln_angle_kappa = "_diffrn_orient_refln_angle_kappa"
    case diffrn_orient_refln_angle_omega = "_diffrn_orient_refln_angle_omega"
    case diffrn_orient_refln_angle_phi = "_diffrn_orient_refln_angle_phi"
    case diffrn_orient_refln_angle_psi = "_diffrn_orient_refln_angle_psi"
    case diffrn_orient_refln_angle_theta = "_diffrn_orient_refln_angle_theta"
    case diffrn_orient_refln_index_h = "_diffrn_orient_refln_index_h"
    case diffrn_orient_refln_index_k = "_diffrn_orient_refln_index_k"
    case diffrn_orient_refln_index_l = "_diffrn_orient_refln_index_l"
  }
  
  enum DiffrnRadiation: CaseInsensitiveString
  {
    case diffrn_radiation_collimation = "_diffrn_radiation_collimation"
    case diffrn_radiation_filter_edge = "_diffrn_radiation_filter_edge"
    case diffrn_radiation_inhomogeneity = "_diffrn_radiation_inhomogeneity"
    case diffrn_radiation_monochromator = "_diffrn_radiation_monochromator"
    case diffrn_radiation_polarisn_norm = "_diffrn_radiation_polarisn_norm"
    case diffrn_radiation_polarisn_ratio = "_diffrn_radiation_polarisn_ratio"
    case diffrn_radiation_probe = "_diffrn_radiation_probe"
    case diffrn_radiation_type = "_diffrn_radiation_type"
    case diffrn_radiation_xray_symbol = "_diffrn_radiation_xray_symbol"
  }
  
  enum DiffrnRadiationWavelength: CaseInsensitiveString
  {
    case diffrn_radiation_wavelength = "_diffrn_radiation_wavelength"
    case diffrn_radiation_wavelength_details = "_diffrn_radiation_wavelength_details"
    case diffrn_radiation_wavelength_determination = "_diffrn_radiation_wavelength_determination"
    case diffrn_radiation_wavelength_id = "_diffrn_radiation_wavelength_id"
    case diffrn_radiation_wavelength_wt = "_diffrn_radiation_wavelength_wt"
  }
  
  enum DiffrnRefln: CaseInsensitiveString
  {
    case diffrn_refln_angle_chi = "_diffrn_refln_angle_chi"
    case diffrn_refln_angle_kappa = "_diffrn_refln_angle_kappa"
    case diffrn_refln_angle_omega = "_diffrn_refln_angle_omega"
    case diffrn_refln_angle_phi = "_diffrn_refln_angle_phi"
    case diffrn_refln_angle_psi = "_diffrn_refln_angle_psi"
    case diffrn_refln_angle_theta = "_diffrn_refln_angle_theta"
    case diffrn_refln_attenuator_code = "_diffrn_refln_attenuator_code"
    case diffrn_refln_class_code = "_diffrn_refln_class_code"
    case diffrn_refln_counts_bg_1 = "_diffrn_refln_counts_bg_1"
    case diffrn_refln_counts_bg_2 = "_diffrn_refln_counts_bg_2"
    case diffrn_refln_counts_net = "_diffrn_refln_counts_net"
    case diffrn_refln_counts_peak = "_diffrn_refln_counts_peak"
    case diffrn_refln_counts_total = "_diffrn_refln_counts_total"
    case diffrn_refln_crystal_id = "_diffrn_refln_crystal_id"
    case diffrn_refln_detect_slit_horiz = "_diffrn_refln_detect_slit_horiz"
    case diffrn_refln_detect_slit_vert = "_diffrn_refln_detect_slit_vert"
    case diffrn_refln_elapsed_time = "_diffrn_refln_elapsed_time"
    case diffrn_refln_index_h = "_diffrn_refln_index_h"
    case diffrn_refln_index_k = "_diffrn_refln_index_k"
    case diffrn_refln_index_l = "_diffrn_refln_index_l"
    case diffrn_refln_intensity_net = "_diffrn_refln_intensity_net"
    case diffrn_refln_intensity_sigma = "_diffrn_refln_intensity_sigma"
    case diffrn_refln_intensity_u = "_diffrn_refln_intensity_u"
    case diffrn_refln_scale_group_code = "_diffrn_refln_scale_group_code"
    case diffrn_refln_scan_mode = "_diffrn_refln_scan_mode"
    case diffrn_refln_scan_mode_backgd = "_diffrn_refln_scan_mode_backgd"
    case diffrn_refln_scan_rate = "_diffrn_refln_scan_rate"
    case diffrn_refln_scan_time_backgd = "_diffrn_refln_scan_time_backgd"
    case diffrn_refln_scan_width = "_diffrn_refln_scan_width"
    case diffrn_refln_sint_divided_by_lambda = "_diffrn_refln_sint/lambda"
    case diffrn_refln_standard_code = "_diffrn_refln_standard_code"
    case diffrn_refln_wavelength = "_diffrn_refln_wavelength"
    case diffrn_refln_wavelength_id = "_diffrn_refln_wavelength_id"
  }
  
  enum DiffrnReflns: CaseInsensitiveString
  {
    case diffrn_reflns_av_R_equivalents = "_diffrn_reflns_av_R_equivalents"
    case diffrn_reflns_av_sigmaI_divided_by_netI = "_diffrn_reflns_av_sigmaI/netI"
    case diffrn_reflns_av_unetI_divided_by_netI = "_diffrn_reflns_av_unetI/netI"
    case diffrn_reflns_Laue_measured_fraction_full = "_diffrn_reflns_Laue_measured_fraction_full"
    case diffrn_reflns_Laue_measured_fraction_max = "_diffrn_reflns_Laue_measured_fraction_max"
    case diffrn_reflns_limit_h_max = "_diffrn_reflns_limit_h_max"
    case diffrn_reflns_limit_h_min = "_diffrn_reflns_limit_h_min"
    case diffrn_reflns_limit_k_max = "_diffrn_reflns_limit_k_max"
    case diffrn_reflns_limit_k_min = "_diffrn_reflns_limit_k_min"
    case diffrn_reflns_limit_l_max = "_diffrn_reflns_limit_l_max"
    case diffrn_reflns_limit_l_min = "_diffrn_reflns_limit_l_min"
    case diffrn_reflns_number = "_diffrn_reflns_number"
    case diffrn_reflns_point_group_measured_fraction_full = "_diffrn_reflns_point_group_measured_fraction_full"
    case diffrn_reflns_point_group_measured_fraction_max = "_diffrn_reflns_point_group_measured_fraction_max"
    case diffrn_reflns_reduction_process = "_diffrn_reflns_reduction_process"
    case diffrn_reflns_resolution_full = "_diffrn_reflns_resolution_full"
    case diffrn_reflns_resolution_max = "_diffrn_reflns_resolution_max"
    case diffrn_reflns_theta_full = "_diffrn_reflns_theta_full"
    case diffrn_reflns_theta_max = "_diffrn_reflns_theta_max"
    case diffrn_reflns_theta_min = "_diffrn_reflns_theta_min"
    case diffrn_reflns_transf_matrix_11 = "_diffrn_reflns_transf_matrix_11"
    case diffrn_reflns_transf_matrix_12 = "_diffrn_reflns_transf_matrix_12"
    case diffrn_reflns_transf_matrix_13 = "_diffrn_reflns_transf_matrix_13"
    case diffrn_reflns_transf_matrix_21 = "_diffrn_reflns_transf_matrix_21"
    case diffrn_reflns_transf_matrix_22 = "_diffrn_reflns_transf_matrix_22"
    case diffrn_reflns_transf_matrix_23 = "_diffrn_reflns_transf_matrix_23"
    case diffrn_reflns_transf_matrix_31 = "_diffrn_reflns_transf_matrix_31"
    case diffrn_reflns_transf_matrix_32 = "_diffrn_reflns_transf_matrix_32"
    case diffrn_reflns_transf_matrix_33 = "_diffrn_reflns_transf_matrix_33"
  }
  
  enum DiffrnReflnsClass: CaseInsensitiveString
  {
    case diffrn_reflns_class_av_R_eq = "_diffrn_reflns_class_av_R_eq"
    case diffrn_reflns_class_av_sgI_divided_by_I = "_diffrn_reflns_class_av_sgI/I"
    case diffrn_reflns_class_av_uI_divided_by_I = "_diffrn_reflns_class_av_uI/I"
    case diffrn_reflns_class_code = "_diffrn_reflns_class_code"
    case diffrn_reflns_class_d_res_high = "_diffrn_reflns_class_d_res_high"
    case diffrn_reflns_class_d_res_low = "_diffrn_reflns_class_d_res_low"
    case diffrn_reflns_class_description = "_diffrn_reflns_class_description"
    case diffrn_reflns_class_number = "_diffrn_reflns_class_number"
  }
  
  enum DiffrnScaleGroup: CaseInsensitiveString
  {
    case diffrn_scale_group_code = "_diffrn_scale_group_code"
    case diffrn_scale_group_I_net = "_diffrn_scale_group_I_net"
  }
  enum DiffrnSource: CaseInsensitiveString
  {
    case diffrn_radiation_source = "_diffrn_radiation_source"
    case diffrn_source = "_diffrn_source"
    case diffrn_source_current = "_diffrn_source_current"
    case diffrn_source_details = "_diffrn_source_details"
    case diffrn_source_power = "_diffrn_source_power"
    case diffrn_source_size = "_diffrn_source_size"
    case diffrn_source_take_off_angle = "_diffrn_source_take-off_angle"
    case diffrn_source_target = "_diffrn_source_target"
    case diffrn_source_type = "_diffrn_source_type"
    case diffrn_source_voltage = "_diffrn_source_voltage"
  }
  
  enum DiffrnStandardRefln: CaseInsensitiveString
  {
    case diffrn_standard_refln_code = "_diffrn_standard_refln_code"
    case diffrn_standard_refln_index_h = "_diffrn_standard_refln_index_h"
    case diffrn_standard_refln_index_k = "_diffrn_standard_refln_index_k"
    case diffrn_standard_refln_index_l = "_diffrn_standard_refln_index_l"
  }
  
  enum DiffrnStandards: CaseInsensitiveString
  {
    case diffrn_standards_decay_percentage = "_diffrn_standards_decay_%"
    case diffrn_standards_interval_count = "_diffrn_standards_interval_count"
    case diffrn_standards_interval_time = "_diffrn_standards_interval_time"
    case diffrn_standards_number = "_diffrn_standards_number"
    case diffrn_standards_scale_sigma = "_diffrn_standards_scale_sigma"
    case diffrn_standards_scale_u = "_diffrn_standards_scale_u"
  }
  
  enum Exptl: CaseInsensitiveString
  {
    case exptl_absorpt_coefficient_mu = "_exptl_absorpt_coefficient_mu"
    case exptl_absorpt_correction_T_max = "_exptl_absorpt_correction_T_max"
    case xptl_absorpt_correction_T_min = "_exptl_absorpt_correction_T_min"
    case exptl_absorpt_correction_type = "_exptl_absorpt_correction_type"
    case exptl_absorpt_process_details = "_exptl_absorpt_process_details"
    case exptl_crystals_number = "_exptl_crystals_number"
    case exptl_special_details = "_exptl_special_details"
    case exptl_transmission_factor_max = "_exptl_transmission_factor_max"
    case exptl_transmission_factor_min = "_exptl_transmission_factor_min"
  }
  
  enum ExptlCrystal: CaseInsensitiveString
  {
    case exptl_crystal_colour = "_exptl_crystal_colour"
    case exptl_crystal_colour_lustre = "_exptl_crystal_colour_lustre"
    case exptl_crystal_colour_modifier = "_exptl_crystal_colour_modifier"
    case exptl_crystal_colour_primary = "_exptl_crystal_colour_primary"
    case exptl_crystal_density_diffrn = "_exptl_crystal_density_diffrn"
    case exptl_crystal_density_meas = "_exptl_crystal_density_meas"
    case exptl_crystal_density_meas_gt = "_exptl_crystal_density_meas_gt"
    case exptl_crystal_density_meas_lt = "_exptl_crystal_density_meas_lt"
    case exptl_crystal_density_meas_temp = "_exptl_crystal_density_meas_temp"
    case exptl_crystal_density_meas_temp_gt = "_exptl_crystal_density_meas_temp_gt"
    case exptl_crystal_density_meas_temp_lt = "_exptl_crystal_density_meas_temp_lt"
    case exptl_crystal_density_method = "_exptl_crystal_density_method"
    case exptl_crystal_description = "_exptl_crystal_description"
    case exptl_crystal_F_000 = "_exptl_crystal_F_000"
    case exptl_crystal_id = "_exptl_crystal_id"
    case exptl_crystal_preparation = "_exptl_crystal_preparation"
    case exptl_crystal_pressure_history = "_exptl_crystal_pressure_history"
    case exptl_crystal_recrystallization_method = "_exptl_crystal_recrystallization_method"
    case exptl_crystal_size_length = "_exptl_crystal_size_length"
    case exptl_crystal_size_max = "_exptl_crystal_size_max"
    case exptl_crystal_size_mid = "_exptl_crystal_size_mid"
    case exptl_crystal_size_min = "_exptl_crystal_size_min"
    case exptl_crystal_size_rad = "_exptl_crystal_size_rad"
    case exptl_crystal_thermal_history = "_exptl_crystal_thermal_history"
  }
  
  enum ExptlCrystalFace: CaseInsensitiveString
  {
    case _exptl_crystal_face_diffr_chi = "_exptl_crystal_face_diffr_chi"
    case _exptl_crystal_face_diffr_kappa = "_exptl_crystal_face_diffr_kappa"
    case _exptl_crystal_face_diffr_phi = "_exptl_crystal_face_diffr_phi"
    case _exptl_crystal_face_diffr_psi = "_exptl_crystal_face_diffr_psi"
    case _exptl_crystal_face_index_h = "_exptl_crystal_face_index_h"
    case _exptl_crystal_face_index_k = "_exptl_crystal_face_index_k"
    case _exptl_crystal_face_index_l = "_exptl_crystal_face_index_l"
    case _exptl_crystal_face_perp_dist = "_exptl_crystal_face_perp_dist"
  }
  
  enum Geom: CaseInsensitiveString
  {
    case geom_special_details = "_geom_special_details"
  }
  
  enum GeomAngle: CaseInsensitiveString
  {
    case geom_angle = "_geom_angle"
    case geom_angle_atom_site_label_1 = "_geom_angle_atom_site_label_1"
    case geom_angle_atom_site_label_2 = "_geom_angle_atom_site_label_2"
    case geom_angle_atom_site_label_3 = "_geom_angle_atom_site_label_3"
    case geom_angle_publ_flag = "_geom_angle_publ_flag"
    case geom_angle_site_symmetry_1 = "_geom_angle_site_symmetry_1"
    case geom_angle_site_symmetry_2 = "_geom_angle_site_symmetry_2"
    case geom_angle_site_symmetry_3 = "_geom_angle_site_symmetry_3"
  }
  
  enum GeomBond: CaseInsensitiveString
  {
    case geom_bond_atom_site_label_1 = "_geom_bond_atom_site_label_1"
    case geom_bond_atom_site_label_2 = "_geom_bond_atom_site_label_2"
    case geom_bond_distance = "_geom_bond_distance"
    case geom_bond_multiplicity = "_geom_bond_multiplicity"
    case geom_bond_publ_flag = "_geom_bond_publ_flag"
    case geom_bond_site_symmetry_1 = "_geom_bond_site_symmetry_1"
    case geom_bond_site_symmetry_2 = "_geom_bond_site_symmetry_2"
    case geom_bond_valence = "_geom_bond_valence"
  }
  
  enum GeomContact: CaseInsensitiveString
  {
    case geom_contact_atom_site_label_1 = "_geom_contact_atom_site_label_1"
    case geom_contact_atom_site_label_2 = "_geom_contact_atom_site_label_2"
    case geom_contact_distance = "_geom_contact_distance"
    case geom_contact_publ_flag = "_geom_contact_publ_flag"
    case geom_contact_site_symmetry_1 = "_geom_contact_site_symmetry_1"
    case geom_contact_site_symmetry_2 = "_geom_contact_site_symmetry_2"
  }
  
  enum GeomHbond: CaseInsensitiveString
  {
    case geom_hbond_angle_DHA = "_geom_hbond_angle_DHA"
    case geom_hbond_atom_site_label_D = "_geom_hbond_atom_site_label_D"
    case geom_hbond_atom_site_label_H = "_geom_hbond_atom_site_label_H"
    case geom_hbond_atom_site_label_A = "_geom_hbond_atom_site_label_A"
    case geom_hbond_distance_DH = "_geom_hbond_distance_DH"
    case geom_hbond_distance_HA = "_geom_hbond_distance_HA"
    case geom_hbond_distance_DA = "_geom_hbond_distance_DA"
    case geom_hbond_publ_flag = "_geom_hbond_publ_flag"
    case geom_hbond_site_symmetry_D = "_geom_hbond_site_symmetry_D"
    case geom_hbond_site_symmetry_H = "_geom_hbond_site_symmetry_H"
    case geom_hbond_site_symmetry_A = "_geom_hbond_site_symmetry_A"
  }
  
  enum GeomTorsion: CaseInsensitiveString
  {
    case geom_torsion = "_geom_torsion"
    case geom_torsion_atom_site_label_1 = "_geom_torsion_atom_site_label_1"
    case geom_torsion_atom_site_label_2 = "_geom_torsion_atom_site_label_2"
    case geom_torsion_atom_site_label_3 = "_geom_torsion_atom_site_label_3"
    case geom_torsion_atom_site_label_4 = "_geom_torsion_atom_site_label_4"
    case geom_torsion_publ_flag = "_geom_torsion_publ_flag"
    case geom_torsion_site_symmetry_1 = "_geom_torsion_site_symmetry_1"
    case geom_torsion_site_symmetry_2 = "_geom_torsion_site_symmetry_2"
    case geom_torsion_site_symmetry_3 = "_geom_torsion_site_symmetry_3"
    case geom_torsion_site_symmetry_4 = "_geom_torsion_site_symmetry_4"
  }
  
  enum Journal: CaseInsensitiveString
  {
    case journal_coden_ASTM = "_journal_coden_ASTM"
    case journal_coden_Cambridge = "_journal_coden_Cambridge"
    case journal_coeditor_address = "_journal_coeditor_address"
    case journal_coeditor_code = "_journal_coeditor_code"
    case journal_coeditor_email = "_journal_coeditor_email"
    case journal_coeditor_fax = "_journal_coeditor_fax"
    case journal_coeditor_name = "_journal_coeditor_name"
    case journal_coeditor_notes = "_journal_coeditor_notes"
    case journal_coeditor_phone = "_journal_coeditor_phone"
    case journal_data_validation_number = "_journal_data_validation_number"
    case journal_date_accepted = "_journal_date_accepted"
    case journal_date_from_coeditor = "_journal_date_from_coeditor"
    case journal_date_to_coeditor = "_journal_date_to_coeditor"
    case journal_date_printers_final = "_journal_date_printers_final"
    case journal_date_printers_first = "_journal_date_printers_first"
    case journal_date_proofs_in = "_journal_date_proofs_in"
    case journal_date_proofs_out = "_journal_date_proofs_out"
    case journal_date_recd_copyright = "_journal_date_recd_copyright"
    case journal_date_recd_electronic = "_journal_date_recd_electronic"
    case journal_date_recd_hard_copy = "_journal_date_recd_hard_copy"
    case journal_issue = "_journal_issue"
    case journal_language = "_journal_language"
    case journal_name_full = "_journal_name_full"
    case journal_page_first = "_journal_page_first"
    case journal_page_last = "_journal_page_last"
    case journal_paper_category = "_journal_paper_category"
    case journal_paper_doi = "_journal_paper_doi"
    case journal_suppl_publ_number = "_journal_suppl_publ_number"
    case journal_suppl_publ_pages = "_journal_suppl_publ_pages"
    case journal_techeditor_address = "_journal_techeditor_address"
    case journal_techeditor_code = "_journal_techeditor_code"
    case journal_techeditor_email = "_journal_techeditor_email"
    case journal_techeditor_fax = "_journal_techeditor_fax"
    case journal_techeditor_name = "_journal_techeditor_name"
    case journal_techeditor_notes = "_journal_techeditor_notes"
    case journal_techeditor_phone = "_journal_techeditor_phone"
    case journal_volume = "_journal_volume"
    case journal_year = "_journal_year"
  }
  
  enum JournalIndex: CaseInsensitiveString
  {
    case journal_index_subterm = "_journal_index_subterm"
    case journal_index_term = "_journal_index_term"
    case journal_index_type = "_journal_index_type"
  }
  
  enum Publ: CaseInsensitiveString
  {
    case publ_contact_author = "_publ_contact_author"
    case publ_contact_author_address = "_publ_contact_author_address"
    case publ_contact_author_email = "_publ_contact_author_email"
    case publ_contact_author_fax = "_publ_contact_author_fax"
    case publ_contact_author_id_iucr = "_publ_contact_author_id_iucr"
    case publ_contact_author_id_orcid = "_publ_contact_author_id_orcid"
    case publ_contact_author_name = "_publ_contact_author_name"
    case publ_contact_author_phone = "_publ_contact_author_phone"
    case publ_contact_letter = "_publ_contact_letter"
    case publ_manuscript_creation = "_publ_manuscript_creation"
    case publ_manuscript_processed = "_publ_manuscript_processed"
    case publ_manuscript_text = "_publ_manuscript_text"
    case publ_requested_category = "_publ_requested_category"
    case publ_requested_coeditor_name = "_publ_requested_coeditor_name"
    case publ_requested_journal = "_publ_requested_journal"
    case publ_section_title = "_publ_section_title"
    case publ_section_title_footnote = "_publ_section_title_footnote"
    case publ_section_synopsis = "_publ_section_synopsis"
    case publ_section_abstract = "_publ_section_abstract"
    case publ_section_comment = "_publ_section_comment"
    case publ_section_introduction = "_publ_section_introduction"
    case publ_section_experimental = "_publ_section_experimental"
    case publ_section_exptl_prep = "_publ_section_exptl_prep"
    case publ_section_exptl_refinement = "_publ_section_exptl_refinement"
    case publ_section_exptl_solution = "_publ_section_exptl_solution"
    case publ_section_discussion = "_publ_section_discussion"
    case publ_section_acknowledgements = "_publ_section_acknowledgements"
    case publ_section_references = "_publ_section_references"
    case publ_section_related_literature = "_publ_section_related_literature"
    case publ_section_figure_captions = "_publ_section_figure_captions"
    case publ_section_table_legends = "_publ_section_table_legends"
    case publ_section_keywords = "_publ_section_keywords"
  }
  
  enum PublAuthor: CaseInsensitiveString
  {
    case publ_author_address = "_publ_author_address"
    case publ_author_email = "_publ_author_email"
    case publ_author_footnote = "_publ_author_footnote"
    case publ_author_id_iucr = "_publ_author_id_iucr"
    case publ_author_id_orcid = "_publ_author_id_orcid"
    case publ_author_name = "_publ_author_name"
  }
  
  enum PublBody: CaseInsensitiveString
  {
    case publ_body_contents = "_publ_body_contents"
    case publ_body_element = "_publ_body_element"
    case publ_body_format = "_publ_body_format"
    case publ_body_label = "_publ_body_label"
    case publ_body_title = "_publ_body_title"
  }
  
  enum PublManuscriptIncl: CaseInsensitiveString
  {
    case publ_manuscript_incl_extra_defn = "_publ_manuscript_incl_extra_defn"
    case publ_manuscript_incl_extra_info = "_publ_manuscript_incl_extra_info"
    case publ_manuscript_incl_extra_item = "_publ_manuscript_incl_extra_item"
  }
  
  enum Refine: CaseInsensitiveString
  {
    case refine_diff_density_max = "_refine_diff_density_max"
    case refine_diff_density_min = "_refine_diff_density_min"
    case refine_diff_density_rms = "_refine_diff_density_rms"
    case refine_ls_abs_structure_details = "_refine_ls_abs_structure_details"
    case refine_ls_abs_structure_Flack = "_refine_ls_abs_structure_Flack"
    case refine_ls_abs_structure_Rogers = "_refine_ls_abs_structure_Rogers"
    case refine_ls_d_res_high = "_refine_ls_d_res_high"
    case refine_ls_d_res_low = "_refine_ls_d_res_low"
    case refine_ls_extinction_coef = "_refine_ls_extinction_coef"
    case refine_ls_extinction_expression = "_refine_ls_extinction_expression"
    case refine_ls_extinction_method = "_refine_ls_extinction_method"
    case refine_ls_F_calc_details = "_refine_ls_F_calc_details"
    case refine_ls_F_calc_formula = "_refine_ls_F_calc_formula"
    case refine_ls_F_calc_precision = "_refine_ls_F_calc_precision"
    case refine_ls_goodness_of_fit_all = "_refine_ls_goodness_of_fit_all"
    case refine_ls_goodness_of_fit_gt = "_refine_ls_goodness_of_fit_gt"
    case refine_ls_goodness_of_fit_obs = "_refine_ls_goodness_of_fit_obs"
    case refine_ls_goodness_of_fit_ref = "_refine_ls_goodness_of_fit_ref"
    case refine_ls_hydrogen_treatment = "_refine_ls_hydrogen_treatment"
    case refine_ls_matrix_type = "_refine_ls_matrix_type"
    case refine_ls_number_constraints = "_refine_ls_number_constraints"
    case refine_ls_number_parameters = "_refine_ls_number_parameters"
    case refine_ls_number_reflns = "_refine_ls_number_reflns"
    case refine_ls_number_restraints = "_refine_ls_number_restraints"
    case refine_ls_R_factor_all = "_refine_ls_R_factor_all"
    case refine_ls_R_factor_gt = "_refine_ls_R_factor_gt"
    case refine_ls_R_factor_obs = "_refine_ls_R_factor_obs"
    case refine_ls_R_Fsqd_factor = "_refine_ls_R_Fsqd_factor"
    case refine_ls_R_I_factor = "_refine_ls_R_I_factor"
    case refine_ls_restrained_S_all = "_refine_ls_restrained_S_all"
    case refine_ls_restrained_S_gt = "_refine_ls_restrained_S_gt"
    case refine_ls_restrained_S_obs = "_refine_ls_restrained_S_obs"
    case refine_ls_shift_divided_by_esd_max = "_refine_ls_shift/esd_max"
    case refine_ls_shift_divided_by_esd_mean = "_refine_ls_shift/esd_mean"
    case refine_ls_shift_divided_by_su_max = "_refine_ls_shift/su_max"
    case refine_ls_shift_divided_by_su_max_lt = "_refine_ls_shift/su_max_lt"
    case refine_ls_shift_divided_by_su_mean = "_refine_ls_shift/su_mean"
    case refine_ls_shift_divided_by_su_mean_lt = "_refine_ls_shift/su_mean_lt"
    case refine_ls_structure_factor_coef = "_refine_ls_structure_factor_coef"
    case refine_ls_weighting_details = "_refine_ls_weighting_details"
    case refine_ls_weighting_scheme = "_refine_ls_weighting_scheme"
    case refine_ls_wR_factor_all = "_refine_ls_wR_factor_all"
    case refine_ls_wR_factor_gt = "_refine_ls_wR_factor_gt"
    case refine_ls_wR_factor_obs = "_refine_ls_wR_factor_obs"
    case refine_ls_wR_factor_ref = "_refine_ls_wR_factor_ref"
    case refine_special_details = "_refine_special_details"
  }
  
  enum RefineLsClass: CaseInsensitiveString
  {
    case refine_ls_class_code = "_refine_ls_class_code"
    case refine_ls_class_d_res_high = "_refine_ls_class_d_res_high"
    case refine_ls_class_d_res_low = "_refine_ls_class_d_res_low"
    case refine_ls_class_R_factor_all = "_refine_ls_class_R_factor_all"
    case refine_ls_class_R_factor_gt = "_refine_ls_class_R_factor_gt"
    case refine_ls_class_R_Fsqd_factor = "_refine_ls_class_R_Fsqd_factor"
    case refine_ls_class_R_I_factor = "_refine_ls_class_R_I_factor"
    case refine_ls_class_wR_factor_all = "_refine_ls_class_wR_factor_all"
  }
  
  enum Reflns: CaseInsensitiveString
  {
    case reflns_d_resolution_high = "_reflns_d_resolution_high"
    case reflns_d_resolution_low = "_reflns_d_resolution_low"
    case reflns_Friedel_coverage = "_reflns_Friedel_coverage"
    case reflns_Friedel_fraction_full = "_reflns_Friedel_fraction_full"
    case reflns_Friedel_fraction_max = "_reflns_Friedel_fraction_max"
    case reflns_limit_h_max = "_reflns_limit_h_max"
    case reflns_limit_h_min = "_reflns_limit_h_min"
    case reflns_limit_k_max = "_reflns_limit_k_max"
    case reflns_limit_k_min = "_reflns_limit_k_min"
    case reflns_limit_l_max = "_reflns_limit_l_max"
    case reflns_limit_l_min = "_reflns_limit_l_min"
    case reflns_number_gt = "_reflns_number_gt"
    case reflns_number_observed = "_reflns_number_observed"
    case reflns_number_total = "_reflns_number_total"
    case reflns_observed_criterion = "_reflns_observed_criterion"
    case reflns_special_details = "_reflns_special_details"
    case reflns_threshold_expression = "_reflns_threshold_expression"
  }
  
  enum ReflnsClass: CaseInsensitiveString
  {
    case reflns_class_code = "_reflns_class_code"
    case reflns_class_d_res_high = "_reflns_class_d_res_high"
    case reflns_class_d_res_low = "_reflns_class_d_res_low"
    case reflns_class_description = "_reflns_class_description"
    case reflns_class_number_gt = "_reflns_class_number_gt"
    case reflns_class_number_total = "_reflns_class_number_total"
    case reflns_class_R_factor_all = "_reflns_class_R_factor_all"
    case reflns_class_R_factor_gt = "_reflns_class_R_factor_gt"
    case reflns_class_R_Fsqd_factor = "_reflns_class_R_Fsqd_factor"
    case reflns_class_R_I_factor = "_reflns_class_R_I_factor"
    case reflns_class_wR_factor_all = "_reflns_class_wR_factor_all"
  }
  
  enum ReflnsScale: CaseInsensitiveString
  {
    case reflns_scale_group_code = "_reflns_scale_group_code"
    case reflns_scale_meas_F = "_reflns_scale_meas_F"
    case reflns_scale_meas_F_squared = "_reflns_scale_meas_F_squared"
    case reflns_scale_meas_intensity = "_reflns_scale_meas_intensity"
  }
  
  enum ReflnsShell: CaseInsensitiveString
  {
    case reflns_shell_d_res_high = "_reflns_shell_d_res_high"
    case reflns_shell_d_res_low = "_reflns_shell_d_res_low"
    case reflns_shell_meanI_over_sigI_all = "_reflns_shell_meanI_over_sigI_all"
    case reflns_shell_meanI_over_sigI_gt = "_reflns_shell_meanI_over_sigI_gt"
    case reflns_shell_meanI_over_sigI_obs = "_reflns_shell_meanI_over_sigI_obs"
    case reflns_shell_meanI_over_uI_all = "_reflns_shell_meanI_over_uI_all"
    case reflns_shell_meanI_over_uI_gt = "_reflns_shell_meanI_over_uI_gt"
    case reflns_shell_number_measured_all = "_reflns_shell_number_measured_all"
    case reflns_shell_number_measured_gt = "_reflns_shell_number_measured_gt"
    case reflns_shell_number_measured_obs = "_reflns_shell_number_measured_obs"
    case reflns_shell_number_possible = "_reflns_shell_number_possible"
    case reflns_shell_number_unique_all = "_reflns_shell_number_unique_all"
    case reflns_shell_number_unique_gt = "_reflns_shell_number_unique_gt"
    case reflns_shell_number_unique_obs = "_reflns_shell_number_unique_obs"
    case reflns_shell_percent_possible_all = "_reflns_shell_percent_possible_all"
    case reflns_shell_percent_possible_gt = "_reflns_shell_percent_possible_gt"
    case reflns_shell_percent_possible_obs = "_reflns_shell_percent_possible_obs"
    case reflns_shell_Rmerge_F_all = "_reflns_shell_Rmerge_F_all"
    case reflns_shell_Rmerge_F_gt = "_reflns_shell_Rmerge_F_gt"
    case reflns_shell_Rmerge_F_obs = "_reflns_shell_Rmerge_F_obs"
    case reflns_shell_Rmerge_I_all = "_reflns_shell_Rmerge_I_all"
    case reflns_shell_Rmerge_I_gt = "_reflns_shell_Rmerge_I_gt"
    case reflns_shell_Rmerge_I_obs = "_reflns_shell_Rmerge_I_obs"
  }
  
  enum SpaceGroup: CaseInsensitiveString
  {
    case space_group_crystal_system = "_space_group_crystal_system"
    case space_group_id = "_space_group_id"
    case space_group_IT_number = "_space_group_IT_number"
    case space_group_name_H_M_alt = "_space_group_name_H-M_alt"
    case space_group_name_Hall = "_space_group_name_Hall"
  }
  
  enum SpaceGroupSymop: CaseInsensitiveString
  {
    case space_group_symop_id = "_space_group_symop_id"
    case space_group_symop_operation_xyz = "_space_group_symop_operation_xyz"
    case space_group_symop_sg_id = "_space_group_symop_sg_id"
  }
  
  enum Symmetry: CaseInsensitiveString
  {
    case symmetry_cell_setting = "_symmetry_cell_setting"
    case symmetry_Int_Tables_number = "_symmetry_Int_Tables_number"
    case symmetry_space_group_name_H_M = "_symmetry_space_group_name_H-M"
    case symmetry_space_group_name_Hall = "_symmetry_space_group_name_Hall"
  }
  
  enum SymmetryEquiv: String
  {
    case symmetry_equiv_pos_as_xyz = "_symmetry_equiv_pos_as_xyz"
    case symmetry_equiv_pos_site_id = "_symmetry_equiv_pos_site_id"
  }
  
  enum ValenceParam: CaseInsensitiveString
  {
    case valence_param_atom_1 = "_valence_param_atom_1"
    case valence_param_atom_1_valence = "_valence_param_atom_1_valence"
    case valence_param_atom_2 = "_valence_param_atom_2"
    case valence_param_atom_2_valence = "_valence_param_atom_2_valence"
    case valence_param_B = "_valence_param_B"
    case valence_param_details = "_valence_param_details"
    case valence_param_id = "_valence_param_id"
    case valence_param_ref_id = "_valence_param_ref_id"
    case valence_param_Ro = "_valence_param_Ro"
  }
  
  enum ValenceRef: CaseInsensitiveString
  {
    case valence_ref_id = "_valence_ref_id"
    case valence_ref_reference = "_valence_ref_reference"
  }
}
