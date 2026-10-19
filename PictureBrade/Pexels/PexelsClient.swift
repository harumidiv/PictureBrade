//
//  PexelsClient.swift
//  PictureBrade
//

import Foundation
import UIKit

nonisolated struct PexelsPhoto: Decodable, Identifiable, Hashable {
    struct Source: Decodable, Hashable {
        let large: URL
        let medium: URL
        let small: URL
        let tiny: URL
    }

    let id: Int
    let width: Int
    let height: Int
    /// Pexels 上の写真ページ
    let url: URL
    let photographer: String
    let photographerURL: URL
    let alt: String?
    let src: Source

    enum CodingKeys: String, CodingKey {
        case id, width, height, url, photographer, alt, src
        case photographerURL = "photographer_url"
    }

    var credit: PhotoCredit {
        PhotoCredit(photographer: photographer, photographerURL: photographerURL, photoURL: url, source: "Pexels")
    }
}

nonisolated struct PexelsSearchResponse: Decodable {
    let photos: [PexelsPhoto]
    let page: Int
    let totalResults: Int
    let nextPage: URL?

    enum CodingKeys: String, CodingKey {
        case photos, page
        case totalResults = "total_results"
        case nextPage = "next_page"
    }
}

/// Pexels API（https://www.pexels.com/api/documentation/）のクライアント。
/// レート制限は 200リクエスト/時・20,000リクエスト/月。
nonisolated struct PexelsClient {
    enum ClientError: LocalizedError {
        case missingAPIKey
        case rateLimited
        case http(Int)
        case noResults
        case invalidImage

        var errorDescription: String? {
            switch self {
            case .missingAPIKey: "Pexels の APIキーが設定されていません（Config/Secrets.xcconfig）"
            case .rateLimited: "Pexels の利用回数の上限に達しました。しばらく待ってから試してください"
            case .http(let code): "Pexels との通信に失敗しました（\(code)）"
            case .noResults: "写真が見つかりませんでした"
            case .invalidImage: "写真を読み込めませんでした"
            }
        }
    }

    static let homepage = URL(string: "https://www.pexels.com")!

    /// 人物系のおすすめ検索ワード（表示名, 検索語）
    static let personQueries: [(label: String, query: String)] = [
        ("ポートレート", "portrait person"),
        ("ダンサー", "dancer"),
        ("アスリート", "athlete"),
        ("ジャンプ", "person jumping"),
        ("ミュージシャン", "musician"),
        ("シェフ", "chef"),
        ("ビジネス", "businessman"),
        ("ヒーロー", "superhero costume"),
    ]

    static var apiKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "PexelsAPIKey") as? String else { return nil }
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty || trimmed.hasPrefix("$(") ? nil : trimmed
    }

    static var isConfigured: Bool { apiKey != nil }

    var session: URLSession = .shared

    func search(query: String, page: Int = 1, perPage: Int = 30) async throws -> PexelsSearchResponse {
        guard let apiKey = Self.apiKey else { throw ClientError.missingAPIKey }
        var components = URLComponents(string: "https://api.pexels.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(min(perPage, 80))),
            URLQueryItem(name: "locale", value: "ja-JP"),
        ]
        var request = URLRequest(url: components.url!)
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try Self.validate(response)
        return try JSONDecoder().decode(PexelsSearchResponse.self, from: data)
    }

    /// 人物写真をランダムに1枚選ぶ
    func randomPerson() async throws -> PexelsPhoto {
        let query = Self.personQueries.randomElement()!.query
        let response = try await search(query: query, page: Int.random(in: 1...10), perPage: 40)
        guard let photo = response.photos.randomElement() else { throw ClientError.noResults }
        return photo
    }

    /// 切り抜き用の画像をダウンロードする（約940px）
    func downloadImage(for photo: PexelsPhoto) async throws -> UIImage {
        let (data, response) = try await session.data(from: photo.src.large)
        try Self.validate(response)
        guard let image = UIImage(data: data) else { throw ClientError.invalidImage }
        return image
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200..<300: return
        case 429: throw ClientError.rateLimited
        default: throw ClientError.http(http.statusCode)
        }
    }
}
