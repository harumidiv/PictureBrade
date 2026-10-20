//
//  BladeComponents.swift
//  PictureBrade
//

import SwiftUI
import UIKit

enum Theme {
    static let background = LinearGradient(
        colors: [Color(red: 0.05, green: 0.04, blue: 0.14), Color(red: 0.13, green: 0.06, blue: 0.25)],
        startPoint: .top, endPoint: .bottom
    )
    static let accent = Color(red: 1, green: 0.32, blue: 0.4)
    static let gold = Color(red: 1, green: 0.82, blue: 0.3)
}

/// 切り抜き画像を回転するコマ風に表示する
struct BladeBadge: View {
    let image: UIImage?
    let tint: Color
    var size: CGFloat = 96
    var spinning = false

    @State private var angle: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [tint.opacity(0.9), tint.opacity(0.35)], center: .center, startRadius: 0, endRadius: size / 2))
            Circle()
                .strokeBorder(LinearGradient(colors: [.white, .gray, .white], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: size * 0.05)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.08)
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
            }
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(angle))
        .onAppear {
            guard spinning else { return }
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                angle = 360
            }
        }
    }
}

/// ステージの星（★1〜★3）。animated なら1つずつ跳ねながら出てくる
struct StarRating: View {
    let stars: Int
    var size: CGFloat = 14
    var animated = false

    @State private var shown = 0

    var body: some View {
        HStack(spacing: size * 0.12) {
            ForEach(0..<3, id: \.self) { index in
                let isOn = index < stars && (!animated || index < shown)
                Image(systemName: "star.fill")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(isOn ? Theme.gold : Color.black.opacity(0.35))
                    .overlay(
                        Image(systemName: "star")
                            .font(.system(size: size, weight: .bold))
                            .foregroundStyle(.white.opacity(isOn ? 0.9 : 0.5))
                    )
                    .shadow(color: isOn ? Theme.gold.opacity(0.7) : .clear, radius: size * 0.2)
                    .scaleEffect(isOn ? 1 : (animated ? 0.85 : 1))
                    // 真ん中の星を少し大きく、上にずらして王冠のように並べる
                    .scaleEffect(index == 1 ? 1.2 : 1)
                    .offset(y: index == 1 ? -size * 0.15 : 0)
            }
        }
        .task {
            guard animated else { return }
            for index in 1...max(stars, 1) {
                try? await Task.sleep(for: .seconds(0.35))
                withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) { shown = index }
            }
        }
    }
}

struct StatBar: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption2.bold())
                .frame(width: 34, alignment: .leading)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12))
                    Capsule().fill(color).frame(width: proxy.size.width * value)
                }
            }
            .frame(height: 6)
            Text("\(Int(value * 100))")
                .font(.caption2.monospacedDigit())
                .frame(width: 24, alignment: .trailing)
        }
        .foregroundStyle(.white.opacity(0.85))
    }
}

struct StatsView: View {
    let stats: BladeStats

    var body: some View {
        VStack(spacing: 4) {
            StatBar(label: "攻撃", value: stats.attack, color: .red)
            StatBar(label: "防御", value: stats.defense, color: .blue)
            StatBar(label: "持久", value: stats.stamina, color: .green)
            StatBar(label: "機動", value: stats.speed, color: .yellow)
        }
    }
}

struct BladeCard: View {
    let blade: Blade
    let image: UIImage?
    var isSelected = false

    var body: some View {
        VStack(spacing: 8) {
            BladeBadge(image: image, tint: blade.tint.color, size: 84)
            Text(blade.name)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(blade.stats.typeName)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Capsule().fill(Theme.accent.opacity(0.8)))
                .foregroundStyle(.white)
            StatsView(stats: blade.stats)
            if let credit = blade.credit {
                CreditLabel(credit: credit)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(isSelected ? 0.18 : 0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isSelected ? Theme.gold : .clear, lineWidth: 3)
        )
    }
}

/// バトルに使う自分のコマを選ぶ横スクロール
struct PlayerBladePicker: View {
    @Binding var selection: Blade?
    @Environment(BladeStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("あなたのコマ")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(store.allBlades) { blade in
                            BladeCard(blade: blade, image: store.image(for: blade), isSelected: selection?.id == blade.id)
                                .frame(width: 150)
                                .onTapGesture { selection = blade }
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: selection?.id, initial: true) { _, id in
                    guard let id else { return }
                    withAnimation { proxy.scrollTo(id, anchor: .center) }
                }
            }
        }
        .onAppear {
            selection = selection ?? store.allBlades.first
        }
    }
}
