//
//  LearningSessionView.swift
//  RisingStarKid
//
//  Active learning session: presents adaptive tasks, handles user responses,
//  shows ABA-based reinforcement (rewards, level-ups, confidence rebuilding).
//

import SwiftUI

struct LearningSessionView: View {
    let dimension: DevelopmentalDimension
    @EnvironmentObject var learningManager: AdaptiveLearningManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var speechService = SpeechService()
    @State private var selectedOption: String?
    @State private var spokenText: String = ""
    @State private var isListening: Bool = false
    @State private var hasRecording: Bool = false
    @State private var isEvaluating: Bool = false
    @State private var showSessionSummary: Bool = false
    @State private var animateReward: Bool = false
    @State private var showCameraView: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                dimension.color.opacity(0.05)
                    .ignoresSafeArea()

                if learningManager.isLoadingTask && learningManager.currentTask == nil {
                    loadingView
                } else if let task = learningManager.currentTask {
                    taskContentView(task: task)
                } else if showSessionSummary, let summary = learningManager.sessionSummary {
                    sessionSummaryView(summary: summary)
                } else {
                    startingView
                }

                // Reward overlay
                if learningManager.showReward && animateReward {
                    rewardOverlay
                }

                // Level up overlay
                if learningManager.showLevelUp {
                    levelUpOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task {
                            await learningManager.endSession()
                            showSessionSummary = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                            Text("Exit")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: dimension.icon)
                            .foregroundColor(dimension.color)
                        Text(dimension.label)
                            .fontWeight(.semibold)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(learningManager.currentStreak)")
                            .fontWeight(.bold)
                    }
                }
            }
            .task {
                await learningManager.startSession(dimension: dimension)
            }
            .onChange(of: learningManager.currentTask?.id) { _ in
                // Reset voice recording state for each new task
                hasRecording = false
                isEvaluating = false
                spokenText = ""
                selectedOption = nil
                if isListening {
                    speechService.stopListening()
                    isListening = false
                }
            }
            .onChange(of: learningManager.showReward) { newValue in
                if newValue {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        animateReward = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { animateReward = false }
                    }
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Getting ready...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Starting View

    private var startingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Starting session...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Task Content

    @ViewBuilder
    private func taskContentView(task: AdaptiveTask) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Task progress
                taskProgressBar

                // Task instruction
                instructionCard(task: task)

                // Content area based on task type
                contentArea(task: task)

                // Submit / interaction area
                interactionArea(task: task)

                // Feedback area
                if let result = learningManager.lastAttemptResult {
                    feedbackView(result: result)
                }
            }
            .padding()
        }
    }

    // MARK: - Task Progress Bar

    private var taskProgressBar: some View {
        HStack {
            Text("Task \(learningManager.sessionTaskCount + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            if let result = learningManager.lastAttemptResult {
                Text("Accuracy: \(Int(result.accuracy * 100))%")
                    .font(.caption)
                    .foregroundColor(result.accuracy >= 0.8 ? .green : .orange)
            }
        }
    }

    // MARK: - Instruction Card

    private func instructionCard(task: AdaptiveTask) -> some View {
        VStack(spacing: 12) {
            // Speak instruction aloud
            Button {
                speechService.speak(task.content.displayInstruction)
            } label: {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(dimension.color)
                    Spacer()
                }
            }

            Text(task.content.displayInstruction)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Image hint
            if let imageHint = task.content.imageHint, !imageHint.isEmpty {
                RemoteImageView(
                    objectName: imageHint,
                    imageType: .flashcard,
                    fallbackIcon: "photo",
                    iconColor: dimension.color,
                    size: 180
                )
                .cornerRadius(16)
            }

            // Target word display
            if let target = task.content.targetWord, !target.isEmpty {
                Text(target)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(dimension.color)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(dimension.color.opacity(0.1))
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        )
    }

    // MARK: - Content Area

    @ViewBuilder
    private func contentArea(task: AdaptiveTask) -> some View {
        // Story / passage display
        if let story = task.content.story, !story.isEmpty {
            Text(story)
                .font(.body)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                )
        }

        if let passage = task.content.passage, !passage.isEmpty {
            Text(passage)
                .font(.body)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                )
        }

        // Sentence display
        if let sentence = task.content.sentence, !sentence.isEmpty {
            Text(sentence)
                .font(.title3)
                .italic()
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(dimension.color.opacity(0.05))
                )
        }

        // Items display (for sorting, sequencing tasks)
        if let items = task.content.items, !items.isEmpty {
            VStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.body)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                }
            }
        }
    }

    // MARK: - Interaction Area

    /// Whether this task supports camera-based interaction (object cognition with target word)
    private func taskSupportsCamera(_ task: AdaptiveTask) -> Bool {
        dimension == .objectCognition &&
        task.content.targetWord != nil &&
        !task.content.targetWord!.isEmpty
    }

    @ViewBuilder
    private func interactionArea(task: AdaptiveTask) -> some View {
        let modalities = task.modalities

        // Camera button for object cognition tasks
        if taskSupportsCamera(task) {
            cameraButton(task: task)
        }

        // Option selection (touch modality)
        if !task.content.displayOptions.isEmpty {
            optionButtons(task: task)
        }

        // Speech input (voice modality)
        if modalities.contains("voice") {
            speechInputArea(task: task)
        }

        // Simple correct/incorrect buttons for tasks without specific interaction
        if task.content.displayOptions.isEmpty && !modalities.contains("voice") && !taskSupportsCamera(task) {
            simpleResponseButtons(task: task)
        }
    }

    // MARK: - Camera Button

    private func cameraButton(task: AdaptiveTask) -> some View {
        Button {
            showCameraView = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "camera.viewfinder")
                    .font(.title2)
                Text("Find with Camera")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [dimension.color, .green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .disabled(learningManager.isSubmitting)
        .fullScreenCover(isPresented: $showCameraView) {
            CameraLearningView(
                task: task,
                dimension: dimension
            ) { isCorrect, score in
                showCameraView = false
                Task {
                    await learningManager.submitAttempt(
                        isCorrect: isCorrect,
                        score: score,
                        dimension: dimension
                    )
                }
            }
        }
    }

    // MARK: - Option Buttons

    private func optionButtons(task: AdaptiveTask) -> some View {
        VStack(spacing: 12) {
            ForEach(task.content.displayOptions, id: \.self) { option in
                Button {
                    selectedOption = option
                    let isCorrect = option.lowercased() == (task.content.correctAnswer ?? "").lowercased()
                    Task {
                        await learningManager.submitAttempt(
                            isCorrect: isCorrect,
                            score: isCorrect ? 1 : 0,
                            dimension: dimension
                        )
                        selectedOption = nil
                    }
                } label: {
                    Text(option)
                        .font(.headline)
                        .foregroundColor(selectedOption == option ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedOption == option ? dimension.color : Color(.secondarySystemBackground))
                        )
                }
                .disabled(learningManager.isSubmitting)
            }
        }
    }

    // MARK: - Speech Input

    private func speechInputArea(task: AdaptiveTask) -> some View {
        let targetWord = task.content.targetWord ?? task.content.correctAnswer ?? ""

        return VStack(spacing: 12) {
            // Show recognized text
            if !spokenText.isEmpty {
                HStack {
                    Image(systemName: "quote.bubble.fill")
                        .foregroundColor(dimension.color)
                    Text("You said: \"\(spokenText)\"")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }

            // Live transcription while listening
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

            // Main mic button: 3 states
            Button {
                if isEvaluating { return }

                if isListening {
                    // State 2 -> Stop recording and evaluate
                    speechService.stopAndEvaluate()
                } else {
                    // State 1 or 3 -> Start recording
                    isListening = true
                    spokenText = ""
                    speechService.startListeningManual(targetWord: targetWord) { rating in
                        isListening = false
                        spokenText = speechService.recognizedText
                        if rating > 0 {
                            hasRecording = true
                            isEvaluating = true
                            let isCorrect = rating >= 3.0
                            Task {
                                await learningManager.submitAttempt(
                                    isCorrect: isCorrect,
                                    score: Int(rating),
                                    dimension: dimension
                                )
                                isEvaluating = false
                            }
                        } else {
                            hasRecording = false
                            spokenText = "Could not hear clearly. Try again!"
                        }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title)
                        .symbolEffect(.pulse, isActive: isListening)
                    Text(micButtonLabel)
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isListening ? Color.red : (hasRecording ? Color.orange : dimension.color))
                )
            }
            .disabled(learningManager.isSubmitting || isEvaluating)

            // Help: speak the target word
            if !targetWord.isEmpty {
                Button {
                    speechService.speak(targetWord)
                } label: {
                    Label("Hear the word", systemImage: "speaker.wave.2")
                        .font(.subheadline)
                        .foregroundColor(dimension.color)
                }
                .disabled(isListening)
            }
        }
    }

    /// Label for the mic button based on current state
    private var micButtonLabel: String {
        if isListening {
            return "Tap to Stop"
        } else if hasRecording {
            return "Say It Again"
        } else {
            return "Say It"
        }
    }

    // MARK: - Simple Response Buttons

    private func simpleResponseButtons(task: AdaptiveTask) -> some View {
        HStack(spacing: 16) {
            Button {
                Task {
                    await learningManager.submitAttempt(
                        isCorrect: true,
                        score: 1,
                        dimension: dimension
                    )
                }
            } label: {
                Label("Got It!", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green)
                    )
            }

            Button {
                Task {
                    await learningManager.submitAttempt(
                        isCorrect: false,
                        score: 0,
                        dimension: dimension
                    )
                }
            } label: {
                Label("Help", systemImage: "questionmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.orange)
                    )
            }
        }
        .disabled(learningManager.isSubmitting)
    }

    // MARK: - Feedback View

    private func feedbackView(result: AttemptResult) -> some View {
        HStack {
            Image(systemName: result.isCorrect ? "star.fill" : "arrow.counterclockwise")
                .foregroundColor(result.isCorrect ? .yellow : .orange)

            Text(result.isCorrect ? "Correct!" : (result.confidenceRebuild ? "Let's try an easier one" : "Try again!"))
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            if result.isCorrect {
                HStack(spacing: 2) {
                    ForEach(0..<min(result.streak, 5), id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(result.isCorrect ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        )
    }

    // MARK: - Reward Overlay

    private var rewardOverlay: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 60))

                Text(learningManager.rewardMessage)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(dimension.color.gradient)
            )
            .scaleEffect(animateReward ? 1 : 0.5)
            .opacity(animateReward ? 1 : 0)

            Spacer()
        }
        .background(Color.black.opacity(0.3))
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Level Up Overlay

    private var levelUpOverlay: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Text("⬆️")
                    .font(.system(size: 60))
                Text("Level Up!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [dimension.color, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )

            Spacer()
        }
        .background(Color.black.opacity(0.4))
        .ignoresSafeArea()
        .onTapGesture {
            learningManager.showLevelUp = false
        }
    }

    // MARK: - Session Summary

    private func sessionSummaryView(summary: EndSessionResponse) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🌟")
                .font(.system(size: 64))

            Text("Great Session!")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                summaryRow(label: "Tasks Completed", value: "\(summary.tasksCompleted)")
                summaryRow(label: "Correct", value: "\(summary.correctCount) / \(summary.totalCount)")
                summaryRow(label: "Accuracy", value: "\(Int(summary.accuracy * 100))%")
                if summary.levelChange > 0 {
                    summaryRow(label: "Level Up!", value: "+\(summary.levelChange)")
                }
                summaryRow(label: "Rewards Earned", value: "\(summary.rewardsEarned)")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            )

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(dimension.color)
                    )
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    LearningSessionView(dimension: .objectCognition)
        .environmentObject(AdaptiveLearningManager())
}
