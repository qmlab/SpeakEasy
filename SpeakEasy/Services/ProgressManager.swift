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
    @Published var showCelebration = false
    
    private let learnedObjectsKey = "learnedObjectIds"
    private let totalStarsKey = "totalStars"
    private let practiceCountKey = "practiceCountById"
    
    init() {
        loadProgress()
    }
    
    func markAsLearnedById(_ objectId: String) {
        if !learnedObjectIds.contains(objectId) {
            learnedObjectIds.insert(objectId)
            totalStars += 1
            showCelebration = true
            saveProgress()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showCelebration = false
            }
        }
    }
    
    func incrementPracticeForObject(id: String, name: String) {
        let currentCount = practiceCountById[id] ?? 0
        practiceCountById[id] = currentCount + 1
        
        if currentCount + 1 >= 3 && !learnedObjectIds.contains(id) {
            markAsLearnedById(id)
        }
        
        saveProgress()
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
    
    private func saveProgress() {
        let learnedArray = Array(learnedObjectIds)
        UserDefaults.standard.set(learnedArray, forKey: learnedObjectsKey)
        UserDefaults.standard.set(totalStars, forKey: totalStarsKey)
        UserDefaults.standard.set(practiceCountById, forKey: practiceCountKey)
    }
    
    private func loadProgress() {
        if let learnedArray = UserDefaults.standard.stringArray(forKey: learnedObjectsKey) {
            learnedObjectIds = Set(learnedArray)
        }
        
        totalStars = UserDefaults.standard.integer(forKey: totalStarsKey)
        
        if let practiceDict = UserDefaults.standard.dictionary(forKey: practiceCountKey) as? [String: Int] {
            practiceCountById = practiceDict
        }
    }
    
    func resetProgress() {
        learnedObjectIds.removeAll()
        totalStars = 0
        practiceCountById.removeAll()
        saveProgress()
    }
    
    func markAsLearned(_ object: ObjectItem) {
        markAsLearnedById(object.id.uuidString)
    }
    
    func incrementPractice(for object: ObjectItem) {
        incrementPracticeForObject(id: object.id.uuidString, name: object.name)
    }
    
    func isLearned(_ object: ObjectItem) -> Bool {
        isLearnedById(object.id.uuidString)
    }
    
    func practiceCountFor(_ object: ObjectItem) -> Int {
        practiceCountForId(object.id.uuidString)
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
