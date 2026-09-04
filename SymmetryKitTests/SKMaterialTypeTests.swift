//
//  SKMaterialTypeTests.swift
//  SymmetryKitTests
//

import XCTest
import AppKit
@testable import SymmetryKit

final class SKMaterialTypeTests: XCTestCase
{
  func testDisplayNamesAndTypo()
  {
    XCTAssertEqual(SKStructure.MaterialType.allDisplayNames, [
      "Unspecified", "Molecule", "Protein", "DNA/RNA", "Molecular crystal",
      "Silica", "Aluminosilicate", "Aluminophosphate",
      "Metallophosphate", "Silicoaluminophosphate", "Zeolite", "MOF", "ZIF", "COF",
      "Carbon", "Oxide",
      "HOF", "PAF", "PIM", "Polymer", "Ionic liquid", "Clay", "Perovskite", "Alloy", "Glass"
    ])
    XCTAssertEqual(SKStructure.MaterialType.fromDisplayName("Silicialuminophosphate"), .silicoaluminophosphate)
    XCTAssertEqual(SKStructure.MaterialType.fromDisplayName("DNA/RNA"), .dnaRna)
    XCTAssertEqual(SKStructure.MaterialType.fromDisplayName("Ionic liquid"), .ionicLiquid)
    XCTAssertEqual(SKStructure.MaterialType.fromDisplayName("MOF"), .mof)
    XCTAssertNil(SKStructure.MaterialType.fromDisplayName("Unknown"))
  }
  
  func testAllSilicaZeolite()
  {
    XCTAssertEqual(infer([14, 8]), .zeolite)
    XCTAssertEqual(infer([14, 8, 1, 11]), .zeolite)
    XCTAssertEqual(SKStructure.MaterialType.infer(elementIdentifiers: [14, 8], kind: .crystal, names: ["AFX_SI"]), .zeolite)
  }
  
  func testMesoporousSilica()
  {
    XCTAssertEqual(SKStructure.MaterialType.infer(elementIdentifiers: [14, 8], kind: .crystal, names: ["MCM-41"]), .silica)
    XCTAssertEqual(SKStructure.MaterialType.infer(elementIdentifiers: [14, 8, 1], kind: .crystal, names: ["SBA-15"]), .silica)
  }
  
  func testAluminosilicate()
  {
    XCTAssertEqual(infer([14, 13, 8, 11]), .aluminosilicate)
  }
  
  func testAluminophosphateAndAsMadeTemplate()
  {
    XCTAssertEqual(infer([13, 15, 8]), .aluminophosphate)
    XCTAssertEqual(infer([13, 15, 8, 6, 7, 1]), .aluminophosphate)
  }
  
  func testSilicoaluminophosphate()
  {
    XCTAssertEqual(infer([14, 13, 15, 8]), .silicoaluminophosphate)
  }
  
  func testMetallophosphate()
  {
    XCTAssertEqual(infer([13, 15, 8, 26]), .metallophosphate)
  }
  
  func testZeoliteLeftover()
  {
    XCTAssertEqual(infer([14, 32, 8]), .zeolite)
    XCTAssertEqual(infer([32, 8]), .zeolite)
  }
  
  func testMOF()
  {
    XCTAssertEqual(infer([30, 6, 8]), .mof)
    XCTAssertEqual(infer([12, 6, 8]), .mof)
    XCTAssertEqual(infer([13, 6, 8]), .mof)
    XCTAssertEqual(infer([29, 6, 8, 1]), .mof)
  }
  
  func testZIF()
  {
    XCTAssertEqual(infer([30, 6, 7, 1]), .zif)
    XCTAssertEqual(infer([27, 6, 7]), .zif)
  }
  
  func testCOF()
  {
    XCTAssertEqual(infer([6, 7, 1]), .cof)
    XCTAssertEqual(infer([6, 5, 8, 1]), .cof)
  }
  
  func testKindBasedTypes()
  {
    XCTAssertEqual(SKStructure.MaterialType.infer(elementIdentifiers: [6, 1], kind: .protein), .protein)
    XCTAssertEqual(SKStructure.MaterialType.infer(elementIdentifiers: [6, 1], kind: .proteinCrystal), .protein)
    XCTAssertEqual(SKStructure.MaterialType.infer(elementIdentifiers: [6, 7, 8], kind: .dna), .dnaRna)
    XCTAssertEqual(SKStructure.MaterialType.infer(elementIdentifiers: [6, 7, 8], kind: .dnaCrystal), .dnaRna)
    XCTAssertEqual(SKStructure.MaterialType.infer(elementIdentifiers: [6, 1], kind: .molecule), .molecule)
    XCTAssertEqual(SKStructure.MaterialType.infer(elementIdentifiers: [6, 1], kind: .molecularCrystal), .molecularCrystal)
  }
  
  func testCarbon()
  {
    XCTAssertEqual(infer([6, 6, 6]), .carbon)
    XCTAssertEqual(infer([6, 8]), .carbon)
  }
  
  func testMolecularCrystalFromComposition()
  {
    XCTAssertEqual(infer([6, 6, 6, 6, 6, 6, 1, 1, 1, 1, 1, 1]), .molecularCrystal)
    XCTAssertEqual(infer([8, 1, 1]), .molecularCrystal)
  }
  
  func testOxide()
  {
    XCTAssertEqual(infer([22, 8]), .oxide)
    XCTAssertEqual(infer([13, 8]), .oxide)
    XCTAssertEqual(infer([30, 8]), .oxide)
  }
  
  func testNameHintOnlyWhenUnspecified()
  {
    XCTAssertEqual(SKStructure.MaterialType.infer(elementIdentifiers: [16], kind: .crystal, names: ["IRMOF-1"]), .mof)
    XCTAssertEqual(SKStructure.MaterialType.infer(elementIdentifiers: [14, 8], kind: .crystal, names: ["some MOF"]), .zeolite)
    XCTAssertEqual(SKStructure.MaterialType.infer(elementIdentifiers: [16], kind: .crystal, names: ["ZIF-8"]), .zif)
  }
  
  func testCIFAllSilicaZeoliteMFI() throws
  {
    try assertCIF("SpglibTestData/zeolites/MFI-para.cif", equals: .zeolite)
  }
  
  func testCIFAluminosilicateSOD() throws
  {
    try assertCIF("SpglibTestData/zeolites/SOD.cif", equals: .aluminosilicate)
  }
  
  func testCIFAluminophosphate() throws
  {
    try assertCIF("SpglibTestData/zeolites/AlPO-17.cif", equals: .aluminophosphate)
  }
  
  func testCIFMOFs() throws
  {
    try assertCIF("SpglibTestData/mofs/IRMOF-1.cif", equals: .mof)
    try assertCIF("SpglibTestData/mofs/Cu-BTC.cif", equals: .mof)
    try assertCIF("SpglibTestData/mofs/MgMOF-74.cif", equals: .mof)
    try assertCIF("SpglibTestData/mofs/MIL-53(Cr)ht.cif", equals: .mof)
  }
  
  func testCIFZIF() throws
  {
    try assertCIF("SpglibTestData/zifs/ZIF-1.cif", equals: .zif)
  }
  
  func testCIFCOF() throws
  {
    try assertCIF("SpglibTestData/mofs/COF-300.cif", equals: .cof)
    try assertCIF("SpglibTestData/mofs/COF-102.cif", equals: .cof)
  }
  
  func testMMCIProtein() throws
  {
    guard let url = sampleURL("1D5H_sample.cif") ?? sampleURL("1D5H_sample.mmcif") else
    {
      throw XCTSkip("1D5H sample mmCIF not found under Scripts/")
    }
    let structure = try parse(url: url, asProtein: true)
    XCTAssertEqual(structure.kind, .protein)
    XCTAssertEqual(structure.materialType, .protein)
  }
  
  private func infer(_ elements: [Int]) -> SKStructure.MaterialType
  {
    return SKStructure.MaterialType.infer(elementIdentifiers: elements, kind: .crystal)
  }
  
  private func assertCIF(_ relativePath: String, equals expected: SKStructure.MaterialType) throws
  {
    guard let url = cifURL(relativePath) else
    {
      throw XCTSkip("Missing \(relativePath)")
    }
    let structure = try parse(url: url)
    XCTAssertEqual(structure.materialType, expected, relativePath)
  }
  
  private func parse(url: URL, asProtein: Bool = false) throws -> SKStructure
  {
    let data = try Data(contentsOf: url)
    let parser = try SKCIFParser(displayName: url.deletingPathExtension().lastPathComponent,
                                 data: data,
                                 onlyAsymmetricUnit: asProtein,
                                 asMolecule: false,
                                 asProtein: asProtein)
    try parser.startParsing()
    XCTAssertFalse(parser.scene.isEmpty)
    XCTAssertFalse(parser.scene[0].isEmpty)
    return parser.scene[0][0]
  }
  
  private func cifURL(_ relativePath: String) -> URL?
  {
    let bundle = Bundle(for: type(of: self))
    if let url = bundle.url(forResource: relativePath, withExtension: nil)
    {
      return url
    }
    let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent(relativePath)
    if FileManager.default.fileExists(atPath: repo.path)
    {
      return repo
    }
    return nil
  }
  
  private func sampleURL(_ name: String) -> URL?
  {
    let candidates: [URL] = [
      URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Scripts").appendingPathComponent(name),
      URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Research/iRASPA-COCOA/Scripts/\(name)")
    ]
    return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
  }
  
  func testApplyInferredMaterialTypeOnStructure()
  {
    let structure = SKStructure()
    structure.kind = .molecule
    structure.displayName = "fragment"
    structure.atoms = [
      SKAsymmetricAtom(displayName: "C", elementId: 6, uniqueForceFieldName: "C", position: .zero, charge: 0.0, color: .black, drawRadius: 1.0, bondDistanceCriteria: 1.0, occupancy: 1.0)
    ]
    structure.applyInferredMaterialType()
    XCTAssertEqual(structure.materialType, .molecule)
    
    structure.kind = .crystal
    structure.applyInferredMaterialType()
    XCTAssertEqual(structure.materialType, .carbon)
    
    structure.atoms = [
      SKAsymmetricAtom(displayName: "Si", elementId: 14, uniqueForceFieldName: "Si", position: .zero, charge: 0.0, color: .black, drawRadius: 1.0, bondDistanceCriteria: 1.0, occupancy: 1.0),
      SKAsymmetricAtom(displayName: "O", elementId: 8, uniqueForceFieldName: "O", position: .zero, charge: 0.0, color: .black, drawRadius: 1.0, bondDistanceCriteria: 1.0, occupancy: 1.0)
    ]
    structure.displayName = "sample"
    structure.applyInferredMaterialType(extraNames: ["MCM-41"])
    XCTAssertEqual(structure.materialType, .silica)
    
    structure.kind = .molecularCrystal
    structure.atoms = [
      SKAsymmetricAtom(displayName: "Ti", elementId: 22, uniqueForceFieldName: "Ti", position: .zero, charge: 0.0, color: .black, drawRadius: 1.0, bondDistanceCriteria: 1.0, occupancy: 1.0),
      SKAsymmetricAtom(displayName: "O", elementId: 8, uniqueForceFieldName: "O", position: .zero, charge: 0.0, color: .black, drawRadius: 1.0, bondDistanceCriteria: 1.0, occupancy: 1.0)
    ]
    structure.applyInferredMaterialType(kind: .crystal)
    XCTAssertEqual(structure.materialType, .oxide)
  }
  
  func testXYZParserInfersMolecule() throws
  {
    let xyz = """
    3
    comment
    C 0.0 0.0 0.0
    H 1.0 0.0 0.0
    H 0.0 1.0 0.0
    """
    let parser = try SKXYZParser(displayName: "fragment", data: Data(xyz.utf8))
    try parser.startParsing()
    XCTAssertEqual(parser.scene[0][0].kind, .molecule)
    XCTAssertEqual(parser.scene[0][0].materialType, .molecule)
  }
  
  func testXYZParserInfersPeriodicComposition() throws
  {
    let graphite = """
    2
    Lattice="10 0 0 0 10 0 0 0 10"
    C 0.0 0.0 0.0
    C 1.4 0.0 0.0
    """
    let carbonParser = try SKXYZParser(displayName: "graphite", data: Data(graphite.utf8))
    try carbonParser.startParsing()
    XCTAssertEqual(carbonParser.scene[0][0].kind, .molecularCrystal)
    XCTAssertEqual(carbonParser.scene[0][0].materialType, .carbon)
    
    let titania = """
    2
    Lattice="5 0 0 0 5 0 0 0 5"
    Ti 0.0 0.0 0.0
    O 1.9 0.0 0.0
    """
    let oxideParser = try SKXYZParser(displayName: "tio2", data: Data(titania.utf8))
    try oxideParser.startParsing()
    XCTAssertEqual(oxideParser.scene[0][0].kind, .molecularCrystal)
    XCTAssertEqual(oxideParser.scene[0][0].materialType, .oxide)
  }
  
  func testPDBParserInfersMolecule() throws
  {
    let pdb = """
    HETATM    1  C   UNK     1       0.000   0.000   0.000  1.00  0.00           C
    HETATM    2  H   UNK     1       1.000   0.000   0.000  1.00  0.00           H
    END
    """
    let parser = try SKPDBParser(displayName: "ligand", data: Data(pdb.utf8),
                                 onlyAsymmetricUnitMolecule: true, asMolecule: true, asProtein: false)
    try parser.startParsing()
    XCTAssertEqual(parser.scene[0][0].kind, .molecule)
    XCTAssertEqual(parser.scene[0][0].materialType, .molecule)
  }
  
  func testPDBParserInfersProtein() throws
  {
    let pdb = """
    ATOM      1  N   ALA A   1       0.000   0.000   0.000  1.00  0.00           N
    ATOM      2  CA  ALA A   1       1.458   0.000   0.000  1.00  0.00           C
    ATOM      3  C   ALA A   1       1.958   1.400   0.000  1.00  0.00           C
    ATOM      4  N   ALA A   2       2.200   1.700   0.000  1.00  0.00           N
    ATOM      5  CA  ALA A   2       3.658   1.700   0.000  1.00  0.00           C
    ATOM      6  C   ALA A   2       4.158   3.100   0.000  1.00  0.00           C
    END
    """
    let parser = try SKPDBParser(displayName: "peptide", data: Data(pdb.utf8),
                                 onlyAsymmetricUnitMolecule: true, asMolecule: false, asProtein: true)
    try parser.startParsing()
    XCTAssertEqual(parser.scene[0][0].kind, .protein)
    XCTAssertEqual(parser.scene[0][0].materialType, .protein)
  }
}
