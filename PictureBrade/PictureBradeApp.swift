//
//  PictureBradeApp.swift
//  PictureBrade
//
//  Created by harumi.sagawa on 2026/10/19.
//

import SwiftUI

@main
struct PictureBradeApp: App {
    @State private var store = BladeStore()
    @State private var enemies = EnemyCatalog()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
                .environment(enemies)
                .preferredColorScheme(.dark)
        }
    }
}
