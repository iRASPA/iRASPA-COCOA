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
import RenderKit
import simd
import SymmetryKit
import SimulationKit

// MARK: -
// MARK: UnitCellVisualAppearanceViewer protocol implementation

extension UnitCellVisualAppearanceViewer
{
  public var renderDrawUnitCell: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.allStructures.compactMap{ return $0.drawUnitCell })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.drawUnitCell = newValue ?? false}
    }
  }
  
  public var renderUnitCellScaleFactor: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.unitCellScaleFactor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.unitCellScaleFactor = newValue ?? 1.0}
    }
  }
  
  public var renderUnitCellDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.unitCellDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.unitCellDiffuseColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderUnitCellDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.unitCellDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.unitCellDiffuseIntensity = newValue ?? 1.0}
    }
  }
}

extension Array where Iterator.Element == UnitCellVisualAppearanceViewer
{
  public var allStructures: [Object]
  {
    return self.flatMap{$0.allStructures}
  }
  
  public var selectedFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.selectedRenderFrames}
  }
  
  public var allRenderFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.allRenderFrames}
  }
  
  public var renderDrawUnitCell: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.allStructures.compactMap{ return $0.drawUnitCell })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.drawUnitCell = newValue ?? false}
    }
  }
  
  public var renderUnitCellScaleFactor: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.unitCellScaleFactor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.unitCellScaleFactor = newValue ?? 1.0}
    }
  }
  
  public var renderUnitCellDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.unitCellDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.unitCellDiffuseColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderUnitCellDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.unitCellDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.unitCellDiffuseIntensity = newValue ?? 1.0}
    }
  }
}

