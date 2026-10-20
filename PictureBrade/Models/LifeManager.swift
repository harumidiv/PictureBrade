//
//  LifeManager.swift
//  PictureBrade
//

import Foundation
import Observation

/// ストーリーのライフ。負けるたびに1つ減り、時間がたつと1つずつ回復する。広告を見ると1つ回復する
@Observable
final class LifeManager {
    static let maxLives = 3
    /// 1つ回復するまでの時間
    static let recoveryInterval: TimeInterval = 60 * 60

    private static let livesKey = "storyLives"
    private static let nextRecoveryKey = "storyLivesNextRecovery"

    /// 最後に保存したときのライフ（時間による回復は含まない）
    private var storedLives: Int
    /// 次の1つが回復する時刻（満タンなら nil）
    private var nextRecovery: Date?

    init() {
        let defaults = UserDefaults.standard
        // 最大数を減らしたときに、前に保存した多いライフが残らないようにする
        storedLives = min(defaults.object(forKey: Self.livesKey) as? Int ?? Self.maxLives, Self.maxLives)
        nextRecovery = defaults.object(forKey: Self.nextRecoveryKey) as? Date
    }

    /// その時点のライフ（時間で回復したぶんを含む）
    func lives(at now: Date = .now) -> Int {
        guard storedLives < Self.maxLives, let nextRecovery, now >= nextRecovery else { return storedLives }
        let recovered = 1 + Int(now.timeIntervalSince(nextRecovery) / Self.recoveryInterval)
        return min(Self.maxLives, storedLives + recovered)
    }

    /// 次の1つが回復するまでの残り時間（満タンなら nil）
    func timeUntilNextLife(at now: Date = .now) -> TimeInterval? {
        guard lives(at: now) < Self.maxLives, let nextRecovery else { return nil }
        let elapsed = max(0, now.timeIntervalSince(nextRecovery))
        let intoCurrent = elapsed.truncatingRemainder(dividingBy: Self.recoveryInterval)
        return now < nextRecovery ? nextRecovery.timeIntervalSince(now) : Self.recoveryInterval - intoCurrent
    }

    var canPlay: Bool { lives() > 0 }

    /// 負けたときに1つ減らす
    func consume(at now: Date = .now) {
        normalize(at: now)
        guard storedLives > 0 else { return }
        if storedLives == Self.maxLives {
            nextRecovery = now.addingTimeInterval(Self.recoveryInterval)
        }
        storedLives -= 1
        save()
    }

    /// 広告を見たときに1つ回復する。時間による回復のカウントダウンはそのまま続く
    func recoverOne(at now: Date = .now) {
        normalize(at: now)
        guard storedLives < Self.maxLives else { return }
        storedLives += 1
        if storedLives == Self.maxLives {
            nextRecovery = nil
        }
        save()
    }

    /// 時間で回復したぶんを保存値に反映する
    private func normalize(at now: Date) {
        let current = lives(at: now)
        guard current != storedLives else { return }
        if current >= Self.maxLives {
            nextRecovery = nil
        } else if let next = nextRecovery {
            nextRecovery = next.addingTimeInterval(Double(current - storedLives) * Self.recoveryInterval)
        }
        storedLives = current
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(storedLives, forKey: Self.livesKey)
        defaults.set(nextRecovery, forKey: Self.nextRecoveryKey)
    }
}
