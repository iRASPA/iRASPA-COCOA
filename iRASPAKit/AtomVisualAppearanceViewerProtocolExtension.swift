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
// MARK: AtomVisualAppearanceViewer protocol implementation

extension AtomVisualAppearanceViewer
{
  public func recheckRepresentationStyle()
  {
    self.allStructures.forEach{$0.recheckRepresentationStyle()}
  }
  
  public func getRepresentationType() -> Structure.RepresentationType?
  {
    let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.getRepresentationType()?.rawValue })
    return Set(set).count == 1 ? Structure.RepresentationType(rawValue: set.first!) : nil
  }
  
  public func setRepresentationType(type: Structure.RepresentationType?)
  {
    self.allStructures.forEach{
      $0.setRepresentationType(type: type)
      $0.reComputeBoundingBox()
    }
  }
  
  
  public func getRepresentationStyle() -> Structure.RepresentationStyle?
  {
    let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.getRepresentationStyle()?.rawValue })
    return Set(set).count == 1 ? Structure.RepresentationStyle(rawValue: set.first!) : nil
  }
  
  public func setRepresentationStyle(style: Structure.RepresentationStyle?, colorSets: SKColorSets)
  {
    self.allStructures.forEach{
      $0.setRepresentationStyle(style: style, colorSets: colorSets)
      $0.reComputeBoundingBox()
    }
  }
  
  public func getRepresentationColorScheme() -> String?
  {
    let set: Set<String> = Set(self.allStructures.compactMap{ return $0.getRepresentationColorScheme() })
    return Set(set).count == 1 ?  set.first! : nil
  }
  
  public func setRepresentationColorScheme(scheme: String?, colorSets: SKColorSets)
  {
  self.allStructures.forEach{$0.setRepresentationColorScheme(scheme: scheme ?? "Default", colorSets: colorSets)}
  }
  
  public func getRepresentationColorOrder() -> SKColorSets.ColorOrder?
  {
    let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.getRepresentationColorOrder()?.rawValue })
    return Set(set).count == 1 ?  SKColorSets.ColorOrder(rawValue: set.first!) : nil
  }
  
  public func setRepresentationColorOrder(order: SKColorSets.ColorOrder?, colorSets: SKColorSets)
  {
    self.allStructures.forEach{$0.setRepresentationColorOrder(order: order ?? SKColorSets.ColorOrder.elementOnly, colorSets: colorSets)}
  }
  
  public func getRepresentationForceField() -> String?
  {
    let set: Set<String> = Set(self.allStructures.compactMap{ return $0.getRepresentationForceField() })
      return Set(set).count == 1 ?  set.first! : nil
  }
  
  public func setRepresentationForceField(forceField: String?, forceFieldSets: SKForceFieldSets)
  {
    self.allStructures.forEach{$0.setRepresentationForceField(forceField: forceField ?? "Default", forceFieldSets: forceFieldSets)}
  }
  
  public func getRepresentationForceFieldOrder() -> SKForceFieldSets.ForceFieldOrder?
  {
    let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.getRepresentationForceFieldOrder()?.rawValue })
    return Set(set).count == 1 ?  SKForceFieldSets.ForceFieldOrder(rawValue: set.first!) : nil
  }
  
  public func setRepresentationForceFieldOrder(order: SKForceFieldSets.ForceFieldOrder?, forceFieldSets: SKForceFieldSets)
  {
    self.allStructures.forEach{$0.setRepresentationForceFieldOrder(order: order, forceFieldSets: forceFieldSets)}
  }
  
  public var renderAtomHue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomHue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomHue = newValue ?? 1.0}
    }
  }
  
  public var renderAtomSaturation: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomSaturation })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomSaturation = newValue ?? 1.0}
    }
  }
  
  public var renderAtomValue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomValue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomValue = newValue ?? 1.0}
    }
  }
  
  public var renderAtomScaleFactor: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomScaleFactor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{
        $0.atomScaleFactor = newValue ?? 1.0
      }
    }
  }
  
  public var renderAtomScaleFactorCompleted: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomScaleFactor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{
        $0.atomScaleFactor = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
  
  
  public var renderDrawAtoms: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.allStructures.compactMap{ return $0.drawAtoms })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.drawAtoms = newValue ?? true}
    }
  }
  
  public var renderAtomAmbientOcclusion: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.allStructures.compactMap{ return $0.atomAmbientOcclusion })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomAmbientOcclusion = newValue ?? true}
    }
  }
  
  public var renderAtomHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.allStructures.compactMap{ return $0.atomHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomHDR = newValue ?? true}
    }
  }
  
  
  public var renderAtomHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomHDRExposure = newValue ?? 1.0}
    }
  }
  
  public var renderAtomAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.atomAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomAmbientColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderAtomDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.atomDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomDiffuseColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderAtomSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.atomSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomSpecularColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  
  public var renderAtomAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderAtomDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAtomSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAtomShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomShininess = newValue ?? 4.0}
    }
  }
  
  public var renderAtomSelectionStyle: RKSelectionStyle?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.atomSelectionStyle.rawValue })
      return Set(set).count == 1 ? RKSelectionStyle(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomSelectionStyle = newValue ?? .glow}
    }
  }
  
  public var renderAtomSelectionFrequency: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderAtomSelectionFrequency })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderAtomSelectionFrequency = newValue ?? 4.0}
    }
  }
  
  public var renderAtomSelectionDensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderAtomSelectionDensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderAtomSelectionDensity = newValue ?? 4.0}
    }
  }
  
  public var renderAtomSelectionIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomSelectionIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomSelectionIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAtomSelectionScaling: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomSelectionScaling })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomSelectionScaling = newValue ?? 1.0}
    }
  }
  
  public var renderTextType: RKTextType?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.atomTextType.rawValue })
      return Set(set).count == 1 ? RKTextType(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextType = newValue ?? .none}
    }
  }
  
  public var renderTextStyle: RKTextStyle?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.atomTextStyle.rawValue })
      return Set(set).count == 1 ? RKTextStyle(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextStyle = newValue ?? .flatBillboard}
    }
  }
  
  public var renderTextAlignment: RKTextAlignment?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.atomTextAlignment.rawValue })
      return Set(set).count == 1 ? RKTextAlignment(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextAlignment = newValue ?? .center}
    }
  }
  
  public var renderTextFont: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.atomTextFont })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextFont = newValue ?? "Helvetica"}
    }
  }
  
  public var renderTextFontFamily: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap({ (structure) -> String? in
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
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.atomTextColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextColor = newValue ?? NSColor.black}
    }
  }
  
  public var renderTextScaling: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomTextScaling })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextScaling = newValue ?? 1.0}
    }
  }
  
  public var renderTextOffsetX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomTextOffset.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextOffset.x = newValue ?? 0}
    }
  }
  
  public var renderTextOffsetY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomTextOffset.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextOffset.y = newValue ?? 0}
    }
  }
  
  public var renderTextOffsetZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomTextOffset.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextOffset.z = newValue ?? 0}
    }
  }
}

extension Array where Iterator.Element == AtomVisualAppearanceViewer
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
  
  public func recheckRepresentationStyle()
  {
    self.allStructures.forEach{$0.recheckRepresentationStyle()}
  }
  
  public func getRepresentationType() -> Structure.RepresentationType?
  {
    let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.getRepresentationType()?.rawValue })
    return Set(set).count == 1 ? Structure.RepresentationType(rawValue: set.first!) : nil
  }
  
  public func setRepresentationType(type: Structure.RepresentationType?)
  {
    self.allStructures.forEach{
      $0.setRepresentationType(type: type)
      $0.reComputeBoundingBox()
    }
  }
  
  public func getRepresentationStyle() -> Structure.RepresentationStyle?
  {
    let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.getRepresentationStyle()?.rawValue })
    return Set(set).count == 1 ? Structure.RepresentationStyle(rawValue: set.first!) : nil
  }
  
  public func setRepresentationStyle(style: Structure.RepresentationStyle?, colorSets: SKColorSets)
  {
    self.allStructures.forEach{
      $0.setRepresentationStyle(style: style, colorSets: colorSets)
      $0.reComputeBoundingBox()
    }
  }
  
  public func getRepresentationColorScheme() -> String?
  {
    let set: Set<String> = Set(self.allStructures.compactMap{ return $0.getRepresentationColorScheme() })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public func setRepresentationColorScheme(scheme: String?, colorSets: SKColorSets)
  {
    self.allStructures.forEach{$0.setRepresentationColorScheme(scheme: scheme ?? SKColorSets.ColorScheme.jmol.rawValue, colorSets: colorSets)}
  }
  
  public func getRepresentationColorOrder() -> SKColorSets.ColorOrder?
  {
    let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.getRepresentationColorOrder()?.rawValue })
    return Set(set).count == 1 ? SKColorSets.ColorOrder(rawValue: set.first!) : nil
  }
  
  public func setRepresentationColorOrder(order: SKColorSets.ColorOrder?, colorSets: SKColorSets)
  {
    self.allStructures.forEach{$0.setRepresentationColorOrder(order: order, colorSets: colorSets)}
  }
  
  public func getRepresentationForceField() -> String?
  {
    let set: Set<String> = Set(self.allStructures.compactMap{ return $0.getRepresentationForceField() })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public func setRepresentationForceField(forceField: String?, forceFieldSets: SKForceFieldSets)
  {
    self.allStructures.forEach{$0.setRepresentationForceField(forceField: forceField ?? "Default", forceFieldSets: forceFieldSets)}
  }
  
  public func getRepresentationForceFieldOrder() -> SKForceFieldSets.ForceFieldOrder?
  {
    let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.getRepresentationForceFieldOrder()?.rawValue })
    return Set(set).count == 1 ? SKForceFieldSets.ForceFieldOrder(rawValue: set.first!) : nil
  }
  
  public func setRepresentationForceFieldOrder(order: SKForceFieldSets.ForceFieldOrder?, forceFieldSets: SKForceFieldSets)
  {
    self.allStructures.forEach{$0.setRepresentationForceFieldOrder(order: order, forceFieldSets: forceFieldSets)}
  }
  
  public var renderAtomHue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomHue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomHue = newValue ?? 1.0}
    }
  }
  
  public var renderAtomSaturation: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomSaturation })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomSaturation = newValue ?? 1.0}
    }
  }
  
  public var renderAtomValue: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomValue })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomValue = newValue ?? 1.0}
    }
  }
  
  public var renderAtomScaleFactor: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomScaleFactor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{
        $0.atomScaleFactor = newValue ?? 1.0
      }
    }
  }
  
  public var renderAtomScaleFactorCompleted: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomScaleFactor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{
        $0.atomScaleFactor = newValue ?? 1.0
        $0.reComputeBoundingBox()
      }
    }
  }
  
 
  public var renderDrawAtoms: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.allStructures.compactMap{ return $0.drawAtoms })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.drawAtoms = newValue ?? true}
    }
  }
  
  public var renderAtomAmbientOcclusion: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.allStructures.compactMap{ return $0.atomAmbientOcclusion })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomAmbientOcclusion = newValue ?? true}
    }
  }
  
  public var renderAtomHDR: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.allStructures.compactMap{ return $0.atomHDR })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomHDR = newValue ?? true}
    }
  }
  
  
  public var renderAtomHDRExposure: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomHDRExposure })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomHDRExposure = newValue ?? 1.5}
    }
  }
  
  public var renderAtomAmbientColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.atomAmbientColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomAmbientColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderAtomDiffuseColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.atomDiffuseColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomDiffuseColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  public var renderAtomSpecularColor: NSColor?
  {
    get
    {
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.atomSpecularColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomSpecularColor = newValue ?? NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)}
    }
  }
  
  
  public var renderAtomAmbientIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomAmbientIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomAmbientIntensity = newValue ?? 0.2}
    }
  }
  
  public var renderAtomDiffuseIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomDiffuseIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomDiffuseIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAtomSpecularIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomSpecularIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomSpecularIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAtomShininess: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomShininess })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomShininess = newValue ?? 4.0}
    }
  }
  
  public var renderAtomSelectionStyle: RKSelectionStyle?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.atomSelectionStyle.rawValue })
      return Set(set).count == 1 ? RKSelectionStyle(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomSelectionStyle = newValue ?? .glow}
    }
  }
  
  public var renderAtomSelectionFrequency: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderAtomSelectionFrequency })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderAtomSelectionFrequency = newValue ?? 4.0}
    }
  }
  
  public var renderAtomSelectionDensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.renderAtomSelectionDensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.renderAtomSelectionDensity = newValue ?? 4.0}
    }
  }
  
  public var renderAtomSelectionIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomSelectionIntensity })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomSelectionIntensity = newValue ?? 1.0}
    }
  }
  
  public var renderAtomSelectionScaling: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomSelectionScaling })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomSelectionScaling = newValue ?? 1.0}
    }
  }
  
  
  public var renderTextType: RKTextType?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.atomTextType.rawValue })
      return Set(set).count == 1 ? RKTextType(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextType = newValue ?? .none}
    }
  }
  
  public var renderTextStyle: RKTextStyle?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.atomTextStyle.rawValue })
      return Set(set).count == 1 ? RKTextStyle(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextStyle = newValue ?? .flatBillboard}
    }
  }
  
  public var renderTextAlignment: RKTextAlignment?
  {
    get
    {
      let set: Set<Int> = Set(self.allStructures.compactMap{ return $0.atomTextAlignment.rawValue })
      return Set(set).count == 1 ? RKTextAlignment(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextAlignment = newValue ?? .center}
    }
  }
  
  public var renderTextFont: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap{ return $0.atomTextFont })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextFont = newValue ?? "Helvetica"}
    }
  }
  
  public var renderTextFontFamily: String?
  {
    get
    {
      let set: Set<String> = Set(self.allStructures.compactMap({ (structure) -> String? in
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
      let set: Set<NSColor> = Set(self.allStructures.compactMap{ return $0.atomTextColor })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextColor = newValue ?? NSColor.black}
    }
  }
  
  public var renderTextScaling: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomTextScaling })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextScaling = newValue ?? 1.0}
    }
  }
  
  public var renderTextOffsetX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomTextOffset.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextOffset.x = newValue ?? 0}
    }
  }
  
  public var renderTextOffsetY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomTextOffset.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextOffset.y = newValue ?? 0}
    }
  }
  
  public var renderTextOffsetZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.allStructures.compactMap{ return $0.atomTextOffset.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.allStructures.forEach{$0.atomTextOffset.z = newValue ?? 0}
    }
  }
}


