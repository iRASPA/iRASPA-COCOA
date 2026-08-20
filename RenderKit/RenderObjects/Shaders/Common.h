/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2026 David Dubbeldam, Jocelyne Vreede, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 J.Vreede@uva.nl      https://www.uva.nl/en/profile/v/r/j.vreede/j.vreede.html
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

typedef struct FragOutput
{
  float4 albedo [[color(0)]];
  float  depth [[depth(any)]];
} FragOutput;

typedef struct InPerVertex
{
  float4 position;
  float4 normal;
  float2 st;
  float2 pad;
  float2 stripeST; // ribbon selection stripes; sizeof becomes 56 (stride 64) — isosurfaces use IsosurfaceInVertex instead
} InPerVertex;

typedef struct InPrimitivePerVertex
{
  float4 position;
  float4 normal;
  float4 color;
  float2 st;
  float2 pad;
} InPrimitivePerVertex;

typedef struct InPerInstanceAttributes
{
  float4 position;
  float4 ambient;
  float4 diffuse;
  float4 specular;
  float4 scale;
  int tag;
} InPerInstanceAttributes;


typedef struct InPerInstanceTextAttributes
{
  float4 position;
  float4 scale;
  float vertexPosition[4];
  float st[4];
} InPerInstanceTextAttributes;

typedef struct InPerInstanceAttributesBonds
{
  float4 position1;
  float4 position2;
  float4 color1;
  float4 color2;
  float4 scale;
  int tag;
  int type;
  // First of the occlusion atlas patches belonging to this bond; a double or triple bond owns one per
  // sub-cylinder, in the order the hull generates them. Stamped when the instance buffers are built,
  // which is also where the bonds are split by order, so the split buffers inherit it.
  uint ambientOcclusionPatch;
} InPerInstanceAttributesBonds;



typedef struct AtomSphereVertexShaderOut
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
} AtomSphereVertexShaderOut;

typedef struct AxesVertexShaderOut
{
  float4 position [[position]];
  float4 ambient;
  float4 diffuse;
  float4 specular;
  
  float3 N;
  float3 Model_N;
  float3 L;
  float3 V;
} AxesVertexShaderOut;

typedef struct PrimitiveVertexShaderOut
{
  float4 position [[position]];
  float3 N;
  float3 Model_N;
  float3 L;
  float3 V;
} PrimitiveVertexShaderOut;

typedef struct AtomSphereImposterVertexShaderOut
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
} AtomSphereImposterVertexShaderOut;

// Ray
typedef struct Ray
{
  float3 origin;
  float3 direction;
} Ray;

// Axis-aligned bounding box
typedef struct AABB
{
  float3 top;
  float3 bottom;
} AABB;

typedef struct FrameUniforms
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

  /// Edge cueing, after Tarini et al. section 5: x is the contour line strength, y its greatest width
  /// in pixels, z the halo strength and w the halo radius in pixels. A zero strength turns that cue off.
  float4 edgeCueing;
  int numberOfMultiSamplePoints;

  /// Depth steps, in scene units, at which a contour line reaches its full width and a halo its full
  /// darkness. Both are set from the size of the scene, so that one setting suits any structure.
  float edgeCueingContourDepth;
  float edgeCueingHaloDepth;

  /// Set when the molecular geometry was path traced, in which case the depth of what is visible is in
  /// the tracer's composite depth buffer rather than in the rasterizer's depth attachment, the geometry
  /// having been left out of the raster passes.
  float edgeCueingUsesTracedDepth;
  
  float bloomLevel;
  float bloomPulse;
  float maximumEDRvalue;
  float padVector44;
} FrameUniforms;




typedef struct ShadowUniforms
{
  float4x4 projectionMatrix;
  float4x4 viewMatrix;
  float4x4 shadowMatrix;
  float4x4 normalMatrix;
  float4x4 viewMatrixInverse;
} ShadowUniforms;

typedef struct StructureUniforms
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
  // Which cues the ribbons of this structure take, as an RKEdgeCueing raw value. Read by the path
  // tracer, which has no stencil to write and so carries the choice in the uniforms instead.
  // Occupies a former pad slot so the stride is unchanged.
  float edgeCueingRibbons = 0.0;
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
  bool isUnity;
  // Which cues the atoms and bonds of this structure take. See `edgeCueingRibbons`.
  float edgeCueingAtoms = 0.0;

  float primitiveHue = 1.0;
  float primitiveSaturation = 1.0;
  float primitiveValue = 1.0;
  // How far occlusion leans towards darkening the direct terms as well as the ambient one. 0 is
  // physically correct, 1 reproduces the "Fancy" look. Occupies a former pad slot so the 1280 byte
  // stride is unchanged.
  float ambientOcclusionStrength = 0.0;
  
  float4 localAxesPosition;
  float4 numberOfReplicas;
  float4 ribbonCoilColor;
  float4 ribbonHelixColor;
  float4 ribbonSheetColor;
  bool ribbonHDR;
  float ribbonHDRExposure;
  float ribbonHue;
  float ribbonSaturation;
  float ribbonValue;
  bool ribbonAmbientOcclusion;
  float padRibbon1;
  float ribbonShininess;
  float padRibbon2;
  float4 ribbonAmbientColor;
  float4 ribbonDiffuseColor;
  float4 ribbonSpecularColor;
  //----------------------------------------  1136 bytes boundary
  // The bond occlusion atlas holds the internal bonds first and the external ones after them, so that a
  // structure needs only one texture; the base is where the second range starts. Occupies former pad
  // slots so the 1280 byte stride is unchanged.
  bool bondAmbientOcclusion;
  int bondAmbientOcclusionPatchNumber;
  float bondAmbientOcclusionPatchSize;
  float bondAmbientOcclusionInverseTextureSize;
  int externalBondAmbientOcclusionPatchBase;
  float padBondAmbientOcclusion0;
  float padBondAmbientOcclusion1;
  float padBondAmbientOcclusion2;
  // Pad 112 bytes so stride is 1280 (multiple of 256) for constant-buffer offsets on iOS.
  float4 padAlignment2;
  float4 padAlignment3;
  float4 padAlignment4;
  float4 padAlignment5;
  float4 padAlignment6;
  float4 padAlignment7;
  float4 padAlignment8;
  //----------------------------------------  1280 bytes boundary
} StructureUniforms;

typedef struct IsosurfaceUniforms
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
  float transparencyThreshold;
  float shininessFrontSide;
  
  float4 ambientBackSide;
  float4 diffuseBackSide;
  float4 specularBackSide;
  bool  backHDR;
  float backHDRExposure;
  int transferFunctionIndex;
  float shininessBackSide;
  
  float hue;
  float saturation;
  float value;
  float stepLength;
  float4 encompassingScaleFactor;
  float4 pad5;
  float4 pad6;
} IsosurfaceUniforms;

typedef struct Light
{
  float4 position;
  /// Unused. Ambient light describes the environment rather than any one lamp, so it lives in
  /// `LightUniforms.sceneAmbient`; the slot is kept only to hold the struct layout steady.
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
  /// 0 directional, 1 point, 2 spot. Occupies former pad slots, so the 128 byte stride is unchanged.
  float lightType;
  /// Non-zero when the light contributes. Only the camera light in slot 0 is on by default.
  float enabled;
  
  float pad3;
  float pad4;
  float pad5;
  float pad6;
} Light;

/// One slot per photographic role: camera, key, fill, side/split, rim/kicker, backlight/silhouette,
/// hair/top and butterfly/paramount. Must match `RKLightUniforms` on the Swift side.
#define NUMBER_OF_LIGHTS 8

/// The unit cell and the bounding box are guides rather than surfaces and have no material of their own to
/// set an ambient level with, so they take this share of the colour they are drawn in. It sits in the same
/// range as the 0.2 an atom's representation style asks for, and it is what keeps them visible when every
/// light is switched off, which the scene ambient makes a reasonable thing to do.
#define GUIDE_GEOMETRY_AMBIENT 0.2

/// Margin for the occlusion bake's depth comparison, in the depth units of its orthographic frustum, whose
/// near and far planes are 1 and 1000, so a thousandth is one Angstrom. It has to clear the rounding between
/// the two passes without reaching the neighbouring strand, which sits several Angstrom away.
#define RIBBON_AMBIENT_OCCLUSION_DEPTH_BIAS 5.0e-4

/// How the atoms, bonds and ribbons record their edge cueing in the scene's stencil, for the compositing
/// pass to read back. The low bits hold an RKEdgeCueing raw value and the high bit says the pixel belongs
/// to a structure at all, whatever it asked for. Kept in step with `stencilValue` on RKEdgeCueing.
#define EDGE_CUEING_STENCIL_MODE_MASK 0x03
#define EDGE_CUEING_STENCIL_CUEABLE_BIT 0x80

typedef struct LightUniforms
{
  Light lights[NUMBER_OF_LIGHTS];

  /// Stands in for the light arriving from the whole environment, and so belongs to the scene rather than
  /// to any single lamp: enabling or disabling a light leaves the ambient floor untouched, and a material
  /// that is lit by ambient alone still shows up when every light is off. Multiplies the material ambient,
  /// which the representation style owns.
  float4 sceneAmbient;
} LightUniforms;


/// The summed contribution of every enabled light, before the material colours are applied. Kept
/// separate from the material so that one loop over the lights serves shaders whose ambient, diffuse
/// and specular colours all differ.
typedef struct LightingWeights
{
  float3 ambient;
  float3 diffuse;
  float3 specular;
} LightingWeights;


typedef struct GlobalAxesUniforms
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

/// Accumulates every enabled light at a point, given the eye-space normal, the unnormalized direction
/// to the eye, and the eye-space position. The lights are defined in eye space, so no further
/// transform is needed here.
///
/// The specular term deliberately does not depend on `N` facing the light, which keeps the highlight
/// behaviour identical to the single-light code this replaced.
LightingWeights accumulateLighting(constant LightUniforms& lightUniforms,
                                   float3 N,
                                   float3 V,
                                   float4 eyePosition,
                                   float materialShininess);

/// As above, but with one bit per light saying whether anything stands between this point and that
/// light. A light whose bit is clear contributes neither diffuse nor specular, which is what casts a
/// shadow; the ambient floor is unaffected, since it stands in for light arriving from everywhere.
///
/// Only the molecular shaders pass a mask, because only atoms, bonds and ribbons are in the
/// acceleration structure that the mask is traced against. Everything else uses the overload above,
/// which is this one with every bit set.
LightingWeights accumulateLighting(constant LightUniforms& lightUniforms,
                                   float3 N,
                                   float3 V,
                                   float4 eyePosition,
                                   float materialShininess,
                                   uint lightVisibility);

/// Reads the per-light visibility of one pixel out of the mask the shadow pass wrote.
///
/// `windowPosition` is the fragment's `[[position]]`. When shadows are off the renderer binds a
/// single all-lit texel, so this reports everything lit without the shaders needing to branch.
uint shadowMaskAtFragment(texture2d<uint> shadowMask, float4 windowPosition);

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
float2 cellular2D(float2 P, float jitter);
float2 cellular3D(float3 P, float jitter);

float2 rayBoxIntersection(Ray ray, AABB box);

#endif /* Common_h */
