import UIKit
import MetalKit
import RenderKit
import iRASPAKit
import LogViewKit
import SymmetryKit

final class RenderHostViewController: UIViewController
{
  let document: iRASPAUIDocument
  let renderController = RenderViewController()
  var onInspect: (() -> Void)?
  var onProjectReady: (() -> Void)?
  private var currentNode: ProjectTreeNode?
  private var pendingNode: ProjectTreeNode?
  private let pickLabel = UILabel()
  private var measureMode = false
  private var multiSelectMode = false
  private weak var measurementController: MeasurementViewController?
  private var measureItem: UIBarButtonItem?
  private var multiSelectItem: UIBarButtonItem?
  private let movieBar = UIToolbar()
  private let movieFrameItem = UIBarButtonItem(title: "Frame", style: .plain, target: nil, action: nil)
  private var movieTimer: DispatchSourceTimer?
  private var isPlayingMovie = false

  init(document: iRASPAUIDocument)
  {
    self.document = document
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView()
  {
    let container = UIView()
    container.backgroundColor = .black
    view = container
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()
    addChild(renderController)
    let metalView = renderController.view!
    metalView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(metalView)
    NSLayoutConstraint.activate([
      metalView.topAnchor.constraint(equalTo: view.topAnchor),
      metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
    renderController.didMove(toParent: self)
    (metalView as? MetalView)?.onTapPoint = { [weak self] point in
      self?.handlePick(at: point)
    }
    movieBar.translatesAutoresizingMaskIntoConstraints = false
    movieBar.isHidden = true
    view.addSubview(movieBar)
    NSLayoutConstraint.activate([
      movieBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      movieBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      movieBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    ])
    updateMovieBarItems()
    pickLabel.translatesAutoresizingMaskIntoConstraints = false
    pickLabel.font = UIFont.preferredFont(forTextStyle: .title3)
    pickLabel.textColor = .white
    pickLabel.backgroundColor = UIColor.black.withAlphaComponent(0.55)
    pickLabel.numberOfLines = 0
    pickLabel.textAlignment = .center
    pickLabel.text = " No structures in this document. Open materials_sample.cif. "
    pickLabel.isHidden = false
    view.addSubview(pickLabel)
    view.bringSubviewToFront(movieBar)
    NSLayoutConstraint.activate([
      pickLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      pickLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      pickLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
      pickLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
    ])
    navigationItem.title = document.fileURL.deletingPathExtension().lastPathComponent
    let measure = UIBarButtonItem(image: UIImage(systemName: "ruler"), style: .plain, target: self, action: #selector(toggleMeasure))
    measureItem = measure
    let multi = UIBarButtonItem(image: UIImage(systemName: "checklist"), style: .plain, target: self, action: #selector(toggleMultiSelect))
    multiSelectItem = multi
    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped)),
      UIBarButtonItem(title: "Inspect", style: .plain, target: self, action: #selector(inspectTapped)),
      measure,
      multi,
      UIBarButtonItem(image: UIImage(systemName: "camera.rotate"), style: .plain, target: self, action: #selector(resetCamera)),
      UIBarButtonItem(title: "View", menu: cameraMenu())
    ]
    if let node = pendingNode
    {
      pendingNode = nil
      display(node: node)
    }
  }

  override func viewDidAppear(_ animated: Bool)
  {
    super.viewDidAppear(animated)
    if let node = pendingNode
    {
      pendingNode = nil
      bindProject(node)
    }
    else if currentProject() == nil
    {
      pickLabel.text = " No structures in this document. Open materials_sample.cif or tap Sample. "
      pickLabel.isHidden = false
      renderController.redraw()
    }
    else
    {
      renderController.redraw()
    }
  }

  override func viewDidLayoutSubviews()
  {
    super.viewDidLayoutSubviews()
    let size = renderController.view?.bounds.size ?? .zero
    if let camera = currentProject()?.renderCamera
    {
      camera.updateCameraForWindowResize(width: Double(max(size.width, 1)), height: Double(max(size.height, 1)))
    }
    if size.width > 8, size.height > 8, currentProject() != nil
    {
      let firstRealSize = lastBoundSize.width < 8
      let changed = abs(size.width - lastBoundSize.width) > 2 || abs(size.height - lastBoundSize.height) > 2
      if firstRealSize || changed
      {
        lastBoundSize = size
        if firstRealSize, let camera = currentProject()?.renderCamera, let project = currentProject(), !camera.initialized
        {
          camera.boundingBox = project.renderBoundingBox
          camera.resetForNewBoundingBox(project.renderBoundingBox)
          camera.resetCameraToDirection()
          camera.resetCameraDistance()
          camera.initialized = true
        }
        renderController.reloadData()
        renderController.redraw()
      }
    }
  }

  private var lastBoundSize: CGSize = .zero

  func display(node: ProjectTreeNode)
  {
    currentNode = node
    do
    {
      let queue: OperationQueue? = node.representedObject.storageType == .publicCloud ? Cloud.shared.cloudQueue : nil
      try node.unwrapProject(outlineView: nil, queue: queue, colorSets: document.colorSets, forceFieldSets: document.forceFieldSets, reloadCompletionBlock: { [weak self] in
        DispatchQueue.main.async {
          self?.bindIfReady(node)
        }
      })
    }
    catch
    {
      LogQueue.shared.error(destination: nil, message: "Could not unwrap \(node.displayName): \(error.localizedDescription)")
      pickLabel.text = " Could not load \(node.displayName) "
      pickLabel.isHidden = false
    }
    if node.representedObject.storageType == .publicCloud,
       node.representedObject.lazyStatus != .loaded
    {
      pickLabel.text = " Loading \(node.displayName) from iCloud… "
      pickLabel.isHidden = false
      return
    }
    if node.representedObject.lazyStatus == .lazy, node.representedObject.data == nil
    {
      pickLabel.text = " Missing project data in this document "
      pickLabel.isHidden = false
    }
    bindIfReady(node)
  }

  private func bindIfReady(_ node: ProjectTreeNode)
  {
    if isViewLoaded, view.window != nil
    {
      bindProject(node)
    }
    else
    {
      pendingNode = node
    }
  }

  private func bindProject(_ node: ProjectTreeNode)
  {
    guard let project = node.representedObject.project as? ProjectStructureNode else {
      pickLabel.text = " \(node.displayName) has no structure to draw "
      pickLabel.isHidden = false
      LogQueue.shared.warning(destination: nil, message: "\(node.displayName) is not a loaded structure project (status \(String(describing: node.representedObject.lazyStatus)))")
      return
    }

    ensureSelection(project)
    project.allObjects.compactMap({ $0 as? Structure }).forEach {
      $0.setRepresentationForceField(forceField: $0.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)
    }

    let createdCamera = project.renderCamera == nil
    if createdCamera
    {
      project.renderCamera = RKCamera()
    }
    if let camera = project.renderCamera
    {
      let size = renderController.view?.bounds.size ?? .zero
      camera.updateCameraForWindowResize(width: Double(max(size.width, 1)), height: Double(max(size.height, 1)))
      if createdCamera || !camera.initialized
      {
        camera.boundingBox = project.renderBoundingBox
        camera.resetForNewBoundingBox(project.renderBoundingBox)
        camera.resetCameraToDirection()
        camera.resetCameraDistance()
        camera.initialized = true
      }
      else
      {
        camera.boundingBox = project.renderBoundingBox
      }
    }
    if project.renderBackgroundCachedImage == nil
    {
      project.renderBackgroundCachedImage = project.drawGradientCGImage()
    }

    renderController.renderDataSource = project
    renderController.renderCameraSource = project
    renderController.reloadData()
    renderController.redraw()

    let atomCount = project.sceneList.totalNumberOfAtoms
    if atomCount == 0
    {
      pickLabel.text = " No atoms in \(node.displayName) "
      pickLabel.isHidden = false
    }
    else
    {
      pickLabel.isHidden = true
    }
    LogQueue.shared.info(destination: nil, message: "Drawing \(node.displayName) (\(atomCount) atoms, \(project.renderStructures.count) selected frames)")
    stopMoviePlayback()
    updateMovieBar()
    onProjectReady?()
  }

  func clearDisplay()
  {
    currentNode = nil
    pendingNode = nil
    renderController.renderDataSource = nil
    renderController.renderCameraSource = nil
    pickLabel.text = " No structures in this document. Open materials_sample.cif or tap Sample. "
    pickLabel.isHidden = false
    stopMoviePlayback()
    movieBar.isHidden = true
    renderController.reloadData()
    renderController.redraw()
  }

  private func ensureSelection(_ project: ProjectStructureNode)
  {
    project.setInitialSelectionIfNeeded()
    if project.sceneList.selectedScene == nil
    {
      project.sceneList.selectedScene = project.sceneList.scenes.first
    }
    for scene in project.sceneList.scenes
    {
      if scene.selectedMovie == nil
      {
        scene.selectedMovie = scene.movies.first
      }
      for movie in scene.movies
      {
        if movie.selectedFrame == nil
        {
          movie.selectedFrame = movie.frames.first
        }
        if let frame = movie.selectedFrame
        {
          movie.selectedFrames.insert(frame)
        }
      }
    }
  }

  private func handlePick(at uiKitPoint: CGPoint)
  {
    guard let metalView = renderController.view, let project = currentProject() else { return }
    let metalPoint = CGPoint(x: uiKitPoint.x, y: metalView.bounds.height - uiKitPoint.y)
    let pick = renderController.pickPoint(metalPoint)
    if pick[0] == 0
    {
      clearAtomSelection(in: project)
      return
    }
    guard pick[0] == 1 else {
      pickLabel.isHidden = true
      return
    }
    let structureIdentifier = Int(pick[2])
    let pickedAtom = Int(pick[3])
    let structures = project.renderStructures
    guard structureIdentifier >= 0, structureIdentifier < structures.count,
          let structure = structures[structureIdentifier] as? Structure,
          structure.drawAtoms else { return }
    let replicas = max(structure.numberOfReplicas(), 1)
    let nodes = structure.atomTreeController.flattenedLeafNodes()
    let atoms = nodes.compactMap { $0.representedObject }.flatMap { $0.copies }.filter { $0.type == .copy }
    let index = pickedAtom / replicas
    guard atoms.indices.contains(index) else { return }
    let atom = atoms[index]
    if measureMode
    {
      addMeasurement(structure: structure, copy: atom, pickedObject: pickedAtom)
      return
    }
    if let treeNode = nodes.first(where: { $0.representedObject === atom.asymmetricParentAtom })
    {
      if multiSelectMode
      {
        if structure.atomTreeController.selectedTreeNodes.contains(treeNode)
        {
          structure.atomTreeController.selectedTreeNodes.remove(treeNode)
        }
        else
        {
          structure.atomTreeController.selectedTreeNodes.insert(treeNode)
        }
      }
      else
      {
        for other in structures.compactMap({ $0 as? Structure }) where other !== structure
        {
          other.atomTreeController.clearSelection()
        }
        structure.atomTreeController.clearSelection()
        structure.atomTreeController.selectedTreeNodes.insert(treeNode)
      }
    }
    // Selection-only: full reloadRenderData() clears isosurface vertex buffers.
    renderController.reloadRenderDataSelectedAtoms()
    renderController.redraw()
    let count = structure.atomTreeController.selectedTreeNodes.count
    if multiSelectMode
    {
      pickLabel.text = " \(count) atom\(count == 1 ? "" : "s") selected "
      pickLabel.isHidden = false
      return
    }
    presentAtomDetail(atom: atom.asymmetricParentAtom, copy: atom, structure: structure)
  }

  private func clearAtomSelection(in project: ProjectStructureNode)
  {
    for structure in project.renderStructures.compactMap({ $0 as? Structure })
    {
      structure.atomTreeController.clearSelection()
    }
    // Match Cocoa: do not call reloadRenderData() here — it wipes isosurface meshes.
    renderController.reloadRenderDataSelectedAtoms()
    renderController.redraw()
    pickLabel.isHidden = true
  }

  private func addMeasurement(structure: Structure, copy: SKAtomCopy, pickedObject: Int)
  {
    guard let project = currentProject() else { return }
    if project.measurementTreeNodes.count >= 4
    {
      project.measurementTreeNodes = []
    }
    let replica = structure.cell.replicaFromIndex(pickedObject)
    project.measurementTreeNodes.append((structure, copy, replica))
    renderController.reloadRenderMeasurePointsData()
    renderController.redraw()
    presentOrReloadMeasurement(project)
  }

  private func presentOrReloadMeasurement(_ project: ProjectStructureNode)
  {
    if let measurementController
    {
      measurementController.reload()
      return
    }
    guard project.measurementTreeNodes.count >= 2 else { return }
    let detail = MeasurementViewController(project: project)
    detail.onClear = { [weak self] in
      project.measurementTreeNodes = []
      self?.renderController.reloadRenderMeasurePointsData()
      self?.renderController.redraw()
    }
    measurementController = detail
    let nav = UINavigationController(rootViewController: detail)
    nav.modalPresentationStyle = .pageSheet
    if let sheet = nav.sheetPresentationController
    {
      sheet.detents = [.medium(), .large()]
      sheet.prefersGrabberVisible = true
    }
    present(nav, animated: true)
  }

  @objc private func toggleMeasure()
  {
    measureMode.toggle()
    if measureMode { multiSelectMode = false }
    measureItem?.image = UIImage(systemName: measureMode ? "ruler.fill" : "ruler")
    multiSelectItem?.image = UIImage(systemName: "checklist")
    if !measureMode, let project = currentProject()
    {
      project.measurementTreeNodes = []
      renderController.reloadRenderMeasurePointsData()
      renderController.redraw()
      if measurementController != nil
      {
        measurementController?.navigationController?.dismiss(animated: true)
      }
    }
  }

  @objc private func toggleMultiSelect()
  {
    multiSelectMode.toggle()
    if multiSelectMode { measureMode = false }
    multiSelectItem?.image = UIImage(systemName: multiSelectMode ? "checkmark.circle.fill" : "checklist")
    measureItem?.image = UIImage(systemName: "ruler")
    if multiSelectMode
    {
      pickLabel.text = " Multi-select: tap atoms, then Hide selected in Appearance "
      pickLabel.isHidden = false
    }
    else
    {
      pickLabel.isHidden = true
    }
  }

  func zoomCamera(_ delta: Double)
  {
    currentProject()?.renderCamera?.increaseDistance(delta)
    renderController.redraw()
    markEdited()
  }

  func setFieldOfView(_ degrees: Double)
  {
    currentProject()?.renderCamera?.updateFieldOfView(newAngle: degrees * .pi / 180.0)
    renderController.redraw()
    markEdited()
  }

  private func presentAtomDetail(atom: SKAsymmetricAtom, copy: SKAtomCopy, structure: Structure)
  {
    let detail = AtomDetailViewController(atom: atom, copy: copy, structureName: structure.displayName, cell: structure.cell)
    detail.onChange = { [weak self] in
      // reloadData() rebuilds atom buffers and restores adsorption/isosurface meshes.
      self?.renderController.reloadData()
      self?.renderController.redraw()
      self?.markEdited()
    }
    let nav = UINavigationController(rootViewController: detail)
    nav.modalPresentationStyle = .pageSheet
    if let sheet = nav.sheetPresentationController
    {
      sheet.detents = [.medium(), .large()]
      sheet.prefersGrabberVisible = true
    }
    present(nav, animated: true)
  }

  func reloadVisibility()
  {
    renderController.reloadVisibility()
  }

  func reloadScene()
  {
    renderController.reloadData()
    renderController.reloadGlobalAxesSystem()
    renderController.reloadLocalAxesSystem()
    updateMovieBar()
  }

  func reloadAdsorptionSurface()
  {
    LogQueue.shared.info(destination: nil, message: "Computing adsorption surface…")
    renderController.invalidateIsosurfaces()
    renderController.updateIsosurfaceUniforms()
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }
      self.renderController.updateAdsorptionSurface {
        DispatchQueue.main.async {
          self.renderController.updateIsosurfaceUniforms()
          self.renderController.redraw()
          let triangles = (self.currentProject()?.allObjects.compactMap({ $0 as? Structure }) ?? []).map { $0.adsorptionSurfaceNumberOfTriangles }.reduce(0, +)
          if triangles == 0
          {
            LogQueue.shared.warning(destination: nil, message: "Adsorption surface produced 0 triangles. Try iso value 0 with a helium probe, or check the Log for Metal errors.")
          }
          else
          {
            LogQueue.shared.info(destination: nil, message: "Adsorption surface: \(triangles) triangles")
          }
        }
      }
    }
  }

  func reloadIsosurfaceAppearance()
  {
    renderController.updateIsosurfaceUniforms()
    renderController.redraw()
  }

  func reloadBlockingPocketAppearance()
  {
    renderController.updateBlockingPocketUniforms()
    renderController.redraw()
  }

  /// Cheap update path for appearance changes that only affect per-structure uniforms
  /// (colors, intensities, HSV, selection styling) — mirrors Cocoa's updateStructureUniforms+redraw.
  func reloadStructureUniforms()
  {
    renderController.updateStructureUniforms()
    renderController.redraw()
  }

  func reloadLights()
  {
    renderController.updateLightUniforms()
    renderController.redraw()
  }

  /// Redraw without rebuilding any buffers (camera moves, rotation, projection).
  func redrawScene()
  {
    renderController.redraw()
  }

  /// Selection-only refresh (atom list selection changed); keeps isosurface meshes intact.
  func reloadSelectedAtoms()
  {
    renderController.reloadRenderDataSelectedAtoms()
    renderController.redraw()
  }

  /// Selection-only refresh for the bond list (mirrors Cocoa's
  /// reloadRenderDataSelectedInternalBonds).
  func reloadSelectedBonds()
  {
    renderController.reloadRenderDataSelectedInternalBonds()
    renderController.redraw()
  }

  /// Mirrors Cocoa's reloadGlobalAxesSystem+redraw for axes-only changes.
  func reloadGlobalAxes()
  {
    renderController.reloadGlobalAxesSystem()
    renderController.redraw()
  }

  func setBloom(_ value: Double)
  {
    currentProject()?.renderCamera?.bloomLevel = value
    renderController.redraw()
    markEdited()
  }

  func setFit(_ value: Double)
  {
    guard let project = currentProject(), let camera = project.renderCamera else { return }
    camera.resetPercentage = value
    camera.resetCameraDistance()
    renderController.redraw()
    markEdited()
  }

  func reloadBackground()
  {
    if let project = currentProject()
    {
      project.renderBackgroundCachedImage = project.drawGradientCGImage()
    }
    renderController.reloadBackgroundImage()
    renderController.redraw()
  }

  func markEdited()
  {
    document.updateChangeCount(.done)
  }

  override func viewWillDisappear(_ animated: Bool)
  {
    super.viewWillDisappear(animated)
    stopMoviePlayback()
  }

  func reloadFrames()
  {
    renderController.reloadRenderData()
    renderController.redraw()
    updateMovieBar()
  }

  func isMoviePlaying() -> Bool
  {
    return isPlayingMovie
  }

  func toggleMoviePlayback()
  {
    if isPlayingMovie
    {
      stopMoviePlayback()
    }
    else
    {
      startMoviePlayback()
    }
    updateMovieBar()
  }

  func setMovieFrame(_ index: Int)
  {
    currentProject()?.sceneList.synchronizeAllMovieFrames(to: max(0, index))
    reloadFrames()
  }

  func stepMovie(_ delta: Int)
  {
    setMovieFrame(max(0, currentMovieFrameIndex() + delta))
  }

  private func currentMovieFrameIndex() -> Int
  {
    let movies = currentProject()?.sceneList.scenes.flatMap { $0.movies } ?? []
    guard let movie = movies.first(where: { $0.selectedFrame != nil }) ?? movies.first,
          let selected = movie.selectedFrame,
          let index = movie.frames.firstIndex(of: selected) else { return 0 }
    return index
  }

  private func maxMovieFrames() -> Int
  {
    return currentProject()?.sceneList.maximumNumberOfFrames ?? 1
  }

  private func startMoviePlayback()
  {
    guard maxMovieFrames() > 1 else { return }
    isPlayingMovie = true
    movieTimer?.cancel()
    let timer = DispatchSource.makeTimerSource(queue: .main)
    timer.schedule(deadline: .now() + 0.4, repeating: 0.4)
    timer.setEventHandler { [weak self] in
      self?.advanceMovieFrame()
    }
    movieTimer = timer
    timer.resume()
  }

  private func stopMoviePlayback()
  {
    isPlayingMovie = false
    movieTimer?.cancel()
    movieTimer = nil
    updateMovieBarItems()
  }

  private func advanceMovieFrame()
  {
    guard let project = currentProject() else {
      stopMoviePlayback()
      return
    }
    let before = currentMovieFrameIndex()
    project.sceneList.advanceAllMovieFrames()
    if currentMovieFrameIndex() == before
    {
      project.sceneList.setAllMovieFramesToBeginning()
    }
    reloadFrames()
  }

  private func updateMovieBar()
  {
    let frames = maxMovieFrames()
    movieBar.isHidden = frames <= 1
    movieFrameItem.title = "\(currentMovieFrameIndex() + 1) / \(max(1, frames))"
    updateMovieBarItems()
  }

  private func updateMovieBarItems()
  {
    let playImage = UIImage(systemName: isPlayingMovie ? "pause.fill" : "play.fill")
    let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    movieBar.items = [
      flex,
      UIBarButtonItem(image: UIImage(systemName: "backward.frame.fill"), style: .plain, target: self, action: #selector(previousFrameTapped)),
      UIBarButtonItem(image: playImage, style: .plain, target: self, action: #selector(playTapped)),
      UIBarButtonItem(image: UIImage(systemName: "forward.frame.fill"), style: .plain, target: self, action: #selector(nextFrameTapped)),
      movieFrameItem,
      flex
    ]
  }

  @objc private func playTapped()
  {
    toggleMoviePlayback()
  }

  @objc private func previousFrameTapped()
  {
    stopMoviePlayback()
    stepMovie(-1)
  }

  @objc private func nextFrameTapped()
  {
    stopMoviePlayback()
    stepMovie(1)
  }

  private func cameraMenu() -> UIMenu
  {
    let directions: [(String, RKCamera.ResetDirectionType)] = [
      ("+X", .plus_X), ("+Y", .plus_Y), ("+Z", .plus_Z),
      ("−X", .minus_X), ("−Y", .minus_Y), ("−Z", .minus_Z)
    ]
    let directionActions = directions.map { title, direction in
      UIAction(title: title) { [weak self] _ in
        self?.setCameraDirection(direction)
      }
    }
    return UIMenu(children: [
      UIMenu(title: "Direction", options: .displayInline, children: directionActions),
      UIAction(title: "Orthographic") { [weak self] _ in self?.setProjection(.orthographic) },
      UIAction(title: "Perspective") { [weak self] _ in self?.setProjection(.perspective) },
      UIAction(title: "Rotate +90° Y") { [weak self] _ in self?.rotateCameraY(90) },
      UIAction(title: "Rotate −90° Y") { [weak self] _ in self?.rotateCameraY(-90) },
      UIAction(title: "Zoom in") { [weak self] _ in self?.zoomCamera(4.0) },
      UIAction(title: "Zoom out") { [weak self] _ in self?.zoomCamera(-4.0) },
      UIAction(title: "Reset camera") { [weak self] _ in self?.resetCamera() }
    ])
  }

  func rotateCameraY(_ degrees: Double)
  {
    currentProject()?.renderCamera?.rotateCameraAroundAxisY(angle: degrees * .pi / 180.0)
    renderController.redraw()
    markEdited()
  }

  func setCameraDirection(_ direction: RKCamera.ResetDirectionType)
  {
    guard let camera = currentProject()?.renderCamera else { return }
    camera.resetDirectionType = direction
    camera.resetCameraToDirection()
    camera.resetCameraDistance()
    renderController.redraw()
    markEdited()
  }

  func setProjection(_ type: RKCamera.FrustrumType)
  {
    guard let camera = currentProject()?.renderCamera else { return }
    switch type
    {
    case .orthographic:
      camera.setCameraToOrthographic()
    case .perspective:
      camera.setCameraToPerspective()
    }
    renderController.redraw()
    markEdited()
  }

  @objc private func inspectTapped()
  {
    onInspect?()
  }

  @objc private func shareTapped()
  {
    guard let node = currentNode else { return }
    ExportController.present(from: self, document: document, node: node, render: renderController)
  }

  @objc func resetCamera()
  {
    guard let project = currentProject(), let camera = project.renderCamera else { return }
    camera.boundingBox = project.renderBoundingBox
    camera.resetCameraToDirection()
    camera.resetCameraDistance()
    renderController.redraw()
  }

  func fitCameraToBoundingBox()
  {
    guard let project = currentProject(), let camera = project.renderCamera else { return }
    camera.resetForNewBoundingBox(project.renderBoundingBox)
    renderController.redraw()
  }
}

extension RenderHostViewController
{
  func currentProject() -> ProjectStructureNode?
  {
    return currentNode?.representedObject.project as? ProjectStructureNode
  }

  func currentNodeForExport() -> ProjectTreeNode?
  {
    return currentNode
  }
}
