//
//  RewardComponents.swift
//  PictureBrade
//

import SwiftUI
import UIKit

// ストーリーの報酬（見た目・エフェクト・サウンド）を装備画面で見せるための部品

// MARK: - 報酬カード

struct RewardCard: View {
    let reward: Reward
    let isUnlocked: Bool
    let isEquipped: Bool
    let isNew: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? Theme.accent.opacity(0.25) : .white.opacity(0.08))
                        .frame(width: 58, height: 58)
                    if isUnlocked {
                        RewardIcon(reward: reward, size: 28)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                Text(isUnlocked ? reward.title : "？？？")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                Text(isUnlocked ? reward.caption : reward.unlockDescription)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
                Text(isEquipped ? String(localized: "装備中") : (isUnlocked ? String(localized: "タップで装備") : String(localized: "まだ手に入れていない")))
                    .font(.caption2.bold())
                    .foregroundStyle(isEquipped ? .black : .white.opacity(0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(isEquipped ? Theme.gold : .white.opacity(0.1)))
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(red: 0.12, green: 0.08, blue: 0.26)))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(isEquipped ? Theme.gold : .white.opacity(0.12), lineWidth: isEquipped ? 3 : 1))
            .overlay(alignment: .topTrailing) {
                if isNew {
                    NewBadge().padding(8)
                }
            }
            .opacity(isUnlocked ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}

/// 報酬のアイコン（エフェクトは実際に飛び散る文字、ほかは SF Symbols）
struct RewardIcon: View {
    let reward: Reward
    var size: CGFloat = 24

    var body: some View {
        switch reward {
        case .effect(let effect):
            Text(effect.icon)
                .font(.glyph(size: size))
                .foregroundStyle(effect == .kanji ? Color.red : Color.pink)
        case .skin(let skin):
            Image(systemName: skin.systemImage)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(Theme.gold)
        case .sound(let sound):
            Image(systemName: sound.systemImage)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(.cyan)
        }
    }
}

struct NewBadge: View {
    var body: some View {
        Text("NEW")
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Theme.accent))
    }
}

extension Reward {
    var caption: String {
        switch self {
        case .skin(let skin): skin.caption
        case .effect(let effect): effect.caption
        case .sound(let sound): sound.caption
        }
    }
}

// MARK: - エフェクトのプレビュー

/// プレビューで1回ぶんはじけるエフェクト
struct EffectBurst: Identifiable {
    struct Particle: Identifiable {
        let id = UUID()
        let glyph: String
        let color: Color
        let angle: Double
        let distance: CGFloat
        let rotation: Double
    }

    let id = UUID()
    let effect: HitEffect
    let particles: [Particle]

    init(effect: HitEffect) {
        self.effect = effect
        let colors: [Color] = [.pink, .orange, .yellow, .green, .teal, .blue, .purple, .red]
        let count = effect == .sparks ? 22 : 12
        particles = (0..<count).map { index in
            Particle(
                glyph: effect.glyphs.randomElement() ?? "",
                color: effect == .kanji ? [.red, .orange, .yellow][index % 3] : colors[index % colors.count],
                angle: .random(in: 0..<(2 * .pi)),
                distance: .random(in: 70...110),
                rotation: .random(in: -60...60)
            )
        }
    }
}

struct EffectBurstView: View {
    let burst: EffectBurst
    @State private var fired = false

    var body: some View {
        ZStack {
            ForEach(burst.particles) { particle in
                particleView(particle)
                    .offset(
                        x: fired ? cos(particle.angle) * particle.distance : 0,
                        y: fired ? sin(particle.angle) * particle.distance : 0
                    )
                    .rotationEffect(.degrees(fired ? particle.rotation : 0))
                    .scaleEffect(fired ? 1 : 0.2)
                    .opacity(fired ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) { fired = true }
        }
    }

    @ViewBuilder
    private func particleView(_ particle: EffectBurst.Particle) -> some View {
        if burst.effect == .sparks {
            Capsule()
                .fill(LinearGradient(colors: [.white, .yellow, .orange], startPoint: .leading, endPoint: .trailing))
                .frame(width: 18, height: 4)
                .rotationEffect(.radians(particle.angle))
        } else if burst.effect.isTextGlyph {
            Text(particle.glyph)
                .font(.glyph(size: 30))
                .foregroundStyle(particle.color)
                .shadow(color: .white, radius: 0, x: 1, y: 1)
                .shadow(color: .white, radius: 0, x: -1, y: -1)
        } else {
            Text(particle.glyph)
                .font(.system(size: 30))
        }
    }
}
