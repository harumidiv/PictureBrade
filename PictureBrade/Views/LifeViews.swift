//
//  LifeViews.swift
//  PictureBrade
//

import SwiftUI

/// ライフのハートと、次に回復するまでの残り時間
struct LifeIndicator: View {
    @Environment(LifeManager.self) private var life

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let lives = life.lives(at: timeline.date)
            HStack(spacing: 6) {
                HStack(spacing: 2) {
                    ForEach(0..<LifeManager.maxLives, id: \.self) { index in
                        Image(systemName: index < lives ? "heart.fill" : "heart")
                            .foregroundStyle(index < lives ? Color.red : .white.opacity(0.35))
                    }
                }
                .font(.system(size: 15, weight: .bold))
                if let remaining = life.timeUntilNextLife(at: timeline.date) {
                    Text(Self.format(remaining))
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
        }
    }

    static func format(_ interval: TimeInterval) -> String {
        let seconds = Int(interval.rounded(.up))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

/// 広告を見てライフを1つ回復するボタン
struct LifeRefillButton: View {
    @Environment(LifeManager.self) private var life
    @Environment(RewardedAds.self) private var rewardedAds

    var body: some View {
        Button {
            rewardedAds.lifeRefill.show { earned in
                if earned { life.recoverOne() }
            }
        } label: {
            HStack(spacing: 8) {
                if rewardedAds.lifeRefill.isReady {
                    Image(systemName: "play.rectangle.fill")
                } else {
                    ProgressView().tint(.white)
                }
                Text("広告を見てライフを1つ回復")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.gold.opacity(0.85))
        .foregroundStyle(.black)
        .disabled(!rewardedAds.lifeRefill.isReady)
        .onAppear { rewardedAds.lifeRefill.load() }
    }
}
