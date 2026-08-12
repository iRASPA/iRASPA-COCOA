//
//  SKCIFmmCIFTests.swift
//  SymmetryKitTests
//

import XCTest
@testable import SymmetryKit

final class SKCIFmmCIFTests: XCTestCase
{
  private func sampleURL(_ name: String) -> URL?
  {
    let candidates: [URL] = [
      URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Scripts").appendingPathComponent(name),
      URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Research/iRASPA-COCOA/Scripts/\(name)")
    ]
    return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
  }
  
  func testMMCIReadsProteinLikePDB() throws
  {
    guard let url = sampleURL("1D5H_sample.cif") ?? sampleURL("1D5H_sample.mmcif") else
    {
      throw XCTSkip("1D5H sample mmCIF not found under Scripts/")
    }
    
    let data = try Data(contentsOf: url)
    let parser = try SKCIFParser(displayName: "1D5H", data: data, onlyAsymmetricUnit: true, asMolecule: false, asProtein: true)
    try parser.startParsing()
    
    XCTAssertFalse(parser.scene.isEmpty)
    XCTAssertFalse(parser.scene[0].isEmpty)
    let structure = parser.scene[0][0]
    XCTAssertEqual(structure.kind, .protein)
    XCTAssertGreaterThan(structure.atoms.count, 100)
    XCTAssertTrue(structure.atoms.contains { $0.residueName == "SET" })
    XCTAssertTrue(structure.atoms.contains { $0.solvent && ($0.residueName == "HOH" || $0.residueName == "SO4") })
    XCTAssertTrue(structure.atoms.contains { !$0.solvent && $0.residueName == "LYS" && $0.displayName == "N" })
  }
  
  func testMaterialsCIFStillCrystal() throws
  {
    guard let url = sampleURL("materials_sample.cif") else
    {
      throw XCTSkip("materials sample CIF not found under Scripts/")
    }
    
    let data = try Data(contentsOf: url)
    let parser = try SKCIFParser(displayName: "materials", data: data, onlyAsymmetricUnit: false, asMolecule: false, asProtein: true)
    try parser.startParsing()
    
    let structure = parser.scene[0][0]
    XCTAssertEqual(structure.kind, .crystal)
    XCTAssertGreaterThan(structure.atoms.count, 0)
  }
}
