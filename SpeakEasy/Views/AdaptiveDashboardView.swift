//
//  AdaptiveDashboardView.swift
//  RisingStarKid
//
//  Multi-dimension progress dashboard for parents/therapists.
//  Shows per-dimension levels, recent sessions, and AI-generated insights.
//

import SwiftUI

struct AdaptiveDashboardView: View {
    @EnvironmentObject var learningManager: AdaptiveLearningManager
    @State private var progressSummary: ProgressSummaryResponse?
    @State private var isLoadingSummary: Bool = false
    @State private var selectedTab: DashboardTab = .overview

    enum DashboardTab: String, CaseIterable {
        case overview = "Overview"
        case insights = "Insights"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Tab picker
                    Picker("", selection: $selectedTab) {
                        ForEach(DashboardTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    switch selectedTab {
                    case .overview:
                        overviewContent
                    case .insights:
                        insightsContent
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
            .task {
                await learningManager.loadProfiles()
                await learningManager.loadDashboard()
            }
            .refreshable {
                await learningManager.loadProfiles()
                await learningManager.loadDashboard()
            }
        }
    }

    // MARK: - Overview Content

    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Stats cards
            if let dash = learningManager.dashboard {
                statsCards(dashboard: dash)
            }

            // Dimension progress
            dimensionProgressSection

            // Recent sessions
            if let dash = learningManager.dashboard, !dash.recentSessions.isEmpty {
                recentSessionsSection(sessions: dash.recentSessions)
            }
        }
    }

    // MARK: - Stats Cards

    private func statsCards(dashboard: DashboardSummary) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Sessions", value: "\(dashboard.totalSessions)", icon: "play.circle.fill", color: .blue)
            StatCard(title: "Tasks Done", value: "\(dashboard.totalTasksCompleted)", icon: "checkmark.circle.fill", color: .green)
            StatCard(title: "Accuracy", value: "\(Int(dashboard.overallAccuracy * 100))%", icon: "target", color: .orange)
            StatCard(title: "Mastered", value: "\(dashboard.masteredTasks)", icon: "star.fill", color: .yellow)
        }
        .padding(.horizontal)
    }

    // MARK: - Dimension Progress

    private var dimensionProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Development Profile")
                .font(.headline)
                .padding(.horizontal)

            ForEach(DevelopmentalDimension.allCases) { dimension in
                DimensionProgressRow(
                    dimension: dimension,
                    level: learningManager.level(for: dimension)
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Recent Sessions

    private func recentSessionsSection(sessions: [LearningSession]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
                .padding(.horizontal)

            ForEach(sessions.prefix(5)) { session in
                SessionRow(session: session)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Insights Content

    private var insightsContent: some View {
        VStack(spacing: 20) {
            if isLoadingSummary {
                ProgressView("Generating insights...")
                    .padding(.top, 40)
            } else if let summary = progressSummary {
                insightCards(summary: summary)
            } else {
                Button {
                    Task { await loadInsights() }
                } label: {
                    Label("Generate Progress Report", systemImage: "wand.and.stars")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.purple.gradient)
                        )
                }
                .padding(.horizontal)
                .padding(.top, 20)

                Text("Get AI-generated insights about your child's development")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private func insightCards(summary: ProgressSummaryResponse) -> some View {
        VStack(spacing: 16) {
            // Narrative
            VStack(alignment: .leading, spacing: 8) {
                Label("Summary", systemImage: "doc.text")
                    .font(.headline)
                Text(summary.narrative)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal)

            // Strengths
            if !summary.strengths.isEmpty {
                InsightList(title: "Strengths", icon: "star.fill", color: .green, items: summary.strengths)
            }

            // Areas for Growth
            if !summary.areasForGrowth.isEmpty {
                InsightList(title: "Areas for Growth", icon: "arrow.up.circle.fill", color: .orange, items: summary.areasForGrowth)
            }

            // Next Steps
            if !summary.nextSteps.isEmpty {
                InsightList(title: "Next Steps", icon: "forward.fill", color: .blue, items: summary.nextSteps)
            }

            // Dimension breakdown
            if !summary.dimensions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("By Dimension", systemImage: "chart.bar.fill")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(summary.dimensions) { dim in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dim.dimensionLabel)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(dim.currentAbility)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("Level \(dim.level)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(statusColor(dim.status).opacity(0.2))
                                )
                        }
                        .padding(.horizontal)
                    }
                }
            }

            // Refresh button
            Button {
                Task { await loadInsights() }
            } label: {
                Label("Refresh Insights", systemImage: "arrow.clockwise")
                    .font(.subheadline)
                    .foregroundColor(.purple)
            }
            .padding(.top, 8)
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "strong": return .green
        case "developing": return .orange
        case "needs_support": return .red
        default: return .gray
        }
    }

    private func loadInsights() async {
        guard let pid = learningManager.playerId else { return }
        isLoadingSummary = true
        do {
            progressSummary = try await learningManager.api.getProgressSummary(playerId: pid)
        } catch {
            print("[Dashboard] Failed to load insights: \(error)")
        }
        isLoadingSummary = false
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Dimension Progress Row

struct DimensionProgressRow: View {
    let dimension: DevelopmentalDimension
    let level: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: dimension.icon)
                .font(.title3)
                .foregroundColor(dimension.color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(dimension.label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                ProgressView(value: Double(level), total: 4.0)
                    .tint(dimension.color)

                if level < dimension.levelDescriptions.count {
                    Text(dimension.levelDescriptions[level])
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Text("Lv.\(level)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(dimension.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(dimension.color.opacity(0.1))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: LearningSession

    var dimensionEnum: DevelopmentalDimension? {
        guard let dim = session.dimension else { return nil }
        return DevelopmentalDimension(rawValue: dim)
    }

    var body: some View {
        HStack(spacing: 12) {
            if let dim = dimensionEnum {
                Image(systemName: dim.icon)
                    .foregroundColor(dim.color)
                    .frame(width: 28)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(dimensionEnum?.label ?? "Practice")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(session.correctCount)/\(session.totalCount) correct")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("Lv.\(session.currentLevel)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Insight List

struct InsightList: View {
    let title: String
    let icon: String
    let color: Color
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(color)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .padding(.horizontal)
    }
}

#Preview {
    AdaptiveDashboardView()
        .environmentObject(AdaptiveLearningManager())
}
