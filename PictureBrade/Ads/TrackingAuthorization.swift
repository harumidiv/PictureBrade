//
//  TrackingAuthorization.swift
//  PictureBrade
//

import AppTrackingTransparency

/// App Tracking Transparency（ATT）の許可ダイアログ
enum TrackingAuthorization {
    /// まだ選んでいなければダイアログを出し、選ばれるまで待つ。
    /// アプリがアクティブでないとダイアログが出ないため、scenePhase が .active になってから呼ぶ
    static func requestIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }
}
