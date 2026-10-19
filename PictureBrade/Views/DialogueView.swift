//
//  DialogueView.swift
//  PictureBrade
//

import SwiftUI
import UIKit

/// 会話の1コマ
struct DialogueLine {
    /// 章タイトルなどの見出し
    var heading: String?
    /// 話している人（nil ならナレーション）
    var speaker: String?
    var text: String
    /// 登場する相手のコマ（このセリフから姿を見せる）
    var portrait: UIImage?
    var portraitTint: Color = .gray
}

/// ストーリー画面で表示する一連の会話
struct StoryDialogue: Identifiable {
    let id = UUID()
    let lines: [DialogueLine]
    let finishTitle: String
    /// 会話のあとに始めるバトルの相手
    var battleEnemy: Enemy?
}

/// タップで進む会話画面
struct DialogueView: View {
    let dialogue: StoryDialogue
    let onFinish: () -> Void

    @State private var index = 0
    @State private var portraitScale: CGFloat = 0.2

    private var line: DialogueLine { dialogue.lines[index] }
    private var isLast: Bool { index == dialogue.lines.count - 1 }
    /// これまでに登場した相手の姿（最後に出てきたもの）
    private var currentPortrait: DialogueLine? {
        dialogue.lines[...index].last { $0.portrait != nil }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                if let heading = line.heading {
                    Text(heading)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [Theme.gold, Theme.accent], startPoint: .leading, endPoint: .trailing))
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
                if let portrait = currentPortrait, let image = portrait.portrait {
                    BladeBadge(image: image, tint: portrait.portraitTint, size: 180, spinning: true)
                        .scaleEffect(portraitScale)
                        .shadow(color: portrait.portraitTint.opacity(0.8), radius: 30)
                        .onAppear {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { portraitScale = 1 }
                        }
                }
                Spacer()
                messageBox
            }
            .padding()
        }
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .animation(.easeInOut(duration: 0.25), value: index)
    }

    private var messageBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let speaker = line.speaker {
                Text(speaker)
                    .font(.headline.bold())
                    .foregroundStyle(Theme.gold)
            }
            Text(line.text)
                .font(.body)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .id(index)
            HStack {
                Spacer()
                if isLast {
                    Button(dialogue.finishTitle) { onFinish() }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                        .controlSize(.large)
                } else {
                    Label("タップで次へ", systemImage: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(.black.opacity(0.55)))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.2)))
    }

    private func advance() {
        guard !isLast else { return }
        index += 1
    }
}
