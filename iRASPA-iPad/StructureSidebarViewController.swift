import UIKit
import iRASPAKit
import SymmetryKit

enum SidebarStructureKind
{
  case crystal, molecularCrystal, molecule, protein, proteinCrystal
  case crystalEllipsoid, crystalCylinder, crystalPolygonalPrism
  case ellipsoid, cylinder, polygonalPrism

  func makeFrame(copyingCellFrom previous: Object? = nil) -> iRASPAObject
  {
    switch self
    {
    case .crystal:
      let crystal = Crystal(name: "New crystal")
      crystal.reComputeBoundingBox()
      return iRASPAObject(crystal: crystal)
    case .molecularCrystal:
      let molecularCrystal = MolecularCrystal(name: "New molecular crystal")
      molecularCrystal.reComputeBoundingBox()
      return iRASPAObject(molecularCrystal: molecularCrystal)
    case .molecule:
      let molecule = Molecule(name: "New molecule")
      molecule.reComputeBoundingBox()
      return iRASPAObject(molecule: molecule)
    case .protein:
      let protein = Protein(name: "New protein")
      protein.reComputeBoundingBox()
      return iRASPAObject(protein: protein)
    case .proteinCrystal:
      let proteinCrystal = ProteinCrystal(name: "New protein crystal")
      proteinCrystal.reComputeBoundingBox()
      return iRASPAObject(proteinCrystal: proteinCrystal)
    case .crystalEllipsoid:
      let primitive = CrystalEllipsoidPrimitive(name: "Ellipsoid")
      primitive.cell = previous?.cell ?? SKCell()
      primitive.reComputeBoundingBox()
      return iRASPAObject(crystalEllipsoidPrimitive: primitive)
    case .crystalCylinder:
      let primitive = CrystalCylinderPrimitive(name: "Cylinder")
      primitive.cell = previous?.cell ?? SKCell()
      primitive.reComputeBoundingBox()
      return iRASPAObject(crystalCylinderPrimitive: primitive)
    case .crystalPolygonalPrism:
      let primitive = CrystalPolygonalPrismPrimitive(name: "Polygonal prism")
      primitive.cell = previous?.cell ?? SKCell()
      primitive.reComputeBoundingBox()
      return iRASPAObject(crystalPolygonalPrismPrimitive: primitive)
    case .ellipsoid:
      let primitive = EllipsoidPrimitive(name: "Ellipsoid")
      if let cell = previous?.cell { primitive.cell = cell }
      primitive.reComputeBoundingBox()
      return iRASPAObject(ellipsoidPrimitive: primitive)
    case .cylinder:
      let primitive = CylinderPrimitive(name: "Cylinder")
      if let cell = previous?.cell { primitive.cell = cell }
      primitive.reComputeBoundingBox()
      return iRASPAObject(cylinderPrimitive: primitive)
    case .polygonalPrism:
      let primitive = PolygonalPrismPrimitive(name: "Polygonal prism")
      if let cell = previous?.cell { primitive.cell = cell }
      primitive.reComputeBoundingBox()
      return iRASPAObject(polygonalPrismPrimitive: primitive)
    }
  }

  var movieName: String
  {
    switch self
    {
    case .crystal: return "New crystal"
    case .molecularCrystal: return "New molecular crystal"
    case .molecule: return "New molecule"
    case .protein: return "New protein"
    case .proteinCrystal: return "New protein crystal"
    case .crystalEllipsoid: return "New crystal ellipsoid"
    case .crystalCylinder: return "New crystal cylinder"
    case .crystalPolygonalPrism: return "New crystal polygonal prism"
    case .ellipsoid: return "New ellipsoid"
    case .cylinder: return "New cylinder"
    case .polygonalPrism: return "New polygonal prism"
    }
  }
}

final class SidebarBottomToolbar: UIView
{
  let plusButton = UIButton(type: .system)
  let minusButton = UIButton(type: .system)
  let filterField = UISearchTextField()
  private let stack = UIStackView()
  private let spacer = UIView()

  var showsFilter = true
  {
    didSet
    {
      filterField.isHidden = !showsFilter
      spacer.isHidden = showsFilter
    }
  }

  override init(frame: CGRect)
  {
    super.init(frame: frame)
    backgroundColor = .secondarySystemBackground
    configureSquareButton(plusButton, systemName: "plus")
    configureSquareButton(minusButton, systemName: "minus")
    filterField.placeholder = "Filter"
    filterField.translatesAutoresizingMaskIntoConstraints = false
    filterField.clearButtonMode = .whileEditing
    filterField.returnKeyType = .search
    filterField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    filterField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    spacer.translatesAutoresizingMaskIntoConstraints = false
    spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    spacer.isHidden = true
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .horizontal
    stack.alignment = .center
    stack.spacing = 2
    stack.distribution = .fill
    stack.addArrangedSubview(plusButton)
    stack.addArrangedSubview(minusButton)
    stack.addArrangedSubview(filterField)
    stack.addArrangedSubview(spacer)
    addSubview(stack)
    let topLine = UIView()
    topLine.translatesAutoresizingMaskIntoConstraints = false
    topLine.backgroundColor = .separator
    addSubview(topLine)
    NSLayoutConstraint.activate([
      topLine.topAnchor.constraint(equalTo: topAnchor),
      topLine.leadingAnchor.constraint(equalTo: leadingAnchor),
      topLine.trailingAnchor.constraint(equalTo: trailingAnchor),
      topLine.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),
      stack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
      stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
      stack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -4),
      heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
    ])
  }

  private func configureSquareButton(_ button: UIButton, systemName: String)
  {
    var config = UIButton.Configuration.plain()
    config.image = UIImage(systemName: systemName)
    config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
    config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
    button.configuration = config
    button.tintColor = .label
    button.setContentHuggingPriority(.required, for: .horizontal)
    button.setContentCompressionResistancePriority(.required, for: .horizontal)
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }
}

final class StructureSidebarViewController: UIViewController
{
  let document: iRASPAUIDocument
  let projectTree: ProjectTreeViewController
  let sceneList = SceneListViewController()
  let frameList = FrameListViewController()
  var onSelect: ((ProjectTreeNode) -> Void)?
  var onClose: (() -> Void)?
  var onSceneSelectionChange: (() -> Void)?
  var onFrameSelectionChange: (() -> Void)?
  var onVisibilityChange: (() -> Void)?
  var onContentChange: (() -> Void)?

  private let segmented = UISegmentedControl(items: ["Project", "Scene", "Frame"])
  private let bottomBar = SidebarBottomToolbar()
  private var currentProject: ProjectStructureNode?

  init(document: iRASPAUIDocument, projectTree: ProjectTreeViewController)
  {
    self.document = document
    self.projectTree = projectTree
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    title = "iRASPA"
    segmented.selectedSegmentIndex = 0
    segmented.translatesAutoresizingMaskIntoConstraints = false
    segmented.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
    view.addSubview(segmented)
    bottomBar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(bottomBar)
    configureBottomBar()
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: projectTree, action: #selector(ProjectTreeViewController.closeTapped))
    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(barButtonSystemItem: .add, target: projectTree, action: #selector(ProjectTreeViewController.importTapped)),
      UIBarButtonItem(barButtonSystemItem: .save, target: projectTree, action: #selector(ProjectTreeViewController.saveTapped))
    ]
    embed(projectTree)
    embed(sceneList)
    embed(frameList)
    sceneList.view.isHidden = true
    frameList.view.isHidden = true
    view.bringSubviewToFront(bottomBar)
    view.bringSubviewToFront(segmented)
    NSLayoutConstraint.activate([
      segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      segmented.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      segmented.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
    sceneList.onChange = { [weak self] in
      self?.frameList.reload()
      self?.onSceneSelectionChange?()
    }
    sceneList.onVisibilityChange = { [weak self] in
      self?.onVisibilityChange?()
    }
    sceneList.onContentChange = { [weak self] in
      self?.frameList.reload()
      self?.onContentChange?()
    }
    frameList.onChange = { [weak self] in
      self?.onFrameSelectionChange?()
    }
    projectTree.onSelect = { [weak self] node in
      self?.setProject(from: node)
      self?.onSelect?(node)
    }
    projectTree.onClose = { [weak self] in
      self?.onClose?()
    }
  }

  private func configureBottomBar()
  {
    bottomBar.plusButton.menu = nil
    bottomBar.plusButton.showsMenuAsPrimaryAction = false
    bottomBar.plusButton.removeTarget(nil, action: nil, for: .allEvents)
    bottomBar.minusButton.removeTarget(nil, action: nil, for: .allEvents)
    bottomBar.filterField.removeTarget(nil, action: nil, for: .allEvents)
    switch segmented.selectedSegmentIndex
    {
    case 1:
      bottomBar.showsFilter = false
      bottomBar.plusButton.menu = structureAddMenu { [weak self] kind in
        self?.sceneList.addStructure(kind)
      }
      bottomBar.plusButton.showsMenuAsPrimaryAction = true
      bottomBar.minusButton.addTarget(self, action: #selector(removeSceneTapped), for: .touchUpInside)
    case 2:
      bottomBar.showsFilter = false
      bottomBar.plusButton.menu = structureAddMenu { [weak self] kind in
        self?.frameList.addStructure(kind)
      }
      bottomBar.plusButton.showsMenuAsPrimaryAction = true
      bottomBar.minusButton.addTarget(self, action: #selector(removeFrameTapped), for: .touchUpInside)
    default:
      bottomBar.showsFilter = true
      bottomBar.plusButton.menu = UIMenu(children: [
        UIAction(title: "Add Structure Project", image: UIImage(systemName: "cube")) { [weak self] _ in
          self?.projectTree.addStructureProject()
        },
        UIAction(title: "Add Project Group", image: UIImage(systemName: "folder.badge.plus")) { [weak self] _ in
          self?.projectTree.addProjectGroup()
        }
      ])
      bottomBar.plusButton.showsMenuAsPrimaryAction = true
      bottomBar.minusButton.addTarget(self, action: #selector(removeProjectTapped), for: .touchUpInside)
      bottomBar.filterField.addTarget(self, action: #selector(filterChanged), for: .editingChanged)
    }
  }

  private func structureAddMenu(handler: @escaping (SidebarStructureKind) -> Void) -> UIMenu
  {
    let objects = UIMenu(title: "Add Objects", children: [
      UIAction(title: "Crystal Ellipsoid") { _ in handler(.crystalEllipsoid) },
      UIAction(title: "Crystal Cylinder") { _ in handler(.crystalCylinder) },
      UIAction(title: "Crystal Polygonal Prism") { _ in handler(.crystalPolygonalPrism) },
      UIAction(title: "Ellipsoid") { _ in handler(.ellipsoid) },
      UIAction(title: "Cylinder") { _ in handler(.cylinder) },
      UIAction(title: "Polygonal Prism") { _ in handler(.polygonalPrism) }
    ])
    return UIMenu(children: [
      UIAction(title: "Add Crystal") { _ in handler(.crystal) },
      UIAction(title: "Add Molecular Crystal") { _ in handler(.molecularCrystal) },
      UIAction(title: "Add Molecule") { _ in handler(.molecule) },
      UIAction(title: "Add Protein") { _ in handler(.protein) },
      UIAction(title: "Add Protein Crystal") { _ in handler(.proteinCrystal) },
      objects
    ])
  }

  @objc private func removeProjectTapped()
  {
    projectTree.removeSelectedProject()
  }

  @objc private func removeSceneTapped()
  {
    sceneList.removeSelectedMovie()
  }

  @objc private func removeFrameTapped()
  {
    frameList.removeSelectedFrames()
  }

  @objc private func filterChanged()
  {
    projectTree.setFilter(bottomBar.filterField.text ?? "")
  }

  func reloadLists()
  {
    if let node = projectTree.currentSelectedNode
    {
      setProject(from: node)
    }
    else
    {
      setProject(from: nil)
    }
  }

  private func setProject(from node: ProjectTreeNode?)
  {
    currentProject = node?.representedObject.project as? ProjectStructureNode
    sceneList.project = currentProject
    frameList.project = currentProject
    sceneList.reload()
    frameList.reload()
  }

  private func embed(_ child: UIViewController)
  {
    addChild(child)
    child.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(child.view)
    NSLayoutConstraint.activate([
      child.view.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 8),
      child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      child.view.bottomAnchor.constraint(equalTo: bottomBar.topAnchor)
    ])
    child.didMove(toParent: self)
  }

  @objc private func tabChanged()
  {
    let index = segmented.selectedSegmentIndex
    projectTree.view.isHidden = index != 0
    sceneList.view.isHidden = index != 1
    frameList.view.isHidden = index != 2
    configureBottomBar()
    if index != 0
    {
      reloadLists()
    }
    onSceneSelectionChange?()
  }

  func selectedIRASPObjects() -> [iRASPAObject]
  {
    guard let project = currentProject ?? (projectTree.currentSelectedNode?.representedObject.project as? ProjectStructureNode) else {
      return []
    }
    switch segmented.selectedSegmentIndex
    {
    case 1:
      let movies = project.sceneList.scenes.flatMap { Array($0.selectedMovies) }
      if movies.isEmpty, let movie = project.sceneList.selectedScene?.selectedMovie
      {
        return movie.allIRASPObjects
      }
      return movies.flatMap { $0.allIRASPObjects }
    case 2:
      if let movie = project.sceneList.selectedScene?.selectedMovie
      {
        if !movie.selectedFrames.isEmpty
        {
          return Array(movie.selectedFrames)
        }
        if let frame = movie.selectedFrame
        {
          return [frame]
        }
      }
      return []
    default:
      return project.sceneList.allIRASPObjects
    }
  }

  func selectionSummary() -> String
  {
    let objects = selectedIRASPObjects()
    if objects.isEmpty { return "Nothing selected" }
    if objects.count == 1 { return objects[0].object.displayName }
    switch segmented.selectedSegmentIndex
    {
    case 1: return "\(objects.count) movie frames"
    case 2: return "\(objects.count) frames"
    default: return "\(objects.count) structures"
    }
  }
}

final class SidebarCheckboxCell: UITableViewCell
{
  let checkbox = UIButton(type: .system)
  private let iconView = UIImageView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  var onToggle: (() -> Void)?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?)
  {
    super.init(style: .default, reuseIdentifier: reuseIdentifier)
    checkbox.translatesAutoresizingMaskIntoConstraints = false
    checkbox.addTarget(self, action: #selector(toggle), for: .touchUpInside)
    checkbox.tintColor = .systemBlue
    checkbox.contentHorizontalAlignment = .center
    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.contentMode = .scaleAspectFit
    iconView.tintColor = .secondaryLabel
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
    titleLabel.adjustsFontForContentSizeCategory = true
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
    subtitleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.adjustsFontForContentSizeCategory = true
    let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    textStack.translatesAutoresizingMaskIntoConstraints = false
    textStack.axis = .vertical
    textStack.spacing = 2
    contentView.addSubview(checkbox)
    contentView.addSubview(iconView)
    contentView.addSubview(textStack)
    NSLayoutConstraint.activate([
      checkbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
      checkbox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      checkbox.widthAnchor.constraint(equalToConstant: 28),
      checkbox.heightAnchor.constraint(equalToConstant: 44),
      iconView.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 8),
      iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 22),
      iconView.heightAnchor.constraint(equalToConstant: 22),
      textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
      textStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
      textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
    ])
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(title: String, subtitle: String, image: UIImage?, visible: Bool, selected: Bool)
  {
    checkbox.setImage(UIImage(systemName: visible ? "checkmark.square.fill" : "square"), for: .normal)
    checkbox.accessibilityLabel = visible ? "Visible" : "Hidden"
    iconView.image = image
    titleLabel.text = title
    subtitleLabel.text = subtitle
    accessoryType = selected ? .checkmark : .none
    selectionStyle = .default
  }

  @objc private func toggle()
  {
    onToggle?()
  }
}

final class SceneListViewController: UITableViewController
{
  var project: ProjectStructureNode?
  var onChange: (() -> Void)?
  var onVisibilityChange: (() -> Void)?
  var onContentChange: (() -> Void)?

  init()
  {
    super.init(style: .insetGrouped)
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.register(SidebarCheckboxCell.self, forCellReuseIdentifier: "movie")
    clearsSelectionOnViewWillAppear = false
  }

  func reload()
  {
    tableView.reloadData()
  }

  private var scenes: [Scene]
  {
    return project?.sceneList.scenes ?? []
  }

  override func numberOfSections(in tableView: UITableView) -> Int
  {
    return max(scenes.count, 1)
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
  {
    guard scenes.indices.contains(section) else { return nil }
    let name = scenes[section].displayName
    return name.isEmpty ? "Scene \(section + 1)" : name
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String?
  {
    if scenes.isEmpty { return "Open a project to see its scenes and movies." }
    if section == 0 { return "The checkbox shows or hides a movie. Tap a row to select it for the inspectors." }
    return nil
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    if scenes.isEmpty { return 1 }
    return max(scenes[section].movies.count, 1)
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    if scenes.isEmpty
    {
      let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
      var config = cell.defaultContentConfiguration()
      config.text = "No scenes"
      config.secondaryText = "Select a project in the Project tab"
      config.image = UIImage(systemName: "square.stack.3d.up")
      cell.contentConfiguration = config
      cell.accessoryType = .none
      cell.selectionStyle = .none
      return cell
    }
    let scene = scenes[indexPath.section]
    if scene.movies.isEmpty
    {
      let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
      var config = cell.defaultContentConfiguration()
      config.text = "No movies"
      cell.contentConfiguration = config
      cell.accessoryType = .none
      cell.selectionStyle = .none
      return cell
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: "movie", for: indexPath) as! SidebarCheckboxCell
    let movie = scene.movies[indexPath.row]
    let frameCount = movie.frames.count
    let selected = project?.sceneList.selectedScene === scene && scene.selectedMovie === movie
    cell.apply(
      title: movie.displayName.isEmpty ? "Movie \(indexPath.row + 1)" : movie.displayName,
      subtitle: "\(frameCount) frame\(frameCount == 1 ? "" : "s")",
      image: UIImage(systemName: frameCount > 1 ? "film.stack" : "film"),
      visible: movie.isVisible,
      selected: selected
    )
    cell.onToggle = { [weak self] in
      self?.toggleVisibility(of: movie)
    }
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  {
    tableView.deselectRow(at: indexPath, animated: true)
    guard scenes.indices.contains(indexPath.section) else { return }
    let scene = scenes[indexPath.section]
    guard scene.movies.indices.contains(indexPath.row) else { return }
    select(scene.movies[indexPath.row], in: scene)
  }

  override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration?
  {
    guard scenes.indices.contains(indexPath.section) else { return nil }
    let scene = scenes[indexPath.section]
    guard scene.movies.indices.contains(indexPath.row) else { return nil }
    let movie = scene.movies[indexPath.row]
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
      let showOnly = UIAction(title: "Show only this movie", image: UIImage(systemName: "eye")) { _ in
        self?.setVisibility(only: movie)
      }
      let showAll = UIAction(title: "Show all movies", image: UIImage(systemName: "eye.circle")) { _ in
        self?.setAllVisible(true)
      }
      let hide = UIAction(title: "Hide this movie", image: UIImage(systemName: "eye.slash")) { _ in
        movie.isVisible = false
        self?.tableView.reloadData()
        self?.onVisibilityChange?()
      }
      return UIMenu(children: [showOnly, showAll, hide])
    }
  }

  private func select(_ movie: Movie, in scene: Scene)
  {
    project?.sceneList.selectedScene = scene
    scene.selectedMovie = movie
    scene.selectedMovies = [movie]
    for other in scenes where other !== scene
    {
      other.selectedMovies = []
    }
    if movie.selectedFrame == nil
    {
      movie.selectedFrame = movie.frames.first
    }
    if let frame = movie.selectedFrame
    {
      movie.selectedFrames.insert(frame)
    }
    tableView.reloadData()
    onChange?()
  }

  private func toggleVisibility(of movie: Movie)
  {
    movie.isVisible.toggle()
    tableView.reloadData()
    onVisibilityChange?()
  }

  private func setVisibility(only movie: Movie)
  {
    for scene in scenes
    {
      for item in scene.movies
      {
        item.isVisible = item === movie
      }
    }
    tableView.reloadData()
    onVisibilityChange?()
  }

  private func setAllVisible(_ visible: Bool)
  {
    for scene in scenes
    {
      for movie in scene.movies
      {
        movie.isVisible = visible
      }
    }
    tableView.reloadData()
    onVisibilityChange?()
  }

  func addStructure(_ kind: SidebarStructureKind)
  {
    guard let project else { return }
    let previous = project.sceneList.selectedScene?.selectedMovie?.frames.first?.object
    let frame = kind.makeFrame(copyingCellFrom: previous)
    let movie = Movie(name: kind.movieName, structure: frame)
    movie.selectedFrame = frame
    movie.selectedFrames = [frame]
    movie.isVisible = true

    if let scene = project.sceneList.selectedScene ?? project.sceneList.scenes.first
    {
      var index = scene.movies.count
      if let selected = scene.selectedMovie, let selectedIndex = scene.movies.firstIndex(where: { $0 === selected })
      {
        index = selectedIndex + 1
      }
      scene.movies.insert(movie, at: min(index, scene.movies.count))
      select(movie, in: scene)
    }
    else
    {
      let scene = Scene(name: "New scene", movies: [movie])
      project.sceneList.scenes.append(scene)
      select(movie, in: scene)
    }
    onContentChange?()
  }

  func removeSelectedMovie()
  {
    guard let project,
          let scene = project.sceneList.selectedScene,
          let movie = scene.selectedMovie,
          let index = scene.movies.firstIndex(where: { $0 === movie }) else { return }
    scene.movies.remove(at: index)
    scene.selectedMovies.remove(movie)
    if scene.selectedMovie === movie
    {
      scene.selectedMovie = scene.movies.first
      if let next = scene.selectedMovie
      {
        scene.selectedMovies = [next]
      }
      else
      {
        scene.selectedMovies = []
      }
    }
    if scene.movies.isEmpty, let sceneIndex = project.sceneList.scenes.firstIndex(where: { $0 === scene })
    {
      project.sceneList.scenes.remove(at: sceneIndex)
      if project.sceneList.selectedScene === scene
      {
        project.sceneList.selectedScene = project.sceneList.scenes.first
      }
    }
    tableView.reloadData()
    onContentChange?()
  }
}

final class FrameListViewController: UITableViewController
{
  var project: ProjectStructureNode?
  var onChange: (() -> Void)?

  init()
  {
    super.init(style: .insetGrouped)
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    clearsSelectionOnViewWillAppear = false
  }

  func reload()
  {
    tableView.reloadData()
  }

  private var movie: Movie?
  {
    if let selected = project?.sceneList.selectedScene?.selectedMovie
    {
      return selected
    }
    return project?.sceneList.scenes.first?.movies.first
  }

  private var frames: [iRASPAObject]
  {
    return movie?.frames ?? []
  }

  override func numberOfSections(in tableView: UITableView) -> Int { return 1 }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
  {
    guard let movie else { return "Frames" }
    let name = movie.displayName.isEmpty ? "Movie" : movie.displayName
    return name
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String?
  {
    if movie == nil { return "Select a project, then a movie, to see frames." }
    if frames.count > 1 { return "Tap frames to include them in the 3D view. The latest tap is the inspector target." }
    return nil
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    return max(frames.count, 1)
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    if frames.isEmpty
    {
      config.text = "No frames"
      config.secondaryText = movie == nil ? "Select a movie in the Scene tab" : "This movie has no frames"
      config.image = UIImage(systemName: "square.stack")
      cell.contentConfiguration = config
      cell.accessoryType = .none
      cell.selectionStyle = .none
      return cell
    }
    let frame = frames[indexPath.row]
    let name = frame.object.displayName
    config.text = name.isEmpty ? "Frame \(indexPath.row + 1)" : name
    config.secondaryText = "Frame \(indexPath.row + 1) of \(frames.count) · \(frame.totalNumberOfAtoms) atoms"
    config.image = UIImage(systemName: "cube")
    cell.contentConfiguration = config
    cell.selectionStyle = .default
    if movie?.selectedFrames.contains(frame) == true
    {
      cell.accessoryType = .checkmark
    }
    else
    {
      cell.accessoryType = .none
    }
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  {
    tableView.deselectRow(at: indexPath, animated: true)
    guard let movie, frames.indices.contains(indexPath.row) else { return }
    let frame = frames[indexPath.row]
    if movie.selectedFrames.contains(frame)
    {
      if movie.selectedFrames.count > 1
      {
        movie.selectedFrames.remove(frame)
        if movie.selectedFrame === frame
        {
          movie.selectedFrame = movie.selectedFrames.first
        }
      }
    }
    else
    {
      movie.selectedFrames.insert(frame)
      movie.selectedFrame = frame
    }
    tableView.reloadData()
    onChange?()
  }

  override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration?
  {
    guard let movie, frames.indices.contains(indexPath.row) else { return nil }
    let frame = frames[indexPath.row]
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
      let only = UIAction(title: "Show only this frame", image: UIImage(systemName: "eye")) { _ in
        movie.selectedFrame = frame
        movie.selectedFrames = [frame]
        self?.tableView.reloadData()
        self?.onChange?()
      }
      let all = UIAction(title: "Show all frames", image: UIImage(systemName: "square.stack.3d.up")) { _ in
        movie.selectedFrame = frame
        movie.selectedFrames = Set(movie.frames)
        self?.tableView.reloadData()
        self?.onChange?()
      }
      return UIMenu(children: [only, all])
    }
  }

  func addStructure(_ kind: SidebarStructureKind)
  {
    guard let movie else { return }
    let frame = kind.makeFrame(copyingCellFrom: movie.frames.first?.object)
    var index = movie.frames.count
    if let selected = movie.selectedFrame, let selectedIndex = movie.frames.firstIndex(of: selected)
    {
      index = selectedIndex + 1
    }
    movie.frames.insert(frame, at: min(index, movie.frames.count))
    movie.selectedFrame = frame
    movie.selectedFrames.insert(frame)
    tableView.reloadData()
    onChange?()
  }

  func removeSelectedFrames()
  {
    guard let movie else { return }
    let toRemove = movie.selectedFrames
    guard !toRemove.isEmpty else { return }
    movie.frames.removeAll { toRemove.contains($0) }
    movie.selectedFrames = []
    movie.selectedFrame = movie.frames.first
    if let frame = movie.selectedFrame
    {
      movie.selectedFrames = [frame]
    }
    tableView.reloadData()
    onChange?()
  }
}
