//
//  SpeakEasyApp.swift
//  RisingStarKid
//
//  An iOS app to help autistic children learn across 6 developmental dimensions
//  with adaptive difficulty adjustment and ABA-based reinforcement.
//  Build: 2026-03-29
//

import SwiftUI

@main
struct SpeakEasyApp: App {
    @StateObject private var progressManager = ProgressManager()
    @StateObject private var learningManager = AdaptiveLearningManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(progressManager)
                .environmentObject(learningManager)
        }
    }
}
