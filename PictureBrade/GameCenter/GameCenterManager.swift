//
//  GameCenterManager.swift
//  PictureBrade
//

import GameKit
import Observation
import UIKit

/// Game Center へのサインインと、ランダム連戦の最高連勝ランキング
@Observable
final class GameCenterManager {
    /// App Store Connect で作成するリーダーボードの ID（最高スコアを保持する設定にする）
    static let endlessLeaderboardID = "photoblade.endless.beststreak"

    private(set) var isAuthenticated = false

    /// 起動時に一度呼ぶ。必要なら Game Center のサインイン画面を出す
    func authenticate(bestStreak: Int) {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, _ in
            Task { @MainActor in
                guard let self else { return }
                if let viewController {
                    Self.topViewController()?.present(viewController, animated: true)
                    return
                }
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                // サインイン前に出した記録もランキングに反映する
                if self.isAuthenticated, bestStreak > 0 {
                    self.submitEndless(streak: bestStreak)
                }
            }
        }
    }

    /// 連勝数を送る（Game Center 側で自己ベストだけが残る）
    func submitEndless(streak: Int) {
        guard isAuthenticated, streak > 0 else { return }
        GKLeaderboard.submitScore(
            streak, context: 0, player: GKLocalPlayer.local,
            leaderboardIDs: [Self.endlessLeaderboardID]
        ) { _ in }
    }

    func showEndlessLeaderboard() {
        guard isAuthenticated else { return }
        GKAccessPoint.shared.trigger(
            leaderboardID: Self.endlessLeaderboardID, playerScope: .global, timeScope: .allTime
        ) {}
    }

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
