//
//  HomeView.swift
//  PictureBrade
//

import SwiftUI
import UIKit

/// タイトル画面風のホーム。自分のコマとライバルの文字が向かい合い、大きなボタンでモードを選ぶ
struct HomeView: View {
    @Environment(BladeStore.self) private var store
    @Environment(EnemyCatalog.self) private var enemies
    @Environment(GameCenterManager.self) private var gameCenter
    @State private var isAddingBlade = false
    @State private var isShowingCollection = false
    @State private var battleMode: BattleGame.Mode?
    /// ホームに飾る自分のコマ（タップで入れ替わる）
    @AppStorage("homeBladeID") private var homeBladeID = ""

    private var hasBlades: Bool { !store.allBlades.isEmpty }

    private var heroBlade: Blade? {
        store.allBlades.first { $0.id.uuidString == homeBladeID } ?? store.allBlades.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HomeBackground()
                VStack(spacing: 0) {
                    HomeLogo()
                        .padding(.top, 12)
                    Spacer(minLength: 8)
                    HomeHero(blade: heroBlade, image: heroBlade.flatMap(store.image(for:)), onTapBlade: cycleHeroBlade, onCreate: { isAddingBlade = true })
                    Spacer(minLength: 8)
                    modeButtons
                    dock
                        .padding(.top, 18)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isAddingBlade) {
                AddBladeView()
            }
            .sheet(isPresented: $isShowingCollection) {
                BladeCollectionView()
            }
            .fullScreenCover(item: $battleMode) { mode in
                switch mode {
                case .story: StoryView()
                case .endless: EndlessSetupView()
                }
            }
        }
    }

    private func cycleHeroBlade() {
        let blades = store.allBlades
        guard blades.count > 1, let current = heroBlade, let index = blades.firstIndex(where: { $0.id == current.id }) else { return }
        homeBladeID = blades[(index + 1) % blades.count].id.uuidString
    }

    // MARK: - モード

    private var modeButtons: some View {
        VStack(spacing: 14) {
            Button {
                battleMode = .story
            } label: {
                ModeButtonLabel(
                    title: "ストーリー",
                    caption: enemies.isStoryCleared ? "全クリア！" : "撃破 \(enemies.defeated.count)/\(EnemyCatalog.enemies.count)",
                    systemImage: "map.fill"
                ) {
                    LifeIndicator()
                }
            }
            .buttonStyle(GameButtonStyle(color: Theme.accent))

            Button {
                battleMode = .endless
            } label: {
                ModeButtonLabel(title: "ランダム連戦", caption: "最高 \(enemies.bestStreak)連勝", systemImage: "bolt.fill") {
                    EmptyView()
                }
            }
            .buttonStyle(GameButtonStyle(color: Color(red: 0.55, green: 0.3, blue: 0.95)))
        }
        .disabled(!hasBlades)
        .opacity(hasBlades ? 1 : 0.5)
    }

    // MARK: - 下のメニュー

    private var dock: some View {
        HStack(spacing: 14) {
            DockButton(title: "コマを作る", systemImage: "camera.fill", color: Theme.gold, isHighlighted: !hasBlades) {
                isAddingBlade = true
            }
            DockButton(title: "マイコマ", systemImage: "square.grid.2x2.fill", color: .cyan, badge: store.blades.count) {
                isShowingCollection = true
            }
            DockButton(title: "ランキング", systemImage: "trophy.fill", color: .orange) {
                gameCenter.showEndlessLeaderboard()
            }
            .disabled(!gameCenter.isAuthenticated)
            .opacity(gameCenter.isAuthenticated ? 1 : 0.5)
        }
    }
}

// MARK: - 背景

/// 回る放射状の光と、漂う文字のコマ
private struct HomeBackground: View {
    private static let drifters: [(String, Color)] = [
        ("火", .orange), ("龍", .red), ("一", .cyan), ("雷", .yellow), ("鬼", .purple),
        ("水", .blue), ("覇", .yellow), ("山", .green), ("風", .mint), ("虎", .orange),
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { proxy in
                let size = proxy.size
                ZStack {
                    Theme.background
                    // 放射状の光（ゆっくり回る）
                    AngularGradient(
                        stops: (0..<24).flatMap { index -> [Gradient.Stop] in
                            let start = Double(index) / 24
                            return [
                                .init(color: .white.opacity(0.07), location: start),
                                .init(color: .white.opacity(0.07), location: start + 1 / 48),
                                .init(color: .clear, location: start + 1 / 48),
                                .init(color: .clear, location: start + 1 / 24),
                            ]
                        },
                        center: .center
                    )
                    .frame(width: size.height * 1.6, height: size.height * 1.6)
                    .rotationEffect(.degrees(time * 6))
                    .position(x: size.width / 2, y: size.height * 0.42)
                    .mask(RadialGradient(colors: [.white, .clear], center: UnitPoint(x: 0.5, y: 0.42), startRadius: 0, endRadius: size.height * 0.6))

                    // 漂う文字のコマ（下から上へゆっくり流れる）
                    ForEach(Self.drifters.indices, id: \.self) { index in
                        let (character, color) = Self.drifters[index]
                        let speed = 0.025 + Double(index % 3) * 0.01
                        let progress = (time * speed + Double(index) * 0.137).truncatingRemainder(dividingBy: 1)
                        let x = size.width * (0.08 + 0.84 * Double((index * 37) % 10) / 9)
                        let y = size.height * (1.1 - 1.2 * progress)
                        Text(character)
                            .font(.system(size: 26 + CGFloat(index % 4) * 8, weight: .black, design: .rounded))
                            .foregroundStyle(color.opacity(0.18))
                            .rotationEffect(.degrees(time * 40 * (index.isMultiple(of: 2) ? 1 : -1)))
                            .position(x: x + 14 * sin(time + Double(index)), y: y)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - ロゴ

/// 立体的なロゴ。光の筋がときどき流れる
private struct HomeLogo: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            // 3秒に1回、左から右へ光が走る
            let shine = (time / 3).truncatingRemainder(dividingBy: 1) * 2.4 - 0.7
            VStack(spacing: 2) {
                ZStack {
                    logoText
                        .foregroundStyle(Color(red: 0.45, green: 0.08, blue: 0.2))
                        .offset(x: 3, y: 5)
                    logoText
                        .foregroundStyle(LinearGradient(colors: [Color(red: 1, green: 0.95, blue: 0.5), Theme.gold, Theme.accent], startPoint: .top, endPoint: .bottom))
                        .overlay {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: shine - 0.12),
                                    .init(color: .white.opacity(0.9), location: shine),
                                    .init(color: .clear, location: shine + 0.12),
                                ],
                                startPoint: .leading, endPoint: .trailing
                            )
                            .mask(logoText)
                        }
                }
                .rotationEffect(.degrees(-4))
                .scaleEffect(1 + 0.025 * sin(time * 2.4))

                Text("写真のコマで、文字をぶっ飛ばせ！")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(.black.opacity(0.45)))
                    .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.6), lineWidth: 1.5))
                    .padding(.top, 6)
            }
        }
    }

    private var logoText: some View {
        Text("PHOTO BLADE")
            .font(.system(size: 46, weight: .black, design: .rounded))
            .italic()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

// MARK: - 中央の対決シーン

/// 自分のコマと、入れ替わり登場するライバルの文字が VS で向かい合う
private struct HomeHero: View {
    let blade: Blade?
    let image: UIImage?
    let onTapBlade: () -> Void
    let onCreate: () -> Void

    @State private var rival = RivalCharacter.random()
    @State private var rivalVisible = true
    @State private var bounce = false
    @State private var tapBoost = false

    var body: some View {
        ZStack {
            stadium
            HStack(alignment: .bottom) {
                player
                Spacer()
                rivalView
            }
            .padding(.horizontal, 8)

            Text("VS")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .italic()
                .foregroundStyle(LinearGradient(colors: [.white, Theme.gold], startPoint: .top, endPoint: .bottom))
                .shadow(color: Theme.accent, radius: 0, x: 3, y: 3)
                .shadow(color: .black.opacity(0.5), radius: 6)
                .scaleEffect(bounce ? 1.12 : 0.95)
                .offset(y: -40)
        }
        .frame(height: 250)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { bounce = true }
        }
        .task {
            // ライバルの文字が数秒ごとに入れ替わる
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                withAnimation(.easeIn(duration: 0.2)) { rivalVisible = false }
                try? await Task.sleep(for: .seconds(0.25))
                rival = RivalCharacter.random()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { rivalVisible = true }
            }
        }
    }

    /// 足元の小さなスタジアム
    private var stadium: some View {
        Ellipse()
            .fill(RadialGradient(colors: [Color(red: 0.25, green: 0.45, blue: 1), Color(red: 0.1, green: 0.18, blue: 0.55)], center: .center, startRadius: 10, endRadius: 180))
            .overlay(Ellipse().strokeBorder(.white.opacity(0.8), lineWidth: 5))
            .overlay(Ellipse().inset(by: 30).stroke(Color(red: 0.4, green: 0.8, blue: 1).opacity(0.7), lineWidth: 2))
            .frame(height: 110)
            .shadow(color: Color(red: 0.3, green: 0.5, blue: 1).opacity(0.6), radius: 20)
            .offset(y: 70)
    }

    @ViewBuilder
    private var player: some View {
        if let blade {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { tapBoost = true }
                Task {
                    try? await Task.sleep(for: .seconds(0.2))
                    tapBoost = false
                    onTapBlade()
                }
            } label: {
                VStack(spacing: 6) {
                    BladeBadge(image: image, tint: blade.tint.color, size: 140, spinning: true)
                        .id(blade.id)
                        .shadow(color: blade.tint.color.opacity(0.8), radius: 16)
                        .scaleEffect(tapBoost ? 1.15 : 1)
                        .rotationEffect(.degrees(tapBoost ? -12 : 0))
                    NameTag(text: blade.name, color: .cyan)
                }
            }
            .buttonStyle(.plain)
        } else {
            Button(action: onCreate) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.08))
                            .overlay(Circle().strokeBorder(.white.opacity(0.6), style: StrokeStyle(lineWidth: 3, dash: [8, 6])))
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(width: 140, height: 140)
                    .scaleEffect(bounce ? 1.05 : 0.97)
                    NameTag(text: "コマを作ろう！", color: Theme.gold)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var rivalView: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [rival.color.opacity(0.9), rival.color.opacity(0.35)], center: .center, startRadius: 0, endRadius: 55))
                Circle()
                    .strokeBorder(LinearGradient(colors: [.white, .gray, .white], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 5)
                Text(rival.character)
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 2, y: 2)
            }
            .frame(width: 110, height: 110)
            .shadow(color: rival.color.opacity(0.7), radius: 14)
            NameTag(text: "ライバル", color: Theme.accent)
        }
        .scaleEffect(rivalVisible ? 1 : 0.2)
        .opacity(rivalVisible ? 1 : 0)
        .rotationEffect(.degrees(rivalVisible ? 0 : 180))
        .offset(y: -10)
    }
}

/// ホームで入れ替わるライバルの文字（画像を作らず、その場で文字を描く）
private struct RivalCharacter {
    let character: String
    let color: Color

    static func random() -> RivalCharacter {
        let colors: [Color] = [.red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink]
        // 絵文字は文字色が付かないため、ここでは漢字・かな・記号だけを使う
        var character = RandomCharacterPool.kanji.randomElement() ?? "覇"
        if Bool.random(), let kana = RandomCharacterPool.kana.randomElement() {
            character = kana
        }
        return RivalCharacter(character: character, color: colors.randomElement()!)
    }
}

private struct NameTag: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.85)))
            .overlay(Capsule().strokeBorder(.white.opacity(0.7), lineWidth: 1.5))
    }
}

// MARK: - ボタン

/// 押すと沈む、厚みのあるゲーム風ボタン
private struct GameButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        let depth: CGFloat = 7
        configuration.label
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [color.mix(with: .white, by: 0.25), color], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.5), lineWidth: 2))
            )
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(color.mix(with: .black, by: 0.45))
                    .offset(y: configuration.isPressed ? 2 : depth)
            )
            .offset(y: configuration.isPressed ? depth - 2 : 0)
            .padding(.bottom, depth)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

private struct ModeButtonLabel<Accessory: View>: View {
    let title: String
    let caption: String
    let systemImage: String
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .bold))
                .frame(width: 52, height: 52)
                .background(Circle().fill(.black.opacity(0.2)))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .shadow(color: .black.opacity(0.3), radius: 0, x: 1, y: 2)
                HStack(spacing: 8) {
                    Text(caption)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .opacity(0.9)
                    accessory()
                        .scaleEffect(0.8, anchor: .leading)
                }
            }
            Spacer()
            Image(systemName: "play.fill")
                .font(.title3.bold())
                .opacity(0.8)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

/// 下に並ぶ丸いメニューボタン
private struct DockButton: View {
    let title: String
    let systemImage: String
    let color: Color
    var badge = 0
    var isHighlighted = false
    let action: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(color.mix(with: .black, by: 0.2)))
                    .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 2))
                    .shadow(color: color.opacity(0.6), radius: isHighlighted && pulse ? 14 : 4)
                    .scaleEffect(isHighlighted && pulse ? 1.1 : 1)
                    .overlay(alignment: .topTrailing) {
                        if badge > 0 {
                            Text("\(badge)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Theme.accent))
                                .offset(x: 4, y: -2)
                        }
                    }
                Text(title)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

// MARK: - マイコマ

/// 自分のコマの一覧（削除もここから）
private struct BladeCollectionView: View {
    @Environment(BladeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isAddingBlade = false
    @State private var bladeToDelete: Blade?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if store.blades.isEmpty {
                        Button {
                            isAddingBlade = true
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: "person.crop.square.badge.camera")
                                    .font(.system(size: 44))
                                Text("まずは写真からコマを作ろう！")
                                    .font(.headline)
                                Text("写真アプリで被写体を長押し →「コピー」で切り抜けます")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8])))
                        }
                    }
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(store.blades) { blade in
                            BladeCard(blade: blade, image: store.image(for: blade))
                                .contextMenu {
                                    Button("削除", systemImage: "trash", role: .destructive) {
                                        bladeToDelete = blade
                                    }
                                }
                        }
                    }
                    if !store.starterBlades.isEmpty {
                        NavigationLink("ファイターを見る（\(store.starterBlades.count)）") {
                            FighterListView()
                        }
                        .tint(Theme.gold)
                    }
                }
                .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("マイコマ（\(store.blades.count)）")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("コマを作る", systemImage: "plus.circle.fill") { isAddingBlade = true }
                        .tint(Theme.gold)
                }
            }
            .sheet(isPresented: $isAddingBlade) {
                AddBladeView()
            }
            .confirmationDialog(
                "「\(bladeToDelete?.name ?? "")」を削除しますか？",
                isPresented: Binding(get: { bladeToDelete != nil }, set: { if !$0 { bladeToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    if let bladeToDelete { store.delete(bladeToDelete) }
                }
            }
        }
    }
}
