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

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
                .environment(enemies)
                .environment(rewardedAds)
                .environment(gameCenter)
                .task {
                    rewardedAds.start()
                    gameCenter.authenticate(bestStreak: enemies.bestStreak)
                }
                .preferredColorScheme(.dark)
        }
    }
}
