import UIKit
import UniformTypeIdentifiers
import iRASPAKit

final class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate
{
  init()
  {
    super.init(forOpening: [.irspdoc, .cif, .pdb, .xyz, .poscar, .cube, .vtk, .plainText])
    delegate = self
    allowsDocumentCreation = true
    allowsPickingMultipleItems = false
    shouldShowFileExtensions = true
    additionalTrailingNavigationBarButtonItems = [
      UIBarButtonItem(image: UIImage(systemName: "cloud"), style: .plain, target: self, action: #selector(openCloudGallery)),
      UIBarButtonItem(title: "Sample", style: .plain, target: self, action: #selector(openSample))
    ]
    installStarterFiles()
  }

  override func viewDidAppear(_ animated: Bool)
  {
    super.viewDidAppear(animated)
    installStarterFiles()
  }

  private func installStarterFiles()
  {
    guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
    for name in ["materials_sample", "1D5H_sample"]
    {
      guard let source = Bundle.main.url(forResource: name, withExtension: "cif") else { continue }
      let destination = documents.appendingPathComponent("\(name).cif")
      if !FileManager.default.fileExists(atPath: destination.path)
      {
        try? FileManager.default.copyItem(at: source, to: destination)
      }
    }
  }

  required init?(coder: NSCoder)
  {
    super.init(coder: coder)
  }

  func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void)
  {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("Untitled.irspdoc")
    let document = iRASPAUIDocument(fileURL: url)
    if let sample = Bundle.main.url(forResource: "materials_sample", withExtension: "cif")
    {
      _ = document.importStructure(from: sample)
    }
    document.save(to: url, for: .forCreating) { success in
      importHandler(success ? url : nil, .move)
    }
  }

  func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL])
  {
    guard let url = documentURLs.first else { return }
    presentDocument(at: url)
  }

  func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL)
  {
    presentDocument(at: destinationURL)
  }

  func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?)
  {
    let alert = UIAlertController(title: "Could not import file", message: error?.localizedDescription ?? documentURL.lastPathComponent, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }

  func presentDocument(at url: URL)
  {
    let accessing = url.startAccessingSecurityScopedResource()
    let ext = url.pathExtension.lowercased()
    if ["cif", "mmcif", "pdb", "ent", "xyz", "poscar", "cube", "cub", "vtk"].contains(ext) || ["POSCAR", "CONTCAR", "CHGCAR", "LOCPOT", "ELFCAR", "XDATCAR"].contains(url.lastPathComponent.uppercased())
    {
      defer { if accessing { url.stopAccessingSecurityScopedResource() } }
      presentImportedStructure(at: url)
      return
    }

    let document = iRASPAUIDocument(fileURL: url)
    document.open { [weak self] success in
      if accessing { url.stopAccessingSecurityScopedResource() }
      guard let self else { return }
      guard success else {
        let alert = UIAlertController(title: "Could not open document", message: url.lastPathComponent, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
        return
      }
      self.showSplitView(for: document)
    }
  }

  private func presentImportedStructure(at url: URL)
  {
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
    let dest = documents.appendingPathComponent(url.deletingPathExtension().lastPathComponent + ".irspdoc")
    let document = iRASPAUIDocument(fileURL: dest)
    guard document.importStructure(from: url) != nil else {
      let alert = UIAlertController(title: "Could not import file", message: url.lastPathComponent, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      present(alert, animated: true)
      return
    }
    showSplitView(for: document)
    document.save(to: dest, for: .forCreating) { _ in }
  }

  private func showSplitView(for document: iRASPAUIDocument)
  {
    let split = MainSplitViewController(document: document)
    split.modalPresentationStyle = .fullScreen
    present(split, animated: true)
  }

  @objc private func openSample()
  {
    guard let url = Bundle.main.url(forResource: "materials_sample", withExtension: "cif") else {
      let alert = UIAlertController(title: "Sample missing", message: "materials_sample.cif is not in the app bundle.", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      present(alert, animated: true)
      return
    }
    presentImportedStructure(at: url)
  }

  @objc private func openCloudGallery()
  {
    guard Cloud.isCloudKitUsable else {
      let alert = UIAlertController(title: "iCloud galleries unavailable", message: "The CoRE MOF and IZA galleries need a signed build with the iCloud.nl.darkwing.iRASPA container. Unsigned simulator builds cannot create that CloudKit container.", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      present(alert, animated: true)
      return
    }
    let nav = UINavigationController(rootViewController: CloudGalleryViewController())
    nav.modalPresentationStyle = .pageSheet
    present(nav, animated: true)
  }
}
