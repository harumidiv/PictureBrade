//
//  CustomizeView.swift
//  PictureBrade
//

import SwiftUI
import UIKit

/// ストーリーの報酬（見た目・エフェクト・サウンド）を選ぶ画面。まだ手に入れていないものは鍵付きで、もらえる場所を出す
struct CustomizeView: View {
    @Environment(CosmeticStore.self) private var cosmetics
    @Environment(EnemyCatalog.self) private var enemies
    @Environment(\.dismiss) private var dismiss

    /// プレビューに使う自分のコマ
    let image: UIImage?
    let tint: Color

    enum Category: String, CaseIterable, Identifiable {
        case skin = "見た目"
        case effect = "エフェクト"
        case sound = "サウンド"
        var id: Self { self }
    }

    @State private var category: Category = .skin
    @State private var burst: EffectBurst?
    /// 開いたときに NEW だったもの（見ている間は NEW を出し続ける）
    @State private var newOnOpen: Set<String> = []

    private var rewards: [Reward] {
        switch category {
        case .skin: BladeSkin.allCases.map(Reward.skin)
        case .effect: HitEffect.allCases.map(Reward.effect)
        case .sound: HitSound.allCases.map(Reward.sound)
        }
    }

    private var unlockedCount: Int {
        Reward.all.count { cosmetics.isUnlocked($0, enemies: enemies) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    preview
                    Picker("種類", selection: $category) {
                        ForEach(Category.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Text("ストーリーで章のボスを倒すと、新しい報酬が手に入る！（\(unlockedCount)/\(Reward.all.count)）")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                        ForEach(rewards) { reward in
                            RewardCard(
                                reward: reward,
                                isUnlocked: cosmetics.isUnlocked(reward, enemies: enemies),
                                isEquipped: cosmetics.isEquipped(reward),
                                isNew: newOnOpen.contains(reward.id)
                            ) {
                                select(reward)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("カスタマイズ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                #if DEBUG
                ToolbarItem(placement: .primaryAction) {
                    @Bindable var cosmetics = cosmetics
                    Toggle(isOn: $cosmetics.debugUnlockAll) {
                        Label("全解放（デバッグ）", systemImage: "ladybug.fill")
                    }
                    .toggleStyle(.button)
                    .tint(.orange)
                }
                #endif
            }
        }
        .onAppear {
            ImpactSound.shared.prepare()
            newOnOpen = Set(cosmetics.newRewards(enemies: enemies).map(\.id))
            cosmetics.markAllSeen(enemies: enemies)
        }
    }

    // MARK: - プレビュー

    private var preview: some View {
        let loadout = cosmetics.loadout
        return ZStack {
            BladeBadge(image: image, tint: tint, size: 150, spinning: true, skin: loadout.skin)
            if let burst {
                EffectBurstView(burst: burst)
                    .id(burst.id)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 24).fill(.black.opacity(0.3)))
        .overlay(alignment: .bottom) {
            HStack(spacing: 14) {
                Label(loadout.skin.title, systemImage: loadout.skin.systemImage)
                Label(loadout.effect.title, systemImage: "sparkles")
                Label(loadout.sound.title, systemImage: loadout.sound.systemImage)
            }
            .font(.caption.bold())
            .foregroundStyle(.white.opacity(0.85))
            .padding(.bottom, 10)
        }
        .contentShape(Rectangle())
        .onTapGesture { playPreview() }
    }

    private func select(_ reward: Reward) {
        guard cosmetics.isUnlocked(reward, enemies: enemies) else { return }
        cosmetics.equip(reward)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch reward {
        case .skin: break
        case .effect, .sound: playPreview()
        }
    }

    /// 装備中のエフェクトと音で、ぶつかったときの様子を見せる
    private func playPreview() {
        burst = EffectBurst(effect: cosmetics.loadout.effect)
        ImpactSound.shared.play(strength: 2, isWall: false, style: cosmetics.loadout.sound)
    }
}

// MARK: - 報酬カード

private struct RewardCard: View {
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
                Text(isEquipped ? "装備中" : (isUnlocked ? "タップで装備" : "まだ手に入れていない"))
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
                .font(.system(size: size, weight: .black, design: .rounded))
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

private struct EffectBurstView: View {
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
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(particle.color)
                .shadow(color: .white, radius: 0, x: 1, y: 1)
                .shadow(color: .white, radius: 0, x: -1, y: -1)
        } else {
            Text(particle.glyph)
                .font(.system(size: 30))
        }
    }
}
