/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl            http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 scaldia@upo.es                http://www.upo.es/raspa/sofiacalero.php
 t.j.h.vlugt@tudelft.nl        http://homepage.tudelft.nl/v9k6y
 
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

public struct PredefinedElements
{
  public let elementSet: [SKElement]
  public static let sharedInstance = PredefinedElements()
  
  private init()
  {
    elementSet =
      [
        SKElement(symbol: "", atomicNumber: 0, group: 0, period: 0, name: "Custom", mass: 0.0, atomRadius: 0.0, covalentRadius: 0.0, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: []),
        SKElement(symbol: "H", atomicNumber: 1, group: 1, period: 1, name: "Hydrogen", mass: 1.00794, atomRadius: 0.53, covalentRadius: 0.32, tripleBondCovalentRadius: 0.0, vDWRadius: 1.2, possibleOxidationStates: [-1,1]),
        SKElement(symbol: "He", atomicNumber: 2, group: 18, period: 1, name: "Helium", mass: 4.002602, atomRadius: 0.31, covalentRadius: 0.28, tripleBondCovalentRadius: 0.0, vDWRadius: 1.4, possibleOxidationStates: [0]),
        SKElement(symbol: "Li", atomicNumber: 3, group: 1, period: 2, name: "Lithium", mass: 6.9421, atomRadius: 1.67, covalentRadius: 1.28, tripleBondCovalentRadius: 0.0, vDWRadius: 1.82, possibleOxidationStates: [1]),
        SKElement(symbol: "Be" ,atomicNumber: 4, group: 2, period: 3, name: "Beryllium", mass: 9.012182, atomRadius: 1.12, covalentRadius: 0.96, tripleBondCovalentRadius: 0.85, vDWRadius: 1.86, possibleOxidationStates: [1,2]),
        SKElement(symbol: "B" ,atomicNumber: 5, group: 13, period: 2, name: "Boron", mass: 10.881, atomRadius: 0.90, covalentRadius: 0.84, tripleBondCovalentRadius: 0.73, vDWRadius: 1.92, possibleOxidationStates: [-5,-1,1,2,3]),
        SKElement(symbol: "C" ,atomicNumber: 6, group: 14, period: 2, name: "Carbon", mass: 12.0107, atomRadius: 0.67, covalentRadius: 0.77, tripleBondCovalentRadius: 0.69, vDWRadius: 1.7, possibleOxidationStates: [-4,-3,-2,-1,0,1,2,3,4]),
        SKElement(symbol: "N" ,atomicNumber: 7, group: 15, period: 2, name: "Nitrogen", mass: 14.0067, atomRadius: 0.56, covalentRadius: 0.71, tripleBondCovalentRadius: 0.54, vDWRadius: 1.55, possibleOxidationStates: [-3,-2,-1,1,2,3,4,5]),
        SKElement(symbol: "O" ,atomicNumber: 8, group: 16, period: 2, name: "Oxygen", mass: 15.9994, atomRadius: 0.48, covalentRadius: 0.66, tripleBondCovalentRadius: 0.53, vDWRadius: 1.52, possibleOxidationStates: [-2,1,1,2]),
        SKElement(symbol: "F" ,atomicNumber: 9, group: 17, period: 2, name: "Fluorine", mass: 18.9984032, atomRadius: 0.42, covalentRadius: 0.64, tripleBondCovalentRadius: 0.53, vDWRadius: 1.35, possibleOxidationStates: [-1]),
        SKElement(symbol: "Ne" ,atomicNumber: 10, group: 18, period: 2, name: "Neon", mass: 20.1797, atomRadius: 0.38, covalentRadius: 0.58, tripleBondCovalentRadius: 0.0, vDWRadius: 1.54, possibleOxidationStates: [0]),
        SKElement(symbol: "Na" ,atomicNumber: 11, group: 1, period: 3, name: "Sodium", mass: 22.98976928, atomRadius: 1.86, covalentRadius: 1.66, tripleBondCovalentRadius: 0.0, vDWRadius: 2.27, possibleOxidationStates: [-1,1]),
        SKElement(symbol: "Mg" ,atomicNumber: 12, group: 2, period: 3, name: "Magnesium", mass: 24.305, atomRadius: 1.60, covalentRadius: 1.41, tripleBondCovalentRadius: 1.27, vDWRadius: 1.73, possibleOxidationStates: [1,2]),
        SKElement(symbol: "Al" ,atomicNumber: 13, group: 13, period: 3, name: "Aluminum", mass: 26.9815386, atomRadius: 1.43, covalentRadius: 1.21, tripleBondCovalentRadius: 1.11, vDWRadius: 1.84, possibleOxidationStates: [-2,-1,1,2,3]),
        SKElement(symbol: "Si" ,atomicNumber: 14, group: 14, period: 3, name: "Silicon", mass: 28.0855, atomRadius: 1.11, covalentRadius: 1.11, tripleBondCovalentRadius: 1.02, vDWRadius: 2.1, possibleOxidationStates: [-4,-3,-2,-1,1,2,3,4]),
        SKElement(symbol: "P" ,atomicNumber: 15, group: 15, period: 3, name: "Phosphorus", mass: 30.973762, atomRadius: 0.98, covalentRadius: 1.07, tripleBondCovalentRadius: 0.94, vDWRadius: 1.8, possibleOxidationStates: [-3,-2,-1,1,2,3,4,5]),
        SKElement(symbol: "S" ,atomicNumber: 16, group: 16, period: 3, name: "Sulfur", mass: 32.065, atomRadius: 0.88, covalentRadius: 1.05, tripleBondCovalentRadius: 0.95, vDWRadius: 1.8, possibleOxidationStates: [-2,-1,1,2,3,4,5,6]),
        SKElement(symbol: "Cl" ,atomicNumber: 17, group: 17, period: 3, name: "Chlorine", mass: 35.453, atomRadius: 0.79, covalentRadius: 1.02, tripleBondCovalentRadius: 0.93, vDWRadius: 1.75, possibleOxidationStates: [-1,1,2,3,4,5,6,7]),
        SKElement(symbol: "Ar" ,atomicNumber: 18, group: 18, period: 3, name: "Argon", mass: 39.948, atomRadius: 0.71, covalentRadius: 1.06, tripleBondCovalentRadius: 0.96, vDWRadius: 1.88, possibleOxidationStates: [0]),
        SKElement(symbol: "K" ,atomicNumber: 19, group: 1, period: 4, name: "Potassium", mass: 39.0983, atomRadius: 2.27, covalentRadius: 2.03, tripleBondCovalentRadius: 0.0, vDWRadius: 2.75, possibleOxidationStates: [-1,1]),
        SKElement(symbol: "Ca" ,atomicNumber: 20, group: 2, period: 4, name: "Calcium", mass: 40.078, atomRadius: 1.97, covalentRadius: 1.76, tripleBondCovalentRadius: 1.33, vDWRadius: 2.31, possibleOxidationStates: [1,2]),
        SKElement(symbol: "Sc" ,atomicNumber: 21, group: 3, period: 4, name: "Scandium", mass: 44.955912, atomRadius: 1.62, covalentRadius: 1.7, tripleBondCovalentRadius: 1.14, vDWRadius: 2.11, possibleOxidationStates: [1,2,3]),
        SKElement(symbol: "Ti" ,atomicNumber: 22, group: 4, period: 4, name: "Titanium", mass: 47.867, atomRadius: 1.47, covalentRadius: 1.6, tripleBondCovalentRadius: 1.08, vDWRadius: 2.14, possibleOxidationStates: [-2,-1,1,2,3,4]),
        SKElement(symbol: "V" ,atomicNumber: 23, group: 5, period: 4, name: "Vanadium", mass: 50.9415, atomRadius: 1.34, covalentRadius: 1.53, tripleBondCovalentRadius: 1.06, vDWRadius: 2.12, possibleOxidationStates: [-3,-1,1,2,3,4,5]),
        SKElement(symbol: "Cr" ,atomicNumber: 24, group: 6, period: 4, name: "Chromium", mass: 51.9961, atomRadius: 1.28, covalentRadius: 1.39, tripleBondCovalentRadius: 1.03, vDWRadius: 1.97, possibleOxidationStates: [-4,-2,-1,1,2,3,4,5,6]),
        SKElement(symbol: "Mn" ,atomicNumber: 25, group: 7, period: 4, name: "Manganese", mass: 54.939045, atomRadius: 1.27, covalentRadius: 1.39, tripleBondCovalentRadius: 1.03, vDWRadius: 1.96, possibleOxidationStates: [-3,-2,1,1,2,3,4,5,6,7]),
        SKElement(symbol: "Fe" ,atomicNumber: 26, group: 8, period: 4, name: "Iron", mass: 55.845, atomRadius: 1.26, covalentRadius: 1.32, tripleBondCovalentRadius: 1.02, vDWRadius: 1.96, possibleOxidationStates: [-4,-2,-1,1,2,3,4,5,6,7]),
        SKElement(symbol: "Co" ,atomicNumber: 27, group: 9, period: 4, name: "Cobalt", mass: 58.933195, atomRadius: 1.25, covalentRadius: 1.26, tripleBondCovalentRadius: 0.96, vDWRadius: 1.95, possibleOxidationStates: [-3,-1,1,2,3,4,5]),
        SKElement(symbol: "Ni" ,atomicNumber: 28, group: 10, period: 4, name: "Nickel", mass: 58.6934 , atomRadius: 1.24, covalentRadius: 1.24, tripleBondCovalentRadius: 1.01, vDWRadius: 1.63, possibleOxidationStates: [-2,-1,1,2,3,4]),
        SKElement(symbol: "Cu" ,atomicNumber: 29, group: 11, period: 4, name: "Copper", mass: 63.546,atomRadius: 1.28, covalentRadius: 1.32, tripleBondCovalentRadius: 1.2, vDWRadius: 1.4, possibleOxidationStates: [-2,1,2,3,4]),
        SKElement(symbol: "Zn" ,atomicNumber: 30, group: 12, period: 4, name: "Zinc", mass: 65.38, atomRadius: 1.34, covalentRadius: 1.22, tripleBondCovalentRadius: 0.0, vDWRadius: 1.39, possibleOxidationStates: [-2,0,1,2]),
        SKElement(symbol: "Ga" ,atomicNumber: 31, group: 13, period: 4, name: "Gallium", mass: 69.723, atomRadius: 1.35, covalentRadius: 1.22, tripleBondCovalentRadius: 1.21, vDWRadius: 1.87, possibleOxidationStates: [-5,-4,-2,-1,1,2,3]),
        SKElement(symbol: "Ge" ,atomicNumber: 32, group: 14, period: 4, name: "Germanium", mass: 72.64, atomRadius: 1.22, covalentRadius: 1.22, tripleBondCovalentRadius: 1.14, vDWRadius: 2.11, possibleOxidationStates: [-4,-3,-2,-1,0,1,2,3,4]),
        SKElement(symbol: "As" ,atomicNumber: 33, group: 15, period: 4, name: "arsenic", mass: 74.9216, atomRadius: 1.19, covalentRadius: 1.19, tripleBondCovalentRadius: 1.06, vDWRadius: 1.85, possibleOxidationStates: [-3,-2,-1,1,2,3,4,5]),
        SKElement(symbol: "Se" ,atomicNumber: 34, group: 16, period: 3, name: "Selenium", mass: 78.96, atomRadius: 1.20, covalentRadius: 1.2, tripleBondCovalentRadius: 1.07, vDWRadius: 1.9, possibleOxidationStates: [-2,-1,1,2,3,4,5,6]),
        SKElement(symbol: "Br" ,atomicNumber: 35, group: 17, period: 4, name: "Bromine", mass: 79.904, atomRadius: 1.20, covalentRadius: 1.2, tripleBondCovalentRadius: 1.1, vDWRadius: 1.85, possibleOxidationStates: [-1,1,3,4,5,7]),
        SKElement(symbol: "Kr" ,atomicNumber: 36, group: 18, period: 4, name: "Krypton", mass: 83.798, atomRadius: 0.88, covalentRadius: 1.16, tripleBondCovalentRadius: 1.08, vDWRadius: 2.02, possibleOxidationStates: [0,1,2]),
        SKElement(symbol: "Rb" ,atomicNumber: 37, group: 1, period: 5, name: "Rubidium", mass: 85.4678, atomRadius: 2.48, covalentRadius: 2.2, tripleBondCovalentRadius: 0.0, vDWRadius: 3.03, possibleOxidationStates: [-1,1]),
        SKElement(symbol: "Sr" ,atomicNumber: 38, group: 2, period: 5, name: "Strontium", mass: 87.62, atomRadius: 2.15, covalentRadius: 1.95, tripleBondCovalentRadius: 1.39, vDWRadius: 2.49, possibleOxidationStates: [1,2]),
        SKElement(symbol: "Y" ,atomicNumber: 39, group: 3, period: 5, name: "Yttrium", mass: 88.90585, atomRadius: 1.80, covalentRadius: 1.9, tripleBondCovalentRadius: 1.24, vDWRadius: 2.45, possibleOxidationStates: [1,2,3]),
        SKElement(symbol: "Zr" ,atomicNumber: 40, group: 4, period: 5, name: "Zirconium", mass: 91.224, atomRadius: 1.60, covalentRadius: 1.75, tripleBondCovalentRadius: 1.21, vDWRadius: 0.0, possibleOxidationStates: [-2,1,2,3,4]),
        SKElement(symbol: "Nb" ,atomicNumber: 41, group: 5, period: 5, name: "Niobium", mass: 92.90638, atomRadius: 1.46, covalentRadius: 1.64, tripleBondCovalentRadius: 1.16, vDWRadius: 0.0, possibleOxidationStates: [-3,-1,1,2,3,4,5]),
        SKElement(symbol: "Mo" ,atomicNumber: 42, group: 6, period: 5, name: "Molybdenum", mass: 95.96, atomRadius: 1.39, covalentRadius: 1.54, tripleBondCovalentRadius: 1.13, vDWRadius: 2.06, possibleOxidationStates: [-4,-2,-1,1,2,3,4,5,6]),
        SKElement(symbol: "Tc" ,atomicNumber: 43, group: 7, period: 5, name: "Technetium", mass: 98, atomRadius: 1.36, covalentRadius: 1.47, tripleBondCovalentRadius: 1.10, vDWRadius: 0.0, possibleOxidationStates: [-3,-1,1,2,3,4,5,6,7]),
        SKElement(symbol: "Ru" ,atomicNumber: 44, group: 8, period: 5, name: "Ruthenium", mass: 101.07, atomRadius: 1.34, covalentRadius: 1.46, tripleBondCovalentRadius: 1.03, vDWRadius: 2.02, possibleOxidationStates: [-4,-2,1,2,3,4,5,6,7,8]),
        SKElement(symbol: "Rh" ,atomicNumber: 45, group: 9, period: 5, name: "Rhodium", mass: 102.59055, atomRadius: 1.34, covalentRadius: 1.42, tripleBondCovalentRadius: 1.06, vDWRadius: 2.02, possibleOxidationStates: [-3,-1,1,2,3,4,5,6]),
        SKElement(symbol: "Pd" ,atomicNumber: 46, group: 10, period: 5, name: "Palladium", mass: 106.42, atomRadius: 1.37, covalentRadius: 1.39, tripleBondCovalentRadius: 1.12, vDWRadius: 1.63, possibleOxidationStates: [0,1,2,3,4]),
        SKElement(symbol: "Ag" ,atomicNumber: 47, group: 11, period: 5, name: "Silver", mass: 107.8682, atomRadius: 1.44, covalentRadius: 1.45, tripleBondCovalentRadius: 1.37, vDWRadius: 1.72, possibleOxidationStates: [-2,-1,1,2,3]),
        SKElement(symbol: "Cd" ,atomicNumber: 48, group: 12, period: 5, name: "Cadmium", mass: 112.411, atomRadius: 1.51, covalentRadius: 1.44, tripleBondCovalentRadius: 0.0, vDWRadius: 1.58, possibleOxidationStates: [-2,1,2]),
        SKElement(symbol: "In" ,atomicNumber: 49, group: 13, period: 5, name: "Indium", mass: 114.818, atomRadius: 1.67, covalentRadius: 1.42, tripleBondCovalentRadius: 1.46, vDWRadius: 1.93, possibleOxidationStates: [-5,-2,-1,1,2,3]),
        SKElement(symbol: "Sn" ,atomicNumber: 50, group: 14, period: 5, name: "Tin", mass: 118.71, atomRadius: 1.40, covalentRadius: 1.39, tripleBondCovalentRadius: 1.32, vDWRadius: 2.17, possibleOxidationStates: [-4,-3,-2,-1,1,2,3,4]),
        SKElement(symbol: "Sb" ,atomicNumber: 51, group: 15, period: 5, name: "Antimony", mass: 121.76, atomRadius: 1.40, covalentRadius: 1.39, tripleBondCovalentRadius: 1.27, vDWRadius: 2.06, possibleOxidationStates: [-3,-2,-1,1,2,3,4,5]),
        SKElement(symbol: "Te" ,atomicNumber: 52, group: 16, period: 5, name: "Tellurium", mass: 127.6, atomRadius: 1.40, covalentRadius: 1.38, tripleBondCovalentRadius: 1.21, vDWRadius: 2.06, possibleOxidationStates: [-2,-1,1,2,3,4,5,6]),
        SKElement(symbol: "I" ,atomicNumber: 53, group: 17, period: 5, name: "Iodine", mass: 126.90447, atomRadius: 1.40, covalentRadius: 1.39, tripleBondCovalentRadius: 1.25, vDWRadius: 1.98, possibleOxidationStates: [-1,1,3,4,5,6,7]),
        SKElement(symbol: "Xe" ,atomicNumber: 54, group: 18, period: 5, name: "Xenon", mass: 131.293, atomRadius: 1.08, covalentRadius: 1.4, tripleBondCovalentRadius: 1.22, vDWRadius: 2.16, possibleOxidationStates: [0,1,2,4,6,8]),
        SKElement(symbol: "Cs" ,atomicNumber: 55, group: 1, period: 6, name: "Cesium", mass: 132.9054519, atomRadius: 2.65, covalentRadius: 2.44, tripleBondCovalentRadius: 0.0, vDWRadius: 3.43, possibleOxidationStates: [-1,1]),
        SKElement(symbol: "Ba" ,atomicNumber: 56, group: 2, period: 6, name: "Barium", mass: 137.327, atomRadius: 2.22, covalentRadius: 2.15, tripleBondCovalentRadius: 1.49, vDWRadius: 2.68, possibleOxidationStates: [1,2]),
        SKElement(symbol: "La" ,atomicNumber: 57, group: -1, period: 6, name: "Lanthanum", mass: 138.90547, atomRadius: 1.87, covalentRadius: 2.07, tripleBondCovalentRadius: 1.39, vDWRadius: 2.51, possibleOxidationStates: [1,2,3]),
        SKElement(symbol: "Ce" ,atomicNumber: 58, group: -1, period: 6, name: "Cerium", mass: 140.116, atomRadius: 1.818, covalentRadius: 2.04, tripleBondCovalentRadius: 1.31, vDWRadius: 0.0, possibleOxidationStates: [1,2,3,4]),
        SKElement(symbol: "Pr" ,atomicNumber: 59, group: -1, period: 6, name: "Praseodymium", mass: 140.90765, atomRadius: 1.82, covalentRadius: 2.03, tripleBondCovalentRadius: 1.28,vDWRadius: 0.0, possibleOxidationStates: [2,3,4,5]),
        SKElement(symbol: "Nd" ,atomicNumber: 60, group: -1, period: 6, name: "Neodymium", mass: 144.242, atomRadius: 1.81, covalentRadius: 2.01, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [2,3,4]),
        SKElement(symbol: "Pm" ,atomicNumber: 61, group: -1, period: 6, name: "Promethium", mass: 145, atomRadius: 1.83, covalentRadius: 1.99, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [2,3]),
        SKElement(symbol: "Sm" ,atomicNumber: 62, group: -1, period: 6, name: "Samarium", mass: 150.36, atomRadius: 1.80, covalentRadius: 1.98, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [1,2,3,4]),
        SKElement(symbol: "Eu" ,atomicNumber: 63, group: -1, period: 6, name: "Europium", mass: 151.964, atomRadius: 1.80, covalentRadius: 1.98, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [1,2,3]),
        SKElement(symbol: "Gd" ,atomicNumber: 64, group: -1, period: 6, name: "Gadolinium", mass: 157.25, atomRadius: 1.80, covalentRadius: 1.96, tripleBondCovalentRadius: 1.32, vDWRadius: 0.0, possibleOxidationStates: [1,2,3]),
        SKElement(symbol: "Tb" ,atomicNumber: 65, group: -1, period: 6, name: "Terbium", mass: 158.92535, atomRadius: 1.77, covalentRadius: 1.94, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [1,2,3,4]),
        SKElement(symbol: "Dy" ,atomicNumber: 66, group: -1, period: 6, name: "Dysprodium", mass: 162.5, atomRadius: 1.78, covalentRadius: 1.92, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [1,2,3,4]),
        SKElement(symbol: "Ho" ,atomicNumber: 67, group: -1, period: 6, name: "Holmium", mass: 164.93032, atomRadius: 1.76, covalentRadius: 1.92, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [1,2,3]),
        SKElement(symbol: "Er" ,atomicNumber: 68, group: -1, period: 6, name: "Erbium", mass: 167.259, atomRadius: 1.76, covalentRadius: 1.89, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [1,2,3]),
        SKElement(symbol: "Tm" ,atomicNumber: 69, group: -1, period: 6, name: "Thulium", mass: 168.93421, atomRadius: 1.76, covalentRadius: 1.9, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [2,3]),
        SKElement(symbol: "Yb" ,atomicNumber: 70, group: -1, period: 6, name: "Ytterbium", mass: 173.054, atomRadius: 1.76, covalentRadius: 1.87, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [1,2,3]),
        SKElement(symbol: "Lu" ,atomicNumber: 71, group: 3, period: 6, name: "Lutetium", mass: 174.9668, atomRadius: 1.74, covalentRadius: 1.87, tripleBondCovalentRadius: 1.31, vDWRadius: 0.0, possibleOxidationStates: [1,2,3]),
        SKElement(symbol: "Hf" ,atomicNumber: 72, group: 4, period: 6, name: "Hafnium", mass: 178.49, atomRadius: 1.59, covalentRadius: 1.75, tripleBondCovalentRadius: 1.22, vDWRadius: 0.0, possibleOxidationStates: [-2,1,2,3,4]),
        SKElement(symbol: "Ta" ,atomicNumber: 73, group: 5, period: 6, name: "Tantalum", mass: 180.94788, atomRadius: 1.46, covalentRadius: 1.7, tripleBondCovalentRadius: 1.19, vDWRadius: 0.0, possibleOxidationStates: [-3,-1,1,2,3,4,5]),
        SKElement(symbol: "W" ,atomicNumber: 74, group: 6, period: 6, name: "Tungsten", mass: 183.84, atomRadius: 1.39, covalentRadius: 1.62, tripleBondCovalentRadius: 1.15, vDWRadius: 2.07, possibleOxidationStates: [-4,-2,-1,0,1,2,3,4,5,6]),
        SKElement(symbol: "Re" ,atomicNumber: 75, group: 7, period: 6, name: "Rhenium", mass: 186.207, atomRadius: 1.37, covalentRadius: 1.51, tripleBondCovalentRadius: 1.1, vDWRadius: 2.05, possibleOxidationStates: [-3,-1,0,1,2,3,4,5,6,7]),
        SKElement(symbol: "Os" ,atomicNumber: 76, group: 8, period: 6, name: "Osmium", mass: 190.23, atomRadius: 1.35, covalentRadius: 1.44, tripleBondCovalentRadius: 1.09, vDWRadius: 2.03, possibleOxidationStates: [-4,-2,0,1,2,3,4,5,6,7,8]),
        SKElement(symbol: "Ir" ,atomicNumber: 77, group: 9, period: 6, name: "Iridium", mass: 192.217, atomRadius: 1.36, covalentRadius: 1.41, tripleBondCovalentRadius: 1.07, vDWRadius: 2.03, possibleOxidationStates: [-3,-1,0,1,2,3,4,5,6,7,8,9]),
        SKElement(symbol: "Pt" ,atomicNumber: 78, group: 10, period: 6, name: "Platinum", mass: 195.084, atomRadius: 1.39, covalentRadius: 1.36, tripleBondCovalentRadius: 1.1, vDWRadius: 1.75, possibleOxidationStates: [-3,-2,-1,2,3,4,5,6]),
        SKElement(symbol: "Au" ,atomicNumber: 79, group: 11, period: 6, name: "Gold", mass: 196.966569, atomRadius: 1.44, covalentRadius: 1.36, tripleBondCovalentRadius: 1.23, vDWRadius: 1.66, possibleOxidationStates: [-3,-2,-1,1,2,3,5]),
        SKElement(symbol: "Hg" ,atomicNumber: 80, group: 12, period: 6, name: "Mercury", mass: 200.59, atomRadius: 1.51, covalentRadius: 1.32, tripleBondCovalentRadius: 1.55, vDWRadius: 0.0, possibleOxidationStates: [-2,1,2]),
        SKElement(symbol: "Tl" ,atomicNumber: 81, group: 13, period: 6, name: "Thallium", mass: 204.3833, atomRadius: 1.70, covalentRadius: 1.45, tripleBondCovalentRadius: 0.15, vDWRadius: 1.96, possibleOxidationStates: [-5,-2,-1,1,2,3]),
        SKElement(symbol: "Pb" ,atomicNumber: 82, group: 14, period: 6, name: "Lead", mass: 207.2, atomRadius: 1.75, covalentRadius: 1.46, tripleBondCovalentRadius: 1.37, vDWRadius: 2.02, possibleOxidationStates: [-4,-2,-1,2,3,4]),
        SKElement(symbol: "Bi" ,atomicNumber: 83, group: 15, period: 6, name: "Bismuth", mass: 208.9804, atomRadius: 1.56, covalentRadius: 1.48, tripleBondCovalentRadius: 1.35, vDWRadius: 2.07, possibleOxidationStates: [-3,-2,-1,1,2,3,4,5]),
        SKElement(symbol: "Po" ,atomicNumber: 84, group: 16, period: 6, name: "Polonium", mass: 210, atomRadius: 1.68, covalentRadius: 1.4, tripleBondCovalentRadius: 1.29, vDWRadius: 1.97, possibleOxidationStates: [-2,2,4,5,6]),
        SKElement(symbol: "At" ,atomicNumber: 85, group: 17, period: 6, name: "Astatine", mass: 210.8, atomRadius: 0.0, covalentRadius: 1.5, tripleBondCovalentRadius: 1.38, vDWRadius: 2.02, possibleOxidationStates: [-1,1,3,5,7]),
        SKElement(symbol: "Rn" ,atomicNumber: 86, group: 18, period: 6, name: "Radon", mass: 222, atomRadius: 1.2, covalentRadius: 1.5, tripleBondCovalentRadius: 1.33, vDWRadius: 2.20, possibleOxidationStates: [0,2,6]),
        SKElement(symbol: "Fr" ,atomicNumber: 87, group: 1, period: 7, name: "Francium", mass: 223, atomRadius: 0.0, covalentRadius: 2.6, tripleBondCovalentRadius: 0.0, vDWRadius: 3.48, possibleOxidationStates: [1]),
        SKElement(symbol: "Ra" ,atomicNumber: 88, group: 2, period: 7, name: "Radium", mass: 226, atomRadius: 0.0, covalentRadius: 2.21, tripleBondCovalentRadius: 1.59, vDWRadius: 2.83, possibleOxidationStates: [2]),
        SKElement(symbol: "Ac" ,atomicNumber: 89, group: -1, period: 7, name: "Actinium", mass: 227, atomRadius: 0.0, covalentRadius: 2.15, tripleBondCovalentRadius: 1.4, vDWRadius: 0.0, possibleOxidationStates: [2,3]),
        SKElement(symbol: "Th" ,atomicNumber: 90, group: -1, period: 7, name: "Thorium", mass: 232.03806, atomRadius: 1.798, covalentRadius: 2.06, tripleBondCovalentRadius: 1.36, vDWRadius: 2.43, possibleOxidationStates: [1,2,3,4]),
        SKElement(symbol: "Pa" ,atomicNumber: 91, group: -1, period: 7, name: "Protactinium", mass: 231.03588, atomRadius: 1.63, covalentRadius: 2.0, tripleBondCovalentRadius: 1.29, vDWRadius: 0.0, possibleOxidationStates: [2,3,4,5]),
        SKElement(symbol: "U" ,atomicNumber: 92, group: -1, period: 7, name: "Uranium", mass: 238.02891, atomRadius: 1.56, covalentRadius: 1.96, tripleBondCovalentRadius: 1.18, vDWRadius: 1.86, possibleOxidationStates: [1,2,3,4,5,6]),
        SKElement(symbol: "Np" ,atomicNumber: 93, group: -1, period: 7, name: "Neptunium", mass: 237, atomRadius: 1.55, covalentRadius: 1.9, tripleBondCovalentRadius: 1.16, vDWRadius: 0.0, possibleOxidationStates: [2,3,4,5,6,7]),
        SKElement(symbol: "Pu" ,atomicNumber: 94, group: -1, period: 7, name: "Plutonium", mass: 244, atomRadius: 1.59, covalentRadius: 1.87, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [1,2,3,4,5,6,7,8]),
        SKElement(symbol: "Am" ,atomicNumber: 95, group: -1, period: 7, name: "Americium", mass: 243, atomRadius: 1.73, covalentRadius: 1.8, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [2,3,4,5,6,7,8]),
        SKElement(symbol: "Cm" ,atomicNumber: 96, group: -1, period: 7, name: "Curium", mass: 247, atomRadius: 1.74, covalentRadius: 1.69, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [2,3,4,6]),
        SKElement(symbol: "Bk" ,atomicNumber: 97, group: -1, period: 7, name: "Berkelium", mass: 247, atomRadius: 1.7, covalentRadius: 0.0, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [2,3,4]),
        SKElement(symbol: "Cf" ,atomicNumber: 98, group: -1, period: 7, name: "Californium", mass: 251, atomRadius: 0.0, covalentRadius: 0.0, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [2,3,4]),
        SKElement(symbol: "Es" ,atomicNumber: 99, group: -1, period: 7, name: "Einsteinium", mass: 252, atomRadius: 0.0, covalentRadius: 0.0, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [2,3,4]),
        SKElement(symbol: "Fm" ,atomicNumber: 100, group: -1, period: 7, name: "Fermium", mass: 257, atomRadius: 0.0, covalentRadius: 0.0, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [2,3]),
        SKElement(symbol: "Md" ,atomicNumber: 101, group: -1, period: 7, name: "Mendelevium", mass: 258, atomRadius: 0.0, covalentRadius: 0.0, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [2,3]),
        SKElement(symbol: "No" ,atomicNumber: 102, group: -1, period: 7, name: "Nobelium", mass: 259, atomRadius: 0.0, covalentRadius: 0.0, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [2,3]),
        SKElement(symbol: "Lr" ,atomicNumber: 103, group: 3, period: 7, name: "Lawrencium", mass: 262, atomRadius: 0.0, covalentRadius: 0.0, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [3]),
        SKElement(symbol: "Rf" ,atomicNumber: 104, group: 4, period: 7, name: "Rutherfordium", mass: 261, atomRadius: 0.0, covalentRadius: 0.0, tripleBondCovalentRadius: 1.31, vDWRadius: 0.0, possibleOxidationStates: [2,3,4]),
        SKElement(symbol: "Db" ,atomicNumber: 105, group: 5, period: 7, name: "Dubnium", mass: 268, atomRadius: 1.39, covalentRadius: 1.49, tripleBondCovalentRadius: 1.26, vDWRadius: 0.0, possibleOxidationStates: [3,4,5]),
        SKElement(symbol: "Sg" ,atomicNumber: 106, group: 6, period: 7, name: "Seaborgium", mass: 269, atomRadius: 1.32, covalentRadius: 1.43, tripleBondCovalentRadius: 1.21, vDWRadius: 0.0, possibleOxidationStates: [3,4,5,6]),
        SKElement(symbol: "Bh" ,atomicNumber: 107, group: 7, period: 7, name: "Bohrium", mass: 270, atomRadius: 1.28, covalentRadius: 1.41, tripleBondCovalentRadius: 1.19, vDWRadius: 0.0, possibleOxidationStates: [3,4,5,7]),
        SKElement(symbol: "Hs" ,atomicNumber: 108, group: 8, period: 7, name: "Hassium", mass: 269, atomRadius: 1.26, covalentRadius: 1.34, tripleBondCovalentRadius: 1.18, vDWRadius: 0.0, possibleOxidationStates: [2,3,4,5,6,8]),
        SKElement(symbol: "Mt" ,atomicNumber: 109, group: 9, period: 7, name: "Meitnerium", mass: 278, atomRadius: 1.28, covalentRadius: 1.29, tripleBondCovalentRadius: 1.13, vDWRadius: 0.0, possibleOxidationStates: [1,3,4,6,8,9]),
        SKElement(symbol: "Ds" ,atomicNumber: 110, group: 10, period: 7, name: "Darmstadtium", mass: 281, atomRadius: 1.32, covalentRadius: 1.28, tripleBondCovalentRadius: 1.12, vDWRadius: 0.0, possibleOxidationStates: [0,2,4,6,8]),
        SKElement(symbol: "Rg" ,atomicNumber: 111, group: 11, period: 7, name: "Roentgenium", mass: 281, atomRadius: 1.38, covalentRadius: 1.21, tripleBondCovalentRadius: 1.18, vDWRadius: 0.0, possibleOxidationStates: [-1,1,3,5]),
        SKElement(symbol: "Cn" ,atomicNumber: 112, group: 12, period: 7, name: "Copernicium", mass: 285, atomRadius: 1.47, covalentRadius: 1.22, tripleBondCovalentRadius: 1.30, vDWRadius: 0.0, possibleOxidationStates: [0,1,2]),
        SKElement(symbol: "Nh" ,atomicNumber: 113, group: 13, period: 7, name: "Nihonium", mass: 286, atomRadius: 1.70, covalentRadius: 1.76, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [-1,1,3,5]),
        SKElement(symbol: "Fl" ,atomicNumber: 114, group: 14, period: 7, name: "Flerovium", mass: 289, atomRadius: 1.80, covalentRadius: 1.74, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [0,1,2,4,6]),
        SKElement(symbol: "Mc" ,atomicNumber: 115, group: 15, period: 7, name: "Moscovium", mass: 288, atomRadius: 1.87, covalentRadius: 1.57, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [1,3]),
        SKElement(symbol: "Lv" ,atomicNumber: 116, group: 16, period: 7, name: "Livermorium", mass: 293, atomRadius: 1.83, covalentRadius: 1.64, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [-2,2,4]),
        SKElement(symbol: "Ts" ,atomicNumber: 117, group: 17, period: 7, name: "Tennessine", mass: 294, atomRadius: 1.38, covalentRadius: 1.56, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [-1,1,3,5]),
        SKElement(symbol: "Og" ,atomicNumber: 118, group: 18, period: 7, name: "Oganesson", mass: 294, atomRadius: 1.52, covalentRadius: 1.57, tripleBondCovalentRadius: 0.0, vDWRadius: 0.0, possibleOxidationStates: [-1,0,1,2,4,6])
    ]
  }
}

public struct SKElement
{
  public var chemicalSymbol: String = "Undefined"
  public var atomicNumber: Int = 0
  public var group: Int = 0
  public var period: Int = 0
  public var name: String = "Undefined"
  public var mass: Double = 1.0
  public var atomRadius: Double = 0.0
  public var covalentRadius: Double = 0.0
  public var singleBondCovalentRadius: Double = 0.0
  public var doubleBondCovalentRadius: Double = 0.0
  public var tripleBondCovalentRadius: Double = 0.0
  public var VDWRadius: Double = 1.0
  public var possibleOxidationStates: [Int] = []
  public var oxidationState: Int = 0
  public var atomicPolarizability: Double = 0.0
  
  public init(symbol: String, atomicNumber: Int, group: Int, period: Int, name: String, mass: Double, atomRadius: Double, covalentRadius: Double, tripleBondCovalentRadius: Double, vDWRadius: Double, possibleOxidationStates: [Int])
  {
    self.chemicalSymbol = symbol
    self.atomicNumber = atomicNumber
    self.group = group
    self.period = period
    self.name = name
    self.mass = mass
    self.atomRadius = atomRadius
    self.covalentRadius = covalentRadius
    self.tripleBondCovalentRadius = tripleBondCovalentRadius
    self.VDWRadius = vDWRadius
    self.possibleOxidationStates = possibleOxidationStates
  }
  
  public static let elementString: [String] =
    [ "H", "He", "Li", "Be", "B", "C", "N", "O" , "F" , "Ne", "Na", "Mg", "Al", "Si", "P", "S", "Cl", "Ar", "K", "Ca", "Sc", "Ti", "V", "Cr", "Mn", "Fe", "Co", "Ni", "Cu", "Zn", "Ga", "Ge", "As", "Se", "Br", "Kr", "Rb", "Sr", "Y" , "Zr", "Nb", "Mo", "Tc", "Ru", "Rh", "Pd", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I" , "Xe", "Cs", "Ba", "La", "Ce", "Pr", "Nd", "Pm", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu", "Hf", "Ta", "W", "Re", "Os", "Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi", "Po", "At", "Rn", "Fr", "Ra", "Ac", "Th", "Pa", "U", "Np", "Pu", "Am", "Cm", "Bk", "Cf", "Es", "Fm", "Md", "No", "Lr", "Rf", "Db", "Sg", "Bh", "Hs", "Mt", "Ds", "Rg", "Cn", "Nh", "Fl", "Mc", "Lv", "Ts", "Og"
  ]
  
  
  // Van der Waals Radii of Elements, S. S. Batsanov
  // VDW: https://physlab.lums.edu.pk/images/f/f6/Franck_ref2.pdf
  public static let atomData: Dictionary<String,Dictionary<String,Any>> =
    [
      "": ["atomicNumber": 0, "group": 0, "period": 0, "name": "Custom", "mass": 0.0, "atomRadius": 0.0, "covalentRadius": 0.0, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [], "potentialParameters" : SIMD2<Double>(0.0,1.0)],
      "H": ["atomicNumber": 1, "group": 1, "period": 1, "name": "Hydrogen", "mass": 1.00794, "atomRadius": 0.53, "covalentRadius": 0.32, "tripleBondCovalentRadius": 0.0, "vDWRadius": 1.2, "oxidationState": [-1,1], "potentialParameters" : SIMD2<Double>(7.64893,2.84642)],
      "He": ["atomicNumber": 2, "group": 18, "period": 1, "name": "Helium", "mass": 4.002602, "atomRadius": 0.31, "covalentRadius": 0.28, "tripleBondCovalentRadius": 0.0, "vDWRadius": 1.4, "oxidationState": [0], "potentialParameters" : SIMD2<Double>(10.9,2.64)],
      "Li": ["atomicNumber": 3, "group": 1, "period": 2, "name": "Lithium", "mass": 6.9421, "atomRadius": 1.67, "covalentRadius": 1.28, "tripleBondCovalentRadius": 0.0, "vDWRadius": 1.82, "oxidationState": [1]],
      "Be": ["atomicNumber": 4, "group": 2, "period": 3, "name": "Beryllium", "mass": 9.012182, "atomRadius": 1.12, "covalentRadius": 0.96, "tripleBondCovalentRadius": 0.85, "vDWRadius": 1.86, "oxidationState": [1,2], "potentialParameters" : SIMD2<Double>(42.7736,2.44552)],
      "B": ["atomicNumber": 5, "group": 13, "period": 2, "name": "Boron", "mass": 10.881, "atomRadius": 0.90, "covalentRadius": 0.84, "tripleBondCovalentRadius": 0.73, "vDWRadius": 1.92, "oxidationState": [-5,-1,1,2,3], "potentialParameters" : SIMD2<Double>(47.8058,3.58141)],
      "C": ["atomicNumber": 6, "group": 14, "period": 2, "name": "Carbon", "mass": 12.0107, "atomRadius": 0.67, "covalentRadius": 0.77, "tripleBondCovalentRadius": 0.69, "vDWRadius": 1.7, "oxidationState": [-4,-3,-2,-1,0,1,2,3,4], "potentialParameters" : SIMD2<Double>(47.8562, 3.47299)],
      "N": ["atomicNumber": 7, "group": 15, "period": 2, "name": "Nitrogen", "mass": 14.0067, "atomRadius": 0.56, "covalentRadius": 0.71, "tripleBondCovalentRadius": 0.54, "vDWRadius": 1.55, "oxidationState": [-3,-2,-1,1,2,3,4,5], "potentialParameters" : SIMD2<Double>(38.9492,3.26256)],
      "O": ["atomicNumber": 8, "group": 16, "period": 2, "name": "Oxygen", "mass": 15.9994, "atomRadius": 0.48, "covalentRadius": 0.66, "tripleBondCovalentRadius": 0.53, "vDWRadius": 1.52, "oxidationState": [-2,1,1,2], "potentialParameters" : SIMD2<Double>(53.0, 3.30)],
      "F": ["atomicNumber": 9, "group": 17, "period": 2, "name": "Fluorine", "mass": 18.9984032, "atomRadius": 0.42, "covalentRadius": 0.64, "tripleBondCovalentRadius": 0.53, "vDWRadius": 1.35, "oxidationState": [-1], "potentialParameters" : SIMD2<Double>(36.4834,3.0932)],
      "Ne": ["atomicNumber": 10, "group": 18, "period": 2, "name": "Neon", "mass": 20.1797, "atomRadius": 0.38, "covalentRadius": 0.58, "tripleBondCovalentRadius": 0.0, "vDWRadius": 1.54, "oxidationState": [0], "potentialParameters" : SIMD2<Double>(21.1352,2.88918)],
      "Na": ["atomicNumber": 11, "group": 1, "period": 3, "name": "Sodium", "mass": 22.98976928, "atomRadius": 1.86, "covalentRadius": 1.66, "tripleBondCovalentRadius": 0.0, "vDWRadius": 2.27, "oxidationState": [-1,1], "potentialParameters" : SIMD2<Double>(15.0966,2.65755)],
      "Mg": ["atomicNumber": 12, "group": 2, "period": 3, "name": "Magnesium", "mass": 24.305, "atomRadius": 1.60, "covalentRadius": 1.41, "tripleBondCovalentRadius": 1.27, "vDWRadius": 1.73, "oxidationState": [1,2], "potentialParameters" : SIMD2<Double>(55.8574,2.69141)],
      "Al": ["atomicNumber": 13, "group": 13, "period": 3, "name": "Aluminum", "mass": 26.9815386, "atomRadius": 1.43, "covalentRadius": 1.21, "tripleBondCovalentRadius": 1.11, "vDWRadius": 1.84, "oxidationState": [-2,-1,1,2,3], "potentialParameters" : SIMD2<Double>(22.0,2.30)],
      "Si": ["atomicNumber": 14, "group": 14, "period": 3, "name": "Silicon", "mass": 28.0855, "atomRadius": 1.11, "covalentRadius": 1.11, "tripleBondCovalentRadius": 1.02, "vDWRadius": 2.1, "oxidationState": [-4,-3,-2,-1,1,2,3,4], "potentialParameters" : SIMD2<Double>(22.0,2.30)],
      "P": ["atomicNumber": 15, "group": 15, "period": 3, "name": "Phosphorus", "mass": 30.973762, "atomRadius": 0.98, "covalentRadius": 1.07, "tripleBondCovalentRadius": 0.94, "vDWRadius": 1.8, "oxidationState": [-3,-2,-1,1,2,3,4,5], "potentialParameters" : SIMD2<Double>(161.03, 3.69723)],
      "S": ["atomicNumber": 16, "group": 16, "period": 3, "name": "Sulfur", "mass": 32.065, "atomRadius": 0.88, "covalentRadius": 1.05, "tripleBondCovalentRadius": 0.95, "vDWRadius": 1.8, "oxidationState": [-2,-1,1,2,3,4,5,6], "potentialParameters" : SIMD2<Double>(173.107,3.59032)],
      "Cl": ["atomicNumber": 17, "group": 17, "period": 3, "name": "Chlorine", "mass": 35.453, "atomRadius": 0.79, "covalentRadius": 1.02, "tripleBondCovalentRadius": 0.93, "vDWRadius": 1.75, "oxidationState": [-1,1,2,3,4,5,6,7], "potentialParameters" : SIMD2<Double>(142.562, 3.51932)],
      "Ar": ["atomicNumber": 18, "group": 18, "period": 3, "name": "Argon", "mass": 39.948, "atomRadius": 0.71, "covalentRadius": 1.06, "tripleBondCovalentRadius": 0.96, "vDWRadius": 1.88, "oxidationState": [0]],
      "K": ["atomicNumber": 19, "group": 1, "period": 4, "name": "Potassium", "mass": 39.0983, "atomRadius": 2.27, "covalentRadius": 2.03, "tripleBondCovalentRadius": 0.0, "vDWRadius": 2.75, "oxidationState": [-1,1]],
      "Ca": ["atomicNumber": 20, "group": 2, "period": 4, "name": "Calcium", "mass": 40.078, "atomRadius": 1.97, "covalentRadius": 1.76, "tripleBondCovalentRadius": 1.33, "vDWRadius": 2.31, "oxidationState": [1,2], "potentialParameters" : SIMD2<Double>(119.766,3.02816)],
      "Sc": ["atomicNumber": 21, "group": 3, "period": 4, "name": "Scandium", "mass": 44.955912, "atomRadius": 1.62, "covalentRadius": 1.7, "tripleBondCovalentRadius": 1.14, "vDWRadius": 2.11, "oxidationState": [1,2,3], "potentialParameters" : SIMD2<Double>(9.56117,2.93551)],
      "Ti": ["atomicNumber": 22, "group": 4, "period": 4, "name": "Titanium", "mass": 47.867, "atomRadius": 1.47, "covalentRadius": 1.6, "tripleBondCovalentRadius": 1.08, "vDWRadius": 2.14, "oxidationState": [-2,-1,1,2,3,4], "potentialParameters" : SIMD2<Double>(8.55473,2.8286)],
      "V": ["atomicNumber": 23, "group": 5, "period": 4, "name": "Vanadium", "mass": 50.9415, "atomRadius": 1.34, "covalentRadius": 1.53, "tripleBondCovalentRadius": 1.06, "vDWRadius": 2.12, "oxidationState": [-3,-1,1,2,3,4,5], "potentialParameters" : SIMD2<Double>(8.05151,2.80099)],
      "Cr": ["atomicNumber": 24, "group": 6, "period": 4, "name": "Chromium", "mass": 51.9961, "atomRadius": 1.28, "covalentRadius": 1.39, "tripleBondCovalentRadius": 1.03, "vDWRadius": 1.97, "oxidationState": [-4,-2,-1,1,2,3,4,5,6], "potentialParameters" : SIMD2<Double>(7.54829,2.69319)],
      "Mn": ["atomicNumber": 25, "group": 7, "period": 4, "name": "Manganese", "mass": 54.939045, "atomRadius": 1.27, "covalentRadius": 1.39, "tripleBondCovalentRadius": 1.03, "vDWRadius": 1.96, "oxidationState": [-3,-2,1,1,2,3,4,5,6,7], "potentialParameters" : SIMD2<Double>(6.54185,2.63795)],
      "Fe": ["atomicNumber": 26, "group": 8, "period": 4, "name": "Iron", "mass": 55.845, "atomRadius": 1.26, "covalentRadius": 1.32, "tripleBondCovalentRadius": 1.02, "vDWRadius": 1.96, "oxidationState": [-4,-2,-1,1,2,3,4,5,6,7], "potentialParameters" : SIMD2<Double>(6.54185,2.5943)],
      "Co": ["atomicNumber": 27, "group": 9, "period": 4, "name": "Cobalt", "mass": 58.933195, "atomRadius": 1.25, "covalentRadius": 1.26, "tripleBondCovalentRadius": 0.96, "vDWRadius": 1.95, "oxidationState": [-3,-1,1,2,3,4,5], "potentialParameters" : SIMD2<Double>(7.04507,2.55866)],
      "Ni": ["atomicNumber": 28, "group": 10, "period": 4, "name": "Nickel", "mass": 58.6934 , "atomRadius": 1.24, "covalentRadius": 1.24, "tripleBondCovalentRadius": 1.01, "vDWRadius": 1.63, "oxidationState": [-2,-1,1,2,3,4], "potentialParameters" : SIMD2<Double>(7.54829,2.52481)],
      "Cu": ["atomicNumber": 29, "group": 11, "period": 4, "name": "Copper", "mass": 63.546,"atomRadius": 1.28, "covalentRadius": 1.32, "tripleBondCovalentRadius": 1.2, "vDWRadius": 1.4, "oxidationState": [-2,1,2,3,4], "potentialParameters" : SIMD2<Double>(2.5161,3.11369)],
      "Zn": ["atomicNumber": 30, "group": 12, "period": 4, "name": "Zinc", "mass": 65.38, "atomRadius": 1.34, "covalentRadius": 1.22, "tripleBondCovalentRadius": 0.0, "vDWRadius": 1.39, "oxidationState": [-2,0,1,2], "potentialParameters" : SIMD2<Double>(62.3992, 2.46155)],
      "Ga": ["atomicNumber": 31, "group": 13, "period": 4, "name": "Gallium", "mass": 69.723, "atomRadius": 1.35, "covalentRadius": 1.22, "tripleBondCovalentRadius": 1.21, "vDWRadius": 1.87, "oxidationState": [-5,-4,-2,-1,1,2,3], "potentialParameters" : SIMD2<Double>(208.836,3.90481)],
      "Ge": ["atomicNumber": 32, "group": 14, "period": 4, "name": "Germanium", "mass": 72.64, "atomRadius": 1.22, "covalentRadius": 1.22, "tripleBondCovalentRadius": 1.14, "vDWRadius": 2.11, "oxidationState": [-4,-3,-2,-1,0,1,2,3,4]],
      "As": ["atomicNumber": 33, "group": 15, "period": 4, "name": "arsenic", "mass": 74.9216, "atomRadius": 1.19, "covalentRadius": 1.19, "tripleBondCovalentRadius": 1.06, "vDWRadius": 1.85, "oxidationState": [-3,-2,-1,1,2,3,4,5]],
      "Se": ["atomicNumber": 34, "group": 16, "period": 3, "name": "Selenium", "mass": 78.96, "atomRadius": 1.20, "covalentRadius": 1.2, "tripleBondCovalentRadius": 1.07, "vDWRadius": 1.9, "oxidationState": [-2,-1,1,2,3,4,5,6]],
      "Br": ["atomicNumber": 35, "group": 17, "period": 4, "name": "Bromine", "mass": 79.904, "atomRadius": 1.2, "covalentRadius": 1.2, "tripleBondCovalentRadius": 1.1, "vDWRadius": 1.85, "oxidationState": [-1,1,3,4,5,7], "potentialParameters" : SIMD2<Double>(186.191,3.51905)],
      "Kr": ["atomicNumber": 36, "group": 18, "period": 4, "name": "Krypton", "mass": 83.798, "atomRadius": 0.88, "covalentRadius": 1.16, "tripleBondCovalentRadius": 1.08, "vDWRadius": 2.02, "oxidationState": [0,1,2]],
      "Rb": ["atomicNumber": 37, "group": 1, "period": 5, "name": "Rubidium", "mass": 85.4678, "atomRadius": 2.48, "covalentRadius": 2.2, "tripleBondCovalentRadius": 0.0, "vDWRadius": 3.03, "oxidationState": [-1,1]],
      "Sr": ["atomicNumber": 38, "group": 2, "period": 5, "name": "Strontium", "mass": 87.62, "atomRadius": 2.15, "covalentRadius": 1.95, "tripleBondCovalentRadius": 1.39, "vDWRadius": 2.49, "oxidationState": [1,2]],
      "Y": ["atomicNumber": 39, "group": 3, "period": 5, "name": "Yttrium", "mass": 88.90585, "atomRadius": 1.80, "covalentRadius": 1.9, "tripleBondCovalentRadius": 1.24, "vDWRadius": 2.45, "oxidationState": [1,2,3]],
      "Zr": ["atomicNumber": 40, "group": 4, "period": 5, "name": "Zirconium", "mass": 91.224, "atomRadius": 1.60, "covalentRadius": 1.75, "tripleBondCovalentRadius": 1.21, "vDWRadius": 0.0, "oxidationState": [-2,1,2,3,4], "potentialParameters" : SIMD2<Double>(34.7221,2.78317)],
      "Nb": ["atomicNumber": 41, "group": 5, "period": 5, "name": "Niobium", "mass": 92.90638, "atomRadius": 1.46, "covalentRadius": 1.64, "tripleBondCovalentRadius": 1.16, "vDWRadius": 0.0, "oxidationState": [-3,-1,1,2,3,4,5]],
      "Mo": ["atomicNumber": 42, "group": 6, "period": 5, "name": "Molybdenum", "mass": 95.96, "atomRadius": 1.39, "covalentRadius": 1.54, "tripleBondCovalentRadius": 1.13, "vDWRadius": 2.06, "oxidationState": [-4,-2,-1,1,2,3,4,5,6]],
      "Tc": ["atomicNumber": 43, "group": 7, "period": 5, "name": "Technetium", "mass": 98.0, "atomRadius": 1.36, "covalentRadius": 1.47, "tripleBondCovalentRadius": 1.10, "vDWRadius": 0.0, "oxidationState": [-3,-1,1,2,3,4,5,6,7]],
      "Ru": ["atomicNumber": 44, "group": 8, "period": 5, "name": "Ruthenium", "mass": 101.07, "atomRadius": 1.34, "covalentRadius": 1.46, "tripleBondCovalentRadius": 1.03, "vDWRadius": 2.02, "oxidationState": [-4,-2,1,2,3,4,5,6,7,8]],
      "Rh": ["atomicNumber": 45, "group": 9, "period": 5, "name": "Rhodium", "mass": 102.59055, "atomRadius": 1.34, "covalentRadius": 1.42, "tripleBondCovalentRadius": 1.06, "vDWRadius": 2.02, "oxidationState": [-3,-1,1,2,3,4,5,6]],
      "Pd": ["atomicNumber": 46, "group": 10, "period": 5, "name": "Palladium", "mass": 106.42, "atomRadius": 1.37, "covalentRadius": 1.39, "tripleBondCovalentRadius": 1.12, "vDWRadius": 1.63, "oxidationState": [0,1,2,3,4]],
      "Ag": ["atomicNumber": 47, "group": 11, "period": 5, "name": "Silver", "mass": 107.8682, "atomRadius": 1.44, "covalentRadius": 1.45, "tripleBondCovalentRadius": 1.37, "vDWRadius": 1.72, "oxidationState": [-2,-1,1,2,3], "potentialParameters" : SIMD2<Double>(18.1159,2.80455)],
      "Cd": ["atomicNumber": 48, "group": 12, "period": 5, "name": "Cadmium", "mass": 112.411, "atomRadius": 1.51, "covalentRadius": 1.44, "tripleBondCovalentRadius": 0.0, "vDWRadius": 1.58, "oxidationState": [-2,1,2], "potentialParameters" : SIMD2<Double>(114.734,2.53728)],
      "In": ["atomicNumber": 49, "group": 13, "period": 5, "name": "Indium", "mass": 114.818, "atomRadius": 1.67, "covalentRadius": 1.42, "tripleBondCovalentRadius": 1.46, "vDWRadius": 1.93, "oxidationState": [-5,-2,-1,1,2,3], "potentialParameters" : SIMD2<Double>(301.428,3.97608)],
      "Sn": ["atomicNumber": 50, "group": 14, "period": 5, "name": "Tin", "mass": 118.71, "atomRadius": 1.40, "covalentRadius": 1.39, "tripleBondCovalentRadius": 1.32, "vDWRadius": 2.17, "oxidationState": [-4,-3,-2,-1,1,2,3,4]],
      "Sb": ["atomicNumber": 51, "group": 15, "period": 5, "name": "Antimony", "mass": 121.76, "atomRadius": 1.40, "covalentRadius": 1.39, "tripleBondCovalentRadius": 1.27, "vDWRadius": 2.06, "oxidationState": [-3,-2,-1,1,2,3,4,5], "potentialParameters" : SIMD2<Double>(225.946,3.93777)],
      "Te": ["atomicNumber": 52, "group": 16, "period": 5, "name": "Tellurium", "mass": 127.6, "atomRadius": 1.40, "covalentRadius": 1.38, "tripleBondCovalentRadius": 1.21, "vDWRadius": 2.06, "oxidationState": [-2,-1,1,2,3,4,5,6], "potentialParameters" : SIMD2<Double>(200.281,3.98232)],
      "I": ["atomicNumber": 53, "group": 17, "period": 5, "name": "Iodine", "mass": 126.90447, "atomRadius": 1.40, "covalentRadius": 1.39, "tripleBondCovalentRadius": 1.25, "vDWRadius": 1.98, "oxidationState": [-1,1,3,4,5,6,7]],
      "Xe": ["atomicNumber": 54, "group": 18, "period": 5, "name": "Xenon", "mass": 131.293, "atomRadius": 1.08, "covalentRadius": 1.4, "tripleBondCovalentRadius": 1.22, "vDWRadius": 2.16, "oxidationState": [0,1,2,4,6,8]],
      "Cs": ["atomicNumber": 55, "group": 1, "period": 6, "name": "Cesium", "mass": 132.9054519, "atomRadius": 2.65, "covalentRadius": 2.44, "tripleBondCovalentRadius": 0.0, "vDWRadius": 3.43, "oxidationState": [-1,1]],
      "Ba": ["atomicNumber": 56, "group": 2, "period": 6, "name": "Barium", "mass": 137.327, "atomRadius": 2.22, "covalentRadius": 2.15, "tripleBondCovalentRadius": 1.49, "vDWRadius": 2.68, "oxidationState": [1,2]],
      "La": ["atomicNumber": 57, "group": -1, "period": 6, "name": "Lanthanum", "mass": 138.90547, "atomRadius": 1.87, "covalentRadius": 2.07, "tripleBondCovalentRadius": 1.39, "vDWRadius": 2.51, "oxidationState": [1,2,3]],
      "Ce": ["atomicNumber": 58, "group": -1, "period": 6, "name": "Cerium", "mass": 140.116, "atomRadius": 1.818, "covalentRadius": 2.04, "tripleBondCovalentRadius": 1.31, "vDWRadius": 0.0, "oxidationState": [1,2,3,4]],
      "Pr": ["atomicNumber": 59, "group": -1, "period": 6, "name": "Praseodymium", "mass": 140.90765, "atomRadius": 1.82, "covalentRadius": 2.03, "tripleBondCovalentRadius": 1.28,"vDWRadius": 0.0, "oxidationState": [2,3,4,5]],
      "Nd": ["atomicNumber": 60, "group": -1, "period": 6, "name": "Neodymium", "mass": 144.242, "atomRadius": 1.81, "covalentRadius": 2.01, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [2,3,4]],
      "Pm": ["atomicNumber": 61, "group": -1, "period": 6, "name": "Promethium", "mass": 145.0, "atomRadius": 1.83, "covalentRadius": 1.99, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [2,3]],
      "Sm": ["atomicNumber": 62, "group": -1, "period": 6, "name": "Samarium", "mass": 150.36, "atomRadius": 1.80, "covalentRadius": 1.98, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [1,2,3,4]],
      "Eu": ["atomicNumber": 63, "group": -1, "period": 6, "name": "Europium", "mass": 151.964, "atomRadius": 1.80, "covalentRadius": 1.98, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [1,2,3]],
      "Gd": ["atomicNumber": 64, "group": -1, "period": 6, "name": "Gadolinium", "mass": 157.25, "atomRadius": 1.80, "covalentRadius": 1.96, "tripleBondCovalentRadius": 1.32, "vDWRadius": 0.0, "oxidationState": [1,2,3]],
      "Tb": ["atomicNumber": 65, "group": -1, "period": 6, "name": "Terbium", "mass": 158.92535, "atomRadius": 1.77, "covalentRadius": 1.94, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [1,2,3,4]],
      "Dy": ["atomicNumber": 66, "group": -1, "period": 6, "name": "Dysprodium", "mass": 162.5, "atomRadius": 1.78, "covalentRadius": 1.92, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [1,2,3,4]],
      "Ho": ["atomicNumber": 67, "group": -1, "period": 6, "name": "Holmium", "mass": 164.93032, "atomRadius": 1.76, "covalentRadius": 1.92, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [1,2,3]],
      "Er": ["atomicNumber": 68, "group": -1, "period": 6, "name": "Erbium", "mass": 167.259, "atomRadius": 1.76, "covalentRadius": 1.89, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [1,2,3]],
      "Tm": ["atomicNumber": 69, "group": -1, "period": 6, "name": "Thulium", "mass": 168.93421, "atomRadius": 1.76, "covalentRadius": 1.9, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [2,3]],
      "Yb": ["atomicNumber": 70, "group": -1, "period": 6, "name": "Ytterbium", "mass": 173.054, "atomRadius": 1.76, "covalentRadius": 1.87, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [1,2,3]],
      "Lu": ["atomicNumber": 71, "group": 3, "period": 6, "name": "Lutetium", "mass": 174.9668, "atomRadius": 1.74, "covalentRadius": 1.87, "tripleBondCovalentRadius": 1.31, "vDWRadius": 0.0, "oxidationState": [1,2,3]],
      "Hf": ["atomicNumber": 72, "group": 4, "period": 6, "name": "Hafnium", "mass": 178.49, "atomRadius": 1.59, "covalentRadius": 1.75, "tripleBondCovalentRadius": 1.22, "vDWRadius": 0.0, "oxidationState": [-2,1,2,3,4]],
      "Ta": ["atomicNumber": 73, "group": 5, "period": 6, "name": "Tantalum", "mass": 180.94788, "atomRadius": 1.46, "covalentRadius": 1.7, "tripleBondCovalentRadius": 1.19, "vDWRadius": 0.0, "oxidationState": [-3,-1,1,2,3,4,5]],
      "W": ["atomicNumber": 74, "group": 6, "period": 6, "name": "Tungsten", "mass": 183.84, "atomRadius": 1.39, "covalentRadius": 1.62, "tripleBondCovalentRadius": 1.15, "vDWRadius": 2.07, "oxidationState": [-4,-2,-1,0,1,2,3,4,5,6]],
      "Re": ["atomicNumber": 75, "group": 7, "period": 6, "name": "Rhenium", "mass": 186.207, "atomRadius": 1.37, "covalentRadius": 1.51, "tripleBondCovalentRadius": 1.1, "vDWRadius": 2.05, "oxidationState": [-3,-1,0,1,2,3,4,5,6,7]],
      "Os": ["atomicNumber": 76, "group": 8, "period": 6, "name": "Osmium", "mass": 190.23, "atomRadius": 1.35, "covalentRadius": 1.44, "tripleBondCovalentRadius": 1.09, "vDWRadius": 2.03, "oxidationState": [-4,-2,0,1,2,3,4,5,6,7,8]],
      "Ir": ["atomicNumber": 77, "group": 9, "period": 6, "name": "Iridium", "mass": 192.217, "atomRadius": 1.36, "covalentRadius": 1.41, "tripleBondCovalentRadius": 1.07, "vDWRadius": 2.03, "oxidationState": [-3,-1,0,1,2,3,4,5,6,7,8,9]],
      "Pt": ["atomicNumber": 78, "group": 10, "period": 6, "name": "Platinum", "mass": 195.084, "atomRadius": 1.39, "covalentRadius": 1.36, "tripleBondCovalentRadius": 1.1, "vDWRadius": 1.75, "oxidationState": [-3,-2,-1,1,2,3,4,5,6]],
      "Au": ["atomicNumber": 79, "group": 11, "period": 6, "name": "Gold", "mass": 196.966569, "atomRadius": 1.44, "covalentRadius": 1.36, "tripleBondCovalentRadius": 1.23, "vDWRadius": 1.66, "oxidationState": [-3,-2,-1,1,2,3,5]],
      "Hg": ["atomicNumber": 80, "group": 12, "period": 6, "name": "Mercury", "mass": 200.59, "atomRadius": 1.51, "covalentRadius": 1.32, "tripleBondCovalentRadius": 1.55, "vDWRadius": 0.0, "oxidationState": [-2,1,2]],
      "Tl": ["atomicNumber": 81, "group": 13, "period": 6, "name": "Thallium", "mass": 204.3833, "atomRadius": 1.70, "covalentRadius": 1.45, "tripleBondCovalentRadius": 0.15, "vDWRadius": 1.96, "oxidationState": [-5,-2,-1,1,2,3]],
      "Pb": ["atomicNumber": 82, "group": 14, "period": 6, "name": "Lead", "mass": 207.2, "atomRadius": 1.75, "covalentRadius": 1.46, "tripleBondCovalentRadius": 1.37, "vDWRadius": 2.02, "oxidationState": [-4,-2,-1,2,3,4]],
      "Bi": ["atomicNumber": 83, "group": 15, "period": 6, "name": "Bismuth", "mass": 208.9804, "atomRadius": 1.56, "covalentRadius": 1.48, "tripleBondCovalentRadius": 1.35, "vDWRadius": 2.07, "oxidationState": [-3,-2,-1,1,2,3,4,5]],
      "Po": ["atomicNumber": 84, "group": 16, "period": 6, "name": "Polonium", "mass": 210.0, "atomRadius": 1.68, "covalentRadius": 1.4, "tripleBondCovalentRadius": 1.29, "vDWRadius": 1.97, "oxidationState": [-2,2,4,5,6]],
      "At": ["atomicNumber": 85, "group": 17, "period": 6, "name": "Astatine", "mass": 210.8, "atomRadius": 0.0, "covalentRadius": 1.5, "tripleBondCovalentRadius": 1.38, "vDWRadius": 2.02, "oxidationState": [-1,1,3,5,7]],
      "Rn": ["atomicNumber": 86, "group": 18, "period": 6, "name": "Radon", "mass": 222.0, "atomRadius": 1.2, "covalentRadius": 1.5, "tripleBondCovalentRadius": 1.33, "vDWRadius": 2.20, "oxidationState": [0,2,6]],
      "Fr": ["atomicNumber": 87, "group": 1, "period": 7, "name": "Francium", "mass": 223.0, "atomRadius": 0.0, "covalentRadius": 2.6, "tripleBondCovalentRadius": 0.0, "vDWRadius": 3.48, "oxidationState": [1]],
      "Ra": ["atomicNumber": 88, "group": 2, "period": 7, "name": "Radium", "mass": 226.0, "atomRadius": 0.0, "covalentRadius": 2.21, "tripleBondCovalentRadius": 1.59, "vDWRadius": 2.83, "oxidationState": [2]],
      "Ac": ["atomicNumber": 89, "group": -1, "period": 7, "name": "Actinium", "mass": 227.0, "atomRadius": 0.0, "covalentRadius": 2.15, "tripleBondCovalentRadius": 1.4, "vDWRadius": 0.0, "oxidationState": [2,3]],
      "Th": ["atomicNumber": 90, "group": -1, "period": 7, "name": "Thorium", "mass": 232.03806, "atomRadius": 1.798, "covalentRadius": 2.06, "tripleBondCovalentRadius": 1.36, "vDWRadius": 2.43, "oxidationState": [1,2,3,4]],
      "Pa": ["atomicNumber": 91, "group": -1, "period": 7, "name": "Protactinium", "mass": 231.03588, "atomRadius": 1.63, "covalentRadius": 2.0, "tripleBondCovalentRadius": 1.29, "vDWRadius": 0.0, "oxidationState": [2,3,4,5]],
      "U": ["atomicNumber": 92, "group": -1, "period": 7, "name": "Uranium", "mass": 238.02891, "atomRadius": 1.56, "covalentRadius": 1.96, "tripleBondCovalentRadius": 1.18, "vDWRadius": 1.86, "oxidationState": [1,2,3,4,5,6]],
      "Np": ["atomicNumber": 93, "group": -1, "period": 7, "name": "Neptunium", "mass": 237.0, "atomRadius": 1.55, "covalentRadius": 1.9, "tripleBondCovalentRadius": 1.16, "vDWRadius": 0.0, "oxidationState": [2,3,4,5,6,7]],
      "Pu": ["atomicNumber": 94, "group": -1, "period": 7, "name": "Plutonium", "mass": 244.0, "atomRadius": 1.59, "covalentRadius": 1.87, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [1,2,3,4,5,6,7,8]],
      "Am": ["atomicNumber": 95, "group": -1, "period": 7, "name": "Americium", "mass": 243.0, "atomRadius": 1.73, "covalentRadius": 1.8, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [2,3,4,5,6,7,8]],
      "Cm": ["atomicNumber": 96, "group": -1, "period": 7, "name": "Curium", "mass": 247.0, "atomRadius": 1.74, "covalentRadius": 1.69, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [2,3,4,6]],
      "Bk": ["atomicNumber": 97, "group": -1, "period": 7, "name": "Berkelium", "mass": 247.0, "atomRadius": 1.7, "covalentRadius": 0.0, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [2,3,4]],
      "Cf": ["atomicNumber": 98, "group": -1, "period": 7, "name": "Californium", "mass": 251.0, "atomRadius": 0.0, "covalentRadius": 0.0, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [2,3,4]],
      "Es": ["atomicNumber": 99, "group": -1, "period": 7, "name": "Einsteinium", "mass": 252.0, "atomRadius": 0.0, "covalentRadius": 0.0, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [2,3,4]],
      "Fm": ["atomicNumber": 100, "group": -1, "period": 7, "name": "Fermium", "mass": 257.0, "atomRadius": 0.0, "covalentRadius": 0.0, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [2,3]],
      "Md": ["atomicNumber": 101, "group": -1, "period": 7, "name": "Mendelevium", "mass": 258.0, "atomRadius": 0.0, "covalentRadius": 0.0, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [2,3]],
      "No": ["atomicNumber": 102, "group": -1, "period": 7, "name": "Nobelium", "mass": 259.0, "atomRadius": 0.0, "covalentRadius": 0.0, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [2,3]],
      "Lr": ["atomicNumber": 103, "group": 3, "period": 7, "name": "Lawrencium", "mass": 262.0, "atomRadius": 0.0, "covalentRadius": 0.0, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [3]],
      "Rf": ["atomicNumber": 104, "group": 4, "period": 7, "name": "Rutherfordium", "mass": 261.0, "atomRadius": 0.0, "covalentRadius": 0.0, "tripleBondCovalentRadius": 1.31, "vDWRadius": 0.0, "oxidationState": [2,3,4]],
      "Db": ["atomicNumber": 105, "group": 5, "period": 7, "name": "Dubnium", "mass": 268.0, "atomRadius": 1.39, "covalentRadius": 1.49, "tripleBondCovalentRadius": 1.26, "vDWRadius": 0.0, "oxidationState": [3,4,5]],
      "Sg": ["atomicNumber": 106, "group": 6, "period": 7, "name": "Seaborgium", "mass": 269.0, "atomRadius": 1.32, "covalentRadius": 1.43, "tripleBondCovalentRadius": 1.21, "vDWRadius": 0.0, "oxidationState": [3,4,5,6]],
      "Bh": ["atomicNumber": 107, "group": 7, "period": 7, "name": "Bohrium", "mass": 270.0, "atomRadius": 1.28, "covalentRadius": 1.41, "tripleBondCovalentRadius": 1.19, "vDWRadius": 0.0, "oxidationState": [3,4,5,7]],
      "Hs": ["atomicNumber": 108, "group": 8, "period": 7, "name": "Hassium", "mass": 269.0, "atomRadius": 1.26, "covalentRadius": 1.34, "tripleBondCovalentRadius": 1.18, "vDWRadius": 0.0, "oxidationState": [2,3,4,5,6,8]],
      "Mt": ["atomicNumber": 109, "group": 9, "period": 7, "name": "Meitnerium", "mass": 278.0, "atomRadius": 1.28, "covalentRadius": 1.29, "tripleBondCovalentRadius": 1.13, "vDWRadius": 0.0, "oxidationState": [1,3,4,6,8,9]],
      "Ds": ["atomicNumber": 110, "group": 10, "period": 7, "name": "Darmstadtium", "mass": 281.0, "atomRadius": 1.32, "covalentRadius": 1.28, "tripleBondCovalentRadius": 1.12, "vDWRadius": 0.0, "oxidationState": [0,2,4,6,8]],
      "Rg": ["atomicNumber": 111, "group": 11, "period": 7, "name": "Roentgenium", "mass": 281.0, "atomRadius": 1.38, "covalentRadius": 1.21, "tripleBondCovalentRadius": 1.18, "vDWRadius": 0.0, "oxidationState": [-1,1,3,5]],
      "Cn": ["atomicNumber": 112, "group": 12, "period": 7, "name": "Copernicium", "mass": 285.0, "atomRadius": 1.47, "covalentRadius": 1.22, "tripleBondCovalentRadius": 1.30, "vDWRadius": 0.0, "oxidationState": [0,1,2]],
      "Nh": ["atomicNumber": 113, "group": 13, "period": 7, "name": "Nihonium", "mass": 286.0, "atomRadius": 1.70, "covalentRadius": 1.76, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [-1,1,3,5]],
      "Fl": ["atomicNumber": 114, "group": 14, "period": 7, "name": "Flerovium", "mass": 289.0, "atomRadius": 1.80, "covalentRadius": 1.74, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [0,1,2,4,6]],
      "Mc": ["atomicNumber": 115, "group": 15, "period": 7, "name": "Moscovium", "mass": 288.0, "atomRadius": 1.87, "covalentRadius": 1.57, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [1,3]],
      "Lv": ["atomicNumber": 116, "group": 16, "period": 7, "name": "Livermorium", "mass": 293.0, "atomRadius": 1.83, "covalentRadius": 1.64, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [-2,2,4]],
      "Ts": ["atomicNumber": 117, "group": 17, "period": 7, "name": "Tennessine", "mass": 294.0, "atomRadius": 1.38, "covalentRadius": 1.56, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [-1,1,3,5]],
      "Og": ["atomicNumber": 118, "group": 18, "period": 7, "name": "Oganesson", "mass": 294.0, "atomRadius": 1.52, "covalentRadius": 1.57, "tripleBondCovalentRadius": 0.0, "vDWRadius": 0.0, "oxidationState": [-1,0,1,2,4,6]]
  ]
 
  
  
  
  enum AminoAcid: Int
  {
    case ala = 0
    case asx = 1
    case cys = 2
    case asp = 3
    case glu = 4
    case phe = 5
    case gly = 6
    case his = 7
    case ile = 8
    case lys = 10
    case leu = 11
    case met = 12
    case asn = 13
    case pyl = 14
    case pro = 15
    case gln = 16
    case arg = 17
    case ser = 18
    case thr = 19
    case sec = 20
    case val = 21
    case trp = 22
    case tyr = 24
    case glx = 25
    case unk = 26
  }
  
  static let aminoAcidAtomTypes: Dictionary<String,Dictionary<String,Any>> =
    [
      "NH1" : ["Element" : "N", "Type" : "BackBone NH", "vdWradius" : 1.65],
      "NC2" : ["Element" : "N", "Type" : "Charged, Arg NH1, NH2", "vdWradius" : 1.65],
      "NH3" : ["Element" : "N", "Type" : "Charged, Lys NZ", "vdWradius" : 1.50],
      "NH2" : ["Element" : "N", "Type" : "Uncharged, Asn ND2, Gln NE2", "vdWradius" : 1.65],
      "N" : ["Element" : "N", "Type" : "Uncharged, Pro N", "vdWradius" : 1.65],
      "NH1S" : ["Element" : "N", "Type" : "Uncharged, Sidechain NH: Arg NE, His ND1, NE1, Trp NE1", "vdWradius" : 1.65],
      "O" : ["Element" : "O", "Type" : "Backbone O", "vdWradius" : 1.40],
      "OS" : ["Element" : "O", "Type" : "Backbone, Sidechain O: Asn OD1, Gln OE1", "vdWradius" : 1.40],
      "OC" : ["Element" : "O", "Type" : "Carboxyl O, (Asp OD1, OD2, Glu OE1, OE2)", "vdWradius" : 1.40],
      "OH1" : ["Element" : "O", "Type" : "Hydroxyl, Alcohol OH (Ser OG, Thr OG1, Tyr OH)", "vdWradius" : 1.40],
      "C" : ["Element" : "C", "Type" : "Backbone C", "vdWradius" : 1.76],
      "CH1E": ["Element" : "C", "Type" : "Backbone CA (exc. Gly)", "vdWradius" : 1.87],
      "CH2G" : ["Element" : "C", "Type" : "Backbone CA, Gly CA", "vdWradius" : 1.87],
      "CR1E" : ["Element" : "C", "Type" : "Aromatic C, Aromatic CH (except CR1W, CRHH, CR1H)", "vdWradius" : 1.76],
      "CR1W" : ["Element" : "C", "Type" : "Aromatic C, Trp CZ2, CH2", "vdWradius" : 1.76],
      "CRHH" : ["Element" : "C", "Type" : "Aromatic C, His CE1", "vdWradius" : 1.76],
      "CR1H" : ["Element" : "C", "Type" : "Aromatic C, His CD2", "vdWradius" : 1.76],
      "CH0" : ["Element" : "C", "Type" : "Aliphatic C, Arg CZ, Asn CG, Asp CG, Gln CD, Glu CD", "vdWradius" : 1.76],
      "CH1S" : ["Element" : "C", "Type" : "Aliphatic C, Sidechain CH1: Ile CB, Leu CG, Thr CB, Val CB", "vdWradius" : 1.87],
      "CF" : ["Element" : "C", "Type" : "Aliphatic C, Phe CG", "vdWradius" : 1.76],
      "CY" : ["Element" : "C", "Type" : "Aliphatic C, Tyr CG", "vdWradius" : 1.76],
      "CW" : ["Element" : "C", "Type" : "Aliphatic C, Trp CD2, CE2", "vdWradius" : 1.76],
      "C5" : ["Element" : "C", "Type" : "Aliphatic C, His CG", "vdWradius" : 1.76],
      "C5W" : ["Element" : "C", "Type" : "Aliphatic C, Trp CG", "vdWradius" : 1.76],
      "CH2E" : ["Element" : "C", "Type" : "Aliphatic C, Tetrahedral CH2 (except CH2P,CH2G) All CB", "vdWradius" : 1.87],
      "CH2P" : ["Element" : "C", "Type" : "Aliphatic C, Pro CG, CD", "vdWradius" : 1.87],
      "CY2" : ["Element" : "C", "Type" : "Aliphatic C, Tyr CZ", "vdWradius" : 1.76],
      "CH3E" : ["Element" : "C", "Type" : "Aliphatic C, Tetrahedral CH3", "vdWradius" : 1.87],
      "SH1E" : ["Element" : "S", "Type" : "All sulphurs, Cys S", "vdWradius" : 1.85],
      "SM" : ["Element" : "S", "Type" : "All sulphurs, Met S", "vdWradius" : 1.85],
      "HOH" : ["Element" : "O", "Type" : "Water", "vdWradius" : 1.40]
  ]
  
  
  static let aminoAcidData: Dictionary<String,Dictionary<String,Any>> =
    [
      "ALA": ["Type": AminoAcid.ala, "Residue": "Alanine", "Synonym": "A", "MolecularWeight": 89.09404, "Formula": "C3 H7 N1 O2"],
      "ASX": ["Type": AminoAcid.asx, "Residue": "ASP/ASN ambiguous", "Synonym": "B", "MolecularWeight": 132.61, "Formula": "C4 H71/2 N11/2 O31/2"],
      "CYS": ["Type": AminoAcid.cys, "Residue": "Cysteine", "Synonym": "C", "MolecularWeight": 121.15404, "Formula": "C3 H7 N1 O2 S1"],
      "ASP": ["Type": AminoAcid.asp, "Residue": "Aspartic acid", "Synonym": "D", "MolecularWeight": 133.10384, "Formula": "C4 H7 N1 O4"],
      "GLU": ["Type": AminoAcid.glu, "Residue": "Glutamic acid", "Synonym": "E", "MolecularWeight": 147.13074, "Formula": "C5 H9 N1 O4"],
      "PHE": ["Type": AminoAcid.phe, "Residue": "Phenylalanine", "Synonym": "F", "MolecularWeight": 165.19184, "Formula": "C9 H11 N1 O2"],
      "GLY": ["Type": AminoAcid.gly, "Residue": "Glycine", "Synonym": "G", "MolecularWeight": 75.06714, "Formula": "C2 H5 N1 O2"],
      "HIS": ["Type": AminoAcid.his, "Residue": "Histidine", "Synonym": "H", "MolecularWeight": 155.15634, "Formula": "C6 H9 N3 O2"],
      "ILE": ["Type": AminoAcid.ile, "Residue": "Isoleucine", "Synonym": "I", "MolecularWeight": 131.17464, "Formula": "C6 H13 N1 O2"],
      "LYS": ["Type": AminoAcid.lys, "Residue": "Lysine", "Synonym": "K", "MolecularWeight": 146.18934, "Formula": "C6 H14 N2 O2"],
      "LEU": ["Type": AminoAcid.leu, "Residue": "Leucine", "Synonym": "L", "MolecularWeight": 131.17464, "Formula": "C6 H13 N1 O2"],
      "MET": ["Type": AminoAcid.met, "Residue": "Methionine", "Synonym": "M", "MolecularWeight": 149.20784, "Formula": "C5 H11 N1 O2 S1"],
      "ASN": ["Type": AminoAcid.asn, "Residue": "Asparagine", "Synonym": "N", "MolecularWeight": 132.11904, "Formula": "C4 H8 N2 O3"],
      "PYL": ["Type": AminoAcid.pyl, "Residue": "Pyrrolysine", "Synonym": "O", "MolecularWeight": 255.31, "Formula": ""],
      "PRO": ["Type": AminoAcid.pro, "Residue": "Proline", "Synonym": "P", "MolecularWeight": 115.13194, "Formula": "C5 H9 N1 O2"],
      "GLN": ["Type": AminoAcid.gln, "Residue": "Glutamine", "Synonym": "Q", "MolecularWeight": 146.14594, "Formula": "C5 H10 N2 O3"],
      "ARG": ["Type": AminoAcid.arg, "Residue": "Arginine", "Synonym": "R", "MolecularWeight": 174.20274, "Formula": "C6 H14 N4 O2"],
      "SER": ["Type": AminoAcid.ser, "Residue": "Serine", "Synonym": "S", "MolecularWeight": 105.09344, "Formula": "C3 H7 N1 O3"],
      "THR": ["Type": AminoAcid.thr, "Residue": "Threonine", "Synonym": "T", "MolecularWeight": 119.12034, "Formula": "C4 H9 N1 O3"],
      "SEC": ["Type": AminoAcid.sec, "Residue": "Selenocysteine", "Synonym": "U", "MolecularWeight": 168.053, "Formula": ""],
      "VAL": ["Type": AminoAcid.val, "Residue": "Valine", "Synonym": "V", "MolecularWeight": 117.14784, "Formula": "C5 H11 N1 O2"],
      "TRP": ["Type": AminoAcid.trp, "Residue": "Tryptophan", "Synonym": "W", "MolecularWeight": 204.23, "Formula": "C11 H12 N2 O2"],
      "TYR": ["Type": AminoAcid.tyr, "Residue": "Tyrosine", "Synonym": "Y", "MolecularWeight": 181.19, "Formula": "C9 H11 N1 O3"],
      "GLX": ["Type": AminoAcid.glx, "Residue": "GLU/GLN ambiguous", "Synonym": "Z", "MolecularWeight": 146.64, "Formula": "C5 H91/2 N11/2 O31/2"],
      "UNK": ["Type": AminoAcid.unk, "Residue": "Undetermined", "Synonym": "", "MolecularWeight": 128.16, "Formula": "C5 H6 N1 O3"]
  ]
  
  //http://www.unav.es/organica/umm/manuales/xsite/manual/examples/atomtypes.dat
  public static let residueDefinitions: Dictionary<String,Dictionary<String,Any>> =
    [
      "ALA+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "ALA+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N","CB","C"]],
      "ALA+CB" : [ "Element" : "C", "Type": "CH3E", "Bonded Atoms" : ["CA"]],
      "ALA+N" :  [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C","CA"]],
      "ALA+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "ALA+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "ALA+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ALA+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ALA+HB1" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ALA+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ALA+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "ARG+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "ARG+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N ","CB ","C"]],
      "ARG+CB" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CA","CG"]],
      "ARG+CD" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CG","NE"]],
      "ARG+CG" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CB","CD"]],
      "ARG+CZ" : [ "Element" : "C", "Type": "CH0", "Bonded Atoms" : ["NE"," NH1","NH2"]],
      "ARG+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C","CA"]],
      "ARG+NE" : [ "Element" : "N", "Type": "NH1S", "Bonded Atoms" : ["CD","CZ"]],
      "ARG+NH1" : [ "Element" : "N", "Type": "NC2", "Bonded Atoms" : ["CZ"]],
      "ARG+NH2" : [ "Element" : "N", "Type": "NC2", "Bonded Atoms" : ["CZ"]],
      "ARG+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "ARG+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "ARG+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ARG+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ARG+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ARG+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ARG+HD2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ARG+HD3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ARG+HE" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ARG+HG2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ARG+HG3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ARG+HH11" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ARG+HH12" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ARG+HH21" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ARG+HH22" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "ASN+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "ASN+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N","CB","C"]],
      "ASN+CB" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CA","CG"]],
      "ASN+CG" : [ "Element" : "C", "Type": "CH0", "Bonded Atoms" : ["CB","OD1","ND2"]],
      "ASN+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C","CA"]],
      "ASN+ND2" : [ "Element" : "N", "Type": "NH2", "Bonded Atoms" : ["CG"]],
      "ASN+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "ASN+OD1" : [ "Element" : "O", "Type": "OS", "Bonded Atoms" : ["CG"]],
      "ASN+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "ASN+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ASN+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ASN+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ASN+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ASN+HD21" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ASN+HD22" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "ASP+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "ASP+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N ","CB","C"]],
      "ASP+CB" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CA ","CG"]],
      "ASP+CG" : [ "Element" : "C", "Type": "CH0", "Bonded Atoms" : ["CB ","OD1","OD2"]],
      "ASP+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C ","CA"]],
      "ASP+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "ASP+OD1" : [ "Element" : "O", "Type": "OC", "Bonded Atoms" : ["CG"]],
      "ASP+OD2" : [ "Element" : "O", "Type": "OC", "Bonded Atoms" : ["CG"]],
      "ASP+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "ASP+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ASP+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ASP+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ASP+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "CYS+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "CYS+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N","CB ","C"]],
      "CYS+CB" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CA","SG"]],
      "CYS+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C","CA"]],
      "CYS+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "CYS+SG" : [ "Element" : "S", "Type": "SH1E", "Bonded Atoms" : ["CB"]],
      "CYS+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "CYS+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "CYS+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "CYS+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "CYS+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      
      
      "GLN+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "GLN+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N","CB","C"]],
      "GLN+CB" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CA ","CG"]],
      "GLN+CD" : [ "Element" : "C", "Type": "CH0", "Bonded Atoms" : ["CG","NE2","OE1"]],
      "GLN+CG" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CB","CD"]],
      "GLN+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C ","CA"]],
      "GLN+NE2" : [ "Element" : "N", "Type": "NH2", "Bonded Atoms" : ["CD"]],
      "GLN+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "GLN+OE1" : [ "Element" : "O", "Type": "OS", "Bonded Atoms" : ["CD"]],
      "GLN+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "GLN+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLN+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLN+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLN+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLN+HG2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLN+HG3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLN+HE21" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLN+HE22" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "GLU+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "GLU+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N","CB","C"]],
      "GLU+CB" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CA","CG"]],
      "GLU+CD" : [ "Element" : "C", "Type": "CH0", "Bonded Atoms" : ["CG","OE1 ","OE2"]],
      "GLU+CG" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CB ","CD"]],
      "GLU+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C","CA"]],
      "GLU+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "GLU+OE1" : [ "Element" : "O", "Type": "OC", "Bonded Atoms" : ["CD"]],
      "GLU+OE2" : [ "Element" : "O", "Type": "OC", "Bonded Atoms" : ["CD"]],
      "GLU+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "GLU+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLU+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLU+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLU+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLU+HG2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLU+HG3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "GLY+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "GLY+CA" : [ "Element" : "C", "Type": "CH2G", "Bonded Atoms" : ["N","C"]],
      "GLY+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C","CA"]],
      "GLY+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "GLY+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "GLY+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLY+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLY+HA2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLY+HA3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLY+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLY+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLY+HG2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "GLY+HG3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "HIS+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "HIS+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N","CB","C"]],
      "HIS+CB" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CA","CG"]],
      "HIS+CD2" : [ "Element" : "C", "Type": "CR1H", "Bonded Atoms" : ["CG ","NE2"]],
      "HIS+CE1" : [ "Element" : "C", "Type": "CRHH", "Bonded Atoms" : ["ND1","NE2"]],
      "HIS+CG" : [ "Element" : "C", "Type": "C5", "Bonded Atoms" : ["CB","CD2","ND1"]],
      "HIS+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C","CA"]],
      "HIS+ND1" : [ "Element" : "N", "Type": "NH1S", "Bonded Atoms" : ["CG ","CE1"]],
      "HIS+NE2" : [ "Element" : "N", "Type": "NH1S", "Bonded Atoms" : ["CD2","CE1"]],
      "HIS+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "HIS+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "HIS+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "HIS+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "HIS+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "HIS+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "HIS+HD1" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "HIS+HD2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "HIS+HE1" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      
      "HOH+O" : [ "Element" : "C", "Type": "HOH", "Bonded Atoms" : []],
      "HOH+H" : [ "Element" : "H", "Type": "HOH", "Bonded Atoms" : []],
      
      "ILE+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "ILE+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N ","CB ","C"]],
      "ILE+CB" : [ "Element" : "C", "Type": "CH1S", "Bonded Atoms" : ["CA","CG1","CG2"]],
      "ILE+CD1" : [ "Element" : "C", "Type": "CH3E", "Bonded Atoms" : ["CG1"]],
      "ILE+CG1" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CB ","CD1"]],
      "ILE+CG2" : [ "Element" : "C", "Type": "CH3E", "Bonded Atoms" : ["CB"]],
      "ILE+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C","CA"]],
      "ILE+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "ILE+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "ILE+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ILE+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ILE+HB" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ILE+HG12" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ILE+HG13" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ILE+HG21" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ILE+HG22" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ILE+HG23" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ILE+HD11" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ILE+HD12" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "ILE+HD13" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "LEU+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "LEU+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N ","CB","C"]],
      "LEU+CB" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CA ","CG"]],
      "LEU+CD1" : [ "Element" : "C", "Type": "CH3E", "Bonded Atoms" : ["CG"]],
      "LEU+CD2" : [ "Element" : "C", "Type": "CH3E", "Bonded Atoms" : ["CG"]],
      "LEU+CG" : [ "Element" : "C", "Type": "CH1S", "Bonded Atoms" : ["CB ","CD1","CD2"]],
      "LEU+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C ","CA"]],
      "LEU+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "LEU+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LEU+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LEU+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LEU+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LEU+HD11" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LEU+HD12" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LEU+HD13" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LEU+HD21" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LEU+HD22" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LEU+HD23" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LEU+HG" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "LYS+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA ","O"]],
      "LYS+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N ","CB","C"]],
      "LYS+CB" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CA ","CG"]],
      "LYS+CD" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CG ","CE"]],
      "LYS+CE" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CD ","NZ"]],
      "LYS+CG" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CB ","CD"]],
      "LYS+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C  ","CA"]],
      "LYS+NZ" : [ "Element" : "N", "Type": "NH3", "Bonded Atoms" : ["CE"]],
      "LYS+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "LYS+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "LYS+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LYS+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LYS+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LYS+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LYS+HG2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LYS+HG3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LYS+HD2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LYS+HD3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LYS+HE2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "LYS+HE3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "MET+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA ","O"]],
      "MET+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N","CB","C"]],
      "MET+CB" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CA ","CG"]],
      "MET+CE" : [ "Element" : "C", "Type": "CH3E", "Bonded Atoms" : ["SD"]],
      "MET+CG" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CB ","SD"]],
      "MET+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C","CA"]],
      "MET+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "MET+SD" : [ "Element" : "S", "Type": "SM", "Bonded Atoms" : ["CG ","CE"]],
      "MET+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "MET+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "PHE+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "PHE+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N","CB","C"]],
      "PHE+CB" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CA","CG"]],
      "PHE+CD1" : [ "Element" : "C", "Type": "CR1E", "Bonded Atoms" : ["CG ","CE1"]],
      "PHE+CD2" : [ "Element" : "C", "Type": "CR1E", "Bonded Atoms" : ["CG ","CE2"]],
      "PHE+CE1" : [ "Element" : "C", "Type": "CR1E", "Bonded Atoms" : ["CD1","CZ"]],
      "PHE+CE2" : [ "Element" : "C", "Type": "CR1E", "Bonded Atoms" : ["CD2 ","CZ"]],
      "PHE+CG" : [ "Element" : "C", "Type": "CF", "Bonded Atoms" : ["CB ","CD1","CD2"]],
      "PHE+CZ" : [ "Element" : "C", "Type": "CR1E", "Bonded Atoms" : ["CE1","CE2"]],
      "PHE+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C ","CA"]],
      "PHE+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "PHE+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "PHE+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "PHE+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "PHE+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "PHE+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "PHE+HD1" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "PHE+HD2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "PHE+HE1" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "PHE+HE2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "PHE+HZ" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "PRO+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "PRO+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N","CB","C"]],
      "PRO+CB" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CA","CG"]],
      "PRO+CD" : [ "Element" : "C", "Type": "CH2P", "Bonded Atoms" : ["N","CG"]],
      "PRO+CG" : [ "Element" : "C", "Type": "CH2P", "Bonded Atoms" : ["CB","CD"]],
      "PRO+N" : [ "Element" : "N", "Type": "N", "Bonded Atoms" : ["-C","CA","CD"]],
      "PRO+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "PRO+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "PRO+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "PRO+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "PRO+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "PRO+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "PRO+HD2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "PRO+HD3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "PRO+HG2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "PRO+HG3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "SER+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "SER+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N","CB","C"]],
      "SER+CB" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CA","OG"]],
      "SER+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C","CA"]],
      "SER+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "SER+OG" : [ "Element" : "O", "Type": "OH1", "Bonded Atoms" : ["CB"]],
      "SER+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "SER+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "SER+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "SER+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "SER+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "THR+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "THR+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N","CB","C"]],
      "THR+CB" : [ "Element" : "C", "Type": "CH1S", "Bonded Atoms" : ["CA","CG2","OG1"]],
      "THR+CG2" : [ "Element" : "C", "Type": "CH3E", "Bonded Atoms" : ["CB"]],
      "THR+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C","CA"]],
      "THR+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "THR+OG1" : [ "Element" : "O", "Type": "OH1", "Bonded Atoms" : ["CB"]],
      "THR+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "THR+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "THR+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "THR+HB" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "THR+HG1" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "THR+HG21" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "THR+HG22" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "THR+HG23" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "THR+HH2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "TRP+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "TRP+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N ","CB","C"]],
      "TRP+CB" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CA","CG"]],
      "TRP+CD1" : [ "Element" : "C", "Type": "CR1E", "Bonded Atoms" : ["CG ","NE1"]],
      "TRP+CD2" : [ "Element" : "C", "Type": "CW", "Bonded Atoms" : ["CG "," CE2","CE3"]],
      "TRP+CE2" : [ "Element" : "C", "Type": "CW", "Bonded Atoms" : ["CD2 ","CZ2","NE1"]],
      "TRP+CE3" : [ "Element" : "C", "Type": "CR1E", "Bonded Atoms" : ["CD2","CZ3"]],
      "TRP+CG" : [ "Element" : "C", "Type": "C5W", "Bonded Atoms" : ["CB ","CD1","CD2"]],
      "TRP+CH2" : [ "Element" : "C", "Type": "CR1W", "Bonded Atoms" : ["CZ2","CZ3"]],
      "TRP+CZ2" : [ "Element" : "C", "Type": "CR1W", "Bonded Atoms" : ["CE2","CH2"]],
      "TRP+CZ3" : [ "Element" : "C", "Type": "CR1E", "Bonded Atoms" : ["CE3","CH2"]],
      "TRP+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C","CA"]],
      "TRP+NE1" : [ "Element" : "N", "Type": "NH1S", "Bonded Atoms" : ["CD1 ","CE2"]],
      "TRP+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "TRP+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "TRP+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TRP+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TRP+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TRP+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TRP+HD1" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TRP+HE1" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TRP+HE3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TRP+HZ2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TRP+HZ3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TRP+HH2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "TYR+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "TYR+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N","CB","C"]],
      "TYR+CB" : [ "Element" : "C", "Type": "CH2E", "Bonded Atoms" : ["CA","CG"]],
      "TYR+CD1" : [ "Element" : "C", "Type": "CR1E", "Bonded Atoms" : ["CG","CE1"]],
      "TYR+CD2" : [ "Element" : "C", "Type": "CR1E", "Bonded Atoms" : ["CG","CE2"]],
      "TYR+CE1" : [ "Element" : "C", "Type": "CR1E", "Bonded Atoms" : ["CD1","CZ"]],
      "TYR+CE2" : [ "Element" : "C", "Type": "CR1E", "Bonded Atoms" : ["CD2","CZ"]],
      "TYR+CG" : [ "Element" : "C", "Type": "CY", "Bonded Atoms" : ["CB","CD1","CD2"]],
      "TYR+CZ" : [ "Element" : "C", "Type": "CY2", "Bonded Atoms" : ["CE1","CE2","OH"]],
      "TYR+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C","CA"]],
      "TYR+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "TYR+OH" : [ "Element" : "O", "Type": "OH1", "Bonded Atoms" : ["CZ"]],
      "TYR+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "TYR+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TYR+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TYR+HB2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TYR+HB3" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TYR+HD1" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TYR+HD2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TYR+HE1" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "TYR+HE2" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      
      "VAL+C" : [ "Element" : "C", "Type": "C", "Bonded Atoms" : ["CA","O"]],
      "VAL+CA" : [ "Element" : "C", "Type": "CH1E", "Bonded Atoms" : ["N","CB","C"]],
      "VAL+CB" : [ "Element" : "C", "Type": "CH1S", "Bonded Atoms" : ["CA","CG1","CG2"]],
      "VAL+CG1" : [ "Element" : "C", "Type": "CH3E", "Bonded Atoms" : ["CB"]],
      "VAL+CG2" : [ "Element" : "C", "Type": "CH3E", "Bonded Atoms" : ["CB"]],
      "VAL+N" : [ "Element" : "N", "Type": "NH1", "Bonded Atoms" : ["-C","CA"]],
      "VAL+O" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "VAL+OXT" : [ "Element" : "O", "Type": "O", "Bonded Atoms" : ["C"]],
      "VAL+H" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "VAL+HA" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "VAL+HB" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "VAL+HG11" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "VAL+HG12" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "VAL+HG13" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "VAL+HG21" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "VAL+HG22" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []],
      "VAL+HG23" : [ "Element" : "H", "Type": "H", "Bonded Atoms" : []]
  ]
  
  
}

