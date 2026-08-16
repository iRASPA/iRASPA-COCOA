import UIKit
import iRASPAKit
import SymmetryKit
import simd

final class AtomDetailViewController: UITableViewController
{
  private let atom: SKAsymmetricAtom
  private let copy: SKAtomCopy?
  private let structureName: String
  private let cell: SKCell?
  var onChange: (() -> Void)?

  init(atom: SKAsymmetricAtom, copy: SKAtomCopy?, structureName: String, cell: SKCell?)
  {
    self.atom = atom
    self.copy = copy
    self.structureName = structureName
    self.cell = cell
    super.init(style: .insetGrouped)
    title = atom.displayName
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
  }

  @objc private func close()
  {
    dismiss(animated: true)
  }

  override func numberOfSections(in tableView: UITableView) -> Int { return 5 }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
  {
    switch section
    {
    case 0: return "Atom"
    case 1: return "Cartesian (Å)"
    case 2: return "Fractional"
    case 3: return "Color"
    default: return "Visibility"
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    switch section
    {
    case 0: return 6
    case 1: return 3
    case 2: return 3
    case 3: return 1
    default: return 1
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    if indexPath.section == 0
    {
      switch indexPath.row
      {
      case 0:
        cell.textLabel?.text = "Label"
        cell.detailTextLabel?.text = atom.displayName
      case 1:
        cell.textLabel?.text = "Element"
        let symbol: String
        let index = atom.elementIdentifier
        if index >= 0, index < PredefinedElements.sharedInstance.elementSet.count
        {
          symbol = PredefinedElements.sharedInstance.elementSet[index].chemicalSymbol
        }
        else
        {
          symbol = "—"
        }
        cell.detailTextLabel?.text = symbol
      case 2:
        cell.textLabel?.text = "Structure"
        cell.detailTextLabel?.text = structureName
      case 3:
        cell.textLabel?.text = "Force field"
        cell.detailTextLabel?.text = atom.uniqueForceFieldName
      case 4:
        cell.textLabel?.text = "Occupancy"
        cell.detailTextLabel?.text = String(format: "%.3f", atom.occupancy)
        cell.accessoryType = .disclosureIndicator
      default:
        cell.textLabel?.text = "Charge"
        cell.detailTextLabel?.text = String(format: "%.3f", atom.charge)
        cell.accessoryType = .disclosureIndicator
      }
      return cell
    }
    if indexPath.section == 1
    {
      let position = copy?.position ?? cartesianPosition()
      switch indexPath.row
      {
      case 0:
        cell.textLabel?.text = "x"
        cell.detailTextLabel?.text = String(format: "%.4f", position.x)
      case 1:
        cell.textLabel?.text = "y"
        cell.detailTextLabel?.text = String(format: "%.4f", position.y)
      default:
        cell.textLabel?.text = "z"
        cell.detailTextLabel?.text = String(format: "%.4f", position.z)
      }
      return cell
    }
    if indexPath.section == 2
    {
      let position = fractionalPosition()
      switch indexPath.row
      {
      case 0:
        cell.textLabel?.text = "x"
        cell.detailTextLabel?.text = String(format: "%.5f", position.x)
      case 1:
        cell.textLabel?.text = "y"
        cell.detailTextLabel?.text = String(format: "%.5f", position.y)
      default:
        cell.textLabel?.text = "z"
        cell.detailTextLabel?.text = String(format: "%.5f", position.z)
      }
      return cell
    }
    if indexPath.section == 3
    {
      cell.textLabel?.text = "Color"
      let well = UIColorWell()
      well.selectedColor = atom.color
      well.supportsAlpha = false
      well.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
      cell.accessoryView = well.inspectorAccessory()
      return cell
    }
    cell.textLabel?.text = "Visible"
    let control = UISwitch()
    control.isOn = atom.isVisible
    control.addTarget(self, action: #selector(visibilityChanged(_:)), for: .valueChanged)
    cell.accessoryView = control
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  {
    tableView.deselectRow(at: indexPath, animated: true)
    guard indexPath.section == 0 else { return }
    if indexPath.row == 4
    {
      editNumber(title: "Occupancy", value: atom.occupancy) { [weak self] value in
        self?.atom.occupancy = value
        self?.onChange?()
        self?.tableView.reloadData()
      }
    }
    else if indexPath.row == 5
    {
      editNumber(title: "Charge", value: atom.charge) { [weak self] value in
        self?.atom.charge = value
        self?.onChange?()
        self?.tableView.reloadData()
      }
    }
  }

  private func cartesianPosition() -> SIMD3<Double>
  {
    if let copy { return copy.position }
    if atom.fractional, let cell
    {
      return cell.convertToCartesian(atom.position)
    }
    return atom.position
  }

  private func fractionalPosition() -> SIMD3<Double>
  {
    if atom.fractional { return atom.position }
    if let cell { return cell.convertToFractional(copy?.position ?? atom.position) }
    return atom.position
  }

  private func editNumber(title: String, value: Double, apply: @escaping (Double) -> Void)
  {
    let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
    alert.addTextField { field in
      field.keyboardType = .decimalPad
      field.text = String(format: "%.4f", value)
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addAction(UIAlertAction(title: "Set", style: .default) { _ in
      guard let text = alert.textFields?.first?.text, let number = Double(text) else { return }
      apply(number)
    })
    present(alert, animated: true)
  }

  @objc private func colorChanged(_ sender: UIColorWell)
  {
    guard let color = sender.selectedColor else { return }
    atom.color = color
    onChange?()
  }

  @objc private func visibilityChanged(_ sender: UISwitch)
  {
    atom.isVisible = sender.isOn
    onChange?()
  }
}
