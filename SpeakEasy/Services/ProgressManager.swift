//
//  ProgressManager.swift
//  SpeakEasy
//

import Foundation
import SwiftUI

class ProgressManager: ObservableObject {
    @Published var learnedObjects: Set<UUID> = []
    @Published var totalStars: Int = 0
    @Published var practiceCount: [UUID: Int] = [:]
    @Published var showCelebration = false
    
    private let learnedObjectsKey = "learnedObjects"
    private let totalStarsKey = "totalStars"
    private let practiceCountKey = "practiceCount"
    
    init() {
        loadProgress()
    }
    
    func markAsLearned(_ object: ObjectItem) {
        if !learnedObjects.contains(object.id) {
            learnedObjects.insert(object.id)
            totalStars += 1
            showCelebration = true
            saveProgress()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showCelebration = false
            }
        }
    }
    
    func incrementPractice(for object: ObjectItem) {
        let currentCount = practiceCount[object.id] ?? 0
        practiceCount[object.id] = currentCount + 1
        
        if currentCount + 1 >= 3 && !learnedObjects.contains(object.id) {
            markAsLearned(object)
        }
        
        saveProgress()
    }
    
    func isLearned(_ object: ObjectItem) -> Bool {
        learnedObjects.contains(object.id)
    }
    
    func practiceCountFor(_ object: ObjectItem) -> Int {
        practiceCount[object.id] ?? 0
    }
    
    func progressForCategory(_ category: ObjectCategory) -> Double {
        let categoryObjects = ObjectData.objects(for: category)
        let learnedCount = categoryObjects.filter { learnedObjects.contains($0.id) }.count
        return categoryObjects.isEmpty ? 0 : Double(learnedCount) / Double(categoryObjects.count)
    }
    
    func overallProgress() -> Double {
        let totalObjects = ObjectData.allObjects.count
        return totalObjects == 0 ? 0 : Double(learnedObjects.count) / Double(totalObjects)
    }
    
    private func saveProgress() {
        let learnedArray = learnedObjects.map { $0.uuidString }
        UserDefaults.standard.set(learnedArray, forKey: learnedObjectsKey)
        UserDefaults.standard.set(totalStars, forKey: totalStarsKey)
        
        let practiceDict = practiceCount.reduce(into: [String: Int]()) { result, pair in
            result[pair.key.uuidString] = pair.value
        }
        UserDefaults.standard.set(practiceDict, forKey: practiceCountKey)
    }
    
    private func loadProgress() {
        if let learnedArray = UserDefaults.standard.stringArray(forKey: learnedObjectsKey) {
            learnedObjects = Set(learnedArray.compactMap { UUID(uuidString: $0) })
        }
        
        totalStars = UserDefaults.standard.integer(forKey: totalStarsKey)
        
        if let practiceDict = UserDefaults.standard.dictionary(forKey: practiceCountKey) as? [String: Int] {
            practiceCount = practiceDict.reduce(into: [UUID: Int]()) { result, pair in
                if let uuid = UUID(uuidString: pair.key) {
                    result[uuid] = pair.value
                }
            }
        }
    }
    
    func resetProgress() {
        learnedObjects.removeAll()
        totalStars = 0
        practiceCount.removeAll()
        saveProgress()
    }
}
