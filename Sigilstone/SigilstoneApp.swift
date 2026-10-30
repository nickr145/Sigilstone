//
//  SigilstoneApp.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2024-09-20.
//

import SwiftUI

@main
struct SigilstoneApp: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var audioManager = AudioPlayerManager()
    
    var body: some Scene {
        WindowGroup {
            TitleView()
                .environmentObject(audioManager)
                .onChange(of: scenePhase) {
                    if scenePhase != .active {
                        audioManager.stopAudio()
                    }
                }
        }
    }
}
