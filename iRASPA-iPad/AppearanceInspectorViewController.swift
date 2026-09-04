import UIKit
import iRASPAKit
import RenderKit
import SimulationKit
import SymmetryKit
import MathKit
import simd

/// iPadOS port of the Cocoa "Appearance" detail view (StructureAppearanceDetailViewController).
/// Sections mirror the Cocoa outline groups and sub-cells one-to-one:
/// Primitive (orientation, transformation, properties, selection, HSV, front, back),
/// Ribbons (representation, HDR, lighting), Atoms (scaling, representation, selection,
/// HDR, lighting), Bonds (scaling, selection, HDR, lighting), Unit Cell, Local Axes,
/// Adsorption Surface (properties, HSV, front, back), and Annotation.
final class AppearanceInspectorViewController: CollapsibleTableViewController
{
  let document: iRASPAUIDocument
  var onChange: (() -> Void)?
  var onUniformChange: (() -> Void)?
  var onBackgroundChange: (() -> Void)?
  var onVisibilityChange: (() -> Void)?
  var onSurfaceAppearanceChange: (() -> Void)?
  var onBlockingPocketAppearanceChange: (() -> Void)?
  var onSurfaceChange: (() -> Void)?

  private var node: ProjectTreeNode?
  private var selectedObjects: [iRASPAObject] = []
  private var structure: Structure?
  private var primitive: Primitive?
  private var project: ProjectStructureNode?

  private let probes: [(String, Structure.ProbeMolecule)] = [
    ("Helium", .helium), ("Methane", .methane), ("Nitrogen", .nitrogen),
    ("Hydrogen", .hydrogen), ("Water", .water), ("CO₂", .co2),
    ("Xenon", .xenon), ("Krypton", .krypton), ("Argon", .argon),
    ("Custom", .custom)
  ]

  // Section indices, in the same order as the Cocoa outline groups
  private enum Section: Int, CaseIterable
  {
    case primitiveOrientation = 0
    case primitiveTransformation
    case primitiveProperties
    case primitiveSelection
    case primitiveHSV
    case primitiveFront
    case primitiveBack
    case ribbonRepresentation
    case ribbonHDR
    case ribbonLighting
    case atomsScaling
    case atomsRepresentation
    case atomsSelection
    case atomsHDR
    case atomsLighting
    case atomsVisibility
    case bondsScaling
    case bondsSelection
    case bondsHDR
    case bondsLighting
    case unitCell
    case localAxes
    case adsorptionProperties
    case adsorptionHSV
    case adsorptionFront
    case adsorptionBack
    case blockingPocketsProperties
    case blockingPocketsFront
    case annotation
  }

  private enum Effect
  {
    case uniforms          // structure uniforms only (colors, intensities, HSV, selection)
    case scene             // full scene reload (geometry, representation, fonts)
    case surfaceAppearance // isosurface uniforms only
    case pocketAppearance  // blocking pocket uniforms only
    case surfaceRecompute  // recompute adsorption surface
    case visibility        // atom visibility buffers
  }

  init(document: iRASPAUIDocument)
  {
    self.document = document
    super.init(style: .insetGrouped)
    title = "Appearance"
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  func reload(from node: ProjectTreeNode, objects: [iRASPAObject]? = nil)
  {
    self.node = node
    try? node.unwrapProject(outlineView: nil, queue: nil, colorSets: document.colorSets, forceFieldSets: document.forceFieldSets, reloadCompletionBlock: {})
    project = node.representedObject.loadedProjectStructureNode
    if let objects
    {
      selectedObjects = objects
    }
    else if let selected = project?.sceneList.selectedScene?.selectedMovie?.selectedFrame
    {
      selectedObjects = [selected]
    }
    else
    {
      selectedObjects = project?.sceneList.allIRASPObjects ?? []
    }
    structure = selectedObjects.compactMap({ $0.object as? Structure }).first
    primitive = selectedObjects.compactMap({ $0.object as? Primitive }).first
    tableView.reloadData()
  }

  // MARK: Object collections

  private func allStructures() -> [Structure]
  {
    let selected = selectedObjects.compactMap({ $0.object as? Structure })
    if !selected.isEmpty { return selected }
    return project?.allObjects.compactMap({ $0 as? Structure }) ?? []
  }

  private func allPrimitives() -> [Primitive]
  {
    let selected = selectedObjects.compactMap({ $0.object as? Primitive })
    if !selected.isEmpty { return selected }
    return project?.allObjects.compactMap({ $0 as? Primitive }) ?? []
  }

  private func proteinRibbonEditors() -> [ProteinRibbonStructureEditor]
  {
    return selectedObjects.compactMap({ $0.object as? ProteinRibbonStructureEditor })
  }

  private func dnaRibbonEditors() -> [DNARibbonStructureEditor]
  {
    return selectedObjects.compactMap({ $0.object as? DNARibbonStructureEditor })
  }

  private func hasRibbon() -> Bool
  {
    return !proteinRibbonEditors().isEmpty || !dnaRibbonEditors().isEmpty
  }

  private func fire(_ effect: Effect)
  {
    document.updateChangeCount(.done)
    switch effect
    {
    case .uniforms: onUniformChange?()
    case .scene: onChange?()
    case .surfaceAppearance: onSurfaceAppearanceChange?()
    case .pocketAppearance: onBlockingPocketAppearanceChange?()
    case .surfaceRecompute: onSurfaceChange?()
    case .visibility: onVisibilityChange?()
    }
  }

  // MARK: Ribbon accessors shared between protein and DNA editors

  private var firstRibbonDraw: Bool { proteinRibbonEditors().first?.drawRibbon ?? dnaRibbonEditors().first?.drawRibbon ?? false }
  private var firstRibbonScale: Double { proteinRibbonEditors().first?.ribbonScaleFactor ?? dnaRibbonEditors().first?.ribbonScaleFactor ?? 1.2 }
  private var firstRibbonHDR: Bool { proteinRibbonEditors().first?.ribbonHDR ?? dnaRibbonEditors().first?.ribbonHDR ?? true }
  private var firstRibbonHDRExposure: Double { proteinRibbonEditors().first?.ribbonHDRExposure ?? dnaRibbonEditors().first?.ribbonHDRExposure ?? 1.5 }

  // MARK: Sections

  override func inspectorSectionCount() -> Int
  {
    return Section.allCases.count
  }

  override func inspectorGroupHeader(_ section: Int) -> String?
  {
    // Static root-node titles from the Cocoa Appearance outline view.
    switch Section(rawValue: section)
    {
    case .primitiveOrientation: return "Primitive Properties"
    case .ribbonRepresentation: return proteinRibbonEditors().isEmpty ? "Ribbons (DNA)" : "Ribbons (Protein)"
    case .atomsScaling: return "Atoms"
    case .bondsScaling: return "Bonds"
    case .unitCell: return "Unit cell"
    case .localAxes: return "Local Axes"
    case .adsorptionProperties: return "Volumetric Data"
    case .blockingPocketsProperties: return "Blocking Pockets"
    case .annotation: return "Annotation"
    default: return nil
    }
  }

  override func inspectorSectionTitle(_ section: Int) -> String
  {
    guard let section = Section(rawValue: section) else { return "" }
    let hasPrimitive = primitive != nil
    let hasStructure = structure != nil
    switch section
    {
    case .primitiveOrientation: return hasPrimitive ? "Orientation" : ""
    case .primitiveTransformation: return hasPrimitive ? "Transformation" : ""
    case .primitiveProperties: return hasPrimitive ? "Properties" : ""
    case .primitiveSelection: return hasPrimitive ? "Selection" : ""
    case .primitiveHSV: return hasPrimitive ? "HSV" : ""
    case .primitiveFront: return hasPrimitive ? "Front Side" : ""
    case .primitiveBack: return hasPrimitive ? "Back Side" : ""
    case .ribbonRepresentation: return hasRibbon() ? "Representation" : ""
    case .ribbonHDR: return hasRibbon() ? "HDR" : ""
    case .ribbonLighting: return hasRibbon() ? "Lighting" : ""
    case .atomsScaling: return hasStructure ? "Scaling" : ""
    case .atomsRepresentation: return hasStructure ? "Representation" : ""
    case .atomsSelection: return hasStructure ? "Selection" : ""
    case .atomsHDR: return hasStructure ? "HDR" : ""
    case .atomsLighting: return hasStructure ? "Lighting" : ""
    case .atomsVisibility: return hasStructure ? "Visibility" : ""
    case .bondsScaling: return hasStructure ? "Scaling" : ""
    case .bondsSelection: return hasStructure ? "Selection" : ""
    case .bondsHDR: return hasStructure ? "HDR" : ""
    case .bondsLighting: return hasStructure ? "Lighting" : ""
    case .unitCell: return hasStructure ? "Scaling" : ""
    case .localAxes: return hasStructure ? "Style & Position" : ""
    case .adsorptionProperties: return hasStructure ? "Properties" : ""
    case .adsorptionHSV: return hasStructure ? "HSV" : ""
    case .adsorptionFront: return hasStructure ? "Front Side" : ""
    case .adsorptionBack: return hasStructure ? "Back Side" : ""
    case .blockingPocketsProperties: return hasStructure ? "Properties" : ""
    case .blockingPocketsFront: return hasStructure ? "Outside Surface" : ""
    case .annotation: return hasStructure ? "Type & Style" : ""
    }
  }

  override func inspectorFooterTitle(_ section: Int) -> String?
  {
    if Section(rawValue: section) == .atomsScaling
    {
      if selectedObjects.isEmpty { return "Select a project, movie, or frame to edit." }
      if selectedObjects.count == 1 { return "Editing \(selectedObjects[0].object.displayName)" }
      return "Editing \(selectedObjects.count) selected structures"
    }
    return nil
  }

  override func inspectorRowCount(in section: Int) -> Int
  {
    guard let section = Section(rawValue: section) else { return 0 }
    switch section
    {
    case .primitiveOrientation: return 7
    case .primitiveTransformation: return 3
    case .primitiveProperties: return 4
    case .primitiveSelection: return 5
    case .primitiveHSV: return 3
    case .primitiveFront: return 9
    case .primitiveBack: return 9
    case .ribbonRepresentation: return proteinRibbonEditors().isEmpty ? 2 : 6
    case .ribbonHDR: return 5
    case .ribbonLighting: return 8
    case .atomsScaling: return 2
    case .atomsRepresentation: return 5
    case .atomsSelection: return 5
    case .atomsHDR: return 5
    case .atomsLighting: return 8
    case .atomsVisibility: return 5
    case .bondsScaling: return 3
    case .bondsSelection: return 5
    case .bondsHDR: return 5
    case .bondsLighting: return 8
    case .unitCell: return 5
    case .localAxes: return 6
    case .adsorptionProperties: return 12
    case .adsorptionHSV: return 3
    case .adsorptionFront: return 9
    case .adsorptionBack: return 9
    case .blockingPocketsProperties: return 1
    case .blockingPocketsFront: return 9
    case .annotation: return 8
    }
  }

  // MARK: Cells

  override func inspectorCell(for indexPath: IndexPath) -> UITableViewCell
  {
    guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }
    switch section
    {
    case .primitiveOrientation: return primitiveOrientationCell(row: indexPath.row)
    case .primitiveTransformation: return primitiveTransformationCell(row: indexPath.row)
    case .primitiveProperties: return primitivePropertiesCell(row: indexPath.row)
    case .primitiveSelection: return primitiveSelectionCell(row: indexPath.row)
    case .primitiveHSV: return primitiveHSVCell(row: indexPath.row)
    case .primitiveFront: return primitiveSideCell(row: indexPath.row, front: true)
    case .primitiveBack: return primitiveSideCell(row: indexPath.row, front: false)
    case .ribbonRepresentation: return ribbonRepresentationCell(row: indexPath.row)
    case .ribbonHDR: return ribbonHDRCell(row: indexPath.row)
    case .ribbonLighting: return ribbonLightingCell(row: indexPath.row)
    case .atomsScaling: return atomsScalingCell(row: indexPath.row)
    case .atomsRepresentation: return atomsRepresentationCell(row: indexPath.row)
    case .atomsSelection: return atomsSelectionCell(row: indexPath.row)
    case .atomsHDR: return atomsHDRCell(row: indexPath.row)
    case .atomsLighting: return atomsLightingCell(row: indexPath.row)
    case .atomsVisibility: return atomsVisibilityCell(row: indexPath.row)
    case .bondsScaling: return bondsScalingCell(row: indexPath.row)
    case .bondsSelection: return bondsSelectionCell(row: indexPath.row)
    case .bondsHDR: return bondsHDRCell(row: indexPath.row)
    case .bondsLighting: return bondsLightingCell(row: indexPath.row)
    case .unitCell: return unitCellCell(row: indexPath.row)
    case .localAxes: return localAxesCell(row: indexPath.row)
    case .adsorptionProperties: return adsorptionPropertiesCell(row: indexPath.row)
    case .adsorptionHSV: return adsorptionHSVCell(row: indexPath.row)
    case .adsorptionFront: return adsorptionSideCell(row: indexPath.row, front: true)
    case .adsorptionBack: return adsorptionSideCell(row: indexPath.row, front: false)
    case .blockingPocketsProperties: return blockingPocketsPropertiesCell(row: indexPath.row)
    case .blockingPocketsFront: return blockingPocketsSurfaceCell(row: indexPath.row)
    case .annotation: return annotationCell(row: indexPath.row)
    }
  }

  override func inspectorDidSelect(at indexPath: IndexPath)
  {
    tableView.deselectRow(at: indexPath, animated: true)
    guard Section(rawValue: indexPath.section) == .atomsVisibility else { return }
    switch indexPath.row
    {
    case 1: hideSelectedAtoms()
    case 2: showAllAtoms()
    case 3: invertVisibility()
    case 4: isolateSelectedAtoms()
    default: break
    }
  }

  // MARK: Primitive sections

  private func primitiveOrientationCell(row: Int) -> UITableViewCell
  {
    let euler = primitive?.primitiveOrientation.EulerAngles ?? SIMD3<Double>(0, 0, 0)
    let toDegrees = 180.0 / Double.pi
    switch row
    {
    case 0:
      return rotationRow("Rotate yaw ±", minus: { [weak self] in self?.rotatePrimitives(simd_quatd(yaw: -(self?.primitive?.primitiveRotationDelta ?? 5.0))) },
                         plus: { [weak self] in self?.rotatePrimitives(simd_quatd(yaw: self?.primitive?.primitiveRotationDelta ?? 5.0)) })
    case 1:
      return rotationRow("Rotate pitch ±", minus: { [weak self] in self?.rotatePrimitives(simd_quatd(pitch: -(self?.primitive?.primitiveRotationDelta ?? 5.0))) },
                         plus: { [weak self] in self?.rotatePrimitives(simd_quatd(pitch: self?.primitive?.primitiveRotationDelta ?? 5.0)) })
    case 2:
      return rotationRow("Rotate roll ±", minus: { [weak self] in self?.rotatePrimitives(simd_quatd(roll: -(self?.primitive?.primitiveRotationDelta ?? 5.0))) },
                         plus: { [weak self] in self?.rotatePrimitives(simd_quatd(roll: self?.primitive?.primitiveRotationDelta ?? 5.0)) })
    case 3:
      return fieldRow("Rotation delta (°)", value: primitive?.primitiveRotationDelta ?? 5.0, format: "%.2f", effect: .uniforms) { [weak self] value in
        self?.allPrimitives().forEach { $0.primitiveRotationDelta = value }
      }
    case 4:
      return sliderRow("Euler x (°)", value: euler.x * toDegrees, min: -180, max: 180, format: "%.1f", effect: .scene) { [weak self] value in
        self?.setPrimitiveEuler(component: 0, degrees: value)
      }
    case 5:
      return sliderRow("Euler y (°)", value: euler.y * toDegrees, min: -90, max: 90, format: "%.1f", effect: .scene) { [weak self] value in
        self?.setPrimitiveEuler(component: 1, degrees: value)
      }
    default:
      return sliderRow("Euler z (°)", value: euler.z * toDegrees, min: -180, max: 180, format: "%.1f", effect: .scene) { [weak self] value in
        self?.setPrimitiveEuler(component: 2, degrees: value)
      }
    }
  }

  private func rotatePrimitives(_ dq: simd_quatd)
  {
    allPrimitives().forEach { primitive in
      primitive.primitiveOrientation = primitive.primitiveOrientation * dq
      primitive.reComputeBoundingBox()
    }
    if let project { project.renderCamera?.boundingBox = project.renderBoundingBox }
    fire(.scene)
    tableView.reloadData()
  }

  private func setPrimitiveEuler(component: Int, degrees: Double)
  {
    let radians = degrees * Double.pi / 180.0
    allPrimitives().forEach { primitive in
      var angles = primitive.primitiveOrientation.EulerAngles
      angles[component] = radians
      primitive.primitiveOrientation = simd_quatd(EulerAngles: angles)
      primitive.reComputeBoundingBox()
    }
    if let project { project.renderCamera?.boundingBox = project.renderBoundingBox }
  }

  private func primitiveTransformationCell(row: Int) -> UITableViewCell
  {
    let matrix = primitive?.primitiveTransformationMatrix ?? double3x3(1.0)
    let names = ["a", "b", "c"]
    let column = SIMD3<Double>(matrix[row][0], matrix[row][1], matrix[row][2])
    return tripleFieldRow("Column \(names[row])", values: column, format: "%.3f", effect: .scene) { [weak self] index, value in
      self?.allPrimitives().forEach { primitive in
        primitive.primitiveTransformationMatrix[row][index] = value
        primitive.reComputeBoundingBox()
      }
      if let project = self?.project { project.renderCamera?.boundingBox = project.renderBoundingBox }
    }
  }

  private func primitivePropertiesCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return sliderRow("Opacity", value: primitive?.primitiveOpacity ?? 1.0, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.allPrimitives().forEach { $0.primitiveOpacity = value }
      }
    case 1:
      return sliderRow("Number of sides", value: Double(primitive?.primitiveNumberOfSides ?? 6), min: 2, max: 41, format: "%.0f", effect: .scene) { [weak self] value in
        self?.allPrimitives().forEach { $0.primitiveNumberOfSides = Int(value.rounded()) }
      }
    case 2:
      return switchRow("Capped", isOn: primitive?.primitiveIsCapped ?? false, effect: .scene) { [weak self] isOn in
        self?.allPrimitives().forEach { $0.primitiveIsCapped = isOn }
      }
    default:
      return switchRow("Fractional", isOn: primitive?.primitiveIsFractional ?? true, effect: .scene) { [weak self] isOn in
        self?.allPrimitives().forEach { $0.primitiveIsFractional = isOn }
      }
    }
  }

  private func primitiveSelectionCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return menuRow("Style", options: ["None", "Worley noise 3D", "Striped", "Glow"],
                     selectedIndex: primitive?.primitiveSelectionStyle.rawValue, effect: .uniforms) { [weak self] index in
        let style = RKSelectionStyle(rawValue: index) ?? .none
        self?.allPrimitives().forEach { $0.primitiveSelectionStyle = style }
      }
    case 1:
      return fieldRow("Frequency", value: primitive?.renderPrimitiveSelectionFrequency ?? 0, effect: .uniforms) { [weak self] value in
        self?.allPrimitives().forEach { $0.renderPrimitiveSelectionFrequency = value }
      }
    case 2:
      return fieldRow("Density", value: primitive?.renderPrimitiveSelectionDensity ?? 0, effect: .uniforms) { [weak self] value in
        self?.allPrimitives().forEach { $0.renderPrimitiveSelectionDensity = value }
      }
    case 3:
      return sliderRow("Intensity", value: primitive?.primitiveSelectionIntensity ?? 1.0, min: 0, max: 2, effect: .uniforms) { [weak self] value in
        self?.allPrimitives().forEach { $0.primitiveSelectionIntensity = value }
      }
    default:
      return sliderRow("Scaling", value: primitive?.primitiveSelectionScaling ?? 1.0, min: 1, max: 2, effect: .uniforms) { [weak self] value in
        self?.allPrimitives().forEach { $0.primitiveSelectionScaling = value }
      }
    }
  }

  private func primitiveHSVCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return sliderRow("Hue", value: primitive?.primitiveHue ?? 1.0, min: 0, max: 1.5, effect: .uniforms) { [weak self] value in
        self?.allPrimitives().forEach { $0.primitiveHue = value }
      }
    case 1:
      return sliderRow("Saturation", value: primitive?.primitiveSaturation ?? 1.0, min: 0, max: 1.5, effect: .uniforms) { [weak self] value in
        self?.allPrimitives().forEach { $0.primitiveSaturation = value }
      }
    default:
      return sliderRow("Value", value: primitive?.primitiveValue ?? 1.0, min: 0, max: 1.5, effect: .uniforms) { [weak self] value in
        self?.allPrimitives().forEach { $0.primitiveValue = value }
      }
    }
  }

  private func primitiveSideCell(row: Int, front: Bool) -> UITableViewCell
  {
    guard let primitive else { return UITableViewCell() }
    switch row
    {
    case 0:
      return switchRow("High dynamic range", isOn: front ? primitive.primitiveFrontSideHDR : primitive.primitiveBackSideHDR, effect: .uniforms) { [weak self] isOn in
        self?.allPrimitives().forEach { if front { $0.primitiveFrontSideHDR = isOn } else { $0.primitiveBackSideHDR = isOn } }
      }
    case 1:
      return sliderRow("Exposure", value: front ? primitive.primitiveFrontSideHDRExposure : primitive.primitiveBackSideHDRExposure, min: 0, max: 3, effect: .uniforms) { [weak self] value in
        self?.allPrimitives().forEach { if front { $0.primitiveFrontSideHDRExposure = value } else { $0.primitiveBackSideHDRExposure = value } }
      }
    case 2:
      return sliderRow("Ambient intensity", value: front ? primitive.primitiveFrontSideAmbientIntensity : primitive.primitiveBackSideAmbientIntensity, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.allPrimitives().forEach { if front { $0.primitiveFrontSideAmbientIntensity = value } else { $0.primitiveBackSideAmbientIntensity = value } }
      }
    case 3:
      return colorRow("Ambient color", color: front ? primitive.primitiveFrontSideAmbientColor : primitive.primitiveBackSideAmbientColor, effect: .uniforms) { [weak self] color in
        self?.allPrimitives().forEach { if front { $0.primitiveFrontSideAmbientColor = color } else { $0.primitiveBackSideAmbientColor = color } }
      }
    case 4:
      return sliderRow("Diffuse intensity", value: front ? primitive.primitiveFrontSideDiffuseIntensity : primitive.primitiveBackSideDiffuseIntensity, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.allPrimitives().forEach { if front { $0.primitiveFrontSideDiffuseIntensity = value } else { $0.primitiveBackSideDiffuseIntensity = value } }
      }
    case 5:
      return colorRow("Diffuse color", color: front ? primitive.primitiveFrontSideDiffuseColor : primitive.primitiveBackSideDiffuseColor, effect: .uniforms) { [weak self] color in
        self?.allPrimitives().forEach { if front { $0.primitiveFrontSideDiffuseColor = color } else { $0.primitiveBackSideDiffuseColor = color } }
      }
    case 6:
      return sliderRow("Specular intensity", value: front ? primitive.primitiveFrontSideSpecularIntensity : primitive.primitiveBackSideSpecularIntensity, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.allPrimitives().forEach { if front { $0.primitiveFrontSideSpecularIntensity = value } else { $0.primitiveBackSideSpecularIntensity = value } }
      }
    case 7:
      return colorRow("Specular color", color: front ? primitive.primitiveFrontSideSpecularColor : primitive.primitiveBackSideSpecularColor, effect: .uniforms) { [weak self] color in
        self?.allPrimitives().forEach { if front { $0.primitiveFrontSideSpecularColor = color } else { $0.primitiveBackSideSpecularColor = color } }
      }
    default:
      return sliderRow("Shininess", value: front ? primitive.primitiveFrontSideShininess : primitive.primitiveBackSideShininess, min: 0.1, max: 256, format: "%.1f", effect: .uniforms) { [weak self] value in
        self?.allPrimitives().forEach { if front { $0.primitiveFrontSideShininess = value } else { $0.primitiveBackSideShininess = value } }
      }
    }
  }

  // MARK: Ribbon sections

  private func ribbonRepresentationCell(row: Int) -> UITableViewCell
  {
    let proteinEditors = proteinRibbonEditors()
    switch row
    {
    case 0:
      return switchRow("Draw ribbon", isOn: firstRibbonDraw, effect: .scene) { [weak self] isOn in
        self?.proteinRibbonEditors().forEach { editor in
          editor.drawRibbon = isOn
          if isOn { editor.rebuildBackbone() }
        }
        self?.dnaRibbonEditors().forEach { editor in
          editor.drawRibbon = isOn
          if isOn { editor.rebuildBackbone() }
        }
      }
    case 1:
      return sliderRow("Scaling", value: firstRibbonScale, min: 0.1, max: 2.0, effect: .scene) { [weak self] value in
        self?.proteinRibbonEditors().forEach { $0.ribbonScaleFactor = value }
        self?.dnaRibbonEditors().forEach { $0.ribbonScaleFactor = value }
      }
    case 2:
      let styles = ProteinRibbonRepresentationStyle.selectableCases
      let selected = styles.firstIndex(where: { $0 == proteinEditors.first?.ribbonRepresentationStyle })
      return menuRow("Style", options: styles.map { $0.displayName }, selectedIndex: selected, effect: .scene) { [weak self] index in
        self?.proteinRibbonEditors().forEach { $0.ribbonRepresentationStyle = styles[index] }
      }
    case 3:
      let sets = ProteinRibbonColorSet.allCases
      let selected = sets.firstIndex(where: { $0 == proteinEditors.first?.ribbonColorSet })
      return menuRow("Color set", options: sets.map { $0.displayName }, selectedIndex: selected, effect: .uniforms) { [weak self] index in
        self?.proteinRibbonEditors().forEach { $0.ribbonColorSet = sets[index] }
      }
    case 4:
      let methods = ProteinRibbonSecondaryStructureMethod.allCases
      let selected = methods.firstIndex(where: { $0 == proteinEditors.first?.ribbonSecondaryStructureMethod })
      return menuRow("Secondary structure", options: methods.map { $0.displayName }, selectedIndex: selected, effect: .scene) { [weak self] index in
        self?.proteinRibbonEditors().forEach { editor in
          editor.ribbonSecondaryStructureMethod = methods[index]
          (editor as? Protein)?.rebuildRibbonSecondaryStructureHierarchy()
          (editor as? ProteinCrystal)?.rebuildRibbonSecondaryStructureHierarchy()
        }
      }
    default:
      let splines = ProteinRibbonSplineType.allCases
      let selected = splines.firstIndex(where: { $0 == proteinEditors.first?.ribbonSplineType })
      return menuRow("Spline", options: splines.map { $0.displayName }, selectedIndex: selected, effect: .scene) { [weak self] index in
        self?.proteinRibbonEditors().forEach { $0.ribbonSplineType = splines[index] }
      }
    }
  }

  private func ribbonHDRCell(row: Int) -> UITableViewCell
  {
    let protein = proteinRibbonEditors().first
    let dna = dnaRibbonEditors().first
    switch row
    {
    case 0:
      return switchRow("High dynamic range", isOn: firstRibbonHDR, effect: .uniforms) { [weak self] isOn in
        self?.proteinRibbonEditors().forEach { $0.ribbonHDR = isOn }
        self?.dnaRibbonEditors().forEach { $0.ribbonHDR = isOn }
      }
    case 1:
      return sliderRow("Exposure", value: firstRibbonHDRExposure, min: 0, max: 3, effect: .uniforms) { [weak self] value in
        self?.proteinRibbonEditors().forEach { $0.ribbonHDRExposure = value }
        self?.dnaRibbonEditors().forEach { $0.ribbonHDRExposure = value }
      }
    case 2:
      return sliderRow("Hue", value: protein?.ribbonHue ?? dna?.ribbonHue ?? 1.0, min: 0, max: 1.5, effect: .uniforms) { [weak self] value in
        self?.proteinRibbonEditors().forEach { $0.ribbonHue = value }
        self?.dnaRibbonEditors().forEach { $0.ribbonHue = value }
      }
    case 3:
      return sliderRow("Saturation", value: protein?.ribbonSaturation ?? dna?.ribbonSaturation ?? 1.0, min: 0, max: 1.5, effect: .uniforms) { [weak self] value in
        self?.proteinRibbonEditors().forEach { $0.ribbonSaturation = value }
        self?.dnaRibbonEditors().forEach { $0.ribbonSaturation = value }
      }
    default:
      return sliderRow("Value", value: protein?.ribbonValue ?? dna?.ribbonValue ?? 1.0, min: 0, max: 1.5, effect: .uniforms) { [weak self] value in
        self?.proteinRibbonEditors().forEach { $0.ribbonValue = value }
        self?.dnaRibbonEditors().forEach { $0.ribbonValue = value }
      }
    }
  }

  private func ribbonLightingCell(row: Int) -> UITableViewCell
  {
    let protein = proteinRibbonEditors().first
    let dna = dnaRibbonEditors().first
    switch row
    {
    case 0:
      return switchRow("Ambient occlusion", isOn: protein?.ribbonAmbientOcclusion ?? dna?.ribbonAmbientOcclusion ?? false, effect: .scene) { [weak self] isOn in
        self?.proteinRibbonEditors().forEach { $0.ribbonAmbientOcclusion = isOn }
        self?.dnaRibbonEditors().forEach { $0.ribbonAmbientOcclusion = isOn }
      }
    case 1:
      return sliderRow("Ambient intensity", value: protein?.ribbonAmbientIntensity ?? dna?.ribbonAmbientIntensity ?? 0.2, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.proteinRibbonEditors().forEach { $0.ribbonAmbientIntensity = value }
        self?.dnaRibbonEditors().forEach { $0.ribbonAmbientIntensity = value }
      }
    case 2:
      return colorRow("Ambient color", color: protein?.ribbonAmbientColor ?? dna?.ribbonAmbientColor ?? .white, effect: .uniforms) { [weak self] color in
        self?.proteinRibbonEditors().forEach { $0.ribbonAmbientColor = color }
        self?.dnaRibbonEditors().forEach { $0.ribbonAmbientColor = color }
      }
    case 3:
      return sliderRow("Diffuse intensity", value: protein?.ribbonDiffuseIntensity ?? dna?.ribbonDiffuseIntensity ?? 1.0, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.proteinRibbonEditors().forEach { $0.ribbonDiffuseIntensity = value }
        self?.dnaRibbonEditors().forEach { $0.ribbonDiffuseIntensity = value }
      }
    case 4:
      return colorRow("Diffuse color", color: protein?.ribbonDiffuseColor ?? dna?.ribbonDiffuseColor ?? .white, effect: .uniforms) { [weak self] color in
        self?.proteinRibbonEditors().forEach { $0.ribbonDiffuseColor = color }
        self?.dnaRibbonEditors().forEach { $0.ribbonDiffuseColor = color }
      }
    case 5:
      return sliderRow("Specular intensity", value: protein?.ribbonSpecularIntensity ?? dna?.ribbonSpecularIntensity ?? 1.0, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.proteinRibbonEditors().forEach { $0.ribbonSpecularIntensity = value }
        self?.dnaRibbonEditors().forEach { $0.ribbonSpecularIntensity = value }
      }
    case 6:
      return colorRow("Specular color", color: protein?.ribbonSpecularColor ?? dna?.ribbonSpecularColor ?? .white, effect: .uniforms) { [weak self] color in
        self?.proteinRibbonEditors().forEach { $0.ribbonSpecularColor = color }
        self?.dnaRibbonEditors().forEach { $0.ribbonSpecularColor = color }
      }
    default:
      return sliderRow("Shininess", value: protein?.ribbonShininess ?? dna?.ribbonShininess ?? 6.0, min: 0.1, max: 128, format: "%.1f", effect: .uniforms) { [weak self] value in
        self?.proteinRibbonEditors().forEach { $0.ribbonShininess = value }
        self?.dnaRibbonEditors().forEach { $0.ribbonShininess = value }
      }
    }
  }

  // MARK: Atoms sections

  private func atomsScalingCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return switchRow("Draw atoms", isOn: structure?.drawAtoms ?? true, effect: .scene) { [weak self] isOn in
        self?.allStructures().forEach { $0.drawAtoms = isOn }
      }
    default:
      return sliderRow("Atom scaling", value: structure?.atomScaleFactor ?? 1.0, min: 0.1, max: 2.0, effect: .scene) { [weak self] value in
        self?.allStructures().forEach { $0.atomScaleFactor = value }
      }
    }
  }

  private func atomsRepresentationCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return menuRow("Type", options: ["Ball and stick", "Van der Waals", "Unity"],
                     selectedIndex: structure?.atomRepresentationType.rawValue, effect: .scene) { [weak self] index in
        let type = Structure.RepresentationType(rawValue: index) ?? .sticks_and_balls
        self?.allStructures().forEach {
          $0.setRepresentationType(type: type)
          $0.recheckRepresentationStyle()
        }
      }
    case 1:
      let styles = Structure.RepresentationStyle.selectableCases
      let selected = styles.firstIndex(where: { $0 == structure?.atomRepresentationStyle })
      return menuRow("Style", options: styles.map { $0.displayName },
                     selectedIndex: selected, placeholder: "Custom", effect: .scene) { [weak self] index in
        guard let self else { return }
        let style = styles[index]
        self.allStructures().forEach { $0.setRepresentationStyle(style: style, colorSets: self.document.colorSets) }
      }
    case 2:
      var names: [String] = []
      for index in 0..<document.colorSets.count { names.append(document.colorSets[index].displayName) }
      let selected = names.firstIndex(where: { $0 == structure?.atomColorSchemeIdentifier })
      return menuRow("Color scheme", options: names, selectedIndex: selected, effect: .scene) { [weak self] index in
        guard let self else { return }
        self.allStructures().forEach { $0.setRepresentationColorScheme(scheme: names[index], colorSets: self.document.colorSets) }
      }
    case 3:
      return menuRow("Color order", options: ["Element", "Force field first", "Force field only"],
                     selectedIndex: structure?.atomColorSchemeOrder.rawValue, effect: .scene) { [weak self] index in
        guard let self else { return }
        let order = SKColorSets.ColorOrder(rawValue: index) ?? .elementOnly
        self.allStructures().forEach { $0.setRepresentationColorOrder(order: order, colorSets: self.document.colorSets) }
      }
    default:
      return menuRow("Force field order", options: ["Element", "Force field first", "Force field only"],
                     selectedIndex: structure?.atomForceFieldOrder.rawValue, effect: .scene) { [weak self] index in
        guard let self else { return }
        let order = SKForceFieldSets.ForceFieldOrder(rawValue: index) ?? .elementOnly
        self.allStructures().forEach { $0.setRepresentationForceFieldOrder(order: order, forceFieldSets: self.document.forceFieldSets) }
      }
    }
  }

  private func atomsSelectionCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return menuRow("Style", options: ["None", "Worley noise 3D", "Striped", "Glow"],
                     selectedIndex: structure?.atomSelectionStyle.rawValue, effect: .uniforms) { [weak self] index in
        let style = RKSelectionStyle(rawValue: index) ?? .none
        self?.allStructures().forEach { $0.atomSelectionStyle = style }
      }
    case 1:
      return fieldRow("Frequency", value: structure?.renderAtomSelectionFrequency ?? 0, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.renderAtomSelectionFrequency = value }
      }
    case 2:
      return fieldRow("Density", value: structure?.renderAtomSelectionDensity ?? 0, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.renderAtomSelectionDensity = value }
      }
    case 3:
      return sliderRow("Intensity", value: structure?.atomSelectionIntensity ?? 0.5, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.atomSelectionIntensity = value }
      }
    default:
      return sliderRow("Scaling", value: structure?.atomSelectionScaling ?? 1.2, min: 1, max: 2, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.atomSelectionScaling = value }
      }
    }
  }

  private func atomsHDRCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return switchRow("High dynamic range", isOn: structure?.atomHDR ?? true, effect: .uniforms) { [weak self] isOn in
        self?.allStructures().forEach { $0.atomHDR = isOn }
      }
    case 1:
      return sliderRow("Exposure", value: structure?.atomHDRExposure ?? 1.5, min: 0, max: 3, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.atomHDRExposure = value }
      }
    case 2:
      return sliderRow("Hue", value: structure?.atomHue ?? 1.0, min: 0, max: 1.5, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.atomHue = value }
      }
    case 3:
      return sliderRow("Saturation", value: structure?.atomSaturation ?? 1.0, min: 0, max: 1.5, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.atomSaturation = value }
      }
    default:
      return sliderRow("Value", value: structure?.atomValue ?? 1.0, min: 0, max: 1.5, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.atomValue = value }
      }
    }
  }

  private func atomsLightingCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return switchRow("Ambient occlusion", isOn: structure?.atomAmbientOcclusion ?? true, effect: .scene) { [weak self] isOn in
        self?.allStructures().forEach { $0.atomAmbientOcclusion = isOn }
      }
    case 1:
      return sliderRow("Ambient intensity", value: structure?.atomAmbientIntensity ?? 0.2, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.atomAmbientIntensity = value }
      }
    case 2:
      return colorRow("Ambient color", color: structure?.atomAmbientColor ?? .white, effect: .uniforms) { [weak self] color in
        self?.allStructures().forEach { $0.atomAmbientColor = color }
      }
    case 3:
      return sliderRow("Diffuse intensity", value: structure?.atomDiffuseIntensity ?? 1.0, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.atomDiffuseIntensity = value }
      }
    case 4:
      return colorRow("Diffuse color", color: structure?.atomDiffuseColor ?? .white, effect: .uniforms) { [weak self] color in
        self?.allStructures().forEach { $0.atomDiffuseColor = color }
      }
    case 5:
      return sliderRow("Specular intensity", value: structure?.atomSpecularIntensity ?? 1.0, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.atomSpecularIntensity = value }
      }
    case 6:
      return colorRow("Specular color", color: structure?.atomSpecularColor ?? .white, effect: .uniforms) { [weak self] color in
        self?.allStructures().forEach { $0.atomSpecularColor = color }
      }
    default:
      return sliderRow("Shininess", value: structure?.atomShininess ?? 4.0, min: 0.1, max: 128, format: "%.1f", effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.atomShininess = value }
      }
    }
  }

  private func atomsVisibilityCell(row: Int) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    switch row
    {
    case 0:
      cell.selectionStyle = .none
      cell.textLabel?.text = "Hide hydrogens"
      cell.accessoryView = makeSwitch(isOn: hydrogensHidden()) { [weak self] isOn in
        self?.allStructures().forEach { structure in
          structure.atomTreeController.flattenedLeafNodes().compactMap({ $0.representedObject }).forEach { atom in
            if atom.elementIdentifier == 1 { atom.isVisible = !isOn }
          }
        }
        self?.fire(.visibility)
      }
    case 1:
      cell.textLabel?.text = "Hide selected"
      cell.accessoryType = .disclosureIndicator
    case 2:
      cell.textLabel?.text = "Show all atoms"
      cell.accessoryType = .disclosureIndicator
    case 3:
      cell.textLabel?.text = "Invert visibility"
      cell.accessoryType = .disclosureIndicator
    default:
      cell.textLabel?.text = "Show only selected"
      cell.accessoryType = .disclosureIndicator
    }
    return cell
  }

  // MARK: Bonds sections

  private func bondsScalingCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return switchRow("Draw bonds", isOn: structure?.drawBonds ?? true, effect: .scene) { [weak self] isOn in
        self?.allStructures().forEach { $0.drawBonds = isOn }
      }
    case 1:
      return sliderRow("Bond scaling", value: structure?.bondScaleFactor ?? 1.0, min: 0.1, max: 1.0, effect: .scene) { [weak self] value in
        self?.allStructures().forEach { $0.setBondScaleFactor(value) }
      }
    default:
      // Menu order matches RKBondColorMode raw values
      return menuRow("Color mode", options: ["Uniform", "Split", "Smoothed split"],
                     selectedIndex: structure?.bondColorMode.rawValue, effect: .scene) { [weak self] index in
        let mode = RKBondColorMode(rawValue: index) ?? .split
        self?.allStructures().forEach { $0.bondColorMode = mode }
      }
    }
  }

  private func bondsSelectionCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return menuRow("Style", options: ["None", "Worley noise 3D", "Striped", "Glow"],
                     selectedIndex: structure?.bondSelectionStyle.rawValue, effect: .uniforms) { [weak self] index in
        let style = RKSelectionStyle(rawValue: index) ?? .none
        self?.allStructures().forEach { $0.bondSelectionStyle = style }
      }
    case 1:
      return fieldRow("Frequency", value: structure?.renderBondSelectionFrequency ?? 0, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.renderBondSelectionFrequency = value }
      }
    case 2:
      return fieldRow("Density", value: structure?.renderBondSelectionDensity ?? 0, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.renderBondSelectionDensity = value }
      }
    case 3:
      return sliderRow("Intensity", value: structure?.bondSelectionIntensity ?? 0.5, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.bondSelectionIntensity = value }
      }
    default:
      return sliderRow("Scaling", value: structure?.bondSelectionScaling ?? 1.2, min: 1, max: 2, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.bondSelectionScaling = value }
      }
    }
  }

  private func bondsHDRCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return switchRow("High dynamic range", isOn: structure?.bondHDR ?? true, effect: .uniforms) { [weak self] isOn in
        self?.allStructures().forEach { $0.bondHDR = isOn }
      }
    case 1:
      return sliderRow("Exposure", value: structure?.bondHDRExposure ?? 1.5, min: 0, max: 3, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.bondHDRExposure = value }
      }
    case 2:
      return sliderRow("Hue", value: structure?.bondHue ?? 1.0, min: 0, max: 1.5, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.bondHue = value }
      }
    case 3:
      return sliderRow("Saturation", value: structure?.bondSaturation ?? 1.0, min: 0, max: 1.5, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.bondSaturation = value }
      }
    default:
      return sliderRow("Value", value: structure?.bondValue ?? 1.0, min: 0, max: 1.5, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.bondValue = value }
      }
    }
  }

  private func bondsLightingCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      // Disabled in the Cocoa UI as well: bond ambient occlusion is not supported
      let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
      cell.selectionStyle = .none
      cell.textLabel?.text = "Ambient occlusion"
      let control = UISwitch()
      control.isOn = structure?.bondAmbientOcclusion ?? false
      control.isEnabled = false
      cell.accessoryView = control
      return cell
    case 1:
      return sliderRow("Ambient intensity", value: structure?.bondAmbientIntensity ?? 0.1, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.bondAmbientIntensity = value }
      }
    case 2:
      return colorRow("Ambient color", color: structure?.bondAmbientColor ?? .white, effect: .uniforms) { [weak self] color in
        self?.allStructures().forEach { $0.bondAmbientColor = color }
      }
    case 3:
      return sliderRow("Diffuse intensity", value: structure?.bondDiffuseIntensity ?? 1.0, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.bondDiffuseIntensity = value }
      }
    case 4:
      return colorRow("Diffuse color", color: structure?.bondDiffuseColor ?? .white, effect: .uniforms) { [weak self] color in
        self?.allStructures().forEach { $0.bondDiffuseColor = color }
      }
    case 5:
      return sliderRow("Specular intensity", value: structure?.bondSpecularIntensity ?? 1.0, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.bondSpecularIntensity = value }
      }
    case 6:
      return colorRow("Specular color", color: structure?.bondSpecularColor ?? .white, effect: .uniforms) { [weak self] color in
        self?.allStructures().forEach { $0.bondSpecularColor = color }
      }
    default:
      return sliderRow("Shininess", value: structure?.bondShininess ?? 4.0, min: 0.1, max: 128, format: "%.1f", effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.bondShininess = value }
      }
    }
  }

  // MARK: Unit cell

  private func unitCellCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return switchRow("Draw unit cell", isOn: structure?.drawUnitCell ?? false, effect: .scene) { [weak self] isOn in
        self?.allStructures().forEach { $0.drawUnitCell = isOn }
      }
    case 1:
      return switchRow("Bounding box", isOn: project?.showBoundingBox ?? false, effect: .scene) { [weak self] isOn in
        self?.project?.showBoundingBox = isOn
      }
    case 2:
      return sliderRow("Scaling", value: structure?.unitCellScaleFactor ?? 1.0, min: 0, max: 2, effect: .scene) { [weak self] value in
        self?.allStructures().forEach { $0.unitCellScaleFactor = value }
      }
    case 3:
      return sliderRow("Light intensity", value: structure?.unitCellDiffuseIntensity ?? 1.0, min: 0, max: 1, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.unitCellDiffuseIntensity = value }
      }
    default:
      return colorRow("Color", color: structure?.unitCellDiffuseColor ?? .white, effect: .uniforms) { [weak self] color in
        self?.allStructures().forEach { $0.unitCellDiffuseColor = color }
      }
    }
  }

  // MARK: Local axes

  private func localAxesCell(row: Int) -> UITableViewCell
  {
    let axes = structure?.renderLocalAxis
    switch row
    {
    case 0:
      return menuRow("Position", options: ["None", "Origin", "Origin bounding box", "Center", "Center bounding box"],
                     selectedIndex: axes?.position.rawValue, effect: .scene) { [weak self] index in
        let position = RKLocalAxes.Position(rawValue: index) ?? .none
        self?.allStructures().forEach { $0.renderLocalAxis.position = position }
      }
    case 1:
      return menuRow("Style", options: ["Default", "Default RGB", "Cylinder", "Cylinder RGB"],
                     selectedIndex: axes?.style.rawValue, effect: .scene) { [weak self] index in
        let style = RKLocalAxes.Style(rawValue: index) ?? .default
        self?.allStructures().forEach { $0.renderLocalAxis.style = style }
      }
    case 2:
      return menuRow("Scaling type", options: ["Absolute", "Relative"],
                     selectedIndex: axes?.scalingType.rawValue, effect: .scene) { [weak self] index in
        let type = RKLocalAxes.ScalingType(rawValue: index) ?? .absolute
        self?.allStructures().forEach { $0.renderLocalAxis.scalingType = type }
      }
    case 3:
      return sliderRow("Length", value: axes?.length ?? 5.0, min: 0, max: 10, effect: .scene) { [weak self] value in
        self?.allStructures().forEach { $0.renderLocalAxis.length = value }
      }
    case 4:
      return sliderRow("Width", value: axes?.width ?? 0.5, min: 0, max: 2, effect: .scene) { [weak self] value in
        self?.allStructures().forEach { $0.renderLocalAxis.width = value }
      }
    default:
      return tripleFieldRow("Offset", values: axes?.offset ?? SIMD3<Double>(0, 0, 0), format: "%.2f", effect: .scene) { [weak self] index, value in
        self?.allStructures().forEach { $0.renderLocalAxis.offset[index] = value }
      }
    }
  }

  // MARK: Adsorption surface

  private func adsorptionPropertiesCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
      cell.selectionStyle = .none
      cell.textLabel?.text = "Show adsorption surface"
      cell.accessoryView = makeSwitch(isOn: structure?.drawAdsorptionSurface ?? false) { [weak self] isOn in
        self?.allStructures().forEach { $0.drawAdsorptionSurface = isOn }
        self?.document.updateChangeCount(.done)
        if isOn { self?.onSurfaceChange?() } else { self?.onChange?() }
      }
      return cell
    case 1:
      return switchRow("Apply blocking pockets", isOn: structure?.applyBlockingPockets ?? false, effect: .surfaceRecompute) { [weak self] isOn in
        self?.allStructures().forEach { $0.applyBlockingPockets = isOn }
      }
    case 2:
      return menuRow("Rendering method", options: ["Isosurface", "Volume rendering", "Well surface", "Well surface overlay", "Geometric surface"],
                     selectedIndex: structure?.adsorptionSurfaceRenderingMethod.rawValue, effect: .surfaceRecompute) { [weak self] index in
        let method = RKEnergySurfaceType(rawValue: index) ?? .isoSurface
        self?.allStructures().forEach { $0.adsorptionSurfaceRenderingMethod = method }
      }
    case 3:
      let current = structure?.adsorptionSurfaceProbeMolecule ?? .helium
      let selectedIndex = probes.firstIndex(where: { $0.1 == current })
      return menuRow("Probe molecule", options: probes.map { $0.0 },
                     selectedIndex: selectedIndex, effect: .surfaceRecompute) { [weak self] index in
        guard let self else { return }
        self.allStructures().forEach { $0.applyAdsorptionSurfaceProbeMolecule(self.probes[index].1) }
        self.tableView.reloadData()
      }
    case 4:
      let cell = fieldRow("Epsilon (K)", value: structure?.adsorptionSurfaceProbeEpsilon ?? 0, format: "%.4f", effect: .surfaceRecompute) { [weak self] value in
        guard let self else { return }
        self.allStructures().forEach { $0.setAdsorptionSurfaceProbeEpsilon(value) }
        self.tableView.reloadData()
      }
      if let label = cell.textLabel
      {
        label.attributedText = epsilonOverKBRowTitle(font: label.font ?? UIFont.preferredFont(forTextStyle: .body))
      }
      return cell
    case 5:
      return fieldRow("Sigma (Å)", value: structure?.adsorptionSurfaceProbeSigma ?? 0, format: "%.4f", effect: .surfaceRecompute) { [weak self] value in
        guard let self else { return }
        self.allStructures().forEach { $0.setAdsorptionSurfaceProbeSigma(value) }
        self.tableView.reloadData()
      }
    case 6:
      let viewer = structure as? VolumetricDataViewer
      var minimum = viewer?.range.0 ?? -1000.0
      var maximum = viewer?.range.1 ?? 0.0
      if !(minimum < maximum) { minimum = -1000.0; maximum = 0.0 }
      return sliderRow("Isovalue", value: structure?.adsorptionSurfaceIsoValue ?? 0.0, min: minimum, max: maximum, format: "%.1f", effect: .surfaceRecompute) { [weak self] value in
        self?.allStructures().forEach { $0.adsorptionSurfaceIsoValue = value }
      }
    case 7:
      return sliderRow("Opacity", value: structure?.adsorptionSurfaceOpacity ?? 1.0, min: 0, max: 1, effect: .surfaceAppearance) { [weak self] value in
        self?.allStructures().forEach { $0.adsorptionSurfaceOpacity = value }
      }
    case 8:
      return sliderRow("Transparency threshold", value: structure?.adsorptionTransparencyThreshold ?? 0.0, min: 0, max: 1, effect: .surfaceAppearance) { [weak self] value in
        self?.allStructures().forEach { $0.adsorptionTransparencyThreshold = value }
      }
    case 9:
      return fieldRow("Step length", value: structure?.adsorptionVolumeStepLength ?? 0.0005, format: "%.4f", effect: .surfaceAppearance) { [weak self] value in
        self?.allStructures().forEach { $0.adsorptionVolumeStepLength = value }
      }
    case 10:
      let functions = ["RASPA PES", "Cool-warm diverging", "X-ray", "Gray", "Rainbow", "Turbo", "Gnuplot", "Spectral", "Cool",
                       "Viridis", "Plasma", "Inferno", "Magma", "Cividis", "Spring", "Summer", "Autumn"]
      return menuRow("Transfer function", options: functions,
                     selectedIndex: structure?.adsorptionVolumeTransferFunction.rawValue, effect: .surfaceAppearance) { [weak self] index in
        let function = RKPredefinedVolumeRenderingTransferFunction(rawValue: index) ?? .RASPA_PES
        self?.allStructures().forEach { $0.adsorptionVolumeTransferFunction = function }
      }
    default:
      let powers = [4, 5, 6, 7, 8, 9]
      let labels = powers.map { "\(1 << $0)×\(1 << $0)×\(1 << $0)" }
      let selected = powers.firstIndex(of: structure?.encompassingPowerOfTwoCubicGridSize ?? 7)
      return menuRow("Grid size", options: labels, selectedIndex: selected, effect: .surfaceRecompute) { [weak self] index in
        self?.allStructures().forEach { $0.encompassingPowerOfTwoCubicGridSize = powers[index] }
      }
    }
  }

  private func adsorptionHSVCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return sliderRow("Hue", value: structure?.adsorptionSurfaceHue ?? 1.0, min: 0, max: 1.5, effect: .surfaceAppearance) { [weak self] value in
        self?.allStructures().forEach { $0.adsorptionSurfaceHue = value }
      }
    case 1:
      return sliderRow("Saturation", value: structure?.adsorptionSurfaceSaturation ?? 1.0, min: 0, max: 1.5, effect: .surfaceAppearance) { [weak self] value in
        self?.allStructures().forEach { $0.adsorptionSurfaceSaturation = value }
      }
    default:
      return sliderRow("Value", value: structure?.adsorptionSurfaceValue ?? 1.0, min: 0, max: 1.5, effect: .surfaceAppearance) { [weak self] value in
        self?.allStructures().forEach { $0.adsorptionSurfaceValue = value }
      }
    }
  }

  private func adsorptionSideCell(row: Int, front: Bool) -> UITableViewCell
  {
    guard let structure else { return UITableViewCell() }
    switch row
    {
    case 0:
      return switchRow("High dynamic range", isOn: front ? structure.adsorptionSurfaceFrontSideHDR : structure.adsorptionSurfaceBackSideHDR, effect: .surfaceAppearance) { [weak self] isOn in
        self?.allStructures().forEach { if front { $0.adsorptionSurfaceFrontSideHDR = isOn } else { $0.adsorptionSurfaceBackSideHDR = isOn } }
      }
    case 1:
      return sliderRow("Exposure", value: front ? structure.adsorptionSurfaceFrontSideHDRExposure : structure.adsorptionSurfaceBackSideHDRExposure, min: 0, max: 3, effect: .surfaceAppearance) { [weak self] value in
        self?.allStructures().forEach { if front { $0.adsorptionSurfaceFrontSideHDRExposure = value } else { $0.adsorptionSurfaceBackSideHDRExposure = value } }
      }
    case 2:
      return sliderRow("Ambient intensity", value: front ? structure.adsorptionSurfaceFrontSideAmbientIntensity : structure.adsorptionSurfaceBackSideAmbientIntensity, min: 0, max: 1, effect: .surfaceAppearance) { [weak self] value in
        self?.allStructures().forEach { if front { $0.adsorptionSurfaceFrontSideAmbientIntensity = value } else { $0.adsorptionSurfaceBackSideAmbientIntensity = value } }
      }
    case 3:
      return colorRow("Ambient color", color: front ? structure.adsorptionSurfaceFrontSideAmbientColor : structure.adsorptionSurfaceBackSideAmbientColor, effect: .surfaceAppearance) { [weak self] color in
        self?.allStructures().forEach { if front { $0.adsorptionSurfaceFrontSideAmbientColor = color } else { $0.adsorptionSurfaceBackSideAmbientColor = color } }
      }
    case 4:
      return sliderRow("Diffuse intensity", value: front ? structure.adsorptionSurfaceFrontSideDiffuseIntensity : structure.adsorptionSurfaceBackSideDiffuseIntensity, min: 0, max: 1, effect: .surfaceAppearance) { [weak self] value in
        self?.allStructures().forEach { if front { $0.adsorptionSurfaceFrontSideDiffuseIntensity = value } else { $0.adsorptionSurfaceBackSideDiffuseIntensity = value } }
      }
    case 5:
      return colorRow("Diffuse color", color: front ? structure.adsorptionSurfaceFrontSideDiffuseColor : structure.adsorptionSurfaceBackSideDiffuseColor, effect: .surfaceAppearance) { [weak self] color in
        self?.allStructures().forEach { if front { $0.adsorptionSurfaceFrontSideDiffuseColor = color } else { $0.adsorptionSurfaceBackSideDiffuseColor = color } }
      }
    case 6:
      return sliderRow("Specular intensity", value: front ? structure.adsorptionSurfaceFrontSideSpecularIntensity : structure.adsorptionSurfaceBackSideSpecularIntensity, min: 0, max: 1, effect: .surfaceAppearance) { [weak self] value in
        self?.allStructures().forEach { if front { $0.adsorptionSurfaceFrontSideSpecularIntensity = value } else { $0.adsorptionSurfaceBackSideSpecularIntensity = value } }
      }
    case 7:
      return colorRow("Specular color", color: front ? structure.adsorptionSurfaceFrontSideSpecularColor : structure.adsorptionSurfaceBackSideSpecularColor, effect: .surfaceAppearance) { [weak self] color in
        self?.allStructures().forEach { if front { $0.adsorptionSurfaceFrontSideSpecularColor = color } else { $0.adsorptionSurfaceBackSideSpecularColor = color } }
      }
    default:
      return sliderRow("Shininess", value: front ? structure.adsorptionSurfaceFrontSideShininess : structure.adsorptionSurfaceBackSideShininess, min: 0.1, max: 256, format: "%.1f", effect: .surfaceAppearance) { [weak self] value in
        self?.allStructures().forEach { if front { $0.adsorptionSurfaceFrontSideShininess = value } else { $0.adsorptionSurfaceBackSideShininess = value } }
      }
    }
  }

  // MARK: Blocking pockets

  private func blockingPocketsPropertiesCell(row: Int) -> UITableViewCell
  {
    return switchRow("Show blocking pockets", isOn: structure?.drawBlockingPockets ?? false, effect: .scene) { [weak self] isOn in
      self?.allStructures().forEach { $0.drawBlockingPockets = isOn }
    }
  }

  /// The pocket spheres are drawn two-sided from one material, so there is no inside counterpart here.
  private func blockingPocketsSurfaceCell(row: Int) -> UITableViewCell
  {
    guard let structure else { return UITableViewCell() }
    switch row
    {
    case 0:
      return switchRow("High dynamic range", isOn: structure.blockingPocketsFrontSideHDR, effect: .pocketAppearance) { [weak self] isOn in
        self?.allStructures().forEach { $0.blockingPocketsFrontSideHDR = isOn }
      }
    case 1:
      return sliderRow("Exposure", value: structure.blockingPocketsFrontSideHDRExposure, min: 0, max: 3, effect: .pocketAppearance) { [weak self] value in
        self?.allStructures().forEach { $0.blockingPocketsFrontSideHDRExposure = value }
      }
    case 2:
      return sliderRow("Ambient intensity", value: structure.blockingPocketsFrontSideAmbientIntensity, min: 0, max: 1, effect: .pocketAppearance) { [weak self] value in
        self?.allStructures().forEach { $0.blockingPocketsFrontSideAmbientIntensity = value }
      }
    case 3:
      return colorRow("Ambient color", color: structure.blockingPocketsFrontSideAmbientColor, effect: .pocketAppearance) { [weak self] color in
        self?.allStructures().forEach { $0.blockingPocketsFrontSideAmbientColor = color }
      }
    case 4:
      return sliderRow("Diffuse intensity", value: structure.blockingPocketsFrontSideDiffuseIntensity, min: 0, max: 1, effect: .pocketAppearance) { [weak self] value in
        self?.allStructures().forEach { $0.blockingPocketsFrontSideDiffuseIntensity = value }
      }
    case 5:
      return colorRow("Diffuse color", color: structure.blockingPocketsFrontSideDiffuseColor, effect: .pocketAppearance) { [weak self] color in
        self?.allStructures().forEach { $0.blockingPocketsFrontSideDiffuseColor = color }
      }
    case 6:
      return sliderRow("Specular intensity", value: structure.blockingPocketsFrontSideSpecularIntensity, min: 0, max: 1, effect: .pocketAppearance) { [weak self] value in
        self?.allStructures().forEach { $0.blockingPocketsFrontSideSpecularIntensity = value }
      }
    case 7:
      return colorRow("Specular color", color: structure.blockingPocketsFrontSideSpecularColor, effect: .pocketAppearance) { [weak self] color in
        self?.allStructures().forEach { $0.blockingPocketsFrontSideSpecularColor = color }
      }
    default:
      return sliderRow("Shininess", value: structure.blockingPocketsFrontSideShininess, min: 0.1, max: 256, format: "%.1f", effect: .pocketAppearance) { [weak self] value in
        self?.allStructures().forEach { $0.blockingPocketsFrontSideShininess = value }
      }
    }
  }

  // MARK: Annotation

  private func annotationCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return menuRow("Type", options: ["None", "Name", "Index", "Element", "Force field", "Position", "Charge"],
                     selectedIndex: structure?.atomTextType.rawValue, effect: .scene) { [weak self] index in
        let type = RKTextType(rawValue: index) ?? .none
        self?.allStructures().forEach { $0.atomTextType = type }
      }
    case 1:
      return colorRow("Color", color: structure?.atomTextColor ?? .black, effect: .uniforms) { [weak self] color in
        self?.allStructures().forEach { $0.atomTextColor = color }
      }
    case 2:
      let families = UIFont.familyNames.sorted()
      let currentFamily = (structure?.atomTextFont).flatMap { UIFont(name: $0, size: 12)?.familyName }
      let selected = families.firstIndex(where: { $0 == currentFamily })
      return menuRow("Font family", options: families, selectedIndex: selected, effect: .scene) { [weak self] index in
        let family = families[index]
        let fontName = UIFont.fontNames(forFamilyName: family).first ?? family
        self?.allStructures().forEach { $0.atomTextFont = fontName }
      }
    case 3:
      let currentFamily = (structure?.atomTextFont).flatMap { UIFont(name: $0, size: 12)?.familyName } ?? "Helvetica"
      let members = UIFont.fontNames(forFamilyName: currentFamily)
      let selected = members.firstIndex(where: { $0 == structure?.atomTextFont })
      return menuRow("Font", options: members, selectedIndex: selected, effect: .scene) { [weak self] index in
        self?.allStructures().forEach { $0.atomTextFont = members[index] }
      }
    case 4:
      return menuRow("Alignment", options: ["Center", "Left", "Right", "Top", "Bottom", "Top left", "Top right", "Bottom left", "Bottom right"],
                     selectedIndex: structure?.atomTextAlignment.rawValue, effect: .uniforms) { [weak self] index in
        let alignment = RKTextAlignment(rawValue: index) ?? .center
        self?.allStructures().forEach { $0.atomTextAlignment = alignment }
      }
    case 5:
      return menuRow("Style", options: ["Flat billboard"],
                     selectedIndex: structure?.atomTextStyle.rawValue, effect: .uniforms) { [weak self] index in
        let style = RKTextStyle(rawValue: index) ?? .flatBillboard
        self?.allStructures().forEach { $0.atomTextStyle = style }
      }
    case 6:
      return sliderRow("Scaling", value: structure?.atomTextScaling ?? 1.0, min: 0, max: 3, effect: .uniforms) { [weak self] value in
        self?.allStructures().forEach { $0.atomTextScaling = value }
      }
    default:
      return tripleFieldRow("Offset", values: structure?.atomTextOffset ?? SIMD3<Double>(0, 0, 0), format: "%.2f", effect: .uniforms) { [weak self] index, value in
        self?.allStructures().forEach { $0.atomTextOffset[index] = value }
      }
    }
  }

  // MARK: Visibility helpers

  private func hideSelectedAtoms()
  {
    allStructures().forEach { structure in
      for node in structure.atomTreeController.selectedTreeNodes
      {
        node.representedObject.isVisible = false
      }
    }
    fire(.visibility)
  }

  private func showAllAtoms()
  {
    allStructures().forEach { structure in
      structure.atomTreeController.flattenedLeafNodes().compactMap({ $0.representedObject }).forEach { $0.isVisible = true }
    }
    fire(.visibility)
  }

  private func invertVisibility()
  {
    allStructures().forEach { structure in
      structure.atomTreeController.flattenedLeafNodes().compactMap({ $0.representedObject }).forEach { $0.isVisible = !$0.isVisible }
    }
    fire(.visibility)
  }

  private func isolateSelectedAtoms()
  {
    allStructures().forEach { structure in
      let selected = Set(structure.atomTreeController.selectedTreeNodes.map { $0.representedObject })
      structure.atomTreeController.flattenedLeafNodes().compactMap({ $0.representedObject }).forEach { atom in
        atom.isVisible = selected.contains(atom)
      }
    }
    fire(.visibility)
  }

  private func hydrogensHidden() -> Bool
  {
    let hydrogens = allStructures().flatMap { $0.atomTreeController.flattenedLeafNodes().compactMap({ $0.representedObject }) }.filter { $0.elementIdentifier == 1 }
    guard !hydrogens.isEmpty else { return false }
    return hydrogens.allSatisfy { $0.isVisible == false }
  }

  // MARK: Row factories

  private func makeSwitch(isOn: Bool, handler: @escaping (Bool) -> Void) -> UISwitch
  {
    let control = UISwitch()
    control.isOn = isOn
    control.addAction(UIAction { action in
      guard let control = action.sender as? UISwitch else { return }
      handler(control.isOn)
    }, for: .valueChanged)
    return control
  }

  private func switchRow(_ title: String, isOn: Bool, effect: Effect, apply: @escaping (Bool) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    cell.accessoryView = makeSwitch(isOn: isOn) { [weak self] isOn in
      apply(isOn)
      self?.fire(effect)
    }
    return cell
  }

  private func sliderRow(_ title: String, value: Double, min: Double, max: Double, format: String = "%.2f", effect: Effect, apply: @escaping (Double) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    cell.detailTextLabel?.text = String(format: format, value)
    let slider = UISlider(frame: CGRect(x: 0, y: 0, width: 150, height: 30))
    slider.minimumValue = Float(min)
    slider.maximumValue = Float(max)
    slider.value = Float(value)
    // Cheap effects fire continuously; heavy reloads only fire when the drag ends.
    let firesContinuously = (effect == .uniforms || effect == .surfaceAppearance)
    slider.addAction(UIAction { [weak self, weak cell] action in
      guard let slider = action.sender as? UISlider else { return }
      let value = Double(slider.value)
      apply(value)
      cell?.detailTextLabel?.text = String(format: format, value)
      if firesContinuously { self?.fire(effect) }
    }, for: .valueChanged)
    if !firesContinuously
    {
      slider.addAction(UIAction { [weak self] _ in self?.fire(effect) }, for: .touchUpInside)
      slider.addAction(UIAction { [weak self] _ in self?.fire(effect) }, for: .touchUpOutside)
    }
    cell.accessoryView = slider
    return cell
  }

  private func colorRow(_ title: String, color: UIColor, effect: Effect, apply: @escaping (UIColor) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    let well = UIColorWell()
    well.supportsAlpha = false
    well.selectedColor = color
    well.addAction(UIAction { [weak self] action in
      guard let well = action.sender as? UIColorWell, let color = well.selectedColor else { return }
      apply(color)
      self?.fire(effect)
    }, for: .valueChanged)
    cell.accessoryView = well.inspectorAccessory()
    return cell
  }

  private func menuRow(_ title: String, options: [String], selectedIndex: Int?, placeholder: String = "—", effect: Effect, apply: @escaping (Int) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    var config = UIButton.Configuration.gray()
    config.buttonSize = .small
    if selectedIndex == nil { config.title = placeholder }
    let button = UIButton(configuration: config)
    let actions = options.enumerated().map { index, name in
      UIAction(title: name, state: index == selectedIndex ? .on : .off) { [weak self] _ in
        apply(index)
        self?.fire(effect)
        self?.tableView.reloadData()
      }
    }
    button.menu = UIMenu(options: .singleSelection, children: actions)
    button.showsMenuAsPrimaryAction = true
    button.changesSelectionAsPrimaryAction = true
    button.sizeToFit()
    var frame = button.frame
    frame.size.width = Swift.min(Swift.max(frame.size.width, 100), 190)
    button.frame = frame
    cell.accessoryView = button
    return cell
  }

  private func fieldRow(_ title: String, value: Double, format: String = "%.2f", effect: Effect, apply: @escaping (Double) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    let field = makeNumberField(value: value, format: format, width: 90) { [weak self] value in
      apply(value)
      self?.fire(effect)
    }
    cell.accessoryView = field
    return cell
  }

  private func tripleFieldRow(_ title: String, values: SIMD3<Double>, format: String = "%.2f", effect: Effect, apply: @escaping (Int, Double) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 4
    for index in 0..<3
    {
      let field = makeNumberField(value: values[index], format: format, width: 62) { [weak self] value in
        apply(index, value)
        self?.fire(effect)
      }
      stack.addArrangedSubview(field)
    }
    stack.frame = CGRect(x: 0, y: 0, width: 3 * 62 + 8, height: 30)
    cell.accessoryView = stack
    return cell
  }

  private func makeNumberField(value: Double, format: String, width: CGFloat, apply: @escaping (Double) -> Void) -> UITextField
  {
    let field = UITextField(frame: CGRect(x: 0, y: 0, width: width, height: 30))
    field.borderStyle = .roundedRect
    field.font = UIFont.preferredFont(forTextStyle: .footnote)
    field.textAlignment = .right
    field.keyboardType = .numbersAndPunctuation
    field.returnKeyType = .done
    field.text = String(format: format, value)
    field.addAction(UIAction { action in
      (action.sender as? UITextField)?.resignFirstResponder()
    }, for: .editingDidEndOnExit)
    field.addAction(UIAction { action in
      guard let field = action.sender as? UITextField,
            let text = field.text, let value = Double(text) else { return }
      apply(value)
    }, for: .editingDidEnd)
    return field
  }

  private func rotationRow(_ title: String, minus: @escaping () -> Void, plus: @escaping () -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 8
    let minusButton = UIButton(configuration: .gray())
    minusButton.configuration?.title = "−"
    minusButton.addAction(UIAction { _ in minus() }, for: .touchUpInside)
    let plusButton = UIButton(configuration: .gray())
    plusButton.configuration?.title = "+"
    plusButton.addAction(UIAction { _ in plus() }, for: .touchUpInside)
    stack.addArrangedSubview(minusButton)
    stack.addArrangedSubview(plusButton)
    stack.frame = CGRect(x: 0, y: 0, width: 110, height: 32)
    cell.accessoryView = stack
    return cell
  }
}

extension UIColorWell
{
  func inspectorAccessory() -> UIView
  {
    let size: CGFloat = 32
    let host = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
    host.isUserInteractionEnabled = true
    host.clipsToBounds = true
    frame = host.bounds
    autoresizingMask = [.flexibleWidth, .flexibleHeight]
    contentHorizontalAlignment = .center
    contentVerticalAlignment = .center
    if superview !== host
    {
      removeFromSuperview()
      host.addSubview(self)
    }
    return host
  }
}
