import UIKit
import LogViewKit

final class LogViewController: UIViewController, LogReporting
{
  private let textView = UITextView()

  override func viewDidLoad()
  {
    super.viewDidLoad()
    title = "Log"
    textView.isEditable = false
    textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    textView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(textView)
    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(equalTo: view.topAnchor),
      textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
    textView.attributedText = LogQueue.shared.textStorageView
    LogQueue.shared.subscribe(self, windowController: self)
  }

  func update(attributedString: NSTextStorage)
  {
    textView.attributedText = LogQueue.shared.textStorageView
  }
}
