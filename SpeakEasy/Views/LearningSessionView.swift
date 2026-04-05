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
    /// Ordered selections for sorting/sequencing tasks
    @State private var orderedSelections: [String] = []
    /// Whether the hint/clue is currently revealed
    @State private var showHint: Bool = false
    /// Animation slideshow state
    @State private var animationFrameIndex: Int = 0
    @State private var animationFinished: Bool = false
    @State private var animationTimer: Timer?
    /// Multi-tap counting state (for go/no-go, sustained attention tasks)
    @State private var multiTapCount: Int = 0
    /// Text/number input state (for counting and fill-in-the-word tasks)
    @State private var textInputValue: String = ""
    /// Flash image state (for visual memory tasks like "Watch the light flash")
    @State private var flashVisible: Bool = false
    @State private var flashPhase: Int = 0  // current index in flash_sequence
    @State private var flashCompleted: Bool = false
    /// Generation counter to invalidate stale DispatchQueue callbacks on task change
    @State private var flashGeneration: Int = 0
    /// Drag-to-arrange state: current arrangement of shape options
    @State private var dragArrangeItems: [String] = []
    /// The item currently being dragged
    @State private var draggedItem: String?
    /// Drag offset for the currently dragged item
    @State private var dragOffset: CGSize = .zero
    /// Cumulative offset consumed by completed swaps (prevents cascading swaps)
    @State private var dragSwapConsumed: CGFloat = 0
    /// Drag-to-category sorting state: maps category name -> array of sorted item names
    @State private var categorySortBuckets: [String: [String]] = [:]
    /// The item currently being dragged in category sort
    @State private var dragSortItem: String?
    /// Drag offset for category sort item
    @State private var dragSortOffset: CGSize = .zero
    /// Position anchors for category drop zones (category name -> frame)
    @State private var categoryFrames: [String: CGRect] = [:]
    /// Position anchor for unsorted items pool
    @State private var unsortedPoolFrame: CGRect = .zero

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
                orderedSelections = []
                animateFeedback = false
                showHint = false
                multiTapCount = 0
                textInputValue = ""
                // Reset drag arrange state
                dragArrangeItems = []
                draggedItem = nil
                dragOffset = .zero
                dragSwapConsumed = 0
                // Reset drag-to-category sort state
                categorySortBuckets = [:]
                dragSortItem = nil
                dragSortOffset = .zero
                categoryFrames = [:]
                // Reset flash state
                flashVisible = false
                flashPhase = 0
                flashCompleted = false
                flashGeneration += 1
                // Reset animation slideshow state
                animationTimer?.invalidate()
                animationTimer = nil
                animationFrameIndex = 0
                animationFinished = false
                // Restart animation if the new task is also animated
                if let newTask = learningManager.currentTask,
                   isAnimatedTask(newTask),
                   let frames = newTask.content.animationFrames {
                    startAnimationSlideshow(frames: frames)
                }
                // Restart flash sequence if the new task is a flash task
                // (onAppear won't re-fire when SwiftUI reuses the view)
                if let newTask = learningManager.currentTask, isFlashTask(newTask) {
                    let images: [String] = {
                        if let seq = newTask.content.flashSequence, !seq.isEmpty { return seq }
                        if let img = newTask.content.flashImage, !img.isEmpty { return [img] }
                        return []
                    }()
                    startFlashSequence(images: images)
                }
                // Initialize drag arrange items in shuffled order
                if let newTask = learningManager.currentTask, isDragArrangeTask(newTask) {
                    initDragArrangeItems(task: newTask)
                }
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
                    let isMultiTap = isMultiTapTask(task)
                    let isTextInput = isTextInputTask(task)
                    let isFlash = isFlashTask(task)
                    let isDragArrange = isDragArrangeTask(task)
                    let isDragSort = isDragSortTask(task)
                    let isMultiSel = isMultiSelectTask(task)
                    if !targetWord.isEmpty && !isSorting && !isMultiTap && !isTextInput && !isFlash && !isDragArrange && !isDragSort && !isMultiSel {
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

    /// Whether this task uses simple option selection (tappable buttons/images)
    /// that should be pinned at the bottom of the screen for easy access.
    /// Complex interactions (drag, sort, ordering, multi-tap, text input)
    /// stay in the scrollable area because they need more vertical space.
    private func isPinnedInteractionTask(_ task: AdaptiveTask) -> Bool {
        if isDragArrangeTask(task) || isDragSortTask(task) || isSortingTask(task)
            || isMultiTapTask(task) || isTextInputTask(task)
            || isMultiSelectTask(task) {
            return false
        }
        // For flash tasks, only pin once flash animation is complete
        if isFlashTask(task) && !flashCompleted {
            return false
        }
        // Must have tappable options
        guard !task.content.displayOptions.isEmpty else { return false }
        // Only pin when there's enough visual content above the options
        // (image, animation, flash, pattern, story, etc.) to justify the
        // split layout.  For short instruction-only tasks (e.g. "Tap A.
        // Do not tap B.") pinning creates an awkward large gap.
        if !hasVisualContentAboveOptions(task) {
            return false
        }
        return true
    }

    /// Whether the task renders substantial visual content (image, animation,
    /// pattern, story, etc.) above the option buttons.  When this returns
    /// `false` the instruction card is short text only, so pinning the
    /// options at the bottom would leave an ugly empty gap.
    private func hasVisualContentAboveOptions(_ task: AdaptiveTask) -> Bool {
        // instructionCard renders a large image from questionImage
        if let qi = task.content.questionImage, !qi.isEmpty { return true }
        // instructionCard renders a large image from imageHint (unless suppressed)
        if let ih = task.content.imageHint, !ih.isEmpty,
           !isImageGridTask(task), !isPatternTask(task),
           task.content.inlineImages != true {
            return true
        }
        // instructionCard renders a targetWord display
        if let tw = task.content.targetWord, !tw.isEmpty { return true }
        // contentArea renders flash / animation / pattern / story / passage / sentence
        if isFlashTask(task) || isAnimatedTask(task) || isPatternTask(task) { return true }
        if let s = task.content.story, !s.isEmpty { return true }
        if let p = task.content.passage, !p.isEmpty { return true }
        if let s = task.content.sentence, !s.isEmpty { return true }
        if let items = task.content.items, !items.isEmpty,
           !isSortingTask(task), !isPatternTask(task), !isDragArrangeTask(task) { return true }
        return false
    }

    @ViewBuilder
    private func taskContentView(task: AdaptiveTask) -> some View {
        ZStack {
            if isPinnedInteractionTask(task) {
                // Pinned layout: question scrolls at top, options fixed at bottom
                GeometryReader { geo in
                    let maxPinnedHeight = geo.size.height * 0.45
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(spacing: 24) {
                                taskProgressBar
                                instructionCard(task: task)
                                contentArea(task: task)
                            }
                            .padding()
                        }

                        // Pinned interaction area at bottom — capped so it
                        // never pushes the image out of the scroll area.
                        ScrollView {
                            VStack(spacing: 12) {
                                interactionArea(task: task)
                            }
                        }
                        .frame(maxHeight: maxPinnedHeight)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(
                            Color(.systemBackground)
                                .shadow(color: .black.opacity(0.06), radius: 4, y: -2)
                        )
                    }
                }
            } else {
                // Original scrollable layout for complex interactions
                ScrollView {
                    VStack(spacing: 24) {
                        taskProgressBar
                        instructionCard(task: task)
                        contentArea(task: task)
                        interactionArea(task: task)
                    }
                    .padding()
                }
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
            // EXCEPTION: When the instruction references looking at a picture
            // (e.g. "What is in this picture?", "What is this?"), the image IS
            // the question and must always be shown even for image grid tasks.
            // Also hide for pattern tasks since the sequence display replaces it.
            // Also hide for inline-image tasks since each option button already
            // shows a shape/color thumbnail — no big image needed above.
            //
            // "Find the same one" tasks: if `questionImage` is set, show that
            // alternate image instead of `imageHint` so the child cannot simply
            // match pictures.  The option buttons still use the original images.
            // Use smaller images when options are pinned at the bottom
            // to keep the question area compact and avoid hiding the options.
            let isPinned = isPinnedInteractionTask(task)
            let imageSize: CGFloat = isPinned ? 160 : 200
            let instructionRefsPicture = instructionReferencesPicture(task)

            if let questionImg = task.content.questionImage, !questionImg.isEmpty,
               !isPatternTask(task), !isDragArrangeTask(task) {
                RemoteImageView(
                    objectName: questionImg,
                    imageType: .flashcard,
                    fallbackIcon: "photo",
                    iconColor: dimension.color,
                    size: imageSize
                )
                .cornerRadius(16)
            } else if let imageHint = task.content.imageHint, !imageHint.isEmpty,
               (!isImageGridTask(task) || instructionRefsPicture),
               !isPatternTask(task),
               task.content.inlineImages != true {
                RemoteImageView(
                    objectName: imageHint,
                    imageType: .flashcard,
                    fallbackIcon: "photo",
                    iconColor: dimension.color,
                    size: imageSize
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

    /// Whether the task instruction references looking at a picture or image.
    /// When true, the image_hint must be shown even for image grid tasks
    /// because the image IS the question (e.g. "What is in this picture?").
    private func instructionReferencesPicture(_ task: AdaptiveTask) -> Bool {
        let text = task.content.displayInstruction.lowercased()
        let phrases = [
            "this picture", "the picture", "this image", "the image",
            "this photo", "the photo", "what is this", "what do you see",
            "what is in this", "tell me about this", "name this"
        ]
        return phrases.contains(where: { text.contains($0) })
    }

    /// Whether this task is a visual pattern-finding task with a sequence of
    /// shape images.  Pattern tasks have a `sequence` array in the content.
    private func isPatternTask(_ task: AdaptiveTask) -> Bool {
        guard let seq = task.content.sequence, seq.count >= 2 else { return false }
        return true
    }

    /// Whether this task has animation frames (n-back, working memory, attention tasks).
    private func isAnimatedTask(_ task: AdaptiveTask) -> Bool {
        guard let frames = task.content.animationFrames, frames.count >= 1 else { return false }
        // Don't treat as animated if it's also a pattern task (sequence takes priority)
        if isPatternTask(task) { return false }
        // Don't treat as animated if it's a flash task — the flash display replaces it
        if isFlashTask(task) { return false }
        return true
    }

    /// Whether this task is a visual flash memory task (flash a shape/color
    /// image briefly, then hide it — child picks from options by memory).
    private func isFlashTask(_ task: AdaptiveTask) -> Bool {
        if let fi = task.content.flashImage, !fi.isEmpty { return true }
        if let fs = task.content.flashSequence, !fs.isEmpty { return true }
        return false
    }

    @ViewBuilder
    private func contentArea(task: AdaptiveTask) -> some View {
        // Flash image display — shows a shape/color image briefly then hides it
        if isFlashTask(task) {
            flashDisplayView(task: task)
        }

        // Animated slideshow display — shows frames one at a time for attention/memory tasks
        if isAnimatedTask(task) {
            animatedSequenceView(task: task)
        }

        // Pattern sequence display — shows shape images in a row/grid with "?" placeholder
        if isPatternTask(task) && !isAnimatedTask(task) {
            patternSequenceView(task: task)
        }

        // Story / passage display with optional image
        if let story = task.content.story, !story.isEmpty {
            VStack(spacing: 12) {
                // Show image hint alongside story for visual context
                if let hint = task.content.imageHint, !hint.isEmpty {
                    RemoteImageView(
                        objectName: hint.lowercased().replacingOccurrences(of: " ", with: "_"),
                        imageType: .flashcard,
                        fallbackIcon: "book.fill",
                        iconColor: dimension.color,
                        size: 60
                    )
                    .cornerRadius(12)
                }
                Text(story)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )
        }

        if let passage = task.content.passage, !passage.isEmpty {
            VStack(spacing: 12) {
                if let hint = task.content.imageHint, !hint.isEmpty {
                    RemoteImageView(
                        objectName: hint.lowercased().replacingOccurrences(of: " ", with: "_"),
                        imageType: .flashcard,
                        fallbackIcon: "book.fill",
                        iconColor: dimension.color,
                        size: 60
                    )
                    .cornerRadius(12)
                }
                Text(passage)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
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
        if let items = task.content.items, !items.isEmpty, !isSortingTask(task), !isPatternTask(task), !isDragArrangeTask(task) {
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

    // MARK: - Animated Sequence Display

    /// Renders a timed slideshow of image frames for attention/memory tasks.
    /// Each frame is shown for ~1.5 seconds with a crossfade, then options appear.
    /// For multi-tap tasks, tapping the slide itself counts as a tap.
    private func animatedSequenceView(task: AdaptiveTask) -> some View {
        let frames = task.content.animationFrames ?? []
        let totalFrames = frames.count
        let isTappable = isMultiTapTask(task)

        return VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: animationFinished ? "checkmark.circle.fill" : "play.circle.fill")
                    .font(.title3)
                Text(animationFinished ? "Now answer!" : "Watch carefully!")
                    .font(.headline)
            }
            .foregroundColor(dimension.color)

            // Frame display area
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: isTappable ? 200 : 140)

                if animationFinished {
                    // Show all frames in a row after animation finishes
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(frames.enumerated()), id: \.offset) { idx, frame in
                                VStack(spacing: 4) {
                                    RemoteImageView(
                                        objectName: frame.lowercased().replacingOccurrences(of: " ", with: "_"),
                                        imageType: .flashcard,
                                        fallbackIcon: "square.dashed",
                                        iconColor: dimension.color,
                                        size: 50
                                    )
                                    .cornerRadius(8)
                                    Text("\(idx + 1)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 60, height: 70)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.tertiarySystemBackground))
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                } else if animationFrameIndex < totalFrames {
                    // Show current frame with animation
                    VStack(spacing: 8) {
                        RemoteImageView(
                            objectName: frames[animationFrameIndex].lowercased()
                                .replacingOccurrences(of: " ", with: "_"),
                            imageType: .flashcard,
                            fallbackIcon: "square.dashed",
                            iconColor: dimension.color,
                            size: isTappable ? 120 : 80
                        )
                        .cornerRadius(12)
                        .id("frame_\(animationFrameIndex)")
                        .transition(.opacity.combined(with: .scale))

                        // Progress dots
                        HStack(spacing: 6) {
                            ForEach(0..<totalFrames, id: \.self) { idx in
                                Circle()
                                    .fill(idx == animationFrameIndex
                                          ? dimension.color
                                          : dimension.color.opacity(0.2))
                                    .frame(width: 8, height: 8)
                            }
                        }

                        // Tap hint for multi-tap tasks
                        if isTappable {
                            Text("Tap here when you see the target!")
                                .font(.caption)
                                .foregroundColor(dimension.color.opacity(0.7))
                        }
                    }
                    .animation(.easeInOut(duration: 0.4), value: animationFrameIndex)
                }
            }
            // Tap gesture for multi-tap tasks — tap the slide to count
            .contentShape(Rectangle())
            .onTapGesture {
                guard isTappable, !animationFinished, !learningManager.isSubmitting else { return }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    multiTapCount += 1
                }
            }

            // Step counter
            if !animationFinished {
                Text("Step \(min(animationFrameIndex + 1, totalFrames)) of \(totalFrames)")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
        .onAppear {
            startAnimationSlideshow(frames: frames)
        }
        .onDisappear {
            animationTimer?.invalidate()
            animationTimer = nil
        }
    }

    /// Starts the timed slideshow for animation frames.
    private func startAnimationSlideshow(frames: [String]) {
        animationFrameIndex = 0
        animationFinished = false
        animationTimer?.invalidate()

        guard !frames.isEmpty else {
            animationFinished = true
            return
        }

        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            if animationFrameIndex < frames.count - 1 {
                withAnimation {
                    animationFrameIndex += 1
                }
            } else {
                timer.invalidate()
                animationTimer = nil
                withAnimation {
                    animationFinished = true
                }
            }
        }
    }

    // MARK: - Flash Image Display

    /// Shows a shape/color image briefly (1.5s each) then hides it.
    /// For `flash_image` — a single image flash.
    /// For `flash_sequence` — multiple images shown one after another.
    @ViewBuilder
    private func flashDisplayView(task: AdaptiveTask) -> some View {
        let images: [String] = {
            if let seq = task.content.flashSequence, !seq.isEmpty { return seq }
            if let img = task.content.flashImage, !img.isEmpty { return [img] }
            return []
        }()
        let isTappable = isMultiTapTask(task)

        VStack(spacing: 16) {
            if !flashCompleted {
                // Show the current flash image
                if flashPhase < images.count && flashVisible {
                    let currentImage = images[flashPhase]
                    VStack(spacing: 8) {
                        Text("👀 Watch carefully!")
                            .font(.headline)
                            .foregroundColor(dimension.color)

                        RemoteImageView(
                            objectName: currentImage,
                            imageType: .flashcard,
                            fallbackIcon: "eye.fill",
                            iconColor: dimension.color,
                            size: isTappable ? 200 : 180
                        )
                        .cornerRadius(16)
                        .transition(.scale.combined(with: .opacity))

                        if images.count > 1 {
                            Text("\(flashPhase + 1) of \(images.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // Tap hint for multi-tap tasks
                        if isTappable {
                            Text("Tap here when you see the target!")
                                .font(.caption)
                                .foregroundColor(dimension.color.opacity(0.7))
                        }
                    }
                } else if !flashVisible && !flashCompleted {
                    // Brief blank between flashes or before start
                    VStack(spacing: 8) {
                        Text("👀 Watch carefully!")
                            .font(.headline)
                            .foregroundColor(dimension.color)
                        ProgressView()
                            .scaleEffect(1.2)
                    }
                }
            } else {
                // Flash completed — prompt child to recall
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(dimension.color)
                    Text("What did you see?")
                        .font(.headline)
                        .foregroundColor(dimension.color)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(dimension.color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(dimension.color.opacity(0.2), lineWidth: 1)
                )
        )
        // Tap gesture for multi-tap tasks — tap the slide to count
        .contentShape(Rectangle())
        .onTapGesture {
            guard isTappable, !flashCompleted, !learningManager.isSubmitting else { return }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                multiTapCount += 1
            }
        }
        .onAppear {
            // Guard: do NOT restart if the flash already completed.
            // When flashCompleted flips to true the layout switches from
            // scrollable → pinned, which re-parents this view and fires
            // onAppear again.  Without this guard the sequence restarts
            // in an infinite loop and options never appear.
            if !flashCompleted {
                startFlashSequence(images: images)
            }
        }
    }

    /// Starts the timed flash sequence.  Shows each image for 1.5 seconds with
    /// a 0.4 second blank gap between them.
    private func startFlashSequence(images: [String]) {
        guard !images.isEmpty else {
            flashCompleted = true
            return
        }
        // Increment generation to invalidate any previously scheduled callbacks
        // (handles the case where both onChange and onAppear call this method)
        flashGeneration += 1
        flashPhase = 0
        flashVisible = false
        flashCompleted = false
        let gen = flashGeneration

        // Small delay before first flash
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard flashGeneration == gen else { return }
            showNextFlash(images: images, generation: gen)
        }
    }

    /// Shows the next flash image, waits 1.5s, then either advances or completes.
    /// The `generation` parameter is compared against `flashGeneration` to bail
    /// out if the task changed while callbacks were pending.
    private func showNextFlash(images: [String], generation: Int) {
        guard flashGeneration == generation else { return }
        guard flashPhase < images.count else {
            withAnimation {
                flashCompleted = true
            }
            return
        }

        withAnimation(.easeIn(duration: 0.2)) {
            flashVisible = true
        }

        // Hide after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard self.flashGeneration == generation else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                self.flashVisible = false
            }
            // Brief gap then show next or complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                guard self.flashGeneration == generation else { return }
                self.flashPhase += 1
                if self.flashPhase < images.count {
                    self.showNextFlash(images: images, generation: generation)
                } else {
                    withAnimation {
                        self.flashCompleted = true
                    }
                }
            }
        }
    }

    // MARK: - Drag-to-Arrange

    /// Whether this task uses drag-to-arrange interaction (interaction_mode == "drag").
    private func isDragArrangeTask(_ task: AdaptiveTask) -> Bool {
        task.content.interactionMode == "drag"
    }

    /// Initialize drag arrange items in a shuffled (wrong) order.
    private func initDragArrangeItems(task: AdaptiveTask) {
        let correct = task.content.items ?? task.content.displayOptions
        guard !correct.isEmpty else { return }
        var shuffled = correct
        // Keep shuffling until the order differs from the correct one
        for _ in 0..<10 {
            shuffled.shuffle()
            if shuffled != correct { break }
        }
        dragArrangeItems = shuffled
    }

    /// Drag-to-arrange interaction area: shows shapes in a row that the
    /// child can drag to reorder. Shows a reference image of the correct
    /// arrangement above the draggable shapes.
    @ViewBuilder
    private func dragArrangeArea(task: AdaptiveTask) -> some View {
        let correctOrder = task.content.items ?? task.content.displayOptions

        VStack(spacing: 20) {
            // Reference image showing the correct arrangement
            if let refImage = task.content.questionImage, !refImage.isEmpty {
                VStack(spacing: 6) {
                    Text("Match this order:")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    RemoteImageView(
                        objectName: refImage,
                        imageType: .flashcard,
                        fallbackIcon: "rectangle.3.group",
                        iconColor: dimension.color,
                        size: 200
                    )
                    .cornerRadius(16)
                }
            }

            // Draggable shapes row
            VStack(spacing: 8) {
                Text("Drag to arrange:")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    ForEach(Array(dragArrangeItems.enumerated()), id: \.element) { index, item in
                        let imageKey = item.lowercased().replacingOccurrences(of: " ", with: "_")
                        let isDragging = draggedItem == item

                        VStack(spacing: 4) {
                            RemoteImageView(
                                objectName: imageKey,
                                imageType: .flashcard,
                                fallbackIcon: "questionmark.circle",
                                iconColor: dimension.color,
                                size: 80
                            )
                            .cornerRadius(12)
                            Text(item.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isDragging ? dimension.color.opacity(0.2) : Color(.secondarySystemBackground))
                                .shadow(color: isDragging ? dimension.color.opacity(0.3) : .clear, radius: 8)
                        )
                        .scaleEffect(isDragging ? 1.1 : 1.0)
                        .zIndex(isDragging ? 10 : 0)
                        .offset(isDragging ? dragOffset : .zero)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if draggedItem == nil {
                                        draggedItem = item
                                    }
                                    dragOffset = CGSize(width: value.translation.width - dragSwapConsumed, height: value.translation.height)
                                    // Determine swap target based on horizontal drag distance.
                                    // Use dragSwapConsumed to track offset already used by
                                    // previous swaps so we don't cascade multiple swaps.
                                    let threshold: CGFloat = 80
                                    let effectiveDragX = value.translation.width - dragSwapConsumed
                                    if abs(effectiveDragX) > threshold, let currentIndex = dragArrangeItems.firstIndex(of: item) {
                                        let targetIndex = effectiveDragX > 0
                                            ? min(currentIndex + 1, dragArrangeItems.count - 1)
                                            : max(currentIndex - 1, 0)
                                        if targetIndex != currentIndex {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                dragArrangeItems.swapAt(currentIndex, targetIndex)
                                                dragSwapConsumed += effectiveDragX > 0 ? threshold : -threshold
                                                dragOffset = .zero
                                            }
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        draggedItem = nil
                                        dragOffset = .zero
                                        dragSwapConsumed = 0
                                    }
                                    // Check if arrangement is correct and auto-submit
                                    if dragArrangeItems == correctOrder {
                                        let capturedTaskId = learningManager.currentTask?.taskId
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                            // Guard against double-submit: skip if already
                                            // submitting or if the task changed since the drag ended.
                                            guard !learningManager.isSubmitting,
                                                  learningManager.currentTask?.taskId == capturedTaskId else { return }
                                            Task {
                                                await learningManager.submitAttempt(
                                                    isCorrect: true,
                                                    score: 1,
                                                    dimension: dimension
                                                )
                                            }
                                        }
                                    }
                                }
                        )
                    }
                }
            }

            // Submit button (in case child thinks they're done but order is wrong)
            Button {
                let isCorrect = dragArrangeItems == correctOrder
                Task {
                    await learningManager.submitAttempt(
                        isCorrect: isCorrect,
                        score: isCorrect ? 1 : 0,
                        dimension: dimension
                    )
                }
            } label: {
                Text("Done!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(dimension.color)
                    )
            }
            .disabled(learningManager.isSubmitting)

            // Shuffle/reset button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    initDragArrangeItems(task: task)
                }
            } label: {
                Label("Shuffle", systemImage: "shuffle")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
        }
        .onAppear {
            if dragArrangeItems.isEmpty {
                initDragArrangeItems(task: task)
            }
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
    /// - Excludes drag-arrange tasks which use their own drag UI.
    private func isSortingTask(_ task: AdaptiveTask) -> Bool {
        // Drag-to-category sort tasks use their own bucket UI
        if isDragSortTask(task) { return false }
        // Drag-arrange tasks use drag reorder, not ordering UI
        if isDragArrangeTask(task) { return false }
        // Pattern tasks have items from steps but should NOT use ordering UI
        if isPatternTask(task) { return false }
        // Multi-tap tasks use tap counting, not ordering UI
        if task.content.tapCount != nil && task.content.tapCount! > 0 { return false }
        let type = task.taskType
        let explicitTypes = type == "sort" || type == "sequence_order" || type == "build_sentence"
        let hasItems = task.content.items != nil && !(task.content.items!.isEmpty)
        return (explicitTypes || hasItems) && task.content.displayOptions.count >= 2
    }

    // MARK: - Drag-to-Category Sorting

    /// Whether this task is a drag-to-category sorting task.
    /// These have `interaction_mode: "drag_sort"` and `sort_categories` array.
    private func isDragSortTask(_ task: AdaptiveTask) -> Bool {
        task.content.interactionMode == "drag_sort"
            && task.content.sortCategories != nil
            && !(task.content.sortCategories!.isEmpty)
    }

    /// Initialize category sort buckets if not already set up.
    private func initCategorySortBuckets(task: AdaptiveTask) {
        guard let categories = task.content.sortCategories else { return }
        if categorySortBuckets.isEmpty {
            for cat in categories {
                categorySortBuckets[cat] = []
            }
        }
    }

    /// All items not yet placed in any category bucket.
    private func unsortedItems(task: AdaptiveTask) -> [String] {
        let allItems = task.content.displayOptions
        let sorted = Set(categorySortBuckets.values.flatMap { $0 })
        return allItems.filter { !sorted.contains($0) }
    }

    /// Drag-to-category sorting area: items at top, category buckets below.
    @ViewBuilder
    private func dragSortArea(task: AdaptiveTask) -> some View {
        let categories = task.content.sortCategories ?? []
        let itemCategoryMap = task.content.itemCategories ?? [:]
        let remaining = unsortedItems(task: task)
        let allPlaced = remaining.isEmpty

        VStack(spacing: 20) {
            // Unsorted items pool
            if !remaining.isEmpty {
                VStack(spacing: 8) {
                    Text("Drag each item to the right group:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    let columns = [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ]
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(remaining, id: \.self) { item in
                            let isDragging = dragSortItem == item
                            VStack(spacing: 4) {
                                RemoteImageView(
                                    objectName: item.lowercased().replacingOccurrences(of: " ", with: "_"),
                                    imageType: .thumbnail,
                                    fallbackIcon: "questionmark.circle",
                                    iconColor: dimension.color,
                                    size: 44
                                )
                                .cornerRadius(8)
                                Text(item)
                                    .font(.subheadline.bold())
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isDragging ? dimension.color.opacity(0.2) : Color(.secondarySystemBackground))
                                    .shadow(color: isDragging ? dimension.color.opacity(0.3) : .clear, radius: 6)
                            )
                            .scaleEffect(isDragging ? 1.1 : 1.0)
                            .offset(isDragging ? dragSortOffset : .zero)
                            .zIndex(isDragging ? 10 : 0)
                            .gesture(
                                DragGesture(coordinateSpace: .global)
                                    .onChanged { value in
                                        dragSortItem = item
                                        dragSortOffset = value.translation
                                    }
                                    .onEnded { value in
                                        // Check which category bucket the item was dropped on
                                        let dropPoint = value.location
                                        var placed = false
                                        for (cat, frame) in categoryFrames {
                                            if frame.contains(dropPoint) {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    categorySortBuckets[cat, default: []].append(item)
                                                }
                                                speechService.speak(item)
                                                placed = true
                                                break
                                            }
                                        }
                                        if !placed {
                                            // Snap back with animation
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                dragSortItem = nil
                                                dragSortOffset = .zero
                                            }
                                        } else {
                                            dragSortItem = nil
                                            dragSortOffset = .zero
                                        }

                                        // Auto-submit only when all items placed correctly
                                        let newRemaining = unsortedItems(task: task)
                                        if placed && newRemaining.isEmpty {
                                            let isCorrect = checkDragSortCorrectness(task: task, itemCategoryMap: itemCategoryMap)
                                            if isCorrect {
                                                let capturedTaskId = learningManager.currentTask?.taskId
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    guard !learningManager.isSubmitting,
                                                          learningManager.currentTask?.taskId == capturedTaskId else { return }
                                                    Task {
                                                        await learningManager.submitAttempt(
                                                            isCorrect: true,
                                                            score: 1,
                                                            dimension: dimension
                                                        )
                                                    }
                                                }
                                            }
                                        }
                                    }
                            )
                        }
                    }
                }
            }

            // Category buckets
            let bucketColumns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
            LazyVGrid(columns: bucketColumns, spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    let bucketItems = categorySortBuckets[category] ?? []
                    VStack(spacing: 6) {
                        // Category label
                        Text(category)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorForCategory(category, categories: categories))
                            )

                        // Drop zone with placed items
                        VStack(spacing: 4) {
                            if bucketItems.isEmpty {
                                Text("Drop here")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, minHeight: 60)
                            } else {
                                ForEach(bucketItems, id: \.self) { item in
                                    HStack(spacing: 6) {
                                        RemoteImageView(
                                            objectName: item.lowercased().replacingOccurrences(of: " ", with: "_"),
                                            imageType: .thumbnail,
                                            fallbackIcon: "circle.fill",
                                            iconColor: colorForCategory(category, categories: categories),
                                            size: 24
                                        )
                                        .cornerRadius(4)
                                        Text(item)
                                            .font(.caption)
                                            .lineLimit(1)
                                        Spacer()
                                        // Remove button
                                        Button {
                                            withAnimation {
                                                categorySortBuckets[category]?.removeAll { $0 == item }
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(colorForCategory(category, categories: categories).opacity(0.1))
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    colorForCategory(category, categories: categories).opacity(0.4),
                                    style: StrokeStyle(lineWidth: 2, dash: [6, 3])
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorForCategory(category, categories: categories).opacity(0.05))
                                )
                        )
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        categoryFrames[category] = geo.frame(in: .global)
                                    }
                                    .onChange(of: geo.frame(in: .global)) { newFrame in
                                        categoryFrames[category] = newFrame
                                    }
                            }
                        )
                    }
                }
            }

            // Status / Submit
            if allPlaced {
                let isCorrect = checkDragSortCorrectness(task: task, itemCategoryMap: itemCategoryMap)
                if isCorrect {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("All sorted!")
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                    }
                } else {
                    // Manual submit button for incorrect sorting
                    Button {
                        Task {
                            await learningManager.submitAttempt(
                                isCorrect: false,
                                score: 0,
                                dimension: dimension
                            )
                        }
                    } label: {
                        Text("Done!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(dimension.color)
                            )
                    }
                    .disabled(learningManager.isSubmitting)
                }
            }

            // Reset button
            if categorySortBuckets.values.contains(where: { !$0.isEmpty }) {
                Button {
                    withAnimation {
                        for key in categorySortBuckets.keys {
                            categorySortBuckets[key] = []
                        }
                    }
                } label: {
                    Label("Start Over", systemImage: "arrow.counterclockwise")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
        }
        .onAppear {
            initCategorySortBuckets(task: task)
        }
    }

    /// Check if all items are in the correct category buckets.
    private func checkDragSortCorrectness(task: AdaptiveTask, itemCategoryMap: [String: String]) -> Bool {
        for (category, items) in categorySortBuckets {
            for item in items {
                if itemCategoryMap[item] != category {
                    return false
                }
            }
        }
        return true
    }

    /// Assign a color to each category bucket for visual distinction.
    private func colorForCategory(_ category: String, categories: [String]) -> Color {
        let colors: [Color] = [.blue, .orange, .green, .purple, .pink, .teal]
        guard let index = categories.firstIndex(of: category) else { return .gray }
        return colors[index % colors.count]
    }

    // MARK: - Multi-Tap Counting

    /// Whether this task is a multi-tap counting task (go/no-go, sustained attention).
    /// These tasks have a `tap_count` field indicating the expected number of taps.
    private func isMultiTapTask(_ task: AdaptiveTask) -> Bool {
        task.content.tapCount != nil && task.content.tapCount! > 0
    }

    /// Whether this task uses a free-text or numeric input field instead of option buttons.
    private func isTextInputTask(_ task: AdaptiveTask) -> Bool {
        task.content.inputMode != nil
    }

    /// Whether this task is a multi-select question (child picks ALL correct answers).
    private func isMultiSelectTask(_ task: AdaptiveTask) -> Bool {
        task.content.multiSelect == true && !task.content.displayOptions.isEmpty
    }

    /// Multi-tap counting interaction area.
    /// Shows a tap counter and Done button. The child taps directly on the
    /// slide/image above (in contentArea) when they see the target, and
    /// the counter updates. When done, they press the Done button.
    @ViewBuilder
    private func multiTapArea(task: AdaptiveTask) -> some View {
        let expectedCount = task.content.tapCount ?? 0
        let hasAnimation = isAnimatedTask(task)
        let hasFlash = isFlashTask(task)
        let animationStillRunning = (hasAnimation && !animationFinished) || (hasFlash && !flashCompleted)

        VStack(spacing: 12) {
            // Tap counter display
            HStack(spacing: 12) {
                Image(systemName: "hand.tap.fill")
                    .font(.title2)
                    .foregroundColor(dimension.color)
                Text("Taps: \(multiTapCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(dimension.color)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(dimension.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(dimension.color.opacity(0.3), lineWidth: 2)
                    )
            )

            // Fallback TAP button for multi-tap tasks without animation/flash content
            // (e.g. story-based or text-based multi-tap tasks)
            if !hasAnimation && !hasFlash {
                Button {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        multiTapCount += 1
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 44))
                        Text("TAP!")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(dimension.color)
                            .shadow(color: dimension.color.opacity(0.4), radius: 8, y: 4)
                    )
                }
                .disabled(learningManager.isSubmitting)
            }

            // Submit button — only visible after animation/flash finishes (or for story tasks)
            if !animationStillRunning {
                Button {
                    let isCorrect = multiTapCount == expectedCount
                    Task {
                        await learningManager.submitAttempt(
                            isCorrect: isCorrect,
                            score: isCorrect ? 1 : 0,
                            dimension: dimension
                        )
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Done (\(multiTapCount) taps)")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green)
                    )
                }
                .disabled(learningManager.isSubmitting)
            }
        }
    }

    // MARK: - Text / Number Input Area

    /// Renders a text field (or number pad) for counting and fill-in-the-word tasks.
    /// The child types their answer and taps Submit.
    @ViewBuilder
    private func textInputArea(task: AdaptiveTask) -> some View {
        let isNumber = task.content.inputMode == "number"

        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: isNumber ? "number.circle.fill" : "textformat.abc")
                    .font(.title2)
                    .foregroundColor(dimension.color)

                if isNumber {
                    TextField("Type your answer", text: $textInputValue)
                        .keyboardType(.numberPad)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(dimension.color.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    TextField("Type your answer", text: $textInputValue)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(dimension.color.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            Button {
                let answer = textInputValue.trimmingCharacters(in: .whitespacesAndNewlines)
                let expected = (task.content.correctAnswer ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let isCorrect = answer.lowercased() == expected.lowercased()
                speechService.speak(isCorrect ? "Correct!" : "The answer is \(expected)")
                Task {
                    await learningManager.submitAttempt(
                        isCorrect: isCorrect,
                        score: isCorrect ? 1 : 0,
                        dimension: dimension
                    )
                    textInputValue = ""
                }
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Submit")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(textInputValue.isEmpty ? Color.gray : dimension.color)
                )
            }
            .disabled(textInputValue.isEmpty || learningManager.isSubmitting)
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
        // Camera button for object cognition tasks
        if taskSupportsCamera(task) {
            cameraButton(task: task)
        }

        // Drag-to-arrange shape tasks
        if isDragArrangeTask(task) {
            dragArrangeArea(task: task)
        }
        // Drag-to-category sorting tasks
        else if isDragSortTask(task) {
            dragSortArea(task: task)
        }
        // Multi-tap counting tasks (go/no-go, sustained attention)
        else if isMultiTapTask(task) {
            multiTapArea(task: task)
        }
        // Text/number input tasks (counting, fill-in-the-word)
        else if isTextInputTask(task) {
            textInputArea(task: task)
        }
        // Sorting/sequencing tasks get ordering UI
        else if isSortingTask(task) {
            orderingArea(task: task)
        }
        // Multi-select: child picks ALL correct answers then taps Done
        else if isMultiSelectTask(task) {
            multiSelectArea(task: task)
        }
        // Regular option selection (touch modality)
        // For flash tasks, hide options until the flash animation completes.
        else if !task.content.displayOptions.isEmpty && (!isFlashTask(task) || flashCompleted) {
            optionButtons(task: task)
        }

        // Speech input — available for ALL tasks with a speakable target word,
        // not just tasks whose modalities include "voice".  This lets children
        // practice pronunciation across every dimension.
        // Skip for multi-tap tasks — the tap count IS the answer.
        // Skip for text input tasks — the child types the answer.
        // Skip for flash tasks — the child should pick visually, not speak.
        let effectiveTarget = task.content.targetWord ?? task.content.correctAnswer ?? ""
        if !effectiveTarget.isEmpty && !isSortingTask(task) && !isMultiTapTask(task) && !isTextInputTask(task) && !isFlashTask(task) && !isDragArrangeTask(task) && !isDragSortTask(task) && !isMultiSelectTask(task) {
            speechInputArea(task: task)
        }

        // Simple correct/incorrect buttons for tasks without any interactive input
        if task.content.displayOptions.isEmpty && effectiveTarget.isEmpty && !taskSupportsCamera(task) && !isSortingTask(task) && !isMultiTapTask(task) && !isTextInputTask(task) && !isDragArrangeTask(task) && !isDragSortTask(task) {
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
        // Inline-image tasks always use image grid — the backend explicitly
        // marks these tasks so both A and B objects are shown as tappable
        // image cards (e.g. go/no-go tasks like "Tap the dog. Do not tap the cat.").
        if task.content.inlineImages == true && task.content.displayOptions.count >= 2 {
            return true
        }
        // Pattern tasks use image grid only when all options are image-compatible
        // names (single words, no bare numbers).  Tasks like Q091 ("5 apples"),
        // Q094 ("5"), Q099 ("162") fall through to text buttons instead.
        if isPatternTask(task) && task.content.displayOptions.count >= 2 {
            let allImageCompatible = task.content.displayOptions.allSatisfy { option in
                let words = option.split(separator: " ")
                return words.count == 1
                    && !option.contains(",")
                    && !option.contains("(")
                    && !option.contains("/")
                    && !option.contains("-")
                    && option.rangeOfCharacter(from: .decimalDigits) != option.startIndex..<option.endIndex
                    && Int(option) == nil
            }
            if allImageCompatible { return true }
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
    ///
    /// Each card has a numbered index badge in the top-left corner so the
    /// child can also say the number aloud to select it via voice input.
    private func imageGridOptions(task: AdaptiveTask) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        let options = task.content.displayOptions
        let gridImageSize: CGFloat = isPinnedInteractionTask(task) ? 80 : 100
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                Button {
                    handleOptionTap(option: option, task: task)
                } label: {
                    VStack(spacing: 6) {
                        RemoteImageView(
                            objectName: option.lowercased().replacingOccurrences(of: " ", with: "_"),
                            imageType: .flashcard,
                            fallbackIcon: "questionmark.circle",
                            iconColor: dimension.color,
                            size: gridImageSize
                        )
                        .cornerRadius(12)

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
                    // Numbered index badge in the top-leading corner
                    .overlay(alignment: .topLeading) {
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(dimension.color))
                            .offset(x: 4, y: 4)
                    }
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

    // MARK: - Multi-Select Area

    /// Multi-select interaction: the child toggles options on/off and taps
    /// "Done" when finished.  Correctness is checked by comparing the
    /// selected set against the comma-separated `correct_answer`.
    @ViewBuilder
    private func multiSelectArea(task: AdaptiveTask) -> some View {
        let options = task.content.displayOptions
        let correctParts: Set<String> = {
            guard let ca = task.content.correctAnswer else { return [] }
            return Set(ca.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
        }()
        let useImageGrid = isImageGridTask(task)
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        VStack(spacing: 16) {
            // Selection count hint
            HStack(spacing: 6) {
                Image(systemName: "hand.tap.fill")
                    .foregroundColor(dimension.color)
                Text("Pick all that match (\(orderedSelections.count) selected)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if useImageGrid {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(options.enumerated()), id: \.element) { index, option in
                        let isSelected = orderedSelections.contains(option)
                        Button {
                            toggleMultiSelect(option: option)
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

                            }
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isSelected ? dimension.color.opacity(0.2) : Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isSelected ? dimension.color : Color.clear, lineWidth: 3)
                            )
                            .overlay(alignment: .topTrailing) {
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(dimension.color)
                                        .offset(x: -4, y: 4)
                                }
                            }
                        }
                        .disabled(learningManager.isSubmitting)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        let isSelected = orderedSelections.contains(option)
                        Button {
                            toggleMultiSelect(option: option)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(isSelected ? dimension.color : .secondary)
                                Text(option)
                                    .font(.headline)
                            }
                            .foregroundColor(isSelected ? .white : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isSelected ? dimension.color : Color(.secondarySystemBackground))
                            )
                        }
                        .disabled(learningManager.isSubmitting)
                    }
                }
            }

            // Done button — submit the multi-select answer
            Button {
                submitMultiSelect(task: task, correctParts: correctParts)
            } label: {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Done")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(orderedSelections.isEmpty ? Color.gray : dimension.color)
                )
            }
            .disabled(orderedSelections.isEmpty || learningManager.isSubmitting)
        }
    }

    /// Toggle an option in the multi-select list.
    private func toggleMultiSelect(option: String) {
        if let idx = orderedSelections.firstIndex(of: option) {
            orderedSelections.remove(at: idx)
        } else {
            orderedSelections.append(option)
        }
        speechService.speak(option)
    }

    /// Submit the multi-select answer: compare selected set vs correct set.
    private func submitMultiSelect(task: AdaptiveTask, correctParts: Set<String>) {
        let selectedSet = Set(orderedSelections.map { $0.trimmingCharacters(in: .whitespaces) })
        let correctSet = Set(correctParts.map { $0.lowercased() })
        let selectedLower = Set(selectedSet.map { $0.lowercased() })
        let isCorrect = selectedLower == correctSet
        Task {
            await learningManager.submitAttempt(
                isCorrect: isCorrect,
                score: isCorrect ? 1 : 0,
                dimension: dimension
            )
            orderedSelections = []
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
    /// - **Inline-image tasks**: always show — the shape/color images ARE the
    ///   primary content (e.g. "Tap the red shape first").
    /// - **Level 0** (easiest): show all images — visual matching is allowed.
    /// - **Level 1–2**: hide the image whose key matches the question's
    ///   `imageHint` so the child cannot simply match pictures.
    /// - **Level 3+** (hardest): hide all option images — text only.
    private func shouldShowOptionImage(task: AdaptiveTask, option: String) -> Bool {
        // Inline-image tasks always show thumbnails regardless of level
        if task.content.inlineImages == true { return true }
        if task.level >= 3 { return false }
        if task.level >= 1, let imageHint = task.content.imageHint {
            let optionKey = option.lowercased().replacingOccurrences(of: " ", with: "_")
            if optionKey == imageHint.lowercased() { return false }
        }
        return true
    }

    // MARK: - Speech Input

    /// Map spoken text (e.g. "1", "one", "two") to a 1-based option index.
    /// Returns `nil` if the text doesn't match any number.
    private func spokenNumberIndex(_ text: String) -> Int? {
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let numberWords: [String: Int] = [
            "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6,
            "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6,
            "first": 1, "second": 2, "third": 3, "fourth": 4, "fifth": 5, "sixth": 6,
        ]
        return numberWords[normalized]
    }

    /// Try to resolve spoken text as a numbered option selection for image-grid
    /// tasks.  Returns `true` if the number matched an option and was submitted.
    private func tryResolveVoiceNumberSelection(spoken: String) -> Bool {
        guard let task = learningManager.currentTask,
              isImageGridTask(task) else { return false }
        let options = task.content.displayOptions
        guard let idx = spokenNumberIndex(spoken),
              idx >= 1, idx <= options.count else { return false }
        let chosen = options[idx - 1]
        handleOptionTap(option: chosen, task: task)
        return true
    }

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

                // Voice-number selection: if the child said a number that
                // matches an image-grid option index, select it directly.
                if tryResolveVoiceNumberSelection(spoken: spokenText) {
                    hasRecording = true
                    return
                }

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
                        spokenText = "Incorrect"
                        isEvaluating = true
                        Task {
                            await learningManager.submitAttempt(
                                isCorrect: false,
                                score: Int(rating),
                                dimension: dimension
                            )
                            isEvaluating = false
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
                        // Speak a descriptive hint instead of just the word
                        let hintText = contextualHint(for: targetWord)
                        speechService.speak(hintText)
                    } label: {
                        Label("Hint", systemImage: "lightbulb")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .disabled(isListening || showHint)
                }

                // Reveal descriptive hint text
                if showHint {
                    Text(contextualHint(for: targetWord))
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
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
        } else if hasRecording {
            return "Say It Again"
        } else {
            return "Say It"
        }
    }

    /// Generate a contextual, descriptive hint for a target word instead of
    /// just revealing the spelling.  Falls back to a phonetic hint for
    /// unknown words.
    private func contextualHint(for word: String) -> String {
        let key = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let hints: [String: String] = [
            // Animals
            "dog": "It's a friendly animal that barks and loves to play fetch",
            "cat": "It's a small furry pet that purrs and says meow",
            "bird": "It has wings and feathers and can fly in the sky",
            "fish": "It lives in water and has fins to swim",
            "elephant": "It's the biggest land animal with a very long nose",
            "bear": "It's a big furry animal that loves honey",
            "lion": "It's the king of the jungle with a big mane",
            "rabbit": "It has long ears and hops around",
            "monkey": "It climbs trees and loves bananas",
            "horse": "You can ride on it and it says neigh",
            "cow": "It gives us milk and says moo",
            "pig": "It's pink and loves to roll in mud",
            "duck": "It swims in ponds and says quack",
            "frog": "It's green, hops, and says ribbit",
            "butterfly": "It has colorful wings and flies around flowers",
            "turtle": "It moves slowly and carries its house on its back",
            "snake": "It has no legs and slithers on the ground",
            "sheep": "It has fluffy white wool and says baa",
            "chicken": "It lays eggs and says cluck",
            "tiger": "It has orange fur with black stripes",
            // Fruits & Food
            "apple": "It's a round fruit, often red, that you can eat",
            "banana": "It's a long yellow fruit that monkeys love",
            "orange": "It's a round fruit with the same name as a color",
            "grape": "It's a small round fruit that grows in bunches",
            "watermelon": "It's big, green outside, and red inside with seeds",
            "strawberry": "It's small, red, and has tiny seeds on the outside",
            "bread": "You can make a sandwich with it",
            "milk": "It's a white drink that comes from cows",
            "egg": "Chickens lay these and you can cook them",
            "cake": "It's a sweet treat you eat on birthdays",
            "cookie": "It's a small sweet snack, often round",
            "pizza": "It's round, has cheese on top, and you eat slices",
            "sandwich": "It has bread on top and bottom with food in between",
            "ice cream": "It's cold, sweet, and comes in many flavors",
            // Objects
            "ball": "It's round and you can throw, kick, or bounce it",
            "book": "It has pages with words and pictures to read",
            "car": "It has four wheels and people drive it on roads",
            "bus": "It's a big vehicle that carries many people",
            "train": "It rides on tracks and goes choo choo",
            "airplane": "It has wings and flies high in the sky",
            "boat": "It floats on water and takes people across",
            "bicycle": "It has two wheels and you pedal to ride it",
            "chair": "You sit on it at a table or desk",
            "table": "You put food or things on top of it",
            "bed": "You sleep in it at night",
            "door": "You open and close it to go in and out of rooms",
            "window": "You can look through it to see outside",
            "cup": "You drink water or juice from it",
            "plate": "You put food on it when you eat",
            "spoon": "You use it to eat soup or cereal",
            "fork": "It has pointy parts and you use it to eat food",
            "knife": "You use it to cut food",
            "key": "You use it to lock and unlock doors",
            "phone": "You use it to call and talk to people",
            "clock": "It tells you what time it is",
            "umbrella": "You hold it over your head when it rains",
            "shoe": "You wear it on your foot to walk",
            "hat": "You wear it on your head",
            "shirt": "You wear it on your upper body",
            "jacket": "You wear it when it's cold outside",
            "glove": "You wear it on your hand when it's cold",
            "sock": "You wear it on your foot inside your shoe",
            "bag": "You carry things inside it",
            "pencil": "You write or draw with it",
            "pen": "You write with it using ink",
            "paper": "You write or draw on it, it's thin and flat",
            "scissors": "You use them to cut paper",
            "soap": "You use it with water to wash your hands",
            "toothbrush": "You use it to clean your teeth",
            "comb": "You use it to make your hair neat",
            "mirror": "You look in it to see yourself",
            "pillow": "You rest your head on it when you sleep",
            "blanket": "You cover yourself with it to stay warm in bed",
            "lamp": "It makes light so you can see in the dark",
            "letter": "You write a message on paper and mail it",
            "doll": "It's a toy that looks like a small person",
            "toy": "Something fun that kids play with",
            // Nature
            "sun": "It shines bright in the sky during the day",
            "moon": "It glows in the night sky",
            "star": "It twinkles in the sky at night",
            "cloud": "It's white and fluffy, floating in the sky",
            "rain": "Water drops falling from the sky",
            "snow": "It's white, cold, and falls from the sky in winter",
            "tree": "It's tall with branches and green leaves",
            "flower": "It's colorful and smells nice in the garden",
            "grass": "It's green and covers the ground outside",
            "rock": "It's hard and you find it on the ground",
            "water": "You drink it and use it to wash things",
            "fire": "It's hot, bright, and can burn things",
            "mountain": "It's very tall land that reaches into the sky",
            "river": "Water flows through it from high to low ground",
            "ocean": "It's a huge body of salt water",
            // Body parts
            "hand": "You have two of these with five fingers each",
            "eye": "You use these to see things",
            "ear": "You use these to hear sounds",
            "nose": "You use it to smell things",
            "mouth": "You use it to eat and talk",
            "head": "It's on top of your body with your face on it",
            "foot": "You stand and walk on these",
            "arm": "It connects your hand to your shoulder",
            "leg": "You use these to walk and run",
            // Colors & Shapes
            "red": "The color of fire trucks and strawberries",
            "blue": "The color of the sky on a clear day",
            "green": "The color of grass and leaves",
            "yellow": "The color of the sun and bananas",
            "circle": "It's round with no corners",
            "square": "It has four equal sides and four corners",
            "triangle": "It has three sides and three corners",
            "rectangle": "It has four sides, two long and two short",
            "diamond": "It looks like a square tilted to the side",
            "hexagon": "It has six sides",
            "pentagon": "It has five sides",
            "oval": "It's like a stretched circle, egg-shaped",
            "spiral": "It goes round and round in circles",
            // People & Places
            "house": "People live inside it, it has rooms and a roof",
            "school": "You go there to learn new things",
            "park": "An outdoor place with trees where kids play",
            "store": "You go there to buy things",
            "hospital": "Doctors and nurses help sick people there",
        ]

        if let hint = hints[key] {
            return hint
        }

        // Fallback: phonetic hint — first letter + length
        let first = key.prefix(1).uppercased()
        return "It starts with the letter \(first) and has \(key.count) letters"
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
