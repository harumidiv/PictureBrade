//
//  BladeSkinShaders.metal
//  PictureBrade
//
//  バトル中のコマの「顔」（切り抜き画像）を加工する RealityKit のサーフェスシェーダー。
//  画面上のプレビュー用（SwiftUI）は SkinPreviewShaders.metal に同じ加工がある。
//  ライトの影響を受けないよう、色はすべて自己発光（emissive）で出す。
//

#include <metal_stdlib>
#include <RealityKit/RealityKit.h>
using namespace metal;

namespace bladeskin {

constexpr sampler linearSampler(address::clamp_to_edge, filter::linear);
constexpr sampler nearestSampler(address::clamp_to_edge, filter::nearest);

inline float3 hsv(float h, float s, float v) {
    float3 k = clamp(abs(fract(h + float3(0, 2.0 / 3.0, 1.0 / 3.0)) * 6 - 3) - 1, 0, 1);
    return v * mix(float3(1), k, s);
}

inline float luminance(float3 c) { return dot(c, float3(0.299, 0.587, 0.114)); }

/// RealityKit の UV は上下が逆なので反転して使う
inline float2 faceUV(realitykit::surface_parameters params) {
    float2 uv = params.geometry().uv0();
    uv.y = 1 - uv.y;
    return uv;
}

inline float4 sampleFace(realitykit::surface_parameters params, float2 uv) {
    return float4(params.textures().base_color().sample(linearSampler, uv));
}

/// ライトを使わず、色をそのまま出す
inline void output(realitykit::surface_parameters params, float3 color, float alpha) {
    auto surface = params.surface();
    surface.set_base_color(half3(0));
    surface.set_emissive_color(half3(saturate(color)));
    surface.set_roughness(1);
    surface.set_metallic(0);
    surface.set_specular(0);
    surface.set_opacity(half(alpha));
}

} // namespace bladeskin

using namespace bladeskin;

/// 黄金：明るさを金色のグラデーションに置き換え、光の筋が流れる
[[visible]]
void bladeSkinGold(realitykit::surface_parameters params) {
    float2 uv = faceUV(params);
    float4 face = sampleFace(params, uv);
    float time = params.uniforms().time();
    float l = luminance(face.rgb);
    float3 gold = mix(float3(0.42, 0.26, 0.04), float3(1.0, 0.86, 0.42), smoothstep(0.05, 0.95, l));
    float band = fract((uv.x + uv.y) * 0.7 - time * 0.6);
    float sheen = smoothstep(0.08, 0.0, abs(band - 0.5));
    output(params, gold + sheen * 0.7, face.a);
}

/// ネオン：輪郭が色を変えながら光り、中は少し暗くする
[[visible]]
void bladeSkinNeon(realitykit::surface_parameters params) {
    float2 uv = faceUV(params);
    float4 face = sampleFace(params, uv);
    float time = params.uniforms().time();
    float d = 0.018;
    float minAlpha = 1;
    for (int i = 0; i < 8; i++) {
        float angle = float(i) * M_PI_F / 4;
        minAlpha = min(minAlpha, sampleFace(params, uv + float2(cos(angle), sin(angle)) * d).a);
    }
    float edge = saturate((face.a - minAlpha) * 2);
    float pulse = 0.75 + 0.25 * sin(time * 6);
    float3 neon = hsv(fract(time * 0.25 + uv.x * 0.3), 0.85, 1);
    float3 color = face.rgb * 0.4 + neon * edge * 1.6 * pulse;
    output(params, color, face.a);
}

/// 虹色：虹色の帯がななめに流れていく
[[visible]]
void bladeSkinRainbow(realitykit::surface_parameters params) {
    float2 uv = faceUV(params);
    float4 face = sampleFace(params, uv);
    float time = params.uniforms().time();
    float l = luminance(face.rgb);
    float3 rainbow = hsv(fract(uv.x * 0.8 + uv.y * 0.5 - time * 0.5), 0.75, 1) * (0.55 + 0.6 * l);
    output(params, mix(face.rgb, rainbow, 0.7), face.a);
}

/// ドット絵：粗いマス目にして、色の段階も減らす
[[visible]]
void bladeSkinPixel(realitykit::surface_parameters params) {
    float2 uv = faceUV(params);
    float cells = 22;
    float2 cell = (floor(uv * cells) + 0.5) / cells;
    float4 face = float4(params.textures().base_color().sample(nearestSampler, cell));
    float3 color = floor(face.rgb * 4 + 0.5) / 4;
    // マスの境目を少し暗くしてドットらしくする
    float2 inCell = fract(uv * cells);
    float grid = step(0.1, inCell.x) * step(0.1, inCell.y);
    output(params, color * (0.75 + 0.25 * grid), face.a > 0.5 ? 1 : 0);
}

/// ホログラム：青緑の光に置き換え、走査線とちらつきを入れる
[[visible]]
void bladeSkinHologram(realitykit::surface_parameters params) {
    float2 uv = faceUV(params);
    float time = params.uniforms().time();
    // ときどき横にずれる（グリッチ）
    float glitch = step(0.93, fract(sin(floor(time * 8) * 12.9898) * 43758.5453));
    uv.x += glitch * 0.02 * sin(uv.y * 60);
    float4 face = sampleFace(params, uv);
    float l = luminance(face.rgb);
    float scan = 0.65 + 0.35 * sin(uv.y * 160 - time * 12);
    float flicker = 0.9 + 0.1 * sin(time * 37);
    float3 color = mix(float3(0.1, 0.55, 1.0), float3(0.6, 1.0, 1.0), l) * scan * flicker;
    // 縁をうっすら光らせる
    float rim = smoothstep(0.25, 0.5, distance(uv, float2(0.5)));
    output(params, color + rim * float3(0.4, 0.2, 0.8), face.a);
}
