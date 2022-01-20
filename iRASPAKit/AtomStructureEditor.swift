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

import Foundation
import simd
import RenderKit
import SymmetryKit
import SimulationKit

public protocol AtomStructureEditor: AnyObject
{
  func recheckRepresentationStyle()
  
  func getRepresentationType() -> Structure.RepresentationType?
  func setRepresentationType(type: Structure.RepresentationType?)
  
  func getRepresentationStyle() -> Structure.RepresentationStyle?
  func setRepresentationStyle(style: Structure.RepresentationStyle?, colorSets: SKColorSets)
  
  func getRepresentationColorScheme() -> String?
  func setRepresentationColorScheme(scheme: String?, colorSets: SKColorSets)
  
  func getRepresentationColorOrder() -> SKColorSets.ColorOrder?
  func setRepresentationColorOrder(order: SKColorSets.ColorOrder?, colorSets: SKColorSets)
  
  func getRepresentationForceField() -> String?
  func setRepresentationForceField(forceField: String?, forceFieldSets: SKForceFieldSets)
  
  func getRepresentationForceFieldOrder() -> SKForceFieldSets.ForceFieldOrder?
  func setRepresentationForceFieldOrder(order: SKForceFieldSets.ForceFieldOrder?, forceFieldSets: SKForceFieldSets)
  
 
  var drawAtoms: Bool {get set}
  
  var atomHue: Double {get set}
  var atomSaturation: Double {get set}
  var atomValue: Double {get set}
  var atomScaleFactor: Double {get set}
  
  var atomAmbientOcclusion: Bool {get set}
  var atomHDR: Bool {get set}
  var atomHDRExposure: Double {get set}
  
  var atomAmbientColor: NSColor {get set}
  var atomDiffuseColor: NSColor {get set}
  var atomSpecularColor: NSColor {get set}
  var atomAmbientIntensity: Double {get set}
  var atomDiffuseIntensity: Double {get set}
  var atomSpecularIntensity: Double {get set}
  var atomShininess: Double {get set}
  
  var atomSelectionStyle: RKSelectionStyle {get set}
  var renderAtomSelectionFrequency: Double {get set}
  var renderAtomSelectionDensity: Double {get set}
  var atomSelectionIntensity: Double {get set}
  var atomSelectionScaling: Double {get set}
}
