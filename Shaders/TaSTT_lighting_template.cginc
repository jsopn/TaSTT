#ifndef TASTT_LIGHTING
#define TASTT_LIGHTING

#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"

struct appdata
{
  float4 position : POSITION;
  float2 uv : TEXCOORD0;
  float3 normal : NORMAL;
};

struct v2f
{
  float4 position : SV_POSITION;
  float4 uv : TEXCOORD0;
  float3 normal : TEXCOORD1;
  float3 worldPos : TEXCOORD2;

  #if defined(VERTEXLIGHT_ON)
  float3 vertexLightColor : TEXCOORD3;
  #endif
};

SamplerState linear_clamp_sampler;
SamplerState linear_repeat_sampler;

float BG_Enable;
Texture2D BG_BaseColor;
Texture2D BG_NormalMap;
Texture2D BG_Metallic;
Texture2D BG_Smoothness;
Texture2D BG_Emission_Mask;
float BG_Smoothness_Invert;
float BG_NormalStrength;
float3 BG_Emission_Color;
float4 BG_BaseColor_ST;
float4 BG_NormalMap_ST;
float4 BG_Metallic_ST;
float4 BG_Smoothness_ST;
float4 BG_Emission_Mask_ST;

float Enable_Dithering;
float AA_Amount;

Texture2D _Font_0x0000_0x1FFF;
float4 _Font_0x0000_0x1FFF_TexelSize;
Texture2D _Font_0x2000_0x3FFF;
float4 _Font_0x2000_0x3FFF_TexelSize;
Texture2D _Font_0x4000_0x5FFF;
float4 _Font_0x4000_0x5FFF_TexelSize;
Texture2D _Font_0x6000_0x7FFF;
float4 _Font_0x6000_0x7FFF_TexelSize;
Texture2D _Font_0x8000_0x9FFF;
float4 _Font_0x8000_0x9FFF_TexelSize;
Texture2D _Font_0xA000_0xBFFF;
float4 _Font_0xA000_0xBFFF_TexelSize;
Texture2D _Font_0xC000_0xDFFF;
float4 _Font_0xC000_0xDFFF_TexelSize;
Texture2D _Img_0xE000_0xE03F;
float4 _Img_0xE000_0xE03F_TexelSize;

fixed4 Text_Color;
fixed4 Background_Color;
fixed4 Margin_Color;

float Metallic;
float Smoothness;
float Emissive;

float Render_Margin;
float Render_Visual_Indicator;
float Margin_Scale;
float Margin_Rounding_Scale;
float Enable_Margin_Effect_Squares;

float Enable_Custom_Cubemap;
UNITY_DECLARE_TEXCUBE(Custom_Cubemap);

// %TEMPLATE__CG_ROW_COL_CONSTANTS%

float3 HUEtoRGB(in float H)
{
  float R = abs(H * 6 - 3) - 1;
  float G = 2 - abs(H * 6 - 2);
  float B = 2 - abs(H * 6 - 4);
  return saturate(float3(R, G, B));
}

float3 HSVtoRGB(in float3 HSV)
{
  float3 RGB = HUEtoRGB(HSV.x);
  return ((RGB - 1) * HSV.y + 1) * HSV.z;
}

float _TaSTT_Indicator_0;
float _TaSTT_Indicator_1;
static const float3 TaSTT_Indicator_Color_0 = HSVtoRGB(float3(0.00, 0.7, 1.0));
static const float3 TaSTT_Indicator_Color_1 = HSVtoRGB(float3(0.07, 0.7, 1.0));
static const float3 TaSTT_Indicator_Color_2 = HSVtoRGB(float3(0.30, 0.7, 1.0));

fixed4 float3tofixed4(in float3 f3, in float alpha)
{
  return fixed4(
    f3.r,
    f3.g,
    f3.b,
    alpha);
}

// %TEMPLATE__CG_ROW_COL_PARAMS%

void getVertexLightColor(inout v2f i)
{
  #if defined(VERTEXLIGHT_ON)
  float3 light_pos = float3(unity_4LightPosX0.x, unity_4LightPosY0.x,
      unity_4LightPosZ0.x);
  float3 light_vec = light_pos - i.worldPos;
  float3 light_dir = normalize(light_vec);
  float ndotl = DotClamped(i.normal, light_dir);
  // Light fills an expanding sphere with surface area 4 * pi * r^2.
  // By conservation of energy, this means that at distance r, light intensity
  // is proportional to 1/(r^2).
  float attenuation = 1 / (1 + dot(light_vec, light_vec) * unity_4LightAtten0.x);
  i.vertexLightColor = unity_LightColor[0].rgb * ndotl * attenuation;

  i.vertexLightColor = Shade4PointLights(
    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
    unity_LightColor[0].rgb,
    unity_LightColor[1].rgb,
    unity_LightColor[2].rgb,
    unity_LightColor[3].rgb,
    unity_4LightAtten0, i.worldPos, i.normal
  );
  #endif
}

v2f vert(appdata v)
{
  v2f o;
  o.position = UnityObjectToClipPos(v.position);
  o.worldPos = mul(unity_ObjectToWorld, v.position);
  o.normal = UnityObjectToWorldNormal(v.normal);
  o.uv.xy = TRANSFORM_TEX(v.uv, BG_BaseColor);
  o.uv.zw = 1.0 - v.uv;
  getVertexLightColor(o);
  return o;
}

float2 AddMarginToUV(float2 uv, float2 margin)
{
  float2 lo = float2(-margin.x / 2, -margin.y / 2);
  float2 hi = float2(1.0 + margin.x / 2, 1.0 + margin.y / 2);

  return clamp(lerp(lo, hi, uv), 0.0, 1.0);
}

// dist = sqrt(dx^2 + dy^2) = sqrt(<dx,dy> * <dx,dy>)
bool InRadius2(float2 uv, float2 pos, float radius2)
{
  float2 delta = uv - pos;
  return dot(delta, delta) < radius2;
}

bool InMargin(float2 uv, float2 margin)
{
  if (uv.x < margin.x ||
      uv.x > 1 - margin.x ||
      uv.y < margin.y ||
      uv.y > 1 - margin.y) {
      return true;
  }

  return false;
}

bool InSpeechIndicator(float2 uv, float2 margin)
{
  if (!Render_Visual_Indicator) {
    return false;
  }

  // Margin is uv_margin/2 wide/tall.
  // We want a circle whose radius is ~80% of that.
  float radius_factor = 0.95;
  float radius = margin.x * radius_factor;
  // We want this circle to be centered halfway through the margin
  // vertically, and at 1.5x the margin width horizontally.
  float2 indicator_center = float2(margin.x + radius, margin.y * 0.5);
  // Finally, translate it to the top of the board instead of the
  // bottom.
  indicator_center.y = 1.0 - indicator_center.y;

  if (InRadius2(uv, indicator_center, radius * radius)) {
    return true;
  }

  return false;
}

bool InMarginRounding(float2 uv, float2 margin, float rounding, bool interior)
{
  if (!interior) {
    rounding += margin.x;
    margin = float2(0, 0);
    float err_margin = 0.001;
    if (uv.x < err_margin || uv.x > 1.0 - err_margin ||
        uv.y < err_margin || uv.y > 1.0 - err_margin) {
      return true;
    }
  }

  // This is the center of a circle whose perimeter touches the
  // upper left corner of the margin.
  float2 c0 = float2(rounding + margin.x, rounding + margin.y);
  if (uv.x < c0.x && uv.y < c0.y && uv.x > margin.x && uv.y > margin.y && !InRadius2(uv, c0, rounding * rounding)) {
      return true;
  }
  c0 = float2(rounding + margin.x, 1 - (rounding + margin.y));
  if (uv.x < c0.x && uv.y > c0.y && uv.x > margin.x && uv.y < 1 - margin.y && !InRadius2(uv, c0, rounding * rounding)) {
      return true;
  }
  c0 = float2(1 - (rounding + margin.x), 1 - (rounding + margin.y));
  if (uv.x > c0.x && uv.y > c0.y && uv.x < 1 - margin.x && uv.y < 1 - margin.y && !InRadius2(uv, c0, rounding * rounding)) {
      return true;
  }
  c0 = float2(1 - (rounding + margin.x), rounding + margin.y);
  if (uv.x > c0.x && uv.y < c0.y && uv.x < 1 - margin.x && uv.y > margin.y && !InRadius2(uv, c0, rounding * rounding)) {
      return true;
  }

  return false;
}

// Write the nth letter in the current cell and return the value of the
// pixel.
// `texture_rows` and `texture_cols` indicate how many rows and columns are
// in the texture being sampled.
float2 GetLetter(float2 uv, int nth_letter,
    float texture_cols, float texture_rows,
    float board_cols, float board_rows,
    float margin)
{
  // UV spans from [0,1] to [0,1].
  // 'U' is horizontal; cols.
  // 'V' is vertical; rows.
  //
  // I want to divide the mesh into an m x n grid.
  // I want to know what grid cell I'm in. This is simply u * m, v * n.

  // OK, I know what cell I'm in. Now I need to know how far across it I
  // am. Produce a float in the range [0, 1).
  float CHAR_FRAC_COL = uv.x * board_cols - floor(uv.x * board_cols);
  float CHAR_FRAC_ROW = uv.y * board_rows - floor(uv.y * board_rows);

  // Avoid rendering pixels right on the edge of the slot. If we were to
  // do this, then that value would get stretched due to clamping
  // (AddMarginToUV), resulting in long lines on the edge of the display.
  float lo = margin / 2;
  float hi = 1.0 - margin / 2;
  if (margin != 0 &&
      (CHAR_FRAC_ROW < lo ||
      CHAR_FRAC_COL < lo ||
      CHAR_FRAC_ROW > hi ||
      CHAR_FRAC_COL > hi)) {
    return float2(-1, -1);
  }

  float LETTER_COL = fmod(nth_letter, floor(texture_cols));
  float LETTER_ROW = floor(texture_rows) - floor(nth_letter / floor(texture_cols));

  float LETTER_UV_ROW = (LETTER_ROW + CHAR_FRAC_ROW - 1.00) / texture_rows;
  float LETTER_UV_COL = (LETTER_COL + CHAR_FRAC_COL) / texture_cols;

  float2 result;
  result.x = LETTER_UV_COL;
  result.y = LETTER_UV_ROW;

  return result;
}

// Get the value of the parameter for the cell we're in.
uint GetLetterParameter(float2 uv)
{
  float CHAR_COL = floor(uv.x * BOARD_NCOLS);
  float CHAR_ROW = floor(uv.y * BOARD_NROWS);
  int res = 0;

  // %TEMPLATE__CG_LETTER_ACCESSOR%
  return res;
}

fixed sq_dist(fixed2 p0, fixed2 p1)
{
  fixed2 delta = p1 - p0;
  //return abs(delta.x) + abs(delta.y);
  return max(abs(delta.x), abs(delta.y));
}

fixed4 effect_squares (v2f i)
{
  float2 uv = i.uv.zw;
  uv.y *= 2;  // Text box has 2:1 aspect ratio
  const fixed time = _Time.y;

  #define PI 3.1415926535
  fixed theta = PI/4 + sin(time / 4) * 0.1;
  fixed2x2 rot =
    fixed2x2(cos(theta), -1 * sin(theta),
    sin(theta), cos(theta));

  #define NSQ_X 9.0
  #define NSQ_Y 5.0

  // Map uv from [0, 1] to [-.5, .5].
  fixed2 p = uv - 0.5;
  p *= fixed2(NSQ_X, NSQ_Y);
  p = mul(rot, p);
  p -= 0.5;

  // See how far we are from the nearest grid point
  fixed2 intra_pos = frac(p);
  fixed2 intra_center = fixed2(0.5, 0.5);
  fixed intra_dist = sq_dist(intra_pos, intra_center);

  fixed st0 = (sin(time) + 1) / 2;
  fixed st1 = (sin(time + PI/8) + 1) / 2;
  fixed st2 = (sin(time + PI/2) + 1) / 2;
  fixed st3 = (sin(time + PI/2 + PI/8) + 1) / 2;

  fixed2 center = fixed2(0, 0);
  center = mul(rot, center);
  center -= 0.5;
  fixed2 rot_lim = fixed2(NSQ_X, NSQ_Y);
  rot_lim = mul(rot, rot_lim);
  rot_lim -= 0.5;

  float v = 0;
  float x = 0;

  if (intra_dist > 0.5 * (0.5 + sin(time * 1.5) * 0.1)) {
    v = intra_dist;
  } else {
    v = 0;
  }

  fixed extra_dist = sq_dist(p, center);
  fixed check = max(rot_lim.x, rot_lim.y) / 2;
  if (extra_dist > check * st0) {
    v = 1.0 - v;
  }
  if (extra_dist > check * st1) {
    v = 1.0 - v;
  }
  if (extra_dist > check * st2) {
    v = 1.0 - v;
  }
  if (extra_dist > check * st3) {
    v = 1.0 - v;
  } else {
    x = 0.50;
  }

  fixed3 hsv;
  hsv[0] = (v * 0.2 * (1 - x * .8) + 0.55) - x;
  hsv[1] = 0.7;
  hsv[2] = 0.8;

  fixed3 col = HSVtoRGB(hsv);

  return fixed4(col, 1.0);
}

fixed4 margin_effect(v2f i)
{
  if (Enable_Margin_Effect_Squares) {
    return effect_squares(i);
  } else {
    return Margin_Color;
  }
}

UnityLight GetLight(v2f i)
{
  UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
  float3 light_color = _LightColor0.rgb * attenuation;

  UnityLight light;
  light.color = light_color;
  #if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
  light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
  #else
  light.dir = _WorldSpaceLightPos0.xyz;
  #endif
  light.ndotl = DotClamped(i.normal, light.dir);

  return light;
}

UnityIndirect GetIndirect(v2f i, float3 view_dir, float smoothness) {
  UnityIndirect indirect;
  indirect.diffuse = 0;
  indirect.specular = 0;

  #if defined(VERTEXLIGHT_ON)
  indirect.diffuse = i.vertexLightColor;
  #endif

  #if defined(FORWARD_BASE_PASS)
  indirect.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
  float3 reflect_dir = reflect(-view_dir, i.normal);
  // There's a nonlinear relationship between mipmap level and roughness.
  float roughness = 1 - smoothness;
  roughness *= 1.7 - .7 * roughness;
  float3 env_sample;
  if (Enable_Custom_Cubemap) {
    env_sample = UNITY_SAMPLE_TEXCUBE_LOD(
        Custom_Cubemap,
        reflect_dir,
        roughness * UNITY_SPECCUBE_LOD_STEPS);
  } else {
    env_sample = UNITY_SAMPLE_TEXCUBE_LOD(
        unity_SpecCube0,
        reflect_dir,
        roughness * UNITY_SPECCUBE_LOD_STEPS);
  }
  indirect.specular = env_sample;
  #endif

  return indirect;
}

void initNormal(inout v2f i)
{
  if (BG_Enable) {
    i.normal = UnpackScaleNormal(
        BG_NormalMap.SampleGrad(linear_repeat_sampler, i.uv.xy,
            ddx(i.uv.x), ddy(i.uv.y)),
        BG_NormalStrength);
    // Swap Y and Z
    i.normal = i.normal.xzy;
  }
  i.normal = normalize(i.normal);
}

float getWorldSpaceDepth(in v2f i)
{
  float4 clip_pos = mul(UNITY_MATRIX_VP, float4(i.worldPos, 1.0));
  return clip_pos.z / clip_pos.w;
}

fixed4 light(v2f i,
    Texture2D albedo_map,
    Texture2D normal_map,
    float normal_str,
    Texture2D metallic_map,
    Texture2D smoothness_map,
    float invert_smoothness,
    Texture2D emission_mask,
    float3 emission_color,
    out float depth)
{
  initNormal(i);

  depth = getWorldSpaceDepth(i);

  float2 iddx = ddx(i.uv.x);
  float2 iddy = ddy(i.uv.y);
  fixed4 albedo = albedo_map.SampleGrad(linear_repeat_sampler, i.uv.xy,
      iddx, iddy);

  fixed3 normal = UnpackScaleNormal(
        normal_map.SampleGrad(linear_repeat_sampler, i.uv.xy,
            iddx, iddy),
        normal_str);
  // Swap Y and Z
  normal = normal.xzy;

  float3 view_dir = normalize(_WorldSpaceCameraPos - i.worldPos);

  float metallic = metallic_map.SampleGrad(linear_repeat_sampler, i.uv.xy,
      iddx, iddy);

  float3 specular_tint;
  float one_minus_reflectivity;
  albedo.rgb = DiffuseAndSpecularFromMetallic(
    albedo, metallic, specular_tint, one_minus_reflectivity);

  UnityIndirect indirect_light;
  indirect_light.diffuse = 0;
  indirect_light.specular = 0;

  float smoothness = smoothness_map.SampleGrad(linear_repeat_sampler, i.uv.xy,
      iddx, iddy);
  if (invert_smoothness) {
    smoothness = 1 - smoothness;
  }

  fixed3 emission = emission_mask.SampleGrad(linear_repeat_sampler, i.uv.xy,
      iddx, iddy);

  fixed3 pbr = UNITY_BRDF_PBS(albedo, specular_tint,
      one_minus_reflectivity, smoothness,
      i.normal, view_dir, GetLight(i), GetIndirect(i, view_dir, smoothness)).rgb;
  pbr.rgb += emission;

  return fixed4(pbr, albedo.a);
}

fixed4 light(v2f i, fixed4 unlit, out float depth)
{
  depth = getWorldSpaceDepth(i);

  // Get color in spherical harmonics
  fixed3 albedo = unlit.rgb;

  float3 view_dir = normalize(_WorldSpaceCameraPos - i.worldPos);

  float3 specular_tint;
  float one_minus_reflectivity;
  albedo = DiffuseAndSpecularFromMetallic(
    albedo, Metallic, specular_tint, one_minus_reflectivity);

  UnityIndirect indirect_light;
  indirect_light.diffuse = 0;
  indirect_light.specular = 0;

  fixed3 pbr = UNITY_BRDF_PBS(albedo, specular_tint,
      one_minus_reflectivity, Smoothness,
      i.normal, view_dir, GetLight(i), GetIndirect(i, view_dir, Smoothness)).rgb;

  pbr = lerp(pbr.rgb, unlit.rgb, Emissive);

  return fixed4(pbr, unlit.a);
}

bool f3ltf3(fixed3 a, fixed3 b)
{
  return a[0] < b[0] &&
    a[1] < b[1] &&
    a[2] < b[2];
}

// Generate a random number on [0, 1].
float prng(float2 p)
{
  return frac(sin(dot(p, float2(561.0, 885.0))) * 776.2) / 2.0;
}

fixed4 frag(v2f i, out float depth : SV_DepthLessEqual) : SV_Target
{
  float2 uv = i.uv.zw;
  depth = -1000.0;

  // Fix text orientation
  uv.y = 0.5 - uv.y;
  uv.x = 1.0 - uv.x;
  uv.y *= 2;  // Text box has 2:1 aspect ratio

  // Derived from github.com/pema99/shader-knowledge (MIT license).
  if (unity_CameraProjection[2][0] != 0.0 ||
      unity_CameraProjection[2][1] != 0.0) {
    uv.x = 1.0 - uv.x;
  }

  float2 uv_margin = float2(Margin_Scale, Margin_Scale * 2) / 2;
  if (Render_Margin) {
    if (Margin_Rounding_Scale > 0.0) {
      if (InMarginRounding(uv, uv_margin, Margin_Rounding_Scale, /*interior=*/true)) {
        return light(i, margin_effect(i), depth);
      }
      if (InMarginRounding(uv, uv_margin, Margin_Rounding_Scale, /*interior=*/false)) {
        return fixed4(0, 0, 0, 0);
      }
    }
    if (InMargin(uv, uv_margin)) {
      if (InSpeechIndicator(uv, uv_margin)) {
        if (floor(_TaSTT_Indicator_0) == 1.0) {
          // Actively speaking
          return light(i, float3tofixed4(TaSTT_Indicator_Color_2, 1.0), depth);
        } else if (floor(_TaSTT_Indicator_1) == 1.0) {
          // Done speaking, waiting for paging.
          return light(i, float3tofixed4(TaSTT_Indicator_Color_1, 1.0), depth);
        } else {
          // Neither speaking nor paging.
          return light(i, float3tofixed4(TaSTT_Indicator_Color_0, 1.0), depth);
        }
      }

      if (Render_Margin) {
        return light(i, margin_effect(i), depth);
      }
    }
  }

  uv_margin *= 4;
  float2 uv_with_margin = AddMarginToUV(uv, uv_margin);

  fixed4 text = fixed4(0, 0, 0, 0);
  bool discard_text = false;

  uint letter = GetLetterParameter(uv_with_margin);

  float texture_cols;
  float texture_rows;
  float2 letter_uv;
  bool is_emote = false;
  if (letter < 0xE000) {
    letter_uv = GetLetter(uv_with_margin, letter % 0x2000, TEXTURE_NCOLS, TEXTURE_NROWS, BOARD_NCOLS, BOARD_NROWS, /*margin=*/0.02);
  } else {
    is_emote = true;
    texture_cols = 16.0;
    texture_rows = 8.0;
    // This will need to be updated if we create multiple emote textures.
    letter_uv = GetLetter(uv_with_margin, letter % 0x2000, texture_cols, texture_rows, BOARD_NCOLS, BOARD_NROWS, /*margin=*/0);
  }

  if (letter_uv.x == -1 && letter_uv.y == -1) {
    discard_text = true;
  }

  // We use ddx/ddy to get the correct mipmaps of the font textures. This
  // confers 2 main benefits:
  //   1. We don't use as much VRAM for distant players.
  //   2. Glyphs anti-alias much more nicely.
  const float iddx = ddx(letter_uv.x);
  const float iddy = ddy(letter_uv.y);

  if (Enable_Dithering && !is_emote) {
    // Add noise to UV.
    // Here, iddx and iddy tell us how big the current UV cell is with respect to
    // screen space (i.e. how many pixels wide it is).
    float noise = frac(prng(letter_uv) + _Time[0]);
    letter_uv.x += (noise - 0.5) * iddx / 4.0;
    letter_uv.y += (noise - 0.5) * iddy / 4.0;
  }

  int which_texture = (int) floor(letter / (uint) (64 * 128));
  [forcecase] switch (which_texture)
  {
    case 0:
      // Divide iddx, iddy by 2.0 to remain on a higher-detail mip level for
      // longer.
      text += _Font_0x0000_0x1FFF.SampleGrad(linear_clamp_sampler,
          letter_uv, iddx / 2.0, iddy / 2.0);
      break;
    case 1:
      text += _Font_0x2000_0x3FFF.SampleGrad(linear_clamp_sampler,
          letter_uv, iddx / 2.0, iddy / 2.0);
      break;
    case 2:
      text += _Font_0x4000_0x5FFF.SampleGrad(linear_clamp_sampler,
          letter_uv, iddx / 2.0, iddy / 2.0);
      break;
    case 3:
      text += _Font_0x6000_0x7FFF.SampleGrad(linear_clamp_sampler,
          letter_uv, iddx / 2.0, iddy / 2.0);
      break;
    case 4:
      text += _Font_0x8000_0x9FFF.SampleGrad(linear_clamp_sampler,
          letter_uv, iddx / 2.0, iddy / 2.0);
      break;
    case 5:
      text += _Font_0xA000_0xBFFF.SampleGrad(linear_clamp_sampler,
          letter_uv, iddx / 2.0, iddy / 2.0);
      break;
    case 6:
      text += _Font_0xC000_0xDFFF.SampleGrad(linear_clamp_sampler,
          letter_uv, iddx / 2.0, iddy / 2.0);
      break;
    case 7:
      text += _Img_0xE000_0xE03F.SampleGrad(linear_clamp_sampler,
          letter_uv, iddx / 2.0, iddy / 2.0);
      break;
    default:
      // Return some distinctive pattern that will look like a bug.
      depth = getWorldSpaceDepth(i);
      return fixed4(1, 0, _SinTime[0], 1);
  }

  // The edges of each letter cell can be slightly grey due to mip maps.
  // Detect this and shade it as the background.
  fixed3 grey = 0.5;
  if (f3ltf3(text.rgb, grey) || discard_text || is_emote) {
    fixed4 bg;
    if (BG_Enable) {
      bg = light(i,
        BG_BaseColor,
        BG_NormalMap,
        BG_NormalStrength,
        BG_Metallic,
        BG_Smoothness,
        BG_Smoothness_Invert,
        BG_Emission_Mask,
        BG_Emission_Color,
        depth);
    } else {
      bg = light(i, Background_Color, depth);
    }
    // Hack: If alpha (text.w) is less than 0.5, don't render it. This
    // eliminates outlines around simple emotes with transparent backgrounds.
    if (is_emote && text.w > 0.5) {
      // Use emote alpha to mix emote color with background color (compositing).
      text.rgb = lerp(bg.rgb, text.rgb, text.w);
      bg = light(i, fixed4(text.rgb, 1.0), depth);
    }
    return bg;
  } else {
    return light(i, Text_Color, depth);
  }
}

#endif  // TASTT_LIGHTING

