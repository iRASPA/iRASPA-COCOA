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

import Foundation
import RenderKit
import simd
import SymmetryKit
import SimulationKit

// MARK: -
// MARK: AdsorptionSurfaceVisualAppearanceViewer protocol implementation



extension AdsorptionSurfaceVisualAppearanceViewer
{
  public var renderMinimumGridEnergyValue: Float?
  {
    get
    {
      let set: Set<Float> = Set(self.structureViewerStructures.compactMap{ return ($0 as? RKRenderAdsorptionSurfaceSource)?.minimumGridEnergyValue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{($0 as? RKRenderAdsorptionSurfaceSource)?.minimumGridEnergyValue = newValue ?? 0.0}
    }
  }
  
  public var renderAdsorptionSurfaceOn: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.drawAdsorptionSurface })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.drawAdsorptionSurface = newValue ?? false}
    }
  }
  
  public var renderAdsorptionSurfaceOpacity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceOpacity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceOpacity = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceIsovalue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceIsoValue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceIsoValue = newValue ?? 0.0}
    }
  }
  
  
  
  public var renderAdsorptionSurfaceProbeMolecule: Structure.ProbeMolecule?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceProbeMolecule.rawValue })
      return Set(set).count == 1 ? Structure.ProbeMolecule(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceProbeMolecule = newValue ?? .helium}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideHDR = newValue ?? true}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideHDRExposure = newValue ?? 1.5}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideShininess = newValue ?? 4.0}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideAmbientColor = newValue ?? NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideDiffuseColor = newValue ?? NSColor(red: 0.588235, green: 0.670588, blue: 0.729412, alpha: 1.0)}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideHDR = newValue ?? true}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideHDRExposure = newValue ?? 1.5}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideShininess = newValue ?? 4.0}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideSpecularColor = newValue ?? NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideAmbientColor = newValue ?? NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideDiffuseColor = newValue ?? NSColor(red: 0.588235, green: 0.670588, blue: 0.729412, alpha: 1.0)}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideSpecularColor = newValue ?? NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)}
    }
  }
}

extension Array where Iterator.Element == AdsorptionSurfaceVisualAppearanceViewer
{
  public var structureViewerStructures: [Structure]
  {
    return self.flatMap{$0.structureViewerStructures}
  }
  
  public var renderCanDrawAdsorptionSurface: Bool
  {
    return self.reduce(into: false, {$0 = $0 || $1.renderCanDrawAdsorptionSurface})
  }
  
  public var selectedFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.selectedRenderFrames}
  }
  
  public var allFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.allFrames}
  }
  
  public var renderMinimumGridEnergyValue: Float?
  {
    get
    {
      let set: Set<Float> = Set(self.structureViewerStructures.compactMap{ return ($0 as? RKRenderAdsorptionSurfaceSource)?.minimumGridEnergyValue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{($0 as? RKRenderAdsorptionSurfaceSource)?.minimumGridEnergyValue = newValue ?? 0.0}
    }
  }
  
  public var renderAdsorptionSurfaceOn: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.drawAdsorptionSurface })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.drawAdsorptionSurface = newValue ?? false}
    }
  }
  
  public var renderAdsorptionSurfaceOpacity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceOpacity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceOpacity = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceIsovalue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceIsoValue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceIsoValue = newValue ?? 0.0}
    }
  }
  
  public var renderAdsorptionSurfaceProbeMolecule: Structure.ProbeMolecule?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceProbeMolecule.rawValue })
      return Set(set).count == 1 ? Structure.ProbeMolecule(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceProbeMolecule = newValue ?? .helium}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideHDR = newValue ?? true}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideHDRExposure = newValue ?? 1.5}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideShininess = newValue ?? 4.0}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideAmbientColor = newValue ?? NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideDiffuseColor = newValue ?? NSColor(red: 0.588235, green: 0.670588, blue: 0.729412, alpha: 1.0)}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideHDR = newValue ?? true}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideHDRExposure = newValue ?? 1.5}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideShininess = newValue ?? 4.0}
    }
  }
  
  public var renderAdsorptionSurfaceFrontSideSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceFrontSideSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceFrontSideSpecularColor = newValue ?? NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideAmbientColor = newValue ?? NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideDiffuseColor = newValue ?? NSColor(red: 0.588235, green: 0.670588, blue: 0.729412, alpha: 1.0)}
    }
  }
  
  public var renderAdsorptionSurfaceBackSideSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.adsorptionSurfaceBackSideSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.adsorptionSurfaceBackSideSpecularColor = newValue ?? NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)}
    }
  }
}




