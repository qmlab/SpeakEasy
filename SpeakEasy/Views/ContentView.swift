//
//  ContentView.swift
//  RisingStarKid
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @EnvironmentObject var learningManager: AdaptiveLearningManager
    @StateObject private var authService = AuthenticationService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if authService.isSignedIn {
                mainTabView
            } else {
                SignInView(authService: authService)
            }
        }
        .onChange(of: authService.isSignedIn) { isSignedIn in
            if isSignedIn {
                progressManager.loadProgressFromServer()
            }
        }
    }
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            DimensionHubView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text(AppLocalization.learn)
                }
                .tag(0)
            
            AdaptiveDashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text(AppLocalization.progress)
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text(AppLocalization.settings)
                }
                .tag(2)
        }
        .accentColor(.purple)
        .overlay(
            CelebrationView()
                .opacity(progressManager.showCelebration ? 1 : 0)
                .animation(.easeInOut, value: progressManager.showCelebration)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ProgressManager())
    }
}
