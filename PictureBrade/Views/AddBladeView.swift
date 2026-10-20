//
//  AddBladeView.swift
//  PictureBrade
//

import PhotosUI
import SwiftUI
import UIKit

/// iOSの切り抜き画像・写真・Pexels の人物写真からコマを作る
struct AddBladeView: View {
    @Environment(BladeStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var photoItem: PhotosPickerItem?
    @State private var preview: UIImage?
    @State private var isRoughCut = false
    @State private var name = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var credit: PhotoCredit?
    @State private var isSearchingPexels = false

    private var analysis: BladeImageProcessor.Analysis? {
        preview.map { BladeImageProcessor.analyze($0, isRoughCut: isRoughCut) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    previewArea
                    if preview != nil {
                        TextField("コマの名前", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    if let credit {
                        CreditLabel(credit: credit)
                    }
                    sources
                    StatGuideView()
                    howTo
                }
                .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("コマを作る")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let preview {
                            store.add(name: name, image: preview, isRoughCut: isRoughCut, credit: credit)
                            dismiss()
                        }
                    }
                    .disabled(preview == nil || isProcessing)
                }
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    let data = try? await item.loadTransferable(type: Data.self)
                    await process(data.flatMap(UIImage.init(data:)))
                    photoItem = nil
                }
            }
            .sheet(isPresented: $isSearchingPexels) {
                PexelsSearchView { photo in
                    Task { await process(pexels: photo) }
                }
            }
            .dropDestination(for: Data.self) { items, _ in
                guard let image = items.lazy.compactMap(UIImage.init(data:)).first else { return false }
                Task { await process(image) }
                return true
            }
        }
    }

    private var previewArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.06))
                .strokeBorder(.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8]))
            if isProcessing {
                ProgressView("切り抜き中…")
                    .tint(.white)
                    .foregroundStyle(.white)
            } else if let preview, let analysis {
                VStack(spacing: 12) {
                    BladeBadge(image: preview, tint: analysis.tint.color, size: 160, spinning: true)
                    Text(analysis.stats.typeName + "タイプ")
                        .font(.headline)
                        .foregroundStyle(Theme.gold)
                    StatsView(stats: analysis.stats)
                        .frame(maxWidth: 260)
                    if isRoughCut {
                        Label("うまく切り抜けなかったので性能ダウン…\n被写体がはっきり写った写真か、iOSの切り抜き機能を使うと本気の性能になるよ", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "scissors")
                        .font(.largeTitle)
                    Text("切り抜いた画像をここにドロップ\nまたは下から選んでね")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                }
                .foregroundStyle(.white.opacity(0.6))
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(8)
            }
        }
        .frame(height: 320)
    }

    private var sources: some View {
        VStack(spacing: 12) {
            Button {
                Task { await process(UIPasteboard.general.image) }
            } label: {
                Label("コピーした切り抜きを貼り付け", systemImage: "doc.on.clipboard")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("写真から自動で切り抜く", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.white)

            if PexelsClient.isConfigured {
                Button {
                    isSearchingPexels = true
                } label: {
                    Label("Pexelsで人物写真を探す", systemImage: "person.crop.rectangle.stack")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Theme.gold)
            }
        }
        .controlSize(.large)
    }

    private var howTo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("iOSの切り抜き機能の使い方")
                .font(.headline)
            Text("1. 写真アプリで被写体を長押し\n2. 「コピー」を選ぶ（またはそのままこの画面にドラッグ）\n3. 「コピーした切り抜きを貼り付け」をタップ")
                .font(.footnote)
        }
        .foregroundStyle(.white.opacity(0.85))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.06)))
    }

    private func process(pexels photo: PexelsPhoto) async {
        isProcessing = true
        errorMessage = nil
        do {
            let image = try await PexelsClient().downloadImage(for: photo)
            await process(image, credit: photo.credit)
        } catch {
            isProcessing = false
            errorMessage = error.localizedDescription
        }
    }

    private func process(_ image: UIImage?, credit newCredit: PhotoCredit? = nil) async {
        credit = newCredit
        guard let image else {
            errorMessage = "画像が見つかりませんでした"
            return
        }
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }
        do {
            let prepared = try await BladeImageProcessor.prepare(image)
            preview = prepared.image
            isRoughCut = prepared.isRoughCut
        } catch {
            errorMessage = "画像を処理できませんでした"
        }
    }
}
