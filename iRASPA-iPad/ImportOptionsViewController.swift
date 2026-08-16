import UIKit
import SymmetryKit

/// iPad replacement for Cocoa's NSOpenPanel accessory view
/// (`ImportAccessoryViewController`): since `UIDocumentPickerViewController`
/// cannot host custom controls, the same import options are collected in this
/// form sheet shown right after the files have been picked.
final class ImportOptionsViewController: UIViewController
{
  struct Options
  {
    var importType: SKParser.ImportType = .asSingleProject
    var onlyAsymmetricUnit: Bool = true
    var asMolecule: Bool = false
    var separatePolymerChains: Bool = false
  }

  private let urls: [URL]
  private let completion: (Options) -> Void
  private var options = Options()

  private let importTypeControl = UISegmentedControl(items: ["Separate projects", "Single project", "Movie frames"])
  private let asymmetricSwitch = UISwitch()
  private let chainsSwitch = UISwitch()
  private let moleculeSwitch = UISwitch()

  init(urls: [URL], completion: @escaping (Options) -> Void)
  {
    self.urls = urls
    self.completion = completion
    super.init(nibName: nil, bundle: nil)
    title = urls.count == 1 ? "Import 1 File" : "Import \(urls.count) Files"
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  /// Wraps the controller in a navigation controller sized as a form sheet.
  static func present(from host: UIViewController, urls: [URL], completion: @escaping (Options) -> Void)
  {
    let controller = ImportOptionsViewController(urls: urls, completion: completion)
    let navigation = UINavigationController(rootViewController: controller)
    navigation.modalPresentationStyle = .formSheet
    navigation.preferredContentSize = CGSize(width: 460, height: 420)
    host.present(navigation, animated: true)
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground

    navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in
      self?.dismiss(animated: true)
    })
    let importItem = UIBarButtonItem(title: "Import", primaryAction: UIAction { [weak self] _ in
      guard let self else { return }
      self.dismiss(animated: true) {
        self.completion(self.options)
      }
    })
    importItem.style = .done
    navigationItem.rightBarButtonItem = importItem

    // File names (first few, then a summary line), like the open panel shows
    // the selection next to the accessory view.
    let fileNames = urls.prefix(4).map { $0.lastPathComponent }
    var fileText = fileNames.joined(separator: "\n")
    if urls.count > 4
    {
      fileText += "\nand \(urls.count - 4) more…"
    }
    let filesLabel = UILabel()
    filesLabel.text = fileText
    filesLabel.numberOfLines = 0
    filesLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
    filesLabel.textColor = .secondaryLabel

    importTypeControl.selectedSegmentIndex = options.importType.rawValue
    importTypeControl.addAction(UIAction { [weak self] _ in
      guard let self, let importType = SKParser.ImportType(rawValue: self.importTypeControl.selectedSegmentIndex) else { return }
      self.options.importType = importType
    }, for: .valueChanged)

    asymmetricSwitch.isOn = options.onlyAsymmetricUnit
    asymmetricSwitch.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.options.onlyAsymmetricUnit = self.asymmetricSwitch.isOn
    }, for: .valueChanged)

    chainsSwitch.isOn = options.separatePolymerChains
    chainsSwitch.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.options.separatePolymerChains = self.chainsSwitch.isOn
    }, for: .valueChanged)

    moleculeSwitch.isOn = options.asMolecule
    moleculeSwitch.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.options.asMolecule = self.moleculeSwitch.isOn
    }, for: .valueChanged)

    func groupBox(_ views: [UIView]) -> UIView
    {
      let background = UIView()
      background.backgroundColor = .secondarySystemGroupedBackground
      background.layer.cornerRadius = 10
      let stack = UIStackView(arrangedSubviews: views)
      stack.axis = .vertical
      stack.spacing = 12
      stack.translatesAutoresizingMaskIntoConstraints = false
      background.addSubview(stack)
      NSLayoutConstraint.activate([
        stack.topAnchor.constraint(equalTo: background.topAnchor, constant: 12),
        stack.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 16),
        stack.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -16),
        stack.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -12)
      ])
      return background
    }

    func switchRow(_ title: String, control: UISwitch) -> UIView
    {
      let label = UILabel()
      label.text = title
      label.font = .systemFont(ofSize: 15)
      let row = UIStackView(arrangedSubviews: [label, control])
      row.axis = .horizontal
      row.alignment = .center
      return row
    }

    func sectionTitle(_ text: String) -> UILabel
    {
      let label = UILabel()
      label.text = text.uppercased()
      label.font = .systemFont(ofSize: 12, weight: .medium)
      label.textColor = .secondaryLabel
      return label
    }

    let mainStack = UIStackView(arrangedSubviews: [
      groupBox([filesLabel]),
      sectionTitle("Import as"),
      groupBox([importTypeControl]),
      sectionTitle("Options"),
      groupBox([
        switchRow("Proteins: only asymmetric unit", control: asymmetricSwitch),
        switchRow("Separate polymer chains", control: chainsSwitch),
        switchRow("Import as molecule", control: moleculeSwitch)
      ])
    ])
    mainStack.axis = .vertical
    mainStack.spacing = 10
    mainStack.setCustomSpacing(18, after: mainStack.arrangedSubviews[0])
    mainStack.translatesAutoresizingMaskIntoConstraints = false

    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)
    scrollView.addSubview(mainStack)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      mainStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
      mainStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
      mainStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
      mainStack.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
      mainStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
    ])
  }
}
