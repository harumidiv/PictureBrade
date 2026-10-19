//
//  BladeAnalyzer.swift
//  PictureBrade
//

import CoreGraphics
import Foundation

// 取り込みツール（tools/FetchStarterBlades）からもコンパイルされるため、UIKit に依存させないこと。

/// 切り抜き画像の形と色からステータスを算出する。
/// - トゲトゲ（周長が長い）ほど攻撃力が高い
/// - 面積が大きい（ずんぐり）ほど防御力が高い
/// - 回転したときの空気抵抗が少ない（円盤に近い）ほど持久力が高い
/// - 色が鮮やかなほど機動力が高い
nonisolated enum BladeAnalyzer {
    static let defaultTint = RGBColor(red: 0.5, green: 0.5, blue: 0.6)

    static func analyze(_ image: CGImage) -> (stats: BladeStats, tint: RGBColor) {
        let n = 64
        guard let pixels = rgbaPixels(image, width: n, height: n) else {
            return (.balanced, defaultTint)
        }
        var mask = [Bool](repeating: false, count: n * n)
        var area = 0
        var sumR = 0.0, sumG = 0.0, sumB = 0.0, sumSaturation = 0.0
        for i in 0..<(n * n) {
            let a = Double(pixels[i * 4 + 3]) / 255
            guard a > 0.5 else { continue }
            mask[i] = true
            area += 1
            // premultiplied なので alpha で割り戻す
            let r = Double(pixels[i * 4]) / 255 / a
            let g = Double(pixels[i * 4 + 1]) / 255 / a
            let b = Double(pixels[i * 4 + 2]) / 255 / a
            sumR += r; sumG += g; sumB += b
            let maxC = max(r, g, b), minC = min(r, g, b)
            sumSaturation += maxC > 0 ? (maxC - minC) / maxC : 0
        }
        guard area > 20 else {
            return (.balanced, defaultTint)
        }

        var perimeter = 0
        var sumX = 0.0, sumY = 0.0
        for y in 0..<n {
            for x in 0..<n where mask[y * n + x] {
                let neighbors = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
                if neighbors.contains(where: { $0.0 < 0 || $0.0 >= n || $0.1 < 0 || $0.1 >= n || !mask[$0.1 * n + $0.0] }) {
                    perimeter += 1
                }
                sumX += Double(x)
                sumY += Double(y)
            }
        }

        // 回転軸（重心）から一番遠い点までの距離 = 回ったときに描く円の半径
        let centerX = sumX / Double(area), centerY = sumY / Double(area)
        var maxRadiusSquared = 0.0
        for y in 0..<n {
            for x in 0..<n where mask[y * n + x] {
                let dx = Double(x) + 0.5 - centerX, dy = Double(y) + 0.5 - centerY
                maxRadiusSquared = max(maxRadiusSquared, dx * dx + dy * dy)
            }
        }
        // 回転円の中が埋まっているほど（円盤に近いほど）空気抵抗が少ない。
        // 細長い形や外に飛び出したトゲは空気をかき回すので抵抗が大きい
        let sweptArea = Double.pi * max(maxRadiusSquared, 1)
        let fillRatio = min(1, Double(area) / sweptArea)

        let compactness = Double(perimeter) / Double(area).squareRoot()
        let attack = clamp((compactness - 3.2) / 5.0)
        let defense = clamp((Double(area) / Double(n * n) - 0.2) / 0.6)
        let stamina = clamp((fillRatio - 0.15) / 0.65)
        let speed = clamp(sumSaturation / Double(area) / 0.7)

        // 合計値を揃えて、どの画像でも極端に強くならないようにする
        let raw = [attack, defense, stamina, speed].map { 0.25 + $0 }
        let scale = 2.6 / raw.reduce(0, +)
        let fair = raw.map { min(1.0, max(0.2, $0 * scale)) }

        let tint = RGBColor(red: sumR / Double(area), green: sumG / Double(area), blue: sumB / Double(area))
        return (BladeStats(attack: fair[0], defense: fair[1], stamina: fair[2], speed: fair[3]), tint)
    }

    static func rgbaPixels(_ image: CGImage, width: Int, height: Int) -> [UInt8]? {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let ok = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return ok ? pixels : nil
    }

    private static func clamp(_ value: Double) -> Double { min(1, max(0, value)) }
}
