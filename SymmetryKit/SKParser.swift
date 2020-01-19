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

public class SKParser: NSObject
{
  public var scene: [[SKStructure]] = []
    
  public var unknownAtoms: Set<String> = []
  
  public func startParsing() throws
  {
    
  }
  
  /*
  var firstFrame: [(fractionalPosition: double3, type: Int)]
  {
    if let frame: Dictionary<String, Any> = scene.first?.first
    {
      let spaceGroupHallNumber: Int = (frame["spaceGroupHallNumber"] as? Int) ?? 1
      let spaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: spaceGroupHallNumber)
      
      var value: [(fractionalPosition: double3, type: Int)] = []
      if let atoms: [Dictionary<String,Any>] = frame["atoms"] as? [Dictionary<String,Any>]
      {
        for atom in atoms
        {
          if let position: double3 = atom["position"] as? double3,
             let atomicNumber: Int = atom["atomicNumber"] as? Int
          {
            let images: [double3] = spaceGroup.listOfSymmetricPositions(position)
            
            for image in images
            {
              value.append((fractionalPosition: image, type: atomicNumber))
            }
            
          }
        }
      }
      
      return value
    }
    return []
  }
  
  var firstFrameUnitCell: double3x3
  {
    if let frame: Dictionary<String, Any> = scene.first?.first,
       let cell = frame["cell"] as? (a: Double, b: Double, c: Double, alpha: Double, beta: Double, gamma: Double)
    {
       return SKSymmetryCell(a: cell.a, b: cell.b, c: cell.c, alpha: cell.alpha*180.0/Double.pi, beta: cell.beta*180.0/Double.pi, gamma: cell.gamma*180.0/Double.pi).unitCell
    }
    return double3x3()
  }*/
}
