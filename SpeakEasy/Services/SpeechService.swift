//
//  SpeechService.swift
//  SpeakEasy
//

import Foundation
import AVFoundation
import Speech

protocol SpeechRecognitionProvider {
    func startListening(completion: @escaping (String?, Error?) -> Void)
    func stopListening()
    var isListening: Bool { get }
}

class SpeechService: NSObject, ObservableObject {
    private nonisolated(unsafe) let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @Published var isListening = false
    @Published var recognizedText: String = ""
    @Published var lastRating: Double = 0.0
    @Published var speechRate: Float = 0.4
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var currentLanguage: SpeechLanguage = .english

    /// Configurable listening duration (seconds). Default 5s, can extend for longer utterances.
    var listeningDuration: TimeInterval = 5.0

    /// Stored completion handler for manual-stop mode
    private var pendingCompletion: ((Double) -> Void)?
    /// Stored target word for manual-stop evaluation
    private var pendingTargetWord: String = ""
    /// Cancellable work item for the delayed recognition start
    private var pendingRecognitionWork: DispatchWorkItem?
    /// Cancellable work item for the auto-stop timer
    private var pendingAutoStopWork: DispatchWorkItem?
    /// Cancellable work item for silence-based auto-stop in manual mode
    private var pendingSilenceWork: DispatchWorkItem?
    /// Duration of silence (no new partial results) before auto-stopping in manual mode
    private let silenceTimeout: TimeInterval = 3.0

    /// Callback fired when TTS finishes speaking naturally (not cancelled).
    /// The view uses this to auto-start listening after the instruction is read.
    var onSpeechFinished: (() -> Void)?

    /// Number of queued storytelling utterances still pending.
    /// `onSpeechFinished` fires only when this reaches zero.
    private var pendingUtteranceCount: Int = 0

    enum SpeechLanguage: String, CaseIterable {
        case english = "en-US"
        case chinese = "zh-CN"

        var displayName: String {
            switch self {
            case .english: return "English"
            case .chinese: return "中文"
            }
        }
    }

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    var mockProvider: SpeechRecognitionProvider?

    private static let languageKey = "speechLanguage"

    override init() {
        super.init()
        synthesizer.delegate = self
        // Restore persisted language preference
        if let savedLang = UserDefaults.standard.string(forKey: SpeechService.languageKey),
           let language = SpeechLanguage(rawValue: savedLang) {
            currentLanguage = language
        }
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: currentLanguage.rawValue))
        checkAuthorizationStatus()
    }

    /// Switch recognition + TTS language
    func setLanguage(_ language: SpeechLanguage) {
        currentLanguage = language
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language.rawValue))
        UserDefaults.standard.set(language.rawValue, forKey: SpeechService.languageKey)
    }
    
    private func checkAuthorizationStatus() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
            }
        }
    }
    
    func setupAudioSession(forPlayback: Bool = true) {
        do {
            // Always use .playAndRecord so switching between TTS and speech
            // recognition never requires an audio-category change.  On real
            // iPhones a .playback → .playAndRecord switch can silently fail
            // (the deactivation races with draining TTS buffers), leaving
            // the audio hardware in a broken state where the mic returns a
            // zero-sample-rate format and recognition fails immediately.
            //
            // .defaultToSpeaker keeps TTS audible through the main speaker
            // instead of the earpiece that .playAndRecord defaults to.
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: forPlayback ? .default : .measurement,
                options: [.defaultToSpeaker, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func speak(_ text: String) {
        setupAudioSession(forPlayback: true)
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        pendingUtteranceCount = 0  // single utterance, no multi-queue
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        utterance.pitchMultiplier = 1.1
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: currentLanguage.rawValue)
        
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// Speak with a lively, storytelling tone for children.
    ///
    /// Splits the text into sentences and speaks each one with varied
    /// pitch and rate so the narration sounds animated rather than flat.
    /// Exclamatory sentences get higher pitch; questions dip lower.
    func speakStorytelling(_ text: String) {
        setupAudioSession(forPlayback: true)

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        // Split into sentences (handles . ! ? and Chinese 。！？)
        let sentences = splitIntoSentences(text)
        guard !sentences.isEmpty else { return }

        pendingUtteranceCount = sentences.count
        isSpeaking = true

        let voice = AVSpeechSynthesisVoice(language: currentLanguage.rawValue)

        for (index, sentence) in sentences.enumerated() {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                pendingUtteranceCount -= 1
                continue
            }

            let utterance = AVSpeechUtterance(string: trimmed)
            utterance.voice = voice
            utterance.volume = 1.0

            // Vary parameters per sentence for natural intonation
            let isExclamation = trimmed.hasSuffix("!") || trimmed.hasSuffix("\u{FF01}")
            let isQuestion    = trimmed.hasSuffix("?") || trimmed.hasSuffix("\u{FF1F}")

            if isExclamation {
                // Excited / happy — higher pitch, slightly faster
                utterance.rate = 0.38
                utterance.pitchMultiplier = Float.random(in: 1.35...1.45)
            } else if isQuestion {
                // Curious / inviting — moderate pitch, slower
                utterance.rate = 0.33
                utterance.pitchMultiplier = Float.random(in: 1.15...1.25)
            } else {
                // Narrative — gentle variation around a warm baseline
                utterance.rate = 0.35
                utterance.pitchMultiplier = Float.random(in: 1.20...1.30)
            }

            // Pauses between sentences give a storytelling rhythm
            utterance.preUtteranceDelay  = index == 0 ? 0.1 : 0.25
            utterance.postUtteranceDelay = 0.15

            synthesizer.speak(utterance)
        }
    }

    /// Split text into individual sentences for storytelling cadence.
    private func splitIntoSentences(_ text: String) -> [String] {
        var results: [String] = []
        // Use NSLinguisticTagger-free approach: split on sentence-ending punctuation
        // while keeping the punctuation attached to the sentence.
        let pattern = "[^.!?\u{3002}\u{FF01}\u{FF1F}]+[.!?\u{3002}\u{FF01}\u{FF1F}]+"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            for match in matches {
                let s = nsText.substring(with: match.range)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !s.isEmpty { results.append(s) }
            }
        }
        // If regex produced nothing (no punctuation), speak the whole text as one piece
        if results.isEmpty && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            results.append(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return results
    }
    
    func stop() {
        pendingUtteranceCount = 0
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    func setSpeechRate(_ rate: Float) {
        speechRate = max(0.1, min(0.6, rate))
    }
    
    /// Start listening with manual stop control. The user must call `stopAndEvaluate()` to finish.
    func startListeningManual(targetWord: String, completion: @escaping (Double) -> Void) {
        startListeningInternal(targetWord: targetWord, autoStop: false, completion: completion)
    }

    /// Stop listening and evaluate the recognized speech against the target word.
    func stopAndEvaluate() {
        // Cancel any pending delayed recognition start (during the 0.3s window)
        if let work = pendingRecognitionWork {
            work.cancel()
            pendingRecognitionWork = nil
            // If the engine never started, fire the completion with 0
            // and reset the listening flag so the UI returns to idle.
            if !audioEngine.isRunning {
                isListening = false
                let completion = pendingCompletion
                pendingCompletion = nil
                completion?(0)
                return
            }
        }

        guard isListening else { return }
        // Stop the audio engine and end the audio stream so the recognition task
        // finalises and fires its callback with the accumulated transcription.
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
    }

    func startListening(targetWord: String, completion: @escaping (Double) -> Void) {
        startListeningInternal(targetWord: targetWord, autoStop: true, completion: completion)
    }

    private func startListeningInternal(targetWord: String, autoStop: Bool, completion: @escaping (Double) -> Void) {
        if let mockProvider = mockProvider {
            isListening = true
            mockProvider.startListening { [weak self] text, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isListening = false
                    if let text = text {
                        self.recognizedText = text
                        let rating = self.calculateRating(recognized: text, target: targetWord)
                        self.lastRating = rating
                        completion(rating)
                    } else {
                        self.recognizedText = ""
                        self.lastRating = 0
                        completion(0)
                    }
                }
            }
            return
        }
        
        guard authorizationStatus == .authorized else {
            checkAuthorizationStatus()
            DispatchQueue.main.async {
                completion(0)
            }
            return
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            DispatchQueue.main.async {
                completion(0)
            }
            return
        }
        
        // Stop any ongoing TTS to release the audio session before recording
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }

        stopListening()

        // Cancel any lingering auto-stop timer from a previous session so it
        // cannot interfere with this new listening session.
        pendingAutoStopWork?.cancel()
        pendingAutoStopWork = nil

        // Re-set pendingCompletion AFTER stopListening() which clears it.
        // stopAndEvaluate() reads this during the 0.3s delay window.
        pendingCompletion = completion
        pendingTargetWord = targetWord

        // Switch audio session mode from .default (TTS) to .measurement
        // (recognition).  The category stays .playAndRecord throughout, so
        // no hardware route change is needed – only the DSP mode changes.
        setupAudioSession(forPlayback: false)

        // Reset audio engine so its node graph is clean for the new session.
        audioEngine.reset()

        // Set isListening immediately so stopAndEvaluate() works during
        // the delay window and the UI shows the listening state right away.
        isListening = true
        recognizedText = ""

        // Give the audio hardware a moment to settle after stopping TTS.
        // On real iPhones the mic input format can be stale if we query it
        // immediately after the synthesizer releases the audio output.
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.pendingRecognitionWork = nil
            self.startRecognitionEngine(
                targetWord: targetWord,
                autoStop: autoStop,
                speechRecognizer: speechRecognizer,
                completion: completion
            )
        }
        pendingRecognitionWork = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    /// Second phase of recognition start – runs after a short delay to let
    /// the audio hardware settle following TTS stop + mode switch.
    private func startRecognitionEngine(
        targetWord: String,
        autoStop: Bool,
        speechRecognizer: SFSpeechRecognizer,
        completion: @escaping (Double) -> Void
    ) {
        guard speechRecognizer.isAvailable else {
            DispatchQueue.main.async {
                self.isListening = false
                completion(0)
            }
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            DispatchQueue.main.async {
                self.isListening = false
                completion(0)
            }
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("Invalid recording format – sampleRate: \(recordingFormat.sampleRate), channels: \(recordingFormat.channelCount)")
            DispatchQueue.main.async {
                self.isListening = false
                completion(0)
            }
            return
        }
        
        var hasCompleted = false
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.recognizedText = text
                }
                isFinal = result.isFinal

                // Early stop: when a partial result already matches the target
                // word well enough, stop listening immediately instead of
                // waiting for the full auto-stop duration. This makes the UX
                // feel snappy — the button flips to "Say It Again" right away.
                if !isFinal && autoStop {
                    let rating = self.calculateRating(recognized: text, target: targetWord)
                    if rating >= 3.5 {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self, self.isListening else { return }
                            self.pendingAutoStopWork?.cancel()
                            self.pendingAutoStopWork = nil
                            self.stopAndEvaluate()
                        }
                    }
                }

                // Silence-based auto-stop for manual mode: after each
                // partial result, reset a timer. If no new results arrive
                // within silenceTimeout, treat it as if the user pressed
                // the stop button.
                if !isFinal && !autoStop && !text.isEmpty {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self, self.isListening else { return }
                        self.pendingSilenceWork?.cancel()
                        let silenceWork = DispatchWorkItem { [weak self] in
                            guard let self = self, self.isListening else { return }
                            self.stopAndEvaluate()
                        }
                        self.pendingSilenceWork = silenceWork
                        DispatchQueue.main.asyncAfter(deadline: .now() + self.silenceTimeout, execute: silenceWork)
                    }
                }
            }
            
            if error != nil || isFinal {
                if self.audioEngine.isRunning {
                    self.audioEngine.stop()
                }
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                DispatchQueue.main.async {
                    guard !hasCompleted else { return }
                    hasCompleted = true
                    self.isListening = false
                    let rating = self.calculateRating(recognized: self.recognizedText, target: targetWord)
                    self.lastRating = rating
                    self.pendingCompletion = nil
                    completion(rating)
                }
            }
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            
            if autoStop {
                let autoStopWork = DispatchWorkItem { [weak self] in
                    if self?.isListening == true {
                        // Use stopAndEvaluate instead of stopListening so
                        // the recognition task finalises and fires its
                        // completion handler with the accumulated text.
                        self?.stopAndEvaluate()
                    }
                }
                self.pendingAutoStopWork = autoStopWork
                DispatchQueue.main.asyncAfter(deadline: .now() + self.listeningDuration, execute: autoStopWork)
            }
        } catch {
            print("Audio engine failed to start: \(error)")
            DispatchQueue.main.async {
                self.isListening = false
                completion(0)
            }
        }
    }
    
    func stopListening() {
        // Cancel any pending timers
        pendingRecognitionWork?.cancel()
        pendingRecognitionWork = nil
        pendingAutoStopWork?.cancel()
        pendingAutoStopWork = nil
        pendingSilenceWork?.cancel()
        pendingSilenceWork = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        recognitionRequest?.endAudio()
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        pendingCompletion = nil
        
        audioEngine.inputNode.removeTap(onBus: 0)
        
        self.isListening = false
    }
    
    func calculateRating(recognized: String, target: String) -> Double {
        let normalizedRecognized = recognized.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTarget = target.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if normalizedRecognized.isEmpty {
            return 0.0
        }
        
        if normalizedRecognized == normalizedTarget {
            return 5.0
        }
        
        // Recognized text contains the full target word (e.g. "I see an apple" for target "apple")
        if normalizedRecognized.contains(normalizedTarget) {
            let lengthRatio = Double(normalizedTarget.count) / Double(normalizedRecognized.count)
            return min(4.5, 3.5 + lengthRatio)
        }
        
        let lengthRatio = Double(min(normalizedRecognized.count, normalizedTarget.count)) / Double(max(normalizedRecognized.count, normalizedTarget.count))
        
        // Target contains the recognized text and it's a substantial portion (e.g. "appl" or "ap" for "apple")
        if normalizedTarget.contains(normalizedRecognized) && lengthRatio >= 0.4 {
            return min(4.5, 3.5 + lengthRatio)
        }
        
        let similarity = levenshteinSimilarity(normalizedRecognized, normalizedTarget)
        return similarity * 5.0
    }
    
    private func levenshteinSimilarity(_ s1: String, _ s2: String) -> Double {
        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)
        if maxLength == 0 { return 1.0 }
        return 1.0 - (Double(distance) / Double(maxLength))
    }
    
    /// Damerau-Levenshtein distance: counts transpositions of adjacent characters as a single edit
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }
        
        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
                // Transposition of two adjacent characters
                if i > 1 && j > 1 && s1Array[i - 1] == s2Array[j - 2] && s1Array[i - 2] == s2Array[j - 1] {
                    matrix[i][j] = min(matrix[i][j], matrix[i - 2][j - 2] + cost)
                }
            }
        }
        
        return matrix[m][n]
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // For storytelling multi-utterance sequences, only fire
            // onSpeechFinished after the very last utterance completes.
            if self.pendingUtteranceCount > 0 {
                self.pendingUtteranceCount -= 1
            }
            if self.pendingUtteranceCount <= 0 {
                self.isSpeaking = false
                self.onSpeechFinished?()
            }
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.pendingUtteranceCount = 0
            self.isSpeaking = false
        }
    }
}

class MockSpeechRecognitionProvider: SpeechRecognitionProvider {
    var mockText: String = ""
    var mockError: Error? = nil
    var mockDelay: TimeInterval = 1.0
    private(set) var isListening: Bool = false
    
    func startListening(completion: @escaping (String?, Error?) -> Void) {
        isListening = true
        DispatchQueue.main.asyncAfter(deadline: .now() + mockDelay) { [weak self] in
            self?.isListening = false
            completion(self?.mockText, self?.mockError)
        }
    }
    
    func stopListening() {
        isListening = false
    }
}
