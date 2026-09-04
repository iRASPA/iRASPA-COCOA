import UIKit
import iRASPAKit
import SymmetryKit
import SimulationKit
import LogViewKit
import simd

/// Faithful iPad version of the Cocoa "Elements" detail view (StructureElementDetailViewController).
/// One card per force-field atom type with the same fields as the Cocoa row view, a +/− pair to
/// duplicate or delete atom types, and force-field / color set pickers at the bottom.
final class ElementInspectorViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
  let document: iRASPAUIDocument
  var onChange: (() -> Void)?

  private var project: ProjectStructureNode?
  private var selectedForceFieldSetIndex = 0
  private var selectedColorSetIndex = 0
  private var selectedRow: Int? = nil

  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private let addButton = UIButton(configuration: .gray())
  private let removeButton = UIButton(configuration: .gray())
  private let forceFieldButton = UIButton(configuration: .gray())
  private let colorSetButton = UIButton(configuration: .gray())

  init(document: iRASPAUIDocument)
  {
    self.document = document
    super.init(nibName: nil, bundle: nil)
    title = "Elements"
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground

    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(ElementTypeCell.self, forCellReuseIdentifier: "element")
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 320

    addButton.configuration?.image = UIImage(systemName: "plus")
    addButton.addAction(UIAction { [weak self] _ in self?.addForceFieldType() }, for: .touchUpInside)
    removeButton.configuration?.image = UIImage(systemName: "minus")
    removeButton.addAction(UIAction { [weak self] _ in self?.removeSelectedForceFieldType() }, for: .touchUpInside)

    forceFieldButton.showsMenuAsPrimaryAction = true
    colorSetButton.showsMenuAsPrimaryAction = true

    let forceFieldLabel = UILabel()
    forceFieldLabel.text = "Force field"
    forceFieldLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
    forceFieldLabel.textColor = .secondaryLabel
    let colorLabel = UILabel()
    colorLabel.text = "Color"
    colorLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
    colorLabel.textColor = .secondaryLabel

    let bottomBar = UIStackView(arrangedSubviews: [addButton, removeButton, UIView(),
                                                   forceFieldLabel, forceFieldButton,
                                                   colorLabel, colorSetButton])
    bottomBar.axis = .horizontal
    bottomBar.spacing = 8
    bottomBar.alignment = .center
    bottomBar.isLayoutMarginsRelativeArrangement = true
    bottomBar.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

    let barBackground = UIView()
    barBackground.backgroundColor = .secondarySystemGroupedBackground
    barBackground.addSubview(bottomBar)
    bottomBar.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(tableView)
    view.addSubview(barBackground)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    barBackground.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
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

    updateBottomBar()
  }

  func reload(from node: ProjectTreeNode, objects: [iRASPAObject])
  {
    project = node.representedObject.loadedProjectStructureNode
    selectedForceFieldSetIndex = min(selectedForceFieldSetIndex, max(0, document.forceFieldSets.count - 1))
    selectedColorSetIndex = min(selectedColorSetIndex, max(0, document.colorSets.count - 1))
    reloadData()
  }

  private func reloadData()
  {
    tableView.reloadData()
    updateBottomBar()
    restoreSelection()
  }

  private func restoreSelection()
  {
    if let selectedRow, selectedRow < currentForceFieldSet.atomTypeList.count
    {
      tableView.selectRow(at: IndexPath(row: selectedRow, section: 0), animated: false, scrollPosition: .none)
    }
  }

  private var currentForceFieldSet: SKForceFieldSet
  {
    return document.forceFieldSets[selectedForceFieldSetIndex]
  }

  private var currentColorSet: SKColorSet
  {
    return document.colorSets[selectedColorSetIndex]
  }

  // MARK: Bottom bar

  private func updateBottomBar()
  {
    forceFieldButton.configuration?.title = currentForceFieldSet.displayName
    colorSetButton.configuration?.title = currentColorSet.displayName
    forceFieldButton.menu = makeForceFieldMenu()
    colorSetButton.menu = makeColorSetMenu()
    let editable = currentForceFieldSet.editable
    addButton.isEnabled = editable && selectedRow != nil
    removeButton.isEnabled = editable && selectedRow != nil
  }

  private func makeForceFieldMenu() -> UIMenu
  {
    var actions: [UIMenuElement] = (0..<document.forceFieldSets.count).map { index in
      UIAction(title: self.document.forceFieldSets[index].displayName,
               state: index == self.selectedForceFieldSetIndex ? .on : .off) { [weak self] _ in
        self?.selectedForceFieldSetIndex = index
        self?.selectedRow = nil
        self?.reloadData()
      }
    }
    actions.append(UIAction(title: "New Force Field Set…", image: UIImage(systemName: "plus")) { [weak self] _ in
      self?.promptNewSetName(title: "New force field set", message: "Copied from the current set and editable.") { name in
        guard let self else { return }
        let set = SKForceFieldSet(name: name, forceFieldSet: self.currentForceFieldSet, editable: true)
        self.document.forceFieldSets.append(set)
        self.selectedForceFieldSetIndex = self.document.forceFieldSets.count - 1
        self.selectedRow = nil
        self.document.updateChangeCount(.done)
        self.reloadData()
      }
    })
    return UIMenu(children: actions)
  }

  private func makeColorSetMenu() -> UIMenu
  {
    var actions: [UIMenuElement] = (0..<document.colorSets.count).map { index in
      UIAction(title: self.document.colorSets[index].displayName,
               state: index == self.selectedColorSetIndex ? .on : .off) { [weak self] _ in
        self?.selectedColorSetIndex = index
        self?.reloadData()
      }
    }
    actions.append(UIAction(title: "New Color Set…", image: UIImage(systemName: "plus")) { [weak self] _ in
      self?.promptNewSetName(title: "New color set", message: "Copied from the current set and editable.") { name in
        guard let self else { return }
        let set = SKColorSet(name: name, from: self.currentColorSet, editable: true)
        self.document.colorSets.append(set)
        self.selectedColorSetIndex = self.document.colorSets.count - 1
        self.document.updateChangeCount(.done)
        self.reloadData()
      }
    })
    return UIMenu(children: actions)
  }

  private func promptNewSetName(title: String, message: String, apply: @escaping (String) -> Void)
  {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addTextField { $0.placeholder = "Name" }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addAction(UIAlertAction(title: "Create", style: .default) { _ in
      guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !name.isEmpty else { return }
      apply(name.capitalizeFirst)
    })
    present(alert, animated: true)
  }

  // MARK: Add / remove atom types

  private func addForceFieldType()
  {
    guard currentForceFieldSet.editable, let row = selectedRow,
          row < currentForceFieldSet.atomTypeList.count else { return }
    let forceFieldSet = currentForceFieldSet
    var forceFieldType = forceFieldSet.atomTypeList[row]
    let elementId = forceFieldType.atomicNumber
    let newUniqueName = forceFieldSet.uniqueName(for: elementId)
    forceFieldType.forceFieldStringIdentifier = newUniqueName
    forceFieldSet.insert(forceFieldType, at: row + 1)
    document.colorSets.insert(key: newUniqueName, element: elementId)
    selectedRow = row + 1
    document.updateChangeCount(.done)
    reloadData()
    LogQueue.shared.info(destination: nil, message: "Added force-field type \(newUniqueName)")
  }

  private func removeSelectedForceFieldType()
  {
    guard currentForceFieldSet.editable, let row = selectedRow,
          row < currentForceFieldSet.atomTypeList.count else { return }
    let forceFieldSet = currentForceFieldSet
    let uniqueName = forceFieldSet.atomTypeList[row].forceFieldStringIdentifier
    guard !SKForceFieldSet.isDefaultForceFieldType(uniqueForceFieldName: uniqueName) else {
      LogQueue.shared.warning(destination: nil, message: "Default types cannot be removed")
      return
    }
    forceFieldSet.remove(sortIndices: IndexSet(integer: row))
    if !document.forceFieldSets.contains(uniqueIdentifier: uniqueName)
    {
      document.colorSets.remove(key: uniqueName)
    }
    selectedRow = nil
    document.updateChangeCount(.done)
    reloadData()
    LogQueue.shared.info(destination: nil, message: "Removed force-field type \(uniqueName)")
  }

  // MARK: Apply changes to structures

  private func applyColorSchemeToStructures()
  {
    let structures = project?.allObjects.compactMap({ $0 as? Structure }) ?? []
    structures.forEach { $0.setRepresentationColorScheme(scheme: $0.atomColorSchemeIdentifier, colorSets: document.colorSets) }
    document.updateChangeCount(.done)
    onChange?()
  }

  private func applyForceFieldToStructures()
  {
    let structures = project?.allObjects.compactMap({ $0 as? Structure }) ?? []
    structures.forEach { $0.setRepresentationForceField(forceField: $0.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets) }
    document.updateChangeCount(.done)
    onChange?()
  }

  // MARK: Table view

  func numberOfSections(in tableView: UITableView) -> Int
  {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    return currentForceFieldSet.atomTypeList.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCell(withIdentifier: "element", for: indexPath) as! ElementTypeCell
    let row = indexPath.row
    let forceFieldSet = currentForceFieldSet
    let forceFieldType = forceFieldSet.atomTypeList[row]
    let uniqueName = forceFieldType.forceFieldStringIdentifier
    let element = PredefinedElements.sharedInstance.elementSet[forceFieldType.atomicNumber]
    let isDefault = SKForceFieldSet.isDefaultForceFieldType(uniqueForceFieldName: uniqueName)
    let editable = forceFieldSet.editable

    cell.configure(index: row,
                   type: forceFieldType,
                   element: element,
                   color: currentColorSet[uniqueName] ?? currentColorSet[element.chemicalSymbol] ?? .black,
                   setEditable: editable,
                   isDefaultType: isDefault,
                   colorEditable: currentColorSet.editable)

    cell.onVisibilityChange = { [weak self] isVisible in
      guard let self, self.currentForceFieldSet.editable else { return }
      self.currentForceFieldSet.atomTypeList[row].isVisible = isVisible
      self.document.updateChangeCount(.done)
      self.onChange?()
    }
    cell.onNameChange = { [weak self] newName in
      self?.renameForceFieldType(row: row, newName: newName)
    }
    cell.onAtomicNumberChange = { [weak self] number in
      guard let self, self.currentForceFieldSet.editable, !isDefault else { return }
      let highest = PredefinedElements.sharedInstance.elementSet.last?.atomicNumber ?? 118
      guard number > 0, number <= highest else { self.reloadData(); return }
      self.currentForceFieldSet.atomTypeList[row].atomicNumber = number
      self.document.updateChangeCount(.done)
      self.reloadData()
    }
    cell.onSymbolChange = { [weak self] symbol in
      guard let self, self.currentForceFieldSet.editable, !isDefault else { return }
      guard let atomicNumber = SKElement.atomicNumber(forSymbol: symbol) else { self.reloadData(); return }
      self.currentForceFieldSet.atomTypeList[row].atomicNumber = atomicNumber
      self.applyColorSchemeToStructures()
      self.reloadData()
    }
    cell.onMassChange = { [weak self] mass in
      guard let self, self.currentForceFieldSet.editable, !isDefault else { return }
      self.currentForceFieldSet.atomTypeList[row].mass = mass
      self.document.updateChangeCount(.done)
    }
    cell.onUserRadiusChange = { [weak self] radius in
      guard let self, self.currentForceFieldSet.editable else { return }
      self.currentForceFieldSet.atomTypeList[row].userDefinedRadius = radius
      self.applyForceFieldToStructures()
    }
    cell.onEpsilonChange = { [weak self] epsilon in
      guard let self, self.currentForceFieldSet.editable else { return }
      let sigma = self.currentForceFieldSet.atomTypeList[row].potentialParameters.y
      self.currentForceFieldSet.atomTypeList[row].potentialParameters = SIMD2<Double>(epsilon, sigma)
      self.applyForceFieldToStructures()
    }
    cell.onSigmaChange = { [weak self] sigma in
      guard let self, self.currentForceFieldSet.editable else { return }
      let epsilon = self.currentForceFieldSet.atomTypeList[row].potentialParameters.x
      self.currentForceFieldSet.atomTypeList[row].potentialParameters = SIMD2<Double>(epsilon, sigma)
      self.applyForceFieldToStructures()
    }
    cell.onChargeChange = { [weak self] charge in
      guard let self, self.currentForceFieldSet.editable else { return }
      self.currentForceFieldSet.atomTypeList[row].charge = charge
      self.applyForceFieldToStructures()
    }
    cell.onColorChange = { [weak self] color in
      guard let self, self.currentColorSet.editable else { return }
      self.document.colorSets[self.selectedColorSetIndex][uniqueName] = color
      self.applyColorSchemeToStructures()
    }
    return cell
  }

  private func renameForceFieldType(row: Int, newName: String)
  {
    let forceFieldSet = currentForceFieldSet
    guard forceFieldSet.editable, row < forceFieldSet.atomTypeList.count else { return }
    let oldName = forceFieldSet.atomTypeList[row].forceFieldStringIdentifier
    guard !SKForceFieldSet.isDefaultForceFieldType(uniqueForceFieldName: oldName) else { reloadData(); return }
    // The new identifier must be unique and may not shadow a default type.
    guard !newName.isEmpty,
          !forceFieldSet.atomTypeList.contains(where: { $0.forceFieldStringIdentifier == newName }),
          !SKForceFieldSet.isDefaultForceFieldType(uniqueForceFieldName: newName) else { reloadData(); return }
    document.colorSets.insert(key: newName, element: forceFieldSet.atomTypeList[row].atomicNumber)
    forceFieldSet.atomTypeList[row].forceFieldStringIdentifier = newName
    if !document.forceFieldSets.contains(uniqueIdentifier: oldName)
    {
      document.colorSets.remove(key: oldName)
    }
    document.updateChangeCount(.done)
    reloadData()
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  {
    selectedRow = indexPath.row
    updateBottomBar()
  }

  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
  {
    if selectedRow == indexPath.row { selectedRow = nil }
    updateBottomBar()
  }
}

/// One force-field atom type, laid out like the Cocoa "elementView" row:
/// header with index, symbol, name, visibility and color; below it two columns
/// with the element data, radii, and Lennard-Jones parameters.
private final class ElementTypeCell: UITableViewCell
{
  var onVisibilityChange: ((Bool) -> Void)?
  var onNameChange: ((String) -> Void)?
  var onAtomicNumberChange: ((Int) -> Void)?
  var onSymbolChange: ((String) -> Void)?
  var onMassChange: ((Double) -> Void)?
  var onUserRadiusChange: ((Double) -> Void)?
  var onEpsilonChange: ((Double) -> Void)?
  var onSigmaChange: ((Double) -> Void)?
  var onChargeChange: ((Double) -> Void)?
  var onColorChange: ((UIColor) -> Void)?

  private let indexLabel = UILabel()
  private let symbolLabel = UILabel()
  private let nameField = UITextField()
  private let visibilitySwitch = UISwitch()
  private let colorWell = UIColorWell()

  private let numberField = UITextField()
  private let elementField = UITextField()
  private let groupValue = UILabel()
  private let periodValue = UILabel()
  private let oxidationValue = UILabel()
  private let epsilonField = UITextField()
  private let sigmaField = UITextField()
  private let chargeField = UITextField()

  private let massField = UITextField()
  private let atomicRadiusValue = UILabel()
  private let covalentRadiusValue = UILabel()
  private let vdwRadiusValue = UILabel()
  private let tripleBondRadiusValue = UILabel()
  private let userRadiusField = UITextField()

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
    indexLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
    indexLabel.textColor = .secondaryLabel
    indexLabel.setContentHuggingPriority(.required, for: .horizontal)

    symbolLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
    symbolLabel.setContentHuggingPriority(.required, for: .horizontal)

    nameField.font = UIFont.preferredFont(forTextStyle: .headline)
    nameField.borderStyle = .roundedRect
    nameField.returnKeyType = .done
    nameField.autocapitalizationType = .none
    nameField.addAction(UIAction { action in
      (action.sender as? UITextField)?.resignFirstResponder()
    }, for: .editingDidEndOnExit)
    nameField.addAction(UIAction { [weak self] action in
      guard let field = action.sender as? UITextField else { return }
      self?.onNameChange?(field.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
    }, for: .editingDidEnd)

    let visibilityLabel = UILabel()
    visibilityLabel.text = "Atom Visibility"
    visibilityLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
    visibilityLabel.textColor = .secondaryLabel
    visibilitySwitch.addAction(UIAction { [weak self] action in
      guard let control = action.sender as? UISwitch else { return }
      self?.onVisibilityChange?(control.isOn)
    }, for: .valueChanged)

    colorWell.supportsAlpha = false
    colorWell.addAction(UIAction { [weak self] action in
      guard let well = action.sender as? UIColorWell, let color = well.selectedColor else { return }
      self?.onColorChange?(color)
    }, for: .valueChanged)

    let header = UIStackView(arrangedSubviews: [indexLabel, symbolLabel, nameField, UIView(),
                                                visibilityLabel, visibilitySwitch, colorWell])
    header.axis = .horizontal
    header.spacing = 10
    header.alignment = .center

    configureNumberField(numberField) { [weak self] text in
      if let value = Int(text) { self?.onAtomicNumberChange?(value) }
    }
    configureTextField(elementField) { [weak self] text in
      self?.onSymbolChange?(text)
    }
    configureNumberField(massField) { [weak self] text in
      if let value = Double(text) { self?.onMassChange?(value) }
    }
    configureNumberField(userRadiusField) { [weak self] text in
      if let value = Double(text) { self?.onUserRadiusChange?(value) }
    }
    configureNumberField(epsilonField) { [weak self] text in
      if let value = Double(text) { self?.onEpsilonChange?(value) }
    }
    configureNumberField(sigmaField) { [weak self] text in
      if let value = Double(text) { self?.onSigmaChange?(value) }
    }
    configureNumberField(chargeField) { [weak self] text in
      if let value = Double(text) { self?.onChargeChange?(value) }
    }

    let leftColumn = UIStackView(arrangedSubviews: [
      fieldRow("Number", control: numberField),
      fieldRow("Element", control: elementField),
      infoRow("Group", value: groupValue),
      infoRow("Period", value: periodValue),
      infoRow("Oxidation States", value: oxidationValue),
      fieldRow("Epsilon", control: epsilonField, unit: "K"),
      fieldRow("Sigma", control: sigmaField, unit: "Å"),
      fieldRow("Charge", control: chargeField, unit: "e")
    ])
    leftColumn.axis = .vertical
    leftColumn.spacing = 6

    let rightColumn = UIStackView(arrangedSubviews: [
      fieldRow("Atomic Mass", control: massField, unit: "amu"),
      infoRow("Atomic Radius", value: atomicRadiusValue, unit: "Å"),
      infoRow("Covalent Radius", value: covalentRadiusValue, unit: "Å"),
      infoRow("Van der Waals Radius", value: vdwRadiusValue, unit: "Å"),
      infoRow("Triple Bond Covalent Radius", value: tripleBondRadiusValue, unit: "Å"),
      fieldRow("User-defined Radius", control: userRadiusField, unit: "Å")
    ])
    rightColumn.axis = .vertical
    rightColumn.spacing = 6

    let columns = UIStackView(arrangedSubviews: [leftColumn, rightColumn])
    columns.axis = .horizontal
    columns.spacing = 20
    columns.distribution = .fillEqually
    columns.alignment = .top

    let content = UIStackView(arrangedSubviews: [header, columns])
    content.axis = .vertical
    content.spacing = 12
    content.isLayoutMarginsRelativeArrangement = true
    content.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

    contentView.addSubview(content)
    content.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      content.topAnchor.constraint(equalTo: contentView.topAnchor),
      content.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      content.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      content.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
    ])
  }

  private func configureNumberField(_ field: UITextField, apply: @escaping (String) -> Void)
  {
    field.keyboardType = .numbersAndPunctuation
    configureTextField(field, apply: apply)
  }

  private func configureTextField(_ field: UITextField, apply: @escaping (String) -> Void)
  {
    field.borderStyle = .roundedRect
    field.font = UIFont.preferredFont(forTextStyle: .footnote)
    field.textAlignment = .right
    field.returnKeyType = .done
    field.autocapitalizationType = .none
    field.addAction(UIAction { action in
      (action.sender as? UITextField)?.resignFirstResponder()
    }, for: .editingDidEndOnExit)
    field.addAction(UIAction { action in
      guard let field = action.sender as? UITextField else { return }
      apply(field.text ?? "")
    }, for: .editingDidEnd)
  }

  private func rowLabel(_ title: String) -> UILabel
  {
    let label = UILabel()
    label.text = title
    label.font = UIFont.preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.adjustsFontSizeToFitWidth = true
    label.minimumScaleFactor = 0.7
    return label
  }

  private func unitLabel(_ unit: String?) -> UILabel?
  {
    guard let unit else { return nil }
    let label = UILabel()
    label.text = unit
    label.font = UIFont.preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.setContentHuggingPriority(.required, for: .horizontal)
    return label
  }

  private func fieldRow(_ title: String, control: UITextField, unit: String? = nil) -> UIStackView
  {
    control.widthAnchor.constraint(equalToConstant: 82).isActive = true
    var views: [UIView] = [rowLabel(title), control]
    if let unit = unitLabel(unit) { views.append(unit) }
    let row = UIStackView(arrangedSubviews: views)
    row.axis = .horizontal
    row.spacing = 6
    row.alignment = .center
    return row
  }

  private func infoRow(_ title: String, value: UILabel, unit: String? = nil) -> UIStackView
  {
    value.font = UIFont.preferredFont(forTextStyle: .footnote)
    value.textAlignment = .right
    value.adjustsFontSizeToFitWidth = true
    value.minimumScaleFactor = 0.7
    var views: [UIView] = [rowLabel(title), value]
    if let unit = unitLabel(unit) { views.append(unit) }
    let row = UIStackView(arrangedSubviews: views)
    row.axis = .horizontal
    row.spacing = 6
    row.alignment = .center
    return row
  }

  func configure(index: Int, type: SKForceFieldType, element: SKElement, color: UIColor,
                 setEditable: Bool, isDefaultType: Bool, colorEditable: Bool)
  {
    let typeEditable = setEditable && !isDefaultType

    indexLabel.text = String(index)
    symbolLabel.text = element.chemicalSymbol
    nameField.text = type.forceFieldStringIdentifier
    nameField.isEnabled = typeEditable

    visibilitySwitch.isOn = type.isVisible
    visibilitySwitch.isEnabled = setEditable
    colorWell.selectedColor = color
    colorWell.isEnabled = colorEditable

    numberField.text = String(element.atomicNumber)
    numberField.isEnabled = typeEditable
    elementField.text = element.chemicalSymbol
    elementField.isEnabled = typeEditable
    groupValue.text = String(element.group)
    periodValue.text = String(element.period)
    oxidationValue.text = element.possibleOxidationStates.map { String($0) }.joined(separator: ",")

    massField.text = String(format: "%.6f", type.mass)
    massField.isEnabled = typeEditable
    atomicRadiusValue.text = String(format: "%.4f", element.atomRadius)
    covalentRadiusValue.text = String(format: "%.4f", element.covalentRadius)
    vdwRadiusValue.text = String(format: "%.4f", element.VDWRadius)
    tripleBondRadiusValue.text = String(format: "%.4f", element.tripleBondCovalentRadius)
    userRadiusField.text = String(format: "%.4f", type.userDefinedRadius)
    userRadiusField.isEnabled = setEditable

    epsilonField.text = String(format: "%.5f", type.potentialParameters.x)
    epsilonField.isEnabled = setEditable
    sigmaField.text = String(format: "%.5f", type.potentialParameters.y)
    sigmaField.isEnabled = setEditable
    chargeField.text = String(format: "%.4f", type.charge)
    chargeField.isEnabled = setEditable
  }

  override func prepareForReuse()
  {
    super.prepareForReuse()
    onVisibilityChange = nil
    onNameChange = nil
    onAtomicNumberChange = nil
    onSymbolChange = nil
    onMassChange = nil
    onUserRadiusChange = nil
    onEpsilonChange = nil
    onSigmaChange = nil
    onChargeChange = nil
    onColorChange = nil
  }
}
