/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
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

import Cocoa
import simd
import RenderKit
import MathKit
import iRASPAKit
import SymmetryKit
import SimulationKit
import LogViewKit

// CellViewer

class StructureCellDetailViewController: NSViewController, NSOutlineViewDelegate, WindowControllerConsumer, ProjectConsumer
{
  @IBOutlet private weak var cellOutlineView: NSStaticViewBasedOutlineView?
 
  weak var windowController: iRASPAWindowController?
  
  var iRASPAObjects: [iRASPAObject] = []
  
  var cellAngleFormatter: AngleNumberFormatter = AngleNumberFormatter()
  
  // MARK: protocol ProjectConsumer
  // =====================================================================
  
  weak var proxyProject: ProjectTreeNode?
    
  
  let boxMaterialInfoCell: OutlineViewItem = OutlineViewItem("BoxMaterialInfoCell")
  let boxBoundingBoxInfoCell: OutlineViewItem = OutlineViewItem("BoxBoundingBoxInfoCell")
  let boxUnitCellPropertiesCell: OutlineViewItem = OutlineViewItem("BoxUnitCellPropertiesCell")
  let boxUnitCellInfoCell: OutlineViewItem = OutlineViewItem("BoxUnitCellInfoCell")
  let boxVolumeCell: OutlineViewItem = OutlineViewItem("BoxVolumeCell")
  let boxReplicasCell: OutlineViewItem = OutlineViewItem("BoxReplicasCell")
  let boxOrientationCell: OutlineViewItem = OutlineViewItem("BoxOrientationCell")
  let boxOriginCell: OutlineViewItem = OutlineViewItem("BoxOriginCell")
  
  let transformContentCell: OutlineViewItem = OutlineViewItem("TransformContentCell")
  
  let structuralPropertiesCell: OutlineViewItem = OutlineViewItem("StructuralPropertiesCell")
  let structuralProbeCell: OutlineViewItem = OutlineViewItem("StructuralProbeCell")
  let structuralChannelCell: OutlineViewItem = OutlineViewItem("StructuralChannelCell")
  
  let symmetrySpaceGroupCell: OutlineViewItem = OutlineViewItem("SymmetrySpaceGroupCell")
  let symmetryCenteringCell: OutlineViewItem = OutlineViewItem("SymmetryCenteringCell")
  let symmetryPropertiesCell: OutlineViewItem = OutlineViewItem("SymmetryPropertiesCell")
  
  
  // ViewDidLoad: bounds are not yet set (do not do geometry-related etup here)
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    // check that it works with strong-references off (for compatibility with 'El Capitan')
    self.cellOutlineView?.stronglyReferencesItems = false
    
    // add viewMaxXMargin: necessary to avoid LAYOUT_CONSTRAINTS_NOT_SATISFIABLE during swiping
    self.view.autoresizingMask = [.height, .width, .maxXMargin]
    
    let cellStructureItem: OutlineViewItem =  OutlineViewItem(title: "BoxGroup", children: [boxMaterialInfoCell, boxBoundingBoxInfoCell, boxUnitCellPropertiesCell, boxUnitCellInfoCell, boxVolumeCell, boxReplicasCell, boxOrientationCell, boxOriginCell])
    
    let cellContentTransformItem: OutlineViewItem = OutlineViewItem(title: "TransformContentGroup", children: [transformContentCell])
    
    let structuralPropertiesItem: OutlineViewItem = OutlineViewItem(title: "StructuralGroup", children: [structuralPropertiesCell, structuralProbeCell, structuralChannelCell])
    
    let symmetryItem: OutlineViewItem = OutlineViewItem(title: "SymmetryGroup", children: [symmetrySpaceGroupCell, symmetryCenteringCell, symmetryPropertiesCell])
    
    self.cellOutlineView?.items = [cellStructureItem, cellContentTransformItem, structuralPropertiesItem, symmetryItem]
    
  }
  
  override func viewWillAppear()
  {
    self.cellOutlineView?.needsLayout = true
    super.viewWillAppear()
  }

  override func viewDidAppear()
  {
    super.viewDidAppear()
   
    NotificationCenter.default.addObserver(self, selector: #selector(StructureCellDetailViewController.reloadData), name: NSNotification.Name(rawValue: NotificationStrings.SpaceGroupShouldReloadNotification), object: self.windowController)
  }
  
  // the windowController still exists when the view is there
  override func viewWillDisappear()
  {
    super.viewWillDisappear()
    
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationStrings.SpaceGroupShouldReloadNotification), object: self.windowController)
  }
  
  
  var expandedItems: [Bool] = [false,false,false,false,false,false,false,false]
  
  func storeExpandedItems()
  {
    if let outlineView = self.cellOutlineView
    {
      for i in 0..<outlineView.items.count
      {
        self.expandedItems[i] = outlineView.isItemExpanded(outlineView.items[i])
      }
    }
  }
  
  @objc func reloadData()
  {
    assert(Thread.isMainThread)
    
    self.cellOutlineView?.reloadData()
    
    NSAnimationContext.runAnimationGroup({context in
      context.duration = 0
    
      if let outlineView = self.cellOutlineView
      {
        for i in 0..<outlineView.items.count
        {
          if (self.expandedItems[i])
          {
            self.cellOutlineView?.expandItem(outlineView.items[i])
          }
          else
          {
            self.cellOutlineView?.collapseItem(outlineView.items[i])
          }
        }
      }
    }, completionHandler: {})
  }
  
  // MARK: NSOutlineView notifications for expanding/collapsing items
  // =====================================================================
  
  
  
  
  func outlineViewItemDidExpand(_ notification:Notification)
  {
    let dictionary: AnyObject  = notification.userInfo?["NSObject"] as AnyObject
    if let index: Int = self.cellOutlineView?.childIndex(forItem: dictionary)
    {
      self.expandedItems[index] = true
    }
  }
  
  
  func outlineViewItemDidCollapse(_ notification:Notification)
  {
    let dictionary: AnyObject  = notification.userInfo?["NSObject"] as AnyObject
    if let index: Int = self.cellOutlineView?.childIndex(forItem: dictionary)
    {
      self.expandedItems[index] = false
    }
  }
  
  
  
  // MARK: NSTableView Delegate Methods
  // =====================================================================
  
  func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool
  {
    return true
  }
  
  func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool
  {
    return false
  }
  
  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView?
  {
    if let rowView: CellTableRowView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cellTableRowView"), owner: self) as? CellTableRowView
    {
      return rowView
    }
    return nil
  }
  
 
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
  {
    if let string: String = (item as? OutlineViewItem)?.title,
      let view: NSTableCellView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: string), owner: self) as? NSTableCellView
    {
      let enabled: Bool = proxyProject?.isEnabled ?? false
      
      setPropertiesBoxTableCells(on: view, identifier: string, enabled: enabled)
      setPropertiesTransformTableCells(on: view, identifier: string, enabled: enabled)
      setPropertiesStructuralTableCells(on: view, identifier: string, enabled: enabled)
      setPropertiesSymmetryTableCells(on: view, identifier: string, enabled: enabled)
      
      return view
    }
    return nil
  }
  
  func setPropertiesBoxTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    switch(identifier)
    {
    case "BoxMaterialInfoCell":
      if let popUpbuttonRepresentationType: iRASPAPopUpButton = view.viewWithTag(1) as? iRASPAPopUpButton
      {
        popUpbuttonRepresentationType.isEditable = false
        popUpbuttonRepresentationType.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          popUpbuttonRepresentationType.isEnabled = enabled
          popUpbuttonRepresentationType.isEditable = enabled
          
          popUpbuttonRepresentationType.autoenablesItems = false
          if let item = popUpbuttonRepresentationType.item(at: SKStructure.Kind.unknown.rawValue)
          {
            item.isEnabled = false
          }
          if let item = popUpbuttonRepresentationType.item(at: SKStructure.Kind.structure.rawValue)
          {
            item.isEnabled = false
          }
          if let item = popUpbuttonRepresentationType.item(at: SKStructure.Kind.proteinCrystalSolvent.rawValue)
          {
            item.isEnabled = false
          }
          if let item = popUpbuttonRepresentationType.item(at: SKStructure.Kind.crystalSolvent.rawValue)
          {
            item.isEnabled = false
          }
          if let item = popUpbuttonRepresentationType.item(at: SKStructure.Kind.molecularCrystalSolvent.rawValue)
          {
            item.isEnabled = false
          }
          
          if let rawValue = self.renderMaterialType?.rawValue
          {
            popUpbuttonRepresentationType.removeItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            popUpbuttonRepresentationType.selectItem(at: rawValue)
          }
          else
          {
            popUpbuttonRepresentationType.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
        
      }
    case "BoxBoundingBoxInfoCell":
      if let textFieldMaximumX: NSTextField = view.viewWithTag(1) as? NSTextField,
         let textFieldMaximumY: NSTextField = view.viewWithTag(2) as? NSTextField,
         let textFieldMaximumZ: NSTextField = view.viewWithTag(3) as? NSTextField,
         let textFieldMinimumX: NSTextField = view.viewWithTag(4) as? NSTextField,
         let textFieldMinimumY: NSTextField = view.viewWithTag(5) as? NSTextField,
         let textFieldMinimumZ: NSTextField = view.viewWithTag(6) as? NSTextField
      {
        textFieldMaximumX.isEditable = false
        textFieldMaximumY.isEditable = false
        textFieldMaximumZ.isEditable = false
        textFieldMinimumX.isEditable = false
        textFieldMinimumY.isEditable = false
        textFieldMinimumZ.isEditable = false
        textFieldMaximumX.stringValue = ""
        textFieldMaximumY.stringValue = ""
        textFieldMaximumZ.stringValue = ""
        textFieldMinimumX.stringValue = ""
        textFieldMinimumY.stringValue = ""
        textFieldMinimumZ.stringValue = ""
        if let project = proxyProject?.representedObject.loadedProjectStructureNode,
           let camera: RKCamera = project.renderCamera,
          !iRASPAObjects.isEmpty
        {
          textFieldMaximumX.doubleValue = self.renderBoundingBoxMaximumX ?? camera.boundingBox.maximum.x
          textFieldMaximumY.doubleValue = self.renderBoundingBoxMaximumY ?? camera.boundingBox.maximum.y
          textFieldMaximumZ.doubleValue = self.renderBoundingBoxMaximumZ ?? camera.boundingBox.maximum.z
          textFieldMinimumX.doubleValue = self.renderBoundingBoxMinimumX ?? camera.boundingBox.minimum.x
          textFieldMinimumY.doubleValue = self.renderBoundingBoxMinimumY ?? camera.boundingBox.minimum.y
          textFieldMinimumZ.doubleValue = self.renderBoundingBoxMinimumZ ?? camera.boundingBox.minimum.z
        }
      }
    case "BoxUnitCellPropertiesCell":
      if let textFieldLengthA: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldLengthA.isEditable = false
        textFieldLengthA.stringValue = ""
        textFieldLengthA.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldLengthA.isEnabled = enabled
          textFieldLengthA.isEditable = enabled
          if let renderLengthA: Double = self.renderUnitCellLengthA
          {
            textFieldLengthA.doubleValue = renderLengthA
          }
          else
          {
            textFieldLengthA.stringValue = NSLocalizedString("Mult. V.", comment: "")
          }
        }
      }
      if let textFieldLengthB: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldLengthB.isEditable = false
        textFieldLengthB.stringValue = ""
        textFieldLengthB.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldLengthB.isEnabled = enabled
          textFieldLengthB.isEditable = enabled
          if let renderLengthB: Double = self.renderUnitCellLengthB
          {
            textFieldLengthB.doubleValue = renderLengthB
          }
          else
          {
            textFieldLengthB.stringValue = NSLocalizedString("Mult. V.", comment: "")
          }
        }
      }
      if let textFieldLengthC: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldLengthC.isEditable = false
        textFieldLengthC.stringValue = ""
        textFieldLengthC.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldLengthC.isEnabled = enabled
          textFieldLengthC.isEditable = enabled
          if let renderLengthC: Double = self.renderUnitCellLengthC
          {
            textFieldLengthC.doubleValue = renderLengthC
          }
          else
          {
            textFieldLengthC.stringValue = NSLocalizedString("Mult. V.", comment: "")
          }
        }
      }
      
      if let textFieldAlphaAngle: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldAlphaAngle.isEditable = false
        textFieldAlphaAngle.stringValue = ""
        textFieldAlphaAngle.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldAlphaAngle.formatter = cellAngleFormatter
          textFieldAlphaAngle.isEnabled = enabled
          textFieldAlphaAngle.isEditable = enabled
          if let renderAlphaAngle: Double = self.renderUnitCellAlphaAngle
          {
            textFieldAlphaAngle.doubleValue = renderAlphaAngle
          }
          else
          {
            textFieldAlphaAngle.stringValue = "M.V."
          }
        }
      }
      if let textFieldBetaAngle: NSTextField = view.viewWithTag(5) as? NSTextField
      {
        textFieldBetaAngle.isEditable = false
        textFieldBetaAngle.stringValue = ""
        textFieldBetaAngle.isEnabled = false
        textFieldBetaAngle.formatter = cellAngleFormatter
        if !iRASPAObjects.isEmpty
        {
          textFieldBetaAngle.isEnabled = enabled
          textFieldBetaAngle.isEditable = enabled
          if let renderBetaAngle: Double = self.renderUnitCellBetaAngle
          {
            textFieldBetaAngle.doubleValue = renderBetaAngle
          }
          else
          {
            textFieldBetaAngle.stringValue = "M.V."
          }
        }
      }
      if let textFieldGammaAngle: NSTextField = view.viewWithTag(6) as? NSTextField
      {
        textFieldGammaAngle.isEditable = false
        textFieldGammaAngle.stringValue = ""
        textFieldGammaAngle.isEnabled = false
        textFieldGammaAngle.formatter = cellAngleFormatter
        if !iRASPAObjects.isEmpty
        {
          textFieldGammaAngle.isEnabled = enabled
          textFieldGammaAngle.isEditable = enabled
          if let renderGammaAngle: Double = self.renderUnitCellGammaAngle
          {
            textFieldGammaAngle.doubleValue = renderGammaAngle
          }
          else
          {
            textFieldGammaAngle.stringValue = "M.V."
          }
        }
      }
      
      if let stepperLengthA: NSStepper = view.viewWithTag(7) as? NSStepper,
         let stepperLengthB: NSStepper = view.viewWithTag(8) as? NSStepper,
         let stepperLengthC: NSStepper = view.viewWithTag(9) as? NSStepper,
         let stepperAngleAlpha: NSStepper = view.viewWithTag(10) as? NSStepper,
         let stepperAngleBeta: NSStepper = view.viewWithTag(11) as? NSStepper,
         let stepperAngleGamma: NSStepper = view.viewWithTag(12) as? NSStepper
      {
        stepperLengthA.isEnabled = false
        stepperLengthB.isEnabled = false
        stepperLengthC.isEnabled = false
        stepperAngleAlpha.isEnabled = false
        stepperAngleBeta.isEnabled = false
        stepperAngleGamma.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          stepperLengthA.isEnabled = enabled
          stepperLengthB.isEnabled = enabled
          stepperLengthC.isEnabled = enabled
          stepperAngleAlpha.isEnabled = enabled
          stepperAngleBeta.isEnabled = enabled
          stepperAngleGamma.isEnabled = enabled
        }
      }
    case "BoxUnitCellInfoCell":
      if let textFieldRenderUnitCellAX: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldRenderUnitCellAX.isEditable = false
        textFieldRenderUnitCellAX.stringValue = ""
        textFieldRenderUnitCellAX.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldRenderUnitCellAX.isEnabled = enabled
          if let renderUnitCellAX: Double = self.renderUnitCellAX
          {
            textFieldRenderUnitCellAX.doubleValue = renderUnitCellAX
          }
          else
          {
            textFieldRenderUnitCellAX.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldRenderUnitCellAY: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldRenderUnitCellAY.isEditable = false
        textFieldRenderUnitCellAY.stringValue = ""
        textFieldRenderUnitCellAY.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldRenderUnitCellAY.isEnabled = enabled
          if let renderUnitCellAY: Double = self.renderUnitCellAY
          {
            textFieldRenderUnitCellAY.doubleValue = renderUnitCellAY
          }
          else
          {
            textFieldRenderUnitCellAY.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldRenderUnitCellAZ: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldRenderUnitCellAZ.isEditable = false
        textFieldRenderUnitCellAZ.stringValue = ""
        textFieldRenderUnitCellAZ.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldRenderUnitCellAZ.isEnabled = enabled
          if let renderUnitCellAZ: Double = self.renderUnitCellAZ
          {
            textFieldRenderUnitCellAZ.doubleValue = renderUnitCellAZ
          }
          else
          {
            textFieldRenderUnitCellAZ.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      
      if let textFieldRenderUnitCellBX: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldRenderUnitCellBX.isEditable = false
        textFieldRenderUnitCellBX.stringValue = ""
        textFieldRenderUnitCellBX.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldRenderUnitCellBX.isEnabled = enabled
          if let renderUnitCellBX: Double = self.renderUnitCellBX
          {
            textFieldRenderUnitCellBX.doubleValue = renderUnitCellBX
          }
          else
          {
            textFieldRenderUnitCellBX.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldRenderUnitCellBY: NSTextField = view.viewWithTag(5) as? NSTextField
      {
        textFieldRenderUnitCellBY.isEditable = false
        textFieldRenderUnitCellBY.stringValue = ""
        textFieldRenderUnitCellBY.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldRenderUnitCellBY.isEnabled = enabled
          if let renderUnitCellBY: Double = self.renderUnitCellBY
          {
            textFieldRenderUnitCellBY.doubleValue = renderUnitCellBY
          }
          else
          {
            textFieldRenderUnitCellBY.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldRenderUnitCellBZ: NSTextField = view.viewWithTag(6) as? NSTextField
      {
        textFieldRenderUnitCellBZ.isEditable = false
        textFieldRenderUnitCellBZ.stringValue = ""
        textFieldRenderUnitCellBZ.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldRenderUnitCellBZ.isEnabled = enabled
          if let renderUnitCellBZ: Double = self.renderUnitCellBZ
          {
            textFieldRenderUnitCellBZ.doubleValue = renderUnitCellBZ
          }
          else
          {
            textFieldRenderUnitCellBZ.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      
      if let textFieldRenderUnitCellCX: NSTextField = view.viewWithTag(7) as? NSTextField
      {
        textFieldRenderUnitCellCX.isEditable = false
        textFieldRenderUnitCellCX.stringValue = ""
        textFieldRenderUnitCellCX.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldRenderUnitCellCX.isEnabled = enabled
          if let renderUnitCellCX: Double = self.renderUnitCellCX
          {
            textFieldRenderUnitCellCX.doubleValue = renderUnitCellCX
          }
          else
          {
            textFieldRenderUnitCellCX.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldRenderUnitCellCY: NSTextField = view.viewWithTag(8) as? NSTextField
      {
        textFieldRenderUnitCellCY.isEditable = false
        textFieldRenderUnitCellCY.stringValue = ""
        textFieldRenderUnitCellCY.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldRenderUnitCellCY.isEnabled = enabled
          if let renderUnitCellCY: Double = self.renderUnitCellCY
          {
            textFieldRenderUnitCellCY.doubleValue = renderUnitCellCY
          }
          else
          {
            textFieldRenderUnitCellCY.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldRenderUnitCellCZ: NSTextField = view.viewWithTag(9) as? NSTextField
      {
        textFieldRenderUnitCellCZ.isEditable = false
        textFieldRenderUnitCellCZ.stringValue = ""
        textFieldRenderUnitCellCZ.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldRenderUnitCellCZ.isEnabled = enabled
          if let renderUnitCellCZ: Double = self.renderUnitCellCZ
          {
            textFieldRenderUnitCellCZ.doubleValue = renderUnitCellCZ
          }
          else
          {
            textFieldRenderUnitCellCZ.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
    case "BoxVolumeCell":
      if let textFieldVolume: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldVolume.isEditable = false
        textFieldVolume.stringValue = ""
        textFieldVolume.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldVolume.isEnabled = enabled
          if let renderUnitCellVolume: Double = self.renderCellVolume
          {
            textFieldVolume.doubleValue = renderUnitCellVolume
          }
          else
          {
            textFieldVolume.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      
      if let textFieldPerpendicularWidthX: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldPerpendicularWidthX.isEditable = false
        textFieldPerpendicularWidthX.stringValue = ""
        textFieldPerpendicularWidthX.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldPerpendicularWidthX.isEnabled = enabled
          if let renderPerpendicularWidthX: Double = self.renderCellPerpendicularWidthX
          {
            textFieldPerpendicularWidthX.doubleValue = renderPerpendicularWidthX
          }
          else
          {
            textFieldPerpendicularWidthX.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldPerpendicularWidthY: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldPerpendicularWidthY.isEditable = false
        textFieldPerpendicularWidthY.stringValue = ""
        textFieldPerpendicularWidthY.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldPerpendicularWidthY.isEnabled = enabled
          if let renderPerpendicularWidthY: Double = self.renderCellPerpendicularWidthY
          {
            textFieldPerpendicularWidthY.doubleValue = renderPerpendicularWidthY
          }
          else
          {
            textFieldPerpendicularWidthY.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldPerpendicularWidthZ: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldPerpendicularWidthZ.isEditable = false
        textFieldPerpendicularWidthZ.stringValue = ""
        textFieldPerpendicularWidthZ.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldPerpendicularWidthZ.isEnabled = enabled
          if let renderPerpendicularWidthZ: Double = self.renderCellPerpendicularWidthZ
          {
            textFieldPerpendicularWidthZ.doubleValue = renderPerpendicularWidthZ
          }
          else
          {
            textFieldPerpendicularWidthZ.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
    case "BoxReplicasCell":
      if let textFieldMaximumReplicaX: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldMaximumReplicaX.isEditable = false
        textFieldMaximumReplicaX.stringValue = ""
        textFieldMaximumReplicaX.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldMaximumReplicaX.isEnabled = enabled
          textFieldMaximumReplicaX.isEditable = enabled
          if let maximumReplicaX: Int32 = self.renderMaximumReplicaX
          {
            textFieldMaximumReplicaX.intValue = maximumReplicaX
          }
          else
          {
            textFieldMaximumReplicaX.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldMaximumReplicaY: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldMaximumReplicaY.isEditable = false
        textFieldMaximumReplicaY.stringValue = ""
        textFieldMaximumReplicaY.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldMaximumReplicaY.isEnabled = enabled
          textFieldMaximumReplicaY.isEditable = enabled
          if let maximumReplicaY: Int32 = self.renderMaximumReplicaY
          {
            textFieldMaximumReplicaY.intValue = maximumReplicaY
          }
          else
          {
            textFieldMaximumReplicaY.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldMaximumReplicaZ: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldMaximumReplicaZ.isEditable = false
        textFieldMaximumReplicaZ.stringValue = ""
        textFieldMaximumReplicaZ.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldMaximumReplicaZ.isEnabled = enabled
          textFieldMaximumReplicaZ.isEditable = enabled
          if let maximumReplicaZ: Int32 = self.renderMaximumReplicaZ
          {
            textFieldMaximumReplicaZ.intValue = maximumReplicaZ
          }
          else
          {
            textFieldMaximumReplicaZ.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }

      if let textFieldMinimumReplicaX: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldMinimumReplicaX.isEditable = false
        textFieldMinimumReplicaX.stringValue = ""
        textFieldMinimumReplicaX.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldMinimumReplicaX.isEnabled = enabled
          textFieldMinimumReplicaX.isEditable = enabled
          if let minimumReplicaX: Int32 = self.renderMinimumReplicaX
          {
            textFieldMinimumReplicaX.intValue =  minimumReplicaX
          }
          else
          {
            textFieldMinimumReplicaX.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldMinimumReplicaY: NSTextField = view.viewWithTag(5) as? NSTextField
      {
        textFieldMinimumReplicaY.isEditable = false
        textFieldMinimumReplicaY.stringValue = ""
        textFieldMinimumReplicaY.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldMinimumReplicaY.isEnabled = enabled
          textFieldMinimumReplicaY.isEditable = enabled
          if let minimumReplicaY: Int32 = self.renderMinimumReplicaY
          {
            textFieldMinimumReplicaY.intValue = minimumReplicaY
          }
          else
          {
            textFieldMinimumReplicaY.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldMinimumReplicaZ: NSTextField = view.viewWithTag(6) as? NSTextField
      {
        textFieldMinimumReplicaZ.isEditable = false
        textFieldMinimumReplicaZ.stringValue = ""
        textFieldMinimumReplicaZ.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          textFieldMinimumReplicaZ.isEnabled = enabled
          textFieldMinimumReplicaZ.isEditable = enabled
          if let minimumReplicaZ: Int32 = self.renderMinimumReplicaZ
          {
            textFieldMinimumReplicaZ.intValue = minimumReplicaZ
          }
          else
          {
            textFieldMinimumReplicaZ.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let stepperMaximumReplicaX: NSStepper = view.viewWithTag(7) as? NSStepper,
         let stepperMaximumReplicaY: NSStepper = view.viewWithTag(8) as? NSStepper,
         let stepperMaximumReplicaZ: NSStepper = view.viewWithTag(9) as? NSStepper,
         let stepperMinimumReplicaX: NSStepper = view.viewWithTag(10) as? NSStepper,
         let stepperMinimumReplicaY: NSStepper = view.viewWithTag(11) as? NSStepper,
         let stepperMinimumReplicaZ: NSStepper = view.viewWithTag(12) as? NSStepper
      {
        stepperMaximumReplicaX.isEnabled = false
        stepperMaximumReplicaY.isEnabled = false
        stepperMaximumReplicaZ.isEnabled = false
        stepperMinimumReplicaX.isEnabled = false
        stepperMinimumReplicaY.isEnabled = false
        stepperMinimumReplicaZ.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          stepperMaximumReplicaX.isEnabled = enabled
          stepperMaximumReplicaY.isEnabled = enabled
          stepperMaximumReplicaZ.isEnabled = enabled
          stepperMinimumReplicaX.isEnabled = enabled
          stepperMinimumReplicaY.isEnabled = enabled
          stepperMinimumReplicaZ.isEnabled = enabled
        }
      }
    case "BoxOrientationCell":
      if let renderRotationDelta: Double = self.renderRotationDelta
      {
        if let textFieldRotationAngle: NSTextField = view.viewWithTag(1) as? NSTextField,
          let textFieldYawPlusX: NSButton = view.viewWithTag(2) as? NSButton,
          let textFieldYawPlusY: NSButton = view.viewWithTag(3) as? NSButton,
          let textFieldYawPlusZ: NSButton = view.viewWithTag(4) as? NSButton,
          let textFieldYawMinusX: NSButton = view.viewWithTag(5) as? NSButton,
          let textFieldYawMinusY: NSButton = view.viewWithTag(6) as? NSButton,
          let textFieldYawMinusZ: NSButton = view.viewWithTag(7) as? NSButton
        {
          textFieldRotationAngle.isEditable = enabled
          textFieldYawPlusX.isEnabled = enabled
          textFieldYawPlusY.isEnabled = enabled
          textFieldYawPlusZ.isEnabled = enabled
          textFieldYawMinusX.isEnabled = enabled
          textFieldYawMinusY.isEnabled = enabled
          textFieldYawMinusZ.isEnabled = enabled
          
          let formatter = MeasurementFormatter()
          formatter.unitStyle = .short
          formatter.unitOptions = .providedUnit
          let minusString = formatter.string(from: Measurement(value: -renderRotationDelta, unit: UnitAngle.degrees))
          let plusString = formatter.string(from: Measurement(value: renderRotationDelta, unit: UnitAngle.degrees))
          
          textFieldRotationAngle.doubleValue = renderRotationDelta
          textFieldYawPlusX.title =  String.localizedStringWithFormat(NSLocalizedString("Rotate (%@)", comment: ""), plusString)
          textFieldYawPlusY.title =  String.localizedStringWithFormat(NSLocalizedString("Rotate (%@)", comment: ""), plusString)
          textFieldYawPlusZ.title =  String.localizedStringWithFormat(NSLocalizedString("Rotate (%@)", comment: ""), plusString)
          textFieldYawMinusX.title =  String.localizedStringWithFormat(NSLocalizedString("Rotate (%@)", comment: ""), minusString)
          textFieldYawMinusY.title =  String.localizedStringWithFormat(NSLocalizedString("Rotate (%@)", comment: ""), minusString)
          textFieldYawMinusZ.title =  String.localizedStringWithFormat(NSLocalizedString("Rotate (%@)", comment: ""), minusString)
        }
      }

      if let textFieldEulerAngleX: NSTextField = view.viewWithTag(8) as? NSTextField,
         let textFieldEulerAngleY: NSTextField = view.viewWithTag(9) as? NSTextField,
         let textFieldEulerAngleZ: NSTextField = view.viewWithTag(10) as? NSTextField,
         let sliderEulerAngleX: NSSlider = view.viewWithTag(11) as? NSSlider,
         let sliderEulerAngleZ: NSSlider = view.viewWithTag(12) as? NSSlider,
         let sliderEulerAngleY: NSSlider = view.viewWithTag(13) as? NSSlider
      {
        sliderEulerAngleX.isEnabled = false
        sliderEulerAngleZ.isEnabled = false
        sliderEulerAngleY.isEnabled = false
        textFieldEulerAngleX.isEditable = false
        textFieldEulerAngleY.isEditable = false
        textFieldEulerAngleZ.isEditable = false
        sliderEulerAngleX.stringValue = ""
        sliderEulerAngleZ.stringValue = ""
        sliderEulerAngleY.stringValue = ""
        textFieldEulerAngleX.stringValue = ""
        textFieldEulerAngleY.stringValue = ""
        textFieldEulerAngleZ.stringValue = ""
        
        if !iRASPAObjects.isEmpty
        {
          if let renderEulerAngleX: Double = self.renderEulerAngleX,
             let renderEulerAngleY: Double = self.renderEulerAngleY,
             let renderEulerAngleZ: Double = self.renderEulerAngleZ
          {
            sliderEulerAngleX.isEnabled = enabled
            sliderEulerAngleZ.isEnabled = enabled
            sliderEulerAngleY.isEnabled = enabled
            textFieldEulerAngleX.isEditable = enabled
            textFieldEulerAngleY.isEditable = enabled
            textFieldEulerAngleZ.isEditable = enabled
            sliderEulerAngleX.doubleValue = renderEulerAngleX * 180.0/Double.pi
            sliderEulerAngleZ.doubleValue = renderEulerAngleZ * 180.0/Double.pi
            sliderEulerAngleY.doubleValue = renderEulerAngleY * 180.0/Double.pi
            textFieldEulerAngleX.doubleValue = renderEulerAngleX * 180.0/Double.pi
            textFieldEulerAngleY.doubleValue = renderEulerAngleZ * 180.0/Double.pi
            textFieldEulerAngleZ.doubleValue = renderEulerAngleY * 180.0/Double.pi
          }
          else
          {
            textFieldEulerAngleX.stringValue = NSLocalizedString("Multiple Values", comment: "")
            textFieldEulerAngleY.stringValue = NSLocalizedString("Multiple Values", comment: "")
            textFieldEulerAngleZ.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
    case "BoxOriginCell":
      if let textFieldOriginX: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldOriginX.isEditable = false
        textFieldOriginX.stringValue = ""
        if !iRASPAObjects.isEmpty
        {
          textFieldOriginX.isEditable = enabled
          if let renderOriginX: Double = self.renderOriginX
          {
            textFieldOriginX.doubleValue =  renderOriginX
          }
          else
          {
            textFieldOriginX.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldOriginY: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldOriginY.isEditable = false
        textFieldOriginY.stringValue = ""
        if !iRASPAObjects.isEmpty
        {
          textFieldOriginY.isEditable = enabled
          if let renderOriginY: Double = self.renderOriginY
          {
            textFieldOriginY.doubleValue =  renderOriginY
          }
          else
          {
            textFieldOriginY.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldOriginZ: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldOriginZ.isEditable = false
        textFieldOriginZ.stringValue = ""
        if !iRASPAObjects.isEmpty
        {
          textFieldOriginZ.isEditable = enabled
          if let renderOriginZ: Double = self.renderOriginZ
          {
            textFieldOriginZ.doubleValue =  renderOriginZ
          }
          else
          {
            textFieldOriginZ.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
    default:
      break
    }
  }
  
  func setPropertiesTransformTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    switch(identifier)
    {
    case "TransformContentCell":
      if let button: NSButton = view.viewWithTag(1) as? NSButton
      {
        button.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          button.isEnabled = enabled
          if let renderContentFlipX: Bool = self.renderContentFlipX
          {
            button.allowsMixedState = false
            button.state = renderContentFlipX ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            button.allowsMixedState = true
            button.state = NSControl.StateValue.mixed
          }
        }
      }
      if let button: NSButton = view.viewWithTag(2) as? NSButton
      {
        button.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          button.isEnabled = enabled
          if let renderContentFlipY: Bool = self.renderContentFlipY
          {
            button.allowsMixedState = false
            button.state = renderContentFlipY ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            button.allowsMixedState = true
            button.state = NSControl.StateValue.mixed
          }
        }
      }
      if let button: NSButton = view.viewWithTag(3) as? NSButton
      {
        button.isEnabled = false
        if !iRASPAObjects.isEmpty
        {
          button.isEnabled = enabled
          if let renderContentFlipZ: Bool = self.renderContentFlipZ
          {
            button.allowsMixedState = false
            button.state = renderContentFlipZ ? NSControl.StateValue.on : NSControl.StateValue.off
          }
          else
          {
            button.allowsMixedState = true
            button.state = NSControl.StateValue.mixed
          }
        }
      }
     
      if let textFieldCenterShiftX: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldCenterShiftX.isEditable = false
        textFieldCenterShiftX.stringValue = "test"
        if !iRASPAObjects.isEmpty
        {
          textFieldCenterShiftX.isEditable = enabled
          if let renderCenterShiftX: Double = self.renderContentShiftX
          {
            textFieldCenterShiftX.doubleValue =  renderCenterShiftX
          }
          else
          {
            textFieldCenterShiftX.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldCenterShiftY: NSTextField = view.viewWithTag(5) as? NSTextField
      {
        textFieldCenterShiftY.isEditable = false
        textFieldCenterShiftY.stringValue = "test"
        if !iRASPAObjects.isEmpty
        {
          textFieldCenterShiftY.isEditable = enabled
          if let renderCenterShiftY: Double = self.renderContentShiftY
          {
            textFieldCenterShiftY.doubleValue =  renderCenterShiftY
          }
          else
          {
            textFieldCenterShiftY.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldCenterShiftZ: NSTextField = view.viewWithTag(6) as? NSTextField
      {
        textFieldCenterShiftZ.isEditable = false
        textFieldCenterShiftZ.stringValue = "test"
        if !iRASPAObjects.isEmpty
        {
          textFieldCenterShiftZ.isEditable = enabled
          if let renderCenterShiftZ: Double = self.renderContentShiftZ
          {
            textFieldCenterShiftZ.doubleValue =  renderCenterShiftZ
          }
          else
          {
            textFieldCenterShiftZ.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
    
    default:
      break
    }
  }
  
  func setPropertiesStructuralTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    switch(identifier)
    {
    case "StructuralPropertiesCell":
      if let comboBoxRenderStructureMaterialType: iRASPAComboBox = view.viewWithTag(1) as? iRASPAComboBox
      {
        comboBoxRenderStructureMaterialType.isEditable = false
        comboBoxRenderStructureMaterialType.stringValue = ""
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor}).isEmpty
        {
          comboBoxRenderStructureMaterialType.isEditable = enabled
          
          if let value: String = self.renderStructureMaterialType
          {
            if comboBoxRenderStructureMaterialType.indexOfItem(withObjectValue: value) == NSNotFound
            {
              comboBoxRenderStructureMaterialType.insertItem(withObjectValue: value, at: 0)
            }
            comboBoxRenderStructureMaterialType.selectItem(withObjectValue: value)
          }
          else
          {
            comboBoxRenderStructureMaterialType.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
      if let textFieldRenderStructureMass: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldRenderStructureMass.isEditable = false
        textFieldRenderStructureMass.stringValue = ""
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor}).isEmpty
        {
          if let structureMass: Double = self.renderStructureMass
          {
            textFieldRenderStructureMass.doubleValue = structureMass
          }
          else
          {
            textFieldRenderStructureMass.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldRenderStructureDensity: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldRenderStructureDensity.isEditable = false
        textFieldRenderStructureDensity.stringValue = ""
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor}).isEmpty
        {
          textFieldRenderStructureDensity.isEnabled = enabled
          if let structureDensity: Double = self.renderStructureDensity
          {
            textFieldRenderStructureDensity.doubleValue = structureDensity
          }
          else
          {
            textFieldRenderStructureDensity.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldRenderStructureHeliumVoidFraction: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldRenderStructureHeliumVoidFraction.isEditable = false
        textFieldRenderStructureHeliumVoidFraction.stringValue = ""
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor & VolumetricDataViewer}).isEmpty
        {
          textFieldRenderStructureHeliumVoidFraction.isEnabled = enabled
          if let structureHeliumVoidFraction: Double = self.renderStructureHeliumVoidFraction
          {
            textFieldRenderStructureHeliumVoidFraction.doubleValue = structureHeliumVoidFraction
          }
          else
          {
            textFieldRenderStructureHeliumVoidFraction.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldRenderStructureSpecificVolume: NSTextField = view.viewWithTag(5) as? NSTextField
      {
        textFieldRenderStructureSpecificVolume.isEditable = false
        textFieldRenderStructureSpecificVolume.stringValue = ""
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor}).isEmpty
        {
          textFieldRenderStructureSpecificVolume.isEnabled = enabled
          if let structureSpecificVolume: Double = self.renderStructureSpecificVolume
          {
            textFieldRenderStructureSpecificVolume.doubleValue = structureSpecificVolume
          }
          else
          {
            textFieldRenderStructureSpecificVolume.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldRenderStructureAccessiblePoreVolume: NSTextField = view.viewWithTag(6) as? NSTextField
      {
        textFieldRenderStructureAccessiblePoreVolume.isEditable = false
        textFieldRenderStructureAccessiblePoreVolume.stringValue = ""
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor & VolumetricDataViewer}).isEmpty
        {
          textFieldRenderStructureAccessiblePoreVolume.isEnabled = enabled
          if let structureAccessiblePoreVolume: Double = self.renderStructureAccessiblePoreVolume
          {
            textFieldRenderStructureAccessiblePoreVolume.doubleValue = structureAccessiblePoreVolume
          }
          else
          {
            textFieldRenderStructureAccessiblePoreVolume.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      
      if let buttonComputeHeliumVoidFraction: NSButton = view.viewWithTag(10) as? NSButton
      {
        buttonComputeHeliumVoidFraction.isEnabled = false
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor & VolumetricDataViewer}).isEmpty
        {
          buttonComputeHeliumVoidFraction.isEnabled = enabled
        }
      }
      

    case "StructuralProbeCell":
      // Probe molecule
      if let popUpbuttonProbeParticle: iRASPAPopUpButton = view.viewWithTag(1) as? iRASPAPopUpButton
      {
        popUpbuttonProbeParticle.isEditable = false
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor & VolumetricDataViewer}).isEmpty
        {
          popUpbuttonProbeParticle.isEditable = enabled
          if let probeMolecule: Structure.ProbeMolecule = self.renderFrameworkProbeMolecule
          {
            popUpbuttonProbeParticle.selectItem(at: probeMolecule.rawValue)
          }
        }
      }
      
      if let textFieldRenderStructureVolumetricNitrogenSurfaceArea: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldRenderStructureVolumetricNitrogenSurfaceArea.isEditable = false
        textFieldRenderStructureVolumetricNitrogenSurfaceArea.stringValue = ""
        textFieldRenderStructureVolumetricNitrogenSurfaceArea.isEnabled = false
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor & VolumetricDataViewer}).isEmpty
        {
          textFieldRenderStructureVolumetricNitrogenSurfaceArea.isEnabled = enabled
          if let structureVolumetricNitrogenSurfaceArea: Double = self.renderStructureVolumetricNitrogenSurfaceArea
          {
            textFieldRenderStructureVolumetricNitrogenSurfaceArea.doubleValue = structureVolumetricNitrogenSurfaceArea
          }
          else
          {
            textFieldRenderStructureVolumetricNitrogenSurfaceArea.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldRenderStructureGravimetricNitrogenSurfaceArea: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldRenderStructureGravimetricNitrogenSurfaceArea.isEditable = false
        textFieldRenderStructureGravimetricNitrogenSurfaceArea.stringValue = ""
        textFieldRenderStructureGravimetricNitrogenSurfaceArea.isEnabled = false
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor & VolumetricDataViewer}).isEmpty
        {
          textFieldRenderStructureGravimetricNitrogenSurfaceArea.isEnabled = enabled
          if let structureGravimetricNitrogenSurfaceArea: Double = self.renderStructureGravimetricNitrogenSurfaceArea
          {
            textFieldRenderStructureGravimetricNitrogenSurfaceArea.doubleValue = structureGravimetricNitrogenSurfaceArea
          }
          else
          {
            textFieldRenderStructureGravimetricNitrogenSurfaceArea.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      
      if let textFieldRenderStructureNumberOfChannelSystems: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldRenderStructureNumberOfChannelSystems.isEditable = false
        textFieldRenderStructureNumberOfChannelSystems.stringValue = ""
        textFieldRenderStructureNumberOfChannelSystems.isEnabled = false
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor & VolumetricDataViewer}).isEmpty
        {
          textFieldRenderStructureNumberOfChannelSystems.isEnabled = enabled
          textFieldRenderStructureNumberOfChannelSystems.isEditable = enabled
          if let structureNumberOfChannelSystems: Int = self.renderStructureNumberOfChannelSystems
          {
            textFieldRenderStructureNumberOfChannelSystems.integerValue = structureNumberOfChannelSystems
          }
          else
          {
            textFieldRenderStructureNumberOfChannelSystems.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldRenderStructureNumberOfInaccessiblePockets: NSTextField = view.viewWithTag(5) as? NSTextField
      {
        textFieldRenderStructureNumberOfInaccessiblePockets.isEditable = false
        textFieldRenderStructureNumberOfInaccessiblePockets.stringValue = ""
        textFieldRenderStructureNumberOfInaccessiblePockets.isEnabled = false
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor & VolumetricDataViewer}).isEmpty
        {
          textFieldRenderStructureNumberOfInaccessiblePockets.isEnabled = enabled
          textFieldRenderStructureNumberOfInaccessiblePockets.isEditable = enabled
          if let structureNumberOfInaccessiblePockets: Int = self.renderStructureNumberOfInaccessiblePockets
          {
            textFieldRenderStructureNumberOfInaccessiblePockets.integerValue = structureNumberOfInaccessiblePockets
          }
          else
          {
            textFieldRenderStructureNumberOfInaccessiblePockets.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      
      
     
      if let buttonComputeVolumetricSurfaceArea: NSButton = view.viewWithTag(10) as? NSButton
      {
        buttonComputeVolumetricSurfaceArea.isEnabled = false
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor & VolumetricDataViewer}).isEmpty
        {
          buttonComputeVolumetricSurfaceArea.isEnabled = enabled
        }
      }
    
      if let buttonComputeGeometricSurfaceArea: NSButton = view.viewWithTag(11) as? NSButton
      {
        buttonComputeGeometricSurfaceArea.isEnabled = false
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor & VolumetricDataViewer}).isEmpty
        {
          buttonComputeGeometricSurfaceArea.isEnabled = enabled
        }
      }
  
    case "StructuralChannelCell":
     
      if let textFieldRenderStructureDimensionalityOfPoreSystem: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldRenderStructureDimensionalityOfPoreSystem.isEditable = false
        textFieldRenderStructureDimensionalityOfPoreSystem.stringValue = ""
        textFieldRenderStructureDimensionalityOfPoreSystem.isEnabled = false
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor & VolumetricDataViewer}).isEmpty
        {
          textFieldRenderStructureDimensionalityOfPoreSystem.isEnabled = enabled
          textFieldRenderStructureDimensionalityOfPoreSystem.isEditable = enabled
          if let structureDimensionalityOfPoreSystem: Int = self.renderStructureDimensionalityOfPoreSystem
          {
            textFieldRenderStructureDimensionalityOfPoreSystem.integerValue = structureDimensionalityOfPoreSystem
          }
          else
          {
            textFieldRenderStructureDimensionalityOfPoreSystem.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldRenderStructureLargestCavityDiameter: NSTextField = view.viewWithTag(2) as? NSTextField
      {
        textFieldRenderStructureLargestCavityDiameter.isEditable = false
        textFieldRenderStructureLargestCavityDiameter.stringValue = ""
        textFieldRenderStructureLargestCavityDiameter.isEnabled = false
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor & VolumetricDataViewer}).isEmpty
        {
          textFieldRenderStructureLargestCavityDiameter.isEnabled = enabled
          textFieldRenderStructureLargestCavityDiameter.isEditable = enabled
          if let structureLargestCavityDiameterX: Double = self.renderStructureLargestCavityDiameter
          {
            textFieldRenderStructureLargestCavityDiameter.doubleValue = structureLargestCavityDiameterX
          }
          else
          {
            textFieldRenderStructureLargestCavityDiameter.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldRenderStructureRestrictingPoreLimitingDiameter: NSTextField = view.viewWithTag(3) as? NSTextField
      {
        textFieldRenderStructureRestrictingPoreLimitingDiameter.isEditable = false
        textFieldRenderStructureRestrictingPoreLimitingDiameter.stringValue = ""
        textFieldRenderStructureRestrictingPoreLimitingDiameter.isEnabled = false
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor & VolumetricDataViewer}).isEmpty
        {
          textFieldRenderStructureRestrictingPoreLimitingDiameter.isEnabled = enabled
          textFieldRenderStructureRestrictingPoreLimitingDiameter.isEditable = enabled
          if let structureRestrictingPoreLimitingDiameter: Double = self.renderStructureRestrictingPoreLimitingDiameter
          {
            textFieldRenderStructureRestrictingPoreLimitingDiameter.doubleValue = structureRestrictingPoreLimitingDiameter
          }
          else
          {
            textFieldRenderStructureRestrictingPoreLimitingDiameter.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
      if let textFieldRenderStructureLargestCavityDiameterAlongAViablePath: NSTextField = view.viewWithTag(4) as? NSTextField
      {
        textFieldRenderStructureLargestCavityDiameterAlongAViablePath.isEditable = false
        textFieldRenderStructureLargestCavityDiameterAlongAViablePath.stringValue = ""
        textFieldRenderStructureLargestCavityDiameterAlongAViablePath.isEnabled = false
        if !iRASPAObjects.filter({$0.object is StructuralPropertyEditor & VolumetricDataViewer}).isEmpty
        {
          textFieldRenderStructureLargestCavityDiameterAlongAViablePath.isEnabled = enabled
          textFieldRenderStructureLargestCavityDiameterAlongAViablePath.isEditable = enabled
          if let structureLargestCavityDiameterAlongAViablePath: Double = self.renderStructureLargestCavityDiameterAlongAViablePath
          {
            textFieldRenderStructureLargestCavityDiameterAlongAViablePath.doubleValue = structureLargestCavityDiameterAlongAViablePath
          }
          else
          {
            textFieldRenderStructureLargestCavityDiameterAlongAViablePath.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
    default:
      break
    }
  }
  
  func setPropertiesSymmetryTableCells(on view: NSTableCellView, identifier: String, enabled: Bool)
  {
    switch(identifier)
    {
    case "SymmetrySpaceGroupCell":
      if let HallSpaceGroupPopUpButton: iRASPAPopUpButton = view.viewWithTag(1) as? iRASPAPopUpButton,
         let SpaceGroupHolohedry: NSTextField = view.viewWithTag(2) as? NSTextField,
         let spaceGroupNumberPopUpButton: iRASPAPopUpButton = view.viewWithTag(3) as? iRASPAPopUpButton,
         let spaceGroupQualifierPopUpButton: iRASPAPopUpButton = view.viewWithTag(4) as? iRASPAPopUpButton
      {
        HallSpaceGroupPopUpButton.isEditable = false
        SpaceGroupHolohedry.isEditable = false
        spaceGroupNumberPopUpButton.isEditable = false
        spaceGroupQualifierPopUpButton.isEditable = false
        
        HallSpaceGroupPopUpButton.stringValue = ""
        SpaceGroupHolohedry.stringValue = ""
        spaceGroupNumberPopUpButton.stringValue = ""
        spaceGroupQualifierPopUpButton.stringValue = ""
       
        
        HallSpaceGroupPopUpButton.removeAllItems()
        HallSpaceGroupPopUpButton.addItems(withTitles: SKSpacegroup.HallSymbols)
        
        spaceGroupNumberPopUpButton.removeAllItems()
        spaceGroupNumberPopUpButton.addItems(withTitles: SKSpacegroup.numbers)
        
        HallSpaceGroupPopUpButton.selectItem(at: 1)
        spaceGroupNumberPopUpButton.selectItem(at: 1)
        
        let qualifiers: [String] = SKSpacegroup.spacegroupQualifiers(number: 1)
        spaceGroupQualifierPopUpButton.addItems(withTitles: qualifiers)
        let ext: Int = SKSpacegroup.SpaceGroupQualifierForHallNumber(1)
        spaceGroupQualifierPopUpButton.selectItem(at: ext)
        
        SpaceGroupHolohedry.stringValue = SKSpacegroup.HolohedryString(HallNumber: 1)
        
        if !iRASPAObjects.filter({$0.object is SpaceGroupEditor}).isEmpty
        {
          HallSpaceGroupPopUpButton.isEditable = enabled
          spaceGroupNumberPopUpButton.isEditable = enabled
          
          if let spaceGroupHallNumber: Int = self.spaceGroupHallNumber
          {
            spaceGroupQualifierPopUpButton.isEditable = enabled
            spaceGroupQualifierPopUpButton.removeAllItems()
            
            let spaceGroupNumber: Int = SKSpacegroup.SpaceGroupNumberForHallNumber(spaceGroupHallNumber)
            let qualifiers: [String] = SKSpacegroup.spacegroupQualifiers(number: spaceGroupNumber)
            spaceGroupQualifierPopUpButton.addItems(withTitles: qualifiers)
            if qualifiers.count <= 1
            {
              spaceGroupQualifierPopUpButton.isEditable = false
            }
            
            HallSpaceGroupPopUpButton.selectItem(at: spaceGroupHallNumber)
            spaceGroupNumberPopUpButton.selectItem(at: spaceGroupNumber)
            let ext: Int = SKSpacegroup.SpaceGroupQualifierForHallNumber(spaceGroupHallNumber)
            spaceGroupQualifierPopUpButton.selectItem(at: ext)
            
            SpaceGroupHolohedry.stringValue = SKSpacegroup.HolohedryString(HallNumber: spaceGroupHallNumber)
          }
          else
          {
            spaceGroupQualifierPopUpButton.removeAllItems()
            spaceGroupQualifierPopUpButton.addItem(withTitle: NSLocalizedString("Multiple Values", comment: ""))
            HallSpaceGroupPopUpButton.setTitle(NSLocalizedString("Multiple Values", comment: ""))
            SpaceGroupHolohedry.stringValue = NSLocalizedString("Multiple Values", comment: "")
            spaceGroupNumberPopUpButton.setTitle(NSLocalizedString("Multiple Values", comment: ""))
            spaceGroupQualifierPopUpButton.setTitle(NSLocalizedString("Multiple Values", comment: ""))
          }
        }
      }
      
      if let textFieldRenderPrecision: NSTextField = view.viewWithTag(5) as? NSTextField
      {
        textFieldRenderPrecision.isEditable = false
        textFieldRenderPrecision.stringValue = ""
        if !iRASPAObjects.isEmpty
        {
          textFieldRenderPrecision.isEditable = enabled
          if let renderPrecision: Double = self.renderCellPrecision
          {
            textFieldRenderPrecision.doubleValue = renderPrecision
          }
          else
          {
            textFieldRenderPrecision.stringValue = NSLocalizedString("Mult. Val.", comment: "")
          }
        }
      }
    case "SymmetryCenteringCell":
      if let centringTextField: NSTextField = view.viewWithTag(1) as? NSTextField,
         let centringLatticeVector1TextField: NSTextField = view.viewWithTag(2) as? NSTextField,
         let centringLatticeVector2TextField: NSTextField = view.viewWithTag(3) as? NSTextField,
         let centringLatticeVector3TextField: NSTextField = view.viewWithTag(4) as? NSTextField,
         let centringLatticeVector4TextField: NSTextField = view.viewWithTag(5) as? NSTextField
      {
        centringTextField.isEditable = false
        centringLatticeVector1TextField.isEditable = false
        centringLatticeVector2TextField.isEditable = false
        centringLatticeVector3TextField.isEditable = false
        centringLatticeVector4TextField.isEditable = false
       
        centringTextField.stringValue = ""
        centringLatticeVector1TextField.stringValue = ""
        centringLatticeVector2TextField.stringValue = ""
        centringLatticeVector3TextField.stringValue = ""
        centringLatticeVector4TextField.stringValue = ""
        
        centringTextField.stringValue = SKSpacegroup.CentringString(HallNumber: 1)
        
        
        if !iRASPAObjects.filter({$0.object is SpaceGroupEditor}).isEmpty
        {
          if let spaceGroupHallNumber: Int = self.spaceGroupHallNumber
          {
            centringTextField.stringValue = SKSpacegroup.CentringString(HallNumber: spaceGroupHallNumber)
            let latticeTranslationStrings: [String] = SKSpacegroup.LatticeTranslationStrings(HallNumber: spaceGroupHallNumber)
            centringLatticeVector1TextField.stringValue = latticeTranslationStrings[0]
            centringLatticeVector2TextField.stringValue = latticeTranslationStrings[1]
            centringLatticeVector3TextField.stringValue = latticeTranslationStrings[2]
            centringLatticeVector4TextField.stringValue = latticeTranslationStrings[3]
          }
          else
          {
            centringTextField.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }

      }
    case "SymmetryPropertiesCell":
      if let hasInversionTextField: NSTextField = view.viewWithTag(1) as? NSTextField,
         let inversionTextField: NSTextField = view.viewWithTag(2) as? NSTextField,
         let centrosymmetricTextField: NSTextField = view.viewWithTag(3) as? NSTextField,
         let enantiomorphicTextField: NSTextField = view.viewWithTag(4) as? NSTextField,
         let LaueGroupTextField: NSTextField = view.viewWithTag(5) as? NSTextField,
         let pointGroupTextField: NSTextField = view.viewWithTag(6) as? NSTextField,
         let SchoenfliesTextField: NSTextField = view.viewWithTag(7) as? NSTextField,
         let symmorphicityTextField: NSTextField = view.viewWithTag(8) as? NSTextField,
         let numberOfElementsTextField: NSTextField = view.viewWithTag(9) as? NSTextField
      {
        hasInversionTextField.isEditable = false
        inversionTextField.isEditable = false
        centrosymmetricTextField.isEditable = false
        enantiomorphicTextField.isEditable = false
        LaueGroupTextField.isEditable = false
        pointGroupTextField.isEditable = false
        SchoenfliesTextField.isEditable = false
        symmorphicityTextField.isEditable = false
        numberOfElementsTextField.isEditable = false
        
        hasInversionTextField.stringValue = ""
        inversionTextField.stringValue = ""
        centrosymmetricTextField.stringValue = ""
        enantiomorphicTextField.stringValue = ""
        LaueGroupTextField.stringValue = ""
        pointGroupTextField.stringValue = ""
        SchoenfliesTextField.stringValue = ""
        symmorphicityTextField.stringValue = ""
        numberOfElementsTextField.stringValue = ""
        
        centrosymmetricTextField.stringValue = SKSpacegroup.CentrosymmetricString(HallNumber: 1)
        enantiomorphicTextField.stringValue = SKSpacegroup.EnantionmorphicString(HallNumber: 1)
        LaueGroupTextField.stringValue = SKSpacegroup.LaueGroupString(HallNumber: 1)
        pointGroupTextField.stringValue = SKSpacegroup.PointGroupString(HallNumber: 1)
        SchoenfliesTextField.stringValue = SKSpacegroup.SchoenfliesString(HallNumber: 1)
        symmorphicityTextField.stringValue = SKSpacegroup.SymmorphicityString(HallNumber: 1)
        numberOfElementsTextField.stringValue = SKSpacegroup.NumberOfElementsString(HallNumber: 1)
        
        if !iRASPAObjects.filter({$0.object is SpaceGroupEditor}).isEmpty
        {
          if let spaceGroupHallNumber: Int = self.spaceGroupHallNumber
          {
            hasInversionTextField.stringValue = SKSpacegroup.hasInversionString(HallNumber: spaceGroupHallNumber)
            inversionTextField.stringValue = SKSpacegroup.hasInversion(HallNumber: spaceGroupHallNumber) ? SKSpacegroup.InversionCenterString(HallNumber: spaceGroupHallNumber) : ""
            centrosymmetricTextField.stringValue = SKSpacegroup.CentrosymmetricString(HallNumber: spaceGroupHallNumber)
            enantiomorphicTextField.stringValue = SKSpacegroup.EnantionmorphicString(HallNumber: spaceGroupHallNumber)
            LaueGroupTextField.stringValue = SKSpacegroup.LaueGroupString(HallNumber: spaceGroupHallNumber)
            pointGroupTextField.stringValue = SKSpacegroup.PointGroupString(HallNumber: spaceGroupHallNumber)
            SchoenfliesTextField.stringValue = SKSpacegroup.SchoenfliesString(HallNumber: spaceGroupHallNumber)
            symmorphicityTextField.stringValue = SKSpacegroup.SymmorphicityString(HallNumber: spaceGroupHallNumber)
            numberOfElementsTextField.stringValue = SKSpacegroup.NumberOfElementsString(HallNumber: spaceGroupHallNumber)
          }
          else
          {
            hasInversionTextField.stringValue = NSLocalizedString("Multiple Values", comment: "")
            inversionTextField.stringValue = NSLocalizedString("Multiple Values", comment: "")
            centrosymmetricTextField.stringValue = NSLocalizedString("Multiple Values", comment: "")
            enantiomorphicTextField.stringValue = NSLocalizedString("Multiple Values", comment: "")
            LaueGroupTextField.stringValue = NSLocalizedString("Multiple Values", comment: "")
            pointGroupTextField.stringValue = NSLocalizedString("Multiple Values", comment: "")
            SchoenfliesTextField.stringValue = NSLocalizedString("Multiple Values", comment: "")
            symmorphicityTextField.stringValue = NSLocalizedString("Multiple Values", comment: "")
            numberOfElementsTextField.stringValue = NSLocalizedString("Multiple Values", comment: "")
          }
        }
      }
    default:
      break
    }
  }
  
  

  // MARK: Update outlineView
  // =====================================================================
  
  func updateOutlineView(identifiers: [OutlineViewItem])
  {
    // Update at the next iteration (reloading could be in progress)
    DispatchQueue.main.async(execute: {[weak self] in
      for identifier in identifiers
      {
        if let row: Int = self?.cellOutlineView?.row(forItem: identifier), row >= 0
        {
          self?.cellOutlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
        }
      }
    })
  }
  
  
   // MARK: Material type changes
   // =====================================================================
  
  @IBAction func changeMaterialType(_ sender: NSPopUpButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      projectTreeNode.representedObject.isEdited = true
      
      // remove the measuring nodes
      project.measurementTreeNodes = []
      
      var to: [iRASPAObject] = []
      var from: [iRASPAObject] = []
      for cellViewer in iRASPAObjects
      {
        for i in 0..<cellViewer.frames.count
        {
          from.append(cellViewer.frames[i])
          switch(SKStructure.Kind(rawValue: sender.indexOfSelectedItem))
          {
          case .none,.unknown, .structure:
            return
          case .crystal:
            to.append(iRASPAObject(crystal: Crystal(from: cellViewer.frames[i].object)))
          case .molecularCrystal:
            to.append(iRASPAObject(molecularCrystal: MolecularCrystal(from: cellViewer.frames[i].object)))
          case .molecule:
            to.append(iRASPAObject(molecule: Molecule(from: cellViewer.frames[i].object)))
          case .protein:
            to.append(iRASPAObject(protein: Protein(from: cellViewer.frames[i].object)))
          case .proteinCrystal:
            to.append(iRASPAObject(proteinCrystal: ProteinCrystal(from: cellViewer.frames[i].object)))
          case .proteinCrystalSolvent,.crystalSolvent,.molecularCrystalSolvent:
            return
          case .crystalEllipsoidPrimitive:
            to.append(iRASPAObject(crystalEllipsoidPrimitive: CrystalEllipsoidPrimitive(from: cellViewer.frames[i].object)))
          case .crystalCylinderPrimitive:
            to.append(iRASPAObject(crystalCylinderPrimitive: CrystalCylinderPrimitive(from: cellViewer.frames[i].object)))
          case .crystalPolygonalPrismPrimitive:
            to.append(iRASPAObject(crystalPolygonalPrismPrimitive: CrystalPolygonalPrismPrimitive(from: cellViewer.frames[i].object)))
          case .ellipsoidPrimitive:
            to.append(iRASPAObject(ellipsoidPrimitive: EllipsoidPrimitive(from: cellViewer.frames[i].object)))
          case .cylinderPrimitive:
            to.append(iRASPAObject(cylinderPrimitive: CylinderPrimitive(from: cellViewer.frames[i].object)))
          case .polygonalPrismPrimitive:
            to.append(iRASPAObject(polygonalPrismPrimitive: PolygonalPrismPrimitive(from: cellViewer.frames[i].object)))
          case .RASPADensityVolume:
            to.append(iRASPAObject(RASPADensityVolume: RASPAVolumetricData(from: cellViewer.frames[i].object)))
          case .VTKDensityVolume:
            to.append(iRASPAObject(VTKDensityVolume: VTKVolumetricData(from: cellViewer.frames[i].object)))
          case .VASPDensityVolume:
            to.append(iRASPAObject(VASPDensityVolume: VASPVolumetricData(from: cellViewer.frames[i].object)))
          case .GaussianCubeVolume:
            to.append(iRASPAObject(GaussianCubeVolume: GaussianCubeVolumetricData(from: cellViewer.frames[i].object)))
          default:
            break
          }
        }
      }
      self.replaceStructure(structures: from, to: to)
      
      project.isEdited = true
    
    }
  }
  
  func replaceStructure(structures from: [iRASPAObject], to: [iRASPAObject])
  {
    if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      project.undoManager.registerUndo(withTarget: self, handler: {$0.replaceStructure(structures: from, to: to)})
      
      project.undoManager.setActionName(NSLocalizedString("Change Material Type", comment: ""))
      
      for i in 0..<from.count
      {
        from[i].swapRepresentedObjects(structure: to[i])
      }
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      project.isEdited = true
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: to.map{$0.object})
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: to.map{$0.object})
      
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurface(completionHandler: {})
      self.windowController?.detailTabViewController?.renderViewController?.updateIsosurfaceUniforms()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.detailTabViewController?.reloadData()
    }
  }
  
  // MARK: Cell changes
  // =====================================================================
  
  @IBAction func changedCellLengthA(_ sender: NSTextField)
  {
    let newValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      self.renderUnitCellLengthA = newValue
      self.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      
      
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      if let projectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
      {
        projectStructureNode.renderCamera?.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
      }
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperCellLengthA(_ sender: NSStepper)
  {
    let deltaValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let renderUnitCellLengthA: Double = self.renderUnitCellLengthA
    {
      let newValue: Double = renderUnitCellLengthA + deltaValue
      self.renderUnitCellLengthA = newValue
      self.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      if let projectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
      {
        projectStructureNode.renderCamera?.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
      }
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
    
    sender.doubleValue = 0
  }
  
  @IBAction func changedCellLengthB(_ sender: NSTextField)
  {
    let newValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      self.renderUnitCellLengthB = newValue
      self.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      if let projectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
      {
        projectStructureNode.renderCamera?.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
      }
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperCellLengthB(_ sender: NSStepper)
  {
    let deltaValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let renderUnitCellLengthB: Double = self.renderUnitCellLengthB
    {
      let newValue: Double = renderUnitCellLengthB + deltaValue
      self.renderUnitCellLengthB = newValue
      self.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      if let projectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
      {
        projectStructureNode.renderCamera?.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
      }
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
    
    sender.doubleValue = 0
  }
  
  
  @IBAction func changedCellLengthC(_ sender: NSTextField)
  {
    let newValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      self.renderUnitCellLengthC = newValue
      self.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      if let projectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
      {
        projectStructureNode.renderCamera?.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
      }
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperCellLengthC(_ sender: NSStepper)
  {
    let deltaValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let renderUnitCellLengthC: Double = self.renderUnitCellLengthC
    {
      let newValue: Double = renderUnitCellLengthC + deltaValue
      self.renderUnitCellLengthC = newValue
      self.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      if let projectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
      {
        projectStructureNode.renderCamera?.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
      }
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
    
    sender.doubleValue = 0
  }
  
  @IBAction func changedCellAngleAlpha(_ sender: NSTextField)
  {
    let newValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      self.renderUnitCellAlphaAngle = newValue
      self.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
        
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      if let projectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
      {
        projectStructureNode.renderCamera?.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
      }
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperCellAngleAlpha(_ sender: NSStepper)
  {
    let deltaValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let renderUnitCellAlphaAngle: Double = self.renderUnitCellAlphaAngle
    {
      let newValue: Double = renderUnitCellAlphaAngle + deltaValue
      self.renderUnitCellAlphaAngle = newValue
      self.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      if let projectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
      {
        projectStructureNode.renderCamera?.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
      }
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
    
    sender.doubleValue = 0
  }
  
  @IBAction func changedCellAngleBeta(_ sender: NSTextField)
  {
    let newValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      self.renderUnitCellBetaAngle = newValue
      self.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      if let projectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
      {
        projectStructureNode.renderCamera?.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
      }
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperCellAngleBeta(_ sender: NSStepper)
  {
    let deltaValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let renderUnitCellBetaAngle: Double = self.renderUnitCellBetaAngle
    {
      let newValue: Double = renderUnitCellBetaAngle + deltaValue
      self.renderUnitCellBetaAngle = newValue
      self.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      if let projectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
      {
        projectStructureNode.renderCamera?.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
      }
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
    
    sender.doubleValue = 0
  }
  
  
  @IBAction func changedCellAngleGamma(_ sender: NSTextField)
  {
    let newValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      self.renderUnitCellGammaAngle = newValue
      self.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      if let projectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
      {
        projectStructureNode.renderCamera?.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
      }
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func updateStepperCellAngleGamma(_ sender: NSStepper)
  {
    let deltaValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let renderUnitCellGammaAngle: Double = self.renderUnitCellGammaAngle
    {
      let newValue: Double = renderUnitCellGammaAngle + deltaValue
      self.renderUnitCellGammaAngle = newValue
      self.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      if let projectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
      {
        projectStructureNode.renderCamera?.resetForNewBoundingBox(projectStructureNode.renderBoundingBox)
      }
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
    
    sender.doubleValue = 0
  }
  
  // MARK: Replica changes
  // =====================================================================
  
  @IBAction func changedCellMinimumReplicaX(_ sender: NSTextField)
  {
    let newValue: Int32 = Int32(sender.doubleValue)
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let renderMaximumReplicaX: Int32 = self.renderMaximumReplicaX
    {
      if (newValue <= renderMaximumReplicaX)
      {
        self.renderMinimumReplicaX = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          self.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
        
        self.updateOutlineView(identifiers: [self.boxBoundingBoxInfoCell])
      }
    }
  }
  
  @IBAction func changedCellMinimumReplicaY(_ sender: NSTextField)
  {
    let newValue: Int32 = Int32(sender.doubleValue)
    
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
       let renderMaximumReplicaY: Int32 = self.renderMaximumReplicaY
    {
      if (newValue <= renderMaximumReplicaY)
      {
        self.renderMinimumReplicaY = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          self.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
        
        self.updateOutlineView(identifiers: [self.boxBoundingBoxInfoCell])
      }
    }
  }
  
  @IBAction func changedCellMinimumReplicaZ(_ sender: NSTextField)
  {
    let newValue: Int32 = Int32(sender.doubleValue)
    
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
      let renderMaximumReplicaZ: Int32 = self.renderMaximumReplicaZ
    {
      if (newValue <= renderMaximumReplicaZ)
      {
        self.renderMinimumReplicaZ = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          self.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
        
        self.updateOutlineView(identifiers: [self.boxBoundingBoxInfoCell])
      }
    }
  }
  
  @IBAction func changedCellMaximumReplicaX(_ sender: NSTextField)
  {
    let newValue: Int32 = Int32(sender.doubleValue)
    
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
      let renderMinimumReplicaX: Int32 = self.renderMinimumReplicaX
    {
      if (newValue >= renderMinimumReplicaX)
      {
        self.renderMaximumReplicaX = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          self.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
        
        self.updateOutlineView(identifiers: [self.boxBoundingBoxInfoCell])
      }
    }
  }
  
  @IBAction func changedCellMaximumReplicaY(_ sender: NSTextField)
  {
    let newValue: Int32 = Int32(sender.doubleValue)
    
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
       let renderMinimumReplicaY: Int32 = self.renderMinimumReplicaY
    {
      if (newValue >= renderMinimumReplicaY)
      {
        self.renderMaximumReplicaY = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          self.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
        
        self.updateOutlineView(identifiers: [self.boxBoundingBoxInfoCell])
      }
    }
  }
  
  @IBAction func changedCellMaximumReplicaZ(_ sender: NSTextField)
  {
    let newValue: Int32 = Int32(sender.doubleValue)
    
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
       let renderMinimumReplicaZ: Int32 = self.renderMinimumReplicaZ
    {
      if (newValue >= renderMinimumReplicaZ)
      {
        self.renderMaximumReplicaZ = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          self.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
        
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
        
        self.updateOutlineView(identifiers: [self.boxBoundingBoxInfoCell])
      }
    }
  }
  
  
  
  @IBAction func updateStepperCellMinimumReplicaX(_ sender: NSStepper)
  {
    let deltaValue: Int32 = Int32(sender.intValue)
    
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
       let renderMinimumReplicaX: Int32 = self.renderMinimumReplicaX,
       let renderMaximumReplicaX: Int32 = self.renderMaximumReplicaX
    {
      
      let newValue: Int32 = renderMinimumReplicaX + deltaValue
      
      if (newValue <= renderMaximumReplicaX)
      {
        self.renderMinimumReplicaX = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          self.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
      
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
        self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
        
        self.updateOutlineView(identifiers: [self.boxReplicasCell, self.boxBoundingBoxInfoCell])
      }
    }
    
    sender.intValue = 0
  }
  
  @IBAction func updateStepperCellMinimumReplicaY(_ sender: NSStepper)
  {
    let deltaValue: Int32 = Int32(sender.intValue)
    
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
       let renderMinimumReplicaY: Int32 = self.renderMinimumReplicaY,
       let renderMaximumReplicaY: Int32 = self.renderMaximumReplicaY
    {
      let newValue: Int32 = renderMinimumReplicaY + deltaValue
      
      if (newValue <= renderMaximumReplicaY)
      {
        self.renderMinimumReplicaY = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          self.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
        self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
        
        self.updateOutlineView(identifiers: [self.boxReplicasCell, self.boxBoundingBoxInfoCell])
      }
    }
    
    sender.intValue = 0
  }
  
  
  @IBAction func updateStepperCellMinimumReplicaZ(_ sender: NSStepper)
  {
    let deltaValue: Int32 = Int32(sender.intValue)
    
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
       let renderMinimumReplicaZ: Int32 = self.renderMinimumReplicaZ,
       let renderMaximumReplicaZ: Int32 = self.renderMaximumReplicaZ
    {
      let newValue: Int32 = renderMinimumReplicaZ + deltaValue
      
      if (newValue <= renderMaximumReplicaZ)
      {
        self.renderMinimumReplicaZ = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          self.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
        self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
        
        self.updateOutlineView(identifiers: [self.boxReplicasCell, self.boxBoundingBoxInfoCell])
      }
    }
    
    sender.intValue = 0
  }
  
  
  @IBAction func updateStepperCellMaximumReplicaX(_ sender: NSStepper)
  {
    let deltaValue: Int32 = Int32(sender.intValue)
    
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
       let renderMinimumReplicaX: Int32 = self.renderMinimumReplicaX,
       let renderMaximumReplicaX: Int32 = self.renderMaximumReplicaX
    {
      let newValue: Int32 = renderMaximumReplicaX + deltaValue
      
      if (newValue >= renderMinimumReplicaX)
      {
        self.renderMaximumReplicaX = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          self.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
        self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
        
        self.updateOutlineView(identifiers: [self.boxReplicasCell, self.boxBoundingBoxInfoCell])
      }
    }
    
    sender.intValue = 0
  }
  
  @IBAction func updateStepperCellMaximumReplicaY(_ sender: NSStepper)
  {
    let deltaValue: Int32 = Int32(sender.intValue)
    
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
       let renderMinimumReplicaY: Int32 = self.renderMinimumReplicaY,
       let renderMaximumReplicaY: Int32 = self.renderMaximumReplicaY
    {
      let newValue: Int32 = renderMaximumReplicaY + deltaValue
      
      if (newValue >= renderMinimumReplicaY)
      {
        self.renderMaximumReplicaY = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          self.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
        self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
        
        self.updateOutlineView(identifiers: [self.boxReplicasCell, self.boxBoundingBoxInfoCell])
      }
    }
    
    sender.intValue = 0
  }
  
  @IBAction func updateStepperCellMaximumReplicaZ(_ sender: NSStepper)
  {
    let deltaValue: Int32 = Int32(sender.intValue)
    
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
       let renderMinimumReplicaZ: Int32 = self.renderMinimumReplicaZ,
       let renderMaximumReplicaZ: Int32 = self.renderMaximumReplicaZ
    {
      let newValue: Int32 = renderMaximumReplicaZ + deltaValue
      
      if (newValue >= renderMinimumReplicaZ)
      {
        self.renderMaximumReplicaZ = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          self.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
        self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
        self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
        self.windowController?.document?.updateChangeCount(.changeDone)
        self.proxyProject?.representedObject.isEdited = true
        
        self.updateOutlineView(identifiers: [self.boxReplicasCell, self.boxBoundingBoxInfoCell])
      }
    }
    
    sender.intValue = 0
  }
  
  
  
  // MARK: Origin
  // =====================================================================
  
  @IBAction func changedOriginX(_ sender: NSTextField)
  {
    let newValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.renderOriginX = newValue
      
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      self.updateOutlineView(identifiers: [self.boxBoundingBoxInfoCell])
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure}), renderStructures.count > 1
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changedOriginY(_ sender: NSTextField)
  {
    let newValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.renderOriginY = newValue
      
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      self.updateOutlineView(identifiers: [self.boxBoundingBoxInfoCell])
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure}), renderStructures.count > 1
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changedOriginZ(_ sender: NSTextField)
  {
    let newValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.renderOriginZ = newValue
      
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      self.updateOutlineView(identifiers: [self.boxBoundingBoxInfoCell])
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure}), renderStructures.count > 1
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  // MARK: Content shift
  // =====================================================================
  
  @IBAction func changedContentShiftX(_ sender: NSTextField)
  {
    let newValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.renderContentShiftX = newValue
      
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
            
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure}), renderStructures.count > 1
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.transformContentCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  @IBAction func updateStepperCellContentShiftX(_ sender: NSStepper)
  {
    let deltaValue: Double = sender.doubleValue
    
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
       let renderContentShiftX: Double = self.renderContentShiftX
    {
      let newValue: Double = renderContentShiftX + deltaValue * 0.01
      
      self.renderContentShiftX = newValue
        
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
      {
        self.reComputeBoundingBox()
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        project.checkValidatyOfMeasurementPoints()
      }
        
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
        
      self.updateOutlineView(identifiers: [self.transformContentCell, self.boxBoundingBoxInfoCell])
    }
    
    sender.doubleValue = 0.0
  }
  
  @IBAction func changedContentShiftY(_ sender: NSTextField)
  {
    let newValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.renderContentShiftY = newValue
      
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
            
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure}), renderStructures.count > 1
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.transformContentCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  @IBAction func updateStepperCellContentShiftY(_ sender: NSStepper)
  {
    let deltaValue: Double = sender.doubleValue
    
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
      let renderContentShiftY: Double = self.renderContentShiftY
    {
      let newValue: Double = renderContentShiftY + deltaValue * 0.01
      
      self.renderContentShiftY = newValue
      
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
      {
        self.reComputeBoundingBox()
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        project.checkValidatyOfMeasurementPoints()
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.transformContentCell, self.boxBoundingBoxInfoCell])
    }
    
    sender.doubleValue = 0.0
  }
  
  @IBAction func changedContentShiftZ(_ sender: NSTextField)
  {
    let newValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.renderContentShiftZ = newValue
      
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
            
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure}), renderStructures.count > 1
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.transformContentCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  @IBAction func updateStepperCellContentShiftZ(_ sender: NSStepper)
  {
    let deltaValue: Double = sender.doubleValue
    
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled,
      let renderContentShiftZ: Double = self.renderContentShiftZ
    {
      let newValue: Double = renderContentShiftZ + deltaValue * 0.01
      
      self.renderContentShiftZ = newValue
      
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
      {
        self.reComputeBoundingBox()
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        project.checkValidatyOfMeasurementPoints()
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.transformContentCell, self.boxBoundingBoxInfoCell])
    }
    
    sender.doubleValue = 0.0
  }
  
  @IBAction func toggleFlipContentX(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      sender.allowsMixedState = false
      self.renderContentFlipX = (sender.state == NSControl.StateValue.on)
      
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
      {
        self.reComputeBoundingBox()
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        project.checkValidatyOfMeasurementPoints()
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.transformContentCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  @IBAction func toggleFlipContentY(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      sender.allowsMixedState = false
      self.renderContentFlipY = (sender.state == NSControl.StateValue.on)
      
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
      {
        self.reComputeBoundingBox()
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        project.checkValidatyOfMeasurementPoints()
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.transformContentCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  
  @IBAction func toggleFlipContentZ(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable
    {
      sender.allowsMixedState = false
      self.renderContentFlipZ = (sender.state == NSControl.StateValue.on)
      
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
      {
        self.reComputeBoundingBox()
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        project.checkValidatyOfMeasurementPoints()
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: self.iRASPAObjects.flatMap{$0.allRenderFrames})
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.transformContentCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  
  // undo for large-changes: completely replace all atoms and bonds by new ones
  func applyCellContentShift(object: Object, cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
       let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode,
       let atomViewer: AtomEditor = object as? AtomEditor
    {
      let oldCell: SKCell = object.cell
      var oldSpaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: 1)
      if let spaceGroupViewer = object as? SpaceGroupEditor
      {
        oldSpaceGroup = spaceGroupViewer.spaceGroup
      }
      let oldAtoms: SKAtomTreeController = atomViewer.atomTreeController
      let oldBonds: SKBondSetController = (object as? BondEditor)?.bondSetController ?? SKBondSetController()
      project.undoManager.registerUndo(withTarget: self, handler: {$0.applyCellContentShift(object: object, cell: oldCell, spaceGroup: oldSpaceGroup, atoms: oldAtoms, bonds: oldBonds)})
      
      object.cell = cell
      if let spaceGroupViewer = object as? SpaceGroupEditor
      {
        spaceGroupViewer.spaceGroup = spaceGroup
      }
      atomViewer.atomTreeController = atoms
      (object as? BondEditor)?.bondSetController = bonds
      
      object.reComputeBoundingBox()
      
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      if let structure: Structure = object as? Structure
      {
        structure.setRepresentationColorScheme(scheme: structure.atomColorSchemeIdentifier, colorSets: document.colorSets)
        structure.setRepresentationForceField(forceField: structure.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [object])
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [object])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.cellOutlineView?.reloadData()
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: object)
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.SpaceGroupShouldReloadNotification), object: self.windowController)
    }
  }
  
  
 
  
  @IBAction func applyContentShift(_ sender: NSButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      let structures: [Structure] = self.iRASPAObjects.compactMap({$0.object as? Structure})
      
      if let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
      {
        project.measurementTreeNodes = []
      }
      
      for structure in structures
      {
        if let state: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.applyCellContentShift()
        {
          self.applyCellContentShift(object: structure, cell: state.cell, spaceGroup: state.spaceGroup, atoms: state.atoms, bonds: state.bonds)
        }
      }
      
      let results: [(minimumEnergyValue: Double, voidFraction: Double)] = SKVoidFraction.compute(structures: iRASPAObjects.compactMap({$0.object as? Structure}).map{($0.cell, $0.atomUnitCellPositions, $0.potentialParameters)}, probeParameters: SIMD2<Double>(10.9, 2.64))
      
      for (i, result) in results.enumerated()
      {
        structures[i].minimumGridEnergyValue = Float(result.minimumEnergyValue)
        structures[i].structureHeliumVoidFraction = result.voidFraction
      }
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.transformContentCell])
    }
  }
  
  
  // MARK: Rotation
  // =====================================================================
  
  @IBAction func changedEulerAngleX(_ sender: NSTextField)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
       let renderOrientation: simd_quatd = self.renderOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.x = sender.doubleValue * Double.pi/180.0
      self.renderOrientation = simd_quatd(EulerAngles: angles)
      
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
    
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.boxOrientationCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  @IBAction func changedEulerAngleY(_ sender: NSTextField)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
       let renderOrientation: simd_quatd = self.renderOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.y = sender.doubleValue * Double.pi/180.0
      self.renderOrientation = simd_quatd(EulerAngles: angles)
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
   
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.boxOrientationCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  @IBAction func changedEulerAngleZ(_ sender: NSTextField)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
       let renderOrientation: simd_quatd = self.renderOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.z = sender.doubleValue * Double.pi/180.0
      self.renderOrientation = simd_quatd(EulerAngles: angles)
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
    
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.boxOrientationCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  @IBAction func rotateYawPlus(_ sender: NSButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
       let renderRotationDelta = self.renderRotationDelta,
       let renderOrientation: simd_quatd = self.renderOrientation
    {
      let dq: simd_quatd = simd_quatd(yaw: renderRotationDelta)
      
      self.renderOrientation = renderOrientation * dq
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.boxOrientationCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  
  @IBAction func rotateYawMinus(_ sender: NSButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
       let renderRotationDelta = self.renderRotationDelta,
       let renderOrientation: simd_quatd = self.renderOrientation
    {
      let dq: simd_quatd = simd_quatd(yaw: -renderRotationDelta)
      
      self.renderOrientation = renderOrientation * dq
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
     
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.boxOrientationCell, self.boxBoundingBoxInfoCell])
    }
    
  }
  
  @IBAction func rotatePitchPlus(_ sender: NSButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
       let renderRotationDelta = self.renderRotationDelta,
       let renderOrientation: simd_quatd = self.renderOrientation
    {
      let dq: simd_quatd = simd_quatd(pitch: renderRotationDelta)
      
      self.renderOrientation = renderOrientation * dq
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
  
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.boxOrientationCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  
  @IBAction func rotatePitchMinus(_ sender: NSButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
       let renderRotationDelta = self.renderRotationDelta,
       let renderOrientation: simd_quatd = self.renderOrientation
    {
      let dq: simd_quatd = simd_quatd(pitch: -renderRotationDelta)
      
      self.renderOrientation = renderOrientation * dq
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
 
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.boxOrientationCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  @IBAction func rotateRollPlus(_ sender: NSButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
       let renderRotationDelta = self.renderRotationDelta,
       let renderOrientation: simd_quatd = self.renderOrientation
    {
      let dq: simd_quatd = simd_quatd(roll: renderRotationDelta)
      
      self.renderOrientation = renderOrientation * dq
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
   
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.boxOrientationCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  
  @IBAction func rotateRollMinus(_ sender: NSButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
       let renderRotationDelta = self.renderRotationDelta,
       let renderOrientation: simd_quatd = self.renderOrientation
    {
      let dq: simd_quatd = simd_quatd(roll: -renderRotationDelta)
      
      self.renderOrientation = renderOrientation * dq
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
      {
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
      }
 
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.boxOrientationCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  @IBAction func changeRotationYawSlider(_ sender: NSSlider)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
       let renderOrientation = self.renderOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.x = sender.doubleValue * Double.pi/180.0
      self.renderOrientation = simd_quatd(EulerAngles: angles)
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      self.updateOutlineView(identifiers: [self.boxOrientationCell, self.boxBoundingBoxInfoCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        else if endingDrag
        {
          if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
          {
            self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
          }
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
          
          self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        }
        else
        {
          self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeRotationPitchSlider(_ sender: NSSlider)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
       let renderOrientation = self.renderOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.z = sender.doubleValue * Double.pi/180.0
      self.renderOrientation = simd_quatd(EulerAngles: angles)
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      self.updateOutlineView(identifiers: [self.boxOrientationCell, self.boxBoundingBoxInfoCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        else if endingDrag
        {
          if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
          {
            self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
          }
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
          self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        }
        else
        {
          self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changeRotationRollSlider(_ sender: NSSlider)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
       let renderOrientation = self.renderOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.y = sender.doubleValue * Double.pi/180.0
      self.renderOrientation = simd_quatd(EulerAngles: angles)
      project.renderCamera?.boundingBox = project.renderBoundingBox
      
      self.updateOutlineView(identifiers: [self.boxOrientationCell, self.boxBoundingBoxInfoCell])
      
      if let event: NSEvent = NSApplication.shared.currentEvent
      {
        let startingDrag: Bool = event.type == NSEvent.EventType.leftMouseDown
        let endingDrag: Bool = event.type == NSEvent.EventType.leftMouseUp
        
        if startingDrag
        {
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToMedium()
        }
        else if endingDrag
        {
          if let renderStructures = project.sceneList.selectedScene?.movies.flatMap({$0.selectedFrames}).compactMap({$0.renderStructure})
          {
            self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: renderStructures)
          }
          self.windowController?.detailTabViewController?.renderViewController?.setRenderQualityToHigh()
          self.windowController?.detailTabViewController?.renderViewController?.reloadData()
        }
        else
        {
          self.windowController?.detailTabViewController?.renderViewController?.reloadBoundingBoxData()
        }
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.updateStructureUniforms()
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  @IBAction func changedRotationAngle(_ sender: NSTextField)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      self.renderRotationDelta = sender.doubleValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.boxOrientationCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  
  // MARK: Structure properties
  // =====================================================================
  
  @IBAction func changeMaterialName(_ sender: NSComboBox)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      self.renderStructureMaterialType = sender.stringValue
    }
  }
  
  @IBAction func setHeliumVoidFraction(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.renderStructureHeliumVoidFraction = sender.doubleValue
      self.renderRecomputeDensityProperties()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralPropertiesCell])
    }
  }
  
  @IBAction func recomputeHeliumVoidFraction(_ sender: NSButton)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      let structures: [Structure & StructuralPropertyEditor & VolumetricDataViewer] = self.iRASPAObjects.compactMap({$0.object as? Structure & StructuralPropertyEditor & VolumetricDataViewer})
      let results: [(minimumEnergyValue: Double, voidFraction: Double)] = SKVoidFraction.compute(structures: structures.map{($0.cell, $0.atomUnitCellPositions, $0.potentialParameters)}, probeParameters: SIMD2<Double>(10.9, 2.64))
        
      for (i, result) in results.enumerated()
      {
        structures[i].minimumGridEnergyValue = Float(result.minimumEnergyValue)
        structures[i].structureHeliumVoidFraction = result.voidFraction
      }
      
      self.renderRecomputeDensityProperties()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralPropertiesCell])
    }
  }
  
  @IBAction func changeFrameworkProbeMolecule(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      let renderFrameworkProbeMolecule = Structure.ProbeMolecule(rawValue: sender.indexOfSelectedItem)
    {
      self.renderFrameworkProbeMolecule = renderFrameworkProbeMolecule
      
      self.renderRecomputeDensityProperties()
      
      do
      {
        let structures: [Structure] = self.iRASPAObjects.compactMap({$0.object as? Structure})
        let results: [Double] = try SKNitrogenSurfaceArea.compute(structures: structures.map{($0.cell, $0.atomUnitCellPositions, $0.potentialParameters, probeParameters: $0.frameworkProbeParameters)})
        for (i, result) in results.enumerated()
        {
          structures[i].structureNitrogenSurfaceArea = result
        }
      }
      catch let error
      {
        LogQueue.shared.error(destination: self.view.window?.windowController, message: error.localizedDescription)
        return
      }
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralProbeCell])
    }
  }
  
  @IBAction func recomputeNitrogenSurfaceArea(_ sender: NSButton)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
     do
      {
        let structures: [Structure & StructuralPropertyEditor & VolumetricDataViewer] = self.iRASPAObjects.compactMap({$0.object as? Structure & StructuralPropertyEditor & VolumetricDataViewer})
        let results: [Double] = try SKNitrogenSurfaceArea.compute(structures: structures.map{($0.cell, $0.atomUnitCellPositions, $0.potentialParameters, probeParameters: $0.frameworkProbeParameters)})
        for (i, result) in results.enumerated()
        {
          structures[i].structureNitrogenSurfaceArea = result
        }
      }
      catch let error
      {
        LogQueue.shared.error(destination: self.view.window?.windowController, message: error.localizedDescription)
        return
      }
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralProbeCell])
    }
  }
  
  @IBAction func setNumberOfChannelSystems(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEditable
    {
      self.renderStructureNumberOfChannelSystems = sender.integerValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralProbeCell])
    }
  }
  
  @IBAction func setNumberOfInaccessiblePockets(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.renderStructureNumberOfInaccessiblePockets = sender.integerValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralProbeCell])
    }
  }
  
  @IBAction func setDimensionalityOfPoreSystem(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.renderStructureDimensionalityOfPoreSystem = sender.integerValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralChannelCell])
    }
  }
  
  @IBAction func setLargestCavityDiameter(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.renderStructureLargestCavityDiameter = sender.doubleValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralChannelCell])
    }
  }
  
  
  @IBAction func setRestrictingPoreLimitingDiameter(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.renderStructureRestrictingPoreLimitingDiameter = sender.doubleValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralChannelCell])
    }
  }
  
  @IBAction func setLargestCavityDiameterAlongAViablePath(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.renderStructureLargestCavityDiameterAlongAViablePath = sender.doubleValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralChannelCell])
    }
  }
  
  
  // MARK: Spacegroup
  // =====================================================================
  
  // undo for large-changes: completely replace all atoms and bonds by new ones
  func setStructureState(structure: Structure, cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
      let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let oldCell: SKCell = structure.cell
      var oldSpaceGroup: SKSpacegroup = SKSpacegroup(HallNumber: 1)
      if let spaceGroupViewer = structure as? SpaceGroupEditor
      {
        oldSpaceGroup = spaceGroupViewer.spaceGroup
      }
      let oldAtoms: SKAtomTreeController = structure.atomTreeController
      let oldBonds: SKBondSetController = structure.bondSetController
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setStructureState(structure: structure, cell: oldCell, spaceGroup: oldSpaceGroup, atoms: oldAtoms, bonds: oldBonds)})
      
      structure.cell = cell
      if let spaceGroupViewer = structure as? SpaceGroupEditor
      {
        spaceGroupViewer.spaceGroup = spaceGroup
      }
      structure.atomTreeController = atoms
      structure.bondSetController = bonds
      
      structure.reComputeBoundingBox()
      
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      structure.setRepresentationColorScheme(scheme: structure.atomColorSchemeIdentifier, colorSets: document.colorSets)
      structure.setRepresentationForceField(forceField: structure.atomForceFieldIdentifier, forceFieldSets: document.forceFieldSets)
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: [structure])
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: [structure])
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.cellOutlineView?.reloadData()
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: structure)
      
      NotificationCenter.default.post(name: Notification.Name(NotificationStrings.SpaceGroupShouldReloadNotification), object: self.windowController)
    }
  }
  
  func setSpaceGroupHallNumber(structures: [Structure], number: [Int])
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.proxyProject?.representedObject.undoManager.setActionName(NSLocalizedString("Change Space Group", comment: ""))
     
      for (index, structure) in structures.enumerated()
      {
        if let state: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.setSpaceGroup(number: number[index])
        {
          self.setStructureState(structure: structure, cell: state.cell, spaceGroup: state.spaceGroup, atoms: state.atoms, bonds: state.bonds)
        }
      
        NotificationCenter.default.post(name: Notification.Name(NotificationStrings.BondsShouldReloadNotification), object: structure)
      }
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structures)
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: structures)
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
    
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.symmetrySpaceGroupCell, self.symmetryCenteringCell, self.symmetryPropertiesCell])
    }
  }
  
  @IBAction func setSpaceGroupHallNumber(_ sender: NSPopUpButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      
      let structures: [Structure] = iRASPAObjects.compactMap({$0.object as? Structure})
      self.setSpaceGroupHallNumber(structures: structures, number: Array(repeating: sender.indexOfSelectedItem, count: structures.count))
    }
  }
  
  @IBAction func setSpaceGroupNumber(_ sender: NSPopUpButton)
  {
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      let HallNumber: Int = SKSpacegroup.HallSymbolForConventionalSpaceGroupNumber(sender.indexOfSelectedItem)
      let structures: [Structure] = iRASPAObjects.compactMap({$0.object as? Structure})
      self.setSpaceGroupHallNumber(structures: structures, number: Array(repeating: HallNumber, count: structures.count))
    }
  }
  
  @IBAction func setSpaceGroupQualifier(_ sender: NSPopUpButton)
  {
    if let spaceGroupHallNumber: Int = self.spaceGroupHallNumber,
       let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      let spaceGroupNumber: Int = SKSpacegroup.SpaceGroupNumberForHallNumber(spaceGroupHallNumber)
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      let HallNumber: Int = SKSpacegroup.BaseHallSymbolForSpaceGroupNumber(spaceGroupNumber) + sender.indexOfSelectedItem
      let structures: [Structure] = iRASPAObjects.compactMap({$0.object as? Structure})
      self.setSpaceGroupHallNumber(structures: structures, number: Array(repeating: HallNumber, count: structures.count))
    }
  }
  
  @IBAction func setSpaceGroupPrecision(_ sender: NSTextField)
  {
    if let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.renderCellPrecision = sender.doubleValue
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      
      self.updateOutlineView(identifiers: [self.symmetrySpaceGroupCell, self.symmetryCenteringCell, self.symmetryPropertiesCell])
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
  
  
  // MARK: Cell Viewer
  //===================================================================================================================================================
  
  func reComputeBoundingBox()
  {
    self.iRASPAObjects.forEach({$0.object.reComputeBoundingBox()})
  }
  
  func renderRecomputeDensityProperties()
  {
    self.iRASPAObjects.compactMap({$0.object as? Structure}).forEach({$0.recomputeDensityProperties()})
  }
  
  public var renderBoundingBoxMinimumX: Double?
  {
    let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.boundingBox.minimum.x })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderBoundingBoxMinimumY: Double?
  {
    let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.boundingBox.minimum.y })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderBoundingBoxMinimumZ: Double?
  {
    let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.boundingBox.minimum.z })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderBoundingBoxMaximumX: Double?
  {
    let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.boundingBox.maximum.x })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderBoundingBoxMaximumY: Double?
  {
    let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.boundingBox.maximum.y })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderBoundingBoxMaximumZ: Double?
  {
    let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.boundingBox.maximum.z })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  
  
  public var renderUnitCellLengthA: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.a })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.a = newValue ?? 20.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellLengthB: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.b })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.b = newValue ?? 20.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellLengthC: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.c })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.c = newValue ?? 20.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  
  public var renderUnitCellAlphaAngle: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.alpha * 180.0/Double.pi })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.alpha = (newValue ?? 90.0)  * (Double.pi / 180.0)
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellBetaAngle: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.beta * 180.0/Double.pi })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.beta = (newValue ?? 90.0)  * (Double.pi / 180.0)
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellGammaAngle: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.gamma * 180.0/Double.pi })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.gamma = (newValue ?? 90.0)  * (Double.pi / 180.0)
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellAX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.unitCell[0].x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.unitCell[0].x = newValue ?? 20.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellAY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.unitCell[0].y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.unitCell[0].y = newValue ?? 0.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellAZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.unitCell[0].z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.unitCell[0].z = newValue ?? 0.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellBX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.unitCell[1].x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.unitCell[1].x = newValue ?? 0.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellBY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.unitCell[1].y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.unitCell[1].y = newValue ?? 20.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellBZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.unitCell[1].z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{$0.object.cell.unitCell[1].z = newValue ?? 20.0}
    }
  }
  
  public var renderUnitCellCX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.unitCell[2].x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.unitCell[2].x = newValue ?? 0.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellCY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.unitCell[2].y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.unitCell[2].y = newValue ?? 0.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderUnitCellCZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.unitCell[2].z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.unitCell[2].z = newValue ?? 20.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderCellVolume: Double?
  {
    let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cellVolume })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderCellPerpendicularWidthX: Double?
  {
    let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cellPerpendicularWidthsX })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderCellPerpendicularWidthY: Double?
  {
    let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cellPerpendicularWidthsY })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderCellPerpendicularWidthZ: Double?
  {
    let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cellPerpendicularWidthsZ })
    return Set(set).count == 1 ? set.first! : nil
  }
  
  public var renderMinimumReplicaX: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.minimumReplica.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.minimumReplica.x = newValue ?? 0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderMinimumReplicaY: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.minimumReplica.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.minimumReplica.y = newValue ?? 0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderMinimumReplicaZ: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.minimumReplica.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.minimumReplica.z = newValue ?? 0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderMaximumReplicaX: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.maximumReplica.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.maximumReplica.x = newValue ?? 0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderMaximumReplicaY: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.maximumReplica.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.maximumReplica.y = newValue ?? 0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderMaximumReplicaZ: Int32?
  {
    get
    {
      let set: Set<Int32> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.maximumReplica.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.maximumReplica.z = newValue ?? 0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderOrientation: simd_quatd?
  {
    get
    {
      let origin: [simd_quatd] = self.iRASPAObjects.compactMap{$0.object.orientation}
      let q: simd_quatd = origin.reduce(simd_quatd()){return simd_add($0, $1)}
      let averaged_vector: simd_quatd = simd_quatd(ix: q.vector.x / Double(origin.count), iy: q.vector.y / Double(origin.count), iz: q.vector.z / Double(origin.count), r: q.vector.w / Double(origin.count))
      return origin.isEmpty ? nil : averaged_vector
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{$0.object.orientation = newValue ?? simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)}
    }
  }
  
  public var renderRotationDelta: Double?
  {
    get
    {
      let origin: [Double] = self.iRASPAObjects.compactMap{$0.object.rotationDelta}
      return origin.isEmpty ? nil : origin.reduce(0.0){return $0 + $1} / Double(origin.count)
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{$0.object.rotationDelta = newValue ?? 5.0}
    }
  }
  
  public var renderEulerAngleX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return ($0.object.orientation.EulerAngles).x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{$0.object.orientation.EulerAngles = SIMD3<Double>(newValue ?? 0.0,$0.object.orientation.EulerAngles.y,$0.object.orientation.EulerAngles.z)}
    }
  }
  
  public var renderEulerAngleY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return ($0.object.orientation.EulerAngles).y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{$0.object.orientation.EulerAngles = SIMD3<Double>($0.object.orientation.EulerAngles.x, newValue ?? 0.0,$0.object.orientation.EulerAngles.z)}
    }
  }
  
  public var renderEulerAngleZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return ($0.object.orientation.EulerAngles).z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{$0.object.orientation.EulerAngles = SIMD3<Double>($0.object.orientation.EulerAngles.x, $0.object.orientation.EulerAngles.y, newValue ?? 0.0)}
    }
  }
  
  public var renderOriginX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.origin.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.origin.x = newValue ?? 0.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderOriginY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.origin.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.origin.y = newValue ?? 0.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  public var renderOriginZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.origin.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.origin.z = newValue ?? 0.0
        $0.object.reComputeBoundingBox()
      }
    }
  }
  
  // MARK: StructuralProperty Viewer
  //===================================================================================================================================================
  
  public var renderMaterialType: Object.ObjectType?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{ return $0.object.materialType.rawValue })
      return Set(set).count == 1 ? Object.ObjectType(rawValue: set.first!) : nil
    }
  }
  
  public var renderStructureMaterialType: String?
  {
    get
    {
      let set: Set<String> = Set(self.iRASPAObjects.compactMap{($0.object as? StructuralPropertyEditor)?.structureMaterialType})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? StructuralPropertyEditor)?.structureMaterialType = newValue ?? ""}
    }
  }
  
  public var renderStructureMass: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? StructuralPropertyEditor)?.structureMass})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? StructuralPropertyEditor)?.structureMass = newValue ?? 0.0}
    }
  }
  
  public var renderStructureDensity: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? StructuralPropertyEditor)?.structureDensity})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? StructuralPropertyEditor)?.structureDensity = newValue ?? 0.0}
    }
  }
  
  public var renderStructureHeliumVoidFraction: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureHeliumVoidFraction})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureHeliumVoidFraction = newValue ?? 0.0}
    }
  }
  
  public var renderStructureSpecificVolume: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? StructuralPropertyEditor)?.structureSpecificVolume})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? StructuralPropertyEditor)?.structureSpecificVolume = newValue ?? 0.0}
    }
  }
  
  public var renderStructureAccessiblePoreVolume: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureAccessiblePoreVolume})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureAccessiblePoreVolume = newValue ?? 0.0}
    }
  }
  
  public var renderFrameworkProbeMolecule: Structure.ProbeMolecule?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.frameworkProbeMolecule.rawValue})
      return Set(set).count == 1 ? Structure.ProbeMolecule(rawValue: set.first!) : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.frameworkProbeMolecule = newValue ?? .helium}
    }
  }
  
  public var renderStructureVolumetricNitrogenSurfaceArea: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureVolumetricNitrogenSurfaceArea})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureVolumetricNitrogenSurfaceArea = newValue ?? 0.0}
    }
  }
  
  public var renderStructureGravimetricNitrogenSurfaceArea: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureGravimetricNitrogenSurfaceArea})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureGravimetricNitrogenSurfaceArea = newValue ?? 0.0}
    }
  }
  
  public var renderStructureNumberOfChannelSystems: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureNumberOfChannelSystems})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureNumberOfChannelSystems = newValue ?? 0}
    }
  }
  
  
  public var renderStructureNumberOfInaccessiblePockets: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureNumberOfInaccessiblePockets})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureNumberOfInaccessiblePockets = newValue ?? 0}
    }
  }
  
  public var renderStructureDimensionalityOfPoreSystem: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureDimensionalityOfPoreSystem})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureDimensionalityOfPoreSystem = newValue ?? 0}
    }
  }
  
  public var renderStructureLargestCavityDiameter: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureLargestCavityDiameter})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureLargestCavityDiameter = newValue ?? 0.0}
    }
  }
  
  
  public var renderStructureRestrictingPoreLimitingDiameter: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureRestrictingPoreLimitingDiameter})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureRestrictingPoreLimitingDiameter = newValue ?? 0.0}
    }
  }
  
  public var renderStructureLargestCavityDiameterAlongAViablePath: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureLargestCavityDiameterAlongAViablePath})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? StructuralPropertyEditor & VolumetricDataViewer)?.structureLargestCavityDiameterAlongAViablePath = newValue ?? 0.0}
    }
  }
  
  public var renderContentShiftX: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.contentShift.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.contentShift.x = newValue ?? 0.0
      }
    }
  }
  
  public var renderContentShiftY: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.contentShift.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.contentShift.y = newValue ?? 0.0
      }
    }
  }
  
  public var renderContentShiftZ: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.contentShift.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.contentShift.z = newValue ?? 0.0
      }
    }
  }
  
  public var renderContentFlipX: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.contentFlip.x })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.contentFlip.x = newValue ?? false
      }
    }
  }
  
  public var renderContentFlipY: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.contentFlip.y })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.contentFlip.y = newValue ?? false
      }
    }
  }
  
  public var renderContentFlipZ: Bool?
  {
    get
    {
      let set: Set<Bool> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.contentFlip.z })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{
        $0.object.cell.contentFlip.z = newValue ?? false
      }
    }
  }
  
  // MARK: SpaceGroup Viewer
  //===================================================================================================================================================
  
  public var spaceGroupHallNumber: Int?
  {
    get
    {
      let set: Set<Int> = Set(self.iRASPAObjects.compactMap{($0.object as? SpaceGroupEditor)?.spaceGroupHallNumber})
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{($0.object as? SpaceGroupEditor)?.spaceGroupHallNumber = newValue ?? 1}
    }
  }
  
  public var renderCellPrecision: Double?
  {
    get
    {
      let set: Set<Double> = Set(self.iRASPAObjects.compactMap{ return $0.object.cell.precision })
      return Set(set).count == 1 ? set.first! : nil
    }
    set(newValue)
    {
      self.iRASPAObjects.forEach{$0.object.cell.precision = newValue ?? 1e-2}
    }
  }
}
