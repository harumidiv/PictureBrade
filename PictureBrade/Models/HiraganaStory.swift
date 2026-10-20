//
//  HiraganaStory.swift
//  PictureBrade
//

import UIKit

/// ひらがなのストーリー：こどもの国から飛び出したひらがなたちを追いかける
enum HiraganaStory {
    static let prologue = [
        "ある日、こどもの国のおもちゃ箱から、ひらがなたちが飛び出した！",
        "まるくて、やわらかくて、ちょっぴりいたずら好きなひらがなたち。回転する「文字ブレード」になって、町じゅうを転がりまわっている。",
        "文字ブレードに対抗できるのは、写真から生まれたコマ──「フォトブレード」だけ。",
        "キミのフォトブレードで、ひらがなたちをこどもの国へ帰してあげよう！",
    ]

    static let chapters = [
        StoryChapter(story: .hiragana, number: 1, title: "はじまりのあ行", intro: "あいうえお──いちばん最初に習う5つの文字が、元気いっぱいに回りだした。"),
        StoryChapter(story: .hiragana, number: 2, title: "くるくるの丘", intro: "くるんと丸まったひらがなたち。まるい形は、長く回り続けるのが得意だ。"),
        StoryChapter(story: .hiragana, number: 3, title: "にごりの洞窟", intro: "暗い洞窟に響く、にごった声。点々や丸をつけたひらがなたちが待ち構えている。"),
        StoryChapter(story: .hiragana, number: 4, title: "ちいさな入り江", intro: "小さな体で、言葉の音を変えてしまう「小さい文字」たち。あなどると痛い目を見るぞ。"),
        StoryChapter(story: .hiragana, number: 5, title: "しりとりの塔", intro: "こどもの国の真ん中にそびえる塔。てっぺんで待つのは、しりとりを終わらせる文字だ。"),
    ]

    static let ending = [
        "最後の文字「ん」が、静かに回転を止めた。",
        "「……しりとりは『ん』でおしまい。キミの勝ちだよ」",
        "ひらがなたちは、あいうえお順に並んで、こどもの国のおもちゃ箱へ帰っていく。",
        "こうして、こどもの国に平和が戻った。",
        "──でも、文字たちはまだまだいる。ほかのストーリーやランダム連戦にも挑戦しよう！",
    ]

    static let enemies: [Enemy] = [
        // 第1章 はじまりのあ行
        Enemy(character: "あ", reading: "", level: 1, color: .systemRed, story: .hiragana,
              intro: "あいうえおの「あ」！　いちばん最初の文字として、負けるわけにはいかないの！",
              defeat: "あ……あっけなかった……。次の「い」はまっすぐな子よ"),
        Enemy(character: "い", reading: "", level: 1, color: .systemOrange, story: .hiragana,
              intro: "2本の線で立つ「い」。シンプルだけど、いい回転するでしょ？",
              defeat: "いいコマだね……。「う」はちょっと気まぐれだよ"),
        Enemy(character: "う", reading: "", level: 1, color: .systemYellow, story: .hiragana,
              intro: "うふふ、ボクは「う」。うずまくように回っちゃうよ！",
              defeat: "うう……うまくいかなかった……"),
        Enemy(character: "え", reading: "", level: 1, color: .systemGreen, story: .hiragana,
              intro: "えっへん！　「え」の回転、とくと見よ！",
              defeat: "えっ……負けちゃった……。あ行のリーダー「お」が待ってるよ"),
        Enemy(character: "お", reading: "", level: 1, color: .systemBlue, story: .hiragana,
              intro: "おっと、ここから先は通さない！　あ行のしめくくり、「お」が相手だ！",
              defeat: "おみごと……。この先は、くるくる丸まった文字たちの丘だ"),
        // 第2章 くるくるの丘
        Enemy(character: "の", reading: "", level: 2, color: .systemMint, story: .hiragana,
              intro: "のんびり、のびのび、「の」の字に回る。ぐるっと一周、のみこんじゃうぞ",
              defeat: "のびちゃった……"),
        Enemy(character: "ろ", reading: "", level: 2, color: .systemTeal, story: .hiragana,
              intro: "「ろ」は「る」とそっくりだけど、しっぽがないのさ。まちがえないでよ！",
              defeat: "ろくに回れなかった……。弟の「る」はしっぽ付きだぞ"),
        Enemy(character: "る", reading: "", level: 2, color: .systemCyan, story: .hiragana,
              intro: "しっぽをくるんと巻いた「る」だよ。兄ちゃんのかたきはとる！",
              defeat: "るるる……しっぽが目を回した……"),
        Enemy(character: "め", reading: "", level: 2, color: .systemPink, story: .hiragana,
              intro: "目をつぶっても勝てるわよ。「ぬ」ちゃんとは似てるけど、別人だからね！",
              defeat: "め、目が回る〜。「ぬ」ちゃんは手ごわいわよ"),
        Enemy(character: "ぬ", reading: "", level: 2, color: .systemPurple, story: .hiragana,
              intro: "くるりとしっぽを丸めた「ぬ」こそ、丘のぬし。「め」とは違うのだよ、「め」とは！",
              defeat: "ぬぬぬ……。この先の洞窟には、にごった声の文字たちがいる……"),
        // 第3章 にごりの洞窟
        Enemy(character: "が", reading: "", level: 3, color: .systemBrown, story: .hiragana,
              intro: "ガガガッ！　点々2つで、「か」が「が」に変身だ！",
              defeat: "が、がっくり……"),
        Enemy(character: "ざ", reading: "", level: 3, color: .systemGray, story: .hiragana,
              intro: "ザザーッと砂嵐のように回る「ざ」！　ザラザラの回転を味わえ！",
              defeat: "ざんねん……"),
        Enemy(character: "だ", reading: "", level: 3, color: .systemIndigo, story: .hiragana,
              intro: "だだだっ！　太鼓みたいに激しく回る「だ」だ！",
              defeat: "だめだった……。「ば」の兄貴は力持ちだぞ"),
        Enemy(character: "ば", reading: "", level: 3, color: .systemOrange, story: .hiragana,
              intro: "バーン！　点々の力でパワーアップした「ば」だ。吹っ飛ばしてやる！",
              defeat: "ばたんきゅう……。最後は丸をつけた「ぱ」が待ってる"),
        Enemy(character: "ぱ", reading: "", level: 3, color: .systemPink, story: .hiragana,
              intro: "ぱっぱらぱーん！　点々じゃなくて丸をつけた、特別な「ぱ」の登場だよ！",
              defeat: "ぱーっと散っちゃった……。入り江には小さい文字たちがいるよ"),
        // 第4章 ちいさな入り江
        Enemy(character: "ゃ", reading: "ちいさい や", level: 4, color: .systemRed, story: .hiragana,
              intro: "小さい「ゃ」！　ボクがつくと「き」が「きゃ」になるんだ。小さいからってなめないでよね！",
              defeat: "きゃ〜っ、負けちゃった……"),
        Enemy(character: "ゅ", reading: "ちいさい ゆ", level: 4, color: .systemGreen, story: .hiragana,
              intro: "「ゅ」がつけば「しゅ」！　シュシュッと素早く回るよ",
              defeat: "しゅん……"),
        Enemy(character: "ょ", reading: "ちいさい よ", level: 4, color: .systemBlue, story: .hiragana,
              intro: "「ょ」がつけば「ちょ」！　ちょこまか動いて、ほんろうしてあげる",
              defeat: "ちょっと……油断した……"),
        Enemy(character: "ぁ", reading: "ちいさい あ", level: 4, color: .systemYellow, story: .hiragana,
              intro: "めったに出番のない「ぁ」。「ふぁいと！」のときくらいしか呼ばれないけど、実力は本物さ",
              defeat: "ふぁ〜……やられた……。「っ」は入り江のボスだ、気をつけて"),
        Enemy(character: "っ", reading: "ちいさい つ", level: 4, color: .systemPurple, story: .hiragana,
              intro: "……（ためて）……っ！　小さい「っ」は、言葉を詰まらせる力を持つ。キミの回転も、詰まらせてやる！",
              defeat: "まいっ……た……。塔には、昔のひらがなたちが待っている"),
        // 第5章 しりとりの塔
        Enemy(character: "ゐ", reading: "い（昔の字）", level: 5, color: .systemTeal, story: .hiragana,
              intro: "われは「ゐ」。いにしえのひらがなよ。いまの子は読めぬであろう？",
              defeat: "いにしえの力も……およばぬか……"),
        Enemy(character: "ゑ", reading: "え（昔の字）", level: 5, color: .systemIndigo, story: .hiragana,
              intro: "わらわは「ゑ」。昔は「え」とは別の文字だったのじゃ。忘れられた恨み、晴らしてくれよう",
              defeat: "思い出してくれて……うれしかったぞ……"),
        Enemy(character: "を", reading: "", level: 5, color: .systemBrown, story: .hiragana,
              intro: "「を」は、言葉と言葉をつなぐ文字。でも、キミとつながる気はない！",
              defeat: "キミ「を」……みとめよう……"),
        Enemy(character: "ゔ", reading: "", level: 5, color: .systemRed, story: .hiragana,
              intro: "ゔぁぁぁ！　「う」に点々の「ゔ」だ！　めったに使われないぶん、力が有り余っている！",
              defeat: "ゔぅ……。塔のてっぺんで、「ん」様がお待ちだ……"),
        Enemy(character: "ん", reading: "", level: 5, color: .systemYellow, story: .hiragana,
              intro: "よく来たね、フォトブレーダー。ボクは「ん」。しりとりを終わらせる、最後の文字さ。キミの冒険も、ここで「ん」にしてあげる！",
              defeat: "しりとりは……ボクの負け……。キミに続く言葉は、まだまだあるんだね"),
    ]
}
