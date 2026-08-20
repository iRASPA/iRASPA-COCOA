/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction.
 *************************************************************************************************************/

import Foundation
import SimulationKit

/// Process-wide document context so domain types do not call NSDocumentController.shared.
public enum DocumentContext
{
  public static weak var forceFieldViewer: ForceFieldViewer?
  public static var forceFieldSets: SKForceFieldSets?
  {
    return forceFieldViewer?.forceFieldSets
  }
}
