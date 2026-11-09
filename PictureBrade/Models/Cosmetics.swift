//
//  Cosmetics.swift
//  PictureBrade
//

import Foundation
import Observation

// ストーリーの報酬で手に入る「見た目」「ヒットエフェクト」「ぶつかったときの音」。
// 手に入ったかどうかは撃破記録から求めるので、報酬そのものは保存しない（追加前に進めていた分もさかのぼってもらえる）

/// コマの見た目の加工（Metal のシェーダーで描く）
enum BladeSkin: String, CaseIterable, Identifiable {
    case normal
    case gold
    case neon
    case rainbow
    case pixel
    case hologram

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal: "そのまま"
        case .gold: "黄金"
        case .neon: "ネオン"
        case .rainbow: "虹色"
        case .pixel: "ドット絵"
        case .hologram: "ホログラム"
        }
    }

    var caption: String {
        switch self {
        case .normal: "写真そのままの姿"
        case .gold: "ピカピカの金ぴかボディ"
        case .neon: "ふちが色を変えながら光る"
        case .rainbow: "虹色がぐるぐる流れる"
        case .pixel: "レトロゲーム風のドット"
        case .hologram: "未来っぽい半透明の光"
        }
    }

    var systemImage: String {
        switch self {
        case .normal: "photo"
        case .gold: "crown.fill"
        case .neon: "lightbulb.max.fill"
        case .rainbow: "rainbow"
        case .pixel: "square.grid.3x3.fill"
        case .hologram: "cube.transparent"
        }
    }
}

/// ぶつかったときに飛び散るもの
enum HitEffect: String, CaseIterable, Identifiable {
    case sparks
    case kanji
    case hiragana
    case hearts
    case stars
    case emoji

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sparks: "火花"
        case .kanji: "漢字"
        case .hiragana: "ひらがな"
        case .hearts: "ハート"
        case .stars: "キラキラ"
        case .emoji: "絵文字"
        }
    }

    var caption: String {
        switch self {
        case .sparks: "熱い金属の火花"
        case .kanji: "「斬」「撃」が飛び出す"
        case .hiragana: "あいうえお が飛び散る"
        case .hearts: "ぶつかるたびにラブラブ"
        case .stars: "星がキラキラ舞う"
        case .emoji: "🎉💥😆 で大さわぎ"
        }
    }

    /// 飛び散る文字（火花は文字を使わない）
    var glyphs: [String] {
        switch self {
        case .sparks: []
        case .kanji: ["斬", "撃", "爆", "轟", "烈", "閃", "破", "衝", "斬", "撃"]
        case .hiragana: "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん".map(String.init)
        case .hearts: ["❤️", "💖", "💕", "💗", "💘"]
        case .stars: ["⭐️", "✨", "🌟", "💫"]
        case .emoji: ["💥", "🎉", "😆", "🔥", "💯", "😵", "🤩", "👊"]
        }
    }

    /// 絵文字ではなく、色を付けて描く文字か
    var isTextGlyph: Bool { self == .kanji || self == .hiragana }

    /// 一覧に出すアイコン
    var icon: String {
        switch self {
        case .sparks: "🔥"
        case .kanji: "斬"
        case .hiragana: "あ"
        case .hearts: "💖"
        case .stars: "⭐️"
        case .emoji: "🎉"
        }
    }
}

/// ぶつかったときの音（どれも音声ファイルを使わずその場で合成する）
enum HitSound: String, CaseIterable, Identifiable {
    case metal
    case taiko
    case bell
    case pop
    case boing
    case chiptune

    var id: String { rawValue }

    var title: String {
        switch self {
        case .metal: "メタル"
        case .taiko: "太鼓"
        case .bell: "鈴"
        case .pop: "ポップ"
        case .boing: "びよーん"
        case .chiptune: "ピコピコ"
        }
    }

    var caption: String {
        switch self {
        case .metal: "ガキッ！と金属の音"
        case .taiko: "ドドン！と響く"
        case .bell: "チリーン♪と澄んだ音"
        case .pop: "ポンッ！とはじける"
        case .boing: "バネみたいにびよよん"
        case .chiptune: "レトロゲームのピコッ"
        }
    }

    var systemImage: String {
        switch self {
        case .metal: "hammer.fill"
        case .taiko: "drum.fill"
        case .bell: "bell.fill"
        case .pop: "bubbles.and.sparkles.fill"
        case .boing: "arrow.up.and.down.and.sparkles"
        case .chiptune: "gamecontroller.fill"
        }
    }
}

/// ストーリーで手に入る報酬1つ
enum Reward: Hashable, Identifiable {
    case skin(BladeSkin)
    case effect(HitEffect)
    case sound(HitSound)

    var id: String {
        switch self {
        case .skin(let skin): "skin.\(skin.rawValue)"
        case .effect(let effect): "effect.\(effect.rawValue)"
        case .sound(let sound): "sound.\(sound.rawValue)"
        }
    }

    var title: String {
        switch self {
        case .skin(let skin): skin.title
        case .effect(let effect): effect.title
        case .sound(let sound): sound.title
        }
    }

    var kindLabel: String {
        switch self {
        case .skin: "見た目"
        case .effect: "エフェクト"
        case .sound: "サウンド"
        }
    }

    /// どのストーリーの何章のボスを倒すと手に入るか（最初から持っているものは nil）
    var unlock: RewardUnlock? {
        Self.unlockTable.first { $0.reward == self }
    }

    var unlockDescription: String {
        guard let unlock else { return "はじめから" }
        return "\(unlock.story.title) 第\(unlock.chapter)章クリア"
    }

    /// 章ボスを倒すたびに1つずつもらえる（各ストーリー5章 × 3 = 15個）
    static let unlockTable: [RewardUnlock] = [
        RewardUnlock(story: .kanji, chapter: 1, reward: .sound(.taiko)),
        RewardUnlock(story: .kanji, chapter: 2, reward: .effect(.kanji)),
        RewardUnlock(story: .kanji, chapter: 3, reward: .skin(.gold)),
        RewardUnlock(story: .kanji, chapter: 4, reward: .sound(.bell)),
        RewardUnlock(story: .kanji, chapter: 5, reward: .skin(.neon)),
        RewardUnlock(story: .hiragana, chapter: 1, reward: .effect(.hiragana)),
        RewardUnlock(story: .hiragana, chapter: 2, reward: .effect(.hearts)),
        RewardUnlock(story: .hiragana, chapter: 3, reward: .sound(.pop)),
        RewardUnlock(story: .hiragana, chapter: 4, reward: .sound(.boing)),
        RewardUnlock(story: .hiragana, chapter: 5, reward: .skin(.rainbow)),
        RewardUnlock(story: .emoji, chapter: 1, reward: .effect(.stars)),
        RewardUnlock(story: .emoji, chapter: 2, reward: .skin(.pixel)),
        RewardUnlock(story: .emoji, chapter: 3, reward: .effect(.emoji)),
        RewardUnlock(story: .emoji, chapter: 4, reward: .sound(.chiptune)),
        RewardUnlock(story: .emoji, chapter: 5, reward: .skin(.hologram)),
    ]

    /// この相手を倒すと手に入る報酬（章ボス以外は空）
    static func rewards(for enemy: Enemy) -> [Reward] {
        guard !enemy.isRandom, enemy.story.isBoss(enemy) else { return [] }
        return unlockTable.filter { $0.story == enemy.story && $0.chapter == enemy.level }.map(\.reward)
    }

    static var all: [Reward] { unlockTable.map(\.reward) }
}

/// 報酬がもらえる場所（そのストーリーのその章のボスを倒すともらえる）
struct RewardUnlock {
    let story: StoryKind
    let chapter: Int
    let reward: Reward
}

/// バトルに持ち込む見た目・エフェクト・音の組み合わせ
struct Loadout: Equatable {
    var skin: BladeSkin = .normal
    var effect: HitEffect = .sparks
    var sound: HitSound = .metal
}

/// コマごとに装備中の報酬と、まだ見ていない新しい報酬を覚えておく
@Observable
final class CosmeticStore {
    private static let skinKey = "cosmetic.skin"
    private static let effectKey = "cosmetic.effect"
    private static let soundKey = "cosmetic.sound"
    private static let bladeLoadoutsKey = "cosmetic.bladeLoadouts"
    private static let seenKey = "cosmetic.seen"

    /// まだ個別に設定していないコマに使う組み合わせ（コマごとの設定ができる前の、全部共通の設定）
    private let defaultLoadout: Loadout
    /// キーはコマの ID、値は [見た目, エフェクト, サウンド]
    private var bladeLoadouts: [String: [String]]
    /// 一度装備画面で見た報酬（NEW を消すのに使う）
    private(set) var seen: Set<String>

    init() {
        let defaults = UserDefaults.standard
        defaultLoadout = Loadout(
            skin: defaults.string(forKey: Self.skinKey).flatMap(BladeSkin.init(rawValue:)) ?? .normal,
            effect: defaults.string(forKey: Self.effectKey).flatMap(HitEffect.init(rawValue:)) ?? .sparks,
            sound: defaults.string(forKey: Self.soundKey).flatMap(HitSound.init(rawValue:)) ?? .metal
        )
        bladeLoadouts = defaults.dictionary(forKey: Self.bladeLoadoutsKey) as? [String: [String]] ?? [:]
        seen = Set(defaults.stringArray(forKey: Self.seenKey) ?? [])
    }

    #if DEBUG
    private static let debugUnlockAllKey = "cosmetic.debugUnlockAll"
    /// デバッグ用：ストーリーを進めなくても、すべての報酬を手に入れたことにする（Debug ビルドのみ）
    var debugUnlockAll = UserDefaults.standard.bool(forKey: CosmeticStore.debugUnlockAllKey) {
        didSet { UserDefaults.standard.set(debugUnlockAll, forKey: Self.debugUnlockAllKey) }
    }
    #endif

    func isUnlocked(_ reward: Reward, enemies: EnemyCatalog) -> Bool {
        #if DEBUG
        if debugUnlockAll { return true }
        #endif
        guard let unlock = reward.unlock else { return true }
        guard let boss = unlock.story.enemies.last(where: { $0.level == unlock.chapter }) else { return false }
        return enemies.isDefeated(boss)
    }

    /// 手に入れたけれど、まだ装備画面で見ていない報酬
    func newRewards(enemies: EnemyCatalog) -> [Reward] {
        Reward.all.filter { isUnlocked($0, enemies: enemies) && !seen.contains($0.id) }
    }

    func markAllSeen(enemies: EnemyCatalog) {
        let unlocked = Reward.all.filter { isUnlocked($0, enemies: enemies) }.map(\.id)
        guard !seen.isSuperset(of: unlocked) else { return }
        seen.formUnion(unlocked)
        UserDefaults.standard.set(Array(seen), forKey: Self.seenKey)
    }

    func loadout(for blade: Blade) -> Loadout {
        guard let values = bladeLoadouts[blade.id.uuidString], values.count == 3 else { return defaultLoadout }
        return Loadout(
            skin: BladeSkin(rawValue: values[0]) ?? defaultLoadout.skin,
            effect: HitEffect(rawValue: values[1]) ?? defaultLoadout.effect,
            sound: HitSound(rawValue: values[2]) ?? defaultLoadout.sound
        )
    }

    /// 装備中のもののうち、手に入れていないものははじめからのものに戻す（記録を消したときなど）
    func validatedLoadout(for blade: Blade, enemies: EnemyCatalog) -> Loadout {
        var result = loadout(for: blade)
        if !isUnlocked(.skin(result.skin), enemies: enemies) { result.skin = .normal }
        if !isUnlocked(.effect(result.effect), enemies: enemies) { result.effect = .sparks }
        if !isUnlocked(.sound(result.sound), enemies: enemies) { result.sound = .metal }
        return result
    }

    func equip(_ reward: Reward, on blade: Blade) {
        var loadout = loadout(for: blade)
        switch reward {
        case .skin(let skin): loadout.skin = skin
        case .effect(let effect): loadout.effect = effect
        case .sound(let sound): loadout.sound = sound
        }
        bladeLoadouts[blade.id.uuidString] = [loadout.skin.rawValue, loadout.effect.rawValue, loadout.sound.rawValue]
        UserDefaults.standard.set(bladeLoadouts, forKey: Self.bladeLoadoutsKey)
    }

    func isEquipped(_ reward: Reward, on blade: Blade) -> Bool {
        let loadout = loadout(for: blade)
        return switch reward {
        case .skin(let skin): loadout.skin == skin
        case .effect(let effect): loadout.effect == effect
        case .sound(let sound): loadout.sound == sound
        }
    }
}
