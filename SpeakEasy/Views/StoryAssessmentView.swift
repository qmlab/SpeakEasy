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

    // Tap-on-image state
    @State private var tappedRegionLabel: String?
    @State private var showTapHint: Bool = false

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

                // Error banner (visible when returning to intro after fetchNextScene failure)
                if let error = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .padding(.horizontal, 32)
                }

                // Start button
                Button {
                    errorMessage = nil
                    speechService.speakStorytelling(story.introNarration)
                    withAnimation(.spring()) {
                        phase = .scene
                    }
                    Task {
                        await fetchNextScene()
                    }
                } label: {
                    HStack {
                        Text(errorMessage != nil ? "Try Again" : "Let's Go!")
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
                    let hasTapRegions = !scene.test.tapRegions.isEmpty

                    // Scene illustration — tappable overlay when tap_regions exist
                    if let url = scene.imageUrl, !url.isEmpty {
                        if hasTapRegions {
                            tappableImageOverlay(url: url, scene: scene)
                                .padding(.horizontal, 16)
                        } else {
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
                    }

                    // Narration bubble
                    narratorBubble(scene)

                    // Hear Again button
                    Button {
                        speechService.speakStorytelling(scene.test.instruction)
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

                    // Options (touch tasks) — only show buttons when no tap regions
                    if scene.test.modality == "touch" && !scene.test.options.isEmpty && !hasTapRegions {
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
            // Auto-speak narration (storytelling style) then instruction
            speechService.onSpeechFinished = {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.speechService.onSpeechFinished = nil
                    self.speechService.speakStorytelling(scene.test.instruction)
                }
            }
            speechService.speakStorytelling(scene.narration)
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

    // MARK: - Tappable Image Overlay

    /// Renders the scene image with invisible tap-region hotspots.
    /// Children tap directly on objects in the picture instead of
    /// choosing from a list of text buttons.
    @ViewBuilder
    private func tappableImageOverlay(url: String, scene: SceneResponse) -> some View {
        let regions = scene.test.tapRegions

        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(
                        GeometryReader { geo in
                            ZStack {
                                // Single tap gesture on the whole image — find the
                                // closest region center so overlapping circles always
                                // resolve to the nearest object.
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture { location in
                                        guard tappedRegionLabel == nil && selectedOption == nil else { return }
                                        // Find the region whose center is closest to the tap
                                        var bestRegion: TapRegion?
                                        var bestDist: CGFloat = .greatestFiniteMagnitude
                                        for region in regions {
                                            let cx = geo.size.width * region.x
                                            let cy = geo.size.height * region.y
                                            let r = max(geo.size.width * region.radius, 22)
                                            let dx = location.x - cx
                                            let dy = location.y - cy
                                            let dist = sqrt(dx * dx + dy * dy)
                                            // Only consider taps within the region's radius
                                            if dist <= r && dist < bestDist {
                                                bestDist = dist
                                                bestRegion = region
                                            }
                                        }
                                        guard let tapped = bestRegion else { return }
                                        tappedRegionLabel = tapped.label
                                        Task {
                                            await submitSceneResponse(scene: scene, selected: tapped.label)
                                        }
                                    }

                                // Visual overlays (feedback rings + hint rings)
                                ForEach(Array(regions.enumerated()), id: \.offset) { _, region in
                                    let cx = geo.size.width * region.x
                                    let cy = geo.size.height * region.y
                                    let r = max(geo.size.width * region.radius, 22)

                                    // Visual feedback — orange ring after tap
                                    if tappedRegionLabel == region.label {
                                        Circle()
                                            .stroke(Color.orange, lineWidth: 3)
                                            .frame(width: r * 2 + 8, height: r * 2 + 8)
                                            .position(x: cx, y: cy)
                                            .transition(.scale.combined(with: .opacity))
                                    }

                                    // Gentle pulsing hint ring (before any tap)
                                    if tappedRegionLabel == nil && showTapHint {
                                        Circle()
                                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                                            .frame(width: r * 2 + 4, height: r * 2 + 4)
                                            .position(x: cx, y: cy)
                                            .transition(.opacity)
                                    }
                                }
                            }
                        }
                    )
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    .onAppear {
                        // Show pulsing hints after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                showTapHint = true
                            }
                        }
                    }
            case .failure:
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.orange.opacity(0.1))
                    .frame(height: 280)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.orange.opacity(0.4))
                    )
            default:
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.orange.opacity(0.1))
                    .frame(height: 280)
                    .overlay(ProgressView())
            }
        }
        .frame(maxHeight: 340)
    }

    // MARK: - Option Buttons

    /// Strip emoji characters from text so TTS reads only words
    private func textForSpeech(_ text: String) -> String {
        text.unicodeScalars.filter { scalar in
            // Keep basic ASCII, Latin, CJK, and common punctuation — drop emoji blocks
            !(
                (scalar.value >= 0x1F600 && scalar.value <= 0x1F64F) || // Emoticons
                (scalar.value >= 0x1F300 && scalar.value <= 0x1F5FF) || // Misc Symbols & Pictographs
                (scalar.value >= 0x1F680 && scalar.value <= 0x1F6FF) || // Transport & Map
                (scalar.value >= 0x1F900 && scalar.value <= 0x1F9FF) || // Supplemental Symbols
                (scalar.value >= 0x2600 && scalar.value <= 0x26FF) ||   // Misc Symbols
                (scalar.value >= 0x2700 && scalar.value <= 0x27BF) ||   // Dingbats
                (scalar.value >= 0xFE00 && scalar.value <= 0xFE0F) ||   // Variation Selectors
                (scalar.value >= 0x200D && scalar.value <= 0x200D)      // Zero-Width Joiner
            )
        }.map { String($0) }.joined().trimmingCharacters(in: .whitespaces)
    }

    /// Extract leading emoji from a string, returning (emoji, remainingText).
    private func extractLeadingEmoji(_ text: String) -> (String, String)? {
        guard let first = text.unicodeScalars.first else { return nil }
        // Check if the first character is in common emoji ranges
        let v = first.value
        let isEmoji = (v >= 0x1F600 && v <= 0x1F64F) ||
                      (v >= 0x1F300 && v <= 0x1F5FF) ||
                      (v >= 0x1F680 && v <= 0x1F6FF) ||
                      (v >= 0x1F900 && v <= 0x1F9FF) ||
                      (v >= 0x2600 && v <= 0x26FF) ||
                      (v >= 0x2700 && v <= 0x27BF)
        guard isEmoji else { return nil }
        // Walk past the emoji (may be multi-scalar)
        var idx = text.startIndex
        // Move past the first Character (which may be a multi-scalar emoji)
        idx = text.index(after: idx)
        let emoji = String(text[text.startIndex..<idx])
        let rest = String(text[idx...]).trimmingCharacters(in: .whitespaces)
        return (emoji, rest)
    }

    private func sceneOptionButtons(_ scene: SceneResponse) -> some View {
        VStack(spacing: 12) {
            let options = scene.test.options
            let imageHints = scene.test.imageHints

            ForEach(Array(options.enumerated()), id: \.offset) { idx, option in
                let emojiParts = extractLeadingEmoji(option)
                let hasImageHint = idx < imageHints.count && !imageHints[idx].isEmpty

                HStack(spacing: 8) {
                    // Speaker button — lets non-readers hear the option before selecting
                    Button {
                        speechService.speak(textForSpeech(option))
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.body)
                            .foregroundColor(.orange)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.orange.opacity(0.12))
                            )
                    }
                    .disabled(selectedOption != nil)

                    // Main option button
                    Button {
                        selectedOption = option
                        speechService.speak(textForSpeech(option))
                        Task {
                            await submitSceneResponse(scene: scene, selected: option)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            // Show image hint if available
                            if hasImageHint {
                                RemoteImageView(
                                    objectName: imageHints[idx],
                                    imageType: .thumbnail,
                                    fallbackIcon: "questionmark.circle",
                                    iconColor: .orange,
                                    size: 44
                                )
                                .cornerRadius(10)
                            } else if let parts = emojiParts {
                                // Large emoji as visual cue for non-readers
                                Text(parts.0)
                                    .font(.system(size: 36))
                                    .frame(width: 48, height: 48)
                            }

                            if let parts = emojiParts, !hasImageHint {
                                // Show only the text part (emoji already displayed large)
                                Text(parts.1)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            } else {
                                Text(option)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
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
                } else {
                    // Error fallback — ensure user can always exit
                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text("Something went wrong")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("The story couldn't be completed, but your progress has been saved.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button {
                            dismiss()
                        } label: {
                            Text("Go Back")
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

                        Spacer()
                    }
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
            tappedRegionLabel = nil
            showTapHint = false
            spokenText = ""
            hasRecording = false
            isListening = false
            isEvaluating = false
            sceneStartTime = Date()
            isLoading = false

            withAnimation(.spring()) {
                phase = .scene
            }
        } catch let apiError as AdaptiveAPIError {
            // 404 means no more scenes — complete the story
            if case .httpError(let statusCode, _) = apiError, statusCode == 404 {
                await completeStoryAssessment()
            } else {
                isLoading = false
                errorMessage = "Could not load next scene: \(apiError.localizedDescription)"
                withAnimation(.spring()) {
                    phase = .intro
                }
            }
        } catch {
            isLoading = false
            errorMessage = "Could not load next scene: \(error.localizedDescription)"
            withAnimation(.spring()) {
                phase = .intro
            }
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
            speechService.speakStorytelling(response.feedback)

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
            // Reset UI state so buttons are re-enabled, then advance
            selectedOption = nil
            tappedRegionLabel = nil
            isEvaluating = false
            spokenText = ""
            await fetchNextScene()
        }
    }

    private func completeStoryAssessment() async {
        guard let aId = assessmentId else { return }

        do {
            let result = try await api.completeStory(assessmentId: aId)
            completionResult = result

            // Speak outro
            speechService.speakStorytelling(result.outroNarration)

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
