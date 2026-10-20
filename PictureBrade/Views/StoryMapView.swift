//
//  StoryMapView.swift
//  PictureBrade
//

import SwiftUI
import UIKit

/// ストーリーの冒険マップ。下のスタートから道をたどって、いちばん上のゴールを目指す
struct StoryMapView: View {
    @Environment(EnemyCatalog.self) private var enemies
    let story: StoryKind
    let playerImage: UIImage?
    let playerTint: Color
    /// 選んでいるステージ（nil ならゴール＝エンディング）
    @Binding var selection: Enemy?

    @State private var scrollPosition = ScrollPosition()
    @State private var didInitialScroll = false
    /// 自分のコマがいる道の上の位置（route の番号。途中は小数）
    @State private var avatarProgress: Double?

    var body: some View {
        GeometryReader { proxy in
            let layout = StoryMapLayout(story: story, width: proxy.size.width)
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    terrain(layout)
                    decorations(layout)
                    road(layout)
                    signs(layout)
                    goal(layout)
                    stages(layout)
                    avatar(layout)
                }
                .frame(width: layout.width, height: layout.height)
            }
            .scrollPosition($scrollPosition)
            .onChange(of: proxy.size, initial: true) { _, size in
                // 表示直後は大きさが決まっていないことがあるので、決まってから1回だけスクロールする
                guard !didInitialScroll, size.width > 100, size.height > 100 else { return }
                didInitialScroll = true
                scrollToCurrent(layout, viewport: size.height, animated: false)
            }
            .onChange(of: enemies.nextStoryEnemy(in: story)) {
                scrollToCurrent(layout, viewport: proxy.size.height, animated: true)
            }
            .onChange(of: selection) { old, new in
                moveAvatar(layout, from: old, to: new)
            }
        }
    }

    /// ステージ（nil ならゴール）の道の上の番号
    private func routeIndex(of stage: Enemy?, _ layout: StoryMapLayout) -> Int {
        guard let stage, let index = story.enemies.firstIndex(of: stage) else {
            return enemies.isStoryCleared(story) ? layout.route.count - 1 : currentRouteIndex(layout)
        }
        return index + 1
    }

    /// 選んだステージまで、自分のコマを道に沿って移動させる。遠いほど時間をかける
    private func moveAvatar(_ layout: StoryMapLayout, from old: Enemy?, to new: Enemy?) {
        let from = avatarProgress ?? Double(routeIndex(of: old, layout))
        let target = Double(routeIndex(of: new, layout))
        avatarProgress = from
        let steps = abs(target - from)
        guard steps > 0 else { return }
        withAnimation(.easeInOut(duration: min(0.3 + 0.12 * steps, 1.4))) {
            avatarProgress = target
        }
    }

    /// いま挑む場所が画面の真ん中に来るようにスクロールする
    private func scrollToCurrent(_ layout: StoryMapLayout, viewport: CGFloat, animated: Bool) {
        let point = layout.route[currentRouteIndex(layout)]
        let y = min(max(point.y - viewport / 2, 0), max(layout.height - viewport, 0))
        if animated {
            withAnimation { scrollPosition.scrollTo(y: y) }
        } else {
            scrollPosition.scrollTo(y: y)
        }
    }

    // MARK: - 地形

    private func isReached(_ chapter: StoryChapter) -> Bool {
        chapter.enemies.contains { enemies.isRevealed($0) }
    }

    private func terrain(_ layout: StoryMapLayout) -> some View {
        ForEach(story.chapters) { chapter in
            let band = layout.band(for: chapter.number)
            let theme = StoryMapTheme(story: story, chapter: chapter.number)
            // 下の章とのつなぎ目をぼかすため、下に少しはみ出させて透明にしていく
            let overlap: CGFloat = chapter.number == 1 ? 0 : 60
            let height = band.bottom - band.top + overlap
            Rectangle()
                .fill(LinearGradient(colors: [theme.top, theme.bottom], startPoint: .top, endPoint: .bottom))
                .overlay(Color.black.opacity(isReached(chapter) ? 0 : 0.45))
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: (height - overlap) / height),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: layout.width, height: height)
                .position(x: layout.width / 2, y: band.top + height / 2)
        }
    }

    private func decorations(_ layout: StoryMapLayout) -> some View {
        ForEach(layout.decorations) { decoration in
            let theme = StoryMapTheme(story: story, chapter: decoration.chapter)
            let reached = story.chapters.first { $0.number == decoration.chapter }.map(isReached) ?? false
            Image(systemName: theme.symbols[decoration.variant % theme.symbols.count])
                .font(.system(size: decoration.size))
                .foregroundStyle(theme.decoration)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 2)
                .opacity(reached ? 0.9 : 0.35)
                .position(decoration.point)
        }
    }

    // MARK: - 道

    /// いま挑む場所（道の上での番号）。全部倒したらゴール
    private func currentRouteIndex(_ layout: StoryMapLayout) -> Int {
        guard let next = enemies.nextStoryEnemy(in: story),
              let index = story.enemies.firstIndex(of: next) else { return layout.route.count - 1 }
        return index + 1
    }

    private func road(_ layout: StoryMapLayout) -> some View {
        let current = currentRouteIndex(layout)
        let last = layout.route.count - 1
        let dots = StrokeStyle(lineWidth: 8, lineCap: .round, dash: [0.1, 16])
        return ZStack(alignment: .topLeading) {
            // 土の道
            layout.routePath(from: 0, to: last)
                .stroke(Color(red: 0.97, green: 0.9, blue: 0.72).opacity(0.45),
                        style: StrokeStyle(lineWidth: 26, lineCap: .round, lineJoin: .round))
            // 進んだところは白い点、まだのところは薄い点
            layout.routePath(from: current, to: last)
                .stroke(.white.opacity(0.4), style: dots)
            layout.routePath(from: 0, to: current)
                .stroke(.white, style: dots)
                .shadow(color: Theme.gold.opacity(0.8), radius: 4)
        }
        .allowsHitTesting(false)
    }

    // MARK: - 看板・ゴール

    private func signs(_ layout: StoryMapLayout) -> some View {
        ForEach(story.chapters) { chapter in
            let reached = isReached(chapter)
            VStack(spacing: 0) {
                Text("第\(chapter.number)章")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                Text(reached ? chapter.title : "？？？")
                    .font(.system(size: 17, weight: .black, design: .rounded))
            }
            .foregroundStyle(Color(red: 0.32, green: 0.18, blue: 0.08))
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [Color(red: 0.93, green: 0.76, blue: 0.5), Color(red: 0.8, green: 0.6, blue: 0.36)],
                                         startPoint: .top, endPoint: .bottom))
            )
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(red: 0.45, green: 0.27, blue: 0.12), lineWidth: 3))
            .shadow(color: .black.opacity(0.4), radius: 4, y: 3)
            .opacity(reached ? 1 : 0.75)
            .position(x: layout.width / 2, y: layout.signY(for: chapter.number))
        }
        .allowsHitTesting(false)
    }

    private func goal(_ layout: StoryMapLayout) -> some View {
        let cleared = enemies.isStoryCleared(story)
        let isSelected = cleared && selection == nil
        return Button {
            if cleared { selection = nil }
        } label: {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Theme.gold, Color(red: 0.75, green: 0.45, blue: 0.1)], center: .center, startRadius: 2, endRadius: 40))
                Circle().strokeBorder(.white, lineWidth: 4)
                Image(systemName: cleared ? "crown.fill" : "flag.checkered")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 2)
            }
            .frame(width: 76, height: 76)
            .overlay(Circle().stroke(Theme.gold, lineWidth: isSelected ? 4 : 0).padding(-6))
            .shadow(color: Theme.gold.opacity(0.6), radius: 12)
            .overlay(alignment: .bottom) {
                Text(cleared ? "エンディング" : "ゴール")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .fixedSize()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .background(Capsule().fill(.black.opacity(0.5)))
                    .offset(y: 22)
            }
        }
        .buttonStyle(.plain)
        .allowsHitTesting(cleared)
        .position(layout.goal)
    }

    // MARK: - ステージ

    private func stages(_ layout: StoryMapLayout) -> some View {
        ForEach(Array(story.enemies.enumerated()), id: \.element.id) { index, enemy in
            let chapterEnemies = story.enemies.filter { $0.level == enemy.level }
            let number = (chapterEnemies.firstIndex(of: enemy) ?? 0) + 1
            let status: StageNode.Status = enemies.isDefeated(enemy) ? .defeated
                : enemy == enemies.nextStoryEnemy(in: story) ? .next : .locked
            StageNode(
                enemy: enemy,
                label: "\(enemy.level)-\(number)",
                status: status,
                isBoss: enemy == chapterEnemies.last,
                isSelected: selection == enemy,
                accent: StoryMapTheme(story: story, chapter: enemy.level).accent
            ) {
                selection = enemy
            }
            .position(layout.nodes[index])
        }
    }

    /// 自分のコマ。選んだステージの上で跳ねていて、別のステージを選ぶと道に沿って移動する
    private func avatar(_ layout: StoryMapLayout) -> some View {
        PlayerMarker(image: playerImage, tint: playerTint)
            .modifier(RouteFollower(progress: avatarProgress ?? Double(routeIndex(of: selection, layout)), layout: layout))
            .allowsHitTesting(false)
    }
}

// MARK: - 部品

/// マップ上のステージの丸
private struct StageNode: View {
    enum Status { case defeated, next, locked }

    let enemy: Enemy
    let label: String
    let status: Status
    let isBoss: Bool
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    @State private var pulse = false

    private var size: CGFloat { isBoss ? 60 : 50 }

    var body: some View {
        Button(action: action) {
            ZStack {
                switch status {
                case .defeated:
                    Circle().fill(.white)
                    Circle().strokeBorder(accent, lineWidth: 4)
                    Text(enemy.character)
                        .font(.system(size: size * 0.5, weight: .black, design: .rounded))
                        .foregroundStyle(Color(enemy.color))
                case .next:
                    Circle().fill(Color(red: 0.9, green: 0.16, blue: 0.2))
                    Circle().strokeBorder(.white, lineWidth: 4)
                    Text("？")
                        .font(.system(size: size * 0.48, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                case .locked:
                    // 後ろの道が透けないよう、不透明な暗い赤にする
                    Circle().fill(Color(red: 0.42, green: 0.12, blue: 0.16))
                    Circle().strokeBorder(.white.opacity(0.45), lineWidth: 3)
                    Image(systemName: "lock.fill")
                        .font(.system(size: size * 0.32, weight: .bold))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.4), radius: 3, y: 3)
            .background {
                if status == .next {
                    Circle()
                        .stroke(Theme.gold, lineWidth: 4)
                        .scaleEffect(pulse ? 1.7 : 1)
                        .opacity(pulse ? 0 : 0.9)
                }
            }
            .overlay {
                if isSelected {
                    Circle().stroke(Theme.gold, lineWidth: 4).padding(-6)
                }
            }
            .overlay(alignment: .top) {
                if isBoss {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.gold)
                        .shadow(color: .black.opacity(0.5), radius: 1, y: 1)
                        .offset(y: -16)
                }
            }
            .overlay(alignment: .topTrailing) {
                if status == .defeated {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white, .green)
                        .offset(x: 6, y: -4)
                }
            }
            .overlay(alignment: .bottom) {
                Text(label)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .fixedSize()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .background(Capsule().fill(.black.opacity(0.5)))
                    .offset(y: 16)
            }
        }
        .buttonStyle(.plain)
        .allowsHitTesting(status != .locked)
        .onAppear {
            guard status == .next else { return }
            withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) { pulse = true }
        }
    }
}

/// マップ上で跳ねている自分のコマ
private struct PlayerMarker: View {
    let image: UIImage?
    let tint: Color

    @State private var hop = false

    var body: some View {
        VStack(spacing: 2) {
            BladeBadge(image: image, tint: tint, size: 44, spinning: true)
                .shadow(color: .black.opacity(0.4), radius: 3, y: 3)
                .offset(y: hop ? -8 : 0)
            Ellipse()
                .fill(.black.opacity(0.3))
                .frame(width: hop ? 22 : 32, height: 7)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { hop = true }
        }
    }
}

/// 道の上の位置（route の番号。途中は小数）にビューを置く。番号をアニメーションさせると道に沿って動く
private struct RouteFollower: ViewModifier, Animatable {
    var progress: Double
    let layout: StoryMapLayout

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let point = layout.point(onRoute: progress)
        // ステージの丸の上に乗せる
        content.position(x: point.x, y: point.y - 40)
    }
}

// MARK: - 章ごとの見た目

private struct StoryMapTheme {
    let top: Color
    let bottom: Color
    let decoration: Color
    let accent: Color
    let symbols: [String]

    private init(_ top: Color, _ bottom: Color, decoration: Color, accent: Color, symbols: [String]) {
        self.top = top
        self.bottom = bottom
        self.decoration = decoration
        self.accent = accent
        self.symbols = symbols
    }

    init(story: StoryKind, chapter: Int) {
        switch story {
        case .kanji: self = Self.kanji(chapter)
        case .hiragana: self = Self.hiragana(chapter)
        case .emoji: self = Self.emoji(chapter)
        }
    }

    private static func kanji(_ chapter: Int) -> StoryMapTheme {
        switch chapter {
        case 1: // はじまりの文字：草原
            StoryMapTheme(Color(red: 0.5, green: 0.76, blue: 0.4), Color(red: 0.36, green: 0.62, blue: 0.3),
                          decoration: Color(red: 0.16, green: 0.42, blue: 0.16), accent: Color(red: 0.25, green: 0.65, blue: 0.3),
                          symbols: ["tree.fill", "leaf.fill", "camera.macro", "tree.fill"])
        case 2: // 五行の試練：荒野
            StoryMapTheme(Color(red: 0.9, green: 0.74, blue: 0.46), Color(red: 0.8, green: 0.6, blue: 0.34),
                          decoration: Color(red: 0.6, green: 0.36, blue: 0.16), accent: Color(red: 0.9, green: 0.5, blue: 0.15),
                          symbols: ["mountain.2.fill", "flame.fill", "drop.fill", "leaf.fill"])
        case 3: // 荒ぶる自然：嵐の森
            StoryMapTheme(Color(red: 0.26, green: 0.5, blue: 0.5), Color(red: 0.18, green: 0.4, blue: 0.4),
                          decoration: Color(red: 0.75, green: 0.9, blue: 0.95), accent: Color(red: 0.2, green: 0.6, blue: 0.85),
                          symbols: ["cloud.bolt.fill", "wind", "tornado", "cloud.rain.fill"])
        case 4: // 伝説の獣：火山
            StoryMapTheme(Color(red: 0.58, green: 0.3, blue: 0.24), Color(red: 0.44, green: 0.2, blue: 0.2),
                          decoration: Color(red: 1, green: 0.55, blue: 0.25), accent: Color(red: 0.85, green: 0.25, blue: 0.2),
                          symbols: ["mountain.2.fill", "flame.fill", "pawprint.fill", "flame.fill"])
        default: // 覇王の城：夜
            StoryMapTheme(Color(red: 0.14, green: 0.08, blue: 0.3), Color(red: 0.26, green: 0.14, blue: 0.42),
                          decoration: Color(red: 0.95, green: 0.85, blue: 0.5), accent: Color(red: 0.6, green: 0.35, blue: 0.9),
                          symbols: ["moon.stars.fill", "sparkles", "building.columns.fill", "star.fill"])
        }
    }

    private static func hiragana(_ chapter: Int) -> StoryMapTheme {
        switch chapter {
        case 1: // はじまりのあ行：こどもの国の広場
            StoryMapTheme(Color(red: 0.62, green: 0.86, blue: 0.5), Color(red: 0.48, green: 0.76, blue: 0.4),
                          decoration: Color(red: 1, green: 0.55, blue: 0.6), accent: Color(red: 0.95, green: 0.45, blue: 0.5),
                          symbols: ["gift.fill", "camera.macro", "tree.fill", "star.fill"])
        case 2: // くるくるの丘：お花畑
            StoryMapTheme(Color(red: 0.98, green: 0.76, blue: 0.84), Color(red: 0.9, green: 0.6, blue: 0.74),
                          decoration: Color(red: 0.75, green: 0.3, blue: 0.55), accent: Color(red: 0.85, green: 0.35, blue: 0.65),
                          symbols: ["camera.macro", "heart.fill", "leaf.fill", "sparkle"])
        case 3: // にごりの洞窟
            StoryMapTheme(Color(red: 0.42, green: 0.38, blue: 0.36), Color(red: 0.3, green: 0.27, blue: 0.27),
                          decoration: Color(red: 0.6, green: 0.85, blue: 1), accent: Color(red: 0.55, green: 0.45, blue: 0.85),
                          symbols: ["diamond.fill", "mountain.2.fill", "drop.fill", "sparkle"])
        case 4: // ちいさな入り江：海辺
            StoryMapTheme(Color(red: 0.45, green: 0.78, blue: 0.95), Color(red: 0.95, green: 0.88, blue: 0.66),
                          decoration: Color(red: 0.1, green: 0.45, blue: 0.75), accent: Color(red: 0.15, green: 0.55, blue: 0.9),
                          symbols: ["water.waves", "fish.fill", "sun.max.fill", "drop.fill"])
        default: // しりとりの塔：夕焼け
            StoryMapTheme(Color(red: 0.98, green: 0.6, blue: 0.4), Color(red: 0.8, green: 0.4, blue: 0.55),
                          decoration: Color(red: 1, green: 0.95, blue: 0.7), accent: Color(red: 0.95, green: 0.55, blue: 0.2),
                          symbols: ["building.columns.fill", "star.fill", "sparkles", "flag.fill"])
        }
    }

    private static func emoji(_ chapter: Int) -> StoryMapTheme {
        switch chapter {
        case 1: // にこにこ広場：街
            StoryMapTheme(Color(red: 0.62, green: 0.82, blue: 0.98), Color(red: 0.5, green: 0.7, blue: 0.9),
                          decoration: Color(red: 1, green: 0.85, blue: 0.2), accent: Color(red: 1, green: 0.7, blue: 0.1),
                          symbols: ["face.smiling.inverse", "building.2.fill", "bubble.left.fill", "heart.fill"])
        case 2: // どうぶつジャングル
            StoryMapTheme(Color(red: 0.25, green: 0.6, blue: 0.3), Color(red: 0.16, green: 0.46, blue: 0.24),
                          decoration: Color(red: 0.75, green: 0.95, blue: 0.4), accent: Color(red: 0.95, green: 0.6, blue: 0.15),
                          symbols: ["pawprint.fill", "tree.fill", "leaf.fill", "bird.fill"])
        case 3: // まんぷく横丁：屋台
            StoryMapTheme(Color(red: 0.98, green: 0.72, blue: 0.4), Color(red: 0.9, green: 0.55, blue: 0.3),
                          decoration: Color(red: 0.6, green: 0.2, blue: 0.1), accent: Color(red: 0.9, green: 0.3, blue: 0.2),
                          symbols: ["fork.knife", "cup.and.saucer.fill", "birthday.cake.fill", "carrot.fill"])
        case 4: // のりものハイウェイ
            StoryMapTheme(Color(red: 0.55, green: 0.58, blue: 0.64), Color(red: 0.42, green: 0.45, blue: 0.52),
                          decoration: Color(red: 1, green: 0.9, blue: 0.3), accent: Color(red: 0.2, green: 0.5, blue: 0.95),
                          symbols: ["car.fill", "bicycle", "fuelpump.fill", "road.lanes"])
        default: // 宇宙の果て
            StoryMapTheme(Color(red: 0.04, green: 0.04, blue: 0.16), Color(red: 0.12, green: 0.08, blue: 0.3),
                          decoration: Color(red: 0.8, green: 0.9, blue: 1), accent: Color(red: 0.45, green: 0.85, blue: 0.4),
                          symbols: ["moon.stars.fill", "sparkles", "globe.asia.australia.fill", "star.fill"])
        }
    }
}

// MARK: - 配置

/// マップ上の位置の計算。ステージ1が下、ゴールが上
struct StoryMapLayout {
    struct Band {
        let top: CGFloat
        let bottom: CGFloat
    }

    struct Decoration: Identifiable {
        let id: Int
        let chapter: Int
        let variant: Int
        let point: CGPoint
        let size: CGFloat
    }

    static let spacing: CGFloat = 92
    static let chapterGap: CGFloat = 96
    static let bottomPadding: CGFloat = 170
    static let topPadding: CGFloat = 210

    let width: CGFloat
    let height: CGFloat
    /// ステージの位置（story.enemies と同じ順）
    let nodes: [CGPoint]
    /// スタート → ステージ → ゴールの順に並べた道
    let route: [CGPoint]
    let goal: CGPoint
    private let bands: [Int: Band]
    private(set) var decorations: [Decoration] = []

    let story: StoryKind

    init(story: StoryKind, width: CGFloat) {
        self.story = story
        self.width = width
        let enemies = story.enemies

        // 下からの距離。章が変わるところは看板のぶん間をあける
        var fromBottom: [CGFloat] = []
        var distance = Self.bottomPadding
        for (index, enemy) in enemies.enumerated() {
            if index > 0 {
                distance += enemy.level != enemies[index - 1].level ? Self.spacing + Self.chapterGap : Self.spacing
            }
            fromBottom.append(distance)
        }
        let height = (fromBottom.last ?? 0) + Self.topPadding
        self.height = height

        // 左右にくねくね曲がる道
        let amplitude = width * 0.27
        let nodes = fromBottom.enumerated().map { index, distance in
            CGPoint(x: width / 2 + amplitude * sin(CGFloat(index) * 0.85), y: height - distance)
        }
        self.nodes = nodes
        goal = CGPoint(x: width / 2, y: 100)
        route = [CGPoint(x: width / 2, y: height + 20)] + nodes + [goal]

        var bands: [Int: Band] = [:]
        for chapter in story.chapters {
            guard let first = enemies.firstIndex(where: { $0.level == chapter.number }),
                  let last = enemies.lastIndex(where: { $0.level == chapter.number }) else { continue }
            let bottom = first == 0 ? height : (nodes[first].y + nodes[first - 1].y) / 2
            let top = last == nodes.count - 1 ? 0 : (nodes[last].y + nodes[last + 1].y) / 2
            bands[chapter.number] = Band(top: top, bottom: bottom)
        }
        self.bands = bands
        decorations = makeDecorations()
    }

    func band(for chapter: Int) -> Band {
        bands[chapter] ?? Band(top: 0, bottom: 0)
    }

    /// 章の看板の位置（章の入り口）
    func signY(for chapter: Int) -> CGFloat {
        chapter == 1 ? height - Self.bottomPadding / 2 : band(for: chapter).bottom
    }

    /// 道の一部（route[from] から route[to] まで）。ステージを必ず通るなめらかな曲線にする
    func routePath(from start: Int, to end: Int) -> Path {
        Path { path in
            guard start < end, route.indices.contains(start), route.indices.contains(end) else { return }
            path.move(to: route[start])
            for index in start..<end {
                let (_, control1, control2, p2) = segment(index)
                path.addCurve(to: p2, control1: control1, control2: control2)
            }
        }
    }

    /// 道の上の点（route の番号。途中は小数で、曲線に沿った位置になる）
    func point(onRoute progress: Double) -> CGPoint {
        let clamped = min(max(progress, 0), Double(route.count - 1))
        let index = min(Int(clamped), route.count - 2)
        let t = CGFloat(clamped - Double(index))
        let (p1, c1, c2, p2) = segment(index)
        let u = 1 - t
        let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
        return CGPoint(
            x: a * p1.x + b * c1.x + c * c2.x + d * p2.x,
            y: a * p1.y + b * c1.y + c * c2.y + d * p2.y
        )
    }

    /// route[index] から route[index + 1] までの曲線（始点・制御点2つ・終点）
    private func segment(_ index: Int) -> (CGPoint, CGPoint, CGPoint, CGPoint) {
        let p0 = route[max(index - 1, 0)]
        let p1 = route[index]
        let p2 = route[index + 1]
        let p3 = route[min(index + 2, route.count - 1)]
        let control1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
        let control2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
        return (p1, control1, control2, p2)
    }

    /// その高さで道が通っている横位置
    private func roadX(at y: CGFloat) -> CGFloat {
        for index in 0..<(route.count - 1) {
            let lower = route[index], upper = route[index + 1]
            if y <= lower.y, y >= upper.y {
                let t = (lower.y - y) / max(lower.y - upper.y, 1)
                return lower.x + (upper.x - lower.x) * t
            }
        }
        return width / 2
    }

    /// 章ごとの木や山などの飾り。道や看板にかからない場所に、毎回同じ配置で散らす
    private func makeDecorations() -> [Decoration] {
        var result: [Decoration] = []
        let signs = story.chapters.map { signY(for: $0.number) }
        for chapter in story.chapters {
            let band = band(for: chapter.number)
            let count = Int((band.bottom - band.top) / 50)
            for index in 0..<count {
                let id = chapter.number * 1000 + index
                let y = band.top + 30 + Self.noise(id, 1) * max(band.bottom - band.top - 60, 1)
                if signs.contains(where: { abs($0 - y) < 36 }) { continue }
                let road = roadX(at: y)
                let (low, high) = road > width / 2
                    ? (width * 0.06, road - 70)
                    : (road + 70, width * 0.94)
                guard high > low else { continue }
                result.append(Decoration(
                    id: id,
                    chapter: chapter.number,
                    variant: Int(Self.noise(id, 3) * 100),
                    point: CGPoint(x: low + Self.noise(id, 2) * (high - low), y: y),
                    size: 20 + Self.noise(id, 4) * 20
                ))
            }
        }
        return result
    }

    /// 0..<1 の決まった乱数
    private static func noise(_ seed: Int, _ salt: Int) -> CGFloat {
        let value = sin(Double(seed) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return CGFloat(value - value.rounded(.down))
    }
}
