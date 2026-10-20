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
        case .kanji: "漢字の乱"
        case .hiragana: "ひらがな大冒険"
        case .emoji: "絵文字パニック"
        }
    }

    /// ストーリー選びの画面に出す一言
    var catchphrase: String {
        switch self {
        case .kanji: "辞書から飛び出した漢字たちと、覇王の城を目指せ！"
        case .hiragana: "こどもの国から飛び出したひらがなたちを、しりとりの塔まで追いかけろ！"
        case .emoji: "宇宙からやってきた絵文字たちを追って、宇宙の果ての母船へ！"
        }
    }

    /// 全員倒したあとに出陣パネルに出す言葉
    var clearedTitle: String {
        switch self {
        case .kanji: "覇王の城を取り戻した！"
        case .hiragana: "しりとりの塔をのぼりきった！"
        case .emoji: "宇宙の果てから帰ってきた！"
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
        "ある日、辞書の中から文字たちが飛び出した！",
        "回転する「文字ブレード」となった文字たちは、街のあちこちで暴れまわっている。",
        "文字ブレードに対抗できるのは、写真から生まれたコマ──「フォトブレード」だけ。",
        "キミのフォトブレードで、文字たちを1体ずつ鎮めていこう！",
    ]

    static let kanjiChapters = [
        StoryChapter(number: 1, title: "はじまりの文字", intro: "まず現れたのは、画数の少ない文字たち。小さな体でも、回転の勢いは本物だ。"),
        StoryChapter(number: 2, title: "五行の試練", intro: "火・水・木・金・土──世界をつくる五行の文字たちが、行く手を阻む。"),
        StoryChapter(number: 3, title: "荒ぶる自然", intro: "空が暗くなり、風がうなる。自然の力を宿した文字たちが目を覚ました。"),
        StoryChapter(number: 4, title: "伝説の獣", intro: "地響きとともに現れたのは、伝説に語られる獣の文字たち。ここからが本番だ。"),
        StoryChapter(number: 5, title: "覇王の城", intro: "ついにたどり着いた覇王の城。文字たちを解き放った黒幕が、この奥で待っている。"),
    ]

    static let kanjiEnding = [
        "最後の文字「覇」が、静かに回転を止めた。",
        "暴れていた文字たちは、ひとつ、またひとつと辞書の中へ帰っていく。",
        "「……見事だ、フォトブレーダー」",
        "こうして文字の世界に平和が戻った。",
        "──でも、辞書にはまだ何千もの文字が眠っている。ほかのストーリーやランダム連戦で、次なる挑戦者が待っているぞ！",
    ]
}
