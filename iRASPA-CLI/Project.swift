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
    
    let string: String
    do
    {
      string = try String(contentsOf: url, encoding: String.Encoding.utf8)
      
      switch(url.pathExtension)
      {
      case "cif":
        parser = SKCIFParser(displayName: displayName, string: string, windowController: nil, onlyAsymmetricUnit: onlyAsymmetricUnit)
      case "pdb":
        parser = SKPDBParser(displayName: displayName, string: string, windowController: nil, onlyAsymmetricUnit: onlyAsymmetricUnit, asMolecule: asMolecule)
        break
      case "xyz":
        parser = SKXYZParser(displayName: displayName, string: string, windowController: nil)
        break
      default:
        fatalError("Unknown structure")
      }
      
      try parser.startParsing()
      
      let scene: Scene = Scene(parser: parser.scene)
      let sceneList: SceneList = SceneList(name: displayName, scenes: [scene])
      projectStructureNode=ProjectStructureNode(name: displayName, sceneList: sceneList)
      
      projectStructureNode.sceneList.allStructures.forEach{$0.setRepresentationStyle(style: .default, colorSets: colorSets)}
      projectStructureNode.sceneList.allStructures.forEach{$0.setRepresentationForceField(forceField: "Default", forceFieldSets: forceFieldSets)}
      
      projectStructureNode.sceneList.allStructures.forEach{$0.reComputeBonds()}
      
      projectStructureNode.sceneList.allStructures.forEach{$0.recomputeDensityProperties()}
      
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
    let bundle: Bundle = Bundle(for: MetalRenderer.self)
    
    if let device = MTLCreateSystemDefaultDevice(),
       let _: MTLCommandQueue = device.makeCommandQueue(),
       let file: String = bundle.path(forResource: "default", ofType: "metallib")
    {
      print("Metal")
      let renderer: MetalRenderer = MetalRenderer()
      
      let defaultLibrary = try! device.makeLibrary(filepath: file)
      renderer.buildPipeLines(device: device, defaultLibrary, maximumNumberOfSamples: 8)
       
       
      renderer.buildTextures(device: device, size: CGSize(width: 400, height: 400), maximumNumberOfSamples: 8)
      renderer.buildVertexBuffers(device: device)
       
      renderer.backgroundShader.buildPermanentTextures(device: device)
      return Data()
    }
    else
    {
      return Data()
    }
  }
}
