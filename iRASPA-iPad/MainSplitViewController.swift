import UIKit
import iRASPAKit
import RenderKit

final class MainSplitViewController: UISplitViewController, UISplitViewControllerDelegate
{
  let document: iRASPAUIDocument
  let projectTree: ProjectTreeViewController
  let sidebar: StructureSidebarViewController
  let renderHost: RenderHostViewController
  let inspectorPager: UITabBarController
  private let appearanceInspector: AppearanceInspectorViewController
  private let structureInspector: StructureInspectorViewController
  private let cameraInspector: CameraInspectorViewController
  private let elementInspector: ElementInspectorViewController
  private let infoInspector: InfoInspectorViewController
  private let atomInspector: AtomInspectorViewController
  private let bondInspector: BondInspectorViewController

  init(document: iRASPAUIDocument)
  {
    self.document = document
    self.projectTree = ProjectTreeViewController(document: document)
    self.sidebar = StructureSidebarViewController(document: document, projectTree: projectTree)
    self.renderHost = RenderHostViewController(document: document)
    let appearance = AppearanceInspectorViewController(document: document)
    let structure = StructureInspectorViewController(document: document)
    let camera = CameraInspectorViewController(document: document)
    let elements = ElementInspectorViewController(document: document)
    let info = InfoInspectorViewController(document: document)
    let atoms = AtomInspectorViewController(document: document)
    let bonds = BondInspectorViewController(document: document)
    let log = LogViewController()
    self.appearanceInspector = appearance
    self.structureInspector = structure
    self.cameraInspector = camera
    self.elementInspector = elements
    self.infoInspector = info
    self.atomInspector = atoms
    self.bondInspector = bonds
    self.inspectorPager = UITabBarController()
    camera.tabBarItem = UITabBarItem(title: "Camera", image: UIImage(systemName: "camera"), tag: 0)
    elements.tabBarItem = UITabBarItem(title: "Elements", image: UIImage(systemName: "atom"), tag: 1)
    info.tabBarItem = UITabBarItem(title: "Info", image: UIImage(systemName: "info.circle"), tag: 2)
    appearance.tabBarItem = UITabBarItem(title: "Appearance", image: UIImage(systemName: "paintpalette"), tag: 3)
    structure.tabBarItem = UITabBarItem(title: "Cell", image: UIImage(systemName: "cube"), tag: 4)
    atoms.tabBarItem = UITabBarItem(title: "Atoms", image: UIImage(systemName: "circle.grid.3x3"), tag: 5)
    bonds.tabBarItem = UITabBarItem(title: "Bonds", image: UIImage(systemName: "link"), tag: 6)
    log.tabBarItem = UITabBarItem(title: "Log", image: UIImage(systemName: "text.alignleft"), tag: 7)
    inspectorPager.viewControllers = [
      UINavigationController(rootViewController: camera),
      UINavigationController(rootViewController: elements),
      UINavigationController(rootViewController: info),
      UINavigationController(rootViewController: appearance),
      UINavigationController(rootViewController: structure),
      UINavigationController(rootViewController: atoms),
      UINavigationController(rootViewController: bonds),
      UINavigationController(rootViewController: log)
    ]
    super.init(style: .doubleColumn)
    preferredDisplayMode = .oneBesideSecondary
    preferredSplitBehavior = .tile
    minimumPrimaryColumnWidth = 240
    preferredPrimaryColumnWidth = 320
    setViewController(UINavigationController(rootViewController: sidebar), for: .primary)
    setViewController(UINavigationController(rootViewController: renderHost), for: .secondary)
    renderHost.onInspect = { [weak self] in
      guard let self else { return }
      self.reloadInspectors()
      self.inspectorPager.modalPresentationStyle = .pageSheet
      if let sheet = self.inspectorPager.sheetPresentationController
      {
        sheet.detents = [.medium(), .large()]
        sheet.prefersGrabberVisible = true
      }
      self.present(self.inspectorPager, animated: true)
    }
    projectTree.renderHost = renderHost
    sidebar.onSelect = { [weak self] node in
      self?.renderHost.display(node: node)
      self?.reloadInspectors()
    }
    sidebar.onClose = { [weak self] in
      self?.closeDocument()
    }
    sidebar.onSceneSelectionChange = { [weak self] in
      self?.reloadInspectors()
    }
    sidebar.onFrameSelectionChange = { [weak self] in
      self?.renderHost.reloadScene()
      self?.document.updateChangeCount(.done)
      self?.reloadInspectors()
    }
    sidebar.onVisibilityChange = { [weak self] in
      self?.renderHost.reloadScene()
      self?.document.updateChangeCount(.done)
    }
    sidebar.onContentChange = { [weak self] in
      self?.renderHost.reloadScene()
      self?.renderHost.fitCameraToBoundingBox()
      self?.document.updateChangeCount(.done)
      self?.reloadInspectors()
    }
    renderHost.onProjectReady = { [weak self] in
      self?.sidebar.reloadLists()
      self?.reloadInspectors()
    }
    appearance.onChange = { [weak self] in
      self?.renderHost.reloadScene()
    }
    appearance.onUniformChange = { [weak self] in
      self?.renderHost.reloadStructureUniforms()
    }
    appearance.onBackgroundChange = { [weak self] in
      self?.renderHost.reloadBackground()
    }
    appearance.onVisibilityChange = { [weak self] in
      self?.renderHost.reloadVisibility()
    }
    appearance.onSurfaceAppearanceChange = { [weak self] in
      self?.renderHost.reloadIsosurfaceAppearance()
    }
    appearance.onBlockingPocketAppearanceChange = { [weak self] in
      self?.renderHost.reloadBlockingPocketAppearance()
    }
    appearance.onSurfaceChange = { [weak self] in
      self?.renderHost.reloadAdsorptionSurface()
    }
    elements.onChange = { [weak self] in
      self?.renderHost.reloadScene()
    }
    atoms.onChange = { [weak self] in
      self?.renderHost.reloadScene()
    }
    atoms.onSelectionChange = { [weak self] in
      self?.renderHost.reloadSelectedAtoms()
    }
    atoms.onVisibilityChange = { [weak self] in
      self?.renderHost.reloadVisibility()
    }
    bonds.onChange = { [weak self] in
      self?.renderHost.reloadScene()
    }
    bonds.onSelectionChange = { [weak self] in
      self?.renderHost.reloadSelectedBonds()
    }
    structure.onChange = { [weak self] in
      self?.renderHost.reloadScene()
      self?.reloadInspectors()
    }
    structure.onGeometryChange = { [weak self] in
      self?.renderHost.reloadScene()
      self?.renderHost.resetCamera()
      self?.reloadInspectors()
    }
    structure.onSurfaceChange = { [weak self] in
      self?.renderHost.reloadAdsorptionSurface()
    }
    structure.onPlayToggle = { [weak self] in
      self?.renderHost.toggleMoviePlayback()
    }
    structure.onSetFrame = { [weak self] index in
      self?.renderHost.setMovieFrame(index)
    }
    structure.isPlaying = { [weak self] in
      self?.renderHost.isMoviePlaying() ?? false
    }
    camera.onCameraChange = { [weak self] in
      self?.renderHost.redrawScene()
    }
    camera.onProjection = { [weak self] type in
      self?.renderHost.setProjection(type)
      if let node = self?.renderHost.currentNodeForExport()
      {
        camera.reload(from: node)
      }
    }
    camera.onFieldOfView = { [weak self] degrees in
      self?.renderHost.setFieldOfView(degrees)
    }
    camera.onReset = { [weak self] in
      self?.renderHost.resetCamera()
      if let node = self?.renderHost.currentNodeForExport()
      {
        camera.reload(from: node)
      }
    }
    camera.onBloom = { [weak self] value in
      self?.renderHost.setBloom(value)
    }
    camera.onLightsChange = { [weak self] in
      self?.renderHost.reloadLights()
    }
    camera.onBackgroundChange = { [weak self] in
      self?.renderHost.reloadBackground()
    }
    camera.onAxesChange = { [weak self] in
      self?.renderHost.reloadGlobalAxes()
    }
    camera.onCreatePicture = { [weak self, weak camera] in
      guard let self, let camera, let node = self.renderHost.currentNodeForExport() else { return }
      ExportController.createPicture(from: camera, node: node, render: self.renderHost.renderController)
    }
    camera.onCreateMovie = { [weak self, weak camera] in
      guard let self, let camera, let node = self.renderHost.currentNodeForExport() else { return }
      ExportController.createMovie(from: camera, node: node)
    }
    camera.aspectRatio = { [weak self] in
      let size = self?.renderHost.renderController.view.bounds.size ?? CGSize(width: 1, height: 1)
      return size.height > 0 ? Double(size.width / size.height) : 1.0
    }
    delegate = self
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  private func reloadInspectors()
  {
    guard let node = renderHost.currentNodeForExport() else { return }
    let objects = sidebar.selectedIRASPObjects()
    appearanceInspector.reload(from: node, objects: objects)
    structureInspector.reload(from: node, objects: objects)
    cameraInspector.reload(from: node)
    elementInspector.reload(from: node, objects: objects)
    infoInspector.reload(from: node, objects: objects)
    atomInspector.reload(from: node, objects: objects)
    bondInspector.reload(from: node, objects: objects)
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    title = document.fileURL.deletingPathExtension().lastPathComponent
  }

  @objc private func closeDocument()
  {
    if document.hasUnsavedChanges
    {
      document.save(to: document.fileURL, for: .forOverwriting) { [weak self] _ in
        self?.document.close { _ in
          self?.dismiss(animated: true)
        }
      }
    }
    else
    {
      document.close { [weak self] _ in
        self?.dismiss(animated: true)
      }
    }
  }
}
