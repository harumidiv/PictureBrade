//
//  Parts.swift
//  PictureBrade
//

import Foundation
import Observation

// コマは「バンパー（写真から作った部分）」「ボディ」「シャフト」の3つでできている。
// バンパーの能力は写真から決まり、ボディとシャフトはガチャで手に入れて装備すると能力が上乗せされる。

nonisolated enum PartKind: String, CaseIterable, Identifiable {
    case body
    case shaft

    var id: String { rawValue }

    var title: String {
        switch self {
        case .body: String(localized: "ボディ")
        case .shaft: String(localized: "シャフト")
        }
    }

    var caption: String {
        switch self {
        case .body: String(localized: "攻撃と防御が上がりやすい、コマの胴体")
        case .shaft: String(localized: "持久と機動が上がりやすい、コマの軸")
        }
    }
}

nonisolated enum PartRarity: Int, CaseIterable, Comparable {
    case normal
    case rare
    case superRare
    case ultraRare

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .normal: "N"
        case .rare: "R"
        case .superRare: "SR"
        case .ultraRare: "SSR"
        }
    }

    /// ガチャで出る確率（合計 100）
    var weight: Double {
        switch self {
        case .normal: 55
        case .rare: 30
        case .superRare: 12
        case .ultraRare: 3
        }
    }

    /// 持っているパーツがもう一度出たときに返ってくるポイント
    var duplicateRefund: Int {
        switch self {
        case .normal: 10
        case .rare: 20
        case .superRare: 50
        case .ultraRare: 100
        }
    }

    var color: RGBColor {
        switch self {
        case .normal: RGBColor(red: 0.7, green: 0.72, blue: 0.78)
        case .rare: RGBColor(red: 0.3, green: 0.65, blue: 1)
        case .superRare: RGBColor(red: 0.75, green: 0.4, blue: 1)
        case .ultraRare: RGBColor(red: 1, green: 0.8, blue: 0.25)
        }
    }
}

/// 能力の上乗せ分（マイナスもある）
nonisolated struct StatBonus: Hashable {
    var attack: Double = 0
    var defense: Double = 0
    var stamina: Double = 0
    var speed: Double = 0

    static let zero = StatBonus()

    func applied(to stats: BladeStats) -> BladeStats {
        func clamp(_ value: Double) -> Double { min(1, max(0.05, value)) }
        return BladeStats(
            attack: clamp(stats.attack + attack),
            defense: clamp(stats.defense + defense),
            stamina: clamp(stats.stamina + stamina),
            speed: clamp(stats.speed + speed)
        )
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        StatBonus(attack: lhs.attack + rhs.attack, defense: lhs.defense + rhs.defense,
                  stamina: lhs.stamina + rhs.stamina, speed: lhs.speed + rhs.speed)
    }

    /// 「攻撃+8 防御-2」のような短い説明
    var summary: String {
        let items = [(String(localized: "攻撃"), attack), (String(localized: "防御"), defense), (String(localized: "持久"), stamina), (String(localized: "機動"), speed)]
            .filter { abs($0.1) >= 0.005 }
            .map { "\($0.0)\($0.1 > 0 ? "+" : "")\(Int(($0.1 * 100).rounded()))" }
        return items.isEmpty ? String(localized: "能力の変化なし") : items.joined(separator: " ")
    }
}

/// シャフトの先端の形
nonisolated enum ShaftTip {
    /// とがった円すい（よく回り続ける）
    case sharp
    /// 平らな先端（よく動き回る）
    case flat
    /// まるい先端（どっしり安定する）
    case ball
    /// 細長い針（ほとんど動かない）
    case needle
    /// 大きく平らな円盤（よく走るが止まりやすい）
    case wide
}

/// パーツ1つ
nonisolated struct Part: Identifiable, Hashable {
    let id: String
    let kind: PartKind
    let name: String
    let rarity: PartRarity
    let bonus: StatBonus
    let caption: String
    /// ボディの色・シャフトの色
    let color: RGBColor
    /// ボディのまわりに付くトゲの数（0 ならなし）
    var fins = 0
    /// トゲの長さ・太さの倍率
    var finLength: Float = 1
    var finWidth: Float = 1
    var tip: ShaftTip = .sharp
    /// シャフトの先端の大きさの倍率
    var tipSize: Float = 1

    /// はじめから持っている、能力の変わらないパーツ
    var isStandard: Bool { id == PartCatalog.standardBody.id || id == PartCatalog.standardShaft.id }
}

nonisolated enum PartCatalog {
    static let standardBody = Part(
        id: "body.standard", kind: .body, name: String(localized: "スタンダードボディ"), rarity: .normal, bonus: .zero,
        caption: String(localized: "写真の色をそのまま生かした、基本のボディ"), color: RGBColor(red: 0.8, green: 0.8, blue: 0.85)
    )
    static let standardShaft = Part(
        id: "shaft.standard", kind: .shaft, name: String(localized: "スタンダードシャフト"), rarity: .normal, bonus: .zero,
        caption: String(localized: "クセのない、基本のシャフト"), color: RGBColor(red: 0.9, green: 0.9, blue: 0.92)
    )

    static let bodies: [Part] = [
        standardBody,
        Part(id: "body.light", kind: .body, name: String(localized: "ライトボディ"), rarity: .normal,
             bonus: StatBonus(speed: 0.05), caption: String(localized: "軽くて素早く動ける"),
             color: RGBColor(red: 0.55, green: 0.85, blue: 0.95)),
        Part(id: "body.heavy", kind: .body, name: String(localized: "ヘビーボディ"), rarity: .normal,
             bonus: StatBonus(defense: 0.06, speed: -0.02), caption: String(localized: "重くて押し出されにくい"),
             color: RGBColor(red: 0.45, green: 0.45, blue: 0.5)),
        Part(id: "body.round", kind: .body, name: String(localized: "ラウンドボディ"), rarity: .normal,
             bonus: StatBonus(stamina: 0.05), caption: String(localized: "まるい形で回転が長持ち"),
             color: RGBColor(red: 0.5, green: 0.85, blue: 0.5)),
        Part(id: "body.blade", kind: .body, name: String(localized: "ブレードボディ"), rarity: .rare,
             bonus: StatBonus(attack: 0.08), caption: String(localized: "3枚の刃で相手を弾き飛ばす"),
             color: RGBColor(red: 0.95, green: 0.35, blue: 0.3), fins: 3),
        Part(id: "body.shield", kind: .body, name: String(localized: "シールドボディ"), rarity: .rare,
             bonus: StatBonus(defense: 0.08), caption: String(localized: "分厚い盾で攻撃を受け止める"),
             color: RGBColor(red: 0.3, green: 0.5, blue: 0.95)),
        Part(id: "body.wing", kind: .body, name: String(localized: "ウィングボディ"), rarity: .rare,
             bonus: StatBonus(defense: -0.02, speed: 0.09), caption: String(localized: "4枚の翼で風に乗る"),
             color: RGBColor(red: 0.95, green: 0.95, blue: 0.6), fins: 4),
        Part(id: "body.dragon", kind: .body, name: String(localized: "ドラゴンボディ"), rarity: .superRare,
             bonus: StatBonus(attack: 0.12, defense: 0.04), caption: String(localized: "竜の爪のような6本のトゲ"),
             color: RGBColor(red: 0.2, green: 0.75, blue: 0.4), fins: 6),
        Part(id: "body.fortress", kind: .body, name: String(localized: "フォートレスボディ"), rarity: .superRare,
             bonus: StatBonus(defense: 0.14, speed: -0.04), caption: String(localized: "城のように動かない鉄壁"),
             color: RGBColor(red: 0.6, green: 0.5, blue: 0.4), fins: 8),
        Part(id: "body.cyclone", kind: .body, name: String(localized: "サイクロンボディ"), rarity: .superRare,
             bonus: StatBonus(attack: 0.05, speed: 0.1), caption: String(localized: "竜巻のように駆け回る"),
             color: RGBColor(red: 0.4, green: 0.95, blue: 0.85), fins: 5),
        Part(id: "body.overlord", kind: .body, name: String(localized: "オーバーロードボディ"), rarity: .ultraRare,
             bonus: StatBonus(attack: 0.16, defense: 0.08, stamina: -0.03), caption: String(localized: "すべてをなぎ倒す覇王の鎧"),
             color: RGBColor(red: 0.6, green: 0.2, blue: 0.85), fins: 6),
        Part(id: "body.eternal", kind: .body, name: String(localized: "エターナルボディ"), rarity: .ultraRare,
             bonus: StatBonus(defense: 0.06, stamina: 0.14), caption: String(localized: "永遠に回り続ける黄金の輪"),
             color: RGBColor(red: 1, green: 0.8, blue: 0.25), fins: 12),
        // ここから下は追加分（N）
        body("pebble", String(localized: "ペブルボディ"), .normal, def: 0.04, sta: 0.01, String(localized: "小石のようにかたい"), 0x8C8070),
        body("leaf", String(localized: "リーフボディ"), .normal, sta: 0.02, spd: 0.03, String(localized: "葉っぱのように軽やか"), 0x5FBF4F, fins: 3, length: 0.7),
        body("flame", String(localized: "フレイムボディ"), .normal, atk: 0.05, String(localized: "小さな炎がゆらめく"), 0xF2603A, fins: 3, length: 0.7),
        body("aqua", String(localized: "アクアボディ"), .normal, sta: 0.04, spd: 0.01, String(localized: "水のようになめらか"), 0x3FC8E8),
        body("sand", String(localized: "サンドボディ"), .normal, def: 0.03, sta: 0.02, String(localized: "砂のようにしっとり重い"), 0xD9BE85),
        body("thunder", String(localized: "サンダーボディ"), .normal, atk: 0.03, spd: 0.03, String(localized: "細い稲妻のトゲ"), 0xF5D93A, fins: 4, width: 0.6),
        body("frost", String(localized: "フロストボディ"), .normal, def: 0.04, spd: 0.01, String(localized: "霜のような短いトゲ"), 0xBDE6FA, fins: 6, length: 0.6),
        body("petal", String(localized: "ペタルボディ"), .normal, sta: 0.03, spd: 0.02, String(localized: "花びらのような5枚の羽"), 0xF5A3C7, fins: 5, length: 0.7, width: 1.4),
        body("iron", String(localized: "アイアンボディ"), .normal, def: 0.06, spd: -0.01, String(localized: "ずっしり重い鉄のボディ"), 0x6E7480),
        body("cloud", String(localized: "クラウドボディ"), .normal, def: -0.01, spd: 0.04, String(localized: "雲のようにふわふわ"), 0xF2F4FA),
        body("ember", String(localized: "エンバーボディ"), .normal, atk: 0.04, sta: 0.01, String(localized: "くすぶる残り火"), 0xC2521F),
        body("moss", String(localized: "モスボディ"), .normal, sta: 0.05, spd: -0.01, String(localized: "苔むした粘り強いボディ"), 0x4A7A3A),
        body("coin", String(localized: "コインボディ"), .normal, def: 0.02, sta: 0.03, String(localized: "ふちがギザギザのコイン"), 0xC9A646, fins: 12, length: 0.4, width: 0.6),
        body("bubble", String(localized: "バブルボディ"), .normal, sta: 0.02, spd: 0.03, String(localized: "シャボン玉のように軽い"), 0xA8D8FF),
        // R
        body("saw", String(localized: "ソーボディ"), .rare, atk: 0.09, def: -0.01, String(localized: "のこぎりのような8枚刃"), 0xC0C6CF, fins: 8, length: 0.6, width: 0.6),
        body("turtle", String(localized: "タートルボディ"), .rare, def: 0.09, spd: -0.01, String(localized: "甲羅のように分厚い"), 0x6B8E4E, fins: 6, length: 0.5, width: 1.6),
        body("hawk", String(localized: "ホークボディ"), .rare, atk: 0.02, spd: 0.07, String(localized: "大きく広げた2枚の翼"), 0x9C6B3F, fins: 2, length: 1.4),
        body("crystal", String(localized: "クリスタルボディ"), .rare, def: 0.02, sta: 0.07, String(localized: "結晶のように透き通る"), 0xC9A8F0, fins: 6, length: 0.8),
        body("magma", String(localized: "マグマボディ"), .rare, atk: 0.07, def: 0.03, spd: -0.02, String(localized: "煮えたぎる溶岩の塊"), 0xB8231B, fins: 4, width: 1.5),
        body("wave", String(localized: "ウェーブボディ"), .rare, sta: 0.05, spd: 0.04, String(localized: "波のようにうねる3本の刃"), 0x2F7FE0, fins: 3, length: 1.2, width: 0.6),
        body("star", String(localized: "スターボディ"), .rare, atk: 0.04, spd: 0.05, String(localized: "5つの角をもつ星"), 0xFFD84D, fins: 5),
        body("ninja", String(localized: "ニンジャボディ"), .rare, def: -0.01, spd: 0.08, String(localized: "手裏剣のような4枚刃"), 0x3B2F5C, fins: 4, length: 1.1, width: 0.6),
        body("samurai", String(localized: "サムライボディ"), .rare, atk: 0.08, sta: 0.01, String(localized: "2本の刀を構える"), 0xB0202E, fins: 2, length: 1.4, width: 0.7),
        body("panda", String(localized: "パンダボディ"), .rare, def: 0.06, sta: 0.03, String(localized: "白と黒のまんまるボディ"), 0xF0F0F0),
        body("rocket", String(localized: "ロケットボディ"), .rare, sta: -0.02, spd: 0.09, String(localized: "3枚の尾翼で一気に加速"), 0xF08A24, fins: 3, length: 0.9),
        body("mirror", String(localized: "ミラーボディ"), .rare, def: 0.05, sta: 0.04, String(localized: "鏡のようにピカピカ"), 0xDDE3EA),
        // SR
        body("phoenix", String(localized: "フェニックスボディ"), .superRare, atk: 0.08, sta: 0.08, String(localized: "よみがえる不死鳥の翼"), 0xFF7A2E, fins: 6, length: 1.3),
        body("tiger", String(localized: "タイガーボディ"), .superRare, atk: 0.13, def: -0.02, spd: 0.03, String(localized: "するどい虎の牙"), 0xF09A1E, fins: 4, length: 1.1),
        body("leviathan", String(localized: "リヴァイアサンボディ"), .superRare, def: 0.10, sta: 0.06, spd: -0.02, String(localized: "深海の竜のうろこ"), 0x1E3F8F, fins: 8, length: 0.8, width: 1.2),
        body("meteor", String(localized: "メテオボディ"), .superRare, atk: 0.14, sta: -0.02, String(localized: "落ちてくる隕石のかけら"), 0x8E2416, fins: 3, width: 1.7),
        body("thunderGod", String(localized: "雷神ボディ"), .superRare, atk: 0.07, spd: 0.09, String(localized: "雷神の太鼓のような6本の稲妻"), 0xFFE14A, fins: 6, length: 1.2, width: 0.5),
        body("windGod", String(localized: "風神ボディ"), .superRare, def: -0.02, sta: 0.04, spd: 0.12, String(localized: "風神の袋から吹き出す風"), 0x6FE0C0, fins: 5, length: 1.3, width: 0.5),
        body("golem", String(localized: "ゴーレムボディ"), .superRare, def: 0.15, spd: -0.03, String(localized: "岩の巨人の拳"), 0x857A6A, fins: 4, length: 0.6, width: 1.8),
        body("unicorn", String(localized: "ユニコーンボディ"), .superRare, sta: 0.10, spd: 0.05, String(localized: "1本の角が光る"), 0xF7C6E6, fins: 1, length: 1.6),
        // SSR
        body("galaxy", String(localized: "ギャラクシーボディ"), .ultraRare, atk: 0.08, def: 0.06, sta: 0.06, spd: 0.04, String(localized: "銀河を閉じこめた究極のボディ"), 0x4B2A8F, fins: 8, length: 1.1),
        body("zeus", String(localized: "ゼウスボディ"), .ultraRare, atk: 0.20, def: 0.02, spd: -0.02, String(localized: "神々の王の雷"), 0xFFD23F, fins: 6, length: 1.5, width: 0.8),
        body("abyss", String(localized: "アビスボディ"), .ultraRare, def: 0.18, sta: 0.06, spd: -0.03, String(localized: "底の見えない深淵"), 0x141B3D, fins: 10, length: 0.5, width: 1.3),
        body("rainbowWing", String(localized: "レインボーウィングボディ"), .ultraRare, def: -0.02, sta: 0.08, spd: 0.14, String(localized: "虹色に輝く6枚の翼"), 0xFF9EE0, fins: 6, length: 1.4, width: 0.6),
    ]

    static let shafts: [Part] = [
        standardShaft,
        Part(id: "shaft.sharp", kind: .shaft, name: String(localized: "シャープシャフト"), rarity: .normal,
             bonus: StatBonus(stamina: 0.05), caption: String(localized: "とがった先端で長く回る"),
             color: RGBColor(red: 0.75, green: 0.8, blue: 0.9)),
        Part(id: "shaft.flat", kind: .shaft, name: String(localized: "フラットシャフト"), rarity: .normal,
             bonus: StatBonus(speed: 0.05), caption: String(localized: "平らな先端でよく走る"),
             color: RGBColor(red: 0.95, green: 0.6, blue: 0.3), tip: .flat),
        Part(id: "shaft.ball", kind: .shaft, name: String(localized: "ボールシャフト"), rarity: .rare,
             bonus: StatBonus(defense: 0.05, stamina: 0.04), caption: String(localized: "まるい先端でどっしり"),
             color: RGBColor(red: 0.4, green: 0.7, blue: 1), tip: .ball),
        Part(id: "shaft.rubber", kind: .shaft, name: String(localized: "ラバーシャフト"), rarity: .rare,
             bonus: StatBonus(attack: 0.07, stamina: -0.02), caption: String(localized: "ゴムの先端で床をつかんで突撃"),
             color: RGBColor(red: 0.2, green: 0.2, blue: 0.25), tip: .flat),
        Part(id: "shaft.needle", kind: .shaft, name: String(localized: "ニードルシャフト"), rarity: .rare,
             bonus: StatBonus(stamina: 0.08, speed: -0.02), caption: String(localized: "針のような先端で粘る"),
             color: RGBColor(red: 0.85, green: 0.85, blue: 0.95), tip: .needle),
        Part(id: "shaft.jet", kind: .shaft, name: String(localized: "ジェットシャフト"), rarity: .superRare,
             bonus: StatBonus(speed: 0.12), caption: String(localized: "ジェットのような加速"),
             color: RGBColor(red: 1, green: 0.4, blue: 0.3), tip: .flat),
        Part(id: "shaft.grip", kind: .shaft, name: String(localized: "グリップシャフト"), rarity: .superRare,
             bonus: StatBonus(attack: 0.08, speed: 0.06), caption: String(localized: "床をがっちりつかんで攻める"),
             color: RGBColor(red: 0.3, green: 0.85, blue: 0.4), tip: .ball),
        Part(id: "shaft.mirage", kind: .shaft, name: String(localized: "ミラージュシャフト"), rarity: .ultraRare,
             bonus: StatBonus(stamina: 0.1, speed: 0.1), caption: String(localized: "残像が見えるほど速く、長く回る"),
             color: RGBColor(red: 0.85, green: 0.5, blue: 1), tip: .sharp),
        Part(id: "shaft.zeroGravity", kind: .shaft, name: String(localized: "ゼログラビティシャフト"), rarity: .ultraRare,
             bonus: StatBonus(defense: 0.03, stamina: 0.16), caption: String(localized: "重さを感じさせない無重力の軸"),
             color: RGBColor(red: 1, green: 0.85, blue: 0.35), tip: .needle),
        // ここから下は追加分（N）
        shaft("mini", String(localized: "ミニシャフト"), .normal, sta: 0.01, spd: 0.03, String(localized: "小さな先端で小回りがきく"), 0xCFD3DA, size: 0.7),
        shaft("wood", String(localized: "ウッドシャフト"), .normal, sta: 0.04, String(localized: "木でできたやさしい軸"), 0x9C6B3F),
        shaft("stone", String(localized: "ストーンシャフト"), .normal, def: 0.04, String(localized: "石のようにすわりがいい"), 0x8A8A8A, tip: .ball, size: 0.8),
        shaft("copper", String(localized: "カッパーシャフト"), .normal, def: 0.02, sta: 0.02, String(localized: "銅のあたたかい輝き"), 0xC0703A),
        shaft("plastic", String(localized: "プラスチックシャフト"), .normal, spd: 0.04, String(localized: "軽くてよくすべる"), 0x3A8CF0, tip: .flat),
        shaft("cork", String(localized: "コルクシャフト"), .normal, def: 0.03, sta: 0.02, String(localized: "コルクのクッション"), 0xC9A170, tip: .flat, size: 1.1),
        shaft("pin", String(localized: "ピンシャフト"), .normal, sta: 0.05, spd: -0.01, String(localized: "まち針のような細い先端"), 0xD9DDE5, tip: .needle, size: 0.8),
        shaft("bead", String(localized: "ビーズシャフト"), .normal, sta: 0.03, spd: 0.02, String(localized: "小さなビーズ玉"), 0xF5A3C7, tip: .ball, size: 0.7),
        shaft("wideFlat", String(localized: "ワイドフラットシャフト"), .normal, sta: -0.01, spd: 0.06, String(localized: "大きな平らな先端で走り回る"), 0xF08A24, tip: .wide),
        shaft("short", String(localized: "ショートシャフト"), .normal, def: 0.03, spd: 0.02, String(localized: "背の低いがっしりした軸"), 0x55595F, tip: .flat, size: 0.8),
        shaft("glass", String(localized: "グラスシャフト"), .normal, sta: 0.04, spd: 0.01, String(localized: "ガラスのように透き通る"), 0xA8E6F0),
        shaft("bamboo", String(localized: "バンブーシャフト"), .normal, sta: 0.02, spd: 0.03, String(localized: "竹のようにしなやか"), 0x7DBF4F, tip: .flat),
        shaft("marble", String(localized: "マーブルシャフト"), .normal, def: 0.02, sta: 0.03, String(localized: "ビー玉のような先端"), 0xF2F2F2, tip: .ball),
        shaft("thorn", String(localized: "ソーンシャフト"), .normal, atk: 0.04, sta: 0.01, String(localized: "いばらのとげ"), 0x3E6B35, tip: .needle),
        shaft("brass", String(localized: "ブラスシャフト"), .normal, def: 0.04, sta: 0.01, String(localized: "真ちゅうの重たい軸"), 0xC9A646, size: 1.1),
        // R
        shaft("drill", String(localized: "ドリルシャフト"), .rare, atk: 0.06, spd: 0.02, String(localized: "床をけずるドリル"), 0xB8BEC8, size: 1.3),
        shaft("spring", String(localized: "スプリングシャフト"), .rare, atk: 0.04, def: 0.04, String(localized: "バネで跳ね返す"), 0xA6E03A, tip: .ball),
        shaft("magnet", String(localized: "マグネットシャフト"), .rare, def: 0.07, String(localized: "床に吸いつく磁石"), 0xE03A3A, tip: .ball, size: 1.1),
        shaft("ice", String(localized: "アイスシャフト"), .rare, sta: 0.02, spd: 0.06, String(localized: "氷の上をすべるように走る"), 0xBDE6FA, tip: .flat),
        shaft("ruby", String(localized: "ルビーシャフト"), .rare, sta: 0.07, String(localized: "ルビーの先端で長く回る"), 0xD11F4F),
        shaft("sapphire", String(localized: "サファイアシャフト"), .rare, def: 0.03, sta: 0.05, String(localized: "サファイアの先端"), 0x2F5FD0),
        shaft("racing", String(localized: "レーシングシャフト"), .rare, sta: -0.01, spd: 0.09, String(localized: "サーキットを駆けるタイヤ"), 0xF5D02A, tip: .wide),
        shaft("hammer", String(localized: "ハンマーシャフト"), .rare, atk: 0.07, spd: -0.01, String(localized: "大きな玉で体当たり"), 0x45484F, tip: .ball, size: 1.3),
        shaft("feather", String(localized: "フェザーシャフト"), .rare, sta: 0.03, spd: 0.05, String(localized: "羽のように軽い針"), 0xF5F5F0, tip: .needle),
        shaft("tank", String(localized: "タンクシャフト"), .rare, def: 0.08, spd: -0.02, String(localized: "戦車のように動じない"), 0x6B7340, tip: .wide),
        shaft("gear", String(localized: "ギアシャフト"), .rare, atk: 0.03, spd: 0.05, String(localized: "歯車で床をかむ"), 0xB0803A, tip: .flat),
        shaft("pearl", String(localized: "パールシャフト"), .rare, def: 0.04, sta: 0.04, String(localized: "真珠のような先端"), 0xF0EBE0, tip: .ball, size: 0.9),
        // SR
        shaft("turbo", String(localized: "ターボシャフト"), .superRare, atk: 0.03, spd: 0.11, String(localized: "ターボで一気に加速"), 0xE0302A, tip: .wide),
        shaft("diamond", String(localized: "ダイヤシャフト"), .superRare, sta: 0.12, String(localized: "ダイヤモンドの先端で回り続ける"), 0xDFF6FF),
        shaft("titan", String(localized: "タイタンシャフト"), .superRare, def: 0.12, sta: 0.02, String(localized: "巨人のような大玉"), 0x8A9099, tip: .ball, size: 1.3),
        shaft("blaze", String(localized: "ブレイズシャフト"), .superRare, atk: 0.10, spd: 0.04, String(localized: "燃える車輪"), 0xFF7A1A, tip: .flat),
        shaft("shadow", String(localized: "シャドウシャフト"), .superRare, sta: 0.06, spd: 0.08, String(localized: "影のように音もなく動く"), 0x22202E, tip: .needle),
        shaft("storm", String(localized: "ストームシャフト"), .superRare, atk: 0.06, spd: 0.08, String(localized: "嵐を呼ぶ先端"), 0x7A4FD0, size: 1.2),
        shaft("anchor", String(localized: "アンカーシャフト"), .superRare, def: 0.10, sta: 0.05, spd: -0.02, String(localized: "いかりのように動かない"), 0x23356B, tip: .wide),
        shaft("lightning", String(localized: "ライトニングシャフト"), .superRare, def: -0.02, spd: 0.13, String(localized: "稲妻のような速さ"), 0xFFE14A, tip: .needle),
        shaft("crystal", String(localized: "クリスタルシャフト"), .superRare, def: 0.04, sta: 0.09, String(localized: "結晶の先端が光る"), 0xC9A8F0),
        // SSR
        shaft("infinity", String(localized: "インフィニティシャフト"), .ultraRare, sta: 0.14, spd: 0.06, String(localized: "いつまでも止まらない無限の軸"), 0xFF9EE0, size: 1.1),
        shaft("meteor", String(localized: "メテオシャフト"), .ultraRare, atk: 0.14, spd: 0.06, String(localized: "隕石のように突っこむ"), 0x9E2416, tip: .ball, size: 1.2),
        shaft("aegis", String(localized: "イージスシャフト"), .ultraRare, def: 0.16, sta: 0.04, String(localized: "すべてをはじく神の盾"), 0xFFD23F, tip: .wide),
        shaft("comet", String(localized: "コメットシャフト"), .ultraRare, sta: 0.02, spd: 0.18, String(localized: "ほうき星のように駆けぬける"), 0x8FD8FF, tip: .needle),
    ]

    // MARK: 定義を短く書くための関数

    private static func body(
        _ id: String, _ name: String, _ rarity: PartRarity,
        atk: Double = 0, def: Double = 0, sta: Double = 0, spd: Double = 0,
        _ caption: String, _ hex: Int, fins: Int = 0, length: Float = 1, width: Float = 1
    ) -> Part {
        Part(id: "body.\(id)", kind: .body, name: name, rarity: rarity,
             bonus: StatBonus(attack: atk, defense: def, stamina: sta, speed: spd), caption: caption,
             color: RGBColor(hex: hex), fins: fins, finLength: length, finWidth: width)
    }

    private static func shaft(
        _ id: String, _ name: String, _ rarity: PartRarity,
        atk: Double = 0, def: Double = 0, sta: Double = 0, spd: Double = 0,
        _ caption: String, _ hex: Int, tip: ShaftTip = .sharp, size: Float = 1
    ) -> Part {
        Part(id: "shaft.\(id)", kind: .shaft, name: name, rarity: rarity,
             bonus: StatBonus(attack: atk, defense: def, stamina: sta, speed: spd), caption: caption,
             color: RGBColor(hex: hex), tip: tip, tipSize: size)
    }

    static func parts(_ kind: PartKind) -> [Part] {
        switch kind {
        case .body: bodies
        case .shaft: shafts
        }
    }

    static func standard(_ kind: PartKind) -> Part {
        switch kind {
        case .body: standardBody
        case .shaft: standardShaft
        }
    }

    static func part(id: String) -> Part? {
        (bodies + shafts).first { $0.id == id }
    }
}

/// コマに付けているボディとシャフト
nonisolated struct Equipment: Hashable {
    var body: Part = PartCatalog.standardBody
    var shaft: Part = PartCatalog.standardShaft

    var bonus: StatBonus { body.bonus + shaft.bonus }

    subscript(kind: PartKind) -> Part {
        get {
            switch kind {
            case .body: body
            case .shaft: shaft
            }
        }
        set {
            switch kind {
            case .body: body = newValue
            case .shaft: shaft = newValue
            }
        }
    }
}

/// ガチャで1つ引いた結果
struct GachaResult: Identifiable {
    let id = UUID()
    let part: Part
    /// 初めて手に入れたか（持っていたらポイントが返ってくる）
    let isNew: Bool
    var refund: Int { isNew ? 0 : part.rarity.duplicateRefund }
}

/// バトルでたまるポイント・手に入れたパーツ・コマごとの装備を覚えておく
@Observable
final class PartsStore {
    static let singleCost = 100
    static let tenCost = 900
    /// はじめて遊ぶときにもらえるポイント（すぐにガチャを試せるように）
    static let welcomePoints = 300

    private static let pointsKey = "parts.points"
    private static let ownedKey = "parts.owned"
    private static let equipmentKey = "parts.equipment"

    private(set) var points: Int
    private(set) var owned: Set<String>
    /// キーはコマの ID、値は [ボディの ID, シャフトの ID]
    private var equipmentIDs: [String: [String]]

    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Self.pointsKey) == nil {
            defaults.set(Self.welcomePoints, forKey: Self.pointsKey)
        }
        points = defaults.integer(forKey: Self.pointsKey)
        owned = Set(defaults.stringArray(forKey: Self.ownedKey) ?? [])
            .union([PartCatalog.standardBody.id, PartCatalog.standardShaft.id])
        equipmentIDs = defaults.dictionary(forKey: Self.equipmentKey) as? [String: [String]] ?? [:]
    }

    // MARK: - ポイント

    func addPoints(_ amount: Int) {
        guard amount > 0 else { return }
        points += amount
        UserDefaults.standard.set(points, forKey: Self.pointsKey)
    }

    private func spend(_ amount: Int) -> Bool {
        guard points >= amount else { return false }
        points -= amount
        UserDefaults.standard.set(points, forKey: Self.pointsKey)
        return true
    }

    /// バトル1試合でもらえるポイント
    static func battleReward(mode: BattleGame.Mode, won: Bool, stars: Int, winStreak: Int, firstClear: Bool) -> Int {
        switch (mode, won) {
        case (.story, true): 20 + 10 * stars + (firstClear ? 30 : 0)
        case (.story, false): 5
        case (.endless, true): 10 + 2 * min(winStreak, 20)
        case (.endless, false): 5
        }
    }

    // MARK: - ガチャ

    func isOwned(_ part: Part) -> Bool { owned.contains(part.id) }

    func ownedCount(_ kind: PartKind) -> Int {
        PartCatalog.parts(kind).count { isOwned($0) }
    }

    /// count 回引く（10連は SR 以上が1つ確定）。ポイントが足りなければ nil。
    /// free なら（広告を見たときなど）ポイントを使わない
    func draw(_ kind: PartKind, count: Int, free: Bool = false) -> [GachaResult]? {
        let cost = count >= 10 ? Self.tenCost : Self.singleCost * count
        guard free || spend(cost) else { return nil }
        var parts = (0..<count).map { _ in Self.randomPart(kind, minimum: .normal) }
        if count >= 10, !parts.contains(where: { $0.rarity >= .superRare }) {
            parts[parts.count - 1] = Self.randomPart(kind, minimum: .superRare)
        }
        var results: [GachaResult] = []
        for part in parts {
            let isNew = !owned.contains(part.id)
            owned.insert(part.id)
            results.append(GachaResult(part: part, isNew: isNew))
        }
        UserDefaults.standard.set(Array(owned), forKey: Self.ownedKey)
        addPoints(results.reduce(0) { $0 + $1.refund })
        return results
    }

    private static func randomPart(_ kind: PartKind, minimum: PartRarity) -> Part {
        let rarities = PartRarity.allCases.filter { $0 >= minimum }
        var roll = Double.random(in: 0..<rarities.reduce(0) { $0 + $1.weight })
        var rarity = rarities.last!
        for candidate in rarities {
            if roll < candidate.weight {
                rarity = candidate
                break
            }
            roll -= candidate.weight
        }
        // はじめから持っている基本のパーツはガチャからは出さない
        let pool = PartCatalog.parts(kind).filter { $0.rarity == rarity && !$0.isStandard }
        return pool.randomElement() ?? PartCatalog.parts(kind).last!
    }

    // MARK: - 装備

    func equipment(for blade: Blade) -> Equipment {
        guard let ids = equipmentIDs[blade.id.uuidString], ids.count == 2 else { return Equipment() }
        var equipment = Equipment()
        if let body = PartCatalog.part(id: ids[0]), isOwned(body) { equipment.body = body }
        if let shaft = PartCatalog.part(id: ids[1]), isOwned(shaft) { equipment.shaft = shaft }
        return equipment
    }

    func equip(_ part: Part, on blade: Blade) {
        guard isOwned(part) else { return }
        var equipment = equipment(for: blade)
        equipment[part.kind] = part
        equipmentIDs[blade.id.uuidString] = [equipment.body.id, equipment.shaft.id]
        UserDefaults.standard.set(equipmentIDs, forKey: Self.equipmentKey)
    }

    /// 装備の能力を足したコマ（バトルにはこれを使う）
    func equipped(_ blade: Blade) -> Blade {
        var result = blade
        result.stats = equipment(for: blade).bonus.applied(to: blade.stats)
        return result
    }

    #if DEBUG
    func debugAddPoints() { addPoints(1000) }
    #endif
}

extension RGBColor {
    /// 0xRRGGBB の形で色を作る
    nonisolated init(hex: Int) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
