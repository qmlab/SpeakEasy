//
//  ContentView.swift
//  SpeakEasy
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var progressManager: ProgressManager
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
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            CategoriesView()
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Learn")
                }
                .tag(1)
            
            CameraRecognitionView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
                .tag(2)
            
            ProgressTrackerView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Progress")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
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
