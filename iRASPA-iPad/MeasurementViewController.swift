import UIKit
import iRASPAKit
import simd

final class MeasurementViewController: UITableViewController
{
  private let project: ProjectStructureNode
  var onClear: (() -> Void)?

  init(project: ProjectStructureNode)
  {
    self.project = project
    super.init(style: .insetGrouped)
    title = "Measurement"
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearTapped))
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
  }

  func reload()
  {
    tableView.reloadData()
  }

  @objc private func clearTapped()
  {
    onClear?()
    tableView.reloadData()
  }

  @objc private func closeTapped()
  {
    dismiss(animated: true)
  }

  override func numberOfSections(in tableView: UITableView) -> Int { return 2 }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
  {
    return section == 0 ? "Atoms" : "Geometry"
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    let count = project.measurementTreeNodes.count
    if section == 0 { return max(count, 1) }
    if count < 2 { return 1 }
    if count == 2 { return 1 }
    if count == 3 { return 3 }
    return 6
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    let points = project.measurementTreeNodes
    if indexPath.section == 0
    {
      if points.isEmpty
      {
        cell.textLabel?.text = "Tap atoms in the viewer"
        cell.detailTextLabel?.text = "1–4 atoms"
        return cell
      }
      let point = points[indexPath.row]
      cell.textLabel?.text = "Atom \(indexPath.row + 1)"
      cell.detailTextLabel?.text = point.copy.asymmetricParentAtom.displayName
      return cell
    }

    if points.count < 2
    {
      cell.textLabel?.text = "Need at least two atoms"
      return cell
    }

    func distanceText(_ a: Int, _ b: Int) -> String
    {
      let value = Structure.distance(points[a], points[b])
      var text = String(format: "%.3f Å", value.0)
      if let periodic = value.1
      {
        text += String(format: "  (periodic %.3f Å)", periodic)
      }
      return text
    }

    func angleText(_ a: Int, _ b: Int, _ c: Int) -> String
    {
      let value = Structure.bendAngle(points[a], points[b], points[c])
      var text = String(format: "%.2f°", value.0 * 180.0 / Double.pi)
      if let periodic = value.1
      {
        text += String(format: "  (periodic %.2f°)", periodic * 180.0 / Double.pi)
      }
      return text
    }

    if points.count == 2
    {
      cell.textLabel?.text = "Distance 1–2"
      cell.detailTextLabel?.text = distanceText(0, 1)
      return cell
    }

    if points.count == 3
    {
      switch indexPath.row
      {
      case 0:
        cell.textLabel?.text = "Distance 1–2"
        cell.detailTextLabel?.text = distanceText(0, 1)
      case 1:
        cell.textLabel?.text = "Distance 2–3"
        cell.detailTextLabel?.text = distanceText(1, 2)
      default:
        cell.textLabel?.text = "Angle 1–2–3"
        cell.detailTextLabel?.text = angleText(0, 1, 2)
      }
      return cell
    }

    switch indexPath.row
    {
    case 0:
      cell.textLabel?.text = "Distance 1–2"
      cell.detailTextLabel?.text = distanceText(0, 1)
    case 1:
      cell.textLabel?.text = "Distance 2–3"
      cell.detailTextLabel?.text = distanceText(1, 2)
    case 2:
      cell.textLabel?.text = "Distance 3–4"
      cell.detailTextLabel?.text = distanceText(2, 3)
    case 3:
      cell.textLabel?.text = "Angle 1–2–3"
      cell.detailTextLabel?.text = angleText(0, 1, 2)
    case 4:
      cell.textLabel?.text = "Angle 2–3–4"
      cell.detailTextLabel?.text = angleText(1, 2, 3)
    default:
      let dihedral = Structure.dihedralAngle(points[0], points[1], points[2], points[3])
      cell.textLabel?.text = "Dihedral 1–2–3–4"
      var text = String(format: "%.2f°", dihedral.0 * 180.0 / Double.pi)
      if let periodic = dihedral.1
      {
        text += String(format: "  (periodic %.2f°)", periodic * 180.0 / Double.pi)
      }
      cell.detailTextLabel?.text = text
    }
    return cell
  }
}
