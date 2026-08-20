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

import Foundation
import simd

public enum ProteinRibbonColorSet: String, CaseIterable, Sendable
{
  case standardAcademic = "Standard Academic"
  case modernUI = "Modern UI"
  case biophysicalProperties = "Biophysical Properties"
  case infographic = "Infographic"
  
  public var displayName: String
  {
    return self.rawValue
  }
  
  public var coilColor: SIMD3<Float>
  {
    switch self
    {
    case .standardAcademic: return SIMD3<Float>(0.0, 1.0, 0.0)
    case .modernUI: return SIMD3<Float>(0.25, 0.27, 0.30)
    case .biophysicalProperties: return SIMD3<Float>(1.0, 0.2, 0.6)
    case .infographic: return SIMD3<Float>(0.85, 0.75, 0.60)
    }
  }
  
  public var helixColor: SIMD3<Float>
  {
    switch self
    {
    case .standardAcademic: return SIMD3<Float>(1.0, 0.0, 1.0)
    case .modernUI: return SIMD3<Float>(0.0, 0.55, 0.65)
    case .biophysicalProperties: return SIMD3<Float>(0.05, 0.25, 0.65)
    case .infographic: return SIMD3<Float>(0.75, 0.65, 0.90)
    }
  }
  
  public var sheetColor: SIMD3<Float>
  {
    switch self
    {
    case .standardAcademic: return SIMD3<Float>(1.0, 1.0, 0.0)
    case .modernUI: return SIMD3<Float>(0.95, 0.60, 0.15)
    case .biophysicalProperties: return SIMD3<Float>(0.40, 0.75, 1.0)
    case .infographic: return SIMD3<Float>(0.60, 0.90, 0.75)
    }
  }
  
  public func color(for structure: ProteinRibbonSecondaryStructure) -> SIMD3<Float>
  {
    switch structure
    {
    case .coil: return coilColor
    case .helix: return helixColor
    case .sheet: return sheetColor
    }
  }
}
