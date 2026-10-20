//
//  PictureBradeApp.swift
//  PictureBrade
//
//  Created by harumi.sagawa on 2026/10/19.
//

import SwiftUI

@main
struct PictureBradeApp: App {
    @State private var store = BladeStore()
    @State private var enemies = EnemyCatalog()
    @State private var rewardedAds = RewardedAdManager()
    @State private var gameCenter = GameCenterManager()
    @State private var life = LifeManager()
    @State private var didStartServices = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
                .environment(enemies)
                .environment(rewardedAds)
                .environment(gameCenter)
                .environment(life)
                .onChange(of: scenePhase, initial: true) { _, phase in
                    guard phase == .active, !didStartServices else { return }
                    didStartServices = true
                    Task {
                        // 広告の読み込みより先に ATT の選択を済ませ、Game Center のログイン画面とも重ならないようにする
                        await TrackingAuthorization.requestIfNeeded()
                        rewardedAds.start()
                        gameCenter.authenticate(bestStreak: enemies.bestStreak)
                    }
                }
                .preferredColorScheme(.dark)
        }
    }
}
