import UIKit
import iRASPAKit
import SymmetryKit

/// Faithful iPad version of the Cocoa "Info" detail view (StructureInfoDetailViewController).
/// Static group headers mirror the Cocoa outline root nodes: Creator, Creation,
/// Chemical Information, and Citation. All fields are editable and apply to every
/// selected object that supports info editing.
final class InfoInspectorViewController: CollapsibleTableViewController
{
  let document: iRASPAUIDocument
  private var selectedObjects: [iRASPAObject] = []

  private enum Section: Int, CaseIterable
  {
    case creator = 0
    case creation
    case creationMethods
    case chemical
    case citation
  }

  // Menu and combo presets copied from the Cocoa storyboard.
  private let temperatureScales = ["Kelvin", "Celsius"]
  private let pressureScales = ["Pascal", "Bar"]
  private let creationMethods = ["Unknown", "Simulation", "Experimental"]
  private let unitCellRelaxationMethods = [
    "Unknown", "Cell and Edge-Lengths Free", "Fixed Angles; Isotropic Edge-Length Free",
    "Fixed Angles; Anisotropic Edge-Length Free", "Fixed 𝝰- 𝝱; and 𝝲-Angles; Edge-Lengths Free",
    "Fixed Volume; Shape Free", "Fixed Cell"
  ]
  private let ionsRelaxationAlgorithms = [
    "Unknown", "None", "Simplex", "Simulated Annealing", "Genetic Algorithm",
    "Steepest Descent", "Conjugate Gradient", "Quasi-Newton", "Newton-Raphson", "Baker's Algorithm"
  ]
  private let ionsRelaxationChecks = [
    "Unknown", "None", "All positive", "Some Small Negative Values",
    "Some Signficantly Negative Values", "Many Negative Eigenvalues"
  ]
  private let positionsSoftwarePresets = ["Experimental", "Gaussian", "VASP", "Spartan", "CP2K", "Classical"]
  private let forceFieldPresets = ["Ab Initio", "UFF", "DREIDING", "MM3", "MM4"]
  private let forceFieldDetailPresets = ["PBE, 600 ev cutoff, Gamma point only"]
  private let chargesSoftwarePresets = [
    "Experimental", "Ab initio", "VASP", "Gaussian", "Spartan", "CP2K", "DMOL3", "TURBOMOLE",
    "SIESTA", "NWCHEM", "ORCA", "ADF", "WIEN2K", "Classical", "RASPA", "Materials Studio", "GULP", "Openbabel"
  ]
  private let chargeAlgorithmPresets = [
    "REPEAT", "CHELPG", "CHELP", "RESP", "Mulliken", "Merz-Kollman", "Hirshfeld",
    "Natural Bond Orbital", "Qeq - Rappe and Goddard 1991", "Qeq - Rick, Stuart, Berne 1994",
    "Qeq - York and Yang 1996", "Qeq - Itskoqitz and Berkowitz 1997", "Qeq - Wilmer, Kim, Snurr 2012"
  ]
  private let journalPresets = [
    "Journal of the American Chemical Society", "Angewandte Chemie Int. Ed.", "Journal of the Physical Chemistry"
  ]
  private lazy var countryNames: [String] = {
    let locale = Locale.current
    return Array(Set(Locale.isoRegionCodes.compactMap { locale.localizedString(forRegionCode: $0) })).sorted()
  }()

  init(document: iRASPAUIDocument)
  {
    self.document = document
    super.init(style: .insetGrouped)
    title = "Info"
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  func reload(from node: ProjectTreeNode, objects: [iRASPAObject])
  {
    selectedObjects = objects
    tableView.reloadData()
  }

  private func infoEditors() -> [InfoEditor]
  {
    return selectedObjects.compactMap({ $0.object as? InfoEditor })
  }

  private var firstEditor: InfoEditor?
  {
    return infoEditors().first
  }

  private func apply(_ change: (InfoEditor) -> Void)
  {
    infoEditors().forEach(change)
    document.updateChangeCount(.done)
  }

  // MARK: Table structure

  override func inspectorSectionCount() -> Int
  {
    return Section.allCases.count
  }

  override func inspectorGroupHeader(_ section: Int) -> String?
  {
    // Static root-node titles from the Cocoa Info outline view.
    switch Section(rawValue: section)
    {
    case .creator: return "Creator"
    case .creation: return "Creation"
    case .chemical: return "Chemical Information"
    case .citation: return "Citation"
    default: return nil
    }
  }

  override func inspectorSectionTitle(_ section: Int) -> String
  {
    guard firstEditor != nil, let section = Section(rawValue: section) else { return "" }
    switch section
    {
    case .creator: return "Author"
    case .creation: return "Conditions"
    case .creationMethods: return "Method Details"
    case .chemical: return "Formula"
    case .citation: return "Article"
    }
  }

  override func inspectorFooterTitle(_ section: Int) -> String?
  {
    if Section(rawValue: section) == .creator
    {
      if selectedObjects.isEmpty { return "Select a project, movie, or frame to edit." }
      if selectedObjects.count == 1 { return "Editing \(selectedObjects[0].object.displayName)" }
      return "Editing \(selectedObjects.count) selected structures"
    }
    return nil
  }

  override func inspectorRowCount(in section: Int) -> Int
  {
    guard let editor = firstEditor, let section = Section(rawValue: section) else { return 0 }
    switch section
    {
    case .creator: return 10
    case .creation: return 6
    case .creationMethods:
      // Simulation shows 10 model rows, experimental 13; both share 3 refinement-quality rows.
      return editor.creationMethod == .experimental ? 16 : 13
    case .chemical: return 3
    case .citation: return 8
    }
  }

  override func inspectorCell(for indexPath: IndexPath) -> UITableViewCell
  {
    switch Section(rawValue: indexPath.section)
    {
    case .creator: return creatorCell(row: indexPath.row)
    case .creation: return creationCell(row: indexPath.row)
    case .creationMethods: return creationMethodsCell(row: indexPath.row)
    case .chemical: return chemicalCell(row: indexPath.row)
    case .citation: return citationCell(row: indexPath.row)
    default: return UITableViewCell()
    }
  }

  // MARK: Creator

  private func creatorCell(row: Int) -> UITableViewCell
  {
    let editor = firstEditor
    switch row
    {
    case 0:
      return textRow("First name", value: editor?.authorFirstName) { [weak self] value in
        self?.apply { $0.authorFirstName = value }
      }
    case 1:
      return textRow("Middle name", value: editor?.authorMiddleName) { [weak self] value in
        self?.apply { $0.authorMiddleName = value }
      }
    case 2:
      return textRow("Last name", value: editor?.authorLastName) { [weak self] value in
        self?.apply { $0.authorLastName = value }
      }
    case 3:
      return textRow("ORCID", value: editor?.authorOrchidID) { [weak self] value in
        self?.apply { $0.authorOrchidID = value }
      }
    case 4:
      return textRow("Researcher ID", value: editor?.authorResearcherID) { [weak self] value in
        self?.apply { $0.authorResearcherID = value }
      }
    case 5:
      return textRow("University", value: editor?.authorAffiliationUniversityName) { [weak self] value in
        self?.apply { $0.authorAffiliationUniversityName = value }
      }
    case 6:
      return textRow("Faculty", value: editor?.authorAffiliationFacultyName) { [weak self] value in
        self?.apply { $0.authorAffiliationFacultyName = value }
      }
    case 7:
      return textRow("Institute", value: editor?.authorAffiliationInstituteName) { [weak self] value in
        self?.apply { $0.authorAffiliationInstituteName = value }
      }
    case 8:
      return textRow("City", value: editor?.authorAffiliationCityName) { [weak self] value in
        self?.apply { $0.authorAffiliationCityName = value }
      }
    default:
      let selectedIndex = countryNames.firstIndex(of: editor?.authorAffiliationCountryName ?? "")
      return menuRow("Country", options: countryNames, selectedIndex: selectedIndex) { [weak self] index in
        guard let self else { return }
        self.apply { $0.authorAffiliationCountryName = self.countryNames[index] }
      }
    }
  }

  // MARK: Creation conditions

  private func creationCell(row: Int) -> UITableViewCell
  {
    let editor = firstEditor
    switch row
    {
    case 0:
      return dateRow("Creation date", date: editor?.creationDate ?? Date()) { [weak self] date in
        self?.apply { $0.creationDate = date }
      }
    case 1:
      return textRow("Temperature", value: editor?.creationTemperature) { [weak self] value in
        self?.apply { $0.creationTemperature = value }
      }
    case 2:
      let selectedIndex = editor?.creationTemperatureScale.rawValue
      return menuRow("Temperature scale", options: temperatureScales, selectedIndex: selectedIndex) { [weak self] index in
        guard let scale = Structure.TemperatureScale(rawValue: index) else { return }
        self?.apply { $0.creationTemperatureScale = scale }
      }
    case 3:
      return textRow("Pressure", value: editor?.creationPressure) { [weak self] value in
        self?.apply { $0.creationPressure = value }
      }
    case 4:
      let selectedIndex = editor?.creationPressureScale.rawValue
      return menuRow("Pressure scale", options: pressureScales, selectedIndex: selectedIndex) { [weak self] index in
        guard let scale = Structure.PressureScale(rawValue: index) else { return }
        self?.apply { $0.creationPressureScale = scale }
      }
    default:
      let selectedIndex = editor?.creationMethod.rawValue
      return menuRow("Method", options: creationMethods, selectedIndex: selectedIndex) { [weak self] index in
        guard let method = Structure.CreationMethod(rawValue: index) else { return }
        self?.apply { $0.creationMethod = method }
      }
    }
  }

  // MARK: Creation method details

  private func creationMethodsCell(row: Int) -> UITableViewCell
  {
    guard let editor = firstEditor else { return UITableViewCell() }
    if editor.creationMethod == .experimental
    {
      return experimentalCell(row: row)
    }
    return simulationCell(row: row)
  }

  private func simulationCell(row: Int) -> UITableViewCell
  {
    let editor = firstEditor
    switch row
    {
    case 0:
      let selectedIndex = editor?.creationUnitCellRelaxationMethod.rawValue
      return menuRow("Unit-cell relaxation", options: unitCellRelaxationMethods, selectedIndex: selectedIndex) { [weak self] index in
        guard let method = Structure.UnitCellRelaxationMethod(rawValue: index) else { return }
        self?.apply { $0.creationUnitCellRelaxationMethod = method }
      }
    case 1:
      return comboRow("Positions software", options: positionsSoftwarePresets, value: editor?.creationAtomicPositionsSoftwarePackage) { [weak self] value in
        self?.apply { $0.creationAtomicPositionsSoftwarePackage = value }
      }
    case 2:
      let selectedIndex = editor?.creationAtomicPositionsIonsRelaxationAlgorithm.rawValue
      return menuRow("Ions relaxation algorithm", options: ionsRelaxationAlgorithms, selectedIndex: selectedIndex) { [weak self] index in
        guard let algorithm = Structure.IonsRelaxationAlgorithm(rawValue: index) else { return }
        self?.apply { $0.creationAtomicPositionsIonsRelaxationAlgorithm = algorithm }
      }
    case 3:
      let selectedIndex = editor?.creationAtomicPositionsIonsRelaxationCheck.rawValue
      return menuRow("Ions relaxation check", options: ionsRelaxationChecks, selectedIndex: selectedIndex) { [weak self] index in
        guard let check = Structure.IonsRelaxationCheck(rawValue: index) else { return }
        self?.apply { $0.creationAtomicPositionsIonsRelaxationCheck = check }
      }
    case 4:
      return comboRow("Positions force field", options: forceFieldPresets, value: editor?.creationAtomicPositionsForcefield) { [weak self] value in
        self?.apply { $0.creationAtomicPositionsForcefield = value }
      }
    case 5:
      return comboRow("Positions force field details", options: forceFieldDetailPresets, value: editor?.creationAtomicPositionsForcefieldDetails) { [weak self] value in
        self?.apply { $0.creationAtomicPositionsForcefieldDetails = value }
      }
    case 6:
      return comboRow("Charges software", options: chargesSoftwarePresets, value: editor?.creationAtomicChargesSoftwarePackage) { [weak self] value in
        self?.apply { $0.creationAtomicChargesSoftwarePackage = value }
      }
    case 7:
      return comboRow("Charges algorithm", options: chargeAlgorithmPresets, value: editor?.creationAtomicChargesAlgorithms) { [weak self] value in
        self?.apply { $0.creationAtomicChargesAlgorithms = value }
      }
    case 8:
      return comboRow("Charges force field", options: forceFieldPresets, value: editor?.creationAtomicChargesForcefield) { [weak self] value in
        self?.apply { $0.creationAtomicChargesForcefield = value }
      }
    case 9:
      return comboRow("Charges force field details", options: forceFieldDetailPresets, value: editor?.creationAtomicChargesForcefieldDetails) { [weak self] value in
        self?.apply { $0.creationAtomicChargesForcefieldDetails = value }
      }
    default:
      return refinementQualityCell(row: row - 10)
    }
  }

  private func experimentalCell(row: Int) -> UITableViewCell
  {
    let editor = firstEditor
    switch row
    {
    case 0:
      return textRow("Radiation", value: editor?.experimentalMeasurementRadiation) { [weak self] value in
        self?.apply { $0.experimentalMeasurementRadiation = value }
      }
    case 1:
      return textRow("Wavelength", value: editor?.experimentalMeasurementWaveLength) { [weak self] value in
        self?.apply { $0.experimentalMeasurementWaveLength = value }
      }
    case 2:
      return textRow("θ min (°)", value: editor?.experimentalMeasurementThetaMin) { [weak self] value in
        self?.apply { $0.experimentalMeasurementThetaMin = value }
      }
    case 3:
      return textRow("θ max (°)", value: editor?.experimentalMeasurementThetaMax) { [weak self] value in
        self?.apply { $0.experimentalMeasurementThetaMax = value }
      }
    case 4:
      return textRow("Index limit h min", value: editor?.experimentalMeasurementIndexLimitsHmin) { [weak self] value in
        self?.apply { $0.experimentalMeasurementIndexLimitsHmin = value }
      }
    case 5:
      return textRow("Index limit h max", value: editor?.experimentalMeasurementIndexLimitsHmax) { [weak self] value in
        self?.apply { $0.experimentalMeasurementIndexLimitsHmax = value }
      }
    case 6:
      return textRow("Index limit k min", value: editor?.experimentalMeasurementIndexLimitsKmin) { [weak self] value in
        self?.apply { $0.experimentalMeasurementIndexLimitsKmin = value }
      }
    case 7:
      return textRow("Index limit k max", value: editor?.experimentalMeasurementIndexLimitsKmax) { [weak self] value in
        self?.apply { $0.experimentalMeasurementIndexLimitsKmax = value }
      }
    case 8:
      return textRow("Index limit l min", value: editor?.experimentalMeasurementIndexLimitsLmin) { [weak self] value in
        self?.apply { $0.experimentalMeasurementIndexLimitsLmin = value }
      }
    case 9:
      return textRow("Index limit l max", value: editor?.experimentalMeasurementIndexLimitsLmax) { [weak self] value in
        self?.apply { $0.experimentalMeasurementIndexLimitsLmax = value }
      }
    case 10:
      return textRow("Independent reflections", value: editor?.experimentalMeasurementNumberOfSymmetryIndependentReflections) { [weak self] value in
        self?.apply { $0.experimentalMeasurementNumberOfSymmetryIndependentReflections = value }
      }
    case 11:
      return textRow("Software", value: editor?.experimentalMeasurementSoftware) { [weak self] value in
        self?.apply { $0.experimentalMeasurementSoftware = value }
      }
    case 12:
      return textRow("Refinement details", value: editor?.experimentalMeasurementRefinementDetails) { [weak self] value in
        self?.apply { $0.experimentalMeasurementRefinementDetails = value }
      }
    default:
      return refinementQualityCell(row: row - 13)
    }
  }

  private func refinementQualityCell(row: Int) -> UITableViewCell
  {
    let editor = firstEditor
    switch row
    {
    case 0:
      return textRow("Goodness of fit", value: editor?.experimentalMeasurementGoodnessOfFit) { [weak self] value in
        self?.apply { $0.experimentalMeasurementGoodnessOfFit = value }
      }
    case 1:
      return textRow("R-factor (gt)", value: editor?.experimentalMeasurementRFactorGt) { [weak self] value in
        self?.apply { $0.experimentalMeasurementRFactorGt = value }
      }
    default:
      return textRow("R-factor (all)", value: editor?.experimentalMeasurementRFactorAll) { [weak self] value in
        self?.apply { $0.experimentalMeasurementRFactorAll = value }
      }
    }
  }

  // MARK: Chemical

  private func chemicalCell(row: Int) -> UITableViewCell
  {
    let editor = firstEditor
    switch row
    {
    case 0:
      return textRow("Chemical formula moiety", value: editor?.chemicalFormulaMoiety) { [weak self] value in
        self?.apply { $0.chemicalFormulaMoiety = value }
      }
    case 1:
      return textRow("Chemical formula sum", value: editor?.chemicalFormulaSum) { [weak self] value in
        self?.apply { $0.chemicalFormulaSum = value }
      }
    default:
      return textRow("Chemical name systematic", value: editor?.chemicalNameSystematic) { [weak self] value in
        self?.apply { $0.chemicalNameSystematic = value }
      }
    }
  }

  // MARK: Citation

  private func citationCell(row: Int) -> UITableViewCell
  {
    let editor = firstEditor
    switch row
    {
    case 0:
      return textRow("Article title", value: editor?.citationArticleTitle) { [weak self] value in
        self?.apply { $0.citationArticleTitle = value }
      }
    case 1:
      return comboRow("Journal", options: journalPresets, value: editor?.citationJournalTitle) { [weak self] value in
        self?.apply { $0.citationJournalTitle = value }
      }
    case 2:
      return textRow("Article authors", value: editor?.citationAuthors) { [weak self] value in
        self?.apply { $0.citationAuthors = value }
      }
    case 3:
      return textRow("Volume", value: editor?.citationJournalVolume) { [weak self] value in
        self?.apply { $0.citationJournalVolume = value }
      }
    case 4:
      return textRow("Number", value: editor?.citationJournalNumber) { [weak self] value in
        self?.apply { $0.citationJournalNumber = value }
      }
    case 5:
      return dateRow("Publication date", date: editor?.citationPublicationDate ?? Date()) { [weak self] date in
        self?.apply { $0.citationPublicationDate = date }
      }
    case 6:
      return textRow("DOI", value: editor?.citationDOI) { [weak self] value in
        self?.apply { $0.citationDOI = value }
      }
    default:
      return textRow("Database codes", value: editor?.citationDatebaseCodes) { [weak self] value in
        self?.apply { $0.citationDatebaseCodes = value }
      }
    }
  }

  // MARK: Row factories

  private func textRow(_ title: String, value: String?, apply: @escaping (String) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    let field = UITextField(frame: CGRect(x: 0, y: 0, width: 180, height: 30))
    field.borderStyle = .roundedRect
    field.font = UIFont.preferredFont(forTextStyle: .footnote)
    field.textAlignment = .right
    field.returnKeyType = .done
    field.autocapitalizationType = .none
    field.text = value ?? ""
    field.addAction(UIAction { action in
      (action.sender as? UITextField)?.resignFirstResponder()
    }, for: .editingDidEndOnExit)
    field.addAction(UIAction { action in
      guard let field = action.sender as? UITextField else { return }
      apply(field.text ?? "")
    }, for: .editingDidEnd)
    cell.accessoryView = field
    return cell
  }

  private func dateRow(_ title: String, date: Date, apply: @escaping (Date) -> Void) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    let picker = UIDatePicker()
    picker.datePickerMode = .date
    picker.preferredDatePickerStyle = .compact
    picker.date = date
    picker.addAction(UIAction { action in
      guard let picker = action.sender as? UIDatePicker else { return }
      apply(picker.date)
    }, for: .valueChanged)
    picker.sizeToFit()
    cell.accessoryView = picker
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
    // Long lists (countries) are split into submenus.
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

  /// Cocoa combo-box equivalent: preset menu plus a "Custom…" entry for free text.
  private func comboRow(_ title: String, options: [String], value: String?, apply: @escaping (String) -> Void) -> UITableViewCell
  {
    var options = options
    if let value, !value.isEmpty, !options.contains(value)
    {
      options.insert(value, at: 0)
    }
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = title
    var config = UIButton.Configuration.gray()
    config.buttonSize = .small
    config.title = (value?.isEmpty ?? true) ? "—" : value
    let button = UIButton(configuration: config)
    var actions: [UIMenuElement] = options.map { option in
      UIAction(title: option, state: option == value ? .on : .off) { [weak self] _ in
        apply(option)
        self?.tableView.reloadData()
      }
    }
    actions.append(UIAction(title: "Custom…", image: UIImage(systemName: "square.and.pencil")) { [weak self] _ in
      self?.presentCustomValueAlert(title: title, current: value) { text in
        apply(text)
        self?.tableView.reloadData()
      }
    })
    button.menu = UIMenu(options: .singleSelection, children: actions)
    button.showsMenuAsPrimaryAction = true
    button.sizeToFit()
    var frame = button.frame
    frame.size.width = Swift.min(Swift.max(frame.size.width, 100), 200)
    button.frame = frame
    cell.accessoryView = button
    return cell
  }

  private func presentCustomValueAlert(title: String, current: String?, apply: @escaping (String) -> Void)
  {
    let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
    alert.addTextField { field in
      field.text = current
      field.autocapitalizationType = .none
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addAction(UIAlertAction(title: "Set", style: .default) { _ in
      apply(alert.textFields?.first?.text ?? "")
    })
    present(alert, animated: true)
  }
}
