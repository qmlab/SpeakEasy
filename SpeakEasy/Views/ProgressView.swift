//
//  ProgressView.swift
//  SpeakEasy
//

import SwiftUI

struct ProgressView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @StateObject private var speechService = SpeechService()
    
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
        }
    }
    
    private var overallProgressSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 180, height: 180)
                
                Circle()
                    .trim(from: 0, to: progressManager.overallProgress())
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
                    .animation(.spring(), value: progressManager.overallProgress())
                
                VStack(spacing: 5) {
                    Text("\(Int(progressManager.overallProgress() * 100))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.purple)
                    
                    Text("Complete")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
            
            Text("\(progressManager.learnedObjects.count) of \(ObjectData.allObjects.count) objects learned")
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
            let percent = Int(progressManager.overallProgress() * 100)
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
                
                Text("\(progressManager.learnedObjects.count)")
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
            speechService.speak("You have \(progressManager.totalStars) stars and learned \(progressManager.learnedObjects.count) objects!")
        }
    }
    
    private var categoryProgressSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Category Progress")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
            
            ForEach(ObjectCategory.allCases, id: \.self) { category in
                CategoryProgressRow(category: category)
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
            
            if progressManager.learnedObjects.isEmpty {
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
                let learnedItems = ObjectData.allObjects.filter { progressManager.isLearned($0) }
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 15) {
                    ForEach(learnedItems) { object in
                        LearnedObjectBadge(object: object, speechService: speechService)
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

struct CategoryProgressRow: View {
    let category: ObjectCategory
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
                
                let objects = ObjectData.objects(for: category)
                let learned = objects.filter { progressManager.isLearned($0) }.count
                Text("\(learned)/\(objects.count)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(category.color)
                        .frame(width: geometry.size.width * progressManager.progressForCategory(category), height: 10)
                        .animation(.spring(), value: progressManager.progressForCategory(category))
                }
            }
            .frame(height: 10)
        }
        .padding(.vertical, 5)
    }
}

struct LearnedObjectBadge: View {
    let object: ObjectItem
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
