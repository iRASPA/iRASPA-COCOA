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
import SymmetryKit
import SimulationKit

// derive from AnyObject (class) to allow mutability
public protocol PrimitiveViewer: AnyObject
{
  var primitiveViewerRotationDelta: Double? {get set}
    
  var primitiveViewerObjects: [PrimitiveViewer] {get}
}

extension iRASPAObject: PrimitiveViewer
{
  public var primitiveViewerObjects: [PrimitiveViewer]
  {
    return self.allObjects.compactMap{$0 as? PrimitiveViewer}
  }
}

extension Movie: PrimitiveViewer
{
  public var primitiveViewerObjects: [PrimitiveViewer]
  {
    return self.allObjects.compactMap{$0 as? PrimitiveViewer}
  }
}

extension Scene: PrimitiveViewer
{
  public var primitiveViewerObjects: [PrimitiveViewer]
  {
    return self.allObjects.compactMap{$0 as? PrimitiveViewer}
  }
}

extension SceneList: PrimitiveViewer
{
  public var primitiveViewerObjects: [PrimitiveViewer]
  {
    return self.allObjects.compactMap{$0 as? PrimitiveViewer}
  }
}

extension Array where Iterator.Element == PrimitiveViewer
{
  public var primitiveViewerObjects: [PrimitiveViewer]
  {
    return self.compactMap{$0}
  }
  
  public var primitiveViewerRotationDelta: Double?
  {
    get
    {
      let origin: [Double] = self.primitiveViewerObjects.compactMap{return $0.primitiveViewerRotationDelta}
      return origin.isEmpty ? nil : origin.reduce(0.0){return $0 + $1} / Double(origin.count)
    }
    set(newValue)
    {
      self.primitiveViewerObjects.forEach{$0.primitiveViewerRotationDelta = newValue ?? 5.0}
    }
  }
}

extension PrimitiveViewer
{
  public var primitiveViewerRotationDelta: Double?
  {
    get
    {
      let origin: [Double] = self.primitiveViewerObjects.compactMap{return $0.primitiveViewerRotationDelta}
      return origin.isEmpty ? nil : origin.reduce(0.0){return $0 + $1} / Double(origin.count)
    }
    set(newValue)
    {
      self.primitiveViewerObjects.forEach{$0.primitiveViewerRotationDelta = newValue ?? 5.0}
    }
  }
}





