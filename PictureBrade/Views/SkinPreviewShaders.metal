//
//  SkinPreviewShaders.metal
//  PictureBrade
//
//  コマの見た目の加工を SwiftUI の画面上で見せるためのシェーダー（layerEffect 用）。
//  バトル中の 3D 版（BladeSkinShaders.metal）と同じ見た目になるようにしてある。
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

namespace skinpreview {

inline float3 hsv(float h, float s, float v) {
    float3 k = clamp(abs(fract(h + float3(0, 2.0 / 3.0, 1.0 / 3.0)) * 6 - 3) - 1, 0, 1);
    return v * mix(float3(1), k, s);
}

inline float luminance(float3 c) { return dot(c, float3(0.299, 0.587, 0.114)); }

/// SwiftUI の色はアルファ乗算済みなので、元に戻して使う
inline float4 unpremultiply(half4 c) {
    float a = float(c.a);
    return a > 0.001 ? float4(float3(c.rgb) / a, a) : float4(0);
}

inline half4 premultiply(float3 rgb, float a) {
    return half4(half3(saturate(rgb) * a), half(a));
}

} // namespace skinpreview

using namespace skinpreview;

[[stitchable]]
half4 previewSkinGold(float2 position, SwiftUI::Layer layer, float2 size, float time) {
    float2 uv = position / size;
    float4 face = unpremultiply(layer.sample(position));
    float l = luminance(face.rgb);
    float3 gold = mix(float3(0.42, 0.26, 0.04), float3(1.0, 0.86, 0.42), smoothstep(0.05, 0.95, l));
    float band = fract((uv.x + uv.y) * 0.7 - time * 0.6);
    float sheen = smoothstep(0.08, 0.0, abs(band - 0.5));
    return premultiply(gold + sheen * 0.7, face.a);
}

[[stitchable]]
half4 previewSkinNeon(float2 position, SwiftUI::Layer layer, float2 size, float time) {
    float2 uv = position / size;
    float4 face = unpremultiply(layer.sample(position));
    float d = 0.018 * size.x;
    float minAlpha = 1;
    for (int i = 0; i < 8; i++) {
        float angle = float(i) * M_PI_F / 4;
        minAlpha = min(minAlpha, float(layer.sample(position + float2(cos(angle), sin(angle)) * d).a));
    }
    float edge = saturate((face.a - minAlpha) * 2);
    float pulse = 0.75 + 0.25 * sin(time * 6);
    float3 neon = hsv(fract(time * 0.25 + uv.x * 0.3), 0.85, 1);
    return premultiply(face.rgb * 0.4 + neon * edge * 1.6 * pulse, face.a);
}

[[stitchable]]
half4 previewSkinRainbow(float2 position, SwiftUI::Layer layer, float2 size, float time) {
    float2 uv = position / size;
    float4 face = unpremultiply(layer.sample(position));
    float l = luminance(face.rgb);
    float3 rainbow = hsv(fract(uv.x * 0.8 + uv.y * 0.5 - time * 0.5), 0.75, 1) * (0.55 + 0.6 * l);
    return premultiply(mix(face.rgb, rainbow, 0.7), face.a);
}

[[stitchable]]
half4 previewSkinPixel(float2 position, SwiftUI::Layer layer, float2 size, float time) {
    float2 uv = position / size;
    float cells = 22;
    float2 cell = (floor(uv * cells) + 0.5) / cells;
    float4 face = unpremultiply(layer.sample(cell * size));
    float3 color = floor(face.rgb * 4 + 0.5) / 4;
    float2 inCell = fract(uv * cells);
    float grid = step(0.1, inCell.x) * step(0.1, inCell.y);
    return premultiply(color * (0.75 + 0.25 * grid), face.a > 0.5 ? 1 : 0);
}

[[stitchable]]
half4 previewSkinHologram(float2 position, SwiftUI::Layer layer, float2 size, float time) {
    float2 uv = position / size;
    float glitch = step(0.93, fract(sin(floor(time * 8) * 12.9898) * 43758.5453));
    uv.x += glitch * 0.02 * sin(uv.y * 60);
    float4 face = unpremultiply(layer.sample(uv * size));
    float l = luminance(face.rgb);
    float scan = 0.65 + 0.35 * sin(uv.y * 160 - time * 12);
    float flicker = 0.9 + 0.1 * sin(time * 37);
    float3 color = mix(float3(0.1, 0.55, 1.0), float3(0.6, 1.0, 1.0), l) * scan * flicker;
    float rim = smoothstep(0.25, 0.5, distance(uv, float2(0.5)));
    return premultiply(color + rim * float3(0.4, 0.2, 0.8), face.a);
}
