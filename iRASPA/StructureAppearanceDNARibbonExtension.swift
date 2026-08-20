/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 *************************************************************************************************************/

import Cocoa
import RenderKit
import iRASPAKit

extension StructureAppearanceDetailViewController
{
  private var hasDNARibbonEditors: Bool
  {
    return !iRASPAObjects.filter({ $0.object is DNARibbonStructureEditor }).isEmpty
  }

  private func dnaRibbonEditable(_ enabled: Bool) -> Bool
  {
    return (proxyProject?.isEditable ?? false) && enabled && hasDNARibbonEditors
  }

  func setPropertiesDNARibbonTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    let editable: Bool = dnaRibbonEditable(enabled)

    switch identifier
    {
    case "DNARibbonsRepresentationCell":
      if let popUpButtonBackboneStyle: iRASPAPopUpButton = view.viewWithTag(5) as? iRASPAPopUpButton
      {
        popUpButtonBackboneStyle.isEditable = false
        if editable
        {
          popUpButtonBackboneStyle.isEditable = true
          if let backboneStyle = self.getDNABackboneStyle()
          {
            popUpButtonBackboneStyle.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpButtonBackboneStyle.selectItem(withTitle: backboneStyle.displayName)
          }
          else
          {
            popUpButtonBackboneStyle.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
      }

      if let popUpButtonTraceMode: iRASPAPopUpButton = view.viewWithTag(4) as? iRASPAPopUpButton
      {
        popUpButtonTraceMode.isEditable = false
        if editable
        {
          popUpButtonTraceMode.isEditable = true
          if let traceMode = self.getDNATraceMode()
          {
            popUpButtonTraceMode.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpButtonTraceMode.selectItem(withTitle: traceMode.displayName)
          }
          else
          {
            popUpButtonTraceMode.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
      }

      if let textFieldOvalLength: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldOvalLength.isEditable = false
        textFieldOvalLength.stringValue = ""
        if editable
        {
          textFieldOvalLength.isEditable = true
          if let ovalLength = self.renderDNAOvalLength
          {
            textFieldOvalLength.doubleValue = ovalLength
          }
          else
          {
            textFieldOvalLength.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }

      if let textFieldOvalWidth: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldOvalWidth.isEditable = false
        textFieldOvalWidth.stringValue = ""
        if editable
        {
          textFieldOvalWidth.isEditable = true
          if let ovalWidth = self.renderDNAOvalWidth
          {
            textFieldOvalWidth.doubleValue = ovalWidth
          }
          else
          {
            textFieldOvalWidth.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }

    case "DNARibbonsScalingCell":
      if let checkDrawRibbonsButton: NSButton = view.viewWithTag(1) as? NSButton
      {
        checkDrawRibbonsButton.isEnabled = false
        if editable
        {
          checkDrawRibbonsButton.isEnabled = true
          if let renderDrawRibbon: Bool = self.renderDNADrawRibbon
          {
            checkDrawRibbonsButton.allowsMixedState = false
            checkDrawRibbonsButton.state = renderDrawRibbon ? .on : .off
          }
          else
          {
            checkDrawRibbonsButton.allowsMixedState = true
            checkDrawRibbonsButton.state = .mixed
          }
        }
      }

      if let textFieldRibbonScaling: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldRibbonScaling.isEditable = false
        textFieldRibbonScaling.stringValue = ""
        if editable
        {
          textFieldRibbonScaling.isEditable = true
          if let scaleFactor = self.renderDNARibbonScaleFactor
          {
            textFieldRibbonScaling.doubleValue = scaleFactor
          }
          else
          {
            textFieldRibbonScaling.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }

      if let sliderRibbonScaling: NSSlider = view.viewWithTag(3) as? NSSlider
      {
        sliderRibbonScaling.isEnabled = false
        sliderRibbonScaling.minValue = 0.1
        sliderRibbonScaling.maxValue = 2.0
        if editable
        {
          sliderRibbonScaling.isEnabled = true
          if let scaleFactor = self.renderDNARibbonScaleFactor
          {
            sliderRibbonScaling.doubleValue = scaleFactor
          }
        }
      }

    case "DNARibbonsSelectionCell":
      bindDNARibbonSelectionCell(view: view, editable: editable)

    case "DNARibbonsHDRCell":
      bindDNARibbonHDRCell(view: view, editable: editable)

    case "DNARibbonsLightingCell":
      bindDNARibbonLightingCell(view: view, editable: editable)

    case "DNARibbonsVisualAppearanceGroup":
      disableRibbonAppearanceControls(in: view)

    default:
      break
    }
  }

  private func bindDNARibbonSelectionCell(view: NSTableCellView, editable: Bool)
  {
    if let popUpbuttonSelectionStyle: iRASPAPopUpButton = view.viewWithTag(1) as? iRASPAPopUpButton,
       let textFieldSelectionFrequency: NSTextField = view.viewWithTag(2) as? NSTextField,
       let textFieldSelectionDensity: NSTextField = view.viewWithTag(3) as? NSTextField
    {
      popUpbuttonSelectionStyle.isEditable = false
      textFieldSelectionFrequency.isEditable = false
      textFieldSelectionFrequency.stringValue = ""
      textFieldSelectionDensity.isEditable = false
      textFieldSelectionDensity.stringValue = ""
      if editable
      {
        popUpbuttonSelectionStyle.isEditable = true
        textFieldSelectionFrequency.isEditable = true
        textFieldSelectionDensity.isEditable = true

        if let selectionStyle: RKSelectionStyle = self.renderDNARibbonSelectionStyle
        {
          popUpbuttonSelectionStyle.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
          popUpbuttonSelectionStyle.selectItem(at: selectionStyle.rawValue)
          if selectionStyle == .glow
          {
            textFieldSelectionFrequency.isEditable = false
            textFieldSelectionDensity.isEditable = false
          }
        }
        else
        {
          popUpbuttonSelectionStyle.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          textFieldSelectionFrequency.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          textFieldSelectionDensity.stringValue = NSLocalizedString("Mult. Val.", comment: "")
        }

        if let frequency = self.renderDNARibbonSelectionFrequency
        {
          textFieldSelectionFrequency.doubleValue = frequency
        }
        else
        {
          textFieldSelectionFrequency.stringValue = NSLocalizedString("Mult. Val.", comment: "")
        }

        if let density = self.renderDNARibbonSelectionDensity
        {
          textFieldSelectionDensity.doubleValue = density
        }
        else
        {
          textFieldSelectionDensity.stringValue = NSLocalizedString("Mult. Val.", comment: "")
        }
      }
    }

    if let textFieldIntensity: NSTextField = view.viewWithTag(4) as? NSTextField
    {
      textFieldIntensity.isEditable = false
      textFieldIntensity.stringValue = ""
      if editable
      {
        textFieldIntensity.isEditable = true
        if let intensity = self.renderDNARibbonSelectionIntensity
        {
          textFieldIntensity.doubleValue = intensity
        }
        else
        {
          textFieldIntensity.stringValue = NSLocalizedString("Multiple Values", comment: "")
        }
      }
    }

    if let sliderIntensity: NSSlider = view.viewWithTag(5) as? NSSlider
    {
      sliderIntensity.isEnabled = false
      sliderIntensity.minValue = 0.0
      sliderIntensity.maxValue = 1.0
      if editable, let intensity = self.renderDNARibbonSelectionIntensity
      {
        sliderIntensity.isEnabled = true
        sliderIntensity.doubleValue = intensity
      }
    }

    if let textFieldScaling: NSTextField = view.viewWithTag(6) as? NSTextField
    {
      textFieldScaling.isEditable = false
      textFieldScaling.stringValue = ""
      if editable
      {
        textFieldScaling.isEditable = true
        if let scaling = self.renderDNARibbonSelectionScaling
        {
          textFieldScaling.doubleValue = scaling
        }
        else
        {
          textFieldScaling.stringValue = NSLocalizedString("Multiple Values", comment: "")
        }
      }
    }

    if let sliderScaling: NSSlider = view.viewWithTag(7) as? NSSlider
    {
      sliderScaling.isEnabled = false
      sliderScaling.minValue = 1.0
      sliderScaling.maxValue = 2.0
      if editable, let scaling = self.renderDNARibbonSelectionScaling
      {
        sliderScaling.isEnabled = true
        sliderScaling.doubleValue = scaling
      }
    }
  }

  private func bindDNARibbonHDRCell(view: NSTableCellView, editable: Bool)
  {
    bindDNARibbonBoolControl(view: view, tag: 1, value: renderDNARibbonHDR, editable: editable)
    bindDNARibbonDoublePair(view: view, textTag: 2, sliderTag: 3, value: renderDNARibbonHDRExposure, sliderMin: 0.0, sliderMax: 3.0, editable: editable)
    bindDNARibbonDoublePair(view: view, textTag: 4, sliderTag: 5, value: renderDNARibbonHue, sliderMin: 0.0, sliderMax: 1.5, editable: editable)
    bindDNARibbonDoublePair(view: view, textTag: 6, sliderTag: 7, value: renderDNARibbonSaturation, sliderMin: 0.0, sliderMax: 1.5, editable: editable)
    bindDNARibbonDoublePair(view: view, textTag: 8, sliderTag: 9, value: renderDNARibbonValue, sliderMin: 0.0, sliderMax: 1.5, editable: editable)
  }

  private func bindDNARibbonLightingCell(view: NSTableCellView, editable: Bool)
  {
    bindDNARibbonBoolControl(view: view, tag: 1, value: renderDNARibbonAmbientOcclusion, editable: editable)
    bindDNARibbonDoublePair(view: view, textTag: 2, sliderTag: 3, value: renderDNARibbonAmbientIntensity, sliderMin: 0.0, sliderMax: 1.0, editable: editable, multipleShort: true)
    bindDNARibbonColorWell(view: view, tag: 4, value: renderDNARibbonAmbientColor, editable: editable)
    bindDNARibbonDoublePair(view: view, textTag: 5, sliderTag: 6, value: renderDNARibbonDiffuseIntensity, sliderMin: 0.0, sliderMax: 1.0, editable: editable, multipleShort: true)
    bindDNARibbonColorWell(view: view, tag: 7, value: renderDNARibbonDiffuseColor, editable: editable)
    bindDNARibbonDoublePair(view: view, textTag: 8, sliderTag: 9, value: renderDNARibbonSpecularIntensity, sliderMin: 0.0, sliderMax: 1.0, editable: editable, multipleShort: true)
    bindDNARibbonColorWell(view: view, tag: 10, value: renderDNARibbonSpecularColor, editable: editable)
    bindDNARibbonDoublePair(view: view, textTag: 11, sliderTag: 12, value: renderDNARibbonShininess, sliderMin: 0.1, sliderMax: 128.0, editable: editable, multipleShort: true)
  }

  private func bindDNARibbonBoolControl(view: NSTableCellView, tag: Int, value: Bool?, editable: Bool)
  {
    guard let button: NSButton = view.viewWithTag(tag) as? NSButton else { return }
    button.isEnabled = false
    guard editable else { return }
    button.isEnabled = true
    if let value = value
    {
      button.allowsMixedState = false
      button.state = value ? .on : .off
    }
    else
    {
      button.allowsMixedState = true
      button.state = .mixed
    }
  }

  private func bindDNARibbonDoublePair(view: NSTableCellView, textTag: Int, sliderTag: Int, value: Double?, sliderMin: Double, sliderMax: Double, editable: Bool, multipleShort: Bool = false)
  {
    let multipleLabel = multipleShort ? NSLocalizedString("Mult. V.", comment: "") : NSLocalizedString("Multiple Values", comment: "")
    if let textField: NSTextField = view.viewWithTag(textTag) as? NSTextField
    {
      textField.isEditable = false
      textField.stringValue = ""
      if editable
      {
        textField.isEditable = true
        if let value = value
        {
          textField.doubleValue = value
        }
        else
        {
          textField.stringValue = multipleLabel
        }
      }
    }
    if let slider: NSSlider = view.viewWithTag(sliderTag) as? NSSlider
    {
      slider.isEnabled = false
      slider.minValue = sliderMin
      slider.maxValue = sliderMax
      if editable, let value = value
      {
        slider.isEnabled = true
        slider.doubleValue = value
      }
    }
  }

  private func bindDNARibbonColorWell(view: NSTableCellView, tag: Int, value: NSColor?, editable: Bool)
  {
    guard let colorWell: NSColorWell = view.viewWithTag(tag) as? NSColorWell else { return }
    colorWell.isEnabled = false
    colorWell.color = NSColor.lightGray
    guard editable else { return }
    colorWell.isEnabled = true
    if let value = value
    {
      colorWell.color = value
    }
  }

  func applyDNARibbonMeshChanges(updateIdentifiers: [OutlineViewItem])
  {
    updateOutlineView(identifiers: updateIdentifiers)
    for treeNode in iRASPAObjects
    {
      (treeNode.object as? DNARibbonStructureEditor)?.rebuildRibbonMesh()
    }
    windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [])
    windowController?.detailTabViewController?.renderViewController?.reloadData()
    windowController?.detailTabViewController?.renderViewController?.updateAmbientOcclusion()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  private func applyDNARibbonBackboneChanges(updateIdentifiers: [OutlineViewItem])
  {
    updateOutlineView(identifiers: updateIdentifiers)
    for treeNode in iRASPAObjects
    {
      if let editor = treeNode.object as? DNARibbonStructureEditor
      {
        editor.rebuildBackbone()
        editor.rebuildRibbonMesh()
      }
    }
    windowController?.detailTabViewController?.renderViewController?.reloadData()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  private func dnaRibbonAppearanceDidChange(updateIdentifiers: [OutlineViewItem])
  {
    updateOutlineView(identifiers: updateIdentifiers)
  }

  func getDNABackboneStyle() -> NucleicAcidBackboneStyle?
  {
    let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.nucleicAcidBackboneStyle })
    return set.count == 1 ? set.first : nil
  }

  func getDNATraceMode() -> NucleicAcidTraceMode?
  {
    let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.nucleicAcidTraceMode })
    return set.count == 1 ? set.first : nil
  }

  var renderDNADrawRibbon: Bool?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.drawRibbon })
      return set.count == 1 ? set.first : nil
    }
    set(newValue)
    {
      iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.drawRibbon = newValue ?? true }
    }
  }

  var renderDNARibbonScaleFactor: Double?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.ribbonScaleFactor })
      return set.count == 1 ? set.first : nil
    }
    set(newValue)
    {
      iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.ribbonScaleFactor = newValue ?? 1.0 }
    }
  }

  var renderDNARibbonScaleFactorCompleted: Double?
  {
    get { renderDNARibbonScaleFactor }
    set(newValue)
    {
      iRASPAObjects.forEach {
        ($0.object as? DNARibbonStructureEditor)?.ribbonScaleFactor = newValue ?? 1.0
        ($0.object as? RKRenderRibbonSource)?.rebuildRibbonMesh()
      }
    }
  }

  var renderDNABackboneStyle: NucleicAcidBackboneStyle?
  {
    get { getDNABackboneStyle() }
    set(newValue)
    {
      guard let newValue = newValue else { return }
      iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.nucleicAcidBackboneStyle = newValue }
    }
  }

  var renderDNATraceMode: NucleicAcidTraceMode?
  {
    get { getDNATraceMode() }
    set(newValue)
    {
      guard let newValue = newValue else { return }
      iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.nucleicAcidTraceMode = newValue }
    }
  }

  var renderDNAOvalLength: Double?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.nucleicAcidOvalLength })
      return set.count == 1 ? set.first : nil
    }
    set(newValue)
    {
      iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.nucleicAcidOvalLength = newValue ?? 0.2 }
    }
  }

  var renderDNAOvalWidth: Double?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.nucleicAcidOvalWidth })
      return set.count == 1 ? set.first : nil
    }
    set(newValue)
    {
      iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.nucleicAcidOvalWidth = newValue ?? 0.2 }
    }
  }

  var renderDNARibbonSelectionStyle: RKSelectionStyle?
  {
    get
    {
      let set: Set<Int> = Set(iRASPAObjects.compactMap {
        guard $0.object is DNARibbonStructureEditor else { return nil }
        return ($0.object as? AtomStructureEditor)?.atomSelectionStyle.rawValue
      })
      return set.count == 1 ? RKSelectionStyle(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      iRASPAObjects.forEach {
        guard $0.object is DNARibbonStructureEditor else { return }
        ($0.object as? AtomStructureEditor)?.atomSelectionStyle = newValue ?? .WorleyNoise3D
      }
    }
  }

  var renderDNARibbonSelectionFrequency: Double?
  {
    get
    {
      let set: Set<Double> = Set(iRASPAObjects.compactMap {
        guard $0.object is DNARibbonStructureEditor else { return nil }
        return ($0.object as? AtomStructureEditor)?.renderAtomSelectionFrequency
      })
      return set.count == 1 ? set.first : nil
    }
    set(newValue)
    {
      iRASPAObjects.forEach {
        guard $0.object is DNARibbonStructureEditor else { return }
        ($0.object as? AtomStructureEditor)?.renderAtomSelectionFrequency = newValue ?? 4.0
      }
    }
  }

  var renderDNARibbonSelectionDensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(iRASPAObjects.compactMap {
        guard $0.object is DNARibbonStructureEditor else { return nil }
        return ($0.object as? AtomStructureEditor)?.renderAtomSelectionDensity
      })
      return set.count == 1 ? set.first : nil
    }
    set(newValue)
    {
      iRASPAObjects.forEach {
        guard $0.object is DNARibbonStructureEditor else { return }
        ($0.object as? AtomStructureEditor)?.renderAtomSelectionDensity = newValue ?? 4.0
      }
    }
  }

  var renderDNARibbonSelectionIntensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(iRASPAObjects.compactMap {
        guard $0.object is DNARibbonStructureEditor else { return nil }
        return ($0.object as? AtomStructureEditor)?.atomSelectionIntensity
      })
      return set.count == 1 ? set.first : nil
    }
    set(newValue)
    {
      iRASPAObjects.forEach {
        guard $0.object is DNARibbonStructureEditor else { return }
        ($0.object as? AtomStructureEditor)?.atomSelectionIntensity = newValue ?? 1.0
      }
    }
  }

  var renderDNARibbonSelectionScaling: Double?
  {
    get
    {
      let set: Set<Double> = Set(iRASPAObjects.compactMap {
        guard $0.object is DNARibbonStructureEditor else { return nil }
        return ($0.object as? AtomStructureEditor)?.atomSelectionScaling
      })
      return set.count == 1 ? set.first : nil
    }
    set(newValue)
    {
      iRASPAObjects.forEach {
        guard $0.object is DNARibbonStructureEditor else { return }
        ($0.object as? AtomStructureEditor)?.atomSelectionScaling = newValue ?? 1.0
      }
    }
  }

  var renderDNARibbonHDR: Bool?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.ribbonHDR })
      return set.count == 1 ? set.first : nil
    }
    set(newValue) { iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.ribbonHDR = newValue ?? false } }
  }

  var renderDNARibbonHDRExposure: Double?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.ribbonHDRExposure })
      return set.count == 1 ? set.first : nil
    }
    set(newValue) { iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.ribbonHDRExposure = newValue ?? 1.5 } }
  }

  var renderDNARibbonHue: Double?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.ribbonHue })
      return set.count == 1 ? set.first : nil
    }
    set(newValue) { iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.ribbonHue = newValue ?? 1.0 } }
  }

  var renderDNARibbonSaturation: Double?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.ribbonSaturation })
      return set.count == 1 ? set.first : nil
    }
    set(newValue) { iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.ribbonSaturation = newValue ?? 1.0 } }
  }

  var renderDNARibbonValue: Double?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.ribbonValue })
      return set.count == 1 ? set.first : nil
    }
    set(newValue) { iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.ribbonValue = newValue ?? 1.0 } }
  }

  var renderDNARibbonAmbientOcclusion: Bool?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.ribbonAmbientOcclusion })
      return set.count == 1 ? set.first : nil
    }
    set(newValue) { iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.ribbonAmbientOcclusion = newValue ?? true } }
  }

  var renderDNARibbonAmbientColor: NSColor?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.ribbonAmbientColor })
      return set.count == 1 ? set.first : nil
    }
    set(newValue) { iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.ribbonAmbientColor = newValue ?? .white } }
  }

  var renderDNARibbonDiffuseColor: NSColor?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.ribbonDiffuseColor })
      return set.count == 1 ? set.first : nil
    }
    set(newValue) { iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.ribbonDiffuseColor = newValue ?? .white } }
  }

  var renderDNARibbonSpecularColor: NSColor?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.ribbonSpecularColor })
      return set.count == 1 ? set.first : nil
    }
    set(newValue) { iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.ribbonSpecularColor = newValue ?? .white } }
  }

  var renderDNARibbonAmbientIntensity: Double?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.ribbonAmbientIntensity })
      return set.count == 1 ? set.first : nil
    }
    set(newValue) { iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.ribbonAmbientIntensity = newValue ?? 0.2 } }
  }

  var renderDNARibbonDiffuseIntensity: Double?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.ribbonDiffuseIntensity })
      return set.count == 1 ? set.first : nil
    }
    set(newValue) { iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.ribbonDiffuseIntensity = newValue ?? 1.0 } }
  }

  var renderDNARibbonSpecularIntensity: Double?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.ribbonSpecularIntensity })
      return set.count == 1 ? set.first : nil
    }
    set(newValue) { iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.ribbonSpecularIntensity = newValue ?? 1.0 } }
  }

  var renderDNARibbonShininess: Double?
  {
    get
    {
      let set = Set(iRASPAObjects.compactMap { ($0.object as? DNARibbonStructureEditor)?.ribbonShininess })
      return set.count == 1 ? set.first : nil
    }
    set(newValue) { iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.ribbonShininess = newValue ?? 4.0 } }
  }

  // MARK: DNA ribbon IBActions

  @IBAction func toggleDrawDNARibbons(_ sender: NSButton)
  {
    guard let projectTreeNode = proxyProject, projectTreeNode.isEditable else { return }
    sender.allowsMixedState = false
    let drawRibbon = (sender.state == .on)
    renderDNADrawRibbon = drawRibbon
    if drawRibbon
    {
      iRASPAObjects.forEach { ($0.object as? DNARibbonStructureEditor)?.rebuildBackbone() }
    }
    updateOutlineView(identifiers: [ribbonsDNAScalingCell])
    windowController?.detailTabViewController?.renderViewController?.reloadVisibility()
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    if drawRibbon
    {
      windowController?.detailTabViewController?.renderViewController?.updateAmbientOcclusion()
    }
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonScalingSlider(_ sender: NSSlider)
  {
    guard let projectTreeNode = proxyProject, projectTreeNode.isEditable else { return }
    renderDNARibbonScaleFactor = sender.doubleValue
    updateOutlineView(identifiers: [ribbonsDNAScalingCell])
    if let event = NSApplication.shared.currentEvent
    {
      if event.type == .leftMouseUp
      {
        renderDNARibbonScaleFactorCompleted = sender.doubleValue
        windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
        applyDNARibbonMeshChanges(updateIdentifiers: [ribbonsDNAScalingCell])
      }
      else if event.type == .leftMouseDown
      {
        windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
      }
    }
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonScalingTextField(_ sender: NSTextField)
  {
    guard let projectTreeNode = proxyProject, projectTreeNode.isEditable else { return }
    renderDNARibbonScaleFactorCompleted = sender.doubleValue
    applyDNARibbonMeshChanges(updateIdentifiers: [ribbonsDNAScalingCell])
    windowController?.window?.makeFirstResponder(appearanceOutlineView)
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNABackboneStyle(_ sender: NSPopUpButton)
  {
    guard let projectTreeNode = proxyProject, projectTreeNode.isEditable,
          let title = sender.titleOfSelectedItem,
          let style = NucleicAcidBackboneStyle.allSelectableCases.first(where: { $0.displayName == title })
    else { return }
    renderDNABackboneStyle = style
    applyDNARibbonMeshChanges(updateIdentifiers: [ribbonsDNACartoonCell])
    windowController?.window?.makeFirstResponder(appearanceOutlineView)
  }

  @IBAction func changeDNATraceMode(_ sender: NSPopUpButton)
  {
    guard let projectTreeNode = proxyProject, projectTreeNode.isEditable,
          let title = sender.titleOfSelectedItem,
          let mode = NucleicAcidTraceMode.allSelectableCases.first(where: { $0.displayName == title })
    else { return }
    renderDNATraceMode = mode
    applyDNARibbonBackboneChanges(updateIdentifiers: [ribbonsDNACartoonCell])
    windowController?.window?.makeFirstResponder(appearanceOutlineView)
  }

  @IBAction func changeDNAOvalLengthTextField(_ sender: NSTextField)
  {
    guard let projectTreeNode = proxyProject, projectTreeNode.isEditable else { return }
    renderDNAOvalLength = sender.doubleValue
    applyDNARibbonMeshChanges(updateIdentifiers: [ribbonsDNACartoonCell])
    windowController?.window?.makeFirstResponder(appearanceOutlineView)
  }

  @IBAction func changeDNAOvalWidthTextField(_ sender: NSTextField)
  {
    guard let projectTreeNode = proxyProject, projectTreeNode.isEditable else { return }
    renderDNAOvalWidth = sender.doubleValue
    applyDNARibbonMeshChanges(updateIdentifiers: [ribbonsDNACartoonCell])
    windowController?.window?.makeFirstResponder(appearanceOutlineView)
  }

  @IBAction func changeDNARibbonSelectionStyle(_ sender: NSPopUpButton)
  {
    guard let projectTreeNode = proxyProject, projectTreeNode.isEditable,
          let selectionStyle = RKSelectionStyle(rawValue: sender.indexOfSelectedItem)
    else { return }
    renderDNARibbonSelectionStyle = selectionStyle
    updateOutlineView(identifiers: [ribbonsDNASelectionCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonSelectionFrequencyTextField(_ sender: NSTextField)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonSelectionFrequency = sender.doubleValue
    updateOutlineView(identifiers: [ribbonsDNASelectionCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonSelectionDensityTextField(_ sender: NSTextField)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonSelectionDensity = sender.doubleValue
    updateOutlineView(identifiers: [ribbonsDNASelectionCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonSelectionIntensityLevelField(_ sender: NSTextField)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonSelectionIntensity = sender.doubleValue
    updateOutlineView(identifiers: [ribbonsDNASelectionCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonSelectionIntensityLevel(_ sender: NSSlider)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonSelectionIntensity = sender.doubleValue
    updateOutlineView(identifiers: [ribbonsDNASelectionCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonSelectionScalingTextField(_ sender: NSTextField)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonSelectionScaling = sender.doubleValue
    updateOutlineView(identifiers: [ribbonsDNASelectionCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonSelectionScalingSlider(_ sender: NSSlider)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonSelectionScaling = sender.doubleValue
    updateOutlineView(identifiers: [ribbonsDNASelectionCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func toggleDNARibbonHDR(_ sender: NSButton)
  {
    guard proxyProject?.isEditable == true else { return }
    sender.allowsMixedState = false
    renderDNARibbonHDR = (sender.state == .on)
    dnaRibbonAppearanceDidChange(updateIdentifiers: [ribbonsDNAHDRCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonHDRExposureTextField(_ sender: NSTextField)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonHDRExposure = sender.doubleValue
    dnaRibbonAppearanceDidChange(updateIdentifiers: [ribbonsDNAHDRCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonExposureSlider(_ sender: NSSlider)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonHDRExposure = sender.doubleValue
    dnaRibbonAppearanceDidChange(updateIdentifiers: [ribbonsDNAHDRCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonHueTextField(_ sender: NSTextField)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonHue = sender.doubleValue
    dnaRibbonAppearanceDidChange(updateIdentifiers: [ribbonsDNAHDRCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonHueSlider(_ sender: NSSlider)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonHue = sender.doubleValue
    dnaRibbonAppearanceDidChange(updateIdentifiers: [ribbonsDNAHDRCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonSaturationTextField(_ sender: NSTextField)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonSaturation = sender.doubleValue
    dnaRibbonAppearanceDidChange(updateIdentifiers: [ribbonsDNAHDRCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonSaturationSlider(_ sender: NSSlider)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonSaturation = sender.doubleValue
    dnaRibbonAppearanceDidChange(updateIdentifiers: [ribbonsDNAHDRCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonValueTextField(_ sender: NSTextField)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonValue = sender.doubleValue
    dnaRibbonAppearanceDidChange(updateIdentifiers: [ribbonsDNAHDRCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonValueSlider(_ sender: NSSlider)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonValue = sender.doubleValue
    dnaRibbonAppearanceDidChange(updateIdentifiers: [ribbonsDNAHDRCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func toggleDNARibbonAmbientOcclusion(_ sender: NSButton)
  {
    guard proxyProject?.isEditable == true else { return }
    sender.allowsMixedState = false
    renderDNARibbonAmbientOcclusion = (sender.state == .on)
    updateOutlineView(identifiers: [ribbonsDNALightingCell])
    windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [])
    windowController?.detailTabViewController?.renderViewController?.updateAmbientOcclusion()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonAmbientTextField(_ sender: NSTextField)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonAmbientIntensity = sender.doubleValue
    updateOutlineView(identifiers: [ribbonsDNALightingCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonAmbientIntensitySlider(_ sender: NSSlider)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonAmbientIntensity = sender.doubleValue
    updateOutlineView(identifiers: [ribbonsDNALightingCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonAmbientColor(_ sender: NSColorWell)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonAmbientColor = sender.color
    updateOutlineView(identifiers: [ribbonsDNALightingCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonDiffuseTextField(_ sender: NSTextField)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonDiffuseIntensity = sender.doubleValue
    updateOutlineView(identifiers: [ribbonsDNALightingCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonDiffuseIntensitySlider(_ sender: NSSlider)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonDiffuseIntensity = sender.doubleValue
    updateOutlineView(identifiers: [ribbonsDNALightingCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonDiffuseColor(_ sender: NSColorWell)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonDiffuseColor = sender.color
    updateOutlineView(identifiers: [ribbonsDNALightingCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonSpecularTextField(_ sender: NSTextField)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonSpecularIntensity = sender.doubleValue
    updateOutlineView(identifiers: [ribbonsDNALightingCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonSpecularIntensitySlider(_ sender: NSSlider)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonSpecularIntensity = sender.doubleValue
    updateOutlineView(identifiers: [ribbonsDNALightingCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonSpecularColor(_ sender: NSColorWell)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonSpecularColor = sender.color
    updateOutlineView(identifiers: [ribbonsDNALightingCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonShininessTextField(_ sender: NSTextField)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonShininess = sender.doubleValue
    updateOutlineView(identifiers: [ribbonsDNALightingCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }

  @IBAction func changeDNARibbonShininessSlider(_ sender: NSSlider)
  {
    guard proxyProject?.isEditable == true else { return }
    renderDNARibbonShininess = sender.doubleValue
    updateOutlineView(identifiers: [ribbonsDNALightingCell])
    windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
    windowController?.detailTabViewController?.renderViewController?.redraw()
    windowController?.document?.updateChangeCount(.changeDone)
    proxyProject?.representedObject.isEdited = true
  }
}
