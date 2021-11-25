/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2021 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 S.Calero@tue.nl         https://www.tue.nl/en/research/researchers/sofia-calero/
 t.j.h.vlugt@tudelft.nl  http://homepage.tudelft.nl/v9k6y
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

import Foundation
import iRASPAKit
import SymmetryKit
import SimulationKit
import RenderKit

class Project
{
  var projectStructureNode: ProjectStructureNode
  
  var parser: SKParser
  var colorSets: SKColorSets = SKColorSets()
  var forceFieldSets: SKForceFieldSets = SKForceFieldSets()
  
  init?(url: URL, onlyAsymmetricUnit: Bool, asMolecule: Bool)
  {
    let displayName: String = (url.lastPathComponent as NSString).deletingPathExtension
    
    guard let data: Data = try? Data(contentsOf: url) else {return nil}
    
    do
    {      
      switch(url.pathExtension)
      {
      case "cif":
        guard let parser = try? SKCIFParser(displayName: displayName, data: data, windowController: nil, onlyAsymmetricUnit: onlyAsymmetricUnit) else {return nil}
        self.parser = parser
      case "pdb":
        guard let parser = try? SKPDBParser(displayName: displayName, data: data, windowController: nil, onlyAsymmetricUnitMolecule: onlyAsymmetricUnit, onlyAsymmetricUnitProtein: onlyAsymmetricUnit, asMolecule: asMolecule, asProtein: asMolecule) else {return nil}
        self.parser = parser
      case "xyz":
        guard let parser = try? SKXYZParser(displayName: displayName, data: data, windowController: nil) else {return nil}
        self.parser = parser
      default:
        fatalError("Unknown structure")
      }
      
      try parser.startParsing()
      
      let scene: Scene = Scene(parser: parser.scene)
      let sceneList: SceneList = SceneList(name: displayName, scenes: [scene])
      projectStructureNode=ProjectStructureNode(name: displayName, sceneList: sceneList)
      
      projectStructureNode.sceneList.allObjects.compactMap({$0 as? Structure}).forEach{$0.setRepresentationStyle(style: .default, colorSets: colorSets)}
      projectStructureNode.sceneList.allObjects.compactMap({$0 as? Structure}).forEach{$0.setRepresentationForceField(forceField: "Default", forceFieldSets: forceFieldSets)}
      
      projectStructureNode.sceneList.allObjects.compactMap({$0 as? Structure}).forEach{$0.reComputeBonds()}
      
      projectStructureNode.sceneList.allObjects.compactMap({$0 as? Structure}).forEach{$0.recomputeDensityProperties()}
      
    }
    catch let error
    {
      print("Error: \(error.localizedDescription)")
      return nil
    }
    
  }
  
  public var voidFractions: [Double]
  {
    return SKVoidFraction.compute(structures: projectStructureNode.sceneList.allAdsorptionSurfaceStructures)
  }
  
  public var surfaceAreas: ([Double], [Double])
  {
    return SKNitrogenSurfaceArea.compute(structures: projectStructureNode.sceneList.allAdsorptionSurfaceStructures)
  }
  
  var makePicture: Data
  {
    let camera: RKCamera = RKCamera()
   
    projectStructureNode.setInitialSelectionIfNeeded()
    
    projectStructureNode.renderBackgroundCachedImage = projectStructureNode.drawGradientCGImage()
      
    camera.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
      
    camera.updateCameraForWindowResize(width: Double(512), height: Double(512))
    camera.resetCameraDistance()
    
    let size: CGSize = CGSize.init(width: 512, height: 512)
    let imagePhysicalSizeInInches: Double = projectStructureNode.renderImagePhysicalSizeInInches
    
    if let device = MTLCreateSystemDefaultDevice()
    {
      let renderer: MetalRenderer = MetalRenderer(device: device, size: size, dataSource: projectStructureNode, camera: camera)
      
      if let data: Data = renderer.renderPicture(device: device, size: size, imagePhysicalSizeInInches: imagePhysicalSizeInInches, camera: camera, imageQuality: RKImageQuality.rgb_8_bits, renderQuality: .picture)
      {
        return data
      }
    }
    
    return Data()
  }
}
