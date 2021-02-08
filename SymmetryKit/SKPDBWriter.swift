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

// PDB file-format
//  1 -  6        Record name     "ATOM  "
//  7 - 11        Integer         serial        Atom serial number
// 13 - 14        Atom            name          Chemical symbol (right justified)
//      15        Remoteness indicator
//      16        Branch designator
// 17             Character       altLoc        Alternate location indicator
// 18 - 20        Residue name    resName       Residue name
//      21        Reserved
// 22             Character       chainID       Chain identifier
// 23 - 26        Integer         resSeq        Residue sequence number
// 27             AChar           iCode         Code for insertion of residues
// 31 - 38        Real(8.3)       x             Orthogonal coordinates for X
// 39 - 46        Real(8.3)       y             Orthogonal coordinates for Y
// 47 - 54        Real(8.3)       z             Orthogonal coordinates for Z
// 55 - 60        Real(6.2)       occupancy     Occupancy
// 61 - 66        Real(6.2)       tempFactor    Isotropic B-factor
// 73 - 76        LString(4)      segID         Segment identifier, left-justified, may
//                                              include a space, e.g., CH86, A 1, NASE.
// 77 - 78        LString(2)      element       Element symbol, right-justified
// 79 - 80        LString(2)      charge        Charge on the atom
// Typical Format:  (6A1,I5,1X,A4,A1,A3,1X,A1,I4,A1,3X,3F8.3,2F6.2,6X,2A4)

// Cols.  1-6    Record name "CRYST1"
//      7-15    a (Angstrom)
//     16-24    b (Angstrom)
//     25-33    c (Angstrom)
//     34-40    alpha (degrees)
//     41-47    beta  (degrees)
//     48-54    gamma (degrees)
//     56-66    Space group symbol, left justified
//     67-70    Z   Z value is the number of polymeric chains in a unit cell. In the case of heteropolymers,
//                  Z is the number of occurrences of the most populous chain.
// Typical Format:  (6A1,3F9.3,3F7.2,1X,11A1,I4)


public class SKPDBWriter
{
  // The lazy initialization of the shared instance is thread safe by the definition of let
  public static let shared: SKPDBWriter = SKPDBWriter()
  
  var counter: Int = 1
  
  private init()
  {
  }
  
  
  
  public func string(displayName: String,spaceGroupHallNumber: Int?, cell: SKCell?, atoms: [SKAsymmetricAtom], origin: SIMD3<Double>) -> String
  {
    counter = 1
    var outputString: String = "COMPND    \(displayName)\n" +
                               "AUTHOR    GENERATED BY IRASPA\n"
    
    outputString += self.string(spaceGroupHallNumber: spaceGroupHallNumber, cell: cell, atoms: atoms, origin: origin)
   
    outputString += "TER" + "   " + self.formatString(str: String(counter), length: 5) + "\n"
    counter += 1
    outputString.append("END\n")
    
    return outputString
  }
  
  
  
  public func string(displayName: String, movies: [[(spaceGroupHallNumber: Int?, cell: SKCell?, atoms: [SKAsymmetricAtom])]], origin: SIMD3<Double>) -> String
  {
    counter = 1
    var outputString: String = "COMPND    \(displayName)\n" +
                               "AUTHOR    GENERATED BY IRASPA\n"
    
    if let maxFrames: Int = movies.map({$0.count}).max()
    {
      for frameIndex in 0..<maxFrames
      {
        outputString += "MODEL    \(frameIndex)\n"
        for movie in movies.enumerated()
        {
          for (j,frame) in movie.element.enumerated()
          {
            if (frameIndex == j)
            {
              outputString += self.string(spaceGroupHallNumber: frame.spaceGroupHallNumber, cell: frame.cell, atoms: frame.atoms, origin: origin)
              outputString += "TER" + "   " + self.formatString(str: String(counter), length: 5) + "\n"
              counter += 1
            }
          }
        }
        outputString += "ENDMDL\n"
      }
      outputString += "END\n"
    }
    return outputString
  }
  
  func formatString(str: String, length: Int, spacer: Character = Character(" "), justifyToTheRight: Bool = true) -> String
  {
    let c = str.count
    let start = str.startIndex
    let end = str.endIndex
    var str = str
    if c > length
    {
      switch justifyToTheRight
      {
      case true:
        let range = str.index(start, offsetBy: c - length)..<end
        return String(str[range])
      case false:
        let range = start..<str.index(end, offsetBy: length - c)
        return String(str[range])
      }
    }
    else
    {
      var extraSpace = String(repeating: spacer, count: length - c)
      if justifyToTheRight
      {
        extraSpace.append(str)
        return extraSpace
      }
      else
      {
        str.append(extraSpace)
        return str
      }
    }
  }

  private func string(spaceGroupHallNumber: Int?, cell: SKCell?, atoms: [SKAsymmetricAtom], origin: SIMD3<Double>) -> String
  {
    var outputString: String = ""
    
    if let cell = cell
    {
      let spaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: spaceGroupHallNumber ?? 1)
      let spaceGroupRecordName = "CRYST1"
      let a = self.formatString(str: String(format: "%9.3f",cell.a), length: 9)
      let b = self.formatString(str: String(format: "%9.3f",cell.b), length: 9)
      let c = self.formatString(str: String(format: "%9.3f",cell.c), length: 9)
      let alpha = self.formatString(str: String(format: "%7.2f",cell.alpha * 180.0/Double.pi), length: 7)
      let beta = self.formatString(str: String(format: "%7.2f",cell.beta * 180.0/Double.pi), length: 7)
      let gamma = self.formatString(str: String(format: "%7.2f",cell.gamma * 180.0/Double.pi), length: 7)
      let spaceGroupString = self.formatString(str: spaceGroup.spaceGroupSetting.HM, length: 11, justifyToTheRight: false)
      let zValue = self.formatString(str: String(cell.zValue), length: 4)
      let line: String = spaceGroupRecordName + a + b + c + alpha + beta + gamma + " " + spaceGroupString + zValue + "\n"
      outputString.append(line)
    }
    
    for atom in atoms
    {
      let elementSymbol = self.formatString(str:  PredefinedElements.sharedInstance.elementSet[atom.elementIdentifier].chemicalSymbol, length: 2)
      
      let atomRecordName = "ATOM  "
      let atomSerialNumber = self.formatString(str: String(counter), length: 5)
      let atomName = self.formatString(str: elementSymbol, length: 2)
      let remotenessIndicator = self.formatString(str: String(atom.remotenessIndicator), length: 1)
      let branchIndicator = self.formatString(str: String(atom.branchDesignator), length: 1)
      let alternateLocationIndicator = self.formatString(str: " ", length: 1)
      let residueName = self.formatString(str: atom.residueName, length: 3)
      let chainIdentifier = self.formatString(str: String(atom.chainIdentifier), length: 1)
      let residueSequenceNumber = self.formatString(str: String(atom.residueSequenceNumber), length: 4)
      let codeForInsertionOfResidues = self.formatString(str: String(atom.codeForInsertionOfResidues), length: 1)
      let orthogonalCoordinatesForX = self.formatString(str: String(format: "%8.3f",atom.position.x - origin.x), length: 8)
      let orthogonalCoordinatesForY = self.formatString(str: String(format: "%8.3f",atom.position.y - origin.y), length: 8)
      let orthogonalCoordinatesForZ = self.formatString(str: String(format: "%8.3f",atom.position.z - origin.z), length: 8)
      let occupancy = self.formatString(str: String(format: "%6.2f",atom.occupancy), length: 6)
      let isotropicBFactor = self.formatString(str: String(format: "%6.2f",atom.temperaturefactor), length: 6)
      let segmentIdentifier = self.formatString(str: String(atom.segmentIdentifier), length: 4, justifyToTheRight: false)
      
      let charge = self.formatString(str:  String("  "), length: 2)
      let line: String = atomRecordName + atomSerialNumber + " " + atomName + remotenessIndicator + branchIndicator + alternateLocationIndicator + residueName + " " + chainIdentifier + residueSequenceNumber + codeForInsertionOfResidues + "   " + orthogonalCoordinatesForX + orthogonalCoordinatesForY + orthogonalCoordinatesForZ + occupancy + isotropicBFactor + "      " + segmentIdentifier + elementSymbol + charge + "\n"
      outputString.append(line)
      counter += 1
    }
    
    return outputString
  }
}
