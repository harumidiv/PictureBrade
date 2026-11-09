//
//  GlyphFont.swift
//  PictureBrade
//

import SwiftUI
import UIKit

// 敵のコマ・エフェクト・背景などで、漢字やかなを大きく描くときのフォント。
// 日本語以外の言語の設定だと、システムのフォントだけでは漢字・かなが描けず「?」の四角になる環境があるため、
// ヒラギノを代わりのフォントとして明示しておく（英字や数字はこれまでどおり丸ゴシックで描く）

extension UIFont {
    /// 丸ゴシックの太字に、漢字・かな用のヒラギノを補ったフォント
    nonisolated static func glyphFont(size: CGFloat, weight: UIFont.Weight = .black) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        let rounded = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
        let japanese = UIFontDescriptor(name: weight >= .semibold ? "HiraginoSans-W7" : "HiraginoSans-W3", size: size)
        return UIFont(descriptor: rounded.addingAttributes([.cascadeList: [japanese]]), size: size)
    }
}

extension Font {
    /// SwiftUI で漢字・かなを大きく描くときのフォント（UIFont.glyphFont と同じ）
    nonisolated static func glyph(size: CGFloat, weight: UIFont.Weight = .black) -> Font {
        Font(UIFont.glyphFont(size: size, weight: weight))
    }
}
