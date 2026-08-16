import UIKit
import iRASPAKit
import SymmetryKit
import SimulationKit
import MathKit
import LogViewKit

/// Faithful iPad version of Cocoa's `StructureAtomDetailViewController`:
/// a table of asymmetric atoms (visibility, fixed, name, element, force-field
/// type, occupancy, position, charge) with the bottom bar holding the +/−
/// buttons, the net-charge readout and the filter field.
final class AtomInspectorViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
  let document: iRASPAUIDocument

  /// Heavy change: geometry/content changed (rebuild render buffers).
  var onChange: (() -> Void)?
  /// Selection-only change (cheap re-upload of selected-atom buffers).
  var onSelectionChange: (() -> Void)?
  /// Visibility uniforms changed (mirrors Cocoa's extra reloadVisibility call).
  var onVisibilityChange: (() -> Void)?

  private var node: ProjectTreeNode?
  private var project: ProjectStructureNode?
  private var structure: Structure?

  private struct Row
  {
    let node: SKAtomTreeNode
    let depth: Int
  }
  private var rows: [Row] = []
  private var filterString: String = ""
  /// Groups start collapsed; only nodes in here show their children.
  private var expandedNodes: Set<SKAtomTreeNode> = []

  private let headerView = UIView()
  private let tableView = UITableView(frame: .zero, style: .plain)
  private let addButton = UIButton(configuration: .gray())
  private let removeButton = UIButton(configuration: .gray())
  private let netChargeLabel = UILabel()
  private let filterField = UISearchTextField()

  // Column layout shared between the header and every row.
  fileprivate struct Columns
  {
    static let checkbox: CGFloat = 30
    static let fixed: CGFloat = 76
    static let name: CGFloat = 78
    static let element: CGFloat = 40
    static let forceField: CGFloat = 58
    static let occupancy: CGFloat = 56
    static let position: CGFloat = 68
    static let charge: CGFloat = 54
    static let spacing: CGFloat = 4
  }

  init(document: iRASPAUIDocument)
  {
    self.document = document
    super.init(nibName: nil, bundle: nil)
    title = "Atoms"
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Layout
  // =====================================================================

  override func viewDidLoad()
  {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground

    buildHeader()

    tableView.dataSource = self
    tableView.delegate = self
    tableView.allowsMultipleSelection = true
    tableView.rowHeight = 40
    tableView.separatorInset = .zero
    tableView.register(AtomRowCell.self, forCellReuseIdentifier: "atomRow")
    tableView.translatesAutoresizingMaskIntoConstraints = false

    let barBackground = UIView()
    barBackground.backgroundColor = .secondarySystemGroupedBackground
    barBackground.translatesAutoresizingMaskIntoConstraints = false

    addButton.configuration?.image = UIImage(systemName: "plus")
    addButton.menu = UIMenu(children: [
      UIAction(title: "Add Atom", image: UIImage(systemName: "circlebadge")) { [weak self] _ in self?.addAtom() },
      UIAction(title: "Add Atom Group", image: UIImage(systemName: "folder")) { [weak self] _ in self?.addAtomGroup() }
    ])
    addButton.showsMenuAsPrimaryAction = true

    removeButton.configuration?.image = UIImage(systemName: "minus")
    removeButton.addAction(UIAction { [weak self] _ in self?.removeSelection() }, for: .touchUpInside)

    netChargeLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    netChargeLabel.textColor = .secondaryLabel
    netChargeLabel.setContentHuggingPriority(.required, for: .horizontal)

    filterField.placeholder = "Filter atoms"
    filterField.addAction(UIAction { [weak self] _ in self?.filterChanged() }, for: .editingChanged)

    let bottomBar = UIStackView(arrangedSubviews: [addButton, removeButton, netChargeLabel, filterField])
    bottomBar.axis = .horizontal
    bottomBar.spacing = 12
    bottomBar.alignment = .center
    bottomBar.isLayoutMarginsRelativeArrangement = true
    bottomBar.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    bottomBar.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(headerView)
    view.addSubview(tableView)
    view.addSubview(barBackground)
    barBackground.addSubview(bottomBar)

    headerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      headerView.heightAnchor.constraint(equalToConstant: 28),

      tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: barBackground.topAnchor),

      barBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      barBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      barBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      bottomBar.topAnchor.constraint(equalTo: barBackground.topAnchor),
      bottomBar.leadingAnchor.constraint(equalTo: barBackground.leadingAnchor),
      bottomBar.trailingAnchor.constraint(equalTo: barBackground.trailingAnchor),
      bottomBar.bottomAnchor.constraint(equalTo: barBackground.safeAreaLayoutGuide.bottomAnchor)
    ])
  }

  private func buildHeader()
  {
    headerView.backgroundColor = .secondarySystemGroupedBackground

    func label(_ text: String, width: CGFloat, alignment: NSTextAlignment = .center) -> UILabel
    {
      let label = UILabel()
      label.text = text
      label.font = .systemFont(ofSize: 11, weight: .semibold)
      label.textColor = .secondaryLabel
      label.textAlignment = alignment
      label.widthAnchor.constraint(equalToConstant: width).isActive = true
      return label
    }

    let stack = UIStackView(arrangedSubviews: [
      label("Vis", width: Columns.checkbox),
      label("Fix", width: Columns.fixed),
      label("Name", width: Columns.name, alignment: .left),
      label("El", width: Columns.element),
      label("Type", width: Columns.forceField),
      label("Occ", width: Columns.occupancy),
      label("x", width: Columns.position),
      label("y", width: Columns.position),
      label("z", width: Columns.position),
      label("q", width: Columns.charge)
    ])
    stack.axis = .horizontal
    stack.spacing = Columns.spacing
    stack.alignment = .center
    stack.translatesAutoresizingMaskIntoConstraints = false
    headerView.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
      stack.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
      stack.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -8)
    ])
  }

  // MARK: Data
  // =====================================================================

  func reload(from node: ProjectTreeNode, objects: [iRASPAObject])
  {
    self.node = node
    self.project = node.representedObject.loadedProjectStructureNode
    self.structure = objects.compactMap { $0.object as? Structure }.first
      ?? project?.allObjects.compactMap { $0 as? Structure }.first
    applyFilterPredicate()
    reloadData()
  }

  private var filterActive: Bool
  {
    return !filterString.isEmpty
  }

  private func applyFilterPredicate()
  {
    guard let structure else { return }
    let searchString = filterString
    if searchString.isEmpty
    {
      structure.atomTreeController.filterPredicate = { _ in return true }
    }
    else
    {
      // Same semantics as Cocoa: case-insensitive regex on the display name.
      structure.atomTreeController.filterPredicate = { atomTreeNode in
        let nodeString = atomTreeNode.representedObject.displayName
        return nodeString.range(of: searchString, options: [.caseInsensitive, .regularExpression]) != nil
      }
    }
    structure.atomTreeController.updateFilteredNodes()
  }

  private func filterChanged()
  {
    filterString = filterField.text ?? ""
    applyFilterPredicate()
    reloadData()
  }

  private func buildRows()
  {
    rows = []
    guard let structure else { return }
    let controller = structure.atomTreeController
    func walk(_ nodes: [SKAtomTreeNode], depth: Int)
    {
      for child in nodes
      {
        rows.append(Row(node: child, depth: depth))
        // While filtering everything is expanded (as in Cocoa); otherwise
        // only descend into explicitly expanded groups.
        if filterActive || expandedNodes.contains(child)
        {
          walk(filterActive ? child.filteredAndSortedNodes : child.childNodes, depth: depth + 1)
        }
      }
    }
    walk(filterActive ? controller.filteredRootNodes : controller.rootNodes, depth: 0)
  }

  private func reloadData()
  {
    buildRows()
    tableView.reloadData()
    syncSelectionFromModel()
    updateNetCharge()
    removeButton.isEnabled = !(structure?.atomTreeController.selectedTreeNodes.isEmpty ?? true)
  }

  private func syncSelectionFromModel()
  {
    guard let structure else { return }
    let selected = structure.atomTreeController.selectedTreeNodes
    for (index, row) in rows.enumerated() where selected.contains(row.node)
    {
      tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
    }
  }

  private func updateNetCharge()
  {
    guard let structure else {
      netChargeLabel.text = ""
      return
    }
    let asymmetricAtoms: [SKAsymmetricAtom] = structure.atomTreeController.flattenedLeafNodes().compactMap { $0.representedObject }
    let atoms: [SKAtomCopy] = asymmetricAtoms.flatMap { $0.copies }.filter { $0.type == .copy }
    let netCharge: Double = atoms.map { $0.asymmetricParentAtom.charge }.reduce(0.0, +)
    netChargeLabel.text = String(format: "Net charge: %.4f", netCharge)
  }

  private func markEdited()
  {
    project?.isEdited = true
    document.updateChangeCount(.done)
  }

  /// Bounding box, representation and render buffers after a structural change
  /// (mirrors Cocoa's addNode/setAtomPosition tail).
  private func contentDidChange(recomputeBonds: Bool)
  {
    guard let structure, let project else { return }
    if recomputeBonds
    {
      structure.bondSetController.selectedObjects = []
      structure.reComputeBonds()
    }
    structure.reComputeBoundingBox()
    project.renderCamera?.boundingBox = project.renderBoundingBox
    markEdited()
    onChange?()
  }

  // MARK: Add / remove
  // =====================================================================

  private func addAtom()
  {
    guard let structure else { return }
    let element = 6
    let displayName = PredefinedElements.sharedInstance.elementSet[element].chemicalSymbol
    let color = document.colorSets[structure.atomColorSchemeIdentifier]?[displayName] ?? NSColor.black
    let drawRadius = structure.drawRadius(elementId: element)
    let bondDistanceCriteria = document.forceFieldSets[structure.atomForceFieldIdentifier]?[displayName]?.userDefinedRadius ?? 1.0
    let asymmetricAtom = SKAsymmetricAtom(displayName: displayName, elementId: element, uniqueForceFieldName: displayName, position: SIMD3<Double>(0, 0, 0), charge: 0.0, color: color, drawRadius: drawRadius, bondDistanceCriteria: bondDistanceCriteria, occupancy: 1.0)
    structure.expandSymmetry(asymmetricAtom: asymmetricAtom)
    let treeNode = SKAtomTreeNode(representedObject: asymmetricAtom)
    treeNode.matchesFilter = true
    insertNode(treeNode)
  }

  private func addAtomGroup()
  {
    guard let structure else { return }
    let displayName = PredefinedElements.sharedInstance.elementSet[6].chemicalSymbol
    let color = document.colorSets[structure.atomColorSchemeIdentifier]?[displayName] ?? NSColor.black
    let drawRadius = structure.drawRadius(elementId: 6)
    let bondDistanceCriteria = document.forceFieldSets[structure.atomForceFieldIdentifier]?[displayName]?.userDefinedRadius ?? 1.0
    let groupAtom = SKAsymmetricAtom(displayName: displayName, elementId: 6, uniqueForceFieldName: displayName, position: SIMD3<Double>(0, 0, 0), charge: 0.0, color: color, drawRadius: drawRadius, bondDistanceCriteria: bondDistanceCriteria, occupancy: 1.0)
    groupAtom.displayName = "New group"
    groupAtom.symmetryType = .container
    structure.expandSymmetry(asymmetricAtom: groupAtom)
    let treeNode = SKAtomTreeNode(representedObject: groupAtom, isGroup: true)
    treeNode.matchesFilter = true
    insertNode(treeNode)
  }

  private func insertNode(_ treeNode: SKAtomTreeNode)
  {
    guard let structure else { return }
    let controller = structure.atomTreeController
    controller.insertNode(treeNode, inItem: nil, atIndex: 0)
    controller.selectedTreeNodes.insert(treeNode)
    controller.tag()
    if filterActive
    {
      controller.updateFilteredNodes()
    }
    structure.setRepresentationForceField(forceField: structure.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)
    structure.setRepresentationStyle(style: structure.atomRepresentationStyle, colorSets: document.colorSets)
    contentDidChange(recomputeBonds: true)
    reloadData()
  }

  private func removeSelection()
  {
    guard let structure else { return }
    let controller = structure.atomTreeController
    // Include every descendant of a selected group node.
    var doomed: Set<SKAtomTreeNode> = []
    func collect(_ node: SKAtomTreeNode)
    {
      doomed.insert(node)
      node.childNodes.forEach(collect)
    }
    controller.selectedTreeNodes.forEach(collect)
    guard !doomed.isEmpty else { return }

    // Drop the bonds that touch a removed atom.
    let removedAtoms = Set(doomed.compactMap { $0.representedObject })
    let bondIndexes = IndexSet(structure.bondSetController.arrangedObjects.enumerated()
      .filter { removedAtoms.contains($0.element.atom1) || removedAtoms.contains($0.element.atom2) }
      .map { $0.offset })
    for index in bondIndexes.reversed()
    {
      structure.bondSetController.arrangedObjects.remove(at: index)
    }
    structure.bondSetController.selectedObjects = []
    structure.bondSetController.tag()

    // Remove deepest nodes first so parent index paths stay valid.
    for node in doomed.sorted(by: { $0.indexPath > $1.indexPath })
    {
      controller.removeNode(node)
    }
    controller.selectedTreeNodes = []
    controller.tag()
    if filterActive
    {
      controller.updateFilteredNodes()
    }
    contentDidChange(recomputeBonds: false)
    onSelectionChange?()
    reloadData()
  }

  private func toggleExpansion(_ treeNode: SKAtomTreeNode)
  {
    if expandedNodes.contains(treeNode)
    {
      expandedNodes.remove(treeNode)
    }
    else
    {
      expandedNodes.insert(treeNode)
    }
    reloadData()
  }

  // MARK: Edit actions
  // =====================================================================

  private func setVisibility(_ treeNode: SKAtomTreeNode, to isVisible: Bool)
  {
    guard let structure else { return }
    if treeNode.isGroup
    {
      ProteinRibbonSegmentSupport.setGroupVisibility(treeNode, isVisible: isVisible)
    }
    else
    {
      treeNode.representedObject.isVisible = isVisible
    }
    structure.atomTreeController.tag()
    markEdited()
    onChange?()
    reloadData()
  }

  /// "Atoms" segment on a protein residue/segment/chain group row: toggles the
  /// visibility of all atoms under the group without touching the ribbon.
  private func setGroupAtomsVisibility(_ treeNode: SKAtomTreeNode, to isVisible: Bool)
  {
    guard let structure else { return }
    ProteinRibbonSegmentSupport.setGroupAtomsVisibility(treeNode, isVisible: isVisible)
    structure.atomTreeController.tag()
    markEdited()
    onChange?()
    onVisibilityChange?()
    reloadData()
  }

  /// "Ribbon" segment: toggles the ribbon of the group, atoms stay as they are.
  private func setGroupRibbonVisibility(_ treeNode: SKAtomTreeNode, to isVisible: Bool)
  {
    guard let structure else { return }
    ProteinRibbonSegmentSupport.setGroupRibbonVisibility(treeNode, isVisible: isVisible)
    structure.atomTreeController.tag()
    markEdited()
    onChange?()
    onVisibilityChange?()
    reloadData()
  }

  private func setFixed(_ treeNode: SKAtomTreeNode, to isFixed: Bool3)
  {
    treeNode.representedObject.isFixed = isFixed
    markEdited()
  }

  private func setName(_ treeNode: SKAtomTreeNode, to newValue: String)
  {
    treeNode.representedObject.displayName = newValue
    markEdited()
    onChange?()
  }

  private func setElement(_ treeNode: SKAtomTreeNode, to symbol: String)
  {
    guard let structure else { return }
    guard let atomicNumber = SKElement.atomicNumber(forSymbol: symbol) else {
      LogQueue.shared.error(destination: nil, message: "Element \(symbol) unknown. Select correct element type.")
      reloadData()
      return
    }
    let atom = treeNode.representedObject
    atom.elementIdentifier = atomicNumber
    structure.setRepresentationStyle(style: structure.atomRepresentationStyle, for: [atom])
    structure.setRepresentationType(type: structure.atomRepresentationType, for: [atom])
    structure.setRepresentationColorScheme(scheme: structure.atomColorSchemeIdentifier, colorSets: document.colorSets)
    contentDidChange(recomputeBonds: true)
    reloadData()
  }

  private func setForceFieldType(_ treeNode: SKAtomTreeNode, to newName: String)
  {
    guard let structure else { return }
    treeNode.representedObject.uniqueForceFieldName = newName
    structure.setRepresentationColorScheme(scheme: structure.atomColorSchemeIdentifier, colorSets: document.colorSets)
    structure.setRepresentationForceField(forceField: structure.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)
    contentDidChange(recomputeBonds: true)
    reloadData()
  }

  private func setOccupancy(_ treeNode: SKAtomTreeNode, to newValue: Double)
  {
    guard let structure else { return }
    let atom = treeNode.representedObject
    atom.occupancy = newValue
    structure.expandSymmetry(asymmetricAtom: atom)
    contentDidChange(recomputeBonds: true)
    reloadData()
  }

  private func setPosition(_ treeNode: SKAtomTreeNode, component: Int, to newValue: Double)
  {
    guard let structure else { return }
    let atom = treeNode.representedObject
    atom.position[component] = newValue
    structure.expandSymmetry(asymmetricAtom: atom)
    contentDidChange(recomputeBonds: true)
    reloadData()
  }

  private func setCharge(_ treeNode: SKAtomTreeNode, to newValue: Double)
  {
    treeNode.representedObject.charge = newValue
    markEdited()
    onChange?()
    updateNetCharge()
  }

  // MARK: Table view
  // =====================================================================

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    return rows.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCell(withIdentifier: "atomRow", for: indexPath) as! AtomRowCell
    let row = rows[indexPath.row]
    let treeNode = row.node

    cell.configure(node: treeNode, depth: row.depth, isExpanded: filterActive || expandedNodes.contains(treeNode))

    cell.onToggleExpand = { [weak self] in self?.toggleExpansion(treeNode) }
    cell.onVisibility = { [weak self] isVisible in self?.setVisibility(treeNode, to: isVisible) }
    cell.onGroupAtomsVisibility = { [weak self] isVisible in self?.setGroupAtomsVisibility(treeNode, to: isVisible) }
    cell.onGroupRibbonVisibility = { [weak self] isVisible in self?.setGroupRibbonVisibility(treeNode, to: isVisible) }
    cell.onFixed = { [weak self] isFixed in self?.setFixed(treeNode, to: isFixed) }
    cell.onName = { [weak self] name in self?.setName(treeNode, to: name) }
    cell.onElement = { [weak self] symbol in self?.setElement(treeNode, to: symbol) }
    cell.onForceField = { [weak self] name in self?.setForceFieldType(treeNode, to: name) }
    cell.onOccupancy = { [weak self] value in self?.setOccupancy(treeNode, to: value) }
    cell.onPosition = { [weak self] component, value in self?.setPosition(treeNode, component: component, to: value) }
    cell.onCharge = { [weak self] value in self?.setCharge(treeNode, to: value) }
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  {
    guard let structure, rows.indices.contains(indexPath.row) else { return }
    structure.atomTreeController.selectedTreeNodes.insert(rows[indexPath.row].node)
    removeButton.isEnabled = true
    onSelectionChange?()
  }

  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
  {
    guard let structure, rows.indices.contains(indexPath.row) else { return }
    structure.atomTreeController.selectedTreeNodes.remove(rows[indexPath.row].node)
    removeButton.isEnabled = !structure.atomTreeController.selectedTreeNodes.isEmpty
    onSelectionChange?()
  }
}

// MARK: Row cell
// =====================================================================

private final class AtomRowCell: UITableViewCell, UITextFieldDelegate
{
  var onToggleExpand: (() -> Void)?
  var onVisibility: ((Bool) -> Void)?
  var onGroupAtomsVisibility: ((Bool) -> Void)?
  var onGroupRibbonVisibility: ((Bool) -> Void)?
  var onFixed: ((Bool3) -> Void)?
  var onName: ((String) -> Void)?
  var onElement: ((String) -> Void)?
  var onForceField: ((String) -> Void)?
  var onOccupancy: ((Double) -> Void)?
  var onPosition: ((Int, Double) -> Void)?
  var onCharge: ((Double) -> Void)?

  private typealias Columns = AtomInspectorViewController.Columns

  private let chevronButton = UIButton(type: .system)
  private let visibilityButton = UIButton(type: .system)
  private let ribbonControl = UIStackView()
  private let groupAtomsButton = AtomRowCell.makeSegmentButton(systemName: "atom")
  private let groupRibbonButton = AtomRowCell.makeSegmentButton(systemName: "scribble.variable")
  private let fixedControl = UIStackView()
  private var fixedAxisButtons: [UIButton] = []
  private let groupIcon = UIImageView(image: UIImage(systemName: "folder"))
  private let nameField = UITextField()
  private let elementField = UITextField()
  private let forceFieldField = UITextField()
  private let occupancyField = UITextField()
  private let xField = UITextField()
  private let yField = UITextField()
  private let zField = UITextField()
  private let chargeField = UITextField()
  private let stack = UIStackView()
  private var indentConstraint: NSLayoutConstraint!

  private var isVisibleState = false
  private var fixedState = Bool3(false, false, false)

  /// Toggle button styled as one segment (blue when selected).
  static func makeSegmentButton(systemName: String) -> UIButton
  {
    var config = UIButton.Configuration.gray()
    config.image = UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 11))
    config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
    config.cornerStyle = .fixed
    config.background.cornerRadius = 4
    let button = UIButton(configuration: config)
    button.changesSelectionAsPrimaryAction = true
    button.configurationUpdateHandler = { button in
      button.configuration?.baseBackgroundColor = button.isSelected ? .systemBlue : nil
      button.configuration?.baseForegroundColor = button.isSelected ? .white : .label
    }
    return button
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?)
  {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    buildLayout()
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  private func numberField(_ field: UITextField, width: CGFloat)
  {
    field.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    field.borderStyle = .roundedRect
    field.textAlignment = .right
    field.keyboardType = .numbersAndPunctuation
    field.autocorrectionType = .no
    field.autocapitalizationType = .none
    field.delegate = self
    field.widthAnchor.constraint(equalToConstant: width).isActive = true
  }

  private func textField(_ field: UITextField, width: CGFloat)
  {
    field.font = .systemFont(ofSize: 12)
    field.borderStyle = .roundedRect
    field.autocorrectionType = .no
    field.autocapitalizationType = .none
    field.delegate = self
    field.widthAnchor.constraint(equalToConstant: width).isActive = true
  }

  private func buildLayout()
  {
    selectionStyle = .default

    chevronButton.widthAnchor.constraint(equalToConstant: 22).isActive = true
    chevronButton.tintColor = .secondaryLabel
    chevronButton.addAction(UIAction { [weak self] _ in
      self?.onToggleExpand?()
    }, for: .touchUpInside)

    visibilityButton.widthAnchor.constraint(equalToConstant: Columns.checkbox).isActive = true
    visibilityButton.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.onVisibility?(!self.isVisibleState)
    }, for: .touchUpInside)

    // Atoms/ribbon visibility segments for protein hierarchy groups
    // (chains, secondary-structure segments, residues), like Cocoa.
    ribbonControl.axis = .horizontal
    ribbonControl.spacing = 1
    ribbonControl.distribution = .fillEqually
    ribbonControl.widthAnchor.constraint(equalToConstant: 64).isActive = true
    groupAtomsButton.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.onGroupAtomsVisibility?(self.groupAtomsButton.isSelected)
    }, for: .touchUpInside)
    groupRibbonButton.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.onGroupRibbonVisibility?(self.groupRibbonButton.isSelected)
    }, for: .touchUpInside)
    ribbonControl.addArrangedSubview(groupAtomsButton)
    ribbonControl.addArrangedSubview(groupRibbonButton)

    // Three independently toggleable segments (x, y, z), like Cocoa's
    // NSSegmentedControl in "select any" mode.
    fixedControl.axis = .horizontal
    fixedControl.spacing = 1
    fixedControl.widthAnchor.constraint(equalToConstant: Columns.fixed).isActive = true
    for (axis, title) in ["x", "y", "z"].enumerated()
    {
      var config = UIButton.Configuration.gray()
      config.attributedTitle = AttributedString(title, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 11, weight: .medium)]))
      config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
      config.cornerStyle = .fixed
      config.background.cornerRadius = 4
      let button = UIButton(configuration: config)
      button.changesSelectionAsPrimaryAction = true
      button.configurationUpdateHandler = { button in
        button.configuration?.baseBackgroundColor = button.isSelected ? .systemBlue : nil
        button.configuration?.baseForegroundColor = button.isSelected ? .white : .label
      }
      button.addAction(UIAction { [weak self] _ in
        guard let self else { return }
        switch axis
        {
        case 0: self.fixedState.x = button.isSelected
        case 1: self.fixedState.y = button.isSelected
        default: self.fixedState.z = button.isSelected
        }
        self.onFixed?(self.fixedState)
      }, for: .touchUpInside)
      fixedAxisButtons.append(button)
      fixedControl.addArrangedSubview(button)
    }
    fixedControl.distribution = .fillEqually

    groupIcon.tintColor = .secondaryLabel
    groupIcon.contentMode = .scaleAspectFit
    groupIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true

    textField(nameField, width: Columns.name)
    textField(elementField, width: Columns.element)
    textField(forceFieldField, width: Columns.forceField)
    numberField(occupancyField, width: Columns.occupancy)
    numberField(xField, width: Columns.position)
    numberField(yField, width: Columns.position)
    numberField(zField, width: Columns.position)
    numberField(chargeField, width: Columns.charge)

    nameField.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.onName?(self.nameField.text ?? "")
    }, for: .editingDidEnd)
    elementField.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.onElement?(self.elementField.text ?? "")
    }, for: .editingDidEnd)
    forceFieldField.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.onForceField?(self.forceFieldField.text ?? "")
    }, for: .editingDidEnd)
    occupancyField.addAction(UIAction { [weak self] _ in
      guard let self, let value = Double(self.occupancyField.text ?? "") else { return }
      self.onOccupancy?(value)
    }, for: .editingDidEnd)
    xField.addAction(UIAction { [weak self] _ in
      guard let self, let value = Double(self.xField.text ?? "") else { return }
      self.onPosition?(0, value)
    }, for: .editingDidEnd)
    yField.addAction(UIAction { [weak self] _ in
      guard let self, let value = Double(self.yField.text ?? "") else { return }
      self.onPosition?(1, value)
    }, for: .editingDidEnd)
    zField.addAction(UIAction { [weak self] _ in
      guard let self, let value = Double(self.zField.text ?? "") else { return }
      self.onPosition?(2, value)
    }, for: .editingDidEnd)
    chargeField.addAction(UIAction { [weak self] _ in
      guard let self, let value = Double(self.chargeField.text ?? "") else { return }
      self.onCharge?(value)
    }, for: .editingDidEnd)

    stack.axis = .horizontal
    stack.spacing = Columns.spacing
    stack.alignment = .center
    stack.translatesAutoresizingMaskIntoConstraints = false
    for view in [chevronButton, visibilityButton, ribbonControl, fixedControl, groupIcon, nameField, elementField, forceFieldField,
                 occupancyField, xField, yField, zField, chargeField]
    {
      stack.addArrangedSubview(view)
    }
    contentView.addSubview(stack)
    indentConstraint = stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
    NSLayoutConstraint.activate([
      indentConstraint,
      stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      stack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -8)
    ])
  }

  private func updateVisibilityIcon()
  {
    visibilityButton.setImage(UIImage(systemName: isVisibleState ? "checkmark.square" : "square"), for: .normal)
  }

  private func updateFixedControl()
  {
    fixedAxisButtons[0].isSelected = fixedState.x
    fixedAxisButtons[1].isSelected = fixedState.y
    fixedAxisButtons[2].isSelected = fixedState.z
  }

  func configure(node: SKAtomTreeNode, depth: Int, isExpanded: Bool)
  {
    let atom = node.representedObject
    indentConstraint.constant = 16 + CGFloat(depth) * 20

    chevronButton.isHidden = !node.isGroup
    chevronButton.setImage(UIImage(systemName: isExpanded ? "chevron.down" : "chevron.right",
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)), for: .normal)

    isVisibleState = atom.isVisible
    updateVisibilityIcon()
    fixedState = atom.isFixed
    updateFixedControl()

    groupIcon.isHidden = !node.isGroup
    nameField.text = atom.displayName

    // Protein hierarchy groups get atoms/ribbon segments instead of the
    // plain visibility checkbox (mirrors Cocoa's group row).
    let isRibbonGroup = node.isGroup && ProteinRibbonSegmentSupport.isRibbonHierarchyGroupNode(node)
    ribbonControl.isHidden = !isRibbonGroup
    visibilityButton.isHidden = isRibbonGroup
    if isRibbonGroup
    {
      groupAtomsButton.isSelected = ProteinRibbonSegmentSupport.groupAtomsVisibilityState(node) == true
      groupRibbonButton.isSelected = atom.isVisible
    }

    let isLeaf = !node.isGroup
    for field in [elementField, forceFieldField, occupancyField, xField, yField, zField, chargeField]
    {
      field.isHidden = !isLeaf
    }
    fixedControl.isHidden = !isLeaf
    if isLeaf
    {
      let element = PredefinedElements.sharedInstance.elementSet[atom.elementIdentifier]
      elementField.text = element.chemicalSymbol
      forceFieldField.text = atom.uniqueForceFieldName
      occupancyField.text = String(format: "%.3f", atom.occupancy)
      xField.text = String(format: "%.5f", atom.position.x)
      yField.text = String(format: "%.5f", atom.position.y)
      zField.text = String(format: "%.5f", atom.position.z)
      chargeField.text = String(format: "%.4f", atom.charge)
    }
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool
  {
    textField.resignFirstResponder()
    return true
  }

  override func prepareForReuse()
  {
    super.prepareForReuse()
    onToggleExpand = nil
    onVisibility = nil
    onGroupAtomsVisibility = nil
    onGroupRibbonVisibility = nil
    onFixed = nil
    onName = nil
    onElement = nil
    onForceField = nil
    onOccupancy = nil
    onPosition = nil
    onCharge = nil
  }
}
