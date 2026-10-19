//
//  main.swift
//  FetchStarterBlades
//
//  Pexels API で人物写真を取得し、Vision で切り抜いて、アプリ同梱用のコマ画像（HEIC）と
//  一覧ファイル（starter-blades.json）を作る macOS 用ツール。
//
//  使い方は tools/FetchStarterBlades/README.md を参照。
//

import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers
import Vision

// MARK: - Options

struct Options {
    var count = 500
    /// 出力画像の一辺(px)。アプリ内の最大表示サイズ（カード 84pt × 3x ≒ 252px）より大きくしてぼやけを防ぐ
    var size = 320
    var quality = 0.8
    var output = URL(fileURLWithPath: "PictureBrade/StarterBlades")
    var apiKey: String?

    static func parse() -> Options {
        var options = Options()
        var args = CommandLine.arguments.dropFirst().makeIterator()
        while let arg = args.next() {
            switch arg {
            case "--count": options.count = Int(args.next() ?? "") ?? options.count
            case "--size": options.size = Int(args.next() ?? "") ?? options.size
            case "--quality": options.quality = Double(args.next() ?? "") ?? options.quality
            case "--out": options.output = URL(fileURLWithPath: args.next() ?? options.output.path)
            default:
                print("不明なオプション: \(arg)")
                exit(1)
            }
        }
        options.apiKey = ProcessInfo.processInfo.environment["PEXELS_API_KEY"] ?? readKeyFromSecrets()
        return options
    }

    private static func readKeyFromSecrets() -> String? {
        guard let text = try? String(contentsOfFile: "Config/Secrets.xcconfig", encoding: .utf8) else { return nil }
        for line in text.split(separator: "\n") where line.hasPrefix("PEXELS_API_KEY") {
            let value = line.split(separator: "=", maxSplits: 1).last?.trimmingCharacters(in: .whitespaces) ?? ""
            return value.isEmpty || value == "your_api_key_here" ? nil : value
        }
        return nil
    }
}

// MARK: - Pexels API

struct Photo: Decodable {
    struct Source: Decodable {
        let large2x: URL
    }

    let id: Int
    let url: URL
    let photographer: String
    let photographerURL: URL
    let src: Source

    enum CodingKeys: String, CodingKey {
        case id, url, photographer, src
        case photographerURL = "photographer_url"
    }
}

struct SearchResponse: Decodable {
    let photos: [Photo]
    let nextPage: URL?

    enum CodingKeys: String, CodingKey {
        case photos
        case nextPage = "next_page"
    }
}

/// 人物が全身・ポーズ付きで写りやすい検索ワード。コマの形にバリエーションを出すため幅広く取る
let queries = [
    "dancer", "street dance", "ballet dancer", "athlete", "person jumping", "martial arts",
    "karate", "boxer", "skateboarder", "basketball player", "soccer player", "gymnast",
    "yoga pose", "runner", "cosplay", "person posing full body", "fashion model full body",
    "guitarist", "chef", "businessman", "hiker", "surfer", "tennis player", "cheerleader",
    "superhero costume", "person dancing", "parkour", "baseball player", "cyclist", "firefighter",
]

func search(query: String, page: Int, apiKey: String) async throws -> SearchResponse {
    var components = URLComponents(string: "https://api.pexels.com/v1/search")!
    components.queryItems = [
        URLQueryItem(name: "query", value: query),
        URLQueryItem(name: "page", value: String(page)),
        URLQueryItem(name: "per_page", value: "80"),
    ]
    var request = URLRequest(url: components.url!)
    request.setValue(apiKey, forHTTPHeaderField: "Authorization")
    let (data, response) = try await URLSession.shared.data(for: request)
    if let http = response as? HTTPURLResponse {
        if let remaining = http.value(forHTTPHeaderField: "X-Ratelimit-Remaining") {
            print("  API残り回数: \(remaining)")
        }
        guard http.statusCode == 200 else {
            throw NSError(domain: "Pexels", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Pexels API エラー \(http.statusCode): \(String(data: data, encoding: .utf8) ?? "")",
            ])
        }
    }
    return try JSONDecoder().decode(SearchResponse.self, from: data)
}

// MARK: - Image processing

enum RejectReason: String, Error {
    case download = "ダウンロード失敗"
    case noSubject = "被写体なし"
    case tooManyPeople = "人物が多すぎる"
    case tooSmall = "被写体が小さい（拡大するとぼやける）"
    case cutOff = "被写体が画面端で切れている"
    case encode = "書き出し失敗"
}

let ciContext = CIContext()

/// 写真から被写体を切り抜き、余白を除いた画像を返す
func liftSubject(from data: Data, minimumSide: Int) -> Result<CGImage, RejectReason> {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return .failure(.download) }

    let request = VNGenerateForegroundInstanceMaskRequest()
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    guard (try? handler.perform([request])) != nil,
          let observation = request.results?.first,
          !observation.allInstances.isEmpty else { return .failure(.noSubject) }
    // グループ写真はコマにしたとき何が写っているか分かりにくいので除外
    guard observation.allInstances.count <= 2 else { return .failure(.tooManyPeople) }

    guard let buffer = try? observation.generateMaskedImage(
        ofInstances: observation.allInstances, from: handler, croppedToInstancesExtent: false
    ) else { return .failure(.noSubject) }
    let ciImage = CIImage(cvPixelBuffer: buffer)
    guard let masked = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return .failure(.noSubject) }

    guard let bounds = opaqueBounds(of: masked) else { return .failure(.noSubject) }
    // 被写体の長辺が出力サイズ未満だと拡大になりぼやけるので除外
    guard max(bounds.width, bounds.height) >= CGFloat(minimumSide) else { return .failure(.tooSmall) }
    // 上下左右のうち2辺以上で画面端に接している（大きく見切れている）ものは除外
    let touches = [bounds.minX <= 1, bounds.minY <= 1, bounds.maxX >= CGFloat(masked.width - 1), bounds.maxY >= CGFloat(masked.height - 1)]
    guard touches.filter({ $0 }).count < 2 else { return .failure(.cutOff) }
    guard let cropped = masked.cropping(to: bounds) else { return .failure(.noSubject) }
    return .success(cropped)
}

/// 不透明部分の範囲（CGImage の左上原点）
func opaqueBounds(of image: CGImage) -> CGRect? {
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
    return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
}

/// 正方形のキャンバスに高品質で縮小して収める（アプリ側の squareFit と同じ 96% の余白）
func squareFit(_ image: CGImage, side: Int) -> CGImage? {
    guard let context = CGContext(
        data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }
    context.interpolationQuality = .high
    let w = CGFloat(image.width), h = CGFloat(image.height)
    let scale = CGFloat(side) * 0.96 / max(w, h)
    let drawSize = CGSize(width: w * scale, height: h * scale)
    context.draw(image, in: CGRect(
        x: (CGFloat(side) - drawSize.width) / 2, y: (CGFloat(side) - drawSize.height) / 2,
        width: drawSize.width, height: drawSize.height
    ))
    return context.makeImage()
}

func writeHEIC(_ image: CGImage, to url: URL, quality: Double) -> Bool {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.heic.identifier as CFString, 1, nil) else { return false }
    CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
    return CGImageDestinationFinalize(destination)
}

// MARK: - Main

let options = Options.parse()
guard let apiKey = options.apiKey else {
    print("APIキーがありません。Config/Secrets.xcconfig に PEXELS_API_KEY を書くか、環境変数 PEXELS_API_KEY を設定してください。")
    exit(1)
}
try FileManager.default.createDirectory(at: options.output, withIntermediateDirectories: true)

// 1. 候補を集める（不採用分を見込んで多めに）
print("▶ 候補の写真を検索中…")
let target = Int(Double(options.count) * 2.2)
var candidates: [Photo] = []
var seen = Set<Int>()
var page = 1
search: while candidates.count < target {
    var gotAny = false
    for query in queries {
        let response = try await search(query: query, page: page, apiKey: apiKey)
        for photo in response.photos where seen.insert(photo.id).inserted {
            candidates.append(photo)
            gotAny = true
        }
        print("  \(query) p\(page): 候補 \(candidates.count)件")
        if candidates.count >= target { break search }
        try await Task.sleep(for: .milliseconds(300))
    }
    guard gotAny else { break }
    page += 1
}
candidates.shuffle()

// 2. ダウンロード → 切り抜き → 縮小 → HEIC 書き出し（6並列）
print("▶ \(candidates.count)件から \(options.count)件のコマを作成中…")
var blades: [Blade] = []
var rejects: [RejectReason: Int] = [:]
let fixedDate = Date(timeIntervalSince1970: 1_790_000_000)
let candidateList = candidates
let outputSize = options.size

await withTaskGroup(of: (Photo, Result<(CGImage, Data), RejectReason>).self) { group in
    var nextIndex = 0
    func enqueue() {
        guard nextIndex < candidateList.count else { return }
        let photo = candidateList[nextIndex]
        nextIndex += 1
        group.addTask {
            guard let (data, _) = try? await URLSession.shared.data(from: photo.src.large2x) else {
                return (photo, .failure(.download))
            }
            return (photo, liftSubject(from: data, minimumSide: outputSize).map { ($0, data) })
        }
    }
    for _ in 0..<6 { enqueue() }

    while let (photo, result) = await group.next() {
        defer { if blades.count < options.count { enqueue() } }
        guard blades.count < options.count else { continue }
        switch result {
        case .failure(let reason):
            rejects[reason, default: 0] += 1
        case .success(let (cutout, _)):
            guard let square = squareFit(cutout, side: options.size) else {
                rejects[.encode, default: 0] += 1
                continue
            }
            let fileName = "pexels-\(photo.id).heic"
            guard writeHEIC(square, to: options.output.appendingPathComponent(fileName), quality: options.quality) else {
                rejects[.encode, default: 0] += 1
                continue
            }
            let analysis = BladeAnalyzer.analyze(square)
            blades.append(Blade(
                id: UUID(),
                name: String(format: "ファイター #%03d", blades.count + 1),
                imageFileName: fileName,
                stats: analysis.stats,
                tint: analysis.tint,
                createdAt: fixedDate,
                credit: PhotoCredit(photographer: photo.photographer, photographerURL: photo.photographerURL, photoURL: photo.url, source: "Pexels")
            ))
            if blades.count % 25 == 0 { print("  \(blades.count)/\(options.count)") }
        }
    }
}

// 3. 一覧ファイル
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
try encoder.encode(blades).write(to: options.output.appendingPathComponent("starter-blades.json"))

let totalBytes = blades.reduce(0) { total, blade in
    let path = options.output.appendingPathComponent(blade.imageFileName).path
    return total + ((try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int) ?? 0)
}
print("""
✅ 完了: \(blades.count)件（画像合計 \(String(format: "%.1f", Double(totalBytes) / 1_048_576))MB、平均 \(blades.isEmpty ? 0 : totalBytes / blades.count / 1024)KB）
   不採用: \(rejects.map { "\($0.key.rawValue) \($0.value)" }.joined(separator: " / "))
   出力先: \(options.output.path)
""")
if blades.count < options.count {
    print("⚠️ 目標の \(options.count)件に届きませんでした。queries を増やして再実行してください。")
}
