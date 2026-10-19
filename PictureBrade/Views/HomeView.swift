//
//  HomeView.swift
//  PictureBrade
//

import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(BladeStore.self) private var store
    @State private var isAddingBlade = false
    @State private var isSettingUpBattle = false
    @State private var bladeToDelete: Blade?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    Button {
                        isSettingUpBattle = true
                    } label: {
                        Label("バトル開始", systemImage: "bolt.fill")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .disabled(store.blades.isEmpty)

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
                }
                .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .sheet(isPresented: $isAddingBlade) {
                AddBladeView()
            }
            .fullScreenCover(isPresented: $isSettingUpBattle) {
                BattleSetupView()
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
            Text("切り抜いた写真がコマになる！")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, 8)
    }
}
