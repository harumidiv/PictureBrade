//
//  RewardedAdManager.swift
//  PictureBrade
//

import GoogleMobileAds
import Observation
import UIKit

enum AdConfig {
    /// ランダム連戦のコンティニュー用リワード広告。
    /// 開発中に本番広告を表示・タップするとポリシー違反になるため、Debug では Google 公式のテスト広告を使う
    #if DEBUG
    static let continueRewardedUnitID = "ca-app-pub-3940256099942544/1712485313"
    #else
    static let continueRewardedUnitID = "ca-app-pub-8522231452310619/1172650202"
    #endif
}

/// リワード広告を事前に読み込んでおき、見終わったら報酬の有無を返す
@Observable
final class RewardedAdManager: NSObject, FullScreenContentDelegate {
    private(set) var isReady = false
    private(set) var isLoading = false

    @ObservationIgnored private var ad: RewardedAd?
    @ObservationIgnored private var didEarnReward = false
    @ObservationIgnored private var completion: ((Bool) -> Void)?

    func start() {
        MobileAds.shared.start(completionHandler: nil)
        load()
    }

    func load() {
        guard ad == nil, !isLoading else { return }
        isLoading = true
        RewardedAd.load(with: AdConfig.continueRewardedUnitID, request: Request()) { [weak self] ad, _ in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                self.ad = ad
                self.isReady = ad != nil
            }
        }
    }

    /// 広告を表示する。最後まで見て報酬を得たら completion(true)
    func show(completion: @escaping (Bool) -> Void) {
        guard let ad, let rootViewController = Self.topViewController() else {
            completion(false)
            load()
            return
        }
        didEarnReward = false
        self.completion = completion
        ad.fullScreenContentDelegate = self
        ad.present(from: rootViewController) { [weak self] in
            self?.didEarnReward = true
        }
    }

    // MARK: - FullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finish()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        finish()
    }

    private func finish() {
        let completion = completion
        let earned = didEarnReward
        self.completion = nil
        ad = nil
        isReady = false
        // 次のコンティニューに備えて読み込み直す
        load()
        completion?(earned)
    }

    /// バトル画面は fullScreenCover の上なので、一番手前の画面から広告を出す
    private static func topViewController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
