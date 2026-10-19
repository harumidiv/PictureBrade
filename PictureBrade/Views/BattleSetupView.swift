//
//  BattleSetupView.swift
//  PictureBrade
//

import SwiftUI
import UIKit

struct BattleSetupView: View {
    @Environment(BladeStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var playerBlade: Blade?
    @State private var cpuBlade: Blade?
    @State private var battle: BattleGame?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    picker(title: "あなたのコマ", selection: $playerBlade)
                    picker(title: "対戦相手", selection: $cpuBlade)
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
                .disabled(playerBlade == nil || cpuBlade == nil)
                .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("バトル準備")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("戻る") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("相手をランダム", systemImage: "dice") {
                        cpuBlade = randomOpponent()
                    }
                }
            }
            .onAppear {
                playerBlade = playerBlade ?? store.blades.first
                cpuBlade = cpuBlade ?? randomOpponent()
            }
            .fullScreenCover(item: $battle) { game in
                BattleView(game: game)
            }
        }
    }

    private func picker(title: String, selection: Binding<Blade?>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.blades) { blade in
                        BladeCard(blade: blade, image: store.image(for: blade), isSelected: selection.wrappedValue?.id == blade.id)
                            .frame(width: 150)
                            .onTapGesture { selection.wrappedValue = blade }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    /// 自分以外の写真から選ぶ。1枚しかなければミラーマッチ
    private func randomOpponent() -> Blade? {
        store.blades.filter { $0.id != playerBlade?.id }.randomElement() ?? playerBlade
    }

    private func startBattle() {
        guard let playerBlade, let cpuBlade,
              let playerImage = store.image(for: playerBlade),
              let cpuImage = store.image(for: cpuBlade) else { return }
        battle = BattleGame(player: playerBlade, playerImage: playerImage, cpu: cpuBlade, cpuImage: cpuImage)
    }
}

extension BattleGame: Identifiable {}
