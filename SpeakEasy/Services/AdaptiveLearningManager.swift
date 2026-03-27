//
//  AdaptiveLearningManager.swift
//  RisingStarKid
//
//  ObservableObject managing adaptive learning session state.
//  Coordinates between the adaptive API, speech service, and UI.
//

import Foundation
import SwiftUI

@MainActor
class AdaptiveLearningManager: ObservableObject {

    // MARK: - Published State

    @Published var profiles: [DevelopmentalProfile] = []
    @Published var overallLevel: Double = 0
    @Published var playerName: String = ""

    @Published var currentSession: LearningSession?
    @Published var currentTask: AdaptiveTask?
    @Published var lastAttemptResult: AttemptResult?
    @Published var sessionSummary: EndSessionResponse?

    @Published var isLoadingProfiles: Bool = false
    @Published var isLoadingTask: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var isInSession: Bool = false

    @Published var showReward: Bool = false
    @Published var rewardMessage: String = ""
    @Published var showLevelUp: Bool = false
    @Published var showConfidenceRebuild: Bool = false

    @Published var errorMessage: String?
    @Published var tasksSeeded: Bool = false

    @Published var dashboard: DashboardSummary?
    @Published var isLoadingDashboard: Bool = false

    // MARK: - Task timing

    private var taskStartTime: Date?
    var currentStreak: Int = 0
    var sessionTaskCount: Int = 0

    // MARK: - Dependencies

    let api: AdaptiveAPIService

    // MARK: - Init

    init(api: AdaptiveAPIService = AdaptiveAPIService()) {
        self.api = api
    }

    // MARK: - Player ID

    var playerId: String? {
        UserDefaults.standard.string(forKey: "speakeasy_player_id")
    }

    // MARK: - Seed Tasks

    func seedTasksIfNeeded() async {
        guard !tasksSeeded else { return }
        do {
            let result = try await api.seedTasks()
            tasksSeeded = true
            print("[Adaptive] Seeded \(result.taskCount) tasks")
        } catch {
            print("[Adaptive] Seed failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Load Profiles

    func loadProfiles() async {
        guard let pid = playerId else {
            errorMessage = "No player logged in"
            return
        }

        isLoadingProfiles = true
        errorMessage = nil

        do {
            let response = try await api.getProfiles(playerId: pid)
            profiles = response.dimensions
            overallLevel = response.overallLevel
            playerName = response.playerName
        } catch {
            errorMessage = "Failed to load profiles: \(error.localizedDescription)"
            print("[Adaptive] Load profiles error: \(error)")
        }

        isLoadingProfiles = false
    }

    // MARK: - Get profile for dimension

    func profile(for dimension: DevelopmentalDimension) -> DevelopmentalProfile? {
        profiles.first { $0.dimension == dimension.rawValue }
    }

    func level(for dimension: DevelopmentalDimension) -> Int {
        profile(for: dimension)?.level ?? 0
    }

    // MARK: - Start Session

    func startSession(dimension: DevelopmentalDimension) async {
        guard let pid = playerId else { return }

        isInSession = false
        errorMessage = nil
        sessionSummary = nil
        lastAttemptResult = nil
        currentStreak = 0
        sessionTaskCount = 0

        do {
            let session = try await api.startSession(playerId: pid, dimension: dimension.rawValue)
            currentSession = session
            isInSession = true
            await fetchNextTask(dimension: dimension)
        } catch {
            errorMessage = "Failed to start session: \(error.localizedDescription)"
            print("[Adaptive] Start session error: \(error)")
        }
    }

    // MARK: - Fetch Next Task

    func fetchNextTask(dimension: DevelopmentalDimension) async {
        guard let pid = playerId, let session = currentSession else { return }

        isLoadingTask = true

        do {
            let task = try await api.getNextTask(
                sessionId: session.id,
                playerId: pid,
                dimension: dimension.rawValue
            )
            currentTask = task
            taskStartTime = Date()
            showReward = false
            showLevelUp = false
            showConfidenceRebuild = false
        } catch {
            errorMessage = "Failed to get task: \(error.localizedDescription)"
            print("[Adaptive] Get task error: \(error)")
        }

        isLoadingTask = false
    }

    // MARK: - Submit Attempt

    func submitAttempt(isCorrect: Bool, score: Int = 0, dimension: DevelopmentalDimension) async {
        guard let pid = playerId,
              let session = currentSession,
              let task = currentTask else { return }

        isSubmitting = true

        let responseTimeMs: Int?
        if let start = taskStartTime {
            responseTimeMs = Int(Date().timeIntervalSince(start) * 1000)
        } else {
            responseTimeMs = nil
        }

        do {
            let result = try await api.submitAttempt(
                sessionId: session.id,
                taskId: task.taskId,
                playerId: pid,
                isCorrect: isCorrect,
                score: isCorrect ? max(score, 1) : 0,
                responseTimeMs: responseTimeMs,
                promptLevel: task.promptLevel
            )

            lastAttemptResult = result
            currentStreak = result.streak
            sessionTaskCount += 1

            // Handle rewards
            if let reward = result.reward {
                rewardMessage = reward.message ?? "Great job!"
                showReward = true
            }

            if result.shouldLevelUp {
                showLevelUp = true
            }

            if result.confidenceRebuild {
                showConfidenceRebuild = true
            }

            // Small delay before next task for feedback
            try await Task.sleep(nanoseconds: isCorrect ? 1_500_000_000 : 2_000_000_000)

            // Fetch next task
            await fetchNextTask(dimension: dimension)

        } catch {
            errorMessage = "Failed to submit: \(error.localizedDescription)"
            print("[Adaptive] Submit attempt error: \(error)")
        }

        isSubmitting = false
    }

    // MARK: - End Session

    func endSession() async {
        guard let session = currentSession else { return }

        do {
            let summary = try await api.endSession(sessionId: session.id)
            sessionSummary = summary
            isInSession = false
            currentTask = nil
            currentSession = nil

            // Refresh profiles after session
            await loadProfiles()
        } catch {
            errorMessage = "Failed to end session: \(error.localizedDescription)"
            print("[Adaptive] End session error: \(error)")
        }
    }

    // MARK: - Dashboard

    func loadDashboard() async {
        guard let pid = playerId else { return }

        isLoadingDashboard = true

        do {
            dashboard = try await api.getDashboard(playerId: pid)
        } catch {
            print("[Adaptive] Dashboard error: \(error.localizedDescription)")
        }

        isLoadingDashboard = false
    }

    // MARK: - Reset

    func reset() {
        profiles = []
        overallLevel = 0
        currentSession = nil
        currentTask = nil
        lastAttemptResult = nil
        sessionSummary = nil
        isInSession = false
        showReward = false
        showLevelUp = false
        showConfidenceRebuild = false
        errorMessage = nil
        dashboard = nil
    }
}
