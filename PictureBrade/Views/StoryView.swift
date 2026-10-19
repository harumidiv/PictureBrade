//
//  StoryView.swift
//  PictureBrade
//

import SwiftUI
import UIKit

/// ストーリーモード：章ごとに文字を1体ずつ倒していく。まだ会っていない相手は「？」で隠す
struct StoryView: View {
    @Environment(BladeStore.self) private var store
    @Environment(EnemyCatalog.self) private var enemies
    @Environment(\.dismiss) private var dismiss

    @State private var playerBlade: Blade?
    @State private var battle: BattleGame?
    @State private var dialogue: StoryDialogue?
    /// 会話が終わったら始めるバトルの相手
    @State private var pendingBattle: Enemy?
    /// バトル前の撃破数（勝って戻ってきたかの判定に使う）
    @State private var defeatedCountBeforeBattle = 0

    private let cellColumns = [GridItem(.adaptive(minimum: 58), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PlayerBladePicker(selection: $playerBlade)
                    progressHeader
                    ForEach(Story.chapters) { chapter in
                        chapterSection(chapter)
                    }
                }
                .padding(.vertical)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    if let next = enemies.nextStoryEnemy {
                        encounter(next)
                    } else {
                        dialogue = endingDialogue
                    }
                } label: {
                    Text(enemies.isStoryCleared ? "エンディングを見る" : "次の相手に挑む")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .disabled(playerBlade == nil)
                .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("ストーリー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("戻る") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("プロローグ", systemImage: "book") {
                        dialogue = prologueDialogue
                    }
                }
            }
            .onAppear {
                if !enemies.hasSeenPrologue {
                    dialogue = prologueDialogue
                    enemies.markPrologueSeen()
                }
            }
            .fullScreenCover(item: $dialogue, onDismiss: startPendingBattle) { dialogue in
                DialogueView(dialogue: dialogue) {
                    pendingBattle = dialogue.battleEnemy
                    self.dialogue = nil
                }
            }
            .fullScreenCover(item: $battle, onDismiss: afterBattle) { game in
                BattleView(game: game)
            }
        }
    }

    // MARK: - 進行状況

    private var progressHeader: some View {
        HStack {
            Text("撃破 \(enemies.defeated.count)/\(EnemyCatalog.enemies.count)")
                .font(.headline)
                .foregroundStyle(Theme.gold)
            Spacer()
            if enemies.isStoryCleared {
                Label("全クリア！", systemImage: "crown.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.gold)
            }
        }
        .padding(.horizontal)
    }

    private func chapterSection(_ chapter: StoryChapter) -> some View {
        // 章の最初の相手に出会うまでは章タイトルも隠す
        let isReached = chapter.enemies.contains { enemies.isRevealed($0) }
        return VStack(alignment: .leading, spacing: 10) {
            Text("第\(chapter.number)章　\(isReached ? chapter.title : "？？？")")
                .font(.headline)
                .foregroundStyle(isReached ? .white : .white.opacity(0.4))
            LazyVGrid(columns: cellColumns, spacing: 10) {
                ForEach(chapter.enemies) { enemy in
                    enemyCell(enemy)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(isReached ? 0.08 : 0.03)))
        .padding(.horizontal)
    }

    @ViewBuilder
    private func enemyCell(_ enemy: Enemy) -> some View {
        let isDefeated = enemies.isDefeated(enemy)
        let isNext = enemy == enemies.nextStoryEnemy
        Button {
            // 倒した相手とは再戦できる（進行には影響しない）
            if isDefeated { encounter(enemy) }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(isDefeated ? 0.15 : 0.06))
                if isDefeated {
                    Text(enemy.character)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Color(enemy.color))
                } else {
                    // 次の相手もまだ姿は見せない
                    Text("？")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(isNext ? Theme.gold : .white.opacity(0.25))
                }
            }
            .frame(height: 58)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(isNext ? Theme.gold : .clear, lineWidth: 3))
            .overlay(alignment: .topTrailing) {
                if isDefeated {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green, .white)
                        .offset(x: 6, y: -6)
                } else if !isNext {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(4)
                }
            }
            .overlay(alignment: .bottom) {
                if isNext {
                    Text("NEXT")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 5)
                        .background(Capsule().fill(Theme.gold))
                        .offset(y: 6)
                }
            }
        }
        .disabled(!isDefeated)
    }

    // MARK: - 会話

    private var prologueDialogue: StoryDialogue {
        let lines = Story.prologue.enumerated().map { index, text in
            DialogueLine(heading: index == 0 ? "プロローグ" : nil, text: text)
        }
        return StoryDialogue(lines: lines, finishTitle: "はじめる")
    }

    private var endingDialogue: StoryDialogue {
        let lines = Story.ending.enumerated().map { index, text in
            DialogueLine(heading: index == 0 ? "エンディング" : nil, text: text)
        }
        return StoryDialogue(lines: lines, finishTitle: "おわり")
    }

    /// 相手の登場シーン → バトル
    private func encounter(_ enemy: Enemy) {
        let blade = enemies.blade(for: enemy)
        var lines: [DialogueLine] = []
        let isRematch = enemies.isDefeated(enemy)
        if let chapter = Story.chapter(for: enemy), chapter.enemies.first == enemy, !isRematch {
            lines.append(DialogueLine(heading: "第\(chapter.number)章\n\(chapter.title)", text: chapter.intro))
        }
        if !isRematch {
            lines.append(DialogueLine(text: "……何者かが近づいてくる。"))
        }
        lines.append(DialogueLine(
            speaker: "\(blade.name)（\(enemy.reading)）Lv.\(enemy.level)",
            text: enemy.intro,
            portrait: enemies.image(for: enemy),
            portraitTint: blade.tint.color
        ))
        dialogue = StoryDialogue(lines: lines, finishTitle: "バトル開始！", battleEnemy: enemy)
    }

    private func startPendingBattle() {
        guard let enemy = pendingBattle else { return }
        pendingBattle = nil
        guard let playerBlade, let playerImage = store.image(for: playerBlade) else { return }
        defeatedCountBeforeBattle = enemies.defeated.count
        battle = BattleGame(
            player: playerBlade, playerImage: playerImage,
            cpu: enemies.blade(for: enemy), cpuImage: enemies.image(for: enemy),
            cpuSkill: enemy.skill, mode: .story
        )
    }

    /// 新しく相手を倒して戻ってきたら、そのまま次の相手の登場シーン（全員倒したらエンディング）へ
    private func afterBattle() {
        guard enemies.defeated.count > defeatedCountBeforeBattle else { return }
        if let next = enemies.nextStoryEnemy {
            encounter(next)
        } else {
            dialogue = endingDialogue
        }
    }
}
