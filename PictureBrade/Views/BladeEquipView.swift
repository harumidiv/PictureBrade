//
//  BladeEquipView.swift
//  PictureBrade
//

import SwiftUI
import UIKit

/// マイコマやファイター一覧からコマをタップしたときに開く、そのコマの装備画面。
/// ガチャで手に入れたボディ・シャフトと、ストーリーの報酬（見た目・エフェクト・サウンド）をコマごとに選ぶ。
/// 上の 3D のコマと能力は固定で、下の一覧だけがスクロールする
struct BladeEquipView: View {
    let blade: Blade
    @Environment(PartsStore.self) private var parts
    @Environment(BladeStore.self) private var store
    @Environment(EnemyCatalog.self) private var enemies
    @Environment(CosmeticStore.self) private var cosmetics

    enum Category: String, CaseIterable, Identifiable {
        case body = "ボディ"
        case shaft = "シャフト"
        case skin = "見た目"
        case effect = "エフェクト"
        case sound = "サウンド"
        var id: Self { self }
    }

    @State private var category: Category = .body
    @State private var burst: EffectBurst?
    /// 開いたときに NEW だった報酬（見ている間は NEW を出し続ける）
    @State private var newOnOpen: Set<String> = []

    var body: some View {
        let equipment = parts.equipment(for: blade)
        let loadout = cosmetics.validatedLoadout(for: blade, enemies: enemies)
        VStack(spacing: 0) {
            header(equipment: equipment, loadout: loadout)
            ScrollView {
                VStack(spacing: 14) {
                    switch category {
                    case .body: partList(.body, equipped: equipment.body)
                    case .shaft: partList(.shaft, equipped: equipment.shaft)
                    case .skin: rewardList(BladeSkin.allCases.map(Reward.skin))
                    case .effect: rewardList(HitEffect.allCases.map(Reward.effect))
                    case .sound: rewardList(HitSound.allCases.map(Reward.sound))
                    }
                }
                .padding(16)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("\(blade.name)の装備")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                PointsLabel(points: parts.points, size: 13)
            }
            #if DEBUG
            ToolbarItem(placement: .topBarTrailing) {
                @Bindable var cosmetics = cosmetics
                Menu {
                    Toggle("報酬を全解放", isOn: $cosmetics.debugUnlockAll)
                    Button("+1000pt") { parts.debugAddPoints() }
                } label: {
                    Image(systemName: "ladybug.fill")
                }
                .tint(.orange)
            }
            #endif
        }
        .onAppear {
            ImpactSound.shared.prepare()
            newOnOpen = Set(cosmetics.newRewards(enemies: enemies).map(\.id))
            cosmetics.markAllSeen(enemies: enemies)
        }
    }

    // MARK: - 上の固定部分

    private func header(equipment: Equipment, loadout: Loadout) -> some View {
        VStack(spacing: 10) {
            BladePreview3D(
                image: store.image(for: blade),
                tint: blade.tint,
                equipment: equipment,
                skin: loadout.skin,
                aura: enemies.aura(for: blade),
                angle: category.previewAngle
            )
            .frame(height: 210)
            .overlay {
                // エフェクトを選んだときは、プレビューの上ではじけさせる
                if let burst {
                    EffectBurstView(burst: burst)
                        .id(burst.id)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    slotLabel("ボディ", part: equipment.body)
                    slotLabel("シャフト", part: equipment.shaft)
                }
                .padding(10)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .topLeading) {
                HStack(spacing: 6) {
                    loadoutChip(loadout.skin.title, systemImage: loadout.skin.systemImage)
                    loadoutChip(loadout.effect.title, systemImage: "sparkles")
                    loadoutChip(loadout.sound.title, systemImage: loadout.sound.systemImage)
                }
                .padding(10)
            }
            BonusStatsView(base: blade.stats, total: equipment.bonus.applied(to: blade.stats))
                .padding(.horizontal, 4)
            Picker("種類", selection: $category) {
                ForEach(Category.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color(red: 0.06, green: 0.04, blue: 0.15).opacity(0.9))
        .overlay(alignment: .bottom) {
            Rectangle().fill(.white.opacity(0.12)).frame(height: 1)
        }
    }

    private func slotLabel(_ title: String, part: Part) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 42, alignment: .leading)
            RarityTag(rarity: part.rarity)
            Text(part.name)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(.black.opacity(0.5)))
    }

    /// 装備中の見た目・エフェクト・サウンド。タップするとエフェクトと音を試せる
    private func loadoutChip(_ title: String, systemImage: String) -> some View {
        Button(action: playPreview) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(.black.opacity(0.5)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 一覧

    private func partList(_ kind: PartKind, equipped: Part) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(kind.caption + "。ホームの「ガチャ」で手に入る")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach(PartCatalog.parts(kind)) { part in
                    PartCard(part: part, isOwned: parts.isOwned(part), isEquipped: equipped == part) {
                        parts.equip(part, on: blade)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
        }
    }

    private func rewardList(_ rewards: [Reward]) -> some View {
        let unlockedCount = Reward.all.count { cosmetics.isUnlocked($0, enemies: enemies) }
        return VStack(alignment: .leading, spacing: 8) {
            Text("ストーリーで章のボスを倒すと、新しい報酬が手に入る！（\(unlockedCount)/\(Reward.all.count)）")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(rewards) { reward in
                    RewardCard(
                        reward: reward,
                        isUnlocked: cosmetics.isUnlocked(reward, enemies: enemies),
                        isEquipped: cosmetics.validatedLoadout(for: blade, enemies: enemies).contains(reward),
                        isNew: newOnOpen.contains(reward.id)
                    ) {
                        select(reward)
                    }
                }
            }
        }
    }

    private func select(_ reward: Reward) {
        guard cosmetics.isUnlocked(reward, enemies: enemies) else { return }
        cosmetics.equip(reward, on: blade)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch reward {
        case .skin: break
        case .effect, .sound: playPreview()
        }
    }

    /// 装備中のエフェクトと音で、ぶつかったときの様子を見せる
    private func playPreview() {
        let loadout = cosmetics.validatedLoadout(for: blade, enemies: enemies)
        burst = EffectBurst(effect: loadout.effect)
        ImpactSound.shared.play(strength: 2, isWall: false, style: loadout.sound)
    }
}

extension BladeEquipView.Category {
    /// 選んでいる種類がいちばん見やすいカメラの向き
    var previewAngle: PreviewAngle {
        switch self {
        case .body: .oblique
        case .shaft: .side
        case .skin, .effect, .sound: .top
        }
    }
}

extension Loadout {
    func contains(_ reward: Reward) -> Bool {
        switch reward {
        case .skin(let skin): self.skin == skin
        case .effect(let effect): self.effect == effect
        case .sound(let sound): self.sound == sound
        }
    }
}
