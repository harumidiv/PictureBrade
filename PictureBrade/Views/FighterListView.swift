//
//  FighterListView.swift
//  PictureBrade
//

import SwiftUI

/// アプリ同梱のファイター一覧
struct FighterListView: View {
    @Environment(BladeStore.self) private var store
    @Environment(EnemyCatalog.self) private var enemies
    @Environment(PartsStore.self) private var parts
    /// タップして装備画面を開いたコマ
    @State private var equippingBlade: Blade?
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(store.starterBlades) { blade in
                    BladeCard(blade: blade, image: store.image(for: blade), bestStreak: enemies.bestStreak(for: blade),
                              stats: parts.equipped(blade).stats)
                        .contentShape(Rectangle())
                        .onTapGesture { equippingBlade = blade }
                }
            }
            .padding()
            Link("Photos provided by Pexels", destination: PexelsClient.homepage)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.bottom)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationDestination(item: $equippingBlade) { blade in
            BladeEquipView(blade: blade)
        }
        .navigationTitle("ファイター")
        .navigationBarTitleDisplayMode(.inline)
    }
}
