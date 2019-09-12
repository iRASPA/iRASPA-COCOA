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
import MathKit
import simd

struct SKTransformationMatrix
{
  var numerator: int3x3
  var denominator: Int = 1
  
  // S.R. Hall, "Space-group notation with an explicit origin", Acta. Cryst. A, 37, 517-525, 981
  
  public static let zero: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0),SIMD3<Int32>(0,0,0)])
  public static let identity: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,1)])
  public static let inversionIdentity: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(0,0,-1)])
  
  // rotations for principle axes
  public static let r_2_100: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(0,0,-1)])
  public static let r_2i_100: SKTransformationMatrix = r_2_100
  public static let r_3_100: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,0,1),SIMD3<Int32>(0,-1,-1)])
  public static let r_3i_100: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,-1,-1),SIMD3<Int32>(0,1,0)])
  public static let r_4_100: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,0,1),SIMD3<Int32>(0,-1,0)])
  public static let r_4i_100: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,0,-1),SIMD3<Int32>(0,1,0)])
  public static let r_6_100: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,1),SIMD3<Int32>(0,-1,0)])
  public static let r_6i_100: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,0,-1),SIMD3<Int32>(0,1,1)])
  
  public static let r_2_010: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,-1)])
  public static let r_2i_010: SKTransformationMatrix = r_2_010
  public static let r_3_010: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1,0,-1),SIMD3<Int32>(0,1,0),SIMD3<Int32>(1,0,0)])
  public static let r_3i_010: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,0,1),SIMD3<Int32>(0,1,0),SIMD3<Int32>(-1,0,-1)])
  public static let r_4_010: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,0,-1),SIMD3<Int32>(0,1,0),SIMD3<Int32>(1,0,0)])
  public static let r_4i_010: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,0,1),SIMD3<Int32>(0,1,0),SIMD3<Int32>(-1,0,0)])
  public static let r_6_010: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,0,-1),SIMD3<Int32>(0,1,0),SIMD3<Int32>(1,0,1)])
  public static let r_6i_010: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1,0,1),SIMD3<Int32>(0,1,0),SIMD3<Int32>(-1,0,0)])
  
  public static let r_2_001: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(0,0,1)])
  public static let r_2i_001: SKTransformationMatrix = r_2_001
  public static let r_3_001: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,1,0),SIMD3<Int32>(-1,-1,0),SIMD3<Int32>(0,0,1)])
  public static let r_3i_001: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1,-1,0),SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,0,1)])
  public static let r_4_001: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,1,0),SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,0,1)])
  public static let r_4i_001: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,-1,0),SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,0,1)])
  public static let r_6_001: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(1,1,0),SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,0,1)])
  public static let r_6i_001: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,-1,0),SIMD3<Int32>(1,1,0),SIMD3<Int32>(0,0,1)])
  
  public static let r_3_111: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,1,0),SIMD3<Int32>(0,0,1),SIMD3<Int32>(1,0,0)])
  public static let r_3i_111: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,0,1),SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,1,0)])
  
  public static let r_2prime_100: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,0,-1),SIMD3<Int32>(0,-1,0)])   // b-c
  public static let r_2iprime_100: SKTransformationMatrix = r_2prime_100
  public static let r_2doubleprime_100: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,0,1),SIMD3<Int32>(0,1,0)]) // b+c
  public static let r_2idoubleprime_100: SKTransformationMatrix = r_2doubleprime_100
  
  public static let r_2prime_010: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,0,-1),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(-1,0,0)]) // a-c
  public static let r_2iprime_010: SKTransformationMatrix = r_2prime_010
  public static let r_2doubleprime_010: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,0,1),SIMD3<Int32>(0,-1,0),SIMD3<Int32>(1,0,0)]) // a+c
  public static let r_2idoubleprime_010: SKTransformationMatrix = r_2doubleprime_010
  
  public static let r_2prime_001: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,-1,0),SIMD3<Int32>(-1,0,0),SIMD3<Int32>(0,0,-1)]) // a-b
  public static let r_2iprime_001: SKTransformationMatrix = r_2prime_001
  public static let r_2doubleprime_001: SKTransformationMatrix = SKTransformationMatrix([SIMD3<Int32>(0,1,0),SIMD3<Int32>(1,0,0),SIMD3<Int32>(0,0,-1)]) // a+b
  public static let r_2idoubleprime_001: SKTransformationMatrix = r_2doubleprime_001
  
  init(_ numerator: [SIMD3<Int32>], denomerator: Int = 1)
  {
    self.numerator = int3x3(numerator)
    self.denominator = denomerator
  }
}
