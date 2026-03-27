//
//  AssessmentGameView.swift
//  RisingStarKid
//
//  Full-screen gamified initial assessment. An animal character guides
//  the child through activities that secretly evaluate all 6 dimensions.
//

import SwiftUI

struct AssessmentGameView: View {
    @EnvironmentObject var learningManager: AdaptiveLearningManager
    @Environment(\.dismiss) private var dismiss

    @State private var phase: AssessmentPhase = .intro
    @State private var assessmentId: String?
    @State private var character: AssessmentCharacter?
    @State private var storyIntro: String = ""
    @State private var totalActivities: Int = 18

    @State private var currentActivity: AssessmentActivity?
    @State private var selectedOption: String?
    @State private var lastFeedback: AssessmentFeedback?
    @State private var progress: Double = 0.0

    @State private var completionResult: AssessmentCompleteResponse?

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    @State private var activityStartTime: Date?

    private let api = AdaptiveAPIService()

    enum AssessmentPhase {
        case intro
        case playing
        case feedback
        case completed
    }

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            VStack(spacing: 0) {
                switch phase {
                case .intro:
                    introView
                case .playing:
                    if let activity = currentActivity {
                        activityView(activity)
                    } else if isLoading {
                        loadingView
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
            await startAssessment()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1), Color.orange.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Intro View

    private var introView: some View {
        VStack(spacing: 32) {
            Spacer()

            if let character = character {
                // Animal character
                Text(character.emoji)
                    .font(.system(size: 120))
                    .shadow(color: .purple.opacity(0.3), radius: 10)

                Text("Meet \(character.name)!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(storyIntro)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
                    .lineSpacing(6)
            } else if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Getting ready...")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if character != nil {
                Button {
                    withAnimation(.spring()) {
                        phase = .playing
                    }
                    Task {
                        await fetchNextActivity()
                    }
                } label: {
                    HStack {
                        Text("Let's Play!")
                            .font(.title2)
                            .fontWeight(.bold)
                        Image(systemName: "play.fill")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.purple.gradient)
                    )
                }
                .padding(.horizontal, 40)
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

    // MARK: - Activity View

    @ViewBuilder
    private func activityView(_ activity: AssessmentActivity) -> some View {
        VStack(spacing: 0) {
            // Progress bar
            progressBar

            ScrollView {
                VStack(spacing: 24) {
                    // Character + narrative
                    characterBubble(activity)

                    // Instruction
                    Text(activity.content.instruction)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Image hint
                    if let imageHint = activity.content.imageHint, !imageHint.isEmpty {
                        RemoteImageView(
                            objectName: imageHint,
                            imageType: .flashcard,
                            fallbackIcon: "photo",
                            iconColor: .orange,
                            size: 160
                        )
                        .cornerRadius(16)
                    }

                    // Target word for voice tasks
                    if let targetWord = activity.content.targetWord, !targetWord.isEmpty {
                        Text(targetWord)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.purple.opacity(0.1))
                            )
                    }

                    // Options (touch interaction)
                    if let options = activity.content.options, !options.isEmpty {
                        optionButtons(options, activity: activity)
                    }
                }
                .padding(.vertical, 24)
            }
        }
    }

    // MARK: - Character Bubble

    private func characterBubble(_ activity: AssessmentActivity) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(activity.character.emoji)
                .font(.system(size: 48))

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.character.name)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)

                Text(activity.content.narrative)
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

    private func optionButtons(_ options: [String], activity: AssessmentActivity) -> some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                Button {
                    selectedOption = option
                    Task {
                        await submitResponse(activity: activity, selected: option)
                    }
                } label: {
                    HStack {
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
                            .fill(selectedOption == option ? Color.purple : Color(.systemBackground))
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    )
                }
                .disabled(selectedOption != nil)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack {
                if let character = character {
                    Text("\(character.emoji) \(character.name)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
            .padding(.horizontal)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.purple.gradient)
                        .frame(width: geo.size.width * progress, height: 10)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 10)
            .padding(.horizontal)
        }
        .padding(.top, 8)
    }

    // MARK: - Feedback View

    private var feedbackView: some View {
        VStack(spacing: 32) {
            Spacer()

            if let feedback = lastFeedback {
                Text(feedback.emoji)
                    .font(.system(size: 100))

                Text(feedback.message)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(feedback.isCorrect ? .green : .orange)
                    .padding(.horizontal)
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
                    // Celebration
                    Text("🎉")
                        .font(.system(size: 80))
                        .padding(.top, 32)

                    Text("All Done!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(result.characterMessage)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    // Overall level
                    VStack(spacing: 8) {
                        Text("Overall Level")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", result.overallLevel))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.purple.opacity(0.1))
                    )

                    // Dimension results
                    VStack(spacing: 12) {
                        Text("Your Strengths")
                            .font(.headline)
                            .padding(.top, 8)

                        ForEach(result.dimensions) { dim in
                            dimensionResultRow(dim)
                        }
                    }
                    .padding(.horizontal)

                    // Stats
                    if let duration = result.durationSeconds {
                        HStack(spacing: 24) {
                            statBadge(value: "\(result.totalCorrect)/\(result.totalActivities)", label: "Correct")
                            statBadge(value: "\(duration / 60)m \(duration % 60)s", label: "Time")
                        }
                        .padding(.top, 8)
                    }

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
                                    .fill(Color.purple.gradient)
                            )
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 24)
                }
            }
        }
    }

    // MARK: - Dimension Result Row

    private func dimensionResultRow(_ dim: DimensionResult) -> some View {
        HStack(spacing: 12) {
            if let dimEnum = dim.dimensionEnum {
                Image(systemName: dimEnum.icon)
                    .font(.title3)
                    .foregroundColor(dimEnum.color)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(dimEnum.color.opacity(0.15))
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(dim.dimensionLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(i <= dim.assessedLevel ? Color.purple : Color(.systemGray4))
                            .frame(width: 8, height: 8)
                    }
                }
            }

            Spacer()

            Text("Level \(dim.assessedLevel)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.purple)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.purple.opacity(0.1))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }

    // MARK: - Stat Badge

    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Getting next activity...")
                .font(.body)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - API Actions

    private func startAssessment() async {
        guard let playerId = learningManager.playerId else {
            errorMessage = "No player logged in"
            return
        }

        isLoading = true
        do {
            let result = try await api.startAssessment(playerId: playerId)
            assessmentId = result.assessmentId
            character = result.character
            storyIntro = result.storyIntro
            totalActivities = result.totalActivities
        } catch {
            errorMessage = "Failed to start assessment: \(error.localizedDescription)"
            print("[Assessment] Start error: \(error)")
        }
        isLoading = false
    }

    private func fetchNextActivity() async {
        guard let aid = assessmentId else { return }

        isLoading = true
        do {
            let activity = try await api.getNextAssessmentActivity(assessmentId: aid)
            withAnimation(.spring()) {
                currentActivity = activity
                selectedOption = nil
                activityStartTime = Date()
            }
        } catch {
            // No more activities — complete the assessment
            await completeAssessment()
        }
        isLoading = false
    }

    private func submitResponse(activity: AssessmentActivity, selected: String) async {
        guard let aid = assessmentId else { return }

        let responseTimeMs: Int?
        if let start = activityStartTime {
            responseTimeMs = Int(Date().timeIntervalSince(start) * 1000)
        } else {
            responseTimeMs = nil
        }

        let interactionType = activity.content.interactionType

        let body = AssessmentRespondRequest(
            activityIndex: activity.activityIndex,
            selectedOption: interactionType == "touch" ? selected : nil,
            spokenText: interactionType == "voice" ? selected : nil,
            responseTimeMs: responseTimeMs,
            interactionType: interactionType
        )

        do {
            let response = try await api.respondToAssessment(assessmentId: aid, body: body)
            lastFeedback = response.feedback
            progress = response.progressFraction

            // Show feedback
            withAnimation(.spring()) {
                phase = .feedback
            }

            // Wait for feedback display
            try await Task.sleep(nanoseconds: 1_500_000_000)

            if response.shouldContinue {
                withAnimation(.spring()) {
                    phase = .playing
                }
                await fetchNextActivity()
            } else {
                await completeAssessment()
            }
        } catch {
            print("[Assessment] Respond error: \(error)")
            // Continue anyway
            withAnimation(.spring()) {
                phase = .playing
            }
            await fetchNextActivity()
        }
    }

    private func completeAssessment() async {
        guard let aid = assessmentId else { return }

        do {
            let result = try await api.completeAssessment(assessmentId: aid)
            completionResult = result
            withAnimation(.spring()) {
                phase = .completed
                progress = 1.0
            }
            // Refresh profiles
            await learningManager.loadProfiles()
        } catch {
            print("[Assessment] Complete error: \(error)")
            dismiss()
        }
    }
}

#Preview {
    AssessmentGameView()
        .environmentObject(AdaptiveLearningManager())
}
