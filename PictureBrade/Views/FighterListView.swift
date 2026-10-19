//
//  FighterListView.swift
//  PictureBrade
//

import SwiftUI

/// アプリ同梱のファイター一覧
struct FighterListView: View {
    @Environment(BladeStore.self) private var store
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(store.starterBlades) { blade in
                    BladeCard(blade: blade, image: store.image(for: blade))
                }
            }
            .padding()
            Link("Photos provided by Pexels", destination: PexelsClient.homepage)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.bottom)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("ファイター")
        .navigationBarTitleDisplayMode(.inline)
    }
}
