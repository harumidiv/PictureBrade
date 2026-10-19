//
//  BladeImageProcessor.swift
//  PictureBrade
//

import CoreImage
import UIKit
import Vision

/// 画像をコマ用の「切り抜き画像」に整え、形や色から性能を算出する。
nonisolated enum BladeImageProcessor {
    static let outputSize: CGFloat = 512

    enum ProcessingError: Error {
        case invalidImage
    }

    struct Analysis {
        var stats: BladeStats
        var tint: RGBColor
    }

    // MARK: - Preparation

    /// 透過画像（iOSの「被写体を持ち上げる」でコピーしたもの等）はそのまま、
    /// 背景のある写真は Vision で被写体を自動切り抜きする。
    static func prepare(_ image: UIImage) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) {
            let upright = redraw(image, maxDimension: 1024)
            guard let cgImage = upright.cgImage else { throw ProcessingError.invalidImage }

            let cutout: CGImage
            if hasTransparency(cgImage) {
                cutout = cgImage
            } else if let lifted = liftSubject(from: cgImage) {
                cutout = lifted
            } else {
                // 被写体が見つからない場合は丸く切り抜いて使う
                cutout = circleCrop(cgImage)
            }
            guard let trimmed = trimTransparentEdges(cutout) else { throw ProcessingError.invalidImage }
            return squareFit(trimmed)
        }.value
    }

    // MARK: - Analysis

    /// 形と色からステータスを算出する。
    /// - トゲトゲ（周長が長い）ほど攻撃力が高い
    /// - 面積が大きい（ずんぐり）ほど防御力が高い
    /// - 左右上下対称ほど持久力が高い
    /// - 色が鮮やかなほど機動力が高い
    static func analyze(_ image: UIImage) -> Analysis {
        let n = 64
        guard let cg = image.cgImage, let pixels = rgbaPixels(cg, width: n, height: n) else {
            return Analysis(stats: .balanced, tint: RGBColor(red: 0.5, green: 0.5, blue: 0.6))
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
            return Analysis(stats: .balanced, tint: RGBColor(red: 0.5, green: 0.5, blue: 0.6))
        }

        var perimeter = 0
        var mirrorMatches = 0
        for y in 0..<n {
            for x in 0..<n where mask[y * n + x] {
                let neighbors = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
                if neighbors.contains(where: { $0.0 < 0 || $0.0 >= n || $0.1 < 0 || $0.1 >= n || !mask[$0.1 * n + $0.0] }) {
                    perimeter += 1
                }
                if mask[y * n + (n - 1 - x)] { mirrorMatches += 1 }
                if mask[(n - 1 - y) * n + x] { mirrorMatches += 1 }
            }
        }

        let compactness = Double(perimeter) / Double(area).squareRoot()
        let attack = clamp((compactness - 3.2) / 5.0)
        let defense = clamp((Double(area) / Double(n * n) - 0.2) / 0.6)
        let stamina = clamp((Double(mirrorMatches) / Double(area * 2) - 0.55) / 0.45)
        let speed = clamp(sumSaturation / Double(area) / 0.7)

        // 合計値を揃えて、どの画像でも極端に強くならないようにする
        let raw = [attack, defense, stamina, speed].map { 0.25 + $0 }
        let scale = 2.6 / raw.reduce(0, +)
        let fair = raw.map { min(1.0, max(0.2, $0 * scale)) }

        let tint = RGBColor(red: sumR / Double(area), green: sumG / Double(area), blue: sumB / Double(area))
        return Analysis(
            stats: BladeStats(attack: fair[0], defense: fair[1], stamina: fair[2], speed: fair[3]),
            tint: tint
        )
    }

    // MARK: - Helpers

    private static func clamp(_ value: Double) -> Double { min(1, max(0, value)) }

    private static func redraw(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, maxDimension / max(longest, 1))
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private static func rgbaPixels(_ image: CGImage, width: Int, height: Int) -> [UInt8]? {
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

    private static func hasTransparency(_ image: CGImage) -> Bool {
        switch image.alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast: return false
        default: break
        }
        let n = 64
        guard let pixels = rgbaPixels(image, width: n, height: n) else { return false }
        var transparent = 0
        for i in 0..<(n * n) where pixels[i * 4 + 3] < 128 { transparent += 1 }
        return Double(transparent) / Double(n * n) > 0.05
    }

    private static func liftSubject(from image: CGImage) -> CGImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first, !observation.allInstances.isEmpty else { return nil }
            let buffer = try observation.generateMaskedImage(
                ofInstances: observation.allInstances, from: handler, croppedToInstancesExtent: true
            )
            let ciImage = CIImage(cvPixelBuffer: buffer)
            return CIContext().createCGImage(ciImage, from: ciImage.extent)
        } catch {
            return nil
        }
    }

    private static func circleCrop(_ image: CGImage) -> CGImage {
        let side = min(image.width, image.height)
        let size = CGSize(width: side, height: side)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let rect = CGRect(origin: .zero, size: size)
            UIBezierPath(ovalIn: rect).addClip()
            let source = UIImage(cgImage: image)
            let drawRect = CGRect(
                x: (CGFloat(side) - CGFloat(image.width)) / 2,
                y: (CGFloat(side) - CGFloat(image.height)) / 2,
                width: CGFloat(image.width), height: CGFloat(image.height)
            )
            source.draw(in: drawRect)
        }
        return rendered.cgImage ?? image
    }

    private static func trimTransparentEdges(_ image: CGImage) -> CGImage? {
        let width = image.width, height = image.height
        guard let pixels = rgbaPixels(image, width: width, height: height) else { return nil }
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            for x in 0..<width where pixels[(y * width + x) * 4 + 3] > 16 {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX >= minX, maxY >= minY else { return nil }
        let rect = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        return image.cropping(to: rect)
    }

    private static func squareFit(_ image: CGImage) -> UIImage {
        let side = outputSize
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let w = CGFloat(image.width), h = CGFloat(image.height)
        let scale = side * 0.96 / max(w, h)
        let drawSize = CGSize(width: w * scale, height: h * scale)
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            UIImage(cgImage: image).draw(in: CGRect(
                x: (side - drawSize.width) / 2, y: (side - drawSize.height) / 2,
                width: drawSize.width, height: drawSize.height
            ))
        }
    }
}
