//
//  StorySelectView.swift
//  PictureBrade
//

import SwiftUI

/// どのストーリー（漢字・ひらがな・絵文字）で遊ぶかを選ぶ
struct StorySelectView: View {
    @Environment(EnemyCatalog.self) private var enemies
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text("ライフ")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.7))
                        LifeIndicator()
                        Spacer()
                    }
                    ForEach(StoryKind.allCases) { story in
                        NavigationLink(value: story) {
                            StoryCard(
                                story: story,
                                defeated: enemies.defeatedCount(in: story),
                                isCleared: enemies.isStoryCleared(story),
                                stars: enemies.totalStars(in: story)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("ストーリーを選ぶ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("戻る") { dismiss() }
                }
            }
            .navigationDestination(for: StoryKind.self) { story in
                StoryView(story: story)
            }
        }
    }
}

/// ストーリーのカード。そのストーリーの文字たちが回りながら浮かんでいる
private struct StoryCard: View {
    let story: StoryKind
    let defeated: Int
    let isCleared: Bool
    let stars: Int

    private var total: Int { story.enemies.count }

    private var colors: [Color] {
        switch story {
        case .kanji: [Color(red: 0.55, green: 0.12, blue: 0.2), Color(red: 0.25, green: 0.08, blue: 0.4)]
        case .hiragana: [Color(red: 1, green: 0.55, blue: 0.6), Color(red: 0.95, green: 0.7, blue: 0.3)]
        case .emoji: [Color(red: 0.1, green: 0.12, blue: 0.4), Color(red: 0.2, green: 0.55, blue: 0.75)]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(story.title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 0, x: 2, y: 2)
                Text(story.catchphrase)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            FloatingCharacters(characters: Array(story.illustrationCharacters.prefix(5)))
                .frame(height: 64)
            HStack(spacing: 8) {
                if isCleared {
                    Label("CLEAR", systemImage: "crown.fill")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.gold)
                }
                ProgressView(value: Double(defeated), total: Double(max(total, 1)))
                    .tint(isCleared ? Theme.gold : .white)
                Text("撃破 \(defeated)/\(total)")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.white)
                Label("\(stars)/\(total * 3)", systemImage: "star.fill")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(Theme.gold)
                    .labelStyle(StarCountLabelStyle())
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.35), lineWidth: 2))
        .shadow(color: colors[0].opacity(0.5), radius: 10, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }
}

/// 星のアイコンと数字を詰めて並べる
private struct StarCountLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 2) {
            configuration.icon
            configuration.title
        }
    }
}

/// ふわふわ上下しながら回っている文字たち
private struct FloatingCharacters: View {
    let characters: [(String, Color)]

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 0) {
                ForEach(characters.indices, id: \.self) { index in
                    let (character, color) = characters[index]
                    Text(character)
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(color)
                        .shadow(color: .white, radius: 1)
                        .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
                        // 横方向の伸び縮みで回転しているように見せる
                        .scaleEffect(x: cos(time * 2.5 + Double(index)), y: 1)
                        .offset(y: sin(time * 2 + Double(index) * 1.3) * 6)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
