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

public struct SKParserError
{
  public static var domain = "nl.darkwing.iRASPA"
  
  public enum code: Int
  {
    case failedDecoding
    case containsNoData
    case incorrectFileFormatVTK
    case unknownDataType
    case MissingCellParameters
    
    case VTKMustBeStructuredPoints
    case VTKMissingDimensions
    case VTKMissingPointData
    
    case VASPMissingScaleFactor
    
    case MolecularOrbitalOutputNotSupported
  }
  
  public static let failedDecoding: NSError = NSError.init(domain: SKParserError.domain, code: SKParserError.code.failedDecoding.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Failed UTF-8 and ASCII decoding", bundle: Bundle(for: SKParser.self), comment: "")])
  public static let containsNoData: NSError = NSError.init(domain: SKParserError.domain, code: SKParserError.code.containsNoData.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Contains no data", bundle: Bundle(for: SKParser.self), comment: "")])
  public static let incorrectFileFormatVTK: NSError = NSError.init(domain: SKParserError.domain, code: SKParserError.code.incorrectFileFormatVTK.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Not a VTK file", bundle: Bundle(for: SKParser.self), comment: "")])
  public static let MissingCellParameters: NSError = NSError.init(domain: SKParserError.domain, code: SKParserError.code.MissingCellParameters.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Missing cell-parameters", bundle: Bundle(for: SKParser.self), comment: "")])
  public static let unknownDataType: NSError = NSError.init(domain: SKParserError.domain, code: SKParserError.code.unknownDataType.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Unknown data type", bundle: Bundle(for: SKParser.self), comment: "")])
  
  public static let VTKMustBeStructuredPoints: NSError = NSError.init(domain: SKParserError.domain, code: SKParserError.code.VTKMustBeStructuredPoints.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("VTK file must be of type StructuredPoints", bundle: Bundle(for: SKParser.self), comment: "")])
  public static let VTKMissingDimensions: NSError = NSError.init(domain: SKParserError.domain, code: SKParserError.code.VTKMissingDimensions.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("VTK missing dimensions", bundle: Bundle(for: SKParser.self), comment: "")])
  public static let VTKMissingPointData: NSError = NSError.init(domain: SKParserError.domain, code: SKParserError.code.VTKMissingPointData.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("VTK missing point data", bundle: Bundle(for: SKParser.self), comment: "")])
 
  public static let VASPMissingScaleFactor: NSError = NSError.init(domain: SKParserError.domain, code: SKParserError.code.VASPMissingScaleFactor.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("VTK missing scale factor", bundle: Bundle(for: SKParser.self), comment: "")])
  
  
  public static let MolecularOrbitalOutputNotSupported: NSError = NSError.init(domain: SKParserError.domain, code: SKParserError.code.MolecularOrbitalOutputNotSupported.rawValue, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Molecular Orbital Input not supported", bundle: Bundle(for: SKParser.self), comment: "")])
}
