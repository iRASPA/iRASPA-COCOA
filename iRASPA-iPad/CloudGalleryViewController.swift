import UIKit
import CloudKit
import iRASPAKit
import LogViewKit

final class CloudGalleryViewController: UITableViewController
{
  private let parentNode: ProjectTreeNode?
  private var nodes: [ProjectTreeNode]
  private var isLoading = false

  init(parentNode: ProjectTreeNode? = nil, nodes: [ProjectTreeNode]? = nil)
  {
    self.parentNode = parentNode
    if let nodes
    {
      self.nodes = nodes
    }
    else
    {
      let data = DocumentData()
      self.nodes = [
        data.cloudCoREMOFRootNode,
        data.cloudCoREMOFDDECRootNode,
        data.cloudCoREMOFASR2019RootNode,
        data.cloudCoREMOFFSR2019RootNode,
        data.cloudIZARootNode
      ]
    }
    super.init(style: .insetGrouped)
    title = parentNode?.displayName ?? "iCloud galleries"
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    if parentNode == nil
    {
      navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
    }
    if !Cloud.isCloudKitUsable
    {
      nodes = []
      return
    }
    if let parentNode, parentNode.childNodes.isEmpty, parentNode.recordID != nil
    {
      fetchChildren(of: parentNode)
    }
  }

  @objc private func close()
  {
    dismiss(animated: true)
  }

  private func fetchChildren(of node: ProjectTreeNode)
  {
    guard let recordID = node.recordID else { return }
    isLoading = true
    tableView.reloadData()
    CKContainer(identifier: "iCloud.nl.darkwing.iRASPA").accountStatus { status, error in
      LogQueue.shared.info(destination: nil, message: "CloudKit accountStatus=\(status.rawValue) error=\(error?.localizedDescription ?? "nil")")
    }
    let operation = ImportChildNodesOfParentRecordIDOperation(parentRecordID: recordID)
    operation.completionBlock = { [weak self, weak operation] in
      DispatchQueue.main.async {
        guard let self, let operation else { return }
        guard self.isLoading else { return }
        self.isLoading = false
        for child in operation.childNodes where child.parentNode == nil
        {
          child.append(inParent: node)
        }
        self.nodes = node.childNodes
        self.tableView.reloadData()
        if operation.childNodes.isEmpty
        {
          LogQueue.shared.warning(destination: nil, message: "Loaded 0 items from iCloud for \(node.displayName)")
        }
        else
        {
          LogQueue.shared.info(destination: nil, message: "Loaded \(self.nodes.count) items from iCloud")
        }
      }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 45) { [weak self, weak operation] in
      guard let self, self.isLoading else { return }
      operation?.cancel()
      self.isLoading = false
      self.tableView.reloadData()
      LogQueue.shared.error(destination: nil, message: "CloudKit timed out. Sign into iCloud in Simulator Settings and use a team-signed build.")
    }
    Cloud.shared.cloudQueue.addOperation(operation)
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    if isLoading && nodes.isEmpty { return 1 }
    return max(nodes.count, 1)
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    if isLoading && nodes.isEmpty
    {
      config.text = "Loading from iCloud…"
      config.image = UIImage(systemName: "icloud")
      cell.contentConfiguration = config
      cell.accessoryType = .none
      return cell
    }
    if nodes.isEmpty
    {
      config.text = "iCloud galleries unavailable"
      config.secondaryText = "Use a signed build with the iCloud.nl.darkwing.iRASPA container"
      config.image = UIImage(systemName: "icloud.slash")
      cell.contentConfiguration = config
      cell.accessoryType = .none
      return cell
    }
    let node = nodes[indexPath.row]
    config.text = node.displayName
    config.secondaryText = node.isLeaf ? "CloudKit structure" : "Folder"
    config.image = UIImage(named: node.isLeaf ? "MaterialsIcon" : "FolderIcon") ?? UIImage(systemName: node.isLeaf ? "cube" : "folder")
    cell.contentConfiguration = config
    cell.accessoryType = node.isLeaf ? .none : .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  {
    tableView.deselectRow(at: indexPath, animated: true)
    guard nodes.indices.contains(indexPath.row) else { return }
    let node = nodes[indexPath.row]
    if node.isLeaf
    {
      openCloudStructure(node)
      return
    }
    if node.childNodes.isEmpty
    {
      let childController = CloudGalleryViewController(parentNode: node, nodes: [])
      navigationController?.pushViewController(childController, animated: true)
    }
    else
    {
      let childController = CloudGalleryViewController(parentNode: node, nodes: node.childNodes)
      navigationController?.pushViewController(childController, animated: true)
    }
  }

  private func openCloudStructure(_ node: ProjectTreeNode)
  {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(node.displayName + ".irspdoc")
    let document = iRASPAUIDocument(fileURL: url)
    let presentLoaded = { [weak self] in
      DispatchQueue.main.async {
        self?.present(document: document, containing: node)
      }
    }
    if node.representedObject.lazyStatus == .loaded
    {
      presentLoaded()
      return
    }
    do
    {
      try node.unwrapProject(outlineView: nil, queue: Cloud.shared.cloudQueue, colorSets: document.colorSets, forceFieldSets: document.forceFieldSets, reloadCompletionBlock: presentLoaded)
    }
    catch
    {
      let alert = UIAlertController(title: "Could not open gallery item", message: error.localizedDescription, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      present(alert, animated: true)
    }
  }

  private func present(document: iRASPAUIDocument, containing node: ProjectTreeNode)
  {
    let copy = ProjectTreeNode(displayName: node.displayName, representedObject: node.representedObject)
    document.documentData.projectData.insertNode(copy, inItem: document.documentData.projectLocalRootNode, atIndex: 0)
    document.save(to: document.fileURL, for: .forCreating) { [weak self] success in
      guard success else { return }
      let split = MainSplitViewController(document: document)
      split.modalPresentationStyle = .fullScreen
      self?.present(split, animated: true)
    }
  }
}
