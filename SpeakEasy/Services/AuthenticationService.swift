//
//  AuthenticationService.swift
//  SpeakEasy
//

import Foundation
import AuthenticationServices
import SwiftUI
import UIKit

class AuthenticationService: NSObject, ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var isSignedIn = false
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isGuest = false
    
    private let appleUserIdKey = "speakeasy_apple_user_id"
    private let deviceIdKey = "speakeasy_device_id"
    private let playerIdKey = "speakeasy_player_id"
    private let userNameKey = "speakeasy_user_name"
    private let userEmailKey = "speakeasy_user_email"
    private let isGuestKey = "speakeasy_is_guest"
    
    override init() {
        super.init()
        loadSavedUser()
    }
    
    private func loadSavedUser() {
        if let playerId = UserDefaults.standard.string(forKey: playerIdKey) {
            let appleUserId = UserDefaults.standard.string(forKey: appleUserIdKey)
            let deviceId = UserDefaults.standard.string(forKey: deviceIdKey)
            let name = UserDefaults.standard.string(forKey: userNameKey)
            let email = UserDefaults.standard.string(forKey: userEmailKey)
            let isGuestUser = UserDefaults.standard.bool(forKey: isGuestKey)
            
            currentUser = AppUser(
                appleUserId: appleUserId,
                deviceId: deviceId,
                playerId: playerId,
                name: name,
                email: email,
                isGuest: isGuestUser
            )
            isSignedIn = true
            isGuest = isGuestUser
            
            APIService.shared.playerId = playerId
        }
    }
    
    func getDeviceId() -> String {
        if let existingId = UserDefaults.standard.string(forKey: deviceIdKey) {
            return existingId
        }
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(deviceId, forKey: deviceIdKey)
        return deviceId
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
        UserDefaults.standard.removeObject(forKey: isGuestKey)
        
        currentUser = nil
        isSignedIn = false
        isGuest = false
        APIService.shared.playerId = nil
    }
    
    func signInAsGuest() {
        isLoading = true
        errorMessage = nil
        
        let deviceId = getDeviceId()
        
        Task {
            do {
                let response = try await APIService.shared.guestSignIn(deviceId: deviceId)
                
                await MainActor.run {
                    self.currentUser = AppUser(
                        appleUserId: nil,
                        deviceId: deviceId,
                        playerId: response.id,
                        name: response.name,
                        email: nil,
                        isGuest: true
                    )
                    self.isSignedIn = true
                    self.isGuest = true
                    self.isLoading = false
                    
                    UserDefaults.standard.set(deviceId, forKey: self.deviceIdKey)
                    UserDefaults.standard.set(response.id, forKey: self.playerIdKey)
                    UserDefaults.standard.set(response.name, forKey: self.userNameKey)
                    UserDefaults.standard.set(true, forKey: self.isGuestKey)
                    
                    APIService.shared.playerId = response.id
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to sign in as guest: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
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
                    self.currentUser = AppUser(
                        appleUserId: appleUserId,
                        deviceId: self.getDeviceId(),
                        playerId: response.id,
                        name: response.name,
                        email: response.email,
                        isGuest: false
                    )
                    self.isSignedIn = true
                    self.isGuest = false
                    self.isLoading = false
                    
                    UserDefaults.standard.set(appleUserId, forKey: self.appleUserIdKey)
                    UserDefaults.standard.set(response.id, forKey: self.playerIdKey)
                    UserDefaults.standard.set(response.name, forKey: self.userNameKey)
                    UserDefaults.standard.set(false, forKey: self.isGuestKey)
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

struct AppUser {
    let appleUserId: String?
    let deviceId: String?
    let playerId: String
    let name: String?
    let email: String?
    let isGuest: Bool
}
