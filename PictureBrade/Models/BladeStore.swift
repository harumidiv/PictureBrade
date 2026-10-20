//
//  BladeStore.swift
//  PictureBrade
//

import Foundation
import Observation
import UIKit

/// 作成したコマを Documents/Blades に保存・読み込みする。
/// あわせて、アプリに同梱されたファイター（StarterBlades）も提供する。
@Observable
final class BladeStore {
    /// ユーザーが作成したコマ
    private(set) var blades: [Blade] = []
    /// アプリ同梱のファイター（tools/FetchStarterBlades で生成）
    let starterBlades: [Blade]

    var allBlades: [Blade] { blades + starterBlades }

    /// 同梱ファイターを一覧で表示しても溜まり続けないよう NSCache を使う
    @ObservationIgnored private let imageCache = NSCache<NSUUID, UIImage>()
    @ObservationIgnored private let directory: URL
    @ObservationIgnored private var indexURL: URL { directory.appendingPathComponent("blades.json") }

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory = documents.appendingPathComponent("Blades", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        starterBlades = Self.loadStarterBlades()
        load()
    }

    func image(for blade: Blade) -> UIImage? {
        if let cached = imageCache.object(forKey: blade.id as NSUUID) { return cached }
        let userFile = directory.appendingPathComponent(blade.imageFileName)
        let bundledFile = Bundle.main.url(forResource: blade.imageFileName, withExtension: nil)
        guard let image = UIImage(contentsOfFile: userFile.path) ?? bundledFile.flatMap({ UIImage(contentsOfFile: $0.path) }) else {
            return nil
        }
        imageCache.setObject(image, forKey: blade.id as NSUUID)
        return image
    }

    @discardableResult
    func add(name: String, image: UIImage, isRoughCut: Bool = false, credit: PhotoCredit? = nil) -> Blade? {
        guard let data = image.pngData() else { return nil }
        let analysis = BladeImageProcessor.analyze(image, isRoughCut: isRoughCut)
        let id = UUID()
        let fileName = "\(id.uuidString).png"
        do {
            try data.write(to: directory.appendingPathComponent(fileName))
        } catch {
            return nil
        }
        let blade = Blade(
            id: id,
            name: name.isEmpty ? "ノーネーム" : name,
            imageFileName: fileName,
            stats: analysis.stats,
            tint: analysis.tint,
            createdAt: .now,
            credit: credit
        )
        imageCache.setObject(image, forKey: id as NSUUID)
        blades.insert(blade, at: 0)
        save()
        return blade
    }

    func delete(_ blade: Blade) {
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(blade.imageFileName))
        imageCache.removeObject(forKey: blade.id as NSUUID)
        blades.removeAll { $0.id == blade.id }
        save()
    }

    private static func loadStarterBlades() -> [Blade] {
        guard let url = Bundle.main.url(forResource: "starter-blades", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Blade].self, from: data) else { return [] }
        return decoded
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([Blade].self, from: data) else { return }
        blades = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(blades) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}
