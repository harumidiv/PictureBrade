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
    /// 場面の挿絵
    var illustration: StoryIllustration?
    /// 相手を黒いシルエットで出し、ズシンズシンと近づいてくる（次のコマで正体を見せる）
    var silhouette = false
}

/// ストーリー画面で表示する一連の会話
struct StoryDialogue: Identifiable {
    let id = UUID()
    let lines: [DialogueLine]
    let finishTitle: String
    /// 会話のあとに始めるバトルの相手
    var battleEnemy: Enemy?
    /// 最後のコマで出す「やめる」系ボタンの文言（nil なら出さない）
    var cancelTitle: String?
}

/// タップで進む会話画面
struct DialogueView: View {
    let dialogue: StoryDialogue
    var onCancel: () -> Void = {}
    let onFinish: () -> Void

    @State private var index = 0
    @State private var portraitScale: CGFloat = 0.2
    /// シルエットが近づいてくるときの大きさ
    @State private var approachScale: CGFloat = 0.3
    @State private var shakeOffset: CGFloat = 0
    /// 「ズシン」の文字（何回目か。左右交互に出す）
    @State private var thudCount = 0
    @State private var showThud = false
    /// 正体を見せるときの白い光
    @State private var flashOpacity = 0.0
    private let haptics = UIImpactFeedbackGenerator(style: .heavy)

    private var line: DialogueLine { dialogue.lines[index] }
    private var isLast: Bool { index == dialogue.lines.count - 1 }
    /// これまでに登場した相手の姿（最後に出てきたもの）
    private var currentPortrait: DialogueLine? {
        dialogue.lines[...index].last { $0.portrait != nil }
    }

    /// 同じ挿絵が続くあいだは同じ id にして、セリフが進んでも挿絵が切り替え直されないようにする
    private var illustrationRunStart: Int {
        var start = index
        while start > 0,
              let previous = dialogue.lines[start - 1].illustration?.sceneName,
              previous == line.illustration?.sceneName {
            start -= 1
        }
        return start
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
                if let illustration = line.illustration {
                    StoryIllustrationView(illustration: illustration)
                        .id(illustrationRunStart)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if let portrait = currentPortrait, let image = portrait.portrait {
                    BladeBadge(image: image, tint: portrait.portraitTint, size: 180, spinning: true)
                        .brightness(line.silhouette ? -1 : 0)
                        .scaleEffect(line.silhouette ? approachScale : portraitScale)
                        .shadow(color: line.silhouette ? .clear : portrait.portraitTint.opacity(0.8), radius: 30)
                        .overlay(alignment: thudCount.isMultiple(of: 2) ? .topLeading : .bottomTrailing) {
                            if showThud {
                                Text("ズシン")
                                    .font(.system(size: 26, weight: .black, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .offset(x: thudCount.isMultiple(of: 2) ? -40 : 40)
                                    .transition(.opacity.combined(with: .offset(y: 8)))
                            }
                        }
                        .onAppear {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { portraitScale = 1 }
                        }
                }
                Spacer()
                messageBox
            }
            .padding()
            .offset(x: shakeOffset)

            // シルエットのあいだは周りを暗くする
            RadialGradient(colors: [.clear, .black.opacity(0.65)], center: .center, startRadius: 80, endRadius: 420)
                .ignoresSafeArea()
                .opacity(line.silhouette ? 1 : 0)
                .allowsHitTesting(false)

            Color.white
                .ignoresSafeArea()
                .opacity(flashOpacity)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .animation(.easeInOut(duration: 0.25), value: index)
        .task(id: index) { await approachIfNeeded() }
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
                if isLast, let cancelTitle = dialogue.cancelTitle {
                    // 2つ並べるときは同じ横幅にする
                    Button {
                        onCancel()
                    } label: {
                        Text(cancelTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .controlSize(.large)
                    Button {
                        onFinish()
                    } label: {
                        Text(dialogue.finishTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .controlSize(.large)
                } else if isLast {
                    Spacer()
                    Button(dialogue.finishTitle) { onFinish() }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                        .controlSize(.large)
                } else {
                    Spacer()
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
        let wasSilhouette = line.silhouette
        index += 1
        if wasSilhouette, !line.silhouette { reveal() }
    }

    // MARK: - シルエットの演出

    /// シルエットのコマで、3回ズシンと揺れながら大きくなる
    private func approachIfNeeded() async {
        guard line.silhouette else { return }
        approachScale = 0.3
        haptics.prepare()
        for scale in [0.45, 0.62, 0.8] as [CGFloat] {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { approachScale = scale }
            await stomp()
        }
    }

    private func stomp() async {
        haptics.impactOccurred()
        thudCount += 1
        withAnimation(.easeOut(duration: 0.15)) { showThud = true }
        for x in [-6, 6, -4, 4, 0] as [CGFloat] {
            withAnimation(.linear(duration: 0.05)) { shakeOffset = x }
            try? await Task.sleep(for: .milliseconds(50))
        }
        shakeOffset = 0
        try? await Task.sleep(for: .milliseconds(200))
        withAnimation(.easeOut(duration: 0.3)) { showThud = false }
    }

    /// シルエットから正体へ：白く光って、色付きの姿がポンと出る
    private func reveal() {
        showThud = false
        shakeOffset = 0
        haptics.impactOccurred(intensity: 1)
        flashOpacity = 0.95
        withAnimation(.easeOut(duration: 0.55)) { flashOpacity = 0 }
        portraitScale = 0.8
        withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) { portraitScale = 1 }
    }
}
