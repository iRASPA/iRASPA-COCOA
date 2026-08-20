/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 *************************************************************************************************************/

import Foundation
import simd
import MathKit

public enum SKCIFSymmetryOperationParserError: Error
{
  case invalidFormat(String)
  case invalidCoefficient(String)
}

/// Parses CIF symmetry strings such as `'+x,+y,+z'` or `'1/2+x,1/2+y,+z'` into `SKSeitzIntegerMatrix`.
public enum SKCIFSymmetryOperationParser
{
  public static func parse(_ xyz: String) throws -> SKSeitzIntegerMatrix
  {
    let trimmed: String = xyz.trimmingCharacters(in: CharacterSet(charactersIn: "'\" "))
    let components: [String] = trimmed.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
    
    guard components.count == 3 else
    {
      throw SKCIFSymmetryOperationParserError.invalidFormat(xyz)
    }
    
    var column0: SIMD3<Int32> = SIMD3<Int32>(0, 0, 0)
    var column1: SIMD3<Int32> = SIMD3<Int32>(0, 0, 0)
    var column2: SIMD3<Int32> = SIMD3<Int32>(0, 0, 0)
    var translation: SIMD3<Double> = SIMD3<Double>(0, 0, 0)
    
    for outputIndex in 0..<3
    {
      let (coefficients, componentTranslation) = try parseComponent(components[outputIndex])
      column0[outputIndex] = coefficients.x
      column1[outputIndex] = coefficients.y
      column2[outputIndex] = coefficients.z
      translation[outputIndex] = componentTranslation
    }
    
    let rotation: SKRotationMatrix = SKRotationMatrix([column0, column1, column2])
    return SKSeitzIntegerMatrix(rotation: rotation, translation: fract(translation))
  }
  
  public static func parseOperations(_ xyzStrings: [String]) throws -> [SKSeitzIntegerMatrix]
  {
    var operations: [SKSeitzIntegerMatrix] = []
    operations.reserveCapacity(xyzStrings.count)
    for xyz in xyzStrings
    {
      operations.append(try parse(xyz))
    }
    return operations
  }
  
  private static func parseComponent(_ input: String) throws -> (SIMD3<Int32>, Double)
  {
    var coefficients: SIMD3<Int32> = SIMD3<Int32>(0, 0, 0)
    var translation: Double = 0.0
    
    var index: String.Index = input.startIndex
    let end: String.Index = input.endIndex
    
    while index < end
    {
      var sign: Double = 1.0
      
      if input[index] == "+"
      {
        index = input.index(after: index)
      }
      else if input[index] == "-"
      {
        sign = -1.0
        index = input.index(after: index)
      }
      
      var hasNumber: Bool = false
      var numerator: Double = 0.0
      var denominator: Double = 1.0
      
      while index < end && input[index].isNumber
      {
        hasNumber = true
        numerator = numerator * 10.0 + Double(input[index].wholeNumberValue ?? 0)
        index = input.index(after: index)
      }
      
      if index < end && input[index] == "/"
      {
        index = input.index(after: index)
        denominator = 0.0
        while index < end && input[index].isNumber
        {
          denominator = denominator * 10.0 + Double(input[index].wholeNumberValue ?? 0)
          index = input.index(after: index)
        }
        guard denominator != 0.0 else
        {
          throw SKCIFSymmetryOperationParserError.invalidFormat(input)
        }
      }
      
      let value: Double = sign * (hasNumber ? numerator / denominator : 1.0)
      
      if index < end
      {
        let axis: Character = Character(input[index].lowercased())
        if axis == "x" || axis == "y" || axis == "z"
        {
          guard abs(value) == 1.0 else
          {
            throw SKCIFSymmetryOperationParserError.invalidCoefficient(input)
          }
          
          switch axis
          {
          case "x":
            coefficients.x += Int32(value)
          case "y":
            coefficients.y += Int32(value)
          case "z":
            coefficients.z += Int32(value)
          default:
            break
          }
          index = input.index(after: index)
        }
        else if hasNumber
        {
          translation += value
        }
        else
        {
          throw SKCIFSymmetryOperationParserError.invalidFormat(input)
        }
      }
      else if hasNumber
      {
        translation += value
      }
      else
      {
        throw SKCIFSymmetryOperationParserError.invalidFormat(input)
      }
    }
    
    return (coefficients, translation)
  }
}
