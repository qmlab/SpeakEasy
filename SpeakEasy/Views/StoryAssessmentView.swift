//
//  StoryAssessmentView.swift
//  RisingStarKid
//
//  Interactive story-based assessment. The child experiences a narrative
//  (e.g. Bunny's Birthday Party) where assessment questions emerge
//  naturally from the plot. Replaces the old random-test assessment.
//

import SwiftUI

struct StoryAssessmentView: View {
    @EnvironmentObject var learningManager: AdaptiveLearningManager
    @Environment(\.dismiss) private var dismiss

    let storyId: String

    @State private var phase: StoryPhase = .intro
    @State private var assessmentId: String?
    @State private var storyStart: StoryStartResponse?
    @State private var currentScene: SceneResponse?
    @State private var completionResult: StoryCompleteResponse?

    @State private var selectedOption: String?
    @State private var lastFeedback: SceneFeedbackInfo?
    @State private var progress: Double = 0.0

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    @State private var sceneStartTime: Date?

    // Voice input state
    @State private var isListening: Bool = false
    @State private var spokenText: String = ""
    @State private var hasRecording: Bool = false
    @State private var isEvaluating: Bool = false

    @StateObject private var speechService = SpeechService()
    private let api = AdaptiveAPIService()

    enum StoryPhase {
        case intro
        case scene
        case feedback
        case completed
    }

    struct SceneFeedbackInfo {
        let isCorrect: Bool
        let message: String
    }

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                switch phase {
                case .intro:
                    introView
                case .scene:
                    if let scene = currentScene {
                        sceneView(scene)
                    } else {
                        loadingView
                    }
                case .feedback:
                    feedbackView
                case .completed:
                    completedView
                }
            }
        }
        .task {
            await startStory()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.pink.opacity(0.08), Color.orange.opacity(0.06), Color.yellow.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Intro View

    private var introView: some View {
        VStack(spacing: 24) {
            Spacer()

            if let story = storyStart {
                // Story cover image
                if let url = story.introImageUrl, !url.isEmpty {
                    AsyncImage(url: URL(string: url)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 280)
                            .cornerRadius(24)
                            .shadow(color: .orange.opacity(0.3), radius: 12, y: 6)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.orange.opacity(0.1))
                            .frame(height: 200)
                            .overlay(ProgressView())
                    }
                    .padding(.horizontal, 32)
                }

                // Title
                Text(story.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(story.titleZh)
                    .font(.title3)
                    .foregroundColor(.secondary)

                // Character intro
                HStack(spacing: 8) {
                    Text(story.character.emoji)
                        .font(.system(size: 40))
                    Text(story.introNarration)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)

                Spacer()

                // Start button
                Button {
                    speechService.speak(story.introNarration)
                    withAnimation(.spring()) {
                        phase = .scene
                    }
                    Task {
                        await fetchNextScene()
                    }
                } label: {
                    HStack {
                        Text("Let's Go!")
                            .font(.title2)
                            .fontWeight(.bold)
                        Image(systemName: "play.fill")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.orange.gradient)
                    )
                }
                .padding(.horizontal, 40)

            } else if let error = errorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                Text(error)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Try Again") {
                    errorMessage = nil
                    Task { await startStory() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Spacer()
            } else if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Loading story...")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Spacer()
            }

            // Close button
            Button {
                dismiss()
            } label: {
                Text("Maybe Later")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 32)
        }
    }

    // MARK: - Scene View

    @ViewBuilder
    private func sceneView(_ scene: SceneResponse) -> some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(scene.sceneIndex + 1) / \(scene.totalScenes)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Progress bar
            storyProgressBar(scene)

            ScrollView {
                VStack(spacing: 20) {
                    // Scene illustration
                    if let url = scene.imageUrl, !url.isEmpty {
                        AsyncImage(url: URL(string: url)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 240)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.orange.opacity(0.1))
                                .frame(height: 180)
                                .overlay(ProgressView())
                        }
                        .padding(.horizontal, 24)
                    }

                    // Narration bubble
                    narratorBubble(scene)

                    // Hear Again button
                    Button {
                        speechService.speak(scene.test.instruction)
                    } label: {
                        Label("Hear Again", systemImage: "speaker.wave.2.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.12))
                            )
                    }
                    .disabled(isListening)

                    // Question
                    Text(scene.test.instruction)
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Options (touch tasks)
                    if scene.test.modality == "touch" && !scene.test.options.isEmpty {
                        sceneOptionButtons(scene)
                    }

                    // Voice task
                    if scene.test.modality == "voice" {
                        voiceSection(scene: scene)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .onAppear {
            sceneStartTime = Date()
            // Auto-speak narration then instruction
            speechService.onSpeechFinished = {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.speechService.onSpeechFinished = nil
                    self.speechService.speak(scene.test.instruction)
                }
            }
            speechService.speak(scene.narration)
        }
    }

    // MARK: - Narrator Bubble

    private func narratorBubble(_ scene: SceneResponse) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(scene.character.emoji)
                .font(.system(size: 44))

            VStack(alignment: .leading, spacing: 4) {
                Text(scene.character.name)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)

                Text(scene.narration)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )

            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Option Buttons

    private func sceneOptionButtons(_ scene: SceneResponse) -> some View {
        VStack(spacing: 12) {
            let options = scene.test.options
            let imageHints = scene.test.imageHints

            ForEach(Array(options.enumerated()), id: \.offset) { idx, option in
                Button {
                    selectedOption = option
                    speechService.speak(option)
                    Task {
                        await submitSceneResponse(scene: scene, selected: option)
                    }
                } label: {
                    HStack(spacing: 12) {
                        // Show image hint if available
                        if idx < imageHints.count && !imageHints[idx].isEmpty {
                            RemoteImageView(
                                objectName: imageHints[idx],
                                imageType: .thumbnail,
                                fallbackIcon: "questionmark.circle",
                                iconColor: .orange,
                                size: 44
                            )
                            .cornerRadius(10)
                        }

                        Text(option)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                        if selectedOption == option {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .foregroundColor(selectedOption == option ? .white : .primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedOption == option ? Color.orange : Color(.systemBackground))
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    )
                }
                .disabled(selectedOption != nil)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Voice Section

    private func voiceSection(scene: SceneResponse) -> some View {
        let targetWord = scene.test.correctAnswer

        return VStack(spacing: 16) {
            Text("Say it out loud!")
                .font(.headline)
                .foregroundColor(.orange)

            if !spokenText.isEmpty {
                HStack {
                    Image(systemName: "quote.bubble.fill")
                        .foregroundColor(.orange)
                    Text("You said: \"\(spokenText)\"")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if isListening && !speechService.recognizedText.isEmpty {
                Text(speechService.recognizedText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
            }

            if isEvaluating {
                HStack {
                    ProgressView()
                    Text("Checking...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Mic button
            Button {
                if isEvaluating { return }
                if isListening {
                    speechService.stopAndEvaluate()
                } else {
                    startListeningForScene(scene: scene, targetWord: targetWord)
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title)
                    Text(isListening ? "Listening..." : (hasRecording ? "Say It Again" : "Say It"))
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isListening ? Color.red : (hasRecording ? Color.orange : Color.orange))
                )
            }
            .disabled(selectedOption != nil || isEvaluating)
            .padding(.horizontal, 24)

            // Hear target again
            if !targetWord.isEmpty {
                Button {
                    speechService.speak(targetWord)
                } label: {
                    Label("Hear Again", systemImage: "speaker.wave.2")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                .disabled(isListening)
            }

            // Skip
            Button {
                Task {
                    await submitSceneResponse(scene: scene, selected: nil, spoken: "")
                }
            } label: {
                Text("Skip")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .disabled(selectedOption != nil || isListening || isEvaluating)
        }
    }

    // MARK: - Progress Bar

    private func storyProgressBar(_ scene: SceneResponse) -> some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.gradient)
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 8)
            .padding(.horizontal)
        }
        .padding(.top, 8)
    }

    // MARK: - Feedback View

    private var feedbackView: some View {
        VStack(spacing: 32) {
            Spacer()

            if let fb = lastFeedback {
                Text(fb.isCorrect ? "🎉" : "💪")
                    .font(.system(size: 100))

                Text(fb.message)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(fb.isCorrect ? .green : .orange)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Completed View

    private var completedView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let result = completionResult {
                    // Outro image
                    if let url = result.outroImageUrl, !url.isEmpty {
                        AsyncImage(url: URL(string: url)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 220)
                                .cornerRadius(20)
                        } placeholder: {
                            ProgressView()
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 16)
                    }

                    Text("🎉")
                        .font(.system(size: 64))

                    Text("Great Job!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(result.outroNarration)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)

                    // Score
                    VStack(spacing: 8) {
                        Text("\(result.totalCorrect) / \(result.totalTested)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        Text("Questions Correct")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.orange.opacity(0.1))
                    )

                    // Dimension results
                    VStack(spacing: 12) {
                        ForEach(result.dimensions) { dim in
                            storyDimensionRow(dim)
                        }
                    }
                    .padding(.horizontal)

                    // Done button
                    Button {
                        dismiss()
                    } label: {
                        Text("Start Learning!")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.orange.gradient)
                            )
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 24)
                }
            }
        }
    }

    // MARK: - Dimension Result Row

    private func storyDimensionRow(_ dim: StoryDimensionResult) -> some View {
        HStack(spacing: 12) {
            if let dimEnum = dim.dimensionEnum {
                Image(systemName: dimEnum.icon)
                    .font(.title3)
                    .foregroundColor(dimEnum.color)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(dimEnum.color.opacity(0.15)))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(dim.dimensionEnum?.label ?? dim.dimension)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Level \(dim.assessedLevel) · \(dim.correctCount)/\(dim.totalCount) correct")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(Int(dim.accuracy * 100))%")
                .font(.headline)
                .foregroundColor(dim.accuracy >= 0.5 ? .green : .orange)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading next scene...")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - API Calls

    private func startStory() async {
        guard let playerId = learningManager.playerId else {
            errorMessage = "No player found"
            return
        }

        isLoading = true
        do {
            let result = try await api.startStory(playerId: playerId, storyId: storyId)
            storyStart = result
            assessmentId = result.assessmentId
            isLoading = false
        } catch {
            errorMessage = "Could not start story: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func fetchNextScene() async {
        guard let aId = assessmentId else { return }

        isLoading = true
        do {
            let scene = try await api.getNextScene(assessmentId: aId)
            currentScene = scene
            progress = scene.progress
            selectedOption = nil
            spokenText = ""
            hasRecording = false
            isListening = false
            isEvaluating = false
            sceneStartTime = Date()
            isLoading = false

            withAnimation(.spring()) {
                phase = .scene
            }
        } catch {
            // No more scenes — complete
            await completeStoryAssessment()
        }
    }

    private func submitSceneResponse(scene: SceneResponse, selected: String?, spoken: String? = nil) async {
        guard let aId = assessmentId else { return }

        let elapsed = sceneStartTime.map { Int(Date().timeIntervalSince($0) * 1000) }

        let body = SceneRespondRequest(
            sceneIndex: scene.sceneIndex,
            selectedOption: selected,
            spokenText: spoken,
            responseTimeMs: elapsed
        )

        do {
            let response = try await api.respondToScene(assessmentId: aId, body: body)
            progress = response.progress

            // Show feedback
            lastFeedback = SceneFeedbackInfo(
                isCorrect: response.isCorrect,
                message: response.feedback
            )

            // Speak feedback
            speechService.speak(response.feedback)

            withAnimation(.spring()) {
                phase = .feedback
            }

            // Auto-advance after feedback
            try? await Task.sleep(nanoseconds: 2_500_000_000)

            if response.shouldContinue {
                await fetchNextScene()
            } else {
                await completeStoryAssessment()
            }
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }

    private func completeStoryAssessment() async {
        guard let aId = assessmentId else { return }

        do {
            let result = try await api.completeStory(assessmentId: aId)
            completionResult = result

            // Speak outro
            speechService.speak(result.outroNarration)

            withAnimation(.spring()) {
                phase = .completed
            }

            // Reload profiles
            await learningManager.loadProfiles()
        } catch {
            // Already completed or error — just dismiss
            withAnimation(.spring()) {
                phase = .completed
            }
        }
    }

    // MARK: - Voice Helpers

    private func startListeningForScene(scene: SceneResponse, targetWord: String) {
        if speechService.isSpeaking {
            speechService.onSpeechFinished = nil
            speechService.stop()
        }
        isListening = true
        spokenText = ""

        if targetWord.isEmpty {
            speechService.startListeningManual(targetWord: "") { _ in
                isListening = false
                let recognized = speechService.recognizedText
                spokenText = recognized

                if !recognized.isEmpty {
                    hasRecording = true
                    isEvaluating = true
                    Task {
                        await submitSceneResponse(scene: scene, selected: nil, spoken: recognized)
                        isEvaluating = false
                    }
                } else {
                    spokenText = "Could not hear clearly. Try again!"
                }
            }
        } else {
            speechService.startListening(targetWord: targetWord) { rating in
                isListening = false
                spokenText = speechService.recognizedText

                if rating > 0 {
                    hasRecording = true
                    let isCorrect = rating >= 3.0
                    let submittedText = isCorrect ? targetWord : spokenText
                    isEvaluating = true
                    Task {
                        await submitSceneResponse(scene: scene, selected: submittedText, spoken: spokenText)
                        isEvaluating = false
                    }
                } else {
                    spokenText = "Could not hear clearly. Try again!"
                }
            }
        }
    }
}

#Preview {
    StoryAssessmentView(storyId: "bunny_birthday")
        .environmentObject(AdaptiveLearningManager())
}
