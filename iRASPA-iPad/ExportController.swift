import UIKit
import iRASPAKit
import RenderKit
import SymmetryKit
import AVFoundation
import Metal
import LogViewKit

enum ExportController
{
  static func present(from host: UIViewController, document: iRASPAUIDocument, node: ProjectTreeNode, render: RenderViewController?)
  {
    try? node.unwrapProject(outlineView: nil, queue: nil, colorSets: document.colorSets, forceFieldSets: document.forceFieldSets, reloadCompletionBlock: {})
    let sheet = UIAlertController(title: "Share", message: node.displayName, preferredStyle: .actionSheet)
    sheet.addAction(UIAlertAction(title: "CIF", style: .default) { _ in
      share(from: host, items: structureFiles(node: node, includeCIF: true, includePDB: false, includeXYZ: false))
    })
    sheet.addAction(UIAlertAction(title: "PDB", style: .default) { _ in
      share(from: host, items: structureFiles(node: node, includeCIF: false, includePDB: true, includeXYZ: false))
    })
    sheet.addAction(UIAlertAction(title: "XYZ", style: .default) { _ in
      share(from: host, items: structureFiles(node: node, includeCIF: false, includePDB: false, includeXYZ: true))
    })
    sheet.addAction(UIAlertAction(title: "mmCIF", style: .default) { _ in
      share(from: host, items: structureFiles(node: node, includeCIF: false, includePDB: false, includeXYZ: false, includeMMCIF: true))
    })
    for size in [1024, 2048, 4096]
    {
      sheet.addAction(UIAlertAction(title: "Picture \(size)×\(size)", style: .default) { _ in
        share(from: host, items: pictureFiles(node: node, render: render, size: size))
      })
    }
    sheet.addAction(UIAlertAction(title: "Rotation movie (Y)", style: .default) { _ in
      exportMovie(from: host, node: node, kind: .rotationY)
    })
    if ((node.representedObject.project as? ProjectStructureNode)?.sceneList.maximumNumberOfFrames ?? 1) > 1
    {
      sheet.addAction(UIAlertAction(title: "Trajectory movie", style: .default) { _ in
        exportMovie(from: host, node: node, kind: .frames)
      })
    }
    sheet.addAction(UIAlertAction(title: "CIF, PDB, XYZ, and picture", style: .default) { _ in
      var items = structureFiles(node: node, includeCIF: true, includePDB: true, includeXYZ: true)
      items.append(contentsOf: pictureFiles(node: node, render: render, size: 2048))
      share(from: host, items: items)
    })
    sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    if let pop = sheet.popoverPresentationController
    {
      pop.sourceView = host.view
      pop.sourceRect = CGRect(x: host.view.bounds.midX, y: host.view.bounds.midY, width: 1, height: 1)
    }
    host.present(sheet, animated: true)
  }

  /// "Create Picture" in the Camera inspector: renders at the project's configured pixel size.
  static func createPicture(from host: UIViewController, node: ProjectTreeNode, render: RenderViewController?)
  {
    guard let project = node.representedObject.project as? ProjectStructureNode else { return }
    let size = max(project.renderImageNumberOfPixels, 64)
    share(from: host, items: pictureFiles(node: node, render: render, size: size))
  }

  /// "Create Movie" in the Camera inspector: honors the project's movie type.
  static func createMovie(from host: UIViewController, node: ProjectTreeNode)
  {
    guard let project = node.representedObject.project as? ProjectStructureNode else { return }
    exportMovie(from: host, node: node, kind: project.movieType)
  }

  private static func share(from host: UIViewController, items: [Any])
  {
    guard !items.isEmpty else { return }
    let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
    if let pop = sheet.popoverPresentationController
    {
      pop.sourceView = host.view
      pop.sourceRect = CGRect(x: host.view.bounds.midX, y: host.view.bounds.midY, width: 1, height: 1)
    }
    host.present(sheet, animated: true)
  }

  private static func structureFiles(node: ProjectTreeNode, includeCIF: Bool, includePDB: Bool, includeXYZ: Bool, includeMMCIF: Bool = false) -> [Any]
  {
    guard let project = node.representedObject.project as? ProjectStructureNode,
          let structure = project.allObjects.compactMap({ $0 as? Structure }).first else { return [] }
    let atoms = structure.atomTreeController.flattenedLeafNodes().compactMap { $0.representedObject }
    var items: [Any] = []
    if includeCIF
    {
      let cif = SKCIFWriter.shared.string(displayName: node.displayName, spaceGroupHallNumber: structure.spaceGroupHallNumber, cell: structure.cell, atoms: atoms, exportFractional: true, origin: SIMD3<Double>(0, 0, 0))
      let cifURL = FileManager.default.temporaryDirectory.appendingPathComponent(node.displayName + ".cif")
      try? cif.write(to: cifURL, atomically: true, encoding: .utf8)
      items.append(cifURL)
    }
    if includePDB
    {
      let pdb = SKPDBWriter.shared.string(displayName: node.displayName, spaceGroupHallNumber: structure.spaceGroupHallNumber, cell: structure.cell, atoms: atoms, origin: SIMD3<Double>(0, 0, 0))
      let pdbURL = FileManager.default.temporaryDirectory.appendingPathComponent(node.displayName + ".pdb")
      try? pdb.write(to: pdbURL, atomically: true, encoding: .utf8)
      items.append(pdbURL)
    }
    if includeMMCIF
    {
      let fractional = !(structure is Protein || structure is Molecule)
      let mmcif = SKmmCIFWriter.shared.string(displayName: node.displayName, spaceGroupHallNumber: structure.spaceGroupHallNumber, cell: structure.cell, atoms: atoms, atomsAreFractional: fractional, exportFractional: fractional, withProteinInfo: structure is Protein || structure is ProteinCrystal, origin: SIMD3<Double>(0, 0, 0))
      let mmcifURL = FileManager.default.temporaryDirectory.appendingPathComponent(node.displayName + ".mmcif")
      try? mmcif.write(to: mmcifURL, atomically: true, encoding: .utf8)
      items.append(mmcifURL)
    }
    if includeXYZ
    {
      let origin: SIMD3<Double>
      if structure is Protein || structure is Molecule
      {
        origin = structure.cell.boundingBox.minimum
      }
      else
      {
        origin = SIMD3<Double>(0, 0, 0)
      }
      let xyzAtoms: [(elementIdentifier: Int, position: SIMD3<Double>)] = atoms.map { atom in
        (atom.elementIdentifier, structure.absoluteCartesianModelPosition(for: atom.position, replicaPosition: SIMD3<Int32>()))
      }
      let comment: String
      if !(structure is Protein || structure is Molecule)
      {
        let unitCell = structure.cell.unitCell
        comment = "Lattice=\"\(unitCell[0][0]) \(unitCell[0][1]) \(unitCell[0][2]) \(unitCell[1][0]) \(unitCell[1][1]) \(unitCell[1][2]) \(unitCell[2][0]) \(unitCell[2][1]) \(unitCell[2][2])\" "
      }
      else
      {
        comment = node.displayName
      }
      let xyz = SKXYZWriter.shared.string(displayName: node.displayName, commentString: comment, atoms: xyzAtoms, origin: origin)
      let xyzURL = FileManager.default.temporaryDirectory.appendingPathComponent(node.displayName + ".xyz")
      try? xyz.write(to: xyzURL, atomically: true, encoding: .utf8)
      items.append(xyzURL)
    }
    return items
  }

  private static func pictureFiles(node: ProjectTreeNode, render: RenderViewController?, size: Int) -> [Any]
  {
    guard let render = render,
          let project = node.representedObject.project as? ProjectStructureNode,
          let camera = project.renderCamera,
          let png = render.makeThumbnail(size: CGSize(width: size, height: size), camera: camera) else { return [] }
    let pngURL = FileManager.default.temporaryDirectory.appendingPathComponent(node.displayName + ".png")
    try? png.write(to: pngURL)
    return [pngURL]
  }

  private static func exportMovie(from host: UIViewController, node: ProjectTreeNode, kind: ProjectStructureNode.MovieType)
  {
    guard let project = node.representedObject.project as? ProjectStructureNode,
          let liveCamera = project.renderCamera else { return }
    LogQueue.shared.info(destination: nil, message: "Encoding \(kind == .frames ? "trajectory" : "rotation") movie…")
    DispatchQueue.global(qos: .userInitiated).async {
      let url = FileManager.default.temporaryDirectory.appendingPathComponent(node.displayName + ".mp4")
      do
      {
        try writeMovie(project: project, camera: RKCamera(camera: liveCamera), url: url, kind: kind)
        DispatchQueue.main.async {
          LogQueue.shared.info(destination: nil, message: "Movie ready")
          share(from: host, items: [url])
        }
      }
      catch
      {
        DispatchQueue.main.async {
          LogQueue.shared.error(destination: nil, message: "Movie export failed: \(error.localizedDescription)")
        }
      }
    }
  }

  private static func writeMovie(project: ProjectStructureNode, camera: RKCamera, url: URL, kind: ProjectStructureNode.MovieType) throws
  {
    try? FileManager.default.removeItem(at: url)
    let size = CGSize(width: 1024, height: 1024)
    camera.updateCameraForWindowResize(width: Double(size.width), height: Double(size.height))
    project.renderBackgroundCachedImage = project.drawGradientCGImage()
    guard let device = MTLCreateSystemDefaultDevice() else {
      throw CocoaError(.fileWriteUnknown)
    }
    let fps: Int32 = Int32(max(project.numberOfFramesPerSecond, 5))
    let settings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: size.width,
      AVVideoHeightKey: size.height
    ]
    let writer = try AVAssetWriter(url: url, fileType: .mp4)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    input.expectsMediaDataInRealTime = false
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
      kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
    ])
    writer.add(input)
    guard writer.startWriting() else {
      throw writer.error ?? CocoaError(.fileWriteUnknown)
    }
    writer.startSession(atSourceTime: .zero)
    let renderer = MetalRenderer(device: device, size: size, dataSource: project, camera: camera)
    var frameNumber: Int64 = 0

    func appendFrame()
    {
      while !input.isReadyForMoreMediaData
      {
        Thread.sleep(forTimeInterval: 0.01)
      }
      guard let pixelBuffer = makePixelBuffer(width: Int(size.width), height: Int(size.height)),
            let data = renderer.renderPictureData(device: device, size: size, camera: camera, imageQuality: .rgb_8_bits, renderQuality: .picture) else { return }
      CVPixelBufferLockBaseAddress(pixelBuffer, [])
      if let dest = CVPixelBufferGetBaseAddress(pixelBuffer)?.assumingMemoryBound(to: UInt8.self)
      {
        data.copyBytes(to: dest, count: min(data.count, CVPixelBufferGetDataSize(pixelBuffer)))
      }
      CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
      adaptor.append(pixelBuffer, withPresentationTime: CMTime(value: frameNumber, timescale: fps))
      frameNumber += 1
    }

    switch kind
    {
    case .frames:
      var saved = 0
      DispatchQueue.main.sync {
        saved = currentFrameIndex(project)
        project.sceneList.setAllMovieFramesToBeginning()
      }
      let count = max(project.sceneList.maximumNumberOfFrames ?? 1, 1)
      for _ in 0..<count
      {
        appendFrame()
        DispatchQueue.main.sync {
          project.sceneList.advanceAllMovieFrames()
        }
      }
      DispatchQueue.main.sync {
        project.sceneList.synchronizeAllMovieFrames(to: saved)
      }
    case .rotationY, .rotationXYlemniscate:
      for _ in stride(from: 0, through: 360, by: 3)
      {
        appendFrame()
        camera.rotateCameraAroundAxisY(angle: -3.0 * .pi / 180.0)
      }
    }

    while !input.isReadyForMoreMediaData
    {
      Thread.sleep(forTimeInterval: 0.01)
    }
    input.markAsFinished()
    let done = DispatchSemaphore(value: 0)
    writer.finishWriting { done.signal() }
    _ = done.wait(timeout: .now() + 30)
    if writer.status != .completed
    {
      throw writer.error ?? CocoaError(.fileWriteUnknown)
    }
  }

  private static func currentFrameIndex(_ project: ProjectStructureNode) -> Int
  {
    let movies = project.sceneList.scenes.flatMap { $0.movies }
    guard let movie = movies.first(where: { $0.selectedFrame != nil }) ?? movies.first,
          let selected = movie.selectedFrame,
          let index = movie.frames.firstIndex(of: selected) else { return 0 }
    return index
  }

  private static func makePixelBuffer(width: Int, height: Int) -> CVPixelBuffer?
  {
    var buffer: CVPixelBuffer?
    let attrs: [CFString: Any] = [
      kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
      kCVPixelBufferWidthKey: width,
      kCVPixelBufferHeightKey: height,
      kCVPixelBufferMetalCompatibilityKey: true
    ]
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs as CFDictionary, &buffer)
    return buffer
  }
}
