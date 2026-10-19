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

    /// 文字から敵の「文字コマ」画像を作る（白い縁取り付き）
    static func renderText(_ text: String, color: UIColor) -> UIImage {
        render(text) { fontSize in
            let base = UIFont.systemFont(ofSize: fontSize, weight: .black)
            let font = base.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: fontSize) } ?? base
            return [
                .font: font,
                .foregroundColor: color,
                .strokeColor: UIColor.white,
                .strokeWidth: -4.0,
            ]
        }
    }

    /// 絵文字のコマ画像を作る（縁取りや丸ゴシック指定をすると描けないため素のフォントで描く）
    static func renderEmoji(_ emoji: String) -> UIImage {
        render(emoji) { fontSize in
            [.font: UIFont.systemFont(ofSize: fontSize)]
        }
    }

    private static func render(_ text: String, attributes: (CGFloat) -> [NSAttributedString.Key: Any]) -> UIImage {
        let size = CGSize(width: outputSize, height: outputSize)
        func attributedString(fontSize: CGFloat) -> NSAttributedString {
            NSAttributedString(string: text, attributes: attributes(fontSize))
        }
        // 枠に収まるまでフォントサイズを下げる
        var fontSize: CGFloat = 420
        var string = attributedString(fontSize: fontSize)
        while fontSize > 40 {
            let bounds = string.boundingRect(with: CGSize(width: 10_000, height: 10_000), options: [.usesLineFragmentOrigin], context: nil)
            if bounds.width <= size.width * 0.92 && bounds.height <= size.height * 0.92 { break }
            fontSize -= 20
            string = attributedString(fontSize: fontSize)
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let bounds = string.boundingRect(with: size, options: [.usesLineFragmentOrigin], context: nil)
            string.draw(at: CGPoint(x: (size.width - bounds.width) / 2, y: (size.height - bounds.height) / 2))
        }
        if let cgImage = rendered.cgImage, let trimmed = trimTransparentEdges(cgImage) {
            return squareFit(trimmed)
        }
        return rendered
    }

    /// 描いた結果に見える部分があるか（フォントが無く何も描けなかった文字を弾く）
    static func hasVisibleContent(_ image: UIImage) -> Bool {
        let n = 32
        guard let cgImage = image.cgImage, let pixels = BladeAnalyzer.rgbaPixels(cgImage, width: n, height: n) else { return false }
        var visible = 0
        for i in 0..<(n * n) where pixels[i * 4 + 3] > 128 { visible += 1 }
        return visible > 8
    }

    // MARK: - Analysis

    static func analyze(_ image: UIImage) -> Analysis {
        guard let cgImage = image.cgImage else {
            return Analysis(stats: .balanced, tint: BladeAnalyzer.defaultTint)
        }
        let result = BladeAnalyzer.analyze(cgImage)
        return Analysis(stats: result.stats, tint: result.tint)
    }

    // MARK: - Helpers

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

    private static func hasTransparency(_ image: CGImage) -> Bool {
        switch image.alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast: return false
        default: break
        }
        let n = 64
        guard let pixels = BladeAnalyzer.rgbaPixels(image, width: n, height: n) else { return false }
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
        guard let pixels = BladeAnalyzer.rgbaPixels(image, width: width, height: height) else { return nil }
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
