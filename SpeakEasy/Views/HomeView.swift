//
//  HomeView.swift
//  RisingStarKid
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @EnvironmentObject var learningManager: AdaptiveLearningManager
    @Binding var selectedTab: Int
    @StateObject private var speechService = SpeechService()
    @State private var totalObjectCount = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    welcomeSection
                    
                    dimensionOverviewSection
                    
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
            .navigationTitle(AppLocalization.appTitle)
            .task {
                await loadTotalObjectCount()
                await learningManager.loadProfiles()
            }
        }
        .navigationViewStyle(.stack)
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
            Image(systemName: "star.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
                .shadow(color: .orange.opacity(0.5), radius: 10)
            
            Text("\(AppLocalization.hello), \(learningManager.playerName.isEmpty ? "⭐" : learningManager.playerName)!")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
            
            Text(AppLocalization.letsLearnTogether)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 20)
        .onTapGesture {
            speechService.speak(AppLocalization.isChineseMode ? "你好！一起来学习吧！" : "Hello! Let's learn together!")
        }
    }
    
    private var dimensionOverviewSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text(AppLocalization.myDevelopment)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                Spacer()
                Text("\(AppLocalization.level) \(String(format: "%.1f", learningManager.overallLevel))")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.orange)
            }
            
            // Mini dimension indicators
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(DevelopmentalDimension.allCases) { dimension in
                    VStack(spacing: 6) {
                        Image(systemName: dimension.icon)
                            .font(.title2)
                            .foregroundColor(dimension.color)
                        
                        Text("Lv.\(learningManager.level(for: dimension))")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(dimension.color)
                        
                        // Mini level dots
                        HStack(spacing: 3) {
                            ForEach(0..<5, id: \.self) { i in
                                Circle()
                                    .fill(i < learningManager.level(for: dimension) ? dimension.color : Color(.systemGray4))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                }
            }
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
            Text(AppLocalization.quickStart)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
            
            HStack(spacing: 15) {
                QuickStartButton(
                    icon: "sparkles",
                    title: AppLocalization.learn,
                    color: .blue
                ) {
                    selectedTab = 1
                }
                
                QuickStartButton(
                    icon: "camera.fill",
                    title: AppLocalization.camera,
                    color: .green
                ) {
                    selectedTab = 2
                }
                
                QuickStartButton(
                    icon: "chart.bar.fill",
                    title: AppLocalization.progress,
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
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: 5)
                
                VStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuickStartButtonStyle())
    }
}

struct QuickStartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(0))
            .environmentObject(ProgressManager())
    }
}
