//
//  BattleView.swift
//  PictureBrade
//

import RealityKit
import SwiftUI

struct BattleView: View {
    let game: BattleGame
    @Environment(BladeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var drag: CGSize?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RealityView { content in
                await game.setUp(content: &content)
            }
            .ignoresSafeArea()

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
    }

    // MARK: - HUD

    private var topBar: some View {
        HStack(alignment: .top) {
            spinGauge(blade: game.player, spin: game.playerSpin, score: game.playerScore, color: .cyan)
            VStack(spacing: 2) {
                Text("ROUND \(game.round)")
                    .font(.caption.bold())
                Text("\(game.playerScore) - \(game.cpuScore)")
                    .font(.system(size: 28, weight: .black, design: .rounded).monospacedDigit())
                Text("\(BattleGame.winningScore)pt先取")
                    .font(.caption2)
            }
            .foregroundStyle(.white)
            .frame(width: 90)
            spinGauge(blade: game.cpu, spin: game.cpuSpin, score: game.cpuScore, color: Theme.accent)
        }
        .overlay(alignment: .topLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .offset(y: -8)
        }
    }

    private func spinGauge(blade: Blade, spin: Float, score: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            BladeBadge(image: store.image(for: blade), tint: blade.tint.color, size: 44)
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
            resultPanel(title: playerWon ? "YOU WIN!" : "YOU LOSE…", subtitle: "\(game.playerScore) - \(game.cpuScore)") {
                HStack {
                    Button("もう一度") { game.restartMatch() }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                    Button("やめる") { dismiss() }
                        .buttonStyle(.bordered)
                        .tint(.white)
                }
            }
        default:
            EmptyView()
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
        }
    }

    private func subtitle(for result: BattleGame.RoundResult) -> String {
        switch result {
        case .playerWins(let finish): "\(game.player.name) が \(finish.points)pt 獲得！"
        case .cpuWins(let finish): "\(game.cpu.name) が \(finish.points)pt 獲得…"
        case .draw: "引き分け"
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
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(Theme.gold, style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [12, 8]))
            Circle()
                .fill(Theme.gold)
                .frame(width: 18, height: 18)
                .position(end)
        }
        .allowsHitTesting(false)
    }
}
