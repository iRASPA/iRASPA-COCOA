/*************************************************************************************************************
The MIT License

Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.

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

import Foundation
import simd
import MathKit
import SimulationKit
import SymmetryKit


public enum RKBackgroundType: Int
{
  case color = 0
  case linearGradient = 1
  case radialGradient = 2
  case image = 3
}

public enum RKBondColorMode: Int
{
  case uniform = 0
  case split = 1
  case smoothed_split = 2
}

public enum RKRenderQuality: Int
{
  case low = 0
  case medium = 1
  case high = 2
  case picture = 3
}

public enum RKImageQuality: Int
{
  case rgb_16_bits = 0
  case rgb_8_bits = 1
  case cmyk_16_bits = 2
  case cmyk_8_bits = 3
}

public enum RKSelectionStyle: Int
{
  case none = 0
  case WorleyNoise3D = 1
  case striped = 2
  case glow = 3
}

public enum RKTextStyle: Int
{
  case flatBillboard = 0
}

public enum RKTextEffect: Int
{
  case none = 0
  case glow = 1
  case pulsate = 2
  case squiggle = 3
}

public enum RKTextType: Int
{
  case none = 0
  case displayName = 1
  case identifier = 2
  case chemicalElement = 3
  case forceFieldType = 4
  case position = 5
  case charge = 6
}

public enum RKTextAlignment: Int
{
  case center = 0
  case left = 1
  case right = 2
  case top = 3
  case bottom = 4
  case topLeft = 5
  case topRight = 6
  case bottomLeft = 7
  case bottomRight = 8
}
