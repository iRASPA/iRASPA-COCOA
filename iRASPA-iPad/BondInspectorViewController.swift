import UIKit
import iRASPAKit
import SymmetryKit
import SimulationKit
import MathKit
import LogViewKit

/// Faithful iPad version of Cocoa's `StructureBondDetailViewController`:
/// one row per asymmetric bond with visibility, id, per-axis fix controls for
/// both atoms, bond type, the two elements, and the bond length (field and
/// slider). The bottom bar holds delete, "Recompute Bonds" and "Type Bonds".
final class BondInspectorViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
  let document: iRASPAUIDocument

  /// Heavy change: geometry/content changed (rebuild render buffers).
  var onChange: (() -> Void)?
  /// Bond-selection-only change (cheap re-upload of selected-bond buffers).
  var onSelectionChange: (() -> Void)?

  private var node: ProjectTreeNode?
  private var project: ProjectStructureNode?
  private var structure: Structure?

  private let headerView = UIView()
  private let tableView = UITableView(frame: .zero, style: .plain)
  private let removeButton = UIButton(configuration: .gray())
  private let recomputeButton = UIButton(configuration: .gray())
  private let typeBondsButton = UIButton(configuration: .gray())
  private let countLabel = UILabel()

  // Column layout shared between the header and every row.
  fileprivate struct Columns
  {
    static let checkbox: CGFloat = 30
    static let id: CGFloat = 34
    static let fix: CGFloat = 100
    static let type: CGFloat = 96
    static let element: CGFloat = 30
    static let length: CGFloat = 70
    static let slider: CGFloat = 110
    static let spacing: CGFloat = 4
  }

  init(document: iRASPAUIDocument)
  {
    self.document = document
    super.init(nibName: nil, bundle: nil)
    title = "Bonds"
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
    tableView.rowHeight = 44
    tableView.separatorInset = .zero
    tableView.register(BondRowCell.self, forCellReuseIdentifier: "bondRow")
    tableView.translatesAutoresizingMaskIntoConstraints = false

    let barBackground = UIView()
    barBackground.backgroundColor = .secondarySystemGroupedBackground
    barBackground.translatesAutoresizingMaskIntoConstraints = false

    removeButton.configuration?.image = UIImage(systemName: "minus")
    removeButton.addAction(UIAction { [weak self] _ in self?.deleteSelection() }, for: .touchUpInside)

    recomputeButton.configuration?.title = "Recompute Bonds"
    recomputeButton.addAction(UIAction { [weak self] _ in self?.recomputeBonds() }, for: .touchUpInside)

    typeBondsButton.configuration?.title = "Type Bonds"
    typeBondsButton.addAction(UIAction { [weak self] _ in self?.typeBonds() }, for: .touchUpInside)

    countLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    countLabel.textColor = .secondaryLabel
    countLabel.textAlignment = .right

    let bottomBar = UIStackView(arrangedSubviews: [removeButton, recomputeButton, typeBondsButton, countLabel])
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
      label("Id", width: Columns.id),
      label("Fix atom 1", width: Columns.fix),
      label("Fix atom 2", width: Columns.fix),
      label("Type", width: Columns.type),
      label("El", width: Columns.element),
      label("El", width: Columns.element),
      label("Length", width: Columns.length),
      label("", width: Columns.slider)
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
    reloadData()
  }

  private func reloadData()
  {
    tableView.reloadData()
    syncSelectionFromModel()
    updateBottomBar()
  }

  private func syncSelectionFromModel()
  {
    guard let structure else { return }
    for index in structure.bondSetController.selectedObjects
      where index < structure.bondSetController.arrangedObjects.count
    {
      tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
    }
  }

  private func updateBottomBar()
  {
    let count = structure?.bondSetController.arrangedObjects.count ?? 0
    countLabel.text = "\(count) bond\(count == 1 ? "" : "s")"
    removeButton.isEnabled = !(structure?.bondSetController.selectedObjects.isEmpty ?? true)
    recomputeButton.isEnabled = structure != nil
    typeBondsButton.isEnabled = structure != nil
  }

  private func markEdited()
  {
    project?.isEdited = true
    document.updateChangeCount(.done)
  }

  // MARK: Bottom-bar actions
  // =====================================================================

  private func deleteSelection()
  {
    guard let structure else { return }
    let indexSet = structure.bondSetController.selectedObjects
    guard !indexSet.isEmpty else { return }
    for index in indexSet.reversed()
    {
      structure.bondSetController.arrangedObjects.remove(at: index)
    }
    structure.bondSetController.selectedObjects = []
    markEdited()
    onChange?()
    reloadData()
  }

  /// Cocoa's context-menu "Recompute Bonds".
  private func recomputeBonds()
  {
    guard let structure else { return }
    structure.bondSetController = SKBondSetController(arrangedObjects: structure.computeBonds(cancelHandler: { return false }, updateHandler: {}))
    markEdited()
    onChange?()
    reloadData()
  }

  /// Cocoa's context-menu "Type Bonds": re-derive single/double/triple types.
  private func typeBonds()
  {
    guard let structure else { return }
    structure.typeBonds()
    markEdited()
    onChange?()
    reloadData()
  }

  // MARK: Edit actions
  // =====================================================================

  private func setBondVisibility(row: Int, to isVisible: Bool)
  {
    guard let structure, structure.bondSetController.arrangedObjects.indices.contains(row) else { return }
    structure.bondSetController.arrangedObjects[row].isVisible = isVisible
    markEdited()
    onChange?()
    reloadData()
  }

  private func fixAtom(_ asymmetricAtom: SKAsymmetricAtom, to isFixed: Bool3)
  {
    asymmetricAtom.isFixed = isFixed
    for copy in asymmetricAtom.copies
    {
      copy.asymmetricParentAtom.isFixed = isFixed
    }
    markEdited()
    // Length editability depends on the fixed state of both atoms.
    reloadData()
  }

  private func setBondType(row: Int, to bondType: SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>.SKBondType)
  {
    guard let structure, structure.bondSetController.arrangedObjects.indices.contains(row) else { return }
    structure.bondSetController.arrangedObjects[row].bondType = bondType
    markEdited()
    onChange?()
  }

  /// Move both atoms along the bond axis so the bond gets the requested
  /// length, then rebuild the affected bonds (mirrors Cocoa's
  /// changedBondLengthTextField/Slider + setBondAtomPositions).
  private func setBondLength(row: Int, to bondLength: Double)
  {
    guard let structure, let project, structure.bondSetController.arrangedObjects.indices.contains(row) else { return }
    let asymmetricBond = structure.bondSetController.arrangedObjects[row]
    guard let bond = asymmetricBond.copies.first else { return }

    guard let atom1 = bond.atom1.asymmetricParentAtom,
          let atom2 = bond.atom2.asymmetricParentAtom else { return }
    let newPos = structure.computeChangedBondLength(bond: bond, to: bondLength)

    atom1.position = newPos.0
    atom1.displacement = SIMD3<Double>(0.0, 0.0, 0.0)
    atom2.position = newPos.1
    atom2.displacement = SIMD3<Double>(0.0, 0.0, 0.0)
    structure.expandSymmetry(asymmetricAtom: atom1)
    structure.expandSymmetry(asymmetricAtom: atom2)
    structure.atomTreeController.tag()

    let newBonds = structure.bonds(subset: [atom1, atom2])
    structure.bondSetController.replaceBonds(atoms: [atom1, atom2], bonds: newBonds)
    structure.bondSetController.selectedObjects = structure.bondSetController.selectedAsymmetricBonds(atoms: [atom1, atom2], bonds: newBonds)
    structure.bondSetController.tag()

    structure.reComputeBoundingBox()
    project.renderCamera?.boundingBox = project.renderBoundingBox

    markEdited()
    onChange?()
    reloadData()
  }

  // MARK: Table view
  // =====================================================================

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    return structure?.bondSetController.arrangedObjects.count ?? 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCell(withIdentifier: "bondRow", for: indexPath) as! BondRowCell
    guard let structure, structure.bondSetController.arrangedObjects.indices.contains(indexPath.row) else { return cell }
    let row = indexPath.row
    let asymmetricBond = structure.bondSetController.arrangedObjects[row]
    let bondLength = asymmetricBond.copies.first.map { structure.bondLength($0) } ?? 0.0

    cell.configure(bond: asymmetricBond, id: row, bondLength: bondLength)

    cell.onVisibility = { [weak self] isVisible in self?.setBondVisibility(row: row, to: isVisible) }
    cell.onFixedAtom1 = { [weak self] isFixed in self?.fixAtom(asymmetricBond.atom1, to: isFixed) }
    cell.onFixedAtom2 = { [weak self] isFixed in self?.fixAtom(asymmetricBond.atom2, to: isFixed) }
    cell.onBondType = { [weak self] bondType in self?.setBondType(row: row, to: bondType) }
    cell.onBondLength = { [weak self] length in self?.setBondLength(row: row, to: length) }
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  {
    guard let structure else { return }
    structure.bondSetController.selectedObjects.insert(indexPath.row)
    updateBottomBar()
    onSelectionChange?()
  }

  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
  {
    guard let structure else { return }
    structure.bondSetController.selectedObjects.remove(indexPath.row)
    updateBottomBar()
    onSelectionChange?()
  }
}

// MARK: Row cell
// =====================================================================

private final class BondRowCell: UITableViewCell, UITextFieldDelegate
{
  var onVisibility: ((Bool) -> Void)?
  var onFixedAtom1: ((Bool3) -> Void)?
  var onFixedAtom2: ((Bool3) -> Void)?
  var onBondType: ((SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>.SKBondType) -> Void)?
  var onBondLength: ((Double) -> Void)?

  private typealias Columns = BondInspectorViewController.Columns

  private let visibilityButton = UIButton(type: .system)
  private let idLabel = UILabel()
  private let fix1Control = FixAtomControl()
  private let fix2Control = FixAtomControl()
  private let typeButton = UIButton(configuration: .gray())
  private let element1Label = UILabel()
  private let element2Label = UILabel()
  private let lengthField = UITextField()
  private let lengthSlider = UISlider()
  private var isVisibleState = false

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?)
  {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    buildLayout()
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  private func buildLayout()
  {
    selectionStyle = .default

    visibilityButton.widthAnchor.constraint(equalToConstant: Columns.checkbox).isActive = true
    visibilityButton.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.onVisibility?(!self.isVisibleState)
    }, for: .touchUpInside)

    idLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    idLabel.textAlignment = .center
    idLabel.widthAnchor.constraint(equalToConstant: Columns.id).isActive = true

    fix1Control.widthAnchor.constraint(equalToConstant: Columns.fix).isActive = true
    fix1Control.onChange = { [weak self] isFixed in self?.onFixedAtom1?(isFixed) }
    fix2Control.widthAnchor.constraint(equalToConstant: Columns.fix).isActive = true
    fix2Control.onChange = { [weak self] isFixed in self?.onFixedAtom2?(isFixed) }

    typeButton.configuration?.attributedTitle = AttributedString("Single", attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 12)]))
    typeButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
    typeButton.showsMenuAsPrimaryAction = true
    typeButton.widthAnchor.constraint(equalToConstant: Columns.type).isActive = true

    for label in [element1Label, element2Label]
    {
      label.font = .systemFont(ofSize: 12)
      label.textAlignment = .center
      label.widthAnchor.constraint(equalToConstant: Columns.element).isActive = true
    }

    lengthField.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    lengthField.borderStyle = .roundedRect
    lengthField.textAlignment = .right
    lengthField.keyboardType = .numbersAndPunctuation
    lengthField.autocorrectionType = .no
    lengthField.delegate = self
    lengthField.widthAnchor.constraint(equalToConstant: Columns.length).isActive = true
    lengthField.addAction(UIAction { [weak self] _ in
      guard let self, let value = Double(self.lengthField.text ?? "") else { return }
      self.onBondLength?(value)
    }, for: .editingDidEnd)

    lengthSlider.minimumValue = 0.5
    lengthSlider.maximumValue = 3.5
    lengthSlider.widthAnchor.constraint(equalToConstant: Columns.slider).isActive = true
    lengthSlider.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.lengthField.text = String(format: "%.5f", Double(self.lengthSlider.value))
    }, for: .valueChanged)
    // Apply once the drag ends, like Cocoa's endingDrag check.
    lengthSlider.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.onBondLength?(Double(self.lengthSlider.value))
    }, for: [.touchUpInside, .touchUpOutside])

    let stack = UIStackView(arrangedSubviews: [visibilityButton, idLabel, fix1Control, fix2Control,
                                               typeButton, element1Label, element2Label, lengthField, lengthSlider])
    stack.axis = .horizontal
    stack.spacing = Columns.spacing
    stack.alignment = .center
    stack.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      stack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -8)
    ])
  }

  func configure(bond: SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>, id: Int, bondLength: Double)
  {
    // Cocoa shows the checkbox off when the bond or either atom is hidden.
    isVisibleState = bond.isVisible && bond.atom1.isVisible && bond.atom2.isVisible
    visibilityButton.setImage(UIImage(systemName: isVisibleState ? "checkmark.square" : "square"), for: .normal)

    idLabel.text = "\(id)"

    fix1Control.configure(tag: bond.atom1.tag, isFixed: bond.atom1.isFixed)
    fix2Control.configure(tag: bond.atom2.tag, isFixed: bond.atom2.isFixed)

    let element1 = PredefinedElements.sharedInstance.elementSet[bond.atom1.elementIdentifier]
    let element2 = PredefinedElements.sharedInstance.elementSet[bond.atom2.elementIdentifier]
    element1Label.text = element1.chemicalSymbol
    element2Label.text = element2.chemicalSymbol

    // Double/partial-double need coordination 2, triple needs 3 (as Cocoa).
    let maxCoordination = min(element1.maximumUFFCoordination, element2.maximumUFFCoordination)
    let titles: [(String, SKAsymmetricBond<SKAsymmetricAtom, SKAsymmetricAtom>.SKBondType, Bool)] = [
      ("Single", .single, true),
      ("Double", .double, maxCoordination >= 2),
      ("Partial double", .partial_double, maxCoordination >= 2),
      ("Triple", .triple, maxCoordination >= 3)
    ]
    typeButton.menu = UIMenu(children: titles.map { title, bondType, enabled in
      UIAction(title: title, attributes: enabled ? [] : [.disabled],
               state: bond.bondType == bondType ? .on : .off) { [weak self] _ in
        self?.typeButton.configuration?.attributedTitle = AttributedString(title, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 12)]))
        self?.onBondType?(bondType)
      }
    })
    let currentTitle = titles.first(where: { $0.1 == bond.bondType })?.0 ?? "Single"
    typeButton.configuration?.attributedTitle = AttributedString(currentTitle, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 12)]))

    let allFixed = bond.atom1.isFixed.x && bond.atom1.isFixed.y && bond.atom1.isFixed.z
      && bond.atom2.isFixed.x && bond.atom2.isFixed.y && bond.atom2.isFixed.z
    lengthField.text = String(format: "%.5f", bondLength)
    lengthField.isEnabled = !allFixed
    lengthSlider.value = Float(bondLength)
    lengthSlider.isEnabled = !allFixed
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool
  {
    textField.resignFirstResponder()
    return true
  }

  override func prepareForReuse()
  {
    super.prepareForReuse()
    onVisibility = nil
    onFixedAtom1 = nil
    onFixedAtom2 = nil
    onBondType = nil
    onBondLength = nil
  }
}

/// Atom tag plus three x/y/z toggle segments — the iPad equivalent of Cocoa's
/// NSLabelSegmentedControl in the bond table.
private final class FixAtomControl: UIView
{
  var onChange: ((Bool3) -> Void)?

  private let tagLabel = UILabel()
  private var buttons: [UIButton] = []
  private var state = Bool3(false, false, false)

  override init(frame: CGRect)
  {
    super.init(frame: frame)

    tagLabel.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)
    tagLabel.textColor = .secondaryLabel
    tagLabel.textAlignment = .center
    tagLabel.widthAnchor.constraint(equalToConstant: 22).isActive = true

    let segmentStack = UIStackView()
    segmentStack.axis = .horizontal
    segmentStack.spacing = 1
    segmentStack.distribution = .fillEqually
    for (axis, title) in ["x", "y", "z"].enumerated()
    {
      var config = UIButton.Configuration.gray()
      config.attributedTitle = AttributedString(title, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 10, weight: .medium)]))
      config.contentInsets = NSDirectionalEdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0)
      config.cornerStyle = .fixed
      config.background.cornerRadius = 3
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
        case 0: self.state.x = button.isSelected
        case 1: self.state.y = button.isSelected
        default: self.state.z = button.isSelected
        }
        self.onChange?(self.state)
      }, for: .touchUpInside)
      buttons.append(button)
      segmentStack.addArrangedSubview(button)
    }

    let stack = UIStackView(arrangedSubviews: [tagLabel, segmentStack])
    stack.axis = .horizontal
    stack.spacing = 2
    stack.alignment = .center
    stack.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor),
      stack.topAnchor.constraint(equalTo: topAnchor),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(tag: Int, isFixed: Bool3)
  {
    tagLabel.text = "\(tag)"
    state = isFixed
    buttons[0].isSelected = isFixed.x
    buttons[1].isSelected = isFixed.y
    buttons[2].isSelected = isFixed.z
  }
}
