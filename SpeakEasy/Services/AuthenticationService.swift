//
//  AuthenticationService.swift
//  SpeakEasy
//

import Foundation
import AuthenticationServices
import SwiftUI

class AuthenticationService: NSObject, ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var isSignedIn = false
    @Published var currentUser: AppleUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let appleUserIdKey = "speakeasy_apple_user_id"
    private let playerIdKey = "speakeasy_player_id"
    private let userNameKey = "speakeasy_user_name"
    private let userEmailKey = "speakeasy_user_email"
    
    override init() {
        super.init()
        loadSavedUser()
    }
    
    private func loadSavedUser() {
        if let appleUserId = UserDefaults.standard.string(forKey: appleUserIdKey),
           let playerId = UserDefaults.standard.string(forKey: playerIdKey) {
            let name = UserDefaults.standard.string(forKey: userNameKey)
            let email = UserDefaults.standard.string(forKey: userEmailKey)
            
            currentUser = AppleUser(
                appleUserId: appleUserId,
                playerId: playerId,
                name: name,
                email: email
            )
            isSignedIn = true
            
            APIService.shared.playerId = playerId
        }
    }
    
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
        
        isLoading = true
        errorMessage = nil
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: appleUserIdKey)
        UserDefaults.standard.removeObject(forKey: playerIdKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        
        currentUser = nil
        isSignedIn = false
        APIService.shared.playerId = nil
    }
    
    private func authenticateWithBackend(appleUserId: String, name: String?, email: String?) {
        Task {
            do {
                let response = try await APIService.shared.appleSignIn(
                    appleUserId: appleUserId,
                    name: name,
                    email: email
                )
                
                await MainActor.run {
                    self.currentUser = AppleUser(
                        appleUserId: appleUserId,
                        playerId: response.id,
                        name: response.name,
                        email: response.email
                    )
                    self.isSignedIn = true
                    self.isLoading = false
                    
                    UserDefaults.standard.set(appleUserId, forKey: self.appleUserIdKey)
                    UserDefaults.standard.set(response.id, forKey: self.playerIdKey)
                    UserDefaults.standard.set(response.name, forKey: self.userNameKey)
                    if let email = response.email {
                        UserDefaults.standard.set(email, forKey: self.userEmailKey)
                    }
                    
                    APIService.shared.playerId = response.id
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to sign in: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

extension AuthenticationService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            isLoading = false
            errorMessage = "Invalid credentials"
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
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isLoading = false
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                errorMessage = nil
            case .failed:
                errorMessage = "Sign in failed. Please try again."
            case .invalidResponse:
                errorMessage = "Invalid response from Apple."
            case .notHandled:
                errorMessage = "Sign in not handled."
            case .unknown:
                errorMessage = "An unknown error occurred."
            @unknown default:
                errorMessage = "An error occurred."
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
}

struct AppleUser {
    let appleUserId: String
    let playerId: String
    let name: String?
    let email: String?
}
