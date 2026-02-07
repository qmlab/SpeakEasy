//
//  SignInView.swift
//  SpeakEasy
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @ObservedObject var authService: AuthenticationService
    @StateObject private var speechService = SpeechService()
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "face.smiling.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange.opacity(0.5), radius: 15)
                
                Text("SpeakEasy")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                
                Text("Learn to speak with fun!")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
            }
            .onTapGesture {
                speechService.speak("Welcome to SpeakEasy! Learn to speak with fun!")
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                if authService.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleSignInResult(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 55)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
                    
                    Button(action: {
                        authService.signInAsGuest()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 20))
                            Text("Continue as Guest")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color.purple)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
                
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
                .frame(height: 50)
        }
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                authService.errorMessage = "Invalid credentials"
                return
            }
            
            let appleUserId = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            var name: String? = nil
            if let givenName = fullName?.givenName {
                name = givenName
                if let familyName = fullName?.familyName {
                    name = "\(givenName) \(familyName)"
                }
            }
            
            authenticateWithBackend(appleUserId: appleUserId, name: name, email: email)
            
        case .failure(let error):
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    authService.errorMessage = nil
                default:
                    authService.errorMessage = "Sign in failed. Please try again."
                }
            } else {
                authService.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func authenticateWithBackend(appleUserId: String, name: String?, email: String?) {
        authService.isLoading = true
        authService.errorMessage = nil
        
        Task {
            do {
                let response = try await APIService.shared.appleSignIn(
                    appleUserId: appleUserId,
                    name: name,
                    email: email
                )
                
                await MainActor.run {
                    let appleUserIdKey = "speakeasy_apple_user_id"
                    let playerIdKey = "speakeasy_player_id"
                    let userNameKey = "speakeasy_user_name"
                    let userEmailKey = "speakeasy_user_email"
                    let isGuestKey = "speakeasy_is_guest"
                    
                    UserDefaults.standard.set(appleUserId, forKey: appleUserIdKey)
                    UserDefaults.standard.set(response.id, forKey: playerIdKey)
                    UserDefaults.standard.set(response.name, forKey: userNameKey)
                    UserDefaults.standard.set(false, forKey: isGuestKey)
                    if let email = response.email {
                        UserDefaults.standard.set(email, forKey: userEmailKey)
                    }
                    
                    APIService.shared.playerId = response.id
                    
                    authService.currentUser = AppUser(
                        appleUserId: appleUserId,
                        deviceId: nil,
                        playerId: response.id,
                        name: response.name,
                        email: response.email,
                        isGuest: false
                    )
                    authService.isSignedIn = true
                    authService.isGuest = false
                    authService.isLoading = false
                }
            } catch {
                await MainActor.run {
                    authService.errorMessage = "Failed to sign in. Please try again."
                    authService.isLoading = false
                }
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(authService: AuthenticationService.shared)
    }
}
