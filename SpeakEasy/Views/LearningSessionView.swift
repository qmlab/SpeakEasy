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
    /// Whether the hint/clue is currently revealed
    @State private var showHint: Bool = false

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
                showHint = false
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
                    let isSorting = isSortingTask(task)
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

            // Image hint — show bigger for visual clarity.
            // Hide for image-grid tasks (identify/point_to) since all options
            // are already displayed as images — showing the answer image here
            // would give it away.
            // Also hide for pattern tasks since the sequence display replaces it.
            if let imageHint = task.content.imageHint, !imageHint.isEmpty,
               !isImageGridTask(task), !isPatternTask(task) {
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

    /// Whether this task is a visual pattern-finding task with a sequence of
    /// shape images.  Pattern tasks have a `sequence` array in the content.
    private func isPatternTask(_ task: AdaptiveTask) -> Bool {
        guard let seq = task.content.sequence, seq.count >= 2 else { return false }
        return true
    }

    @ViewBuilder
    private func contentArea(task: AdaptiveTask) -> some View {
        // Pattern sequence display — shows shape images in a row/grid with "?" placeholder
        if isPatternTask(task) {
            patternSequenceView(task: task)
        }

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
        // Also hide for pattern tasks since the sequence display replaces items.
        if let items = task.content.items, !items.isEmpty, !isSortingTask(task), !isPatternTask(task) {
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

    // MARK: - Pattern Sequence Display

    /// Renders the visual pattern sequence as a row or grid of shape images.
    /// Each item in the sequence is shown as an image; "?" is shown as a
    /// placeholder indicating the missing piece the child must identify.
    private func patternSequenceView(task: AdaptiveTask) -> some View {
        let seq = task.content.sequence ?? []
        let layout = task.content.gridLayout  // e.g. [3, 3] for a 3x3 grid

        return VStack(spacing: 12) {
            Text("🔍 Find the pattern!")
                .font(.headline)
                .foregroundColor(dimension.color)

            if let layout = layout, layout.count == 2 {
                // Grid layout (e.g. 2x2, 3x3)
                let cols = layout[0]
                let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: cols)
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(Array(seq.enumerated()), id: \.offset) { _, item in
                        patternItemView(item: item)
                    }
                }
            } else {
                // Horizontal row layout
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(seq.enumerated()), id: \.offset) { _, item in
                            patternItemView(item: item)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(dimension.color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(dimension.color.opacity(0.2), lineWidth: 1)
                )
        )
    }

    /// Renders a single item in the pattern sequence — either a shape image
    /// or a "?" placeholder for the missing piece.
    @ViewBuilder
    private func patternItemView(item: String) -> some View {
        if item == "?" {
            // Question mark placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(dimension.color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                            )
                            .foregroundColor(dimension.color)
                    )
                Text("?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(dimension.color)
            }
            .frame(width: 70, height: 70)
        } else {
            // Shape image from Cloudinary
            VStack(spacing: 2) {
                RemoteImageView(
                    objectName: item.lowercased().replacingOccurrences(of: " ", with: "_"),
                    imageType: .flashcard,
                    fallbackIcon: "square.dashed",
                    iconColor: dimension.color,
                    size: 60
                )
                .cornerRadius(8)
            }
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    /// Whether this task is a sorting/sequencing task that needs ordering UI.
    ///
    /// Triggers for:
    /// - Explicit ordering types: sort, sequence_order, build_sentence
    /// - Any task with an `items` array (the correct ordering) — this covers
    ///   social-behavior step-ordering tasks and memory-sequence tasks that
    ///   are typed as `identify` but need sequential multi-tap interaction.
    /// - Excludes pattern tasks (which have a `sequence` field) — those use
    ///   single-tap option selection, not multi-tap ordering.
    private func isSortingTask(_ task: AdaptiveTask) -> Bool {
        // Pattern tasks have items from steps but should NOT use ordering UI
        if isPatternTask(task) { return false }
        let type = task.taskType
        let explicitTypes = type == "sort" || type == "sequence_order" || type == "build_sentence"
        let hasItems = task.content.items != nil && !(task.content.items!.isEmpty)
        return (explicitTypes || hasItems) && task.content.displayOptions.count >= 2
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

        // Skip button — always available so the child can move on
        skipButton
    }

    private var skipButton: some View {
        Button {
            Task {
                await learningManager.submitAttempt(
                    isCorrect: false,
                    score: 0,
                    dimension: dimension
                )
            }
        } label: {
            Label("Skip", systemImage: "forward.fill")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .disabled(learningManager.isSubmitting)
        .padding(.top, 4)
    }

    // MARK: - Ordering Area (Sort / Sequence)

    /// Whether the ordering area should use an image-grid layout for the
    /// remaining options instead of a simple text list.
    ///
    /// Only returns `true` for visual task types (identify, point_to, etc.)
    /// whose options are likely to have matching Cloudinary images.
    /// Excludes build_sentence (words like "I", "am", "happy") and
    /// memory-sequence tasks (numbers like "3", "7") that have no images.
    private func isOrderingImageGrid(_ task: AdaptiveTask) -> Bool {
        let visualTypes: Set<String> = ["identify", "point_to", "match_word_image", "recognize_image", "match"]
        guard visualTypes.contains(task.taskType) else { return false }
        return task.content.displayOptions.allSatisfy { option in
            let words = option.split(separator: " ")
            return words.count == 1
                && !option.contains(",")
                && !option.contains("(")
                && !option.contains("/")
                && !option.contains("-")
        }
    }

    private func orderingArea(task: AdaptiveTask) -> some View {
        let options = task.content.displayOptions
        let remaining = options.filter { !orderedSelections.contains($0) }
        let useImageGrid = isOrderingImageGrid(task)

        return VStack(spacing: 16) {
            // Selected items (in order) — horizontal chips for compact display
            if !orderedSelections.isEmpty {
                VStack(spacing: 8) {
                    Text("Your order:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(orderedSelections.enumerated()), id: \.offset) { index, item in
                                HStack(spacing: 6) {
                                    Text("\(index + 1)")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                        .frame(width: 22, height: 22)
                                        .background(Circle().fill(dimension.color))
                                    if useImageGrid {
                                        RemoteImageView(
                                            objectName: item.lowercased().replacingOccurrences(of: " ", with: "_"),
                                            imageType: .thumbnail,
                                            fallbackIcon: "questionmark.circle",
                                            iconColor: dimension.color,
                                            size: 28
                                        )
                                        .cornerRadius(4)
                                    }
                                    Text(item)
                                        .font(.subheadline.bold())
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(dimension.color.opacity(0.15))
                                )
                            }
                            // Undo last selection
                            if !orderedSelections.isEmpty {
                                Button {
                                    orderedSelections.removeLast()
                                } label: {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
            }

            // Remaining options to pick from
            if !remaining.isEmpty {
                VStack(spacing: 8) {
                    Text(orderedSelections.isEmpty ? "Tap in order:" : "Next:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if useImageGrid {
                        // 2-column image grid for simple single-word options
                        let columns = [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ]
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(remaining, id: \.self) { option in
                                Button {
                                    handleOrderingTap(option: option, task: task)
                                } label: {
                                    VStack(spacing: 6) {
                                        RemoteImageView(
                                            objectName: option.lowercased().replacingOccurrences(of: " ", with: "_"),
                                            imageType: .flashcard,
                                            fallbackIcon: "questionmark.circle",
                                            iconColor: dimension.color,
                                            size: 80
                                        )
                                        .cornerRadius(12)
                                        Text(option)
                                            .font(.subheadline.bold())
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.secondarySystemBackground))
                                    )
                                }
                                .disabled(learningManager.isSubmitting)
                            }
                        }
                    } else {
                        // Text list for multi-word options
                        ForEach(remaining, id: \.self) { option in
                            Button {
                                handleOrderingTap(option: option, task: task)
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

    /// Handle tapping an option in the ordering area.
    private func handleOrderingTap(option: String, task: AdaptiveTask) {
        let options = task.content.displayOptions
        speechService.onSpeechFinished = nil
        speechService.speak(option)
        orderedSelections.append(option)
        // Auto-submit when all items selected
        if orderedSelections.count == options.count {
            let isCorrect: Bool
            if let correctItems = task.content.items, correctItems.count == orderedSelections.count {
                isCorrect = zip(orderedSelections, correctItems).allSatisfy { $0.lowercased() == $1.lowercased() }
            } else {
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

    /// Whether this task should display options as a visual image grid
    /// (identify / point_to tasks where the child picks from multiple images).
    ///
    /// Only shows the grid when ALL options are short, simple object names
    /// that are likely to have matching Cloudinary images.  Expanded
    /// question-bank tasks often have action-phrase options like
    /// "Tap star only" or "Miss or false alarm" — those fall back to
    /// the standard text-button layout.
    private func isImageGridTask(_ task: AdaptiveTask) -> Bool {
        // Pattern tasks always use image grid for options (shape images)
        if isPatternTask(task) && task.content.displayOptions.count >= 2 {
            return true
        }
        let visualTypes: Set<String> = ["identify", "point_to", "match_word_image", "recognize_image", "match"]
        guard visualTypes.contains(task.taskType),
              task.content.displayOptions.count >= 2 else {
            return false
        }
        // Every option must be a single word with no special characters.
        // This reliably keeps base-task options like "Dog", "Cat", "Ball"
        // and simple expanded options like "Happy", "Circle", "Star" in the
        // grid, while pushing multi-word action phrases ("Tap star only",
        // "Red circle", "Say sorry") to text buttons.
        return task.content.displayOptions.allSatisfy { option in
            let words = option.split(separator: " ")
            return words.count == 1
                && !option.contains(",")
                && !option.contains("(")
                && !option.contains("/")
                && !option.contains("-")
        }
    }

    @ViewBuilder
    private func optionButtons(task: AdaptiveTask) -> some View {
        if isImageGridTask(task) {
            imageGridOptions(task: task)
        } else {
            textOptionButtons(task: task)
        }
    }

    /// Image grid layout — shows each option as a tappable image card in a
    /// 2-column grid.  Used for identify / point_to tasks so the child can
    /// visually select the correct object.
    private func imageGridOptions(task: AdaptiveTask) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(task.content.displayOptions, id: \.self) { option in
                Button {
                    handleOptionTap(option: option, task: task)
                } label: {
                    VStack(spacing: 6) {
                        RemoteImageView(
                            objectName: option.lowercased().replacingOccurrences(of: " ", with: "_"),
                            imageType: .flashcard,
                            fallbackIcon: "questionmark.circle",
                            iconColor: dimension.color,
                            size: 100
                        )
                        .cornerRadius(12)

                        Text(option)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedOption == option ? dimension.color.opacity(0.2) : Color(.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedOption == option ? dimension.color : Color.clear, lineWidth: 3)
                    )
                }
                .disabled(learningManager.isSubmitting)
            }
        }
    }

    /// Traditional text-based option list with optional small thumbnails.
    private func textOptionButtons(task: AdaptiveTask) -> some View {
        VStack(spacing: 12) {
            ForEach(task.content.displayOptions, id: \.self) { option in
                Button {
                    handleOptionTap(option: option, task: task)
                } label: {
                    HStack(spacing: 12) {
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

    /// Shared handler for tapping an option (used by both image grid and text buttons).
    private func handleOptionTap(option: String, task: AdaptiveTask) {
        selectedOption = option
        speechService.onSpeechFinished = nil
        speechService.speak(option)
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
    }

    /// Whether to show the thumbnail image for a given option button (text mode).
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

        // Check if this is an open-ended task that should use AI evaluation
        let isOpenEnded = learningManager.currentTask?.content.openEnded == true

        if isOpenEnded {
            // For open-ended tasks, use manual stop mode so the child can
            // speak freely without early-stop on keyword match
            speechService.startListeningManual(targetWord: "") { rating in
                isListening = false
                let recognized = speechService.recognizedText
                spokenText = recognized

                if recognized.isEmpty {
                    hasRecording = false
                    spokenText = "Could not hear clearly. Try again!"
                    return
                }

                hasRecording = true
                isEvaluating = true

                // Call backend AI evaluation
                Task {
                    await evaluateOpenEndedResponse(spoken: recognized)
                    isEvaluating = false
                }
            }
        } else {
            speechService.startListening(targetWord: targetWord) { rating in
                isListening = false
                spokenText = speechService.recognizedText
                if rating > 0 {
                    hasRecording = true
                    let isCorrect = rating >= 3.0
                    if isCorrect {
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
                        speechRetryCount += 1
                        if speechRetryCount >= maxSpeechRetries {
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
                            spokenText = "Not quite! Try again (\(maxSpeechRetries - speechRetryCount) left)"
                        }
                    }
                } else {
                    hasRecording = false
                    spokenText = "Could not hear clearly. Try again!"
                }
            }
        }
    }

    /// Evaluate an open-ended response via the backend AI endpoint.
    private func evaluateOpenEndedResponse(spoken: String) async {
        guard let task = learningManager.currentTask else { return }
        let question = task.content.question ?? task.content.instructionText ?? task.content.instruction ?? ""

        do {
            let result = try await learningManager.api.evaluateOpenEnded(
                question: question,
                spoken: spoken,
                exampleAnswers: task.content.exampleAnswers,
                keywords: task.content.keywords
            )

            let score = Int(result.score * 5.0)
            await learningManager.submitAttempt(
                isCorrect: result.isAccepted,
                score: max(score, result.isAccepted ? 1 : 0),
                dimension: dimension
            )
        } catch {
            // If AI evaluation fails, be lenient — accept the response
            // as long as the child said something meaningful
            let wordCount = spoken.split(separator: " ").count
            let fallbackCorrect = wordCount >= 1
            await learningManager.submitAttempt(
                isCorrect: fallbackCorrect,
                score: fallbackCorrect ? 3 : 0,
                dimension: dimension
            )
        }
    }

    private func speechInputArea(task: AdaptiveTask) -> some View {
        let isOpenEnded = task.content.openEnded == true
        let targetWord = isOpenEnded ? "" : (task.content.targetWord ?? task.content.correctAnswer ?? "")

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

            // Help buttons: hear the word + show hint
            if !targetWord.isEmpty {
                HStack(spacing: 20) {
                    Button {
                        speechService.speak(targetWord)
                    } label: {
                        Label("Hear Again", systemImage: "speaker.wave.2")
                            .font(.subheadline)
                            .foregroundColor(dimension.color)
                    }
                    .disabled(isListening)

                    Button {
                        withAnimation { showHint = true }
                        // Also speak the hint aloud
                        speechService.speak(targetWord)
                    } label: {
                        Label("Hint", systemImage: "lightbulb")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .disabled(isListening || showHint)
                }

                // Reveal hint text
                if showHint {
                    Text("💡 \(targetWord)")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                        .transition(.scale.combined(with: .opacity))
                }
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
