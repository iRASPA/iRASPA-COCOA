import UIKit
import iRASPAKit
import UniformTypeIdentifiers
import ZIPFoundation
import BinaryCodable
import LogViewKit
import CloudKit

final class BundledGallery
{
  static let shared = BundledGallery()
  private(set) var children: [ProjectTreeNode] = []
  private(set) var isLoading = false
  private var didLoad = false
  private var callbacks: [() -> Void] = []

  func load(_ completion: @escaping () -> Void)
  {
    if didLoad
    {
      completion()
      return
    }
    callbacks.append(completion)
    guard !isLoading else { return }
    isLoading = true
    DispatchQueue.global(qos: .userInitiated).async {
      let nodes = Self.readFromBundle()
      DispatchQueue.main.async {
        self.children = nodes
        self.didLoad = true
        self.isLoading = false
        let done = self.callbacks
        self.callbacks.removeAll()
        done.forEach { $0() }
      }
    }
  }

  private static func readFromBundle() -> [ProjectTreeNode]
  {
    guard let url = Bundle.main.url(forResource: "Gallery", withExtension: "irspdoc"),
          let archive = Archive(url: url, accessMode: .read) else {
      LogQueue.shared.warning(destination: nil, message: "Gallery.irspdoc is not in the app bundle")
      return []
    }
    guard let entry = archive["nl.darkwing.iRASPA_projectData"] else { return [] }
    do
    {
      var projectBytes = Data(capacity: entry.uncompressedSize)
      _ = try archive.extract(entry, consumer: { projectBytes.append($0) })
      let galleryData = try BinaryDecoder(data: [UInt8](projectBytes)).decode(DocumentData.self)
      for node in galleryData.projectLocalRootNode.flattenedNodes()
      {
        let key = "nl.darkwing.iRASPA_Project_" + node.representedObject.fileNameUUID
        if let projectEntry = archive[key]
        {
          var blob = Data(capacity: projectEntry.uncompressedSize)
          _ = try archive.extract(projectEntry, consumer: { blob.append($0) })
          node.representedObject.data = blob
        }
        node.isDropEnabled = false
        node.isEditable = false
        node.isExpanded = false
      }
      // Detach from the temporary document tree (parentNode is weak).
      let children = Array(galleryData.projectLocalRootNode.childNodes)
      for child in children
      {
        child.parentNode = nil
      }
      LogQueue.shared.info(destination: nil, message: "Loaded gallery with \(galleryData.projectLocalRootNode.descendantLeafNodes().count) structures in \(children.count) folders")
      return children
    }
    catch
    {
      LogQueue.shared.error(destination: nil, message: "Could not load gallery: \(error.localizedDescription)")
      return []
    }
  }
}

final class ProjectTreeViewController: UITableViewController, UIDocumentPickerDelegate
{
  let document: iRASPAUIDocument
  var onSelect: ((ProjectTreeNode) -> Void)?
  var onClose: (() -> Void)?
  var renderHost: RenderHostViewController?

  private var galleryRows: [(node: ProjectTreeNode, depth: Int)] = []
  private var projectRows: [(node: ProjectTreeNode, depth: Int)] = []
  private var cloudRows: [(node: ProjectTreeNode, depth: Int)] = []
  private var selectedNode: ProjectTreeNode?
  private var loadingCloudNodes = Set<ObjectIdentifier>()
  private var cloudLoadErrors: [ObjectIdentifier: String] = [:]
  private var filterText = ""
  private let galleryGroupNode: ProjectTreeNode = {
    let node = ProjectTreeNode(displayName: "Gallery", representedObject: iRASPAProject(group: ProjectGroup(name: "Gallery")))
    node.isExpanded = false
    node.isEditable = false
    return node
  }()

  init(document: iRASPAUIDocument)
  {
    self.document = document
    super.init(style: .insetGrouped)
    title = "iRASPA"
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    clearsSelectionOnViewWillAppear = false
    collapseCloudFolders()
    galleryGroupNode.isExpanded = false
    reloadNodes()
    BundledGallery.shared.load { [weak self] in
      self?.collapseGalleryFolders()
      self?.reloadNodes()
    }
  }

  func reloadNodes()
  {
    galleryRows = []
    galleryRows.append((galleryGroupNode, 0))
    if galleryGroupNode.isExpanded
    {
      appendVisible(nodes: BundledGallery.shared.children, into: &galleryRows, depth: 1)
    }
    projectRows = []
    let root = document.documentData.projectLocalRootNode
    root.isExpanded = true
    appendVisible(nodes: root.childNodes, into: &projectRows, depth: 0)
    cloudRows = []
    appendVisible(nodes: document.documentData.cloudRootNode.childNodes, into: &cloudRows, depth: 0)
    tableView.reloadData()
  }

  private func collapseGalleryFolders()
  {
    func collapse(_ nodes: [ProjectTreeNode])
    {
      for node in nodes
      {
        node.isExpanded = false
        collapse(node.childNodes)
      }
    }
    collapse(BundledGallery.shared.children)
  }

  private func collapseCloudFolders()
  {
    func collapse(_ nodes: [ProjectTreeNode])
    {
      for node in nodes
      {
        node.isExpanded = false
        collapse(node.childNodes)
      }
    }
    collapse(document.documentData.cloudRootNode.childNodes)
  }

  var currentSelectedNode: ProjectTreeNode?
  {
    return selectedNode
  }

  func select(_ node: ProjectTreeNode)
  {
    selectedNode = node
    reloadNodes()
    onSelect?(node)
  }

  func setFilter(_ text: String)
  {
    filterText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    reloadNodes()
  }

  func addStructureProject()
  {
    let (parent, index) = insertionParentAndIndex()
    let sceneList = SceneList(name: "New scenelist", scenes: [])
    let project = ProjectStructureNode(name: "New structure", sceneList: sceneList)
    project.isEdited = true
    let node = ProjectTreeNode(displayName: project.displayName, representedObject: iRASPAProject(structureProject: project))
    node.isDropEnabled = false
    node.matchesFilter = true
    document.documentData.projectData.insertNode(node, inItem: parent, atIndex: index)
    document.updateChangeCount(.done)
    reloadNodes()
  }

  func addProjectGroup()
  {
    let (parent, index) = insertionParentAndIndex()
    let project = ProjectGroup(name: "New Group project")
    project.isEdited = true
    let node = ProjectTreeNode(displayName: project.displayName.isEmpty ? "New Group project" : project.displayName, representedObject: iRASPAProject(group: project))
    node.isDropEnabled = true
    node.matchesFilter = true
    document.documentData.projectData.insertNode(node, inItem: parent, atIndex: index)
    document.updateChangeCount(.done)
    reloadNodes()
  }

  func removeSelectedProject()
  {
    guard let node = selectedNode, canDelete(node) else { return }
    deleteNode(node)
  }

  private func insertionParentAndIndex() -> (ProjectTreeNode, Int)
  {
    let root = document.documentData.projectLocalRootNode
    guard let selected = selectedNode, selected.isDescendantOfNode(root) else {
      return (root, root.childNodes.count)
    }
    if selected.representedObject.isProjectGroup
    {
      return (selected, selected.childNodes.count)
    }
    if let parent = selected.parentNode
    {
      let index = (selected.indexPath.last ?? 0) + 1
      return (parent, min(index, parent.childNodes.count))
    }
    return (root, root.childNodes.count)
  }

  private func appendVisible(nodes: [ProjectTreeNode], into rows: inout [(node: ProjectTreeNode, depth: Int)], depth: Int)
  {
    for node in nodes
    {
      guard passesFilter(node) else { continue }
      rows.append((node, depth))
      let showChildren = !node.isLeaf && (filterText.isEmpty ? node.isExpanded : true)
      if showChildren
      {
        appendVisible(nodes: node.childNodes, into: &rows, depth: depth + 1)
      }
    }
  }

  private func passesFilter(_ node: ProjectTreeNode) -> Bool
  {
    guard !filterText.isEmpty else { return true }
    if node.displayName.range(of: filterText, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    {
      return true
    }
    return node.childNodes.contains { passesFilter($0) }
  }

  private func rows(in section: Int) -> [(node: ProjectTreeNode, depth: Int)]
  {
    switch section
    {
    case 0: return galleryRows
    case 1: return projectRows
    default: return cloudRows
    }
  }

  override func numberOfSections(in tableView: UITableView) -> Int { return 3 }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
  {
    let titles = ["Gallery", "Projects", "iCloud"]
    return makeSectionHeader(title: titles[section])
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String?
  {
    if section == 2, !Cloud.isCloudKitUsable
    {
      return "CoRE MOF and IZA galleries need a signed build with the iCloud.nl.darkwing.iRASPA container."
    }
    return nil
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
  {
    return 36
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    if section == 0
    {
      return max(galleryRows.count, 1)
    }
    return max(rows(in: section).count, 1)
  }

  private func makeSectionHeader(title: String) -> UIView
  {
    let button = UIButton(type: .system)
    button.contentHorizontalAlignment = .leading
    button.isUserInteractionEnabled = false
    var config = UIButton.Configuration.plain()
    config.title = title
    config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
      var outgoing = incoming
      outgoing.font = UIFont.preferredFont(forTextStyle: .headline)
      outgoing.foregroundColor = .secondaryLabel
      return outgoing
    }
    config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
    button.configuration = config
    return button
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    let sectionRows = rows(in: indexPath.section)
    if sectionRows.isEmpty
    {
      if indexPath.section == 0
      {
        config.text = "No gallery structures"
        config.secondaryText = nil
        config.image = UIImage(systemName: "photo.on.rectangle.angled")
      }
      else if indexPath.section == 2
      {
        config.text = "No iCloud galleries"
        config.secondaryText = Cloud.isCloudKitUsable ? nil : "Use a signed build with the iCloud.nl.darkwing.iRASPA container"
        config.image = UIImage(systemName: "icloud")
      }
      else
      {
        config.text = "No structures"
        config.secondaryText = "Tap + to import a CIF, PDB, XYZ, or .irspdoc file"
        config.image = UIImage(systemName: "tray")
      }
      cell.contentConfiguration = config
      cell.accessoryType = .none
      cell.indentationLevel = 0
      cell.selectionStyle = .none
      return cell
    }
    let row = sectionRows[indexPath.row]
    config.text = row.node.displayName
    if row.node.isLeaf
    {
      config.secondaryText = nil
      config.image = UIImage(named: "MaterialsIcon") ?? UIImage(systemName: "cube")
    }
    else
    {
      if loadingCloudNodes.contains(ObjectIdentifier(row.node))
      {
        config.secondaryText = "Loading…"
      }
      else if let errorText = cloudLoadErrors[ObjectIdentifier(row.node)]
      {
        config.secondaryText = errorText
      }
      else if row.node === galleryGroupNode, BundledGallery.shared.isLoading
      {
        config.secondaryText = "Loading…"
      }
      else
      {
        config.secondaryText = row.node.isExpanded ? nil : "Folder"
      }
      config.image = UIImage(named: "FolderIcon") ?? UIImage(systemName: row.node.isExpanded ? "folder.fill" : "folder")
    }
    cell.contentConfiguration = config
    cell.indentationWidth = 16
    cell.indentationLevel = row.depth
    cell.selectionStyle = .default
    if row.node === selectedNode
    {
      cell.accessoryType = .checkmark
    }
    else if !row.node.isLeaf
    {
      cell.accessoryType = row.node.isExpanded ? .none : .disclosureIndicator
    }
    else
    {
      cell.accessoryType = .none
    }
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  {
    let sectionRows = rows(in: indexPath.section)
    guard sectionRows.indices.contains(indexPath.row) else {
      tableView.deselectRow(at: indexPath, animated: true)
      return
    }
    let node = sectionRows[indexPath.row].node
    if !node.isLeaf
    {
      node.isExpanded.toggle()
      if node.isExpanded
      {
        fetchCloudChildrenIfNeeded(node)
      }
      reloadNodes()
      return
    }
    selectedNode = node
    tableView.reloadData()
    onSelect?(node)
  }

  override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
  {
    let sectionRows = rows(in: indexPath.section)
    guard sectionRows.indices.contains(indexPath.row) else { return nil }
    let node = sectionRows[indexPath.row].node
    guard canDelete(node) else { return nil }
    let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
      self?.deleteNode(node)
      completion(true)
    }
    return UISwipeActionsConfiguration(actions: [delete])
  }

  override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration?
  {
    let sectionRows = rows(in: indexPath.section)
    guard sectionRows.indices.contains(indexPath.row) else { return nil }
    let node = sectionRows[indexPath.row].node
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
      var actions: [UIMenuElement] = []
      if indexPath.section == 1
      {
        actions.append(UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { _ in
          self?.renameNode(node)
        })
      }
      if self?.canDelete(node) == true
      {
        actions.append(UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
          self?.deleteNode(node)
        })
      }
      guard !actions.isEmpty else { return nil }
      return UIMenu(children: actions)
    }
  }

  private func isGalleryNode(_ node: ProjectTreeNode) -> Bool
  {
    if node === galleryGroupNode { return true }
    var current: ProjectTreeNode? = node
    while let item = current
    {
      if BundledGallery.shared.children.contains(where: { $0 === item })
      {
        return true
      }
      current = item.parentNode
    }
    return false
  }

  private func isCloudNode(_ node: ProjectTreeNode) -> Bool
  {
    return node.isDescendantOfNode(document.documentData.cloudRootNode)
  }

  private func canDelete(_ node: ProjectTreeNode) -> Bool
  {
    return node.isEditable && !isGalleryNode(node) && !isCloudNode(node) && node.parentNode != nil && node !== document.documentData.projectLocalRootNode
  }

  private func fetchCloudChildrenIfNeeded(_ node: ProjectTreeNode)
  {
    guard node.childNodes.isEmpty, let recordID = node.recordID, Cloud.isCloudKitUsable else { return }
    let id = ObjectIdentifier(node)
    guard !loadingCloudNodes.contains(id) else { return }
    loadingCloudNodes.insert(id)
    cloudLoadErrors.removeValue(forKey: id)
    tableView.reloadData()

    let container = CKContainer(identifier: "iCloud.nl.darkwing.iRASPA")
    container.accountStatus { status, error in
      let label: String
      switch status
      {
      case .available: label = "available"
      case .noAccount: label = "noAccount — sign into iCloud in Simulator Settings"
      case .restricted: label = "restricted"
      case .couldNotDetermine: label = "couldNotDetermine"
      case .temporarilyUnavailable: label = "temporarilyUnavailable"
      @unknown default: label = "unknown(\(status.rawValue))"
      }
      LogQueue.shared.info(destination: nil, message: "CloudKit accountStatus=\(label)\(error.map { " (\($0.localizedDescription))" } ?? "") for \(node.displayName)")
    }

    // Prefer the modern CloudKit API on iPad — the OperationKit/CKOperation path
    // can hang forever on Simulator when entitlements are missing.
    let database = container.publicCloudDatabase
    database.fetch(withRecordID: recordID) { [weak self, weak node] parentRecord, fetchError in
      guard let self else { return }
      if let fetchError
      {
        DispatchQueue.main.async {
          guard self.loadingCloudNodes.contains(id) else { return }
          self.loadingCloudNodes.remove(id)
          self.cloudLoadErrors[id] = fetchError.localizedDescription
          LogQueue.shared.error(destination: nil, message: "CloudKit fetch \(recordID.recordName): \(fetchError.localizedDescription)")
          self.reloadNodes()
        }
        return
      }
      guard let parentRecord else
      {
        DispatchQueue.main.async {
          guard self.loadingCloudNodes.contains(id) else { return }
          self.loadingCloudNodes.remove(id)
          self.cloudLoadErrors[id] = "Parent record missing"
          self.reloadNodes()
        }
        return
      }

      let reference = CKRecord.Reference(record: parentRecord, action: .none)
      let predicate = NSPredicate(format: "parent == %@", reference)
      let query = CKQuery(recordType: "ProjectNode", predicate: predicate)
      query.sortDescriptors = [NSSortDescriptor(key: "displayName", ascending: true)]

      database.perform(query, inZoneWith: nil) { [weak self, weak node] records, queryError in
        DispatchQueue.main.async {
          guard let self, let node else { return }
          guard self.loadingCloudNodes.contains(id) else { return }
          self.loadingCloudNodes.remove(id)
          if let queryError
          {
            self.cloudLoadErrors[id] = queryError.localizedDescription
            LogQueue.shared.error(destination: nil, message: "CloudKit query \(node.displayName): \(queryError.localizedDescription)")
            self.reloadNodes()
            return
          }
          let records = records ?? []
          if records.isEmpty
          {
            self.cloudLoadErrors[id] = "No children — check Production DB / entitlements"
            LogQueue.shared.warning(destination: nil, message: "CloudKit returned 0 children for \(node.displayName)")
          }
          else
          {
            self.cloudLoadErrors.removeValue(forKey: id)
            for record in records
            {
              let child = ProjectTreeNode(record: record)
              if let type = record["type"] as? Int64, type == 2,
                 let name = record["displayName"] as? String
              {
                child.representedObject = iRASPAProject(group: ProjectGroup(name: name))
              }
              child.isEditable = false
              child.isExpanded = false
              if child.parentNode == nil
              {
                child.append(inParent: node)
              }
            }
            LogQueue.shared.info(destination: nil, message: "Loaded \(records.count) CloudKit children for \(node.displayName)")
          }
          self.reloadNodes()
        }
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
      guard let self, self.loadingCloudNodes.contains(id) else { return }
      self.loadingCloudNodes.remove(id)
      self.cloudLoadErrors[id] = "Timed out — Run from Xcode after Clean; need CloudKit entitlements"
      LogQueue.shared.error(destination: nil, message: "CloudKit timed out loading \(node.displayName). Product → Clean Build Folder, then Run so the Simulator resign script embeds iCloud entitlements.")
      self.reloadNodes()
    }
  }

  private func deleteNode(_ node: ProjectTreeNode)
  {
    if selectedNode === node
    {
      selectedNode = nil
    }
    document.documentData.projectData.removeNode(node)
    document.updateChangeCount(.done)
    reloadNodes()
    if selectedNode == nil
    {
      renderHost?.clearDisplay()
    }
  }

  private func renameNode(_ node: ProjectTreeNode)
  {
    let alert = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
    alert.addTextField { field in
      field.text = node.displayName
      field.autocapitalizationType = .words
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
      guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return }
      node.displayName = name
      self?.document.updateChangeCount(.done)
      self?.reloadNodes()
    })
    present(alert, animated: true)
  }

  @objc func closeTapped()
  {
    onClose?()
  }

  @objc func exportTapped()
  {
    let node = selectedNode ?? projectRows.first?.node ?? galleryRows.first?.node ?? cloudRows.first?.node
    guard let node else { return }
    ExportController.present(from: self, document: document, node: node, render: renderHost?.renderController)
  }

  @objc func saveTapped()
  {
    document.save(to: document.fileURL, for: .forOverwriting) { [weak self] success in
      let title = success ? "Saved" : "Save failed"
      let alert = UIAlertController(title: title, message: self?.document.fileURL.lastPathComponent, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      self?.present(alert, animated: true)
    }
  }

  @objc func importTapped()
  {
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.cif, .pdb, .xyz, .poscar, .cube, .vtk, .irspdoc, .plainText], asCopy: true)
    picker.delegate = self
    picker.allowsMultipleSelection = true
    present(picker, animated: true)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL])
  {
    guard !urls.isEmpty else { return }
    // The picker cannot host an accessory view like Cocoa's NSOpenPanel, so
    // the import options are collected in a sheet right after picking.
    ImportOptionsViewController.present(from: self, urls: urls) { [weak self] options in
      guard let self else { return }
      let accessing = urls.map { $0.startAccessingSecurityScopedResource() }
      defer {
        for (url, wasAccessing) in zip(urls, accessing) where wasAccessing
        {
          url.stopAccessingSecurityScopedResource()
        }
      }
      self.document.importStructures(urls: urls,
                                     importType: options.importType,
                                     onlyAsymmetricUnit: options.onlyAsymmetricUnit,
                                     asMolecule: options.asMolecule,
                                     separatePolymerChains: options.separatePolymerChains)
      self.reloadNodes()
    }
  }
}
