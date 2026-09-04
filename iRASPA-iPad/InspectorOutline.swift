import UIKit
import iRASPAKit
import SymmetryKit

/// Collapsible outline-style table used by the inspectors. Subclasses describe their
/// content in *inspector section* indices; sections whose title is empty are omitted
/// from the table entirely, so hidden sections never leave blank space behind.
class CollapsibleTableViewController: UITableViewController
{
  /// Expanded state, keyed by inspector section index (stable across visibility changes).
  var expandedSections = Set<Int>()

  /// Maps table section -> inspector section; rebuilt on every reload.
  private var visibleSections: [Int] = []

  func inspectorSectionCount() -> Int
  {
    return 0
  }

  func inspectorSectionTitle(_ section: Int) -> String
  {
    return ""
  }

  /// Static header shown above a section, mirroring the root nodes of the
  /// Cocoa outline views (e.g. "Cell/Bounding-Box Properties", "Atoms").
  func inspectorGroupHeader(_ section: Int) -> String?
  {
    return nil
  }

  func inspectorFooterTitle(_ section: Int) -> String?
  {
    return nil
  }

  func inspectorRowCount(in section: Int) -> Int
  {
    return 0
  }

  func inspectorCell(for indexPath: IndexPath) -> UITableViewCell
  {
    return UITableViewCell(style: .value1, reuseIdentifier: nil)
  }

  func inspectorDidSelect(at indexPath: IndexPath)
  {
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()
    tableView.sectionHeaderTopPadding = 4
  }

  private func inspectorSection(_ tableSection: Int) -> Int
  {
    guard visibleSections.indices.contains(tableSection) else { return tableSection }
    return visibleSections[tableSection]
  }

  override func numberOfSections(in tableView: UITableView) -> Int
  {
    visibleSections = (0..<inspectorSectionCount()).filter { !inspectorSectionTitle($0).isEmpty }
    return visibleSections.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    let inspector = inspectorSection(section)
    return expandedSections.contains(inspector) ? inspectorRowCount(in: inspector) + 1 : 1
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String?
  {
    return inspectorFooterTitle(inspectorSection(section))
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
  {
    guard let title = inspectorGroupHeader(inspectorSection(section)) else { return nil }
    let header = UITableViewHeaderFooterView()
    var config = UIListContentConfiguration.prominentInsetGroupedHeader()
    config.text = title
    config.textProperties.color = .label
    header.contentConfiguration = config
    return header
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
  {
    return inspectorGroupHeader(inspectorSection(section)) == nil ? 8 : UITableView.automaticDimension
  }

  override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat
  {
    return inspectorGroupHeader(inspectorSection(section)) == nil ? 8 : 44
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    let inspector = inspectorSection(indexPath.section)
    if indexPath.row == 0
    {
      return groupCell(forInspectorSection: inspector)
    }
    let cell = inspectorCell(for: IndexPath(row: indexPath.row - 1, section: inspector))
    cell.indentationWidth = 16
    cell.indentationLevel = max(cell.indentationLevel, 1)
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  {
    tableView.deselectRow(at: indexPath, animated: true)
    if indexPath.row == 0
    {
      toggleInspectorSection(tableSection: indexPath.section)
      return
    }
    inspectorDidSelect(at: IndexPath(row: indexPath.row - 1, section: inspectorSection(indexPath.section)))
  }

  private func groupCell(forInspectorSection section: Int) -> UITableViewCell
  {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    var config = cell.defaultContentConfiguration()
    let expanded = expandedSections.contains(section)
    config.text = inspectorSectionTitle(section)
    config.textProperties.font = UIFont.preferredFont(forTextStyle: .headline)
    config.image = UIImage(systemName: expanded ? "chevron.down" : "chevron.right")
    config.imageProperties.tintColor = .secondaryLabel
    config.imageProperties.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
    cell.contentConfiguration = config
    cell.accessoryType = .none
    cell.selectionStyle = .default
    return cell
  }

  private func toggleInspectorSection(tableSection: Int)
  {
    let inspector = inspectorSection(tableSection)
    if expandedSections.contains(inspector)
    {
      expandedSections.remove(inspector)
    }
    else
    {
      expandedSections.insert(inspector)
    }
    tableView.reloadSections(IndexSet(integer: tableSection), with: .automatic)
  }
}

func epsilonOverKBRowTitle(font: UIFont, unit: String = "K") -> NSAttributedString
{
  let string = "Epsilon/kB (\(unit))"
  let attributed = NSMutableAttributedString(string: string, attributes: [.font: font])
  let bRange = (string as NSString).range(of: "B")
  let subscriptFont = font.withSize(font.pointSize * 0.7)
  attributed.addAttributes([
    .font: subscriptFont,
    .baselineOffset: -font.pointSize * 0.18
  ], range: bRange)
  return attributed
}
