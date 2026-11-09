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
    var tip: ShaftTip = .sharp

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
    ]

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
