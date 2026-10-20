//
//  EmojiStory.swift
//  PictureBrade
//

import UIKit

/// 絵文字のストーリー：宇宙からやってきた絵文字たちを追って、宇宙の果ての母船を目指す
enum EmojiStory {
    static let prologue = [
        "ある夜、空に光る円盤が現れた。中から降ってきたのは──絵文字たち！",
        "顔も、動物も、食べ物も。宇宙からやってきた絵文字たちは、回転する「文字ブレード」になって街中で大騒ぎ。",
        "文字ブレードに対抗できるのは、写真から生まれたコマ──「フォトブレード」だけ。",
        "キミのフォトブレードで、絵文字たちを宇宙へ帰そう！",
    ]

    static let chapters = [
        StoryChapter(story: .emoji, number: 1, title: "にこにこ広場", intro: "笑ったり、怒ったり。表情ゆたかな顔の絵文字たちが、広場で大暴れ！"),
        StoryChapter(story: .emoji, number: 2, title: "どうぶつジャングル", intro: "鳴き声がこだまするジャングル。どうぶつの絵文字たちが、縄張りを守っている。"),
        StoryChapter(story: .emoji, number: 3, title: "まんぷく横丁", intro: "いいにおいがしてきた……！　食べ物の絵文字たちが、屋台の通りで待ち構えている。"),
        StoryChapter(story: .emoji, number: 4, title: "のりものハイウェイ", intro: "エンジン全開！　のりものの絵文字たちが、猛スピードで追いかけてくる。"),
        StoryChapter(story: .emoji, number: 5, title: "宇宙の果て", intro: "ロケットに乗って、たどり着いたのは宇宙の果て。絵文字たちを地球に送りこんだ黒幕が、母船で待っている。"),
    ]

    static let ending = [
        "最後の絵文字「👾」が、静かに回転を止めた。",
        "「ピコ……ピコ……。地球のコマ、つよすぎる……。おとなしく帰るよ」",
        "絵文字たちは、ひとつ、またひとつと円盤に吸いこまれ、宇宙へ帰っていく。",
        "こうして地球に平和が戻った。",
        "──でも、文字たちはまだまだいる。ほかのストーリーやランダム連戦にも挑戦しよう！",
    ]

    static let enemies: [Enemy] = [
        // 第1章 にこにこ広場
        Enemy(character: "🙂", reading: "にっこり", level: 1, color: .systemYellow, isEmoji: true, story: .emoji,
              intro: "にっこり。笑顔で回るよ。でも、目は笑ってないかもね？",
              defeat: "にっこり……できない……"),
        Enemy(character: "😆", reading: "おおわらい", level: 1, color: .systemYellow, isEmoji: true, story: .emoji,
              intro: "あはははは！　笑いが止まらない！　回転も止まらないぞ〜！",
              defeat: "わ、笑いすぎて……目が回った……"),
        Enemy(character: "😎", reading: "サングラス", level: 1, color: .systemOrange, isEmoji: true, story: .emoji,
              intro: "フッ……サングラスの奥の目は、キミの動きを全部見切っている",
              defeat: "サングラスが……ずれた……"),
        Enemy(character: "😡", reading: "ぷんぷん", level: 1, color: .systemRed, isEmoji: true, story: .emoji,
              intro: "ぷんぷん！　なんでジャマするの！　怒りの回転を受けてみろ！",
              defeat: "怒りすぎて……疲れた……。「🤯」は頭が爆発しそうなくらい強いぞ"),
        Enemy(character: "🤯", reading: "あたまドカーン", level: 1, color: .systemOrange, isEmoji: true, story: .emoji,
              intro: "地球は情報が多すぎて、頭がドカーン！　その爆発パワーで、キミを吹き飛ばす！",
              defeat: "頭が……スッキリした……。ジャングルの動物たちは、もっと手ごわいぞ"),
        // 第2章 どうぶつジャングル
        Enemy(character: "🐶", reading: "いぬ", level: 2, color: .systemBrown, isEmoji: true, story: .emoji,
              intro: "ワンワン！　しっぽをふりふり、全力で回るワン！",
              defeat: "クゥ〜ン……"),
        Enemy(character: "🐱", reading: "ねこ", level: 2, color: .systemYellow, isEmoji: true, story: .emoji,
              intro: "ニャッ。気まぐれなネコの回転、読めるものなら読んでみニャ",
              defeat: "ニャんてこった……"),
        Enemy(character: "🐸", reading: "かえる", level: 2, color: .systemGreen, isEmoji: true, story: .emoji,
              intro: "ケロケロ！　ぴょんと跳ねて、ケロっと勝っちゃうケロ！",
              defeat: "ケロ……おうちに帰る……"),
        Enemy(character: "🐼", reading: "パンダ", level: 2, color: .systemGray, isEmoji: true, story: .emoji,
              intro: "のんびりパンダだけど、体は重いよ。押し出せるかな？",
              defeat: "笹を食べて……出直す……。ジャングルの王様が怒ってるよ"),
        Enemy(character: "🦁", reading: "ライオン", level: 2, color: .systemOrange, isEmoji: true, story: .emoji,
              intro: "ガオォォ！　ジャングルの王、ライオン様だ！　王の回転にひれ伏せ！",
              defeat: "王の座を……ゆずろう……。この先から、おいしいにおいがするぞ"),
        // 第3章 まんぷく横丁
        Enemy(character: "🍙", reading: "おにぎり", level: 3, color: .systemGray, isEmoji: true, story: .emoji,
              intro: "具は何かって？　それは勝負が終わってからのお楽しみ！",
              defeat: "具は……梅干しでした……"),
        Enemy(character: "🍣", reading: "おすし", level: 3, color: .systemRed, isEmoji: true, story: .emoji,
              intro: "へいらっしゃい！　回転ずしならぬ、回転コマのおすしだよ！",
              defeat: "お、お会計で……"),
        Enemy(character: "🍩", reading: "ドーナツ", level: 3, color: .systemPink, isEmoji: true, story: .emoji,
              intro: "まんなかに穴があいてても、回転には自信あり！　甘く見ないでね",
              defeat: "穴があったら……入りたい……"),
        Enemy(character: "🍕", reading: "ピザ", level: 3, color: .systemOrange, isEmoji: true, story: .emoji,
              intro: "8つに切り分けたピースのように、キミのコマも切り分けてやる！",
              defeat: "ピザ……冷めちゃった……。最後はハンバーガーの親分だ"),
        Enemy(character: "🍔", reading: "ハンバーガー", level: 3, color: .systemBrown, isEmoji: true, story: .emoji,
              intro: "パン、肉、チーズ、レタス！　重ねた具材のぶん、重くて強いぞ！",
              defeat: "具が……はみ出た……。のりものたちが、エンジンをふかしてる音がする"),
        // 第4章 のりものハイウェイ
        Enemy(character: "🚲", reading: "じてんしゃ", level: 4, color: .systemGreen, isEmoji: true, story: .emoji,
              intro: "チリンチリン！　ペダルをこいで、ぐるぐる回るよ！",
              defeat: "パンクしちゃった……"),
        Enemy(character: "🚗", reading: "くるま", level: 4, color: .systemRed, isEmoji: true, story: .emoji,
              intro: "ブーン！　アクセル全開、ハンドルさばきには自信があるぜ",
              defeat: "ガス欠だ……"),
        Enemy(character: "🚒", reading: "しょうぼうしゃ", level: 4, color: .systemRed, isEmoji: true, story: .emoji,
              intro: "ウーウー！　キミの燃える闘志、消火してやる！",
              defeat: "火は消せても……キミは止められなかった……"),
        Enemy(character: "🚄", reading: "しんかんせん", level: 4, color: .systemBlue, isEmoji: true, story: .emoji,
              intro: "時速300キロの回転！　ついてこられるかな？",
              defeat: "終点です……。お忘れ物のないように……"),
        Enemy(character: "🚀", reading: "ロケット", level: 4, color: .systemIndigo, isEmoji: true, story: .emoji,
              intro: "3、2、1……発射！　宇宙まで吹き飛ばしてあげる！",
              defeat: "負けたから……宇宙まで乗せてあげる。黒幕は宇宙の果てにいるよ"),
        // 第5章 宇宙の果て
        Enemy(character: "🌙", reading: "みかづき", level: 5, color: .systemYellow, isEmoji: true, story: .emoji,
              intro: "夜空に浮かぶ三日月。ほそい体で、するどく切り裂く！",
              defeat: "満ちる前に……欠けてしまった……"),
        Enemy(character: "🪐", reading: "どせい", level: 5, color: .systemOrange, isEmoji: true, story: .emoji,
              intro: "ワタシの輪っかは、回転のあかし。輪の中に閉じ込めてあげる",
              defeat: "輪っかが……外れた……"),
        Enemy(character: "☄️", reading: "すいせい", level: 5, color: .systemCyan, isEmoji: true, story: .emoji,
              intro: "流れ星に願いごと？　そんなひまは与えない！　一瞬で燃え尽きろ！",
              defeat: "願いは……かなわなかった……"),
        Enemy(character: "👽", reading: "うちゅうじん", level: 5, color: .systemGreen, isEmoji: true, story: .emoji,
              intro: "ワレワレハ、ウチュウジンダ。チキュウノ、コマヲ、シラベサセテモラウ",
              defeat: "ワレワレノ……マケダ……。「👾」サマニ、キヲツケロ……"),
        Enemy(character: "👾", reading: "インベーダー", level: 5, color: .systemPurple, isEmoji: true, story: .emoji,
              intro: "ピコピコ……ボクは「👾」。絵文字たちを地球に送りこんだのは、このボクさ！　地球のコマなんて、ピコッとやっつけてあげる！",
              defeat: "ピコ……ピコ……。写真から生まれたコマ……計算外……"),
    ]
}
