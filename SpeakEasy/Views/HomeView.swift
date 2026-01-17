//
//  HomeView.swift
//  SpeakEasy
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @StateObject private var speechService = SpeechService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    welcomeSection
                    
                    progressSection
                    
                    quickStartSection
                    
                    featuredObjectsSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("SpeakEasy")
        }
    }
    
    private var welcomeSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "face.smiling.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
                .shadow(color: .orange.opacity(0.5), radius: 10)
            
            Text("Hello, Friend!")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
            
            Text("Let's learn together!")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 20)
        .onTapGesture {
            speechService.speak("Hello, Friend! Let's learn together!")
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                Text("\(progressManager.totalStars) Stars")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text("\(Int(progressManager.overallProgress() * 100))%")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.green)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                    
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressManager.overallProgress(), height: 20)
                        .animation(.spring(), value: progressManager.overallProgress())
                }
            }
            .frame(height: 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 10)
        )
    }
    
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quick Start")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
            
            HStack(spacing: 15) {
                QuickStartButton(
                    icon: "square.grid.2x2.fill",
                    title: "Flashcards",
                    color: .blue
                )
                
                QuickStartButton(
                    icon: "camera.fill",
                    title: "Camera",
                    color: .green
                )
                
                QuickStartButton(
                    icon: "star.fill",
                    title: "Progress",
                    color: .orange
                )
            }
        }
    }
    
    private var featuredObjectsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Featured Objects")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(ObjectData.allObjects.prefix(8)) { object in
                        FeaturedObjectCard(object: object, speechService: speechService)
                    }
                }
            }
        }
    }
}

struct QuickStartButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(color)
                .shadow(color: color.opacity(0.4), radius: 5)
        )
    }
}

struct FeaturedObjectCard: View {
    let object: ObjectItem
    @ObservedObject var speechService: SpeechService
    @EnvironmentObject var progressManager: ProgressManager
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(object.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: iconForObject(object))
                    .font(.system(size: 35))
                    .foregroundColor(object.color)
            }
            
            Text(object.name)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            if progressManager.isLearned(object) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 5)
        )
        .onTapGesture {
            speechService.speak(object.name)
            progressManager.incrementPractice(for: object)
        }
    }
    
    private func iconForObject(_ object: ObjectItem) -> String {
        switch object.name.lowercased() {
        case "dog": return "dog.fill"
        case "cat": return "cat.fill"
        case "bird": return "bird.fill"
        case "fish": return "fish.fill"
        case "rabbit": return "hare.fill"
        case "apple": return "apple.logo"
        case "car": return "car.fill"
        case "sun": return "sun.max.fill"
        case "moon": return "moon.fill"
        case "star": return "star.fill"
        case "tree": return "tree.fill"
        case "flower": return "camera.macro"
        case "house": return "house.fill"
        case "ball": return "circle.fill"
        case "book": return "book.fill"
        case "cup": return "cup.and.saucer.fill"
        default: return "photo.fill"
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(ProgressManager())
    }
}
