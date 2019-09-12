//
//  HermiteNormalForm.swift


import Foundation

extension IntegerMatrix
{
  public func HermiteNormalForm() ->(IntegerMatrix, IntegerMatrix,[Int])
  {
    // Create larger matrix
    var Apad: IntegerMatrix = IntegerMatrix(numberOfRows: self.numberOfRows + 2, numberOfColumns: self.numberOfColumns + 2)
    Apad[0, 0] = 1
    Apad[self.numberOfRows + 1, self.numberOfColumns + 1] = 1
    Apad.assignSubmatrix(startRow: 1, startColumn: 1, integerMatrix: self)
    
    var rp: [Int] = [0]
    var r: Int = 0
    // Create transformation matrix
    var QQ: IntegerMatrix = IntegerMatrix.identity(size: self.numberOfRows + 2)
    var CC: IntegerMatrix = IntegerMatrix.identity(size: self.numberOfRows + 2)
    
    // Begin computing the HNF
    for j in 1..<Apad.numberOfColumns
    {
      // Search for next rank increase
      var found: Bool = false
      for k in (r + 1)..<Apad.numberOfRows
      {
        if Apad[r, rp[r]] * Apad[k, j] != Apad[r, j] * Apad[k, rp[r]]
        {
          found = true
        }
      }
     
      // Found something?
      if found
      {
        // Increase rank
        rp.append(j)
        r += 1
        
        // Do column reduction
        let columnReduction: (Q: IntegerMatrix, C: IntegerMatrix, Apad: IntegerMatrix) = ColumnReduction(A1: Apad, col_1: rp[r - 1], col_2: rp[r], row_start: r - 1)
        Apad = columnReduction.Apad
        
        // Update CC
        for i in (r + 1)..<columnReduction.C.numberOfColumns
        {
          CC[r, i] = columnReduction.C[r, i]
        }
        // Update QQ to QQ * C^{-1}
        for j in (r + 1)..<columnReduction.C.numberOfColumns
        {
          if columnReduction.C[r, j] != 0
          {
            for i in 0..<QQ.numberOfRows
            {
              QQ[i, j] -= columnReduction.C[r, j] * QQ[i, r]
            }
          }
        }
        // Update QQ to C * QQ
        for i in (r + 1)..<columnReduction.C.numberOfColumns
        {
          if columnReduction.C[r, i] != 0
          {
            for j in 0..<QQ.numberOfRows
            {
              QQ[r, j] += columnReduction.C[r, i] * QQ[i, j]
            }
          }
        }
        // Update QQ to Q * QQ
        for i in 0..<QQ.numberOfRows
        {
          if i != r - 1 && i != r
          {
            for j in 0..<QQ.numberOfColumns
            {
              QQ[i, j] = QQ[i, j] + columnReduction.Q[i, r - 1] * QQ[r - 1, j] + columnReduction.Q[i, r] * QQ[r, j]
            }
          }
        }
        let a = columnReduction.Q[r - 1, r - 1]
        let b = columnReduction.Q[r - 1, r    ]
        let c = columnReduction.Q[r,     r - 1]
        let d = columnReduction.Q[r,     r    ]
        for j in 0..<QQ.numberOfColumns
        {
          let temp1: Int = a * QQ[r - 1, j] + b * QQ[r, j]
          let temp2: Int = c * QQ[r - 1, j] + d * QQ[r, j]
          QQ[r - 1, j] = temp1
          QQ[r, j] = temp2
        }
      }
    }
    // Compute the transformation matrix
    let T: IntegerMatrix = QQ * CC
    
    
    // Extract the necessary matrices
    var TT = IntegerMatrix(numberOfRows: self.numberOfRows, numberOfColumns: self.numberOfRows)
   
    if r>1
    {
      TT.assignSubmatrix(startRow: 0, startColumn: 0, integerMatrix: T.submatrix(startRow: 1, startColumn: 1, numberOfRows: r - 2, numberOfColumns: self.numberOfRows))
      TT.assignSubmatrix(startRow: r - 2, startColumn: 0, integerMatrix: T.submatrix(startRow: r - 1, startColumn: 1, numberOfRows: self.numberOfRows - r + 2, numberOfColumns: self.numberOfRows))
    }
    let AA: IntegerMatrix = IntegerMatrix(matrix: Apad.submatrix(startRow: 1, startColumn: 1, numberOfRows: self.numberOfRows, numberOfColumns: self.numberOfColumns))
    // Extract rank profile
    rp = Array(rp[1..<r])
    for i in 0..<rp.count
    {
      rp[i] -= 1
    }
    return (TT, AA, rp)
  }
  
  func Algorithm_6_14(a: Int, b: Int, N: Int, Nfact: [Int]) -> Any
  {
  
    var k: Int = 0
    var HNF_C_Iwaniec: Int = IntegerMatrix.HNF_C_Iwaniec
    
    while(true)
    {
      if N == 2
      {
        k = 1
      }
      else
      {
        let temp: Double = log(Double(N))/log(2.0)
        k = Int(Double(HNF_C_Iwaniec) * temp * (pow(log(temp),2)))
      }
      
      // Prepare B
      var B: [Bool] = [Bool](repeating: true, count: k+1)
      
      // Compute residues
      let t: Int = Nfact.count
      var ai: [Int] = [Int](repeating: 0, count: t)
      var bi: [Int] = [Int](repeating: 0, count: t)
     
      for i in 0..<t
      {
        ai[i] = Int.modulo(a: a, b: Nfact[i])
        bi[i] = Int.modulo(a: b, b: Nfact[i])
      }
      
      // Compute extended GCDs
      var xi: [Int] = [Int](repeating: 0, count: t)
      for i in 0..<t
      {
        let extendedGCD: (gi: Int, xi: Int, yi: Int) = Int.extendedGreatestCommonDivisor(a: bi[i], b: Nfact[i])
        xi[i] = extendedGCD.xi
        if 1 < extendedGCD.gi && extendedGCD.gi < Nfact[i]
        {
          return Array(Nfact[0..<i]) + Array([extendedGCD.gi, Nfact[i] / extendedGCD.gi]) + Array(Nfact[i+1..<t])
        }
      }
      
      // Do sieving
      for i in 0..<t
      {
        if bi[i] != 0
        {
          let si: Int =  Int.modulo(a: -ai[i] * xi[i], b: Nfact[i])
          var idx: Int = si
          while idx <= k
          {
            B[idx] = false
            idx += Nfact[i]
          }
        }
      }
      // Find result
      for c in 0..<(k+1)
      {
        if B[c] == true
        {
          for i in 0..<t
          {
            let gi: Int = Int.greatestCommonDivisor(a: ai[i] + c * bi[i], b: Nfact[i])
            if gi > 1
            {
              return Array(Nfact[0..<i]) + Array([gi, Nfact[i] / gi]) + Array(Nfact[(i+1)..<t])
            }
          }
          return c
        }
      }
      HNF_C_Iwaniec *= 2
    }
  }
  

  
  private func RemovedDuplicates(array: [Int]) -> [Int]
  {
    var res: [Int] = []
  
    if array.count > 0
    {
      res.append(array[0])
      for i in 1..<array.count
      {
        if array[i] != res[res.count-1]
        {
          res.append(array[i])
        }
      }
    }
    return res
  }
  
  private func Conditioning(A: IntegerMatrix, col_1: Int, col_2: Int, row_start: Int) -> ([Int], [Int])
  {
   
    let k: Int = A.numberOfRows - row_start - 2
    let d11 = A[row_start, col_1]
    let d12 = A[row_start, col_2]
    var d21 = A[row_start + 1, col_1]
    var d22 = A[row_start + 1, col_2]
    var ci = [Int](repeating: 0, count : k)
    if d11 * d22 == d12 * d21
    {
      for s in (row_start + 2)..<A.numberOfRows
      {
        if d11 * A[s, col_2] != d12 * A[s, col_1]
        {
          ci[s - row_start - 2] = 1
          d21 += A[s, col_1]
          d22 += A[s, col_2]
          break
        }
      }
    }
    
    // We now have  det( d11 & d12 \\ d21 & d22 ) \neq 0.
    if d11 > 1
    {
      // Perform a modified Algorithm 6.15:
      var F: [Int] = [d11]
      var ahat: Int = d21
      var i: Int = 0
      var has_gi: Bool = false
      var neg = false
      
      var biprime: Int = 0
      var ahatprime: Int = 0
      var bi: Int = 0
      var bip: Int = 0
      while i < k
      {
        if !has_gi
        {
          bi = A[row_start + 2 + i, col_1]
          bip = A[row_start + 2 + i, col_2]
          let gi = Int.greatestCommonDivisor(a: ahat, b: bi)
          if gi == 0
          {
            i += 1
            continue
          }
          ahatprime = Int.modulo(a: (ahat / gi), b: d11)
          biprime = Int.modulo(a: (bi / gi), b: d11)
          neg = false
          if (d11 * d22 - d12 * d21).sign != (d11 * bip - d12 * bi).sign
          {
            biprime = -biprime
            neg = true
          }
          has_gi = true
        }
        
        let res: Any = Algorithm_6_14(a: ahatprime, b: biprime, N: d11, Nfact: F)
        if res is [Int]
        {
          F = res as! [Int]
          F.sort()
          F = RemovedDuplicates(array: F)
        }
        else
        {
          if neg
          {
            ci[i] -= (res as! Int)
            d21 -= (res as! Int) * bi
            d22 -= (res as! Int) * bip
            ahat = Int.modulo(a: (ahat - (res as! Int) * bi), b: d11)
          }
          else
          {
            ci[i] += (res as! Int)
            d21 += (res as! Int) * bi
            d22 += (res as! Int) * bip
            ahat = Int.modulo(a: (ahat + (res as! Int) * bi), b: d11)
          }
          has_gi = false
          i += 1

        }
      }
    }
  
    return ([d21,d22],ci)
  }
  
  private func ColumnReduction(A1: IntegerMatrix, col_1: Int, col_2: Int, row_start: Int) -> (IntegerMatrix, IntegerMatrix, IntegerMatrix)
  {
    var A: IntegerMatrix = A1
    let n: Int = A.numberOfRows
    let m: Int = A.numberOfColumns
    
    // Apply conditioning subroutine
    let conditioning: (D: [Int], ci: [Int]) = Conditioning(A: A, col_1: col_1, col_2: col_2, row_start: row_start)
    
    // Initialize C
    var C: IntegerMatrix = IntegerMatrix.identity(size: n)
    
    for j in 0..<conditioning.ci.count
    {
      C[row_start + 1, row_start + 2 + j] = conditioning.ci[j]
    }
    // Transform A
    for j in col_1..<m
    {
      var v: Int = A[row_start + 1, j]
      for i in 0..<conditioning.ci.count
      {
        v += conditioning.ci[i] * A[row_start + 2 + i, j]
      }
      A[row_start + 1, j] = v
    }
    
    // Compute Q transform
    let extendedGCD: (t1: Int, m1: Int, m2: Int) = Int.extendedGreatestCommonDivisor(a: A[row_start, col_1], b: A[row_start + 1, col_1])
    
    let s: Int = (A[row_start, col_1] * A[row_start + 1, col_2] - A[row_start, col_2] * A[row_start + 1, col_1]).sign
    var Q = IntegerMatrix.identity(size: n)
    let q1: Int = -s * A[row_start + 1, col_1] / extendedGCD.t1
    let q2: Int = s * A[row_start, col_1] / extendedGCD.t1
    Q[row_start, row_start] = extendedGCD.m1
    Q[row_start, row_start + 1] = extendedGCD.m2
    Q[row_start + 1, row_start] = q1
    Q[row_start + 1, row_start + 1] = q2
    
    // Transform A
    let v: Int  = extendedGCD.m1 * A[row_start, col_2] + extendedGCD.m2 * A[row_start + 1, col_2]
    let t2: Int = q1 * A[row_start, col_2] + q2 * A[row_start + 1, col_2]
    A[row_start, col_1] = extendedGCD.t1
    A[row_start, col_2] = v
    A[row_start + 1, col_1] = 0
    A[row_start + 1, col_2] = t2
    for j in (col_1 + 1)..<m
    {
      if j != col_2
      {
        let v1: Int = extendedGCD.m1 * A[row_start, j] + extendedGCD.m2 * A[row_start + 1, j]
        let v2: Int = q1 * A[row_start, j] + q2 * A[row_start + 1, j]
        A[row_start, j] = v1
        A[row_start + 1, j] = v2
      }
    }
    
    
    // Clean up above
    for i in 0..<row_start
    {
      let s1: Int = -Int.floorDivision(a: A[i, col_1], b: extendedGCD.t1)
      for j in col_1..<m
      {
        A[i, j] = A[i, j] + s1 * A[row_start, j]
      }
      let s2: Int = -Int.floorDivision(a: A[i, col_2], b: t2)
      for j in col_1..<m
      {
         A[i, j] = A[i, j] + s2 * A[row_start + 1, j]
      }
      for j in 0..<n
      {
        let temp: Int = Q[i, j] + s1 * Q[row_start, j] + s2 * Q[row_start + 1, j]
        Q[i, j] = temp
      }
    }
    
    // Clean up below
    for i in (row_start + 2)..<n
    {
      // assert A[i, col_1] % t1 == 0
      let s1: Int = -Int.floorDivision(a: A[i, col_1], b: extendedGCD.t1)
      for j in col_1..<m
      {
        A[i, j] += s1 * A[row_start, j]
      }
      let s2: Int = -Int.floorDivision(a: A[i, col_2], b: t2)
      for j in col_1..<m
      {
        A[i, j] += s2 * A[row_start + 1, j]
      }
      for j in 0..<n
      {
        Q[i, j] +=  s1 * Q[row_start, j] + s2 * Q[row_start + 1, j]
      }
    }
    
    return (Q, C, A)

  }
}
