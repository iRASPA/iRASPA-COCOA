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
// MARK: AtomVisualAppearanceViewer protocol implementation

extension AtomVisualAppearanceViewer
{
  public func recheckRepresentationStyle()
  {
    self.structureViewerStructures.forEach{$0.recheckRepresentationStyle()}
  }
  
  public func getRepresentationType() -> Structure.RepresentationType?
  {
    let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.getRepresentationType()?.rawValue })
    return Set(set).count == 1 ? Structure.RepresentationType(rawValue: set.first!) : nil
  }
  
  public func setRepresentationType(type: Structure.RepresentationType?)
  {
    self.structureViewerStructures.forEach{$0.setRepresentationType(type: type)}
  }
  
  
  public func getRepresentationStyle() -> Structure.RepresentationStyle?
  {
    let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.getRepresentationStyle()?.rawValue })
    return Set(set).count == 1 ? Structure.RepresentationStyle(rawValue: set.first!) : nil
  }
  
  public func setRepresentationStyle(style: Structure.RepresentationStyle?, colorSets: SKColorSets)
  {
    self.structureViewerStructures.forEach{$0.setRepresentationStyle(style: style, colorSets: colorSets)}
  }
  
  public func getRepresentationColorScheme() -> String?
  {
    let set: Set<String> = Set(self.structureViewerStructures.compactMap{ return $0.getRepresentationColorScheme() })
    return Set(set).count == 1 ?  set.first! : nil
  }
  
  public func setRepresentationColorScheme(scheme: String?, colorSets: SKColorSets)
  {
  self.structureViewerStructures.forEach{$0.setRepresentationColorScheme(scheme: scheme ?? "Default", colorSets: colorSets)}
  }
  
  public func getRepresentationColorOrder() -> SKColorSets.ColorOrder?
  {
    let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.getRepresentationColorOrder()?.rawValue })
    return Set(set).count == 1 ?  SKColorSets.ColorOrder(rawValue: set.first!) : nil
  }
  
  public func setRepresentationColorOrder(order: SKColorSets.ColorOrder?, colorSets: SKColorSets)
  {
    self.structureViewerStructures.forEach{$0.setRepresentationColorOrder(order: order ?? SKColorSets.ColorOrder.elementOnly, colorSets: colorSets)}
  }
  
  public func getRepresentationForceField() -> String?
  {
    let set: Set<String> = Set(self.structureViewerStructures.compactMap{ return $0.getRepresentationForceField() })
      return Set(set).count == 1 ?  set.first! : nil
  }
  
  public func setRepresentationForceField(forceField: String?, forceFieldSets: SKForceFieldSets)
  {
    self.structureViewerStructures.forEach{$0.setRepresentationForceField(forceField: forceField ?? "Default", forceFieldSets: forceFieldSets)}
  }
  
  public func getRepresentationForceFieldOrder() -> SKForceFieldSets.ForceFieldOrder?
  {
    let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.getRepresentationForceFieldOrder()?.rawValue })
    return Set(set).count == 1 ?  SKForceFieldSets.ForceFieldOrder(rawValue: set.first!) : nil
  }
  
  public func setRepresentationForceFieldOrder(order: SKForceFieldSets.ForceFieldOrder?, forceFieldSets: SKForceFieldSets)
  {
    self.structureViewerStructures.forEach{$0.setRepresentationForceFieldOrder(order: order, forceFieldSets: forceFieldSets)}
  }
  
  public var renderAtomHue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomHue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomHue = newValue ?? 1.0}
    }
  }
  
  public var renderAtomSaturation: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomSaturation })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomSaturation = newValue ?? 1.0}
    }
  }
  
  public var renderAtomValue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomValue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomValue = newValue ?? 1.0}
    }
  }
  
  public var renderAtomScaleFactor: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomScaleFactor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomScaleFactor = newValue ?? 1.0}
    }
  }
  
  public var renderDrawAtoms: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.drawAtoms })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.drawAtoms = newValue ?? true}
    }
  }
  
  public var renderAtomAmbientOcclusion: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.atomAmbientOcclusion })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomAmbientOcclusion = newValue ?? true}
    }
  }
  
  public var renderAtomHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.atomHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomHDR = newValue ?? true}
    }
  }
  
  
  public var renderAtomHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomHDRExposure = newValue ?? 1.0}
    }
  }
  
  public var renderAtomHDRBloomLevel: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomHDRBloomLevel })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomHDRBloomLevel = newValue ?? 1.0}
    }
  }
  
  public var renderSelectionScaling: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.selectionScaling })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.selectionScaling = newValue ?? 1.0}
    }
  }
  
  public var renderAtomAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.atomAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomAmbientColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderAtomDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.atomDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomDiffuseColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderAtomSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.atomSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomSpecularColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  
  public var renderAtomAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderAtomDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAtomSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAtomShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomShininess = newValue ?? 4.0}
    }
  }
  
  public var renderSelectionStyle: RKSelectionStyle?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.renderSelectionStyle.rawValue })
      return Set(set).count == 1 ? RKSelectionStyle(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.renderSelectionStyle = newValue ?? .glow}
    }
  }
  
  public var renderSelectionFrequency: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.renderAtomSelectionFrequency })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.renderAtomSelectionFrequency = newValue ?? 4.0}
    }
  }
  
  public var renderSelectionDensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.renderAtomSelectionDensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.renderAtomSelectionDensity = newValue ?? 4.0}
    }
  }
  
  public var renderTextType: RKTextType?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.renderTextType.rawValue })
      return Set(set).count == 1 ? RKTextType(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.renderTextType = newValue ?? .none}
    }
  }
  
  public var renderTextStyle: RKTextStyle?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextStyle.rawValue })
      return Set(set).count == 1 ? RKTextStyle(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextStyle = newValue ?? .flatBillboard}
    }
  }
  
  public var renderTextAlignment: RKTextAlignment?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextAlignment.rawValue })
      return Set(set).count == 1 ? RKTextAlignment(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextAlignment = newValue ?? .center}
    }
  }
  
  public var renderTextFont: String?
  {
    get
    {
      let set: Set<String> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextFont })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextFont = newValue ?? "Helvetica"}
    }
  }
  
  public var renderTextFontFamily: String?
  {
    get
    {
      let set: Set<String> = Set(self.structureViewerStructures.compactMap({ (structure) -> String? in
        if let font: NSFont = NSFont(name: structure.atomTextFont, size: 32)
        {
          return font.familyName
        }
        return nil
      }))
      return Set(set).count == 1 ? set.first! : nil
    }
  }
  
  public var renderTextColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextColor = newValue ?? NSColor.black}
    }
  }
  
  public var renderTextScaling: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextScaling })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextScaling = newValue ?? 1.0}
    }
  }
  
  public var renderTextOffsetX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextOffset.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextOffset.x = newValue ?? 0}
    }
  }
  
  public var renderTextOffsetY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextOffset.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextOffset.y = newValue ?? 0}
    }
  }
  
  public var renderTextOffsetZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextOffset.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextOffset.z = newValue ?? 0}
    }
  }
}

extension Array where Iterator.Element == AtomVisualAppearanceViewer
{
  public var selectedFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.selectedRenderFrames}
  }
  
  public var allFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.allFrames}
  }
  
  public var structureViewerStructures: [Structure]
  {
    return self.flatMap{$0.structureViewerStructures}
  }
  
  public func recheckRepresentationStyle()
  {
    self.structureViewerStructures.forEach{$0.recheckRepresentationStyle()}
  }
  
  public func getRepresentationType() -> Structure.RepresentationType?
  {
    let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.getRepresentationType()?.rawValue })
    return Set(set).count == 1 ? Structure.RepresentationType(rawValue: set.first!) : nil
  }
  
  public func setRepresentationType(type: Structure.RepresentationType?)
  {
    self.structureViewerStructures.forEach{$0.setRepresentationType(type: type)}
  }
  
  public func getRepresentationStyle() -> Structure.RepresentationStyle?
  {
    let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.getRepresentationStyle()?.rawValue })
    return Set(set).count == 1 ? Structure.RepresentationStyle(rawValue: set.first!) : nil
  }
  
  public func setRepresentationStyle(style: Structure.RepresentationStyle?, colorSets: SKColorSets)
  {
    self.structureViewerStructures.forEach{$0.setRepresentationStyle(style: style, colorSets: colorSets)}
  }
  
  public func getRepresentationColorScheme() -> String?
  {
    let set: Set<String> = Set(self.structureViewerStructures.compactMap{ return $0.getRepresentationColorScheme() })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public func setRepresentationColorScheme(scheme: String?, colorSets: SKColorSets)
  {
    self.structureViewerStructures.forEach{$0.setRepresentationColorScheme(scheme: scheme ?? SKColorSets.ColorScheme.jmol.rawValue, colorSets: colorSets)}
  }
  
  public func getRepresentationColorOrder() -> SKColorSets.ColorOrder?
  {
    let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.getRepresentationColorOrder()?.rawValue })
    return Set(set).count == 1 ? SKColorSets.ColorOrder(rawValue: set.first!) : nil
  }
  
  public func setRepresentationColorOrder(order: SKColorSets.ColorOrder?, colorSets: SKColorSets)
  {
    self.structureViewerStructures.forEach{$0.setRepresentationColorOrder(order: order, colorSets: colorSets)}
  }
  
  public func getRepresentationForceField() -> String?
  {
    let set: Set<String> = Set(self.structureViewerStructures.compactMap{ return $0.getRepresentationForceField() })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public func setRepresentationForceField(forceField: String?, forceFieldSets: SKForceFieldSets)
  {
    self.structureViewerStructures.forEach{$0.setRepresentationForceField(forceField: forceField ?? "Default", forceFieldSets: forceFieldSets)}
  }
  
  public func getRepresentationForceFieldOrder() -> SKForceFieldSets.ForceFieldOrder?
  {
    let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.getRepresentationForceFieldOrder()?.rawValue })
    return Set(set).count == 1 ? SKForceFieldSets.ForceFieldOrder(rawValue: set.first!) : nil
  }
  
  public func setRepresentationForceFieldOrder(order: SKForceFieldSets.ForceFieldOrder?, forceFieldSets: SKForceFieldSets)
  {
    self.structureViewerStructures.forEach{$0.setRepresentationForceFieldOrder(order: order, forceFieldSets: forceFieldSets)}
  }
  
  public var renderAtomHue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomHue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomHue = newValue ?? 1.0}
    }
  }
  
  public var renderAtomSaturation: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomSaturation })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomSaturation = newValue ?? 1.0}
    }
  }
  
  public var renderAtomValue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomValue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomValue = newValue ?? 1.0}
    }
  }
  
  public var renderAtomScaleFactor: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomScaleFactor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomScaleFactor = newValue ?? 1.0}
    }
  }
  
  public var renderDrawAtoms: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.drawAtoms })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.drawAtoms = newValue ?? true}
    }
  }
  
  public var renderAtomAmbientOcclusion: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.atomAmbientOcclusion })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomAmbientOcclusion = newValue ?? true}
    }
  }
  
  public var renderAtomHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.atomHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomHDR = newValue ?? true}
    }
  }
  
  
  public var renderAtomHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomHDRExposure = newValue ?? 1.5}
    }
  }
  
  public var renderAtomHDRBloomLevel: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomHDRBloomLevel })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomHDRBloomLevel = newValue ?? 1.0}
    }
  }
  
  public var renderSelectionScaling: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.selectionScaling })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.selectionScaling = newValue ?? 1.0}
    }
  }
  
  public var renderAtomAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.atomAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomAmbientColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderAtomDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.atomDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomDiffuseColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderAtomSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.atomSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomSpecularColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  
  public var renderAtomAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderAtomDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAtomSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAtomShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomShininess = newValue ?? 4.0}
    }
  }
  
  public var renderSelectionStyle: RKSelectionStyle?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.renderSelectionStyle.rawValue })
      return Set(set).count == 1 ? RKSelectionStyle(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.renderSelectionStyle = newValue ?? .glow}
    }
  }
  
  public var renderSelectionFrequency: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.renderAtomSelectionFrequency })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.renderAtomSelectionFrequency = newValue ?? 4.0}
    }
  }
  
  public var renderSelectionDensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.renderAtomSelectionDensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.renderAtomSelectionDensity = newValue ?? 4.0}
    }
  }
  
  public var renderTextType: RKTextType?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.renderTextType.rawValue })
      return Set(set).count == 1 ? RKTextType(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.renderTextType = newValue ?? .none}
    }
  }
  
  public var renderTextStyle: RKTextStyle?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextStyle.rawValue })
      return Set(set).count == 1 ? RKTextStyle(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextStyle = newValue ?? .flatBillboard}
    }
  }
  
  public var renderTextAlignment: RKTextAlignment?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextAlignment.rawValue })
      return Set(set).count == 1 ? RKTextAlignment(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextAlignment = newValue ?? .center}
    }
  }
  
  public var renderTextFont: String?
  {
    get
    {
      let set: Set<String> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextFont })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextFont = newValue ?? "Helvetica"}
    }
  }
  
  public var renderTextFontFamily: String?
  {
    get
    {
      let set: Set<String> = Set(self.structureViewerStructures.compactMap({ (structure) -> String? in
        if let font: NSFont = NSFont(name: structure.atomTextFont, size: 32)
        {
          return font.familyName
        }
        return nil
      }))
      return Set(set).count == 1 ? set.first! : nil
    }
  }
  
  
  
  
  public var renderTextColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextColor = newValue ?? NSColor.black}
    }
  }
  
  public var renderTextScaling: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextScaling })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextScaling = newValue ?? 1.0}
    }
  }
  
  public var renderTextOffsetX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextOffset.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextOffset.x = newValue ?? 0}
    }
  }
  
  public var renderTextOffsetY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextOffset.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextOffset.y = newValue ?? 0}
    }
  }
  
  public var renderTextOffsetZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.atomTextOffset.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.atomTextOffset.z = newValue ?? 0}
    }
  }
}


// MARK: -
// MARK: BondVisualAppearanceViewer protocol implementation

extension BondVisualAppearanceViewer
{
  public func recheckRepresentationStyleBond()
  {
    self.structureViewerStructures.forEach{$0.recheckRepresentationStyle()}
  }
  
  public var renderDrawBonds: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.drawBonds })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.drawBonds = newValue ?? true}
    }
  }
  
  public var renderBondScaleFactor: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondScaleFactor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondScaleFactor = newValue ?? 1.0}
    }
  }
  
  public var renderBondColorMode: RKBondColorMode?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.bondColorMode.rawValue })
      return Set(set).count == 1 ? RKBondColorMode(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondColorMode = newValue ?? .split}
    }
  }
  
  public var renderBondAmbientOcclusion: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.bondAmbientOcclusion })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondAmbientOcclusion = newValue ?? false}
    }
  }
  
  public var renderBondHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.bondHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondHDR = newValue ?? false}
    }
  }
  
  public var renderBondHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondHDRExposure = newValue ?? 1.5}
    }
  }
  
  public var renderBondHDRBloomLevel: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondHDRBloomLevel })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondHDRBloomLevel = newValue ?? 1.0}
    }
  }
  
  public var renderBondHue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondHue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondHue = newValue ?? 1.0}
    }
  }
  
  public var renderBondSaturation: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondSaturation })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondSaturation = newValue ?? 1.0}
    }
  }
  
  public var renderBondValue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondValue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondValue = newValue ?? 1.0}
    }
  }
  
  public var renderBondAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.bondAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondAmbientColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderBondDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.bondDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondDiffuseColor = newValue ?? NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)}
    }
  }
  
  public var renderBondSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.bondSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondSpecularColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderBondAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderBondDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderBondSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderBondShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondShininess = newValue ?? 4.0}
    }
  }
}

extension Array where Iterator.Element == BondVisualAppearanceViewer
{
  public var structureViewerStructures: [Structure]
  {
    return self.flatMap{$0.structureViewerStructures}
  }
  
  public var selectedFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.selectedRenderFrames}
  }
  
  public var allFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.allFrames}
  }
  
  public func recheckRepresentationStyleBond()
  {
    self.structureViewerStructures.forEach{$0.recheckRepresentationStyle()}
  }
  
  public var renderDrawBonds: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.drawBonds })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.drawBonds = newValue ?? true}
    }
  }
  
  public var renderBondScaleFactor: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondScaleFactor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondScaleFactor = newValue ?? 1.0}
    }
  }
  
  public var renderBondColorMode: RKBondColorMode?
  {
    get
    {
      let set: Set<Int> = Set(self.structureViewerStructures.compactMap{ return $0.bondColorMode.rawValue })
      return Set(set).count == 1 ? RKBondColorMode(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondColorMode = newValue ?? .split}
    }
  }
  
  public var renderBondAmbientOcclusion: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.bondAmbientOcclusion })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondAmbientOcclusion = newValue ?? false}
    }
  }
  
  public var renderBondHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.bondHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondHDR = newValue ?? false}
    }
  }
  
  public var renderBondHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondHDRExposure = newValue ?? 1.5}
    }
  }
  
  public var renderBondHDRBloomLevel: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondHDRBloomLevel })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondHDRBloomLevel = newValue ?? 1.0}
    }
  }
  
  public var renderBondHue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondHue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondHue = newValue ?? 1.0}
    }
  }
  
  public var renderBondSaturation: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondSaturation })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondSaturation = newValue ?? 1.0}
    }
  }
  
  public var renderBondValue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondValue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondValue = newValue ?? 1.0}
    }
  }
  
  public var renderBondAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.bondAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondAmbientColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderBondDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.bondDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondDiffuseColor = newValue ?? NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)}
    }
  }
  
  public var renderBondSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.bondSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondSpecularColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderBondAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderBondDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderBondSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderBondShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.bondShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.bondShininess = newValue ?? 4.0}
    }
  }
}




// MARK: -
// MARK: UnitCellVisualAppearanceViewer protocol implementation

extension UnitCellVisualAppearanceViewer
{
  public var renderDrawUnitCell: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.drawUnitCell })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.drawUnitCell = newValue ?? false}
    }
  }
  
  public var renderUnitCellScaleFactor: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCellScaleFactor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.unitCellScaleFactor = newValue ?? 1.0}
    }
  }
  
  public var renderUnitCellDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.unitCellDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.unitCellDiffuseColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderUnitCellDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCellDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.unitCellDiffuseIntensity = newValue ?? 1.0}
    }
  }
}

extension Array where Iterator.Element == UnitCellVisualAppearanceViewer
{
  public var structureViewerStructures: [Structure]
  {
    return self.flatMap{$0.structureViewerStructures}
  }
  
  public var selectedFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.selectedRenderFrames}
  }
  
  public var allFrames: [RKRenderStructure]
  {
    return self.flatMap{$0.allFrames}
  }
  
  public var renderDrawUnitCell: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.structureViewerStructures.compactMap{ return $0.drawUnitCell })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.drawUnitCell = newValue ?? false}
    }
  }
  
  public var renderUnitCellScaleFactor: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCellScaleFactor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.unitCellScaleFactor = newValue ?? 1.0}
    }
  }
  
  public var renderUnitCellDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.structureViewerStructures.compactMap{ return $0.unitCellDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.unitCellDiffuseColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderUnitCellDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.structureViewerStructures.compactMap{ return $0.unitCellDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{$0.unitCellDiffuseIntensity = newValue ?? 1.0}
    }
  }
}

// MARK: -
// MARK: AdsorptionSurfaceVisualAppearanceViewer protocol implementation



extension AdsorptionSurfaceVisualAppearanceViewer
{
  public var renderMinimumGridEnergyValue: Float?
  {
    get
    {
      let set: Set<Float> = Set(self.structureViewerStructures.compactMap{ return ($0 as? RKRenderAdsorptionSurfaceStructure)?.minimumGridEnergyValue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{($0 as? RKRenderAdsorptionSurfaceStructure)?.minimumGridEnergyValue = newValue ?? 0.0}
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
  
  public var renderFrontAdsorptionSurfaceHDR: Bool?
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
  
  public var renderFrontAdsorptionSurfaceHDRExposure: Double?
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
  
  public var renderFrontAdsorptionSurfaceAmbientIntensity: Double?
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
  
  public var renderFrontAdsorptionSurfaceDiffuseIntensity: Double?
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
  
  public var renderFrontAdsorptionSurfaceSpecularIntensity: Double?
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
  
  public var renderFrontAdsorptionSurfaceShininess: Double?
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
  
  public var renderFrontAdsorptionSurfaceAmbientColor: NSColor?
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
  
  public var renderFrontAdsorptionSurfaceDiffuseColor: NSColor?
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
  
  public var renderBackAdsorptionSurfaceHDR: Bool?
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
  
  public var renderBackAdsorptionSurfaceHDRExposure: Double?
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
  
  public var renderBackAdsorptionSurfaceAmbientIntensity: Double?
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
  
  public var renderBackAdsorptionSurfaceDiffuseIntensity: Double?
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
  
  public var renderBackAdsorptionSurfaceSpecularIntensity: Double?
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
  
  public var renderBackAdsorptionSurfaceShininess: Double?
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
  
  public var renderFrontAdsorptionSurfaceSpecularColor: NSColor?
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
  
  public var renderBackAdsorptionSurfaceAmbientColor: NSColor?
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
  
  public var renderBackAdsorptionSurfaceDiffuseColor: NSColor?
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
  
  public var renderBackAdsorptionSurfaceSpecularColor: NSColor?
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
      let set: Set<Float> = Set(self.structureViewerStructures.compactMap{ return ($0 as? RKRenderAdsorptionSurfaceStructure)?.minimumGridEnergyValue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.structureViewerStructures.forEach{($0 as? RKRenderAdsorptionSurfaceStructure)?.minimumGridEnergyValue = newValue ?? 0.0}
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
  
  public var renderBackAdsorptionSurfaceHDR: Bool?
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
  
  public var renderBackAdsorptionSurfaceHDRExposure: Double?
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
  
  public var renderFrontAdsorptionSurfaceAmbientIntensity: Double?
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
  
  public var renderFrontAdsorptionSurfaceDiffuseIntensity: Double?
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
  
  public var renderFrontAdsorptionSurfaceSpecularIntensity: Double?
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
  
  public var renderFrontAdsorptionSurfaceShininess: Double?
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
  
  public var renderFrontAdsorptionSurfaceAmbientColor: NSColor?
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
  
  public var renderFrontAdsorptionSurfaceDiffuseColor: NSColor?
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
  
  public var renderFrontAdsorptionSurfaceHDR: Bool?
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
  
  public var renderFrontAdsorptionSurfaceHDRExposure: Double?
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
  
  public var renderBackAdsorptionSurfaceAmbientIntensity: Double?
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
  
  public var renderBackAdsorptionSurfaceDiffuseIntensity: Double?
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
  
  public var renderBackAdsorptionSurfaceSpecularIntensity: Double?
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
  
  public var renderBackAdsorptionSurfaceShininess: Double?
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
  
  public var renderFrontAdsorptionSurfaceSpecularColor: NSColor?
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
  
  public var renderBackAdsorptionSurfaceAmbientColor: NSColor?
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
  
  public var renderBackAdsorptionSurfaceDiffuseColor: NSColor?
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
  
  public var renderBackAdsorptionSurfaceSpecularColor: NSColor?
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




