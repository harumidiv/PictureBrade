import AVFoundation
import AppKit
import CoreImage

// 画面収録の動画から、横向きの App プレビュー動画を作る。
// 使い方: tools/MakeAppPreview/run.sh <画面収録.mp4> <出力.mp4> <幅> <高さ>
// 場面の構成（どの秒数を使うか・説明文）は下の `segments` に書く。詳しくは README.md。
let args = CommandLine.arguments
let srcURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2])
let W = Int(args[3])!, H = Int(args[4])!
let Wf = CGFloat(W), Hf = CGFloat(H)
let fps = 30.0

// MARK: - Timeline
enum Mode { case full, arena }
struct Piece { let src: Double; let dur: Double; let rate: Double; let hit: Bool; let freeze: Bool }
struct Segment { let mode: Mode; let pieces: [Piece]; let cap: (String, String)?; let sfx: Bool; let endCard: Bool }

func n(_ s: Double, _ d: Double) -> Piece { Piece(src: s, dur: d, rate: 1, hit: false, freeze: false) }
func hitPieces(_ onset: Double, pre: Double = 0.5, slow: Double = 0.25, post: Double = 0.45) -> [Piece] {
    [n(onset - pre, pre), Piece(src: onset, dur: slow, rate: 0.35, hit: true, freeze: false), n(onset + slow, post)]
}
func hitSeg(_ onset: Double, _ cap: (String, String)) -> Segment {
    Segment(mode: .arena, pieces: hitPieces(onset), cap: cap, sfx: true, endCard: false)
}
let c1 = ("漢字も、", "ひらがなも、")
let c2 = ("絵文字も、", "ぶっ飛ばせ！")
let c3 = ("ストーリーの", "ボスに挑め！")
let segments: [Segment] = [
    Segment(mode: .full, pieces: [n(4.3, 1.7)], cap: ("写真のコマで、", "文字をぶっ飛ばせ！"), sfx: false, endCard: false),
    Segment(mode: .full, pieces: [n(169.8, 1.3)], cap: ("写真が", "ブレードになる"), sfx: false, endCard: false),
    hitSeg(11.55, c1), hitSeg(60.75, c1), hitSeg(86.10, c1),
    hitSeg(70.90, c2), hitSeg(94.35, c2), hitSeg(106.55, c2),
    Segment(mode: .full, pieces: [n(119.05, 1.15)], cap: ("連勝して", "記録をのばせ！"), sfx: false, endCard: false),
    Segment(mode: .full, pieces: [n(211.3, 1.3)], cap: c3, sfx: false, endCard: false),
    hitSeg(201.80, c3), hitSeg(148.05, c3), hitSeg(215.10, c3),
    Segment(mode: .full, pieces: [n(221.2, 1.1)], cap: ("必殺の", "SPIN FINISH！"), sfx: false, endCard: false),
    Segment(mode: .full, pieces: [n(158.5, 0.8), Piece(src: 159.25, dur: 1.8, rate: 1, hit: false, freeze: true)], cap: nil, sfx: false, endCard: true),
]

struct FrameInfo { let src: Double; let seg: Int; let segT: Double; let sinceHit: Double; let hitIndex: Int; let globalT: Double }
var frames: [FrameInfo] = []
var audioPlan: [(src: Double, out: Double, dur: Double)] = []
do {
    var t = 0.0; var lastHit = -100.0; var hitCount = -1
    for (si, seg) in segments.enumerated() {
        let segStart = t
        for p in seg.pieces {
            let outDur = p.dur / p.rate
            if p.hit { lastHit = t; hitCount += 1 }
            let nF = Int((outDur * fps).rounded())
            if !p.freeze { audioPlan.append((p.src, t, Double(nF) / fps)) }
            for k in 0..<nF {
                let lt = Double(k) / fps
                let src = p.freeze ? p.src : p.src + lt * p.rate
                let gt = t + lt
                frames.append(FrameInfo(src: src, seg: si, segT: gt - segStart, sinceHit: gt - lastHit, hitIndex: hitCount, globalT: gt))
            }
            t += Double(nF) / fps
        }
    }
    print(String(format: "total %.2fs, %d frames", t, frames.count))
}

// MARK: - Drawing helpers
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
func col(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: a)
}
func ease(_ x: Double) -> Double { let c = max(0, min(1, x)); return 1 - pow(1 - c, 3) }

struct RNG { var s: UInt64; mutating func next() -> Double { s = s &* 6364136223846793005 &+ 1442695040888963407; return Double(s >> 11) / Double(1 << 53) } }
var rng = RNG(s: 42)
let glyphs = ["龍", "し", "魅", "M", "易", "こ", "列", "る", "め", "ぬ", "★", "火", "あ", "ケ", "陽", "?"]
struct Floater { let g: String; let x: Double; let y: Double; let size: Double; let speed: Double; let rot: Double }
let floaters: [Floater] = (0..<16).map { i in
    Floater(g: glyphs[i], x: rng.next(), y: rng.next(), size: 0.22 + rng.next() * 0.22, speed: 0.015 + rng.next() * 0.03, rot: (rng.next() - 0.5) * 0.6)
}
struct Streak { let ang: Double; let phase: Double; let speed: Double; let hue: Int }
let streaks: [Streak] = (0..<90).map { _ in Streak(ang: rng.next() * .pi * 2, phase: rng.next(), speed: 0.6 + rng.next() * 0.9, hue: Int(rng.next() * 3)) }

func drawText(_ ctx: CGContext, _ s: String, font: NSFont, center: CGPoint, fill: NSColor, stroke: NSColor?, strokeW: CGFloat, outer: NSColor? = nil, outerW: CGFloat = 0, rot: CGFloat = 0, scale: CGFloat = 1, alpha: CGFloat = 1, kern: CGFloat = 0) {
    let base: [NSAttributedString.Key: Any] = [.font: font, .kern: kern]
    let size = (s as NSString).size(withAttributes: base)
    ctx.saveGState()
    ctx.setAlpha(alpha)
    ctx.translateBy(x: center.x, y: center.y)
    ctx.rotate(by: rot)
    ctx.scaleBy(x: scale, y: scale)
    let origin = CGPoint(x: -size.width / 2, y: -size.height / 2)
    ctx.setLineJoin(.round)
    if let o = outer { var a = base; a[.strokeColor] = o; a[.strokeWidth] = outerW; (s as NSString).draw(at: origin, withAttributes: a) }
    if let st = stroke { var a = base; a[.strokeColor] = st; a[.strokeWidth] = strokeW; (s as NSString).draw(at: origin, withAttributes: a) }
    var a = base; a[.foregroundColor] = fill; (s as NSString).draw(at: origin, withAttributes: a)
    ctx.restoreGState()
}
func fitFont(_ name: String, _ s: String, maxW: CGFloat, maxSize: CGFloat) -> NSFont {
    var sz = maxSize
    while sz > 10 { let f = NSFont(name: name, size: sz)!; if (s as NSString).size(withAttributes: [.font: f]).width <= maxW { return f }; sz -= 2 }
    return NSFont(name: name, size: sz)!
}

func drawBackground(_ ctx: CGContext, t: Double, hitBoost: Double, endCard: Bool) {
    let center = CGPoint(x: Wf / 2, y: Hf / 2)
    let grad = CGGradient(colorsSpace: cs, colors: [col(endCard ? 0x3A1A78 : 0x2B1560), col(0x120A2E), col(0x05040C)] as CFArray, locations: [0, 0.55, 1])!
    ctx.drawRadialGradient(grad, startCenter: center, startRadius: 0, endCenter: center, endRadius: Wf * 0.75, options: [.drawsAfterEndLocation])
    // rotating concentration lines
    let R = Wf * 1.2
    let rotA = t * 0.12
    let nL = 64
    for i in 0..<nL {
        let a0 = rotA + Double(i) / Double(nL) * .pi * 2
        let w = 0.012 + 0.008 * sin(Double(i) * 1.7)
        let a = (i % 2 == 0 ? 0.07 : 0.05) + 0.22 * hitBoost
        ctx.setFillColor(i % 3 == 0 ? col(0xFF3B6B, a) : col(0x3FD0FF, a))
        ctx.beginPath(); ctx.move(to: center)
        ctx.addLine(to: CGPoint(x: center.x + R * cos(a0 - w), y: center.y + R * sin(a0 - w)))
        ctx.addLine(to: CGPoint(x: center.x + R * cos(a0 + w), y: center.y + R * sin(a0 + w)))
        ctx.closePath(); ctx.fillPath()
    }
    // drifting giant glyphs
    for f in floaters {
        let x = (f.x - t * f.speed).truncatingRemainder(dividingBy: 1.2)
        let xx = (x < -0.1 ? x + 1.2 : x) * Wf
        let font = NSFont(name: "HiraginoSans-W9", size: CGFloat(f.size) * Hf)!
        drawText(ctx, f.g, font: font, center: CGPoint(x: xx, y: CGFloat(f.y) * Hf), fill: NSColor(white: 1, alpha: 0.06), stroke: nil, strokeW: 0, rot: CGFloat(f.rot))
    }
    // speed streaks flying outward
    ctx.setLineCap(.round)
    for s in streaks {
        let p = (s.phase + t * s.speed * (1 + 2.5 * hitBoost)).truncatingRemainder(dividingBy: 1)
        let r0 = Double(Wf) * (0.08 + p * 0.75), len = Double(Wf) * (0.03 + 0.1 * p) * (1 + 2 * hitBoost)
        let colr: CGColor = s.hue == 0 ? col(0xFFE14D, 0.5 * p) : (s.hue == 1 ? col(0x3FD0FF, 0.45 * p) : col(0xFF5FA2, 0.4 * p))
        ctx.setStrokeColor(colr); ctx.setLineWidth(CGFloat(1.5 + 3 * p) * Hf / 886)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: center.x + CGFloat(r0 * cos(s.ang)), y: center.y + CGFloat(r0 * sin(s.ang))))
        ctx.addLine(to: CGPoint(x: center.x + CGFloat((r0 + len) * cos(s.ang)), y: center.y + CGFloat((r0 + len) * sin(s.ang))))
        ctx.strokePath()
    }
}

func drawPanel(_ ctx: CGContext, img: CGImage, crop: CGRect, rect: CGRect, radius: CGFloat, glow: Double) {
    guard let c = img.cropping(to: crop) else { return }
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    // glow
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 60 * Hf / 886, color: col(0x3FD0FF, 0.55 + 0.4 * glow))
    ctx.addPath(path); ctx.setFillColor(col(0x000000)); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(path); ctx.clip()
    ctx.translateBy(x: rect.minX, y: rect.maxY); ctx.scaleBy(x: 1, y: -1)
    ctx.interpolationQuality = .high
    ctx.draw(c, in: CGRect(x: 0, y: 0, width: rect.width, height: rect.height))
    ctx.restoreGState()
    // neon border
    ctx.saveGState()
    ctx.addPath(path); ctx.setLineWidth(6 * Hf / 886); ctx.replacePathWithStrokedPath(); ctx.clip()
    let g = CGGradient(colorsSpace: cs, colors: [col(0x3FD0FF), col(0xB061FF), col(0xFF3B6B)] as CFArray, locations: [0, 0.5, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: rect.minX, y: rect.minY), end: CGPoint(x: rect.maxX, y: rect.maxY), options: [])
    ctx.restoreGState()
}

let sfxWords = ["ドカッ！", "バキィ！", "ズドン！", "ガキン！", "ドーン！", "バシッ！", "ゴッ！", "ズガン！", "ドゴォ！"]

// MARK: - Source frames
let asset = AVURLAsset(url: srcURL)
let gen = AVAssetImageGenerator(asset: asset)
gen.requestedTimeToleranceBefore = CMTime(value: 1, timescale: 120)
gen.requestedTimeToleranceAfter = CMTime(value: 1, timescale: 120)
gen.appliesPreferredTrackTransform = true

// MARK: - Writer
let tmpVideo = outURL.deletingPathExtension().appendingPathExtension("silent.mov")
try? FileManager.default.removeItem(at: tmpVideo)
let writer = try! AVAssetWriter(outputURL: tmpVideo, fileType: .mov)
let vin = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: W, AVVideoHeightKey: H,
    AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 16_000_000, AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel, AVVideoExpectedSourceFrameRateKey: 30, AVVideoMaxKeyFrameIntervalKey: 30],
])
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: vin, sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA, kCVPixelBufferWidthKey as String: W, kCVPixelBufferHeightKey as String: H])
writer.add(vin)
writer.startWriting(); writer.startSession(atSourceTime: .zero)

let srcW: CGFloat = 1170, srcH: CGFloat = 2532
let fullCrop = CGRect(x: 0, y: 150, width: srcW, height: srcH - 150)
let arenaCrop = CGRect(x: 0, y: 640, width: srcW, height: 1300)
let s = Hf / 886

var cache: (Double, CGImage)? = nil
for (fi, f) in frames.enumerated() {
    let seg = segments[f.seg]
    let img: CGImage
    if let c = cache, abs(c.0 - f.src) < 0.0001 { img = c.1 } else {
        img = try! gen.copyCGImage(at: CMTime(seconds: f.src, preferredTimescale: 6000), actualTime: nil)
        cache = (f.src, img)
    }
    var pb: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pb)
    CVPixelBufferLockBaseAddress(pb!, [])
    let ctx = CGContext(data: CVPixelBufferGetBaseAddress(pb!), width: W, height: H, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pb!), space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
    ctx.translateBy(x: 0, y: Hf); ctx.scaleBy(x: 1, y: -1)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)

    let isHitSeg = seg.sfx
    let dtH = f.sinceHit
    let hitActive = isHitSeg && dtH >= 0 && dtH < 1.0 && dtH <= f.segT + 0.001
    let boost = hitActive ? exp(-dtH * 5) : 0
    drawBackground(ctx, t: f.globalT, hitBoost: boost, endCard: seg.endCard)

    // panel geometry
    let crop = seg.mode == .arena ? arenaCrop : fullCrop
    let panelH = Hf * (seg.mode == .arena ? 0.9 : 0.9)
    let panelW = panelH * crop.width / crop.height
    var cx = Wf / 2, cy = Hf / 2
    if seg.endCard { cx = Wf * 0.70 }
    // entrance: quick zoom-in at each segment start
    let ent = ease(f.segT / 0.18)
    var scale = 0.86 + 0.14 * ent
    if hitActive { scale *= 1 + 0.09 * exp(-dtH * 7) }
    if hitActive {
        let amp = 22 * s * exp(-dtH * 9)
        cx += amp * CGFloat(sin(dtH * 95)); cy += amp * CGFloat(cos(dtH * 77))
    }
    let pw = panelW * CGFloat(scale), ph = panelH * CGFloat(scale)
    let rect = CGRect(x: cx - pw / 2, y: cy - ph / 2, width: pw, height: ph)
    drawPanel(ctx, img: img, crop: crop, rect: rect, radius: 34 * s, glow: boost)

    let sideW = (Wf - panelW) / 2 - 40 * s
    // captions (left side)
    if let cap = seg.cap {
        let a = CGFloat(ease(f.segT / 0.2))
        let lx = (Wf - panelW) / 4 + 6 * s - CGFloat(1 - a) * 60 * s
        let f1 = fitFont("HiraginoSans-W8", cap.0, maxW: sideW, maxSize: 64 * s)
        let f2 = fitFont("HiraginoSans-W9", cap.1, maxW: sideW, maxSize: 84 * s)
        drawText(ctx, cap.0, font: f1, center: CGPoint(x: lx, y: Hf * 0.42), fill: .white, stroke: NSColor(calibratedRed: 0.1, green: 0.05, blue: 0.25, alpha: 1), strokeW: 8, alpha: a)
        drawText(ctx, cap.1, font: f2, center: CGPoint(x: lx, y: Hf * 0.42 + 96 * s), fill: NSColor(calibratedRed: 1, green: 0.88, blue: 0.3, alpha: 1), stroke: NSColor(calibratedRed: 0.84, green: 0.15, blue: 0.24, alpha: 1), strokeW: 10, alpha: a)
    }
    // SFX (right side)
    if hitActive || (isHitSeg && dtH >= 0 && dtH <= f.segT + 0.001) {
        let word = sfxWords[max(0, f.hitIndex) % sfxWords.count]
        let pop = dtH < 0.12 ? 1.35 - 0.35 * ease(dtH / 0.12) : 1.0
        let rx = Wf - (Wf - panelW) / 4 - 10 * s
        let font = fitFont("HiraginoSans-W9", word, maxW: sideW * 0.78, maxSize: 140 * s)
        let rot: CGFloat = f.hitIndex % 2 == 0 ? -0.16 : 0.14
        let jitter = CGFloat(dtH < 0.4 ? sin(dtH * 120) * 6 * s * exp(-dtH * 6) : 0)
        drawText(ctx, word, font: font, center: CGPoint(x: rx + jitter, y: Hf * 0.47), fill: NSColor(calibratedRed: 1, green: 0.9, blue: 0.3, alpha: 1), stroke: NSColor(calibratedRed: 0.86, green: 0.12, blue: 0.22, alpha: 1), strokeW: 12, outer: NSColor(calibratedRed: 0.06, green: 0.02, blue: 0.12, alpha: 1), outerW: 26, rot: rot, scale: CGFloat(pop))
    }
    // end card logo
    if seg.endCard {
        let a = CGFloat(ease(f.segT / 0.3))
        let lx = Wf * 0.70 - panelW / 2 - 40 * s
        let leftCX = lx / 2 + 20 * s
        let maxW = lx - 80 * s
        let logoFont = fitFont("AvenirNext-HeavyItalic", "PHOTO BLADE", maxW: maxW, maxSize: 150 * s)
        let pop = CGFloat(f.segT < 0.25 ? 1.3 - 0.3 * ease(f.segT / 0.25) : 1)
        drawText(ctx, "PHOTO BLADE", font: logoFont, center: CGPoint(x: leftCX, y: Hf * 0.40), fill: NSColor(calibratedRed: 1, green: 0.78, blue: 0.2, alpha: 1), stroke: NSColor(calibratedRed: 0.9, green: 0.25, blue: 0.1, alpha: 1), strokeW: 8, outer: NSColor(calibratedRed: 0.08, green: 0.03, blue: 0.18, alpha: 1), outerW: 22, scale: pop, alpha: a)
        let tag = fitFont("HiraginoSans-W8", "写真のコマで、文字をぶっ飛ばせ！", maxW: maxW, maxSize: 52 * s)
        drawText(ctx, "写真のコマで、文字をぶっ飛ばせ！", font: tag, center: CGPoint(x: leftCX, y: Hf * 0.40 + 120 * s), fill: .white, stroke: NSColor(calibratedRed: 0.1, green: 0.05, blue: 0.25, alpha: 1), strokeW: 8, alpha: a)
        let nm = NSFont(name: "HiraginoSans-W7", size: 40 * s)!
        drawText(ctx, "フォトブレード", font: nm, center: CGPoint(x: leftCX, y: Hf * 0.40 + 195 * s), fill: NSColor(calibratedRed: 0.6, green: 0.85, blue: 1, alpha: 1), stroke: nil, strokeW: 0, alpha: a)
    }
    // flashes: hit (strong) and cut (light)
    var flash = 0.0
    if hitActive { flash = max(flash, 0.85 * (1 - dtH / 0.1)) }
    if f.segT < 0.07 && f.seg > 0 { flash = max(flash, 0.45 * (1 - f.segT / 0.07)) }
    if flash > 0 { ctx.setFillColor(col(0xFFFFFF, CGFloat(flash))); ctx.fill(CGRect(x: 0, y: 0, width: Wf, height: Hf)) }
    // fade out at very end
    let remain = Double(frames.count - fi) / fps
    if remain < 0.35 { ctx.setFillColor(col(0x000000, CGFloat(1 - remain / 0.35))); ctx.fill(CGRect(x: 0, y: 0, width: Wf, height: Hf)) }

    NSGraphicsContext.current = nil
    CVPixelBufferUnlockBaseAddress(pb!, [])
    while !vin.isReadyForMoreMediaData { usleep(2000) }
    adaptor.append(pb!, withPresentationTime: CMTime(value: CMTimeValue(fi), timescale: 30))
    if fi % 60 == 0 { print("frame \(fi)/\(frames.count)") }
}
vin.markAsFinished()
let ws = DispatchSemaphore(value: 0)
writer.finishWriting { ws.signal() }; ws.wait()
print("video written", writer.status.rawValue, writer.error as Any)

// MARK: - Mux audio
let comp = AVMutableComposition()
let rendered = AVURLAsset(url: tmpVideo)
let sem = DispatchSemaphore(value: 0)
Task {
    do {
        let rv = try await rendered.loadTracks(withMediaType: .video)[0]
        let rdur = try await rendered.load(.duration)
        let cv = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        try cv.insertTimeRange(CMTimeRange(start: .zero, duration: rdur), of: rv, at: .zero)
        let sa = try await asset.loadTracks(withMediaType: .audio)[0]
        let ca = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        // merge consecutive plan items: for slow pieces, audio plays at normal speed from the onset
        for p in audioPlan {
            let start = CMTime(seconds: p.src, preferredTimescale: 48000)
            let d = CMTime(seconds: min(p.dur, rdur.seconds - p.out), preferredTimescale: 48000)
            if d.seconds <= 0 { continue }
            try ca.insertTimeRange(CMTimeRange(start: start, duration: d), of: sa, at: CMTime(seconds: p.out, preferredTimescale: 48000))
        }
        // fade audio at end
        let mix = AVMutableAudioMix()
        let prm = AVMutableAudioMixInputParameters(track: ca)
        prm.setVolumeRamp(fromStartVolume: 1, toEndVolume: 0, timeRange: CMTimeRange(start: rdur - CMTime(seconds: 0.6, preferredTimescale: 600), duration: CMTime(seconds: 0.6, preferredTimescale: 600)))
        mix.inputParameters = [prm]
        try? FileManager.default.removeItem(at: outURL)
        let reader = try AVAssetReader(asset: comp)
        let vOut = AVAssetReaderTrackOutput(track: cv, outputSettings: nil)
        let aOut = AVAssetReaderAudioMixOutput(audioTracks: [ca], audioSettings: [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 48000, AVNumberOfChannelsKey: 2, AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false, AVLinearPCMIsNonInterleaved: false])
        aOut.audioMix = mix
        reader.add(vOut); reader.add(aOut)
        let w2 = try AVAssetWriter(outputURL: outURL, fileType: .mp4)
        let fdesc = (try await rv.load(.formatDescriptions)).first
        let v2 = AVAssetWriterInput(mediaType: .video, outputSettings: nil, sourceFormatHint: fdesc)
        var acl = AudioChannelLayout(); acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo
        let a2 = AVAssetWriterInput(mediaType: .audio, outputSettings: [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 48000, AVNumberOfChannelsKey: 2, AVEncoderBitRateKey: 256000, AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_Constant, AVChannelLayoutKey: Data(bytes: &acl, count: MemoryLayout<AudioChannelLayout>.size)])
        w2.add(v2); w2.add(a2)
        reader.startReading(); w2.startWriting(); w2.startSession(atSourceTime: .zero)
        let g = DispatchGroup()
        for (inp, out, name) in [(v2, vOut as AVAssetReaderOutput, "v"), (a2, aOut as AVAssetReaderOutput, "a")] {
            g.enter()
            inp.requestMediaDataWhenReady(on: DispatchQueue(label: name)) {
                while inp.isReadyForMoreMediaData {
                    if let sb = out.copyNextSampleBuffer() { inp.append(sb) } else { inp.markAsFinished(); g.leave(); return }
                }
            }
        }
        g.wait()
        await w2.finishWriting()
        print("mux status", w2.status.rawValue, w2.error as Any, reader.error as Any)
        print("exported", outURL.path)
        try? FileManager.default.removeItem(at: tmpVideo)
    } catch { print("ERR", error) }
    sem.signal()
}
sem.wait()
