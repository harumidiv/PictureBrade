//
//  GameCenterManager.swift
//  PictureBrade
//

import GameKit
import Observation
import UIKit

/// Game Center へのサインインと、ランダム連戦の最高連勝ランキング・連勝の実績
@Observable
final class GameCenterManager {
    /// App Store Connect で作成するリーダーボードの ID（最高スコアを保持する設定にする）
    static let endlessLeaderboardID = "photoblade.endless.beststreak"

    /// App Store Connect で作成する実績の ID と、達成に必要な連勝数
    static let streakAchievements: [(id: String, streak: Int)] = [
        ("photoblade.endless.streak5", 5),
        ("photoblade.endless.streak10", 10),
        ("photoblade.endless.streak20", 20),
        ("photoblade.endless.streak50", 50),
        ("photoblade.endless.streak100", 100),
    ]

    private(set) var isAuthenticated = false
    /// Game Center に記録済みの実績の達成率（0...100）。同じ値を何度も送らないために覚えておく
    @ObservationIgnored private var achievementProgress: [String: Double] = [:]

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
                guard self.isAuthenticated else { return }
                // 記録済みの実績を読んでから、サインイン前に出した記録もランキングと実績に反映する
                await self.loadAchievementProgress()
                if bestStreak > 0 {
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
        reportStreakAchievements(streak: streak)
    }

    /// 連勝の実績を送る。まだの実績も途中の達成率を送るので、Game Center で「あと何連勝」かがわかる
    private func reportStreakAchievements(streak: Int) {
        let achievements: [GKAchievement] = Self.streakAchievements.compactMap { item in
            let percent = min(100, Double(streak) / Double(item.streak) * 100)
            // 達成率は下がらないので、前より進んだときだけ送る
            guard percent > achievementProgress[item.id, default: 0] else { return nil }
            achievementProgress[item.id] = percent
            let achievement = GKAchievement(identifier: item.id)
            achievement.percentComplete = percent
            achievement.showsCompletionBanner = true
            return achievement
        }
        guard !achievements.isEmpty else { return }
        let ids = achievements.map(\.identifier)
        GKAchievement.report(achievements) { [weak self] error in
            guard error != nil else { return }
            // 送れなかったときは、次に勝ったときにもう一度送る
            Task { @MainActor [weak self] in
                ids.forEach { self?.achievementProgress[$0] = nil }
            }
        }
    }

    private func loadAchievementProgress() async {
        guard let achievements = try? await GKAchievement.loadAchievements() else { return }
        for achievement in achievements {
            achievementProgress[achievement.identifier] = achievement.percentComplete
        }
    }

    func showAchievements() {
        guard isAuthenticated else { return }
        GKAccessPoint.shared.trigger(state: .achievements) {}
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
