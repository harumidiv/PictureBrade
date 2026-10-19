//
//  EndlessSetupView.swift
//  PictureBrade
//

import SwiftUI
import UIKit

/// ランダム連戦の準備画面
struct EndlessSetupView: View {
    @Environment(BladeStore.self) private var store
    @Environment(EnemyCatalog.self) private var enemies
    @Environment(\.dismiss) private var dismiss

    @State private var playerBlade: Blade?
    @State private var battle: BattleGame?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PlayerBladePicker(selection: $playerBlade)
                    info
                }
                .padding(.vertical)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    startBattle()
                } label: {
                    Text("3, 2, 1, ゴーシュート！")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .disabled(playerBlade == nil)
                .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("ランダム連戦")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("戻る") { dismiss() }
                }
            }
            .fullScreenCover(item: $battle) { game in
                BattleView(game: game)
            }
        }
    }

    private var info: some View {
        VStack(spacing: 14) {
            Text("？")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(Theme.gold)
                .frame(width: 110, height: 110)
                .background(Circle().fill(.white.opacity(0.1)))
            Text("漢字・ひらがな・カタカナ・絵文字・記号から\nランダムな相手が次々に現れる！")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            Text("5連勝ごとに相手が強くなる。負けたら終了")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Label("最高記録 \(enemies.bestStreak)連勝", systemImage: "trophy.fill")
                .font(.headline)
                .foregroundStyle(Theme.gold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.08)))
        .padding(.horizontal)
    }

    private func startBattle() {
        guard let playerBlade, let playerImage = store.image(for: playerBlade) else { return }
        let opponent = enemies.randomEnemy(level: 1)
        battle = BattleGame(
            player: playerBlade, playerImage: playerImage,
            cpu: enemies.blade(for: opponent), cpuImage: enemies.image(for: opponent),
            cpuSkill: opponent.skill, mode: .endless
        )
    }
}
