//
//  HomeView.swift
//  PictureBrade
//

import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(BladeStore.self) private var store
    @Environment(EnemyCatalog.self) private var enemies
    @Environment(GameCenterManager.self) private var gameCenter
    @State private var isAddingBlade = false
    @State private var battleMode: BattleGame.Mode?
    @State private var bladeToDelete: Blade?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    HStack(spacing: 12) {
                        modeButton(.story, title: "ストーリー", subtitle: "撃破 \(enemies.defeated.count)/\(EnemyCatalog.enemies.count)", systemImage: "book.fill", tint: Theme.accent)
                        modeButton(.endless, title: "ランダム連戦", subtitle: "最高 \(enemies.bestStreak)連勝", systemImage: "shuffle", tint: .purple)
                    }
                    .disabled(store.allBlades.isEmpty)

                    HStack {
                        Text("マイコマ（\(store.blades.count)）")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Button {
                            isAddingBlade = true
                        } label: {
                            Label("コマを作る", systemImage: "plus.circle.fill")
                        }
                        .tint(Theme.gold)
                    }

                    if store.blades.isEmpty {
                        emptyState
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(store.blades) { blade in
                            BladeCard(blade: blade, image: store.image(for: blade))
                                .contextMenu {
                                    Button("削除", systemImage: "trash", role: .destructive) {
                                        bladeToDelete = blade
                                    }
                                }
                        }
                    }

                    if !store.starterBlades.isEmpty {
                        fighters
                    }
                }
                .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("ランキング", systemImage: "trophy.fill") {
                        gameCenter.showEndlessLeaderboard()
                    }
                    .tint(Theme.gold)
                    .disabled(!gameCenter.isAuthenticated)
                }
            }
            .sheet(isPresented: $isAddingBlade) {
                AddBladeView()
            }
            .fullScreenCover(item: $battleMode) { mode in
                switch mode {
                case .story: StoryView()
                case .endless: EndlessSetupView()
                }
            }
            .confirmationDialog(
                "「\(bladeToDelete?.name ?? "")」を削除しますか？",
                isPresented: Binding(get: { bladeToDelete != nil }, set: { if !$0 { bladeToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    if let bladeToDelete { store.delete(bladeToDelete) }
                }
            }
        }
    }

    private func modeButton(_ mode: BattleGame.Mode, title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        Button {
            battleMode = mode
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title)
                Text(title)
                    .font(.headline.bold())
                Text(subtitle)
                    .font(.caption)
                    .opacity(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }

    /// アプリ同梱のファイター
    private var fighters: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ファイター（\(store.starterBlades.count)）")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                NavigationLink("すべて見る") {
                    FighterListView()
                }
                .tint(Theme.gold)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(store.starterBlades.prefix(20)) { blade in
                        BladeCard(blade: blade, image: store.image(for: blade))
                            .frame(width: 150)
                    }
                }
            }
            Link("Photos provided by Pexels", destination: PexelsClient.homepage)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var emptyState: some View {
        Button {
            isAddingBlade = true
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "person.crop.square.badge.camera")
                    .font(.system(size: 44))
                Text("まずは写真からコマを作ろう！")
                    .font(.headline)
                Text("写真アプリで被写体を長押し →「コピー」で切り抜けます")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8])))
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("PHOTO BLADE")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .italic()
                .foregroundStyle(LinearGradient(colors: [Theme.gold, Theme.accent], startPoint: .leading, endPoint: .trailing))
            Text("切り抜いた写真のコマで、文字を倒せ！")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, 8)
    }
}
