//
//  main.swift
//  MakeAchievementImages
//
//  Game Center の実績画像（連勝・ストーリークリア。1024×1024 の PNG、透明なし）を作る。
//  色はアプリのオーラ（PictureBrade/Models/Aura.swift）とそろえてある。
//
//  使い方：swift tools/MakeAchievementImages/main.swift [出力先フォルダ]
//  （出力先を省略すると AppStoreAssets/Achievements に書き出す）
//

import AppKit
import CoreText

struct Tier {
    let id: String
    let color: (CGFloat, CGFloat, CGFloat)
    let isRainbow: Bool
    /// 外側の光の筋の数（強い実績ほど多い）
    let rays: Int
    let stars: Int
    /// メダルの真ん中に大きく描く文字（連勝数、またはストーリーを表す文字）
    let symbol: String
    let symbolSize: CGFloat
    /// 文字のふちの太さ（画数の多い漢字は細くしないとつぶれる）
    let symbolStroke: CGFloat
    /// 絵文字はふちを付けずにそのまま描く
    let isEmoji: Bool
    /// 下に添える言葉
    let caption: String
}

/// ランダム連戦の連勝
func streakTier(_ streak: Int, color: (CGFloat, CGFloat, CGFloat), isRainbow: Bool = false, rays: Int, stars: Int) -> Tier {
    Tier(id: "photoblade.endless.streak\(streak)", color: color, isRainbow: isRainbow, rays: rays, stars: stars,
         symbol: "\(streak)", symbolSize: streak >= 100 ? 270 : 330, symbolStroke: 16, isEmoji: false, caption: "連勝")
}

/// ストーリーのクリア。ID は GameCenterManager.storyAchievementID と同じ（StoryKind の rawValue）
func storyTier(_ story: String, symbol: String, size: CGFloat, stroke: CGFloat = 16, color: (CGFloat, CGFloat, CGFloat), isEmoji: Bool = false) -> Tier {
    Tier(id: "photoblade.story.\(story)", color: color, isRainbow: false, rays: 20, stars: 3,
         symbol: symbol, symbolSize: size, symbolStroke: stroke, isEmoji: isEmoji, caption: "クリア")
}

let tiers = [
    streakTier(5, color: (0.95, 0.55, 0.25), rays: 12, stars: 1),
    streakTier(10, color: (0.7, 0.85, 1.0), rays: 14, stars: 2),
    streakTier(20, color: (1.0, 0.82, 0.2), rays: 16, stars: 3),
    streakTier(50, color: (1.0, 0.2, 0.25), rays: 18, stars: 4),
    streakTier(100, color: (1.0, 0.6, 1.0), isRainbow: true, rays: 24, stars: 5),
    // 漢字は最後の敵「覇」、ひらがなは「あ」、絵文字は宇宙の果ての母船
    storyTier("kanji", symbol: "覇", size: 290, stroke: 7, color: (0.85, 0.25, 0.2)),
    storyTier("hiragana", symbol: "あ", size: 320, color: (1.0, 0.5, 0.72)),
    storyTier("emoji", symbol: "🛸", size: 460, color: (0.35, 0.85, 0.55), isEmoji: true),
]

let side: CGFloat = 1024
let center = CGPoint(x: side / 2, y: side / 2)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

func mix(_ c: (CGFloat, CGFloat, CGFloat), with other: (CGFloat, CGFloat, CGFloat), _ t: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
    (c.0 + (other.0 - c.0) * t, c.1 + (other.1 - c.1) * t, c.2 + (other.2 - c.2) * t)
}

func hsv(_ h: CGFloat, _ s: CGFloat, _ v: CGFloat) -> CGColor {
    NSColor(hue: h, saturation: s, brightness: v, alpha: 1).cgColor
}

func radialGradient(_ ctx: CGContext, colors: [CGColor], locations: [CGFloat], radius: CGFloat) {
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: locations)!
    ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [.drawsAfterEndLocation])
}

/// 中心を通る円を塗る
func fillCircle(_ ctx: CGContext, radius: CGFloat, color: CGColor) {
    ctx.setFillColor(color)
    ctx.fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
}

/// 円形に切り抜いてから描く
func clipped(_ ctx: CGContext, radius: CGFloat, _ draw: () -> Void) {
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    ctx.clip()
    draw()
    ctx.restoreGState()
}

func star(_ ctx: CGContext, at point: CGPoint, radius: CGFloat, color: CGColor) {
    let path = CGMutablePath()
    for i in 0..<10 {
        let angle = CGFloat(i) * .pi / 5 + .pi / 2
        let r = i.isMultiple(of: 2) ? radius : radius * 0.45
        let p = CGPoint(x: point.x + cos(angle) * r, y: point.y + sin(angle) * r)
        i == 0 ? path.move(to: p) : path.addLine(to: p)
    }
    path.closeSubpath()
    ctx.addPath(path)
    ctx.setFillColor(color)
    ctx.setStrokeColor(rgb(0.1, 0.05, 0.2))
    ctx.setLineWidth(6)
    ctx.drawPath(using: .fillStroke)
}

/// 太字の丸ゴシックで、ふち付きの文字を中央に描く
func drawText(_ ctx: CGContext, _ text: String, size: CGFloat, centerY: CGFloat, fill: CGColor, stroke: CGColor, strokeWidth: CGFloat) {
    let base = NSFont.systemFont(ofSize: size, weight: .black)
    let font = base.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: size) } ?? base
    func line(_ attributes: [NSAttributedString.Key: Any]) -> CTLine {
        CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
    }
    let strokeLine = line([.font: font, .foregroundColor: NSColor(cgColor: stroke)!, .strokeColor: NSColor(cgColor: stroke)!, .strokeWidth: strokeWidth])
    let fillLine = line([.font: font, .foregroundColor: NSColor(cgColor: fill)!])
    let bounds = CTLineGetBoundsWithOptions(fillLine, .useGlyphPathBounds)
    let origin = CGPoint(x: center.x - bounds.midX, y: centerY - bounds.midY)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 18, color: rgb(0, 0, 0, 0.6))
    ctx.textPosition = origin
    CTLineDraw(strokeLine, ctx)
    ctx.restoreGState()
    ctx.textPosition = origin
    CTLineDraw(fillLine, ctx)
}

/// 絵文字を影付きで中央に描く（ふちを付けると絵がつぶれるので付けない）
func drawEmoji(_ ctx: CGContext, _ text: String, size: CGFloat, centerY: CGFloat) {
    let font = NSFont(name: "AppleColorEmoji", size: size) ?? NSFont.systemFont(ofSize: size)
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: font]))
    let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    let origin = CGPoint(x: center.x - bounds.midX, y: centerY - bounds.midY)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 18, color: rgb(0, 0, 0, 0.6))
    ctx.textPosition = origin
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

func render(_ tier: Tier) -> Data {
    let ctx = CGContext(
        data: nil, width: Int(side), height: Int(side), bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!
    let c = tier.color
    let dark: (CGFloat, CGFloat, CGFloat) = (0.05, 0.04, 0.14)

    // 背景：アプリと同じ濃い紫に、オーラの色の光を広げる
    ctx.setFillColor(rgb(dark.0, dark.1, dark.2))
    ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
    let glow = mix(c, with: dark, 0.35)
    radialGradient(ctx, colors: [rgb(glow.0, glow.1, glow.2), rgb(0.13, 0.06, 0.25)], locations: [0, 1], radius: side * 0.72)

    // 放射状の光の筋（ゆっくり回るオーラのイメージ）
    ctx.saveGState()
    for i in 0..<tier.rays {
        let start = CGFloat(i) / CGFloat(tier.rays) * 2 * .pi
        let width = .pi / CGFloat(tier.rays) * 0.55
        let path = CGMutablePath()
        path.move(to: center)
        path.addArc(center: center, radius: side, startAngle: start - width, endAngle: start + width, clockwise: false)
        path.closeSubpath()
        ctx.addPath(path)
        let rayColor = tier.isRainbow ? hsv(CGFloat(i) / CGFloat(tier.rays), 0.6, 1) : rgb(1, 1, 1)
        ctx.setFillColor(rayColor.copy(alpha: tier.isRainbow ? 0.22 : 0.1)!)
        ctx.fillPath()
    }
    ctx.restoreGState()

    // メダルの外側のリング
    let ringRadius: CGFloat = 360
    if tier.isRainbow {
        clipped(ctx, radius: ringRadius) {
            let steps = 180
            for i in 0..<steps {
                let a0 = CGFloat(i) / CGFloat(steps) * 2 * .pi
                let a1 = CGFloat(i + 1) / CGFloat(steps) * 2 * .pi + 0.01
                let path = CGMutablePath()
                path.move(to: center)
                path.addArc(center: center, radius: ringRadius, startAngle: a0, endAngle: a1, clockwise: false)
                path.closeSubpath()
                ctx.addPath(path)
                ctx.setFillColor(hsv(CGFloat(i) / CGFloat(steps), 0.75, 1))
                ctx.fillPath()
            }
        }
    } else {
        let light = mix(c, with: (1, 1, 1), 0.55)
        let deep = mix(c, with: (0, 0, 0), 0.35)
        clipped(ctx, radius: ringRadius) {
            let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [
                rgb(light.0, light.1, light.2), rgb(c.0, c.1, c.2), rgb(deep.0, deep.1, deep.2), rgb(c.0, c.1, c.2), rgb(light.0, light.1, light.2),
            ] as CFArray, locations: [0, 0.3, 0.5, 0.75, 1])!
            ctx.drawLinearGradient(gradient, start: CGPoint(x: 150, y: 900), end: CGPoint(x: 880, y: 120), options: [])
        }
    }
    // リングの白いふちと、内側の暗い円盤
    ctx.setStrokeColor(rgb(1, 1, 1, 0.9))
    ctx.setLineWidth(10)
    ctx.strokeEllipse(in: CGRect(x: center.x - ringRadius, y: center.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2))
    let innerRadius: CGFloat = 300
    clipped(ctx, radius: innerRadius) {
        let inner = mix(c, with: dark, 0.7)
        radialGradient(ctx, colors: [rgb(inner.0, inner.1, inner.2), rgb(dark.0, dark.1, dark.2)], locations: [0, 1], radius: innerRadius)
        // 下から立ちのぼる炎のような光
        let flame: (CGFloat, CGFloat, CGFloat) = tier.isRainbow ? (1.0, 0.5, 0.9) : c
        let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [
            rgb(flame.0, flame.1, flame.2, 0.75), rgb(flame.0, flame.1, flame.2, 0),
        ] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: center.x, y: center.y - innerRadius), end: CGPoint(x: center.x, y: center.y + 60), options: [])
    }
    ctx.setStrokeColor(rgb(0.1, 0.05, 0.2, 0.8))
    ctx.setLineWidth(8)
    ctx.strokeEllipse(in: CGRect(x: center.x - innerRadius, y: center.y - innerRadius, width: innerRadius * 2, height: innerRadius * 2))

    // 星（強い実績ほど多い）をメダルの上側に並べる
    let starColor = tier.isRainbow ? rgb(1, 0.95, 0.5) : rgb(1, 0.9, 0.4)
    for i in 0..<tier.stars {
        let spread: CGFloat = 0.55
        let t = tier.stars == 1 ? 0.5 : CGFloat(i) / CGFloat(tier.stars - 1)
        let angle = .pi / 2 + spread * (0.5 - t) * 2
        let point = CGPoint(x: center.x + cos(angle) * 330, y: center.y + sin(angle) * 330)
        star(ctx, at: point, radius: tier.stars == 5 && i == 2 ? 62 : 50, color: starColor)
    }

    // 真ん中の文字と、下の言葉（「連勝」「クリア」）
    let outline = tier.isRainbow ? rgb(0.45, 0.15, 0.6) : rgb(mix(c, with: (0, 0, 0), 0.55).0, mix(c, with: (0, 0, 0), 0.55).1, mix(c, with: (0, 0, 0), 0.55).2)
    if tier.isEmoji {
        drawEmoji(ctx, tier.symbol, size: tier.symbolSize, centerY: center.y + 40)
    } else {
        drawText(ctx, tier.symbol, size: tier.symbolSize, centerY: center.y + 40, fill: rgb(1, 1, 1), stroke: outline, strokeWidth: tier.symbolStroke)
    }
    drawText(ctx, tier.caption, size: 120, centerY: center.y - 190, fill: rgb(1, 0.92, 0.55), stroke: rgb(0.1, 0.05, 0.2), strokeWidth: 14)

    let image = ctx.makeImage()!
    let rep = NSBitmapImageRep(cgImage: image)
    rep.size = NSSize(width: side, height: side) // 72dpi
    return rep.representation(using: .png, properties: [:])!
}

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "AppStoreAssets/Achievements", isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for tier in tiers {
    let url = output.appendingPathComponent("\(tier.id).png")
    try render(tier).write(to: url)
    print("書き出し: \(url.path)")
}
