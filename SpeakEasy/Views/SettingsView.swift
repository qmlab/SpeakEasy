//
//  SettingsView.swift
//  SpeakEasy
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @StateObject private var speechService = SpeechService()
    @ObservedObject private var authService = AuthenticationService.shared
    @State private var speechRate: Double = 0.4
    @State private var showResetAlert = false
    @State private var showSignOutAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    accountSection
                    
                    speechSettingsSection
                    
                    aboutSection
                    
                    resetSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.gray.opacity(0.1), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Settings")
            .alert("Reset Progress", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    progressManager.resetProgress()
                }
            } message: {
                Text("Are you sure you want to reset all progress? This cannot be undone.")
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Account")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            if let user = authService.currentUser {
                VStack(alignment: .leading, spacing: 15) {
                    if let name = user.name {
                        AboutRow(icon: "person.fill", color: .blue, title: "Name", value: name)
                        Divider()
                    }
                    
                    if let email = user.email {
                        AboutRow(icon: "envelope.fill", color: .purple, title: "Email", value: email)
                        Divider()
                    }
                    
                    AboutRow(icon: "checkmark.seal.fill", color: .green, title: "Signed in with", value: "Apple")
                }
            }
            
            Button(action: {
                showSignOutAlert = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.orange)
                )
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 10)
        )
    }
    
    private var speechSettingsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Speech Settings")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Speech Speed")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "tortoise.fill")
                        .foregroundColor(.green)
                    
                    Slider(value: $speechRate, in: 0.1...0.6, step: 0.1)
                        .accentColor(.blue)
                        .onChange(of: speechRate) { newValue in
                            speechService.setSpeechRate(Float(newValue))
                        }
                    
                    Image(systemName: "hare.fill")
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        speechService.speak("Hello! This is how I sound.")
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Test Voice")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 10)
        )
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                Text("About SpeakEasy")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 15) {
                AboutRow(icon: "star.fill", color: .yellow, title: "Version", value: "1.0.0")
                
                Divider()
                
                AboutRow(icon: "heart.fill", color: .red, title: "Made with", value: "Love")
                
                Divider()
                
                AboutRow(icon: "person.3.fill", color: .blue, title: "For", value: "Special Kids")
            }
            
            Text("SpeakEasy helps non-verbal children learn to recognize and speak object names through interactive flashcards and camera recognition.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
                .padding(.top, 10)
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 10)
        )
    }
    
    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("Reset")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Text("Reset all progress and start fresh. This will remove all learned objects and stars.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
            
            Button(action: {
                showResetAlert = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "trash.fill")
                    Text("Reset All Progress")
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.red)
                )
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 10)
        )
    }
}

struct AboutRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.gray)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ProgressManager())
    }
}
