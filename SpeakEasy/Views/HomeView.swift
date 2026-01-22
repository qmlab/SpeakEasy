//
//  HomeView.swift
//  SpeakEasy
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @StateObject private var speechService = SpeechService()
    @State private var featuredObjects: [ObjectListResponse] = []
    @State private var totalObjectCount = 0
    @State private var isLoading = true
    
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
            .task {
                await loadFeaturedObjects()
            }
        }
    }
    
    private func loadFeaturedObjects() async {
        do {
            let objects = try await APIService.shared.getObjects()
            await MainActor.run {
                self.featuredObjects = Array(objects.prefix(8))
                self.totalObjectCount = objects.count
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
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
        let progress = progressManager.overallProgressById(totalObjectCount: totalObjectCount)
        return VStack(spacing: 15) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                Text("\(progressManager.totalStars) Stars")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
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
                        .frame(width: geometry.size.width * progress, height: 20)
                        .animation(.spring(), value: progress)
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
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if featuredObjects.isEmpty {
                Text("No objects available")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(featuredObjects) { object in
                            APIFeaturedObjectCard(object: object, speechService: speechService)
                        }
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

struct APIFeaturedObjectCard: View {
    let object: ObjectListResponse
    @ObservedObject var speechService: SpeechService
    @EnvironmentObject var progressManager: ProgressManager
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(object.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                RemoteImageView(
                    objectName: object.name,
                    imageType: .thumbnail,
                    fallbackIcon: iconForObject(object.name),
                    iconColor: object.color,
                    size: 60,
                    directURL: object.thumbnailUrl
                )
                .clipShape(Circle())
            }
            
            Text(object.name)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            if progressManager.isLearnedById(object.id) {
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
                }
    }
    
    private func iconForObject(_ name: String) -> String {
        switch name.lowercased() {
        case "dog": return "dog.fill"
        case "cat": return "cat.fill"
        case "bird": return "bird.fill"
        case "fish": return "fish.fill"
        case "rabbit": return "hare.fill"
        case "elephant": return "tortoise.fill"
        case "apple": return "apple.logo"
        case "banana": return "leaf.fill"
        case "orange": return "circle.fill"
        case "grapes": return "circle.grid.2x2.fill"
        case "mushroom": return "leaf.fill"
        case "tomato": return "circle.fill"
        case "car": return "car.fill"
        case "bicycle": return "bicycle"
        case "motorcycle": return "bicycle"
        case "boat": return "ferry.fill"
        case "sun": return "sun.max.fill"
        case "moon": return "moon.fill"
        case "star": return "star.fill"
        case "tree": return "tree.fill"
        case "flower": return "camera.macro"
        case "rock": return "mountain.2.fill"
        case "house": return "house.fill"
        case "ball": return "circle.fill"
        case "teddy bear": return "teddybear.fill"
        case "doll": return "person.fill"
        case "puzzle": return "puzzlepiece.fill"
        case "yo yo": return "circle.fill"
        case "book": return "book.fill"
        case "chair": return "chair.fill"
        case "table": return "rectangle.fill"
        case "lamp": return "lamp.desk.fill"
        case "mirror": return "rectangle.portrait.fill"
        case "cup": return "cup.and.saucer.fill"
        case "hand": return "hand.raised.fill"
        case "foot": return "figure.walk"
        case "eye": return "eye.fill"
        case "ear": return "ear.fill"
        case "shirt": return "tshirt.fill"
        case "hat": return "hat.widebrim.fill"
        case "socks": return "shoe.fill"
        case "gloves": return "hand.raised.fill"
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
