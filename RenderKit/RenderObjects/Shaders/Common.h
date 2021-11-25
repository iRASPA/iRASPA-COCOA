/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2021 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 S.Calero@tue.nl         https://www.tue.nl/en/research/researchers/sofia-calero/
 t.j.h.vlugt@tudelft.nl  http://homepage.tudelft.nl/v9k6y
 
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

#ifndef Common_h
#define Common_h

#include <simd/simd.h>

using namespace simd;

typedef struct
{
  float4 albedo [[color(0)]];
  float  depth [[depth(any)]];
} FragOutput;

typedef struct
{
  float4 position;
  float4 normal;
  float2 st;
  float2 pad;
} InPerVertex;

typedef struct
{
  float4 position;
  float4 normal;
  float4 color;
  float2 st;
  float2 pad;
} InPrimitivePerVertex;

typedef struct
{
  float4 position;
  float4 ambient;
  float4 diffuse;
  float4 specular;
  float4 scale;
  int tag;
} InPerInstanceAttributes;


typedef struct
{
  float4 position;
  float4 scale;
  float vertexPosition[4];
  float st[4];
} InPerInstanceTextAttributes;

typedef struct
{
  float4 position1;
  float4 position2;
  float4 color1;
  float4 color2;
  float4 scale;
  int tag;
  int type;
} InPerInstanceAttributesBonds;



struct AtomSphereVertexShaderOut
{
  float4 position [[position]];
  float4 ambient [[ flat ]];
  float4 diffuse [[ flat ]];
  float4 specular [[ flat ]];
  
  float3 N;
  float3 Model_N;
  float3 L;
  float3 V;
  float k1 [[ flat ]];    // must be float on ATI-cards  (int does not work)
  float k2 [[ flat ]];
  float4 ambientOcclusionTransformMatrix1 [[ flat ]];
  float4 ambientOcclusionTransformMatrix2 [[ flat ]];
  float4 ambientOcclusionTransformMatrix3 [[ flat ]];
  float4 ambientOcclusionTransformMatrix4 [[ flat ]];
  float clippingDistance0;
  float clippingDistance1;
  float clippingDistance2;
  float clippingDistance3;
  float clippingDistance4;
  float clippingDistance5;
};

struct AxesVertexShaderOut
{
  float4 position [[position]];
  float4 ambient;
  float4 diffuse;
  float4 specular;
  
  float3 N;
  float3 Model_N;
  float3 L;
  float3 V;
};

struct PrimitiveVertexShaderOut
{
  float4 position [[position]];
  float3 N;
  float3 Model_N;
  float3 L;
  float3 V;
};

struct AtomSphereImposterVertexShaderOut
{
  float4 position [[position]];
  float4 eye_position;
  float4 instancePosition [[ flat ]];
  float2 texcoords;
  float4 ambient [[ flat ]];
  float4 diffuse [[ flat ]];
  float4 specular [[ flat ]];
  float3 frag_pos ;
  float3 frag_center [[ flat]];
  float3 N;
  float3 L;
  float3 V;
  float4 sphere_radius [[ flat ]];
  float k1 [[ flat ]];
  float k2 [[ flat ]];
  float4 ambientOcclusionTransformMatrix1 [[ flat ]];
  float4 ambientOcclusionTransformMatrix2 [[ flat ]];
  float4 ambientOcclusionTransformMatrix3 [[ flat ]];
  float4 ambientOcclusionTransformMatrix4 [[ flat ]];
};

// Ray
struct Ray
{
  float3 origin;
  float3 direction;
};

// Axis-aligned bounding box
struct AABB
{
  float3 top;
  float3 bottom;
};

typedef struct
{
  float4x4 projectionMatrix;
  float4x4 viewMatrix;
  float4x4 mvpMatrix;
  float4x4 shadowMatrix;
  
  float4x4 projectionMatrixInverse;
  float4x4 viewMatrixInverse;
  float4x4 normalMatrix;
  
  float4x4 axesProjectionMatrix;
  float4x4 axesViewMatrix;
  float4x4 axesMvpMatrix;
  float4x4 padMatrix;
  
  float4 cameraPosition;
  float4 padVector3;
  int numberOfMultiSamplePoints;
  float padVector41;
  float padVector42;
  float padVector43;
  
  float bloomLevel;
  float bloomPulse;
  float maximumEDRvalue;
  float padVector44;
} FrameUniforms;




typedef struct
{
  float4x4 projectionMatrix;
  float4x4 viewMatrix;
  float4x4 shadowMatrix;
  float4x4 normalMatrix;
} ShadowUniforms;

typedef struct
{
  int sceneIdentifier1;
  int MovieIdentifier1;
  float atomScaleFactor;
  int numberOfMultiSamplePoints;
  
  bool ambientOcclusion;
  int ambientOcclusionPatchNumber;
  float ambientOcclusionPatchSize;
  float ambientOcclusionInverseTextureSize;
  
  float atomHue;
  float atomSaturation;
  float atomValue;
  int structureIdentifier;
  
  bool atomHDR;
  float atomHDRExposure;
  float atomSelectionIntensity;
  bool clipAtomsAtUnitCell;
  
  float4 atomAmbientColor;
  float4 atomDiffuseColor;
  float4 atomSpecularColor;
  float atomShininess;
  
  float bondHue;
  float bondSaturation;
  float bondValue;
  
  //----------------------------------------  128 bytes boundary
  
  bool bondHDR;
  float bondHDRExposure;
  float bondSelectionIntensity;
  bool clipBondsAtUnitCell;
  
  float4 bondAmbientColor;
  float4 bondDiffuseColor;
  float4 bondSpecularColor;
  
  float bondShininess;
  float bondScaling;
  int bondColorMode;
  
  float unitCellScaling;
  float4 unitCellColor;
  
  float4 clipPlaneLeft;
  float4 clipPlaneRight;
  
  //----------------------------------------  256 bytes boundary
  
  float4 clipPlaneTop;
  float4 clipPlaneBottom;
  
  float4 clipPlaneFront;
  float4 clipPlaneBack;
  
  
  float4x4 modelMatrix;
  
  //----------------------------------------  384 bytes boundary
  
  float4x4 inverseModelMatrix;
  float4x4 boxMatrix;
  
  //----------------------------------------  512 bytes boundary
  
  float4x4 inverseBoxMatrix;
  float atomSelectionStripesDensity;
  float atomSelectionStripesFrequency;
  float atomSelectionWorleyNoise3DFrequency;
  float atomSelectionWorleyNoise3DJitter;
  
  float4 atomAnnotationTextDisplacement;
  float4 atomAnnotationTextColor;
  float atomAnnotationTextScaling;
  float atomSelectionScaling;
  float bondSelectionScaling;
  bool colorAtomsWithBondColor;
  
  //----------------------------------------  640 bytes boundary
  
  float4x4 transformationMatrix;
  float4x4 transformationNormalMatrix;
  
  //----------------------------------------  768 bytes boundary
  
  float4 primitiveAmbientFrontSide;
  float4 primitiveDiffuseFrontSide;
  float4 primitiveSpecularFrontSide;
  bool primitiveFrontSideHDR;
  float primitiveFrontSideHDRExposure;
  float primitiveOpacity;
  float primitiveShininessFrontSide;
  
  float4 primitiveAmbientBackSide;
  float4 primitiveDiffuseBackSide;
  float4 primitiveSpecularBackSide;
  bool primitiveBackSideHDR;
  float primitiveBackSideHDRExposure;
  float pad6;
  float primitiveShininessBackSide;
  
  //----------------------------------------  896 bytes boundary
  
  float bondSelectionStripesDensity;
  float bondSelectionStripesFrequency;
  float bondSelectionWorleyNoise3DFrequency;
  float bondSelectionWorleyNoise3DJitter;
  
  float primitiveSelectionStripesDensity = 0.25;
  float primitiveSelectionStripesFrequency = 12.0;
  float primitiveSelectionWorleyNoise3DFrequency = 2.0;
  float primitiveSelectionWorleyNoise3DJitter = 1.0;

  float primitiveSelectionScaling = 1.01;
  float primitiveSelectionIntensity = 0.8;
  float pad7;
  float pad8;

  float primitiveHue = 1.0;
  float primitiveSaturation = 1.0;
  float primitiveValue = 1.0;
  float pad9;
  
  float4 localAxesPosition;
  float4 numberOfReplicas;
  float4 pad11;
  float4 pad12;
  //----------------------------------------  1024 bytes boundary
} StructureUniforms;

typedef struct
{
  float4x4 unitCellMatrix;
  float4x4 inverseUnitCellMatrix;
  float4x4 unitCellNormalMatrix;
  
  float4x4 boxMatrix;
  float4x4 inverseBoxMatrix;
  
  float4 ambientFrontSide;
  float4 diffuseFrontSide;
  float4 specularFrontSide;
  bool  frontHDR;
  float frontHDRExposure;
  float pad1;
  float shininessFrontSide;
  
  float4 ambientBackSide;
  float4 diffuseBackSide;
  float4 specularBackSide;
  bool  backHDR;
  float backHDRExposure;
  float pad2;
  float shininessBackSide;
  
  float hue;
  float saturation;
  float value;
  float stepLength;
  float4 pad4;
  float4 pad5;
  float4 pad6;
} IsosurfaceUniforms;

typedef struct
{
  float4 position;
  float4 ambient;
  float4 diffuse;
  float4 specular;
  
  float4 spotDirection;
  float constantAttenuation;
  float linearAttenuation;
  float quadraticAttenuation;
  float spotCutoff;
  
  float spotExponent;
  float shininess;
  float pad1;
  float pad2;
  
  float pad3;
  float pad4;
  float pad5;
  float pad6;
} Light;

typedef struct
{
  Light lights[4];
} LightUniforms;


typedef struct
{
  float4 axesBackgroundColor;
  float4 textColor[3];
  float4 textDisplacement[3];
  int axesBackGroundStyle;
  float axesScale;
  float centerScale;
  float textOffset;
  float textScale[4];
} GlobalAxesUniforms;

float mod289(float x);
float2 mod289(float2 x);
float3 mod289(float3 x);
float4 mod289(float4 x);

float permute(float x);
float3 permute(float3 x);
float4 permute(float4 x);

float4 taylorInvSqrt(float4 r);
float taylorInvSqrt(float r);

float3 rgb2hsv(float3 c);
float3 hsv2rgb(float3 c);
float frontFacing(float4 pos0, float4 pos1, float4 pos2);

float2 cellular2D(float2 P, float jitter);
float2 cellular3D(float3 P, float jitter);

float2 rayBoxIntersection(Ray ray, AABB box);

#endif /* Common_h */
