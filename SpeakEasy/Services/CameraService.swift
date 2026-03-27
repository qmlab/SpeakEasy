//
//  CameraService.swift
//  RisingStarKid
//
//  Live camera preview + real-time object classification using Vision framework.
//  Supports target label matching for adaptive learning object cognition tasks.
//

import Foundation
import AVFoundation
import Vision
import SwiftUI

class CameraService: NSObject, ObservableObject {
    @Published var recognizedObject: String?
    @Published var confidence: Float = 0
    @Published var isProcessing = false
    @Published var permissionGranted = false
    @Published var capturedImage: UIImage?
    @Published var isSessionRunning = false

    /// Top N classification results for display / matching
    @Published var topClassifications: [(label: String, confidence: Float)] = []

    /// When set, `matchFound` fires when any top-5 result contains this label
    @Published var targetLabel: String?
    @Published var matchFound = false
    @Published var matchConfidence: Float = 0

    /// Exposed for SwiftUI live preview via CameraPreviewView
    private(set) var captureSession: AVCaptureSession?

    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var lastProcessingTime = Date()
    private let processingInterval: TimeInterval = 0.5  // 2 FPS for real-time feel

    private lazy var classificationRequest: VNClassifyImageRequest = {
        let request = VNClassifyImageRequest { [weak self] request, error in
            self?.processClassifications(for: request, error: error)
        }
        return request
    }()

    override init() {
        super.init()
        checkPermission()
    }

    // MARK: - Permissions

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }

    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
            }
        }
    }

    // MARK: - Session Setup

    func setupCamera() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    private func configureSession() {
        guard captureSession == nil else { return }
        let session = AVCaptureSession()
        session.sessionPreset = .medium

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video.output.queue"))
        output.alwaysDiscardsLateVideoFrames = true

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        captureSession = session
        videoOutput = output
    }

    // MARK: - Session Control

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession == nil {
                self.configureSession()
            }
            self.captureSession?.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }

    // MARK: - Target Matching for Adaptive Learning

    /// Set a target object label for matching during live preview.
    /// When the camera recognizes this object, `matchFound` is set to true.
    func setTargetLabel(_ label: String?) {
        DispatchQueue.main.async {
            let trimmed = label?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            self.targetLabel = (trimmed?.isEmpty == true) ? nil : trimmed
            self.matchFound = false
            self.matchConfidence = 0
        }
    }

    /// Reset match state for next task
    func resetMatch() {
        DispatchQueue.main.async {
            self.matchFound = false
            self.matchConfidence = 0
            self.recognizedObject = nil
            self.topClassifications = []
        }
    }

    // MARK: - Static Image Classification

    func classifyImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        DispatchQueue.main.async { self.isProcessing = true }
        capturedImage = image

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = classificationRequest

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform classification: \(error)")
                DispatchQueue.main.async {
                    self?.isProcessing = false
                }
            }
        }
    }

    // MARK: - Classification Processing

    private func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else {
            DispatchQueue.main.async { [weak self] in
                self?.isProcessing = false
                self?.recognizedObject = nil
                self?.confidence = 0
                self?.topClassifications = []
            }
            return
        }

        // Take top 5 results above 5% confidence
        let topResults = results
            .prefix(5)
            .filter { $0.confidence > 0.05 }
            .map { obs -> (label: String, confidence: Float) in
                let label = obs.identifier
                    .components(separatedBy: ",")
                    .first?
                    .trimmingCharacters(in: .whitespaces)
                    .capitalized ?? obs.identifier
                return (label: label, confidence: obs.confidence)
            }

        let topResult = topResults.first

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isProcessing = false
            self.topClassifications = topResults
            self.recognizedObject = topResult?.label
            self.confidence = topResult?.confidence ?? 0

            // Check target match
            if let target = self.targetLabel {
                let matched = topResults.first { classification in
                    classification.label.lowercased().contains(target) ||
                    target.contains(classification.label.lowercased())
                }
                if let matched = matched {
                    self.matchFound = true
                    self.matchConfidence = matched.confidence
                }
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastProcessingTime) >= processingInterval else { return }
        lastProcessingTime = currentTime

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        let request = classificationRequest

        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform classification: \(error)")
        }
    }
}

// MARK: - Camera Preview UIViewRepresentable

/// SwiftUI wrapper for AVCaptureVideoPreviewLayer to show live camera feed
struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        if let session = cameraService.captureSession {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            context.coordinator.previewLayer = previewLayer
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame when view resizes
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }

        // If session was set up after initial makeUIView, add the layer
        if context.coordinator.previewLayer == nil, let session = cameraService.captureSession {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = uiView.bounds
            uiView.layer.addSublayer(previewLayer)
            context.coordinator.previewLayer = previewLayer
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
