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
  
  var cellAngleFormatter: AngleNumberFormatter = AngleNumberFormatter()
  
  deinit
  {
    //Swift.print("deinit: StructureCellDetailViewController")
  }
  
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
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
          
          if let rawValue = representedStructure.renderMaterialType?.rawValue
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          textFieldMaximumX.doubleValue = representedStructure.renderBoundingBox.maximum.x
          textFieldMaximumY.doubleValue = representedStructure.renderBoundingBox.maximum.y
          textFieldMaximumZ.doubleValue = representedStructure.renderBoundingBox.maximum.z
          textFieldMinimumX.doubleValue = representedStructure.renderBoundingBox.minimum.x
          textFieldMinimumY.doubleValue = representedStructure.renderBoundingBox.minimum.y
          textFieldMinimumZ.doubleValue = representedStructure.renderBoundingBox.minimum.z
        }
      }
    case "BoxUnitCellPropertiesCell":
      if let textFieldLengthA: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldLengthA.isEditable = false
        textFieldLengthA.stringValue = ""
        textFieldLengthA.isEnabled = false
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldLengthA.isEnabled = enabled && renderPeriodic
          }
          textFieldLengthA.isEditable = enabled
          if let renderLengthA: Double = representedStructure.renderUnitCellLengthA
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldLengthB.isEnabled = enabled && renderPeriodic
          }
          textFieldLengthB.isEditable = enabled
          if let renderLengthB: Double = representedStructure.renderUnitCellLengthB
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldLengthC.isEnabled = enabled && renderPeriodic
          }
          textFieldLengthC.isEditable = enabled
          if let renderLengthC: Double = representedStructure.renderUnitCellLengthC
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          textFieldAlphaAngle.formatter = cellAngleFormatter
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldAlphaAngle.isEnabled = enabled && renderPeriodic
          }
          textFieldAlphaAngle.isEditable = enabled
          if let renderAlphaAngle: Double = representedStructure.renderUnitCellAlphaAngle
          {
            textFieldAlphaAngle.doubleValue = renderAlphaAngle * 180.0/Double.pi
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldBetaAngle.isEnabled = enabled && renderPeriodic
          }
          textFieldBetaAngle.isEditable = enabled
          if let renderBetaAngle: Double = representedStructure.renderUnitCellBetaAngle
          {
            textFieldBetaAngle.doubleValue = renderBetaAngle * 180.0/Double.pi
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldGammaAngle.isEnabled = enabled && renderPeriodic
          }
          textFieldGammaAngle.isEditable = enabled
          if let renderGammaAngle: Double = representedStructure.renderUnitCellGammaAngle
          {
            textFieldGammaAngle.doubleValue = renderGammaAngle * 180.0/Double.pi
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer],
           let renderPeriodic: Bool = representedStructure.renderPeriodic
        {
          stepperLengthA.isEnabled = enabled && renderPeriodic
          stepperLengthB.isEnabled = enabled && renderPeriodic
          stepperLengthC.isEnabled = enabled && renderPeriodic
          stepperAngleAlpha.isEnabled = enabled && renderPeriodic
          stepperAngleBeta.isEnabled = enabled && renderPeriodic
          stepperAngleGamma.isEnabled = enabled && renderPeriodic
        }
      }
    case "BoxUnitCellInfoCell":
      if let textFieldRenderUnitCellAX: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldRenderUnitCellAX.isEditable = false
        textFieldRenderUnitCellAX.stringValue = ""
        textFieldRenderUnitCellAX.isEnabled = false
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderUnitCellAX.isEnabled = enabled && renderPeriodic
          }
          if let renderUnitCellAX: Double = representedStructure.renderUnitCellAX
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderUnitCellAY.isEnabled = enabled && renderPeriodic
          }
          if let renderUnitCellAY: Double = representedStructure.renderUnitCellAY
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderUnitCellAZ.isEnabled = enabled && renderPeriodic
          }
          if let renderUnitCellAZ: Double = representedStructure.renderUnitCellAZ
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderUnitCellBX.isEnabled = enabled && renderPeriodic
          }
          if let renderUnitCellBX: Double = representedStructure.renderUnitCellBX
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderUnitCellBY.isEnabled = enabled && renderPeriodic
          }
          if let renderUnitCellBY: Double = representedStructure.renderUnitCellBY
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderUnitCellBZ.isEnabled = enabled && renderPeriodic
          }
          if let renderUnitCellBZ: Double = representedStructure.renderUnitCellBZ
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderUnitCellCX.isEnabled = enabled && renderPeriodic
          }
          if let renderUnitCellCX: Double = representedStructure.renderUnitCellCX
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderUnitCellCY.isEnabled = enabled && renderPeriodic
          }
          if let renderUnitCellCY: Double = representedStructure.renderUnitCellCY
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderUnitCellCZ.isEnabled = enabled && renderPeriodic
          }
          if let renderUnitCellCZ: Double = representedStructure.renderUnitCellCZ
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldVolume.isEnabled = enabled && renderPeriodic
          }
          if let renderUnitCellVolume: Double = representedStructure.renderCellVolume
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldPerpendicularWidthX.isEnabled = enabled && renderPeriodic
          }
          if let renderPerpendicularWidthX: Double = representedStructure.renderCellPerpendicularWidthX
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldPerpendicularWidthY.isEnabled = enabled && renderPeriodic
          }
          if let renderPerpendicularWidthY: Double = representedStructure.renderCellPerpendicularWidthY
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldPerpendicularWidthZ.isEnabled = enabled && renderPeriodic
          }
          if let renderPerpendicularWidthZ: Double = representedStructure.renderCellPerpendicularWidthZ
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldMaximumReplicaX.isEnabled = enabled && renderPeriodic
          }
          textFieldMaximumReplicaX.isEditable = enabled
          if let maximumReplicaX: Int32 = representedStructure.renderMaximumReplicaX
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldMaximumReplicaY.isEnabled = enabled && renderPeriodic
          }
          textFieldMaximumReplicaY.isEditable = enabled
          if let maximumReplicaY: Int32 = representedStructure.renderMaximumReplicaY
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldMaximumReplicaZ.isEnabled = enabled && renderPeriodic
          }
          textFieldMaximumReplicaZ.isEditable = enabled
          if let maximumReplicaZ: Int32 = representedStructure.renderMaximumReplicaZ
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldMinimumReplicaX.isEnabled = enabled && renderPeriodic
          }
          textFieldMinimumReplicaX.isEditable = enabled
          if let minimumReplicaX: Int32 = representedStructure.renderMinimumReplicaX
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldMinimumReplicaY.isEnabled = enabled && renderPeriodic
          }
          textFieldMinimumReplicaY.isEditable = enabled
          if let minimumReplicaY: Int32 = representedStructure.renderMinimumReplicaY
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldMinimumReplicaZ.isEnabled = enabled && renderPeriodic
          }
          textFieldMinimumReplicaZ.isEditable = enabled
          if let minimumReplicaZ: Int32 = representedStructure.renderMinimumReplicaZ
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer],
           let renderPeriodic: Bool = representedStructure.renderPeriodic
        {
          stepperMaximumReplicaX.isEnabled = enabled && renderPeriodic
          stepperMaximumReplicaY.isEnabled = enabled && renderPeriodic
          stepperMaximumReplicaZ.isEnabled = enabled && renderPeriodic
          stepperMinimumReplicaX.isEnabled = enabled && renderPeriodic
          stepperMinimumReplicaY.isEnabled = enabled && renderPeriodic
          stepperMinimumReplicaZ.isEnabled = enabled && renderPeriodic
        }
      }
    case "BoxOrientationCell":
      if let renderRotationDelta: Double = (self.representedObject as? [CellViewer])?.renderRotationDelta
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
        
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderEulerAngleX: Double = representedStructure.renderEulerAngleX,
             let renderEulerAngleY: Double = representedStructure.renderEulerAngleY,
             let renderEulerAngleZ: Double = representedStructure.renderEulerAngleZ
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          textFieldOriginX.isEditable = enabled
          if let renderOriginX: Double = representedStructure.renderOriginX
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          textFieldOriginY.isEditable = enabled
          if let renderOriginY: Double = representedStructure.renderOriginY
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          textFieldOriginZ.isEditable = enabled
          if let renderOriginZ: Double = representedStructure.renderOriginZ
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          button.isEnabled = enabled
          if let renderContentFlipX: Bool = representedStructure.renderContentFlipX
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          button.isEnabled = enabled
          if let renderContentFlipY: Bool = representedStructure.renderContentFlipY
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          button.isEnabled = enabled
          if let renderContentFlipZ: Bool = representedStructure.renderContentFlipZ
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          textFieldCenterShiftX.isEditable = enabled
          if let renderCenterShiftX: Double = representedStructure.renderContentShiftX
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          textFieldCenterShiftY.isEditable = enabled
          if let renderCenterShiftY: Double = representedStructure.renderContentShiftY
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          textFieldCenterShiftZ.isEditable = enabled
          if let renderCenterShiftZ: Double = representedStructure.renderContentShiftZ
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          comboBoxRenderStructureMaterialType.isEditable = enabled
          
          if let value: String = representedStructure.renderStructureMaterialType
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let structureMass: Double = representedStructure.renderStructureMass
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          textFieldRenderStructureDensity.isEnabled = false
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderStructureDensity.isEnabled = enabled && renderPeriodic
          }
          if let structureDensity: Double = representedStructure.renderStructureDensity
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          textFieldRenderStructureHeliumVoidFraction.isEnabled = false
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderStructureHeliumVoidFraction.isEnabled = enabled && renderPeriodic
          }
          if let structureHeliumVoidFraction: Double = representedStructure.renderStructureHeliumVoidFraction
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          textFieldRenderStructureSpecificVolume.isEnabled = false
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderStructureSpecificVolume.isEnabled = enabled && renderPeriodic
          }
          if let structureSpecificVolume: Double = representedStructure.renderStructureSpecificVolume
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          textFieldRenderStructureAccessiblePoreVolume.isEnabled = false
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderStructureAccessiblePoreVolume.isEnabled = enabled && renderPeriodic
          }
          if let structureAccessiblePoreVolume: Double = representedStructure.renderStructureAccessiblePoreVolume
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic, renderPeriodic
          {
            buttonComputeHeliumVoidFraction.isEnabled = enabled
          }
          else
          {
            buttonComputeHeliumVoidFraction.isEnabled = false
          }
        }
      }
      
     
    case "StructuralProbeCell":
      // Probe molecule
      if let popUpbuttonProbeParticle: iRASPAPopUpButton = view.viewWithTag(1) as? iRASPAPopUpButton
      {
        popUpbuttonProbeParticle.isEditable = false
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          popUpbuttonProbeParticle.isEditable = enabled
          if let probeMolecule: Structure.ProbeMolecule = representedStructure.renderFrameworkProbeMolecule
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderStructureVolumetricNitrogenSurfaceArea.isEnabled = enabled && renderPeriodic
          }
          if let structureVolumetricNitrogenSurfaceArea: Double = representedStructure.renderStructureVolumetricNitrogenSurfaceArea
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderStructureGravimetricNitrogenSurfaceArea.isEnabled = enabled && renderPeriodic
          }
          if let structureGravimetricNitrogenSurfaceArea: Double = representedStructure.renderStructureGravimetricNitrogenSurfaceArea
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderStructureNumberOfChannelSystems.isEnabled = enabled && renderPeriodic
          }
          textFieldRenderStructureNumberOfChannelSystems.isEditable = enabled
          if let structureNumberOfChannelSystems: Int = representedStructure.renderStructureNumberOfChannelSystems
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderStructureNumberOfInaccessiblePockets.isEnabled = enabled && renderPeriodic
          }
          textFieldRenderStructureNumberOfInaccessiblePockets.isEditable = enabled
          if let structureNumberOfInaccessiblePockets: Int = representedStructure.renderStructureNumberOfInaccessiblePockets
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic, renderPeriodic
          {
            buttonComputeVolumetricSurfaceArea.isEnabled = enabled
          }
          else
          {
            buttonComputeVolumetricSurfaceArea.isEnabled = false
          }
        }
      }
    
      if let buttonComputeGeometricSurfaceArea: NSButton = view.viewWithTag(11) as? NSButton
      {
        buttonComputeGeometricSurfaceArea.isEnabled = false
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic, renderPeriodic
          {
            buttonComputeGeometricSurfaceArea.isEnabled = enabled
          }
          else
          {
            buttonComputeGeometricSurfaceArea.isEnabled = false
          }
        }
      }
  
    case "StructuralChannelCell":
     
      if let textFieldRenderStructureDimensionalityOfPoreSystem: NSTextField = view.viewWithTag(1) as? NSTextField
      {
        textFieldRenderStructureDimensionalityOfPoreSystem.isEditable = false
        textFieldRenderStructureDimensionalityOfPoreSystem.stringValue = ""
        textFieldRenderStructureDimensionalityOfPoreSystem.isEnabled = false
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderStructureDimensionalityOfPoreSystem.isEnabled = enabled && renderPeriodic
          }
          textFieldRenderStructureDimensionalityOfPoreSystem.isEditable = enabled
          if let structureDimensionalityOfPoreSystem: Int = representedStructure.renderStructureDimensionalityOfPoreSystem
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderStructureLargestCavityDiameter.isEnabled = enabled && renderPeriodic
          }
          textFieldRenderStructureLargestCavityDiameter.isEditable = enabled
          if let structureLargestCavityDiameterX: Double = representedStructure.renderStructureLargestCavityDiameter
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderStructureRestrictingPoreLimitingDiameter.isEnabled = enabled && renderPeriodic
          }
          textFieldRenderStructureRestrictingPoreLimitingDiameter.isEditable = enabled
          if let structureRestrictingPoreLimitingDiameter: Double = representedStructure.renderStructureRestrictingPoreLimitingDiameter
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          if let renderPeriodic: Bool = representedStructure.renderPeriodic
          {
            textFieldRenderStructureLargestCavityDiameterAlongAViablePath.isEnabled = enabled && renderPeriodic
          }
          textFieldRenderStructureLargestCavityDiameterAlongAViablePath.isEditable = enabled
          if let structureLargestCavityDiameterAlongAViablePath: Double = representedStructure.renderStructureLargestCavityDiameterAlongAViablePath
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
        
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer],
          !representedStructure.allStructures.filter({$0 is SpaceGroupProtocol}).isEmpty
        {
          HallSpaceGroupPopUpButton.isEditable = enabled
          spaceGroupNumberPopUpButton.isEditable = enabled
          
          if let spaceGroupHallNumber: Int = representedStructure.spaceGroupHallNumber
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
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer]
        {
          textFieldRenderPrecision.isEditable = enabled
          if let renderPrecision: Double = representedStructure.renderCellPrecision
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
        
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer],
          !representedStructure.allStructures.filter({$0 is SpaceGroupProtocol}).isEmpty
        {
        
          if let spaceGroupHallNumber: Int = representedStructure.spaceGroupHallNumber
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
        
        if let representedStructure: [CellViewer] = representedObject as? [CellViewer],
          !representedStructure.allStructures.filter({$0 is SpaceGroupProtocol}).isEmpty
        {
          if let spaceGroupHallNumber: Int = representedStructure.spaceGroupHallNumber
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
    if let cellViewers: [CellViewer] = self.representedObject as? [CellViewer],
       let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       let project = projectTreeNode.representedObject.loadedProjectStructureNode
    {
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      projectTreeNode.representedObject.isEdited = true
      
      // remove the measuring nodes
      project.measurementTreeNodes = []
      
      var to: [iRASPAStructure] = []
      var from: [iRASPAStructure] = []
      for cellViewer in cellViewers
      {
        for i in 0..<cellViewer.frames.count
        {
          from.append(cellViewer.frames[i])
          switch(SKStructure.Kind(rawValue: sender.indexOfSelectedItem))
          {
          case .none,.unknown, .structure:
            return
          case .crystal:
            to.append(iRASPAStructure(crystal: Crystal(clone: cellViewer.frames[i].structure)))
          case .molecularCrystal:
            to.append(iRASPAStructure(molecularCrystal: MolecularCrystal(clone: cellViewer.frames[i].structure)))
          case .molecule:
            to.append(iRASPAStructure(molecule: Molecule(clone: cellViewer.frames[i].structure)))
          case .protein:
            to.append(iRASPAStructure(protein: Protein(clone: cellViewer.frames[i].structure)))
          case .proteinCrystal:
            to.append(iRASPAStructure(proteinCrystal: ProteinCrystal(clone: cellViewer.frames[i].structure)))
          case .proteinCrystalSolvent,.crystalSolvent,.molecularCrystalSolvent:
            return
          case .crystalEllipsoidPrimitive:
            to.append(iRASPAStructure(crystalEllipsoidPrimitive: CrystalEllipsoidPrimitive(clone: cellViewer.frames[i].structure)))
          case .crystalCylinderPrimitive:
            to.append(iRASPAStructure(crystalCylinderPrimitive: CrystalCylinderPrimitive(clone: cellViewer.frames[i].structure)))
          case .crystalPolygonalPrismPrimitive:
            to.append(iRASPAStructure(crystalPolygonalPrismPrimitive: CrystalPolygonalPrismPrimitive(clone: cellViewer.frames[i].structure)))
          case .ellipsoidPrimitive:
            to.append(iRASPAStructure(ellipsoidPrimitive: EllipsoidPrimitive(clone: cellViewer.frames[i].structure)))
          case .cylinderPrimitive:
            to.append(iRASPAStructure(cylinderPrimitive: CylinderPrimitive(clone: cellViewer.frames[i].structure)))
          case .polygonalPrismPrimitive:
            to.append(iRASPAStructure(polygonalPrismPrimitive: PolygonalPrismPrimitive(clone: cellViewer.frames[i].structure)))
          }
        }
      }
      self.replaceStructure(structures: from, to: to)
      
      project.isEdited = true
      
    }
  }
  
  func replaceStructure(structures from: [iRASPAStructure], to: [iRASPAStructure])
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
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: to.map{$0.structure})
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: to.map{$0.structure})
      
      project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
      
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.windowController?.detailTabViewController?.renderViewController?.redraw()
      
      self.windowController?.detailTabViewController?.reloadData()
    }
  }
  
  // MARK: Cell changes
  // =====================================================================
  
  @IBAction func changedCellLengthA(_ sender: NSTextField)
  {
    let newValue: Double = sender.doubleValue
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       var structure: [CellViewer] = self.representedObject as? [CellViewer]
    {
      structure.renderUnitCellLengthA = newValue
      structure.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
      
      
      
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderUnitCellLengthA: Double = structure.renderUnitCellLengthA,
       let _ = structure.renderPeriodic
    {
      let newValue: Double = renderUnitCellLengthA + deltaValue
      structure.renderUnitCellLengthA = newValue
      structure.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
      
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
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       var structure: [CellViewer] = self.representedObject as? [CellViewer]
    {
      structure.renderUnitCellLengthB = newValue
      structure.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
      
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderUnitCellLengthB: Double = structure.renderUnitCellLengthB,
       let _ = structure.renderPeriodic
    {
      let newValue: Double = renderUnitCellLengthB + deltaValue
      structure.renderUnitCellLengthB = newValue
      structure.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
      
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
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       var structure: [CellViewer] = self.representedObject as? [CellViewer]
    {
      structure.renderUnitCellLengthC = newValue
      structure.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
      
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderUnitCellLengthC: Double = structure.renderUnitCellLengthC,
       let _ = structure.renderPeriodic
    {
      let newValue: Double = renderUnitCellLengthC + deltaValue
      structure.renderUnitCellLengthC = newValue
      structure.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
      
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
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       var structure: [CellViewer] = self.representedObject as? [CellViewer]
    {
      structure.renderUnitCellAlphaAngle = newValue * Double.pi / 180.0
      structure.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
        
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
      
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderUnitCellAlphaAngle: Double = structure.renderUnitCellAlphaAngle,
       let _ = structure.renderPeriodic
    {
      let newValue: Double = renderUnitCellAlphaAngle + deltaValue * Double.pi / 180.0
      structure.renderUnitCellAlphaAngle = newValue
      structure.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
      
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
    let newValue: Double = sender.doubleValue * Double.pi / 180.0
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       var structure: [CellViewer] = self.representedObject as? [CellViewer]
    {
      structure.renderUnitCellBetaAngle = newValue
      structure.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
      
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderUnitCellBetaAngle: Double = structure.renderUnitCellBetaAngle,
       let _ = structure.renderPeriodic
    {
      let newValue: Double = renderUnitCellBetaAngle + deltaValue * Double.pi / 180.0
      structure.renderUnitCellBetaAngle = newValue
      structure.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
      
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
    let newValue: Double = sender.doubleValue * Double.pi / 180.0
    
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       var structure: [CellViewer] = self.representedObject as? [CellViewer]
    {
      structure.renderUnitCellGammaAngle = newValue
      structure.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
      
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderUnitCellGammaAngle: Double = structure.renderUnitCellGammaAngle,
       let _ = structure.renderPeriodic
    {
      let newValue: Double = renderUnitCellGammaAngle + deltaValue * Double.pi / 180.0
      structure.renderUnitCellGammaAngle = newValue
      structure.reComputeBoundingBox()
      
      self.updateOutlineView(identifiers: [self.boxMaterialInfoCell, self.boxBoundingBoxInfoCell, self.boxUnitCellPropertiesCell, self.boxUnitCellInfoCell, self.boxVolumeCell])
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
      
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
       var structure: [CellViewer] = (self.representedObject as? [CellViewer]),
       let renderMaximumReplicaX: Int32 = structure.renderMaximumReplicaX,
       let _ = structure.renderPeriodic
    {
      if (newValue <= renderMaximumReplicaX)
      {
        
        structure.renderMinimumReplicaX = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          structure.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: structure.allRenderFrames)
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
        
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
       var structure: [CellViewer] = (self.representedObject as? [CellViewer]),
       let renderMaximumReplicaY: Int32 = structure.renderMaximumReplicaY,
       let _ = structure.renderPeriodic
    {
      
      if (newValue <= renderMaximumReplicaY)
      {
        structure.renderMinimumReplicaY = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          structure.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: structure.allRenderFrames)
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
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
       var structure: [CellViewer] = (self.representedObject as? [CellViewer]),
      let renderMaximumReplicaZ: Int32 = structure.renderMaximumReplicaZ,
      let _ = structure.renderPeriodic
    {
      if (newValue <= renderMaximumReplicaZ)
      {
        structure.renderMinimumReplicaZ = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          structure.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: structure.allRenderFrames)
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
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
      var structure: [CellViewer] = self.representedObject as? [CellViewer],
      let renderMinimumReplicaX: Int32 = structure.renderMinimumReplicaX,
      let _ = structure.renderPeriodic
    {
      if (newValue >= renderMinimumReplicaX)
      {
        structure.renderMaximumReplicaX = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          structure.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: structure.allRenderFrames)
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderMinimumReplicaY: Int32 = structure.renderMinimumReplicaY,
       let _ = structure.renderPeriodic
    {
      if (newValue >= renderMinimumReplicaY)
      {
        structure.renderMaximumReplicaY = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          structure.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: structure.allRenderFrames)
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderMinimumReplicaZ: Int32 = structure.renderMinimumReplicaZ,
       let _ = structure.renderPeriodic
    {
      if (newValue >= renderMinimumReplicaZ)
      {
        structure.renderMaximumReplicaZ = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          structure.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: structure.allRenderFrames)
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderMinimumReplicaX: Int32 = structure.renderMinimumReplicaX,
       let renderMaximumReplicaX: Int32 = structure.renderMaximumReplicaX,
       let _ = structure.renderPeriodic
    {
      
      let newValue: Int32 = renderMinimumReplicaX + deltaValue
      
      if (newValue <= renderMaximumReplicaX)
      {
        structure.renderMinimumReplicaX = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          structure.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
      
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: structure.allRenderFrames)
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderMinimumReplicaY: Int32 = structure.renderMinimumReplicaY,
       let renderMaximumReplicaY: Int32 = structure.renderMaximumReplicaY,
       let _ = structure.renderPeriodic
    {
      let newValue: Int32 = renderMinimumReplicaY + deltaValue
      
      if (newValue <= renderMaximumReplicaY)
      {
        structure.renderMinimumReplicaY = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          structure.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: structure.allRenderFrames)
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderMinimumReplicaZ: Int32 = structure.renderMinimumReplicaZ,
       let renderMaximumReplicaZ: Int32 = structure.renderMaximumReplicaZ,
       let _ = structure.renderPeriodic
    {
      let newValue: Int32 = renderMinimumReplicaZ + deltaValue
      
      if (newValue <= renderMaximumReplicaZ)
      {
        structure.renderMinimumReplicaZ = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          structure.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: structure.allRenderFrames)
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderMinimumReplicaX: Int32 = structure.renderMinimumReplicaX,
       let renderMaximumReplicaX: Int32 = structure.renderMaximumReplicaX,
       let _ = structure.renderPeriodic
    {
      let newValue: Int32 = renderMaximumReplicaX + deltaValue
      
      if (newValue >= renderMinimumReplicaX)
      {
        structure.renderMaximumReplicaX = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          structure.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: structure.allRenderFrames)
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderMinimumReplicaY: Int32 = structure.renderMinimumReplicaY,
       let renderMaximumReplicaY: Int32 = structure.renderMaximumReplicaY,
       let _ = structure.renderPeriodic
    {
      let newValue: Int32 = renderMaximumReplicaY + deltaValue
      
      if (newValue >= renderMinimumReplicaY)
      {
        structure.renderMaximumReplicaY = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          structure.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: structure.allRenderFrames)
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderMinimumReplicaZ: Int32 = structure.renderMinimumReplicaZ,
       let renderMaximumReplicaZ: Int32 = structure.renderMaximumReplicaZ,
       let _ = structure.renderPeriodic
    {
      let newValue: Int32 = renderMaximumReplicaZ + deltaValue
      
      if (newValue >= renderMinimumReplicaZ)
      {
        structure.renderMaximumReplicaZ = newValue
        
        if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
        {
          structure.reComputeBoundingBox()
          project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
          project.checkValidatyOfMeasurementPoints()
        }
        
        //self.windowController?.detailTabViewController?.renderViewController?.invalidateIsosurface(cachedIsosurfaces: structure.allRenderFrames)
        self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
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
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
       var structure: [CellViewer] = self.representedObject as? [CellViewer]
    {
      structure.renderOriginX = newValue
      
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
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
       var structure: [CellViewer] = self.representedObject as? [CellViewer]
    {
      structure.renderOriginY = newValue
      
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
       let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
       var structure: [CellViewer] = self.representedObject as? [CellViewer]
    {
      structure.renderOriginZ = newValue
      
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
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var structure: [CellViewer] = self.representedObject as? [CellViewer]
    {
      structure.renderContentShiftX = newValue
      
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderContentShiftX: Double = structure.renderContentShiftX
    {
      let newValue: Double = renderContentShiftX + deltaValue * 0.01
      
      structure.renderContentShiftX = newValue
        
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
      {
        structure.reComputeBoundingBox()
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        project.checkValidatyOfMeasurementPoints()
      }
        
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
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
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var structure: [CellViewer] = self.representedObject as? [CellViewer]
    {
      structure.renderContentShiftY = newValue
      
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
      var structure: [CellViewer] = self.representedObject as? [CellViewer],
      let renderContentShiftY: Double = structure.renderContentShiftY
    {
      let newValue: Double = renderContentShiftY + deltaValue * 0.01
      
      structure.renderContentShiftY = newValue
      
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
      {
        structure.reComputeBoundingBox()
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        project.checkValidatyOfMeasurementPoints()
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
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
      let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode,
      var structure: [CellViewer] = self.representedObject as? [CellViewer]
    {
      structure.renderContentShiftZ = newValue
      
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
      var structure: [CellViewer] = self.representedObject as? [CellViewer],
      let renderContentShiftZ: Double = structure.renderContentShiftZ
    {
      let newValue: Double = renderContentShiftZ + deltaValue * 0.01
      
      structure.renderContentShiftZ = newValue
      
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
      {
        structure.reComputeBoundingBox()
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        project.checkValidatyOfMeasurementPoints()
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
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
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var structure: [CellViewer] = representedObject as? [CellViewer]
    {
      sender.allowsMixedState = false
      structure.renderContentFlipX = (sender.state == NSControl.StateValue.on)
      
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
      {
        structure.reComputeBoundingBox()
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        project.checkValidatyOfMeasurementPoints()
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.transformContentCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  @IBAction func toggleFlipContentY(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var structure: [CellViewer] = representedObject as? [CellViewer]
    {
      sender.allowsMixedState = false
      structure.renderContentFlipY = (sender.state == NSControl.StateValue.on)
      
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
      {
        structure.reComputeBoundingBox()
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        project.checkValidatyOfMeasurementPoints()
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.transformContentCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  
  @IBAction func toggleFlipContentZ(_ sender: NSButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var structure: [CellViewer] = representedObject as? [CellViewer]
    {
      sender.allowsMixedState = false
      structure.renderContentFlipZ = (sender.state == NSControl.StateValue.on)
      
      if let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
      {
        structure.reComputeBoundingBox()
        project.renderCamera?.resetForNewBoundingBox(project.renderBoundingBox)
        project.checkValidatyOfMeasurementPoints()
      }
      
      self.windowController?.detailTabViewController?.renderViewController?.invalidateCachedAmbientOcclusionTexture(cachedAmbientOcclusionTextures: structure.allRenderFrames)
      self.windowController?.detailTabViewController?.renderViewController?.reloadData()
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.transformContentCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  
  // undo for large-changes: completely replace all atoms and bonds by new ones
  func applyCellContentShift(structure: Structure, cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController)
  {
    if let document: iRASPADocument = self.windowController?.currentDocument,
      let project: ProjectStructureNode = self.proxyProject?.representedObject.loadedProjectStructureNode
    {
      let oldCell: SKCell = structure.cell
      let oldSpaceGroup: SKSpacegroup = structure.spaceGroup
      let oldAtoms: SKAtomTreeController = structure.atomTreeController
      let oldBonds: SKBondSetController = structure.bondController
      project.undoManager.registerUndo(withTarget: self, handler: {$0.applyCellContentShift(structure: structure, cell: oldCell, spaceGroup: oldSpaceGroup, atoms: oldAtoms, bonds: oldBonds)})
      
      structure.cell = cell
      structure.spaceGroup = spaceGroup
      structure.atomTreeController = atoms
      structure.bondController = bonds
      
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
  
  
 
  
  @IBAction func applyContentShift(_ sender: NSButton)
  {
    if let cellViewer: [CellViewer] = self.representedObject as? [CellViewer],
      let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      if let project: ProjectStructureNode = projectTreeNode.representedObject.loadedProjectStructureNode
      {
        project.measurementTreeNodes = []
      }
      
      for structure in cellViewer.allStructures
      {
        if let state: (cell: SKCell, spaceGroup: SKSpacegroup, atoms: SKAtomTreeController, bonds: SKBondSetController) = structure.applyCellContentShift()
        {
          self.applyCellContentShift(structure: structure, cell: state.cell, spaceGroup: state.spaceGroup, atoms: state.atoms, bonds: state.bonds)
        }
      }
      
      let results: [(minimumEnergyValue: Double, voidFraction: Double)] = SKVoidFraction.compute(structures: cellViewer.allStructures.map{($0.cell, $0.atomUnitCellPositions, $0.potentialParameters)}, probeParameters: SIMD2<Double>(10.9, 2.64))
      
      for (i, result) in results.enumerated()
      {
        cellViewer.allStructures[i].minimumGridEnergyValue = Float(result.minimumEnergyValue)
        cellViewer.allStructures[i].structureHeliumVoidFraction = result.voidFraction
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderOrientation: simd_quatd = structure.renderOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.x = sender.doubleValue * Double.pi/180.0
      structure.renderOrientation = simd_quatd(EulerAngles: angles)
      
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderOrientation: simd_quatd = structure.renderOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.y = sender.doubleValue * Double.pi/180.0
      structure.renderOrientation = simd_quatd(EulerAngles: angles)
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderOrientation: simd_quatd = structure.renderOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.z = sender.doubleValue * Double.pi/180.0
      structure.renderOrientation = simd_quatd(EulerAngles: angles)
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderRotationDelta = structure.renderRotationDelta,
       let renderOrientation: simd_quatd = structure.renderOrientation
    {
      let dq: simd_quatd = simd_quatd(yaw: renderRotationDelta)
      
      structure.renderOrientation = renderOrientation * dq
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderRotationDelta = structure.renderRotationDelta,
       let renderOrientation: simd_quatd = structure.renderOrientation
    {
      let dq: simd_quatd = simd_quatd(yaw: -renderRotationDelta)
      
      structure.renderOrientation = renderOrientation * dq
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderRotationDelta = structure.renderRotationDelta,
       let renderOrientation: simd_quatd = structure.renderOrientation
    {
      let dq: simd_quatd = simd_quatd(pitch: renderRotationDelta)
      
      structure.renderOrientation = renderOrientation * dq
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderRotationDelta = structure.renderRotationDelta,
       let renderOrientation: simd_quatd = structure.renderOrientation
    {
      let dq: simd_quatd = simd_quatd(pitch: -renderRotationDelta)
      
      structure.renderOrientation = renderOrientation * dq
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderRotationDelta = structure.renderRotationDelta,
       let renderOrientation: simd_quatd = structure.renderOrientation
    {
      let dq: simd_quatd = simd_quatd(roll: renderRotationDelta)
      
      structure.renderOrientation = renderOrientation * dq
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderRotationDelta = structure.renderRotationDelta,
       let renderOrientation: simd_quatd = structure.renderOrientation
    {
      let dq: simd_quatd = simd_quatd(roll: -renderRotationDelta)
      
      structure.renderOrientation = renderOrientation * dq
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderOrientation = structure.renderOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.x = sender.doubleValue * Double.pi/180.0
      structure.renderOrientation = simd_quatd(EulerAngles: angles)
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderOrientation = structure.renderOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.z = sender.doubleValue * Double.pi/180.0
      structure.renderOrientation = simd_quatd(EulerAngles: angles)
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
       var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let renderOrientation = structure.renderOrientation
    {
      var angles: SIMD3<Double> = renderOrientation.EulerAngles
      angles.y = sender.doubleValue * Double.pi/180.0
      structure.renderOrientation = simd_quatd(EulerAngles: angles)
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
    if let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled,
       var structure: [CellViewer] = self.representedObject as? [CellViewer]
    {
      structure.renderRotationDelta = sender.doubleValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.boxOrientationCell, self.boxBoundingBoxInfoCell])
    }
  }
  
  
  // MARK: Structure properties
  // =====================================================================
  
  @IBAction func changeMaterialName(_ sender: NSComboBox)
  {
    if var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.windowController?.document?.updateChangeCount(.changeDone)
      ProjectTreeNode.representedObject.isEdited = true
      structure.renderStructureMaterialType = sender.stringValue
    }
  }
  
  @IBAction func setHeliumVoidFraction(_ sender: NSTextField)
  {
    if var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.renderStructureHeliumVoidFraction = sender.doubleValue
      structure.renderRecomputeDensityProperties()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralPropertiesCell])
    }
  }
  
  @IBAction func recomputeHeliumVoidFraction(_ sender: NSButton)
  {
    if let cellViewer: [CellViewer] = self.representedObject as? [CellViewer],
       let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      let results: [(minimumEnergyValue: Double, voidFraction: Double)] = SKVoidFraction.compute(structures: cellViewer.allStructures.map{($0.cell, $0.atomUnitCellPositions, $0.potentialParameters)}, probeParameters: SIMD2<Double>(10.9, 2.64))
        
      for (i, result) in results.enumerated()
      {
        cellViewer.allStructures[i].minimumGridEnergyValue = Float(result.minimumEnergyValue)
        cellViewer.allStructures[i].structureHeliumVoidFraction = result.voidFraction
      }
      
      cellViewer.renderRecomputeDensityProperties()
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralPropertiesCell])
    }
  }
  
  @IBAction func changeFrameworkProbeMolecule(_ sender: NSPopUpButton)
  {
    if let projectTreeNode = self.proxyProject, projectTreeNode.isEditable,
      var cellViewer: [CellViewer] = representedObject as? [CellViewer]
    {
      cellViewer.renderFrameworkProbeMolecule = Structure.ProbeMolecule(rawValue: sender.indexOfSelectedItem)!
      
      cellViewer.renderRecomputeDensityProperties()
      
      do
      {
        let results: [Double] = try SKNitrogenSurfaceArea.compute(structures: cellViewer.allStructures.map{($0.cell, $0.atomUnitCellPositions, $0.potentialParameters, probeParameters: $0.frameworkProbeParameters)})
        for (i, result) in results.enumerated()
        {
          cellViewer.allStructures[i].structureNitrogenSurfaceArea = result
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
    if let cellViewer: [CellViewer] = self.representedObject as? [CellViewer],
       let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
     do
      {
        let results: [Double] = try SKNitrogenSurfaceArea.compute(structures: cellViewer.allStructures.map{($0.cell, $0.atomUnitCellPositions, $0.potentialParameters, probeParameters: $0.frameworkProbeParameters)})
        for (i, result) in results.enumerated()
        {
          cellViewer.allStructures[i].structureNitrogenSurfaceArea = result
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
    if var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.renderStructureNumberOfChannelSystems = sender.integerValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralProbeCell])
    }
  }
  
  @IBAction func setNumberOfInaccessiblePockets(_ sender: NSTextField)
  {
    if var structure: [CellViewer] = self.representedObject as? [CellViewer]
    {
      structure.renderStructureNumberOfInaccessiblePockets = sender.integerValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralProbeCell])
    }
  }
  
  @IBAction func setDimensionalityOfPoreSystem(_ sender: NSTextField)
  {
    if var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.renderStructureDimensionalityOfPoreSystem = sender.integerValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralChannelCell])
    }
  }
  
  @IBAction func setLargestCavityDiameter(_ sender: NSTextField)
  {
    if var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.renderStructureLargestCavityDiameter = sender.doubleValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralChannelCell])
    }
  }
  
  
  @IBAction func setRestrictingPoreLimitingDiameter(_ sender: NSTextField)
  {
    if var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.renderStructureRestrictingPoreLimitingDiameter = sender.doubleValue
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
      
      self.updateOutlineView(identifiers: [self.structuralChannelCell])
    }
  }
  
  @IBAction func setLargestCavityDiameterAlongAViablePath(_ sender: NSTextField)
  {
    if var structure: [CellViewer] = self.representedObject as? [CellViewer],
       let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.renderStructureLargestCavityDiameterAlongAViablePath = sender.doubleValue
      
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
      let oldSpaceGroup: SKSpacegroup = structure.spaceGroup
      let oldAtoms: SKAtomTreeController = structure.atomTreeController
      let oldBonds: SKBondSetController = structure.bondController
      project.undoManager.registerUndo(withTarget: self, handler: {$0.setStructureState(structure: structure, cell: oldCell, spaceGroup: oldSpaceGroup, atoms: oldAtoms, bonds: oldBonds)})
      
      structure.cell = cell
      structure.spaceGroup = spaceGroup
      structure.atomTreeController = atoms
      structure.bondController = bonds
      
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
    if let cellViewer: [CellViewer] = self.representedObject as? [CellViewer],
       let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      self.setSpaceGroupHallNumber(structures: cellViewer.allStructures, number: Array(repeating: sender.indexOfSelectedItem, count: cellViewer.allStructures.count))
    }
  }
  
  @IBAction func setSpaceGroupNumber(_ sender: NSPopUpButton)
  {
    if let cellViewer: [CellViewer] = self.representedObject as? [CellViewer],
       let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      let HallNumber: Int = SKSpacegroup.HallSymbolForConventionalSpaceGroupNumber(sender.indexOfSelectedItem)
      self.setSpaceGroupHallNumber(structures: cellViewer.allStructures, number: Array(repeating: HallNumber, count: cellViewer.allStructures.count))
    }
  }
  
  @IBAction func setSpaceGroupQualifier(_ sender: NSPopUpButton)
  {
    if let cellViewer: [CellViewer] = self.representedObject as? [CellViewer],
       let spaceGroupHallNumber: Int = cellViewer.spaceGroupHallNumber,
       let projectTreeNode: ProjectTreeNode = self.proxyProject, projectTreeNode.isEnabled
    {
      let spaceGroupNumber: Int = SKSpacegroup.SpaceGroupNumberForHallNumber(spaceGroupHallNumber)
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      let HallNumber: Int = SKSpacegroup.BaseHallSymbolForSpaceGroupNumber(spaceGroupNumber) + sender.indexOfSelectedItem
      self.setSpaceGroupHallNumber(structures: cellViewer.allStructures, number: Array(repeating: HallNumber, count: cellViewer.allStructures.count))
    }
  }
  
  @IBAction func setSpaceGroupPrecision(_ sender: NSTextField)
  {
    if var structure: [CellViewer] = self.representedObject as? [CellViewer],
      let ProjectTreeNode: ProjectTreeNode = self.proxyProject, ProjectTreeNode.isEnabled
    {
      structure.renderCellPrecision = sender.doubleValue
      
      self.windowController?.window?.makeFirstResponder(self.cellOutlineView)
      
      self.updateOutlineView(identifiers: [self.symmetrySpaceGroupCell, self.symmetryCenteringCell, self.symmetryPropertiesCell])
      
      self.windowController?.document?.updateChangeCount(.changeDone)
      self.proxyProject?.representedObject.isEdited = true
    }
  }
}
