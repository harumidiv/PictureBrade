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
        case .body: "ボディ"
        case .shaft: "シャフト"
        }
    }

    var caption: String {
        switch self {
        case .body: "攻撃と防御が上がりやすい、コマの胴体"
        case .shaft: "持久と機動が上がりやすい、コマの軸"
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
        let items = [("攻撃", attack), ("防御", defense), ("持久", stamina), ("機動", speed)]
            .filter { abs($0.1) >= 0.005 }
            .map { "\($0.0)\($0.1 > 0 ? "+" : "")\(Int(($0.1 * 100).rounded()))" }
        return items.isEmpty ? "能力の変化なし" : items.joined(separator: " ")
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
        id: "body.standard", kind: .body, name: "スタンダードボディ", rarity: .normal, bonus: .zero,
        caption: "写真の色をそのまま生かした、基本のボディ", color: RGBColor(red: 0.8, green: 0.8, blue: 0.85)
    )
    static let standardShaft = Part(
        id: "shaft.standard", kind: .shaft, name: "スタンダードシャフト", rarity: .normal, bonus: .zero,
        caption: "クセのない、基本のシャフト", color: RGBColor(red: 0.9, green: 0.9, blue: 0.92)
    )

    static let bodies: [Part] = [
        standardBody,
        Part(id: "body.light", kind: .body, name: "ライトボディ", rarity: .normal,
             bonus: StatBonus(speed: 0.05), caption: "軽くて素早く動ける",
             color: RGBColor(red: 0.55, green: 0.85, blue: 0.95)),
        Part(id: "body.heavy", kind: .body, name: "ヘビーボディ", rarity: .normal,
             bonus: StatBonus(defense: 0.06, speed: -0.02), caption: "重くて押し出されにくい",
             color: RGBColor(red: 0.45, green: 0.45, blue: 0.5)),
        Part(id: "body.round", kind: .body, name: "ラウンドボディ", rarity: .normal,
             bonus: StatBonus(stamina: 0.05), caption: "まるい形で回転が長持ち",
             color: RGBColor(red: 0.5, green: 0.85, blue: 0.5)),
        Part(id: "body.blade", kind: .body, name: "ブレードボディ", rarity: .rare,
             bonus: StatBonus(attack: 0.08), caption: "3枚の刃で相手を弾き飛ばす",
             color: RGBColor(red: 0.95, green: 0.35, blue: 0.3), fins: 3),
        Part(id: "body.shield", kind: .body, name: "シールドボディ", rarity: .rare,
             bonus: StatBonus(defense: 0.08), caption: "分厚い盾で攻撃を受け止める",
             color: RGBColor(red: 0.3, green: 0.5, blue: 0.95)),
        Part(id: "body.wing", kind: .body, name: "ウィングボディ", rarity: .rare,
             bonus: StatBonus(defense: -0.02, speed: 0.09), caption: "4枚の翼で風に乗る",
             color: RGBColor(red: 0.95, green: 0.95, blue: 0.6), fins: 4),
        Part(id: "body.dragon", kind: .body, name: "ドラゴンボディ", rarity: .superRare,
             bonus: StatBonus(attack: 0.12, defense: 0.04), caption: "竜の爪のような6本のトゲ",
             color: RGBColor(red: 0.2, green: 0.75, blue: 0.4), fins: 6),
        Part(id: "body.fortress", kind: .body, name: "フォートレスボディ", rarity: .superRare,
             bonus: StatBonus(defense: 0.14, speed: -0.04), caption: "城のように動かない鉄壁",
             color: RGBColor(red: 0.6, green: 0.5, blue: 0.4), fins: 8),
        Part(id: "body.cyclone", kind: .body, name: "サイクロンボディ", rarity: .superRare,
             bonus: StatBonus(attack: 0.05, speed: 0.1), caption: "竜巻のように駆け回る",
             color: RGBColor(red: 0.4, green: 0.95, blue: 0.85), fins: 5),
        Part(id: "body.overlord", kind: .body, name: "オーバーロードボディ", rarity: .ultraRare,
             bonus: StatBonus(attack: 0.16, defense: 0.08, stamina: -0.03), caption: "すべてをなぎ倒す覇王の鎧",
             color: RGBColor(red: 0.6, green: 0.2, blue: 0.85), fins: 6),
        Part(id: "body.eternal", kind: .body, name: "エターナルボディ", rarity: .ultraRare,
             bonus: StatBonus(defense: 0.06, stamina: 0.14), caption: "永遠に回り続ける黄金の輪",
             color: RGBColor(red: 1, green: 0.8, blue: 0.25), fins: 12),
        // ここから下は追加分（N）
        body("pebble", "ペブルボディ", .normal, def: 0.04, sta: 0.01, "小石のようにかたい", 0x8C8070),
        body("leaf", "リーフボディ", .normal, sta: 0.02, spd: 0.03, "葉っぱのように軽やか", 0x5FBF4F, fins: 3, length: 0.7),
        body("flame", "フレイムボディ", .normal, atk: 0.05, "小さな炎がゆらめく", 0xF2603A, fins: 3, length: 0.7),
        body("aqua", "アクアボディ", .normal, sta: 0.04, spd: 0.01, "水のようになめらか", 0x3FC8E8),
        body("sand", "サンドボディ", .normal, def: 0.03, sta: 0.02, "砂のようにしっとり重い", 0xD9BE85),
        body("thunder", "サンダーボディ", .normal, atk: 0.03, spd: 0.03, "細い稲妻のトゲ", 0xF5D93A, fins: 4, width: 0.6),
        body("frost", "フロストボディ", .normal, def: 0.04, spd: 0.01, "霜のような短いトゲ", 0xBDE6FA, fins: 6, length: 0.6),
        body("petal", "ペタルボディ", .normal, sta: 0.03, spd: 0.02, "花びらのような5枚の羽", 0xF5A3C7, fins: 5, length: 0.7, width: 1.4),
        body("iron", "アイアンボディ", .normal, def: 0.06, spd: -0.01, "ずっしり重い鉄のボディ", 0x6E7480),
        body("cloud", "クラウドボディ", .normal, def: -0.01, spd: 0.04, "雲のようにふわふわ", 0xF2F4FA),
        body("ember", "エンバーボディ", .normal, atk: 0.04, sta: 0.01, "くすぶる残り火", 0xC2521F),
        body("moss", "モスボディ", .normal, sta: 0.05, spd: -0.01, "苔むした粘り強いボディ", 0x4A7A3A),
        body("coin", "コインボディ", .normal, def: 0.02, sta: 0.03, "ふちがギザギザのコイン", 0xC9A646, fins: 12, length: 0.4, width: 0.6),
        body("bubble", "バブルボディ", .normal, sta: 0.02, spd: 0.03, "シャボン玉のように軽い", 0xA8D8FF),
        // R
        body("saw", "ソーボディ", .rare, atk: 0.09, def: -0.01, "のこぎりのような8枚刃", 0xC0C6CF, fins: 8, length: 0.6, width: 0.6),
        body("turtle", "タートルボディ", .rare, def: 0.09, spd: -0.01, "甲羅のように分厚い", 0x6B8E4E, fins: 6, length: 0.5, width: 1.6),
        body("hawk", "ホークボディ", .rare, atk: 0.02, spd: 0.07, "大きく広げた2枚の翼", 0x9C6B3F, fins: 2, length: 1.4),
        body("crystal", "クリスタルボディ", .rare, def: 0.02, sta: 0.07, "結晶のように透き通る", 0xC9A8F0, fins: 6, length: 0.8),
        body("magma", "マグマボディ", .rare, atk: 0.07, def: 0.03, spd: -0.02, "煮えたぎる溶岩の塊", 0xB8231B, fins: 4, width: 1.5),
        body("wave", "ウェーブボディ", .rare, sta: 0.05, spd: 0.04, "波のようにうねる3本の刃", 0x2F7FE0, fins: 3, length: 1.2, width: 0.6),
        body("star", "スターボディ", .rare, atk: 0.04, spd: 0.05, "5つの角をもつ星", 0xFFD84D, fins: 5),
        body("ninja", "ニンジャボディ", .rare, def: -0.01, spd: 0.08, "手裏剣のような4枚刃", 0x3B2F5C, fins: 4, length: 1.1, width: 0.6),
        body("samurai", "サムライボディ", .rare, atk: 0.08, sta: 0.01, "2本の刀を構える", 0xB0202E, fins: 2, length: 1.4, width: 0.7),
        body("panda", "パンダボディ", .rare, def: 0.06, sta: 0.03, "白と黒のまんまるボディ", 0xF0F0F0),
        body("rocket", "ロケットボディ", .rare, sta: -0.02, spd: 0.09, "3枚の尾翼で一気に加速", 0xF08A24, fins: 3, length: 0.9),
        body("mirror", "ミラーボディ", .rare, def: 0.05, sta: 0.04, "鏡のようにピカピカ", 0xDDE3EA),
        // SR
        body("phoenix", "フェニックスボディ", .superRare, atk: 0.08, sta: 0.08, "よみがえる不死鳥の翼", 0xFF7A2E, fins: 6, length: 1.3),
        body("tiger", "タイガーボディ", .superRare, atk: 0.13, def: -0.02, spd: 0.03, "するどい虎の牙", 0xF09A1E, fins: 4, length: 1.1),
        body("leviathan", "リヴァイアサンボディ", .superRare, def: 0.10, sta: 0.06, spd: -0.02, "深海の竜のうろこ", 0x1E3F8F, fins: 8, length: 0.8, width: 1.2),
        body("meteor", "メテオボディ", .superRare, atk: 0.14, sta: -0.02, "落ちてくる隕石のかけら", 0x8E2416, fins: 3, width: 1.7),
        body("thunderGod", "雷神ボディ", .superRare, atk: 0.07, spd: 0.09, "雷神の太鼓のような6本の稲妻", 0xFFE14A, fins: 6, length: 1.2, width: 0.5),
        body("windGod", "風神ボディ", .superRare, def: -0.02, sta: 0.04, spd: 0.12, "風神の袋から吹き出す風", 0x6FE0C0, fins: 5, length: 1.3, width: 0.5),
        body("golem", "ゴーレムボディ", .superRare, def: 0.15, spd: -0.03, "岩の巨人の拳", 0x857A6A, fins: 4, length: 0.6, width: 1.8),
        body("unicorn", "ユニコーンボディ", .superRare, sta: 0.10, spd: 0.05, "1本の角が光る", 0xF7C6E6, fins: 1, length: 1.6),
        // SSR
        body("galaxy", "ギャラクシーボディ", .ultraRare, atk: 0.08, def: 0.06, sta: 0.06, spd: 0.04, "銀河を閉じこめた究極のボディ", 0x4B2A8F, fins: 8, length: 1.1),
        body("zeus", "ゼウスボディ", .ultraRare, atk: 0.20, def: 0.02, spd: -0.02, "神々の王の雷", 0xFFD23F, fins: 6, length: 1.5, width: 0.8),
        body("abyss", "アビスボディ", .ultraRare, def: 0.18, sta: 0.06, spd: -0.03, "底の見えない深淵", 0x141B3D, fins: 10, length: 0.5, width: 1.3),
        body("rainbowWing", "レインボーウィングボディ", .ultraRare, def: -0.02, sta: 0.08, spd: 0.14, "虹色に輝く6枚の翼", 0xFF9EE0, fins: 6, length: 1.4, width: 0.6),
    ]

    static let shafts: [Part] = [
        standardShaft,
        Part(id: "shaft.sharp", kind: .shaft, name: "シャープシャフト", rarity: .normal,
             bonus: StatBonus(stamina: 0.05), caption: "とがった先端で長く回る",
             color: RGBColor(red: 0.75, green: 0.8, blue: 0.9)),
        Part(id: "shaft.flat", kind: .shaft, name: "フラットシャフト", rarity: .normal,
             bonus: StatBonus(speed: 0.05), caption: "平らな先端でよく走る",
             color: RGBColor(red: 0.95, green: 0.6, blue: 0.3), tip: .flat),
        Part(id: "shaft.ball", kind: .shaft, name: "ボールシャフト", rarity: .rare,
             bonus: StatBonus(defense: 0.05, stamina: 0.04), caption: "まるい先端でどっしり",
             color: RGBColor(red: 0.4, green: 0.7, blue: 1), tip: .ball),
        Part(id: "shaft.rubber", kind: .shaft, name: "ラバーシャフト", rarity: .rare,
             bonus: StatBonus(attack: 0.07, stamina: -0.02), caption: "ゴムの先端で床をつかんで突撃",
             color: RGBColor(red: 0.2, green: 0.2, blue: 0.25), tip: .flat),
        Part(id: "shaft.needle", kind: .shaft, name: "ニードルシャフト", rarity: .rare,
             bonus: StatBonus(stamina: 0.08, speed: -0.02), caption: "針のような先端で粘る",
             color: RGBColor(red: 0.85, green: 0.85, blue: 0.95), tip: .needle),
        Part(id: "shaft.jet", kind: .shaft, name: "ジェットシャフト", rarity: .superRare,
             bonus: StatBonus(speed: 0.12), caption: "ジェットのような加速",
             color: RGBColor(red: 1, green: 0.4, blue: 0.3), tip: .flat),
        Part(id: "shaft.grip", kind: .shaft, name: "グリップシャフト", rarity: .superRare,
             bonus: StatBonus(attack: 0.08, speed: 0.06), caption: "床をがっちりつかんで攻める",
             color: RGBColor(red: 0.3, green: 0.85, blue: 0.4), tip: .ball),
        Part(id: "shaft.mirage", kind: .shaft, name: "ミラージュシャフト", rarity: .ultraRare,
             bonus: StatBonus(stamina: 0.1, speed: 0.1), caption: "残像が見えるほど速く、長く回る",
             color: RGBColor(red: 0.85, green: 0.5, blue: 1), tip: .sharp),
        Part(id: "shaft.zeroGravity", kind: .shaft, name: "ゼログラビティシャフト", rarity: .ultraRare,
             bonus: StatBonus(defense: 0.03, stamina: 0.16), caption: "重さを感じさせない無重力の軸",
             color: RGBColor(red: 1, green: 0.85, blue: 0.35), tip: .needle),
        // ここから下は追加分（N）
        shaft("mini", "ミニシャフト", .normal, sta: 0.01, spd: 0.03, "小さな先端で小回りがきく", 0xCFD3DA, size: 0.7),
        shaft("wood", "ウッドシャフト", .normal, sta: 0.04, "木でできたやさしい軸", 0x9C6B3F),
        shaft("stone", "ストーンシャフト", .normal, def: 0.04, "石のようにすわりがいい", 0x8A8A8A, tip: .ball, size: 0.8),
        shaft("copper", "カッパーシャフト", .normal, def: 0.02, sta: 0.02, "銅のあたたかい輝き", 0xC0703A),
        shaft("plastic", "プラスチックシャフト", .normal, spd: 0.04, "軽くてよくすべる", 0x3A8CF0, tip: .flat),
        shaft("cork", "コルクシャフト", .normal, def: 0.03, sta: 0.02, "コルクのクッション", 0xC9A170, tip: .flat, size: 1.1),
        shaft("pin", "ピンシャフト", .normal, sta: 0.05, spd: -0.01, "まち針のような細い先端", 0xD9DDE5, tip: .needle, size: 0.8),
        shaft("bead", "ビーズシャフト", .normal, sta: 0.03, spd: 0.02, "小さなビーズ玉", 0xF5A3C7, tip: .ball, size: 0.7),
        shaft("wideFlat", "ワイドフラットシャフト", .normal, sta: -0.01, spd: 0.06, "大きな平らな先端で走り回る", 0xF08A24, tip: .wide),
        shaft("short", "ショートシャフト", .normal, def: 0.03, spd: 0.02, "背の低いがっしりした軸", 0x55595F, tip: .flat, size: 0.8),
        shaft("glass", "グラスシャフト", .normal, sta: 0.04, spd: 0.01, "ガラスのように透き通る", 0xA8E6F0),
        shaft("bamboo", "バンブーシャフト", .normal, sta: 0.02, spd: 0.03, "竹のようにしなやか", 0x7DBF4F, tip: .flat),
        shaft("marble", "マーブルシャフト", .normal, def: 0.02, sta: 0.03, "ビー玉のような先端", 0xF2F2F2, tip: .ball),
        shaft("thorn", "ソーンシャフト", .normal, atk: 0.04, sta: 0.01, "いばらのとげ", 0x3E6B35, tip: .needle),
        shaft("brass", "ブラスシャフト", .normal, def: 0.04, sta: 0.01, "真ちゅうの重たい軸", 0xC9A646, size: 1.1),
        // R
        shaft("drill", "ドリルシャフト", .rare, atk: 0.06, spd: 0.02, "床をけずるドリル", 0xB8BEC8, size: 1.3),
        shaft("spring", "スプリングシャフト", .rare, atk: 0.04, def: 0.04, "バネで跳ね返す", 0xA6E03A, tip: .ball),
        shaft("magnet", "マグネットシャフト", .rare, def: 0.07, "床に吸いつく磁石", 0xE03A3A, tip: .ball, size: 1.1),
        shaft("ice", "アイスシャフト", .rare, sta: 0.02, spd: 0.06, "氷の上をすべるように走る", 0xBDE6FA, tip: .flat),
        shaft("ruby", "ルビーシャフト", .rare, sta: 0.07, "ルビーの先端で長く回る", 0xD11F4F),
        shaft("sapphire", "サファイアシャフト", .rare, def: 0.03, sta: 0.05, "サファイアの先端", 0x2F5FD0),
        shaft("racing", "レーシングシャフト", .rare, sta: -0.01, spd: 0.09, "サーキットを駆けるタイヤ", 0xF5D02A, tip: .wide),
        shaft("hammer", "ハンマーシャフト", .rare, atk: 0.07, spd: -0.01, "大きな玉で体当たり", 0x45484F, tip: .ball, size: 1.3),
        shaft("feather", "フェザーシャフト", .rare, sta: 0.03, spd: 0.05, "羽のように軽い針", 0xF5F5F0, tip: .needle),
        shaft("tank", "タンクシャフト", .rare, def: 0.08, spd: -0.02, "戦車のように動じない", 0x6B7340, tip: .wide),
        shaft("gear", "ギアシャフト", .rare, atk: 0.03, spd: 0.05, "歯車で床をかむ", 0xB0803A, tip: .flat),
        shaft("pearl", "パールシャフト", .rare, def: 0.04, sta: 0.04, "真珠のような先端", 0xF0EBE0, tip: .ball, size: 0.9),
        // SR
        shaft("turbo", "ターボシャフト", .superRare, atk: 0.03, spd: 0.11, "ターボで一気に加速", 0xE0302A, tip: .wide),
        shaft("diamond", "ダイヤシャフト", .superRare, sta: 0.12, "ダイヤモンドの先端で回り続ける", 0xDFF6FF),
        shaft("titan", "タイタンシャフト", .superRare, def: 0.12, sta: 0.02, "巨人のような大玉", 0x8A9099, tip: .ball, size: 1.3),
        shaft("blaze", "ブレイズシャフト", .superRare, atk: 0.10, spd: 0.04, "燃える車輪", 0xFF7A1A, tip: .flat),
        shaft("shadow", "シャドウシャフト", .superRare, sta: 0.06, spd: 0.08, "影のように音もなく動く", 0x22202E, tip: .needle),
        shaft("storm", "ストームシャフト", .superRare, atk: 0.06, spd: 0.08, "嵐を呼ぶ先端", 0x7A4FD0, size: 1.2),
        shaft("anchor", "アンカーシャフト", .superRare, def: 0.10, sta: 0.05, spd: -0.02, "いかりのように動かない", 0x23356B, tip: .wide),
        shaft("lightning", "ライトニングシャフト", .superRare, def: -0.02, spd: 0.13, "稲妻のような速さ", 0xFFE14A, tip: .needle),
        shaft("crystal", "クリスタルシャフト", .superRare, def: 0.04, sta: 0.09, "結晶の先端が光る", 0xC9A8F0),
        // SSR
        shaft("infinity", "インフィニティシャフト", .ultraRare, sta: 0.14, spd: 0.06, "いつまでも止まらない無限の軸", 0xFF9EE0, size: 1.1),
        shaft("meteor", "メテオシャフト", .ultraRare, atk: 0.14, spd: 0.06, "隕石のように突っこむ", 0x9E2416, tip: .ball, size: 1.2),
        shaft("aegis", "イージスシャフト", .ultraRare, def: 0.16, sta: 0.04, "すべてをはじく神の盾", 0xFFD23F, tip: .wide),
        shaft("comet", "コメットシャフト", .ultraRare, sta: 0.02, spd: 0.18, "ほうき星のように駆けぬける", 0x8FD8FF, tip: .needle),
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

    /// count 回引く（10連は SR 以上が1つ確定）。ポイントが足りなければ nil
    func draw(_ kind: PartKind, count: Int) -> [GachaResult]? {
        let cost = count >= 10 ? Self.tenCost : Self.singleCost * count
        guard spend(cost) else { return nil }
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
