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

import Foundation
import simd
import SymmetryKit
import BinaryCodable

public class SKForceFieldSet: BinaryDecodable, BinaryEncodable
{
  private static var classVersionNumber: Int = 1

  public var displayName: String = "Default"
  public var referenceCount: Int = 0  // Legacy
  public var editable = true
  public var atomTypeList: [SKForceFieldType] = []
  
  public init(name: String, forceFieldSet: SKForceFieldSet, editable: Bool = true)
  {
    self.displayName = name
    self.atomTypeList = forceFieldSet.atomTypeList
    self.editable = editable
  }
  
  public subscript(index: String) -> SKForceFieldType?
  {
    return self.atomTypeList.first(where:  {$0.forceFieldStringIdentifier == index})
  }
  
  public func insert(_ item: SKForceFieldType, at index: Int)
  {
    self.atomTypeList.insert(item, at: index)
  }
  
  public func remove(sortIndices: IndexSet)
  {
    atomTypeList.remove(at: sortIndices)
  }
  
  public func uniqueName(for element: Int) -> String
  {
    let element: String = PredefinedElements.sharedInstance.elementSet[element].chemicalSymbol.capitalizeFirst
    for i in 1...65536
    {
      let newName: String = element + String(i)
      if !self.atomTypeList.contains(where: {$0.forceFieldStringIdentifier == newName})
      {
        return newName
      }
    }
    return "Xx"
  }
  
  
  public static func isDefaultForceFieldType(uniqueForceFieldName: String) -> Bool
  {
    return SKForceFieldSet.defaultForceField.contains(where: {$0.forceFieldStringIdentifier == uniqueForceFieldName})
  }
  
  public init()
  {
    self.editable = false
    
    self.atomTypeList = SKForceFieldSet.defaultForceField
  }
  
  // MARK: -
  // MARK: Binary Encodable support
  
  public func binaryEncode(to encoder: BinaryEncoder)
  {
    encoder.encode(SKForceFieldSet.classVersionNumber)
    encoder.encode(self.displayName)
    encoder.encode(self.editable)
    
    encoder.encode(atomTypeList)
  }
  
  // MARK: -
  // MARK: Binary Decodable support
  
  public required init(fromBinary decoder: BinaryDecoder) throws
  {
    let readVersionNumber: Int = try decoder.decode(Int.self)
    if readVersionNumber > SKForceFieldSet.classVersionNumber
    {
      throw BinaryDecodableError.invalidArchiveVersion
    }
    
    self.displayName  = try decoder.decode(String.self)
    self.referenceCount = 1
    self.editable  = try decoder.decode(Bool.self)
    self.atomTypeList = try decoder.decode([SKForceFieldType].self)
  }
  
  
  private static let defaultForceField: [SKForceFieldType] =
  [
    SKForceFieldType(forceFieldStringIdentifier: "H", atomicNumber:   1, sortIndex:   0, potentialParameters: SIMD2<Double>(7.64893,2.84642), mass: 1.00794, userDefinedRadius: 0.31), // DREIDING
    SKForceFieldType(forceFieldStringIdentifier: "He", atomicNumber:   2, sortIndex:   1, potentialParameters: SIMD2<Double>(10.9,2.64), mass: 4.002602, userDefinedRadius: 0.28), // Talu and Myers
    SKForceFieldType(forceFieldStringIdentifier: "Li", atomicNumber:   3, sortIndex:   2, potentialParameters: SIMD2<Double>(12.580415,2.183592758), mass: 6.9421, userDefinedRadius: 1.28), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Be", atomicNumber:   4, sortIndex:   3, potentialParameters: SIMD2<Double>(42.773411,2.445516981), mass: 9.012182, userDefinedRadius: 0.96), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "B", atomicNumber:   5, sortIndex:   4, potentialParameters: SIMD2<Double>(47.8058,3.58141), mass: 10.881, userDefinedRadius: 0.84), // DREIDING
    SKForceFieldType(forceFieldStringIdentifier: "C", atomicNumber:   6, sortIndex:   5, potentialParameters: SIMD2<Double>(47.8562, 3.47299), mass: 12.0107, userDefinedRadius: 0.76), // DREIDING
    SKForceFieldType(forceFieldStringIdentifier: "N", atomicNumber:   7, sortIndex:   6, potentialParameters: SIMD2<Double>(38.9492,3.26256), mass: 14.0067, userDefinedRadius: 0.71), // DREIDING
    SKForceFieldType(forceFieldStringIdentifier: "O", atomicNumber:   8, sortIndex:   7, potentialParameters: SIMD2<Double>(53.0, 3.30), mass: 15.9994, userDefinedRadius: 0.66), // TraPPE-ZEO
    SKForceFieldType(forceFieldStringIdentifier: "F", atomicNumber:   9, sortIndex:   8, potentialParameters: SIMD2<Double>(36.4834,3.0932), mass: 18.9984032, userDefinedRadius: 0.57), // DREIDING
    SKForceFieldType(forceFieldStringIdentifier: "Ne", atomicNumber:  10, sortIndex:   9, potentialParameters: SIMD2<Double>(21.1350972,2.889184543), mass: 20.1797, userDefinedRadius: 0.58), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Na", atomicNumber:  11, sortIndex:  10, potentialParameters: SIMD2<Double>(15.096498,2.657550876), mass: 22.98976928, userDefinedRadius: 1.66), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Mg", atomicNumber:  12, sortIndex:  11, potentialParameters: SIMD2<Double>(55.8570426,2.691405028), mass: 24.305, userDefinedRadius: 1.41), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Al", atomicNumber:  13, sortIndex:  12, potentialParameters: SIMD2<Double>(22.6183,2.30), mass: 26.9815386, userDefinedRadius: 1.21), // chosen same as Si from TraPPE-ZEO but with epsilon ratio from DREIDING (4.39/4.27)*22.0 = 22.6183
    SKForceFieldType(forceFieldStringIdentifier: "Si", atomicNumber:  14, sortIndex:  13, potentialParameters: SIMD2<Double>(22.0,2.30), mass: 28.0855, userDefinedRadius: 1.11), // TraPPE-ZEO
    SKForceFieldType(forceFieldStringIdentifier: "P", atomicNumber:  15, sortIndex:  14, potentialParameters: SIMD2<Double>(161.03, 3.69723), mass: 30.973762, userDefinedRadius: 1.07), // DREIDING
    SKForceFieldType(forceFieldStringIdentifier: "S", atomicNumber:  16, sortIndex:  15, potentialParameters: SIMD2<Double>(173.107,3.59032), mass: 32.065, userDefinedRadius: 1.05), // DREIDING
    SKForceFieldType(forceFieldStringIdentifier: "Cl", atomicNumber:  17, sortIndex:  16, potentialParameters: SIMD2<Double>(142.562, 3.51932), mass: 35.453, userDefinedRadius: 1.02), // DREIDING
    SKForceFieldType(forceFieldStringIdentifier: "Ar", atomicNumber:  18, sortIndex:  17, potentialParameters: SIMD2<Double>(93.095071, 3.445996242), mass: 39.948, userDefinedRadius: 1.06), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "K", atomicNumber:  19, sortIndex:  18, potentialParameters: SIMD2<Double>(17.612581, 3.396105914), mass: 39.0983, userDefinedRadius: 2.03), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Ca", atomicNumber:  20, sortIndex:  19, potentialParameters: SIMD2<Double>(119.7655508,3.028164743), mass: 40.078, userDefinedRadius: 1.76), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Sc", atomicNumber:  21, sortIndex:  20, potentialParameters: SIMD2<Double>(9.5611154,2.935511276), mass: 44.955912, userDefinedRadius: 1.7), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Ti", atomicNumber:  22, sortIndex:  21, potentialParameters: SIMD2<Double>(8.5546822,2.82860343), mass: 47.867, userDefinedRadius: 1.6), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "V", atomicNumber:  23, sortIndex:  22, potentialParameters: SIMD2<Double>(8.0514656,2.80098557), mass: 50.9415, userDefinedRadius: 1.53), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Cr", atomicNumber:  24, sortIndex:  23, potentialParameters: SIMD2<Double>(7.548249,2.693186825), mass: 51.9961, userDefinedRadius: 1.39), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Mn", atomicNumber:  25, sortIndex:  24, potentialParameters: SIMD2<Double>(6.5418158,2.637951104), mass: 54.939045, userDefinedRadius: 1.39), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Fe", atomicNumber:  26, sortIndex:  25, potentialParameters: SIMD2<Double>(6.5418158,2.594297067), mass: 55.845, userDefinedRadius: 1.32), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Co", atomicNumber:  27, sortIndex:  26, potentialParameters: SIMD2<Double>(7.0450324,2.558661118), mass: 58.933195, userDefinedRadius: 1.26), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Ni", atomicNumber:  28, sortIndex:  27, potentialParameters: SIMD2<Double>(7.548249,2.524806967), mass: 58.6934, userDefinedRadius: 1.24), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Cu", atomicNumber:  29, sortIndex:  28, potentialParameters: SIMD2<Double>(2.516083,3.11369102), mass: 63.546, userDefinedRadius: 1.32), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Zn", atomicNumber:  30, sortIndex:  29, potentialParameters: SIMD2<Double>(62.3988584, 2.461553158), mass: 65.38, userDefinedRadius: 1.22), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Ga", atomicNumber:  31, sortIndex:  30, potentialParameters: SIMD2<Double>(208.834889,3.904809082), mass: 69.723, userDefinedRadius: 1.22), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Ge", atomicNumber:  32, sortIndex:  31, potentialParameters: SIMD2<Double>(190.7190914, 3.813046514), mass: 72.64, userDefinedRadius: 1.2), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "As", atomicNumber:  33, sortIndex:  32, potentialParameters: SIMD2<Double>(155.4939294, 3.768501578), mass: 74.9216, userDefinedRadius: 1.19), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Se", atomicNumber:  34, sortIndex:  33, potentialParameters: SIMD2<Double>(146.4360306, 3.746229110), mass: 78.96, userDefinedRadius: 1.2), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Br", atomicNumber:  35, sortIndex:  34, potentialParameters: SIMD2<Double>(186.191,3.51905), mass: 79.904, userDefinedRadius: 1.2), // DREIDING
    SKForceFieldType(forceFieldStringIdentifier: "Kr", atomicNumber:  36, sortIndex:  35, potentialParameters: SIMD2<Double>(110.707652, 3.689211592), mass: 83.798, userDefinedRadius: 1.16), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Rb", atomicNumber:  37, sortIndex:  36, potentialParameters: SIMD2<Double>(20.128664, 3.665157326), mass: 85.4678, userDefinedRadius: 2.2), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Sr", atomicNumber:  38, sortIndex:  37, potentialParameters: SIMD2<Double>(118.255901, 3.243762233), mass: 87.62, userDefinedRadius: 1.95), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Y", atomicNumber:  39, sortIndex:  38, potentialParameters: SIMD2<Double>(36.2315952, 2.980056212), mass: 88.90585, userDefinedRadius: 1.9), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Zr", atomicNumber:  40, sortIndex:  39, potentialParameters: SIMD2<Double>(34.7219454,2.783167595), mass: 91.224, userDefinedRadius: 1.75), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Nb", atomicNumber:  41, sortIndex:  40, potentialParameters: SIMD2<Double>(29.6897794, 2.819694443), mass: 92.90638, userDefinedRadius: 1.64), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Mo", atomicNumber:  42, sortIndex:  41, potentialParameters: SIMD2<Double>(28.1801296, 2.719022888), mass: 95.96, userDefinedRadius: 1.54), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Tc", atomicNumber:  43, sortIndex:  42, potentialParameters: SIMD2<Double>(24.1543968, 2.670914357), mass: 98, userDefinedRadius: 1.47), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Ru", atomicNumber:  44, sortIndex:  43, potentialParameters: SIMD2<Double>(28.1801296, 2.639732902), mass: 101.07, userDefinedRadius: 1.46), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Rh", atomicNumber:  45, sortIndex:  44, potentialParameters: SIMD2<Double>(26.6704798, 2.609442345), mass: 102.59055, userDefinedRadius: 1.42), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Pd", atomicNumber:  46, sortIndex:  45, potentialParameters: SIMD2<Double>(24.1543968, 2.582715384), mass: 106.42, userDefinedRadius: 1.39), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Ag", atomicNumber:  47, sortIndex:  46, potentialParameters: SIMD2<Double>(18.1157976,2.804549165), mass: 107.8682, userDefinedRadius: 1.45), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Cd", atomicNumber:  48, sortIndex:  47, potentialParameters: SIMD2<Double>(114.7333848,2.537279549), mass: 112.411, userDefinedRadius: 1.44), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "In", atomicNumber:  49, sortIndex:  48, potentialParameters: SIMD2<Double>(301.4267434,3.976080979), mass: 114.818, userDefinedRadius: 1.42), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Sn", atomicNumber:  50, sortIndex:  49, potentialParameters: SIMD2<Double>(285.3238122, 3.91282717), mass: 118.71, userDefinedRadius: 1.39), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Sb", atomicNumber:  51, sortIndex:  50, potentialParameters: SIMD2<Double>(225.9442534, 3.937772334), mass: 121.76, userDefinedRadius: 1.39), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Te", atomicNumber:  52, sortIndex:  51, potentialParameters: SIMD2<Double>(200.2802068, 3.98231727), mass: 127.6, userDefinedRadius: 1.38), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "I", atomicNumber:  53, sortIndex:  52, potentialParameters: SIMD2<Double>(170.5904274, 4.009044232), mass: 126.90447, userDefinedRadius: 1.39), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Xe", atomicNumber:  54, sortIndex:  53, potentialParameters: SIMD2<Double>(167.0679112, 3.923517955), mass: 131.293, userDefinedRadius: 1.4), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Cs", atomicNumber:  55, sortIndex:  54, potentialParameters: SIMD2<Double>(22.644747, 4.02418951), mass: 132.9054519, userDefinedRadius: 2.44), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Ba", atomicNumber:  56, sortIndex:  55, potentialParameters: SIMD2<Double>(183.1708424, 3.298997953), mass: 137.327, userDefinedRadius: 2.15), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "La", atomicNumber:  57, sortIndex:  56, potentialParameters: SIMD2<Double>(8.5546822, 3.137745285), mass: 138.90547, userDefinedRadius: 2.07), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Ce", atomicNumber:  58, sortIndex:  57, potentialParameters: SIMD2<Double>(6.5418158, 3.168035842), mass: 140.116, userDefinedRadius: 2.04), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Pr", atomicNumber:  59, sortIndex:  58, potentialParameters: SIMD2<Double>(5.032166, 3.212580778), mass: 140.90765, userDefinedRadius: 2.03), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Nd", atomicNumber:  60, sortIndex:  59, potentialParameters: SIMD2<Double>(5.032166, 3.184962917), mass: 144.242, userDefinedRadius: 2.01), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Pm", atomicNumber:  61, sortIndex:  60, potentialParameters: SIMD2<Double>(4.5289494, 3.160017753), mass: 145, userDefinedRadius: 1.99), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Sm", atomicNumber:  62, sortIndex:  61, potentialParameters: SIMD2<Double>(4.0257328, 3.135963488), mass: 150.36, userDefinedRadius: 1.98), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Eu", atomicNumber:  63, sortIndex:  62, potentialParameters: SIMD2<Double>(4.0257328, 3.111909222), mass: 151.964, userDefinedRadius: 1.98), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Gd", atomicNumber:  64, sortIndex:  63, potentialParameters: SIMD2<Double>(4.5289494, 3.000546883), mass: 157.25, userDefinedRadius: 1.96), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Tb", atomicNumber:  65, sortIndex:  64, potentialParameters: SIMD2<Double>(3.5225162, 3.074491476), mass: 158.92535, userDefinedRadius: 1.94), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Dy", atomicNumber:  66, sortIndex:  65, potentialParameters: SIMD2<Double>(3.5225162, 3.054000806), mass: 162.5, userDefinedRadius: 1.92), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Ho", atomicNumber:  67, sortIndex:  66, potentialParameters: SIMD2<Double>(3.5225162, 3.03707373), mass: 164.93032, userDefinedRadius: 1.92), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Er", atomicNumber:  68, sortIndex:  67, potentialParameters: SIMD2<Double>(3.5225162, 3.021037553), mass: 167.259, userDefinedRadius: 1.89), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Tm", atomicNumber:  69, sortIndex:  68, potentialParameters: SIMD2<Double>(3.0192996, 3.005892275), mass: 168.93421, userDefinedRadius: 1.9), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Yb", atomicNumber:  70, sortIndex:  69, potentialParameters: SIMD2<Double>(114.7333848, 2.988965199), mass: 173.054, userDefinedRadius: 1.87), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Lu", atomicNumber:  71, sortIndex:  70, potentialParameters: SIMD2<Double>(20.6318806, 3.242871334), mass: 174.9668, userDefinedRadius: 1.87), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Hf", atomicNumber:  72, sortIndex:  71, potentialParameters: SIMD2<Double>(36.2315952, 2.798312874), mass: 178.49, userDefinedRadius: 1.75), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Ta", atomicNumber:  73, sortIndex:  72, potentialParameters: SIMD2<Double>(40.7605446, 2.824148937), mass: 180.94788, userDefinedRadius: 1.7), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "W", atomicNumber:  74, sortIndex:  73, potentialParameters: SIMD2<Double>(33.7155122, 2.734168166), mass: 183.84, userDefinedRadius: 1.62), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Re", atomicNumber:  75, sortIndex:  74, potentialParameters: SIMD2<Double>(33.2122956, 2.631714813), mass: 186.207, userDefinedRadius: 1.51), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Os", atomicNumber:  76, sortIndex:  75, potentialParameters: SIMD2<Double>(18.6190142, 2.779604001), mass: 190.23, userDefinedRadius: 1.44), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Ir", atomicNumber:  77, sortIndex:  76, potentialParameters: SIMD2<Double>(36.7348118, 2.53015236), mass: 192.217, userDefinedRadius: 1.41), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Pt", atomicNumber:  78, sortIndex:  77, potentialParameters: SIMD2<Double>(40.257328, 2.45353507), mass: 195.084, userDefinedRadius: 1.36), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Au", atomicNumber:  79, sortIndex:  78, potentialParameters: SIMD2<Double>(19.6254474, 2.933729479), mass: 196.966569, userDefinedRadius: 1.36), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Hg", atomicNumber:  80, sortIndex:  79, potentialParameters: SIMD2<Double>(193.738391, 2.409881033), mass: 200.59, userDefinedRadius: 1.32), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Tl", atomicNumber:  81, sortIndex:  80, potentialParameters: SIMD2<Double>(342.187288, 3.872736728), mass: 204.3833, userDefinedRadius: 1.45), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Pb", atomicNumber:  82, sortIndex:  81, potentialParameters: SIMD2<Double>(333.6326058, 3.828191792), mass: 207.2, userDefinedRadius: 1.46), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Bi", atomicNumber:  83, sortIndex:  82, potentialParameters: SIMD2<Double>(260.6661988, 3.893227398), mass: 208.9804, userDefinedRadius: 1.48), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Po", atomicNumber:  84, sortIndex:  83, potentialParameters: SIMD2<Double>(163.545395, 4.195242064), mass: 210, userDefinedRadius: 1.4), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "At", atomicNumber:  85, sortIndex:  84, potentialParameters: SIMD2<Double>(142.9135144, 4.231768911), mass: 210.8, userDefinedRadius: 1.5), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Rn", atomicNumber:  86, sortIndex:  85, potentialParameters: SIMD2<Double>(124.7977168, 4.245132392), mass: 222, userDefinedRadius: 1.5), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Fr", atomicNumber:  87, sortIndex:  86, potentialParameters: SIMD2<Double>(25.16083, 4.365403719), mass: 223, userDefinedRadius: 2.6), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Ra", atomicNumber:  88, sortIndex:  87, potentialParameters: SIMD2<Double>(203.2995064, 3.275834587), mass: 226, userDefinedRadius: 2.21), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Ac", atomicNumber:  89, sortIndex:  88, potentialParameters: SIMD2<Double>(16.6061478, 3.098545742), mass: 227, userDefinedRadius: 2.15), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Th", atomicNumber:  90, sortIndex:  89, potentialParameters: SIMD2<Double>(13.0836316, 3.025492047), mass: 232.03806, userDefinedRadius: 2.06), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Pa", atomicNumber:  91, sortIndex:  90, potentialParameters: SIMD2<Double>(11.0707652, 3.050437211), mass: 231.03588, userDefinedRadius: 2.0), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "U", atomicNumber:  92, sortIndex:  91, potentialParameters: SIMD2<Double>(11.0707652, 3.024601148), mass: 238.02891, userDefinedRadius: 1.96), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Np", atomicNumber:  93, sortIndex:  92, potentialParameters: SIMD2<Double>(9.5611154, 3.050437211), mass: 237, userDefinedRadius: 1.9), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Pu", atomicNumber:  94, sortIndex:  93, potentialParameters: SIMD2<Double>(8.0514656, 3.050437211), mass: 244, userDefinedRadius: 1.87), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Am", atomicNumber:  95, sortIndex:  94, potentialParameters: SIMD2<Double>(7.0450324, 3.012128566), mass: 243, userDefinedRadius: 1.8), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Cm", atomicNumber:  96, sortIndex:  95, potentialParameters: SIMD2<Double>(6.5418158, 2.963129137), mass: 247, userDefinedRadius: 1.69), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Bk", atomicNumber:  97, sortIndex:  96, potentialParameters: SIMD2<Double>(6.5418158, 2.97471082), mass: 247, userDefinedRadius: 1.71), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Cf", atomicNumber:  98, sortIndex:  97, potentialParameters: SIMD2<Double>(6.5418158, 2.951547453), mass: 251, userDefinedRadius: 1.71), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Es", atomicNumber:  99, sortIndex:  98, potentialParameters: SIMD2<Double>(6.0385992, 2.939074871), mass: 252, userDefinedRadius: 1.68), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Fm", atomicNumber: 100, sortIndex:  99, potentialParameters: SIMD2<Double>(6.0385992, 2.927493188), mass: 257, userDefinedRadius: 1.70), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Md", atomicNumber: 101, sortIndex: 100, potentialParameters: SIMD2<Double>(5.53538260, 2.916802403), mass: 258, userDefinedRadius: 1.76), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "No", atomicNumber: 102, sortIndex: 101, potentialParameters: SIMD2<Double>(5.5353826, 2.893639037), mass: 259, userDefinedRadius: 1.79), // UFF
    SKForceFieldType(forceFieldStringIdentifier: "Lr", atomicNumber: 103, sortIndex: 102, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 262, userDefinedRadius: 1.64), // same as "No"
    SKForceFieldType(forceFieldStringIdentifier: "Rf", atomicNumber: 104, sortIndex: 103, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 261, userDefinedRadius: 1.57), // same as "No"
    SKForceFieldType(forceFieldStringIdentifier: "Db", atomicNumber: 105, sortIndex: 104, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 268, userDefinedRadius: 1.49), // same as "No"
    SKForceFieldType(forceFieldStringIdentifier: "Sg", atomicNumber: 106, sortIndex: 105, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 269, userDefinedRadius: 1.43), // same as "No"
    SKForceFieldType(forceFieldStringIdentifier: "Bh", atomicNumber: 107, sortIndex: 106, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 270, userDefinedRadius: 1.41), // same as "No"
    SKForceFieldType(forceFieldStringIdentifier: "Hs", atomicNumber: 108, sortIndex: 107, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 269, userDefinedRadius: 1.34), // same as "No"
    SKForceFieldType(forceFieldStringIdentifier: "Mt", atomicNumber: 109, sortIndex: 108, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 278, userDefinedRadius: 1.29), // same as "No"
    SKForceFieldType(forceFieldStringIdentifier: "Ds", atomicNumber: 110, sortIndex: 109, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 281, userDefinedRadius: 1.28), // same as "No"
    SKForceFieldType(forceFieldStringIdentifier: "Rg", atomicNumber: 111, sortIndex: 110, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 281, userDefinedRadius: 1.21), // same as "No"
    SKForceFieldType(forceFieldStringIdentifier: "Cn", atomicNumber: 112, sortIndex: 111, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 285, userDefinedRadius: 1.22), // same as "No"
    SKForceFieldType(forceFieldStringIdentifier: "Uut", atomicNumber: 113, sortIndex: 112, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 286, userDefinedRadius: 1.36), // same as "No"
    SKForceFieldType(forceFieldStringIdentifier: "Uuq", atomicNumber: 114, sortIndex: 113, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 289, userDefinedRadius: 1.43), // same as "No"
    SKForceFieldType(forceFieldStringIdentifier: "Uup", atomicNumber: 115, sortIndex: 114, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 288, userDefinedRadius: 1.62), // same as "No"
    SKForceFieldType(forceFieldStringIdentifier: "Uuh", atomicNumber: 116, sortIndex: 115, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 293, userDefinedRadius: 1.75), // same as "No"
    SKForceFieldType(forceFieldStringIdentifier: "Uus", atomicNumber: 117, sortIndex: 116, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 294, userDefinedRadius: 1.65), // same as "No"
    SKForceFieldType(forceFieldStringIdentifier: "Uuo", atomicNumber: 118, sortIndex: 117, potentialParameters: SIMD2<Double>(5.5353826, 2.882948252), mass: 294, userDefinedRadius: 1.57)  // same as "No"
  ]
  
}
