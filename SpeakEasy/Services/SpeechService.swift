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

class SpeechService: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @Published var isListening = false
    @Published var recognizedText: String = ""
    @Published var lastRating: Double = 0.0
    @Published var speechRate: Float = 0.4
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var mockProvider: SpeechRecognitionProvider?
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        checkAuthorizationStatus()
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
            if forPlayback {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            } else {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            }
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
    
    func startListening(targetWord: String, completion: @escaping (Double) -> Void) {
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
            completion(0)
            return
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            completion(0)
            return
        }
        
        stopListening()
        setupAudioSession(forPlayback: false)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            completion(0)
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.recognizedText = text
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                DispatchQueue.main.async {
                    self.isListening = false
                    let rating = self.calculateRating(recognized: self.recognizedText, target: targetWord)
                    self.lastRating = rating
                    completion(rating)
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
                self.recognizedText = ""
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                if self?.isListening == true {
                    self?.stopListening()
                }
            }
        } catch {
            print("Audio engine failed to start: \(error)")
            completion(0)
        }
    }
    
    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        DispatchQueue.main.async {
            self.isListening = false
        }
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
        
        if normalizedRecognized.contains(normalizedTarget) || normalizedTarget.contains(normalizedRecognized) {
            let lengthRatio = Double(min(normalizedRecognized.count, normalizedTarget.count)) / Double(max(normalizedRecognized.count, normalizedTarget.count))
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
            }
        }
        
        return matrix[m][n]
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
