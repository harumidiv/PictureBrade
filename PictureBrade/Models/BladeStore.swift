//
//  BladeStore.swift
//  PictureBrade
//

import Foundation
import Observation
import UIKit

/// 作成したコマを Documents/Blades に保存・読み込みする。
@Observable
final class BladeStore {
    private(set) var blades: [Blade] = []

    @ObservationIgnored private var imageCache: [UUID: UIImage] = [:]
    @ObservationIgnored private let directory: URL
    @ObservationIgnored private var indexURL: URL { directory.appendingPathComponent("blades.json") }

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory = documents.appendingPathComponent("Blades", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        load()
    }

    func image(for blade: Blade) -> UIImage? {
        if let cached = imageCache[blade.id] { return cached }
        let url = directory.appendingPathComponent(blade.imageFileName)
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        imageCache[blade.id] = image
        return image
    }

    @discardableResult
    func add(name: String, image: UIImage) -> Blade? {
        guard let data = image.pngData() else { return nil }
        let analysis = BladeImageProcessor.analyze(image)
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
            createdAt: .now
        )
        imageCache[id] = image
        blades.insert(blade, at: 0)
        save()
        return blade
    }

    func delete(_ blade: Blade) {
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(blade.imageFileName))
        imageCache[blade.id] = nil
        blades.removeAll { $0.id == blade.id }
        save()
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
