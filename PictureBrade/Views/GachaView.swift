//
//  GachaView.swift
//  PictureBrade
//

import SwiftUI
import UIKit

/// バトルでためたポイントでボディ・シャフトのガチャを引く画面（装備はマイコマでコマをタップして行う）
struct GachaView: View {
    @Environment(PartsStore.self) private var parts
    @Environment(\.dismiss) private var dismiss

    @State private var results: [GachaResult]?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    PointsLabel(points: parts.points, size: 22)
                    gachaContent
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("ガチャ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                #if DEBUG
                ToolbarItem(placement: .primaryAction) {
                    Button("+1000pt（デバッグ）", systemImage: "ladybug.fill") { parts.debugAddPoints() }
                        .tint(.orange)
                }
                #endif
            }
            .overlay {
                if let results {
                    GachaResultView(results: results) {
                        withAnimation { self.results = nil }
                    }
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            // 最初のガチャの音が遅れないよう、先に音の準備をしておく
            ImpactSound.shared.prepare()
        }
    }

    // MARK: - ガチャ

    private var gachaContent: some View {
        VStack(spacing: 16) {
            Text("バトルで勝つとポイントがたまる！（負けてもちょっとだけもらえる）")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(PartKind.allCases) { kind in
                banner(kind)
            }
            rateTable
            Label("手に入れたパーツは、ホームの「マイコマ」でコマをタップすると装備できる", systemImage: "wrench.and.screwdriver.fill")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func banner(_ kind: PartKind) -> some View {
        // SSR から3つだけ見せる（全部並べると横に入りきらない）
        let featured = Array(PartCatalog.parts(kind).filter { $0.rarity == .ultraRare }.prefix(3))
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(kind.title)ガチャ")
                        .font(.title2.weight(.black))
                        .foregroundStyle(.white)
                    Text(kind.caption)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                    Text("コンプリート \(parts.ownedCount(kind))/\(PartCatalog.parts(kind).count)")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.gold)
                }
                Spacer()
                HStack(spacing: -10) {
                    ForEach(featured) { part in
                        PartIcon(part: part, size: 54)
                    }
                }
            }
            HStack(spacing: 10) {
                drawButton(kind, count: 1, cost: PartsStore.singleCost, title: "1回")
                drawButton(kind, count: 10, cost: PartsStore.tenCost, title: "10連（SR以上1つ確定）")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    colors: kind == .body
                        ? [Color(red: 0.55, green: 0.15, blue: 0.4), Color(red: 0.2, green: 0.08, blue: 0.35)]
                        : [Color(red: 0.1, green: 0.35, blue: 0.6), Color(red: 0.08, green: 0.08, blue: 0.3)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.2), lineWidth: 1))
    }

    private func drawButton(_ kind: PartKind, count: Int, cost: Int, title: String) -> some View {
        Button {
            guard let drawn = parts.draw(kind, count: count) else { return }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            withAnimation { results = drawn }
        } label: {
            VStack(spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(cost)pt")
                    .font(.caption.monospacedDigit())
                    .opacity(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .tint(count >= 10 ? Theme.accent : Color(red: 0.35, green: 0.3, blue: 0.6))
        .disabled(parts.points < cost)
    }

    private var rateTable: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("出る確率")
                .font(.caption.bold())
            HStack(spacing: 14) {
                ForEach(PartRarity.allCases, id: \.self) { rarity in
                    HStack(spacing: 4) {
                        RarityTag(rarity: rarity)
                        Text("\(Int(rarity.weight))%")
                            .font(.caption.monospacedDigit())
                    }
                }
            }
            Text("持っているパーツが出たら、N 10pt・R 20pt・SR 50pt・SSR 100pt が返ってくる")
                .font(.caption2)
                .opacity(0.7)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.06)))
    }
}

// MARK: - 部品

/// ポイントの表示
struct PointsLabel: View {
    let points: Int
    var size: CGFloat = 15

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.hexagongrid.fill")
                .foregroundStyle(Theme.gold)
            Text("\(points)")
                .monospacedDigit()
            Text("pt")
                .font(.system(size: size * 0.65, weight: .heavy, design: .rounded))
        }
        .font(.system(size: size, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, size * 0.7)
        .padding(.vertical, size * 0.3)
        .background(Capsule().fill(.black.opacity(0.45)))
        .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.6), lineWidth: 1.5))
    }
}

struct RarityTag: View {
    let rarity: PartRarity

    var body: some View {
        Text(rarity.label)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(rarity >= .superRare ? .black : .white)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(Capsule().fill(rarity.color.color))
    }
}

/// パーツの絵。ボディは色付きの円盤とトゲ、シャフトは先端の形で描く
struct PartIcon: View {
    let part: Part
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [part.rarity.color.color.opacity(0.5), .black.opacity(0.6)], center: .center, startRadius: 0, endRadius: size / 2))
            Circle()
                .strokeBorder(part.rarity.color.color, lineWidth: max(1.5, size * 0.05))
            switch part.kind {
            case .body: bodyShape
            case .shaft: shaftShape
            }
        }
        .frame(width: size, height: size)
        // 長いトゲが丸い枠からはみ出さないようにする
        .clipShape(Circle())
    }

    private var bodyShape: some View {
        ZStack {
            ForEach(0..<part.fins, id: \.self) { index in
                Capsule()
                    .fill(part.color.color.mix(with: .black, by: 0.15))
                    .frame(width: size * 0.36 * CGFloat(part.finLength), height: size * 0.1 * CGFloat(part.finWidth))
                    .offset(x: size * (0.08 + 0.18 * CGFloat(part.finLength)))
                    .rotationEffect(.degrees(Double(index) / Double(part.fins) * 360 + 20))
            }
            Circle()
                .fill(LinearGradient(colors: [part.color.color.mix(with: .white, by: 0.3), part.color.color], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size * 0.46, height: size * 0.46)
                .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: max(1, size * 0.03)))
        }
    }

    @ViewBuilder
    private var shaftShape: some View {
        let color = LinearGradient(colors: [part.color.color.mix(with: .white, by: 0.35), part.color.color], startPoint: .leading, endPoint: .trailing)
        let scale = CGFloat(part.tipSize)
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: size * 0.03)
                .fill(color)
                .frame(width: size * 0.4, height: size * 0.1)
            switch part.tip {
            case .wide:
                Rectangle().fill(color).frame(width: size * 0.1 * scale, height: size * 0.24)
                Capsule().fill(color).frame(width: size * 0.5 * scale, height: size * 0.1)
            case .sharp:
                Triangle().fill(color).frame(width: size * 0.3 * scale, height: size * 0.38)
            case .needle:
                Triangle().fill(color).frame(width: size * 0.12 * scale, height: size * 0.44)
            case .flat:
                Rectangle().fill(color).frame(width: size * 0.14, height: size * 0.22)
                RoundedRectangle(cornerRadius: size * 0.03).fill(color).frame(width: size * 0.32 * scale, height: size * 0.12)
            case .ball:
                Rectangle().fill(color).frame(width: size * 0.1, height: size * 0.12)
                Circle().fill(color).frame(width: size * 0.28 * min(1.15, scale), height: size * 0.28 * min(1.15, scale))
            }
        }
        .offset(y: size * 0.02)
    }
}

/// 下向きの三角形（シャフトの先端）
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

struct PartCard: View {
    let part: Part
    let isOwned: Bool
    let isEquipped: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isOwned {
                    PartIcon(part: part, size: 44)
                } else {
                    Image(systemName: "questionmark")
                        .font(.title3.bold())
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.white.opacity(0.06)))
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        RarityTag(rarity: part.rarity)
                        if isEquipped {
                            Text("装備中")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(Theme.gold)
                        }
                    }
                    Text(isOwned ? part.name : "？？？")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(isOwned ? part.bonus.summary : "ガチャで手に入る")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.12, green: 0.08, blue: 0.26)))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(isEquipped ? Theme.gold : .white.opacity(0.1), lineWidth: isEquipped ? 2.5 : 1))
            .opacity(isOwned ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!isOwned)
    }
}

/// 写真だけの能力と、装備を足した能力を並べて見せる
struct BonusStatsView: View {
    let base: BladeStats
    let total: BladeStats

    var body: some View {
        VStack(spacing: 5) {
            row("攻撃", base.attack, total.attack, .red)
            row("防御", base.defense, total.defense, .blue)
            row("持久", base.stamina, total.stamina, .green)
            row("機動", base.speed, total.speed, .yellow)
        }
    }

    private func row(_ label: String, _ base: Double, _ total: Double, _ color: Color) -> some View {
        let diff = Int((total * 100).rounded()) - Int((base * 100).rounded())
        return HStack(spacing: 6) {
            Text(label)
                .font(.caption2.bold())
                .frame(width: 30, alignment: .leading)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12))
                    // 装備で増えた分は明るく、減った分は暗く見せる
                    Capsule().fill(color.mix(with: .white, by: 0.45)).frame(width: proxy.size.width * max(base, total))
                    Capsule().fill(color).frame(width: proxy.size.width * min(base, total))
                }
            }
            .frame(height: 7)
            Text("\(Int((total * 100).rounded()))")
                .font(.caption2.monospacedDigit().bold())
                .frame(width: 24, alignment: .trailing)
            Text(diff == 0 ? "" : (diff > 0 ? "+\(diff)" : "\(diff)"))
                .font(.caption2.monospacedDigit().bold())
                .foregroundStyle(diff > 0 ? .green : .red)
                .frame(width: 28, alignment: .leading)
        }
        .foregroundStyle(.white.opacity(0.9))
    }
}

// MARK: - ガチャの結果

/// ガチャの演出：カプセルが落ちてきて揺れ、光をためて割れ、裏向きのカードが1枚ずつめくれる。
/// いいパーツが入っているほど揺れが長く、光が強くなる（SSR は虹色の確定演出）
private struct GachaResultView: View {
    let results: [GachaResult]
    let onClose: () -> Void

    private enum Stage: Int, Comparable {
        case drop, charge, burst, reveal
        static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    @State private var stage = Stage.drop
    @State private var capsuleOffset: CGFloat = -600
    @State private var tilt: Double = 0
    @State private var glow: Double = 0
    @State private var flash: Double = 0
    @State private var halvesApart = false
    /// SSR が出るときだけ、ための途中でカプセルが金色に変わる
    @State private var capsuleRarity = PartRarity.normal
    @State private var announce: String?
    /// 場に配られたカードの数と、表になったカードの数
    @State private var dealt = 0
    @State private var flipped = 0
    @State private var sparkles: SparkleBurst?
    @State private var skipped = false

    private var best: PartRarity { results.map(\.part.rarity).max() ?? .normal }
    private var isSingle: Bool { results.count == 1 }

    var body: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()
            LightRays(color: rayColor, isRainbow: capsuleRarity == .ultraRare, intensity: glow)
                .ignoresSafeArea()
            if stage < .reveal {
                capsule
                    .offset(y: capsuleOffset)
            }
            if let announce {
                Text(announce)
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .italic()
                    .foregroundStyle(LinearGradient(colors: [.white, Theme.gold, Theme.accent], startPoint: .top, endPoint: .bottom))
                    .shadow(color: Theme.gold, radius: 16)
                    .offset(y: -190)
                    .transition(.scale(scale: 2.5).combined(with: .opacity))
            }
            if stage == .reveal {
                resultsContent
            }
            if let sparkles {
                SparkleBurstView(burst: sparkles)
                    .id(sparkles.id)
                    .allowsHitTesting(false)
            }
            Color.white.opacity(flash)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { skip() }
        .task { await play() }
    }

    private var rayColor: Color {
        stage == .reveal ? best.color.color : capsuleRarity.color.color
    }

    // MARK: カプセル

    private var capsule: some View {
        let color = capsuleRarity.color.color
        return ZStack {
            // 割れると上下に飛んでいく
            UnevenRoundedRectangle(topLeadingRadius: 80, topTrailingRadius: 80)
                .fill(LinearGradient(colors: [color.mix(with: .white, by: 0.5), color], startPoint: .top, endPoint: .bottom))
                .overlay(alignment: .topLeading) {
                    Capsule().fill(.white.opacity(0.6)).frame(width: 40, height: 14).rotationEffect(.degrees(-30)).offset(x: 34, y: 24)
                }
                .frame(width: 160, height: 80)
                .offset(y: halvesApart ? -260 : -40)
                .rotationEffect(.degrees(halvesApart ? -25 : 0))
            UnevenRoundedRectangle(bottomLeadingRadius: 80, bottomTrailingRadius: 80)
                .fill(LinearGradient(colors: [.white, Color(white: 0.75)], startPoint: .top, endPoint: .bottom))
                .frame(width: 160, height: 80)
                .offset(y: halvesApart ? 260 : 40)
                .rotationEffect(.degrees(halvesApart ? 20 : 0))
            Capsule()
                .fill(.black.opacity(0.35))
                .frame(width: 170, height: 10)
                .opacity(halvesApart ? 0 : 1)
        }
        .opacity(halvesApart ? 0 : 1)
        .shadow(color: color.opacity(0.4 + 0.6 * glow), radius: 10 + 40 * glow)
        .scaleEffect(1 + 0.15 * glow)
        .rotationEffect(.degrees(tilt))
    }

    // MARK: 結果

    private var resultsContent: some View {
        VStack(spacing: 18) {
            Text(isSingle ? "ゲット！" : "\(results.count)連の結果")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [Theme.gold, Theme.accent], startPoint: .top, endPoint: .bottom))
                .shadow(color: .black, radius: 4)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: isSingle ? 1 : 5), spacing: 10) {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    GachaCard(result: result, large: isSingle, isFaceUp: index < flipped)
                        .scaleEffect(index < dealt ? 1 : 0.2)
                        .opacity(index < dealt ? 1 : 0)
                        .offset(y: index < dealt ? 0 : 200)
                }
            }
            .frame(maxWidth: isSingle ? 240 : .infinity)
            let refund = results.reduce(0) { $0 + $1.refund }
            Group {
                if refund > 0 {
                    Text("持っていたパーツの分 +\(refund)pt")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.gold)
                }
                Button("OK", action: onClose)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .controlSize(.large)
            }
            .opacity(flipped >= results.count ? 1 : 0)
        }
        .padding(20)
    }

    // MARK: 進行

    private func play() async {
        // SSR はいったん SR の色で見せておき、ための途中で金色に変える
        capsuleRarity = best == .ultraRare ? .superRare : best

        // 1. 上から落ちてきて、ドスンと着地
        withAnimation(.spring(duration: 0.45, bounce: 0.35)) { capsuleOffset = 0 }
        guard await wait(0.45) else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        GachaSound.rattle()

        // 2. カタカタ揺れる（いいものほど多く揺れる）
        let rattles = best >= .superRare ? 5 : 3
        for index in 0..<rattles {
            withAnimation(.spring(duration: 0.15, bounce: 0.6)) { tilt = index.isMultiple(of: 2) ? 14 : -14 }
            GachaSound.rattle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            guard await wait(0.2) else { return }
        }
        withAnimation(.spring(duration: 0.2)) { tilt = 0 }

        // 3. 光をためる
        stage = .charge
        let chargeTime: Double = best >= .superRare ? 1.3 : 0.7
        GachaSound.charge(duration: Float(chargeTime), rarity: best)
        withAnimation(.easeIn(duration: chargeTime)) { glow = 1 }
        if best >= .superRare {
            guard await wait(chargeTime * 0.6) else { return }
            if best == .ultraRare {
                withAnimation(.spring(duration: 0.3)) { capsuleRarity = .ultraRare }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            withAnimation(.spring(duration: 0.35, bounce: 0.5)) { announce = best == .ultraRare ? "SSR確定!!" : "!?" }
            guard await wait(chargeTime * 0.4) else { return }
        } else {
            guard await wait(chargeTime) else { return }
        }

        // 4. 白く光ってカプセルが割れる
        stage = .burst
        GachaSound.burst(rarity: best)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        flash = 1
        sparkles = SparkleBurst(color: best.color.color, isRainbow: best == .ultraRare, count: best >= .superRare ? 70 : 40)
        withAnimation(.easeOut(duration: 0.5)) {
            flash = 0
            halvesApart = true
            announce = nil
        }
        guard await wait(0.35) else { return }

        // 5. カードを配って、1枚ずつめくる
        withAnimation(.easeOut(duration: 0.3)) { stage = .reveal }
        for index in results.indices {
            withAnimation(.spring(duration: 0.35, bounce: 0.3)) { dealt = max(dealt, index + 1) }
            guard await wait(isSingle ? 0.25 : 0.06) else { return }
        }
        guard await wait(0.25) else { return }
        for (index, result) in results.enumerated() {
            let rarity = result.part.rarity
            // SR 以上はめくる前に一瞬ためる
            if rarity >= .superRare {
                guard await wait(0.25) else { return }
            }
            withAnimation { flipped = max(flipped, index + 1) }
            GachaSound.reveal(index: index, rarity: rarity)
            if rarity >= .superRare {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                sparkles = SparkleBurst(color: rarity.color.color, isRainbow: rarity == .ultraRare, count: 36)
            }
            guard await wait(rarity >= .superRare ? 0.45 : 0.16) else { return }
        }
    }

    /// 待つ。演出を飛ばしたら false を返す
    private func wait(_ seconds: Double) async -> Bool {
        try? await Task.sleep(for: .seconds(seconds))
        return !skipped && !Task.isCancelled
    }

    /// タップで演出を飛ばして、全部の結果を見せる
    private func skip() {
        guard flipped < results.count else { return }
        skipped = true
        GachaSound.burst(rarity: best)
        withAnimation(.easeOut(duration: 0.3)) {
            capsuleRarity = best
            stage = .reveal
            glow = 1
            flash = 0
            announce = nil
            dealt = results.count
            flipped = results.count
        }
    }
}

/// 裏向きから表にめくれるカード
private struct GachaCard: View {
    let result: GachaResult
    let large: Bool
    let isFaceUp: Bool

    private var rarity: PartRarity { result.part.rarity }
    private var cardHeight: CGFloat { large ? 300 : 104 }

    var body: some View {
        ZStack {
            front
                .rotation3DEffect(.degrees(isFaceUp ? 0 : -90), axis: (x: 0, y: 1, z: 0))
                .animation(.easeOut(duration: 0.16).delay(isFaceUp ? 0.16 : 0), value: isFaceUp)
            back
                .rotation3DEffect(.degrees(isFaceUp ? 90 : 0), axis: (x: 0, y: 1, z: 0))
                .animation(.easeIn(duration: 0.16).delay(isFaceUp ? 0 : 0.16), value: isFaceUp)
        }
        .frame(height: cardHeight)
    }

    /// 裏面。SR 以上はふちがうっすら光って、いいものが入っているのがわかる
    private var back: some View {
        RoundedRectangle(cornerRadius: large ? 22 : 10)
            .fill(LinearGradient(colors: [Color(red: 0.25, green: 0.15, blue: 0.5), Color(red: 0.1, green: 0.06, blue: 0.25)], startPoint: .top, endPoint: .bottom))
            .overlay(
                Image(systemName: "questionmark")
                    .font(.system(size: large ? 80 : 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: large ? 22 : 10)
                    .strokeBorder(rarity >= .superRare ? rarity.color.color : .white.opacity(0.3), lineWidth: rarity >= .superRare ? 3 : 1.5)
            )
            .shadow(color: rarity >= .superRare ? rarity.color.color.opacity(0.8) : .clear, radius: 8)
    }

    private var front: some View {
        VStack(spacing: large ? 8 : 3) {
            PartIcon(part: result.part, size: large ? 130 : 46)
                .shadow(color: rarity >= .superRare ? rarity.color.color : .clear, radius: 12)
            RarityTag(rarity: rarity)
            Text(result.part.name)
                .font(large ? .title3.weight(.black) : .system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
            if large {
                Text(result.part.bonus.summary)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.85))
                Text(result.part.caption)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .padding(large ? 16 : 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: large ? 22 : 10)
                .fill(RadialGradient(colors: [rarity.color.color.opacity(0.45), Color(red: 0.08, green: 0.05, blue: 0.18)], center: .center, startRadius: 0, endRadius: large ? 200 : 70))
        )
        .overlay {
            if rarity >= .superRare {
                RarityShine(rarity: rarity, cornerRadius: large ? 22 : 10)
            } else {
                RoundedRectangle(cornerRadius: large ? 22 : 10).strokeBorder(rarity.color.color, lineWidth: 1.5)
            }
        }
        .overlay(alignment: .topTrailing) {
            if result.isNew { NewBadge().padding(4) }
        }
    }
}

/// SR・SSR のカードのふちを光がぐるぐる回る
private struct RarityShine: View {
    let rarity: PartRarity
    let cornerRadius: CGFloat

    var body: some View {
        TimelineView(.animation) { timeline in
            let angle = timeline.date.timeIntervalSinceReferenceDate * 180
            let colors: [Color] = rarity == .ultraRare
                ? [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red]
                : [rarity.color.color, .white, rarity.color.color, rarity.color.color.opacity(0.3), rarity.color.color]
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(AngularGradient(colors: colors, center: .center, angle: .degrees(angle)), lineWidth: 3)
        }
    }
}

/// 後ろでゆっくり回る放射状の光。intensity が 1 に近いほど明るい
private struct LightRays: View {
    let color: Color
    let isRainbow: Bool
    let intensity: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = hypot(size.width, size.height)
                let count = 18
                for index in 0..<count {
                    let start = Double(index) / Double(count) * 2 * .pi + time * 0.4
                    var path = Path()
                    path.move(to: center)
                    path.addArc(center: center, radius: radius, startAngle: .radians(start), endAngle: .radians(start + .pi / Double(count) * 0.6), clockwise: false)
                    path.closeSubpath()
                    let rayColor = isRainbow ? Color(hue: (Double(index) / Double(count) + time * 0.1).truncatingRemainder(dividingBy: 1), saturation: 0.7, brightness: 1) : color
                    context.fill(path, with: .color(rayColor.opacity(0.08 + 0.3 * intensity)))
                }
                // 真ん中の光のかたまり
                let glowRadius = 80 + 160 * intensity
                context.fill(
                    Path(ellipseIn: CGRect(x: center.x - glowRadius, y: center.y - glowRadius, width: glowRadius * 2, height: glowRadius * 2)),
                    with: .radialGradient(Gradient(colors: [color.opacity(0.2 + 0.6 * intensity), .clear]), center: center, startRadius: 0, endRadius: glowRadius)
                )
            }
        }
        .allowsHitTesting(false)
    }
}

/// カプセルが割れたときやいいカードがめくれたときに飛び散る光の粒
private struct SparkleBurst: Identifiable {
    struct Particle {
        let angle: Double
        let speed: Double
        let size: CGFloat
        let hue: Double
        let spin: Double
    }

    let id = UUID()
    let start = Date.now
    let color: Color
    let isRainbow: Bool
    let particles: [Particle]

    init(color: Color, isRainbow: Bool, count: Int) {
        self.color = color
        self.isRainbow = isRainbow
        particles = (0..<count).map { _ in
            Particle(angle: .random(in: 0..<(2 * .pi)), speed: .random(in: 180...520), size: .random(in: 6...16),
                     hue: .random(in: 0...1), spin: .random(in: -6...6))
        }
    }
}

private struct SparkleBurstView: View {
    let burst: SparkleBurst
    private let life: Double = 1.3

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(burst.start)
            Canvas { context, size in
                guard elapsed < life else { return }
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let progress = elapsed / life
                for particle in burst.particles {
                    // 勢いよく飛び出して、だんだん遅くなりながら少し落ちる
                    let distance = particle.speed * (1 - pow(1 - min(1, elapsed / 0.9), 3)) * 0.9
                    let x = center.x + cos(particle.angle) * distance
                    let y = center.y + sin(particle.angle) * distance + 120 * elapsed * elapsed
                    let scale = particle.size * (1 - progress * 0.7)
                    let color = burst.isRainbow ? Color(hue: particle.hue, saturation: 0.7, brightness: 1) : burst.color.mix(with: .white, by: particle.hue * 0.6)
                    var star = context
                    star.translateBy(x: x, y: y)
                    star.rotate(by: .radians(particle.spin * elapsed))
                    star.opacity = 1 - progress
                    star.fill(Self.starPath(size: scale), with: .color(color))
                }
            }
        }
        .ignoresSafeArea()
    }

    /// 4つの角がとがったキラキラの形
    private static func starPath(size: CGFloat) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: -size))
            path.addQuadCurve(to: CGPoint(x: size, y: 0), control: .zero)
            path.addQuadCurve(to: CGPoint(x: 0, y: size), control: .zero)
            path.addQuadCurve(to: CGPoint(x: -size, y: 0), control: .zero)
            path.addQuadCurve(to: CGPoint(x: 0, y: -size), control: .zero)
        }
    }
}
