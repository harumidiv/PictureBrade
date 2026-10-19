//
//  Story.swift
//  PictureBrade
//

import Foundation

/// ストーリーモードの章（章番号 = 敵のレベル）
struct StoryChapter: Identifiable {
    let number: Int
    let title: String
    let intro: String

    var id: Int { number }
    var enemies: [Enemy] { EnemyCatalog.enemies.filter { $0.level == number } }
}

enum Story {
    static let prologue = [
        "ある日、辞書の中から文字たちが飛び出した！",
        "回転する「文字ブレード」となった文字たちは、街のあちこちで暴れまわっている。",
        "文字ブレードに対抗できるのは、写真から生まれたコマ──「フォトブレード」だけ。",
        "キミのフォトブレードで、文字たちを1体ずつ鎮めていこう！",
    ]

    static let chapters = [
        StoryChapter(number: 1, title: "はじまりの文字", intro: "まず現れたのは、画数の少ない文字たち。小さな体でも、回転の勢いは本物だ。"),
        StoryChapter(number: 2, title: "五行の試練", intro: "火・水・木・金・土──世界をつくる五行の文字たちが、行く手を阻む。"),
        StoryChapter(number: 3, title: "荒ぶる自然", intro: "空が暗くなり、風がうなる。自然の力を宿した文字たちが目を覚ました。"),
        StoryChapter(number: 4, title: "伝説の獣", intro: "地響きとともに現れたのは、伝説に語られる獣の文字たち。ここからが本番だ。"),
        StoryChapter(number: 5, title: "覇王の城", intro: "ついにたどり着いた覇王の城。文字たちを解き放った黒幕が、この奥で待っている。"),
    ]

    static let ending = [
        "最後の文字「覇」が、静かに回転を止めた。",
        "暴れていた文字たちは、ひとつ、またひとつと辞書の中へ帰っていく。",
        "「……見事だ、フォトブレーダー」",
        "こうして文字の世界に平和が戻った。",
        "──でも、辞書にはまだ何千もの文字が眠っている。ランダム連戦で、次なる挑戦者が待っているぞ！",
    ]

    static func chapter(for enemy: Enemy) -> StoryChapter? {
        chapters.first { $0.number == enemy.level }
    }
}
