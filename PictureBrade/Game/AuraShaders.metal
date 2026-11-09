//
//  AuraShaders.metal
//  PictureBrade
//
//  連勝したコマの足元から立ちのぼるオーラの炎（RealityKit のサーフェスシェーダー）。
//  メッシュは半径1・高さ1（y = 0〜1）の筒で、エンティティの拡大率で大きさを合わせる。
//  色は custom_parameter（xyz が色、w が 1 なら虹色）で受け取る。
//

#include <metal_stdlib>
#include <RealityKit/RealityKit.h>
using namespace metal;

namespace aura {

inline float3 hsv(float h, float s, float v) {
    float3 k = clamp(abs(fract(h + float3(0, 2.0 / 3.0, 1.0 / 3.0)) * 6 - 3) - 1, 0, 1);
    return v * mix(float3(1), k, s);
}

} // namespace aura

[[visible]]
void bladeAura(realitykit::surface_parameters params) {
    float3 position = params.geometry().model_position();
    float time = params.uniforms().time();
    float4 parameter = params.uniforms().custom_parameter();

    float height = saturate(position.y);
    float angle = atan2(position.z, position.x);

    // ゆらめく炎の舌：角度と高さで波を重ね、上に流していく
    float wave = 0.5 + 0.5 * sin(angle * 6 + time * 4 - height * 9);
    float wave2 = 0.5 + 0.5 * sin(angle * 11 - time * 6 - height * 14);
    float tongues = mix(wave, wave2, 0.4);
    // 上に行くほど薄く、炎の舌の部分だけが高く伸びる
    float fade = pow(1 - height, 1.4);
    float reach = smoothstep(0.0, 0.5, fade + (tongues - 0.5) * 0.6 * height);
    float pulse = 0.85 + 0.15 * sin(time * 5);
    float alpha = reach * fade * (0.55 + 0.45 * tongues) * pulse * smoothstep(0.0, 0.06, height);

    float3 color = parameter.xyz;
    if (parameter.w > 0.5) {
        color = aura::hsv(fract(angle / (2 * M_PI_F) + time * 0.25 + height * 0.4), 0.7, 1);
    }
    // 根元ほど白っぽく熱く光る
    color = mix(color, float3(1), (1 - height) * 0.35);

    auto surface = params.surface();
    surface.set_base_color(half3(0));
    surface.set_emissive_color(half3(saturate(color)));
    surface.set_roughness(1);
    surface.set_metallic(0);
    surface.set_specular(0);
    surface.set_opacity(half(saturate(alpha)));
}
