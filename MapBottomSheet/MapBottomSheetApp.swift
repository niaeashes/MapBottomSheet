//
//  MapBottomSheetApp.swift
//  MapBottomSheet
//

import SwiftUI

@main
struct MapBottomSheetApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem { Text("Map") }
            }
        }
    }
}
