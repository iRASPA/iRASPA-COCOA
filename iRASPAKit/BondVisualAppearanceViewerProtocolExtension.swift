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
import RenderKit
import simd
import SymmetryKit
import SimulationKit

// MARK: -
// MARK: BondVisualAppearanceViewer protocol implementation

extension BondVisualAppearanceViewer
{
  public func recheckRepresentationStyleBond()
  {
    self.allStructures.forEach{$0.recheckRepresentationStyle()}
  }
  
  public var renderDrawBonds: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.allStructures.compactMap{ return $0.drawBonds })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.drawBonds = newValue ?? true}
    }
  }
  
  public var renderBondScaleFactor: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondScaleFactor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{
        $0.bondScaleFactor = newValue ?? 1.0
        if($0.atomRepresentationType == .unity)
        {
          let asymmetricAtoms: [SKAsymmetricAtom] = $0.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
          asymmetricAtoms.forEach{$0.drawRadius = newValue ?? 1.0}
        }
      }
    }
  }
  
  public var renderBondColorMode: RKBondColorMode?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.bondColorMode.rawValue })
      return Set(set).count == 1 ? RKBondColorMode(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondColorMode = newValue ?? .split}
    }
  }
  
  public var renderBondAmbientOcclusion: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.allStructures.compactMap{ return $0.bondAmbientOcclusion })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondAmbientOcclusion = newValue ?? false}
    }
  }
  
  public var renderBondHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.allStructures.compactMap{ return $0.bondHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondHDR = newValue ?? false}
    }
  }
  
  public var renderBondHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondHDRExposure = newValue ?? 1.5}
    }
  }
  
  
  
  public var renderBondHue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondHue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondHue = newValue ?? 1.0}
    }
  }
  
  public var renderBondSaturation: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondSaturation })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondSaturation = newValue ?? 1.0}
    }
  }
  
  public var renderBondValue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondValue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondValue = newValue ?? 1.0}
    }
  }
  
  public var renderBondAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.bondAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondAmbientColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderBondDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.bondDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondDiffuseColor = newValue ?? NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)}
    }
  }
  
  public var renderBondSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.bondSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondSpecularColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderBondAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderBondDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderBondSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderBondShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondShininess = newValue ?? 4.0}
    }
  }
  
  public var renderBondSelectionStyle: RKSelectionStyle?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.bondSelectionStyle.rawValue })
      return Set(set).count == 1 ? RKSelectionStyle(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondSelectionStyle = newValue ?? .glow}
    }
  }
  
  public var renderBondSelectionFrequency: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderBondSelectionFrequency })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderBondSelectionFrequency = newValue ?? 4.0}
    }
  }
  
  public var renderBondSelectionDensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderBondSelectionDensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderBondSelectionDensity = newValue ?? 4.0}
    }
  }
  
  public var renderBondSelectionIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondSelectionIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondSelectionIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderBondSelectionScaling: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondSelectionScaling })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondSelectionScaling = newValue ?? 1.0}
    }
  }
}

extension Array where Iterator.Element == BondVisualAppearanceViewer
{
  public var allStructures: [Structure]
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
  
  public func recheckRepresentationStyleBond()
  {
    self.allStructures.forEach{$0.recheckRepresentationStyle()}
  }
  
  public var renderDrawBonds: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.allStructures.compactMap{ return $0.drawBonds })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.drawBonds = newValue ?? true}
    }
  }
  
  public var renderBondScaleFactor: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondScaleFactor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{
        $0.bondScaleFactor = newValue ?? 1.0
        if($0.atomRepresentationType == .unity)
        {
          let asymmetricAtoms: [SKAsymmetricAtom] = $0.atomTreeController.flattenedLeafNodes().compactMap{$0.representedObject}
          asymmetricAtoms.forEach{$0.drawRadius = newValue ?? 1.0}
        }
      }
    }
  }
  
  public var renderBondColorMode: RKBondColorMode?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.bondColorMode.rawValue })
      return Set(set).count == 1 ? RKBondColorMode(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondColorMode = newValue ?? .split}
    }
  }
  
  public var renderBondAmbientOcclusion: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.allStructures.compactMap{ return $0.bondAmbientOcclusion })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondAmbientOcclusion = newValue ?? false}
    }
  }
  
  public var renderBondHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.allStructures.compactMap{ return $0.bondHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondHDR = newValue ?? false}
    }
  }
  
  public var renderBondHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondHDRExposure = newValue ?? 1.5}
    }
  }
  
  public var renderBondHue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondHue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondHue = newValue ?? 1.0}
    }
  }
  
  public var renderBondSaturation: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondSaturation })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondSaturation = newValue ?? 1.0}
    }
  }
  
  public var renderBondValue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondValue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondValue = newValue ?? 1.0}
    }
  }
  
  public var renderBondAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.bondAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondAmbientColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderBondDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.bondDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondDiffuseColor = newValue ?? NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)}
    }
  }
  
  public var renderBondSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.bondSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondSpecularColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderBondAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderBondDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderBondSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderBondShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondShininess = newValue ?? 4.0}
    }
  }
  
  public var renderBondSelectionStyle: RKSelectionStyle?
  {
     get
     {
       let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.bondSelectionStyle.rawValue })
       return Set(set).count == 1 ? RKSelectionStyle(rawValue: set.first!) : nil
     }
     set(newValue)
     {
       self.allStructures.forEach{$0.bondSelectionStyle = newValue ?? .glow}
     }
   }
   
   public var renderBondSelectionFrequency: Double?
   {
     get
     {
       let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderBondSelectionFrequency })
       return Set(set).count == 1 ? set.first! : nil
     }
     set(newValue)
     {
       self.allStructures.forEach{$0.renderBondSelectionFrequency = newValue ?? 4.0}
     }
   }
   
   public var renderBondSelectionDensity: Double?
   {
     get
     {
       let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderBondSelectionDensity })
       return Set(set).count == 1 ? set.first! : nil
     }
     set(newValue)
     {
       self.allStructures.forEach{$0.renderBondSelectionDensity = newValue ?? 4.0}
     }
   }
  
  public var renderBondSelectionIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondSelectionIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.bondSelectionIntensity = newValue ?? 1.0}
    }
  }
   
   public var renderBondSelectionScaling: Double?
   {
     get
     {
       let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.bondSelectionScaling })
       return Set(set).count == 1 ? set.first! : nil
     }
     set(newValue)
     {
       self.allStructures.forEach{$0.bondSelectionScaling = newValue ?? 1.0}
     }
   }
   
}
