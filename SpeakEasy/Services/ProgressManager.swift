//
//  ProgressManager.swift
//  SpeakEasy
//

import Foundation
import SwiftUI

class ProgressManager: ObservableObject {
    @Published var learnedObjectIds: Set<String> = []
    @Published var totalStars: Int = 0
    @Published var practiceCountById: [String: Int] = [:]
    @Published var lastRatingById: [String: Double] = [:]
    @Published var consecutiveFailedAttemptsById: [String: Int] = [:]
    @Published var showCelebration = false
    @Published var isLoading = false
    
    init() {
        loadProgressFromServer()
    }
    
    func loadProgressFromServer() {
        Task {
            do {
                let progressList = try await APIService.shared.getProgress()
                await MainActor.run {
                    self.learnedObjectIds.removeAll()
                    self.practiceCountById.removeAll()
                    self.lastRatingById.removeAll()
                    self.consecutiveFailedAttemptsById.removeAll()
                    
                    for progress in progressList {
                        if progress.isLearned {
                            self.learnedObjectIds.insert(progress.objectId)
                        }
                        self.practiceCountById[progress.objectId] = progress.practiceCount
                        self.lastRatingById[progress.objectId] = progress.lastRating
                        self.consecutiveFailedAttemptsById[progress.objectId] = progress.consecutiveFailedAttempts
                    }
                    
                    self.totalStars = self.learnedObjectIds.count
                }
            } catch {
                print("Failed to load progress from server: \(error)")
            }
        }
    }
    
    func recordRating(id: String, name: String, rating: Double) {
        lastRatingById[id] = rating
        let currentCount = practiceCountById[id] ?? 0
        practiceCountById[id] = currentCount + 1
        
        if rating >= 4.0 {
            consecutiveFailedAttemptsById[id] = 0
            if !learnedObjectIds.contains(id) {
                learnedObjectIds.insert(id)
                totalStars += 1
                showCelebration = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showCelebration = false
                }
            }
        } else {
            let currentFailed = consecutiveFailedAttemptsById[id] ?? 0
            consecutiveFailedAttemptsById[id] = currentFailed + 1
        }
        
        Task {
            do {
                let response = try await APIService.shared.recordProgress(objectId: id, rating: rating)
                await MainActor.run {
                    if response.isLearned {
                        self.learnedObjectIds.insert(id)
                    }
                    self.lastRatingById[id] = response.lastRating
                    self.practiceCountById[id] = response.practiceCount
                    self.consecutiveFailedAttemptsById[id] = response.consecutiveFailedAttempts
                    self.totalStars = self.learnedObjectIds.count
                }
            } catch {
                print("Failed to record progress to server: \(error)")
            }
        }
    }
    
    func consecutiveFailedAttemptsForId(_ objectId: String) -> Int {
        consecutiveFailedAttemptsById[objectId] ?? 0
    }
    
    func resetConsecutiveFailedAttempts(id: String) {
        consecutiveFailedAttemptsById[id] = 0
    }
    
    func lastRatingForId(_ objectId: String) -> Double {
        lastRatingById[objectId] ?? 0.0
    }
    
    func isLearnedById(_ objectId: String) -> Bool {
        learnedObjectIds.contains(objectId)
    }
    
    func practiceCountForId(_ objectId: String) -> Int {
        practiceCountById[objectId] ?? 0
    }
    
    func progressForCategoryById(_ category: ObjectCategory, objectIds: [String]) -> Double {
        let learnedCount = objectIds.filter { learnedObjectIds.contains($0) }.count
        return objectIds.isEmpty ? 0 : Double(learnedCount) / Double(objectIds.count)
    }
    
    func overallProgressById(totalObjectCount: Int) -> Double {
        return totalObjectCount == 0 ? 0 : Double(learnedObjectIds.count) / Double(totalObjectCount)
    }
    
    func resetProgress() {
        learnedObjectIds.removeAll()
        totalStars = 0
        practiceCountById.removeAll()
        lastRatingById.removeAll()
        consecutiveFailedAttemptsById.removeAll()
        
        Task {
            do {
                try await APIService.shared.resetProgress()
            } catch {
                print("Failed to reset progress on server: \(error)")
            }
        }
    }
    
    func markAsLearned(_ object: ObjectItem) {
        if !learnedObjectIds.contains(object.id.uuidString) {
            learnedObjectIds.insert(object.id.uuidString)
            totalStars += 1
        }
    }
    
    func incrementPractice(for object: ObjectItem) {
        let id = object.id.uuidString
        let currentCount = practiceCountById[id] ?? 0
        practiceCountById[id] = currentCount + 1
    }
    
    func isLearned(_ object: ObjectItem) -> Bool {
        isLearnedById(object.id.uuidString)
    }
    
    func practiceCountFor(_ object: ObjectItem) -> Int {
        practiceCountForId(object.id.uuidString)
    }
    
    func lastRatingFor(_ object: ObjectItem) -> Double {
        lastRatingForId(object.id.uuidString)
    }
    
    func recordRating(for object: ObjectItem, rating: Double) {
        recordRating(id: object.id.uuidString, name: object.name, rating: rating)
    }
    
    func progressForCategory(_ category: ObjectCategory) -> Double {
        let categoryObjects = ObjectData.objects(for: category)
        let objectIds = categoryObjects.map { $0.id.uuidString }
        return progressForCategoryById(category, objectIds: objectIds)
    }
    
    func overallProgress() -> Double {
        let totalObjects = ObjectData.allObjects.count
        return overallProgressById(totalObjectCount: totalObjects)
    }
}
