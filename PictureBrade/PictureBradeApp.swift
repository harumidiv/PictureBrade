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

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
                .preferredColorScheme(.dark)
        }
    }
}
