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
    @State private var animateFeedback: Bool = false
    @State private var showCameraView: Bool = false
    /// Number of incorrect speech attempts on the current task (max 3 before auto-advance)
    @State private var speechRetryCount: Int = 0
    /// Maximum retries allowed for incorrect speech answers
    private let maxSpeechRetries = 3
    /// Ordered selections for sorting/sequencing tasks
    @State private var orderedSelections: [String] = []

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
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.secondary)
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
            .onChange(of: learningManager.currentTask?.taskId) { _ in
                // Reset voice recording state for each new task
                hasRecording = false
                isEvaluating = false
                spokenText = ""
                selectedOption = nil
                speechRetryCount = 0
                orderedSelections = []
                animateFeedback = false
                if isListening {
                    speechService.stopListening()
                    isListening = false
                }
                // Always clear the TTS callback first so a stale closure
                // from the previous task cannot fire (e.g. when the session
                // ends and currentTask becomes nil while TTS is still playing).
                speechService.onSpeechFinished = nil

                // Auto-speak the instruction so illiterate kids can understand.
                // When TTS finishes, auto-enter listening for voice tasks.
                if let task = learningManager.currentTask {
                    let targetWord = task.content.targetWord ?? task.content.correctAnswer ?? ""
                    // Auto-listen after TTS for ALL tasks with a speakable target
                    // word (not just voice-modality tasks).  Skip sorting/sequencing
                    // tasks where ordering is the goal, not speaking.
                    let taskType = task.taskType
                    let isSorting = (taskType == "sort" || taskType == "sequence_order")
                    if !targetWord.isEmpty && !isSorting {
                        speechService.onSpeechFinished = { [self] in
                            // Clear the callback so it doesn't fire again for
                            // "Hear Again" or target-word taps.
                            speechService.onSpeechFinished = nil
                            startListeningForTask(targetWord: targetWord)
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        speechService.speak(task.content.displayInstruction)
                    }
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
        ZStack {
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
                }
                .padding()
            }

            // Feedback overlay (prominent, centered)
            if let result = learningManager.lastAttemptResult {
                feedbackOverlay(result: result)
                    .id(result.attemptId)
            }
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
            // Tap-to-speak instruction button (prominent for illiterate kids)
            Button {
                speechService.speak(task.content.displayInstruction)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("Hear Again")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(dimension.color)
                )
            }

            Text(task.content.displayInstruction)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Image hint — show bigger for visual clarity
            if let imageHint = task.content.imageHint, !imageHint.isEmpty {
                RemoteImageView(
                    objectName: imageHint,
                    imageType: .flashcard,
                    fallbackIcon: "photo",
                    iconColor: dimension.color,
                    size: 200
                )
                .cornerRadius(16)
            }

            // Target word display with speaker icon so kid can tap to hear it
            if let target = task.content.targetWord, !target.isEmpty {
                Button {
                    speechService.speak(target)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.2")
                            .font(.title3)
                        Text(target)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(dimension.color)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(dimension.color.opacity(0.1))
                    )
                }
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

        // Items display (for non-sorting tasks only — sorting tasks show items in orderingArea)
        if let items = task.content.items, !items.isEmpty, !isSortingTask(task) {
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

    /// Whether this task is a sorting/sequencing task that needs ordering UI
    private func isSortingTask(_ task: AdaptiveTask) -> Bool {
        let type = task.taskType
        return (type == "sort" || type == "sequence_order") &&
               task.content.displayOptions.count >= 3
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
        // Camera button for object cognition tasks
        if taskSupportsCamera(task) {
            cameraButton(task: task)
        }

        // Sorting/sequencing tasks get ordering UI
        if isSortingTask(task) {
            orderingArea(task: task)
        }
        // Regular option selection (touch modality)
        else if !task.content.displayOptions.isEmpty {
            optionButtons(task: task)
        }

        // Speech input — available for ALL tasks with a speakable target word,
        // not just tasks whose modalities include "voice".  This lets children
        // practice pronunciation across every dimension.
        let effectiveTarget = task.content.targetWord ?? task.content.correctAnswer ?? ""
        if !effectiveTarget.isEmpty && !isSortingTask(task) {
            speechInputArea(task: task)
        }

        // Simple correct/incorrect buttons for tasks without any interactive input
        if task.content.displayOptions.isEmpty && effectiveTarget.isEmpty && !taskSupportsCamera(task) && !isSortingTask(task) {
            simpleResponseButtons(task: task)
        }
    }

    // MARK: - Ordering Area (Sort / Sequence)

    private func orderingArea(task: AdaptiveTask) -> some View {
        let options = task.content.displayOptions
        let remaining = options.filter { !orderedSelections.contains($0) }

        return VStack(spacing: 16) {
            // Selected items (in order)
            if !orderedSelections.isEmpty {
                VStack(spacing: 8) {
                    Text("Your order:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(Array(orderedSelections.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(dimension.color))
                            Text(item)
                                .font(.headline)
                            Spacer()
                            // Undo button
                            if index == orderedSelections.count - 1 {
                                Button {
                                    orderedSelections.removeLast()
                                } label: {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(dimension.color.opacity(0.1))
                        )
                    }
                }
            }

            // Remaining options to pick from
            if !remaining.isEmpty {
                VStack(spacing: 8) {
                    Text(orderedSelections.isEmpty ? "Tap in order:" : "Next:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(remaining, id: \.self) { option in
                        Button {
                            // Speak the option text so the child learns pronunciation
                            // Clear any pending auto-listen callback so option TTS finishing
                            // doesn't accidentally start the microphone.
                            speechService.onSpeechFinished = nil
                            speechService.speak(option)
                            orderedSelections.append(option)
                            // Auto-submit when all items selected
                            if orderedSelections.count == options.count {
                                // Validate full ordering against items (correct order) or correct_answer (first item fallback)
                                let isCorrect: Bool
                                if let correctItems = task.content.items, correctItems.count == orderedSelections.count {
                                    // Full order validation: compare user's sequence against correct items order
                                    isCorrect = zip(orderedSelections, correctItems).allSatisfy { $0.lowercased() == $1.lowercased() }
                                } else {
                                    // Fallback: at least check first item matches correct_answer
                                    let correctFirst = task.content.correctAnswer ?? ""
                                    isCorrect = orderedSelections.first?.lowercased() == correctFirst.lowercased()
                                }
                                Task {
                                    await learningManager.submitAttempt(
                                        isCorrect: isCorrect,
                                        score: isCorrect ? 1 : 0,
                                        dimension: dimension
                                    )
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                RemoteImageView(
                                    objectName: option.lowercased().replacingOccurrences(of: " ", with: "_"),
                                    imageType: .thumbnail,
                                    fallbackIcon: "questionmark.circle",
                                    iconColor: dimension.color,
                                    size: 40
                                )
                                .cornerRadius(8)
                                Text(option)
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(dimension.color)
                            }
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                        .disabled(learningManager.isSubmitting)
                    }
                }
            }

            // Reset button
            if orderedSelections.count > 1 {
                Button {
                    orderedSelections = []
                } label: {
                    Label("Start Over", systemImage: "arrow.counterclockwise")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
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
                    // Speak the option text so the child learns pronunciation
                    // Clear any pending auto-listen callback so option TTS finishing
                    // doesn't accidentally start the microphone.
                    speechService.onSpeechFinished = nil
                    speechService.speak(option)
                    // Stop any active listening so voice input doesn't race
                    // with the tap submission.
                    if isListening {
                        speechService.stopListening()
                        isListening = false
                    }
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
                    HStack(spacing: 12) {
                        // Difficulty-based option image display:
                        // Level 0: show all images (visual matching, easiest)
                        // Level 1-2: hide the image that matches the question
                        //            image so the child can't just match visually
                        // Level 3+: hide all option images (text-only, hardest)
                        if shouldShowOptionImage(task: task, option: option) {
                            RemoteImageView(
                                objectName: option.lowercased().replacingOccurrences(of: " ", with: "_"),
                                imageType: .thumbnail,
                                fallbackIcon: "questionmark.circle",
                                iconColor: dimension.color,
                                size: 48
                            )
                            .cornerRadius(8)
                        }
                        Text(option)
                            .font(.headline)
                    }
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

    /// Whether to show the thumbnail image for a given option button.
    ///
    /// Difficulty progression for option images:
    /// - **Level 0** (easiest): show all images — visual matching is allowed.
    /// - **Level 1–2**: hide the image whose key matches the question's
    ///   `imageHint` so the child cannot simply match pictures.
    /// - **Level 3+** (hardest): hide all option images — text only.
    private func shouldShowOptionImage(task: AdaptiveTask, option: String) -> Bool {
        if task.level >= 3 { return false }
        if task.level >= 1, let imageHint = task.content.imageHint {
            let optionKey = option.lowercased().replacingOccurrences(of: " ", with: "_")
            if optionKey == imageHint.lowercased() { return false }
        }
        return true
    }

    // MARK: - Speech Input

    /// Start listening for speech and handle the result (shared by button tap and auto-start).
    private func startListeningForTask(targetWord: String) {
        // Stop any ongoing TTS so the mic can activate
        if speechService.isSpeaking {
            speechService.onSpeechFinished = nil   // prevent callback loop
            speechService.stop()
        }
        isListening = true
        spokenText = ""
        speechService.startListening(targetWord: targetWord) { rating in
            isListening = false
            spokenText = speechService.recognizedText
            if rating > 0 {
                hasRecording = true
                let isCorrect = rating >= 3.0
                if isCorrect {
                    // Correct — submit and auto-advance (submitAttempt already
                    // shows feedback + fetches the next task after a delay).
                    isEvaluating = true
                    Task {
                        await learningManager.submitAttempt(
                            isCorrect: true,
                            score: Int(rating),
                            dimension: dimension
                        )
                        isEvaluating = false
                    }
                } else {
                    // Incorrect
                    speechRetryCount += 1
                    if speechRetryCount >= maxSpeechRetries {
                        // Out of retries — submit as incorrect and move on
                        isEvaluating = true
                        Task {
                            await learningManager.submitAttempt(
                                isCorrect: false,
                                score: Int(rating),
                                dimension: dimension
                            )
                            isEvaluating = false
                        }
                    } else {
                        // Still has retries — show feedback and let user try again
                        spokenText = "Not quite! Try again (\(maxSpeechRetries - speechRetryCount) left)"
                    }
                }
            } else {
                hasRecording = false
                spokenText = "Could not hear clearly. Try again!"
            }
        }
    }

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

            // Main mic button
            Button {
                if isEvaluating { return }

                if isListening {
                    // Already listening -> stop and evaluate
                    speechService.stopAndEvaluate()
                } else {
                    // Not listening -> if TTS is still playing, interrupt it
                    startListeningForTask(targetWord: targetWord)
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title)
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

            // Retry counter
            if speechRetryCount > 0 && speechRetryCount < maxSpeechRetries && !isListening {
                Text("Attempt \(speechRetryCount)/\(maxSpeechRetries)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

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
            return "Listening..."
        } else if hasRecording || speechRetryCount > 0 {
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

    // MARK: - Feedback Overlay

    private func feedbackOverlay(result: AttemptResult) -> some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                // Big icon
                Image(systemName: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(result.isCorrect ? .green : .red)

                Text(result.isCorrect ? "Correct!" : (result.confidenceRebuild ? "Let's try easier" : "Try again!"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(result.isCorrect ? .green : .red)

                // Stars for streaks
                if result.isCorrect && result.streak > 0 {
                    HStack(spacing: 4) {
                        ForEach(0..<min(result.streak, 5), id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.title3)
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
            )
            .scaleEffect(animateFeedback ? 1 : 0.5)
            .opacity(animateFeedback ? 1 : 0)

            Spacer()
        }
        .background(Color.black.opacity(animateFeedback ? 0.2 : 0))
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            animateFeedback = false
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                animateFeedback = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { animateFeedback = false }
            }
        }
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
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)
                    .shadow(color: .yellow.opacity(0.6), radius: 12)

                Text("Level Up!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Great job! Keep going!")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [dimension.color, dimension.color.opacity(0.7), .yellow.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: dimension.color.opacity(0.4), radius: 20, y: 10)
            )
            .padding(.horizontal, 40)
        }
        .onTapGesture {
            learningManager.showLevelUp = false
        }
    }

    // MARK: - Session Summary

    private func sessionSummaryView(summary: EndSessionResponse) -> some View {
        VStack(spacing: 24) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)

            Spacer()

            Image(systemName: "star.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.yellow)

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
        .navigationBarHidden(true)
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
