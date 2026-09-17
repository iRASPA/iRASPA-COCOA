/*************************************************************************************************************
 The MIT License

 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.

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

// GPU Marching Cubes 33 (Lewiner et al., JGT 2003) with histo-pyramid compaction.
// Lookup tables: MarchingCubesLewinerTables.h (Thomas Lewiner MC33).

#include <metal_stdlib>
#include "MarchingCubesLewinerTables.h"
using namespace metal;

constant float LEWINER_EPS = 1.e-7f;

constant uint3 hpCubeOffsets[8] =
{
  {0, 0, 0},
  {1, 0, 0},
  {0, 0, 1},
  {1, 0, 1},
  {0, 1, 0},
  {1, 1, 0},
  {0, 1, 1},
  {1, 1, 1}
};

struct LewinerMesh
{
  uint nTriangles;
  char edges[36]; // up to 12 triangles × 3 edge ids (0..12)
};

struct IsoVertex
{
  float4 position;
  float4 normal;
};

inline void lewinerAppend(thread LewinerMesh &mesh, constant signed char *trig, int n)
{
  for (int t = 0; t < 3 * n; t++)
  {
    mesh.edges[mesh.nTriangles * 3 + (t % 3)] = trig[t];
    if ((t % 3) == 2)
      mesh.nTriangles++;
  }
}

inline bool lewinerTestFace(thread const float cube[8], signed char face)
{
  float A = 0.0f, B = 0.0f, C = 0.0f, D = 0.0f;
  switch (face)
  {
    case -1: case 1: A = cube[0]; B = cube[4]; C = cube[5]; D = cube[1]; break;
    case -2: case 2: A = cube[1]; B = cube[5]; C = cube[6]; D = cube[2]; break;
    case -3: case 3: A = cube[2]; B = cube[6]; C = cube[7]; D = cube[3]; break;
    case -4: case 4: A = cube[3]; B = cube[7]; C = cube[4]; D = cube[0]; break;
    case -5: case 5: A = cube[0]; B = cube[3]; C = cube[2]; D = cube[1]; break;
    case -6: case 6: A = cube[4]; B = cube[7]; C = cube[6]; D = cube[5]; break;
    default: return false;
  }
  float AC_BD = A * C - B * D;
  if (fabs(AC_BD) < LEWINER_EPS)
    return face >= 0;
  return (float(face) * A * AC_BD) >= 0.0f;
}

inline bool lewinerTestInterior(thread const float cube[8], int _case, int config, int subconfig, signed char s)
{
  float t = 0.0f, At = 0.0f, Bt = 0.0f, Ct = 0.0f, Dt = 0.0f, a = 0.0f, b = 0.0f;
  int test = 0;
  int edge = -1;

  if (_case == 4 || _case == 10)
  {
    a = (cube[4] - cube[0]) * (cube[6] - cube[2]) - (cube[7] - cube[3]) * (cube[5] - cube[1]);
    b = cube[2] * (cube[4] - cube[0]) + cube[0] * (cube[6] - cube[2])
      - cube[1] * (cube[7] - cube[3]) - cube[3] * (cube[5] - cube[1]);
    t = -b / (2.0f * a + LEWINER_EPS);
    if (t < 0.0f || t > 1.0f)
      return s > 0;
    At = cube[0] + (cube[4] - cube[0]) * t;
    Bt = cube[3] + (cube[7] - cube[3]) * t;
    Ct = cube[2] + (cube[6] - cube[2]) * t;
    Dt = cube[1] + (cube[5] - cube[1]) * t;
  }
  else if (_case == 6 || _case == 7 || _case == 12 || _case == 13)
  {
    if (_case == 6) edge = lewinerTest6[config][2];
    else if (_case == 7) edge = lewinerTest7[config][4];
    else if (_case == 12) edge = lewinerTest12[config][3];
    else edge = lewinerTiling13_5_1[config][subconfig][0];

    switch (edge)
    {
      case 0:
        t = cube[0] / (cube[0] - cube[1] + LEWINER_EPS);
        At = 0; Bt = cube[3] + (cube[2] - cube[3]) * t; Ct = cube[7] + (cube[6] - cube[7]) * t; Dt = cube[4] + (cube[5] - cube[4]) * t;
        break;
      case 1:
        t = cube[1] / (cube[1] - cube[2] + LEWINER_EPS);
        At = 0; Bt = cube[0] + (cube[3] - cube[0]) * t; Ct = cube[4] + (cube[7] - cube[4]) * t; Dt = cube[5] + (cube[6] - cube[5]) * t;
        break;
      case 2:
        t = cube[2] / (cube[2] - cube[3] + LEWINER_EPS);
        At = 0; Bt = cube[1] + (cube[0] - cube[1]) * t; Ct = cube[5] + (cube[4] - cube[5]) * t; Dt = cube[6] + (cube[7] - cube[6]) * t;
        break;
      case 3:
        t = cube[3] / (cube[3] - cube[0] + LEWINER_EPS);
        At = 0; Bt = cube[2] + (cube[1] - cube[2]) * t; Ct = cube[6] + (cube[5] - cube[6]) * t; Dt = cube[7] + (cube[4] - cube[7]) * t;
        break;
      case 4:
        t = cube[4] / (cube[4] - cube[5] + LEWINER_EPS);
        At = 0; Bt = cube[7] + (cube[6] - cube[7]) * t; Ct = cube[3] + (cube[2] - cube[3]) * t; Dt = cube[0] + (cube[1] - cube[0]) * t;
        break;
      case 5:
        t = cube[5] / (cube[5] - cube[6] + LEWINER_EPS);
        At = 0; Bt = cube[4] + (cube[7] - cube[4]) * t; Ct = cube[0] + (cube[3] - cube[0]) * t; Dt = cube[1] + (cube[2] - cube[1]) * t;
        break;
      case 6:
        t = cube[6] / (cube[6] - cube[7] + LEWINER_EPS);
        At = 0; Bt = cube[5] + (cube[4] - cube[5]) * t; Ct = cube[1] + (cube[0] - cube[1]) * t; Dt = cube[2] + (cube[3] - cube[2]) * t;
        break;
      case 7:
        t = cube[7] / (cube[7] - cube[4] + LEWINER_EPS);
        At = 0; Bt = cube[6] + (cube[5] - cube[6]) * t; Ct = cube[2] + (cube[1] - cube[2]) * t; Dt = cube[3] + (cube[0] - cube[3]) * t;
        break;
      case 8:
        t = cube[0] / (cube[0] - cube[4] + LEWINER_EPS);
        At = 0; Bt = cube[3] + (cube[7] - cube[3]) * t; Ct = cube[2] + (cube[6] - cube[2]) * t; Dt = cube[1] + (cube[5] - cube[1]) * t;
        break;
      case 9:
        t = cube[1] / (cube[1] - cube[5] + LEWINER_EPS);
        At = 0; Bt = cube[0] + (cube[4] - cube[0]) * t; Ct = cube[3] + (cube[7] - cube[3]) * t; Dt = cube[2] + (cube[6] - cube[2]) * t;
        break;
      case 10:
        t = cube[2] / (cube[2] - cube[6] + LEWINER_EPS);
        At = 0; Bt = cube[1] + (cube[5] - cube[1]) * t; Ct = cube[0] + (cube[4] - cube[0]) * t; Dt = cube[3] + (cube[7] - cube[3]) * t;
        break;
      case 11:
        t = cube[3] / (cube[3] - cube[7] + LEWINER_EPS);
        At = 0; Bt = cube[2] + (cube[6] - cube[2]) * t; Ct = cube[1] + (cube[5] - cube[1]) * t; Dt = cube[0] + (cube[4] - cube[0]) * t;
        break;
      default:
        return s > 0;
    }
  }
  else
  {
    return s > 0;
  }

  if (At >= 0.0f) test += 1;
  if (Bt >= 0.0f) test += 2;
  if (Ct >= 0.0f) test += 4;
  if (Dt >= 0.0f) test += 8;
  switch (test)
  {
    case 0: case 1: case 2: case 3: case 4: case 6: case 8: case 9: case 12:
      return s > 0;
    case 7: case 11: case 13: case 14: case 15:
      return s < 0;
    case 5:
      if (At * Ct - Bt * Dt < LEWINER_EPS) return s > 0;
      break;
    case 10:
      if (At * Ct - Bt * Dt >= LEWINER_EPS) return s > 0;
      break;
  }
  return s < 0;
}

inline LewinerMesh lewinerProcessCube(thread const float cube[8])
{
  LewinerMesh mesh;
  mesh.nTriangles = 0;
  for (int i = 0; i < 36; i++) mesh.edges[i] = 0;

  int lut = 0;
  if (cube[0] > 0.0f) lut |= 1;
  if (cube[1] > 0.0f) lut |= 2;
  if (cube[2] > 0.0f) lut |= 4;
  if (cube[3] > 0.0f) lut |= 8;
  if (cube[4] > 0.0f) lut |= 16;
  if (cube[5] > 0.0f) lut |= 32;
  if (cube[6] > 0.0f) lut |= 64;
  if (cube[7] > 0.0f) lut |= 128;

  int _case = lewinerCases[lut][0];
  int config = lewinerCases[lut][1];
  int subconfig = 0;
  if (_case <= 0)
    return mesh;

  switch (_case)
  {

  case 1:
    lewinerAppend(mesh, &lewinerTiling1[config][0], 1);
    break;
  case 2:
    lewinerAppend(mesh, &lewinerTiling2[config][0], 2);
    break;
  case 3:
    if (lewinerTestFace(cube, lewinerTest3[config]))
      lewinerAppend(mesh, &lewinerTiling3_2[config][0], 4);
    else
      lewinerAppend(mesh, &lewinerTiling3_1[config][0], 2);
    break;
  case 4:
    if (lewinerTestInterior(cube, _case, config, subconfig, lewinerTest4[config]))
      lewinerAppend(mesh, &lewinerTiling4_1[config][0], 2);
    else
      lewinerAppend(mesh, &lewinerTiling4_2[config][0], 6);
    break;
  case 5:
    lewinerAppend(mesh, &lewinerTiling5[config][0], 3);
    break;
  case 6:
    if (lewinerTestFace(cube, lewinerTest6[config][0]))
      lewinerAppend(mesh, &lewinerTiling6_2[config][0], 5);
    else if (lewinerTestInterior(cube, _case, config, subconfig, lewinerTest6[config][1]))
      lewinerAppend(mesh, &lewinerTiling6_1_1[config][0], 3);
    else
      lewinerAppend(mesh, &lewinerTiling6_1_2[config][0], 9);
    break;
  case 7:
    if (lewinerTestFace(cube, lewinerTest7[config][0])) subconfig += 1;
    if (lewinerTestFace(cube, lewinerTest7[config][1])) subconfig += 2;
    if (lewinerTestFace(cube, lewinerTest7[config][2])) subconfig += 4;
    switch (subconfig)
    {
      case 0: lewinerAppend(mesh, &lewinerTiling7_1[config][0], 3); break;
      case 1: lewinerAppend(mesh, &lewinerTiling7_2[config][0][0], 5); break;
      case 2: lewinerAppend(mesh, &lewinerTiling7_2[config][1][0], 5); break;
      case 3: lewinerAppend(mesh, &lewinerTiling7_3[config][0][0], 9); break;
      case 4: lewinerAppend(mesh, &lewinerTiling7_2[config][2][0], 5); break;
      case 5: lewinerAppend(mesh, &lewinerTiling7_3[config][1][0], 9); break;
      case 6: lewinerAppend(mesh, &lewinerTiling7_3[config][2][0], 9); break;
      case 7:
        if (lewinerTestInterior(cube, _case, config, subconfig, lewinerTest7[config][3]))
          lewinerAppend(mesh, &lewinerTiling7_4_2[config][0], 9);
        else
          lewinerAppend(mesh, &lewinerTiling7_4_1[config][0], 5);
        break;
    }
    break;
  case 8:
    lewinerAppend(mesh, &lewinerTiling8[config][0], 2);
    break;
  case 9:
    lewinerAppend(mesh, &lewinerTiling9[config][0], 4);
    break;
  case 10:
    if (lewinerTestFace(cube, lewinerTest10[config][0]))
    {
      if (lewinerTestFace(cube, lewinerTest10[config][1]))
        lewinerAppend(mesh, &lewinerTiling10_1_1_[config][0], 4);
      else
        lewinerAppend(mesh, &lewinerTiling10_2[config][0], 8);
    }
    else
    {
      if (lewinerTestFace(cube, lewinerTest10[config][1]))
        lewinerAppend(mesh, &lewinerTiling10_2_[config][0], 8);
      else if (lewinerTestInterior(cube, _case, config, subconfig, lewinerTest10[config][2]))
        lewinerAppend(mesh, &lewinerTiling10_1_1[config][0], 4);
      else
        lewinerAppend(mesh, &lewinerTiling10_1_2[config][0], 8);
    }
    break;
  case 11:
    lewinerAppend(mesh, &lewinerTiling11[config][0], 4);
    break;
  case 12:
    if (lewinerTestFace(cube, lewinerTest12[config][0]))
    {
      if (lewinerTestFace(cube, lewinerTest12[config][1]))
        lewinerAppend(mesh, &lewinerTiling12_1_1_[config][0], 4);
      else
        lewinerAppend(mesh, &lewinerTiling12_2[config][0], 8);
    }
    else
    {
      if (lewinerTestFace(cube, lewinerTest12[config][1]))
        lewinerAppend(mesh, &lewinerTiling12_2_[config][0], 8);
      else if (lewinerTestInterior(cube, _case, config, subconfig, lewinerTest12[config][2]))
        lewinerAppend(mesh, &lewinerTiling12_1_1[config][0], 4);
      else
        lewinerAppend(mesh, &lewinerTiling12_1_2[config][0], 8);
    }
    break;
  case 13:
    if (lewinerTestFace(cube, lewinerTest13[config][0])) subconfig += 1;
    if (lewinerTestFace(cube, lewinerTest13[config][1])) subconfig += 2;
    if (lewinerTestFace(cube, lewinerTest13[config][2])) subconfig += 4;
    if (lewinerTestFace(cube, lewinerTest13[config][3])) subconfig += 8;
    if (lewinerTestFace(cube, lewinerTest13[config][4])) subconfig += 16;
    if (lewinerTestFace(cube, lewinerTest13[config][5])) subconfig += 32;
    subconfig = lewinerSubconfig13[subconfig];
    switch (subconfig)
    {
      case 0: lewinerAppend(mesh, &lewinerTiling13_1[config][0], 4); break;
      case 1: lewinerAppend(mesh, &lewinerTiling13_2[config][0][0], 6); break;
      case 2: lewinerAppend(mesh, &lewinerTiling13_2[config][1][0], 6); break;
      case 3: lewinerAppend(mesh, &lewinerTiling13_2[config][2][0], 6); break;
      case 4: lewinerAppend(mesh, &lewinerTiling13_2[config][3][0], 6); break;
      case 5: lewinerAppend(mesh, &lewinerTiling13_2[config][4][0], 6); break;
      case 6: lewinerAppend(mesh, &lewinerTiling13_2[config][5][0], 6); break;
      case 7: lewinerAppend(mesh, &lewinerTiling13_3[config][0][0], 10); break;
      case 8: lewinerAppend(mesh, &lewinerTiling13_3[config][1][0], 10); break;
      case 9: lewinerAppend(mesh, &lewinerTiling13_3[config][2][0], 10); break;
      case 10: lewinerAppend(mesh, &lewinerTiling13_3[config][3][0], 10); break;
      case 11: lewinerAppend(mesh, &lewinerTiling13_3[config][4][0], 10); break;
      case 12: lewinerAppend(mesh, &lewinerTiling13_3[config][5][0], 10); break;
      case 13: lewinerAppend(mesh, &lewinerTiling13_3[config][6][0], 10); break;
      case 14: lewinerAppend(mesh, &lewinerTiling13_3[config][7][0], 10); break;
      case 15: lewinerAppend(mesh, &lewinerTiling13_3[config][8][0], 10); break;
      case 16: lewinerAppend(mesh, &lewinerTiling13_3[config][9][0], 10); break;
      case 17: lewinerAppend(mesh, &lewinerTiling13_3[config][10][0], 10); break;
      case 18: lewinerAppend(mesh, &lewinerTiling13_3[config][11][0], 10); break;
      case 19: lewinerAppend(mesh, &lewinerTiling13_4[config][0][0], 12); break;
      case 20: lewinerAppend(mesh, &lewinerTiling13_4[config][1][0], 12); break;
      case 21: lewinerAppend(mesh, &lewinerTiling13_4[config][2][0], 12); break;
      case 22: lewinerAppend(mesh, &lewinerTiling13_4[config][3][0], 12); break;
      case 23:
        subconfig = 0;
        if (lewinerTestInterior(cube, _case, config, subconfig, lewinerTest13[config][6]))
          lewinerAppend(mesh, &lewinerTiling13_5_1[config][0][0], 6);
        else
          lewinerAppend(mesh, &lewinerTiling13_5_2[config][0][0], 10);
        break;
      case 24:
        subconfig = 1;
        if (lewinerTestInterior(cube, _case, config, subconfig, lewinerTest13[config][6]))
          lewinerAppend(mesh, &lewinerTiling13_5_1[config][1][0], 6);
        else
          lewinerAppend(mesh, &lewinerTiling13_5_2[config][1][0], 10);
        break;
      case 25:
        subconfig = 2;
        if (lewinerTestInterior(cube, _case, config, subconfig, lewinerTest13[config][6]))
          lewinerAppend(mesh, &lewinerTiling13_5_1[config][2][0], 6);
        else
          lewinerAppend(mesh, &lewinerTiling13_5_2[config][2][0], 10);
        break;
      case 26:
        subconfig = 3;
        if (lewinerTestInterior(cube, _case, config, subconfig, lewinerTest13[config][6]))
          lewinerAppend(mesh, &lewinerTiling13_5_1[config][3][0], 6);
        else
          lewinerAppend(mesh, &lewinerTiling13_5_2[config][3][0], 10);
        break;
      case 27: lewinerAppend(mesh, &lewinerTiling13_3_[config][0][0], 10); break;
      case 28: lewinerAppend(mesh, &lewinerTiling13_3_[config][1][0], 10); break;
      case 29: lewinerAppend(mesh, &lewinerTiling13_3_[config][2][0], 10); break;
      case 30: lewinerAppend(mesh, &lewinerTiling13_3_[config][3][0], 10); break;
      case 31: lewinerAppend(mesh, &lewinerTiling13_3_[config][4][0], 10); break;
      case 32: lewinerAppend(mesh, &lewinerTiling13_3_[config][5][0], 10); break;
      case 33: lewinerAppend(mesh, &lewinerTiling13_3_[config][6][0], 10); break;
      case 34: lewinerAppend(mesh, &lewinerTiling13_3_[config][7][0], 10); break;
      case 35: lewinerAppend(mesh, &lewinerTiling13_3_[config][8][0], 10); break;
      case 36: lewinerAppend(mesh, &lewinerTiling13_3_[config][9][0], 10); break;
      case 37: lewinerAppend(mesh, &lewinerTiling13_3_[config][10][0], 10); break;
      case 38: lewinerAppend(mesh, &lewinerTiling13_3_[config][11][0], 10); break;
      case 39: lewinerAppend(mesh, &lewinerTiling13_2_[config][0][0], 6); break;
      case 40: lewinerAppend(mesh, &lewinerTiling13_2_[config][1][0], 6); break;
      case 41: lewinerAppend(mesh, &lewinerTiling13_2_[config][2][0], 6); break;
      case 42: lewinerAppend(mesh, &lewinerTiling13_2_[config][3][0], 6); break;
      case 43: lewinerAppend(mesh, &lewinerTiling13_2_[config][4][0], 6); break;
      case 44: lewinerAppend(mesh, &lewinerTiling13_2_[config][5][0], 6); break;
      case 45: lewinerAppend(mesh, &lewinerTiling13_1_[config][0], 4); break;
    }
    break;
  case 14:
    lewinerAppend(mesh, &lewinerTiling14[config][0], 4);
    break;

  }
  return mesh;
}

// Same central-difference convention as the previous GPU MC: (f[i-1] - f[i+1], …),
// i.e. opposite the mathematical ∇f. Shading / front-back materials depend on this sign.
inline float3 lewinerGridGradient(texture3d<float, access::read> rawData,
                                  uint3 p,
                                  uint3 dimensions)
{
  const uint3 px = uint3(1, 0, 0);
  const uint3 py = uint3(0, 1, 0);
  const uint3 pz = uint3(0, 0, 1);
  return float3(
    rawData.read((p + dimensions - px) % dimensions).x - rawData.read((p + px) % dimensions).x,
    rawData.read((p + dimensions - py) % dimensions).x - rawData.read((p + py) % dimensions).x,
    rawData.read((p + dimensions - pz) % dimensions).x - rawData.read((p + pz) % dimensions).x);
}

inline void lewinerEdgeVertex(texture3d<float, access::read> rawData,
                              thread const float cube[8],
                              uint3 cubePos,
                              uint3 dimensions,
                              int edge,
                              thread float3 &outPos,
                              thread float3 &outN)
{
  if (edge == 12)
  {
    float ff = 0.0f;
    float3 pos = float3(0.0f);
    float3 nrm = float3(0.0f);
    for (int c = 0; c < 8; c++)
    {
      float w = 1.0f / (LEWINER_EPS + fabs(cube[c]));
      ff += w;
      uint3 corner = (cubePos + lewinerCornerOffset[c]) % dimensions;
      pos += float3(lewinerCornerOffset[c]) * w;
      nrm += lewinerGridGradient(rawData, corner, dimensions) * w;
    }
    outPos = float3(cubePos) + pos / ff;
    outN = nrm;
    return;
  }

  int2 ends = lewinerEdgeCorners[edge];
  float v0 = cube[ends.x];
  float v1 = cube[ends.y];
  float denom = v1 - v0;
  float u = (fabs(denom) < LEWINER_EPS) ? 0.5f : (-v0) / denom;
  u = clamp(u, 0.0f, 1.0f);
  uint3 point0 = (cubePos + lewinerCornerOffset[ends.x]) % dimensions;
  uint3 point1 = (cubePos + lewinerCornerOffset[ends.y]) % dimensions;
  float3 p0 = float3(lewinerCornerOffset[ends.x]);
  float3 p1 = float3(lewinerCornerOffset[ends.y]);
  outPos = float3(cubePos) + mix(p0, p1, u);
  outN = mix(lewinerGridGradient(rawData, point0, dimensions),
             lewinerGridGradient(rawData, point1, dimensions), u);
}

inline void sampleLewinerCube(texture3d<float, access::read> rawData,
                              uint3 gid,
                              uint3 dimensions,
                              float isolevel,
                              thread float cube[8])
{
  for (int c = 0; c < 8; c++)
  {
    uint3 p = (gid + lewinerCornerOffset[c]) % dimensions;
    cube[c] = rawData.read(p).x - isolevel;
    if (fabs(cube[c]) < LEWINER_EPS)
      cube[c] = (cube[c] >= 0.0f) ? LEWINER_EPS : -LEWINER_EPS;
  }
}

kernel void constructHPLevel(texture3d<uint, access::read> readHistoPyramid [[texture(0)]],
                             texture3d<uint, access::write> writeHistoPyramid [[texture(1)]],
                             uint3 gid [[thread_position_in_grid]])
{
  uint3 readPos = gid * 2;
  uint writeValue = readHistoPyramid.read(readPos).x
                 + readHistoPyramid.read(readPos + hpCubeOffsets[1]).x
                 + readHistoPyramid.read(readPos + hpCubeOffsets[2]).x
                 + readHistoPyramid.read(readPos + hpCubeOffsets[3]).x
                 + readHistoPyramid.read(readPos + hpCubeOffsets[4]).x
                 + readHistoPyramid.read(readPos + hpCubeOffsets[5]).x
                 + readHistoPyramid.read(readPos + hpCubeOffsets[6]).x
                 + readHistoPyramid.read(readPos + hpCubeOffsets[7]).x;
  writeHistoPyramid.write(uint4(writeValue, 0u, 0u, 0u), gid);
}

kernel void countHPTriangles(texture3d<uint, access::read> hp [[texture(0)]],
                             device uint *out [[buffer(0)]])
{
  uint sum = 0;
  for (uint z = 0; z < 2; z++)
    for (uint y = 0; y < 2; y++)
      for (uint x = 0; x < 2; x++)
        sum += hp.read(uint3(x, y, z)).x;
  *out = sum;
}

uint4 scanHPLevel(uint target, texture3d<uint, access::read> hp, uint4 current)
{
  uint neighbors[8] =
  {
    hp.read(current.xyz).x,
    hp.read(current.xyz + hpCubeOffsets[1]).x,
    hp.read(current.xyz + hpCubeOffsets[2]).x,
    hp.read(current.xyz + hpCubeOffsets[3]).x,
    hp.read(current.xyz + hpCubeOffsets[4]).x,
    hp.read(current.xyz + hpCubeOffsets[5]).x,
    hp.read(current.xyz + hpCubeOffsets[6]).x,
    hp.read(current.xyz + hpCubeOffsets[7]).x
  };

  uint acc = current.w + neighbors[0];
  uint cmp[8] = {0, 0, 0, 0, 0, 0, 0, 0};
  cmp[0] = acc <= target;
  acc += neighbors[1];
  cmp[1] = acc <= target;
  acc += neighbors[2];
  cmp[2] = acc <= target;
  acc += neighbors[3];
  cmp[3] = acc <= target;
  acc += neighbors[4];
  cmp[4] = acc <= target;
  acc += neighbors[5];
  cmp[5] = acc <= target;
  acc += neighbors[6];
  cmp[6] = acc <= target;
  cmp[7] = 0;

  current += uint4(hpCubeOffsets[(cmp[0] + cmp[1] + cmp[2] + cmp[3] + cmp[4] + cmp[5] + cmp[6] + cmp[7])], 0);
  current.x = current.x * 2;
  current.y = current.y * 2;
  current.z = current.z * 2;
  current.w = current.w
            + cmp[0] * neighbors[0] + cmp[1] * neighbors[1] + cmp[2] * neighbors[2] + cmp[3] * neighbors[3]
            + cmp[4] * neighbors[4] + cmp[5] * neighbors[5] + cmp[6] * neighbors[6] + cmp[7] * neighbors[7];
  return current;
}

kernel void classifyLewinerCubes(texture3d<float, access::read> rawData [[texture(0)]],
                                 texture3d<uint, access::write> writeHistoPyramid [[texture(1)]],
                                 device const float &isolevel [[buffer(0)]],
                                 device const uint3 &dimensions [[buffer(1)]],
                                 uint3 gid [[thread_position_in_grid]])
{
  if (any(gid >= dimensions))
  {
    writeHistoPyramid.write(uint4(0, 0, 0, 0), gid);
    return;
  }

  float cube[8];
  sampleLewinerCube(rawData, gid, dimensions, isolevel, cube);
  LewinerMesh mesh = lewinerProcessCube(cube);
  writeHistoPyramid.write(uint4(mesh.nTriangles, 0, 0, 0), gid);
}

kernel void traverseLewinerHP(texture3d<float, access::read> rawData [[texture(0)]],
                              array<texture3d<uint, access::read>, 10> hp [[texture(1)]],
                              device IsoVertex *VBOBuffer [[buffer(0)]],
                              device const float &isolevel [[buffer(1)]],
                              device uint &sum [[buffer(2)]],
                              device const uint3 &dimensions [[buffer(3)]],
                              device const int &size [[buffer(4)]],
                              uint gid [[thread_position_in_grid]])
{
  uint target = gid;
  if (target >= sum)
    target = 0;

  uint4 cubePosition = uint4(0);
  for (int i = size; i >= 0; i--)
    cubePosition = scanHPLevel(target, hp[i], cubePosition);

  cubePosition.x = cubePosition.x / 2;
  cubePosition.y = cubePosition.y / 2;
  cubePosition.z = cubePosition.z / 2;

  float cube[8];
  sampleLewinerCube(rawData, cubePosition.xyz, dimensions, isolevel, cube);
  LewinerMesh mesh = lewinerProcessCube(cube);

  uint local = target - cubePosition.w;
  if (local >= mesh.nTriangles)
    local = 0;

  // Emit CW winding for Metal. Negate field gradients so stored normals match the
  // geometric front face (cross product of CW edges); otherwise front-side lighting is dark.
  for (int v = 0; v < 3; v++)
  {
    int edge = mesh.edges[local * 3 + (2 - v)];
    float3 pos, nrm;
    lewinerEdgeVertex(rawData, cube, cubePosition.xyz, dimensions, edge, pos, nrm);
    nrm = -nrm;
    float nlen = length(nrm);
    if (nlen > LEWINER_EPS)
      nrm /= nlen;
    IsoVertex vert;
    vert.position = float4(pos.x / float(dimensions.x),
                           pos.y / float(dimensions.y),
                           pos.z / float(dimensions.z), 1.0f);
    vert.normal = float4(nrm, 0.0f);
    VBOBuffer[target * 3 + uint(v)] = vert;
  }
}
