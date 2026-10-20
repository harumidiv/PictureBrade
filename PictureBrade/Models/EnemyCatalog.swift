//
//  EnemyCatalog.swift
//  PictureBrade
//

import Foundation
import Observation
import UIKit

/// 敵の「文字コマ」
struct Enemy: Identifiable, Hashable {
    let character: String
    let reading: String
    /// 1...5。高いほど性能・CPUの腕前が上がる
    let level: Int
    let color: UIColor
    /// 絵文字は縁取りなしで描く
    var isEmoji = false
    /// ランダム連戦で出た敵（ストーリーの撃破記録には数えない）
    var isRandom = false
    /// どのストーリーの敵か
    var story: StoryKind = .kanji
    /// ストーリーで登場したときのセリフ
    var intro = ""
    /// ストーリーで倒されたときのセリフ
    var defeat = ""

    var id: String { (isRandom ? "random-" : "") + character }

    /// 文字ごとに固定の ID（バトル結果の記録に使う）。ランダムの敵はストーリーと重ならない範囲にする
    var bladeID: UUID {
        let scalar = character.unicodeScalars.first?.value ?? 0
        let namespace = isRandom ? "9000" : "8000"
        return UUID(uuidString: String(format: "00000000-0000-4000-\(namespace)-%012X", scalar))!
    }

    /// CPU の腕前 0...1（シュートの強さや突進の頻度に影響）
    var skill: Float { Float(level - 1) / 4 }

    /// 「あ」や「🙂（にっこり）」のような表示名（読みがあれば添える）
    var displayName: String {
        reading.isEmpty ? character : "\(character)（\(reading)）"
    }
}

/// 敵の一覧と撃破状況
@Observable
final class EnemyCatalog {
    /// 漢字ストーリーの敵（この順番で1体ずつ戦う。level が章番号）
    static let kanjiEnemies: [Enemy] = [
        // 第1章 はじまりの文字
        Enemy(character: "一", reading: "いち", level: 1, color: .systemTeal,
              intro: "オレは「一」。画数はたった1本……だが、まっすぐさなら誰にも負けん！",
              defeat: "ま、まっすぐすぎた……。キミのコマ、なかなか曲者だな"),
        Enemy(character: "人", reading: "ひと", level: 1, color: .systemGreen,
              intro: "人は支え合って生きる……でも今日は、キミを倒すために回る！",
              defeat: "支え合う相手が欲しかった……。次の「口」はおしゃべりだぞ"),
        Enemy(character: "口", reading: "くち", level: 1, color: .systemBrown,
              intro: "口ほどにもないって？　言わせないよ！　四角い体はぶつかると痛いぞ！",
              defeat: "口ほどにもなかったのはボクのほうか……"),
        Enemy(character: "山", reading: "やま", level: 1, color: .systemGreen,
              intro: "どっしり構えた山は動かない。押し出せるものなら押し出してみろ！",
              defeat: "山が……動いた……！"),
        Enemy(character: "川", reading: "かわ", level: 1, color: .systemBlue,
              intro: "流れる3本の線、それが川。この流れ、止められるかな？",
              defeat: "流れが止まった……。気をつけろ、この先は五行の文字たちが待っている"),
        // 第2章 五行の試練
        Enemy(character: "火", reading: "ひ", level: 2, color: .systemOrange,
              intro: "五行の一番手、火！　燃え尽きるまで回り続けてやる！",
              defeat: "ちっ、水があれば消えるとは思っていたが……写真に消されるとはな"),
        Enemy(character: "水", reading: "みず", level: 2, color: .systemCyan,
              intro: "火を消し、形を変える水。どんな攻撃も受け流してあげる",
              defeat: "受け流しきれなかった……。木はしぶといわよ"),
        Enemy(character: "木", reading: "き", level: 2, color: .systemGreen,
              intro: "根を張った木は倒れない。長期戦なら負けないぞ",
              defeat: "根こそぎ……やられた……"),
        Enemy(character: "金", reading: "きん", level: 2, color: .systemYellow,
              intro: "硬くて重い、それが金！　キラキラ回って跳ね返してやる！",
              defeat: "ピカピカのボディに傷が……。土のヤツは手ごわいぞ"),
        Enemy(character: "土", reading: "つち", level: 2, color: .systemBrown,
              intro: "五行の最後、土。すべてを受け止める大地の力を見せてやろう",
              defeat: "大地が揺れた……。この先の文字たちは、自然そのものの力を持っている"),
        // 第3章 荒ぶる自然
        Enemy(character: "炎", reading: "ほのお", level: 3, color: .systemRed,
              intro: "火が2つ重なれば炎！　さっきの「火」とは格が違うぜ！",
              defeat: "燃え広がる前に……消された……"),
        Enemy(character: "雷", reading: "かみなり", level: 3, color: .systemYellow,
              intro: "ゴロゴロ……ピシャーン！　雷の速さについてこられるか！",
              defeat: "雨の下に田んぼ……そう、オレは雷。覚えておけ……"),
        Enemy(character: "風", reading: "かぜ", level: 3, color: .systemMint,
              intro: "見えない風が、キミのコマを場外まで吹き飛ばすよ",
              defeat: "風向きが……変わった……"),
        Enemy(character: "氷", reading: "こおり", level: 3, color: .systemCyan,
              intro: "水に点を1つ足せば氷。冷たく、鋭く、回り続ける",
              defeat: "溶けて……しまう……。次の「剣」は自然の文字じゃない、気をつけて"),
        Enemy(character: "剣", reading: "つるぎ", level: 3, color: .systemGray,
              intro: "我は剣。自然の文字を束ね、伝説の獣たちを目覚めさせた者の刃なり",
              defeat: "見事……。だが獣たちはもう目覚めた。この先は伝説の領域だ"),
        // 第4章 伝説の獣
        Enemy(character: "鬼", reading: "おに", level: 4, color: .systemPurple,
              intro: "ガハハ！　鬼の金棒ならぬ、鬼の回転を食らえ！",
              defeat: "鬼に金棒……持ってくればよかった……"),
        Enemy(character: "龍", reading: "りゅう", level: 4, color: .systemRed,
              intro: "十六画の体に宿るは龍の魂。天を舞う回転、見せてやろう",
              defeat: "この龍が……地に落ちるとは……"),
        Enemy(character: "虎", reading: "とら", level: 4, color: .systemOrange,
              intro: "龍虎相打つ！　龍を倒したなら、次はこの虎が相手だ！",
              defeat: "虎の威を借るまでもなかったか……完敗だ"),
        Enemy(character: "鷹", reading: "たか", level: 4, color: .systemBrown,
              intro: "空から獲物を狙う鷹の目からは、逃げられない",
              defeat: "能ある鷹が……爪を隠しすぎた……"),
        Enemy(character: "嵐", reading: "あらし", level: 4, color: .systemIndigo,
              intro: "山に風が吹けば嵐となる。すべてを巻き込んで吹き飛ばす！",
              defeat: "嵐が過ぎ去った……。覇王の城への道が開かれたぞ"),
        // 第5章 覇王の城
        Enemy(character: "魔", reading: "ま", level: 5, color: .systemPurple,
              intro: "ここは覇王の城。門番の魔が、通すわけにはいかないねぇ",
              defeat: "魔が差した……ってやつかねぇ……"),
        Enemy(character: "轟", reading: "ごう", level: 5, color: .systemRed,
              intro: "車が3つ！　ゴウゴウと轟く回転で、粉々にしてやる！",
              defeat: "エンジン……停止……"),
        Enemy(character: "鬱", reading: "うつ", level: 5, color: .systemIndigo,
              intro: "二十九画……書けるものなら書いてみろ。この複雑さこそ最強の証……",
              defeat: "画数の多さだけでは……勝てなかった……"),
        Enemy(character: "爆", reading: "ばく", level: 5, color: .systemOrange,
              intro: "覇王様の前に、ドカンと一発！　爆発的な回転を見せてやる！",
              defeat: "ふ、不発……。覇王様、あとは頼みます……"),
        Enemy(character: "覇", reading: "は", level: 5, color: .systemYellow,
              intro: "よくぞここまで来た、フォトブレーダーよ。文字たちを解き放ったのはこの覇だ。辞書の頂点に立つ力、その身で味わうがいい！",
              defeat: "写真から生まれたコマに……覇道を阻まれるとは……"),
    ]

    private static let defeatedKey = "defeatedEnemies"
    private static let bestStreakKey = "randomBestStreak"

    private(set) var defeated: Set<String>
    /// ランダム連戦の最高連勝数
    private(set) var bestStreak: Int

    @ObservationIgnored private var cache: [String: (blade: Blade, image: UIImage)] = [:]

    init() {
        defeated = Set(UserDefaults.standard.stringArray(forKey: Self.defeatedKey) ?? [])
        bestStreak = UserDefaults.standard.integer(forKey: Self.bestStreakKey)
    }

    // MARK: - ランダム連戦

    /// 連勝数に応じた敵のレベル（5連勝ごとに上がる）
    static func randomLevel(forStreak streak: Int) -> Int {
        min(5, 1 + streak / 5)
    }

    func randomEnemy(level: Int) -> Enemy {
        let colors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemMint,
                                 .systemTeal, .systemCyan, .systemBlue, .systemIndigo, .systemPurple, .systemPink]
        // 端末によっては描けない文字（絵文字フォントが無い等）があるので、描けたものだけ採用する
        for _ in 0..<20 {
            let (character, isEmoji) = RandomCharacterPool.random()
            let enemy = Enemy(character: character, reading: "", level: level, color: colors.randomElement()!, isEmoji: isEmoji, isRandom: true)
            if BladeImageProcessor.hasVisibleContent(image(for: enemy)) {
                return enemy
            }
        }
        let fallback = Self.kanjiEnemies.randomElement()!
        return Enemy(character: fallback.character, reading: fallback.reading, level: level, color: fallback.color, isRandom: true)
    }

    func recordStreak(_ streak: Int) {
        guard streak > bestStreak else { return }
        bestStreak = streak
        UserDefaults.standard.set(streak, forKey: Self.bestStreakKey)
    }

    func isDefeated(_ enemy: Enemy) -> Bool {
        defeated.contains(enemy.id)
    }

    func markDefeated(bladeID: UUID) {
        guard let enemy = Self.enemy(forBladeID: bladeID) else { return }
        defeated.insert(enemy.id)
        UserDefaults.standard.set(Array(defeated), forKey: Self.defeatedKey)
    }

    /// すべてのストーリーの敵
    static let allStoryEnemies: [Enemy] = StoryKind.allCases.flatMap(\.enemies)

    static func enemy(forBladeID id: UUID) -> Enemy? {
        allStoryEnemies.first { $0.bladeID == id }
    }

    /// ストーリーで次に戦う敵（全員倒していれば nil）
    func nextStoryEnemy(in story: StoryKind) -> Enemy? {
        story.enemies.first { !isDefeated($0) }
    }

    /// 倒した敵と次の敵だけが姿を見せる
    func isRevealed(_ enemy: Enemy) -> Bool {
        isDefeated(enemy) || enemy == nextStoryEnemy(in: enemy.story)
    }

    func isStoryCleared(_ story: StoryKind) -> Bool { nextStoryEnemy(in: story) == nil }

    var isEveryStoryCleared: Bool { StoryKind.allCases.allSatisfy(isStoryCleared) }

    func defeatedCount(in story: StoryKind) -> Int {
        story.enemies.count { isDefeated($0) }
    }

    /// すべてのストーリーで倒した数
    var storyDefeatedCount: Int {
        Self.allStoryEnemies.count { isDefeated($0) }
    }

    // MARK: - プロローグ

    /// 漢字のストーリーは追加前からある記録をそのまま使う
    private static func prologueSeenKey(_ story: StoryKind) -> String {
        story == .kanji ? "storyPrologueSeen" : "storyPrologueSeen.\(story.rawValue)"
    }

    private(set) var seenPrologues: Set<StoryKind> = Set(
        StoryKind.allCases.filter { UserDefaults.standard.bool(forKey: EnemyCatalog.prologueSeenKey($0)) }
    )

    func hasSeenPrologue(_ story: StoryKind) -> Bool {
        seenPrologues.contains(story)
    }

    func markPrologueSeen(_ story: StoryKind) {
        seenPrologues.insert(story)
        UserDefaults.standard.set(true, forKey: Self.prologueSeenKey(story))
    }

    func image(for enemy: Enemy) -> UIImage {
        resolve(enemy).image
    }

    /// 文字を描画してコマにする。形からステータスを出し、レベルに応じて底上げする
    func blade(for enemy: Enemy) -> Blade {
        resolve(enemy).blade
    }

    private func resolve(_ enemy: Enemy) -> (blade: Blade, image: UIImage) {
        let cacheKey = "\(enemy.id)-\(enemy.level)"
        if let cached = cache[cacheKey] { return cached }
        let image = enemy.isEmoji
            ? BladeImageProcessor.renderEmoji(enemy.character)
            : BladeImageProcessor.renderText(enemy.character, color: enemy.color)
        let analysis = BladeImageProcessor.analyze(image)
        let boost = 0.75 + 0.1 * Double(enemy.level)
        var stats = analysis.stats
        stats.attack = min(1, stats.attack * boost)
        stats.defense = min(1, stats.defense * boost)
        stats.stamina = min(1, stats.stamina * boost)
        stats.speed = min(1, stats.speed * boost)
        let blade = Blade(
            id: enemy.bladeID,
            name: "「\(enemy.character)」",
            imageFileName: "",
            stats: stats,
            tint: analysis.tint,
            createdAt: .distantPast,
            credit: nil
        )
        cache[cacheKey] = (blade, image)
        return (blade, image)
    }
}
