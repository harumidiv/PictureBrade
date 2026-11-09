//
//  HiraganaStory.swift
//  PictureBrade
//

import UIKit

/// ひらがなのストーリー：こどもの国から飛び出したひらがなたちを追いかける
enum HiraganaStory {
    static let prologue = [
        String(localized: "ある日、こどもの国のおもちゃ箱から、ひらがなたちが飛び出した！"),
        String(localized: "まるくて、やわらかくて、ちょっぴりいたずら好きなひらがなたち。おもちゃ箱の宝物まで持ち出して、回転する「文字ブレード」になって町じゅうを転がりまわっている。"),
        String(localized: "文字ブレードに対抗できるのは、写真から生まれたコマ──「フォトブレード」だけ。"),
        String(localized: "キミのフォトブレードで、ひらがなたちをこどもの国へ帰して、おもちゃ箱の宝物を取り戻そう！"),
    ]

    static let chapters = [
        StoryChapter(story: .hiragana, number: 1, title: String(localized: "はじまりのあ行"), intro: String(localized: "あいうえお──いちばん最初に習う5つの文字が、元気いっぱいに回りだした。リーダーの「お」は、ひらがなの力がつまった「あいうえおの積み木」を持っているらしい。")),
        StoryChapter(story: .hiragana, number: 2, title: String(localized: "くるくるの丘"), intro: String(localized: "くるんと丸まったひらがなたち。まるい形は、長く回り続けるのが得意だ。丘のてっぺんから、ハートがふわふわ飛んでくる……？")),
        StoryChapter(story: .hiragana, number: 3, title: String(localized: "にごりの洞窟"), intro: String(localized: "暗い洞窟に響く、にごった声。点々や丸をつけたひらがなたちが待ち構えている。奥からは、ポンッ、ポンッとはじける音がする。")),
        StoryChapter(story: .hiragana, number: 4, title: String(localized: "ちいさな入り江"), intro: String(localized: "小さな体で、言葉の音を変えてしまう「小さい文字」たち。あなどると痛い目を見るぞ。入り江には、びよよーんとよく跳ねるバネが隠されているという。")),
        StoryChapter(story: .hiragana, number: 5, title: String(localized: "しりとりの塔"), intro: String(localized: "こどもの国の真ん中にそびえる塔。てっぺんには大きな虹がかかり、しりとりを終わらせる文字が待っている。")),
    ]

    static let ending = [
        String(localized: "最後の文字「ん」が、静かに回転を止めた。"),
        String(localized: "「……しりとりは『ん』でおしまい。キミの勝ちだよ」"),
        String(localized: "ひらがなたちは、あいうえお順に並んで、こどもの国のおもちゃ箱へ帰っていく。"),
        String(localized: "取り戻した宝物は、キミのフォトブレードの新しい力になった。"),
        String(localized: "こうして、こどもの国に平和が戻った。"),
        String(localized: "──でも、文字たちはまだまだいる。ほかのストーリーやランダム連戦にも挑戦しよう！"),
    ]

    static let enemies: [Enemy] = [
        // 第1章 はじまりのあ行
        Enemy(character: "あ", reading: "", level: 1, color: .systemRed, story: .hiragana,
              intro: String(localized: "あいうえおの「あ」！　いちばん最初の文字として、負けるわけにはいかないの！"),
              defeat: String(localized: "あ……あっけなかった……。次の「い」はまっすぐな子よ")),
        Enemy(character: "い", reading: "", level: 1, color: .systemOrange, story: .hiragana,
              intro: String(localized: "2本の線で立つ「い」。シンプルだけど、いい回転するでしょ？"),
              defeat: String(localized: "いいコマだね……。「う」はちょっと気まぐれだよ")),
        Enemy(character: "う", reading: "", level: 1, color: .systemYellow, story: .hiragana,
              intro: String(localized: "うふふ、ボクは「う」。うずまくように回っちゃうよ！"),
              defeat: String(localized: "うう……うまくいかなかった……")),
        Enemy(character: "え", reading: "", level: 1, color: .systemGreen, story: .hiragana,
              intro: String(localized: "えっへん！　「え」の回転、とくと見よ！"),
              defeat: String(localized: "えっ……負けちゃった……。あ行のリーダー「お」が待ってるよ")),
        Enemy(character: "お", reading: "", level: 1, color: .systemBlue, story: .hiragana,
              intro: String(localized: "おっと、ここから先は通さない！　この「あいうえおの積み木」は渡さないぞ。あ行のしめくくり、「お」が相手だ！"),
              defeat: String(localized: "おみごと……。積み木はキミにあげる。ぶつかるたびに、ひらがなが飛び出すよ。この先は、くるくる丸まった文字たちの丘だ")),
        // 第2章 くるくるの丘
        Enemy(character: "の", reading: "", level: 2, color: .systemMint, story: .hiragana,
              intro: String(localized: "のんびり、のびのび、「の」の字に回る。ぐるっと一周、のみこんじゃうぞ"),
              defeat: String(localized: "のびちゃった……")),
        Enemy(character: "ろ", reading: "", level: 2, color: .systemTeal, story: .hiragana,
              intro: String(localized: "「ろ」は「る」とそっくりだけど、しっぽがないのさ。まちがえないでよ！"),
              defeat: String(localized: "ろくに回れなかった……。弟の「る」はしっぽ付きだぞ")),
        Enemy(character: "る", reading: "", level: 2, color: .systemCyan, story: .hiragana,
              intro: String(localized: "しっぽをくるんと巻いた「る」だよ。兄ちゃんのかたきはとる！"),
              defeat: String(localized: "るるる……しっぽが目を回した……")),
        Enemy(character: "め", reading: "", level: 2, color: .systemPink, story: .hiragana,
              intro: String(localized: "目をつぶっても勝てるわよ。「ぬ」ちゃんとは似てるけど、別人だからね！"),
              defeat: String(localized: "め、目が回る〜。「ぬ」ちゃんは手ごわいわよ")),
        Enemy(character: "ぬ", reading: "", level: 2, color: .systemPurple, story: .hiragana,
              intro: String(localized: "くるりとしっぽを丸めた「ぬ」こそ、丘のぬし。丘いっぱいのハートは、ぜんぶワシのもの。「め」とは違うのだよ、「め」とは！"),
              defeat: String(localized: "ぬぬぬ……キミの回転に、ハートをうばわれてしまった……。このハート、持っていくがいい。この先の洞窟には、にごった声の文字たちがいる……")),
        // 第3章 にごりの洞窟
        Enemy(character: "が", reading: "", level: 3, color: .systemBrown, story: .hiragana,
              intro: String(localized: "ガガガッ！　点々2つで、「か」が「が」に変身だ！"),
              defeat: String(localized: "が、がっくり……")),
        Enemy(character: "ざ", reading: "", level: 3, color: .systemGray, story: .hiragana,
              intro: String(localized: "ザザーッと砂嵐のように回る「ざ」！　ザラザラの回転を味わえ！"),
              defeat: String(localized: "ざんねん……")),
        Enemy(character: "だ", reading: "", level: 3, color: .systemIndigo, story: .hiragana,
              intro: String(localized: "だだだっ！　太鼓みたいに激しく回る「だ」だ！"),
              defeat: String(localized: "だめだった……。「ば」の兄貴は力持ちだぞ")),
        Enemy(character: "ば", reading: "", level: 3, color: .systemOrange, story: .hiragana,
              intro: String(localized: "バーン！　点々の力でパワーアップした「ば」だ。吹っ飛ばしてやる！"),
              defeat: String(localized: "ばたんきゅう……。最後は丸をつけた「ぱ」が待ってる")),
        Enemy(character: "ぱ", reading: "", level: 3, color: .systemPink, story: .hiragana,
              intro: String(localized: "ぱっぱらぱーん！　点々じゃなくて丸をつけた、特別な「ぱ」の登場だよ！　ポンッとはじける音は、ボクの宝物なんだ！"),
              defeat: String(localized: "ぱーっと散っちゃった……。はじける音、キミにあげるね。ポンッといい音させてよ！　入り江には小さい文字たちがいるよ")),
        // 第4章 ちいさな入り江
        Enemy(character: "ゃ", reading: String(localized: "ちいさい や"), level: 4, color: .systemRed, story: .hiragana,
              intro: String(localized: "小さい「ゃ」！　ボクがつくと「き」が「きゃ」になるんだ。小さいからってなめないでよね！"),
              defeat: String(localized: "きゃ〜っ、負けちゃった……")),
        Enemy(character: "ゅ", reading: String(localized: "ちいさい ゆ"), level: 4, color: .systemGreen, story: .hiragana,
              intro: String(localized: "「ゅ」がつけば「しゅ」！　シュシュッと素早く回るよ"),
              defeat: String(localized: "しゅん……")),
        Enemy(character: "ょ", reading: String(localized: "ちいさい よ"), level: 4, color: .systemBlue, story: .hiragana,
              intro: String(localized: "「ょ」がつけば「ちょ」！　ちょこまか動いて、ほんろうしてあげる"),
              defeat: String(localized: "ちょっと……油断した……")),
        Enemy(character: "ぁ", reading: String(localized: "ちいさい あ"), level: 4, color: .systemYellow, story: .hiragana,
              intro: String(localized: "めったに出番のない「ぁ」。「ふぁいと！」のときくらいしか呼ばれないけど、実力は本物さ"),
              defeat: String(localized: "ふぁ〜……やられた……。「っ」は入り江のボスだ、気をつけて")),
        Enemy(character: "っ", reading: String(localized: "ちいさい つ"), level: 4, color: .systemPurple, story: .hiragana,
              intro: String(localized: "……（ためて）……っ！　小さい「っ」は、ぐっとためて、びよーんと跳ねる力を持つ。このバネで、キミの回転を詰まらせてやる！"),
              defeat: String(localized: "まいっ……た……。このバネ、キミが使って。ぶつかるたびに、びよーんって鳴るよ。塔には、昔のひらがなたちが待っている")),
        // 第5章 しりとりの塔
        Enemy(character: "ゐ", reading: String(localized: "い（昔の字）"), level: 5, color: .systemTeal, story: .hiragana,
              intro: String(localized: "われは「ゐ」。いにしえのひらがなよ。いまの子は読めぬであろう？"),
              defeat: String(localized: "いにしえの力も……およばぬか……")),
        Enemy(character: "ゑ", reading: String(localized: "え（昔の字）"), level: 5, color: .systemIndigo, story: .hiragana,
              intro: String(localized: "わらわは「ゑ」。昔は「え」とは別の文字だったのじゃ。忘れられた恨み、晴らしてくれよう"),
              defeat: String(localized: "思い出してくれて……うれしかったぞ……")),
        Enemy(character: "を", reading: "", level: 5, color: .systemBrown, story: .hiragana,
              intro: String(localized: "「を」は、言葉と言葉をつなぐ文字。でも、キミとつながる気はない！"),
              defeat: String(localized: "キミ「を」……みとめよう……")),
        Enemy(character: "ゔ", reading: "", level: 5, color: .systemRed, story: .hiragana,
              intro: String(localized: "ゔぁぁぁ！　「う」に点々の「ゔ」だ！　めったに使われないぶん、力が有り余っている！"),
              defeat: String(localized: "ゔぅ……。塔のてっぺんで、「ん」様がお待ちだ……")),
        Enemy(character: "ん", reading: "", level: 5, color: .systemYellow, story: .hiragana,
              intro: String(localized: "よく来たね、フォトブレーダー。ボクは「ん」。しりとりを終わらせる、最後の文字さ。塔にかかる虹は、ボクの宝物。キミの冒険も、ここで「ん」にしてあげる！"),
              defeat: String(localized: "しりとりは……ボクの負け……。この虹は、キミのコマにかけてあげる。キミに続く言葉は、まだまだあるんだね")),
    ]
}
