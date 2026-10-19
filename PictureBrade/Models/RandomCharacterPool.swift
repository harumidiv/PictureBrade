//
//  RandomCharacterPool.swift
//  PictureBrade
//

import CoreText
import Foundation
import UIKit

/// ランダム連戦で出てくる文字の候補。一覧を手で持たず、文字コードから集める
nonisolated enum RandomCharacterPool {
    /// JIS 第1水準漢字（日常でよく使う漢字 約3,000字）。Shift_JIS の 0x889F〜0x9872
    static let kanji: [String] = {
        var result: [String] = []
        for lead in UInt8(0x88)...UInt8(0x98) {
            for trail in UInt8(0x40)...UInt8(0xFC) where trail != 0x7F {
                let code = UInt16(lead) << 8 | UInt16(trail)
                guard code >= 0x889F, code <= 0x9872,
                      let character = String(data: Data([lead, trail]), encoding: .shiftJIS),
                      character.count == 1 else { continue }
                result.append(character)
            }
        }
        return result
    }()

    /// ひらがな・カタカナ（小書き文字は除く）
    static let kana: [String] = {
        let small: Set<Character> = ["ぁ", "ぃ", "ぅ", "ぇ", "ぉ", "っ", "ゃ", "ゅ", "ょ", "ゎ",
                                     "ァ", "ィ", "ゥ", "ェ", "ォ", "ッ", "ャ", "ュ", "ョ", "ヮ", "ヵ", "ヶ"]
        let ranges: [ClosedRange<UInt32>] = [0x3041...0x3093, 0x30A1...0x30F6]
        return ranges.flatMap { $0 }
            .compactMap(Unicode.Scalar.init)
            .map(Character.init)
            .filter { !small.contains($0) }
            .map(String.init)
    }()

    /// 絵文字として表示される文字（1文字で表せるもの）
    static let emoji: [String] = {
        let ranges: [ClosedRange<UInt32>] = [0x2600...0x27BF, 0x1F300...0x1F5FF, 0x1F600...0x1F64F, 0x1F680...0x1F6FF, 0x1F900...0x1FAFF]
        return ranges.flatMap { $0 }
            .compactMap(Unicode.Scalar.init)
            .filter { $0.properties.isEmojiPresentation }
            .map { String(Character($0)) }
    }()

    static let symbols: [String] = {
        let latin = (UInt32(0x41)...UInt32(0x5A)).compactMap(Unicode.Scalar.init).map { String(Character($0)) }
        let digits = (0...9).map(String.init)
        return latin + digits + ["★", "☆", "♠", "♣", "♥", "♦", "♪", "＠", "＆", "＃", "％", "※", "〒", "∞", "Ω"]
    }()

    /// この端末で絵文字をカラーで描けるか。
    /// 絵文字フォントが使えない環境（一部のシミュレーター等）では「?」入りの四角が描かれてしまうため、
    /// 黄色い 😀 を試しに描いて、黄色い画素が出るかで判定する
    static let canRenderEmoji: Bool = {
        let size = CGSize(width: 32, height: 32)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            NSAttributedString(string: "😀", attributes: [.font: UIFont.systemFont(ofSize: 26)])
                .draw(at: CGPoint(x: 1, y: 1))
        }
        guard let cgImage = image.cgImage,
              let pixels = BladeAnalyzer.rgbaPixels(cgImage, width: 32, height: 32) else { return false }
        var yellow = 0
        for i in 0..<(32 * 32) {
            let r = Int(pixels[i * 4]), g = Int(pixels[i * 4 + 1]), b = Int(pixels[i * 4 + 2])
            if r > 180 && g > 140 && b < 100 { yellow += 1 }
        }
        return yellow > 20
    }()

    /// ランダムに1文字選ぶ。表示できない文字（□になる文字）は引き直す
    static func random() -> (character: String, isEmoji: Bool) {
        while true {
            let roll = Double.random(in: 0..<1)
            let (pool, isEmoji): ([String], Bool) = switch roll {
            case ..<0.45: (kanji, false)
            case ..<0.60: (kana, false)
            case ..<0.90: (canRenderEmoji ? emoji : kanji, canRenderEmoji)
            default: (symbols, false)
            }
            guard let character = pool.randomElement() else { continue }
            if isRenderable(character) {
                return (character, isEmoji)
            }
        }
    }

    /// フォントの代替を含めて描画できるか（どのフォントにもない文字は LastResort になる）
    static func isRenderable(_ text: String) -> Bool {
        let base = UIFont.systemFont(ofSize: 40) as CTFont
        let font = CTFontCreateForString(base, text as CFString, CFRange(location: 0, length: (text as NSString).length))
        return (CTFontCopyPostScriptName(font) as String) != "LastResort"
    }
}
