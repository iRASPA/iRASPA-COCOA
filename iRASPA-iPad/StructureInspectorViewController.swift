import UIKit
import iRASPAKit
import RenderKit
import SymmetryKit
import SimulationKit
import LogViewKit
import simd

/// Faithful iPad version of the Cocoa "Cell" detail view (StructureCellDetailViewController).
/// Groups mirror the Cocoa outline view: Box (material, bounding box, unit cell, volume,
/// replicas, orientation, origin), Transform Content, Structural, and Symmetry.
final class StructureInspectorViewController: CollapsibleTableViewController
{
  let document: iRASPAUIDocument
  var onChange: (() -> Void)?
  var onGeometryChange: (() -> Void)?
  var onSurfaceChange: (() -> Void)?
  var onPlayToggle: (() -> Void)?
  var onSetFrame: ((Int) -> Void)?
  var isPlaying: (() -> Bool)?

  private var node: ProjectTreeNode?
  private var project: ProjectStructureNode?
  private var structure: Structure?
  private var selectedObjects: [iRASPAObject] = []
  private var movies: [Movie] = []
  private var isComputing = false

  private let probes: [(String, Structure.ProbeMolecule)] = [
    ("Helium", .helium), ("Methane", .methane), ("Nitrogen", .nitrogen),
    ("Hydrogen", .hydrogen), ("Water", .water), ("CO₂", .co2),
    ("Xenon", .xenon), ("Krypton", .krypton), ("Argon", .argon)
  ]

  private let materialKinds: [(String, SKStructure.Kind)] = [
    ("Crystal", .crystal),
    ("Molecular crystal", .molecularCrystal),
    ("Molecule", .molecule),
    ("Protein", .protein),
    ("Protein crystal", .proteinCrystal),
    ("Crystal ellipsoid", .crystalEllipsoidPrimitive),
    ("Crystal cylinder", .crystalCylinderPrimitive),
    ("Crystal polygonal prism", .crystalPolygonalPrismPrimitive),
    ("Ellipsoid", .ellipsoidPrimitive),
    ("Cylinder", .cylinderPrimitive),
    ("Polygonal prism", .polygonalPrismPrimitive)
  ]

  private let materialNames: [String] = [
    "Unspecified", "Silica", "Aluminosilicate", "Metallophosphate",
    "Silicoaluminophosphate", "Zeolite", "MOF", "ZIF"
  ]

  private enum Section
  {
    case material
    case boundingBox
    case unitCell
    case cellVectors
    case volume
    case replicas
    case orientation
    case origin
    case transformContent
    case structural
    case probe
    case channels
    case spaceGroup
    case centering
    case symmetryProperties
    case actions
    case movies
  }

  private var sections: [Section]
  {
    var list: [Section] = [.material, .boundingBox, .unitCell, .cellVectors, .volume,
                           .replicas, .orientation, .origin, .transformContent,
                           .structural, .probe, .channels,
                           .spaceGroup, .centering, .symmetryProperties, .actions]
    if showsMovies
    {
      list.append(.movies)
    }
    return list
  }

  init(document: iRASPAUIDocument)
  {
    self.document = document
    super.init(style: .insetGrouped)
    title = "Cell"
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
    project?.setInitialSelectionIfNeeded()
    movies = project?.sceneList.scenes.flatMap { $0.movies } ?? []
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
    structure?.recomputeDensityProperties()
    tableView.reloadData()
  }

  private var showsMovies: Bool
  {
    return movies.count > 1 || movies.contains(where: { $0.frames.count > 1 })
  }

  private func allStructures() -> [Structure]
  {
    let selected = selectedObjects.compactMap({ $0.object as? Structure })
    if !selected.isEmpty { return selected }
    if let structure { return [structure] }
    return []
  }

  private func allObjects() -> [Object]
  {
    let selected = selectedObjects.map({ $0.object })
    if !selected.isEmpty { return selected }
    if let structure { return [structure] }
    return []
  }

  // MARK: Table structure

  override func inspectorSectionCount() -> Int
  {
    return sections.count
  }

  override func inspectorGroupHeader(_ section: Int) -> String?
  {
    // Static root-node titles from the Cocoa Cell outline view.
    switch sections[section]
    {
    case .material: return "Cell/Bounding-Box Properties"
    case .transformContent: return "Transform Content"
    case .structural: return "Structural Properties"
    case .spaceGroup: return "Symmetry Properties"
    default: return nil
    }
  }

  override func inspectorSectionTitle(_ section: Int) -> String
  {
    switch sections[section]
    {
    case .material: return "Material"
    case .boundingBox: return "Bounding Box"
    case .unitCell: return "Unit Cell Properties"
    case .cellVectors: return "Unit Cell Vectors"
    case .volume: return "Volume"
    case .replicas: return "Replicas"
    case .orientation: return "Orientation"
    case .origin: return "Origin"
    case .transformContent: return "Flip & Shift"
    case .structural: return "Properties"
    case .probe: return "Probe"
    case .channels: return "Channels"
    case .spaceGroup: return "Space Group"
    case .centering: return "Centering"
    case .symmetryProperties: return "Properties"
    case .actions: return "Actions"
    case .movies: return "Movies"
    }
  }

  override func inspectorFooterTitle(_ section: Int) -> String?
  {
    if sections[section] == .material
    {
      if selectedObjects.isEmpty { return "Select a project, movie, or frame to edit." }
      if selectedObjects.count == 1 { return "Editing \(selectedObjects[0].object.displayName)" }
      return "Editing \(selectedObjects.count) selected structures"
    }
    return nil
  }

  override func inspectorRowCount(in section: Int) -> Int
  {
    switch sections[section]
    {
    case .material: return 1
    case .boundingBox: return 2
    case .unitCell: return 6
    case .cellVectors: return 3
    case .volume: return 4
    case .replicas: return 6
    case .orientation: return 7
    case .origin: return 3
    case .transformContent: return 7
    case .structural: return 7
    case .probe: return 6
    case .channels: return 4
    case .spaceGroup: return 5
    case .centering: return 5
    case .symmetryProperties: return 9
    case .actions: return 11
    case .movies:
      let extra = maxFrameCount() > 1 ? 3 : 0
      return extra + movies.count
    }
  }

  override func inspectorCell(for indexPath: IndexPath) -> UITableViewCell
  {
    switch sections[indexPath.section]
    {
    case .material: return materialCell(row: indexPath.row)
    case .boundingBox: return boundingBoxCell(row: indexPath.row)
    case .unitCell: return unitCellCell(row: indexPath.row)
    case .cellVectors: return cellVectorsCell(row: indexPath.row)
    case .volume: return volumeCell(row: indexPath.row)
    case .replicas: return replicasCell(row: indexPath.row)
    case .orientation: return orientationCell(row: indexPath.row)
    case .origin: return originCell(row: indexPath.row)
    case .transformContent: return transformContentCell(row: indexPath.row)
    case .structural: return structuralCell(row: indexPath.row)
    case .probe: return probeCell(row: indexPath.row)
    case .channels: return channelsCell(row: indexPath.row)
    case .spaceGroup: return spaceGroupCell(row: indexPath.row)
    case .centering: return centeringCell(row: indexPath.row)
    case .symmetryProperties: return symmetryPropertiesCell(row: indexPath.row)
    case .actions: return actionsCell(row: indexPath.row)
    case .movies: return moviesCell(row: indexPath.row)
    }
  }

  override func inspectorDidSelect(at indexPath: IndexPath)
  {
    tableView.deselectRow(at: indexPath, animated: true)
    switch sections[indexPath.section]
    {
    case .transformContent:
      if indexPath.row == 6 { applyContentShift() }
    case .structural:
      if indexPath.row == 6 { computeHeliumVoidFraction() }
    case .probe:
      if indexPath.row == 3 { computeNitrogenSurfaceArea() }
    case .actions:
      switch indexPath.row
      {
      case 0: recomputeBonds()
      case 1: expandToP1()
      case 2: makeSuperCell()
      case 3: wrapAtomsToCell()
      case 4: findAndImposeSymmetry()
      case 5: findNiggli()
      case 6: findPrimitive()
      case 7: removeSymmetry()
      case 8: presentAddAtomPicker()
      case 9: deleteSelectedAtoms()
      default: presentPrimitivePicker()
      }
    case .movies:
      didSelectMoviesRow(indexPath.row)
    default:
      break
    }
  }

  // MARK: Material

  private func materialCell(row: Int) -> UITableViewCell
  {
    let currentKind = selectedFrame()?.type
    let selectedIndex = materialKinds.firstIndex(where: { $0.1 == currentKind })
    return menuRow("Material type", options: materialKinds.map { $0.0 }, selectedIndex: selectedIndex) { [weak self] index in
      guard let self else { return }
      self.convertType(self.materialKinds[index].1)
    }
  }

  // MARK: Bounding box

  private func boundingBoxCell(row: Int) -> UITableViewCell
  {
    let box = structure?.cell.boundingBox
    if row == 0
    {
      return tripleInfoRow("Minimum (Å)", values: box?.minimum)
    }
    return tripleInfoRow("Maximum (Å)", values: box?.maximum)
  }

  // MARK: Unit cell

  private func unitCellCell(row: Int) -> UITableViewCell
  {
    let cellParams = structure?.cell
    let toDegrees = 180.0 / Double.pi
    switch row
    {
    case 0:
      return fieldRow("Length a (Å)", value: cellParams?.a ?? 0, format: "%.5f") { [weak self] value in
        self?.setCellParameter(index: 0, value: value)
      }
    case 1:
      return fieldRow("Length b (Å)", value: cellParams?.b ?? 0, format: "%.5f") { [weak self] value in
        self?.setCellParameter(index: 1, value: value)
      }
    case 2:
      return fieldRow("Length c (Å)", value: cellParams?.c ?? 0, format: "%.5f") { [weak self] value in
        self?.setCellParameter(index: 2, value: value)
      }
    case 3:
      return fieldRow("Angle α (°)", value: (cellParams?.alpha ?? 0) * toDegrees, format: "%.3f") { [weak self] value in
        self?.setCellParameter(index: 3, value: value)
      }
    case 4:
      return fieldRow("Angle β (°)", value: (cellParams?.beta ?? 0) * toDegrees, format: "%.3f") { [weak self] value in
        self?.setCellParameter(index: 4, value: value)
      }
    default:
      return fieldRow("Angle γ (°)", value: (cellParams?.gamma ?? 0) * toDegrees, format: "%.3f") { [weak self] value in
        self?.setCellParameter(index: 5, value: value)
      }
    }
  }

  private func setCellParameter(index: Int, value: Double)
  {
    guard value.isFinite else { return }
    if index < 3, value <= 0 { return }
    for structure in allStructures()
    {
      var cell = structure.cell
      switch index
      {
      case 0: cell.a = value
      case 1: cell.b = value
      case 2: cell.c = value
      case 3: cell.alpha = value * .pi / 180.0
      case 4: cell.beta = value * .pi / 180.0
      default: cell.gamma = value * .pi / 180.0
      }
      structure.cell = cell
      structure.reComputeBoundingBox()
      structure.recomputeDensityProperties()
    }
    document.updateChangeCount(.done)
    tableView.reloadData()
    onGeometryChange?()
  }

  // MARK: Unit cell vectors

  private func cellVectorsCell(row: Int) -> UITableViewCell
  {
    let unitCell = structure?.cell.unitCell
    switch row
    {
    case 0: return tripleInfoRow("a (Å)", values: unitCell?[0])
    case 1: return tripleInfoRow("b (Å)", values: unitCell?[1])
    default: return tripleInfoRow("c (Å)", values: unitCell?[2])
    }
  }

  // MARK: Volume

  private func volumeCell(row: Int) -> UITableViewCell
  {
    let cellParams = structure?.cell
    switch row
    {
    case 0:
      return infoRow("Volume (Å³)", value: cellParams.map { String(format: "%.5f", $0.volume) })
    case 1:
      return infoRow("Perpendicular width x (Å)", value: cellParams.map { String(format: "%.5f", $0.perpendicularWidths.x) })
    case 2:
      return infoRow("Perpendicular width y (Å)", value: cellParams.map { String(format: "%.5f", $0.perpendicularWidths.y) })
    default:
      return infoRow("Perpendicular width z (Å)", value: cellParams.map { String(format: "%.5f", $0.perpendicularWidths.z) })
    }
  }

  // MARK: Replicas

  private func replicasCell(row: Int) -> UITableViewCell
  {
    let cellParams = structure?.cell
    let titles = ["Minimum x", "Maximum x", "Minimum y", "Maximum y", "Minimum z", "Maximum z"]
    let values: [Int] = [cellParams?.minimumReplicaX ?? 0, cellParams?.maximumReplicaX ?? 0,
                         cellParams?.minimumReplicaY ?? 0, cellParams?.maximumReplicaY ?? 0,
                         cellParams?.minimumReplicaZ ?? 0, cellParams?.maximumReplicaZ ?? 0]
    let isMaximum = row % 2 == 1
    return stepperRow(titles[row], value: values[row],
                      minimum: isMaximum ? 0 : -50,
                      maximum: isMaximum ? 50 : 0) { [weak self] value in
      self?.setReplica(row: row, value: value)
    }
  }

  private func setReplica(row: Int, value: Int)
  {
    for structure in allStructures()
    {
      switch row
      {
      case 0: structure.cell.minimumReplicaX = min(value, structure.cell.maximumReplicaX)
      case 1: structure.cell.maximumReplicaX = max(value, structure.cell.minimumReplicaX)
      case 2: structure.cell.minimumReplicaY = min(value, structure.cell.maximumReplicaY)
      case 3: structure.cell.maximumReplicaY = max(value, structure.cell.minimumReplicaY)
      case 4: structure.cell.minimumReplicaZ = min(value, structure.cell.maximumReplicaZ)
      default: structure.cell.maximumReplicaZ = max(value, structure.cell.minimumReplicaZ)
      }
      structure.reComputeBoundingBox()
    }
    document.updateChangeCount(.done)
    tableView.reloadData()
    onGeometryChange?()
  }

  // MARK: Orientation

  private func orientationCell(row: Int) -> UITableViewCell
  {
    let object = allObjects().first
    let euler = object?.orientation.EulerAngles ?? SIMD3<Double>(0, 0, 0)
    let toDegrees = 180.0 / Double.pi
    let delta = object?.rotationDelta ?? 5.0
    switch row
    {
    case 0:
      return rotationRow("Rotate yaw ±\(String(format: "%.1f", delta))°",
                         minus: { [weak self] in self?.rotateObjects(makeDelta: { simd_quatd(yaw: -$0) }) },
                         plus: { [weak self] in self?.rotateObjects(makeDelta: { simd_quatd(yaw: $0) }) })
    case 1:
      return rotationRow("Rotate pitch ±\(String(format: "%.1f", delta))°",
                         minus: { [weak self] in self?.rotateObjects(makeDelta: { simd_quatd(pitch: -$0) }) },
                         plus: { [weak self] in self?.rotateObjects(makeDelta: { simd_quatd(pitch: $0) }) })
    case 2:
      return rotationRow("Rotate roll ±\(String(format: "%.1f", delta))°",
                         minus: { [weak self] in self?.rotateObjects(makeDelta: { simd_quatd(roll: -$0) }) },
                         plus: { [weak self] in self?.rotateObjects(makeDelta: { simd_quatd(roll: $0) }) })
    case 3:
      return fieldRow("Rotation delta (°)", value: delta, format: "%.2f") { [weak self] value in
        guard let self else { return }
        self.allObjects().forEach { $0.rotationDelta = value }
        self.document.updateChangeCount(.done)
        self.tableView.reloadData()
      }
    case 4:
      return sliderRow("Euler x (°)", value: euler.x * toDegrees, min: -180, max: 180, format: "%.1f") { [weak self] value in
        self?.setEulerAngle(component: 0, degrees: value)
      }
    case 5:
      return sliderRow("Euler y (°)", value: euler.y * toDegrees, min: -90, max: 90, format: "%.1f") { [weak self] value in
        self?.setEulerAngle(component: 1, degrees: value)
      }
    default:
      return sliderRow("Euler z (°)", value: euler.z * toDegrees, min: -180, max: 180, format: "%.1f") { [weak self] value in
        self?.setEulerAngle(component: 2, degrees: value)
      }
    }
  }

  private func rotateObjects(makeDelta: (Double) -> simd_quatd)
  {
    for object in allObjects()
    {
      let dq = makeDelta(object.rotationDelta)
      object.orientation = object.orientation * dq
      object.reComputeBoundingBox()
    }
    if let project { project.renderCamera?.boundingBox = project.renderBoundingBox }
    document.updateChangeCount(.done)
    tableView.reloadData()
    onGeometryChange?()
  }

  private func setEulerAngle(component: Int, degrees: Double)
  {
    let radians = degrees * Double.pi / 180.0
    for object in allObjects()
    {
      var angles = object.orientation.EulerAngles
      angles[component] = radians
      object.orientation = simd_quatd(EulerAngles: angles)
      object.reComputeBoundingBox()
    }
    if let project { project.renderCamera?.boundingBox = project.renderBoundingBox }
    document.updateChangeCount(.done)
    onGeometryChange?()
  }

  // MARK: Origin

  private func originCell(row: Int) -> UITableViewCell
  {
    let origin = allObjects().first?.origin ?? SIMD3<Double>(0, 0, 0)
    let titles = ["Origin x (Å)", "Origin y (Å)", "Origin z (Å)"]
    return fieldRow(titles[row], value: origin[row], format: "%.4f") { [weak self] value in
      guard let self else { return }
      self.allObjects().forEach { $0.origin[row] = value }
      self.document.updateChangeCount(.done)
      self.onGeometryChange?()
    }
  }

  // MARK: Transform content

  private func transformContentCell(row: Int) -> UITableViewCell
  {
    let cellParams = structure?.cell
    switch row
    {
    case 0:
      return switchRow("Flip x", isOn: cellParams?.contentFlip.x ?? false) { [weak self] isOn in
        self?.allStructures().forEach { $0.cell.contentFlip.x = isOn }
        self?.fireContentTransformChange()
      }
    case 1:
      return switchRow("Flip y", isOn: cellParams?.contentFlip.y ?? false) { [weak self] isOn in
        self?.allStructures().forEach { $0.cell.contentFlip.y = isOn }
        self?.fireContentTransformChange()
      }
    case 2:
      return switchRow("Flip z", isOn: cellParams?.contentFlip.z ?? false) { [weak self] isOn in
        self?.allStructures().forEach { $0.cell.contentFlip.z = isOn }
        self?.fireContentTransformChange()
      }
    case 3:
      return fieldRow("Shift x", value: cellParams?.contentShift.x ?? 0, format: "%.4f") { [weak self] value in
        self?.allStructures().forEach { $0.cell.contentShift.x = value }
        self?.fireContentTransformChange()
      }
    case 4:
      return fieldRow("Shift y", value: cellParams?.contentShift.y ?? 0, format: "%.4f") { [weak self] value in
        self?.allStructures().forEach { $0.cell.contentShift.y = value }
        self?.fireContentTransformChange()
      }
    case 5:
      return fieldRow("Shift z", value: cellParams?.contentShift.z ?? 0, format: "%.4f") { [weak self] value in
        self?.allStructures().forEach { $0.cell.contentShift.z = value }
        self?.fireContentTransformChange()
      }
    default:
      return actionRow("Apply content shift")
    }
  }

  private func fireContentTransformChange()
  {
    if let project { project.renderCamera?.boundingBox = project.renderBoundingBox }
    document.updateChangeCount(.done)
    onChange?()
  }

  private func applyContentShift()
  {
    guard let structure else { return }
    guard let state = structure.applyCellContentShift() else {
      LogQueue.shared.warning(destination: nil, message: "Could not apply the content shift")
      return
    }
    if spaceGroupEditor() != nil
    {
      applySpaceGroupState(state, message: "Applied content shift")
      return
    }
    structure.cell = state.cell
    structure.atomTreeController = state.atoms
    structure.bondSetController = state.bonds
    structure.setRepresentationColorScheme(scheme: structure.atomColorSchemeIdentifier, colorSets: document.colorSets)
    structure.setRepresentationForceField(forceField: structure.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)
    structure.reComputeBoundingBox()
    document.updateChangeCount(.done)
    tableView.reloadData()
    onGeometryChange?()
    LogQueue.shared.info(destination: nil, message: "Applied content shift")
  }

  // MARK: Structural properties

  private func structuralCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      var options = materialNames
      let current = structure?.structureMaterialType ?? "Unspecified"
      if !options.contains(current) { options.insert(current, at: 0) }
      let selectedIndex = options.firstIndex(of: current)
      return menuRow("Material", options: options, selectedIndex: selectedIndex) { [weak self] index in
        guard let self else { return }
        self.allStructures().forEach { $0.structureMaterialType = options[index] }
        self.document.updateChangeCount(.done)
      }
    case 1:
      return infoRow("Mass (g/mol per uc)", value: structure.map { String(format: "%.4f", $0.structureMass) })
    case 2:
      return infoRow("Density (kg/m³)", value: structure.map { String(format: "%.4f", $0.structureDensity) })
    case 3:
      return infoRow("Helium void fraction", value: structure.map { String(format: "%.5f", $0.structureHeliumVoidFraction) })
    case 4:
      return infoRow("Specific volume (cm³/g)", value: structure.map { String(format: "%.5f", $0.structureSpecificVolume) })
    case 5:
      return infoRow("Accessible pore volume (cm³/g)", value: structure.map { String(format: "%.5f", $0.structureAccessiblePoreVolume) })
    default:
      return actionRow(isComputing ? "Computing helium void fraction…" : "Compute helium void fraction")
    }
  }

  // MARK: Structural probe

  private func probeCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      let current = structure?.frameworkProbeMolecule ?? .nitrogen
      let selectedIndex = probes.firstIndex(where: { $0.1 == current })
      return menuRow("Probe molecule", options: probes.map { $0.0 }, selectedIndex: selectedIndex) { [weak self] index in
        guard let self else { return }
        self.allStructures().forEach { $0.frameworkProbeMolecule = self.probes[index].1 }
        self.document.updateChangeCount(.done)
      }
    case 1:
      return infoRow("Surface area (m²/cm³)", value: structure.map { String(format: "%.3f", $0.structureVolumetricNitrogenSurfaceArea) })
    case 2:
      return infoRow("Surface area (m²/g)", value: structure.map { String(format: "%.3f", $0.structureGravimetricNitrogenSurfaceArea) })
    case 3:
      return actionRow(isComputing ? "Computing surface area…" : "Compute surface area")
    case 4:
      return intFieldRow("Number of channel systems", value: structure?.structureNumberOfChannelSystems ?? 0) { [weak self] value in
        self?.allStructures().forEach { $0.structureNumberOfChannelSystems = value }
        self?.document.updateChangeCount(.done)
      }
    default:
      return intFieldRow("Inaccessible pockets", value: structure?.structureNumberOfInaccessiblePockets ?? 0) { [weak self] value in
        self?.allStructures().forEach { $0.structureNumberOfInaccessiblePockets = value }
        self?.document.updateChangeCount(.done)
      }
    }
  }

  // MARK: Channels

  private func channelsCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0:
      return intFieldRow("Dimensionality of pore system", value: structure?.structureDimensionalityOfPoreSystem ?? 0) { [weak self] value in
        self?.allStructures().forEach { $0.structureDimensionalityOfPoreSystem = value }
        self?.document.updateChangeCount(.done)
      }
    case 1:
      return fieldRow("Largest cavity diameter (Å)", value: structure?.structureLargestCavityDiameter ?? 0, format: "%.4f") { [weak self] value in
        self?.allStructures().forEach { $0.structureLargestCavityDiameter = value }
        self?.document.updateChangeCount(.done)
      }
    case 2:
      return fieldRow("Pore limiting diameter (Å)", value: structure?.structureRestrictingPoreLimitingDiameter ?? 0, format: "%.4f") { [weak self] value in
        self?.allStructures().forEach { $0.structureRestrictingPoreLimitingDiameter = value }
        self?.document.updateChangeCount(.done)
      }
    default:
      return fieldRow("Cavity diameter, viable path (Å)", value: structure?.structureLargestCavityDiameterAlongAViablePath ?? 0, format: "%.4f") { [weak self] value in
        self?.allStructures().forEach { $0.structureLargestCavityDiameterAlongAViablePath = value }
        self?.document.updateChangeCount(.done)
      }
    }
  }

  // MARK: Space group

  private func spaceGroupCell(row: Int) -> UITableViewCell
  {
    let hall = structure?.spaceGroupHallNumber
    switch row
    {
    case 0:
      let numbers = SKSpacegroup.numbers
      let selectedIndex = hall.map { SKSpacegroup.SpaceGroupNumberForHallNumber($0) }
      return menuRow("Space group (IT number)", options: numbers, selectedIndex: selectedIndex, placeholder: "—") { [weak self] index in
        self?.setSpaceGroupHall(SKSpacegroup.HallSymbolForConventionalSpaceGroupNumber(index))
      }
    case 1:
      let number = hall.map { SKSpacegroup.SpaceGroupNumberForHallNumber($0) } ?? 1
      let qualifiers = SKSpacegroup.spacegroupQualifiers(number: number)
      let selectedIndex = hall.map { SKSpacegroup.SpaceGroupQualifierForHallNumber($0) }
      return menuRow("Qualifier", options: qualifiers, selectedIndex: selectedIndex, placeholder: "—") { [weak self] index in
        self?.setSpaceGroupHall(SKSpacegroup.BaseHallSymbolForSpaceGroupNumber(number) + index)
      }
    case 2:
      return menuRow("Hall symbol", options: SKSpacegroup.HallSymbols, selectedIndex: hall, placeholder: "—") { [weak self] index in
        self?.setSpaceGroupHall(index)
      }
    case 3:
      return infoRow("Holohedry", value: hall.map { SKSpacegroup.HolohedryString(HallNumber: $0) })
    default:
      return fieldRow("Precision (Å)", value: structure?.cell.precision ?? 1e-2, format: "%.5f") { [weak self] value in
        self?.allStructures().forEach { $0.cell.precision = value }
        self?.document.updateChangeCount(.done)
      }
    }
  }

  private func setSpaceGroupHall(_ hall: Int)
  {
    guard hall > 0 else { return }
    let editors = allStructures().compactMap({ $0 as? Structure & SpaceGroupEditor })
    guard !editors.isEmpty else {
      LogQueue.shared.warning(destination: nil, message: "Space group can only be set on a crystal")
      return
    }
    for crystal in editors
    {
      guard let state = crystal.setSpaceGroup(number: hall) else {
        LogQueue.shared.warning(destination: nil, message: "Could not set space group \(hall)")
        continue
      }
      crystal.cell = state.cell
      crystal.spaceGroup = state.spaceGroup
      crystal.atomTreeController = state.atoms
      crystal.bondSetController = state.bonds
      crystal.setRepresentationColorScheme(scheme: crystal.atomColorSchemeIdentifier, colorSets: document.colorSets)
      crystal.setRepresentationForceField(forceField: crystal.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)
      crystal.reComputeBoundingBox()
    }
    project?.measurementTreeNodes = []
    document.updateChangeCount(.done)
    tableView.reloadData()
    onGeometryChange?()
    let setting = SKSpacegroup(HallNumber: hall).spaceGroupSetting
    LogQueue.shared.info(destination: nil, message: "Set space group \(setting.HM) (#\(setting.spaceGroupNumber))")
  }

  // MARK: Centering

  private func centeringCell(row: Int) -> UITableViewCell
  {
    let hall = structure?.spaceGroupHallNumber
    if row == 0
    {
      return infoRow("Centering", value: hall.map { SKSpacegroup.CentringString(HallNumber: $0) })
    }
    let translations = hall.map { SKSpacegroup.LatticeTranslationStrings(HallNumber: $0) }
    let value = translations.map { $0[row - 1] }
    return infoRow("Lattice vector \(row)", value: (value?.isEmpty ?? true) ? "—" : value)
  }

  // MARK: Symmetry properties

  private func symmetryPropertiesCell(row: Int) -> UITableViewCell
  {
    guard let hall = structure?.spaceGroupHallNumber else
    {
      return infoRow(symmetryPropertyTitle(row), value: nil)
    }
    let value: String
    switch row
    {
    case 0: value = SKSpacegroup.hasInversionString(HallNumber: hall)
    case 1: value = SKSpacegroup.hasInversion(HallNumber: hall) ? SKSpacegroup.InversionCenterString(HallNumber: hall) : "—"
    case 2: value = SKSpacegroup.CentrosymmetricString(HallNumber: hall)
    case 3: value = SKSpacegroup.EnantionmorphicString(HallNumber: hall)
    case 4: value = SKSpacegroup.LaueGroupString(HallNumber: hall)
    case 5: value = SKSpacegroup.PointGroupString(HallNumber: hall)
    case 6: value = SKSpacegroup.SchoenfliesString(HallNumber: hall)
    case 7: value = SKSpacegroup.SymmorphicityString(HallNumber: hall)
    default: value = SKSpacegroup.NumberOfElementsString(HallNumber: hall)
    }
    return infoRow(symmetryPropertyTitle(row), value: value)
  }

  private func symmetryPropertyTitle(_ row: Int) -> String
  {
    switch row
    {
    case 0: return "Inversion"
    case 1: return "Inversion center"
    case 2: return "Centrosymmetric"
    case 3: return "Enantiomorphic"
    case 4: return "Laue group"
    case 5: return "Point group"
    case 6: return "Schoenflies"
    case 7: return "Symmorphicity"
    default: return "Number of elements"
    }
  }

  // MARK: Actions

  private func actionsCell(row: Int) -> UITableViewCell
  {
    switch row
    {
    case 0: return actionRow("Recompute bonds")
    case 1: return actionRow("Expand to P1")
    case 2: return actionRow("Super cell")
    case 3: return actionRow("Wrap atoms to cell")
    case 4: return actionRow("Find and impose symmetry")
    case 5: return actionRow("Niggli cell")
    case 6: return actionRow("Primitive cell")
    case 7: return actionRow("Remove symmetry")
    case 8: return actionRow("Add atom")
    case 9: return actionRow("Delete selected atoms")
    default: return actionRow("Add primitive")
    }
  }

  // MARK: Movies

  private func moviesCell(row: Int) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    let extra = maxFrameCount() > 1 ? 3 : 0
    if extra > 0, row < extra
    {
      switch row
      {
      case 0:
        cell.textLabel?.text = "Frame"
        cell.detailTextLabel?.text = "\(currentFrameIndex() + 1) / \(maxFrameCount())"
        let stepper = UIStepper()
        stepper.minimumValue = 0
        stepper.maximumValue = Double(max(0, maxFrameCount() - 1))
        stepper.stepValue = 1
        stepper.value = Double(currentFrameIndex())
        stepper.addAction(UIAction { [weak self] action in
          guard let stepper = action.sender as? UIStepper else { return }
          self?.onSetFrame?(Int(stepper.value))
          self?.tableView.reloadData()
        }, for: .valueChanged)
        cell.accessoryView = stepper
      case 1:
        cell.textLabel?.text = "Previous frame"
      default:
        cell.textLabel?.text = (isPlaying?() ?? false) ? "Pause" : "Play"
      }
      return cell
    }
    let movie = movies[row - extra]
    cell.textLabel?.text = movie.displayName
    cell.detailTextLabel?.text = "\(movie.frames.count) frame\(movie.frames.count == 1 ? "" : "s")"
    cell.accessoryType = (movie.selectedFrame != nil && movie.selectedFrames.isEmpty == false) ? .checkmark : .none
    return cell
  }

  private func didSelectMoviesRow(_ row: Int)
  {
    let extra = maxFrameCount() > 1 ? 3 : 0
    if extra > 0, row < extra
    {
      if row == 1
      {
        onSetFrame?(max(0, currentFrameIndex() - 1))
        tableView.reloadData()
      }
      else if row == 2
      {
        onPlayToggle?()
        tableView.reloadData()
      }
      return
    }
    let movieIndex = row - extra
    guard movies.indices.contains(movieIndex) else { return }
    let movie = movies[movieIndex]
    for scene in project?.sceneList.scenes ?? []
    {
      if scene.movies.contains(where: { $0 === movie })
      {
        project?.sceneList.selectedScene = scene
        scene.selectedMovie = movie
        scene.selectedMovies = [movie]
      }
    }
    movie.selectedFrame = movie.frames.first
    if let frame = movie.selectedFrame
    {
      movie.selectedFrames = [frame]
    }
    structure = movie.selectedFrame?.object as? Structure
    document.updateChangeCount(.done)
    tableView.reloadData()
    onChange?()
  }

  private func maxFrameCount() -> Int
  {
    return project?.sceneList.maximumNumberOfFrames ?? 1
  }

  private func currentFrameIndex() -> Int
  {
    guard let movie = movies.first(where: { $0.selectedFrame != nil }) ?? movies.first,
          let selected = movie.selectedFrame,
          let index = movie.frames.firstIndex(of: selected) else { return 0 }
    return index
  }

  // MARK: Structure operations

  private func recomputeBonds()
  {
    allStructures().forEach { $0.reComputeBonds() }
    document.updateChangeCount(.done)
    tableView.reloadData()
    onChange?()
  }

  private func expandToP1()
  {
    allStructures().forEach { structure in
      structure.expandSymmetry()
      structure.reComputeBonds()
      structure.reComputeBoundingBox()
    }
    document.updateChangeCount(.done)
    tableView.reloadData()
    onGeometryChange?()
    LogQueue.shared.info(destination: nil, message: "Expanded symmetry to P1")
  }

  private func spaceGroupEditor() -> (Structure & SpaceGroupEditor)?
  {
    return structure as? Structure & SpaceGroupEditor
  }

  private func applySpaceGroupState(_ state: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController), message: String)
  {
    guard let crystal = spaceGroupEditor() else { return }
    crystal.cell = state.cell
    crystal.spaceGroup = state.spaceGroup
    crystal.atomTreeController = state.atoms
    crystal.bondSetController = state.bonds
    crystal.setRepresentationColorScheme(scheme: crystal.atomColorSchemeIdentifier, colorSets: document.colorSets)
    crystal.setRepresentationForceField(forceField: crystal.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)
    crystal.reComputeBoundingBox()
    project?.measurementTreeNodes = []
    document.updateChangeCount(.done)
    tableView.reloadData()
    onGeometryChange?()
    LogQueue.shared.info(destination: nil, message: message)
  }

  private func makeSuperCell()
  {
    guard let crystal = spaceGroupEditor() else {
      LogQueue.shared.warning(destination: nil, message: "Super cell needs a periodic crystal")
      return
    }
    applySpaceGroupState(crystal.superCell, message: "Built super cell from current replicas")
  }

  private func wrapAtomsToCell()
  {
    guard let crystal = spaceGroupEditor() else {
      LogQueue.shared.warning(destination: nil, message: "Wrap atoms needs a periodic crystal")
      return
    }
    applySpaceGroupState(crystal.wrapAtomsToCell, message: "Wrapped atoms into the unit cell")
  }

  private func findAndImposeSymmetry()
  {
    guard let crystal = spaceGroupEditor() else { return }
    LogQueue.shared.info(destination: nil, message: "Finding space group…")
    let colorSets = document.colorSets
    let forceFieldSets = document.forceFieldSets
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      let state = crystal.imposedSymmetry(colorSets: colorSets, forceFieldSets: forceFieldSets)
      DispatchQueue.main.async {
        guard let self else { return }
        if let state
        {
          let setting = state.spaceGroup.spaceGroupSetting
          self.applySpaceGroupState(state, message: "Imposed \(setting.HM) (#\(setting.spaceGroupNumber))")
        }
        else
        {
          LogQueue.shared.warning(destination: nil, message: "Could not impose a higher symmetry")
        }
      }
    }
  }

  private func findNiggli()
  {
    guard let crystal = spaceGroupEditor() else { return }
    if let state = crystal.Niggli(colorSets: document.colorSets, forceFieldSets: document.forceFieldSets)
    {
      applySpaceGroupState(state, message: "Reduced to the Niggli cell")
    }
    else
    {
      LogQueue.shared.warning(destination: nil, message: "Could not compute a Niggli cell")
    }
  }

  private func findPrimitive()
  {
    guard let crystal = spaceGroupEditor() else { return }
    if let state = crystal.primitive(colorSets: document.colorSets, forceFieldSets: document.forceFieldSets)
    {
      applySpaceGroupState(state, message: "Reduced to the primitive cell")
    }
    else
    {
      LogQueue.shared.warning(destination: nil, message: "Could not compute a primitive cell")
    }
  }

  private func removeSymmetry()
  {
    guard let crystal = spaceGroupEditor() else { return }
    applySpaceGroupState(crystal.removedSymmetry, message: "Removed symmetry (P1 copies kept)")
  }

  // MARK: Compute properties

  private func computeHeliumVoidFraction()
  {
    guard !isComputing else { return }
    let structures = computeTargets()
    guard !structures.isEmpty else {
      LogQueue.shared.warning(destination: nil, message: "No structure with unit-cell positions to compute a void fraction")
      return
    }
    isComputing = true
    tableView.reloadData()
    let payload = structures.map { ($0.cell, $0.atomUnitCellPositions, $0.potentialParameters) }
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      let results = SKVoidFraction.compute(structures: payload, probeParameters: SIMD2<Double>(10.9, 2.64))
      DispatchQueue.main.async {
        guard let self else { return }
        for (i, result) in results.enumerated() where structures.indices.contains(i)
        {
          structures[i].minimumGridEnergyValue = Float(result.minimumEnergyValue)
          structures[i].structureHeliumVoidFraction = result.voidFraction
          structures[i].recomputeDensityProperties()
        }
        self.isComputing = false
        self.document.updateChangeCount(.done)
        self.tableView.reloadData()
        let text = results.map { String(format: "%.4f", $0.voidFraction) }.joined(separator: ", ")
        LogQueue.shared.info(destination: nil, message: "Helium void fraction: \(text)")
      }
    }
  }

  private func computeNitrogenSurfaceArea()
  {
    guard !isComputing else { return }
    let structures = computeTargets()
    guard !structures.isEmpty else {
      LogQueue.shared.warning(destination: nil, message: "No structure with unit-cell positions to compute a surface area")
      return
    }
    isComputing = true
    tableView.reloadData()
    let payload = structures.map { ($0.cell, $0.atomUnitCellPositions, $0.potentialParameters, probeParameters: $0.frameworkProbeParameters) }
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      do
      {
        let results = try SKNitrogenSurfaceArea.compute(structures: payload)
        DispatchQueue.main.async {
          guard let self else { return }
          for (i, result) in results.enumerated() where structures.indices.contains(i)
          {
            structures[i].structureNitrogenSurfaceArea = result
            structures[i].recomputeDensityProperties()
          }
          self.isComputing = false
          self.document.updateChangeCount(.done)
          self.tableView.reloadData()
          let text = structures.map { String(format: "%.1f m²/g", $0.structureGravimetricNitrogenSurfaceArea) }.joined(separator: ", ")
          LogQueue.shared.info(destination: nil, message: "Nitrogen surface area: \(text)")
        }
      }
      catch
      {
        DispatchQueue.main.async {
          self?.isComputing = false
          self?.tableView.reloadData()
          LogQueue.shared.error(destination: nil, message: error.localizedDescription)
        }
      }
    }
  }

  private func computeTargets() -> [Structure]
  {
    let all = project?.allObjects.compactMap({ $0 as? Structure }) ?? []
    return all.filter { !$0.atomUnitCellPositions.isEmpty }
  }

  // MARK: Add atom / delete atoms / primitives

  private func presentAddAtomPicker()
  {
    let sheet = UIAlertController(title: "Add atom", message: "Inserted at the cell center.", preferredStyle: .actionSheet)
    for symbol in ["H", "C", "N", "O", "F", "Si", "Al", "P", "S", "Cl", "Fe", "Cu", "Zn", "Zr"]
    {
      sheet.addAction(UIAlertAction(title: symbol, style: .default) { [weak self] _ in
        self?.addAtom(symbol: symbol)
      })
    }
    sheet.addAction(UIAlertAction(title: "Other…", style: .default) { [weak self] _ in
      self?.presentCustomElement()
    })
    sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    presentSheet(sheet)
  }

  private func presentCustomElement()
  {
    let alert = UIAlertController(title: "Element", message: "Chemical symbol, e.g. Mo", preferredStyle: .alert)
    alert.addTextField { $0.autocapitalizationType = .words }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
      guard let symbol = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !symbol.isEmpty else { return }
      self?.addAtom(symbol: symbol)
    })
    present(alert, animated: true)
  }

  private func addAtom(symbol: String)
  {
    guard let structure else { return }
    guard let elementId = SKElement.atomicNumber(forSymbol: symbol),
          elementId >= 0, elementId < PredefinedElements.sharedInstance.elementSet.count else {
      LogQueue.shared.warning(destination: nil, message: "Unknown element \(symbol)")
      return
    }
    let displayName = PredefinedElements.sharedInstance.elementSet[elementId].chemicalSymbol
    let color = document.colorSets[structure.atomColorSchemeIdentifier]?[displayName] ?? UIColor.black
    let drawRadius = structure.drawRadius(elementId: elementId)
    let bondDistanceCriteria = document.forceFieldSets[structure.atomForceFieldIdentifier]?[displayName]?.userDefinedRadius ?? 1.0
    let position: SIMD3<Double> = structure.isFractional ? SIMD3<Double>(0.5, 0.5, 0.5) : structure.cell.boundingBox.center
    let atom = SKAsymmetricAtom(displayName: displayName, elementId: elementId, uniqueForceFieldName: displayName, position: position, charge: 0.0, color: color, drawRadius: drawRadius, bondDistanceCriteria: bondDistanceCriteria, occupancy: 1.0)
    structure.expandSymmetry(asymmetricAtom: atom)
    let node = SKAtomTreeNode(representedObject: atom)
    structure.atomTreeController.insertNode(node, inItem: nil, atIndex: 0)
    structure.atomTreeController.selectedTreeNodes = [node]
    structure.atomTreeController.tag()
    structure.reComputeBonds()
    structure.bondSetController.tag()
    structure.reComputeBoundingBox()
    document.updateChangeCount(.done)
    tableView.reloadData()
    onGeometryChange?()
    LogQueue.shared.info(destination: nil, message: "Added \(displayName)")
  }

  private func deleteSelectedAtoms()
  {
    guard let structure else { return }
    let selected = structure.atomTreeController.selectedTreeNodes.flatMap { $0.flattenedNodes() }.sorted { $0.indexPath > $1.indexPath }
    guard !selected.isEmpty else {
      LogQueue.shared.warning(destination: nil, message: "Select atoms in the viewer first")
      return
    }
    for node in selected
    {
      structure.atomTreeController.removeNode(node)
    }
    structure.atomTreeController.selectedTreeNodes.removeAll()
    structure.atomTreeController.tag()
    structure.reComputeBonds()
    structure.bondSetController.tag()
    structure.reComputeBoundingBox()
    document.updateChangeCount(.done)
    tableView.reloadData()
    onGeometryChange?()
    LogQueue.shared.info(destination: nil, message: "Deleted \(selected.count) atom\(selected.count == 1 ? "" : "s")")
  }

  private func presentPrimitivePicker()
  {
    let sheet = UIAlertController(title: "Add primitive", message: "Drawn together with the current structure", preferredStyle: .actionSheet)
    sheet.addAction(UIAlertAction(title: "Ellipsoid", style: .default) { [weak self] _ in self?.addPrimitive(.ellipsoid) })
    sheet.addAction(UIAlertAction(title: "Cylinder", style: .default) { [weak self] _ in self?.addPrimitive(.cylinder) })
    sheet.addAction(UIAlertAction(title: "Polygonal prism", style: .default) { [weak self] _ in self?.addPrimitive(.prism) })
    sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    presentSheet(sheet)
  }

  private enum PrimitiveKind { case ellipsoid, cylinder, prism }

  private func usesCrystalPrimitives() -> Bool
  {
    guard let structure else { return true }
    return !(structure is Molecule || structure is Protein || structure is DNA)
  }

  private func addPrimitive(_ kind: PrimitiveKind)
  {
    guard let project else { return }
    let crystal = usesCrystalPrimitives()
    let frame: iRASPAObject
    switch kind
    {
    case .ellipsoid:
      if crystal
      {
        let primitive = CrystalEllipsoidPrimitive(name: "Ellipsoid")
        if let cell = structure?.cell { primitive.cell = cell }
        primitive.reComputeBoundingBox()
        frame = iRASPAObject(crystalEllipsoidPrimitive: primitive)
      }
      else
      {
        let primitive = EllipsoidPrimitive(name: "Ellipsoid")
        if let cell = structure?.cell { primitive.cell = cell }
        primitive.reComputeBoundingBox()
        frame = iRASPAObject(ellipsoidPrimitive: primitive)
      }
    case .cylinder:
      if crystal
      {
        let primitive = CrystalCylinderPrimitive(name: "Cylinder")
        primitive.primitiveNumberOfSides = 41
        if let cell = structure?.cell { primitive.cell = cell }
        primitive.reComputeBoundingBox()
        frame = iRASPAObject(crystalCylinderPrimitive: primitive)
      }
      else
      {
        let primitive = CylinderPrimitive(name: "Cylinder")
        primitive.primitiveNumberOfSides = 41
        if let cell = structure?.cell { primitive.cell = cell }
        primitive.reComputeBoundingBox()
        frame = iRASPAObject(cylinderPrimitive: primitive)
      }
    case .prism:
      if crystal
      {
        let primitive = CrystalPolygonalPrismPrimitive(name: "Polygonal prism")
        primitive.primitiveNumberOfSides = 4
        if let cell = structure?.cell { primitive.cell = cell }
        primitive.reComputeBoundingBox()
        frame = iRASPAObject(crystalPolygonalPrismPrimitive: primitive)
      }
      else
      {
        let primitive = PolygonalPrismPrimitive(name: "Polygonal prism")
        primitive.primitiveNumberOfSides = 4
        if let cell = structure?.cell { primitive.cell = cell }
        primitive.reComputeBoundingBox()
        frame = iRASPAObject(polygonalPrismPrimitive: primitive)
      }
    }
    let movie = Movie(name: frame.object.displayName, structure: frame)
    movie.selectedFrame = frame
    movie.selectedFrames.insert(frame)
    if let scene = project.sceneList.selectedScene ?? project.sceneList.scenes.first
    {
      scene.movies.append(movie)
      scene.selectedMovies.insert(movie)
    }
    else
    {
      let scene = Scene()
      scene.displayName = movie.displayName
      scene.movies = [movie]
      scene.selectedMovie = movie
      scene.selectedMovies = [movie]
      project.sceneList.scenes.append(scene)
      project.sceneList.selectedScene = scene
    }
    document.updateChangeCount(.done)
    movies = project.sceneList.scenes.flatMap { $0.movies }
    tableView.reloadData()
    onGeometryChange?()
    LogQueue.shared.info(destination: nil, message: "Added \(movie.displayName)")
  }

  // MARK: Material conversion

  private func selectedFrame() -> iRASPAObject?
  {
    return selectedObjects.first
      ?? project?.sceneList.selectedScene?.selectedMovie?.selectedFrame
      ?? movies.compactMap({ $0.selectedFrame }).first
  }

  private func convertType(_ kind: SKStructure.Kind)
  {
    guard let frame = selectedFrame() else { return }
    if frame.type == kind { return }
    let replacement: iRASPAObject
    switch kind
    {
    case .crystal:
      replacement = iRASPAObject(crystal: Crystal(from: frame.object))
    case .molecularCrystal:
      replacement = iRASPAObject(molecularCrystal: MolecularCrystal(from: frame.object))
    case .molecule:
      replacement = iRASPAObject(molecule: Molecule(from: frame.object))
    case .protein:
      replacement = iRASPAObject(protein: Protein(from: frame.object))
    case .proteinCrystal:
      replacement = iRASPAObject(proteinCrystal: ProteinCrystal(from: frame.object))
    case .crystalEllipsoidPrimitive:
      replacement = iRASPAObject(crystalEllipsoidPrimitive: CrystalEllipsoidPrimitive(from: frame.object))
    case .crystalCylinderPrimitive:
      replacement = iRASPAObject(crystalCylinderPrimitive: CrystalCylinderPrimitive(from: frame.object))
    case .crystalPolygonalPrismPrimitive:
      replacement = iRASPAObject(crystalPolygonalPrismPrimitive: CrystalPolygonalPrismPrimitive(from: frame.object))
    case .ellipsoidPrimitive:
      replacement = iRASPAObject(ellipsoidPrimitive: EllipsoidPrimitive(from: frame.object))
    case .cylinderPrimitive:
      replacement = iRASPAObject(cylinderPrimitive: CylinderPrimitive(from: frame.object))
    case .polygonalPrismPrimitive:
      replacement = iRASPAObject(polygonalPrismPrimitive: PolygonalPrismPrimitive(from: frame.object))
    default:
      return
    }
    frame.swapRepresentedObjects(structure: replacement)
    structure = frame.object as? Structure
    project?.measurementTreeNodes = []
    document.updateChangeCount(.done)
    tableView.reloadData()
    onGeometryChange?()
    LogQueue.shared.info(destination: nil, message: "Converted material type")
  }

  // MARK: Row factories

  private func infoRow(_ title: String, value: String?) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    cell.detailTextLabel?.text = value ?? "—"
    return cell
  }

  private func tripleInfoRow(_ title: String, values: SIMD3<Double>?, format: String = "%.4f") -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    if let values
    {
      cell.detailTextLabel?.text = "\(String(format: format, values.x))  \(String(format: format, values.y))  \(String(format: format, values.z))"
      cell.detailTextLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
    }
    else
    {
      cell.detailTextLabel?.text = "—"
    }
    return cell
  }

  private func actionRow(_ title: String) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.textLabel?.text = title
    cell.textLabel?.textColor = view.tintColor
    cell.accessoryType = .disclosureIndicator
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
    // Geometry updates are expensive: apply only when the drag ends.
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
    let makeAction: (Int) -> UIAction = { [weak self] index in
      UIAction(title: options[index], state: index == selectedIndex ? .on : .off) { _ in
        apply(index)
        self?.tableView.reloadData()
      }
    }
    // Long lists (space group numbers, Hall symbols) are split into submenus.
    if options.count > 40
    {
      var groups: [UIMenu] = []
      var start = 0
      while start < options.count
      {
        let end = Swift.min(start + 30, options.count)
        let children = (start..<end).map(makeAction)
        groups.append(UIMenu(title: "\(options[start]) … \(options[end - 1])", children: children))
        start = end
      }
      button.menu = UIMenu(children: groups)
    }
    else
    {
      button.menu = UIMenu(options: .singleSelection, children: options.indices.map(makeAction))
    }
    button.showsMenuAsPrimaryAction = true
    button.sizeToFit()
    var frame = button.frame
    frame.size.width = Swift.min(Swift.max(frame.size.width, 100), 200)
    button.frame = frame
    cell.accessoryView = button
    return cell
  }

  private func fieldRow(_ title: String, value: Double, format: String = "%.2f", apply: @escaping (Double) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    cell.accessoryView = makeNumberField(value: value, format: format, width: 100, apply: apply)
    return cell
  }

  private func intFieldRow(_ title: String, value: Int, apply: @escaping (Int) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    cell.accessoryView = makeNumberField(value: Double(value), format: "%.0f", width: 80) { value in
      apply(Int(value))
    }
    return cell
  }

  private func stepperRow(_ title: String, value: Int, minimum: Int, maximum: Int, apply: @escaping (Int) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    cell.detailTextLabel?.text = String(value)
    let stepper = UIStepper()
    stepper.minimumValue = Double(minimum)
    stepper.maximumValue = Double(maximum)
    stepper.stepValue = 1
    stepper.value = Double(value)
    stepper.addAction(UIAction { action in
      guard let stepper = action.sender as? UIStepper else { return }
      apply(Int(stepper.value))
    }, for: .valueChanged)
    cell.accessoryView = stepper
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

  private func presentSheet(_ sheet: UIAlertController)
  {
    if let pop = sheet.popoverPresentationController
    {
      pop.sourceView = tableView
      pop.sourceRect = tableView.bounds
    }
    present(sheet, animated: true)
  }
}
