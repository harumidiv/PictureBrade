//
//  PexelsSearchView.swift
//  PictureBrade
//

import SwiftUI

/// Pexels で人物写真を探して選ぶ画面
struct PexelsSearchView: View {
    let onPick: (PexelsPhoto) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var query = PexelsClient.personQueries[0].query
    @State private var photos: [PexelsPhoto] = []
    @State private var page = 1
    @State private var hasMore = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let client = PexelsClient()
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    searchBar
                    presetChips
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(photos) { photo in
                            Button {
                                onPick(photo)
                                dismiss()
                            } label: {
                                PexelsThumbnail(photo: photo)
                            }
                        }
                    }
                    if isLoading {
                        ProgressView().tint(.white).padding()
                    } else if hasMore {
                        Button("もっと見る") {
                            Task { await load(reset: false) }
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    }
                    attribution
                }
                .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Pexelsで人物を探す")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .task {
                if photos.isEmpty { await load(reset: true) }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            TextField("検索ワード（英語がおすすめ）", text: $query)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit { Task { await load(reset: true) } }
            Button("検索") {
                Task { await load(reset: true) }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
        }
    }

    private var presetChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(PexelsClient.personQueries, id: \.query) { preset in
                    Button(preset.label) {
                        query = preset.query
                        Task { await load(reset: true) }
                    }
                    .buttonStyle(.bordered)
                    .tint(query == preset.query ? Theme.gold : .white)
                    .controlSize(.small)
                }
            }
        }
    }

    /// Pexels API ガイドラインに従い、Pexels へのリンクを目立つ位置に表示する
    private var attribution: some View {
        Link(destination: PexelsClient.homepage) {
            Text("Photos provided by Pexels")
                .font(.footnote.bold())
                .foregroundStyle(.white.opacity(0.8))
                .underline()
        }
        .padding(.top, 8)
    }

    private func load(reset: Bool) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let nextPage = reset ? 1 : page + 1
        do {
            let response = try await client.search(query: trimmed, page: nextPage)
            photos = reset ? response.photos : photos + response.photos
            page = nextPage
            hasMore = response.nextPage != nil
            if photos.isEmpty { errorMessage = PexelsClient.ClientError.noResults.localizedDescription }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct PexelsThumbnail: View {
    let photo: PexelsPhoto

    var body: some View {
        VStack(spacing: 2) {
            AsyncImage(url: photo.src.medium) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.white.opacity(0.08)
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(photo.photographer)
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

/// 撮影者クレジット（Pexels のガイドラインに沿って撮影者と写真ページへのリンクを表示）
struct CreditLabel: View {
    let credit: PhotoCredit

    var body: some View {
        Link(destination: credit.photoURL) {
            Text("Photo by \(credit.photographer) on \(credit.source)")
                .font(.caption2)
                .underline()
                .lineLimit(1)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}
