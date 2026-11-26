//
//  AddBladeView.swift
//  PictureBrade
//

import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

/// iOSの切り抜き画像・写真・Pexels の人物写真からコマを作る
struct AddBladeView: View {
    @Environment(BladeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var photoItem: PhotosPickerItem?
    @State private var isShowingCamera = false
    @State private var capturedImage: UIImage?
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
        .fullScreenCover(isPresented: $isShowingCamera, onDismiss: processCapturedImage) {
            BladeCameraPicker { image in
                capturedImage = image
                isShowingCamera = false
            }
            .ignoresSafeArea()
        }
    }

    private var previewArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.06))
                .strokeBorder(.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8]))
            if isProcessing {
                ProgressView(String(localized: "切り抜き中…"))
                    .tint(.white)
                    .foregroundStyle(.white)
            } else if let preview, let analysis {
                VStack(spacing: 12) {
                    BladeBadge(image: preview, tint: analysis.tint.color, size: 160, spinning: true)
                    Text(analysis.stats.typeName + String(localized: "タイプ"))
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
                Task { await openCamera() }
            } label: {
                Label("カメラで撮影", systemImage: "camera")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .disabled(isProcessing || photoItem != nil)

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

    private func openCamera() async {
        let authorization = AVCaptureDevice.authorizationStatus(for: .video)
        if authorization == .denied, let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            openURL(settingsURL)
            return
        }

        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            errorMessage = String(localized: "カメラを使用できません。")
            return
        }

        switch authorization {
        case .authorized:
            isShowingCamera = true
        case .notDetermined:
            isShowingCamera = await AVCaptureDevice.requestAccess(for: .video)
        default:
            errorMessage = String(localized: "カメラを使用できません。")
        }
    }

    private func processCapturedImage() {
        guard let capturedImage else { return }
        self.capturedImage = nil
        Task { await process(capturedImage) }
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
            errorMessage = String(localized: "画像が見つかりませんでした")
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
            errorMessage = String(localized: "画像を処理できませんでした")
        }
    }
}

private struct BladeCameraPicker: UIViewControllerRepresentable {
    let onFinish: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onFinish: (UIImage?) -> Void

        init(onFinish: @escaping (UIImage?) -> Void) {
            self.onFinish = onFinish
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            onFinish(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onFinish(nil)
        }
    }
}
