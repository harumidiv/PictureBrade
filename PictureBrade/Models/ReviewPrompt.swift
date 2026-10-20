//
//  ReviewPrompt.swift
//  PictureBrade
//

import Foundation

/// App Store レビューのお願いを出すタイミング。
/// ある程度遊んでから（勝った回数で判断）、1つのバージョンにつき1回だけ出す
enum ReviewPrompt {
    /// この回数だけ勝ったらお願いする
    static let requiredWins = 5

    private static let winsKey = "reviewTotalWins"
    private static let promptedVersionKey = "reviewPromptedVersion"

    private static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    /// バトルに勝ったときに呼ぶ（ストーリー・ランダム連戦どちらも数える）
    static func recordWin() {
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: winsKey) + 1, forKey: winsKey)
    }

    /// いまお願いしてよいか
    static var shouldRequest: Bool {
        let defaults = UserDefaults.standard
        return defaults.integer(forKey: winsKey) >= requiredWins
            && defaults.string(forKey: promptedVersionKey) != currentVersion
    }

    /// お願いを出したことを記録する（このバージョンではもう出さない）
    static func markRequested() {
        UserDefaults.standard.set(currentVersion, forKey: promptedVersionKey)
    }
}
