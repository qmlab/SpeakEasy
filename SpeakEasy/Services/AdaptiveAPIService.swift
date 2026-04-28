//
//  AdaptiveAPIService.swift
//  RisingStarKid
//
//  API client for the adaptive learning and AI personalization backend endpoints.
//

import Foundation

class AdaptiveAPIService {
    private let baseURL: String

    init(baseURL: String = "https://risingstar-backend-zclkfobb.fly.dev") {
        self.baseURL = baseURL
    }

    // MARK: - Generic Helpers

    private func makeURL(_ path: String) -> URL {
        URL(string: "\(baseURL)\(path)")!
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = makeURL(path)
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateHTTPResponse(response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func post<Req: Encodable, Res: Decodable>(_ path: String, body: Req) async throws -> Res {
        let url = makeURL(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)
        return try JSONDecoder().decode(Res.self, from: data)
    }

    private func postNoBody<Res: Decodable>(_ path: String) async throws -> Res {
        let url = makeURL(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)
        return try JSONDecoder().decode(Res.self, from: data)
    }

    private func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AdaptiveAPIError.httpError(statusCode: httpResponse.statusCode, body: body)
        }
    }

    // MARK: - Task Seeding

    func seedTasks() async throws -> SeedTasksResponse {
        try await postNoBody("/tasks/seed")
    }

    // MARK: - Profiles

    func getProfiles(playerId: String) async throws -> FullProfileResponse {
        try await get("/adaptive/profiles/\(playerId)")
    }

    // MARK: - Sessions

    func startSession(playerId: String, dimension: String, sessionType: String = "practice") async throws -> LearningSession {
        let body = StartSessionRequest(playerId: playerId, sessionType: sessionType, dimension: dimension)
        return try await post("/adaptive/sessions/start", body: body)
    }

    func endSession(sessionId: String) async throws -> EndSessionResponse {
        try await postNoBody("/adaptive/sessions/\(sessionId)/end")
    }

    // MARK: - Tasks & Attempts

    func getNextTask(sessionId: String, playerId: String, dimension: String) async throws -> AdaptiveTask {
        try await get("/adaptive/sessions/\(sessionId)/next-task?player_id=\(playerId)&dimension=\(dimension)")
    }

    func submitAttempt(
        sessionId: String,
        taskId: String,
        playerId: String,
        isCorrect: Bool,
        score: Int = 0,
        responseTimeMs: Int? = nil,
        promptLevel: Int = 0
    ) async throws -> AttemptResult {
        let body = SubmitAttemptRequest(
            sessionId: sessionId,
            taskId: taskId,
            playerId: playerId,
            isCorrect: isCorrect,
            score: score,
            responseTimeMs: responseTimeMs,
            promptLevel: promptLevel,
            responseData: nil
        )
        return try await post("/adaptive/attempts", body: body)
    }

    // MARK: - Speech Evaluation

    func evaluateSpeech(target: String, spoken: String, threshold: Double = 0.6) async throws -> SpeechEvalResponse {
        let body = SpeechEvalRequest(target: target, spoken: spoken, acceptThreshold: threshold)
        return try await post("/adaptive/evaluate-speech", body: body)
    }

    func evaluateOpenEnded(question: String, spoken: String, exampleAnswers: [String]?, keywords: [String]?) async throws -> OpenEndedEvalResponse {
        let body = OpenEndedEvalRequest(question: question, spoken: spoken, exampleAnswers: exampleAnswers, keywords: keywords)
        return try await post("/adaptive/evaluate-open-ended", body: body)
    }

    // MARK: - Modality

    func getModality(playerId: String) async throws -> ModalityRecommendation {
        try await get("/adaptive/modality/\(playerId)")
    }

    // MARK: - Dashboard

    func getDashboard(playerId: String) async throws -> DashboardSummary {
        try await get("/dashboard/\(playerId)")
    }

    // MARK: - AI Endpoints

    func getAIStatus() async throws -> AIStatusResponse {
        try await get("/ai/status")
    }

    func generateSocialStory(playerId: String, scenario: String? = nil, language: String = "en") async throws -> SocialStoryResponse {
        let body = SocialStoryRequest(playerId: playerId, scenario: scenario, language: language)
        return try await post("/ai/social-story", body: body)
    }

    func getBehaviorGuidance(playerId: String, dimension: String? = nil, concern: String? = nil, language: String = "en") async throws -> BehaviorGuidanceResponse {
        let body = BehaviorGuidanceRequest(playerId: playerId, dimension: dimension, concern: concern, language: language)
        return try await post("/ai/behavior-guidance", body: body)
    }

    func getProgressSummary(playerId: String, language: String = "en") async throws -> ProgressSummaryResponse {
        let body = ProgressSummaryRequest(playerId: playerId, language: language)
        return try await post("/ai/progress-summary", body: body)
    }

    // MARK: - Assessment

    func startAssessment(playerId: String) async throws -> AssessmentStartResponse {
        try await postNoBody("/assessment/start/\(playerId)")
    }

    func getNextAssessmentActivity(assessmentId: String) async throws -> AssessmentActivity {
        try await get("/assessment/\(assessmentId)/next-activity")
    }

    func respondToAssessment(assessmentId: String, body: AssessmentRespondRequest) async throws -> AssessmentRespondResponse {
        try await post("/assessment/\(assessmentId)/respond", body: body)
    }

    func completeAssessment(assessmentId: String) async throws -> AssessmentCompleteResponse {
        try await postNoBody("/assessment/\(assessmentId)/complete")
    }

    // MARK: - Story-Based Assessment

    func listStories() async throws -> StoryListResponse {
        try await get("/story/list")
    }

    func startStory(playerId: String, storyId: String) async throws -> StoryStartResponse {
        let body = StoryStartRequest(storyId: storyId)
        return try await post("/story/start/\(playerId)", body: body)
    }

    func getNextScene(assessmentId: String) async throws -> SceneResponse {
        try await get("/story/\(assessmentId)/next-scene")
    }

    func respondToScene(assessmentId: String, body: SceneRespondRequest) async throws -> SceneRespondResponse {
        try await post("/story/\(assessmentId)/respond", body: body)
    }

    func completeStory(assessmentId: String) async throws -> StoryCompleteResponse {
        try await postNoBody("/story/\(assessmentId)/complete")
    }

    // MARK: - Photo URLs

    func getPhotoURLs() async throws -> [String: String] {
        struct PhotoURLsResponse: Codable {
            let photos: [String: String]
        }
        let response: PhotoURLsResponse = try await get("/adaptive/photo-urls")
        return response.photos
    }

    // MARK: - AI Fuzzy Answer Evaluation

    func evaluateAnswer(question: String, givenAnswer: String, correctAnswer: String, options: [String], dimension: String) async throws -> FuzzyAnswerResult {
        let body = FuzzyAnswerRequest(
            question: question,
            givenAnswer: givenAnswer,
            correctAnswer: correctAnswer,
            options: options,
            dimension: dimension
        )
        return try await post("/adaptive/evaluate-answer", body: body)
    }
}

struct FuzzyAnswerRequest: Codable {
    let question: String
    let givenAnswer: String
    let correctAnswer: String
    let options: [String]
    let dimension: String

    enum CodingKeys: String, CodingKey {
        case question
        case givenAnswer = "given_answer"
        case correctAnswer = "correct_answer"
        case options
        case dimension
    }
}

struct FuzzyAnswerResult: Codable {
    let isAccepted: Bool
    let score: Double
    let feedback: String

    enum CodingKeys: String, CodingKey {
        case isAccepted = "is_accepted"
        case score
        case feedback
    }
}

// MARK: - Error

enum AdaptiveAPIError: LocalizedError {
    case httpError(statusCode: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .httpError(let statusCode, let body):
            return "Server error (\(statusCode)): \(body)"
        }
    }
}
