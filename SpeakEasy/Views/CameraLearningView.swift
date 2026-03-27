//
//  CameraLearningView.swift
//  RisingStarKid
//
//  Camera-based interaction for object cognition tasks in adaptive learning.
//  Shows live camera preview with real-time object detection, guiding children
//  to find and identify objects in the real world.
//

import SwiftUI

struct CameraLearningView: View {
    let task: AdaptiveTask
    let dimension: DevelopmentalDimension
    let onResult: (Bool, Int) -> Void

    @StateObject private var cameraService = CameraService()
    @StateObject private var speechService = SpeechService()
    @State private var showSuccess = false
    @State private var countdown: Int = 0
    @State private var hasSubmitted = false

    /// The object the child needs to find
    private var targetObject: String {
        task.content.targetWord ?? task.content.correctAnswer ?? ""
    }

    var body: some View {
        ZStack {
            // Live camera preview
            if cameraService.permissionGranted {
                CameraPreviewView(cameraService: cameraService)
                    .ignoresSafeArea()
            } else {
                permissionDeniedView
            }

            // Overlay UI
            VStack {
                // Top: close button + instruction banner
                HStack {
                    Button {
                        guard !hasSubmitted else { return }
                        onResult(false, 0)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    Spacer()
                }

                instructionBanner

                Spacer()

                // Bottom: detection results + action area
                VStack(spacing: 16) {
                    // Live detection labels
                    if !cameraService.topClassifications.isEmpty && !showSuccess {
                        detectionLabels
                    }

                    // Success celebration
                    if showSuccess {
                        successBanner
                    }

                    // Hint button
                    if !showSuccess {
                        hintButton
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            cameraService.setupCamera()
            cameraService.setTargetLabel(targetObject)
            cameraService.startSession()
            speechService.speak("Can you find a \(targetObject)?")
        }
        .onDisappear {
            cameraService.stopSession()
        }
        .onChange(of: cameraService.matchFound) { found in
            if found && !hasSubmitted {
                handleMatch()
            }
        }
    }

    // MARK: - Instruction Banner

    private var instructionBanner: some View {
        VStack(spacing: 8) {
            Text(task.content.displayInstruction)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Image(systemName: "viewfinder")
                    .foregroundColor(.yellow)
                Text("Find: \(targetObject)")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.black.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Detection Labels

    private var detectionLabels: some View {
        VStack(spacing: 8) {
            ForEach(Array(cameraService.topClassifications.prefix(3).enumerated()), id: \.offset) { _, classification in
                HStack {
                    Text(classification.label)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(Int(classification.confidence * 100))%")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isTargetMatch(classification.label) ? Color.green.opacity(0.8) : Color.black.opacity(0.5))
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Success Banner

    private var successBanner: some View {
        VStack(spacing: 12) {
            Text("Found it!")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("\(targetObject)")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.yellow)

            Text("\(Int(cameraService.matchConfidence * 100))% confident")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.green.opacity(0.85))
                .shadow(color: .green.opacity(0.5), radius: 20)
        )
        .scaleEffect(showSuccess ? 1.0 : 0.5)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showSuccess)
    }

    // MARK: - Hint Button

    private var hintButton: some View {
        Button {
            speechService.speak("Try to find a \(targetObject). Point the camera at it!")
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title3)
                Text("Hint")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(dimension.color.opacity(0.9))
                    .shadow(color: dimension.color.opacity(0.4), radius: 8)
            )
        }
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Camera Access Needed")
                .font(.title2)
                .fontWeight(.bold)

            Text("Please allow camera access in Settings to use this feature.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Helpers

    private func isTargetMatch(_ label: String) -> Bool {
        let target = targetObject.lowercased()
        let detected = label.lowercased()
        return detected.contains(target) || target.contains(detected)
    }

    private func handleMatch() {
        hasSubmitted = true
        withAnimation {
            showSuccess = true
        }

        // Celebrate with speech
        speechService.speak("Great job! You found the \(targetObject)!")

        // Auto-submit after a brief celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onResult(true, 1)
        }
    }
}

// MARK: - Manual Fallback (for when camera can't detect)

struct CameraFallbackView: View {
    let task: AdaptiveTask
    let dimension: DevelopmentalDimension
    let onResult: (Bool, Int) -> Void

    @StateObject private var cameraService = CameraService()
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?

    private var targetObject: String {
        task.content.targetWord ?? task.content.correctAnswer ?? ""
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Take a photo of: \(targetObject)")
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(16)

                if cameraService.isProcessing {
                    ProgressView("Analyzing...")
                } else if let recognized = cameraService.recognizedObject {
                    let isMatch = isTargetMatch(recognized)
                    VStack(spacing: 8) {
                        Text(isMatch ? "Found: \(recognized)" : "I see: \(recognized)")
                            .font(.headline)
                            .foregroundColor(isMatch ? .green : .orange)

                        Button(isMatch ? "Correct!" : "Try Again") {
                            if isMatch {
                                onResult(true, 1)
                            } else {
                                selectedImage = nil
                                cameraService.recognizedObject = nil
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isMatch ? .green : .orange)
                    }
                }
            } else {
                Button {
                    showImagePicker = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                        Text("Take Photo")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(width: 160, height: 160)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(dimension.color)
                    )
                }
            }
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                cameraService.classifyImage(image)
            }
        }
    }

    private func isTargetMatch(_ label: String) -> Bool {
        let target = targetObject.lowercased()
        let detected = label.lowercased()
        return detected.contains(target) || target.contains(detected)
    }
}
