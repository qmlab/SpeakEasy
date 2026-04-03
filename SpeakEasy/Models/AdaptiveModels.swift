//
//  AdaptiveModels.swift
//  RisingStarKid
//
//  Codable models for the adaptive learning and AI personalization APIs.
//

import Foundation
import SwiftUI

// MARK: - Developmental Dimensions

enum DevelopmentalDimension: String, Codable, CaseIterable, Identifiable {
    case objectCognition = "object_cognition"
    case languageExpression = "language_expression"
    case languageComprehension = "language_comprehension"
    case literacy = "literacy"
    case socialBehavior = "social_behavior"
    case cognitiveLogic = "cognitive_logic"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .objectCognition: return "Object Cognition"
        case .languageExpression: return "Language Expression"
        case .languageComprehension: return "Language Comprehension"
        case .literacy: return "Literacy"
        case .socialBehavior: return "Social Behavior"
        case .cognitiveLogic: return "Cognitive Logic"
        }
    }

    var icon: String {
        switch self {
        case .objectCognition: return "cube.fill"
        case .languageExpression: return "mouth.fill"
        case .languageComprehension: return "ear.fill"
        case .literacy: return "book.fill"
        case .socialBehavior: return "person.2.fill"
        case .cognitiveLogic: return "brain.head.profile"
        }
    }

    var color: Color {
        switch self {
        case .objectCognition: return .orange
        case .languageExpression: return .blue
        case .languageComprehension: return .green
        case .literacy: return .purple
        case .socialBehavior: return .pink
        case .cognitiveLogic: return .cyan
        }
    }

    var levelDescriptions: [String] {
        switch self {
        case .objectCognition:
            return [
                "Basic Matching", "Object Identification", "Classifying",
                "Function Understanding", "Abstract Relations",
                "Complex Categories", "Multi-Feature Sorting",
                "Conceptual Grouping", "Analogical Reasoning", "Expert Abstraction"
            ]
        case .languageExpression:
            return [
                "Imitating Sounds", "Naming Objects", "Simple Describing",
                "Building Sentences", "Basic Conversation",
                "Detailed Description", "Complex Sentences",
                "Storytelling", "Persuasive Speech", "Advanced Discourse"
            ]
        case .languageComprehension:
            return [
                "Receptive ID (Basic)", "Receptive ID (Intermediate)",
                "Receptive ID (Advanced)", "Semantic & Verbal (Basic)",
                "Semantic & Verbal (Advanced)", "Complex Instructions",
                "Inferential Comprehension", "Abstract Language",
                "Critical Listening", "Advanced Reasoning"
            ]
        case .literacy:
            return [
                "Image Recognition", "Word-Image Matching", "Sight Words",
                "Simple Sentences", "Short Passages",
                "Paragraph Reading", "Story Comprehension",
                "Informational Text", "Critical Reading", "Advanced Literacy"
            ]
        case .socialBehavior:
            return [
                "Joint Attention", "Emotion Recognition", "Social Referencing",
                "Turn Taking", "Perspective Taking",
                "Conflict Resolution", "Group Interaction",
                "Empathy & Support", "Social Problem Solving", "Leadership"
            ]
        case .cognitiveLogic:
            return [
                "Basic Pairing", "Simple Sorting", "Cause & Effect",
                "Sequencing", "Basic Reasoning",
                "Pattern Recognition", "Logical Deduction",
                "Abstract Reasoning", "Multi-Step Logic", "Expert Problem Solving"
            ]
        }
    }
}

// MARK: - Profile Models

struct DevelopmentalProfile: Codable, Identifiable {
    let id: String
    let playerId: String
    let dimension: String
    let level: Int
    let ceilingLevel: Int?
    let basalLevel: Int?
    let subScores: [String: AnyCodableValue]?
    let assessed: Bool
    let lastAssessedAt: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case playerId = "player_id"
        case dimension
        case level
        case ceilingLevel = "ceiling_level"
        case basalLevel = "basal_level"
        case subScores = "sub_scores"
        case assessed
        case lastAssessedAt = "last_assessed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var dimensionEnum: DevelopmentalDimension? {
        DevelopmentalDimension(rawValue: dimension)
    }
}

struct FullProfileResponse: Codable {
    let playerId: String
    let playerName: String
    let dimensions: [DevelopmentalProfile]
    let overallLevel: Double

    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case playerName = "player_name"
        case dimensions
        case overallLevel = "overall_level"
    }
}

// MARK: - Session Models

struct StartSessionRequest: Codable {
    let playerId: String
    let sessionType: String
    let dimension: String?

    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case sessionType = "session_type"
        case dimension
    }
}

struct LearningSession: Codable, Identifiable {
    let id: String
    let playerId: String
    let sessionType: String
    let dimension: String?
    let startedAt: String
    let endedAt: String?
    let tasksCompleted: Int
    let correctCount: Int
    let totalCount: Int
    let avgResponseTimeMs: Double?
    let status: String
    let currentLevel: Int

    enum CodingKeys: String, CodingKey {
        case id
        case playerId = "player_id"
        case sessionType = "session_type"
        case dimension
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case tasksCompleted = "tasks_completed"
        case correctCount = "correct_count"
        case totalCount = "total_count"
        case avgResponseTimeMs = "avg_response_time_ms"
        case status
        case currentLevel = "current_level"
    }
}

// MARK: - Task Models

struct AdaptiveTask: Codable {
    let taskId: String
    let dimension: String
    let level: Int
    let taskType: String
    let modalities: [String]
    let content: TaskContent
    let promptLevel: Int
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case dimension
        case level
        case taskType = "task_type"
        case modalities
        case content
        case promptLevel = "prompt_level"
        case sessionId = "session_id"
    }
}

/// Helper for decoding the nested `target` object from backend task content.
private struct TaskTarget: Codable {
    let name: String
    let category: String?
}

/// Helper for decoding `choices` array items from backend task content.
private struct TaskChoice: Codable {
    let name: String
    let category: String?
    let isCorrect: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case category
        case isCorrect = "is_correct"
    }
}

struct TaskContent: Codable {
    let instruction: String?
    let instructionText: String?
    let instructionAudio: String?
    let instructionZh: String?
    let targetWord: String?
    let imageHint: String?
    let correctAnswer: String?
    let options: [String]?
    let prompt: String?
    let scenario: String?
    let sentence: String?
    let story: String?
    let question: String?
    let passage: String?
    let items: [String]?
    let sequence: [String]?
    let gridLayout: [Int]?
    let animationFrames: [String]?
    let tapCount: Int?
    let openEnded: Bool?
    let exampleAnswers: [String]?
    let keywords: [String]?
    let inputMode: String?
    let inlineImages: Bool?
    let questionImage: String?

    enum CodingKeys: String, CodingKey {
        case instruction
        case instructionText = "instruction_text"
        case instructionAudio = "instruction_audio"
        case instructionZh = "instruction_zh"
        case targetWord = "target_word"
        case imageHint = "image_hint"
        case correctAnswer = "correct_answer"
        case options
        case prompt
        case scenario
        case sentence
        case story
        case question
        case passage
        case items
        case sequence
        case gridLayout = "grid_layout"
        case animationFrames = "animation_frames"
        case target
        case choices
        case tapCount = "tap_count"
        case openEnded = "open_ended"
        case exampleAnswers = "example_answers"
        case keywords
        case inputMode = "input_mode"
        case inlineImages = "inline_images"
        case questionImage = "question_image"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        instruction = try container.decodeIfPresent(String.self, forKey: .instruction)
        instructionText = try container.decodeIfPresent(String.self, forKey: .instructionText)
        instructionAudio = try container.decodeIfPresent(String.self, forKey: .instructionAudio)
        instructionZh = try container.decodeIfPresent(String.self, forKey: .instructionZh)
        imageHint = try container.decodeIfPresent(String.self, forKey: .imageHint)
        prompt = try container.decodeIfPresent(String.self, forKey: .prompt)
        scenario = try container.decodeIfPresent(String.self, forKey: .scenario)
        sentence = try container.decodeIfPresent(String.self, forKey: .sentence)
        story = try container.decodeIfPresent(String.self, forKey: .story)
        question = try container.decodeIfPresent(String.self, forKey: .question)
        passage = try container.decodeIfPresent(String.self, forKey: .passage)
        items = try container.decodeIfPresent([String].self, forKey: .items)
        sequence = try container.decodeIfPresent([String].self, forKey: .sequence)
        gridLayout = try container.decodeIfPresent([Int].self, forKey: .gridLayout)
        animationFrames = try container.decodeIfPresent([String].self, forKey: .animationFrames)
        tapCount = try container.decodeIfPresent(Int.self, forKey: .tapCount)
        openEnded = try container.decodeIfPresent(Bool.self, forKey: .openEnded)
        exampleAnswers = try container.decodeIfPresent([String].self, forKey: .exampleAnswers)
        keywords = try container.decodeIfPresent([String].self, forKey: .keywords)
        inputMode = try container.decodeIfPresent(String.self, forKey: .inputMode)
        inlineImages = try container.decodeIfPresent(Bool.self, forKey: .inlineImages)
        questionImage = try container.decodeIfPresent(String.self, forKey: .questionImage)

        // Decode targetWord: try explicit "target_word" string first, then extract from nested "target" object
        if let tw = try? container.decodeIfPresent(String.self, forKey: .targetWord) {
            targetWord = tw
        } else if let targetObj = try? container.decodeIfPresent(TaskTarget.self, forKey: .target) {
            targetWord = targetObj.name
        } else {
            targetWord = nil
        }

        // Decode options: try explicit "options" [String] first, then extract from nested "choices" array
        let decodedChoices = try? container.decodeIfPresent([TaskChoice].self, forKey: .choices)
        if let opts = try? container.decodeIfPresent([String].self, forKey: .options) {
            options = opts
        } else if let choicesList = decodedChoices {
            options = choicesList.map { $0.name }
        } else {
            options = nil
        }

        // Decode correctAnswer: try explicit "correct_answer" first, then extract from choices
        if let ca = try? container.decodeIfPresent(String.self, forKey: .correctAnswer) {
            correctAnswer = ca
        } else if let choicesList = decodedChoices,
                  let correct = choicesList.first(where: { $0.isCorrect == true }) {
            correctAnswer = correct.name
        } else {
            correctAnswer = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(instruction, forKey: .instruction)
        try container.encodeIfPresent(instructionText, forKey: .instructionText)
        try container.encodeIfPresent(instructionAudio, forKey: .instructionAudio)
        try container.encodeIfPresent(instructionZh, forKey: .instructionZh)
        try container.encodeIfPresent(targetWord, forKey: .targetWord)
        try container.encodeIfPresent(imageHint, forKey: .imageHint)
        try container.encodeIfPresent(correctAnswer, forKey: .correctAnswer)
        try container.encodeIfPresent(options, forKey: .options)
        try container.encodeIfPresent(prompt, forKey: .prompt)
        try container.encodeIfPresent(scenario, forKey: .scenario)
        try container.encodeIfPresent(sentence, forKey: .sentence)
        try container.encodeIfPresent(story, forKey: .story)
        try container.encodeIfPresent(question, forKey: .question)
        try container.encodeIfPresent(passage, forKey: .passage)
        try container.encodeIfPresent(items, forKey: .items)
        try container.encodeIfPresent(sequence, forKey: .sequence)
        try container.encodeIfPresent(gridLayout, forKey: .gridLayout)
        try container.encodeIfPresent(animationFrames, forKey: .animationFrames)
        try container.encodeIfPresent(tapCount, forKey: .tapCount)
        try container.encodeIfPresent(openEnded, forKey: .openEnded)
        try container.encodeIfPresent(exampleAnswers, forKey: .exampleAnswers)
        try container.encodeIfPresent(keywords, forKey: .keywords)
        try container.encodeIfPresent(inputMode, forKey: .inputMode)
        try container.encodeIfPresent(inlineImages, forKey: .inlineImages)
        try container.encodeIfPresent(questionImage, forKey: .questionImage)
    }

    var displayInstruction: String {
        instructionText ?? instruction ?? prompt ?? question ?? "Complete this task"
    }

    var displayOptions: [String] {
        options ?? []
    }
}

// MARK: - Attempt Models

struct SubmitAttemptRequest: Codable {
    let sessionId: String
    let taskId: String
    let playerId: String
    let isCorrect: Bool
    let score: Int
    let responseTimeMs: Int?
    let promptLevel: Int
    let responseData: [String: AnyCodableValue]?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case taskId = "task_id"
        case playerId = "player_id"
        case isCorrect = "is_correct"
        case score
        case responseTimeMs = "response_time_ms"
        case promptLevel = "prompt_level"
        case responseData = "response_data"
    }
}

struct AttemptResult: Codable {
    let attemptId: String
    let isCorrect: Bool
    let score: Int
    let reward: RewardInfo?
    let streak: Int
    let accuracy: Double
    let shouldLevelUp: Bool
    let shouldLevelDown: Bool
    let confidenceRebuild: Bool
    let nextAction: String
    let levelChange: Int
    let hintLevel: Int?
    let scaffoldingHint: String?
    let isCeiling: Bool?
    let isBasal: Bool?

    enum CodingKeys: String, CodingKey {
        case attemptId = "attempt_id"
        case isCorrect = "is_correct"
        case score
        case reward
        case streak
        case accuracy
        case shouldLevelUp = "should_level_up"
        case shouldLevelDown = "should_level_down"
        case confidenceRebuild = "confidence_rebuild"
        case nextAction = "next_action"
        case levelChange = "level_change"
        case hintLevel = "hint_level"
        case scaffoldingHint = "scaffolding_hint"
        case isCeiling = "is_ceiling"
        case isBasal = "is_basal"
    }
}

struct RewardInfo: Codable {
    let type: String?
    let message: String?
}

struct EndSessionResponse: Codable {
    let sessionId: String
    let tasksCompleted: Int
    let correctCount: Int
    let totalCount: Int
    let accuracy: Double
    let avgResponseTimeMs: Double?
    let levelChange: Int
    let rewardsEarned: Int

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case tasksCompleted = "tasks_completed"
        case correctCount = "correct_count"
        case totalCount = "total_count"
        case accuracy
        case avgResponseTimeMs = "avg_response_time_ms"
        case levelChange = "level_change"
        case rewardsEarned = "rewards_earned"
    }
}

// MARK: - Dashboard Models

struct DashboardSummary: Codable {
    let playerId: String
    let playerName: String
    let dimensions: [DevelopmentalProfile]
    let recentSessions: [LearningSession]
    let totalSessions: Int
    let totalTasksCompleted: Int
    let overallAccuracy: Double
    let streakDays: Int
    let masteredTasks: Int
    let strugglingTasks: Int

    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case playerName = "player_name"
        case dimensions
        case recentSessions = "recent_sessions"
        case totalSessions = "total_sessions"
        case totalTasksCompleted = "total_tasks_completed"
        case overallAccuracy = "overall_accuracy"
        case streakDays = "streak_days"
        case masteredTasks = "mastered_tasks"
        case strugglingTasks = "struggling_tasks"
    }
}

// MARK: - Modality

struct ModalityRecommendation: Codable {
    let playerId: String
    let recommendedModality: String
    let alternatives: [String]
    let profileLevels: [String: Int]

    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case recommendedModality = "recommended_modality"
        case alternatives
        case profileLevels = "profile_levels"
    }
}

// MARK: - AI Models

struct SocialStoryRequest: Codable {
    let playerId: String
    let scenario: String?
    let language: String

    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case scenario
        case language
    }
}

struct SocialStoryResponse: Codable {
    let playerId: String
    let title: String
    let story: String
    let targetSkill: String
    let practiceTips: [String]
    let socialLevel: Int?
    let source: String

    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case title
        case story
        case targetSkill = "target_skill"
        case practiceTips = "practice_tips"
        case socialLevel = "social_level"
        case source
    }
}

struct BehaviorGuidanceRequest: Codable {
    let playerId: String
    let dimension: String?
    let concern: String?
    let language: String

    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case dimension
        case concern
        case language
    }
}

struct GuidanceRecommendation: Codable, Identifiable {
    var id: String { dimension }
    let dimension: String
    let dimensionLabel: String?
    let currentLevel: Int?
    let priority: String
    let suggestions: [String]?
    let rationale: String?

    enum CodingKeys: String, CodingKey {
        case dimension
        case dimensionLabel = "dimension_label"
        case currentLevel = "current_level"
        case priority
        case suggestions
        case rationale
    }
}

struct BehaviorGuidanceResponse: Codable {
    let playerId: String
    let summary: String
    let recommendations: [GuidanceRecommendation]
    let homeActivities: [String]
    let source: String

    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case summary
        case recommendations
        case homeActivities = "home_activities"
        case source
    }
}

struct ProgressSummaryRequest: Codable {
    let playerId: String
    let language: String

    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case language
    }
}

struct DimensionAnalysis: Codable, Identifiable {
    var id: String { dimension }
    let dimension: String
    let dimensionLabel: String
    let level: Int
    let currentAbility: String
    let nextSkill: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case dimension
        case dimensionLabel = "dimension_label"
        case level
        case currentAbility = "current_ability"
        case nextSkill = "next_skill"
        case status
    }
}

struct ProgressStatsResponse: Codable {
    let totalSessions: Int
    let totalAttempts: Int
    let overallAccuracy: Double

    enum CodingKeys: String, CodingKey {
        case totalSessions = "total_sessions"
        case totalAttempts = "total_attempts"
        case overallAccuracy = "overall_accuracy"
    }
}

struct ProgressSummaryResponse: Codable {
    let playerId: String
    let narrative: String
    let strengths: [String]
    let areasForGrowth: [String]
    let nextSteps: [String]
    let dimensions: [DimensionAnalysis]
    let stats: ProgressStatsResponse
    let source: String

    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case narrative
        case strengths
        case areasForGrowth = "areas_for_growth"
        case nextSteps = "next_steps"
        case dimensions
        case stats
        case source
    }
}

struct AIStatusResponse: Codable {
    let llmEnabled: Bool
    let model: String?
    let baseUrl: String?
    let fallbackMode: String
    let supportedFeatures: [String]

    enum CodingKeys: String, CodingKey {
        case llmEnabled = "llm_enabled"
        case model
        case baseUrl = "base_url"
        case fallbackMode = "fallback_mode"
        case supportedFeatures = "supported_features"
    }
}

// MARK: - Seed Tasks

struct SeedTasksResponse: Codable {
    let message: String
    let taskCount: Int

    enum CodingKeys: String, CodingKey {
        case message
        case taskCount = "task_count"
    }
}

// MARK: - Speech Evaluation

struct SpeechEvalRequest: Codable {
    let target: String
    let spoken: String
    let acceptThreshold: Double

    enum CodingKeys: String, CodingKey {
        case target
        case spoken
        case acceptThreshold = "accept_threshold"
    }
}

struct SpeechEvalResponse: Codable {
    let similarityScore: Double
    let isAccepted: Bool
    let feedback: String

    enum CodingKeys: String, CodingKey {
        case similarityScore = "similarity_score"
        case isAccepted = "is_accepted"
        case feedback
    }
}

// MARK: - Open-Ended Evaluation

struct OpenEndedEvalRequest: Codable {
    let question: String
    let spoken: String
    let exampleAnswers: [String]?
    let keywords: [String]?

    enum CodingKeys: String, CodingKey {
        case question
        case spoken
        case exampleAnswers = "example_answers"
        case keywords
    }
}

struct OpenEndedEvalResponse: Codable {
    let isAccepted: Bool
    let score: Double
    let feedback: String
    let evaluationMethod: String

    enum CodingKeys: String, CodingKey {
        case isAccepted = "is_accepted"
        case score
        case feedback
        case evaluationMethod = "evaluation_method"
    }
}

// MARK: - Assessment Models

struct AssessmentCharacter: Codable {
    let name: String
    let emoji: String
    let greeting: String?
}

struct AssessmentStartResponse: Codable {
    let assessmentId: String
    let playerId: String
    let character: AssessmentCharacter
    let storyIntro: String
    let totalActivities: Int

    enum CodingKeys: String, CodingKey {
        case assessmentId = "assessment_id"
        case playerId = "player_id"
        case character
        case storyIntro = "story_intro"
        case totalActivities = "total_activities"
    }
}

struct AssessmentActivityContent: Codable {
    let instruction: String
    let narrative: String
    let imageHint: String?
    let options: [String]?
    let correctAnswer: String?
    let targetWord: String?
    let interactionType: String

    enum CodingKeys: String, CodingKey {
        case instruction
        case narrative
        case imageHint = "image_hint"
        case options
        case correctAnswer = "correct_answer"
        case targetWord = "target_word"
        case interactionType = "interaction_type"
    }
}

struct AssessmentActivity: Codable {
    let activityIndex: Int
    let totalActivities: Int
    let dimension: String
    let level: Int
    let character: AssessmentCharacter
    let content: AssessmentActivityContent
    let isLast: Bool

    enum CodingKeys: String, CodingKey {
        case activityIndex = "activity_index"
        case totalActivities = "total_activities"
        case dimension
        case level
        case character
        case content
        case isLast = "is_last"
    }
}

struct AssessmentRespondRequest: Codable {
    let activityIndex: Int
    let selectedOption: String?
    let spokenText: String?
    let responseTimeMs: Int?
    let interactionType: String

    enum CodingKeys: String, CodingKey {
        case activityIndex = "activity_index"
        case selectedOption = "selected_option"
        case spokenText = "spoken_text"
        case responseTimeMs = "response_time_ms"
        case interactionType = "interaction_type"
    }
}

struct AssessmentFeedback: Codable {
    let message: String
    let emoji: String
    let isCorrect: Bool

    enum CodingKeys: String, CodingKey {
        case message
        case emoji
        case isCorrect = "is_correct"
    }
}

struct AssessmentRespondResponse: Codable {
    let isCorrect: Bool
    let feedback: AssessmentFeedback
    let shouldContinue: Bool
    let progressFraction: Double

    enum CodingKeys: String, CodingKey {
        case isCorrect = "is_correct"
        case feedback
        case shouldContinue = "should_continue"
        case progressFraction = "progress_fraction"
    }
}

struct DimensionResult: Codable, Identifiable {
    let dimension: String
    let dimensionLabel: String
    let assessedLevel: Int
    let maxTestedLevel: Int
    let correctCount: Int
    let totalCount: Int
    let accuracy: Double
    let icon: String
    let color: String

    var id: String { dimension }

    enum CodingKeys: String, CodingKey {
        case dimension
        case dimensionLabel = "dimension_label"
        case assessedLevel = "assessed_level"
        case maxTestedLevel = "max_tested_level"
        case correctCount = "correct_count"
        case totalCount = "total_count"
        case accuracy
        case icon
        case color
    }

    var dimensionEnum: DevelopmentalDimension? {
        DevelopmentalDimension(rawValue: dimension)
    }
}

struct AssessmentCompleteResponse: Codable {
    let assessmentId: String
    let playerId: String
    let dimensions: [DimensionResult]
    let overallLevel: Double
    let totalActivities: Int
    let totalCorrect: Int
    let durationSeconds: Int?
    let characterMessage: String

    enum CodingKeys: String, CodingKey {
        case assessmentId = "assessment_id"
        case playerId = "player_id"
        case dimensions
        case overallLevel = "overall_level"
        case totalActivities = "total_activities"
        case totalCorrect = "total_correct"
        case durationSeconds = "duration_seconds"
        case characterMessage = "character_message"
    }
}

// MARK: - AnyCodableValue (for flexible dict values)

enum AnyCodableValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if container.decodeNil() {
            self = .null
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}
