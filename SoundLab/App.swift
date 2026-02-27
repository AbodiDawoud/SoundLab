//
//  SoundLabApp.swift
//  SoundLab


import SwiftUI
import AVFoundation


@main
struct SoundLabApp: App {
    
    var body: some Scene {
        #if os(macOS)
        Window("Sound Lab", id: "main") {
                ContentView()
                    .frame(minWidth: 380, idealWidth: 420, maxWidth: 520,
                           minHeight: 500, idealHeight: 500, maxHeight: 600)
                    .toolbarBackground(.hidden, for: .windowToolbar)
                    .containerBackground(.thickMaterial, for: .window)
                    .windowResizeBehavior(.disabled)
                    .windowFullScreenBehavior(.disabled)
                    .windowMinimizeBehavior(.disabled)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 420, height: 500)
        #else
        WindowGroup {
            ContentView()
                .onAppear(perform: configureAudioSession)
        }
        #endif
    }

    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif
    }
}
