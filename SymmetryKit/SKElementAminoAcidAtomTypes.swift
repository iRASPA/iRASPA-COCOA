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


enum AminoAcid: Int
{
  case ala = 0
  case asx = 1
  case cys = 2
  case asp = 3
  case glu = 4
  case phe = 5
  case gly = 6
  case his = 7
  case ile = 8
  case lys = 10
  case leu = 11
  case met = 12
  case asn = 13
  case pyl = 14
  case pro = 15
  case gln = 16
  case arg = 17
  case ser = 18
  case thr = 19
  case sec = 20
  case val = 21
  case trp = 22
  case tyr = 24
  case glx = 25
  case unk = 26
}


struct SKAminoAcidAtomType
{
  let element: String
  let type: String
  let vdWRadius: Double
}

extension SKElement
{
  static let knownAminoAcidResidueCodes: Set<String> = [
      "ALA", "ASX", "CYS", "ASP", "GLU", "PHE", "GLY", "HIS", "ILE", "LYS", "LEU", "MET",
      "ASN", "PYL", "PRO", "GLN", "ARG", "SER", "THR", "SEC", "VAL", "TRP", "TYR", "GLX", "UNK"
    ]

  static let aminoAcidAtomTypes: [String: SKAminoAcidAtomType] = [
    "NH1": SKAminoAcidAtomType(element: "N", type: "BackBone NH", vdWRadius: 1.65),
    "NC2": SKAminoAcidAtomType(element: "N", type: "Charged, Arg NH1, NH2", vdWRadius: 1.65),
    "NH3": SKAminoAcidAtomType(element: "N", type: "Charged, Lys NZ", vdWRadius: 1.5),
    "NH2": SKAminoAcidAtomType(element: "N", type: "Uncharged, Asn ND2, Gln NE2", vdWRadius: 1.65),
    "N": SKAminoAcidAtomType(element: "N", type: "Uncharged, Pro N", vdWRadius: 1.65),
    "NH1S": SKAminoAcidAtomType(element: "N", type: "Uncharged, Sidechain NH: Arg NE, His ND1, NE1, Trp NE1", vdWRadius: 1.65),
    "O": SKAminoAcidAtomType(element: "O", type: "Backbone O", vdWRadius: 1.4),
    "OS": SKAminoAcidAtomType(element: "O", type: "Backbone, Sidechain O: Asn OD1, Gln OE1", vdWRadius: 1.4),
    "OC": SKAminoAcidAtomType(element: "O", type: "Carboxyl O, (Asp OD1, OD2, Glu OE1, OE2)", vdWRadius: 1.4),
    "OH1": SKAminoAcidAtomType(element: "O", type: "Hydroxyl, Alcohol OH (Ser OG, Thr OG1, Tyr OH)", vdWRadius: 1.4),
    "C": SKAminoAcidAtomType(element: "C", type: "Backbone C", vdWRadius: 1.76),
    "CH1E": SKAminoAcidAtomType(element: "C", type: "Backbone CA (exc. Gly)", vdWRadius: 1.87),
    "CH2G": SKAminoAcidAtomType(element: "C", type: "Backbone CA, Gly CA", vdWRadius: 1.87),
    "CR1E": SKAminoAcidAtomType(element: "C", type: "Aromatic C, Aromatic CH (except CR1W, CRHH, CR1H)", vdWRadius: 1.76),
    "CR1W": SKAminoAcidAtomType(element: "C", type: "Aromatic C, Trp CZ2, CH2", vdWRadius: 1.76),
    "CRHH": SKAminoAcidAtomType(element: "C", type: "Aromatic C, His CE1", vdWRadius: 1.76),
    "CR1H": SKAminoAcidAtomType(element: "C", type: "Aromatic C, His CD2", vdWRadius: 1.76),
    "CH0": SKAminoAcidAtomType(element: "C", type: "Aliphatic C, Arg CZ, Asn CG, Asp CG, Gln CD, Glu CD", vdWRadius: 1.76),
    "CH1S": SKAminoAcidAtomType(element: "C", type: "Aliphatic C, Sidechain CH1: Ile CB, Leu CG, Thr CB, Val CB", vdWRadius: 1.87),
    "CF": SKAminoAcidAtomType(element: "C", type: "Aliphatic C, Phe CG", vdWRadius: 1.76),
    "CY": SKAminoAcidAtomType(element: "C", type: "Aliphatic C, Tyr CG", vdWRadius: 1.76),
    "CW": SKAminoAcidAtomType(element: "C", type: "Aliphatic C, Trp CD2, CE2", vdWRadius: 1.76),
    "C5": SKAminoAcidAtomType(element: "C", type: "Aliphatic C, His CG", vdWRadius: 1.76),
    "C5W": SKAminoAcidAtomType(element: "C", type: "Aliphatic C, Trp CG", vdWRadius: 1.76),
    "CH2E": SKAminoAcidAtomType(element: "C", type: "Aliphatic C, Tetrahedral CH2 (except CH2P,CH2G) All CB", vdWRadius: 1.87),
    "CH2P": SKAminoAcidAtomType(element: "C", type: "Aliphatic C, Pro CG, CD", vdWRadius: 1.87),
    "CY2": SKAminoAcidAtomType(element: "C", type: "Aliphatic C, Tyr CZ", vdWRadius: 1.76),
    "CH3E": SKAminoAcidAtomType(element: "C", type: "Aliphatic C, Tetrahedral CH3", vdWRadius: 1.87),
    "SH1E": SKAminoAcidAtomType(element: "S", type: "All sulphurs, Cys S", vdWRadius: 1.85),
    "SM": SKAminoAcidAtomType(element: "S", type: "All sulphurs, Met S", vdWRadius: 1.85),
    "HOH": SKAminoAcidAtomType(element: "O", type: "Water", vdWRadius: 1.4),
  ]
}
