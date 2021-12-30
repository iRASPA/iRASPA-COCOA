//
//  Constants.swift
//  SimulationKit
//
//  Created by David Dubbeldam on 15/12/2018.
//  Copyright © 2018 David Dubbeldam. All rights reserved.
//

import Foundation

public class SKConstant
{
  public static let BoltzmannConstant: Double = 1.380650324e-23    // J K^-1
  public static let AvogadroConstant: Double = 6.022140857e23
  public static let Angstrom: Double = 10e-10
  public static let AvogadroConstantPerAngstromCubed: Double = 6.022140857e-7
  public static let AvogadroConstantPerAngstromSquared: Double = 6022.140857
  public static let K_B: Double = 0.8314464919
}

extension Double
{
  var BohrToAngstrom: Double { return self * 0.529177249 }
}
