//
//  DimensionHubView.swift
//  RisingStarKid
//
//  Grid of 6 developmental dimensions. Tap a dimension to start a learning session.
//

import SwiftUI

struct DimensionHubView: View {
    @EnvironmentObject var learningManager: AdaptiveLearningManager
    @ObservedObject private var authService = AuthenticationService.shared
    @State private var selectedDimension: DevelopmentalDimension?
    @State private var showAssessment: Bool = false
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

                    // Assessment prompt (when not yet assessed)
                    if learningManager.needsInitialAssessment && !learningManager.isLoadingProfiles {
                        assessmentPromptBanner
                    }

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
            .fullScreenCover(isPresented: $showAssessment) {
                AssessmentGameView()
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

    // MARK: - Assessment Prompt Banner

    private var assessmentPromptBanner: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Text("🐰")
                    .font(.system(size: 44))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Let's Play a Game!")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("A friendly animal will guide you through fun activities to find the best starting point.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
            }

            Button {
                showAssessment = true
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Adventure")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purple.gradient)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .purple.opacity(0.15), radius: 8, y: 4)
        )
        .padding(.horizontal)
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
