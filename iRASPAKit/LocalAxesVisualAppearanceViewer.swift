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
// MARK: LocalAxesVisualAppearanceViewer protocol implementation

//var renderLocalAxesPosition: RKLocalAxes.Position? {get set}
//var renderLocalAxesStyle: RKLocalAxes.Style? {get set}
//var renderLocalAxesScalingType: RKLocalAxes.ScalingType? {get set}
//var renderLocalAxesLength: Double? {get set}
//var renderLocalAxesWidth: Double? {get set}
//var renderLocalAxesOffsetX: Double? {get set}
//var renderLocalAxesOffsetY: Double? {get set}
//var renderLocalAxesOffsetZ: Double? {get set}


extension LocalAxesVisualAppearanceViewer
{
  public var renderLocalAxesPosition: RKLocalAxes.Position?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.position.rawValue })
      return Set(set).count == 1 ? RKLocalAxes.Position(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.position = newValue ?? .none}
    }
  }
  
  public var renderLocalAxesStyle: RKLocalAxes.Style?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.style.rawValue })
      return Set(set).count == 1 ? RKLocalAxes.Style(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.style = newValue ?? .default}
    }
  }
  
  public var renderLocalAxesScalingType: RKLocalAxes.ScalingType?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.scalingType.rawValue })
      return Set(set).count == 1 ? RKLocalAxes.ScalingType(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.scalingType = newValue ?? .absolute}
    }
  }
  
  public var renderLocalAxesLength: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.length })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.length = newValue ?? 5.0}
    }
  }
  
  public var renderLocalAxesWidth: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.width })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.width = newValue ?? 5.0}
    }
  }
  
  public var renderLocalAxesOffsetX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.offset.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.offset.x = newValue ?? 5.0}
    }
  }
  
  public var renderLocalAxesOffsetY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.offset.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.offset.y = newValue ?? 5.0}
    }
  }
  
  public var renderLocalAxesOffsetZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.offset.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.offset.z = newValue ?? 5.0}
    }
  }
}

extension Array where Iterator.Element == LocalAxesVisualAppearanceViewer
{
  public var selectedFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.selectedRenderFrames}
  }
  
  public var allRenderFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.allRenderFrames}
  }
  
  public var allStructures: [Structure]
  {
    return self.flatMap{$0.allStructures}
  }
  
  public var renderLocalAxesPosition: RKLocalAxes.Position?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.position.rawValue })
      return Set(set).count == 1 ? RKLocalAxes.Position(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.position = newValue ?? .none}
    }
  }
  
  public var renderLocalAxesStyle: RKLocalAxes.Style?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.style.rawValue })
      return Set(set).count == 1 ? RKLocalAxes.Style(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.style = newValue ?? .default}
    }
  }
  
  public var renderLocalAxesScalingType: RKLocalAxes.ScalingType?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.scalingType.rawValue })
      return Set(set).count == 1 ? RKLocalAxes.ScalingType(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.scalingType = newValue ?? .absolute}
    }
  }
  
  public var renderLocalAxesLength: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.length })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.length = newValue ?? 5.0}
    }
  }
  
  public var renderLocalAxesWidth: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.width })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.width = newValue ?? 5.0}
    }
  }
  
  public var renderLocalAxesOffsetX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.offset.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.offset.x = newValue ?? 5.0}
    }
  }
  
  public var renderLocalAxesOffsetY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.offset.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.offset.y = newValue ?? 5.0}
    }
  }
  
  public var renderLocalAxesOffsetZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderLocalAxis.offset.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderLocalAxis.offset.z = newValue ?? 5.0}
    }
  }
}
