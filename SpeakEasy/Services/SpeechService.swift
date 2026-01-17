//
//  SpeechService.swift
//  SpeakEasy
//

import Foundation
import AVFoundation

class SpeechService: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @Published var speechRate: Float = 0.4
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func speak(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        utterance.pitchMultiplier = 1.1
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        isSpeaking = true
        synthesizer.speak(utterance)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(text.count) * 0.1 + 0.5) {
            self.isSpeaking = false
        }
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    func setSpeechRate(_ rate: Float) {
        speechRate = max(0.1, min(0.6, rate))
    }
}
