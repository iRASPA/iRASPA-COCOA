import UIKit
import UniformTypeIdentifiers
import ImageIO
import simd
import iRASPAKit
import RenderKit
import MathKit

/// Faithful iPad version of the Cocoa "Camera" detail view (StructureCameraDetailViewController).
/// The static group headers mirror the Cocoa outline-view root nodes: Camera, Selection, Axes,
/// Lights, Pictures/Movies, and Background.
final class CameraInspectorViewController: CollapsibleTableViewController, UIDocumentPickerDelegate
{
  let document: iRASPAUIDocument

  /// Camera moved or reoriented: redraw only.
  var onCameraChange: (() -> Void)?
  var onReset: (() -> Void)?
  var onProjection: ((RKCamera.FrustrumType) -> Void)?
  var onFieldOfView: ((Double) -> Void)?
  var onBloom: ((Double) -> Void)?
  var onLightsChange: (() -> Void)?
  var onAxesChange: (() -> Void)?
  var onBackgroundChange: (() -> Void)?
  var onCreatePicture: (() -> Void)?
  var onCreateMovie: (() -> Void)?
  /// Render view width divided by height, used to derive picture heights (Cocoa's aspectRatioValue).
  var aspectRatio: (() -> Double)?

  private var node: ProjectTreeNode?
  private var project: ProjectStructureNode?
  private var camera: RKCamera?

  private enum Section: Int, CaseIterable
  {
    case orientation
    case rotation
    case viewMatrix
    case virtualPosition
    case selection
    case axes
    case axesBackground
    case axesText
    case lights
    case picture
    case pictureDimensions
    case movie
    case background
  }

  init(document: iRASPAUIDocument)
  {
    self.document = document
    super.init(style: .insetGrouped)
    title = "Camera"
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  func reload(from node: ProjectTreeNode)
  {
    self.node = node
    project = node.representedObject.project as? ProjectStructureNode
    camera = project?.renderCamera
    tableView.reloadData()
  }

  private func markEdited()
  {
    document.updateChangeCount(.done)
    node?.representedObject.isEdited = true
  }

  // MARK: Section layout

  override func inspectorSectionCount() -> Int
  {
    return Section.allCases.count
  }

  override func inspectorGroupHeader(_ section: Int) -> String?
  {
    // Static root-node titles from the Cocoa Camera outline view.
    switch Section(rawValue: section)
    {
    case .orientation: return "Camera"
    case .selection: return "Selection"
    case .axes: return "Axes"
    case .lights: return "Lights"
    case .picture: return "Pictures/Movies"
    case .background: return "Background"
    default: return nil
    }
  }

  override func inspectorSectionTitle(_ section: Int) -> String
  {
    guard project != nil else { return "" }
    switch Section(rawValue: section)
    {
    case .orientation: return "Orientation"
    case .rotation: return "Rotation"
    case .viewMatrix: return "View Matrix"
    case .virtualPosition: return "Virtual Camera Position"
    case .selection: return "Overall Luminance"
    case .axes: return "Position & Style"
    case .axesBackground: return "Background Shape"
    case .axesText: return "Text Properties"
    case .lights: return "Camera Light"
    case .picture: return "Picture"
    case .pictureDimensions: return "Edit Dimensions & Units"
    case .movie: return "Movie"
    case .background: return "Type & Colors"
    case .none: return ""
    }
  }

  override func inspectorRowCount(in section: Int) -> Int
  {
    switch Section(rawValue: section)
    {
    case .orientation: return 6
    case .rotation: return 7
    case .viewMatrix: return 4
    case .virtualPosition: return 4
    case .selection: return 1
    case .axes: return 4
    case .axesBackground: return 3
    case .axesText: return 7
    case .lights: return 7
    case .picture: return 6
    case .pictureDimensions: return 4
    case .movie: return 2
    case .background: return backgroundRowCount()
    case .none: return 0
    }
  }

  private func backgroundRowCount() -> Int
  {
    switch project?.renderBackgroundType ?? .color
    {
    case .color: return 2
    case .linearGradient: return 4
    case .radialGradient: return 4
    case .image: return 3
    }
  }

  override func inspectorCell(for indexPath: IndexPath) -> UITableViewCell
  {
    switch Section(rawValue: indexPath.section)
    {
    case .orientation: return orientationCell(indexPath.row)
    case .rotation: return rotationCell(indexPath.row)
    case .viewMatrix: return viewMatrixCell(indexPath.row)
    case .virtualPosition: return virtualPositionCell(indexPath.row)
    case .selection: return selectionCell(indexPath.row)
    case .axes: return axesCell(indexPath.row)
    case .axesBackground: return axesBackgroundCell(indexPath.row)
    case .axesText: return axesTextCell(indexPath.row)
    case .lights: return lightsCell(indexPath.row)
    case .picture: return pictureCell(indexPath.row)
    case .pictureDimensions: return pictureDimensionsCell(indexPath.row)
    case .movie: return movieCell(indexPath.row)
    case .background: return backgroundCell(indexPath.row)
    case .none: return UITableViewCell()
    }
  }

  // MARK: Camera — Orientation

  private func orientationCell(_ row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      let directions: [(String, RKCamera.ResetDirectionType)] = [
        ("-X", .minus_X), ("+X", .plus_X), ("-Y", .minus_Y),
        ("+Y", .plus_Y), ("-Z", .minus_Z), ("+Z", .plus_Z)
      ]
      let selected = directions.firstIndex(where: { $0.1 == camera?.resetDirectionType })
      return menuRow("Reset Direction", options: directions.map { $0.0 }, selectedIndex: selected) { [weak self] index in
        // Cocoa only stores the direction; the camera moves on "Reset Camera".
        self?.camera?.resetDirectionType = directions[index].1
        self?.markEdited()
        self?.onCameraChange?()
      }
    case 1:
      return fieldRow("Reset to [%]", value: (camera?.resetPercentage ?? 0.85) * 100.0, format: "%.0f", enabled: camera != nil) { [weak self] value in
        self?.camera?.resetPercentage = value / 100.0
        self?.markEdited()
      }
    case 2:
      return buttonRow("Reset Camera", enabled: camera != nil) { [weak self] in
        self?.onReset?()
        self?.markEdited()
        self?.tableView.reloadData()
      }
    case 3:
      let selected: Int? = (camera?.frustrumType).map { $0 == .perspective ? 0 : 1 }
      return menuRow("Projection", options: ["Perspective", "Orthographic"], selectedIndex: selected) { [weak self] index in
        self?.onProjection?(index == 0 ? .perspective : .orthographic)
        self?.markEdited()
      }
    case 4:
      return fieldRow("Angle of View [°]", value: (camera?.angleOfView ?? 60.0 * .pi / 180.0) * 180.0 / .pi, format: "%.2f", enabled: camera != nil) { [weak self] value in
        self?.onFieldOfView?(value)
        self?.markEdited()
      }
    default:
      let center = camera?.centerOfScene ?? SIMD3<Double>()
      return valueRow("Center of Scene", text: String(format: "%.4f  %.4f  %.4f", center.x, center.y, center.z))
    }
  }

  // MARK: Camera — Rotation

  private func rotationCell(_ row: Int) -> UITableViewCell
  {
    let delta = camera?.rotationDelta ?? 15.0
    switch row
    {
    case 0:
      return fieldRow("Rotation Angle [°]", value: delta, format: "%.1f", enabled: camera != nil) { [weak self] value in
        self?.camera?.rotationDelta = value
        self?.markEdited()
        self?.tableView.reloadData()
      }
    case 1:
      return rotationRow(String(format: "Yaw (%.4g°)", delta),
                         minus: { [weak self] in self?.rotateCamera(simd_quatd(yaw: -delta)) },
                         plus: { [weak self] in self?.rotateCamera(simd_quatd(yaw: delta)) })
    case 2:
      return rotationRow(String(format: "Pitch (%.4g°)", delta),
                         minus: { [weak self] in self?.rotateCamera(simd_quatd(pitch: -delta)) },
                         plus: { [weak self] in self?.rotateCamera(simd_quatd(pitch: delta)) })
    case 3:
      return rotationRow(String(format: "Roll (%.4g°)", delta),
                         minus: { [weak self] in self?.rotateCamera(simd_quatd(roll: -delta)) },
                         plus: { [weak self] in self?.rotateCamera(simd_quatd(roll: delta)) })
    case 4:
      return eulerRow("Euler X [°]", component: \.x)
    case 5:
      return eulerRow("Euler Z [°]", component: \.z)
    default:
      return eulerRow("Euler Y [°]", component: \.y)
    }
  }

  private func rotateCamera(_ dq: simd_quatd)
  {
    guard let camera else { return }
    camera.worldRotation = simd_mul(camera.worldRotation, dq)
    markEdited()
    onCameraChange?()
    tableView.reloadData()
  }

  private func eulerRow(_ title: String, component: WritableKeyPath<SIMD3<Double>, Double>) -> UITableViewCell
  {
    let angles = camera?.EulerAngles ?? SIMD3<Double>()
    let degrees = angles[keyPath: component] * 180.0 / .pi
    return sliderRow(title, value: degrees, min: -180, max: 180, format: "%.1f") { [weak self] value in
      guard let self, let camera = self.camera else { return }
      var angles = camera.EulerAngles
      angles[keyPath: component] = value * .pi / 180.0
      camera.worldRotation = simd_quatd(EulerAngles: angles)
      self.markEdited()
      self.onCameraChange?()
      self.tableView.reloadData()
    }
  }

  // MARK: Camera — View matrix / virtual position (read-only)

  private func viewMatrixCell(_ row: Int) -> UITableViewCell
  {
    let matrix = camera?.modelViewMatrix ?? double4x4(1.0)
    let text = String(format: "%9.5f %9.5f %9.5f %9.5f", matrix[0][row], matrix[1][row], matrix[2][row], matrix[3][row])
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = text
    cell.textLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    cell.textLabel?.textAlignment = .center
    cell.textLabel?.textColor = .secondaryLabel
    return cell
  }

  private func virtualPositionCell(_ row: Int) -> UITableViewCell
  {
    let position = camera?.position ?? SIMD3<Double>()
    switch row
    {
    case 0: return valueRow("Position X", text: String(format: "%.5f", position.x))
    case 1: return valueRow("Position Y", text: String(format: "%.5f", position.y))
    case 2: return valueRow("Position Z", text: String(format: "%.5f", position.z))
    default: return valueRow("Distance", text: String(format: "%.5f", length(position)))
    }
  }

  // MARK: Selection

  private func selectionCell(_ row: Int) -> UITableViewCell
  {
    return sliderRow("Overall Luminance", value: camera?.bloomLevel ?? 1.0, min: 0.0, max: 2.0) { [weak self] value in
      self?.onBloom?(value)
      self?.markEdited()
    }
  }

  // MARK: Axes

  private func axesCell(_ row: Int) -> UITableViewCell
  {
    let axes = project?.renderAxes
    switch row
    {
    case 0:
      let options = ["None", "Bottom-left", "Mid-left", "Top-left", "Mid-top",
                     "Top-right", "Mid-right", "Bottom-right", "Mid-bottom", "Center"]
      return menuRow("Position", options: options, selectedIndex: axes?.position.rawValue) { [weak self] index in
        guard let position = RKGlobalAxes.Position(rawValue: index) else { return }
        self?.project?.renderAxes.position = position
        self?.markEdited()
        self?.onAxesChange?()
      }
    case 1:
      let options = ["Default", "Thick RGB", "Thick", "Thin RGB", "Thin",
                     "Beam Arrow RGB", "Beam Arrow", "Beam RGB", "Beam", "Squashed RGB", "Squashed"]
      return menuRow("Style", options: options, selectedIndex: axes?.style.rawValue) { [weak self] index in
        guard let style = RKGlobalAxes.Style(rawValue: index) else { return }
        self?.project?.renderAxes.style = style
        self?.project?.renderAxes.setStyle(style: style)
        self?.markEdited()
        self?.onAxesChange?()
      }
    case 2:
      return fieldRow("Size [%]", value: (axes?.sizeScreenFraction ?? 0.2) * 100.0, format: "%.1f", enabled: axes != nil) { [weak self] value in
        self?.project?.renderAxes.sizeScreenFraction = value / 100.0
        self?.markEdited()
        self?.onAxesChange?()
      }
    default:
      return fieldRow("Border Offset [%]", value: (axes?.borderOffsetScreenFraction ?? 1.0 / 32.0) * 100.0, format: "%.1f", enabled: axes != nil) { [weak self] value in
        self?.project?.renderAxes.borderOffsetScreenFraction = value / 100.0
        self?.markEdited()
        self?.onAxesChange?()
      }
    }
  }

  private func axesBackgroundCell(_ row: Int) -> UITableViewCell
  {
    let axes = project?.renderAxes
    switch row
    {
    case 0:
      let options = ["None", "Filled Circle", "Filled Box", "Filled Rounded Box", "Circle", "Box", "Rounded Box"]
      return menuRow("Background Shape", options: options, selectedIndex: axes?.axesBackgroundStyle.rawValue) { [weak self] index in
        guard let style = RKGlobalAxes.BackgroundStyle(rawValue: index) else { return }
        self?.project?.renderAxes.axesBackgroundStyle = style
        self?.markEdited()
        self?.onAxesChange?()
      }
    case 1:
      return colorRow("Background Color", color: axes?.axesBackgroundColor ?? .black) { [weak self] color in
        self?.project?.renderAxes.axesBackgroundColor = color
        self?.markEdited()
        self?.onAxesChange?()
      }
    default:
      return fieldRow("Background Additional Size", value: axes?.axesBackgroundAdditionalSize ?? 0.0, format: "%.2f", enabled: axes != nil) { [weak self] value in
        self?.project?.renderAxes.axesBackgroundAdditionalSize = value
        self?.markEdited()
        self?.onAxesChange?()
      }
    }
  }

  private func axesTextCell(_ row: Int) -> UITableViewCell
  {
    let axes = project?.renderAxes
    switch row
    {
    case 0:
      return tripleFieldRow("Scaling", values: axes?.textScale ?? SIMD3<Double>(1, 1, 1)) { [weak self] values in
        self?.project?.renderAxes.textScale = values
        self?.markEdited()
        self?.onAxesChange?()
      }
    case 1:
      return tripleFieldRow("X-Text Δ", values: axes?.textDisplacementX ?? SIMD3<Double>()) { [weak self] values in
        self?.project?.renderAxes.textDisplacementX = values
        self?.markEdited()
        self?.onAxesChange?()
      }
    case 2:
      return colorRow("X-Text Color", color: axes?.textColorX ?? .red) { [weak self] color in
        self?.project?.renderAxes.textColorX = color
        self?.markEdited()
        self?.onAxesChange?()
      }
    case 3:
      return tripleFieldRow("Y-Text Δ", values: axes?.textDisplacementY ?? SIMD3<Double>()) { [weak self] values in
        self?.project?.renderAxes.textDisplacementY = values
        self?.markEdited()
        self?.onAxesChange?()
      }
    case 4:
      return colorRow("Y-Text Color", color: axes?.textColorY ?? .green) { [weak self] color in
        self?.project?.renderAxes.textColorY = color
        self?.markEdited()
        self?.onAxesChange?()
      }
    case 5:
      return tripleFieldRow("Z-Text Δ", values: axes?.textDisplacementZ ?? SIMD3<Double>()) { [weak self] values in
        self?.project?.renderAxes.textDisplacementZ = values
        self?.markEdited()
        self?.onAxesChange?()
      }
    default:
      return colorRow("Z-Text Color", color: axes?.textColorZ ?? .blue) { [weak self] color in
        self?.project?.renderAxes.textColorZ = color
        self?.markEdited()
        self?.onAxesChange?()
      }
    }
  }

  // MARK: Lights

  private func lightsCell(_ row: Int) -> UITableViewCell
  {
    switch row
    {
    // ambient describes the environment rather than one lamp, so it belongs to the scene and is not read
    // off a light: see sceneAmbient in Common.h
    case 0:
      return sliderRow("Ambient Light Intensity", value: project?.renderSceneAmbientIntensity ?? 1.0, min: 0.0, max: 1.0) { [weak self] value in
        self?.mutateSceneAmbient { $0.renderSceneAmbientIntensity = value }
      }
    case 1:
      return colorRow("Ambient Color", color: project?.renderSceneAmbientColor ?? .white) { [weak self] color in
        self?.mutateSceneAmbient { $0.renderSceneAmbientColor = color }
      }
    case 2:
      return sliderRow("Diffuse Light Intensity", value: project?.renderLights.first?.diffuseIntensity ?? 1.0, min: 0.0, max: 1.0) { [weak self] value in
        self?.mutateLight { $0.diffuseIntensity = value }
      }
    case 3:
      return colorRow("Diffuse Color", color: project?.renderLights.first?.diffuse ?? .white) { [weak self] color in
        self?.mutateLight { $0.diffuse = color }
      }
    case 4:
      return sliderRow("Specular Light Intensity", value: project?.renderLights.first?.specularIntensity ?? 1.0, min: 0.0, max: 1.0) { [weak self] value in
        self?.mutateLight { $0.specularIntensity = value }
      }
    case 5:
      return colorRow("Specular Color", color: project?.renderLights.first?.specular ?? .white) { [weak self] color in
        self?.mutateLight { $0.specular = color }
      }
    default:
      return sliderRow("Shininess", value: project?.renderLights.first?.shininess ?? 4.0, min: 0.1, max: 128.0, format: "%.1f") { [weak self] value in
        self?.mutateLight { $0.shininess = value }
      }
    }
  }

  private func mutateLight(_ body: (inout RKRenderLight) -> Void)
  {
    guard let project, !project.renderLights.isEmpty else { return }
    body(&project.renderLights[0])
    project.recheckLightStyle()
    markEdited()
    onLightsChange?()
  }

  private func mutateSceneAmbient(_ body: (ProjectStructureNode) -> Void)
  {
    guard let project else { return }
    body(project)
    project.recheckLightStyle()
    markEdited()
    onLightsChange?()
  }

  // MARK: Pictures/Movies

  private func currentAspectRatio() -> Double
  {
    let ratio = aspectRatio?() ?? 1.0
    return ratio > 0.0 ? ratio : 1.0
  }

  private func pictureCell(_ row: Int) -> UITableViewCell
  {
    let ratio = currentAspectRatio()
    let editPhysical = project?.imageDimensions == .physical
    let unitsToInch = (project?.imageUnits == .cm) ? 2.54 : 1.0
    let unitName = (project?.imageUnits == .cm) ? "cm" : "inch"
    switch row
    {
    case 0:
      let options = ["72 dpi", "75 dpi", "150 dpi", "300 dpi", "600 dpi", "1200 dpi"]
      return menuRow("Dots-per-Inch", options: options, selectedIndex: project?.imageDPI.rawValue) { [weak self] index in
        guard let self, let project = self.project,
              let dpi = ProjectStructureNode.DPI(rawValue: index) else { return }
        project.imageDPI = dpi
        // Keep the other dimension in sync, like Cocoa's changeDPI.
        switch project.imageDimensions
        {
        case .physical:
          project.renderImageNumberOfPixels = Int(project.ImageDotsPerInchValue * project.renderImagePhysicalSizeInInches)
        case .pixels:
          project.renderImagePhysicalSizeInInches = Double(project.renderImageNumberOfPixels) / project.ImageDotsPerInchValue
        }
        self.markEdited()
        self.tableView.reloadData()
      }
    case 1:
      let options = ["16-bits, RGB", "8-bits, RGB", "16-bits, CMYK", "8-bits, CMYK"]
      return menuRow("Quality/Type", options: options, selectedIndex: project?.renderImageQuality.rawValue) { [weak self] index in
        guard let quality = RKImageQuality(rawValue: index) else { return }
        self?.project?.renderImageQuality = quality
        self?.markEdited()
      }
    case 2:
      let width = (project?.renderImagePhysicalSizeInInches ?? 6.5) * unitsToInch
      return fieldRow("Physical Width [\(unitName)]", value: width, format: "%.3f", enabled: editPhysical) { [weak self] value in
        guard let self, let project = self.project, value >= 0 else { self?.tableView.reloadData(); return }
        project.renderImagePhysicalSizeInInches = value / unitsToInch
        project.renderImageNumberOfPixels = Int(rint(project.ImageDotsPerInchValue * project.renderImagePhysicalSizeInInches))
        self.markEdited()
        self.tableView.reloadData()
      }
    case 3:
      let height = (project?.renderImagePhysicalSizeInInches ?? 6.5) * unitsToInch / ratio
      return valueRow("Physical Height [\(unitName)]", text: String(format: "%.3f", height))
    case 4:
      return fieldRow("Pixel Width", value: Double(project?.renderImageNumberOfPixels ?? 1600), format: "%.0f", enabled: !editPhysical) { [weak self] value in
        guard let self, let project = self.project, value >= 0 else { self?.tableView.reloadData(); return }
        project.renderImageNumberOfPixels = Int(value)
        project.renderImagePhysicalSizeInInches = Double(project.renderImageNumberOfPixels) / project.ImageDotsPerInchValue
        self.markEdited()
        self.tableView.reloadData()
      }
    default:
      let pixels = rint(Double(project?.renderImageNumberOfPixels ?? 1600) / ratio)
      return valueRow("Pixel Height", text: String(format: "%.0f", pixels))
    }
  }

  private func pictureDimensionsCell(_ row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      let selected: Int? = (project?.imageDimensions).map { $0 == .physical ? 0 : 1 }
      return menuRow("Edit Dimensions", options: ["Physical Dimensions", "Pixel Dimensions"], selectedIndex: selected) { [weak self] index in
        self?.project?.imageDimensions = index == 0 ? .physical : .pixels
        self?.markEdited()
        self?.tableView.reloadData()
      }
    case 1:
      let selected: Int? = (project?.imageUnits).map { $0 == .inch ? 0 : 1 }
      return menuRow("Units", options: ["Inch", "Cm"], selectedIndex: selected) { [weak self] index in
        self?.project?.imageUnits = index == 0 ? .inch : .cm
        self?.markEdited()
        self?.tableView.reloadData()
      }
    case 2:
      return buttonRow("Create Picture", enabled: project != nil) { [weak self] in
        self?.onCreatePicture?()
      }
    default:
      return buttonRow("Create Movie", enabled: project != nil) { [weak self] in
        self?.onCreateMovie?()
      }
    }
  }

  private func movieCell(_ row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return fieldRow("Frames per Second", value: Double(project?.numberOfFramesPerSecond ?? 15), format: "%.0f", enabled: project != nil) { [weak self] value in
        guard let self, value > 0 else { self?.tableView.reloadData(); return }
        self.project?.numberOfFramesPerSecond = Int(value)
        self.markEdited()
      }
    default:
      return menuRow("Movie Type", options: ["Frames", "Rotation Around Y"], selectedIndex: project?.movieType.rawValue) { [weak self] index in
        guard let type = ProjectStructureNode.MovieType(rawValue: index) else { return }
        self?.project?.movieType = type
        self?.markEdited()
      }
    }
  }

  // MARK: Background

  private func backgroundCell(_ row: Int) -> UITableViewCell
  {
    let type = project?.renderBackgroundType ?? .color
    if row == 0
    {
      let options = ["Color", "Linear Gradient", "Radial Gradient", "Image"]
      return menuRow("Type", options: options, selectedIndex: type.rawValue) { [weak self] index in
        guard let backgroundType = RKBackgroundType(rawValue: index) else { return }
        self?.project?.renderBackgroundType = backgroundType
        self?.markEdited()
        self?.onBackgroundChange?()
        self?.tableView.reloadData()
      }
    }
    switch type
    {
    case .color:
      return colorRow("Color", color: project?.renderBackgroundColor ?? .white) { [weak self] color in
        self?.project?.renderBackgroundColor = color
        self?.markEdited()
        self?.onBackgroundChange?()
      }
    case .linearGradient:
      switch row
      {
      case 1:
        return colorRow("From", color: project?.backgroundLinearGradientFromColor ?? .white) { [weak self] color in
          self?.project?.backgroundLinearGradientFromColor = color
          self?.markEdited()
          self?.onBackgroundChange?()
        }
      case 2:
        return colorRow("To", color: project?.backgroundLinearGradientToColor ?? .black) { [weak self] color in
          self?.project?.backgroundLinearGradientToColor = color
          self?.markEdited()
          self?.onBackgroundChange?()
        }
      default:
        return sliderRow("Angle [°]", value: project?.backgroundLinearGradientAngle ?? 45.0, min: 0.0, max: 360.0, format: "%.0f") { [weak self] value in
          self?.project?.backgroundLinearGradientAngle = max(value, 0.0001)
          self?.markEdited()
          self?.onBackgroundChange?()
        }
      }
    case .radialGradient:
      switch row
      {
      case 1:
        return colorRow("From", color: project?.backgroundRadialGradientFromColor ?? .white) { [weak self] color in
          self?.project?.backgroundRadialGradientFromColor = color
          self?.markEdited()
          self?.onBackgroundChange?()
        }
      case 2:
        return colorRow("To", color: project?.backgroundRadialGradientToColor ?? .black) { [weak self] color in
          self?.project?.backgroundRadialGradientToColor = color
          self?.markEdited()
          self?.onBackgroundChange?()
        }
      default:
        return sliderRow("Roundness", value: project?.backgroundRadialGradientRoundness ?? 0.4, min: 0.0, max: 4.0, format: "%.2f") { [weak self] value in
          self?.project?.backgroundRadialGradientRoundness = max(value, 0.0001)
          self?.markEdited()
          self?.onBackgroundChange?()
        }
      }
    case .image:
      if row == 1
      {
        return buttonRow("Choose Picture…", enabled: project != nil) { [weak self] in
          self?.presentBackgroundImagePicker()
        }
      }
      return buttonRow("Clear Picture", enabled: project?.renderBackgroundImage != nil) { [weak self] in
        self?.project?.renderBackgroundImage = nil
        self?.project?.renderBackgroundType = .color
        self?.markEdited()
        self?.onBackgroundChange?()
        self?.tableView.reloadData()
      }
    }
  }

  private func presentBackgroundImagePicker()
  {
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.image])
    picker.allowsMultipleSelection = false
    picker.delegate = self
    present(picker, animated: true)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL])
  {
    guard let url = urls.first, let project else { return }
    let accessing = url.startAccessingSecurityScopedResource()
    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else { return }
    project.renderBackgroundImage = image
    project.renderBackgroundType = .image
    markEdited()
    onBackgroundChange?()
    tableView.reloadData()
  }

  // MARK: Row factories

  private func valueRow(_ title: String, text: String) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    cell.detailTextLabel?.text = text
    cell.detailTextLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    return cell
  }

  private func buttonRow(_ title: String, enabled: Bool, action: @escaping () -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none
    let button = UIButton(configuration: .gray())
    button.configuration?.title = title
    button.isEnabled = enabled
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    button.sizeToFit()
    cell.textLabel?.text = ""
    cell.accessoryView = button
    return cell
  }

  private func colorRow(_ title: String, color: UIColor, apply: @escaping (UIColor) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    let well = UIColorWell(frame: CGRect(x: 0, y: 0, width: 34, height: 34))
    well.supportsAlpha = false
    well.selectedColor = color
    well.addAction(UIAction { action in
      guard let well = action.sender as? UIColorWell, let color = well.selectedColor else { return }
      apply(color)
    }, for: .valueChanged)
    cell.accessoryView = well
    return cell
  }

  private func switchRow(_ title: String, isOn: Bool, apply: @escaping (Bool) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    let control = UISwitch()
    control.isOn = isOn
    control.addAction(UIAction { action in
      guard let control = action.sender as? UISwitch else { return }
      apply(control.isOn)
    }, for: .valueChanged)
    cell.accessoryView = control
    return cell
  }

  private func sliderRow(_ title: String, value: Double, min: Double, max: Double, format: String = "%.2f", apply: @escaping (Double) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    cell.detailTextLabel?.text = String(format: format, value)
    let slider = UISlider(frame: CGRect(x: 0, y: 0, width: 150, height: 30))
    slider.minimumValue = Float(min)
    slider.maximumValue = Float(max)
    slider.value = Float(value)
    slider.addAction(UIAction { [weak cell] action in
      guard let slider = action.sender as? UISlider else { return }
      cell?.detailTextLabel?.text = String(format: format, Double(slider.value))
    }, for: .valueChanged)
    for event in [UIControl.Event.touchUpInside, .touchUpOutside]
    {
      slider.addAction(UIAction { action in
        guard let slider = action.sender as? UISlider else { return }
        apply(Double(slider.value))
      }, for: event)
    }
    cell.accessoryView = slider
    return cell
  }

  private func menuRow(_ title: String, options: [String], selectedIndex: Int?, placeholder: String = "—", apply: @escaping (Int) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    var config = UIButton.Configuration.gray()
    config.buttonSize = .small
    if let selectedIndex, options.indices.contains(selectedIndex)
    {
      config.title = options[selectedIndex]
    }
    else
    {
      config.title = placeholder
    }
    let button = UIButton(configuration: config)
    let actions = options.indices.map { index in
      UIAction(title: options[index], state: index == selectedIndex ? .on : .off) { [weak self] _ in
        apply(index)
        self?.tableView.reloadData()
      }
    }
    button.menu = UIMenu(children: actions)
    button.showsMenuAsPrimaryAction = true
    button.sizeToFit()
    cell.accessoryView = button
    return cell
  }

  private func fieldRow(_ title: String, value: Double, format: String = "%.2f", enabled: Bool = true, apply: @escaping (Double) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    let field = makeNumberField(value: value, format: format, width: 100, apply: apply)
    field.isEnabled = enabled
    cell.textLabel?.textColor = enabled ? .label : .secondaryLabel
    cell.accessoryView = field
    return cell
  }

  private func tripleFieldRow(_ title: String, values: SIMD3<Double>, format: String = "%.2f", apply: @escaping (SIMD3<Double>) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    var current = values
    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 4
    for index in 0..<3
    {
      let field = makeNumberField(value: values[index], format: format, width: 62) { value in
        current[index] = value
        apply(current)
      }
      stack.addArrangedSubview(field)
    }
    stack.frame = CGRect(x: 0, y: 0, width: 194, height: 30)
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
