//
//  Aura.swift
//  PictureBrade
//

import SwiftUI
import UIKit
import simd

/// ランダム連戦で連勝したコマにつくオーラ（Game Center の連勝の実績と同じ区切り）
enum AuraTier: Int, CaseIterable, Comparable {
    case none = 0
    case bronze = 5
    case silver = 10
    case gold = 20
    case crimson = 50
    case rainbow = 100

    /// そのコマの最高連勝数から決める
    init(streak: Int) {
        self = Self.allCases.last { streak >= $0.rawValue } ?? .none
    }

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var requiredStreak: Int { rawValue }

    var title: String {
        switch self {
        case .none: ""
        case .bronze: String(localized: "ブロンズオーラ")
        case .silver: String(localized: "シルバーオーラ")
        case .gold: String(localized: "ゴールドオーラ")
        case .crimson: String(localized: "クリムゾンオーラ")
        case .rainbow: String(localized: "レジェンドオーラ")
        }
    }

    /// オーラの色（虹色のオーラは代表の色）
    var rgb: SIMD3<Float> {
        switch self {
        case .none: [1, 1, 1]
        case .bronze: [0.95, 0.55, 0.25]
        case .silver: [0.7, 0.85, 1.0]
        case .gold: [1.0, 0.82, 0.2]
        case .crimson: [1.0, 0.2, 0.25]
        case .rainbow: [1.0, 0.6, 1.0]
        }
    }

    var color: Color { Color(red: Double(rgb.x), green: Double(rgb.y), blue: Double(rgb.z)) }
    var uiColor: UIColor { UIColor(red: CGFloat(rgb.x), green: CGFloat(rgb.y), blue: CGFloat(rgb.z), alpha: 1) }

    var isRainbow: Bool { self == .rainbow }

    /// 3D のオーラの炎の高さ（強いオーラほど高く燃える）
    var flameHeight: Float {
        switch self {
        case .none: 0
        case .bronze: 0.12
        case .silver: 0.15
        case .gold: 0.19
        case .crimson: 0.23
        case .rainbow: 0.28
        }
    }

    /// AuraShaders.metal に渡す値（xyz が色、w が 1 なら虹色）
    var shaderParameter: SIMD4<Float> {
        SIMD4(rgb, isRainbow ? 1 : 0)
    }
}
