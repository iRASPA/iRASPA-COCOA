//
//  SmithNormalForm.swift


import Foundation

extension IntegerMatrix
{
  public func SmithNormalForm() -> (IntegerMatrix, IntegerMatrix, IntegerMatrix)
  {
    let n: Int = self.numberOfRows
    let m: Int = self.numberOfColumns
    
    var hnf: (U: IntegerMatrix, A: IntegerMatrix, rp: [Int]) = HermiteNormalForm()
    
    var U: IntegerMatrix = hnf.U
    var A: IntegerMatrix = hnf.A
    let r: Int = hnf.rp.count
    
    var V: IntegerMatrix = IntegerMatrix.identity(size: m)
    
    // Transform A via V so that the left r x r block of A is invertible
    for i in 0..<r
    {
      if hnf.rp[i] > i
      {
        hnf.A.swapColumns(a: i, b: hnf.rp[i])
        V.swapColumns(a: i, b: hnf.rp[i])
      }
    }
    
    // Phase one
    for i in 0..<r
    {
      Smith_Theorem5(A: &A, U: &U, V: &V, col: i)
    }
    var beg: Int = 0
    while beg < r && hnf.A[beg, beg] == 1
    {
      beg += 1
    }
    
    // Phase two
    if beg < r && r < m
    {
      for i in beg..<r
      {
        Smith_Theorem8(A: &A, U: &U, V: &V, row: i, r: r)
      }
      
      // Run transposed Phase One
      var AA = hnf.A.submatrix(startRow: beg, startColumn: beg, numberOfRows: r - beg, numberOfColumns: r - beg).transposed()
      var UU = IntegerMatrix.identity(size: r - beg)
      var VV = IntegerMatrix.identity(size: r - beg)
      // Check if it is actually not a diagonal matrix
      for i in 0..<(r - beg)
      {
        Smith_Theorem5(A: &AA, U: &UU, V: &VV, col: i)
      }
      
      // Insert AA
      AA = AA.transposed()
      hnf.A.assignSubmatrix(startRow: beg, startColumn: beg, integerMatrix: AA.transposed())
      
     // Insert transformations
      let temp: IntegerMatrix = UU
      UU = VV.transposed()
      VV = temp.transposed()
      
      hnf.U.assignSubmatrix(startRow: beg, startColumn: 0, integerMatrix: UU * hnf.U.submatrix(startRow: beg, startColumn: 0, numberOfRows: r - beg, numberOfColumns: n))
      V.assignSubmatrix(startRow: 0, startColumn: beg, integerMatrix: V.submatrix(startRow: 0, startColumn: beg, numberOfRows: m, numberOfColumns: r - beg) * VV)

    }
    
    //V.denominator = self.denominator
    return (hnf.U, V, hnf.A)
  }
  
  private func Smith_Theorem5(A: inout IntegerMatrix, U: inout IntegerMatrix, V: inout IntegerMatrix, col: Int)
  {
    let n: Int = A.numberOfRows
    let m: Int = A.numberOfColumns
    
    // Lemma 6:
    for i in (0..<col).reversed()
    {
      // Compute ci[0] such that GCD(A[i, col] + ci[0] * A[i + 1, col], A[i, i])
      // equals GCD(A[i, col], A[i + 1, col], A[i, i])
      let ci: [Int] = Algorithm_6_15(a: A[i, col], bi: [A[i + 1, col]], N: A[i, i])
      
      // Add ci[0] times the (i+1)-th row to the i-th row
      for j in 0..<m
      {
        A[i, j] = A[i, j] + ci[0] * A[i + 1, j]
      }
      for j in 0..<n
      {
        U[i, j] = U[i, j] + ci[0] * U[i + 1, j]
      }
      
      // Reduce i-th row modulo A[i, i]
      for j in (i + 1)..<m
      {
        let divmod: (d: Int, r: Int) = Int.divisionModulo(a: A[i, j], b: A[i, i])
        //let d: Int = Int.floorDivision(a: A[i, j], b: A[i, i])
        //let r: Int = ((A[i, j] % A[i, i]) + A[i, i]) % A[i, i]
        if divmod.d != 0
        {
          // Subtract d times the i-th column from the j-th column
          A[i, j] = divmod.r
          for k in 0..<m
          {
            V[k, j] = V[k, j] - divmod.d * V[k, i]
          }
        }
      }
    }
    
    // Lemma 7
    for j in 0..<col
    {
      // Apply lemma 7 to submatrix starting at (j, j)
      let extendedGCD: (s1: Int, s: Int, t: Int) = Int.extendedGreatestCommonDivisor(a: A[j, j], b: A[j, col])
      let ss: Int = -A[j, col] / extendedGCD.s1
      let tt: Int = A[j, j] / extendedGCD.s1
      // Transform columns j and col by a 2x2 matrix
      A[j, j] = extendedGCD.s1
      A[j, col] = 0
      for i in (j + 1)..<n
      {
        let temp: Int = A[i, j]
        A[i, j] = extendedGCD.s * A[i, j] + extendedGCD.t * A[i, col]
        A[i, col] = ss * temp + tt * A[i, col]
      }
      for i in 0..<m
      {
        let temp: Int = V[i, j]
        V[i, j] = extendedGCD.s * V[i, j] + extendedGCD.t * V[i, col]
        V[i, col] = ss * temp + tt * V[i, col]
      }
      
      // Clear column j in rows below
      for i in (j + 1)..<n
      {
        let mul: Int = A[i, j] / A[j, j]
        if mul != 0
        {
          for jj in 0..<m
          {
            A[i, jj] = A[i, jj] - mul * A[j, jj]
          }
          for jj in 0..<n
          {
            U[i, jj] = U[i, jj] - mul * U[j, jj]
          }
        }
      }
      
      // Reduce j-th row modulo A[j, j]
      for jj in (j + 1)..<m
      {
        //d, r = divmod(A[j, jj], A[j, j])
        //let d: Int = Int.floorDivision(a: A[j, jj], b: A[j, j])
        //let r: Int = ((A[j, jj] % A[j, j]) + A[j, j]) % A[j, j]
        let divmod: (d: Int, r: Int) = Int.divisionModulo(a: A[j, jj], b: A[j, j])
        if divmod.d != 0
        {
          // Subtract d times the i-th column from the j-th column
          A[j, jj] = divmod.r
          for k in 0..<m
          {
            V[k, jj] = V[k, jj] - divmod.d * V[k, j]
          }
        }
      }
    }
    
    // Make A[col, col] positive
    if A[col, col] < 0
    {
      for jj in col..<m
      {
        A[col, jj] = -A[col, jj]
      }
      for jj in 0..<n
      {
        U[col, jj] = -U[col, jj]
      }
    }
    
    // Reduce col-th row modulo A[col, col]
    for j in (col + 1)..<m
    {
      //d, r = divmod(A[col, j], A[col, col])
      //let d: Int = Int.floorDivision(a: A[col, j], b: A[col, col])
      //let r: Int = ((A[col, j] % A[col, col]) + A[col, col]) % A[col, col]
      let divmod: (d: Int, r: Int) = Int.divisionModulo(a: A[col, j], b: A[col, col])
      if divmod.d != 0
      {
        // Subtract d times the col-th column from the j-th column
        A[col, j] = divmod.r
        for k in 0..<m
        {
          V[k, j] = V[k, j] - divmod.d * V[k, col]
        }
      }
    }
    
  }
  
  private func Smith_Theorem8(A: inout IntegerMatrix, U: inout IntegerMatrix, V: inout IntegerMatrix, row: Int, r: Int)
  {
    let n: Int = A.numberOfRows
    let m: Int = A.numberOfColumns
    
    for j in r..<m
    {
      if A[row, j] != 0
      {
        let extendedGCD: (s1: Int, s: Int, t: Int) = Int.extendedGreatestCommonDivisor(a: A[row, row], b: A[row, j])
        let ss: Int = -A[row, j] / extendedGCD.s1
        let tt: Int = A[row, row] / extendedGCD.s1
        // Transform columns row and j by a 2x2 matrix
        A[row, row] = extendedGCD.s1
        A[row, j] = 0
        
        for i in (row + 1)..<n
        {
          let temp: Int = A[i, row]
          A[i, row] = extendedGCD.s * A[i, row] + extendedGCD.t * A[i, j]
          A[i, j] = ss * temp + tt * A[i, j]
        }
        for i in 0..<m
        {
          let temp: Int = V[i, row]
          V[i, row] = extendedGCD.s * V[i, row] + extendedGCD.t * V[i, j]
          V[i, j] = ss * temp + tt * V[i, j]
        }
        
        // Reduce column row
        for i in (row + 1)..<n
        {
           let d: Int = Int.floorDivision(a: A[i, row], b: A[row, row])
           if d != 0
           {
             for jj in 0..<m
             {
               A[i, jj] = A[i, jj] - d * A[row, jj]
            }
            for jj in 0..<n
            {
              U[i, jj] = U[i, jj] - d * U[row, jj]
            }
          }
        }
        // Reduce column row
        for i in (row + 1)..<n
        {
          let d: Int = Int.floorDivision(a: A[i, row], b: A[row, row])
          if d != 0
          {
            for jj in 0..<m
            {
              A[i, jj] = A[i, jj] - d * A[row, jj]
            }
            for jj in 0..<n
            {
              U[i, jj] = U[i, jj] - d * U[row, jj]
            }
          }
        }
        
      }
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
  
  private func Algorithm_6_15(a: Int, bi: [Int], N: Int) -> [Int]
  {
    if N == 1
    {
      return [Int](repeating: 0, count: bi.count)
    }
    var F: [Int] = [N]
    var ahat: Int = a
    var i: Int = 0
    let n = bi.count
    var has_gi: Bool = false
    var ci: [Int] = [Int](repeating: 0, count: n)
    
    var ahatprime: Int = 0
    var biprime: Int = 0
    
    while i < n
    {
      if !has_gi
      {
        let gi: Int = Int.greatestCommonDivisor(a: ahat, b: bi[i])
        if gi == 0
        {
          // both ahat and bi[i] are zero: take 0 as ci[i] and continue with next entry
          ci[i] = 0
          i += 1
          continue
        }
        //ahatprime = (ahat / gi) % N
        //biprime = (bi[i] / gi) % N
        ahatprime = Int.modulo(a: (ahat / gi), b: N)
        biprime = Int.modulo(a:(bi[i] / gi), b: N)
        has_gi = true
      }
      let res: Any = Algorithm_6_14(a: ahatprime, b: biprime, N: N, Nfact: F)
      
      if res is [Int]
      {
        F = res as! [Int]
        F.sort()
        F = RemovedDuplicates(array: F)
      }
      else
      {
        ci[i] = (res as! Int)
        //ahat = (ahat + (res as! Int) * bi[i]) % N
        ahat = Int.modulo(a: (ahat + (res as! Int) * bi[i]), b: N)
        i += 1
        has_gi = false
      }
    }
    return ci
  }
}
