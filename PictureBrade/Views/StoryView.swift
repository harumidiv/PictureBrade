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
    @Environment(LifeManager.self) private var life

    let story: StoryKind

    @State private var playerBlade: Blade?
    @State private var battle: BattleGame?
    @State private var dialogue: StoryDialogue?
    /// 会話が終わったら始めるバトルの相手
    @State private var pendingBattle: Enemy?
    /// バトル前の撃破数（勝って戻ってきたかの判定に使う）
    @State private var defeatedCountBeforeBattle = 0

    /// マップで選んでいるステージ（nil ならゴール＝エンディング）
    @State private var selectedStage: Enemy?

    var body: some View {
        StoryMapView(
                story: story,
                playerImage: playerImage,
                playerTint: playerBlade?.tint.color ?? .gray,
                selection: $selectedStage
            )
            .safeAreaInset(edge: .bottom) { departurePanel }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(story.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    progressHeader
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("プロローグ", systemImage: "book") {
                        dialogue = prologueDialogue
                    }
                }
            }
            .onAppear {
                // プロローグの挿絵に自分のコマを使うため、先に選んでおく
                playerBlade = playerBlade ?? store.allBlades.first
                selectedStage = enemies.nextStoryEnemy(in: story)
                if !enemies.hasSeenPrologue(story) {
                    dialogue = prologueDialogue
                    enemies.markPrologueSeen(story)
                }
            }
            .onChange(of: enemies.nextStoryEnemy(in: story)) { _, next in
                selectedStage = next
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

    // MARK: - 進行状況

    private var progressHeader: some View {
        HStack(spacing: 6) {
            if enemies.isStoryCleared(story) {
                Image(systemName: "crown.fill")
            }
            Text("撃破 \(enemies.defeatedCount(in: story))/\(story.enemies.count)")
        }
        .font(.headline)
        .foregroundStyle(Theme.gold)
    }

    // MARK: - 出陣パネル

    /// 選んだステージの情報・コマ選び・出陣ボタン
    private var departurePanel: some View {
        VStack(spacing: 12) {
            HStack {
                Text("ライフ")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.7))
                LifeIndicator()
                Spacer()
            }
            stageInfo
            bladeStrip
            // ライフが時間で回復したらボタンが戻るよう、1秒ごとに見直す
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                if selectedStage != nil, life.lives(at: timeline.date) == 0 {
                    VStack(spacing: 8) {
                        Text("ライフがありません。回復を待つか、広告を見て回復しよう")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.8))
                        LifeRefillButton()
                    }
                } else {
                    departureButton
                }
            }
        }
        .padding(16)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .fill(Color(red: 0.08, green: 0.05, blue: 0.18))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var departureButton: some View {
        Button {
            if let selectedStage {
                encounter(selectedStage)
            } else {
                dialogue = endingDialogue
            }
        } label: {
            Text(departureTitle)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.accent)
        .disabled(selectedStage != nil && playerBlade == nil)
    }

    private var departureTitle: String {
        guard let selectedStage else { return "エンディングを見る" }
        return enemies.isDefeated(selectedStage) ? "もう一度戦う" : "いざ出陣！！"
    }

    @ViewBuilder
    private var stageInfo: some View {
        HStack(spacing: 10) {
            if let stage = selectedStage {
                let chapter = story.chapter(for: stage)
                let number = (chapter?.enemies.firstIndex(of: stage) ?? 0) + 1
                let isDefeated = enemies.isDefeated(stage)
                VStack(alignment: .leading, spacing: 2) {
                    Text("第\(stage.level)章  ステージ\(number)")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                    // 倒すまでは相手の姿を見せない
                    Text(isDefeated ? stage.displayName : "？？？")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)
                }
                Spacer()
                if isDefeated {
                    StarRating(stars: enemies.stars(for: stage), size: 22)
                } else {
                    Text("NEXT")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Theme.gold))
                }
            } else {
                Text(story.clearedTitle)
                    .font(.title3.weight(.black))
                    .foregroundStyle(Theme.gold)
                Spacer()
            }
        }
    }

    /// 戦うコマを選ぶ
    @ViewBuilder
    private var bladeStrip: some View {
        if store.allBlades.isEmpty {
            Text("ホーム画面でコマを作ってから挑もう")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.allBlades) { blade in
                        Button {
                            playerBlade = blade
                        } label: {
                            BladeBadge(image: store.image(for: blade), tint: blade.tint.color, size: 46)
                                .overlay(Circle().stroke(Theme.gold, lineWidth: playerBlade?.id == blade.id ? 3 : 0).padding(-4))
                                .padding(5)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - 会話

    private var playerImage: UIImage? {
        playerBlade.flatMap(store.image(for:))
    }

    private var prologueDialogue: StoryDialogue {
        let illustrations: [StoryIllustration] = [
            .dictionaryBurst(story),
            .cityRampage(story),
            .photoBlade(playerImage),
            .faceOff(playerImage),
        ]
        let lines = story.prologue.enumerated().map { index, text in
            DialogueLine(
                heading: index == 0 ? "プロローグ" : nil,
                text: text,
                illustration: illustrations.indices.contains(index) ? illustrations[index] : nil
            )
        }
        return StoryDialogue(lines: lines, finishTitle: "はじめる")
    }

    private var endingDialogue: StoryDialogue {
        // 見出しは出さず、最初から文字たちが元の場所へ帰っていく場面を流し続ける
        let lines = story.ending.map { text in
            DialogueLine(text: text, illustration: .returnToDictionary(story))
        }
        return StoryDialogue(lines: lines, finishTitle: "おわり")
    }

    /// 相手の登場シーン → バトル
    private func encounter(_ enemy: Enemy) {
        let blade = enemies.blade(for: enemy)
        var lines: [DialogueLine] = []
        let isRematch = enemies.isDefeated(enemy)
        if let chapter = story.chapter(for: enemy), chapter.enemies.first == enemy, !isRematch {
            lines.append(DialogueLine(heading: "第\(chapter.number)章\n\(chapter.title)", text: chapter.intro))
        }
        if !isRematch {
            lines.append(DialogueLine(text: "……何者かが近づいてくる。"))
        }
        lines.append(DialogueLine(
            speaker: blade.name + (enemy.reading.isEmpty ? "" : "（\(enemy.reading)）") + " Lv.\(enemy.level)",
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
        if let next = enemies.nextStoryEnemy(in: story) {
            encounter(next)
        } else {
            dialogue = endingDialogue
        }
    }
}
