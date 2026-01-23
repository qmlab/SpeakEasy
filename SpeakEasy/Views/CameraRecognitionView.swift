//
//  CameraRecognitionView.swift
//  SpeakEasy
//

import SwiftUI
import AVFoundation
import PhotosUI

struct CameraRecognitionView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var speechService = SpeechService()
    @EnvironmentObject var progressManager: ProgressManager
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showResult = false
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 30) {
                    headerSection
                    
                    imageSection
                    
                    if let recognizedObject = cameraService.recognizedObject {
                        resultSection(recognizedObject)
                    }
                    
                    actionButtons
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Camera")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    cameraService.classifyImage(image)
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Find Objects!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.green)
            
            Text("Take a photo or choose from your library")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .onTapGesture {
            speechService.speak("Take a photo to find objects!")
        }
    }
    
    private var imageSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
                .frame(height: 250)
                .shadow(color: .gray.opacity(0.2), radius: 15)
            
            if let image = selectedImage ?? cameraService.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 230)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No image selected")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
            
            if cameraService.isProcessing {
                ZStack {
                    Color.black.opacity(0.5)
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                    
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(2)
                            .tint(.white)
                        
                        Text("Looking...")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 250)
            }
        }
    }
    
    private func resultSection(_ recognizedObject: String) -> some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title)
                
                Text("Found:")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            Text(recognizedObject)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
            
            let confidencePercent = Int(cameraService.confidence * 100)
            Text("\(confidencePercent)% confident")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
            
            Button(action: {
                speechService.speak(recognizedObject)
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.title2)
                    Text("Say It!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    Capsule()
                        .fill(Color.purple)
                        .shadow(color: .purple.opacity(0.4), radius: 8)
                )
            }
            .scaleEffect(speechService.isSpeaking ? 0.95 : 1.0)
            .animation(.spring(), value: speechService.isSpeaking)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 10)
        )
    }
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button(action: {
                showImagePicker = true
            }) {
                VStack(spacing: 10) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 30))
                    Text("Gallery")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(width: 100, height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.blue)
                        .shadow(color: .blue.opacity(0.4), radius: 8)
                )
            }
            
            Button(action: {
                selectedImage = nil
                cameraService.capturedImage = nil
                cameraService.recognizedObject = nil
            }) {
                VStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 30))
                    Text("Clear")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(width: 100, height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.orange)
                        .shadow(color: .orange.opacity(0.4), radius: 8)
                )
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.image = image as? UIImage
                }
            }
        }
    }
}

struct CameraRecognitionView_Previews: PreviewProvider {
    static var previews: some View {
        CameraRecognitionView()
            .environmentObject(ProgressManager())
    }
}
