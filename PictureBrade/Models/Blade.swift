//
//  Blade.swift
//  PictureBrade
//

import SwiftUI
import UIKit

/// コマの性能。各値は 0...1。
nonisolated struct BladeStats: Codable, Hashable {
    var attack: Double
    var defense: Double
    var stamina: Double
    var speed: Double

    static let balanced = BladeStats(attack: 0.6, defense: 0.6, stamina: 0.6, speed: 0.6)

    var typeName: String {
        let values = [("アタック", attack), ("ディフェンス", defense), ("スタミナ", stamina), ("スピード", speed)]
        let sorted = values.sorted { $0.1 > $1.1 }
        if sorted[0].1 - sorted[3].1 < 0.12 { return "バランス" }
        return sorted[0].0
    }
}

nonisolated struct RGBColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double

    var color: Color { Color(red: red, green: green, blue: blue) }
    var uiColor: UIColor { UIColor(red: red, green: green, blue: blue, alpha: 1) }
}

nonisolated struct Blade: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var imageFileName: String
    var stats: BladeStats
    var tint: RGBColor
    var createdAt: Date
}
