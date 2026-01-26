//
//  HomeView.swift
//  SpeakEasy
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @Binding var selectedTab: Int
    @StateObject private var speechService = SpeechService()
    @State private var totalObjectCount = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    welcomeSection
                    
                    progressSection
                    
                    quickStartSection
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
                await loadTotalObjectCount()
            }
        }
    }
    
    private func loadTotalObjectCount() async {
        do {
            let objects = try await APIService.shared.getObjects()
            await MainActor.run {
                self.totalObjectCount = objects.count
            }
        } catch {
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
                ) {
                    selectedTab = 1
                }
                
                QuickStartButton(
                    icon: "camera.fill",
                    title: "Camera",
                    color: .green
                ) {
                    selectedTab = 2
                }
                
                QuickStartButton(
                    icon: "star.fill",
                    title: "Progress",
                    color: .orange
                ) {
                    selectedTab = 3
                }
            }
        }
    }
    
}

struct QuickStartButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
        .buttonStyle(QuickStartButtonStyle())
    }
}

struct QuickStartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(0))
            .environmentObject(ProgressManager())
    }
}
