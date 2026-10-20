//
//  StoryIllustrationView.swift
//  PictureBrade
//

import SwiftUI
import UIKit

/// プロローグ・エンディングの挿絵（アプリ内で描画してアニメーションさせる）
enum StoryIllustration {
    /// 辞書から文字が飛び出す
    case dictionaryBurst
    /// 文字のコマが夜の街で暴れまわる
    case cityRampage
    /// 写真から被写体が切り抜かれてコマになる
    case photoBlade(UIImage?)
    /// 自分のコマと文字たちが向かい合う
    case faceOff(UIImage?)
    /// 文字たちが辞書へ帰っていく
    case returnToDictionary

    /// 同じ場面かどうかの判定用
    var sceneName: String {
        switch self {
        case .dictionaryBurst: "dictionaryBurst"
        case .cityRampage: "cityRampage"
        case .photoBlade: "photoBlade"
        case .faceOff: "faceOff"
        case .returnToDictionary: "returnToDictionary"
        }
    }
}

struct StoryIllustrationView: View {
    let illustration: StoryIllustration

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Group {
                switch illustration {
                case .dictionaryBurst: DictionaryScene(time: time, reversed: false)
                case .returnToDictionary: DictionaryScene(time: time, reversed: true)
                case .cityRampage: CityScene(time: time)
                case .photoBlade(let image): PhotoBladeScene(time: time, image: image)
                case .faceOff(let image): FaceOffScene(time: time, image: image)
                }
            }
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.15)))
    }
}

// MARK: - 共通

private let flyingCharacters: [(String, Color)] = [
    ("一", .cyan), ("火", .orange), ("龍", .red), ("鬼", .purple), ("水", .blue),
    ("山", .green), ("雷", .yellow), ("覇", .yellow), ("人", .mint), ("川", .teal),
]

/// 回転する文字のコマ（上から少し傾けて見た円盤 + 文字）
private struct SpinningCharacterTop: View {
    let character: String
    let color: Color
    let angle: Double
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Ellipse()
                .fill(RadialGradient(colors: [color.opacity(0.9), color.opacity(0.3)], center: .center, startRadius: 0, endRadius: size / 2))
                .overlay(Ellipse().strokeBorder(.white.opacity(0.8), lineWidth: 2))
                .frame(width: size, height: size * 0.45)
                .offset(y: size * 0.18)
            Text(character)
                .font(.system(size: size * 0.6, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .shadow(color: .white, radius: 1)
                .shadow(color: color, radius: 8)
                // 横方向の伸び縮みで回転しているように見せる
                .scaleEffect(x: cos(angle), y: 1)
        }
    }
}

// MARK: - 辞書から飛び出す

private struct DictionaryScene: View {
    let time: TimeInterval
    let reversed: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let bookCenter = CGPoint(x: size.width / 2, y: size.height * 0.78)
            ZStack {
                RadialGradient(colors: [Color(red: 0.35, green: 0.2, blue: 0.6), Color(red: 0.05, green: 0.03, blue: 0.15)],
                               center: UnitPoint(x: 0.5, y: 0.75), startRadius: 10, endRadius: size.width)
                // 辞書から立ちのぼる光
                Ellipse()
                    .fill(RadialGradient(colors: [Color.yellow.opacity(0.7), .clear], center: .center, startRadius: 0, endRadius: 120))
                    .frame(width: 260, height: 220)
                    .position(x: bookCenter.x, y: bookCenter.y - 60)
                    .opacity(0.6 + 0.3 * sin(time * 3))

                OpenBook()
                    .frame(width: 220, height: 90)
                    .position(bookCenter)

                ForEach(flyingCharacters.indices, id: \.self) { index in
                    let (character, color) = flyingCharacters[index]
                    let raw = (time * 0.35 + Double(index) / Double(flyingCharacters.count)).truncatingRemainder(dividingBy: 1)
                    // 帰っていくときは逆再生
                    let t = reversed ? 1 - raw : raw
                    let direction = Double(index % 2 == 0 ? 1 : -1) * (0.3 + Double(index) / 14)
                    let x = bookCenter.x + CGFloat(direction * t) * size.width * 0.55
                    let y = bookCenter.y - 20 - CGFloat(sin(.pi * min(t * 1.1, 1)) * 0.75 + t * 0.15) * size.height * 0.75
                    Text(character)
                        .font(.system(size: 22 + 34 * t, weight: .black, design: .rounded))
                        .foregroundStyle(color)
                        .shadow(color: .white, radius: 1)
                        .shadow(color: color, radius: 10)
                        .rotationEffect(.radians(t * 6 * direction))
                        .position(x: x, y: y)
                        .opacity(t < 0.08 ? t / 0.08 : (t > 0.85 ? (1 - t) / 0.15 : 1))
                }

                Sparkles(time: time, area: size)
            }
        }
    }
}

private struct OpenBook: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height
            ZStack {
                // 表紙
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.55, green: 0.1, blue: 0.12))
                    .frame(width: w, height: h * 0.9)
                    .offset(y: h * 0.12)
                // 左右のページ
                HStack(spacing: 2) {
                    page(lines: 5).rotation3DEffect(.degrees(18), axis: (x: 0, y: 1, z: 0), anchor: .trailing)
                    page(lines: 5).rotation3DEffect(.degrees(-18), axis: (x: 0, y: 1, z: 0), anchor: .leading)
                }
                .frame(width: w * 0.94, height: h * 0.85)
                Text("国語辞典")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(red: 1, green: 0.85, blue: 0.4))
                    .offset(y: h * 0.52)
            }
        }
    }

    private func page(lines: Int) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(red: 0.98, green: 0.95, blue: 0.86))
            .overlay(
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(0..<lines, id: \.self) { index in
                        Capsule().fill(.gray.opacity(0.35)).frame(height: 3).padding(.trailing, CGFloat(index % 3) * 12)
                    }
                }
                .padding(10)
            )
    }
}

private struct Sparkles: View {
    let time: TimeInterval
    let area: CGSize

    var body: some View {
        ForEach(0..<14, id: \.self) { index in
            let seed = Double(index) * 12.9898
            let x = (sin(seed) * 0.5 + 0.5) * area.width
            let y = (cos(seed * 1.7) * 0.5 + 0.5) * area.height * 0.7
            let twinkle = (sin(time * 4 + seed) + 1) / 2
            Image(systemName: "sparkle")
                .font(.system(size: 8 + 8 * twinkle))
                .foregroundStyle(.white.opacity(0.3 + 0.6 * twinkle))
                .position(x: x, y: y)
        }
    }
}

// MARK: - 街で暴れる

private struct CityScene: View {
    let time: TimeInterval

    /// ビルの並び（相対幅, 相対高さ）
    private let buildings: [(CGFloat, CGFloat)] = [
        (0.10, 0.45), (0.08, 0.62), (0.12, 0.38), (0.09, 0.7), (0.11, 0.5),
        (0.08, 0.58), (0.12, 0.42), (0.1, 0.66), (0.1, 0.48), (0.1, 0.55),
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let groundY = size.height * 0.82
            // ドカーンの瞬間（約2.4秒ごと）
            let impactPhase = (time / 2.4).truncatingRemainder(dividingBy: 1)
            let shake = impactPhase < 0.15 ? sin(time * 80) * 4 : 0

            ZStack {
                LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.2), Color(red: 0.35, green: 0.12, blue: 0.3)],
                               startPoint: .top, endPoint: .bottom)
                Circle()
                    .fill(Color(red: 1, green: 0.95, blue: 0.75))
                    .frame(width: 46)
                    .shadow(color: .yellow.opacity(0.6), radius: 20)
                    .position(x: size.width * 0.82, y: size.height * 0.16)

                // ビル群
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(buildings.indices, id: \.self) { index in
                        let (w, h) = buildings[index]
                        Building(seed: index, flicker: time)
                            .frame(width: size.width * w, height: size.height * h)
                    }
                }
                .frame(width: size.width, height: groundY, alignment: .bottom)
                .position(x: size.width / 2 + shake, y: groundY / 2)

                // 道路
                Rectangle()
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.16))
                    .frame(height: size.height - groundY)
                    .position(x: size.width / 2, y: groundY + (size.height - groundY) / 2)

                // 暴れる文字のコマたち
                ForEach(0..<3, id: \.self) { index in
                    let (character, color) = flyingCharacters[[2, 3, 6][index]]
                    let speed = 0.18 + Double(index) * 0.07
                    let progress = (time * speed + Double(index) * 0.37).truncatingRemainder(dividingBy: 1)
                    // 左右に行ったり来たり
                    let pingPong = progress < 0.5 ? progress * 2 : (1 - progress) * 2
                    let x = size.width * (0.1 + 0.8 * CGFloat(pingPong))
                    let bounce = abs(sin(time * (5 + Double(index)))) * 14
                    SpinningCharacterTop(character: character, color: color, angle: time * (9 + Double(index) * 3), size: 58)
                        .position(x: x, y: groundY - 18 - bounce)
                    // 砂ぼこり
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 30 + bounce, height: 10)
                        .blur(radius: 4)
                        .position(x: x, y: groundY + 4)
                }

                if impactPhase < 0.35 {
                    Text("ドカーン！")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.yellow)
                        .shadow(color: .red, radius: 0, x: 3, y: 3)
                        .rotationEffect(.degrees(-12))
                        .scaleEffect(0.6 + impactPhase * 2)
                        .position(x: size.width * 0.32, y: size.height * 0.28)
                        .opacity(1 - impactPhase / 0.35)
                    Image(systemName: "burst.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.orange.opacity(0.8))
                        .scaleEffect(0.5 + impactPhase * 2)
                        .position(x: size.width * 0.62, y: groundY - 60)
                        .opacity(1 - impactPhase / 0.35)
                }
            }
        }
    }
}

private struct Building: View {
    let seed: Int
    let flicker: TimeInterval

    var body: some View {
        GeometryReader { proxy in
            let columns = 3
            let rows = max(3, Int(proxy.size.height / 16))
            ZStack(alignment: .top) {
                Rectangle().fill(Color(red: 0.1, green: 0.1, blue: 0.22))
                VStack(spacing: 6) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach(0..<columns, id: \.self) { column in
                                // 窓の明かりがときどき点滅する
                                let value = sin(Double(seed * 31 + row * 7 + column * 13) + flicker * 0.7)
                                Rectangle()
                                    .fill(value > 0.1 ? Color.yellow.opacity(0.75) : Color.white.opacity(0.08))
                            }
                        }
                        .frame(height: 8)
                    }
                }
                .padding(5)
            }
        }
    }
}

// MARK: - 写真からコマが生まれる

private struct PhotoBladeScene: View {
    let time: TimeInterval
    let image: UIImage?

    var body: some View {
        // 4秒周期：写真 → 切り抜き線 → 浮かび上がって回転
        let phase = (time / 4).truncatingRemainder(dividingBy: 1)
        let lift = phase < 0.35 ? 0 : min(1, (phase - 0.35) / 0.3)
        ZStack {
            RadialGradient(colors: [Color(red: 0.15, green: 0.35, blue: 0.6), Color(red: 0.03, green: 0.05, blue: 0.15)],
                           center: .center, startRadius: 10, endRadius: 260)
            // 光の筋
            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(LinearGradient(colors: [.white.opacity(0.35 * lift), .clear], startPoint: .bottom, endPoint: .top))
                    .frame(width: 6, height: 140)
                    .offset(y: -70)
                    .rotationEffect(.degrees(Double(index) * 30 + time * 20))
            }

            // スマホ
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(white: 0.12))
                .frame(width: 130, height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [Color(red: 0.6, green: 0.85, blue: 1), Color(red: 0.4, green: 0.75, blue: 0.4)], startPoint: .top, endPoint: .bottom))
                        .padding(8)
                )
                .offset(y: 30)
                .opacity(1 - lift * 0.5)

            // 切り抜かれる被写体
            subject
                .frame(width: 90, height: 90)
                .overlay(
                    // 切り抜き中の点線
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [6, 5], dashPhase: time * 30))
                        .foregroundStyle(.white)
                        .opacity(phase > 0.12 && phase < 0.4 ? 1 : 0)
                )
                .scaleEffect(x: lift > 0 ? cos(time * 10 * lift) : 1, y: 1)
                .scaleEffect(1 + 0.3 * lift)
                .shadow(color: .cyan.opacity(lift), radius: 25)
                .offset(y: 30 - 90 * lift)

            Image(systemName: "scissors")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(sin(time * 12) * 15))
                .offset(x: 70, y: -20)
                .opacity(phase > 0.08 && phase < 0.4 ? 1 : 0)
        }
    }

    @ViewBuilder
    private var subject: some View {
        if let image {
            Image(uiImage: image).resizable().scaledToFit()
        } else {
            Image(systemName: "figure.run")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .padding(10)
        }
    }
}

// MARK: - 対決

private struct FaceOffScene: View {
    let time: TimeInterval
    let image: UIImage?

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let flash = (sin(time * 6) + 1) / 2
            ZStack {
                // 左右で色の違う背景
                HStack(spacing: 0) {
                    LinearGradient(colors: [Color(red: 0.05, green: 0.3, blue: 0.6), Color(red: 0.02, green: 0.1, blue: 0.25)], startPoint: .leading, endPoint: .trailing)
                    LinearGradient(colors: [Color(red: 0.25, green: 0.03, blue: 0.08), Color(red: 0.6, green: 0.08, blue: 0.15)], startPoint: .leading, endPoint: .trailing)
                }
                Rectangle()
                    .fill(.white)
                    .frame(width: 4)
                    .rotationEffect(.degrees(12))
                    .shadow(color: .white, radius: 10)

                // 自分のコマ
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.25))
                        .frame(width: 130)
                        .blur(radius: 10)
                    Group {
                        if let image {
                            Image(uiImage: image).resizable().scaledToFit()
                        } else {
                            Image(systemName: "photo.fill").resizable().scaledToFit().foregroundStyle(.white)
                        }
                    }
                    .frame(width: 100, height: 100)
                    .scaleEffect(x: cos(time * 8), y: 1)
                }
                .position(x: size.width * 0.25, y: size.height * 0.52 + sin(time * 3) * 6)

                // 文字たち（まだ正体は分からない）
                ForEach(0..<3, id: \.self) { index in
                    Text("？")
                        .font(.system(size: [70, 46, 46][index], weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity([0.95, 0.6, 0.6][index]))
                        .shadow(color: .red, radius: 12)
                        .position(
                            x: size.width * [0.76, 0.6, 0.9][index],
                            y: size.height * [0.5, 0.25, 0.78][index] + sin(time * 2.5 + Double(index)) * 8
                        )
                }

                Text("VS")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .italic()
                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                    .shadow(color: .black, radius: 0, x: 3, y: 3)
                    .scaleEffect(1 + 0.08 * flash)
                    .position(x: size.width / 2, y: size.height / 2)
            }
        }
    }
}
