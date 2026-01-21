//
//  ProgressView.swift
//  SpeakEasy
//

import SwiftUI

struct ProgressView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @StateObject private var speechService = SpeechService()
    @State private var allObjects: [ObjectListResponse] = []
    @State private var isLoading = true
    @State private var totalObjectCount = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    overallProgressSection
                    
                    starsSection
                    
                    categoryProgressSection
                    
                    learnedObjectsSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("My Progress")
            .task {
                await loadAllObjects()
            }
        }
    }
    
    private func loadAllObjects() async {
        isLoading = true
        do {
            let objects = try await APIService.shared.getObjects()
            await MainActor.run {
                self.allObjects = objects
                self.totalObjectCount = objects.count
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private var overallProgressSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 180, height: 180)
                
                let progress = progressManager.overallProgressById(totalObjectCount: totalObjectCount)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: progress)
                
                VStack(spacing: 5) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.purple)
                    
                    Text("Complete")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
            
            Text("\(progressManager.learnedObjectIds.count) of \(totalObjectCount) objects learned")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 15)
        )
        .onTapGesture {
            let progress = progressManager.overallProgressById(totalObjectCount: totalObjectCount)
            let percent = Int(progress * 100)
            speechService.speak("You have completed \(percent) percent!")
        }
    }
    
    private var starsSection: some View {
        HStack(spacing: 20) {
            VStack(spacing: 10) {
                Image(systemName: "star.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange.opacity(0.5), radius: 5)
                
                Text("\(progressManager.totalStars)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                
                Text("Total Stars")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white)
                    .shadow(color: .yellow.opacity(0.3), radius: 10)
            )
            
            VStack(spacing: 10) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.purple)
                    .shadow(color: .purple.opacity(0.5), radius: 5)
                
                Text("\(progressManager.learnedObjectIds.count)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                
                Text("Objects Learned")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white)
                    .shadow(color: .purple.opacity(0.3), radius: 10)
            )
        }
        .onTapGesture {
            speechService.speak("You have \(progressManager.totalStars) stars and learned \(progressManager.learnedObjectIds.count) objects!")
        }
    }
    
    private var categoryProgressSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Category Progress")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
            
            ForEach(ObjectCategory.allCases, id: \.self) { category in
                APICategoryProgressRow(category: category, objects: allObjects.filter { $0.category == category.rawValue })
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 10)
        )
    }
    
    private var learnedObjectsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Learned Objects")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
            
            if progressManager.learnedObjectIds.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "star")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No objects learned yet")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                    
                    Text("Start practicing to earn stars!")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(30)
            } else {
                let learnedItems = allObjects.filter { progressManager.isLearnedById($0.id) }
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 15) {
                    ForEach(learnedItems) { object in
                        APILearnedObjectBadge(object: object, speechService: speechService)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 10)
        )
    }
}

struct APICategoryProgressRow: View {
    let category: ObjectCategory
    let objects: [ObjectListResponse]
    @EnvironmentObject var progressManager: ProgressManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                    .font(.title3)
                
                Text(category.rawValue)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                let learned = objects.filter { progressManager.isLearnedById($0.id) }.count
                Text("\(learned)/\(objects.count)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                    
                    let progress = progressManager.progressForCategoryById(category, objectIds: objects.map { $0.id })
                    RoundedRectangle(cornerRadius: 8)
                        .fill(category.color)
                        .frame(width: geometry.size.width * progress, height: 10)
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 10)
        }
        .padding(.vertical, 5)
    }
}

struct APILearnedObjectBadge: View {
    let object: ObjectListResponse
    @ObservedObject var speechService: SpeechService
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(object.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
            }
            
            Text(object.name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .onTapGesture {
            speechService.speak(object.name)
        }
    }
}

struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressView()
            .environmentObject(ProgressManager())
    }
}
