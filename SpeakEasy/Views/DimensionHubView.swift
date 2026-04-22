//
//  DimensionHubView.swift
//  RisingStarKid
//
//  Grid of 6 developmental dimensions with Story Mode. Tap a dimension to start a learning session.
//

import SwiftUI

struct DimensionHubView: View {
    @EnvironmentObject var learningManager: AdaptiveLearningManager
    @ObservedObject private var authService = AuthenticationService.shared
    @State private var selectedDimension: DevelopmentalDimension?
    @State private var showStoryAssessment: Bool = false
    @State private var showSignOutAlert: Bool = false

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    overallProgressHeader

                    // Story Mode section
                    storyModeSection

                    // Dimension Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(DevelopmentalDimension.allCases) { dimension in
                            DimensionCard(
                                dimension: dimension,
                                level: learningManager.level(for: dimension),
                                isAssessed: learningManager.profile(for: dimension)?.assessed ?? false
                            )
                            .onTapGesture {
                                selectedDimension = dimension
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Learn")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if let user = authService.currentUser {
                            Section {
                                Label(user.name ?? "Player", systemImage: "person.fill")
                                if let email = user.email {
                                    Label(email, systemImage: "envelope.fill")
                                }
                            }
                        }
                        Button(role: .destructive) {
                            showSignOutAlert = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.title3)
                            .foregroundColor(.purple)
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .fullScreenCover(item: $selectedDimension) { dimension in
                LearningSessionView(dimension: dimension)
                    .environmentObject(learningManager)
            }
            .fullScreenCover(isPresented: $showStoryAssessment) {
                StoryAssessmentView(storyId: "bunny_birthday")
                    .environmentObject(learningManager)
            }
            .task {
                await learningManager.seedTasksIfNeeded()
                await learningManager.loadProfiles()
            }
            .refreshable {
                await learningManager.loadProfiles()
            }
        }
    }

    // MARK: - Story Mode Section

    private var storyModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                Text("Story Mode")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    storyCard(
                        title: "Bunny's Birthday Party",
                        titleZh: "小兔子的生日派对",
                        emoji: "🐰",
                        description: "Help Bunny prepare a birthday party! Find items, decorate, and greet friends.",
                        sceneCount: 8,
                        estimatedMinutes: 4,
                        imageUrl: "https://res.cloudinary.com/dgpir7tqk/image/upload/f_png/risingstar/stories/story_s1_kitchen_find_apple"
                    ) {
                        showStoryAssessment = true
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Story Card

    private func storyCard(
        title: String,
        titleZh: String,
        emoji: String,
        description: String,
        sceneCount: Int,
        estimatedMinutes: Int,
        imageUrl: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Story cover image
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(16)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.1))
                        .frame(height: 150)
                        .overlay(
                            Text(emoji)
                                .font(.system(size: 48))
                        )
                }

                // Title row
                HStack(spacing: 8) {
                    Text(emoji)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text(titleZh)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Description
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .lineSpacing(2)

                // Metadata
                HStack(spacing: 12) {
                    Label("\(sceneCount) scenes", systemImage: "film")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Label("~\(estimatedMinutes) min", systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }

                // Play button
                HStack {
                    Image(systemName: "play.fill")
                    Text("Play Story")
                        .fontWeight(.bold)
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.orange.gradient)
                )
            }
            .padding(16)
            .frame(width: 280)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .orange.opacity(0.15), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Overall Progress Header

    private var overallProgressHeader: some View {
        VStack(spacing: 12) {
            if learningManager.isLoadingProfiles {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello, \(learningManager.playerName.isEmpty ? "Star" : learningManager.playerName)!")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Choose an area to practice")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Overall level badge
                    VStack {
                        Text("⭐")
                            .font(.title)
                        Text("Level \(String(format: "%.1f", learningManager.overallLevel))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if let error = learningManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Dimension Card

struct DimensionCard: View {
    let dimension: DevelopmentalDimension
    let level: Int
    let isAssessed: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: dimension.icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(dimension.color.gradient)
                )

            // Label
            Text(dimension.label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            // Level indicator
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(i < level ? dimension.color : Color(.systemGray4))
                        .frame(width: 10, height: 10)
                }
            }

            // Level description
            if level < dimension.levelDescriptions.count {
                Text(dimension.levelDescriptions[level])
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: dimension.color.opacity(0.2), radius: 8, y: 4)
        )
    }
}

#Preview {
    DimensionHubView()
        .environmentObject(AdaptiveLearningManager())
}
