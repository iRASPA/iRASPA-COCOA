/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2022 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions
 of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

import Foundation
import simd

/// Ideal heavy-atom coordinates for standard amino acids (CA at origin).
/// Values adapted from AlphaFold rigid-group reference geometry (DeepMind, Apache 2.0).
public enum SKAminoAcidIdealGeometry
{
  public static let replaceableResidueCodes: [String] = [
    "ALA", "ARG", "ASN", "ASP", "CYS", "GLN", "GLU", "GLY", "HIS", "ILE",
    "LEU", "LYS", "MET", "PHE", "PRO", "SER", "THR", "TRP", "TYR", "VAL",
  ]
  
  private static let coordinatesByResidue: [String: [String: SIMD3<Double>]] = [
    "ALA": ["N": SIMD3(-0.525, 1.363, 0.000), "CA": .zero, "C": SIMD3(1.526, 0.000, 0.000), "CB": SIMD3(-0.529, -0.774, -1.205), "O": SIMD3(0.627, 1.062, 0.000)],
    "ARG": ["N": SIMD3(-0.524, 1.362, 0.000), "CA": .zero, "C": SIMD3(1.525, 0.000, 0.000), "CB": SIMD3(-0.524, -0.778, -1.209), "O": SIMD3(0.626, 1.062, 0.000), "CG": SIMD3(0.616, 1.390, 0.000), "CD": SIMD3(0.564, 1.414, 0.000), "NE": SIMD3(0.539, 1.357, 0.000), "NH1": SIMD3(0.206, 2.301, 0.000), "NH2": SIMD3(2.078, 0.978, 0.000), "CZ": SIMD3(0.758, 1.093, 0.000)],
    "ASN": ["N": SIMD3(-0.536, 1.357, 0.000), "CA": .zero, "C": SIMD3(1.526, 0.000, 0.000), "CB": SIMD3(-0.531, -0.787, -1.200), "O": SIMD3(0.625, 1.062, 0.000), "CG": SIMD3(0.584, 1.399, 0.000), "ND2": SIMD3(0.593, -1.188, 0.001), "OD1": SIMD3(0.633, 1.059, 0.000)],
    "ASP": ["N": SIMD3(-0.525, 1.362, 0.000), "CA": .zero, "C": SIMD3(1.527, 0.000, 0.000), "CB": SIMD3(-0.526, -0.778, -1.208), "O": SIMD3(0.626, 1.062, 0.000), "CG": SIMD3(0.593, 1.398, 0.000), "OD1": SIMD3(0.610, 1.091, 0.000), "OD2": SIMD3(0.592, -1.101, -0.003)],
    "CYS": ["N": SIMD3(-0.522, 1.362, 0.000), "CA": .zero, "C": SIMD3(1.524, 0.000, 0.000), "CB": SIMD3(-0.519, -0.773, -1.212), "O": SIMD3(0.625, 1.062, 0.000), "SG": SIMD3(0.728, 1.653, 0.000)],
    "GLN": ["N": SIMD3(-0.526, 1.361, 0.000), "CA": .zero, "C": SIMD3(1.526, 0.000, 0.000), "CB": SIMD3(-0.525, -0.779, -1.207), "O": SIMD3(0.626, 1.062, 0.000), "CG": SIMD3(0.615, 1.393, 0.000), "CD": SIMD3(0.587, 1.399, 0.000), "NE2": SIMD3(0.593, -1.189, -0.001), "OE1": SIMD3(0.634, 1.060, 0.000)],
    "GLU": ["N": SIMD3(-0.528, 1.361, 0.000), "CA": .zero, "C": SIMD3(1.526, 0.000, 0.000), "CB": SIMD3(-0.526, -0.781, -1.207), "O": SIMD3(0.626, 1.062, 0.000), "CG": SIMD3(0.615, 1.392, 0.000), "CD": SIMD3(0.600, 1.397, 0.000), "OE1": SIMD3(0.607, 1.095, 0.000), "OE2": SIMD3(0.589, -1.104, -0.001)],
    "GLY": ["N": SIMD3(-0.572, 1.337, 0.000), "CA": .zero, "C": SIMD3(1.517, 0.000, 0.000), "O": SIMD3(0.626, 1.062, 0.000)],
    "HIS": ["N": SIMD3(-0.527, 1.360, 0.000), "CA": .zero, "C": SIMD3(1.525, 0.000, 0.000), "CB": SIMD3(-0.525, -0.778, -1.208), "O": SIMD3(0.625, 1.063, 0.000), "CG": SIMD3(0.600, 1.370, 0.000), "CD2": SIMD3(0.889, -1.021, 0.003), "ND1": SIMD3(0.744, 1.160, 0.000), "CE1": SIMD3(2.030, 0.851, 0.002), "NE2": SIMD3(2.145, -0.466, 0.004)],
    "ILE": ["N": SIMD3(-0.493, 1.373, 0.000), "CA": .zero, "C": SIMD3(1.527, 0.000, 0.000), "CB": SIMD3(-0.536, -0.793, -1.213), "O": SIMD3(0.627, 1.062, 0.000), "CG1": SIMD3(0.534, 1.437, 0.000), "CG2": SIMD3(0.540, -0.785, -1.199), "CD1": SIMD3(0.619, 1.391, 0.000)],
    "LEU": ["N": SIMD3(-0.520, 1.363, 0.000), "CA": .zero, "C": SIMD3(1.525, 0.000, 0.000), "CB": SIMD3(-0.522, -0.773, -1.214), "O": SIMD3(0.625, 1.063, 0.000), "CG": SIMD3(0.678, 1.371, 0.000), "CD1": SIMD3(0.530, 1.430, 0.000), "CD2": SIMD3(0.535, -0.774, 1.200)],
    "LYS": ["N": SIMD3(-0.526, 1.362, 0.000), "CA": .zero, "C": SIMD3(1.526, 0.000, 0.000), "CB": SIMD3(-0.524, -0.778, -1.208), "O": SIMD3(0.626, 1.062, 0.000), "CG": SIMD3(0.619, 1.390, 0.000), "CD": SIMD3(0.559, 1.417, 0.000), "CE": SIMD3(0.560, 1.416, 0.000), "NZ": SIMD3(0.554, 1.387, 0.000)],
    "MET": ["N": SIMD3(-0.521, 1.364, 0.000), "CA": .zero, "C": SIMD3(1.525, 0.000, 0.000), "CB": SIMD3(-0.523, -0.776, -1.210), "O": SIMD3(0.625, 1.062, 0.000), "CG": SIMD3(0.613, 1.391, 0.000), "SD": SIMD3(0.703, 1.695, 0.000), "CE": SIMD3(0.320, 1.786, 0.000)],
    "PHE": ["N": SIMD3(-0.518, 1.363, 0.000), "CA": .zero, "C": SIMD3(1.524, 0.000, 0.000), "CB": SIMD3(-0.525, -0.776, -1.212), "O": SIMD3(0.626, 1.062, 0.000), "CG": SIMD3(0.607, 1.377, 0.000), "CD1": SIMD3(0.709, 1.195, 0.000), "CD2": SIMD3(0.706, -1.196, 0.000), "CE1": SIMD3(2.102, 1.198, 0.000), "CE2": SIMD3(2.098, -1.201, 0.000), "CZ": SIMD3(2.794, -0.003, -0.001)],
    "PRO": ["N": SIMD3(-0.566, 1.351, 0.000), "CA": .zero, "C": SIMD3(1.527, 0.000, 0.000), "CB": SIMD3(-0.546, -0.611, -1.293), "O": SIMD3(0.621, 1.066, 0.000), "CG": SIMD3(0.382, 1.445, 0.000), "CD": SIMD3(0.477, 1.424, 0.000)],
    "SER": ["N": SIMD3(-0.529, 1.360, 0.000), "CA": .zero, "C": SIMD3(1.525, 0.000, 0.000), "CB": SIMD3(-0.518, -0.777, -1.211), "O": SIMD3(0.626, 1.062, 0.000), "OG": SIMD3(0.503, 1.325, 0.000)],
    "THR": ["N": SIMD3(-0.517, 1.364, 0.000), "CA": .zero, "C": SIMD3(1.526, 0.000, 0.000), "CB": SIMD3(-0.516, -0.793, -1.215), "O": SIMD3(0.626, 1.062, 0.000), "CG2": SIMD3(0.550, -0.718, -1.228), "OG1": SIMD3(0.472, 1.353, 0.000)],
    "TRP": ["N": SIMD3(-0.521, 1.363, 0.000), "CA": .zero, "C": SIMD3(1.525, 0.000, 0.000), "CB": SIMD3(-0.523, -0.776, -1.212), "O": SIMD3(0.627, 1.062, 0.000), "CG": SIMD3(0.609, 1.370, 0.000), "CD1": SIMD3(0.824, 1.091, 0.000), "CD2": SIMD3(0.854, -1.148, -0.005), "CE2": SIMD3(2.186, -0.678, -0.007), "CE3": SIMD3(0.622, -2.530, -0.007), "NE1": SIMD3(2.140, 0.690, -0.004), "CH2": SIMD3(3.028, -2.890, -0.013), "CZ2": SIMD3(3.283, -1.543, -0.011), "CZ3": SIMD3(1.715, -3.389, -0.011)],
    "TYR": ["N": SIMD3(-0.522, 1.362, 0.000), "CA": .zero, "C": SIMD3(1.524, 0.000, 0.000), "CB": SIMD3(-0.522, -0.776, -1.213), "O": SIMD3(0.627, 1.062, 0.000), "CG": SIMD3(0.607, 1.382, 0.000), "CD1": SIMD3(0.716, 1.195, 0.000), "CD2": SIMD3(0.713, -1.194, -0.001), "CE1": SIMD3(2.107, 1.200, -0.002), "CE2": SIMD3(2.104, -1.201, -0.003), "OH": SIMD3(4.168, -0.002, -0.005), "CZ": SIMD3(2.791, -0.001, -0.003)],
    "VAL": ["N": SIMD3(-0.494, 1.373, 0.000), "CA": .zero, "C": SIMD3(1.527, 0.000, 0.000), "CB": SIMD3(-0.533, -0.795, -1.213), "O": SIMD3(0.627, 1.062, 0.000), "CG1": SIMD3(0.540, 1.429, 0.000), "CG2": SIMD3(0.533, -0.776, 1.203)],
  ]
  
  public static func idealCoordinates(for residueCode: String) -> [String: SIMD3<Double>]?
  {
    return coordinatesByResidue[residueCode.uppercased().trimmingCharacters(in: .whitespaces)]
  }
  
  public static func atomNames(for residueCode: String) -> [String]
  {
    guard let coordinates: [String: SIMD3<Double>] = idealCoordinates(for: residueCode) else {return []}
    return coordinates.keys.sorted()
  }
  
  public static func alignedCoordinates(for residueCode: String,
                                        actualN: SIMD3<Double>,
                                        actualCA: SIMD3<Double>,
                                        actualC: SIMD3<Double>) -> [String: SIMD3<Double>]?
  {
    guard let ideal: [String: SIMD3<Double>] = idealCoordinates(for: residueCode),
          let idealN: SIMD3<Double> = ideal["N"],
          let idealCA: SIMD3<Double> = ideal["CA"],
          let idealC: SIMD3<Double> = ideal["C"] else {return nil}
    
    let rotation: double3x3
    let translation: SIMD3<Double>
    (rotation, translation) = backboneAlignmentTransform(idealN: idealN,
                                                       idealCA: idealCA,
                                                       idealC: idealC,
                                                       actualN: actualN,
                                                       actualCA: actualCA,
                                                       actualC: actualC)
    
    var aligned: [String: SIMD3<Double>] = [:]
    for (atomName, position) in ideal
    {
      aligned[atomName] = rotation * position + translation
    }
    return aligned
  }
  
  private static func backboneAlignmentTransform(idealN: SIMD3<Double>,
                                                 idealCA: SIMD3<Double>,
                                                 idealC: SIMD3<Double>,
                                                 actualN: SIMD3<Double>,
                                                 actualCA: SIMD3<Double>,
                                                 actualC: SIMD3<Double>) -> (double3x3, SIMD3<Double>)
  {
    let idealFrame: double3x3 = localFrame(at: idealCA, nitrogen: idealN, carbonyl: idealC)
    let actualFrame: double3x3 = localFrame(at: actualCA, nitrogen: actualN, carbonyl: actualC)
    let rotation: double3x3 = actualFrame * idealFrame.transpose
    let translation: SIMD3<Double> = actualCA - rotation * idealCA
    return (rotation, translation)
  }
  
  private static func localFrame(at alphaCarbon: SIMD3<Double>,
                                 nitrogen: SIMD3<Double>,
                                 carbonyl: SIMD3<Double>) -> double3x3
  {
    var xAxis: SIMD3<Double> = nitrogen - alphaCarbon
    let xLength: Double = length(xAxis)
    if xLength > 1.0e-8
    {
      xAxis /= xLength
    }
    else
    {
      xAxis = SIMD3<Double>(1.0, 0.0, 0.0)
    }
    
    var zAxis: SIMD3<Double> = cross(xAxis, carbonyl - alphaCarbon)
    let zLength: Double = length(zAxis)
    if zLength > 1.0e-8
    {
      zAxis /= zLength
    }
    else
    {
      zAxis = SIMD3<Double>(0.0, 0.0, 1.0)
    }
    
    let yAxis: SIMD3<Double> = cross(zAxis, xAxis)
    return double3x3(columns: (xAxis, yAxis, zAxis))
  }
}
