/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 *************************************************************************************************************/

import Foundation
import SymmetryKit
import iRASPAKit

func objectTypeIsPrimitive(_ type: SKStructure.Kind) -> Bool
{
  switch type
  {
  case .ellipsoidPrimitive, .cylinderPrimitive, .polygonalPrismPrimitive,
       .crystalEllipsoidPrimitive, .crystalCylinderPrimitive, .crystalPolygonalPrismPrimitive:
    return true
  default:
    return false
  }
}

func objectTypeIsProteinRibbon(_ type: SKStructure.Kind) -> Bool
{
  return type == .protein || type == .proteinCrystal
}

func objectTypeIsDNARibbon(_ type: SKStructure.Kind) -> Bool
{
  return type == .dna || type == .dnaCrystal
}

func hasPrimitiveStructure(in objects: [iRASPAObject]) -> Bool
{
  return objects.contains { objectTypeIsPrimitive($0.type) && $0.object is PrimitiveEditor }
}

func hasProteinRibbonStructure(in objects: [iRASPAObject]) -> Bool
{
  return objects.contains { objectTypeIsProteinRibbon($0.type) && $0.object is ProteinRibbonStructureEditor }
}

func hasDNARibbonStructure(in objects: [iRASPAObject]) -> Bool
{
  return objects.contains { objectTypeIsDNARibbon($0.type) && $0.object is DNARibbonStructureEditor }
}

extension NucleicAcidBackboneStyle
{
  public var displayName: String
  {
    switch self
    {
    case .oval: return "Oval"
    case .tube: return "Tube"
    case .dumbbell: return "Dumbbell"
    case .rect: return "Rect"
    }
  }

  public static var allSelectableCases: [NucleicAcidBackboneStyle]
  {
    return [.oval, .tube, .dumbbell, .rect]
  }
}

extension NucleicAcidTraceMode
{
  public var displayName: String
  {
    switch self
    {
    case .phosphateMode4: return "Phosphate (P)"
    case .c3PrimeMode1: return "C3 Prime"
    }
  }

  public static var allSelectableCases: [NucleicAcidTraceMode]
  {
    return [.phosphateMode4, .c3PrimeMode1]
  }
}
