//
//  EmojiStory.swift
//  PictureBrade
//

import UIKit

/// 絵文字のストーリー：宇宙からやってきた絵文字たちを追って、宇宙の果ての母船を目指す
enum EmojiStory {
    static let prologue = [
        String(localized: "ある夜、空に光る円盤が現れた。中から降ってきたのは──絵文字たち！"),
        String(localized: "顔も、動物も、食べ物も。宇宙からやってきた絵文字たちは、円盤に積んであったふしぎな道具まで持ち出して、回転する「文字ブレード」になって街中で大騒ぎ。"),
        String(localized: "文字ブレードに対抗できるのは、写真から生まれたコマ──「フォトブレード」だけ。"),
        String(localized: "キミのフォトブレードで絵文字たちを宇宙へ帰して、ふしぎな道具を手に入れよう！"),
    ]

    static let chapters = [
        StoryChapter(story: .emoji, number: 1, title: String(localized: "にこにこ広場"), intro: String(localized: "笑ったり、怒ったり。表情ゆたかな顔の絵文字たちが、広場で大暴れ！　だれかの頭がドカーンとなるたび、キラキラの星が飛び散っている。")),
        StoryChapter(story: .emoji, number: 2, title: String(localized: "どうぶつジャングル"), intro: String(localized: "鳴き声がこだまするジャングル。どうぶつの絵文字たちが、縄張りを守っている。ジャングルの王は、円盤から持ち出した「ドットカメラ」で、なんでもドット絵にしてしまうらしい。")),
        StoryChapter(story: .emoji, number: 3, title: String(localized: "まんぷく横丁"), intro: String(localized: "いいにおいがしてきた……！　食べ物の絵文字たちが、屋台の通りで待ち構えている。横丁の親分は、絵文字が飛び出すパーティーの準備中らしい。")),
        StoryChapter(story: .emoji, number: 4, title: String(localized: "のりものハイウェイ"), intro: String(localized: "エンジン全開！　のりものの絵文字たちが、猛スピードで追いかけてくる。ハイウェイの先のロケットから、ピコピコと電子音が聞こえる。")),
        StoryChapter(story: .emoji, number: 5, title: String(localized: "宇宙の果て"), intro: String(localized: "ロケットに乗って、たどり着いたのは宇宙の果て。絵文字たちを地球に送りこんだ黒幕が、なんでも光に変えてしまうホログラム装置とともに、母船で待っている。")),
    ]

    static let ending = [
        String(localized: "最後の絵文字「👾」が、静かに回転を止めた。"),
        String(localized: "「ピコ……ピコ……。地球のコマ、つよすぎる……。おとなしく帰るよ」"),
        String(localized: "絵文字たちは、ひとつ、またひとつと円盤に吸いこまれ、宇宙へ帰っていく。"),
        String(localized: "絵文字たちがのこしていったふしぎな道具は、キミのフォトブレードの宝物になった。"),
        String(localized: "こうして地球に平和が戻った。"),
        String(localized: "──でも、文字たちはまだまだいる。ほかのストーリーやランダム連戦にも挑戦しよう！"),
    ]

    static let enemies: [Enemy] = [
        // 第1章 にこにこ広場
        Enemy(character: "🙂", reading: String(localized: "にっこり"), level: 1, color: .systemYellow, isEmoji: true, story: .emoji,
              intro: String(localized: "にっこり。笑顔で回るよ。でも、目は笑ってないかもね？"),
              defeat: String(localized: "にっこり……できない……")),
        Enemy(character: "😆", reading: String(localized: "おおわらい"), level: 1, color: .systemYellow, isEmoji: true, story: .emoji,
              intro: String(localized: "あはははは！　笑いが止まらない！　回転も止まらないぞ〜！"),
              defeat: String(localized: "わ、笑いすぎて……目が回った……")),
        Enemy(character: "😎", reading: String(localized: "サングラス"), level: 1, color: .systemOrange, isEmoji: true, story: .emoji,
              intro: String(localized: "フッ……サングラスの奥の目は、キミの動きを全部見切っている"),
              defeat: String(localized: "サングラスが……ずれた……")),
        Enemy(character: "😡", reading: String(localized: "ぷんぷん"), level: 1, color: .systemRed, isEmoji: true, story: .emoji,
              intro: String(localized: "ぷんぷん！　なんでジャマするの！　怒りの回転を受けてみろ！"),
              defeat: String(localized: "怒りすぎて……疲れた……。「🤯」は頭が爆発しそうなくらい強いぞ")),
        Enemy(character: "🤯", reading: String(localized: "あたまドカーン"), level: 1, color: .systemOrange, isEmoji: true, story: .emoji,
              intro: String(localized: "地球は情報が多すぎて、頭がドカーン！　飛び散るキラキラ星といっしょに、キミを吹き飛ばす！"),
              defeat: String(localized: "頭が……スッキリした……。このキラキラ星、キミにあげる。ジャングルの動物たちは、もっと手ごわいぞ")),
        // 第2章 どうぶつジャングル
        Enemy(character: "🐶", reading: String(localized: "いぬ"), level: 2, color: .systemBrown, isEmoji: true, story: .emoji,
              intro: String(localized: "ワンワン！　しっぽをふりふり、全力で回るワン！"),
              defeat: String(localized: "クゥ〜ン……")),
        Enemy(character: "🐱", reading: String(localized: "ねこ"), level: 2, color: .systemYellow, isEmoji: true, story: .emoji,
              intro: String(localized: "ニャッ。気まぐれなネコの回転、読めるものなら読んでみニャ"),
              defeat: String(localized: "ニャんてこった……")),
        Enemy(character: "🐸", reading: String(localized: "かえる"), level: 2, color: .systemGreen, isEmoji: true, story: .emoji,
              intro: String(localized: "ケロケロ！　ぴょんと跳ねて、ケロっと勝っちゃうケロ！"),
              defeat: String(localized: "ケロ……おうちに帰る……")),
        Enemy(character: "🐼", reading: String(localized: "パンダ"), level: 2, color: .systemGray, isEmoji: true, story: .emoji,
              intro: String(localized: "のんびりパンダだけど、体は重いよ。押し出せるかな？"),
              defeat: String(localized: "笹を食べて……出直す……。ジャングルの王様が怒ってるよ")),
        Enemy(character: "🦁", reading: String(localized: "ライオン"), level: 2, color: .systemOrange, isEmoji: true, story: .emoji,
              intro: String(localized: "ガオォォ！　ジャングルの王、ライオン様だ！　このドットカメラで、キミのコマもカクカクのドット絵にしてやる！"),
              defeat: String(localized: "王の座を……ゆずろう……。ドットカメラも持っていけ。この先から、おいしいにおいがするぞ")),
        // 第3章 まんぷく横丁
        Enemy(character: "🍙", reading: String(localized: "おにぎり"), level: 3, color: .systemGray, isEmoji: true, story: .emoji,
              intro: String(localized: "具は何かって？　それは勝負が終わってからのお楽しみ！"),
              defeat: String(localized: "具は……梅干しでした……")),
        Enemy(character: "🍣", reading: String(localized: "おすし"), level: 3, color: .systemRed, isEmoji: true, story: .emoji,
              intro: String(localized: "へいらっしゃい！　回転ずしならぬ、回転コマのおすしだよ！"),
              defeat: String(localized: "お、お会計で……")),
        Enemy(character: "🍩", reading: String(localized: "ドーナツ"), level: 3, color: .systemPink, isEmoji: true, story: .emoji,
              intro: String(localized: "まんなかに穴があいてても、回転には自信あり！　甘く見ないでね"),
              defeat: String(localized: "穴があったら……入りたい……")),
        Enemy(character: "🍕", reading: String(localized: "ピザ"), level: 3, color: .systemOrange, isEmoji: true, story: .emoji,
              intro: String(localized: "8つに切り分けたピースのように、キミのコマも切り分けてやる！"),
              defeat: String(localized: "ピザ……冷めちゃった……。最後はハンバーガーの親分だ")),
        Enemy(character: "🍔", reading: String(localized: "ハンバーガー"), level: 3, color: .systemBrown, isEmoji: true, story: .emoji,
              intro: String(localized: "パン、肉、チーズ、レタス！　重ねた具材のぶん、重くて強いぞ！　キミに勝ったら、絵文字パーティーのはじまりだ！"),
              defeat: String(localized: "具が……はみ出た……。パーティーの絵文字はキミにゆずるよ、🎉で盛り上げてくれ！　のりものたちが、エンジンをふかしてる音がする")),
        // 第4章 のりものハイウェイ
        Enemy(character: "🚲", reading: String(localized: "じてんしゃ"), level: 4, color: .systemGreen, isEmoji: true, story: .emoji,
              intro: String(localized: "チリンチリン！　ペダルをこいで、ぐるぐる回るよ！"),
              defeat: String(localized: "パンクしちゃった……")),
        Enemy(character: "🚗", reading: String(localized: "くるま"), level: 4, color: .systemRed, isEmoji: true, story: .emoji,
              intro: String(localized: "ブーン！　アクセル全開、ハンドルさばきには自信があるぜ"),
              defeat: String(localized: "ガス欠だ……")),
        Enemy(character: "🚒", reading: String(localized: "しょうぼうしゃ"), level: 4, color: .systemRed, isEmoji: true, story: .emoji,
              intro: String(localized: "ウーウー！　キミの燃える闘志、消火してやる！"),
              defeat: String(localized: "火は消せても……キミは止められなかった……")),
        Enemy(character: "🚄", reading: String(localized: "しんかんせん"), level: 4, color: .systemBlue, isEmoji: true, story: .emoji,
              intro: String(localized: "時速300キロの回転！　ついてこられるかな？"),
              defeat: String(localized: "終点です……。お忘れ物のないように……")),
        Enemy(character: "🚀", reading: String(localized: "ロケット"), level: 4, color: .systemIndigo, isEmoji: true, story: .emoji,
              intro: String(localized: "3、2、1……発射！　ピコピコ鳴る操縦席から、宇宙まで吹き飛ばしてあげる！"),
              defeat: String(localized: "負けたから……宇宙まで乗せてあげる。操縦席のピコピコ音もプレゼント！　黒幕は宇宙の果てにいるよ")),
        // 第5章 宇宙の果て
        Enemy(character: "🌙", reading: String(localized: "みかづき"), level: 5, color: .systemYellow, isEmoji: true, story: .emoji,
              intro: String(localized: "夜空に浮かぶ三日月。ほそい体で、するどく切り裂く！"),
              defeat: String(localized: "満ちる前に……欠けてしまった……")),
        Enemy(character: "🪐", reading: String(localized: "どせい"), level: 5, color: .systemOrange, isEmoji: true, story: .emoji,
              intro: String(localized: "ワタシの輪っかは、回転のあかし。輪の中に閉じ込めてあげる"),
              defeat: String(localized: "輪っかが……外れた……")),
        Enemy(character: "☄️", reading: String(localized: "すいせい"), level: 5, color: .systemCyan, isEmoji: true, story: .emoji,
              intro: String(localized: "流れ星に願いごと？　そんなひまは与えない！　一瞬で燃え尽きろ！"),
              defeat: String(localized: "願いは……かなわなかった……")),
        Enemy(character: "👽", reading: String(localized: "うちゅうじん"), level: 5, color: .systemGreen, isEmoji: true, story: .emoji,
              intro: String(localized: "ワレワレハ、ウチュウジンダ。チキュウノ、コマヲ、シラベサセテモラウ"),
              defeat: String(localized: "ワレワレノ……マケダ……。「👾」サマニ、キヲツケロ……")),
        Enemy(character: "👾", reading: String(localized: "インベーダー"), level: 5, color: .systemPurple, isEmoji: true, story: .emoji,
              intro: String(localized: "ピコピコ……ボクは「👾」。絵文字たちを地球に送りこんだのは、このボクさ！　母船のホログラム装置で、地球のコマなんてピコッと消してあげる！"),
              defeat: String(localized: "ピコ……ピコ……。写真から生まれたコマ……計算外……。ホログラム装置は……キミにゆずる……")),
    ]
}
