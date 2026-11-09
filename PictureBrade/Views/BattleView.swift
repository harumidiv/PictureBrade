//
//  BattleView.swift
//  PictureBrade
//

import RealityKit
import SwiftUI
import UIKit

struct BattleView: View {
    let game: BattleGame
    @Environment(EnemyCatalog.self) private var enemies
    @Environment(RewardedAds.self) private var rewardedAds
    @Environment(GameCenterManager.self) private var gameCenter
    @Environment(LifeManager.self) private var life
    @Environment(\.dismiss) private var dismiss
    /// ランダム連戦で勝利時に引いた次の相手（表示のたびに変わらないよう保持する）
    @State private var nextEnemy: Enemy?
    @State private var drag: CGSize?
    /// この試合ですでにライフを減らしたか（二重に減らさないため）
    @State private var lifeCharged = false
    /// この勝利で新しく手に入れた報酬（ストーリーの章ボスを初めて倒したとき）
    @State private var earnedRewards: [Reward] = []
    /// ストーリーで勝利後「ストーリーを進める」を選んだときに呼ぶ（やめるを選んだときは呼ばない）
    var onAdvanceStory: () -> Void = {}

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RealityView { content in
                await game.setUp(content: &content)
            }
            .ignoresSafeArea()
            // 3D は画面全体に描かれるので、セーフエリアも含めた大きさで画角を決める
            .onGeometryChange(for: CGSize.self) { proxy in
                CGSize(
                    width: proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing,
                    height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
                )
            } action: { size in
                game.updateViewport(size: size)
            }

            inputLayer
            VStack {
                topBar
                Spacer()
                bottomArea
            }
            .padding()
            overlayMessage
        }
        .statusBarHidden()
        .onChange(of: game.phase) { _, phase in
            // ストーリーで負けたらライフを1つ減らす
            if game.mode == .story, phase == .matchOver(playerWon: false) {
                chargeLife()
            }
            guard phase == .matchOver(playerWon: true) else { return }
            ReviewPrompt.recordWin()
            switch game.mode {
            case .story:
                if let enemy = EnemyCatalog.enemy(forBladeID: game.cpu.id), !enemies.isDefeated(enemy) {
                    earnedRewards = Reward.rewards(for: enemy)
                }
                enemies.markDefeated(bladeID: game.cpu.id, stars: game.earnedStars)
            case .endless:
                enemies.recordStreak(game.winStreak)
                gameCenter.submitEndless(streak: game.winStreak)
                nextEnemy = enemies.randomEnemy(level: EnemyCatalog.randomLevel(forStreak: game.winStreak))
            }
        }
    }

    // MARK: - HUD

    private var topBar: some View {
        HStack(alignment: .top) {
            spinGauge(blade: game.player, image: game.playerImage, spin: game.playerSpin, score: game.playerScore, color: .cyan, skin: game.loadout.skin)
            VStack(spacing: 2) {
                switch game.mode {
                case .story:
                    Text("ROUND \(game.round)")
                        .font(.caption.bold())
                    Text("\(game.playerScore) - \(game.cpuScore)")
                        .font(.system(size: 28, weight: .black, design: .rounded).monospacedDigit())
                    Text("\(game.winningScore)pt先取")
                        .font(.caption2)
                case .endless:
                    Text("\(game.winStreak + 1)戦目")
                        .font(.caption.bold())
                    Text("\(game.winStreak)")
                        .font(.system(size: 28, weight: .black, design: .rounded).monospacedDigit())
                    Text("連勝中・一本勝負")
                        .font(.caption2)
                }
            }
            .foregroundStyle(.white)
            .frame(width: 90)
            spinGauge(blade: game.cpu, image: game.cpuImage, spin: game.cpuSpin, score: game.cpuScore, color: Theme.accent)
        }
    }

    private func spinGauge(blade: Blade, image: UIImage, spin: Float, score: Int, color: Color, skin: BladeSkin = .normal) -> some View {
        VStack(spacing: 4) {
            BladeBadge(image: image, tint: blade.tint.color, size: 44, skin: skin)
            Text(blade.name)
                .font(.caption.bold())
                .lineLimit(1)
                .foregroundStyle(.white)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.15))
                    Capsule().fill(color).frame(width: proxy.size.width * CGFloat(spin))
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var bottomArea: some View {
        switch game.phase {
        case .aiming:
            VStack(spacing: 8) {
                if let drag {
                    powerMeter(power: BattleGame.power(for: drag))
                }
                Text(drag == nil ? "下に引っ張って離すとシュート！" : "離してシュート！")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.black.opacity(0.5)))
            }
        case .battle:
            HStack {
                Text("ドラッグで操作")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Button {
                    game.rush()
                } label: {
                    ZStack {
                        Circle()
                            .trim(from: 0, to: CGFloat(game.rushProgress))
                            .stroke(Theme.gold, lineWidth: 5)
                            .rotationEffect(.degrees(-90))
                        Text("RUSH")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                    }
                    .frame(width: 84, height: 84)
                    .background(Circle().fill(game.rushProgress >= 1 ? Theme.accent : .gray.opacity(0.5)))
                }
                .disabled(game.rushProgress < 1)
            }
        default:
            EmptyView()
        }
    }

    private func powerMeter(power: Float) -> some View {
        VStack(spacing: 4) {
            Text("POWER \(Int(power * 100))%")
                .font(.headline.monospacedDigit())
                .foregroundStyle(power > 0.9 ? Theme.gold : .white)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.2))
                    Capsule()
                        .fill(LinearGradient(colors: [.green, .yellow, .red], startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * CGFloat(power))
                }
            }
            .frame(width: 220, height: 12)
        }
    }

    @ViewBuilder
    private var overlayMessage: some View {
        switch game.phase {
        case .loading:
            ProgressView().tint(.white)
        case .roundOver(let result):
            resultPanel(title: title(for: result), subtitle: subtitle(for: result)) {
                Button("次のラウンド") { game.nextRound() }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
            }
        case .matchOver(let playerWon):
            if playerWon {
                victoryPanel
            } else if game.mode == .endless {
                resultPanel(
                    title: "YOU LOSE…",
                    subtitle: "記録：\(game.streakBeforeLoss)連勝（最高 \(enemies.bestStreak)連勝）"
                ) {
                    VStack(spacing: 10) {
                        if game.canContinue {
                            continueButton
                        }
                        Button {
                            game.resetRun()
                            challenge(enemies.randomEnemy(level: 1))
                        } label: {
                            Text("最初から")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                        quitButton
                    }
                }
            } else {
                resultPanel(title: "YOU LOSE…", subtitle: "\(game.playerScore) - \(game.cpuScore)") {
                    VStack(spacing: 10) {
                        LifeIndicator()
                        if life.canPlay {
                            Button {
                                restartStoryMatch()
                            } label: {
                                Text("もう一度")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.accent)
                            quitButton
                        } else {
                            Text("ライフがなくなりました")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                            LifeRefillButton()
                            quitButton
                        }
                    }
                }
            }
        default:
            EmptyView()
        }
    }

    // MARK: - ライフ（ストーリー）

    private func chargeLife() {
        guard game.mode == .story, !lifeCharged else { return }
        lifeCharged = true
        life.consume()
    }

    private func restartStoryMatch() {
        lifeCharged = false
        game.restartMatch()
    }

    @ViewBuilder
    private var victoryPanel: some View {
        switch game.mode {
        case .story: storyVictoryPanel
        case .endless: endlessVictoryPanel
        }
    }

    /// ストーリー：倒した相手の最後のひと言を出してストーリー画面へ戻る（次の相手はそこで登場する）
    private var storyVictoryPanel: some View {
        let defeatLine = EnemyCatalog.enemy(forBladeID: game.cpu.id)?.defeat ?? ""
        return resultPanel(title: "YOU WIN!", subtitle: "\(game.cpu.name)を撃破！") {
            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    StarRating(stars: game.earnedStars, size: 40, animated: true)
                    Text("\(game.playerScore) - \(game.cpuScore)" + (game.earnedStars == 3 ? "  パーフェクト！" : "  1点も取られずに勝つと★3"))
                        .font(.caption.bold())
                        .foregroundStyle(game.earnedStars == 3 ? Theme.gold : .white.opacity(0.7))
                }
                if !defeatLine.isEmpty {
                    Text("\(game.cpu.name)「\(defeatLine)」")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(earnedRewards) { reward in
                    RewardGetBanner(reward: reward)
                }
                Button {
                    onAdvanceStory()
                    dismiss()
                } label: {
                    Text("ストーリーを進める")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                quitButton
            }
        }
    }

    /// ランダム連戦：勝利時に引いた次の相手を見せて連戦する
    private var endlessVictoryPanel: some View {
        let streak = game.winStreak >= 2 ? "  \(game.winStreak)連勝中！" : ""
        return resultPanel(title: "YOU WIN!", subtitle: "\(game.cpu.name)を撃破！\(streak)") {
            VStack(spacing: 10) {
                if let nextEnemy {
                    let blade = enemies.blade(for: nextEnemy)
                    HStack(spacing: 12) {
                        BladeBadge(image: enemies.image(for: nextEnemy), tint: blade.tint.color, size: 64, spinning: true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("次の相手")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(blade.name)  Lv.\(nextEnemy.level)")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    Button {
                        challenge(nextEnemy)
                    } label: {
                        Text("\(blade.name)に挑む")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                }
                quitButton
            }
        }
    }

    /// 結果パネル共通の「やめる」ボタン（上のボタンと同じ横幅）
    private var quitButton: some View {
        Button {
            dismiss()
        } label: {
            Text("やめる")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.white)
    }

    /// 広告を最後まで見たら、連勝を引き継いで同じ相手に再挑戦
    private var continueButton: some View {
        Button {
            rewardedAds.continuation.show { earned in
                if earned { game.continueAfterLoss() }
            }
        } label: {
            HStack(spacing: 8) {
                if rewardedAds.continuation.isReady {
                    Image(systemName: "play.rectangle.fill")
                } else {
                    ProgressView().tint(.white)
                }
                VStack(spacing: 0) {
                    Text(rewardedAds.continuation.isReady ? "広告を見てコンティニュー" : "広告を準備中…")
                        .font(.headline)
                    Text("\(game.streakBeforeLoss)連勝を引き継いで再挑戦（1回まで）")
                        .font(.caption2)
                        .opacity(0.85)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.gold)
        .foregroundStyle(.black)
        .disabled(!rewardedAds.continuation.isReady)
        .onAppear { rewardedAds.continuation.load() }
    }

    private func challenge(_ enemy: Enemy) {
        nextEnemy = nil
        Task {
            await game.challengeNext(cpu: enemies.blade(for: enemy), image: enemies.image(for: enemy), skill: enemy.skill)
        }
    }

    private func resultPanel<Buttons: View>(title: String, subtitle: String, @ViewBuilder buttons: () -> Buttons) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 40, weight: .black, design: .rounded))
                .italic()
                .foregroundStyle(LinearGradient(colors: [Theme.gold, Theme.accent], startPoint: .top, endPoint: .bottom))
                .shadow(color: .black, radius: 4)
            Text(subtitle)
                .font(.headline)
                .foregroundStyle(.white)
            buttons()
                .controlSize(.large)
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 24).fill(.black.opacity(0.6)))
        .transition(.scale.combined(with: .opacity))
    }

    private func title(for result: BattleGame.RoundResult) -> String {
        switch result {
        case .playerWins(let finish), .cpuWins(let finish): finish.title
        case .draw: "DRAW"
        case .doubleOver: "DOUBLE OVER!"
        }
    }

    private func subtitle(for result: BattleGame.RoundResult) -> String {
        switch result {
        case .playerWins(let finish): "\(game.player.name) が \(finish.points)pt 獲得！"
        case .cpuWins(let finish): "\(game.cpu.name) が \(finish.points)pt 獲得…"
        case .draw: "引き分け"
        case .doubleOver: "両者場外で引き分け"
        }
    }

    // MARK: - Input

    /// 発射前はスリングショット、バトル中はコマの操作に使う
    private var inputLayer: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        drag = value.translation
                        if game.phase == .battle {
                            game.steer(drag: value.translation)
                        }
                    }
                    .onEnded { value in
                        if game.phase == .aiming {
                            game.launch(drag: value.translation)
                        }
                        game.steer(drag: nil)
                        drag = nil
                    }
            )
            .overlay {
                if game.phase == .aiming, let drag {
                    AimArrow(drag: drag)
                }
            }
    }
}

/// 引っ張った方向の逆（発射方向）を示す矢印
private struct AimArrow: View {
    let drag: CGSize

    var body: some View {
        GeometryReader { proxy in
            let start = CGPoint(x: proxy.size.width / 2, y: proxy.size.height * 0.62)
            let power = CGFloat(BattleGame.power(for: drag))
            let length = hypot(drag.width, drag.height)
            let direction = length > 0 ? CGPoint(x: -drag.width / length, y: -drag.height / length) : .zero
            let end = CGPoint(x: start.x + direction.x * (40 + 160 * power), y: start.y + direction.y * (40 + 160 * power))
            // 矢じりの付け根。点線はここで止めて、矢じりから線がはみ出さないようにする
            let headLength: CGFloat = 26
            let headHalfWidth: CGFloat = 15
            let base = CGPoint(x: end.x - direction.x * headLength, y: end.y - direction.y * headLength)
            Path { path in
                path.move(to: start)
                path.addLine(to: base)
            }
            .stroke(Theme.gold, style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [12, 8]))
            Path { path in
                path.move(to: end)
                path.addLine(to: CGPoint(x: base.x - direction.y * headHalfWidth, y: base.y + direction.x * headHalfWidth))
                path.addLine(to: CGPoint(x: base.x + direction.y * headHalfWidth, y: base.y - direction.x * headHalfWidth))
                path.closeSubpath()
            }
            .fill(Theme.gold)
        }
        .allowsHitTesting(false)
    }
}

/// 勝利パネルに出す「報酬ゲット！」
private struct RewardGetBanner: View {
    let reward: Reward
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 12) {
            RewardIcon(reward: reward, size: 26)
                .frame(width: 48, height: 48)
                .background(Circle().fill(.white.opacity(0.12)))
            VStack(alignment: .leading, spacing: 2) {
                Text("報酬ゲット！  \(reward.kindLabel)")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.gold)
                Text(reward.title)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
                Text("ホームの「カスタム」で装備できる")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.gold.opacity(0.15)))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.gold, lineWidth: 2))
        .scaleEffect(appeared ? 1 : 0.6)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.5).delay(0.6)) { appeared = true }
        }
    }
}
