//
//  SpeakEasyApp.swift
//  SpeakEasy
//
//  An iOS app to help non-verbal autistic children learn to speak and recognize objects
//

import SwiftUI

@main
struct SpeakEasyApp: App {
    @StateObject private var progressManager = ProgressManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(progressManager)
        }
    }
}
