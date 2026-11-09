//
//  Story.swift
//  PictureBrade
//

import Foundation

/// ストーリーの種類（どの文字たちと戦うか）
enum StoryKind: String, CaseIterable, Identifiable, Hashable {
    case kanji
    case hiragana
    case emoji

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kanji: String(localized: "漢字の乱")
        case .hiragana: String(localized: "ひらがな大冒険")
        case .emoji: String(localized: "絵文字パニック")
        }
    }

    /// ストーリー選びの画面に出す一言
    var catchphrase: String {
        switch self {
        case .kanji: String(localized: "辞書から飛び出した漢字たちと、覇王の城を目指せ！")
        case .hiragana: String(localized: "こどもの国から飛び出したひらがなたちを、しりとりの塔まで追いかけろ！")
        case .emoji: String(localized: "宇宙からやってきた絵文字たちを追って、宇宙の果ての母船へ！")
        }
    }

    /// 全員倒したあとに出陣パネルに出す言葉
    var clearedTitle: String {
        switch self {
        case .kanji: String(localized: "覇王の城を取り戻した！")
        case .hiragana: String(localized: "しりとりの塔をのぼりきった！")
        case .emoji: String(localized: "宇宙の果てから帰ってきた！")
        }
    }

    var prologue: [String] {
        switch self {
        case .kanji: Story.kanjiPrologue
        case .hiragana: HiraganaStory.prologue
        case .emoji: EmojiStory.prologue
        }
    }

    var ending: [String] {
        switch self {
        case .kanji: Story.kanjiEnding
        case .hiragana: HiraganaStory.ending
        case .emoji: EmojiStory.ending
        }
    }

    var chapters: [StoryChapter] {
        switch self {
        case .kanji: Story.kanjiChapters
        case .hiragana: HiraganaStory.chapters
        case .emoji: EmojiStory.chapters
        }
    }

    /// このストーリーの敵（この順番で1体ずつ戦う。level が章番号）
    var enemies: [Enemy] {
        switch self {
        case .kanji: EnemyCatalog.kanjiEnemies
        case .hiragana: HiraganaStory.enemies
        case .emoji: EmojiStory.enemies
        }
    }

    func chapter(for enemy: Enemy) -> StoryChapter? {
        chapters.first { $0.number == enemy.level }
    }

    /// 章の最後の相手（マップで王冠がつくボス）か
    func isBoss(_ enemy: Enemy) -> Bool {
        enemies.last { $0.level == enemy.level } == enemy
    }
}

/// ストーリーモードの章（章番号 = 敵のレベル）
struct StoryChapter: Identifiable {
    var story: StoryKind = .kanji
    let number: Int
    let title: String
    let intro: String

    var id: Int { number }
    var enemies: [Enemy] { story.enemies.filter { $0.level == number } }
}

/// 漢字のストーリー
enum Story {
    static let kanjiPrologue = [
        String(localized: "ある日、辞書の中から文字たちが飛び出した！"),
        String(localized: "回転する「文字ブレード」となった文字たちは、辞書の奥の「宝物庫」から5つのお宝まで持ち出して、街のあちこちで暴れまわっている。"),
        String(localized: "文字ブレードに対抗できるのは、写真から生まれたコマ──「フォトブレード」だけ。"),
        String(localized: "キミのフォトブレードで文字たちを1体ずつ鎮め、お宝を取り戻そう！　取り戻したお宝は、きっとキミのコマの力になる。"),
    ]

    static let kanjiChapters = [
        StoryChapter(number: 1, title: String(localized: "はじまりの文字"), intro: String(localized: "まず現れたのは、画数の少ない文字たち。小さな体でも、回転の勢いは本物だ。川のほうから、ドンドンと太鼓の音が聞こえてくる……。")),
        StoryChapter(number: 2, title: String(localized: "五行の試練"), intro: String(localized: "火・水・木・金・土──世界をつくる五行の文字たちが、行く手を阻む。五行の奥の大地には、文字に宿る「漢字の魂」が眠っているという。")),
        StoryChapter(number: 3, title: String(localized: "荒ぶる自然"), intro: String(localized: "空が暗くなり、風がうなる。自然の力を宿した文字たちが目を覚ました。その先で、黄金の光がギラリとまたたいている。")),
        StoryChapter(number: 4, title: String(localized: "伝説の獣"), intro: String(localized: "地響きとともに現れたのは、伝説に語られる獣の文字たち。吹き荒れる嵐の中で、チリーンと鈴の音が鳴り続けている。")),
        StoryChapter(number: 5, title: String(localized: "覇王の城"), intro: String(localized: "ついにたどり着いた覇王の城。お宝の最後のひとつ、ギラギラのネオンが城を照らしている。文字たちを解き放った黒幕が、この奥で待っている。")),
    ]

    static let kanjiEnding = [
        String(localized: "最後の文字「覇」が、静かに回転を止めた。"),
        String(localized: "暴れていた文字たちは、ひとつ、またひとつと辞書の中へ帰っていく。"),
        String(localized: "取り戻した5つのお宝は、キミのフォトブレードを飾る力になった。"),
        String(localized: "「……見事だ、フォトブレーダー」"),
        String(localized: "こうして文字の世界に平和が戻った。"),
        String(localized: "──でも、辞書にはまだ何千もの文字が眠っている。ほかのストーリーやランダム連戦で、次なる挑戦者が待っているぞ！"),
    ]
}
