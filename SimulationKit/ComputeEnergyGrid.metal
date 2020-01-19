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

#include <metal_stdlib>
using namespace metal;


kernel void ComputeEnergyGrid(constant int& numberOfAtoms [[ buffer(0) ]],
                              const device float4* atomPosition [[ buffer(1) ]],
                              const device float4* gridPosition [[ buffer(2) ]],
                              const device float2* potparameters [[ buffer(3) ]],
                              constant float3x3& cell [[ buffer(4) ]],
                              constant int& numberOfReplicas [[ buffer(5) ]],
                              constant float4* replicas [[ buffer(6) ]],
                              device float *output [[ buffer(7) ]],
                              threadgroup float *shared [[ threadgroup(0)]],
                              uint igrid [[thread_position_in_grid]],
                              uint lsize [[threads_per_threadgroup]],
                              uint lid [[thread_position_in_threadgroup]])
{
  float value = 0.0f;
  float3 t,dr,pos;

  float3 gridpos =  gridPosition[igrid].xyz;
  
  for(int j=0;j<numberOfReplicas;j++)
  {
    float3 replica = replicas[j].xyz;
    for(int iatom = 0; iatom < numberOfAtoms; iatom++ )
    {
      pos = atomPosition[iatom].xyz;
      float eps = potparameters[iatom].x;
      float size = potparameters[iatom].y;
    
    
      dr = (gridpos - pos) - replica;
      
      t = dr - rint(dr);
      
      dr = cell * t;
      
      float rr = dot(dr,dr);
      
      if (rr<12.0*12.0)
      {
        float temp = size*size/rr;
        float rri3 = temp * temp * temp;
        
        value += eps*(rri3*(rri3-1.0f));
      }
    }
  }
  
  output[ igrid ] += min(value,10000000.0f);
}

