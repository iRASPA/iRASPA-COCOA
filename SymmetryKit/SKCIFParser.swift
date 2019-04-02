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

import Cocoa
import simd
import LogViewKit


public final class SKCIFParser: SKParser, ProgressReporting
{
  weak var windowController: NSWindowController? = nil
  var onlyAsymmetricUnit: Bool
  var a: Double = 0.0
  var b: Double = 0.0
  var c: Double = 0.0
  var alpha: Double = 90.0
  var beta: Double = 90.0
  var gamma: Double = 90.0
  var cellFormulaUnitsZ: Int = 0
  var scanner: Scanner
  let letterSet: CharacterSet
  let nonLetterSet: CharacterSet
  let whiteSpacesAndNewlines: CharacterSet
  let keywordSet: CharacterSet
  let newLineChararterSet: CharacterSet
  let letters = CharacterSet.letters
  let digits = CharacterSet.decimalDigits
  
  var atoms: [SKAsymmetricAtom] = []
  var solvent: [SKAsymmetricAtom] = []
  var numberOfAminoAcidAtoms: Int = 0
  
  enum SpaceGroupStatus: Int
  {
    case notFound = 0
    case HallSymbolFound = 1
    case HMSymbolFound = 2
    case NumberFound = 3
  }
  
  var spaceGroupFound: SpaceGroupStatus = .notFound
  var spaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: 1)
  
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
  var currentSolventMovie: Int = 1
  
  var currentFrame: Int = 0
  
  public var progress: Progress
  
  
  //unowned var ProjectTreeNode : ProjectTreeNode
  
  func checkForComment() -> Bool
  {
    let _: Int = self.scanner.scanLocation
    return true
  }
  
  
  public init(displayName: String, string: String, windowController: NSWindowController?, onlyAsymmetricUnit: Bool = false)
  {
    //self.ProjectTreeNode = ProjectTreeNode
    self.name = displayName
    self.windowController = windowController
    self.onlyAsymmetricUnit = onlyAsymmetricUnit
    
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
    var tempstring: NSString? = nil
    
    // define 1 steps
    progress.totalUnitCount = 1
    
    LogQueue.shared.verbose(destination: windowController, message: "start reading CIF-file: \(name)")
    
    
    
   
    
    
    while(!scanner.isAtEnd)
    {
      // scan to first keyword
      let previousScanLocation: Int = self.scanner.scanLocation
      scanner.scanCharacters(from: keywordSet,into: &tempstring)
      
      if let keyword: String = tempstring?.lowercased as String?
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
          self.scanner.scanLocation = previousScanLocation
          skipComment()
        }
      }
    }
    
    // post-reading
    //=============
    
    scene.append([SKStructure()])
    
    let cell: SKCell = SKCell(a: a, b: b, c: c, alpha: alpha*Double.pi/180.0, beta: beta*Double.pi/180.0, gamma: gamma*Double.pi/180.0)
    
    if (Double(numberOfAminoAcidAtoms)/(Double)(atoms.count)) > 0.5
    {
      scene[currentMovie][currentFrame].kind = .proteinCrystal
      scene[currentMovie][currentFrame].drawUnitCell = !onlyAsymmetricUnit
    }
    else
    {
      scene[currentMovie][currentFrame].kind = .crystal
      scene[currentMovie][currentFrame].drawUnitCell = true
    }
    
    scene[currentMovie][currentFrame].displayName = self.name
    scene[currentMovie][currentFrame].spaceGroupHallNumber = onlyAsymmetricUnit ? 1 : self.spaceGroup.spaceGroupSetting.number
    scene[currentMovie][currentFrame].cell = cell
    scene[currentMovie][currentFrame].periodic = true
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
    
    // write possible solvent atoms to a second movie
    if solvent.count > 0
    {
      scene.append([SKStructure()])
      
      if (Double(numberOfAminoAcidAtoms)/(Double)(atoms.count)) > 0.5
      {
        scene[currentSolventMovie][currentFrame].kind = .proteinCrystalSolvent
        scene[currentSolventMovie][currentFrame].drawUnitCell = !onlyAsymmetricUnit
      }
      else
      {
        scene[currentSolventMovie][currentFrame].kind = .crystalSolvent
        scene[currentSolventMovie][currentFrame].drawUnitCell = true
      }
    
      scene[currentSolventMovie][currentFrame].displayName = self.name
      scene[currentSolventMovie][currentFrame].spaceGroupHallNumber = onlyAsymmetricUnit ? 1 : self.spaceGroup.spaceGroupSetting.number
      scene[currentSolventMovie][currentFrame].cell = cell
      scene[currentSolventMovie][currentFrame].periodic = true
      scene[currentSolventMovie][currentFrame].atoms = self.solvent
      scene[currentSolventMovie][currentFrame].creationDate = self.creationDate
      scene[currentSolventMovie][currentFrame].creationMethod = self.creationMethod
      scene[currentSolventMovie][currentFrame].chemicalFormulaSum = self.chemicalFormulaSum
      scene[currentSolventMovie][currentFrame].chemicalFormulaStructural = self.chemicalFormulaStructural
      scene[currentSolventMovie][currentFrame].cellFormulaUnitsZ = self.cellFormulaUnitsZ
    
    
      scene[currentSolventMovie][currentFrame].numberOfChannels = self.numberOfChannels
      scene[currentSolventMovie][currentFrame].numberOfPockets = self.numberOfPockets
      scene[currentSolventMovie][currentFrame].dimensionality = self.dimensionality
      scene[currentSolventMovie][currentFrame].Di = self.Di
      scene[currentSolventMovie][currentFrame].Df = self.Df
      scene[currentSolventMovie][currentFrame].Dif = self.Dif
    }
    
    progress.completedUnitCount = 1
  }
  
  func skipComment()
  {
    self.scanner.scanUpToCharacters(from: CharacterSet.newlines, into: nil)
  }
  
  func scanInteger() -> Int
  {
    var tempstring: NSString? = nil
    var value: Int = 0
    
    if !self.scanner.scanInt(&value)
    {
      scanner.scanCharacters(from: keywordSet,into: &tempstring)
      if let string: String = tempstring as String?
      {
        return (string.trimmingCharacters(in: CharacterSet.punctuationCharacters) as NSString).integerValue
      }
      return 0
    }
    return value
  }
  
  func scanDouble() -> Double
  {
    var tempstring: NSString? = nil
    var value: Double = 0.0
    
    if !self.scanner.scanDouble(&value)
    {
      scanner.scanCharacters(from: keywordSet,into: &tempstring)
      if let string: String = tempstring as String?
      {
        return (string.trimmingCharacters(in: CharacterSet.punctuationCharacters) as NSString).doubleValue
      }
      return 0.0
    }
    return value
  }
  
  func scanString() -> String?
  {
    var tempString: NSString? = nil
    self.scanner.scanUpToCharacters(from: CharacterSet.newlines, into: &tempString)
    
    if let string = tempString
    {
      return string as String
    }
    return nil
  }
  
  func parseName(_ keyword: String)
  {
    
    self.name = keyword
    let range = name.startIndex..<name.index(name.startIndex, offsetBy: 5)
    self.name.removeSubrange(range)
  }
  
  func parseiRASPA(_ keyword: String)
  {
    switch(keyword)
    {
    case "_iraspa_number_of_channels".lowercased():
      let value: Int = scanInteger()
      self.numberOfChannels = value
    case "_iraspa_number_of_pockets".lowercased():
      let value: Int = scanInteger()
      self.numberOfPockets = value
    case "_iraspa_dimensionality".lowercased():
      let value: Int = scanInteger()
      self.dimensionality = value
    case "_iraspa_Di".lowercased():
      let value: Double = scanDouble()
      self.Di = value
    case "_iraspa_Df".lowercased():
      let value: Double = scanDouble()
      self.Df = value
    case "_iraspa_Dif".lowercased():
      let value: Double = scanDouble()
      self.Dif = value
    default:
      break
    }
  }
  
  
  func parseSymmetry(_ keyword: String)
  {
    switch(keyword)
    {
    case "_symmetry_cell_setting":
      break
    case "_space_group_name_Hall".lowercased(),
         "_symmetry_space_group_name_Hall".lowercased(),
         "_symmetry.space_group_name_Hall".lowercased():
      if let string: String = scanString(),
         let spaceGroup = SKSpacegroup(Hall: string)
      {
        self.spaceGroup = spaceGroup
        spaceGroupFound = .HallSymbolFound
      }
    case "_space_group_name_H-M_alt".lowercased(),
         "_symmetry_space_group_name_H-M".lowercased(),
         "_symmetry.pdbx_full_space_group_name_H-M".lowercased():
      if (spaceGroupFound != .HallSymbolFound)
      {
        if let string: String = scanString(),
           let spaceGroup = SKSpacegroup(H_M: string)
        {
          self.spaceGroup = spaceGroup
          spaceGroupFound = .HMSymbolFound
        }
      }
    case "_space_group_IT_number".lowercased(),
         "_symmetry_Int_Tables_number".lowercased(),
         "_symmetry.Int_Tables_number".lowercased():
      if (spaceGroupFound == .notFound)
      {
        let number: Int = scanInteger()
        if let spaceGroup = SKSpacegroup(number: number)
        {
          self.spaceGroup = spaceGroup
          spaceGroupFound = .NumberFound
        }
      }
    default:
      break
    }
  }
  
  
  func parseChemical(_ keyword: String)
  {
    if let keyword: ChemicalFormula = ChemicalFormula(rawValue: keyword)
    {
      switch(keyword)
      {
      case .chemical_formula_analytical:
        break
      case .chemical_formula_iupac:
        break
      case .chemical_formula_moiety:
        break
      case .chemical_formula_structural:
        if let string: String = scanString()
        {
          self.chemicalFormulaStructural = string
        }
      case .chemical_formula_sum:
        if let string: String = scanString()
        {
          self.chemicalFormulaSum = string
          //self.chemicalFormulaSum = String(String(string.dropFirst()).dropLast())
        }
      case .chemical_formula_weight:
        break
      case .chemical_formula_weight_meas:
        break
      }
    }
  }
  
  func parseAudit(_ keyword: String)
  {
    switch(keyword)
    {
    case "_audit_creation_date":
      if let string: String = scanString()
      {
        self.creationDate = string
      }
    case "_audit_creation_method":
      if let string: String = scanString()
      {
        self.creationMethod = string
      }
    default:
      break
    }
  }
  
  func parseCell(_ keyword: String)
  {
    switch(keyword)
    {
    case "_cell_length_a".lowercased(),"_cell.length_a".lowercased():
      a = scanDouble()
    // assign a to cell-data
    case "_cell_length_b".lowercased(),"_cell.length_b".lowercased():
      b = scanDouble()
    // assign b to cell-data
    case "_cell_length_c".lowercased(),"_cell.length_c".lowercased():
      c = scanDouble()
    // assign c to cell-data
    case "_cell_angle_alpha".lowercased(),"_cell.angle_alpha".lowercased():
      alpha = scanDouble()
    // assign alpha to cell-data
    case "_cell_angle_beta".lowercased(),"_cell.angle_beta".lowercased():
      beta = scanDouble()
    // assign beta to cell-data
    case "_cell_angle_gamma".lowercased(),"_cell.angle_gamma".lowercased():
      gamma = scanDouble()
    // assign gamma to cell-data
    case "_cell_volume".lowercased():
      //let volume: Double = scanDouble()
      break
    case "_cell_formula_units_Z".lowercased(),"_cell.Z_PDB".lowercased():
      cellFormulaUnitsZ = scanInteger()
      break
    default:
      print("cell-keyword \(keyword) not recognized")
    }
  }
  
  func parseValue() -> String?
  {
    var tempString: NSString? = nil
    var previousScanLocation: Int
    
    if self.scanner.isAtEnd
    {
      return nil
    }
    
    previousScanLocation=self.scanner.scanLocation
    
    while(self.scanner.scanCharacters(from: keywordSet, into:&tempString) && (tempString != nil) && (tempString!.hasPrefix("#")))
    {
      if let keyword = tempString
      {
        if (keyword.hasPrefix("#"))
        {
          skipComment()
        }
      }
    }
    
    if let string: String = tempString as String?
    {
      // detect end of loop
      if (string.hasPrefix("_") || string.hasPrefix("loop_"))
      {
        // set scanner back to before parsing the value
        self.scanner.scanLocation = previousScanLocation
        return nil
      }
        
      else // must be a value
      {
        return string
      }
    }
    return nil
  }
  
  
  
  // a loop can contain comments
  // <DataItems> = <Tag> <WhiteSpace> <Value> | <LoopHeader> <LoopBody>    [case sensitive]
  // <LoopHeader> = <LOOP_> {<WhiteSpace> <Tag>}+                          [case insensitive]
  // <LoopBody> = <Value> { <WhiteSpace> <Value> }*                        [case sensitive]
  //
  // <Tag> = '_'{ <NonBlankChar>}+                                         [case insensitive]
  // <Value> = { '.' | '?' | <Numeric> | <CharString> | <TextField> }      [case sensitive]
  
  func parseLoop()
  {
    var tempString: NSString? = nil
    var previousScanLocation: Int
    var tags: [String] = [String]()
    
    // part 1: read the 'tags'
    previousScanLocation = self.scanner.scanLocation
    while(self.scanner.scanCharacters(from: keywordSet, into:&tempString) && (tempString != nil) && (tempString!.hasPrefix("_") || (tempString!.hasPrefix("#"))))
    {
      if let keyword: String = tempString as String?
      {
       
        if (keyword.hasPrefix("#"))
        {
          skipComment()
        }
        else if (keyword.hasPrefix("_"))
        {
          // found a tag -> add it to the tags-array
          tags.append(keyword)
          
        }
      }
      previousScanLocation=self.scanner.scanLocation
    }
    
    
    // set scanner back to the first <value>
    self.scanner.scanLocation=previousScanLocation
    
    // part 2: read the values
    var value: String?
    
    repeat
    {
      var dictionary: Dictionary<String,String> = Dictionary<String,String>()
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
        if let chemicalSymbol: String = dictionary["_atom_site_type_symbol"]
        {
          let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: "new", elementId: 0, uniqueForceFieldName: "C", position: double3(0.0,0.0,0.0), charge: 0.0, color: NSColor.black, drawRadius: 1.0, bondDistanceCriteria: 1.0)
          
          if let label: String = dictionary["_atom_site_label"]
          {
            atom.displayName = label
          }
          
          if let stringFractionalX = dictionary["_atom_site_fract_x"],
             let stringFractionalY = dictionary["_atom_site_fract_y"],
             let stringFractionalZ = dictionary["_atom_site_fract_z"]
          {
            let x: Double = NSString(string: stringFractionalX).doubleValue
            let y: Double = NSString(string: stringFractionalY).doubleValue
            let z: Double = NSString(string: stringFractionalZ).doubleValue
            atom.position = double3(x: x, y: y, z: z)
            atom.fractional = true
          }
          
          if let stringCartesianX = dictionary["_atom_site_Cartn_x"],
             let stringCartesianY = dictionary["_atom_site_Cartn_y"],
             let stringCartesianZ = dictionary["_atom_site_Cartn_z"]
          {
            let x: Double = NSString(string: stringCartesianX).doubleValue
            let y: Double = NSString(string: stringCartesianY).doubleValue
            let z: Double = NSString(string: stringCartesianZ).doubleValue
            atom.position = double3(x: x, y: y, z: z)
            atom.fractional = false
          }
          
          var charge: Double = 1.0
          if let chargeString: String = dictionary["_atom_site_charge"]
          {
            charge = NSString(string: chargeString).doubleValue
            atom.charge = charge
          }
          
          if let atomicNumber: Int = SKElement.atomData[chemicalSymbol]?["atomicNumber"] as? Int
          {
            atom.elementIdentifier = atomicNumber
            atom.uniqueForceFieldName = chemicalSymbol
            atoms.append(atom)
          }
          else
          {
            let chemicalElement: String = chemicalSymbol.trimmingCharacters(in: CharacterSet(charactersIn: "01234567890.+-"))
            
            if let atomicNumber: Int = SKElement.atomData[chemicalElement]?["atomicNumber"] as? Int
            {
              atom.elementIdentifier = atomicNumber
              atoms.append(atom)
            }
          }
        }
        else if let chemicalSymbol: String = dictionary["_atom_site.type_symbol"]
        {
          let atom: SKAsymmetricAtom = SKAsymmetricAtom(displayName: "new", elementId: 0, uniqueForceFieldName: "C", position: double3(0.0,0.0,0.0), charge: 0.0, color: NSColor.black, drawRadius: 1.0, bondDistanceCriteria: 1.0)
          
          if let label: String = dictionary["_atom_site.id"]
          {
            atom.displayName = label
          }
          
          if let label: String = dictionary["_atom_site.label_atom_id"]  // e.g. OG1
          {
            if label.hasPrefix(chemicalSymbol)
            {
              let secondPart = String(label.dropFirst(chemicalSymbol.count))
              
              if let firstChar: Character = secondPart.first
              {
                atom.remotenessIndicator = firstChar
              
                if let secondChar: Character = secondPart.dropFirst(1).first
                {
                  atom.branchDesignator = secondChar
                }
              }
              
            }
          }
          
          if let label: String = dictionary["_atom_site.group_PDB"]
          {
            atom.solvent = false
            if label.uppercased() == "HETATM"
            {
              atom.solvent = true
            }
          }
         
          if let residueName: String = dictionary["_atom_site.label_comp_id"]  // e.g. "THR"
          {
            atom.residueName = residueName
            
            if let _ = SKElement.aminoAcidData[residueName.uppercased()]
            {
              numberOfAminoAcidAtoms += 1
            }
          }
          
          if let asymmetricID: String = dictionary["_atom_site.label_asym_id"]
          {
            atom.asymetricID = Int(asymmetricID) ?? 0
          }
          
          if let labelEntityID: String = dictionary["_atom_site.label_entity_id"]
          {
            atom.chainIdentifier = labelEntityID.first ?? "?"
          }
          
          if let sequenceID: String = dictionary["_atom_site.label_seq_id"]
          {
            atom.residueSequenceNumber = Int(sequenceID) ?? 0
          }
          
          if let insertionCode: String = dictionary["_atom_site.pdbx_PDB_ins_code"]
          {
            atom.codeForInsertionOfResidues = insertionCode.first ?? " "
          }
          
          if let stringFractionalX = dictionary["_atom_site.fract_x"],
             let stringFractionalY = dictionary["_atom_site.fract_y"],
             let stringFractionalZ = dictionary["_atom_site.fract_z"]
          {
            let x: Double = NSString(string: stringFractionalX).doubleValue
            let y: Double = NSString(string: stringFractionalY).doubleValue
            let z: Double = NSString(string: stringFractionalZ).doubleValue
            atom.position = double3(x: x, y: y, z: z)
            atom.fractional = true
          }
          
          if let stringCartesianX = dictionary["_atom_site.Cartn_x"],
             let stringCartesianY = dictionary["_atom_site.Cartn_y"],
             let stringCartesianZ = dictionary["_atom_site.Cartn_z"]
          {
            let x: Double = NSString(string: stringCartesianX).doubleValue
            let y: Double = NSString(string: stringCartesianY).doubleValue
            let z: Double = NSString(string: stringCartesianZ).doubleValue
            atom.position = double3(x: x, y: y, z: z)
            atom.fractional = false
          }
          
          var charge: Double = 1.0
          if let chargeString: String = dictionary["_atom_site.charge"]
          {
            charge = NSString(string: chargeString).doubleValue
            atom.charge = charge
          }
          
          if let atomicNumber: Int = SKElement.atomData[chemicalSymbol]?["atomicNumber"] as? Int
          {
            atom.elementIdentifier = atomicNumber
            atom.uniqueForceFieldName = chemicalSymbol
            
            if atom.solvent
            {
              solvent.append(atom)
            }
            else
            {
              atoms.append(atom)
            }
          }
          else
          {
            let chemicalElement: String = chemicalSymbol.trimmingCharacters(in: CharacterSet(charactersIn: "01234567890.+-"))
            
            if let atomicNumber: Int = SKElement.atomData[chemicalElement]?["atomicNumber"] as? Int
            {
              atom.elementIdentifier = atomicNumber
              atom.uniqueForceFieldName = chemicalElement
              if atom.solvent
              {
                solvent.append(atom)
              }
              else
              {
                atoms.append(atom)
              }
            }
          }
        }
        else
        {
          
        }
      }
    } while (value != nil)
    // Note: scanner-location is restored to first word after the 'loop'
  }
  
}


// Core dictionary (coreCIF) version 2.4.5 definitions
extension SKCIFParser
{
  enum AtomSite: String
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
  
  enum AtomSites: String
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
  
  enum AtomType: String
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
  
  enum Audit: String
  {
    case audit_block_code = "_audit_block_code"
    case audit_block_doi = "_audit_block_doi"
    case audit_creation_date = "_audit_creation_date"
    case audit_creation_method = "_audit_creation_method"
    case audit_update_record = "_audit_update_record"
  }
  
  enum AuditAuthor: String
  {
    case audit_author_address = "_audit_author_address"
    case audit_author_name = "_audit_author_name"
  }
  
  enum  AuditConform: String
  {
    case audit_conform_dict_location = "_audit_conform_dict_location"
    case audit_conform_dict_name = "_audit_conform_dict_name"
    case audit_conform_dict_version = "_audit_conform_dict_version"
  }
  enum AuditContactAuthor: String
  {
    case audit_contact_author_address = "_audit_contact_author_address"
    case audit_contact_author_email = "_audit_contact_author_email"
    case audit_contact_author_fax = "_audit_contact_author_fax"
    case audit_contact_author_name = "_audit_contact_author_name"
    case audit_contact_author_phone = "_audit_contact_author_phone"
  }
  enum AuditLink: String
  {
    case audit_link_block_code = "_audit_link_block_code"
    case audit_link_block_description = "_audit_link_block_description"
  }
  
  enum Cell: String
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
  
  enum CellMeasurementRefln: String
  {
    case cell_measurement_refln_index_h = "_cell_measurement_refln_index_h"
    case cell_measurement_refln_index_k = "_cell_measurement_refln_index_k"
    case cell_measurement_refln_index_l = "_cell_measurement_refln_index_l"
    case cell_measurement_refln_theta = "_cell_measurement_refln_theta"
  }
  
  enum Chemical: String
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
  
  enum ChemicalConnAtom: String
  {
    case chemical_conn_atom_charge = "_chemical_conn_atom_charge"
    case chemical_conn_atom_display_x = "_chemical_conn_atom_display_x"
    case chemical_conn_atom_display_y = "_chemical_conn_atom_display_y"
    case chemical_conn_atom_NCA = "_chemical_conn_atom_NCA"
    case chemical_conn_atom_NH = "_chemical_conn_atom_NH"
    case chemical_conn_atom_number = "_chemical_conn_atom_number"
    case chemical_conn_atom_type_symbol = "_chemical_conn_atom_type_symbol"
  }
  
  enum ChemicalConnBond: String
  {
    case chemical_conn_bond_atom_1 = "_chemical_conn_bond_atom_1"
    case chemical_conn_bond_atom_2 = "_chemical_conn_bond_atom_2"
    case chemical_conn_bond_type = "_chemical_conn_bond_type"
  }
  
  enum ChemicalFormula: String
  {
    case chemical_formula_analytical = "_chemical_formula_analytical"
    case chemical_formula_iupac = "_chemical_formula_iupac"
    case chemical_formula_moiety = "_chemical_formula_moiety"
    case chemical_formula_structural = "_chemical_formula_structural"
    case chemical_formula_sum = "_chemical_formula_sum"
    case chemical_formula_weight = "_chemical_formula_weight"
    case chemical_formula_weight_meas = "_chemical_formula_weight_meas"
  }
  
  enum Citation: String
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
  
  enum CitationAuthor: String
  {
    case citation_author_citation_id = "_citation_author_citation_id"
    case citation_author_name = "_citation_author_name"
    case citation_author_ordinal = "_citation_author_ordinal"
  }
  
  enum CitationEditor: String
  {
    case citation_editor_citation_id = "_citation_editor_citation_id"
    case citation_editor_name = "_citation_editor_name"
    case citation_editor_ordinal = "_citation_editor_ordinal"
  }
  
  enum Computing: String
  {
    case computing_cell_refinement = "_computing_cell_refinement"
    case computing_data_collection = "_computing_data_collection"
    case computing_data_reduction = "_computing_data_reduction"
    case computing_molecular_graphics = "_computing_molecular_graphics"
    case computing_publication_material = "_computing_publication_material"
    case computing_structure_refinement = "_computing_structure_refinement"
    case computing_structure_solution = "_computing_structure_solution"
  }
  
  enum Database: String
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
  
  enum Diffrn: String
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
  
  enum DiffrnAttenuator: String
  {
    case diffrn_attenuator_code = "_diffrn_attenuator_code"
    case diffrn_attenuator_material = "_diffrn_attenuator_material"
    case diffrn_attenuator_scale = "_diffrn_attenuator_scale"
  }
  
  enum DiffrnDetector: String
  {
    case diffrn_detector = "_diffrn_detector"
    case diffrn_detector_area_resol_mean = "_diffrn_detector_area_resol_mean"
    case diffrn_detector_details = "_diffrn_detector_details"
    case diffrn_detector_dtime = "_diffrn_detector_dtime"
    case diffrn_detector_type = "_diffrn_detector_type"
    case diffrn_radiation_detector = "_diffrn_radiation_detector"
    case diffrn_radiation_detector_dtime = "_diffrn_radiation_detector_dtime"
  }
  
  enum DiffrnMeasurement: String
  {
    case diffrn_measurement_details = "_diffrn_measurement_details"
    case diffrn_measurement_device = "_diffrn_measurement_device"
    case diffrn_measurement_device_details = "_diffrn_measurement_device_details"
    case diffrn_measurement_device_type = "_diffrn_measurement_device_type"
    case diffrn_measurement_method = "_diffrn_measurement_method"
    case diffrn_measurement_specimen_support = "_diffrn_measurement_specimen_support"
  }
  
  enum DiffrnOrientMatrix: String
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
  
  enum DiffrnOrientRefln: String
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
  
  enum DiffrnRadiation: String
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
  
  enum DiffrnRadiationWavelength: String
  {
    case diffrn_radiation_wavelength = "_diffrn_radiation_wavelength"
    case diffrn_radiation_wavelength_details = "_diffrn_radiation_wavelength_details"
    case diffrn_radiation_wavelength_determination = "_diffrn_radiation_wavelength_determination"
    case diffrn_radiation_wavelength_id = "_diffrn_radiation_wavelength_id"
    case diffrn_radiation_wavelength_wt = "_diffrn_radiation_wavelength_wt"
  }
  
  enum DiffrnRefln: String
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
  
  enum DiffrnReflns: String
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
  
  enum DiffrnReflnsClass: String
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
  
  enum DiffrnScaleGroup: String
  {
    case diffrn_scale_group_code = "_diffrn_scale_group_code"
    case diffrn_scale_group_I_net = "_diffrn_scale_group_I_net"
  }
  enum DiffrnSource: String
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
  
  enum DiffrnStandardRefln: String
  {
    case diffrn_standard_refln_code = "_diffrn_standard_refln_code"
    case diffrn_standard_refln_index_h = "_diffrn_standard_refln_index_h"
    case diffrn_standard_refln_index_k = "_diffrn_standard_refln_index_k"
    case diffrn_standard_refln_index_l = "_diffrn_standard_refln_index_l"
  }
  
  enum DiffrnStandards: String
  {
    case diffrn_standards_decay_percentage = "_diffrn_standards_decay_%"
    case diffrn_standards_interval_count = "_diffrn_standards_interval_count"
    case diffrn_standards_interval_time = "_diffrn_standards_interval_time"
    case diffrn_standards_number = "_diffrn_standards_number"
    case diffrn_standards_scale_sigma = "_diffrn_standards_scale_sigma"
    case diffrn_standards_scale_u = "_diffrn_standards_scale_u"
  }
  
  enum Exptl: String
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
  
  enum ExptlCrystal: String
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
  
  enum ExptlCrystalFace: String
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
  
  enum Geom: String
  {
    case geom_special_details = "_geom_special_details"
  }
  
  enum GeomAngle: String
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
  
  enum GeomBond: String
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
  
  enum GeomContact: String
  {
    case geom_contact_atom_site_label_1 = "_geom_contact_atom_site_label_1"
    case geom_contact_atom_site_label_2 = "_geom_contact_atom_site_label_2"
    case geom_contact_distance = "_geom_contact_distance"
    case geom_contact_publ_flag = "_geom_contact_publ_flag"
    case geom_contact_site_symmetry_1 = "_geom_contact_site_symmetry_1"
    case geom_contact_site_symmetry_2 = "_geom_contact_site_symmetry_2"
  }
  
  enum GeomHbond: String
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
  
  enum GeomTorsion: String
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
  
  enum Journal: String
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
  
  enum JournalIndex: String
  {
    case journal_index_subterm = "_journal_index_subterm"
    case journal_index_term = "_journal_index_term"
    case journal_index_type = "_journal_index_type"
  }
  
  enum Publ: String
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
  
  enum PublAuthor: String
  {
    case publ_author_address = "_publ_author_address"
    case publ_author_email = "_publ_author_email"
    case publ_author_footnote = "_publ_author_footnote"
    case publ_author_id_iucr = "_publ_author_id_iucr"
    case publ_author_id_orcid = "_publ_author_id_orcid"
    case publ_author_name = "_publ_author_name"
  }
  
  enum PublBody: String
  {
    case publ_body_contents = "_publ_body_contents"
    case publ_body_element = "_publ_body_element"
    case publ_body_format = "_publ_body_format"
    case publ_body_label = "_publ_body_label"
    case publ_body_title = "_publ_body_title"
  }
  
  enum PublManuscriptIncl: String
  {
    case publ_manuscript_incl_extra_defn = "_publ_manuscript_incl_extra_defn"
    case publ_manuscript_incl_extra_info = "_publ_manuscript_incl_extra_info"
    case publ_manuscript_incl_extra_item = "_publ_manuscript_incl_extra_item"
  }
  
  enum Refine: String
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
  
  enum RefineLsClass: String
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
  
  enum Reflns: String
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
  
  enum ReflnsClass: String
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
  
  enum ReflnsScale: String
  {
    case reflns_scale_group_code = "_reflns_scale_group_code"
    case reflns_scale_meas_F = "_reflns_scale_meas_F"
    case reflns_scale_meas_F_squared = "_reflns_scale_meas_F_squared"
    case reflns_scale_meas_intensity = "_reflns_scale_meas_intensity"
  }
  
  enum ReflnsShell: String
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
  
  enum SpaceGroup: String
  {
    case space_group_crystal_system = "_space_group_crystal_system"
    case space_group_id = "_space_group_id"
    case space_group_IT_number = "_space_group_IT_number"
    case space_group_name_H_M_alt = "_space_group_name_H-M_alt"
    case space_group_name_Hall = "_space_group_name_Hall"
  }
  
  enum SpaceGroupSymop: String
  {
    case space_group_symop_id = "_space_group_symop_id"
    case space_group_symop_operation_xyz = "_space_group_symop_operation_xyz"
    case space_group_symop_sg_id = "_space_group_symop_sg_id"
  }
  
  enum Symmetry: String
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
  
  enum ValenceParam: String
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
  
  enum ValenceRef: String
  {
    case valence_ref_id = "_valence_ref_id"
    case valence_ref_reference = "_valence_ref_reference"
  }
}
