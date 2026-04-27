//
//  SoundEffectService.swift
//  RisingStarKid
//
//  Provides audio feedback sounds for correct/incorrect answers,
//  level-up events, and other interactions. Uses system sounds and
//  synthesized tones via AVFoundation.
//

import AVFoundation
import UIKit

@MainActor
class SoundEffectService: ObservableObject {
    static let shared = SoundEffectService()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()

    /// Whether sound effects are enabled (respects user settings).
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "soundEffectsEnabled")
        }
    }

    init() {
        self.isEnabled = UserDefaults.standard.object(forKey: "soundEffectsEnabled") as? Bool ?? true
        configureAudioEngine()
    }

    private func configureAudioEngine() {
        do {
            // Use .playAndRecord to match SpeechService — switching between
            // .playback and .playAndRecord can silently fail on real iPhones,
            // leaving the mic in a broken state.
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)

            let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
            engine.attach(playerNode)
            engine.connect(playerNode, to: engine.mainMixerNode, format: format)
            try engine.start()
        } catch {
            print("[SoundEffect] Audio engine setup error: \(error)")
        }
    }

    private func ensureEngineRunning() {
        if !engine.isRunning {
            do { try engine.start() } catch {
                print("[SoundEffect] Engine restart error: \(error)")
            }
        }
    }

    // MARK: - Public API

    /// Play a short, bright chime for correct answers.
    func playCorrect() {
        guard isEnabled else { return }
        playSystemTone(frequency: 880, duration: 0.15, secondFrequency: 1320, secondDelay: 0.12)
        hapticSuccess()
    }

    /// Play a gentle tone for incorrect answers (non-punishing).
    func playIncorrect() {
        guard isEnabled else { return }
        playSystemTone(frequency: 330, duration: 0.25, secondFrequency: 280, secondDelay: 0.2)
        hapticError()
    }

    /// Play a celebratory fanfare for level-up events.
    func playLevelUp() {
        guard isEnabled else { return }
        playLevelUpSequence()
        hapticSuccess()
    }

    /// Play a short tap feedback sound.
    func playTap() {
        guard isEnabled else { return }
        playSystemTone(frequency: 1200, duration: 0.05)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Play a streak bonus sound.
    func playStreakBonus() {
        guard isEnabled else { return }
        playStreakSequence()
        hapticSuccess()
    }

    // MARK: - Haptic Feedback

    private func hapticSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func hapticError() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    // MARK: - Tone Synthesis

    private func playSystemTone(frequency: Double, duration: Double, secondFrequency: Double? = nil, secondDelay: Double? = nil) {
        let sampleRate: Double = 44100
        let samples = Int(sampleRate * duration)

        var audioData = [Float](repeating: 0, count: samples)
        for i in 0..<samples {
            let t = Double(i) / sampleRate
            let envelope = min(1.0, min(t / 0.01, (duration - t) / 0.03))
            audioData[i] = Float(sin(2.0 * .pi * frequency * t) * envelope * 0.3)
        }

        playAudioData(audioData, sampleRate: sampleRate)

        if let freq2 = secondFrequency, let delay = secondDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playSystemTone(frequency: freq2, duration: duration)
            }
        }
    }

    private func playLevelUpSequence() {
        let notes: [(freq: Double, delay: Double)] = [
            (523.25, 0.0),   // C5
            (659.25, 0.12),  // E5
            (783.99, 0.24),  // G5
            (1046.5, 0.36),  // C6
        ]
        for note in notes {
            DispatchQueue.main.asyncAfter(deadline: .now() + note.delay) { [weak self] in
                self?.playSystemTone(frequency: note.freq, duration: 0.2)
            }
        }
    }

    private func playStreakSequence() {
        let notes: [(freq: Double, delay: Double)] = [
            (660, 0.0),
            (880, 0.08),
            (1100, 0.16),
        ]
        for note in notes {
            DispatchQueue.main.asyncAfter(deadline: .now() + note.delay) { [weak self] in
                self?.playSystemTone(frequency: note.freq, duration: 0.12)
            }
        }
    }

    private func playAudioData(_ data: [Float], sampleRate: Double) {
        ensureEngineRunning()

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(data.count)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let channelData = buffer.floatChannelData![0]
        for i in 0..<data.count {
            channelData[i] = data[i]
        }

        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
}
